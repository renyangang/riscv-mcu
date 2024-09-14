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
    input wire rst_n,
    input wire [31:0] addr,   
    input wire [31:0] wdata,  
    input wire write_enable,
    input wire load_enable,
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    input wire cs, // cache select
    output reg [31:0] rdata,
    output reg [(`CACHE_LINE_SIZE*8)-1:0] write_back_data, 
    output wire hit,
    output wire dirty_status
);
    
    reg [31:0] cache_data [`CACHE_LINES-1:0][`CACHE_LINE_SIZE/4-1:0]; 
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

    integer i, j;
    always @(negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < `CACHE_LINES; i = i + 1) begin
                valid[i] <= 0;
                tag[i] <= 0;
                dirty[i] <= 0;
                for (j = 0; j < `CACHE_LINE_SIZE/4; j = j + 1) begin
                    cache_data[i][j] <= 0;
                end
            end
            write_back_data <= 0;
            rdata <= 0;
        end
    end

    
    always @(posedge clk) begin
        if(cs) begin
            if (load_enable) begin
                for(i = 0; i < `CACHE_LINE_SIZE/4; i = i + 4) begin
                    cache_data[index][i] <= 32'hFFFFFFFF & write_load_data >> (i << 2);
                end
                dirty[index] <= 0;
                valid[index] <= 1;
                tag[index] <= tag_in;
            end
            else if (write_enable) begin
                cache_data[index][offset >> 2] <= wdata; 
                dirty[index] <= 1;                    
            end
            else begin
                if (valid[index] && (tag[index] == tag_in)) begin
                    rdata <= cache_data[index][offset >> 2];
                    for(i = 0; i < `CACHE_LINE_SIZE/4; i = i + 1) begin
                        write_back_data <= write_back_data | (cache_data[index][i] << (i << 2));
                    end
                end
                else begin
                    rdata <= 32'h0;
                    write_back_data <= 0;
                end
            end
        end
        else begin
            rdata <= 32'hz;
        end
    end
endmodule

`define S_IDLE 2'b00
`define S_ADDR 2'b01
`define S_GETHIT 2'b10
`define S_WRITELOAD 2'b11
module cache_set(
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,   
    input wire [31:0] wdata,  
    input wire write_enable,
    input wire load_enable,
    input wire read_enable,
    input wire begin_save,
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    output reg status_ready,
    output reg save_ready,
    output wire [31:0] rdata,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] write_back_data, 
    output reg dirty,
    output reg hit
);

    wire [`CACHE_WAYS-1:0] way_hit;
    reg [`CACHE_WAYS-1:0] way_cs [`CACHE_LINES-1:0];
    wire [`CACHE_WAYS-1:0] dirty_status;
    // support max way num == 4
    reg [2:0] write_cs [`CACHE_LINES-1:0][`CACHE_WAYS-1:0]; 

    wire [5:0] index;
    assign index = addr[9:4];

    reg [1:0]status;


    genvar i_way;
    generate
        for (i_way = 0; i_way < `CACHE_WAYS; i_way = i_way + 1) begin : cache_way_gen
            cache_way cache_way_inst (
                .clk(clk),
                .rst_n(rst_n),
                .addr(addr),
                .wdata(wdata),
                .write_enable(write_enable),
                .load_enable(begin_save),
                .write_load_data(write_load_data),
                .cs(way_cs[index][i_way]),
                .rdata(rdata),
                .write_back_data(write_back_data),
                .dirty_status(dirty_status[i_way]),
                .hit(way_hit[i_way])
            );
        end
    endgenerate

    
    integer i,j;
    
    always @(addr or load_enable or write_enable or read_enable) begin
        status_ready = 1'b0;
        save_ready = 1'b0;
        if (status == `S_IDLE) begin
            status = `S_ADDR;
        end

    end

    always @(posedge clk) begin
        case (status)
          `S_ADDR: begin
                if(!load_enable) begin
                    hit <= (|way_hit);
                    way_cs[index] <= way_hit;
                    dirty <= 1'b0;
                end
                else begin
                    way_cs[index][write_cs[index][0]] <= 1'b1;
                    dirty <= dirty_status[write_cs[index][0]];
                end
                status <= `S_GETHIT;
                status_ready <= 1'b1;
            end
            `S_GETHIT: begin
                if(!load_enable) begin
                    if(hit) begin
                        // 常规读写命中时，更新
                        for (i = 0; i < `CACHE_WAYS; i = i + 1) begin
                            if (way_cs[index][i]) begin
                                for (j = 0; j < `CACHE_WAYS - 1; j = j + 1) begin
                                    write_cs[index][j] <= write_cs[index][j+1];
                                end
                                write_cs[index][`CACHE_WAYS-1] <= i[2:0];
                            end
                        end
                    end
                    status <= `S_IDLE;
                end
                else begin
                    status <= `S_WRITELOAD;
                end
            end
            `S_WRITELOAD: begin
                if (!begin_save && load_enable) begin
                    save_ready <= 1'b0;
                    status <= status;
                end
                else begin
                    status <= `S_IDLE;
                    save_ready <= 1'b1;
                end
            end
        endcase
    end

    always @(negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < `CACHE_WAYS; i = i + 1) begin
                for(j=0;j<`CACHE_LINES;j=j+1) begin
                    write_cs[j][i] <= i[2:0];
                    way_cs[j][i] <= 1'b0;
                end
            end
            status <= `S_IDLE;
            dirty <= 1'b0;
            hit <= 1'b0;
            status_ready <= 1'b0;
        end
    end

endmodule

`define IDLE 3'd0
`define WAIT_HIT 3'd1
`define DO_READ_OR_WRITE 3'd2
`define WAIT_WRITE_2_MEM 3'd3
`define WAIT_LOAD_SAVE 3'd4
module cache(
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire write_enable,
    input wire read_enable,
    input wire load_enable,
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    input wire save_ready,
    output reg save_data,
    output reg data_hit,
    output reg status_ready,
    output reg load_complate,
    output wire [31:0] data_out,
    output wire [(`CACHE_LINE_SIZE*8)-1:0] write_back_data
);

    wire dirty;
    wire hit;
    reg [2:0] status;
    reg op_start;
    reg begin_load;
    wire status_r;
    wire load_save_ready;

    
    cache_set cache_set_inst(
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr),
        .wdata(data_in),
        .write_enable(write_enable),
        .read_enable(read_enable),
        .load_enable(load_enable),
        .begin_save(begin_load),
        .write_load_data(write_load_data),
        .rdata(data_out),
        .write_back_data(write_back_data),
        .dirty(dirty),
        .hit(hit),
        .save_ready(load_save_ready),
        .status_ready(status_r)
    );

    always @(addr or posedge read_enable or posedge write_enable or posedge load_enable) begin
        op_start = 1'b1;
    end

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            save_data <= 0;
            data_hit <= 0;
            status_ready <= 0;
            load_complate <= 0;
            begin_load <= 0;
            op_start <= 0;
            status <= `IDLE;
        end
        else begin
            case (status)
                `IDLE: begin
                    load_complate <= 0;
                    begin_load <= 0;
                    status_ready <= 0;
                    data_hit <= 0;
                    if(op_start && (read_enable || write_enable || load_enable)) begin
                        status <= `WAIT_HIT;
                        op_start <= 0;
                    end
                    else begin
                        status <= status;
                    end
                end
                `WAIT_HIT: begin
                    if(status_r) begin
                        status_ready <= 1'b1;
                        data_hit <= hit;
                        status <= `DO_READ_OR_WRITE;
                    end
                    else begin
                        status <= status;
                    end
                end
                `DO_READ_OR_WRITE: begin
                    if (load_enable) begin
                        if (dirty) begin
                            status <= `WAIT_WRITE_2_MEM; // 进入等待写入内存状态
                            save_data <= 1'b1;
                            begin_load <= 1'b0;
                        end
                        else begin
                            status <= `WAIT_LOAD_SAVE; // 进入等待加载状态
                            save_data <= 1'b0;
                            begin_load <= 1'b1;
                        end
                    end
                    else begin
                        status <= `IDLE;
                    end
                end
                `WAIT_WRITE_2_MEM: begin // 等待写入内存
                    if (save_ready) begin
                        status <= `WAIT_LOAD_SAVE; // 保存内存完毕，进入等待加载状态
                        save_data <= 1'b0;
                        begin_load <= 1'b1;
                    end
                    else begin // 否则继续等待
                        status <= status;
                    end
                end
                `WAIT_LOAD_SAVE: begin // 等待加载
                    if (load_save_ready) begin
                        load_complate <= 1'b1;
                        begin_load <= 1'b0;
                        status <= `IDLE; // 保存cache到内存，返回空闲状态
                    end
                    else begin
                        status <= status;
                    end
                end
            endcase
        end
    end


endmodule