`timescale 1ns/1ns
`include "cache.v"

module cache_tb();

    reg clk;
    reg rst_n;
    reg [31:0] addr;
    reg [31:0] data_in;
    reg write_enable;
    reg load_enable;
    reg read_enable;
    reg [127:0] write_load_data;
    reg save_ready;
    wire save_data;
    wire data_hit;
    wire status_ready;
    wire load_complate;
    wire [31:0] data_out;
    wire [127:0] write_back_data;

    initial begin            
        $dumpfile("cache.vcd");
        $dumpvars; // dump all vars
    end

cache dut(
	.clk(clk),
	.rst_n(rst_n),
	.addr(addr),
	.data_in(data_in),
	.write_enable(write_enable),
	.load_enable(load_enable),
	.read_enable(read_enable),
	.write_load_data(write_load_data),
	.save_ready(save_ready),
	.save_data(save_data),
	.data_hit(data_hit),
	.status_ready(status_ready),
	.load_complate(load_complate),
	.data_out(data_out),
    .write_back_data(write_back_data)
);

    task read_and_load;
        input [31:0] addr_read;
        input [127:0] write_load_data_read;
        begin
            read_enable = 1'b1;
            addr = addr_read;
            #1;
            wait(status_ready);
             #10;
            if(data_hit) begin
                $display("addr: %h, read data: %h", addr_read, data_out);
                read_enable = 1'b0;
            end
            else begin
                read_enable = 1'b0;
                write_load_data = write_load_data_read;
                load_enable = 1'b1;
                wait(load_complate || save_data);
                if (save_data) begin
                    $display("save back data: %h", write_back_data);
                    #20;
                    save_ready = 1'b1;
                    wait(load_complate);
                end
                load_enable = 1'b0;
                $display("addr: %h, load data to cache: %h", addr_read,write_load_data_read);
            end
        end
    endtask;

    task read_data;
        input [31:0] addr_read;
        begin
            read_enable = 1'b1;
            addr = addr_read;
            #10;
            wait(status_ready);
            if(data_hit) begin
                $display("addr: %h, read data: %h", addr_read, data_out);
            end
            else begin
                $display("addr: %h, failed to hit cache", addr_read);
            end
            read_enable = 1'b0;
        end
    endtask;

    task write_data;
        input [31:0] addr_write;
        input [31:0] wdata_in;
        begin
            addr = addr_write;
            data_in = wdata_in;
            write_enable = 1'b1;
            #1;
            wait(status_ready);
             #10;
            if(data_hit) begin
                $display("addr: %h, write data: %h", addr_write, wdata_in);
            end
            write_enable = 1'b0;
        end
    endtask;
    

    always #10 clk = ~clk;
    integer i;
    initial begin
        clk = 0;
        rst_n = 0;
        addr = 0;
        data_in = 0;
        write_enable = 0;
        load_enable = 0;
        write_load_data = 0;
        read_enable = 0;
        save_ready = 0;
        #11;
        rst_n = 1;
        #21;
        // way 0
        $display("way 0");
        read_and_load(32'h0000_0000,128'h1010_0000_1C1C_0000_1414_0000_1111);
        #21;
        read_data(32'h0000_0000);
        #21;
        read_data(32'h0000_0004);
        #21;
        read_data(32'h0000_0008);
        #21;
        read_data(32'h0000_000C);

        // way 1
        $display("\nway 1");
        #21;
        read_and_load(32'hA000_0000,128'hAAAA);
        #21;
        read_data(32'hA000_0000);
        #21;
        read_data(32'h0000_0000);

        // diffent index
        $display("\ndiffent index");
        #21;
        read_and_load(32'h0000_0010,128'h1010);
        #21;
        read_data(32'h0000_0010);
        #21;
        read_data(32'hA000_0000);
        #21;
        read_data(32'h0000_0000);
       
        // replace
        $display("\nreplace");
        #21;
        read_and_load(32'hB000_0000,128'h1111_2222_3333_4444_5555_6666_7777_BBBB);
        #21;
        read_data(32'hB000_0000);
        #21;
        read_data(32'h0000_0010);
        #21;
        read_data(32'hA000_0000);
        #21;
        read_data(32'h0000_0000);

        // write data
        $display("\nwrite data");
        #21;
        write_data(32'h0000_0000,32'h0000_1234);
        #21;
        read_data(32'h0000_0000);

        // write back dirty data
        $display("\nwrite back dirty data");
        #21;
        read_data(32'hB000_0000);
        #21;
        read_and_load(32'hC000_0000,128'hCCCC);
        #21;
        read_data(32'h0000_0000);
        #21;
        read_data(32'hC000_0000);
        #21;
        read_data(32'hB000_0000);

        #21;

        #101;
        $finish;
    end

endmodule