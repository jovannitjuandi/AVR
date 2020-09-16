/*
 * task2.asm
 *
 *  Created: 25/06/2019 2:09:20 PM
 *   Author: Kilam_Lin
 */ 

 .include "m2560def.inc"
 .def temp = r16
 .def temp1 = r17
 .def temp2 = r18
 .def temp3 = r19
 .def temp4 = r21
 .def temp5 = r22
 .def temp6 = r23
 .def temp7 = r24
 .def temp8 = r25

 .def temp_1 = r3
 .def temp_2 = r4
 .def overflow_flag = r20
 .macro load_in_coefficient
	ldi ZL, low(@0<<1) ; load the memory address to Z
	ldi ZH, high(@0<<1)
	ldi XL,low(@1)
	ldi XH,high(@1)
	//Get data poly?
	lds temp,i//temp is 5 in this case
	inc temp//6 elements
	load_coe_loop:
		//if (temp>5)break;
		cpi temp,0
		breq end_load_coe_loop
		lpm temp1,Z+
		st  X+,temp1
		dec temp
		rjmp load_coe_loop
	end_load_coe_loop:
.endmacro

 .dseg
 poly: .byte 6//signed char poly[6] //changeable
 x_var:	   .byte 1//signed char x;
 i:    .byte 1//unsigned char i, n
 n:	   .byte 1//unsigned char i, n
 result: .byte 2//2 bytes signed result
 sign_var: .byte 1//1 pos 0 neg
 sign_result: .byte 1
 sign_expect: .byte 1
 once:		  .byte 1
 .cseg
 rjmp main
 //polynomial const
 constant:			   .db 100,-60,120,-100,50,-70
 variable_const:	   .db 5//x
 counter:			   .db 5//i
 //array_size = #of constants;
 array_size:		   .db 5//n

 main:


	//signed char x = 5;
	ldi ZL,low(variable_const<<1)
	ldi ZH,high(Variable_const<<1)
	lpm temp,Z

	cpi temp,0
	brlt neg_sign_var
	ldi temp1,1
	sts sign_var,temp1
	rjmp done_sign_var
	neg_sign_var:
	ldi temp1,0
	sts once,temp1
	sts sign_var,temp1

	done_sign_var:
	sts x_var,temp
	//unsigned char i, n=5;
	ldi ZL,low(counter<<1)
	ldi ZH,high(counter<<1)
	lpm temp,Z
	sts i,temp
	//unsigned char  n=5;
	ldi ZL,low(array_size<<1)
	ldi ZH,high(array_size<<1)
	lpm temp,Z
	sts n,temp
	//Load in coe
	load_in_coefficient constant,poly
	
	ldi temp,0
	//actual calculation loop
	//result=poly[0];
	lds temp,poly

	cpi temp,0
	brlt neg_sign_poly
	ldi temp1,1
	sts sign_result,temp1
	rjmp done_sign_poly
	neg_sign_poly:
	ldi temp1,0
	sts sign_result,temp1

	done_sign_poly:

	sts result,temp

	//int i = 1;Initialization
	lds temp,i
	// temp//Elements = size + 1;
	ldi XL,low(poly+1)
	ldi XH,high(poly+1)
	rjmp poly_loop

	end_poly_loop_label:
	rjmp end_poly_loop

	poly_loop:
	//If (temp == 0)break;
		cpi temp,0
		breq end_poly_loop_label

		lds temp1,sign_var
		//test sign of var 
		//if sign_var is pos
		cpi temp1,1
		breq test_sign_result
		//else if sign_var is neg
		rjmp test_sign_result_1

		test_sign_result_1:
		lds temp1,sign_result
		//if var is neg and result is pos
		//final result will be neg
		cpi temp1,1
		breq case2_expect
		//else if var is neg and result is neg
		rjmp case1_expect

		test_sign_result:
		lds temp1,sign_result
		cpi temp1,1
		//if result is pos , final result will be pos 
		breq case1_expect
		//else result is neg , final result will be neg
		rjmp case2_expect

		case1_expect:
		ldi temp1,1
		sts sign_expect,temp1
		rjmp start_algor
		case2_expect:
		ldi temp1,0
		sts sign_expect,temp1
		rjmp start_algor


		///algorithim part//////////////////////=========================
		start_algor:
		//Booth algorithim signed number mulplication
			//n -- number of bits
			ldi temp1,16 // 16 bits result + 8 bits multiplier//?

			//M -- Multiplicand
			//X , 1 byte
			lds temp2,x_var

			//-M 
			//-X
			lds temp7,x_var
			neg temp7


			//Q -- Multiplier
			//result , 2 bytes
			lds temp3,result
			lds temp4,result+1

			//q_-1 -- bit get shifted from Q(Multiplier)
			ldi temp5,0
			//A -- accumulation
			ldi temp6,0
			rjmp booth_alorithimic_loop
			end_of_booth_alorithimic_loop_label:
			rjmp end_of_booth_alorithimic_loop


			booth_alorithimic_loop:
				cpi temp1,0
				breq end_of_booth_alorithimic_loop_label

				//Testing Q_0 and Q_-1
				mov temp8,temp3
				andi temp8,(0x01)//Q_0
				cpi temp8,(0x01)
				//if Q_0 is 1 then branch
				breq test_Q_neg_1
				//else if(Q_0 is !1) means == 0

				cpi temp5,0
				//If Q_0 == 0 and Q_-1 == 0 branch
				breq do_shifting_pro
				
				//else Q_0 == 0 and Q_-1 == 1
				//A = A+M
				add temp6,temp2
				rjmp do_shifting_pro


				test_Q_neg_1:
				mov temp8,temp5
				andi temp8,(0x01)
				cpi temp8,(0x01)
				//If Q_0 is 1 and Q_-1 is 1
				breq do_shifting_pro
				//else Q_0 is 1 and Q_-1 is 0
				//A = A - M
				add temp6,temp7
				rjmp do_shifting_pro

				do_shifting_pro:
				asr temp6//Might have carry out
				ror temp4//Might have carry out
				ror temp3//Might have carry out
				brcs Q_neg_1_to_be_1
				rjmp Q_neg_1_to_be_0

				Q_neg_1_to_be_0:
				ldi temp5,0
				rjmp decrement_n


				Q_neg_1_to_be_1:
				//Q_-1 is 1
				ldi temp5,1
				rjmp decrement_n

				decrement_n:

				dec temp1
				rjmp booth_alorithimic_loop

			end_of_booth_alorithimic_loop:
			///algorithim part//////////////////////=========================
			//END


			//Restore result
			sts result,temp3
			sts result+1,temp4

			//update sign of result
			lds temp4,result+1
			andi temp4,0x80
			cpi temp4,0x80
			breq negative_result_return

			//else positive result returned
			ldi temp2,1
			sts sign_result,temp2
			rjmp check_ow

			negative_result_return:
			ldi temp2,0
			sts sign_result,temp2
			rjmp check_ow

			check_ow:
			lds temp2,once
			cpi temp2,0
			breq excute_check_ow
			rjmp skip_check_ow

			excute_check_ow:
			lds temp3,sign_expect
			lds temp2,sign_result
			cp temp3,temp2
			brne over_f
			//else no overflow
			rjmp skip_check_ow
			over_f:
			ldi overflow_flag,1
			sts once,overflow_flag

		//After the process, correct result of muliplication needs to be
		//in "result"
		//poly[i]
		skip_check_ow:
		ld temp2,X+
		//Check sign?
		mov temp3,temp2
		andi temp3,(0x80)
		cpi temp3,0x80
		//if its neg
		breq subtraction
		//ele addition
		//Need to fix not r24:r25
		lds temp1,result
		lds temp3,result+1
		add temp1,temp2
		ldi temp2,0
		adc temp3,temp2

		rjmp done_if_sign

		subtraction:
		NEG temp2
		//Need to fix not r24:r25
		lds temp1,result
		lds temp3,result+1
		sub temp1,temp2
		sbci temp3,0
		done_if_sign:
		sts result,temp1
		sts result+1,temp3


		dec temp
		
		rjmp poly_loop

		//?

	end_poly_loop:
		
		lds temp,result
		lds temp1,result+1
		

 end:
	rjmp end

