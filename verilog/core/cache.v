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
    input wire [`MAX_BIT_POS:0] addr,   
    input wire [`MAX_BIT_POS:0] wdata,  
    input wire write_enable,
    input wire load_enable,
    input wire [1:0]byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    input wire [(`CACHE_LINE_SIZE*8)-1:0] write_load_data,
    input wire cs, // cache select
    output reg [`MAX_BIT_POS:0] rdata,
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

    always @(addr) begin
        case(byte_size)
            1: begin
                rdata = cs ? {24'd0,cache_data[index][(offset*8) +: 8]} : 32'bz;
            end
            2: begin
                rdata = cs ? {16'd0,cache_data[index][(offset*8) +: 16]} : 32'bz;
            end
            default: begin
                rdata = cs ? cache_data[index][(offset*8) +: 32] : 32'bz;
            end
        endcase
    end
    
    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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

`define S_IDLE 2'b00
`define S_ADDR 2'b01
`define S_GETHIT 2'b10
`define S_WRITELOAD 2'b11
module cache_set(
    input wire clk,
    input wire rst_n,
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
    reg [`CACHE_WAYS-1:0] write_cs [`CACHE_LINES-1:0];
    reg [$clog2(`CACHE_WAYS)-1:0] cover_idx;
    reg [$clog2(`CACHE_WAYS)-1:0] last_acc_idx;
    wire [5:0] index;
    reg found;
    assign index = addr[9:4];
    assign hit = (|way_hit);

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

    task update_hitstatus();
        if (read_enable || write_enable) begin
            way_cs[index] = way_hit;
            dirty = 1'b0;
            if(|way_hit) begin
                // 常规读写命中时，更新
                for (i = 0; i < `CACHE_WAYS; i = i + 1) begin
                    if (way_hit[i]) begin
                        write_cs[index][i] <= 1'b1;
                        last_acc_idx <= i[$clog2(`CACHE_WAYS)-1:0];
                    end
                end
            end
        end
    endtask
    
    integer i,j,n;
    
    always @(addr or posedge load_enable or posedge write_enable or posedge read_enable) begin
        save_ready = 1'b0;
        if (status == `S_IDLE) begin
            if (read_enable) begin
                // 读取状态下直接返回，不要等待状态
                status_ready = 1'b1;
                update_hitstatus();
            end
            else begin
                status_ready = 1'b0;
                status = `S_ADDR;
            end
            if (&write_cs[index]) begin
                write_cs[index] = {`CACHE_WAYS{1'b0}};
                write_cs[last_acc_idx] = 1;
            end
            found = 0;
            for (i = 0; i < `CACHE_WAYS; i = i + 1) begin
                if (!found && !write_cs[index][i]) begin
                    cover_idx = i[$clog2(`CACHE_WAYS)-1:0];
                    found = 1'b1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(j=0;j<`CACHE_LINES;j=j+1) begin
                write_cs[j] <= {`CACHE_WAYS{1'b0}};
                way_cs[j] <=  {`CACHE_WAYS{1'b0}};
                cover_idx <= 0;
            end
            status <= `S_IDLE;
            dirty <= 1'b0;
            last_acc_idx <= 0;
            status_ready <= 1'b0;
        end
        else begin
            case (status)
                `S_ADDR: begin
                    if(!load_enable) begin
                        update_hitstatus();
                        status <= `S_IDLE;
                    end
                    else begin
                        way_cs[index][cover_idx] <= 1'b1;
                        dirty <= dirty_status[cover_idx];
                        status <= `S_WRITELOAD;
                    end
                    status_ready <= 1'b1;
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
    reg [2:0] status;
    reg begin_load;
    wire load_save_ready;

    
    cache_set cache_set_inst(
        .clk(clk),
        .rst_n(rst_n),
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

    always @(posedge status_ready) begin
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

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            save_data <= 0;
            load_complate <= 0;
            begin_load <= 0;
            status <= `IDLE;
        end
        else begin
            case (status)
                `IDLE: begin
                    load_complate <= 0;
                    begin_load <= 0;
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