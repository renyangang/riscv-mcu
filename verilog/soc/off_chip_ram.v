`include "config.v"

module off_chip_ram(
    input clk,
    input rst,
    input [31:0] addr,
    input [(`CACHE_LINE_SIZE*8)-1:0] data_in,
    input write_en,
    input read_en,
    output [(`CACHE_LINE_SIZE*8)-1:0] data_out,
    output reg status_ready
);

    always @(negedge rst) begin
        if(!rst) begin
            status_ready <= 1'b0;
        end
    end

    always @(addr or write_en or read_en) begin
        status_ready = 1'b0;
    end

endmodule