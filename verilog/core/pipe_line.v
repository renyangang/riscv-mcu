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

 Description: pipe line controller 
    流水线公共寄存器、调度、冲刷等逻辑控制
 */

module pipe_line(
    input [31:0] IR, PC,next_PC,
    input [4:0] r_toMem, r_toReg, //写回寄存器
    input [31:0] r_memData, r_writbackData, //访存数据、写回数据
    output reg [31:0] r_IR, r_PC, r_nextPC, //指令寄存器、PC寄存器
    output reg [31:0] mem_addr, //待访存地址
    output reg jump_pc, //跳转地址
    output reg writback_busy, write_mem_busy, read_mem_busy, //写回、访存忙信号
    output reg stop,flush //停止信号、冲刷信号
);



endmodule