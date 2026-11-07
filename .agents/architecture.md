---
name: architecture
description: How SaftUI's addons, modules, config, profiles and load order fit together
last_updated: 2026-11-07
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
- Lifecycle: `OnInitialize` (rarely used), `OnEnable` (build frames, register movers, hook Blizzard), `UpdateConfig` (re-apply everything from the profile; see below), `GetConfigTable` (the module's `/sui` section). A `/sui <command>` with its own top-row button is `st.Config:AddCommand` (see `.agents/edit-mode.md`).
- `SaftUI-Core/constants.lua` sets client flags and screen constants. See `.agents/clients.md` for `st.retail` / `st.forever`.
- Core helpers live in `SaftUI-Core/api.lua`. The ones you'll use most:
  - position: `st:UnpackPoint`, `st:ResolveFrame`, `st:ValidateAnchor`, `st:RoundToPixel`, `st:GetPixelSize`
  - combat-safe moves: `st:CanMoveNow`, `st:SafeReposition`, `st:QueueAfterCombat`, `st:GetPoints`/`st:RestorePoints`
  - moving Blizzard frames whose methods are Lua overrides: `st:SetPointDirect`, `st:ClearAllPointsDirect`, `st:SetSizeDirect`
- Styling: `st:SetBackdrop`, `st:SetTemplate`, `st:CreateFrame` (`panels.lua`), `st:GetFont` (`Media/fonts.lua`), `st:CreateButton`/`st:SkinButton` (`Widgets/`). Templates and colors live in `st.config.profile.templates` / `.colors`.

## Config, defaults and profiles

- Each module defines its defaults at file load in its own `config.lua`, as `st.defaults.<key> = { ... }`. Unit frames keep theirs in `SaftUI-Unitframes/config/`.
- `Config:InitializeAceConfig` (called from `SaftUI:OnEnable`) creates `st.config = AceDB:New('SaftUI_DB', { profile = st.defaults, ... })`. Read settings through `st.config.profile.<key>`.
- **Bind, don't cache.** In `OnEnable`, call `st:BindModuleConfig(self, '<key>')` instead of `self.config = st.config.profile.<key>`. On a profile change, AceDB switches to the new profile's tables and strips defaults from the old ones, so any reference cached at enable time (including upvalues and closures holding sub-tables) returns nil fields. Bound modules are re-pointed automatically. In option `get`/`set` functions and hooks, read through `self.config` at call time.
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
- Layout "profiles" inside the SaftUI profile: `st.config.profile.unitframes.profiles[UF:GetProfile()]`, read through `UF:GetProfileConfig()`.
- Unit frames are secure. See `.agents/taint.md` before moving or resizing them.

## See also

- `.agents/edit-mode.md` covers movers and `/sui` options.
- `.agents/taint.md` covers combat and Blizzard frames.
- Design specs and plans are in `docs/superpowers/`, starting with the edit mode spec `docs/superpowers/specs/2026-11-06-saftui-edit-mode-design.md`.
