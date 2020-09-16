.include "m2560def.inc"

.DEF temp = r16
.DEF speed = r17
.def index = r20
.def count = r21
.def counter = r22

.EQU MAX_SPEED = 100
.EQU MIN_SPEED = 0
.EQU DIFFERENCE = 20

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
CLR speed

;PORTC = LED, PORTD = BUTTONS
SER temp
OUT DDRC, temp ; set portc all output
OUT PORTD, temp ; activate pull-up
CLR temp
OUT DDRD, temp ; set portd all input
OUT PORTC, temp

LDI temp, ((1 << ISC11)&(0 << ISC10)) | ((1 << ISC01)&(0 << ISC00))
STS EICRA, temp
 
IN temp, EIMSK
ORI temp, (1 << INT0) | (1 << INT1)
OUT EIMSK, temp

SER temp
OUT DDRE, temp; set porte all output
LDI temp, 0
STS OCR3BL, temp; OC3B low register
STS OCR3BH, temp;0C3B high register
LDI temp, 0b00000001 ; CS30 = 1: no prescaling
STS TCCR3B, temp; set the prescaling value
LDI temp, 0b00100001 ;(1<<WGM30)|(1<<COM3B1)
;WGM30=1: phase correct PWM, 8 bits
;COM3B1=1: make OC3B override the normal port functionality of the I/O pin PE2
STS TCCR3A, temp

SEI 
JMP main




EXT_INT0: ; INCREASE SPEED
	CLR count
	RCALL DELAY
	RCALL DELAY
	CPI speed, MAX_SPEED
	BREQ TOO_FAST

	LDI temp, DIFFERENCE
	ADD speed, temp
	STS OCR3BL, speed
	CLR temp
	STS OCR3BH, temp

	FINISH_INT0:
	OUT PORTC, speed
	RETI

TOO_FAST:
	LDI speed, MAX_SPEED
	JMP FINISH_INT0

EXT_INT1: ; REDUCE SPEED
	CLR count
	RCALL DELAY
	RCALL DELAY
	CPI speed, MIN_SPEED
	BREQ TOO_SLOW

	LDI temp, DIFFERENCE
	SUB speed, temp
	STS OCR3BL, speed
	CLR temp
	STS OCR3BH, temp

	FINISH_INT1:
	OUT PORTC, speed
	RETI

TOO_SLOW:
	LDI speed, MIN_SPEED
	JMP FINISH_INT1

 main:
 LOOP: RJMP LOOP

 //DELAY FUNCTIONALITY
DELAY:
CLR index
INC count
NOP
NOP
RCALL DDELAY
CPI count, 255
BRLO DELAY
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
