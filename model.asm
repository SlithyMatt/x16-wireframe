.ifndef MODEL_INC
MODEL_INC = 1

.include "fixedpt.asm"

USE_X16_GRAPH = 0

BITMAP_SIZE = 320 * 240 / 2

X0_INIT = 0
Y0_INIT = 120
X1_INIT = 255
Y1_INIT = 120

NO_LINE_Y = 240

line_upper: .res 256
line_lower: .res 256

model_x0: .byte X0_INIT
model_y0: .byte Y0_INIT
model_x1: .byte X1_INIT
model_y1: .byte Y1_INIT

use_buffer: .byte 0
vbyte:      .byte 0
delta_x:    .word 0
delta_y:    .word 0
slope:      .word 0
offset:     .word 0
scratch:    .word 0

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
.if USE_X16_GRAPH
   stz r0L
   stz r0H
   jsr GRAPH_init
   lda #1 ; white stroke
   ldx #0 ; black fill
   ldy #0 ; black background
   jsr GRAPH_set_colors
.endif
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
   lda joystick1_right
   sec
   sbc joystick1_left
   sta delta_x
   lda joystick1_down
   sec
   sbc joystick1_up
   sta delta_y
   lda joystick1_a
   eor joystick1_b
   beq @move_0
   cmp joystick1_b
   beq @move_1
@move_0:
   php
   lda model_x0
   clc
   adc delta_x
   sta model_x0
   lda model_y0
   clc
   adc delta_y
   sta model_y0
   plp
   bne @set_buffer
@move_1:
   lda model_x1
   clc
   adc delta_x
   sta model_x1
   lda model_y1
   clc
   adc delta_y
   sta model_y1
@set_buffer:
.if USE_X16_GRAPH
   jsr GRAPH_clear
   lda model_x0
   clc
   adc #32
   sta r0L
   lda model_x0+1
   lda #0
   adc #0
   sta r0H
   lda model_y0
   sta r1L
   lda model_y0+1
   sta r1H
   lda model_x1
   clc
   adc #32
   sta r2L
   lda model_x1+1
   lda #0
   adc #0
   sta r2H
   lda model_y1
   sta r3L
   lda model_y1+1
   sta r3H
   jsr GRAPH_draw_line
   jmp @return
.endif
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
   bne @check_reverse
   jmp @vertical
@check_reverse:
   bcc @calc_slope
   pha
   lda model_x1
   sta model_x0
   pla
   sta model_x1
   lda model_y0
   pha
   lda model_y1
   sta model_y0
   pla
   sta model_y1
@calc_slope:
   lda model_y1
   jsr fp_lda_byte
   lda model_y0
   jsr fp_ldb_byte
   jsr fp_subtract
   FP_STC delta_y
   lda model_x1
   jsr fp_lda_byte
   lda model_x0
   jsr fp_ldb_byte
   jsr fp_subtract
   jsr fp_tcb
   FP_LDA delta_y
   jsr fp_divide
   FP_STC slope
   jsr fp_tca
   lda model_x0
   jsr fp_ldb_byte
   jsr fp_multiply
   jsr fp_tcb
   lda model_y0
   jsr fp_lda_byte
   jsr fp_subtract
   FP_STC offset
   ldx model_x0
   lda model_y0
   sta line_upper,x
   inx
@calc_line_upper:
   phx
   txa
   jsr fp_lda_byte
   FP_LDB slope
   jsr fp_multiply
   jsr fp_tca
   FP_LDB offset
   jsr fp_add
   jsr fp_floor_byte
   plx
   sta line_upper,x
   cpx model_x1
   beq @calc_line_lower
   inx
   bra @calc_line_upper
@calc_line_lower:
   lda model_y1
   sta line_lower,x
@copy_loop:
   lda line_upper,x
   dex
   sta line_lower,x
   cpx model_x0
   bne @copy_loop
   bit slope+1
   bpl @draw
   ldx model_x0
@switch_loop:
   lda line_upper,x
   pha
   lda line_lower,x
   sta line_upper,x
   pla
   sta line_lower,x
   cpx model_x1
   beq @draw
   inx
   bra @switch_loop
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
   ldx #0
@draw_x_loop:
   ldy line_upper,x
@draw_y_loop:
   sty scratch
   lda line_lower,x
   sec
   sbc scratch
   cmp #$FF
   bne @plot
   inx
   bne @draw_x_loop
   bra @switch
@plot:
   iny
   phx
   phy
   lda #1 ; color
   jsr plot_pixel
   ply
   plx
   bra @draw_y_loop
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
