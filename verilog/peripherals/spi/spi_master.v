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
    File Name   : spi_master.v
    Description : SPI master module
*/

module spi_master #(
    parameter DATA_WIDTH = 8,      // 数据宽度，例如 8 位、16 位
    parameter FIFO_DEPTH = 16      // FIFO 缓冲深度
) (
    input wire         clk,         // 系统时钟
    input wire         rst_n,       // 复位信号，低电平有效
    input wire         start,       // 启动信号，高电平有效
    input wire         op_mode,      // 操作模式， 0: 发送数据 1: 接收数据 2: 发送接收
    input wire [1:0]   spi_mode,    // SPI 模式 (Mode 0-3: CPOL, CPHA)
    input wire [15:0]  clk_div,     // SPI 时钟分频值 (控制速度)
    input wire         cs_enable,   // 片选使能信号
    input wire [DATA_WIDTH-1:0] tx_data,  // 要发送的数据
    input wire         tx_valid,    // 发送数据有效
    output wire        tx_ready,    // 发送缓冲区准备好

    output wire [DATA_WIDTH-1:0] rx_data,  // 接收到的数据
    output wire        rx_valid,    // 接收数据有效
    input wire         rx_ready,    // 读取接收缓冲区准备好

    output wire        spi_clk,     // SPI 时钟信号
    output wire        spi_mosi,    // 主输出从输入 (MOSI)
    input wire         spi_miso,    // 主输入从输出 (MISO)
    output wire        spi_cs       // 片选信号
);

// 内部信号定义
reg [15:0] clk_cnt;           // 时钟分频计数器
reg spi_clk_reg;             // SPI时钟寄存器
reg spi_cs_reg;              // 片选寄存器
reg spi_mosi_reg;            // MOSI数据寄存器
reg [DATA_WIDTH-1:0] tx_shift_reg;  // 发送移位寄存器
reg [DATA_WIDTH-1:0] rx_shift_reg;  // 接收移位寄存器
reg [3:0] bit_cnt;           // 位计数器
reg busy;                    // 忙状态标志
wire cpol;     // 时钟极性
wire cpha;     // 时钟相位
wire sample_edge; // 采样时刻
// 状态机定义
localparam IDLE = 2'b00;     // 空闲状态
localparam TRANSFER = 2'b01; // 传输状态

localparam OP_MODE_SEND = 2'b00;
localparam OP_MODE_RECEIVE = 2'b01;
localparam OP_MODE_BOTH = 2'b10;


reg [1:0] state, next_state;

assign cpol = spi_mode[0];
assign cpha = spi_mode[1];
assign sample_edge = ((cpol == 1'b0 && cpha == 1'b0) || (cpol == 1'b1 && cpha == 1'b1)) ? spi_clk_reg : ~spi_clk_reg;

// SPI时钟生成
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_cnt <= 16'd0;
        spi_clk_reg <= cpol;
    end else if (busy) begin
        if (clk_cnt == clk_div - 1) begin
            clk_cnt <= 16'd0;
            spi_clk_reg <= ~spi_clk_reg;
        end else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end else begin
        spi_clk_reg <= cpol;
        clk_cnt <= 16'd0;
    end
end


// 状态机
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        next_state <= IDLE;
        busy <= 1'b0;
        bit_cnt <= 4'd0;
        spi_cs_reg <= 1'b1;
        tx_shift_reg <= {DATA_WIDTH{1'b0}};
        rx_shift_reg <= {DATA_WIDTH{1'b0}};
    end else begin
        state <= next_state;
        case (state)
            IDLE: begin
                if (start) begin
                    busy <= 1'b1;
                    spi_cs_reg <= 1'b0;
                    tx_shift_reg <= tx_data;
                    bit_cnt <= 4'd0;
                    next_state <= TRANSFER;
                end else begin
                    busy <= 1'b0;
                    spi_cs_reg <= 1'b1;
                    next_state <= IDLE;
                end
            end
            TRANSFER: begin
                if (bit_cnt == DATA_WIDTH) begin
                    busy <= 1'b0;
                    spi_cs_reg <= 1'b1;
                    next_state <= IDLE;
                end else if (sample_edge) begin
                    bit_cnt <= bit_cnt + 1'b1;
                    case (op_mode)
                        OP_MODE_SEND: begin // 发送数据
                            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                        end
                        OP_MODE_RECEIVE: begin // 接收数据
                            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], spi_miso};
                        end
                        OP_MODE_BOTH: begin // 同时发送和接受
                            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], spi_miso};
                        end
                    endcase
                end
            end
        endcase
    end
end




// 输出赋值
assign spi_clk = spi_clk_reg;
assign spi_cs = spi_cs_reg;
assign spi_mosi = tx_shift_reg[DATA_WIDTH-1];
assign rx_data = rx_shift_reg;
assign rx_valid = !busy && (state == IDLE);
assign tx_ready = !busy && (state == IDLE);


endmodule
