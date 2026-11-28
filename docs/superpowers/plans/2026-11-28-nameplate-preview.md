# Nameplate preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A sample nameplate, drawn from the page's settings with every part showing, in a fixed band at the top of the Enemy and Friendly nameplates pages in `/sui`.

**Architecture:** Core's options window learns a generic `pickerBand` (a pick's group asks for a band under the picker line; the window sizes, places, clips and redraws it). Unitframes supplies the band for the two plate pages from a new `nameplates/preview.lua`: a plain frame built with the real element constructors and updaters, filled with made-up data, with SaftUI-drawn aura icons in place of Blizzard's aura container. Two pure text helpers are lifted out of `tags.lua` and `health.lua` so the preview and real plates format names and health the same way.

**Tech Stack:** Lua 5.1 (WoW addon), Ace3 option tables, bundled oUF; tests on `tests/run` (lupa), WoW API stubs in `tests/wow/`.

**Spec:** `docs/superpowers/specs/2026-11-28-nameplate-preview-design.md`

## Global Constraints

- Plain frames only: no oUF frame, no secure frame, no unit token, no Blizzard aura container, nothing written on a Blizzard frame (`.agents/taint.md`). Works the same in combat.
- Core never references Unitframes. The band is generic.
- Placement goes through the real updaters (`UF:UpdateElement`, `UF:UpdateElementPosition`, `UF:ElementSize`, `UF:UpdateText`, `UF:GetFrame`) and each element's own `UpdateConfig` where it takes a plain frame.
- Real plates' behaviour does not change; every existing test passes unchanged.
- Both clients (Forever and retail).
- Every edge whole pixels (the window's rule, `edit-mode.md`).
- Sample data, exact: Enemy "Thornfang Ravager", hostile NPC (reaction 2), health 72% of 250,000, cast "Shadow Bolt" at 60% interruptible, time "1.2", threat "87%" untinted (normal text colour, bar keeps its reaction colour), subtext "<Pack Leader>" (shown only while the page's NPC box is on), raid mark skull, quest icon shown. Friendly "Aldric", a friendly player of the player's own class, full health, cast "Flash Heal", subtext "<Emerald Wardens>" (only while the page's Player box is on), no threat. Debuffs: up to Max of six; buffs: up to Max of four, Magic.
- Never use `git stash` or `sed -i`; never edit `Libraries/`.

## Review Focus

1. Tab, pick or window-size change while the band is up: the body starts under the band every time, never under it by a stale height, and a toggle on the page does not change the height (settings never move under the cursor). Tests in Task 1.
2. The page's box checked (Use friendly / Use enemy nameplates' settings): the preview draws from the source page's config, and threat still only on the Enemy page. Test in Task 3.
3. Another nameplate addon loaded: no band at all, the body sits where it does today. Test in Task 3.
4. A profile switch replaces the config tables: the preview reads through `GetConfig` at draw time, never a kept table. Test in Task 3.
5. Max debuffs raised past the default (8, 2 rows) or Grow left/down: icons laid out by per row, spacing, growth and initial anchor, and the band still clips. Test in Task 4.

---

### Task 1: The options window's band (Core)

**Files:**
- Modify: `SaftUI-Core/Config/optionsmodel.lua` (`OM.BuildView`, ~line 676; the header comment's view shape, ~line 640)
- Modify: `SaftUI-Core/Config/optionswindow.lua` (`DrawPage` ~902, `Changed` ~524, `ReleaseBody` ~811, frame setup ~1470)
- Modify: `tests/core/options_window_helpers.lua` (a `ufPickerBand` global like `ufPickerControl`, set on the player's unit group)
- Create: `tests/core/options_band_test.lua`
- Modify: `.agents/edit-mode.md` (a bullet after "A pick's control", same style)

**Interfaces:**
- Produces: a pick's group field `pickerBand = { height = function(width) -> number|nil, draw = function(holder, width, height), refresh = function(holder) (optional), release = function(holder) (optional) }`. `OM.BuildView` returns it as `view.picker.band` (a table, else nil). The window calls `height(width)` only when the page, tab, subtab, pick or body width changed since the last band draw (cached as `S.bandKey`/`S.bandHeight`); `nil` or `<= 0` means no band. `draw` runs on every `DrawPage` that shows the band. `refresh` runs in the drag path next to `pageBody:Refresh(widget)`. `release` runs when a draw shows no band (or another band) after one was shown, and on window hide.
- Holder: `F.band`, a frame child of `F.main`, `SetClipsChildren(true)`, placed `TOPLEFT` at `(PAD, -(pickerBottom + BAND_GAP))`, `S.bodyWidth` wide, the whole height tall; `BAND_GAP = 12`. The body is placed at the band's bottom (`PlaceBody(bandBottom)`). Under Thick and Thin a `BACKGROUND` texture over the holder in `OB.PANEL_FILL`; under Blizzard none (`W.BlizzardLook()`).

- [ ] **Step 1: Write the failing tests** in `tests/core/options_band_test.lua`, using the helpers' Unitframes page with `ufPickerBand` set:
  - `band: drawn under the picker line, the body under it` — height returns 120; `F.band` shown, its top 12 under the picker line's bottom, height 120, width `S.bodyWidth`; `F.body`'s top equals the band's bottom.
  - `band: height asked once per page, tab, pick and width` — count `height` calls: one on open; a toggle's set (a render) adds none; a tab change adds one; a pick change adds one; a window size change adds one.
  - `band: draw runs on every render` — count `draw` calls across two renders: 2.
  - `band: a drag refreshes it` — drive a slider drag as `options_rerender_test.lua` does; `refresh` called, `draw` not.
  - `band: none without one, for search, or height 0` — a pick with no `pickerBand`, the search page, and `height` returning 0: `F.band` hidden, the body at the picker line's bottom as today, and `release` called once when leaving a band.
  - `band: clips its children` — `F.band`'s clips flag (the stub's `clips_children`) is true.
  - `model: view.picker.band is the picked group's pickerBand` (in this file or `options_model_test.lua`).
- [ ] **Step 2: Run** `tests/run tests/core/options_band_test.lua` — expect FAIL (no `band`).
- [ ] **Step 3: Implement** `view.picker.band` in `OM.BuildView` and the band in `optionswindow.lua` per Interfaces. Release it from `ReleaseBody`'s callers where a page change or hide happens (not on every render: draw runs on every render).
- [ ] **Step 4: Run** `tests/run tests/core/` — expect PASS, every existing core test too.
- [ ] **Step 5: Document** the band in `.agents/edit-mode.md` after "A pick's control" (what it is, the contract, the caching rule and why: settings never move under the cursor; the clip; the panel look).
- [ ] **Step 6: Commit** `options window: a band a pick can ask for under its picker line`.

### Task 2: Shared name and health text helpers (Unitframes)

Independent of Task 1; may run in parallel.

**Files:**
- Modify: `SaftUI-Unitframes/tags.lua` (`LevelPart`, `NameColor`, the `st:name` method)
- Modify: `SaftUI-Unitframes/elements/health.lua` (`PostUpdateHealth`)
- Create: `tests/unitframes/plate_text_helpers_test.lua`

**Interfaces:**
- Produces:
  - `UF.NameParts(config, info) -> prefix, suffix` — `config` a unit's `name` table; `info = { level, playerLevel, classification, reaction, isPlayer, isPet, class }` with plain values (nil for unknown/secret). Same result as today's `LevelPart` + `NameColor` (with `UnitIsPlayer(unit) or UnitInPartyIsAI(unit)` passed as `isPlayer`, `UnitPlayerControlled(unit) and not UnitIsPlayer(unit)` as `isPet`, the class only when not secret).
  - `UF.FormatName(config, name, prefix, suffix) -> string` — the plain-name branch: allCaps, `UTF8strsub(name, config.maxLength)`, joined.
  - `UF.PlainHealthText(textConfig, current, max, dead, isBoss) -> string` — the plain (non-secret) branches of `PostUpdateHealth` in the same order: hide_full → '', dead → 'Dead', deficit → '-' .. (max - current) (blank when zero, as `TruncateWhenZero` does), percent → '%.0f', else value (short via `UF.ShortNumber`), with ' | %.1f' percent when `boss_percent` and `isBoss`.
- The tag method and `PostUpdateHealth` call these for plain values and keep their secret-value branches exactly as they are.

- [ ] **Step 1: Write the failing tests**: `NameParts` — hostile reaction 2 with `color_hostile` gives the danger colour code; reaction 4 caution; `showLevel` with level 62 vs player 60 gives the level in caution colour + ' '; level -1 gives '??'; `show_classification` elite gives '+'; a player with `colorClass` gives the class colour. `FormatName` — allCaps and maxLength. `PlainHealthText` — {short} 180000/250000 → '180K' (whatever `UF.ShortNumber(180000)` returns; assert equality with it), percent → '72', hide_full at full → '', dead → 'Dead', deficit → '-70000', boss_percent with isBoss → value .. ' | 72.0'.
- [ ] **Step 2: Run** `tests/run tests/unitframes/plate_text_helpers_test.lua` — FAIL.
- [ ] **Step 3: Implement** by moving the logic into the exported functions and calling them from the old sites.
- [ ] **Step 4: Run** `tests/run tests/unitframes/` — PASS, existing name, health and plate tests unchanged.
- [ ] **Step 5: Commit** `unit frames: name and health text helpers the preview shares`.

### Task 3: The preview plate and its band (Unitframes)

Needs Tasks 1 and 2 merged.

**Files:**
- Create: `SaftUI-Unitframes/nameplates/preview.lua` (listed in `nameplates/nameplates.xml` after `options.lua`)
- Modify: `SaftUI-Unitframes/nameplates/options.lua` (`UF.SetUpPlatePage`: `config_table.pickerBand = UF.PlatePreviewBand(unit)`)
- Create: `tests/unitframes/nameplate_preview_test.lua` (on `nameplate_world.lua`)
- Modify: `.agents/architecture.md` (Nameplates section), `AGENTS.md` (the Unitframes row: "the preview at the top of the plate pages")

**Interfaces:**
- Consumes: Task 1's `pickerBand` contract; Task 2's `UF.NameParts`, `UF.FormatName`, `UF.PlainHealthText`.
- Produces:
  - `UF.PlatePreviewBand(page) -> pickerBand table` for `page` 'nameplate' or 'friendlynameplate'. `height` returns nil while `UF:NameplateAddon()` names one.
  - `UF:PlatePreviewFrame(page) -> frame` (lazily built, one per page) and `UF:StylePlatePreview(page)` (re-reads config and data, restyles; what `draw` and `refresh` call).
  - The frame: `base_unit` = `UF.PlateConfigKey(page == 'friendlynameplate')` re-read on every style (the source page while the box is checked), `GetConfig(_, unit)` like `UF.ConstructUnit`'s, `isNamePlate = true`, `friendly`, `TextOverlay`, `elements`, and stub `Tag`/`Untag`/`UpdateTags` (no-ops) so `name.lua`'s and `subtext.lua`'s config code runs. Parts from the registered constructors whose `ValidUnit` takes the page, except `Buffs` and `Debuffs` (Task 4).
  - `UF.PlatePreviewExtent(frame) -> above, below` in pixels from the health bar's top and bottom to the highest and lowest shown part.
- Style order: as `UF:UpdateUnitFrame` (frame size from config, each element's `UpdateConfig`, then the frame's backdrop), then fill sample data per Global Constraints: health bar value and colour (reaction colour for the hostile NPC, class colour for the friendly player where the bar colours by class: the helpers in `grouppreview.lua`), health text from `UF.PlainHealthText`, name from `UF.NameParts`/`UF.FormatName`, castbar value/text/time/icon (Shadow Bolt icon 136197, Flash Heal 135907), threat '87%' in the normal text colour on the Enemy page only (`UF:ElementWanted` with `friendly` set hides it on Friendly), subtext text by the page's `npc`/`player` box, raid mark skull, quest icon's texture as `indicators.lua` sets it. Parts off in config hidden by `UF:ElementWanted`.
- Band: `height(width)` = clamp(above + bar height + below + 2 × 12, 120, 200), whole; `draw` parents the frame to the holder, styles it, places the health bar's centre horizontally in the holder and its top `12 + above` from the holder's top, shows it; `refresh` restyles; `release` hides the frame.

- [ ] **Step 1: Write the failing tests** in `nameplate_preview_test.lua`:
  - `preview: every part on by default shows on the Enemy page` — Health, Name, Castbar (and icon, text), Threat, QuestIndicator, RaidTargetIndicator shown; Subtext hidden (NPC box off by default); name text 'Thornfang Ravager' in the danger colour; health text equals `UF.PlainHealthText(config.health.text, 180000, 250000)`; threat '87%'.
  - `preview: parts placed by the page's config` — change `nameplate.castbar.position.y_off` to -10 and restyle: the castbar's top is 10 under the bar's bottom; the debuff-free parts' anchors resolve through `UF:GetFrame` on the preview.
  - `preview: a part turned off hides` — `nameplate.castbar.enable = false`: castbar hidden after restyle.
  - `preview: Friendly page shows no threat and draws from Friendly config` — Friendly preview's name 'Aldric', no Threat shown.
  - `preview: the box draws from the other page` — `friendlynameplate.use_enemy = true`: the Friendly preview's `base_unit` is 'nameplate' and its castbar follows `nameplate.castbar`.
  - `preview: subtext follows the page's NPC box` — `nameplate.subtext.npc = true`: '<Pack Leader>' shown.
  - `preview: a profile switch` — swap the profile's tables (as `profile_switch_test.lua` does): the restyled preview reads the new width.
  - `band: none while another nameplate addon draws` — loaded Plater stub: `height` returns nil.
  - `band: height from the extent` — default Enemy config: `height(774)` between 120 and 200 and equal to clamp(above + 20 + below + 24).
  - `band: the page has it` — `UF:GetConfigTable().args.nameplate.pickerBand` and the friendly one are tables with `height` and `draw`.
- [ ] **Step 2: Run** `tests/run tests/unitframes/nameplate_preview_test.lua` — FAIL.
- [ ] **Step 3: Implement** `nameplates/preview.lua` per Interfaces, wire `SetUpPlatePage`, add it to `nameplates.xml`.
- [ ] **Step 4: Run** `tests/run tests/unitframes/` — PASS.
- [ ] **Step 5: Document** `preview.lua` in `.agents/architecture.md`'s Nameplates section and the `AGENTS.md` row.
- [ ] **Step 6: Commit** `nameplates: a preview plate at the top of the plate pages`.

### Task 4: The preview's aura areas (Unitframes)

Needs Task 3.

**Files:**
- Modify: `SaftUI-Unitframes/elements/auras.lua` (export `UF.AuraButtonSize(unitframe, config)` = today's `getButtonSize`; `UF.AuraAreaSize(unitframe, config) -> width, height` from `UpdateConfig`'s sums; `UF.StyleAuraButton(auras, button)` = `StyleButton`, if it styles a plain button with `Icon`, `Count`, `Cooldown` without container calls; otherwise export only the pieces that do)
- Modify: `SaftUI-Unitframes/nameplates/preview.lua`
- Modify: `tests/unitframes/nameplate_preview_test.lua`

**Interfaces:**
- Consumes: Task 3's preview frame and `UF:StylePlatePreview(page)`.
- Produces: on the preview frame, `Debuffs` and `Buffs` as plain frames (fields `config`, `GetConfig`, `name`, `unitframe`), placed through `UF:UpdateElement` (bare: no backdrop), sized by `UF.AuraAreaSize`, hidden by `UF:ElementWanted`; each holds `min(config.max, 6 or 4)` icon buttons (frames with `Icon`, `Count`, `Cooldown` like Blizzard's aura buttons), styled through `UF.StyleAuraButton`, laid out by `initial_anchor`, `per_row`, `spacing`, `grow_right`, `grow_up`. Debuff icons 136207, 136118, 136139, 136096, 132155, 132204 with stacks (none, 3, none, 2, none, 5), one of each dispel type colour where the area colours by type; buff icons 135987, 135932, 136078, 135953 with the stealable border where the area colours stealable; cooldown swipe set part way and not ticking; timer text only when the area's timer is on.

- [ ] **Step 1: Write the failing tests**:
  - `auras: default debuffs` — 6 icons, 20 square, the row 150 wide (6 × 20 + 5 × 6), its bottom-left 6 above the bar's top-left.
  - `auras: default buffs` — 4 icons, 6 right of the bar, level with its top.
  - `auras: max 8, per row 4, grow left and down` — 8 icons, two rows, each step right-to-left and top-to-bottom by size + spacing.
  - `auras: off hides the area` — `nameplate.debuffs.enable = false`.
  - `auras: band height grows with a second row` — `height` after a page change measures the taller extent (capped at 200).
- [ ] **Step 2: Run** — FAIL.
- [ ] **Step 3: Implement** the exports in `auras.lua` (real plates unchanged) and the areas in `preview.lua`.
- [ ] **Step 4: Run** `tests/run` (whole suite once, the plan's end) — PASS.
- [ ] **Step 5: Commit** `nameplates: the preview's debuffs and buffs`.
