
objs += cpu/start.o cpu/cpu_init.o cpu/lowlevel_init.o cpu/clk.o \
	main.o

ifeq (cpu/config.mk,$(wildcard cpu/config.mk))
	
include cpu/config.mk
	
#CROSS_COMPILE = /usr/local/arm/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
CROSS_COMPILE = /usr/local/arm/arm-4.5.1/bin/arm-linux-
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

LDFLAGS := -Tlink.lds
CPPFLAGS := -nostdinc -nostdlib
CFLAGS := -fno-builtin -Wall -O2 -mfloat-abi=hard -I./include -g

ifneq ($(TEXT_BASE),)
CPPFLAGS += -DTEXT_BASE=$(TEXT_BASE)
LDFLAGS += -Ttext $(TEXT_BASE)
endif

all: start.bin clean
	@echo -e '\033[1;33m$< is ready! \033[0m'

start.bin:$(objs)
	$(LD) $^ -o $(@:%.bin=%.elf) $(LDFLAGS)
	$(OBJCOPY) -O binary -S $(@:%.bin=%.elf) $@
	$(OBJDUMP) -D $(@:%.bin=%.elf) > $(@:%.bin=%.dis)

else	# !cpu/config.mk

all start.bin:
	@echo "System not configured - see README" >&2
	@ exit 1
	
endif	# cpu/config.mk
	
gec210_config:
	echo "TEXT_BASE = 0xc3e00000" > cpu/config.mk
	
%.o:%.S
	$(CC) $< -o $@ -c $(CPPFLAGS) $(CFLAGS)
	
%.o:%.c
	$(CC) $< -o $@ -c $(CPPFLAGS) $(CFLAGS)
	
clean:
	rm -rf *.o
	$(MAKE) clean -C cpu

all_clean:
	rm -rf *.o *.elf *.bin *.dis cpu/config.mk
	$(MAKE) clean -C cpu	

.PHONY:clean all_clean
