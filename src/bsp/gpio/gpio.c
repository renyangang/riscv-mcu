#include "gpio.h"

// set gpio low 7 pin output, high 3 input
void init_gpio_config() {
    volatile int* gpio_config = (int*)GPIO_CONFIG_ADDR;
    *gpio_config = 0x7F;
    return;
}