; =============================================================================
;   game.asm — Snake state machine: title wait, tick logic, HUD, game over
; =============================================================================

.segment "CART"

; -----------------------------------------------------------------------------
; DrawTitleScreen — draw the title screen in Graphics I, using the same
; tiles/palette as gameplay (called once at boot, before WaitForStart, on
; top of the border InitGraphicsI already drew). Every line's column is
; computed for exact centering in the 32-wide grid.
; -----------------------------------------------------------------------------
DrawTitleScreen:
  lda #<TitleText
  sta WORK_PTR
  lda #>TitleText
  sta WORK_PTR+1
  lda #8
  ldx #11
  jsr DrawString

  ; snake + apple decoration, row 10: the same tiles used in gameplay, so
  ; the title screen reads as the same game, not a splash screen bolted
  ; on top of it. "S N A K E" above (cols 11-19) is the point of
  ; reference — the body underlines the whole word and runs a couple
  ; cells past it on both ends, with the head chasing a nearby apple.
  lda #9
  sta SCAN_TMP
@titleSnakeBody:
  lda #10
  ldx SCAN_TMP
  ldy #TILE_BODY
  jsr DrawTile
  inc SCAN_TMP
  lda SCAN_TMP
  cmp #20
  bne @titleSnakeBody

  lda #10
  ldx #20
  ldy #TILE_HEAD
  jsr DrawTile

  lda #10
  ldx #22
  ldy #TILE_FOOD
  jsr DrawTile

  lda #<HighScoreLabel
  sta WORK_PTR
  lda #>HighScoreLabel
  sta WORK_PTR+1
  lda #12
  ldx #7
  jsr DrawString
  lda HIGH_SCORE_LO
  ldx HIGH_SCORE_HI
  jsr ValueToDigits
  lda #12
  ldx #19
  jsr DrawDigitBuf

  lda #<StartPromptMsg
  sta WORK_PTR
  lda #>StartPromptMsg
  sta WORK_PTR+1
  lda #14
  ldx #8
  jmp DrawString

; -----------------------------------------------------------------------------
; WaitForStart — title-screen loop. Polls for the A button, seeds RNG_STATE
; from elapsed loop iterations (reaction-time entropy) plus the RTC clock
; if fitted.
; -----------------------------------------------------------------------------
WaitForStart:
  stz RNG_STATE
@loop:
  inc RNG_STATE
  jsr PollInput
  lda START_PRESSED
  bne @done
  jmp @loop
@done:
  lda HW_PRESENT
  and #HW_RTC
  beq @noRtc
  jsr RtcReadTime          ; A=hours, X=minutes, Y=seconds
  eor RNG_STATE
  sta RNG_STATE
  txa
  eor RNG_STATE
  sta RNG_STATE
  tya
  eor RNG_STATE
  sta RNG_STATE
@noRtc:
  lda RNG_STATE
  bne @nonzero
  lda #$2A
  sta RNG_STATE
@nonzero:
  rts

; -----------------------------------------------------------------------------
; NewGame — reset the playfield and snake for a fresh game (also used to
; restart from GAMEOVER; safe to call repeatedly since it fully redraws the
; occupancy grid and border rather than tracking incremental cleanup).
; -----------------------------------------------------------------------------
NewGame:
  jsr ClearScreen          ; wipe any leftover snake/food/message from a
                            ; previous game before rebuilding the board
  jsr InitOccupancy
  jsr DrawBorder

  lda #15
  sta SEGMENTS_X
  lda #12
  sta SEGMENTS_Y
  lda #16
  sta SEGMENTS_X+1
  lda #12
  sta SEGMENTS_Y+1
  lda #17
  sta SEGMENTS_X+2
  lda #12
  sta SEGMENTS_Y+2

  lda #0
  sta TAIL_IDX
  lda #2
  sta HEAD_IDX
  lda #3
  sta SNAKE_LEN
  lda #17
  sta HEAD_X
  lda #12
  sta HEAD_Y
  lda #DIR_RIGHT
  sta DIRECTION
  sta NEXT_DIR
  lda #0
  sta SCORE_LO
  sta SCORE_HI

  lda #12
  ldx #15
  ldy #1
  jsr OccupancySet
  lda #12
  ldx #16
  ldy #1
  jsr OccupancySet
  lda #12
  ldx #17
  ldy #1
  jsr OccupancySet

  lda #12
  ldx #15
  ldy #TILE_BODY
  jsr DrawTile
  lda #12
  ldx #16
  ldy #TILE_BODY
  jsr DrawTile
  lda #12
  ldx #17
  ldy #TILE_HEAD
  jsr DrawTile

  jsr RespawnFood
  jsr DrawHudLabel
  jsr UpdateHud

  lda #STATE_PLAYING
  sta GAME_STATE
  rts

; -----------------------------------------------------------------------------
; Tick — advance the snake one grid step
; -----------------------------------------------------------------------------
Tick:
  jsr Sound_ServiceSilence
  lda DIRECTION
  eor #1
  cmp NEXT_DIR
  beq @skipDirUpdate
  lda NEXT_DIR
  sta DIRECTION
@skipDirUpdate:

  lda HEAD_X
  sta NEW_HEAD_X
  lda HEAD_Y
  sta NEW_HEAD_Y

  lda DIRECTION
  cmp #DIR_UP
  bne @notUp
  dec NEW_HEAD_Y
  jmp @dirDone
@notUp:
  cmp #DIR_DOWN
  bne @notDown
  inc NEW_HEAD_Y
  jmp @dirDone
@notDown:
  cmp #DIR_LEFT
  bne @notLeft
  dec NEW_HEAD_X
  jmp @dirDone
@notLeft:
  inc NEW_HEAD_X
@dirDone:

  lda NEW_HEAD_X
  cmp FOOD_X
  bne @notFood
  lda NEW_HEAD_Y
  cmp FOOD_Y
  bne @notFood
  lda #1
  sta GROW_FLAG
  jmp @foodCheckDone
@notFood:
  lda #0
  sta GROW_FLAG
@foodCheckDone:

  lda NEW_HEAD_Y
  ldx NEW_HEAD_X
  jsr OccupancyGet
  cmp #0
  beq @moveOk
  cmp #3
  beq @collision

  lda GROW_FLAG
  bne @collision

  ldy TAIL_IDX
  lda SEGMENTS_X,y
  cmp NEW_HEAD_X
  bne @collision
  lda SEGMENTS_Y,y
  cmp NEW_HEAD_Y
  bne @collision
  jmp @moveOk

@collision:
  jmp GameOver

@moveOk:
  lda HEAD_Y
  ldx HEAD_X
  ldy #TILE_BODY
  jsr DrawTile

  inc HEAD_IDX
  ldy HEAD_IDX
  lda NEW_HEAD_X
  sta SEGMENTS_X,y
  lda NEW_HEAD_Y
  sta SEGMENTS_Y,y

  lda NEW_HEAD_X
  sta HEAD_X
  lda NEW_HEAD_Y
  sta HEAD_Y

  lda HEAD_Y
  ldx HEAD_X
  ldy #1
  jsr OccupancySet

  lda HEAD_Y
  ldx HEAD_X
  ldy #TILE_HEAD
  jsr DrawTile

  lda GROW_FLAG
  beq @noGrow

  inc SNAKE_LEN
  clc
  lda SCORE_LO
  adc #10
  sta SCORE_LO
  lda SCORE_HI
  adc #0
  sta SCORE_HI
  jsr UpdateHud
  jsr Sound_Eat
  jsr RespawnFood
  jmp @tickDone

@noGrow:
  ldy TAIL_IDX
  lda SEGMENTS_X,y
  sta OLD_TAIL_X
  lda SEGMENTS_Y,y
  sta OLD_TAIL_Y

  lda OLD_TAIL_Y
  ldx OLD_TAIL_X
  ldy #0
  jsr OccupancySet

  lda OLD_TAIL_Y
  ldx OLD_TAIL_X
  jsr EraseTile

  inc TAIL_IDX

@tickDone:
  rts

; -----------------------------------------------------------------------------
; GameOver
; -----------------------------------------------------------------------------
GameOver:
  lda #STATE_GAMEOVER
  sta GAME_STATE
  jsr Sound_Death

  stz NEW_HIGH_FLAG
  lda SCORE_HI
  cmp HIGH_SCORE_HI
  bcc @notHigh
  bne @isHigh
  lda SCORE_LO
  cmp HIGH_SCORE_LO
  bcc @notHigh
  beq @notHigh            ; a tied score doesn't count as a NEW high
@isHigh:
  lda SCORE_LO
  sta HIGH_SCORE_LO
  lda SCORE_HI
  sta HIGH_SCORE_HI
  lda #1
  sta NEW_HIGH_FLAG
  jsr SaveHighScore
@notHigh:
  jsr DrawGameOverOverlay
  rts

; -----------------------------------------------------------------------------
; High score persistence — the cartridge ROM itself is read-only and can't
; store anything, but the RTC card (when fitted) carries 256 bytes of
; battery-backed NVRAM that survives power cycles. We use 3 of those bytes:
; a signature (to tell "our data" from an untouched/foreign NVRAM) plus the
; 16-bit score. With no RTC card, the high score is still tracked — it just
; lives in RAM only and resets whenever the machine is powered off.
; -----------------------------------------------------------------------------
NVRAM_SIG_ADDR      = 0
NVRAM_SCORE_LO_ADDR = 1
NVRAM_SCORE_HI_ADDR = 2
NVRAM_MAGIC         = $A5

; LoadHighScore — call once at boot, before the title screen is drawn
LoadHighScore:
  stz HIGH_SCORE_LO
  stz HIGH_SCORE_HI
  lda HW_PRESENT
  and #HW_RTC
  beq @done
  ldx #NVRAM_SIG_ADDR
  jsr RtcReadNVRAM
  cmp #NVRAM_MAGIC
  bne @done                ; untouched NVRAM (or a different program's data) -> start at 0
  ldx #NVRAM_SCORE_LO_ADDR
  jsr RtcReadNVRAM
  sta HIGH_SCORE_LO
  ldx #NVRAM_SCORE_HI_ADDR
  jsr RtcReadNVRAM
  sta HIGH_SCORE_HI
@done:
  rts

; SaveHighScore — call whenever HIGH_SCORE_LO/HI changes
SaveHighScore:
  lda HW_PRESENT
  and #HW_RTC
  beq @done                ; no RTC card -> nothing to persist to, skip silently
  lda #NVRAM_MAGIC
  ldx #NVRAM_SIG_ADDR
  jsr RtcWriteNVRAM
  lda HIGH_SCORE_LO
  ldx #NVRAM_SCORE_LO_ADDR
  jsr RtcWriteNVRAM
  lda HIGH_SCORE_HI
  ldx #NVRAM_SCORE_HI_ADDR
  jsr RtcWriteNVRAM
@done:
  rts

; -----------------------------------------------------------------------------
; RespawnFood — place food on a random empty cell (bounded retry)
; -----------------------------------------------------------------------------
RespawnFood:
  stz RETRY_CNT
@try:
  jsr RollCol
  sta FOOD_X
  jsr RollRow
  sta FOOD_Y

  lda FOOD_Y
  ldx FOOD_X
  jsr OccupancyGet
  cmp #0
  beq @placed

  inc RETRY_CNT
  lda RETRY_CNT
  cmp #32
  bne @try

  lda #FIELD_LEFT
  sta FOOD_X
  lda #FIELD_TOP
  sta FOOD_Y

@placed:
  lda FOOD_Y
  ldx FOOD_X
  ldy #TILE_FOOD
  jsr DrawTile
  rts

; -----------------------------------------------------------------------------
; Decimal HUD helpers
; -----------------------------------------------------------------------------

; Sub16IfGE — if SC_TMP >= SUB, subtract and return carry set; else carry clear
Sub16IfGE:
  lda SC_TMP_HI
  cmp SUB_HI
  bcc @no
  bne @yes
  lda SC_TMP_LO
  cmp SUB_LO
  bcc @no
@yes:
  lda SC_TMP_LO
  sec
  sbc SUB_LO
  sta SC_TMP_LO
  lda SC_TMP_HI
  sbc SUB_HI
  sta SC_TMP_HI
  sec
  rts
@no:
  clc
  rts

; CountDigit — count how many times SUB can be subtracted from SC_TMP
; Out: A = ASCII digit ('0'-'9')
CountDigit:
  lda #0
  sta DIGIT_COUNT
@loop:
  jsr Sub16IfGE
  bcc @done
  inc DIGIT_COUNT
  jmp @loop
@done:
  lda DIGIT_COUNT
  clc
  adc #'0'
  rts

; ValueToDigits — convert a 16-bit value into 5 ASCII digits in DIGIT_BUF
; In: A = value low, X = value high
ValueToDigits:
  sta SC_TMP_LO
  stx SC_TMP_HI

  lda #<10000
  sta SUB_LO
  lda #>10000
  sta SUB_HI
  jsr CountDigit
  sta DIGIT_BUF+0

  lda #<1000
  sta SUB_LO
  lda #>1000
  sta SUB_HI
  jsr CountDigit
  sta DIGIT_BUF+1

  lda #<100
  sta SUB_LO
  lda #>100
  sta SUB_HI
  jsr CountDigit
  sta DIGIT_BUF+2

  lda #<10
  sta SUB_LO
  lda #>10
  sta SUB_HI
  jsr CountDigit
  sta DIGIT_BUF+3

  lda SC_TMP_LO
  clc
  adc #'0'
  sta DIGIT_BUF+4
  rts

; UpdateHud — redraw the score digits at row 0, columns 8-12
UpdateHud:
  lda SCORE_LO
  ldx SCORE_HI
  jsr ValueToDigits
  lda #0
  ldx #8
  jmp DrawDigitBuf

; DrawDigitBuf — draw the 5 ASCII digits currently in DIGIT_BUF at (row,col)
; In: A = row, X = col
DrawDigitBuf:
  sta MSG_ROW
  stx SCAN_TMP
  stz STR_IDX
@loop:
  ldy STR_IDX
  lda DIGIT_BUF,y
  tay
  lda MSG_ROW
  ldx SCAN_TMP
  jsr DrawTile
  inc SCAN_TMP
  inc STR_IDX
  lda STR_IDX
  cmp #5
  bne @loop
  rts

; DrawString — draw a null-terminated string starting at (row,col)
; In: A = row, X = col, WORK_PTR/WORK_PTR+1 = string pointer
DrawString:
  sta MSG_ROW
  stx SCAN_TMP
  stz STR_IDX
@loop:
  ldy STR_IDX
  lda (WORK_PTR),y
  beq @done
  tay
  lda MSG_ROW
  ldx SCAN_TMP
  jsr DrawTile
  inc SCAN_TMP
  inc STR_IDX
  jmp @loop
@done:
  rts

; ClearRow — blank an entire row
; In: A = row
ClearRow:
  sta MSG_ROW
  stz SCAN_TMP
@loop:
  lda MSG_ROW
  ldx SCAN_TMP
  jsr EraseTile
  inc SCAN_TMP
  lda SCAN_TMP
  cmp #GRID_COLS
  bne @loop
  rts

; DrawHudLabel — draw the static "SCORE:" label at row 0, column 1
DrawHudLabel:
  lda #<ScoreLabel
  sta WORK_PTR
  lda #>ScoreLabel
  sta WORK_PTR+1
  lda #0
  ldx #1
  jmp DrawString

; DrawGameOverOverlay — draw a highlighted box centered on the board with
; the final score and, if this round set a new record, a callout for it
; (otherwise the standing high score, for reference).
DrawGameOverOverlay:
  jsr DrawBoxFrame
  jsr ClearBoxInterior

  lda #<GameOverTitleMsg
  sta WORK_PTR
  lda #>GameOverTitleMsg
  sta WORK_PTR+1
  lda #(BOX_TOP+2)
  ldx #11
  jsr DrawString

  lda #<ScoreLabel2
  sta WORK_PTR
  lda #>ScoreLabel2
  sta WORK_PTR+1
  lda #(BOX_TOP+3)
  ldx #10
  jsr DrawString
  lda SCORE_LO
  ldx SCORE_HI
  jsr ValueToDigits
  lda #(BOX_TOP+3)
  ldx #17
  jsr DrawDigitBuf

  lda NEW_HIGH_FLAG
  beq @showHighRef

  lda #<NewHighMsg
  sta WORK_PTR
  lda #>NewHighMsg
  sta WORK_PTR+1
  lda #(BOX_TOP+4)
  ldx #8
  jsr DrawString
  jmp @afterHighLine

@showHighRef:
  lda #<HighLabelMsg
  sta WORK_PTR
  lda #>HighLabelMsg
  sta WORK_PTR+1
  lda #(BOX_TOP+4)
  ldx #10
  jsr DrawString
  lda HIGH_SCORE_LO
  ldx HIGH_SCORE_HI
  jsr ValueToDigits
  lda #(BOX_TOP+4)
  ldx #17
  jsr DrawDigitBuf

@afterHighLine:
  lda #<PressAMsg
  sta WORK_PTR
  lda #>PressAMsg
  sta WORK_PTR+1
  lda #(BOX_TOP+5)
  ldx #12
  jmp DrawString

; DrawPauseMessage — draw the paused text at row 23
DrawPauseMessage:
  lda #<PauseMsg
  sta WORK_PTR
  lda #>PauseMsg
  sta WORK_PTR+1
  lda #23
  ldx #7
  jmp DrawString

ScoreLabel:
  .byte "SCORE:", $00

PauseMsg:
  .byte "PAUSED - PRESS A", $00

GameOverTitleMsg:
  .byte "GAME OVER", $00

ScoreLabel2:
  .byte "SCORE: ", $00

NewHighMsg:
  .byte "NEW HIGH SCORE!", $00

HighLabelMsg:
  .byte "HIGH:  ", $00   ; extra space vs "SCORE: " so the digits line up

PressAMsg:
  .byte "PRESS A", $00

TitleText:
  .byte "S N A K E", $00

HighScoreLabel:
  .byte "HIGH SCORE: ", $00

StartPromptMsg:
  .byte "PRESS A TO START", $00
