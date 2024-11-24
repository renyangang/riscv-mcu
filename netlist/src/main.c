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
#include "gpio.h"
#include "timer.h"
#include "interrupt.h"
#include "uart.h"
#include "guess.h"

static int mode = 0;

void flash_by_sleep() {
    // set low 7 pins of port D as output
    set_all_pins_mode(0x7f);
    for(;;) {
        mode = get_pin(10);
        if(mode) {
            set_all_pins(get_all_pins() | 0x7f);
            sleep(500);
            set_all_pins(get_all_pins() & ~0x7f);
            sleep(500);
        } else {
            for(int i=1;i<8 && mode==0;i++) {
                set_pin(i, 1);
                sleep(500);
                set_pin(i, 0);
            }
        }
    }
}

static int cur_pin = 0;
static int cur_pins_status = 0;

void flash_timer_handler() {
    // set low 7 pins of port D as output
    set_all_pins_mode(0x7f);
    if(mode) {
        if(cur_pins_status) {
            set_all_pins(get_all_pins() & ~0x7f);
            cur_pins_status = 0;
        }else{
            set_all_pins(get_all_pins() | 0x7f);
            cur_pins_status = 1;
        }
    } else {
        set_all_pins(get_all_pins() & ~0x7f);
        cur_pin++;
        if(cur_pin > 7) {
            cur_pin = 1;
        }
        set_pin(cur_pin, 1);
    }
    send_string("led status changed\n");
    add_soft_timer(500, flash_timer_handler);
}

void mode_change_handler() {
    mode = get_pin(10);
    clear_gpio_int();
    send_string("led flash mode changed\n");
}

void flash_by_interrupt() {
    init_global_timer();
    add_soft_timer(500, flash_timer_handler);
    register_peripheral_int_handler(INT_GPIO,mode_change_handler);
    for(;;) {}
}

int main() {
    flash_by_sleep();
    flash_by_interrupt();
    // run_guess_game();
    return 0;
}