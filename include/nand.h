/*
 * (C) Copyright 2018 Lucifer Zhu <LuciferZhu@yeah.net>
 * date: 2018-4-8 22:19:03
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
#ifndef _NAND_H_
#define _NAND_H_


extern void nand_init (void);

extern void nand_read_id (char *buff);

extern unsigned long nand_read (unsigned int addr,char *buf,unsigned int len);
 
extern int nand_write (unsigned int addr,char *buf,unsigned int len);
 
 /* erase basis block(128KB) */
extern int nand_block_erase (unsigned int addr);
 
extern void nand_test (void);
 
 
#endif

