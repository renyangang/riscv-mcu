`timescale 1ns/1ns
`include "config.v"
`include "cpu_pipeline.v"

module cpu_tb;
    reg clk;
    reg rst;
    reg clk_timer;

    // 片外内存
    reg [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data;
    reg offchip_mem_ready;
    wire [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata;
    output wire offchip_mem_write_en;
    output wire offchip_mem_read_en;
    output wire [31:0] offchip_mem_addr;

    cpu_pipeline cpu_pipeline(
        .clk(clk),
        .rst(rst),
        .clk_timer(clk_timer),
        .offchip_mem_data(offchip_mem_data),
        .offchip_mem_ready(offchip_mem_ready),
        .offchip_mem_wdata(offchip_mem_wdata),
        .offchip_mem_write_en(offchip_mem_write_en),
        .offchip_mem_read_en(offchip_mem_read_en),
        .offchip_mem_addr(offchip_mem_addr)
    );

    always @(posedge offchip_mem_read_en) begin
        offchip_mem_data = 128'h00000000002081b30010011300000093;
        #100;
        offchip_mem_ready = 1'd1;
        #100;
        offchip_mem_ready = 1'd0;
    end

    initial begin            
        $dumpfile("cpu_pipeline.vcd");
        $dumpvars; // dump all vars
    end

    initial begin
        clk = 0;
        rst = 0;
        clk_timer = 0;
        offchip_mem_ready = 0;
        #10 rst = 1;
        
        #1000;
        $finish;
    end

    always #5 clk = ~clk;
    always #100 clk_timer = ~clk_timer;


endmodule