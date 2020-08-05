.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
   jmp start

.include "irq.asm"

vram_map_fn: .byte "vrammap.bin"


start:
   ; load VRAM map
   lda #KERNAL_ROM_BANK
   sta ROM_BANK
   lda #1
   ldx #8
   ldy #0
   jsr SETLFS
   lda #11
   ldx #<vram_map_fn
   ldy #>vram_map_fn
   jsr SETNAM
   lda #VRAMMAP_BANK
   sta RAM_BANK
   lda #0
   ldx #<RAM_WIN
   ldy #>RAM_WIN
   jsr LOAD


   ; clear VRAM
   lda #06
   jsr clear_screen

   ; Scale to 320x240
   lda #64
   sta VERA_dc_hscale
   sta VERA_dc_vscale

   ; Configure bitmap mode
   lda #$06
   sta VERA_L1_config
   stz VERA_L1_tilebase
   stz VERA_L1_hscroll_h

   ; Enable interrupts
   jsr init_irq

@main_loop:
   wai
   jsr check_vsync
   bra @main_loop
