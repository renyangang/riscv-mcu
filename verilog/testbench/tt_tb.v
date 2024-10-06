`timescale 1ps/1ps

`define ABC 16
module tt_tb;
    reg clk;
    reg rst;
    reg [2:0] status;
    reg flag;
    reg sflag;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            status <= 3'b000;
            flag <= 1'd0;
        end
        else begin
            if (flag) begin
                status <= status + 1'b1;
                flag <= 1'd0;
            end
            else begin
                status <= 3'b000;
            end
        end
    end

    always @(posedge sflag) begin
        flag <= 1'd1;
    end

    initial begin            
        $dumpfile("tt.vcd");
        $dumpvars; // dump all vars
    end

    always #20 clk = ~clk;

    reg [0:0] st;

    initial begin
        // clk = 1'b0;
        // rst = 1'b0;
        // sflag = 1'b0;
        // #100 rst = 1'b1;
        // #100 sflag = 1'b1;
        // #100 sflag = 1'b0;
        // #100 sflag = 1'b1;
        // #100 sflag = 1'b0;
        // #100 sflag = 1'b1;
        // #100 sflag = 1'b1;
        // #100 sflag = 1'b1;
        // #100 sflag = 1'b1;
        st = 1'b0;
        $display("testbench start %d", st[0]);
        #100 st = 1'b1;
        $display("testbench start %d", st[0]);
        $display("testbench start %d", $clog2(4));
        $finish;
    end
endmodule