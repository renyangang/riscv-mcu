MEMORY
{
  /* boot rom */
  FLASH (rwx) : ORIGIN = 0x00000000, LENGTH = 5120K
  /* gpio and so on */
  PERIPHERAL(rwx): ORIGIN = 0xA0000000, LENGTH = 128K
  RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 128K
}

ENTRY(_start)

SECTIONS
{
  . = ALIGN(4);
  .text 0x00000000: {
    *(.text)
    _etext = .;
  } > FLASH
}
