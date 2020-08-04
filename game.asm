.ifndef GAME_INC
GAME_INC = 1

.include "x16.inc"
.include "joystick.asm"
.include "model.asm"

init_game:
   jsr init_model
   rts

game_tick:        ; called after every VSYNC detected (60 Hz)
   jsr joystick_tick
   jsr model_tick
   rts


.endif
