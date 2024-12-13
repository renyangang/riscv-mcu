module breath_led(
    input clk_s,
    input clk_ss,
    input rst_n,
    output reg [7:0] led
);

localparam COUNT_MAX = 15;

reg [7:0] cnt_10ms;
reg [7:0] cnt_100ms;
reg [7:0] cnt_1s;
reg led_en;

always @(posedge clk_s or negedge rst_n) begin
    if(!rst_n) begin
        cnt_10ms <= 0;
    end
    else begin
        if (cnt_10ms == COUNT_MAX) begin
            cnt_10ms <= 0;
        end
        else begin
            cnt_10ms <= cnt_10ms + 1;
        end
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if(!rst_n) begin
        cnt_100ms <= 0;
    end
    else begin
        if (cnt_100ms == COUNT_MAX) begin
            cnt_100ms <= 0;
        end
        else if(cnt_10ms == COUNT_MAX) begin
            cnt_100ms <= cnt_100ms + 1;
        end
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if(!rst_n) begin
        cnt_1s <= 0;
    end
    else begin
        if (cnt_1s == COUNT_MAX) begin
            cnt_1s <= 0;
        end
        else if(cnt_100ms == COUNT_MAX) begin
            cnt_1s <= cnt_1s + 1;
        end
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if(!rst_n) begin
        led_en <= 1'b0;
    end
    else begin
        if (cnt_1s == COUNT_MAX) begin
            led_en <= ~led_en;
        end
    end
end

always @(posedge clk_s or negedge rst_n) begin
    if(!rst_n) begin
        led <= 8'h00;
    end
    else begin
        if ((!led_en && cnt_100ms < cnt_1s) || (led_en && cnt_100ms >= cnt_1s)) begin
            led <= 8'hFF;
        end
        else begin
            led <= 8'h0;
        end
    end
end

endmodule