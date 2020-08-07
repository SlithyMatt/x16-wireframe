.ifndef FIXEDPT_INC
FIXEDPT_INC = 1

FP_A = $28
FP_B = $2A
FP_C = $2C
FP_R = $2E

fp_lda_byte: ; FP_A = A
   lsr
   sta FP_A+1
   stz FP_A
   ror FP_A
   rts

fp_ldb_byte: ; FP_B = A
   lsr
   sta FP_B+1
   stz FP_B
   ror FP_B
   rts

.macro FP_LDA addr
   lda addr
   sta FP_A
   lda addr+1
   sta FP_A+1
.endmacro

.macro FP_LDB addr
   lda addr
   sta FP_B
   lda addr+1
   sta FP_B+1
.endmacro

fp_floor_byte: ; A = floor(FP_C)
   lda FP_C+1
   bit FP_C
   bmi @odd
   clc
   bra @shift
@odd:
   sec
@shift:
   rol
   bit FP_C+1
   rts

fp_floor: ; FP_C = floor(FP_C)
   lda FP_C
   and #$80
   sta FP_C
   rts

fp_tca: ; FP_A = FP_C
   lda FP_C
   sta FP_A
   lda FP_C+1
   sta FP_A+1
   rts

fp_tcb: ; FP_B = FP_C
   lda FP_C
   sta FP_B
   lda FP_C+1
   sta FP_B+1
   rts

fp_subtract: ; FP_C = FP_A - FP_B
   lda FP_A
   sec
   sbc FP_B
   sta FP_C
   lda FP_A+1
   sbc FP_B+1
   sta FP_C+1
   rts

fp_add: ; FP_C = FP_A + FP_B
   lda FP_A
   clc
   adc FP_B
   sta FP_C
   lda FP_A+1
   adc FP_B+1
   sta FP_C+1
   rts

fp_divide: ; FP_C = FP_A / FP_B; FP_R = FP_A % FP_B
   lda FP_B
   pha
   lda FP_B+1
   pha ; preserve original B on stack
   bit FP_A+1
   bmi @abs_a
   lda FP_A
   sta FP_C
   lda FP_A+1
   sta FP_C+1
   bra @check_sign_b
@abs_a:
   lda #0
   sec
   sbc FP_A
   sta FP_C
   lda #0
   sbc FP_A+1
   sta FP_C+1 ; C = |A|
@check_sign_b:
   bit FP_B+1
   bmi @init_r
   lda #0
   sec
   sbc FP_B
   sta FP_B
   lda #0
   sta FP_B+1 ; B = |B|
@init_r:
   stz FP_R
   stz FP_R+1
   ldx #16     ;There are 16 bits in C
@loop1:
   asl FP_C    ;Shift hi bit of C into REM
   rol FP_C+1  ;(vacating the lo bit, which will be used for the quotient)
   rol FP_R
   rol FP_R+1
   lda FP_R
   sec         ;Trial subtraction
   sbc FP_B
   tay
   lda FP_R+1
   sbc FP_B+1
   bcc @loop2  ;Did subtraction succeed?
   sta FP_R+1   ;If yes, save it
   sty FP_R
   inc FP_C    ;and record a 1 in the quotient
@loop2:
   dex
   bne @loop1
   pla
   sta FP_B+1
   pla
   sta FP_B
   bit FP_B+1
   bmi @check_cancel
   bit FP_A+1
   bmi @negative
   bra @return
@check_cancel:
   bit FP_A+1
   bmi @return
@negative:
   lda #0
   sec
   sbc FP_C
   sta FP_C
   lda #0
   sbc FP_C+1
   sta FP_C+1
@return:
   rts

fp_multiply: ; FP_C = FP_A * FP_B
   ; push original A and B to stack
   lda FP_A
   pha
   lda FP_A+1
   pha
   lda FP_B
   pha
   lda FP_B+1
   pha
   bit FP_A+1
   bpl @check_sign_b
   lda #0
   sec
   sbc FP_A
   sta FP_C
   lda #0
   sbc FP_A+1
   sta FP_C+1 ; A = |A|
@check_sign_b:
   bit FP_B+1
   bpl @init_c
   lda #0
   sec
   sbc FP_B
   sta FP_B
   lda #0
   sta FP_B+1 ; B = |B|
@init_c:
   stz FP_C
   stz FP_C+1
   ldx #16
@loop1:
   lsr FP_B+1
   ror FP_B
   bcc @loop2
   tay
   clc
   lda FP_A
   adc FP_C
   sta FP_C
   tya
   adc FP_A+1
@loop2:
   ror
   ror FP_C
   dex
   bne @loop1
   sta FP_C+1
   ; restore A and B
   pla
   sta FP_B+1
   pla
   sta FP_B
   pla
   sta FP_A+1
   pla
   sta FP_A
   bit FP_B+1
   bmi @check_cancel
   bit FP_A+1
   bmi @negative
   bra @return
@check_cancel:
   bit FP_A+1
   bmi @return
@negative:
   lda #0
   sec
   sbc FP_C
   sta FP_C
   lda #0
   sbc FP_C+1
   sta FP_C+1
@return:
   rts

.endif
