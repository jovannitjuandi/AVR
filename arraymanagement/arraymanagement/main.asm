.INCLUDE "m2560def.inc"

.DSEG
.ORG 0x200
ARRAY: .BYTE 100; 10 byte element size

.DEF variable = r17
.EQU index = 4

GETITEMNUM:
CLR variable
CPI variable


HALR: RJMP HALT
