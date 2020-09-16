.include "m2560def.inc"


.MACRO shiftleft
	LSL @1
	ROL @0
.ENDMACRO

.DEF temp_h = r23
.DEF temp_l = r22
.DEF mul_h = r17
.DEF mul_l = r16
.DEF mult = r18
.DEF result_h = r21
.DEF result_l = r20

LDI mul_h, high(-4500)
LDI mul_l, low(-4500)
LDI mult, 6
;JMP SIGNED_MULT

UNSIGNED_MULT:
MUL mul_l, mult
MOVW temp_h:temp_l, r1:r0
MULS mul_h, mult
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
ADD temp_l, r0
ADC temp_h, r1
MOVW result_h:result_l, temp_h:temp_l
JMP HALT

SIGNED_MULT:
NEG mult
MUL mul_l, mult
MOVW temp_h:temp_l, r1:r0
MULS mul_h, mult
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
ADD temp_l, r0
ADC temp_h, r1
MOVW result_h:result_l, temp_h:temp_l
COM result_l
COM result_h
LDI temp_l, low(1)
LDI temp_h, high(1)
ADD result_l, temp_l
ADC result_h, temp_h
JMP HALT



HALT: RJMP HALT