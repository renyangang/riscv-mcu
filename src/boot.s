_start:
    // cust flag set instruction code
    .long 0x7F000080
    addi x1, x0, 0x40000000
loop: lb x1, 