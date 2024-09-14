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

module ex_csr(
    input clk, rst,
    input [4:0] rd,
    input [4:0] imm_1519,
    input [31:0] rs1_data, csr_data,
    input [11:0] imm_2031,
    input inst_csrrc,
    input inst_csrrci,
    input inst_csrrs,
    input inst_csrrsi,
    input inst_csrrw,
    input inst_csrrwi,
    output reg [4:0] rd_out,
    output reg out_en,
    output reg [31:0] rd_data,
    output reg csr_out_en,
    output reg [31:0] csrw_data,
    output reg [11:0] csrw_addr
);


always @(posedge clk or posedge rst) begin
    if (!rst) begin
        out_en <= 0;
    end
    else begin
        rd_out <= rd;
        csrw_addr <= imm_2031;
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
        else if (inst_csrrs) begin
            out_en <= 1'b1;
            rd_data <= csr_data | (1 << imm_2031);
        end
        else if (inst_csrrsi) begin
            out_en <= 1'b1;
            rd_data <= csr_data | (1 << rs1_data);
        end
        else if (inst_csrrw) begin
            out_en <= 1'b1;
            rd_data <= imm_2031;
        end
        else if (inst_csrrwi) begin
            out_en <= 1'b1;
            rd_data <= rs1_data;
        end
        else begin
            out_en <= 1'b0;
            csr_out_en <= 1'b0;
        end
    end
end

endmodule