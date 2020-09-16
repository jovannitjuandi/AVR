.INCLUDE "m2560def.inc"

.DSEG
;DEFINING MEMORY SPACES
.ORG 0X200
ARRAY_LETTERS: .BYTE 30
COUNTER: .BYTE 1 ; counter
LENGTH: .BYTE 1 ; current name's length
ALL_ONES: .BYTE 1 ; stores all one 
STATION_ARRAY: .BYTE 100 ; holds name of all stations in order
MODE: .BYTE 1 ; 1 = letter, 0 = number
PRESSED: .BYTE 1 ; the pressed button
REPEAT_BUTTON: .BYTE 1 ; check if same button was pressed
INDEX: .BYTE 1 ; holds temporary indexing in macros
EMPTY: .BYTE 1 ; holds the number 0
REPETITION: .BYTE 1 ; temporary loop counters
STATION_TOTAL: .BYTE 1 ; stores how many stations there are
STATION_TIME: .BYTE 10 ; stores time between stations
STATION_LENGTH: .BYTE 10 ; stores length of name of each station
CURRENT: .BYTE 2 ; holds current letter input
NUMBER: .BYTE 2 ; holds current number input
NUM: .BYTE 1 ; holds current ONEBYTE number input
NUMBER_INPUT: .BYTE 1 ; temporarily store processed number input
NUMBER_PRESSED: .BYTE 1 ; how many digits were pressed
LETTER: .BYTE 2 ; holds letter input
STOP_TIME: .BYTE 1 ; holds how long monorail stops
STATION: .BYTE 10 ; holds current station name 
TIMER_CURRENT: .BYTE 1 ; holds current time during the steps
TIMER_INTERRUPT: .BYTE 2 ; holds current number of interrupts
TIMER_COUNTING: .BYTE 1 ; flag wether timer should be counting, 0 = stop, otherwise counts
TIMER_TARGET: .BYTE 1 ; holds how long before timer is reset
MOTOR_MOVING: .BYTE 1 ; flag wether motor should be running or not, 0 = stop, otherwise runs
MOTOR_STOP: .BYTE 1 ; flag wether the motor will stop at the next station
HASH_STOPPED: .BYTE 1 ; flag wether hash is stopping, 0 = stopped, otherwise not stopped

;DEFINING VARIABLES
.DEF to_hold = r11
.DEF two_led = r12
.DEF int_flag = r13
.DEF comparator = r14
.DEF int_temp = r15
.DEF temp = r16
.DEF row = r17
.DEF col = r18
.DEF mask = r19
.DEF temp2 = r20
.DEF variable = r21
.DEF memory = r22
.DEF flags = r23
.DEF lowbyte = r24
.DEF highbyte = r25

;DEFINING CONSTANTS
.EQU PORTLDIR = 0xF0; 0b11110000
.EQU INITCOLMASK = 0xEF; 0b11101111
.EQU INITROWMASK = 0x01; 0b00000001
.EQU ROWMASK = 0x0F; 0b00001111
.EQU LCD_RS = 7
.EQU LCD_E = 6
.EQU LCD_RW = 5
.EQU LCD_BE = 4
.EQU BUTTON_SIZE = 3
.EQU MOTOR_START = 60

;LCD COMMANDS (MACROS)
.MACRO lcd_set
	SBI PORTA, @0
.ENDMACRO

.MACRO lcd_clr
	CBI PORTA, @0
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

.MACRO do_lcd_data_direct
	LDI temp, @0
	RCALL lcd_data
	RCALL lcd_wait
.ENDMACRO

;MEMORY COMMANDS (MACROS)
.MACRO move_onebyte; NAMETO, NAMEFROM
	reset_z @1
	LD memory, z
	reset_z @0
	ST z, memory
.ENDMACRO

.MACRO print_station ; index
	do_lcd_command 0b00000001
	set_z STATION_LENGTH, 1, @0
	LD variable, z
	PUSH variable
	set_z STATION_ARRAY, 10, @0
	POP variable
	CLR temp2

	STILL_PRINTING:
	LD memory, z+
	do_lcd_data memory
	INC temp2
	CP temp2, variable
	BRLT STILL_PRINTING
.ENDMACRO

.MACRO store_to_onebyte; NAME, VALUE
	reset_z @0
	LDI variable, @1
	ST z, variable
.ENDMACRO

.MACRO multiply_onebyte_ten; NAME
	reset_z @0
	LD memory, z
	LDI variable, 10
	MUL memory, variable
	ST z, r0
.ENDMACRO

.MACRO add_to_onebyte; NAME, VALUE
	reset_z @0
	LDI variable, @1
	LD memory, z
	ADD variable, memory
	ST z, variable
.ENDMACRO

.MACRO subtract_from_onebyte; NAME, VALUE
	reset_z @0
	LD memory, z
	LDI variable, @1
	SUB memory, variable
	ST z, memory
.ENDMACRO

.MACRO is_zero; NAME, INSTRUCTION
	reset_z @0
	LD memory, z
	CPI memory, 0
	BREQ JUMP_SOMEWHERE
	JMP FINISH_IS_ZERO_MACRO

	JUMP_SOMEWHERE: JMP @1

	FINISH_IS_ZERO_MACRO:
.ENDMACRO

.MACRO is_how_much; NAME, number, INSTRUCTION
	reset_z @0
	LD memory, z
	CPI memory, @1
	BREQ JUMP_SOMEWHERE
	JMP FINISH_IS_ZERO_MACRO

	JUMP_SOMEWHERE: JMP @2
	FINISH_IS_ZERO_MACRO:
.ENDMACRO

.MACRO clear_onebyte; NAME
	reset_z @0
	CLR variable
	ST z, variable
.ENDMACRO

.MACRO add_to_array; arrayname, element_size, current_length, addded
	LDI memory, @2
	set_z @0, @1, memory
	LDI variable, @3
	ST z+, variable
	CLR variable
.ENDMACRO

.MACRO add_reg_to_array; arrayname, element_size, current_length, addded
	PUSH flags
	MOV flags, @2
	set_z @0, @1, flags
	MOV variable, @3
	ST z+, variable
	CLR variable
	POP flags
.ENDMACRO

.MACRO reset_z; MEMORY NAME
	LDI zh, high(@0)
	LDI zl, low(@0)
.ENDMACRO

.MACRO reset_y; MEMORY NAME
	LDI yh, high(@0)
	LDI yl, low(@0)
.ENDMACRO

.MACRO reset_x; MEMORY NAME
	LDI xh, high(@0)
	LDI xl, low(@0)
.ENDMACRO

.MACRO clear_names; NAME, size
	LDI memory, 32
	clear_onebyte COUNTER
	reset_z @0
	CLR variable

	CLEARING:
	ST z+, memory
	INC variable
	CPI variable, @1
	BRNE CLEARING
.ENDMACRO

.MACRO clear_array; NAME, size
	LDI memory, 0
	clear_onebyte COUNTER
	reset_z @0
	CLR variable

	CLEARING:
	ST z+, memory
	INC variable
	CPI variable, @1
	BRNE CLEARING
.ENDMACRO

.MACRO clear_twobyte; NAME
	reset_z @0
	CLR variable
	ST z+, variable
	ST z, variable
.ENDMACRO

.MACRO store_station_name ; ARRAY, STATION, currentindex
	set_z @0, 10, @2
	reset_x STATION
	CLR variable

	MOVE_NAME:
	LD memory, x+
	ST z+, memory
	INC variable
	CPI variable, 10
	BRLT MOVE_NAME
.ENDMACRO

.MACRO add_to_twobyte; NAME, VALUE
	reset_z @0
	LDI variable, low(@1)
	LDD memory, z+1
	ADD variable, memory
	STD z+1, variable
	LDI variable, high(@1)
	LD memory, z
	ADC variable, memory
	ST z, variable
.ENDMACRO

.MACRO set_z; arrayname, element_size, index
	reset_z @0
	LDI variable, @1
	MOV memory, @2
	MUL variable, memory 
	CLR variable
	MOV memory, r0
	CPI memory, 0
	BREQ FINISH_set_z

	MOVE_NEXT:
	LD memory, z+
	INC variable
	CP variable, r0
	BRLT MOVE_NEXT

	FINISH_set_z:
	CLR variable
	CLR memory
.ENDMACRO

.MACRO twobyte_to_register; NAME, REG_h, REG_l
	reset_z @0
	LD @1, z+
	LD @2, z
.ENDMACRO

.MACRO determine_button; col, row
	reset_z PRESSED
	MOV variable, row
	LDI memory, 3
	MUL variable, memory
	MOV memory, col
	INC memory
	ADD r0, memory
	ST z, r0
.ENDMACRO

.MACRO add_reg_onebyte ; NAME, REG
	MOV variable, @1
	reset_z @0
	LD memory, z
	ADD memory, variable
	ST z, memory
.ENDMACRO

.MACRO onebyte_to_register; NAME, REG
	reset_z @0
	LD @1, z
.ENDMACRO

.MACRO register_to_onebyte; NAME, REG
	reset_z @0
	ST z, @1
.ENDMACRO

.MACRO determine_index_letter; NO INPUT, pressed_button*3 + repeat_button
	reset_z PRESSED
	LD variable, z
	LDI memory, 3
	MUL variable, memory
	reset_z REPEAT_BUTTON
	LD variable, z
	ADD r0, variable
	reset_z INDEX
	ST z, r0
	CLR memory
.ENDMACRO

.MACRO make_letters
	add_to_array ARRAY_LETTERS, 1, 0, 'Q'
	add_to_array ARRAY_LETTERS, 1, 1, 'Z'
	add_to_array ARRAY_LETTERS, 1, 2, 32
	add_to_array ARRAY_LETTERS, 1, 3, '-'
	add_to_array ARRAY_LETTERS, 1, 4, '_'
	add_to_array ARRAY_LETTERS, 1, 5, '.'
	add_to_array ARRAY_LETTERS, 1, 6, 'A'
	add_to_array ARRAY_LETTERS, 1, 7, 'B'
	add_to_array ARRAY_LETTERS, 1, 8, 'C'
	add_to_array ARRAY_LETTERS, 1, 9, 'D'
	add_to_array ARRAY_LETTERS, 1, 10, 'E'
	add_to_array ARRAY_LETTERS, 1, 11, 'F'
	add_to_array ARRAY_LETTERS, 1, 12, 'G'
	add_to_array ARRAY_LETTERS, 1, 13, 'H'
	add_to_array ARRAY_LETTERS, 1, 14, 'I'
	add_to_array ARRAY_LETTERS, 1, 15, 'J'
	add_to_array ARRAY_LETTERS, 1, 16, 'K'
	add_to_array ARRAY_LETTERS, 1, 17, 'L'
	add_to_array ARRAY_LETTERS, 1, 18, 'M'
	add_to_array ARRAY_LETTERS, 1, 19, 'N'
	add_to_array ARRAY_LETTERS, 1, 20, 'O'
	add_to_array ARRAY_LETTERS, 1, 21, 'P'
	add_to_array ARRAY_LETTERS, 1, 22, 'R'
	add_to_array ARRAY_LETTERS, 1, 23, 'S'
	add_to_array ARRAY_LETTERS, 1, 24, 'T'
	add_to_array ARRAY_LETTERS, 1, 25, 'U'
	add_to_array ARRAY_LETTERS, 1, 26, 'V'
	add_to_array ARRAY_LETTERS, 1, 27, 'W'
	add_to_array ARRAY_LETTERS, 1, 28, 'X'
	add_to_array ARRAY_LETTERS, 1, 29, 'Y'
.ENDMACRO

.MACRO motor_action
	reset_z MOTOR_MOVING
	LD variable, z
	CPI variable, 0
	BREQ MOTOR_STOPS
	JMP MOTOR_MOVES

	MOTOR_STOPS:
	CLR variable
	STS OCR3BL, variable
	STS OCR3BH, variable
	JMP FINISH_MOTOR_ACTION

	MOTOR_MOVES:
	LDI variable, MOTOR_START
	STS OCR3BL, variable
	CLR variable
	STS OCR3BH, variable
	JMP FINISH_MOTOR_ACTION

	FINISH_MOTOR_ACTION:
.ENDMACRO

.MACRO two_led_action
	LDS int_flag, MOTOR_MOVING
	LDS to_hold, EMPTY
	CP int_flag, to_hold
	BREQ ALMOST_FINISH_TWO_LED_BLINK

	;if motor is moving
	LDS to_hold, EMPTY
	CP two_led, to_hold
	BREQ TURNING_ON_LED
	JMP TURNING_OFF_LED

	TURNING_ON_LED:
	LDS two_led, ALL_ONES
	OUT PORTG, two_led
	JMP FINISH_TWO_LED_BLINK

	TURNING_OFF_LED:
	LDS two_led, EMPTY
	OUT PORTG, two_led
	JMP FINISH_TWO_LED_BLINK

	ALMOST_FINISH_TWO_LED_BLINK:
	CLR two_led
	OUT PORTG, two_led

	FINISH_TWO_LED_BLINK:
.ENDMACRO

;CODE BEGINS
.CSEG
JMP RESET

.ORG OVF0addr
JMP Timer0OVF

.ORG INT0addr
JMP EXT_INT0

.ORG INT1addr
JMP EXT_INT1

.ORG 0X72
RESET: ;MAINRESET
	
	;SETUP STACK
	LDI temp, low(RAMEND)
	OUT SPL, temp
	LDI temp, high(RAMEND)
	OUT SPH, temp

	;INITIALIZE MEMORIES
	clear_onebyte MODE
	clear_onebyte PRESSED
	clear_onebyte REPEAT_BUTTON
	clear_onebyte NUMBER_INPUT
	clear_onebyte INDEX
	clear_onebyte COUNTER
	clear_onebyte LENGTH
	clear_onebyte REPETITION
	clear_onebyte NUMBER_PRESSED
	clear_onebyte EMPTY
	clear_onebyte STOP_TIME
	clear_onebyte NUM
	clear_names STATION_ARRAY, 100
	clear_onebyte CURRENT
	clear_array STATION_LENGTH, 10
	clear_onebyte TIMER_CURRENT
	clear_onebyte TIMER_TARGET
	clear_onebyte TIMER_COUNTING
	clear_twobyte TIMER_INTERRUPT
	clear_onebyte MOTOR_MOVING
	clear_onebyte HASH_STOPPED
	clear_onebyte MOTOR_STOP
	add_to_onebyte CURRENT, 40
	store_to_onebyte ALL_ONES, 15

	;ACTIVATE KEYPAD
	LDI temp, PORTLDIR; 0b11110000
	STS DDRL, temp

	;ACTIVATE LED
	CLR temp
	OUT PORTC, temp ; Write ones to all the LEDs
	SER temp
	OUT DDRC, temp ; PORTC is all outputs
	CLR temp
	OUT PORTG, temp ; Write ones to all the LEDs
	SER temp
	OUT DDRG, temp ; PORTC is all outputs

	;ACTIVATE PB BUTTONS
	SER temp
	OUT PORTD, temp ; Enable pull-up resistors on PORTD
	CLR temp
	OUT DDRD, temp ; PORTD is all inputs

	;ACTIVATE LCD
	SER temp
	OUT DDRF, temp
	OUT DDRA, temp
	CLR temp
	OUT PORTF, temp
	OUT PORTA, temp

	;INITIALIZE LCD
	do_lcd_command 0b00111000 ; 2x5x7
	RCALL sleep_5ms
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001110 ; Cursor on, bar, no blink

	;INITIALIZE BUTTON LETTERS
	make_letters

	;ACTIVATE TIMER0
	CLR temp
	OUT TCCR0A, temp ; timer
	LDI temp, 2 ; prescaling value
	OUT TCCR0B, temp
	LDI temp, 1 ; enable overflow interrupt
	STS TIMSK0, temp

	;ACTIVATE PWM
	SER temp
	OUT DDRE, temp ; set porte all output
	LDI temp, 0
	STS OCR3BL, temp ; OC3B low register
	STS OCR3BH, temp ; 0C3B high register
	LDI temp, 0b00000001 ; CS30 = 1: no prescaling
	STS TCCR3B, temp ; set the prescaling value
	LDI temp, 0b00100001 ; (1<<WGM30)|(1<<COM3B1)
	;WGM30=1: phase correct PWM, 8 bits
	;COM3B1=1: make OC3B override the normal port functionality of the I/O pin PE2
	STS TCCR3A, temp

	;ACTIVATE INTERRUPT 0 AND 1
	LDI temp, 0b00001010
	STS EICRA, temp
	IN temp, EIMSK
	ORI temp, 0b00000011
	OUT EIMSK, temp

	SEI
JMP PROGRAM

PROGRAM:
	; get number of stations, MODE number
	GET_STATION_TOTAL:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data_direct 'N'
	do_lcd_data_direct 'U'
	do_lcd_data_direct 'M'
	do_lcd_data_direct ' '
	do_lcd_data_direct 'S'
	do_lcd_data_direct 'T'
	do_lcd_data_direct 'A'
	do_lcd_data_direct 'T'
	do_lcd_data_direct 'I'
	do_lcd_data_direct 'O'
	do_lcd_data_direct 'N'
	do_lcd_data_direct 'S'
	do_lcd_data_direct ':'
	store_to_onebyte MODE, 0
	RCALL MAIN ; get keyboard input
	; CHECK INPUT LESS THAN 10
	reset_z NUMBER_INPUT
	LD temp, z
	CPI temp, 11
	BRLT VALID_STATION_NUMBER
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data_direct 'M'
	do_lcd_data_direct 'A'
	do_lcd_data_direct 'X'
	do_lcd_data_direct ' '
	do_lcd_data_direct '1'
	do_lcd_data_direct '0'

	RCALL display_delay
	do_lcd_command 0b00000001 ; clear display
	JMP GET_STATION_TOTAL

	VALID_STATION_NUMBER:
	is_zero NUMBER_INPUT, GET_STATION_TOTAL

	move_onebyte STATION_TOTAL, NUMBER_INPUT
	do_lcd_command 0b00000001 ; clear display

	;get station names
	store_to_onebyte MODE, 1

	ALL_STATION_NAME:
	reset_z REPETITION
	LD temp, z
	reset_z STATION_TOTAL
	LD temp2, z
	CP temp, temp2 
	BRLT GET_STATION_NAME
	JMP ALL_STATION_TIME

	GET_STATION_NAME:
	PUSH temp
	do_lcd_data_direct 'S'
	POP temp
	LDI temp2, 48
	ADD temp, temp2
	do_lcd_data temp
	do_lcd_data_direct ':'
	RCALL MAIN
	add_to_onebyte REPETITION, 1
	JMP ALL_STATION_NAME
	
	;get time between stations
	ALL_STATION_TIME:
	store_to_onebyte MODE, 0
	clear_onebyte REPETITION

	MORE_STATION_TIME:
	do_lcd_command 0b00000001 ; clear display
	reset_z REPETITION
	LD temp, z
	reset_z STATION_TOTAL
	LD temp2, z
	CP temp, temp2
	BRLT GET_STATION_TIME
	JMP GET_STOP_TIME

	GET_STATION_TIME:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data_direct 'T'
	do_lcd_data_direct 'I'
	do_lcd_data_direct 'M'
	do_lcd_data_direct 'E'
	do_lcd_data_direct ' '
	reset_z REPETITION
	LD temp, z
	LDI temp2, 48
	ADD temp, temp2
	do_lcd_data temp
	do_lcd_data_direct ':'
	RCALL MAIN

	; check 10 or less
	onebyte_to_register NUMBER_INPUT, temp
	CPI temp, 11
	BRLT VALID_TIME_INPUT

	;if invalid set time to 10
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data_direct 'M'
	do_lcd_data_direct 'A'
	do_lcd_data_direct 'X'
	do_lcd_data_direct ' '
	do_lcd_data_direct '1'
	do_lcd_data_direct '0'
	RCALL display_delay
	do_lcd_command 0b00000001 ; clear display
	JMP MORE_STATION_TIME

	;if valid move to array
	VALID_TIME_INPUT: 
	is_zero NUMBER_INPUT, GET_STATION_TIME
	reset_z NUMBER_INPUT 
	LD temp2, z
	reset_z REPETITION
	LD temp, z
	add_reg_to_array STATION_TIME, 1, temp, temp2
	add_to_onebyte REPETITION, 1
	JMP MORE_STATION_TIME


	GET_STOP_TIME:
	clear_onebyte REPETITION
	store_to_onebyte MODE, 0
	do_lcd_data_direct 'S'
	do_lcd_data_direct 'T'
	do_lcd_data_direct 'O'
	do_lcd_data_direct 'P'
	do_lcd_data_direct ' '
	do_lcd_data_direct 'T'
	do_lcd_data_direct 'I'
	do_lcd_data_direct 'M'
	do_lcd_data_direct 'E'
	do_lcd_data_direct ':'
	RCALL MAIN

	;has to be 5 or less
	LDI temp2, 5
	onebyte_to_register NUMBER_INPUT, temp
	CP temp2, temp; is input > 5
	BRLT STOP_TOO_LONG; if input > 5
	JMP SECOND_STOP_TIME_CHECK

	STOP_TOO_LONG:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data_direct 'M'
	do_lcd_data_direct 'A'
	do_lcd_data_direct 'X'
	do_lcd_data_direct ' '
	do_lcd_data_direct '5'

	RCALL display_delay
	do_lcd_command 0b00000001 ; clear display
	JMP GET_STOP_TIME

	;has to be 2 or more
	SECOND_STOP_TIME_CHECK:
	LDI temp2, 2
	onebyte_to_register NUMBER_INPUT, temp
	CP temp, temp2; is input < 2
	BRLT STOP_TOO_SHORT; if input < 2
	JMP VALID_STOP_TIME

	STOP_TOO_SHORT:
	do_lcd_command 0b00000001 ; clear display
	do_lcd_data_direct 'M'
	do_lcd_data_direct 'I'
	do_lcd_data_direct 'N'
	do_lcd_data_direct ' '
	do_lcd_data_direct '2'

	RCALL display_delay
	do_lcd_command 0b00000001 ; clear display
	JMP GET_STOP_TIME

	VALID_STOP_TIME:
	is_zero NUMBER_INPUT, GET_STOP_TIME
	onebyte_to_register NUMBER_INPUT, temp
	reset_z STOP_TIME
	ST z, temp


; FINISHED SETUP 
START_RUNNING_PROGRAM:
clear_onebyte REPETITION

;IN TESTING PROCESS
RUNNING_PROCESS:
onebyte_to_register REPETITION, flags
print_station flags
store_to_onebyte MOTOR_MOVING, 1
motor_action

CHECKING_TIME_YET:
RCALL CHECK_HASH
NOP
NOP
NOP
NOP
store_to_onebyte TIMER_COUNTING, 1
onebyte_to_register TIMER_CURRENT, temp
onebyte_to_register TIMER_TARGET, temp2
CP temp, temp2
BRLT CHECKING_TIME_YET
store_to_onebyte TIMER_COUNTING, 0
JMP AT_NEXT_STATION

AT_NEXT_STATION:
;pausing time and resetting time
clear_onebyte TIMER_COUNTING ; stop counting
clear_onebyte TIMER_CURRENT ; reset timer
clear_twobyte TIMER_INTERRUPT ; reset interrupts

;display name of next station
onebyte_to_register REPETITION, flags
INC flags

;check if last station
onebyte_to_register STATION_TOTAL, temp
CP flags, temp
BREQ LAST_STATION_DISP_NEXT
JMP PRINT_STATION_NAME

LAST_STATION_DISP_NEXT: 
	CLR flags
	JMP PRINT_STATION_NAME

PRINT_STATION_NAME:
print_station flags

;check if it needs to stop
onebyte_to_register MOTOR_STOP, flags
CPI flags, 1
BREQ MOTOR_STOPPED
JMP NOT_STOPPING

;if it needs to stop
MOTOR_STOPPED:
clear_onebyte MOTOR_MOVING
motor_action

CHECK_FINISH_STOPPING:
store_to_onebyte TIMER_COUNTING, 1
NOP
NOP
NOP
NOP
onebyte_to_register TIMER_CURRENT, temp
onebyte_to_register STOP_TIME, temp2
CP temp, temp2
BRLT CHECK_FINISH_STOPPING

clear_onebyte MOTOR_STOP
clear_onebyte TIMER_COUNTING
clear_onebyte TIMER_CURRENT
clear_twobyte TIMER_INTERRUPT
store_to_onebyte MOTOR_MOVING, 1
motor_action
clear_onebyte TIMER_COUNTING

;get target time
NOT_STOPPING:
onebyte_to_register REPETITION, flags
set_z STATION_TIME, 1, flags
LD temp, z
register_to_onebyte TIMER_TARGET, temp

;move to next station
add_to_onebyte REPETITION, 1
;if last station
onebyte_to_register REPETITION, temp
onebyte_to_register STATION_TOTAL, temp2
CP temp, temp2
BREQ LAST_STATION_RESET_INDEX
JMP CHECKING_TIME_YET

LAST_STATION_RESET_INDEX:
clear_onebyte REPETITION
JMP CHECKING_TIME_YET

FINISH_PROGRAM: RJMP FINISH_PROGRAM

MAIN: ; CHECKS KEYBOARD INPUT
	RCALL main_delay ; for debouncing
	RCALL main_delay ; for debouncing
	RCALL main_delay ; for debouncing
	RCALL main_delay ; for debouncing
	LDI mask, INITCOLMASK ; 0b11101111
	CLR col

	COLLOOP: ; LOOPS TO CHECK PRESSED COLUMN
	STS PORTL, mask ; set column to mask value initially 0b11110000
	LDI temp, 0xFF ; count down to 0 for delay

	DELAY:
	DEC temp
	BRNE delay

	; CONTINUE COLLOOP
	LDS temp, PINL ; read PORTL
	ANDI temp, ROWMASK ; 0b00001111 read row only
	CPI temp, 0xF ; 0b00001111 check if any rows are grounded
	BREQ NEXTCOL ; if no rows are grounded check next column
	LDI mask, INITROWMASK ; if one is grounded find the row
	CLR row

	ROWLOOP: ; LOOPS TO CHECK PRESSED ROW
	MOV temp2, temp ; temp is all 0s except the grounded one
	AND temp2, mask ; mask is 0b00000001
	BRNE NEXTROW ; if not equal 
	RJMP ACTION ; if row is found ORIGINALLY RCALL
	JMP MAIN

	NEXTROW: ; check next row
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
	BREQ JMP_LETTERS
	CPI row, 3 ; if last row then symbols
	BREQ JMP_SYMBOLS 
	RJMP JMP_NUMBERS ; otherwise numbers

	JMP_LETTERS: JMP LETTERS
	JMP_SYMBOLS: JMP SYMBOLS
	JMP_NUMBERS: JMP NUMBERS
FINISH_MAIN:
RET
HALT: RJMP HALT

; IF LETTERS WERE PRESSED
LETTERS:
	CPI row, 0
	BREQ JMP_LETA
	CPI row, 1
	BREQ JMP_LETB
	CPI row, 2
	BREQ JMP_LETC
	CPI row, 3
	BREQ JMP_LETD

	JMP_LETA: JMP LETA
	JMP_LETB: JMP LETB
	JMP_LETC: JMP LETC
	JMP_LETD: JMP LETD

	LETA: ; adds a letter to station, increment counter for name length, maximum 10 letters
	reset_z MODE
	LD flags, z
	CPI flags, 0
	BREQ SAVE_NUMBER_INPUT

	onebyte_to_register LENGTH, temp
	onebyte_to_register LETTER, temp2
	add_reg_to_array STATION, 1, temp, temp2; TESTAGAIN LATER
	add_to_onebyte LENGTH, 1


	;resetting letters back to the first
	clear_onebyte REPEAT_BUTTON
	clear_onebyte LETTER 
	store_to_onebyte LETTER, 32 
	clear_onebyte CURRENT
	add_to_onebyte CURRENT, 40
	CPI temp, 9 
	BREQ LETB
	do_lcd_command 0b00010100 ;shift cursor right
	JMP END_LETTERS

	SAVE_NUMBER_INPUT:
		move_onebyte NUMBER_INPUT, NUM
		clear_onebyte NUM
		clear_onebyte NUMBER_PRESSED
	JMP FINISH_MAIN

	LETB: ; stores name length in station_length array, clear length byte, move station to station_array; clear screen
	is_zero MODE, LETA
	is_zero LENGTH, NO_STATION_NAME

	do_lcd_command 0b00000001 ; clear display
	;store length in station_length array
	reset_z REPETITION
	LD temp, z
	reset_z LENGTH
	LD temp2, z
	add_reg_to_array STATION_LENGTH, 1, temp, temp2
	clear_onebyte LENGTH ; clear length array

	;store name in station_name array
	reset_z REPETITION
	LD temp, z
	store_station_name STATION_ARRAY, STATION, temp
	JMP FINISH_MAIN

	NO_STATION_NAME: 
	subtract_from_onebyte REPETITION, 1 
	do_lcd_command 0b00000001 ; clear display 
	JMP FINISH_MAIN

	LETC: 


	LETD: 

	END_LETTERS: JMP MAIN

JMP MAIN

;IF *, 0 OR # WERE PRESSED
SYMBOLS:
	CPI col, 0
	BREQ JMP_STAR
	CPI col, 1
	BREQ JMP_ZERO
	CPI col, 2
	BREQ JMP_HASH

	JMP_ZERO: JMP ZERO
	JMP_STAR: JMP STAR
	JMP_HASH: JMP HASH


	ZERO: 
	LDI row, 0 ; setting index to 0
	LDI col, 255 ; setting index to 0
	JMP NUMBERS

	STAR:

	HASH:
	
	END_SYMBOLS: JMP MAIN

JMP MAIN

;IF NUMBERS WERE PRESSED
NUMBERS:
	reset_z MODE
	LD flags, z
	CPI flags, 1

	;PRINTING LETTER
	BREQ PRINT_LETTER

	PRINT_NUMBER:
	add_to_onebyte NUMBER_PRESSED, 1
	reset_z NUMBER_PRESSED
	is_how_much NUMBER_PRESSED, 3, LETA

	determine_button col, row
	onebyte_to_register PRESSED, temp
	multiply_onebyte_ten NUM
	add_reg_onebyte NUM, temp
	add_to_onebyte PRESSED, 48
	reset_z PRESSED
	LD temp, z
	do_lcd_data temp

	END_NUMBERS: JMP MAIN ; ENDPOINT OF NUMBERS

	PRINT_LETTER:
	determine_button col, row ; changes PRESSED
	onebyte_to_register CURRENT, temp
	onebyte_to_register PRESSED, temp2
	CP temp, temp2
	BREQ BUTTON_REPEATED

	clear_onebyte REPEAT_BUTTON

	FINAL_PRINT_LETTER:
	move_onebyte CURRENT, PRESSED ; current <- pressed
	determine_index_letter ; changes INDEX
	onebyte_to_register INDEX, temp

	set_z ARRAY_LETTERS, 1, temp
	LD temp, z
	register_to_onebyte LETTER, temp ; stores the current input

	do_lcd_data temp
	do_lcd_command 0b00010000 ;shift cursor left
	JMP END_NUMBERS	;

	RESET_REPEAT:
	clear_onebyte REPEAT_BUTTON
	JMP FINAL_PRINT_LETTER

	BUTTON_REPEATED:
	add_to_onebyte REPEAT_BUTTON, 1
	onebyte_to_register REPEAT_BUTTON, temp
	CPI temp, 3
	BREQ RESET_REPEAT
	JMP FINAL_PRINT_LETTER

JMP MAIN



;ADDITIONAL FUNCTIONS
	;push flags before, clear flags, then pop after calling this function
	CHECK_HASH: ; CHECKS KEYBOARD INPUT
	LDI mask, INITCOLMASK ; 0b11101111
	CLR col

	HASH_COLLOOP: ; LOOPS TO CHECK PRESSED COLUMN
	STS PORTL, mask ; set column to mask value initially 0b11110000
	LDI temp, 0xFF ; count down to 0 for delay

	HASH_DELAY:
	DEC temp
	BRNE HASH_DELAY

	; CONTINUE HASH_COLLOOP
	LDS temp, PINL ; read PORTL
	ANDI temp, ROWMASK ; 0b00001111 read row only
	CPI temp, 0xF ; 0b00001111 check if any rows are grounded
	BREQ HASH_NEXTCOL ; if no rows are grounded check next column
	LDI mask, INITROWMASK ; if one is grounded find the row
	CLR row

	HASH_ROWLOOP: ; LOOPS TO CHECK PRESSED ROW
	MOV temp2, temp ; temp is all 0s except the grounded one
	AND temp2, mask ; mask is 0b00000001
	BRNE HASH_NEXTROW ; if not equal 
	RJMP HASH_ACTION ; if row is found ORIGINALLY RCALL
	JMP FINISH_CHECK_HASH

	HASH_NEXTROW: ; check next row
	INC row
	LSL mask ; shift the mask left
	JMP HASH_ROWLOOP 

	HASH_NEXTCOL:
	CPI col, 3 ; check if its the last row
	BREQ JMP_FINISH_CHECK_HASH ; if last row then no button is pressed
	JMP SKIPPING_JUMP

	JMP_FINISH_CHECK_HASH: JMP FINISH_CHECK_HASH

	SKIPPING_JUMP:
	SEC ; set the carry bit
	ROL mask ; shift the column mask to check next column
	INC col ; column number
	JMP HASH_COLLOOP ; if not the last check for the next column

	HASH_ACTION: ; when row is found
	CPI row, 3 ; if last row then check if its hash
	BREQ RIGHT_ROW
	JMP FINISH_CHECK_HASH

	RIGHT_ROW:
	CPI col, 2
	BREQ HASH_PRESSED
	JMP FINISH_CHECK_HASH

	HASH_PRESSED:
	LDS int_flag, HASH_STOPPED
	LDS comparator, EMPTY
	CP int_flag, comparator
	BREQ HASH_STOPPING; if it was stopped, continue moving
	JMP HASH_CONTINUING; otherwise stop

	HASH_CONTINUING:
	store_to_onebyte MOTOR_MOVING, 1
	motor_action
	store_to_onebyte HASH_STOPPED, 0
	JMP FINISH_CHECK_HASH
	
	HASH_STOPPING:
	store_to_onebyte TIMER_COUNTING, 0
	store_to_onebyte MOTOR_MOVING, 0
	motor_action
	two_led_action
	store_to_onebyte HASH_STOPPED, 1
	JMP FINISH_CHECK_HASH
	

	FINISH_CHECK_HASH:
	LDS int_flag, HASH_STOPPED
	LDS comparator, EMPTY
	CP int_flag, comparator
	BRNE START_OVER_CHECK_HASH
	JMP REALLY_FINISH_CHECK_HASH

	START_OVER_CHECK_HASH: JMP CHECK_HASH

	REALLY_FINISH_CHECK_HASH:
	RET

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

main_delay: ; 1 second
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

display_delay:
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
	RCALL main_delay
RET

;FIX TIMER INTERRUPT
Timer0OVF:
	LDS int_temp, TIMER_COUNTING
	LDS comparator, EMPTY
	CP int_temp, comparator
	BRNE PROCESS_TIMER0OVF
	JMP FINISH_TIMER0OVF

	PROCESS_TIMER0OVF:
	;add one to interrupt
	reset_y TIMER_INTERRUPT
	LDI highbyte, 1
	LDD lowbyte, y+1
	ADD lowbyte, highbyte
	STD y+1, lowbyte
	CLR highbyte
	LD lowbyte, y
	ADC lowbyte, highbyte
	ST y, lowbyte

	
	;check if its been 20 seconds
	reset_y TIMER_INTERRUPT
	LDD lowbyte, y+1
	CPI lowbyte, low(651)
	LD lowbyte, y
	LDI highbyte, high(651)
	CPC lowbyte, highbyte
	BREQ TWENTY_SECOND_PASS
	JMP NOT_TWENTY_SECOND

	TWENTY_SECOND_PASS:
	two_led_action


	NOT_TWENTY_SECOND:
	;check if its been one second
	reset_y TIMER_INTERRUPT
	LDD lowbyte, y+1
	CPI lowbyte, low(7812)
	LD lowbyte, y
	LDI highbyte, high(7812)
	CPC lowbyte, highbyte
	BREQ ONE_SECOND_PASS
	JMP FINISH_TIMER0OVF

	ONE_SECOND_PASS:
	;add one to timer_current counter
	reset_y TIMER_CURRENT
	LD lowbyte, y
	INC lowbyte
	ST y, lowbyte

	;clear interrupt counter
	reset_y TIMER_INTERRUPT
	CLR lowbyte
	ST y+, lowbyte
	ST y, lowbyte

	;show current timer
	reset_y TIMER_CURRENT
	LD lowbyte, y
	OUT PORTC, lowbyte

	FINISH_TIMER0OVF:
RETI

EXT_INT0:
	store_to_onebyte MOTOR_STOP, 1
RETI

EXT_INT1:
	store_to_onebyte MOTOR_STOP, 1
RETI