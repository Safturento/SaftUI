# Blizzard theme, round 3: one border — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Under the Blizzard theme, every SaftUI panel, bar, tooltip, unit frame, group and micro menu box wears one border, the minimap button box, drawn over its content and the same weight at every size.

**Architecture:** One new art entry, `ThemeArt.ART.box` (Forever: a nine-slice cut of `ui-hud-minimap-header-button`'s Camelot member; retail: the existing `MINIMAP_BUTTON_KIT`). `ThemeArt.Paint` lays it on a SaftUI "box" frame placed `reach` outside the frame it borders and levelled above that frame's children, instead of on the backdrop below. Kinds keep their insets, so no layout moves. Callers that lay art themselves (the group border, the micro menu) switch to the same box.

**Tech Stack:** Lua 5.1 WoW addon (Forever 16001, retail 120000); tests are the repo's stub harness, `tests/run` (`.agents/testing.md`).

**Spec:** `docs/superpowers/specs/2026-11-17-saftui-blizzard-theme-one-border-design.md`. Read it first: its "The design" section is the source for every value below.

## Global Constraints

- Nothing changes under Thick or Thin (spec goal 5). Every task's tests also assert its frame under Thick is unchanged.
- No kind's `inset` changes: `ThemeArt.Inset`, `st:ThemeInset`, `st:DrawnInset` and `st:CalculateSpacing` return today's values ("Nothing moves").
- The box sits `reach` = 4 outside a frame drawn behind content (`st:SetBackdrop`, `st:SetBackdropIn`, or `st:SetTemplate` given `over`), and `reach` = 0 (inside its bounds) on a frame drawn on itself (`st:SetTemplate` with no `over`) and on micro menu boxes.
- Art goes on frames of SaftUI's only; nothing created on, written to or re-levelled on a Blizzard frame (`.agents/taint.md`). Never arithmetic on a secret frame level (`issecretvalue`).
- Forever atlas data: `ui-hud-minimap-header-button` → Camelot member in file 8026705 (512 x 512), member rect 256..408 x 256..279 (152 x 23). Box cut size 6.
- Lines in whole pixels of the frame (`ThemeArt.Whole`); `reach` is passed through it.
- Windows (`window`), rings (`action`, `slot`), auras, `small`, controls and `/sui`'s round-2 Settings art keep their art.
- Commits: lowercase `module: imperative summary`, explicit paths only, end with the session's Co-Authored-By line. Never `sed -i`, never bare `git stash`, nothing under `Libraries/`.

## Review Focus

1. **A theme switch away from Blizzard** (Thick, Thin, None, or a frame's own Theme) must hide the box frame and its pieces, not leave a bronze rim floating over a Thick frame. Test in Task 1.
2. **A frame first drawn while its owner's level is secret** (a Blizzard frame such as `GameTooltipStatusBar`): the box frame is made, placed and shown, with no level arithmetic and no error. Test in Task 1.
3. **An own border colour set, then cleared** (`st:SetBorderColor(f)` with no colour): the pieces lose the desaturation and the tint and read plain bronze again. Test in Task 2.
4. **A frame hidden and shown again** (a tooltip, the swing timer between swings): the box hides and shows with it, because it is a child of the drawn backdrop. Test in Task 1.
5. **A group border in combat:** a member joining in combat must not re-level anything protected; the border's level is only set out of combat. Test in Task 4.

---

### Task 1: The box, laid outside and over the content

**Files:**
- Modify: `SaftUI-Core/themeart_data.lua` (new `ART.box`; `KINDS.panel`, `.bar`, `.tooltip`, `.unitframe` take `art = 'box'` and `reach`; `ART.tooltip` stays only if something else still names it, else remove)
- Modify: `SaftUI-Core/themeart.lua` (`ThemeArt.Paint` gains `over`; new box frame and level helper; `ThemeArt.Clear` hides it)
- Modify: `SaftUI-Core/theme.lua` (`DrawBackdrop` passes its `owner` as `over`; `st:SetTemplate(frame, theme, background, kind, host, over)` gains `over`)
- Modify: `tests/wow/atlases.lua` (Forever `ui-hud-minimap-header-button` becomes `{ 152, 23, file = 8026705, coords = { 256 / 512, 408 / 512, 256 / 512, 279 / 512 } }`, with a comment naming its Camelot member, as the portrait entries have)
- Create: `tests/core/theme_blizzard_box_test.lua`
- Modify: `tests/core/theme_blizzard_draw_test.lua`, `tests/core/theme_blizzard_test.lua` (cases that assert the tooltip border on panel, bar or tooltip now assert the box)

**Interfaces:**
- Produces: `ThemeArt.ART.box` = `ByClient(cut, MINIMAP_BUTTON_KIT)`; the Forever cut is `{ layer = 'BORDER', size = 6, pieces = { TopLeftCorner = { atlas = 'ui-hud-minimap-header-button', rect = { 0, 6, 0, 6 } }, TopRightCorner = rect { 146, 152, 0, 6 }, BottomLeftCorner = { 0, 6, 17, 23 }, BottomRightCorner = { 146, 152, 17, 23 }, TopEdge = { 6, 146, 0, 6 }, BottomEdge = { 6, 146, 17, 23 }, LeftEdge = { 0, 6, 6, 17 }, RightEdge = { 146, 152, 6, 17 } }, centre = { 6, 146, 6, 17 } }`. Mark the atlas `Atlas(name, 'forever')`.
- Produces: `KINDS[kind].reach` = `ByClient(4, 4)` on panel, bar, tooltip, unitframe.
- Produces: `ThemeArt.Paint(frame, look, kind, host, pixel, over)`: with `over`, the box's pieces are laid on `ThemeArt.BoxFrame(frame)`, anchored `TOPLEFT over -r, r` / `BOTTOMRIGHT over r, -r` with `r = ThemeArt.Whole(reach, over, pixel)`; without `over`, anchored to `frame`'s own bounds (r = 0).
- Produces: `ThemeArt.BoxFrame(frame) -> Frame`: a frame of SaftUI's, child of `frame`, made once, kept in a weak table; its level is `ThemeArt.LevelAbove(over or frame)`.
- Produces: `ThemeArt.LevelAbove(target) -> number|nil`: one more than the highest non-secret level among `target` and its direct children (`target:GetChildren()`); nil when `target`'s own level is secret (the caller then leaves the level as made).
- Produces: `ThemeArt.LayBox(pieces, frame, centre)`: lays this client's box on `frame`'s own bounds into the caller's `pieces` (Forever by `LayCut`, retail by `LayBorder`), with the centre piece only when `centre` is true. Used by Task 5.

- [ ] **Step 1: Add the Forever atlas data to `tests/wow/atlases.lua`**

- [ ] **Step 2: Write the failing tests** in `tests/core/theme_blizzard_box_test.lua`, header comment in the file's usual style, each on both clients unless named:
  - `panel, bar and tooltip draw the box, 4 outside the frame, on a frame above it`: `st:SetBackdrop(f, 'theme', 'theme', kind)` for each kind; `T.art(f.backdrop)` lists the eight pieces (Forever: each `=8026705`); `T.around(ThemeArt.BoxFrame(f.backdrop), f) == '-4,4,4,-4'`; the box frame's level `> f:GetFrameLevel()`; `T.inset(f.backdrop)` equals today's inset (3) for each kind.
  - `the box is above the frame's children`: `f` with a child StatusBar at `f`'s level + 3 → box frame level == that + 1.
  - `Forever cuts the box from the header button`: `TopLeftCorner` coords = `px(256, 262, 256, 262, 512, 512)`; `TopEdge` = `px(262, 402, 256, 262, 512, 512)`; corners `6x6`; edges stretched, not tiled; no `Center` piece.
  - `retail draws the minimap button kit`: `T.art` lists the kit's eight pieces by atlas name (no Center).
  - `a frame drawn on itself keeps the box inside`: `st:SetTemplate(f, 'theme', 'theme', 'panel')` → `T.around(ThemeArt.BoxFrame(f), f) == '0,0,0,0'`.
  - `over places a self-drawn backdrop's box outside another frame`: `st:SetTemplate(b, 'theme', 'theme', 'panel', nil, owner)` → box around `owner` at `-4,4,4,-4`.
  - Review Focus 1, `switching to Thick, Thin or None hides the box`: after each switch, `ThemeArt.BoxFrame(f.backdrop):IsShown() == false` and `T.art(f.backdrop) == ''`; back to Blizzard shows it.
  - Review Focus 2, `a frame with a secret level gets its box with no level math`: stub `GetFrameLevel` to return a secret value on the owner; `SetBackdropIn` succeeds, the box is shown and placed.
  - Review Focus 4, `the box hides and shows with its frame`: `f:Hide()` → `BoxFrame(...):IsVisible() == false`; `f:Show()` → true.
  - `nothing moves`: `st:CalculateSpacing` and `st:ThemeInset` for panel, bar, tooltip and unitframe return the same numbers as on `modular` (copy them from `tests/core/theme_blizzard_draw_test.lua`'s inset cases).

- [ ] **Step 3: Run them to see them fail**
  Run: `tests/run tests/core/theme_blizzard_box_test.lua`. Expected: FAIL (`ThemeArt.BoxFrame` is nil).

- [ ] **Step 4: Implement** `ART.box`, `KINDS.*.reach`, `ThemeArt.BoxFrame`, `ThemeArt.LevelAbove`, `ThemeArt.LayBox` and the `over` path through `Paint`, `DrawBackdrop` and `st:SetTemplate`. `ThemeArt.Clear` hides the box frame. `Paint` dispatches `art == ART.box` before the existing `TopLeftCorner` / `IsCut` branches so other borders are untouched.

- [ ] **Step 5: Update the older theme tests** that asserted `Tooltip-NineSlice-*` on panel, bar or tooltip to assert the box; keep every window, ring, aura and small assertion as is.

- [ ] **Step 6: Run the core theme tests**
  Run: `tests/run tests/core`. Expected: PASS.

- [ ] **Step 7: Commit** `core: draw the Blizzard theme's one box over panels, bars and tooltips` with the files above.

### Task 2: A frame's own colour on the box

**Files:**
- Modify: `SaftUI-Core/themeart.lua` (`ThemeArt.SetBorder`, `ThemeArt.Color`)
- Test: `tests/core/theme_blizzard_box_test.lua`

**Interfaces:**
- Consumes: Task 1's box pieces in `ThemeArt.Get(frame).pieces`.
- Produces: under Blizzard, `st:SetBorderColor(f, r, g, b, a)` on a box-drawn frame sets every box piece `SetDesaturated(true)` and `SetVertexColor(r, g, b, a)`; with no colour, `SetDesaturated(false)` and white. Other arts (rings, own-colour icon border, small line) unchanged.

- [ ] **Step 1: Write the failing tests**
  - `an own colour shows on a desaturated box`: `st:SetBorderColor(f.backdrop, 0.64, 0.21, 0.93)` → each piece's stub `desaturated == true` and vertex colour `0.64,0.21,0.93,1.00`.
  - Review Focus 3, `clearing the own colour gives plain bronze back`: then `st:SetBorderColor(f.backdrop)` → `desaturated == false`, vertex `1.00,1.00,1.00,1.00`.
  - `a recolour pass (ThemeArt.Color) leaves the box plain`: after a colour, `st:UpdateTheme`-driven recolour → not desaturated, white.
- [ ] **Step 2: Run** `tests/run tests/core/theme_blizzard_box_test.lua`. Expected: the three new cases FAIL.
- [ ] **Step 3: Implement** in `ThemeArt.SetBorder` (the box branch) and `ThemeArt.Color`.
- [ ] **Step 4: Run** `tests/run tests/core`. Expected: PASS.
- [ ] **Step 5: Commit** `core: show a frame's own colour on the Blizzard box, desaturated`.

### Task 3: Unit frames: the box at every size

**Files:**
- Modify: `SaftUI-Unitframes/unitframes.lua` (`UF.SizedKind`, `UF.BoxFits`: under the box no size falls back to `small`; `UF.SizedKind` returns `UF.UnitKind(unit)`), `SaftUI-Unitframes/updaters.lua` (`BORDERED` comment and set), `SaftUI-Unitframes/grouppreview.lua` if it relies on `small`
- Modify: `SaftUI-Core/themeart_data.lua` (remove `ART.unitframe` and the `UF_PLAYER` / `UF_TARGET` locals; `KINDS.unitframe.art = 'box'`, `inset` unchanged at 2)
- Modify: `tests/wow/atlases.lua` (drop the two portrait entries only if no test or art still names them)
- Test: `tests/unitframes/blizzard_look_test.lua`, `tests/core/theme_blizzard_draw_test.lua` (the bronze box case becomes the box case)

**Interfaces:**
- Consumes: Task 1 (`KINDS.unitframe.reach`, the box over the frame's child bars via `LevelAbove`).
- Produces: `UF.SizedKind(unit, width, height) -> kind` no longer returns `'small'` for a unit frame unit; `UF.BoxFits` is removed if nothing else calls it.

- [ ] **Step 1: Write the failing tests** in `tests/unitframes/blizzard_look_test.lua`:
  - `an 8 tall power bar draws the box, not a line`: the player's separate power bar at 299 x 8 → its drawn kind is `unitframe`, `T.art` lists the box.
  - `the frame's box sits over its health and power bars`: player frame drawn; box frame level > the health bar's level.
  - `the 34 tall frame and its 8 tall bar have the same box`: both `T.art` equal (same pieces and file).
  - Under Thick the same frames draw exactly as on `modular` (keep the existing Thick cases green).
- [ ] **Step 2: Run** `tests/run tests/unitframes/blizzard_look_test.lua`. Expected: FAIL (`small` returned).
- [ ] **Step 3: Implement**; delete the dead under-12 path and its comments.
- [ ] **Step 4: Run** `tests/run tests/unitframes tests/core`. Expected: PASS.
- [ ] **Step 5: Commit** `unitframes: draw the Blizzard box on frames and bars of any size`.

### Task 4: The group border is the box

**Files:**
- Modify: `SaftUI-Unitframes/groups.lua` (`UF:GroupBorder`, `FitBorder`, `UF:UpdateGroupBorder` and the block comment), `SaftUI-Core/themeart_data.lua` (remove `ART.groupborder`, `GROUP_BORDER`; remove `groupborder` from `CONTROLS` in `themeart.lua`)
- Modify: `tests/wow/atlases.lua` (drop `options_frame_child` if unused)
- Test: `tests/unitframes/blizzard_look_test.lua` (the group border cases)

**Interfaces:**
- Consumes: `ThemeArt.LayBox(pieces, frame, false)` (Task 1), `KINDS.unitframe.reach`.
- Produces: the group border frame is anchored to the header at `-reach, reach, reach, -reach` (whole pixels), its art laid by `ThemeArt.LayBox`; `FitBorder`'s least size is `2 * 6`; its level is `ThemeArt.LevelAbove(header)` set only when `not InCombatLockdown()` (in `UF:UpdateGroupBorder`, out of combat; a draw in combat keeps the last level).

- [ ] **Step 1: Write the failing tests**
  - `party and raid groups wear the box, 4 outside the members`: `T.around(border, header) == '-4,4,4,-4'`, `T.art(border)` lists the box.
  - `the border sits above the members`: members at header level + 1 → border level header + 2.
  - Review Focus 5, `a member joining in combat re-levels nothing`: enter combat (the stub's `InCombatLockdown` true), add a member, run the header's layout → no `SetFrameLevel` call on the border or on any member (spy), no error; after combat ends `UF:UpdateGroupBorder` raises it.
  - The existing sliver case (`showPlayer` off, pending invite) stays green with the new least size.
- [ ] **Step 2: Run** `tests/run tests/unitframes/blizzard_look_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** `tests/run tests/unitframes tests/core`. Expected: PASS.
- [ ] **Step 5: Commit** `unitframes: wrap each party and raid group in the Blizzard box`.

### Task 5: The micro menu: one box per item

**Files:**
- Modify: `SaftUI-Minimap/micromenuart.lua` (`UpdateArt`, `UpdateBackdrop`; remove `UpdateStrip`, `MicroMenu:GetStrip`, `S.UpdateStrip` and the strip locals; header comment), `SaftUI-Minimap/micromenu.lua` (callers of `UpdateStrip`; items' `art` keys go), `SaftUI-Minimap/micromenuitems.lua` (the addon count item gets a box like the rest; search keeps its own magnifier icon shown)
- Modify: `SaftUI-Core/themeart_data.lua` (remove `ART.microbar`; `microbar` from `CONTROLS`), `tests/wow/atlases.lua` (drop the microbar atlases if unused)
- Test: `tests/minimap/blizzard_look_test.lua`, `tests/minimap/micro_coords_test.lua`

**Interfaces:**
- Consumes: `ThemeArt.LayBox(item.boxPieces, item.backdrop, true)` (Task 1): inside the item's rect, with the centre.
- Produces: under Blizzard every micro menu item (zone, clock, latency, FPS, addon count, expansion, mail, difficulty, queue, search, each micro button) has its box laid on `item.backdrop` at the item's own rect (the bar's height, `MicroMenu:BarHeight()`, by the item's width, `S.ItemWidth(item, height)`; see `.agents/architecture.md`, "The bar's settings"), centre shown, no other fill (the item's backdrop is drawn as `control`, which has none); no strip frame exists; Blizzard's micro button art stays above (backdrop level stays button level - 1).

- [ ] **Step 1: Write the failing tests** in `tests/minimap/blizzard_look_test.lua`:
  - `every item stands on the same box`: for each item, `T.around(item.backdrop, button) == '0,0,0,0'` and its box pieces read the same pieces (Forever file 8026705) with a `Center`; every box's height equals `MicroMenu:BarHeight()`, checked at the default 25 and at the setting's ends, 16 and 48 (6px corners whole, edges a positive length).
  - `a turned-off item draws no box`: `show['micro_<name>'] = false` → the item's holder alpha is 0 and its box pieces aren't visible; `show['zone'] = false` the same for a text item.
  - `no fill outside the box`: `item.backdrop`'s backdrop fill alpha is 0 under Blizzard (the spec's band outside the rim).
  - `no strip under the micro buttons`: `MicroMenu.GetStrip` is nil and no texture of `ui-hud-actionbar-frame` is shown.
  - `search keeps its magnifier`: the search item's icon is shown under Blizzard.
  - `retail draws the kit on every item` (retail client).
  - Thick: the micro menu reads as on `modular` (existing Thick cases green).
- [ ] **Step 2: Run** `tests/run tests/minimap`. Expected: FAIL.
- [ ] **Step 3: Implement**.
- [ ] **Step 4: Run** `tests/run tests/minimap tests/core`. Expected: PASS.
- [ ] **Step 5: Commit** `minimap: stand every micro menu item on the same Blizzard box`.

### Task 6: The minimap and the self-drawn panels

**Files:**
- Modify: `SaftUI-Minimap/config.lua` (`UpdateBackdrop`: `st:SetTemplate(backdrop, theme, background, 'panel', nil, Minimap)`, so the box is around the map and above it)
- Test: `tests/minimap/blizzard_look_test.lua`; a sweep case in `tests/core/theme_blizzard_box_test.lua`

**Interfaces:**
- Consumes: Task 1's `over` argument.

- [ ] **Step 1: Write the failing tests**
  - `the minimap's box is 4 outside the map, above it`: `T.around(BoxFrame(backdrop), Minimap) == '-4,4,4,-4'`; box level > `Minimap`'s.
  - `the swing timer, the XP and reputation bars and the tooltip's status bar wear the box outside`: draw each the way its module does (`st:SetBackdropIn(..., 'bar')`, `st:SetBackdrop(..., 'bar')`) → box around the bar at `-4,4,4,-4`. These should already pass after Task 1; they pin the owner's flagged frames.
- [ ] **Step 2: Run** `tests/run tests/minimap/blizzard_look_test.lua tests/core/theme_blizzard_box_test.lua`. Expected: the minimap case FAILS.
- [ ] **Step 3: Implement** the `over` call in `SaftUI-Minimap/config.lua`.
- [ ] **Step 4: Run** the full suite: `tests/run`. Expected: PASS.
- [ ] **Step 5: Commit** `minimap: draw the Blizzard box around the map, over it`.

### Task 7: Docs, followups and in-game checks

**Files:**
- Modify: `docs/design-system/05-decisions.md` (a new numbered decision: one Blizzard box on every panel, bar, tooltip, unit frame, group and micro box; outside and over; desaturated own colour; with the owner's words from the spec's Intent), `docs/design-system/10-discrepancies.md` or `25-colour-roles.md` only where they name the tooltip border, bronze box or microbar art
- Modify: `docs/followups.md` (Resolve: "Blizzard theme: dark grey everywhere" only if it no longer applies, else leave; the round 1 and round 2 check lists' items about `ART.unitframe`, the group border cut, the micro strip and the under-12 line get a dated note that round 3 replaced them; add a followup "Blizzard box: tune the reach and the cut in game" with the spec's builder items; update Contents)
- Modify: `AGENTS.md` / `.agents/*.md` where they name `ART.unitframe`, `ART.groupborder`, `ART.microbar` or the under-12 fallback (run the `agents-doc-parity-check` skill)
- Outside the repo: the Test Rounds artifact gets the spec's seven in-game checks as `checks` docs (list `other`, a new section "Blizzard box", orders from 400); the Design System artifact is republished with the changed `docs/design-system` files (`.scratch/HANDOFF.md`, "Design system").

- [ ] **Step 1: Write the docs and followups changes.**
- [ ] **Step 2: Run** `tests/run` (doc parity and file scans run in the suite). Expected: PASS.
- [ ] **Step 3: Commit** `docs: record the Blizzard theme's one box`.
- [ ] **Step 4: Add the in-game checks to Test Rounds and republish the design system** (controller, not a worker).
