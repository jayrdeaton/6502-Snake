; =============================================================================
;   sound.asm — eat / death sound feedback
; =============================================================================
;   Beep is guaranteed safe (self-no-ops with no SID card) but blocks the
;   CPU for its full ~300ms tone duration — fine for a one-off like
;   GameOver, but audible every apple pickup as a freeze twice as long as
;   a game tick. Sound_Eat instead drives SidPlayNote/SidSilence directly:
;   both are plain register writes with no delay loop, so they return to
;   the caller immediately.
;
;   SidPlayNote's envelope is Attack=0 (~2ms to peak on real SID hardware),
;   Decay=9, Sustain=$F, Release=8. Calling SidSilence back-to-back with
;   SidPlayNote (a handful of CPU cycles apart, i.e. microseconds) gates
;   the note off before that ~2ms attack ramp has gotten anywhere near
;   peak amplitude — what actually plays is a near-silent fade from
;   whatever tiny level it reached, not a crisp hit. That reads as the
;   sound being soft/late even though it's logically triggered on the
;   right tick. Fix: let the note actually ring for about one game tick
;   before silencing it, via a deferred flag serviced at the top of the
;   next tick, instead of silencing it in the same breath as triggering it.
; =============================================================================

.segment "CART"

Sound_Eat:
  lda #0
  ldx #<SID_NOTE_E6
  ldy #>SID_NOTE_E6
  jsr SidPlayNote
  lda #1
  sta SOUND_PENDING
  rts

; Sound_ServiceSilence — call once per tick, before triggering any new
; sound this tick, so a note from last tick gets roughly a full tick's
; worth of real time to ring before being cut off.
Sound_ServiceSilence:
  lda SOUND_PENDING
  beq @done
  jsr SidSilence
  stz SOUND_PENDING
@done:
  rts

Sound_Death:
  jsr Beep
  jsr Beep
  rts
