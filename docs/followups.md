# Followups

A queue between "noticed it" and "decided what to do about it." Items might become Jira tickets, get fixed inline during related work, or be explicitly abandoned. Triage periodically.

Format: see the user-level `~/.claude/CLAUDE.md` "Followup detection" section.

## Contents

- [Active](#active)
  - [2026-11-07 — Chat mover leftovers: overlay reach-in, anchor in Blizzard layout, clamp dead zone](#2026-11-07--chat-mover-leftovers-overlay-reach-in-anchor-in-blizzard-layout-clamp-dead-zone)
  - [2026-11-07 — Profile switch: Show/Hide on protected frames in combat, mover/unit-frame anchor swaps](#2026-11-07--profile-switch-showhide-on-protected-frames-in-combat-moverunit-frame-anchor-swaps)
  - [2026-11-07 — Profile settings that still need a /reload after a profile switch](#2026-11-07--profile-settings-that-still-need-a-reload-after-a-profile-switch)
  - [2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite](#2026-11-05--aura-filters-and-per-aura-styling-lost-in-the-ouf-aura-container-rewrite)
- [Resolved](#resolved)
  - [2026-11-07 — Party and raid unit frames: re-enable headers and add edit mode movers](#2026-11-07--party-and-raid-unit-frames-re-enable-headers-and-add-edit-mode-movers)
  - [2026-11-07 — SaftUI-Minimap's bar replaces Blizzard frame scripts and writes onto them (taint risk)](#2026-11-07--saftui-minimaps-bar-replaces-blizzard-frame-scripts-and-writes-onto-them-taint-risk)
  - [2026-11-07 — Bank leftovers: broken non-combined bank path, Forever gold tooltip, leaked globals](#2026-11-07--bank-leftovers-broken-non-combined-bank-path-forever-gold-tooltip-leaked-globals)
  - [2026-11-07 — SaftUI-Loot writes onto Blizzard frames and globals (taint risk)](#2026-11-07--saftui-loot-writes-onto-blizzard-frames-and-globals-taint-risk)
- [Abandoned](#abandoned)

## Active

### 2026-11-07 — Chat mover leftovers: overlay reach-in, anchor in Blizzard layout, clamp dead zone

**What:** Three minor items left after the chat frame became a mover (Task 12, `2ad2e90`) and SaftUI took over its size (`ccfcaa2`):
1. `SaftUI-Chat` re-anchors the edit mode mover's overlay (`mover.overlay`, a Core internal) to cover the chat plus padding. A Core API for a mover's footprint (e.g. `def.footprint` or an `overlayInsets` field) would replace that reach-in.
2. Blizzard's `UpdateSystemAnchorInfo` copies ChatFrame1's current anchor into Blizzard's saved Edit Mode layout. A Blizzard Save can store SaftUI's placement there. It's harmless while SaftUI-Chat is on, but with it off the chat comes back at that spot instead of Blizzard's.
3. Blizzard clamps the chat frame about 32px from the screen's left and bottom edges (`UpdateClampOffsets`). SaftUI's holder isn't clamped, so dragging the outline into that band leaves the outline and the chat apart.

**Why noticed:** The Task 12 review and the fix round (`.superpowers/sdd/2026-11-06-saftui-edit-mode/task-12-review.md`).

**Anchors:** `SaftUI-Chat/chatframe.lua` (holder, `PlaceChatFrame`, overlay re-anchor); `SaftUI-Core/EditMode/mover.lua` (overlay creation).

**Shape of work:** Small. A footprint option in `st:RegisterMover`; clamp the holder with the same insets; item 2 may just be documented.

### 2026-11-07 — Profile switch: Show/Hide on protected frames in combat, mover/unit-frame anchor swaps

**What:** Two gaps left after the profile-switch fix round (`a44a62f`..`6764cb5`):
1. `Show`/`Hide` on frames that can be implicitly protected (a unit frame anchored to them) isn't deferred in combat. That covers the XP bars in `UpdateExperience`/`UpdateReputation`, the loot feed lines, and the roll test previews. This was already true before.
2. Out of combat, if a mover and a unit frame swap which one anchors to the other between two profiles, the module pass can raise one anchor-loop error. The final edit mode pass still places both correctly.

**Why noticed:** Reported by the agent that fixed the profile-switch review findings on 2026-11-07. Background: the review (`.superpowers/sdd/2026-11-06-saftui-edit-mode/review-profile.md`, I1) found that in-combat profile switches moved frames that became protected because a secure unit frame was anchored to them. The fix added `st:CanMoveNow`/`st:SafeReposition` for positioning, but not for visibility.

**Anchors:** `SaftUI-Core/api.lua` (`st:SafeReposition`, `st:CanMoveNow`); `SaftUI-Misc/experience.lua`; `SaftUI-Loot/Feed/feed.lua`; `SaftUI-Loot/roll.lua` (previews); `SaftUI-Core/Config/config.lua` (`Config:UpdateConfig` order).

**What's been considered:** Item 1 only matters if someone anchors a unit frame to one of these frames. Item 2 is cosmetic: one reported error, and the result is still correct.

**Shape of work:** Small. Route the Show/Hide calls through a `CanMoveNow`-style check with deferral. For item 2, clear unit frame and mover anchors in the same pass before placing either.

### 2026-11-07 — Profile settings that still need a /reload after a profile switch

**What:** Switching the SaftUI profile now re-applies almost everything live (every module's `UpdateConfig`, run in order by `Config:UpdateConfig`). A few profile settings still only take effect on `/reload`:
1. Aura group options on unit frames: filter (`onlyShowPlayer`), `max`, button `size`, and which borders show. They're baked into the `AuraContainer` group when it's made. This is the open question in the aura-container followup below.
2. `chat.tabs.fade`: turning fading off replaces `Tab.SetAlpha` on Blizzard's chat tabs at enable. Undoing or redoing that live would mean more writes onto Blizzard frames.
3. Module on/off switches such as `inventory.enable`, and `minimap.compartment_buttons` (its option already says it needs a reload).
4. ~~Party and raid group headers: their size and layout attributes are set at spawn.~~ **Resolved 2026-11-07** (edit mode Task 15): `UF:ApplyGroupLayout` (`SaftUI-Unitframes/groups.lua`) re-applies every header attribute, resizes the buttons, and re-registers the visibility on option edits and profile switches. In combat it waits for combat to end. Nothing in the headers needs a reload now.
5. Templates, colors, headers and buttons have no options UI, so they're the same in every profile unless the saved variables are edited by hand. Modules re-apply their own templates on a switch, but frames styled once at creation with a fixed template (header bars, close buttons, edit mode overlays, the /sui window) don't pick up a profile's different template colors. `st.template_cache` and `Config:UpdateTemplateConfig` look meant for this, but `UpdateTemplateConfig` reads `self.template_cache` on the Config module (it lives on `st`) and loops without `pairs`, so it never worked.

**Why noticed:** On 2026-11-07, while making profile switches apply live across all modules and unit frames. The user asked for "update steps for those modules and for unit frames so that everything cleanly changes" on a profile switch, instead of needing a `/reload`. These were the pieces that couldn't be made live cleanly in that pass.

**Anchors:** `SaftUI-Core/Config/config.lua` (`Config:UpdateConfig`), `SaftUI-Unitframes/elements/auras.lua` (`AddGroup`), `SaftUI-Chat/chatframe.lua` (`SkinChatFrame`, `tabs.fade`), `SaftUI-Bags/inventory.lua` (`OnEnable`), `SaftUI-Core/panels.lua` (`st:SetTemplate`, `template_cache`), `SaftUI-Core/Config/widgets.lua` (`UpdateTemplateConfig`).

**What's been considered:**
- Item 3 matches the rest of the UI: module toggles generally need a reload. A "Reload to apply" message on a switch that changes one would be enough.
- For item 2, a `hooksecurefunc` on each tab's `SetAlpha` that re-applies alpha 1 while fading is off would be taint-safe and could follow the profile.
- For item 5, fixing `UpdateTemplateConfig` (`pairs(st.template_cache)`, and recording the latest template per frame) would re-color every templated frame. But it would also reset borders that modules recolor after `SetBackdrop` (bag slot quality, the edit mode overlay, the unit tooltip), so those would need re-applying after it.

**Shape of work:** Small items, separable: a reload hint for 3, a tab `SetAlpha` hook for 2, and a template re-color pass for 5 if template options ever get a UI. Item 1 depends on the aura-container research.

**Open questions:** Will templates or colors ever get options? If not, item 5 can be dropped.

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

### 2026-11-07 — Party and raid unit frames: re-enable headers and add edit mode movers

**What:** Party, raid10 and raid40 frames aren't spawned: `CreateGroupHeaders()` and the groups loop in `UF:GetConfigTable` are commented out. So they got no edit mode mover in Task 10 (`3c0108b`). `CreateGroupHeaders` also looks broken: party passes a table to `SpawnHeader`, and there's an `oUF-initiateConfigFunction` typo. Arena is commented out of `UF.unit_strings` too.

**Why noticed:** Reported by the Task 10 agent (unit frames as movers) on 2026-11-07. Only boss is a spawned group. It got a holder frame (`SaftUI_BossHolder`) sized from its config, so the outline shows with no boss up.

**Anchors:** `SaftUI-Unitframes/unitframes.lua` (`CreateGroupHeaders`, `UF.unit_strings`, `UF:RegisterMovers`, the boss holder code); `SaftUI-Unitframes/config/config.lua` (the groups loop).

**What's been considered:** Re-use the boss holder pattern for each header. Size the holder from `unitsPerColumn`, `maxColumns` and spacing, and anchor the header to the holder. Headers are secure, so only move them out of combat.

**Shape of work:** Medium. Fix and re-enable the headers, add holders and movers, and add `/sui` sections.

**Resolved 2026-11-07:** Edit mode Task 15 (`unitframes: re-enable party and raid frames as movers`). The headers were rebuilt in `SaftUI-Unitframes/groups.lua`: fixed attributes (the `oUF-initialConfigFunction` typo, signed offsets), visibility by group kind and raid size, every unit button made out of combat, and live re-apply on option edits and profile switches. Each group got a holder mover (`uf_party`, `uf_raid10`, `uf_raid40`), `/sui` sections with a Layout group, and a session-only test mode with SaftUI-owned preview frames. Arena is still commented out of `UF.unit_strings`.

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

**Also (2026-11-07, retail only):** Blizzard's `MicroMenu:Layout` re-anchors `QueueStatusButton` to its own micro menu on every layout, which can pull the queue eye out of SaftUI's bar. Forever doesn't do this. Found while putting the micro buttons inline (`116e9b6`).

**Resolved 2026-11-07:** Fixed inline on `fu-minimap-taint` (`18398ef`, `a7a112b`, `79568a2`). Every hook on a Blizzard frame or function in SaftUI-Minimap is now a post-hook (native `HookScript`, `hooksecurefunc`, AceHook `SecureHook`). The expansion button keeps Blizzard's OnEnter/OnLeave and hides the tooltip in a post-hook. Blizzard's clock and difficulty frame are hidden with `Hide()` plus an OnShow post-hook instead of `st:Kill`/`st:Hide`. Bar item data (width, template, text, backdrop) lives in a weak table in `micromenu.lua`, every panel is a SaftUI frame, and `MicroMenu:SkinBarButton` replaces `st:SkinButton` on Blizzard buttons; the minimap's own panel moved off `Minimap` too. The queue eye is put back after live's `UpdatePosition` and Forever's `UpdateDefaultAnchor`/`SetEditModeScale`, and Forever's `SetHeaderUnderneath` and the expansion button's `UpdateIcon` get the same relayout. Open question, answered from Blizzard's source (the BugGrabber log wasn't checked): on Forever the eye is an Edit Mode system whose Lua `SetPoint`/`ClearAllPoints` the bar was calling, which wrote Edit Mode snap state and `EditModeManagerFrame.editModeSystemAnchorDirty` under SaftUI's taint (bar items now use `st:SetPointDirect`/`st:ClearAllPointsDirect`). The other field writes were latent: no Blizzard code reads those keys. Left as is: `minimapbuttons.lua` still `tremove`s its entries from `AddonCompartmentFrame.registeredAddons` (no Unregister API on either client, same as LibDBIcon), and the mail frame's OnEvent still calls the container's Lua `Layout` no-op as its last statement.

(items move here when ticketed and shipped, or fixed inline — keep for historical context, prune when the file gets long)

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

**Resolved 2026-11-07:** Removed the reagent button (no reagent bank on either client), pointed the warband window at `BankPanel` and `ACCOUNT_MONEY` instead of the missing `AccountBankPanel`, gated the warband button and gold tooltip line on `INV:HasWarbandBank()` (not Forever), and made the deposit/withdraw buttons local.

### 2026-11-07 — SaftUI-Loot writes onto Blizzard frames and globals (taint risk)

**What:** `SaftUI-Loot/init.lua` `LT:OnEnable` replaces a method on a Blizzard frame (`AlertFrame.SetAlertsEnabled = st.dummy`) and sets Blizzard globals (`LOOTFRAME_AUTOLOOT_RATE`, `LOOTFRAME_AUTOLOOT_DELAY`). Either can taint Blizzard code that later reads them.

**Why noticed:** On 2026-11-07, while planning edit mode Task 6 (loot movers), right after tracking a combat `ADDON_ACTION_BLOCKED` to SaftUI-Minimap's micro button alert hook (`3211006`). That bug was the same pattern: addon code writing state that secure Blizzard code reads before a protected call. Task 6 removes the `GroupLootContainer` writes; these two are outside its scope.

**Anchors:** `SaftUI-Loot/init.lua` (`LT:OnEnable`); `AlertFrame` (`Blizzard_FrameXML` AlertFrameSystems); BugGrabber log at `E:\Games\World of Warcraft\_forever_\WTF\Account\JMMH\SavedVariables\!BugGrabber.lua`.

**What's been considered:** `AlertFrame:SetAlertsEnabled(false, reason)` is Blizzard's API for this, so the call is fine and only the method replacement is the problem. If something re-enables alerts, a `hooksecurefunc` on `SetAlertsEnabled` that re-disables would be the taint-safe version. Check the autoloot globals against Forever's LootFrame code before deciding.

**Shape of work:** Small: one or two lines in `init.lua` plus an in-game check that loot and boss toasts stay hidden.

**Open questions:** Does anything in combat read `AlertFrame.SetAlertsEnabled` or the autoloot globals? If not, this is cosmetic risk only.

**Resolved 2026-11-07:** Dropped the `AlertFrame.SetAlertsEnabled` replacement (alerts stay off through a SaftUI-only reason key) and the `LOOTFRAME_AUTOLOOT_*` writes (nothing in the live or forever source reads them).

## Abandoned

(items move here when explicitly decided against — note the reason in a one-line addendum so the decision is recoverable)
