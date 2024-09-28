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

 Description: interrupts bus
中断总线
 */

`include "registers_csr.v"

module int_bus(
    input  wire        clk,
    input  wire        rst,
    input [31:0] pc,
    input [31:0] pc_next,
    input [31:0] inst_cur,
    input [31:0] exception_code,
    input exception_en,
    input cur_branch_hazard,

    output wire jmp_en,
    output wire [31:0] jmp_pc,

    input wire clk_timer,
    input wire [31:0] mtimecmp_low,
    input wire [31:0] mtimecmp_high,
    output wire [31:0] mtime_low,
    output wire [31:0] mtime_high,

    input wire [11:0] csr_read_addr,
    input wire [11:0] csrw_addr,
    input wire [31:0] w_data,
    input wire write_en,
    output wire [31:0] csr_out,

    input soft_int,
    input [7:0]soft_int_code,
    output wire [7:0] cur_int_code,

    input gpio_int,
    input uart_int,
    input iic_int,
    input spi_int
);

    reg peripheral_int;
    reg [7:0]peripheral_int_code;

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            peripheral_int <= 1'b0;
        end 
        else begin
            if (!peripheral_int) begin
                if (gpio_int) begin
                    peripheral_int <= 1'b1;
                    peripheral_int_code <= 8'h1;
                end
                else if (uart_int) begin
                    peripheral_int <= 1'b1;
                    peripheral_int_code <= 8'h2;
                end
                else if (iic_int) begin
                    peripheral_int <= 1'b1;
                    peripheral_int_code <= 8'h3;
                end
                else if (spi_int) begin
                    peripheral_int <= 1'b1;
                    peripheral_int_code <= 8'h4;
                end
            end
            else if (peripheral_int && !(gpio_int || uart_int || iic_int || spi_int)) begin
                peripheral_int <= 1'b0;
                peripheral_int_code <= 8'h0;
            end     
        end
    end

    registers_csr registers_csr(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .pc_next(pc_next),
        .inst_cur(inst_cur),
        .exception_code(exception_code),
        .exception_en(exception_en),
        .cur_branch_hazard(cur_branch_hazard),
        .peripheral_int(peripheral_int),
        .peripheral_int_code(peripheral_int_code),
        .soft_int(soft_int),
        .soft_int_code(soft_int_code),
        .cur_int_code(cur_int_code),
        .jmp_en(jmp_en),
        .jmp_pc(jmp_pc),
        .clk_timer(clk_timer),
        .mtimecmp_low(mtimecmp_low),
        .mtimecmp_high(mtimecmp_high),
        .mtime_low(mtime_low),
        .mtime_high(mtime_high),
        .csr_read_addr(csr_read_addr),
        .csrw_addr(csrw_addr),
        .w_data(w_data),
        .write_en(write_en),
        .csr_out(csr_out)
    );

endmodule