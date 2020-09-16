.INCLUDE "m2560def.inc"

.EQU testnumber = 2078

.DSEG
.ORG 0x200
NUMBER: .BYTE 2

.CSEG
.DEF temp = r18
.DEF temp2 = r19

.MACRO reset_z
	LDI zh, high(@0)
	LDI zl, low(@0)
.ENDMACRO
.MACRO increment_space
	reset_z @0
	LDI temp2, 1
	LDD temp, z+1
	ADD temp, temp2
	STD z+1, temp
	LD temp, z
	CLR temp2
	ADC temp, temp2
	ST z, temp
.ENDMACRO

.MACRO make_negative
	reset_z @0
	LD temp, z
	COM temp
	ST z, temp
	LDD temp, z+1
	COM temp
	STD z+1, temp
	increment_space @0
.ENDMACRO

MAIN:
	reset_z NUMBER
	LDI temp, high(testnumber)
	ST z+, temp
	LDI temp, low(testnumber)
	ST z, temp
JMP INVERT

INVERT:
	make_negative NUMBER


HALT : RJMP HALT
