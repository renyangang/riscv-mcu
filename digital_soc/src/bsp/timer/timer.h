#ifndef TIMER_H
#define TIMER_H
#include "types.h"
#include "addr.h"

#define MTIME_CMP_LOW (TIMER_ADDR_BASE+8)
#define MTIME_CMP_HIGH (TIMER_ADDR_BASE+12)
#define MTIME_LOW TIMER_ADDR_BASE
#define MTIME_HIGH (TIMER_ADDR_BASE+4)

#define MAX_SOFT_TIMER_NUM 5

typedef void (*soft_callback) ();

typedef struct {
    uint64_t ms_wakeup;
    soft_callback call_back;
} soft_timer_t;


uint64_t get_mtime_cur();
uint64_t get_mtime_cmp();

int add_soft_timer(uint64_t ms, soft_callback call_back);

/**
 * after kernel start, init a global timer
 * other timers in application can use soft timer
 * this global timer is used to recive timer interrupt and wake up soft timer
 */
void init_global_timer();

void interrupt_timer_handler();

void sleep(uint64_t ms);

#endif