; =============================================================================
;   Snake.asm — cartridge entry point, title screen, and main loop
; =============================================================================
;   A classic grid-based Snake game for the AC6502 family, built as a
;   standalone ROM cartridge (6502-CRT template). Boots directly, no BASIC.
;
;   Controls: WASD, arrow keys, or joystick 1 to move. Space or fire to
;   start / restart, and to pause / resume during play.
; =============================================================================

.setcpu "65C02"

.include "6502.inc"
.include "src/zeropage.inc"

.segment "CART"

.include "src/tiles.asm"
.include "src/vdp.asm"
.include "src/rng.asm"
.include "src/input.asm"
.include "src/sound.asm"
.include "src/game.asm"

GAME_SPEED_LO = 15    ; SysDelay units are centiseconds (10ms) -> ~150ms/tick
GAME_SPEED_HI = 0

; =============================================================================
;   CartReset — cartridge entry point
; =============================================================================
CartReset:
  ldx #$ff
  txs                            ; Reset the stack pointer
  jsr KernalInit                 ; Initialize all detected hardware

  jsr Beep                       ; Startup beep (skips silently if no SID)
  cli                             ; Enable interrupts

  jsr InitVideo                  ; side effect: loads CP437 font into VRAM,
                                   ; which InitGraphicsI below depends on
  jsr LoadHighScore               ; from RTC NVRAM if fitted, else 0 (session-only)

  lda #1
  jsr SetIOMode                   ; serial, so Chrin's echo can't smear our VRAM

  jsr InitGraphicsI               ; also draws the border and blanks the screen
  jsr DrawTitleScreen              ; same tiles/colors/palette as gameplay

  jsr WaitForStart                ; blocks until fire/space, seeds RNG_STATE

  jsr NewGame

; -----------------------------------------------------------------------------
; MainLoop
; -----------------------------------------------------------------------------
MainLoop:
  jsr PollInput

  lda GAME_STATE
  cmp #STATE_PLAYING
  bne @notPlaying
  lda FIRE_EDGE
  beq @doTick
  lda #STATE_PAUSED
  sta GAME_STATE
  jsr DrawPauseMessage
  jmp @delay
@doTick:
  jsr Tick
  jmp @delay

@notPlaying:
  cmp #STATE_PAUSED
  bne @notPaused
  lda FIRE_EDGE
  beq @delay
  lda #STATE_PLAYING
  sta GAME_STATE
  lda #23
  jsr ClearRow
  jmp @delay

@notPaused:
  cmp #STATE_GAMEOVER
  bne @delay
  lda FIRE_EDGE
  beq @delay
  jsr NewGame

@delay:
  lda #GAME_SPEED_LO
  ldx #GAME_SPEED_HI
  jsr SysDelay
  jmp MainLoop

; =============================================================================
;   IRQ / NMI handlers — cartridge owns the vectors, so it must supply these.
;   Both just dispatch through the RAM vectors KernalInit already configured
;   (default keyboard-scanning IRQ handler, no-op NMI).
; =============================================================================

IrqTrampoline:
  jmp (IRQ_PTR)

NmiTrampoline:
  jmp (NMI_PTR)

; =============================================================================
;   CPU Vectors — cart owns $FFFA-$FFFF
; =============================================================================

.segment "VECTORS"

.word   NmiTrampoline
.word   CartReset
.word   IrqTrampoline
