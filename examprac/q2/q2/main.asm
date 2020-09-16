.INCLUDE "m2560def.inc"

;DECLARE VARIABLES
.DSEG
.ORG 0x200
.DEF n = r16
.DEF zero = r17
.DEF sum_h = r25
.DEF sum_l = r24

;INITIALIZE STACK POINTER
.CSEG
.ORG 0x72
LDI yl, low(RAMEND)
LDI yh, high(RAMEND)
OUT SPL, yl
OUT SPH, yh

;INITIALIZE VARIABLE
LDI n, 100
LDI zero, 0

;START RECURSION
RCALL SUM
HALT: RJMP HALT

;RECURSIVE FUNCTION
SUM:
;MOVE STACK POINTER
PUSH yl
PUSH yh
IN yl, SPL
IN yh, SPH
SBIW yh:yl, 1
OUT SPL, yl
OUT SPH, yh

;SAVE VARIABLES
STD y+1, n

;CHECK IF
CP zero, n
BRSH EXIT
JMP GO_ELSE

EXIT:
CLR sum_h
CLR sum_l
JMP EPILOGUE

;RECURSIVE CALL
GO_ELSE:
LDD n, y+1
SUBI n, 1
RCALL SUM

;ACTIONS AFTER RECURSIVE CALL
LDD n, y+1
ADD sum_l, n
ADC sum_h, zero

EPILOGUE:
ADIW yh:yl, 1
OUT SPL, yl
OUT SPH, yh
POP yh
POP yl
RET
