/* Copyright (C) 2017 Lucifer Zhu
 *
 * date: 2018-1-28 23:52:02
 * e-mail: LuciferZhu@yeah.net
 * soc low level hardware init.
 */

.include "s5p_regs.h"
.include "api.h"
#include "s5pc110.h"


.text
.global lowlevel_init
lowlevel_init:
	push	{lr}

	/* IO Retention release */
	ldr	r0, =(ELFIN_CLOCK_POWER_BASE + OTHERS_OFFSET)	@ 0xE010_E000
	ldr	r1, [r0]
	ldr	r2, =IO_RET_REL		@ ((1 << 31) | (1 << 29) | (1 << 28))
	orr	r1, r1, r2
	str	r1, [r0]
	
	/* disable watchdog */
	ldr	r0, =rWTCON
	ldr	r1, =0x0
	str	r1, [r0]
	
	/* when we already run in ram, we do not need to relocate U-Boot.
	 * and actually, memory controller must be configured before U-Boot
	 * is running in ram.
	 */
	ldr	r0, =0xff000fff
	bic	r1, pc, r0		/* r0 <- current base addr of code */
	ldr	r2, =TEXT_BASE		/* r1 <- original base addr in ram */
	bic	r2, r2, r0		/* r0 <- current base addr of code */
	cmp     r1, r2                  /* compare r0, r1                  */
	beq     1f			/* r0 == r1 then skip flash copy   */
	
	bl	CMU_init		@ init system clock
	
	bl	mem_ctrl_asm_init	@ Memory initialize
1:	
	bl	uart_asm_init
	
	bl	tzpc_init
	
	/* simple init nand */
	bl	nand_asm_init
	
	/* print "K" */
	ldr 	r0, =rUART0_BASE
	ldr 	r1, =0x4b
	str 	r1, [r0, #UTXH_OFFSET]
	
	pop 	{pc}


uart_asm_init:
	/* uart0 gpio setup */
	ldr 	r0, =rGPA0CON
	ldr 	r1, [r0]
	bic 	r1, #0xff
	orr 	r1, #0x22
	str 	r1, [r0]
	
	ldr 	r0, =rUART0_BASE
	
	ldr 	r1, =0x00000003		@ No parityNo parity, No parity, 8-bit
	str 	r1, [r0, #ULCON_OFFSET]
	
	ldr 	r1, =0x00000305		@  PCLK, Level, Interrupt request or polling mode
	str 	r1, [r0, #UCON_OFFSET]
	
	ldr 	r1, =0x00000001		@ [trigger level] Tx FIFO-0 byte, Rx FIFO-32 byte,fifo en
	str 	r1, [r0, #UFCON_OFFSET]

	ldr 	r1, =0			@ disable Auto Flow Control 
	str 	r1, [r0, #UMCON_OFFSET]

	/* 
	 * baudrate=115200
	 * DIV_VAL = (660000000 / (115200 x 16)) -1 = 34.8
	 * UBRDIVn = 34 ( integer part of DIV_VAL )
	 * (num of 1's in UDIVSLOTn)/16 = 0.8, (num of 1's in UDIVSLOTn) = 13, UDIVSLOT=0xDFDD
	 */
	ldr 	r1, =34
	str 	r1, [r0, #UBRDIV_OFFSET]
	ldr 	r1, =0xDFDD
	str 	r1, [r0, #UDIVSLOT_OFFSET]
	
	ldr 	r1, =0x0f	
	str 	r1, [r0, #UINTM_OFFSET]	@ disable all uart interrupt
	
	/* print "O" */
	ldr 	r1, =0x4f
	str 	r1, [r0, #UTXH_OFFSET]

	bx 	lr
	

/*
 * Setting TZPC[TrustZone Protection Controller] to memory as non-secure
 */
tzpc_init:	
	ldr	r0, =ELFIN_TZPC0_BASE
	mov 	r1, #0x0
	str	r1, [r0]
	mov	r1, #0xff
	str	r1, [r0,#TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0,#TZPC_DECPROT1SET_OFFSET]
	
	ldr	r0, =ELFIN_TZPC1_BASE
	str	r1, [r0,#TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0,#TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0,#TZPC_DECPROT2SET_OFFSET]
	
	ldr	r0, =ELFIN_TZPC2_BASE
	str	r1, [r0,#TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0,#TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0,#TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0,#TZPC_DECPROT3SET_OFFSET]
	
	ldr	r0, =ELFIN_TZPC3_BASE
	str	r1, [r0,#TZPC_DECPROT0SET_OFFSET]

	mov	pc, lr
	

nand_asm_init:
	ldr	r0, =ELFIN_GPIO_BASE
	/* pin CSn2 */
	ldr	r1, [r0,#MP01CON_OFFSET]
	bic	r1, r1, #(0xf<<8)
	orr	r1, r1, #(0x3<<8)
	str	r1, [r0,#MP01CON_OFFSET]
	
	/* pin CLE, ALE, WE, RE, RnB */
	ldr	r1, [r0,#MP03CON_OFFSET]
	ldr	r2, =0xFFFFF
	bic	r1, r1, r2
	ldr	r2, =0x22222
	orr	r1, r1, r2
	str	r1, [r0,#MP03CON_OFFSET]
	
	/* pin DATA[15:0] */
	ldr	r1, =0x22222222
	str	r1, [r0,#MP06CON_OFFSET]
	
	/*
	 *  [1]: When page size is 2K ,5 address cycle
	 */
	ldr	r0, =ELFIN_NAND_BASE
	ldr	r1, =0x00800202			@ (1<<23) | (0<<12) | (2<<8) | (0<<4) | (1<<1)
	str	r1, [r0,#NFCONF_OFFSET]
	
	ldr	r1, =0x3			@ (0<<8) | (1<<1) | (1<<0)
	str	r1, [r0,#NFCONT_OFFSET]
	 
	mov	pc, lr


	/* first-level section descriptor entry. */
.macro FL_SECTION_ENTRY base,ap,d,c,b
	.word (\base<<20) | (\ap<<10) | (\d<<5) | \
		(1<<4) | (\c<<3) | (\b<<2) | (1<<1)
.endm
	
.section .mmudata, "a"
	.align 14
	/* alignment 2^14=16K bytes. */
	.global mmu_table
mmu_table:
#if 1
	.set __base,0
	// Access for iRAM
	.rept 0x100
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	// Not Allowed
	.rept 0x200 - 0x100
	.word 0x00000000
	.endr

	.set __base,0x200
	// should be accessed
	.rept 0x600 - 0x200
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	.rept 0x800 - 0x600
	.word 0x00000000
	.endr

	.set __base,0x800
	// should be accessed
	.rept 0xb00 - 0x800
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	.set __base,0xB00
	.rept 0xc00 - 0xb00
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	.set __base,0x300               //(2016-10-14朱相东修改)
	// 256MB for SDRAM with cacheable
	.rept 0xD00 - 0xC00
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr
	
	.set __base,0xD00
	// 1:1 mapping for debugging with non-cacheable
	.rept 0x1000 - 0xD00
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr	
#else
	.set __base, 0x000
	.rept 0x600
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base, __base+1
	.endr

	.set __base, 0xe00
	.rept 0x800 - 0x600
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base, __base+1
	.endr

	.set __base, 0x800
	.rept 0xe00 - 0x800
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base, __base+1
	.endr

	.set __base, 0xe00
	.rept 0x1000 - 0xe00
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base, __base+1
	.endr
#endif
.end