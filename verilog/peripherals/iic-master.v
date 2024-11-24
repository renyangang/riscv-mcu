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
module iic_master#(
    //Module clk clock frequency, unit is Hz
    parameter CLK_FREQ = 50_000_000
)(
    input clk,
    input rst,
    input rw, //0:write, 1:read
    input [1:0]mode, //0:standard mode, 1:fast mode, 2:high-speed mode
    input [7:0] data,
    input start,
    input stop,
    inout sda,
    output wire scl,
    output reg proc_ing,
    output reg done,
    output reg [7:0] data_out,
    output reg ack
);
    //State machine state
    localparam S_IDLE = 3'd0;
    localparam S_START = 3'd1;
    localparam S_DATA = 3'd2;
    localparam S_READ = 3'd3;
    localparam S_ACK = 3'd4;
    localparam S_SENDACK = 3'd5;
    localparam S_STOP = 3'd6;
    

    //Standard mode 100K, fast mode 400K, high-speed mode 3.4M	
    parameter STD_IC_FREQ = 100_000;
    parameter FAST_IC_FREQ = 400_000; 
    parameter HS_IC_FREQ = 3_400_000; 

    reg [24:0] SCL_CNT;
    reg scl_reg;
    reg sda_reg;

    reg [2:0] state,nextstate;
    reg [24:0] counter_scl;
    reg [2:0] bit_cnt;

    assign scl = scl_reg;
    assign sda = sda_reg;

    // SCL counter
    always @(*) begin
        case (mode)
            2'd0: SCL_CNT = (CLK_FREQ/STD_IC_FREQ) - 1;
            2'd1: SCL_CNT = (CLK_FREQ/FAST_IC_FREQ) - 1;
            2'd2: SCL_CNT = (CLK_FREQ/HS_IC_FREQ) - 1;
            default: SCL_CNT = (CLK_FREQ/STD_IC_FREQ) - 1;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_reg <= 1'b1;
            counter_scl <= 25'd0;
        end
        else if (state == S_IDLE && nextstate == S_IDLE) begin
            counter_scl <= 25'd0;
        end
        else if (counter_scl == SCL_CNT) begin
            scl_reg <= ~scl_reg;
            counter_scl <= 25'd0;
        end
        else begin
            counter_scl <= counter_scl + 25'd1;
        end
    end

    // status
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            nextstate <= S_IDLE;
            proc_ing <= 1'b0;
            done <= 1'b1;
            sda_reg <= 1'bz;
            bit_cnt <= 3'd0;
        end
        else if (start && done) begin
            nextstate <= S_START;
        end
        else if (stop && done) begin
            nextstate <= S_STOP;
        end
    end

    always @(posedge clk) begin
        if (state == S_START) begin
            if (scl_reg == 1'b1 && counter_scl >= SCL_CNT/2 - 1) begin
                sda_reg <= 1'b0;
                nextstate <= S_DATA;
            end
        end
        else if (state == S_STOP) begin
            if (scl_reg == 1'b1 && counter_scl >= SCL_CNT/2 - 1) begin
                sda_reg <= 1'b1;
                nextstate <= S_IDLE;
            end
        end
    end

    always @(negedge scl_reg) begin
        state <= nextstate;
        if (nextstate == S_START) begin
            sda_reg <= 1'b1;
            done <= 1'b0;
            proc_ing <= 1'b1;
        end
        else if (nextstate == S_STOP) begin
            sda_reg <= 1'b0;
        end
        else if (nextstate == S_DATA) begin
            sda_reg <= data[bit_cnt];
        end
        else if (nextstate == S_ACK) begin
            sda_reg <= 1'bz;
        end
        else if (nextstate == S_READ) begin
            bit_cnt <= bit_cnt + 3'd1;
        end
        else if (nextstate == S_SENDACK) begin
            sda_reg <= 1'b0;
        end
        else if (nextstate == S_IDLE) begin
            sda_reg <= 1'bz;
        end
    end

    always @(posedge scl_reg) begin
        if (state == S_DATA) begin
            proc_ing <= 1'b1;
            if (bit_cnt == 3'd7) begin
                nextstate <= S_ACK;
                bit_cnt <= 3'd0;
            end
            else begin
                bit_cnt <= bit_cnt + 3'd1;
            end
        end
        else if (state == S_ACK) begin
            proc_ing <= 1'b0;
            done <= 1'b1;
            ack <= sda_reg;
            nextstate <= S_IDLE;
        end
        else if (state == S_IDLE) begin
            proc_ing <= 1'b0;
        end
        else if (state == S_READ) begin
            proc_ing <= 1'b1;
            data_out[bit_cnt] <= sda_reg;
            if (bit_cnt == 3'd7) begin
                bit_cnt <= 1'b0;
                nextstate <= S_SENDACK;
            end
        end
        else if (state == S_SENDACK) begin
            nextstate <= S_IDLE;
            proc_ing <= 1'b0;
            done <= 1'b1;
        end
    end


    
endmodule
