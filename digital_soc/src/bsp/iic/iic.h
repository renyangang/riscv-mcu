#ifndef IIC_H
#define IIC_H

#include "types.h"

/***
0xA0000200 -> IIC opration config address 
              (bits[1-7]: dev address, bit[0]: read/write)
              (bits[8-15]: reg address valid in write mode)
              (bits[16-23]: data only support 1 byte valid in write mode)
              (bits[24-31]: reserved)
0xA0000204 -> IIC read buffer address
              (bits[1-7]: reserved, bit[0]: opration status 0 doing 1 complate)
              (bits[8-15]: data only support 1 byte valid in read mode)
              (bits[16-31]: reserved)
 */

#define IIC_OPERATION_ADDR 0xA0000200
#define IIC_READBUF_ADDR 0xA0000204


void iic_write(uint8_t dev_addr, uint8_t reg_addr, uint8_t data);
uint8_t iic_read(uint8_t dev_addr, uint8_t reg_addr);

#endif