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

 Description: branch unit
    分支跳转指令执行单元
 */
`include "config.v"
module ex_branch(
    input rst,
    input [`MAX_BIT_POS:0] pc_cur,pc_next,
    input [4:0] rd,
    input [`MAX_BIT_POS:0] rs1_data, rs2_data,
    input [19:0] imm_1231,
    input [47:0] inst_flags,

    output reg [`MAX_BIT_POS:0] pc_next_out,
    output reg jmp_en,
    output reg [4:0] rd_out,
    output reg [`MAX_BIT_POS:0] rd_data_out,
    output reg b_n_jmp, // 用于标记未达成跳转条件的指令
    output reg rd_out_en
);

    wire [6:0] imm_2531;
    wire inst_beq;
    wire inst_bge;
    wire inst_bgeu;
    wire inst_blt;
    wire inst_bltu;
    wire inst_bne;
	wire inst_jalr;
	wire inst_jal;
	wire inst_auipc;

    assign imm_2531 = imm_1231[19:13];
    assign inst_beq = inst_flags[0];
    assign inst_bge = inst_flags[1];
    assign inst_bgeu = inst_flags[2];
    assign inst_blt = inst_flags[3];
    assign inst_bltu = inst_flags[4];
    assign inst_bne = inst_flags[5];
	assign inst_jalr = inst_flags[6];
	assign inst_jal = inst_flags[7];
	assign inst_auipc = inst_flags[8];

    always @(*) begin
        if (inst_beq) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data == rs2_data) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
            b_n_jmp = ~jmp_en;
        end
        else if (inst_bge) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = ($signed(rs1_data) >= $signed(rs2_data)) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
            b_n_jmp = ~jmp_en;
        end
        else if (inst_bgeu) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data >= rs2_data) ? 1'b1 : 1'b0;
            rd_out = 5'b0;
            b_n_jmp = ~jmp_en;
        end
        else if (inst_blt) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = ($signed(rs1_data) < $signed(rs2_data)) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
            b_n_jmp = ~jmp_en;
        end
        else if (inst_bltu) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data < rs2_data) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
            b_n_jmp = ~jmp_en;
        end
        else if (inst_bne) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data != rs2_data) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
            b_n_jmp = ~jmp_en;
        end
        else if (inst_jalr) begin
            pc_next_out = (rs1_data + {{20{imm_1231[19]}}, imm_1231[19:8]});
            pc_next_out[0] = 1'b0;
            jmp_en = 1'b1;
            rd_out = rd;
            rd_data_out = pc_next;
            rd_out_en = 1'b1;
            b_n_jmp = 1'b0;
        end
        else if (inst_jal) begin
            pc_next_out = (pc_cur + {{13{imm_1231[19]}}, imm_1231[7:1], imm_1231[8], imm_1231[18:9], 1'b0});
            jmp_en = 1'b1;
            rd_out = rd;
            rd_data_out = pc_next;
            rd_out_en = 1'b1;
            b_n_jmp = 1'b0;
        end
        else if (inst_auipc) begin
            rd_data_out = pc_cur + ({{12{imm_1231[19]}}, imm_1231[19:0]} << 12);
            jmp_en = 1'b0;
            rd_out_en = 1'b1;
            rd_out = rd;
            b_n_jmp = 1'b0;
        end
        else begin
            pc_next_out = pc_next;
            jmp_en = 1'b0;
            rd_out_en = 1'b0;
            b_n_jmp = 1'b0;
        end
    end

    always @(negedge rst) begin
        if (!rst) begin
            pc_next_out <= 32'b0;
            jmp_en <= 1'b0;
            rd_out <= 5'b0;
            rd_data_out <= 32'b0;
            rd_out_en <= 1'b0;
            b_n_jmp <= 1'b0;
        end
    end

endmodule