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
    File Name   : iic_master.v
    Description : IIC master module
*/
module iic_master#(
    //Module clk clock frequency, unit is Hz
    parameter CLK_FREQ = 50_000_000
)(
    input clk,
    input rst_n,
    input rw, //0:write, 1:read
    input [1:0] mode, //0:standard mode, 1:fast mode, 2:high-speed mode
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
    localparam S_STOP = 3'd2;
    localparam S_DEVADDR = 3'd3;
    localparam S_SEND = 3'd4;
    localparam S_READ = 3'd5;
    localparam S_WAITACK = 3'd6;
    localparam S_SENDACK = 3'd7;

    //Standard mode 100K, fast mode 400K, high-speed mode 3.4M	
    parameter STD_IC_FREQ = 100_000;
    parameter FAST_IC_FREQ = 400_000; 
    parameter HS_IC_FREQ = 3_400_000; 

    reg [24:0] SCL_MAX;
    reg [24:0] SAMPLE_SCL_MAX;
    reg scl_reg;
    reg sample_scl_reg;
    reg sda_reg;
    reg [7:0] send_data;

    reg [2:0] state,nextstate;
    reg [24:0] counter_scl;
    reg [24:0] counter_sample_scl;
    reg [2:0] bit_cnt;
    reg last_start;
    reg last_stop;
    reg switch_flag;
    reg last_scl;
    wire scl_falling_edge;
    wire scl_rising_edge;
    reg send_ack;

    assign scl_falling_edge = (!scl_reg && last_scl);
    assign scl_rising_edge = (scl_reg && !last_scl);
    assign scl = scl_reg;
    assign sda = (!sda_reg) ? 1'b0 : 1'bz;

    // SCL counter
    always @(*) begin
        case (mode)
            2'd0: SCL_MAX = (CLK_FREQ/STD_IC_FREQ) - 1;
            2'd1: SCL_MAX = (CLK_FREQ/FAST_IC_FREQ) - 1;
            2'd2: SCL_MAX = (CLK_FREQ/HS_IC_FREQ) - 1;
            default: SCL_MAX = (CLK_FREQ/STD_IC_FREQ) - 1;
        endcase
        SAMPLE_SCL_MAX = SCL_MAX / 4;
    end

    always @(posedge clk or negedge rst_n) begin
        if ((!rst_n) || (state == S_IDLE && nextstate == S_IDLE)) begin
            scl_reg <= 1'b1;
            counter_scl <= 25'd0;
        end
        else if (counter_scl == SCL_MAX) begin
            scl_reg <= ~scl_reg;
            counter_scl <= 25'd0;
        end
        else begin
            counter_scl <= counter_scl + 25'd1;
        end
    end

    always @(posedge clk or posedge rst_n) begin
        if ((!rst_n) || (state == S_IDLE && nextstate == S_IDLE)) begin
            sample_scl_reg <= 1'b1;
            counter_sample_scl <= 25'd0;
        end
        else if (counter_scl == SAMPLE_SCL_MAX) begin
            sample_scl_reg <= ~sample_scl_reg;
            counter_sample_scl <= 25'd0;
        end
        else begin
            counter_sample_scl <= counter_sample_scl + 25'd1;
        end
    end

    always @(*) begin
        if (!rst_n) begin
            nextstate = S_IDLE;
        end
        else begin
            if (start && !proc_ing) begin
                nextstate = S_START;
            end
            else if (stop && !proc_ing) begin
                nextstate = S_STOP;
            end
            else begin
                if (state == S_START && !sda_reg) begin
                    nextstate = S_SEND;
                end
                else if (state == S_STOP && sda_reg && !scl_reg) begin
                    nextstate = S_IDLE;
                end
                else if ((state == S_SEND && bit_cnt == 3'd0) && scl_falling_edge) begin
                    nextstate = S_WAITACK;
                end
                else if (state == S_WAITACK && ack) begin
                    if (rw) begin
                        nextstate = S_READ;
                    end
                    else begin
                        nextstate = S_SEND;
                    end
                end
                else if (state == S_READ && bit_cnt == 3'd0) begin
                    nextstate = S_SENDACK;
                end
                else if (state == S_SENDACK && ack) begin
                    nextstate = S_READ;
                end
                else begin
                    nextstate = state;
                end
            end
        end
    end

    always @(posedge sample_scl_reg or posedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end
        else begin
            state <= nextstate;
        end
    end

    always @(posedge sample_scl_reg or posedge rst_n) begin
        if (!rst_n) begin
            proc_ing <= 1'b0;
            done <= 1'b0;
            ack <= 1'b0;
            data_out <= 8'd0;
            switch_flag <= 1'b0;
            sda_reg <= 1'b1;
            last_scl <= 1'b1;
            bit_cnt <= 3'd7;
            send_ack <= 1'b0;
        end
        else begin
            last_scl <= scl_reg;
            case (state)
                S_IDLE: begin
                    proc_ing <= 1'b0;
                    sda_reg <= 1'b1;
                    bit_cnt <= 3'd7;
                end
                S_START: begin
                    proc_ing <= 1'b0;
                    switch_flag <= scl_reg & sda_reg;
                    if (scl_reg && switch_flag) begin
                        sda_reg <= 1'b0;
                        switch_flag <= 1'b0;
                        send_data = {data[6:0], rw};
                    end
                    bit_cnt <= 3'd7;
                end
                S_STOP: begin
                    proc_ing <= 1'b0;
                    switch_flag <= scl_reg & !sda_reg;
                    if (!scl_reg) begin
                        sda_reg <= 1'b0;
                    end
                    else if (scl_reg && switch_flag) begin
                        sda_reg <= 1'b1;
                        switch_flag <= 1'b0;
                    end
                end
                S_SEND: begin
                    proc_ing <= 1'b1;
                    if (scl_falling_edge) begin
                        // falling edge
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                    sda_reg <= send_data[bit_cnt];
                    ack <= 1'b0;
                end
                S_WAITACK: begin
                    proc_ing <= 1'b0;
                    ack <= sda & scl_reg;
                    bit_cnt <= 3'd7;
                    send_data <= data;
                end
                S_READ: begin
                    proc_ing <= 1'b1;
                    if (scl_falling_edge) begin
                        // falling edge
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                    if (scl_reg) begin
                        data_out[bit_cnt] <= sda;
                    end
                    ack <= 1'b0;
                end
                S_SENDACK: begin
                    proc_ing <= 1'b0;
                    if (scl_falling_edge && !send_ack) begin
                        // falling edge
                        sda_reg <= 1'b0;
                        send_ack <= 1'b1;
                    end
                    else if (scl_falling_edge && send_ack) begin
                        ack <= 1'b1;
                        send_ack <= 1'b0;
                    end
                    bit_cnt <= 3'd7;
                end
            endcase
        end
    end

    
endmodule
