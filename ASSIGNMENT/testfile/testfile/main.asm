.DEF grade = r20
.INCLUDE "m2560def.inc"
LDI r29, high(RAMEND)
LDI r28, low(RAMEND)
OUT SPH, r29
OUT SPL, r28
LDI r18, 45
RCALL GRADE_CAL

HALT: RJMP HALT

GRADE_CAL:
PUSH R29
PUSH R28
CPI r18, 50
IN r17, SPL
IN r16, SPH
BRGE grade1
LDI grade, 2
RJMP exit

grade1: LDI grade, 1

exit:
POP r28
POP r29
RET