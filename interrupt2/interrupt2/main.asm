.INCLUDE "m2560def.inc"

;MACRO
.MACRO subtract_from_twobyte; NAME, VALUE
	reset_z @0
	LDD memory, z+1
	LDI variable, low(@1)
	SUB memory, variable
	STD z+1, memory
	LD memory, z
	LDI variable, high(@1)
	SBC memory, variable
	ST z, memory
.ENDMACRO

.MACRO divide_twobyte_by_onebyte ; numbermemory, remaindermemory, onebyteinteger
clear_onebyte @1
clear_twobyte TEMPORARY
RJMP CHECK_LESS_THAN

MINUSING:
subtract_from_twobyte @0, @2
increment_twobyte TEMPORARY

CHECK_LESS_THAN:
reset_z @0
LD variable, z+ ; highbyte
LD memory, z ; lowbyte

CPI memory, low(@2)
LDI memory, high(@2)
CPC variable, memory
BRLT FINISH_DIVIDE
RJMP MINUSING

FINISH_DIVIDE:
reset_z @0
LDD memory, z+1; lowbyte only <10
reset_z @1
ST z, memory
move_twobyte @0, TEMPORARY
.ENDMACRO

.MACRO move_twobyte; NAMETO, NAMEFROM
	reset_z @1
	LD memory, z
	reset_z @0
	ST z, memory
	reset_z @1
	LDD memory, z+1
	reset_z @0
	STD z+1, memory
.ENDMACRO

.MACRO clear_onebyte; NAME
	reset_z @0
	CLR variable
	ST z, variable
.ENDMACRO

.MACRO clear_twobyte; NAME
	reset_z @0
	CLR variable
	ST z+, variable
	ST z, variable
.ENDMACRO

.MACRO reset_z; MEMORY NAME
	LDI zh, high(@0)
	LDI zl, low(@0)
.ENDMACRO

.MACRO increment_twobyte; NAME
	reset_z @0
	LDI variable, 1
	LDD memory, z+1
	ADD variable, memory
	STD z+1, variable
	CLR variable
	LD memory, z
	ADC variable, memory
	ST z, variable
.ENDMACRO

.MACRO twobyte_to_register; NAME, REG_h, REG_l
	reset_z @0
	LD @1, z+
	LD @2, z
.ENDMACRO

;DATA DEFINITION
.DSEG
.DEF temp = r16
.DEF variable = r17
.DEF memory = r18
.DEF lowbyte = r19
.DEF highbyte = r20
.DEF testing = r21

;DEFINING MEMORIES
SPEED: .BYTE 2 ; in rotations per second
HOLES: .BYTE 2 ; number of holes in 100ms
INDEX: .BYTE 1 ; how many characters printed
INTERRUPT: .BYTE 2 ; number of overflows
TEMPORARY: .BYTE 2 ; temporary storage for macro uses
REMAINDER: .BYTE 1 ; remainder from onebyte divisions
INDIVIDUAL: .BYTE 5 ; separate speed to be printed

.CSEG
.ORG 0X00
JMP RESET	

.ORG OVF0addr
JMP Timer0OVF

.ORG INT2addr
JMP EXT_INT2

.ORG 0x72
RESET:
;SETUP STACK
	LDI temp, low(RAMEND)
	OUT SPL, temp
	LDI temp, high(RAMEND)
	OUT SPH, temp

	clear_twobyte HOLES
	clear_twobyte SPEED
	clear_twobyte INTERRUPT
	clear_onebyte INDEX
	clear_onebyte REMAINDER
	clear_twobyte TEMPORARY

;INITIALIZE LCD
	;do_lcd_command 0b00110000 ; 1x5x7
	;RCALL sleep_5ms
	;do_lcd_command 0b00000001 ; clear display
	;do_lcd_command 0b00000110 ; increment, no display shift
	;do_lcd_command 0b00001110 ; Cursor on, bar, no blink

;ACTIVATE LED (DEBUGGING)
	SER temp
	OUT PORTC, temp ; Write ones to all the LEDs
	SER temp
	OUT DDRC, temp ; PORTC is all outputs
	CLR testing

;SETTING TIMER
	CLR temp
	OUT TCCR0A, temp //timer
	LDI temp, 1
	OUT TCCR0B, temp
	LDI temp, 1<<TOIE0 //enable overflow interrupt
	STS TIMSK0, temp

;SETTING INTERRUPT	
	;LDI temp, (1 << ISC21)&(0 << ISC20)
	LDI temp, 0b00100000
	STS EICRA, temp

	IN temp, EIMSK
	ORI temp, (1 << INT2)
	OUT EIMSK, temp
	SEI

JMP MAIN

MAIN: 
	;CLR testing
	OUT PORTC, testing
JMP MAIN

Timer0OVF:
	increment_twobyte INTERRUPT; interrupt <- interrupt + 1
	twobyte_to_register INTERRUPT, highbyte, lowbyte
	CPI lowbyte, low(6250) ; 100ms
	LDI lowbyte, high(6250) ; 100ms
	CPC highbyte, lowbyte
	BREQ CHECK_SPEED
	JMP FINISH_OVF

	CHECK_SPEED:

	;DEBUGGING
	;reset_z HOLES
	;divide_twobyte_by_onebyte HOLES, REMAINDER, 4
	;LDD testing, z+1
	;OUT PORTC, testing


	clear_twobyte INTERRUPT

	FINISH_OVF:
RETI

EXT_INT2:
	INC testing
	OUT PORTC, testing
RETI