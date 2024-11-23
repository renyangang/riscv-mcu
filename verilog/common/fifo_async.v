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

Description: async fifo

*/

module fifo_async #(parameter DEPTH = 16, parameter WIDTH = 8) (
    input wclk,
    input rclk,
    input rst,
    input wr_en,
    input rd_en,
    input [WIDTH-1:0] wr_data,
    output reg [WIDTH-1:0] rd_data,
    output wr_full,
    output rd_empty
);

reg  [WIDTH-1:0] data [DEPTH-1:0];
reg  [$clog2(DEPTH):0] wr_ptr = 4'd0;
reg  [$clog2(DEPTH):0] rd_ptr = 4'd0;

wire [$clog2(DEPTH)-1:0] wr_addr;
wire [$clog2(DEPTH)-1:0] rd_addr;

wire [$clog2(DEPTH):0] wr_ptr_gray;
wire [$clog2(DEPTH):0] rd_ptr_gray;
reg  [$clog2(DEPTH):0] wr_ptr_gray_1;
reg  [$clog2(DEPTH):0] wr_ptr_gray_2;
reg  [$clog2(DEPTH):0] rd_ptr_gray_1;
reg  [$clog2(DEPTH):0] rd_ptr_gray_2;
 
assign wr_addr = wr_ptr[$clog2(DEPTH)-1:0]; 
assign rd_addr = rd_ptr[$clog2(DEPTH)-1:0];
 
assign wr_ptr_gray = ((wr_ptr>>1) ^ wr_ptr); //指针转格雷码
assign rd_ptr_gray = ((rd_ptr>>1) ^ rd_ptr);

assign rd_empty = (rd_ptr_gray == wr_ptr_gray_2);
assign wr_full  = (wr_ptr_gray == {~rd_ptr_gray_2[3:2], rd_ptr_gray_2[1:0]});
 
always@(posedge wclk or negedge rst) begin
    if(!rst) begin
        wr_ptr <= 4'd0;
    end
    else if(wr_en && !wr_full)begin
        data[wr_addr] <= wr_data;
        wr_ptr <= wr_ptr + 4'd1;
    end
end
 
always@(posedge rclk or negedge rst) begin
    if(!rst)
        rd_ptr <= 4'd0;
    else if(rd_en && !rd_empty)begin
        rd_data  <= data[rd_addr];
        rd_ptr <= rd_ptr + 4'd1;
    end
end
 
always@(posedge wclk or negedge rst) begin
    if(!rst)begin
        rd_ptr_gray_1 <= 4'd0;
        rd_ptr_gray_2 <= 4'd0;
    end
    else begin
        rd_ptr_gray_1 <= rd_ptr_gray;
        rd_ptr_gray_2 <= rd_ptr_gray_1;
    end
end
 
always@(posedge rclk or negedge rst) begin
    if(!rst)begin
        wr_ptr_gray_1 <= 4'd0;
        wr_ptr_gray_2 <= 4'd0;
    end
    else begin
        wr_ptr_gray_1 <= wr_ptr_gray;
        wr_ptr_gray_2 <= wr_ptr_gray_1;
    end
end

endmodule