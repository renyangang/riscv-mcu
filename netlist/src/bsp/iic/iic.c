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
#include "iic.h"
#include "interrupt.h"

static volatile uint32_t* iic_op = (volatile uint32_t*)IIC_OPERATION_ADDR;
static volatile uint32_t* iic_res_buf = (volatile uint32_t*)IIC_READBUF_ADDR;
static uint32_t iic_int_status = 0;
static uint32_t iic_int_reg_status = 0;

inline static void iic_int_proc() {
    iic_int_status = 1;
}

inline static void iin_int_status_clear() {
    iic_int_status = 0;
}

inline static void wait_iic_int() {
    // wait for interrupt or op flag complate ,this is not a good way, just for leaning
    while(iic_int_status == 0 && (*iic_res_buf & 0x1));
}

void iic_init(void) {
    if(iic_int_reg_status == 0) {
        register_peripheral_int_handler(INT_IIC, iic_int_proc);
        iic_int_reg_status = 1;
    }
    iin_int_status_clear();
}

void iic_write(uint8_t dev_addr, uint8_t reg_addr, uint8_t data) {
    iic_init();
    uint32_t op = 0;
    op |= (dev_addr << 1);
    op |= (reg_addr << 8);
    op |= (data << 16);
    *iic_op = op;
    wait_iic_int();
}

uint8_t iic_read(uint8_t dev_addr, uint8_t reg_addr) {
    iic_init();
    uint32_t op = 0;
    op |= 0x1;
    op |= (dev_addr << 1);
    // reg_addr is ignored
    *iic_op = op;
    wait_iic_int();
    // read data
    uint8_t r =  (uint8_t)(((*iic_res_buf) >> 8) & 0xFF);
    return r;
}