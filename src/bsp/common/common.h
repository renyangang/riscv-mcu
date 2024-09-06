#ifndef COMMON_H
#define COMMON_H

#include "types.h"

void* memset(void* s, uint8_t c, size_t n);

uint8_t atoi(const char* str);

char* itoa(int value, char* str);

#endif /* COMMON_H */