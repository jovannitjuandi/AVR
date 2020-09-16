.include "m2560def.inc" 

.cseg
.org 0x0000
.DEF UP = r21
.DEF DOWN = r20
.EQU start = 0x0F
.EQU loop = 124
.DEF temp = r16
.DEF iH = r25
.DEF iL = r24
.DEF countH = r18
.DEF countL = r17

.MACRO delay
	LDI countL, low(loop)
	LDI countH, high(loop)

	CLR iH
	CLR iL

looping: cp iL, countL
	CPC iH, countH
	BRSH done
	adiw iH:iL, 1
	nop
	RJMP loop

done:
.ENDMACRO

SER UP
CLR DOWN
CLR i

LDI temp, start
out PORTC, temp 
out DDRC, UP
out PORTD, UP
out DDRD, DOWN

DECREASE:
SBIC PIND, 1
RJMP DECREASE
DEC temp
out PORTC, temp
RJMP DECREASE

END: RJMP END