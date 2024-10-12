LD := riscv32-unknown-linux-gnu-ld
AS := riscv32-unknown-linux-gnu-as
CC := riscv32-unknown-linux-gnu-gcc
OBJCOPY := riscv32-unknown-linux-gnu-objcopy
OBJDUMP := riscv32-unknown-linux-gnu-objdump

OBJDIR := ./objs

INCDIRS 		:= examples \
				   bsp/common \
				   bsp/gpio \
				   bsp/interrupt \
				   bsp/uart \
				   bsp/iic \
				   bsp/timer 
				   			   
SRCDIRS			:= . \
				   examples \
				   bsp/common \
				   bsp/gpio \
				   bsp/interrupt \
				   bsp/uart \
				   bsp/iic \
				   bsp/timer 
				   
				   
INCLUDE			:= $(patsubst %, -I %, $(INCDIRS))

SFILES			:= $(foreach dir, $(SRCDIRS), $(wildcard $(dir)/*.S))
CFILES			:= $(foreach dir, $(SRCDIRS), $(wildcard $(dir)/*.c))

SFILENDIR		:= $(notdir  $(SFILES))
CFILENDIR		:= $(notdir  $(CFILES))

SOBJS			:= $(patsubst %, $(OBJDIR)/%, $(SFILENDIR:.S=.o))
COBJS			:= $(patsubst %, $(OBJDIR)/%, $(CFILENDIR:.c=.o))
OBJS			:= $(SOBJS) $(COBJS)

VPATH			:= $(SRCDIRS)

all: boot.bin kernel.bin test.bin

%.bin: $(OBJDIR)/%.elf
	$(OBJCOPY) -O binary -S $^ $@
	
$(OBJDIR)/test.elf: $(OBJDIR)/test.o
	$(LD) -o $@ $^
	$(OBJDUMP) -D $@ > $@.asm

$(OBJDIR)/boot.elf: $(OBJDIR)/boot.o
	$(LD) -T boot.ld -o $@ $^
	$(OBJDUMP) -D $@ > $@.asm
	
$(OBJDIR)/%.o: %.s
	mkdir -p $(OBJDIR)
	$(AS) -march=rv32i -mabi=ilp32 $(INCLUDE) -o $@ $^

$(COBJS) : $(OBJDIR)/%.o: %.c
	mkdir -p $(OBJDIR)
	$(CC) -march=rv32i -mabi=ilp32 -Wall -nostdlib -fno-builtin-memset $(INCLUDE) -c -O2 -o $@ $<

$(OBJDIR)/kernel.elf: $(OBJDIR)/start.o $(COBJS)
	$(LD) -T kernel.ld -o $@ $^
	$(OBJDUMP) -D $@ > $@.asm

.PHONY: clean
clean:
	rm -rf *.bin* *.o *.elf* *.hex objs 