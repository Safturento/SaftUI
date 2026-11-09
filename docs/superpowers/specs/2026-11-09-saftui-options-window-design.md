# SaftUI options window: SaftUI's own window for Ace's option tables

Date: 2026-11-09. Status: draft for the user's review.

This is project 1 of 3 in the options redesign the user asked for on 2026-11-09:
1. **This spec:** the new window.
2. Re-sorting each module's settings into sections, plus the options the 2026-11-09 settings audit found missing.
3. A Global Settings page with editable fonts, templates and colors, re-applied live across modules.

Projects 2 and 3 get their own specs.

## Intent

`/sui` today is AceConfigDialog with SaftUI's scoped reskin (`SaftUI-Core/Config/aceskin.lua`). The user finds it "very cramped and disorganized":
- AceGUI's flow layout drops widgets into rows wherever they fit, labels sit above controls, and items don't line up. Some even touch.
- Pages have no structure beyond bordered boxes. Position gets a box, and everything else on a page is "just kinda tossed in together with no structure".

The user likes EllesmereUI's options window (screenshots shared in chat, 2026-11-09) as inspiration, "not a copy, keep the saftui style and fonts". A clickable mockup was built and approved ("that looks FANTASTIC"). It's committed at `docs/superpowers/specs/assets/2026-11-09-options-window-mockup.html` and is the visual reference for this spec.
- To view it with SaftUI's fonts, serve it with Colus, Agency FB and Homespun from `SaftUI-Core/Media/Fonts/` under `/files/`.
- Opened directly, it falls back to other fonts. The layout still shows.

## What the user decided

- **The layout follows the mockup:**
  - a sidebar;
  - a page title in Colus, with a one-line description;
  - tabs;
  - for modules with many of something, a picker;
  - titled sections separated by thin lines, never boxed;
  - in each section, two aligned columns of rows, with the label on the left and the control on the right;
  - Reload UI and Close at the bottom.
- **Fonts:** section titles (and the page title) in Colus; labels and values in Agency FB. Quoting the user: "section titles could use colus, we could use agency fb for the labels and values".
- **Structure:** sections are "separated by a line to keep things structured without having an excessive amount of borders".
- **A close X at the top right, style A from the mockup:**
  - a small dark square with the window's grey border and a pixel-art X;
  - on hover, the border and X turn red and the square takes a faint red tint;
  - it replaces SaftUI's current close button (`st:CreateCloseButton`, a 20×10 red bar with no X or hover) everywhere. The user wanted to "use that as an opportunity to improve on it".
- **How it's built:** SaftUI draws its own window. In the user's words: "I'm okay with dropping ace's gui but keeping everything else."
  - **Kept:** AceDB (profiles), AceConfig's option-table format (every module's `GetConfigTable`), AceDBOptions' profile table, AceConfigRegistry.
  - **Dropped:** AceConfigDialog and AceGUI, for SaftUI's options.
- **Order:** this window first, then the module re-sort, then Global Settings.

## Goals

- **Every option every module exposes today works in the new window on day one, as is,** with no module rewritten. The window reads the same `Config:GetOptionsTable()` tree.
- **The window matches the mockup's layout, look and fonts.**
- **Everything that opens or drives `/sui` today still works:**
  - `/sui`, `/sui edit`, `/sui kb`, and the commands added with `st.Config:AddCommand`;
  - edit mode's click-to-open (`st.Config:Open(path…)`, a mover's `configPath`);
  - `st.Config:Refresh()`, `st.Config:GetWindow()`, closing on entering combat, refusing to open in combat.
- **Edit mode's footer controls** (Grid, Snap to grid, Snap to frames, and the − size + steppers from `SaftUI-Core/EditMode/settings.lua`) live on the new window's footer while edit mode is on.
- **The unit frame "Copy from" dialog** (`UF:OpenCopyTable`, `SaftUI-Unitframes/config/config.lua`) and keybind mode's close of the options (`SaftUI-ActionBars/bindings.lua`) stop using AceConfigDialog.
- **AceConfigDialog, and SaftUI's reskin of it, are removed** from SaftUI's code paths once nothing uses them. Other addons' Ace windows are untouched.

## Non-goals

- Re-sorting modules' settings into sections, and adding missing options. That's project 2.
- Editable fonts, templates and colors, and live appearance refresh. That's project 3. The mockup's Global Settings page is drawn there, not here.
- Changing what any setting does.
- A window scale setting. The window lives at SaftUI's pixel-perfect scale.

## Anti-goals

- **Rows that don't line up,** controls that touch, or widths that change with their neighbors.
- **Boxes around sections.**
- **Taint.** The window and every widget are SaftUI frames. Blizzard is used only through what `.agents/taint.md` allows; for example, the color picker opens Blizzard's `ColorPickerFrame` through its public API, without writing onto it.
- **A module's options going missing,** or behaving differently than in AceConfigDialog: `get`, `set`, `validate`, `confirm`, `disabled`, `hidden`, `order` and inherited handlers.

## How Ace's tables map onto the window

These follow from AceConfig's own semantics:
- **A top-level module group** is a sidebar entry, and its page:
  - the group's `name` is the page title;
  - its `desc` is the description line.
- **Child groups that aren't inline** are the page's tabs. This holds whether the parent says `childGroups = 'tab'` or leaves it at the default `'tree'`; the window has no nested tree. If a tab has child groups of its own, those become tabs too, in a second tab row or as the picker below.
- **`childGroups = 'select'`** turns the child groups into the picker: the unit and bar dropdowns in the mockup.
- **Inline groups** (`inline = true`, or `childGroups = 'inline'` on the parent) are sections. The section title is the group's `name`, and any `desc` is a note line under it.
- **Options in a group** are rows, in `order`, in two columns row by row: left, right, left, right.
  - An option with `width = 'full'` or `'double'` spans both columns.
  - A `description` is a full-width text line.
  - A `header` starts a new section titled with its name.
- **Rows** show `name` as the label, the control on the right, and `desc` as the tooltip. A disabled option shows dimmed and doesn't respond.
- **Widgets,** by type:
  - `toggle`: the checkbox;
  - `range`: the slider with a value box (min, max, step, `bigStep`, `isPercent`);
  - `select`: the dropdown list (`values`, `sorting`, `style = 'radio'` drawn as a dropdown);
  - `multiselect`: a list of checkboxes;
  - `input`: a text box (plus `multiline`);
  - `color`: the swatch, with `hasAlpha`;
  - `execute`: a button;
  - `keybinding`: a key-capture box;
  - `description`: text, and `image` if present.
- **What happens on set:**
  - `validate` failures show in a status line on the footer, as AceConfigDialog's status text does today.
  - `confirm` asks in a SaftUI confirm dialog.
  - A `set` re-renders the page, the way AceConfigRegistry's NotifyChange would.

## Builder's calls (marked so the user can reject any)

- **The sidebar:**
  - **The top:** two buttons (Edit mode and Keybinds), then Global Settings and Profiles, then the module groups.
  - **Global Settings, for now,** holds what Core shows today, which is Fonts, until project 3 fills it out.
  - **The module groups:**
    - each module declares its group by adding a `category` field to its top-level group table;
    - the first grouping is Frames, Combat and Info, as in the mockup;
    - modules that don't declare one go under "Other".
- **Size and position:** the window is a fixed size, about 1040×700 in pixel-perfect units, with the same proportions as the mockup. It moves by dragging its title area, and its position is remembered, account-wide. It isn't resizable; the body scrolls instead.
- **Keyboard:** Esc closes the window, through a SaftUI keyboard catcher like edit mode's, not by adding to Blizzard's `UISpecialFrames` table.
- **Search:** the search box filters settings by name across every module. Results show as a page of rows grouped by module, tab and section, and clicking one goes to that page.
- **Fonts:** the window makes its own font objects from the profile's Colus (`fonts.title`) and Agency FB (`fonts.normal`) faces, at sizes fixed by the window. Page titles are about 34px, section titles about 15px, labels about 16px and values about 15px. That way the profile's 72px title size doesn't apply, but its face does.
- **The close X:**
  - It's a crisp pixel-art X texture drawn for SaftUI, added to `SaftUI-Core/Media/Textures/`. A rotated line would blur.
  - `st:CreateCloseButton` makes it, and every SaftUI window that has a close button gets it. Its bug of storing the button under an undefined `close_button` variable is fixed on the way.
- **The edit mode footer:** while edit mode is on, the window's footer holds the Grid, Snap to grid and Snap to frames toggles and the size steppers, between Reload UI and Close. `EditMode/footer.lua` is adapted to the new footer.
- **The unit frame "Copy from" dialog** becomes a small SaftUI dialog drawn by the same widgets.

## Builder's calls after the builder check

These answer the builder check's questions. They're marked so the user can reject any of them.

- **Font dropdowns keep their preview.** Selects with `dialogControl = 'LSM30_Font'` (in `SaftUI-Core/Media/fonts.lua`, `SaftUI-ActionBars/options.lua` and `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua`) open a scrolling list with each font name drawn in its own face, as AceGUI's LibSharedMedia widget does today. Any other `dialogControl` gets the plain dropdown.
- **What the window draws:**
  - It draws the tree `Config:GetOptionsTable()` returns, including its current reshaping: `MergePositionIntoGeneral` and `UseTabsForInnermostSections` stay until project 2 makes them unnecessary.
  - The `topmenu` group is dropped from that tree. Its buttons become the sidebar's top buttons: Edit mode, plus one per `st.Config:AddCommand` entry (Keybinds today).
  - The mapping tests run on that same tree.
- **The nesting rule:**
  - Level 1 is a sidebar page.
  - A page's non-inline child groups are its tabs, or the picker when the page says `childGroups = 'select'`.
  - Inside a tab, non-inline child groups are a second tab row, or the picker when the tab says `'select'`.
  - Anything deeper, non-inline or not, is drawn as sections on that page, and is never dropped.
  - The deepest nesting in the repo today fits this: for example, Unitframes > unit > element tabs > sections, ActionBars > bar > tabs, and Inventory > window > General/Position.
- **The sidebar groups ship with this project.** Each module's top-level group gets a one-line `category` (Frames, Combat or Info), so the grouping shows on day one.
  - Fonts (Core's only section today) shows as Global Settings.
  - Profiles is AceDBOptions' table.
  - Project 2 can rename or regroup.
- **The AceConfig contract is implemented as AceConfigDialog implements it,** for every field the repo's tables and AceDBOptions' table use:
  - `info` tables (`info[#info]`, `info.option`, `info.options`, `info.arg`, `info.handler`, `info.type`, `info.uiType = 'dialog'`, `info.uiName`);
  - `handler` with method-name strings;
  - `get`/`set`/`handler`/`disabled`/`hidden`/`validate` inherited from parent groups;
  - function-valued `name`/`desc`/`values`/`disabled`/`hidden`;
  - `guiHidden`;
  - numeric `width` (relative to a standard column);
  - `confirm`/`confirmText`;
  - `multiselect`'s `get(info, key)` / `set(info, key, value)`.

  AceDBOptions' profile table is the acceptance test for this. Fields neither uses (`cmdHidden`, `descStyle`, `tooltipHidden`, …) are ignored.
- **Refreshing:** the window re-renders after its own `set`, and whenever AceConfigRegistry fires `ConfigTableChange` for SaftUI's table. `Config:Refresh()` still calls NotifyChange, so edit mode's live position updates and every module's existing refresh calls keep working.
- **The edit mode footer:** as today, edit mode's controls show on the window's footer only while edit mode is on and the window is open. Edit mode keeps working with the window closed; the controls just aren't shown.
- **The window position** is stored in AceDB's account-wide `global` namespace, which `st.config` already has, under one key for the window.
- **Search:**
  - It matches option names, evaluating function names with a proper `info` table, plus section and tab titles.
  - Hidden options and `guiHidden` options aren't searched. Descriptions and `desc` text aren't searched.
- **Order of work:** the permanent test suite (`tests/`) is being finished now and lands on `modular` before this project starts.
- **The unit frame Copy dialog** uses only `select`, `multiselect`, `toggle` and `execute`, with function-valued `values`, all covered by the contract above.

## Constraints

- **Clients:** WoW Forever (16001, the one the user plays) and retail (120000).
- **Taint:** `.agents/taint.md` applies. All frames are SaftUI's, with no writes onto Blizzard frames or tables.
- **Tests:** the permanent test suite (`tests/`, see `.agents/testing.md`) is expected to cover the logic that can be checked outside the game:
  - mapping the option table onto pages, tabs, sections and rows;
  - row order and the two-column flow;
  - `disabled`/`hidden`;
  - the `get`/`set`/`validate` plumbing;
  - search filtering.

  Looks are checked in game.
- **Docs:** `.agents/edit-mode.md` (its `/sui` options and Ace skin sections) and `README.md` (Usage) are updated. The scoped Ace skin's description goes away with the skin.

## Left to the builder

- The file layout under `SaftUI-Core/Config/`.
- How widgets are pooled and reused across page changes.
- The exact colors and alphas, within SaftUI's palette (`st.config.profile.colors`, the thick template) and the mockup.
- How the dropdown's list and the confirm dialog are drawn.
- How the window re-renders after a `set`: the whole page, or only what changed.
