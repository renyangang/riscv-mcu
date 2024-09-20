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

module ex_alu(
    input rst,
    input [4:0] rd, 
    input [31:0] rs1_data, rs2_data,
    input [19:0] imm_1231,
    input inst_addi,
    input inst_add,
    input inst_sub,
    input inst_andi,
    input inst_and,
    input inst_ori,
    input inst_or,
    input inst_xor,
    input inst_xori,
    input inst_slli,
    input inst_slti,
    input inst_sltiu,
    input inst_srai,
    input inst_srli,
    input inst_sll,
    input inst_slt,
    input inst_sltu,
    input inst_sra,
    input inst_srl,
    input inst_lui,
    output reg [4:0] rd_out,
    output reg out_en,
    output reg [31:0] rd_data
);

wire [11:0] imm_2031;
assign imm_2031 = imm_1231[19:8];

always @(*) begin
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
    else if (inst_slli || inst_sll) begin
        rd_data = rs1_data << {imm_2031[4:0]};
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
    else if (inst_srai || inst_sra) begin
        rd_data = rs1_data >>> imm_2031[4:0];
        out_en = 1'b1;
    end
    else if (inst_srli || inst_srl) begin
        rd_data = rs1_data >> imm_2031[4:0];
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
        rd_data = {{12{imm_1231[19]}}, imm_1231, 12'b0};
        out_en = 1'b1;
    end
    else begin
        out_en = 1'b0;
    end
end


always @(posedge rst) begin
    if (!rst) begin
        out_en = 0;
    end
end

endmodule