.include "m2560def.inc"

LDI r16, 0b00000001
SUBI r16, 1
BRNE HALT
JMP LOOP

LOOP:
NOP
NOP

HALT: RJMP HALT