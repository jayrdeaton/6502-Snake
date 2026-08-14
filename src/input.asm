; =============================================================================
;   input.asm — joystick-first polling, keyboard fallback (WASD/arrows)
; =============================================================================
;   Movement and the A button come from the joystick when one is present and
;   being used; WASD or arrow keys act as a fallback for a single player
;   when the joystick shows no direction this poll (including when no GPIO
;   card is fitted at all). Joystick and keyboard are never blended within
;   the same poll: if the joystick shows any direction, that direction wins
;   outright and the keyboard isn't even consulted for direction. The fire
;   button is the one exception — joystick A held OR keyboard space seen
;   this drain, either sets START_PRESSED, independent of which source won
;   the direction for this poll.
;
;   Both joystick ports are still read and combined via the shared
;   PollJoyCombined (whichever is plugged in and moved/pressed drives the
;   game), so it doesn't matter which port a single-player controller is
;   plugged into. This is single-player, so DrainKeyboardCombined is used
;   (not the two-player split): WASD or arrow keys, whichever was pressed
;   most recently in the drain, wins.
;
;   Joystick bit layout and button naming (A/B/X/Y, not generic "fire") and
;   the keyboard scancode constants are now defined by the shared library
;   (see ../../6502-Lib/core/input.asm) rather than duplicated here.
; =============================================================================

.include "../../6502-Lib/core/input.asm"

.segment "CART"

; -----------------------------------------------------------------------------
; PollInput — sample joystick 1 and 2 (combined) for movement and the A
; button; fall back to the keyboard (WASD/arrows/space) only when the
; joystick shows no direction this poll. Safe to call every frame regardless
; of GAME_STATE.
; -----------------------------------------------------------------------------
PollInput:
  stz START_PRESSED

  jsr PollJoyCombined       ; JOY_STATE = combined active-low byte, or $FF if
                             ; no GPIO card / nothing pressed on either port

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
  and #JOY_A
  bne @jNotA
  lda #1
  sta START_PRESSED
@jNotA:

  ; Keyboard fallback: only consulted when the joystick showed NO direction
  ; this poll (all four direction bits high in JOY_STATE) — joystick always
  ; wins outright when it shows anything, per the priority rule above.
  lda JOY_STATE
  and #(JOY_UP | JOY_DOWN | JOY_LEFT | JOY_RIGHT)
  cmp #(JOY_UP | JOY_DOWN | JOY_LEFT | JOY_RIGHT)
  bne @doneDrain             ; some direction bit is low -> joystick wins

  jsr DrainKeyboardCombined

  lda KB_DIR
  cmp #KB_DIR_NONE
  beq @kbNoDir
  sta NEXT_DIR
@kbNoDir:
  lda KB_FIRE
  beq @doneDrain
  lda #1
  sta START_PRESSED

@doneDrain:
  ; Edge-detect the A button / space: FIRE_EDGE is set only on the poll it
  ; first goes down, so a held button (which reads as continuously down
  ; every poll) doesn't repeatedly re-trigger pause/resume/restart every
  ; tick.
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
