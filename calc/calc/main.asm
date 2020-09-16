.include "mdef2560.inc"

; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.
  
.include "m2560def.inc"
.DEF temp = r16
.DEF row = r17
.DEF col = r18
.DEF mask = r19
.DEF temp2 = r20
.DEF printed = r21
.DEF character = r22
.EQU PORTLDIR = 0xF0; 0b11110000
.EQU INITCOLMASK = 0xEF; 0b11101111
.EQU INITROWMASK = 0x01; 0b00000001
.EQU ROWMASK = 0x0F; 0b00001111
.EQU LCD_RS = 7
.EQU LCD_E = 6
.EQU LCD_RW = 5
.EQU LCD_BE = 4

.macro lcd_set
	sbi PORTA, @0
.endmacro
.macro lcd_clr
	cbi PORTA, @0
.endmacro

.macro do_lcd_command
	ldi temp, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro
.macro do_lcd_data
	mov temp, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.CSEG
	jmp RESET


.ORG 0x72
RESET:
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	LDI temp, PORTLDIR ; 0b11110000
	STS DDRL, temp
	CLR character

	ser temp
	out DDRF, temp
	out DDRA, temp
	clr temp
	out PORTF, temp
	out PORTA, temp

	do_lcd_command 0b00110000 ; 1x5x7
	rcall sleep_5ms
	do_lcd_command 0b00110000 ; 1x5x7
	rcall sleep_1ms
	do_lcd_command 0b00110000 ; 1x5x7
	do_lcd_command 0b00110000 ; 1x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

MAIN:
	RCALL main_delay
	LDI mask, INITCOLMASK ; 0b11101111
	CLR col

COLLOOP:
	STS PORTL, mask ; set column to mask value initially 0b11110000
	LDI temp, 0xFF ; count down to 0 for delay

	DELAY:
		DEC temp
		BRNE delay

	LDS temp, PINL ; read PORTL
	ANDI temp, ROWMASK ; 0b00001111 read row only (?)
	CPI temp, 0xF ; 0b00001111 check if any rows are grounded
	BREQ NEXTCOL ; if no rows are grounded check next column
	LDI mask, INITROWMASK ; if one is grounded find the row
	CLR row

ROWLOOP: ; if one is grounded
	MOV temp2, temp ; temp is all 0s except the grounded one
	AND temp2, mask ; mask is 0b00000001
	BRNE SKIPCONV ; if not equal 
	RCALL CONVERT ; if row is found
	JMP MAIN

SKIPCONV: ; check next row
	INC row
	LSL mask ; shift the mask left
	JMP ROWLOOP 

NEXTCOL:
	CPI col, 3 ; check if its the last row
	BREQ MAIN ; if last row then no button is pressed
	SEC ; set the carry bit
	ROL mask ; shift the column mask to check next column
	INC col ; column number
	JMP COLLOOP ; if not the last check for the next column

CONVERT: ; when row is found
	CPI col, 3 ; if last column then letters
	BREQ LETTERS
	CPI row, 3 ; if last row then symbols
	BREQ SYMBOLS 
	RJMP NUMBERS ; otherwise numbers

LETTERS:
	LDI printed, 65 ; A is 65 on ASCII
	ADD printed, row
	RJMP PRINT

SYMBOLS:
	CPI col, 0
	BREQ STAR

	CPI col, 1
	BREQ ZERO

	CPI col, 2
	BREQ HASH

STAR:
	LDI printed, 42
	RJMP PRINT
ZERO:
	LDI printed, 48
	RJMP PRINT
HASH:
	LDI printed, 35
	RJMP PRINT

NUMBERS:
	LDI printed, 49
	LDI temp2, 3
	MUL row, temp2
	ADD printed, r0
	ADD printed, col
	RJMP PRINT

PRINT:
	INC character
	do_lcd_data printed
	CPI character, 17
	BREQ STARTOVER
	RJMP MAIN

STARTOVER:
	CLR character
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink
	do_lcd_data printed
	RJMP MAIN

;
; Send a command to the LCD (temp)
;

lcd_command:
	out PORTF, temp
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	ret

lcd_data:
	out PORTF, temp
	lcd_set LCD_RS
	nop
	nop
	nop
	lcd_set LCD_E
	nop
	nop
	nop
	lcd_clr LCD_E
	nop
	nop
	nop
	lcd_clr LCD_RS
	ret

lcd_wait:
	push temp
	clr temp
	out DDRF, temp
	out PORTF, temp
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E
	nop
	nop
    nop
	in temp, PINF
	lcd_clr LCD_E
	sbrc temp, 7
	rjmp lcd_wait_loop
	lcd_clr LCD_RW
	ser temp
	out DDRF, temp
	pop temp
	ret

.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:
	push r24
	push r25
	ldi r25, high(DELAY_1MS)
	ldi r24, low(DELAY_1MS)
delayloop_1ms:
	sbiw r25:r24, 1
	brne delayloop_1ms
	pop r25
	pop r24
	ret

sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret

main_delay:
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RET