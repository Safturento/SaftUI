---
name: edit-mode
description: SaftUI's edit mode (movers), the /sui options tree, option widgets and the scoped Ace skin
last_updated: 2026-11-08
covers:
  - 'SaftUI-Core/EditMode/**'
  - 'SaftUI-Core/Config/aceskin.lua'
  - 'SaftUI-Core/Config/widgets.lua'
  - 'SaftUI-*/options.lua'
  - 'SaftUI-*/movers.lua'
  - 'SaftUI-Misc/Skinning/*Position.lua'
  - 'SaftUI-Misc/tooltipposition.lua'
  - 'SaftUI-Misc/totembar.lua'
  - 'SaftUI-ActionBars/extras.lua'
---

# Edit mode and `/sui`

SaftUI has its own edit mode. It never adds frames to Blizzard's Edit Mode.
- `/sui edit` or the `/sui` "Edit mode" button toggles it. It also follows Blizzard's Edit Mode opening and closing.
- Registered frames get a draggable overlay. Arrow keys nudge 1px, Shift+arrows 10px.
- Where overlays overlap, a list by the cursor names every one under it and marks the one a click or drag gets; the rest dim. Alt brings the next one to the front (`EditMode/picker.lua`, like `/fstack`). Overlays share one strata, so their frame levels decide which is on top: each gets its own pair (backdrop one below), handed out rising by `EM:BringToFront`. Don't set an overlay's level anywhere else.
- Clicking a frame opens `/sui` at that frame's section.
- It closes on combat and refuses to open in combat.

The spec is in `docs/superpowers/specs/2026-11-06-saftui-edit-mode-design.md`, and the plan (Tasks 1–15) in `docs/superpowers/plans/2026-11-06-saftui-edit-mode.md`.

## Registering a mover

```lua
st:RegisterMover('key', {
	frame = holderOrFrame,        -- the overlay does SetAllPoints on this; it needs a real size
	label = 'Name',
	getPosition = function() return self.config.position end,   -- read through self.config at call time
	setPosition = function(pos) self.config.position = pos end,
	apply = function() self:ApplyPosition() end,                 -- can run in combat lockdown
	configPath = { 'ModuleName', 'section', 'general' },         -- keys from the /sui root to a leaf group
})
```

- **Offsets.** Drags and nudges write pixel-rounded `x_off`/`y_off` into the table from `getPosition()`, call `setPosition`, then `apply` (about every 0.1s while dragging, and once at drag end). Drags keep the frame's anchor point and relative frame. Only the offsets change.
- **`apply`** must go through `st:SafeReposition`, because a secure frame anchored to yours makes it protected in combat.
- **`configPath`** must resolve in `Config:GetOptionsTable`. Module tables are keyed by module name. End the path at a leaf group, usually `general`, since selecting a parent that only holds subgroups shows an empty pane.
- **Holder pattern.** Use a SaftUI holder frame when the real frame:
  - can be empty or hidden (loot rolls, boss and party/raid groups, closed bag windows),
  - has no size (the micro menu container), or
  - belongs to Blizzard (swing timer, buffs, chat, the extra action button and zone ability).

  Size the holder from the config, place it from the profile, and anchor the real frame to it. The overlay then always has a footprint.

  A SaftUI frame that's only hidden, and still sized and placed from the profile while hidden, can be its own mover frame: the overlay follows its edges either way. SaftUI's action bars (`SaftUI-ActionBars/options.lua`) move their secure headers this way, also while a bar is disabled or hidden by its Visibility setting, and while the pet bar has no pet or the stance bar no forms (laid out as one button then, so the outline keeps a size). Label the outline when the frame may not be visible (`mover.label:SetText`), as the action bars and the swing timer do. The extra buttons' outlines (`SaftUI-ActionBars/options.lua`) always say when they show, as they mostly don't.
- **Taking over a Blizzard Edit Mode frame.** The swing timer bars (`SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua`), buffs (`Blizzard_BuffFramePosition.lua`), chat (`SaftUI-Chat/chatframe.lua`), the default tooltip's `GameTooltipDefaultContainer` (`SaftUI-Misc/tooltipposition.lua`; the tooltip itself is never moved) and, on a shaman, Forever's totem bar `MultiCastActionBarFrame` (`SaftUI-Misc/totembar.lua`, mover `totembar`) all follow the same pattern:
  - Use a holder.
  - Re-anchor the Blizzard frame with `st:SetPointDirect` / `st:ClearAllPointsDirect` in post-hooks on its `SetPoint` / `ClearAllPoints` / `UpdateSystem`. If it's protected (the totem bar holds secure buttons), the re-anchor waits for the end of combat (`st:QueueAfterCombat`), and the holder goes through `st:SafeReposition`.
  - Where Blizzard's Edit Mode can read the frame's anchor (a snap break, when the frame it's snapped to hides, records it into the layout through `UpdateSystemAnchorInfo`, and a layout save keeps it), don't anchor the frame straight to a SaftUI holder. Place it on UIParent at the holder's spot instead, from the holder's rect, and again whenever the holder moves or resizes (the totem bar's `TB:AnchorBar`, run from a post-hook on the holder's `SetPoint`). Otherwise the layout names the holder, and Blizzard anchors the frame to a missing frame wherever the holder doesn't exist. Chat copies its holder's own anchor instead (`CHT:PlaceChatFrame`), so the layout would name the holder's relative frame, UIParent by default.
  - Hide its `Selection` box with a `HookScript('OnShow', Hide)`.
  - List which Blizzard settings become unreachable, and rebuild the useful ones in `/sui`.
  - Keep first load from moving anything. Profiles saved before the takeover have no position, so either give `position` a default that reproduces Blizzard's default layout (swing timer, buffs) or give it none and capture the frame's spot on screen once Blizzard's Edit Mode has placed it (the totem bar, `TB:CapturePosition`, and chat's size, `CHT:CaptureSize`). Blizzard's layout can arrive after SaftUI loads, and a frame in its default position can sit somewhere temporary until Blizzard lays it out (a totem bar in its default position waits at UIParent's top-left until it first shows), so capture outside Blizzard's re-places, on the next frame.

  Read `.agents/taint.md` first.
- **When post-hooks can't hold it.** The extra action button and the zone ability (`SaftUI-ActionBars/extras.lua`) live in Blizzard's `ExtraAbilityContainer`, which lays its frames out again each time one is added, in combat too. `ExtraActionBarFrame` holds a secure button, so a post-hook couldn't move it back until combat ends. So SaftUI moves none of Blizzard's frames. It anchors what Blizzard never re-anchors (`ExtraActionButton1`, the zone's `SpellButtonContainer` and `Style` art) to the holder once, out of combat, and the buttons then show at SaftUI's spot even when they first appear mid-fight. Blizzard's empty frames stay in Blizzard's layout; make any that take the mouse click-through (`AB:DisableMouse` in `SaftUI-ActionBars/hideblizzard.lua`), so they don't block clicks to what's under them. Before using this, grep both branches to confirm nothing re-anchors the inner frame. The totem bar combines both patterns: Blizzard re-places the bar itself in combat, so its buttons are anchored straight to the holder too and only the empty bar frame moves until combat ends. Blizzard's own button update re-anchors two of them to the bar (the first element and the summon pages), so in a fight that runs it while the bar is elsewhere they follow the bar until combat ends. Size Blizzard's buttons with a Scale setting (the widget's own `SetScale`), since their art is laid out for one size.
- **Validating anchors.** The Position editor's typed relative frame is validated with `st:ValidateAnchor(target, name)`. Always pass `target` (the frame being moved) so self-anchors, anchor loops and descendants are rejected.
- **Profile switches.** `EM:ClearPositions` then `EM:UpdateConfig` re-apply every mover. Implement `UpdateConfig` in your module too (see `.agents/architecture.md`).
- **Test modes.** Loot rolls/feed and party/raid groups have session-only test toggles that draw SaftUI-owned previews anchored to the holder. Never fake units or override Blizzard APIs.

## `/sui` options

- `/sui` is one window. It's built in `Config:GetOptionsTable` from each module's `GetConfigTable()`, and opened with `st.Config:Open(...path)`, which uses `AceConfigDialog:SelectGroup`.
- **Subcommands.** `st.Config:AddCommand(command, label, func)` makes `/sui <command>` run `func`, and adds a `label` button after "Edit mode" in the window's top row. Call it at file load or in `OnEnable`. SaftUI-ActionBars adds `kb` (Keybind mode, `SaftUI-ActionBars/bindings.lua`).
- **Section shape.** A mover's section is a group with `general` and `position` subgroups, plus any others it needs (e.g. the action bars' Text and Visibility). `Config:GetOptionsTable` then:
  - moves `position` into General as a box at its end (`MergePositionIntoGeneral`), so size and position sit together and the mover's `configPath` still ends at `general`;
  - turns innermost subgroups into tabs (`UseTabsForInnermostSections`, `childGroups = 'tab'`) unless the group already sets `childGroups`.
  - A unit frame's section shows its elements as tabs (General, Health, Castbar, ...): one per element that registered a `GetConfigTable` and whose `ValidUnit` accepts the unit. Keep sub-areas inside a tab as inline groups.
- **Widgets** are `st.Config.generators` in `SaftUI-Core/Config/widgets.lua`:
  - `position(order, true, get, set, target)` is the full SetPoint editor. `target` (the frame being placed, or a function returning it) is what typed anchors are checked against.
  - `uf_element_position(order, get, set, target)` places a unit frame element, text or icon. Its Frame select (unit frame, another element, or a global frame) reads and writes `position.element` / `position.frame` the way `UF:GetFrame` resolves them, and clears a key with `false` so it overrides an AceDB default. Pass `UF:ConfigTarget(unit, element, key)` as `target`.
  - `width`/`height` are input boxes that display numbers and save numbers.
  - Also available: `range`, `toggle`, `template`, `font`, …
  - AceConfigDialog shows an `input` as blank unless `get` returns a string, so use these generators rather than raw inputs for numbers.
- Option `get`/`set` must read through `self.config` (or `UF:GetProfileConfig()`) at call time, never a captured table.

## Scoped Ace skin (`SaftUI-Core/Config/aceskin.lua`)

AceGUI widgets are **pooled and shared with every other addon**:
- Only widgets inside windows from `st.AceSkin:CreateWindow` are styled (`Scope`). Every change pushes an undo, and the undos run on `AceGUI:Release`, so other addons get stock widgets back.
- Never hook `AceGUI:Create` or a widget constructor globally.
- New styling goes through the recorded helpers (`SetFont`, `SetAlpha`, `Retexture`, `Box`, `Owned`, `HookMethod`, …).
- Fonts: see rule 10 in `.agents/taint.md`.
- `STYLERS[type]` covers Frame, TreeGroup, TabGroup, InlineGroup, ScrollFrame, CheckBox, Slider, EditBox, Button, Heading, Label, ColorPicker, Dropdown and its pullout, and the LSM30 widgets.
- On Forever the AceGUI and AceConfigDialog that actually load come from another addon (HandyNotes' copies). Stay defensive about version differences.
