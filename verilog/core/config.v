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

 Description: global configuration and macros

 */
`define XLEN 32
`define MAX_BIT_POS (`XLEN-1)
`define CACHE_LINES 64
`define CACHE_LINE_SIZE 16
`define CACHE_LINE_WIDTH (`CACHE_LINE_SIZE*8)
`define CACHE_WAYS 4

`define BOOT_ADDR 32'h0000_0000

`define GPIO_NUMS 32

`define FLASH_ADDR_BASE  `XLEN'h0000_0000
`define FLASH_ADDR_END  `XLEN'h00FF_FFFF
`define INT_ADDR_BASE  `XLEN'h0FFF_0000
`define INT_ADDR_END  `XLEN'h0FFF_F000
`define TIMER_ADDR_BASE  `XLEN'h0FFF_F000
`define TIMER_ADDR_END  `XLEN'h0FFF_FFFF
`define SDRAM_ADDR_BASE  `XLEN'h1000_0000
`define SDRAM_ADDR_END  `XLEN'h3FFF_FFFF
`define GPIO_ADDR_BASE  `XLEN'hC000_0000
`define GPIO_ADDR_END  `XLEN'hC000_0FFF
`define UART_ADDR_BASE  `XLEN'hC001_0000
`define UART_ADDR_END  `XLEN'hC001_0fff
`define I2C_ADDR_BASE  `XLEN'hC003_0000
`define I2C_ADDR_END  `XLEN'hC003_0fff
`define SPI_ADDR_BASE  `XLEN'hC005_0000
`define SPI_ADDR_END  `XLEN'hC005_0fff

`define EXCEPT_ILLEGAL_INSTR `XLEN'd2
`define EXCEPT_NONALIGNED_INST_ADDR `XLEN'd0

// interrupt defines
`define INT_CODE_WIDTH 8
`define INT_CODE_NONE `INT_CODE_WIDTH'd0
`define INT_CODE_GPIO `INT_CODE_WIDTH'd1
`define INT_CODE_UART1_RX_READY `INT_CODE_WIDTH'd11
`define INT_CODE_UART1_TX_READY `INT_CODE_WIDTH'd12