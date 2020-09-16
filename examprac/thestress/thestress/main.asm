.INCLUDE "m2560def.inc"
.DEF n = r16
.DEF sum_h = r20
.DEF sum_l = r19


.CSEG
.ORG 0x72
LDI yl, low(RAMEND)
LDI yh, high(RAMEND)
OUT SPH, yh
OUT SPL, yl
CLR sum_h
CLR sum_l
LDI n, 100
RCALL SUM 

HALT: RJMP HALT

SUM:
PUSH yl
PUSH yh
IN yl, SPL
IN yh, SPH
SBIW yh:yl, 1
OUT SPH, yh
OUT SPL, yl
STD y+1, n
CPI n, 0
BREQ EXIT
DEC n
RCALL SUM
LDD n, y+1
SUB sum_l, n
SBCI sum_h, 0
RJMP EPILOGUE


EXIT:
CLR sum_l
CLR sum_h

EPILOGUE:
ADIW yh:yl, 1
OUT SPH, yh
OUT SPL, yl
POP yh
POP yl
RET

