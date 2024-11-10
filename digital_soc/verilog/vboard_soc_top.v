`include "config.v"

module vboard_soc_top(
    input  wire        clk,           // 时钟信号
    input  wire        rst,           // 复位信号
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
    inout wire [`GPIO_NUMS-1:0] gpio_values
);
    

    initial begin
        $dumpfile("D:\\work\\v-computer\\cpu-v\\digital_soc\\verilog\\digital.vcd");
        // $dumpfile("D:\\work\\source\\linux\\cpu-v\\digital_soc\\verilog\\digital.vcd");
        $dumpvars(0, vboard_soc_top);
    end


    digital_soc digital_soc(
        .clk(clk),
        .rst(rst),
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
        .gpio_values(gpio_values)
    );

    


endmodule