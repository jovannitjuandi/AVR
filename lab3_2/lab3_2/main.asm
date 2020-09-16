;Lab 3.2
.include "m2560def.inc"
.EQU size = 6
.EQU nol = '0'
.DEF zero = r21
.DEF count = r20
.DEF char = r16
.DEF n_h = r19
.DEF n_m = r18
.DEF n_l = r17
.DEF t_h = r22
.DEF t_m = r23
.DEF t_l = r24

START:
LDI zero, 0
str: .DB "325658"
LDI zl, low(str<<1)
LDI zh, high(str<<1)
clr n_h
clr n_m
clr n_l
clr char
clr count

CONVERT:
LPM char, z+
SUBI char, nol
INC count

RCALL SHIFT
MOV t_l, n_l
MOV t_m, n_m
MOV t_h, n_h
RCALL SHIFT
RCALL SHIFT  
ADC n_l, t_l
ADC n_m, t_m
ADC n_h, t_h
ADC n_l, char
CPI count, size
BRLT CONVERT

END: RJMP END

SHIFT:
LSL n_l
ROL n_m
ROL n_h
RET