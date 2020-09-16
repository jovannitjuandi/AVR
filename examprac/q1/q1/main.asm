.INCLUDE "m2560def.inc"

.DSEG
.ORG 0x200
ARRAY: .BYTE 20
.EQU size = 10
.DEF th = r17
.DEF tl = r16
.DEF look_h = r19
.DEF look_l = r18
.DEF occurence = r20
.DEF index = r21


.CSEG
.ORG 0x72
MAKE_ARRAY:					
LDI poly_in, 100
ST z+, poly_in					; poly [0] = 100
LDI poly_in, -60
ST z+, poly_in					; poly [0] = -60
LDI poly_in, 120
ST z+, poly_in					; poly [0] = 120
LDI poly_in, -100
ST z+, poly_in					; poly [0] = -100
LDI poly_in, 50
ST z+, poly_in					; poly [0] = 50
LDI poly_in, -70
ST z, poly_in					; poly [0] = -70
LDI zl, low(POLY)	
LDI zh, high(POLY)

