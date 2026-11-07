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
    - *Superseded by Task 7:* `options`/`shared` were replaced by `configPath: string[]`, the option keys from the `/sui` root to the frame's section.
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

*(Task 7 moved the footer to the `/sui` window: `EM:AddFooterButton` buttons show on `/sui` while edit mode is active.)*

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

---

### Task 6: Loot roll frames and loot feed as movers

*Added 2026-11-07 at the user's request ("the loot window is fixed, can we make that the next movable item?", then chose roll frames + feed). Independent of Task 5.*

**Files:**
- Modify: `SaftUI-Loot/roll.lua`, `SaftUI-Loot/Feed/feed.lua`
- Create: `SaftUI-Loot/options.lua` (option pieces for both movers), added to `SaftUI-Loot/SaftUI-Loot.toc` (check for per-client TOCs too)

**Interfaces:**
- **Consumes:** `st:RegisterMover(key, def)` (Task 2); `st.Config.generators.position(order, global_frame, get, set, target)` (Task 1); the existing generators in `SaftUI-Core/Config/widgets.lua` (template, range, font, toggle); `st:UnpackPoint`.
- **Produces:**
  - `LT:GetRollMoverOptions() -> AceConfigGroup`: `General` (width, height, spacing, template, font, grow_down) and `Position`.
  - `LT:GetFeedMoverOptions() -> AceConfigGroup`: `General` (width, item_height, spacing, max_items, fade_time, template, font) and `Position`.
  - Mover keys `'lootroll'` (label `'Loot Rolls'`) and `'lootfeed'` (label `'Loot Feed'`).

- [ ] **Step 1: Roll anchor owned by SaftUI.** `GroupLootContainer` is a Blizzard bottom-managed frame (`BottomManagedFrameTemplate`), so SaftUI must not move or size it.
  - Create a SaftUI frame (e.g. `SaftUILootRollAnchor`) on UIParent, sized `roll.width` x `roll.height` and positioned from `loot.roll.position`.
  - In the `GroupLootContainer_Update` hook, anchor the first roll frame to that anchor (TOP or BOTTOM per `grow_down`) instead of to the container. Roll frames stay parented where Blizzard puts them.
  - Remove SaftUI's writes onto `GroupLootContainer`: `container:SetHeight`, `GroupLootContainer:SetWidth`, the `GroupLootContainer.Selection:SetFrameStrata` line, and the `UIPARENT_MANAGED_FRAME_POSITIONS.GroupLootContainer = nil` write. Replace the old no-op `st:RegisterEditMode` registration (`LT:RegisterRollFrameEditMode`) with the mover.
- [ ] **Step 2: Feed.** The feed frame (`SaftUILootFeed`) is already SaftUI's. Position it only from `loot.feed.position` (drop the `st:RegisterEditMode` branch), and make re-applying the position a function the mover's `apply` can call.
- [ ] **Step 3: Register both movers** after their frames exist, in the same shape as the minimap (`SaftUI-Minimap/minimap.lua`, `SaftUI-Minimap/config.lua` `MM:GetMoverOptions`). `apply` re-applies position and size and must be safe in combat lockdown (these frames are not protected). Option `set`s apply live.
- [ ] **Step 4: Visible while editing.** The roll anchor is empty unless a roll is up and the feed fades when idle. The overlays must still be clickable and show the frames' footprint in edit mode. The overlay covers the anchor and feed frames themselves, so they need real sizes even when nothing is showing.
- [ ] **Step 5: Self-review:** `grep -n "GroupLootContainer" SaftUI-Loot/*.lua` shows only reads, `rollFrames` iteration, and `SecureHook` targets.
- [ ] **Step 6: In-game check (user).**
  - `/sui edit` shows outlines for Loot Rolls and Loot Feed.
  - Dragging each moves it; clicking opens its window with General and Position.
  - On the next group roll, rolls stack from the new spot (up or down per Grow down).
  - New loot shows in the feed at its new spot.
  - `/reload` keeps both positions.
  - No errors or taint in combat after using edit mode.
- [ ] **Step 7: Commit:** `loot: make loot rolls and the loot feed edit mode movers`

---

### Task 7: One settings window: clicking a frame selects its section in `/sui`

*Added 2026-11-07 at the user's request, replacing Task 4's per-frame window (spec: "Settings window", revision 2026-11-07). Runs before Task 5, whose footer buttons now go on `/sui`.*

**Files:**
- Modify: `SaftUI-Core/EditMode/editmode.lua` / `mover.lua` (selection → open `/sui` at the mover's section), `SaftUI-Core/Config/config.lua` (opening `/sui` and selecting a path, footer while edit mode is active)
- Delete or reduce: `SaftUI-Core/EditMode/window.lua` (keep only the footer API, re-pointed at `/sui`); the cross-window relay and `LinkOptions` in `SaftUI-Core/Config/aceskin.lua` if nothing else needs them with one window
- Modify: `SaftUI-Minimap/config.lua` (`MM:GetConfigTable` becomes a tree section with General and Position subgroups); `SaftUI-Loot/options.lua` plus a new `LT:GetConfigTable` (Loot → Rolls, Feed, each with General and Position)
- Modify: the `st:RegisterMover` calls in `SaftUI-Minimap/minimap.lua`, `SaftUI-Loot/roll.lua`, `SaftUI-Loot/Feed/feed.lua`

**Interfaces:**
- **Consumes:** `st:RegisterMover`, `EM:On('Selected')` (Task 2); `st.AceSkin:CreateWindow`, `EM:AddFooterButton` (Task 4); `Config:Refresh()` / `AceConfigRegistry:NotifyChange(st.name)`.
- **Produces:**
  - `def.configPath`: an array of option-table keys from the `/sui` root to the frame's section, e.g. `{ 'Minimap', 'general' }` (it ends at a leaf group, since selecting a node that only holds subgroups shows an empty pane). It replaces `def.options`.
  - `st.Config:Open(...)`: opens the skinned `/sui` window if needed and, given a path, selects it via `AceConfigDialog:SelectGroup(st.name, ...)`. The `/sui` slash command uses it too.
  - `EM:AddFooterButton(text, onClick)`: same signature as before, but the buttons sit on the `/sui` window's footer and show only while edit mode is active, keeping validation status text clear of them.

- [ ] **Step 1: Sections in `/sui`.** Each mover's options become a non-inline group in the `/sui` tree with General and Position subgroups, reusing the existing option pieces (`MM:GetOptionPieces`, `SaftUI-Loot/options.lua`). Keep every SetPoint field, including the typed relative frame validated with `target`.
- [ ] **Step 2: Select on click.** `EM:On('Selected', mover)` calls `st.Config:Open(unpack(def.configPath))`. Re-selecting while `/sui` is open just switches the tree selection. Deselecting doesn't close `/sui`, and closing `/sui` doesn't change edit mode.
- [ ] **Step 3: Remove the second window.** Drop the edit mode app (`SaftUI_EditMode`), its placement code, and anything that only existed to sync two windows. Drags and nudges still refresh `/sui` live through `Config:Refresh()`.
- [ ] **Step 4: Footer on `/sui`.** `EM:AddFooterButton` buttons attach to the `/sui` window's status bar area while edit mode is active and `/sui` is open. They hide when edit mode turns off, and re-attach whenever `/sui` is (re)opened. Status text stays clear of them.
- [ ] **Step 5: Self-review.**
  - `grep -rn "SaftUI_EditMode\|OpenWindow\|def.options" SaftUI-*/` returns nothing stale.
  - Every `st:RegisterMover` passes a `configPath` that exists in `Config:GetOptionsTable()`.
- [ ] **Step 6: In-game check (user).**
  - In edit mode, clicking the minimap opens `/sui` at Minimap → General. Clicking Loot Rolls or Loot Feed switches the same window to that section, with no second window.
  - Drags and nudges update Position live.
  - The crash retest still passes: `/sui` → Edit mode several times, then close and reopen.
  - Other addons' Ace windows still look stock.
- [ ] **Step 7: Commit:** `core: select a frame's section in /sui instead of opening a window`

---

### Task 8: Forever swing timer bars owned by SaftUI and registered as movers

*Added 2026-11-07 at the user's request: "can we replace the blizzard swing timer edit mode with the saftui one the same way we did with minimap? and also adding configs for it for sizing and position." Independent of Task 5.*

**Context:**
- Forever's `Blizzard_SwingTimer` bars are Blizzard Edit Mode system frames: `SwingTimerMainHandFrame`, `SwingTimerOffHandFrame` and `SwingTimerRangedFrame` (`SwingTimerMixin`, whose `OnLoad` calls `EditModeSystemMixin.OnSystemLoad`).
- SaftUI already skins them (`SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua`, commit `a250261`).
- Retail has no swing timer, so everything here must be inert there.

**Files:**
- Modify: `SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua`, or split positioning into a sibling file loaded from `SaftUI-Misc/Skinning/load.xml`.
- Modify: SaftUI-Misc defaults (`SaftUI-Misc/config.lua`): a `swingtimer` table with per-bar `width`, `height` and `position` `{ point, frame, rel_point, x_off, y_off }`.

**Interfaces:**
- **Consumes:**
  - `st:RegisterMover(key, def)` with `def = { frame, label, getPosition, setPosition, apply, configPath }` (`SaftUI-Core/EditMode/editmode.lua`).
  - `st.Config.generators.position(order, true, get, set, target)` and `range`.
  - `st:BindModuleConfig(module, key)` (`SaftUI-Core/Config/config.lua`).
  - The minimap pattern: `SaftUI-Minimap/minimap.lua` (mover registration, Blizzard Edit Mode box hidden with `Selection:HookScript('OnShow', Hide)`) and `SaftUI-Minimap/config.lua` (`GetConfigTable` tree section with General/Position, `configPath` ending at `general`).
- **Produces:**
  - Movers `'swingtimer_mainhand'`, `'swingtimer_offhand'` and `'swingtimer_ranged'`.
  - A `/sui` tree section "Swing Timer" with Main Hand, Off Hand and Ranged, each with General (width, height) and Position.
  - A module `UpdateConfig` that re-applies size and position, so profile changes apply live.

- [ ] **Step 1: Research.** In the forever source, find how Blizzard positions and sizes these bars: the Edit Mode system anchor and settings, `UpdateSystem`, and any `SetSize`/`SetScale` calls. Find what re-applies them (layout load, Edit Mode exit, `UpdateFrameState`). List the bars' Blizzard Edit Mode settings, and say which ones SaftUI replaces (position, size) and which it doesn't (e.g. visibility).
- [ ] **Step 2: Own position and size.** SaftUI applies size and position from its profile, and re-applies them in post-hooks wherever Blizzard re-applies its own. Use the least invasive way that holds, and taint-safe calls only. If Blizzard's own layout fights direct `SetPoint` on the bars, use SaftUI-owned holder frames.
- [ ] **Step 3: Hide Blizzard's Edit Mode box** for each bar, as with the minimap cluster, so Blizzard's Edit Mode can't move them. Make sure any Blizzard setting SaftUI doesn't replace stays reachable (e.g. its CVar or the game options), and say how.
- [ ] **Step 4: Movers and `/sui` section** as in Interfaces. The defaults reproduce the bars' current default spots and sizes as closely as the source allows.
- [ ] **Step 5: Self-review.** Check that no fields or methods are written onto Blizzard frames or tables, that nothing does arithmetic on possibly-secret values without `issecretvalue`, and that retail stays inert.
- [ ] **Step 6: In-game check (user, Forever).**
  - `/sui edit` shows outlines for the three bars.
  - Dragging moves each bar, and clicking one opens its `/sui` section.
  - Width and height apply live.
  - Blizzard's Edit Mode shows no swing timer boxes.
  - `/reload` keeps positions and sizes.
  - Switching profiles re-applies them.
  - No errors or taint in combat.
- [ ] **Step 7: Commit:** `misc: make forever's swing timer bars saftui movers`

---

### Task 9: BuffFrame and DebuffFrame layout owned by SaftUI and registered as movers

*Added 2026-11-07 at the user's request: "can we setup configs for the BuffFrame and DebuffFrame to be able to configure text (position, size, font, etc.) spacing, wrap count (Icon Limit in blizzard options), grow direction (all four directions) icon size, and general position and add them to edit mode?"*

**Approach (controller's call):**
- Keep Blizzard's `BuffFrame` and `DebuffFrame`. They are Edit Mode system frames built from `AuraFrameEditModeTemplate`, and their aura buttons are plain, non-secure `Button`s (`AuraButtonTemplate`). SaftUI takes over their position and layout, the same way it took over the swing timer bars (Task 8).
- Rejected alternative: SaftUI's own secure aura headers. That means more code and re-implementing Blizzard's collapse button, private auras, weapon enchants and dispel-type borders.
- Blizzard's layout fields (`isHorizontal`, `iconStride`, `iconPadding`, `addIconsToRight`, `addIconsToTop`, `maxAuras`) are Lua state written by Blizzard's Edit Mode settings, so SaftUI must not write them. SaftUI re-lays out the aura buttons itself in a post-hook instead.

**Files:**
- Create: `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua`, loaded from `SaftUI-Misc/Skinning/load.xml` after `Blizzard_BuffFrame.lua`.
- Modify: `SaftUI-Misc/config.lua`, adding `buffs` and `debuffs` defaults.
- Modify: `SaftUI-Misc/Skinning/Blizzard_BuffFrame.lua` only where its text and icon styling must follow the new settings.

**Interfaces:**
- **Consumes:**
  - `st:RegisterMover(key, def)` with `def = { frame, label, getPosition, setPosition, apply, configPath }`
  - `st.Config.generators.position(order, true, get, set, target)`, plus `range` and font helpers
  - `st:BindModuleConfig`
  - `st:SafeReposition(frame, key, fn)` and `st:CanMoveNow(frame)` (SaftUI-Core/api.lua)
  - `st:SetPointDirect` / `st:ClearAllPointsDirect`, for frames whose `SetPoint` is a Blizzard Lua override
  - The pattern to follow: `SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua` (holders, post-hooks, the hidden Blizzard Edit Mode box, `/sui` section, `UpdateConfig`)
- **Produces:**
  - Movers `'buffs'` and `'debuffs'`.
  - A `/sui` section "Auras" with Buffs and Debuffs. Each has:
    - **General:** icon size, spacing (x and y), icons per row ("wrap count", like Blizzard's Icon Limit/Wrap), max icons shown, and grow direction. Grow direction covers all four primary directions (left, right, up, down), plus the wrap direction perpendicular to it.
    - **Text:** duration and stack count, each with font, size, outline, anchor point and x/y offset.
    - **Position.**

- [ ] **Step 1: Research.** In the forever source (`Interface/AddOns/Blizzard_BuffFrame/`, `Blizzard_EditMode`), find:
  - every path that lays out the aura buttons: `AuraContainerMixin:UpdateGridLayout`, `AuraFrameMixin:UpdateGridLayout`/`UpdateSize`, the expand/collapse button, Edit Mode setting handlers, and `ExternalDefensivesFrame`, which is out of scope but must not break
  - how `BuffFrame` and `DebuffFrame` are positioned, including whether they are managed-frame-container children
  - which Blizzard settings SaftUI replaces
- [ ] **Step 2: Own position.** Use SaftUI holder frames sized to the computed grid, as in Task 8.
- [ ] **Step 3: Own layout.**
  - In a post-hook after Blizzard's grid layout, re-anchor every shown aura button by SaftUI's settings using plain widget methods: size, spacing, per-row count, grow and wrap direction.
  - Hide buttons beyond the max-shown setting.
  - Keep Blizzard's ordering (sort, weapon enchants first, and so on).
  - Every position and size goes through `st:RoundToPixel`.
- [ ] **Step 4: Text.** Style the duration and count font strings per the Text settings, re-applying after Blizzard updates them (`UpdateDuration`, count updates). Keep Blizzard's duration color, such as the expiring warning, unless the existing skin already overrides it.
- [ ] **Step 5: Hide Blizzard's Edit Mode boxes** for `BuffFrame` and `DebuffFrame`, as with the minimap. List which Blizzard settings become unreachable, and rebuild any of those that matter here in SaftUI.
- [ ] **Step 6: Combat.** Aura buttons aren't protected, but use `st:CanMoveNow`/`st:SafeReposition` for the holders and frames in case something protected is anchored to them. Layout must keep working in combat, since auras change constantly.
- [ ] **Step 7: Self-review.**
  - No fields or methods written onto Blizzard frames or tables.
  - No `st:Kill`.
  - No arithmetic on possibly secret values without `issecretvalue`.
  - Both clients covered: Forever 16001 and retail 120000. Check the retail source too.
- [ ] **Step 8: In-game check (user, Forever).**
  - `/sui edit` shows Buffs and Debuffs outlines. Dragging moves them, and clicking opens their `/sui` section.
  - Each grow direction and wrap direction lays icons out correctly as buffs come and go, in and out of combat.
  - Icon size, spacing, per-row and max apply live.
  - Text settings apply live.
  - Right-click cancelling a buff still works out of combat.
  - Weapon enchants and the collapse button still work.
  - `/reload` and profile switches keep everything.
- [ ] **Step 9: Commit:** `misc: make the buff and debuff frames saftui movers with layout settings`

---

### Tasks 10–14: more modules as movers

*Added 2026-11-07 at the user's request: "can we start getting edit mode for unit frames and all of the other components we mentioned earlier? I think it's stable enough now that we can just start doing a lot of the modules". Action bars are deferred: SaftUI only skins Blizzard's secure Edit Mode action bars, and the `SaftUIActionBar1..` positions in `SaftUI-Misc/config.lua` point at bars that no longer exist. That needs its own design decision.*

**Shared rules for Tasks 10–14** (they run in parallel, one worktree each):
- Follow the mover pattern already in the repo:
  - minimap: `SaftUI-Minimap/minimap.lua`, `SaftUI-Minimap/config.lua`
  - loot: `SaftUI-Loot/options.lua`, `SaftUI-Loot/roll.lua`
  - swing timer: `SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua`
- Use these helpers:
  - `st:RegisterMover(key, def)` with `def = { frame, label, getPosition, setPosition, apply, configPath }`; `configPath` ends at a leaf group, usually `general`
  - `st.Config.generators.position(order, true, get, set, target)`
  - `st:BindModuleConfig`, the module's `UpdateConfig`
  - `st:SafeReposition` / `st:CanMoveNow` for anything a secure frame could be anchored to
  - `st:SetPointDirect` / `st:ClearAllPointsDirect` for Blizzard frames whose `SetPoint` is a Lua override
- Blizzard Edit Mode boxes for frames SaftUI takes over get hidden with `Selection:HookScript('OnShow', Hide)`. List which Blizzard settings become unreachable.
- Position config uses the `{ point, frame, rel_point, x_off, y_off }` shape. Convert older array-style positions, migrating saved values so nothing jumps.
- Defaults match today's on-screen spots.
- Never write fields or methods onto Blizzard frames or tables. No `st:Kill` on Edit Mode frames. No protected calls in combat. No arithmetic on possibly secret values.
- Stay inside your module's files. Only Task 10 may edit `SaftUI-Core` (removing `st:RegisterEditMode`). If another task needs a Core helper, report it instead of adding one.
- In-game check for each task: outlines in `/sui edit`; drag, nudge and click open the right `/sui` section; `/reload` and profile switch keep positions; no errors or taint in combat.


### Task 10: Unit frames as movers

- Each single unit frame (player, target, targettarget, focus, pet, and any others SaftUI spawns) gets a mover, keyed `uf_<unit>`. Party, raid, boss and arena each get one mover for the whole group, positioned by the group's config. Labels use `UF.unit_strings`.
- `configPath` points into the existing `/sui` unit frames tree (`UF:GetConfigTable`): the unit's General group. Each unit's General gets a full Position section through `generators.position(..., true, get, set, frame)`. The existing frame_position get/set read `UF:GetProfileConfig()[unit].position`.
- Unit frames are secure. Edit mode already closes in combat. `apply` must use `st:SafeReposition` and the unit frames' existing apply path. Group headers can only move out of combat.
- Remove the dead old edit mode code: `st:RegisterEditMode` (SaftUI-Core/api.lua) and its caller in `SaftUI-Unitframes/unitframes.lua`, `SaftUI.EditMode` (SaftUI-Core/init.lua), and the commented TOC line and `Libraries/EditModeExpanded-1.0`. Also update the comment in `SaftUI-Core/EditMode/editmode.lua`.
- Commit: `unitframes: register unit frames as edit mode movers`

### Task 11: SaftUI micro menu bar and XP/rep bars as movers

- The micro menu bar (`SaftUI-Minimap/micromenu.lua`, positioned from `micromenu.position`) gets mover `'micromenu'`. Its container is 1x1 with items chained from it, so give the overlay a frame sized to the bar's real extent: a SaftUI holder, or size the container. Add a `/sui` section for it, with General plus Position.
- The XP and rep bars (`SaftUI-Misc/experience.lua`, `SaftUI_Experience`, positioned from `experience.position`) get mover `'experience'`, with a `/sui` section holding its existing options plus Position.
- Commit: `minimap: make the micro menu bar a mover`, then `misc: make the experience bars a mover`

### Task 12: Chat frame as a mover

- `ChatFrame1` (`SaftUI-Chat/chatframe.lua`, `CHT:ApplyPosition`, `chat.position`, placed with `st:SetPointDirect`) gets mover `'chat'`. The overlay covers the chat frame plus SaftUI's chat panel or backdrop, whichever is the visible footprint.
- Add a `/sui` section with the chat options plus Position, and width and height if SaftUI sizes the chat frame.
- Hide Blizzard's Edit Mode box for the chat frame.
- Commit: `chat: make the chat frame a mover`

### Task 13: Bag and bank windows as movers

- Each SaftUI container window in `SaftUI-Bags` (`inventory` config: bag, bank, and whatever else has a `position` in `SaftUI-Bags/config.lua`) gets mover `'bags_<id>'`. The positions are currently array-style, e.g. `{'BOTTOMRIGHT', -20, 20}`. Convert them to the shared shape and migrate saved values.
- Windows that aren't open still need to be placeable in edit mode. Show the outline at their position even while the window is closed, using a holder if needed.
- Add `/sui` sections, reusing the existing bag config where it exists.
- Commit: `bags: make the bag and bank windows movers`

### Task 14: Forever totem bar: hide option and mover

- This is the request that started edit mode: a hide option for WoW Forever's totem bar.
- `MultiCastActionBarFrame` is a protected Blizzard Edit Mode system with no settings. Research the forever source first: what positions and shows it, and what is protected.
- **Hide option:** a `/sui` toggle that hides it the taint-free way (e.g. a state driver, or parenting to a hidden SaftUI frame out of combat). It applies on the next out-of-combat moment if toggled in combat.
- **Position:** only if a clean way exists. The bar is protected, so all moves must happen out of combat, and Blizzard must not re-anchor it in combat. Otherwise leave position to Blizzard and say why.
- Retail has no totem bar, so this must be inert there.
- Commit: `misc: add a hide option and mover for forever's totem bar`

---

### Task 15: Party and raid frames: re-enable the group headers and make them movers

*Added 2026-11-07 at the user's request ("can we setup the party and raid frames?"). This resolves the followup "Party and raid unit frames: re-enable headers and add edit mode movers".*

- **Fix and re-enable the headers.** Fix `UF:CreateGroupHeaders` in `SaftUI-Unitframes/unitframes.lua`: party passes a table to `SpawnHeader`, and there's an `oUF-initiateConfigFunction` typo. Check the header attributes against the bundled oUF master's `SpawnHeader` and Blizzard's `SecureGroupHeaderTemplate` (forever and live). Re-enable the call in `OnEnable`. Re-enable the groups loop in `UF:GetConfigTable` so party, raid10 and raid40 get `/sui` sections. Group visibility: party shows in a party but not a raid; raid10 and raid40 show by raid size. Use the existing config, or a sensible visibility macro if there is none.
- **Holders and movers.** Follow the boss pattern from Task 10 (`SaftUI_BossHolder`, `UF:RegisterMovers`). Each group gets a SaftUI holder sized from its layout config (unitsPerColumn, maxColumns, spacing, grow direction), and the header is anchored to the holder. Movers are keyed `uf_party`, `uf_raid10` and `uf_raid40`, with configPath `{ 'Unitframes', <group>, 'general' }`. The outline shows even when solo. Headers are secure: all moves, sizes and attribute changes go through `st:SafeReposition`/`st:CanMoveNow`, out of combat only.
- **Profile switches.** Header attributes are set at spawn. On a profile switch, re-apply the attributes that can change out of combat, or print "reload to apply" for anything that can't. Close the matching item in the "Profile settings that still need a /reload" followup.
- **Testing aid.** Add a "Test mode" toggle per group in `/sui`, like the loot test mode. It's session-only and uses SaftUI-owned preview frames, or oUF's own test approach if it has a taint-free one. The user can only see raid layouts in a raid otherwise. Never fake units through Blizzard globals.
- **Followups.** Move the party/raid followup to Resolved in the same change.
- **In-game check.** Party frames appear in a party; raid frames appear in a raid of the right size. Outlines and test previews show when solo. Drag, nudge and click work. `/reload` and profile switches keep the frames in place. No errors or taint in combat (joining or leaving a group in combat must not error).
- **Commit:** `unitframes: re-enable party and raid frames as movers`
