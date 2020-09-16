.include "m2560def.inc"

.DEF LC = r16
.DEF LG = r17
.DEF c1 = r20
.DEF c2 = r21
.DEF c3 = r22
.DEF seconds = r23
.DEF minutes = r24

.CSEG
.ORG 0x00
SER LC
SER LG
CLR seconds
CLR minutes
OUT DDRC, LC
OUT DDRG, LG
OUT PORTC, LC
OUT PORTG, LG


MAIN:
	CLR c1
	RCALL DELAY
	RCALL DELAY
	INC seconds
	CPI seconds, 61
	BREQ UNOMINUTES
	MOV LC, seconds 
	MOV LG, minutes
	OUT PORTC, LC
	OUT PORTG, LG
	RJMP MAIN

UNOMINUTES:
	CLR seconds
	MOV LC, seconds
	INC minutes
	MOV LG, minutes
	OUT PORTC, LC
	OUT PORTG, minutes
	CPI minutes, 4
	BREQ RESTART
RJMP MAIN

RESTART:
	CLR minutes
RJMP MAIN

DELAY: // 65261*250 + 3
INC c1 // 1 cycle
CLR c2 // 1 cycle
RCALL DDELAY // 3 + 65253
CPI c1, 250 // 1 cycle
BRLO DELAY // 2 cycles
RET // 4 cycle

DDELAY: // 261*250 + 3
INC c2 // 1 cycle
CLR c3 // 1 cycle
RCALL DDDELAY //3 + 253 cycles
CPI c2, 250 // 1 cycle
BRLO DDELAY // 2 cycles
RET // 4 cycles

DDDELAY: //4*50 + 3
INC c3 // 1 cycle
CPI c3, 50 // 1 cycle
BRLO DDDELAY // 2 cycles
RET // 4 cycles
