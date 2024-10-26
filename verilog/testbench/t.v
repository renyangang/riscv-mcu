module t(
    input clk,
    input rst,
    output reg [3:0] leds
);

    always @(posedge clk or rst) begin
        if (!rst) begin
            leds <= 4'b0001;
        end
        else begin
            leds <= {leds[2:0], leds[3]};
        end
    end
endmodule