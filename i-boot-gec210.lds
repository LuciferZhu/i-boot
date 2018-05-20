/*
 * (C) Copyright 2018 Lucifer Zhu <LuciferZhu@yeah.net>
 * date: 2018-4-15 22:19:55
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)
SECTIONS
{
	. = 0x00000000;
	. = ALIGN(4);
	.text : 
	{
		cpu/start.o (.text)
		cpu/lowlevel_init.o (.text)
		cpu/clk.o (.text)
		cpu/cpu_init.o (.text)
		cpu/nand.o (.text)
		* (.text)
	}
	
	.=ALIGN(4);
	.rodata : { *(.rodata) }

	. = ALIGN(4);
	.data : { *(.data) }
	
	. = ALIGN(4);
	.mmudata : { *(.mmudata) }
	
	. = ALIGN(4);
	__bss_start = .;
	.bss : { *(.bss) }
	_end = .;
}