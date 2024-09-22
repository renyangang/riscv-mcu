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

 Description: CPU pipeline
 */

`include "config.v"
`include "sys_bus.v"
`include "inst_fetch.v"
`include "inst_decoder.v"
`include "ex_alu.v"
`include "ex_mem.v"
`include "ex_branch.v"
`include "ex_csr.v"
`include "registers.v"

module cpu_pipeline(
    input wire clk,
    input wire rst,
    input wire clk_timer
);

    wire inst_read_en;
    wire [31:0] inst_read_addr;
    wire [31:0] inst_rdata;
    wire inst_read_ready;
    wire read_en;
    wire [31:0] mem_addr;
    wire [31:0] rdata;
    wire write_en;
    wire [31:0] wdata;
    wire [1:0] byte_size;
    wire mem_busy;
    wire mem_ready;

    reg [31:0]pc_cur;
    reg [31:0]pc_next;
    reg [31:0]inst_cur_ex;
    reg [31:0]exception_code;
    reg exception_en;
    wire [31:0] int_jmp_pc;
    wire int_jmp_en;

    reg [11:0] csr_read_addr;
    reg [31:0] csrw_data;
    reg [11:0] csrw_addr;
    reg [31:0] csr_data;
    reg csr_out_en;

    sys_bus sys_bus(
        .clk(clk),
        .rst(rst),
        .inst_read_en(inst_read_en),       
        .inst_read_addr(inst_read_addr),
        .inst_rdata(inst_rdata),
        .inst_read_ready(inst_read_ready),
        .read_en(read_en),       
        .mem_addr(mem_addr),
        .rdata(rdata),
        .write_en(write_en),
        .wdata(wdata),     
        .byte_size(byte_size),
        .mem_busy(mem_busy),
        .mem_ready(mem_ready),
        .pc(pc_cur),
        .pc_next(pc_next),
        .inst_cur(inst_cur_ex),
        .exception_code(exception_code),
        .exception_en(exception_en),
        .jmp_en(int_jmp_en),
        .jmp_pc(int_jmp_pc),
        .clk_timer(clk_timer),
        
        .csr_read_addr(csr_read_addr),
        .csrw_addr(csrw_addr),
        .w_data(csrw_data),
        .write_en(csr_out_en),
        .csr_out(csr_data)
    );

    reg [31:0] cur_inst_addr;
    reg [31:0] next_inst_addr;
    reg [31:0] inst_code;
    reg inst_ready;
    reg [31:0] jmp_pc;
    reg jmp_en;
    reg next_en;
    reg [31:0] inst_data;
    reg inst_mem_ready;

    inst_fetch inst_fetch(
        .clk(clk),
        .rst(rst),
        .jmp_pc(jmp_pc),
        .jmp_en(jmp_en),
        .next_en(next_en),
        // 指令返回通道
        .inst_data(inst_data),
        .inst_mem_ready(inst_mem_ready),

        .cur_inst_addr(cur_inst_addr),
        .next_inst_addr(next_inst_addr),
        .inst_code(inst_code),
        .inst_ready(inst_ready)
    );

    reg [31:0] instruction_code;
    reg en;
    wire [4:0] rd, rs1, rs2;
    wire [6:0] imm_2531;
    wire [19:0] imm_1231;
    wire [11:0] imm_2031;
    wire invalid_instruction;
    wire inst_beq;
    wire inst_bge;
    wire inst_bgeu;
    wire inst_blt;
    wire inst_bltu;
    wire inst_bne;
    wire inst_addi;
    wire inst_andi;
    wire inst_csrrc;
    wire inst_csrrci;
    wire inst_csrrs;
    wire inst_csrrsi;
    wire inst_csrrw;
    wire inst_csrrwi;
    wire inst_ebreak;
    wire inst_ecall;
    wire inst_jalr;
    wire inst_lb;
    wire inst_lbu;
    wire inst_lh;
    wire inst_lhu;
    wire inst_lw;
    wire inst_ori;
    wire inst_slli;
    wire inst_slti;
    wire inst_sltiu;
    wire inst_srai;
    wire inst_srli;
    wire inst_xori;
    wire inst_jal;
    wire inst_add;
    wire inst_and;
    wire inst_mret;
    wire inst_or;
    wire inst_sll;
    wire inst_slt;
    wire inst_sltu;
    wire inst_sra;
    wire inst_sret;
    wire inst_srl;
    wire inst_sub;
    wire inst_wfi;
    wire inst_xor;
    wire inst_sb;
    wire inst_sh;
    wire inst_sw;
    wire inst_auipc;
    wire inst_lui;

    inst_decoder inst_decoder(
        .clk(clk),
        .rst(rst),
        .instruction_code(instruction_code),
        .en(en),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm_2531(imm_2531),
        .imm_1231(imm_1231),
        .imm_2031(imm_2031),
        .invalid_instruction(invalid_instruction),
        .inst_beq(inst_beq),
        .inst_bge(inst_bge),
        .inst_bgeu(inst_bgeu),
        .inst_blt(inst_blt),
        .inst_bltu(inst_bltu),
        .inst_bne(inst_bne),
        .inst_addi(inst_addi),
        .inst_andi(inst_andi),
        .inst_csrrc(inst_csrrc),
        .inst_csrrci(inst_csrrci),
        .inst_csrrs(inst_csrrs),
        .inst_csrrsi(inst_csrrsi),
        .inst_csrrw(inst_csrrw),
        .inst_csrrwi(inst_csrrwi),
        .inst_ebreak(inst_ebreak),
        .inst_ecall(inst_ecall),
        .inst_jalr(inst_jalr),
        .inst_lb(inst_lb),
        .inst_lbu(inst_lbu),
        .inst_lh(inst_lh),
        .inst_lhu(inst_lhu),
        .inst_lw(inst_lw),
        .inst_ori(inst_ori),
        .inst_slli(inst_slli),
        .inst_slti(inst_slti),
        .inst_sltiu(inst_sltiu),
        .inst_srai(inst_srai),
        .inst_srli(inst_srli),
        .inst_xori(inst_xori),
        .inst_jal(inst_jal),
        .inst_add(inst_add),
        .inst_and(inst_and),
        .inst_mret(inst_mret),
        .inst_or(inst_or),
        .inst_sll(inst_sll),
        .inst_slt(inst_slt),
        .inst_sltu(inst_sltu),
        .inst_sra(inst_sra),
        .inst_sret(inst_sret),
        .inst_srl(inst_srl),
        .inst_sub(inst_sub),
        .inst_wfi(inst_wfi),
        .inst_xor(inst_xor),
        .inst_sb(inst_sb),
        .inst_sh(inst_sh),
        .inst_sw(inst_sw),
        .inst_auipc(inst_auipc),
        .inst_lui(inst_lui)
    );

    reg [4:0] inst_rd_reg;
    reg [31:0] rs1_data, rs2_data;
    reg [19:0] imm_1231_reg;
    reg inst_beq_reg;
    reg inst_bge_reg;
    reg inst_bgeu_reg;
    reg inst_blt_reg;
    reg inst_bltu_reg;
    reg inst_bne_reg;
    reg inst_addi_reg;
    reg inst_andi_reg;
    reg inst_csrrc_reg;
    reg inst_csrrci_reg;
    reg inst_csrrs_reg;
    reg inst_csrrsi_reg;
    reg inst_csrrw_reg;
    reg inst_csrrwi_reg;
    reg inst_ebreak_reg;
    reg inst_ecall_reg;
    reg inst_jalr_reg;
    reg inst_lb_reg;
    reg inst_lbu_reg;
    reg inst_lh_reg;
    reg inst_lhu_reg;
    reg inst_lw_reg;
    reg inst_ori_reg;
    reg inst_slli_reg;
    reg inst_slti_reg;
    reg inst_sltiu_reg;
    reg inst_srai_reg;
    reg inst_srli_reg;
    reg inst_xori_reg;
    reg inst_jal_reg;
    reg inst_add_reg;
    reg inst_and_reg;
    reg inst_mret_reg;
    reg inst_or_reg;
    reg inst_sll_reg;
    reg inst_slt_reg;
    reg inst_sltu_reg;
    reg inst_sra_reg;
    reg inst_sret_reg;
    reg inst_srl_reg;
    reg inst_sub_reg;
    reg inst_wfi_reg;
    reg inst_xor_reg;
    reg inst_sb_reg;
    reg inst_sh_reg;
    reg inst_sw_reg;
    reg inst_auipc_reg;
    reg inst_lui_reg;
    wire [4:0] alu_rd_out;
    wire alu_rd_out_en;
    wire [31:0] alu_rd_data;

    ex_alu alu(
        .rst(rst),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_1231(imm_1231_reg),
        .inst_addi(inst_addi_reg),
        .inst_add(inst_add_reg),
        .inst_sub(inst_sub_reg),
        .inst_andi(inst_andi_reg),
        .inst_and(inst_and_reg),
        .inst_ori(inst_ori_reg),
        .inst_or(inst_or_reg),
        .inst_xor(inst_xori_reg),
        .inst_xori(inst_xor_reg),
        .inst_slli(inst_slli_reg),
        .inst_slti(inst_slti_reg),
        .inst_sltiu(inst_sltiu_reg),
        .inst_srai(inst_srai_reg),
        .inst_srli(inst_srli_reg),
        .inst_sll(inst_sll_reg),
        .inst_slt(inst_slt_reg),
        .inst_sltu(inst_sltu_reg),
        .inst_sra(inst_sra_reg),
        .inst_srl(inst_srl_reg),
        .inst_lui(inst_lui_reg),
        .rd_out(alu_rd_out),
        .out_en(alu_rd_out_en),
        .rd_data(alu_rd_data)
    );

    

    wire [31:0] branch_pc_next_out;
    wire branch_jmp_en;
    wire [4:0] branch_rd_out;
    wire [31:0] branch_rd_data_out;
    wire branch_rd_out_en;

    ex_branch ex_branch(
        .rst(rst),
        .pc_cur(pc_cur),
        .pc_next(pc_next),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_1231(imm_1231_reg),
        .inst_beq(inst_beq_reg),
        .inst_bge(inst_bge_reg),
        .inst_bgeu(inst_bgeu_reg),
        .inst_blt(inst_blt_reg),
        .inst_bltu(inst_bltu_reg),
        .inst_bne(inst_bne_reg),
        .inst_jalr(inst_jalr_reg),
        .inst_jal(inst_jal_reg),
        .inst_auipc(inst_auipc_reg),
        .rd_out(branch_rd_out),
        .rd_out_en(branch_rd_out_en),
        .rd_data_out(branch_rd_data_out),
        .pc_next_out(branch_pc_next_out),
        .jmp_en(branch_jmp_en)
    );

    reg  [4:0] mem_rd_out;
    reg mem_rd_en;
    reg [31:0] mem_rd_data;
    reg [1:0] mem_byte_size;
    reg [31:0] ex_mem_data;
    reg [31:0] ex_mem_addr;
    reg ex_mem_write_en;
    reg ex_mem_read_en;

    ex_mem ex_mem(
        .clk(clk),
        .rst(rst),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_2031(imm_1231_reg[19:8]),

        .inst_lb(inst_lb_reg),
        .inst_lbu(inst_lbu_reg),
        .inst_lh(inst_lh_reg),
        .inst_lhu(inst_lhu_reg),
        .inst_lw(inst_lw_reg),
        .inst_sb(inst_sb_reg),
        .inst_sh(inst_sh_reg),
        .inst_sw(inst_sw_reg),

        .mem_data_in(rdata),
        .mem_read_ready(mem_ready),
        .mem_write_ready(mem_ready),

        .rd_out(mem_rd_out),
        .rd_en(mem_rd_en),
        .rd_data(mem_rd_data),
        .byte_size(mem_byte_size),
        .mem_data(ex_mem_data),
        .mem_addr(ex_mem_addr),
        .mem_write_en(ex_mem_write_en),
        .mem_read_en(ex_mem_read_en)
    );

    reg [4:0] csr_rd_out;
    reg csr_rd_out_en;
    reg [31:0] csr_rd_data;
    

    ex_csr ex_csr(
        .rst(rst),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .csr_data(csr_data),
        .imm_2031(imm_1231_reg[19:8]),
        .imm_1519(imm_1231_reg[7:3]),
        .inst_csrrw(inst_csrrw_reg),
        .inst_csrrs(inst_csrrs_reg),
        .inst_csrrc(inst_csrrc_reg),
        .inst_csrrwi(inst_csrrwi_reg),
        .inst_csrrsi(inst_csrrsi_reg),
        .inst_csrrci(inst_csrrci_reg),
        .rd_out(csr_rd_out),
        .out_en(csr_rd_out_en),
        .rd_data(csr_rd_data),
        .csr_out_en(csr_out_en),
        .csrw_data(csrw_data),
        .csrw_addr(csrw_addr)
    );


endmodule