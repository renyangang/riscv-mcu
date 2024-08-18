#include "main.h"
static int gpio_flag = 0;
static int flash_flag = 1;

void exception_handler() {
    return;
}
void int_timer_handler() {
    volatile int* gpio_out = (int*)GPIO_INPUT_ADDR;
    if(flash_flag){
        if(gpio_flag == 0) {
            gpio_flag = 1;
            *gpio_out = *gpio_out | 0x7f;
        }else{
            gpio_flag = 0;
            *gpio_out = *gpio_out & 0x80;
        }
    }else{
        *gpio_out = *gpio_out | 0x7f;
        gpio_flag = 1;
    }
    set_timer_after(800);
    return;
}
void int_peripheral_handler() {
    volatile int* gpio_out = (int*)GPIO_INPUT_ADDR;
    int is_button_pressed = *gpio_out & 0x200;
    if(is_button_pressed) {
        if(flash_flag){
            flash_flag = 0;
        }else{
            flash_flag = 1;
        }
    }
    volatile int* int_clear = (int*)GPIO_INT_CLEAR_ADDR;
    *int_clear = 0x0;
    return;
}

void set_timer_after(int ms) {
    volatile int* ctime = (int*)MTIME_LOW;
    volatile int* cmp_time = (int*)MTIME_CMP_LOW;
    *cmp_time = (*ctime) + ms;
}

// set gpio low 7 pin output, high 3 input
void init_gpio_config() {
    volatile int* gpio_config = (int*)GPIO_CONFIG_ADDR;
    *gpio_config = 0x7F;
    return;
}

int main() {
    init_gpio_config();
    volatile int* gpio_out = (int*)GPIO_INPUT_ADDR;
    *gpio_out = 0x7f;
    set_timer_after(2000);
    set_mie(TIMEER_INT | PERIPHERAL_INT);
    while (1) {
        
    }
    return 0;
}