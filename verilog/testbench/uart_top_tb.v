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
	#100;
	rst = 1;
    // set baudrate to 115200
    addr1 = 32'h00000000;
    wdata1[15:0] = 16'd27;
    wdata1[20:16] = 5'd2;
    wdata1[24:21] = 4'd7;
    wdata1[26:25] = 2'd0; // parity none
    wdata1[28:27] = 2'd1; // stop bit 1
    wr_en_1 = 1;
    wait(uart_ready_1);
    #21;
    wr_en_1 = 0;
    wait(!uart_ready_1);
    #10;
    wr_en_2 = 1;
    addr2 = 32'h00000000;
    wdata2[15:0] = 16'd27;
    wdata2[20:16] = 5'd2;
    wdata2[24:21] = 4'd7;
    wdata2[26:25] = 2'd0; // parity none
    wdata2[28:27] = 2'd1; // stop bit 1
    wait(uart_ready_2);
    #21;
    wr_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    // send data
    addr1 = 32'h00000004;
    wdata1 = 32'h00000001;
    wr_en_1 = 1;
    wait(uart_ready_1);
    #21;
    wr_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    addr1 = 32'h00000004;
    wdata1 = 32'h00000002;
    wr_en_1 = 1;
    wait(uart_ready_1);
    #21;
    wr_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    addr1 = 32'h00000004;
    wdata1 = 32'h00000003;
    wr_en_1 = 1;
    wait(uart_ready_1);
    #21;
    wr_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    addr1 = 32'h00000004;
    wdata1 = 32'h00000004;
    wr_en_1 = 1;
    wait(uart_ready_1);
    #21;
    wr_en_1 = 0;
    wait(!uart_ready_1);

    // send data
    addr2 = 32'h00000004;
    wdata2 = 32'h00000019;
    wr_en_2 = 1;
    wait(uart_ready_2);
    #21;
    wr_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    addr2 = 32'h00000004;
    wdata2 = 32'h00000018;
    wr_en_2 = 1;
    wait(uart_ready_2);
    #21;
    wr_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    addr2 = 32'h00000004;
    wdata2 = 32'h00000017;
    wr_en_2 = 1;
    wait(uart_ready_2);
    #21;
    wr_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    addr2 = 32'h00000004;
    wdata2 = 32'h00000016;
    wr_en_2 = 1;
    wait(uart_ready_2);
    #21;
    wr_en_2 = 0;
    wait(!uart_ready_2);

    // read data
    wait(data_ready_int_1);
    addr1 = 32'h00000008;
    rd_en_1 = 1;
    wait(uart_ready_1);
    #21;
    rd_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    wait(data_ready_int_1);
    addr1 = 32'h00000004;
    rd_en_1 = 1;
    wait(uart_ready_1);
    #21;
    rd_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    wait(data_ready_int_1);
    addr1 = 32'h00000004;
    rd_en_1 = 1;
    wait(uart_ready_1);
    #21;
    rd_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    wait(data_ready_int_1);
    addr1 = 32'h00000004;
    rd_en_1 = 1;
    wait(uart_ready_1);
    #21;
    rd_en_1 = 0;
    wait(!uart_ready_1);
    #21;
    wait(data_ready_int_1);
    addr1 = 32'h00000004;
    rd_en_1 = 1;
    wait(uart_ready_1);
    #21;
    rd_en_1 = 0;
    wait(!uart_ready_1);

    // read data
    wait(data_ready_int_2);
    addr2 = 32'h00000008;
    rd_en_2 = 1;
    wait(uart_ready_2);
    #21;
    rd_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    wait(data_ready_int_2);
    addr2 = 32'h00000004;
    rd_en_2 = 1;
    wait(uart_ready_2);
    #21;
    rd_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    wait(data_ready_int_2);
    addr2 = 32'h00000004;
    rd_en_2 = 1;
    wait(uart_ready_2);
    #21;
    rd_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    wait(data_ready_int_2);
    addr2 = 32'h00000004;
    rd_en_2 = 1;
    wait(uart_ready_2);
    #21;
    rd_en_2 = 0;
    wait(!uart_ready_2);
    #21;
    wait(data_ready_int_2);
    addr2 = 32'h00000004;
    rd_en_2 = 1;
    wait(uart_ready_2);
    #21;
    rd_en_2 = 0;
    wait(!uart_ready_2);
    $finish;
end

always #10 clk = ~clk;

endmodule