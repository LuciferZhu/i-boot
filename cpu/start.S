/* Copyright (C) 2017 Lucifer Zhu
 *
 * date: 2018-3-10 12:37:00
 * e-mail: LuciferZhu@yeah.net
 * bootloader for gec210.
 */
 
#include <gec210single.h>
#include "s5pc110.h"
.include "s5p_regs.h"
.include "api.h"


.text
	@ BL1 header info
	.word 0x2000		@indicate BL1 size = 8KB
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

        /* Read booting information */
        ldr	r0, =PRO_ID_BASE
        ldr	r1, [r0,#OMR_OFFSET]
        bic	r2, r1, #0xffffffc1
	
	/* NAND BOOT */
	cmp	r2, #0x0		@ eSSD
	moveq	r3, #BOOT_NAND
	cmp	r2, #0x2		@ 2KB 5-cycle	8-bit ECC
	moveq	r3, #BOOT_NAND
	cmp	r2, #0x4		@ 4KB 5-cycle	8-bit ECC
	moveq	r3, #BOOT_NAND
	cmp	r2, #0x6		@ 4KB 5-cycle	16-bit ECC
	moveq	r3, #BOOT_NAND
	cmp	r2, #0x8		@ OneNAND Mux
	moveq	r3, #BOOT_ONENAND
	/* SD/MMC BOOT */
	cmp     r2, #0xc
	moveq   r3, #BOOT_MMCSD	
	/* NOR BOOT */
	cmp     r2, #0x14
	moveq   r3, #BOOT_NOR	
	/* Uart BOOTONG failed */
	cmp     r2, #(0x1<<4)
	moveq   r3, #BOOT_SEC_DEV
	
	ldr	r0, =INF_REG_BASE
	str	r3, [r0, #INF_REG3_OFFSET]	@ save into inform3 register
	
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
	/* bootloader size:r2 = __bss_start - _start + 16 */
	ldr	r1, =_start-16		@ link address
	ldr	r2, =__bss_start
	subs 	r2, r2, r1	
	/*
	 * boot from specific device.
	 */
	ldr	r0, =INF_REG_BASE
	ldr	r1, [r0, #INF_REG3_OFFSET]
	cmp	r1, #BOOT_NAND		/* 0x0 => boot device is nand */
	beq	nand_boot
	cmp     r1, #BOOT_MMCSD
	beq     mmcsd_boot
	cmp     r1, #BOOT_SEC_DEV
	beq     mmcsd_boot
	b	boot_failed
	
nand_boot:
#if 0
	ldr	r0, =CFG_PHY_UBOOT_BASE
	add	r3, r2, r0		@ r3 indicated BL2 ending address
	/* @param_0 uint32 Source block address number */
	ldr	r0, =0
	/* @param_1 uint32 Source page address number to copy */
	ldr	r1, =0
	/* @param_2  uint8* Target Buffer pointer */
	ldr	r2, =CFG_PHY_UBOOT_BASE
_copy_nand_loop:
	push	{r0, r1, r2, r3}
	ldr	r4, copy_nand_to_mem
	mov	lr, pc
	ldr	pc, [r4]
	pop	{r0, r1, r2, r3}
	add	r1, #1
	cmp	r1, #64
	moveq	r1, #0
	addeq	r0, #1
	add	r2, r2, #(1<<11)	@ r2 += 2kB/page
	cmp	r2, r3
	blt	_copy_nand_loop		@ Target Buffer pointer less than BL2 ending address.
#else
	ldr	r0, =0x7ff
	add	r2, r0			@ r2 += 2047,
	bic	r2, r0			@ len align 2kB
	ldr	r0, =0			@ nand addr
	ldr	r1, =CFG_PHY_UBOOT_BASE	@ buff addr
	bl	nand_read
#endif
	b	_after_copy
	
mmcsd_boot:
	/* @param_0 channel */
	ldr	r0, =0
	/* @param_1 u32 StartBlkAddress */
	ldr	r1, =49		@ BL1 at block1,BL2 at block49
	/* @param_2 u16 blockSize */
	lsr	r2, #9		@ r2 >>= 9, as r2/=512
	add	r2, #1		@ r2 += 1
	/* @param_3 u32* memoryPtr */
	ldr	r3, =CFG_PHY_UBOOT_BASE	@ link start address
	/* @param_4 bool with_init */
	ldr	r4, =0		@ no init
	push	{r4}		@ fourth arg at stack
	
	ldr	r4, copy_sd_mmc_to_mem
	mov	lr, pc
	ldr	pc, [r4]
	b	_after_copy
	
_after_copy:
#ifdef CONFIG_ENABLE_MMU
_enable_mmu:
	/*  defines the access permission for each of the sixteen memory domains. */
	ldr	r0, =0x0000ffff		@ [D0-D7]Manager, [D8-D15]No access
	mcr	p15, 0, r0, c3, c0, 0	@ Write Rt to DACR
	
	/* holds the base address of translation table 0. */
	ldr	r0, _mmu_table_base
	ldr	r1, =0xfff00000
	ldr	r2, =CFG_PHY_UBOOT_BASE
	bic	r0, r0, r1
	orr	r0, r0, r2
	mcr	p15, 0, r0, c2, c0, 0	@ Write Rt to 32-bit TTBR0
	
	/* enable mmu */
	mrc	p15, 0, r0, c1, c0, 0	@ Read SCTLR into Rt
	orr	r0, r0, #(1<<0)		@ ---M ,PL1&0 stage 1 MMU enabled
	mcr	p15, 0, r0, c1, c0, 0	@ Write Rt to SCTLR
	nop
	nop
	nop
	nop
#endif

stack_setup:
	ldr	fp, =(CFG_UBOOT_BASE + CFG_UBOOT_SIZE - 0x1000) @ configure stack into DDR2 sdram, 4KB for malloc, bdinfo
	sub	sp, fp, #12
	
_clean_bss:
	ldr r0, =__bss_start
	ldr r1, =_end
	mov r2, #0
_clean_loop:
	str r2, [r0], #4
	cmp r0, r1
	ble _clean_loop
	
	ldr pc, _start_armboot		@ jump to BL2

	
_start_armboot:
	.word start_armboot

_mmu_table_base:
	.word mmu_table	
	
copy_sd_mmc_to_mem:
	.word CopySDMMCtoMem

copy_nand_to_mem:
	.word NF8_ReadPage_Adv
	
boot_failed:
	nop			/* boot from specific device failed */
	b	boot_failed
	
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
