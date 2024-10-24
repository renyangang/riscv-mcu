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
    reg digital_flash_ready;
    wire  [`MAX_BIT_POS:0] digital_mem_addr;
    wire  digital_mem_write_en;
    wire  digital_mem_read_en;
    wire  [3:0] digital_mem_byte_size;
    wire  [`MAX_BIT_POS:0] digital_mem_wdata;
    reg  [`MAX_BIT_POS:0] digital_mem_data;
    reg digital_mem_ready;
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

    reg [7:0] flash [0:4000];
    reg [7:0] memory [0:8000];
    integer i;

    initial begin
        // 读取 hex 文件
        $readmemh("../digital_soc/src/test.hex", flash);

        for(i=0;i<8000;i=i+1) begin
            memory[i] = 0;
        end
    end

    always @(posedge digital_mem_write_en or digital_mem_addr or posedge digital_mem_read_en) begin
        digital_mem_ready = 1'd0;
        if (digital_mem_write_en) begin
            memory[{digital_mem_addr[15:0]}] = digital_mem_wdata;
            digital_mem_ready = 1'd1;
        end
        if (digital_mem_read_en) begin
            digital_mem_data = memory[{digital_mem_addr[15:0]}];
            digital_mem_ready = 1'd1;
        end
    end

    always @(posedge digital_flash_read_en or digital_flash_addr) begin
        digital_flash_ready = 1'd0;
        if (digital_flash_read_en) begin
            digital_flash_data = flash[digital_flash_addr];
            digital_flash_ready = 1'd1;
        end
        // offchip_mem_ready = 1'd1;
        // #20;
        // offchip_mem_ready = 1'd0;
    end

    initial begin            
        $dumpfile("digital_soc.vcd");
        $dumpvars; // dump all vars
    end

    genvar idx;
    generate
        for (idx = 0; idx < `GPIO_NUMS; idx = idx + 1) begin
            pulldown(gpio_values[idx]);
        end
    endgenerate

    initial begin
        clk = 0;
        rst = 0;
        clk_timer = 0;
        digital_flash_ready = 1'd0;
        digital_mem_ready = 1'd0;
        
        // offchip_mem_ready = 0;
        #10 rst = 1;
        
        #25000;
        $finish;
    end

    always #5 clk = ~clk;
    always #20 clk_timer = ~clk_timer;


endmodule