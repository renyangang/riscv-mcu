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
    input [`MAX_BIT_POS:0] pc,
    input [`MAX_BIT_POS:0] pc_next,
    input [`MAX_BIT_POS:0] exp_val, //异常数据值
    input [`MAX_BIT_POS:0] exception_code,
    input exception_en,
    input cur_branch_hazard,
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

    wire exp_en;
    wire peripheral_int, software_int, timer_int;

    assign peripheral_int = mstatus[3] & mip[11] & mie[11];
    assign software_int = mstatus[3] & mip[3] & mie[3] & (!peripheral_int);
    assign timer_int = mstatus[3] & mip[7] & mie[7] & (!peripheral_int & !software_int);
    assign exp_en = exception_en | (peripheral_int | software_int | timer_int);

    task get_csr_value;
        input [11:0] addr;
        output [`MAX_BIT_POS:0] value;
        begin
            case (addr)
                12'h300: value = mstatus;
                12'h301: value = misa;
                12'h304: value = mie;
                12'h305: value = mtvec;
                12'h340: value = mscratch;
                12'h341: value = mepc;
                12'h342: value = mcause;
                12'h343: value = mtval;
                12'h344: value = mip;
                12'hF11: value = mvendorid;
                12'hF12: value = marchid;
                12'hF13: value = mimpid;
                12'hF14: value = mhartid;
                default: value = 32'h0;
            endcase
        end
    endtask

    always @(csr_read_addr) begin
        get_csr_value(csr_read_addr, csr_out);
    end

    always @(peripheral_int_code or soft_int_code) begin
        if (|(peripheral_int_code)) begin
            mip[7:0] <= {mip[31:12],1'b1,mip[10:0]};
            cur_int_code <= peripheral_int_code;
        end
        else if (|(soft_int_code)) begin
            mip[7:0] <= {mip[31:4],1'b1,mip[2:0]};
            cur_int_code <= soft_int_code;
        end
    end

    always @(posedge set_mtimecmp_low or posedge set_mtimecmp_high) begin
        if (set_mtimecmp_low) begin
            mtimecmp[31:0] <= mtimecmp_low;
        end
        else if (set_mtimecmp_high) begin
            mtimecmp[63:32] <= mtimecmp_high;
        end
    end

    always @(posedge clk_timer or negedge rst) begin
        if (!rst) begin
            mtime <= 64'd0;
            mtimecmp <= ~64'd0;
        end
        else begin
            mtime <= mtime + 64'd1;
            mip[7] <= (mtime >= mtimecmp) ? 1'b1 : 1'b0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            jmp_en <= 1'b0;
        end
        else begin
            if (exp_en && !cur_branch_hazard) begin
                mstatus <= {mstatus[31:8],mstatus[3],mstatus[6:4],1'b0,mstatus[2:0]};
                jmp_en <= 1'b1;
                if (exception_en) begin
                    mcause <= exception_code;
                    mepc <= pc;
                    mtval <= exp_val;
                    jmp_pc <= {mtvec[31:2],2'b00};
                end
                else begin
                    mepc <= pc_next;
                    if(peripheral_int) begin
                        mcause <= {1'd1,30'd11};
                        jmp_pc <= mtvec[0] ? ({mtvec[31:2],2'b00} + (4*11)):{mtvec[31:2],2'b00};
                    end
                    else if(software_int) begin
                        mcause <= {1'd1,30'd3};
                        jmp_pc <= mtvec[0] ? ({mtvec[31:2],2'b00} + (4*3)):{mtvec[31:2],2'b00};
                    end
                    else if(timer_int) begin
                        mcause <= {1'd1,30'd7};
                        jmp_pc <= mtvec[0] ? ({mtvec[31:2],2'b00} + (4*7)):{mtvec[31:2],2'b00};
                    end
                end
            end
            else if (write_en) begin
                case (csrw_addr)
                    12'h300: mstatus <= w_data;
                    12'h301: misa <= w_data;
                    12'h304: mie <= w_data;
                    12'h305: mtvec <= w_data;
                    12'h340: mscratch <= w_data;
                    12'h341: mepc <= w_data;
                    12'h342: mcause <= w_data;
                    12'h343: mtval <= w_data;
                    12'h344: mip <= w_data;
                    12'hF11: mvendorid <= w_data;
                    12'hF12: marchid <= w_data;
                    12'hF13: mimpid <= w_data;
                    12'hF14: mhartid <= w_data;
                endcase
                jmp_en <= 1'b0;
            end
            else begin
                jmp_en <= 1'b0;
            end
        end
    end
endmodule