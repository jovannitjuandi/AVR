.INCLUDE "m2560def.inc"

.DEF temp = r16
.DEF leds = r17
.DEF second = r18
.DEF minute = r19

.MACRO clear
	LDI YL, LOW(@0)
	LDI YH, HIGH(@0)
	CLR temp
	ST Y+, temp
	ST Y, temp
.ENDMACRO

.DSEG
	tcount: .BYTE 2

.CSEG
.ORG 0x0000
JMP RESET
.ORG OVF0addr
JMP Timer0OVF

RESET:
	LDI temp, HIGH(RAMEND)
	OUT SPH, temp
	LDI temp, LOW(RAMEND)
	OUT SPL, temp
	SER temp
	OUT DDRC, temp
	RJMP main

Timer0OVF:
	IN temp, SREG
	PUSH temp
	PUSH YH
	PUSH YL
	PUSH r25
	PUSH r24
	LDS r24, tcount
	LDS r25, tcount + 1
	ADIW r25:r24, 1

	CPI r24, low(7812)
	LDI temp, high(7812)
	CPC r25, temp
	BRNE NotSecond

	INC second
	CPI second, 60
	BREQ IncMin
	RJMP time

	NotSecond:
		STS tcount, r24
		STS tcount+1, r25

	End:
		POP r24
		POP r25
		POP YL
		POP YH
		POP temp
		OUT SREG, temp
	RETI

time:
	MOV leds, minute
	LSL leds
	LSL leds
	LSL leds
	LSL leds
	LSL leds
	LSL leds
	OR leds, second
	OUT PORTC, leds

CLEAR tcount
RJMP End

IncMin:
	CLR second
	INC minute
	CPI minute, 4
	BREQ preset
	RJMP time

preset:
	CLR minute
	RJMP time

main:
	LDI second, 0x00
	OUT PORTC, second
	CLEAR tcount

	LDI temp, 0
	OUT TCCR0A, temp
	LDI temp, 16
	OUT TCCR0B, temp
	LDI temp, 1<<TOIE0
	STS TIMSK0, temp
	SEI

FINISH: RJMP FINISH
