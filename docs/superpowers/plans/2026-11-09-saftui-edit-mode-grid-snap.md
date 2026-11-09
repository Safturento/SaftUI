# Edit mode grid and snapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SaftUI's edit mode gets three things:
- a visible alignment grid, centered on the screen;
- toggleable snap to grid;
- toggleable snap to other frames.

**Architecture:**
- **Pure math** (grid line positions, snap choice) lives as plain functions on `st.EditModeFrames` (`EM`), so a lupa harness can test it.
- **Grid drawing, settings UI and snapping** are three new files in `SaftUI-Core/EditMode/`.
- **The drag** (`mover.lua`) gains one snap step. Offsets keep their anchor, as today.

**Tech Stack:** WoW addon Lua (Forever 16001 and retail 120000), Ace3 (AceConfig, AceEvent through `st:NewModule`), and a lupa harness (Python `lupa`, Lua 5.5) in the session scratchpad.

**Spec:** `docs/superpowers/specs/2026-11-09-saftui-edit-mode-grid-snap-design.md`. Read it, including its "Builder's calls".

## Global Constraints

- **Settings** live in the profile at `st.config.profile.editmode`, with keys `grid` (bool), `grid_size` (number), `snap_grid` (bool) and `snap_frames` (bool). The defaults are `false`, `32`, `false` and `false`. Read them at call time, never cache the table (profile switches replace it).
- **Old keys:** remove `st.defaults.grid` and `editmode.snap` from `SaftUI-Core/Config/defaults.lua`. That file has CRLF line endings in the working copy; keep them.
- **Grid size** comes from a slider, 8 to 128, step 1.
- **Snap reach** is the constant `SNAP_REACH = 8`, in UIParent units.
- **Ctrl** held during a drag turns snapping off (`IsControlKeyDown()`).
- **Taint:** SaftUI-owned frames and textures only. No Blizzard frame is touched (`.agents/taint.md`).
- **Snapping** never changes a frame's anchor point or relative frame. Only `x_off`/`y_off` change, rounded with `st:RoundToPixel(value, frame)`.
- **Where tests run:**
  - The repo has no test runner. Tests live in the session scratchpad at `/tmp/claude-1000/-mnt-c-Github-wow-addons-SaftUI-Modular/f9fdefff-45d5-4c08-9fb0-3c0ba643bed7/scratchpad/emsim/`.
  - They run with `/tmp/claude-1000/-mnt-c-Github-wow-addons-SaftUI-Modular/f9fdefff-45d5-4c08-9fb0-3c0ba643bed7/scratchpad/lupavenv/bin/python emsim/run.py <test.lua>` from the scratchpad.
  - `run.py` loads a stub world, then the EditMode files under test, then the test file. It exits non-zero on any failure.
- **Commits** go on the branch you're given. Every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **A frame with its own scale** (e.g. a Blizzard frame SaftUI scales with `SetScale`): its snapped edge should land on the line on screen, not off by the scale ratio. Pinned by `snapped offset honours the frame's scale` (Task 2).
2. **Dragging a frame others are anchored to** (Target, with TargetTarget anchored to it): the attached frames move along and must not be snap targets. Pinned by `MovesWith` tests and `GetSnapLines skips frames that move with the dragged one` (Task 2).
3. **Grid size at its smallest on a big screen** (8px on 3840 wide): line textures are pooled, and lowering the line count hides the extras rather than leaking. Pinned by `UpdateGrid reuses and hides pooled lines` (Task 1).
4. **A profile switch while editing:** the grid follows the new profile's toggle and size. Pinned by `UpdateConfig refreshes the grid` (Task 1).
5. **Odd screen width or height:** the center line sits on the rounded center pixel. Pinned by `center line on the rounded center` (Task 1).

---

### Task 1: Settings, grid drawing and the controls

**Files:**
- Modify: `SaftUI-Core/Config/defaults.lua` (`st.defaults.grid`, `st.defaults.editmode`)
- Create: `SaftUI-Core/EditMode/grid.lua` (grid frame, line math, `EM:UpdateGrid`)
- Create: `SaftUI-Core/EditMode/settings.lua` (footer toggles, `/sui` section, events)
- Modify: `SaftUI-Core/EditMode/editmode.lua` (`EM:UpdateConfig` refreshes grid and toggles)
- Modify: `SaftUI-Core/EditMode/load.xml`. Add `grid.lua`, `snap.lua` and `settings.lua` after `footer.lua`, in that order. Create `snap.lua` as an empty stub file now (`local st = SaftUI`), and Task 2 fills it.
- Modify: `.agents/edit-mode.md` (grid and controls), `README.md` (the `/sui edit` usage line)
- Test: `emsim/run.py`, `emsim/stubs.lua`, `emsim/test_grid.lua` (scratchpad)

**Interfaces:**
- Produces:
  - `EM.GridLinePositions(center, low, high, size) -> { number... }`: every `center + k*size` (k any integer) with `low <= p <= high`, ascending. When `size < 1` it returns `{ center }`.
  - `EM:GetSettings() -> table`, which returns `st.config.profile.editmode`.
  - `EM:UpdateGrid()` shows the grid if `self.active and settings.grid`, otherwise hides it. When shown, it redraws it.
  - `EM:UpdateFooterToggles()`.
  - `EM:GetConfigTable()` makes the `/sui` section, keyed `EditMode` by module name, with the name "Edit mode".

- [ ] **Step 1: Write the harness and the failing tests.**
  - `stubs.lua` provides:
    - `SaftUI` (`st`): `st.config.profile.editmode`, `st:RoundToPixel(v) = math.floor(v + 0.5)`, `st:GetPixelSize() = 1`, `st:CreateFrame`, and colors with `GetRGB`;
    - `UIParent` with `GetWidth`/`GetHeight` set by the test;
    - frames whose `CreateTexture` returns recordable textures (`SetPoint`, `SetColorTexture`, `SetWidth`/`SetHeight`, `Show`/`Hide`, `IsShown`);
    - `st.EditModeFrames` with `EM:On`, `EM.movers = {}` and `st:SafeReposition(frame, key, fn)` that calls `fn()`.
  - `test_grid.lua` asserts:
    - `GridLinePositions(960, 0, 1920, 32)` has 61 entries, the first is 0, the last 1920, and it contains 960.
    - `GridLinePositions(960, 0, 1920, 100)` has 19 entries, from 60 to 1860.
    - `GridLinePositions(720, 0, 1440, 128)` has 11 entries, from 80 to 1360.
    - `GridLinePositions(500, 0, 1000, 0)` equals `{ 500 }`.
    - `center line on the rounded center`: with UIParent 1921×1081, `EM.active = true` and `grid = true`, `UpdateGrid` draws a center vertical line at x = 961 and a center horizontal line at y = 541, each in a color distinct from the other lines.
    - `UpdateGrid hides when inactive`: with `EM.active = false`, the grid frame is hidden.
    - `UpdateGrid reuses and hides pooled lines`: at size 8 on 3840×2160 then size 64, the second draw creates no new textures, and exactly the second draw's line count is shown.
    - `UpdateConfig refreshes the grid`: set the profile's `grid = false` and call `EM:UpdateConfig()`, and the grid is hidden. Set `grid = true` and call it again, and it's shown.
- [ ] **Step 2: Run** `lupavenv/bin/python emsim/run.py emsim/test_grid.lua`. Expected: FAIL, with `GridLinePositions` undefined.
- [ ] **Step 3: Defaults.** Remove `st.defaults.grid`. Set `st.defaults.editmode = { grid = false, grid_size = 32, snap_grid = false, snap_frames = false }`.
- [ ] **Step 4: `grid.lua`.**
  - **The frame:** a SaftUI frame on UIParent (`SetAllPoints(UIParent)`) at strata `BACKGROUND`, with `EnableMouse(false)`, hidden by default.
  - **Lines:** textures from a pool, each 1 physical pixel thick (`st:GetPixelSize(gridFrame)`). Vertical lines are placed from the frame's left edge, horizontal lines from its bottom edge.
  - **Center:** `st:RoundToPixel(UIParent:GetWidth() / 2, UIParent)`, and the same for the height.
  - **Look:** center lines clearly stronger than the others (e.g. `colors.button.blue` at high alpha; the others white at low alpha). The exact look is your call.
  - **When it updates:** `UpdateGrid` runs on `EM:On('Enabled')` and `EM:On('Disabled')`.
- [ ] **Step 5: `settings.lua`.**
  - **Footer buttons**, made in `EM:OnEnable` (define it, or extend it if one exists): `EM:AddFooterButton('Grid', …)`, `'Snap to grid'` and `'Snap to frames'`. Each flips its key, then calls `EM:UpdateGrid()` and `EM:UpdateFooterToggles()`. `UpdateFooterToggles` gives each button a visible on/off look; you choose how.
  - **The `/sui` section:** `EM:GetConfigTable()` returns a group with an inner `general` group holding:
    - `grid` (toggle "Show grid");
    - `grid_size` (`st.Config.generators.range(…, 'Grid size', 8, 128, 1)`);
    - `snap_grid` (toggle "Snap to grid");
    - `snap_frames` (toggle "Snap to frames").

    Its get and set go through `EM:GetSettings()`. Set calls `UpdateGrid` and `UpdateFooterToggles`.
  - **Events:** in `OnEnable`, register `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` to call `EM:UpdateGrid()`.
- [ ] **Step 6: `editmode.lua`.** At the end of `EM:UpdateConfig()`, call `self:UpdateGrid()` and `self:UpdateFooterToggles()`. Guard the second, since the footer buttons may not exist yet.
- [ ] **Step 7: Run the tests.** Expected: every check passes. Also syntax-check every changed `.lua` file with lupa's `load`.
- [ ] **Step 8: Docs.**
  - `.agents/edit-mode.md`: add the grid, the footer toggles and the "Edit mode" `/sui` section to its opening list, and bump `last_updated`.
  - `README.md`: extend the `/sui edit` bullet with the grid and the snap toggles, and Ctrl to drag freely. Ctrl lands in Task 2; write the line once, here.
- [ ] **Step 9: Commit.** Message: `editmode: alignment grid, with grid and snap toggles`.

### Task 2: Snapping

**Files:**
- Modify: `SaftUI-Core/api.lua`. Add `st:MovesWith`, and have `st:ValidateAnchor` use it.
- Modify: `SaftUI-Core/EditMode/snap.lua` (snap math and targets)
- Modify: `SaftUI-Core/EditMode/mover.lua` (`EM:StartDrag`, `EM:UpdateDrag`)
- Modify: `.agents/edit-mode.md` (snapping)
- Test: `emsim/test_snap.lua` (scratchpad)

**Interfaces:**
- Consumes: `EM.GridLinePositions`, `EM:GetSettings()` (Task 1).
- Produces:
  - `st:MovesWith(frame, target) -> boolean`. True if `frame == target`; or if an anchor of `frame` reaches `target`, directly or through other frames (today's local `AnchorReaches` in `api.lua`); or if `target` is an ancestor of `frame` through `GetParent`. `st:ValidateAnchor(frame, relative)` keeps its messages but uses `st:MovesWith(relativeFrame, frame)` for its loop checks.
  - `EM.SnapAxis(edges, lines, reach) -> number`. Over every (edge, line) pair with `|line - edge| <= reach`, it returns `line - edge` for the smallest `|line - edge|`. A tie goes to the earlier edge in `edges`. With no pair in reach it returns 0.
  - `EM.SnapDrag(rect0, dx, dy, xLines, yLines, reach) -> sx, sy`:
    - `rect0` is `{ left, right, bottom, top }` at drag start, in UIParent units.
    - `dx` and `dy` are the raw drag delta in UIParent units.
    - The x edges are `left+dx`, `(left+right)/2+dx` and `right+dx`; the y edges are `bottom+dy`, the center plus `dy`, and `top+dy`.
  - `EM.SnappedOffset(x0, d, s, ratio) -> number`, which returns `x0 + (d + s) * ratio`, unrounded.
  - `EM:GetSnapLines(mover) -> xLines, yLines`, in UIParent units:
    - with `snap_grid`, the grid's positions across the screen, from `GridLinePositions` with Task 1's center;
    - with `snap_frames`, the screen's center lines, plus `left`, `(left+right)/2` and `right` (and `bottom`, the middle and `top`) of every other mover whose `overlay:IsShown()` and whose rect overlaps the screen. Skip any mover whose `def.frame` satisfies `st:MovesWith(other.def.frame, mover.def.frame)`.

- [ ] **Step 1: Write the failing tests** in `test_snap.lua`:
  - `SnapAxis({100,150,200}, {0,96,300}, 8) == -4`
  - `SnapAxis({100,150,200}, {205}, 8) == 5`
  - `SnapAxis({100,150,200}, {97,203}, 8) == -3` (a tie, so the earlier edge wins)
  - `SnapAxis({100,150,200}, {120}, 8) == 0` (nothing in reach)
  - `SnapAxis({100,150,200}, {108}, 8) == 8` (exactly at reach snaps)
  - `SnapDrag({left=100,right=200,bottom=50,top=80}, 10, 0, {113}, {}, 8)` returns `sx == 3` and `sy == 0`. The drag puts the left edge at 110, 3 short of the line.
  - `snapped offset honours the frame's scale`: `SnappedOffset(20, 10, 3, 0.5) == 26.5`
  - `MovesWith`, with mock frames (`GetNumPoints`, `GetPoint`, `GetParent`):
    - a frame anchored to the target is true;
    - one anchored through a middle frame is true;
    - a child of the target is true;
    - an unrelated frame is false;
    - the target itself is true;
    - an anchor cycle that doesn't include the target terminates and is false.
  - `GetSnapLines skips frames that move with the dragged one`: two other movers, one anchored to the dragged frame, with `snap_frames` on and `snap_grid` off. Only the unanchored mover's three x values, plus the screen center, are in `xLines`.
  - `GetSnapLines with both off` returns two empty lists.
- [ ] **Step 2: Run** `lupavenv/bin/python emsim/run.py emsim/test_snap.lua`. Expected: FAIL, with the functions undefined.
- [ ] **Step 3: Implement** `st:MovesWith` (refactoring `ValidateAnchor` onto it), and `EM.SnapAxis`, `EM.SnapDrag`, `EM.SnappedOffset` and `EM:GetSnapLines` in `snap.lua`, with `local SNAP_REACH = 8`.
- [ ] **Step 4: Wire the drag** (`mover.lua`):
  - **`EM:StartDrag`** also stores two things on `mover.drag`:
    - `rect0`, the frame's rect in UIParent units: each of `GetLeft`, `GetRight`, `GetBottom` and `GetTop` × `frame:GetEffectiveScale() / UIParent:GetEffectiveScale()`, skipped if any is nil;
    - the snap lines from `EM:GetSnapLines(mover)`, computed once per drag.
  - **`EM:UpdateDrag`** keeps the cursor delta in UIParent units (`dUIx`, `dUIy`, before `* ratio`).
    - Unless `IsControlKeyDown()`, `rect0` is missing, or both line lists are empty, it gets `sx, sy = EM.SnapDrag(rect0, dUIx, dUIy, xLines, yLines, SNAP_REACH)`.
    - Then `drag.x = st:RoundToPixel(EM.SnappedOffset(drag.x0, dUIx, sx, ratio), frame)`, and the same for y with `sy`.
    - Nudges are unchanged.
  - Expose `SNAP_REACH` to `mover.lua` as `EM.SNAP_REACH`.
- [ ] **Step 5: Run the tests,** both `test_snap.lua` and `test_grid.lua`. Expected: every check passes. Syntax-check the changed files.
- [ ] **Step 6: Docs.** In `.agents/edit-mode.md`, describe snapping:
  - what it snaps to;
  - that it only changes offsets;
  - that Ctrl suspends it;
  - that frames moving with the dragged one are skipped (`st:MovesWith`).

  Bump `last_updated`.
- [ ] **Step 7: Commit.** Message: `editmode: snap to the grid and to other frames while dragging`.

## In-game checks (for the user, after both tasks)

- `/sui edit`: the footer shows Grid, Snap to grid and Snap to frames. Grid toggles the grid. The center lines are clearly stronger. `/sui` → Edit mode → Grid size redraws the grid live.
- With Snap to grid on, dragging the minimap near a line makes it jump onto it. With Ctrl held, it doesn't.
- With Snap to frames on, dragging the experience bar lines its edges up with the minimap's. Dragging Target doesn't snap to TargetTarget.
- Arrow keys still nudge 1px and 10px, ignoring snapping.
- After a profile switch, the grid follows the new profile's settings.
