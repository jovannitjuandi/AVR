.INCLUDE "m2560def.inc"

.MACRO add_to_test	; number
	LDI j, high(@0)
	LDI i, low(@0)
	ST z+, j
	ST z+, i
.ENDMACRO

.DSEG
.ORG 0x200
TEST: .BYTE 20
.DEF p = r16
.DEF q = r17
.DEF i = r18
.DEF j = r19
.DEF th = r21
.DEF tl = r20
.DEF pivot_h = r23
.DEF pivot_l = r22
.DEF r = r26

.CSEG
.ORG 0X72
;INITIALIZE STACK POINTER
LDI yl, low(RAMEND)
LDI yh, high(RAMEND)
OUT SPH, yh
OUT SPL, yl

;INITIALIZE DATA
LDI zl, low(TEST)
LDI zh, high(TEST)
add_to_test 100
add_to_test 200
add_to_test -70
add_to_test -20
add_to_test 50
add_to_test 30
add_to_test 60
add_to_test -40
add_to_test 100
add_to_test 30
LDI p, 0
LDI r, 9

;START RECURSION
RCALL QUICKSORT
HALT: RJMP HALT

;RECURSION FUNCTION
QUICKSORT:
PUSH yl			; push conflicting register
PUSH yh
IN yl, SPL		; because operations don't work with SP
IN yh, SPH
SBIW yh:yl, 2	; no. of variable 
OUT SPL, yl
OUT SPH, yh

;SAVE PARAMETER
STD y+1, p
STD y+2, r

;CHECK IF
CP p, r
BRLO REPEAT
JMP EPILOGUE_Q

REPEAT:
;FIRST CALL
LDD p, y+1
LDD r, y+2
RCALL PARTITION

;SECOND CALL
LDD p, y+1
LDD r, y+2
RCALL QUICKSORT

;THIRD CALL
LDD p, y+1
LDD r, y+2
RCALL QUICKSORT


EPILOGUE_Q:
ADIW yh:yl, 3
OUT SPH, yh
OUT SPL, yl
POP yh
POP yl
RET

;ADDITIONAL FUNCTION
PARTITION:
PUSH yl
PUSH yh
IN yl, SPL
IN yh, SPH
SBIW yh:yl, 2