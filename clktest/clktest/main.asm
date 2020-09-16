; COMP2121 Lab 5 Part A
;
; Matthew Bourke
; 15/04/2019


.include "m2560def.inc"

.def temp = r16
.def num = r18

.equ LCD_RS = 7
.equ LCD_E = 6
.equ LCD_RW = 5
.equ LCD_BE = 4
.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4

.dseg
.org 0x200
Counter: .byte 2
Speed: .byte 2


.cseg
.org 0x000
	rjmp RESET
.org INT2addr
	rjmp EXT_INT2
.org OVF0addr
	rjmp Timer0


// Macros
.macro do_lcd_command
	ldi temp, @0
	rcall lcd_command
	rcall lcd_wait
.endmacro

.macro do_lcd_data
	ldi temp, @0
	rcall lcd_data
	rcall lcd_wait
.endmacro

.macro clear
	ldi YL, low(@0)
	ldi YH, high(@0)
	clr temp
	st Y+, temp
	st Y, temp
.endmacro

.macro lcd_set
	sbi PORTA, @0
.endmacro

.macro lcd_clr
	cbi PORTA, @0
.endmacro

	


// Interrupts
RESET:
	ldi temp, high(RAMEND)
	out SPH, temp
	ldi temp, low(RAMEND)
	out SPL, temp

	ldi XL, low(Speed)
	ldi XH, high(Speed)

	ser temp				; set ports A, C, F, and G as outputs
	out DDRA, temp
	out DDRC, temp
	out DDRF, temp
	out DDRG, temp

	clr num

	// LCD reset
	do_lcd_command 0b00111000	; 2x5x7
	do_lcd_command 0b00001110	; turn display on
	do_lcd_command 0b10000000	; move curser to beginning of first line
	do_lcd_command 0b00000001	; clear display

	// Initialise timer interrupt
	clr temp
	out TCCR0A, temp
	ldi temp, 0b00000010
	out TCCR0B, temp			; set prescaler value to 8
	ldi temp, (1 << TOIE0)		; interrupt occurs every 128us
	sts TIMSK0, temp


	// Initialise interrupt 2
	ldi temp, (2 << ISC20)		; set interrupt 2 as falling-edge triggered
	sts EICRA, temp
	ldi r16, (1 << INT2)			//enables int2
	out EIMSK, r16

	sei
	
	rjmp setup

EXT_INT2:
	inc num
	reti

Timer0:
	push temp
	in temp, SREG
	push temp
	push r24
	push r25

	lds r24, Counter
	lds r25, Counter + 1
	adiw r25:r24, 1
	ldi temp, high(3906)	// 500ms counter
	cpi r24, low(3906)
	cpc r25, temp
	brne notTime
	clear Counter
	brsh light
	rjmp end

	light:
		lsr num				// revs per second
		out PORTC, num
		
	cpi num, 0
	breq zeroSpeed

	// Divide by 10 and display each number
	ldi temp, 10
	clr r19
	clr r21
	clr r20
	mov r20, num
	d:
	sub r20, temp
	inc r19
	cp r20, temp
	brsh d
	st X+, r20
	inc r21
	mov r20, r19
	cp r19, temp
	clr r19
	brsh d
	st X, r20
	inc r21

	display:
	//do_lcd_command 0b00000001
	ld temp, X			// First number
	subi temp, -'0'
	rcall lcd_data
	rcall lcd_wait
	dec r21
	breq finDisplay
	sbiw X, 1
	rjmp display

	finDisplay:
	do_lcd_data ' '
	do_lcd_data ' '
	do_lcd_command 0b10000000
	rjmp res

	zeroSpeed:
		do_lcd_data '0'	
		do_lcd_data ' '
		do_lcd_data ' '
		do_lcd_command 0b10000000
		rjmp res

	notTime:
		sts Counter, r24
		sts Counter + 1, r25
		rjmp end

	res:
	ldi XL, low(Speed)
	ldi XH, high(Speed)

	clr r19
	clr r20
	clr r21
	clr num
	rjmp end

	end:
		pop r25
		pop r24
		pop temp
		out SREG, temp
		pop temp
		reti

setup:
	rjmp main

main:
	//do_lcd_data 'M'
	rjmp main
	
halt:
	rjmp halt


// LCD Command function carries out command given from macro
lcd_command:
	out PORTF, temp
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	ret

// LCD Data function carries out data given from macro

lcd_data:
	out PORTF, temp
	lcd_set LCD_RS
	rcall sleep_1ms
	lcd_set LCD_E
	rcall sleep_1ms
	lcd_clr LCD_E
	rcall sleep_1ms
	lcd_clr LCD_RS
	ret

// LCD Wait function makes the LCD display wait to continue operations
lcd_wait:
	push temp
	clr temp
	out DDRF, temp
	out PORTF, temp
	lcd_set LCD_RW
	lcd_wait_loop:
		rcall sleep_1ms
		lcd_set LCD_E
		rcall sleep_1ms
		in temp, PINF
		lcd_clr LCD_E
		sbrc temp, 7
		rjmp lcd_wait_loop
		lcd_clr LCD_RW
		ser temp
		out DDRF, temp
		pop temp
		ret

// Sleep 1ms function acts as a 1ms delay
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

// Sleep 5ms function acts as a 5ms delay
sleep_5ms:
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	rcall sleep_1ms
	ret
