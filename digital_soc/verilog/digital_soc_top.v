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
`include "config.v"

module digital_soc_top(
    input clk,
    input [43:0] input_sig,
    output [146:0] output_sig
);
    // reg clk;
    wire rst;
    wire clk_timer;
    wire clk_r;
    wire digital_flash_ready;
    wire digital_mem_ready;

    wire  [`MAX_BIT_POS:0] digital_flash_addr;
    wire  digital_flash_write_en;
    wire  digital_flash_read_en;
    wire  [2:0] digital_flash_byte_size;
    wire  [7:0] digital_flash_wdata;
    wire  [7:0] digital_flash_data;
    wire  [`MAX_BIT_POS:0] digital_mem_addr;
    wire  digital_mem_write_en;
    wire  digital_mem_read_en;
    wire  [3:0] digital_mem_byte_size;
    wire  [`MAX_BIT_POS:0] digital_mem_wdata;
    wire  [`MAX_BIT_POS:0] digital_mem_data;
    wire  [`GPIO_NUMS-1:0] gpio_values;

    // assign output_sig = {digital_flash_addr[31:0],digital_flash_write_en,digital_flash_read_en,digital_flash_byte_size[2:0],digital_flash_wdata[7:0],
    // digital_mem_addr[31:0],digital_mem_write_en,digital_mem_read_en,digital_mem_byte_size[3:0],digital_mem_wdata[31:0],gpio_values[31:0]};
    assign output_sig = {gpio_values[31:0],digital_mem_wdata_l[31:0],digital_mem_byte_size[3:0],digital_mem_read_en_l,digital_mem_write_en_l,digital_mem_addr_l[31:0],digital_flash_wdata_l[7:0],digital_flash_byte_size[2:0],digital_flash_read_en_l,digital_flash_write_en_l,digital_flash_addr_l[31:0]};
    // assign output_sig = {32'd1,32'd2,4'd0,1'b1,1'b1,32'd2,8'd1,3'd0,1'b0,1'b0,32'd2};
    assign clk_r = input_sig[0];
    assign rst = input_sig[1];
    assign clk_timer = input_sig[2];
    assign digital_flash_data_l = input_sig[10:3];
    assign digital_mem_data_l = input_sig[42:11];
    assign gpio_values[9] = input_sig[43];

    initial begin
        // $dumpfile("D:\\work\\v-computer\\cpu-v\\digital_soc\\verilog\\digital.vcd");
        $dumpfile("D:\\work\\source\\linux\\cpu-v\\digital_soc\\verilog\\digital.vcd");
        $dumpvars(0, digital_soc_top);
    end


    digital_soc digital_soc(
        .clk(clk_r),
        .rst(rst),
        .clk_timer(clk_timer),
        .digital_flash_addr(digital_flash_addr),
        .digital_flash_write_en(digital_flash_write_en),
        .digital_flash_read_en(digital_flash_read_en),
        .digital_flash_byte_size(digital_flash_byte_size),
        .digital_flash_wdata(digital_flash_wdata),
        .digital_flash_data(digital_flash_data),
        .digital_flash_ready(digital_flash_ready),
        .digital_mem_addr(digital_mem_addr),
        .digital_mem_write_en(digital_mem_write_en),
        .digital_mem_read_en(digital_mem_read_en),
        .digital_mem_byte_size(digital_mem_byte_size),
        .digital_mem_wdata(digital_mem_wdata),
        .digital_mem_data(digital_mem_data),
        .digital_mem_ready(digital_mem_ready),
        .gpio_values(gpio_values)
    );

    // initial begin
    //     // clk = 0;
    //     // input_sig = 0;
    //     // $setSignalNames("digital_soc_top.input_sig", "digital_soc_top.output_sig");
    //     // rst = 0;
    //     // clk_timer = 0;
    //     // // offchip_mem_ready = 0;
    //     // #10 rst = 1;
        
    // end

    genvar idx;
    generate
        for (idx = 0; idx < `GPIO_NUMS; idx = idx + 1) begin
            pulldown(gpio_values[idx]);
        end
    endgenerate

    // reg [7:0] flash [0:4000];
    // reg [`MAX_BIT_POS:0] memory [0:8000];
    // integer i;

    // initial begin
    //     // 读取 hex 文件
    //     // $readmemh("D:\\work\\v-computer\\cpu-v\\digital_soc\\src\\test.hex", flash);

    //     for(i=0;i<8000;i=i+1) begin
    //         memory[i] = 0;
    //     end
    // end

    // always @(posedge digital_mem_write_en or digital_mem_addr or posedge digital_mem_read_en) begin
    //     digital_mem_ready = 1'd0;
    //     if (digital_mem_write_en) begin
    //         memory[{digital_mem_addr[12:0]}] = digital_mem_wdata;
    //         digital_mem_ready = 1'd1;
    //     end
    //     if (digital_mem_read_en) begin
    //         digital_mem_data = memory[{digital_mem_addr[12:0]}];
    //         digital_mem_ready = 1'd1;
    //     end
    // end

    // always @(posedge digital_flash_read_en or digital_flash_addr) begin
    //     digital_flash_ready = 1'd0;
    //     if (digital_flash_read_en) begin
    //         digital_flash_data = flash[digital_flash_addr];
    //         digital_flash_ready = 1'd1;
    //     end
    //     // offchip_mem_ready = 1'd1;
    //     // #20;
    //     // offchip_mem_ready = 1'd0;
    // end

    // always @(posedge clk) begin
    //     $refresh;
    //     // $display("input_sig = %b, output_sig = %b", input_sig, output_sig);
    // end

    wire digital_flash_ready_l;
    wire digital_mem_ready_l;

    wire  [`MAX_BIT_POS:0] digital_flash_addr_l;
    wire  digital_flash_write_en_l;
    wire  digital_flash_read_en_l;
    wire  [2:0] digital_flash_byte_size_l;
    wire  [7:0] digital_flash_wdata_l;
    wire  [7:0] digital_flash_data_l;
    wire  [`MAX_BIT_POS:0] digital_mem_addr_l;
    wire  digital_mem_write_en_l;
    wire  digital_mem_read_en_l;
    wire  [3:0] digital_mem_byte_size_l;
    wire  [`MAX_BIT_POS:0] digital_mem_wdata_l;
    wire  [`MAX_BIT_POS:0] digital_mem_data_l;

    hl_adapter #(8) hl_adapter_flash (
        .clk_h(clk),
        .rst(rst),
        .clk_l(clk_r),
        .h_read_en(digital_flash_read_en),
        .h_write_en(digital_flash_write_en),
        .h_addr(digital_flash_addr),
        .h_data_in(digital_flash_wdata),
        .h_data_ready(digital_flash_ready),
        .h_data_out(digital_flash_data),
        .l_read_en(digital_flash_read_en_l),
        .l_write_en(digital_flash_write_en_l),
        .l_addr(digital_flash_addr_l),
        .l_data_in(digital_flash_wdata_l),
        .l_data_out(digital_flash_data_l)
    );

    hl_adapter #(`XLEN) hl_adapter_mem (
        .clk_h(clk),
        .rst(rst),
        .clk_l(clk_r),
        .h_read_en(digital_mem_read_en),
        .h_write_en(digital_mem_write_en),
        .h_addr(digital_mem_addr),
        .h_data_in(digital_mem_wdata),
        .h_data_ready(digital_mem_ready),
        .h_data_out(digital_mem_data),
        .l_read_en(digital_mem_read_en_l),
        .l_write_en(digital_mem_write_en_l),
        .l_addr(digital_mem_addr_l),
        .l_data_in(digital_mem_wdata_l),
        .l_data_out(digital_mem_data_l)
    );

    // always #50 clk = ~clk;
    // always #1000000 clk_timer = ~clk_timer;


endmodule