---
name: architecture
description: How SaftUI's addons, modules, config, profiles and load order fit together
last_updated: 2026-11-10
covers:
  - 'SaftUI-*/*.toc'
  - 'SaftUI-Core/init.lua'
  - 'SaftUI-Core/constants.lua'
  - 'SaftUI-Core/Config/config.lua'
  - 'SaftUI-Core/Config/defaults.lua'
  - 'SaftUI-*/config.lua'
  - 'SaftUI-*/init.lua'
---

# Architecture

## Addons and load order

- Every folder `SaftUI-<Name>/` is a separate WoW addon. All of them `## RequiredDeps: SaftUI-Core` and `## Group: SaftUI-Core`.
- **TOCs:** Core and Unitframes have per-client TOCs (`*_Forever.toc` = `## Interface: 16001`, `*_Mainline.toc` = `120000`). The other addons use one TOC listing both (`## Interface: 120000, 16001`). When you add a file, add it to **every** TOC of that addon (and to the folder's `load.xml` where one is used, e.g. `SaftUI-Core/EditMode/load.xml`, `SaftUI-Misc/Skinning/load.xml`).
- Load order matters: Core loads first, then each module addon in its TOC order. Defaults (`st.defaults.*`) must be defined at file load, before Core creates the AceDB (see below).
- **Libraries:** Core bundles LibStub, CallbackHandler-1.0, Ace3 and the shared media libraries. An addon that needs more bundles them in its own `Libraries/` and lists them first in its TOC, without a second copy of LibStub or CallbackHandler: Unitframes has oUF, ActionBars has LibActionButton-1.0 and LibButtonGlow-1.0 (sources and versions in `SaftUI-ActionBars/Libraries/README.md`).

## The `st` object and modules

- `SaftUI-Core/init.lua` creates the addon: `SaftUI = AceAddon:NewAddon(st, 'SaftUI-Core', 'AceEvent-3.0', 'AceHook-3.0')`. Every file starts with `local st = SaftUI`.
- A module is `local M = st:NewModule('Name')` (AceAddon module, with AceEvent + AceHook mixed in). Module names are the keys used everywhere else: `st.modules[name]`, the `/sui` tree, and edit mode `configPath`s. Current modules include ActionBars, Auras, Chat, Config, EditMode, Experience, Fonts, Inventory, Loot, MicroMenu, Minimap, Movable, Skinning, SwingTimer, TaintFix, Tooltip, TotemBar, Unitframes, Utilities.
- Lifecycle: `OnInitialize` (rarely used), `OnEnable` (build frames, register movers, hook Blizzard), `UpdateConfig` (re-apply everything from the profile; see below), `GetConfigTable` (the module's `/sui` page; its top-level table's `category`, Frames, Combat or Info, groups it in the window's sidebar). A `/sui <command>` with its own sidebar button is `st.Config:AddCommand` (see `.agents/edit-mode.md`).
- A module that shows profile colors can define `OnColorsChanged(group)`. `st:ColorsChanged(group)` (`SaftUI-Core/Media/colors.lua`) calls it on every module that has one, after a Colors tab change; `group` is `text`, `button`, `class`, `reaction`, `renown`, `power`, `item_quality` or `status`. Anything that colors by item quality uses `st:QualityColor(quality)` (the profile's color, else Blizzard's).
- `SaftUI-Core/constants.lua` sets client flags and screen constants. See `.agents/clients.md` for `st.retail` / `st.forever`.
- Core helpers live in `SaftUI-Core/api.lua`. The ones you'll use most:
  - position: `st:UnpackPoint`, `st:ResolveFrame`, `st:ValidateAnchor`, `st:RoundToPixel`, `st:GetPixelSize`
  - **Half pixels from centred anchors.** SaftUI's UI scale makes one unit one physical pixel, and `st:RoundToPixel` keeps sizes and offsets whole. But a frame anchored by its centre on an axis (TOP/BOTTOM centre it across, LEFT/RIGHT up and down, CENTER both) that's an odd number of pixels long on that axis has its edges half a pixel off the grid. So do its children. The game then rounds each child separately, and children either side of the centre round in opposite directions. Symptom: one gap in a row of buttons is a pixel short, right at the middle (a 12-button bar at 3px spacing is 573px wide). Fix: round the frame up to an even pixel length on each centred axis, so its edges and its centre stay on whole pixels and frames anchored to it line up too. `EvenIfCentred` in `SaftUI-ActionBars/bars.lua` does this, through `AB:PlaceFrame`, which sizes and places both the bars and the extra buttons' holders (`extras.lua`). When another addon needs it, move it into `api.lua`. Where the anchor can change without SaftUI's sizing code seeing it, round up on both axes whatever it is. The totem bar (`SaftUI-Misc/totembar.lua`, `EvenPixels`) is always sized even, with the spare pixel as empty bar at the right and the top: on a shaman SaftUI places it from its holder, whose Position can be anchored by any point and is changed by drags, and on other classes Blizzard's Edit Mode places it.
  - combat-safe moves: `st:CanMoveNow`, `st:SafeReposition`, `st:QueueAfterCombat`, `st:GetPoints`/`st:RestorePoints`
  - moving Blizzard frames whose methods are Lua overrides: `st:SetPointDirect`, `st:ClearAllPointsDirect`, `st:SetSizeDirect`
- Styling: `st:SetBackdrop`, `st:SetTemplate`, `st:CreateFrame` (`panels.lua`), `st:GetFont` (`Media/fonts.lua`), `st:CreateButton`/`st:SkinButton` (`Widgets/`). Templates and colors live in `st.config.profile.templates` / `.colors`.

## Config, defaults and profiles

- Each module defines its defaults at file load in its own `config.lua`, as `st.defaults.<key> = { ... }`. Unit frames keep theirs in `SaftUI-Unitframes/config/`.
- `Config:InitializeAceConfig` (called from `SaftUI:OnEnable`) creates `st.config = AceDB:New('SaftUI_DB', { profile = st.defaults, ... })`. Read settings through `st.config.profile.<key>`.
- **Bind, don't cache.** In `OnEnable`, call `st:BindModuleConfig(self, '<key>')` instead of `self.config = st.config.profile.<key>`. On a profile change, AceDB switches to the new profile's tables and strips defaults from the old ones, so any reference cached at enable time (including upvalues and closures holding sub-tables) returns nil fields. Bound modules are re-pointed automatically. In option `get`/`set` functions and hooks, read through `self.config` at call time.
- **Per-character saved data** (not settings) goes in AceDB's char namespace, `st.config.char.<key>`, which a profile switch doesn't touch. SaftUI-Loot keeps its saved feed and recorded roll drops there (`Feed/history.lua`, `Feed/rolls.lua`). Read it through an accessor at call time (`st.config` doesn't exist at file load). Save only plain data (strings, numbers, booleans and tables of them), never a secret value (`.agents/clients.md`) and never test-mode entries, and keep each record to the fields its readers need.
- **Profile changes** (`OnProfileChanged`/`Copied`/`Reset`) run `Config:UpdateConfig()` in `SaftUI-Core/Config/config.lua`. Order:
  1. Re-point every bound `module.config`.
  2. Clear mover anchors (`EM:ClearPositions`, which saves them and skips frames that are protected in combat).
  3. Apply fonts, then headers.
  4. Run every module's `UpdateConfig` inside `xpcall`, with errors going to `geterrorhandler()`.
  5. Re-apply edit mode movers (`EM:UpdateConfig`), restoring the old anchors of any frame left without points.
  6. Rebuild and refresh an open `/sui`.

  In combat, protected work is deferred with `st:SafeReposition` / `st:QueueAfterCombat`, and one chat message says what will finish after combat.
- **Every module needs an `UpdateConfig`** that re-reads the profile and re-applies everything it controls (positions, sizes, templates, fonts, colors, visibility). It must be idempotent: never create frames, font strings or hooks on each call. Create once, re-style on every call. Settings that genuinely can't apply live (module on/off toggles, secure header attributes) say "reload to apply" in their option description.
- Position config shape: `{ point, frame, rel_point, x_off, y_off }`, unpacked with `st:UnpackPoint`. Some older code used array positions (`{'BOTTOMRIGHT', -20, 20}`). Modules that converted (Bags, Chat, Experience) migrate saved arrays in place on enable and on profile change, filling missing slots from the old array defaults, because AceDB only saves slots that differ from the default.

## Unit frames

- These are oUF (`SaftUI-Unitframes/Libraries/oUF`, oUF master). In this oUF the active unit is `frame.__unit`, **not** `frame.unit`.
- Elements register through `UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)`.
  - `ValidUnit(unit)` gets the config unit (`player`, `boss`, `party`, ...). A unit it rejects gets neither the element nor its `/sui` tab. ClassPower and AdditionalPower are player-only, Castbar skips `targettarget` and `focustarget` (as oUF does), and ReadyCheckIndicator is party and raid only.
  - `GetConfigTable(unit)` returns the element's tab. Its `set` calls `UF:UpdateConfig(unit, '<Element>')`, which re-runs that element's `UpdateConfig` on every frame of the unit.
  - oUF shows and hides many elements itself (castbar on a cast, indicators by state, additional power by power type), so `UF:SetElementEnabled` alone doesn't keep a disabled one hidden. Those elements also check `config.enable` in an oUF hook (`ShouldShow`, `PostVisibility`, `PostUpdate`).
  - Texts made by `UF:AddText` sit on the unit frame's `TextOverlay`, not on their element, so they don't hide with it. `UF:UpdateElement` hides them when the element is disabled.
- Layout "profiles" inside the SaftUI profile: `st.config.profile.unitframes.profiles[UF:GetProfile()]`, read through `UF:GetProfileConfig()`.
- Unit frames are secure. See `.agents/taint.md` before moving or resizing them.

## See also

- `.agents/edit-mode.md` covers movers and `/sui` options.
- `.agents/taint.md` covers combat and Blizzard frames.
- Design specs and plans are in `docs/superpowers/`, starting with the edit mode spec `docs/superpowers/specs/2026-11-06-saftui-edit-mode-design.md`.
