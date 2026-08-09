Snake
=====

A classic grid-based Snake game, built as a standalone ROM cartridge for the
[A.C. Wright 6502](https://github.com/acwright/6502-ACE) family of computer
systems, using the [6502-CRT](https://github.com/acwright/6502-CRT) template.

![Snake gameplay](screenshot.png)

Boots directly from the cartridge — no BASIC, no loading screen. Grow by
eating the food, avoid the walls and your own tail. Beats the high score?
The title screen remembers, across restarts and — on hardware with the RTC
card fitted — across power cycles too.

## Controls

- **W A S D**, **Arrow keys**, or **Joystick 1** — move
- **Space** or **Fire** — start / restart, and pause / resume during play

## Building

Requires [cc65](https://github.com/cc65/cc65) (`brew install cc65` on macOS):

```bash
make
```

Produces `Snake.crt` — a 32 KB ROM image (`$8000–$FFFF`), ready to run in the
[6502-EMULATOR](https://github.com/acwright/6502-EMULATOR) or burn to a
28C256/27C256 EEPROM.

```bash
make run      # launch the emulator with Snake.crt loaded
make eeprom   # burn to an AT28C256 via a TL866 programmer + minipro
```

## How it's built

- **Graphics:** TMS9918 Graphics I mode (32×24 cells), with five custom 8×8
  tiles (head, body, food, wall, overlay frame) hand-authored as raw pattern
  bytes — see `src/tiles.asm`. The Kernal's `InitVideo` is used once at boot
  purely for its side effect of loading the CP437 font into VRAM, then the
  VDP is reprogrammed directly for Graphics I (`src/vdp.asm`). HUD text and
  the game-over overlay reuse the surviving CP437 letter/digit glyphs via
  direct name-table pokes, since the Kernal's text routines assume its own
  40-column layout. Every multi-byte VDP register/address write is wrapped
  in `PHP`/`SEI`/`PLP` — the VDP is itself an IRQ source, and its own status
  read resets the same two-byte write latch our own writes depend on, so an
  interrupt landing mid-sequence (routine at real frame rates, not in
  headless turbo-speed testing) would otherwise scramble the screen.
- **Title screen:** lives entirely in Graphics I too (not the Kernal's
  separate text mode), so it shares the exact same tiles, palette, and
  black background as gameplay instead of looking like a bolted-on splash
  screen — right down to a little snake-chasing-an-apple decoration built
  from the same head/body/food tiles.
- **Game over:** a highlighted box overlay centered on the board (not a
  footer line) shows the final score and, when it's a new record, calls
  that out explicitly — otherwise it shows the standing high score for
  reference.
- **High score:** tracked for the whole power-on session in RAM, and
  persisted across power cycles via the RTC card's 256-byte battery-backed
  NVRAM when that card is fitted (`RtcReadNVRAM`/`RtcWriteNVRAM`, gated on
  `HW_RTC` — see `LoadHighScore`/`SaveHighScore` in `src/game.asm`). The
  cartridge ROM itself is read-only and has no storage of its own.
- **Game logic:** `src/game.asm` — a ring buffer of snake segments, a
  32×24 occupancy grid for O(1) collision checks, and a repeated-subtraction
  binary-to-decimal routine for score/high-score digit display.
- **Randomness:** an 8-bit Galois LFSR (`src/rng.asm`), seeded from
  reaction-time entropy at the title screen plus the RTC clock if fitted.
- **Input:** `src/input.asm` polls `ReadJoystick1` (gated on `HW_GPIO`,
  since that call doesn't check hardware presence itself) and drains the
  keyboard buffer for WASD/arrow keys — note the Kernal delivers
  **uppercase** ASCII for letters, and arrow keys arrive as control codes
  ($1C-$1F), not as printable characters.

## Project layout

| File | Purpose |
|------|---------|
| `Snake.asm` | Cartridge entry point, title screen, main loop, CPU vectors |
| `src/zeropage.inc` | Zero-page variables and RAM array layout |
| `src/tiles.asm` | Graphics I constants and custom 8×8 tile bitmaps |
| `src/vdp.asm` | TMS9918 register/VRAM primitives and Graphics I setup |
| `src/rng.asm` | LFSR pseudo-random generator |
| `src/input.asm` | Joystick + keyboard polling |
| `src/sound.asm` | Eat / death sound effects |
| `src/game.asm` | State machine: tick logic, HUD, game over |
| `6502.inc` / `6502.cfg` | Vendored system include and linker config (unmodified) |

## Verification

Built and tested end-to-end against the emulator's headless CLI and
JSON-RPC debug protocol (`6502 run --headless --debug`, `6502 dbg ...`):
title screen, Graphics I rendering, movement, turning, food/growth/scoring,
wall and self collision, restart-from-game-over, and the no-video-card
fallback were all exercised and visually/programmatically confirmed.

## License

MIT License — see [LICENSE](LICENSE).
