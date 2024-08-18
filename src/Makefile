LD := riscv32-unknown-linux-gnu-ld
AS := riscv32-unknown-linux-gnu-as
CC := riscv32-unknown-linux-gnu-gcc
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump

all: boot.bin

boot.bin: boot.elf
	$(OBJCOPY) -O binary --gap-fill 0 -S $^ $@
	
boot.elf: boot.o
	$(LD) -T boot.ld -o $@ $^
	$(OBJDUMP) -D $@ > $@.asm
	
%.o: %.s
	$(AS) -o $@ $^

clean:
	rm -f *.bin* *.o *.elf* *.hex