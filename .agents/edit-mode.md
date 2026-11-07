---
name: edit-mode
description: SaftUI's edit mode (movers), the /sui options tree, option widgets and the scoped Ace skin
last_updated: 2026-11-07
covers:
  - 'SaftUI-Core/EditMode/**'
  - 'SaftUI-Core/Config/aceskin.lua'
  - 'SaftUI-Core/Config/widgets.lua'
  - 'SaftUI-*/options.lua'
  - 'SaftUI-*/movers.lua'
  - 'SaftUI-Misc/Skinning/*Position.lua'
---

# Edit mode and `/sui`

SaftUI has its own edit mode. It never adds frames to Blizzard's Edit Mode.
- `/sui edit` or the `/sui` "Edit mode" button toggles it. It also follows Blizzard's Edit Mode opening and closing.
- Registered frames get a draggable overlay. Arrow keys nudge 1px, Shift+arrows 10px.
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
  - belongs to Blizzard (swing timer, buffs, chat).

  Size the holder from the config, place it from the profile, and anchor the real frame to it. The overlay then always has a footprint.
- **Taking over a Blizzard Edit Mode frame.** The swing timer bars (`SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua`), buffs (`Blizzard_BuffFramePosition.lua`) and chat (`SaftUI-Chat/chatframe.lua`) all follow the same pattern:
  - Use a holder.
  - Re-anchor the Blizzard frame with `st:SetPointDirect` / `st:ClearAllPointsDirect` in post-hooks on its `SetPoint` / `ClearAllPoints` / `UpdateSystem`.
  - Hide its `Selection` box with a `HookScript('OnShow', Hide)`.
  - List which Blizzard settings become unreachable, and rebuild the useful ones in `/sui`.

  Read `.agents/taint.md` first.
- **Validating anchors.** The Position editor's typed relative frame is validated with `st:ValidateAnchor(target, name)`. Always pass `target` (the frame being moved) so self-anchors, anchor loops and descendants are rejected.
- **Profile switches.** `EM:ClearPositions` then `EM:UpdateConfig` re-apply every mover. Implement `UpdateConfig` in your module too (see `.agents/architecture.md`).
- **Test modes.** Loot rolls/feed and party/raid groups have session-only test toggles that draw SaftUI-owned previews anchored to the holder. Never fake units or override Blizzard APIs.

## `/sui` options

- `/sui` is one window. It's built in `Config:GetOptionsTable` from each module's `GetConfigTable()`, and opened with `st.Config:Open(...path)`, which uses `AceConfigDialog:SelectGroup`.
- **Section shape.** A mover's section is a group with `general` and `position` subgroups. `UseTabsForInnermostSections` turns innermost subgroups into tabs automatically (`childGroups = 'tab'`) unless the group already sets `childGroups`. Unit frames use `select`.
- **Widgets** are `st.Config.generators` in `SaftUI-Core/Config/widgets.lua`:
  - `position(order, true, get, set, target)` is the full SetPoint editor.
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
