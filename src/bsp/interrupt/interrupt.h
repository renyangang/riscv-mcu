#ifndef INTERRUPT_H
#define INTERRUPT_H
#include "types.h"

#define TIMER_INT 0x80
#define PERIPHERAL_INT 0x800
#define SOFT_INT 0x8

#define INT_CODE_ADDR 0xB0001000

#define PERIPHERAL_INT_NUM 5
#define INT_GPIO 0x1

typedef void (*int_handler_t)(void);

void register_peripheral_int_handler(int int_num, int_handler_t handler);
void register_timer_int_handler(int_handler_t handler);

extern void set_mie(int mie);

#endif