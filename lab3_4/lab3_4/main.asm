;Lab 3.4

.include "m2560def.inc"

.DSEG
.ORG 0x200
mata: .BYTE 25
.ORG 0x300
matb: .BYTE 25
.ORG 0x400
matc: .BYTE 50

.EQU len = 5
.DEF i = r16
.DEF j = r17
.DEF debug = r18
.DEF zero = r19
.DEF content = r20
.DEF intone = r21
.DEF inttwo = r22
.DEF val1 = r23
.DEF val2 = r24


.CSEG
CLR i
LDI xl, low(mata)
LDI xh, high(mata)
LDI yl, low(matb)
LDI yh, high(matb)
LDI zl, low(matc)
LDI zh, high(matc)

FILLROW:
CLR j
	FILLCOLLUMN:
	MOV content, i
	ADD content, j
	ST x+, content
	SUB content, j
	SUB content, j
	ST y+, content
	SUB content, i
	ST z+, zero
	ST z+, zero
	INC j
	CPI j, len
	BRLT FILLCOLLUMN
INC i
CPI i, len
BRLT FILLROW

CLR i
CLR j
CLR val1
CLR val2
LDI zl, low(mata)
LDI zh, high(mata)
LDI yl, low(matb)
LDI yh, high(matb)
LDI xl, low(matc)
LDI xh, high(matc)

PRODUCT:
INC i
LD intone, z+
LD inttwo, y
ADIW y, 5
MUL intone, inttwo
ADD val1, r0
ADC val2, r1
CPI i, len
BRLT PRODUCT

MOVING:
CLR i
SBIW y, 19
INC j
ST x+, val2
ST x+, val1
CLR val1
CLR val2
CPI j, 25
BRLT PRODUCT

END: RJMP END