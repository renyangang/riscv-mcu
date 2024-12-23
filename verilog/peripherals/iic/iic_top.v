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
    File Name   : iic_top.v
    Module Name : iic_top
*/
`include "config.v"

module iic_top(
    input clk,
    input rst_n,
    output iic_scl,
    inout iic_sda,
    input wire iic_reg_wr_en,
    input wire iic_reg_rd_en,
    // offset [7:0] 8'h00 config 8'h04 write info 8'h08 data 
    // write info: [7:0] dev addr [15:8] reg addr [23:16] datalen max datalen is 4 bytes [63:24] data
    input wire [`MAX_BIT_POS:0]   iic_reg_addr,  
    input wire [`MAX_BIT_POS:0]   iic_reg_wdata,
    output reg [`MAX_BIT_POS:0]  iic_reg_rdata,
    output reg iic_ready,
    output wire data_ready_int,  // data ready interrupt
    output wire write_ready_int // write ready interrupt
);

// [1:0] mode config 0:standard mode, 1:fast mode, 2:high-speed mode
// other bits reserved
reg [`MAX_BIT_POS:0] iic_reg_addr_r;
reg [1:0] data_offset;

localparam CONFIG_OFFSET = 8'h00, DATA_OFFSET = 8'h04;
localparam S_IDLE = 2'b00, S_WRITE = 2'b01, S_READ = 2'b10;

// 64 bytes tx ram， [0] rw [7:1] dev addr [15:8] reg addr [23:16] datalen [63:24] data
reg [63:0] tx_ram;
reg [31:0] rx_ram; // 4 bytes rx ram,max datalen is 4 bytes

always @(posedge clk or posedge rst_n) begin
end

endmodule