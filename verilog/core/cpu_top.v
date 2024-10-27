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

 Description: CPU top module
    封装CPU核心和总线模块,提供外部soc集成接口
 */
`include "config.v"
module cpu_top(
    input  wire        clk,           // 时钟信号
    input  wire        rst,           // 复位信号
    input  wire        clk_timer,

    output wire [`MAX_BIT_POS:0] io_addr,
    output wire io_read,
    output wire io_write,
    output wire burst,
    output wire [2:0] burst_size,
    output wire read_ready,
    output wire [`MAX_BIT_POS:0] io_wdata,
    output wire [1:0] io_byte_size,
    input wire  [`MAX_BIT_POS:0] io_rdata,
    input wire  io_ready,
    input wire [`INT_CODE_WIDTH-1:0]peripheral_int_code
);

    wire read_en;
    wire [`MAX_BIT_POS:0] mem_addr;
    wire [`MAX_BIT_POS:0] rdata;
    wire write_en;
    wire [`MAX_BIT_POS:0] wdata;
    wire [1:0] byte_size;
    wire mem_busy;
    wire mem_ready;

    // interrupts and exceptions
    
    wire [`MAX_BIT_POS:0] exp_pc;
    wire [`MAX_BIT_POS:0] exp_pc_next;
    wire [`MAX_BIT_POS:0]exception_code;
    wire exception_en;
    wire [`MAX_BIT_POS:0] int_jmp_pc;
    wire int_jmp_en;
    wire mret_en;
    wire int_en;
    wire int_jmp_ready;

    // csr operations
    wire [11:0] csr_read_addr;
    wire [`MAX_BIT_POS:0] csr_data;
    wire [11:0] wb_csr_addr;
    wire wb_csr_out_en;
    wire [`MAX_BIT_POS:0] wb_csrw_data;

    // fetch
    wire inst_read_en;
    wire [`MAX_BIT_POS:0] cur_inst_addr;
    wire [`MAX_BIT_POS:0] next_inst_addr;
    wire inst_ready;
    wire [`MAX_BIT_POS:0] jmp_pc;
    wire jmp_en;
    wire fetch_en;
    wire [`MAX_BIT_POS:0] inst_data;
    wire inst_mem_ready;

    cpu_pipeline cpu_pipeline(
        .clk(clk),
        .rst(rst),
        .read_en,
        .mem_addr(mem_addr),
        .rdata(rdata),
        .write_en(write_en),
        .wdata(wdata),
        .byte_size(byte_size),
        .mem_busy(mem_busy),
        .mem_ready(mem_ready),
        .exp_pc(exp_pc),
        .exp_pc_next(exp_pc_next),
        .exception_code(exception_code),
        .exception_en(exception_en),
        .int_jmp_ready(int_jmp_ready),
        .int_en(int_en),
        .mret_en(mret_en),
        .int_jmp_pc(int_jmp_pc),
        .int_jmp_en(int_jmp_en),
        .csr_read_addr(csr_read_addr),
        .csr_data(csr_data),
        .wb_csr_addr(wb_csr_addr),
        .wb_csr_out_en(wb_csr_out_en),
        .wb_csrw_data(wb_csrw_data),
        .inst_read_en(inst_read_en),
        .cur_inst_addr(cur_inst_addr),
        .next_inst_addr(next_inst_addr),
        .inst_ready(inst_ready),
        .jmp_pc(jmp_pc),
        .jmp_en(jmp_en),
        .fetch_en(fetch_en),
        .inst_data(inst_data),
        .inst_mem_ready(inst_mem_ready)
    );

    sys_bus sys_bus(
        .clk(clk),
        .rst(rst),
        .inst_read_en(inst_read_en),       
        .inst_read_addr(cur_inst_addr),
        .inst_rdata(inst_data),
        .inst_read_ready(inst_mem_ready),
        .read_en(read_en),       
        .mem_addr(mem_addr),
        .rdata(rdata),
        .write_en(write_en),
        .wdata(wdata),     
        .byte_size(byte_size),
        .mem_busy(mem_busy),
        .mem_ready(mem_ready),
        .exp_pc(exp_pc),
        .exp_pc_next(exp_pc_next),
        .exception_code(exception_code),
        .int_jmp_ready(int_jmp_ready),
        .int_en(int_en),
        .exception_en(exception_en),
        .mret_en(mret_en),
        .jmp_en(int_jmp_en),
        .jmp_pc(int_jmp_pc),
        .clk_timer(clk_timer),
        .peripheral_int_code(peripheral_int_code),
        
        .csr_read_addr(csr_read_addr),
        .csrw_addr(wb_csr_addr),
        .w_data(wb_csrw_data),
        .csr_write_en(wb_csr_out_en),
        .csr_out(csr_data),

        .io_addr(io_addr),
        .io_read(io_read),
        .io_write(io_write),
        .burst(burst),
        .burst_size(burst_size),
        .read_ready(read_ready),
        .io_wdata(io_wdata),
        .io_byte_size(io_byte_size),
        .io_rdata(io_rdata),
        .io_ready(io_ready)
    );

endmodule