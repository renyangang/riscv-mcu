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

Description: High low adapter

高频到低频的通信适配模块，用于在cpu内部访问外部digital慢时钟设备

*/
`include "config.v"


module hl_adapter #(parameter WIDTH = 32) (
    input clk_h,
    input rst,
    input clk_l,
    input h_read_en,
    input h_write_en,
    input [`MAX_BIT_POS:0]h_addr,
    input [WIDTH-1:0]h_data_in,
    output reg h_data_ready,
    output reg [WIDTH-1:0]h_data_out,

    output reg l_read_en,
    output reg l_write_en,
    output reg [`MAX_BIT_POS:0]l_addr,
    output reg [WIDTH-1:0]l_data_in,
    input [WIDTH-1:0]l_data_out
);

    localparam L_IDLE = 0, L_WAIT = 1, L_READY = 2;
    localparam H_IDLE = 0, H_WAIT = 1, H_READY = 2;

    reg [1:0]l_state;
    reg [1:0]l_state_next;
    reg [1:0]h_state;
    reg [1:0]h_state_next;
    reg l_data_ready;
    reg l_data_wait;

    always @(posedge clk_h or posedge rst) begin
        if (!rst) begin
            h_state <= H_IDLE;
        end
        else begin
            h_state <= h_state_next;
        end
    end

    always @(*) begin
        if (!rst) begin
            h_state_next = H_IDLE;
        end
        else begin
            case (h_state) 
                H_IDLE: begin
                    h_state_next = ((h_read_en | h_write_en) && l_state == L_IDLE) ? H_WAIT : H_IDLE;
                end
                H_WAIT: begin
                    h_state_next = l_data_ready ? H_READY : H_WAIT;
                end
                H_READY: begin
                    h_state_next = H_IDLE;
                end
                default: begin
                    h_state_next = h_state;
                end
            endcase
        end
    end

    always @(posedge clk_h or posedge rst) begin
        if (!rst) begin
            h_data_ready <= 0;
            h_data_out <= 0;
            l_data_wait <= 0;
        end
        else begin
            case (h_state) 
                H_IDLE: begin
                    h_data_ready <= 0;
                    h_data_out <= 0;
                    l_data_wait <= 0;
                end
                H_WAIT: begin
                    l_data_wait <= 1;
                end
                H_READY: begin
                    h_data_ready <= 1;
                    h_data_out <= l_data_out;
                    l_data_wait <= 0;
                end
                default: begin
                end
            endcase
        end
    end

    always @(posedge clk_l or posedge rst) begin
        if (!rst) begin
            l_state <= L_IDLE;
        end
        else begin
            l_state <= l_state_next;
        end
    end

    always @(*) begin
        if (!rst) begin
            l_state_next = L_IDLE;
        end
        else begin
            case (l_state) 
                L_IDLE: begin
                    l_state_next = (l_data_wait) ? L_WAIT : L_IDLE;
                end
                L_WAIT: begin
                    l_state_next = L_READY;
                end
                L_READY: begin
                    l_state_next = (l_data_wait) ? L_READY : L_IDLE;
                end
                default: begin
                    l_state_next = l_state;
                end
            endcase
        end
    end

    always @(posedge clk_l or posedge rst) begin
        if (!rst) begin
            l_read_en <= 0;
            l_write_en <= 0;
            l_addr <= 0;
            l_data_in <= 0;
            l_data_ready <= 0;
        end
        else begin
            case (l_state) 
                L_IDLE: begin
                    l_read_en <= 0;
                    l_write_en <= 0;
                    l_addr <= 0;
                    l_data_in <= 0;
                    l_data_ready <= 0;
                end
                L_WAIT: begin
                    l_read_en <= h_read_en;
                    l_write_en <= h_write_en;
                    l_addr <= h_addr;
                    l_data_in <= h_data_in;
                end
                L_READY: begin
                    l_read_en <= 0;
                    l_write_en <= 0;
                    l_addr <= 0;
                    l_data_in <= 0;
                    l_data_ready <= 1;
                end
                default: begin
                end
            endcase
        end
    end

endmodule