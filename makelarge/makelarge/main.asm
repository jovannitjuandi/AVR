.INCLUDE "m2560def.inc"

.EQU num1 = 1
.EQU num2 = 3
.EQU num3 = 5
.EQU num4 = 7

;will be negative
.EQU num5 = 2
.EQU num6 = 4
.EQU num7 = 6
.EQU num8 = 8

.EQU num9 = 2
.EQU num10 = 9
.EQU num11 = 2
.EQU num12 = 0

.EQU size = 3
.EQU bytesize = 5

.DEF new = r16
.DEF temp = r19
.DEF temp2 = r20
.DEF temp_h = r18
.DEF temp_l = r17
.DEF input = r21
.DEF negat = r22

.DSEG 
.ORG 0x200
NUMBER: .BYTE 2
QUOTIENT: .BYTE 2
TEMPO: .BYTE 2
TOTAL: .BYTE 2
ARRAY: .BYTE 10
SIGNS: .BYTE 5
INDIVIDUAL: .BYTE 5

.MACRO reset_z
	LDI zh, high(@0)
	LDI zl, low(@0)
.ENDMACRO
.MACRO mul_ten ; low and high registers
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

.MACRO minus_ten
	reset_z @0
	LDD temp, z+1
	SUBI temp, 10
	STD z+1, temp
	LD temp, z
	SBCI temp, 0
	ST z, temp
.ENDMACRO

.MACRO clear_space
	CLR temp2
	reset_z @0
	ST z+, temp2
	ST z, temp2
.ENDMACRO

.MACRO add_number
	reset_z NUMBER
	LDD temp_l, z+1
	LD temp_h, z
	LDI new, @0
	ADD temp_l, new
	LDI new, 0
	ADC temp_h, new

	reset_z NUMBER
	STD z+1, temp_l
	ST z, temp_h
.ENDMACRO

.MACRO move_to_array
	reset_z NUMBER
	LD temp_h, z+
	LD temp_l, z
	ST y+, temp_h
	ST y+, temp_l
	CLR temp_l
	CLR temp_h
	reset_z NUMBER
	ST z+, temp_h
	ST z, temp_l
.ENDMACRO

.MACRO determine_sign
	LDI temp, @0
	ST x+, temp
.ENDMACRO

.MACRO total_array
	CLR new
	LDI yl, low(ARRAY)
	LDI yh, high(ARRAY)
	LDI xl, low(SIGNS)
	LDI xh, high(SIGNS)
	reset_z NUMBER
	ST z+, new
	ST z, new

	TOTALLOOP:
		INC new
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


	COMPARING:
	CPI new, SIZE
	BRLT TOTALLOOP
	reset_z NUMBER
	LD temp_h, z+
	LD temp_l, z
	reset_z TOTAL
	ST z+, temp_h
	ST z, temp_l
.ENDMACRO

.CSEG

LDI yl, low(ARRAY)
LDI yh, high(ARRAY)

LDI xl, low(SIGNS)
LDI xh, high(SIGNS)

reset_z NUMBER

determine_sign 1
add_number num1
mul_ten

add_number num2
mul_ten

add_number num3
mul_ten

add_number num4

move_to_array

determine_sign 0
add_number num5
mul_ten

add_number num6
mul_ten

add_number num7
mul_ten

add_number num8

move_to_array

determine_sign 1
add_number num9
mul_ten

add_number num10
mul_ten

add_number num11
mul_ten

add_number num12

move_to_array

total_array

SEPARATE_TOTAL:
	LDI yl, low(INDIVIDUAL)
	LDI yh, high(INDIVIDUAL)
	JMP SUBTRACT

	INVERT:
	make_negative TOTAL
	LDI negat, 0

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

HALT: RJMP HALT

	JUMP_SUBTRACT:
	JMP SUBTRACT
