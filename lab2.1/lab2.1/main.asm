.INCLUDE "m2560def.inc"

.DEF quot_h = r15
.DEF quot_l = r14
.DEF dividen_h = r17
.DEF dividen_l = r16
.DEF shift_h = r19
.DEF shift_l = r18
.DEF divisor_h = r21
.DEF divisor_l = r20
.DEF temp_h = r23
.DEF temp_l = r22


.ORG 0x72
.CSEG
;INTIALIZE DATA TO BE USED
LDI divisor_h, high(6000)
LDI divisor_l, low(6000)
LDI dividen_h, high(64004)
LDI dividen_l, low(64004)

;POSDIV FUNCTION
POSDIV:
CLR quot_h			; quotient = 0
CLR quot_l
LDI shift_l, low(1)	; bit_position = 1
LDI shift_h, high(1)

;WHILE (dividend > divisor) AND !(divisor & 0x8000)
LOOP1:
LSL divisor_l				; divisor = divisor << 1
ROL divisor_h
LSL shift_l					; bit_position << 1
ROL shift_h
CP divisor_l, dividen_l		; divisor < dividen
CPC divisor_h, dividen_h
BRLO CONDITION1				; while divisor < dividen
JMP LOOP2

CONDITION1:						; if divisor < dividen
MOVW temp_h:temp_l, divisor_h:divisor_l
ANDI temp_l, low(32768)		;check its not overflowing (2^15)
ANDI temp_h, high(32768)
ADD temp_h, temp_l
CPI temp_h, 0
BREQ REPEAT_LOOP1
JMP LOOP2

REPEAT_LOOP1:
JMP LOOP1


;WHILE (bit_position > 0)
LOOP2:
CP dividen_l, divisor_l		; if dividen >= divisor
CPC dividen_h, divisor_h
BRSH CONDITIONAL1
JMP END_CONDITIONAL1

CONDITIONAL1:				; when dividen >= divisor
SUB dividen_l, divisor_l	; dividen = dividen - divisor
SBC dividen_h, divisor_h
ADD quot_l, shift_l			; quotient = quotient + bit_position
ADC quot_h, shift_h

END_CONDITIONAL1:
LSR divisor_h				; divisor = divisor >> 1
ROR divisor_l
LSR shift_h
ROR shift_l					; bit_position = bit_position >> 1

CONDITION2:					; check if bit_position > 0
CLR temp_h					; temp = 0
CLR temp_l
CP temp_l, shift_l			; 0 < bit_position
CPC temp_h, shift_h
BRLO REPEAT_LOOP2
JMP FINISH_PROGRAM

REPEAT_LOOP2:
JMP LOOP2

FINISH_PROGRAM:
HALT: RJMP HALT