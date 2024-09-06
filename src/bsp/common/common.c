#include "common.h"

#define HEAP_BASE 0x01100000


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

char* itoa(int value, char* str) {
    char digits[] = "0123456789";
    str[3] = '\0';
    char* ptr = &str[2];

    do {
        int digit = 0;
        int temp = value;
        while (temp >= 10) {
            temp -= 10;
            digit++;
        }
        *ptr-- = digits[temp];

        value = digit;
    } while (value > 0);
    return str;
}