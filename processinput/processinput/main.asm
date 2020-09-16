.INCLUDE "m2560def.inc"

.DSEG
.ORG 0x200
RESULT: .BYTE 2

.CSEG
.EQU num1 = 2000
.EQU num2 = 200
.EQU num3 = 9
.EQU num4 = 2
.EQU num5 = 8 
.DEF NUM = r16
.DEF TEMP = r17

NUMONE:
LDI zl, low(RESULT)
LDI zh, high(RESULT)

LDI TEMP, low(num1)
LDD NUM, z+1

ADD TEMP, NUM
STD z+1, TEMP
LDI zl, low(RESULT)
LDI zh, high(RESULT)

LDI TEMP, high(num1)
LD NUM, z

ADC TEMP, NUM
ST z, TEMP


NUMTWO:
LDI zl, low(RESULT)
LDI zh, high(RESULT)

LDI TEMP, low(num2)
LDD NUM, z+1

ADD TEMP, NUM
STD z+1, TEMP
LDI zl, low(RESULT)
LDI zh, high(RESULT)

LDI TEMP, high(num2)
LD NUM, z

ADC TEMP, NUM
ST z, TEMP


HALT: RJMP HALT


