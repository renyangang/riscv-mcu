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

 module inst_fetch(
    input clk,
    input rst,
    input [31:0] jmp_pc,
    input jmp_en,
    input next_en,
    // 指令返回通道
    input [31:0] inst_data,
    input inst_mem_ready,

    output reg inst_mem_read_en,
    output reg [31:0] cur_inst_addr,
    output reg [31:0] next_inst_addr,
    output wire [31:0] inst_code,
    output reg control_hazard,
    output wire inst_ready
 );

    reg fetch_stop;

    assign inst_ready = inst_mem_ready;
    assign inst_code = (inst_data !== 32'hz) ? inst_data : 32'd0;


    task branch_prediction();
        if (inst_data[6:0] == 7'b1100011) begin
            // 分支跳转指令，进行静态预测， 向后统一预测为跳转，向前统一预测为不跳转
            fetch_stop = inst_data[31];
            // 如果预测不跳转，则设置冒险标记
            control_hazard = ~(inst_data[31]);
        end
        else if (inst_data[6:0] == 7'b1101111 || inst_data[6:0] == 7'b1100111) begin
            fetch_stop = 1'b1; // 等待跳转
        end
    endtask

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cur_inst_addr <= `BOOT_ADDR;
            next_inst_addr <= `BOOT_ADDR + 4;
            inst_mem_read_en <= 1'b0;
            fetch_stop <= 1'b0;
            control_hazard <= 1'b0;
        end
        else if (inst_mem_ready) begin
            branch_prediction();
            cur_inst_addr <= next_inst_addr;
            if (next_en && !fetch_stop) begin
                if (jmp_en) begin
                    // 跳转情况下，已读取的指令已经无意义
                    next_inst_addr <= jmp_pc;
                end
                else begin
                    next_inst_addr <= next_inst_addr + 4;
                end
                inst_mem_read_en <= 1'b1;
            end
            else begin
                inst_mem_read_en <= 1'b0;
            end
        end
        else if (fetch_stop && jmp_en) begin
            next_inst_addr <= jmp_pc;
            fetch_stop <= 1'b0; // 等到跳转指令，停顿结束
            inst_mem_read_en <= 1'b1;
        end
        else begin
            inst_mem_read_en <= 1'b1;
        end
    end

 endmodule