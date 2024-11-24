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
`timescale 1ns/1ns

module uart_top_tb();

reg clk;
reg rst;
wire uart_rx;
wire uart_tx;
reg wr_en_1;
reg rd_en_1;
reg wr_en_2;
reg rd_en_2;
reg [31:0]   addr1;  // offset [7:0] 8'h00 config 8'h04 data 8'h08 data status(empty/full)
reg [31:0]   wdata1;
wire [31:0]  rdata1;
wire uart_ready_1;
wire  data_ready_int_1;  // data ready interrupt
reg [31:0]   addr2;  // offset [7:0] 8'h00 config 8'h04 data 8'h08 data status(empty/full)
reg [31:0]   wdata2;
wire [31:0]  rdata2;
wire uart_ready_2;
wire  data_ready_int_2;  // data ready interrupt

uart_top dut(
	.clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx),
    .uart_reg_wr_en(wr_en_1),
    .uart_reg_rd_en(rd_en_1),
    .uart_reg_addr(addr1),
    .uart_reg_wdata(wdata1),
    .uart_reg_rdata(rdata1),
    .uart_ready(uart_ready_1),
    .data_ready_int(data_ready_int_1)
);

uart_top dut1(
	.clk(clk),
    .rst(rst),
    .uart_rx(uart_tx),
    .uart_tx(uart_rx),
    .uart_reg_wr_en(wr_en_2),
    .uart_reg_rd_en(rd_en_2),
    .uart_reg_addr(addr2),
    .uart_reg_wdata(wdata2),
    .uart_reg_rdata(rdata2),
    .uart_ready(uart_ready_2),
    .data_ready_int(data_ready_int_2)
);

initial begin            
    $dumpfile("uart_top.vcd");
    $dumpvars; // dump all vars
end


reg [31:0] uart_config;
reg [31:0] uart_data;

task uart1_send(
    input [31:0] data,
    input [31:0] addr
);
    if (rst) begin
        addr1 = addr;
        wdata1 = data;
        wr_en_1 = 1;
        wait(uart_ready_1);
        #21;
        wr_en_1 = 0;
        wait(!uart_ready_1);
    end
endtask

task uart2_send(
    input [31:0] data,
    input [31:0] addr
);
    if (rst) begin
        addr2 = addr;
        wdata2 = data;
        wr_en_2 = 1;
        wait(uart_ready_2);
        #21;
        wr_en_2 = 0;
        wait(!uart_ready_2);
    end
endtask

task uart1_read(
    input [31:0] addr
);
    if (rst) begin
        wait(data_ready_int_1);
        addr1 = addr;
        rd_en_1 = 1;
        wait(uart_ready_1);
        #21;
        rd_en_1 = 0;
        wait(!uart_ready_1);
    end
endtask

task uart2_read(
    input [31:0] addr
);
    if (rst) begin
        wait(data_ready_int_2);
        addr2 = addr;
        rd_en_2 = 1;
        wait(uart_ready_2);
        #21;
        rd_en_2 = 0;
        wait(!uart_ready_2);
    end
endtask

integer i,j;

initial begin
	clk = 0;
	rst = 0;
    wr_en_1 = 0;
	rd_en_1 = 0;
	wr_en_2 = 0;
	rd_en_2 = 0;
	addr1 = 0;
	addr2 = 0;
	wdata1 = 0;
	wdata2 = 0;
    uart_config[15:0] = 16'd27;
    uart_config[20:16] = 5'd2;
    uart_config[24:21] = 4'd7;
    uart_config[26:25] = 2'd0; // parity none
    uart_config[28:27] = 2'd1; // stop bit 1
    uart_config[29] = 1'd1; // data read interrupt enable
    uart_config[31:30] = 2'd0;
	#100;
	rst = 1;
    // set baudrate to 115200
    uart1_send(uart_config, 32'h00000000);
    #10;
    uart2_send(uart_config, 32'h00000000);

    #21;
    // send data
    for (i = 0; i < 10; i = i + 1) begin
        uart1_send(i, 32'h00000004);
        #21;
    end
    for (i = 32'h80; i < 32'h90; i = i + 1) begin
        uart2_send(i, 32'h00000004);
        #21;
    end

    // read data
    #21;
    uart1_read(32'h00000008);
    #21;
    for (i = 0; i < 10; i = i + 1) begin
        uart1_read(32'h00000004);
        #21;
    end
    #21;
    // read data
    uart2_read(32'h00000008);
    #21;
    for (i = 0; i < 10; i = i + 1) begin
        uart2_read(32'h00000004);
        #21;
    end

    $finish;
end

always #10 clk = ~clk;

endmodule