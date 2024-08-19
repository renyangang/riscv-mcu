#include "gpio.h"
#include "timer.h"
#include "interrupt.h"

int main() {
    init_gpio_config();
    volatile int* gpio_out = (int*)GPIO_INPUT_ADDR;
    *gpio_out = 0x7f;
    while (1) {
        
    }
    return 0;
}