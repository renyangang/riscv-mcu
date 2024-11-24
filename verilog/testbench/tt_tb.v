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
`timescale 1ms/1ms

module tt_tb;
    reg [42:0] inputsig;
    reg [81:0] inputsig1;
    wire [81:0] outputsig;

    reg clk;
    reg rst;

    reg [2:0] leds;
    assign outputsig = inputsig1;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            leds <= 3'b000;
            inputsig1 <= 82'h22ee_22ee_33ff_33ff;
        end
        else begin
            $refresh;
            $display("inputsig = %b", inputsig1);
            $display("inputsig = %b", inputsig);
            leds <= inputsig[2:0];
        end
    end

    initial begin
        rst = 0;
        clk = 0;
        $setSignalNames("tt_tb.inputsig", "tt_tb.outputsig");
        #20;
        rst = 1;
        $refresh;
    end

    always #20000000 clk = ~clk;

endmodule