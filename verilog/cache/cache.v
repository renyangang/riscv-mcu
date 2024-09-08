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
       
module cache_way #(
    parameter CACHE_LINES = 64,
    parameter BLOCK_SIZE = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,   
    input wire [31:0] wdata,  
    input wire write_enable,
    input wire cs, // cache select
    output reg [31:0] rdata,  
    output reg hit,
    output reg busy,
    output reg dirty_status,
    output reg pre_hit
);
    
    reg [31:0] cache_data [CACHE_LINES-1:0][BLOCK_SIZE/4-1:0]; 
    reg [21:0] tag [CACHE_LINES-1:0];                          
    reg valid [CACHE_LINES-1:0];
    reg dirty [CACHE_LINES-1:0];                               

    wire [5:0] index = addr[9:4];      
    wire [3:0] offset = addr[3:0];     
    wire [21:0] tag_in = addr[31:10];


    always @(addr) begin
        pre_hit <= (valid[index] && (tag[index] == tag_in))? 1'b1:1'b0;
        busy <= valid[index];
        dirty_status <= dirty[index];
    end

    integer i, j;

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < CACHE_LINES; i = i + 1) begin
                valid[i] <= 0;
                tag[i] <= 0;
                for (j = 0; j < BLOCK_SIZE/4; j = j + 1)
                    cache_data[i][j] <= 0;
            end
        end
    end

    
    always @(posedge clk) begin
        if(cs) begin
            if (write_enable) begin
                // 写入缓存
                cache_data[index][offset >> 2] <= wdata; 
                tag[index] <= tag_in;                   
                valid[index] <= 1;
                dirty[index] <= 1;                    
            end
            else begin
                if (valid[index] && (tag[index] == tag_in)) begin
                    hit <= 1;  
                    rdata <= cache_data[index][offset >> 2];  
                end
                else begin
                    hit <= 0;  
                    rdata <= 32'h0;
                end
            end
        end
        else begin
            rdata <= 32'hz;
            hit <= 0;
        end
    end
endmodule

`define CLEAR_HIT_CS \
            way_cs[0] <= 0; \
            way_cs[1] <= 0; \
            way_cs[2] <= 0; \
            way_cs[3] <= 0; \
            hit <= 0;
module cache_set #(
    parameter CACHE_WAYS = 4,
    parameter CACHE_LINES = 64,
    parameter BLOCK_SIZE = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [31:0] addr,   
    input wire [31:0] wdata,  
    input wire write_enable,
    output wire [31:0] rdata,
    output reg hit
);

    wire pre_hit [CACHE_WAYS-1:0];
    wire way_hit [CACHE_WAYS-1:0];
    reg way_cs [CACHE_WAYS-1:0];
    wire way_status [CACHE_WAYS-1:0];
    wire dirty_status [CACHE_WAYS-1:0];
    reg [CACHE_WAYS*2-1:0] write_cs; 

    genvar i_way;
    generate
        for (i_way = 0; i_way < CACHE_WAYS; i_way = i_way + 1) begin : cache_way_gen
            cache_way #(CACHE_LINES, BLOCK_SIZE) cache_way_inst (
                .clk(clk),
                .rst_n(rst_n),
                .addr(addr),
                .wdata(wdata),
                .write_enable(write_enable),
                .cs(way_cs[i_way]),
                .rdata(rdata),
                .busy(way_status[i_way]),
                .dirty_status(dirty_status[i_way]),
                .hit(way_hit[i_way]),
                .pre_hit(pre_hit[i_way])
            );
        end
    endgenerate

    integer i;
    always @(addr) begin
        for (i = 0; i < CACHE_WAYS; i = i + 1) begin
            if (pre_hit[i]) begin
                way_cs[i] = 1'b1;
                hit = 1'b1;
                if (write_cs[i] == 1'b0) begin
                    write_cs[i] = 1'b1;
                end
                else if (write_cs[i+CACHE_WAYS] == 1'b0) begin
                    write_cs[i+CACHE_WAYS] = 1'b1;
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            `CLEAR_HIT_CS;
            write_cs <= 0;
        end
        if (write_enable && !hit) begin
            write_cs
        end
    end

    always @(negedge clk) begin
        `CLEAR_HIT_CS;
        if (&write_cs) begin
            write_cs <= 0;
        end
    end

endmodule



module cache(
    input wire clk,
    input wire rst,
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire write_enable,
    output reg hit,
    output reg [31:0] data_out
);

    parameter CACHE_SIZE = 32 * 1024;
    parameter SET_NUM = 2;
    parameter SET_SIZE = 4;
    parameter LINE_NUM = 256;
    parameter BLOCK_SIZE = 16;

    
    reg [31:0] cache_data [SET_NUM-1:0][SET_SIZE-1:0][LINE_NUM-1:0][BLOCK_SIZE/4-1:0]; 
    reg [21:0] tag [SET_NUM-1:0][SET_SIZE-1:0][LINE_NUM-1:0];
    reg valid [SET_NUM-1:0][SET_SIZE-1:0][LINE_NUM-1:0];


endmodule