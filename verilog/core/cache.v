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

 Description: cpu cache module

 */
`include "config.v"

// cache_way with 64*16 bytes
module cache_way (
    input wire clk,
    input wire rst,
    input wire [`MAX_BIT_POS:0] addr,   
    input wire [`MAX_BIT_POS:0] wdata,  
    input wire write_enable,
    input wire load_enable,
    input wire [1:0]byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    input wire cs, // cache select
    output wire [`MAX_BIT_POS:0] rdata,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] write_back_data, 
    output wire hit,
    output wire dirty_status
);
    
    reg [`CACHE_LINE_WIDTH-1:0] cache_data [`CACHE_LINES-1:0]; 
    reg [21:0] tag [`CACHE_LINES-1:0];                          
    reg valid [`CACHE_LINES-1:0];
    reg dirty [`CACHE_LINES-1:0];                             

    wire [5:0] index;
    wire [3:0] offset;
    wire [21:0] tag_in;

    assign index = addr[9:4];      
    assign offset = addr[3:0];     
    assign tag_in = addr[31:10];    

    assign hit = (valid[index] && (tag[index] == tag_in))? 1'b1:1'b0;
    assign dirty_status = dirty[index];
    assign write_back_data = cs ? cache_data[index] : {`CACHE_LINE_WIDTH{1'bz}};

    assign rdata = hit ? (byte_size == 1 ? {24'd0,cache_data[index][(offset*8) +: 8]} : 
                    (byte_size == 2 ? {16'd0,cache_data[index][(offset*8) +: 16]} : 
                    cache_data[index][(offset*8) +: 32])) : 
                    `XLEN'bz;
    // always @(*) begin
    //     if (rst) begin
    //         case(byte_size)
    //             1: begin
    //                 in_rdata = hit ? {24'd0,cache_data[index][(offset*8) +: 8]} : `XLEN'bz;
    //             end
    //             2: begin
    //                 in_rdata = hit ? {16'd0,cache_data[index][(offset*8) +: 16]} : `XLEN'bz;
    //             end
    //             default: begin
    //                 in_rdata = hit ? cache_data[index][(offset*8) +: 32] : `XLEN'bz;
    //             end
    //         endcase
    //     end
    //     else begin
    //         in_rdata = `XLEN'bz;
    //     end
    // end
    
    integer i, j;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < `CACHE_LINES; i = i + 1) begin
                valid[i] <= 0;
                tag[i] <= 0;
                dirty[i] <= 0;
                cache_data[i] <= {`CACHE_LINE_WIDTH{1'b0}};
            end
        end
        else if(cs) begin
            if (load_enable) begin
                cache_data[index] <= write_load_data;
                dirty[index] <= 0;
                valid[index] <= 1;
                tag[index] <= tag_in;
            end
            else if (write_enable) begin
                case (byte_size)
                    1: begin
                        cache_data[index][(offset*8) +: 8] <= wdata[7:0];     
                    end
                    2: begin
                        cache_data[index][(offset*8) +: 16] <= wdata[15:0]; 
                    end
                    default: begin
                        cache_data[index][(offset*8) +: 32] <= wdata;
                    end
                endcase
                dirty[index] <= 1;                   
            end
        end
    end
endmodule


module cache_set(
    input wire clk,
    input wire rst,
    input wire [`MAX_BIT_POS:0] addr,   
    input wire [`MAX_BIT_POS:0] wdata,  
    input wire write_enable,
    input wire load_enable,
    input wire read_enable,
    input wire [1:0]byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    input wire begin_save,
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    output reg status_ready,
    output reg save_ready,
    output wire [`MAX_BIT_POS:0] rdata,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] write_back_data, 
    output reg dirty,
    output wire hit
);

    wire [`CACHE_WAYS-1:0] way_hit;
    reg [`CACHE_WAYS-1:0] way_cs [`CACHE_LINES-1:0];
    wire [`CACHE_WAYS-1:0] dirty_status;
    reg [$clog2(`CACHE_WAYS)-1:0] evict_idx;
    wire [5:0] index;
    assign index = addr[9:4];
    assign hit = (|way_hit);

    reg [1:0]state;
    reg [1:0]next_state;

    // 计算树的深度
    localparam DEPTH = $clog2(`CACHE_WAYS);
    // 存储每个节点的方向位
    // 总节点数为 CACHE_WAYS -1
    reg [`CACHE_WAYS-2:0] plru_bits;

    localparam S_IDLE = 2'b00, S_ADDR = 2'b01, S_GETHIT = 2'b10, S_WRITELOAD = 2'b11;

    genvar i_way;
    generate
        for (i_way = 0; i_way < `CACHE_WAYS; i_way = i_way + 1) begin : cache_way_gen
            cache_way cache_way_inst (
                .clk(clk),
                .rst(rst),
                .addr(addr),
                .wdata(wdata),
                .write_enable(write_enable),
                .load_enable(begin_save),
                .byte_size(byte_size),
                .write_load_data(write_load_data),
                .cs(way_cs[index][i_way]),
                .rdata(rdata),
                .write_back_data(write_back_data),
                .dirty_status(dirty_status[i_way]),
                .hit(way_hit[i_way])
            );
        end
    endgenerate

    integer i,j,d,bit_idx;
    task update_hitstatus();
        if (read_enable || write_enable) begin
            way_cs[index] = way_hit;
            dirty = 1'b0;
            if(|way_hit) begin
                // 常规读写命中时，更新
                for (i = 0; i < `CACHE_WAYS; i = i + 1) begin
                    if (way_hit[i]) begin
                        bit_idx = 0;
                        for (d = DEPTH - 1; d >= 0; d = d - 1) begin
                            plru_bits[bit_idx] = i[d];
                            if (i[d]) begin
                                bit_idx = bit_idx * 2 + 2;
                            end
                            else begin
                                bit_idx = bit_idx * 2 + 1;
                            end
                        end
                        bit_idx = 0;
                        for (d = DEPTH - 1; d >= 0; d = d - 1) begin
                            evict_idx[d] = ~plru_bits[bit_idx];
                            if (evict_idx[d]) begin
                                bit_idx = bit_idx * 2 + 2;
                            end
                            else begin
                                bit_idx = bit_idx * 2 + 1;
                            end
                        end
                    end
                end
            end
        end
    endtask
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(addr) begin
        if (read_enable || write_enable) begin
            update_hitstatus();
        end
    end
    
    always @(*) begin
        if (!rst) begin
            for(j=0;j<`CACHE_LINES;j=j+1) begin
                way_cs[j] =  {`CACHE_WAYS{1'b0}};
            end
            dirty = 1'b0;
            evict_idx = 0;
            status_ready = 1'b0;
            plru_bits = {(`CACHE_WAYS-1){1'b0}};
            next_state = S_IDLE;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if (read_enable) begin
                        // 读取状态下直接返回，不要等待状态
                        status_ready = 1'b1;
                        update_hitstatus();
                    end
                    else if (load_enable || write_enable) begin
                        status_ready = 1'b0;
                        next_state = S_ADDR;
                    end
                end
                S_ADDR: begin
                    save_ready = 1'b0;
                    if(!load_enable) begin
                        update_hitstatus();
                        next_state = S_IDLE;
                    end
                    else begin
                        way_cs[index][evict_idx] = 1'b1;
                        dirty = dirty_status[evict_idx];
                        next_state = S_WRITELOAD;
                    end
                    status_ready = 1'b1;
                end
                S_WRITELOAD: begin
                    if (!begin_save && load_enable) begin
                        save_ready = 1'b0;
                        next_state = state;
                    end
                    else begin
                        next_state = S_IDLE;
                        save_ready = 1'b1;
                    end
                end
                default: begin
                    next_state = S_IDLE;
                end
            endcase
        end
    end

endmodule


module cache(
    input wire clk,
    input wire rst,
    input wire [`MAX_BIT_POS:0] addr,
    input wire [`MAX_BIT_POS:0] data_in,
    input wire write_enable,
    input wire read_enable,
    input wire load_enable,
    input wire [1:0]byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    input wire save_ready,
    output reg save_data,
    output wire data_hit,
    output wire status_ready,
    output reg load_complate,
    output wire [`MAX_BIT_POS:0] data_out,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] write_back_data
);

    wire dirty;
    reg [2:0] state;
    reg [2:0] next_state;
    /* verilator lint_off UNOPTFLAT */
    reg begin_load;
    wire load_save_ready;

    localparam IDLE = 3'd0, WAIT_HIT = 3'd1, DO_READ_OR_WRITE = 3'd2, WAIT_WRITE_2_MEM = 3'd3, WAIT_LOAD_SAVE = 3'd4;

    
    cache_set cache_set_inst(
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wdata(data_in),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .load_enable(load_enable),
        .byte_size(byte_size),
        .begin_save(begin_load),
        .write_load_data(write_load_data),
        .rdata(data_out),
        .write_back_data(write_back_data),
        .dirty(dirty),
        .hit(data_hit),
        .save_ready(load_save_ready),
        .status_ready(status_ready)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        if (!rst) begin
            next_state = IDLE;
            save_data = 0;
            load_complate = 0;
            begin_load = 0;
        end
        else begin
            case (state)
                IDLE: begin
                    begin_load = 1'b0;
                    load_complate = 0;
                    if (status_ready && load_enable) begin
                        if (dirty) begin
                            next_state = WAIT_WRITE_2_MEM; // 进入等待写入内存状态
                            save_data = 1'b1;
                            begin_load = 1'b0;
                        end
                        else begin
                            next_state = WAIT_LOAD_SAVE; // 进入等待加载状态
                            save_data = 1'b0;
                            begin_load = 1'b1;
                        end
                    end
                    else begin
                        next_state = state;
                    end
                end
                WAIT_WRITE_2_MEM: begin // 等待写入内存
                    if (save_ready) begin
                        next_state = WAIT_LOAD_SAVE; // 保存内存完毕，进入等待加载状态
                        save_data = 1'b0;
                        begin_load = 1'b1;
                    end
                    else begin // 否则继续等待
                        next_state = state;
                    end
                end
                WAIT_LOAD_SAVE: begin // 等待加载
                    if (load_save_ready) begin
                        load_complate = 1'b1;
                        begin_load = 1'b0;
                        next_state = IDLE; // 保存cache到内存，返回空闲状态
                    end
                    else begin
                        next_state = state;
                    end
                end
                default: begin
                    next_state = IDLE;
                end
            endcase
        end
    end

endmodule