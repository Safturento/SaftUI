# Action Bars Shared Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/sui` → Action Bars gets an All bars entry whose settings every bar follows until a bar owns one, marks and a hover line that show and act on what differs, small parts (the four texts) as one-line items with a menu, a growth direction, and faded section backgrounds on every `/sui` page.

**Architecture:** Two Core pieces any module can use (section backgrounds in the options body; shareable options, menu items and the menu in the options kit, driven by SaftUI-only option fields), and the action bars' side: All bars' values in `actionbars.all`, each bar's values where they are today plus a table of own flags, one function that resolves a bar's effective config for every reader, and a one-time conversion that keeps every existing bar looking as it does. The page is then rebuilt on those pieces.

**Tech Stack:** Lua 5.1, WoW API (Forever 16001 and retail 120000), AceDB-3.0 profiles, AceConfig option tables drawn by SaftUI's own options window, LibActionButton-1.0 (bundled, unchanged), tests on stubs with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-13-saftui-actionbars-shared-settings-design.md`. Its last two sections ("Settled after the builder check", "Chosen after the icon and background mockups") override anything earlier they contradict. The page's look is `.superpowers/brainstorm/46409-1794604463/content/actionbars-shared-v6.html`, part 1, switch S2.

## How the tasks are cut

The six tasks are the ones asked for, in that order, with two moves:

- **Task 2 re-routes today's per-bar page through the new storage.** "No page change yet" holds for what the user sees, but the old General and Text tabs write `self.config[id]` directly; once a bar follows All bars those writes would no longer show. So Task 2 points their `get`/`set` at the new setters (a change on a bar makes it the bar's own), and the countdown Reset at `AB:ResetCountdown`. Task 3 adds "First button" to that interim General tab; Task 6 replaces the whole page.
- **The item's mark and diff aggregation is model logic in Task 4; the item widget is Task 5.** `OM.ShareState` handles an item (a Show box plus a menu of settings) as pure data in Task 4, tested on option tables; Task 5 draws the item row and its menu and reuses Task 4's marks for it.

Order: 1 → 4 → 5 (Core), 2 → 3 (Action Bars) can run beside them; 6 needs all five.

## Global Constraints

- Nothing under any `Libraries/` folder may change (`SaftUI-Core/Libraries`, `SaftUI-Unitframes/Libraries/oUF`, `SaftUI-ActionBars/Libraries`).
- Core's options kit must not know about action bars. No Core file names a bar, `AB`, `actionbars` or "All bars"; the action bars hand Core every name and text through the option fields.
- The bars are secure frames: no layout in combat; every change goes through the existing deferring path (`AB:UpdateBar`, `AB:UpdateConfig`, `st:SafeReposition`). `.agents/taint.md` applies.
- The game calls `OnEnter`/`OnLeave` with a second argument (`motion`); never bind a function with an optional second parameter straight as a script, and fire hover scripts in tests with `true` as the game does (a bug of exactly this kind was fixed in b4e218c).
- Icons are Lucide's, from `st.icons` (`SaftUI-Core/constants.lua`); a new one is made with `tools/lucide-to-tga.cjs`. This work needs none new: `st.icons.diff`, `st.icons.rotateCcw`, `st.icons.ellipsisVertical` exist. An icon texture is drawn at the size the mockup's SVG is (the TGA is Lucide's whole 24 grid).
- New SaftUI-only option fields go in `SAFTUI_FIELDS` (`tests/lib/options_walk.lua`) and `.agents/edit-mode.md`; a new SaftUI-only type goes in `SAFTUI_TYPES`.
- Both looks: under the Blizzard theme the new kit pieces must draw sensibly (each task says how per piece), and section backgrounds are Thick and Thin only.
- Both clients (Forever 16001 and retail 120000).
- Commits: lowercase `module: imperative summary` (`core: …`, `actionbars: …`, `docs: …`); stage by explicit path; never `git add -A`. End each with the session's `Co-Authored-By` line.
- Keep the user's account and character names out of everything.
- Each task updates the docs its change makes wrong (`.agents/*.md`, file header comments, `README.md`) and hands back an in-game checklist. New Core files go in `.agents/edit-mode.md`'s `covers:`; new ActionBars files in whichever doc covers their glob (add them where none does).
- Each task ends green on `tests/run`. Run single files while working (`tests/run tests/<area>/<file>`) and the whole suite as `tests/run -j2` before the task's last commit. Then run the `agents-doc-parity-check` and `readme-freshness-check` skills (AGENTS.md).
- Keep each file's line endings (these files are LF). An assertion an earlier test made is changed only where this work changes the behaviour it pins, and the report lists each one with why.

## Review Focus

1. **A profile made before the update, with bars set every which way** (different sizes, a bar with Buttons below Buttons per row, texts moved or hidden on some bars, cooldown fonts set on one bar, the pet bar's unused stack count set): after the first login every bar shows exactly what it did, and only the settings where a bar differs from Bar 1 are its own. Task 2.
2. **The pet and stance bars' 10 buttons and missing texts:** All bars' Buttons is 12 and they show 10; Apply to: All from a 12-button bar leaves them at 10; Stack count and Macro name are never owned by them, never listed in their diff lines, never offered in a check list. Tasks 2 and 6.
3. **A profile switch, copy or reset mid-session, in combat too:** the new profile is converted at once (table writes only) and the bars are laid out from it when combat ends; copying from a profile never converted converts it; a reset gives exactly the shipped own flags. Task 2.
4. **The menu open while the page draws again or a dropdown opens inside it:** a redraw (a set in the menu, Blizzard's cooldown setting changed elsewhere, a profile switch) leaves it on its item, re-anchored and showing the new values, or closes it when the item is gone; a dropdown's list or a confirm opens above it, a click on the list's catcher closes only the list, Esc closes the list first and then the menu. Task 5.
5. **The hover line as the mouse moves from label to control, onto the line's links, or into the Multiple list:** it stays up the whole way and goes when the mouse leaves the row, and a plain row never moves. Task 4.

## Rulings on the spec

Points the spec leaves open or the code forces; the tasks assume these.

1. **Blizzard keeps today's layout.** Section backgrounds come with their metrics (rows 38 tall, 14 side padding, no column gap); under Blizzard the body lays out exactly as today (34, 0, 40) with no panels. Under Blizzard a marked row's content moves 6 right to make room for the mark inside the cell (the body's scroll frame clips left of the content).
2. **No line between sections any more.** Under Thick and Thin the panels part the sections; Blizzard never drew the line. The space the layout keeps for it stays.
3. **A section holding a fill row gets no panel or padding** (the bags' Categories tab, the nameplate pages' centred line). Every other row (position blocks, descriptions, bare rows, search results, lines of buttons) sits on its section's panel, inside the padding.
4. **Every options body draws panels under Thick and Thin:** the window, the small dialog, the bags' Categories editor and the new menu.
5. **Owning is differing.** A bar that owns a setting counts as differing on All bars (its diff line and the Multiple list there), even when its value equals All bars'. That is what makes ruling 7 of the spec ("two diff icons on a new profile") true.
6. **An item's diff icon** shows when its Show or any setting in its menu differs; its tooltip lists each differing bar with the names of those settings ("Bar 3: Show, Size"). Its hover line, as its own mark's Reset and Apply, acts on Show only (spec ruling 1). The cooldown numbers item has no shareable Show, so it is marked or diff-iconed by its menu alone and never has a hover line.
7. **The diff icon is `st.icons.diff`**, not three textures: the icon exists (e2094e5).
8. **Theme and Background stay at `actionbars.theme` and `.background`**, read by every bar as today; they are not moved into `actionbars.all`.
9. **The Multiple list starts with nothing checked.** Apply with none checked closes it and changes nothing. No confirm on Reset or Apply to: All; their tooltips say what they do.
10. **Search** finds a setting in a menu; its result opens the page with the item in view and its label blue, and opens the item's menu.
11. **A text's position option in its menu is named Position** (the menu's title names the text), so diff lines read "Bar 3: Size, Position" as the spec's example does.
12. **"This bar" holds Enable only.** The mockup also drew Position there; the spec puts Position last, as on every page.
13. **Growth doesn't change the flyout direction**, which stays `perrow`'s (read from the effective config).
14. **The menu doesn't scroll** (no scroll frame), so nothing opened from it is cut off; it is as tall as its contents.
15. **The conversion marker is `actionbars.version = 1`** (no default).

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Config/optionsbody.lua` | Two metric sets, panels, hairlines, cells inside the padding; hooks for marks and the menu item's row | 1, 4, 5 |
| `SaftUI-Core/Config/optionsmodel.lua` | The `share` field: `OM.ShareState`, `OM.ShareCall`, `OM.ShareTargets`, `OM.MenuRoot`; a position section's `shareRow`; the `item` type; search into menus | 4, 5 |
| `SaftUI-Core/Config/optionsshare.lua` (new, after `optionsbody.lua`) | Drawing marks, the diff icon and tooltip, the hover line and its watcher, a section title's marks | 4 |
| `SaftUI-Core/Config/optionslist.lua` | `W.OpenApplyList`: the check list with an Apply button | 4 |
| `SaftUI-Core/Config/optionsitem.lua` (new, before `optionsposition.lua`) | The `item` widget: Show box, dots | 5 |
| `SaftUI-Core/Config/optionsmenu.lua` (new, after `optionssmalldialog.lua`) | The menu: `OW:OpenMenu`, following its item, closing | 5 |
| `SaftUI-Core/Config/optionswindow.lua`, `optionssmalldialog.lua`, `optionswidgets.lua`, `load.xml` | Wiring the menu into renders, Esc, page changes; `widget.body`; load order | 5 |
| `SaftUI-ActionBars/shared.lua` (new, after `init.lua`) | All bars and own flags: effective config, setters, Apply to, conversion | 2, 3 |
| `SaftUI-ActionBars/config.lua`, `init.lua`, `bars.lua`, `skin.lua`, `options.lua` | Defaults; conversion hooks; readers on the effective config; growth | 2, 3, 6 |
| `SaftUI-ActionBars/textoptions.lua` (new, after `extras.lua`) | The four text items and their menus | 6 |
| `tests/lib/options_walk.lua`, `tests/lib/shell.lua` | `SAFTUI_FIELDS`, `SAFTUI_TYPES`, walking menus; the new files in the loaders' lists | 4, 5 |

---

### Task 1: Core: section backgrounds with a column divider and hairlines

**Files:**
- Modify: `SaftUI-Core/Config/optionsbody.lua` (metrics, panels, hairlines, `Body:SlotRect`, `Body:CellRect`, `DrawSections`, `RowCell`, `PlaceRow`, header comment)
- Test: `tests/core/options_body_test.lua` (new cases); update geometry assertions under Thick and Thin in `tests/core/options_rerender_test.lua` ("every cell of the body starts and ends on whole pixels"), `tests/core/options_open_test.lua` (its last case, the page of every row type) and whichever others the suite shows failing on cell geometry under Thick or Thin only (expected: `tests/core/options_small_dialog_test.lua`, `tests/bags/categories_editor_test.lua`, `tests/unitframes/config_test.lua`). No assertion under Blizzard changes.
- Docs: `.agents/edit-mode.md` (the Body bullet: rows, columns, dividers, the line between sections, panels; the dialog), `.agents/testing.md` (`options_body_test.lua`'s line), `README.md` (line 21, "thin lines between the columns"), `optionsbody.lua`'s header.

**Interfaces:**
- Produces:
  - `OB.FLAT = { rowHeight = 34, pad = 0, columnGap = 40, quarterGap = 24, panels = false }` (today's; Blizzard).
  - `OB.PANELED = { rowHeight = 38, pad = 14, columnGap = 0, quarterGap = 0, panels = true }` (Thick and Thin).
  - `OB.PANEL_FILL = { 0, 0, 0, 0.28 }`, `OB.HAIRLINE = { 1, 1, 1, 0.07 }`.
  - `body.metrics`: chosen at `OB.New` and again at the start of every `Draw`/`DrawResults` (`W.BlizzardLook() and OB.FLAT or OB.PANELED`); `body.columnWidth = floor((width - metrics.columnGap) / 2)` and `body.quarterWidth = floor((columnWidth - metrics.quarterGap) / 2)` follow it.
  - `Body:SlotRect(col, quarter) -> x, width`: today's `CellRect` formula with the metrics' gaps (second column and second quarter flush right).
  - `Body:CellRect(col, quarter) -> x, width`: the slot inset by `metrics.pad` on each side; `'full'` too. Under `OB.FLAT` both equal today's `CellRect`.
  - `OB.LayoutSections` entries gain `rowsHeight` (the height `OB.LayoutRows` gave its rows). Nothing else in `LayoutSections`, `LayoutRows` or `Dividers` changes.
  - `OB.Hairlines(placed) -> { y, ... }`: every distinct line top in `placed` but the first, ascending.
  - `body.pools.panel`, `body.pools.hairline`: textures in the content (panels in `BACKGROUND`, hairlines and paneled dividers in `BORDER`), so tests read `.used`.
  - `OB.ROW_HEIGHT` (34), `OB.SCROLL_STEP` and `OB.TOP` keep their values: other files read them.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_body_test.lua` (after the existing body cases; `draw_body` and `point_x` are the file's own). Set the theme as the file's other cases do (`st.config.profile.theme.name`), and put it back.

```lua
test('under Thick and Thin a section sits on a faded panel, rows 38 tall, 14 in from their slots', function()
	local body, by = draw_body(774, {
		{ 'a', 'range', 'A' }, { 'b', 'range', 'B' },
		{ 'c', 'toggle', 'C', 'small' }, { 'd', 'toggle', 'D', 'small' }, { 'e', 'toggle', 'E', 'small' }, { 'f', 'toggle', 'F', 'small' },
	})
	eq(point_x(by.a.frame) .. '+' .. by.a.frame:GetWidth(), '14+359', 'a half, inside its padding')
	eq(point_x(by.b.frame) .. '+' .. by.b.frame:GetWidth(), '401+359', 'the second half')
	eq(table.concat({ point_x(by.c.frame), point_x(by.d.frame), point_x(by.e.frame), point_x(by.f.frame) }, ','), '14,208,401,595', 'quarters')
	eq(by.c.frame:GetWidth(), 165, 'a quarter inside its padding')
	eq(by.a.height, 38, 'rows are 38 tall')
	local panels = body.pools.panel.used
	eq(#panels, 1, 'one panel')
	-- the panel: x 0, y the rows' top, 774 x 76, OB.PANEL_FILL
	-- hairlines (height 1): one, at the second line's top, 774 wide, OB.HAIRLINE
	-- dividers (width 1, OB.HAIRLINE): x 387 on both lines, 193 and 580 on the second; each 38 tall
	-- no texture from pools.line is shown (no line between sections, none for dividers)
end)

test('under Blizzard the body is laid out as before, with no panel or hairline', function()
	-- theme 'blizzard': a at 0+367, b at 407+367, quarters 0,196,407,603 (171 wide), rows 34,
	-- #body.pools.panel.used == 0, #body.pools.hairline.used == 0, dividers from pools.line in OB.LINE
end)

test('panels, hairlines and dividers sit on whole pixels at any width', function()
	-- for widths 774, 520, 540 and 525, Thick: every used panel, hairline and divider's
	-- TOPLEFT offsets, width and height are whole numbers; SlotRect(2) and SlotRect(1, 2)
	-- end flush with the body and the column; CellRect is SlotRect inset by 14 each side
end)

test('position blocks, descriptions, bare rows, aligned buttons and results sit inside the padding; a fill row does not', function()
	-- Thick, 774: a position row at x 14; a description 14 in and 746 wide; a bare row (W.Define)
	-- given SetWidth(746) at x 14; a 'right' group's last button ending at 760; DrawResults
	-- halves at 14 and 401 on a panel; a fill type (W.Define bare + fill) at x 0, 774 wide,
	-- and its section has no panel
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_body_test.lua`
Expected: FAIL — `body.pools.panel` is nil and cells sit at 0 / 407.

- [ ] **Step 3: Implement in `SaftUI-Core/Config/optionsbody.lua`**

Add the metric tables, `SlotRect`, the new `CellRect`, `OB.Hairlines`, `rowsHeight` and the two pools as the Interfaces say. In `DrawSections`, under `metrics.panels`: one panel per laid section with rows (none for a section with a fill cell), hairlines at `rowsY + y`, dividers from the hairline pool; never the line between sections. A divider's x keeps today's formula on the slots, not the padded cells: `floor(width / 2)` between halves, `floor(SlotRect(col) + columnWidth / 2)` between quarters (with no gap these land on the boundaries: 387, 193, 580 at 774). Rows: `metrics.rowHeight` wherever the code uses `ROW_HEIGHT` for a cell (the default height, the description and multiselect minimum, the tall row's label offset in `PlaceRow`); a fill cell placed with `0, self.width`; a bare widget given the cell's width; a line of aligned buttons laid with `OB.ButtonRow(widths, align, self.width - 2 * pad)` and shifted by `pad`.

- [ ] **Step 4: Run the file, then the suite**

Run: `tests/run tests/core/options_body_test.lua`, then `tests/run -j2`.
Expected: the new cases PASS. The suite fails only on assertions about cell geometry under Thick or Thin; update each to the paneled numbers, its message saying so, and list them in the report.

- [ ] **Step 5: Docs** as listed under Files. Describe: the two metric sets; panels (black at 28%), hairlines and dividers (white at 7%); what sits on a panel and what doesn't (ruling 3); no line between sections (ruling 2); Blizzard unchanged.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionsbody.lua tests/core/options_body_test.lua tests/core/options_rerender_test.lua tests/core/options_open_test.lua <each other test changed> .agents/edit-mode.md .agents/testing.md README.md
git commit -m "core: draw options sections on faded panels with hairlines between rows"
```

**In-game checks:** under Thick and Thin every `/sui` page's sections sit on a darker panel with a faint divider between columns and faint lines between rows, all crisp (not blurred, not missing) at your UI scale; the small dialog (Unitframes → Copy from) too; the bags' Categories tab has no panel behind it, its editor's sections do; under Blizzard every page looks as before.

---

### Task 2: Action bars: All bars, own flags, the effective config and the conversion

**Files:**
- Create: `SaftUI-ActionBars/shared.lua`, listed in `SaftUI-ActionBars/SaftUI-ActionBars.toc` right after `init.lua`.
- Modify: `SaftUI-ActionBars/config.lua` (defaults: `all`, each bar's `own`; header), `init.lua` (conversion in `OnEnable` and `UpdateConfig`; file list in the header), `bars.lua` (readers; `AB:UpdateBars`; the fade alpha), `skin.lua` (`GetButtonConfig`, `StyleBar`), `options.lua` (interim: `get`/`set` through the setters, `UpdateMoverLabel`, Faded opacity's `hidden`, the countdown `get` and Reset).
- Test: create `tests/actionbars/shared_settings_test.lua`; modify `tests/actionbars/cooldown_numbers_test.lua` (load `shared.lua`; convert in `fresh` and `switch_profile`; read and write through the API), `tests/actionbars/theme_test.lua` (load `shared.lua`), `tests/core/options_frames_pages_test.lua` (load `shared.lua` before `options.lua`).
- Docs: `AGENTS.md` (the ActionBars row: `shared.lua`), `.agents/architecture.md` (`covers:` gains `SaftUI-ActionBars/shared.lua`; Config, defaults and profiles: a bullet on a module that converts its profile once, with the action bars' marker, beside the bags' categories), `.agents/taint.md` only if a covered file's rule changes (none should), `.agents/testing.md` (`tests/actionbars/` row), the headers of `config.lua`, `init.lua`, `bars.lua`, `skin.lua`, `shared.lua`.

**Interfaces:**
- Produces (all in `shared.lua` unless said):
  - Defaults: `st.defaults.actionbars.all = { buttons = 12, perrow = 12, size = 45, spacing = 3, visibility = 'always', fade_alpha = 0.3, text = { hotkey, count, macro, countdown } }`, the text tables made by `config.lua`'s own `Text(...)` and `Countdown()` exactly as bar 1's. Every bar keeps today's defaults (the conversion reads them) and gains `own`: `{}`, but `{ perrow = true }` on bars 4–8 and `{ size = true }` on the pet and stance bars. `actionbars.version` has no default.
  - `AB.CONFIG_VERSION = 1`; `AB.TEXT_KINDS = { 'hotkey', 'count', 'macro', 'countdown' }`; `AB.POSITION_PARTS = { 'point', 'rel_point', 'x_off', 'y_off' }`.
  - `AB.SHARED_KEYS`, in this order: `buttons, perrow, size, spacing, visibility, fade_alpha`, then for `hotkey`, `count`, `macro`: `<kind>.show, <kind>.font, <kind>.size, <kind>.outline, <kind>.position`, then `countdown.font, countdown.size, countdown.outline, countdown.position`. A key is one setting; `<kind>.position` is the four parts at once.
  - `AB:HasSetting(id, key) -> boolean`: `id` a bar id or `'all'`; false for a text key whose kind isn't in `AB.barTypes[id].texts` (the pet and stance bars' count and macro). Reads `barTypes` at call time.
  - `AB:IsOwn(id, key) -> boolean`: `self.config[id].own[key] == true`; false for `'all'`.
  - `AB:GetBarConfig(id) -> table`: built per call, never cached. `id` a bar id or `'all'`. `{ enable, position, buttons, perrow, size, spacing, visibility, fade_alpha, text = { hotkey = { show, font, size, outline, point, rel_point, x_off, y_off }, count = {...}, macro = {...}, countdown = { font, size, outline, point, rel_point, x_off, y_off } } }`; each value the bar's own where it owns the key, else All bars'. A key the bar doesn't have (`HasSetting` false) reads the bar's stored value. `enable` and `position` are the bar's (`nil` for `'all'`); `position` is the profile's table itself (edit mode writes it).
  - `AB:GetSetting(id, key, part) -> value`: one value of `GetBarConfig(id)` (`part` for a position key).
  - `AB:SetSetting(id, key, value, part)`: on `'all'`, writes All bars' value. On a bar, makes the key the bar's own (flag `true`) and writes the bar's value; when a bar first owns a `<kind>.position`, All bars' four parts are copied into the bar before the part is written. Applies nothing.
  - `AB:ResetSetting(id, key)`: the bar follows All bars again: its flag set to `false` (never nil, so a flag that ships `true` stays cleared). Its stored value stays.
  - `AB:ApplyToAll(id, key)`: from a bar, All bars takes the bar's effective value (all four parts for a position), then every bar's flag is `false`; from `'all'`, every bar's flag is `false`.
  - `AB:ApplyTo(id, key, targets)`: `targets` a list of bar ids; a target that doesn't `HasSetting` is skipped. From a bar: each target owns a copy of the bar's value, or follows (flag `false`) when that value equals All bars'. From `'all'`: each target follows.
  - `AB:OwnersOf(key) -> { id, ... }`: the bars in `AB.BAR_IDS` order that have the key and own it.
  - `AB:ResetCountdown(id)`: on `'all'`, All bars' countdown font, size and outline unset (nil) and its place back to the default's (`st.defaults.actionbars.all.text.countdown`); on a bar, the same values given to the bar, each own only where All bars' value differs from that default, else followed (spec ruling 4).
  - `AB:ConvertProfile()`: once per profile (see Step 3).
  - `AB:UpdateBars()` (`bars.lua`): `AB:UpdateBar(id)` for each built bar in `BAR_IDS` order.
  - `AB:GetButtonConfig(id, i, config)` (`skin.lua`): `config` is the bar's resolved table, built when nil.
- Every reader reads `AB:GetBarConfig(id)`: `GetVisibilityDriver`, `UpdateFade`, `GetNumButtons`, `LayoutBar` (`bars.lua`); `GetButtonConfig`, `StyleBar` (`skin.lua`, which passes the resolved table to `StyleButton`, whose signature stays); `UpdateMoverLabel`, Faded opacity's `hidden`, the countdown rows' `get` (`options.lua`). `WantedBindings` keeps reading `enable` (never shared) and `GetNumButtons`. `extras.lua` doesn't change. The fader's `OnUpdate` builds no table: `UpdateFade` keeps each fading bar's target alpha (`FadeAlpha` of its resolved config) and refreshes it every time it runs.

- [ ] **Step 1: Write the failing tests** in `tests/actionbars/shared_settings_test.lua`. Its world is `cooldown_numbers_test.lua`'s (copy `fresh`, `button`, `bar`, `dump` and its FILES list with `shared.lua` after `init.lua`), with `fresh(saved, convert)` running `AB:ConvertProfile()` unless `convert == false`. A helper `before(id)` reads, before converting, what a bar shows today: for each key the bar has, the stored-or-default value under `AB.config[id]` (the four parts for a position), with `buttons` and `perrow` clamped to 1..n (n = 10 on pet and stance, else 12); `after(id)` reads the same from `AB:GetBarConfig(id)` with the same clamp.

```lua
test('a new profile: every bar follows All bars but the shipped own settings', function()
	fresh()
	for _, id in ipairs(AB.BAR_IDS) do
		for _, key in ipairs(AB.SHARED_KEYS) do
			local shipped = (key == 'perrow' and id:match('^bar[4-8]$')) or (key == 'size' and (id == 'pet' or id == 'stance'))
			eq(AB:IsOwn(id, key), shipped and true or false, id .. ' ' .. key)
		end
	end
	eq(AB.config.version, 1, 'the marker, inside actionbars')
	eq(table.concat(AB:OwnersOf('perrow'), ','), 'bar4,bar5,bar6,bar7,bar8', 'Buttons per row is owned by bars 4-8')
	eq(table.concat(AB:OwnersOf('size'), ','), 'pet,stance', 'Button size by the pet and stance bars')
end)

test('a profile saved before the update looks exactly as it did, and owns only where it differs from Bar 1', function()
	local saved = {
		bar1 = { size = 36, spacing = 2, text = { hotkey = { size = 12, point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 2 }, countdown = { size = 14 } } },
		bar2 = { perrow = 6, visibility = 'mouseover', fade_alpha = 0.5 },
		bar3 = { size = 36, spacing = 2, text = { hotkey = { size = 12, point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 2 }, countdown = { size = 14 } } },
		bar4 = { buttons = 6, perrow = 12 },
		bar6 = { enable = true, text = { macro = { show = false } } },
		pet = { size = 24, text = { count = { size = 20 } } },
		stance = { buttons = 12, perrow = 3 },
	}
	fresh(saved, false)
	local was = {}
	for _, id in ipairs(AB.BAR_IDS) do was[id] = before(id) end
	AB:ConvertProfile()
	for _, id in ipairs(AB.BAR_IDS) do eq(dump(after(id)), dump(was[id]), id .. ': shows what it did') end
	eq(table.concat(AB:OwnersOf('size'), ','), 'bar2,bar4,bar5,bar6,bar7,bar8,pet,stance',
		'Bar 1 is 36: every bar left at 45, and the pet (24) and stance (30) bars, own their size; Bar 3 follows')
	eq(AB:IsOwn('bar4', 'perrow'), false, '12 per row on 6 buttons shows what All bars\' 12 does there: the shipped flag is cleared')
	eq(AB:IsOwn('bar3', 'hotkey.position') or AB:IsOwn('bar3', 'countdown.size'), false, 'Bar 3, set like Bar 1, owns nothing')
	eq(AB:IsOwn('stance', 'buttons'), false, '12 saved on a 10-button bar shows 10, as All bars does there')
	eq(AB:IsOwn('pet', 'count.size'), false, "the pet bar's unused stack count is never owned")
end)

test('the conversion runs once per profile, and again for one switched to, copied or reset', function()
	-- ConvertProfile twice: the profile's dump is unchanged the second time;
	-- a bar's own value changed after it is kept by a third call (the marker);
	-- st.config.profile replaced by a table without the marker, bound again, AB:UpdateConfig():
	-- converted; replaced by {} (a reset): exactly the shipped flags
end)

test('a profile switched to in combat is converted at once, and the bars wait for the end of combat', function()
	-- AB.built = true, bar2 a plain bar of buttons (the file's bar()); stub.in_combat = true;
	-- switch to { actionbars = { bar2 = { size = 30 } } } and AB:UpdateConfig():
	-- AB.config.version == 1 and AB:IsOwn('bar2', 'size') at once; bar2's buttons still 45 wide;
	-- stub.in_combat = false; stub.fire_event('PLAYER_REGEN_ENABLED'): 30 wide; #take_errors() == 0
end)

test('setting, resetting and applying', function()
	-- SetSetting('all', 'size', 36): GetBarConfig('bar3').size 36, pet 30 (owns it)
	-- SetSetting('bar3', 'size', 40): IsOwn('bar3','size'); ResetSetting: follows (36), and its own 40 is still stored;
	-- ResetSetting('pet', 'size'): profile.actionbars.pet.own.size == false (not nil), pet size 36
	-- SetSetting('bar3', 'hotkey.position', 'TOPLEFT', 'point') on a bar whose stored hotkey x_off is 7 while All bars' is -3:
	--   x_off reads -3 (All bars' parts copied in first), point TOPLEFT
	-- ApplyToAll('bar5', 'perrow') with bar5's 1: All bars' perrow 1, OwnersOf('perrow') empty
	-- ApplyTo('bar3', 'size', { 'bar5', 'pet' }) with bar3 at 40, All bars 36: both own 40;
	--   with bar3's value equal to All bars': both follow
	-- ApplyTo('all', 'perrow', { 'bar4' }): bar4 follows, bar5 still owns
	-- ApplyTo('bar1', 'count.size', { 'pet' }): the pet bar is unchanged
end)

test("the pet and stance bars show at most 10, whatever All bars' Buttons says", function()
	-- AB.bars.pet a bar of 10 buttons: All bars' buttons 12, pet follows: GetNumButtons('pet') == 10;
	-- ApplyToAll('bar1', 'buttons') with 12: still 10; HasSetting('pet', 'macro.show') false, HasSetting('pet', 'hotkey.size') true
end)

test('every reader takes the effective config', function()
	-- bar4 owns perrow 1: GetButtonConfig('bar4', 1).flyoutDirection == 'LEFT'; ResetSetting: 'UP'
	-- bar2 follows All bars' size 36 after SetSetting('all', 'size', 36) and UpdateBar('bar2'): its buttons are 36 wide
	-- SetSetting('bar2', 'visibility', 'mouseover'), SetSetting('all', 'fade_alpha', 0.5), UpdateBar: bar2's alpha 0.5
	-- SetSetting('all', 'hotkey.size', 14): bar1's GetButtonConfig text.hotkey.font.size == 14
end)

test('the countdown Reset: on All bars the shared values, on a bar its own only where All bars differs', function()
	-- SetSetting('all', 'countdown.size', 14); SetSetting('bar3', 'countdown.font', 'Friz Quadrata TT')
	-- ResetCountdown('bar3'): IsOwn('bar3','countdown.size') true and its size nil; IsOwn(...,'countdown.font') false;
	--   IsOwn(...,'countdown.position') false; GetBarConfig('bar3').text.countdown.font nil
	-- ResetCountdown('all'): All bars' countdown size nil; bar3 keeps its own (nil) size
end)
```

- [ ] **Step 2: Run to see them fail**

Run: `tests/run tests/actionbars/shared_settings_test.lua`
Expected: FAIL — `shared.lua` doesn't exist.

- [ ] **Step 3: Implement**

Defaults in `config.lua`; the Interfaces' functions in `shared.lua`. `AB:ConvertProfile()`:
1. Return if `self.config.version` is set.
2. All bars takes Bar 1's values: for every key, the value read through `self.config.bar1` (stored or default) is written into `self.config.all` (the four parts for a position).
3. Each bar, Bar 1 included: for every key it has, `own[key]` is written `true` where what the bar shows differs from what it would show following All bars, else `false`. Compare `buttons` and `perrow` each clamped to 1..n (n = the bar's button count, 10 on pet and stance, 12 on the rest, from a table in `shared.lua`, not the built bars), the rest as stored (`nil` equals `nil`), a position by its four parts.
4. `self.config.version = AB.CONFIG_VERSION`.

Table writes only, safe in combat. Call it in `AB:OnEnable` right after `st:BindModuleConfig` (before the build, deferred or not), and first thing in `AB:UpdateConfig`, before its `built` check and before `QueueAfterCombat`.

Then the readers (Interfaces), `AB:UpdateBars`, and the interim page in `options.lua`: each bar's General, Visibility and Text options `get` with `AB:GetSetting(id, key[, part])` and `set` with `AB:SetSetting(...)` then `AB:UpdateBar(id)` (the option key is the setting key, `<kind>.<option key>` in a text group, `<kind>.position` for its Position); the countdown Reset's `func` calls `AB:ResetCountdown(id)` and `AB:UpdateBar(id)`.

- [ ] **Step 4: Update the existing action bar tests** so each assertion keeps its meaning: in `cooldown_numbers_test.lua`, `shared.lua` after `init.lua` in FILES, `AB:ConvertProfile()` at the end of `fresh` and in `switch_profile` after binding, `AB.config.bar1.size = n` → `AB:SetSetting('bar1', 'size', n)`, reads of `AB.config[id].text.countdown` → `AB:GetBarConfig(id).text.countdown`; `theme_test.lua` and `options_frames_pages_test.lua` load `shared.lua`.

- [ ] **Step 5: Run**

Run: `tests/run tests/actionbars`, then `tests/run -j2`.
Expected: PASS.

- [ ] **Step 6: Docs** as listed under Files.

- [ ] **Step 7: Commit**

```bash
git add SaftUI-ActionBars/shared.lua SaftUI-ActionBars/SaftUI-ActionBars.toc SaftUI-ActionBars/config.lua SaftUI-ActionBars/init.lua SaftUI-ActionBars/bars.lua SaftUI-ActionBars/skin.lua SaftUI-ActionBars/options.lua tests/actionbars/shared_settings_test.lua tests/actionbars/cooldown_numbers_test.lua tests/actionbars/theme_test.lua tests/core/options_frames_pages_test.lua AGENTS.md .agents/architecture.md .agents/testing.md
git commit -m "actionbars: share settings through All bars and per-bar own flags"
```

**In-game checks:** log in on a profile you've had a while: every bar, the pet and stance bars too, looks and behaves exactly as before (size, rows, spacing, texts, cooldown numbers, fade); `/sui` → Action Bars, change a bar's size: only that bar changes; switch to another profile and back (out of combat, then once in combat): each looks as it did, the in-combat one once combat ends; a new profile looks like SaftUI's default layout.

---

### Task 3: Action bars: growth direction ("First button")

**Files:**
- Modify: `SaftUI-ActionBars/config.lua` (`growth = 'TOPLEFT'` in `Bar()` and in `all`; header), `shared.lua` (`'growth'` in `AB.SHARED_KEYS` after `'spacing'`; `GetBarConfig` gains `growth`), `bars.lua` (`AB.ButtonPoint`, `LayoutBar`; header's Layout paragraph), `options.lua` (interim: First button in each bar's General, after Spacing).
- Test: create `tests/actionbars/layout_test.lua`.
- Docs: `README.md` (line 35: which corner the first button sits in), `.agents/testing.md`.

**Interfaces:**
- Consumes: `AB:GetBarConfig`, `AB:GetSetting`, `AB:SetSetting`, `AB:ConvertProfile`, `AB.SHARED_KEYS` (Task 2).
- Produces:
  - Setting `growth`: `'TOPLEFT'` (default, today's layout), `'TOPRIGHT'`, `'BOTTOMLEFT'`, `'BOTTOMRIGHT'`; anything else reads as `'TOPLEFT'`.
  - `AB.ButtonPoint(i, perRow, size, spacing, growth) -> point, x, y`: button `i`'s anchor: `point` is the growth corner, of the button and of the bar alike; column `(i - 1) % perRow`, row `floor((i - 1) / perRow)`; `x` is `column * (size + spacing)`, negated for a RIGHT corner; `y` is `row * (size + spacing)`, negated for a TOP corner.
  - `AB.GROWTH_VALUES = { TOPLEFT = 'Top left', TOPRIGHT = 'Top right', BOTTOMLEFT = 'Bottom left', BOTTOMRIGHT = 'Bottom right' }` and `AB.GROWTH_ORDER` in that order (`options.lua`; Task 6 reads them).

- [ ] **Step 1: Write the failing tests** (world: Task 2's test file's `fresh`, `bar` and `button`, copied)

```lua
test('ButtonPoint: rows fill across from the first corner, the next row away from it', function()
	local function p(...) return table.concat({ AB.ButtonPoint(...) }, ',') end
	eq(p(1, 12, 45, 3, 'TOPLEFT'), 'TOPLEFT,0,0', 'today')
	eq(p(2, 12, 45, 3, 'TOPLEFT'), 'TOPLEFT,48,0', 'then right')
	eq(p(2, 12, 45, 3, 'TOPRIGHT'), 'TOPRIGHT,-48,0', 'a row from the right runs right to left')
	eq(p(2, 1, 45, 3, 'BOTTOMLEFT'), 'BOTTOMLEFT,0,48', 'a column from the bottom runs upward')
	eq(p(5, 4, 30, 2, 'BOTTOMRIGHT'), 'BOTTOMRIGHT,0,32', 'the second row goes away from the corner')
	eq(p(7, 6, 45, 3, 'TOPRIGHT'), 'TOPRIGHT,0,-48', 'down from a top corner')
	eq(p(1, 12, 45, 3, 'MIDDLE'), 'TOPLEFT,0,0', 'an unknown corner is top left')
end)

test("the bar's size and place don't change with it, and every offset is a whole pixel", function()
	-- bar1 of 12 plain buttons, perrow 6 owned: for each corner (SetSetting('bar1', 'growth', corner), UpdateBar):
	-- bar1's size is the same (285 x 93 at 45/3, or as EvenIfCentred makes it), its point the same;
	-- button 1's point is (corner, bar1, corner, 0, 0); button 7's offsets are whole numbers
end)

test('a profile from before has every bar follow All bars at top left', function()
	-- fresh({ bar2 = { size = 30 } }): GetBarConfig(id).growth == 'TOPLEFT' and not IsOwn(id, 'growth') for every bar
end)

test("First button on a bar's General writes the setting as the bar's own", function()
	-- AB.built = true; GetBarOptions('bar3', 3).args.general.args.growth: type select, name 'First button',
	-- sorting AB.GROWTH_ORDER, a desc; set → IsOwn('bar3', 'growth') and UpdateBar:bar3
end)
```

- [ ] **Step 2: Run to see them fail**

Run: `tests/run tests/actionbars/layout_test.lua`
Expected: FAIL — `AB.ButtonPoint` is nil.

- [ ] **Step 3: Implement** `AB.ButtonPoint` and use it in `LayoutBar` (`button:SetPoint(point, bar, point, x, y)`); the bar's width and height and `AB:PlaceFrame` call are unchanged. Add `growth` to the defaults and `AB.SHARED_KEYS`, and the interim option.

- [ ] **Step 4: Run** `tests/run tests/actionbars`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-ActionBars/config.lua SaftUI-ActionBars/shared.lua SaftUI-ActionBars/bars.lua SaftUI-ActionBars/options.lua tests/actionbars/layout_test.lua README.md .agents/testing.md
git commit -m "actionbars: add which corner a bar's first button sits in"
```

**In-game checks:** on a bar of two rows, try each First button: the bar's outline in edit mode doesn't move or resize, the buttons fill from that corner, gaps even (no pixel short at the middle of a centred bar); a single row with Top right runs right to left, a column with Bottom left runs upward; keys still press the right buttons (button 1 is the first key); a /reload in combat with a corner set lays out right.

---

### Task 4: Core kit: shareable options, own marks, the hover line, the diff icon, the Apply list

**Files:**
- Modify: `SaftUI-Core/Config/optionsmodel.lua` (the `share` field in the header; `OM.MENU_KEY`, `OM.MenuRoot`, `OM.ShareState`, `OM.ShareCall`, `OM.ShareTargets`; `Feed` gives a position row's section `shareRow`).
- Create: `SaftUI-Core/Config/optionsshare.lua`, in `SaftUI-Core/Config/load.xml` right after `optionsbody.lua`, and first in `options_window_files()` (`tests/lib/shell.lua`; `harness_self_test.lua` checks the list against `load.xml`).
- Modify: `SaftUI-Core/Config/optionsbody.lua` (metrics gain `markX`, `markShift`; `RowCell` sets `cell.body`; `PlaceRow` ends with `OB.PlaceShare(cell)`; the row pool's `OnEnter` also calls `OB.ShareEnter(self)`; `DrawSections` calls `OB.PlaceShareTitle` for a section with `shareRow`).
- Modify: `SaftUI-Core/Config/optionslist.lua` (`W.OpenApplyList`).
- Modify: `tests/lib/options_walk.lua` (`share` in `SAFTUI_FIELDS`; its header).
- Test: create `tests/core/options_share_test.lua` (on `options_window_helpers.lua`'s world, bodies made with `OB.New` as `options_body_test.lua` does); add the Apply list's cases to `tests/core/options_list_test.lua`.
- Docs: `.agents/edit-mode.md` (`covers:` gains `optionsshare.lua`; the SaftUI fields list; a paragraph on shareable options; `W.OpenApplyList`; the body's metrics), `.agents/testing.md`, the headers of `optionsmodel.lua`, `optionsbody.lua`, `optionslist.lua`, `optionsshare.lua`.

**Interfaces:**
- Consumes: `OB.FLAT`, `OB.PANELED`, `body.metrics`, `Body:SlotRect`, `Body:CellRect`, `OB.LayoutSections`' entries (Task 1).
- Produces:
  - **The `share` field** (SaftUI's, on any option; read raw from `row.option.share`, never inherited). Each function is called with the option's AceConfigDialog-style `info`:
    ```
    share = {
      source = 'All bars',          -- string: the page everything follows, for texts
      page = 'Bar 3',               -- string, a member page: this page's name, for texts
      own = function(info) -> bool, -- a member page: the setting is this page's own
      reset = function(info),       -- a member page: follow the source again
      differs = function(info) -> { { name = 'Bar 3', value = '6' }, ... },  -- the source page (may be empty)
      shared = function(info) -> string,                                     -- the source's value, as text
      targets = function(info) -> { { key = 'bar2', label = 'Bar 2' }, ... }, -- who Multiple lists
      applyAll = function(info),
      apply = function(info, keys), -- keys: the picked targets' keys, in targets' order
    }
    ```
    A page with `own` is a member page; one with `differs` is the source page.
  - `OM.MENU_KEY = 'menu'`; `OM.MenuRoot(option) -> { menu = option.menu }`: the tree an item's menu is read from (Task 5's menu draws it; an inner option's `info` comes from it).
  - `OM.ShareState(root, row) -> state | nil`: nil when neither the row's option nor (for `type = 'item'`) any option directly in its `menu.args` has `share`.
    `state = { member = bool, own = bool, marked = bool, offers = bool, source = string, page = string|nil, shared = string|nil, differs = { { name, value }, ... }, item = bool }`:
    - `own`: a member page and `share.own(info)`; `marked`: `own`, or for an item any menu option's `share.own`;
    - `differs`: a plain row's `share.differs(info)` (or `{}`); an item's, grouped by `name` in first-seen order over its own `share.differs` (setting name `'Show'`) then each menu option's (its `name`), each `value` the setting names joined with `', '`;
    - `offers`: `own` on a member page, or a non-empty own `differs` on the source page (an item's Show alone, ruling 6);
    - a `share` function that errors goes to `geterrorhandler()` and counts as false or empty.
  - `OM.ShareCall(root, row, action, ...) -> boolean`: `action` is `'reset'`, `'applyAll'` or `'apply'`; calls `share[action](info, ...)` through the model's `safecall`.
  - `OM.ShareTargets(root, row) -> { { key, label }, ... }` (empty without `targets`).
  - `Feed`: a position row whose option has `share` gives its section `shareRow = row`.
  - Metrics: `OB.PANELED.markX = 5, markShift = 0`; `OB.FLAT.markX = 0, markShift = 6`. The mark is `markX` in from its slot's left (inside the panel's padding under Thick and Thin), and under Blizzard what it marks (label, box, block, title) moves `markShift` right.
  - `OB.OWN_TEXT = { 0.56, 0.85, 1 }` (the mockup's light blue), `OB.DIFF_COLOR = { 0.88, 0.63, 0.25 }` (its orange).
  - `OB.PlaceShare(cell)`, `OB.ShareEnter(frame)`, `OB.PlaceShareTitle(body, entry, title)` (`optionsshare.lua`). The pieces live on the pooled row frame as `frame.share = { mark, diff, line, ownText, reset, all, multiple }` (hidden on every row they don't apply to), a title's in `body.shareTitles`, a list in section order of `{ section, title, hover, parts }` (`hover` a pooled frame over the title line), so tests reach them.
  - `W.OpenApplyList(owner, entries, onApply)` (`optionslist.lua`): the select list's frames as a check list, `entries = { { key, label } }`, every row unchecked to start; a click toggles its mark and keeps the list open, calling nothing; an Apply button under the rows closes the list and calls `onApply(keys)` with the checked keys in `entries`' order, or nothing when none is checked; Esc, a click outside and `W.CloseList` close it calling nothing; `W.ListOwner()` is `owner` while it's open; an empty list doesn't open. The list's other uses never show the button. Under Blizzard the button is the panel button (`W.LookButton`).

**What each piece draws** (`OB.PlaceShare`, rows of type toggle, range, select, input, color and, from Task 5, item; on a position row only the mark, its title carrying the rest):
- **Mark** (`state.marked`): a 2px bar in `Colors().button.blue`, 6 in from the row's top and bottom, at `markX` in the slot; the label in `OB.OWN_TEXT` while the row isn't disabled.
- **Diff icon** (`#state.differs > 0`): `st.icons.diff`, 16x16, `OB.DIFF_COLOR`, 4 after the label's text (its string width, at most the label's width), on a frame that takes the mouse; its tooltip: the row's name (white), then `'<source>: <shared>'` (not for an item), then a line per entry, `'<name>: <value>'`.
- **Hover line** (`state.offers`): the `'small'` font under the label. On a member page: `Own` (its tooltip: the row's name, then `'<source>: <shared>'`), the reset icon (`st.icons.rotateCcw`, 14x14, blue; its tooltip `'Reset'`, then `'<name> follows <source> again. <page>'s own value is dropped.'`), then `· Apply to: All | Multiple`. On the source page: `Apply to: All | Multiple`. The links are frames that take the mouse (Text > Blue), one level over the row frame. Reset runs `OM.ShareCall(root, row, 'reset')`, All `'applyAll'`, Multiple opens `W.OpenApplyList(multiple, OM.ShareTargets(root, row), ...)` whose Apply runs `'apply'`; each then calls the body's `onChanged(true)`. All's and Multiple's tooltips say what they do (wording the implementer's).
- **Showing it:** `OB.ShareEnter(frame)` (from the row frame's wrapped `OnEnter`) shows the line on an offering row: the label anchored from the top so it and the line are centred in the row, the line under it; where the line would end past the body's width it ends at the body's width instead. A watcher (the line's `OnUpdate`) hides it and puts the label back once neither the row frame nor the line is under the mouse (`IsMouseOver`) and the Apply list it opened isn't open. A row that doesn't offer never moves.
- **A section title** (`OB.PlaceShareTitle`, a position section whose `shareRow` has a state): the title in `OB.OWN_TEXT` when marked (and `markShift` right under Blizzard); the diff icon after the title's text; the hover line inline, 8 right of the title's text (or the icon). It shows while the mouse is on the title's line (its `hover` frame), the block's row frame or the line. The block's own row gets the mark like any row (its block moves `markShift` under Blizzard).
- **Under Blizzard:** the same pieces, colors and icons, placed by `OB.FLAT`'s `markX` and `markShift`; Blizzard's Settings panel has nothing to draw them with.

- [ ] **Step 1: Write the failing tests**

In `tests/core/options_share_test.lua` a synthetic store and two roots: a member page (`share` with `own`, `reset`, `shared`, `targets`, `applyAll`, `apply`, `source = 'All bars'`, `page = 'Bar 3'`) and a source page (`differs`, `shared`, `targets`, `applyAll`, `apply`), each recording its calls; a range `spacing` and a select `show` on each, and an item option table (`type = 'item'`, `share` for its Show, `menu = { type = 'group', name = 'Hotkey', args = { size = <range with share>, position = <position with share> } }`) for the model's cases.

```lua
test('ShareState: a member page marks and offers an own row, and leaves a following row plain', function()
	-- spacing own: member, own, marked, offers true; show not own: all false; no share: nil
end)

test('ShareState: the source page offers a row some page owns, with who and what', function()
	-- differs { { name = 'Bar 2', value = '2' }, { name = 'Bar 4', value = '1' } }: offers, differs as given, shared '3'
end)

test("ShareState: an item is marked by its Show or anything in its menu; it offers for its Show alone", function()
	-- member: Show not own, menu size own: marked true, offers false
	-- source: Show differs on Bar 3; size differs on Bar 3 and Bar 5:
	--   differs == { { name = 'Bar 3', value = 'Show, Size' }, { name = 'Bar 5', value = 'Size' } }, offers true
	-- source: Show differs on none, size on Bar 5: diff shown, offers false
end)

test('ShareCall and ShareTargets call the option with its info; an erroring share counts as none', function()
	-- ShareCall(root, row, 'apply', { 'bar2' }): apply got info[#info] == 'spacing' and { 'bar2' }; returns true
	-- own erroring: one error taken, ShareState(...).own false
end)

test("a position option's section carries its row for the title's marks", function()
	-- OM.BuildView: the section titled 'Position' has shareRow == its position row
end)

test('Thick: an own row has the mark in the padding and a light blue label; a following row has neither', function()
	-- body 774, member page: spacing's frame.share.mark shown, 2 wide, (38 - 12) tall, 9 left of the row frame (slot x 5);
	-- its label colored OB.OWN_TEXT; show's mark hidden, its label Text > Normal
end)

test("Blizzard: the mark at the cell's edge, the label 6 to its right", function()
	-- theme blizzard, member page: spacing's mark at the row frame's left (content x 0, or 407 in the
	-- second column), 2 wide, (34 - 12) tall; its label's LEFT offset 6; show's label offset 0
end)

test("the diff icon follows the label's text and lists who differs", function()
	-- source page: spacing's frame.share.diff shown, st.icons.diff, 16x16, OB.DIFF_COLOR, 4 after the label's text;
	-- stub.fire_script(diff, 'OnEnter', true): tooltip lines 'Spacing', 'All bars: 3', 'Bar 2: 2', 'Bar 4: 1'
end)

test('the hover line: it shows on an offering row and stays while the mouse is on the row, its control or the line', function()
	local OnUpdate = function(line) stub.fire_script(line, 'OnUpdate', 0.01) end
	-- cursor (stub.cursor_x / cursor_y) on spacing's label; stub.fire_script(frame, 'OnEnter', true):
	--   frame.share.line shown, the label's point is TOPLEFT (lifted)
	-- cursor onto the slider, stub.fire_script(frame, 'OnLeave', true), OnUpdate: still shown
	-- cursor onto frame.share.multiple: still shown; click it: W.ListOwner() == multiple; cursor off the row, OnUpdate: still shown
	-- W.CloseList(); OnUpdate: hidden, label anchored LEFT again
	-- a plain row: OnEnter(true): no line, the label's point unchanged
end)

test('Reset, All and Multiple act through the share and draw the page again', function()
	-- click reset: one reset call, onChanged(true) once; reset's tooltip lines 'Reset',
	--   'Spacing follows All bars again. Bar 3's own value is dropped.'
	-- click all: one applyAll call; click multiple, check two rows, click Apply: apply got { 'bar2', 'bar5' }
end)

test("a section title carries its block's marks and the line beside it", function()
	-- member page, a position option own: body.shareTitles[1].title colored OB.OWN_TEXT, the block's row mark shown;
	-- fire hover OnEnter(true): the line shown right of the title's text; source page with differs: the diff icon after the title
end)

test('Blizzard: every piece draws, and no line runs past the body', function()
	-- theme blizzard: mark, diff, line shown as on Thick; a row in the second column whose line is wider than
	-- its room: the line's right edge at the body's width
end)
```

In `tests/core/options_list_test.lua`:

```lua
test('the Apply list: checks change nothing until Apply, which hands over the checked keys', function()
	-- W.OpenApplyList(owner, { {key='a',label='A'}, {key='b',label='B'}, {key='c',label='C'} }, onApply):
	-- every box unchecked, the Apply button shown under the rows; click rows b and c: marked, list open, no call;
	-- click Apply: list closed, onApply got { 'b', 'c' }
	-- again with nothing checked: Apply closes it, no call; Esc and a click on the catcher close it, no call
	-- W.OpenList(...) afterwards: no Apply button; under Blizzard the button wears the panel button
end)
```

- [ ] **Step 2: Run to see them fail**

Run: `tests/run tests/core/options_share_test.lua tests/core/options_list_test.lua`
Expected: FAIL — `OM.ShareState` and `W.OpenApplyList` are nil.

- [ ] **Step 3: Implement** the model functions, `W.OpenApplyList`, `optionsshare.lua` and the body's hooks as the Interfaces say. Every script set or hooked wraps its handler (`function(self) ... end`), never a function with an optional second parameter.

- [ ] **Step 4: Run** the two files, then `tests/run -j2`. Expected: PASS, `harness_self_test.lua` included (the shell's list matches `load.xml`).

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionsmodel.lua SaftUI-Core/Config/optionsshare.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/Config/optionslist.lua SaftUI-Core/Config/load.xml tests/lib/shell.lua tests/lib/options_walk.lua tests/core/options_share_test.lua tests/core/options_list_test.lua .agents/edit-mode.md .agents/testing.md
git commit -m "core: mark shared options that differ and offer Reset and Apply to"
```

**In-game checks:** nothing in `/sui` uses `share` until Task 6, so this task's check is that every page looks and behaves as after Task 1 (no stray marks, no row moving under the mouse), under Thick, Thin and Blizzard. Task 6 carries the checks of these pieces.

---

### Task 5: Core kit: the menu item and its menu

**Files:**
- Create: `SaftUI-Core/Config/optionsitem.lua` (the `item` widget), in `load.xml` and `options_widget_files()` after `optionskeybinding.lua`, before `optionsposition.lua` (so it's a built-in type).
- Create: `SaftUI-Core/Config/optionsmenu.lua` (the menu), in `load.xml` and `options_window_files()` after `optionssmalldialog.lua`.
- Modify: `optionsmodel.lua` (`item` may be small; `menuTitle` in `stringIsLiteral`; `OM.Search` into menus), `optionswidgets.lua` (`W.WIDTH.item = 0`; `Base:Release` clears `self.body`; the header's type list and file list), `optionsbody.lua` (`RowCell` sets `widget.body = self`; `PlaceRow`'s item branch; `OB.New(content, root, onChanged, width, opts)` with `opts.oneColumn`), `optionswindow.lua` (`OW:Render` runs `S.FollowMenu` after `S.FollowDialog`; the window's Esc passes while a menu shows; `OnHide`, `OW:Navigate`, `Select` and `GoTo` close the menu; a search result's `menu` opens it), `optionssmalldialog.lua` (the dialog's Esc passes while a menu shows; its `OnHide` closes a menu whose item is in its body), `load.xml`, `tests/lib/shell.lua`, `tests/lib/options_walk.lua` (`item` in `SAFTUI_TYPES`; `menu` and `menuTitle` in `SAFTUI_FIELDS`; `each_option` also walks an option's `menu` group, its paths going on through the item's key and `'menu'`).
- Test: create `tests/core/options_item_test.lua` and `tests/core/options_menu_test.lua` (the window world of `options_window_helpers.lua`, with a synthetic module page of items: one with a box and a menu of a select, a range, a Position and a centred Reset; one with no `get`; one item in the small dialog for the dialog's case).
- Docs: `.agents/edit-mode.md` (`covers:` gains both files; the `item` type, `menu` and `menuTitle` fields; the menu's behaviour; search into menus; the widget and window file lists), `.agents/testing.md`, the headers of every file touched.

**Interfaces:**
- Consumes: `OM.ShareState`, `OM.MenuRoot`, `OM.MENU_KEY`, `OB.PlaceShare` (Task 4); `body.metrics`, `Body:CellRect` (Task 1).
- Produces:
  - **The `item` type** (SaftUI's): `{ type = 'item', name, desc, order, size = 'small', get, set, share, menu = <group>, menuTitle = <string> }`. `get`/`set` are its Show box (no `get`: no box); `share` is its Show's (Task 4); `menu` a group whose options the menu draws; `menuTitle` the menu's title (the item's name when nil). It may be small (a quarter cell), normal or wide.
  - **The widget** (`optionsitem.lua`): `w.frame` spans the cell and takes no mouse; `w.box` (the 18 check box, `Kit.CheckBox`, at the cell's left; under Blizzard the Settings check box at the check list's row size, `W.CheckArtSize(22)`, `'LEFT'`); `w.dots` (a button 16 x 24 at the cell's right edge holding `st.icons.ellipsisVertical` at 16x16, Text > Grey, Text > Blue under the mouse, white under Blizzard); `w:OpenMenu()` (`st.OptionsWindow:OpenMenu(self)`; a click on the dots while its menu is open closes it); a click on the box commits `not value` through `Base:Commit`; `OnDisabled` stops the box's and the dots' mouse.
  - **The row** (`PlaceRow`'s item branch): the widget is given the cell's width; the label starts 26 in when there's a box (else at the cell's left), plus `markShift` when marked, centred on the row, and ends 6 before the dots (less the diff icon's 20 when it shows, so the icon never reaches the dots); `OB.PlaceShare` draws its mark, diff and hover line.
  - `widget.body`: the body that drew a widget (every widget; cleared on release).
  - `OB.New(content, root, onChanged, width, opts)`: `opts.oneColumn` lays every row of the body as wide.
  - **The menu** (`optionsmenu.lua`):
    - `OW:OpenMenu(widget) -> boolean`: false in combat or when the widget's row has no `menu`; closes any open menu first. Remembers the item as `{ body = widget.body, path = widget.row.path }`.
    - `OW:CloseMenu()`, `OW:IsMenuShown() -> boolean`.
    - `OW.GetMenuFrames() -> M`: `{ frame, catcher, title, content, body, keys, owner = { body, path } }`.
    - `OW.MenuPlace(anchor, width, height, screenWidth, screenHeight) -> point, relPoint, x, y`: `anchor = { left, right, top, bottom }` the dots' rect on the screen. The menu's TOPRIGHT on the dots' BOTTOMRIGHT, 4 below; its TOPLEFT on the dots' BOTTOMLEFT when that would put its left edge past the screen's; BOTTOM* on TOP*, 4 above, when its bottom would go past the screen's.
    - The frame: `FULLSCREEN_DIALOG`, level 410 (over the small dialog's 300), 400 wide, drawn `st:SetTemplate(frame, 'theme', 'solid', 'panel')` (under Blizzard that is the panel art, as the dialog), with `st:KeepInScreenMargin`; the title (`OB.Font('section')`, grey) 12 in and 10 down; under it a plain content frame (no scroll frame) holding a body of its own, `OB.New(content, OM.MenuRoot(option), MenuChanged, 376, { oneColumn = true })`, drawing `OM.BuildView(root, OM.MENU_KEY).sections`; the menu as tall as the title and the body. Its catcher: a frame over UIParent at `FULLSCREEN_DIALOG` level 400 that takes the mouse and closes the menu on `OnMouseDown`. Its keys: the window's `EscapeKeys` on the menu frame, closing it.
    - `MenuChanged(ok, err, isDragging, widget)`: a failed validate shows in the window's status line; mid-drag the menu's body refreshes in place (`body:Refresh(widget)`); otherwise `OW:Render()`.
    - `S.FollowMenu()` (after `S.FollowDialog`, on every render): skipped while the menu is busy (a list or confirm of its own open, its slider held, its box typing), as `FollowDialog` skips; else it finds its item's cell again in `owner.body.cells` by path and re-anchors (`OW.MenuPlace`) to that cell's dots and draws its body again, or closes when no cell has the path.
    - It closes on Esc, a click outside, `OW:Navigate`, a tab or pick (`Select`), a search result's `GoTo`, the window hiding (combat closes the window), and the small dialog hiding when the item is in the dialog's body.
  - **Search** (`OM.Search`): an item's menu settings are found as the page's are (by their name, the item's name as their section title, or a tab name); each result is `{ pageKey, path = <the item's path>, name = <the setting's name>, tabName, sectionTitle = <the item's name>, menu = true }`. The window's `GoTo(path, footer, menu)` brings the item into view with its label blue (as today) and, with `menu`, opens its menu at the end of the draw, once the scroll is set (ruling 10).

- [ ] **Step 1: Write the failing tests**

`tests/core/options_item_test.lua`:

```lua
test('four small items make one line of quarters', function()
	-- Thick: items at x 14, 208, 401, 595, 165 wide, 38 tall; Blizzard: 0, 196, 407, 603, 171 wide
end)

test('an item: its Show box, its name, its dots', function()
	-- w.box at the cell's left, checked from get; click: set got false, onChanged(true);
	-- the label 26 in, the row's name; w.dots at the cell's right end, its texture st.icons.ellipsisVertical, 16x16, grey;
	-- stub.fire_script(dots, 'OnEnter', true): blue; OnLeave(true): grey
	-- an item with no get: no box, the label at the cell's left
end)

test("an item's marks: own-marked by its menu, its diff icon short of the dots", function()
	-- member item whose menu size is own: mark shown, label OB.OWN_TEXT, no hover line on OnEnter(true)
	-- source item with differs and a long name: diff icon shown, its right edge left of the dots' left
end)

test("Blizzard: the box is the Settings check box at the row size, the dots white under the mouse, the last item's line inside the body", function()
	-- theme blizzard: w.box.art.normal shown at 23 x 22 from the box's top left (W.CheckArtSize(22), 'LEFT');
	-- dots OnEnter(true): vertex color 1,1,1; the fourth item on the source page with Show differing:
	-- OnEnter(true) on its row, its line's right edge at the body's width (774), not past it
end)
```

`tests/core/options_menu_test.lua`:

```lua
test('MenuPlace: under the dots, right-aligned; flipped above near the bottom; left-aligned near the left', function()
	local function at(...) return table.concat({ OW.MenuPlace(...) }, ',') end
	eq(at({ left = 600, right = 616, top = 500, bottom = 476 }, 400, 300, 1920, 1080), 'TOPRIGHT,BOTTOMRIGHT,0,-4', 'below')
	eq(at({ left = 600, right = 616, top = 200, bottom = 176 }, 400, 300, 1920, 1080), 'BOTTOMRIGHT,TOPRIGHT,0,4', 'above, near the bottom')
	eq(at({ left = 100, right = 116, top = 500, bottom = 476 }, 400, 300, 1920, 1080), 'TOPLEFT,BOTTOMLEFT,0,-4', 'to the right, near the left')
end)

test('the dots open the menu: over the dialog, one column, titled, the position block in it', function()
	-- click dots: OW:IsMenuShown(); M.frame strata FULLSCREEN_DIALOG, level 410, width 400; M.catcher level 400 over UIParent;
	-- M.title's text is menuTitle; every menu row's cell spans the body (one column); a 'Position' section; Reset centred
	-- click the dots again: closed; open one item then another: the second's menu, one frame shown
end)

test('the menu closes on Esc, a click outside, another pick or tab, and the window closing', function()
	-- each: OW:IsMenuShown() false after; Esc: M.keys OnKeyDown 'ESCAPE', the window still shown, and the window's
	-- own keys pass Esc while the menu showed (SetPropagateKeyboardInput(true))
	-- OW:OpenMenu in combat: false
end)

test('the menu follows its item through a redraw, and closes when the item is gone', function()
	-- open; change a value behind it and OW:Render(): still shown, anchored to the item's new cell's dots
	-- (the redrawn cell's widget.dots), its row showing the new value; hide the item (hidden = true) and render: closed
end)

test('a set in the menu draws the page and the menu again', function()
	-- set the menu's range: the page re-rendered once (OW.GetRenderCount), the menu still shown with the value
end)

test("a dropdown inside the menu opens above it, and closing the list leaves the menu", function()
	-- click the menu's select: W.ListOwner() is it; the list's strata TOOLTIP;
	-- OnKeyDown 'ESCAPE' on the list's catcher: list closed, menu shown; open again, OnMouseDown on the list's catcher: same
end)

test('a menu from an item in the small dialog opens over it and closes with it', function()
	-- OW:OpenDialog('Dialog', group with an item); click its dots: M.owner.body == OW.GetDialogFrames().body,
	-- M.frame's level over the dialog's; OW:Render(): the menu still on the dialog's item; OW:CloseDialog(): menu closed
end)

test("search finds a menu's setting and opens the page and the menu", function()
	-- search 'Outline' (tick past the delay): a result named Outline under the item; click it:
	-- the page shown, the item's label Text > Blue, OW:IsMenuShown()
end)

test('Blizzard: the menu drawn as the dialog is, its body without panels', function()
	-- T.watch-style: M.frame drawn 'theme,solid,panel'; M.body.metrics == OB.FLAT; #M.body.pools.panel.used == 0
end)
```

Also `options_walk`'s `ace_ready` leaving an item out and `each_option` reaching a menu's options: one case in `tests/core/options_kit_test.lua` beside the existing `ace_ready` cases.

- [ ] **Step 2: Run to see them fail**

Run: `tests/run tests/core/options_item_test.lua tests/core/options_menu_test.lua`
Expected: FAIL — no widget for type `item`.

- [ ] **Step 3: Implement** as the Interfaces say.

- [ ] **Step 4: Run** the two files and `tests/core/options_kit_test.lua`, then `tests/run -j2`. Expected: PASS (`options_validate_test.lua` and `options_desc_test.lua` too).

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionsitem.lua SaftUI-Core/Config/optionsmenu.lua SaftUI-Core/Config/optionsmodel.lua SaftUI-Core/Config/optionswidgets.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionssmalldialog.lua SaftUI-Core/Config/load.xml tests/lib/shell.lua tests/lib/options_walk.lua tests/core/options_item_test.lua tests/core/options_menu_test.lua tests/core/options_kit_test.lua .agents/edit-mode.md .agents/testing.md
git commit -m "core: add menu items, small parts whose settings open in a menu"
```

**In-game checks:** none of SaftUI's pages has an item until Task 6, which carries the menu's checks; here, check that `/sui` opens, searches, closes with Esc and draws its pages as after Task 4, and that the small dialog (Unitframes → Copy from) still opens, works and closes.

---

### Task 6: Action bars: the new page

**Files:**
- Create: `SaftUI-ActionBars/textoptions.lua` (the four text items and their menus), listed in the TOC after `extras.lua`, before `options.lua`.
- Modify: `SaftUI-ActionBars/options.lua` (the page: the All bars entry and each bar, no tabs; `AB:ShareFor`, `AB:SettingText`; movers' `configPath`; header), `SaftUI-ActionBars/SaftUI-ActionBars.toc`.
- Test: create `tests/actionbars/page_test.lua`; rewrite the Action bars case of `tests/core/options_frames_pages_test.lua` for the new page (Position last on each bar and each extra; the texts' Position blocks with no TO part in their menus; theme and background on All bars; every option and menu option with a desc); move `tests/actionbars/cooldown_numbers_test.lua`'s toggle and Text tab cases onto the countdown item's Show on All bars and its menu.
- Docs: `README.md` (line 35, the Action Bars page), `AGENTS.md` (the ActionBars row: `shared.lua`, `textoptions.lua`, `options.lua`), `.agents/edit-mode.md` (the section-shape bullet's "action bars' Text and Visibility" tabs; a sentence on the page as the kit's first user; `covers:` gains `SaftUI-ActionBars/textoptions.lua`), `.agents/testing.md`, `options.lua`'s and `textoptions.lua`'s headers, `docs/followups.md` (move "2026-11-13 — Action bars: shared settings for all bars, and Cooldown numbers as an Enable box" to Resolved with a `**Resolved 2026-11-13:**` line, and its ToC link).

**Interfaces:**
- Consumes: every `AB:*` setter and reader of Task 2, `growth` and `AB.GROWTH_VALUES`/`AB.GROWTH_ORDER` of Task 3, the `share` field (Task 4), the `item` type with `menu` and `menuTitle` (Task 5).
- Produces:
  - `AB:SettingText(id, key) -> string`: a value as the tooltips show it: a number as is; `fade_alpha` as a percent (`'30%'`); `visibility` and `growth` by their labels; `<kind>.show` `'Shown'` or `'Hidden'`; a font by its name; an outline by the Fonts module's label; an unset countdown font, size or outline `'Default'`; a position `'<point label> to <rel_point label>, <x>, <y>'` with `st.FRAME_ANCHORS`' labels (`'Top Right to Top Right, -3, -3'`).
  - `AB:ShareFor(id, key) -> share`: `source = 'All bars'`; on `'all'`: `shared`, `differs` (`AB:OwnersOf(key)` as `{ name = label, value = AB:SettingText(owner, key) }`), `targets` (the owners), `applyAll` (`AB:ApplyToAll('all', key)`, `AB:UpdateBars()`), `apply` (`AB:ApplyTo('all', key, keys)`, `AB:UpdateBar` each); on a bar: `page` (its label), `own` (`AB:IsOwn`), `reset` (`AB:ResetSetting`, `AB:UpdateBar(id)`), `shared`, `targets` (the other bars that `HasSetting`, in `BAR_IDS` order), `applyAll` (`AB:ApplyToAll(id, key)`, `AB:UpdateBars()`), `apply` (`AB:ApplyTo(id, key, keys)`, `AB:UpdateBar` for the bar and each key).
  - `AB:GetTextItem(id, kind, order) -> option` (`textoptions.lua`, `id` a bar or `'all'`): `type = 'item'`, `size = 'small'`; name Hotkey, Stack count, Macro name, or **Cooldown** with `menuTitle = 'Cooldown numbers'`; its Show (`<kind>.show`, with `share = AB:ShareFor(id, '<kind>.show')`), except the countdown's: on All bars Blizzard's setting (`AB:ShowsCooldownNumbers`, `AB:SetShowCooldownNumbers`, no `share`, desc as today's toggle's), on a bar none (no `get`; desc: the numbers are turned on for every bar on All bars). `menu`: Font, Size (6–32), Outline, then Position (`generators.position`, no TO part, named `'Position'`), each with `share = AB:ShareFor(id, '<kind>.<key>')`; the countdown's Font, Size and Outline show what's drawn until set (`AB:GetCountdownFont(AB:GetBarConfig(id))`, as today) and its menu ends with Reset (`align = 'center'`, `confirm`, `AB:ResetCountdown(id)` then the update). A set on `'all'` runs `AB:UpdateBars()`, on a bar `AB:UpdateBar(id)`.
  - `AB:GetAllBarsOptions(order)` and `AB:GetBarOptions(id, order)` (no `childGroups`), and `AB:GetConfigTable()` with `all` first in the picker (`order = 0`, named `'All bars'`), then the bars, then the extras (`AB:GetExtraOptions` unchanged). Nothing above the picker. Inline groups, in order:
    - All bars: `look` (Look: `theme`, `background`, as today's, `AB:UpdateConfig()` on a set), `layout` (Layout: `buttons` 1–12, `perrow` 1–12, `size`, `spacing`, `growth` 'First button'), `visibility` (Visibility: `visibility` 'Show', `fade_alpha` 'Faded opacity'), `text` (Text: `hotkey`, `count`, `macro`, `countdown` items).
    - A bar: `thisbar` (This bar: `enable`, small), `layout` (as All bars', `buttons` and `perrow` up to the bar's own count), `visibility`, `text` (the pet and stance bars: `hotkey`, `countdown`), then `position` (order 1000, as today).
    - Every Layout and Visibility option has `share = AB:ShareFor(id, key)`, gets with `AB:GetSetting` and sets with `AB:SetSetting` and the update.
    - Faded opacity's `hidden`: on a bar, while its effective Show isn't `'mouseover'`; on All bars, unless All bars' Show or any bar's effective Show is `'mouseover'` (spec ruling 6).
  - Movers: `configPath = { 'ActionBars', id }` for the bars; the extras keep theirs.

- [ ] **Step 1: Write the failing tests** in `tests/actionbars/page_test.lua` (world: `cooldown_numbers_test.lua`'s, every bar a plain bar with its 12 or 10 buttons, `AB.built = true`, the extras stood in as `options_frames_pages_test.lua` does; `OM.BuildView`, `OM.ShareState` and `OM.Search` over `{ ActionBars = AB:GetConfigTable() }`).

```lua
test('the picker: All bars first, then the bars, then the extras; nothing above it', function()
	-- picker keys all,bar1..bar8,pet,stance,extra,zone,vehicleleave; values[1].name 'All bars';
	-- the page's own args hold only the picks (no theme, background or countdown)
end)

test('All bars: Look, Layout, Visibility, Text; no tabs', function()
	-- section titles in order; rows per section by key; view.tabs empty; the four items small on one line
end)

test('a bar: This bar, Layout, Visibility, Text, then Position last; the pet and stance bars have two texts', function()
	-- bar3's view (pick 'bar3'): section titles This bar, Layout, Visibility, Text, Position; This bar's one row enable (small);
	-- Layout's rows buttons, perrow, size, spacing, growth, buttons' and perrow's max 12; view.tabs empty
	-- pet's Text rows: hotkey, countdown; pet's buttons max 10
end)

test('a change on a bar is its own; on All bars every following bar takes it', function()
	-- set bar3's size: IsOwn('bar3','size'), UpdateBar:bar3; ShareState(bar3 size row).own and offers
	-- set All bars' spacing: UpdateBar for every bar
end)

test('a new profile: All bars shows the diff icon on Buttons per row and Button size, with who differs', function()
	-- ShareState(all perrow row).differs names Bar 4..Bar 8 with '1'; size: 'Pet bar: 30', 'Stance bar: 30'; the others none
end)

test("Reset, All and Multiple on a bar, and on All bars", function()
	-- OM.ShareCall(bar4 perrow row, 'reset'): bar4 follows, its row no longer own
	-- OM.ShareTargets(bar3 size row): every bar but Bar 3; (bar3 count.size): no Pet bar or Stance bar
	-- ShareCall(bar3 size, 'apply', { 'bar5' }); ShareCall(all perrow, 'applyAll'): OwnersOf('perrow') empty
end)

test("a text item: own-marked by its menu, its diff lines naming the settings", function()
	-- SetSetting('bar3','hotkey.size',8) and ('bar3','hotkey.position', 'TOPLEFT','point'):
	-- bar3's hotkey item marked; All bars' hotkey item differs == { { name = 'Bar 3', value = 'Size, Position' } }, offers false
	-- SetSetting('bar3','hotkey.show',false): All bars' item offers, differs 'Bar 3: Show, Size, Position'
end)

test("the cooldown numbers: Show is Blizzard's setting on All bars, none on a bar; Reset as the spec says", function()
	-- all's countdown item: name 'Cooldown', menuTitle 'Cooldown numbers', get/set the CVar, nothing written to the profile;
	-- bar3's: no get, desc names All bars; the menu's reset on bar3 runs AB:ResetCountdown('bar3') (spec ruling 4's values)
end)

test("Faded opacity shows when the page's Show, or on All bars any bar's, is faded until moused over", function()
	-- fresh: the fade_alpha option's hidden() true on bar3 and on all;
	-- SetSetting('bar3', 'visibility', 'mouseover'): bar3's false, all's false, bar2's still true;
	-- ResetSetting('bar3', 'visibility'), SetSetting('all', 'visibility', 'mouseover'): all's false, bar2's false (follows)
end)

test('clicking a bar in edit mode opens its page', function()
	-- st.RegisterConfigMover spied: AB:RegisterBarMover('bar3') passes configPath { 'ActionBars', 'bar3' };
	-- OM.SelectionForPath(root, that path) gives pick 'bar3'
end)

test("search finds a text menu's settings on All bars and on each bar", function()
	-- OM.Search(root, 'Outline'): results with menu = true, sectionTitle 'Hotkey', on 'all' and 'bar3' paths
end)

test('SettingText', function()
	-- fade_alpha 0.3 → '30%'; growth 'TOPRIGHT' → 'Top right'; hotkey.position → 'Top Right to Top Right, -3, -3';
	-- countdown.size unset → 'Default'; hotkey.show false → 'Hidden'
end)
```

- [ ] **Step 2: Run to see them fail**

Run: `tests/run tests/actionbars/page_test.lua`
Expected: FAIL — no `all` pick.

- [ ] **Step 3: Implement** `textoptions.lua` and the page in `options.lua` as the Interfaces say. Keep the descriptions in today's style (each option a `desc`; descs say "Global Settings > Fonts", never an arrow).

- [ ] **Step 4: Update** `options_frames_pages_test.lua`'s Action bars case and `cooldown_numbers_test.lua`'s page cases (Files), keeping what each asserted about the bars.

- [ ] **Step 5: Run** `tests/run tests/actionbars tests/core/options_frames_pages_test.lua tests/core/options_validate_test.lua tests/core/options_desc_test.lua`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 6: Docs** as listed under Files.

- [ ] **Step 7: Commit**

```bash
git add SaftUI-ActionBars/textoptions.lua SaftUI-ActionBars/options.lua SaftUI-ActionBars/SaftUI-ActionBars.toc tests/actionbars/page_test.lua tests/actionbars/cooldown_numbers_test.lua tests/core/options_frames_pages_test.lua README.md AGENTS.md .agents/edit-mode.md .agents/testing.md docs/followups.md
git commit -m "actionbars: rebuild the page around All bars, with menus for the texts"
```

**In-game checks:**
1. `/sui` → Action Bars opens on All bars: Look, Layout, Visibility, Text on panels; Buttons per row and Button size carry the orange diff icon; hovering it lists Bars 4–8 (per row 1) and the pet and stance bars (size 30).
2. Change All bars' Button size: bars 1–8 change, the pet and stance bars keep 30. Change Bar 3's spacing: only Bar 3; its row turns blue with a bar at its left; on All bars, Spacing gets the diff icon naming Bar 3.
3. On Bar 3, hover Spacing's label: the label lifts, the line shows Own, the reset arrow and Apply to; move onto the slider and onto Multiple: it stays; leave the row: it goes. A row that isn't Bar 3's own never moves.
4. Reset (the arrow): Bar 3 takes All bars' spacing at once. Apply to: All from a bar with its own value: every bar takes it and no diff icon remains. Multiple: tick two bars, Apply: they take the value; Esc or a click outside changes nothing. Stack count's list has no pet or stance bar.
5. The texts: the four on one line (two on the pet and stance bars); the dots open a menu titled with the text, with Font, Size, Outline and Position; a font dropdown opened in it shows over it and choosing closes only the list; Esc closes the list, then the menu; the menu stays on screen near the window's right and bottom edges; switching bar closes it.
6. Cooldown: All bars' box is Blizzard's Show Numbers for Cooldowns (toggle it in Blizzard's options while `/sui` is open: the box follows, the open menu stays); on a bar there's no box and the tooltip says so; Reset puts the numbers back to Pixel Med / Pixel in the middle.
7. First button on All bars turns every following bar's buttons from that corner; the edit mode outlines don't move.
8. Clicking a bar in edit mode opens its page; searching "Outline" lists the text menus and a result opens the page with the menu open.
9. Under the Blizzard theme: no panels, the marks, icons, line and menu all drawn and readable; on Forever and on retail.
10. Enter combat with `/sui` open: it closes, the menu with it; nothing blocked (BugGrabber clean).
