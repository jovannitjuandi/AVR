; LAB 2.2

;tst then brvs to check overflow
.include "m2560def.inc"

.DSEG
.ORG 0x200
array: .BYTE 12
.DEF temp = r16
.DEF k = r17 ; x equivalent
.DEF n = r18
.DEF res_h = r20
.DEF res_m = r21
.DEF res_l = r22
.DEF t_h = r19
.DEF t_l = r23
.DEF zero = r24
.DEF count = r25

.CSEG
LDI n, 5
LDI k, 5 

CLR res_h
CLR res_m
CLR res_l
CLR zero

.MACRO RESET
	LDI yl, low(array)
	LDI yh, high(array)
.ENDMACRO

.MACRO FILL 
	LDI temp, @0
	ST y+, temp
.ENDMACRO

RESET
FILL 100
FILL -60
FILL 120
FILL -100
FILL 50
FILL -70
RESET

LD temp, y+
EVALUATE:
	INC count
	MULS res_l, k
	MOV t_l, r0
	MOV t_h, r1
	MULS res_m, k
	CLC
	MOV res_l, t_l
	MOV res_m, t_h
	CLC
	ADD res_m, r0
	ADC res_h, r1
	CLC
	TST temp
	BRMI MINUS
	ADD res_l, temp
	ADC res_m, zero
	ADC res_h, zero
	LD temp, y+
	CP count, n
	BRLT EVALUATE

	CP res_h, zero
	BRNE SETR20

	SETR20:
	LDI r20, 1

	MINUS:
	ADD res_l, temp
	ADD res_m, zero
	ADD res_h, zero
	LD temp, y+
	CP count, n
	BRLT EVALUATE



END: RJMP END



LD temp, y+
	MULS temp, k
	ADD res_l, r0
	ADC res_m, r1
	MULS t_h, k
	ADD res_m, r0
	ADC res_h, r1