.global _start
_start:
    # cust flag set instruction code
    .insn 4, 0x8000007F
    # close interrupts
    csrrw t0,mstatus,zero
    # ssd base address
    lui t1, 0x40000
    # offset
    mv t2, zero
    # total 1024 bytes
    addi t3, zero, 0x400
loop:
    lbu t4, 0(t1)
    add t1,t1,t2
    sb t4, 0(t2)
    addi t2, t2, 1
    blt t2, t3, loop
    
    # set boot status
    li t1, 0xC0000100
    csrrw t2,misa, t1
    csrrw t2,mvendorid,zero
    csrrw t2,marchid,zero
    csrrw t2,mimpid,zero
    csrrw t2,mhartid,zero
    li t1,0x1808
    csrrw t2,mstatus,t1
    csrrw t2,mtvec,zero
    csrrw t2,mepc,zero
    csrrw t2,mcause,zero
    csrrw t2,mtval,zero
    csrrw t2,mip,zero
    li t1,0x448
    csrrw t2,mie,t1

    # clear all registers
    li t0, 0
    li t1, 0
    li t2, 0
    li t3, 0
    li t4, 0

main:
    j main
