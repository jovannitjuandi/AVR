.INCLUDE "m2560def.inc"

.DEF count = r16
.DEF a = r17
.DEF b = r18
.DEF c = r19
.DEF n = r20


.CSEG
.ORG 0x72
;INITIALIZE STACK POINTER
LDI yl, low(RAMEND)
LDI yh, high(RAMEND)
OUT SPH, yh
OUT SPL, yl

;INITIALIZE DATA
CLR count
LDI n, 8
LDI a, 1
LDI b, 3
LDI c, 2

;START RECURSION
RCALL MOVE
HALT: RJMP HALT

;RECURSION FUNCTION
MOVE:
PUSH yl			; push conflicting register
PUSH yh
IN yl, SPL		; because operations don't work with SP
IN yh, SPH
SBIW yh:yl, 4	; 4 variable a, b, c, n
OUT SPH, yh		; make sure stack pointer is at the top
OUT SPL, yl

;SAVE PARAMETER
STD y+1, n
STD y+2, a
STD y+3, c
STD y+4, b

;CHECK IF 
CPI n, 1
BREQ COUNTER_INCREMENT
JMP GO_ELSE

COUNTER_INCREMENT:
INC count
JMP EPILOGUE

GO_ELSE:
;FIRST RECURSIVE CALL
LDD n, y+1
LDD a, y+2
LDD b, y+3
LDD c, y+4
SUBI n, 1
RCALL MOVE

;SECOND RECURSIVE CALL
LDD n, y+1
LDD a, y+2
LDD c, y+3
LDD b, y+4
LDI n, 1
RCALL MOVE

;THIRD RECURSIVE CALL
LDD n, y+1
LDD b, y+2
LDD c, y+3
LDD a, y+4
SUBI n, 1
RCALL MOVE

EPILOGUE:
ADIW yh:yl, 4	; get the return address
OUT SPH, yh
OUT SPL, yl
POP yh
POP yl
RET