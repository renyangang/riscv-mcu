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

void set_pin_mode(int pin, int mode) {
    if(mode) {
        *(int*)GPIO_CONFIG_ADDR = *(int*)GPIO_CONFIG_ADDR | (mode << (pin - 1));
    } else {
        *(int*)GPIO_CONFIG_ADDR = *(int*)GPIO_CONFIG_ADDR & ~(mode << (pin - 1));
    }
}

void set_all_pins_mode(int mode) {
    *(int*)GPIO_CONFIG_ADDR = mode;
}

void set_pin(int pin, int value) {
    if(value) {
        *(int*)GPIO_SET_ADDR = *(int*)GPIO_READ_ADDR | (1 << (pin - 1));
    } else {
        *(int*)GPIO_SET_ADDR = *(int*)GPIO_READ_ADDR & ~(1 << (pin - 1));
    }
}

void set_all_pins(int value) {
    *(int*)GPIO_SET_ADDR = value;
}

int get_all_pins() {
    return *(int*)GPIO_READ_ADDR;
}

int get_pin(int pin) {
    return *(int*)GPIO_READ_ADDR & (1 << (pin - 1));
}

void clear_gpio_int() {
    *(int*)GPIO_INT_CLEAR_ADDR = 0;
}