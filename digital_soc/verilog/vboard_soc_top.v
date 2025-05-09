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
*/
`include "config.v"

module vboard_soc_top(
    input  wire        clk,           // 时钟信号
    input  wire        rst_n,           // 复位信号
    input  wire        clk_timer,

    output wire  [`MAX_BIT_POS:0] digital_flash_addr,
    output wire  digital_flash_write_en,
    output wire  digital_flash_read_en,
    output wire  [2:0] digital_flash_byte_size,
    output wire  [7:0] digital_flash_wdata,
    input wire   [7:0] digital_flash_data,
    input wire   digital_flash_ready,
    output wire  [`MAX_BIT_POS:0] digital_mem_addr,
    output wire  digital_mem_write_en,
    output wire  digital_mem_read_en,
    output wire  [3:0] digital_mem_byte_size,
    output wire  [`MAX_BIT_POS:0] digital_mem_wdata,
    input wire [`MAX_BIT_POS:0] digital_mem_data,
    input wire digital_mem_ready,
    input wire [`GPIO_NUMS-1:0] gpio_values_in,
    output wire [`GPIO_NUMS-1:0] gpio_values_out,
    input wire uart_rx,
    output wire uart_tx
);
    

    // initial begin
    //     // $dumpfile("D:\\work\\v-computer\\cpu-v\\digital_soc\\verilog\\digital.vcd");
    //     $dumpfile("D:\\work\\source\\linux\\cpu-v\\digital_soc\\verilog\\digital.vcd");
    //     $dumpvars(0, vboard_soc_top);
    // end

    wire [`GPIO_NUMS-1:0] gpio_values;

    assign gpio_values_out = gpio_values;

    genvar idx;
    generate
        for (idx = 0; idx < `GPIO_NUMS; idx = idx + 1) begin
            pulldown(gpio_values[idx]);
        end
    endgenerate

    // assign gpio_values[9] = gpio_values_in[9];
    // assign gpio_values[10] = gpio_values_in[10];

    genvar i;
    generate
        for (i = 20; i < `GPIO_NUMS; i = i + 1) begin : gpio_logic
            assign gpio_values[i] = gpio_values_in[i];
        end
    endgenerate


    vboard_soc vboard_inst(
        .clk(clk),
        .rst_n(rst_n),
        .clk_timer(clk_timer),
        .digital_flash_addr(digital_flash_addr),
        .digital_flash_write_en(digital_flash_write_en),
        .digital_flash_read_en(digital_flash_read_en),
        .digital_flash_byte_size(digital_flash_byte_size),
        .digital_flash_wdata(digital_flash_wdata),
        .digital_flash_data(digital_flash_data),
        .digital_flash_ready(digital_flash_ready),
        .digital_mem_addr(digital_mem_addr),
        .digital_mem_write_en(digital_mem_write_en),
        .digital_mem_read_en(digital_mem_read_en),
        .digital_mem_byte_size(digital_mem_byte_size),
        .digital_mem_wdata(digital_mem_wdata),
        .digital_mem_data(digital_mem_data),
        .digital_mem_ready(digital_mem_ready),
        .gpio_values(gpio_values),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    


endmodule