; =============================================================================
;   sound.asm — eat / death sound feedback
; =============================================================================
;   Beep is guaranteed safe (self-no-ops with no SID card) but blocks the
;   CPU for its full ~300ms tone duration — fine for a one-off like
;   GameOver, but audible every apple pickup as a freeze twice as long as
;   a game tick. Sound_Eat instead drives SidPlayNote/SidSilence directly:
;   both are plain register writes with no delay loop, so they return to
;   the caller immediately. The SID's own envelope hardware keeps ringing
;   the note out in real time after that — gating off right away just
;   starts the (already short, full-sustain) release phase, it doesn't
;   cut the sound short. Also self-no-ops with no SID fitted.
; =============================================================================

.segment "CART"

Sound_Eat:
  lda #0
  ldx #<SID_NOTE_E6
  ldy #>SID_NOTE_E6
  jsr SidPlayNote
  jsr SidSilence
  rts

Sound_Death:
  jsr Beep
  jsr Beep
  rts
