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

 Description: ex_mem module

   访存指令执行

 */
`include "config.v"
`define IDLE 2'b00
`define READ 2'b01
`define WRITE 2'b10
`define DONE 2'b11
module ex_mem(
    input clk, rst,
    input [4:0] rd,
    input [`MAX_BIT_POS:0] rs1_data, rs2_data,
    input [11:0] imm_2031,

    input [`MAX_BIT_POS:0] mem_data_in,
    input mem_read_ready,
    input mem_write_ready,
    input [47:0] inst_flags,

    output reg wb_rd_wait,
    output reg [4:0] rd_out,
    output reg rd_en,
    output reg [`MAX_BIT_POS:0] rd_data,

    output reg [1:0] byte_size, // 0: 32bit, 1: 8bit, 2: 16bit
    output reg [`MAX_BIT_POS:0] mem_data,
    output reg [`MAX_BIT_POS:0] mem_addr,
    output reg busy_flag,
    output reg mem_write_en,
    output reg mem_read_en
);

    reg [1:0] state;
    wire inst_lb;
    wire inst_lbu;
    wire inst_lh;
    wire inst_lhu;
    wire inst_lw;
    wire inst_sb;
    wire inst_sh;
    wire inst_sw;

    assign inst_lb = inst_flags[29];
    assign inst_lbu = inst_flags[30];
    assign inst_lh = inst_flags[31];
    assign inst_lhu = inst_flags[32];
    assign inst_lw = inst_flags[33];
    assign inst_sb = inst_flags[34];
    assign inst_sh = inst_flags[35];
    assign inst_sw = inst_flags[36];

    // assign busy_flag = ((state == `IDLE) && (inst_flags[36:29] == 8'd0)) ? 1'b0 : 1'b1;

    task mem_read_set();
        if (clk) begin
            mem_read_en <= 1'b1;
            state <= `READ;
        end
    endtask

    task mem_write_set();
        if (clk) begin
            mem_write_en <= 1'b1;
            state <= `WRITE;
        end
    endtask

    always @(*) begin
        busy_flag = (((state == `IDLE) && (inst_flags[36:29] == 8'd0)) || state == `DONE) ? 1'b0 : 1'b1;
        rd_out = (state != `IDLE) ? rd_out : (inst_lb || inst_lbu || inst_lh || inst_lhu || inst_lw)? rd : 5'd0;
        wb_rd_wait = (state == `READ) ? 1'b1 : ((state == `IDLE) && (inst_lb || inst_lbu || inst_lh || inst_lhu || inst_lw)) ? 1'b1 : 1'b0;
    end

    always @(posedge clk or posedge rst) begin
        if (!rst) begin
            rd_en <= 1'b0;
            rd_data <= 32'd0;
            byte_size <= 2'd0;
            mem_data <= 32'd0;
            mem_addr <= 32'd0;
            mem_write_en <= 1'b0;
            mem_read_en <= 1'b0;
            state <= `IDLE;
        end
        else begin
            case (state)
                `IDLE: begin
                    rd_en <= 1'b0;
                    if (inst_lb) begin
                        mem_addr <= rs1_data + {{20{imm_2031[11]}},imm_2031};
                        byte_size <= 2'd1;
                        mem_read_set();
                    end
                    else if (inst_lbu) begin
                        mem_addr <= rs1_data + {20'd0,imm_2031};
                        byte_size <= 2'd1;
                        mem_read_set();
                    end
                    else if (inst_lh) begin
                        mem_addr <= rs1_data + {{20{imm_2031[11]}},imm_2031};
                        byte_size <= 2'd2;
                        mem_read_set();
                    end
                    else if (inst_lhu) begin
                        mem_addr <= rs1_data + {20'd0,imm_2031};
                        byte_size <= 2'd2;
                        mem_read_set();
                    end
                    else if (inst_lw) begin
                        mem_addr <= rs1_data + {{20{imm_2031[11]}},imm_2031};
                        byte_size <= 2'd0;
                        mem_read_set();
                    end
                    else if (inst_sb) begin
                        mem_addr <= rs1_data + {{20{imm_2031[11]}},imm_2031[11:5],rd};
                        mem_data <= {24'd0, rs2_data[7:0]};
                        byte_size <= 2'd1;
                        mem_write_set();
                    end
                    else if (inst_sh) begin
                        mem_addr <= rs1_data + {{20{imm_2031[11]}},imm_2031[11:5],rd};
                        mem_data <= {16'd0, rs2_data[15:0]};
                        byte_size <= 2'd2;
                        mem_write_set();
                    end
                    else if (inst_sw) begin
                        mem_addr <= rs1_data + {{20{imm_2031[11]}},imm_2031[11:5],rd};
                        mem_data <= rs2_data;
                        byte_size <= 2'd0;
                        mem_write_set();
                    end
                    else begin
                        state <= `IDLE;
                        mem_write_en <= 1'b0;
                        mem_read_en <= 1'b0;
                        rd_en <= 1'b0;
                    end
                end
                `READ: begin
                    if (mem_read_ready) begin
                        case (byte_size)
                            2'd0: begin
                                rd_data <= mem_data_in;
                            end
                            2'd1: begin
                                rd_data <= {24'd0, mem_data_in[7:0]};
                            end
                            2'd2: begin
                                rd_data <= {16'd0, mem_data_in[15:0]};
                            end
                            default: begin
                                rd_data <= 32'd0;
                            end
                        endcase
                        rd_en <= 1;
                        state <= `DONE;
                        mem_read_en <= 1'b0;
                    end
                    else begin
                        state <= state;
                    end
                end
                `WRITE: begin
                    if (mem_write_ready) begin
                        state <= `DONE;
                        mem_write_en <= 1'b0;
                    end
                    else begin
                        state <= state;
                    end
                end
                `DONE: begin
                    rd_en <= 1'b0;
                    state <= `IDLE;
                end
                default: begin
                    state <= `IDLE;
                end
            endcase
        end
    end
endmodule