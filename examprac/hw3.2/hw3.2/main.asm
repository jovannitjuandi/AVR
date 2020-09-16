.INCLUDE "m2560def.inc"
.DEF n = r16
.DEF sum_h = r20
.DEF sum_l = r19


.CSEG
.ORG 0x72
;INITIALIZE STACK POINTER
LDI yl, low(RAMEND)
LDI yh, high(RAMEND)
OUT SPH, yh
OUT SPL, yl

;INITIALIZE DATA
CLR sum_h
CLR sum_l
LDI n, 100

;START RECURSION
RCALL SUM 
HALT: RJMP HALT

;RECURSION FUNCTION
SUM:
PUSH yl			; push conflicting register
PUSH yh
IN yl, SPL		; because operations don't work with SP
IN yh, SPH
SBIW yh:yl, 1	; 1 variable input
OUT SPH, yh		; make sure stack pointer is at the top
OUT SPL, yl

;SAVE PARAMETER
STD y+1, n

;CHECK IF
CPI n, 0
BREQ EXIT
JMP GO_ELSE

EXIT:
CLR sum_l
CLR sum_h
JMP EPILOGUE

GO_ELSE:
;RECURSIVE CALL
DEC n
RCALL SUM

;ACTIONS AFTER RECURSIVE CALL
LDD n, y+1
SUB sum_l, n
SBCI sum_h, 0
RJMP EPILOGUE

EPILOGUE:
ADIW yh:yl, 1
OUT SPH, yh
OUT SPL, yl
POP yh
POP yl
RET

