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
    input wire [1:0] byte_size,
    input wire [`MAX_BIT_POS:0]   uart_reg_addr,
    input wire [`MAX_BIT_POS:0]   uart_reg_wdata,
    output wire [`MAX_BIT_POS:0]  uart_reg_rdata,
    output wire        uart_ready
);

reg [`MAX_BIT_POS:0] uart_clk_cfg_r;

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


wire clk_sample;
wire clk_uart;

wire [7:0] rx_data;
wire rx_data_ready;
wire [7:0] tx_data;
wire tx_start;

reg wr_en;
reg rd_en;
wire [7:0] rd_data;
wire wr_full;
wire rd_empty;


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

reg rx_ready_flag;

always @(posedge clk_sample or posedge rst) begin
    if (rst) begin
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

always @(posedge clk or posedge rst) begin
    if (rst) begin
        rd_en <= 1'b0;
    end else begin
        rd_en <= tx_start;
        end
end


endmodule