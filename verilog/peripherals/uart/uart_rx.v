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

Description: UART RX module

*/

module uart_rx(
    input clk_sample,
    input rst,
    input rx,
    input [1:0] parity_mode,
    input [1:0] stop_bit,
    output reg [7:0] rx_data,
    output reg rx_data_ready
);

reg [2:0] rx_sample_cnt;
reg [2:0] rx_cnt;
reg [7:0] rx_shift;
reg rx_parity;
reg rx_reg1;
reg rx_reg2;
reg [2:0] rx_state;
reg [4:0] rx_1_cnt;
reg [3:0] rx_t_cnt; // 高频采样，统计1的次数
reg [3:0] rx_f_cnt; // 高频采样，统计0的次数

localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_PARITY = 3, RX_STOP = 4;
localparam PARITY_NONE = 0, PARITY_EVEN = 1, PARITY_ODD = 2;

always @(posedge clk_sample or negedge rst) begin
    if (!rst) begin
        rx_reg1 <= 1'b1;
        rx_reg2 <= 1'b1;
    end else begin
        rx_reg1 <= rx;
        rx_reg2 <= rx_reg1;
    end
end

always @(posedge clk_sample or negedge rst) begin
    if (!rst) begin
        rx_state <= RX_IDLE;
        rx_cnt <= 3'b0;
        rx_sample_cnt <= 3'd0;
        rx_t_cnt <= 4'd0;
        rx_f_cnt <= 4'd0;
        rx_data_ready <= 1'b0;
        rx_shift <= 8'b0;
    end
    else begin
        case(rx_state)
            RX_IDLE: begin
                if (!rx_reg2) begin
                    rx_cnt <= 3'b0;
                    rx_state <= RX_START;
                    rx_sample_cnt <= 3'b0;
                    rx_data_ready <= 1'b0;
                end
            end
            RX_START: begin
                rx_sample_cnt <= rx_sample_cnt + 1;
                if (rx_sample_cnt == 3'd7) begin
                    rx_state <= RX_DATA;
                    rx_cnt <= 3'd0;
                    rx_sample_cnt <= 3'd0;
                    rx_t_cnt <= 4'd0;
                    rx_f_cnt <= 4'd0;
                    rx_shift <= 8'b0;
                    rx_1_cnt <= 5'd0;
                end
            end
            RX_DATA: begin
                rx_sample_cnt <= rx_sample_cnt + 1;
                if (rx_reg2) begin
                    rx_t_cnt <= rx_t_cnt + 1'b1;
                end
                else begin
                    rx_f_cnt <= rx_f_cnt + 1'b1;
                end
                if (rx_sample_cnt == 3'd7) begin
                    if (rx_t_cnt > rx_f_cnt) begin
                        rx_1_cnt <= rx_1_cnt + 1'b1;
                    end
                    rx_shift <= {rx_t_cnt > rx_f_cnt ? 1'b1 : 1'b0, rx_shift[7:1]};
                    rx_cnt <= rx_cnt + 1;
                    rx_sample_cnt <= 3'd0;
                    rx_t_cnt <= 4'd0;
                    rx_f_cnt <= 4'd0;
                    rx_parity = rx_t_cnt > rx_f_cnt ? 1'b1 : 1'b0;
                    if (rx_cnt == 3'd7) begin
                        rx_state <= parity_mode == PARITY_NONE ? (stop_bit > 0 ? RX_STOP : RX_IDLE) : RX_PARITY;
                        if (parity_mode == PARITY_NONE && stop_bit == 0) begin
                            rx_data_ready <= 1'b1;
                            rx_data <= rx_shift;
                        end
                        rx_cnt <= 3'b0;
                    end
                end
            end
            RX_PARITY: begin
                rx_sample_cnt <= rx_sample_cnt + 1;
                if (rx_reg2) begin
                    rx_t_cnt <= rx_t_cnt + 1'b1;
                end
                else begin
                    rx_f_cnt <= rx_f_cnt + 1'b1;
                end
                if (rx_sample_cnt == 3'd7) begin
                    rx_parity = rx_t_cnt > rx_f_cnt ? 1'b1 : 1'b0;
                    rx_sample_cnt <= 3'd0;
                    rx_t_cnt <= 4'd0;
                    rx_f_cnt <= 4'd0;
                    rx_1_cnt <= 5'd0;
                    if (((parity_mode == PARITY_ODD) && (rx_parity != rx_1_cnt[0])) || ((parity_mode == PARITY_EVEN) && (rx_parity == rx_1_cnt[0]))) begin
                        rx_state <= RX_STOP;
                    end
                    else begin
                        rx_state <= RX_IDLE; // 校验失败
                    end
                end
            end
            RX_STOP: begin
                rx_sample_cnt <= rx_sample_cnt + 1;
                rx_data_ready <= 1'b1;
                rx_data <= rx_shift;
                if (rx_sample_cnt == 3'd7) begin
                    rx_cnt <= rx_cnt + 1;
                    rx_sample_cnt <= 3'd0;
                    if (rx_cnt == (stop_bit - 1)) begin
                        rx_state <= RX_IDLE;
                        rx_cnt <= 3'd0;
                    end
                end
            end
        endcase
    end
end

endmodule