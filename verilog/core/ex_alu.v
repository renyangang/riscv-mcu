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

 Description: ex_alu.v
    计算、逻辑执行单元
 */
`include "config.v"
module ex_alu(
    input rst,
    input [4:0] rd, 
    input [`MAX_BIT_POS:0] rs1_data, rs2_data,
    input [19:0] imm_1231,
    input [47:0] inst_flags,
    
    output reg [4:0] rd_out,
    output reg out_en,
    output reg [`MAX_BIT_POS:0] rd_data
);

wire inst_addi;
wire inst_andi;
wire inst_ori;
wire inst_slli;
wire inst_slti;
wire inst_sltiu;
wire inst_srai;
wire inst_srli;
wire inst_xori;
wire inst_add;
wire inst_and;
wire inst_or;
wire inst_sll;
wire inst_slt;
wire inst_sltu;
wire inst_sra;
wire inst_srl;
wire inst_sub;
wire inst_xor;
wire inst_lui;
wire [11:0] imm_2031;
assign imm_2031 = imm_1231[19:8];

assign inst_addi = inst_flags[9];
assign inst_andi = inst_flags[10];
assign inst_ori = inst_flags[11];
assign inst_slli = inst_flags[12];
assign inst_slti = inst_flags[13];
assign inst_sltiu = inst_flags[14];
assign inst_srai = inst_flags[15];
assign inst_srli = inst_flags[16];
assign inst_xori = inst_flags[17];
assign inst_add = inst_flags[18];
assign inst_and = inst_flags[19];
assign inst_or = inst_flags[20];
assign inst_sll = inst_flags[21];
assign inst_slt = inst_flags[22];
assign inst_sltu = inst_flags[23];
assign inst_sra = inst_flags[24];
assign inst_srl = inst_flags[25];
assign inst_sub = inst_flags[26];
assign inst_xor = inst_flags[27];
assign inst_lui = inst_flags[28];

always @(*) begin
    if (rst) begin
        rd_out = rd;
        if (inst_addi) begin
            rd_data = rs1_data + {{20{imm_2031[11]}}, imm_2031};
            out_en = 1'b1;
        end
        else if (inst_add) begin
            rd_data = rs1_data + rs2_data;
            out_en = 1'b1;
        end
        else if (inst_sub) begin
            rd_data = rs1_data - rs2_data;
            out_en = 1'b1;
        end
        else if (inst_andi) begin
            rd_data = rs1_data & {{20{imm_2031[11]}}, imm_2031};
            out_en = 1'b1;
        end
        else if (inst_and) begin
            rd_data = rs1_data & rs2_data;
            out_en = 1'b1;
        end
        else if (inst_ori) begin
            rd_data = rs1_data | {{20{imm_2031[11]}}, imm_2031};
            out_en = 1'b1;
        end
        else if (inst_or) begin
            rd_data = rs1_data | rs2_data;
            out_en = 1'b1;
        end
        else if (inst_xor) begin
            rd_data = rs1_data ^ rs2_data;
            out_en = 1'b1;
        end
        else if (inst_xori) begin
            rd_data = rs1_data ^ {{20{imm_2031[11]}}, imm_2031};
            out_en = 1'b1;
        end
        else if (inst_slli) begin
            rd_data = rs1_data << {imm_2031[4:0]};
            out_en = 1'b1;
        end
        else if (inst_sll) begin
            rd_data = rs1_data << {rs2_data[4:0]};
            out_en = 1'b1;
        end
        else if (inst_slti) begin
            rd_data = ($signed(rs1_data) < {{20{imm_2031[11]}}, imm_2031}) ? 32'd1 : 32'b0;
            out_en = 1'b1;
        end
        else if (inst_sltiu) begin
            rd_data = (rs1_data < {20'b0, imm_2031}) ? 32'd1 : 32'b0;
            out_en = 1'b1;
        end
        else if (inst_srai) begin
            rd_data = rs1_data >>> imm_2031[4:0];
            out_en = 1'b1;
        end
        else if (inst_sra)  begin
            rd_data = rs1_data >>> rs2_data[4:0];
            out_en = 1'b1;
        end
        else if (inst_srli) begin
            rd_data = rs1_data >> imm_2031[4:0];
            out_en = 1'b1;
        end
        else if (inst_srl) begin
            rd_data = rs1_data >> rs2_data[4:0];
            out_en = 1'b1;
        end
        else if (inst_slt) begin
            rd_data = ($signed(rs1_data) < $signed(rs2_data)) ? 32'd1 : 32'b0;
            out_en = 1'b1;
        end
        else if (inst_sltu) begin
            rd_data = (rs1_data < rs2_data) ? 32'd1 : 32'b0;
            out_en = 1'b1;
        end
        else if (inst_lui) begin
            rd_data = {imm_1231, 12'b0};
            out_en = 1'b1;
        end
        else begin
            out_en = 1'b0;
            rd_out = 0;
            rd_data = 0;
        end
    end
    else begin
        out_en = 0;
        rd_out = 0;
        rd_data = 0;
    end
end

endmodule