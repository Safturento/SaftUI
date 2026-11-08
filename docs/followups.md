# Followups

A queue between "noticed it" and "decided what to do about it." Items might become Jira tickets, get fixed inline during related work, or be explicitly abandoned. Triage periodically.

Format: see the user-level `~/.claude/CLAUDE.md` "Followup detection" section.

## Contents

- [Active](#active)
  - [2026-11-08 — Specialty bags (herb, mining, etc.) count as normal bags in the bag window](#2026-11-08--specialty-bags-herb-mining-etc-count-as-normal-bags-in-the-bag-window)
  - [2026-11-07 — Minimap pieces still belong to MinimapCluster, which stretches across the screen](#2026-11-07--minimap-pieces-still-belong-to-minimapcluster-which-stretches-across-the-screen)
  - [2026-11-07 — Extra buttons leftovers: zone ability hidden by Blizzard's bar settings, Blizzard's art, skinned vehicles' pitch and status bars](#2026-11-07--extra-buttons-leftovers-zone-ability-hidden-by-blizzards-bar-settings-blizzards-art-skinned-vehicles-pitch-and-status-bars)
  - [2026-11-07 — Pet and stance bar leftovers: spellbook highlight, pings, pickup click, autocast names after an in-combat pet swap](#2026-11-07--pet-and-stance-bar-leftovers-spellbook-highlight-pings-pickup-click-autocast-names-after-an-in-combat-pet-swap)
  - [2026-11-07 — Tooltip skin writes .backdrop onto Blizzard's tooltips](#2026-11-07--tooltip-skin-writes-backdrop-onto-blizzards-tooltips)
  - [2026-11-07 — Fonts outline dropdowns show None as a blank entry](#2026-11-07--fonts-outline-dropdowns-show-none-as-a-blank-entry)
  - [2026-11-07 — Unit frame defaults that nothing reads, or that break when turned on](#2026-11-07--unit-frame-defaults-that-nothing-reads-or-that-break-when-turned-on)
  - [2026-11-07 — Action bar leftovers: main bar concealed not blocked, LibActionButton on deprecated APIs, unskinned flyouts](#2026-11-07--action-bar-leftovers-main-bar-concealed-not-blocked-libactionbutton-on-deprecated-apis-unskinned-flyouts)
  - [2026-11-07 — Chat mover leftovers: overlay reach-in, anchor in Blizzard layout, clamp dead zone](#2026-11-07--chat-mover-leftovers-overlay-reach-in-anchor-in-blizzard-layout-clamp-dead-zone)
  - [2026-11-07 — Profile switch: Show/Hide on protected frames in combat, mover/unit-frame anchor swaps](#2026-11-07--profile-switch-showhide-on-protected-frames-in-combat-moverunit-frame-anchor-swaps)
  - [2026-11-07 — Profile settings that still need a /reload after a profile switch](#2026-11-07--profile-settings-that-still-need-a-reload-after-a-profile-switch)
  - [2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite](#2026-11-05--aura-filters-and-per-aura-styling-lost-in-the-ouf-aura-container-rewrite)
- [Resolved](#resolved)
  - [2026-11-07 — No way to cancel a possess](#2026-11-07--no-way-to-cancel-a-possess)
  - [2026-11-07 — Unit frame indicators ignore their enable setting once oUF updates them](#2026-11-07--unit-frame-indicators-ignore-their-enable-setting-once-ouf-updates-them)
  - [2026-11-07 — Blizzard's raid frames still show next to SaftUI's raid frames](#2026-11-07--blizzards-raid-frames-still-show-next-to-saftuis-raid-frames)
  - [2026-11-07 — Party and raid unit frames: re-enable headers and add edit mode movers](#2026-11-07--party-and-raid-unit-frames-re-enable-headers-and-add-edit-mode-movers)
  - [2026-11-07 — SaftUI-Minimap's bar replaces Blizzard frame scripts and writes onto them (taint risk)](#2026-11-07--saftui-minimaps-bar-replaces-blizzard-frame-scripts-and-writes-onto-them-taint-risk)
  - [2026-11-07 — Bank leftovers: broken non-combined bank path, Forever gold tooltip, leaked globals](#2026-11-07--bank-leftovers-broken-non-combined-bank-path-forever-gold-tooltip-leaked-globals)
  - [2026-11-07 — SaftUI-Loot writes onto Blizzard frames and globals (taint risk)](#2026-11-07--saftui-loot-writes-onto-blizzard-frames-and-globals-taint-risk)
- [Abandoned](#abandoned)

## Active

### 2026-11-08 — Specialty bags (herb, mining, etc.) count as normal bags in the bag window

**What:** The bag window marks the reagent bag's items and empty slots (a green corner wedge), and the Empty Slots category's Grouped mode has one slot for the normal bags and one for the reagent bag. A specialty bag (herb, mining, enchanting, etc.) is treated as a normal bag: its items get no marker, and its free slots are counted in the normal group even though they only take that profession's items. Grouped's normal slot points at the first free normal-kind slot, which can be in a specialty bag, so dropping a non-matching item on it fails with the game's "That item doesn't go in that container" error.

**Why noticed:** Brainstorming the reagent marker and Empty Slots category (2026-11-08). The user's problem was telling reagent bag items apart when moving reagents into a new reagent bag and swapping which items stay there. Specialty bags have the same "only some items fit" shape, but the user only raised the reagent bag, so they were left out to keep the change small.

**Anchors:** `SaftUI-Bags/category.lua` (`GetSortedInventory`, the empty slot groups), `SaftUI-Bags/slot.lua` (`AssignSlot`, the marker). `C_Container.GetContainerNumFreeSlots(bagID)` returns the bag's family as its second value (0 for a normal bag).

**What's been considered:** Grouping empty slots by bag family instead of normal/reagent would handle specialty bags with no special cases, and the first free slot of a normal-family bag would then always take any item. The marker would need a colour or shape per family, or one shared "special bag" marker.

**Shape of work:** Small: group by bag family in the empty slot code, pick the Grouped normal slot from family-0 bags only, and decide the marker for specialty bags.

**Open questions:** Does the user (or anyone on Forever) use specialty bags enough to want them marked? One marker for all of them, or per profession?

### 2026-11-07 — Minimap pieces still belong to MinimapCluster, which stretches across the screen

**What:** SaftUI-Minimap moves Blizzard's minimap pieces (zone text, tracking, mail/crafting indicator, instance difficulty, and others hosted in its micro menu bar) to SaftUI's spots, but they stay children of `MinimapCluster`. The cluster is a `ResizeLayoutFrame`, so it grows to cover them and spans the top of the screen. It was also eating clicks there. That part is fixed: the cluster is now click-through (`SaftUI-Minimap/minimap.lua`, `MinimapCluster:EnableMouse(false)`). The cluster is still huge, though, and anything else that reads its size (Blizzard's Edit Mode snapping, managed-frame layout) sees the stretched rect.

**Why noticed:** On 2026-11-07 the user found a full-width strip across the top of the screen that couldn't be clicked. `/fstack` showed `MinimapCluster` covering it. There's an old `-- TODO: figure out how to stop cluster resizing` in `minimap.lua`'s `OnEnable` about the same thing.

**Anchors:** `SaftUI-Minimap/minimap.lua` (`OnEnable`), `micromenu.lua` (mail and tracking hosting), `zonetextbutton.lua`, `instancedifficulty.lua`, `queuebutton.lua`, `addoncompartmentframe.lua`; Blizzard's `Blizzard_Minimap/Mainline/Minimap.xml` (`MinimapCluster` inherits `ResizeLayoutFrame`, `enableMouse="true"`) and `Minimap.lua` (`MinimapClusterMixin`), on `forever` and `live`.

**What's been considered:**
- Mark the moved pieces `ignoreInLayout` so the cluster's layout skips them: that writes a field onto Blizzard frames, against rule 1 in `.agents/taint.md`.
- Reparent the pieces to SaftUI frames: takes them out of the layout, but Blizzard's code for them may expect the cluster as parent (`GetParent()` calls in their mixins), and `SetParent` on a shown frame runs its scripts. Needs a per-piece read of Blizzard's code on both clients.
- Replace the pieces with SaftUI's own (zone text and the mail indicator are easy; tracking has Blizzard's menu behind it): no Blizzard frames moved at all, but more to build.

**Shape of work:** A research pass per piece on both clients, then either reparenting the safe ones or SaftUI replacements. One focused change in SaftUI-Minimap.

**Open questions:** Does anything visible go wrong with the stretched cluster now that it's click-through? If not, this can wait.

### 2026-11-07 — Extra buttons leftovers: zone ability hidden by Blizzard's bar settings, Blizzard's art, skinned vehicles' pitch and status bars

**What:** Three gaps left by `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`: two from Task 5 (the extra action button, zone ability and leave vehicle button, `SaftUI-ActionBars/extras.lua`), one from hiding Blizzard's override bar (Task 1, `SaftUI-ActionBars/hideblizzard.lua`):
1. **The zone ability can hide behind a SaftUI bar that's off, or show twice.** `ZoneAbilityFrameMixin:UpdateDisplayedZoneAbilities` leaves out a zone spell that's on an active action bar (`ActionButtonUtil.IsSpellOnAnyActiveMkbActionBar` on forever, `IsSpellOnAnyActiveActionBar` on live). For the multibars "active" means on in Blizzard's own Action Bars settings, not SaftUI's Enable. So a zone spell on a slot of a SaftUI bar that's off, whose Blizzard bar is on in Blizzard's settings, shows nowhere; and one on an enabled SaftUI bar whose Blizzard bar is off in Blizzard's settings shows twice.
2. **The extra action button and zone ability keep Blizzard's look**, art included, scaled by a Scale setting. They're Blizzard's buttons, so SaftUI's skin (`st:SetBackdrop` writes `.backdrop`) can't go on them as it is.
3. **A skinned vehicle loses Blizzard's pitch buttons and its vehicle health, power and XP bars.** They're parts of `OverrideActionBar` (`pitchFrame` with `PitchUpButton`/`PitchDownButton`, `OverrideActionBarHealthBar`, `OverrideActionBarPowerBar`, `xpBar`), which `hideblizzard.lua` blocks, events and all. SaftUI's leave vehicle button replaces the bar's leave button, and bar 1 takes its abilities ([vehicleui]/[overridebar] paging), but nothing replaces the rest. The `VEHICLEAIMUP`/`VEHICLEAIMDOWN` keys still aim (they call `VehicleAimUpStart` and friends from Blizzard's bindings), and SaftUI's player frame can show the vehicle, but a pitch-aimed vehicle (catapults, siege turrets) is hard to aim by mouse. ElvUI hides the bar the same way.

**Why noticed:** Reading Blizzard's source for Task 5. Item 1 from `Blizzard_ZoneAbility/ZoneAbility.lua` and `ActionButtonUtil.GetMkbActionBarsForSpell` ("MultiActionBar: Active if not disabled via Action Bar settings"). Item 2 is the Scale-not-size choice in `extras.lua`: the buttons' art and masks are fixed-size textures. Item 3 is Minor 1 of the SaftUI-ActionBars final review, which also turned the override bar's events off to keep Blizzard's micro menu out of the blocked bar (Important 1). The possess cancel that used to be item 1 here is resolved (see Resolved).

**Anchors:** `SaftUI-ActionBars/extras.lua`, `SaftUI-ActionBars/hideblizzard.lua` (`OverrideActionBar`); `ZoneAbilityFrameMixin:UpdateDisplayedZoneAbilities`, `ActionButtonUtil.GetMkbActionBarsForSpell`; `Blizzard_OverrideActionBar/OverrideActionBar.xml` and `.lua` (`pitchFrame`, `CalcSize`, the `UNIT_ENTERING_VEHICLE` `HasPitch` flag, `VEHICLE_ANGLE_UPDATE`), the `VEHICLEAIMUP`/`VEHICLEAIMDOWN` bindings (`Bindings_Standard.xml`).

**What's been considered:** For 1, keeping Blizzard's multibar settings in step with SaftUI's Enable would mean writing Blizzard's settings; more likely just document it. For 2, a "hide art" toggle is one `SetAlpha(0)` on `ExtraActionButton1.style` and `ZoneAbilityFrame.Style` (Blizzard only sets their texture and shown state); a full skin would keep SaftUI's backdrop in a local table, as the tooltip skin followup suggests. For 3, SaftUI pitch buttons next to the leave vehicle button, shown in a vehicle that has pitch (Blizzard reads it from `UNIT_ENTERING_VEHICLE`'s sixth argument), whose mouse down/up call `VehicleAimUpStart`/`VehicleAimUpStop` and the down pair, plus a marker from `VEHICLE_ANGLE_UPDATE`. Check first whether those calls are protected. The vehicle's health and power belong to SaftUI's player frame, which oUF swaps to the vehicle.

**Shape of work:** 1 is a note or nothing. 2 is a toggle, or a small skin pass. 3 is a small pitch holder in `extras.lua` plus an in-game check in a catapult or turret.

### 2026-11-07 — Pet and stance bar leftovers: spellbook highlight, pings, pickup click, autocast names after an in-combat pet swap

**What:** SaftUI's pet and stance bars (Task 4 of `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`) are SaftUI's own secure buttons, not Blizzard's, so four small things Blizzard's pet and stance buttons do are missing:
1. Hovering a pet spell in the spellbook doesn't highlight it on SaftUI's pet bar. Blizzard's spellbook calls `PetActionBar:UpdatePetActionHighlightMarks` and `PetActionBar:Update()`, which only reach Blizzard's hidden bar.
2. Pet and stance buttons can't be pinged. Blizzard's action buttons set the `ping-receiver` attribute (`PingableType_ActionButtonMixin:UpdatePingAttributes`); SaftUI's don't, and their `GetActionButtonInfo` is the template's nil.
3. A click with the pickup modifier (Shift by default) on a pet button does nothing; picking a pet action up needs a drag. Blizzard's button picks it up on the click itself (`PickupPetAction` in its OnClick).
4. Right-click autocast uses `/petautocasttoggle <name>`, set out of combat. After a pet is summoned or swapped in combat, right-click toggles by the old pet's names until combat ends.

**Why noticed:** Building Task 4. Item 1 came from grepping the forever and live source for `PetActionBar:` callers outside its own file (`Blizzard_PlayerSpells/SpellBook/Blizzard_SpellBookItem.lua`). Item 2 from reading `Blizzard_SharedXML/PingableType.lua`. Items 3 and 4 are choices made in `SaftUI-ActionBars/petbar.lua`: the pickup click is stopped by the secure pre-click snippet so the action isn't cast, and the autocast toggle goes through a secure macro command because Blizzard calls `TogglePetAutocast` from its secure click handler.

**Anchors:** `SaftUI-ActionBars/petbar.lua` (`PRE_CLICK`, `UpdateActions`), `SaftUI-ActionBars/stancebar.lua`, `SaftUI-ActionBars/buttons.lua`; `PET_ACTION_HIGHLIGHT_MARKS` and `C_ActionBar.GetPetActionPetBarIndices` in `Blizzard_ActionBar/Shared/PetActionBar.lua`; `PingableType_ActionButtonMixin`.

**What's been considered:** For 1, a `hooksecurefunc` on `PetActionBarMixin.UpdatePetActionHighlightMarks` could read `C_ActionBar.GetPetActionPetBarIndices` and show the template's `SpellHighlightTexture` on SaftUI's buttons. For 2, `GetActionButtonInfo` returning the spell ID, plus setting `ping-receiver` out of combat when a slot fills. For 3, the snippet could leave the click to an insecure `PostClick` that calls `PickupPetAction` out of combat. For 4, nothing better fits: attributes can't change in combat, and no secure button type toggles autocast.

**Shape of work:** Small, each one independent: a hook for 1, two methods and an attribute for 2, a few lines in `petbar.lua` for 3. 4 is a known limit.

### 2026-11-07 — Tooltip skin writes .backdrop onto Blizzard's tooltips

**What:** `SaftUI-Misc/tooltip.lua` skins Blizzard's tooltips with `st:SetBackdrop(GameTooltip, ...)` (also `ItemRefTooltip`, the shopping tooltips, `GameTooltipStatusBar`, `DropDownList1/2`), which writes a `.backdrop` field onto each Blizzard frame. That breaks rule 1 in `.agents/taint.md`. `GameTooltip_OnTooltipSetUnit` then reads `tooltip.backdrop` back to color the border.

**Why noticed:** The 2026-11-07 review of the tooltip mover (`f7ec45e`, review in `.superpowers/sdd/2026-11-07-saftui-action-bars/review-tooltip.md`) flagged it as outside that commit. The same review flagged AceHook's replacing `HookScript` on GameTooltip's OnShow, which is now a `SecureHookScript`.

**Anchors:** `SaftUI-Misc/tooltip.lua` (`OnEnable`, `UpdateConfig`, `UpdateTooltipDisplay`, `GameTooltip_OnTooltipSetUnit`), `SaftUI-Core/panels.lua` (`st:SetBackdrop`), `.agents/taint.md` rule 1.

**What's been considered:** Keep each tooltip's SaftUI backdrop frame in a local weak table keyed by the tooltip, as the rule says, and color it through that table. The tooltips are Blizzard frames that secure code uses heavily on Midnight (secret values), so this is worth doing before tooltip errors show up rather than after.

**Shape of work:** A small refactor of `tooltip.lua`. It may want a `st:SetBackdrop` variant that returns the backdrop frame without storing it on the target, which other skins writing onto Blizzard frames could reuse.

### 2026-11-07 — Fonts outline dropdowns show None as a blank entry

**What:** `FN.outlines` in `SaftUI-Core/Media/fonts.lua` is the `values` table for every font outline dropdown, and its `NONE` entry is `st.retail and '' or 'NONE'`. `st.retail` is true on both clients, so the None choice shows as a blank line in `/sui` → Fonts and in the Auras text options. It looks like the `''` was meant as the font flag to pass to `SetFont` rather than the label. `FN:UpdateFontConfig` passes the saved `'NONE'` straight to `SetFont`.

**Why noticed:** Building the action bars' Text options (Task 3 of `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`). `SaftUI-ActionBars/options.lua` copies the table and names None itself, and `skin.lua` maps `'NONE'` to `''` for `SetFont`, as `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua` (`OutlineFlags`) already does.

**Anchors:** `SaftUI-Core/Media/fonts.lua` (`FN.outlines`, `FN:UpdateFontConfig`); `OutlineFlags` in `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua` and `SaftUI-ActionBars/skin.lua`; `OutlineValues` in `SaftUI-ActionBars/options.lua`.

**Shape of work:** Small: label `NONE` as 'None', map `'NONE'` to `''` in `FN:UpdateFontConfig`, then drop the local copies in the action bars and auras.

### 2026-11-07 — Unit frame defaults that nothing reads, or that break when turned on

**What:** Adding `/sui` tabs for the remaining unit frame elements turned up defaults (`SaftUI-Unitframes/config/default.lua`, `config/units/*.lua`) that do nothing, or that error once turned on. They were left out of the options:
- **Read by nothing:**
  - Auras: `font` (the count always has its own `count.font`), `showDebuffType`, `horizontal_growth`, `showBar` (player buffs) and `border` (target buffs). Also the `filter` tables and `desaturateOthers`, which the aura-container followup below covers.
  - Additional power: `colorClass` (oUF's AdditionalPower only knows `colorPower`), `text.hide_full`, `text.percent`.
  - Class power: `show_empty` is read (`elements/classpower.lua`) but changes nothing, since oUF already shows every point up to the max.
  - Focus `castbar.colors.normal = { .5, .9, .7 }`: a list, but `GetRGB` reads the `r`/`g`/`b` that the base default's color fills in, so the focus castbar uses the base color.
  - Raid target `position.element = 'Portrait'`: Portrait isn't registered, so the marker anchors to the unit frame.
  - `widget` (`widget.lua` is commented out of `elements/elements.xml`, and it has no `UpdateConfig`), `portrait` and `aurawatch` (their `RegisterElement` calls are commented out).
- **Errors once on:**
  - `castbar.bg.enable`: the castbar's `bg` has no `alpha` or `multiplier`, so `UF:UpdateStatusBarElement` calls `bg:SetAlpha(nil)`. Nothing colors the background either.
  - `colorCustom` on health, power and additional power: the `customColor` defaults are plain `{ r, g, b }` lists, and `config.customColor:GetRGB()` errors on them.
- **Half done:** `additionalpower.manaAsPrimary` swaps the size, texture and text settings of the Power and AdditionalPower bars (`UF:UpdateElement`'s `configOverride`), but not their positions: `UF:UpdateElementPosition(element, unitframe, configOverride)` gets the override in its `unitframe` slot. The `Override` that would keep the bar on mana is commented out, and power's `GetDisplayPower` never runs (oUF only calls it with `displayAltPower`).
- **Looks broken:** additional power defaults to `colorPower = false`, and nothing else colors the bar or its background, so it's white once enabled. Its `/sui` option says so.

**Why noticed:** On 2026-11-07, while adding Castbar, Class power, Additional power, Buffs, Debuffs and indicator tabs to `/sui` → Unitframes (the user asked to "start adding other UF elements to the config"). The rule for that pass was to expose only settings the element code reads, and note the rest.

**Anchors:** `SaftUI-Unitframes/config/default.lua`, `config/units/focus.lua`, `config/units/player.lua` (`manaAsPrimary`); `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`, `UF:UpdateStatusBarElement`); `SaftUI-Unitframes/elements/additionalpower.lua`, `power.lua` (`GetDisplayPower`), `health.lua` (`PostUpdateHealth`), `classpower.lua`, `auras.lua`, `elements/elements.xml`; `SaftUI-Unitframes/groups.lua` (`UnpackColor`).

**What's been considered:**
- Keys nothing reads can simply be dropped from the defaults. Saved values of them are harmless.
- `customColor`: store it as a color (`CreateColor`), or read it with something like `groups.lua`'s `UnpackColor`, which takes either shape. Then `colorCustom` and a color picker could go into the Health and Power tabs.
- Castbar background: give it `alpha` and `multiplier` defaults and color it from the bar color, or drop `bg` from the castbar defaults.
- Additional power: default `colorPower = true`, or color the bar in `PostUpdateColor` when oUF passes no color.

**Shape of work:** A small cleanup of the defaults, plus two small fixes (`customColor`, the castbar background). `manaAsPrimary` needs a decision first.

**Open questions:** Finish `manaAsPrimary` or remove it? Should the focus castbar get its own color back?

### 2026-11-07 — Action bar leftovers: main bar concealed not blocked, LibActionButton on deprecated APIs, unskinned flyouts

**What:** Three items left after SaftUI-ActionBars Task 1 (SaftUI's own bars on LibActionButton-1.0):
1. Blizzard's `MainActionBar` is concealed (alpha 0, mouse off), not blocked with `SetRolesets('alwaysBlocked')`. It's on screen when SaftUI loads, and blocking a visible bar would run its secure buttons' OnHide tainted (`.agents/taint.md` rules 4 and 8). It keeps its place in Blizzard's bottom bar stack and keeps running.
2. LibActionButton minor 168 calls Blizzard's global action APIs (`HasAction`, `GetActionTexture`, `IsUsableAction` and others). In 12.0 those only exist through `Blizzard_DeprecatedActionBar`, which returns early unless the `loadDeprecationFallbacks` CVar is on, and Blizzard says they go at the next expansion.
3. LibActionButton's flyout buttons (`LABFlyoutButton1..`, shared by every addon that uses the library) keep Blizzard's look.

**Why noticed:** Building Task 1 of `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`. Item 1 came from checking `ActionBarActionButtonMixin:OnHide` in the forever source: it writes `needsUpdate` and Blizzard's range and usable check tables, which `UpdateAction` reads again before `SetAttribute('pressAndHoldAction')`, also when paging in combat. Item 2 came from reading `Blizzard_DeprecatedActionBar/Deprecated_ActionBar.lua` (the same on forever and live). Item 3 is out of the task's scope.

**Anchors:** `SaftUI-ActionBars/hideblizzard.lua` (`Conceal`, `HideBar`); `SaftUI-ActionBars/Libraries/README.md`; `SaftUI-ActionBars/skin.lua`; `ValidateActionBarTransition` in `Blizzard_ActionBarController/ActionBarController.lua` (where Blizzard hides `MainActionBar` for a skinned vehicle); LibActionButton's `OnFlyoutButtonCreated` callback.

**What's been considered:** For 1, a `hooksecurefunc('ValidateActionBarTransition', ...)` could block the main bar the first time Blizzard hides it out of combat (a skinned vehicle), after which it stays blocked. That's rare, so concealment stays the normal state, and nothing else is wrong with it. For 2, the fix is upstream: update the bundled copy once LibActionButton uses `C_ActionBar`. For 3, skinning the flyout buttons touches buttons other addons' bars share.

**Shape of work:** 1 is a small hook in `hideblizzard.lua` plus an in-game check in a skinned vehicle. 2 is a library update and a re-read. 3 is a small skin pass through `OnFlyoutButtonCreated`, if wanted.

**Open questions:** For 3, is styling LibActionButton's shared flyout buttons acceptable when another LibActionButton addon is loaded too?

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
1. Aura group options on unit frames: filter (`onlyShowPlayer`), `max`, button `size`, which borders show, and whether buttons get a cooldown. They're baked into the `AuraContainer` group when it's made. Their `/sui` options (the Buffs and Debuffs tabs) say "Reload to apply". This is the open question in the aura-container followup below.
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
- Found 2026-11-07 (review of the unit frame element options): groups can't be removed, but `CustomAuraContainerSharedMixin` (`Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`, on `live` and `forever`) has `SetAuraGroupMaxFrameCount(key, n)`, `SetAuraGroupFilterString(key, filter)` and `SetAuraGroupLayout(key, layout)`. `elements/auras.lua` now keeps the key oUF's `AddGroup` returns as `auras.groupKey` and re-applies the spacing with `SetAuraGroupLayout` (`af25f66`). `max` and `onlyShowPlayer` could go live the same way and lose their "Reload to apply". Size, borders and cooldown are button options, set when a button is made, so they still need a reload.

**Shape of work:** A research pass on the AuraContainer API (group options, policies, removing groups), then a small change in `elements/auras.lua` that maps config to options. It may also need a config-schema cleanup to drop options that can't be supported.

**Open questions:** Which of the old filter options are worth keeping at all? (Removing groups isn't supported; changing a group's filter, max and layout is.)

## Resolved

### 2026-11-07 — No way to cancel a possess

**What:** Blizzard's `PossessActionBar` has a cancel slot (`PossessButtonMixin:OnClick`: `TaxiRequestEarlyLanding` on a flight path, `VehicleExit` when controlling a vehicle, otherwise `CancelPetPossess`). `hideblizzard.lua` hides that bar, and SaftUI's leave vehicle button only showed while `CanExitVehicle()`, which a possess (a quest's mind control, say) isn't. Task 1's report listed the possess cancel as gone until Tasks 4/5; neither task's brief covered it. Bar 1 paged to the possessed creature, but the player couldn't end the possess.

**Why noticed:** Reading Blizzard's source for Task 5 of `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`: grepping forever and live for `TaxiRequestEarlyLanding` (`Blizzard_ActionBar/Shared/PossessActionBar.lua`). It was item 1 of the extras leftovers entry (Active) until the final review of SaftUI-ActionBars rated it Important, since the feature removed Blizzard's only on-screen way out of a possess.

**Anchors:** `SaftUI-ActionBars/extras.lua` (`LEAVE_DRIVER`, `LEAVE_SNIPPET`, `LeaveOnClick`, `CreateLeaveButton`), `SaftUI-ActionBars/hideblizzard.lua` (`PossessActionBar`); `PossessButtonMixin`, `POSSESS_CANCEL_SLOT`, `PossessButton2`; `SECURE_ACTIONS.click` in `Blizzard_FrameXML/SecureTemplates.lua`.

**What's been considered:** A second SaftUI button shown by `[possessbar]` that calls `CancelPetPossess` from its OnClick, or folding it into the leave vehicle button with Blizzard's three-way click. Blizzard's possess buttons are `SecureFrameTemplate` buttons, like its stance and pet buttons (whose OnClicks call protected functions) and unlike its two leave buttons, so `CancelPetPossess` is likely protected. ElvUI's bar 1 exit button calls `PetDismiss` instead, from insecure code (LibActionButton's custom type); not followed, since Blizzard's own cancel calls `CancelPetPossess`.

**Shape of work:** A few lines in `extras.lua` plus an in-game check with a possess.

**Resolved 2026-11-07:** Folded into SaftUI's leave vehicle button (`SaftUI-ActionBars/extras.lua`), now a `SecureActionButtonTemplate` button. Its driver adds `[possessbar] possess` after `[canexitvehicle]`, and its snippet shows it while possessing and sets the secure `click` type, which clicks Blizzard's own cancel button (`PossessButton2`) from secure code. So Blizzard's `PossessButtonMixin:OnClick` runs its three-way order, in combat too, and SaftUI never calls `CancelPetPossess` itself. Its tooltip says `CANCEL` then. Vehicles and flight paths keep Task 5's click, from `PostClick`. Still to check in game: that a click on the blocked possess bar's button goes through.

### 2026-11-07 — Unit frame indicators ignore their enable setting once oUF updates them

**What:** `UF:SetElementEnabled` only shows or hides an element (`SaftUI-Unitframes/updaters.lua`); oUF keeps every indicator element enabled. So after an oUF update the indicator shows by its own rules. The group role corner's `postUpdate` (`SaftUI-Unitframes/elements/indicators.lua`) calls `SetShown` from the role alone, whatever `grouproleindicator.enable` says. A disabled indicator is never anchored, because `UF:UpdateElement` returns before placing it. That probably keeps it from drawing, but it's shown, and one that was anchored by an earlier profile with it enabled would draw.

**Why noticed:** While building the party/raid test mode previews (Task 15, 2026-11-07), which had to decide whether to mirror the real role corner. The previews honor `enable`, which matches the default look: role corners on party, none on the raids or single frames.

**Anchors:** `SaftUI-Unitframes/elements/indicators.lua` (`postUpdate`, the `PostUpdate` wrapper); `SaftUI-Unitframes/updaters.lua` (`UF:SetElementEnabled`, the commented-out `EnableElement` path); `SaftUI-Unitframes/groups.lua` (`FillPreviewFrame`, role corner).

**What's been considered:** Hiding the indicator in the `PostUpdate` wrapper when its config disables it is a small fix. The indicators have no `/sui` options, so `enable` only comes from the defaults.

**Shape of work:** Small: a line in the indicator `PostUpdate` wrapper, plus an in-game check that the player and target frames don't lose a role corner the user relies on.

**Resolved 2026-11-07:** The indicator `PostUpdate` wrapper in `SaftUI-Unitframes/elements/indicators.lua` now hides a disabled indicator after every oUF update, the group role corner included. Each indicator also got a `/sui` tab (enable, size, position), so `enable` is no longer only a default.

### 2026-11-07 — Blizzard's raid frames still show next to SaftUI's raid frames

**What:** SaftUI now spawns raid10 and raid40 headers, but nothing hides Blizzard's own raid frames (`CompactRaidFrameManager` / `CompactRaidFrameContainer`). In a raid, both may show. Party is fine: oUF's `SpawnHeader` calls `DisableBlizzard('party')` for the party header (`SaftUI-Unitframes/Libraries/oUF/blizzard.lua`), and that only covers the party frames.

**Why noticed:** While re-enabling the party and raid headers (edit mode Task 15, 2026-11-07). The task's rules forbid writing onto Blizzard frames and `st:Kill`, so hiding the compact raid frames was left out.

**Anchors:** `SaftUI-Unitframes/groups.lua` (`UF:CreateGroupHeaders`); `SaftUI-Unitframes/Libraries/oUF/blizzard.lua` (`DisableBlizzard`, party branch); Blizzard's `Blizzard_CompactRaidFrames`.

**What's been considered:** Hiding or unregistering the compact raid frames from addon code is a known taint source, and on retail Edit Mode manages them. The user can turn them off through Blizzard's own settings instead. A SaftUI option could point there, or use whatever API Blizzard offers for it.

**Shape of work:** Small research pass on both clients (is there a taint-free API or CVar?), then either a one-line setting or a note in `/sui`.

**Open questions:** Does Blizzard's raid-frame setting cover Forever? Does the user want SaftUI to manage it at all?

**Resolved 2026-11-07:** `unitframes: hide blizzard's raid frames while saftui's are enabled`. While raid10 or raid40 is enabled, `UF:UpdateBlizzardRaidFrames` (`SaftUI-Unitframes/groups.lua`) gives `CompactRaidFrameContainer` the `alwaysBlocked` roleset, oUF's own way of hiding Blizzard frames (`SetRolesets` exists on both clients). The container holds every Blizzard raid frame. Its events stay registered, and turning both raid groups off gives it back its own rolesets, live while not in a raid. `CompactRaidFrameManager` (the raid tools tab) is left alone. Per `.agents/taint.md` rule 4 the roleset only changes while that doesn't change whether the container is on screen; otherwise it waits for a post-hook on `CompactRaidFrameManager_UpdateContainerVisibility`. So after a `/reload` in a raid, Blizzard's raid frames stay until you leave the raid. The `raidOptionIsShown` CVar was ruled out: setting it from addon code runs `CompactUnitFrameProfiles:ApplyCurrentSettings` (every compact frame option) in SaftUI's call chain, and it's the user's own saved setting. The raid groups' Enable option describes this.

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

**Resolved 2026-11-07:** Fixed in `8bee1ca`, `f2f876a`, `541efc4` and `197f794` on `modular`. Every hook on a Blizzard frame or function in SaftUI-Minimap is now a post-hook (native `HookScript`, `hooksecurefunc`, AceHook `SecureHook`). The expansion button keeps Blizzard's OnEnter/OnLeave and hides the tooltip in a post-hook. Blizzard's clock and difficulty frame are hidden with `Hide()` plus an OnShow post-hook instead of `st:Kill`/`st:Hide`. Bar item data (width, template, text, backdrop) lives in a weak table in `micromenu.lua`, every panel is a SaftUI frame, and `MicroMenu:SkinBarButton` replaces `st:SkinButton` on Blizzard buttons; the minimap's own panel moved off `Minimap` too. The queue eye is put back after live's `UpdatePosition` and Forever's `UpdateDefaultAnchor`/`SetEditModeScale`, and Forever's `SetHeaderUnderneath` and the expansion button's `UpdateIcon` get the same relayout. Open question, answered from Blizzard's source (the BugGrabber log wasn't checked): on Forever the eye is an Edit Mode system whose Lua `SetPoint`/`ClearAllPoints` the bar was calling, which wrote Edit Mode snap state and `EditModeManagerFrame.editModeSystemAnchorDirty` under SaftUI's taint (bar items now use `st:SetPointDirect`/`st:ClearAllPointsDirect`). The other field writes were latent: no Blizzard code reads those keys. Left as is: `minimapbuttons.lua` still `tremove`s its entries from `AddonCompartmentFrame.registeredAddons` (no Unregister API on either client, same as LibDBIcon), and the mail frame's OnEvent still calls the container's Lua `Layout` no-op as its last statement.

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

**Anchors:** `SaftUI-Loot/init.lua` (`LT:OnEnable`); `AlertFrame` (`Blizzard_FrameXML` AlertFrameSystems); BugGrabber log at `E:\Games\World of Warcraft\_forever_\WTF\Account\<account>\SavedVariables\!BugGrabber.lua`.

**What's been considered:** `AlertFrame:SetAlertsEnabled(false, reason)` is Blizzard's API for this, so the call is fine and only the method replacement is the problem. If something re-enables alerts, a `hooksecurefunc` on `SetAlertsEnabled` that re-disables would be the taint-safe version. Check the autoloot globals against Forever's LootFrame code before deciding.

**Shape of work:** Small: one or two lines in `init.lua` plus an in-game check that loot and boss toasts stay hidden.

**Open questions:** Does anything in combat read `AlertFrame.SetAlertsEnabled` or the autoloot globals? If not, this is cosmetic risk only.

**Resolved 2026-11-07:** Dropped the `AlertFrame.SetAlertsEnabled` replacement (alerts stay off through a SaftUI-only reason key) and the `LOOTFRAME_AUTOLOOT_*` writes (nothing in the live or forever source reads them).

## Abandoned

(items move here when explicitly decided against — note the reason in a one-line addendum so the decision is recoverable)
