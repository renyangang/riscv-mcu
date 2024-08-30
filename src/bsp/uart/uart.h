#ifndef UART_H
#define UART_H

#include "types.h"

// Set baud rate, start bit, stop bit and other communication configurations
// note: this is reserved for future use
#define UART_CONFIG_ADDR 0xA0000100
// Write data to the UART
#define UART_WRITE_ADDR 0xA0000104
// after read data from the UART, set current read address for clear interupt
#define UART_SET_READEND_ADDR 0xA0000108
// current data bufer end address
#define UART_CUR_BUFEND_ADDR 0xA000010C
// get uart current status bit 0 writeable other bits reserved (read only)
#define UART_STATUS_ADDR 0xA0000110
// data buffer start address
#define UART_DMA_BASE 0xC0000000


void send_char(uint8_t c);
void send_data(uint8_t *data, uint32_t len);
uint32_t read_data(uint8_t *data, uint32_t len);
// get char from uart keyboard
uint8_t getchar();
void send_string(const char *str);

#endif