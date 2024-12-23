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

Description: vboard soc
    封装用于fpga vboard虚拟开发板的soc
*/

 `include "config.v"

module vboard_soc(
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
    inout wire [`GPIO_NUMS-1:0] gpio_values,
    input uart_rx,
    output uart_tx
);

    wire [`MAX_BIT_POS:0] io_addr;
    wire io_read;
    wire io_write;
    wire burst;
    wire [2:0] burst_size;
    wire read_ready;
    wire [`MAX_BIT_POS:0] io_wdata;
    wire [1:0] io_byte_size;
    wire  [`MAX_BIT_POS:0] io_rdata;
    wire  io_ready;
    wire [`INT_CODE_WIDTH-1:0]peripheral_int_code;

cpu_top cpu(
    .clk(clk),
    .rst_n(rst_n),
    .clk_timer(clk_timer),
    .io_addr(io_addr),
    .io_read(io_read),
    .io_write(io_write),
    .burst(burst),
    .burst_size(burst_size),
    .read_ready(read_ready),
    .io_wdata(io_wdata),
    .io_byte_size(io_byte_size),
    .io_rdata(io_rdata),
    .io_ready(io_ready),
    .peripheral_int_code(peripheral_int_code)
);

peripherals_bus peripherals_bus(
    .pclk(clk),
    .rst_n(rst_n),
    .io_addr(io_addr),
    .io_read(io_read),
    .io_write(io_write),
    .burst(burst),
    .burst_size(burst_size),
    .read_ready(read_ready),
    .io_wdata(io_wdata),
    .io_byte_size(io_byte_size),
    .io_rdata(io_rdata),
    .io_ready(io_ready),
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
    .uart_tx(uart_tx),
    .peripheral_int_code(peripheral_int_code)
);

endmodule