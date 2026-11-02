# Ibis-Lua — Windows UI reconstruction

**Goal:** faithfully rebuild the **ibisPaint for Windows** interface in **Lua / LuaJIT + LÖVE 11.5**, without a painting or image-processing engine.

**Official reference:** Windows **14.1.4**, released on **October 28, 2026**.

**Current status:** first new implementation. **Incomplete; not visually verified as 1:1.** The old implementation was completely discarded.

## Run on Windows

1. Install LÖVE 11.5: https://love2d.org/
2. Clone or download this repository.
3. Double-click `testar.bat` in the project root.
4. Alternatively run `love .` from this directory.

`testar.bat` searches for a local `love.exe`, Program Files installations, and the executable in PATH, then displays launch errors.

## Implemented initial UI flow

- Title screen > My Gallery > + > New Canvas > Editor.
- New canvas presets, width/height input, in-memory gallery.
- Vertical editor tool selector.
- Brush list and simulated size/opacity controls.
- Layer list, add, duplicate, delete, toggle visibility, blending and opacity.
- Color swatches and selected color.
- Settings view, back navigation, zoom and simulated canvas movement.
- B: Brush; E: Eraser; L: Layers; Esc: Back; F12: capture screenshot to the LÖVE save directory.

**No real brush marks, image pixels, filters, project import/export, or rendering of works are implemented.**

## Project structure

- `main.lua`: views and interactions
- `src/model.lua`: application state and data
- `src/ui.lua`: drawing and hit-test primitives
- `tests/test_model.lua`: state regression tests
- `docs/INVENTARIO.md`: screen inventory and open work
- `docs/REFERENCIAS.md`: official references and evidence gaps

## Testing

With Lua installed run `lua tests/test_model.lua`.

**Validation still required:** execution on a Windows machine running LÖVE 11.5, real screenshots, comparison with images captured from Windows ibisPaint 14.1.4 at the same resolution and DPI. The current hand-drawn icon geometry is provisional, not certified visually identical.

The reconstruction must stay Windows-specific; no Android layouts or proprietary ibisPaint resources are bundled.