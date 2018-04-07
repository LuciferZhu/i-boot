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


void start_armboot (void)
{
	__asm__ __volatile__("":::"memory");

	printf("\n\n%s[%d] in", __func__, __LINE__);
	while(1)
	{
		if (tstc ())
			putc ((char)getc());
	}

}

