#include "common.h"

void* memset(void* s, uint8_t c, size_t n) {
    unsigned char* p = s;
    while (n--) {
        *p++ = (unsigned char)c;
    }
    return s;
}

uint8_t atoi(const char* str) {
    uint8_t res = 0;
    while (*str) {
        res = res * 10 + (*str++ - '0');
    }
    return res;
}