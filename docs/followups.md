# Followups

A queue between "noticed it" and "decided what to do about it." Items might become Jira tickets, get fixed inline during related work, or be explicitly abandoned. Triage periodically.

Format: see the user-level `~/.claude/CLAUDE.md` "Followup detection" section.

## Contents

- [Active](#active)
  - [2026-11-10 — panels.tab_height has no option, because nothing live reads it](#2026-11-10--panelstab_height-has-no-option-because-nothing-live-reads-it)
  - [2026-11-10 — Colors tab: role and rune colors, and a switch for Blizzard's class colors](#2026-11-10--colors-tab-role-and-rune-colors-and-a-switch-for-blizzards-class-colors)
  - [2026-11-09 — Unit frame color flags are set after oUF enables the bars, so their recolor events are never registered](#2026-11-09--unit-frame-color-flags-are-set-after-ouf-enables-the-bars-so-their-recolor-events-are-never-registered)
  - [2026-11-09 — st:Kill and st:SkinIcon still write onto Blizzard pieces (roll bars and elsewhere)](#2026-11-09--stkill-and-stskinicon-still-write-onto-blizzard-pieces-roll-bars-and-elsewhere)
  - [2026-11-09 — st:SetBackdropIn duplicates st:SetBackdrop](#2026-11-09--stsetbackdropin-duplicates-stsetbackdrop)
  - [2026-11-09 — Loot feed: a merge while scrolled shifts the scroll offset](#2026-11-09--loot-feed-a-merge-while-scrolled-shifts-the-scroll-offset)
  - [2026-11-09 — st:CreateHeader writes title and close_button onto the Blizzard panels it skins](#2026-11-09--stcreateheader-writes-title-and-close_button-onto-the-blizzard-panels-it-skins)
  - [2026-11-09 — st:CreateButton's SetText and SetFont aliases break when called as methods](#2026-11-09--stcreatebuttons-settext-and-setfont-aliases-break-when-called-as-methods)
  - [2026-11-09 — Unit frame Portrait, and AuraWatch as Grid2-style corner indicators](#2026-11-09--unit-frame-portrait-and-aurawatch-as-grid2-style-corner-indicators)
  - [2026-11-09 — Aura timer bars: stacked bars instead of icons](#2026-11-09--aura-timer-bars-stacked-bars-instead-of-icons)
  - [2026-11-09 — Edit mode movers for unit frame parts placed on the screen](#2026-11-09--edit-mode-movers-for-unit-frame-parts-placed-on-the-screen)
  - [2026-11-09 — Settings with no /sui option, settings nothing reads, and frames with no edit mode mover](#2026-11-09--settings-with-no-sui-option-settings-nothing-reads-and-frames-with-no-edit-mode-mover)
  - [2026-11-08 — Forever: wrong or missing aura tooltips on party frames](#2026-11-08--forever-wrong-or-missing-aura-tooltips-on-party-frames)
  - [2026-11-08 — Edit Mode frames anchored straight to SaftUI holders: tooltip container, buffs, swing timers](#2026-11-08--edit-mode-frames-anchored-straight-to-saftui-holders-tooltip-container-buffs-swing-timers)
  - [2026-11-08 — Loot rolls: confirm the client assumptions in game](#2026-11-08--loot-rolls-confirm-the-client-assumptions-in-game)
  - [2026-11-08 — Saved loot feed size in SaftUI_DB](#2026-11-08--saved-loot-feed-size-in-saftui_db)
  - [2026-11-08 — Confirm the totem bar's protection and secret-value claims in game, then document the duration-object pattern](#2026-11-08--confirm-the-totem-bars-protection-and-secret-value-claims-in-game-then-document-the-duration-object-pattern)
  - [2026-11-08 — TemplateInset is duplicated between SaftUI-ActionBars and SaftUI-Misc](#2026-11-08--templateinset-is-duplicated-between-saftui-actionbars-and-saftui-misc)
  - [2026-11-08 — Specialty bags (herb, mining, etc.) count as normal bags in the bag window](#2026-11-08--specialty-bags-herb-mining-etc-count-as-normal-bags-in-the-bag-window)
  - [2026-11-07 — Minimap pieces still belong to MinimapCluster, which stretches across the screen](#2026-11-07--minimap-pieces-still-belong-to-minimapcluster-which-stretches-across-the-screen)
  - [2026-11-07 — Extra buttons leftovers: zone ability hidden by Blizzard's bar settings, Blizzard's art, skinned vehicles' pitch and status bars](#2026-11-07--extra-buttons-leftovers-zone-ability-hidden-by-blizzards-bar-settings-blizzards-art-skinned-vehicles-pitch-and-status-bars)
  - [2026-11-07 — Pet and stance bar leftovers: spellbook highlight, pings, pickup click, autocast names after an in-combat pet swap](#2026-11-07--pet-and-stance-bar-leftovers-spellbook-highlight-pings-pickup-click-autocast-names-after-an-in-combat-pet-swap)
  - [2026-11-07 — Fonts outline dropdowns show None as a blank entry](#2026-11-07--fonts-outline-dropdowns-show-none-as-a-blank-entry)
  - [2026-11-07 — Unit frame defaults that nothing reads, or that break when turned on](#2026-11-07--unit-frame-defaults-that-nothing-reads-or-that-break-when-turned-on)
  - [2026-11-07 — Action bar leftovers: main bar concealed not blocked, LibActionButton on deprecated APIs, unskinned flyouts](#2026-11-07--action-bar-leftovers-main-bar-concealed-not-blocked-libactionbutton-on-deprecated-apis-unskinned-flyouts)
  - [2026-11-07 — Chat mover leftovers: overlay reach-in, anchor in Blizzard layout, clamp dead zone](#2026-11-07--chat-mover-leftovers-overlay-reach-in-anchor-in-blizzard-layout-clamp-dead-zone)
  - [2026-11-07 — Profile switch: Show/Hide on protected frames in combat, mover/unit-frame anchor swaps](#2026-11-07--profile-switch-showhide-on-protected-frames-in-combat-moverunit-frame-anchor-swaps)
  - [2026-11-07 — Profile settings that still need a /reload after a profile switch](#2026-11-07--profile-settings-that-still-need-a-reload-after-a-profile-switch)
  - [2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite](#2026-11-05--aura-filters-and-per-aura-styling-lost-in-the-ouf-aura-container-rewrite)
- [Resolved](#resolved)
  - [2026-11-10 — Boss frames have no test mode, so their Layout options can't be checked out of an encounter](#2026-11-10--boss-frames-have-no-test-mode-so-their-layout-options-cant-be-checked-out-of-an-encounter)
  - [2026-11-09 — Test runner self-check: tell a runner crash from a caught failure](#2026-11-09--test-runner-self-check-tell-a-runner-crash-from-a-caught-failure)
  - [2026-11-08 — The roll bar skin writes fields onto Blizzard's GroupLootFrames](#2026-11-08--the-roll-bar-skin-writes-fields-onto-blizzards-grouplootframes)
  - [2026-11-09 — The /link copy dialog replaces scripts on Blizzard's popup edit box](#2026-11-09--the-link-copy-dialog-replaces-scripts-on-blizzards-popup-edit-box)
  - [2026-11-07 — Tooltip skin writes .backdrop onto Blizzard's tooltips](#2026-11-07--tooltip-skin-writes-backdrop-onto-blizzards-tooltips)
  - [2026-11-08 — Older loot feed quirks: timer refresh by unfiltered index, a full feed trims on merges](#2026-11-08--older-loot-feed-quirks-timer-refresh-by-unfiltered-index-a-full-feed-trims-on-merges)
  - [2026-11-07 — No way to cancel a possess](#2026-11-07--no-way-to-cancel-a-possess)
  - [2026-11-07 — Unit frame indicators ignore their enable setting once oUF updates them](#2026-11-07--unit-frame-indicators-ignore-their-enable-setting-once-ouf-updates-them)
  - [2026-11-07 — Blizzard's raid frames still show next to SaftUI's raid frames](#2026-11-07--blizzards-raid-frames-still-show-next-to-saftuis-raid-frames)
  - [2026-11-07 — Party and raid unit frames: re-enable headers and add edit mode movers](#2026-11-07--party-and-raid-unit-frames-re-enable-headers-and-add-edit-mode-movers)
  - [2026-11-07 — SaftUI-Minimap's bar replaces Blizzard frame scripts and writes onto them (taint risk)](#2026-11-07--saftui-minimaps-bar-replaces-blizzard-frame-scripts-and-writes-onto-them-taint-risk)
  - [2026-11-07 — Bank leftovers: broken non-combined bank path, Forever gold tooltip, leaked globals](#2026-11-07--bank-leftovers-broken-non-combined-bank-path-forever-gold-tooltip-leaked-globals)
  - [2026-11-07 — SaftUI-Loot writes onto Blizzard frames and globals (taint risk)](#2026-11-07--saftui-loot-writes-onto-blizzard-frames-and-globals-taint-risk)
- [Abandoned](#abandoned)

## Active

### 2026-11-10 — panels.tab_height has no option, because nothing live reads it

**What:** `panels.tab_height` (21, in `st.defaults.panels`, `SaftUI-Core/Config/defaults.lua`) is the one leftover Core setting that got no `/sui` option when Global Settings gained its General tab and the Fonts tab's new rows. Nothing that runs reads it. Either wire it to something that draws tabs and give it an option, or remove the key.

**Why noticed:** Options project 3 (Core's leftover settings, `coresettings` branch, approved by the user 2026-11-10). The approved design gave every other Core setting an option (icon trim, title bar height, clamp inset, font shadow and spacing, and the header, button and panel fonts) and said `panels.tab_height` gets none, to be treated like chat's `linespacing`: a setting nothing applies gets no option, only a followup to wire it up or drop it. Chat's `linespacing` is in the Chat line of [Settings with no /sui option](#2026-11-09--settings-with-no-sui-option-settings-nothing-reads-and-frames-with-no-edit-mode-mover).

**Anchors:**
- Its only readers are in `SaftUI-Misc/Skinning/skinning.lua`: `SK:UpdateTab` (`tab:SetHeight(...)`, reached from `SK:SkinTab`) and `SK:SkinTabHeader` (`header:SetHeight(...)`). `SK:SkinTab` is called only by `SK:SkinBlizzardPanel` and `SK:SkinTabHeader`, and nothing calls either of those (grep `SkinBlizzardPanel`, `SkinTabHeader`).
- The same dead path also reads `panels.font` (`SK:UpdateTab`'s `SetDisabledFontObject`) and `panels.template` (`SK:SkinBlizzardPanel`, and `SK:SkinTab` through `st:SkinActionButton(tab, st.config.profile.panels)`). `panels.font` stays alive through check box labels (`SaftUI-Core/Widgets/checkbutton.lua`), which is the reader its Fonts → Kinds of text → Check box labels option names.
- The dead helpers also write fields onto Blizzard's tabs (`tab.skinned`, `tab.Text`, and `st:SkinActionButton`'s fields), which `.agents/taint.md` rule 1 forbids, so reviving them as they are isn't an option.

**What's been considered:**
- Removing the key: saved values are harmless (the 2026-11-09 audit settled that dead keys can be dropped from the defaults). `SK:SkinBlizzardPanel`, `SkinTab`, `UpdateTab` and `SkinTabHeader` could go with it, or be left for a future Blizzard panel skin.
- Wiring it up: only worth it once SaftUI skins a Blizzard window with tabs again, through side tables. Its option would then sit in General → Windows, with Title bar height.

**Shape of work:** Small. Removal: one default, and the dead helpers if they go too, plus the line in the options-coverage entry's Core list. Wiring it up belongs with whichever skin first needs tabs.

**Open questions:** Remove now, or keep it for a Blizzard panel skin the Themes project might bring?

### 2026-11-10 — Colors tab: role and rune colors, and a switch for Blizzard's class colors

**What:** Two additions to the Colors tab of Global Settings (spec `docs/superpowers/specs/2026-11-10-saftui-colors-tab-design.md`), left out of its first version: editable role colors (tank, healer, damage) and death knight rune colors (blood, frost, unholy), and a switch to use Blizzard's class colors instead of SaftUI's own muted palette.

**Why noticed:** Drafting the Colors tab design (2026-11-10). The draft listed both as non-goals; the user answered "we should follow up with this".

**Anchors:** `UF:UpdateColors` (`SaftUI-Unitframes/unitframes.lua`): `UF.oUF.colors.roles = st.config.profile.colors.roles or DEFAULT_ROLE_COLORS`, and the same for `runes`. The profile (`st.defaults.colors`, `SaftUI-Core/Config/defaults.lua`) has neither table, so oUF's colors are used. SaftUI has no Runes element yet, so rune colors need one first (`colors.power.RUNES` stays in the defaults, but nothing draws it and the tab has no row for it). `colors.class` in the same defaults is SaftUI's palette; Blizzard's is `RAID_CLASS_COLORS` (or `C_ClassColor.GetClassColor`).

**What's been considered:** Roles and runes would be two more sections of the Colors tab, which needs their defaults added to the profile (oUF's values) so there's something to edit; `UF:UpdateColors` then drops the fallback. The class switch is a toggle at the top of the Class section that greys the swatches out while on. Everything that reads `colors.class` (unit frames through `UF.oUF.colors.class`, the group previews, the unit tooltip) would then need to read through one helper, so the switch reaches them all.

**Shape of work:** Small to medium, after the Colors tab ships: two sections with defaults, plus a toggle and a single class color lookup.

**Open questions:** Whether the Blizzard switch also covers reaction colors (Blizzard's `FACTION_BAR_COLORS`).

### 2026-11-09 — Unit frame color flags are set after oUF enables the bars, so their recolor events are never registered

**What:** oUF's Health and Power register `UNIT_FACTION` (for `colorTapping` and `colorReaction`), `UNIT_FLAGS` (`colorSelection`) and `UNIT_THREAT_LIST_UPDATE` (`colorThreat`) in their `Enable`, and only if the flag is already on then; turning a flag on later is meant to go through the element's `SetColorTapping` / `SetColorReaction` / ..., which register the event. SaftUI assigns the flags straight onto the element in each element's `UpdateConfig` (`elements/health.lua`, `elements/power.lua`). For single units (player, target, focus, ...) that first runs in `UF:ApplyConfig`, after `oUF:Spawn` has enabled the elements, so the flags were nil at `Enable` and those events are never registered, even for the defaults (Health's `colorTapping` and `colorReaction` are on). Group buttons are fine: `UF.ConstructUnit` updates them inside the style function, before `Enable`.

**Why noticed:** Task 9 of the options layout project (2026-11-09) exposed the color flags in `/sui` and checked that oUF re-reads them. It does, on every health or power update (`Path` runs `ColorPath`), and SaftUI's option set ends in `UpdateAllElements`, so each option works at once. What's missed is a recolor between updates: a target someone else tags without damaging it (no `UNIT_HEALTH`) stays its old color until its next health or power change, or until it's targeted again.

**Anchors:** `SaftUI-Unitframes/elements/health.lua` and `power.lua` (`UpdateConfig`); `SaftUI-Unitframes/Libraries/oUF/elements/health.lua` and `power.lua` (`Enable`, `SetColorTapping`, `SetColorReaction`); `SaftUI-Unitframes/Libraries/oUF/ouf.lua` (`initObject`: the style function, then `EnableElement`); `UF.ConstructUnit`, `UF:ApplyConfig` (`unitframes.lua`).

**What's been considered:** Call `element:SetColorTapping(config.colorTapping, true)` and `SetColorReaction` in `UpdateConfig` instead of assigning those two (the forced call registers or unregisters the event to match). Plain table writes stay fine in combat; registering an event on a unit frame is too. **A guard is needed (Task 9's review, 2026-11-09):** `SetColorTapping` and `SetColorReaction` only exist after oUF's `Enable`, and group buttons run `UpdateConfig` inside the style function, before `Enable`, so calling them unguarded errors on party and raid frames. Check for a nil `element.SetColorTapping`: when it's nil, assign the flag directly (as now), and `Enable` registers the event itself.

**Shape of work:** A few lines in health.lua and power.lua, and an in-game check: tag a target with a debuff from another player and watch it go grey.

### 2026-11-09 — st:Kill and st:SkinIcon still write onto Blizzard pieces (roll bars and elsewhere)

**What:** Two Core helpers write fields onto the frames they're given:
- `st:Kill` writes `Show`, `_Show` and `SetAtlas`;
- `st:SkinIcon` writes `__stTexCoord`, plus a hook.

The roll bar skin (`SaftUI-Loot/roll.lua`) calls them on Blizzard pieces: `IconFrame.Border`, `Timer.Background`, `NameFrame`, `Corner`, `IconFrame.Count`, `IconFrame.Icon`. That breaks `.agents/taint.md` rule 1. Other skins likely do the same. Separately, `SaftUI-Loot/popup.lua` writes `LootFrame.skinned`, but that file isn't loaded; it goes away with the loot window reskin.

**Why noticed:** The roll bar side-table fix (2026-11-09) left these alone, because the followup it fixed didn't list them. Both its implementer and its reviewer flagged them.

**Anchors:** `SaftUI-Core` (`st:Kill`, `st:SkinIcon`), `SaftUI-Loot/roll.lua`; grep `st:Kill(` and `st:SkinIcon(` across the repo for Blizzard targets.

**What's been considered:**
- For art: hide with `SetAlpha(0)` or `Hide()` plus a post-hook, instead of replacing `Show` (taint rule 4 and the totem skin's pattern).
- For icons: keep the tex-coord state in a weak table, keyed by the texture.

**Shape of work:** An audit of the callers, then a side-table version of each helper for Blizzard targets.

### 2026-11-09 — st:SetBackdropIn duplicates st:SetBackdrop

**What:** `st:SetBackdropIn` (`SaftUI-Core/api.lua`, added by the tooltip side-table fix) copies the body of `st:SetBackdrop` (`SaftUI-Core/panels.lua`), but returns the backdrop frame without storing it on its target. If `SetBackdrop`'s offset or frame-level rules change, the two will drift.

**Why noticed:** The review of the tooltip fix (2026-11-09). That fix wasn't allowed to touch `panels.lua` while the options window work was changing it.

**Anchors:** `SaftUI-Core/api.lua` (`SetBackdropIn`), `SaftUI-Core/panels.lua` (`SetBackdrop`).

**Shape of work:** Small, once the options window branch has landed: make `SetBackdrop` call `SetBackdropIn` and then store the result, or share one inner function.

### 2026-11-09 — Loot feed: a merge while scrolled shifts the scroll offset

**What:** `LootFeedPush` (`SaftUI-Loot/Feed/feed.lua`) still does `offset = offset + 1` when the feed is scrolled, even when the push merges into an existing entry (gold, or the same item) instead of adding one. A merge adds no entry, so the view probably shifts by one line for no reason.

**Why noticed:** The review of the "Older loot feed quirks" fix (2026-11-09) noticed it. It was outside that fix's scope.

**Anchors:** `SaftUI-Loot/Feed/feed.lua` (`LootFeedPush`, the merge branches, `offset`); `tests/loot/feed_test.lua`.

**Shape of work:** Small: bump the offset only on an insert, with a test.

### 2026-11-09 — st:CreateHeader writes title and close_button onto the Blizzard panels it skins

**What:** `st:CreateHeader(frame, title, close_button)` (`SaftUI-Core/panels.lua`) writes `frame.title`, `frame.close_button` and `frame.header` onto the frame it's given. That frame can be a Blizzard panel: `SK:SkinBlizzardPanel` (`SaftUI-Misc/Skinning/skinning.lua`) calls it for Blizzard frames, and so does the unloaded loot window code (`SaftUI-Loot/popup.lua`). Writing them breaks `.agents/taint.md` rule 1.

**Why noticed:** The options window rework (2026-11-09) fixed the same class of write in `st:CreateCloseButton`, which now uses a weak side table and `st:GetCloseButton(frame)`. Its re-reviewer pointed out that `CreateHeader` still does it. That's old code, outside that task.

**Anchors:** `SaftUI-Core/panels.lua` (`CreateHeader`, `closeOf`, `headerTitles`), `SaftUI-Misc/Skinning/skinning.lua` (`SkinBlizzardPanel`), `SaftUI-Loot/popup.lua`.

**What's been considered:** Use the same pattern: weak side tables keyed by frame, with accessors such as `st:GetHeader(frame)`. Then find every reader of `.header`, `.title` and `.close_button` and switch it over.

**Shape of work:** A small refactor in `panels.lua`, plus its readers.

### 2026-11-09 — st:CreateButton's SetText and SetFont aliases break when called as methods

**What:** `st:CreateButton` aliases `SetText` and `SetFont` onto its button, and both break when called the normal way, as methods (`button:SetText(x)`, `button:SetFont('pixel')`).

**Why noticed:** The final review of the edit mode grid/snap branch found the footer's Grid size label calling `sizeLabel:SetText(...)`, which would error in game. That call was fixed in the branch to use `sizeLabel.text:SetText(...)`; `button.lua` was left alone because it has other callers.

**Anchors:**
- `SaftUI-Core/Widgets/button.lua:8-9`. `button.SetText = button.text.SetText` passes the button, not the FontString, as `self` when called as `button:SetText(x)`, which errors. `button.SetFont = function(font) ... end` receives the button as `font` when called as `button:SetFont('pixel')`.
- `SaftUI-Bags/container.lua:53` and `SaftUI-Bags/currencies.lua:179` call `button:SetFont('pixel')`, so the bag filter buttons' font is probably never set as intended.
- `SaftUI-Core/Widgets/checkbutton.lua:30`, the pattern to copy: `function(self, v) self.text:SetText(v) end`.

**What's been considered:** Make both aliases take `self` first, like `checkbutton.lua:30`. Changing them changes what existing callers do (for example the bag buttons would start getting their font), so check every `st:CreateButton` caller before changing it.

**Shape of work:** Small fix in `button.lua`, plus a pass over every `st:CreateButton` caller for `SetText` / `SetFont` use, then a check in game that the bag filter buttons look right.

### 2026-11-09 — Unit frame Portrait, and AuraWatch as Grid2-style corner indicators

**What:** Two unit frame elements the user wants built. Both have defaults in `SaftUI-Unitframes/config/default.lua` but were never registered:
- **Portrait** (`elements/portrait.lua`).
- **AuraWatch** (`elements/aurawatch.lua`, a commented-out stub). The user wants Grid2's corner indicators (https://github.com/michaelnpsp/Grid2): small colored squares in the corners of party and raid frames. Each square means the unit has one of the player's tracked auras, for example Riptide or Rejuvenation. The user's screenshot showed green, yellow and olive squares in the top-left and bottom-left corners of Grid2 cells, and a debuff icon in the center of one cell. The user: "it could be really useful for tracking heals on raid frames (defining heals for each corner, like riptide, rejuv, etc.) - if restrictions don't allow you to filter down to that level then maybe we just drop it."

**Why noticed:** The 2026-11-09 settings audit found both elements' defaults unused. The user chose to build them rather than remove them.

**Anchors:**
- oUF's Auras meta element, `AddSlot(filter, { candidateFilters = { includeSpellIDs = { [id] = true } } })` (`SaftUI-Unitframes/Libraries/oUF/elements/auras.lua`). Each slot is one aura button that Blizzard's `AuraContainer` fills natively, so it works when aura data is secret in combat.
- SaftUI's "Only mine" candidate filter (`elements/auras.lua`). On Forever the `PLAYER` filter string keeps others' auras too; see `.agents/clients.md`.
- `taint.md` rule 11: aura buttons' state is secret, and hooks on dispel textures don't fire.
- oUF's Portrait element (`Libraries/oUF/elements/portrait.lua`).

**What's been considered:**
- AuraWatch: one slot per tracked spell, all of a corner's slots stacked on that corner. Each button gets a custom `initializeFrame` that draws a flat colored square (the spell's color) instead of the icon, maybe with a cooldown swipe. Blizzard decides when each shows. No external AuraWatch library is needed. The old oUF_AuraWatch plugin was never bundled.
- Settings: per corner (top-left, top-right, bottom-left, bottom-right), a list of spell IDs with a color each. Probably per class, since the spells are class spells.

**Shape of work:** A brainstorm and spec covering both elements. Portrait needs a look decision: 3D model or 2D, and placement inside or beside the frame. AuraWatch needs a research spike in game first, to confirm that `includeSpellIDs` slots plus the only-mine filter show only the player's HoTs on Forever.

**Open questions:**
- Portrait look and placement.
- AuraWatch spell lists: per class or per character? Size and offset per corner? Show a duration (swipe or a draining square)?

### 2026-11-09 — Aura timer bars: stacked bars instead of icons

**What:** An option to show a unit frame's buffs and debuffs as stacked timer bars (name, time left, a draining bar) instead of icons. Some aura defaults that nothing reads today look meant for this, and were kept for it:
- `font`;
- `showBar` (player buffs);
- `horizontal_growth`;
- target buffs' `border`.

**Why noticed:** The 2026-11-09 settings audit proposed removing those keys. The user: "I think could be useful to leave it and implement stacked timer bars instead of just the aura icons, lets leave for now and track that implementation as a followup".

**Anchors:**
- `SaftUI-Unitframes/elements/auras.lua`, built on oUF's Auras meta element over Blizzard's `AuraContainer`.
- The `buffs` and `debuffs` defaults in `SaftUI-Unitframes/config/default.lua` and `config/units/*.lua`.

**What's been considered:** Aura data is secret in combat, so bars can't be built from Lua-side aura data. The container's buttons draw natively. A bar look probably has to come from the container's own button options or a custom `initializeFrame` with a duration-driven bar, like the totem timers (`SetTimerDuration` in `SaftUI-Misc/totemtimers.lua`). That needs research.

**Shape of work:** First, a research pass on what a container button can show: a duration bar and a name. Then a design pass and an implementation in `elements/auras.lua`.

**Open questions:** Which units get bars (player only, or player and target)? Do bars replace icons per group, or show next to them?

### 2026-11-09 — Edit mode movers for unit frame parts placed on the screen

**What:** Some unit frame elements are positioned against the screen (`position.frame = 'UIParent'`) rather than on their unit frame. They have no edit mode mover, so they move only by typing x/y offsets in `/sui`:
- the player's power bar, castbar, class power and additional power (`SaftUI-Unitframes/config/units/player.lua`);
- the target's castbar (`config/units/target.lua`);
- the focus castbar (`config/units/focus.lua`).

**Why noticed:** The 2026-11-09 settings and edit mode audit. The user said: "lets plan the unit frame parts positioning for later - that's a pretty big endeavor on its own".

**Anchors:**
- `UF:RegisterMovers` and `UF:GetMoverFrame` in `SaftUI-Unitframes/unitframes.lua`.
- `UF:UpdateElementPosition` in `SaftUI-Unitframes/updaters.lua`.
- The element position editor `generators.uf_element_position` in `SaftUI-Core/Config/widgets.lua`.
- `st:RegisterMover` in `SaftUI-Core/EditMode/`.

**What's been considered:** One idea: register a mover for any element whose position's `frame` is `UIParent`, re-registered when that changes. Most of these elements are children of secure unit frames, so moves go through `st:SafeReposition`.

**Shape of work:** Needs a design pass. Open points:
- the mover's frame (the element itself, or a holder);
- what happens when an element switches between frame-relative and screen-relative;
- group units (party, raid), whose elements repeat per member.

**Open questions:**
- Should every element be able to detach to the screen, or only the ones that do today?
- Should dragging a frame-relative element in edit mode detach it?

### 2026-11-09 — Settings with no /sui option, settings nothing reads, and frames with no edit mode mover

**What:** An audit of every `st.defaults` table against `/sui` and edit mode. It found three kinds of gap. Some settings are read by the code but have no option. Some settings are read by nothing. Some frames SaftUI places have no edit mode mover. It also found a few broken options. Unit frame findings already listed in [Unit frame defaults that nothing reads, or that break when turned on](#2026-11-07--unit-frame-defaults-that-nothing-reads-or-that-break-when-turned-on) aren't repeated here.

**Progress 2026-11-09 (options layout project 2, `optlayout` branch):** the per-module gaps in the lists below are closed: Misc (Tooltip, Skinning, Totem bar), Bags, Action bars (`actionbars.template`), and the unit frames (range alpha, the boss layout, `alpha`, `health.texture`, the color toggles and the rest, as itemized under Unit frames). Each also got tooltips on every option and its Position options. **Still open:** Core's settings (the "Core" list: icon trim, font shadow and spacing, header, button and panel fonts and templates, editable templates, `colors.*`), which are project 3 of the options redesign; and `loot.popup.*`, which waits on the loot window's own design. Chat's `linespacing` and the broken-option, mover and unit frame "still without an option" items below are as they were.

**Progress 2026-11-10 (options project 3):** the Colors tab (`colors.*`) and Core's leftover settings (`coresettings` branch: Global Settings' General tab, and the Fonts tab's shadow, spacing and Kinds of text rows) close the Core list, but for the templates (`templates.*`, `buttons.template`, `panels.template`), which wait on the Themes project, and `panels.tab_height`, which has [its own entry](#2026-11-10--panelstab_height-has-no-option-because-nothing-live-reads-it). **Still open:** those, `loot.popup.*`, Chat's `linespacing`, and the broken-option, mover and unit frame items below.

**Read by the code, no option in `/sui`:**
- **Core** (`SaftUI-Core/Config/defaults.lua`). Core's settings are under Global Settings in `/sui`.
  - `misc.icon_trim`, `misc.clamp_inset`. *Done 2026-11-10 (options project 3, `coresettings` branch): General → Icons → Icon zoom, and General → Windows → Screen edge margin.*
  - `fonts.<key>.shadow_offset` and `.spacing`. *Done 2026-11-10: each font's Shadow offset X, Shadow offset Y and Line spacing on the Fonts tab.*
  - `headers.font` and `.height`; `buttons.font` and `.template`; `panels.font`, `.template` and `.tab_height`. *Done 2026-11-10: `headers.height` is General → Windows → Title bar height, and `headers.font`, `buttons.font` and `panels.font` are Fonts → Kinds of text (Window titles, Button text, Check box labels). `buttons.template` and `panels.template` wait on the Themes project. `panels.tab_height` gets no option, since nothing live reads it: see [its own entry](#2026-11-10--panelstab_height-has-no-option-because-nothing-live-reads-it).*
  - `templates.*` can be picked from a dropdown but not edited. *Waits on the Themes project.*
  - `colors.text`, `.button`, `.item_quality`, `.power`, `.class`, `.reaction`, `.status` and `.renown`. Only `colors.experience` has pickers (Experience → General, since 2026-11-09). *Done 2026-11-10: the Colors tab of Global Settings.*
- **Misc** (`SaftUI-Misc/config.lua`): `tooltip.template` and `.font`, `skinning.font` and `.template` (the new Skinning page, `SK:GetConfigTable`) and `totembar.colors.*` now have options (Task 4 of the options layout project, 2026-11-09).
- **Action bars:** `actionbars.template`.
- **Bags:** `inventory.enable`, `template`, `padding`, `categoryTitleHeight`, `scrollSpeed`, `autorepair`, `autovendor`, `combinedBank`, `inverted`, `fonts.titles` and `fonts.icons` now have options (Task 5 of the options layout project, 2026-11-09): Bags → General and Look.
- **Chat:** `chat.linespacing` is left without an option, because nothing applies it. Only `CHT:ChatFrame_OnUpdate` (`SaftUI-Chat/chatframe.lua`) reads it, and its `SecureHook` is commented out, so the setting is read by nothing. Either hook it back up (the function sets each line's spacing once, so a change would also need the lines un-marked `handled`, and it writes a field onto Blizzard's chat lines, which `.agents/taint.md` forbids, so it needs a side table) and give it an option, or remove the key.
- **Loot:** `loot.popup.*` (template, font, name_wrap, width, button_height, spacing) is in fact read by nothing. `SaftUI-Loot/popup.lua` isn't in the TOC, and `LT:InitializeLootFrame()` has been commented out of `init.lua` since the Loot addon was added. The skin is also written for the classic loot window (`LootButton1`-`4`, `LootFrameInset`), which current clients don't have, and it writes onto `LootFrame`. Skinning the loot window means a new skin for today's `LootFrame`, with these settings.
- **Unit frames:** these now have options (Tasks 8 and 9 of the options layout project, 2026-11-09), each only on the units where it does something:
  - `range_alpha.inside` and `.outside`: on party and the raids, the only frames with oUF's Range element.
  - `boss.spacing`, with the rest of boss's layout: boss has a Layout group.
  - `alpha` on every element: each element tab, in Castbar's Bar and the auras' Buttons.
  - `health.texture` on every unit, and `health.text.boss_percent` where a skull-level unit can show (boss, target, focus and their targets, the pet's target; not player, pet, party or raid).
  - Health's color toggles (`colorTapping`, `colorDisconnected`, `colorHealth`, `colorClass`, `colorClassNPC`, `colorClassPet`, `colorReaction`, `colorSmooth`) and Power's (`colorTapping`, `colorDisconnected`, `colorPower`, `colorClass`, `colorClassNPC`, `colorClassPet`, `colorReaction`), in each tab's Colors section. A flag is left off the units whose frames never show what it checks for (`UF.CanShow` in `config/config.lua`): e.g. Tapped isn't on player, pet, party or raid, Class isn't on pet or boss.
  - `colorCustom` and `customColor` on Health, Power and Additional power.
  - `power.text.hide_full` already had one.
  - `name.show_classification` (not on player, pet, party or raid) and `name.colorClass` (not on pet or boss).
  - The indicators' `template`.
  - **Still without an option, and not on this list:**
    - Power's `colorSmooth` (oUF's `colorPowerSmooth`, a gradient by power percent). It's applied (`elements/power.lua`) and needs `colorPower` on too; oUF's power colors keep their curves through `UF:UpdateColors`' merge. Check it in game, then add it to Power's Colors after Power type.
    - The castbar's `bg` (`enable`, `alpha`, `multiplier`), which works since 2026-11-09 (`bar_colors_test.lua`). The Castbar tab could take a Background section like Health's and Power's.

**Read by nothing:** settled with the user on 2026-11-09.
- **Done in 0308977:**
  - Removed:
    - `addon_manager`, `buttons.height`, `panels.padding`, every template's `inner_shadow`, and `maps` (`experience.width` is now a plain 250);
    - `minimap.font` and `.enable`;
    - bags' `compact`;
    - chat's `fadetabs` and `tabs.height`;
    - unit frames' `config_unit`, `config_element`, `health.text.tags`, `health.absorbColor` and additional power's `colorClass`;
    - the nameplate table (the user: "almost everyone just uses plater").
  - Hooked up:
    - bags' `buttontemplate`, now the item and currency slots' template;
    - `Smooth` on health, power and additional power, mapped to oUF's `smoothing`, on by default;
    - `power.colorSmooth`, mapped to oUF's `colorPowerSmooth`;
    - power and additional power `text.percent` and `text.hide_full`;
    - `name.color_hostile`, now a Name option, off by default.
  - Pettarget is now spawned, off by default.
- **Kept, for work to come:**
  - `grid.*` and `editmode.grid`/`.snap` were replaced by edit mode's grid and snap (2026-11-09): `editmode.grid`, `grid_size`, `snap_grid`, `snap_frames`.
  - Boss `growthDirection` and `spacing` stay as options. Decided 2026-11-10: the other boss layout keys, `maxColumns`, `unitsPerColumn`, `columnSpacing` and `initialAnchor`, were removed (options and defaults; boss is always one line, and a saved value is ignored). The user, after checking them in boss Test mode: "on the layout the only options that do anything are growth and spacing, we can scrap the other layout config options." (An earlier note had the user wanting all five implemented as options.)
  - The aura keys `font`, `horizontal_growth`, `showBar` and target buffs' `border` are for aura timer bars; see [Aura timer bars](#2026-11-09--aura-timer-bars-stacked-bars-instead-of-icons).
  - The aura filters, `showDebuffType` and `desaturateOthers` stay with the aura-container followup.
  - `portrait` and `aurawatch` are elements the user wants built. AuraWatch: per-corner HoT tracking on raid frames, which may be possible with AuraContainer slots (`AddSlot` with `candidateFilters.includeSpellIDs`); no separate library is needed.
  - `arena`: the user will deal with arena frames one day.
  - The size and frame level keys every element inherits are harmless, and stay.
- **Widget** was a retail-only status bar stub with no update code, for Blizzard's NPC widget bars. It was dropped with the user's OK, along with its defaults.

**Broken options and defaults:**
- **Fixed 2026-11-09 (5962f4d):**
  - the unit frame profile Rename and Import, which also fixed `Config:Import`;
  - the Frame level option, removed;
  - focus's duplicate `health` table. The first table was removed, since it would have offset focus health without shrinking it.
- **Health → Text → Deficit** had defaults only on party and the raids. *Fixed 2026-11-09 (options layout project, Task 9): `deficit = false` in the base health text defaults.*

**Frames with no edit mode mover:**
- **Unit frame elements placed on the screen** are moved to their own entry, [Edit mode movers for unit frame parts placed on the screen](#2026-11-09--edit-mode-movers-for-unit-frame-parts-placed-on-the-screen). The user wants that planned later as its own effort.
- **The zone text banner,** fixed at `TOP, 0, -300` (`SaftUI-Misc/Skinning/ZoneText.lua:51`). The user said to leave it for now.
- **The loot window.** Blizzard places it, and SaftUI's skin isn't loaded (see Loot above). The user said to leave its position for now.
- **`Blizzard_WatchFrame.lua`** returns early on `st.retail`, which is true on both supported clients, so it is dead code rather than a gap.
- Everything else SaftUI places has a mover.

**Why noticed:** On 2026-11-09 the user asked to "go through all of the existing config settings in saftui and see what all hasn't been setup in the config gui yet as well as what modules haven't been setup on edit mode". Three read-only agents audited the defaults by area (unit frames; Core, minimap and misc; action bars, bags, chat and loot). The session checked the edit mode side, and spot-checked the dead-setting and broken-option claims with greps.

**Anchors:**
- Defaults: `SaftUI-Core/Config/defaults.lua`, `SaftUI-*/config.lua`, `SaftUI-Unitframes/config/default.lua`, `SaftUI-Unitframes/config/units/*.lua`.
- Options: each module's `GetConfigTable`; the shared generators in `SaftUI-Core/Config/widgets.lua`.
- Movers: `st:RegisterMover` calls; `UF:RegisterMovers` in `SaftUI-Unitframes/unitframes.lua`.

**What's been considered:**
- Dead keys can be dropped from the defaults. Their saved values are harmless.
- Global colors and editable templates would be a bigger design (a Core "Appearance" section) than per-module options.
- Screen-placed unit frame elements could get their own movers when their `position.frame` is `UIParent`.

**Shape of work:** Several independent pieces:
- Quick fixes: Rename, focus `health`, the Frame level option.
- Removing the dead defaults.
- Options, one module at a time: the Loot window and Bags first, since they have the most settings with no option.
- Movers for the screen-placed unit frame elements and the zone text.
- Optionally, a Core appearance section for colors and templates.

**Open questions:**
- Which settings should never be in `/sui`, as internal tuning (e.g. `misc.clamp_inset`, `headers.height`)? *Answered 2026-11-10: the user approved options for both (Global Settings → General).*
- Should global colors and templates be editable at all?

### 2026-11-08 — Forever: wrong or missing aura tooltips on party frames

**What:** On Forever, hovering a buff on a SaftUI party frame shows another buff's tooltip or none. Blizzard's aura buttons (the `AuraContainer` that `SaftUI-Unitframes/elements/auras.lua` builds on, through oUF's Auras) fill their tooltip with `AuraButtonTooltip:SetUnitAuraByAuraInstanceID(unit, auraInstanceID)`, and on Forever that call returns the wrong aura or nothing for some party member auras. SaftUI doesn't touch that tooltip.

**Why noticed:** The user reported "Only mine" not working on party frames (fixed separately, see the Forever aura notes in `.agents/clients.md`) and noticed the tooltips along the way. Two in-game checks on `party1`, with five buffs up (Find Herbs, Mark of the Wild, Blood Pact, Arcane Intellect, Camp Benefits): `GameTooltip:SetUnitAuraByAuraInstanceID` with each aura's own `auraInstanceID` gave Find Herbs, Mark of the Wild, then Camp Benefits for Blood Pact, and nothing for Arcane Intellect or Camp Benefits.

**Anchors:** `Blizzard_AuraContainer/Blizzard_AuraButton.lua` (`ShowTooltip`, `PopulateTooltip`), `Blizzard_PrivateAurasUI/*/PrivateAurasTooltip.lua` (`ShowAuraTooltip`), `SaftUI-Unitframes/elements/auras.lua`.

**What's been considered:**
- The by-index tooltip is right on Forever: `GameTooltip:SetUnitAura('party1', i, 'HELPFUL')` gave the right name for all five buffs.
- SaftUI can't hook the buttons. The button's aura (`GetAuraInstance`) is on a secure-sourced private mixin, and the `AuraButton` template forbids `UntrustedScriptExecution` (no addon scripts on the button, propagated to its children) and `QueryFocus` (`Blizzard_AuraButton.xml`). So neither a HookScript nor a child overlay frame on a button would run.
- What's left is a SaftUI frame over the aura row, parented to the unit frame rather than to a button. On enter or update it would find the shown button under the cursor (`GetAuraGroupFrame(groupKey, i)`, `IsShown`, `IsMouseOver`), match that button's icon texture to `C_UnitAuras.GetAuraDataByIndex`, and show `GameTooltip:SetUnitAura(unit, index, filter)`. Unknowns: whether those reads are allowed (the buttons carry `DenyTaintedAccessWhenAurasAreSecret`, so not while auras are secret), two auras sharing an icon, and the overlay eating clicks meant for the buttons (cancel-aura clicks only matter on the player's own frame).
- It may be a Forever client bug better reported to its developers. Unchecked whether Blizzard's own party frames show the same thing.

**Shape of work:** The overlay idea above was built (`e3c6548`) and backed out. Blizzard sets each aura button's shown state, position and icon through `secretwrap` (`Blizzard_CustomAuraButton.lua` `ApplyVisibility`, `Blizzard_CustomAuraContainer.lua` `ApplyElementLayout`, `Blizzard_AuraContainerUtil.lua` `SetIconTextureForAura`), so they're secret to addons even out of combat: `IsShown()` errored on a boolean test, and every tooltip vanished behind the overlay. Addons can't learn which aura a button holds.

The one route left is to work out the button order without reading the buttons. Rebuild the displayed list from `C_UnitAuras` (readable out of combat): the group's filter, the Only mine candidate filter, Blizzard's sort comparator (`AuraContainerSortComparators`, ExpirationOnly), capped at the group's max. Then lay it out with SaftUI's own layout settings (size, spacing, anchor, growth, per-row width) to find which slot is under the cursor, from an overlay sized and placed by SaftUI rather than anchored to the secret-sized container. Any difference from Blizzard's order or layout shows the wrong aura's tooltip, the bug this is meant to fix. It's a design pass and a plan, not a small fix.

**Open questions:** Is the rebuilt order worth its fragility, given it only helps out of combat? Does it happen on target, focus or raid frames too, or only party? Does it hit the player's own auras on party members, which are all "Only mine" shows there? Do Blizzard's own party frames show it?

### 2026-11-08 — Edit Mode frames anchored straight to SaftUI holders: tooltip container, buffs, swing timers

**What:** Three of SaftUI's Blizzard Edit Mode takeovers anchor the Blizzard frame straight to SaftUI's holder: `GameTooltipDefaultContainer` to `SaftUITooltipHolder` (`SaftUI-Misc/tooltipposition.lua`, `UpdateTooltipAnchor`), `BuffFrame`/`DebuffFrame` to their holders (`SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua`, around line 449), and the swing timer bars to theirs (`Blizzard_SwingTimerPosition.lua`, around line 79). Blizzard's Edit Mode can read such a frame's anchor and write it into the active layout (`EditModeManagerFrameMixin:UpdateSystemAnchorInfo`, which stores `relativeTo:GetName()`), and a layout save keeps it. Wherever the holder doesn't exist (an alt with that SaftUI addon off, or the module disabled), Blizzard's `ApplySystemAnchor` would then anchor the frame to a frame that isn't there.

**Why noticed:** The totem bar mover's review (fix round 1, 2026-11-08, `.superpowers/sdd/2026-11-08-totem-mover/review-1.md`) found the same exposure for the totem bar. There the bar is snapped to MainActionBar in its default position; entering a vehicle out of combat hides MainActionBar, `BreakSnappedFrames` runs the bar's `BreakFrameSnap`, which re-anchors it (SaftUI's post-hooks put it on the holder) and then calls `OnSystemPositionChange` → `UpdateSystemAnchorInfo`, reading `GetPoint(1)`. The totem bar was fixed by placing the bar on UIParent at the holder's spot instead (`TB:AnchorBar`, re-run from a post-hook on the holder's `SetPoint`), and `.agents/edit-mode.md`'s takeover bullet now says to do that. The three older takeovers predate the rule and weren't checked.

**Anchors:** `SaftUI-Misc/tooltipposition.lua`, `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua`, `SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua`, `SaftUI-Misc/totembar.lua` (`TB:AnchorBar`, the pattern to copy), Blizzard source in `Blizzard_EditMode/Shared/EditModeSystemTemplates.lua` (`BreakFrameSnap`, `BreakSnappedFrames`, `SetSnappedToFrame`, `PrepareForSave`) and `EditModeManager.lua` (`UpdateSystemAnchorInfo`, `OnSystemPositionChange`). Related: the chat entry below (item 2), where ChatFrame1 copies its holder's anchor, so the layout names UIParent by default.

**What's been considered:** Each frame only reaches `UpdateSystemAnchorInfo` if something triggers it: a snap break (the frame is in another Edit Mode system's `snappedFrames`, which `SetSnappedToFrame` adds when Blizzard anchors it relative to that system), `PrepareForSave` on a layout save (it calls `BreakFrameSnap` for a frame not in its default position that has `alwaysUseTopLeftAnchor` or `alwaysUseTopRightAnchor`, which may be the case for the buff frames), or a drag or nudge in Blizzard's Edit Mode (blocked, as SaftUI hides their Selection). Copying the holder's anchor, as chat does, names whatever frame the user typed in Position, which could be a SaftUI frame too; placing on UIParent from the holder's rect is the safe form.

**Shape of work:** Small per frame, once confirmed: check which triggers can reach each frame on Forever and retail, then switch the ones that can to the totem bar's UIParent placement with a SetPoint post-hook on the holder. For the tooltip container the grow-from corner matters (`GrowthCorner`): place that corner on UIParent at the holder's matching corner. Buffs use two anchors (TOPLEFT and BOTTOMRIGHT) to size the frame, so they'd need two UIParent points or a SetSize.

**Open questions:** Do any of these frames have the `alwaysUseTop*Anchor` flags or get snapped to another system by default on either client? Can a SaftUI user even trigger a Blizzard layout save that includes them, given their Selection is hidden?

### 2026-11-08 — Loot rolls: confirm the client assumptions in game

**What:** The roll bar counts and the feed's roll results (`SaftUI-Loot/rollinfo.lua`, `Feed/rolls.lua`) rest on assumptions about `C_LootHistory` and the roll frames that come from reading Blizzard's source, not from the game.
- **Timing:** drops' and encounters' `startTime` and `duration` are on the same millisecond clock as `GetLootHistoryTime()`, and `duration` is the roll window. `GetOpenDrops` skips drops past it. If that's wrong, counts never appear or vanish mid-roll, and the "ago" time of a result added at load is off.
- **Roll order:** rollIDs rise in the order rolls start. Identical items pair with bars first come, first served on that.
- **History at load:** `C_LootHistory` is filled at PLAYER_LOGIN after a `/reload`, empty after a relog, and filled an encounter at a time. The load-time prune only drops keys of encounters present in the history. If an encounter is only partly listed at load, a drop missing from it can come back as a duplicate result.
- **History clears:** it's unknown when `LOOT_HISTORY_CLEAR_HISTORY` fires (zoning, leaving the group).
- **Trash rolls:** it's unknown whether trash and other non-boss group-loot rolls appear in `C_LootHistory` on Forever. README says "every item your group rolls on".

**Why noticed:** The loot rolls plan's final review (2026-11-08) listed these as unverifiable outside the game.

**Anchors:**
- `SaftUI-Loot/Feed/rolls.lua`: `RollTimeOver`, `GetOpenDrops`, `CatchUp`, `EstimateWhen`.
- `SaftUI-Loot/rollinfo.lua`: `UpdateRollBars`.
- `.agents/clients.md` "Loot rolls".
- `docs/superpowers/specs/2026-11-08-saftui-loot-rolls-history-design.md`.

**Shape of work:**
- In game (Forever, group loot): watch counts through a whole roll, roll two copies at once, `/reload` mid-roll and after, relog, roll on trash.
- Fix whatever doesn't hold.
- Record what's confirmed in `.agents/clients.md`.

### 2026-11-08 — Saved loot feed size in SaftUI_DB

**What:** The loot feed is saved per character in `SaftUI_DB` (AceDB char namespace), which is account-wide, so every character's feed is loaded at every login. 500 roll results with full roll lists come to about 1.6 MB per character at 20 players and 2.8 MB at 40, by the final reviewer's estimate. Several raiding characters could push `SaftUI_DB.lua` to 10 MB or more, parsed at every login and written at every reload.

**Why noticed:** The loot rolls plan's final review (2026-11-08), finding 4.

**Anchors:** `SaftUI-Loot/Feed/history.lua` (`SAVED_FIELDS`, `CopyRolls`), `SaftUI-Loot/Feed/rolls.lua` (`SummarizeDrop`'s trimmed lists). The reviewer's size estimate script is gone with the session scratchpad.

**What's been considered:** Store each choice's names as one compact string, Pass especially. Cap roll lists. Keep fewer entries for other players' results.

**Shape of work:** Measure first: check `SaftUI_DB.lua`'s size after a raid night. Shrink the saved roll format only if it's large.

### 2026-11-08 — Confirm the totem bar's protection and secret-value claims in game, then document the duration-object pattern

**What:** Two things in the totem bar work (`SaftUI-Misc/totemskin.lua`, `totemtimers.lua`) rest on reading Blizzard's source and API docs, not on the game:
1. The flyout, its choices and its open arrow aren't protected, so SaftUI resizes them and re-anchors the first choice in combat.
2. The timers' secret-value path works, if totem times are ever secret. It uses `GetTotemDuration` → `StatusBar:SetTimerDuration`, `FormatRemainingDuration` with a `C_StringUtil` rule formatter (probe-checked, falling back to a seconds formatter), colour curves for the 10-second warning, and `SetAlphaFromBoolean(duration:IsActive())`.

Once both are confirmed, record the duration-object pattern in `.agents/clients.md`'s secret values section, and drop the "not yet confirmed in game" wording from `.agents/taint.md` rule 6.

**Why noticed:** The totem bar plan's final review (2026-11-08). The pattern is reusable for any secret-safe timer, and it lives only in code comments until it's confirmed.

**Anchors:** `SaftUI-Misc/totemtimers.lua` (`RefreshSecret`, the formatter probe), `.agents/taint.md` rule 6, `.agents/clients.md` "Secret values", `docs/superpowers/specs/2026-11-08-saftui-totem-bar-skin-design.md`.

**Shape of work:**
- In game (Forever shaman, `/console taintLog 1`): open flyouts and change the summon page in combat, then check `taint.log`.
- A doc edit after that. The secret path only shows if totem slots ever go secret, so it may stay unconfirmed.

### 2026-11-08 — TemplateInset is duplicated between SaftUI-ActionBars and SaftUI-Misc

**What:** The helper that works out how far a template's border insets the icon exists in `SaftUI-ActionBars/skin.lua` and again as `TB.TemplateInset` in `SaftUI-Misc/totemskin.lua`, which `totemtimers.lua` shares. If one copy changes, the totem bar and the action bars drift apart.

**Why noticed:** The totem bar plan's Task 1 review (2026-11-08) parked it. SaftUI-Misc must not depend on SaftUI-ActionBars, so it couldn't call the ActionBars copy.

**Anchors:** `SaftUI-ActionBars/skin.lua` (`TemplateInset`), `SaftUI-Misc/totemskin.lua` (`TB.TemplateInset`).

**Shape of work:** Small: move it into SaftUI-Core (next to `st:CalculateSpacing` / the template helpers) as `st:TemplateInset(template)` and use it from both.

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

### 2026-11-07 — Fonts outline dropdowns show None as a blank entry

**What:** `FN.outlines` in `SaftUI-Core/Media/fonts.lua` is the `values` table for every font outline dropdown, and its `NONE` entry is `st.retail and '' or 'NONE'`. `st.retail` is true on both clients, so the None choice shows as a blank line in `/sui` → Fonts and in the Auras text options. It looks like the `''` was meant as the font flag to pass to `SetFont` rather than the label. `FN:UpdateFontConfig` passes the saved `'NONE'` straight to `SetFont`.

**Why noticed:** Building the action bars' Text options (Task 3 of `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`). `SaftUI-ActionBars/options.lua` copies the table and names None itself, and `skin.lua` maps `'NONE'` to `''` for `SetFont`, as `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua` (`OutlineFlags`) already does.

**Anchors:** `SaftUI-Core/Media/fonts.lua` (`FN.outlines`, `FN:UpdateFontConfig`); `OutlineFlags` in `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua` and `SaftUI-ActionBars/skin.lua`; `OutlineValues` in `SaftUI-ActionBars/options.lua`.

**Shape of work:** Small: label `NONE` as 'None', map `'NONE'` to `''` in `FN:UpdateFontConfig`, then drop the local copies in the action bars and auras.

### 2026-11-07 — Unit frame defaults that nothing reads, or that break when turned on

**What:** Adding `/sui` tabs for the remaining unit frame elements turned up defaults (`SaftUI-Unitframes/config/default.lua`, `config/units/*.lua`) that do nothing, or that error once turned on. They were left out of the options:
- **Read by nothing:**
  - Auras: `font` (the count always has its own `count.font`), `showDebuffType`, `horizontal_growth`, `showBar` (player buffs) and `border` (target buffs). Also the `filter` tables and `desaturateOthers`, which the aura-container followup below covers.
  - Additional power: `colorClass` (oUF's AdditionalPower only knows `colorPower`), `text.hide_full`, `text.percent`. *2026-11-09 (0308977): `colorClass` removed; `text.hide_full` and `text.percent` hooked up.*
  - Class power: `show_empty` is read (`elements/classpower.lua`) but changes nothing, since oUF already shows every point up to the max.
  - Focus `castbar.colors.normal = { .5, .9, .7 }`: a list, but `GetRGB` reads the `r`/`g`/`b` that the base default's color fills in, so the focus castbar uses the base color. *Fixed 2026-11-09 (options layout project, Task 9): now `{ r = .5, g = .9, b = .7 }`.*
  - Raid target `position.element = 'Portrait'`: Portrait isn't registered, so the marker anchors to the unit frame.
  - `widget` (`widget.lua` is commented out of `elements/elements.xml`, and it has no `UpdateConfig`), `portrait` and `aurawatch` (their `RegisterElement` calls are commented out).
- **Errors once on** (*both fixed 2026-11-09:* `colorCustom` reads either color shape through `UF.UnpackColor`, and is applied in `PostUpdateColor` after oUF's recolor on health, power and additional power, with power backgrounds following it. The castbar's `bg` has `alpha`/`multiplier` defaults and is colored from the bar. `tests/unitframes/bar_colors_test.lua`. Still open: `groups.lua`'s preview path applies the custom power color without `UF.SetPowerBackgroundColor`):
  - `castbar.bg.enable`: the castbar's `bg` has no `alpha` or `multiplier`, so `UF:UpdateStatusBarElement` calls `bg:SetAlpha(nil)`. Nothing colors the background either.
  - `colorCustom` on health, power and additional power: the `customColor` defaults are plain `{ r, g, b }` lists, and `config.customColor:GetRGB()` errors on them.
- **Half done:** `additionalpower.manaAsPrimary` swaps the size, texture and text settings of the Power and AdditionalPower bars (`UF:UpdateElement`'s `configOverride`), but not their positions: `UF:UpdateElementPosition(element, unitframe, configOverride)` gets the override in its `unitframe` slot. The `Override` that would keep the bar on mana is commented out, and power's `GetDisplayPower` never runs (oUF only calls it with `displayAltPower`).
- **Looks broken:** additional power defaults to `colorPower = false`, and nothing else colors the bar or its background, so it's white once enabled. Its `/sui` option says so. *Fixed 2026-11-09 (options layout project, Task 9): the default is `colorPower = true`.*

**Progress 2026-11-09:** the additional power bar's color (`colorPower = true`), the focus castbar color (now `{ r, g, b }`) and the health text Deficit defaults (on every unit) are fixed (options layout project 2, Task 9, `e5e4426`), and `colorCustom` and the castbar background were fixed earlier the same day. What's left is the "read by nothing" keys, `show_empty`, Raid target's `Portrait` anchor, and the `manaAsPrimary` decision.

**Why noticed:** On 2026-11-07, while adding Castbar, Class power, Additional power, Buffs, Debuffs and indicator tabs to `/sui` → Unitframes (the user asked to "start adding other UF elements to the config"). The rule for that pass was to expose only settings the element code reads, and note the rest.

**Anchors:** `SaftUI-Unitframes/config/default.lua`, `config/units/focus.lua`, `config/units/player.lua` (`manaAsPrimary`); `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`, `UF:UpdateStatusBarElement`); `SaftUI-Unitframes/elements/additionalpower.lua`, `power.lua` (`GetDisplayPower`), `health.lua` (`PostUpdateHealth`), `classpower.lua`, `auras.lua`, `elements/elements.xml`; `SaftUI-Unitframes/groups.lua` (`UnpackColor`).

**What's been considered:**
- Keys nothing reads can simply be dropped from the defaults. Saved values of them are harmless.
- `customColor`: store it as a color (`CreateColor`), or read it with something like `groups.lua`'s `UnpackColor`, which takes either shape. Then `colorCustom` and a color picker could go into the Health and Power tabs.
- Castbar background: give it `alpha` and `multiplier` defaults and color it from the bar color, or drop `bg` from the castbar defaults.
- Additional power: default `colorPower = true`, or color the bar in `PostUpdateColor` when oUF passes no color.

**Shape of work:** A small cleanup of the defaults, plus two small fixes (`customColor`, the castbar background). `manaAsPrimary` needs a decision first.

**Open questions:** Finish `manaAsPrimary` or remove it? Should the focus castbar get its own color back? *(The second was settled by the options layout spec: yes, fixed 2026-11-09.)*

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

### 2026-11-10 — Boss frames have no test mode, so their Layout options can't be checked out of an encounter

**What:** Party and raid have a Test mode toggle that fills their holder with SaftUI-owned preview frames (`UF:UpdateGroupPreview`, `SaftUI-Unitframes/groups.lua`). Boss has none, so its new Layout options (Growth, Column growth, Spacing, Column spacing, Units per column, Max columns) can only be seen with real boss frames up.

**Why noticed:** The user's in-game check of options project 2 (2026-11-10): the boss Layout options "look good", but "I'd need a test mode with boss frames to see them".

**Anchors:** `SaftUI-Unitframes/groups.lua` (the group test mode section: `UF.testGroups`, `UF.previews`, `CreatePreviewFrame`, `StylePreviewFrame`, `FillPreviewFrame`); `SaftUI-Unitframes/unitframes.lua` (`PlaceUnitFrame`, which parks boss frames past `shown`); `UF.GroupAnchor` and `UF.GetGroupLayoutSize`; the Test mode toggle in `SaftUI-Unitframes/config/config.lua` (`args.test_mode`, groups only today); `.agents/edit-mode.md` "Test modes" rule (never fake units or override Blizzard APIs).

**What's been considered:** Reuse the group previews: they're plain frames styled from the same config and laid out with the same sums. Boss frames aren't a header, so the preview container would stand in for the boss holder and place previews with `UF.GroupAnchor`, hiding while any real boss frame shows. Nothing secure is touched, so it can run in combat like the group previews.

**Shape of work:** Small: widen the test mode to boss (preview count = the boss frame count the layout shows), add the toggle to the boss page, a test like the group preview tests.

**Resolved 2026-11-10:** boss's Layout has the Test mode toggle; `UF:UpdateGroupPreview('boss')` fills the boss holder with made-up bosses (hostile, full health, no role), one per boss frame the layout shows, where `UF:PlaceUnitFrame` puts each, redrawn on Layout and color changes and hidden while any boss frame shows (`UF:WatchFramesForPreview`). tests/unitframes/boss_preview_test.lua.

### 2026-11-09 — Test runner self-check: tell a runner crash from a caught failure

**What:** Two small gaps in the new test suite (`tests/`):
- `tests/run --self-check` (`tests/runner.py`) treats any exit code of 1 as "the runner caught the broken fixture". A Python traceback in `runner.py` also exits 1, so a crashing runner would pass its own self-check. The fix is to assert on the output text, or give test failures a distinct exit code.
- `.agents/testing.md` doesn't say that code running inside a coroutine escapes the per-case instruction limit. Lua 5.1's `debug.sethook` is per coroutine, and only `tests/lib/harness.lua`'s comment says so.

**Why noticed:** The scoped re-review of the test suite's final fix wave (2026-11-09) listed both as out of scope. The suite merged without them.

**Anchors:** `tests/runner.py` (`--self-check`, `FIXTURE_EXPECTED`), `tests/lib/runner_fixtures/`, `tests/lib/harness.lua` (`limited()`), `.agents/testing.md`.

**Shape of work:** Small: one runner change with a fixture that crashes the runner, and one doc line.

**Resolved 2026-11-09:** test failures exit 1, a runner crash exits 70 (any Python exception, including one inside running a file), and the self-check checks each fixture's expected text with no traceback, plus two hidden crash cases. .agents/testing.md also says code inside a coroutine escapes the instruction limit.

### 2026-11-08 — The roll bar skin writes fields onto Blizzard's GroupLootFrames

**What:** `SaftUI-Loot/roll.lua`'s skin of Blizzard's roll frames writes fields onto them: `frame.skinned`, `frame.Timer.Text`, each roll button's `.Text`, `frame.InfoFrame` (`LT:SkinRollFrame`, `LT:UpdateRollFrame`), and `st:SetBackdrop` on `frame.InfoFrame` / `frame.IconFrame` writes `.backdrop` onto `IconFrame`. That breaks `.agents/taint.md` rule 1. The roll frames aren't protected, so the risk is Blizzard's GroupLootFrame code reading a tainted value, not a blocked action, but it's the same pattern the rule exists for.

**Why noticed:** Writing the loot rolls and saved feed design (2026-11-08), which adds counts to the roll buttons. That design makes new code keep its pieces in its own tables and leaves the existing writes alone to keep its scope.

**Anchors:** `SaftUI-Loot/roll.lua` (lines around `frame.skinned`, `frame.Timer.Text`, `button.Text`, `frame.InfoFrame`); `.agents/taint.md` rule 1 and its "skinning a Blizzard button" pattern (added with the totem bar skin); `docs/superpowers/specs/2026-11-08-saftui-loot-rolls-history-design.md`.

**What's been considered:** Move every SaftUI piece into a table keyed by the roll frame, as `SaftUI-Misc/totemskin.lua` does, and build backdrops as SaftUI frames rather than `st:SetBackdrop` on Blizzard's.

**Shape of work:** Small refactor of `roll.lua`, plus an in-game check of rolls in a group and the test previews.

**Resolved 2026-11-09:** the skin keeps its pieces in weak side tables (LT:GetRollInfoFrame for rollinfo.lua), and the icon backdrop sits on a SaftUI iconBox frame. tests/loot/roll_skin_test.lua. st:Kill and st:SkinIcon on Blizzard pieces remain; they have their own followup.

### 2026-11-09 — The /link copy dialog replaces scripts on Blizzard's popup edit box

**What:** `EXTRACT_LINK_DIALOG` (`SaftUI-Core/utilities.lua`, `/link`) calls `SetScript('OnTextChanged')` and `SetScript('OnEscapePressed')` on the dialog's edit box. That replaces Blizzard's handlers on that `StaticPopupN` for good, so later Blizzard dialogs on the same frame lose them. A delete-item confirmation's typed text, for one, is reset to the link. That breaks taint rule 2. It also reads `self.editBox`, which current dialogs don't have (`GetEditBox()`), so `/link` likely errors anyway.

**Why noticed:** On 2026-11-09, while fixing the unit frame profile popups, which had the same kind of field writes on `StaticPopup1`.

**Anchors:** `SaftUI-Core/utilities.lua` (`EXTRACT_LINK_DIALOG`). Blizzard's dialog keys `EditBoxOnTextChanged` and `EditBoxOnEscapePressed` (`Blizzard_StaticPopup/SharedTemplates.lua` on the forever branch).

**What's been considered:** Put the handlers in the dialog definition's `EditBoxOnTextChanged` / `EditBoxOnEscapePressed` keys. Blizzard calls those per dialog, so nothing is replaced. Find the edit box with `dialog:GetEditBox()`.

**Shape of work:** A small fix in one file.

**Resolved 2026-11-09:** EXTRACT_LINK_DIALOG uses Blizzard's EditBoxOnTextChanged / EditBoxOnEscapePressed dialog keys and GetEditBox(); no SetScript. Both clients' handler signatures were checked. tests/core/link_dialog_test.lua.

### 2026-11-07 — Tooltip skin writes .backdrop onto Blizzard's tooltips

**What:** `SaftUI-Misc/tooltip.lua` skins Blizzard's tooltips with `st:SetBackdrop(GameTooltip, ...)` (also `ItemRefTooltip`, the shopping tooltips, `GameTooltipStatusBar`, `DropDownList1/2`), which writes a `.backdrop` field onto each Blizzard frame. That breaks rule 1 in `.agents/taint.md`. `GameTooltip_OnTooltipSetUnit` then reads `tooltip.backdrop` back to color the border.

**Why noticed:** The 2026-11-07 review of the tooltip mover (`f7ec45e`, review in `.superpowers/sdd/2026-11-07-saftui-action-bars/review-tooltip.md`) flagged it as outside that commit. The same review flagged AceHook's replacing `HookScript` on GameTooltip's OnShow, which is now a `SecureHookScript`.

**Anchors:** `SaftUI-Misc/tooltip.lua` (`OnEnable`, `UpdateConfig`, `UpdateTooltipDisplay`, `GameTooltip_OnTooltipSetUnit`), `SaftUI-Core/panels.lua` (`st:SetBackdrop`), `.agents/taint.md` rule 1.

**What's been considered:** Keep each tooltip's SaftUI backdrop frame in a local weak table keyed by the tooltip, as the rule says, and color it through that table. The tooltips are Blizzard frames that secure code uses heavily on Midnight (secret values), so this is worth doing before tooltip errors show up rather than after.

**Shape of work:** A small refactor of `tooltip.lua`. It may want a `st:SetBackdrop` variant that returns the backdrop frame without storing it on the target, which other skins writing onto Blizzard frames could reuse.

**Resolved 2026-11-09:** the skin keeps its backdrop frames in a weak table, through the new st:SetBackdropIn (SaftUI-Core/api.lua), and writes nothing onto Blizzard's tooltips. tests/misc/tooltip_skin_test.lua pins it. The st:CreateCloseButton call is fixed separately by the options window work.

### 2026-11-08 — Older loot feed quirks: timer refresh by unfiltered index, a full feed trims on merges

**What:** Two older behaviours in `SaftUI-Loot/Feed/feed.lua` that the saved feed makes more visible:
- `LT:UpdateAllFeedTimers(index)` indexes the unfiltered `feed_stack` with an index from the filtered list. While filters hide some entries, hovering a line can refresh the wrong entries' fade timers.
- `LT:LootFeedPush` drops the oldest entry when the feed is full, even when the push then merges into the top entry. So a full feed loses an entry on a merge. The saved store is trimmed separately, so the two only drift slightly.

**Why noticed:** The loot rolls plan's reviews (2026-11-08) noted both as existing code, outside that plan.

**Anchors:** `SaftUI-Loot/Feed/feed.lua` (`UpdateAllFeedTimers`, `LootFeedPush`), `SaftUI-Loot/Feed/filter.lua` (`GetFilteredItems`).

**Shape of work:** Small: index the filtered list in `UpdateAllFeedTimers`, and trim only when an entry is actually inserted.

**Resolved 2026-11-09:** both quirks are fixed in SaftUI-Loot/Feed/feed.lua: hover refreshes timers through the filtered list, and only an insert trims a full feed. tests/loot/feed_test.lua pins both.

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
