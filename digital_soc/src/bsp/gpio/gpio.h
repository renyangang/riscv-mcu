#ifndef GPIO_H
#define GPIO_H
#include "addr.h"

// GPIO address 
#define GPIO_CONFIG_ADDR GPIO_ADDR_BASE
#define GPIO_SET_ADDR (GPIO_ADDR_BASE+4)
#define GPIO_READ_ADDR (GPIO_ADDR_BASE+8)
#define GPIO_INT_READ_ADDR (GPIO_ADDR_BASE+12)
#define GPIO_INT_CLEAR_ADDR (GPIO_ADDR_BASE+16)

#define GPIO_INPUT_MODE 0
#define GPIO_OUTPUT_MODE 1

// gpio mode set functions
void set_pin_mode(int pin, int mode);
void set_all_pins_mode(int mode);
// gpio value set functions
void set_pin(int pin, int value);
void set_all_pins(int value);
int get_pin(int pin);
int get_all_pins();
// clear gpio interrupt
void clear_gpio_int();

#endif