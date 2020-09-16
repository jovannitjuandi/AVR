.include "m2560def.inc"
.def temp =r16
.equ PATTERN1 = 0x5B
.equ PATTERN2 = 0xAA

.cseg
.org 0x0
ser temp
out PORTC, temp ; Write ones to all the LEDs
out DDRC, temp ; PORTC is all outputs
out PORTD, temp ; Enable pull-up resistors on PORTD
clr temp
out DDRD, temp ; PORTD is all inputs

switch0:
sbic PIND, 0 ; Skip the next instruction if PB0 is pushed
rjmp switch1 ; If not pushed, check the other switch
ldi temp, PATTERN1 ; Store PATTERN1 to the LEDs if the switch was pushed
out PORTC, temp

switch1:
sbic PIND, 1 ; Skip the next instruction if PB1 is pushed
rjmp switch0 ; If not pushed, check the other switch
ldi temp, PATTERN2 ; Store PATTERN2 to the LEDs if the switch was pushed
out PORTC, temp
rjmp switch0 ; Now check PB0 again