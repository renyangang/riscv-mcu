MEMORY
{
  /* boot rom */
  FLASH (rwx) : ORIGIN = 0x80000000, LENGTH = 5120K
  /* gpio and so on */
  PERIPHERAL(rwx): ORIGIN = 0xA0000000, LENGTH = 128K
  RAM (rwx) : ORIGIN = 0x2000000, LENGTH = 128K
}

ENTRY(_start)

SECTIONS
{
  . = ALIGN(4);
  .text 0x2000000: {
    . = 0x0;
    . = ALIGN(4);
    *(.starttext)
    . = ALIGN(4);
    _int_begin = .;
    *(.exceptiontext)
    . = ALIGN(4);
    . = (_int_begin + 0x1C);
    *(.timerinttext)
    . = ALIGN(4);
    . = (_int_begin + 0x2C);
    *(.peripheralinttext)
    . = ALIGN(4);
    *(.text)
    _etext = .;
  } > RAM =0x13000000
  .rodata ALIGN(4) : {*(.rodata*)}  > RAM   
	.data ALIGN(4)   : { *(.data) }   > RAM 
	__bss_start = .;    
	.bss ALIGN(4)  : { *(.bss)  *(COMMON) }    > RAM
	__bss_end = .;
}
