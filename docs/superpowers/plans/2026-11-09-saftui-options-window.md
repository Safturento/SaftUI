# SaftUI options window Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/sui` is drawn by SaftUI's own window from the same Ace option tables, matching the approved mockup. AceConfigDialog, AceGUI and SaftUI's Ace skin are no longer used by SaftUI.

**Architecture:** Three layers in `SaftUI-Core/Config/`:
- **A pure model** (`optionsmodel.lua`) turns `Config:GetOptionsTable()` into page views. It implements AceConfig's contract: info tables, inheritance, and the get/set/validate/confirm calls. It's fully testable in `tests/`.
- **Widgets** (`optionswidgets.lua`): SaftUI frames, one per option type.
- **The window** (`optionswindow.lua`) draws a view and owns navigation, search, the footer and the keyboard.

`config.lua` keeps its public API (`Open`, `GetWindow`, `Refresh`, `AddCommand`) on top of the new window.

**Tech Stack:** WoW Lua (Forever 16001, retail 120000), Ace3 (AceDB, AceDBOptions, AceConfigRegistry), and the repo test suite (`tests/run`, Lua 5.1 through lupa; see `.agents/testing.md`).

**Spec:** `docs/superpowers/specs/2026-11-09-saftui-options-window-design.md`. Read all of it, including both sets of builder's calls. The visual reference is `docs/superpowers/specs/assets/2026-11-09-options-window-mockup.html`.

## Global Constraints

- **Taint:**
  - Every frame and texture is SaftUI's. Nothing is written onto Blizzard frames or tables; not `UISpecialFrames` either, since Esc uses a SaftUI keyboard catcher.
  - The color picker uses Blizzard's `ColorPickerFrame` only through its public setup API (`ColorPickerFrame:SetupColorPickerAndShow(info)` where it exists, with the older fields as a fallback), as `.agents/taint.md` allows.
- **Combat:** `/sui` refuses to open in combat, and closes on `PLAYER_REGEN_DISABLED` (as today).
- **Public API kept:**
  - `st.Config:Open(...)` (a path of option keys), `st.Config:Close()` (new), `st.Config:GetWindow()` (truthy while open), `st.Config:Refresh()` (AceConfigRegistry NotifyChange), and `st.Config:AddCommand(command, label, func)`.
  - The slash commands `/sui`, `/saftui` and `/sui edit` are unchanged.
- **Layout and look (from the mockup):**
  - The window is fixed at 1040×700 UI units, in the thick template.
  - The sidebar is 210 wide.
  - The page title uses Colus at about 34; the description Agency FB at about 15, in grey.
  - Tabs use Agency FB Bold at about 17. The active tab is underlined in `colors.button.blue`.
  - Section titles use Colus at about 15, in grey. A 1px line (`#2e2e2e`) separates sections; there are no boxes.
  - Rows are 34 high, in two columns with a 40 gap. The label (Agency FB Bold, about 16) is on the left and the control is right-aligned.
  - Widths: dropdowns and text inputs 170; sliders a 116 track plus a 46 value box; checkboxes 18; swatches 22.
  - The footer holds Reload UI (left) and Close (right). The close X sits top right, in style A.
- **Fonts:** the window's own font objects use the profile's `fonts.title` face (Colus) and `fonts.normal` face (Agency FB). The sizes are the window's, and the outline comes from the profile.
- **The AceConfig contract** follows AceConfigDialog, for the fields the spec lists:
  - `info` arrays carry `option`, `options`, `arg`, `handler`, `type`, `uiType = 'dialog'` and `uiName = st.name`;
  - `get`, `set`, `validate`, `confirm`, `disabled`, `hidden` and `handler` inherit from parents;
  - method-name strings resolve on the handler;
  - function-valued `name`, `desc`, `values`, `disabled` and `hidden` are called with `info`;
  - `guiHidden` is honored.
- **The nesting rule (spec):**
  - a page's non-inline child groups are tabs, or a picker when `childGroups == 'select'`;
  - inside a tab, non-inline child groups are a second tab row, or a picker for `'select'`;
  - deeper groups are drawn as sections;
  - nothing is dropped.
- **Tests:** model logic, widget value logic and window layout math get tests in `tests/` (`tests/run` must pass). Strict, faithful stubs as `.agents/testing.md` requires; add stubs as needed.
- **Commits:** on the branch you're given. Messages end with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **AceDBOptions' profile table** (inherited handler with method-name strings, `confirm` on execute, function `values`, `description`): every row reads and sets correctly. Pinned by `options_model_test: profiles table` (Task 1).
2. **A group whose `hidden` or `disabled` is inherited from a parent group:** its rows hide or dim. Pinned in Task 1.
3. **A `set` that changes which options exist**, like toggling Enable on a unit frame element: the page re-renders without stale rows. Pinned by `options_window_test: rerender after set` (Task 3).
4. **`st.Config:Open('Unitframes', 'player', 'general')`** from an edit mode click lands on the right page, picker value and tab. Pinned in Task 3.
5. **Dropdown values from a function that depends on another option's value:** they're re-read when the list opens. Pinned in Task 2.

---

### Task 1: The options model

**Files:**
- Create: `SaftUI-Core/Config/optionsmodel.lua`. Add it to both Core TOCs after `Config\config.lua`.
- Test: `tests/core/options_model_test.lua`, using synthetic option tables, AceDBOptions' real table (`SaftUI-Core/Libraries/Ace3/AceDBOptions-3.0`, with whatever AceDB it needs loaded for real if practical), and one real module table, Experience (`SaftUI-Misc/experience.lua`'s `XP:GetConfigTable()`).

**Interfaces (Produces):** `st.OptionsModel` (a plain table):
- `OM.Pages(root) -> { {key, name, desc, category, special} ... }`.
  - `root` is the args table `Config:GetOptionsTable()` returns.
  - Top-level groups are returned in `order`, then by name.
  - `special = 'global'` for the `Fonts` group (named "Global Settings") and `'profiles'` for `profile`.
  - `topmenu` is excluded.
  - A missing `category` gives `'Other'`.
- `OM.BuildView(root, pageKey, selection) -> view`, where `selection = { tab=key, subtab=key, pick=key }`, each nil for the first.
  - `view = { title, desc, tabs = { {key, name} }, tab, subtabs, subtab, picker = { name, values = { {key, name} }, selected } | nil, sections = { { title, note, rows = { row } } } }`
  - `row = { key, type, name, desc, width = 'normal'|'full', disabled, path = { keys from root }, option }`.
  - Rows in each section are in `order` (AceConfig's default 100), then by key.
  - Hidden and `guiHidden` options and groups are omitted.
  - A page's own direct options form an untitled first section. A `header` option starts a new section titled with its name.
- `OM.Info(root, path) -> info`: an AceConfigDialog-style info array for the option at `path`.
- `OM.Get(root, row) -> ...values`; `OM.Set(root, row, ...) -> ok, err`.
  - `Set` runs `validate` first. A string or false result returns `false, message`.
  - `Set` doesn't handle `confirm`; the window asks first.
- `OM.Values(root, row) -> { {key, name} }`, sorted by `sorting` if given, otherwise by name. It's re-read on every call.
- `OM.Confirm(root, row) -> nil | text`: the confirm prompt text, if the option confirms.
- `OM.Search(root, text) -> { {pageKey, path, name, tabName, sectionTitle} }`.
  - It matches names case-insensitively (function names called with `info`), plus section and tab titles.
  - Hidden options are skipped. There are at most 100 results.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_model_test.lua`:
  - `Pages`: order, category default, specials, `topmenu` excluded.
  - Nesting (one synthetic case each):
    - tabs;
    - a picker via `childGroups = 'select'`;
    - a tab with its own child groups (second tab row);
    - a picker inside a tab;
    - a third non-inline level drawn as a section;
    - inline groups as sections with `name` and `desc`.
  - Row order and width: `width = 'full'`/`'double'` give `'full'`; numbers and `'half'` give `'normal'`; `description` gives `'full'`.
  - `hidden` and `disabled`: booleans, functions, and values inherited from a parent group.
  - `get`, `set` and `validate` through a handler with method-name strings, and through inherited `get`/`set`.
  - `info[#info]` equals the option key, `info.arg` is passed through, and `info.options` is the root.
  - `Values`: a function that depends on another setting is re-read after that setting changes.
  - `Confirm`: `confirm = true` uses `confirmText`, otherwise "Are you sure?"; a confirm function's return value is used.
  - `Search` finds by option name and by section title, and skips hidden options.
  - **Profiles table:** the AceDBOptions table yields rows. `Get` on its profile select returns the current profile, and `Set` switches profiles on a real AceDB if that loads; otherwise the test checks that the handler method was called with the right `info`.
  - **Experience:** `BuildView` on `XP:GetConfigTable()` gives the General page with its rows, including the Position box merged in.
- [ ] **Step 2: Run** `tests/run tests/core/options_model_test.lua`. Expected: FAIL (the module isn't there).
- [ ] **Step 3: Implement** `optionsmodel.lua`. Mirror AceConfigDialog's own functions where they exist (its `GetOptionsMemberValue`, `CallOptionsFunction` and `BuildSortedOptionsTable` in `SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua`), so the semantics match.
- [ ] **Step 4: Run** `tests/run`. Expected: everything passes.
- [ ] **Step 5: Commit.** Message: `config: options model maps Ace option tables to pages, tabs, sections and rows`.

### Task 2: The widgets and the close button

**Files:**
- Create: `SaftUI-Core/Config/optionswidgets.lua`, in both TOCs after `optionsmodel.lua`.
- Create: `SaftUI-Core/Media/Textures/close.tga`, a 10×10 white pixel-art X with 2px-thick diagonals as in the mockup's SVG, on a transparent background. Generate it with a small script; the script isn't committed.
- Modify: `SaftUI-Core/panels.lua` (`st:CreateCloseButton`) and `SaftUI-Core/constants.lua` (`st.CLOSE_BUTTON_SIZE` becomes `{24, 24}`).
- Modify: `SaftUI-Core/Media/sharedmedia.lua`, or wherever `st.textures` is defined, to register `close`.
- Test: `tests/core/options_widgets_test.lua`.

**Interfaces:**
- Consumes: Task 1's `row` shape, `OM.Get`, `OM.Set`, `OM.Values` and `OM.Confirm`.
- Produces: `st.OptionsWidgets`.
  - `W.Create(parent, rowType) -> widget`, with `widget:Bind(root, row, onChanged)` (reads the value with `OM.Get`, writes with `OM.Set`, then calls `onChanged(ok, err)`), `widget:SetDisabled(bool)`, `widget:GetWidth()` (its fixed width), and `widget:Release()` (back to a pool keyed by type).
  - The types: `toggle` (checkbox), `range` (slider plus value box), `select` (dropdown), `multiselect`, `input`, `color`, `execute`, `keybinding`, `description`.
  - **`select` opens a list:**
    - a scrolling SaftUI list, at most 12 rows tall, one shared list frame;
    - with `dialogControl == 'LSM30_Font'`, each entry is drawn in its own face, from LibSharedMedia's font path;
    - the list closes on a choice, an outside click or Esc.
  - **`range`:**
    - the value snaps to `step`, or `bigStep` while dragging;
    - the box accepts typed numbers, clamped to `softMin`/`softMax`, then `min`/`max`;
    - `isPercent` shows `x%` and stores the fraction.
  - **`color`:** opens `ColorPickerFrame` with the current color (and alpha if `hasAlpha`). It writes on change, and restores the previous color on cancel.
  - **`execute`:** asks through `W.Confirm(text, onYes)` when `OM.Confirm` gives text.
  - **`W.Confirm(text, onYes)`:** a small SaftUI dialog with Yes and No buttons, centered over the window.
- Produces: `st:CreateCloseButton(frame)`.
  - Returns a 24×24 button: the field color fill, a 1px `edge` border with the dark line outside, and the close texture tinted grey.
  - On hover, the border and X turn `colors.text.red`, with a faint red fill. While pressed, the X moves down 1px.
  - A click hides `frame`. It's stored as `frame.close`, fixing the undefined-variable bug.
  - `st:CreateHeader(frame, title, close_button)` (`panels.lua`) gives a close button it's handed the same look, but only when that button was made by `st:CreateCloseButton`. A Blizzard button passed in is left as it is styled today. Don't write new fields onto Blizzard frames (`.agents/taint.md`).

- [ ] **Step 1: Write the failing tests:**
  - slider: snapping, clamping, percent shown and stored;
  - select: values sorted, and a function `values` re-read when the list opens;
  - multiselect `set(info, key, value)`;
  - a toggle's `Bind` reads and writes through `OM`;
  - `execute` with `confirm` asks first, and runs only after Yes;
  - the color widget passes `r`, `g`, `b`, `a` through `set`;
  - `CreateCloseButton`'s click hides the frame, and `frame.close` is the button;
  - a released widget is reused for the same type.
- [ ] **Step 2: Run** `tests/run tests/core/options_widgets_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** the widgets, the texture and the close button.
- [ ] **Step 4: Run** `tests/run`. Expected: everything passes.
- [ ] **Step 5: Commit.** Message: `config: SaftUI option widgets and a new close button`.

### Task 3: The window and its wiring

**Files:**
- Create: `SaftUI-Core/Config/optionswindow.lua`, in both TOCs after `optionswidgets.lua`.
- Modify: `SaftUI-Core/Config/config.lua`.
  - `Open`, `Close`, `GetWindow`, the profile-change rebuild and `PLAYER_REGEN_DISABLED` use the new window instead of AceConfigDialog and `st.AceSkin`.
  - `GetOptionsTable` no longer adds `topmenu`; commands become sidebar buttons.
  - The options table is still registered with AceConfigRegistry, so `Refresh` → NotifyChange → re-render.
- Modify: each module's top-level `GetConfigTable` adds `category`:
  - **Frames:** Unitframes, ActionBars, Inventory (bags), Chat, Minimap, MicroMenu;
  - **Combat:** Auras, SwingTimer, TotemBar;
  - **Info:** Loot, Experience, Tooltip.

  Fonts stays special.
- Test: `tests/core/options_window_test.lua`.

**Interfaces:**
- Consumes: Task 1's `OM.*` and Task 2's `W.*` and `st:CreateCloseButton`.
- Produces: `st.OptionsWindow`.
  - `OW:Open(path)`, `OW:Close()`, `OW:IsShown()`, `OW:Render()`, `OW:GetFooter() -> frame`.
  - `OW:Navigate(pageKey, selection)`; `OW:SetStatus(text)` for validate errors.
  - `OW:Open(path)` turns a path of option keys into page, picker, tab and subtab.
  - `OW:GetFooter()` is the region between Reload UI and Close, for edit mode's controls.
- **The window** is SaftUI frames, laid out as the mockup:
  - **The sidebar:** Edit mode and command buttons; Global Settings; Profiles; categories in a fixed order (Frames, Combat, Info, then Other); entries in `order`, then by name.
  - **The header:** title and description. The close X sits at top right, made by `st:CreateCloseButton`.
  - **Tabs:** a row of tabs, and a second row when there are subtabs. The picker row is a label and a dropdown. A search box sits at the right of the tab row.
  - **The body:** a scroll frame, with sections laid out by `OW.LayoutRows(rows) -> { {row, col = 1|2|'full', y} }`. This is a pure function, exposed for tests.
  - **The footer:** Reload UI, the edit mode region, and Close. A status line shows validate errors.
- **Behavior:**
  - **Moving:** drag by the header. The position is saved to `st.config.global.optionsWindow = { point, x, y }` and restored.
  - **Esc:** a keyboard catcher that only exists while the window is open closes it. It propagates every other key, and is off in combat.
  - **Re-rendering:** after a widget's set, and on AceConfigRegistry's `ConfigTableChange` for `st.name`. The page, tab and picker stay selected when they still exist.
  - **Search:** typing shows a results page grouped by page, tab and section. Clicking a result navigates to it.

- [ ] **Step 1: Write the failing tests:**
  - `LayoutRows`: normal rows alternate columns 1 and 2 in order; a full row takes both and starts a new line; `y` steps by 34.
  - `Open({'Unitframes','player','general'})` selects the page, picker value and tab, using a synthetic table shaped like Unitframes.
  - `rerender after set`: a set that hides an option removes its row on the next render.
  - The sidebar order and categories.
  - `GetWindow()` is truthy only while the window is open.
  - The position save and restore.
  - `PLAYER_REGEN_DISABLED` closes the window.
  - `Open` in combat refuses.
- [ ] **Step 2: Run** `tests/run tests/core/options_window_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** the window and wire `config.lua`. Add `category` to the module tables.
- [ ] **Step 4: Run** `tests/run`. Expected: everything passes.
- [ ] **Step 5: Commit.** Message: `config: SaftUI draws /sui itself, with sidebar, tabs, sections and search`.

### Task 4: Move the remaining Ace window users and remove the skin

**Files:**
- Modify:
  - `SaftUI-Core/EditMode/footer.lua`: attach its buttons to `st.OptionsWindow:GetFooter()` while edit mode is on and the window is open; drop `st.AceSkin`.
  - `SaftUI-Unitframes/config/config.lua`: `UF:OpenCopyTable` shows its options table in a small SaftUI dialog drawn with `st.OptionsModel` and `st.OptionsWidgets`. Add a minimal `OW:OpenDialog(title, optionsTable)` to `optionswindow.lua` for it.
  - `SaftUI-ActionBars/bindings.lua`: replace `LibStub('AceConfigDialog-3.0'):Close(st.name)` with `st.Config:Close()`.
- Delete: `SaftUI-Core/Config/aceskin.lua`, and its line in both Core TOCs. AceConfigDialog and AceGUI stay loaded as libraries for other addons; SaftUI just stops using them.
- Modify docs:
  - `.agents/edit-mode.md`: the `/sui` options section describes the new window, the model, the widgets and the mapping rules; the Ace skin text goes.
  - `README.md` Usage: `/sui` describes the sidebar, sections and search.
  - `.agents/architecture.md`, if it mentions AceConfigDialog or the skin.
- Test: extend `tests/core/editmode_grid_test.lua` (the footer buttons attach to the new footer), and `tests/unitframes/profiles_test.lua` or a new test for the Copy dialog opening.

- [ ] **Step 1: Write the failing tests:**
  - the edit mode footer buttons are parented to the options footer when edit mode is on and the window is open, and hidden otherwise;
  - `UF:OpenCopyTable` opens a SaftUI dialog whose rows come from its table.
- [ ] **Step 2: Run** `tests/run`. Expected: those fail.
- [ ] **Step 3: Implement** the moves. Delete `aceskin.lua`.
- [ ] **Step 4: Check nothing still uses the old window:** `grep -rn "AceConfigDialog\|AceGUI\|AceSkin" --include='*.lua' SaftUI-* | grep -v Libraries` finds nothing.
- [ ] **Step 5: Run** `tests/run`. Expected: everything passes.
- [ ] **Step 6: Commit.** Message: `config: edit mode, UF copy and keybinds on the new window; Ace skin removed`.

## In-game checks (for the user, after all tasks)

- `/sui` opens the new window: sidebar, Colus titles, sections with lines, aligned two-column rows, and the close X (style A) with its red hover. Esc closes it.
- Every module's options are present and work: toggles, sliders (drag and type), dropdowns (font lists show their fonts), color swatches (Blizzard's picker, cancel restores), and buttons with confirmations.
- Unit frames: the unit picker and element tabs work. Copy from opens the SaftUI dialog.
- Profiles: switch, copy, reset and delete work.
- Edit mode: clicking a frame opens its page. The footer shows Grid, Snap and the size steppers. Dragging updates the Position fields live.
- The window remembers where you put it. Entering combat closes it.
- Keybind mode (`/sui kb`) still works and closes the options.
