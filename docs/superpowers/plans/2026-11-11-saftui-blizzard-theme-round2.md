# Blizzard Theme, Round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Under the Blizzard theme, `/sui` becomes Blizzard's Settings window (metal, title bar, inner frame, banners, Settings controls, steppers where the choices fit, minimal scroll bars), unit frames wear Blizzard's unit frame box and raid group border with Blizzard's bar fills, and the micro menu bar stands on Blizzard's micro menu and minimap art. In every theme, `/sui` grows taller by its bottom edge, and the Categories editor keeps Caught now and Pinned items in a fixed footer. Nothing else changes under Thick or Thin.

**Architecture:**
- **Part A, `/sui`** (Tasks 1 to 11). The window keeps one code path with two layouts, `OW.LAYOUT.own` (today's numbers, Thick and Thin) and `OW.LAYOUT.blizzard`, chosen on every render by `W.BlizzardLook()` and applied only when the look changed. The new art is tables in `SaftUI-Core/themeart.lua`, read through `st.ThemeArt.Control(name)`. The controls stay `optionswidgets.lua`'s, each drawn inside its own rect apart from the dropdown face's glow. A Blizzard scroll bar is a companion of today's 3px bar, so every call site and Thick test keeps working. Task 10 lets the window grow taller in every look: SaftUI's own drag on a bottom edge and a corner grip, the height an even number from the layout's height up to the screen's, saved in SaftUI's global settings. Task 11 splits the Categories editor into its scrolling rows and a fixed footer, a second options body in the same tab.
- **Part B, unit frames** (Tasks 12 to 15). Two new kinds: `unitframe` (the bronze box cut from Blizzard's player and target art) and `member` (a party or raid member: the Background fill, no art). Under Thick and Thin both draw exactly as `bar`. The group border is a frame of SaftUI's, a child of each group header, anchored to it. Blizzard's bar fills go on through `UF:UpdateStatusBarElement`.
- **Part C, the micro menu bar** (Tasks 16 and 17). No new kind: the bar items' panels draw as `control` (a small frame under Thick and Thin, as today; clear under Blizzard, as the micro buttons' own panels are), and the micro menu draws its art itself from `st.ThemeArt.Control('microbar')`: one texture per atlas, sliced by the engine from the atlas's own slice data, or retail's minimap button kit laid by `ThemeArt.LayBorder`. The bronze strip behind the micro buttons is a frame of SaftUI's anchored to the first and last shown holder. An atlas one client lacks is marked for the client that has it (`Atlas(name, 'forever')`), and the atlas test checks each on its own clients.
- Parts B and C share only `themeart.lua`, `tests/wow/atlases.lua`, `tests/core/theme_blizzard_test.lua`, `tests/core/theme_blizzard_draw_test.lua` and the `tests/wow/` stubs with Part A and with each other, in separate entries. Each can run after Part A, or beside it in its own worktree, without needing anything another part makes.

**Tech Stack:** Lua 5.1 (WoW Forever 16001 and retail 120000), oUF, SaftUI's own options window (no AceGUI), tests on lupa's Lua 5.1 through `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-11-saftui-blizzard-theme-round2-design.md`. Read it first. Its "My call"s, "The user's answers" and "The builder check's answers" are binding. Commits 3e2f594 and 8cc0287 revised it after this plan's first version: goals 2, 3 and 5, and the user's answers 5 to 8. The research behind it (atlas names, sizes, Blizzard's layouts) is summarised in the spec's "Blizzard's art" and goal 5's. This plan adds the numbers the spec leaves to the builder (below).

**Starting point:** `modular` at `8cc0287`. Its code is `28c0448`: `e5b12f3` ("Merge the Categories tab fixes…", the four fixes the spec's "Today" assumes, plus their review fixes: `a6f1a32`, headers and footers wait out combat, `st:ArtAboveHeader`, `st.ThemeArt.MetalAbove`, and stub widgets a test marks protected, whose moves in combat are blocked and noted in `stub.blocked`; `4596ad5`, the Categories tab's reveal and edge band), with `st:SkinIcon`'s crop hook keeping its state in weak tables of `skinning.lua`'s (`iconCrops`, `hookedIcons`), not on the icon. Nothing in this plan reads that state. `tests/run` passes there (78 files).

## Global Constraints

- **Clients:** Forever (16001) and retail (120000). Read per-client values at call time through `st.ThemeArt` (`ThemeArt.Client()`), never at file load. Tests switch clients with `T.client(name)`, or for `/sui` with the `world(client)` helper Task 2 defines. An atlas only one client has is named only in that client's art (Task 16).
- **`.agents/taint.md`:**
  - every new piece of art is a texture of a frame of SaftUI's, kept in a weak table or on SaftUI's own frame;
  - nothing is written onto a frame that isn't SaftUI's (the group headers' new border is kept in a side table; the micro menu's art is kept in its items' entries, never on Blizzard's bar items);
  - no `NineSliceUtil`, no Blizzard setter, no protected call to draw, size or move a unit frame's border (tests mark a secure frame protected with an `IsProtected` of its own, set with `rawset` on a locked frame, and check `stub.blocked` stays empty);
  - Blizzard's micro menu art (`MicroMenu.BorderArt`, `BackgroundArt`) stays hidden and unmoved: the strip is SaftUI's own;
  - no math on a frame level that `issecretvalue` says is secret;
  - the hover stays in the HIGHLIGHT layer (`st.ThemeArt.HOVER_LAYER`).
- **Thick and Thin draw exactly as today**, but for the two changes the spec makes in every theme: `/sui` grows taller (Task 10) and the Categories editor's footer (Task 11). Task 1 pins `/sui`'s frames at absolute positions, and every existing Thick or Thin assertion keeps passing unchanged. The only existing assertions this plan changes are Blizzard ones, the Categories editor's height (Task 11), and the kind names drawn (`'bar'` → `'unitframe'`/`'member'` in `SaftUI-Unitframes`, `'panel'` → `'window'` for `/sui`'s window, `'small'` → `'control'` for the micro menu bar's items), which change nothing visible under Thick and Thin. Each task names the ones it changes.
- **Whole pixels** (`.agents/edit-mode.md`): every frame and texture starts and ends on a whole pixel under every look. A frame anchored by its centre has even sides: `/sui`'s window is 1040 or 1110 wide and an even height, at least 700 or 728 (Task 10).
- **No row height or cell rect changes under Blizzard** (`body:CellRect`, `W.WIDTH`, every widget's frame size). Art may spill outside a control only where a task says so (the dropdown's glow), and then never into a neighbouring control or past a scroll frame's clip.
- **Fonts:** no font changes. Only the text colors the spec names change: gold `{ 1, 0.82, 0 }` (Blizzard's `NORMAL_FONT_COLOR`) and white `{ 1, 1, 1 }`.
- **Words the user sees:** the title bar reads `SaftUI Options`. No atlas or file name is shown anywhere.
- **Saved profiles keep working:** no new profile key, no migration. One new optional field in SaftUI's global settings, `optionsWindow.height` (Task 10); a saved table without it, or with anything but a number there, reads as no height.
- **The bronze box and group border cut atlases by texture coordinates**, from `C_Texture.GetAtlasInfo`'s file and coordinates, never from a size read back from a frame. The micro menu bar's art is set whole (`SetAtlas`), the engine slicing it by the atlas's own slice data.
- **Files:** keep each file's line endings (all files touched here are LF today; check with `file` before editing). Never `sed -i` a CRLF file. Stage by explicit path. Never `git stash`.
- **`tests/run` passes at the end of every task.**
- **Commits:** `<area>[, <area>]: <plain sentence>`, a body saying what and why, ending with exactly:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsM3V6p9vWPEFz7WA9o
  ```

### Starting values (the spec leaves these to the builder; tuned in game later)

All in UI units (pixels at SaftUI's scale). "Window" coordinates are from `/sui`'s top-left, y down.

| What | Value | Derived from | Task |
| ---- | ----- | ------------ | ---- |
| `/sui` under Blizzard | 1110 × 728 | 17 + 1076 + 17 wide; 28 + 654 + 46 tall; both even (centred) | 2 |
| Inner frame | at 17, 28; 1076 × 654 | Settings' inner frame sits 17 in from the metal's sides; its tabs' top is 27 below the frame's top, +1 for an even height; 654 keeps the body today's 539 tall | 2 |
| Sidebar | 242 wide, from x 17 | `floor(199 × 1076 / 886 + 0.5)`: its right edge on the divider drawn at 199 of 886 | 2 |
| Main column | 834 wide: `PAD` 28, the body 774, right pad 32 | 32 = the dropdown glow 7, the scroll bar's gap 12 and its 17-wide arrows less 4 (ends 25 past the content), then 2 for the inner frame's rim and 5 clear | 2 |
| Body | bottom 4 above the inner frame's bottom; its scroll frame reaches 7 past the 774 content | the inner frame's 2px rim and 2 clear; the dropdown's 7px glow | 2 |
| A fill page's reach | 25 past the content (13 today) | the Blizzard bar's arrows end there | 2 |
| Footer | 46 tall under the inner frame; Reload UI and Close 16 from the window's bottom and sides | `SettingsPanel`'s Close button, BOTTOMRIGHT −16, 16 | 2 |
| Title text | centred 10 above the title bar's bottom | the 20-tall title strip (`ThemeArt.TitleStrip()`), its bottom on the title bar's | 2 |
| Nav rows | 226 wide | the 242 sidebar less 16: the nav's narrow scroll bar 4 from the rows and 4 from the divider | 2 |
| Group headers | 30 tall; banner TOPLEFT at its 199 × 144; label LEFT 20, −1, white | `SettingsCategoryListHeaderTemplate` | 3 |
| Search glass | 10 × 10 at LEFT 6, −1 | `SearchBoxTemplate`'s LEFT 1, −1 is from its edit box, whose border starts 5 outside it; SaftUI's border starts at the box's edge | 3 |
| Check box art | toggle 30 × 29, its right on the box's right, 5 above its top; a multiselect's or check list's row 23 × 22, its left on the box's left, 2 above | the largest whole size up to 30 × 29, in proportion, within the row (34 and 22 tall); the 18 box stays | 4 |
| Dropdown face | glow (outset) 7 on an option row's select, 4 on a compact one; text insets 13, centred; pressed text (2, −1); hover arrow 12 × 5 hanging under the face | `WowStyle2DropdownTemplate`; compact dropdowns have 4 between them and the next control (the rule editor's 22-tall fields in 26-tall rows; the position block's dropdown and name box) | 5 |
| Dropdown list | `common-dropdown-c-bg` from (−17, 12) to (17, −22) around the list; rows inset 3, 6, 3, 7 | `MenuStyle2Mixin` | 5 |
| Steppers | each 26 × 24, back at the select's left, next at its right; the face from 31 to 140 (109 wide); icon 17 × 17 at (4, −3); only on a select whose longest choice fits `W.StepperRoom()`, 83 (109 less two insets of 13) | `DropdownWithSteppersTemplate`: back 5 left of the dropdown, next 4 right of it; the user's answer 5 | 6 |
| Slider arrows | back 11 × 19 at (0, −2); the slider 88 wide from 15; forward 9 × 18 at (107, −3) | `MinimalSliderWithSteppersTemplate`: arrows 4 from the track, inside the slider's 116 | 7 |
| Scroll bar | track 8 wide, `OB.BLIZZARD_GAP` 12 right of the content (callers' own gaps kept); wide: arrows 17 × 11 starting 4 left of the track, track inset 19; narrow: arrows 8 × 5, inset 9; thumb at least 23 | `MinimalScrollBar` | 8 |
| `/sui`'s height | even, from the layout's `height` (700, 728) to `OW.MaxHeight()`; a drag also stops where the bottom meets the screen edge margin | the spec's goal 2 | 10 |
| Resize grip and edge | grip 16 × 16 at the window's BOTTOMRIGHT; the edge 6 tall along the bottom, left of the grip; both 10 levels over the window | `PanelResizeButtonTemplate`'s 16 | 10 |
| Categories footer | its top edge 1 tall; as tall as its body's drawn height plus that edge, at most half the tab's height (floor) | the spec's goal 3 | 11 |
| Bronze box | inset 2; 8 × 8 pieces; rectangles per client (Task 12's table) | the decoded art: each piece's outer 2px is the dark outline and the bronze (or grey) rim | 12 |
| Group border | `options_frame_child` cut at 6px; (−2, 2) and (2, −3) around the header | `CompactRaidGroup_UpdateBorder` | 14 |
| Micro menu strip (Forever) | 4 outside the first and last shown micro holder (33 tall on the 25 row); its background 2 inside it | the spec's "about 4 outside them"; Blizzard's background overhangs its frame by 13, which here would reach the box beside it | 17 |
| Micro menu boxes | Forever: the header art 23 tall from 1 below the box's top, the box's width; a square 23 × 22 and the tracking button 23 × 23 at TOPLEFT (1, −1). Retail: the kit on the box's rect | the spec's "drawn at its own height, centred"; centred on whole pixels in the 25 row | 17 |

## Review Focus

1. **A theme or profile switch with `/sui` open: scrolled down, on a fill page (Categories), or at a height the user dragged it to.** The page, the scroll, the fill row's height and the dragged height survive (a height under the new look's least takes the least), and the window re-lays out with no reload (Task 2 test `'a switch with /sui scrolled or on a fill page'`, Task 10 test `'under Blizzard /sui grows taller from 728…'`).
2. **A saved `/sui` height the screen no longer fits (a smaller resolution, a larger UI scale), one under the look's least, or one that isn't a number.** `/sui` opens at a height from the look's least to the screen's most, and never runs past the screen edge margin where the screen has room (Task 10 test `'a saved height the screen no longer fits, or under the least'`).
3. **A select with no current choice among its values, one value, disabled, or whose choices grow longer between renders.** The steppers mustn't wrap, error or pick past the ends: no choice means back disabled and next picks the first; one value means both disabled; a disabled select means both disabled; and they come and go with the fit at each render (Task 6 test `'stepper edge cases'`).
4. **A unit frame whose health doesn't quite fill it** (resized, offset, anchored to another element), with the frame's own Theme on under Blizzard. Both boxes show; only an exact fill hides health's (Task 13 test `'one box per edge'`).
5. **Blizzard showing and hiding micro buttons and bar items under Blizzard** (a button the game hides at a level or in a region, mail and the queue eye coming and going, in combat). The strip follows the shown run and goes when none shows, an item's art goes with the item, and nothing of Blizzard's is shown, moved or written onto (Task 17 test `'the micro buttons stand on one bronze strip…'`).

## Order and parallelism

- **Part A, in order:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9, then 10 and 11 in either order. Each of 1 to 9 touches `optionswidgets.lua` or `optionswindow.lua`, and 6 builds on 5's face. Task 10 (`optionswindow.lua`) needs 2's layouts and 8's bars; Task 11 (`categoriestab.lua`) needs 3's divider, 8's bars and 9's list. 10 and 11 touch different files, so in one worktree they run one after the other, and either may go first.
- **Part B, in order:** 12 → 13 → 14 → 15, after Part A, or in parallel with it in its own worktree.
- **Part C, in order:** 16 → 17, after Parts A and B, or in parallel with them in its own worktree. It needs nothing they make.
- **Shared files across parts:** `themeart.lua` (ART and CONTROLS entries; Part C also `LayBorder` and the atlas marking, Part B `Paint`), `tests/wow/atlases.lua` (entries; Task 5 removes WowStyle1's, Task 12 adds the file and coordinates format), `tests/wow/widgets.lua`, `tests/core/theme_blizzard_test.lua` (Task 12's kind insets, Task 16's atlas test) and `tests/core/theme_blizzard_draw_test.lua` (Task 12's and Task 16's new cases). Keep both sides on a merge, then run `tests/run`: the atlas test then checks every part's atlases.
- **Task 18 (docs) last**, after all three parts, so `.agents/` never conflicts.

## Files

| File | Tasks | What changes |
| ---- | ----- | ------------ |
| `SaftUI-Core/Config/optionswindow.lua` | 1–3, 5, 6, 8, 10 | the two layouts; the title bar; the inner frame; the sidebar's dressing; the bars' owners; growing taller |
| `SaftUI-Core/Config/optionsbody.lua` | 3, 8 | no section rules under Blizzard; the scroll bar's companion |
| `SaftUI-Core/Config/optionswidgets.lua` | 3–8 | the glass; check box size; the dropdown face, list, steppers where the choices fit; slider arrows; the Blizzard scroll bar |
| `SaftUI-Core/themeart.lua` | 2, 3, 5–8, 10, 12, 14–16 | new art tables, the cut layout, the two kinds, the resize grip, the micro bar's art, atlases one client has, `ThemeArt.LayBorder` |
| `SaftUI-Core/theme.lua` | 12 | `THEME_KINDS` gains `unitframe` and `member` |
| `SaftUI-Bags/ruleeditor.lua` | 5 | its fields take the dropdown face |
| `SaftUI-Bags/categoriestab.lua` | 8, 9, 11 | its bars' owners; the list in the nav rows' look; the editor's fixed footer |
| `SaftUI-Unitframes/unitframes.lua`, `updaters.lua`, `groups.lua` | 13–15 | kinds, one box per edge, the group border, fills |
| `SaftUI-Minimap/micromenu.lua`, `microbuttons.lua`, `zonetextbutton.lua`, `clockbutton.lua`, `stats.lua` | 17 | the items' art, the strip |
| `tests/wow/atlases.lua`, `tests/wow/blizzard.lua`, `tests/wow/widgets.lua` | 2–8, 12, 14–16 | new atlases (Forever's only ones in Forever's table alone); atlas files and coordinates; hit rects; a bar texture's atlas |
| `tests/core/theme_blizzard_test.lua`, `tests/core/theme_blizzard_draw_test.lua` | 12, 16 | the kinds' insets; atlases one client has; the cut and `ThemeArt.LayBorder` |
| `tests/core/options_window_test.lua`, `tests/core/options_widgets_test.lua` | 1–8, 10 | Thick pins; Blizzard controls; growing taller |
| `tests/core/options_settings_test.lua` (new) | 2, 3, 6, 8, 10 | `/sui` under Blizzard on both clients |
| `tests/bags/categories_tab_test.lua`, `tests/bags/rule_editor_test.lua` | 5, 8, 9, 11 | the rule editor's faces; the bars; the list's look; the footer |
| `tests/unitframes/blizzard_look_test.lua` (new) | 13–15 | unit frames under Blizzard on both clients |
| `tests/minimap/blizzard_look_test.lua` (new), `tests/minimap/theme_test.lua` | 17 | the micro menu bar under Blizzard on both clients |

---

## Part A: `/sui` as the Settings window

### Task 1: Pin today's `/sui` under Thick and Thin

Today's tests compare Thick with Thin and with Thick after a Blizzard round trip, so a change that moved both the same way would pass. This task pins absolute positions before anything moves. Already pinned elsewhere, and kept as they are:
- `tests/core/options_window_test.lua`: the cells' quarters (`'quarter cells are whole pixels…'`: 0, 196, 407; 171 wide), the dividers at 387 and 183, a toggle's and a color's place in their cell, a small input's 60, the position cell, every cell on whole pixels, the footer region between Reload UI and Close, a fill row's body edge and bar (774 + 10), the nav entry's 207 × 26 (inside the Blizzard sidebar test), the search box's 190 × 24 and hint at 8, and `'under Thick and Thin /sui is unchanged'` (every cell and widget the same under Thick, Thin and Thick again);
- `tests/core/options_widgets_test.lua`: every widget's size (`W.WIDTH`, the range's 168, 116 and 46, the select's 170 × 24, the caret's pixels, the position block's parts 12 apart);
- `tests/bags/categories_tab_test.lua`: the list's 210 and its bar 3 wide, 4 right of it; the editor's 540 at 234 and its bar at 774 + 10.

**Files:**
- Test: `tests/core/options_window_test.lua` (a new case before the "under the Blizzard theme" section).

**Interfaces:** none (reads `OW.GetFrames()` as it is today).

- [ ] **Step 1: Write the test** `"/sui's frames where they sit today, under Thick and Thin"`. The values are today's as read from the code. If one comes out different, today's code is the truth: record what it gives and say so in the report.
  ```lua
  -- Where a frame sits in the window: x and y from its top left, and its size.
  local function at(f)
  	local w = frames().window
  	return ('%d,%d %dx%d'):format(f:GetLeft() - w:GetLeft(), w:GetTop() - f:GetTop(), f:GetWidth(), f:GetHeight())
  end
  -- The textures a frame shows, as 'r,g,b,a x,y WxH', sorted.
  local function fills(frame) --[[ each shown texture's color texture and at() ]] end

  for _, name in ipairs({ 'thick', 'thin' }) do
  	st.config.profile.theme.name = name
  	st:RedrawThemed() -- the window drawn once already takes the theme, as a switch does
  	st.Config:Open('Loot') -- one tab: no tab row
  	local F = frames()
  	local side = F.navFrame:GetParent()
  	local brand = select(2, F.actionsFrame:GetPoint(1))
  	eq(at(F.window), '0,0 1040x700', name)
  	eq(F.window.backdropInfo.insets.left, name == 'thick' and 2 or 1, name .. ': the border')
  	eq(at(side), '2,2 208x696', name)
  	eq(at(brand), '2,2 207x73', name)
  	eq(at(F.actionsFrame), '2,75 207x44', name)
  	eq(at(F.navFrame), '2,120 207x547', name)
  	eq(at(F.profile:GetParent()), '2,668 207x30', name)
  	eq(at(F.main), '210,2 828x696', name)
  	eq(at(F.title):match('^%d+,%d+'), '238,22', name)
  	eq(at(F.close), '1000,14 24x24', name)
  	eq(at(F.search), '822,83 190x24', name)
  	eq(at(F.tabLine), '210,113 828x1', name)
  	eq(at(F.body), '238,113 774x539', name)
  	eq(at(F.reloadButton:GetParent()), '210,652 828x46', name)
  	eq(fills(side), '0.09,0.09,0.09,1.00 2,2 208x696\n0.18,0.18,0.18,1.00 209,2 1x696', name .. ': the fill and edge')
  	-- every nav entry 207x26, every group header 207x29 with its text at 18, -12
  	st.Config:Close()
  end
  ```
- [ ] **Step 2: Run it.** `tests/run tests/core/options_window_test.lua`: it passes against today's code (it pins, it doesn't drive a change).
- [ ] **Step 3: Commit.** `core, tests: pin /sui's frames under Thick and Thin before the Blizzard layout`

### Task 2: `/sui`'s frame under Blizzard: the metal, the title bar, the inner frame and the wider layout

**Files:**
- Modify: `SaftUI-Core/Config/optionswindow.lua`.
- Modify: `SaftUI-Core/themeart.lua`: `ART.optionswindow` and `CONTROLS.optionswindow`.
- Modify: `tests/wow/atlases.lua`: `Options_InnerFrame` = `{ 886, 618 }` on both clients.
- Create: `tests/core/options_settings_test.lua`.
- Modify, as named in Step 1: `tests/core/options_window_test.lua`, `tests/core/theme_core_frames_test.lua`, `tests/core/theme_blizzard_windows_test.lua`.

**Interfaces:**
- Consumes: `st.ThemeArt.TitleHeight()`, `.TitleStrip()`, `.Close()`; `st:UpdateCloseButton(frame)`; `W.BlizzardLook()`.
- Produces:
  - `st.ThemeArt.Control('optionswindow') -> { inner = 'Options_InnerFrame', width = 886, divider = 199 }`.
  - `OW.LAYOUT.own` and `OW.LAYOUT.blizzard`, plain tables with these fields (own = today's constants):

    | Field | own | blizzard |
    | ----- | --- | -------- |
    | `width`, `height` (`height`: the window's height with none saved, and from Task 10 its least) | 1040, 700 | 1110, 728 |
    | `sideX`, `sideTop`, `sideBottom`, `sideWidth` | 2, 2, 2, 208 | 17, 28, 46, 242 |
    | `navWidth` | 207 | 226 |
    | `mainLeft`, `mainTop`, `mainRight`, `mainBottom` | 210, 2, 2, 2 | 259, 28, 17, 46 |
    | `rightPad` | 26 | 32 |
    | `bodyBottom` (from main's bottom) | 46 | 4 |
    | `bodyReach` (the scroll frame past the content) | 0 | 7 |
    | `fillReach` (a fill page's) | 13 | 25 |
    | `footer` | 46, in main | 46, across the window |
    | `innerX`, `innerTop` | none | 17, 28 |
    | `footerX`, `footerY` (Reload and Close from the window's corners) | none (today's: LEFT 28, RIGHT −26 in the footer) | 16, 16 |

  - `OW.SidebarWidth(innerWidth) -> number`: `floor(divider × innerWidth / width + 0.5)` from `Control('optionswindow')`.
  - New fields of `OW.GetFrames()`: `side`, `brand`, `foot`, `footer`, `titleBar` (the drag strip), `titleText`, `inner` (the inner frame's texture), `layout` (the table in use).

- [ ] **Step 1: Write the failing tests.**
  - In the new `tests/core/options_settings_test.lua`, a fresh world per client:
    ```lua
    local T = load_test_file('lib/theme_helpers.lua')
    local st, OW, drawn
    local function world(client)
    	reset_world()
    	stub.interface = client == 'forever' and 16001 or 120000
    	load_saftui('SaftUI-Core/constants.lua')
    	load_test_file('core/config_helpers.lua')
    	for _, f in ipairs({ 'optionsmodel', 'optionswidgets', 'optionsbody', 'optionswindow' }) do
    		load_saftui('SaftUI-Core/Config/' .. f .. '.lua')
    	end
    	st, OW = SaftUI, SaftUI.OptionsWindow
    	drawn = T.watch()
    	-- modules: a small page in each of Frames, Combat, Info and none (as options_window_test.lua's
    	-- SmallModule); 'Long': three titled sections of ten toggles (it scrolls);
    	-- 'Tabs': two tabs, the first with two subtabs; 'Fill': a fill row (W.Define, fill, minHeight 100)
    end
    local function switch(name) st.config.profile.theme.name = name; st:ThemeChanged(); tick() end
    ```
    with `at(f)` as Task 1's, `tick()` firing `OW.GetFrames().ticker`'s OnUpdate, `anchor(region)` as `'POINT rel RELPOINT x,y'` (rel by name: `window`, `main`, `frame`, `search`, `header`), `rgb(fontString)` its text color as `'r,g,b'` to two places, and `size_of`, `around`, `insets` and `atlases_of` as `options_widgets_test.lua`'s.
  - `'/sui under Blizzard: the metal, its title bar and the close button in the socket'`, for each client:
    ```lua
    switch('blizzard'); st.Config:Open('Loot')
    local F, close = OW.GetFrames(), st.ThemeArt.Close()
    eq(drawn(F.window), 'theme,solid,window', client)
    eq(T.art(F.window), METAL, client .. ': the metal') -- the eight UI-Frame-Metal pieces, as theme_blizzard_windows_test.lua spells them
    eq(at(F.window), '0,0 1110x728', client)
    eq(F.titleText:GetText(), 'SaftUI Options', client)
    eq(F.titleText:GetFontObject(), st:GetFont(st.config.profile.headers.font), client .. ': the header font')
    local cx, cy = F.titleText:GetCenter()
    eq(F.window:GetTop() - cy, st.ThemeArt.TitleHeight() - 10, client .. ': centred on the title strip')
    eq(at(F.titleBar), ('0,0 1110x%d'):format(st.ThemeArt.TitleHeight()), client .. ': the drag strip is the title bar')
    eq(anchor(F.close), ('TOPRIGHT window TOPRIGHT %d,%d'):format(close.x, close.y), client .. ': in the socket')
    eq(F.close:GetWidth(), close.size, client .. ": Blizzard's close button")
    check(not F.brand:IsShown(), client .. ': no brand')
    ```
    and dragging `F.titleBar` (OnDragStart, then OnDragStop) saves `st.config.global.optionsWindow`, as the brand's drag does under Thick.
  - `'/sui under Blizzard: the inner frame, the sidebar on its divider, the footer under it'`, for each client:
    ```lua
    eq(F.inner:GetAtlas(), 'Options_InnerFrame'); check(F.inner:IsShown())
    eq(at(F.inner), '17,28 1076x654')
    eq(at(F.side), '17,28 242x654')
    eq(F.side:GetWidth(), OW.SidebarWidth(1076), 'the sidebar ends on the drawn divider')
    eq(at(F.actionsFrame), '17,28 241x44', 'the actions at the sidebar top')
    eq(at(F.foot), '17,652 241x30', "the profile's name at the sidebar's bottom, inside the inner frame")
    eq(at(F.main), '259,28 834x654')
    eq(at(F.body), '287,139 781x539', 'the body: 28 in, the 774 content plus 7, as tall as under Thick')
    eq(F.content:GetWidth(), 774)
    eq(at(F.footer), '0,682 1110x46')
    eq(at(F.reloadButton):match('^%d+'), '16'); eq(F.window:GetBottom() + 16, F.reloadButton:GetBottom())
    eq(F.window:GetRight() - 16, F.closeButton:GetRight()); eq(F.window:GetBottom() + 16, F.closeButton:GetBottom())
    eq(F.search:GetRight() - F.content:GetLeft(), 774, "the search box's right on the content's")
    for _, item in ipairs(F.nav) do if item.key then eq(item:GetWidth(), 226) end end
    ```
  - `'OW.LAYOUT: Blizzard sizes follow the divider and keep the body'`:
    ```lua
    local b = OW.LAYOUT.blizzard
    eq(b.width, 2 * b.innerX + b.sideWidth + 28 + 774 + b.rightPad)
    eq(b.sideWidth, OW.SidebarWidth(b.width - 2 * b.innerX))
    eq(b.width % 2 + b.height % 2, 0, 'even: the window is anchored by its centre')
    eq(b.height - b.innerTop - b.footer - 111 - b.bodyBottom, 700 - 4 - 46 - 111, 'the body as tall as today')
    ```
  - `'Thick to Blizzard to Thick, and a profile switch, re-lay /sui out'` (Forever): open at Thick, `switch('blizzard')`, `switch('thick')`. Every Task 1 value comes back, and `F.inner`, `F.titleBar` are hidden, `F.brand` shown, `T.art(F.window) == ''`, the close at `TOPRIGHT window TOPRIGHT -16,-14`. Then with `SaftUI_DB.profiles.Blue = { theme = { name = 'blizzard' } }`: `st.config:SetProfile('Blue')`, `tick()` → the Blizzard layout; back to the first profile, `tick()` → Task 1's values.
  - `'a switch with /sui scrolled or on a fill page'` (Review Focus 1): on `Long`, wheel the body down 3 turns; `switch('blizzard')`: the same page, `F.body:GetVerticalScroll()` unchanged, the body still 539 tall; `switch('thick')`: unchanged again. On `Fill`: the fill row's `SetHeight` gets the body's visible height less 12 under each look, and `F.body:GetRight() - F.content:GetRight()` is 25 under Blizzard and 13 under Thick.
  - Changes to existing tests (the spec's new behavior):
    - `tests/core/theme_core_frames_test.lua`, `"the /sui window takes the theme's border and stays solid"`: the window is drawn `'theme,solid,window'` (the dialog stays `'theme,solid,panel'`). Its Thick and Thin edge, alpha and inset assertions stay as they are.
    - `tests/core/theme_blizzard_windows_test.lua`, `"the /sui window's close button keeps its place under Blizzard"` becomes `"the /sui window's close button sits in the metal's socket under Blizzard, and back under Thick"`: `st:DrawnKind(window) == 'window'`; under Blizzard `'TOPRIGHT window TOPRIGHT 0.00,3.00'` and 28 (Forever); under Thick again `'TOPRIGHT window TOPRIGHT -16.00,-14.00'` and its own look.
    - `tests/core/options_window_test.lua`, `"the sidebar's open page sits on Options_List_Active"`: under Blizzard the entry is `'226x26'`.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/core/options_settings_test.lua`: `F.titleText` is nil and the window is 1040 wide.
- [ ] **Step 3: Implement the Blizzard layout in `optionswindow.lua`.**
  - Replace today's layout constants with `OW.LAYOUT.own`'s values (same numbers) and add `OW.LAYOUT.blizzard`. `CONTENT_WIDTH` (774), `PAD` (28), `HEAD_TOP`, `TABS_TOP` and the rest inside main stay single constants: main's insides keep their places relative to main.
  - The window is drawn `st:SetTemplate(window, 'theme', 'solid', 'window')` (a panel under Thick and Thin).
  - `Draw()` reads `blizzard = W.BlizzardLook()`. When it differs from the look last laid out (none at first), `Relayout(layout)` runs. It:
    - sets the window's size;
    - draws the window's template again;
    - runs `st:UpdateCloseButton(F.window)`, then places the close button: own `TOPRIGHT window -16, -14`; Blizzard `TOPRIGHT window (close.x, close.y)`;
    - shows or hides `F.titleBar` (a Frame, `Draggable`, TOPLEFT and TOPRIGHT of the window, `TitleHeight()` tall, under Blizzard only) and `F.titleText` (`'%s Options'` of `st.name`, font `st:GetFont(st.config.profile.headers.font)` set on every relayout, CENTER at the title bar's BOTTOM, 0, `TitleStrip() / 2`);
    - shows the brand (own) or hides it and anchors the actions frame to the side's TOPLEFT and TOPRIGHT (−1, 0) (Blizzard);
    - shows `F.inner` (a texture of the window in ARTWORK, `Options_InnerFrame`, from (innerX, −innerTop) to (−innerX, footer)) only under Blizzard;
    - re-anchors the side (`sideX`, `sideTop`, `sideBottom`, `sideWidth`), main (its four insets), the footer (own: a 46 strip along main's bottom with Reload at LEFT 28 and Close at RIGHT −26, as today; Blizzard: along the window's bottom, Reload at BOTTOMLEFT window 16, 16 and Close at BOTTOMRIGHT −16, 16), the search box (TOPRIGHT main −`rightPad`), and the nav content and items (`navWidth`; an item's text `navWidth − 30` wide).
  - `PlaceBody(top, filled)` puts the body's BOTTOMRIGHT at main (−(`rightPad` − (`filled` and `fillReach` or `bodyReach`)), `bodyBottom`).
  - Dragging stays as it is: the header area and, under Thick and Thin, the brand; under Blizzard the title bar.
- [ ] **Step 4: Add `ART.optionswindow`** to `themeart.lua` (with `Atlas('Options_InnerFrame')`) and `CONTROLS.optionswindow = true`, and the atlas to `tests/wow/atlases.lua` for both clients.
- [ ] **Step 5: Run all tests.** `tests/run`: everything passes, Task 1's case included.
- [ ] **Step 6: Commit.** `core: under Blizzard /sui is Blizzard's Settings window: the metal, its title bar, the inner frame and a wider layout`

### Task 3: `/sui`'s dressing under Blizzard: sidebar, banners, gold names, the page divider, no rules

**Files:**
- Modify: `SaftUI-Core/Config/optionswindow.lua`, `SaftUI-Core/Config/optionsbody.lua`, `SaftUI-Core/Config/optionswidgets.lua` (`W.LookSearch`).
- Modify: `SaftUI-Core/themeart.lua`: `ART.optionswindow` gains `banners` and `rule`; `ART.optionslist` gains `text`.
- Modify: `tests/wow/atlases.lua`: `Options_CategoryHeader_1`, `_2`, `_3` = `{ 199, 144 }`, `Options_HorizontalDivider` = `{ 630, 1 }`, both clients.
- Test: `tests/core/options_settings_test.lua`; `tests/core/options_window_test.lua` (Thick textures).

**Interfaces:**
- Consumes: Task 2's `OW.LAYOUT`, `F.side`, `F.brand`, `F.foot`, `F.footer`.
- Produces:
  - `Control('optionswindow').banners = { 'Options_CategoryHeader_1', '_2', '_3' }`, `.rule = 'Options_HorizontalDivider'`, `.groupHeight = 30`, `.groupLabel = { x = 20, y = -1 }`.
  - `Control('optionslist').text = { normal = { 1, 0.82, 0 }, picked = { 1, 1, 1 } }`.
  - `OW.BannerAtlas(n) -> atlas`: `banners[((n - 1) % 3) + 1]`.
  - New `OW.GetFrames()` fields: `sideFill` (the sidebar's texture), `sideLines` (its edge and the brand's, actions' and foot's lines), `footerLine`.
  - `body.blizzard`, set by `Body:Draw` and `Body:DrawResults` from `W.BlizzardLook()`.

- [ ] **Step 1: Write the failing tests**, for each client in `options_settings_test.lua`:
  - `'the sidebar under Blizzard: no fill or lines, banners by index, gold and white names'`:
    ```lua
    check(not F.sideFill:IsShown()); for _, l in ipairs(F.sideLines) do check(not l:IsShown()) end
    -- the group headers in order: Frames, Combat, Info, then the page with no category
    eq(banners(), 'Frames=Options_CategoryHeader_1,Combat=Options_CategoryHeader_2,Info=Options_CategoryHeader_3,Other=Options_CategoryHeader_1')
    eq(header:GetHeight(), 30); eq(insets(header.banner, header):match('^0,0'), '0,0'); eq(size_of(header.banner), '199x144')
    eq(anchor(header.text), 'LEFT header LEFT 20,-1'); eq(rgb(header.text), '1.00,1.00,1.00')
    eq(rgb(active.text), '1.00,1.00,1.00', 'the open page white')
    eq(rgb(other.text), '1.00,0.82,0.00', 'the others gold')
    stub.fire_script(other, 'OnEnter'); eq(rgb(other.text), '1.00,1.00,1.00', 'white under the mouse')
    stub.fire_script(other, 'OnLeave'); eq(rgb(other.text), '1.00,0.82,0.00')
    ```
  - `'the main column under Blizzard: the page divider, no section rules, no footer line, the glass'`:
    ```lua
    eq(F.tabLine:GetAtlas(), 'Options_HorizontalDivider'); eq(at(F.tabLine), '259,139 834x1')
    st.Config:Open('Tabs'); eq(F.subLine:GetAtlas(), 'Options_HorizontalDivider', "the subtab row's line too")
    st.Config:Open('Long') -- three titled sections
    eq(rules(), 0, 'no 1px line across the body') ; check(dividers() > 0, "the halves' dividers stay")
    check(not F.footerLine:IsShown())
    eq(size_of(glass), '10x10'); eq(anchor(glass), 'LEFT search LEFT 6,-1')
    ```
    `banners()` lists each group header's text and its banner's atlas, in order; `header`, `active` and `other` are a group header, the open page's entry and another entry. `rules()` counts the body's shown line textures as wide as the body and 1 tall; `dividers()` those 1 wide.
  - `'the dressing comes off under Thick'`: `switch('thick')`: `sideFill` shown at `0.09,0.09,0.09,1.00`, every side line shown, group headers 29 tall with text at TOPLEFT 18, −12 in grey and no banner, names in the profile's normal text color, `F.tabLine` with no atlas and `OB.LINE`'s color, `rules()` equal to the section count less one, the footer line shown, the glass back to Thick's (none).
  - In `options_window_test.lua`, Task 1's case also checks `fills(F.footer)` and `F.tabLine`'s color: Thick's lines, as today.
- [ ] **Step 2: Run them; they fail** (no `sideFill`; the tab line has no atlas).
- [ ] **Step 3: Implement.**
  - `optionswindow.lua`: keep the sidebar fill, the four side lines and the footer line in `F`, shown only under own. `MakeNavGroup`'s header gains `header.banner` (a BACKGROUND texture at TOPLEFT, at its atlas size, shown only under Blizzard). `DrawSidebar` numbers the group headers in order and sets the banner (`OW.BannerAtlas(n)`), the header's height (29 or 30) and its text (own: TOPLEFT 18, −12, grey; Blizzard: LEFT 20, −1, white). `StyleNavItem` and the item's OnEnter and OnLeave color the name: Blizzard gold, white when active or under the mouse; own the label font's color, as today. `PlaceLine` gives the tab and subtab lines the rule atlas under Blizzard and `OB.LINE`'s color texture under own.
  - `optionsbody.lua`: `Body:DrawSections` acquires no section line (`entry.lineY`) while `self.blizzard`. The layout's y values don't change: the gap stays where the line was.
  - `W.LookSearch`: the glass at LEFT 6, −1 (it is 10 × 10 at LEFT 6, 0 today; the spec's "drawn 24" is out of date, see "Spec conflicts and gaps").
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core: /sui under Blizzard: banners, gold names, the page divider, no rules or sidebar fill`

### Task 4: Settings check boxes at the Settings size

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua` (`CheckBox`, `LookCheckBox`, `LookRow`, `LayCheckRow`, the toggle).
- Modify: `tests/wow/widgets.lua`: `Frame.SetHitRectInsets(left, right, top, bottom)` and `Frame.GetHitRectInsets()`, remembered (the client stores them and widens or narrows where the frame takes the mouse; the stub doesn't model clicks by position, so it only remembers them).
- Test: `tests/core/options_widgets_test.lua`.

**Interfaces:**
- Produces: `W.CheckArtSize(rowHeight) -> width, height`: `height = min(29, rowHeight)`, `width = min(30, floor(height × 30 / 29 + 0.5))`.

- [ ] **Step 1: Write the failing tests.**
  - `'W.CheckArtSize: the largest whole size up to 30x29, in proportion, within the row'`:
    ```lua
    eq(table.concat({ W.CheckArtSize(34) }, 'x'), '30x29')
    eq(table.concat({ W.CheckArtSize(29) }, 'x'), '30x29')
    eq(table.concat({ W.CheckArtSize(22) }, 'x'), '23x22')
    eq(table.concat({ W.CheckArtSize(18) }, 'x'), '19x18')
    ```
  - `"under Blizzard a toggle's box is drawn 30x29, a multiselect's and a check list's rows 23x22; no box or row changes size"`:
    ```lua
    theme('blizzard'); rebind(t); rebind(m)
    for _, region in ipairs(shown_textures(t.frame)) do
    	eq(size_of(region), '30x29'); eq(around(region, t.frame), '-12,5,0,-6', 'its right on the box, 5 above')
    end
    eq(size_of(t.frame), '18x18'); eq(t:GetWidth(), 18)
    eq(table.concat({ t.frame:GetHitRectInsets() }, ','), '-12,0,-5,-6', 'a click on the art reaches the box')
    for _, region in ipairs(shown_textures(m.rows[1].box)) do
    	eq(size_of(region), '23x22'); eq(around(region, m.rows[1].box), '0,2,5,-2')
    end
    eq(m.rows[1]:GetHeight(), 22)
    -- W.OpenCheckList's rows: the same 23x22 on an 18 box
    theme('thick'); rebind(t)
    eq(atlases_of(t.frame), '', 'Thick: no art'); eq(table.concat({ t.frame:GetHitRectInsets() }, ','), '0,0,0,0')
    ```
  - Change `"/sui's execute button and toggle take Blizzard's art…"`: its loop asserting each region `'0,0,0,0'` inside the 18 square is replaced by this test's sizes. Its atlas assertions stay.
- [ ] **Step 2: Run them; they fail** (the art is 18 × 18).
- [ ] **Step 3: Implement** `LookCheckBox(box, blizzard, rowHeight, align)`. Under Blizzard its textures (and a multiselect row's hover) are `W.CheckArtSize(rowHeight)`, placed by whole pixels: `align` `'RIGHT'` (the toggle: TOPRIGHT box (0, `floor((h − 18) / 2)`)) or `'LEFT'` (a row: TOPLEFT box (0, `floor((h − 18) / 2)`)). The toggle's hit rect insets are (−(w − 18), 0, −top, −(h − 18 − top)) under Blizzard and 0 under own. The toggle passes `OB.ROW_HEIGHT`'s 34 (`optionswidgets.lua` loads first, so use the literal 34 named as the body's row height), and the multiselect and check list rows their 22.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core: /sui's check boxes are drawn at the Settings box's size under Blizzard`

### Task 5: The Settings dropdown (WowStyle2) and its list

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua`:
  - `LookDropdown` draws the face;
  - `PaintArrow` becomes `PaintFace`;
  - `DropdownStates` keeps the face following the button's state;
  - `LookList` and `BuildList`, for the list's art;
  - exports `W.LookDropdown` and `W.DropdownStates`.
- Modify: `SaftUI-Core/Config/optionswindow.lua`: the dialog's scroll frame reaches 7 past its content under Blizzard.
- Modify: `SaftUI-Bags/ruleeditor.lua`: `MakeField` keeps its caret rows in `field.caret`, calls `W.DropdownStates`, and each field takes `W.LookDropdown(field, W.BlizzardLook(), true)` when its row is laid out.
- Modify: `SaftUI-Core/themeart.lua`: `ART.dropdown` replaced by WowStyle2's.
- Modify: `tests/wow/atlases.lua`, both clients:
  - remove `common-dropdown-textholder`, `common-dropdown-a-button` (and `-hover`, `-pressed`, `-open`, `-disabled`) and `common-dropdown-bg`: nothing names them any more;
  - add `common-dropdown-c-button`, `-hover-1`, `-pressed-1`, `-pressedhover-1`, `-open`, `-disabled` = `{ 39, 39 }`;
  - add `common-dropdown-c-button-hover-arrow` = `{ 12, 5 }`, `common-dropdown-c-bg` = `{ 90, 90 }`, `common-dropdown-customize-mouseover` = `{ 20, 20 }`.
- Test: `tests/core/options_widgets_test.lua`, `tests/bags/rule_editor_test.lua`, `tests/core/options_window_test.lua` (the dialog).

**Interfaces:**
- Produces:
  - `Control('dropdown')`:
    ```
    { face = { normal = 'common-dropdown-c-button', hover = '…-hover-1', pressed = '…-pressed-1',
               pressedhover = '…-pressedhover-1', open = '…-open', disabled = '…-disabled' },
      hoverArrow = 'common-dropdown-c-button-hover-arrow', outset = 7, compactOutset = 4,
      textInset = 13, pressedOffset = { 2, -1 },
      list = 'common-dropdown-c-bg', listOutsets = { -17, 12, 17, -22 }, listInsets = { 3, 6, 3, 7 },
      rowHover = 'common-dropdown-customize-mouseover' }
    ```
  - `W.LookDropdown(button, blizzard, compact)`: `button.caret` (its rows) and `button.text` are the button's. The face is the button's rect, or `button.faceLeft` to `button.faceRight` in from its sides (0 until Task 6 sets them).
  - `W.DropdownStates(button, isDisabled)`.
  - `PaintFace(button)` picks the face's state: disabled; pressedhover (down and over); hover; pressed; open (`W.ListOwner() == button`); else normal.

- [ ] **Step 1: Write the failing tests.**
  - Replace `'a select is a Blizzard dropdown, its arrow open while its list shows'` with `"a select is the Settings dropdown: its face follows the mouse, a press and its list"`:
    ```lua
    theme('blizzard'); rebind(w)
    check_no_box(button, 'Blizzard'); eq(size_of(button), '170x24')
    eq(atlases_of(button), 'common-dropdown-c-button', 'the face; no caret, no hover arrow yet')
    eq(around(face, button), '-7,7,7,-7', 'a 7px glow round the button')
    eq(w.text:GetJustifyH(), 'CENTER'); eq(insets_of_text(), '13,13')
    stub.fire_script(button, 'OnEnter'); eq(face:GetAtlas(), 'common-dropdown-c-button-hover-1')
    check(arrow:IsShown()); eq(size_of(arrow), '12x5'); eq(around(arrow, button):match(',(-?%d+)$'), '-5', 'hanging under the face')
    stub.fire_script(button, 'OnMouseDown', 'LeftButton'); eq(face:GetAtlas(), 'common-dropdown-c-button-pressedhover-1')
    eq(text_offset(), '2,-1', 'the text pressed in')
    stub.fire_script(button, 'OnMouseUp', 'LeftButton'); stub.fire_script(button, 'OnLeave')
    eq(face:GetAtlas(), 'common-dropdown-c-button'); check(not arrow:IsShown())
    click(button); eq(face:GetAtlas(), 'common-dropdown-c-button-open'); W.CloseList()
    w:SetDisabled(true); eq(face:GetAtlas(), 'common-dropdown-c-button-disabled'); w:SetDisabled(false)
    theme('thick'); rebind(w); eq(atlases_of(button), ''); check_box(button, 'Thick again'); eq(#shown_textures(button), caret)
    ```
    `face` and `arrow` are the button's pieces showing a `common-dropdown-c-button…` atlas and the hover arrow; `insets_of_text()` is the text's LEFT and RIGHT offsets from the face; `text_offset()` how far the text sits from its unpressed place.
  - Replace `"the list's rows sit on common-dropdown-bg"` with `"the list sits on common-dropdown-c-bg, in place of the tooltip border"`:
    ```lua
    check_no_box(list.frame); check(list.skin:IsShown())
    eq(st:DrawnKind(list.skin), nil, 'the theme draws nothing there: c-bg is its border')
    eq(atlases_of(list.skin), 'common-dropdown-c-bg'); eq(around(menu, list.frame), '-17,12,17,-22')
    eq(anchor(list.rows[1]), 'TOPLEFT frame TOPLEFT 3,-6'); eq(list.frame:GetHeight(), 2 * 22 + 13)
    stub.fire_script(list.rows[1], 'OnEnter'); eq(list.rows[1].hover:GetAtlas(), 'common-dropdown-customize-mouseover')
    eq(around(list.rows[1].hover, list.rows[1]), '0,0,0,0')
    -- Thick: Box, the blue hover at 0.25, rows at 1,-1, height 2 * 22 + 2, the skin hidden
    ```
  - Change `'W.OpenCheckList under Blizzard…'`: "drawn as the select list is" now means the c-bg skin, the rows at (3, −6) and the mouseover hover.
  - Change `"the position block's boxes, dropdown and nudges take their art…"`: the dropdown is the face, compact: `around(face, select) == '-4,4,4,-4'`, and OnEnter shows `-hover-1` with no hover arrow.
  - `tests/bags/rule_editor_test.lua`, `"under Blizzard a rule's value fields are compact Settings dropdowns; under Thick their own box"`: a class field shows `common-dropdown-c-button` at `'-4,4,4,-4'`, its caret hidden, `-open` while its list shows, and under Thick `W.Box`'s backdrop and caret again with its size unchanged.
  - `options_window_test.lua`, `"the dialog's scroll reaches 7 past its content under Blizzard"`: `OW.GetDialogFrames().scroll:GetWidth()` is 527 under Blizzard and 520 under Thick.
- [ ] **Step 2: Run them; they fail** (WowStyle1 atlases).
- [ ] **Step 3: Implement.**
  - `LookDropdown`'s Blizzard look:
    - a `Face` texture (BACKGROUND), from (faceLeft − outset, outset) to (−faceRight + outset, −outset) of the button, outset 7 or `compactOutset`;
    - a `HoverArrow` (OVERLAY, 12 × 5, not on a compact one), TOPLEFT at (faceLeft + `floor((faceWidth − 12) / 2)`, −24): its left edge on a whole pixel;
    - the text from faceLeft + 13 to −(faceRight + 13), centred.

    Its own look puts back Box, the caret and the text at LEFT 8, RIGHT −22, justified left. `PaintFace` sets the face's atlas, shows the arrow while over and enabled, and offsets the text (2, −1) while down, under Blizzard only.
  - `LookList`'s Blizzard look:
    - no Box;
    - `list.skin` is a plain frame of SaftUI's (never drawn with `st:SetTemplate`) holding `c-bg` at `listOutsets` around `list.frame`, under it;
    - rows at (3, −6 − (i − 1) × 22) to (−3, …);
    - the list `rows × 22 + 13` tall;
    - each row's hover the `rowHover` atlas at alpha 1.

    Its own look keeps today's.
  - `ART.dropdown` loses the WowStyle1 entries. Nothing else reads them (`grep -n "Control('dropdown')"`).
  - `BuildDialog` (`optionswindow.lua`): the dialog's scroll frame's BOTTOMRIGHT is (−(DIALOG_PAD − 7), DIALOG_FOOT) under Blizzard, re-set when the dialog renders with another look.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core, bags: /sui's dropdowns are the Settings dropdown, its list on Blizzard's menu art`

### Task 6: Steppers on an option row's dropdown, where its choices fit

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua` (the select builder and methods).
- Modify: `SaftUI-Core/themeart.lua`: `Control('dropdown').stepper`.
- Modify: `tests/wow/atlases.lua`, both clients: `common-dropdown-c-button-hover-2`, `-pressed-2`, `-pressedhover-2` = `{ 39, 39 }`; `common-dropdown-icon-back`, `-back-disabled`, `-next`, `-next-disabled` = `{ 17, 17 }`.
- Test: `tests/core/options_widgets_test.lua`, `tests/core/options_settings_test.lua` (the picker).

**Interfaces:**
- Consumes: Task 5's `W.LookDropdown`, `button.faceLeft`, `button.faceRight`, `Control('dropdown').textInset`.
- Produces:
  - `Control('dropdown').stepper`:
    ```
    { width = 26, backGap = 5, nextGap = 4,
      background = { normal = 'common-dropdown-c-button', hover = '…-hover-2', pressed = '…-pressed-2',
                     pressedhover = '…-pressedhover-2', disabled = '…-disabled' },
      back = 'common-dropdown-icon-back', backDisabled = '…-back-disabled',
      next = 'common-dropdown-icon-next', nextDisabled = '…-next-disabled', icon = 17 }
    ```
  - `W.StepperRoom() -> number`: the stepped face's room for its text, `W.WIDTH.select − (width + backGap) − (width + nextGap) − 2 × textInset`: 83.
  - On a select widget: `w.back` and `w.next` (Buttons, children of `w.frame`, 26 × 24); `w:StepsFit() -> boolean`: the longest choice's label (`ListEntries`, read when asked), measured in the font the face draws it in (a hidden font string of the widget's, through `SetFieldFont`; a font list's entry in its own face), is at most `W.StepperRoom()` wide (`ceil(GetUnboundedStringWidth())`), and true with no choices; `w:StepTargets() -> backKey | nil, nextKey | nil` in the list's order (`ListEntries`); `w:Step(direction)`, −1 or 1, which does `w:Commit(key)`.

- [ ] **Step 1: Write the failing tests.**
  - `'under Blizzard a select whose choices fit has steppers inside its 170, the face between them'` (values `A`, `B`, `C`):
    ```lua
    eq(size_of(w.back), '26x24'); eq(anchor(w.back), 'LEFT frame LEFT 0,0')
    eq(size_of(w.next), '26x24'); eq(anchor(w.next), 'RIGHT frame RIGHT 0,0')
    eq(around(face, button), '24,7,-23,-7', 'the face from 31 to 140')
    eq(arrow_left(), 79)
    eq(icon_of(w.back), 'common-dropdown-icon-back'); eq(anchor(icon(w.back)), 'TOPLEFT back TOPLEFT 4,-3')
    eq(around(background(w.next), w.next), '-7,7,7,-7')
    stub.fire_script(w.next, 'OnEnter'); eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-hover-2')
    theme('thick'); rebind(w); check(not w.back:IsShown() and not w.next:IsShown())
    ```
    `icon(b)` and `background(b)` are a stepper's two textures, `icon_of(b)` the icon's atlas, and `arrow_left()` the hover arrow's left from the button's. Task 5's select test (its values fit) changes with this: its face sits at `'24,7,-23,-7'`.
  - `'a select gets steppers only when its longest choice fits the stepped face; otherwise the Settings face at the full 170'` (the user's answer 5):
    ```lua
    eq(W.StepperRoom(), 83)
    local char = select(2, W.GetFont():GetFont()) / 2 -- the stub's character: half the font's size wide
    local fits = string.rep('m', math.floor(83 / char))
    values = { a = fits, b = 'B' }; theme('blizzard'); rebind(w)
    check(w.back:IsShown() and w.next:IsShown(), 'the longest choice fits: steppers')
    values = { a = fits .. 'm', b = 'B' }; rebind(w)
    check(not w.back:IsShown() and not w.next:IsShown(), 'one character more: none')
    eq(around(face, button), '-7,7,7,-7', 'the face at the full 170'); eq(arrow_left(), 79, 'the hover arrow centred on it')
    values = { theme = "Use SaftUI's theme", thick = 'Thick', blizzard = 'Blizzard' }; rebind(w)
    check(not w.back:IsShown(), "a Theme select's choices don't fit")
    ```
  - `'a stepper picks the next or previous choice through the same path as a pick, and stops at the ends'`: values `{ a = 'A', b = 'B', c = 'C' }` at `b`, with counters on validate, set and onChanged:
    ```lua
    click(w.next); eq(stored, 'c'); eq(validated, 1); eq(changed, 1)
    check(not w.next:IsEnabled()); eq(icon_of(w.next), 'common-dropdown-icon-next-disabled')
    eq(background(w.next):GetAtlas(), 'common-dropdown-c-button-disabled')
    click(w.back); click(w.back); eq(stored, 'a'); check(not w.back:IsEnabled())
    -- a validate that fails: nothing set, onChanged(false, message); a confirm: W.Confirm asks first, No sets nothing
    ```
  - `'stepper edge cases'` (Review Focus 3):
    - a stored value not among the values: back disabled, next picks the first;
    - one value: both disabled;
    - `w:SetDisabled(true)`: both disabled; enabled again: as the value says;
    - a `values` function that changes between clicks: the order read at the click;
    - a `values` function whose longest label grows past `W.StepperRoom()`: steppers at one bind, none at the next, and back when it shrinks.
  - `options_settings_test.lua`, `"the picker row's select has steppers when its choices fit; the position block's dropdown has none"` (a picker of short names).
- [ ] **Step 2: Run them; they fail** (no `w.back`).
- [ ] **Step 3: Implement.**
  - The builder makes `w.back` and `w.next`, hidden, each with a `Background` texture at (−7, 7) to (7, −7) around it and an `Icon` at (4, −3).
  - The select's `Bind`: under Blizzard, when `w:StepsFit()`, `button.faceLeft` and `faceRight` are 31 and 30 and the steppers show; else both 0 (the full-width face) and the steppers hide. Under own both 0 and hidden. Then `W.LookDropdown`. The fit is read at each bind, so a render follows a change in the choices.
  - Their states follow the mouse as the face does (disabled, pressedhover, hover, pressed, normal), and the icon moves (2, −1) while pressed. `Refresh` and `OnDisabled` enable each by `w:StepTargets()` and `w.disabled`.
  - A click runs `w:Step(±1)`.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core: under Blizzard an option row's dropdown has Blizzard's steppers where its choices fit`

### Task 7: The slider's end arrows

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua` (the range builder, `LookRange`, its methods).
- Modify: `SaftUI-Core/themeart.lua`: `Control('slider')` gains `back`, `forward`, `arrowGap = 4`.
- Modify: `tests/wow/atlases.lua`, both clients: `Minimal_SliderBar_Button_Left` = `{ 11, 19 }`, `Minimal_SliderBar_Button_Right` = `{ 9, 18 }`.
- Test: `tests/core/options_widgets_test.lua`.

**Interfaces:**
- Produces: on a range widget, `w.backArrow` and `w.forwardArrow` (Buttons, children of `w.frame`); `w:StepBy(direction) -> nil`. It steps from the shown value (`self.value`, else `softMin`) by `step`, else `bigStep`, else a hundredth of the slider's span; snaps on `softMin`'s grid of that step; clamps to `softMin`–`softMax`, then `Cut`; commits only a changed value.

- [ ] **Step 1: Write the failing tests.**
  - `"under Blizzard a range has the minimal slider's end arrows inside its 116"`:
    ```lua
    eq(atlas_of(w.backArrow), 'Minimal_SliderBar_Button_Left'); eq(size_of(w.backArrow), '11x19'); eq(anchor(w.backArrow), 'TOPLEFT frame TOPLEFT 0,-2')
    eq(anchor(w.slider), 'LEFT frame LEFT 15,0'); eq(size_of(w.slider), '88x24')
    eq(atlas_of(w.forwardArrow), 'Minimal_SliderBar_Button_Right'); eq(size_of(w.forwardArrow), '9x18'); eq(anchor(w.forwardArrow), 'TOPLEFT frame TOPLEFT 107,-3')
    eq(size_of(w.frame), '168x24'); eq(size_of(w.edit), '46x24')
    theme('thick'); rebind(w); check(not w.backArrow:IsShown()); eq(size_of(w.slider), '116x24'); eq(anchor(w.slider), 'LEFT frame LEFT 0,0')
    ```
    `'a range is a minimal slider…'` changes its Blizzard `'and its slider'` assertion to `'88x24'`.
  - `'a slider arrow steps by the option's step through the same path as a drag, clamped, disabled at the ends'`: min 0, max 10, step 1, at 5:
    ```lua
    click(w.forwardArrow); eq(stored, 6); eq(validated, 1)
    stored = 10; w:Refresh(); check(not w.forwardArrow:IsEnabled()); check(w.backArrow:IsEnabled())
    stored = 0; w:Refresh(); check(not w.backArrow:IsEnabled())
    w:SetDisabled(true); check(not w.forwardArrow:IsEnabled() and not w.backArrow:IsEnabled())
    ```
    A disabled arrow's texture is desaturated.
  - `'slider arrow edge cases'`:
    - isPercent with step 0.05 at 0.5: forward stores 0.55 and the box shows `55%`;
    - no step and no bigStep, slider 0 to 200: forward from 100 stores 102;
    - softMax 10 and max 100 with a stored 50: forward disabled, back stores 10;
    - a bigStep of 5 with a step of 1: an arrow moves 1.
- [ ] **Step 2: Run them; they fail** (no `w.backArrow`).
- [ ] **Step 3: Implement.** Under Blizzard `LookRange` narrows and moves the slider (LEFT 15, 88 wide) and shows the arrows. Under own it puts the slider back at LEFT 0, 116 wide, and hides them. `Refresh` and `OnDisabled` enable the arrows by `w.value` against `softMin` and `softMax` and by `w.disabled`. A click runs `w:StepBy(±1)`.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core: under Blizzard a slider has Blizzard's end arrows, each a step`

### Task 8: Blizzard's minimal scroll bar on every `/sui` scroll area

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua`: `W.BlizzardBar`, and the select list's bar.
- Modify: `SaftUI-Core/Config/optionsbody.lua`: `OB.ScrollBar` and `OB.ScrollTo` drive a companion.
- Modify: `SaftUI-Core/Config/optionswindow.lua`: the body's, the nav's and the dialog's bars with their setters.
- Modify: `SaftUI-Bags/categoriestab.lua`: the list's and editor's bars with their setters.
- Modify: `SaftUI-Core/themeart.lua`: `ART.scrollbar`, `CONTROLS.scrollbar`.
- Modify: `tests/wow/atlases.lua`, both clients:
  - `minimal-scrollbar-track-top` and `-bottom` = `{ 8, 8 }`; `!minimal-scrollbar-track-middle` = `{ 8, 1, 'v' }`;
  - `minimal-scrollbar-small-thumb-top` and `-bottom` = `{ 8, 8 }`, `-middle` = `{ 8, 715 }`;
  - each thumb piece's `-over` and `-down` at the same sizes.
- Test: `tests/core/options_settings_test.lua`, `tests/core/options_widgets_test.lua`, `tests/bags/categories_tab_test.lua`.

**Interfaces:**
- Produces:
  - `Control('scrollbar')`:
    ```
    { track = { top = 'minimal-scrollbar-track-top', middle = '!minimal-scrollbar-track-middle', bottom = 'minimal-scrollbar-track-bottom' },
      thumb = { normal = { top, middle, bottom }, over = { … '-over' }, down = { … '-down' } },
      up = Control('nudge').up, down = Control('nudge').down, -- the arrows' normal, hover, pressed
      width = 8, arrow = { 17, 11 }, narrowArrow = { 8, 5 }, inset = 19, narrowInset = 9, minThumb = 23 }
    ```
  - `W.BlizzardBar(parent, onScroll, opts) -> bar`, `opts = { narrow = bool, step = number }`:
    - `bar:Set(anchor, x, y, length, view, total, offset)`: the track's left `x` right of `anchor`'s left, the column's top (the up arrow's) `y` below `anchor`'s top, `length` tall, arrows included. It shows only while `total > view`; the thumb is `max(23, floor(trackLength × view / total))` tall, as far down as offset says.
    - `bar:Hide()`.
    - `bar.frame`, `.track`, `.thumb`, `.up`, `.down` for tests.
    - `onScroll(offset)` gets the new offset, unclamped: a thumb drag (start offset + cursor travel × range / (track − thumb), read on the frame's OnUpdate while held), an arrow click (± `opts.step`), a track click (± view, above or below the thumb).
  - `OB.ScrollBar(parent, onScroll, opts) -> texture`: as today the 3px bar, plus a companion `W.BlizzardBar`. `opts.flat == false` draws no 3px bar under own.
  - `OB.Companion(bar) -> companion`: the `W.BlizzardBar` made with a 3px bar.
  - `OB.BLIZZARD_GAP = 12`.
  - `OB.ScrollTo(frame, bar, offset, height, gap)`: signature and return unchanged. Under own exactly today's, the companion hidden. Under Blizzard the 3px texture hidden, and the companion `Set` at x = child width + (gap or `OB.BLIZZARD_GAP`) from the scroll frame.
  - The list's own bar: `list.blizzardBar = W.BlizzardBar(list.frame, …, { narrow = true, step = 1 })` in rows, its track at `list.frame` width − 3 − 8 from `listInsets.top`, shown by `ListFill` under Blizzard in place of `list.bar`.

- [ ] **Step 1: Write the failing tests.**
  - `options_settings_test.lua`, `'under Blizzard a scroll area shows MinimalScrollBar only with something to scroll'`, for each client, on `Long`:
    ```lua
    local bar = OB.Companion(F.bar)
    check(bar.frame:IsShown()); check(not F.bar:IsShown(), 'not the 3px bar')
    eq(atlases_of(bar.track), '!minimal-scrollbar-track-middle,minimal-scrollbar-track-bottom,minimal-scrollbar-track-top')
    eq(bar.track:GetLeft() - F.content:GetLeft(), 774 + 12); eq(bar.track:GetWidth(), 8)
    eq(size_of(bar.up), '17x11'); eq(bar.up:GetLeft(), bar.track:GetLeft() - 4); eq(bar.up:GetTop(), F.body:GetTop())
    eq(bar.track:GetTop(), F.body:GetTop() - 19)
    eq(bar.thumb:GetHeight(), math.max(23, math.floor(track_len * view / total)))
    check(bar.down:GetRight() <= F.main:GetRight() - 7, 'clear of the inner frame')
    st.Config:Open('Loot'); check(not bar.frame:IsShown(), 'nothing to scroll: no bar')
    switch('thick'); st.Config:Open('Long'); check(F.bar:IsShown()); check(not bar.frame:IsShown())
    ```
    `track_len` is the track's height, `view` the body's and `total` the content's.
  - `'the scroll bar works: drag the thumb, click an arrow, click the track; the wheel as before'`, on `Long` under Blizzard:
    - `OnMouseDown` on the thumb, then `stub.cursor_y` lowered by 40 × scale and the bar frame's OnUpdate fired: the body scrolls `floor(40 × range / (track − thumb) + 0.5)`;
    - the thumb shows `-over` under the mouse and `-down` while held;
    - the down arrow scrolls 68 and the up arrow back;
    - a click on the track below the thumb scrolls a view's height;
    - a wheel turn scrolls 68, as today.
  - `'each scroll area has its bar where there is room'`, under Blizzard:
    - the nav with 40 pages: narrow, track at `F.side` left + 226 + 4, inside the sidebar; under Thick no bar;
    - the dialog: narrow at its content + 12;
    - a dropdown list of 20 entries: narrow, inside the list frame on its right;
    - Categories: in `tests/bags/categories_tab_test.lua`, the list's bar narrow, `bar.track:GetLeft() - w.listScroll:GetRight() == 4` and its right at or before the divider's left; the editor's wide, its track 12 right of the editor and inside the body's clip (`bar.down:GetRight() <= F.body:GetRight()`).

    The existing Thick assertions in that file are unchanged.
- [ ] **Step 2: Run them; they fail** (`OB.Companion` is nil).
- [ ] **Step 3: Implement.**
  - `W.BlizzardBar` builds:
    - a column frame;
    - the track's three textures;
    - a thumb Button with three textures;
    - two arrow Buttons with the nudge's normal, hover and pressed atlases;
    - `narrow` arrows at 8 × 5 with the track inset 9.

    Thumb drag, arrows and track clicks call `onScroll`; while the thumb is held the frame runs an OnUpdate reading `GetCursorPosition()` over its effective scale.
  - Callers pass setters and steps:
    - the body: `SetScroll`, step `SCROLL_STEP`;
    - the nav: `SetNavScroll` (now through `OB.ScrollTo(F.navFrame, F.navBar, offset, navHeight, 4)`, which clamps as today), narrow, step `NAV_ITEM × 2`, `flat = false`;
    - the dialog: `SetDialogScroll`, narrow, `SCROLL_STEP`;
    - the Categories list: `ScrollList`, narrow, `LIST_STEP`, its gap 4;
    - the Categories editor: `ScrollEditor`, `OB.SCROLL_STEP`.
  - `W.Prompt` and `W.Confirm` size themselves to their text and never scroll: nothing to add there.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core, bags: under Blizzard every /sui scroll area has Blizzard's minimal scroll bar`

### Task 9: The Categories tab's list in the nav rows' look

**Files:**
- Modify: `SaftUI-Bags/categoriestab.lua` (`LayListRow`).
- Test: `tests/bags/categories_tab_test.lua`.

**Interfaces:**
- Consumes: `st.ThemeArt.Control('optionslist')`: `picked`, `hover`, and Task 3's `text`.

- [ ] **Step 1: Write the failing test** `"under Blizzard the category list is the Settings category list; its handles, counts, markers and drop line stay"`:
  ```lua
  st.config.profile.theme.name = 'blizzard'; OW:Render(); local w = tab()
  local sel, other, off = row_of(w, 'Consumables'), row_of(w, SETS), a_disabled_row(w)
  eq(sel.tint:GetAtlas(), 'Options_List_Active'); eq(around(sel.tint, sel.frame), '0,0,0,0')
  check(not sel.bar:IsShown(), 'no blue bar'); eq(rgb(sel.name), '1.00,1.00,1.00')
  eq(rgb(other.name), '1.00,0.82,0.00'); check(not other.tint:IsShown())
  stub.fire_script(other.frame, 'OnEnter'); eq(other.frame.hover:GetAtlas(), 'Options_List_Hover')
  eq(rgb(off.name), grey); check(off.strike:IsShown())
  check(sel.handle:IsShown()); eq(rgb(sel.count), grey); eq(size_of(sel.frame), '210x22')
  -- a drag still draws the drop line (as the drag test does)
  st.config.profile.theme.name = 'thick'; OW:Render(); w = tab()
  -- as today: the blue tint at 0.25, the 3px bar, the blue hover at 0.1, the normal text color
  ```
- [ ] **Step 2: Run it; it fails** (the tint is a blue color texture).
- [ ] **Step 3: Implement** in `LayListRow`, by `W.BlizzardLook()` read on each layout:
  - Blizzard: the hover and tint take the `hover` and `picked` atlases at alpha 1, the bar hidden, the name gold, white when selected, grey when off;
  - own: today's colors.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `bags: under Blizzard the Categories tab's list is the Settings category list`

### Task 10: `/sui` grows taller (every theme)

**Files:**
- Modify: `SaftUI-Core/Config/optionswindow.lua`: the grip and the bottom edge, the drag, `OW.MaxHeight`, `OW.WindowHeight`, the saved height; `Relayout` and `RestorePosition` size the window by it; `Busy` while resizing.
- Modify: `SaftUI-Core/themeart.lua`: `ART.resizegrip`, `CONTROLS.resizegrip`.
- Test: `tests/core/options_window_test.lua` (Thick), `tests/core/options_settings_test.lua` (Blizzard).

**Interfaces:**
- Consumes: Task 2's `OW.LAYOUT`, `F.layout`, `Relayout`, `F.inner`, `F.footer`; Task 8's `OB.ScrollTo` (the companion follows the body's height).
- Produces:
  - `Control('resizegrip') = { normal = [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]], highlight = [[…-Highlight]], pushed = [[…-Down]], size = 16 }`: Blizzard's `PanelResizeButtonTemplate` (`Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml`, the same on both clients). Files, so not among `st:ThemeAtlases()`.
  - `OW.LAYOUT.own.height` and `.blizzard.height` are each look's least height, and its height with none saved.
  - `OW.MaxHeight() -> number`: `2 × floor((UIParent:GetHeight() − 2 × st.config.profile.misc.clamp_inset) / 2)`: the screen less the screen edge margin at its top and its bottom, even.
  - `OW.WindowHeight(layout) -> number`: the saved `st.config.global.optionsWindow.height` when it's a number, made even (`2 × floor(h / 2 + 0.5)`), at most `OW.MaxHeight()`, and at least `layout.height` (which wins on a screen too small for it); `layout.height` with none saved.
  - New `OW.GetFrames()` fields: `grip` (a Button) and `sizer` (the bottom edge, a Frame).
  - `st.config.global.optionsWindow = { point = 'CENTER', x, y, height }`: a move (`SavePosition`) keeps the height saved there as it was, and only a resize writes it. A move must not save the window's height: a window moved under Blizzard (728) would then open 728 tall under Thick.

- [ ] **Step 1: Write the failing tests.**
  - In `options_window_test.lua`, a helper as the mouse drags a handle:
    ```lua
    -- Drags handle dy units down (up when negative): the button down, one frame, the button up.
    local function resize(handle, dy)
    	local scale = frames().window:GetEffectiveScale()
    	stub.mouse_buttons.LeftButton = true
    	stub.cursor_y = 500 * scale
    	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
    	stub.cursor_y = (500 - dy) * scale
    	stub.fire_script(handle, 'OnUpdate', 0.016)
    	stub.mouse_buttons.LeftButton = nil
    	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
    end
    ```
  - `'/sui grows taller by its bottom edge or its grip: its width and top stay, the body takes the height, and it remembers it'` (Thick, on `Loot`):
    ```lua
    local F = frames(); local w = F.window; local top = w:GetTop()
    eq(at(F.grip), '1024,684 16x16'); eq(F.grip:GetNormalTexture():GetTexture(), st.textures.cornerbr)
    eq(at(F.sizer), '0,694 1024x6')
    resize(F.grip, 100)
    eq(at(w), '0,0 1040x800'); eq(w:GetTop(), top, 'its top stays')
    eq(at(F.side), '2,2 208x796'); eq(at(F.navFrame), '2,120 207x647'); eq(at(F.body), '238,113 774x639')
    eq(at(F.reloadButton:GetParent()), '210,752 828x46', 'the footer at the bottom')
    eq(st.config.global.optionsWindow.height, 800, "saved in SaftUI's global settings")
    resize(F.sizer, -300); eq(w:GetHeight(), 700, 'no shorter than its default')
    resize(F.sizer, 51); eq(w:GetHeight(), 752, 'an even height: centred on whole pixels')
    st.Config:Close(); st.Config:Open('Loot'); eq(w:GetHeight(), 752, 'restored when it opens'); eq(w:GetTop(), top)
    resize(F.grip, 5000)
    local inset = st.config.profile.misc.clamp_inset
    check(w:GetBottom() >= inset and w:GetBottom() < inset + 2, 'it stops at the screen edge margin')
    ```
  - `'a resize renders nothing; a fill page draws its fill row once, when the mouse is let go'`, with the fill row test's `FillRows` module: the button down on the grip, OnUpdates at 30, 60 and 100 down, each followed by `tick()`: `OW.GetRenderCount()` and the fill row's height unchanged; the button up and `tick()`: one render, the fill row 100 taller, `F.content:GetHeight() == F.body:GetHeight()`. On a page that scrolls, scrolled to its bottom: a resize 100 taller renders nothing, the offset clamps to the new range, and `F.bar`'s height is `max(20, floor(view × view / total))` for the new view.
  - `'a saved height the screen no longer fits, or under the least'` (Review Focus 2): with `optionsWindow = { point = 'CENTER', x = 0, y = 0, height = h }` before each open:
    - `h = 5000`: `OW.MaxHeight()` tall, its top and bottom inside the screen edge margin;
    - `h = 600`: 700; `h = 'tall'`: 700; `h = 751`: 752;
    - `stub.screen_height = 500` (a screen shorter than 700 plus the margin): 700, the least winning; the screen height back after.
  - `options_settings_test.lua`, with the `resize` helper (copied), for each client, `'under Blizzard /sui grows taller from 728; the inner frame and the sidebar stretch; the grip is Blizzard's'` (Review Focus 1):
    ```lua
    switch('blizzard'); st.Config:Open('Loot')
    eq(at(F.window), '0,0 1110x728')
    eq(F.grip:GetNormalTexture():GetTexture(), [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]])
    eq(F.grip:GetHighlightTexture():GetTexture(), [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]])
    eq(F.grip:GetPushedTexture():GetTexture(), [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]])
    resize(F.grip, 100)
    eq(at(F.inner), '17,28 1076x754'); eq(at(F.side), '17,28 242x754'); eq(at(F.body), '287,139 781x639')
    eq(at(F.footer), '0,782 1110x46')
    switch('thick'); eq(at(F.window), '0,0 1040x828', 'the dragged height under Thick too')
    eq(F.grip:GetNormalTexture():GetTexture(), st.textures.cornerbr)
    st.config.global.optionsWindow.height = 700; switch('blizzard'); eq(F.window:GetHeight(), 728, "a height under Blizzard's least")
    st.config.global.optionsWindow = nil; st.Config:Close(); st.Config:Open('Loot')
    stub.fire_script(F.titleBar, 'OnDragStart'); stub.fire_script(F.titleBar, 'OnDragStop') -- a move at 728
    eq(st.config.global.optionsWindow.height, nil, 'a move saves no height')
    switch('thick'); eq(F.window:GetHeight(), 700, "so Thick keeps today's 700")
    ```
- [ ] **Step 2: Run them; they fail** (`F.grip` is nil).
- [ ] **Step 3: Implement.**
  - `F.grip`: a Button of the window's, 16 × 16 at its BOTTOMRIGHT (0, 0), 10 levels over the window. Its normal, highlight and pushed textures, set on each relayout: under Blizzard `Control('resizegrip')`'s files; under own `st.textures.cornerbr`, the highlight and pushed tinted the button hover color, as `st:EnableResizing` (`skinning.lua`) draws its grip. `F.sizer`: a Frame 6 tall from the window's BOTTOMLEFT to the grip's BOTTOMLEFT, at the grip's level. Both take the left button.
  - OnMouseDown (LeftButton) on either starts a resize: the cursor's y over the window's effective scale, the window's height, its centre offset and its top. While it's held, the pressed handle's OnUpdate sets the height to the start's plus the cursor's travel down, made even as `OW.WindowHeight` makes it, at least `F.layout.height`, at most `min(OW.MaxHeight(), 2 × floor((top − clamp_inset) / 2))`, and moves the CENTER offset down by half the change, so the top stays (whole units: the change is even). Only a changed height is set. After each change: `SetScroll(scrollOffset)`, `SetNavScroll(navOffset)`, and on a fill page `Schedule()` (the body's own OnSizeChanged does the same in game).
  - The resize ends on OnMouseUp, on OnHide, or when its OnUpdate finds the button up: the window's height into `optionsWindow.height`, then `SavePosition()`.
  - `Busy()` is true while a resize is held, so a scheduled render waits for its end.
  - `Relayout` sizes the window `layout.width × OW.WindowHeight(layout)`; `RestorePosition` sets the height too, `OW.WindowHeight(F.layout or OW.LAYOUT.own)`.
  - Update the file's header comment: the window's size, the grip and the edge, the saved height.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core: /sui grows taller by its bottom edge or a grip, in every theme, and remembers its height`

### Task 11: The Categories editor's fixed footer (every theme)

**Files:**
- Modify: `SaftUI-Bags/categoriestab.lua`: the editor pane's footer (`w.footer`, its edge, scroll frame, body and bar), `SplitFooter`, `Layout`, `Fit`, `ScrollFooter`, `EditorCell`, `OnRelease`, and the header comment.
- Test: `tests/bags/categories_tab_test.lua`.

**Interfaces:**
- Consumes: Task 8's `OB.ScrollBar(parent, onScroll, opts)`, `OB.ScrollTo` and `OB.Companion`; Task 3's `Control('optionswindow').rule`; `W.BlizzardLook()`.
- Produces:
  - On a `bagcategories` widget: `w.footer` (a Frame in the editor's column, at the tab's bottom), `w.footerLine` (its top edge, a texture), `w.footerScroll` (a ScrollFrame under the edge) with its scroll child `w.footerPane`, `w.footerBody` (an `OB.New` body, 540 wide), `w.footerBar` (an `OB.ScrollBar`), `w.footerContent` (the footer body's drawn height).
  - `w:EditorCell(key)` finds a row in the editor's body, then the footer's, so `'caught'` and `'pins'` are found where they now are.
  - `INV.categoryEditor.footerOffset`: the footer's scroll, for the session; 0 for another category, as the editor's.
  - `INV:CategoryEditorOptions` is unchanged. The tab splits its group: `SplitFooter(group) -> editorGroup, footerGroup` moves the args named in `FOOTER_KEYS = { 'caught', 'pins' }` into a group of their own, each given its place in that list as its order (Caught now above Pinned items).

- [ ] **Step 1: Write the failing tests.**
  - `"the editor's footer: Caught now above Pinned items at the pane's bottom, as tall as they need, the rest scrolling above it"` (Thick; `INV:PinItem(301, 'Consumables')`, Consumables selected):
    ```lua
    local w = tab(); local height = w.frame:GetHeight()
    local caught, pins = w:EditorCell('caught'), w:EditorCell('pins')
    check(inside(caught.frame, w.footer) and inside(pins.frame, w.footer), 'both in the footer')
    check(caught.frame:GetTop() > pins.frame:GetTop(), 'Caught now above Pinned items')
    eq(caught.widget.frame:GetWidth(), 540, "the pane's full width")
    eq(w.footer:GetLeft() - w.frame:GetLeft(), 234); eq(w.footer:GetWidth(), 540)
    eq(w.footer:GetBottom(), w.frame:GetBottom(), "at the pane's bottom")
    eq(w.footer:GetHeight(), w.footerContent + 1, 'as tall as its strips and its edge')
    eq(w.editorScroll:GetHeight(), height - w.footer:GetHeight()); eq(w.editorScroll:GetBottom(), w.footer:GetTop())
    eq(editor_keys(w), 'name,enabled,show,rule,reset,delete', 'the rest in the editor, Reset and Delete at its end')
    eq(w.footerLine:GetTop(), w.footer:GetTop()); eq(w.footerLine:GetWidth(), 540); eq(w.footerLine:GetHeight(), 1)
    check(same_rgb(stub.state(w.footerLine).color_texture, { unpack(OB.LINE) }), "Thick: the body's line color")
    check(not w.footerBar:IsShown(), 'nothing to scroll')
    INV:UnpinItem(301); OW:Render(); eq(tab():EditorCell('pins'), nil, 'no pins: Caught now alone, as today')
    ```
    `editor_keys(w)` lists `w.body.cells`' row keys in order; `inside` as `options_window_test.lua`'s.
  - `'a footer taller than half the pane scrolls on its own, with the same bar as the other areas'`: 80 pins not in the bags (item IDs 2000 to 2079) on Consumables:
    ```lua
    eq(w.footer:GetHeight(), math.floor(height / 2), 'half the pane')
    check(w.footerBar:IsShown()); eq(w.footerBar:GetWidth(), 3)
    eq(w.footerBar:GetLeft() - w.footerScroll:GetRight(), 10); check(w.footerBar:GetRight() <= F.body:GetRight())
    wheel(w.footerScroll, -1); eq(w.footerScroll:GetVerticalScroll(), 68); eq(w.editorScroll:GetVerticalScroll(), 0, 'the editor stays')
    OW:Render(); eq(tab().footerScroll:GetVerticalScroll(), 68, 'kept when the tab is drawn again')
    -- the X on a pin scrolled into view unpins it
    INV.categoryEditor.selected = 'Trade Goods'; OW:Render(); eq(tab().footerScroll:GetVerticalScroll(), 0, "another category's starts at its top")
    ```
  - `'with the footer fixed, a long rule and the items it catches are in view at once'` (the spec's reason): Grays/Auto Vendor, whose rule is taller than the editor's view: wheel the editor to its end; the gray cloth's icon (502) lies inside the tab's rect; OnEnter on it tints `block{1,1}`, and its tooltip opens beside the window (as `"an item's tooltip opens beside the window…"` places it).
  - `"under Blizzard the footer's edge is the Settings divider and its bar Blizzard's"`: `w.footerLine:GetAtlas() == 'Options_HorizontalDivider'`; with the 80 pins `OB.Companion(w.footerBar).frame:IsShown()` and its track 12 right of the footer's pane; under Thick again the color line with no atlas.
  - Change `"the tab fills the body's view…"`: the editor's view is the tab less the footer: `w.editorScroll:GetHeight() == height - w.footer:GetHeight()` (was `height`); Equipment sets' editor fits that view and Toys' doesn't; the wheel stops at `w.pane:GetHeight() - w.editorScroll:GetHeight()`. Its list, divider and bar-place assertions stay.
- [ ] **Step 2: Run them; they fail** (`w.footer` is nil).
- [ ] **Step 3: Implement.**
  - `build`: `w.footer`, a Frame of the tab's frame, 540 wide; `w.footerLine`, an ARTWORK texture across its top, 1 tall; `w.footerScroll` from 1 under the footer's top to its bottom, with `w.footerPane`; `w.footerBody = OB.New(w.footerPane, nil, function(...) Forward(w, ...) end, EDITOR_WIDTH)`; `w.footerBar = OB.ScrollBar(frame, function(offset) ScrollFooter(w, offset) end, { step = OB.SCROLL_STEP })`; the wheel over the footer runs `ScrollFooter`.
  - `Layout`: `local editor, footer = SplitFooter(INV:CategoryEditorOptions(selected, w, items))`. The editor's body draws `{ category = editor }` as today. `w.footerBody` releases and draws `{ footer = footer }` (`OM.BuildView(root, 'footer')`); `w.footerContent` is what it drew and `w.footerPane` that tall. The footer's levels are the editor's. Another category resets the footer's offset with the editor's. The edge, by `W.BlizzardLook()`: Blizzard `SetAtlas(Control('optionswindow').rule)`, white; own `SetColorTexture(unpack(OB.LINE))`.
  - `Fit`: the footer `min(w.footerContent + 1, floor(height / 2))` tall at TOPLEFT frame (EDITOR_X, −(height − footer)); the editor's scroll `height − footer` tall; the footer's scroll `footer − 1` tall, scrolled with `OB.ScrollTo(w.footerScroll, w.footerBar, offset, w.footerContent)` from where Layout found it, as the editor's is.
  - `OnRelease` releases `w.footerBody` too. `EditorCell` searches `w.body.cells`, then `w.footerBody.cells`. `HighlightWhy`, the tooltip and the X need nothing: they find the rule through `EditorCell('rule')` and the window through the icon's ancestors.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `bags: the Categories editor keeps Caught now and Pinned items in a fixed footer`

---

## Part B: unit frame borders

### Task 12: The `unitframe` and `member` kinds: the bronze box and a bare fill

**Files:**
- Modify: `SaftUI-Core/theme.lua`: `st.THEME_KINDS.unitframe` (a unit frame or one of its bars) and `.member` (a party or raid member's frame or bar).
- Modify: `SaftUI-Core/themeart.lua`:
  - `KINDS.unitframe = { inset = ByClient(2, 2), art = 'unitframe', fill = 'backdropcolor' }`;
  - `KINDS.member = { inset = ByClient(0, 0), fill = 'backdropcolor' }`;
  - `ART.unitframe` with its cut table;
  - `ThemeArt.Cut` and a cut layout used by `Paint`;
  - `SetBorder` tints a cut's pieces as a border's.
- Modify: `tests/wow/blizzard.lua`: `C_Texture.GetAtlasInfo` also returns `file`, `leftTexCoord`, `rightTexCoord`, `topTexCoord`, `bottomTexCoord` for an entry that has them. The game's AtlasInfo carries the atlas's file and coordinates in it. The stub gives them only for the atlases SaftUI cuts, from the clients' `UiTextureAtlas` and `UiTextureAtlasMember` tables at the builds `atlases.lua` names.
- Modify: `tests/wow/atlases.lua`. The format gains `file` and `coords = { left, right, top, bottom }`. Coordinates are the member's pixel rectangle over its atlas file's size; Forever's are the Camelot (`-c60`) members'.

  | Atlas | Forever | Retail |
  | ----- | ------- | ------ |
  | `UI-HUD-UnitFrame-Player-PortraitOn` | 198 × 71, file 8036204, coords 605/1024, 803/1024, 1/512, 72/512 | 198 × 71, file 4631591, coords 1/1024, 199/1024, 87/512, 158/512 |
  | `UI-HUD-UnitFrame-Target-PortraitOn` | 194 × 68, file 8036204, coords 201/1024, 395/1024, 87/512, 155/512 | 192 × 67, file 4631591, coords 1/1024, 193/1024, 229/512, 296/512 |
- Test: `tests/core/theme_blizzard_draw_test.lua`.
- Modify: `tests/core/theme_test.lua` (`'THEME_KINDS has the eleven kinds…'` → thirteen: `action,aura,bar,close,control,header,member,panel,slot,small,tooltip,unitframe,window`) and `tests/core/theme_blizzard_test.lua` (`BLIZZARD_INSETS` gains `unitframe = 2, member = 0`; the count is 13).

**Interfaces:**
- Produces:
  - `st.ThemeArt.ART.unitframe = { layer = 'BORDER', size = 8, pieces = ByClient(forever, live) }`. Each piece is `{ atlas = Atlas(name), rect = { x0, x1, y0, y1 } }`: atlas-local units, ends exclusive, keyed `TopLeftCorner`, `TopRightCorner`, `BottomLeftCorner`, `BottomRightCorner`, `TopEdge`, `BottomEdge`, `LeftEdge`, `RightEdge`. The starting rectangles, measured from the decoded art so each piece's outer two pixels are the dark outline and the rim:

    | Piece | Atlas | Forever | Retail |
    | ----- | ----- | ------- | ------ |
    | TopLeftCorner | Target | 2–10 × 8–16 | 1–9 × 21–29 |
    | BottomLeftCorner | Target | 2–10 × 48–56 | 1–9 × 48–56 |
    | LeftEdge (stretched down) | Target | 2–10 × 30–40 | 1–9 × 30–40 |
    | TopRightCorner | Player | 187–195 × 11–19 | 186–194 × 24–32 |
    | BottomRightCorner | Player | 187–195 × 51–59 | 186–194 × 51–59 |
    | RightEdge (stretched down) | Player | 187–195 × 34–42 | 186–194 × 34–42 |
    | TopEdge (stretched across) | Player | 120–121 × 11–19 | 120–121 × 24–32 |
    | BottomEdge (stretched across) | Player | 120–121 × 51–59 | 120–121 × 51–59 |

    The spec's bottom rectangles (BottomLeft 50–58, BottomRight and BottomEdge 52–60) put the bottom rim two rows and one row further in than the top's. These put the rim on the second row in from the edge on every side, which also aligns BottomLeft with BottomRight as the spec asked (see "Spec conflicts and gaps").
  - `st.ThemeArt.Cut(texture, atlas, rect) -> boolean`: sets the texture to the atlas's file at texture coordinates `left + (right − left) × x / width` (and the same down). It returns false, hiding the texture, when `GetAtlasInfo` gives no file.
  - The cut layout: corners `size` × `size` at the drawn frame's corners (offset 0); edges between their corners, stretched (no tiling); every piece in `layer`. Shared by Task 14's group border.

- [ ] **Step 1: Write the failing tests** in `theme_blizzard_draw_test.lua`:
  - `'unitframe and member draw as bar under Thick and Thin'`: for Thick and Thin, `st:SetBackdrop` of `unitframe`, `member` and `bar` on three frames give equal `T.fill`, `T.edge`, `T.inset`, `T.offset(…, 'TOPLEFT')` and Thick's outer lines.
  - `'under Blizzard unitframe is the bronze box: eight pieces cut from the player and target art, on each client'`:
    ```lua
    for _, client in ipairs(CLIENTS) do
    	local st = T.client(client); st.config.profile.theme.name = 'blizzard'
    	local owner = frame(st); st:SetBackdrop(owner, 'theme', 'theme', 'unitframe')
    	local pieces = st.ThemeArt.Get(owner.backdrop).pieces
    	local forever = client == 'forever'
    	eq(pieces.TopLeftCorner:GetTexture(), forever and 8036204 or 4631591)
    	eq(coords(pieces.TopLeftCorner), forever and px(203, 211, 95, 103, 1024, 512) or px(2, 10, 250, 258, 1024, 512))
    	eq(coords(pieces.BottomRightCorner), forever and px(792, 800, 52, 60, 1024, 512) or px(187, 195, 138, 146, 1024, 512))
    	eq(size_of(pieces.TopLeftCorner), '8x8')
    	eq(T.around(pieces.TopLeftCorner, owner):match('^%-?%d+,%-?%d+'), '-2,2', 'its corner 2 outside the frame')
    	eq(T.around(pieces.TopEdge, owner):match('^%-?%d+,%-?%d+'), '6,2', 'the top edge from the corner')
    	eq(T.around(pieces.BottomRightCorner, owner):match('%-?%d+,%-?%d+$'), '2,-2')
    	check(not pieces.TopEdge:GetHorizTile(), 'stretched, not tiled')
    	eq(pieces.LeftEdge:GetDrawLayer(), 'BORDER')
    	eq(T.inset(owner.backdrop), 2); eq(T.fill(owner.backdrop), backdropcolor)
    end
    ```
    `coords(texture)` gives its `GetTexCoord()` as left, right, top, bottom, 6 decimals; `px(l, r, t, b, w, h)` formats `l/w, r/w, t/h, b/h` the same way. Each file pixel is the member's left or top plus the rectangle's (Forever's target member starts at 201, 87; retail's at 1, 229; Forever's player at 605, 1; retail's at 1, 87).
  - `'under Blizzard member is the Background fill, inset 0, with no art'`: `T.art(owner.backdrop) == ''`, `T.inset == 0`, `T.fill` the Background.
  - `'a cut with no atlas file hides its pieces'`: with `GetAtlasInfo` returning an info without `file` (a test-only entry in a stand-in table for the case, not a change to the stub's data), drawing errors nothing and no piece shows.
  - `"a frame's own border color tints the box's pieces"`: `st:SetBorderColor(owner.backdrop, 1, 0, 0)` tints each piece; with no color, white again.
- [ ] **Step 2: Run them; they fail** (`unitframe` is not a kind).
- [ ] **Step 3: Implement** the kinds, the art table, `ThemeArt.Cut`, the cut layout (a branch in `ThemeArt.Paint` for an art with `pieces` and `size`) and `SetBorder`'s cut branch. Mark both atlases with `Atlas()`, so `st:ThemeAtlases()` lists them, and add them to `atlases.lua` for both clients.
- [ ] **Step 4: Run all tests.** `tests/run`: passes (the kind-name lists updated in the two tests above).
- [ ] **Step 5: Commit.** `core: the unitframe and member kinds: under Blizzard the bronze box, and a bare fill`

### Task 13: Unit frames draw as `unitframe` or `member`, one box per edge

**Files:**
- Modify: `SaftUI-Unitframes/unitframes.lua`: `UF.UnitKind`; the frame's draw.
- Modify: `SaftUI-Unitframes/updaters.lua`: `UF:ElementKind`, `UF.FillsFrame`, `UF:ElementTheme`, `UF:UpdateElement`.
- Modify: `SaftUI-Unitframes/groups.lua`: `StylePreviewFrame`'s draw.
- Create: `tests/unitframes/blizzard_look_test.lua`.
- Modify: `tests/unitframes/theme_test.lua`: the drawn kinds (`'bar'` → `'unitframe'`, and `'member'` for party and raid previews).

**Interfaces:**
- Consumes: Task 12's kinds.
- Produces:
  - `UF.UnitKind(unit) -> 'member' | 'unitframe'`: `member` for `party`, `raid10`, `raid40`.
  - `UF:ElementKind(element) -> kind`: a status bar takes its unit frame's `UF.UnitKind(frame.base_unit)`; anything else `'control'`.
  - `UF.FillsFrame(config) -> boolean`: relative width and height both 0, no `position.element` and no `position.frame`, `point == rel_point`, and both offsets `tonumber(...) == 0`.
  - `UF:ElementTheme(element, config) -> theme, background`: `'none', background` when the element's kind is `unitframe`, it fills its frame (`UF.FillsFrame`), and both its own and its frame's Theme resolve to Blizzard (`st:IsBlizzardLook`). Else the config's own pair.

- [ ] **Step 1: Write the failing tests** in the new `tests/unitframes/blizzard_look_test.lua`. Its `world(client)`: `reset_world()`, `stub.interface`, `constants.lua`, then `theme_test.lua`'s prelude and `make_unit_frame` (copied), with `T.watch()` for `drawn`.
  - `'every unit frame and bar draws as unitframe, a party or raid member as member; under Thick and Thin as a bar'`:
    ```lua
    local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'AdditionalPower', 'Castbar' })
    local party = make_unit_frame('M', 'party', { 'Health', 'Power' })
    UF:UpdateUnitFrame(player); UF:UpdateUnitFrame(party)
    eq(drawn(player), 'none,theme,unitframe'); eq(drawn(player.Health), 'theme,theme,unitframe')
    eq(drawn(player.Castbar), 'theme,theme,unitframe'); eq(drawn(party.Health), 'theme,theme,member')
    eq(looks(player.Health), looks_as_bar) -- Thick: inset 2, the same fill, edge and outer lines as a bar
    ```
    `looks` is `theme_test.lua`'s; `looks_as_bar` is what it reads off a frame of the same size drawn with the same pair as `'bar'`.
  - `'one box per edge'` (Review Focus 4), under Blizzard with the player's frame Theme set to `'theme'`:
    - health filling the frame is drawn `'none,theme,unitframe'` and the frame's box shows (`T.art(player.backdrop)` names eight pieces);
    - health at relative height −4: both boxes;
    - health offset y −1: both;
    - health anchored to `element = 'Power'`: both;
    - the frame `'thick'` and health `'theme'`: both, one Thick and one Blizzard;
    - Thick SaftUI: health drawn with its own pair, as today.
  - `"the player's separate power bar has its own box; a castbar set to Thin keeps Thin's line"`: Power `'theme,theme,unitframe'` with eight pieces. The target's castbar at its `'thin'` default draws `'thin,solid,unitframe'`: inset 1, a line, no pieces.
  - `'a party preview draws as members, a boss preview as a unit frame'` (`UF:UpdateGroupPreview`).
  - `theme_test.lua`'s drawn-kind assertions change to the new kinds (lines 230–235, 293, 417–418, 460 and the preview test).
- [ ] **Step 2: Run them; they fail** (drawn `bar`).
- [ ] **Step 3: Implement.**
  - `UF:UpdateUnitFrame` draws `st:SetBackdrop(frame, theme, background, UF.UnitKind(frame.base_unit))`.
  - `UF:UpdateElement` takes `local theme, background = UF:ElementTheme(element, config)` first (a call in the middle of an argument list would give only its first return), then draws `st:SetBackdrop(element, theme, background, UF:ElementKind(element))`.
  - `StylePreviewFrame` draws with `UF.UnitKind(frame.base_unit)`.
  - The local `ElementKind` goes; the scan in `tests/core/theme_kinds_test.lua` still sees four arguments.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `unitframes: frames and bars draw as unitframe, party and raid as member, one box per edge`

### Task 14: The group border

**Files:**
- Modify: `SaftUI-Unitframes/groups.lua`: `UF:GroupBorder`, `UF.GroupBorderShown`, `UF:UpdateGroupBorder`, called from `UF:CreateGroupHeaders` and `UF:UpdateGroupPreview`.
- Modify: `SaftUI-Unitframes/unitframes.lua`: the groups branch of `UF:ApplyConfig` runs `UF:UpdateGroupBorder(unit)` in `xpcall` after the members' update. It isn't protected, so it runs in and out of combat.
- Modify: `SaftUI-Core/themeart.lua`: `ART.groupborder`, `CONTROLS.groupborder`, `ThemeArt.PaintCut(frame, name)`.
- Modify: `tests/wow/atlases.lua`: `options_frame_child` = 28 × 26 on both clients:
  - Forever: file 8086468, coords 901/1024, 929/1024, 1/1024, 27/1024;
  - retail: file 1318750, coords 616/1024, 644/1024, 24/1024, 50/1024.
- Test: `tests/unitframes/blizzard_look_test.lua`.

**Interfaces:**
- Consumes: Task 12's cut layout and `ThemeArt.Cut`; Task 13's `UF.UnitKind`.
- Produces:
  - `ART.groupborder = { layer = 'BORDER', size = 6, offsets = { -2, 2, 2, -3 }, pieces = … }` from `Atlas('options_frame_child')`, the same rectangles on both clients:
    - corners 0–6 × 0–6, 22–28 × 0–6, 0–6 × 20–26, 22–28 × 20–26;
    - edges 6–22 × 0–6 (top), 6–22 × 20–26 (bottom), 0–6 × 6–20 (left), 22–28 × 6–20 (right).
  - `st.ThemeArt.PaintCut(frame, name)`: lays and shows `ART[name]`'s cut on `frame` (pieces in `ThemeArt.Get(frame)`); `ThemeArt.Clear(frame)` hides them.
  - `UF:GroupBorder(owner) -> frame`: made once per owner (a group header or a preview container), kept in a weak table keyed by `owner`. A plain frame of SaftUI's, child of `owner`, at `owner`'s frame level (left as made when that level is secret) so the members (one level up) draw over its inner part. Anchored TOPLEFT `owner` (−2, 2) and BOTTOMRIGHT `owner` (2, −3). Nothing is written onto `owner`.
  - `UF.GroupBorderShown(config) -> boolean`: `st:IsBlizzardLook(config.theme, config.background)`, or, when `config.theme == 'none'`, `st:IsBlizzardLook(config.health.theme, config.health.background)`.
  - `UF:UpdateGroupBorder(group)`: for the group's header and its preview container (each when it exists), `PaintCut(border, 'groupborder')` and show it when `UF.GroupBorderShown`, else `Clear` and hide.

- [ ] **Step 1: Write the failing tests.**
  - `"the group border: options_frame_child cut at 6px around the group header, no middle"`, for each client, with `locked = load_test_file('misc/fixtures/locked_widget.lua')` standing in for the header SaftUI mustn't write onto:
    ```lua
    local header = locked(CreateFrame('Frame', 'SaftUI_Party', UIParent), 'secure group header')
    header:SetPoint('CENTER'); header:SetSize(200, 4 * 34 + 3 * 8)
    UF.groups = { party = header }
    local border = UF:GroupBorder(header)
    st.config.profile.theme.name = 'blizzard'; UF:UpdateGroupBorder('party')
    check(border:IsShown()); eq(T.around(border, header), '-2,2,2,-3')
    local pieces = st.ThemeArt.Get(border).pieces
    eq(count(pieces), 8, 'no middle'); eq(size_of(pieces.TopLeftCorner), '6x6')
    eq(pieces.TopLeftCorner:GetTexture(), client == 'forever' and 8086468 or 1318750)
    eq(coords(pieces.TopLeftCorner), client == 'forever' and px(901, 907, 1, 7, 1024, 1024) or px(616, 622, 24, 30, 1024, 1024))
    eq(border:GetFrameLevel(), header:GetFrameLevel())
    ```
  - `'which Theme turns the group border on'`, under SaftUI's Blizzard:
    - party at its defaults (frame None, health Use SaftUI's theme): shown;
    - the frame `'thick'`: hidden, and a party member's frame draws Thick (`T.inset == 2`, Thick's lines);
    - the frame None and health `'thick'`: hidden, and the member's health draws Thick;
    - frame None and health None: hidden;
    - raid10 at its defaults (frame `'theme'`): shown;
    - SaftUI's Thick: hidden everywhere.
  - `'it follows a member joining in combat, with nothing of SaftUI's running, nothing protected called and nothing written onto the header'`. The header is locked (the fixture) and protected, as a secure group header is:
    ```lua
    local protected = true
    rawset(header, 'IsProtected', function() return protected, protected end)
    stub.in_combat = true
    UF:UpdateGroupBorder('party') -- an update that reaches it in combat touches only SaftUI's border
    eq(#stub.blocked, 0, 'nothing protected called')
    local calls = 0; local real = UF.UpdateGroupBorder
    UF.UpdateGroupBorder = function(...) calls = calls + 1; return real(...) end
    -- The header's own secure layout pass for a fifth member: not addon code, so the game doesn't block it.
    protected = false; header:SetSize(200, 5 * 34 + 4 * 8); protected = true
    eq(T.around(border, header), '-2,2,2,-3', 'the border follows by its anchors'); eq(calls, 0)
    UF.UpdateGroupBorder = real; stub.in_combat = false
    ```
  - `'test mode previews get the same border'`: `UF:SetGroupTestMode('party', true)` under Blizzard shows a border around the preview container; under Thick none.
- [ ] **Step 2: Run them; they fail** (`UF.GroupBorder` is nil).
- [ ] **Step 3: Implement** as the Interfaces say:
  - `UF:CreateGroupHeaders` makes each header's border right after `SpawnHeader` (out of combat);
  - `UF:UpdateGroupPreview` makes and updates the container's;
  - `UF:ApplyConfig`'s loop over a header's children already skips the border (it has no `Health`).
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `unitframes: under Blizzard each party and raid header has Blizzard's raid group border`

### Task 15: Blizzard's bar fills

**Files:**
- Modify: `SaftUI-Unitframes/updaters.lua` (`UF:UpdateStatusBarElement`, `UF.BlizzardFill`).
- Modify: `SaftUI-Core/themeart.lua`: `ART.unitbars`, `CONTROLS.unitbars`.
- Modify: `tests/wow/atlases.lua`, both clients: `RaidFrame-Hp-Fill` = `{ 32, 32, 'hv' }`, `raidframe-hp-bg-white` = `{ 32, 32 }`, `_RaidFrame-Resource-Fill` and `_RaidFrame-Resource-Background` = `{ 16, 6, 'h' }`.
- Modify: `tests/wow/widgets.lua`: `StatusBar.SetStatusBarTexture` with a path or file ID also clears the bar texture's atlas. In game it sets the bar's texture region, which then shows that file and no atlas; today's stub keeps the old atlas.
- Test: `tests/unitframes/blizzard_look_test.lua`.

**Interfaces:**
- Produces:
  - `Control('unitbars') = { health = { fill = 'RaidFrame-Hp-Fill', bg = 'raidframe-hp-bg-white', tileH = true, tileV = true }, power = { fill = '_RaidFrame-Resource-Fill', bg = '_RaidFrame-Resource-Background', tileH = true, tileV = false } }`. Tiling is Blizzard's (`CompactUnitFrame.xml`'s wrap modes).
  - `UF.BlizzardFill(element, config) -> Control('unitbars')[key] | nil`: key `health` for `Health`, `power` for `Power` and `AdditionalPower`. Nil for any other element, when `config.texture` is neither nil nor `'SaftUI Flat'` (the default), or when `st:IsBlizzardLook(config.theme, config.background)` is false.

- [ ] **Step 1: Write the failing tests.**
  - `'under Blizzard health fills with RaidFrame-Hp-Fill over raidframe-hp-bg-white, power with the resource fill, still tinted'`, for each client:
    ```lua
    eq(player.Health:GetStatusBarTexture():GetAtlas(), 'RaidFrame-Hp-Fill')
    check(player.Health:GetStatusBarTexture():GetHorizTile() and player.Health:GetStatusBarTexture():GetVertTile())
    eq(player.Health.bg:GetAtlas(), 'raidframe-hp-bg-white')
    eq(player.Power:GetStatusBarTexture():GetAtlas(), '_RaidFrame-Resource-Fill'); eq(player.Power.bg:GetAtlas(), '_RaidFrame-Resource-Background')
    player.Health:SetStatusBarColor(0.2, 0.4, 0.6) -- as oUF's class color does
    eq(text(player.Health:GetStatusBarColor()), '0.20,0.40,0.60,1.00', 'the class color still tints it')
    ```
    A custom color (`colorCustom`) still lands after an update.
  - `'only the default texture, only its own Blizzard look; Thick puts the flat fill back'`:
    - health with `texture = 'Another'` keeps that texture;
    - the castbar keeps its texture;
    - health with Theme None under SaftUI's Blizzard keeps the flat fill;
    - `'thick'`: every fill back to `st.BLANK_TEX` with no atlas, the bg too.
- [ ] **Step 2: Run them; they fail** (no atlas on the bar texture).
- [ ] **Step 3: Implement.** `UF:UpdateStatusBarElement` asks `UF.BlizzardFill`. With a fill: `element:GetStatusBarTexture():SetAtlas(fill.fill)` and its tiling, and `element.bg:SetAtlas(fill.bg)` with the same tiling. Without: today's `SetStatusBarTexture(st:GetStatusBarTexture(config.texture))`, and `element.bg:SetTexture(st.BLANK_TEX)` with tiling off. The bg's tint and shown state stay as today.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `unitframes: under Blizzard the bars use Blizzard's raid bar fills`

---

## Part C: the micro menu bar

### Task 16: The micro menu bar's art, and atlases one client has

**Files:**
- Modify: `SaftUI-Core/themeart.lua`:
  - `Atlas(name, client)`, and `st:ThemeAtlases()` giving each atlas's clients (the header comment's account of the tables too);
  - `ART.microbar`, `CONTROLS.microbar`;
  - the local `LayBorder` lays a `Center` piece when the border has one; `ThemeArt.LayBorder(pieces, frame, border)` and `ThemeArt.HidePieces(pieces)`.
- Modify: `tests/wow/atlases.lua`: the header's rule (an atlas one client lacks is in the other's table only) and these entries:

  | Atlas | Forever | Retail |
  | ----- | ------- | ------ |
  | `UI-HUD-ActionBar-Frame` | 55 × 55 (its `-c60-2x` member, 110 × 110) | 55 × 55 (`-2x`) |
  | `ui-hud-minimap-header-button` | 152 × 23 (`-c60`) | none |
  | `ui-hud-minimap-addon-indicator` | 23 × 22 (`-c60`) | none |
  | `ui-hud-minimap-tracking-button` | 23 × 23 (`-c60`) | none |
  | `ui-hud-minimap-button-NineSlice-CornerTopLeft`, `-CornerTopRight`, `-CornerBottomLeft`, `-CornerBottomRight` | 6 × 6, 7 × 6, 6 × 7, 7 × 7 | the same |
  | `_ui-hud-minimap-button-NineSlice-EdgeTop`, `_…-EdgeBottom` | 16 × 6, 16 × 7, `'h'` | the same |
  | `!ui-hud-minimap-button-NineSlice-EdgeLeft`, `!…-EdgeRight` | 6 × 16, 7 × 16, `'v'` | the same |
  | `ui-hud-minimap-button-NineSlice-Center` | 16 × 16 | the same |

  From the clients' `UiTextureAtlasMember` tables at the builds the file names (the research's `report-research-micromenu-art.md`); `UI-HUD-ActionBar-IconFrame-Background` is there already.
- Modify: `tests/core/theme_blizzard_test.lua`: `'every atlas the theme names exists on both clients'`.
- Test: `tests/core/theme_blizzard_test.lua`, `tests/core/theme_blizzard_draw_test.lua`.

**Interfaces:**
- Produces:
  - `Atlas(name, client)`: `client` nil for an atlas both clients have, `'forever'` or `'live'` for one only that client has; it marks `ATLASES[name]` `true` or the client.
  - `st:ThemeAtlases() -> { [name] = true | 'forever' | 'live' }`.
  - `Control('microbar')`, by client:
    ```
    forever: { strip = { frame = 'UI-HUD-ActionBar-Frame', background = 'UI-HUD-ActionBar-IconFrame-Background', pad = 4, backgroundInset = 2 },
               header = { atlas = 'ui-hud-minimap-header-button', height = 23 },
               square = { atlas = 'ui-hud-minimap-addon-indicator', width = 23, height = 22 },
               tracking = { atlas = 'ui-hud-minimap-tracking-button', width = 23, height = 23, icon = true } }
    live:    { strip = false, header = { kit = KIT }, square = { kit = KIT }, tracking = { kit = KIT } }
    ```
    `KIT = { layer = 'BACKGROUND', TopLeftCorner = { atlas = 'ui-hud-minimap-button-NineSlice-CornerTopLeft' }, …, Center = { atlas = 'ui-hud-minimap-button-NineSlice-Center' } }`: Blizzard's `UniqueCornersLayout` with the `ui-hud-minimap-button` kit, as retail's minimap header draws it (`Blizzard_Minimap/Mainline/Minimap.xml`, `BorderTop`). The three Camelot atlases are marked `Atlas(name, 'forever')`; the rest `Atlas(name)`. `icon = true`: the art has the item's icon drawn in.
  - `ThemeArt.LayBorder(pieces, frame, border)`: lays `border` (a border table as `Control` gives it) on `frame` as the tooltip border is laid (corners at the frame's corners, edges between them, tiled across or down), and its `Center` when it has one, from the top left corner's BOTTOMRIGHT to the bottom right corner's TOPLEFT (Blizzard's NineSlice default). The textures are `frame`'s, kept by key in the caller's `pieces` table (never `ThemeArt.Get`'s, which a redraw clears), shown and white. `ThemeArt.HidePieces(pieces)` hides them. The tooltip border and the metal have no Center, so they lay as before.

- [ ] **Step 1: Write the failing tests.**
  - `theme_blizzard_test.lua`: `'every atlas the theme names exists on both clients'` becomes `'every atlas the theme names exists on the clients it is for'`, for each client:
    ```lua
    local st = T.client(client)
    local mine, names = st.ThemeArt.Client(), st:ThemeAtlases()
    for name, value in pairs(names) do
    	if value ~= true and value ~= 'forever' and value ~= 'live' then odd[#odd + 1] = name .. ' is marked ' .. tostring(value) end
    	local here = value == true or value == mine
    	if here and not C_Texture.GetAtlasInfo(name) then missing[#missing + 1] = name end
    	if not here and C_Texture.GetAtlasInfo(name) then odd[#odd + 1] = name .. " is marked one client's, but " .. client .. ' has it' end
    end
    -- today's checks: no file or format, at least 100 names, the named ones listed
    eq(names['ui-hud-minimap-header-button'], 'forever', "Forever's Camelot chrome is Forever's only")
    eq(names['ui-hud-minimap-button-NineSlice-Center'], true, 'the minimap button kit is on both')
    ```
  - `"a client's micro bar art names only atlases that client has"`, for each client: every string in `Control('microbar')` (walked) that `st:ThemeAtlases()` names is `true` or this client's; on Forever each item's art has an `atlas` and the strip its two; on retail `strip == false` and each item's art a `kit`.
  - `theme_blizzard_draw_test.lua`, `"ThemeArt.LayBorder lays a kit with its Center on a frame, in the caller's own table"` (retail):
    ```lua
    local owner, pieces = frame(st), {}
    st.ThemeArt.LayBorder(pieces, owner, st.ThemeArt.Control('microbar').header.kit)
    eq(count(pieces), 9)
    eq(pieces.TopLeftCorner:GetAtlas(), 'ui-hud-minimap-button-NineSlice-CornerTopLeft'); eq(size_of(pieces.TopLeftCorner), '6x6')
    eq(T.around(pieces.TopLeftCorner, owner):match('^%-?%d+,%-?%d+'), '0,0', 'at the corner')
    eq(T.around(pieces.Center, owner), '6,-6,-7,7', 'between the corners')
    check(pieces.TopEdge:GetHorizTile() and pieces.LeftEdge:GetVertTile(), 'the edges tiled')
    eq(pieces.Center:GetParent(), owner); eq(st.ThemeArt.Get(owner), nil, "kept in the caller's table")
    st.ThemeArt.HidePieces(pieces); check(not pieces.Center:IsShown())
    ```
    The tooltip border's draw tests stay as they are (eight pieces, no Center).
- [ ] **Step 2: Run them; they fail** (`Control('microbar')` errors: not a control).
- [ ] **Step 3: Implement** as the Interfaces say, and add the entries to `atlases.lua` (Forever's three in its table only).
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `core: the micro menu bar's Blizzard art, and atlases one client has`

### Task 17: The micro menu bar under Blizzard

**Files:**
- Modify: `SaftUI-Minimap/micromenu.lua`: `UpdateBackdrop` draws kind `control`; each item's art (`UpdateArt`); the strip (`UpdateStrip`, at the end of `UpdateButtons`); `SkinTrackingButton`'s options; `MicroMenu:GetItemArt`, `MicroMenu:GetStrip`; the header comment.
- Modify: `SaftUI-Minimap/zonetextbutton.lua`, `clockbutton.lua`, `stats.lua` (latency and FPS): `art = 'header'` in the options they return.
- Modify: `SaftUI-Minimap/microbuttons.lua`: each holder is added with `micro = true`.
- Create: `tests/minimap/blizzard_look_test.lua`.
- Modify: `tests/minimap/theme_test.lua`: `"a micro menu item's panel is a small frame…"` reads `'theme,theme,control'` (Thick's inset, offset and fill unchanged; its name says a control, a small frame under Thick).

**Interfaces:**
- Consumes: Task 16's `Control('microbar')`, `ThemeArt.LayBorder`, `ThemeArt.HidePieces`.
- Produces:
  - `MicroMenu:AddButton(button, options)`: options gain `art` (`'header'`, `'square'` (the default) or `'tracking'`: a key of `Control('microbar')`), `icon` (a texture of SaftUI's on the item, hidden while its art has an icon drawn in) and `micro` (true for a micro button's holder).
  - `MicroMenu:GetItemArt(button) -> texture | nil, pieces | nil`: the item's art texture and its kit pieces (each made the first time it's needed), for tests.
  - `MicroMenu:GetStrip() -> frame | nil, frameTexture, backgroundTexture`: the strip, a frame of SaftUI's, child of `MicroMenu.Container`, made the first time it's shown.

- [ ] **Step 1: Write the failing tests** in the new `tests/minimap/blizzard_look_test.lua`. Its `world(client)`: `T.client(client)`, `drawn = T.watch()`, Blizzard's minimap (`CreateFrame('Frame', 'Minimap', UIParent)`), the minimap's `minimap.lua` and `config.lua`, `apply_defaults()`, `micromenu.lua` and `microbuttons.lua`, with `MM.Container` a frame at UIParent's TOPLEFT as `theme_test.lua` makes it. `theme(name)` sets the profile's theme, runs `st:RedrawThemed()` and `MM:UpdateButtons()`, as a switch runs them; `item(options)` adds a Button of UIParent's with `MM:AddButton`; `panel(button)` is its child the theme drew.
  - `"Forever under Blizzard: the zone, clock, latency and FPS boxes on the header button, the square items on the addon indicator, search on Blizzard's tracking button; Thick puts today's boxes back"`:
    ```lua
    local zone, fps = item({ width = 200, art = 'header' }), item({ width = 48, art = 'header' })
    local square, search = item(), CreateFrame('Button', nil, UIParent)
    local magnifier = search:CreateTexture(); MM:AddButton(search, { art = 'tracking', icon = magnifier })
    MM:SkinBarButton(zone) -- its flat hover
    theme('blizzard')
    local z = MM:GetItemArt(zone)
    eq(z:GetAtlas(), 'ui-hud-minimap-header-button'); eq(T.around(z, zone), '0,-1,0,1', 'its 23 centred on the 25 row, the box wide')
    eq(T.around(MM:GetItemArt(fps), fps), '0,-1,0,1')
    local s = MM:GetItemArt(square); eq(s:GetAtlas(), 'ui-hud-minimap-addon-indicator'); eq(T.around(s, square), '1,-1,-1,2')
    local t = MM:GetItemArt(search); eq(t:GetAtlas(), 'ui-hud-minimap-tracking-button'); eq(T.around(t, search), '1,-1,-1,1')
    check(not magnifier:IsShown(), "SaftUI's magnifier hidden: Blizzard's is drawn in")
    eq(drawn(panel(zone)), 'theme,theme,control'); eq(panel(zone).backdropInfo, nil, 'no flat box, no line')
    eq(z:GetParent(), panel(zone), "on the item's panel, under the item's own art")
    eq(zone:GetHighlightTexture():GetDrawLayer(), 'HIGHLIGHT', 'the flat hover stays')
    theme('thick')
    check(not z:IsShown() and not s:IsShown() and not t:IsShown()); check(magnifier:IsShown())
    eq(T.inset(panel(zone)), 2); eq(T.offset(panel(zone), 'TOPLEFT'), '-2.00,2.00', "today's small frame")
    ```
  - `'retail under Blizzard: every box takes the grey minimap button kit, and there is no strip'`: the zone, a square and search each show nine kit pieces on their panel (`select(2, MM:GetItemArt(x))`), the top left corner at the box's corner and the Center between the corners; the magnifier stays (the kit draws no icon); a run of `micro` holders has no strip (`MM:GetStrip()` nil or hidden); under Thick no piece shows.
  - `'the micro buttons stand on one bronze strip from the first shown holder to the last, and it follows Blizzard showing and hiding them'` (Review Focus 5), Forever:
    ```lua
    local before = item({ width = 48, art = 'header' })
    local a, b, c = item({ width = 20, theme = 'none', micro = true }), item({ width = 20, theme = 'none', micro = true }), item({ width = 20, theme = 'none', micro = true })
    local mail = item()
    theme('blizzard')
    local strip, frameArt, background = MM:GetStrip()
    check(strip:IsShown()); eq(frameArt:GetAtlas(), 'UI-HUD-ActionBar-Frame'); eq(T.around(frameArt, strip), '0,0,0,0')
    eq(background:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Background'); eq(T.around(background, strip), '2,-2,-2,2')
    eq(T.around(strip, a):match('^%-?%d+,%-?%d+'), '-4,4'); eq(T.around(strip, c):match('%-?%d+,%-?%d+$'), '4,-4')
    eq(strip:GetHeight(), 33); check(strip:GetLeft() > before:GetRight(), 'clear of the box before it')
    c:Hide(); eq(strip:GetRight(), b:GetRight() + 4, 'it ends at the last one shown')
    mail:Hide(); check(not MM:GetItemArt(mail):IsVisible(), "an item's art goes with it")
    stub.in_combat = true; c:Show(); eq(strip:GetRight(), c:GetRight() + 4); eq(#stub.blocked, 0); stub.in_combat = false
    a:Hide(); b:Hide(); c:Hide(); check(not strip:IsShown(), 'none shown: no strip')
    a:Show(); theme('thick'); check(not strip:IsShown())
    ```
  - `"nothing of Blizzard's micro menu is shown, moved or written onto"`: with `theme_test.lua`'s `micro_button` (copied) on a `MicroMenu` that has `BorderArt` and `BackgroundArt` textures and is locked after it's set up, `MM:SkinBlizzardMicroMenu()` then `theme('blizzard')`: both textures at alpha 0 with their points unchanged, the strip around the button's holder, the strip's parent `MM.Container`, and no error from the locked frames.
- [ ] **Step 2: Run them; they fail** (`MM.GetItemArt` is nil).
- [ ] **Step 3: Implement.**
  - `UpdateBackdrop` draws and insets the item's panel as kind `control` (`st:SetTemplate(…, 'control')`, `st:ThemeInset(…, 'control')`), then `UpdateArt(button, item)`.
  - `UpdateArt`: under `st:IsBlizzardLook(item.theme or 'theme', item.background or 'theme')`, `local art = st.ThemeArt.Control('microbar')[item.art or 'square']`. An `atlas` art: one ARTWORK texture of the panel's (kept in the item's entry), `SetAtlas(art.atlas)`; with `width`, `width × height` at TOPLEFT panel (`floor((w − width) / 2)`, `−floor((25 − height) / 2)`); without, from TOPLEFT (0, −`floor((25 − height) / 2)`) to TOPRIGHT, `height` tall. A `kit` art: `ThemeArt.LayBorder(entry.pieces, panel, art.kit)`. The other of the two is hidden. Under another look both are hidden. `item.icon` shows unless the art drawn has `icon`.
  - `UpdateStrip`, after the items are placed: under SaftUI's Blizzard look with a `strip` (Forever), and with a shown `micro` item, the strip shows, its frame texture (BORDER) over it all and its background (BACKGROUND) `backgroundInset` in; it's anchored through `st:SafeReposition(strip, 'MicroMenu_strip', fn)` from the first shown micro item's TOPLEFT (−pad, pad) to the last's BOTTOMRIGHT (pad, −pad). Otherwise it hides. Its frame level: the Container's, so it lies under the holders and under Blizzard's buttons (level 51 in `MicroMenu`). Blizzard's `BorderArt` and `BackgroundArt` stay as `SkinBlizzardMicroMenu` leaves them.
  - `SkinTrackingButton` returns its button with `{ art = 'tracking', icon = <SaftUI's magnifier> }` (no icon on live, where Blizzard's own shows). The zone, clock, latency and FPS builders add `art = 'header'`; `SkinBlizzardMicroMenu` adds each holder with `micro = true`.
- [ ] **Step 4: Run all tests.** `tests/run`: passes.
- [ ] **Step 5: Commit.** `minimap: under Blizzard the micro menu bar stands on Blizzard's micro menu and minimap art`

---

### Task 18: Docs, followups, README and the in-game list

**Files:**
- Modify: `.agents/edit-mode.md` (`last_updated: 2026-11-11`):
  - the options window: the two layouts, the title bar, the inner frame, the footer across the window, banners and gold names, the page divider, no section rules under Blizzard; growing taller (the grip and the edge, `OW.MaxHeight`, `OW.WindowHeight`, the height in `optionsWindow`, one render on release for a fill page);
  - the widgets: the check box art size, the WowStyle2 face and compact faces, steppers only where the choices fit (`W.StepperRoom`, `w:StepsFit`), the c-bg list, slider arrows, the Blizzard bar and `OB.ScrollBar`'s new arguments;
  - the Categories list's look and the editor's fixed footer.
- Modify: `.agents/architecture.md`: Themes (the thirteen kinds, `unitframe` and `member`, the cut art, `ThemeArt.Cut` and `PaintCut`, `ThemeArt.LayBorder` with a Center, `Atlas(name, client)` and what `st:ThemeAtlases()` gives, `Control('resizegrip')` and `Control('microbar')`), Unit frames (`UF.UnitKind`, one box per edge, the group border, the fills) and the micro menu bar (its items' panels drawn as `control` with the bar's own art, the strip).
- Modify: `.agents/clients.md`, the Blizzard theme art bullet: most atlases exist on both clients; Forever's Camelot minimap art (`ui-hud-minimap-header-button`, `-addon-indicator`, `-tracking-button`) is Forever's only, marked `Atlas(name, 'forever')` and named only in Forever's art, and the atlas test checks each atlas on its own clients.
- Modify: `.agents/taint.md`:
  - rule 6 or 12: the group border, a frame of SaftUI's that is a child of a secure header and anchored to it, following it in combat with no SaftUI code;
  - the micro menu's strip and art are SaftUI's own frames and textures; Blizzard's `BorderArt` and `BackgroundArt` stay hidden;
  - the skinning helpers' line: `st:SkinIcon` keeps its crop and its hooked flag in weak tables of `skinning.lua`'s since 28c0448, so it writes nothing onto the icon but its hook.
- Modify: `.agents/testing.md`: the three new test files (`tests/core/options_settings_test.lua`, `tests/unitframes/blizzard_look_test.lua`, `tests/minimap/blizzard_look_test.lua`) and what they cover; the stubs' new behaviour (atlas files and coordinates, hit rects, a bar texture's atlas, an atlas in one client's table only); the atlas test's rule for one client's atlases.
- Modify: `README.md`:
  - the `/sui` bullet: drag its bottom edge, or the grip at its bottom right corner, to make it taller; it remembers its height;
  - the Theme bullet: under Blizzard `/sui` looks like Blizzard's Settings window, unit frames wear Blizzard's unit frame box, party and raid frames Blizzard's raid group border, with Blizzard's bar fills, and the micro menu bar Blizzard's micro menu and minimap art (on retail, Blizzard's grey minimap buttons);
  - the Bags → Categories bullet: the items it catches now and the items pinned to it stay in a footer at the editor's bottom while the rest scrolls.
- Modify: `docs/followups.md`, each change with its ToC line:
  - a new entry for the in-game list below ("Blizzard theme round 2: in-game checks");
  - a new entry for a border per real raid group (the spec's "a followup if wanted": a secure header per group);
  - revise "Blizzard theme: the bags' rule editor and Categories list keep the options window's own look": the fields and the list now follow; the boxes, the "whole word" check, the NOT toggles and the AND/OR badges still don't;
  - revise "Categories tab: the scrolled editor's two gaps": with the footer, Caught now stays in view under the rule; a lit block can still be out of the editor's view when the rule is taller than it;
  - revise "st:Kill and st:SkinIcon still write onto Blizzard pieces": `st:SkinIcon` no longer writes its crop onto the icon (28c0448), only its hook; `st:Kill` still writes.

- [ ] **Step 1:** Make the doc edits above. Every doc whose `covers:` matches a changed file is reviewed (`git diff --name-only 8cc0287...HEAD`), and its `last_updated` bumped where it changed.
- [ ] **Step 2:** Run the `agents-doc-parity-check` and `readme-freshness-check` skills; fix what they find.
- [ ] **Step 3:** `tests/run`: passes.
- [ ] **Step 4: Commit.** `docs: the Blizzard theme round 2 in the agent docs, README and followups`

## In-game check list (for the user, after Task 18)

Each under the Blizzard theme on both clients, then Thick to check nothing moved.

1. **`/sui`'s frame:**
   - the metal with "SaftUI Options" centred in its title bar, and the close button in the socket;
   - the inner frame's drawn divider on the sidebar's right edge (242), its vignette not over text;
   - the footer's buttons clear of the metal's bottom;
   - the window (1110 × 728) fits your screen inside the edge margin, and dragged to the screen's top, the metal's top (16 above the window, `st.ThemeArt.MetalAbove()`, outside the rect the margin holds) isn't cut off.
2. **The sidebar:**
   - FRAMES, COMBAT and INFO on the banners, their art hanging below without covering the first entries' text;
   - gold names, white for the open page and under the mouse.
3. **Nested scroll clipping:**
   - on the Categories tab, the editor's bar inside the body's clip;
   - the rule editor's dropdown faces not cut at the editor's edges;
   - a dropdown in the body's right column with its glow whole at the body's right edge.
4. **The dropdown faces:** a select whose choices fit has the steppers and the face at 109; one with a long choice (a Theme select's "Use SaftUI's theme") has the face at the full 170 and no steppers; the compact faces in the rule editor and the position block. The c-button art's rounded ends stretch cleanly at each width, and the list's c-bg sits right under the button.
5. **Check boxes at 30 × 29:** lined up with their labels; the 23 × 22 rows in a multiselect and a check list.
6. **Slider arrows:** inside the slider, each a step.
7. **Scroll bars:** dragging the thumb, the arrows, the track and the wheel; the narrow bars in the sidebar, the Categories list and a long dropdown list.
8. **Growing taller, in each theme:**
   - the bottom edge and the grip both drag; the top stays put; it stops at 700 (728 under Blizzard) and with its bottom at the screen edge margin;
   - the height comes back after a `/reload`, and after a theme switch;
   - under Blizzard the inner frame stretched taller (its vignette and rim) looks right, and Blizzard's grip in the metal's bottom right corner shows, takes the mouse and stays clear of Close;
   - the Categories tab redraws once when the mouse is let go, its list and editor taller.
9. **The Categories footer:** Caught now above Pinned items at the editor's bottom, the rule above in view at once; a category with many items: the footer at half the pane, scrolling on its own; its top edge (a line, or Blizzard's divider); a pin's X and an item's tooltip as before.
10. **The bronze box seams on Forever and retail:**
    - at the player's 301 × 34, a 120-wide pet or target of target, and the player's 299 × 20 power bar;
    - corners meet the edges with no step or gap;
    - Forever shows bronze (its Camelot member's file), retail grey and gold.
11. **The group border** around party and raid10 and raid40 (57 × 30, 3 apart). It follows someone joining or leaving in combat. Members show no border of their own.
12. **Bar fills:** class colors on `RaidFrame-Hp-Fill` read as class colors, not muddy; the resource fill on power.
13. **The micro menu bar, Forever:**
    - the bronze strip behind the micro buttons, 33 tall on the 25 row, 4 above and below the boxes; the engine's slicing of `UI-HUD-ActionBar-Frame` on SaftUI's own texture: a crisp rim, chamfered ends not squashed (its slice margins, 16 and 20, are taken to be the `-2x` member's texels, 8 and 10 UI units; if the ends look squeezed, cut the pieces by texture coordinates instead, as the spec allows);
    - the strip under Blizzard's buttons, their own bronze squares on top, and its background 2 inside its rim;
    - the header button's art at 200, 60, 48 and 48 wide (at 48 its two ends leave 4 between them if the margins are halved), the addon indicator and the tracking button centred, the flat hover over each;
    - in a vehicle and a pet battle, where Blizzard moves its buttons out of the bar but the holders stay: whether an empty strip there looks wrong.
14. **The micro menu bar, retail:** the grey minimap button kit on every box and no strip; the instance difficulty button's own purple fill covers its box (left as it is).

## Spec conflicts and gaps, and how this plan handles them

- **The search glass:** the spec's "Today" says the glass is drawn 24 wide. The code (`W.LookSearch`) already draws it 10 × 10 at LEFT 6, which is Blizzard's LEFT 1 measured from where SaftUI's border starts. Task 3 only adds Blizzard's y of −1.
- **One kind for every unit frame draw:** the spec has no look for a party or raid member under Blizzard (the Background fill, no border) that the bronze-box kind can give. Task 12 adds a second kind, `member` (a bar under Thick and Thin); Task 13 uses it for party, raid10 and raid40.
- **The bronze rectangles:** BottomLeft moves from the spec's 50–58 to 48–56, and BottomRight and the bottom edge from 52–60 to 51–59, so each piece's outer two pixels are the outline and the rim on every side, and BottomLeft meets BottomRight as the spec asked. Retail's are measured from retail's members (Task 12's table). All are starting values for the in-game pass.
- **The sidebar width:** the spec estimated 225–235. With the body kept at 774 and Blizzard's right-hand room (the glow, the minimal scroll bar), the divider rule gives 242 in a 1110 window.
- **The dropdown's glow vs compact rows:** the rule editor's fields and the position block's dropdown have 4 to their neighbours, so their face's outset is 4, not 7. Their hover arrow is left off, as it would hang into the next row.
- **"In place of the tab row's 1px line":** the subtab row's line takes the divider too. "No rules between sections" applies to every options body (window, dialog, the Categories editor). The vertical dividers between halves stay.
- **`W.Prompt` and `W.Confirm` never scroll** (they size to their text), so the spec's "if they scroll" adds nothing there.
- **An existing test contradicts the spec:** `"the /sui window's close button keeps its place under Blizzard"` (`theme_blizzard_windows_test.lua`) asserted round one's behaviour. Task 2 rewrites it to the socket.
- **Steppers where the choices fit:** the spec's "about 83" is this plan's `W.StepperRoom()`, 83 exactly. A choice is measured in the font the face draws it in, so a font list's entry is measured in its own face. The followup this plan used to plan for cut labels is dropped: a select whose choices don't fit has no steppers, and its 144 for text (170 less the two insets) cuts only what today's dropdown cuts.
- **"The most is the screen's height less the screen edge margin":** read as less the margin at the top and at the bottom, so the window fits inside the margin. A drag also stops where the window's bottom meets the margin, so it never pushes the window up; to grow further, move it up first.
- **The grip's look:** the spec names none. Under Blizzard it's Blizzard's own resize grip (`PanelResizeButtonTemplate`'s three files, on both clients); under Thick and Thin SaftUI's corner arrow, as `st:EnableResizing` draws it.
- **"Resizing redraws only what the height changes":** a page with no fill row isn't drawn again at all (its scroll, bars and nav re-clamp); a fill page's fill row is drawn once, when the mouse is let go, by the window's existing render scheduling, which waits while the drag is held.
- **A new saved value:** the plan's earlier "no new saved key" gives way to the spec's saved height: one optional field in SaftUI's global settings, never in a profile, so no profile migrates.
- **The footer's split:** `INV:CategoryEditorOptions` keeps every row (its tests and order unchanged); the tab moves Caught now and Pinned items into the footer, Caught now first, as the spec orders them.
- **"Dragging an item from the bags onto the Pinned items strip … work as today":** today nothing takes an item dropped on the Pinned items strip (pins come from the slot menu, and a dragged item drops onto the rule editor's "Item is one of" block, which stays in the editor). The plan keeps both as they are and adds no drop.
- **"A strip with no items shows its title and its empty line as today":** today Pinned items is hidden when there are none, and Caught now shows its title with nothing under it. The footer keeps both.
- **The micro menu's background:** Blizzard's `BackgroundArt` reaches 13 and 14 past the frame on the sides, which on SaftUI's bar would lie over the box beside the strip (8 away). It sits 2 inside the strip instead.
- **No new kind for the micro menu:** the items' panels draw as `control`, which Thick and Thin draw exactly as `small` and Blizzard leaves clear, as the micro buttons' own panels already do; the art is the bar's own. This keeps Part C off `theme.lua` and the kind lists Part B changes.
- **Retail's kit has a Center:** Blizzard's `UniqueCornersLayout` draws one, which `LayBorder` didn't lay; Task 16 teaches it, and the tooltip border and the metal, which have none, lay as before.
- **The engine's slicing:** Part C sets each atlas whole on a texture of SaftUI's and relies on the atlas's own slice data, as Blizzard's XML does. If it misbehaves in game, the spec's fallback (cutting by texture coordinates) needs each atlas's file and coordinates (Task 12's format) and is a follow-on change.
- **`st:SkinIcon`'s state (28c0448):** nothing in the plan reads or writes `__stTexCoord`. The bronze box, the group border and the Categories icons set texture coordinates on SaftUI's own textures directly. Task 18 corrects `.agents/taint.md` and the followup that still describe the old fields.
