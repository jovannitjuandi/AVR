; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.
  
.include "m2560def.inc"

.DSEG
.ORG 0x200
NUMBER: .BYTE 2
TEMPO: .BYTE 2
TOTAL: .BYTE 2
CURSIGN: .BYTE 1
ARRAY: .BYTE 10
SIGNS: .BYTE 5
VALID: .BYTE 1
QUOTIENT: .BYTE 2
INDIVIDUAL: .BYTE 5

.CSEG
.DEF temp = r16
.DEF val = r15
.DEF row = r17
.DEF col = r18
.DEF mask = r19
.DEF temp2 = r20
.DEF negat = r21
.DEF temp_h = r22
.DEF temp_l = r23
.DEF input = r24
.DEF printed = r25
.EQU bytesize = 5
.EQU PORTLDIR = 0xF0; 0b11110000
.EQU INITCOLMASK = 0xEF; 0b11101111
.EQU INITROWMASK = 0x01; 0b00000001
.EQU ROWMASK = 0x0F; 0b00001111
.EQU LCD_RS = 7
.EQU LCD_E = 6
.EQU LCD_RW = 5
.EQU LCD_BE = 4

; increment value by one in space
.MACRO increment
	reset_z @0
	LD temp2, z
	INC temp2
	ST z, temp2
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

; move from one memory space to another each 2 byte size
.MACRO move_from_to
	reset_z @0
	LD temp, z
	reset_z @1
	ST z, temp
	reset_z @0
	LDD temp, z+1
	reset_z @1
	STD z+1, temp
.ENDMACRO

; minus number in memory space by 10
.MACRO minus_ten
	reset_z @0
	LDD temp, z+1
	SUBI temp, 10
	STD z+1, temp
	LD temp, z
	SBCI temp, 0
	ST z, temp
.ENDMACRO

; clear space in memory
.MACRO clear_space
	CLR temp2
	reset_z @0
	ST z+, temp2
	ST z, temp2
.ENDMACRO

; clear significant memory space
.MACRO clearall
	CLR temp2
	reset_z NUMBER
	ST z+, temp2
	ST z, temp2

	reset_z TEMPO
	ST z+, temp2
	ST z, temp2

	reset_z TOTAL
	ST z+, temp2
	ST z, temp2

	reset_z ARRAY
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2

	reset_z SIGNS
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2
	ST z+, temp2

	reset_z VALID
	ST z+, temp2

	reset_z CURSIGN
	ST z+, temp2
.ENDMACRO

; move pointer z to any memory space
.MACRO reset_z
	LDI zh, high(@0)
	LDI zl, low(@0)
.ENDMACRO

; multiply NUMBER by 10
.MACRO mul_ten ; NUMBER 
	reset_z NUMBER
	LD temp_h, z+
	LD temp_l, z
	LSL temp_l; times 2
	ROL temp_h
	reset_z TEMPO; store in temporary storage
	ST z+, temp_h
	ST z, temp_l
	LSL temp_l; times 4
	ROL temp_h
	LSL temp_l; times 8
	ROL temp_h
	reset_z NUMBER; store in number
	ST z+, temp_h
	ST z, temp_l
	LD temp_l, z; low of *8
	reset_z TEMPO
	LDD temp_h, z+1; low of *2
	ADD temp_l, temp_h; add lows
	reset_z NUMBER
	STD z+1, temp_l; store low in number
	LD temp_h, z; high of *8
	reset_z TEMPO
	LD temp_l, z; high of *2
	ADC temp_l, temp_h; add highs
	reset_z NUMBER; store result in NUMBER
	ST z, temp_l
.ENDMACRO

; add new number to NUMBER
.MACRO add_number
	reset_z NUMBER
	LDD temp_l, z+1
	LD temp_h, z
	MOV temp2, @0
	ADD temp_l, temp2
	CLR temp2
	ADC temp_h, temp2

	reset_z NUMBER
	STD z+1, temp_l
	ST z, temp_h
.ENDMACRO

;determine sign
.MACRO determine_sign
	LDI temp, @0
	ST x+, temp
.ENDMACRO

; change sign of memory space
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

; move any space into array
.MACRO move_to_array
	reset_z @0
	LD temp_h, z+
	LD temp_l, z
	ST y+, temp_h
	ST y+, temp_l
	CLR temp_l
	CLR temp_h
	reset_z @0
	ST z+, temp_h
	ST z, temp_l
.ENDMACRO

; add every element in array
.MACRO total_array
	CLR temp2
	LDI yl, low(ARRAY)
	LDI yh, high(ARRAY)
	LDI xl, low(SIGNS)
	LDI xh, high(SIGNS)
	reset_z NUMBER
	ST z+, temp2
	ST z, temp2

	TOTALLOOP:
		INC temp2
		reset_z TEMPO; TEMPO is current element
		LD temp_h, y+
		LD temp_l, y+
		ST z+, temp_h
		ST z, temp_l
		LD temp, x+
		CPI temp, 1
		BREQ NEGATIVE

		POSITIVE:
		reset_z NUMBER
		LDD temp_h, z+1; lowbits
		ADD temp_l, temp_h
		STD z+1, temp_l
		LD temp_h, z; highbits
		reset_z TEMPO
		LD temp_l, z
		ADC temp_h, temp_l
		reset_z NUMBER
		ST z, temp_h
		BRPL posFLAG
		RJMP COMPARING

		posFLAG:
			CLR negat
		RJMP COMPARING

		NEGATIVE:
		reset_z NUMBER; NUMBER is current total
		LDD temp_h, z+1
		SUB temp_h, temp_l
		STD z+1, temp_h
		LD temp_h, z
		reset_z TEMPO
		LD temp_l, z
		SBC temp_h, temp_l
		reset_z NUMBER
		ST z, temp_h
		BRMI negFLAG
		RJMP COMPARING

		negFLAG:
			LDI negat, 1
		RJMP COMPARING

	COMPARING:
	CP temp2, input
	BRLT TOTALLOOP
	reset_z NUMBER
	LD temp_h, z+
	LD temp_l, z
	reset_z TOTAL
	ST z+, temp_h
	ST z, temp_l
.ENDMACRO

; LCD INSTRUCTIONS
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

.macro do_lcd_data_direct
	LDI temp, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

; CODE BEGIN
.CSEG
	jmp RESET

.ORG 0x72
RESET: ; MAINRESET
	clearall
	CLR val
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	LDI yl, low(ARRAY)
	LDI yh, high(ARRAY)

	LDI xl, low(SIGNS)
	LDI xh, high(SIGNS)
	determine_sign 0

	LDI temp, PORTLDIR ; 0b11110000
	STS DDRL, temp

	CLR input

	ser temp
	out DDRF, temp
	out DDRA, temp
	out DDRC, temp
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
	RCALL ACTION ; if row is found
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

ACTION: ; when row is found
	CPI col, 3 ; if last column then letters
	BREQ LETTERS
	CPI row, 3 ; if last row then symbols
	BREQ SYMBOLING
	RJMP NUMBERS ; otherwise numbers

;NOT_VALID: 
;	increment VALID

SYMBOLING:
	JMP SYMBOLS

LETTERS:
	CPI row, 0
	BREQ MINUS
	CPI row, 1
	BREQ PLUS

	;reset_z CURSIGN
	;LD temp, z
	;CPI temp, 1
	;BRNE NOT_VALID

	CPI row, 2
	BREQ EQUALLING

	EQUALLING: JMP EQUAL

	MINUS:
		INC input
		LDI printed, 45
		determine_sign 1
		move_to_array NUMBER
		increment CURSIGN
		RJMP PRINT
	
	PLUS:
		INC input
		LDI printed, 43
		determine_sign 0
		move_to_array NUMBER
		increment CURSIGN
		RJMP PRINT

	EQUAL:
		INC input
		LDI printed, 61
		move_to_array NUMBER
		total_array
		JMP SEPARATE_TOTAL
		CLR input
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
		reset_z VALID
		increment VALID
		RJMP PRINT
	ZERO:
		mul_ten
		LDI printed, 48
		RJMP PRINT
	HASH:
		LDI printed, 35
		reset_z VALID
		increment VALID
		RJMP PRINT

NUMBERS:
	clear_space CURSIGN
	mul_ten
	LDI printed, 49
	LDI temp2, 3
	MUL row, temp2
	ADD printed, r0
	ADD printed, col
	ADD r0, col
	INC r0

	add_number r0

	RJMP PRINT

	
	INVALIDING: JMP INVALIDINPUT

PRINT:
	do_lcd_data printed
	RJMP MAIN

SEPARATE_TOTAL:
	reset_z VALID
	LD temp, z
	CPI temp, 0
	BRNE INVALIDING

	CLR input
	LDI yl, low(INDIVIDUAL)
	LDI yh, high(INDIVIDUAL)
	JMP SUBTRACT

	INVERT:
	make_negative TOTAL
	
	LDI negat, 2

	SUBTRACT:
	CPI negat, 1
	BREQ INVERT
	move_from_to TOTAL, TEMPO ; working

	REPEAT:
	reset_z TEMPO
	LDD temp, z+1
	CPI temp, low(10)
	LD temp, z
	LDI temp2, high(10)
	CPC temp, temp2
	BRLO SAVENUMBER
	RJMP MORETEN

	MORETEN:
	increment_space QUOTIENT
	minus_ten TEMPO
	RJMP REPEAT
	
	SAVENUMBER:
	INC input
	reset_z TEMPO
	LDD temp, z+1
	ST y+, temp
	move_from_to QUOTIENT, TOTAL
	clear_space QUOTIENT
	CPI input, bytesize
	BRLO JUMP_SUBTRACT

	PRINT_TOTAL:
	do_lcd_data_direct 61

	PRINTNOW:
	reset_z INDIVIDUAL
	LDI temp2, 48
	LDD temp, z+4
	ADD temp, temp2
	do_lcd_data temp
	LDD temp, z+3
	ADD temp, temp2
	do_lcd_data temp
	LDD temp, z+2
	ADD temp, temp2
	do_lcd_data temp
	LDD temp, z+1
	ADD temp, temp2
	do_lcd_data temp
	LD temp, z
	ADD temp, temp2
	do_lcd_data temp
	RJMP finish_PRINT_TOTAL

	finish_PRINT_TOTAL:
	CPI negat, 2
	BREQ print_sign

HALT: RJMP HALT
	JUMP_SUBTRACT:
	JMP SUBTRACT

	INVALIDINPUT:
	do_lcd_data_direct 'I'
	do_lcd_data_direct 'N'
	do_lcd_data_direct 'V'
	do_lcd_data_direct 'A'
	do_lcd_data_direct 'L'
	do_lcd_data_direct 'I'
	do_lcd_data_direct 'D'

	print_sign:
	do_lcd_data_direct 45

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
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RCALL sleep_5ms
	RET