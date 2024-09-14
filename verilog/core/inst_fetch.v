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

    output reg [31:0] cur_inst_addr,
    output reg [31:0] next_inst_addr,
    output reg [31:0] inst_code,
    output reg inst_ready,

    // 指令片外内存获取通道
    input [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data,
    input offchip_mem_ready,
    output offchip_mem_read_en,
    output [31:0] offchip_mem_addr,
    output wire offchip_mem_read_busy
 );

    // 指令返回通道
    wire [31:0] inst_data;
    wire inst_mem_ready;

    mem_controller inst_mem(
        .clk(clk),
        .rst(rst),
        .inst_mem_addr(cur_inst_addr),
        .inst_read_en(next_en | (!inst_mem_ready)),
        .inst_mem_rdata(inst_data),
        .inst_mem_ready(inst_mem_ready),
        .offchip_mem_data(offchip_mem_data),
        .offchip_mem_ready(offchip_mem_ready),
        .offchip_mem_read_en(offchip_mem_read_en),
        .offchip_mem_addr(offchip_mem_addr),
        .offchip_mem_read_busy(offchip_mem_read_busy)
    );

    always @(negedge rst) begin
        if (!rst) begin
            cur_inst_addr <= `BOOT_ADDR;
            next_inst_addr <= `BOOT_ADDR + 4;
            inst_ready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(next_en) begin
            if (jmp_en) begin
                cur_inst_addr <= jmp_pc;
                next_inst_addr <= jmp_pc + 4;
                inst_ready <= 1'b0;
            end
            else if (inst_mem_ready) begin
                cur_inst_addr <= next_inst_addr;
                next_inst_addr <= next_inst_addr + 4;
                inst_ready <= 1'b0;
            end
        end
        if (inst_mem_ready) begin
            inst_ready <= 1'b1;
            inst_code <= inst_data;
        end
    end

 endmodule