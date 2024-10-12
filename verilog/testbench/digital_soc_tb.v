`timescale 1ns/1ns
`include "config.v"

module cpu_tb;
    reg clk;
    reg rst;
    reg clk_timer;

    wire  [`MAX_BIT_POS:0] digital_flash_addr;
    wire  digital_flash_write_en;
    wire  digital_flash_read_en;
    wire  [2:0] digital_flash_byte_size;
    wire  [7:0] digital_flash_wdata;
    reg  [7:0] digital_flash_data;
    wire  [`MAX_BIT_POS:0] digital_mem_addr;
    wire  digital_mem_write_en;
    wire  digital_mem_read_en;
    wire  [3:0] digital_mem_byte_size;
    wire  [`MAX_BIT_POS:0] digital_mem_wdata;
    reg  [`MAX_BIT_POS:0] digital_mem_data;
    wire  [`GPIO_NUMS-1:0] gpio_values;

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
        .digital_mem_addr(digital_mem_addr),
        .digital_mem_write_en(digital_mem_write_en),
        .digital_mem_read_en(digital_mem_read_en),
        .digital_mem_byte_size(digital_mem_byte_size),
        .digital_mem_wdata(digital_mem_wdata),
        .digital_mem_data(digital_mem_data),
        .gpio_values(gpio_values)
    );

    reg [7:0] memory [0:255];  // 假设要加载 256 个字节的内容
    integer i;

    initial begin
        // 读取 hex 文件
        $readmemh("../digital_soc/src/test.hex", memory);

        // // 打印每个字节以确保数据正确加载
        // for (i = 0; i < 256; i = i + 1) begin
        //     $display("memory[%0d] = %02x", i, memory[i]);
        // end
    end

    always @(posedge digital_flash_read_en or digital_flash_addr) begin
        if (digital_flash_read_en) begin
            digital_flash_data = memory[digital_flash_addr];
        end
        // offchip_mem_ready = 1'd1;
        // #20;
        // offchip_mem_ready = 1'd0;
    end

    initial begin            
        $dumpfile("digital_soc.vcd");
        $dumpvars; // dump all vars
    end

    initial begin
        clk = 0;
        rst = 0;
        clk_timer = 0;
        // offchip_mem_ready = 0;
        #10 rst = 1;
        
        #2500;
        $finish;
    end

    always #5 clk = ~clk;
    always #100 clk_timer = ~clk_timer;


endmodule