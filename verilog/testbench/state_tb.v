`timescale 1ns/1ns
`include "config.v"
`include "cpu_pipeline.v"

module cpu_tb;
    reg clk;
    reg rst;

    initial begin            
        $dumpfile("state.vcd");
        $dumpvars; // dump all vars
    end

    initial begin
        clk = 0;
        rst = 0;
        #10 rst = 1;
        
        #500;
        $finish;
    end

    always #5 clk = ~clk;


endmodule