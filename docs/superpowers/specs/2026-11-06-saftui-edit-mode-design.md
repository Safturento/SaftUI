# SaftUI Edit Mode — Design

**Date:** 2026-11-06
**Status:** Ready for approval
**First version scope:** the framework, with the minimap as the only frame wired in.

## Intent

PitBull-level customization without digging through an options tree. In edit mode, every SaftUI frame can be dragged, nudged, and clicked. Clicking a frame opens its own settings in a small window next to it, so changes are judged against the real frame on screen and apply live.

The user wants this to be SaftUI's own system. SaftUI's frames must never be added to Blizzard's Edit Mode. Blizzard's Edit Mode frames are layout-sensitive and protected-adjacent. Addons that write to them have caused combat taint (`ADDON_ACTION_BLOCKED` on action bars), and this project has already hit that.

## Goals

- **Edit mode:** a SaftUI-only mode where registered frames show a draggable, clickable overlay.
- **Per-frame settings window:** clicking a frame's overlay opens its settings next to it. The window is Ace's config dialog laid out with a sidebar (tree) and reskinned to SaftUI's look.
- **Pixel-perfect positioning:** dragging, arrow-key nudging, and typed values all land on whole screen pixels.
- **One source of truth:** frame positions come only from the SaftUI profile (AceDB), never from Blizzard's saved frame positions or layout cache.
- **Reusable framework:** after the minimap, unit frames, the micro menu, the experience bar, the loot feed and others can be registered the same way.

## Non-goals (this version)

- Wiring any frame other than the minimap. The framework must support the others, but only the minimap gets registered now.
- Unit-frame-specific features (per-element sidebar sections, the shared "All unit frames" section). They are designed for, but not built.
- Removing `st:RegisterEditMode`. It goes away when unit frames move to this system, not in this version. Its library, `EditModeExpanded-1.0`, is already commented out of the Mainline TOC and absent from the Forever TOC, so `st:RegisterEditMode` currently does nothing on both clients. *(Done 2026-11-07 in Task 10, `3c0108b`, when unit frames became movers.)*
- Blizzard frames (e.g. the Forever totem bar, `MultiCastActionBarFrame`). They come later, as frames that get an overlay and options.

## Anti-goals (would make this a failure even if it works)

- Touching Blizzard's Edit Mode frames, dialogs or settings, or writing fields or functions onto them. SaftUI only *listens* for Blizzard's Edit Mode opening and closing.
- Frames ending up on half pixels and rendering blurry.
- A position that only lives in Blizzard's frame-position memory and disagrees with the profile after a reload.
- Errors or blocked actions in combat.

## Decided by the user

### Entering and leaving

- SaftUI's edit mode turns on when Blizzard's Edit Mode opens, and off when it closes.
- `/sui` (and `/saftui`) keeps opening the existing SaftUI options window. Its contents are unchanged, and it gets the SaftUI reskin. That window gets an **Edit mode** button that toggles SaftUI's edit mode. Its top group has a commented-out "Toggle Positioning" stub (`SaftUI-Core/Config/config.lua`, `topmenu`) where this belongs.

### Combat

- Edit mode closes itself when combat starts and refuses to open during combat, with a chat message.

### Settings window

**Revised 2026-11-07 (user, after testing):** "clicking on the edit mode windows to load the config opens a new window, can we just have all of those components registered on the main SaftUI config window and it just switches to the appropriate tab? that way we can keep everything grouped up and not have multiple windows open." This replaces the per-frame window:

- There is one settings window, the `/sui` window. Clicking a frame in edit mode opens `/sui` if it's closed and selects that frame's section in its tree. No second window opens.
- Every registered frame has its section in the `/sui` tree, with sub-sections such as General and Position (e.g. Minimap → General / Position; Loot → Rolls → General / Position, Loot → Feed → General / Position).
- *Builder's calls, made with this revision:*
  - `/sui` stays where the user put it. It doesn't jump beside the clicked frame.
  - Deselecting a frame doesn't close `/sui`.
  - The footer buttons (grid, snap) sit on the `/sui` window's footer while edit mode is active.

The rest of this section still applies to the `/sui` window. Where it says "the window" or "per-frame windows" below, read `/sui`.

- Ace's AceConfigDialog renders the window with a tree/sidebar layout.
  - The sidebar lists the clicked frame's sections.
  - For frames with shared settings, a group below the sidebar holds settings shared across frames of that kind. Example for later: "All unit frames" → Colors, Fonts.
- SaftUI reskins Ace's widgets so the window looks like SaftUI. The user chose Ace for its stability, but it must not keep the stock look.
  - **Reach (decided after review):** only SaftUI's windows get the SaftUI look, meaning the per-frame edit mode windows and the existing `/sui` options window.
  - Other addons' Ace windows (WeakAuras, Details, etc.) must stay stock.
  - AceGUI is one shared library whose widgets are pooled and recycled across addons. So the reskin must be scoped: apply SaftUI styling only to widgets inside SaftUI windows, and undo it when they're released back to the pool.
- Settings stay in the AceConfig option-table format (`type`, `name`, `get`, `set`, `args`) SaftUI already uses.
  - The existing `GetConfigTable` functions are the baseline, both module-level (`MM:GetConfigTable` in `SaftUI-Minimap/config.lua`) and per element (`UF:RegisterElement(..., GetConfigTable)`).
  - Changing their shape to fit this system, or improving them, is welcome.
- Changes apply live through each module's existing update path (e.g. `MM:UpdateConfig()`).
- **Footer buttons** on the settings window:
  - toggle an alignment grid on screen
  - switch drag mode between free drag and snap to other frames

### Position options

Every `SetPoint` parameter is editable in the frame's Position section:

- point
- relative frame, as a free-text box where any global frame name can be typed
- relative point
- x offset
- y offset

The existing position config shape `{ point, frame, rel_point, x_off, y_off }` (read with `st:UnpackPoint`) is the format.

The current position generator (`st.Config.generators.position`, `SaftUI-Core/Config/widgets.lua`) stores offsets as strings and its `%d+` input pattern rejects negative numbers. Fix both: store numbers, and accept negative values. *(Builder's call, found in review.)*

### Dragging

- Dragging keeps the frame's current anchor (point, relative frame, relative point) and only recalculates x/y offsets. It must not re-anchor everything to a screen corner the way Blizzard's `StartMoving` does.
- When a drag ends, the new offsets are written to the frame's position config in the profile.
- The relative frame changes only through the Position section (typed name) or snapping.

### Nudging

- With a frame selected, the arrow keys move it 1 pixel and Shift+arrows move it 10 pixels.
- Each nudge writes the new x/y into the position config, so the Position section updates live.

### Pixel perfect

- Every resulting offset, from drag, nudge, snap or typed value, is rounded to the nearest whole physical screen pixel at the current UI scale.
  - SaftUI tracks scale in `st.scale` / `st.mult`, set in Core.

## Builder's calls (marked as such; reject any you disagree with)

These were proposed and the user accepted them provisionally ("we can adjust later"):

- **Snap to other frames:** a frame's edges align to nearby registered frames' edges and the screen center when within a few pixels. Snapping aligns; it doesn't change the relative frame unless the builder decides snapping to a frame should anchor to it. Keep it simple and say which.
- **Sizes:** sizes set in edit mode are also rounded to whole pixels.
- **Typed anchors:** a typed relative frame name that doesn't exist, or that would make a frame anchor to itself or create an anchor loop, is rejected with a message rather than applied.
- **Overlay look:** a SaftUI-styled outline with the frame's name, plus a highlighted state for the selected frame. Exact look is up to the builder, using SaftUI's backdrop templates and fonts.
- **`/sui edit`:** this subcommand toggles edit mode directly. A convenience; drop it if it complicates the slash handler.

## The minimap specifically

**Decided by the user (after review):**

- **SaftUI owns the minimap outright.**
  - `Minimap` is moved out from under `MinimapCluster` and sized and positioned only from SaftUI's profile.
  - Blizzard's own Edit Mode minimap settings, such as Size, are allowed to stop having any effect. This keeps sizes and offsets on whole pixels, since a Blizzard size multiplier can no longer scale the minimap.
  - Pieces that hang off the cluster and that SaftUI already uses (zone text, mail/indicator frame, tracking, instance difficulty, etc., hooked in `SaftUI-Minimap/minimap.lua` and `micromenu.lua`) are re-anchored as needed so they still work.
- **Clean up the existing writes onto Blizzard's Edit Mode frame**, so SaftUI never writes onto it:
  - `st:Kill(MinimapCluster.Selection)` in `SaftUI-Minimap/minimap.lua`. `st:Kill` swaps `Show` for `Hide` on the frame.
  - `MinimapCluster:EnableMouse(false)`.
  - SaftUI's own positioning/sizing of `MinimapCluster` in `MM:UpdateConfig()`.
  - Replace each with a taint-safe equivalent, or drop it if it's no longer needed once `Minimap` is out of the cluster. For example, Blizzard's selection box may simply be left alone, with SaftUI's overlay sitting on our own minimap.
  - The global `GetMinimapShape` override is a plain global function other minimap addons read, not a write onto an Edit Mode frame. Keep it unless it's shown to cause taint.
  - These writes are a suspected cause of an earlier combat error, `ADDON_ACTION_BLOCKED` on `MultiBarBottomRightButton1:SetShown()` blamed on SaftUI-Minimap.
- **Settings to expose:** the existing minimap options (template, size, addon buttons in compartment, position), with Position using the full `SetPoint` editor above.
- **When Blizzard's Edit Mode is open too:** its selection box stays on `MinimapCluster`, which no longer holds the minimap. SaftUI's overlay on the minimap must be clickable and above anything of Blizzard's that overlaps it.

## Constraints

- **Clients:** retail (Midnight, interface 120000) and WoW Forever (interface 16001, a mainline-family client with "Camelot" overrides). `st.retail` is true on both; `st.forever` only on Forever. The user plays Forever now.
- **Libraries:** Ace3 (AceConfig, AceConfigDialog, AceGUI, AceDB) is already loaded by SaftUI-Core on both clients.
- **Blizzard UI source reference:** `Gethe/wow-ui-source`, branches `live` and `forever`.
- **Where it lives:** the framework is generic and lives in SaftUI-Core. The minimap wiring lives in SaftUI-Minimap.
- **Taint safety:** hooks via `hooksecurefunc` / `HookScript` only. Use `EventRegistry` callbacks or `EditModeManagerFrame` show/hide hooks to detect Blizzard's Edit Mode. No method replacement on Blizzard frames.
- **Testing:** the game can't be run by the builder. The user verifies in game on Forever (and retail when available). Each step should leave the UI loadable, with a short list of what to check.

## Left to the builder

- **Registration API:** the shape of the registration call (e.g. `st:RegisterMover(frame, options)`), covering the frame, display name, position config getter/setter, options table provider, and apply/update callback.
- **Ace reskin approach:** how the scoped reskin is done, and which AceGUI widget types are covered in this version. At minimum, everything the minimap's window and the `/sui` window show.
- **Settings window placement:** where the window opens relative to the clicked frame, and keeping it on screen.
- **Grid:** spacing and look of the alignment grid.
- **Mode settings:** where edit-mode-wide settings (grid on/off, snap mode) are stored.
