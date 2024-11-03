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

 Description: register file
    寄存器文件 csr 寄存器,12位地址,只实现部分机器模式寄存器
    写入读取都是单周期完成
    根据mip和mie实现中断寄存器设置和跳转pc计算
    定时器寄存器，以及中断触发
 */
`include "config.v"
 module registers_csr(
    input wire clk,
    input wire rst,

    // 中断信号
    input [`MAX_BIT_POS:0] exp_pc,
    input [`MAX_BIT_POS:0] exp_pc_next,
    input [`MAX_BIT_POS:0] exp_val, //异常数据值
    input [`MAX_BIT_POS:0] exception_code,
    input exception_en,
    input int_jmp_ready,
    input mret_en,
    output wire int_en, // 中断信号,中断信号发出后，等待cpu响应int_jmp_ready信号
    output reg jmp_en,
    output reg [`MAX_BIT_POS:0] jmp_pc,

    input [`INT_CODE_WIDTH-1:0]peripheral_int_code,
    input [`INT_CODE_WIDTH-1:0]soft_int_code,
    output reg [`INT_CODE_WIDTH-1:0] cur_int_code,

    // 定时器处理
    input wire clk_timer,
    input wire [`MAX_BIT_POS:0] mtimecmp_low,
    input wire [`MAX_BIT_POS:0] mtimecmp_high,
    input wire set_mtimecmp_low,
    input wire set_mtimecmp_high,
    output wire [`MAX_BIT_POS:0] mtime_low,
    output wire [`MAX_BIT_POS:0] mtime_high,

    input wire [11:0] csr_read_addr,
    input wire [11:0] csrw_addr,
    input wire [`MAX_BIT_POS:0] w_data,
    input wire write_en,
    output reg [`MAX_BIT_POS:0] csr_out
    );
    
    reg [`MAX_BIT_POS:0] mstatus; // 12'h300
    reg [`MAX_BIT_POS:0] misa; // 12'h301
    reg [`MAX_BIT_POS:0] mie; // 12'h304
    reg [`MAX_BIT_POS:0] mtvec; // 12'h305
    reg [`MAX_BIT_POS:0] mscratch; // 12'h340
    reg [`MAX_BIT_POS:0] mepc; // 12'h341
    reg [`MAX_BIT_POS:0] mcause; // 12'h342
    reg [`MAX_BIT_POS:0] mtval; // 12'h343
    reg [`MAX_BIT_POS:0] mip; // 12'h344
    reg [`MAX_BIT_POS:0] mvendorid; // 12'hF11
    reg [`MAX_BIT_POS:0] marchid; // 12'hF12
    reg [`MAX_BIT_POS:0] mimpid; // 12'hF13
    reg [`MAX_BIT_POS:0] mhartid; // 12'hF14

    reg [63:0] mtime;
    reg [63:0] mtimecmp;
    reg int_proc_state; // 1 中断处理中，这是不再发出中断信号

    wire peripheral_int, software_int, timer_int;

    assign peripheral_int = mstatus[3] & mip[11] & mie[11];
    assign software_int = mstatus[3] & mip[3] & mie[3] & (!peripheral_int);
    assign timer_int = mstatus[3] & mip[7] & mie[7] & (!peripheral_int & !software_int);
    assign int_en = (peripheral_int | software_int | timer_int) & (~int_proc_state);
    assign mtime_low = mtime[31:0];
    assign mtime_high = mtime[63:32];

    always @(*) begin
        case (csr_read_addr)
            12'h300: csr_out = mstatus;
            12'h301: csr_out = misa;
            12'h304: csr_out = mie;
            12'h305: csr_out = mtvec;
            12'h340: csr_out = mscratch;
            12'h341: csr_out = mepc;
            12'h342: csr_out = mcause;
            12'h343: csr_out = mtval;
            12'h344: csr_out = mip;
            12'hF11: csr_out = mvendorid;
            12'hF12: csr_out = marchid;
            12'hF13: csr_out = mimpid;
            12'hF14: csr_out = mhartid;
            default: csr_out = 32'h0;
        endcase
    end

    /* verilator lint_off LATCH */
    always @(*) begin
        if (!rst) begin
            mip = `XLEN'd0;
        end
        else begin
            if (|(peripheral_int_code)) begin
                mip[11] = 1'b1;
                cur_int_code = peripheral_int_code;
            end
            else begin
                mip[11] = 1'b0;
            end
            if (|(soft_int_code)) begin
                mip[3] = 1'b1;
                cur_int_code = soft_int_code;
            end
            else begin
                mip[3] = 1'b0;
            end
            if (mtime >= mtimecmp) begin
                mip[7] =  1'b1;
            end
            else begin
                mip[7] =  1'b0;
            end
        end
    end

    always @(posedge clk_timer or negedge rst) begin
        if (!rst) begin
            mtime <= 64'd0;
        end
        else begin
            mtime <= mtime + 64'd1;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            mtimecmp <= {64{1'b1}};
        end
        else begin
            if (set_mtimecmp_low) begin
                mtimecmp[31:0] <= mtimecmp_low;
            end
            else if (set_mtimecmp_high) begin
                mtimecmp[63:32] <= mtimecmp_high;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jmp_en <= 1'b0;
            jmp_pc <= `XLEN'd0;
            mstatus <= `XLEN'd0;
            misa <= `XLEN'b11000000000000000000000010000000;
            mie <= `XLEN'd0;
            mtvec <= `XLEN'd0;
            mscratch <= `XLEN'd0;
            mvendorid <= `XLEN'd0;
            marchid <= `XLEN'd0;
            mimpid <= `XLEN'd0;
            mhartid <= `XLEN'd0;
        end
        else begin
            if (write_en) begin
                case (csrw_addr)
                    12'h300: mstatus <= w_data;
                    // 12'h301: misa <= w_data;
                    12'h304: mie <= w_data;
                    12'h305: mtvec <= w_data;
                    12'h340: mscratch <= w_data;
                    // 12'h341: mepc <= w_data;
                    // 12'h342: mcause <= w_data;
                    // 12'h343: mtval <= w_data;
                    default: ;
                endcase
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            int_proc_state <= 1'b0;
            jmp_en <= 1'b0;
            jmp_pc <= `XLEN'd0;
            mepc <= `XLEN'd0;
            mcause <= `XLEN'd0;
            mtval <= `XLEN'd0;
        end
        else begin
            if (exception_en) begin
                mstatus[7] <= mstatus[3];
                mstatus[3] <= 1'b0;
                jmp_en <= 1'b1;
                mcause <= exception_code;
                mepc <= exp_pc;
                mtval <= exp_val;
                jmp_pc <= {mtvec[31:2],2'b00};
            end
            else if (mret_en) begin
                jmp_en <= 1'b1;
                jmp_pc <= mepc;
                mepc <= `XLEN'd0;
                mstatus[3] <= mstatus[7];
                mstatus[7] <= 1'b1;
                int_proc_state <= 1'b0;
            end
            else if (int_jmp_ready && !int_proc_state) begin
                mepc <= exp_pc_next;
                int_proc_state <= 1'b1;
                jmp_en <= 1'b1;
                mstatus[7] <= mstatus[3];
                mstatus[3] <= 1'b0;
                if(peripheral_int) begin
                    mcause <= {1'd1,31'd11};
                    jmp_pc <= mtvec[0] ? ({mtvec[31:2],2'b00} + (4*11)):{mtvec[31:2],2'b00};
                end
                else if(software_int) begin
                    mcause <= {1'd1,31'd3};
                    jmp_pc <= mtvec[0] ? ({mtvec[31:2],2'b00} + (4*3)):{mtvec[31:2],2'b00};
                end
                else if(timer_int) begin
                    mcause <= {1'd1,31'd7};
                    jmp_pc <= mtvec[0] ? ({mtvec[31:2],2'b00} + (4*7)):{mtvec[31:2],2'b00};
                end
            end
            else begin
                jmp_en <= 1'b0;
            end
        end
    end
endmodule