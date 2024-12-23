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

 Description: digital ram
        片外内存读写，支持Digital模拟软件内存
 */
`include "config.v"

module digital_ram(
    input wire ramclk,
    input wire rst_n,
    input wire [`MAX_BIT_POS:0] mem_io_addr,
    input wire mem_io_read,
    input wire mem_io_write,
    input wire mem_read_ready,
    input wire [`MAX_BIT_POS:0] mem_io_wdata,
    input wire [1:0] io_byte_size,
    output wire [`MAX_BIT_POS:0] mem_io_rdata,
    output reg mem_io_ready,

    //digital外部接口
    output wire [`MAX_BIT_POS:0] digital_mem_addr,
    output reg digital_mem_write_en,
    output reg digital_mem_read_en,
    output reg [3:0] digital_mem_byte_size,
    output reg [`MAX_BIT_POS:0] digital_mem_wdata,
    input wire [`MAX_BIT_POS:0] digital_mem_data,
    input wire digital_mem_ready
);
    localparam IDLE = 2'd0, WAIT_PROC = 2'd1, DO_PROC = 2'd2, COMPLATE_PROC = 2'd3;

    reg [1:0] byte_count;
    wire [1:0] byte_size;
    reg [1:0]state;
    reg [1:0]next_state;

    assign byte_size = (io_byte_size == 0) ? 2'd3 : (io_byte_size - 2'd1);
    assign digital_mem_addr = mem_io_addr;
    assign mem_io_rdata = digital_mem_data;

    always @(*) begin
        if (state == IDLE && (mem_io_read || mem_io_write)) begin
            next_state = WAIT_PROC;
        end
        else if (state == WAIT_PROC) begin
            next_state = (mem_io_read | mem_io_write) ? DO_PROC : IDLE;
        end
        else if (state == DO_PROC) begin
            next_state = (mem_io_read | mem_io_write) ? (mem_io_ready ? COMPLATE_PROC : DO_PROC) : IDLE;
        end
        else if (state == COMPLATE_PROC) begin
            //保持一个周期读取
            next_state = IDLE;
        end
        else begin
            next_state = IDLE;
        end
    end

    integer i;
    always @(mem_io_wdata or io_byte_size) begin
        byte_count = 0;
        if (mem_io_write) begin
            digital_mem_wdata = `XLEN'd0;
            digital_mem_byte_size = 4'b0000;
            for (i = 0; i < `XLEN/8; i = i + 1) begin
                if (byte_count <= byte_size) begin
                    digital_mem_wdata[i*8 +: 8] = mem_io_wdata[i*8 +: 8];
                    byte_count = byte_count + 1;
                end
            end
            digital_mem_byte_size[byte_count-1] = 1'b1;
        end
        else begin
            // digital 固定位4字节
            digital_mem_byte_size = 4'b1111;
        end
    end

    always @(posedge ramclk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge ramclk or negedge rst_n) begin
        if(!rst_n) begin
            mem_io_ready <= 1'b0;
            digital_mem_write_en <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    mem_io_ready <= 1'b0;
                    digital_mem_write_en <= 1'b0;
                    digital_mem_read_en <= 1'b0;
                end
                WAIT_PROC: begin
                    digital_mem_read_en <= mem_io_read;
                end
                DO_PROC: begin
                    if(mem_io_read && !mem_io_ready) begin
                        mem_io_ready <= digital_mem_ready;
                        digital_mem_write_en <= 1'b0;
                    end
                    else if(mem_io_write && !mem_io_ready) begin
                        digital_mem_write_en <= 1'b1;
                        mem_io_ready <= digital_mem_ready;
                    end
                end
                COMPLATE_PROC: begin
                    mem_io_ready <= 1'b1;
                    digital_mem_write_en <= 1'b0;
                    digital_mem_read_en <= 1'b0;
                end
            endcase
        end
    end
    

endmodule