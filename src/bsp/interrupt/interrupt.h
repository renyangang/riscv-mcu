#ifndef INTERRUPT_H
#define INTERRUPT_H
#include "types.h"

#define TIMEER_INT 0x80
#define PERIPHERAL_INT 0x800
#define SOFT_INT 0x8

#define INT_CODE_ADDR 0xB0001000

uint64_t get_cur_mtime();

void exception_handler();
void int_timer_handler();
void int_peripheral_handler();


extern void set_mie(int mie);

#endif