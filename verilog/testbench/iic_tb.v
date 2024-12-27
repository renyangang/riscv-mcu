`timescale 1ps/1ps

module iic_tb;

reg clk;
reg rst_n;
wire iic_scl;
wire iic_sda;
reg iic_reg_wr_en;
reg iic_reg_rd_en;
reg [31:0] iic_reg_addr;  
reg [31:0] iic_reg_wdata;
wire [31:0] iic_reg_rdata;
wire iic_ready;
wire data_ready_int;  
wire write_ready_int;

iic_top iic_top_inst(
    .clk(clk),
    .rst_n(rst_n),
    .iic_scl(iic_scl),
    .iic_sda(iic_sda),
    .iic_reg_wr_en(iic_reg_wr_en),
    .iic_reg_rd_en(iic_reg_rd_en),
    .iic_reg_addr(iic_reg_addr),
    .iic_reg_wdata(iic_reg_wdata),
    .iic_reg_rdata(iic_reg_rdata),
    .iic_ready(iic_ready),
    .data_ready_int(data_ready_int),
    .write_ready_int(write_ready_int)
);

reg reg1_w_en;
reg reg2_w_en;

reg [7:0] reg1_in;
reg [31:0] reg2_in;

wire [7:0] reg1_out;
wire [31:0] reg2_out;

iic_slave iic_slave_inst(
    .clk(clk),
    .rst_n(rst_n),
    .scl(iic_scl),
    .sda(iic_sda),
    .reg1_w_en(reg1_w_en),
    .reg2_w_en(reg2_w_en),
    .reg1_in(reg1_in),
    .reg2_in(reg2_in),
    .reg1_out(reg1_out),
    .reg2_out(reg2_out)
);

pullup(iic_sda);

initial begin
    $dumpfile("iic_tb.vcd");
    $dumpvars(0, iic_tb);
end

task set_iic_reg(input [31:0] addr, input [31:0] wdata);
    if (rst_n) begin
        iic_reg_wr_en = 1;
        iic_reg_addr = addr;
        iic_reg_wdata = wdata;
        wait(iic_ready);
        iic_reg_wr_en = 0;
        #21;
    end
endtask

initial begin
    clk = 0;
    rst_n = 0;
    reg1_w_en = 0;
    reg2_w_en = 0;
    reg1_in = 0;
    reg2_in = 0;
    iic_reg_wr_en = 0;
    iic_reg_rd_en = 0;
    iic_reg_addr = 0;
    iic_reg_wdata = 0;
    #21;
    rst_n = 1;
    #21;
    set_iic_reg(32'h00, (500000000/100000) - 1);
    set_iic_reg(32'h04, (500000000/100000/4) - 1);
    set_iic_reg(32'h14, 32'h18);
    #51;
    reg1_in = 8'h0f;
    reg1_w_en = 1;
    #51;
    set_iic_reg(32'h08, 32'h03000002);
    wait(write_ready_int);
    $display("reg1_out = %h", reg1_out);
    #100;
    $finish;
end

always #10 clk = ~clk;

endmodule