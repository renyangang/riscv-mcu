#ifndef GPIO_H
#define GPIO_H

#define GPIO_CONFIG_ADDR 0xA0000000
#define GPIO_DATA_ADDR 0xA0000004
#define GPIO_INT_CLEAR_ADDR 0xA0000008

#define GPIO_INPUT_MODE 0
#define GPIO_OUTPUT_MODE 1

void set_pin_mode(int pin, int mode);
void set_all_pins_mode(int mode);

void set_pin(int pin, int value);
void set_all_pins(int value);
int get_pin(int pin);
int get_all_pins();

void clear_gpio_int();

#endif