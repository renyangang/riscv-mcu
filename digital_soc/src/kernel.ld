MEMORY
{
  /* boot rom */
  FLASH (rwx) : ORIGIN = 0x00000000, LENGTH = 5120K
  /* gpio and so on */
  PERIPHERAL(rwx): ORIGIN = 0xC0000000, LENGTH = 128K
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 128K
}

ENTRY(_start)

SECTIONS
{
  . = ALIGN(4);
  .text 0x00000000: {
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
  } > FLASH
  .rodata ALIGN(4) : {*(.rodata*)}  > FLASH
  . = ALIGN(4);  
	.data 0x10000000   : { *(.data) }   > RAM 
	__bss_start = .;    
	.bss ALIGN(4)  : { *(.bss)  *(COMMON) }    > RAM
	__bss_end = .;
}
