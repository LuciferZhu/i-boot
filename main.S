
.include "s5p_regs.h"

.global main
.text
main:
	bl LED_INIT
loop:
	ldr r0, =0
_for:	ldr r1, =0 		@on
	bl LED_GPIO_SET
	bl DELAY
	ldr r1, =1 		@off
	bl LED_GPIO_SET
	add r0, r0, #1	
	cmp r0, #4
	bne _for
	b loop


DELAY:
	stmfd sp!, {r0}
	ldr r0, =0x2000000
_delay:	subs r0, r0, #1
	bne _delay
	ldmfd sp!, {r0}
	bx lr


LED_INIT:
	stmfd sp!, {lr}

	@LED0
	ldr r0, =0
	ldr r1, =1
	bl LED_GPIO_CFG

	@LED1
	ldr r0, =1
	ldr r1, =1
	bl LED_GPIO_CFG
	
	@LED2
	ldr r0, =2
	ldr r1, =1
	bl LED_GPIO_CFG

	@LED3
	ldr r0, =3
	ldr r1, =1
	bl LED_GPIO_CFG

	@turn off four leds
	ldr r0, =0
	ldr r1, =0xf
	bl LED_GPIO_SET

	ldmfd sp!, {lr}
	bx lr


@ args: r0=[1]:num of pin
@	r1=[2]:set val

LED_GPIO_CFG:
	ldr r2,	=rGPJ2CON
	ldr r4, [r2]		@ r4 is the value of rGPJ2CON
	lsl r0, r0, #2		@ n = n*4
	ldr r3, =0xf
	bic r4, r4, r3, lsl r0
	orr r4, r4, r1, lsl r0
	str r4, [r2]

	bx lr


LED_GPIO_SET:
	stmfd sp!, {r0-r4}
	ldr r2,	=rGPJ2DAT
	ldr r4, [r2]		@ r4 is the value of rGPJ2DAT
	ldr r3, =0x1
	bic r4, r4, r3, lsl r0
	orr r4, r4, r1, lsl r0
	str r4, [r2]	

	ldmfd sp!, {r0-r4}
	bx lr

.end