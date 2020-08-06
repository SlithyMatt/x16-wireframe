.ifndef MODEL_INC
MODEL_INC = 1

BITMAP_SIZE = 320 * 240 / 2

X0_INIT = 30
Y0_INIT = 120
X1_INIT = 0
Y1_INIT = 200

model_x0: .byte X0_INIT
model_y0: .byte Y0_INIT
model_x1: .byte X1_INIT
model_y1: .byte Y1_INIT

use_buffer: .byte 0
vbyte:      .byte 0
cur_x:      .byte 0
cur_y:      .byte 0
delta_x:    .byte 0
delta_y:    .byte 0

VRAMMAP_BANK = 1

init_model:
   lda #0
   sta use_buffer
   jsr clear_screen
   lda #1
   jsr clear_screen
   lda #X0_INIT
   sta model_x0
   lda #Y0_INIT
   sta model_y0
   lda #X1_INIT
   sta model_x1
   lda #Y1_INIT
   sta model_y1
   rts

clear_screen:
   cmp #0
   beq @bank0
   lda #$11
   bra @start
@bank0:
   lda #$10
@start:
   stz VERA_ctrl
   stz VERA_addr_low
   stz VERA_addr_high
   sta VERA_addr_bank
   ldx #<BITMAP_SIZE
   ldy #>BITMAP_SIZE
@clear_loop:
   stz VERA_data0
   dex
   cpx #$FF
   bne @clear_loop
   dey
   cpy #$FF
   bne @clear_loop
   rts

model_tick:
   ; TODO: handle joystick

   lda use_buffer
   eor #$01
   sta use_buffer
   jsr clear_screen
   stz VERA_ctrl
   lda use_buffer
   sta VERA_addr_bank
   lda #1
   ldx model_x0
   ldy model_y0
   jsr plot_pixel
   lda model_x0
   sta cur_x
   lda model_y0
   sta cur_y
@loop:
   stz delta_x
   stz delta_y
   lda cur_x
   cmp model_x1
   beq @check_y
   bcs @left
   lda #1
   sta delta_x
   bra @check_y
@left:
   lda #$FF
   sta delta_x
@check_y:
   lda cur_y
   cmp model_y1
   beq @check_x
   bcs @up
   lda #1
   sta delta_y
   bra @plot
@up:
   lda #$FF
   sta delta_y
   bra @plot
@check_x:
   lda cur_x
   cmp model_x1
   beq @switch
@plot:
   lda cur_x
   clc
   adc delta_x
   sta cur_x
   tax
   lda cur_y
   clc
   adc delta_y
   sta cur_y
   tay
   lda #1 ; color
   jsr plot_pixel
   bra @loop
@switch:
   lda use_buffer
   lsr
   ror
   sta VERA_L1_tilebase
@return:
   rts

plot_pixel:
   pha
   txa
   and #$E0
   asl
   rol
   rol
   rol
   clc
   adc #VRAMMAP_BANK
   sta RAM_BANK
   txa
   lsr
   and #$0F
   sta ZP_PTR_1+1
   tya
   asl
   rol ZP_PTR_1+1
   clc
   adc #<RAM_WIN
   sta ZP_PTR_1
   lda ZP_PTR_1+1
   adc #>RAM_WIN
   sta ZP_PTR_1+1
   ldy #0
   lda (ZP_PTR_1),y
   sta VERA_addr_low
   iny
   lda (ZP_PTR_1),y
   sta VERA_addr_high
   pla ; color
   sta vbyte
   txa
   bit #$01
   bne @draw
   asl vbyte
   asl vbyte
   asl vbyte
   asl vbyte
@draw:
   lda VERA_data0
   ora vbyte
   sta VERA_data0
   rts


.endif
