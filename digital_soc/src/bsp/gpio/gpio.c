#include "gpio.h"

void set_pin_mode(int pin, int mode) {
    if(mode) {
        *(int*)GPIO_CONFIG_ADDR = *(int*)GPIO_CONFIG_ADDR | (mode << (pin - 1));
    } else {
        *(int*)GPIO_CONFIG_ADDR = *(int*)GPIO_CONFIG_ADDR & ~(mode << (pin - 1));
    }
}

void set_all_pins_mode(int mode) {
    *(int*)GPIO_CONFIG_ADDR = mode;
}

void set_pin(int pin, int value) {
    if(value) {
        *(int*)GPIO_SET_ADDR = *(int*)GPIO_READ_ADDR | (1 << (pin - 1));
    } else {
        *(int*)GPIO_SET_ADDR = *(int*)GPIO_READ_ADDR & ~(1 << (pin - 1));
    }
}

void set_all_pins(int value) {
    *(int*)GPIO_SET_ADDR = value;
}

int get_all_pins() {
    return *(int*)GPIO_READ_ADDR;
}

int get_pin(int pin) {
    return *(int*)GPIO_READ_ADDR & (1 << (pin - 1));
}

void clear_gpio_int() {
    *(int*)GPIO_INT_CLEAR_ADDR = 0;
}