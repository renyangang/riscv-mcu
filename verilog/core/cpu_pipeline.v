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

 Description: CPU pipeline
 */

`include "config.v"

`define INITIAL 2'b00
`define WAIT_DECODE 2'b01
`define TO_EXECUTE 2'b10
`define WAIT_EXECUTE 2'b01
`define EXECUTE_COMPLATE 2'b10
module cpu_pipeline(
    input wire clk,
    input wire rst,
    input wire clk_timer
);

    wire read_en;
    wire [`MAX_BIT_POS:0] mem_addr;
    wire [`MAX_BIT_POS:0] rdata;
    wire write_en;
    wire [`MAX_BIT_POS:0] wdata;
    wire [1:0] byte_size;
    wire mem_busy;
    wire mem_ready;

    // interrupts and exceptions
    reg [`MAX_BIT_POS:0]pc_cur;
    reg [`MAX_BIT_POS:0]pc_next;
    reg [`MAX_BIT_POS:0]inst_cur_ex;
    reg [`MAX_BIT_POS:0]exception_code;
    reg exception_en;
    wire [`MAX_BIT_POS:0] int_jmp_pc;
    wire int_jmp_en;

    // csr operations
    reg [11:0] csr_read_addr;
    wire [`MAX_BIT_POS:0] csr_data;
    wire [11:0] wb_csr_addr;
    wire wb_csr_out_en;
    wire [`MAX_BIT_POS:0] wb_csrw_data;

    

    // branch instuctions
    wire [`MAX_BIT_POS:0] branch_pc_next_out;
    wire branch_jmp_en;
    wire [4:0] branch_rd_out;
    wire [`MAX_BIT_POS:0] branch_rd_data_out;
    wire branch_rd_out_en;
    reg cur_branch_hazard; // 标识当前是否正在执行跳转指令，如果是，中断等处理就需要等待结果

    // fetch
    wire inst_read_en;
    wire [`MAX_BIT_POS:0] cur_inst_addr;
    wire [`MAX_BIT_POS:0] next_inst_addr;
    wire [`MAX_BIT_POS:0] inst_code;
    wire inst_ready;
    reg [`MAX_BIT_POS:0] jmp_pc;
    reg jmp_en;
    wire fetch_en;
    wire [`MAX_BIT_POS:0] inst_data;
    wire inst_mem_ready;
    wire fetch_hazard;
    wire b_n_jmp; // 用于标记未达成跳转条件的指令

    // decode
    reg decoder_en;
    wire [47:0] inst_decode_out;
    

    // memory instructions
    wire inst_mem_busy; // 访存指令忙

     sys_bus sys_bus(
        .clk(clk),
        .rst(rst),
        .inst_read_en(inst_read_en),       
        .inst_read_addr(cur_inst_addr),
        .inst_rdata(inst_data),
        .inst_read_ready(inst_mem_ready),
        .read_en(read_en),       
        .mem_addr(mem_addr),
        .rdata(rdata),
        .write_en(write_en),
        .wdata(wdata),     
        .byte_size(byte_size),
        .mem_busy(mem_busy),
        .mem_ready(mem_ready),
        .pc(id_ex_pc_cur),
        .pc_next(id_ex_pc_next),
        .inst_cur(id_ex_cur_inst_code),
        .exception_code(exception_code),
        .cur_branch_hazard(cur_branch_hazard),
        .exception_en(exception_en),
        .jmp_en(int_jmp_en),
        .jmp_pc(int_jmp_pc),
        .clk_timer(clk_timer),
        
        .csr_read_addr(csr_read_addr),
        .csrw_addr(wb_csr_addr),
        .w_data(wb_csrw_data),
        .csr_write_en(wb_csr_out_en),
        .csr_out(csr_data)
    );

    inst_fetch inst_fetch(
        .clk(clk),
        .rst(rst),
        .jmp_pc(jmp_pc),
        .jmp_en(jmp_en),
        .next_en(fetch_en),
        // 指令返回通道
        .inst_data(inst_data),
        .inst_mem_ready(inst_mem_ready),
        .inst_mem_read_en(inst_read_en),
        .b_n_jmp(b_n_jmp),

        .cur_inst_addr(cur_inst_addr),
        .next_inst_addr(next_inst_addr),
        .inst_code(inst_code),
        .control_hazard(fetch_hazard),
        .inst_ready(inst_ready)
    );

    wire [4:0] rd, rs1, rs2;
    wire [19:0] imm_1231;
    wire invalid_instruction;
    

    inst_decoder inst_decoder(
        .instruction_code(if_id_inst_code),
        .en(decoder_en),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm_1231(imm_1231),
        .invalid_instruction(invalid_instruction),
        .inst_flags(inst_decode_out)
    );
    
    wire [4:0] alu_rd_out;
    wire alu_rd_out_en;
    wire [`MAX_BIT_POS:0] alu_rd_data;

    ex_alu alu(
        .rst(rst),
        .rd(id_ex_rd),
        .rs1_data(id_ex_rs1_data),
        .rs2_data(id_ex_rs2_data),
        .imm_1231(id_ex_imm_1231),
        .inst_flags(id_ex_inst_flags),
        .rd_out(alu_rd_out),
        .out_en(alu_rd_out_en),
        .rd_data(alu_rd_data)
    );

    ex_branch ex_branch(
        .rst(rst),
        .pc_cur(id_ex_pc_cur),
        .pc_next(id_ex_pc_next),
        .rd(id_ex_rd),
        .rs1_data(id_ex_rs1_data),
        .rs2_data(id_ex_rs2_data),
        .imm_1231(id_ex_imm_1231),
        .inst_flags(id_ex_inst_flags),
        .rd_out(branch_rd_out),
        .rd_out_en(branch_rd_out_en),
        .rd_data_out(branch_rd_data_out),
        .b_n_jmp(b_n_jmp),
        .pc_next_out(branch_pc_next_out),
        .jmp_en(branch_jmp_en)
    );

    wire  [4:0] mem_rd_out;
    wire mem_rd_en;
    wire [`MAX_BIT_POS:0] mem_rd_data;
    wire wb_rd_wait;

    ex_mem ex_mem(
        .clk(clk),
        .rst(rst),
        .rd(id_ex_rd),
        .rs1_data(id_ex_rs1_data),
        .rs2_data(id_ex_rs2_data),
        .imm_2031(id_ex_imm_1231[19:8]),
        .inst_flags(id_ex_inst_flags),
        .mem_data_in(rdata),
        .mem_read_ready(mem_ready),
        .mem_write_ready(mem_ready),

        .busy_flag(inst_mem_busy),
        .wb_rd_wait(wb_rd_wait),
        .rd_out(mem_rd_out),
        .rd_en(mem_rd_en),
        .rd_data(mem_rd_data),
        .byte_size(byte_size),
        .mem_data(wdata),
        .mem_addr(mem_addr),
        .mem_write_en(write_en),
        .mem_read_en(read_en)
    );

    wire [4:0] csr_rd_out;
    wire csr_rd_out_en;
    wire [`MAX_BIT_POS:0] csr_rd_data;
    

    ex_csr ex_csr(
        .rst(rst),
        .rd(id_ex_rd),
        .rs1_data(id_ex_rs1_data),
        .csr_data(id_ex_rs2_data),
        .imm_2031(id_ex_imm_1231[19:8]),
        .imm_1519(id_ex_imm_1231[7:3]),
        .inst_flags(id_ex_inst_flags),
        .rd_out(csr_rd_out),
        .out_en(csr_rd_out_en),
        .rd_data(csr_rd_data),
        .csr_out_en(wb_csr_out_en),
        .csrw_data(wb_csrw_data),
        .csrw_addr(wb_csr_addr)
    );

    
    wire [`MAX_BIT_POS:0] rs1_out;
    wire [`MAX_BIT_POS:0] rs2_out;

    registers registers(
        .clk(clk),
        .rst(rst),
        .rd_addr(wb_rd),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_data(wb_rd_data),
        .rd_en(wb_rd_en),
        .rs1_out(rs1_out),
        .rs2_out(rs2_out)
    );

    // pipeline regs
    reg if_id_control_hazard;
    reg [`MAX_BIT_POS:0] if_id_pc_cur;
    reg [`MAX_BIT_POS:0] if_id_pc_next;
    reg [`MAX_BIT_POS:0] if_id_inst_code;


    reg id_ex_control_hazard;
    reg [`MAX_BIT_POS:0] id_ex_pc_cur;
    reg [`MAX_BIT_POS:0] id_ex_pc_next;
    reg [47:0] id_ex_inst_flags;
    reg [4:0] id_ex_rd;
    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;
    reg [`MAX_BIT_POS:0] id_ex_rs1_data;
    reg [`MAX_BIT_POS:0] id_ex_rs2_data;
    reg [19:0] id_ex_imm_1231;
    reg [`MAX_BIT_POS:0] id_ex_cur_inst_code;

    reg [`MAX_BIT_POS:0] ex_mem_addr;
    reg [`MAX_BIT_POS:0] ex_mem_data;
    reg [4:0] ex_mem_rd;
    reg ex_mem_rd_en;
    reg [`MAX_BIT_POS:0] ex_mem_rd_data;
    reg ex_mem_write_en;
    reg ex_mem_read_en;
    reg [1:0] ex_mem_byte_size;

    reg [4:0] wb_rd_last;
    reg wb_rd_en_last;
    reg [`MAX_BIT_POS:0] wb_rd_data_last;

    reg wb_hazard; // 寄存器结构冒险标记，在内存指令操作同时可以执行计算指令，在写回时需要处理顺序
    reg [4:0] wb_rd;
    reg wb_rd_en;
    reg [`MAX_BIT_POS:0] wb_rd_data;

    wire pipe_flush; // 流水线冲刷标记
    reg ex_stop; // 执行停止标记
    reg rs1_forward, rs2_forward, rs1_forward_last, rs2_forward_last;  // 寄存器数据旁路标记

    task check_data_hazard(
        input check_rs1, check_rs2, check_rd,
        input ex_stop_check
    );

        if (ex_stop_check) begin
            if (check_rs1 || check_rs2 || check_rd) begin
                ex_stop = ex_stop_check && (((check_rd && rd != 5'd0) && ((rd == mem_rd_out && wb_rd_wait) || (rd == wb_rd && wb_rd_en)))
                || (check_rs1 && rs1 != 5'd0 && rs1 == mem_rd_out && wb_rd_wait)
                || (check_rs2 && rs2 != 5'd0 && rs2 == mem_rd_out && wb_rd_wait));
            end
            else begin
                ex_stop = 1'b0;
            end
        end
        else begin
            if (check_rs1 || check_rs2 || check_rd) begin
                rs1_forward = (rs1 == wb_rd && wb_rd_en);
                rs1_forward_last = (rs1 == wb_rd_last && wb_rd_en_last);
                rs2_forward = (rs2 == wb_rd && wb_rd_en);
                rs2_forward_last = (rs2 == wb_rd_last && wb_rd_en_last);
            end
            else begin
                rs1_forward = 1'b0;
                rs2_forward = 1'b0;
                rs1_forward_last = 1'b0;
                rs2_forward_last = 1'b0;
            end
        end
    endtask

    task check_inst(
        input ex_stop_check
    );
        if (inst_decode_out[5:0] != 6'd0) begin
            // branch
            check_data_hazard(1'b1, 1'b1, 1'b0, ex_stop_check);
        end
        else if (inst_decode_out[7:6] != 2'd0) begin
            // jalr 需要校验rs1
            check_data_hazard(inst_decode_out[6],1'b0,1'b1,ex_stop_check);
        end
        else if (inst_decode_out[27:9] != 19'd0) begin
            // alu
            if (inst_decode_out[20:18] != 3'd0 || inst_decode_out[23:22] != 2'd0 || inst_decode_out[27:26] != 2'd0) begin
                check_data_hazard(1'b1, 1'b1, 1'b1, ex_stop_check);
            end
            else begin
                check_data_hazard(1'b1, 1'b0, 1'b1, ex_stop_check);
            end
        end
        else if (inst_decode_out[36:29] != 8'd0) begin
            // mem
            if (inst_mem_busy & ex_stop_check) begin
                ex_stop = 1'b1;
            end
            else if (inst_decode_out[36:34] != 3'd0) begin
                check_data_hazard(1'b1, 1'b0, 1'b0, ex_stop_check);
            end
            else begin
                check_data_hazard(1'b1, 1'b1, 1'b1, ex_stop_check);
            end
        end
        else if (inst_decode_out[42:37] != 7'd0) begin
            // csr
            if (inst_decode_out[37] || inst_decode_out[39] || inst_decode_out[41]) begin
                check_data_hazard(1'b1, 1'b0, 1'b1, ex_stop_check);
            end
            else begin
                check_data_hazard(1'b0, 1'b0, 1'b1, ex_stop_check);
            end
        end
        else begin
            check_data_hazard(1'b0, 1'b0, 1'b0, ex_stop_check);
        end
    endtask

    task wb_task();
            if (mem_rd_en) begin
                wb_rd = mem_rd_out;
                wb_rd_data = mem_rd_data;
                wb_rd_en = 1'b1;
            end
            else if(branch_rd_out_en) begin
                wb_rd = branch_rd_out;
                wb_rd_data = branch_rd_data_out;
                wb_rd_en = 1'b1;
            end
            else if (alu_rd_out_en) begin
                wb_rd = alu_rd_out;
                wb_rd_data = alu_rd_data;
                wb_rd_en = 1'b1;
            end
            else if (csr_rd_out_en) begin
                wb_rd = csr_rd_out;
                wb_rd_data = csr_rd_data;
                wb_rd_en = 1'b1;
            end
            else begin
                wb_rd_en = 1'b0;
                wb_rd = 5'd0;
                wb_rd_data = 32'd0;
            end
    endtask

    // 控制冒险失败或者中断发生时，冲刷流水线
    assign pipe_flush = int_jmp_en | (branch_jmp_en & id_ex_control_hazard);
    assign fetch_en = ~ex_stop;
    // assign decoder_en = ~ex_stop;

    always @(inst_mem_busy or wb_rd_wait or mem_rd_out or inst_decode_out) begin
        check_inst(1'b1);
        if (inst_mem_busy & ~ex_stop) begin
            wb_hazard = 1'b1;
        end
    end

    task jmp_task();
        if (int_jmp_en) begin
            jmp_en = 1'b1;
            jmp_pc = int_jmp_pc;
            // 中断发生时，通过冲刷清理掉未执行的指令
        end
        else if (branch_jmp_en) begin
            jmp_en = 1'b1;
            jmp_pc = branch_pc_next_out;
            pc_next = branch_pc_next_out;
        end
        else begin
            jmp_en = 1'b0;
            jmp_pc = 32'd0;
        end
    endtask

    // if to id
    always @(posedge clk) begin
        if (rst) begin
            if_id_control_hazard <= (ex_stop || (mem_rd_en & wb_hazard)) ? if_id_control_hazard : ((~pipe_flush & inst_ready) ? fetch_hazard : 1'b0);
            if_id_pc_cur <= (ex_stop || (mem_rd_en & wb_hazard)) ? if_id_pc_cur : ((~pipe_flush & inst_ready) ? cur_inst_addr : 32'd0);
            if_id_pc_next <= (ex_stop || (mem_rd_en & wb_hazard)) ? if_id_pc_next : ((~pipe_flush & inst_ready) ? next_inst_addr : 32'd0);
            if_id_inst_code <= (ex_stop || (mem_rd_en & wb_hazard)) ? if_id_inst_code : ((~pipe_flush & inst_ready) ? inst_code : 32'd0);
        end
    end

    // id to ex
    always @(posedge clk) begin
        if (rst) begin
            wb_rd_last = wb_rd;
            wb_rd_data_last = wb_rd_data;
            wb_rd_en_last = wb_rd_en;
            jmp_task();
            wb_task();
            check_inst(1'b0);
            // 取指或者执行停顿都会导致取指停顿
            if (ex_stop || (mem_rd_en & wb_hazard)) begin
                if (wb_hazard) begin
                    // 结构冒险标志清理
                    wb_hazard = 1'b0;
                end
                id_ex_control_hazard <= id_ex_control_hazard;
                id_ex_pc_cur <= id_ex_pc_cur;
                id_ex_pc_next <= id_ex_pc_next;
                id_ex_inst_flags <= id_ex_inst_flags;
                id_ex_rd <= id_ex_rd;
                id_ex_imm_1231 <= id_ex_imm_1231;
                id_ex_rs1_data <= id_ex_rs1_data;
                id_ex_rs2_data <= id_ex_rs2_data;
                id_ex_rs1 <= id_ex_rs1;
                id_ex_rs2 <= id_ex_rs2;
                id_ex_cur_inst_code <= id_ex_cur_inst_code;
            end
            else if (pipe_flush) begin
                // 冲刷流水线
                id_ex_inst_flags <= 48'd0;
                id_ex_pc_cur <= 32'd0;
                id_ex_pc_next <= 32'd0;
                id_ex_rd <= 5'd0;
                id_ex_imm_1231 <= 20'd0;
                id_ex_rs1_data <= 32'd0;
                id_ex_rs2_data <= 32'd0;
                id_ex_rs1 <= 5'd0;
                id_ex_rs2 <= 5'd0;
                id_ex_control_hazard <= 1'b0;
                id_ex_cur_inst_code <= 32'd0;
            end
            else begin
                id_ex_inst_flags <= inst_decode_out;
                id_ex_rd <= rd;
                id_ex_imm_1231 <= imm_1231;
                id_ex_rs1_data <= rs1_forward? wb_rd_data : rs1_forward_last? wb_rd_data_last : rs1_out;
                id_ex_rs2_data <= rs2_forward? wb_rd_data : rs2_forward_last? wb_rd_data_last : rs2_out;
                id_ex_rs1 <= rs1;
                id_ex_rs2 <= rs2;
                id_ex_pc_cur <= if_id_pc_cur;
                id_ex_pc_next <= if_id_pc_next;
                id_ex_control_hazard <= if_id_control_hazard;
                id_ex_cur_inst_code <= if_id_inst_code;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jmp_en <= 1'd0;
            decoder_en <= 1'd1;
            wb_hazard <= 1'b0;
            cur_branch_hazard <= 1'b0;
            ex_stop <= 1'b0;
            wb_rd_en <= 1'b0;
            wb_rd_data <= 32'd0;
            wb_rd <= 5'd0;
            if_id_control_hazard <= 1'b0;
            if_id_pc_cur <= 32'd0;
            if_id_pc_next <= 32'd0;
            if_id_inst_code <= 32'd0;

            id_ex_control_hazard <= 1'b0;
            id_ex_pc_cur <= 32'd0;
            id_ex_pc_next <= 32'd0;
            id_ex_inst_flags <= 48'd0;
            id_ex_rd <= 5'd0;
            id_ex_rs1 <= 5'd0;
            id_ex_rs2 <= 5'd0;
            id_ex_rs1_data <= 32'd0;
            id_ex_rs2_data <= 32'd0;
            id_ex_imm_1231 <= 20'd0;
            id_ex_cur_inst_code <= 32'd0;
        end
    end

endmodule