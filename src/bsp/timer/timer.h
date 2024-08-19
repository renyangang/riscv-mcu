#ifndef TIMER_H
#define TIMER_H
#include "types.h"

#define MTIME_CMP_LOW 0xB0000000
#define MTIME_CMP_HIGH 0xB0000004
#define MTIME_LOW 0xB0000008
#define MTIME_HIGH 0xB000000C

typedef int (*soft_callback) (uint64_t cur, uint64_t cmp);

uint64_t get_mtime_cur();
uint64_t get_mtime_cmp();

void add_soft_timer(uint64_t ms, soft_callback call_back);

void set_timer_after(int ms);
#endif