# SaftUI Interaction States Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One color setting, the Accent, from which every interaction state of every SaftUI widget is derived by one rule per shape (hover tints the body, pushed tints it stronger, selected is an accent edge or bar and a fading fill, focus an accent edge, disabled an opacity), through one cache and one set of drawing helpers, with the derivation's settings in the Accent row's dots menu and Buttons > Normal, Hover, Pushed and Checked gone.

**Architecture:**
- **The derivation** (`SaftUI-Core/Media/states.lua`, new, `st.States`): pure OKLCH functions (the mockup's math), three modes (Layers, Tones, Hue-shifted tones), the settings in `st.config.profile.theme.states`, and one cache that checks itself on every read (the Accent's r, g, b, the settings table, `ST.serial`) and computes again in place when one differs. Readers call `st:StateColor(name)`, `st:StateSolid`, `st:StateText`, `st:StateFade`, `st:StateAlpha`.
- **The drawing helpers** (`SaftUI-Core/Widgets/states.lua`, new): `st:AddStates(frame, shape, opts)` once, `st:SetState(frame, key, on)` as a state changes; the pieces (Layer, Fill, Edge, Bar, Mark, Solid, Glyph, Alpha) are the spec's. Every state frame follows `accent`, so a change of the Accent or a derivation setting (`ST.Changed()`: `st:ColorChanged('accent')`) reaches it through the live color mechanism, one pass a frame during the picker's or the menu's edit.
- **The areas** then draw their widgets through the helpers, each in its own files; the previews and the Accent row's dots menu come after the kit; a last task retires the four Buttons defaults and the tint constants and adds the scan that keeps it so.

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0; SaftUI's options kit (`st.OptionsModel`, `st.OptionsWidgets`, `st.OptionsBody`, `st.OptionsWindow`), its color picker and the live color mechanism (`st:ColorChanged`, `st:FollowColor`, `tests/lib/color_cost.lua`); the bundled oUF and LibActionButton-1.0, neither changed; Node (no dependencies) for one texture-making script; tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md`. Its calls are taken as accepted. The defaults are the owner's (Tones and the mockup's numbers, confirmed 2026-11-15). Its three questions don't block: the plan builds the accent edge on checked icon buttons (Question 1), the thumb at `kit-edge` behind one constant, `ST.THUMB_REST` (Question 2), and Danger where it is (Question 3).

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder changes (LibActionButton, oUF, Ace3).
- **Privacy.** No account, realm or character name anywhere: code, tests, docs, commits.
- **Commits.** Lowercase `module: imperative summary`. Stage by explicit path, never `git add -A`, `.` or a folder. End with the session's `Co-Authored-By` line.
- **Line endings.** Some working-tree files are CRLF. Never `sed -i`. Edit with the editor and keep each file's endings (`file <path>`).
- **Words.** Sentence case for every name, label and desc, in American spelling ("color"). Name a path with ">": "Global settings > Theme".
- **Resets.** Per setting (the option's `default` or `saved`), never a section's or a page's Reset button.
- **Icons.** Lucide's (`st.icons`), drawn at twice the glyph. An icon-only control always has a tooltip.
- **Scripts.** Kit controls take `control.onClick`, never `SetScript('OnClick')`. The helpers wire with `HookScript` only, never `SetScript`. The game calls `OnEnter` and `OnLeave` with a second argument, `motion`: wrap each as `function(self) ... end`, and fire hover scripts in tests with `true`.
- **Whole pixels.** Every size and offset through `st:RoundToPixel`; a line is `st:GetLineSize(frame)` and a bar two of them; a size read back is rounded, never ceiled. A new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard with `stub.size_noise` at `2 ^ -14`, `-2 ^ -14` and `0`.
- **States through the helpers.** From the task that converts a file on, nothing in it reads the Accent at a strength, a Buttons > Normal, Hover, Pushed or Checked color, `st.HOVER_TINT`, `st.TINT_ROW` or `st.TINT_OBJECT`, or sets a state texture's color, for a state. Markers and progress fills keep `st:Color('accent')`. Task 11's scan enforces it on every file.
- **Blizzard and secure frames.** Nothing written onto a Blizzard frame (taint rule 1); hooks are post-hooks (rule 2); state textures are made and styled out of combat at skin time, as today; in a pass only a color, an alpha and a Fill's texture coordinates are set (`.agents/taint.md` rules 1 to 6). Read `.agents/taint.md` before Tasks 2, 5, 6, 7 and 8.
- **A pass only colors**, as the live colors plan has it, plus a Fill's `SetTexCoord` and `SetAlpha` on a disabled SaftUI frame or a state piece (Ruling 9). `tests/lib/color_cost.lua` checks it.
- **Hot paths.** No change to an element's update, a plate's add, an action button's update or a bag update.
- **Both clients.** Every task's tests run on `T.client('forever')` and `'retail'` where they touch a widget that differs (the micro buttons, the bank, the loot window, the color picker skin).
- **Three looks.** Every area's state tests run under Thick, Thin and Blizzard (`T.theme`, `T.round_trip`): under Blizzard nothing of SaftUI's state pieces shows where Blizzard's art stands in (the spec's table).
- **Rest is unchanged.** Every area task pins, before it changes anything, what its widgets draw at rest (fill, edge, text, icon colors and alpha), and its tests assert the same values after. An earlier assertion changes only where this work changes what it pins, and the report lists each one changed.
- **Tests.** Each task ends green on `tests/run -j2` and runs single files while working.
- **Docs.** Each task updates the docs its files make stale, in the same commit: `AGENTS.md`, the `.agents/*.md` whose `covers:` list its files. Then it runs `agents-doc-parity-check` and `readme-freshness-check`. The design system is Task 11's (one rewrite, then the controller republishes the artifact).
- **In game.** Each task ends with its in-game checks for the owner. Nothing counts as verified until he confirms it.

## Review Focus

1. **The derivation's numbers.** Every worked value of the spec's tables comes out to the byte (within 1 per channel), the hue never passes its target, and nothing returns NaN for black, white, grey or an out-of-range setting. Test: Task 1 `'the test vectors'`, `'extremes'`.
2. **Taint on secure buttons in combat.** The only new calls on action, pet, stance and totem buttons in a pass are `SetVertexColor`, `SetTexCoord` and `SetAlpha` on SaftUI's own textures, and the `SetChecked` post-hook colors SaftUI's backdrop only. Tests: Task 6 `'in combat a pass only colors'`, `'a checked button's edge from the post-hook'`; G12 in game.
3. **Text under fills.** No scripted Layer or Fill sits over a label (draw layer `ARTWORK` -8 and -7, labels in `OVERLAY`), and the text pick turns dark only where the vectors say. Tests: Task 1 `'the text pick'`, Task 3 `'a button's label is over its layer'`.
4. **The Blizzard theme.** Under Blizzard the helpers' pieces are at alpha 0 and the edge is the art's, on every converted widget, and switching Thick to Blizzard and back loses no state. Tests: each area's `'under Blizzard'` case with `T.round_trip`.
5. **The cost of a drag.** An Accent pass over the full UI is under 2,500 setter calls, makes nothing, calls nothing forbidden, and leaves under 4 KB over 100 passes; the dots menu's drag is one pass a frame. Tests: each area's cost case, Task 10 `'a drag in the menu is one pass a frame'`.

---

## How the tasks are cut

| # | Task | Spec part | Needs | Runs beside | Owner can try in game |
| --- | --- | --- | --- | --- | --- |
| 1 | The engine: derivation, settings, cache, migration step 7, the drawing helpers, the fade texture | 2, 3, 5 (storage, migration) | — | — | nothing visible yet but a profile's dropped Buttons colors |
| 2 | Core's widgets and skinners | 4 (A2) | 1 | 3 to 8 | buttons, check boxes, slots, thumbs, edit boxes in the bags and elsewhere |
| 3 | The options kit | 4 (A1) | 1 | 2, 4 to 8 | every `/sui` control, the sidebar, tabs, lists |
| 4 | Edit mode | 4 (A3) | 1 | 2, 3, 5 to 8 | movers, the History list |
| 5 | Bags | 4 (A5) | 1 | 2 to 4, 6 to 8 | view buttons, slots, the Categories tab, the rule editor |
| 6 | Action bars, totem bar, minimap and micro menu | 4 (A4, A6, totems of A8) | 1 | 2 to 5, 7, 8 | bars, keybind mode, totems, micro buttons |
| 7 | Loot | 4 (A7) | 1 | 2 to 6, 8 | rolls, the loot window, the feed |
| 8 | Misc's skins and SaftUI's tracker | 4 (A8, A9) | 1 | 2 to 7 | the color picker skin, Blizzard's tracker's items, RestedXP, SaftUI's tracker |
| 9 | The reworked previews and the Colors page | 5 (previews, the pages) | 1, 3 | — | the Accent's preview, Danger's, the Buttons section |
| 10 | The Accent row's dots menu | 6 | 3, 9 | — | the menu, live while dragging |
| 11 | Retire the four Buttons colors and the tints; the source scan; docs, design system, followups, the checklist | 5 (removed), 7 | 2 to 10 | — | G1 to G16 |

Unit frames get no task: nothing there is a state (spec A10).

Tasks 2 to 8 share no source file and run side by side, each in its own worktree. They share, merged by hand keeping both sides: the `.agents/*.md` docs (each edits only its own files' sentences), `tests/wow/*.lua` (a stub one task appends; see `.agents/workflow.md` on `game.lua`'s closing `end`), and `tests/lib/color_cost.lua` and `tests/lib/states_look.lua`, which Task 1 makes and none of them changes. A module that sets states on a button Core skins (the bags' view buttons, the feed's buttons) registers them itself with `st:AddStates` (Ruling 6 makes a second call merge), so its tests pass with or without Task 2; the full suite runs on `modular` after all seven merge. Task 9 needs Task 3 for the kit's states and edits `Media/colors.lua` after Task 1. Task 10 edits Task 1's `Media/states.lua`, Task 3's `optionstypes.lua` and Task 9's `colors.lua`, so it runs after both. Task 11 runs last.

## Files shared with work in flight

The UI scaling plan's later phase converts the kit's 1-unit lines (`optionslook.lua`'s Box, `optionsrange.lua`, `optionsnav.lua`'s bar, `optionspreview.lua`): Tasks 3 and 9 draw bars and edges with `st:GetLineSize`, and say so in their reports, so that phase has fewer lines to convert. `SaftUI-Core/Config/optionssizes.lua` and `EditMode/Bar/*.lua` changed in `sc-task5`; Tasks 3 and 4 start from `e592f835` or later.

| Task | Shared with the scaling work |
| --- | --- |
| 3 | `optionslook.lua`, `optionsrange.lua`, `optionsnav.lua` (their lines) |
| 4 | `EditMode/mover.lua` (its line) |
| 9 | `optionspreview.lua` |

## Rulings on the spec

1. **Names** (the spec leaves locals to the builder; these are the shared ones): the files `SaftUI-Core/Media/states.lua` (`st.States`, here `ST`) and `SaftUI-Core/Widgets/states.lua`; the functions of the spec's section 3; the test seam `st:StateLook(frame) -> table` (allocates: tests only, never in a pass) in `Widgets/states.lua`; `st.textures.stateFade`; the kit's `W.HoverStates(frame, isDisabled)`; the preview kinds `states` and `danger` and the menu row type `statepreview`; the menu group's field `colorEdit = true`; `ST.MenuGroup()`.
2. **The derived table** (`ST.NewDerived()`, made once by each holder): `{ hover = { r, g, b, a }, pushed = {...}, fill = {...}, fillHover = {...}, edge = {...}, edgeHover = {...}, light = { r, g, b }, dark = { r, g, b }, accent = { r, g, b }, h, p, s, f, d, mode }`. `ST.Derive` writes into it in place. `ST.cache` is one, with `ST.cache.from = { r, g, b, states, serial }` its stamp.
3. **Recompute**: every `st:State*` call without a `derived` argument first compares `st:Color('accent')`'s r, g, b, `st.config.profile.theme.states` (the table itself) and `ST.serial` with `ST.cache.from`; any difference runs `ST.Derive(r, g, b, ST.Settings(), ST.cache)` and stamps it. `ST.Settings()` clamps the saved values into one scratch table made at load (`ST.RANGES`); an unknown `mode` or `direction` reads as the default.
4. **The fade texture**: `SaftUI-Core/Media/Textures/state-fade.tga`, 256 by 8, 32-bit uncompressed true color (type 2), origin bottom left, every pixel white with the alpha of its column `x` (0 to 255) `floor(255 * (1 - x / 255) + 0.5)`: 255 at the left, 0 in the last column. Made by `tools/fade-to-tga.cjs` (Node, no dependencies; its header says how to run it), committed. Set with `SetTexture(st.textures.stateFade, 'CLAMP', 'CLAMP')` (beyond 1 the last column, clear, repeats) and `SetTexCoord(0, 1 / f, 0, 1)`.
5. **Draw layers**: a scripted Layer `ARTWORK` sublevel -8, the Fill `ARTWORK` -7, the Bar `ARTWORK` 1, on the host. An icon button's game pieces keep the layers they have today (the highlight in `HIGHLIGHT`, `st.ThemeArt.HOVER_LAYER`; pushed and checked in `OVERLAY` 0), over the icon's rect.
6. **`st:AddStates` twice** on a frame merges: each field the second call gives replaces the first's, the rest stay, the pieces already made are kept, and it restyles. A shape change errors (one frame, one shape). It returns the frame.
7. **Wiring** (the default for every shape but `'icon'`): `HookScript` on `OnEnter` (hover on), `OnLeave` (hover off), `OnMouseDown` (pushed on, left button), `OnMouseUp` (pushed off) and `OnHide` (hover and pushed off). Leaving while held keeps pushed until the mouse is let go, as the game's buttons do. While disabled, hover and pushed are ignored and cleared. A shape `'icon'` is shown by the game and is not wired.
8. **The record** keeps what a pass reads: the shape, the five states, the pieces, the edge kind and its drawn frame, the text and its body color (read at `AddStates` and `RestyleStates`: the kit's `st.BOX_COLORS.field` for fields, check boxes and selects, `.bg` for buttons and lists, the sidebar's `SIDEBAR_BG` (#171717) for its rows, a theme-drawn frame's `backdropcolor` from the profile's theme), and whether the look is Blizzard's. `st:PaintStates` reads only the record and the cache: no theme lookup in a pass.
9. **What a pass may call**, added to `.agents/architecture.md`'s list and to `tests/lib/color_cost.lua` (`C.SETTERS` gains `'SetTexCoord'` and `'SetAlpha'`, so they are counted, not forbidden): `SetTexCoord` on a Fill, and `SetAlpha` on a disabled SaftUI frame and on a state piece.
10. **Edges**: `edge = 'backdrop'` paints with `SetBackdropBorderColor(r, g, b, 1)` and the rest edge with `SetBackdropBorderColor(unpack(st.BOX_COLORS.edge))`; `'theme'` with `st:SetBorderColor(drawn, r, g, b, 1)` and `st:SetBorderColor(drawn)`; a function gets `(frame, r, g, b)` and `(frame, nil)`.
11. **The text pick's body** for a see-through body is its color alone (the game world behind is not known).
12. **Paint rules** (spec section 3): `st:PaintStates` sets a game piece's color on every call; a scripted piece's only while shown; an edge only while selected or focused; a text only while on a piece. `st:SetState` paints what it shows as it shows it.
13. **Disabled**: `st:SetState(frame, 'disabled', true)` sets `host:SetAlpha(st:StateAlpha())` and `false` sets 1. The kit's `Base:SetDisabled` and `W.SetEnabled` call it (no more literal 0.4).
14. **The check's Mark**: `floor(size / 6)` units in from each side; the kit's 18 box keeps its 3, `st:SkinCheckButton`'s 12 gets 2, the bags' 8 gets 1.
15. **The thumb**: `ST.THUMB_REST = st.BOX_COLORS.edge` (Question 2: one constant to change).
16. **Checked icon buttons** (Task 6): `hooksecurefunc(button, 'SetChecked', AB.OnChecked)` once per button in `AB:SkinButton`, out of combat; `AB.OnChecked(button)` reads `button:GetChecked()` (a secret counts as unchecked) and runs `AB:PaintEdge(button)`, the one function for the backdrop's edge: checked, the Accent; else equipped, the Accent; else the theme's. `AB:UpdateEquippedBorder` calls it too. The pet and stance buttons (SaftUI's) the same. Totem buttons get no hook.
17. **Micro buttons** (Task 6): `hooksecurefunc(button, 'SetButtonState', MicroMenu.OnButtonState)` once per button where SaftUI skins it; it reads `button:GetButtonState() == 'PUSHED'` and colors SaftUI's panel's edge (`skins[button]`), nothing of Blizzard's.
18. **The menu's edit** (Task 10): `OW:OpenMenu` begins a color edit when the menu group has `colorEdit = true` and none is on (`st:InColorEdit()`), and remembers it began it; the menu's `OnHide` ends it only then. The Accent's menu group sets it.
19. **The `states` kind's numbers** (Task 9): six tiles 58 wide, x = `floor((i - 1) * (370 - 58) / 5)` (0, 62, 124, 187, 249, 312), 44 tall; a kit button 46 by 20 at `(6, 12)` from its tile's top left (centred), "Okay"; captions `Rest`, `Hover`, `Pushed`, `Selected`, `Sel. + hover`, `Disabled`. The `danger` kind: two tiles 118 wide at x 0 and 252.
20. **Cost bounds per task** (each case: 100 passes of `st:ColorChanged('accent')` outside an edit): no make, no forbidden call, under 4 KB, and the calls as each task's case says. The full UI's sum is the spec's under 2,500.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Media/states.lua` (new) | derivation, settings, cache, `st:State*`; later the menu group | 1, 10 |
| `SaftUI-Core/Widgets/states.lua` (new) | the drawing helpers, `st:StateLook` | 1 |
| `SaftUI-Core/Media/Textures/state-fade.tga` (new), `tools/fade-to-tga.cjs` (new) | the Fill's ramp | 1 |
| `SaftUI-Core/constants.lua` | `st.textures.stateFade` (1); the tint constants removed (11) | 1, 11 |
| `SaftUI-Core/Config/defaults.lua` | `st.defaults.theme.states` (1); the four Buttons defaults removed (11) | 1, 11 |
| `SaftUI-Core/Media/colors.lua` | migration step 7 and `CO.OLD_COLORS` (1); the Buttons section, previews, the Accent row's preview (9) and menu (10) | 1, 9, 10 |
| `SaftUI-Core/SaftUI-Core_Forever.toc`, `_Mainline.toc`, `Widgets/load.xml`; `tests/lib/shell.lua` | the new files' load order | 1 |
| `tests/lib/color_cost.lua`; `tests/lib/states_look.lua` (new) | the two counted setters; reading a state frame's look | 1 |
| `SaftUI-Core/Widgets/button.lua`, `checkbutton.lua`, `scrollbar.lua`, `radiogroup.lua`; `SaftUI-Core/skinning.lua` | Core's skinners | 2 |
| `SaftUI-Core/Config/optionswidgets.lua`, `optionslook.lua`, `optionscontrols.lua`, `optionstypes.lua`, `optionsrange.lua`, `optionsselect.lua`, `optionslist.lua`, `optionskeybinding.lua`, `optionsitem.lua`, `optionsfont.lua`, `optionsposition.lua`, `optionsbody.lua`, `optionsshare.lua`, `optionsnav.lua`, `optionsresize.lua`, `optionsdialog.lua`, `optionscolorpicker.lua` | the kit | 3 (and `optionstypes.lua`, the color row's slot, 10) |
| `SaftUI-Core/EditMode/mover.lua`, `EditMode/Bar/historylist.lua`, `EditMode/Bar/bargroups.lua` | edit mode | 4 |
| `SaftUI-Bags/header.lua`, `slot.lua`, `containers/bag.lua`, `containers/bank.lua`, `categoriestab.lua`, `ruleeditor.lua`, `category.lua`, `currencies.lua`, `containers/combinedbank.lua` | bags | 5 |
| `SaftUI-ActionBars/skin.lua`, `keybindmode.lua`, `petbar.lua`, `stancebar.lua`; `SaftUI-Misc/totemskin.lua`; `SaftUI-Minimap/microbuttons.lua`, `micromenuitems.lua`, `queuebutton.lua`, `expansionbutton.lua` | bars, totems, micro menu | 6 |
| `SaftUI-Loot/rollbar.lua`, `popup.lua`, `Feed/feed.lua` | loot | 7 |
| `SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua`, `Blizzard_ObjectiveTracker.lua`, `Skinning/addons/restedxp.lua`; `SaftUI-Tracker/rows.lua`, `items.lua`, `window.lua` | Misc's skins, SaftUI's tracker | 8 |
| `SaftUI-Core/Config/optionspreview.lua` | the `states` and `danger` kinds, the `statepreview` row | 9, 10 |
| `SaftUI-Core/Config/optionsmodel.lua`, `optionsmenu.lua`; `tests/lib/reset_walk.lua`, `tests/lib/options_walk.lua` | a color row's menu; the menu's edit; the walks | 10 |
| `tests/core/states_scan_test.lua` (new), `tests/core/color_reads_test.lua`; the docs and design system | the scan, the docs | 11 |

---

### Task 1: The engine

**Files:**
- Create:
  - `SaftUI-Core/Media/states.lua`: the pure functions, the settings, the cache, `ST.Changed`, the `st:State*` readers (Interfaces below; the spec's section 2 formulas exactly).
  - `SaftUI-Core/Widgets/states.lua`: the helpers (Interfaces), the record (Ruling 8), the wiring (Ruling 7), the paint rules (Ruling 12), each record followed with `st:FollowColor(record, 'accent', nil, PaintRecord)` and, where it colors a drawn frame's edge, kept with `st:KeepOwnColors(record, PaintRecord)`.
  - `SaftUI-Core/Media/Textures/state-fade.tga`, `tools/fade-to-tga.cjs` (Ruling 4).
  - `tests/core/states_derive_test.lua`, `tests/core/states_draw_test.lua`, `tests/lib/states_look.lua`.
- Modify:
  - `SaftUI-Core/constants.lua`: `st.textures.stateFade = st:TexturePath('state-fade.tga')`.
  - `SaftUI-Core/Config/defaults.lua`: `st.defaults.theme.states = { mode = 'tones', hover = 0.16, pushed = 0.32, selected = 0.24, fade = 0.70, disabled = 0.40, step = 0.08, shift = 20, chroma = 0.10, direction = 'warm' }`, with a comment naming the spec.
  - `SaftUI-Core/Media/colors.lua`: `CO.MIGRATION_STEPS[7] = { retire = { 'button.normal', 'button.hover', 'button.pushed', 'button.checked' } }` with its comment (dropped: the states are the Accent's now); `CO.OLD_COLORS['button.normal'] = { r = 0.1, g = 0.1, b = 0.1, a = 1 }`, `['button.hover'] = { r = 0.3, g = 0.5, b = 0.7, a = 1 }`, `['button.pushed'] = { r = 0.3, g = 0.4, b = 0.5, a = 1 }`, `['button.checked'] = { r = 0.3, g = 0.5, b = 0.7, a = 1 }`. The four defaults stay until Task 11 (readers still read them until their task lands; nothing visible changes but a profile's dropped values).
  - `SaftUI-Core/SaftUI-Core_Forever.toc`, `SaftUI-Core_Mainline.toc`: `Media\states.lua` after `Media\colors.lua`. `SaftUI-Core/Widgets/load.xml`: `states.lua` first.
  - `tests/lib/shell.lua`: the two files in its lists (the harness self test checks them against the TOCs and `load.xml`).
  - `tests/lib/color_cost.lua`: `C.SETTERS` gains `'SetTexCoord'` and `'SetAlpha'` (Ruling 9); its header says why.
- Test, modify: `tests/core/color_migration_test.lua` (step 7), `tests/lib/color_cost_test.lua` (the two setters counted). The fade file is read by `states_derive_test.lua`'s own case.
- Docs: `.agents/architecture.md` (the colors bullet: `Media/states.lua`, the cache, `ST.Changed`, migration step 7, what a pass may call gains Ruling 9's two; Core's helpers in the api list), `.agents/testing.md` (`states_look.lua`, the new tests), `AGENTS.md` (Core's row: the two files and the texture's tool in `tools/`).

**Interfaces:**
- Produces:

```lua
-- SaftUI-Core/Media/states.lua
st.States = ST
ST.Oklch(r, g, b) -> L, C, H                     -- r, g, b 0..1; H radians (math.atan2)
ST.Srgb(L, C, H) -> r, g, b                      -- clamped 0..1, no fit
ST.InGamut(L, C, H) -> boolean                   -- every linear channel in [-0.0005, 1.0005]
ST.FitChroma(L, C, H) -> C                       -- 24 halvings
ST.Tone(r, g, b, k, settings) -> r, g, b         -- settings.mode 'layers' returns r, g, b
ST.Mix(r1, g1, b1, r2, g2, b2, a) -> r, g, b
ST.Contrast(r1, g1, b1, r2, g2, b2) -> ratio      -- WCAG 2
ST.NewDerived() -> derived                       -- Ruling 2's table
ST.Derive(r, g, b, settings, derived) -> derived -- in place
ST.Settings() -> settings                        -- the profile's, clamped (one scratch table)
ST.RANGES = { hover = { 0, 0.6 }, pushed = { 0, 0.8 }, selected = { 0, 0.6 }, fade = { 0.1, 1 },
	disabled = { 0.1, 0.9 }, step = { 0.02, 0.2 }, shift = { 0, 60 }, chroma = { 0, 0.3 } }
ST.MODES = { 'layers', 'tones', 'hue' }; ST.DIRECTIONS = { 'warm', 'cool' }
ST.DARK_TEXT = { 17 / 255, 17 / 255, 17 / 255 }; ST.THUMB_REST = st.BOX_COLORS.edge
ST.cache, ST.serial
ST.Changed()                                     -- serial + 1, then st:ColorChanged('accent')
st:StateColor(name, derived) -> r, g, b, a       -- 'hover', 'pushed', 'fill', 'fillHover', 'edge', 'edgeHover'
st:StateSolid(name, r, g, b, derived) -> r, g, b -- 'hover' | 'pushed'
st:StateText(name, r, g, b, derived) -> r, g, b  -- 'rest', 'hover', 'pushed', 'fill', 'fillHover'
st:StateFade(derived) -> right                   -- 1 / f
st:StateAlpha(derived) -> d

-- SaftUI-Core/Widgets/states.lua
st:AddStates(frame, shape, opts) -> frame        -- shape: 'box', 'row', 'tab', 'check', 'thumb', 'knob', 'icon', 'mover', 'glyph'
	-- opts: host, inset, edge ('backdrop' | 'theme' | fn | false), bar ('left' | 'bottom'), text (fs or list),
	--       textRest (fn -> r, g, b), body ({ r, g, b } | fn), mark (texture), glyph (texture | fs), glyphRest (fn),
	--       game (true), checked (true), pieces ({ hover, pushed, checked }: existing textures, colored only),
	--       wire (boolean), blizzard (fn -> boolean), solidRest (fn -> r, g, b)
st:SetState(frame, key, on)                      -- 'hover', 'pushed', 'selected', 'focus', 'disabled'
st:GetState(frame, key) -> boolean
st:PaintStates(frame, derived)
st:RestyleStates(frame)
st:RemoveStates(frame)
st:StateLook(frame) -> { shape, hover, pushed, selected, focus, disabled, alpha,
	layer = { shown, r, g, b, a, layer, sublevel, blend }, fill = { shown, r, g, b, a, right, blend },
	edge = { r, g, b, a }, bar = { shown, r, g, b, width }, mark = { shown, r, g, b },
	text = { r, g, b }, glyph = { r, g, b }, solid = { r, g, b } }   -- tests only

-- tests/lib/states_look.lua: local SL = load_test_file('lib/states_look.lua')
SL.rgb(t) -> '0.36,0.78,1.00'          -- r, g, b rounded to 2 places (t a table of StateLook)
SL.bytes(t) -> 'RRGGBB'                -- each channel floor(v * 255 + 0.5)
SL.hover_over(st, body) -> 'RRGGBB'    -- the cache's hover composited over body, for expected values
SL.each_look(fn)                       -- runs fn under Thick, Thin and Blizzard (T.round_trip)
```

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/states_derive_test.lua (load_core_helpers(); local ST = SaftUI.States)
local function hex(r, g, b) return ('%02x%02x%02x'):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)) end
local function within(label, got, want) -- each byte within 1 of want ('rrggbb')
	-- for each of the three channels: check(math.abs(byte(got, i) - byte(want, i)) <= 1, label .. ': ' .. got .. ' ~ ' .. want)
end
test('OKLCH of the presets', function()
	-- ST.Oklch(0, 173/255, 240/255): near(L, 0.7061, 1e-4), near(C, 0.1505, 1e-4), near(deg(H), 235.32, 0.01)
	-- #8a5cf5: 0.6040, 0.2177, 292.50; #e6c84a: 0.8360, 0.1450, 95.58
	-- round trip: ST.Srgb(ST.Oklch(x)) is x to 1e-6 for the three presets and #000000, #ffffff, #808080
end)
test('the test vectors: tones', function()
	-- the spec's tones table, every cell: ST.Tone(preset, k, { mode = 'tones', step = 0.08 }) for k = -3..3 (not 0)
	-- e.g. within('#00adf0 +1', hex(ST.Tone(0, 173/255, 240/255, 1, TONES)), '5cc6ff'); -1 '0093cd'; +2 'a1dcff'; -3 '006189'
	-- #8a5cf5: -3 '49009c' .. +3 'cdc2ff'; #e6c84a: -3 '967d00', -1 'ccae28', +1 'ffe370', +3 'ffffff'
end)
test('the test vectors: hue-shifted, warm and cool', function()
	-- warm (shift 20, chroma 0.10): #00adf0 -3 '4c3fc2' -2 '5660d7' -1 '3888e9' +1 '1ccef0' +2 '5fecec' +3 'b5ffea'
	-- #8a5cf5 -1 '5a44ed' (its hue 280.0: it stops at the target) +1 'c26eef'; #e6c84a -1 'e99f00' +1 'f7e579' (100.0)
	-- cool: #00adf0 -1 '0098b2' +1 '89bcff'; #8a5cf5 -1 '9721c9' +1 '878aff'; #e6c84a -1 'c8b100' +1 'ffdeaf'
	-- the hue never passes its target: for every preset and k in 1..6, the warm +k hue is between the start and 100 the short way
end)
test('the gamut fit', function()
	-- ST.InGamut(ST.Oklch(preset)) for the presets; #00adf0 +1 before the fit is out of gamut and after it C is near 0.1271
	-- ST.FitChroma of an in-gamut color returns its C unchanged
end)
test('the composites and the text pick at the defaults', function()
	-- over 0.12: the spec's composites table, every cell, e.g. Tones #00adf0 hover '283943' light, pushed '154456',
	-- fill start '174151', selected + hover start '355b70'; Layers #00adf0 hover '1a3540'; Hue #e6c84a pushed '5f4815'
	-- ST.Contrast(composite, Text > Normal) near the table's ratio to 0.05; the pick is Text > Normal for every cell
end)
test('the text pick turns dark where the vectors say', function()
	-- hover 0.6: #00adf0 Tones over 0.12 is '4383a5' and st:StateText('hover', 0.12, 0.12, 0.12) is ST.DARK_TEXT;
	-- Layers '0c749c' stays Text > Normal; #e6c84a Layers '968439' dark; pushed 0.8 #00adf0 Tones '067caa' dark
end)
test('solids', function()
	-- Layers #00adf0 over ST.THUMB_REST: hover '1f86af', pushed '0b9fd7'; over Text > Normal: '5cc4e2', '22b5eb'
	-- Tones: st:StateSolid('hover', any rest) is T+ ('5cc6ff'), 'pushed' T- ('0093cd')
end)
test('extremes: black, white, grey, no NaN', function()
	-- #000000: '020202', '000000'; #ffffff: 'ffffff', 'e4e4e4'; #808080 Tones and Hue both '989898', '696969';
	-- #0a0a0a '1c1c1c', '010101'; #ff0000 Tones 'ff6a59', 'd50000', Hue 'fa7400', 'd00055'
	-- every channel of every result is a number with v == v (not NaN), in 0..1
end)
test('the settings: defaults, clamps, unknown words', function()
	-- with no saved states ST.Settings() is the defaults; hover 2 reads 0.6, fade 0 reads 0.1, mode 'neon' reads 'tones'
end)
test('the cache computes once per change and makes nothing', function()
	-- a spy on ST.Derive: 100 st:StateColor('hover') reads -> 1 call; set the Accent's r -> the next read 1 call;
	-- ST.Changed() -> 1 call and a pass of 'accent'; a profile switch (another states table) -> 1 call
	-- 1000 reads leave under 1 KB (collectgarbage('count'))
	-- st:StateColor('hover') at the defaults is 92/255, 198/255, 255/255 (each within 1/255), 0.16
	-- st:StateFade() is 1 / 0.7; st:StateAlpha() is 0.4; st:StateColor('nope') errors naming the caller
end)
test('migration step 7 drops the four Buttons colors and keeps Danger', function()
	-- a profile at version 6 with colors.button.hover, .normal, .pushed, .checked saved and .danger customized:
	-- after st:MigrateColors: the four nil, danger unchanged, colors.version 7; running it again changes nothing
end)
test('the fade texture', function()
	-- read SaftUI-Core/Media/Textures/state-fade.tga: type 2, 256 x 8, 32 bits; column 0 alpha 255, 64 alpha 191,
	-- 128 alpha 127, 255 alpha 0; every pixel's r, g, b 255
end)
```

```lua
-- tests/core/states_draw_test.lua (load_core_helpers(); C = load_test_file('lib/color_cost.lua'); SL = states_look)
-- each case makes a frame drawn by the theme engine (st:SetTemplate(f, 'theme', 'solid', 'control')) or a kit Box
test("a box: rest is untouched; hover tints the body inside the edge, under the text", function()
	-- before AddStates: the frame's fill and edge; after AddStates and at rest: the same values
	-- SetState(f, 'hover', true): layer shown, SL.bytes == '5cc6ff' at a 0.16, blend 'BLEND', layer 'ARTWORK' -8,
	-- its points inset by st:DrawnInset(f); the edge unchanged; hover false: hidden
end)
test('pushed wins over hover; a disabled box ignores both and dims', function()
	-- hover then pushed: layer '0093cd' at 0.32; pushed off with hover on: back to hover
	-- disabled: alpha 0.4, layer hidden, hover and pushed cleared; a later OnEnter shows nothing
end)
test('selected: the edge in the accent and a fill fading over 70%; selected + hover in the lighter tone', function()
	-- selected: edge '00adf0' at 1, fill shown, '00adf0' at 0.24, right 1/0.7, ARTWORK -7, texture st.textures.stateFade
	-- + hover: layer '5cc6ff' 0.16, fill '5cc6ff' 0.24, edge '5cc6ff'; + pushed: layer pushed, fill and edge '00adf0'
end)
test('focus is the accent edge; the body is unchanged', ...)
test('a row: bar two lines at its left, a tab: two lines along its bottom', function()
	-- at k 1 the bar is 2 wide; under a scaled world (scaled_test, 1.55) it is 2 * st:GetLineSize(row)
end)
test('a check: edge, mark and fill when selected; the mark floor(size / 6) in', ...)
test('a thumb and a knob: solid fills from their rest colors', ...)
test("an icon: the game pieces are the button's own highlight, pushed and checked textures, BLEND, colored on every pass", function()
	-- GetHighlightTexture() is the record's hover piece, blend 'BLEND'; checked uses the fade texture and right 1/0.7
end)
test('a glyph: rest its own color; hover the lighter tone; Layers the accent', ...)
test('the text on a fill follows the pick, and its rest color comes back', ...)
test('under Blizzard the pieces are held at alpha 0 and the edge is the art', function()
	-- blizzard = function() return true end: SetState hover -> layer alpha 0; selected -> no edge call
	-- T.round_trip('box', ...): Thick, Blizzard, Thick again: states kept, pieces back at full
end)
test('AddStates twice merges and makes no second piece; a new shape errors', ...)
test('RemoveStates forgets the frame: a pass paints nothing of it', ...)
test("a theme recolor puts a selected box's accent edge back (KeepOwnColors)", function()
	-- selected; st:RecolorThemed() -> edge '00adf0'
end)
test('a pass: game pieces always, scripted pieces only while shown, nothing made', function()
	-- 500 icons and 500 boxes at rest, 20 boxes selected; m = C.measure(function() st:ColorChanged('accent') end, 100)
	-- m.made 0, m.forbidden.total 0, m.kb < 4; per pass m.calls.total <= 500 * 2 + 20 * 4
	-- the boxes at rest: 0 setter calls; C.print('states', m)
end)
test('in combat a pass only colors', function()
	-- stub.in_combat = true; same measure: forbidden 0 (no Show, Hide, SetPoint on any frame)
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/states_derive_test.lua tests/core/states_draw_test.lua tests/core/color_migration_test.lua`. Expected: FAIL, `SaftUI.States` is nil.
- [ ] **Step 3: Implement** as the Interfaces and Rulings 1 to 14 and 20 say: the formulas of the spec's section 2 to the letter (constants as given, `cbrt` keeping the sign, `%` for the hue's modulo), the helpers' pieces as its section 1 table. Run `node tools/fade-to-tga.cjs` once to write the texture (from outside the repo's sandbox if it needs one) and commit the file.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`, then `tests/run --scales=all tests/core/states_draw_test.lua`. Expected: PASS. Nothing else changed: no reader calls the helpers yet.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Media/states.lua SaftUI-Core/Widgets/states.lua SaftUI-Core/Media/Textures/state-fade.tga tools/fade-to-tga.cjs SaftUI-Core/constants.lua SaftUI-Core/Config/defaults.lua SaftUI-Core/Media/colors.lua SaftUI-Core/SaftUI-Core_Forever.toc SaftUI-Core/SaftUI-Core_Mainline.toc SaftUI-Core/Widgets/load.xml tests/lib/shell.lua tests/lib/color_cost.lua tests/lib/color_cost_test.lua tests/lib/states_look.lua tests/core/states_derive_test.lua tests/core/states_draw_test.lua tests/core/color_migration_test.lua .agents/architecture.md .agents/testing.md AGENTS.md
git commit -m "core: derive every interaction state from the accent, and draw them through one set of helpers"
```

**In-game checks:**
- Both clients: log in with no Lua errors; nothing looks different yet.
- A profile that had Buttons > Hover changed: the Colors page still shows the row (until Task 11), at its default now.

---

### Task 2: Core's widgets and skinners

**Files:**
- Modify:
  - `SaftUI-Core/Widgets/button.lua`: `st:SkinButton` calls `st:AddStates(button, 'box', { edge = 'theme', text = <its font string>, body = <the drawn theme's backdrop>, blizzard = <st:IsBlizzardLook of its theme and background> })`; its flat highlight and pushed textures and its disabled texture go (no `SetHighlightTexture` on it; `PaintHighlight` and `PaintPushed` and their follows go); post-hooks on `Enable`, `Disable` and `SetEnabled` set the disabled state, except on a Blizzard panel button (`skin.own`: its art and alpha stay); `st:SetButtonPressed` also sets selected; `Draw` runs `st:RestyleStates(button)` after a look change.
  - `SaftUI-Core/Widgets/checkbutton.lua`: its default style `'check'` (the checked texture is the Mark, `floor(12 / 6)` = 2 in; a post-hook on `SetChecked` and `PostClick` sets selected); `'button'` style `'box'` (selected while checked: Edge and Fill; its `Repaint` for Blizzard's pressed art stays); `'bare'` a `'box'` with `edge = false` (the Layer only; its checked texture is its caller's). `Flat`, `PaintChecked`, `PaintHighlight`, `PaintFlatHighlight` and their follows go.
  - `SaftUI-Core/Widgets/scrollbar.lua`: `st:AddStates(thumb, 'thumb', { solidRest = function() return unpack(ST.THUMB_REST) end, blizzard = ... })`; `ColorThumb` becomes `st:PaintStates(thumb)` inside `DrawScrollBar`; the three Buttons follows go; the hooks set hover and pushed.
  - `SaftUI-Core/Widgets/radiogroup.lua`: the pick is `st:SetState(button, 'selected', picked)`; `ColorPicked`, its follow and its `KeepOwnColors` go (a None group no longer errors: nothing indexes `button.backdrop`).
  - `SaftUI-Core/skinning.lua`: `st:SkinActionButton` registers `'icon'` with `game = true` over its hover and pushed textures (made as today), `blizzard` from its look; the hover's blend is `BLEND` under SaftUI's look (the `hoverBlends` table and `PaintHover` and its follow go); under Blizzard `ThemeArt.StyleState` as today; the disabled texture stays (spec call 8). `st:SkinEditBox`'s focus: `ColorFocused` sets `st:SetState(backdrop, 'focus', ...)` on its backdrop of SaftUI's (registered `'box'`, `edge = 'theme'`, `wire = false`), in the Accent; white goes. `st:EnableResizing`: `'glyph'` on the corner (its pushed and highlight textures are the glyph's states; `PaintCorner` goes).
- Create: `tests/core/widget_states_test.lua`.
- Test, modify: `tests/core/button_opacity_test.lua` (only Danger's cases stay; the rest move here or go), `tests/core/live_widgets_test.lua` (Buttons follows become the Accent's), `tests/core/skinning_test.lua` (white focus becomes the Accent), `tests/core/theme_core_frames_test.lua` (the radio group's pick).
- Docs: `.agents/architecture.md` (Core's skinners' states; the radio group; the edit box's focus), `.agents/taint.md` (the recipe's state textures: `BLEND`, made by the helper; rule 1's list unchanged: nothing is written onto a frame).

**Interfaces:**
- Consumes: Task 1's `st:AddStates`, `st:SetState`, `st:PaintStates`, `st:RestyleStates`, `ST.THUMB_REST`, `C.measure`, `SL.*`.
- Produces: every frame `st:SkinButton`, `st:SkinCheckButton`, `st:SkinActionButton`, `st:SkinNewScrollBar`, `st:CreateRadioGroup`, `st:SkinEditBox` and `st:EnableResizing` touch is a state frame; a module may call `st:SetState` on it.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/widget_states_test.lua (load_core_helpers(); C, SL)
test('a skinned button at rest is drawn as before', function()
	-- st:CreateButton(nil, UIParent, 'Okay'): T.drawn(b) 'theme,solid,control', T.fill(b) and T.edge(b) today's values
	-- (recorded in this file from today's code before Step 3), its label's color unchanged
end)
test('a skinned button: hover and pushed tint its body under the label; disabled dims it', function()
	-- fire OnEnter(true): SL.bytes(look.layer) '5cc6ff' 0.16 ARTWORK -8; the label's draw layer OVERLAY, over it
	-- GetHighlightTexture() is nil (no game highlight over the label); OnMouseDown: '0093cd' 0.32
	-- b:Disable(): alpha 0.4; b:Enable(): 1
end)
test("a skinned button selected: the theme's edge in the accent and the fade; st:SetButtonPressed sets it", ...)
test("a Blizzard panel button st:SkinButton skins keeps the game's disabled art and alpha", ...)
test('a check box: off, hover, checked (edge, mark 8 square, fade), checked + hover; button style; bare style', function()
	-- checked by a click (PostClick) and by SetChecked(true) from code; 'bare': only a layer, its checked texture untouched
end)
test('a scroll bar thumb rests in kit-edge and is solid T+ and T- under the mouse and held', ...)
test('a radio group picks with the selected look; a group drawn with None no longer errors', ...)
test('st:SkinActionButton: hover BLEND T+ at 0.16 over the icon, pushed T- at 0.32, the disabled texture kept', ...)
test("st:SkinEditBox's focus is the accent edge, kept through a recolor; under Blizzard none", ...)
test('a resize corner is a glyph: white at rest, the lighter tone under the mouse and held', ...)
test('under Blizzard: panel art, Settings check art, MinimalScrollBar art, the state art; no SaftUI piece shows', function()
	-- SL.each_look over one of each: under Blizzard every piece's alpha 0 or hidden, T.art(frame) as today
end)
test('a pass over 200 Core widgets and 700 slots: under 1,500 calls, nothing made or forbidden, under 4 KB', function()
	-- 100 buttons, 50 check boxes, 50 thumbs at rest; 700 st:SkinActionButton slots
	-- m = C.measure(function() st:ColorChanged('accent') end, 100): calls per pass <= 700 * 2 + 50; m.made 0; forbidden 0; kb < 4
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/widget_states_test.lua`. Expected: FAIL, the hover is Buttons > Hover's.
- [ ] **Step 3: Implement** as listed under Files. Pin the rest look in the test before changing the code.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS; the report names every earlier assertion changed.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Widgets/button.lua SaftUI-Core/Widgets/checkbutton.lua SaftUI-Core/Widgets/scrollbar.lua SaftUI-Core/Widgets/radiogroup.lua SaftUI-Core/skinning.lua tests/core/widget_states_test.lua tests/core/button_opacity_test.lua tests/core/live_widgets_test.lua tests/core/skinning_test.lua tests/core/theme_core_frames_test.lua .agents/architecture.md .agents/taint.md
git commit -m "core: buttons, check boxes, thumbs, slots, radios and edit boxes draw their states from the accent"
```

**In-game checks:**
- A bag window's header buttons, the Bag Slots toggle: hover tints, pressed tints darker, the label clear over it.
- Bag slots: a faint tint under the mouse (G7, first part); a scroll thumb lighter at rest, light blue under the mouse.
- The bag search box and the chat edit box: a blue edge while typing.

---

### Task 3: The options kit

**Files:**
- Modify:
  - `SaftUI-Core/Config/optionswidgets.lua`: `Base:SetDisabled` sets `st:SetState(self.frame, 'disabled', ...)` where its frame is a state frame, else `SetAlpha(st:StateAlpha())` (no literal 0.4).
  - `SaftUI-Core/Config/optionslook.lua`: `W.HoverStates(frame, isDisabled)` (`st:AddStates(frame, 'box', { edge = 'backdrop', body = <the box's fill> })`, honouring `isDisabled`) in place of `W.HoverEdge`; `W.Edge` stays for focus (`st:SetState(frame, 'focus', lit)`); `Kit.CheckBox` registers `'check'` with its mark; `Kit.SetCheck` sets selected; under Blizzard `LookCheckBox` keeps its art and the helper's `blizzard` is true.
  - `SaftUI-Core/Config/optionscontrols.lua`: `Paint(control)` sets `selected` (`control.on`), `hover` and `disabled`; the edge, layer and fill are the helper's; the icon keeps its rule (A while on; `hoverIcon` and links `edgeHover` under the mouse; else Muted); `W.IconLink` is a `'glyph'`; the nudges' arrows `'glyph'`; `DISABLED_ALPHA` goes.
  - `SaftUI-Core/Config/optionstypes.lua`: the toggle, input (focus), color field, execute and `MakeCheck` take `W.HoverStates`; the execute's label move stays.
  - `SaftUI-Core/Config/optionsrange.lua`: the knob is `'knob'` (rest Text > Normal; its texture's color the Solid); the fill stays A (progress); the value box `W.HoverStates` and focus.
  - `SaftUI-Core/Config/optionsselect.lua`, `optionskeybinding.lua` (waiting is selected; "Press a key" stays A), `optionsfont.lua` (its face), `optionscolorpicker.lua` (chips and was/new blocks `W.HoverStates`), `optionsdialog.lua` (its input): `W.HoverStates`.
  - `SaftUI-Core/Config/optionslist.lua`: list and check list rows are `'row'` (text: the row's; body `st.BOX_COLORS.bg`); the picked entry is selected (Bar + Fill, its text by the pick: no longer A); a check list row's box takes its row's hover; `TINT_ROW` goes; under Blizzard `look.rowHover` as today.
  - `SaftUI-Core/Config/optionsbody.lua`: search result rows `'row'`; `OB.Accent()` stays for markers.
  - `SaftUI-Core/Config/optionsshare.lua`: the reset icon `'glyph'`; the links stay `'glyph'` links (A, Strong under the mouse: unchanged); the own mark and labels unchanged.
  - `SaftUI-Core/Config/optionsitem.lua`: the slot (`Kit.NewSlot`, `Kit.PaintSlot`) is a `'glyph'` (white under Blizzard, as today); the item's box `'check'`.
  - `SaftUI-Core/Config/optionsposition.lua`: the dots `'glyph'` (4 square grey, `edgeHover` under the mouse, 8 square A picked, `edgeHover` picked and hovered).
  - `SaftUI-Core/Config/optionsnav.lua`: sidebar rows `'row'` (`bar = 'left'`, body #171717, text Normal; `HOVER` goes; the current page is selected); tabs `'tab'` (`bar = 'bottom'`, the underline is the Bar, `textRest` Muted); the title's page arrow `'glyph'`; under Blizzard the list and tab art as today.
  - `SaftUI-Core/Config/optionsresize.lua`: the grip `'glyph'` (`PaintGrip` and its Buttons follows go).
- Create: `tests/core/kit_states_test.lua`.
- Test, modify: the kit tests that pin an accent edge on hover or the sidebar's grey (`tests/core/options_controls_test.lua`, `options_widget_look_test.lua`, `options_sidebar_test.lua`, `options_list_test.lua`, `options_range_test.lua`, `options_toggle_guard_test.lua`, `options_window_look_test.lua`, `options_kit_test.lua`, `options_resize_test.lua`, `state_colors_test.lua`, `theme_blizzard_controls_test.lua`): only the assertions this work changes, each listed in the report.
- Docs: `.agents/edit-mode.md` (the kit's look: `W.HoverStates`, `W.Edge` for focus, the states by control; the sidebar, tabs, lists, the position block).

**Interfaces:**
- Consumes: Task 1's helpers and readers.
- Produces: `W.HoverStates(frame, isDisabled)`; every kit control, list row, sidebar row and tab is a state frame (`st:GetState` reads it).

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/kit_states_test.lua (load_test_file('core/options_window_helpers.lua'); C, SL)
test('every kit control at rest is drawn as before', function()
	-- the window open on Global settings > Theme under Thick: each control's fill, edge, text and alpha equal the
	-- values pinned in this file from today's code (Box: field 0.078 / bg 0.12, edge 0.3); a tab Muted, the active Normal
end)
test("a button's label is over its layer; hover changes the body, never the edge", function()
	-- Reload UI under the mouse: layer '5cc6ff' 0.16 ARTWORK -8, the label OVERLAY; edge 0.3, 0.3, 0.3 (unchanged)
end)
test('an input: hover tints, focus is the accent edge, both at once compose', ...)
test('a toggle: hover, on (edge, mark, fade), on + hover; disabled 40% with its label Muted', ...)
test('an icon button on: the accent edge and the fade, its icon in the accent', ...)
test('the sidebar: hover tints (no grey); the current page has a 2-line bar and the fade; under Blizzard the list art', ...)
test('tabs: hover tints and the text goes Normal; the active one has the underline as the bar and the fade', ...)
test('a dropdown list: rows tint under the mouse; the picked row has the bar and fade and its text by the pick', ...)
test('the range: the fill stays the accent; the knob is solid T+ under the mouse and T- while dragged', ...)
test('glyphs: the reset icon, dots, links, nudges, the page arrow, the position dots', function()
	-- reset icon Muted, then '5cc6ff' under the mouse; a link '00adf0', then Text > Strong; a picked dot 8 square
end)
test('the keybinding button waiting for a key: the selected look, "Press a key" in the accent', ...)
test('under Blizzard: every control wears its art and no SaftUI piece shows (T.round_trip)', ...)
test('whole pixels: the bars and pieces under Thick, Thin and Blizzard (P.off == 0, size noise)', ...)
test('a pass over the open window: under 300 calls, nothing made or forbidden, under 4 KB', function()
	-- the window open on Global settings > Theme with a dropdown open: m = C.measure(accent pass, 100)
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/kit_states_test.lua`. Expected: FAIL, the hover is the edge's.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionswidgets.lua SaftUI-Core/Config/optionslook.lua SaftUI-Core/Config/optionscontrols.lua SaftUI-Core/Config/optionstypes.lua SaftUI-Core/Config/optionsrange.lua SaftUI-Core/Config/optionsselect.lua SaftUI-Core/Config/optionslist.lua SaftUI-Core/Config/optionskeybinding.lua SaftUI-Core/Config/optionsitem.lua SaftUI-Core/Config/optionsfont.lua SaftUI-Core/Config/optionsposition.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/Config/optionsshare.lua SaftUI-Core/Config/optionsnav.lua SaftUI-Core/Config/optionsresize.lua SaftUI-Core/Config/optionsdialog.lua SaftUI-Core/Config/optionscolorpicker.lua tests/core/kit_states_test.lua .agents/edit-mode.md
git add tests/core/options_controls_test.lua tests/core/options_widget_look_test.lua tests/core/options_sidebar_test.lua tests/core/options_list_test.lua tests/core/options_range_test.lua tests/core/options_toggle_guard_test.lua tests/core/options_window_look_test.lua tests/core/options_kit_test.lua tests/core/options_resize_test.lua tests/core/state_colors_test.lua tests/core/theme_blizzard_controls_test.lua
git commit -m "options: every control, row and tab draws its states from the accent: the body under the mouse, an edge and a fade when selected"
```

(Stage only the test files the task changed.)

**In-game checks:** G1, G2, G3 under Thick, Thin and Blizzard.

---

### Task 4: Edit mode

**Files:**
- Modify:
  - `SaftUI-Core/EditMode/mover.lua`: each overlay is `'mover'` (`edge = 'theme'` on its backdrop, its rest edge white and body black 30% as today, `blizzard` while `st:IsBlizzardLook('theme', 'solid')`); `SetBorderColor(mover, selected)` becomes `st:SetState(overlay, 'selected', selected)` and the selection kit under Blizzard as today; hover from the overlay's own enter and leave (a drag keeps hover: spec call 9); `TINT_OBJECT` goes; `EM:OnColorsChanged` still fires `ColorsChanged` (the helper paints the movers on the pass).
  - `SaftUI-Core/EditMode/Bar/historylist.lua`: rows `'row'`; the current step is selected (its mark becomes the Bar); `LookList` and `RecolorList` stop painting the hover (the helper does); under Blizzard `look.rowHover` as today; `TINT_ROW` goes.
  - `SaftUI-Core/EditMode/Bar/bargroups.lua`: `EM.RecolorNumberBox` keeps only the arrows' Muted; the edit box's focus edge is the helper's (`W.NumberBox` is Task 3's box).
- Create: `tests/core/editmode_states_test.lua`.
- Test, modify: `tests/core/editmode_movers_test.lua`, `editmode_colors_test.lua`, `editmode_history_test.lua`, `theme_blizzard_editmode_test.lua` (only what this changes).
- Docs: `.agents/edit-mode.md` (the movers' look, the History rows).

**Interfaces:**
- Consumes: Task 1's helpers.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/editmode_states_test.lua (load_test_file('core/editmode_helpers.lua'); C, SL)
test('a mover at rest is drawn as before: a white line, black 30%', ...)
test('a mover under the mouse tints (new); selected: the accent edge and the fade; both compose', function()
	-- hover: layer '5cc6ff' 0.16; selected: edge '00adf0', fill '00adf0' 0.24 right 1/0.7 (no flat 15%)
end)
test("the overlap picker's other movers keep their 40%; under Blizzard the selection kit", ...)
test('History rows: hover tints; the current step is the selected row', ...)
test('a pass with 60 movers shown: under 250 calls, nothing made or forbidden, under 4 KB', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/editmode_states_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/EditMode/mover.lua SaftUI-Core/EditMode/Bar/historylist.lua SaftUI-Core/EditMode/Bar/bargroups.lua tests/core/editmode_states_test.lua tests/core/editmode_movers_test.lua tests/core/editmode_colors_test.lua tests/core/editmode_history_test.lua tests/core/theme_blizzard_editmode_test.lua .agents/edit-mode.md
git commit -m "editmode: movers tint under the mouse and a selected one has the accent edge and fade; History rows as rows"
```

**In-game checks:** G10.

---

### Task 5: Bags

**Files:**
- Modify:
  - `SaftUI-Bags/header.lua`: each view button `st:AddStates(button, 'box', { edge = 'theme', glyph = <its pieces> })` after `st:CreateButton` (Ruling 6); the current view `st:SetState(button, 'selected', true)` in place of `ColorLit` and its `KeepOwnColors`; under Blizzard `st:SetButtonPressed` as today; the Edit toggle and funnel are Core's `'button'` style (Task 2) and this file only sets nothing new for them.
  - `SaftUI-Bags/slot.lua`: `INV:SkinSlot` no longer clears the pushed texture under Thick and Thin (slots gain the pushed tint); the hover is Core's.
  - `SaftUI-Bags/containers/bag.lua`: `RestyleBagSlot` keeps restyling Blizzard's slot after `UpdateTextures` (its texture, points and `BLEND`, not `ADD`), as today, then runs `st:PaintStates(slot)` to put the colors back; the slot is registered `'icon'` once with `pieces = { hover = slot:GetHighlightTexture(), pushed = slot:GetPushedTexture() }` (SaftUI's hover and pushed textures, made when it was skinned, which Blizzard's `UpdateTextures` restyles and `RestyleBagSlot` takes back); `PaintBagSlotHover` and its accent follow go.
  - `SaftUI-Bags/containers/bank.lua`: the tab slots are Core's `'icon'`; the unbought tint stays Danger.
  - `SaftUI-Bags/categoriestab.lua`: list rows `'row'` (`bar = 'left'`, two lines: `BAR_WIDTH` goes); selected sets selected; hover from the row; `TINT_ROW` goes; the `+ New category` link a `'glyph'` link (Strong under the mouse); under Blizzard `look.hover` and `look.picked` as today.
  - `SaftUI-Bags/ruleeditor.lua`: the NOT box `'box'` (on: selected; its label by the pick); `+ Block` and `+ Group` links `'glyph'`; the Caught now tint keeps Text > Warning at its own `CAUGHT_ALPHA = 0.25`.
  - `SaftUI-Bags/category.lua` (the header filter check: Core's `'check'`, its 8 box's mark 1 in), `currencies.lua` and `containers/combinedbank.lua` (`'bare'` checks: the hover only; their own checked looks unchanged).
- Create: `tests/bags/interaction_states_test.lua`.
- Test, modify: `tests/bags/accent_pins_test.lua`, `bag_bar_slot_test.lua`, `bare_check_keep_test.lua`, `categories_list_test.lua`, `live_colors_test.lua`, `rule_editor_test.lua`, `search_box_test.lua`, `state_colors_test.lua`, `theme_test.lua`, `views_switch_test.lua` (only what this changes).
- Docs: `.agents/architecture.md` (the bags' readers: the view buttons, slots, Categories, the rule editor).

**Interfaces:**
- Consumes: Task 1's helpers; Core's `'button'` check style and `st:SkinActionButton` registration (Task 2) when merged; this task's own `st:AddStates` calls stand alone (Ruling 6).

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/bags/interaction_states_test.lua (load_test_file('bags/container_helpers.lua'); C, SL; both clients)
test('every bag widget at rest is drawn as before', ...)
test('view buttons: hover tints; the current view has the accent edge and the fade; under Blizzard the pressed art', ...)
test('item slots: a 16% tint under the mouse in BLEND; a 32% darker tint while pressed (new); bank and tab slots alike', ...)
test("the bag bar's slots: BLEND after Blizzard's UpdateTextures, colored by the helper", ...)
test('the Categories list: hover tints; selected has a 2-line bar and the fade (was 3 and flat)', ...)
test('the rule editor: NOT on has the edge and fade, its label by the pick; links Strong under the mouse; Caught now Warning 25%', ...)
test('the filter check (8): edge, a 6 square mark, the fade when ticked; bare checks keep their own checked look', ...)
test('the unbought slot keeps Danger at 0.3; the selected bank window keeps its accent edge (a marker)', ...)
test('a pass with every bag and both banks open (about 700 slots): under 1,500 calls, nothing made or forbidden, under 4 KB', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/bags/interaction_states_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/bags`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Bags/header.lua SaftUI-Bags/slot.lua SaftUI-Bags/containers/bag.lua SaftUI-Bags/containers/bank.lua SaftUI-Bags/categoriestab.lua SaftUI-Bags/ruleeditor.lua SaftUI-Bags/category.lua SaftUI-Bags/currencies.lua SaftUI-Bags/containers/combinedbank.lua tests/bags/interaction_states_test.lua .agents/architecture.md
git commit -m "bags: view buttons, slots, the categories list and the rule editor draw their states from the accent"
```

(Add the changed test files by path.)

**In-game checks:** G7, on both clients (the bank and the combined bank on retail).

---

### Task 6: Action bars, the totem bar, the minimap and the micro menu

**Files:**
- Modify:
  - `SaftUI-ActionBars/skin.lua`: `AB:SkinButton` registers `'icon'` (`game = true`, `checked = true`, the edge a function: `AB:PaintEdge`); `AB:StyleButton` under SaftUI's look puts the pieces over the icon with `BLEND` (white 15% `ADD`, black 10% and white 30% `ADD` go; `HOVER_ALPHA` goes), under Blizzard `ThemeArt.StyleState` as today; the `SetChecked` post-hook (Ruling 16); `AB:UpdateEquippedBorder` calls `AB:PaintEdge`; `AB:OnColorsChanged('accent')` repaints the edges through `AB:PaintEdge` (the helper paints the pieces); the flash unchanged.
  - `SaftUI-ActionBars/petbar.lua`, `stancebar.lua`: nothing but what the post-hook needs (their buttons call `SetChecked` already).
  - `SaftUI-ActionBars/keybindmode.lua`: the highlight overlay (SaftUI's) is `'box'` with `edge = 'theme'`, selected while it marks a button (spec call 11).
  - `SaftUI-Misc/totemskin.lua`: `'icon'` with the checked Fill, no edge and no hook (spec call 6); `ADD` goes.
  - `SaftUI-Minimap/microbuttons.lua`: under Thick and Thin the highlight is the `hover` piece and the pushed background the Fill (registered `'icon'` with `pieces = { hover = button:GetHighlightTexture(), checked = button.PushedBackground }`: Blizzard's two regions, colored only, the second given the fade texture at skin time as it is given a color today), the panel's edge from the `SetButtonState` post-hook (Ruling 17); `HOVER_ALPHA`, `PUSHED_ALPHA` and `ColorMicroButtons`' hover and pushed parts go (the alert stays).
  - `SaftUI-Minimap/micromenuitems.lua`: `SkinBarButton` registers `'box'` (Layer for hover and pushed, Alpha for disabled; its three textures and their follows go); the tracking button's highlight `'icon'`.
  - `SaftUI-Minimap/queuebutton.lua`, `expansionbutton.lua`: the highlight `'icon'` with `BLEND`; the expansion button's pushed art Blizzard's.
- Create: `tests/actionbars/interaction_states_test.lua`, `tests/minimap/interaction_states_test.lua`, `tests/misc/totem_interaction_states_test.lua`.
- Test, modify: `tests/actionbars/theme_test.lua`, `live_colors_test.lua`; `tests/minimap/state_colors_test.lua`, `theme_test.lua`, `blizzard_look_test.lua`; `tests/misc/totem_state_colors_test.lua`, `theme_test.lua` (only what this changes).
- Docs: `.agents/architecture.md` (the action bars', totem bar's and micro menu's readers), `.agents/taint.md` (the `SetChecked` and `SetButtonState` post-hooks, what they touch; the totem buttons get none).

**Interfaces:**
- Consumes: Task 1's helpers.
- Produces: `AB:PaintEdge(button)`, `AB.OnChecked(button)`, `MicroMenu.OnButtonState(button)`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/actionbars/interaction_states_test.lua (the bars' world; C, SL; both clients)
test('an action button at rest is drawn as before; an equipped one has the accent edge', ...)
test('hover: the highlight BLEND T+ at 0.16 over the icon; pushed: T- at 0.32; checked: the fade at 0.24 and the accent edge', ...)
test("a checked button's edge from the post-hook; unchecked: the equipped accent or the theme's; a secret counts as unchecked", ...)
test('pet and stance buttons the same', ...)
test("keybind mode's highlight is the selected look over the button it marks", ...)
test('under Blizzard: the state art, untinted; no SaftUI piece shows (T.round_trip)', ...)
test('in combat a pass only colors (Review Focus 2)', function()
	-- stub.in_combat = true; m = C.measure(accent pass, 1): forbidden 0 on every button; only SetVertexColor, SetTexCoord, SetAlpha
end)
test('a pass over 164 buttons: under 700 calls, nothing made, under 4 KB', ...)
-- tests/minimap/interaction_states_test.lua
test("micro buttons: the highlight T+ at 0.16; a window open: the fade and the panel's accent edge, off again when it closes", ...)
test('bar items: Layer for hover and pushed, 40% when disabled; tracking, queue and expansion: BLEND hover at 0.16', ...)
test('under Blizzard: Blizzard\'s highlight and pushed art', ...)
test('a pass: under 60 calls, nothing made or forbidden', ...)
-- tests/misc/totem_interaction_states_test.lua
test('totem buttons: hover, pushed, the checked fill; no edge; the flash unchanged; nothing hooked', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run the three files. Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/actionbars tests/minimap tests/misc`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-ActionBars/skin.lua SaftUI-ActionBars/keybindmode.lua SaftUI-ActionBars/petbar.lua SaftUI-ActionBars/stancebar.lua SaftUI-Misc/totemskin.lua SaftUI-Minimap/microbuttons.lua SaftUI-Minimap/micromenuitems.lua SaftUI-Minimap/queuebutton.lua SaftUI-Minimap/expansionbutton.lua tests/actionbars/interaction_states_test.lua tests/minimap/interaction_states_test.lua tests/misc/totem_interaction_states_test.lua .agents/architecture.md .agents/taint.md
git commit -m "actionbars: bars, totems and micro buttons draw hover, pushed and checked from the accent"
```

(Add the changed test files by path.)

**In-game checks:** G8, G9, G12 (in combat).

---

### Task 7: Loot

**Files:**
- Modify:
  - `SaftUI-Loot/rollbar.lua`: the chosen button's icon backdrop (SaftUI's) is `'box'` (`edge = 'theme'`, `wire = false`), selected while chosen; `ColorLit` goes; `LOCKED_ALPHA` goes, the others take `st:StateAlpha()`; "Choice" stays A; the timer stays A (progress).
  - `SaftUI-Loot/popup.lua`: each card (its holder of SaftUI's) is `'row'` with `edge = false`, hover from the row's enter and leave (the edge stays the theme's: `ColorCard`'s accent goes); under Blizzard as today.
  - `SaftUI-Loot/Feed/feed.lua`: each icon button `st:AddStates(button, 'box', { edge = 'theme', glyph = button.icon, glyphRest = <Text > Normal> })` after `st:CreateButton` (Ruling 6); the icon `edgeHover` under the mouse; `TintButton`'s accent goes.
- Create: `tests/loot/interaction_states_test.lua`.
- Test, modify: `tests/loot/roll_held_test.lua`, `roll_skin_test.lua`, `popup_test.lua`, `feed_buttons_test.lua`, `live_colors_test.lua`, `theme_test.lua` (only what this changes).
- Docs: `.agents/architecture.md` (Loot's readers).

**Interfaces:**
- Consumes: Task 1's helpers.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/loot/interaction_states_test.lua (the loot world; C, SL; both clients for the window)
test('roll bars, cards and feed buttons at rest are drawn as before', ...)
test('a chosen roll: the edge and fade on its icon, "Choice" in the accent; the others at 40%', ...)
test('a loot window row tints under the mouse; its edge stays the theme\'s', ...)
test('the feed\'s buttons: Layer for hover, the icon the lighter tone', ...)
test('under Blizzard: Blizzard\'s', ...)
test('a pass with four rolls and the window open: under 60 calls, nothing made or forbidden', ...)
```

- [ ] **Step 2: Run them to see them fail.** Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/loot`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Loot/rollbar.lua SaftUI-Loot/popup.lua SaftUI-Loot/Feed/feed.lua tests/loot/interaction_states_test.lua .agents/architecture.md
git commit -m "loot: the chosen roll, the loot window's rows and the feed's buttons draw their states from the accent"
```

**In-game checks:** G14.

---

### Task 8: Misc's skins and SaftUI's tracker

**Files:**
- Modify:
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua`: Okay and Cancel: `st:AddStates(entry.box, 'box', { edge = 'theme' })`, hover from post-hooks on Blizzard's buttons' `OnEnter` and `OnLeave` (`HookScript`, as today's `hovered`), the Layer on SaftUI's box; `ColorHover`'s accent edge goes; the hex box's focus is the Accent edge (`ColorFocus` white goes).
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua`: the quest item's own hover texture (SaftUI's, `HIGHLIGHT`, never handed to `SetHighlightTexture`) is registered `'icon'` with `pieces = { hover = entry.hover }`, `BLEND`; `ADD` goes.
  - `SaftUI-Misc/Skinning/addons/restedxp.lua`: the steps' highlight textures (SaftUI's) colored `hover` at h through the helper (`'row'`, `wire = false`, shown by the existing `SetBackdropColor` hook); `ColorHighlight`'s header color goes.
  - `SaftUI-Tracker/rows.lua`: quest rows and popup rows `'row'` (the Layer 2 past the row, `L.HOVER_PAD`, as today); `row.hover` and `TR:NewAccent(hover, st.TINT_ROW)` go; the focus bar, popup bar, label and tag stay `TR:NewAccent` (markers).
  - `SaftUI-Tracker/items.lua`: each item button's hover (`HIGHLIGHT`, its own) `'icon'` with `pieces = { hover = button.hover }`, `BLEND`; `TR:NewAccent(button.hover, 0.4)` goes; the in-area edge and the combat dim unchanged.
  - `SaftUI-Tracker/window.lua`: the chevrons `'glyph'` (Muted, `edgeHover` under the mouse; Strong goes).
- Create: `tests/misc/skin_interaction_states_test.lua`, `tests/tracker/interaction_states_test.lua`.
- Test, modify: `tests/misc/color_picker_skin_test.lua`, `objective_tracker_skin_test.lua`, `restedxp_steplist_test.lua`; `tests/tracker/states_test.lua`, `rows_test.lua`, `items_test.lua`, `window_test.lua` (only what this changes). `tests/tracker/source_scan_test.lua` must still pass: nothing new is called on Blizzard's tracker.
- Docs: `.agents/architecture.md` (Skinning's and the tracker's readers), `.agents/taint.md` (the color picker skin's hooks, unchanged in kind).

**Interfaces:**
- Consumes: Task 1's helpers.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/misc/skin_interaction_states_test.lua (the color picker fixture; both clients)
test("the color picker's Okay and Cancel tint under the mouse on SaftUI's box; the hex box's focus is the accent", ...)
test("Blizzard's tracker's quest item: a BLEND tint at 0.16 in its own HIGHLIGHT texture", ...)
test("RestedXP's steps: the hover tint in the tone, shown by RestedXP's own SetBackdropColor", ...)
-- tests/tracker/interaction_states_test.lua (load_test_file('tracker/tracker_world.lua'))
test('quest rows at rest as before; under the mouse a 16% tint 2 past the row; the focus bar unchanged', ...)
test('quest item buttons: a BLEND hover; the combat dim and the in-area edge unchanged', ...)
test('the chevrons: Muted, the lighter tone under the mouse', ...)
test('a pass with 40 rows and their items: under 120 calls, nothing made or forbidden; TR:ColorRows unchanged for text', ...)
```

- [ ] **Step 2: Run them to see them fail.** Expected: FAIL.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/misc tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua SaftUI-Misc/Skinning/addons/restedxp.lua SaftUI-Tracker/rows.lua SaftUI-Tracker/items.lua SaftUI-Tracker/window.lua tests/misc/skin_interaction_states_test.lua tests/tracker/interaction_states_test.lua .agents/architecture.md .agents/taint.md
git commit -m "tracker: rows, quest items and chevrons, and Misc's skins, draw their states from the accent"
```

(Add the changed test files by path.)

**In-game checks:** G15; the color picker skin's buttons and hex box; Blizzard's tracker's items; RestedXP's steps.

---

### Task 9: The reworked previews and the Colors page

**Files:**
- Modify:
  - `SaftUI-Core/Config/optionspreview.lua`: the `button` and `accent` kinds go; `states` (Ruling 19: six kit buttons held with `st:SetState`, painted with `st:PaintStates(piece, pieces.derived)` from `ST.Derive(r, g, b, ST.Settings(), pieces.derived)`; the note under Blizzard) and `danger` (Ruling 19's two tiles: the action flash at 0.4 and a locked slot at 0.3, the picked color times its opacity; the note under Blizzard); the built-in list at the file's end.
  - `SaftUI-Core/Media/colors.lua`: the Buttons section holds only Danger (`{ 'danger', ... }`, its note "Opacity sets how strongly it is drawn: 100% is SaftUI's own."); `PreviewOf` gives Danger `'danger'`; `CO:AccentOption`'s `preview = 'states'` and its new desc (the spec's section 5).
- Test, modify: `tests/core/options_color_preview_test.lua` (the two kinds; every row's preview), `tests/core/colors_test.lua` (the Buttons section), `tests/core/accent_test.lua` (the desc and preview), `tests/core/options_desc_test.lua` (the reset walk of the page, which now has fewer Buttons rows).
- Docs: `.agents/edit-mode.md` (the preview kinds).

**Interfaces:**
- Consumes: Task 1's `ST.Derive`, `ST.NewDerived`, `ST.Settings`, `st:PaintStates(frame, derived)`; Task 3's kit button (`W.Button`) as a state frame.
- Produces: the preview kinds `states` and `danger`; `W.PreviewKinds()` lists `text`, `bar`, `border`, `states`, `danger`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_color_preview_test.lua
test('the states kind: six buttons in their states, in the picked color, the frame of the change', function()
	-- open the picker on Theme > Accent; pick #8a5cf5: the Hover tile's layer '9f7fff' 0.16 (T+, Tones), the Pushed
	-- tile's '7441d9' 0.32, the Selected tile's edge '8a5cf5' and fill 0.24, Sel. + hover's edge '9f7fff', Disabled's alpha 0.4
	-- captions Muted; whole pixels under Thick, Thin and Blizzard; under Blizzard the note and Thick's look
end)
test('the states kind follows the derivation settings: Layers makes the Hover tile the accent itself', ...)
test("the danger kind: the flash at 0.4 and the locked slot at 0.3 times the picked opacity", ...)
test('the Buttons section holds only Danger; every Colors row and the Accent have a preview that opens', ...)
test('a paint: 30 setter calls at most, nothing made; 1000 paints under 4 KB', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/options_color_preview_test.lua`. Expected: FAIL, no `states` kind.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionspreview.lua SaftUI-Core/Media/colors.lua tests/core/options_color_preview_test.lua tests/core/colors_test.lua tests/core/accent_test.lua tests/core/options_desc_test.lua .agents/edit-mode.md
git commit -m "options: the accent's preview shows the states it makes, Danger's its flash, and Buttons keeps only Danger"
```

**In-game checks:**
- Theme > Accent opens the picker with six state tiles that follow the drag; Buttons > Danger with the flash and a locked slot; under Blizzard the note.
- Colors > Buttons shows only Danger.

---

### Task 10: The Accent row's dots menu

**Files:**
- Modify:
  - `SaftUI-Core/Media/states.lua`: `ST.MenuGroup()`, the spec's section 6 in order (the `statepreview` row, Derivation, the Strengths, Tones and Hue shift sections), each setting row with `saved = st.Config.SavedAt('theme', 'states', <key>)`, its desc, `isPercent` where a percent, `disabled` and `disabledDesc` by mode, and a set that writes the profile and calls `ST.Changed()`; the group's `colorEdit = true` (Ruling 18).
  - `SaftUI-Core/Media/colors.lua`: `CO:AccentOption` gains `menu = ST.MenuGroup()` and `menuTitle = 'Accent'`.
  - `SaftUI-Core/Config/optionstypes.lua`: the color widget's slot (`Kit.NewSlot` with `st.icons.ellipsisVertical`, at the field's right after `Kit.FONT_SLOT_GAP`, the control 190 wide when the option has a `menu`, else 170 as today), its tooltip (spec section 6), `Menu`, `OpenMenu`, `ToggleMenu` as the item's; disabled takes the slot's mouse too.
  - `SaftUI-Core/Config/optionsmodel.lua`: the header and `OM.Search` (a color row's menu's settings found on its path), `OM.MenuRoot` for a color option.
  - `SaftUI-Core/Config/optionsmenu.lua`: Ruling 18's edit.
  - `SaftUI-Core/Config/optionspreview.lua`: `W.Define('statepreview', { bare = true, width = 370, ... })`, the `states` strip as a row, painted from the profile (no `derived`: the cache).
  - `tests/lib/reset_walk.lua`, `tests/lib/options_walk.lua`: a color row's menu walked as an item's (`{ 'menu', ... }`).
- Create: `tests/core/accent_menu_test.lua`.
- Test, modify: `tests/core/options_menu_test.lua` (a color row's menu), `tests/core/options_desc_test.lua` (the menu's rows walked), `tests/core/theme_tab_test.lua` (the Accent row 190 wide).
- Docs: `.agents/edit-mode.md` (a color row's menu and slot; the menu's edit), `.agents/architecture.md` (the derivation's settings and their rows).

**Interfaces:**
- Consumes: Task 1's `ST`, Task 3's color widget and kit, Task 9's `states` kind.
- Produces: `ST.MenuGroup()`; the color option fields `menu`, `menuTitle`; the menu group field `colorEdit`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/accent_menu_test.lua (load_test_file('core/options_window_helpers.lua'); C)
test('the Accent row has its swatch, its reset and the dots; a color row without a menu is as before (170)', ...)
test('the menu: its title, the preview, then Derivation, Strengths, Tones, Hue shift, in order, with their descs', ...)
test('by mode: Layers dims Tones and Hue shift with their reasons; Tones dims Hue shift; a dimmed row keeps its value', ...)
test('every setting has a reset once it differs, and the reset puts the default back and passes the accent', function()
	-- Hover to 30%: the reset icon shows; click it: 0.16, ST.serial up, one accent pass
end)
test('a set reaches every state frame: Selected fade to 100% sets each shown fill to right 1', ...)
test('a drag in the menu is one pass a frame, and the whole pass at close (Review Focus 5)', function()
	-- open the menu: st:InColorEdit(); 20 Hover changes then C.step(st): one 'accent' pass; close: the whole pass, edit off
	-- the picker opened elsewhere ends only its own edit
end)
test('search finds Hover, Lightness step and the rest on the Accent row', ...)
test('the reset walk covers the menu (R.check_page on Global settings)', ...)
test('under Blizzard the slot is white under the mouse and the menu draws on the panel art', ...)
test('whole pixels: the row and the menu under Thick, Thin and Blizzard', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/accent_menu_test.lua`. Expected: FAIL, the Accent row has no dots.
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Media/states.lua SaftUI-Core/Media/colors.lua SaftUI-Core/Config/optionstypes.lua SaftUI-Core/Config/optionsmodel.lua SaftUI-Core/Config/optionsmenu.lua SaftUI-Core/Config/optionspreview.lua tests/lib/reset_walk.lua tests/lib/options_walk.lua tests/core/accent_menu_test.lua tests/core/options_menu_test.lua tests/core/options_desc_test.lua tests/core/theme_tab_test.lua .agents/edit-mode.md .agents/architecture.md
git commit -m "options: the accent's dots open how its states are made, live as you drag, each setting with its reset"
```

**In-game checks:** G4, G5, G6.

---

### Task 11: Retire the Buttons states and the tints; the scan; the docs

**Files:**
- Modify:
  - `SaftUI-Core/Config/defaults.lua`: `st.defaults.colors.button` holds only `danger`.
  - `SaftUI-Core/constants.lua`: `st.HOVER_TINT`, `st.TINT_ROW`, `st.TINT_OBJECT` and their comment go.
  - `tests/core/color_reads_test.lua`: `RETIRED.button` gains `'normal'`, `'hover'`, `'pushed'`, `'checked'`; rule E's names gain `HOVER_TINT`, `TINT_ROW`, `TINT_OBJECT`, `HOVER_ALPHA`, `PUSHED_ALPHA`, `HoverEdge`.
  - `tests/core/hover_readers_test.lua`: removed (`git rm`): its two rules (Buttons > Normal read only by the thumb, `st.HOVER_TINT` at 0.4) end with the keys and the constant, and S4 below holds the rest.
  - The docs and the design system (the spec's section 7, every file named there), `docs/followups.md` (the two entries; the ToC), and the in-game checklist below written to its own file.
- Create:
  - `tests/core/states_scan_test.lua`: over `T.saftui_files()` (comments and strings blanked with `lib/source_lex.lua`), outside `SaftUI-Core/Media/states.lua` and `SaftUI-Core/Widgets/states.lua`:
    - **S1** no `ColorRGBA('accent'` with a third argument, but `OB.OWN_STRENGTH` (a mark at full);
    - **S2** no `SetHighlightTexture(`, `SetPushedTexture(` or `SetCheckedTexture(` but at the sites of `ALLOWED`, a table of file to count with a reason each, of two kinds only: a Blizzard art branch that hands the helper's own texture back with Blizzard's blend (`st:SkinActionButton`'s under the Blizzard look, `skinning.lua`), and a glyph's own state textures the game shows (`st:EnableResizing`'s corner, `skinning.lua`; the options window's grip, `optionsresize.lua`). The counts are the ones found after Tasks 2 to 8, written in with their lines' reasons; a new call fails until it is listed;
    - **S3** no `SetBlendMode('ADD')` on a texture of a file in `STATE_FILES` (the files Tasks 2 to 8 converted);
    - **S4** no read of a retired Buttons key (rule A, above) and no `'button', 'hover'`-style literal pair for the four keys;
    - **S5** every `st:AddStates(` names a shape of the list.
  - `docs/superpowers/plans/2026-11-15-saftui-interaction-states-in-game-checklist.md`: the checklist below, for the owner.
- Docs: `.agents/architecture.md`, `.agents/edit-mode.md`, `.agents/taint.md`, `.agents/testing.md` (the scan), `AGENTS.md`; `docs/design-system/README.md`, `05-decisions.md` (decision 55), `25-colour-roles.md`, `tokens.json`, `10-discrepancies.md`, `30-code-changes.md`, and the components' `README.md` and `preview.html` the spec lists (`Button`, `Toggle`, `Input`, `Select`, `ColorBar`, `Range`, `Row`, `MenuItem`, `CheckList`, `OptionsWindow`, `ActionButton`, `BagSlot`, `Mover`, `ResetIcon`, `Icons`, `PositionBlock`, `Dialog`, `CloseButton`). The report says the design system changed: the controller republishes the Design System artifact.

**Interfaces:**
- Consumes: every earlier task.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/states_scan_test.lua
test('S1: no file reads the accent at a strength for a state', ...)
test('S2: state textures are set only by the helpers and the listed Blizzard art branches', ...)
test("S3: no ADD blend on a converted file's textures", ...)
test('S4: no Buttons > Normal, Hover, Pushed or Checked read anywhere', ...)
test('S5: every AddStates names a known shape', ...)
test('the scan catches each: a fixture line per rule fails it (as color_reads_test does)', ...)
-- tests/core/colors_test.lua
test("st.defaults.colors.button has only danger; st:Color('button', 'hover') errors at the caller", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/states_scan_test.lua tests/core/color_reads_test.lua`. Expected: FAIL until the defaults and constants go (and any reader a task missed is found: fix it here, and say so).
- [ ] **Step 3: Implement** as listed under Files.
- [ ] **Step 4: Run** `tests/run -j2`, then `tests/run --scales=all`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files; run `agents-doc-parity-check` and `readme-freshness-check`.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/defaults.lua SaftUI-Core/constants.lua tests/core/color_reads_test.lua tests/core/states_scan_test.lua tests/core/colors_test.lua docs/superpowers/plans/2026-11-15-saftui-interaction-states-in-game-checklist.md docs/followups.md .agents/architecture.md .agents/edit-mode.md .agents/taint.md .agents/testing.md AGENTS.md docs/design-system/README.md docs/design-system/05-decisions.md docs/design-system/25-colour-roles.md docs/design-system/tokens.json docs/design-system/10-discrepancies.md docs/design-system/30-code-changes.md
for c in Button Toggle Input Select ColorBar Range Row MenuItem CheckList OptionsWindow ActionButton BagSlot Mover ResetIcon Icons PositionBlock Dialog CloseButton; do
	git add "docs/design-system/components/$c/README.md" "docs/design-system/components/$c/preview.html"
done
git rm tests/core/hover_readers_test.lua
git commit -m "colors: Buttons keeps only Danger, the tints retire, and a scan keeps every state on the helpers"
```

(Each component's `README.md` and `preview.html` is staged by its own path; skip one the task left untouched.)

**In-game checks:** the whole checklist below.

---

## In-game checklist (the whole plan)

Do it on both clients (WoW Forever, interface 16001, and retail, interface 120000), at SaftUI's defaults unless an item says otherwise, under Thick, then Thin, then Blizzard where it says. Nothing here needs a character, realm or account name.

1. **G1.** `/sui`: a button, a field, a select, a color field and a check box under the mouse tint their body and keep a grey edge; a pressed button tints darker; Reload UI works.
2. **G2.** The sidebar: a page tints under the mouse; the current one has a two-line bar and a fill fading across it. Tabs: a tint under the mouse; the current tab's fill over its underline.
3. **G3.** A dropdown open: rows tint; the picked one has the bar and the fade, its text white.
4. **G4.** Theme > Accent's dots: the menu opens with its preview; change and reset each setting; Tones and Hue shift dim by mode; drag Hover, Selected fill, Selected fade and Disabled: the preview and the page behind follow as you drag.
5. **G5.** Pick #8a5cf5, then #e6c84a: every state follows, text on fills stays readable; Hover at 60% with the yellow: the preview's Hover tile's text turns dark.
6. **G6.** Hue-shifted tones with the yellow: pushed is orange (#e99f00), hover a paler yellow; with the blue, hover turns cyan and pushed toward violet. Say if it reads wrong.
7. **G7.** Bags: view buttons, item slots (a faint tint, darker when clicked), the Categories list, the Edit toggle, the category filter box, the search box's focus.
8. **G8.** Action bars: hover, press, auto attack on (an edge and the fade), an equipped trinket's edge, keybind mode's highlight; pet and stance bars. Under Blizzard: Blizzard's art.
9. **G9.** Micro menu: hover; the character window open: its micro button shows the edge and the fade, gone when it closes; the tracking, queue and expansion buttons.
10. **G10.** Edit mode: a mover tints under the mouse; a selected one has the edge and the fade; History rows.
11. **G11.** `/sui debug` on, in a raid or a busy city with every bag and the bank open: drag the Accent in the picker a few seconds and press Okay; drag Hover in the dots menu and close it. Each line's slowest pass is under 2 ms; say if not, with the line.
12. **G12.** `/console taintLog 1`; in combat use action, pet and stance buttons, toggle auto attack, open and close windows from the micro menu, use a totem: no `ADDON_ACTION_BLOCKED`, nothing in `taint.log` naming SaftUI's states.
13. **G13.** A profile whose Buttons > Hover was changed: after the update the Colors page shows only Danger and nothing errors.
14. **G14.** A loot roll, chosen: the edge and fade on its icon, the others at 40%; the loot window's rows tint.
15. **G15.** SaftUI's tracker: rows and quest items under the mouse, the chevrons; any scroll bar's thumb.
16. **G16.** Under Blizzard, `/sui`, bags, bars and edit mode wear Blizzard's states and no SaftUI tint shows over them.

---

## Spec coverage check

| Spec section, decision or call | Task |
| --- | --- |
| Why; decided 1 (one Accent), 2 (the rules), 3 (three modes), 4 (Tones and its numbers), 5 (the dots menu) | 1 (the engine), 2 to 8 (the rules on every widget), 10 (the menu) |
| Goals: every state by rule; one look per shape; live within budget; Buttons trimmed; docs | 1; 2 to 8; 1 and each cost case, 10; 9, 11; 11 |
| Non-goals: markers, Blizzard's art, LibActionButton's unusable look, other Theme colors, retuning | each area's "unchanged" cases; Global Constraints (Libraries) |
| Anti-goals: no hand-drawn state; no unnamed visible change; no taint; no slower drag; readable text | 11 (scan); Global Constraints (rest unchanged); Review Focus 2, 6's combat case; each cost case; 1 and 3 (text pick, layers) |
| 1. The states, precedence, pieces, the shape table | 1 (helpers), 2 to 8 (each shape on its widgets) |
| 1. Text on a fill; meanings that keep their colors; under Blizzard | 1, 3; each area's cases; each area's Blizzard case |
| 2. Settings, ranges, defaults; formulas; modes; gamut; solids; text pick; extremes; vectors | 1 |
| 3. `Media/states.lua`, the cache, `ST.Changed`, what a pass may call | 1 (Rulings 2, 3, 9) |
| 3. `Widgets/states.lua`, the paint rules, Core's skinners, the kit, another addon's widget | 1 (Rulings 5 to 8, 12), 2, 3, 5 and 7 (Ruling 6) |
| 4. The mapping A1 | 3 |
| 4. A2 | 2 |
| 4. A3 | 4 |
| 4. A4, A6, the totems of A8 | 6 |
| 4. A5 | 5 |
| 4. A7 | 7 |
| 4. A8 (skins), A9 | 8 |
| 4. A10 (nothing), B (stays), the inconsistencies, visible changes | each area's "unchanged" cases; 11 (scan, decision 55) |
| 5. Removed; Danger; storage; migration step 7 | 11; 9; 1; 1 |
| 5. The Colors page and the Theme tab after; the `states` and `danger` previews | 9, 10 |
| 6. The row, the menu, by mode, resets, live, the menu's edit, the cost of a drag | 10 (Ruling 18), each cost case |
| 7. Docs and the design system | each task (`.agents`), 11 (the rest) |
| 8. Risks | Review Focus 1 to 5 |
| 9. In-game checks G1 to G16 | the checklist above; per task |
| Calls 1 to 24 (task: calls) | 1: 1, 2, 3, 4, 15, 16, 17, 18, 20; 2: 5, 8, 24; 3: 10; 4: 9; 5: 14; 6: 6, 7, 11, 12; 7: 13; 8: 10, 14; 9: 19, 21; 10: 22; every task's cost case: 23 |

**Where the spec is silent or the code disagrees** (each is a Ruling above):
- **The code disagrees:** `st:SkinButton`'s hover is a game highlight over the label (Ruling 5 moves it under); the bags' and the feed's buttons are skinned by Core but their states are set by the module, which parallel tasks can't share (Ruling 6); the kit's lines are 1 unit while the scaling work moves lines to `st:GetLineSize` (Global Constraints: the bars use the token); `color_cost.lua` forbids nothing for `SetTexCoord` and `SetAlpha` but counts neither (Ruling 9); the reset walk only enters an item's menu (Task 10 widens it).
- **Tests that pin what this work changes:** the hover and Buttons readers' tests (`hover_readers_test.lua` retired in Task 2, `button_opacity_test.lua` trimmed), the kit's edge-on-hover assertions (3), the movers' 15% fill (4), the bags' accent pins and view buttons (5), the action bars' white 15% (6), the roll bars' 35% (7), the tracker's 25% rows (8), the previews' `button` and `accent` kinds (9).
- **The spec leaves open:** Rulings 1 to 20.
</content>
</invoke>
<invoke name="Bash">
<parameter name="command">cd /tmp/claude-1000/-mnt-c-Github-wow-addons-SaftUI-Modular/f9fdefff-45d5-4c08-9fb0-3c0ba643bed7/scratchpad/states && cat > check.py <<'EOF'
# Recompute every vector cited in the spec once more, through the mockup-faithful 0..255 implementation (vectors.py style),
# and compare with the 0..1 implementation (lib.py).
import math, re
from lib import *
import importlib.util
spec=importlib.util.spec_from_file_location('m','vectors.py')
EOF
python3 - <<'EOF'
import math,sys
sys.path.insert(0,'.')
exec(open('vectors.py').read().split('import sys')[0])  # mockup-faithful functions (0..255)
import lib
presets=['#00adf0','#8a5cf5','#e6c84a']
bad=0
for p in presets:
    for mode in ('tones','hue'):
        for d in ('warm','cool'):
            for k in (-3,-2,-1,1,2,3):
                a=toneAt(p,k,mode,dir=d)['hex']
                b=lib.hx(lib.tone(*lib.h2f(p),k,dict(lib.DEF,mode=mode,direction=d)))
                if a!=b: bad+=1; print('DIFF',p,mode,d,k,a,b)
print('tone mismatches:',bad)
# spec text values to verify
spec=open('/mnt/c/Github/wow-addons/SaftUI-Modular/docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md').read()
checks={
 ('#00adf0','tones',-3):'#006189',('#00adf0','tones',-2):'#007aaa',('#00adf0','tones',-1):'#0093cd',('#00adf0','tones',1):'#5cc6ff',('#00adf0','tones',2):'#a1dcff',('#00adf0','tones',3):'#dbf1ff',
 ('#8a5cf5','tones',-3):'#49009c',('#8a5cf5','tones',-1):'#7441d9',('#8a5cf5','tones',1):'#9f7fff',('#8a5cf5','tones',3):'#cdc2ff',
 ('#e6c84a','tones',-1):'#ccae28',('#e6c84a','tones',1):'#ffe370',('#e6c84a','tones',2):'#fffef9',
 ('#00adf0','hue',-3):'#4c3fc2',('#00adf0','hue',-1):'#3888e9',('#00adf0','hue',1):'#1ccef0',('#00adf0','hue',3):'#b5ffea',
 ('#8a5cf5','hue',-1):'#5a44ed',('#8a5cf5','hue',1):'#c26eef',('#e6c84a','hue',-1):'#e99f00',('#e6c84a','hue',1):'#f7e579',('#e6c84a','hue',-3):'#d7461d',
}
for (p,m,k),want in checks.items():
    got=toneAt(p,k,m)['hex']
    print('OK ' if got==want else 'BAD',p,m,k,got,want)
EOF