.ifndef MODEL_INC
MODEL_INC = 1

.include "fixedpt.asm"

BITMAP_SIZE = 320 * 240 / 2

X0_INIT = 30
Y0_INIT = 120
X1_INIT = 0
Y1_INIT = 200

NO_LINE_Y = 240

line_upper: .res 256
line_lower: .res 256

model_x0: .byte X0_INIT
model_y0: .byte Y0_INIT
model_x1: .byte X1_INIT
model_y1: .byte Y1_INIT

use_buffer: .byte 0
vbyte:      .byte 0
cur_x:      .byte 0
cur_y:      .byte 0
delta_x:    .word 0
delta_y:    .word 0

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

   jsr clear_line
   lda model_x0
   cmp model_x1
   beq @vertical
   bcc @calc_slope
   pha
   lda model_x1
   sta model_x0
   pla
   sta model_x1
@calc_slope:
   lda model_y1
   jsr fp_lda_byte
   lda model_y0
   jsr fp_ldb_byte
   jsr fp_subtract
   lda FP_C
   sta delta_y
   lda FP_C+1
   sta delta_y+1
   lda model_x1
   jsr fp_lda_byte
   lda model_x0
   jsr fp_ldb_byte
   jsr fp_subtract
   jsr fp_tcb
   FP_LDA delta_y
   jsr fp_divide ; FP_C = slope
   jsr fp_tca
   ; TODO calculate offset


@vertical:
   ldx model_x0
   lda model_y0
   cmp model_y1
   bcc @set_vert_line
   pha
   lda model_y1
   sta model_y0
   pla
   sta model_y1
@set_vert_line:
   lda model_y0
   sta line_upper,x
   lda model_y1
   sta line_lower,x

@draw:

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

clear_line:
   ldx #0
@loop:
   lda #NO_LINE_Y
   sta line_upper,x
   sta line_lower,x
   inx
   bne @loop
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
