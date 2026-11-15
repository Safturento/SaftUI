# SaftUI Fonts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SaftUI's font objects become six shared fonts named for their jobs (Heading among them), and every Font row offers them first, then every typeface, with a typeface carrying that text's own size, outline, shadow and line spacing in a menu behind three dots. Every font setting applies at once through one function.

**Architecture:**
- **One value, two shapes.** A font setting holds a shared font's key (a string, as every saved value is today) or a typeface table with a shared font's own fields. `SaftUI-Core/Media/fonts.lua` reads either through one normaliser, `st:FontFields(value)`. Every other helper is built on it: `st:GetFont` (the shared object, or one typeface object per look, made once and never changed), `st:ApplyFont`, `st:FontValues`, `st:FontLabel`, `st:FaceFont`.
- **Following.** A Fonts tab change changes the shared object, so its texts follow with no code. Texts with no module to re-apply them are kept in `st:FollowFont`'s weak list. Readers that only take values re-apply from `OnFontsChanged`. `st:FontsChanged()` runs both.
- **The row.** A new kit type, `font` (`SaftUI-Core/Config/optionsfont.lua`), is a select face plus one 16 by 24 slot. The slot holds the link to the shared font (`OW:Reveal`) or the dots, which open `OW:OpenMenu` on a menu the row builds itself from `FN.FieldOptions`, the builder the Fonts tab uses.

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0; LibSharedMedia-3.0; SaftUI's options kit (`st.OptionsModel`, `st.OptionsWidgets`, `st.OptionsBody`, `st.OptionsWindow`); `tools/lucide-to-tga.cjs` (Node, `@resvg/resvg-js`) for the link icon; tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`. Its last section, "Settled with the owner after the draft (2026-11-14)", overrides anything above it:
- Settled 1 approves the design and its 27 calls.
- Settled 2: `tracker.header_font` stays one setting for the tracker's header line and zone headers, defaulting to Heading.
- Settled 3: at upgrade, Heading's face starts from Huge title's face when the profile holds a changed one (a one-time, marked step), else Colus.

The audit `docs/research/2026-11-14-fonts-audit.md` is the source for where each font is read. Line numbers there are at `e9b5197`. The spec's are at `ccfb21f`.

**Assumed state.** `modular` at `42452b9`, with the spec's Settled section added. Tracker task 6 is merged. Tracker tasks 7 to 13 and the color roles plan (from `docs/superpowers/specs/2026-11-14-saftui-color-roles-design.md`) are being built alongside this plan: see "Files shared with work in flight".

## How the tasks are cut

| # | Task | Spec phase | Needs | Owner can try in game |
| --- | --- | --- | --- | --- |
| 1 | The shared fonts and their values | 1 | — | the Fonts tab's new names and order, Heading's section, no Pixel Huge, Normal Med or Name rows |
| 2 | The Fonts tab and `/sui`'s titles | 2 | 1 | the tab's top line, notes, renamed rows and resets; `/sui`'s titles follow Heading at once (G4) |
| 3 | The font row and its list | 3 | 2 | every Font row: the two-part list, the link to the Fonts tab (G7), a typeface picked |
| 4 | The dots and their menu | 3 | 3 | a typeface's own size, outline, shadow and spacing (G8) |
| 5 | Core, Chat and Misc readers on the rule | 4 | 4 | chat as before with Font size gone (G5); Button text and Check box labels at once |
| 6 | The other readers, and the `SetFont` scan | 4 | 5 | a hotkey switched between fonts with no reload (G2); typefaces on unit frames, bags, loot, the tracker |
| 7 | Heading's defaults, and Window titles in Theme | 5 | 6 | bag category titles and the tracker in Colus 15 (G3); Theme > Window titles |
| 8 | The action bars' and buffs' font lists | 6 | 7 | shared fonts in the action bars' and buffs' Font lists, Size and Outline hidden while one is picked |

The tasks run in this order. The spec lets its phases 4 and 5 (Tasks 5 and 6, and Task 7) run either way round. Here Task 7 follows Task 6, because both edit `SaftUI-Bags/inventory.lua` and `container.lua` and `SaftUI-Misc/Skinning/addons/restedxp.lua`. Task 7 may run beside Task 5 or Task 6 if those three files are merged by hand. G6 and G1's first part are Task 1's checks. G1 is finished in Task 3, and G2 in Task 8, once the hotkey's Font row lists the shared fonts.

## Files shared with work in flight

SaftUI-Tracker is being built task by task (its plan's tasks 7 to 13 edit `init.lua`, `window.lua`, `rows.lua`, `options.lua`, `config.lua` and `tests/tracker/`). The color roles plan touches the options kit's files in `SaftUI-Core/Config/`, Global settings' Colors and Theme tabs, `Config/defaults.lua`, `Config/generators.lua`, `Media/colors.lua`, `Media/theme.lua`, `docs/design-system/` and the `.agents/` docs.

| Task | Shared with the tracker | Shared with color roles |
| --- | --- | --- |
| 1 | `SaftUI-Tracker/init.lua` (the Fonts hook becomes `TR:OnFontsChanged`), `tests/tracker/rows_test.lua` (two cases) | `SaftUI-Core/Config/defaults.lua`, `Config/generators.lua`, `Config/config.lua`, `.agents/architecture.md`, `docs/design-system/README.md`, `tokens.json`, `30-code-changes.md` |
| 2 | — | `SaftUI-Core/Config/optionsbody.lua` (`FONTS`), `optionslook.lua` (`W.UpdateFonts`), `Config/config.lua`, `.agents/edit-mode.md`, `docs/design-system/README.md`, `tokens.json` |
| 3 | `tests/tracker/window_test.lua` (its font rows change type; it should pass unchanged) | `SaftUI-Core/Config/optionslist.lua`, `optionsselect.lua`, `optionsposition.lua`, `optionsitem.lua`, `optionsshare.lua`, `optionswindow.lua`, `generators.lua`, `load.xml`, `tests/lib/shell.lua`, `tests/lib/options_walk.lua`, `.agents/edit-mode.md`, `.agents/testing.md`, `docs/design-system/components/Icons/README.md`, `components/Select/README.md` |
| 4 | — | `SaftUI-Core/Config/optionsmenu.lua`, `.agents/edit-mode.md` |
| 5 | — | `SaftUI-Core/Config/optionswindow.lua`, `SaftUI-Core/panels.lua`, `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua` |
| 6 | `SaftUI-Tracker/rows.lua`, `window.lua`, `tests/tracker/rows_test.lua`, `window_test.lua` | `SaftUI-Bags/slot.lua`, the Loot files (`roll.lua`, `rollbar.lua`, `Feed/feed.lua`) |
| 7 | `SaftUI-Tracker/config.lua`, `tests/tracker/window_test.lua`, `rows_test.lua` | `SaftUI-Core/Media/theme.lua` (Accent lands before Options windows; Window titles after it), `tests/core/theme_tab_test.lua` (its row-order assertion) |
| 8 | — | `docs/followups.md` |

Where both touch a file, merge by hand and keep both sides. The font row paints its slot with the item's own dots painter (Ruling 12), so the color roles' change to the dots' colors reaches the font row with no second edit.

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder changes.
- **Privacy.** No account, realm or character name anywhere: code, tests, docs, commits.
- **Commits.** Lowercase `module: imperative summary`. Stage by explicit path, never `git add -A`, `.` or a folder. End with the session's `Co-Authored-By` line.
- **Line endings.** Some working-tree files are CRLF. Never `sed -i`. Edit with the editor and keep each file's endings (`file <path>`).
- **Words.** Sentence case for every name, label and desc, in American spelling. Name a path with ">": "Global settings > Fonts".
- **Resets.** Per setting (the option's `default` field), never a section's or a page's Reset button.
- **Icons.** Lucide's (`st.icons`), drawn at twice the glyph. An icon-only control always has a tooltip.
- **Scripts.** Kit controls (`W.Button`, `W.IconButton`, `W.IconLink`, `W.SelectFace`, `Kit.NewSlot`) take `control.onClick`, never `SetScript('OnClick')`. The game calls `OnEnter` and `OnLeave` with a second argument, `motion`: wrap each as `function(self) ... end`, and fire hover scripts in tests with `true`.
- **Whole pixels.** Every size and offset through `st:RoundToPixel`; a size read back is rounded, never ceiled (a text's width may be `ceil`). Every new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard with `stub.size_noise` at `2 ^ -14`, `-2 ^ -14` and `0`.
- **No `SetFont` on a text SaftUI keeps** (the spec's anti-goal and rule 1). A text gets its font from `st:ApplyFont`, or from `SetFontObject(st:FontObject(value))` where the code must compare objects (Ruling 2). From Task 6 `tests/core/setfont_scan_test.lua` enforces it.
- **Font objects.** Only `CreateFont` objects SaftUI makes and keeps; never one the game made (`.agents/taint.md` rule 10). A shared font's object is never changed by one text's settings.
- **No menu inside a menu.** A font row inside an item's menu is `faceOnly` and has no dots.
- **Both clients.** Every task's tests run on `T.client('forever')` and `'retail'` where they touch a reader that differs. Nothing here is client-specific.
- **Tests.** Each task ends green on `tests/run -j2`, and runs single files while working. An earlier assertion changes only where this work changes what it pins, and the report lists each one changed.
- **Docs.** Each task updates the docs its files make stale, in the same commit: `AGENTS.md`, the `.agents/*.md` whose `covers:` list its files, and `docs/design-system/`. Then it runs `agents-doc-parity-check` and `readme-freshness-check`. A task that changes `docs/design-system/` says so in its report: the controller republishes the Design System artifact.
- **In game.** Each task ends with its in-game checklist for the owner. Nothing counts as verified until he confirms it.

## Review Focus

1. **A typeface whose face LibSharedMedia no longer lists**, for example the face of an addon since removed. It draws in LibSharedMedia's default face with no error. The row reads the saved name in the field font, no typeface in the list is blue, and picking another face works. Tests: Task 1 `'a face LibSharedMedia does not list'`, Task 3 `'a typeface LibSharedMedia does not list'`.
2. **A typeface table with fields of the wrong type or out of range**, from an import or a hand edit: `font_size = '12'`, `font_size = 0`, `shadow_offset = 3`, `font_outline = 'BOLD'`. Each such field reads as the base's (Text's default), sizes are clamped to the rows' ranges, one object is made, and nothing errors. The dots menu shows the clamped values. Test: Task 1 `'a malformed typeface'`.
3. **Chat's conversion on an odd profile.** Three cases: `chat.font` names a dropped font (a player who picked Normal Med for chat); it names a key that no longer exists; Text's size or shadow was changed while Font size stayed at its default. Chat keeps the look it drew, as a typeface, or follows Text when that look is Text's. Nothing errors, and a second run changes nothing. Test: Task 5 `'chat on odd profiles'`.
4. **The value changing under an open dots menu.** Its row's reset, a profile switch, a Copy from, or the page redrawn with the row gone. The menu closes when the value is no longer a typeface, follows the new typeface when it still is one, and never writes a copy of a stale table. Test: Task 4 `'the value changing under an open menu'`.
5. **A Size drag across the menu's whole range on a unit frame page.** One typeface object per size passed, the same one again when the drag comes back over a size, and one re-apply of the element per step. Test: Task 4 `'a drag across the range'`.

## Rulings on the spec

1. **Helper names** (the spec leaves them to the builder):
   - `st:FontFields(value)` is the one normaliser every other helper reads (table below).
   - `st:FontObject(value)` is `st:GetFont(value)` or Text's object. It serves readers that need an object rather than a text: a button's normal font object, Blizzard's tracker's `Font(kind)`, the tracker's own diffing.
   - Also `FN:Font(key)`, `FN.FieldOptions`, `FN.FontSettingDefault` and `FN:ConvertHeadingFace`.
2. **`st:ApplyFont(fs, value)` is `fs:SetFontObject(st:FontObject(value))`**, with no skip when the object is the same. The unit frames put a custom text color back after it. SaftUI-Tracker's rows keep their own changed-only `SetFontObject(FontOf(role))` (`rows.lua`), with `FontOf` through `st:FontObject`, so an idle refresh still calls no setter (its refresh rule).
3. **`st:FontFields(value)` rules.**

   | value | base | overlay |
   | --- | --- | --- |
   | a key in `FN.FONTS` | `st.defaults.fonts[key]` | `st.config.profile.fonts[key]` |
   | a key in `FN.DROPPED` | `FN.DROPPED[key]` | `rawget(st.config.profile.fonts, key)` when it is a table |
   | a table | `st.defaults.fonts.normal` | the table |
   | anything else (nil, an unknown key, a number) | `st.defaults.fonts.normal` | `st.config.profile.fonts.normal` |

   An overlay field is taken only when it is valid, else the base's:
   - `font_name`: a non-empty string;
   - `font_size`: a number, then `st.Clamp(n, 1, 100)`;
   - `font_outline`: a key of `FN.outlines`;
   - `shadow_offset`: a table whose `[1]` and `[2]` are numbers, each `st.Clamp(n, -5, 5)`;
   - `spacing`: a number, then `st.Clamp(n, 0, 20)`.

   It returns a fresh table every call, and never writes to the profile.
4. **Heading's face step (Settled 3).**
   - `FN:ConvertHeadingFace()` runs in `FN:OnEnable` and first in `FN:UpdateConfig`, before the objects are set, so the profile update's fonts step covers a switch, a copy, a reset and an import.
   - It runs only while `fonts.version` is nil. If `fonts.title.font_name` is a string other than `st.defaults.fonts.title.font_name` and `fonts.heading.font_name` is still `st.defaults.fonts.heading.font_name`, it copies the face to Heading. Then it sets `fonts.version = 1` (no default), and returns whether it ran.
   - Only the face moves: the owner's words name the face, so Huge title's outline is not carried.
   - It lands in Task 1 with Heading, before anything reads Heading.
5. **`st:FontsChanged()`** runs `st:RefollowFonts()`, then every module's `OnFontsChanged()` in `xpcall` to `geterrorhandler()`. It is called by every set and reset on the Fonts tab (a shared font's rows and Kinds of text), by Theme > Window titles (Task 7), and by `Config:UpdateConfig` right after its fonts step. A module whose `OnFontsChanged` reads a profile it converts runs its conversion first (chat, Task 5), because the profile update calls it before the modules' `UpdateConfig`.
6. **The totem timers' post-hook on `FN:UpdateFontConfig`** (`SaftUI-Misc/totemtimers.lua`) moves to `TB:OnFontsChanged()` with the tracker's, so no code hooks `UpdateFontConfig`.
7. **Chat keeps Blizzard's line spacing.** This is where the spec contradicts the code. The spec has chat take `st:FontValues` "whole", but Blizzard's chat frames draw at line spacing 0 (`ChatFontNormal` sets none) while Text's is 4. "Whole" would widen every chat's line gaps at upgrade, against G5, and make the conversion always write a table.
   - Chat takes the face, size, outline and shadow (offset, and opaque black), and leaves spacing alone, as the tooltip does (the spec's non-goal). The conversion compares size and shadow only, as the spec says.
   - `generators.font` takes `opts.fields`: the dots-menu rows its reader applies. Chat's row passes `{ 'font_size', 'font_outline', 'shadow_x', 'shadow_y' }`, the tooltip's `{ 'font_size', 'font_outline' }`, and every other row all five. This narrows call 12 for those two rows only, so no row in a menu does nothing. The owner should confirm it.
8. **The color picker's title follows through `CP:OnFontsChanged()`** (it styles its texts again, as its `UpdateConfig` does), not through `st:FollowFont`. The skin puts Blizzard's font back when it is off, and a follower would undo that. `SK:OnFontsChanged()` hands the call to Skinning's submodules, as `SK:OnColorsChanged` does.
9. **Button text follows through `st:SkinActionButton(button, nil, kind)`.** A nil config already means Core's `buttons` settings. Only then does it keep its texts with `st:FollowFont(region, function() return st.config.profile.buttons.font end)`. The bags' bag slot bars and bank bag slots (`containers/bag.lua:134`, `bank.lua:60`) pass nil instead of `st.config.profile.buttons`.
10. **The check button's helper `button.SetFont`** (`Widgets/checkbutton.lua`, called once at `SaftUI-Bags/header.lua:172`) becomes `button.SetTextFont`, so the scan needs no exception for a method that isn't a font string's.
11. **The row's sizes.** The slot is 16 by 24 at the widget's right edge. The dropdown (`W.SelectFace`, 170 by 24) ends `FONT_SLOT_GAP` left of it: 4 under Thick and Thin, and 8 under Blizzard, whose dropdown art reaches 7 past the face. `W.WIDTH.font` is 190, and the widget's own width is 194 under Blizzard (set on each bind). The slot's room is kept when it is empty.
12. **The slot is the item's dots, shared.** `optionsitem.lua` exports its dots as `Kit.NewSlot(parent, icon)` and `Kit.PaintSlot(button, over)`. The item and the font row both use them, so the dots and the link look alike and change together.
13. **`OW:OpenMenu(widget)`** opens `widget:Menu()` when the widget has one, else the row's `option.menu`. `FollowMenu` asks the widget again on every render and closes the menu when it returns nil.
14. **The dots come in Task 4.** In Task 3 a typeface leaves the slot empty, so there is no control that does nothing.
15. **The list draws per entry.** An entry with `font` is drawn in it at 15 with no outline. A caption is drawn in `OB.Font('group')`, set outright: `SetFontObject(object)`, then `SetFont(object:GetFont())`, so it keeps that object and drops a pooled row's last face. Any other entry is drawn in the field font. `W.OpenList`'s fifth argument (`fontMode`) goes, and `optionsselect.lua` and `optionsposition.lua` stop passing it.
16. **Typeface keys in the list are `'face:' .. name`.** Shared fonts keep their key. A typeface value (a table, a dropped key, a `faceOnly` face name) shows `'face:' .. <its face>` blue.
17. **The action bars' texts** lose their forced `SetShadowOffset(0, 0)` (as the totem bar's do, call 20). The typeface `st:FaceFont` builds has shadow 0, 0 unless set, and so does Small text. The hotkey's and macro name's heights come from the size `st:FontValues` gives.
18. **The cooldown numbers' value** is `AB:CountdownValue(config)`. While the bar sets none of font, size and outline, it is the shared font by button size (`pixel_med` at 36 and up, else `pixel`). Otherwise it is `st:FaceFont(AB:GetCountdownFont(config))`. In Task 8 the Font row shows the shared font only while none of the three is set. With a size or an outline set but no font, it shows the face it draws, as today, with Size and Outline shown.
19. **The spec's phase 4 is split** into Core, Chat and Misc (Task 5), then the rest with the scan (Task 6). The bags' footer texts and search box keep their current reads until Task 7 moves them to Text.
20. **The kit type** is a built-in one: `SaftUI-Core/Config/optionsfont.lua`, loaded after `optionscolorpicker.lua` and before `optionsposition.lua`, which records the built-in types. It uses `W.SelectFace`, `W.LookSelectFace` and `W.ShowTip`.
21. **`Config:OnFontsChanged()`** runs `st.OptionsBody.UpdateFonts()` when that is loaded, which is what `OW:UpdateFonts()` does, so a body-only test world follows too.
22. **Kinds of text keeps its "reload" note until Task 5**, which makes Button text and Check box labels follow at once. Window titles keeps calling `st:UpdateHeader()` until Task 5 makes the titles follow.
23. **The preload.** `SaftUI-Core/Media/sharedmedia.lua` registers SaftUI's faces through a local `Face(name, file)`, which also appends the name to `st.SAFTUI_FACES`. `fonts.lua`, loaded next, sets each on a font object `SaftUI_Preload<n>Font` at file load (`FN.preloaded[name]`). The font demo's own preload stays.
24. **`st:IsSharedFont(value)`** is true only for a key in `FN.FONTS`: a dropped key is a typeface. `st:FaceFont(font, size, outline)` returns `font` when `st:IsSharedFont(font)`, else `{ font_name = font, font_size = size, font_outline = outline }`.
25. **`st:FontLabel(value)`**:
    - a shared font: its name;
    - a typeface (a table or a dropped key): `'<face> <size>'`, plus `', ' .. FN.outlines[outline]:lower()` unless the outline is `NONE` ("Colus 15, outline", "Homespun 10");
    - anything else: `'Text'`.
26. **Defaults of font rows** use `FN.FontSettingDefault(read, write, default)`: `differs` is any value but the default (a table always differs); `reset` writes the default and runs `st:FontsChanged()`; `text` is `st:FontLabel(default)`. The kit's reset tooltip gets a `font` branch in `optionsshare.lua`'s `DefaultText` (`st:FontLabel(value)`), so `TR.SettingDefault`'s rows name Heading with no change to the tracker.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Media/fonts.lua` | the shared fonts, the dropped ones, the value helpers, typeface objects, following, `FontsChanged`, the preload, Heading's step; the Fonts tab and its field rows | 1, 2, 5, 7 |
| `SaftUI-Core/Config/defaults.lua` | `st.defaults.fonts` | 1 |
| `SaftUI-Core/Media/sharedmedia.lua` | faces registered and listed for the preload | 1 |
| `SaftUI-Core/Config/config.lua` | `FontsChanged` in the profile update; `Config:OnFontsChanged` | 1, 2 |
| `SaftUI-Core/Config/optionsbody.lua`, `optionslook.lua` | `/sui`'s fonts from Heading and Text | 2 |
| `SaftUI-Core/Config/optionsfont.lua` (new), `load.xml` | the `font` type | 3, 4 |
| `SaftUI-Core/Config/optionslist.lua`, `optionsselect.lua`, `optionsposition.lua` | per-entry list fonts | 3 |
| `SaftUI-Core/Config/optionsitem.lua` | the shared slot | 3 |
| `SaftUI-Core/Config/optionsshare.lua`, `optionswindow.lua`, `generators.lua` | share kind and reset text; `OW:Reveal`; `generators.font` | 3 |
| `SaftUI-Core/Config/optionsmenu.lua` | a widget's own menu | 4 |
| `SaftUI-Core/constants.lua`, `Media/Textures/lucide-link.tga` (new) | `st.icons.link` | 3 |
| `SaftUI-Core/Widgets/*.lua`, `skinning.lua`, `panels.lua` | Core's readers and followers | 5 |
| `SaftUI-Chat/*` | chat's conversion and reader | 5 |
| `SaftUI-Misc/*` (tooltip, totems, skins, RestedXP, buffs) | Misc's readers | 5, 7, 8 |
| Bags, Loot, Tracker, Unitframes, ActionBars readers | `st:ApplyFont` | 6 |
| `SaftUI-Core/Media/theme.lua` | Theme > Window titles | 7 |
| `SaftUI-ActionBars/textoptions.lua`, `skin.lua`, `options.lua` | the `faceOnly` rows | 8 |
| `tests/core/fonts_model_test.lua`, `options_font_test.lua`, `setfont_scan_test.lua`, `tests/chat/font_test.lua`, `tests/misc/font_readers_test.lua`, `tests/bags/fonts_test.lua` (new) | the tests | 1, 3–7 |

---

### Task 1: The shared fonts and their values

**Files:**
- Modify:
  - `SaftUI-Core/Media/fonts.lua`:
    - `FN.FONTS`, `FN.DROPPED`, `FN:Font`, `FN:SetObject` and `FN:UpdateFontConfig` over `FN.FONTS`;
    - objects named `SaftUI_<key>Font`, and the typeface objects;
    - every `st:` helper below, the preload, and `FN:ConvertHeadingFace` in `OnEnable` and `UpdateConfig`;
    - in `FN:GetConfigTable`, the sections walk `FN.FONTS` with the names from code and `order = i + 1`, and the Name row goes. The rest of the tab is Task 2.
  - `SaftUI-Core/Config/defaults.lua`: `st.defaults.fonts` loses every `name`, gains `heading`, and drops `pixel_huge` and `normal_med`.
  - `SaftUI-Core/Media/sharedmedia.lua`: font registrations through `Face(name, file)` (Ruling 23).
  - `SaftUI-Core/Config/generators.lua`: `st.Config:GetFontObjects()` walks `FN.FONTS`; `generators.font` gains `sorting`, the keys in `FN.FONTS` order.
  - `SaftUI-Core/Config/config.lua`: `Config:UpdateConfig` runs `Safely(function() st:FontsChanged() end)` right after `UpdateModule(fonts)`.
  - `SaftUI-Core/Media/fonts.lua`'s Fonts tab sets (the existing `set` and `ShadowOffset`'s) and Kinds of text's `set` call `st:FontsChanged()` after their apply.
  - `SaftUI-Tracker/init.lua`: the `hooksecurefunc(fonts, 'UpdateFontConfig', ...)` block becomes `TR:OnFontsChanged()`.
  - `SaftUI-Misc/totemtimers.lua`: its hook becomes `TB:OnFontsChanged()`.
  - `SaftUI-ActionBars/textoptions.lua` (`CountdownDefault`'s sentence), and the comments naming Pixel or Pixel Med in `SaftUI-ActionBars/config.lua` and `skin.lua`.
- Test:
  - Create `tests/core/fonts_model_test.lua`, on `core/config_helpers.lua`'s real AceDB.
  - Modify `tests/core/fonts_tab_test.lua` (six sections, no Name row, `normal_med` replaced by `pixel_med`, `pairs(profile.fonts)` loops over `FN.FONTS`).
  - Modify `tests/lib/harness_self_test.lua` (`apply_defaults` cases) and `tests/actionbars/page_test.lua` (the strings at 474 and 779).
  - Modify `tests/tracker/rows_test.lua`: the cases at 822 and 981 call `st:FontsChanged()` where they relied on the hook.
- Docs:
  - `.agents/architecture.md`:
    - the Styling bullet's `st:GetFont` becomes a Fonts bullet: the two shapes, the helpers, the rule for readers, `st:FontsChanged` beside `st:ColorsChanged`;
    - the tracker paragraph's "post-hook on the Fonts module's `UpdateFontConfig`" becomes `TR:OnFontsChanged`;
    - "A module that converts its profile once" gains `fonts.version`.
  - `.agents/edit-mode.md`: the Fonts tab line (sections from `FN.FONTS`, names in code, no Name row).
  - `.agents/testing.md`: the `tests/core/` row gains `fonts_model_test.lua`.
  - `docs/design-system/README.md`: the line naming the faces' objects "(Title, Normal, Pixel)" uses the new names.
  - `tokens.json`: "The Title object" becomes "Huge title".
  - `30-code-changes.md`: Code change 3 gains "Taken up by the fonts design (`docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`, plan `docs/superpowers/plans/2026-11-14-saftui-fonts.md`)."

**Interfaces:**
- Produces:

```lua
FN.FONTS = { -- the order of the Fonts tab and of every list; job: the spec's Job column, word for word
	{ key = 'normal',    name = 'Text',          job = '...' },
	{ key = 'pixel',     name = 'Small text',    job = '...' },
	{ key = 'pixel_med', name = 'Large numbers', job = '...' },
	{ key = 'heading',   name = 'Heading',       job = '...' },
	{ key = 'title',     name = 'Huge title',    job = '...' },
	{ key = 'subtitle',  name = 'Subtitle',      job = '...' },
}
FN.DROPPED = {
	pixel_huge = { font_name = 'Homespun', font_size = 32, font_outline = 'MONOCHROMEOUTLINE', shadow_offset = { 0, 0 }, spacing = 4 },
	normal_med = { font_name = 'AgencyFB Bold', font_size = 24, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 },
}
st.defaults.fonts.heading = { font_name = 'Colus', font_size = 15, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
```

  - `FN:Font(key) -> entry | nil`.
  - `FN:SetObject(object, fields)`, where `fields` has `st:FontFields`' shape. It does what `UpdateFontConfig` does today: the face from LibSharedMedia, size, `st.OutlineFlag`, an opaque black shadow, the offset, spacing, then the size one up and back.
  - `FN:UpdateFontConfig(key | nil)`: nil walks `FN.FONTS`.
  - `FN:ConvertHeadingFace() -> boolean` (Ruling 4).
  - `FN.preloaded = { [faceName] = object }` and `st.SAFTUI_FACES = { name, ... }`, the 15 faces in registration order.
  - `st:FontFields(value) -> { font_name, font_size, font_outline, shadow_offset = { x, y }, spacing }` (Ruling 3).
  - `st:GetFont(value) -> object | nil`:
    - a shared key: its object;
    - a dropped key or a table: the typeface object for its look, one per distinct `FontFields` look, named `SaftUI_Typeface<n>Font`, white, never set again;
    - anything else: nil.
  - `st:FontObject(value) -> object`, `st:ApplyFont(fs, value)` (Ruling 2), `st:FontValues(value) -> path, size, flags, shadowX, shadowY, spacing`, `st:FontLabel(value) -> string` (Ruling 25), `st:IsSharedFont(value) -> boolean` and `st:FaceFont(font, size, outline) -> string | table` (Ruling 24).
  - `st:FollowFont(region, getValue)`: keeps `region -> getValue` in a weak-keyed table and applies `getValue()` at once. A nil `getValue` forgets the region.
  - `st:RefollowFonts()`: each kept region again, each in `xpcall`.
  - `st:FontsChanged()` (Ruling 5).
  - `TR:OnFontsChanged()` is `if TR.model then TR:MarkDirty('FONTS') end`, in `init.lua`. `TB:OnFontsChanged()` is `if timersReady then self:ApplyTimerLayout() end`, in `totemtimers.lua`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/fonts_model_test.lua (load_test_file('core/config_helpers.lua'))
local function path(name) return st.LSM:Fetch('font', name) end
test('six shared fonts in order, named in code, objects named by key; a saved name is ignored', function()
	-- keys of FN.FONTS: normal,pixel,pixel_med,heading,title,subtitle; names: Text,Small text,Large numbers,Heading,Huge title,Subtitle
	-- st:GetFont('heading'):GetName() == 'SaftUI_headingFont'; profile.fonts.normal.name = 'Mine' -> st:FontLabel('normal') == 'Text'
	-- st.defaults.fonts.pixel_huge == nil; st.defaults.fonts.normal.name == nil
end)
test('Heading ships as Colus 15, Outline, shadow 0, 0, line spacing 4', function()
	-- {st:GetFont('heading'):GetFont()} == path('Colus'), 15, 'OUTLINE'; GetShadowOffset 0,0; GetSpacing 4
end)
test('strings: a shared key is its object, a dropped key its old look, anything else nil', function()
	-- st:GetFont('pixel') == FN.font_objects.pixel
	-- {st:GetFont('pixel_huge'):GetFont()} == path('Homespun'), 32, 'MONOCHROMEOUTLINE'; normal_med: AgencyFB Bold, 24, OUTLINE
	-- st:GetFont('nope'), st:GetFont(nil), st:GetFont(12) == nil
end)
test("a dropped key with saved edits: its old look with the profile's fields over it; nothing written", function()
	-- profile.fonts.pixel_huge = { font_size = 40 } -> st:FontFields('pixel_huge').font_size == 40, .font_name == 'Homespun'
	-- next(profile.fonts.pixel_huge) has only font_size; FN:UpdateFontConfig() errors on nothing and makes no object for it
end)
test('a typeface table: one object per look, white, made once and never changed', function()
	-- a = st:GetFont({ font_name = 'Colus', font_size = 15 }); b = the same with every field written out -> a == b
	-- c = st:GetFont({ font_name = 'Colus', font_size = 16 }) ~= a; select(2, a:GetFont()) still 15; a:GetTextColor() == 1, 1, 1
	-- a:GetName():match('^SaftUI_Typeface%d+Font$')
end)
test('the size nudge, one up and straight back, on a shared update and on a new typeface', ...)
test('a malformed typeface (Review Focus 2)', function()
	-- { font_name = 'Colus', font_size = '12' } -> font_size 16 (Text's default); { font_size = 0 } -> 1; { font_size = 400 } -> 100
	-- { shadow_offset = 3 } -> { 0, 0 }; { shadow_offset = { 9, -9 } } -> { 5, -5 }; { font_outline = 'BOLD' } -> 'OUTLINE'; { font_name = '' } -> 'AgencyFB Bold'
	-- st:GetFont of each is one object per resulting look; #take_errors() == 0
end)
test('a face LibSharedMedia does not list (Review Focus 1)', function()
	-- st:FontValues({ font_name = 'Gone' }) == st.LSM:Fetch('font', st.LSM:GetDefault('font')), 16, 'OUTLINE', 0, 0, 4
	-- st:FontLabel({ font_name = 'Gone', font_size = 12 }) == 'Gone 12, outline'
end)
test('FontValues, FontLabel, IsSharedFont, FaceFont', function()
	-- st:FontValues('normal') == path('AgencyFB Bold'), 16, 'OUTLINE', 0, 0, 4
	-- labels: 'heading' -> 'Heading'; { font_name = 'Colus', font_size = 15 } -> 'Colus 15, outline'
	--   { font_name = 'Homespun', font_size = 10, font_outline = 'NONE' } -> 'Homespun 10'; 'pixel_huge' -> 'Homespun 32, monochrome outline'; nil -> 'Text'
	-- st:IsSharedFont('pixel') true, 'pixel_huge' false, {} false
	-- st:FaceFont('pixel', 9, 'NONE') == 'pixel'; st:FaceFont('Colus', 12, 'OUTLINE') is { font_name = 'Colus', font_size = 12, font_outline = 'OUTLINE' }
end)
test('ApplyFont draws Text for nil, an unknown key and a number, and never errors', ...)
test('FollowFont applies at once and again on RefollowFonts, reading the getter then; nil forgets; a region kept twice keeps the last', ...)
test("FontsChanged: the followers first, then every module's OnFontsChanged; one that errors is reported and the rest still run", ...)
test('a profile switch runs FontsChanged after the fonts step, with the new profile in place', ...)
test("Heading's face: Huge title on another face gives it to Heading once, and the profile is marked", function()
	-- profile.fonts.title.font_name = 'Bebas Neue'; profile.fonts.version = nil; FN:UpdateConfig()
	-- heading.font_name == 'Bebas Neue'; fonts.version == 1; then title -> 'Righteous', FN:UpdateConfig(): heading stays 'Bebas Neue'
end)
test("Heading's face: Huge title at Colus, or Heading already set, leaves Heading; marked either way", ...)
test('a profile switched to, copied or reset takes the step on its first load; a reset profile is marked again', ...)
test('AceDB keeps a typeface table under a string default across a profile switch and back, with no keys added', function()
	-- profile.headers.font = { font_name = 'Colus', font_size = 15 }; SetProfile('B'); SetProfile(first)
	-- the table's keys are exactly font_name and font_size
end)
test('every face SaftUI registers is preloaded on a font object of its own at load', function()
	-- #st.SAFTUI_FACES == 15; for each name, FN.preloaded[name]:GetFont() == path(name)
end)
-- tests/lib/harness_self_test.lua
test('apply_defaults keeps a table saved under a string default and merges no ** defaults into it', function()
	-- st.defaults = { a = { font = 'normal', count = { font = 'pixel' }, ['**'] = { filter = { on = true } } } }
	-- profile a.font = { font_name = 'Colus' }, a.count.font = { font_name = 'Homespun' } -> both the same tables, one key each
	-- a.count.filter.on == true, as today
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/fonts_model_test.lua tests/lib/harness_self_test.lua`. Expected: FAIL, `FN.FONTS` is nil.
- [ ] **Step 3: Implement** as the Interfaces and Rulings 1 to 6 and 23 to 25 say. Update the assertions in `fonts_tab_test.lua`, `page_test.lua` ("Large numbers' <field> on buttons of 36px and up, Small text's below (Global settings > Fonts)") and `rows_test.lua`.
- [ ] **Step 4: Run** `tests/run tests/core tests/tracker/rows_test.lua tests/actionbars/page_test.lua tests/misc`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Media/fonts.lua SaftUI-Core/Config/defaults.lua SaftUI-Core/Media/sharedmedia.lua SaftUI-Core/Config/generators.lua SaftUI-Core/Config/config.lua SaftUI-Tracker/init.lua SaftUI-Misc/totemtimers.lua SaftUI-ActionBars/textoptions.lua SaftUI-ActionBars/config.lua SaftUI-ActionBars/skin.lua tests/core/fonts_model_test.lua tests/core/fonts_tab_test.lua tests/lib/harness_self_test.lua tests/actionbars/page_test.lua tests/tracker/rows_test.lua .agents/architecture.md .agents/edit-mode.md .agents/testing.md docs/design-system/README.md docs/design-system/tokens.json docs/design-system/30-code-changes.md
git commit -m "core: name the shared fonts for their jobs, add Heading, and read a font setting's two shapes"
```

**In-game checks:**
- On both clients, log in with no Lua errors.
- The Fonts tab lists Text, Small text, Large numbers, Heading, Huge title and Subtitle, in that order, with no Pixel Huge, Normal Med or Name rows.
- G6: the zone name is Huge title at 72, with its subtitle lines as before.
- G1, first part: from `/run`, `SaftUI:GetFont({ font_name = 'Righteous', font_size = 20 })` on a unit frame's name (`SetFontObject`) draws at once. Repeat with a face another addon registers. If one doesn't draw, note it for Task 3's check of G1.

---

### Task 2: The Fonts tab and `/sui`'s titles

**Files:**
- Modify:
  - `SaftUI-Core/Media/fonts.lua`: the tab as the spec's "The Fonts tab after the change" says, except that Kinds of text keeps Window titles until Task 7 and its reload note until Task 5. Also `FN.outlines` in sentence case, `FN.FieldOptions` and `FN.FontSettingDefault`. Button text's desc also names the bag slot bars and the bank's bag slots.
  - `SaftUI-Core/Config/optionsbody.lua`: `FONTS`' `title`, `brand`, `section`, `group`, `caption` and `mini` read `'heading'`, the rest `'normal'`. `ApplyFont` takes the path and flags from `st:FontValues(face)`.
  - `SaftUI-Core/Config/optionslook.lua`: `W.UpdateFonts` from `st:FontValues('normal')`.
  - `SaftUI-Core/Config/config.lua`: `Config:OnFontsChanged()` (Ruling 21).
- Test: modify `tests/core/fonts_tab_test.lua` (most of it; it also loads `load_options_widgets()` and `optionsbody.lua` for `/sui`'s fonts) and `tests/actionbars/page_test.lua:555` ('Monochrome outline').
- Docs:
  - `.agents/edit-mode.md`: the Fonts tab bullet; "The fonts are the window's own objects with the profile's title and normal faces" becomes Heading's and Text's; the header's "Colus 34" becomes "Heading's face, 34".
  - `docs/design-system/README.md`: the Type table's title rows read "Heading's face (Colus)".
  - `tokens.json`: the Titles family's note ("Colus, the profile's Title face") becomes Heading's face.
  - Any other `docs/design-system/` page that says `/sui`'s titles take Colus or the Title face: `grep -rn "Title face\|Colus" docs/design-system`.

**Interfaces:**
- Consumes: Task 1's `FN.FONTS`, `st:FontValues`, `st:FontLabel`, `st:FontsChanged`.
- Produces:
  - `FN.FIELDS = { 'font_size', 'font_outline', 'shadow_x', 'shadow_y', 'spacing' }`.
  - `FN.FieldOptions(read, write, subject, fields) -> { [field] = option }`, built once and used by the tab and Task 4's menu. The options are orders 2 to 6:
    - Size, `range` 1 to 100 step 1;
    - Outline, `select` of `FN.outlines`, with `sorting` in the outline list's order;
    - Shadow offset X and Shadow offset Y, `range` -5 to 5;
    - Line spacing, `range` 0 to 20.

    `read(field) -> value` and `write(field, value)` take the field's name: `shadow_x` and `shadow_y` are the two numbers of `shadow_offset`. `subject` is `'shared'` (the tab's descs, as today's, "every text that uses this font") or `'text'` (the spec's menu descs, word for word). `fields` (nil for all five) leaves out the rest.
  - `FN.FontSettingDefault(read, write, default) -> option.default` (Ruling 26).
  - `FN.outlines = { NONE = 'None', OUTLINE = 'Outline', THICKOUTLINE = 'Thick outline', MONOCHROME = 'Monochrome', MONOCHROMEOUTLINE = 'Monochrome outline', MONOCHROMETHICKOUTLINE = 'Monochrome thick outline' }`.
  - The tab:
    - `intro`: a description at order 0, the spec's line word for word.
    - Each shared font's section: `args[key]`, inline, `order = i`, `name` its name, `desc` its job.
    - Each section's rows: `font_name` (Typeface, `dialogControl = 'LSM30_Font'`, desc "The typeface of every text that uses this font."), then `FN.FieldOptions(..., 'shared')`.
    - Every row's `default` compares against `st.defaults.fonts[key][field]` (one index of `shadow_offset` for X and Y).
    - Every set and reset runs `FN:UpdateFontConfig(key)`, then `st:FontsChanged()`.
    - `kinds` is last (`order = #FN.FONTS + 1`). Its rows get `FN.FontSettingDefault`: Window titles to `'normal'`, Button text to `'pixel'`, Check box labels to `'normal'`.
  - `Config:OnFontsChanged()`.

- [ ] **Step 1: Write the failing tests** (in `tests/core/fonts_tab_test.lua`)

```lua
test('the tab: the line at the top, the six fonts in FN.FONTS order with their jobs as notes, Kinds of text last', function()
	-- OM.BuildView(...).sections titles: '' (the intro), 'Text', 'Small text', 'Large numbers', 'Heading', 'Huge title', 'Subtitle', 'Kinds of text'
	-- each font section's note is its FN.FONTS job; the intro's text is the spec's line
end)
test("each font's rows: Typeface, Size, Outline, Shadow offset X, Shadow offset Y, Line spacing; no Name", ...)
test('the outline names in sentence case, in the list order None ... Monochrome thick outline', ...)
test("every row resets by itself while it differs from st.defaults.fonts, putting the default on its object at once", function()
	-- Set('pixel', 'font_size', 12): OM.DefaultState differs; OM.DefaultReset -> profile 10, select(2, st:GetFont('pixel'):GetFont()) == 10
	-- Set('pixel', 'shadow_x', 2) differs while shadow_y does not; the tooltip names the default ('Size goes back to its default: 10.')
end)
test('a set reaches its object at once and runs st:FontsChanged once', ...)
test("Kinds of text: Window titles, Button text, Check box labels, each with its reset; Button text's desc names the bag slot bars and the bank's bag slots", ...)
test("/sui's titles take Heading's face and outline at their own sizes; tabs, labels and the small line Text's", function()
	-- OB.Font('section'):GetFont() == path('Colus'), 15, 'OUTLINE'; title 34, brand 26, mini 18, group 13, caption 11
	-- OB.Font('label'):GetFont() == path('AgencyFB Bold'), 16, 'OUTLINE'; W.GetFont() at 15 in AgencyFB Bold
end)
test("Heading's face changed on the tab reaches /sui's titles at once; its size doesn't", function()
	-- Set('heading', 'font_name', 'Bebas Neue') -> OB.Font('title') path('Bebas Neue'), 34; Set('heading', 'font_size', 24) -> OB.Font('section') size 15
end)
-- kept: 'after a profile switch, the rows reach the new profile ...'; 'a font saved with the outline NONE ...'
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/fonts_tab_test.lua`. Expected: FAIL on the section order (Kinds of text comes first today).
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/core tests/actionbars`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Media/fonts.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/Config/optionslook.lua SaftUI-Core/Config/config.lua tests/core/fonts_tab_test.lua tests/actionbars/page_test.lua .agents/edit-mode.md docs/design-system/README.md docs/design-system/tokens.json
git commit -m "core: lay out the Fonts tab by job with per-setting resets, and draw /sui's titles in Heading's face"
```

**In-game checks:**
- The Fonts tab: the line at the top, the sections in order with their notes, the renamed rows, the outline names in sentence case, and a reset icon on a changed row.
- G4: Heading's face changed on the tab reaches `/sui`'s page title, section titles and sidebar group titles at once, with nothing clipped, under Thick, Thin and Blizzard. Heading's size leaves them as they are.
- If Huge title's face was changed on this profile before the upgrade, `/sui`'s titles still show it (Task 1's step).

---

### Task 3: The font row and its list

**Files:**
- Create:
  - `SaftUI-Core/Config/optionsfont.lua`: the `font` type (Ruling 20).
  - `SaftUI-Core/Media/Textures/lucide-link.tga`, made in Step 3.
- Modify:
  - `SaftUI-Core/Config/load.xml` and `tests/lib/shell.lua`'s `options_widget_files()`: `optionsfont.lua` after `optionscolorpicker.lua`.
  - `SaftUI-Core/Config/optionslist.lua`: per-entry fonts and the caption set outright (Ruling 15), with `SetFieldFont` taking an optional fifth argument, the object (`optionslook.lua`).
  - `SaftUI-Core/Config/optionsselect.lua` and `optionsposition.lua`: stop passing `fontMode`.
  - `SaftUI-Core/Config/optionsitem.lua`: `Kit.NewSlot` and `Kit.PaintSlot` (Ruling 12); the item's dots use them.
  - `SaftUI-Core/Config/optionsshare.lua`: `OB.SHARE_KINDS.font = 'row'`, and `DefaultText`'s `font` branch.
  - `SaftUI-Core/Config/optionswindow.lua`: `OW:Reveal(path)`.
  - `SaftUI-Core/Config/generators.lua`: `generators.font(order, desc, opts)`; `st.Config:GetFontObjects` goes.
  - `SaftUI-Core/constants.lua`: `st.icons.link`.
  - `SaftUI-Misc/tooltipposition.lua` and `SaftUI-Chat/options.lua`: their `fields` (Ruling 7).
- Test:
  - Create `tests/core/options_font_test.lua`, on `core/options_window_helpers.lua` with synthetic pages, as `options_item_test.lua` does.
  - Modify:
    - `tests/lib/options_walk.lua`: `font` in `SAFTUI_TYPES`; `faceOnly` and `fontFields` in `SAFTUI_FIELDS`;
    - `tests/core/icons_test.lua`: `NAMES` gains `'link'`;
    - `tests/core/config_generators_test.lua:111`: `'font'`;
    - `tests/core/options_list_test.lua`: the caption keeps the group object, and its face is set outright after a face list;
    - `tests/core/fonts_tab_test.lua`: Kinds of text's rows are `font`;
    - `tests/core/options_frames_pages_test.lua:123`: `st:IsSharedFont(config.fonts[key])` in place of `values`;
    - `tests/misc/options_pages_test.lua:92,243` and `tests/misc/objective_tracker_position_test.lua:475`: `'font'`.
- Docs:
  - `AGENTS.md`: Core's row names the font row, `Config/optionsfont.lua`.
  - `.agents/edit-mode.md`:
    - covers gains `'SaftUI-Core/Config/optionsfont.lua'`;
    - "thirteen files" becomes fourteen, with the load order;
    - `W.Create`'s types; `generators.font(order, desc, opts)`;
    - a paragraph on the font row: the slot, the list, picking, the link, `faceOnly`;
    - `OW:Reveal`, the list's per-entry fonts, and `SHARE_KINDS`.
  - `.agents/testing.md`: `options_walk.lua`'s types and fields, and the `tests/core/` row.
  - `.agents/architecture.md`: `st.icons` gains `link`.
  - `docs/design-system/components/Icons/README.md`: a `link` row ("the font row's link to a shared font, 16, `text-grey`, `accent`") and the names list.
  - `docs/design-system/components/Select/README.md`: the font list's headings and faces, and a "Font row" section.

**Interfaces:**
- Consumes: Task 1's helpers; Task 2's tab paths (`{ 'Fonts', 'fonts', <key>, 'font_name' }`).
- Produces:
  - `generators.font(order, desc, opts) -> { type = 'font', name = 'Font', desc = desc, order = order, faceOnly = opts.faceOnly, fontFields = opts.fields }`. Every `opts` field is optional, and the 18 sites keep `(order, desc)`.
  - `W.WIDTH.font = 190`, `Kit.FONT_SLOT_GAP = { theme = 4, blizzard = 8 }`.
  - `Kit.NewSlot(parent, icon) -> button`: 16 by 24, its 16 by 16 icon centred, Text > Grey. It reads `button.onClick`, `button.tip` (`function(button) -> title, lines`, shown with `W.ShowTip`) and `button.blizzard`, does nothing while `button.disabled`, and wraps its scripts as `function(self)`. `Kit.PaintSlot(button, over)` paints it Text > Blue under the mouse, white under Blizzard.
  - `W.FontEntries(value, faceOnly) -> entries, selected`:
    - a caption, "SaftUI fonts";
    - the six shared fonts, each with `font = st:FontValues(key)`'s path;
    - a caption, "Typefaces";
    - `{ key = 'face:' .. name, label = name, font = st.LSM:Fetch('font', name) }` for each name of `st.LSM:List('font')`, in that order.

    `selected` follows Ruling 16; a nil or unknown value selects `'normal'`.
  - The widget: `w.frame` (a container, `w.width` by 24), `w.face` (`W.SelectFace(w.frame, W.WIDTH.select, function() w:Open() end)`), `w.dots` (the slot; one button, whose icon is the link or, from Task 4, the dots), `w.value`, `w.kind` (`'shared'` or `'typeface'`), `w:Open()` and `w:Pick(key)`.

    | `w.value` | the face reads, in | the slot | `w.kind` |
    | --- | --- | --- | --- |
    | a shared key | its name, in its face at 15 | the link | `'shared'` |
    | nil or an unknown key | "Text", in Text's face | the link | `'shared'` |
    | a table or a dropped key | `st:FontFields(value).font_name`, in that face (the field font when LibSharedMedia doesn't list it) | empty until Task 4 | `'typeface'` |
    | a face name (`faceOnly`) | the name, in its face | empty | `'typeface'` |

    | picked | a row | a `faceOnly` row |
    | --- | --- | --- |
    | a shared key | `Commit(key)` | `Commit(key)` |
    | `'face:' .. name` | `Commit(t)`, `t` a fresh `st:FontFields(w.value)` with `font_name = name` | `Commit(name)` |

  - The link's tooltip: the font's name, then "A shared font. Its typeface, size and outline are set on Global settings > Fonts, and change every text that uses it." and "Click to go there.". Its click runs `OW:Reveal({ 'Fonts', 'fonts', key, 'font_name' })`. On a disabled row neither the face nor the slot takes a click.
  - `OW:Reveal(path)` is the window's `GoTo(path)`. It navigates (closing an open menu, as `OW:Navigate` does), and the next render brings the row into view with its label in Text > Blue.
  - `W.OpenList(owner, entries, selected, onPick)` (Ruling 15).
  - `st.icons.link = st:TexturePath('lucide-link.tga')`.

- [ ] **Step 1: Write the failing tests** (in `tests/core/options_font_test.lua`, unless named)

```lua
test('generators.font: type font, named Font, its desc and order; opts.faceOnly and opts.fields become faceOnly and fontFields', ...)
test("the row under Thick, Thin and Blizzard: label, the 170 x 24 face, the 16 x 24 slot at the cell's right edge, 4 apart (8 under Blizzard)", function()
	-- w:GetWidth() == 190 (194 under Blizzard); the slot's right == the cell's right; the face's left unchanged when the slot's icon changes
end)
test("a shared font picked: the face reads its name in its face at 15, the slot shows the link", function()
	-- value 'heading': w.face.text:GetText() == 'Heading', {w.face.text:GetFont()} == path('Colus'), 15; w.dots.icon:GetTexture() == st.icons.link, shown
end)
test('a typeface picked: the face reads its face in that face; the slot is empty', ...)
test('the list: SaftUI fonts, the six in order each in its face, Typefaces, then every LibSharedMedia face in its order, each in its face', function()
	-- entries[1] caption 'SaftUI fonts'; [2..7] normal..subtitle labelled Text..Subtitle; [8] caption 'Typefaces'; [9..] 'face:' .. each of st.LSM:List('font')
	-- the drawn caption rows keep OB.Font('group') with its face, even after a face was drawn in that pooled row
end)
test('the picked entry is blue: the shared font, or the typeface by its face', ...)
test('picking: a shared font saves its key; a typeface a fresh table filled from what showed; a face swap keeps the options', function()
	-- from 'heading', pick 'face:Bebas Neue' -> set got { font_name = 'Bebas Neue', font_size = 15, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
	-- from that table pick 'face:Homespun' -> its other fields kept, a new table, the first unchanged; pick 'pixel' -> 'pixel'
end)
test('a dropped key shows its old face and writes nothing until a pick', ...)
test('a typeface LibSharedMedia does not list (Review Focus 1)', function()
	-- value { font_name = 'Gone', font_size = 12 }: the face reads 'Gone' in the field font; no entry blue; picking 'face:Colus' commits a table with font_size 12
end)
test("the link: its tooltip, and its click opening Global settings > Fonts at that font with its Typeface label lit, closing an open item menu", ...)
test('a disabled row: neither the face nor the slot takes a click', ...)
test('faceOnly: the same list; a typeface saves its face name, a shared font its key and shows the link; never a dots icon', ...)
test("a default's reset names the default by FontLabel: 'Header font goes back to its default: Heading.'", ...)
test('a share on the row: the own mark, the diff icon and Apply to draw as on a select', ...)
test('search finds a font row by its name', ...)
test('whole pixels under Thick, Thin and Blizzard, size noise up, down and off', ...)
-- options_list_test.lua: 'a caption is drawn in the group font ...' also checks rows[12].text:GetFont() == OB.Font('group'):GetFont()
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/options_font_test.lua tests/core/icons_test.lua`. Expected: FAIL, the `font` type is unknown to `W.Create`, and `st.icons.link` is nil.
- [ ] **Step 3: Make the link icon.**
  - Install the rasteriser outside the repo, in the session's scratchpad: `npm init -y && npm install @resvg/resvg-js`.
  - From the repo root run `NODE_PATH=<that folder>/node_modules node tools/lucide-to-tga.cjs link`. The tool fetches `lucide-static@0.460.0` from unpkg; if the sandbox blocks the fetch, stop and ask the controller.
  - Expected: `wrote .../SaftUI-Core/Media/Textures/lucide-link.tga`, 32 by 32.
  - Register `st.icons.link`.
- [ ] **Step 4: Implement** as the Interfaces and Rulings 11, 12, 14 to 16, 20 and 26 say, and update the listed assertions.
- [ ] **Step 5: Run** `tests/run tests/core tests/misc tests/tracker/window_test.lua tests/unitframes/config_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 6: Docs** as listed under Files.
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Core/Config/optionsfont.lua SaftUI-Core/Config/load.xml SaftUI-Core/Config/optionslist.lua SaftUI-Core/Config/optionslook.lua SaftUI-Core/Config/optionsselect.lua SaftUI-Core/Config/optionsposition.lua SaftUI-Core/Config/optionsitem.lua SaftUI-Core/Config/optionsshare.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/generators.lua SaftUI-Core/constants.lua SaftUI-Core/Media/Textures/lucide-link.tga SaftUI-Misc/tooltipposition.lua SaftUI-Chat/options.lua tests/core/options_font_test.lua tests/lib/shell.lua tests/lib/options_walk.lua tests/core/icons_test.lua tests/core/config_generators_test.lua tests/core/options_list_test.lua tests/core/fonts_tab_test.lua tests/core/options_frames_pages_test.lua tests/misc/options_pages_test.lua tests/misc/objective_tracker_position_test.lua AGENTS.md .agents/edit-mode.md .agents/testing.md .agents/architecture.md docs/design-system/components/Icons/README.md docs/design-system/components/Select/README.md
git commit -m "options: add the font row, listing SaftUI's fonts then every typeface, with a link to the Fonts tab"
```

**In-game checks:**
- Every Font row in `/sui` shows the new list, each entry in its own face, and the link beside a shared font.
- G7: the link lands on the right section of the Fonts tab with its Typeface label lit, at full and half size, under Thick, Thin and Blizzard.
- G1: a typeface picked for a unit frame's name draws at once, and again for a face another addon registers. If one doesn't, preload every face LibSharedMedia lists, and its later registrations, as a followup.

---

### Task 4: The dots and their menu

**Files:**
- Modify:
  - `SaftUI-Core/Config/optionsfont.lua`: the dots in the slot while a typeface is picked (not `faceOnly`), their tooltip, `w:Menu()`, and the click toggling the menu as an item's dots do.
  - `SaftUI-Core/Config/optionsmenu.lua`: `OW:OpenMenu`, `Draw` and `FollowMenu` take the widget's own menu (Ruling 13).
- Test: modify `tests/core/options_font_test.lua` (the menu's cases); `tests/core/options_menu_test.lua` should pass unchanged.
- Docs:
  - `.agents/edit-mode.md`: the menu bullet (a font row's menu, its title, its rows, how it saves).
  - `docs/design-system/components/Select/README.md`: the font row's dots and menu.

**Interfaces:**
- Consumes:
  - Task 2's `FN.FieldOptions(read, write, 'text', fields)`;
  - Task 3's widget (`w.dots`, `w.kind`, `w.value`, `w.root`, `w.row`) and `Kit.PaintSlot`.
- Produces:
  - `w:Menu() -> group, title | nil`. It returns nil unless `w.kind == 'typeface'` and the row isn't `faceOnly`.
    - `title` is `row.name .. ': ' .. face` ("Header font: Colus").
    - `group = { type = 'group', name = title, args = FN.FieldOptions(read, write, 'text', option.fontFields) }`.
    - `read(field)` reads `st:FontFields(w.value)`.
    - `write(field, v)` commits a fresh `st:FontFields(w.value)` with that one field changed, through `OM.Set(w.root, w.row, copy)`, and never edits the saved table.
  - The dots' tooltip: "<face> for <row name>", then "Its own size, outline, shadow and line spacing.".
  - `OW:OpenMenu(widget) -> boolean`: false in combat, when the widget is disabled, or when it has no menu. The menu comes from `widget:Menu()` when the widget has `Menu`, else from `widget.row.option.menu`.

- [ ] **Step 1: Write the failing tests**

```lua
test('a typeface picked: the dots in the slot, grey, lit under the mouse (white under Blizzard); the tooltip names the face and the row', ...)
test("the dots open the menu 'Header font: Colus': Size, Outline, Shadow offset X, Shadow offset Y, Line spacing, with the tab's ranges; a second click closes it", ...)
test('fontFields: the tooltip row lists Size and Outline only, the chat row Size, Outline and both shadows', ...)
test("a menu change calls the row's set with a new table, the saved one unchanged; the page and the menu draw again", ...)
test('the value changing under an open menu (Review Focus 4)', function()
	-- the row's reset (back to 'heading') -> the menu closes; the value replaced by another table -> the menu follows its face
	-- a profile switch -> closed or following, never a write of the old table; the cell gone -> closed; #take_errors() == 0
end)
test('a drag across the range (Review Focus 5)', function()
	-- from { font_name = 'Colus', font_size = 15 } (its object made when the row drew), drag Size 15 -> 40 -> 15 on a row whose set counts calls:
	-- one set per step; 25 typeface objects made on the way up (16 to 40), none on the way back
end)
test('under Thick, Thin and Blizzard with a share on the row: the menu draws, follows its row, and closes on Esc, a click outside and navigation', ...)
test("a disabled row's dots take no mouse; in combat the menu does not open", ...)
test("search finds no row of a dots menu ('Size' matches only real Size rows)", ...)
test('a faceOnly row never shows dots, so no menu opens inside an item menu', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/options_font_test.lua`. Expected: FAIL, the slot is empty for a typeface.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/core/options_font_test.lua tests/core/options_menu_test.lua tests/core/options_item_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionsfont.lua SaftUI-Core/Config/optionsmenu.lua tests/core/options_font_test.lua .agents/edit-mode.md docs/design-system/components/Select/README.md
git commit -m "options: give a typeface its own size, outline, shadow and line spacing behind the dots"
```

**In-game checks:**
- G8: a typeface on a unit frame's name, then its dots menu: a Size drag follows on the frame as it moves, and Outline and the shadows reach it at once.
- The menu hangs from the dots, stays inside the screen margin, and closes on Esc, a click outside and a page change.
- Chat's dots change nothing yet: chat reads its own Font size until Task 5.

---

### Task 5: Core, Chat and Misc readers on the rule

**Files:**
- Modify:
  - Core:
    - `SaftUI-Core/Widgets/checkbutton.lua`: labels follow `panels.font`; `button.SetTextFont` (Ruling 10).
    - `Widgets/button.lua`: `st:SkinButton` through `st:FontObject`.
    - `Widgets/statusbar.lua`: `st:ApplyFont`.
    - `skinning.lua`: `st:SkinActionButton`'s texts by `st:ApplyFont`, kept with `st:FollowFont` when the config is nil (Ruling 9); `st:StyleEditBox`'s text and instructions by `st:ApplyFont`.
    - `panels.lua`: header titles follow `headers.font`, and `st:UpdateHeader`'s title line goes; `st:CreateFontString` by `st:ApplyFont`.
    - `Config/optionswindow.lua`: the Blizzard title bar's text follows `headers.font`, and the line in `Draw` goes.
    - `Media/fonts.lua`: Kinds of text's note drops the reload sentence, and Window titles' `apply` goes.
  - Bags: `SaftUI-Bags/header.lua:172` (`SetTextFont`); `containers/bag.lua:134` and `containers/bank.lua:60` pass nil.
  - Chat:
    - `SaftUI-Chat/config.lua`: `fontsize` leaves the defaults.
    - `chatframe.lua`: `CHT.OLD_FONT_SIZE`, `CHT:ConvertFonts` in `OnEnable` after `st:BindModuleConfig` and first in `UpdateConfig`, `CHT:ApplyChatFont` and `CHT:OnFontsChanged`.
    - `options.lua`: the Font size row goes.
  - Misc:
    - `SaftUI-Misc/tooltip.lua`: `st:FontValues`, the first three values.
    - `totemskin.lua`: the texts follow `buttons.font`; the forced shadow goes.
    - `totemtimers.lua`: the timer text follows `buttons.font`.
    - `Skinning/skinning.lua`: `SK:OnFontsChanged`.
    - `Skinning/addons/restedxp.lua`: `st:FontValues(chat.font)` for its texts and timers, and `RX:OnFontsChanged`. The title keeps `'title'` until Task 7.
    - `Skinning/blizzard/Blizzard_BuffFramePosition.lua`: `AP:UpdateFont` from `st:FontValues(st:FaceFont(config.font, config.size, config.outline))`, with the shadow too; `AP:OnFontsChanged`.
    - `Blizzard_ColorPicker.lua`: `TitleFont` and `SkinFont` through `st:FontObject`; `CP:OnFontsChanged` (Ruling 8).
    - `Blizzard_BuffFrame.lua`, `Blizzard_ObjectiveTracker.lua` (`Font(kind)`), `Blizzard_CooldownViewer.lua`, `Blizzard_SwingTimer.lua` and `characterframe/characterframe.lua`: through `st:ApplyFont` or `st:FontObject`.
- Test:
  - Create `tests/chat/font_test.lua`, with chat's world as `tests/chat/theme_test.lua` loads it.
  - Create `tests/misc/font_readers_test.lua`, with Misc's world as `tests/misc/theme_test.lua` loads it, plus `tooltip.lua`, RestedXP's fixtures and the color picker fixture.
  - Modify `tests/core/fonts_tab_test.lua` (Kinds of text at once), `tests/core/options_frames_pages_test.lua:230` (chat's rows), and `tests/misc/tooltip_skin_test.lua` and `color_picker_skin_test.lua` where they pin a read.
- Docs:
  - `.agents/architecture.md`: the readers' rule (which follow, which re-apply from `OnFontsChanged`), and the converters list gains `chat.fontsVersion`.
  - `.agents/edit-mode.md`: Kinds of text at once.

**Interfaces:**
- Consumes: Task 1's helpers and `st:FontsChanged`; Task 3's `fields` on chat's row.
- Produces:
  - `CHT.OLD_FONT_SIZE = 16`.
  - `CHT:ConvertFonts() -> boolean`. While `config.fontsVersion` is nil:
    - `size` is `config.fontsize`, or `CHT.OLD_FONT_SIZE` when nil;
    - `fields` is `st:FontFields(config.font)`;
    - when `size ~= fields.font_size`, or `fields.shadow_offset` isn't `{ 0, 0 }`, it writes `config.font = fields`, with `font_size = size` and `shadow_offset = { 0, 0 }`;
    - then `config.fontsize = nil` and `config.fontsVersion = 1`.
  - `CHT:ApplyChatFont(frame)`: `SetFont(path, size, flags)`, `SetShadowColor(0, 0, 0, 1)` and `SetShadowOffset(x, y)` from `st:FontValues(config.font)`. No spacing (Ruling 7). The edit box goes through `st:StyleEditBox` as today.
  - `CHT:OnFontsChanged()`: `ConvertFonts`, then `ApplyChatFrameConfig` on every chat frame.
  - `AP:OnFontsChanged()`, `SK:OnFontsChanged()` (to its submodules), `RX:OnFontsChanged()` and `CP:OnFontsChanged()`.
  - `button.SetTextFont(self, value)`: `st:FollowFont(text, nil)`, then `st:ApplyFont(text, value)`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/chat/font_test.lua (both clients)
test('as shipped: nothing written, chat follows Text; fontsize cleared and the profile marked', function()
	-- after CHT:Enable: profile.chat.font == 'normal'; rawget(profile.chat, 'fontsize') == nil; fontsVersion == 1
	-- {ChatFrame1:GetFont()} == path('AgencyFB Bold'), 16, 'OUTLINE'; ChatFrame1:GetShadowOffset() == 0, 0
end)
test("a Font size of 14 keeps chat's look as a typeface", function()
	-- chat.font == { font_name = 'AgencyFB Bold', font_size = 14, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
end)
test("Text at 18 with Font size left at 16 (G5): chat keeps 16, as a typeface", ...)
test("Text's shadow set to 1, -1: chat keeps no shadow, as a typeface", ...)
test('chat on odd profiles (Review Focus 3)', function()
	-- chat.font = 'normal_med', fontsize 16 -> a typeface AgencyFB Bold 16; chat.font = 'gone', fontsize 16 -> 'gone' kept, drawn as Text
	-- each run twice: nothing more; #take_errors() == 0
end)
test('a profile switched to with an old Font size converts on the profile update; one already converted is left', ...)
test("the page: Font is a font row with Size, Outline and both shadows in its dots; no Font size row", ...)
test('a Fonts tab change to Text reaches every chat frame at once; a typeface on chat leaves the line spacing alone', ...)
-- tests/misc/font_readers_test.lua
test('a Small text change reaches the totem texts and timers at once, with their shadow no longer forced off', ...)
test("Button text set to Text on the Fonts tab reaches the totem texts and the bag slot bars' texts at once", ...)
test("the buff and debuff timers on a shared font follow it; on a face they keep their size and outline", ...)
test("the tooltip's lines take Text's face, size and outline from st:FontValues; a typeface's too", ...)
test("RestedXP's texts take chat's face and outline at RestedXP's sizes, again on a Fonts tab change", ...)
test("the color picker's title takes Window titles' font at once, and Blizzard's again with the skin off", ...)
test('every reader draws Text for a value that names nothing, with no error', ...)
-- tests/core/fonts_tab_test.lua
test("Kinds of text: Button text and Check box labels apply at once; the note says nothing of a reload", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/chat/font_test.lua tests/misc/font_readers_test.lua`. Expected: FAIL, `CHT.ConvertFonts` is nil.
- [ ] **Step 3: Implement** as the Interfaces and Rulings 5 and 7 to 10 say.
- [ ] **Step 4: Run** `tests/run tests/core tests/chat tests/misc tests/bags`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Widgets/checkbutton.lua SaftUI-Core/Widgets/button.lua SaftUI-Core/Widgets/statusbar.lua SaftUI-Core/skinning.lua SaftUI-Core/panels.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Media/fonts.lua SaftUI-Bags/header.lua SaftUI-Bags/containers/bag.lua SaftUI-Bags/containers/bank.lua SaftUI-Chat/config.lua SaftUI-Chat/chatframe.lua SaftUI-Chat/options.lua SaftUI-Misc/tooltip.lua SaftUI-Misc/totemskin.lua SaftUI-Misc/totemtimers.lua SaftUI-Misc/Skinning/skinning.lua SaftUI-Misc/Skinning/addons/restedxp.lua SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFrame.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua SaftUI-Misc/Skinning/blizzard/Blizzard_CooldownViewer.lua SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimer.lua SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua tests/chat/font_test.lua tests/misc/font_readers_test.lua tests/core/fonts_tab_test.lua tests/core/options_frames_pages_test.lua tests/misc/tooltip_skin_test.lua tests/misc/color_picker_skin_test.lua .agents/architecture.md .agents/edit-mode.md
git commit -m "core: put Core's, chat's and Misc's font readers on the shared values, applying at once"
```

**In-game checks:**
- G5: chat looks the same after the upgrade, both with Text unchanged and with Text's size changed before the upgrade. The Chat page has no Font size row, and chat's dots change its size.
- Fonts > Kinds of text: Button text reaches the totem bar and the bags' bag slot bars at once; Check box labels reaches the bags' filters at once.
- With Skinning's color picker on, a Window titles change reaches its title at once. Turned off, the title is Blizzard's.
- Tooltips, RestedXP and the buff timers look as before.

---

### Task 6: The other readers, and the `SetFont` scan

**Files:**
- Modify:
  - Bags: `SaftUI-Bags/category.lua:411`, `inventory.lua:243` (the titles only) and `slot.lua:462,505`.
  - Loot: `SaftUI-Loot/roll.lua`, `rollbar.lua` (through `st:FontObject`), `Feed/feed.lua:585` and `popup.lua`.
  - Tracker: `SaftUI-Tracker/rows.lua` (`FontOf` through `st:FontObject`; Ruling 2) and `window.lua:506,539`.
  - Unitframes: `SaftUI-Unitframes/updaters.lua:151,400`, `elements/auras.lua:145` and `elements/name.lua:42`.
  - ActionBars:
    - `SaftUI-ActionBars/buttons.lua`: `ApplyText` by `st:ApplyFont(region, text.value)`.
    - `skin.lua`: `TextConfig` adds `value = st:FaceFont(text.font, text.size, text.outline)`; `StyleCountdown` by `st:ApplyFont(numbers, AB:CountdownValue(config))`, so `skin.ownCountdownFont` goes; the forced shadow goes; the text heights come from `st:FontValues` (Rulings 17 and 18).
- Test:
  - Create `tests/core/setfont_scan_test.lua`.
  - Modify `tests/actionbars/cooldown_numbers_test.lua` (the cases on a set font, size or outline compare `numbers:GetFontObject()` with `st:GetFont(AB:CountdownValue(config))`) and `tests/actionbars/theme_test.lua` where it pins the shadow.
  - Modify `tests/unitframes/copy_from_history_test.lua`, `tests/tracker/rows_test.lua` and `tests/loot/feed_test.lua` (one case each, below).
  - Modify `tests/bags/views_walk_test.lua` if it pins the title read.
- Docs:
  - `.agents/architecture.md`: the rule's last readers.
  - `.agents/testing.md`: the scan's row; the `tests/core/` row.

**Interfaces:**
- Consumes: Task 1's helpers.
- Produces:
  - `AB:CountdownValue(config) -> value` (Ruling 18).
  - The scan's allowlist, `ALLOWED` in `setfont_scan_test.lua`, each file with its reason:
    - `SaftUI-Core/Media/fonts.lua`: the shared, typeface and preload objects;
    - `SaftUI-Core/Config/optionsbody.lua`: `/sui`'s objects;
    - `SaftUI-Core/Config/optionslook.lua`: the field font and `SetFieldFont`;
    - `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua`: the buff frames' objects;
    - `SaftUI-Chat/chatframe.lua`: Blizzard's chat frames;
    - `SaftUI-Misc/tooltip.lua`: Blizzard's tooltip lines;
    - `SaftUI-Misc/Skinning/addons/restedxp.lua`: RestedXP's texts;
    - `SaftUI-Core/Dev/fontdemo.lua`: the demo.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/setfont_scan_test.lua (local T = load_test_file('lib/theme_helpers.lua'))
test('no file the TOCs load calls :SetFont( outside the allowed list', function()
	-- for each path of T.saftui_files() not in ALLOWED: its source (comments stripped) has no ':SetFont(' -> else fail naming path and line
end)
test('every allowed file still has a call, so a stale entry is noticed', ...)
-- tests/actionbars/cooldown_numbers_test.lua
test('a hotkey switched Small text, then Colus, then Small text follows each with no SetFont (G2)', function()
	-- set text.hotkey.font through the profile as the page does; after each AB:StyleBar, HotKey:GetFontObject() == st:GetFont(value)
end)
-- tests/unitframes/copy_from_history_test.lua
test('Copy from carries a typeface table deep: the two units never share one, and an undo puts it back whole', ...)
-- tests/tracker/rows_test.lua
test('a typeface on Font and Header font reaches the rows; a refresh with nothing changed sets no font', ...)
-- tests/loot/feed_test.lua
test("a typeface on the feed's Font reaches its texts; a value naming nothing draws Text", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/setfont_scan_test.lua`. Expected: FAIL, naming `SaftUI-ActionBars/buttons.lua:59` and `skin.lua:337,340`.
- [ ] **Step 3: Implement** as the Files and Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/core tests/actionbars tests/unitframes tests/tracker tests/loot tests/bags`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Bags/category.lua SaftUI-Bags/inventory.lua SaftUI-Bags/slot.lua SaftUI-Loot/roll.lua SaftUI-Loot/rollbar.lua SaftUI-Loot/Feed/feed.lua SaftUI-Loot/popup.lua SaftUI-Tracker/rows.lua SaftUI-Tracker/window.lua SaftUI-Unitframes/updaters.lua SaftUI-Unitframes/elements/auras.lua SaftUI-Unitframes/elements/name.lua SaftUI-ActionBars/buttons.lua SaftUI-ActionBars/skin.lua tests/core/setfont_scan_test.lua tests/actionbars/cooldown_numbers_test.lua tests/actionbars/theme_test.lua tests/unitframes/copy_from_history_test.lua tests/tracker/rows_test.lua tests/loot/feed_test.lua .agents/architecture.md .agents/testing.md
git commit -m "core: draw every remaining font setting through st:ApplyFont, and scan for SetFont"
```

**In-game checks:**
- G2: an action bar hotkey switched Small text, then Colus, then Small text (from `/run` until Task 8 gives it the list) follows each with no reload.
- Cooldown numbers as before, on 30, 36 and 45 pixel buttons.
- A typeface picked for a unit frame's health text, the bags' Icon font, the loot feed and the tracker's Font each draws at once.
- Copy from on a unit frame, then Undo, puts the typeface back.

---

### Task 7: Heading's defaults, and Window titles in Theme

**Files:**
- Modify:
  - `SaftUI-Tracker/config.lua`: `header_font = 'heading'`.
  - `SaftUI-Bags/config.lua`: `fonts.titles = 'heading'`.
  - `SaftUI-Bags/inventory.lua:215`: the search box on `'normal'`.
  - `SaftUI-Bags/container.lua:105,143`: the footer texts by `st:ApplyFont(fs, 'normal')`.
  - `SaftUI-Bags/options.lua`: Title font's desc, "The font of the category titles.".
  - `SaftUI-Core/Media/theme.lua`: the Window titles section.
  - `SaftUI-Core/Media/fonts.lua`: Kinds of text down to Button text and Check box labels.
  - `SaftUI-Misc/Skinning/addons/restedxp.lua`: the guide title from `'heading'`.
- Test:
  - Create `tests/bags/fonts_test.lua`, with the bags' world (`bags/bag_world.lua`).
  - Modify:
    - `tests/core/theme_tab_test.lua`: the rows case gains the section;
    - `tests/core/fonts_tab_test.lua`;
    - `tests/tracker/window_test.lua` and `rows_test.lua`: the Header font is `'heading'` at 40 and 458;
    - `tests/misc/restedxp_title_test.lua`;
    - `tests/misc/color_picker_skin_test.lua`: a change through the Theme tab.
- Docs:
  - `.agents/edit-mode.md`: the Theme tab's Window titles, and Kinds of text's two rows.
  - `docs/design-system/README.md`: the Type table's Heading row (the bags' category titles, SaftUI's tracker).
  - `tokens.json`: Heading's usage.

**Interfaces:**
- Consumes: Task 2's `FN.FontSettingDefault`; Task 3's `generators.font`; Task 5's following header titles.
- Produces:
  - The Theme tab's `window_titles = { type = 'group', inline = true, order = 7, name = 'Window titles', args = { font = <font row> } }`.
  - The font row reads and writes `headers.font`, with the spec's desc word for word.
  - Its `default` is `FN.FontSettingDefault(read, write, 'normal')`.
  - Its set runs `st:FontsChanged()`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/theme_tab_test.lua
test('Window titles: a section after Options windows with one Font row, saved in headers.font, reset to Text', ...)
test("a Window titles set reaches every header title, /sui's Blizzard title bar and the color picker's title at once", ...)
-- tests/core/fonts_tab_test.lua
test('Kinds of text: Button text and Check box labels; Window titles has left', ...)
-- tests/bags/fonts_test.lua (both clients)
test('the category titles in Heading by default; the search box and the gold and free-slot texts in Text', ...)
test('Title font set to a typeface reaches the titles only, not the search box', ...)
test("Title font's desc says it is the category titles' font", ...)
-- tests/tracker/window_test.lua
test("Header font defaults to Heading for the header line and the zone headers; its reset says 'Header font goes back to its default: Heading.'", ...)
-- tests/misc/restedxp_title_test.lua
test("RestedXP's guide title takes Heading's face at RestedXP's size plus 3", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/theme_tab_test.lua tests/bags/fonts_test.lua tests/tracker/window_test.lua`. Expected: FAIL, there is no Window titles section, and the titles are in Text.
- [ ] **Step 3: Implement** as the Files and Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/core tests/bags tests/tracker tests/misc`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/config.lua SaftUI-Bags/config.lua SaftUI-Bags/inventory.lua SaftUI-Bags/container.lua SaftUI-Bags/options.lua SaftUI-Core/Media/theme.lua SaftUI-Core/Media/fonts.lua SaftUI-Misc/Skinning/addons/restedxp.lua tests/bags/fonts_test.lua tests/core/theme_tab_test.lua tests/core/fonts_tab_test.lua tests/tracker/window_test.lua tests/tracker/rows_test.lua tests/misc/restedxp_title_test.lua tests/misc/color_picker_skin_test.lua .agents/edit-mode.md docs/design-system/README.md docs/design-system/tokens.json
git commit -m "core: set bag titles and the tracker's headers in Heading, and move Window titles to the Theme tab"
```

**In-game checks:**
- G3: the bags' category titles in Colus 15 sit right in their band, down to Category title height 20. With SaftUI's tracker on, its header line, count and zone headers lay out.
- The bags' search box and gold and free-slot texts are as before.
- Theme > Window titles changes the bags' and bank's titles, `/sui`'s title bar under Blizzard, and Blizzard's color picker's title at once.
- RestedXP's guide title is in Heading's face.

---

### Task 8: The action bars' and buffs' font lists

**Files:**
- Modify:
  - `SaftUI-ActionBars/textoptions.lua`:
    - the four texts' Font rows become `generators.font(1, desc, { faceOnly = true })`, with their own `get`, `set`, shares and resets as today;
    - Size and Outline are `hidden` while `st:IsSharedFont(<font>)`;
    - the cooldown numbers' unset Font shows the shared font by size (Ruling 18).
  - `SaftUI-ActionBars/skin.lua`: `AB:GetCountdownFont`'s first return follows Ruling 18.
  - `SaftUI-ActionBars/options.lua`: `AB:SettingText` names a shared font by name, through `st:FontLabel`.
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua`: Duration's and Stack count's Font rows become `faceOnly`, with Size and Outline hidden as above.
  - `docs/followups.md`: the followup moves to Resolved; the Later items become followups.
- Test:
  - Modify `tests/actionbars/page_test.lua`, `shared_settings_test.lua` and `cooldown_numbers_test.lua`.
  - Modify `tests/misc/options_pages_test.lua` (the Auras page's text rows).
- Docs:
  - `.agents/edit-mode.md`: the action bars' text menus and the Auras page's text rows.
  - `.agents/architecture.md`: the action bars' text values.
  - `docs/design-system/30-code-changes.md`: Code change 3 done.
  - `docs/design-system/10-discrepancies.md`: discrepancy 20 resolved, and discrepancy 2 fixed by a pick, with its default Later.

**Interfaces:**
- Consumes: Task 3's `faceOnly` row; Task 6's `AB:CountdownValue`.
- Produces: nothing new for other tasks.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/actionbars/page_test.lua
test("a text's Font lists the shared fonts first; Small text picked saves 'pixel', hides Size and Outline and shows the link", ...)
test('a face picked saves its name and shows Size and Outline again, with what they held', ...)
test("the cooldown numbers' unset Font shows Large numbers on 45 px buttons and Small text on 30, with the link; a size set alone shows the face it draws", ...)
-- tests/actionbars/shared_settings_test.lua
test("a shared font on All bars' hotkey reaches every bar that follows it; Apply to and the diff icon name it 'Small text'", ...)
-- tests/misc/options_pages_test.lua
test("Buffs > Duration's Font lists the shared fonts; Small text picked hides Size and Outline, and the timers follow Small text", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/actionbars tests/misc/options_pages_test.lua`. Expected: FAIL, the Font rows are LSM selects.
- [ ] **Step 3: Implement** as the Files say.
- [ ] **Step 4: Followups.**
  - Move `2026-11-10 — Fonts: separate the fonts users pick per kind of text from SaftUI's internal font objects` (anchor `#2026-11-10--fonts-separate-the-fonts-users-pick-per-kind-of-text-from-saftuis-internal-font-objects`) to Resolved, with "**Resolved 2026-11-14:** the fonts design, Tasks 1 to 8.", and update both ToC links.
  - Add one entry for each item of the spec's Later list, with the template's fields from the spec's words.
  - Add the G1 preload followup if Task 3's check called for it.
- [ ] **Step 5: Run** `tests/run -j2`. Expected: PASS.
- [ ] **Step 6: Docs** as listed under Files.
- [ ] **Step 7: Commit**

```bash
git add SaftUI-ActionBars/textoptions.lua SaftUI-ActionBars/skin.lua SaftUI-ActionBars/options.lua SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua tests/actionbars/page_test.lua tests/actionbars/shared_settings_test.lua tests/actionbars/cooldown_numbers_test.lua tests/misc/options_pages_test.lua docs/followups.md .agents/edit-mode.md .agents/architecture.md docs/design-system/30-code-changes.md docs/design-system/10-discrepancies.md
git commit -m "actionbars: list SaftUI's fonts in the texts' and buffs' Font rows, hiding Size and Outline while one is picked"
```

**In-game checks:**
- G7, from the action bars' text menu: the link closes the menu and lands on the Fonts tab.
- G2: from the hotkey's Font row, Small text, then Colus, then Small text: each draws with no reload.
- A hotkey on Small text follows a Small text change on the Fonts tab at once.
- The buffs' timers on Small text follow it.
- All bars' Apply to with a shared font reaches the chosen bars.

---

## Spec coverage check

| Spec section, decision or call | Task |
| --- | --- |
| Why; What the owner decided 1 (names only), 7 (dropped, no rename) | 1 |
| Decided 2 (shared fonts editable), Goals' "one function", "applies at once" | 1, 2, 5, 6 |
| Decided 3 (the dropdown, the dots, the link) | 3, 4, 8 |
| Decided 4 (Heading; `/sui`'s titles; tracker and bags default to it) | 1, 2, 7 |
| Decided 5 (Window titles in the theme) | 7 |
| Decided 6 (Homespun at any size) | 3 (every LibSharedMedia face listed) |
| Anti-goals (no `SetFont`; no menu in a menu; no game-made object; no reload; no shared font changed by a text) | 6 (scan), 3 and 4 (`faceOnly` has no dots), 1 (`CreateFont` only), 5, 1 and 4 (fresh tables, objects never changed) |
| The shared fonts; Dropped | 1 |
| A font setting's value: saved shape, old values, AceDB | 1 (Rulings 3 and 24; the AceDB and `apply_defaults` cases) |
| One function; the rule for readers 1 to 3 | 1 (helpers), 5 and 6 (readers), 6 (scan) |
| The font row: the row, the list, picking | 3 |
| The dots and their menu; how the menu saves | 4 |
| The link | 3 (icon made in Step 3) |
| Rows with their options beside them (`faceOnly`) | 3 (the row), 8 (its sites) |
| Resets, shares and search | 3, 4, 8 |
| The Fonts tab after the change | 1 (fixed sections), 2, 5 (note), 7 (Kinds of text's two rows) |
| Heading: `/sui`'s titles, their sizes, RestedXP | 2, 7 |
| Heading's defaults; what changes at upgrade; Settled 2 and 3 | 7; 1 (the face step) |
| Window titles in Theme; the bags' footer texts | 7 |
| Readers that copy values (chat, tooltip, RestedXP, buffs, action bars, cooldown numbers, totems, Button text and Check box labels, Window titles, the rest) | 5, 6 |
| Unit frame profiles, Copy from and the history | 4 (whole values), 6 (Copy from case) |
| Phases 1 to 6 | 1; 2; 3 and 4; 5 and 6; 7; 8 |
| Followups and Later | 8 |
| In-game checks G1 to G8 | G1: 1, 3; G2: 6, 8; G3: 7; G4: 2; G5: 5; G6: 1; G7: 3, 8; G8: 4 |
| Risks 1 to 5 | 1 (preload), 6 (scan), 1 (AceDB cases), 1 (dropped), 4 (share and menu under both looks) |
| Calls 1 to 27 | 1: 5; 2: 7; 3: 2; 4, 5: 7; 6: 7 (left as is); 7, 8, 9: 1; 10: 3; 11: 1, 4; 12: 4 (narrowed by Ruling 7); 13: 3; 14: 3, 8; 15: 4; 16: 2, 5; 17: 2; 18: 5; 19: 7; 20: 5; 21: 5; 22: 1; 23: 6, 8; 24: 2; 25: 7; 26: 1; 27: task order |

**Where the spec is silent or the code disagrees** (each is a Ruling above):
- **The code disagrees:**
  - Ruling 7: chat's line spacing is Blizzard's 0, while Text's is 4.
  - Ruling 8: the color picker's skin restores Blizzard's font.
  - Ruling 2: the tracker's idle-refresh rule.
  - Ruling 6: totem timers hook `UpdateFontConfig` too.
  - Ruling 10: a check button helper is named `SetFont`.
  - Ruling 15: a caption set after a face keeps the face in game; `fontMode` is per list.
  - Ruling 11: the dropdown art's 7 outset under Blizzard.
- **Tests that pin what this work changes:** the Fonts tab's (1, 2, 5, 7), the five `select` type assertions (3), `page_test.lua`'s names and outline label (1, 2), the tracker's hook cases (1), the cooldown numbers' `SetFont` cases (6), the Theme tab's rows (7).
- **The spec leaves open:** Rulings 1, 3 to 5, 9, 12 to 14, 16 to 26.
