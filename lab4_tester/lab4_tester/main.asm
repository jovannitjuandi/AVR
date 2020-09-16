.include "m2560def.inc"

LDI r17, 240
LDI r18, -4
ADD r17, r18






LDI r20, 0

LDI r17, low(277)
LDI r18, high(277)

LDI r19, -120

ADD r18, r19
ADC r17, r20




LDI r19, -5

MULS r17, r19
MOV r20, r0 ; low
MOV r21, r1 ; high

MULS r18, r19
ADD r21, r0
CLR r22
ADC r22, r1

END: RJMP END