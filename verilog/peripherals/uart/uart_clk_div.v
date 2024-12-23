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

module uart_clk_div(
    input clk,
    input rst_n,
    input [15:0] uart_clk_div, // 波特率时钟分频数，整数部分  主频/(波特率 * 16)
    input [4:0] uart_clk_frag_total, // 每16个整数周期中，小数分频添加个数  (主频 % (波特率 * 16)) * 16
    input [3:0] uart_clk_frag_i, // 小数添加间隔 1 / (主频 % (波特率 * 16))
    output reg clk_sample,
    output reg clk_uart
);

    reg [15:0] div_cnt;
    reg [4:0] frag_cnt_16;
    reg frag_en;
    reg [3:0] frag_cnt_i;
    reg [4:0] frag_cnt;
    reg [1:0] uart_cnt;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt <= 16'b0;
            clk_sample <= 1'b0;
        end
        else begin
            if (((div_cnt == uart_clk_div - 1) && !frag_en) || ((div_cnt == uart_clk_div) && frag_en)) begin
                clk_sample <= ~clk_sample;
                div_cnt <= 16'b0;
            end
            else begin
                div_cnt <= div_cnt + 1;
            end
        end
    end

    always @(posedge clk_sample or negedge rst_n) begin
        if (!rst_n) begin
            frag_cnt_16 <= 5'b0;
            frag_cnt_i <= 4'b0;
            frag_cnt <= 5'b0;
            frag_en <= 1'b0;
        end
        else begin
            if (frag_cnt_16 == 15) begin
                frag_cnt_16 <= 0;
                frag_cnt <= 5'b0;
            end
            else begin
                frag_cnt_16 <= frag_cnt_16 + 1;
            end
            if (frag_cnt_i == uart_clk_frag_i) begin
                frag_en <= frag_cnt > uart_clk_frag_total ? 1'b0 : 1'b1;
                frag_cnt <= frag_cnt > uart_clk_frag_total ? frag_cnt : (frag_cnt + 1);
                frag_cnt_i <= 0;
            end
            else begin
                frag_cnt_i <= frag_cnt_i + 1;
                frag_en <= 1'b0;
            end
        end
    end

    always @(posedge clk_sample or negedge rst_n) begin
        if (!rst_n) begin
            uart_cnt <= 2'b0;
            clk_uart <= 1'b0;
        end
        else begin
            if (uart_cnt == 3) begin
                uart_cnt <= 2'b0;
                clk_uart <= ~clk_uart;
            end
            else begin
                uart_cnt <= uart_cnt + 1;
            end
        end
    end

endmodule