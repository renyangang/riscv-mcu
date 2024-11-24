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
`timescale 1ns/1ns
`include "config.v"
`include "cpu_pipeline.v"

module cpu_tb;
    reg clk;
    reg rst;
    reg clk_timer;

    // 片外内存
    reg [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_data;
    reg offchip_mem_ready;
    wire [(`CACHE_LINE_SIZE*8)-1:0] offchip_mem_wdata;
    output wire offchip_mem_write_en;
    output wire offchip_mem_read_en;
    output wire [`MAX_BIT_POS:0] offchip_mem_addr;

    // cpu_pipeline cpu_pipeline(
    //     .clk(clk),
    //     .rst(rst),
    //     .clk_timer(clk_timer),
    //     .offchip_mem_data(offchip_mem_data),
    //     .offchip_mem_ready(offchip_mem_ready),
    //     .offchip_mem_wdata(offchip_mem_wdata),
    //     .offchip_mem_write_en(offchip_mem_write_en),
    //     .offchip_mem_read_en(offchip_mem_read_en),
    //     .offchip_mem_addr(offchip_mem_addr)
    // );

    reg [7:0] memory [0:255];  // 假设要加载 256 个字节的内容
    integer i;

    initial begin
        // 读取 hex 文件
        $readmemh("test.hex", memory);

        // // 打印每个字节以确保数据正确加载
        // for (i = 0; i < 256; i = i + 1) begin
        //     $display("memory[%0d] = %02x", i, memory[i]);
        // end
    end

    always @(posedge offchip_mem_read_en) begin
        for (i = 0; i < 16; i = i + 1) begin
            offchip_mem_data[i*8 +: 8] = memory[offchip_mem_addr+i];  // 逐字节赋值
        end
        offchip_mem_ready = 1'd1;
        #20;
        offchip_mem_ready = 1'd0;
    end

    initial begin            
        $dumpfile("cpu_pipeline.vcd");
        $dumpvars; // dump all vars
    end

    initial begin
        clk = 0;
        rst = 0;
        clk_timer = 0;
        offchip_mem_ready = 0;
        #10 rst = 1;
        
        #500;
        $finish;
    end

    always #5 clk = ~clk;
    always #100 clk_timer = ~clk_timer;


endmodule