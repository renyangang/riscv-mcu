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
#include "interrupt.h"
#include "uart.h"
#include "common.h"

static int_handler_t int_handler[PERIPHERAL_INT_NUM] = {NULL};
static int_handler_t timer_handler = NULL;

static uint32_t cur_int_mode = 0;

void register_peripheral_int_handler(int int_num, int_handler_t handler) {
    int_handler[int_num] = handler;
    if(cur_int_mode < PERIPHERAL_INT) {
        cur_int_mode |= PERIPHERAL_INT;
        set_mie(cur_int_mode);
    }
}

void register_timer_int_handler(int_handler_t handler) {
    timer_handler = handler;
    cur_int_mode |= TIMER_INT;
    set_mie(cur_int_mode);
}

void exception_handler() {
    return;
}

void int_timer_handler() {
    if(timer_handler) {
        timer_handler();
    }
    return;
}

void int_peripheral_handler() {
    // send_string("int peripheral handler\n");
    uint32_t int_code = *(uint32_t *)INT_CODE_ADDR;
    if(int_handler[int_code]) {
        int_handler[int_code]();
    }
    return;
}

