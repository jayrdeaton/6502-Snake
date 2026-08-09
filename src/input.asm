; =============================================================================
;   input.asm — joystick + keyboard polling
; =============================================================================
;   ReadJoystick1 does NOT check HW_PRESENT (6502.inc explicitly warns a
;   floating bus reads as meaningless), so we gate on HW_GPIO ourselves.
;   Bit layout (active low):  7=R 6=L 5=D 4=U 3=Y 2=X 1=B 0=A
; =============================================================================

JOY_FIRE  = %00000001
JOY_UP    = %00010000
JOY_DOWN  = %00100000
JOY_LEFT  = %01000000
JOY_RIGHT = %10000000

; Arrow keys arrive as control codes, not 'W'/'A'/'S'/'D' — confirmed against
; the emulator's USB-HID-to-ASCII keyboard tables (KeyboardEncoderAttachment
; and KeyboardMatrixAttachment both agree on these four).
KEY_UP    = $1E
KEY_DOWN  = $1F
KEY_LEFT  = $1C
KEY_RIGHT = $1D

.segment "CART"

; -----------------------------------------------------------------------------
; PollInput — sample joystick (if present) and drain the keyboard buffer,
; updating NEXT_DIR and START_PRESSED. Safe to call every frame regardless
; of GAME_STATE.
; -----------------------------------------------------------------------------
PollInput:
  stz START_PRESSED

  lda HW_PRESENT
  and #HW_GPIO
  beq @kbOnly

  jsr ReadJoystick1
  sta JOY_STATE

  lda JOY_STATE
  and #JOY_UP
  bne @jNotUp
  lda #DIR_UP
  sta NEXT_DIR
@jNotUp:
  lda JOY_STATE
  and #JOY_DOWN
  bne @jNotDown
  lda #DIR_DOWN
  sta NEXT_DIR
@jNotDown:
  lda JOY_STATE
  and #JOY_LEFT
  bne @jNotLeft
  lda #DIR_LEFT
  sta NEXT_DIR
@jNotLeft:
  lda JOY_STATE
  and #JOY_RIGHT
  bne @jNotRight
  lda #DIR_RIGHT
  sta NEXT_DIR
@jNotRight:
  lda JOY_STATE
  and #JOY_FIRE
  bne @jNotFire
  lda #1
  sta START_PRESSED
@jNotFire:

@kbOnly:
@drain:
  jsr Chrin
  bcc @doneDrain
  sta KB_CHAR

  cmp #'W'
  beq @setUp
  cmp #KEY_UP
  bne @notW
@setUp:
  lda #DIR_UP
  sta NEXT_DIR
  jmp @drain
@notW:
  lda KB_CHAR
  cmp #'S'
  beq @setDown
  cmp #KEY_DOWN
  bne @notS
@setDown:
  lda #DIR_DOWN
  sta NEXT_DIR
  jmp @drain
@notS:
  lda KB_CHAR
  cmp #'A'
  beq @setLeft
  cmp #KEY_LEFT
  bne @notA
@setLeft:
  lda #DIR_LEFT
  sta NEXT_DIR
  jmp @drain
@notA:
  lda KB_CHAR
  cmp #'D'
  beq @setRight
  cmp #KEY_RIGHT
  bne @notD
@setRight:
  lda #DIR_RIGHT
  sta NEXT_DIR
  jmp @drain
@notD:
  lda KB_CHAR
  cmp #' '
  bne @drain
  lda #1
  sta START_PRESSED
  jmp @drain

@doneDrain:
  ; Edge-detect fire/space: FIRE_EDGE is set only on the poll it first goes
  ; down, so a held button (in particular a held joystick fire, which reads
  ; as continuously down every poll) doesn't repeatedly re-trigger
  ; pause/resume/restart on every subsequent tick.
  stz FIRE_EDGE
  lda PREV_FIRE
  bne @noEdge
  lda START_PRESSED
  beq @noEdge
  inc FIRE_EDGE
@noEdge:
  lda START_PRESSED
  sta PREV_FIRE
  rts
