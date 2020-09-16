;Lab 3.3

.include "m2560def.inc"

.DSEG
.ORG 0x200
array: .BYTE 20
.EQU size = 10
.DEF count = r16
.DEF tot_l = r17
.DEF tot_h = r18
.DEF cur_l = r19
.DEF cur_h = r20
.DEF multiplier = r21


.CSEG
LDI yl, low(array)
LDI yh, high(array)
CLR count
CLR tot_h
CLR tot_l
LDI r21, 200

MAKEARRAY:
MUL r21, count
INC count
ST y+, r1
ST y+, r0
CPI count, size
BRLT MAKEARRAY

CLR count
LDI yl, low(array)
LDI yh, high(array)

ADDING:
LD cur_h, y+
LD cur_l, y+
ADD tot_l, cur_l
ADC tot_h, cur_h
INC count
CPI count, size
BRLT ADDING

END: RJMP END
