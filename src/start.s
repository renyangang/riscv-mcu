.section .starttext
.global _start
.global set_mie
_start:
    # register interrupts handler
    la a5,int_handler
    addi a5,a5, 0x1
    csrrw t2,mtvec,a5
    # open interrupts
    li t3,0x1808
    csrrw t2,mstatus,t3
    call main

set_mie:
    csrrw t2,mie,a0
    ret

.section .exceptiontext
int_handler:
    # call exception func in c file
    call exception_handler
    mret

.section .timerinttext
timer_handler:
    call int_timer_handler
    mret

.section .peripheralinttext
peripheral_handler:
    call int_peripheral_handler
    mret
