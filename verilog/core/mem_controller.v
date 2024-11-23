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


module mem_controller(
    input clk,
    input rst,
    // 指令获取通道
    input [`MAX_BIT_POS:0] inst_mem_addr,
    input inst_read_en,
     // 指令返回通道
    output wire [`MAX_BIT_POS:0] inst_mem_rdata,
    output wire inst_mem_ready,
    // 数据获取通道
    input [`MAX_BIT_POS:0] mem_addr,
    input read_en,
    input write_en,
    input wire [1:0]byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    input [`MAX_BIT_POS:0] mem_wdata,
    // 数据返回通道
    output wire [`MAX_BIT_POS:0] mem_rdata,
    output wire mem_ready,

    // 片外内存获取通道
    input [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data,
    input offchip_mem_ready,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata,
    output reg offchip_mem_write_en,
    output reg offchip_mem_read_en,
    output reg [`MAX_BIT_POS:0] offchip_mem_addr
);
    // 指令缓存
    cache i_cache(
        .clk(clk),
        .rst(rst),
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

    // 数据缓存
    cache d_cache(
        .clk(clk),
        .rst(rst),
        .addr(mem_addr),
        .data_in(mem_wdata),
        .write_enable(d_write_cache_en),
        .load_enable(d_load_en),
        .read_enable(d_read_cache_en),
        .byte_size(byte_size),
        .write_load_data(offchip_mem_data),
        .save_ready(d_save_ready),
        .save_data(d_save_data),
        .data_hit(d_data_hit),
        .status_ready(d_status_ready),
        .load_complate(d_load_complate),
        .data_out(mem_rdata),
        .write_back_data(offchip_mem_wdata)
    );

    // 指令读取相关
    reg inst_load_en;
    wire inst_save_data;
    wire inst_data_hit;
    wire inst_status_ready;
    /* verilator lint_off UNOPTFLAT */
    wire inst_load_complate;

    wire inst_read_cache_en;
    /* verilator lint_off UNOPTFLAT */
    wire inst_cache_load_en;

    
    
    assign inst_read_cache_en = inst_read_en & ~inst_load_en;
    assign inst_mem_ready = inst_read_cache_en & inst_status_ready & inst_data_hit;
    assign inst_cache_load_en = inst_read_cache_en && inst_status_ready && (!inst_data_hit);



    // 数据读写相关
    reg d_load_en;
    /* verilator lint_off UNOPTFLAT */
    wire d_save_data;
    /* verilator lint_off UNOPTFLAT */
    reg d_save_ready;
    wire d_data_hit;
    wire d_status_ready;
    wire d_load_complate;

    reg [1:0] d_offchip_status;
    wire d_read_cache_en;
    wire d_write_cache_en;
    wire d_cache_load_en;

    assign d_read_cache_en = read_en & ~d_load_en;
    assign d_write_cache_en = write_en & ~d_load_en;
    assign mem_ready = (d_read_cache_en | d_write_cache_en) & d_status_ready & d_data_hit;
    assign d_cache_load_en = (d_read_cache_en || d_write_cache_en) && d_status_ready && (!d_data_hit);

    localparam OFF_STATUS_IDLE = 0, OFF_STATUS_RW = 1, OFF_STATUS_WRITEBACK = 2, OFF_STATUS_WRITECACHE = 3, OFF_STATUS_WAITIDLE = 4;
    localparam CUR_LOAD_IDLE = 0, CUR_INST_LOAD = 1, CUR_DATA_LOAD = 2;

    reg [2:0] offship_state;
    reg [2:0] next_offship_state;
    /* verilator lint_off UNOPTFLAT */
    reg [1:0]cur_load_type; // 0: inst, 1: data

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            offship_state <= OFF_STATUS_IDLE;
        end
        else begin
            offship_state <= next_offship_state;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            offchip_mem_read_en <= 1'b0;
            offchip_mem_write_en <= 1'b0;
            cur_load_type <= CUR_LOAD_IDLE;
            d_save_ready <= 1'b0;
            inst_load_en <= 1'b0;
            d_load_en <= 1'b0;
        end
        else begin
            case (offship_state)
                OFF_STATUS_IDLE: begin
                    if (inst_cache_load_en && cur_load_type == CUR_LOAD_IDLE) begin
                        offchip_mem_addr <= {inst_mem_addr[31:4],4'b0000}; // 指令保证4字节对齐访问
                        offchip_mem_read_en <= 1'b1;
                        cur_load_type <= CUR_INST_LOAD;
                    end
                    else if (d_cache_load_en && cur_load_type == CUR_LOAD_IDLE) begin
                        offchip_mem_addr <= {mem_addr[31:4],4'b0000};
                        offchip_mem_read_en <= 1'b1;
                        cur_load_type <= CUR_DATA_LOAD;
                    end
                    inst_load_en <= 1'b0;
                    d_load_en <= 1'b0;
                    d_save_ready <= 1'b0;
                end
                OFF_STATUS_RW: begin // 等待片外读取完毕
                    if (offchip_mem_ready) begin
                        if (cur_load_type == CUR_INST_LOAD) begin
                            inst_load_en <= 1'b1;
                        end
                        else begin
                            d_load_en <= 1'b1;
                        end
                    end
                end
                OFF_STATUS_WRITECACHE: begin // 写入缓存
                    if (inst_load_complate && cur_load_type == CUR_INST_LOAD) begin
                        inst_load_en <= 1'b0;
                        offchip_mem_read_en <= 1'b0;
                        if (!inst_cache_load_en) begin
                            cur_load_type <= CUR_LOAD_IDLE;
                        end
                    end
                    else if (d_load_complate && cur_load_type == CUR_DATA_LOAD) begin
                        d_load_en <= 1'b0;
                        offchip_mem_read_en <= 1'b0;
                        if (!d_cache_load_en) begin
                            cur_load_type <= CUR_LOAD_IDLE;
                        end
                    end
                    else if (d_save_data && !d_save_ready && cur_load_type == CUR_DATA_LOAD) begin
                        // 待覆盖缓存行存在脏数据，需要先写回到外部
                        offchip_mem_write_en <= 1'b1;
                    end
                end
                OFF_STATUS_WRITEBACK: begin // 写回外部
                    if (offchip_mem_ready) begin
                        offchip_mem_write_en <= 1'b0;
                        d_save_ready <= 1'b1;
                    end
                end
                OFF_STATUS_WAITIDLE: begin
                    if (cur_load_type == CUR_INST_LOAD && !inst_cache_load_en) begin
                        cur_load_type <= CUR_LOAD_IDLE;
                    end
                    else if (cur_load_type == CUR_DATA_LOAD && !d_cache_load_en) begin
                        cur_load_type <= CUR_LOAD_IDLE;
                    end
                end
                default: begin
                    // nothing
                end
            endcase
        end
    end

    /* verilator lint_off LATCH */
    always @(*) begin
        if (!rst) begin
            next_offship_state = OFF_STATUS_IDLE;
        end
        else begin
            case (offship_state)
                OFF_STATUS_IDLE: begin
                    if (cur_load_type != CUR_LOAD_IDLE) begin
                        next_offship_state = OFF_STATUS_RW;
                    end
                    else begin
                        next_offship_state = OFF_STATUS_IDLE;
                    end
                end
                OFF_STATUS_RW: begin // 等待片外读取完毕
                    if (inst_load_en || d_load_en) begin
                        next_offship_state = OFF_STATUS_WRITECACHE;
                    end
                    else begin
                        next_offship_state = OFF_STATUS_RW;
                    end
                end
                OFF_STATUS_WRITECACHE: begin // 写入缓存
                    if (!inst_load_en && !d_load_en) begin
                        next_offship_state = OFF_STATUS_WAITIDLE;
                        if (cur_load_type == CUR_LOAD_IDLE) begin
                            next_offship_state = OFF_STATUS_IDLE;
                        end
                    end
                    else if (offchip_mem_write_en) begin
                        // 待覆盖缓存行存在脏数据，需要先写回到外部
                        next_offship_state = OFF_STATUS_WRITEBACK;
                    end
                    else begin
                        next_offship_state = OFF_STATUS_WRITECACHE;
                    end
                end
                OFF_STATUS_WRITEBACK: begin // 写回外部
                    if (!offchip_mem_write_en) begin
                        next_offship_state = OFF_STATUS_WRITECACHE;
                    end
                    else begin
                        next_offship_state = OFF_STATUS_WRITEBACK;
                    end
                end
                OFF_STATUS_WAITIDLE: begin
                    if (cur_load_type == CUR_LOAD_IDLE) begin
                        next_offship_state = OFF_STATUS_IDLE;
                    end
                    else begin
                        next_offship_state = OFF_STATUS_WAITIDLE;
                    end
                end
                default: begin
                    // nothing
                end
            endcase
        end
    end

endmodule