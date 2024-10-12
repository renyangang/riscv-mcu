#include "timer.h"
#include "interrupt.h"

static soft_timer_t soft_timers[MAX_SOFT_TIMER_NUM];

uint64_t get_mtime_cur() {
    return *(uint64_t*)MTIME_LOW;;
}

uint64_t get_mtime_cmp() {
    return *(uint64_t*)MTIME_CMP_LOW;;
}

void set_mtime_cmp(uint64_t cmp) {
    *(uint32_t*)MTIME_CMP_HIGH = cmp >> 32;
    *(uint32_t*)MTIME_CMP_LOW = cmp & 0xffffffff;
}

static void set_timer_after(int ms) {
    uint64_t ctime = get_mtime_cur();
    set_mtime_cmp(ctime + ms);
}

int add_soft_timer(uint64_t ms, soft_callback call_back) {
    for(int i = 0; i < MAX_SOFT_TIMER_NUM; i++) {
        if(soft_timers[i].call_back == NULL) {
            soft_timers[i].call_back = call_back;
            soft_timers[i].ms_wakeup = get_mtime_cur() + ms;
            return 0;
         }
    }
    return 1; // no space
}

void init_global_timer() {
    for(int i = 0; i < MAX_SOFT_TIMER_NUM; i++) {
        soft_timers[i].call_back = NULL;
    }
    set_timer_after(300);
    register_timer_int_handler(interrupt_timer_handler);
}

void interrupt_timer_handler() {
    for(int i = 0; i < MAX_SOFT_TIMER_NUM; i++) {
        if(soft_timers[i].call_back != NULL) {
            if(soft_timers[i].ms_wakeup <= get_mtime_cur()) {
                soft_timers[i].call_back();
                soft_timers[i].call_back = NULL;
            }
        }
    }
    set_timer_after(100);
}

void sleep(uint64_t ms) {
    uint64_t ctime = get_mtime_cur() + ms;
    while(get_mtime_cur() < ctime) {
        __asm__ __volatile__("nop");
    }
}