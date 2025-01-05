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
module iic_master(
    input scl_in,
    input sample_scl_reg,
    input rst_n,
    input [7:0] data,
    input start,
    inout sda,
    input is_stop, // 0:ack, 1:no_ack and stop, in last byte, no ack send or wait.
    output wire scl,
    output reg proc_ing, //0:finish, 1:processing
    output reg done, //0:processing, 1: after stop singal confirm
    output reg [7:0] data_out,
    output reg ack,
    output reg no_ack
);
    //State machine state
    localparam S_IDLE = 3'd0;
    localparam S_START = 3'd1;
    localparam S_STOP = 3'd2;
    localparam S_SEND = 3'd3;
    localparam S_READ = 3'd4;
    localparam S_WAITACK = 3'd5;
    localparam S_SENDACK = 3'd6;

    reg rw; //0:write, 1:read
    reg sda_reg;
    wire scl_reg;
    reg [7:0] send_data;

    reg [2:0] state,nextstate;
    reg [2:0] bit_cnt;
    reg last_scl;
    reg in_stop;
    wire scl_falling_edge;
    wire scl_rising_edge;


    assign scl_reg = (state != S_IDLE) ? scl_in : 1'b1;
    assign scl_falling_edge = (!scl_reg && last_scl);
    assign scl_rising_edge = (scl_reg && !last_scl);
    assign scl = scl_reg;
    assign sda = scl_reg ? sda_reg : 1'bz;

    always @(posedge sample_scl_reg or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end
        else begin
            state <= nextstate;
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
            else begin
                if (state == S_START && !sda_reg && scl_falling_edge) begin
                    nextstate = S_SEND;
                end
                else if (state == S_STOP && done) begin
                    nextstate = S_IDLE;
                end
                else if ((state == S_SEND && bit_cnt == 3'd0) && scl_falling_edge) begin
                    nextstate = S_WAITACK;
                end
                else if (state == S_WAITACK && scl_falling_edge) begin
                    if (is_stop || !ack) begin
                        nextstate = S_STOP;
                    end
                    else if (rw) begin
                        nextstate = S_READ;
                    end
                    else begin
                        nextstate = S_SEND;
                    end
                end
                else if (state == S_READ && bit_cnt == 3'd0 && scl_falling_edge) begin
                    if (is_stop) begin
                        nextstate = S_STOP;
                    end
                    else begin
                        nextstate = S_SENDACK;
                    end
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

    always @(posedge sample_scl_reg or negedge rst_n) begin
        if (!rst_n) begin
            proc_ing <= 1'b0;
            ack <= 1'b0;
            data_out <= 8'd0;
            sda_reg <= 1'bz;
            last_scl <= 1'b1;
            bit_cnt <= 3'd7;
            no_ack <= 1'b0;
            done <= 1'b0;
        end
        else begin
            last_scl <= scl_reg;
            case (state)
                S_IDLE: begin
                    proc_ing <= 1'b0;
                    sda_reg <= 1'bz;
                    bit_cnt <= 3'd7;
                    ack <= 1'b0;
                    no_ack <= 1'b0;
                    done <= 1'b0;
                    in_stop <= 1'b0;
                end
                S_START: begin
                    if (scl_in && sda) begin
                        proc_ing <= 1'b1;
                        done <= 1'b0;
                        rw <= data[0];
                        if (scl_in) begin
                            sda_reg <= 1'b0;
                            send_data = data;
                        end
                        bit_cnt <= 3'd7;
                        ack <= 1'b0;
                        no_ack <= 1'b0;
                    end
                    else begin
                        proc_ing <= 1'b0;
                    end
                    in_stop <= 1'b0;
                end
                S_SEND: begin
                    proc_ing <= 1'b1;
                    if (scl_falling_edge && !scl_reg) begin
                        // falling edge
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                    sda_reg <= send_data[bit_cnt];
                    ack <= 1'b0;
                    no_ack <= 1'b0;
                end
                S_WAITACK: begin
                    proc_ing <= 1'b0;
                    sda_reg <= 1'bz;
                    no_ack <= 1'b0;
                    ack <= (~sda) & scl_reg;
                    bit_cnt <= 3'd7;
                    send_data <= data;
                end
                S_READ: begin
                    sda_reg <= 1'bz;
                    proc_ing <= 1'b1;
                    if (scl_falling_edge) begin
                        // falling edge
                        bit_cnt <= bit_cnt - 3'd1;
                    end
                    if (scl_reg) begin
                        data_out[bit_cnt] <= sda;
                    end
                    ack <= 1'b0;
                    no_ack <= 1'b0;
                end
                S_SENDACK: begin
                    proc_ing <= 1'b0;
                    sda_reg <= 1'b0;
                    if (scl_falling_edge) begin
                        ack <= 1'b1;
                        sda_reg <= 1'bz;
                    end
                    bit_cnt <= 3'd7;
                    no_ack <= 1'b0;
                end
                S_STOP: begin
                    proc_ing <= 1'b0;
                    if (scl_falling_edge) begin
                        sda_reg <= 1'b0;
                        in_stop <= 1'b1;
                    end
                    else if (scl_reg && in_stop) begin
                        sda_reg <= 1'b1;
                        done <= 1'b1;
                    end
                    ack <= 1'b0;
                    no_ack <= 1'b1;
                end
            endcase
        end
    end

endmodule
