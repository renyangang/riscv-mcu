.global _start
_start:
    # cust flag set instruction code
    .insn 4, 0x8000007F
    # ssd base address
    lui x1, 0x1000
    # offset
    mv x2, x0
    # total 512k bytes
    lui x3, 0x80
loop:
    lbu x4, 0(x1)
    add x1,x1,x2
    sb x4, 0(x2)
    addi x2, x2, 1
    blt x2, x3, loop
    
    # clear all registers
    li x1, 0
    li x2, 0
    li x3, 0
    li x4, 0

main:
    j main
