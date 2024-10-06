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

 Description: ex_csr.v
    CSR寄存器执行单元
 */
`include "config.v"
module ex_csr (
    input rst,
    input [4:0] rd,
    input [4:0] imm_1519,
    input [`MAX_BIT_POS:0] rs1_data, csr_data,
    input [11:0] imm_2031,
    input [47:0] inst_flags,
    output reg [4:0] rd_out,
    output reg out_en,
    output reg [`MAX_BIT_POS:0] rd_data,
    output reg csr_out_en,
    output reg [`MAX_BIT_POS:0] csrw_data,
    output reg [11:0] csrw_addr
);

    wire inst_csrrc; 
    wire inst_csrrci;
    wire inst_csrrs;
    wire inst_csrrsi;
    wire inst_csrrw;
    wire inst_csrrwi;

    assign inst_csrrc = inst_flags[37];
    assign inst_csrrci = inst_flags[38];
    assign inst_csrrs = inst_flags[39];
    assign inst_csrrsi = inst_flags[40];
    assign inst_csrrw = inst_flags[41];
    assign inst_csrrwi = inst_flags[42];

always @(*) begin
    rd_out = rd;
    csrw_addr = imm_2031;
    if (inst_csrrc) begin
        out_en <= 1'b1;
        csr_out_en <= 1'b1;
        rd_data <= csr_data;
        csrw_data <= csr_data & ~rs1_data;
    end
    else if (inst_csrrci) begin
        out_en <= 1'b1;
        csr_out_en <= 1'b1;
        rd_data <= csr_data;
        csrw_data <= csr_data & ~{27'b0,imm_1519};
    end
    else if (inst_csrrsi) begin
        out_en <= 1'b1;
        csr_out_en <= 1'b1;
        csrw_data <= csr_data & {27'b0,imm_1519};
        rd_data <= csr_data;
    end
    else if (inst_csrrs) begin
        out_en <= 1'b1;
        csr_out_en <= 1'b1;
        csrw_data <= csr_data & rs1_data;
        rd_data <= csr_data;
    end
    else if (inst_csrrwi) begin
        out_en <= 1'b1;
        csr_out_en <= 1'b1;
        csrw_data <= {27'b0,imm_1519};
        rd_data <= csr_data;
    end
    else if (inst_csrrw) begin
        out_en <= 1'b1;
        csr_out_en <= 1'b1;
        csrw_data <= rs1_data;
        rd_data <= csr_data;
    end
    else begin
        out_en = 1'b0;
        csr_out_en = 1'b0;
    end
end

always @(posedge rst) begin
    if (!rst) begin
        out_en <= 0;
        csr_out_en <= 1'b0;
    end
end

endmodule