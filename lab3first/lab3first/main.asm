.include "m2560def.inc"

.DEF temp = r16
.def index = r20
.def count = r21
.def counter = r22

.EQU start = 0x0F

.CSEG
.ORG 0x00

JMP RESET

.ORG INT0addr
JMP EXT_INT0

.ORG INT1addr
JMP EXT_INT1

 RESET:
 LDI temp, low(RAMEND)
 OUT SPL, temp
 LDI temp, high(RAMEND)
 OUT SPH, temp


 SER temp
 OUT DDRC, temp

 OUT PORTD, temp
 CLR TEMP
 OUT DDRD, temp

 LDI temp, start
 OUT PORTC, temp

 LDI temp, 0b00000000
 STS EICRA, temp
 IN temp, EIMSK
 ORI temp, 0b00000011
 OUT EIMSK, temp
 LDI temp, start
 SEI 
 JMP main

 EXT_INT0:
 CLR count
 RCALL PBDELAY
 RCALL PBDELAY
 DEC temp
 
 DECREMENT:
 OUT PORTC, temp
 CPI temp, 0xFF
 BREQ TOO

 RETI

 TOO:
	LDI temp, 0x0F
 RJMP DECREMENT

 EXT_INT1:
 CLR count
 RCALL PBDELAY
 RCALL PBDELAY
 INC temp
 CPI temp, 0x10
 BREQ PRE

 INCREMENT:
 OUT PORTC, temp
 RETI

 PRE:
	CLR temp
RJMP INCREMENT

 main:
 OUT PORTC, temp
 LOOP: RJMP LOOP

 //DELAY FUNCTIONALITY
PBDELAY:
CLR index
INC count
NOP
NOP
RCALL DDELAY
CPI count, 255
BRLO PBDELAY
RET

DDELAY:
CLR counter
INC index
RCALL DDDELAY
NOP
NOP
CPI index, 255
BRLO DDELAY
RET

DDDELAY:
INC counter
NOP
CPI counter, 10
BRLO DDDELAY
RET
