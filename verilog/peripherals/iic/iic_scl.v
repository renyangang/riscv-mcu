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
    File Name   : iic_scl.v
    Description: iic_scl
*/
module iic_scl(
    input  wire clk,
    input  wire rst_n,
    input  [31:0] scl_count_max,
    input  [31:0] scl_sample_count_max,
    output reg  sample_scl_out,
    output reg  scl_out
);

reg [24:0] counter_scl;
reg [24:0] counter_sample_scl;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n || scl_count_max == 0) begin
        scl_out <= 1'b1;
        counter_scl <= 25'd0;
    end
    else if (counter_scl == scl_count_max) begin
        scl_out <= ~scl_out;
        counter_scl <= 25'd0;
    end
    else begin
        counter_scl <= counter_scl + 25'd1;
    end
end

always @(posedge clk or posedge rst_n) begin
    if (!rst_n || scl_sample_count_max == 0) begin
        sample_scl_out <= 1'b1;
        counter_sample_scl <= 25'd0;
    end
    else if (counter_sample_scl == scl_sample_count_max) begin
        sample_scl_out <= ~sample_scl_out;
        counter_sample_scl <= 25'd0;
    end
    else begin
        counter_sample_scl <= counter_sample_scl + 25'd1;
    end
end

endmodule