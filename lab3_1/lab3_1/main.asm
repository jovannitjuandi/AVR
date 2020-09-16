;Lab 3.1

.include "m2560def.inc"
.def first = r18
.def second = r17

ldi first, 50
ldi second, 20

while:
	cp second, first
	brlt more
	
	cp first, second
	brlt less

	cp second, first
	brne while
	breq end


less:
	sub second, first
	rjmp while

more:
	sub first, second
	rjmp while

end: rjmp end