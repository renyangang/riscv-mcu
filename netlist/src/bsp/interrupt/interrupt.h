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
#ifndef INTERRUPT_H
#define INTERRUPT_H
#include "types.h"

#define TIMER_INT 0x80
#define PERIPHERAL_INT 0x800
#define SOFT_INT 0x8

#define INT_CODE_ADDR 0xB0001000

#define PERIPHERAL_INT_NUM 5
#define INT_GPIO 0x1
#define INT_UART 0x2
#define INT_IIC 0x3

typedef void (*int_handler_t)(void);

void register_peripheral_int_handler(int int_num, int_handler_t handler);
void register_timer_int_handler(int_handler_t handler);

extern void set_mie(int mie);

#endif