.section .text
.global _start
_start:
    li x1, 0x1
    li x2, 0x2
b0:
    add x3, x1, x2
    li x4, 0x3
    # bne x3, x0, b0
    # beq x3, x0, b0
    # beq x3, x0, b1
    # bne x3, x0, b1
    # j b1
    lw x9, 68(x0)
    lw x10, 72(x0)
    li x5, 0x5
    addi x11, x3, 0x1
    # addi x10, x9, 0x1
    li x6, 0x6
    li x7, 0x7
b1:
    li x8, 0x8
    li x12, 12
    li x13, 13
    li x14, 14

d0:
    .rept 10
    .long 0x1
    .endr

.end