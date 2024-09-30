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

 Description: mem controller
    内存访问控制，包括调用缓存、外部内存、外设内存映射等
 */
 `include "config.v"

`define OFF_STATUS_IDLE 2'b00
`define OFF_STATUS_RW 2'b01
`define OFF_STATUS_WRITEBACK 2'b10
`define OFF_STATUS_WRITECACHE 2'b11
module mem_controller(
    input clk,
    input rst,
    // 指令获取通道
    input [31:0] inst_mem_addr,
    input inst_read_en,
     // 指令返回通道
    output wire [31:0] inst_mem_rdata,
    output wire inst_mem_ready,
    // 数据获取通道
    input [31:0] mem_addr,
    input read_en,
    input write_en,
    input wire [1:0]byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    input [31:0] mem_wdata,
    // 数据返回通道
    output wire [31:0] mem_rdata,
    output wire mem_ready,

    // 片外内存获取通道
    input [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data,
    input offchip_mem_ready,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata,
    output reg offchip_mem_write_en,
    output reg offchip_mem_read_en,
    output reg [31:0] offchip_mem_addr,
    output reg offchip_mem_read_busy,
    output reg offchip_mem_write_busy
);

    // 指令读取相关
    reg inst_load_en;
    wire inst_save_data;
    wire inst_data_hit;
    wire inst_status_ready;
    wire inst_load_complate;

    // 指令缓存
    cache i_cache(
        .clk(clk),
        .rst_n(rst),
        .addr(inst_mem_addr),
        .data_in(),
        .write_enable(1'b0),
        .load_enable(inst_load_en),
        .read_enable(inst_read_cache_en),
        .byte_size(2'b00),
        .write_load_data(offchip_mem_data),
        .save_ready(1'b1),
        .save_data(inst_save_data),
        .data_hit(inst_data_hit),
        .status_ready(inst_status_ready),
        .load_complate(inst_load_complate),
        .data_out(inst_mem_rdata),
        .write_back_data()
    );

    reg [1:0] inst_offchip_status;
    reg inst_read_cache_en;

    always @(inst_read_en or inst_load_en) begin
        inst_read_cache_en = inst_read_en & ~inst_load_en;
    end

    assign inst_mem_ready = inst_read_cache_en & inst_status_ready & inst_data_hit;

    // 指令片外读取
    always @(posedge clk) begin
        if (rst) begin
            case (inst_offchip_status)
                `OFF_STATUS_IDLE: begin
                    if (inst_read_cache_en && inst_status_ready && (!inst_data_hit) && !offchip_mem_read_busy) begin
                        inst_offchip_status <= `OFF_STATUS_RW;
                        offchip_mem_addr <= {inst_mem_addr[31:4],4'b0000};
                        offchip_mem_read_en <= 1'b1;
                        offchip_mem_read_busy <= 1'b1;
                    end
                    else begin
                        inst_offchip_status <= inst_offchip_status;
                    end
                end
                `OFF_STATUS_RW: begin // 等待片外读取完毕
                    if (offchip_mem_ready) begin
                        inst_offchip_status <= `OFF_STATUS_WRITECACHE;
                        inst_load_en <= 1'b1;
                    end
                    else begin
                        inst_offchip_status <= inst_offchip_status;
                    end
                end
                `OFF_STATUS_WRITECACHE: begin // 写入缓存
                    if (inst_load_complate) begin
                        inst_load_en <= 1'b0;
                        offchip_mem_read_busy <= 1'b0;
                        offchip_mem_read_en <= 1'b0;
                        inst_offchip_status <= `OFF_STATUS_IDLE;
                    end
                    else begin
                        inst_offchip_status <= inst_offchip_status;
                    end
                end
            endcase
        end
    end

    // 数据读写相关
    reg d_load_en;
    reg [(`CACHE_LINE_SIZE*8)-1:0] d_write_load_data;
    wire d_save_data;
    reg d_save_ready;
    wire d_data_hit;
    wire d_status_ready;
    wire d_load_complate;

    // 数据缓存
    cache d_cache(
        .clk(clk),
        .rst_n(rst),
        .addr(mem_addr),
        .data_in(mem_wdata),
        .write_enable(d_write_cache_en),
        .load_enable(d_load_en),
        .read_enable(d_read_cache_en),
        .byte_size(byte_size),
        .write_load_data(d_write_load_data),
        .save_ready(d_save_ready),
        .save_data(d_save_data),
        .data_hit(d_data_hit),
        .status_ready(d_status_ready),
        .load_complate(d_load_complate),
        .data_out(mem_rdata),
        .write_back_data(offchip_mem_wdata)
    );

    reg [1:0] d_offchip_status;
    reg d_read_cache_en;
    reg d_write_cache_en;

    always @(read_en or d_load_en) begin
        d_read_cache_en = read_en & ~d_load_en;
    end

    always @(write_en or d_load_en) begin
        d_write_cache_en = read_en & ~d_load_en;
    end

    always @(mem_addr) begin
        d_save_ready = 1'b0;
    end

    assign mem_ready = (d_read_cache_en | d_write_cache_en) & d_status_ready & d_data_hit;

    // 数据片外读写
    always @(posedge clk) begin
        if (rst) begin
            case (d_offchip_status)
                `OFF_STATUS_IDLE: begin
                    if ((d_read_cache_en || d_write_cache_en) && d_status_ready && (!d_data_hit) && !offchip_mem_read_busy) begin
                        d_offchip_status <= `OFF_STATUS_RW;
                        offchip_mem_addr <= {mem_addr[31:4],4'b0000};
                        offchip_mem_read_en <= 1'b1;
                        offchip_mem_read_busy <= 1'b1;
                        d_load_en <= 1'b0;
                    end
                    else begin
                        d_offchip_status <= d_offchip_status;
                    end
                end
                `OFF_STATUS_RW: begin // 等待片外读取完毕
                    if (offchip_mem_ready) begin
                        d_write_load_data <= offchip_mem_data;
                        d_offchip_status <= `OFF_STATUS_WRITECACHE;
                        d_load_en <= 1'b1;
                    end
                    else begin
                        d_offchip_status <= d_offchip_status;
                    end
                end
                `OFF_STATUS_WRITECACHE: begin // 写入缓存
                    if (d_save_data && !d_save_ready) begin
                        // 待覆盖缓存行存在脏数据，需要先写回到外部
                        offchip_mem_write_en <= 1'b1;
                        offchip_mem_write_busy <= 1'b1;
                        d_offchip_status <= `OFF_STATUS_WRITEBACK;
                    end
                    else if (d_load_complate) begin
                        d_load_en <= 1'b0;
                        offchip_mem_read_busy <= 1'b0;
                        offchip_mem_read_en <= 1'b0;
                        d_offchip_status <= `OFF_STATUS_IDLE;
                    end
                    else begin
                        d_offchip_status <= d_offchip_status;
                    end
                end
                `OFF_STATUS_WRITEBACK: begin // 写回外部
                    if (offchip_mem_ready) begin
                        offchip_mem_write_en <= 1'b0;
                        offchip_mem_write_busy <= 1'b0;
                        d_save_ready <= 1'b1;
                        d_offchip_status <= `OFF_STATUS_WRITECACHE;
                    end
                    else begin
                        d_offchip_status <= d_offchip_status;
                    end
                end
            endcase
        end
    end

    // 复位初始化
    always @(negedge rst) begin
        if (!rst) begin
            inst_load_en <= 1'b0;
            d_load_en <= 1'b0;
            d_save_ready <= 1'b0;
            offchip_mem_addr <= 32'b0;
            offchip_mem_read_busy <= 1'b0;
            offchip_mem_write_busy <= 1'b0;
            offchip_mem_read_en <= 1'b0;
            offchip_mem_write_en <= 1'b0;
            inst_offchip_status <= `OFF_STATUS_IDLE;
            d_offchip_status <= `OFF_STATUS_IDLE;
        end
    end

endmodule