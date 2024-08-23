#include "uart.h"
#include "timer.h"

static volatile uint8_t* write_buffer = (volatile uint8_t*)UART_WRITE_ADDR;
static volatile uint8_t* read_buffer = (volatile uint8_t*)UART_DMA_BASE;
static volatile uint32_t* buffer_end = (volatile uint32_t*)UART_CUR_BUFEND_ADDR;

void send_data(uint8_t *data, uint32_t len) {
    for (uint32_t i = 0; i < len; i++) {
        *write_buffer = data[i];
        while (!(*((volatile uint32_t*)UART_STATUS_ADDR) & 0x1)); // Wait for the previous byte to be sent
    }
}

uint32_t read_data(uint8_t *data, uint32_t len) {
    uint32_t r_len = 0;
    while (r_len < len && read_buffer < (uint8_t*)(*buffer_end)) {
        data[r_len++] = *read_buffer++;
    }
    *(volatile uint8_t**)UART_SET_READEND_ADDR = read_buffer;
    return r_len;
}

void send_string(const char *str) {
    while (*str) {
        *write_buffer = *str++;
        while (!(*((volatile uint32_t*)UART_STATUS_ADDR) & 0x1)); // Wait for the previous byte to be sent
    }
}