.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
   jmp start

.include "vsync.asm"

start:
   stz r0L
   stz r0H
   jsr GRAPH_init
   jsr GRAPH_clear

   stz r0L
   stz r0H
   stz r1L
   stz r1H
   lda #<320
   sta r2L
   lda #>320
   sta r2H
   lda #240
   sta r3L
   stz r3H
   jsr GRAPH_draw_line

@loop:
   wai
   jsr check_vsync
   bra @loop
