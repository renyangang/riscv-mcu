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
    input wire [7:0] digital_flash_data
);
    reg [1:0] byte_count;
    wire [1:0] byte_size;

    assign byte_size = (io_byte_size == 0) ? 2'd3 : (io_byte_size - 2'd1);

    always @(flash_io_addr or flash_io_read or flash_io_write) begin
        flash_io_ready = 1'b0;
        byte_count = 0;
        flash_io_rdata = `XLEN'd0;
        digital_flash_addr = flash_io_addr;
        digital_flash_read_en = flash_io_read;
    end

    always @(posedge flashclk or negedge rst) begin
        if(!rst) begin
            flash_io_ready <= 1'b0;
            // digital 固定位4字节
            digital_flash_byte_size <= 4'b1111;
            digital_flash_write_en <= 1'b0;
            digital_flash_read_en <= 1'b0;
            byte_count <= 0;
        end
        else if(flash_io_read && !flash_io_ready) begin
            if (byte_count <= byte_size) begin
                flash_io_rdata[byte_count*8 +: 8] <= digital_flash_data;
                digital_flash_addr = digital_flash_addr + `XLEN'd1;
                flash_io_ready <= (byte_count == byte_size);
                byte_count += 1;
            end
            digital_flash_write_en <= 1'b0;
        end
        else if(flash_io_write && !flash_io_ready) begin
            digital_flash_write_en <= 1'b1;
            if (byte_count <= byte_size) begin
                digital_flash_wdata <= flash_io_wdata[byte_count*8 +: 8];
                digital_flash_addr = digital_flash_addr + `XLEN'd1;
                flash_io_ready <= (byte_count == byte_size);
                byte_count += 1;
            end
            else begin
                flash_io_ready <= 1'b1;
                digital_flash_write_en <= 1'b0;
            end
        end
        else begin
            flash_io_ready <= 1'b0;
            digital_flash_write_en <= 1'b0;
        end
    end

    

endmodule