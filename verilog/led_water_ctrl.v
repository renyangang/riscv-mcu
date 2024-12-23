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
module led_water_ctrl (
    input clk_ss,
    input rst_n,
    output led1,
    output led2,
    output led3
);
   
   reg [2:0] led_state;
   reg [24:0] counter;

   assign led1 = led_state[0];
   assign led2 = led_state[1];
   assign led3 = led_state[2];

   localparam COUTER_MAX = 25'd999;
   
   always @(posedge clk_ss or negedge rst_n) begin
      if (!rst_n) begin
         led_state <= 3'b001;
         counter <= 25'b0;
      end 
      else begin
         counter <= counter + 1;
         if (counter == COUTER_MAX) begin
            counter <= 25'b0;
            led_state <= {led_state[1:0], led_state[2]};
         end
         else if (!(|led_state)) begin
            led_state <= 3'b001;
         end
      end
   end
    
endmodule