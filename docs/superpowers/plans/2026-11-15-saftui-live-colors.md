# SaftUI Live Colors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every Colors page color and the Accent reaches every SaftUI reader on screen as the picker is dragged, with no reload and no lag a drag can feel, and the picker shows a preview of what the color being edited colors.

**Architecture:**
- **One notification per color.** The Colors rows and the Accent row call `st:ColorChanged(group, key)` (`SaftUI-Core/Media/colors.lua`). During an edit (the picker open) it marks the color and one pass runs on the next frame; outside one it passes at once. A pass runs the color's followers (`st:FollowColor`), then every module's `OnColorsChanged(group, key)`. `st:ColorsChanged(group)` stays as the whole pass (key nil), which an edit's end runs for each group it touched, and the profile update runs for every group.
- **Readers repaint only color.** Each module's handler filters by key and only sets colors; what has no module registers as a follower. Nothing is made, moved, laid out or allocated in a pass, and no hot path changes.
- **The preview** is a strip under the picker's square (placement A), drawn by a kind the option names in its `preview` field (`text`, `button`, `bar`, `border`, `accent`), from real SaftUI pieces drawn by the theme engine (`SaftUI-Core/Config/optionspreview.lua`).

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0; the bundled oUF (unit frames) and LibActionButton-1.0 (action bars), neither changed; SaftUI's options kit (`st.OptionsModel`, `st.OptionsWidgets`, `st.OptionsBody`, `st.OptionsWindow`) and color picker; tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-15-saftui-live-colors-design.md`. Its calls are taken as accepted. Question 1 (placement A or B) doesn't block: this plan builds A, and Ruling 18 says what B changes. Question 2 doesn't block: this plan builds "`/sui` redraws at close".

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder changes. oUF's `ColorPath` stays local: the unit frames recolor through an element's `ForceUpdate`.
- **Privacy.** No account, realm or character name anywhere: code, tests, docs, commits.
- **Commits.** Lowercase `module: imperative summary`. Stage by explicit path, never `git add -A`, `.` or a folder. End with the session's `Co-Authored-By` line.
- **Line endings.** Some working-tree files are CRLF. Never `sed -i`. Edit with the editor and keep each file's endings (`file <path>`).
- **Words.** Sentence case for every name, label and desc, in American spelling ("color"). Name a path with ">": "Global settings > Colors".
- **Resets.** Per setting (the option's `default` field), never a section's or a page's Reset button.
- **Icons.** Lucide's (`st.icons`), drawn at twice the glyph. An icon-only control always has a tooltip.
- **Scripts.** Kit controls take `control.onClick`, never `SetScript('OnClick')`. The game calls `OnEnter` and `OnLeave` with a second argument, `motion`: wrap each as `function(self) ... end`, and fire hover scripts in tests with `true`.
- **Whole pixels.** Every size and offset through `st:RoundToPixel`; a size read back is rounded, never ceiled (a text's width may be `ceil`). Every new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard with `stub.size_noise` at `2 ^ -14`, `-2 ^ -14` and `0`.
- **Colors through the accessor.** Every Text, Buttons, Roles, Factions, Loot and Accent read is `st:Color` or `st:ColorRGBA` (a Buttons read is `st:ColorRGBA('button', key, strength)`); the game-concept groups (class, reaction, power, item quality, status, threat, objectives) keep their own reads. `tests/core/color_reads_test.lua`'s rules A to F hold after every task.
- **Blizzard and secure frames.** Nothing on a secure or Blizzard frame beyond the color of a region that exists: no field written onto it, no method called but a color setter on its region (`.agents/taint.md` rules 1 to 3).
- **A pass only colors** (the spec's "What a pass may call"): color setters, `SetText` on SaftUI's own font strings, a font object's `SetTextColor`, an oUF element's `ForceUpdate` and `UpdateTags`. No frame, texture or font string made; no `Show`, `Hide`, `SetShown`, `SetParent`, `SetPoint`, `ClearAllPoints`, `SetSize`, `SetWidth`, `SetHeight`, `SetAttribute` or `SetScript` on any frame; no `UpdateConfig`, layout, sort or rebuild; no table or closure. `tests/lib/color_cost.lua` checks it.
- **Hot paths.** No change to an element's update, a plate's add, an action button's update or a bag update.
- **No `SetFont`** on a text SaftUI keeps (`tests/core/setfont_scan_test.lua`).
- **Both clients.** Every task's tests run on `T.client('forever')` and `'retail'` where they touch a reader that differs.
- **Tests.** Each task ends green on `tests/run -j2`, and runs single files while working. An earlier assertion changes only where this work changes what it pins, and the report lists each one changed.
- **Docs.** Each task updates the docs its files make stale, in the same commit: `AGENTS.md`, the `.agents/*.md` whose `covers:` list its files, and `docs/design-system/`. Then it runs `agents-doc-parity-check` and `readme-freshness-check`. A task that changes `docs/design-system/` says so in its report: the controller republishes the Design System artifact.
- **In game.** Each task ends with its in-game checks for the owner. Nothing counts as verified until he confirms it.

## Review Focus

1. **A profile switch while the picker is open** (a profile macro, or Copy from on another page). The picker closes as a Cancel writing nothing into the new profile (its `stale` check), the edit ends, and every touched group's whole pass runs on the new profile's colors, so no reader keeps the old profile's or the dragged color. Test: Task 1 `'a profile switch during an edit'`.
2. **A secret class, standing or power type** on a frame during a per-key pass (retail, an instance's plates). The frame counts as a match and is updated; nothing compares the secret; no error. Test: Task 3 `'a secret class, standing or power type counts as a match'`.
3. **A follower whose paint errors** (a region of a frame another addon took apart). It is reported once and forgotten; every other follower still paints; the next pass reports nothing. Test: Task 1 `'a follower whose paint errors'`.
4. **Combat starting with the picker open.** Cancel's restore and the whole passes run in combat: color only, no forbidden call, nothing protected, on the action bars' secure buttons and the unit frames too. Tests: Task 1 `'combat cancels an open picker'`, and each heavy reader's `'in combat'` case (Tasks 3, 4, 5).
5. **Opening the picker on a second color while one is open.** The first is accepted as Okay: its edit ends with its whole passes before the second edit begins, and no pass of the first runs inside the second. Test: Task 1 `'opening for another field ends the first edit first'`.

---

## How the tasks are cut

| # | Task | Spec part | Needs | Runs beside | Owner can try in game |
| --- | --- | --- | --- | --- | --- |
| 1 | The pass: notification, edits, followers, whole passes, guard, debug line | A: mechanism | — | — | the picker's own captions and chips follow; the field font; the debug line |
| 2 | Core's widgets, skinning, close buttons, edit mode | A: readers | 1 | 3, 4, 5, 6, 7 | Buttons colors on SaftUI buttons, check boxes, thumbs; slot hover; the grid |
| 3 | Unit frames and nameplates | A: readers | 1 | 2, 4, 5, 6, 7 | class, standing, power, roles and level tags by key, cheaply |
| 4 | Bags | A: readers | 1 | 2, 3, 5, 6, 7 | quality by key; item levels, footers, titles, the bank |
| 5 | Action bars, totem bar, minimap | A: readers | 1 | 2, 3, 4, 6, 7 | the flash, equipped border, totems, micro buttons |
| 6 | Loot | A: readers | 1 | 2, 3, 4, 5, 7 | roll letters and counts, the feed's names, mounts and bars |
| 7 | Misc's skins, the tooltip, SaftUI's tracker | A: readers | 1 | 2, 3, 4, 5, 6 | the shown unit tooltip, the character frame, RestedXP |
| 8 | The Colors page's notes and the docs | A: notes | 2 to 7 | — | no reload notes; the tab's line |
| 9 | The preview area, its field and the `text` kind | B | 1, 8 | — | the preview on Text, Factions, Loot letters, Objectives |
| 10 | The `button` and `accent` kinds | B | 9 | — | the preview on Buttons and the Accent |
| 11 | The `bar` and `border` kinds | B | 10 | — | the preview on every other row |

Tasks 2 to 7 share no source file and can run side by side, each in its own worktree. They do share three things, merged by hand, keeping both sides: `.agents/architecture.md` (each edits only its own module's sentences), `tests/wow/*.lua` (a stub one task appends; see `.agents/workflow.md` on `game.lua`'s closing `end`), and `tests/lib/color_cost.lua`, which Task 1 makes and none of them changes. Task 9 needs Task 8 only because both edit `SaftUI-Core/Media/colors.lua`; it may run beside Tasks 2 to 8 if that file is merged by hand. Tasks 9, 10 and 11 edit the same two files and run in order.

## Files shared with work in flight

Open branches touch `SaftUI-Core/Config/options*.lua`, `SaftUI-Core/Media/fonts.lua`, `SaftUI-Core/Widgets/button.lua` and `checkbutton.lua`, `SaftUI-Bags/`, `SaftUI-ActionBars/`, `SaftUI-Misc/totem*.lua` and `SaftUI-Loot/popup.lua`. Two designs are being written beside this one: UI scaling, and a reset on every setting (which touches every options row, the Colors rows included).

| Task | Shared with open branches | Shared with the two designs |
| --- | --- | --- |
| 1 | `SaftUI-Core/Config/optionscolorpicker.lua` | `SaftUI-Core/Media/colors.lua` (the rows' `set` and `default`, the reset design's ground) |
| 2 | `SaftUI-Core/Widgets/button.lua`, `checkbutton.lua`, `SaftUI-Core/Config/optionsresize.lua` | `optionsresize.lua` and `panels.lua` (UI scaling may size them) |
| 3 | — | — |
| 4 | `SaftUI-Bags/slot.lua`, `header.lua`, `container.lua`, `containers/*.lua`, `currencies.lua`, `inventory.lua`, `views.lua` | — |
| 5 | `SaftUI-ActionBars/skin.lua`, `SaftUI-Misc/totemskin.lua`, `totemtimers.lua` | — |
| 6 | none (`SaftUI-Loot/popup.lua` is not edited: its slot's hover follows through Task 2's `st:SkinActionButton`) | — |
| 7 | — | — |
| 8 | — | `SaftUI-Core/Media/colors.lua` |
| 9 | `optionscolorpicker.lua`, `optionstypes.lua`, `SaftUI-Core/Config/load.xml` | `Media/colors.lua`; `tests/lib/options_walk.lua` (the reset design adds fields there too) |
| 10, 11 | — | `Media/colors.lua` |

`SaftUI-Core/Media/fonts.lua` is not edited by this plan.

## Rulings on the spec

1. **Names** (the spec leaves them to the builder): `st:ColorChanged(group, key)`, `st:ColorsChanged(group)` (kept), `st:FollowColor(object, group, key, paint)`, `st:UnfollowColor(object)`, `st:BeginColorEdit()`, `st:EndColorEdit()`, `st:InColorEdit()`, `st.COLOR_GROUPS`, and in `Media/colors.lua`'s module `CO`: `CO.ticker`, `CO.PASS_BUDGET_MS = 8`, `CO.MAX_WAIT = 3`, `CO.EditStats()`, `CO.Timed(group, key, fn, ...)`.
2. **`paint(object, key)`**: key is the changed key, nil on a whole pass. A paint reads its own colors (and its object's state, a thumb's hover) as it runs.
3. **No allocation per pass.** The followers are `followers[group][key or '*']`, weak-keyed tables made once per group and key at first registration. The marks are two arrays (`markGroup[i]`, `markKey[i]`) and a set per group made at load; the touched groups an array and a set. All are cleared in place. `CO.EditStats()` returns one table, reset at `st:BeginColorEdit()`.
4. **The ticker** is a plain `CreateFrame('Frame')`, hidden. A mark during an edit shows it; its `OnUpdate` waits while `CO.wait > 0` (counting it down), else hides itself and runs the due pass. `st:EndColorEdit()` hides it and drops what is marked.
5. **The guard.** After a pass during an edit: `CO.wait = math.min(CO.MAX_WAIT, math.floor(cost / CO.PASS_BUDGET_MS))`, cost from `debugprofilestop()`, added to the stats' `waited`.
6. **The debug line**, at `st:EndColorEdit()` when `st.DEBUG` and the edit ran a pass: `st:Debug('Colors', ('%d passes, slowest %.1f ms (%s), mean %.1f ms, %d frames waited.'):format(passes, slowest, name, total / passes, waited))`, `name` being `group .. ' ' .. tostring(key)`, or `group` alone when key is nil, built only here.
7. **The Theme tab's recolor is timed**, not changed: `Media/theme.lua`'s local `Recolor()` runs `st:RecolorThemed()` through `CO.Timed('theme', nil, fn)`, which only adds the time to the edit's stats while `st:InColorEdit()`.
8. **A follower whose paint errors** (`xpcall` returns false) is set to nil in place, which Lua 5.1 allows while its table is walked; the handler has reported it.
9. **A follow made during a pass** goes into a pending list and is applied when the pass ends (an allocation only then).
10. **The picker.** `W.OpenColorPicker` calls `st:BeginColorEdit()` once its new `spec` is set (after the Okay that accepts an open one). Okay calls `st:EndColorEdit()` after `frame:Hide()`; Cancel after `onCancel`. `st:EndColorEdit()` does nothing outside an edit, so the OnHide that runs Cancel again is harmless.
11. **`Config:OnColorsChanged(group, key)`**: `'theme'` as today; `'text'` with key nil or `'normal'` runs `st.OptionsBody.UpdateFonts()` when the body is loaded.
12. **The profile update.** A local `AllColorsChanged()` in `SaftUI-Core/Config/config.lua` runs `Safely(function() st:ColorsChanged(group) end)` for each group of `st.COLOR_GROUPS` but `'accent'`, in order. It is called right after `ColorsChanged('accent')` in `RedrawTheme` (`config.lua:254`) and in the out-of-combat branch (`config.lua:342`).
13. **The unit frames by key** (Task 3): `UF.ColorReaches(frame, group, key) -> boolean`, true when key is nil or the frame's unit is reached:
    - `class`: a player (or a party AI) whose `UnitClass` token is key;
    - `reaction`: a unit not controlled by a player whose `UnitReaction(unit, 'player')` is key;
    - `power`: a unit whose `UnitPowerType` token is key;
    - `status`: `disconnected`, a unit not `UnitIsConnected`; `tapped`, one `UnitIsTapDenied`;
    - `roles`: `UnitGroupRolesAssigned` is key (`'DAMAGER'` also for `'NONE'`);
    - `text`: every frame.
    A secret answer at any step counts as reached. The elements a group updates are `UF.COLOR_ELEMENTS = { class = { 'Health', 'Power' }, reaction = { 'Health', 'Power' }, power = { 'Power', 'AdditionalPower', 'ClassPower' }, status = { 'Health' }, roles = { 'GroupRoleIndicator' } }`; AdditionalPower only for `'MANA'`, ClassPower only on the player's frame. Tags update for `UF.COLOR_TAGS = { class = true, reaction = true, text = true }`, previews for `UF.PREVIEW_GROUPS = { class = true, reaction = true, power = true, roles = true, text = true }`. `UF:UpdateColors(group, key)` copies only that key into oUF's table (its object's `SetRGB`), or every group as today when both are nil.
14. **The bags' item level key** (Task 4): `INV.ItemLevelKey(info) -> 'shared' | 'success' | 'strong'`, the rule `slot.lua:138-144` applies today (Warbound, Bind on Equip, else).
15. **The loot feed** (Task 6): an item entry keeps `plain` (its name) and `quality`, and its text is `LT.FeedItemName(info)` at each draw; a progress entry keeps `colorGroup` (`'reaction'` or `'renown'`) and `colorKey`, and reads its color as it draws, so a profile switch reaches it too.
16. **Edit mode** fires `ColorsChanged` with `(group, key)`.
17. **The preview's numbers** (placement A, Task 9): `W.PREVIEW = { CAPTION_Y = 248, Y = 266, HEIGHT = 64, ROOM = 94, GAP = 8, TILE_HEIGHT = 44, CAPTION_GAP = 6 }`. With a preview the picker is 482 tall; Class colors' caption and chips at 342 and 360, Last used's at 388 and 406, the buttons 16 from the bottom as today.
18. **If the owner picks B** (Question 1): `W.PREVIEW` takes B's numbers (the area at the number column's right plus 16, 176 by 172 from 66, its caption at 48, `ROOM = 0`, the panel 192 wider), and each kind's `Build` lays its tiles in rows when the area is taller than wide. Nothing else changes.
19. **Held button states** (Task 10): `LockHighlight()` and `SetButtonState('PUSHED', true)`. Where the stubs lack one, Task 10 adds it faithfully (`tests/wow/widgets.lua`) with a `tests/lib/harness_self_test.lua` case.
20. **The preview's file** `SaftUI-Core/Config/optionspreview.lua` loads right after `optionscolorpicker.lua` (before `optionsfont.lua`) in `load.xml` and `tests/lib/shell.lua`'s list. It records its built-in kinds at its end, as `optionsposition.lua` records the built-in types.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Media/colors.lua` | the notification, edits, followers, the whole pass, the guard, stats; the rows' calls; later the notes and the rows' previews | 1, 8, 9, 10, 11 |
| `SaftUI-Core/Media/theme.lua` | the Theme tab's recolor timed | 1 |
| `SaftUI-Core/Config/optionscolorpicker.lua` | edits begun and ended; its own captions and chips follow; later the preview area | 1, 9 |
| `SaftUI-Core/Config/config.lua` | the profile update's whole passes; `Config:OnColorsChanged` | 1 |
| `tests/lib/color_cost.lua` (new) | counting a pass's calls, makes, garbage and time | 1 |
| `SaftUI-Core/Widgets/button.lua`, `checkbutton.lua`, `scrollbar.lua`, `radiogroup.lua`, `skinning.lua`, `panels.lua`, `Config/optionsresize.lua`, `EditMode/grid.lua`, `EditMode/mover.lua`, `EditMode/Bar/bar.lua` | Core's readers | 2 |
| `SaftUI-Unitframes/unitframes.lua`, `elements/indicators.lua`, `grouppreview.lua`, `nameplates/threat.lua` | the unit frames by key | 3 |
| `SaftUI-Bags/slot.lua`, `header.lua`, `container.lua`, `containers/bag.lua`, `bank.lua`, `combinedbank.lua`, `currencies.lua`, `inventory.lua`, `views.lua` | the bags by key | 4 |
| `SaftUI-ActionBars/skin.lua`; `SaftUI-Misc/totemskin.lua`, `totemtimers.lua`; `SaftUI-Minimap/micromenu.lua`, `microbuttons.lua`, `micromenuitems.lua`, `queuebutton.lua`, `expansionbutton.lua`, `instancedifficulty.lua` | flashes, hovers, totems, micro buttons | 5 |
| `SaftUI-Loot/init.lua`, `roll.lua`, `rollinfo.lua`, `rollbar.lua`, `Feed/feed.lua`, `Feed/progress.lua` | Loot | 6 |
| `SaftUI-Misc/tooltip.lua`, `Skinning/skinning.lua`, `Skinning/blizzard/characterframe/characterframe.lua`, `Skinning/addons/restedxp.lua`, `Skinning/blizzard/Blizzard_ColorPicker.lua`, `Skinning/blizzard/Blizzard_ObjectiveTracker.lua`; `SaftUI-Tracker/init.lua` | Misc and the tracker | 7 |
| `SaftUI-Core/Config/optionspreview.lua` (new), `optionstypes.lua`, `load.xml`; `tests/lib/shell.lua`, `tests/lib/options_walk.lua` | the preview, its field and kinds | 9, 10, 11 |

---

### Task 1: The pass

**Files:**
- Modify:
  - `SaftUI-Core/Media/colors.lua`: everything in the Interfaces below; `st:ColorsChanged(group)` runs the group's followers before the modules and passes no key; the rows' `set` and `ColorDefault`'s `reset`, and `CO:AccentOption`'s set and reset, call `st:ColorChanged(color.group, color.key)` (`'accent'`, nil) in place of `st:ColorsChanged`.
  - `SaftUI-Core/Media/theme.lua`: the local `Recolor()` through `CO.Timed` (Ruling 7).
  - `SaftUI-Core/Config/optionscolorpicker.lua`: Ruling 10; in `Build`, `st:FollowColor(frame, 'text', nil, PaintText)` (the captions, box labels and chevron, the color part of `Look()`, which `Look()` then calls) and `st:FollowColor(frame, 'class', nil, PaintClassChips)` (each shown chip in its class's color, the colors part of `FillClassChips`).
  - `SaftUI-Core/Config/config.lua`: Rulings 11 and 12.
- Create: `tests/lib/color_cost.lua`, `tests/core/color_live_test.lua`.
- Test, modify: `tests/core/colors_test.lua` and `tests/core/accent_test.lua` (where they spy `st:ColorsChanged` on a set or reset, they now see `st:ColorChanged`); `tests/core/options_color_picker_test.lua` (two cases below).
- Docs:
  - `.agents/architecture.md`: the `OnColorsChanged` bullet (line 57) becomes the mechanism: `st:ColorChanged`, edits, the pass and the whole pass, followers and their rules, `OnColorsChanged(group, key)`, what a pass may call, the guard, the debug line; "Nearly everything else reads it when it draws" waits for Task 8. The profile update's step 8 gains the whole passes.
  - `.agents/edit-mode.md`: the picker paragraph: it begins and ends an edit; its captions and chips follow.
  - `.agents/testing.md`: `tests/lib/color_cost.lua` in the lib table; `color_live_test.lua` in the `tests/core/` row.

**Interfaces:**
- Produces:

```lua
st.COLOR_GROUPS = { 'text', 'button', 'class', 'roles', 'reaction', 'renown', 'factions', 'power',
	'item_quality', 'loot', 'status', 'threat', 'objectives', 'accent' }
st:ColorChanged(group, key)            -- key nil for 'accent' and 'renown'
st:ColorsChanged(group)                -- the whole pass: followers of group, then OnColorsChanged(group) (no key)
st:FollowColor(object, group, key, paint)  -- paint(object, key); key nil: every key; paint nil forgets that one
st:UnfollowColor(object)               -- forgets every registration of object
st:BeginColorEdit()
st:EndColorEdit()                      -- whole pass per touched group, in order first touched; then the debug line
st:InColorEdit() -> boolean
CO.ticker                              -- a frame; tests fire its OnUpdate
CO.PASS_BUDGET_MS, CO.MAX_WAIT         -- 8, 3
CO.EditStats() -> { passes, total, slowest, slowestGroup, slowestKey, waited }
CO.Timed(group, key, fn, ...)          -- runs fn(...), adding its time to the edit's stats while one is on
-- every module: OnColorsChanged(group, key)   key nil: every color of the group
```

```lua
-- tests/lib/color_cost.lua: local C = load_test_file('lib/color_cost.lua') (no globals)
C.FORBIDDEN = { 'Show', 'Hide', 'SetShown', 'SetParent', 'SetPoint', 'ClearAllPoints', 'SetSize',
	'SetWidth', 'SetHeight', 'SetAttribute', 'SetScript' }      -- on frames; a texture may Show or Hide
C.MAKERS = { 'CreateFrame', 'CreateTexture', 'CreateFontString' }
C.SETTERS = { 'SetVertexColor', 'SetTextColor', 'SetColorTexture', 'SetStatusBarColor', 'SetGradient',
	'SetBackdropColor', 'SetBackdropBorderColor', 'SetText', 'SetFormattedText' }
C.measure(fn, runs) -> { calls = { total, by = { [method] = n } }, forbidden = { total, by }, made = n,
	kb = <garbage over all runs, KB>, ms = <slowest run, stub ms> }
C.step(st)                             -- one frame: fires CO.ticker's OnUpdate while it is shown
C.edit(st, fn)                         -- st:BeginColorEdit(); fn(); st:EndColorEdit()
C.print(label, m)                      -- '  <label>: <ms> ms, <calls> calls' (shown under -v)
```

  `C.measure` counts every method of `C.SETTERS`, `C.FORBIDDEN` and `C.MAKERS` on the stub widget types' method tables (Frame, Button, CheckButton, StatusBar, EditBox, ScrollFrame, Texture, FontString), and the global `CreateFrame`, as `tests/tracker/rows_world.lua`'s `RW.calls` does, and puts them back after.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/color_live_test.lua (load_test_file('core/config_helpers.lua'); C = load_test_file('lib/color_cost.lua'))
-- M: a stand-in module (st:NewModule('LiveProbe')) whose OnColorsChanged records group .. ':' .. tostring(key)
test("outside an edit a change passes at once: the color's followers, the group's, then each module", function()
	-- st:FollowColor(a, 'text', 'danger', P); st:FollowColor(b, 'text', nil, P); st:FollowColor(c, 'text', 'muted', P)
	-- st:ColorChanged('text', 'danger') -> painted a then b, with key 'danger'; not c; M saw { 'text:danger' }
end)
test('during an edit changes wait for the next frame, and one pass runs however many came', function()
	-- st:BeginColorEdit(); 50 x ColorChanged('class', 'MAGE'), 50 x ('text', 'danger') -> nothing painted; CO.ticker:IsShown()
	-- C.step(st) -> each follower once per color; M saw { 'class:MAGE', 'text:danger' }; ticker hidden; C.step again -> nothing
end)
test("an edit's end runs the whole pass of each group it touched, in the order first touched, dropping a pass still due", function()
	-- Begin; ('text','danger'); C.step; ('class','MAGE'); ('text','muted'); st:EndColorEdit()
	-- M saw { 'text:danger', 'text:nil', 'class:nil' }; st:InColorEdit() false; ticker hidden
end)
test('st:ColorsChanged(group) is the whole pass: every follower of the group with key nil, then each module with no key', ...)
test("the Colors rows and the Accent row say ColorChanged, on a set and on a reset", function()
	-- CO:GetConfigTable(): text.danger set and default.reset -> ('text', 'danger'); reaction's renown -> ('renown', nil)
	-- CO:AccentOption(5) set and default.reset -> ('accent', nil); none calls st:ColorsChanged
end)
test('the picker begins an edit as it opens and ends it as it closes, after Cancel puts the color back', function()
	-- H.open on a Colors row's field; drag; C.step -> a pass; Cancel -> M's last two: 'text:danger' (the restore, marked) is dropped,
	-- then 'text:nil' after onCancel; the profile's text.danger is the opening color
end)
test('opening for another field ends the first edit first (Review Focus 5)', function()
	-- open on Text > Danger, change; open on Class > Mage -> 'text:nil' ran, then the new edit began with no touched group
end)
test('a profile switch during an edit (Review Focus 1)', function()
	-- open on Text > Danger, pick red; st.config:SetProfile('B') -> picker closed; B's text.danger untouched;
	-- the whole pass ran with B in place (a follower read B's danger); st:InColorEdit() false
end)
test('a follower whose paint errors is reported once and forgotten; the rest still paint (Review Focus 3)', function()
	-- three followers on ('text','danger'), the middle one errors -> #take_errors() == 1, the others painted
	-- the next pass: no error, the other two painted again
end)
test('a follow made during a pass takes effect after it; UnfollowColor forgets every registration', ...)
test('the guard: a pass over 8 ms makes the next wait a frame per 8 ms, three at most', function()
	-- debugprofilestop stood in by a clock a paint moves 20 ms -> the next pass waits 2 steps; 40 ms -> 3
	-- CO.EditStats(): passes, slowest 20 or 40, slowestGroup 'text', waited 2 (then 3)
end)
test("the Theme tab's recolor is timed during an edit, as theme, and changes nothing outside one", ...)
test('with /sui debug on an edit ends with one line; with no pass, none', function()
	-- st.DEBUG = true; 3 passes -> one print matching '<DEBUG:Colors> 3 passes, slowest [%d.]+ ms %(class MAGE%), mean [%d.]+ ms, 0 frames waited%.'
end)
test('a pass makes nothing and allocates nothing: 1000 followers, 100 passes', function()
	-- m = C.measure(function() st:ColorChanged('text', 'danger') end, 100): m.made == 0, m.forbidden.total == 0, m.kb < 4
end)
test("the profile update runs every group's whole pass after theme and accent, and in combat once it ends", function()
	-- st.Config:UpdateConfig() -> M saw 'theme:nil', 'accent:nil', then each of st.COLOR_GROUPS but accent, key nil, in order
	-- stub.in_combat = true: nothing until stub.fire_event('PLAYER_REGEN_ENABLED'), then the same
end)
test('combat cancels an open picker: the restore and the whole pass run, color only (Review Focus 4)', function()
	-- open, drag; stub.in_combat = true; stub.fire_event('PLAYER_REGEN_DISABLED') inside C.measure -> forbidden 0, made 0;
	-- the color is the opening one
end)
test("Config:OnColorsChanged('text', 'normal') gives the kit's font objects Text's color; ('text', 'danger') does not", ...)
-- tests/core/options_color_picker_test.lua
test("its captions, box labels and chevron follow Text > Muted and Normal while it is open", ...)
test("a class chip follows its class's color while it is open", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/color_live_test.lua tests/core/options_color_picker_test.lua`. Expected: FAIL, `st.ColorChanged` is nil.
- [ ] **Step 3: Implement** as the Interfaces and Rulings 1 to 12 say. Update the set/reset spies in `colors_test.lua` and `accent_test.lua`.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS. Every module's handler still works unchanged: it is called with a key it ignores.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Media/colors.lua SaftUI-Core/Media/theme.lua SaftUI-Core/Config/optionscolorpicker.lua SaftUI-Core/Config/config.lua tests/lib/color_cost.lua tests/core/color_live_test.lua tests/core/colors_test.lua tests/core/accent_test.lua tests/core/options_color_picker_test.lua .agents/architecture.md .agents/edit-mode.md .agents/testing.md
git commit -m "core: pass a color change once per frame to what it colors, and time it"
```

**In-game checks:**
- Both clients: log in with no Lua errors; the Colors page works as before.
- Drag Text > Muted: the picker's own captions and labels follow; a field's text in `/sui` follows Text > Normal.
- Drag Class > Mage: the Mage chip in the picker follows.
- `/sui debug` on: drag a color a few seconds, press Okay: one `<DEBUG:Colors>` line. Note its numbers (unit frames still use today's whole-roster handler: Task 3 cuts it). Drag a Theme tab color: the line names `theme`.
- Cancel after a drag: the color is back everywhere it went.

---

### Task 2: Core's widgets, skinning, close buttons and edit mode

**Files:**
- Modify:
  - `SaftUI-Core/Widgets/button.lua`: `st:SkinButton`'s highlight and pushed textures follow (`'button'`, `'normal'` and `'pushed'`), where it draws SaftUI's flat look.
  - `SaftUI-Core/Widgets/checkbutton.lua`: `Flat`'s textures follow their key; the skinned check box's checked and hover textures follow `'hover'` and `'normal'`.
  - `SaftUI-Core/Widgets/scrollbar.lua`: `st:FollowColor(thumb, 'button', nil, ColorThumb)`.
  - `SaftUI-Core/Widgets/radiogroup.lua`: the picked button follows the Accent (`'accent'`; a paint that colors it only while it is picked).
  - `SaftUI-Core/skinning.lua`: `st:SkinActionButton`'s hover follows the Accent; the resize corners' pushed and highlight textures follow `'hover'`.
  - `SaftUI-Core/panels.lua`: a close button's look becomes a file-level `LookClose(close)` that reads the button's own hover and Blizzard state (fields on SaftUI's own frame), and the button follows `'text'`.
  - `SaftUI-Core/Config/optionsresize.lua`: the grip follows `'hover'`.
  - `SaftUI-Core/EditMode/mover.lua`: `EM:Fire('ColorsChanged', group, key)`.
  - `SaftUI-Core/EditMode/Bar/bar.lua`: `EM:RefreshBar()` on `ColorsChanged` only for `'text'`, `'button'`, `'accent'` and `'theme'`.
  - `SaftUI-Core/EditMode/grid.lua`: on `ColorsChanged` with `'accent'`, the two centre lines take it (`SetColorTexture` at `CENTER_ALPHA`), nothing redrawn.
- Create: `tests/core/live_widgets_test.lua`.
- Test, modify: `tests/core/button_opacity_test.lua` (its cases stay; one more below), `tests/core/editmode_grid_test.lua`.
- Docs: `.agents/architecture.md` (the Buttons opacity sentence: these readers follow at once; `st:KeepOwnColors`' list unchanged), `.agents/edit-mode.md` (the grid's centre lines, the bar's refresh groups).

**Interfaces:**
- Consumes: Task 1's `st:FollowColor`, `st:ColorChanged`, `C.measure`, `C.edit`, `C.step`.
- Produces: `EM`'s `ColorsChanged` event carries `(group, key)`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/live_widgets_test.lua (load_core_helpers(); C = load_test_file('lib/color_cost.lua'))
-- each case: draw the widget, then C.edit(st, function() set the color; C.step(st) end), and read it back
test("a SaftUI button's highlight and pressed fill follow Buttons > Normal and Pushed at their opacity", function()
	-- Normal to 0.2, 0.4, 0.6, a 0.5 -> hover's vertex color 0.2, 0.4, 0.6, 0.5; Pushed likewise; Hover changes neither
end)
test("a check box's checked fill and highlight follow Hover and Normal", ...)
test('a scroll bar thumb follows the key of its state: Normal at rest, Hover under the mouse, Pushed held', ...)
test("the resize corners and /sui's grip follow Hover", ...)
test("st:SkinActionButton's hover follows the Accent", ...)
test("a radio group's picked button follows the Accent; the others keep the theme's border", ...)
test("a close button's cross follows Muted at rest and Danger under the mouse", ...)
test("the grid's centre lines follow the Accent, nothing redrawn; the bar looks again only for text, button, accent and theme", function()
	-- EM:RefreshBar counted: ('class','MAGE') 0, ('accent', nil) 1
end)
test("under Blizzard none is painted where Blizzard's art shows", ...)
test('a pass of a color no widget reads paints nothing: Buttons > Danger, Class > Mage', ...)
test('100 passes over 200 widgets make nothing and allocate under 4 KB', function()
	-- 50 buttons, 50 check boxes, 50 thumbs, 50 action-button skins; m = C.measure(Normal pass, 100): m.made 0, m.forbidden.total 0, m.kb < 4
	-- C.print('core widgets', m)
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/live_widgets_test.lua`. Expected: FAIL, the highlight keeps its first color.
- [ ] **Step 3: Implement** the follows listed under Files. Each paint is a file-level function that reads `st:ColorRGBA` (Buttons) or `st:Color` when it runs and closes over nothing.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Widgets/button.lua SaftUI-Core/Widgets/checkbutton.lua SaftUI-Core/Widgets/scrollbar.lua SaftUI-Core/Widgets/radiogroup.lua SaftUI-Core/skinning.lua SaftUI-Core/panels.lua SaftUI-Core/Config/optionsresize.lua SaftUI-Core/EditMode/mover.lua SaftUI-Core/EditMode/Bar/bar.lua SaftUI-Core/EditMode/grid.lua tests/core/live_widgets_test.lua tests/core/button_opacity_test.lua tests/core/editmode_grid_test.lua .agents/architecture.md .agents/edit-mode.md
git commit -m "core: buttons, check boxes, thumbs, slot hovers, close buttons and the grid follow a color at once"
```

**In-game checks:**
- Buttons > Hover at 50%: a bag window's thumb under the mouse, a checked category filter box, the world map's resize corner follow as you drag (spec L2, first part).
- Buttons > Normal and Pushed: a bag header button's highlight and held fill.
- The Accent: bag slot hover follows; edit mode's grid centre lines (with `/sui edit` on) follow.
- Text > Muted: a close button's cross at rest.

---

### Task 3: Unit frames and nameplates

**Files:**
- Modify:
  - `SaftUI-Unitframes/unitframes.lua`: `UF:OnColorsChanged(group, key)` by Ruling 13; `UF:UpdateColors(group, key)`; `UF.ColorReaches`, `UF.COLOR_ELEMENTS`, `UF.COLOR_TAGS`, `UF.PREVIEW_GROUPS`. `'threat'` and `'theme'` as today.
  - `SaftUI-Unitframes/elements/indicators.lua`: nothing but what the role indicator needs to be found by `UF.COLOR_ELEMENTS` (its element name).
  - `SaftUI-Unitframes/grouppreview.lua`: `UF:UpdateGroupPreview` unchanged; the call sites in `UF:OnColorsChanged` take `UF.PREVIEW_GROUPS`.
  - `SaftUI-Unitframes/nameplates/threat.lua`: for `('text', 'normal')` (and key nil), `UF:UpdatePlateThreat(frame, true)` on shown plates, from `UF:OnColorsChanged`.
- Create: `tests/unitframes/color_cost_test.lua`.
- Test, modify: `tests/unitframes/colors_test.lua` (its cases call `OnColorsChanged(group)` with no key: the whole pass, unchanged), `tests/unitframes/role_colors_test.lua`, `tests/unitframes/threat_test.lua`.
- Docs: `.agents/architecture.md`'s unit frames Colors bullet (line 137): by key, the elements per group, a secret answer is a match, previews' groups.

**Interfaces:**
- Consumes: Task 1's `OnColorsChanged(group, key)`, `C.measure`, `C.print`.
- Produces: `UF.ColorReaches(frame, group, key) -> boolean`; `UF:UpdateColors(group, key)`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/color_cost_test.lua: colors_test.lua's stand-in oUF and counting frames, made into the full UI:
-- 40 raid frames 'raid1'..'raid40' (classes cycling the client's, 5 mages; roles 2 TANK, 8 HEALER, rest DAMAGER; raid7 offline),
-- 40 plates 'nameplate1'..'nameplate40' (30 NPCs at standing 2, 6 at 4, 4 enemy player mages), 10 single frames;
-- UnitClass, UnitReaction, UnitPowerType, UnitIsConnected, UnitIsTapDenied, UnitGroupRolesAssigned stubbed by unit
test("Class > Mage reaches only the mages' frames: Health and Power once each, and their tags; 15 calls at most", function()
	-- per frame updates; the 9 mages (5 raid + 4 plates) 1 Health, 1 Power, 1 tags each; every other frame 0
	-- UF.oUF.colors.class.MAGE is the new color; C.print('unit frames, class', m)
end)
test("Reputation > Hostile: the 30 plates at standing 2, Health and tags, 60 at most; the enemy players' plates untouched", ...)
test('Power > Mana: Power of mana users, every AdditionalPower; ClassPower only on the player frame, only for its own points', ...)
test('Status > Disconnected: Health of raid7 alone', ...)
test('Text > Danger: UpdateTags on every frame showing a unit (90 at most), no element update; Text > Normal: the shown plates\' threat text', ...)
test("Roles > Tank: the 2 tanks' role corners, in the Tank color; Damage reaches the damage dealers and those with none", ...)
test('a secret class, standing or power type counts as a match (Review Focus 2)', function()
	-- S.install(); UnitClass('raid3') returns a secret token -> raid3 updated on Class > Mage; #take_errors() == 0
end)
test('the whole pass (key nil) updates every frame with a unit, for the group\'s elements only', ...)
test('previews redraw for class, reaction, power, roles and text; not for status or threat', ...)
test('100 Class > Mage passes allocate under 4 KB; in combat the same calls (Review Focus 4)', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/unitframes/color_cost_test.lua`. Expected: FAIL, every frame's four elements update.
- [ ] **Step 3: Implement** by Ruling 13. A plate is skipped while it doesn't show its unit (`UF:PlateShowsUnit`), as today. Nothing else in the unit frames changes: no element's update, no plate's add.
- [ ] **Step 4: Run** `tests/run tests/unitframes`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Unitframes/unitframes.lua SaftUI-Unitframes/elements/indicators.lua SaftUI-Unitframes/grouppreview.lua SaftUI-Unitframes/nameplates/threat.lua tests/unitframes/color_cost_test.lua tests/unitframes/colors_test.lua tests/unitframes/role_colors_test.lua tests/unitframes/threat_test.lua .agents/architecture.md
git commit -m "unitframes: recolor only the frames and bars one color reaches, and follow roles and text colors at once"
```

**In-game checks:**
- In a group or raid, drag your class's color: your frame, your name and (in PvP) such plates follow; nothing else flickers (spec L3).
- Drag Reputation > Hostile near hostile mobs: their plates follow.
- Drag Text > Danger with a much higher mob targeted: its level tag follows.
- Roles: the corners in a group and in Test mode follow (spec L6, first part).
- `/sui debug`: the line's slowest pass for a class color in a raid.

---

### Task 4: Bags

**Files:**
- Modify:
  - `SaftUI-Bags/slot.lua`: `INV:OnColorsChanged(group, key)`: `'item_quality'` with a key, the slots of that quality only; `'text'`, `INV:ColorSlotTexts(slot)` (the item level by `INV.ItemLevelKey`, the reagent marker) on the slots whose key it is; `'accent'` and `'text'` normal, the view buttons as today; `'button'` danger, the bank's slots; `'theme'` as today. `INV.ItemLevelKey(info)` (Ruling 14), which `AssignSlot` uses too.
  - `SaftUI-Bags/header.lua`: `INV:ColorViewButtons(group, key)` by key.
  - `SaftUI-Bags/container.lua`: the loading bar follows the Accent (follower).
  - `SaftUI-Bags/containers/bag.lua`: the bag bar's slot hover follows the Accent; the footer text set again for `('text', 'success')`.
  - `SaftUI-Bags/containers/bank.lua`: the unbought slots' tint and the price text, by key.
  - `SaftUI-Bags/containers/combinedbank.lua`: the eye follows Muted; the footer for `('text', 'shared')`.
  - `SaftUI-Bags/currencies.lua`: the funnel follows Normal; the shown counts by key; the borders by quality key.
  - `SaftUI-Bags/inventory.lua`: the selected bank window's border on `'accent'`.
  - `SaftUI-Bags/views.lua`: `INV:RetitleSections()`, the shown sections' titles set again (`BagTitle`), nothing laid out, for `('text', 'muted')`.
- Create: `tests/bags/live_colors_test.lua`.
- Test, modify: `tests/bags/slot_quality_test.lua`, `tests/bags/item_level_colors_test.lua`, `tests/bags/state_colors_test.lua`, `tests/bags/accent_pins_test.lua` (where they pin "reload" behavior).
- Docs: `.agents/architecture.md` (the accent sentence's bags; the item quality line), and nothing else.

**Interfaces:**
- Consumes: Task 1; Task 2's `st:SkinActionButton` hover follower (the item slots' hover follows through it).
- Produces: `INV.ItemLevelKey(info)`, `INV:ColorSlotTexts(slot)`, `INV:RetitleSections()`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/bags/live_colors_test.lua (as font_drag_test.lua's world: Core's window and the bags' real files;
-- containers made by hand: 4 bags, the reagent bag, the bank and the warband bank, 700 slots, 40 of them epic,
-- 100 armor or weapons (10 Warbound, 20 Bind on Equip), 20 currencies (3 epic))
test('Item quality > Epic: only the 40 epic slots and 3 epic currencies, nothing laid out, sorted or made', function()
	-- st:SetBorderColor calls == 43; INV:UpdateContainer, INV:ApplyView, the sorter: 0 calls; m.made == 0; m.forbidden.total == 0
end)
test("the Accent: every item slot's hover once (Task 2's follower), the bag bar's slots, the loading bars, the selected bank window", ...)
test('Text > Strong, Success, Shared: item levels by their key, reagent markers, currency counts, footers', function()
	-- Strong: 70 item levels and the strong currency counts; Success: 20 item levels, the reagent markers, the reagent footer
end)
test("Text > Muted: a special bag's title set again (nothing laid out), the combined bank's eye", ...)
test("Buttons > Danger: the bank's unbought slots, at their region's 0.3", ...)
test('INV.ItemLevelKey: Warbound shared, Bind on Equip success, else strong', ...)
test('100 Accent passes over 700 slots allocate under 4 KB; in combat the same (Review Focus 4)', function()
	-- C.print('bags, accent', m); C.print('bags, epic', m2)
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/bags/live_colors_test.lua`. Expected: FAIL, every filled slot is recolored on Epic.
- [ ] **Step 3: Implement** as listed under Files. Colors on the slots' regions are set in combat too (a color setter is not protected); nothing waits for combat.
- [ ] **Step 4: Run** `tests/run tests/bags`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Bags/slot.lua SaftUI-Bags/header.lua SaftUI-Bags/container.lua SaftUI-Bags/containers/bag.lua SaftUI-Bags/containers/bank.lua SaftUI-Bags/containers/combinedbank.lua SaftUI-Bags/currencies.lua SaftUI-Bags/inventory.lua SaftUI-Bags/views.lua tests/bags/live_colors_test.lua tests/bags/slot_quality_test.lua tests/bags/item_level_colors_test.lua tests/bags/state_colors_test.lua tests/bags/accent_pins_test.lua .agents/architecture.md
git commit -m "bags: recolor only what one color reaches, and follow text, button and accent colors at once"
```

**In-game checks:**
- Every bag and the bank open: drag Item quality > Epic; only epic borders change (spec L4, first part).
- Text > Strong, Success, Shared: item levels; the reagent and warband counts in the footers; currency counts.
- Text > Muted: a special bag's title's grey part; the combined bank's eye.
- Buttons > Danger: unbought bank slots.
- The Accent: the bags' loading bar on a fresh open, the selected bank window's border.

---

### Task 5: Action bars, the totem bar and the minimap

**Files:**
- Modify:
  - `SaftUI-ActionBars/skin.lua`: `AB:OnColorsChanged(group, key)`: `'theme'` as today; `'accent'`, the equipped buttons' border; `'button'` with `'danger'` or nil, `AB:ColorFlash(button)` on each skinned button whose look isn't Blizzard's (the flash's `SetColorTexture` at 0.4).
  - `SaftUI-Misc/totemskin.lua`: `TB:OnColorsChanged(group, key)`: `'theme'` as today; `'button'` danger, the flash; `'accent'`, the hover; `'text'` normal, the flyout's arrow; `'text'` normal or danger, `TB:ColorTimers()`.
  - `SaftUI-Misc/totemtimers.lua`: `TB:ColorTimers()`: the text curve and each timer's bar curve dropped (`textCurve = nil`, `timer.barCurve = nil`), each shown timer colored again by its state; nothing laid out (not `ApplyTimerLayout`).
  - `SaftUI-Minimap/micromenu.lua`: `MicroMenu:OnColorsChanged(group, key)` calls `MicroMenu:ColorMicroButtons(key)` for `'button'` hover or pushed and `'text'` caution, and `MicroMenu:ColorDifficulty()` for `'item_quality'` 1, 3, 4 (or nil).
  - `SaftUI-Minimap/microbuttons.lua`: `MicroMenu:ColorMicroButtons(key)`: each skinned micro button's highlight (Hover at `HOVER_ALPHA`), pushed fill (Pushed at `PUSHED_ALPHA`) and alert flash (Caution at `ALERT_ALPHA`), under Thick and Thin only, the color of the region SaftUI already set.
  - `SaftUI-Minimap/micromenuitems.lua`, `queuebutton.lua`, `expansionbutton.lua`: their textures follow (followers).
  - `SaftUI-Minimap/instancedifficulty.lua`: `MicroMenu:ColorDifficulty()`, the badge's color part of the skin, which the skin calls.
- Create: `tests/actionbars/live_colors_test.lua`.
- Test, modify: `tests/misc/totem_state_colors_test.lua`, `tests/minimap/state_colors_test.lua`.
- Docs: `.agents/architecture.md` (the micro menu's line: its handler), `.agents/taint.md` (rule 5's micro menu note, or the totem bar's: a color pass only colors their regions, in combat too).

**Interfaces:**
- Consumes: Task 1.
- Produces: `AB:ColorFlash(button)`, `TB:ColorTimers()`, `MicroMenu:ColorMicroButtons(key)`, `MicroMenu:ColorDifficulty()`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/actionbars/live_colors_test.lua (the action bars' world as layout_test.lua builds it: 12 bars of 12, the pet and stance bars)
test("Buttons > Danger: every button's flash once under Thick and Thin (164 SetColorTexture), none under Blizzard", ...)
test("the Accent: the equipped buttons' borders only", ...)
test('in combat the same calls, and none forbidden on a secure button (Review Focus 4)', function()
	-- stub.in_combat = true; m = C.measure(Danger pass): m.forbidden.total == 0; C.print('action bars, danger', m)
end)
-- tests/misc/totem_state_colors_test.lua
test("Text > Danger and Normal: the timers' curves are made again and each shown timer colored at once, nothing laid out", ...)
test('Buttons > Danger: the flash; the Accent: the hover; Text > Normal: the flyout arrow', ...)
-- tests/minimap/state_colors_test.lua
test("Buttons > Hover and Pushed: the micro buttons' highlight at 0.4 and pushed fill at 0.6, under Thick and Thin only", ...)
test('Text > Caution: the alert flash; Item quality 1, 3 and 4: the difficulty badge', ...)
test('the bar items and the tracking, queue and expansion buttons follow Normal, Pushed and Hover', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/actionbars/live_colors_test.lua tests/misc/totem_state_colors_test.lua tests/minimap/state_colors_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/actionbars tests/misc tests/minimap`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-ActionBars/skin.lua SaftUI-Misc/totemskin.lua SaftUI-Misc/totemtimers.lua SaftUI-Minimap/micromenu.lua SaftUI-Minimap/microbuttons.lua SaftUI-Minimap/micromenuitems.lua SaftUI-Minimap/queuebutton.lua SaftUI-Minimap/expansionbutton.lua SaftUI-Minimap/instancedifficulty.lua tests/actionbars/live_colors_test.lua tests/misc/totem_state_colors_test.lua tests/minimap/state_colors_test.lua .agents/architecture.md .agents/taint.md
git commit -m "actionbars, misc, minimap: flashes, the equipped border, totems and micro buttons follow a color at once"
```

**In-game checks:**
- Buttons > Danger: an action button's flash (attack with an auto-attack button) and a totem's.
- The Accent: an equipped item's border on a bar; totem hover.
- Text > Danger with a totem down: its timer under 10 seconds follows.
- Buttons > Hover and Pushed: the micro buttons; Text > Caution: an alert flash; in an instance, the difficulty badge for Item quality.
- No `ADDON_ACTION_BLOCKED` with bars and totems in use.

---

### Task 6: Loot

**Files:**
- Modify:
  - `SaftUI-Loot/init.lua`: `LT:OnColorsChanged(group, key)` passes the key on.
  - `SaftUI-Loot/roll.lua`: `LT:ColorRollBars(group, key)`: `'accent'` as today, plus the held bars' timers; `'loot'`, each skinned roll frame's letter of that choice (`skin.buttonText`); `'item_quality'`, the shown rolls of that quality (`skin.shown` keeps `quality`) color their `Name` again; the held bars likewise.
  - `SaftUI-Loot/rollinfo.lua`: `LT:ColorRollCounts(key)`, the shown counts of that choice.
  - `SaftUI-Loot/rollbar.lua`: the held bar's timer color as a function `ColorBarTimer(bar)` the pass can call.
  - `SaftUI-Loot/Feed/feed.lua`: Ruling 15; `LT:ColorFeed(group, key)`: `'text'` and `'accent'` as today; `'theme'` and `('loot', 'mount')`, the shown mount entries; `'item_quality'`, the shown lines of that quality set their name again; `'reaction'` and `'renown'`, the shown progress lines' bars.
  - `SaftUI-Loot/Feed/progress.lua`: a progress entry keeps `colorGroup` and `colorKey` (Ruling 15).
- Create: `tests/loot/live_colors_test.lua`.
- Test, modify: `tests/loot/loot_colors_test.lua`, `tests/loot/feed_test.lua` (where they read a pushed entry's colored `name`).
- Docs: `.agents/architecture.md` (Loot's line under the accent sentence; "Roles and Loot readers don't recolor live" goes in Task 8).

**Interfaces:**
- Consumes: Task 1.
- Produces: `LT.FeedItemName(info) -> string`, `LT:ColorRollCounts(key)`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/loot/live_colors_test.lua (roll_skin_test.lua's skinned roll frames, feed_test.lua's feed with 20 lines:
-- 6 epic items, 4 rare, 2 mounts, 3 reputation lines at Friendly, 1 renown)
test("Loot > Need: each roll frame's Need letter and the shown Need counts; Greed's untouched", ...)
test("Loot > Mount: the 2 shown mount entries' border and 60% fill", ...)
test('Item quality > Epic: the 6 epic lines set their name again in the new color; the others untouched', ...)
test('the feed keeps the plain name and quality, and a line drawn later takes the current color (LT.FeedItemName)', ...)
test("Reputation > Friendly: the 3 reputation lines' bars; Renown: the renown line's", ...)
test('a progress line reads its color as it draws, so a profile switch reaches it', ...)
test("the Accent: held bars' timers; Item quality on a shown roll: its name", ...)
test('a pass makes nothing and allocates under 4 KB over 100', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/loot/live_colors_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files. The roll letters are SaftUI's own font strings on Blizzard's roll buttons and the `Name` is a region of Blizzard's roll frame: color setters only (`.agents/taint.md` rule 1: nothing written onto them).
- [ ] **Step 4: Run** `tests/run tests/loot`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Loot/init.lua SaftUI-Loot/roll.lua SaftUI-Loot/rollinfo.lua SaftUI-Loot/rollbar.lua SaftUI-Loot/Feed/feed.lua SaftUI-Loot/Feed/progress.lua tests/loot/live_colors_test.lua tests/loot/loot_colors_test.lua tests/loot/feed_test.lua .agents/architecture.md
git commit -m "loot: roll letters and counts, the feed's names, mounts and bars follow a color at once"
```

**In-game checks:**
- Test mode's rolls (`/sui` > Loot): drag Loot > Need and Pass: the letters and counts follow (spec L6, second part).
- The feed with a mount line: Loot > Mount follows; Item quality > Epic: epic names in the feed follow; a reputation gain line: its standing's color follows.

---

### Task 7: Misc's skins, the tooltip and SaftUI's tracker

**Files:**
- Modify:
  - `SaftUI-Misc/tooltip.lua`: `TT:OnColorsChanged(group, key)`: `'theme'` as today; `'class'` and `'reaction'`, each shown unit tooltip's first line and borders from the color it holds.
  - `SaftUI-Misc/Skinning/skinning.lua`: `SK:OnColorsChanged(group, key)` passes the key on.
  - `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua`: `('text', 'strong')` (or nil), the shown slots' item levels.
  - `SaftUI-Misc/Skinning/addons/restedxp.lua`: `RX:OnColorsChanged(group, key)`: `'theme'` as today; `('text', 'muted')`, the thumb, step numbers and titles (`MutedRGB` readers).
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua`: `CP:OnColorsChanged(group)` only for `'accent'` and `'theme'`.
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua`: `OT:OnColorsChanged(group)` only for `'text'`, `'objectives'`, `'accent'` and `'theme'`.
  - `SaftUI-Tracker/init.lua`: `TR:OnColorsChanged(group, key)` returns for any group but `'text'`, `'objectives'`, `'accent'` and `'theme'`.
- Test, modify: `tests/misc/tooltip_skin_test.lua`, `tests/misc/characterframe_test.lua`, `tests/misc/restedxp_panel_test.lua`, `tests/misc/color_picker_skin_test.lua`, `tests/misc/objective_tracker_skin_test.lua`, `tests/tracker/rows_test.lua`.
- Docs: `.agents/architecture.md` (the tracker's "repaints its accent pieces on any group" becomes its four groups), `.agents/taint.md` (rule 1's objective tracker paragraph names its groups).

**Interfaces:**
- Consumes: Task 1.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/misc/tooltip_skin_test.lua
test('a shown unit tooltip takes its class or standing color at once; a hidden one is left for its next show', ...)
-- tests/misc/characterframe_test.lua
test('Text > Strong: the shown item levels at once', ...)
-- tests/misc/restedxp_panel_test.lua
test('Text > Muted: the thumb, the step numbers and the titles at once', ...)
-- tests/misc/color_picker_skin_test.lua, objective_tracker_skin_test.lua
test('the skin repaints for its groups only: a Class pass touches nothing', ...)
-- tests/tracker/rows_test.lua
test('a Class or Power pass repaints nothing in the tracker; Text, Objectives and the Accent still do', function()
	-- RW.calls() around st:ColorChanged('class', 'MAGE') outside an edit: total 0; ('text', 'muted'): > 0
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/misc tests/tracker/rows_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files. The tooltip's first line is Blizzard's font string on `GameTooltip`: `SetTextColor` on that region only, as `TT:GameTooltip_OnTooltipSetUnit` already does.
- [ ] **Step 4: Run** `tests/run tests/misc tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Misc/tooltip.lua SaftUI-Misc/Skinning/skinning.lua SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua SaftUI-Misc/Skinning/addons/restedxp.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua SaftUI-Tracker/init.lua tests/misc/tooltip_skin_test.lua tests/misc/characterframe_test.lua tests/misc/restedxp_panel_test.lua tests/misc/color_picker_skin_test.lua tests/misc/objective_tracker_skin_test.lua tests/tracker/rows_test.lua .agents/architecture.md .agents/taint.md
git commit -m "misc, tracker: the shown unit tooltip, item levels and RestedXP follow a color, and skins repaint only for theirs"
```

**In-game checks:**
- Hover a player, keep the tooltip up, drag their class's color: the name and border follow.
- Character frame open: Text > Strong.
- RestedXP open: Text > Muted.
- SaftUI's tracker on: Text and Objectives colors still follow; dragging a class color costs it nothing (the debug line).

---

### Task 8: The Colors page's notes and the docs

**Files:**
- Modify:
  - `SaftUI-Core/Media/colors.lua`: `RELOAD_NOTE` and `ACCENT_RELOAD_NOTE` go; Buttons' note is "Opacity sets how strongly each is drawn: 100% is SaftUI's own."; Text, Roles, Factions and Loot have none; the Accent's desc ends at "and the chat prefix."; `CO:GetConfigTable()` gains `args.intro = { type = 'description', order = 0, name = 'A change shows everywhere as you pick it. This window takes it when the picker closes.' }`.
  - `docs/superpowers/specs/2026-11-14-saftui-color-roles-design.md`: under its non-goal "Live Text and Buttons colors", "**Revised 2026-11-15:** every color now shows at once; see `docs/superpowers/specs/2026-11-15-saftui-live-colors-design.md`."
  - `docs/superpowers/plans/2026-11-15-saftui-color-roles-in-game-checklist.md`: a note at its top: its reload steps (the top line, 4.3, 6 "reload") now show at once, checked by `docs/superpowers/plans/2026-11-15-saftui-live-colors.md`'s checklist.
  - `.agents/architecture.md`: "Nearly everything else reads it when it draws... (the Accent row's description says so). Roles and Loot readers don't recolor live (their sections say to reload)" becomes the list of what stays as it is (the spec's section).
  - `docs/followups.md`: two entries, by the template: "`/sui` following during a color drag" (the spec's Question 2: why it waits for close, the kit files it would touch, the branches in flight) and "The Theme tab's color drag recolors every drawn frame" (to act on if the owner's debug line shows `theme` over 8 ms).
- Test, modify: `tests/core/colors_test.lua`, `tests/core/accent_test.lua`.

**Interfaces:**
- Consumes: Tasks 2 to 7 (every reader live).

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/colors_test.lua
test('no section note says to reload; Buttons\' says what opacity does; the others have none', function()
	-- for each section of CO.SECTIONS: not (section.note or ''):lower():find('reload')
	-- button's note == "Opacity sets how strongly each is drawn: 100% is SaftUI's own."; text, roles, factions, loot: nil
end)
test('the Colors tab starts with its line', function()
	-- args.intro: type 'description', order 0, name 'A change shows everywhere as you pick it. This window takes it when the picker closes.'
end)
-- tests/core/accent_test.lua
test("the Accent's description says nothing of a reload", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/colors_test.lua tests/core/accent_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Commit**

```bash
git add SaftUI-Core/Media/colors.lua tests/core/colors_test.lua tests/core/accent_test.lua docs/superpowers/specs/2026-11-14-saftui-color-roles-design.md docs/superpowers/plans/2026-11-15-saftui-color-roles-in-game-checklist.md .agents/architecture.md docs/followups.md
git commit -m "core: the Colors page drops its reload notes and says a change shows as you pick it"
```

**In-game checks:**
- The Colors page: no "reload" anywhere; the line at its top; Buttons' opacity note.
- The whole of Part A's checklist below (L1 to L9).

---

### Task 9: The preview area, its field and the `text` kind

**Files:**
- Create: `SaftUI-Core/Config/optionspreview.lua`: `W.DefinePreview`, `W.ReadPreview`, `W.PreviewKinds`, `W.PREVIEW` (Ruling 17), the `text` kind; the built-in kinds recorded at its end (Ruling 20).
- Modify:
  - `SaftUI-Core/Config/optionscolorpicker.lua`: `W.OpenColorPicker`'s spec takes `preview` and `name`; `Layout(hasAlpha, kind)` adds the area when `W.ReadPreview(spec.preview)` gives a known kind (else today's layout); `F.preview` (the area, a SaftUI frame), `F.previewCaption` ("Preview", the caption font, Muted), `F.previewNote` (the kind's `note`, right-aligned, Muted, hidden without one); the kind's pieces built once (`F.previewPieces[name]`) and shown for it; `Paint()` calls the kind's `Paint(pieces, S.r, S.g, S.b, alpha, spec)`; `st:KeepOwnColors(F.preview, RepaintPreview)`.
  - `SaftUI-Core/Config/optionstypes.lua`: the color type's `Pick` passes `preview = self.row.option.preview` (raw) and `name` (the row's name).
  - `SaftUI-Core/Config/load.xml`, `tests/lib/shell.lua`: `optionspreview.lua` after `optionscolorpicker.lua`.
  - `tests/lib/options_walk.lua`: `preview` in `SAFTUI_FIELDS`.
  - `SaftUI-Core/Media/colors.lua`: `preview` on the Text rows (`'text'`), Factions (`{ kind = 'text', sample = '(Alliance territory)' }`, `'(Horde territory)'`, `'(Contested territory)'`), Loot's Need, Greed, Transmog and Pass (`'text'`), Objectives (`sample = '8/8 Things slain'`, `'Escort failed'`).
- Create: `tests/core/options_color_preview_test.lua`.
- Test, modify: `tests/lib/harness_self_test.lua` (the shell's file list against `load.xml`).
- Docs:
  - `.agents/edit-mode.md`: the picker paragraph (the preview area, sizes, `preview` as SaftUI's field read raw, `W.DefinePreview`, `W.ReadPreview`, the kinds); the widget files' list and order (`optionspreview.lua`); `covers:` gains `SaftUI-Core/Config/optionspreview.lua`.
  - `.agents/testing.md`: the new test file; `options_walk.lua`'s fields.
  - `docs/design-system/components/ColorBar/README.md`: it opens SaftUI's picker (not Blizzard's), whose swatch and code follow live; a `preview` field adds the picker's preview.

**Interfaces:**
- Consumes: Task 1's `st:BeginColorEdit` in the picker (unchanged).
- Produces:

```lua
W.PREVIEW                               -- Ruling 17
W.DefinePreview(name, def) -> boolean   -- def = { Build = fn(area, width, height) -> pieces, Paint = fn(pieces, r, g, b, a, spec), note = string|nil }
                                        -- false for a built-in kind's name, or a def without Build and Paint
W.ReadPreview(value) -> name, fields | nil  -- 'text' -> 'text', {}; { kind = 'bar', style = 'unit' } -> 'bar', that table; anything else, or a name no kind has, -> nil
W.PreviewKinds() -> { [name] = def }    -- for tests
-- spec passed to Paint: { fields = <the preview table, or {}>, name = <the option's name>, hasAlpha = boolean }
```

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_color_preview_test.lua (on options_widgets_helpers.lua's world, as options_color_picker_test.lua)
test("an option with no preview opens today's picker: 410 by 388, 442 with an opacity, nothing moved", ...)
test('a text preview: 482 tall; Class colors at 342 and 360, Last used at 388 and 406, the buttons 16 from the bottom; the area 370 by 64 at 20, 266', ...)
test("the text kind: three tiles 118 by 44 at 20, 146, 272, drawn thick/solid, thin/solid and theme/options as panels", function()
	-- T.watch() drawn(tile) == 'thick,solid,panel', 'thin,solid,panel', 'theme,options,panel'
	-- each: 'Text' in Text > Normal beside the sample in the picker's color; captions Thick, Thin, Options windows in Muted
end)
test('it paints on every change, live: 1000 changes, 24 setter calls at most each, under 4 KB', ...)
test("the sample: the field's own, else the color's name", ...)
test('W.ReadPreview: a name, a table with a kind, else nil; an unknown kind opens today\'s picker with no error', ...)
test("W.DefinePreview refuses a built-in kind's name and a def without Build and Paint; a module's kind shows", ...)
test('the pieces are built once per kind and kept; a picker opened for another kind hides them', ...)
test('every part is on whole pixels under Thick, Thin and Blizzard, with sizes read back a hair off', ...)
test("a theme recolor while it is open puts the preview's own colors back", ...)
test('the Text, Factions, Loot letter and Objectives rows carry their previews', ...)
-- tests/lib/harness_self_test.lua: load_options_widgets()'s list matches load.xml, optionspreview.lua after optionscolorpicker.lua
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/options_color_preview_test.lua`. Expected: FAIL, `W.DefinePreview` is nil.
- [ ] **Step 3: Implement** as the Interfaces and Rulings 17 and 20 say. The tiles are SaftUI frames children of `F.preview`, drawn with `st:SetTemplate`; the Options windows tile sits on a texture in the `world` stand-in color (`#2f3324`, `docs/design-system/tokens.json`), so its see-through shows.
- [ ] **Step 4: Run** `tests/run tests/core tests/lib/harness_self_test.lua`, then `tests/run -j2`. Expected: PASS; `options_color_picker_test.lua` passes unchanged.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionspreview.lua SaftUI-Core/Config/optionscolorpicker.lua SaftUI-Core/Config/optionstypes.lua SaftUI-Core/Config/load.xml SaftUI-Core/Media/colors.lua tests/lib/shell.lua tests/lib/options_walk.lua tests/lib/harness_self_test.lua tests/core/options_color_preview_test.lua .agents/edit-mode.md .agents/testing.md docs/design-system/components/ColorBar/README.md
git commit -m "options: a preview strip in the color picker, chosen by the option, with the text kind"
```

**In-game checks:**
- P1: Text > Danger: the three tiles, Text beside Danger, under Thick, Thin and Blizzard; the Options windows tile see-through when Options windows are.
- Factions and Objectives: their lines; Loot's letters.
- P5: a unit's Custom color opens today's picker, no preview.
- The picker opens beside its field and stays on screen at its new height.

---

### Task 10: The `button` and `accent` kinds

**Files:**
- Modify:
  - `SaftUI-Core/Config/optionspreview.lua`: the `button` kind (five tiles 74 by 44, the states as the spec tables, each piece at its reader's strength times the opacity; the captions of the tiles the edited key reaches in Text, the rest Muted; under Blizzard drawn as Thick with the note "Shown as Thick: under Blizzard, SaftUI's buttons wear Blizzard's art.") and the `accent` kind (four tiles: a field's edge as under the mouse (`W.Box`, `W.Edge`), a ticked `Kit.CheckBox`, a slider's track and fill, a selected sidebar row's 25% tint and bar; under Blizzard a link, a picked list entry, an own mark and a selected mover's edge).
  - `SaftUI-Core/Media/colors.lua`: the Buttons rows' `{ kind = 'button', key = <key> }`; the Accent row's `'accent'`.
  - `tests/wow/widgets.lua`: `LockHighlight` and `SetButtonState`, if missing (Ruling 19).
- Test, modify: `tests/core/options_color_preview_test.lua`, `tests/lib/harness_self_test.lua` (the stubs, if added).
- Docs: `.agents/edit-mode.md` (the two kinds).

**Interfaces:**
- Consumes: Task 9's `W.DefinePreview` contract (built-ins recorded at the file's end).

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_color_preview_test.lua
test("the button kind: five tiles, each state's pieces at its strength times the opacity; the edited key's captions in Text", function()
	-- Buttons > Hover picked at 0.7: the Hover tile's thumb and the Checked tile's box draw (r, g, b, 0.7);
	-- captions Hover and Checked in Text > Normal, Rest, Pressed and Flash in Muted
	-- Buttons > Danger at 0.5: the flash at 0.4 * 0.5, the bank slot's tint at 0.3 * 0.5
	-- the button's highlight held by LockHighlight and its press by SetButtonState('PUSHED', true): stub.state(button) records both,
	-- and GetButtonState() == 'PUSHED'
end)
test('the button kind under Blizzard: its pieces drawn as Thick, the note on the caption row', ...)
test('the accent kind: an edge, a ticked check box, a slider fill, a selected row, in the picked color; under Blizzard the other four', ...)
test('the Buttons rows and the Accent row carry their previews', ...)
test('whole pixels under each look; 24 setter calls at most per paint, under 4 KB over 1000', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/options_color_preview_test.lua`. Expected: FAIL, no `button` kind.
- [ ] **Step 3: Implement** as listed under Files. Every piece is the real one (`st:CreateButton` and `st:SkinButton`, `st:SkinCheckButton`, the action bars' flash as `skin.lua` draws it on a SaftUI button), with its state held by the button's own methods.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionspreview.lua SaftUI-Core/Media/colors.lua tests/core/options_color_preview_test.lua tests/wow/widgets.lua tests/lib/harness_self_test.lua .agents/edit-mode.md
git commit -m "options: the color picker's preview shows a button's states and the accent's controls"
```

**In-game checks:**
- P2: each Buttons color: the five states, its own tiles lit, the opacity drawn; under Blizzard the note.
- P4, second part: the Accent: the four tiles; under Blizzard the other four.

---

### Task 11: The `bar` and `border` kinds

**Files:**
- Modify:
  - `SaftUI-Core/Config/optionspreview.lua`: the `bar` kind's styles (`unit`: a 200 by 28 health bar filled 70% with the label and "70%", an 80 by 40 raid frame, a unit tooltip with its name and border in the color; `role`: a raid frame with `st.textures.cornerbr` in the color; `reputation`: the experience bar's reputation bar and an NPC's health bar; `power`: a health bar with a power bar under it; `points`: five class power points, three lit; `plate`: a 200 by 20 nameplate with its name, and with `threat` the percent above its right end in the color), drawn with `st:CreateStatusBar` (kind `bar`); the `border` kind's styles (`slot`: a `slot` with an icon and `st:SetBorderColor`, and a feed line with an item's name in the color; `entry`: a feed entry with its border and its fill at 60%).
  - `SaftUI-Core/Media/colors.lua`: the previews of Class, Roles, Reputation and Renown, Power (the five point powers `'points'`), Item quality, Loot > Mount, Status and Threat, as the spec's table.
- Test, modify: `tests/core/options_color_preview_test.lua`.
- Docs: `.agents/edit-mode.md` (the two kinds).

**Interfaces:**
- Consumes: Task 9's contract.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_color_preview_test.lua
test('bar unit: a 200 by 28 health bar 70% filled in the color with the label and 70%; an 80 by 40 raid frame; a tooltip in the color', function()
	-- drawn(bar) == 'theme,solid,bar'; GetStatusBarColor == the picked color; label 'Mage'
end)
test('bar role, reputation, power, points, plate and threat, each its pieces in the color', ...)
test("border slot: the slot's border in the color through st:SetBorderColor, and the feed line's name; entry: border and 60% fill", ...)
test('every Colors row has a preview that opens, and every Accent row too', function()
	-- for each section and color of CO.SECTIONS, and CO:AccentOption: W.ReadPreview(option.preview) ~= nil, and opening it errors nothing
end)
test('whole pixels under each look; 24 setter calls at most per paint, under 4 KB over 1000', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/options_color_preview_test.lua`. Expected: FAIL, no `bar` kind.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionspreview.lua SaftUI-Core/Media/colors.lua tests/core/options_color_preview_test.lua .agents/edit-mode.md
git commit -m "options: the color picker's preview shows bars, plates, slots and feed entries for every other color"
```

**In-game checks:**
- P3: Class, Power (a bar and Combo points), Reputation, Status, Threat and Roles: their bars at their sizes, in the picked color.
- P4, first part: Item quality on a slot and a feed line; Loot > Mount on a feed entry.
- Every Colors row opens with a preview; under Thick, Thin and Blizzard.

---

## In-game checklist (the whole plan)

Do it on both clients (WoW Forever, interface 16001, and retail, interface 120000), at SaftUI's defaults unless an item says otherwise. Nothing here needs a character, realm or account name.

**Part A** (after Task 8):

1. **L1.** Global settings > Colors, drag Text > Danger: an error status line, the edit mode bar's refusal, a loot roll timer under a minute, expiring totems, and a much higher mob's level tag follow as you drag. Cancel: every one goes back.
2. **L2.** Buttons > Hover at 50%: a bag window's thumb under the mouse, a checked category filter box, the micro buttons' highlight, as you drag, with no reload.
3. **L3.** In a group, Class > your class: your raid frame, your name and your nameplate follow; nothing else flickers.
4. **L4.** Every bag and the bank open, Item quality > Epic: only epic borders change; the loot feed's epic names follow.
5. **L5.** The Accent: bag slot hover, totem hover, an equipped item's border, the grid's centre lines, a held roll's timer follow at once; `/sui`'s sidebar, tabs and sliders follow when the picker closes.
6. **L6.** Roles and Loot: role corners in a group and in Test mode; roll letters, counts and the feed's mount lines.
7. **L7.** `/sui debug` on, in a raid or a busy city with every bag open: drag Class, Item quality, Text > Danger and the Accent a few seconds each, Okay each time. Each line's slowest pass stays under 2 ms; say if one doesn't, with its line. Drag a Theme tab color: note the `theme` line.
8. **L8.** Switch to a profile with other colors, out of combat and with the color roles checklist's macro (2.8) in combat: every reader takes the new colors (in combat once it ends), no `ADDON_ACTION_BLOCKED`.
9. **L9.** At a training dummy, open the picker and drag, then attack: the picker cancels, everything is back on the opening color, no error, no blocked action.

**Part B** (after Task 11):

1. **P1.** Text colors: three tiles, Text beside the color, on Thick, Thin and the Options windows background, under each theme.
2. **P2.** Buttons colors: five states, the edited key's lit, the opacity drawn; under Blizzard the note.
3. **P3.** Class, Power, Reputation, Status, Threat, Roles: the bars at their sizes.
4. **P4.** Item quality and Mount: the slot and the feed entry. The Accent: its four tiles, and under Blizzard the other four.
5. **P5.** A unit's Custom color: no preview, today's size.
6. **Placement.** If the strip under the square feels wrong in use, say so: B is Ruling 18.

---

## Spec coverage check

| Spec section, decision or call | Task |
| --- | --- |
| Why; decided 1 (live first), 2 (Cancel restores) | 1 (mechanism, Cancel through the same path), 2 to 7 (readers) |
| Decided 3 (a preview by context) | 9, 10, 11 |
| Decided 4 (lag measured) | 1 (`tests/lib/color_cost.lua`, the guard, the debug line), 2 to 7 (each heavy reader's cost case) |
| Goals: 80 colors live; one pass a frame; nothing made or allocated; notes true | 1; 2 to 7; 1 and each cost case; 8 |
| Non-goals: Theme tab colors (timed only); other color options; `/sui` during a drag; chat lines; Buttons' mapping; previews elsewhere | 1 (Ruling 7), — , 8 (followup), —, 10 (shows the mapping), 9 (the field) |
| Anti-goals: no frame made, no layout, no allocation; no taint; no hot path; Cancel; real pieces, whole pixels | 1 (`C.FORBIDDEN`, `C.MAKERS`), Global Constraints, each reader task's Step 3, 1, 9 to 11 |
| The audit: Text | 1 (field font, picker), 2 (close button), 3 (tags, threat text, previews), 4 (bags), 5 (totems, micro flash), 6 (roll timers as today), 7 (character frame, RestedXP, tracker filter) |
| The audit: Buttons | 2 (Core's), 4 (bank), 5 (action bars, totems, micro buttons and items) |
| The audit: Class, Reputation, Renown, Power, Status, Threat, Roles | 3 (unit frames, previews), 7 (tooltip), 6 (feed bars), 1 (picker chips) |
| The audit: Item quality, Loot | 4 (bags), 6 (feed, rolls), 5 (difficulty badge) |
| The audit: Factions, Objectives | as today (7 narrows the skins' and tracker's groups) |
| The audit: the Accent | 2 (slot hover, radio, grid, edit mode bar), 4 (loading bar, selected window), 5 (equipped border, totems), 6 (held bars), 7 (color picker skin) |
| Live today and after (41 to 80) | 2 to 7, checked by L1 to L6 |
| The mechanism: notification, edits, pass, whole pass, followers, modules, what a pass may call, hot paths, guard, debug line | 1 |
| The profile update's whole passes | 1 (Ruling 12), L8 |
| The budget and how it is measured; the heavy readers' bounds | 1 (helper), 3 (unit frames, nameplates), 4 (bags), 5 (action bars), 7 (tracker), 2 (edit mode bar) |
| What stays as it is | 8 (architecture.md, followups) |
| The Colors page's notes; the color roles spec and checklist notes | 8 |
| Part B: where it sits (A; B as Ruling 18); no preview | 9 |
| The field; `W.DefinePreview` | 9 |
| The kinds: `text`; `button`, `accent`; `bar`, `border`; each row's preview | 9; 10; 11; 9, 10, 11 |
| Real pieces; Thick, Thin and Blizzard; whole pixels; cost; theme recolor | 9 (and each kind's task) |
| In-game checks L1 to L9, P1 to P5 | the checklist above; per task |
| Calls 1 to 20 | 1: 1; 2: 1, 2; 3, 4, 5, 6, 7, 8, 9: 1; 10: 8; 11: 1; 12: 3; 13: 2, 7; 14: 6; 15: 9; 16: 9; 17: 9 to 11; 18: 10; 19: 9; 20: 9, 11 |

**Where the spec is silent or the code disagrees** (each is a Ruling above):
- **The code disagrees:** step 8 runs in two places (Ruling 12); the picker's `OnHide` runs Cancel a second time (Ruling 10); oUF's color path is local (Global Constraints: `ForceUpdate`); the loot feed bakes a name's color and a progress bar holds the profile's color object (Ruling 15); the totem timers' only re-color path also lays out (`ApplyTimerLayout`, so Task 5 adds `TB:ColorTimers`).
- **Tests that pin what this work changes:** the set and reset spies in `colors_test.lua` and `accent_test.lua` (1); the bags' quality and state color cases (4); the loot feed's colored names (6); the tracker's repaint on any group (7); the Colors page's notes (8).
- **The spec leaves open:** Rulings 1 to 9, 13, 14, 16, 17, 19, 20.
