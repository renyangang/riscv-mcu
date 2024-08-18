LD := riscv32-unknown-linux-gnu-ld
AS := riscv32-unknown-linux-gnu-as
CC := riscv32-unknown-linux-gnu-gcc
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump

all: boot.bin kernel.bin

%.bin: %.elf
	$(OBJCOPY) -O binary --gap-fill 0 -S $^ $@
	
boot.elf: boot.o
	$(LD) -T boot.ld -o $@ $^
	$(OBJDUMP) -D $@ > $@.asm
	
%.o: %.s
	$(AS) -march=rv32im -mabi=ilp32 -o $@ $^

%.o: %.c
	$(CC) -march=rv32im -mabi=ilp32 -Wall -nostdlib -c -O2 -o $@ $<

kernel.elf: start.o main.o
	$(LD) -T kernel.ld -o $@ $^
	$(OBJDUMP) -D $@ > $@.asm

clean:
	rm -f *.bin* *.o *.elf* *.hex