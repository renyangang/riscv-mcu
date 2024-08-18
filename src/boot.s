.section .text
.global _start
_start:
    # cust flag set instruction code
    .insn 4, 0x8000007F
    # close interrupts
    csrrw t0,mstatus,zero
    addi t1, zero, 0b0001111111
    li a1, 0xA0000000
    sw t1, 0(a1)
    li t3, 0xB0000008
    lw t4, 0(t3)
    addi t4, t4, 0x7D0
    li t3, 0xB0000000
    sw t4, 0(t3)
    la a5,int_handler
    addi a5,a5, 0x1
    csrrw t2,mtvec,a5
    li t3,0x1808
    csrrw t2,mstatus,t3
    li t3,0x888
    csrrw t2,mie,t3
    mv s0,zero
    # ssd base address
#     lui t1, 0x40000
#     # offset
#     mv t2, zero
#     # total 1024 bytes
#     addi t3, zero, 0x400
# loop:
#     lbu t4, 0(t1)
#     add t1,t1,t2
#     sb t4, 0(t2)
#     addi t2, t2, 1
#     blt t2, t3, loop
    
#     # set boot status
#     li t1, 0xC0000100
#     csrrw t2,misa, t1
#     csrrw t2,mvendorid,zero
#     csrrw t2,marchid,zero
#     csrrw t2,mimpid,zero
#     csrrw t2,mhartid,zero
#     li t1,0x1808
#     csrrw t2,mstatus,t1
#     csrrw t2,mtvec,zero
#     csrrw t2,mepc,zero
#     csrrw t2,mcause,zero
#     csrrw t2,mtval,zero
#     csrrw t2,mip,zero
#     li t1,0x448
#     csrrw t2,mie,t1

#     # clear all registers
#     li t0, 0
#     li t1, 0
#     li t2, 0
#     li t3, 0
#     li t4, 0
main:
    j main

.section .exceptiontext
int_handler:
    nop

.section .timerinttext
timer_handler:
    j timer_func

.section .peripheralinttext
peripheral_handler:
    li t5, 0xA0000004
    lw s3, 0(t5)
    andi s3,s3,0b001000000000
    beq s3, zero, clearint
    addi s0, s0, 1
clearint:
    sw zero, 4(t5)
    mret

timer_func:
    and t0, s0, 0x1
    bnez t0, delay
    addi s1,s1,1
    lw t1, 4(a1)
    and t0, s1, 0x1
    bnez t0, close
open:
    ori t1, t1, 0b1111111
    j save
close:
    andi t1, t1, 0b1110000000 
save:
    sw t1, 4(a1)
delay:
    # set timer after 500ms
    li t3, 0xB0000000
    lw t4, 8(t3)
    addi t4, t4, 0x2E8
    sw t4, 0(t3)
    mret
