; =============================================================================
;   rng.asm - 8-bit Galois LFSR pseudo-random generator
; =============================================================================

.segment "CART"

; -----------------------------------------------------------------------------
; AdvanceRng - step the LFSR one bit (maximal-length, period 255)
; -----------------------------------------------------------------------------
AdvanceRng:
  lda RNG_STATE
  lsr a
  bcc @noeor
  eor #$B4
@noeor:
  sta RNG_STATE
  rts

; -----------------------------------------------------------------------------
; RollCol - random playfield column
; Out: A in [FIELD_LEFT, FIELD_RIGHT]
; -----------------------------------------------------------------------------
RollCol:
  jsr AdvanceRng
  lda RNG_STATE
@reduce:
  cmp #(FIELD_RIGHT-FIELD_LEFT+1)
  bcc @done
  sec
  sbc #(FIELD_RIGHT-FIELD_LEFT+1)
  jmp @reduce
@done:
  clc
  adc #FIELD_LEFT
  rts

; -----------------------------------------------------------------------------
; RollRow - random playfield row
; Out: A in [FIELD_TOP, FIELD_BOTTOM]
; -----------------------------------------------------------------------------
RollRow:
  jsr AdvanceRng
  lda RNG_STATE
@reduce:
  cmp #(FIELD_BOTTOM-FIELD_TOP+1)
  bcc @done
  sec
  sbc #(FIELD_BOTTOM-FIELD_TOP+1)
  jmp @reduce
@done:
  clc
  adc #FIELD_TOP
  rts
