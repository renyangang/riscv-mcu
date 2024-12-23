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
`timescale 1ps/1ps

module uart_div_tb();

reg clk;
reg rst_n;
reg [15:0] uart_clk_div;
reg [4:0] uart_clk_frag_total; // 每16个整数周期中，多少个添加个数 
reg [3:0] uart_clk_frag_i; // 小数添加间隔
wire clk_sample;
wire clk_uart;

uart_clk_div uut (
    .clk(clk),
    .rst_n(rst_n),
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
	rst_n = 0;
	uart_clk_div = 16'd27;
	uart_clk_frag_total = 5'd2;
	uart_clk_frag_i = 4'd7;
	#20;
	rst_n = 1;
	#30000;
	$finish;
end


always #10 clk = ~clk;

endmodule