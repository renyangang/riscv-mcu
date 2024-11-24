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
*/
`timescale 1ns/1ns


module add_logic(
    input [3:0] a, 
    input [3:0] b, 
    output [3:0] s);

    assign s = a + b;

endmodule


module add_mealy_1(
    input clk,
    input rst,
    input [3:0] p,
    input [1:0] p_seq, // 1 第一个参数，2 第二个参数
    output reg res_valid,
    output reg [3:0] s
);

    localparam IDLE = 3'd0;
    localparam WAIT_P2 = 3'd1;
    
    reg [1:0] state;
    reg [3:0] p1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            res_valid <= 1'b0;
            p1 <= 4'd0;
            s <= 4'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (p_seq == 2'd1) begin
                        p1 <= p;
                        res_valid <= 1'b0;
                        s <= 4'd0;
                        state <= WAIT_P2;
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                WAIT_P2: begin
                    if (p_seq == 2'd2) begin
                        s <= p1 + p;
                        res_valid <= 1'b1;
                        state <= IDLE;
                    end
                    else begin
                        state <= WAIT_P2;
                        s <= 4'd0;
                    end
                end
            endcase
        end
    end

endmodule

module add_mealy_2(
    input clk,
    input rst,
    input [3:0] p,
    input [1:0] p_seq, // 1 第一个参数，2 第二个参数
    output reg res_valid,
    output reg [3:0] s
);

    localparam IDLE = 3'd0;
    localparam WAIT_P2 = 3'd1;
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [3:0] p1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            res_valid <= 1'b0;
            p1 <= 4'd0;
            s <= 4'd0;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (p_seq == 2'd1) begin
                    next_state = WAIT_P2;
                    res_valid = 1'b0;
                    p1 = p;
                    s = 4'd0;
                end
                else begin
                    next_state = IDLE;
                end
            end
            WAIT_P2: begin
                if (p_seq == 2'd2) begin
                    next_state = IDLE;
                    res_valid = 1'b1;
                    s = p1 + p;
                end
                else begin
                    next_state = WAIT_P2;
                    s = 4'd0;
                    res_valid = 1'b0;
                end
            end
            default: begin
                next_state = IDLE;
                s = 4'd0;
                res_valid = 1'b0;
            end
        endcase
    end

endmodule

module add_mealy_3(
    input clk,
    input rst,
    input [3:0] p,
    input [1:0] p_seq, // 1 第一个参数，2 第二个参数
    output reg res_valid,
    output reg [3:0] s
);

    localparam IDLE = 3'd0;
    localparam WAIT_P2 = 3'd1;
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [3:0] p1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            res_valid <= 1'b0;
            p1 <= 4'd0;
            s <= 4'd0;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (p_seq == 2'd1) begin
                    next_state = WAIT_P2;
                end
                else begin
                    next_state = IDLE;
                end
            end
            WAIT_P2: begin
                if (p_seq == 2'd2) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = WAIT_P2;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            case (state)
                IDLE: begin
                    if (p_seq == 2'd1) begin
                        p1 <= p;
                        s <= 4'd0;
                        res_valid <= 1'b0;
                    end
                end
                WAIT_P2: begin
                    if (p_seq == 2'd2) begin
                        s <= p1 + p;
                        res_valid <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule

module add_moore_3(
    input clk,
    input rst,
    input [3:0] p,
    input [1:0] p_seq, // 1 第一个参数，2 第二个参数
    output reg res_valid,
    output reg [3:0] s
);

    localparam IDLE = 3'd0;
    localparam WAIT_P2 = 3'd1;
    localparam DONE = 3'd2;
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [3:0] p1;
    reg [3:0] p2;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            res_valid <= 1'b0;
            p1 <= 4'd0;
            p2 <= 4'd0;
            s <= 4'd0;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (p_seq == 2'd1) begin
                    next_state = WAIT_P2;
                    p1 = p;
                end
                else begin
                    next_state = IDLE;
                end
            end
            WAIT_P2: begin
                if (p_seq == 2'd2) begin
                    next_state = DONE;
                    p2 = p;
                end
                else begin
                    next_state = WAIT_P2;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            case (state)
                IDLE: begin
                    s <= 4'd0;
                    res_valid <= 1'b0;
                end
                WAIT_P2: begin
                    s <= 4'd0;
                    res_valid <= 1'b0;
                end
                DONE: begin
                    s <= p1 + p2;
                    res_valid <= 1'b1;
                end
            endcase
        end
    end

endmodule

module add_moore_2(
    input clk,
    input rst,
    input [3:0] p,
    input [1:0] p_seq, // 1 第一个参数，2 第二个参数
    output reg res_valid,
    output reg [3:0] s
);

    localparam IDLE = 3'd0;
    localparam WAIT_P2 = 3'd1;
    localparam DONE = 3'd2;
    
    reg [1:0] state;
    reg [1:0] next_state;
    reg [3:0] p1;
    reg [3:0] p2;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
            res_valid <= 1'b0;
            p1 <= 4'd0;
            p2 <= 4'd0;
            s <= 4'd0;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                s = 4'd0;
                res_valid = 1'b0;
                if (p_seq == 2'd1) begin
                    next_state = WAIT_P2;
                    p1 = p;
                    
                end
                else begin
                    next_state = IDLE;
                end
            end
            WAIT_P2: begin
                s = 4'd0;
                res_valid = 1'b0;
                if (p_seq == 2'd2) begin
                    next_state = DONE;
                    p2 = p;
                end
                else begin
                    next_state = WAIT_P2;
                end
            end
            DONE: begin
                next_state = IDLE;
                s = p1 + p2;
                res_valid = 1'b1;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule

module state_tb;
    reg clk;
    reg rst;

    reg [1:0] p_seq;
    reg [3:0] p;

    wire [3:0] add_mealy_1_s;
    wire add_mealy_1_res_valid;

    add_mealy_1 add_mealy_1_inst(
        .clk(clk),
        .rst(rst),
        .p_seq(p_seq),
        .p(p),
        .res_valid(add_mealy_1_res_valid),
        .s(add_mealy_1_s)
    );

    wire [3:0] add_mealy_2_s;
    wire add_mealy_2_res_valid;

    add_mealy_2 add_mealy_2_inst(
        .clk(clk),
        .rst(rst),
        .p_seq(p_seq),
        .p(p),
        .res_valid(add_mealy_2_res_valid),
        .s(add_mealy_2_s)
    );

    wire [3:0] add_mealy_3_s;
    wire add_mealy_3_res_valid;

    add_mealy_3 add_mealy_3_inst(
        .clk(clk),
        .rst(rst),
        .p_seq(p_seq),
        .p(p),
        .res_valid(add_mealy_3_res_valid),
        .s(add_mealy_3_s)
    );

    wire [3:0] add_moore_3_s;
    wire add_moore_3_res_valid;

    add_moore_3 add_moore_3_inst(
        .clk(clk),
        .rst(rst),
        .p_seq(p_seq),
        .p(p),
        .res_valid(add_moore_3_res_valid),
        .s(add_moore_3_s)
    );

    wire [3:0] add_moore_2_s;
    wire add_moore_2_res_valid;

    add_moore_2 add_moore_2_inst(
        .clk(clk),
        .rst(rst),
        .p_seq(p_seq),
        .p(p),
        .res_valid(add_moore_2_res_valid),
        .s(add_moore_2_s)
    );
    

    initial begin            
        $dumpfile("state.vcd");
        $dumpvars; // dump all vars
    end

    initial begin
        clk = 0;
        rst = 0;
        p = 0;
        p_seq = 2'd0;
        #11;
        rst = 1;
        #11;
        p_seq = 2'd1;
        #1;
        p = 4'd2;
        #5;
        p_seq = 2'd2;
        #1;
        p = 4'd3;
        #42;
        $finish;
    end

    always #5 clk = ~clk;


endmodule