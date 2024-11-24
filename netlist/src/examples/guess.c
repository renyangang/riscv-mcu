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
#include "guess.h"
#include "iic.h"
#include "uart.h"
#include "timer.h"
#include "common.h"

void run_guess_game() {
    uart_init();
    while(1){
        iic_write(DEV_ADDRESS, MIN_REG_ADDR, MIN_NUMBER);
        iic_write(DEV_ADDRESS, MAX_REG_ADDR, MAX_NUMBER);
        while(1) {
            uint8_t fact_num = iic_read(DEV_ADDRESS, 0);
            while(1) {
                send_string("Guess one number between [1,100]: ");
                uint8_t guess_num[4] = {0,0,0,0};
                int i = 0;
                while(i < 3) {
                    uint8_t c = getchar();
                    if (c == 0xa) {
                        break;
                    }
                    send_char(c);
                    guess_num[i++] = c;
                }
                send_string("\n");
                uint8_t guess = atoi((char*)guess_num);
                if (guess == fact_num) {
                    send_string("You win!\n");
                    break;
                } else if( guess > fact_num) {
                    send_string("Too large!\n");
                } else {
                    send_string("Too small!\n");
                }
            }
        }
        sleep(500);
   }
}