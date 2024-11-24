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

Description: UART TX module

*/

module uart_tx(
    input clk_uart,
    input rst,
    input [7:0] tx_data,
    input tx_start,
    input [1:0] parity_mode,
    input [1:0] stop_bit,
    output reg tx,
    output reg tx_busy
);

reg [2:0] tx_cnt;
reg rx_parity;
reg [1:0] tx_state;
reg [4:0] tx_h_cnt;

localparam TX_IDLE = 0, TX_DATA = 1, TX_PARITY = 2, TX_STOP = 3;
localparam PARITY_NONE = 0, PARITY_EVEN = 1, PARITY_ODD = 2;

always @(posedge clk_uart or negedge rst) begin
    if (!rst) begin
        tx_cnt <= 3'b0;
        tx_state <= TX_IDLE;
        tx_busy <= 1'b0;
        tx <= 1'b1;
    end
    else begin
        case (tx_state)
            TX_IDLE: begin
                if (tx_start) begin
                    tx_cnt <= 3'b0;
                    tx_state <= TX_DATA;
                    tx_busy <= 1'b1;
                    tx <= 1'b0;
                end
                else begin
                    tx_busy <= 1'b0;
                    tx <= 1'b1;
                end
            end
            TX_DATA: begin
                tx_cnt <= tx_cnt + 1;
                tx <= tx_data[tx_cnt];
                tx_h_cnt <= tx_data[tx_cnt] ? (tx_h_cnt + 1) : tx_h_cnt;
                if (tx_cnt == 7) begin
                    tx_state <= parity_mode == PARITY_NONE ? TX_STOP : TX_PARITY;
                    tx_cnt <= 3'b0;
                end
            end
            TX_PARITY: begin
                if (parity_mode == PARITY_EVEN) begin
                    tx <= tx_h_cnt[0];
                end
                else if (parity_mode == PARITY_ODD) begin
                    tx <= (~tx_h_cnt[0]);
                end
                tx_h_cnt <= 5'b0;
                tx_state <= TX_STOP;
            end
            TX_STOP: begin
                tx_cnt <= tx_cnt + 1;
                tx <= 1'b1;
                if (tx_cnt >= {1'b0,stop_bit}) begin
                    tx_cnt <= 3'b0;
                    tx_state <= TX_IDLE;
                    tx_busy <= 1'b0;
                end
            end
        endcase
    end
end

endmodule