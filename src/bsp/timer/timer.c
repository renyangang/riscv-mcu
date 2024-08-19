#include "timer.h"

uint64_t get_mtime_cur() {
    uint64_t mtime_cur = (uint64_t)*(uint32_t*)MTIME_HIGH << 32;
    mtime_cur |= *(uint32_t*)MTIME_LOW;
    return mtime_cur;
}

uint64_t get_mtime_cmp() {
    uint64_t mtime_cmp = ((uint64_t)*(uint32_t*)MTIME_CMP_HIGH) << 32;
    mtime_cmp |= *(uint32_t*)MTIME_CMP_LOW;
    return mtime_cmp;
}

void add_soft_timer(uint64_t ms, soft_callback call_back) {
    
}

void set_timer_after(int ms) {
    volatile int* ctime = (int*)MTIME_LOW;
    volatile int* cmp_time = (int*)MTIME_CMP_LOW;
    *cmp_time = (*ctime) + ms;
}