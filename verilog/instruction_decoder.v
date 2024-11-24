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
`define CLEAR_ALL_OUTPINTS \
    alu_op = 19'b0; \
    jmp_op = 9'b0; \
    mem_op = 9'b0; \
    cust_op = 1'b0; \
    csr_op = 6'b0; \
    mechie_op = 8'b0; \
    invalid_instruction = 32'bz;
`include "config.v"
module instruction_decoder(
    input [`MAX_BIT_POS:0] instruction_code,
    input en,
    output reg [`MAX_BIT_POS:0] invalid_instruction,
    output reg [18:0] alu_op,
    output reg [8:0] jmp_op,
    output reg [8:0] mem_op,
    output reg cust_op,
    output reg [5:0] csr_op,
    output reg [7:0] mechie_op,
    output wire [4:0] rd, rs1, rs2,
    output wire [6:0] imm_2531,
    output wire [19:0] imm_1231,
    output wire [11:0] imm_2032
);
    wire [6:2] opcode;
    wire [2:0] funct3;

    assign opcode = instruction_code[6:2];
    assign funct3 = instruction_code[14:12];
    assign imm_2531 = en ? instruction_code[31:25] : 7'b0;
    assign imm_1231 = en ? instruction_code[31:12] : 19'b0;
    assign imm_2032 = en ? instruction_code[31:20] : 12'b0;
    assign rd = en ? instruction_code[11:7] : 5'b0;
    assign rs1 = en ? instruction_code[19:15] : 5'b0;
    assign rs2 = en ? instruction_code[24:20] : 5'b0;

    function [8:0] get_jmp_op(input [2:0] funct3);
        case (funct3)
            3'b000: get_jmp_op = 9'b000000100; //beq
            3'b001: get_jmp_op = 9'b000001000; //bne
            3'b100: get_jmp_op = 9'b000010000; //blt
            3'b101: get_jmp_op = 9'b000100000; //bge
            3'b110: get_jmp_op = 9'b001000000; //bltu
            3'b111: get_jmp_op = 9'b010000000; //bgeu
            default: begin
                get_jmp_op = 9'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction

    function [18:0] get_alu_op(input [2:0] funct3);
        case (funct3)
            3'b000: get_alu_op = instruction_code[30] ? 19'b1 << 1 : 19'b1;  //add/sub
            3'b001: get_alu_op = 19'b1 << 2;  // sll    
            3'b010: get_alu_op = 19'b1 << 3;  // slt  
            3'b011: get_alu_op = 19'b1 << 4;  // sltu
            3'b100: get_alu_op = 19'b1 << 5;  // xor
            3'b101: get_alu_op = instruction_code[30] ? 19'b1 << 7 : 19'b1 << 6; // srl/sra
            3'b110: get_alu_op = 19'b1 << 8;  // or
            3'b111: get_alu_op = 19'b1 << 9;  // and
            default: begin
                get_alu_op = 9'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction

    function [18:0] get_alu1_op(input [2:0] funct3);
        case (funct3)
            3'b000: get_alu1_op = 19'b1 << 10;  //addi
            3'b001: get_alu1_op = 19'b1 << 11;  //slli
            3'b010: get_alu1_op = 19'b1 << 12;  //slti
            3'b011: get_alu1_op = 19'b1 << 13;  //sltiu
            3'b100: get_alu1_op = 19'b1 << 14;  //xori
            3'b101: get_alu1_op = instruction_code[30] ? 19'b1 << 16 : 19'b1 << 15; //srli/srai
            3'b110: get_alu1_op = 19'b1 << 17; //ori
            3'b111: get_alu1_op = 19'b1 << 18; //andi
            default: begin
                get_alu1_op = 9'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction

    function [8:0] get_mem_load_op(input [2:0] funct3);
        case (funct3)
            3'b000: get_mem_load_op = 9'b000000010; //lb
            3'b001: get_mem_load_op = 9'b000000100; //lh
            3'b010: get_mem_load_op = 9'b000001000; //lw
            3'b100: get_mem_load_op = 9'b000010000; //lbu
            3'b101: get_mem_load_op = 9'b000100000; //lhu
            default: begin
                get_mem_load_op = 9'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction

    function [8:0] get_mem_store_op(input [2:0] funct3);
        case (funct3)
            3'b000: get_mem_store_op = 9'b001000000; //sb
            3'b001: get_mem_store_op = 9'b010000000; //sh
            3'b010: get_mem_store_op = 9'b100000000; //sw
            default: begin
                get_mem_store_op = 9'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction

    function [5:0] get_csr_op(input [2:0] funct3);
        case (funct3)
            3'b001: get_csr_op = 6'b000001; //csrrw
            3'b010: get_csr_op = 6'b000010; //csrrs
            3'b011: get_csr_op = 6'b000100; //csrrc
            3'b101: get_csr_op = 6'b001000; //csrrwi
            3'b110: get_csr_op = 6'b010000; //csrrsi
            3'b111: get_csr_op = 6'b100000; //csrrci
            default: begin
                get_csr_op = 6'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction

    function [7:0] get_mechine_op(input [`MAX_BIT_POS:0] instruction_code);
        case (instruction_code)
            32'h10200073: get_mechine_op = 8'b00010000; //sret
            32'h10500073: get_mechine_op = 8'b00100000; //wfi
            32'h30200073: get_mechine_op = 8'b00000100; //mret
            32'h100073: get_mechine_op = 8'b00000001; //ebreak
            32'h73: get_mechine_op = 8'b00000010; //ecall
            default: begin
                get_mechine_op = 8'd0;
                invalid_instruction = 32'd2;
            end
        endcase
    endfunction


    always @(*) begin
        if (en) begin
            `CLEAR_ALL_OUTPINTS;
            if(instruction_code[1:0] != 2'b11) begin
                invalid_instruction = 32'd2;
            end
            else begin
                case (opcode)
                    7'b11000: begin
                        jmp_op = get_jmp_op(funct3);
                    end
                    7'b11001: begin
                        if (funct3 == 3'b000) begin //jalr
                            jmp_op = 9'b000000010;
                        end
                    end
                    7'b11011: begin // jal
                        jmp_op = 9'b000000001;
                    end
                    7'b00101: begin 
                        jmp_op = 9'b100000000; //auipc
                    end
                    7'b00100: begin
                        alu_op = get_alu1_op(funct3);
                    end
                    7'b01100: begin
                        alu_op = get_alu_op(funct3);
                    end
                    7'b01101: begin
                        mem_op = 9'b000000001; //lui
                    end
                    7'b00000: begin
                        mem_op = get_mem_load_op(funct3);
                    end
                    7'b01000: begin
                        mem_op = get_mem_store_op(funct3);
                    end
                    7'b11100: begin
                        if (funct3 == 3'b000) begin
                            mechie_op = get_mechine_op(instruction_code);
                        end
                        else begin
                            csr_op = get_csr_op(funct3);
                        end
                    end
                    7'b11111: begin
                        cust_op = 1'b1;
                    end
                    default: begin
                        invalid_instruction = 32'd2;
                    end
                endcase
            end
        end
        else begin
            `CLEAR_ALL_OUTPINTS;
        end
    end

endmodule
