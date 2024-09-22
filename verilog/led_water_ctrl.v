module led_water_ctrl (
    input clk,
    input rst,
    output led1,
    output led2,
    output led3
);
   
   reg [2:0] led_state;
   reg [15:0] counter;

   assign led1 = led_state[0];
   assign led2 = led_state[1];
   assign led3 = led_state[2];
   
   always @(posedge clk or negedge rst) begin
      if (!rst) begin
         led_state <= 3'b001;
         counter <= 16'b0;
      end 
      else begin
         counter <= counter + 1;
         if (counter == 16'd19) begin
            counter <= 16'b0;
            led_state <= {led_state[1:0], led_state[2]};
         end
         else begin
            led_state <= led_state;
         end
      end
   end
    
endmodule