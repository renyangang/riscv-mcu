#ifndef GPIO_H
#define GPIO_H

#define GPIO_CONFIG_ADDR 0xA0000000
#define GPIO_INPUT_ADDR 0xA0000004
#define GPIO_INT_CLEAR_ADDR 0xA0000008

void init_gpio_config();

#endif