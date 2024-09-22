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

module ex_branch(
    input rst,
    input [31:0] pc_cur,pc_next,
    input [4:0] rd,
    input [31:0] rs1_data, rs2_data,
    input [19:0] imm_1231,
    input inst_beq,
    input inst_bge,
    input inst_bgeu,
    input inst_blt,
    input inst_bltu,
    input inst_bne,
    input inst_jalr,
    input inst_jal,
    input inst_auipc,

    output reg [31:0] pc_next_out,
    output reg jmp_en,
    output reg [4:0] rd_out,
    output reg [31:0] rd_data_out,
    output reg rd_out_en
);

    wire [6:0] imm_2531;

    assign imm_2531 = imm_1231[19:13];

    always @(inst_beq or inst_bge or inst_bgeu or inst_blt or inst_bltu or inst_bne or inst_jalr or inst_jal or inst_auipc) begin
        if (inst_beq) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data == rs2_data) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
        end
        else if (inst_bge) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = ($signed(rs1_data) >= $signed(rs2_data)) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
        end
        else if (inst_bgeu) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data >= rs2_data) ? 1'b1 : 1'b0;
            rd_out = 5'b0;
        end
        else if (inst_blt) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = ($signed(rs1_data) < $signed(rs2_data)) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
        end
        else if (inst_bltu) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data < rs2_data) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
        end
        else if (inst_bne) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, rd[0], imm_2531[5:0], rd[4:1], 1'b0});
            jmp_en = (rs1_data != rs2_data) ? 1'b1 : 1'b0;
            rd_out_en = 1'b0;
        end
        else if (inst_jalr) begin
            pc_next_out = (pc_cur + {{20{imm_2531[6]}}, imm_1231[19:8]});
            pc_next_out[0] = 1'b0;
            jmp_en = 1'b1;
            rd_out = rd;
            rd_data_out = pc_next;
            rd_out_en = 1'b1;
        end
        else if (inst_jal) begin
            pc_next_out = (pc_cur + {{13{imm_1231[19]}}, imm_1231[7:1], imm_1231[8], imm_1231[18:9], 1'b0});
            jmp_en = 1'b1;
            rd_out = rd;
            rd_data_out = pc_next;
            rd_out_en = 1'b1;
        end
        else if (inst_auipc) begin
            rd_data_out = pc_cur + ({{12{imm_1231[19]}}, imm_1231[19:0]} << 12);
            jmp_en = 1'b0;
            rd_out_en = 1'b1;
            rd_out = rd;
        end
        else begin
            pc_next_out = pc_next;
            jmp_en = 1'b0;
            rd_out_en = 1'b0;
        end
    end

    always @(negedge rst) begin
        if (!rst) begin
            pc_next_out <= 32'b0;
            jmp_en <= 1'b0;
            rd_out <= 5'b0;
            rd_data_out <= 32'b0;
            rd_out_en <= 1'b0;
        end
    end

endmodule