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

#include "s5pc110.h"


#define EN_NF0()			( NFCONT_REG &= ~(1<<1) )
#define DIS_NF0()			( NFCONT_REG |= (1<<1) )
#define IS_READY_NF0()			( NFSTAT_REG & 0x1 )
#define PAGE_SIZE			(2048)

/* K9K8G08U1A */
void nand_init(void)
{
	/* pin CSn2 */
	MP01CON_REG &= ~(0xf<<8);
	MP01CON_REG |= (0x3<<8);
	/* pin CLE, ALE, WE, RE, RnB */
	MP03CON_REG &= ~0xfffff;
	MP03CON_REG |= 0x22222;
	/* pin DATA[15:0] */
	MP06CON_REG = 0x22222222;
	
	/*
	 *  [1]: When page size is 2K ,5 address cycle
	 */
	NFCONF_REG = (1<<23) | (0<<12) | (2<<8) | (0<<4) | (1<<1);
	
	NFCONT_REG = (0<<8) | (0<<1) | (1<<0);
	
	DIS_NF0();
}


void nand_read_id (char *buff)
{
	volatile int i;
	
	EN_NF0();
	
	NFCMD_REG = 0x90;
	
	NFADDR_REG = 0x00;

	while( !IS_READY_NF0() );
	
	for (i=0; i<5; i++)
		buff[i] = NFDATA8_REG;

	DIS_NF0();
}


void nand_read_buf (unsigned long addr, char *buf,unsigned long len)
{
	unsigned long i, col, row;
	EN_NF0();
	
	NFCMD_REG = 0x00;

	col = addr & 0x7ff;			/* "addr & 0x7ff" -> addr%2048 */
	row = addr>>11;				/* "addr>>11" -> addr/2048 */
	
	/* column addr */
	NFADDR_REG = col & 0xff;
	NFADDR_REG = col >> 8;

	/* row(page) addr */
	NFADDR_REG = row & 0xff;
	NFADDR_REG = row >> 8 & 0xff;
	NFADDR_REG = row >> 16 & 0x7;
	
	NFCMD_REG = 0x30;
	
	while( !IS_READY_NF0() );

	if (col || len & (PAGE_SIZE-1) || ((ulong)buf) & 3) {
		for(i=0; i<len; i++)
			buf[i] = NFDATA8_REG;
	} else {
		for(i=0; i<len/sizeof(ulong); i++) {
			((ulong*)buf)[i] = NFDATA_REG;	// pick up speed
		}
	}
		
	DIS_NF0();
}


/* read page align 2kB */
unsigned long nand_read (unsigned long addr, char *buf, unsigned long len)
{
	unsigned long i = 0;

	if (addr & (PAGE_SIZE-1) || len & (PAGE_SIZE-1)) {
		printf("%s[%d] addr,len should align in 2kB\n", __func__, __LINE__);
		return 0;
	}

	while (i < len) {
		nand_read_buf (addr, buf + i, PAGE_SIZE);	/* only read a page */
		i += PAGE_SIZE;
		addr += PAGE_SIZE;
	}

	return i;
}


int nand_write (unsigned int addr,char *buf,unsigned int len)
{
	int ret=0;
	EN_NF0();
	
	NFCMD_REG = 0x80;
	
	/* column addr */
	NFADDR_REG = (addr & 0x7ff)& 0xff;		/* "addr & 0x7ff" -> addr%2048 */
	NFADDR_REG = (addr & 0x7ff)>>8;
	/* row(page) addr */
	NFADDR_REG = (addr>>11)&0xff;		/* "addr>>11" -> addr/2048 */
	NFADDR_REG = (addr>>11)>>8 & 0xff;
	NFADDR_REG = (addr>>11)>>16 & 0x7;
	
	while (len--)
		NFDATA8_REG = *buf++;
	
	NFCMD_REG = 0x10;
	
	while( !IS_READY_NF0() );
	
	NFCMD_REG = 0x70;
		
	ret = NFDATA8_REG & 0x1;			/* I/O_0 =0 Successful Erase, I/O_0 =1 Error in Erase  */
	
	DIS_NF0();
	
	return ret;
}


/* erase basis block(128KB) */
int nand_block_erase (unsigned int addr)
{
	int ret=0;
	EN_NF0();
	
	NFCMD_REG = 0x60;
	
	/* row(page) addr */
	NFADDR_REG = (addr>>11)&0xff;		/* "addr>>11" -> addr/2048 */
	NFADDR_REG = (addr>>11)>>8 & 0xff;
	NFADDR_REG = (addr>>11)>>16 & 0x7;
	
	NFCMD_REG = 0xd0;
	
	while( !IS_READY_NF0() );
	
	NFCMD_REG = 0x70;
		
	ret = NFDATA8_REG & 0x1;			/* I/O_0 =0 Successful Erase, I/O_0 =1 Error in Erase  */
	
	DIS_NF0();
	
	return ret;
}


void nand_test (void)
{
	int addr=0x600000;//0x3FFC0000; /* NO.8190 block */
	int i;
	char buf[64]={0};
	
	
	printf("%s [%d]\n", __func__, __LINE__);
	
	nand_read_id(buf);
	printf("<nand flash> id=");
	for(i=0; i<5; i++)
		printf("%02X ",buf[i]);
	printf("\n");
#if 0
	if (nand_block_erase(addr))
		printf("block erases fail!\r\n");
	
	for(i=0;i<64;i++)
		buf[i]= i;
	
	if ( nand_write(addr,buf,sizeof buf) )
		printf("nand program fail!\r\n");
#endif
	nand_read(addr,buf,sizeof buf);
	
	for(i=0; i<64; i++)
		printf("%02X ",buf[i]);
	
	printf("\n");
}


