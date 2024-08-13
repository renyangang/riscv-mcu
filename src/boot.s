_start:
    // cust flag set instruction code
    .long 0x7F000080
    addi x1, x0, 0x40000000  // ssd base address
    mv x2, x0 // offset
    addi x3, x0, 0x080000  // total 512k bytes
loop: 
    lbu x4, x1, x2
    sb x4, x0, x2
    addi x2, x2, 1
    blt x2, x3, loop
    
    // clear all registers
    li x1 0
    li x2 0
    li x3 0
    li x4 0

main:
    j main