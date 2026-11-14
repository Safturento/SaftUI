# /sui Window Sizes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/sui` gets three sizes and a sidebar that collapses. The sizes are full, half (the page in one column) and a 42 tall bar at the window's corner. The sidebar can be shown or collapsed at full and at half. The arrows beside the close X step between the sizes. The sidebar's toggle sits in the sidebar's foot, and in the footer's left while the sidebar is collapsed. With it collapsed, Search, Edit mode and Keybind mode become icon buttons in the footer, and the page title opens the page list. Reload UI moves beside Close. The size and the sidebar's state are remembered account-wide. The unit frames' profile control leaves the footer for the Unit dropdown's line. At half, the bags' Categories tab puts its list in a menu on a button.

**Architecture:**
- **One frame, one body, two values.** The window keeps one frame and one page body. Its state is `S.size` (`'full'`, `'half'` or `'mini'`) and `S.sidebar` (a boolean). Both are read from and written to `st.config.global.optionsWindow`, beside the place and height it holds today.
- **Widths are pure functions.** Every width comes from the layout (`OW.LAYOUT`, which gains `halfBody`) and that state, through pure functions in `optionslayout.lua` that the tests call.
- **Anchored by the top right corner.** The window is placed and saved by its top right corner, so a size change moves nothing at its right or top. `Relayout` lays the window out for the look, the size and the sidebar together, and runs whenever any of them changes.
- **Half is the same body, narrower.** At half the page is the same `OB.New` body, given a narrower width (`body:SetWidth`) and one more size mapping (`OB.HalfSize`, each row one size larger), through the `sizeOf` that `OB.LayoutRows` already takes.
- **The bar is the window.** The mini bar is the window's own frame with its parts hidden.
- **Where the code goes.** A new file, `optionssizes.lua`, holds the header's arrows, the size changes and the bar. `optionsnav.lua` gains the sidebar toggle and the things that move out of the sidebar when it collapses.
- **Outside `/sui`**, only these change: edit mode's mover click, `Config:AddCommand` (it gains an icon), the unit frames' page, the bags' Categories tab, and Blizzard's art data.

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0 (its account-wide `global`); SaftUI's options kit (`st.OptionsWidgets` `W`, `st.OptionsBody` `OB`, `st.OptionsModel` `OM`, `st.OptionsWindow` `OW` with its shared `OW.S`); Lucide icons (lucide-static 0.460.0, made with `tools/lucide-to-tga.cjs`); tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-13-saftui-options-window-sizes-design.md`. Its last section, "Settled with the owner after the first draft" (points 1 to 9), overrides anything earlier that it contradicts:
- Settled 2 and 4 replace "What collapsing hides" and Call 1.
- Settled 5 replaces the footer's second line for a page's control ("The footer", Call 7).
- Settled 9 replaces "A row too wide for one column" and Call 6. The controller's call is kept: at full the list stays beside the editor.
- Settled 3 and 6 add the accent to the name.
- Settled 1, 7 and 8 confirm the arrows, Call 2 and Call 3.

The looks are in `.superpowers/brainstorm/46409-1794604463/content/`: `window-and-editmode-v4.html` part 3 (W1 to W5), `window-collapsed-v1.html` (choice F for the footer, choice A for the name) and `bags-categories-half-v1.html` (choice B). Where a mockup and the spec differ, the spec wins.

**Assumed state.** This plan runs on the integration branch after two others have merged:
- **(a) `fb-kit2`.** A pick's group may carry `pickerControl`. `OM.BuildView` hands it on as `view.picker.control`, `OM.Search` finds its options on the pick's path, and `optionswindow.lua`'s `DrawPickerControl` draws its buttons 12 right of the picker into `F.pickerWidgets`. Copy from is in every unit's `pickerControl`, and `UF.SetUpPlatePage` sets the plates' to nil. The colour swatch is a field.
- **(b) Tasks 1 to 3 of `docs/superpowers/plans/2026-11-13-saftui-edit-mode-bar.md`.**
  - `optionscontrols.lua` exists, with `W.Button`, `W.IconButton(parent, icon, tip)`, `W.SetOn`, `W.SetEnabled`, `W.SetCompact`, `W.LookControl`, `W.ShowTip`, `W.HideTip` and `W.SelectFace`. `S.Button` is `W.Button`.
  - `st.icons` has `search`, `settings` and the bar's other icons.
  - `OW:GetFooter`, `OW:SetFooterInset`, `footerInset` and `EditMode/footer.lua` are gone. The signature is now `OW.FooterPlace(regionWidth, labelWidth, widgetsWidth) -> x, labelShown`.
  - `/sui`'s footer holds Reload UI, the status line from the region's left, the page's footer control and Close.
  - `S.UpdateEditModeButton` uses `W.SetOn`.

  Nothing from that plan's Tasks 4 to 8 is needed. Its Task 7 edits `SaftUI-Unitframes/config/config.lua` (Copy from as one history step) and `config/profiles.lua` (clearing the history on a profile switch). If it lands first, this plan's Task 7 keeps both: it reuses `UF.GenerateProfileConfigGroup().args.current` as it is.

## How the tasks are cut

| # | Task | Needs | Owner can try in game |
| --- | --- | --- | --- |
| 1 | Icons, the window's numbers, its saved corner | — | `/sui` reopens where it was left; growing taller keeps the top |
| 2 | The half body | — | nothing visible (stub tests only) |
| 3 | Full and half: the header's arrows; Reload UI beside Close | 1, 2 | Shrink to half and grow back, under both looks |
| 4 | The mini bar | 3 | Shrink to a bar; drag it; grow back |
| 5 | The sidebar toggle | 3, 4 | Collapse and show the sidebar at full and half |
| 6 | With the sidebar collapsed: icons in the footer, the page list on the title | 5 | Search, Edit mode, Keybind mode and pages without the sidebar |
| 7 | The unit frames' profile control on the Unit dropdown's line | 3 | Unit, Copy from, Profile, Manage on one line (two at half) |
| 8 | The bags' Categories tab at half: the list in a menu | 3, 4 | The menu, dragging in it, previous and next |
| 9 | Blizzard's art for the size arrows; every state checked | 3 to 8 | the red expand and condense buttons under Blizzard |

**Side by side.** Tasks 1 and 2 share no code file:
- Task 1 owns `constants.lua`, the new TGAs, `optionslayout.lua`, `optionswindow.lua` and `optionsresize.lua`.
- Task 2 owns `optionsbody.lua`.

Both update `.agents/edit-mode.md` and `.agents/testing.md`. In `testing.md` the `tests/core/` row is one line, so that merge needs a hand: keep both sides (`.agents/workflow.md`). Tasks 3 to 9 run one after another in the order above. Each edits a file its neighbour also edits (`optionswindow.lua`, `optionssizes.lua`, `optionsnav.lua`, `tests/core/options_sizes_test.lua`, the same docs).

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder may change.
- **Whole pixels.** A size read back from the game carries float noise. Round it (`floor(x + 0.5)`, or `OB.WholeHeight` for a height a body reads back); never `ceil` it. Place frames by their top left (or, for the window, its top right corner) on whole offsets. Every width and height the window takes is even, because the small dialog and the confirm sit on its centre (`W.PlaceCentred`). Every new layout gets a `tests/lib/pixels.lua` check (`P.off(root)` empty, with `stub.size_noise = 2 ^ -14`) under Thick and Thin and under Blizzard on both clients.
- **Icons.**
  - Wherever an icon fits, it is Lucide's, registered in `st.icons` and made with `tools/lucide-to-tga.cjs` at the pinned 0.460.0. The tool fetches each name at that version and errors on a 404, so a name that fails isn't Lucide's there: the funnel is `filter`.
  - Draw an icon at twice its glyph (a 10 px chevron at 20, an 8 px one at 16, a 12 px panel at 16), centred with an even margin so its edges are whole.
  - Every icon-only control has a tooltip, through `W.ShowTip`, with a white title and lines in Text > Normal. A reason a control is disabled is a red line.
  - A disabled control keeps the mouse, so its tooltip can say why. It is alpha 0.4, and its click does nothing (`W.SetEnabled`).
- **Motion.** The game calls `OnEnter` and `OnLeave` with a second argument, `motion`. Never bind a function with an optional second parameter directly as a script; wrap it as `function(self) ... end`. Tests fire hover scripts with `true`.
- **Resets** stay per setting. Nothing here adds a page or section Reset.
- **Both looks, both clients.** Every task says how each new piece draws under Blizzard, and is checked on Forever (16001) and retail (120000). Each new state exists under Blizzard too.
- **Blizzard frames.** The window changes only SaftUI's own frames. It never writes a field onto a Blizzard frame, and nothing it does is secure. The one touch is a native post-hook, `ColorPickerFrame:HookScript('OnShow' | 'OnHide')`, that only reads `IsShown` (`.agents/taint.md` rules 1 and 2).
- **Combat.** `/sui` and everything of it closes in combat and refuses to open there: the bar too, and the Categories menu. That is the existing `Config:PLAYER_REGEN_DISABLED` and `OW:Open`.
- **`OW.S` state.** State in `OW.S` that is replaced as it changes is read and written as `S.name`, never kept in a local. This plan adds `S.size`, `S.sidebar`, `S.bodyWidth`, `S.corner` and `S.keepRow`; keep the load order rule in `optionslayout.lua`'s header.
- **No build step.** A new file is listed in `SaftUI-Core/Config/load.xml` and in the shell's `options_window_files()`, which `tests/lib/harness_self_test.lua` checks against `load.xml`.
- **Commits** are lowercase `module: imperative summary`. Stage by explicit path, never `git add -A`. End each with the session's `Co-Authored-By` line. Keep the user's account and character names out of everything.
- **Docs.** Each task updates the docs its change makes wrong: the `.agents/*.md` whose `covers:` list its files, file headers, `README.md`, and the design system under `docs/design-system/` where a component it documents changes. It hands back an in-game checklist, then runs the `agents-doc-parity-check` and `readme-freshness-check` skills (AGENTS.md).
- **Tests.**
  - Each task ends green on `tests/run -j2`. Run single files while working (`tests/run tests/<area>/<file>`).
  - Keep each file's line endings.
  - An earlier test's assertion is changed only where this work changes the behaviour it pins, and the report lists each one with why.
  - `H.close_all()` (`tests/core/options_window_helpers.lua`) also clears `size` and `sidebar` from `st.config.global.optionsWindow`, so no test's size leaks into the next. Task 1 makes that change.

## Review Focus

1. **A saved place from before this work, or one edited by hand.**
   - An older save: `{ point = 'CENTER', x, y, height }` with no `size`.
   - Bad values: `size = 'mini'`, `'huge'` or `7`; `sidebar = 0` or `'no'`; a `point` that isn't one of the nine.

   The window opens at full with the sidebar, at the spot the old centre put it, and converts once to `TOPRIGHT`, keeping the height. It never writes `size` or `sidebar` until the player clicks. A saved `'mini'` opens at half.
   Tests: Task 1 (the conversion, and `OW.SavedState` on bad values) and Task 3 (opening at a saved half).
2. **A page opened from outside while the bar shows.**
   - `/sui` typed.
   - `/sui` with a path (`st.Config:Open('Loot')`).
   - A click on an unselected mover (`EM:Select`, then `EM:ShowSettings`).
   - A click on the selected mover (the "leave the user on whatever section" branch in `mover.lua`).
   - A bag's Edit category (`INV:EditCategory`).
   - `/sui kb` (keybind mode closes `/sui` a frame later).

   Each grows the bar to half on that page with the sidebar as it was, except keybind mode, which closes it. The Categories tab opens in its menu layout with the category named in the button.
   Tests: Task 4 (`Open`, both mover clicks, keybind mode) and Task 8 (`EditCategory` from the bar).
3. **A search with the sidebar collapsed.**
   - A results page is on screen when the sidebar collapses.
   - A result is clicked while it's collapsed.
   - A result is in an item's menu at W4, where the menu hangs past the window's left.
   - A search is typed in the footer's search box.
   - The window shrinks to the bar mid-search.

   The results stay; the box loses the keyboard. A click opens the page, ends the search and keeps the sidebar collapsed. The menu opens inside the screen margin. Showing the sidebar shows the box's text. The bar shows "Search" and the text, and growing back shows the results at the scroll they had.
   Tests: Task 5 (collapsing mid-search), Task 6 (the footer box, a result's click, a menu result at W4) and Task 4 (the bar).
4. **A drag in the Categories menu when the menu goes away under it.** Esc on the menu mid-drag, combat closing the window mid-drag, and a bag update arriving mid-drag. The drag ends with no move: the order is unchanged, the ghost and the drop line are hidden, and no render is held. Reopened at half, the menu is closed.
   Tests: Task 8.
5. **A screen too small, or a corner near an edge.**
   - On a 1024 wide screen (Thick: `OW.MaxWidth` 984), W1's 1040 doesn't fit. A saved full opens at half and the save stays full. Grow is disabled, saying why. With the sidebar collapsed, full (832) is allowed, and showing the sidebar there is disabled, saying why.
   - A corner where full's left edge would pass the screen margin: Grow, then Shrink, leaves the window's anchor and the saved corner exactly as they were.
   - A bar dragged into the bottom margin grows back with its anchor unchanged.

   Tests: Task 3 (the narrow screen, the corner), Task 5 (the sidebar on a narrow screen) and Task 4 (the bar low on the screen).

## Rulings on the spec

Each ruling is a call the spec leaves open or the code forces. The tasks assume them, and the report lists them for the owner.

1. **Button sizes.**
   - The header's arrows (and the bar's grow) are the close X's size, `st.CLOSE_X_BUTTON_SIZE[1]` (24, so they follow decision 19 if the close X changes), with chevrons at 20.
   - Every other new icon button is `W.IconButton`'s 26 with a 16 icon: the sidebar toggle, and the footer's Search, Edit mode and command buttons, which sit beside the 26 tall Reload UI and Close.
   - The Categories tab's previous and next buttons are 24 with 16 chevrons, to match the 24 tall face beside them.
   - `W.IconButton` gains optional `size` and `iconSize` arguments, and its icon moves 1 down while pressed if it doesn't already.
2. **The corner.**
   - The window is anchored `TOPRIGHT` on UIParent's `TOPRIGHT` at `S.corner`.
   - `S.corner` comes from the save, or, with none, centres the full window with the sidebar (`OW.CentredCorner`).
   - Only a drag saves a new corner, read from where the window shows. A size change, the sidebar or the clamp never moves it.
   - An older save by another point is placed as saved on the first open (at the full width with the sidebar, the only width an older version saved), then rewritten as `TOPRIGHT` from where it shows, keeping its height.
3. **What is saved:** `size = 'half'` or nil (full), and `sidebar = false` or nil (shown). Shrinking to the bar saves `'half'`. `OW.SavedState` reads `'half'` and `'mini'` as half, anything else as full, and only `false` as a collapsed sidebar.
4. **A screen too narrow.**
   - A state whose width passes `OW.MaxWidth(L)` isn't entered: the screen less the margin each side (0 below 0), less the metal's reach left and right under Blizzard, made even.
   - On open, a saved state that doesn't fit falls back to half, keeping the sidebar's state. The save is untouched.
   - Grow at half is disabled with the red line "The screen is too narrow for the full window."
   - At full with the sidebar collapsed, the toggle is disabled with "The screen is too narrow for the sidebar at full size. Shrink to half first."
   - A screen that changes while the window is open changes nothing until the next click or open.
5. **Transitional:** at half the shrink arrow is hidden until Task 4 lands, so the window never offers a size it hasn't got.
6. **The title and the description at half.**
   - The title is as wide as the room before the header's arrows: it ends 8 short of the leftmost under Thick and Thin (724 at full, 308 at half), and is `S.bodyWidth - 40` under Blizzard (734 and 328), whose arrows sit on the title bar.
   - A title wider than its room is drawn in the brand font (26).
   - The description wraps at every size, as wide as the body. The first tab line starts at `TABS_TOP` (87), or 14 under the description's last line when that ends lower. A one-line description ends at 73, so nothing moves today.
7. **The status line** wraps to at most two lines in whatever room the footer's region leaves, and is cut past that. At W4 that room is about 65 wide: the narrowest, and an in-game check.
8. **The footer field** stays in the kit, unused once Task 7 moves the profile control. There is no second footer line. A footer control the region can't hold is hidden by `PlaceFooter`'s existing guard.
9. **Search with the sidebar collapsed** (choice F doesn't say). The Search icon opens the sidebar's own search box (`F.search`, moved into `F.searchPop`) in a small panel 6 above the icon, with the keyboard in the box. The panel closes when the box loses the keyboard (Enter, a click away, Esc, which clears the search as today), and the search stays. The icon is "on" (`W.SetOn`) while a search is on.
10. **Commands.** `Config:AddCommand(command, label, func, icon)` gains an optional icon. Keybind mode passes `st.icons.keyboard`. In the collapsed footer, a command without an icon is a `W.Button` with its label.
11. **The page list** is the kit's select list (`W.OpenList`) on the title. It gains caption entries (the sidebar's groups: Text > Grey, no hover, no click) and disabled entries (alpha 0.4, no pick). It shows up to 12 rows and scrolls past that. The title's arrow is `chevronDown` at 16 (an 8 px chevron, by the icon rule; the mockup draws 18), 8 after the title's text.
12. **The profile control.**
    - Its order on the picker's line is Unit [dropdown], Copy from, Profile [dropdown], Manage.
    - A `pickerControl` option that isn't a button is drawn after its name, `LABEL_GAP` (10) apart, as the picker is. The profile select's name is "Profile", short enough that its piece fits the 368 Blizzard half body.
    - The line's pieces wrap when one would pass the body's width.
    - Nameplate settings are in the unit frame profile, so the plates' pages get Profile and Manage, without Copy from.
13. **The Categories tab.**
    - **When.** The tab uses its menu layout whenever its width is under 774 (`EDITOR_X + EDITOR_WIDTH`). At full it is as today.
    - **The button.** A 260 wide `W.SelectFace` holding the `list` icon, the category's name and its place ("3 of 31", counting every row of the list).
    - **Previous and next.** Two 24 square buttons, 6 apart, disabled at their ends ("This is the first category.", "This is the last category."), not wrapping round.
    - **The menu.** 234 wide (the list's 210, its bar's room and 8 padding each side), up to 14 rows, scrolling past that. Its caption reads "Categories: drag to reorder", avoiding the mockup's middle dot, which SaftUI's fonts may not have.
    - **When it closes.** It closes on a pick, + New category, a click outside, Esc, the window closing or leaving half, and `INV:EditCategory`. It stays open through a drop, Reset all and a bag update.
14. **Size buttons and the colour picker.** While Blizzard's colour picker is open, the size buttons, the bar's grow and the sidebar toggle are disabled, with the red line "Close the color picker first." The window learns of the picker through the post-hook in the Global Constraints, and their clicks also refuse while `ColorPickerFrame:IsShown()`.
15. **Scroll between full and half.** The first row in view stays first in view, by its path (`OW.FirstInView`, `OW.OffsetFor`). Half to the bar and back, and the sidebar both ways, keep the exact offset, because the body's width doesn't change.
16. **The guard:** a size button ignores clicks for `OW.SIZE_GUARD` (0.3 seconds) after the size last changed.
17. **Blizzard.**
    - The inner frame is cut at its divider into two textures (`OW.InnerCuts`, `ThemeArt.Cut`), the list part over the sidebar and the settings part over the main column.
    - The size arrows and the toggle wear Lucide icons on Blizzard's panel button (`W.LookControl`) until Task 9, which gives the arrows Blizzard's red expand and condense art where the client has it.
    - The bar is drawn as kind `panel`, with Blizzard's red close button inside it.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/constants.lua`, `SaftUI-Core/Media/Textures/lucide-*.tga` (7 new) | the new icons | 1 |
| `SaftUI-Core/Config/optionslayout.lua` | `halfBody`; the pure width, state, corner, scroll, cut, bar, flow and page-list functions | 1, 3, 4, 6, 7 |
| `SaftUI-Core/Config/optionswindow.lua` | the corner, `Relayout` per state, the main column following the body's width, the footer, the inner frame's parts, `Draw` at each size, the picker line's flow | 1, 3, 4, 5, 6, 7 |
| `SaftUI-Core/Config/optionsresize.lua` | growing taller by the top; nothing at the bar | 1, 4 |
| `SaftUI-Core/Config/optionsbody.lua` | `OB.HalfSize`, `body:SetWidth`, the half metrics, the right-aligned group's rule, the `mini` font | 2, 4 |
| `SaftUI-Core/Config/optionssizes.lua` (new, after `optionsresize.lua`) | the header's arrows, `OW:SetWindowSize`, `OW:Grow`, `OW:Shrink`, the guard, the bar, the Blizzard size art | 3, 4, 9 |
| `SaftUI-Core/Config/optionscontrols.lua` | `W.IconButton`'s `size` and `iconSize` | 3 |
| `SaftUI-Core/Config/optionsnav.lua` | tabs at the body's width; the sidebar toggle; the footer's tools; the search panel; the title's page list | 3, 5, 6 |
| `SaftUI-Core/Config/optionslist.lua` | caption and disabled entries in `W.OpenList` | 6 |
| `SaftUI-Core/Config/config.lua`, `SaftUI-ActionBars/keybindmode.lua` | `AddCommand`'s icon | 6 |
| `SaftUI-Core/EditMode/mover.lua` | the selected mover's click counts the bar as closed | 4 |
| `SaftUI-Core/Config/general.lua`, `Media/fonts.lua`, `Media/colors.lua` | "Reload UI, bottom right" | 3 |
| `SaftUI-Unitframes/config/profiles.lua`, `config/config.lua`, `nameplates/options.lua` | the profile control on the picker's line | 7 |
| `SaftUI-Bags/categoriestab.lua` | the menu layout at half | 8 |
| `SaftUI-Core/themeart.lua`, `themeart_data.lua`, `tests/wow/atlases.lua` | `sizebutton` art; `Options_InnerFrame`'s file and coordinates | 3, 9 |
| `tests/lib/shell.lua`, `tests/wow/widgets.lua` | the new file in `options_window_files()`; `FontString.SetMaxLines`/`GetMaxLines` | 3 |

---

### Task 1: Icons, the window's numbers, its saved corner

**Files:**
- Create the seven TGAs under `SaftUI-Core/Media/Textures/`: `lucide-chevron-left.tga`, `lucide-chevron-right.tga`, `lucide-panel-left-open.tga`, `lucide-panel-left-close.tga`, `lucide-move.tga`, `lucide-keyboard.tga` and `lucide-list.tga`. Make them with `NODE_PATH=/tmp/lucide-tool/node_modules node tools/lucide-to-tga.cjs chevron-left chevron-right panel-left-open panel-left-close move keyboard list` (the tool's header says how to install it).
- Modify: `SaftUI-Core/constants.lua` (`st.icons`).
- Modify: `SaftUI-Core/Config/optionslayout.lua`: `halfBody` in both layouts and in the header comment's field list; the functions under Interfaces.
- Modify: `SaftUI-Core/Config/optionswindow.lua`:
  - `SavedPosition`, `RestorePosition` and `SavePosition` work by the corner.
  - `S.corner` and `S.SaveWindow`.
  - `Build` anchors by `TOPRIGHT`.
  - The header comment's saved-place lines.
- Modify: `SaftUI-Core/Config/optionsresize.lua`: `StartResize` and `UpdateResize` set the height only, because the top is the anchor; `S.sizing` loses `x` and `y`.
- Test: create `tests/core/options_sizes_test.lua`, on `options_window_helpers.lua`'s world with `local P = load_test_file('lib/pixels.lua')`.
- Modify tests:
  - `tests/core/icons_test.lua` (`NAMES` gains the seven).
  - `tests/core/options_frame_test.lua`: the position case becomes the corner's.
  - `tests/core/options_resize_test.lua`: its first case also checks that the anchor stays `TOPRIGHT` at the same offsets. Its `CENTER` saves stay, now covering the conversion.
  - `tests/core/options_window_helpers.lua`: `close_all` clears `size` and `sidebar`.
- Docs:
  - `.agents/edit-mode.md`: the Header bullet (`{ point = 'TOPRIGHT', x, y, height, size, sidebar }`, the conversion) and Growing taller (anchored by the top, no recentring).
  - `.agents/architecture.md`: the "Textures and icons" bullet, and the account-wide saved values, which gain the size and the sidebar.
  - `.agents/testing.md`.
  - `docs/design-system/components/Icons/README.md` (the seven icons and what will use them).

**Interfaces:**
- Produces:
  - `st.icons`: `chevronLeft`, `chevronRight`, `panelLeftOpen`, `panelLeftClose`, `move`, `keyboard` and `list`, each `st:TexturePath('lucide-<name>.tga')`.
  - `OW.LAYOUT.own.halfBody = 388` and `OW.LAYOUT.blizzard.halfBody = 368`.
  - `OW.MINI_HEIGHT = 42` and `OW.MINI_MAX = 400`.
  - `OW.WindowWidth(L, size, sidebar) -> width` for `'full'` and `'half'`: `L.width`, less `L.sideWidth` when `sidebar` is false, less `OB.WIDTH - L.halfBody` at half.
  - `OW.MainLeft(L, sidebar) -> x`: `L.mainLeft`, or `L.sideX` with the sidebar collapsed (2 under Thick and Thin, 17 under Blizzard).
  - `OW.BodyWidth(L, size) -> width`: `OB.WIDTH` at full, `L.halfBody` at half and at the bar.
  - `OW.NextSize(size, step) -> size | nil`: `step` 1 shrinks (full, half, mini) and -1 grows; nil past either end.
  - `OW.SavedState() -> size, sidebar`, as Ruling 3 says.
  - `OW.MaxWidth(L) -> width` and `OW.Fits(L, size, sidebar) -> boolean`, as Ruling 4 says.
  - `OW.CentredCorner(screenWidth, screenHeight, width, height) -> x, y`: `-floor((screenWidth - width) / 2)` and `-floor((screenHeight - height) / 2)`.
  - `S.corner = { x, y }`, as Ruling 2 says.
  - `S.SaveWindow(fields)`: sets `fields`' keys in `st.config.global.optionsWindow`, making the table if there is none and keeping its other keys. `SavePosition` and `StopResize` go through it, so a move keeps the height, size and sidebar, and a resize keeps the rest.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_sizes_test.lua`

```lua
test('OW.WindowWidth, OW.MainLeft and OW.BodyWidth: each state of each layout, every width even', function()
	local own, blizzard = OW.LAYOUT.own, OW.LAYOUT.blizzard
	local function widths(L)
		return ('%d %d %d %d'):format(OW.WindowWidth(L, 'full', true), OW.WindowWidth(L, 'full', false),
			OW.WindowWidth(L, 'half', true), OW.WindowWidth(L, 'half', false))
	end
	eq(widths(own), '1040 832 654 446', 'Thick and Thin: W1 to W4')
	eq(widths(blizzard), '1110 868 704 462', 'Blizzard: W1 to W4')
	eq(OW.MainLeft(own, true) .. ' ' .. OW.MainLeft(own, false), '210 2', 'the main column moves by whole numbers')
	eq(OW.MainLeft(blizzard, true) .. ' ' .. OW.MainLeft(blizzard, false), '259 17')
	eq(OW.BodyWidth(own, 'full') .. ' ' .. OW.BodyWidth(own, 'half') .. ' ' .. OW.BodyWidth(blizzard, 'half'), '774 388 368')
	-- the main column (width - MainLeft - mainRight): 828 at W1 and W2, 442 at W3 and W4; Blizzard 834 and 428
end)

test('OW.NextSize steps full, half, mini and back, and stops at each end', function()
	-- ('full', 1) 'half'; ('half', 1) 'mini'; ('mini', 1) nil; ('mini', -1) 'half'; ('half', -1) 'full'; ('full', -1) nil
end)

test('OW.SavedState reads an older save, bad values and a saved bar safely', function()
	-- nil -> 'full', true; { size = 'half' } -> 'half', true; { size = 'mini' } -> 'half', true (a bar comes back as half)
	-- { size = 'huge' } and { size = 7 } -> 'full'; { sidebar = false } -> 'full', false; { sidebar = 0 }, { sidebar = 'no' } -> true
	-- { point = 'CENTER', x = 1, y = 2, height = 760 } -> 'full', true
end)

test('OW.MaxWidth and OW.Fits: the screen less the margin, and the metal under Blizzard', function()
	-- stub.screen_width = 1024: OW.MaxWidth(own) == 984; Fits(own, 'full', true) false; Fits(own, 'full', false) true;
	-- Fits(own, 'half', true) true; Blizzard: 1024 - 40 - 8 - the metal's right reach, made even;
	-- clamp_inset -10 counts as 0, as in OW.MaxHeight; stub.screen_width = 1920 after
end)

test('OW.CentredCorner: centred by its top right corner, in whole units', function()
	eq(table.concat({ OW.CentredCorner(1920, 1080, 1040, 700) }, ','), '-440,-190')
	eq(table.concat({ OW.CentredCorner(1365, 767, 1040, 700) }, ','), '-162,-33', 'an odd screen rounds down')
end)

test('the window is anchored and saved by its top right corner, read from where it shows', function()
	st.config.global.optionsWindow = nil
	st.Config:Open()
	local w = frames().window
	local point, relative, relPoint, x, y = w:GetPoint(1)
	eq(table.concat({ point, relPoint, x, y }, ' '), 'TOPRIGHT TOPRIGHT -440 -190', 'centred, by its corner')
	eq(relative, UIParent)
	eq(st.config.global.optionsWindow, nil, 'a window never moved saves nothing')
	stub.fire_script(frames().header, 'OnDragStart')
	w:ClearAllPoints(); w:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 300, -100) -- as StopMovingOrSizing leaves it
	stub.fire_script(frames().header, 'OnDragStop')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'TOPRIGHT -580 -100', 'saved from where it shows')
	-- saved.size = 'half'; saved.sidebar = false; another drag: both kept, and the height
	-- reopened: the same corner; at 1365x767 with stub.size_noise = 2 ^ -14: #P.off(w) == 0
end)

test('an older save by the centre restores where it was, and is converted to the corner on the first open', function()
	st.config.global.optionsWindow = { point = 'CENTER', x = -200, y = 50, height = 760 }
	st.Config:Open()
	local cx, cy = frames().window:GetCenter()
	eq((cx - 960) .. ',' .. (cy - 540), '-200,50', 'where the older version left it')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y .. ' ' .. saved.height, 'TOPRIGHT -640 -110 760', 'converted, the height kept')
	-- { point = 'BOTTOMLEFT', ... } converts the same way; { point = 'NOWHERE' } opens centred and writes nothing
end)
```

In `options_resize_test.lua`'s first case: after each resize, `w:GetPoint(1)` is still `'TOPRIGHT'` at the offsets it had (no re-anchoring), and `w:GetTop()` stays.

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_sizes_test.lua`
Expected: FAIL: `OW.WindowWidth` is nil.

- [ ] **Step 3: Make the icons.** Check that every name fetches at 0.460.0. Register them, and add them to `icons_test.lua`'s `NAMES`.

- [ ] **Step 4: Implement** the layout numbers, the functions, the corner and the resize by the top, as the Interfaces say.

- [ ] **Step 5: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS. The position case in `options_frame_test.lua` is changed to the corner. List it.

- [ ] **Step 6: Docs** as listed under Files.

- [ ] **Step 7: Commit**

```bash
git add SaftUI-Core/constants.lua SaftUI-Core/Media/Textures/lucide-chevron-left.tga SaftUI-Core/Media/Textures/lucide-chevron-right.tga SaftUI-Core/Media/Textures/lucide-panel-left-open.tga SaftUI-Core/Media/Textures/lucide-panel-left-close.tga SaftUI-Core/Media/Textures/lucide-move.tga SaftUI-Core/Media/Textures/lucide-keyboard.tga SaftUI-Core/Media/Textures/lucide-list.tga SaftUI-Core/Config/optionslayout.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionsresize.lua tests/core/options_sizes_test.lua tests/core/icons_test.lua tests/core/options_frame_test.lua tests/core/options_resize_test.lua tests/core/options_window_helpers.lua .agents/edit-mode.md .agents/architecture.md .agents/testing.md docs/design-system/components/Icons/README.md
git commit -m "core: anchor /sui by its top right corner and name its sizes"
```

**In-game checks:**
- `/sui` opens where it was left last time, on both clients.
- Drag it, `/reload`: it is where you left it.
- Grow it taller by the grip: its top doesn't move, and its edges stay crisp.

---

### Task 2: The half body

**Files:**
- Modify: `SaftUI-Core/Config/optionsbody.lua`:
  - `OB.HalfSize`, `Body:SetWidth`, `body.half`;
  - `Body:UseMetrics` at half;
  - `Body:Draw`'s and `Body:DrawResults`' size mappings;
  - `OB.LayoutRows`' right-aligned group;
  - the header comment's API list.
- Test: create `tests/core/options_body_half_test.lua` on `options_window_helpers.lua`'s world, with a local `draw_body(width, options, half)` as `options_body_test.lua` has it, calling `body:SetWidth(width, half)` before it draws. Add one case to `tests/core/options_share_test.lua`.
- Docs: `.agents/edit-mode.md` (the Body bullet: the half mapping, `SetWidth`, the half metrics, the button rule), `.agents/testing.md`.

**Interfaces:**
- Produces:
  - `OB.HalfSize(row) -> size`: `'small'` gives `'normal'`; `'normal'` and none give `'wide'`; `'wide'` stays.
  - `body:SetWidth(width, half)`:
    - sets `body.width` and `body.half`, and the width of every pooled section title and note, used or free;
    - takes effect at the next `Draw`;
    - at half, `UseMetrics` puts the columns `metrics.quarterGap` apart in place of `columnGap`, so the halves are 194 and 194 at 388 under `OB.PANELED`, and 172 and 172, 24 apart, at 368 under `OB.FLAT`.
  - `Body:Draw` passes `Wide` for a `oneColumn` body, else `OB.HalfSize` while `body.half`.
  - `Body:DrawResults` lays each result out `'wide'` at half (one to a line), and `'normal'` otherwise, as today.
  - `OB.LayoutRows`: a `'right'` group joins the line of the wide row before it only when that row's own `row.size` is `'wide'` (and `SharesLine`). A row made wide by `sizeOf` keeps the buttons on a line of their own. With no `sizeOf`, nothing changes: today's only right group (Copy from's All and None) follows a row that is wide of its own.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_body_half_test.lua`

```lua
test('OB.HalfSize reads each row one size larger; a wide row stays wide', function()
	eq(OB.HalfSize({ size = 'small' }), 'normal', 'a quarter takes half of the narrow body')
	eq(OB.HalfSize({ size = 'normal' }), 'wide', 'a half takes the whole line')
	eq(OB.HalfSize({}), 'wide', 'no size is normal')
	eq(OB.HalfSize({ size = 'wide' }), 'wide', 'a wide row stays')
end)

test('at 388 under Thick and Thin: halves stack in their order, quarters pair up, each as wide as today', function()
	H.theme('thick')
	local body, cells = draw_body(388, {
		{ 'enable', 'toggle', 'Enable' }, { 'theme', 'select', 'Theme' }, { 'width', 'range', 'Width' }, { 'height', 'range', 'Height' },
		{ 'bg', 'select', 'Background' }, { 'tex', 'select', 'Texture' },
		{ 'q1', 'toggle', 'Hotkey', 'small' }, { 'q2', 'toggle', 'Stack count', 'small' },
		{ 'q3', 'toggle', 'Macro name', 'small' }, { 'q4', 'toggle', 'Cooldown', 'small' },
	}, true)
	-- enable, theme, width, height, bg and tex: one to a line, in that order, each cell x 14 and 360 wide (today 359)
	-- q1 at 14 and q2 at 208, each 166 wide (today 165), on one line; q3 and q4 on the next
	-- a divider at x 194 on each line of two quarters, none on a line of one row; a hairline at the top of every line but the first
	-- body:SetWidth(774, false) and Draw: two columns again, as options_body_test.lua pins them
end)

test('at 368 under Blizzard: the two columns 24 apart, each as wide as a quarter is today', function()
	-- H.theme('blizzard'): body:SlotRect(1) is 0, 172; body:SlotRect(2) is 196, 172; a mapped half's cell is 0, 368
end)

test("a small input keeps its 60 box; a section's titles and notes take the narrower width", function()
	-- an input sized 'small' at half: widget.frame:GetWidth() == 60
	-- a titled section with a note, drawn at 774, then SetWidth(388, true): the title's and note's widths 388, pooled ones too
end)

test('buttons aligned right join a row that is wide of its own, never one the half made wide', function()
	local placed = OB.LayoutRows({ { key = 'sel' }, { key = 'a', align = 'right' }, { key = 'b', align = 'right' } }, nil, OB.HalfSize)
	-- sel on y 0, a and b on y 34, its line
	placed = OB.LayoutRows({ { key = 'w', size = 'wide' }, { key = 'a', align = 'right' } }, nil, OB.HalfSize)
	-- a on w's line: placed[1].buttons is a's group
	-- with no sizeOf: unchanged from options_body_test.lua's cases
end)

test('search results are one to a line at half', function()
	-- body:SetWidth(388, true); DrawResults with three results: each cell col 'full', y 0, 38 and 76 (Thick)
end)

test('a half body sits on whole pixels under every look, with the read-back noise', function()
	-- for look in thick, thin, blizzard: stub.size_noise = 2 ^ -14; draw the first case's rows; #P.off(content) == 0; stub.size_noise = 0
end)
```

In `options_share_test.lua`: its member page's body drawn at half has the own mark at `markX` in from each slot, a row's hover line ending at its cell's right, and a section title's hover line whole.

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_body_half_test.lua`
Expected: FAIL: `OB.HalfSize` is nil.

- [ ] **Step 3: Implement** as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS. No earlier assertion changes.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionsbody.lua tests/core/options_body_half_test.lua tests/core/options_share_test.lua .agents/edit-mode.md .agents/testing.md
git commit -m "core: lay a page out in one column when its body is half wide"
```

**In-game checks:** nothing changes yet. On both clients, `/sui` draws every page as before, and search results look as before.

---

### Task 3: Full and half: the header's arrows; Reload UI beside Close

**Files:**
- Create: `SaftUI-Core/Config/optionssizes.lua`. List it in `SaftUI-Core/Config/load.xml` after `optionsresize.lua`, and in `options_window_files()` (`tests/lib/shell.lua`) in the same place.
- Modify: `SaftUI-Core/Config/optionswindow.lua`:
  - `Relayout()` reads `S.blizzard`, `S.size` and `S.sidebar`. `Draw` runs it when their key differs from `laidOut`.
  - The main column follows `S.bodyWidth`: `F.content`, the title's width and font, `F.desc`'s width and wrap, and the first tab line's top.
  - `pageBody:SetWidth(S.bodyWidth, S.size ~= 'full')`, and `S.keepRow` applied after the draw.
  - In the footer, Reload UI goes left of Close, 12 apart; the region runs from `PAD` (`L.footerX` under Blizzard) to 12 before Reload UI; the status line wraps to at most two lines.
  - `F.close` gets its tooltip.
  - `F.inner` becomes `F.innerList` and `F.innerSettings`.
  - `OW:Open` sets `S.size` and `S.sidebar` from `OW.SavedState` (fitted, Ruling 4) when the window was hidden.
- Modify: `SaftUI-Core/Config/optionsnav.lua`: `DrawTabRow` wraps at `S.bodyWidth`.
- Modify: `SaftUI-Core/Config/optionslayout.lua`: `OW.FirstInView`, `OW.OffsetFor`, `OW.InnerCuts`, `OW.SIZE_GUARD`.
- Modify: `SaftUI-Core/Config/optionscontrols.lua`: `W.IconButton`'s `size` and `iconSize`.
- Modify: `SaftUI-Core/Config/general.lua` (`ICONS_NOTE`), `SaftUI-Core/Media/fonts.lua` (`TEXT_FONTS_NOTE`) and `SaftUI-Core/Media/colors.lua` (`RELOAD_NOTE`): "Reload UI, bottom right".
- Modify: `tests/wow/atlases.lua`: `Options_InnerFrame` on both clients gains its `file` and `coords`, from the same tables (wago.tools, as its header and `.agents/clients.md` say). `tests/wow/widgets.lua`: `FontString.SetMaxLines` and `GetMaxLines`.
- Test: add cases to `tests/core/options_sizes_test.lua` and `tests/core/options_settings_test.lua` (Blizzard, both clients). Add `W.IconButton`'s sizes to `tests/core/options_controls_test.lua`.
- Modify tests:
  - `tests/core/options_frame_test.lua`: the region case, now Reload UI beside Close.
  - `tests/core/options_settings_test.lua`: the inner frame case's `F.inner` becomes the two parts; Reload UI is left of Close, not 16 in.
  - `tests/core/options_open_test.lua`: its layout list's footer.
  - `tests/core/colors_test.lua:52`, `general_tab_test.lua:22`, `fonts_tab_test.lua:17`: the notes.
- Docs:
  - `.agents/edit-mode.md`:
    - the window paragraph: seven files with `optionssizes.lua`; full and half; `S.size` and `S.bodyWidth` in the list of shared state;
    - the Header, Tabs, Body and Footer bullets;
    - the Blizzard inner frame's two parts.
  - `.agents/architecture.md` (`Media/fonts.lua`'s note).
  - `.agents/testing.md`.
  - `README.md`: line 21, the window shrinks to half and grows, and Reload UI is at the bottom right; lines 22 and 24, "bottom right".
  - `docs/design-system/README.md` (the Reload note example).
  - The design system's `components/OptionsWindow/README.md` (Anatomy: the header's arrows, the footer, half; States), `components/CloseButton/README.md` (the window's X has its tooltip) and `components/Button/README.md` (`W.IconButton`'s sizes).

**Interfaces:**
- Consumes:
  - Task 1: `OW.WindowWidth`, `OW.MainLeft`, `OW.BodyWidth`, `OW.NextSize`, `OW.SavedState`, `OW.Fits`, `OW.MaxWidth`, `S.corner`, `S.SaveWindow`, `st.icons.chevronLeft` and `chevronRight`.
  - Task 2: `body:SetWidth`.
  - The edit mode bar's Task 2: `W.IconButton`, `W.SetEnabled`, `W.ShowTip`, `W.LookControl`.
- Produces:
  - `W.IconButton(parent, icon, tip, size, iconSize) -> button`: `size` (26) and `iconSize` (16) are optional, and `(size - iconSize) / 2` must be whole. The icon moves 1 down while pressed.
  - `OW:GetWindowSize() -> 'full' | 'half' | 'mini'`.
  - `OW:SetWindowSize(size) -> boolean`:
    - It is false in combat, while `ColorPickerFrame:IsShown()`, for a size that doesn't `OW.Fits`, and for no change. In this task it takes `'full'` and `'half'`.
    - It saves `size = 'half'` or nil through `S.SaveWindow`, and sets `S.size`.
    - Between full and half it sets `S.keepRow = { OW.FirstInView(OW.GetDrawnRows(), S.scrollOffset) }`.
    - Then `OW:Render()`: one render, keeping the page, tab, pick and search.
    - It stamps `S.sizedAt = GetTime()`.
  - `OW:Grow() -> boolean` and `OW:Shrink() -> boolean`: `OW:SetWindowSize(OW.NextSize(S.size, -1 or 1))`. They do nothing while `GetTime() - S.sizedAt < OW.SIZE_GUARD` (0.3).
  - `F.grow` and `F.shrink`: `W.IconButton(window, st.icons.chevronLeft or chevronRight, tip, st.CLOSE_X_BUTTON_SIZE[1], 20)` (`S.BuildSizeButtons(window)`, placed by `S.PlaceSizeButtons()` in `Relayout`).
    - Under Thick and Thin they sit right to left from the close X, 6 apart, top-aligned with it.
    - Under Blizzard they sit on the title bar left of the socket, 6 apart, centred on the close button: on Forever's 28 tall close, 2 lower than its top; on retail's 24, level with it.
    - Shrink shows at full, grow and shrink at half (shrink hidden at half until Task 4).
    - Under Blizzard they get `W.LookControl` (Ruling 17).
  - Tooltips, through `W.ShowTip` under the button:
    - shrink at full: "Shrink to half", "The page in one column. The window's right edge stays.";
    - grow at half: "Grow to full", "The page in two columns.";
    - shrink at half (Task 4): "Shrink to a bar", "A small bar, to see the whole UI. It keeps the page.".
    - Disabled lines are red, as Rulings 4 and 14 say.
  - `S.UpdateWindowButtons()`: each button's `W.SetEnabled`, by the colour picker and `OW.Fits`. It runs in `Relayout` and from the colour picker's post-hook, set once in `Build`, guarded by `if ColorPickerFrame`.
  - `F.close`'s tooltip, by `HookScript('OnEnter', function(self) ... end)`: "Close", "Closes the options window. Esc does too.".
  - `F.header` stops 18 short of the leftmost header button under Thick and Thin (today's 56 is the close X's 38 plus 18); under Blizzard it stays 56.
  - `OW.FirstInView(cells, offset) -> path, delta`: the first cell with `y + height > offset`, giving its `row.path` and `offset - y`. `OW.OffsetFor(cells, path, delta) -> offset | nil`: the cell with that path's `max(0, y + delta)`.
  - `OW.InnerCuts(look, height) -> listRect, settingsRect`, each `{ x0, x1, 0, height }`: `{ 0, look.divider }` and `{ look.divider, look.width }`. `height` comes from `C_Texture.GetAtlasInfo(look.inner).height`, never from a frame.
  - `F.innerList` covers the sidebar; `F.innerSettings` runs from the main column's left (`L.innerX + L.sideWidth`) to `L.innerX` short of the window's right. Both come down from `innerTop` to the footer.

- [ ] **Step 1: Write the failing tests**, added to `tests/core/options_sizes_test.lua`

```lua
test('Shrink to half: 386 narrower from the left; the corner, the close X and the shrink arrow stay', function()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames(); local w = F.window
	local right, top, closeLeft, shrinkLeft = w:GetRight(), w:GetTop(), F.close:GetLeft(), F.shrink:GetLeft()
	click(F.shrink)
	eq(OW:GetWindowSize(), 'half', 'half')
	eq(w:GetWidth(), 654, '1040 less 386'); eq(w:GetRight(), right, 'the right edge stays'); eq(w:GetTop(), top, 'and the top')
	eq(F.close:GetLeft(), closeLeft, 'the close X stays'); eq(F.shrink:GetLeft(), shrinkLeft, 'and the shrink arrow')
	check(F.grow:IsShown(), 'grow at half'); eq(F.grow:GetRight(), F.shrink:GetLeft() - 6, '6 left of shrink')
	eq(F.content:GetWidth(), 388, 'the body one column')
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/player/general', 'the page, pick and tab kept')
	eq(st.config.global.optionsWindow.size, 'half', 'remembered')
	stub.time = stub.time + 0.31
	click(F.grow)
	eq(w:GetWidth(), 1040); eq(w:GetRight(), right); eq(st.config.global.optionsWindow.size, nil, 'full saves nil')
end)

test('the arrows: the close X\'s size, chevrons at 20, grey at rest and accent under the mouse, each with its tooltip', function()
	-- F.shrink 24x24, icon st.icons.chevronRight 20x20 centred, vertex color Text > Grey; OnEnter(true): accent, tooltip
	--   owned by it, 'Shrink to half'; OnLeave(true): grey, hidden; F.grow's icon st.icons.chevronLeft, 'Grow to full'
	-- F.close: OnEnter(true) shows 'Close'; F.header:GetRight() == leftmost:GetLeft() - 18 at full and at half
end)

test('a size button ignores clicks for a third of a second after a change', function()
	-- click(F.shrink): half; click(F.grow) at the same stub.time: still half; stub.time + 0.31, click(F.grow): full
end)

test('between full and half the first row in view stays first in view, in one render', function()
	-- a page of 30 toggles (a small module), scrolled so t12 is the first row in view; renders = OW.GetRenderCount()
	-- OW:SetWindowSize('half'): OW.FirstInView(OW.GetDrawnRows(), F.body:GetVerticalScroll()) names t12; renders + 1
	-- and back to full: t12 first again
end)

test('at half the title, the description and the tabs follow the narrow body', function()
	-- the tabs wrap at 388 (each line ends at or before PAD + 388)
	-- a page named with 20 characters: at full in the title font; at half (308 of room) in the brand font
	-- F.desc wraps (CanWordWrap) and is S.bodyWidth wide; with its GetStringHeight reading 45 (a stand-in on the
	--   font string, as a wrapped one reads in game), the first tab line's top is 14 under its bottom; with one line, 87
end)

test('Reload UI sits beside Close at every size; the region from the footer\'s left; the status wraps to two lines', function()
	-- full and half: F.reloadButton:GetRight() == F.closeButton:GetLeft() - 12; F.footerRegion:GetLeft() == F.footer:GetLeft() + 28
	-- F.footerRegion:GetRight() == F.reloadButton:GetLeft() - 12; F.status:CanWordWrap() and F.status:GetMaxLines() == 2
end)

test('opens at the remembered size; one the screen cannot hold opens at half, and Grow says why', function()
	-- saved { size = 'half' }: opens at half
	-- stub.screen_width = 1024, saved size nil: opens at half; the save still has no size; F.grow.disabled; its tooltip's last line
	--   red 'The screen is too narrow for the full window.'; click(F.grow) does nothing
	-- 1920 again, closed and opened: full
end)

test('a size change never moves the corner, even where the full window passes the margin', function()
	-- st.config.global.optionsWindow = { point = 'TOPRIGHT', x = -1300, y = -50, size = 'half' }: open; Grow, then Shrink:
	--   w:GetPoint(1) offsets still -1300, -50 after each; the save's x and y unchanged
end)

test('while the color picker is open the arrows do nothing and say why', function()
	-- ColorPickerFrame:SetupColorPickerAndShow({ ... }): F.shrink.disabled; OnEnter(true): red 'Close the color picker first.'
	-- click: still full; stub.color_picker_cancel(): enabled again
end)

test('whole pixels at full and at half, and the small dialog and an item\'s menu over the half window', function()
	-- for thick and thin, with stub.size_noise = 2 ^ -14: #P.off(frames().window) == 0 at full and at half
	-- at half: OW:OpenDialog over the window: centred (its centre within 1 of the window's), #P.off(dialog frame) == 0
	-- an item's menu opened from a left-column item at half: #P.off(menu frame) == 0, kept in the screen margin
end)
```

In `tests/core/options_settings_test.lua`, for each client:

```lua
test('under Blizzard: the inner frame in two parts, the arrows on the title bar, at full and at half', function()
	-- W1: at(F.innerList) '17,28 242x654', at(F.innerSettings) '259,28 834x654', their texcoords the cuts of
	--   OW.InnerCuts(look, 618); W3: window 704 wide, at(F.innerSettings) '259,28 428x654', the list part as at full
	-- F.shrink 6 left of the close button, centred on it; Close 16 from the bottom right, Reload UI 12 left of it
	-- #P.off(F.window) == 0 at W1 and W3, with stub.size_noise = 2 ^ -14
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_sizes_test.lua tests/core/options_settings_test.lua`
Expected: FAIL: `F.shrink` is nil.

- [ ] **Step 3: Implement** the new file, `Relayout` per state, the main column, the footer, the inner frame's parts, the notes and the stubs' `SetMaxLines`, as the Interfaces say.

- [ ] **Step 4: Update the existing tests** under Files so each keeps its meaning.

- [ ] **Step 5: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 6: Docs** as listed under Files.

- [ ] **Step 7: Commit**

```bash
git add SaftUI-Core/Config/optionssizes.lua SaftUI-Core/Config/load.xml SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionsnav.lua SaftUI-Core/Config/optionslayout.lua SaftUI-Core/Config/optionscontrols.lua SaftUI-Core/Config/general.lua SaftUI-Core/Media/fonts.lua SaftUI-Core/Media/colors.lua tests/wow/atlases.lua tests/wow/widgets.lua tests/lib/shell.lua tests/core/options_sizes_test.lua tests/core/options_settings_test.lua tests/core/options_controls_test.lua tests/core/options_frame_test.lua tests/core/options_open_test.lua tests/core/colors_test.lua tests/core/general_tab_test.lua tests/core/fonts_tab_test.lua .agents/edit-mode.md .agents/architecture.md .agents/testing.md README.md docs/design-system/README.md docs/design-system/components/OptionsWindow/README.md docs/design-system/components/CloseButton/README.md docs/design-system/components/Button/README.md
git commit -m "core: shrink /sui to half and grow it back from its header"
```

**In-game checks:**
- Shrink with the arrow beside the X. The window narrows from its left, and the X and the arrow stay under the mouse.
- Every page reads in one column: Unitframes' General, Action bars' texts (two to a line), a position block, Global Settings' title.
- Grow back: the row you were looking at is still at the top.
- Reload UI is beside Close at both sizes.
- Under Blizzard, on both clients: the inner frame's line sits on the sidebar's edge at both sizes, its right rim still looks right squeezed to half, and the arrows sit on the title bar. If the rim thins too much, note it for a third cut.
- `/reload` at half: it reopens at half.

---

### Task 4: The mini bar

**Files:**
- Modify: `SaftUI-Core/Config/optionssizes.lua`:
  - `OW:SetWindowSize('mini')` and what it closes;
  - the bar: `S.BuildMini(window)` and `S.DrawMini()`;
  - its drag and its click;
  - shrink shown at half.
- Modify: `SaftUI-Core/Config/optionswindow.lua`:
  - `Relayout` at the bar: the parts hidden, kind `panel`, the corner shift;
  - `Draw` at the bar: no page, no sidebar, no `SetScroll`, so `S.scrollOffset` and `S.navOffset` are kept;
  - `RestorePosition` and `SavePosition` with `OW.MiniShift`;
  - `OW:Open` while the bar shows grows it to half first;
  - `F.brandName` with `OW.BrandText()`.
- Modify: `SaftUI-Core/Config/optionsresize.lua`: `ApplyHeight` returns at the bar.
- Modify: `SaftUI-Core/Config/optionslayout.lua`: `ArtReach(L)` is 0 at the bar; `OW.MiniLayout`, `OW.MiniShift` and `OW.BrandText`.
- Modify: `SaftUI-Core/Config/optionsbody.lua`: `FONTS.mini = { 'title', 18 }`.
- Modify: `SaftUI-Core/EditMode/mover.lua`: the selected mover's click opens `/sui` when `not st.Config:GetWindow() or st.OptionsWindow:GetWindowSize() == 'mini'`.
- Test: create `tests/core/options_mini_test.lua` (the world: `options_window_helpers.lua`'s, whose `config_helpers.lua` loads edit mode). Add a Blizzard case to `tests/core/options_settings_test.lua`, and `OW.MiniLayout` to `options_sizes_test.lua`.
- Docs:
  - `.agents/edit-mode.md`: the bar, the Header bullet, Esc, combat and the mover's click in the edit mode bullets.
  - `.agents/testing.md`.
  - `README.md` line 21 (the bar).
  - The design system's `components/OptionsWindow/README.md` (W5, under both looks), and `README.md`'s type table (the bar's brand: Colus 18). Update `tokens.json` where the README's tokens name it.

**Interfaces:**
- Consumes: Task 3's `OW:SetWindowSize`, `OW:Grow`, `OW:Shrink`, `S.UpdateWindowButtons` and `W.IconButton(..., size, iconSize)`.
- Produces:
  - `OW:SetWindowSize('mini')`:
    - it is taken only from half;
    - first `OW:CloseMenu()`, `OW:CloseDialog()` and `W.CloseList()`;
    - `ClearFocus` on `GetCurrentKeyBoardFocus()` when it's inside the window, and `OW:SetStatus(nil)`;
    - it saves `size = 'half'`.
  - `OW.MiniLayout(brand, page, tab, buttons) -> pageWidth, tabWidth, width`:
    - each text's width is rounded first;
    - the parts are 12 + brand + 8 + page + 8 + tab + 8 + buttons + 8, the tab and its gap dropped when `tab` is 0;
    - the width is rounded up to even;
    - at most `OW.MINI_MAX`, cutting the tab first and then the page.
    - `buttons` is grow plus 8 plus the close X.
  - `OW.MiniShift(L) -> dx, dy`: under Blizzard, the metal's right and top reach (`st.ThemeArt.MetalReach()`); else 0, 0. At the bar the window's corner is `S.corner` plus the shift. A drag at the bar saves the corner less it.
  - `OW.BrandText() -> string`: `'Saft|cffRRGGBBUI|r'`, the hex from `st.config.profile.colors.button.blue`, read at each draw.
  - The bar's parts, each shown only at the bar, children of `F.mini` (a frame over the whole window):
    - `F.miniBrand`, in the `mini` font;
    - `F.miniPage`, in `group`, Text > Grey: the title's text;
    - `F.miniTab`, in `field`, Text > Grey: empty for a page with one tab; for a search, `'"<text>"'`, with the page "Search";
    - `F.miniNames`, a Button over the page and tab names;
    - `F.miniGrow`, `W.IconButton(F.mini, st.icons.chevronLeft, tip, st.CLOSE_X_BUTTON_SIZE[1], 20)`: "Grow to half", "Back to the page as you left it.".
    - `F.close` is moved in. The buttons are centred on the bar's 42, and the close X sits 8 in from the right.
  - Hidden at the bar: `F.side`, `F.main`, `F.footer`, `F.grip`, `F.sizer`, `F.innerList`, `F.innerSettings`, `F.titleBar` and `F.titleText`. The window is `st:SetTemplate(window, 'theme', 'solid', 'panel')` at the bar and `'window'` at the other sizes. A theme change at the bar keeps it a bar.
  - The drag and the click:
    - `F.mini` and `F.miniNames` drag the window (`RegisterForDrag('LeftButton')`, `StartMoving`, then `StopMovingOrSizing` and `SavePosition`).
    - `F.miniNames.dragged` is false on `OnMouseDown` and true on `OnDragStart`. Its `OnClick` returns while it's dragged; otherwise it runs `OW:Grow()`.
    - Its tooltip, by a script that takes `(self)` only: the path ("Unitframes > Player > Power", from the page's, pick's and tab's names), then "Click to grow to half. Drag to move.".
  - Under Blizzard: the red close button, at `st.ThemeArt.Close()`'s size, centred on the bar's height; `F.miniGrow` on Blizzard's panel button until Task 9.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_mini_test.lua`

```lua
local function to_half()
	OW:SetWindowSize('half')
	stub.time = stub.time + 1
end

test('Shrink at half: a 42 tall bar at the same corner with the name, the page, the tab, grow and close', function()
	st.Config:Open('Unitframes', 'player', 'power'); to_half()
	local F = frames(); local w = F.window
	local right, top = w:GetRight(), w:GetTop()
	click(F.shrink)
	eq(OW:GetWindowSize(), 'mini'); check(OW:IsShown(), 'still the window, shown')
	eq(w:GetHeight(), 42); eq(w:GetRight(), right); eq(w:GetTop(), top)
	for _, part in ipairs({ 'side', 'main', 'footer', 'grip', 'sizer' }) do check(not F[part]:IsShown(), part .. ' hidden') end
	eq(F.miniBrand:GetText(), OW.BrandText(), 'SaftUI, UI in the accent')
	eq(F.miniPage:GetText() .. '/' .. F.miniTab:GetText(), 'Unitframes/Power', 'the page and the tab')
	eq(st:DrawnKind(w), 'panel', 'drawn as a panel')
	eq(st.config.global.optionsWindow.size, 'half', 'a bar comes back as half')
	-- F.miniBrand's left 12 in; each part 8 after the last; F.close's right 8 in; grow and close 9 from the top and the bottom
	-- w:GetWidth() even and <= 400
end)

test('shrinking to the bar closes a menu, the small dialog and a list, takes the keyboard, and clears the status', function()
	-- OW:OpenDialog(...) at half, then OW:Shrink(): not OW:IsDialogShown(); W.ListOwner() nil;
	-- GetCurrentKeyBoardFocus() nil; F.status:GetText() == ''
end)

test('growing back: half at the page, tab, pick, scroll and search it had', function()
	-- scrolled to 120 at half; shrink, a render (st.Config:Refresh(); tick()): OW.GetDrawnRows() empty
	-- grow: F.body:GetVerticalScroll() == 120 exactly; with a search 'width' running: the bar's page 'Search',
	--   its tab '"width"'; grow: the results page, at its scroll
end)

test('a click on the names grows it; a drag anywhere but its buttons moves it and is no click', function()
	-- OnMouseDown, OnDragStart, the window moved, OnDragStop, OnClick on F.miniNames: still mini; the corner saved from where it shows
	-- OnMouseDown, OnClick: half
	-- OnEnter(true): the tooltip 'Unitframes > Player > Power' and 'Click to grow to half. Drag to move.'
end)

test('Esc, combat and keybind mode close the bar; it opens again at half', function()
	-- stub.fire_script(frames().keys, 'OnKeyDown', 'ESCAPE') at the bar: closed; st.Config:Open(): half
	-- at the bar, PLAYER_REGEN_DISABLED: closed, says why; refuses to open in combat
	-- keybind mode's own calls: st.Config:GetWindow() is the frame, then st.Config:Close(): closed
end)

test('/sui, a path, and a mover\'s click while the bar shows grow it to half on that page', function()
	-- st.Config:Open(): half on the page it had; shrink; st.Config:Open('Loot'): half, Loot
	-- a mover (st:RegisterConfigMover, configPath { 'Loot' }); shrink; EM:Select(mover): half, Loot
	-- shrink; click the selected mover's overlay (stub.click(mover.overlay), mover.dragged false): half
	-- at half, the same click leaves /sui on the page it shows
end)

test('the height grip and the margin leave the bar alone; a bar low on the screen grows back with its anchor kept', function()
	-- at the bar: st:UpdateScreenMargin(); w:GetHeight() == 42; F.grip hidden
	-- corner { x = -100, y = -1040 } at the bar; grow: w:GetPoint(1) offsets still -100, -1040; the save unchanged
end)

test('the sidebar\'s brand: Saft in the text colour, UI in the accent, read at each draw', function()
	-- frames().brandName:GetText() == OW.BrandText(); the accent changed and a render: the new hex
end)
```

In `options_sizes_test.lua`: `OW.MiniLayout(54, 90, 70, 56)` gives `90, 70, 314`; `(54, 90, 0, 56)` gives width 236; `(55, 90, 70, 56)` gives 316 (even); `(54, 300, 300, 56)` gives tab 2, width 400; `(54, 400, 0, 56)` gives page 266, width 400.

In `options_settings_test.lua`, for each client:

```lua
test('the bar under Blizzard: a panel at the metal\'s top right, the red close button inside it', function()
	-- at full, the metal's top right = window corner + MetalReach right and top; shrink twice:
	--   the bar's top right there; T.art(window) is the panel kind's; F.close wears st.ThemeArt.Close().normal,
	--   centred on the bar; a switch to Thick and back keeps it a bar; grow: the window under the metal again
	-- #P.off(F.window) == 0 at the bar
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_mini_test.lua`
Expected: FAIL: `F.miniBrand` is nil.

- [ ] **Step 3: Implement** as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionssizes.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionsresize.lua SaftUI-Core/Config/optionslayout.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/EditMode/mover.lua tests/core/options_mini_test.lua tests/core/options_settings_test.lua tests/core/options_sizes_test.lua .agents/edit-mode.md .agents/testing.md README.md docs/design-system/components/OptionsWindow/README.md docs/design-system/README.md docs/design-system/tokens.json
git commit -m "core: shrink /sui to a small bar at its corner"
```

**In-game checks:**
- Press the arrow beside the X twice: full, half, bar. Double-click it fast: it stops at half.
- The bar reads "SaftUI" with UI in your accent, then the page and the tab. Drag it, click its names: half again, at the same scroll.
- From the bar: `/sui`, `/sui edit` then a click on a frame, and Edit this category on a bag item each grow it to half on that page.
- Esc closes it. Entering combat closes it. `/sui kb` closes it.
- Under Blizzard, on both clients, the bar is a panel with the red X, where the metal's corner was.

---

### Task 5: The sidebar toggle

**Files:**
- Modify: `SaftUI-Core/Config/optionsnav.lua`:
  - `OW:IsSidebarShown`, `OW:SetSidebarShown`;
  - `F.sideToggle`, placed by `S.PlaceSideToggle()`;
  - `F.profile` ends 8 before the toggle.
- Modify: `SaftUI-Core/Config/optionswindow.lua`:
  - `Relayout` with `S.sidebar`: `F.side` and `F.innerList` hidden while collapsed, `OW.MainLeft` and `OW.WindowWidth`;
  - the region starts 12 after the toggle while collapsed;
  - `OW:Open` sets `S.sidebar` from the save.
- Modify: `SaftUI-Core/Config/optionssizes.lua`: `S.UpdateWindowButtons` covers the toggle (the colour picker, and Ruling 4's narrow screen).
- Test: create `tests/core/options_sidebar_test.lua` (`options_window_helpers.lua`'s world, `lib/pixels.lua`). Add a Blizzard case to `tests/core/options_settings_test.lua`.
- Docs: `.agents/edit-mode.md` (the Sidebar and Footer bullets; `S.sidebar` in the shared state), `.agents/testing.md`, `README.md` line 21, the design system's `components/OptionsWindow/README.md`.

**Interfaces:**
- Consumes: Tasks 1, 3 and 4 (`OW.WindowWidth`, `OW.MainLeft`, `OW.Fits`, `S.SaveWindow`, `S.UpdateWindowButtons`, the bar); `st.icons.panelLeftOpen` and `panelLeftClose`.
- Produces:
  - `OW:IsSidebarShown() -> boolean`.
  - `OW:SetSidebarShown(shown) -> boolean`:
    - false in combat, while the colour picker is open, when the new width doesn't `OW.Fits`, or for no change;
    - it saves `sidebar = false` or nil, sets `S.sidebar`, takes the keyboard off `F.search`, and runs `OW:Render()`;
    - the page, tab, pick, search, `S.scrollOffset` and `S.navOffset` are kept exactly;
    - it works at full and at half; at the bar the state is kept for when it grows.
  - `F.sideToggle = W.IconButton(window, icon, tip)` (26, 16 icon):
    - **Shown:** in `F.foot`, its right 8 in from the foot's right, centred on the foot's 30, with `panelLeftOpen` and the tip "Collapse the sidebar", "Hides the page list; the window narrows from its left.". `F.profile`'s width is `L.sideWidth - 61`.
    - **Collapsed:** under Thick and Thin at the footer's left, `PAD` (28) in from the main column, centred on the footer; under Blizzard 16 from the window's bottom left (`L.footerX`, `L.footerY`). It shows `panelLeftClose` and "Show the sidebar", "Shows the page list again.".
    - Under Blizzard it wears `W.LookControl` (Blizzard's panel button, square).

- [ ] **Step 1: Write the failing tests** in `tests/core/options_sidebar_test.lua`

```lua
test('Collapse the sidebar at full: 208 narrower from the left, and the page does not move at all', function()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames(); local w = F.window
	local right, top, mainLeft, titleLeft, bodyLeft = w:GetRight(), w:GetTop(), F.main:GetLeft(), F.title:GetLeft(), F.body:GetLeft()
	click(F.sideToggle)
	eq(OW:IsSidebarShown(), false); eq(w:GetWidth(), 832); eq(w:GetRight(), right); eq(w:GetTop(), top)
	check(not F.side:IsShown(), 'the sidebar hidden')
	eq(F.main:GetLeft(), mainLeft, 'the main column stays'); eq(F.title:GetLeft(), titleLeft); eq(F.body:GetLeft(), bodyLeft)
	eq(st.config.global.optionsWindow.sidebar, false, 'remembered')
	eq(F.sideToggle:GetLeft(), F.main:GetLeft() + 28, 'the toggle at the footer\'s left')
	eq(F.sideToggle.icon:GetTexture(), st.icons.panelLeftClose, 'its arrow points left: show')
	click(F.sideToggle)
	eq(w:GetWidth(), 1040); check(F.side:IsShown()); eq(st.config.global.optionsWindow.sidebar, nil)
end)

test("the toggle in the sidebar's foot at its right; the profile line ends 8 before it", function()
	-- F.sideToggle:GetParent() == F.foot; its right == F.foot:GetRight() - 8; centred on the foot
	-- F.profile:GetWidth() == 147; icon st.icons.panelLeftOpen; OnEnter(true): 'Collapse the sidebar'
end)

test('the sidebar and the size are separate: collapsed at full stays collapsed at half, and the bar keeps it', function()
	-- collapse at full; OW:SetWindowSize('half'): 446; to the bar and back: 446, still collapsed
	-- closed and opened: half, collapsed (the save { size = 'half', sidebar = false })
end)

test('collapsing takes the keyboard off the search box and keeps the search; showing the sidebar shows its text', function()
	-- F.search:SetText('width'), tick(0.3): the results page; F.search:SetFocus(); collapse:
	--   GetCurrentKeyBoardFocus() nil; OW:GetState().search == 'width'; F.title 'Search'
	-- show the sidebar: F.search:GetText() == 'width', its hint hidden; the results still shown
end)

test('the page\'s and the nav\'s scroll are kept exactly across a collapse', function()
	-- F.body:GetVerticalScroll() and S.navOffset (read through F.navFrame:GetVerticalScroll()) the same after collapse and show
end)

test('on a screen too narrow for full with the sidebar, the toggle at full is disabled and says why', function()
	-- stub.screen_width = 1024; saved { sidebar = false }: opens at full, 832; F.sideToggle.disabled; its red line
	--   'The screen is too narrow for the sidebar at full size. Shrink to half first.'; at half it is enabled
end)

test('whole pixels at W2 and W4 under Thick and Thin', function()
	-- stub.size_noise = 2 ^ -14: #P.off(frames().window) == 0 at full collapsed and at half collapsed
end)
```

In `options_settings_test.lua`, for each client:

```lua
test('collapsed under Blizzard: only the settings part of the inner frame, from 17; the toggle 16 from the bottom left', function()
	-- W2: window 868, F.innerList hidden, at(F.innerSettings) '17,28 834x654', at(F.main) '17,28 834x654'
	-- W4: 462, at(F.innerSettings) '17,28 428x654'; F.sideToggle 16 from the window's left and bottom, on Blizzard's panel button art
	-- #P.off(F.window) == 0 at W2 and W4
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_sidebar_test.lua`
Expected: FAIL: `F.sideToggle` is nil.

- [ ] **Step 3: Implement** as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/optionsnav.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionssizes.lua tests/core/options_sidebar_test.lua tests/core/options_settings_test.lua .agents/edit-mode.md .agents/testing.md README.md docs/design-system/components/OptionsWindow/README.md
git commit -m "core: collapse /sui's sidebar from its foot, narrowing the window from its left"
```

**In-game checks:**
- Collapse the sidebar at full: the page doesn't move, and the window loses its left. Show it again from the footer's left.
- The same at half. A `/reload` keeps it.
- A long profile name is cut before the toggle.
- Under Blizzard, on both clients, only the settings part of the inner frame shows while collapsed, its line the window's left edge.

---

### Task 6: With the sidebar collapsed: icons in the footer, the page list on the title

**Files:**
- Modify: `SaftUI-Core/Config/config.lua`: `Config:AddCommand(command, label, func, icon)`; `GetCommands` entries carry `icon`.
- Modify: `SaftUI-ActionBars/keybindmode.lua`: `AddCommand('kb', 'Keybind mode', ..., st.icons.keyboard)`.
- Modify: `SaftUI-Core/Config/optionsnav.lua`:
  - the footer's tools, `S.DrawTools()`;
  - the search panel (`F.searchPop`);
  - the title's page list (`F.titleButton`, `F.titleArrow`);
  - `S.UpdateEditModeButton` also sets the footer's Edit mode button.
- Modify: `SaftUI-Core/Config/optionswindow.lua`:
  - `F.search`'s `OnEditFocusLost` hides `F.searchPop` while collapsed;
  - the region starts 12 after the last tool;
  - the title's room loses its arrow's 24 while collapsed.
- Modify: `SaftUI-Core/Config/optionslayout.lua`: `OW.PageMenuEntries`.
- Modify: `SaftUI-Core/Config/optionslist.lua`: caption and disabled entries.
- Test: add cases to `tests/core/options_sidebar_test.lua`, `tests/core/options_list_test.lua` and `tests/core/options_open_test.lua` (`GetCommands`' icon).
- Docs:
  - `.agents/edit-mode.md`: Subcommands (the icon), Sidebar, Footer and Search; the select list's entries in the widgets section.
  - `.agents/architecture.md` (`Config/config.lua`'s `AddCommand`).
  - `.agents/taint.md`: review only, since `keybindmode.lua` is covered; only an argument changes.
  - `.agents/testing.md`.
  - `README.md` lines 21 and 37 (Keybind mode's icon while collapsed).
  - The design system's `components/OptionsWindow/README.md` (collapsed: the footer's icons, the page list) and `components/Select/README.md` (captions and disabled entries).

**Interfaces:**
- Consumes: Task 5's `OW:IsSidebarShown` and `F.sideToggle`; `st.icons.search` (the edit mode bar's Task 2), `move`, `keyboard` and `chevronDown`; `W.SetOn`, `W.IconButton`, `W.Button`, `W.ShowTip`.
- Produces:
  - `Config:AddCommand(command, label, func, icon)`: `icon` is optional, a texture path. `Config:GetCommands()` entries are `{ command, label, func, icon }`.
  - `F.tools`, shown only while collapsed, in a line from the toggle, 6 apart, centred on the footer:
    - `F.tools[1]` Search: `W.IconButton(main, st.icons.search, tip)`. Its tip is "Search settings", "Finds a setting by name, on any page.", or while a search is on, `'Searching for "<text>". Click to change it.'`. It is `W.SetOn` while `state.search ~= ''`.
    - `F.tools[2]` Edit mode: `st.icons.move`, "Edit mode", "Drag and nudge SaftUI's frames. /sui edit does too.". Its click runs `st.EditModeFrames:Toggle()`, and it is `W.SetOn` while edit mode is on.
    - Then each command: `W.IconButton` with its icon and its label as the title. Without an icon, a `W.Button` with its label.
    - Under Blizzard each wears `W.LookControl`.
  - `F.searchPop`:
    - a child of `F.main` at its frame level + 20, drawn `st:SetTemplate(pop, 'theme', 'solid', 'panel')`;
    - its size is `SEARCH_WIDTH + 16` by `FIELD_HEIGHT + 16`, its bottom left 6 over the Search icon's top left;
    - the Search icon's click moves `F.search` into it (`SetParent`, 8 in) and gives it the keyboard;
    - it hides when the box loses the keyboard;
    - `F.search` goes back to `F.actionsFrame` when the sidebar shows.
  - `F.titleButton` and `F.titleArrow`:
    - while collapsed, the arrow (`chevronDown`, 16, Text > Grey, the accent under the mouse) sits 8 after the title's text, and the button covers the title and the arrow;
    - its click is `W.OpenList(F.titleButton, OW.PageMenuEntries(entries), state.page, function(key) OW:Navigate(key) end)`, with the tooltip "Choose a page";
    - hidden, and taking no click, while the sidebar shows.
  - `OW.PageMenuEntries(entries) -> list`, from `OW.SidebarEntries`' entries: a page gives `{ key, label = name, disabled }`, and a `{ group }` header gives `{ caption = true, label = group }`.
  - `W.OpenList(owner, entries, ...)`:
    - an entry with `caption = true` draws its label in Text > Grey, shows no hover, and its click does nothing, the list staying open;
    - an entry with `disabled = true` is alpha 0.4 and can't be picked;
    - under Blizzard the same, on the Settings menu's art.

- [ ] **Step 1: Write the failing tests**, added to `tests/core/options_sidebar_test.lua` (the world adds `st.Config:AddCommand('kb', 'Keybind mode', fn, st.icons.keyboard)` and `('two', 'Two', fn2)`)

```lua
test('collapsed, the footer holds the toggle, then Search, Edit mode and each command, 6 apart, each with its tooltip', function()
	st.Config:Open('Loot'); OW:SetSidebarShown(false)
	local F = frames()
	eq(F.tools[1].icon:GetTexture(), st.icons.search); eq(F.tools[2].icon:GetTexture(), st.icons.move)
	eq(F.tools[3].icon:GetTexture(), st.icons.keyboard, "Keybind mode's icon")
	eq(F.tools[4].text:GetText(), 'Two', 'a command without an icon: its label')
	eq(F.tools[1]:GetLeft(), F.sideToggle:GetRight() + 6, '6 after the toggle')
	eq(F.footerRegion:GetLeft(), F.tools[4]:GetRight() + 12, 'the region after them')
	-- OnEnter(true) on each: 'Search settings', 'Edit mode', 'Keybind mode', 'Two'; with the sidebar shown none is shown
end)

test("Edit mode's icon toggles edit mode and is on in the accent while it is on", function()
	-- click(F.tools[2]): st.EditModeFrames.active, F.tools[2].on true; again: off
end)

test("Search opens the sidebar's box over the footer; losing the keyboard closes it and keeps the search", function()
	-- click(F.tools[1]): F.searchPop shown, F.search:GetParent() == F.searchPop, F.search:HasFocus()
	-- F.searchPop's bottom == F.tools[1]:GetTop() + 6
	-- type 'width', tick(0.3): the results page; OnEnterPressed: popup hidden, results kept, F.tools[1].on
	-- click a result: its page, OW:IsSidebarShown() false, OW:GetState().search == '', the icon off
	-- open again, type, OnEscapePressed: the search cleared, the page back
end)

test('the title opens the page list, grouped as the sidebar is, while the sidebar is collapsed', function()
	-- F.titleArrow shown, its left 8 after F.title's text; click(F.titleButton): W.ListOwner() == F.titleButton
	-- listed(): 'Global Settings,Profiles,Frames,...' with the captions grey and the open page blue; a caption's click keeps it open
	-- pick 'Loot': OW:GetState().page == 'Loot', the sidebar still collapsed; OnEnter(true): 'Choose a page'
	-- with the sidebar shown: F.titleArrow hidden, F.titleButton takes no click
end)

test("a search result in an item's menu at W4 opens the menu, kept in the screen margin", function()
	-- a page with an item (as options_menu_test.lua registers one); half, collapsed; search the item's menu setting; click it:
	--   OW:IsMenuShown(); the menu's left >= the screen margin; #P.off(menu frame) == 0
end)

test("whole pixels: the footer's icons at W2 and W4, the search box over the footer, the title's arrow", function()
	-- for thick and thin, with stub.size_noise = 2 ^ -14: #P.off(frames().window) == 0 with the popup open
end)
```

In `options_list_test.lua`:

```lua
test('a list with captions and disabled entries: a caption takes no click and no hover, a disabled entry no pick', function()
	-- W.OpenList(owner, { { caption = true, label = 'Frames' }, { key = 'a', label = 'A' }, { key = 'b', label = 'B', disabled = true } }, 'a', onPick)
	-- row 1 grey, OnEnter shows no hover, click: list still open, onPick not run; row 3 alpha 0.4, click: not picked; row 2 picks 'a'
	-- under Blizzard the same rows on the Settings menu's art
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_sidebar_test.lua tests/core/options_list_test.lua`
Expected: FAIL: `F.tools` is nil.

- [ ] **Step 3: Implement** as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core tests/actionbars`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/config.lua SaftUI-ActionBars/keybindmode.lua SaftUI-Core/Config/optionsnav.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionslayout.lua SaftUI-Core/Config/optionslist.lua tests/core/options_sidebar_test.lua tests/core/options_list_test.lua tests/core/options_open_test.lua .agents/edit-mode.md .agents/architecture.md .agents/testing.md README.md docs/design-system/components/OptionsWindow/README.md docs/design-system/components/Select/README.md
git commit -m "core: move the collapsed sidebar's search, modes and pages to the footer and the title"
```

**In-game checks:**
- Collapse the sidebar. The footer shows the toggle, Search, Edit mode and Keybind mode as icons, each with its tooltip.
- Search: a box opens above the icon. Type, press Enter, click a result.
- Click the title: the page list, grouped as the sidebar. Pick a page.
- Edit mode's icon lights in the accent while edit mode is on.
- At W4 the footer still fits. A validation error, from a typed value on any page, wraps to two lines there; note whether it reads.
- Under Blizzard, on both clients, the icons sit on Blizzard's buttons.

---

### Task 7: The unit frames' profile control on the Unit dropdown's line

**Files:**
- Modify: `SaftUI-Core/Config/optionswindow.lua`:
  - `DrawPickerControl(picker, top) -> bottom` draws an option that isn't an execute after its name (`pools.pickerLabel`, `field` font, Text > Normal, `LABEL_GAP` before its widget);
  - it places the picker and each piece by `OW.PickerFlow`;
  - `DrawPage` places the body under its bottom.
- Modify: `SaftUI-Core/Config/optionslayout.lua`: `OW.PickerFlow` and `OW.PICKER_LINE_GAP`.
- Modify: `SaftUI-Unitframes/config/profiles.lua`: `UF.GenerateProfileFooter` becomes `UF.GenerateProfileControl()`; the header comment.
- Modify: `SaftUI-Unitframes/config/config.lua`: the page's `footer` goes; each unit's `pickerControl.args` takes `copy` and the profile control's two.
- Modify: `SaftUI-Unitframes/nameplates/options.lua`: `UF.SetUpPlatePage` gives the plates a `pickerControl` holding only the profile control.
- Test: `git mv tests/unitframes/profile_footer_test.lua tests/unitframes/profile_control_test.lua`, its cases rewritten for the picker's line. Add `OW.PickerFlow` to `tests/core/options_sizes_test.lua`, and a case to `tests/core/options_frame_test.lua`.
- Modify tests: `tests/unitframes/config_test.lua` (about lines 420 and 1084 to 1085) and `tests/unitframes/friendly_page_test.lua` (lines 151 to 152): the plates' `pickerControl` holds `profile` and `manage` and no `copy`.
- Docs:
  - `.agents/edit-mode.md`: Tabs, which gains the picker row's control (labels, the flow); the footer field (unused, with no page drawing one); the small dialog paragraph ("UF's Manage (the Unitframes page's footer control)" becomes the picker's line).
  - `.agents/architecture.md` (`config/profiles.lua` and `nameplates/**` are covered).
  - `.agents/testing.md` (the renamed file).
  - `README.md` line 21 (the profile beside the Unit dropdown).
  - The design system's `components/OptionsWindow/README.md` (the picker row, the footer).

**Interfaces:**
- Consumes: `fb-kit2`'s `pickerControl`, `view.picker.control`, `F.pickerWidgets` and `TipFooterWidget`; Task 3's `S.bodyWidth`.
- Produces:
  - `OW.PICKER_LINE_GAP = 8`.
  - `OW.PickerFlow(widths, width) -> places, height`. `widths[1]` is the picker with its label, and each later entry is one piece of the control (a button, or a label and its widget). Pieces go left to right, 12 apart. A piece that would pass `width` starts a new line at x 0, `FIELD_HEIGHT + OW.PICKER_LINE_GAP` under the last; a piece wider than the line goes alone on one. `places[i] = { x, y }`, both whole. The height is `lines * FIELD_HEIGHT + (lines - 1) * OW.PICKER_LINE_GAP`.
  - `UF.GenerateProfileControl() -> args`:
    - `profile`: a copy of `UF.GenerateProfileConfigGroup().args.current`, its `size` cleared, named "Profile", `order = 10`;
    - `manage`: today's Manage, `order = 11`.
  - The Unitframes page group has no `footer`. Each unit's `pickerControl.args` is `{ copy = <today's>, profile, manage }`, and each plate page's is `{ profile, manage }`.

- [ ] **Step 1: Write the failing tests**

In `options_sizes_test.lua`:

```lua
test('OW.PickerFlow: pieces 12 apart, wrapping at the width, a line 24 tall and 8 under the last', function()
	local places, height = OW.PickerFlow({ 210, 90, 225, 84 }, 774)
	-- xs 0, 222, 324, 561, every y 0; height 24
	places, height = OW.PickerFlow({ 210, 90, 225, 84 }, 388)
	-- (0,0) (222,0) (0,32) (237,32); height 56
	-- OW.PickerFlow({ 210, 400 }, 388): the 400 alone on line 2 at x 0
end)
```

In `options_frame_test.lua`:

```lua
test("a pick's control: a dropdown drawn after its name, and the line wrapping at the body's width", function()
	-- ufPickerControl with copy (execute), profile (a select named 'Profile'), manage (execute):
	-- at full one line: Copy from 12 after the picker; 'Profile' 12 after it; the select 10 after its label; Manage 12 after
	-- at half: Profile's label at PAD on a second line 32 under the first; the body's top under that line; #P.off(F.main) == 0
end)
```

In `tests/unitframes/profile_control_test.lua`, rewriting today's cases (its world as `profile_footer_test.lua` had it):

```lua
test("the unit frame profile is on the Unit dropdown's line: Unit, Copy from, Profile, Manage; the footer holds none", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local F = OW.GetFrames()
	eq(#F.footerWidgets, 0, 'no footer control')
	local types = {}
	for i, w in ipairs(F.pickerWidgets) do types[i] = w.type end
	eq(table.concat(types, ','), 'execute,select,execute', 'Copy from, the profile, Manage')
	-- the select lists the profiles and switches (UF:UpdateConfig counted); Manage opens Unit frame profiles;
	-- New, Rename and Delete in the dialog: the line's dropdown follows
end)
-- the plates' pages: 'select,execute', no Copy from; a search for 'profile' finds it on the pick's path;
-- at half: two lines on whole pixels under Thick and Blizzard
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_sizes_test.lua tests/core/options_frame_test.lua tests/unitframes/profile_control_test.lua`
Expected: FAIL: `OW.PickerFlow` is nil.

- [ ] **Step 3: Implement** the flow and the labels in Core, then the unit frames' side, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes`, then `tests/run -j2`. Expected: PASS. List the changed plate assertions.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git mv tests/unitframes/profile_footer_test.lua tests/unitframes/profile_control_test.lua
git add SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionslayout.lua SaftUI-Unitframes/config/profiles.lua SaftUI-Unitframes/config/config.lua SaftUI-Unitframes/nameplates/options.lua tests/unitframes/profile_control_test.lua tests/unitframes/config_test.lua tests/unitframes/friendly_page_test.lua tests/core/options_sizes_test.lua tests/core/options_frame_test.lua .agents/edit-mode.md .agents/architecture.md .agents/testing.md README.md docs/design-system/components/OptionsWindow/README.md
git commit -m "unitframes: move the unit frame profile beside the Unit dropdown"
```

**In-game checks:**
- On Unitframes at full, one line reads Unit, Copy from, Profile, Manage. At half it is two lines.
- Switching profiles there switches every unit frame, and Manage opens the dialog.
- The nameplate pages have Profile and Manage.
- The footer is clear. Both looks, both clients.

---

### Task 8: The bags' Categories tab at half: the list in a menu

**Files:**
- Modify: `SaftUI-Bags/categoriestab.lua`:
  - the compact layout in `Layout` and `Fit`;
  - the button, previous and next, the menu;
  - `w.body:SetWidth` and `w.footerBody:SetWidth`;
  - `INV:EditCategory` closes the menu;
  - the header comment.
- Modify: `tests/bags/categories_world.lua`: `half()`, which runs `OW:SetWindowSize('half')` and moves `stub.time` past the guard.
- Test: create `tests/bags/categories_half_test.lua`.
- Docs:
  - `.agents/testing.md` (`tests/bags/`);
  - `.agents/architecture.md`'s Bag categories section, if it names the tab's layout;
  - `README.md` line 40 (at half, the list is a menu);
  - `AGENTS.md`'s SaftUI-Bags row, if it describes the tab's layout.

**Interfaces:**
- Consumes: Task 2's `body:SetWidth`; Tasks 3 and 4 (`OW:GetWindowSize`, the window at half, `OW:Open` from the bar); `W.SelectFace`, `W.IconButton(..., size, iconSize)`, `W.SetEnabled`, `W.ShowTip`, `W.Kit.CatchKeys`; `st.icons.list`, `chevronLeft` and `chevronRight`.
- Produces:
  - Constants:
    - `COMPACT_BELOW = EDITOR_X + EDITOR_WIDTH` (774);
    - `MENU_BUTTON_WIDTH = 260`;
    - `BUTTON_LINE = W.FIELD_HEIGHT + 10` (34, the editor's top in the compact layout);
    - `MENU_PAD = 8`; `MENU_WIDTH = LIST_WIDTH + 24` (234); `MENU_ROWS = 14`;
    - `MENU_LEVEL = 410` and `MENU_CATCHER_LEVEL = 400` (as an item's menu).
  - `w.compact`: `SetWidth(width)` makes it `width < COMPACT_BELOW`.
  - `w.menuButton = W.SelectFace(w.frame, MENU_BUTTON_WIDTH, onClick)`:
    - `face.icon` is `st.icons.list`, 16, 8 in;
    - `face.text` is the category's name, 6 after the icon;
    - `face.place` is `'<i> of <n>'` in the small font, Text > Grey, 6 before the caret;
    - its tip is "Categories", "Opens the list: pick one to edit, or drag one to reorder.".
  - `w.prevButton` and `w.nextButton`: `W.IconButton(w.frame, st.icons.chevronLeft or chevronRight, tip, 24, 16)`, 6 apart after the face. Their tips are "Previous category" and "Next category", disabled at their ends with Ruling 13's red lines.
  - The editor in compact: `w.editorScroll` and `w.footer` at x 0, the whole width. The editor and footer bodies get `SetWidth(width)`, and the list's pane leaves the tab.
  - `w.menu`:
    - **Frames.** A frame on UIParent at `FULLSCREEN_DIALOG` `MENU_LEVEL`, drawn `st:SetTemplate(menu, 'theme', 'solid', 'panel')` and kept in the screen margin, with a catcher at `MENU_CATCHER_LEVEL` that closes it on a click outside.
    - **Contents.** `w.menu.caption` ("Categories: drag to reorder", the `caption` font, Text > Grey), then `w.listPane` moved into it, holding the rows, their handles, counts, markers, ghost and drop line, the bar, + New category and Reset all. Its list view is at most `MENU_ROWS` rows tall.
    - **Placement.** Its top left is 4 under the face's bottom left.
    - **Keys.** Esc closes it, through `W.Kit.CatchKeys`.
    - **Back at full.** `w.listPane` returns to `w.frame`.
  - `INV.categoryEditor.menuOpen`: the menu is open while it's true and the tab is compact. It is set by the face, and cleared as Ruling 13 says.
  - A close mid-drag runs `StopDrag(w)` first, with no move.

- [ ] **Step 1: Write the failing tests** in `tests/bags/categories_half_test.lua` (world: `categories_world.lua`'s, with `open`, `tab`, `cell`, `click`, `cursor_on`, `drag_frame` and `half`; `local P = load_test_file('lib/pixels.lua')`)

```lua
test('at half the list is a button over the editor naming the category and its place; the editor takes the width', function()
	open(); half()
	local w = tab()
	local list = INV:GetCategoryList()
	check(w.compact, 'compact at 388')
	eq(w.menuButton.text:GetText(), list[1].name); eq(w.menuButton.place:GetText(), '1 of ' .. #list)
	eq(w.menuButton.icon:GetTexture(), st.icons.list)
	eq(w.prevButton:GetLeft(), w.menuButton:GetRight() + 6); eq(w.nextButton:GetLeft(), w.prevButton:GetRight() + 6)
	check(not w.listPane:IsVisible(), 'the list is in the closed menu')
	eq(w.editorScroll:GetLeft(), w.frame:GetLeft(), 'the editor at the left'); eq(w.body.width, 388, 'the whole width')
	OW:SetWindowSize('full')
	-- tab() at full: the list beside the editor as before (w.listPane:GetParent() == w.frame, the editor at 234, 540)
end)

test('the button opens the list as a menu: the same rows and counts; a pick closes it and edits that category', function()
	-- click(w.menuButton): w.menu shown, its top 4 under the button; #w.rows == #list; counts as at full
	-- click(w.rows[3].frame): INV.categoryEditor.selected == list[3].id; w.menu hidden; the button '3 of n'
end)

test('dragging in the menu reorders as the list does; the menu stays open after the drop', function()
	-- the handle's OnMouseDown on row 4, cursor_on(row 2's upper half), OnMouseUp: the order moved as at full; tab().menu shown
end)

test('previous and next step through the categories, each disabled at its end', function()
	-- click(next): list[2]; at the first: prevButton.disabled, its tooltip's red line 'This is the first category.'; last likewise
end)

test('a drag in the menu that ends with the menu closing moves nothing', function()
	-- start a drag on row 4; Esc on the menu's keys: w.menu hidden, w.drag nil, the ghost hidden, the order unchanged
	-- again, then PLAYER_REGEN_DISABLED: the window closed, the order unchanged; open again at half: the menu closed
	-- again, then a bag update (INV:UpdateHandler): nothing drawn until the mouse is let go (the tab's hold)
end)

test('EditCategory from the bar or at half opens the tab at half with the category in the button', function()
	-- OW:SetWindowSize('mini') (from half); INV:EditCategory('Trade Goods'): OW:GetWindowSize() == 'half',
	--   OW:GetState().tab == 'categories', tab().menuButton.text 'Trade Goods', the menu closed
end)

test('whole pixels at half with the menu open, under Thick and under Blizzard on both clients; a long rule wraps', function()
	-- for client in forever, retail; theme thick and blizzard: #P.off(OW:GetFrame()) == 0, #P.off(tab().menu) == 0
	-- the editor's rule (the Old gear block) at 388: every field clear of its X, as categories_editor_test.lua checks at 540
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/bags/categories_half_test.lua`
Expected: FAIL: `w.compact` is nil.

- [ ] **Step 3: Implement** as the Interfaces say. The list's code (`LayListRow`, `ScrollList`, `DropSpot`, `EdgeScroll`) is the same in either place: only its pane's parent and its view's height change.

- [ ] **Step 4: Run** `tests/run tests/bags`, then `tests/run -j2`. Expected: PASS. Every earlier Categories test passes unchanged at full.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Bags/categoriestab.lua tests/bags/categories_world.lua tests/bags/categories_half_test.lua .agents/testing.md .agents/architecture.md README.md AGENTS.md
git commit -m "bags: put the category list in a menu on a button at half width"
```

**In-game checks:**
- Bags > Categories at half: the button names the category and its place. The menu lists every category with counts.
- Drag one to reorder, and pick one: the menu closes on it. Previous and next step through the list.
- A long rule wraps in the narrow editor.
- Grow to full: the list is beside the editor again.
- Edit this category on a bag item while `/sui` is a bar: half, on that category.
- Both looks, both clients.

---

### Task 9: Blizzard's art for the size arrows; every state checked

**Files:**
- Modify: `SaftUI-Core/themeart_data.lua` (`ART.sizebutton`, each atlas marked per client) and `SaftUI-Core/themeart.lua` (`CONTROLS` gains `sizebutton`).
- Modify: `SaftUI-Core/Config/optionssizes.lua`: `S.LookSizeButton(button, kind)` gives `F.grow`, `F.shrink` and `F.miniGrow` the art under Blizzard, where the client has it.
- Modify: `tests/wow/atlases.lua`: the new atlases on each client that has them, from the same tables.
- Test: create `tests/core/options_states_test.lua`. Add the names to `tests/core/theme_blizzard_test.lua`'s list.
- Docs: `.agents/architecture.md` (the art data), `.agents/edit-mode.md` (the arrows under Blizzard), `.agents/testing.md`, `.agents/clients.md` (which client has the art), the design system's `components/OptionsWindow/README.md` (Blizzard).

**Interfaces:**
- Consumes: Tasks 3 to 8.
- Produces:
  - `ThemeArt.Control('sizebutton') -> { size, grow = { normal, pushed, disabled }, shrink = { normal, pushed, disabled }, highlight, highlightBlend }`.
    - These are Blizzard's `MaximizeMinimizeButtonFrameTemplate` art: grow takes its expand, shrink its condense.
    - Find the names in wow-ui-source for both clients (`.agents/clients.md`). Candidates are `RedButton-Expand`, `RedButton-Condense` and their `-Pressed` and `-Disabled`, with `RedButton-Highlight`.
    - Mark each `Atlas(name)` or `Atlas(name, 'forever' | 'live')`.
    - A client without them keeps Task 3's Lucide chevron on Blizzard's panel button.
  - `S.LookSizeButton(button, kind)` (`kind` is `'grow'` or `'shrink'`):
    - under Blizzard with the art, it hides the button's Box and icon and shows the art at its `size`, centred where the 24 square is, its disabled art when `button.disabled`;
    - otherwise `W.LookControl` and the chevron, as before;
    - under Thick and Thin the Box and the chevron.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_states_test.lua` (worlds per client as `options_settings_test.lua`'s `world(client)`; `lib/pixels.lua`)

```lua
local STATES = {
	{ 'W1', 'full', true }, { 'W2', 'full', false }, { 'W3', 'half', true }, { 'W4', 'half', false }, { 'W5', 'mini', true },
}

test("under Blizzard the size arrows wear Blizzard's expand and condense art where the client has it", function()
	-- per client: art = st.ThemeArt.Control('sizebutton'); with art: F.shrink shows art.shrink.normal, F.grow (half)
	--   art.grow.normal, the bar's grow art.grow.normal; disabled (colour picker open): art's disabled; Thick again:
	--   the Box and the chevrons; without art (a client lacking it): W.LookControl's panel button and the chevron
end)

test('every state on every look and client sits on whole pixels', function()
	-- for client, look in thick, thin, blizzard, each STATE (sizes stepped with the guard passed):
	--   stub.size_noise = 2 ^ -14; the widths of Task 1's table (the bar's even and <= 400); #P.off(window) == 0
end)

test('Esc and combat close every state; it opens again at the size it should', function()
	-- each STATE: Esc -> closed; Open -> the same, but W5 -> half with its sidebar; PLAYER_REGEN_DISABLED -> closed, likewise
end)

test('a theme change keeps the state', function()
	-- each STATE: thick -> blizzard -> thick: OW:GetWindowSize() and OW:IsSidebarShown() unchanged, the corner unchanged
end)
```

In `theme_blizzard_test.lua`'s "every atlas the theme names exists" list: the size button names that each client has.

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_states_test.lua tests/core/theme_blizzard_test.lua`
Expected: FAIL: `sizebutton is not a control`.

- [ ] **Step 3: Implement** the art data (names checked in each client's source and atlas tables) and `S.LookSizeButton`, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/themeart_data.lua SaftUI-Core/themeart.lua SaftUI-Core/Config/optionssizes.lua tests/wow/atlases.lua tests/core/options_states_test.lua tests/core/theme_blizzard_test.lua .agents/architecture.md .agents/edit-mode.md .agents/testing.md .agents/clients.md docs/design-system/components/OptionsWindow/README.md
git commit -m "core: dress /sui's size arrows in Blizzard's expand and condense art"
```

**In-game checks:**
- Under Blizzard, on both clients, compare the red expand and condense buttons against Task 3's chevrons on Blizzard's buttons, and keep the better. A client without the art keeps the chevrons.
- Step through W1 to W5 under each theme: crisp edges, nothing moves at the right or the top.
- Esc and combat close every state, and the bar comes back as half.
- A theme change in each state keeps it.

---

## Spec coverage check

| Spec section, or settled point | Task |
| --- | --- |
| What the owner decided 1 (the sidebar shrinks the window), 2 (toggle by the sidebar), 5 (sidebar at half) | 5 |
| What the owner decided 3 (Reload UI beside Close) | 3 |
| What the owner decided 4 (three sizes, arrows by the X), 7 (arrows flipped) | 3, 4 |
| What the owner decided 6 (the bar keeps the name, 42 tall) | 4 |
| The states: widths, W1 to W5 | 1 (numbers), 3, 4, 5 |
| The new buttons (sizes, looks, tooltips, the close X's "Close") | 3, 5, 6 |
| The icons | 1 (and `move`, `keyboard`, `list` for Settled 2, 4 and 9) |
| The sidebar toggle: where it sits; Search | 5 |
| What collapsing hides | replaced by Settled 2: 6 |
| Half size: the body, halves, quarters, wide rows, lines of buttons, panels and dividers | 2 |
| Half size: search results one to a line | 2, 3 |
| Half size: the header, the tabs, the footer's status line | 3 |
| Half size: the picker row | 7 |
| Half size: the footer control's own line | replaced by Settled 5: 7 |
| Half size: dialogs and menus | 3 (the dialog and a menu at half), 6 (a menu at W4) |
| A row too wide for one column | replaced by Settled 9: 8 |
| Mini (what shows, it is the window, dragging, the names' click, what shrinking closes, the colour picker) | 4 (the picker: 3, 5) |
| Moving between states: the corner and its conversion | 1 |
| Moving between states: whole pixels | every task; 9 sweeps all states |
| Near a screen edge | 3, 4 |
| The height grip | 1, 4 |
| Scroll | 3, 4, 5 |
| One change at a time (relayout, the guard) | 3 |
| What is remembered | 1 (reading), 3 (size), 5 (sidebar), 4 (the bar comes back as half; pages opened while it shows) |
| Escape and combat | 4, 9 |
| The Blizzard layout: the inner frame's cut | 3, 5 |
| The Blizzard layout: W2 to W4 | 3, 5 |
| The Blizzard layout: the arrows on the title bar, and their art | 3, 9 |
| The Blizzard layout: the toggle on the panel button | 5 |
| The Blizzard layout: Reload UI and Close; W5 as a panel | 3; 4 |
| What's left to the builder: the "bottom right" notes | 3 |
| What's left to the builder: docs and tests | every task |
| Risks: tests pinning the centre | 1 |
| Risks: dialogs on the centre | 3 (`fb-pixfix` is merged) |
| Risks: `Relayout` per state | 3 |
| Risks: `ApplyHeight`, `RestorePosition` and `StopResize` | 1, 4 |
| Risks: the fill row | 8 |
| Risks: shared settings at half | 2 |
| Risks: edit mode's footer buttons | assumed gone (the edit mode bar's Task 3) |
| Risks: the double click | 3 |
| Risks: Blizzard's cut and art | 3, 9 |
| Risks: keybind mode | 4 |
| Settled 1 (arrows as drawn) | 3, 5 |
| Settled 2 (the sidebar's things move: footer icons, the title's page list, no name while collapsed) | 6 (the name hides with the sidebar: 5) |
| Settled 3 and 6 ("Saft" in the text colour, "UI" in the accent) | 4 |
| Settled 4 (the icons in the footer, choice F) | 6 |
| Settled 5 (the profile control beside the Unit dropdown) | 7 |
| Settled 7 (the size and sidebar remembered) | 1, 3, 5 |
| Settled 8 (everything hides in combat, the bar too) | 4, 8 (the menu), 9 |
| Settled 9 (the bags' list in a menu, previous and next, the list kept beside the editor at full) | 8 |

**Where the spec is ambiguous, and the reading chosen:**
1. **Choice F's Search icon.** The spec doesn't say what it opens. Read as: it opens the sidebar's own box in a small panel above it, which closes when the box loses the keyboard (Ruling 9).
2. **The size of the new buttons.** The spec's "the size of the close X it sits by" is read for the header only. The footer's and the foot's icon buttons are the kit's 26, beside the 26 tall Reload UI and Close (Ruling 1).
3. **Commands other than Keybind mode.** The spec names only Search, Edit mode and Keybind mode, and Core never names a module. So `AddCommand` gains an optional icon, and a command without one is a text button (Ruling 10).
4. **The profile control's order and label.** Read as: Unit, Copy from, Profile, Manage, the label "Profile" so it fits the 368 half body. The plates' pages keep the control, because their settings are in the unit frame profile (Ruling 12).
5. **The footer field with no user.** It is kept in the kit, unused, with no second footer line (Ruling 8).
6. **The status line at W4.** With the three icons there, the region is about 65 wide, not the spec's 165. The status line wraps to two lines and is cut past that (Ruling 7). An in-game check.
7. **Screen too small.** The spec says nothing about it. Ruling 4 adds the fit rule, the disabled Grow and toggle, and opening at half.
8. **The menu's open state across renders, and the ends of previous and next.** Read as: it stays open through a drop, Reset all and a bag update, and closes on a pick and the rest of Ruling 13; previous and next are disabled at the ends, not wrapping.
9. **The description at full.** The spec asks it to wrap at half. It wraps at every size here, one rule, and a one-line description leaves the tabs at 87 as today (Ruling 6).
10. **The title's arrow.** It is 16, not the mockup's 18, to keep the icon rule (Ruling 11).
11. **The Categories menu's caption.** It reads "Categories: drag to reorder", not the mockup's middle dot, which SaftUI's fonts may not draw (Ruling 13).
12. **Blizzard's expand and condense art.** The spec leaves the choice to the builder in game. Task 9 builds the art where the client has it, keeps the chevron otherwise, and the in-game check picks.

