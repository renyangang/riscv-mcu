`include "config.v"

module digital_soc_top(
    input [43:0] input_sig,
    output [146:0] output_sig
);
    // reg clk;
    wire rst;
    wire clk_timer;
    wire clk_r;
    reg digital_flash_ready;
    reg digital_mem_ready;

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
    assign clk_r = input_sig[0];
    assign rst = input_sig[1];
    assign clk_timer = input_sig[2];
    assign digital_flash_data = input_sig[10:3];
    assign digital_mem_data = input_sig[42:11];
    assign gpio_values[9] = input_sig[43];

    // initial begin
    //     $dumpfile("D:\\work\\v-computer\\cpu-v\\digital_soc\\verilog\\digital.vcd");
    //     $dumpvars(0, digital_soc_top);
    // end

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

    reg digital_flash_ready_r;
    reg digital_mem_ready_r;

    always @(posedge clk_r) begin
        if (rst) begin
            digital_flash_ready_r <= (~digital_flash_ready) ? 1'b1 : digital_flash_ready;
            digital_mem_ready_r <= (~digital_mem_ready) ? 1'b1 : digital_mem_ready;
        end
        else begin
            digital_mem_ready_r <= 1'b0;
            digital_flash_ready_r <= 1'b0;
        end
    end

    always @(digital_flash_addr or digital_flash_write_en or digital_flash_read_en or digital_flash_ready_r) begin
        digital_flash_ready = 1'b0;
        if (digital_flash_ready_r) begin
            digital_flash_ready = 1'b1;
        end
    end

    always @(digital_mem_addr or digital_mem_write_en or digital_mem_read_en or digital_mem_ready_r) begin
        digital_mem_ready = 1'b0;
        if (digital_mem_ready_r) begin
            digital_mem_ready = 1'b1;
        end
    end

    // always #50 clk = ~clk;
    // always #1000000 clk_timer = ~clk_timer;


endmodule