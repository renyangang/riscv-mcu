LD := riscv32-unknown-linux-gnu-ld
AS := riscv32-unknown-linux-gnu-as 
CC := riscv32-unknown-linux-gnu-gcc
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump

all: boot.bin

boot.bin: boot.o
	$(LD) -Ttext 0x80000000 -o $@ $^
	$(OBJCOPY) -O binary $@ $@.raw
	$(OBJDUMP) -D $@ > $@.asm

%.o: %.s
	$(AS) -o $@ $^

clean:
	rm -f kernel.bin kernel.o kernel.bin.raw kernel.bin.asm