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

### 001 - UI controls do not auto-hide when idle
- Bug ID: 001
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

### 002 - Some tooltips appear at the wrong location after CRT selection
- Bug ID: 002
- Summary: Some tooltips in the CRT/cart loading UI do not appear in the correct place, while others do.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop UI
- Steps to reproduce:
  1. Open the UI area that shows a tooltip for the CRT loading control.
  2. Hover or trigger the tooltip.
  3. Select a CRT entry.
  4. Observe where the tooltip appears.
- Expected behavior: Every tooltip should appear near the actual control or button that triggered it.
- Actual behavior: The load cart button tooltip still appears after selection and is positioned at the current cursor location rather than the control. Other tooltips (for example, Power Cycle and Reset) appear correctly.
- Severity: Medium
- Notes: This appears to be a control-specific UI event/positioning bug rather than a core emulation issue, since some controls already position tooltips correctly.

### 003 - Unloading a cartridge that left the VDP in a custom graphics mode corrupts the following BASIC/Monitor boot screen
- Bug ID: 003
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

### 004 - Joy key selection does not persist across emulator restart
- Bug ID: 004
- Summary: Joystick key mapping settings are lost after closing and reopening the emulator.
- Emulator version / commit: Not recorded
- Platform / environment: macOS, desktop UI
- Steps to reproduce:
  1. Open input settings and set Joy1 or Joy2 key mode (for example Num Pad, WASD, or Arrows).
  2. Close the emulator.
  3. Reopen the emulator.
  4. Check the Joy key selection.
- Expected behavior: Joy key selections should be saved and restored on next launch.
- Actual behavior: Joy key selection resets and does not persist across app restarts.
- Severity: Medium
- Notes: This appears to be a settings persistence issue in the UI/preferences layer.

---

## Feature Requests

### FR-001 - Make Joy1 and Joy2 controls in the bottom panel clickable for quick mapping
- Request ID: FR-001
- Summary: The Joy1 and Joy2 indicators in the bottom screen panel should be pressable and open the key mode picker directly.
- Desired behavior:
  1. Clicking Joy1 opens a menu for Joy1 mapping mode.
  2. Clicking Joy2 opens a menu for Joy2 mapping mode.
  3. Menu options include Num Pad, WASD, and Arrows.
  4. The currently active option is clearly highlighted.
- Value: Faster access to control setup without navigating deeper settings menus.
- Notes: This should complement, not replace, existing settings controls.

### FR-002 - Clarify and separate Fire key mappings per control scheme
- Request ID: FR-002
- Summary: Fire key behavior is unclear for Num Pad and WASD schemes, especially when mappings can overlap.
- Desired behavior:
  1. Show the Fire key for each scheme explicitly in UI/help text.
  2. Prevent conflicting defaults where practical, or warn clearly when conflicts exist.
  3. Allow independent Fire mapping per scheme and per joystick when supported.
- Value: Reduces confusion and accidental key conflicts during gameplay.
- Notes: Current behavior suggests ambiguity around shared key space for Fire across schemes.
