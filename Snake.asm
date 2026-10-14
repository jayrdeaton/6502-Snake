; =============================================================================
;   Snake.asm - cartridge entry point, title screen, and main loop
; =============================================================================
;   A classic grid-based Snake game for the AC6502 family, built as a
;   standalone ROM cartridge (6502-CRT template). Boots directly, no BASIC.
;
;   Controls: joystick, either port, to move, with WASD or arrow keys as a
;   fallback when the joystick shows no direction (e.g. no GPIO card
;   fitted). The A button (or space) to start/restart, and to pause/resume
;   during play.
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
;   CartReset - cartridge entry point
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

  lda #0
  jsr SetIOMode                   ; video/local keyboard -- Chrin's SOURCE
                                    ; follows IO_MODE too, not just Chrout's
                                    ; destination, so the WASD/arrow-key
                                    ; fallback (DrainKeyboardCombined, which
                                    ; calls Chrin) would silently read from
                                    ; the serial port instead of the local
                                    ; keyboard if this were left at serial
                                    ; mode. This does mean the NO VIDEO CARD
                                    ; fallback message below is no longer
                                    ; visible over serial if it ever fires --
                                    ; accepted, since the cartridge is
                                    ; unplayable either way with no video
                                    ; card (every screen is graphical), and
                                    ; keyboard input needs to actually work
                                    ; for the overwhelmingly common case
                                    ; where a video card IS fitted

  jsr InitGraphicsI               ; also draws the border and blanks the screen
  jsr DrawTitleScreen              ; same tiles/colors/palette as gameplay

  jsr WaitForStart                ; blocks until the A button, seeds RNG_STATE

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
;   IRQ / NMI handlers - cartridge owns the vectors, so it must supply these.
;   Both just dispatch through the RAM vectors KernalInit already configured
;   (default keyboard-scanning IRQ handler, no-op NMI).
; =============================================================================

IrqTrampoline:
  jmp (IRQ_PTR)

NmiTrampoline:
  jmp (NMI_PTR)

; =============================================================================
;   CPU Vectors - cart owns $FFFA-$FFFF
; =============================================================================

.segment "VECTORS"

.word   NmiTrampoline
.word   CartReset
.word   IrqTrampoline
