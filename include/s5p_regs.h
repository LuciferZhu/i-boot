
.equ	UND_VEC_ADDR,		0xD0037404
.equ	FETCH_ABT_VEC_ADDR,	0xD003740C
.equ	DATA_ABT_VEC_ADDR,	0xD0037410
.equ	IRQ_VECTOR_ADDR,	0xD0037418

.equ	rWTCON,			0xE2700000
.equ	SVC_STACK,		0xD0037D80

.set	rGPA0CON,		0xE0200000
.equ	rGPH2CON,		0xE0200C40
.equ	rGPH3CON,		0xE0200C60
.equ	rGPJ2CON,		0xE0200280@virtual addr 0x60000280, --PA:0xE0200280
.equ	rGPJ2DAT,		0xE0200284@virtual addr 0x60000284, --PA:0xE0200284
.equ	rGPD0CON,		0xE02000A0

.equ	rEXT_INT_2_CON,		0xE0200E08
.equ	rEXT_INT_3_CON,		0xE0200E0C
.equ	rEXT_INT_2_PEND,	0xE0200F48
.equ	rEXT_INT_3_PEND,	0xE0200F4C
.equ	rEXT_INT_2_MASK,	0xE0200F08
.equ	rEXT_INT_3_MASK,	0xE0200F0C

.equ	rVIC0IRQSTATUS, 	0xF2000000
.equ	rVIC0INTSELECT,		0xF200000C
.equ	rVIC0INTENABLE,		0xF2000010
.equ	rVIC0VECTADDR16,	0xF2000140
.equ	rVIC0VECTADDR21,	0xF2000154
.equ	rVIC0ADDRESS,		0xF2000f00
.equ	rVIC1ADDRESS,		0xF2100F00
.equ	rVIC2ADDRESS,		0xF2200F00
.equ	rVIC3ADDRESS,		0xF2300F00

.equ	rAPLL_CON0,		0xE0100100
.equ	rMPLL_CON,		0xE0100108
.equ	rAPLL_LOCK,		0xE0100000
.equ	rMPLL_LOCK,		0xE0100008
.equ	rCLK_SRC0,		0xE0100200
.equ	rCLK_DIV0,		0xE0100300

.equ	rTCFG0,			0xE2500000
.equ	rTCFG1,			0xE2500004
.equ	rTCON,			0xE2500008
.equ	rTCNTB0,		0xE250000C
.equ	rTCMPB0,		0xE2500010
.equ	rTINT_CSTAT,		0xE2500044

/*
 * uart REGISTER MAP
 */
.set	rUART0_BASE,		0xE2900000
.set	ULCON_OFFSET,		0x00
.set	UCON_OFFSET,		0x04
.set	UFCON_OFFSET,		0x08
.set	UMCON_OFFSET,		0x0C
.set	UTRSTAT_OFFSET,		0x10
.set	UERSTAT_OFFSET,		0x14
.set	UFSTAT_OFFSET,		0x18
.set	UMSTAT_OFFSET,		0x1C
.set	UTXH_OFFSET,		0x20
.set	URXH_OFFSET,		0x24
.set	UBRDIV_OFFSET,		0x28
.set	UDIVSLOT_OFFSET,	0x2C
.set	UINTP_OFFSET,		0x30
.set	UINTSP_OFFSET,		0x34
.set	UINTM_OFFSET,		0x38

 
@irom api
/**
* This Function copy MMC(MoviNAND/iNand) Card Data to memory.
* Always use EPLL source clock.
* This function works at 20Mhz.
* @param u32 StartBlkAddress : Source card(MoviNAND/iNand MMC)) Address.(It must block address.)
* @param u16 blockSize : Number of blocks to copy.
* @param u32* memoryPtr : Buffer to copy from.
* @param bool with_init : determined card initialization.
* @return bool(u8) - Success or failure.
*/
/*#define CopySDMMCtoMem(z,a,b,c,e) \
	(((bool(*)(int, unsigned int, unsigned short, unsigned int*, bool))(*((unsigned
int *)0xD0037F98)))(z,a,b,c,e))*/
.set	CopySDMMCtoMem,		0xD0037F98

/**
* This Function copies a block of page to destination memory.( 8-Bit ECC only )
* @param uint32 block : Source block address number to copy.
* @param uint32 page : Source page address number to copy.
* @param uint8 *buffer : Target Buffer pointer.
* @return int32 - Success or failure.
*/
/*#define NF8_ReadPage_Adv (a,b,c) \
	(((int(*)(uint32, uint32, uint8*))(*((uint32 *) 0xD0037F90)))(a,b,c))*/
.set	NF8_ReadPage_Adv,	0xD0037F90
