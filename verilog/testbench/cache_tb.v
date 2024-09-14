`timescale 1ns/1ns
`include "cache.v"

module cache_tb();

    reg clk;
    reg rst_n;
    reg [31:0] addr;
    reg [31:0] data_in;
    reg write_enable;
    reg load_enable;
    reg read_enable;
    reg [127:0] write_load_data;
    reg save_ready;
    wire save_data;
    wire data_hit;
    wire status_ready;
    wire load_complate;
    wire [31:0] data_out;
    wire [127:0] write_back_data;

    initial begin            
        $dumpfile("cache.vcd"); // 指定用作dumpfile的文件
        $dumpvars; // dump all vars
    end

cache dut(
	.clk(clk),
	.rst_n(rst_n),
	.addr(addr),
	.data_in(data_in),
	.write_enable(write_enable),
	.load_enable(load_enable),
	.read_enable(read_enable),
	.write_load_data(write_load_data),
	.save_ready(save_ready),
	.save_data(save_data),
	.data_hit(data_hit),
	.status_ready(status_ready),
	.load_complate(load_complate),
	.data_out(data_out),
    .write_back_data(write_back_data)
);

    

    always #20 clk = ~clk;
    integer i;
    initial begin
        clk = 0;
        rst_n = 0;
        addr = 0;
        data_in = 0;
        write_enable = 0;
        load_enable = 0;
        write_load_data = 0;
        read_enable = 0;
        save_ready = 0;
        #21;
        rst_n = 1;
        #10;
        addr = 32'h0000_0000;
        read_enable = 1'b1;
        wait(status_ready);
        #100;
        write_load_data = 128'h0000_0000_0000_0000_0000_0000_0000_1111;
        load_enable = 1'b1;
        read_enable = 1'b0;
        wait(load_complate);
        load_enable = 1'b0;
        #100;
        addr = 32'hA000_0000;
        read_enable = 1'b1;
        wait(status_ready);
        write_load_data = 128'h0000_0000_0000_0000_0000_0000_0000_2222;
        load_enable = 1'b1;
        read_enable = 1'b0;
        wait(load_complate);
        load_enable = 1'b0;
        #100;
        addr = 32'h0000_0000;
        read_enable = 1'b1;
        wait(status_ready);
        #100;
        addr = 32'hA000_0000;
        read_enable = 1'b1;
        wait(status_ready);
         #100;
        addr = 32'h0000_0110;
        read_enable = 1'b1;
        wait(status_ready);
        write_load_data = 128'h0000_0000_0000_0000_0000_0000_0000_3333;
        load_enable = 1'b1;
        wait(load_complate);
        load_enable = 1'b0;
         #100;
        addr = 32'h0000_0110;
        read_enable = 1'b1;
        wait(status_ready);
        #100;
        addr = 32'h0000_0000;
        read_enable = 1'b1;
        wait(status_ready);
        #100;
        addr = 32'hA000_0000;
        read_enable = 1'b1;
        wait(status_ready);
        
        #101;
        $finish;
    end

endmodule