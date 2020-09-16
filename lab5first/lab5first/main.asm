.INCLUDE "m2560def.inc"

;MACRO
.MACRO multiply_twobyte_ten ; @0 
	reset_z @0
	LD variable, z+
	LD memory, z
	LSL memory; times 2
	ROL variable
	reset_z TEMPORARY; store in TEMPORARY storage
	ST z+, variable
	ST z, memory
	LSL memory; times 4
	ROL variable
	LSL memory; times 8
	ROL variable
	reset_z @0; store in @0
	ST z+, variable
	ST z, memory
	LD memory, z; low of *8
	reset_z TEMPORARY
	LDD variable, z+1; low of *2
	ADD memory, variable; add lows
	reset_z @0
	STD z+1, memory; store low in @0
	LD variable, z; high of *8
	reset_z TEMPORARY
	LD memory, z; high of *2
	ADC memory, variable; add highs
	reset_z @0; store result in @0
	ST z, memory
.ENDMACRO

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

.MACRO do_lcd_command
	LDI temp, @0
	RCALL lcd_command
	RCALL lcd_wait
.ENDMACRO

.MACRO do_lcd_data
	MOV temp, @0
	RCALL lcd_data
	RCALL lcd_wait
.ENDMACRO

.MACRO lcd_set
	SBI PORTA, @0
.ENDMACRO

.MACRO lcd_clr
	CBI PORTA, @0
.ENDMACRO

;DATA DEFINITION
.DSEG
.DEF temp = r16
.DEF variable = r17
.DEF memory = r18
.DEF lowbyte = r19
.DEF highbyte = r20
.DEF ascii  = r22
.DEF testing = r21
.DEF wth = r23
.DEF count = r24

;DEFINING CONSTANTS
.EQU LCD_RS = 7
.EQU LCD_E = 6
.EQU LCD_RW = 5
.EQU LCD_BE = 4

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

.ORG INT2addr
JMP EXT_INT2

.ORG OVF0addr
JMP Timer0OVF

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
	LDI ascii, 48

;ACTIVATE LCD
	SER temp
	OUT DDRF, temp
	OUT DDRA, temp
	CLR temp
	OUT PORTF, temp
	OUT PORTA, temp

;INITIALIZE LCD
	do_lcd_command 0b00110000 ; 1x5x7
	RCALL sleep_5ms
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

;ACTIVATE LED (DEBUGGING)
	SER temp
	OUT PORTC, temp ; Write ones to all the LEDs
	SER temp
	OUT DDRC, temp ; PORTC is all outputs
	CLR testing

;SETTING TIMER
	CLR temp
	OUT TCCR0A, temp //timer
	LDI temp, 1 // no prescaling
	OUT TCCR0B, temp
	LDI temp, 1<<TOIE0 //enable overflow interrupt
	STS TIMSK0, temp

;SETTING INTERRUPT	
	
	LDI temp, 0b00100000
	STS EICRA, temp

	IN temp, EIMSK
	ORI temp, (1 << INT2)
	OUT EIMSK, temp
	SEI

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
	multiply_twobyte_ten HOLES
	divide_twobyte_by_onebyte HOLES, REMAINDER, 4 ; 4 holes in one rotation
	do_lcd_command 0b00000001	; clear display

	divide_twobyte_by_onebyte HOLES, REMAINDER, 10
	reset_z REMAINDER
	LD wth, z
	ADD wth, ascii
	PUSH wth

	divide_twobyte_by_onebyte HOLES, REMAINDER, 10
	reset_z REMAINDER
	LD wth, z
	ADD wth, ascii
	PUSH wth

	reset_z REMAINDER 
	LD testing, z
	OUT PORTC, testing

	divide_twobyte_by_onebyte HOLES, REMAINDER, 10
	reset_z REMAINDER
	LD wth, z
	ADD wth, ascii
	PUSH wth

	divide_twobyte_by_onebyte HOLES, REMAINDER, 10
	reset_z REMAINDER
	LD wth, z
	ADD wth, ascii
	PUSH wth

	divide_twobyte_by_onebyte HOLES, REMAINDER, 10
	reset_z REMAINDER
	LD wth, z
	ADD wth, ascii
	PUSH wth

	POP wth
	do_lcd_data wth
	POP wth
	do_lcd_data wth
	POP wth
	do_lcd_data wth
	POP wth
	do_lcd_data wth
	POP wth
	do_lcd_data wth
	LDI wth, 114
	do_lcd_data wth
	LDI wth, 112
	do_lcd_data wth
	LDI wth, 115
	do_lcd_data wth

	clear_twobyte HOLES
	clear_twobyte INTERRUPT

	FINISH_OVF:
RETI

EXT_INT2:
	increment_twobyte HOLES
	reset_z HOLES
	;LDD testing, z+1
	;OUT PORTC, testing
RETI


MAIN: 
	;CLR testing
	OUT PORTC, testing
JMP MAIN

;ADDITIONAL FUNCTIONS
lcd_command:
	OUT PORTF, temp
	NOP
	lcd_set LCD_E
	NOP
	NOP
	NOP
	lcd_clr LCD_E
	NOP
	NOP
	NOP
	RET

lcd_data:
	OUT PORTF, temp
	lcd_set LCD_RS
	NOP
	NOP
	NOP
	lcd_set LCD_E
	NOP
	NOP
	NOP
	lcd_clr LCD_E
	NOP
	NOP
	NOP
	lcd_clr LCD_RS
	RET

lcd_wait:
	PUSH temp
	CLR temp
	OUT DDRF, temp
	OUT PORTF, temp
	lcd_set LCD_RW
lcd_wait_loop:
	NOP
	lcd_set LCD_E
	NOP
	NOP
    NOP
	IN temp, PINF
	lcd_clr LCD_E
	SBRC temp, 7
	RJMP lcd_wait_loop
	lcd_clr LCD_RW
	SER temp
	OUT DDRF, temp
	POP temp
	RET

.EQU F_CPU = 16000000 ; 16MHz board frequency
.EQU DELAY_1MS = F_CPU / 4 / 1000 - 4 ; 1ms clock cycle
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	PUSH r24
	PUSH r25
	LDI r25, high(DELAY_1MS)
	LDI r24, low(DELAY_1MS)
delayloop_1ms:
	SBIW r25:r24, 1
	BRNE delayloop_1ms
	POP r25
	POP r24
	RET

sleep_5ms:
	RCALL sleep_1ms
	RCALL sleep_1ms
	RCALL sleep_1ms
	RCALL sleep_1ms
	RCALL sleep_1ms
	RET

THREETE:
	CLR count
	REPEAT_NOP:
	NOP
	INC count
	CPI count, 40
	BRLT REPEAT_NOP
	CLR count
RET