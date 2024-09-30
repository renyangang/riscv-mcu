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

 Description: inst decoder
    指令解码器，将指令解码成控制信号
 */
`define CLEAR_ALL_OUTPINS \
    invalid_instruction = 1'b0; \
    inst_beq = 1'b0; \
    inst_bge = 1'b0; \
    inst_bgeu = 1'b0; \
    inst_blt = 1'b0; \
    inst_bltu = 1'b0; \
    inst_bne = 1'b0; \
    inst_addi = 1'b0; \
    inst_andi = 1'b0; \
    inst_csrrc = 1'b0; \
    inst_csrrci = 1'b0; \
    inst_csrrs = 1'b0; \
    inst_csrrsi = 1'b0; \
    inst_csrrw = 1'b0; \
    inst_csrrwi = 1'b0; \
    inst_ebreak = 1'b0; \
    inst_ecall = 1'b0; \
    inst_jalr = 1'b0; \
    inst_lb = 1'b0; \
    inst_lbu = 1'b0; \
    inst_lh = 1'b0; \
    inst_lhu = 1'b0; \
    inst_lw = 1'b0; \
    inst_ori = 1'b0; \
    inst_slli = 1'b0; \
    inst_slti = 1'b0; \
    inst_sltiu = 1'b0; \
    inst_srai = 1'b0; \
    inst_srli = 1'b0; \
    inst_xori = 1'b0; \
    inst_jal = 1'b0; \
    inst_add = 1'b0; \
    inst_and = 1'b0; \
    inst_mret = 1'b0; \
    inst_or = 1'b0; \
    inst_sll = 1'b0; \
    inst_slt = 1'b0; \
    inst_sltu = 1'b0; \
    inst_sra = 1'b0; \
    inst_sret = 1'b0; \
    inst_srl = 1'b0; \
    inst_sub = 1'b0; \
    inst_wfi = 1'b0; \
    inst_xor = 1'b0; \
    inst_sb = 1'b0; \
    inst_sh = 1'b0; \
    inst_sw = 1'b0; \
    inst_auipc = 1'b0; \
    inst_lui = 1'b0; 
module inst_decoder(
    input wire [31:0] instruction_code,
    input en,
    output wire [4:0] rd, rs1, rs2,
    output wire [19:0] imm_1231,
    output reg invalid_instruction,
    output [47:0] inst_flags
);

 	reg inst_beq;
    reg inst_bge;
    reg inst_bgeu;
    reg inst_blt;
    reg inst_bltu;
    reg inst_bne;
	reg inst_jalr;
	reg inst_jal;
	reg inst_auipc;
    reg inst_addi;
    reg inst_andi;
	reg inst_ori;
    reg inst_slli;
    reg inst_slti;
    reg inst_sltiu;
    reg inst_srai;
    reg inst_srli;
    reg inst_xori;
	reg inst_add;
    reg inst_and;
	reg inst_or;
    reg inst_sll;
    reg inst_slt;
    reg inst_sltu;
    reg inst_sra;
    reg inst_srl;
    reg inst_sub;
	reg inst_xor;
	reg inst_lui;
	reg inst_lb;
    reg inst_lbu;
    reg inst_lh;
    reg inst_lhu;
    reg inst_lw;
    reg inst_sb;
    reg inst_sh;
    reg inst_sw;
    reg inst_csrrc;
    reg inst_csrrci;
    reg inst_csrrs;
    reg inst_csrrsi;
    reg inst_csrrw;
    reg inst_csrrwi;
    reg inst_ebreak;
    reg inst_ecall;
	reg inst_mret;
	reg inst_sret;
	reg inst_wfi;

    wire [6:2] opcode;
    wire [2:0] funct3;

    // reg [31:0] instruction_code;

    // always @(in_instruction_code) begin
    //     instruction_code = en? in_instruction_code : instruction_code;
    // end

    assign opcode = instruction_code[6:2];
    assign funct3 = instruction_code[14:12];
    assign imm_1231 = en ? instruction_code[31:12] : 19'b0;
    assign rd = en ? instruction_code[11:7] : 5'b0;
    assign rs1 = en ? instruction_code[19:15] : 5'b0;
    assign rs2 = en ? instruction_code[24:20] : 5'b0;

    assign inst_flags = {inst_wfi,inst_sret,inst_mret,inst_ecall,inst_ebreak,inst_csrrwi,inst_csrrw,inst_csrrsi,inst_csrrs,inst_csrrci,inst_csrrc,inst_sw,inst_sh,inst_sb,inst_lw,inst_lhu,inst_lh,inst_lbu,inst_lb,inst_lui,inst_xor,inst_sub,inst_srl,inst_sra,inst_sltu,inst_slt,inst_sll,inst_or,inst_and,inst_add,inst_xori,inst_srli,inst_srai,inst_sltiu,inst_slti,inst_slli,inst_ori,inst_andi,inst_addi,inst_auipc,inst_jal,inst_jalr,inst_bne,inst_bltu,inst_blt,inst_bgeu,inst_bge,inst_beq};

    task get_jmp_op;
        case (funct3)
            3'b000: inst_beq = 1'b1; //beq
            3'b001: inst_bne = 1'b1; //bne
            3'b100: inst_blt = 1'b1; //blt
            3'b101: inst_bge = 1'b1; //bge
            3'b110: inst_bltu = 1'b1; //bltu
            3'b111: inst_bgeu = 1'b1; //bgeu
            default: begin
                invalid_instruction = 1'd1;
            end
        endcase
    endtask

    task get_alu_op;
        case (funct3)
            3'b000: begin 
                inst_add = instruction_code[30] ? 1'b0 : 1'b1;  //add/sub
                inst_sub = instruction_code[30] ? 1'b1 : 1'b0;
            end
            3'b001: inst_sll = 1'b1;  // sll    
            3'b010: inst_slt = 1'b1;  // slt  
            3'b011: inst_sltu = 1'b1;  // sltu
            3'b100: inst_xor = 1'b1;  // xor
            3'b101: begin
                inst_srl = instruction_code[30] ? 1'b0 : 1'b1; // srl/sra
                inst_sra = instruction_code[30] ? 1'b1 : 1'b0;
            end
            3'b110: inst_or = 1'b1;  // or
            3'b111: inst_and = 1'b1;  // and
            default: begin
                invalid_instruction = 1'd1;
            end
        endcase
    endtask

    task get_alu1_op;
        case (funct3)
            3'b000: inst_addi = 1'b1;  //addi
            3'b001: inst_slli = 1'b1;  //slli
            3'b010: inst_slti = 1'b1;  //slti
            3'b011: inst_sltiu = 1'b1;  //sltiu
            3'b100: inst_xori = 1'b1;  //xori
            3'b101: begin 
                inst_srli = instruction_code[30] ? 1'b0 : 1'b1; //srli/srai
                inst_srai = instruction_code[30] ? 1'b1 : 1'b0;
            end
            3'b110: inst_ori = 1'b1; //ori
            3'b111: inst_andi = 1'b1; //andi
            default: begin
                invalid_instruction = 1'd1;
            end
        endcase
    endtask

    task get_mem_load_op;
        case (funct3)
            3'b000: inst_lb = 1'b1; //lb
            3'b001: inst_lh = 1'b1; //lh
            3'b010: inst_lw = 1'b1; //lw
            3'b100: inst_lbu = 1'b1; //lbu
            3'b101: inst_lhu = 1'b1; //lhu
            default: begin
                // 全0指令为特殊用途，非异常指令
                invalid_instruction = (instruction_code == 32'd0) ? 1'd0 : 1'd1;
            end
        endcase
    endtask

    task get_mem_store_op;
        case (funct3)
            3'b000: inst_sb = 1'b1; //sb
            3'b001: inst_sh = 1'b1; //sh
            3'b010: inst_sw = 1'b1; //sw
            default: begin
                invalid_instruction = 1'd1;
            end
        endcase
    endtask

    task get_csr_op;
        case (funct3)
            3'b001: inst_csrrw = 1'b1; //csrrw
            3'b010: inst_csrrs = 1'b1; //csrrs
            3'b011: inst_csrrc = 1'b1; //csrrc
            3'b101: inst_csrrwi = 1'b1; //csrrwi
            3'b110: inst_csrrsi = 1'b1; //csrrsi
            3'b111: inst_csrrci = 1'b1; //csrrci
            default: begin
                invalid_instruction = 1'd1;
            end
        endcase
    endtask

    task get_mechine_op;
        case (instruction_code)
            32'h10200073: inst_sret = 1'b1; //sret
            32'h10500073: inst_wfi = 1'b1; //wfi
            32'h30200073: inst_mret = 1'b1; //mret
            32'h100073: inst_ebreak = 1'b1; //ebreak
            32'h73: inst_ecall = 1'b1; //ecall
            default: begin
                invalid_instruction = 1'd1;
            end
        endcase
    endtask


    always @(*) begin
        if (en) begin
            `CLEAR_ALL_OUTPINS;
            if(instruction_code[1:0] != 2'b11) begin
                invalid_instruction = 1'd1;
            end
            else begin
                case (opcode)
                    7'b11000: begin
                        get_jmp_op();
                    end
                    7'b11001: begin
                        if (funct3 == 3'b000) begin //jalr
                            inst_jalr = 1'b1;
                        end
                    end
                    7'b11011: begin // jal
                        inst_jal = 1'b1;
                    end
                    7'b00101: begin
                        inst_auipc = 1'b1; //auipc
                    end
                    7'b00100: begin
                        get_alu1_op();
                    end
                    7'b01100: begin
                        get_alu_op();
                    end
                    7'b01101: begin
                        inst_lui = 1'b1; //lui
                    end
                    7'b00000: begin
                        get_mem_load_op();
                    end
                    7'b01000: begin
                        get_mem_store_op();
                    end
                    7'b11100: begin
                        if (funct3 == 3'b000) begin
                            get_mechine_op();
                        end
                        else begin
                            get_csr_op();
                        end
                    end
                    default: begin
                        invalid_instruction = 1'd1;
                    end
                endcase
            end
        end
        else begin
            `CLEAR_ALL_OUTPINS;
        end
    end

endmodule