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

 Description: system bus module
 系统总线，负责CPU与外设、片外内存等之间的通信
 */

 `include "config.v"

`define CUR_INST_CACHE 2'b00
`define CUR_INST_FLASH 2'b01
module sys_bus(
    input         clk,
    input         rst,

    input         inst_read_en,       
    input  [31:0] inst_read_addr,
    output wire [31:0] inst_rdata,
    output wire    inst_read_ready,

    input         read_en,       
    input  [31:0] mem_addr,
    output [31:0] rdata,
    input         write_en,
    input  [31:0] wdata,     
    input  [1:0]  byte_size,
    output reg    mem_busy,
    output reg    mem_ready,

    input [31:0] pc,
    input [31:0] pc_next,
    input [31:0] inst_cur,
    input [31:0] exception_code,
    input exception_en,
    input cur_branch_hazard,

    output wire jmp_en,
    output wire [31:0] jmp_pc,

    input wire clk_timer,

    input wire [11:0] csr_read_addr,
    input wire [11:0] csrw_addr,
    input wire [31:0] w_data,
    input wire csr_write_en,
    output wire [31:0] csr_out,

    // 片外内存与内部cache
    input [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data,
    input offchip_mem_ready,
    output [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata,
    output wire offchip_mem_write_en,
    output wire offchip_mem_read_en,
    output wire [31:0] offchip_mem_addr
);

    wire offchip_mem_read_busy;
    wire offchip_mem_write_busy;

    // 指令cache读取部分
    reg         inst_read_en_icache;      
    reg  [31:0] inst_read_addr_icache;
    wire [31:0] inst_rdata_icache;
    wire    inst_read_ready_icache;

    reg [1:0] inst_cur_from; // 指令来源，0表示来自指令cache，1表示来自flash

    always @(negedge rst) begin
        if (!rst) begin
            inst_read_en_icache = 1'd0;
        end
    end

    assign inst_read_ready = (inst_cur_from == `CUR_INST_CACHE) ? inst_read_ready_icache : 1'b0;
    assign inst_rdata = (inst_cur_from == `CUR_INST_CACHE) ? inst_rdata_icache : 32'd0;

    always @(posedge inst_read_en or inst_read_addr) begin
        // TODO 需要判断指令地址，决定从哪里读取，目前只有缓存
        inst_read_en_icache = inst_read_en;
        inst_read_addr_icache = inst_read_addr;
        inst_cur_from = `CUR_INST_CACHE;
    end

    // 数据cache读取部分
    reg         read_en_dcache;       
    reg  [31:0] mem_addr_dcache;
    wire [31:0] rdata_dcache;
    wire        mem_ready_dcache;
    reg         write_en_dcache;
    wire  [31:0] wdata_dcache;   
    wire [1:0]   byte_size_dcache;

    mem_controller d_cache(
        .clk(clk),
        .rst(rst),
        .inst_mem_addr(inst_read_addr_icache),
        .inst_read_en(inst_read_en_icache),
        .inst_mem_rdata(inst_rdata_icache),
        .inst_mem_ready(inst_read_ready_icache),

        .mem_addr(mem_addr_dcache),
        .read_en(read_en_dcache),
        .write_en(write_en_dcache),
        .byte_size(byte_size_dcache),
        .mem_wdata(wdata_dcache),
        .mem_rdata(rdata_dcache),
        .mem_ready(mem_ready_dcache),

        // 片外内存获取通道
        .offchip_mem_data(offchip_mem_data),
        .offchip_mem_ready(offchip_mem_ready),
        .offchip_mem_wdata(offchip_mem_wdata),
        .offchip_mem_write_en(offchip_mem_write_en),
        .offchip_mem_read_en(offchip_mem_read_en),
        .offchip_mem_addr(offchip_mem_addr),
        .offchip_mem_read_busy(offchip_mem_read_busy),
        .offchip_mem_write_busy(offchip_mem_write_busy)
    );

    reg gpio_int;
    reg uart_int;
    reg iic_int;
    reg spi_int;
    reg soft_int;
    reg [7:0]soft_int_code;

    reg [31:0] mtimecmp_low;
    reg [31:0] mtimecmp_high;
    wire [31:0] mtime_low;
    wire [31:0] mtime_high;
    wire [7:0] cur_int_code;

    int_bus int_bus(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .pc_next(pc_next),
        .inst_cur(inst_cur),
        .exception_code(exception_code),
        .exception_en(exception_en),
        .cur_branch_hazard(cur_branch_hazard),
        .jmp_en(jmp_en),
        .jmp_pc(jmp_pc),
        .clk_timer(clk_timer),
        .mtimecmp_low(mtimecmp_low),
        .mtimecmp_high(mtimecmp_high),
        .mtime_low(mtime_low),
        .mtime_high(mtime_high),
        .csr_read_addr(csr_read_addr),
        .csrw_addr(csrw_addr),
        .w_data(w_data),
        .write_en(csr_write_en),
        .csr_out(csr_out),
        .soft_int(soft_int),
        .soft_int_code(soft_int_code),
        .cur_int_code(cur_int_code),
        .gpio_int(gpio_int),
        .uart_int(uart_int),
        .iic_int(iic_int),
        .spi_int(spi_int)
    );

endmodule