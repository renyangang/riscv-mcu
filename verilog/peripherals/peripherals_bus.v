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

 Description: peripherals bus

 */
`include "config.v"
`define INIT_ENS \
    flash_io_read = 0; \
    flash_io_write = 0; \
    mem_io_read = 0; \
    mem_io_write = 0; \
    gpio_read = 0; \
    gpio_write = 0; \
    uart_wr_en = 0; \
    uart_rd_en = 0;
module peripherals_bus(
    input wire pclk,
    input wire rst_n,
    input wire [`MAX_BIT_POS:0] io_addr,
    input wire io_read,
    input wire io_write,
    input wire burst,
    input wire [2:0] burst_size,
    input wire read_ready,
    input wire [`MAX_BIT_POS:0] io_wdata,
    input wire [1:0] io_byte_size,
    output wire [`MAX_BIT_POS:0] io_rdata,
    output wire io_ready,
    
    //digital外部接口
    output wire [`MAX_BIT_POS:0] digital_flash_addr,
    output wire digital_flash_write_en,
    output wire digital_flash_read_en,
    output wire [2:0] digital_flash_byte_size,
    output wire [7:0] digital_flash_wdata,
    input wire [7:0] digital_flash_data,
    input wire digital_flash_ready,
    //digital外部接口
    output wire [`MAX_BIT_POS:0] digital_mem_addr,
    output wire digital_mem_write_en,
    output wire digital_mem_read_en,
    output wire [3:0] digital_mem_byte_size,
    output wire [`MAX_BIT_POS:0] digital_mem_wdata,
    input wire [`MAX_BIT_POS:0] digital_mem_data,
    input wire digital_mem_ready,
    inout wire [`GPIO_NUMS-1:0] gpio_values,

    input uart_rx,
    output uart_tx,

    output reg [`INT_CODE_WIDTH-1:0]peripheral_int_code
);

task addr_mapping();
    /* verilator lint_off UNSIGNED */
    if (io_addr >= `FLASH_ADDR_BASE && io_addr <= `FLASH_ADDR_END) begin
        flash_io_read = io_read;
        flash_io_write = io_write;
    end 
    else if (io_addr >= `TIMER_ADDR_BASE && io_addr <= `TIMER_ADDR_END) begin
        // do nothing
    end 
    else if (io_addr >= `SDRAM_ADDR_BASE && io_addr <= `SDRAM_ADDR_END) begin
        mem_io_read = io_read;
        mem_io_write = io_write;
    end 
    else if (io_addr >= `GPIO_ADDR_BASE && io_addr <= `GPIO_ADDR_END) begin
        gpio_read = io_read;
        gpio_write = io_write;
    end 
    else if (io_addr >= `UART_ADDR_BASE && io_addr <= `UART_ADDR_END) begin
        uart_wr_en = io_write;
        uart_rd_en = io_read;
    end
endtask

/* verilator lint_off UNOPTFLAT */
assign io_rdata = (gpio_read || gpio_write) ? gpio_rdata : (flash_io_read || flash_io_write) ? flash_io_rdata : (mem_io_read || mem_io_write) ? mem_io_rdata : (uart_wr_en || uart_rd_en) ? uart_reg_rdata : `XLEN'd0;
assign io_ready = (gpio_read || gpio_write) ? gpio_ready : (flash_io_read || flash_io_write) ? flash_io_ready : (mem_io_read || mem_io_write) ? mem_io_ready : (uart_wr_en || uart_rd_en) ? uart_ready : 1'b0;

always @(io_addr or io_read or io_write) begin
    `INIT_ENS
    addr_mapping();
end

always @(negedge rst_n) begin
    if (!rst_n) begin
        `INIT_ENS
    end
end

always @(gpio_int) begin
    if (gpio_int) begin
        peripheral_int_code <= `INT_CODE_GPIO;
    end
    else if (data_ready_int) begin
        peripheral_int_code <= `INT_CODE_UART1_RX_READY;
    end
    else if (write_ready_int) begin
        peripheral_int_code <= `INT_CODE_UART1_TX_READY;
    end
    else begin
        peripheral_int_code <= `INT_CODE_NONE;
    end
end

wire gpio_int; // gpio interrupt
reg gpio_read;
reg gpio_write;
wire [`MAX_BIT_POS:0] gpio_rdata;
wire gpio_ready;


gpio_controller gpio_controller_inst(
    .gpio_clk(pclk),
    .rst_n(rst_n),
    .io_addr(io_addr),
    .io_read(gpio_read),
    .io_write(gpio_write),
    .read_ready(read_ready),
    .io_wdata(io_wdata),
    .io_rdata(gpio_rdata),
    .io_ready(gpio_ready),
    .gpio_values(gpio_values),
    .gpio_int(gpio_int)
);

    reg mem_io_read;
    reg mem_io_write;
    wire [`MAX_BIT_POS:0] mem_io_rdata;
    wire mem_io_ready;

digital_ram ram(
    .ramclk(pclk),
    .rst_n(rst_n),
    .mem_io_addr(io_addr),
    .mem_io_read(mem_io_read),
    .mem_io_write(mem_io_write),
    .mem_read_ready(read_ready),
    .mem_io_wdata(io_wdata),
    .io_byte_size(io_byte_size),
    .mem_io_rdata(mem_io_rdata),
    .mem_io_ready(mem_io_ready),
    .digital_mem_addr(digital_mem_addr),
    .digital_mem_write_en(digital_mem_write_en),
    .digital_mem_read_en(digital_mem_read_en),
    .digital_mem_byte_size(digital_mem_byte_size),
    .digital_mem_wdata(digital_mem_wdata),
    .digital_mem_data(digital_mem_data),
    .digital_mem_ready(digital_mem_ready)
);

    reg flash_io_read;
    reg flash_io_write;
	wire [`MAX_BIT_POS:0] flash_io_rdata;
    wire flash_io_ready;

digital_flash flash(
    .flashclk(pclk),
    .rst_n(rst_n),
    .flash_io_addr(io_addr),
    .flash_io_read(flash_io_read),
    .flash_io_write(flash_io_write),
    .flash_read_ready(read_ready),
    .flash_io_wdata(io_wdata),
    .io_byte_size(io_byte_size),
    .flash_io_rdata(flash_io_rdata),
    .flash_io_ready(flash_io_ready),
    .digital_flash_addr(digital_flash_addr),
    .digital_flash_write_en(digital_flash_write_en),
    .digital_flash_read_en(digital_flash_read_en),
    .digital_flash_byte_size(digital_flash_byte_size),
    .digital_flash_wdata(digital_flash_wdata),
    .digital_flash_data(digital_flash_data),
    .digital_flash_ready(digital_flash_ready)
);

reg uart_wr_en;
reg uart_rd_en;
wire uart_ready;
wire data_ready_int;
wire write_ready_int;
wire [`MAX_BIT_POS:0] uart_reg_rdata;

uart_top dut(
	.clk(pclk),
    .rst_n(rst_n),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .uart_reg_wr_en(uart_wr_en),
    .uart_reg_rd_en(uart_rd_en),
    .uart_reg_addr(io_addr),
    .uart_reg_wdata(io_wdata),
    .uart_reg_rdata(uart_reg_rdata),
    .uart_ready(uart_ready),
    .data_ready_int(data_ready_int),
    .write_ready_int(write_ready_int)
);

endmodule