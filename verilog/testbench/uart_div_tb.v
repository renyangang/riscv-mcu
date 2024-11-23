`timescale 1ps/1ps

module uart_div_tb();

reg clk;
reg rst;
reg [15:0] uart_clk_div;
reg [4:0] uart_clk_frag_total; // 每16个整数周期中，多少个添加个数 
reg [3:0] uart_clk_frag_i; // 小数添加间隔
wire clk_sample;
wire clk_uart;

uart_clk_div uut (
    .clk(clk),
    .rst(rst),
    .uart_clk_div(uart_clk_div),
    .uart_clk_frag_total(uart_clk_frag_total),
    .uart_clk_frag_i(uart_clk_frag_i),
    .clk_sample(clk_sample),
    .clk_uart(clk_uart)
);

initial begin            
    $dumpfile("uart_div.vcd");
    $dumpvars; // dump all vars
end

initial begin
	clk = 0;
	rst = 0;
	uart_clk_div = 16'd27;
	uart_clk_frag_total = 5'd2;
	uart_clk_frag_i = 4'd7;
	#20;
	rst = 1;
	#30000;
	$finish;
end


always #10 clk = ~clk;

endmodule