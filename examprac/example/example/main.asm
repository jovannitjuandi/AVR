.include "m2560def.inc"  
.cseg  
.org 0x72    
ldi yl, low(RAMEND)    ; yl is r28     
ldi yh, high(RAMEND)   ; yh is r29   
out SPH, r29           ; Initialize the stack pointer SP   
out SPL, r28           ; to point to the highest SRAM address  
ldi r16, low(100)      ; Actual parameter 100 is stored r17:r16  
ldi r17, high(100)  
rcall sum              ; Call sum(100)  
loopforever: rjmp loopforever   ; Infinite loop  
  
sum: 
push yl             ; Save Y on the stack       
push yh       
in yl, SPL       
in yh, SPH       
sbiw yh:yl, 2       ; Let Y point to the bottom of the stack frame        
out SPH, yh         ; Update SP so that it points to        
out SPL, yl         ; the new stack top         
std Y+1, r16        ; Pass the actual parameter 100 to the formal parameter n         
std Y+2, r17        ; n is stored in big endian order         
clr r0              ; Set r0 to 0            
cpi r16, 0          ; Compare n with 0       
cpc r17, r0       
breq exit           ; If n=0, go to exit       
subi r16, 1         ; Pass n-1 to the callee       
sbc r17, r0 
rcall sum           ; call sum(n-1)       
ldd r16, Y+1        ; Load n       
ldd r17, Y+2       
sub r19, r16        ; r25:r24=sum(n-1)-n       
sbc r20, r17       
rjmp epilogue 

exit: 
clr r19             ; return 0        
clr r20 

epilogue: 
adiw yh:yl, 2		; Deallocate the stack frame for sum()        
out SPH, yh         ; Restore SP       
out SPL, yl       
pop yh              ; Restore Y using the reverse order of push instructions       
pop yl       
ret                 ; Return from the subroutine, and must 