; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
; 2. Connect the four LCD control pins BE-RS to PORTA4-7.
  
.INCLUDE "m2560def.inc"
.DEF temp = r16
.DEF second_low = r17
.DEF second_high = r18
.DEF minute_low = r19
.DEF minute_high = r20
.DEF disp = r21

.CSEG
	.ORG 0x0000
	JMP RESET
	.ORG OVF0addr
	JMP Timer0OVF

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

RESET:
	LDI temp, low(RAMEND)
	OUT SPL, temp
	LDI temp, high(RAMEND)
	OUT SPH, temp

	SER temp
	OUT DDRF, temp
	OUT DDRA, temp
	CLR temp
	OUT PORTF, temp
	OUT PORTA, temp
	LDI disp, 48
	CLR minute_low
	CLR minute_high
	CLR second_low
	CLR second_high

	do_lcd_command 0b00111100 ; 2x5x7
	RCALL sleep_5ms
	do_lcd_command 0b00111100 ; 2x5x7
	RCALL sleep_1ms
	do_lcd_command 0b00111100 ; 2x5x7
	do_lcd_command 0b00111100 ; 2x5x7
	do_lcd_command 0b00001000 ; display off?
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	CLR temp
	OUT TCCR0A, temp //timer
	LDI temp, 2
	OUT TCCR0B, temp
	LDI temp, 1<<TOIE0 //?
	STS TIMSK0, temp
	SEI

HALT: RJMP HALT 

Timer0OVF:
	ADIW r25:r24, 1
	CPI r24, low(7812)
	LDI temp, high(7812)
	CPC r25, temp
	BREQ incSecond

	BACK:
RETI

incSecond:
	INC second_low
	CLR r24
	CLR r25
	CPI second_low, 10
	BREQ tensec
	RJMP PRINT

tensec:
	INC second_high
	CLR second_low
	CPI second_high, 6
	BREQ incMinute
	RJMP PRINT

incMinute:
	CLR second_high
	INC minute_low
	CPI minute_low, 10
	BREQ tenmin
	RJMP PRINT

tenmin:
	INC minute_high
	CLR minute_low
	RJMP PRINT

PRINT:
	LDI disp, 48
	ADD disp, minute_high
	do_lcd_data disp

	LDI disp, 48
	ADD disp, minute_low
	do_lcd_data disp

	LDI disp, 58
	do_lcd_data disp

	LDI disp, 48
	ADD disp, second_high
	do_lcd_data disp

	LDI disp, 48
	ADD disp, second_low
	do_lcd_data disp

	do_lcd_command 0b00010000 ;shift cursor left
	do_lcd_command 0b00010000 ;shift cursor left
	do_lcd_command 0b00010000 ;shift cursor left
	do_lcd_command 0b00010000 ;shift cursor left
	do_lcd_command 0b00010000 ;shift cursor left
RJMP BACK

.EQU LCD_RS = 7
.EQU LCD_E = 6
.EQU LCD_RW = 5
.EQU LCD_BE = 4

.MACRO lcd_set
	SBI PORTA, @0
.ENDMACRO
.MACRO lcd_clr
	CBI PORTA, @0
.ENDMACRO

;
; Send a command to the LCD (temp)
;

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

.EQU F_CPU = 16000000
.EQU DELAY_1MS = F_CPU / 4 / 1000 - 4
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