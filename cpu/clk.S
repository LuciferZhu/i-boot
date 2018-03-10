@ Copyright (C) 2017 Lucifer Zhu
@
@ date: 2017-11-19 01:09:05
@ e-mail: LuciferZhu@yeah.net
@ clock domain configuration

.include "s5p_regs.h"

.global CMU_init
.text
CMU_init:
	stmfd sp!, {lr}
	bl APLL_cfg
	bl MSYS_domain_cfg
	bl MPLL_cfg
	bl DSYS_domain_cfg
	bl PSYS_domain_cfg
	@ldr r0, =fmt_cmu
	@bl printf
	ldmfd sp!, {pc}

APLL_cfg:
	@FIN(MHz)   Target FOUT(MHz)   PLL   P   M   S   Fref(MHz)   Lock time(us)
	@24	     1000.0000         APLL  3  125  1      8          30
	ldr r0, =rAPLL_CON0
	ldr r1, =0
	
	ldr r2, =1
	lsl r2, r2, #31
	orr r1, r2
	
	ldr r2, =125
	lsl r2, r2, #16
	orr r1, r2
	
	ldr r2, =3
	lsl r2, r2, #8
	orr r1, r2
	
	ldr r2, =1
	orr r1, r2
	str r1, [r0]
	
	ldr r0, =rAPLL_LOCK
	ldr r1, =30
	str r1, [r0]
	
	@ MUXAPLL=1:FOUTAPLL
	ldr r0, =rCLK_SRC0
	ldr r1, [r0]
	orr r1, r1, #0x1
	str r1, [r0]
	bx lr

MSYS_domain_cfg:
	@ MUX_MSYS=0:SCLKAPLL
	ldr r0, =rCLK_SRC0
	ldr r1, [r0]
	ldr r2, =1
	bic r1, r1, r2, lsl #16
	str r1, [r0]
	
	ldr r0, =rCLK_DIV0
	ldr r1, [r0]
	@ARMCLK = MOUT_MSYS / (APLL_RATIO + 1) = 1000MHz --> DIVAPLL=1 
	bic r1, r1, #0x7
	@HCLK_MSYS = ARMCLK / (HCLK_MSYS_RATIO + 1) = 200MHz --> DIVHCLKM=5
	ldr r2, =0x7
	bic r1, r1, r2, lsl #8
	ldr r2, =4
	orr r1, r1, r2, lsl #8 
	@PCLK_MSYS = HCLK_MSYS / (PCLK_MSYS_RATIO + 1) = 100MHz --> DIVPCLKM=2
	ldr r2, =0x7
	bic r1, r1, r2, lsl #12
	ldr r2, =1
	orr r1, r1, r2, lsl #12 
	
	str r1, [r0]
	bx lr

	
MPLL_cfg:
	@FIN(MHz)   Target FOUT(MHz)   PLL   P   M   S   Fref(MHz)   Lock time(us)
	@24          667.0000          MPLL  12 667  1      2            200
	ldr r0, =rMPLL_CON
	ldr r1, =0
	
	ldr r2, =1
	orr r1, r1, r2, lsl #31
	
	bic r1, r1, r2, lsl #27
	
	ldr r2, =667
	orr r1, r1, r2, lsl #16
	
	ldr r2, =12
	orr r1, r1, r2, lsl #8
	
	ldr r2, =1
	orr r1, r2
	str r1, [r0]
	
	ldr r0, =rMPLL_LOCK
	ldr r1, =200
	str r1, [r0]
	@ MUXMPLL=1:FOUTMPLL
	ldr r0, =rCLK_SRC0
	ldr r1, [r0]
	orr r1, r1, #0x10
	str r1, [r0]
	bx lr

DSYS_domain_cfg:
	@ MUX_DSYS=0:SCLKMPLL
	ldr r0, =rCLK_SRC0
	ldr r1, [r0]	
	ldr r2, =1
	bic r1, r1, r2, lsl #20
	str r1, [r0]
	
	ldr r0, =rCLK_DIV0
	ldr r1, [r0]
	@HCLK_DSYS = MOUT_DSYS / (HCLK_DSYS_RATIO + 1) = 166MHz --> DIVHCLKD=4
	ldr r2, =0xf
	bic r1, r1, r2, lsl #16
	ldr r2, =3
	orr r1, r1, r2, lsl #16
	@PCLK_DSYS = HCLK_DSYS / (PCLK_DSYS_RATIO + 1) = 83MHz --> DIVPCLKM=2
	ldr r2, =0x7
	bic r1, r1, r2, lsl #20
	ldr r2, =1
	orr r1, r1, r2, lsl #20 
	str r1, [r0]
	bx lr
	
PSYS_domain_cfg:
	@ MUX_PSYS=0:SCLKMPLL
	ldr r0, =rCLK_SRC0
	ldr r1, [r0]	
	ldr r2, =1
	bic r1, r1, r2, lsl #24
	str r1, [r0]
	
	ldr r0, =rCLK_DIV0
	ldr r1, [r0]
	@HCLK_PSYS = MOUT_PSYS / (HCLK_PSYS_RATIO + 1) = 133MHz --> DIVHCLKP=5
	ldr r2, =0xf
	bic r1, r1, r2, lsl #24
	ldr r2, =4
	orr r1, r1, r2, lsl #24
	@PCLK_PSYS = HCLK_PSYS / (PCLK_PSYS_RATIO + 1) = 66MHz --> DIVPCLKM=2
	ldr r2, =0x7
	bic r1, r1, r2, lsl #28
	ldr r2, =1
	orr r1, r1, r2, lsl #28 
	str r1, [r0]
	bx lr

.data
fmt_cmu:
	.string "APLL = 1000MHz, MPLL = 667MHz\r\n\tARMCLK = 1000MHz, HCLK_MSYS = 200MHz, PCLK_MSYS = 100MHz\r\n\tHCLK_DSYS = 166MHz, PCLK_DSYS = 83MHz\r\n\tHCLK_PSYS = 133MHz, PCLK_PSYS = 66MHz\r\n"
	
	
.end
