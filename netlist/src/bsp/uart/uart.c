#include "uart.h"
#include "timer.h"
#include "interrupt.h"

static volatile uint8_t* write_buffer = (volatile uint8_t*)UART_WRITE_ADDR;
static volatile uint8_t* read_buffer = (volatile uint8_t*)UART_DMA_BASE;
static volatile uint32_t* buffer_end = (volatile uint32_t*)UART_CUR_BUFEND_ADDR;

static volatile uint32_t uart_int_reg_status = 0;
static volatile uint32_t uart_int_status = 0;

void uart_int_proc() {
    uart_int_status = 1;
    // send_string("Interrupt received\n");
}

void uart_init(void) {
    if(uart_int_reg_status == 0) {
        register_peripheral_int_handler(INT_UART, uart_int_proc);
        uart_int_reg_status = 1;
    }
    uart_int_status = 0;
}


void send_char(uint8_t c) {
    *write_buffer = c;
    while (!(*((volatile uint32_t*)UART_STATUS_ADDR) & 0x1)); // Wait for the previous byte to be sent
}

void send_data(uint8_t *data, uint32_t len) {
    for (uint32_t i = 0; i < len; i++) {
        send_char(data[i]);
    }
}

uint32_t read_data(uint8_t *data, uint32_t len) {
    uint32_t r_len = 0;
    uint8_t* ret_buffer = (uint8_t*)read_buffer;
    while (r_len < len && ret_buffer < (uint8_t*)(*buffer_end)) {
        data[r_len++] = *ret_buffer++;
    }
    *(volatile uint8_t**)UART_SET_READEND_ADDR = ret_buffer;
    return r_len;
}

void send_string(const char *str) {
    while (*str) {
        *write_buffer = *str++;
        while (!(*((volatile uint32_t*)UART_STATUS_ADDR) & 0x1)); // Wait for the previous byte to be sent
    }
}

uint8_t getchar() {
    // send keyboard enable command
    send_char((uint8_t)0xFF);
    // read the character
    
    // waiting for the character to be received
    while (uart_int_status == 0 && read_buffer >= (uint8_t*)(*buffer_end));
    uint8_t c = *read_buffer;
    // sleep(200);
    *(volatile uint8_t**)UART_SET_READEND_ADDR = read_buffer+4;
    while((uint8_t*)(*buffer_end) > read_buffer);
    uart_int_status = 0;
    return c;
}