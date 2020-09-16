.INCLUDE "m2560def.inc"

.DSEG
.ORG 0X200
;FOR TESTING
INDIVIDUAL: .BYTE 5
ARRAY: .BYTE 100
ONEBYTE: .BYTE 1
TWOBYTE: .BYTE 2

QUOTIENT: .BYTE 2
REMAINDER: .BYTE 1
NUMBER: .BYTE 2

;DEPENDANCIES
TEMPORARY: .BYTE 2
INDEX: .BYTE 1
.DEF variable = r16
.DEF memory = r17
.DEF temp = r18
.DEF temp2 = r19

;FOR TESTING
.EQU testnum1 = 2487
.EQU testnum2 = 4332
.EQU testnum3 = 54
.EQU testnum4 = 65
.EQU index_search = 4
.EQU element_size = 10

; MOVING POINTERS
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

; ADDING TO MEMORY 
;(depends on reset_z, memory, variable)
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

;(depends on reset_z, memory, variable)
.MACRO add_to_onebyte; NAME, VALUE
	reset_z @0
	LDI variable, @1
	LD memory, z
	ADD variable, memory
	ST z, variable
.ENDMACRO

;(depends on reset_z, memory, variable)
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

;(depends on reset_z, memory, variable)
.MACRO increment_onebyte; NAME
	reset_z @0
	LD memory, z
	INC memory
	ST z, memory
.ENDMACRO

;CLEARING SPACES
;(depends on reset_z, variable)
.MACRO clear_twobyte; NAME
	reset_z @0
	CLR variable
	ST z+, variable
	ST z, variable
.ENDMACRO

;(depends on reset_z, variable)
.MACRO clear_onebyte; NAME
	reset_z @0
	CLR variable
	ST z, variable
.ENDMACRO

;STORING VALUES
;(depends on reset_z, variable)
.MACRO store_to_twobyte; NAME, VALUE
	reset_z @0
	LDI variable, low(@1)
	STD z+1, variable
	LDI variable, high(@1)
	ST z, variable
.ENDMACRO

;(depends on reset_z, variable)
.MACRO store_to_onebyte; NAME, VALUE
	reset_z @0
	LDI variable, @1
	ST z, variable
.ENDMACRO

;SUBTRACTING FROM MEMORY
;(depends on reset_z, memory, variable)
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

;(depends on reset_z, memory, variable)
.MACRO subtract_from_onebyte; NAME, VALUE
	reset_z @0
	LD memory, z
	LDI variable, @1
	SUB memory, variable
	ST z, memory
.ENDMACRO

;(depends on reset_z, memory)
.MACRO decrement_onebyte; NAME
	reset_z @0
	LD memory, z
	DEC memory
	ST z, memory
.ENDMACRO

;(depends on reset_z, memory)
.MACRO decrement_twobyte; NAME
	reset_z @0
	LDD memory, z+1
	SUBI memory, 1
	STD z+1, memory
	LD memory, z
	SBIC memory, 0
	ST z, memory
.ENDMACRO

;MOVE FROM OR TO REGISTER
;(depends on reset_z)
.MACRO register_to_twobyte; NAME, REG_h, REG_l
	reset_z @0
	ST z+, @1
	ST z, @2
.ENDMACRO

;(depends on reset_z)
.MACRO twobyte_to_register; NAME, REG_h, REG_l
	reset_z @0
	LD @1, z+
	LD @2, z
.ENDMACRO

;(depends on reset_z)
.MACRO onebyte_to_register; NAME, REG
	reset_z @0
	LD @1, z
.ENDMACRO

;(depends on reset_z)
.MACRO register_to_onebyte; NAME, REG
	reset_z @0
	ST z, @1
.ENDMACRO

; MOVE TO OTHER SPACE
;(depends on reset_z, memory)
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

;(depends on reset_z, memory)
.MACRO move_onebyte; NAMETO, NAMEFROM
	reset_z @1
	LD memory, z
	reset_z @0
	ST z, memory
.ENDMACRO

;BETWEEN MEMORIES OPERATION
;(depends on reset_z, memory, variable)
.MACRO add_memories; NAMETO, NAMEFROM
	reset_z @1
	LDD variable, z+1
	reset_z @0
	LDD memory, z+1
	ADD variable, memory
	STD z+1, variable
	LD memory, z
	reset_z @1
	LD variable, z
	ADC variable, memory
	reset_z @0
	ST z, variable
.ENDMACRO

;NAMETO -> NAMETO - NAMEFROM
;(depends on reset_z, memory, variable)
.MACRO subtract_memories; NAMETO, NAMEFROM
	reset_z @1
	LDD variable, z+1
	reset_z @0
	LDD memory, z+1
	SUB memory, variable
	STD z+1, memory
	LD memory, z
	reset_z @1
	LD variable, z
	SBC memory, variable
	reset_z @0
	ST z, memory
.ENDMACRO

;MAKE NEGATIVE
;(depend on reset_z, inrement_twobyte, variable)
.MACRO twobyte_signflip; NAME
	reset_z @0
	LD variable, z
	COM variable
	ST z, variable
	LDD variable, z+1
	COM variable
	STD z+1, variable
	increment_twobyte @0
.ENDMACRO

;(depend on reset_z, variable)
.MACRO onebyte_signflip; NAME
	reset_z @0
	LD variable, z
	NEG variable
	ST z, variable
.ENDMACRO

;MULTIPLYING BY 10
;(depends on reset_z, variable, memory, temporary)
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

;MAKE ARRAY
;(depends on reset_z, variable)
.MACRO make_array_3; NAME, element0, element1, element2
	reset_z @0
	LDI variable @1
	ST z+, variable
	LDI variable @2
	ST z+, variable 
	LDI variable, @3
	ST z+, variable
.ENDMACRO


;TO BE REVISED
;(depends on reset_z, set_z)
.MACRO add_to_array; arrayname, element_size, current_length, addded
	set_z @0, @1, @2
	MOV variable, @3
	ST z+, variable
.ENDMACRO

.MACRO multiply_onebyte_ten; NAME
	reset_z @0
	LD memory, z
	LDI variable, 10
	MUL memory, variable
	ST z, r0
.ENDMACRO

;depends on (subtract_from_twobyte, reset_z, clear_onebyte, clear_twobyte, increment_twobyte, move_twobyte)
;divide a twobyte by 10
.MACRO divide_ten ; numbermemory, remaindermemory
clear_onebyte @1
clear_twobyte TEMPORARY
RJMP CHECK_LESS_TEN

MINUS_TEN:
subtract_from_twobyte @0, 10
increment_twobyte TEMPORARY

CHECK_LESS_TEN:
reset_z @0
LD variable, z+ ; highbyte
LD memory, z ; lowbyte

CPI memory, low(10)
LDI memory, high(10)
CPC variable, memory
BRLT FINISH_DIVIDE_TEN
RJMP MINUS_TEN

FINISH_DIVIDE_TEN:
reset_z @0
LDD memory, z+1; lowbyte only <10
reset_z @1
ST z, memory
move_twobyte @0, TEMPORARY
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
CLR variable
CLR memory
.ENDMACRO

.MACRO print_separated ; NUMBER
	clear_onebyte INDEX
	
	RJMP CHECK_SEPARATED
	SEPARATE_AGAIN:
	divide_twobyte_by_onebyte TWOBYTE, REMAINDER, 10
	reset_z INDEX
	LD memory, z
	reset_z REMAINDER
	LD temp, z
	add_to_array INDIVIDUAL, 1, memory, temp
	increment_onebyte INDEX


	CHECK_SEPARATED: 
	reset_z TWOBYTE
	LDD memory, z+1
	CPI memory, low(0)
	LDI variable, high(0)
	CPC memory, variable
	BREQ FINISH_SEPARATE
	JMP JMP_SEPARATE_AGAIN

	JMP_SEPARATE_AGAIN:
	JMP SEPARATE_AGAIN

	FINISH_SEPARATE:
.ENDMACRO

.MACRO add_reg_onebyte ; NAME, REG
	MOV variable, @1
	reset_z @0
	LD memory, z
	ADD memory, variable
	ST z, memory
.ENDMACRO

.MACRO store_station_name ; ARRAY, STATION, currentindex
	set_z @0, 10, @2
	reset_y @1
	CLR variable

	MOVE_NAME:
	LD memory, y+
	ST z+, memory
	INC variable
	CPI variable, 10
	BRLT MOVE_NAME
.ENDMACRO

.MACRO print_station ; index
	set_z STATION_LENGTH, 1, @1
	LD variable, z
	set_z STATION_ARRAY, 10, @1
	PUSH flags
	CLR flags
	
	STILL_PRINTING:
	LD memory, z+
	do_lcd_data memory
	INC flags
	CP flags, variable
	BRLT STILL_PRINTING

	POP flags
.ENDMACRO

.CSEG
store_to_twobyte NUMBER, 899
store_to_twobyte TWOBYTE, 786
add_to_twobyte TWOBYTE, 1
add_to_twobyte TWOBYTE, 1
add_to_twobyte TWOBYTE, 1

clear_twobyte TWOBYTE

HALT: RJMP HALT