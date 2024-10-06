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

 Description: off chip ram
        片外内存读写，支持Digital模拟软件内存、SDRAM、DDR SDRAM等，根据实际情况适配
        当前版本只支持digital
 */
`include "config.v"

module off_chip_ram(
    input clk,
    input rst,
    
    input [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata,
    input offchip_mem_write_en,
    input offchip_mem_read_en,
    input [`MAX_BIT_POS:0] offchip_mem_addr,
    output reg [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data,
    output reg offchip_mem_ready,

    output wire [`MAX_BIT_POS:0] digital_mem_addr,
    output reg digital_mem_write_en,
    output reg digital_mem_read_en,
    output reg [`MAX_BIT_POS:0] digital_mem_wdata,
    output reg [3:0] digital_mem_byte_size,
    input [`MAX_BIT_POS:0] digital_mem_data
);
    reg [$clog2(`CACHE_LINE_SIZE)-1:0] rw_count;

    assign digital_mem_addr = offchip_mem_addr;

    always @(offchip_mem_addr or offchip_mem_write_en or offchip_mem_read_en) begin
        offchip_mem_ready = 1'b0;
        // digital_mem_write_en = offchip_mem_write_en;
        digital_mem_read_en = offchip_mem_read_en;
        rw_count = 0;
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            offchip_mem_ready <= 1'b0;
            // digital 固定位4字节
            digital_mem_byte_size <= 4'b1111;
            digital_mem_write_en <= 1'b0;
            digital_mem_read_en <= 1'b0;
            rw_count <= 0;
        end
        else if(offchip_mem_read_en && !offchip_mem_ready) begin
            offchip_mem_data[rw_count*32 +: 32] <= digital_mem_data;
            rw_count <= rw_count + 4;
            if(rw_count == `CACHE_LINE_SIZE-1) begin
                offchip_mem_ready <= 1'b1;
            end
        end
        else if(offchip_mem_write_en && !offchip_mem_ready) begin
            digital_mem_wdata <= offchip_mem_wdata[rw_count*32 +: 32];
            digital_mem_write_en <= 1'b1;
            rw_count <= rw_count + 4;
            if(rw_count == `CACHE_LINE_SIZE-1) begin
                offchip_mem_ready <= 1'b1;
                digital_mem_write_en <= 1'b0;
            end
        end
    end

    

endmodule