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
    input wire clk_timer,

    // 片外内存
    input [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data,
    input offchip_mem_ready,
    output [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata,
    output wire offchip_mem_write_en,
    output wire offchip_mem_read_en,
    output wire [31:0] offchip_mem_addr
);

    wire read_en;
    wire [31:0] mem_addr;
    wire [31:0] rdata;
    wire write_en;
    wire [31:0] wdata;
    wire [1:0] byte_size;
    wire mem_busy;
    wire mem_ready;

    // interrupts and exceptions
    reg [31:0]pc_cur;
    reg [31:0]pc_next;
    reg [31:0]inst_cur_ex;
    reg [31:0]exception_code;
    reg exception_en;
    wire [31:0] int_jmp_pc;
    wire int_jmp_en;

    // csr operations
    reg [11:0] csr_read_addr;
    wire [31:0] csrw_data;
    wire [11:0] csrw_addr;
    wire [31:0] csr_data;
    wire csr_out_en;

    

    // branch instuctions
    wire [31:0] branch_pc_next_out;
    wire branch_jmp_en;
    wire [4:0] branch_rd_out;
    wire [31:0] branch_rd_data_out;
    wire branch_rd_out_en;
    reg cur_branch_inst; // 标识当前是否正在执行跳转指令，如果是，中断等处理就需要等待结果

    // fetch
    wire inst_read_en;
    wire [31:0] cur_inst_addr;
    wire [31:0] next_inst_addr;
    wire [31:0] inst_code;
    wire inst_ready;
    reg [31:0] jmp_pc;
    reg jmp_en;
    reg next_en;
    wire [31:0] inst_data;
    wire inst_mem_ready;

    // decode
    reg [31:0] instruction_code;
    reg decoder_en;
    reg decoder_state;
    wire [47:0] inst_decode_out;

    // memory instructions
    wire inst_mem_busy; // 访存指令忙

     sys_bus sys_bus(
        .clk(clk),
        .rst(rst),
        .inst_read_en(inst_read_en),       
        .inst_read_addr(next_inst_addr),
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
        .pc(pc_cur),
        .pc_next(pc_next),
        .inst_cur(inst_cur_ex),
        .exception_code(exception_code),
        .cur_branch_inst(cur_branch_inst),
        .exception_en(exception_en),
        .jmp_en(int_jmp_en),
        .jmp_pc(int_jmp_pc),
        .clk_timer(clk_timer),
        
        .csr_read_addr(csr_read_addr),
        .csrw_addr(csrw_addr),
        .w_data(csrw_data),
        .csr_write_en(csr_out_en),
        .csr_out(csr_data),

        // 片外内存获取通道
        .offchip_mem_data(offchip_mem_data),
        .offchip_mem_ready(offchip_mem_ready),
        .offchip_mem_wdata(offchip_mem_wdata),
        .offchip_mem_write_en(offchip_mem_write_en),
        .offchip_mem_read_en(offchip_mem_read_en),
        .offchip_mem_addr(offchip_mem_addr)
    );

    inst_fetch inst_fetch(
        .clk(clk),
        .rst(rst),
        .jmp_pc(jmp_pc),
        .jmp_en(jmp_en),
        .next_en(next_en),
        // 指令返回通道
        .inst_data(inst_data),
        .inst_mem_ready(inst_mem_ready),
        .inst_mem_read_en(inst_read_en),

        .cur_inst_addr(cur_inst_addr),
        .next_inst_addr(next_inst_addr),
        .inst_code(inst_code),
        .inst_ready(inst_ready)
    );

    wire [4:0] rd, rs1, rs2;
    wire [19:0] imm_1231;
    wire invalid_instruction;
    

    inst_decoder inst_decoder(
        .instruction_code(instruction_code),
        .en(decoder_en),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .imm_1231(imm_1231),
        .invalid_instruction(invalid_instruction),
        .inst_flags(inst_decode_out)
    );

    reg [4:0] inst_rd_reg;
    reg [31:0] rs1_data, rs2_data;
    reg [19:0] imm_1231_reg;
    
    wire [4:0] alu_rd_out;
    wire alu_rd_out_en;
    wire [31:0] alu_rd_data;

    ex_alu alu(
        .rst(rst),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_1231(imm_1231_reg),
        .inst_flags(cur_ex_inst_code),
        .rd_out(alu_rd_out),
        .out_en(alu_rd_out_en),
        .rd_data(alu_rd_data)
    );

    ex_branch ex_branch(
        .rst(rst),
        .pc_cur(pc_cur),
        .pc_next(pc_next),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_1231(imm_1231_reg),
        .inst_flags(cur_ex_inst_code),
        .rd_out(branch_rd_out),
        .rd_out_en(branch_rd_out_en),
        .rd_data_out(branch_rd_data_out),
        .pc_next_out(branch_pc_next_out),
        .jmp_en(branch_jmp_en)
    );

    wire  [4:0] mem_rd_out;
    wire mem_rd_en;
    wire [31:0] mem_rd_data;

    ex_mem ex_mem(
        .clk(clk),
        .rst(rst),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm_2031(imm_1231_reg[19:8]),
        .inst_flags(cur_ex_inst_code),
        .mem_data_in(rdata),
        .mem_read_ready(mem_ready),
        .mem_write_ready(mem_ready),

        .busy_flag(inst_mem_busy),
        .rd_out(mem_rd_out),
        .rd_en(mem_rd_en),
        .rd_data(mem_rd_data),
        .byte_size(byte_size),
        .mem_data(wdata),
        .mem_addr(mem_addr),
        .mem_write_en(csr_write_en),
        .mem_read_en(read_en)
    );

    wire [4:0] csr_rd_out;
    wire csr_rd_out_en;
    wire [31:0] csr_rd_data;
    

    ex_csr ex_csr(
        .rst(rst),
        .rd(inst_rd_reg),
        .rs1_data(rs1_data),
        .csr_data(csr_data),
        .imm_2031(imm_1231_reg[19:8]),
        .imm_1519(imm_1231_reg[7:3]),
        .inst_flags(cur_ex_inst_code),
        .rd_out(csr_rd_out),
        .out_en(csr_rd_out_en),
        .rd_data(csr_rd_data),
        .csr_out_en(csr_out_en),
        .csrw_data(csrw_data),
        .csrw_addr(csrw_addr)
    );

    reg [4:0] wb_rd;
    reg wb_rd_en;
    reg wb_wait_mem_flag;
    reg [31:0] wb_rd_data;
    wire [31:0] rs1_out;
    wire [31:0] rs2_out;

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
    reg [47:0] cur_ex_inst_code;
    reg control_hazard; // 控制冒险标记
    reg branch_jmp_prediction; // 静态预测结果 0 不跳转 1 跳转
    reg fetch_stop; // 取指停止标记
    reg ex_stop; // 执行停止标记
    reg ex_mem_rd_wait; // 执行阶段访存写回依赖标记
    reg pipe_flush; // 流水线冲刷标记

    reg rs1_forward, rs2_forward;

    reg ex_state;

    task check_data_hazard(
        input check_rs1, check_rs2,
        output reg need_stop
    );
        if (check_rs1 && rs1 == wb_rd && wb_rd_en && rs1 != 5'd0) begin
            if (wb_wait_mem_flag) begin
                need_stop = 1'b1;
                rs1_forward = 1'b0;
            end
            else begin
                rs1_forward = 1'b1;
                need_stop = 1'b0;
            end
        end
        else if (check_rs2 && rs2 == wb_rd && wb_rd_en && rs2 != 5'd0) begin
            if (wb_wait_mem_flag) begin
                need_stop = 1'b1;
                rs2_forward = 1'b0;
            end
            else begin
                rs2_forward = 1'b1;
                need_stop = 1'b0;
            end
        end
        else begin
            rs1_forward = 1'b0;
            rs2_forward = 1'b0;
            need_stop = 1'b0;
        end
    endtask

    task check_inst();
        if (inst_decode_out[5:0] != 6'd0) begin
            // 分支跳转指令，进行静态预测， 向后统一预测为跳转，向前统一预测为不跳转
            branch_jmp_prediction = imm_1231[19]; // 地址为负数，高位为1，则预测跳转
            if (imm_1231[19]) begin
                fetch_stop = 1'b1;
            end
            else begin
                // 只有预测为不跳转,才是冒险，跳转直接停顿流水线取指，无需标记
                control_hazard = 1'b1;
            end
            check_data_hazard(1'b1, 1'b1, ex_stop);
        end
        else if (inst_decode_out[7:6] != 2'd0) begin
            // jal jalr 指令，必然跳转
            fetch_stop = 1'b1;
            // jalr 需要校验rs1
            check_data_hazard(inst_decode_out[6],1'b0,ex_stop);
        end
        else if (inst_decode_out[27:9] != 19'd0) begin
            // alu
            if (inst_decode_out[20:18] != 3'd0 || inst_decode_out[23:22] != 2'd0 || inst_decode_out[27:26] != 2'd0) begin
                check_data_hazard(1'b1, 1'b1, ex_stop);
            end
            else begin
                check_data_hazard(1'b1, 1'b0, ex_stop);
            end
        end
        else if (inst_decode_out[36:29] != 8'd0) begin
            // mem
            if (inst_decode_out[36:34] != 3'd0) begin
                check_data_hazard(1'b1, 1'b0, ex_stop);
            end
            else begin
                check_data_hazard(1'b1, 1'b1, ex_stop);
            end
        end
        else if (inst_decode_out[42:37] != 7'd0) begin
            // csr
            if (inst_decode_out[37] || inst_decode_out[39] || inst_decode_out[41]) begin
                check_data_hazard(1'b1, 1'b0, ex_stop);
            end
            else begin
                check_data_hazard(1'b0, 1'b0, ex_stop);
            end
        end
        else begin
            check_data_hazard(1'b0, 1'b0, ex_stop);
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

    task jmp_task();
        if (int_jmp_en) begin
            jmp_en = 1'b1;
            jmp_pc = int_jmp_pc;
        end
        else if (branch_jmp_en) begin
            jmp_en = 1'b1;
            jmp_pc = branch_pc_next_out;
            pc_next = branch_pc_next_out;
            cur_branch_inst = 1'b0;
            if (control_hazard) begin
                // 控制冒险失败，冲刷流水线
                pipe_flush = 1'b1;
            end
            if (fetch_stop) begin
                fetch_stop = 1'b0;
            end
        end
    endtask

    always @(posedge inst_ready) begin
        next_en = 1'b0; // 指令读取完成，等待译码处理完毕后，再进行下一条指令获取
    end

    always @(cur_ex_inst_code) begin
        cur_branch_inst = (inst_decode_out[7:0] != 8'd0);
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jmp_en <= 1'd0;
            next_en <= 1'd1;
            decoder_en <= 1'd1;
            decoder_state <= 1'b0;
            ex_state <= 1'b0;
            control_hazard <= 1'b0;
            branch_jmp_prediction <= 1'b0;
            instruction_code <= 32'd0;
            cur_ex_inst_code <= 48'd0;
            cur_branch_inst <= 1'b0;
            fetch_stop <= 1'b0;
            ex_stop <= 1'b0;
            pipe_flush <= 1'b0;
            wb_rd_en <= 1'b0;
            wb_rd <= 5'd0;
        end
        else begin
            wb_task();
            jmp_task();
            if (inst_ready && !next_en && !decoder_state) begin
                if ((pipe_flush && jmp_pc != cur_inst_addr) || fetch_stop || ex_stop) begin
                    // 冲刷流水线，直接传递一个空指令译码
                    instruction_code <= 32'd0;
                    pipe_flush <= 1'b0;
                end
                else begin
                    instruction_code <= inst_code;
                    // 当前解码的指令，是ex执行的下一条指令
                    pc_next <= cur_inst_addr;
                    decoder_state <= 1'b1;
                end
            end
            if (decoder_state) begin
                check_inst();
                // 取指或者执行停顿都会导致取指停顿
                next_en <= (~ex_stop & ~fetch_stop) & ~((inst_decode_out[36:29] != 8'd0) & inst_mem_busy);
                if (pipe_flush) begin
                    // 译码完成后冲刷流水线
                    cur_ex_inst_code <= 48'd0;
                    pipe_flush <= 1'b0;
                    decoder_state <= 1'b0;
                end
                // 如果下一步执行的是访存指令，并且当前访存还未结束，则暂停流水线（结构冒险冲突)
                else if (!ex_stop && !((inst_decode_out[36:29] != 8'd0) && inst_mem_busy)) begin
                    cur_ex_inst_code <= inst_decode_out;
                    pc_cur <= pc_next;
                    // 数据前向传递
                    inst_rd_reg <= rd;
                    imm_1231_reg <= imm_1231;
                    rs1_data <= rs1_forward? wb_rd_data : rs1_out;
                    rs2_data <= rs2_forward? wb_rd_data : rs2_out;
                    decoder_state <= 1'b0;
                    ex_state <= 1'b1;
                end
                else begin
                    cur_ex_inst_code <= 48'd0;
                    decoder_state <= decoder_state;
                end
            end
            else if (!ex_state) begin
                // 如果执行已完成，但是还没有新指令到来，加一条空指令进去
                cur_ex_inst_code <= 48'd0;
                ex_state <= 1'b1;
            end
            if (ex_state) begin
                // 一个周期运行结束，内存操作指令触发停顿实现
                ex_state <= 1'b0;
            end
        end
    end

endmodule