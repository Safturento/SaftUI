# SaftUI Edit Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add SaftUI's own edit mode. Registered frames get a draggable, nudgeable, clickable overlay. Clicking one opens a SaftUI-skinned Ace settings window with a sidebar. The minimap is the first and only registered frame in this version.

**Architecture:**
- A new Core module, `EditMode` (`SaftUI-Core/EditMode/`), owns the mover registry, the overlays, dragging and nudging, entering and leaving edit mode, the grid and snapping, and the settings window.
- Modules register frames through `st:RegisterMover(key, def)`, supplying position get/set, an apply callback and an AceConfig options provider.
- Positions live only in the AceDB profile.
- The settings window is AceConfigDialog rendered into a SaftUI-owned AceGUI `Frame`. A scoped reskinner (`SaftUI-Core/Config/aceskin.lua`) styles only widgets inside SaftUI's windows.

**Tech Stack:** WoW addon Lua (retail Midnight 120000 and WoW Forever 16001), Ace3 (AceAddon, AceDB, AceConfig, AceConfigDialog, AceConfigRegistry, AceGUI). Already loaded by SaftUI-Core.

**Spec:** `docs/superpowers/specs/2026-11-06-saftui-edit-mode-design.md`

## Global Constraints

- **Clients:** both must load without errors.
  - Retail (Midnight, interface 120000).
  - WoW Forever (interface 16001). The user plays Forever now.
  - `st.retail` is true on both; `st.forever` only on Forever.
- **Never write onto Blizzard Edit Mode frames.** No fields, no method replacement, no `st:Kill` on `MinimapCluster` or its `Selection`.
  - SaftUI only listens for Blizzard's Edit Mode, through `EventRegistry` callbacks `"EditMode.Enter"` / `"EditMode.Exit"`. These exist on Forever (`EditModeManager.lua` `TriggerEvent`); verify on `live`.
  - Use `hooksecurefunc` / `HookScript` only.
- **Profile is the only source of truth for positions.**
  - Shape: `{ point, frame, rel_point, x_off, y_off }`, read with `st:UnpackPoint`.
  - Never use `StartMoving` / `SetUserPlaced`.
- **Pixel perfect:** every offset or size written by edit mode is rounded with `st:RoundToPixel`.
- **Combat:**
  - Edit mode closes on `PLAYER_REGEN_DISABLED`.
  - `Enable` refuses while `InCombatLockdown()`.
  - Both cases print a chat message.
- **Scoped Ace reskin:** only SaftUI windows (edit mode settings and `/sui`) are restyled. Every other addon's Ace windows look stock. Restyled widgets are restored when AceGUI releases them.
- **`/sui` and `/saftui`** still open the full options window, now with an **Edit mode** button. `/sui edit` toggles edit mode.
- **Commits:** lowercase `area: description` (e.g. `core: add edit mode mover registry`). End with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Work on branch `modular`. Never push.
- **Line endings:** LF (enforced by `.gitattributes`). Match surrounding indentation in each file (Core uses tabs; some Minimap files use 4 spaces).
- **Blizzard source reference:** `gh api "repos/Gethe/wow-ui-source/contents/<path>?ref=<live|forever>" -H "Accept: application/vnd.github.raw"`.

## Verification model

There is no Lua interpreter or test runner in this environment, and the game can't run here. Each task's verification is:

- **Implementer and reviewer:** a careful read-through for syntax and API correctness against Blizzard source and Ace3 source (in `SaftUI-Core/Libraries/Ace3`).
- **User:** the in-game checklist in the task, run on Forever after `/reload`.

The orchestrator pauses after each task for the user's in-game result before starting the next.

## Review Focus

1. **Combat starts mid-drag or mid-nudge:** the drag stops, the frame stays where it was last written, the profile holds a valid numeric position, and edit mode closes with a message. *(Task 2)*
2. **Bad typed anchors:** a typed relative frame that doesn't exist, is the frame itself, or depends on the frame (anchor loop) is rejected with a message, and the old anchor stays. *(Task 1 `st:ValidateAnchor`, used by Task 1's position generator and Task 4's window)*
3. **UI scale not equal to `768/screenHeight`:** for example, the user changed Blizzard's UI scale, or the frame has its own scale. Drags and nudges still land on whole physical pixels, and a nudge moves exactly 1 physical pixel. *(Task 1 `st:RoundToPixel`, used by Task 2)*
4. **Blizzard Edit Mode closes while a SaftUI settings window is open, or during a drag:** everything SaftUI closes cleanly. Blizzard's drag of `MinimapCluster` never moves SaftUI's minimap. *(Tasks 2, 3)*
5. **`/reload` and profile switch after editing:** the frame comes back exactly where it was left, and a profile switch re-applies the new profile's position. *(Tasks 2, 3)*

---

### Task 1: Pixel and anchor helpers, and the position editor fix

**Files:**
- Modify: `SaftUI-Core/api.lua` (add helpers near `st:UnpackPoint`)
- Modify: `SaftUI-Core/Config/widgets.lua:49-112` (`generators.position`)

**Interfaces:**
- **Produces:**
  - `st:RoundToPixel(value: number, frame: Region|nil) -> number`
  - `st:ResolveFrame(ref: string|Region|nil) -> Region|nil`
  - `st:ValidateAnchor(frame: Region, relative: string|Region) -> true | (false, errorMessage: string)`
  - `generators.position(order, global_frame, get, set)`: same signature as today, with fixed behavior.

- [ ] **Step 1: Implement `st:RoundToPixel` in `api.lua`.**
  - Physical pixel size in the frame's coordinate space is `(768 / physicalHeight) / (frame or UIParent):GetEffectiveScale()`, where `physicalHeight = select(2, GetPhysicalScreenSize())`.
  - Return the value rounded to the nearest multiple of that size.
  - Handle negatives symmetrically, so `-0.6px` rounds to `-1px`.
- [ ] **Step 2: Implement `st:ResolveFrame`.**
  - A string resolves to `_G[ref]`; a table with `GetObjectType` is returned as-is; anything else returns nil.
- [ ] **Step 3: Implement `st:ValidateAnchor`.**
  - Fail with `"Frame doesn't exist"` when the frame can't be resolved.
  - Fail with `"Can't anchor a frame to itself"` when it is the frame itself.
  - Fail with `"Anchor would create a loop"` when the relative frame, through any of its points' relative frames recursively (`GetNumPoints` / `GetPoint(i)`, visited set), reaches `frame`. Also fail when `relative` is a descendant of `frame` (walk `GetParent`).
- [ ] **Step 4: Fix `generators.position`.**
  - `x_off` / `y_off` get displayed with `tostring`. On set they are stored with `tonumber`, after rounding with `st:RoundToPixel(value)`.
  - Input `pattern` becomes `'^%-?%d+%.?%d*$'`.
  - The `frame` input's `validate` resolves the frame being edited only when the caller passes it. Add an optional 5th parameter `target: Region|nil`. If set, validate with `st:ValidateAnchor(target, name)`; otherwise keep today's existence check.
  - The current `get`/`set` contract with callers is unchanged.
- [ ] **Step 5: Self-review.** Check every changed line for Lua syntax and that no caller of `generators.position` breaks:
  - `grep -rn "generators.position\|uf_element_position" SaftUI-*`
- [ ] **Step 6: In-game check (user).** `/reload` is clean. In `/sui` → Maps → Minimap → Position, typing `-25` into X is accepted and moves the minimap. Typing `NoSuchFrame` into Frame is rejected.
- [ ] **Step 7: Commit:** `core: add pixel rounding and anchor validation helpers`

---

### Task 2: Edit mode core (registry, overlays, drag, nudge, enter/exit) and `/sui` hookup

**Files:**
- Create: `SaftUI-Core/EditMode/editmode.lua` (module, registry, enter/exit, combat)
- Create: `SaftUI-Core/EditMode/mover.lua` (overlay creation, drag, nudge, selection)
- Create: `SaftUI-Core/EditMode/load.xml`
- Modify: `SaftUI-Core/SaftUI-Core_Mainline.toc` and `SaftUI-Core/SaftUI-Core_Forever.toc`: add `EditMode\load.xml` after `Config\widgets.lua`. Check for any other Core TOC with `ls SaftUI-Core/*.toc`.
- Modify: `SaftUI-Core/Config/defaults.lua`: add `st.defaults.editmode = { grid = false, snap = false }`.
- Modify: `SaftUI-Core/Config/config.lua`:
  - Slash handler: `/sui edit` toggles; anything else opens options as today.
  - `topmenu.args`: add an `edit_mode` execute button named `Edit mode`, replacing the commented `toggle_movers` stub.

**Interfaces:**
- **Consumes:** `st:RoundToPixel`, `st:ResolveFrame` (Task 1); `st:CreateFrame`, `st:SetBackdrop`, `st:GetFont`, `st:Print` (Core).
- **Produces:**
  - `local EM = st:NewModule('EditMode')`, also exposed as `st.EditModeFrames = EM`. Don't reuse `st.EditMode`, which `init.lua` sets to the dead `EditModeExpanded` lib.
  - `st:RegisterMover(key: string, def: MoverDef) -> mover`
    - `MoverDef = { frame: Region, label: string, getPosition: fun(): PositionTable, setPosition: fun(pos: PositionTable), apply: fun(), options: fun(): AceConfigGroup|nil, shared: { key: string, label: string, options: fun(): AceConfigGroup }|nil }`
    - `PositionTable = { point, frame, rel_point, x_off, y_off }`
  - Edit mode on/off: `EM:Activate()` / `EM:Deactivate()` / `EM:Toggle()` / `EM:IsActive()` so they don't clash with AceAddon's module `Enable` / `Disable` / `IsEnabled`.
  - `EM:Select(mover|nil)` sets the selected mover.
  - `EM.movers: table<string, mover>`.
  - `EM:CommitPosition(mover, x: number, y: number)` rounds, writes x/y into `def.getPosition()`'s table through `def.setPosition`, then calls `def.apply()` and `EM:Fire('PositionChanged', mover)`.
  - `EM:Fire(event: string, ...)` / `EM:On(event: string, fn)` is a tiny local callback list for Tasks 4 and 5. Events: `'PositionChanged'`, `'Selected'`, `'Enabled'`, `'Disabled'`.

- [ ] **Step 1: Overlay per mover (`mover.lua`).**
  - A `Button` parented to `UIParent` at `FULLSCREEN_DIALOG` strata, `SetAllPoints(def.frame)`, hidden by default.
  - SaftUI backdrop: template `'thick'`. The selected state recolors the border with `st.config.profile.colors.button.blue`.
  - The label is a fontstring using `st:GetFont('pixel')`.
  - Register `LeftButtonUp` clicks. A click without movement selects; Task 4 will also open the window on select.
- [ ] **Step 2: Drag that keeps the anchor.**
  - On `OnDragStart`, record the cursor position (`GetCursorPosition()` divided by `UIParent:GetEffectiveScale()`) and the mover's current `x_off` / `y_off`.
  - `OnUpdate` while dragging: new offset = start offset + cursor delta (in UIParent units, converted to `def.frame`'s scale), passed through `st:RoundToPixel(v, def.frame)`. Re-apply with `ClearAllPoints` + `SetPoint(point, relative, rel_point, x, y)` on `def.frame`. Point and relative stay unchanged.
  - On `OnDragStop`, call `EM:CommitPosition`.
  - Never call `StartMoving`.
- [ ] **Step 3: Nudge.**
  - A single hidden keyboard-catcher frame takes keys while a mover is selected: `EnableKeyboard(true)`, and `SetPropagateKeyboardInput` true for every key except `UP`, `DOWN`, `LEFT`, `RIGHT`, `ESCAPE`.
  - Arrows move 1 physical pixel, Shift+arrow moves 10. The step is `st:RoundToPixel` of the pixel size for `def.frame`.
  - Each nudge calls `EM:CommitPosition`.
  - `ESCAPE` deselects, or disables edit mode when nothing is selected.
- [ ] **Step 4: Enter, exit and combat (`editmode.lua`).**
  - `EventRegistry:RegisterCallback('EditMode.Enter', ...)` calls `EM:Activate()`; `'EditMode.Exit'` calls `EM:Deactivate()`.
  - `PLAYER_REGEN_DISABLED`: if active, stop any drag (commit the last applied offset), `EM:Deactivate()`, and print `Edit mode closed: entering combat.`
  - `EM:Activate()` during `InCombatLockdown()`: print `Can't open edit mode in combat.` and return.
  - `EM:Deactivate()` hides all overlays, deselects, and fires `'Disabled'`.
- [ ] **Step 5: `/sui` hookup** in `config.lua`, per the Files list.
- [ ] **Step 6: Self-review** for syntax, the module name clash, and that no Blizzard Edit Mode frame is written to (`grep -n "EditModeManagerFrame\|MinimapCluster" SaftUI-Core/EditMode`, which should return only the `EventRegistry` usage).
- [ ] **Step 7: In-game check (user).** Nothing is registered yet, so the checks are:
  - `/reload` is clean.
  - `/sui edit` toggles edit mode without errors (nothing visible yet).
  - Opening and closing Blizzard Edit Mode doesn't error.
  - `/sui edit` in combat prints the refusal.
  - The `/sui` window shows an **Edit mode** button.
- [ ] **Step 8: Commit:** `core: add saftui edit mode with draggable movers`

---

### Task 3: Minimap owned by SaftUI and registered as a mover

**Files:**
- Modify: `SaftUI-Minimap/minimap.lua` (`MM:OnEnable`)
- Modify: `SaftUI-Minimap/config.lua` (`MM:UpdateConfig`, plus registration and options split)
- Possibly modify: `SaftUI-Minimap/micromenu.lua` and its siblings, only if something anchored through `MinimapCluster` stops showing once `Minimap` leaves it.

**Interfaces:**
- **Consumes:** `st:RegisterMover` (Task 2); `generators.position` with `target` (Task 1).
- **Produces:**
  - `MM:GetMoverOptions() -> AceConfigGroup`: the minimap's options split into sidebar sections for Task 4:
    - `General`: template, size, compartment_buttons
    - `Position`: `generators.position(…, true, get, set, Minimap)`
  - `MM:GetConfigTable()` keeps returning the `/sui` tree, built from the same option pieces.

- [ ] **Step 1: Move `Minimap` out of the cluster.**
  - In `MM:OnEnable`: `Minimap:SetParent(UIParent)`, keeping the frame level/strata it had (read before reparenting).
  - Remove `st:Kill(MinimapCluster.Selection)` and `MinimapCluster:EnableMouse(false)`.
  - Keep the `GetMinimapShape` override (spec decision).
- [ ] **Step 2: `MM:UpdateConfig`** sizes and positions only `Minimap`, with the size rounded via `st:RoundToPixel`. Remove every `MinimapCluster:SetSize` / `SetPoint`.
- [ ] **Step 3: Re-anchor anything that still lives in `MinimapCluster`** and was visually on the minimap.
  - Check Blizzard's `forever` and `live` minimap XML (`Interface/AddOns/Blizzard_Minimap/...`) for children of `MinimapCluster` other than `Minimap`.
  - Most SaftUI-used pieces are already reparented into the micro menu by `MicroMenu:UpdateButtons`.
  - Anchor anything remaining to `Minimap` or the micro menu, using hooks only. `MM:MiniMapIndicatorFrame_UpdatePosition` currently anchors `IndicatorFrame` to `MinimapCluster.BorderTop`; decide whether that still makes sense, and note the decision in the commit body.
- [ ] **Step 4: Register the mover** in `MM:OnEnable` after `MM:UpdateConfig()`:
  - key `'minimap'`, frame `Minimap`, label `'Minimap'`
  - `getPosition` returns `self.config.position`
  - `setPosition` writes into it
  - `apply = function() MM:UpdateConfig() end`
  - `options = function() return MM:GetMoverOptions() end`
- [ ] **Step 5: Self-review:** `grep -n "MinimapCluster" SaftUI-Minimap/*.lua` should show only reads and `hooksecurefunc`/`SecureHook` targets, no writes.
- [ ] **Step 6: In-game check (user, Forever).**
  - The minimap looks and sits the same as before.
  - Zone text, clock, mail, tracking and the queue button still show in the micro menu.
  - `/sui edit` shows an overlay on the minimap.
  - Dragging moves it with the anchor unchanged (check in `/sui` → Position).
  - Arrow keys move 1px and Shift+arrow 10px.
  - `/reload` keeps the position.
  - In Blizzard Edit Mode, moving Blizzard's minimap box doesn't move SaftUI's minimap.
  - No taint errors in combat after using edit mode.
- [ ] **Step 7: Commit:** `minimap: take minimap out of the cluster and register it as a mover`

---

### Task 4: Scoped Ace reskin and the per-frame settings window

**Files:**
- Create: `SaftUI-Core/Config/aceskin.lua`
- Create: `SaftUI-Core/EditMode/window.lua`
- Modify: `SaftUI-Core/EditMode/load.xml`: add `window.lua`.
- Modify: the Core TOCs: add `Config\aceskin.lua` after `Config\widgets.lua`.
- Modify: `SaftUI-Core/Config/config.lua`: open the `/sui` window through the skinned container.

**Interfaces:**
- **Consumes:** `EM` events and `EM.movers` (Task 2); `def.options` / `def.shared` (Task 2); `st:ValidateAnchor` (Task 1).
- **Produces:**
  - `st.AceSkin:CreateWindow(name: string, title: string) -> AceGUIFrame`: an AceGUI `Frame` that SaftUI owns and that is skinned, with everything later added under it skinned too.
  - `st.AceSkin:IsScoped(widget) -> boolean`
  - `EM:OpenWindow(mover)`, `EM:CloseWindow()`
  - `EM:AddFooterButton(text: string, onClick: fun(button))`, for Task 5's footer buttons.

- [ ] **Step 1: Scoped reskin (`aceskin.lua`).**
  - Mark the root container from `CreateWindow` as scoped.
  - Hook `AddChild` on scoped containers, recursively, so every descendant widget is styled when added. Remember what was changed per widget.
  - `hooksecurefunc(AceGUI, 'Release', ...)` restores originals for scoped widgets only, before the pool reuses them. `AceGUI` is the LibStub table; verify `Release` exists in the bundled `AceGUI-3.0.lua`.
  - **Widget types to cover:** at minimum `Frame`, `TreeGroup`, `InlineGroup`, `SimpleGroup`, `ScrollFrame`, `CheckBox`, `Slider`, `Dropdown` (and its pullout), `EditBox`, `Button`, `Heading`, `Label`, `ColorPicker`, and the LSM30 widgets if `/sui` uses them.
  - **Styling:**
    - backdrops: `st:SetBackdrop(..., 'thick')` / `'thin'`
    - fonts: `st:GetFont('pixel')` or the config's normal font
    - flat checkbox and slider textures
    - hide Blizzard art regions, without `st:Kill` (these are AceGUI frames, but still restore them on release)
- [ ] **Step 2: Settings window (`window.lua`).**
  - On mover select (`EM:On('Selected')`), build an options table `{ type='group', childGroups='tree', args = { [def.label] = def.options(), [shared.label] = shared.options() } }`. Register it as `st.name..'_EditMode'` with AceConfigRegistry.
  - Open it via `AceConfigDialog:Open(appName, window)` into the scoped `CreateWindow` frame.
  - Place the window beside the mover's frame (whichever side has room), clamped to the screen.
  - On `'PositionChanged'`, call `AceConfigRegistry:NotifyChange(appName)` so Position updates live.
  - On `'Disabled'` or deselect, close the window.
- [ ] **Step 3: Footer.** Add a strip at the bottom of the window frame (AceGUI `Frame` has a status bar area; place SaftUI buttons there with `st:CreateButton`). `EM:AddFooterButton` appends to it. Task 5 adds the grid and snap toggles.
- [ ] **Step 4: `/sui` window:** `config.lua` opens `AceConfigDialog:Open(st.name, st.AceSkin:CreateWindow(...))`.
- [ ] **Step 5: Self-review:**
  - Confirm no global `AceGUI:Create` hook styles widgets unconditionally.
  - Confirm every style change has a matching restore.
- [ ] **Step 6: In-game check (user).**
  - In edit mode, clicking the minimap opens a SaftUI-styled window beside it, with a sidebar (General, Position).
  - Changing size or template applies live.
  - Dragging or nudging updates the Position fields live.
  - Typing a bad frame name is rejected.
  - The `/sui` window is SaftUI-styled.
  - Opening another addon's Ace options (e.g. Details or any Ace addon) afterwards still looks stock.
  - Closing edit mode closes the window.
- [ ] **Step 7: Commit:** `core: add skinned settings window for edit mode`

---

### Task 5: Alignment grid and snapping

**Files:**
- Create: `SaftUI-Core/EditMode/grid.lua`
- Create: `SaftUI-Core/EditMode/snap.lua`
- Modify: `SaftUI-Core/EditMode/load.xml`
- Modify: `SaftUI-Core/EditMode/mover.lua` (drag `OnUpdate` calls snapping)

**Interfaces:**
- **Consumes:** `EM:AddFooterButton` (Task 4); `st.config.profile.editmode.grid` / `.snap` (Task 2 defaults); `st.config.profile.grid.horizontalSpacing` / `.verticalSpacing` (existing Core defaults).
- **Produces:**
  - `EM:SetGridShown(shown: boolean)`
  - `EM:Snap(mover, x: number, y: number) -> x: number, y: number`

- [ ] **Step 1: Grid.**
  - A full-screen, click-through frame of 1-physical-pixel lines at the configured spacing, centered on the screen center (thicker or colored center lines).
  - Shown only while edit mode is active and `editmode.grid` is true.
  - Footer button `Grid` toggles it and saves the setting.
- [ ] **Step 2: Snapping.**
  - While dragging with `editmode.snap` true, if any edge or center of the mover's frame is within 6 physical pixels of the matching edge or center of another registered mover's frame, or of the screen center lines, shift the offset so they align.
  - Apply the shift in the frame's current anchor space. Snapping never changes the relative frame (spec builder's call).
  - Result goes through `st:RoundToPixel`.
  - Footer button `Snap: Free` / `Snap: Frames` toggles it and saves.
- [ ] **Step 3: Self-review** for syntax and that grid lines are pixel-snapped (line positions and thickness go through `st:RoundToPixel`).
- [ ] **Step 4: In-game check (user).**
  - The Grid footer button shows and hides the grid, and the choice persists across `/reload`.
  - With Snap on, dragging the minimap near the screen center lines snaps to them. Only one mover exists, so frame-to-frame snapping is verified later when more movers exist.
- [ ] **Step 5: Commit:** `core: add edit mode grid and snapping`
