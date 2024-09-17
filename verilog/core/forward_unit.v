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

 Description: forwarding unit for pipelined processor

 */

module forwarding_unit(
    input [4:0] rs1,         // 当前指令的源寄存器 1
    input [4:0] rs2,         // 当前指令的源寄存器 2
    input [4:0] rd_ex,       // 前一条指令的目的寄存器（EX 阶段）
    input [4:0] rd_mem,      // 前两条指令的目的寄存器（MEM 阶段）
    input reg_write_ex,      // 前一条指令是否会写回（EX 阶段）
    input reg_write_mem,     // 前两条指令是否会写回（MEM 阶段）
    output reg [1:0] forward_a, // 决定源寄存器 1 的转发来源
    output reg [1:0] forward_b  // 决定源寄存器 2 的转发来源
);

always @(*) begin
    // 初始化转发控制信号
    forward_a = 2'b00; // 默认从寄存器文件读取 rs1
    forward_b = 2'b00; // 默认从寄存器文件读取 rs2

    // 对 rs1 的转发逻辑
    if (reg_write_ex && (rd_ex != 0) && (rd_ex == rs1)) begin
        forward_a = 2'b10; // 从 EX 阶段转发
    end else if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs1)) begin
        forward_a = 2'b01; // 从 MEM 阶段转发
    end

    // 对 rs2 的转发逻辑
    if (reg_write_ex && (rd_ex != 0) && (rd_ex == rs2)) begin
        forward_b = 2'b10; // 从 EX 阶段转发
    end else if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs2)) begin
        forward_b = 2'b01; // 从 MEM 阶段转发
    end
end

endmodule
