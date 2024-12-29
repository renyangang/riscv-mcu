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

    File Name   : iic_slave.v
    Module Name : iic_slave
    for iic examples
*/
module iic_slave(
    input wire clk,
    input wire rst_n,
    input wire scl,
    inout wire sda,
    input [7:0] reg1_in,
    input [31:0] reg2_in,
    input reg1_w_en, reg2_w_en,
    output reg [7:0] reg1_out,
    output reg [31:0] reg2_out
);

localparam DEV_ADDR = 7'h01;
localparam REG1_ADDR = 8'h00;
localparam REG2_ADDR = 8'h01;

localparam CUR_DEV_ADDR = 0, CUR_REG_ADDR = 1, CUR_DATA = 2;

localparam S_IDLE = 0, S_START = 1, S_STOP = 2, S_DEV_ADDR = 3, S_REG_ADDR = 4, S_READ = 5, S_SEND = 6, S_WAITACK = 7, S_SENDACK = 8;

reg [3:0] state;
reg [3:0] nextstate;
reg [3:0] state_after_ack;
reg [3:0] bit_cnt; // 8bit = 1byte
reg [6:0] dev_addr_reg;
reg [7:0] reg_addr_reg;
reg [7:0] data_reg;
reg [1:0] cur_info_reg;

wire start_sig;
wire stop_sig;
wire scl_falling_edge;
wire scl_rising_edge;

reg [1:0] reg2_offset;
reg rw_reg; // 1: read, 0: write
reg ack_flag;
reg last_scl;
reg last_sda;
reg sda_out;
wire [7:0] send_data;
reg data_procing;

assign start_sig = (last_scl && scl) && (last_sda && !sda);
assign stop_sig = (last_scl && scl) && (!last_sda && sda);
assign scl_falling_edge = last_scl && !scl;
assign scl_rising_edge = !last_scl && scl;
assign sda = sda_out;
assign send_data = (reg_addr_reg == REG1_ADDR) ? reg1_out : reg2_out[reg2_offset*8+:8];


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg1_out <= 8'h00;
        reg2_out <= 32'h00000000;
    end
    else begin
        if (reg1_w_en) reg1_out <= reg1_in;
        if (reg2_w_en) reg2_out <= reg2_in;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S_IDLE;
    else state <= nextstate;
end

always @(*) begin
    if (!rst_n) begin
        nextstate = S_IDLE;
        state_after_ack = S_IDLE;
    end
    else begin
        nextstate = state;
        case (state)
            S_IDLE: begin
            end
            S_START: begin
                if (scl_falling_edge) begin
                    nextstate = S_DEV_ADDR;
                end
            end
            S_DEV_ADDR: begin
                if (bit_cnt == 0) begin
                    nextstate = S_SENDACK;
                    if (rw_reg) begin
                        state_after_ack = S_SEND;
                    end
                    else begin
                        state_after_ack = S_REG_ADDR;
                    end
                end
            end
            S_REG_ADDR: begin
                if (bit_cnt == 0) begin
                    nextstate = S_SENDACK;
                    state_after_ack = S_READ;
                end
            end
            S_READ: begin
                if (bit_cnt == 0) begin
                    nextstate = S_SENDACK;
                    state_after_ack = S_READ;
                end
            end
            S_SEND: begin
                if (bit_cnt == 0 && !scl) begin
                    nextstate = S_WAITACK;
                    state_after_ack = S_SEND;
                end
            end
            S_WAITACK: begin
                if (dev_addr_reg != DEV_ADDR) begin
                    // not my device
                    nextstate = S_IDLE;
                end
                else if (ack_flag && scl_falling_edge) begin
                    nextstate = S_SEND;
                end
                else if (scl_falling_edge) begin
                    // no ack
                    nextstate = S_IDLE;
                end
            end
            S_SENDACK: begin
                if (ack_flag && scl_falling_edge) begin
                    if (dev_addr_reg != DEV_ADDR) begin
                        // not my device
                        nextstate = S_IDLE;
                    end
                    else if (rw_reg && state_after_ack == S_REG_ADDR) begin
                        // 在start信号结束后，才能获取是读取还是写入标记
                        nextstate = S_SEND;
                    end
                    else begin
                        nextstate = state_after_ack;
                    end
                end
            end
        endcase
        if (start_sig) begin
            nextstate = S_START;
        end
        if (stop_sig) begin
            nextstate = S_IDLE;
        end
    end
end

task init_signals();
    if (1'b1) begin
        bit_cnt <= 8;
        dev_addr_reg <= 0;
        reg_addr_reg <= 0;
        data_reg <= 0;
        cur_info_reg <= 0;
        rw_reg <= 0;
        ack_flag <= 0;
        sda_out <= 1'bz;
        reg2_offset <= 0;
        data_procing <= 0;
    end
endtask;

task recv_data();
    if (last_scl && scl) begin
        data_reg[bit_cnt - 1] <= sda;
    end
    else if (scl_falling_edge) begin
            bit_cnt <= bit_cnt - 1;
    end
endtask

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        init_signals();
    end
    else begin
        last_scl <= scl;
        last_sda <= sda;
        case (state)
            S_IDLE: begin
                init_signals();
            end
            S_START: begin
                reg2_offset <= 0;
            end
            S_SENDACK: begin
                if (dev_addr_reg == DEV_ADDR) begin
                    if (!scl) begin
                        sda_out <= 1'b0;
                        ack_flag <= 1;
                    end
                end
                case (cur_info_reg)
                    CUR_DEV_ADDR: begin
                        dev_addr_reg <= data_reg[7:1];
                        rw_reg <= data_reg[0];
                    end
                    CUR_REG_ADDR: begin
                        reg_addr_reg <= data_reg;
                    end
                    CUR_DATA: begin
                        if (data_procing) begin
                            reg2_offset <= reg2_offset + 1;
                            data_procing <= 0;
                            if (reg_addr_reg == REG1_ADDR) begin
                                reg1_out <= data_reg;
                            end
                            else if (reg_addr_reg == REG2_ADDR) begin
                                reg2_out[(reg2_offset*8)+:8] <= data_reg;
                            end
                        end
                        
                    end
                endcase
                bit_cnt <= 8;
            end
            S_DEV_ADDR: begin
                cur_info_reg <= CUR_DEV_ADDR;
                sda_out <= 1'bz;
                ack_flag <= 0;
                recv_data();
            end
            S_REG_ADDR: begin
                cur_info_reg <= CUR_REG_ADDR;
                sda_out <= 1'bz;
                ack_flag <= 0;
                recv_data();
            end
            S_READ: begin
                cur_info_reg <= CUR_DATA;
                sda_out <= 1'bz;
                ack_flag <= 0;
                recv_data();
                data_procing <= 1;
            end
            S_SEND: begin
                ack_flag <= 0;
                data_procing <= 1;
                if (scl_falling_edge) begin
                    bit_cnt <= bit_cnt - 1;
                    // if (bit_cnt == 1) begin
                    //     sda_out <= 1'bz;
                    // end
                end
                if (bit_cnt >= 1) begin
                    sda_out <= send_data[bit_cnt - 1];
                end
            end
            S_WAITACK: begin
                bit_cnt <= 8;
                sda_out <= 1'bz;
                if (scl && !sda) begin
                    ack_flag <= 1;
                    if (data_procing) begin
                        reg2_offset <= reg2_offset + 1;
                        data_procing <= 0;
                    end
                end
            end
        endcase
    end
end

endmodule