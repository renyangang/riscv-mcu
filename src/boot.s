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
    addi t4, t4, 2000
    li t3, 0xB0000000
    sw t4, 0(t3)
    la a5,int_handler
    csrrw t2,mtvec,a5
    li t3,0x1808
    csrrw t2,mstatus,t3
    li t3,0x888
    csrrw t2,mie,t3
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

int_handler:
    lw t1, 4(a1)
     # 将低7位取反
    li      a2, 0x7F            # 加载0x7F到a2，0x7F = 0111 1111b (用于掩码)
    and     a2, t1, a2          # 提取a1中的低7位：a2 = a1 & 0x7F
    xori    a2, a2, 0x7F        # 取反低7位：a2 = a2 ^ 0x7F

    # 清除a1的低7位，然后将取反后的值写回a1
    li      t0, -0x80           # t0 = 0xFFFFFF80，用于清除低7位
    and     t1, t1, t0          # 清除a1的低7位：a1 = a1 & 0xFFFFFF80
    or      t1, t1, a2          # 将取反后的低7位合并到a1中
    sw t1, 4(a1)
    li t3, 0xB0000008
    lw t4, 0(t3)
    addi t4, t4, 2000
    li t3, 0xB0000000
    sw t4, 0(t3)
    mret
