/*                                                                      
    Designer   : Renyangang               
                                                                            
    Licensed under the Apache License, Version 2.0 (the "License");         
    you may not use this file except in compliance with the License.        
    You may obtain a copy of the License at                                 
                                                                            
        http://www.apache.org/licenses/LICENSE-2.0                          
                                                                            
    Unless required by applicable law or agreed to in writing, software    
    distributed under the License is distributed on an "AS IS" BASIS,       
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and     
    limitations under the License. 
    File Name   : iic_top.v
    Module Name : iic_top
*/
`include "config.v"

module iic_top(
    input clk,
    input rst_n,
    output wire iic_scl,
    inout iic_sda,
    input wire iic_reg_wr_en,
    input wire iic_reg_rd_en,
    // offset [7:0] 8'h00 scl count max 8'h04 scl sample count max 8'h08 write info 8'h10 data 8'h14 status
    // write info: [7:0] dev addr [15:8] reg addr [23:16] datalen max datalen is 4 bytes [63:24] data
    input wire [`MAX_BIT_POS:0]   iic_reg_addr,  
    input wire [`MAX_BIT_POS:0]   iic_reg_wdata,
    output reg [`MAX_BIT_POS:0]  iic_reg_rdata,
    output reg iic_ready,
    output wire data_ready_int,  // data ready interrupt
    output wire write_ready_int // write ready interrupt
);

reg [31:0] iic_scl_count_max_reg;
reg [31:0] iic_scl_sample_count_max_reg;
// [0] processing [1] data ready [2] write ready
// [3] data interrupt enable [4] write interrupt enable
// [5:] reserved
reg [`MAX_BIT_POS:0] iic_status_reg;
reg [2:0] data_offset;
reg in_data_procing;
wire [7:0] addr_offset;

assign data_ready_int = iic_status_reg[1] & iic_status_reg[3];
assign write_ready_int = iic_status_reg[2] & iic_status_reg[4];
assign addr_offset = iic_reg_addr[7:0];

localparam SCL_COUNT_MAX = 8'h00, SCL_SAMPLE_COUNT_MAX = 8'h04, WRITE_INFO_OFFSET = 8'h08, DATA_OFFSET = 8'h10, STATUS_OFFSET = 8'h14;
localparam S_IDLE = 0, S_START = 1, S_REG_ADDR = 2, S_DATA_WRITE = 3, S_START_READ = 4, S_DATA_READ = 5, S_WAITACK = 6, S_STOP = 7;

wire sample_scl;
wire scl_out;

iic_scl iic_scl_inst(
    .clk(clk),
    .rst_n(rst_n),
    .scl_count_max(iic_scl_count_max_reg),
    .scl_sample_count_max(iic_scl_sample_count_max_reg),
    .sample_scl_out(sample_scl),
    .scl_out(scl_out)
);

reg [2:0] state;
reg [2:0] next_state;
reg [2:0] after_ack_state; // state after ack

// 64 bytes tx ram， [0] rw [7:1] dev addr [15:8] reg addr [23:16] datalen [63:24] data
reg [63:0] tx_ram;
reg [31:0] rx_ram; // 4 bytes rx ram,max datalen is 4 bytes
wire [7:0] data_len;

assign data_len = tx_ram[23:16];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_ram <= 64'b0;
        iic_ready <= 1'b0;
    end
    else begin
        if (iic_reg_wr_en && !iic_ready) begin
            case (addr_offset)
                SCL_COUNT_MAX: iic_scl_count_max_reg <= iic_reg_wdata;
                SCL_SAMPLE_COUNT_MAX: iic_scl_sample_count_max_reg <= iic_reg_wdata;
                WRITE_INFO_OFFSET: tx_ram[31:0] <= iic_reg_wdata;
                DATA_OFFSET: tx_ram[63:32] <= iic_reg_wdata;
                STATUS_OFFSET: iic_status_reg <= iic_reg_wdata;
            endcase
            iic_ready <= 1'b1;
        end
        else if (iic_reg_rd_en && !iic_ready) begin
            case (addr_offset)
                DATA_OFFSET: iic_reg_rdata <= rx_ram;
                STATUS_OFFSET: iic_reg_rdata <= iic_status_reg;
            endcase
            iic_ready <= 1'b1;
        end
        else if (!iic_reg_wr_en && !iic_reg_rd_en && iic_ready) begin
            iic_ready <= 1'b0;
        end
    end
end

reg start;
reg stop;
wire proc_ing;
wire ack;
wire no_ack;
wire done;
reg [7:0] data_send;
wire [7:0] data_recv;
reg stoped;
reg is_ack;

iic_master iic_master_inst(
    .scl_in(scl_out),
    .sample_scl_reg(sample_scl),
    .rst_n(rst_n),
    .data(data_send),
    .start(start),
    .stop(stop),
    .is_ack(is_ack),
    .sda(iic_sda),
    .scl(iic_scl),
    .proc_ing(proc_ing),
    .data_out(data_recv),
    .ack(ack),
    .no_ack(no_ack),
    .done(done)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;
    end
    else begin
        state <= next_state;
    end
end

always @(*) begin
    next_state = state;
    case (state)
        S_IDLE: begin
            if (iic_reg_wr_en && addr_offset == WRITE_INFO_OFFSET && iic_status_reg[0] == 1'b0) begin
                next_state = S_START;
            end
        end
        S_START: begin
            after_ack_state = S_REG_ADDR;
            if (proc_ing) begin
                next_state = S_WAITACK;
            end
        end
        S_REG_ADDR: begin
            if (tx_ram[0]) begin
                after_ack_state = S_START_READ;
            end
            else begin
                after_ack_state = S_DATA_WRITE;
            end
            if (proc_ing) begin
                next_state = S_WAITACK;
            end
        end
        S_START_READ: begin
            after_ack_state = S_DATA_READ;
            if (proc_ing) begin
                next_state = S_WAITACK;
            end
        end
        S_DATA_READ: begin
            if (data_offset >= data_len) begin
                next_state = S_STOP;
            end
            else if(proc_ing) begin
                after_ack_state = S_DATA_READ;
                next_state = S_WAITACK;
            end
        end
        S_DATA_WRITE: begin
            if (data_offset >= data_len) begin
                next_state = S_STOP;
            end
            else if (proc_ing) begin
                after_ack_state = S_DATA_WRITE;
                next_state = S_WAITACK;
            end
        end
        S_WAITACK: begin
            if (data_offset >= data_len || no_ack) begin
                next_state = S_STOP;
            end
            else if (ack) begin
                next_state = after_ack_state;
            end
        end
        S_STOP: begin
            if (stoped) begin
                next_state = S_IDLE;
            end
        end
        default: next_state = S_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        iic_status_reg <= 0;
        start <= 1'b0;
        stop <= 1'b0;
        data_send <= 8'h00;
        data_offset <= 0;
        in_data_procing <= 1'b0;
        rx_ram <= 0;
        is_ack <= 1'b1;
    end
    else begin
        case (state)
            S_IDLE: begin
                start <= 1'b0;
                stop <= 1'b0;
                data_send <= 8'h00;
                data_offset <= 0;
                iic_status_reg[0] <= 1'b0;
                in_data_procing <= 1'b0;
                stoped <= 1'b0;
                is_ack <= 1'b1;
            end
            S_START: begin
                start <= 1'b1;
                stop <= 1'b0;
                is_ack <= 1'b1;
                iic_status_reg[0] <= 1'b1;
                data_send <= {tx_ram[7:1],1'b0};
                if (tx_ram[0]) begin
                    iic_status_reg[1] <= 1'b0;
                end
                else begin
                    iic_status_reg[2] <= 1'b0;
                end
                stoped <= 1'b0;
            end
            S_REG_ADDR: begin
                start <= 1'b0;
                stop <= 1'b0;
                data_send <= tx_ram[15:8];
                data_offset <= 0;
            end
            S_DATA_WRITE: begin
                start <= 1'b0;
                stop <= 1'b0;
                in_data_procing <= 1'b1;
                data_send <= tx_ram[((data_offset*8)+24) +: 8];
            end
            S_START_READ: begin
                start <= 1'b1;
                stop <= 1'b0;
                rx_ram <= 0;
                data_send <= {tx_ram[7:1],1'b1};
                data_offset <= 0;
            end
            S_DATA_READ: begin
                start <= 1'b0;
                stop <= 1'b0;
                in_data_procing <= 1'b1;
                if (data_offset >= (data_len - 1)) begin
                    is_ack <= 1'b0;
                end
            end
            S_WAITACK: begin
                start <= 1'b0;
                stop <= 1'b0;
                if (in_data_procing && !proc_ing) begin
                    data_offset <= data_offset + 1'b1;
                    in_data_procing <= 1'b0;
                    if (tx_ram[0]) begin
                        rx_ram[(data_offset*8) +: 8] <= data_recv;
                    end
                end
            end
            S_STOP: begin
                start <= 1'b0;
                stop <= 1'b1;
                if (done) begin
                    if (tx_ram[0]) begin
                        iic_status_reg[1] <= 1'b1;
                    end
                    else begin
                        iic_status_reg[2] <= 1'b1;
                    end
                    stoped <= 1'b1;
                end
            end
        endcase
    end
end

endmodule