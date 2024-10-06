`timescale 1ns/1ns
`include "config.v"
`include "instruction_decoder.v"

module instdecoder_tb();
    reg [`MAX_BIT_POS:0] instruction_code;
    reg en;
    wire [`MAX_BIT_POS:0] invalid_instruction;
    wire [18:0] alu_op;
    wire [8:0] jmp_op;
    wire [8:0] mem_op;
    wire cust_op;
    wire [5:0] csr_op;
    wire [7:0] mechie_op;
    wire [4:0] rd; 
    wire [4:0] rs1; 
    wire [4:0] rs2;
    wire [6:0] imm_2531;
    wire [19:0] imm_1231;
    wire [11:0] imm_2032;

    instruction_decoder dut(
        .instruction_code(instruction_code),
        .en(en),
        .invalid_instruction(invalid_instruction),
        .alu_op(alu_op),
        .jmp_op(jmp_op),
        .mem_op(mem_op),
        .cust_op(cust_op),
        .csr_op(csr_op),
        .mechie_op(mechie_op),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm_2531(imm_2531),
        .imm_1231(imm_1231),
        .imm_2032(imm_2032)
    );

    initial begin
        $dumpfile("instdecoder.vcd");
        $dumpvars(0, instdecoder_tb);
    end

    initial begin
        en = 1;
        instruction_code = 32'd0; // invalid instruction
        #200;
        instruction_code = 32'h00000797;  // auipc	a5,0x0
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h02c78793;  // addi	a5,a5,44
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h305793f3; // csrrw	t2,mtvec,a5
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h1a5000ef; // jal	20009c4
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h00112623; // sw	ra,12(sp)
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h30200073; // mret
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h04079263; // bnez	a5,20000cc  (bne rs,x0,offset)
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h07f56513; // ori	a0,a0,127
        #200;
        instruction_code = 32'd0; 
        #10;
        instruction_code = 32'h8000007F; // cust op
        #200;
        $finish;
    end


endmodule