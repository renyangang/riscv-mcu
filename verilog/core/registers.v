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

 Description: register file
    寄存器文件 x0-x31, 32个32位寄存器
    写入读取都是单周期完成
 */

 module registers(
    input wire clk,
    input wire rst,
    input wire [4:0] rs1_addr,
    input wire [4:0] rs2_addr,
    input wire [4:0] rd_addr,
    input wire [31:0] rd_data,
    input wire rd_en,
    output wire [31:0] rs1_out,
    output wire [31:0] rs2_out
    );
    reg [31:0] reg_file[31:0];
    integer i;
    wire [31:0] x1_out;
    wire [31:0] x2_out;


    assign rs1_out = (rs1_addr == 5'd0) ? 32'd0 : reg_file[rs1_addr];
    assign rs2_out = (rs2_addr == 5'd0) ? 32'd0 : reg_file[rs2_addr];

    assign x1_out = reg_file[1];
    assign x2_out = reg_file[2];

    always @(posedge clk) begin
        if (!rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_file[i] <= 32'h00000000;
            end
        end
        else begin 
            if (rd_en & (rd_addr != 5'd0)) begin
                reg_file[rd_addr] <= rd_data;
            end
        end
    end
endmodule