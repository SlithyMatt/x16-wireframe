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
   pha
   lsr
   lsr
   lsr
   lsr
   ora #$30
   jsr CHROUT
   pla
   and #$0F
   ora #$30
   jsr CHROUT
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
   pha
   lsr
   lsr
   lsr
   lsr
   ora #$30
   jsr CHROUT
   pla
   and #$0F
   clc
   adc #$37
   jsr CHROUT
   PRINT_CR
   PRINT_CR


   rts
