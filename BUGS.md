# Emulator Bugs

This file is for issues discovered in the 6502 emulator itself, not in this repository.

## Bug Report Template

- Bug ID:
- Summary:
- Emulator version / commit:
- Platform / environment:
- Steps to reproduce:
- Expected behavior:
- Actual behavior:
- Severity:
- Notes:

---

## Logged Issues

### 001 - Fullscreen viewport loses centering after app is backgrounded
- Bug ID: 001
- Summary: When the emulator is running in fullscreen, the game display loses its centered positioning after the app is swiped away and brought back, especially after repeated transitions.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, likely Electron-based fullscreen window behavior
- Steps to reproduce:
  1. Start the emulator in fullscreen.
  2. Open another app or swipe the emulator away from the foreground.
  3. Return to the emulator.
  4. Repeat a few times.
- Expected behavior: The game screen remains centered and stable after returning from the background.
- Actual behavior: The screen appears offset or no longer centered after the window is reactivated.
- Severity: Medium
- Notes: May be related to Electron window redraw / fullscreen state handling.

### 002 - UI controls do not auto-hide when idle
- Bug ID: 002
- Summary: The emulator UI does not automatically hide or reduce visibility of buttons and controls when the mouse is not moving or hovering.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop UI
- Steps to reproduce:
  1. Launch the emulator with the UI visible.
  2. Stop moving the mouse for a short period.
  3. Observe whether buttons and controls remain visible.
- Expected behavior: The UI should automatically hide or dim when idle to reduce distraction and improve immersion.
- Actual behavior: Buttons and other interactive elements remain visible at all times.
- Severity: Low
- Notes: This may be a UX enhancement but is worth tracking as a usability issue.

### 003 - Clickable controls should use pointer cursor
- Bug ID: 003
- Summary: Interactive controls do not visibly indicate that they are clickable.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop UI
- Steps to reproduce:
  1. Hover over buttons or other clickable UI elements.
  2. Observe the cursor style.
- Expected behavior: The cursor should change to a pointer when hovering over clickable controls.
- Actual behavior: The cursor does not change, making the controls feel less interactive.
- Severity: Low
- Notes: This is a small but noticeable usability issue.

### 004 - Tooltips appear at the wrong location after CRT selection
- Bug ID: 004
- Summary: Tooltips do not appear in the correct place when interacting with the CRT load UI.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop UI
- Steps to reproduce:
  1. Open the UI area that shows a tooltip for the CRT loading control.
  2. Hover or trigger the tooltip.
  3. Select a CRT entry.
  4. Observe where the tooltip appears.
- Expected behavior: The tooltip should appear near the actual control or button that triggered it.
- Actual behavior: The tooltip appears after selection and is positioned at the current cursor location rather than the control.
- Severity: Medium
- Notes: This looks like a UI event / positioning bug rather than a core emulation issue.

### 005 - Debug server port and token are not copyable
- Bug ID: 005
- Summary: The debug server connection details cannot be copied easily from the UI.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop UI
- Steps to reproduce:
  1. Open the debug server panel.
  2. Try to copy the displayed port or token.
  3. Observe whether selection/copy works.
- Expected behavior: The port and token should be copyable via normal UI copy actions, ideally with a dedicated copy button.
- Actual behavior: The values are not readily copyable and require awkward selection behavior.
- Severity: Medium
- Notes: A simple copy button or click-to-copy interaction would improve usability significantly.

### 006 - Joypad input mapping should support WASD and arrow keys
- Bug ID: 006
- Summary: The emulator does not expose Joy 1 and Joy 2 as configurable input devices in a way that supports common keyboard layouts such as WASD and arrows, which is especially problematic on MacBook keyboards without a numpad.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop keyboard input
- Steps to reproduce:
  1. Launch the emulator and attempt to configure Joy 1 or Joy 2 input.
  2. Try to assign movement keys using WASD or arrow keys.
  3. Notice that the input mapping does not provide a practical option for these layouts.
- Expected behavior: Joy 1 and Joy 2 should be configurable with common keyboard layouts such as WASD and arrow keys, and the fire button mapping should be clear and usable.
- Actual behavior: The emulator requires explicit or limited input mapping behavior, making keyboard play awkward on laptops without a numpad.
- Severity: Medium
- Notes: The fire-button assignment for the two-button layout is still unclear and may need a more intuitive default or customization option.

### 007 - Unloading a cartridge that left the VDP in a custom graphics mode corrupts the following BASIC/Monitor boot screen
- Bug ID: 007
- Summary: If a cartridge was running in a TMS9918 graphics mode (e.g. Graphics I) with a custom palette/pattern table, unloading it (or reloading a different cart) and warm-resetting back into BASIC/Monitor renders a corrupted, garbled screen instead of a clean boot — readable text fragments mixed with stray CP437 glyphs, wrong colors/background.
- Emulator version / commit: 2.6.2 (Electron)
- Platform / environment: macOS, desktop app (also checked against the headless CLI's source, same version)
- Steps to reproduce:
  1. Load a cartridge that switches the VDP into Graphics I mode with a non-default color table (e.g. this repo's Snake.crt).
  2. Play for a bit so the cart's custom VRAM content (tiles, colors, name table) is well established.
  3. In Settings, click "Unload" on the Cart row (or load a different cartridge file over it).
  4. Observe the screen immediately after the resulting reset.
- Expected behavior: BASIC/Monitor's boot/splash screen renders cleanly regardless of what graphics mode/VRAM state the previous cartridge left behind.
- Actual behavior: The boot screen renders corrupted — a mix of legible leftover text and garbled characters, often with the wrong backdrop color.
- Severity: Medium
- Notes: Root-caused this together in a debugging session (connected live via the Debug Server to the running app while reproducing it). The likely mechanism: `unloadCart()` in `src/renderer/src/stores/emulator.ts` calls `machine.unloadCart()` then `session.reset(false)` — a **warm** reset. `Video.reset(coldStart)` in `src/core/IO/Video.ts` only clears VRAM `if (coldStart)`, so a warm reset leaves the previous cartridge's Graphics I VRAM (custom pattern table, color table, name table) fully intact. BASIC/Monitor's own boot sequence doesn't appear to fully reprogram the VDP back to its expected default state before drawing, so it ends up rendering against stale, wrong-mode VRAM. A workaround that avoids it: use Power Cycle (which does `vram.fill(0)` on cold start) instead of Reset when unloading or swapping cartridges that use custom graphics modes. Possible fixes: have BASIC/Monitor's boot path fully reinitialize the VDP (registers + color table, not just the character set) before drawing anything, regardless of prior state; or have cartridge unload/swap force a cold reset instead of warm.
