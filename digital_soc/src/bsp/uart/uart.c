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
#include "uart.h"
#include "timer.h"
#include "interrupt.h"

static volatile uint8_t* write_buffer = (volatile uint8_t*)UART1_DATA_ADDR;
static volatile uint8_t* read_buffer = (volatile uint8_t*)UART1_DATA_ADDR;
static volatile uint32_t* fifo_status = (volatile uint32_t*)UART1_DATA_STATUS_ADDR;


static volatile uint32_t uart_int_reg_status = 0;
static volatile uint32_t uart_int_status = 0;

void uart_int_proc() {
    uart_int_status = 1;
    // send_string("Interrupt received\n");
}

void uart_init(void) {
    // if(uart_int_reg_status == 0) {
    //     register_peripheral_int_handler(INT_UART, uart_int_proc);
    //     uart_int_reg_status = 1;
    // }
    // uart_int_status = 0;
    // 默认预置50mhz主频下的 115200波特率，无奇偶校验，8位数据位，1位停止位，关闭中断
    *(volatile uint32_t*)UART1_CONFIG_ADDR = 0x08e2001b;
}

void send_char(uint8_t c) {
    // wait for write fifo to be not full
    while (*fifo_status & (0x2 << 2));
    *write_buffer = c;
}

void send_data(uint8_t *data, uint32_t len) {
    for (uint32_t i = 0; i < len; i++) {
        send_char(data[i]);
    }
}

uint32_t read_data(uint8_t *data, uint32_t len) {
    uint32_t r_len = 0;
    while (((*fifo_status) & 0x3) && r_len < len) {
        data[r_len++] = *read_buffer;
    }
    return r_len;
}

void send_string(const char *str) {
    while (*str) {
        send_char(*str++);
    }
}

uint8_t getchar() {
    // waiting for the character to be received
    while (!((*fifo_status) & 0x3));
    uint8_t c = *read_buffer;
    return c;
}