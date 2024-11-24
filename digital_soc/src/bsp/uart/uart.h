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
#ifndef UART_H
#define UART_H

#include "types.h"
#include "addr.h"

// Set baud rate, start bit, stop bit and other communication configurations
// [15:0]  波特率时钟分频数，整数部分  主频/(波特率 * 16)
// [20:16] 每16个整数周期中，小数分频添加个数  (主频 % (波特率 * 16)) * 16
// [24:21] 小数添加间隔 1 / (主频 % (波特率 * 16))
// [26:25] parity_mode; // 0 none 1 even 2 odd
// [28:27] stop_bit;
// [29] // data ready int enable
// [30] // write ready int enable
#define UART1_CONFIG_ADDR UART1_ADDR_BASE
// Read/Write data to the UART
#define UART1_DATA_ADDR (UART1_ADDR_BASE + 0x4)
// read/write fifo status 
// [1:0] read fifo 0 empty 1 not empty 2 full 
// [3:2] write fifo 0 empty 1 not empty 2 full
#define UART1_DATA_STATUS_ADDR (UART1_ADDR_BASE + 0x8)

void uart_init(void);

void send_char(uint8_t c);
void send_data(uint8_t *data, uint32_t len);
uint32_t read_data(uint8_t *data, uint32_t len);
// get char from uart keyboard
uint8_t getchar();
void send_string(const char *str);

#endif