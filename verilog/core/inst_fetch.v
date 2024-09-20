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

 Description: inst fetch
    指令取指实现
 */
 `include "config.v"
 `include "mem_controller.v"

 module inst_fetch(
    input clk,
    input rst,
    input [31:0] jmp_pc,
    input jmp_en,
    input next_en,
    // 指令返回通道
    input [31:0] inst_data,
    input inst_mem_ready,

    output reg [31:0] cur_inst_addr,
    output reg [31:0] next_inst_addr,
    output reg [31:0] inst_code,
    output reg inst_ready
 );

    always @(negedge rst) begin
        if (!rst) begin
            cur_inst_addr <= `BOOT_ADDR;
            next_inst_addr <= `BOOT_ADDR;
            inst_ready <= 1'b0;
        end
    end

    always @(negedge inst_mem_ready) begin
        inst_ready = 1'b0;
    end

    always @(posedge clk) begin
        if(next_en) begin
            if (jmp_en) begin
                next_inst_addr <= jmp_pc;
            end
            else if (inst_mem_ready && (!inst_ready)) begin
                cur_inst_addr <= next_inst_addr;
                next_inst_addr <= next_inst_addr + 4;
                inst_ready <= 1'b1;
                inst_code <= inst_data;
            end
        end
    end

 endmodule