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

Description: GPIO module

GPIO 控制模块

*/
`include "config.v"

module gpio(
    input wire rst_n,
    // 用于CPU设置GPIO值
    input  wire       [`GPIO_NUMS-1:0] gpio_set,
    // 用于清除GPIO中断
    input  wire      int_clear,
    input  wire        [`GPIO_NUMS-1:0] gpio_int_clear_set,
    // 用于外设设置GPIO值或者cpu读取GPIO值
    inout  wire       [`GPIO_NUMS-1:0] gpio_values,
    // 控制位，0表示输入，1表示输出
    input  wire       [`GPIO_NUMS-1:0] gpio_ctrl,
    output reg        [`GPIO_NUMS-1:0] gpio_int_set
);
    /* verilator lint_off UNOPTFLAT */
    reg        [`GPIO_NUMS-1:0] gpio_out;
    genvar i;
    generate
        for (i = 0; i < `GPIO_NUMS; i = i + 1) begin : gpio_logic
            assign gpio_values[i] = (gpio_ctrl[i]) ? gpio_out[i] : 1'bz; // 控制输出或高阻态
        end
    endgenerate

    always @(*) begin
        if (rst_n) begin
            if (int_clear) begin
                gpio_int_set = 0;
            end
            gpio_int_set |= (gpio_out & (~gpio_ctrl)) ^ (gpio_values & (~gpio_ctrl));
            gpio_out = (gpio_out & (~gpio_ctrl)) | (gpio_set & gpio_ctrl);
            gpio_out = (gpio_out & gpio_ctrl) | (gpio_values & (~gpio_ctrl));
        end
        else begin
            gpio_int_set = `GPIO_NUMS'b0;
            gpio_out = `GPIO_NUMS'b0;
        end
    end

endmodule

`define GPIO_CONFIG_OFFSET 6'd0
`define GPIO_SET_OFFSET 6'd4
`define GPIO_READ_OFFSET 6'd8
`define GPIO_INT_READ_OFFSET 6'd12
`define GPIO_INT_CLEAR_OFFSET 6'd16
module gpio_controller(
    input wire gpio_clk,
    input wire rst_n,
    input wire [`MAX_BIT_POS:0] io_addr,
    input wire io_read,
    input wire io_write,
    input wire read_ready,
    input wire [`MAX_BIT_POS:0] io_wdata,
    // input wire [(`MAX_BIT_POS/8):0] io_data_mask,
    output reg [`MAX_BIT_POS:0] io_rdata,
    output reg io_ready,
    inout wire [`GPIO_NUMS-1:0] gpio_values,
    output reg gpio_int
);

    wire [5:0]addr_offset;

    assign addr_offset = io_addr[5:0];

    reg      [`GPIO_NUMS-1:0] gpio_set;
    reg      int_clear;
    reg      [`GPIO_NUMS-1:0] gpio_int_clear_set;
    /* verilator lint_off UNOPTFLAT */
    wire     [`GPIO_NUMS-1:0] gpio_int_set;
    reg      [`GPIO_NUMS-1:0] gpio_ctrl;
    


    gpio gpio(
        .rst_n(rst_n),
        .gpio_set(gpio_set),
        .int_clear(int_clear),
        .gpio_values(gpio_values),
        .gpio_ctrl(gpio_ctrl),
        .gpio_int_set(gpio_int_set),
        .gpio_int_clear_set(gpio_int_clear_set)
    );

    always @(posedge gpio_clk or negedge rst_n) begin
        if (!rst_n) begin
            io_ready <= 1'b0;
            gpio_set <= `GPIO_NUMS'b0;
            gpio_ctrl <= `GPIO_NUMS'b0;
            int_clear <= 1'b0;
            gpio_int <= 1'b0;
        end 
        else begin
            if (int_clear) begin
                gpio_int <= |gpio_int_set;
            end
            else begin
                gpio_int <= gpio_int | (|gpio_int_set);
            end
            if(io_write) begin
                case (addr_offset)
                    `GPIO_CONFIG_OFFSET: begin
                        gpio_ctrl <= io_wdata[`GPIO_NUMS-1:0];
                        io_ready <= 1'b1;
                    end
                    `GPIO_SET_OFFSET: begin
                        gpio_set <= io_wdata[`GPIO_NUMS-1:0];
                        io_ready <= 1'b1;
                    end
                    `GPIO_INT_CLEAR_OFFSET: begin
                        int_clear <= 1'b1;
                        gpio_int_clear_set <= io_wdata[`GPIO_NUMS-1:0];
                        io_ready <= 1'b1;
                    end
                    default: begin
                        io_ready <= 1'b0;
                        int_clear <= 1'b0;
                    end
                endcase
            end
            else if (io_read) begin
                int_clear <= 1'b0;
                case (addr_offset)
                    `GPIO_CONFIG_OFFSET: begin
                        io_rdata <= gpio_ctrl;
                        io_ready <= 1'b1;
                    end
                    `GPIO_READ_OFFSET: begin
                        io_rdata <= gpio_values;
                        io_ready <= 1'b1;
                    end
                    `GPIO_INT_READ_OFFSET: begin
                        io_rdata <= gpio_int_set;
                        io_ready <= 1'b1;
                    end
                    default: begin
                        io_ready <= 1'b0;
                    end
                endcase
            end
            else begin
                io_ready <= 1'b0;
                int_clear <= 1'b0;
            end
        end
    end

endmodule