`timescale 1ns/1ns
`include "config.v"

module digital_soc_top;
    reg clk;
    wire rst;
    wire clk_timer;

    reg [42:0] input_sig;
    wire [146:0] output_sig;

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
    assign output_sig = {gpio_values[31:0],digital_mem_wdata[31:0],digital_mem_byte_size[3:0],digital_mem_read_en,digital_mem_write_en,digital_mem_addr[31:0],digital_flash_wdata[7:0],digital_flash_byte_size[2:0],digital_flash_read_en,digital_flash_write_en,digital_flash_addr[31:0]};
    // assign output_sig = {32'd1,32'd2,4'd0,1'b1,1'b1,32'd2,8'd1,3'd0,1'b0,1'b0,32'd2};
    assign rst = input_sig[1];
    assign clk_timer = input_sig[2];
    assign digital_flash_data = input_sig[10:3];
    assign digital_mem_data = input_sig[42:11];

    initial begin
        $dumpfile("digital.vcd");
        $dumpvars(0, digital_soc_top);
    end

    digital_soc digital_soc(
        .clk(input_sig[0]),
        .rst(rst),
        .clk_timer(clk_timer),
        .digital_flash_addr(digital_flash_addr),
        .digital_flash_write_en(digital_flash_write_en),
        .digital_flash_read_en(digital_flash_read_en),
        .digital_flash_byte_size(digital_flash_byte_size),
        .digital_flash_wdata(digital_flash_wdata),
        .digital_flash_data(digital_flash_data),
        .digital_mem_addr(digital_mem_addr),
        .digital_mem_write_en(digital_mem_write_en),
        .digital_mem_read_en(digital_mem_read_en),
        .digital_mem_byte_size(digital_mem_byte_size),
        .digital_mem_wdata(digital_mem_wdata),
        .digital_mem_data(digital_mem_data),
        .gpio_values(gpio_values)
    );

    initial begin
        clk = 0;
        input_sig = 0;
        $setSignalNames("digital_soc_top.input_sig", "digital_soc_top.output_sig");
        // rst = 0;
        // clk_timer = 0;
        // // offchip_mem_ready = 0;
        // #10 rst = 1;
        
    end

    genvar idx;
    generate
        for (idx = 0; idx < `GPIO_NUMS; idx = idx + 1) begin
            pulldown(gpio_values[idx]);
        end
    endgenerate

    always @(posedge clk) begin
        $refresh;
        // $display("input_sig = %b, output_sig = %b", input_sig, output_sig);
    end

    always #50 clk = ~clk;
    // always #100 clk_timer = ~clk_timer;


endmodule