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
		* (.text)
	}
	
	. = ALIGN(4);
	.data : { *(.data) }
	
	. = ALIGN(4);
	.mmudata : { *(.mmudata) }
	
	. = ALIGN(4);
	__bss_start = .;
	.bss : { *(.bss) }
	_end = .;
}