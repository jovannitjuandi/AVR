.INCLUDE "m2560def.inc"

.MACRO shiftleft
	LSL @1
	ROL @0
.ENDMACRO


.DSEG
.ORG 0x300
POLY: .BYTE 6
.DEF neg_flag = r12
.DEF temp_h = r15
.DEF temp_l = r14
.DEF variable = r16
.DEF power = r17
.DEF index = r18
.DEF uno = r19
.DEF result_l = r20
.DEF result_h = r21
.DEF poly_in = r22
.DEF temporary = r13
.DEF ovf_flag = r23

.CSEG
.ORG 0x72
LDI zl, low(POLY)			; signed char[6] poly
LDI zh, high(POLY)
LDI variable, -2			; signed char x = 5
LDI power, 5				; unsigned char n = 5	
LDI index, 1				; unsigned char i = 0
LDI result_l, 0				; short int result = 0
LDI result_h, 0
LDI uno, 1
CLR temporary

MAKE_ARRAY:					; signed char poly[6] = {100, -60, 120, -100, 50, -70}
LDI poly_in, 100
ST z+, poly_in					; poly [0] = 100
LDI poly_in, -60
ST z+, poly_in					; poly [0] = -60
LDI poly_in, 120
ST z+, poly_in					; poly [0] = 120
LDI poly_in, -100
ST z+, poly_in					; poly [0] = -100
LDI poly_in, 50
ST z+, poly_in					; poly [0] = 50
LDI poly_in, -70
ST z, poly_in					; poly [0] = -70
LDI zl, low(POLY)	
LDI zh, high(POLY)

CHECK_VARIABLE:
CPI variable, 0
BRLT NEG_VAR
JMP MAIN

NEG_VAR:
MOV neg_flag, index

MAIN:						; int main()
LD result_l, z+				; result = poly[0]
LOOP1:						; for(int i = 1; i <= n; i++)
CP neg_flag, temporary
BRNE FLIP_FIRST
JMP NO_FLIP

FLIP_FIRST:
NEG variable

NO_FLIP:
INC index					; i++
LD poly_in, z+				; poly[i]
MUL result_l, variable		; result*x
MOVW temp_h:temp_l, r1:r0	; move result_l*x to temporary storage
MULS result_h, variable		; result_h*x
shiftleft r1, r0			; shift 8 times since high bytes
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
shiftleft r1, r0
BRVS OVF_HAPPEN
JMP NO_OVF

OVF_HAPPEN:
SER ovf_flag

NO_OVF:
CP neg_flag, temporary
BRNE REFLIP
JMP NO_REFLIP

REFLIP:
ADD temp_l, r0
ADC temp_h, r1
COM temp_l
COM temp_h
ADD temp_l, uno
ADC temp_h, temporary
NEG variable
JMP NEW_COEF


NO_REFLIP:
ADD temp_l, r0							; result*x
ADC temp_h, r1

NEW_COEF:
CP poly_in, temporary
BRLT NEG_COEF

ADD temp_l, poly_in						; result*x + poly[i]
ADC temp_h, temporary
MOVW result_h:result_l, temp_h:temp_l	; result = result*x + poly[i]
JMP CONDITION1

NEG_COEF:
NEG poly_in
SUB temp_l, poly_in						; result*x + poly[i]
SBC temp_h, temporary
MOVW result_h:result_l, temp_h:temp_l	; result = result*x + poly[i]

CONDITION1:
CP power, index				; n >= i
BRSH LOOP1

FINISH_PROGRAM: RJMP FINISH_PROGRAM