# SaftUI Reset on Every Setting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every value row in `/sui` shows the reset icon while it differs from its default, with the default read from the AceDB defaults by where the setting is saved, and the bags' Categories tab loses its last two Reset buttons.

**Architecture:**
- **One source table.** A page says where a group's settings are saved with SaftUI's `saved` field beside the group's `get`. A new Core file, `SaftUI-Core/Config/optionsdefault.lua`, reads `st.defaults` at that path by AceDB's rules (`st:DefaultAt`), so the default is what a fresh profile holds.
- **One reset path.** A reset writes the default through the row's own `set` (`OM.WriteValue`), or for a mover's Position through `EM:Reset`. The kit's icon, placement and tooltip (`optionsshare.lua`'s `OB.PlaceDefault`) stay as they are and gain the new sources.
- **One walk.** `tests/lib/reset_walk.lua` checks a page's every value row has a reset or a stated `noReset`, and round-trips each derived one. A coverage scan makes sure every page is walked.

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0; SaftUI's options kit (`st.OptionsModel`, `st.OptionsWidgets`, `st.OptionsBody`, `st.OptionsWindow`); edit mode (`st.EditModeFrames`); tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-15-saftui-reset-every-setting-design.md`. Its calls 1 to 18 are taken as accepted. Its one question (Reset all) doesn't block: the plan builds call 13 (Reset all goes); if the owner keeps it, Task 5's Step 5 keeps the button under a new label instead, and nothing else changes.

**Assumed state.** `modular` at `12859a99` with the spec committed. The audit's throwaway files are not in the repo; the walk in Task 1 is their committed form.

## How the tasks are cut

| # | Task | Needs | Runs beside | Owner can try in game |
| --- | --- | --- | --- | --- |
| 1 | The kit: derived defaults, the mover link, the walk and the coverage scan | — | — | no page declares `saved` yet; a mover's Position (the tracker's) resets, and Undo takes it back |
| 2 | Global settings | 1 | 3, 4, 5, 6, 7 | General and Edit mode tabs' resets; Kinds of text and Window titles still resetting |
| 3 | Unit frames | 1 | 2, 4, 5, 6, 7 | G2 |
| 4 | Action bars | 1 | 2, 3, 5, 6, 7 | the extra buttons' resets; G6 |
| 5 | Bags and the Categories tab | 1 | 2, 3, 4, 6, 7 | G1, G4, G5 |
| 6 | Misc's pages | 1 | 2, 3, 4, 5, 7 | the tooltip's, totem bar's, buffs', swing timer's, Skinning's, experience bar's and durability's resets |
| 7 | Chat, Loot, Minimap, Micro menu, Tracker | 1 | 2, 3, 4, 5, 6 | Chat's, Loot's, the minimap's resets; G7 |
| 8 | The coverage made strict, and the docs closed | 2–7 | — | G3 across the pages |

Task 1 lands first. Tasks 2 to 7 touch no file in common (their code and their tests are each one addon's, or Core's pages for Task 2), so they can run side by side; each leaves `tests/run` green on its own because the coverage scan stays lenient until Task 8. Their docs touch separate paragraphs of `.agents/edit-mode.md`, `.agents/testing.md` and `.agents/architecture.md`: merge those by hand, keeping both sides.

## Files shared with work in flight

Branches open today touch `SaftUI-Core/Config/options*.lua` (the font list, menus), `SaftUI-Core/Media/fonts.lua`, `SaftUI-Core/Widgets/`, `SaftUI-Bags/`, `SaftUI-ActionBars/` text options, `SaftUI-Misc/totem*.lua` and `SaftUI-Loot/` options. Two designs are being written beside this one: UI scaling, and colors applied live with a preview in the color picker.

| Task | Shared with branches in flight | Shared with the designs being written |
| --- | --- | --- |
| 1 | `SaftUI-Core/Config/optionsshare.lua`, `optionsmodel.lua` (small edits: the new code is in the new `optionsdefault.lua`), `load.xml`, `.agents/edit-mode.md` | the color picker: a reset under an open picker closes it writing nothing (kept, `optionscolorpicker.lua` unchanged); UI scaling: its UI size row needs a real AceDB default (a sentinel for "automatic") to take a derived reset |
| 2 | `SaftUI-Core/Media/fonts.lua` (Kinds of text's two rows) | UI scaling (General tab rows, `general.lua`); live colors (`Media/theme.lua`'s rows) |
| 3 | — | — |
| 4 | `SaftUI-ActionBars/textoptions.lua` (the Cooldown item) | — |
| 5 | `SaftUI-Bags/options.lua`, `categoriestab.lua`, `categories.lua` | — |
| 6 | `SaftUI-Misc/totemoptions.lua` | — |
| 7 | `SaftUI-Loot/options.lua` | — |
| 8 | — | — |

Where both touch a file, merge by hand and keep both sides. A row added by another branch after this lands is caught by the walk of its page.

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder changes.
- **Privacy.** No account, realm or character name anywhere: code, tests, docs, commits.
- **Commits.** Lowercase `module: imperative summary`. Stage by explicit path, never `git add -A`, `.` or a folder. End with the session's `Co-Authored-By` line.
- **Line endings.** Some working-tree files are CRLF. Never `sed -i`. Edit with the editor and keep each file's endings (`file <path>`).
- **Words.** Sentence case for every name, label and desc, in American spelling. Name a path with ">": "Global settings > Fonts".
- **Resets.** Per setting (a row's reset source, spec section 1), never a section's or a page's Reset button.
- **Icons.** Lucide's (`st.icons`), drawn at twice the glyph. An icon-only control always has a tooltip.
- **Scripts.** Kit controls (`W.Button`, `W.IconButton`, `W.IconLink`, `W.SelectFace`, `Kit.NewSlot`) take `control.onClick`, never `SetScript('OnClick')`. The game calls `OnEnter` and `OnLeave` with a second argument, `motion`: wrap each as `function(self) ... end`, and fire hover scripts in tests with `true`.
- **Whole pixels.** Every size and offset through `st:RoundToPixel`; a size read back is rounded, never ceiled (a text's width may be `ceil`). Every new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard with `stub.size_noise` at `2 ^ -14`, `-2 ^ -14` and `0`.
- **Colors** are read through `st:Color` and `st:ColorRGBA` (`tests/core/color_reads_test.lua` scans for direct reads); the icon's are Text > Muted and the accent, read as it is painted.
- **Fonts** go on a text through `st:ApplyFont` or `st:FontObject`, never `SetFont` (`tests/core/setfont_scan_test.lua`).
- **Font objects.** Only `CreateFont` objects SaftUI makes and keeps; never one the game made (`.agents/taint.md` rule 10).
- **No menu inside a menu.** A font row inside an item's menu is `faceOnly` and has no dots.
- **No literal defaults.** A hand `default` reads its value from `st.defaults` (`st:DefaultAt`) or the module's shipped table. A reset writes through the row's `set` and never clears a key; a table default is written as a deep copy.
- **SaftUI's fields.** `saved` and `noReset` join `SAFTUI_FIELDS` in `tests/lib/options_walk.lua`, so `ace_ready` leaves them off and AceConfigRegistry's validator keeps passing.
- **Both clients.** Every task's tests run on `T.client('forever')` and `'retail'` where they touch a reader that differs.
- **Tests.** Each task ends green on `tests/run -j2`, and runs single files while working. An earlier assertion changes only where this work changes what it pins, and the report lists each one changed.
- **Docs.** Each task updates the docs its files make stale, in the same commit: `AGENTS.md`, the `.agents/*.md` whose `covers:` list its files, and `docs/design-system/`. Then it runs `agents-doc-parity-check` and `readme-freshness-check`. A task that changes `docs/design-system/` says so in its report: the controller republishes the Design System artifact.
- **In game.** Each task ends with its in-game checklist for the owner. Nothing counts as verified until he confirms it.

## Review Focus

1. **A default the `set` can't store.** The player's Power, Castbar and Additional power positions default to X 0.5, and the position `set` stores whole pixels. After a reset the icon must be gone, not stuck. Tests: Task 1 `'offsets compare as the set stores them'`, Task 3's walk of the player's page.
2. **A `saved` that names another setting's key.** A reset would write that setting's default into this one. The walk must fail the row. Test: Task 1 `'a saved that names another key fails the round trip'`.
3. **A unit frame profile of another name, and an element whose default comes only from `'**'`.** A new unit frame profile ("Healer") and a key the element's table doesn't name (Buffs' `alpha`, from the element-level `'**'`) still find their defaults, and a `'**'` table is not taken for a key a sibling `'**'` names. Tests: Task 1 `'DefaultAt follows AceDB: a sibling **, a table **, a *'`, Task 3 `'resets on a unit frame profile of another name'`.
4. **A mover's Position.** The reset is one history step Undo takes back; a mover with no default (the durability figure) shows no icon; a default whose anchor would loop shows none. Test: Task 1 `'a mover Position resets through edit mode'`.
5. **A shipped bag category whose shipped name another category now has.** Its Name reset fails validation, says so in the status line, keeps the icon, and resets nothing else. Test: Task 5 `'a name reset another category blocks'`.

## Rulings on the spec

1. **Names** (the spec leaves them to the builder), all in `SaftUI-Core/Config/optionsdefault.lua` unless named otherwise:
   - `st:DefaultAt(...) -> found, value`, `st.Config.SavedIn(...)`, `st.Config.SavedAt(...)`;
   - `OM.DefaultSource(root, row) -> 'share' | 'default' | 'mover' | 'derived' | 'none' | nil` (`'none'` is a `noReset`; nil is no source, the walk's failure; a row of a valueless kind gives `'none'` too);
   - `OM.DefaultDiffers(root, row) -> boolean`, for the icon;
   - `OM.ValueOf(root, row) -> value` and `OM.DefaultValueOf(root, row, default) -> value`: one Lua value per row in one shape (a color `{ r, g, b, a }`; a multiselect `{ [key] = boolean }` over its values; a position `{ point, rel_point, frame or element, x_off, y_off }` read part by part through `get(part)`; an input its text; else `OM.Get`'s first answer);
   - `OM.SameValue(rowType, a, b, opts) -> boolean`, pure, `opts = { hasAlpha }` (spec section 2's table);
   - `OM.WriteValue(root, row, value) -> ok, message`: through `OM.Set`, per type (spec section 3);
   - `EM:MoverAt(path) -> mover | nil` in `SaftUI-Core/EditMode/editmode.lua`: the registered mover whose `configPath` is `path` (a list of keys, compared key by key).
2. **`OM.DefaultState` and `OM.DefaultReset` stay in `optionsmodel.lua`** and ask `OM.DefaultSource` when it is defined; with `optionsdefault.lua` not loaded they behave as today. That file loads after `generators.lua` in `SaftUI-Core/Config/load.xml`; tests that need it load it with `load_saftui`, and `tests/lib/reset_walk.lua` loads it when `OM.DefaultSource` is nil. The shell's file lists stay as `tests/lib/harness_self_test.lua` checks them.
3. **The generators take a path.** `generators.position(order, global_frame, get, set, target, desc, name, saved)` and `generators.uf_element_position(order, get, set, target, desc, name, saved)` put `saved` on the option they build. A mover's Position needs none (the mover link).
4. **The walk's probe values** are the audit's: a toggle or Show flipped, a range one `step` (else `bigStep`, else 1) up, or down at `max`; another select key in `OM.Values` order; a multiselect's first key flipped; an input's number plus 1, or its text plus `'z'`, or `'7'` for a `pattern` row that held no number; a color's red plus 0.37 wrapped; a position's `x_off` plus 3; a font row's `'pixel'`, or `'normal'` when it holds `'pixel'`; a keybinding `'CTRL-F12'`.
5. **Hidden and disabled rows** are checked for a source, never probed and never asked `differs` on a fresh profile.
6. **The coverage scan is lenient until Task 8**: a page whose test file doesn't call `R.check_page` for it is listed in its output and passes; Task 8 sets `STRICT = true`.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Config/optionsdefault.lua` (new), `load.xml` | `st:DefaultAt`, `SavedIn`/`SavedAt`, the sources, compares and writes | 1 |
| `SaftUI-Core/Config/optionsmodel.lua` | `OM.DefaultState`/`DefaultReset` ask the sources | 1 |
| `SaftUI-Core/Config/optionsshare.lua` | the icon from `OM.DefaultDiffers`, the new tooltip words, a titled custom row's icon | 1 |
| `SaftUI-Core/Config/generators.lua` | `generators.position`'s `saved` | 1 |
| `SaftUI-Core/EditMode/editmode.lua` | `EM:MoverAt` | 1 |
| `tests/lib/harness.lua`, `options_walk.lua`, `reset_walk.lua` (new) | `read_test_source`, the fields, the walk | 1 |
| `SaftUI-Core/Config/general.lua`, `EditMode/settings.lua`, `Media/fonts.lua`, `Media/theme.lua` | Global settings' `saved` | 2 |
| `SaftUI-Unitframes/config/*.lua`, `elements/*.lua`, `nameplates/options.lua` | unit frames' `saved`, `noReset` | 3 |
| `SaftUI-ActionBars/options.lua`, `textoptions.lua` | the extras' `saved`; the Cooldown Show's default | 4 |
| `SaftUI-Bags/options.lua`, `categoriestab.lua`, `categories.lua` | the bags' `saved`; the editor's field resets; the order's reset | 5 |
| `SaftUI-Misc/tooltipposition.lua`, `experience.lua`, `totemoptions.lua`, `durability.lua`, `Skinning/skinning.lua`, `Skinning/blizzard/Blizzard_*Position.lua` | Misc's `saved` | 6 |
| `SaftUI-Chat/options.lua`, `SaftUI-Loot/options.lua`, `SaftUI-Minimap/config.lua`, `micromenuoptions.lua`, `SaftUI-Tracker/options.lua` | their `saved`, `noReset` | 7 |
| `tests/core/options_saved_test.lua`, `reset_walk_test.lua`, `reset_coverage_test.lua` (new); each page's test file | the tests | 1–8 |

---

### Task 1: The kit: derived defaults, the mover link, the walk and the coverage scan

**Files:**
- Create: `SaftUI-Core/Config/optionsdefault.lua`; add it to `SaftUI-Core/Config/load.xml` after `generators.lua`.
- Modify:
  - `SaftUI-Core/Config/optionsmodel.lua`: `OM.DefaultState` and `OM.DefaultReset` ask `OM.DefaultSource` (Ruling 2); the header comment on `default` gains `saved` and `noReset`.
  - `SaftUI-Core/Config/optionsshare.lua`: `OB.PlaceDefault` places the icon while `OM.DefaultDiffers` (when defined, else as today); a titled custom row (`W.CUSTOM[type].titled`) with a source gets the icon 6 after its label's text, centred on the label's band, the label cut to leave it room and `LABEL_ROOM`; `DefaultText` gains multiselect, input, keybinding and position (spec section 5).
  - `SaftUI-Core/Config/generators.lua`: `generators.position`'s `saved` (Ruling 3).
  - `SaftUI-Core/EditMode/editmode.lua`: `EM:MoverAt(path)`.
  - `tests/lib/harness.lua`: `read_test_source(path)`, the text of a file under `tests/` (the same path rules as `load_test_file`, CRLF made LF). `tests/lib/harness_self_test.lua` checks it.
  - `tests/lib/options_walk.lua`: `saved` and `noReset` in `SAFTUI_FIELDS`, and in its header.
- Create tests: `tests/lib/reset_walk.lua`, `tests/core/options_saved_test.lua`, `tests/core/reset_walk_test.lua`, `tests/core/reset_coverage_test.lua`. Modify `tests/core/options_default_test.lua`.
- Docs:
  - `.agents/edit-mode.md`: "A setting's own reset" rewritten as spec section 1 to 5 (the sources in order, `saved` and where it is read, `noReset`, the mover link, the compares, the writes, the rows with none, the words); `saved` and `noReset` in SaftUI's fields list; `generators.position`'s parameter.
  - `.agents/architecture.md`, "Config, defaults and profiles": `st:DefaultAt` and the rule that a page says where its settings are saved.
  - `.agents/testing.md`: `reset_walk.lua` and `read_test_source` in the helpers, the three new tests in the `tests/core/` row.
  - `docs/design-system/05-decisions.md`: decision 50, as the spec words it, under a "2026-11-15" heading.
  - `docs/design-system/components/ResetIcon/README.md` (Status: built for every setting; What the consumer provides: where the setting is saved, or a hand default, or why none), `Row/README.md` (`saved`, `noReset`), `Section/README.md` (the Do line about a section's Reset).

**Interfaces:**
- Produces (Ruling 1's names):

```lua
st:DefaultAt(...)                  -- -> found, value (never a copy)
st.Config.SavedIn(...)             -- -> function(info) return <parts>, info[#info] end; a part that is a function is called with info
st.Config.SavedAt(...)             -- -> function(info) return <parts> end
OM.DefaultSource(root, row)        -- -> 'share' | 'default' | 'mover' | 'derived' | 'none' | nil
OM.DefaultDiffers(root, row)       -- -> boolean
OM.ValueOf(root, row), OM.DefaultValueOf(root, row, default), OM.SameValue(rowType, a, b, opts), OM.WriteValue(root, row, value)
EM:MoverAt(path)                   -- -> mover | nil
read_test_source(path)             -- harness: text of tests/<path>
-- tests/lib/reset_walk.lua returns R:
R.problems(root, pageKey, opts) -> { string, ... }   -- opts = { fresh = true, probe = true, skip = { ['<path joined by .>'] = true } }
R.check_page(root, pageKey, opts)                    -- check(false, p) per problem, and check(walked > 0)
```

  - Option fields: `saved = function(info) -> key, ... | false` (read from the node that gives the row its `get`), `noReset = '<why>'` (read raw).

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_saved_test.lua (core/config_helpers.lua's real AceDB, then optionsdefault.lua)
test('DefaultAt follows AceDB: a sibling **, a table **, a *', function()
	st.defaults.t_ = { a = { x = 1, ['**'] = { deep = true } }, ['**'] = { y = 2, x = 9 }, star = { ['*'] = 5 } }
	-- DefaultAt('t_', 'a', 'x') == true, 1 (own beats the sibling **)
	-- DefaultAt('t_', 'a', 'y') == true, 2 (the sibling **, as AceDB copies it in)
	-- DefaultAt('t_', 'b', 'y') == true, 2;  DefaultAt('t_', 'a', 'z', 'deep') == true, true (a's own **)
	-- DefaultAt('t_', 'star', 'q') == true, 5;  DefaultAt('t_', 'nope') == false
	-- the unit frames: DefaultAt('unitframes', 'profiles', 'Healer', 'player', 'buffs', 'alpha') gives the element-level ** alpha (1), not buffs' own ** table
end)
test('SavedIn and SavedAt give the keys as returns, parts that are functions called with info', function()
	-- SavedIn('chat')({ 'Chat', 'general', 'font' }) returns 'chat', 'font'
	-- SavedAt('a', function(info) return info[1] end, 'c')({ 'p' }) returns 'a', 'p', 'c'
end)
test('the sources in order: share, default, mover, derived, noReset, else nil', function()
	-- a member share with own: 'share'; default = {...}: 'default'; a mover's Position: 'mover';
	-- a group saved = SavedIn('editmode') over a toggle: 'derived'; noReset = 'why': 'none';
	-- an execute, a description, an item with get = false, a bagitems row: 'none'; none of these: nil
end)
test('saved is read from the node that gives get', function()
	-- group { get, saved = SavedIn('chat') } with an option that has its own get: nil (not 'derived')
	-- the same option with its own saved: 'derived'; a group saved = false: nil
end)
test('SameValue by type', function()
	-- toggle: nil == false; range 0.30000001 == 0.3, 0.3 ~= 0.31; input '200' == 200, 'a' ~= 'A'
	-- multiselect { a = true } == { a = true, b = false }; color { 1, 0, 0 } == { 1, 0, 0, 1 } without hasAlpha,
	-- { 1, 0, 0, 0.5 } ~= { 1, 0, 0, 1 } with hasAlpha, 0.5 / 255 off is the same byte;
	-- font 'normal' ~= { font_name = 'Colus' }; two tables with the same st:FontFields are the same
	-- keybinding nil == ''
end)
test('offsets compare as the set stores them', function()
	-- position { point = 'TOP', x_off = 0.5 } against a saved x_off of st:RoundToPixel(0.5): the same
	-- after OM.WriteValue of the default, OM.DefaultDiffers is false
end)
test('WriteValue goes through set: validate runs, a failure stops it and says why', function()
	-- a set counter; a validate refusing 7: WriteValue(row, 7) -> false, '<name>: ...', nothing written
	-- a color writes r, g, b, a; a multiselect calls set only for keys that differ; a position sets only
	-- parts that differ, in the order point, rel_point, frame, x_off, y_off; a table default is a copy (~= the one in st.defaults)
end)
test('a mover Position resets through edit mode', function()
	-- load_editmode(); a mover with configPath { 'Page', 'general' }, its Position at { 'Page', 'general', 'position' }:
	-- OM.DefaultSource == 'mover'; moved: differs; OM.DefaultReset -> EM:Reset ran, one 'reset' step, History:Undo() puts it back
	-- a mover with getDefaultPosition nil and noDefaultReason: differs false (no icon), source 'mover'
	-- a default anchored to a frame now anchored to the mover's: differs false
end)
test('a profile switch: differs reads the new profile, a reset writes the new one', function() end)
test('the cost: a draw asks saved once a row and get at most once more, and no words before a tooltip', function()
	-- a page of 40 derived rows drawn in a body: wrappers count saved and get calls; DefaultText is not called
	-- until the icon's OnEnter (true)
end)

-- tests/core/options_default_test.lua (added cases)
test('a derived row shows the icon only while it differs, on every built-in type, under Thick and Blizzard', function() end)
test('a titled custom row with a default: the icon 6 after its title, the title cut for it', function() end)
test("the tooltip's new words: a multiselect's labels or none, an input's text or empty, a key or Not bound, a position in words", function()
	-- 'Show in goes back to its default: Bags, Bank.'; 'Name goes back to its default: empty.'
	-- 'Key goes back to its default: Not bound.'; 'Position goes back to its default: Top right of the screen: -320, -275.'
end)

-- tests/core/reset_walk_test.lua
test('the check is real: a value row with no source fails, and a stated one passes', function()
	-- a page: a toggle with no saved (fails, named 'Page.box.bare (toggle Bare) has no reset: ...'),
	-- one under saved = SavedIn('t_') (passes), one with noReset = '' (fails: empty), one with noReset = 'session only' (passes)
end)
test('a saved that names another key fails the round trip', function()
	-- group get/set on t_.a while saved = SavedIn('t_b'): problems name the row: the probe changed the profile outside its saved path
end)
test('a fresh profile shows no icon; a row whose default differs at start fails', function() end)

-- tests/core/reset_coverage_test.lua
-- PAGES, by the file that defines GetConfigTable: { page = '<root key>', test = '<file under tests/>' }
-- 'SaftUI-Core/Config/general.lua', 'SaftUI-Core/EditMode/settings.lua', 'SaftUI-Core/Media/fonts.lua',
-- 'SaftUI-Core/Media/colors.lua', 'SaftUI-Core/Media/theme.lua'  -> Fonts, core/options_desc_test.lua
-- 'SaftUI-Unitframes/config/config.lua' -> Unitframes, unitframes/config_test.lua
-- 'SaftUI-ActionBars/options.lua' -> ActionBars, actionbars/page_test.lua
-- 'SaftUI-Bags/options.lua' -> Inventory, bags/theme_test.lua
-- 'SaftUI-Misc/tooltipposition.lua' Tooltip, 'totemoptions.lua' TotemBar, 'Skinning/skinning.lua' Skinning,
-- 'Blizzard_BuffFramePosition.lua' Auras, 'Blizzard_SwingTimerPosition.lua' SwingTimer -> misc/options_pages_test.lua
-- 'SaftUI-Misc/experience.lua' -> Experience, misc/experience_test.lua
-- 'SaftUI-Misc/durability.lua' -> Durability, misc/durability_position_test.lua
-- 'Blizzard_ObjectiveTrackerPosition.lua' -> ObjectiveTracker, misc/objective_tracker_position_test.lua
-- 'SaftUI-Chat/options.lua' Chat, chat/theme_test.lua; 'SaftUI-Loot/options.lua' Loot, loot/theme_test.lua
-- 'SaftUI-Minimap/config.lua' Minimap and 'micromenuoptions.lua' MicroMenu, minimap/theme_test.lua
-- 'SaftUI-Tracker/options.lua' Tracker, tracker/options_test.lua
test('every page with a GetConfigTable is in PAGES, and its test file is there', function()
	-- T.saftui_files(): every file with 'function %w+:GetConfigTable%(' is a key of PAGES; read_test_source(test) ~= nil
end)
test('every page is walked (lenient until the last task)', function()
	-- for each entry: read_test_source(test) holds "check_page(" and the page key in quotes; with STRICT false a miss is printed, not failed
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `tests/run tests/core/options_saved_test.lua tests/core/reset_walk_test.lua tests/core/reset_coverage_test.lua tests/core/options_default_test.lua tests/lib/harness_self_test.lua`
Expected: FAIL: `st.DefaultAt` is nil, `read_test_source` is nil, `tests/lib/reset_walk.lua` can't be loaded.

- [ ] **Step 3: Write `optionsdefault.lua`**

`st:DefaultAt` keeps two scratch lists at file level for its candidates (an explicit key's default, then each candidate's sibling `'**'`, then `'*'` only where no candidate had the key), so a lookup makes no table. `OM.DefaultSource` takes the row's `get` node by walking the path as `Inherited` does in `optionsmodel.lua`, then reads that node's `saved`. `OM.DefaultDiffers` for a derived row is `not OM.SameValue(row.type, OM.ValueOf(root, row), OM.DefaultValueOf(root, row, value), { hasAlpha = OM.Member(root, row, 'hasAlpha') })`, a mover's is `EM:CanReset(mover)`, a hand default's is its `differs`. For a mover row `OM.DefaultReset` runs `EM:Reset(mover)` and returns its `ok, message`.

- [ ] **Step 4: Hook the model, the body and the edit mode link**

`OM.DefaultState(root, row)` gives `{ differs, text, value }` for every source (`value` for a derived row: `OM.DefaultValueOf` packed as `{ n, ... }`, a color's four numbers; a mover's: its default position). `OB.PlaceDefault` asks `OM.DefaultDiffers` alone; `DefaultTip` asks `OM.DefaultState` when the icon is entered. A failed reset puts its message on the status line through the body's owner (`onChanged(false, message)`, as a failed set does). `generators.position` and `EM:MoverAt` as Ruling 3 and 1.

- [ ] **Step 5: Write `read_test_source`, the fields, `reset_walk.lua` and the coverage scan**

`R.problems` walks with `each_option`, also over each group's `pickerControl.args`, builds each row as `{ option, path = { pageKey, ... }, type, key }` (an item's menu rows on `OM.MenuRoot(item)` with a `{ 'menu', ... }` path), and for the round trip snapshots `st.config.profile` before and after the probe set (deep copies of plain data) and diffs them: every changed key must be under the row's saved path. After each set it calls `take_errors()` and reports any error as a problem naming the row.

- [ ] **Step 6: Run the tests to see them pass, then the suite**

Run: `tests/run tests/core/options_saved_test.lua tests/core/reset_walk_test.lua tests/core/reset_coverage_test.lua tests/core/options_default_test.lua tests/lib/harness_self_test.lua`, then `tests/run -j2`
Expected: PASS. The coverage case prints every page as not yet walked.

- [ ] **Step 7: Commit**

```bash
git add SaftUI-Core/Config/optionsdefault.lua SaftUI-Core/Config/load.xml SaftUI-Core/Config/optionsmodel.lua SaftUI-Core/Config/optionsshare.lua SaftUI-Core/Config/generators.lua SaftUI-Core/EditMode/editmode.lua tests/lib/harness.lua tests/lib/harness_self_test.lua tests/lib/options_walk.lua tests/lib/reset_walk.lua tests/core/options_saved_test.lua tests/core/reset_walk_test.lua tests/core/reset_coverage_test.lua tests/core/options_default_test.lua .agents/edit-mode.md .agents/architecture.md .agents/testing.md docs/design-system/05-decisions.md docs/design-system/components/ResetIcon/README.md docs/design-system/components/Row/README.md docs/design-system/components/Section/README.md
git commit -m "core: derive every option's reset from the AceDB defaults by where it is saved"
```

In game: no page declares `saved` yet, so only Positions of movers gain a reset: move the tracker in edit mode, open its page, its Position shows the icon; click it, it goes back, and edit mode's Undo moves it again.

---

### Task 2: Global settings

**Files:**
- Modify:
  - `SaftUI-Core/Config/general.lua`: Icon zoom `saved = SavedAt('misc', 'icon_trim')`, Screen edge margin `SavedAt('misc', 'clamp_inset')`, Title bar height `SavedAt('headers', 'height')` (each row has its own `get`).
  - `SaftUI-Core/EditMode/settings.lua`: the `general` group `saved = st.Config.SavedIn('editmode')`.
  - `SaftUI-Core/Media/fonts.lua`: Kinds of text's two rows take `saved = SavedAt('buttons', 'font')` and `SavedAt('panels', 'font')` and lose their `FN.FontSettingDefault`; `FN.FontSettingDefault` goes once nothing calls it.
  - `SaftUI-Core/Media/theme.lua`: Theme `saved = SavedAt('theme', 'name')`; Window titles `saved = SavedAt('headers', 'font')`, its `FN.FontSettingDefault` gone. Each `set` still runs `st:FontsChanged()` or `st:ThemeChanged()` as now, so a reset does too.
- Test: `tests/core/options_desc_test.lua` (a case walking `Fonts`), `tests/core/fonts_tab_test.lua` and `theme_tab_test.lua` where they assert `FN.FontSettingDefault`'s rows.
- Docs: `.agents/edit-mode.md`'s General, Fonts, Theme and Edit mode lines (each row's reset); `.agents/architecture.md`'s Fonts bullet where it names `FN.FontSettingDefault`.

**Interfaces:**
- Consumes: Task 1's `st.Config.SavedIn`, `SavedAt`, `R.check_page`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_desc_test.lua
local R = load_test_file('lib/reset_walk.lua')
test('Global settings: every value row has a reset, and each derived one round-trips', function()
	R.check_page(st.Config:GetOptionsTable(), 'Fonts')
end)
-- tests/core/fonts_tab_test.lua
test('Button text and Check box labels reset to their AceDB defaults and apply at once', function()
	-- set buttons.font to 'normal': OM.DefaultDiffers true; OM.DefaultReset: st.config.profile.buttons.font == st.defaults.buttons.font, st:FontsChanged() ran
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_desc_test.lua tests/core/fonts_tab_test.lua`
Expected: FAIL naming `Fonts.general.icons.icon_trim`, the nine `Fonts.editmode.general.*` rows and `Fonts.theme.theme` as having no reset.

- [ ] **Step 3: Add the `saved` fields and drop the literal defaults**

- [ ] **Step 4: Run them to see them pass, then `tests/run -j2`**

Expected: PASS; the coverage case no longer lists `Fonts`.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Core/Config/general.lua SaftUI-Core/EditMode/settings.lua SaftUI-Core/Media/fonts.lua SaftUI-Core/Media/theme.lua tests/core/options_desc_test.lua tests/core/fonts_tab_test.lua tests/core/theme_tab_test.lua .agents/edit-mode.md .agents/architecture.md
git commit -m "core: a reset on every Global settings row"
```

In game: Global settings > General's Screen edge margin, Edit mode's Grid size, Theme's Theme: each shows the icon once changed and resets at once.

---

### Task 3: Unit frames

**Files:**
- Modify:
  - `SaftUI-Unitframes/config/config.lua`: `UF.SavedIn(unit, ...)`, a `st.Config.SavedIn('unitframes', 'profiles', function() return UF:GetProfile() end, unit, ...)`; each unit's General group and its sections take it.
  - `SaftUI-Unitframes/config/groupoptions.lua`: Layout and Range take `saved`; Test mode `noReset = 'Test mode lasts this session: it is off at every login.'`.
  - `SaftUI-Unitframes/config/profiles.lua`: the pick control's Profile `noReset = 'Chooses the unit frame profile in use.'`.
  - `SaftUI-Unitframes/config/position.lua`: `uf_element_position`'s `saved` (Ruling 3).
  - `SaftUI-Unitframes/elements/*.lua` (name, auras, power, additionalpower, health, castbar, classpower, indicators): each element group `saved = UF.SavedIn(unit, '<element key>')`, each part's Position its own `saved` (`SavedAt` of its position table).
  - `SaftUI-Unitframes/nameplates/options.lua`: the plate pages' General groups, Friendly plates' own `get` (`nameplate.friendly`) its own `saved`.
- Test: `tests/unitframes/config_test.lua`; `tests/unitframes/nameplate_page_test.lua` where its plate pages are built.
- Docs: `.agents/edit-mode.md`'s unit frame and nameplate page paragraphs (Test mode, the Profile select have no reset); `.agents/architecture.md`'s Unit frames section where it names how a setting is read.

**Interfaces:**
- Consumes: Task 1's builders and `R.check_page`. Produces `UF.SavedIn(unit, ...) -> function(info) -> keys` in `config/config.lua`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/config_test.lua (after its world, before any case changes a value)
local R = load_test_file('lib/reset_walk.lua')
test('every unit frame row has a reset, and each derived one round-trips', function()
	R.check_page({ Unitframes = UF:GetConfigTable() }, 'Unitframes')
end)
test('resets on a unit frame profile of another name', function()
	-- UF:SetProfile to a new 'Healer' (made from **): player.health.enable set false differs; its reset writes
	-- st.defaults' value into profiles.Healer, and profiles.SaftUI is untouched
end)
test("the player's Power position resets though its default X is half a pixel", function()
	-- move it 3: differs; reset: OM.DefaultDiffers false
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/unitframes/config_test.lua`
Expected: FAIL naming the unit pages' rows with no reset.

- [ ] **Step 3: Add `UF.SavedIn`, the groups' `saved` and the two `noReset`s**

- [ ] **Step 4: Run them to see them pass, then `tests/run -j2`**

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/config/config.lua SaftUI-Unitframes/config/groupoptions.lua SaftUI-Unitframes/config/profiles.lua SaftUI-Unitframes/config/position.lua SaftUI-Unitframes/elements/*.lua SaftUI-Unitframes/nameplates/options.lua tests/unitframes/config_test.lua tests/unitframes/nameplate_page_test.lua .agents/edit-mode.md .agents/architecture.md
git commit -m "unitframes: a reset on every unit frame and nameplate row"
```

(Stage each `elements/*.lua` file by its own path.) In game: G2.

---

### Task 4: Action bars

**Files:**
- Modify:
  - `SaftUI-ActionBars/options.lua`: the extra buttons' General groups (`extra`, `zone`, `vehicleleave`) `saved = st.Config.SavedIn('actionbars', id)`.
  - `SaftUI-ActionBars/textoptions.lua`: All bars' Cooldown item gets `default`: `differs` while `AB:ShowsCooldownNumbers()` isn't the game's default (`C_CVar.GetCVarDefault(COUNTDOWN_CVAR) == '1'`), `reset` `AB:SetShowCooldownNumbers(<that>)`, `value` it; with no `C_CVar.GetCVarDefault`, `noReset = "Blizzard's own setting, and this client gives no default for it."`. The CVar's name moves to `AB.COUNTDOWN_CVAR` in `skin.lua` so both files read one.
- Test: `tests/actionbars/page_test.lua`; `tests/wow/game.lua` gains `C_CVar.GetCVarDefault` (faithful: the stub's registered defaults, `'1'` for `countdownForCooldowns`).
- Docs: `.agents/edit-mode.md` (the Cooldown item's reset); `.agents/testing.md`'s `tests/wow/` row.

**Interfaces:**
- Consumes: Task 1. Produces `AB.COUNTDOWN_CVAR`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/actionbars/page_test.lua (in the case that builds the page, before it changes anything)
local R = load_test_file('lib/reset_walk.lua')
test('every action bar row has a reset or its share, and each derived one round-trips', function()
	R.check_page({ ActionBars = AB:GetConfigTable() }, 'ActionBars')
end)
test("All bars' Cooldown Show resets to Blizzard's default", function()
	-- C_CVar.SetCVar('countdownForCooldowns', '0'): the item's default differs; reset: GetCVarBool true, '1'
	-- with C_CVar.GetCVarDefault nil (a client without it): OM.DefaultSource == 'none'
end)
```

- [ ] **Step 2: Run them to see them fail** — `tests/run tests/actionbars/page_test.lua`; expected FAIL naming `ActionBars.extra.general.scale` and `ActionBars.all.text.countdown`.

- [ ] **Step 3: Add the extras' `saved` and the Cooldown default**

- [ ] **Step 4: Run them to see them pass, then `tests/run -j2`**

- [ ] **Step 5: Commit**

```bash
git add SaftUI-ActionBars/options.lua SaftUI-ActionBars/textoptions.lua SaftUI-ActionBars/skin.lua tests/actionbars/page_test.lua tests/wow/game.lua .agents/edit-mode.md .agents/testing.md
git commit -m "actionbars: a reset on the extra buttons' rows and the cooldown numbers' Show"
```

In game: G6; the zone ability's Scale resets.

---

### Task 5: Bags and the Categories tab

**Files:**
- Modify:
  - `SaftUI-Bags/options.lua`: each window's General group `saved = st.Config.SavedIn('inventory', id)`, the page's groups `SavedIn('inventory')`, the Title font and Icon font rows `SavedAt('inventory', 'fonts', 'titles')` and `'icons'` (their own `get`).
  - `SaftUI-Bags/categories.lua`: `INV:CategoryOrderDiffers() -> boolean`, `INV:ResetCategoryOrder()` (spec section 6's rule; ends in `INV:CategoriesChanged()`); `INV:ResetAllCategories` goes, and `INV:ResetCategory` too if nothing else calls it (the header's list follows).
  - `SaftUI-Bags/categoriestab.lua`:
    - `INV:CategoryEditorOptions`: Name, On, Show in and the rule each get a `default` against `INV:GetDefaultCategory(id)` through their own setters (spec section 6); on a category of your own each gets `noReset = 'Your own category has no shipped version.'`; `args.reset` goes;
    - Delete's confirm: "Delete <name>? You can bring it back with + New category > Restore a default...";
    - the list's footer: Reset all goes; a `ResetIcon` (Text > Muted, accent under the mouse, read as painted) where it was, shown while `INV:CategoryOrderDiffers()`, its tooltip "Reset" and "Order goes back to its default: SaftUI's order, with your own categories where they are.", its click `INV:ResetCategoryOrder()` then the tab drawn again; the same in the compact (half) list menu.
- Test: `tests/bags/theme_test.lua` (the page walk), `tests/bags/categories_editor_test.lua`, `categories_list_test.lua`, `categories_half_test.lua` (its "Reset to default" case becomes the field resets at half).
- Docs: `.agents/edit-mode.md`'s Categories tab paragraph; `.agents/architecture.md`'s Bag categories; `docs/followups.md`: "Categories tab at full size: a long "Reset <name> to default" overlaps Delete" to Resolved with "**Resolved 2026-11-15:** the button is gone; each field has its own reset (reset-every-setting, Task 5)." and its ToC line.

**Interfaces:**
- Consumes: Task 1, including a titled custom row's icon for the rule. Produces `INV:CategoryOrderDiffers`, `INV:ResetCategoryOrder`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/bags/theme_test.lua
test('every Bags row has a reset, and each derived one round-trips', function()
	R.check_page({ Inventory = INV:GetConfigTable() }, 'Inventory')
end)
-- tests/bags/categories_editor_test.lua
test("a shipped category's fields each reset alone; there is no Reset button", function()
	-- rename Toys to 'Fun', turn it off, hide it in the bank, add a block: four icons; the Name's reset
	-- brings 'Toys' back and leaves it off; the rule's icon sits 6 after 'Catches an item when'
	-- the editor's args have no 'reset'
end)
test('a name reset another category blocks', function()
	-- rename Toys to 'Fun', then a category of your own to 'Toys': Name's reset fails, the status line says why,
	-- the icon stays, On and Show in are untouched
end)
test('a category of your own has no field resets', function() end)
-- tests/bags/categories_list_test.lua
test("the order's reset: shown once a shipped category moves, it puts SaftUI's order back with your own where they are", function()
	-- order Toys above Hearthstone, a custom after Toys: CategoryOrderDiffers true; ResetCategoryOrder: shipped order,
	-- the custom right after Toys, Miscellaneous last; the footer has no 'Reset all'
end)
```

- [ ] **Step 2: Run them to see them fail** — `tests/run tests/bags/`; expected FAIL naming `Inventory.look.titles` and the editor's missing icons.

- [ ] **Step 3: Add the bags' `saved`, the order's store functions, the editor's defaults and the footer icon**

- [ ] **Step 4: Run them to see them pass, then `tests/run -j2`**

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Bags/options.lua SaftUI-Bags/categories.lua SaftUI-Bags/categoriestab.lua tests/bags/theme_test.lua tests/bags/categories_editor_test.lua tests/bags/categories_list_test.lua tests/bags/categories_half_test.lua .agents/edit-mode.md .agents/architecture.md docs/followups.md
git commit -m "bags: a reset on every row, and the categories' fields and order reset one by one"
```

If the owner keeps Reset all (the spec's question): Step 3 keeps it as a list action labelled "Start over", with its confirm, and drops only the editor's button; the order's icon still lands. In game: G1, G4, G5.

---

### Task 6: Misc's pages

**Files:**
- Modify (each group with a `get` takes the `saved` beside it; each row with its own `get` its own):
  - `SaftUI-Misc/tooltipposition.lua` (`SavedIn('tooltip')`), `experience.lua` (`SavedIn('experience')`, its color rows `SavedAt` of their tables), `Skinning/skinning.lua` (`SavedIn('skinning')`), `totemoptions.lua` (`SavedIn('totembar')`, its colors `SavedAt('totembar', 'colors', <element>)`), `durability.lua` (`SavedIn('durability')`; its Position needs nothing: the mover's `noDefaultReason`), `Skinning/blizzard/Blizzard_SwingTimerPosition.lua` (`SavedIn('swingtimer', key)`), `Blizzard_BuffFramePosition.lua` (`SavedIn('auras', key, kind)` and its texts' groups), `Blizzard_ObjectiveTrackerPosition.lua` (`SavedIn('objectivetracker')`).
- Test: `tests/misc/options_pages_test.lua` (Tooltip, TotemBar, Auras, SwingTimer, Skinning), `experience_test.lua`, `durability_position_test.lua`, `objective_tracker_position_test.lua`: a walk each. Where a page's stand-ins error under the probe (the Auras page's geometry), complete the stand-in; `probe = false` only with a comment saying why.
- Docs: `.agents/edit-mode.md` (Blizzard's tracker's Position resets to Blizzard's spot; the durability figure's has none).

**Interfaces:**
- Consumes: Task 1.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/misc/options_pages_test.lua (each page's case, before it changes values)
R.check_page({ Tooltip = TT:GetConfigTable() }, 'Tooltip')   -- and TotemBar, Auras, SwingTimer, Skinning
-- tests/misc/experience_test.lua, durability_position_test.lua, objective_tracker_position_test.lua: the same for Experience, Durability, ObjectiveTracker
test("the durability figure's Position has no reset; Blizzard's tracker's resets to Blizzard's spot", function()
	-- DUR: OM.DefaultSource == 'mover', differs false after a move; OTP: moved, differs; reset: st:DefaultTrackerPosition()
end)
```

- [ ] **Step 2: Run them to see them fail** — `tests/run tests/misc/`.

- [ ] **Step 3: Add the `saved` fields**

- [ ] **Step 4: Run them to see them pass, then `tests/run -j2`**

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Misc/tooltipposition.lua SaftUI-Misc/experience.lua SaftUI-Misc/Skinning/skinning.lua SaftUI-Misc/totemoptions.lua SaftUI-Misc/durability.lua SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimerPosition.lua SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua tests/misc/options_pages_test.lua tests/misc/experience_test.lua tests/misc/durability_position_test.lua tests/misc/objective_tracker_position_test.lua .agents/edit-mode.md
git commit -m "misc: a reset on every row of Misc's pages"
```

In game: a buff's Size, the swing timer's Width, the totem bar's fire color, the tooltip's Font each reset.

---

### Task 7: Chat, Loot, Minimap, Micro menu, Tracker

**Files:**
- Modify:
  - `SaftUI-Chat/options.lua`: the General group `SavedIn('chat')`; the edit box's Height and the tabs' Fade `SavedAt` of theirs; Width and Height `noReset = "Blizzard's chat frame's size, taken on first load: there is no default."`.
  - `SaftUI-Loot/options.lua`: its groups `SavedIn('loot', config_key)`; the two Test modes `noReset = 'Test mode lasts this session: it is off at every login.'`.
  - `SaftUI-Minimap/config.lua` (`SavedIn('minimap')`), `micromenuoptions.lua` (its Position is its mover's: nothing to add, unless the walk names a row).
  - `SaftUI-Tracker/options.lua`: nothing unless the walk names a row (every value row has `TR.SettingDefault`; the two Positions are movers').
- Test: `tests/chat/theme_test.lua`, `tests/loot/theme_test.lua`, `tests/minimap/theme_test.lua` (Minimap and MicroMenu), `tests/tracker/options_test.lua`: a walk each.
- Docs: `.agents/edit-mode.md`'s Tracker page paragraph (its Positions reset through their movers).

**Interfaces:**
- Consumes: Task 1.

- [ ] **Step 1: Write the failing tests**

```lua
R.check_page({ Chat = CHT:GetConfigTable() }, 'Chat')            -- tests/chat/theme_test.lua
R.check_page({ Loot = LT:GetConfigTable() }, 'Loot')             -- tests/loot/theme_test.lua
R.check_page({ Minimap = MM:GetConfigTable() }, 'Minimap')       -- tests/minimap/theme_test.lua, and MicroMenu
R.check_page({ Tracker = TR:GetConfigTable() }, 'Tracker')       -- tests/tracker/options_test.lua
test("SaftUI's tracker's Position resets to its default spot, and Undo takes it back", function() end)
```

- [ ] **Step 2: Run them to see them fail** — `tests/run tests/chat tests/loot tests/minimap tests/tracker/options_test.lua`.

- [ ] **Step 3: Add the `saved` fields and the `noReset`s**

- [ ] **Step 4: Run them to see them pass, then `tests/run -j2`**

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Chat/options.lua SaftUI-Loot/options.lua SaftUI-Minimap/config.lua SaftUI-Minimap/micromenuoptions.lua SaftUI-Tracker/options.lua tests/chat/theme_test.lua tests/loot/theme_test.lua tests/minimap/theme_test.lua tests/tracker/options_test.lua .agents/edit-mode.md
git commit -m "chat, loot, minimap, tracker: a reset on every row"
```

(Stage only the files the task changed.) In game: Chat's font, the loot feed's spacing, the minimap's size each reset; G7.

---

### Task 8: The coverage made strict, and the docs closed

**Files:**
- Modify: `tests/core/reset_coverage_test.lua` (`STRICT = true`).
- Docs: `docs/followups.md`: "A reset on every font row" to Resolved ("**Resolved 2026-11-15:** every font row takes its default from where it is saved (reset-every-setting, Tasks 1 to 7).") and its ToC line; `docs/design-system/10-discrepancies.md` 17: "Built (reset on every setting): every row has its own reset; the Categories editor's button and Reset all are gone."; `docs/design-system/30-code-changes.md` where it lists resets still to build; `.agents/edit-mode.md`'s line that the coverage scan is strict.

**Interfaces:**
- Consumes: every page task's walk.

- [ ] **Step 1: Set `STRICT = true` and run the coverage test**

Run: `tests/run tests/core/reset_coverage_test.lua`
Expected: PASS, every page walked. A FAIL names the page and the test file still missing its `R.check_page`.

- [ ] **Step 2: Close the docs, then `tests/run -j2`**

- [ ] **Step 3: Commit**

```bash
git add tests/core/reset_coverage_test.lua docs/followups.md docs/design-system/10-discrepancies.md docs/design-system/30-code-changes.md .agents/edit-mode.md
git commit -m "docs: every page walked for its resets; close the font row and discrepancy 17"
```

In game: G3 on two or three pages, at full and half, under Thick, Thin and Blizzard.

## Spec coverage check

| Spec section | Task |
| --- | --- |
| 1. Where a default comes from (`saved`, `st:DefaultAt`, the order of sources, hand defaults without literals) | 1; literals dropped in 2 |
| 1. A mover's Position | 1; pages' movers need nothing (6, 7 test theirs) |
| 2. What differs means | 1 |
| 3. What a reset does (through `set`, validation, a mover's Undo step, disabled rows, profile switch) | 1 |
| 4. Rows with no reset | 1 (by type, the walk); 3 (Profile, Test mode), 7 (Chat's size, Loot's Test mode), 6 (durability), 4 (the CVar) |
| 5. The icon's places and its words | 1 (titled custom row, words); 5 (the order's icon) |
| 6. The Categories' Reset buttons | 5 |
| 7. The walk and the coverage scan | 1 (lenient), 2–7 (walks), 8 (strict) |
| 8. Cost | 1 (`'the cost: ...'`) |
| 9. Docs and followups, decision 50 | 1, 5, 8 |
| In-game checks G1–G7 | 5 (G1, G4, G5), 3 (G2), 8 (G3), 4 (G6), 7 (G7) |
| Risks R1–R3 | Review Focus 1–3, tests in 1 and 3 |
