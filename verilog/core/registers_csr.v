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
 */

 module registers_csr(
    input wire clk,
    input wire rst,
    input wire [11:0] csr1_addr,
    input wire [11:0] csr2_addr,
    input wire [4:0] csrw_addr,
    input wire [31:0] w_data,
    input wire write_en,
    output reg [31:0] csr1_out,
    output reg [31:0] csr2_out
    );
    
    reg [31:0] mstatus; // 12'h300
    reg [31:0] misa; // 12'h301
    reg [31:0] mie; // 12'h304
    reg [31:0] mtvec; // 12'h305
    reg [31:0] mscratch; // 12'h340
    reg [31:0] mepc; // 12'h341
    reg [31:0] mcause; // 12'h342
    reg [31:0] mtval; // 12'h343
    reg [31:0] mip; // 12'h344
    reg [31:0] mvendorid; // 12'hF11
    reg [31:0] marchid; // 12'hF12
    reg [31:0] mimpid; // 12'hF13
    reg [31:0] mhartid; // 12'hF14

    task get_csr_value;
        input [11:0] addr;
        output [31:0] value;
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

    always @(csr1_addr or csr2_addr) begin
        get_csr_value(csr1_addr, csr1_out);
        get_csr_value(csr2_addr, csr2_out);
    end

    always @(posedge clk) begin
        if (write_en) begin
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
        end 
    end
endmodule