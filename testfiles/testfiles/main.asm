.INCLUDE "m2560def.inc"


.DSEG
.ORG 0x200
COUNT: .BYTE 2

.CSEG
.ORG 0x072
TEST: .DB low(455), high(455), low(776), high(776), low(555), high(555), low(332), high(332)
LDI zl, low(TEST << 1)
LDI zh, high(TEST << 1)
LPM r16, z+
LPM r16, z+
LPM r16, z+
LPM r16, z+
LPM r16, z+
LPM r16, z+
LPM r16, z+
LPM r16, z+
HALT: RJMP HALT