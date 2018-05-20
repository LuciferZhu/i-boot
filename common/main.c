/*
 * (C) Copyright 2018 Lucifer Zhu <LuciferZhu@yeah.net>
 * date: 2018-4-10 21:44:25
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

#include <common.h>
#include "nand.h"


static struct tag *param;


static image_header_t *image_get_kernel (ulong img_addr, int verify)
{
	image_header_t *hdr = (image_header_t *)img_addr;

	if (!image_check_hcrc (hdr)) {
		puts ("Bad Header Checksum\n");
		return NULL;
	}

	image_print_contents (hdr);

	if (verify) {
		puts ("   Verifying Checksum ... ");
		if (!image_check_dcrc (hdr)) {
			printf ("Bad Data CRC\n");
			return NULL;
		}
		puts ("OK\n");
	}

	return hdr;
}


void setup_start_tag (void)
{
	debug("%s[%d] in\n", __func__, __LINE__);
	
	param = (struct tag *)CFG_BOOT_PARAMS;

	param->hdr.tag = ATAG_CORE;
	param->hdr.size = tag_size(tag_core);

	param->u.core.flags = 0;
	param->u.core.pagesize = 0;
	param->u.core.rootdev = 0;

	param = tag_next (param);
}


void setup_mem_tag (void)
{
	debug("%s[%d] in\n", __func__, __LINE__);

	param->hdr.tag = ATAG_MEM;
	param->hdr.size = tag_size(tag_mem32);

	param->u.mem.start = PHYS_SDRAM_1;
	param->u.mem.size = PHYS_SDRAM_1_SIZE;

	param = tag_next (param);


	param->hdr.tag = ATAG_MEM;
	param->hdr.size = tag_size(tag_mem32);

	param->u.mem.start = PHYS_SDRAM_2;
	param->u.mem.size = PHYS_SDRAM_2_SIZE;

	param = tag_next (param);

}


void setup_cmdline_tag (char * cml)
{
	int len = strlen(cml) + 1;

	debug("%s[%d] in\n", __func__, __LINE__);

	param->hdr.tag = ATAG_CMDLINE;
	param->hdr.size = ((sizeof(struct tag_header) + len+3) >> 2);
	
	strncpy(param->u.cmdline.cmdline , cml, len);

	param = tag_next (param);
}


void setup_mtdpart_tag (void)
{
	debug("%s[%d] in\n", __func__, __LINE__);

	param->hdr.tag = ATAG_MTDPART;
	param->hdr.size = tag_size(tag_mtdpart);

	param->u.mtdpart_info.mtd_part_size[0] = 0x80000;	// uboot,512kB
	param->u.mtdpart_info.mtd_part_size[1] = 0x400000;	
	param->u.mtdpart_info.mtd_part_size[2] = 0x3000000;
	param = tag_next (param);
}


void setup_end_tag (void)
{
	debug("%s[%d] in\n", __func__, __LINE__);

	param->hdr.tag = ATAG_NONE;
	param->hdr.size = 0;

	debug("%s[%d] param=0x%p\n", __func__, __LINE__, param);
}


void cleanup_for_linux (void)
{
	unsigned long i, temp;

	debug("%s[%d] in\n", __func__, __LINE__);

	/* disable IRQ/FIQ */
	__asm__ __volatile__(
		"mrs %0, cpsr\n" 
		"orr %1, %0, #0xc0\n"
		"msr cpsr_c, %1"
		: "=r"(i) , "=r"(temp)
		:: "memory"
	);

	/* turn-off I/D cache */
	__asm__ __volatile__("mrc p15, 0, %0, c1, c0, 0" :"=r"(i) :);
	i &= ~((1<<2) | (1<<12));
	__asm__ __volatile__("mcr p15, 0, %0, c1, c0, 0" : :"r"(i));

	i = 0;
	/* flush(invaildate) I-cache */
	__asm__ __volatile__("mcr p15, 0, %0, c7, c5, 0" : :"r"(i));
	
	/* data Synchronization barrier to sync up things */
	__asm__ __volatile__("mcr p15, 0, %0, c7, c10, 4": :"r"(i));

	/* instruction barrier */
	i = 0;
	__asm__ __volatile__("mcr p15, 0, %0, c7, c5, 4": :"r"(i));

}


void do_bootm_linux (unsigned long *image)
{
	void (*theKernel)(int zero, int machid, ulong params);
	uint32_t ep = image_get_ep((image_header_t *)image);
	
	theKernel = (void (*)(int,int,ulong))ep;
	debug ("## Transferring control to Linux (at address 0x%08lx) ...\n",
	       (ulong) theKernel);

	/* 
	 * setup any tag.
	 */
	setup_start_tag ();
	setup_mem_tag();
	setup_cmdline_tag (CONFIG_BOOTARGS);
	setup_mtdpart_tag();
	setup_end_tag();

	printf("\nStarting kernel...\n\n");

	cleanup_for_linux();

	theKernel(0, MACH_TYPE, CFG_BOOT_PARAMS);

	/* It shouldn't run below code. */
	puts("boot linux failed!\n");

	return;
}


void hang (void)
{
	puts ("### ERROR ### Please RESET the board ###\n");
	for (;;);
}


void main_loop (void)
{
	int i, j;
	ulong ret;
	char *image = (char *)CFG_PHY_KERNEL_BASE;

	debug("%s[%d] in\n", __func__, __LINE__);

	/* 
	 * load image into DDR.
	 */
	printf("Load image from nand flash...");
	ret = nand_read (CFG_IMAGE_FROM, image, CFG_IMAGE_SIZE);
	printf("%ld Bytes!\n", ret);

	for(i=0; i<16; i++) {
		debug("%08lx: ", (ulong)image + i*16);
		for (j = 0; j < 4; j++)
			debug("%08lx ",((ulong*)image)[i*4+j]);
		
		debug("\n");
	}

	if (!image_get_kernel ((ulong)image, 1))
		hang();

	do_bootm_linux ((ulong *)image);
	
	while(1)
	{
		if (tstc ())
			putc ((char)getc());
	}

	for(;;);

}
