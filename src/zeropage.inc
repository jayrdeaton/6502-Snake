; =============================================================================
;   zeropage.inc — Snake zero-page variables, RAM arrays, and game constants
; =============================================================================
;   Zero page $3A-$FF is free for a program that has taken the machine over
;   (see SECTION 1 of 6502.inc). A cartridge never runs BASIC/Monitor/XModem,
;   so $0800+ RAM (normally program space) is also free for our arrays.
;
;   6502.cfg defines no RAM/BSS segment, so every variable below is a fixed-
;   address equate (:=), not a .zeropage/.bss allocation.
; =============================================================================

; --- Game state constants ---
STATE_TITLE     = 0
STATE_PLAYING   = 1
STATE_GAMEOVER  = 2
STATE_PAUSED    = 3

DIR_UP          = 0
DIR_DOWN        = 1
DIR_LEFT        = 2
DIR_RIGHT       = 3

; --- Zero page variables ---
GAME_STATE      := $3A   ; STATE_TITLE / STATE_PLAYING / STATE_GAMEOVER
DIRECTION       := $3B   ; current heading (DIR_*)
NEXT_DIR        := $3C   ; buffered heading, applied next tick if not a reversal
HEAD_X          := $3D   ; current head column
HEAD_Y          := $3E   ; current head row
HEAD_IDX        := $3F   ; ring-buffer index of newest segment
TAIL_IDX        := $40   ; ring-buffer index of oldest segment
SNAKE_LEN       := $41   ; current length
FOOD_X          := $42
FOOD_Y          := $43
SCORE_LO        := $44   ; binary score, 16-bit
SCORE_HI        := $45
RNG_STATE       := $46   ; 8-bit LFSR state (never 0)
NEW_HEAD_X      := $47   ; scratch: candidate head position this tick
NEW_HEAD_Y      := $48
GROW_FLAG       := $49   ; nonzero if candidate head lands on food this tick
OFFSET_LO       := $4A   ; scratch: row*32+col offset (VRAM name-table / occupancy index)
OFFSET_HI       := $4B
RETRY_CNT       := $4C   ; bounded retry counter for food respawn
SCAN_TMP        := $4D   ; scratch loop counter (used by init/drawing loops)
DIGIT_BUF       := $4E   ; 5 bytes, $4E-$52: ASCII decimal digits of score
LAST_KEY        := $53   ; unused scratch (reserved)
JOY_STATE       := $54   ; last raw ReadJoystick1 byte
KB_CHAR         := $55   ; last Chrin byte
WORK_PTR        := $56   ; 2 bytes, $56-$57: general-purpose indirect pointer
OLD_TAIL_X      := $58   ; scratch: tail cell about to be vacated this tick
OLD_TAIL_Y      := $59
STR_IDX         := $5A   ; scratch: string/loop index for text-drawing routines
SC_TMP_LO       := $5B   ; scratch: working copy of score during digit conversion
SC_TMP_HI       := $5C
SUB_LO          := $5D   ; scratch: subtrahend for decimal digit conversion
SUB_HI          := $5E
DIGIT_COUNT     := $5F   ; scratch: digit accumulator during conversion
START_PRESSED   := $60   ; set by PollInput when fire/space is down this poll
PREV_FIRE       := $61   ; START_PRESSED as of the previous poll (edge detection)
FIRE_EDGE       := $62   ; set only on the poll fire/space first goes down —
                          ; use this (not START_PRESSED) for state transitions,
                          ; so holding the button doesn't repeatedly re-trigger
                          ; pause/resume/restart every tick it stays held
MSG_ROW         := $63   ; scratch: row argument for DrawString/ClearRow/DrawDigitBuf
SCAN_TMP2       := $64   ; scratch: second loop counter for nested row/col loops
HIGH_SCORE_LO   := $65   ; best score this power-on session (persisted to RTC
HIGH_SCORE_HI   := $66   ; NVRAM when that card is fitted; session-only otherwise)
NEW_HIGH_FLAG   := $67   ; set by GameOver when this round beat HIGH_SCORE

; --- RAM arrays (outside zero page; a cartridge never uses BASIC/PRG/CF RAM) ---
SEGMENTS_X      := $0800   ; 256 bytes — ring buffer of segment columns
SEGMENTS_Y      := $0900   ; 256 bytes — ring buffer of segment rows
OCCUPANCY       := $0A00   ; 768 bytes — 32x24 grid, row*32+col: 0=empty 1=snake 3=wall
