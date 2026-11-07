# Followups

A queue between "noticed it" and "decided what to do about it." Items might become Jira tickets, get fixed inline during related work, or be explicitly abandoned. Triage periodically.

Format: see the user-level `~/.claude/CLAUDE.md` "Followup detection" section.

## Contents

- [Active](#active)
  - [2026-11-07 — SaftUI-Minimap's bar replaces Blizzard frame scripts and writes onto them (taint risk)](#2026-11-07--saftui-minimaps-bar-replaces-blizzard-frame-scripts-and-writes-onto-them-taint-risk)
  - [2026-11-07 — Bank leftovers: broken non-combined bank path, Forever gold tooltip, leaked globals](#2026-11-07--bank-leftovers-broken-non-combined-bank-path-forever-gold-tooltip-leaked-globals)
  - [2026-11-07 — SaftUI-Loot writes onto Blizzard frames and globals (taint risk)](#2026-11-07--saftui-loot-writes-onto-blizzard-frames-and-globals-taint-risk)
  - [2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite](#2026-11-05--aura-filters-and-per-aura-styling-lost-in-the-ouf-aura-container-rewrite)
- [Resolved](#resolved)
- [Abandoned](#abandoned)

## Active

### 2026-11-07 — SaftUI-Minimap's bar replaces Blizzard frame scripts and writes onto them (taint risk)

**What:** `MicroMenu:OnEnable` (`SaftUI-Minimap/micromenu.lua`) uses AceHook's `self:HookScript(button, 'OnShow'/'OnHide', 'UpdateButtons')` on every bar piece. Several of those are Blizzard frames: `MinimapCluster.ZoneTextButton`, `AddonCompartmentFrame`, the tracking frame, `ExpansionLandingPageMinimapButton`, the mail frame and `QueueStatusButton`. AceHook's non-secure `HookScript` calls `frame:SetScript` with an addon wrapper, so Blizzard's own OnShow/OnHide handlers then always run tainted. The bar also writes Lua fields onto those frames: `st:SetBackdrop`/`st:SkinButton` add `.backdrop`, `.thick`, `.hover`, `.pushed` and `.disabled`, the bar code adds `.width` and `.text`, and the tracking skin adds `.SaftIcon`. `expansionbutton.lua` replaces the button's OnEnter/OnLeave with `st.dummy`.

**Why noticed:** On 2026-11-07, while skinning Blizzard's micro menu into the bar (`SaftUI-Minimap/microbuttons.lua`). That work had to avoid writing onto Blizzard frames because of the `3211006` combat `ADDON_ACTION_BLOCKED`. Reading `micromenu.lua` showed the existing bar pieces don't follow that rule. I confirmed the AceHook behavior in `SaftUI-Core/Libraries/Ace3/AceHook-3.0/AceHook-3.0.lua`: the non-secure script path calls `obj:SetScript(method, uid)`, and `SecureHookScript` calls `obj:HookScript`.

**Anchors:** `SaftUI-Minimap/micromenu.lua` (`OnEnable`, `UpdateButtons`, `SkinTrackingButton`), `zonetextbutton.lua`, `addoncompartmentframe.lua`, `expansionbutton.lua`, `queuebutton.lua`; `SaftUI-Core/Widgets/button.lua` (`st:SkinButton`); `SaftUI-Core/panels.lua` (`st:SetBackdrop`).

**What's been considered:**
- Switching to `self:SecureHookScript` (or native `frame:HookScript`) is a drop-in fix for the script replacement.
- The field writes need SaftUI-owned backdrop frames kept in a local lookup table, the way `microbuttons.lua` does, instead of `st:SetBackdrop` on the Blizzard frame.
- `QueueStatusButton` is the riskiest piece: Blizzard reads and anchors it from the micro menu and the queue UI.

**Shape of work:** Small to medium. The hook swap is a few lines. Moving backdrops off Blizzard frames touches each bar-piece skin file, and needs an in-game check that the bar still lays out and reacts to show/hide.

**Open questions:** Has any of this caused a real `ADDON_ACTION_BLOCKED` so far, or is it latent? Check the BugGrabber log before prioritizing.

### 2026-11-07 — Bank leftovers: broken non-combined bank path, Forever gold tooltip, leaked globals

**What:** Three bank problems found while adding the bank bag slot bar (`4f86164`, `f3d2d4b`, `3ec5a77`), all outside that change:
1. The non-combined bank path is broken on both clients. `InitializeReagentBank` doesn't exist, and `InitializeWarbandBank` uses `AccountBankPanel`, which doesn't exist either.
2. The gold tooltip still shows a "Warband bank" line on Forever.
3. `warbandbank.lua` leaks `depositButton` and `withdrawButton` as globals.

**Why noticed:** Reported by the agent that built the Forever bank changes on 2026-11-07, at the user's request: bank slot bar with purchasing, hiding the money controls outside retail, and hiding the useless reagent "0/0".

**Anchors:** `SaftUI-Bags/containers/bank.lua`, `combinedbank.lua`, `warbandbank.lua`; the gold tooltip in `SaftUI-Bags` (grep "Warband").

**What's been considered:** The combined bank is the path in use, so item 1 only matters if the separate-bank option is turned on. Gate item 2 on `st.forever`, like the money controls.

**Shape of work:** Small. Make the three fixes, or delete the dead non-combined path if it's not worth keeping.

**Open questions:** Is the non-combined bank layout still wanted at all?

### 2026-11-07 — SaftUI-Loot writes onto Blizzard frames and globals (taint risk)

**What:** `SaftUI-Loot/init.lua` `LT:OnEnable` replaces a method on a Blizzard frame (`AlertFrame.SetAlertsEnabled = st.dummy`) and sets Blizzard globals (`LOOTFRAME_AUTOLOOT_RATE`, `LOOTFRAME_AUTOLOOT_DELAY`). Either can taint Blizzard code that later reads them.

**Why noticed:** On 2026-11-07, while planning edit mode Task 6 (loot movers), right after tracking a combat `ADDON_ACTION_BLOCKED` to SaftUI-Minimap's micro button alert hook (`3211006`). That bug was the same pattern: addon code writing state that secure Blizzard code reads before a protected call. Task 6 removes the `GroupLootContainer` writes; these two are outside its scope.

**Anchors:** `SaftUI-Loot/init.lua` (`LT:OnEnable`); `AlertFrame` (`Blizzard_FrameXML` AlertFrameSystems); BugGrabber log at `E:\Games\World of Warcraft\_forever_\WTF\Account\JMMH\SavedVariables\!BugGrabber.lua`.

**What's been considered:** `AlertFrame:SetAlertsEnabled(false, reason)` is Blizzard's API for this, so the call is fine and only the method replacement is the problem. If something re-enables alerts, a `hooksecurefunc` on `SetAlertsEnabled` that re-disables would be the taint-safe version. Check the autoloot globals against Forever's LootFrame code before deciding.

**Shape of work:** Small: one or two lines in `init.lua` plus an in-game check that loot and boss toasts stay hidden.

**Open questions:** Does anything in combat read `AlertFrame.SetAlertsEnabled` or the autoloot globals? If not, this is cosmetic risk only.

### 2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite

**What:** Buffs/Debuffs were rebuilt on oUF master's Auras meta element (Blizzard `AuraContainer`). Several aura config options no longer do anything: the `filter.whitelist`, `filter.blacklist` and `filter.time` settings, `desaturateOthers`, and changing group options (`max`, `size`, `onlyShowPlayer`, borders) without a `/reload`.

**Why noticed:** Swapping SaftUI-Unitframes from the old bundled oUF copies to oUF-wow/oUF master (`c5ff6e4`). Master removed the classic `Buffs`/`Debuffs` element and its `FilterAura`/`PostUpdateButton` callbacks. The new containers process auras natively and don't hand aura data to Lua, which is consistent with Midnight's secret values. So SaftUI's Lua filters had nothing to run against. All of the lost filters were disabled in the defaults at the time, so no default behaviour changed.

**Anchors:** `SaftUI-Unitframes/elements/auras.lua` (commit `255a5ae`), `SaftUI-Unitframes/config/default.lua` (`auras` / `buffs` / `debuffs` tables), `SaftUI-Unitframes/Libraries/oUF/elements/auras.lua` (`AddGroup`, `AddSlot`, `CreateButton`).

**What's been considered:**
- Group options include a `candidateFilters` table (the oUF docs show `includeSpellIDs` on `AddSlot`). That could replace the spell whitelist, and possibly the blacklist, if the group options support the same keys. Verify against `CustomAuraContainerGroupDefaultOptions` on warcraft.wiki.gg.
- Duration filtering may be expressible through the container's processing `policy` (`CustomAuraContainerAuraProcessingPolicy`).
- Live updates to group options would need either an AuraContainer API to remove or clear groups, or recreating the container on config change.

**Shape of work:** A research pass on the AuraContainer API (group options, policies, removing groups), then a small change in `elements/auras.lua` that maps config to options. It may also need a config-schema cleanup to drop options that can't be supported.

**Open questions:** Does AuraContainer support removing or replacing groups at runtime? Which of the old filter options are worth keeping at all?

## Resolved

(items move here when ticketed and shipped, or fixed inline — keep for historical context, prune when the file gets long)

## Abandoned

(items move here when explicitly decided against — note the reason in a one-line addendum so the decision is recoverable)
