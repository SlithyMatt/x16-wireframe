.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
   jmp start

.include "fixedpt.asm"

.macro PRINT_STRING str_arg
   .scope
         jmp end_string
      string_begin: .byte str_arg
      end_string:
         lda #<string_begin
         sta ZP_PTR_1
         lda #>string_begin
         sta ZP_PTR_1+1
         ldx #(end_string-string_begin)
         ldy #0
      loop:
         lda (ZP_PTR_1),y
         jsr CHROUT
         iny
         dex
         bne loop
   .endscope
.endmacro

.macro PRINT_CR
   lda #$0D
   jsr CHROUT
.endmacro

print_byte:
   pha
   lsr
   lsr
   lsr
   lsr
   cmp #$0A
   bpl @letter1
   ora #$30
   jsr CHROUT
   bra @lower
@letter1:
   clc
   adc #$37
   jsr CHROUT
@lower:
   pla
   and #$0F
   cmp #$0A
   bpl @letter2
   ora #$30
   jsr CHROUT
   bra @return
@letter2:
   clc
   adc #$37
   jsr CHROUT
@return:
   rts

scratch: .word 0

start:
   PRINT_CR
   PRINT_STRING "fixed-point test"
   PRINT_CR
   PRINT_STRING "test 1: 2 + 3 = 5 ($05)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #2
   jsr fp_lda_byte
   lda #3
   jsr fp_ldb_byte
   jsr fp_add
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   PRINT_STRING "test 2: 100 + (-25) = 75 ($4b)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #0
   jsr fp_lda_byte
   lda #25
   jsr fp_ldb_byte
   jsr fp_subtract
   jsr fp_tcb
   lda #100
   jsr fp_lda_byte
   jsr fp_add
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   PRINT_STRING "test 3: 6 / 3 = 2 ($02)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #6
   jsr fp_lda_byte
   lda #3
   jsr fp_ldb_byte
   jsr fp_divide
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   PRINT_STRING "test 4: 9 * 25 = 225 ($e1)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #9
   jsr fp_lda_byte
   lda #25
   jsr fp_ldb_byte
   jsr fp_multiply
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   PRINT_STRING "test 5: (101 / 8) * 16 = 202 ($ca)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #101
   jsr fp_lda_byte
   lda #8
   jsr fp_ldb_byte
   jsr fp_divide
   jsr fp_tca
   lda #16
   jsr fp_ldb_byte
   jsr fp_multiply
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   PRINT_STRING "test 6: 6 * -3 + 21 = 3 ($03)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #0
   jsr fp_lda_byte
   lda #3
   jsr fp_ldb_byte
   jsr fp_subtract
   jsr fp_tcb
   lda #6
   jsr fp_lda_byte
   jsr fp_multiply
   jsr fp_tca
   lda #21
   jsr fp_ldb_byte
   jsr fp_add
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   PRINT_STRING "test 7: -6 * -3 = 18 ($12)"
   PRINT_CR
   PRINT_STRING "result: $"
   lda #0
   jsr fp_lda_byte
   lda #6
   jsr fp_ldb_byte
   jsr fp_subtract
   FP_STC scratch
   lda #0
   jsr fp_lda_byte
   lda #3
   jsr fp_ldb_byte
   jsr fp_subtract
   jsr fp_tcb
   FP_LDA scratch
   jsr fp_multiply
   jsr fp_floor_byte
   jsr print_byte
   PRINT_CR
   PRINT_CR

   rts
