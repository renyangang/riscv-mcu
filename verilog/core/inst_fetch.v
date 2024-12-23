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
    input rst_n,
    input [`MAX_BIT_POS:0] jmp_pc,
    input jmp_en,
    input b_n_jmp, // 用于标记跳转指令，并没有发生跳转，在fetch_stop状态下用于解除指令冻结
    input next_en,
    // 指令返回通道
    input [`MAX_BIT_POS:0]inst_data,
    input inst_mem_ready,

    output reg inst_mem_read_en,
    output reg [`MAX_BIT_POS:0] cur_inst_addr,
    output reg [`MAX_BIT_POS:0] next_inst_addr,
    output wire [`MAX_BIT_POS:0] inst_code,
    output reg control_hazard,
    output wire inst_ready
 );

    reg fetch_stop;
    reg stop_f;
    reg int_jmp_en;
    reg [`MAX_BIT_POS:0] int_jmp_pc;

    assign inst_ready = (stop_f || (!next_en && jmp_en) || int_jmp_en) ? 1'b0 : inst_mem_ready;
    // assign inst_code = (inst_data !== 32'hz) ? inst_data : 32'd0;
    assign inst_code = inst_data;

    always @(*) begin
        if (!int_jmp_en && inst_data[6:0] == 7'b1100011) begin
            // 分支跳转指令，进行静态预测， 向后统一预测为跳转，向前统一预测为不跳转
            fetch_stop = inst_data[31];
            // 如果预测不跳转，则设置冒险标记
            control_hazard = ~(inst_data[31]);
        end
        else if (!int_jmp_en && (inst_data[6:0] == 7'b1101111 || inst_data[6:0] == 7'b1100111)) begin
            fetch_stop = 1'b1; // 等待跳转
            control_hazard = 1'b0;
        end
        else if (inst_data == 32'h30200073) begin
            // mret 跳转,也需要等待
            fetch_stop = 1'b1; // 等待跳转
            control_hazard = 1'b0;
        end
        else begin
            fetch_stop = 1'b0;
            control_hazard = 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_inst_addr <= `BOOT_ADDR;
            next_inst_addr <= `BOOT_ADDR + 4;
            inst_mem_read_en <= 1'b0;
            stop_f <= 1'b0;
            int_jmp_en <= 1'b0;
        end
        else begin
            if (fetch_stop) begin
                if (jmp_en) begin
                    cur_inst_addr <= jmp_pc;
                    next_inst_addr <= jmp_pc + 4;
                    // fetch_stop <= 1'b0; // 等到跳转指令，停顿结束
                    inst_mem_read_en <= 1'b1;
                    stop_f <= 1'b0;
                end
                else if (b_n_jmp) begin
                    // fetch_stop <= 1'b0;
                    cur_inst_addr <= next_inst_addr;
                    next_inst_addr <= next_inst_addr + 4;
                    inst_mem_read_en <= 1'b1;
                    stop_f <= 1'b0;
                end
                else if(inst_mem_ready && next_en) begin
                    // 解决等跳转同时遇到流水线暂停的情况，需要在流水线非暂停情况下至少有一个时钟周期输出跳转指令
                     stop_f <= 1'b1;
                     inst_mem_read_en <= 1'b0;
                end
                else begin
                    inst_mem_read_en <= 1'b0;
                end
            end
            else if (inst_mem_ready) begin
                if (!next_en && jmp_en) begin
                    // 在暂停期间，如果暂停的是跳转指令，需要先记录跳转地址，等待恢复后执行
                    cur_inst_addr <= jmp_pc;
                    next_inst_addr <= jmp_pc + 4;
                end
                else if (next_en && !fetch_stop) begin
                    if (int_jmp_en) begin
                        // 跳转情况下，已读取的指令已经无意义
                        cur_inst_addr <= int_jmp_pc;
                        next_inst_addr <= int_jmp_pc + 4;
                        int_jmp_en <= 1'b0;
                    end
                    else if (jmp_en) begin
                        // 跳转情况下，已读取的指令已经无意义
                        cur_inst_addr <= jmp_pc;
                        next_inst_addr <= jmp_pc + 4;
                    end
                    else begin
                        cur_inst_addr <= next_inst_addr;
                        next_inst_addr <= next_inst_addr + 4;
                    end
                    stop_f <= 1'b0;
                    inst_mem_read_en <= 1'b1;
                end
                else begin
                    inst_mem_read_en <= 1'b0;
                end
            end
            else begin
                inst_mem_read_en <= 1'b1;
                if (jmp_en) begin
                    int_jmp_en <= 1'b1;
                    int_jmp_pc <= jmp_pc;
                end
            end
        end
    end
 endmodule