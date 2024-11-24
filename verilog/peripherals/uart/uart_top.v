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

Description: UART Top module

*/
`include "config.v"

module uart_top(
    input  wire        clk,
    input  wire        rst,
    input  wire        uart_rx,
    output wire        uart_tx,
    
    input wire uart_reg_wr_en,
    input wire uart_reg_rd_en,
    input wire [`MAX_BIT_POS:0]   uart_reg_addr,  // offset [7:0] 8'h00 config 8'h04 data 8'h08 data status(empty/full)
    input wire [`MAX_BIT_POS:0]   uart_reg_wdata,
    output reg [`MAX_BIT_POS:0]  uart_reg_rdata,
    output reg uart_ready,
    output wire data_ready_int,  // data ready interrupt
    output wire write_ready_int // write ready interrupt
);

reg [`MAX_BIT_POS:0] uart_clk_cfg_r;
 // [1:0] read fifo 0 empty 1 not empty 2 full 
 // [3:2] write fifo 0 empty 1 not empty 2 full 
reg [`MAX_BIT_POS:0] uart_data_status_r;

wire [15:0] uart_clk_div; // 波特率时钟分频数，整数部分  主频/(波特率 * 16)
wire [4:0] uart_clk_frag_total; // 每16个整数周期中，小数分频添加个数  (主频 % (波特率 * 16)) * 16
wire [3:0] uart_clk_frag_i; // 小数添加间隔 1 / (主频 % (波特率 * 16))
wire [1:0] parity_mode; // 0 none 1 even 2 odd
wire [1:0] stop_bit;

assign uart_clk_div = uart_clk_cfg_r[15:0];
assign uart_clk_frag_total = uart_clk_cfg_r[20:16];
assign uart_clk_frag_i = uart_clk_cfg_r[24:21];
assign parity_mode = uart_clk_cfg_r[26:25];
assign stop_bit = uart_clk_cfg_r[28:27];
// uart_clk_cfg_r[29] // data ready int enable
// uart_clk_cfg_r[30] // write ready int enable

wire clk_sample;
wire clk_uart;

wire [7:0] rx_data;
wire rx_data_ready;
reg [7:0] tx_data;
reg tx_start;

reg wr_en;
reg rd_en;
reg rd_data_flag;
wire [7:0] rd_data;
wire wr_full;
wire rd_empty;

wire [7:0] addr_offset;

assign addr_offset = uart_reg_addr[7:0];
assign data_ready_int = uart_clk_cfg_r[29] & ~rd_empty;
assign write_ready_int = uart_clk_cfg_r[30] & ~tx_fifo_full; // write ready interrupt

localparam ADDR_CONFIG = 0, ADDR_DATA = 4, ADDR_DATA_STATUS = 8;


uart_clk_div clk_div(
    .clk(clk),
    .rst(rst),
    .uart_clk_div(uart_clk_div),
    .uart_clk_frag_total(uart_clk_frag_total),
    .uart_clk_frag_i(uart_clk_frag_i),
    .clk_sample(clk_sample),
    .clk_uart(clk_uart)
);

uart_rx uart_rx_inst(
    .clk_sample(clk_sample),
    .rst(rst),
    .rx(uart_rx),
    .parity_mode(parity_mode),
    .stop_bit(stop_bit),
    .rx_data(rx_data),
    .rx_data_ready(rx_data_ready)
);

uart_tx uart_tx_inst(
    .clk_uart(clk_uart),
    .rst(rst),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .parity_mode(parity_mode),
    .stop_bit(stop_bit),
    .tx(uart_tx),
    .tx_busy(uart_tx_busy)
);

fifo_async uart_fifo(
    .wclk(clk_sample),
    .rclk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .wr_data(rx_data),
    .rd_data(rd_data),
    .wr_full(wr_full),
    .rd_empty(rd_empty)
);

reg tx_wr_en;
reg tx_rd_en;
reg tx_rd_data_flag;
reg [7:0] tx_fifo_wdata;
wire [7:0] tx_fifo_rdata;
wire tx_fifo_empty;
wire tx_fifo_full;

fifo_async uart_fifo_tx(
    .wclk(clk),
    .rclk(clk_uart),
    .rst(rst),
    .wr_en(tx_wr_en),
    .rd_en(tx_rd_en),
    .wr_data(tx_fifo_wdata),
    .rd_data(tx_fifo_rdata),
    .wr_full(tx_fifo_full),
    .rd_empty(tx_fifo_empty)
);

always @(posedge clk_uart or negedge rst) begin
    if (!rst) begin
        tx_start <= 1'b0;
        tx_rd_en <= 1'b0;
        tx_rd_data_flag <= 1'b0;
    end
    else begin
        if (tx_rd_data_flag) begin
            tx_data <= tx_fifo_rdata;
            tx_start <= 1'b1;
            tx_rd_data_flag <= 1'b0;
        end
        else if (tx_rd_en) begin
            tx_rd_en <= 1'b0;
            tx_rd_data_flag <= 1'b1;
        end
        else if (!tx_start && !tx_fifo_empty && !uart_tx_busy) begin
            tx_rd_en <= 1'b1;
            tx_start <= 1'b0;
        end
        else begin
            tx_start <= 1'b0;
            tx_rd_en <= 1'b0;
            tx_rd_data_flag <= 1'b0;
        end
    end
end

reg rx_ready_flag;
reg uart_inner_state; // 0 idle 1 wait change

always @(*) begin
    if (!rst) begin
        uart_data_status_r = 0;
    end
    else begin
        uart_data_status_r[1:0] = wr_full ? 2'd2 : rd_empty ? 2'd0 : 2'd1;
        uart_data_status_r[3:2] = tx_fifo_empty ? 2'd0 : tx_fifo_full ? 2'd2 : 2'd1;
    end
end

always @(uart_reg_addr or uart_reg_rd_en or uart_reg_wr_en or uart_reg_wdata or posedge uart_ready) begin
    if (!rst) begin
        uart_inner_state = 0;
    end
    else begin
        if (uart_ready && !uart_inner_state) begin
            uart_inner_state = 1'b1;
        end
        else begin
            uart_inner_state = 1'b0;
        end
    end
end

always @(posedge clk_sample or negedge rst) begin
    if (!rst) begin
        wr_en <= 1'b0;
        rx_ready_flag <= 1'b0;
    end
    else begin
        wr_en <= rx_data_ready && (!rx_ready_flag) && (!wr_full);
        if (rx_data_ready && (!rx_ready_flag) && (!wr_full)) begin
            rx_ready_flag <= 1'b1;
        end
        else if (!rx_data_ready) begin
            rx_ready_flag <= 1'b0;
        end
    end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        rd_en <= 1'b0;
        uart_ready <= 1'b0;
        tx_wr_en <= 1'b0;
        rd_data_flag <= 1'b0;
        uart_reg_rdata <= 0;
    end
    else begin
        if (!uart_inner_state) begin
            if (uart_reg_wr_en) begin
                rd_en <= 1'b0;
                rd_data_flag <= 1'b0;
                case (addr_offset)
                    ADDR_CONFIG: begin
                        uart_clk_cfg_r <= uart_reg_wdata;
                        uart_ready <= 1'b1;
                    end
                    ADDR_DATA: begin
                        if (tx_wr_en) begin
                            tx_wr_en <= 1'b0;
                        end
                        else if (!tx_fifo_full) begin
                            tx_fifo_wdata <= uart_reg_wdata[7:0];
                            tx_wr_en <= 1'b1;
                            uart_ready <= 1'b1;
                        end
                        else begin
                            uart_ready <= 1'b0;
                            tx_wr_en <= 1'b0;
                        end
                    end
                    default: begin
                        uart_ready <= 1'b0;
                        tx_wr_en <= 1'b0;
                    end
                endcase
            end
            else if (uart_reg_rd_en) begin
                tx_wr_en <= 1'b0;
                case (addr_offset)
                    ADDR_CONFIG: begin
                        uart_reg_rdata <= uart_clk_cfg_r;
                        uart_ready <= 1'b1;
                    end
                    ADDR_DATA_STATUS: begin
                        uart_reg_rdata <= uart_data_status_r;
                        uart_ready <= 1'b1;
                    end
                    ADDR_DATA: begin
                        if (rd_data_flag) begin
                            uart_reg_rdata[7:0] <= rd_data;
                            uart_ready <= 1'b1;
                            rd_data_flag <= 1'b0;
                        end
                        else if (rd_en) begin
                            rd_data_flag <= 1'b1;
                            rd_en <= 1'b0;
                        end
                        else if (!rd_empty) begin
                            rd_en <= 1'b1;
                            uart_ready <= 1'b0;
                            rd_data_flag <= 1'b0;
                        end
                        else begin
                            uart_ready <= 1'b0;
                            rd_data_flag <= 1'b0;
                        end
                    end
                    default: begin
                        uart_ready <= 1'b0;
                    end
                endcase
            end
            else begin
                rd_en <= 1'b0;
                uart_ready <= 1'b0;
                tx_wr_en <= 1'b0;
                rd_data_flag <= 1'b0;
            end
        end
        else begin
            rd_en <= 1'b0;
            tx_wr_en <= 1'b0;
            rd_data_flag <= 1'b0;
        end
    end
end


endmodule