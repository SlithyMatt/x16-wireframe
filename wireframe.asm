.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
   jmp start

.include "vsync.asm"

start:
   ; clear VRAM
   lda #06
   jsr clear_screen

   ; Scale to 320x240
   lda #64
   sta VERA_dc_hscale
   sta VERA_dc_vscale

   ; Configure bitmap mode
   lda #$04
   sta VERA_L1_config
   stz VERA_L1_tilebase
   stz VERA_L1_hscroll_h

   ; Enable interrupts
   jsr init_irq

@main_loop:
   wai
   jsr check_vsync
   bra @main_loop
