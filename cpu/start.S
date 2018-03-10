/* Copyright (C) 2017 Lucifer Zhu
 *
 * date: 2018-3-10 12:37:00
 * e-mail: LuciferZhu@yeah.net
 * bootloader for gec210.
 */
 
#include <gec210single.h>
.include "s5p_regs.h"
.include "api.h"


.text
	@ BL1 header info
	.word 0x4000		@indicate BL1 size = 16KB
	.word 0x0
	.word 0x0
	.word 0x0
.global _start
_start:
	b	reset	

/*
 * Below variable is very important because we use MMU in U-Boot.
 * Without it, we cannot run code correctly before MMU is ON.
 * by scsuh.
 */
_TEXT_PHY_BASE:
	.word	CFG_PHY_UBOOT_BASE
	
	
reset:
	/* SVC32 mode, IRQ/FIQ disable */
	msr	cpsr_c, #0xd3		@ (IFTm|mmmm)
	
	ldr	sp, =SVC_STACK		@ configure svc stack pointer

_cpu_init_crit:	
	/*
	 * setup Level 2 cache
	 */
	bl	disable_l2cache
	bl	set_l2cache_auxctrl_cycle
	bl	enable_l2cache
	
       /*
        * Invalidate L1 I/D
        */
        mov	r0, #0                  @ set up for MCR
        mcr	p15, 0, r0, c8, c7, 0   @ invalidate TLBs
        mcr	p15, 0, r0, c7, c5, 0   @ invalidate icache
	
        /*
         * disable MMU stuff and D-caches
         */
        mrc	p15, 0, r0, c1, c0, 0
        bic	r0, r0, #0x00000007     @ clear bits 2:0 (-CAM)
        orr	r0, r0, #0x00000002     @ set bit 1 (--A-) Align
        orr	r0, r0, #0x00000800     @ set bit 12 (Z---) I-cache enable
        mcr 	p15, 0, r0, c1, c0, 0

	/*
	 * Go setup Memory and board specific bits prior to relocation.
	 */
	 
	ldr	fp, =0xD0036400
	sub	sp, fp, #12		@ 4Byte for old pc,lr,sp,fp
	
	bl	lowlevel_init		@ go setup pll,mux,memory,etc.
		
	/* get ready to call C functions */
	ldr	fp, _TEXT_PHY_BASE
	sub	sp, fp , #12
	
	/* when we already run in ram, we do not need to relocate U-Boot.
	 * and actually, memory controller must be configured before U-Boot
	 * is running in ram.
	 */
	ldr	r0, =0xff000fff
	bic	r1, pc, r0		/* r0 <- current base addr of code */
	ldr	r2, =TEXT_BASE		/* r1 <- original base addr in ram */
	bic	r2, r2, r0		/* r0 <- current base addr of code */
	cmp     r1, r2                  /* compare r0, r1                  */
	beq     _after_copy		/* r0 == r1 then skip flash copy   */
	
_relocate:
	adr r0, _start		@ reality work address
	ldr r1, =_start		@ link address
	cmp r0, r1
	beq _after_copy
	
	/* bootloader size:r2 = __bss_start - _start */
	ldr r2, =__bss_start
	subs r2, r2, r1
	
_mmcsd_boot:
	/* @param_0 channel */
	ldr r0, =0
	/* @param_1 u32 StartBlkAddress */
	ldr r1, =1		@ BL1 at block1
	/* @param_2 u16 blockSize */
	lsr r2, #9		@ r2 >>= 9, as r2/=512
	add r2, #1		@ r2 += 1
	/* @param_3 u32* memoryPtr */
	ldr r3, =CFG_PHY_UBOOT_BASE	@ link start address
	/* @param_4 bool with_init */
	ldr r4, =0		@ no init
	push {r4}		@ fourth arg at stack
	
	ldr r4, copy_sd_mmc_to_mem
	mov lr, pc
	ldr pc, [r4]

_after_copy:
	/* print "\na" */
	ldr r0, =rUART0_BASE
	ldr r1, =0x0a
	str r1, [r0, #UTXH_OFFSET]
	ldr r1, =0x61
	str r1, [r0, #UTXH_OFFSET]
	
stack_setup:
	ldr sp, =(CFG_PHY_UBOOT_BASE + CFG_UBOOT_SIZE - 0x1000) @ configure stack into DDR2 sdram, 4KB for malloc, bdinfo
	
_clean_bss:
	ldr r0, =__bss_start
	ldr r1, =_end
	mov r2, #0
_clean_loop:
	str r2, [r0], #4
	cmp r0, r1
	ble _clean_loop
.if 1
_enable_mmu:
	/*  defines the access permission for each of the sixteen memory domains. */
	ldr r0, =0x0000ffff		@ [D0-D7]Manager, [D8-D15]No access
	mcr p15, 0, r0, c3, c0, 0	@ Write Rt to DACR
	
	/* holds the base address of translation table 0. */
	ldr r0, =mmu_table
	mcr p15, 0, r0, c2, c0, 0	@ Write Rt to 32-bit TTBR0
	
	/* enable mmu */
	mrc p15, 0, r0, c1, c0, 0	@ Read SCTLR into Rt
	orr r0, r0, #(1<<0)		@ ---M ,PL1&0 stage 1 MMU enabled
	mcr p15, 0, r0, c1, c0, 0	@ Write Rt to SCTLR
.endif
	ldr pc, start_armboot

	
start_armboot:
	.word main
	
copy_sd_mmc_to_mem:
	.word CopySDMMCtoMem

       .align  5
.global disable_l2cache
disable_l2cache:
	mrc     p15, 0, r0, c1, c0, 1
	bic     r0, r0, #(1<<1)
	mcr     p15, 0, r0, c1, c0, 1
	mov	pc, lr


       .align  5
.global enable_l2cache
enable_l2cache:
	mrc     p15, 0, r0, c1, c0, 1
	orr     r0, r0, #(1<<1)
	mcr     p15, 0, r0, c1, c0, 1
	mov     pc, lr

       .align  5
.global set_l2cache_auxctrl_cycle
set_l2cache_auxctrl_cycle:
	mrc 	p15, 1, r0, c9, c0, 2
	bic 	r0, r0, #(0x1<<29)
	bic 	r0, r0, #(0x1<<21)
	bic 	r0, r0, #(0x7<<6)
	bic 	r0, r0, #(0x7<<0)
	mcr 	p15, 1, r0, c9, c0, 2
	mov     pc,lr
	
.end
