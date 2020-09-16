.include "m2560def.inc"

.CSEG

.ORG 0x00
JMP RESET

.ORG INT2addr
JMP EXT_INT2

RESET:
	;SETUP STACK
	LDI temp, low(RAMEND)
	OUT SPL, temp
	LDI temp, high(RAMEND)
	OUT SPH, temp
