#
# (C) Copyright 2018
# Lucifer Zhu, LuciferZhu@yeah.net.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundatio; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#
objs += cpu/start.o cpu/cpu_init.o cpu/lowlevel_init.o cpu/clk.o \
	cpu/serial.o lib/board.o lib_generic/string.o lib_generic/vsprintf.o \
	common/console.o lib_generic/ctype.o cpu/nand.o common/main.o \
	common/image.o

#########################################################################
ifeq (cpu/config.mk,$(wildcard cpu/config.mk))
	
include cpu/config.mk

#
# Make variables (CC, etc...)
#
#CROSS_COMPILE = /usr/local/arm/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-
CROSS_COMPILE = /usr/local/arm/arm-4.5.1/bin/arm-linux-
CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy
OBJDUMP := $(CROSS_COMPILE)objdump

gccincdir := $(shell $(CC) -print-file-name=include)
DBGFLAGS = -g -DDEBUG

LDFLAGS := -Ti-boot-gec210.lds
CPPFLAGS := -ffreestanding -fno-builtin -nostdinc -isystem $(gccincdir) -I./include \
		-O2 -mfloat-abi=softfp $(DBGFLAGS) -D__KERNEL__
OBJCFLAGS := --gap-fill=0xff

ifneq ($(TEXT_BASE),)
CPPFLAGS += -DTEXT_BASE=$(TEXT_BASE)
LDFLAGS += -Ttext $(TEXT_BASE)
endif

CFLAGS := -Wall -Wstrict-prototypes $(CPPFLAGS)
AFLAGS := -D__ASSEMBLY__ $(CPPFLAGS)

# use math calculate which should link libgcc.a
PLATFORM_LIBS := -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc

# make the rule for the default target.
all: start.bin clean
	@echo -e '\033[1;33m$< is ready! \033[0m'

start.bin:$(objs)
	$(LD) $^ -o $(@:%.bin=%.elf) $(LDFLAGS) $(PLATFORM_LIBS)
	$(OBJCOPY) $(OBJCFLAGS) -O binary -S $(@:%.bin=%.elf) $@
	$(OBJDUMP) -D $(@:%.bin=%.elf) > $(@:%.bin=%.dis)

else	# !cpu/config.mk

all start.bin:
	@echo "System not configured - see README" >&2
	@ exit 1
	
endif	# cpu/config.mk
#########################################################################

#
# configuration's rule
#
gec210_config:
	echo "TEXT_BASE = 0xc3e00000" > cpu/config.mk
	
#
# make the rule for general target
#
%.o:%.S
	$(CC) $< -o $@ -c $(AFLAGS)
	
%.o:%.c
	$(CC) $< -o $@ -c $(CFLAGS)
	
clean:
	rm -rf *.o
	$(MAKE) clean -C cpu	
	$(MAKE) clean -C lib
	$(MAKE) clean -C lib_generic
	$(MAKE) clean -C common

all_clean:
	rm -rf *.o *.elf *.bin *.dis cpu/config.mk
	$(MAKE) clean -C cpu	
	$(MAKE) clean -C lib
	$(MAKE) clean -C lib_generic
	$(MAKE) clean -C common	
	
.PHONY:clean all_clean
	