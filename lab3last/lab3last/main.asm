.INCLUDE "m2560def.inc"

.DEF temp = r17
.DEF second = r18
.DEF minute = r19
.DEF LC = r20
.DEF LG = r21

.DSEG
	tcount: .BYTE 2

.CSEG
	.ORG 0x0000
	JMP RESET
	.ORG OVF0addr
	JMP Timer0OVF

RESET:
	LDI temp, low(RAMEND)
	OUT SPL, temp
	LDI temp, high(RAMEND)
	OUT SPH, temp

	SER temp
	OUT DDRC, temp
	OUT DDRG, temp

	CLR temp
	OUT PORTC, temp
	OUT PORTG, temp

	CLR minute
	CLR second

	CLR temp
	OUT TCCR0A, temp //timer
	LDI temp, 2 // prescaling value
	OUT TCCR0B, temp
	LDI temp, 1 //enable overflow interrupt
	STS TIMSK0, temp
	SEI

	RJMP main

Timer0OVF:
	ADIW r25:r24, 1
	CPI r24, low(7812)
	LDI temp, high(7812)
	CPC r25, temp
	BREQ incSecond

	BACK:
RETI

incSecond:
	INC second
	CLR r24
	CLR r25
	MOV LC, second
	OUT PORTC, LC
	CPI second, 61
	BREQ incMinute
	RJMP BACK

incMinute:
	INC minute
	MOV LG, minute
	CLR second
	OUT PORTC, LC
	OUT PORTG, LG
	CPI minute, 4
	BREQ AGAIN
	RJMP BACK

AGAIN:
	CLR minute
	RJMP BACK

MAIN: 
	END: RJMP END
