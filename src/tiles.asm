; =============================================================================
;   tiles.asm — Graphics I playfield constants and custom 8x8 tile patterns
; =============================================================================

GRID_COLS       = 32
GRID_ROWS       = 24

; Playable interior bounds (row 0 = HUD, row 1/22 = border, row 23 = messages)
FIELD_LEFT      = 1
FIELD_RIGHT     = 30
FIELD_TOP       = 2
FIELD_BOTTOM    = 21

; Tile codes — each in its own color group (group = code>>3) so it gets an
; independent fg/bg pair without disturbing the CP437 text glyphs used by
; the HUD and messages (groups 4-11 for space/digits/uppercase letters).
TILE_BLANK      = $20    ; reused CP437 space glyph — untouched
TILE_HEAD       = $80    ; color group 16
TILE_BODY       = $88    ; color group 17
TILE_FOOD       = $90    ; color group 18
TILE_WALL       = $98    ; color group 19
TILE_FRAME      = $A0    ; color group 20 — game-over overlay box border

COLOR_HEAD      = (TMS_LT_GREEN  << 4) | TMS_BLACK
COLOR_BODY      = (TMS_MED_GREEN << 4) | TMS_BLACK
COLOR_FOOD      = (TMS_MED_RED   << 4) | TMS_BLACK
COLOR_WALL      = (TMS_GRAY      << 4) | TMS_DK_BLUE
COLOR_FRAME     = (TMS_LT_YELLOW << 4) | TMS_LT_YELLOW
COLOR_TEXT      = (TMS_WHITE     << 4) | TMS_BLACK   ; default fill for all other groups

; Pattern-table destinations ($0800 base + code*8, per InitVideo's font load)
PATTERN_BASE    = $0800
PAT_HEAD_ADDR   = PATTERN_BASE + (TILE_HEAD*8)
PAT_BODY_ADDR   = PATTERN_BASE + (TILE_BODY*8)
PAT_FOOD_ADDR   = PATTERN_BASE + (TILE_FOOD*8)
PAT_WALL_ADDR   = PATTERN_BASE + (TILE_WALL*8)
PAT_FRAME_ADDR  = PATTERN_BASE + (TILE_FRAME*8)

; Game-over overlay box geometry (screen is 32x24; playfield rows 2-21)
BOX_LEFT        = 6
BOX_TOP         = 8
BOX_WIDTH       = 20
BOX_HEIGHT      = 8

.segment "CART"

; 8x8 bitmaps, MSB = leftmost pixel, 1 = ink

TileHeadData:
  .byte %00111100
  .byte %01111110
  .byte %11011011      ; eye dots punched into the blob
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %01111110
  .byte %00111100

TileBodyData:
  .byte %00111100
  .byte %01111110
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %01111110
  .byte %00111100

TileFoodData:
  .byte %00011000
  .byte %00111100
  .byte %01111110
  .byte %11111111
  .byte %11111111
  .byte %01111110
  .byte %00111100
  .byte %00011000

TileWallData:
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111

TileFrameData:
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %11111111
