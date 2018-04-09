/*
 * (C) Copyright 2018 Lucifer Zhu <LuciferZhu@yeah.net>
 * date: 2018-4-6 14:15:18
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


void start_armboot (void)
{
	int i;
	char *image = (char *)CFG_ADDR_IMAGE;

	printf("\n\n%s[%d] in\n", __func__, __LINE__);

	__asm__ __volatile__("":::"memory");

	/* 
	 * load image into DDR.
	 */
	printf("Load image from nand flash...");
	nand_read (CFG_IMAGE_FROM, image, CFG_IMAGE_SIZE);
	printf("finish!\n");

	for(i=0; i<64; i++)
		printf("%02X ",image[i]);
	
	printf("\n");

	/* 
	 * setup any tag.
	 */
	
	while(1)
	{
		if (tstc ())
			putc ((char)getc());
	}

	for(;;);
}

