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

 Description: digital flash
        片外存储读取，支持digital软件中的rom
 */
`include "config.v"

module digital_flash(
    input wire flashclk,
    input wire rst,
    input wire [`MAX_BIT_POS:0] flash_io_addr,
    input wire flash_io_read,
    input wire flash_io_write,
    input wire flash_read_ready,
    input wire [`MAX_BIT_POS:0] flash_io_wdata,
    input wire [1:0] io_byte_size,
    output reg [`MAX_BIT_POS:0] flash_io_rdata,
    output reg flash_io_ready,

    //digital外部接口
    output reg [`MAX_BIT_POS:0] digital_flash_addr,
    output reg digital_flash_write_en,
    output reg digital_flash_read_en,
    output reg [2:0] digital_flash_byte_size,
    output reg [7:0] digital_flash_wdata,
    input wire [7:0] digital_flash_data,
    input wire digital_flash_ready
);
    localparam IDLE = 2'd0;
    localparam WAIT_PROC = 2'd1;
    localparam DO_PROC  = 2'd2;
    localparam COMPLATE_PROC = 2'd3;


    reg [1:0] byte_count;
    wire [1:0] byte_size;
    reg [1:0] state;
    reg [1:0] next_state;

    assign byte_size = (io_byte_size == 0) ? 2'd3 : (io_byte_size - 2'd1);

    always @(*) begin
        if (state == IDLE && (flash_io_read || flash_io_write)) begin
            next_state = WAIT_PROC;
        end
        else if (state == WAIT_PROC) begin
            next_state = DO_PROC;
        end
        else if (state == DO_PROC) begin
            next_state = flash_io_ready ? COMPLATE_PROC : DO_PROC;
        end
        else if (state == COMPLATE_PROC) begin
            //保持一个周期读取
            next_state = IDLE;
        end
        else begin
            next_state = IDLE;
        end
    end

    always @(posedge flashclk or negedge rst) begin
        if(!rst) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @(posedge flashclk or negedge rst) begin
        if(!rst) begin
            flash_io_ready <= 1'b0;
            // digital 固定位4字节
            digital_flash_byte_size <= 0;
            digital_flash_write_en <= 1'b0;
            byte_count <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    byte_count <= 0;
                    flash_io_ready <= 1'b0;
                    digital_flash_write_en <= 1'b0;
                    digital_flash_read_en <= 1'b0;
                end
                WAIT_PROC: begin
                    flash_io_rdata <= 0;
                    digital_flash_addr <= flash_io_addr;
                    digital_flash_read_en <= flash_io_read;
                end
                DO_PROC: begin
                    if(flash_io_read && !flash_io_ready) begin
                        if (byte_count <= byte_size && digital_flash_ready) begin
                            flash_io_rdata[byte_count*8 +: 8] <= digital_flash_data;
                            digital_flash_addr <= digital_flash_addr + `XLEN'd1;
                            flash_io_ready <= (byte_count == byte_size);
                            byte_count <= byte_count + 1;
                        end
                    end
                    else if(flash_io_write && !flash_io_ready) begin
                        digital_flash_write_en <= 1'b1;
                        if (byte_count <= byte_size && digital_flash_ready) begin
                            digital_flash_wdata <= flash_io_wdata[byte_count*8 +: 8];
                            digital_flash_addr <= digital_flash_addr + `XLEN'd1;
                            flash_io_ready <= (byte_count == byte_size);
                            byte_count <= byte_count + 1;
                        end
                    end
                end
                COMPLATE_PROC: begin
                    digital_flash_write_en <= 1'b0;
                    digital_flash_read_en <= 1'b0;
                end
            endcase
        end
    end

endmodule