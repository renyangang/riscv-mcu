#define MTIME_CMP_LOW 0xB0000000
#define MTIME_CMP_HIGH 0xB0000004
#define MTIME_LOW 0xB0000008
#define MTIME_HIGH 0xB000000C
#define INT_CODE_ADDR 0xB0001000
#define GPIO_CONFIG_ADDR 0xA0000000
#define GPIO_INPUT_ADDR 0xA0000004
#define GPIO_INT_CLEAR_ADDR 0xA0000008

#define TIMEER_INT 0x80
#define PERIPHERAL_INT 0x800
#define SOFT_INT 0x8


void exception_handler();
void int_timer_handler();
void int_peripheral_handler();
void set_timer_after(int ms);
extern void set_mie(int mie);