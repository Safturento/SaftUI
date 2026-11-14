# Followups

A queue between "noticed it" and "decided what to do about it." Items might become Jira tickets, get fixed inline during related work, or be explicitly abandoned. Triage periodically.

Format: see the user-level `~/.claude/CLAUDE.md` "Followup detection" section.

## Contents

- [Active](#active)
  - [2026-11-14 — A first-run setup dialog: UI size, theme, unit frame layout](#2026-11-14--a-first-run-setup-dialog-ui-size-theme-unit-frame-layout)
  - [2026-11-14 — /sui at half with the sidebar collapsed: a validation error is cut or hidden in the footer](#2026-11-14--sui-at-half-with-the-sidebar-collapsed-a-validation-error-is-cut-or-hidden-in-the-footer)
  - [2026-11-14 — Categories tab at full size: a long "Reset <name> to default" overlaps Delete](#2026-11-14--categories-tab-at-full-size-a-long-reset-name-to-default-overlaps-delete)
  - [2026-11-14 — Copy from writes default tables into keys the source unit doesn't have](#2026-11-14--copy-from-writes-default-tables-into-keys-the-source-unit-doesnt-have)
  - [2026-11-13 — Design decisions waiting to be built](#2026-11-13--design-decisions-waiting-to-be-built)
  - [2026-11-13 — Objective tracker skin: in-game checks and what was left out](#2026-11-13--objective-tracker-skin-in-game-checks-and-what-was-left-out)
  - [2026-11-13 — Scale SaftUI across resolutions and stay pixel perfect](#2026-11-13--scale-saftui-across-resolutions-and-stay-pixel-perfect)
  - [2026-11-13 — Bags: a general sort order of draggable blocks, with a per-category override](#2026-11-13--bags-a-general-sort-order-of-draggable-blocks-with-a-per-category-override)
  - [2026-11-13 — Unit frames: shared settings across units, and small parts as menu items](#2026-11-13--unit-frames-shared-settings-across-units-and-small-parts-as-menu-items)
  - [2026-11-13 — Character frame slots: SaftUI writes fields onto Blizzard's buttons](#2026-11-13--character-frame-slots-saftui-writes-fields-onto-blizzards-buttons)
  - [2026-11-13 — Loot rolls: the roll bar doesn't hold after a choice](#2026-11-13--loot-rolls-the-roll-bar-doesnt-hold-after-a-choice)
  - [2026-11-13 — Test mode: choose which elements the previews show](#2026-11-13--test-mode-choose-which-elements-the-previews-show)
  - [2026-11-13 — Unit frame profiles are hard to find in /sui](#2026-11-13--unit-frame-profiles-are-hard-to-find-in-sui)
  - [2026-11-13 — Colour swatches read as checkboxes, and the colour picker](#2026-11-13--colour-swatches-read-as-checkboxes-and-the-colour-picker)
  - [2026-11-13 — Codebase cleanup: small things left over](#2026-11-13--codebase-cleanup-small-things-left-over)
  - [2026-11-13 — Chat's dock hook runs only on forced updates](#2026-11-13--chats-dock-hook-runs-only-on-forced-updates)
  - [2026-11-13 — Bag search box is made multi-line](#2026-11-13--bag-search-box-is-made-multi-line)
  - [2026-11-12 — Codebase cleanup: the items waiting on a decision](#2026-11-12--codebase-cleanup-the-items-waiting-on-a-decision)
  - [2026-11-12 — Cooldown Manager skin: in-game checks](#2026-11-12--cooldown-manager-skin-in-game-checks)
  - [2026-11-12 — Cooldown Manager skin: a tracked debuff's dispel type on SaftUI's border](#2026-11-12--cooldown-manager-skin-a-tracked-debuffs-dispel-type-on-saftuis-border)
  - [2026-11-12 — Nameplates: a plate page's Position editor checks anchors against whichever plate has the lowest number](#2026-11-12--nameplates-a-plate-pages-position-editor-checks-anchors-against-whichever-plate-has-the-lowest-number)
  - [2026-11-12 — Unit frames: a profile switch places a frame's parts against the old profile's anchors](#2026-11-12--unit-frames-a-profile-switch-places-a-frames-parts-against-the-old-profiles-anchors)
  - [2026-11-12 — Nameplates: the Friendly page's aura borders and cooldown never reach plate buttons](#2026-11-12--nameplates-the-friendly-pages-aura-borders-and-cooldown-never-reach-plate-buttons)
  - [2026-11-12 — Nameplates: what a kind change costs in oUF updates](#2026-11-12--nameplates-what-a-kind-change-costs-in-ouf-updates)
  - [2026-11-12 — Nameplates: a box toggled in combat leaves shown plates on the old config until combat ends](#2026-11-12--nameplates-a-box-toggled-in-combat-leaves-shown-plates-on-the-old-config-until-combat-ends)
  - [2026-11-12 — Nameplates: a neutral unit turning hostile keeps its name's old color](#2026-11-12--nameplates-a-neutral-unit-turning-hostile-keeps-its-names-old-color)
  - [2026-11-12 — Nameplates: friendly players and friendly NPCs configured apart](#2026-11-12--nameplates-friendly-players-and-friendly-npcs-configured-apart)
  - [2026-11-11 — Nameplates: in-game checks](#2026-11-11--nameplates-in-game-checks)
  - [2026-11-11 — Nameplates: a profile switch doesn't set the game's friendly plates](#2026-11-11--nameplates-a-profile-switch-doesnt-set-the-games-friendly-plates)
  - [2026-11-11 — UIParent's scale is set once, at login, so plates leave whole pixels after a UI scale or display change](#2026-11-11--uiparents-scale-is-set-once-at-login-so-plates-leave-whole-pixels-after-a-ui-scale-or-display-change)
  - [2026-11-11 — Nameplates: a plate that turns widgets-only, or back, without a new add](#2026-11-11--nameplates-a-plate-that-turns-widgets-only-or-back-without-a-new-add)
  - [2026-11-11 — Nameplates: small items left after the build](#2026-11-11--nameplates-small-items-left-after-the-build)
  - [2026-11-11 — Health text's Boss percent and Hide full with a secret health](#2026-11-11--health-texts-boss-percent-and-hide-full-with-a-secret-health)
  - [2026-11-11 — Purge filters: in-game checks](#2026-11-11--purge-filters-in-game-checks)
  - [2026-11-11 — Purge table: retail gaps](#2026-11-11--purge-table-retail-gaps)
  - [2026-11-11 — Blizzard theme round 2: in-game checks](#2026-11-11--blizzard-theme-round-2-in-game-checks)
  - [2026-11-11 — Blizzard theme: a border per real raid group, not per header](#2026-11-11--blizzard-theme-a-border-per-real-raid-group-not-per-header)
  - [2026-11-11 — /sui: no resize cursor on the grip and the bottom edge](#2026-11-11--sui-no-resize-cursor-on-the-grip-and-the-bottom-edge)
  - [2026-11-11 — Screen edge margin: art reach only for /sui](#2026-11-11--screen-edge-margin-art-reach-only-for-sui)
  - [2026-11-11 — Blizzard theme round 2: test gaps and small items parked in review](#2026-11-11--blizzard-theme-round-2-test-gaps-and-small-items-parked-in-review)
  - [2026-11-11 — Categories tab: the scrolled editor's two gaps](#2026-11-11--categories-tab-the-scrolled-editors-two-gaps)
  - [2026-11-11 — Blizzard theme: in-game checks](#2026-11-11--blizzard-theme-in-game-checks)
  - [2026-11-11 — st:SetBackdrop and st:SetBackdropIn do arithmetic on frame levels that can be Blizzard's](#2026-11-11--stsetbackdrop-and-stsetbackdropin-do-arithmetic-on-frame-levels-that-can-be-blizzards)
  - [2026-11-11 — Edit Mode snapping under Blizzard measures the frames' borders, not the selection art](#2026-11-11--edit-mode-snapping-under-blizzard-measures-the-frames-borders-not-the-selection-art)
  - [2026-11-11 — Per-dispel-type debuff art on SaftUI's own aura buttons](#2026-11-11--per-dispel-type-debuff-art-on-saftuis-own-aura-buttons)
  - [2026-11-11 — Blizzard bag-bar slots and the Hekili skin write onto frames that aren't SaftUI's](#2026-11-11--blizzard-bag-bar-slots-and-the-hekili-skin-write-onto-frames-that-arent-saftuis)
  - [2026-11-11 — Loot feed: retail item quality text and profession overlay sit under the Blizzard ring](#2026-11-11--loot-feed-retail-item-quality-text-and-profession-overlay-sit-under-the-blizzard-ring)
  - [2026-11-11 — The disabled loot popup writes nametext onto Blizzard's LootButton](#2026-11-11--the-disabled-loot-popup-writes-nametext-onto-blizzards-lootbutton)
  - [2026-11-11 — Class power types with no Blizzard art draw a borderless flat bar under Blizzard](#2026-11-11--class-power-types-with-no-blizzard-art-draw-a-borderless-flat-bar-under-blizzard)
  - [2026-11-11 — Blizzard theme: the bags' rule editor and Categories list keep the options window's own look](#2026-11-11--blizzard-theme-the-bags-rule-editor-and-categories-list-keep-the-options-windows-own-look)
  - [2026-11-11 — Grays/Auto Vendor: a finished edit that broadens its rule sells at the next merchant](#2026-11-11--graysauto-vendor-a-finished-edit-that-broadens-its-rule-sells-at-the-next-merchant)
  - [2026-11-11 — Rule editor: a level mode picked before a number is typed does nothing](#2026-11-11--rule-editor-a-level-mode-picked-before-a-number-is-typed-does-nothing)
  - [2026-11-11 — Bag categories: in-game checks](#2026-11-11--bag-categories-in-game-checks)
  - [2026-11-11 — Bag settings: the reagent section nothing reads](#2026-11-11--bag-settings-the-reagent-section-nothing-reads)
  - [2026-11-11 — ItemRack is still an optional dependency, and nothing reads it](#2026-11-11--itemrack-is-still-an-optional-dependency-and-nothing-reads-it)
  - [2026-11-11 — Bag categories: a default added in a later version can duplicate a user category's name](#2026-11-11--bag-categories-a-default-added-in-a-later-version-can-duplicate-a-user-categorys-name)
  - [2026-11-11 — Bag categories: a Set checkbox is dead while the Equipment sets entry hides the window](#2026-11-11--bag-categories-a-set-checkbox-is-dead-while-the-equipment-sets-entry-hides-the-window)
  - [2026-11-11 — Old gear's tabard and shirt exclusion never matched](#2026-11-11--old-gears-tabard-and-shirt-exclusion-never-matched)
  - [2026-11-11 — Auto Vendor pins now beat Grays' exclusions and equipment sets](#2026-11-11--auto-vendor-pins-now-beat-grays-exclusions-and-equipment-sets)
  - [2026-11-10 — Fonts: separate the fonts users pick per kind of text from SaftUI's internal font objects](#2026-11-10--fonts-separate-the-fonts-users-pick-per-kind-of-text-from-saftuis-internal-font-objects)
  - [2026-11-10 — Zone level and faction line: in-game checks](#2026-11-10--zone-level-and-faction-line-in-game-checks)
  - [2026-11-10 — Zone faction line edge cases: a PvP subzone's status, same-named zones on the map](#2026-11-10--zone-faction-line-edge-cases-a-pvp-subzones-status-same-named-zones-on-the-map)
  - [2026-11-10 — Zone text's fade times are written onto Blizzard's frames](#2026-11-10--zone-texts-fade-times-are-written-onto-blizzards-frames)
  - [2026-11-10 — The zone faction table is a snapshot of two builds](#2026-11-10--the-zone-faction-table-is-a-snapshot-of-two-builds)
  - [2026-11-10 — Chat writes fields and scripts onto Blizzard's chat frames](#2026-11-10--chat-writes-fields-and-scripts-onto-blizzards-chat-frames)
  - [2026-11-10 — The Hekili and WeakAuras skins error when Skinning's Theme is None](#2026-11-10--the-hekili-and-weakauras-skins-error-when-skinnings-theme-is-none)
  - [2026-11-10 — Edit box focus borders lost on a theme switch, and two ways of keeping colors](#2026-11-10--edit-box-focus-borders-lost-on-a-theme-switch-and-two-ways-of-keeping-colors)
  - [2026-11-10 — Retail bank leftovers after Themes: category selector, selected window's border, radio group under None](#2026-11-10--retail-bank-leftovers-after-themes-category-selector-selected-windows-border-radio-group-under-none)
  - [2026-11-10 — Themes: in-game checks for what was only compile-checked](#2026-11-10--themes-in-game-checks-for-what-was-only-compile-checked)
  - [2026-11-10 — Bag views: the bank windows build a full button pool per view](#2026-11-10--bag-views-the-bank-windows-build-a-full-button-pool-per-view)
  - [2026-11-10 — Bank eye toggle doesn't re-apply the bag search](#2026-11-10--bank-eye-toggle-doesnt-re-apply-the-bag-search)
  - [2026-11-10 — Bag views: in-game checks for what the stubs can't show](#2026-11-10--bag-views-in-game-checks-for-what-the-stubs-cant-show)
  - [2026-11-10 — Bag item sort compares item levels as text, and should be built from blocks](#2026-11-10--bag-item-sort-compares-item-levels-as-text-and-should-be-built-from-blocks)
  - [2026-11-10 — The minimap has no SaftUI holder, so the screen edge margin only holds it in edit mode](#2026-11-10--the-minimap-has-no-saftui-holder-so-the-screen-edge-margin-only-holds-it-in-edit-mode)
  - [2026-11-10 — panels.tab_height has no option, because nothing live reads it](#2026-11-10--panelstab_height-has-no-option-because-nothing-live-reads-it)
  - [2026-11-10 — Colors tab: role and rune colors, and a switch for Blizzard's class colors](#2026-11-10--colors-tab-role-and-rune-colors-and-a-switch-for-blizzards-class-colors)
  - [2026-11-09 — st:Kill and st:SkinIcon still write onto Blizzard pieces (roll bars and elsewhere)](#2026-11-09--stkill-and-stskinicon-still-write-onto-blizzard-pieces-roll-bars-and-elsewhere)
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
  - [2026-11-08 — Specialty bags (herb, mining, etc.) count as normal bags in the bag window](#2026-11-08--specialty-bags-herb-mining-etc-count-as-normal-bags-in-the-bag-window)
  - [2026-11-07 — Minimap pieces still belong to MinimapCluster, which stretches across the screen](#2026-11-07--minimap-pieces-still-belong-to-minimapcluster-which-stretches-across-the-screen)
  - [2026-11-07 — Extra buttons leftovers: zone ability hidden by Blizzard's bar settings, Blizzard's art, skinned vehicles' pitch and status bars](#2026-11-07--extra-buttons-leftovers-zone-ability-hidden-by-blizzards-bar-settings-blizzards-art-skinned-vehicles-pitch-and-status-bars)
  - [2026-11-07 — Pet and stance bar leftovers: spellbook highlight, pings, pickup click, autocast names after an in-combat pet swap](#2026-11-07--pet-and-stance-bar-leftovers-spellbook-highlight-pings-pickup-click-autocast-names-after-an-in-combat-pet-swap)
  - [2026-11-07 — Unit frame defaults that nothing reads, or that break when turned on](#2026-11-07--unit-frame-defaults-that-nothing-reads-or-that-break-when-turned-on)
  - [2026-11-07 — Action bar leftovers: main bar concealed not blocked, LibActionButton on deprecated APIs, unskinned flyouts](#2026-11-07--action-bar-leftovers-main-bar-concealed-not-blocked-libactionbutton-on-deprecated-apis-unskinned-flyouts)
  - [2026-11-07 — Chat mover leftovers: overlay reach-in, anchor in Blizzard layout, clamp dead zone](#2026-11-07--chat-mover-leftovers-overlay-reach-in-anchor-in-blizzard-layout-clamp-dead-zone)
  - [2026-11-07 — Profile switch: Show/Hide on protected frames in combat, mover/unit-frame anchor swaps](#2026-11-07--profile-switch-showhide-on-protected-frames-in-combat-moverunit-frame-anchor-swaps)
  - [2026-11-07 — Profile settings that still need a /reload after a profile switch](#2026-11-07--profile-settings-that-still-need-a-reload-after-a-profile-switch)
  - [2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite](#2026-11-05--aura-filters-and-per-aura-styling-lost-in-the-ouf-aura-container-rewrite)
- [Resolved](#resolved)
  - [2026-11-13 — Theme change errors in the theme engine: can't measure restricted regions](#2026-11-13--theme-change-errors-in-the-theme-engine-cant-measure-restricted-regions)
  - [2026-11-13 — Action bars: shared settings for all bars, and Cooldown numbers as an Enable box](#2026-11-13--action-bars-shared-settings-for-all-bars-and-cooldown-numbers-as-an-enable-box)
  - [2026-11-13 — In-game pass: five small changes asked for](#2026-11-13--in-game-pass-five-small-changes-asked-for)
  - [2026-11-13 — Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks)
  - [2026-11-11 — UF:UpdateElement passes its config override into the wrong argument of UpdateElementPosition (Mana as primary)](#2026-11-11--ufupdateelement-passes-its-config-override-into-the-wrong-argument-of-updateelementposition-mana-as-primary)
  - [2026-11-07 — Fonts outline dropdowns show None as a blank entry](#2026-11-07--fonts-outline-dropdowns-show-none-as-a-blank-entry)
  - [2026-11-12 — Nameplates: a plate switching config can trip an anchor loop in a user's config](#2026-11-12--nameplates-a-plate-switching-config-can-trip-an-anchor-loop-in-a-users-config)
  - [2026-11-09 — Unit frame color flags are set after oUF enables the bars, so their recolor events are never registered](#2026-11-09--unit-frame-color-flags-are-set-after-ouf-enables-the-bars-so-their-recolor-events-are-never-registered)
  - [2026-11-11 — Blizzard theme: the bag slot bars sit over the metal's title bar](#2026-11-11--blizzard-theme-the-bag-slot-bars-sit-over-the-metals-title-bar)
  - [2026-11-11 — Blizzard theme: test gaps left after the final review](#2026-11-11--blizzard-theme-test-gaps-left-after-the-final-review)
  - [2026-11-11 — Blizzard theme: dark grey everywhere](#2026-11-11--blizzard-theme-dark-grey-everywhere)
  - [2026-11-10 — Two ways to reset a border to the theme's (bag slots and action buttons)](#2026-11-10--two-ways-to-reset-a-border-to-the-themes-bag-slots-and-action-buttons)
  - [2026-11-10 — Bag categories: make the category rules configurable in /sui](#2026-11-10--bag-categories-make-the-category-rules-configurable-in-sui)
  - [2026-11-10 — Zone text replaces Blizzard's OnEvent script with AceHook's HookScript](#2026-11-10--zone-text-replaces-blizzards-onevent-script-with-acehooks-hookscript)
  - [2026-11-10 — Loot rolls stay shown, locked, after you choose (approved, queued after Themes)](#2026-11-10--loot-rolls-stay-shown-locked-after-you-choose-approved-queued-after-themes)
  - [2026-11-09 — st:SetBackdropIn duplicates st:SetBackdrop](#2026-11-09--stsetbackdropin-duplicates-stsetbackdrop)
  - [2026-11-08 — TemplateInset is duplicated between SaftUI-ActionBars and SaftUI-Misc](#2026-11-08--templateinset-is-duplicated-between-saftui-actionbars-and-saftui-misc)
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
  - [2026-11-11 — Nameplates: a plate handed to the other kind scans its auras twice](#2026-11-11--nameplates-a-plate-handed-to-the-other-kind-scans-its-auras-twice)

## Active

### 2026-11-14 — A first-run setup dialog: UI size, theme, unit frame layout

**What:** A dialog shown the first time SaftUI runs that walks a new player through a few choices and introduces the UI: the UI size (a default worked out from their resolution, which they can override), the theme (Thick, Thin, Blizzard, and any added later), and which unit frame layout to use, from a few the owner will make.

**Why noticed:** The owner, while the UI scaling design was being written (2026-11-14): "I wonder if it would be worth having an initial setup dialog that can work through a few steps and introduce the UI, this scaling could be a good first candidate - set a default based on the user's resolution but allow them to override it. I'm probably going to setup a few different unitframe configurations, so a follow up setup could be choosing which unitframe theme to choose (also picking which theme from thick, thin, blizzard, and any other that gets added)". The friends who play at 1080p and on a Mac at 3456x2234 are the people it is for: they get SaftUI's defaults, tuned on the owner's 1440p screen, with no guided way to fit them.

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` (the scale's interface a setup step calls: computed default, preview, apply, revert); `SaftUI-Core/Media/theme.lua` (the theme setting); `SaftUI-Unitframes/config/profiles.lua` (unit frame profiles, the natural home for shipped layouts); `SaftUI-Core/Config/optionssmalldialog.lua` and `optionsdialog.lua` (the kit's dialogs); `SaftUI-Core/Config/` (AceDB: where "setup done" would be recorded).

**What's been considered:** The scaling design keeps "the default worked out from the resolution" apart from "what the player chose" so this dialog can show one and save the other, and ships usable without the dialog. Nothing else is designed.

**Shape of work:** A design first. Likely pieces: the dialog itself (steps, back and next, skip, a live preview behind it); a way to ship unit frame layouts as data (presets the owner authors in game and exports, loaded as named unit frame profiles); each step's content; when it shows (first login with no SaftUI settings; offered again from `/sui`).

**Settled 2026-11-14:** the owner builds each unit frame layout in game as a unit frame profile, and it is migrated from the game's saved settings (SaftUI's SavedVariables in the WTF folder) into built-in defaults that ship with the addon. "yep I'd build them myself in game and you can just migrate the settings from the wtf folder to actual defaults". When migrating, only the settings go into the repo: no account, realm or character names from the file or its path.

**Open questions:** How a shipped layout is stored and named (data files under `SaftUI-Unitframes/config/`, listed beside the player's own profiles and not editable in place?), and how one is refreshed when the owner changes it. Whether existing players see it after the update or only fresh installs. Whether it is per account or per character. What else belongs in it (action bar layout, bags view, the tracker switch).

### 2026-11-14 — /sui at half with the sidebar collapsed: a validation error is cut or hidden in the footer

**What:** With the sidebar collapsed at half width (W4), the footer's status line, where a validation error such as "Size: a number, please" shows, has a region about 54 wide under Thick and Thin (96 under Blizzard), so the message is cut after two lines, and with one more icon command registered the region is 22, under `FOOTER_MIN_ROOM` (24), so the status line is hidden and no message shows anywhere. The page's field then keeps only the typed text.

**Why noticed:** Review of the footer's collapsed tools (window sizes work, Task 6). The plan's Ruling 7 expected about 65 wide and a wrapped status line; the real room is smaller because Search, Edit mode, the toggle and the "More" button are the floor and take the footer. The task's report had said errors still show in the field itself, which they don't: the field shows the typed text, not the error (`optionswidgets.lua`, the field's validation path).

**Anchors:** `SaftUI-Core/Config/optionswindow.lua` (`PlaceFooter`, `FOOTER_MIN_ROOM`, the status line), `SaftUI-Core/Config/optionsnav.lua` (`S.DrawTools`), `SaftUI-Core/Config/optionswidgets.lua` (a field's error), `tests/core/options_footer_tools_test.lua`, `tests/core/options_sidebar_test.lua` (the footer never overlaps).

**What's been considered:** Show the error in the field's tooltip, or on a line over the footer (or over the page's bottom) while the footer's region is short; or let the status line borrow the room of the tools that follow Reload UI. None is built. The owner's rule that nothing overlaps (the footer's tools stop short of Reload UI) means the status line can only give way, so the message needs another place.

**Shape of work:** A small design pass on where an error shows when the region is short (a tooltip on the field is the smallest), then a change in `PlaceFooter` or the field plus a test at W4 with the real command set and with one more icon command.

**Open questions:** Where should the message show when the footer has no room: the field's tooltip, a line over the footer, or both? An in-game check at W4 with Keybind mode only (54 wide) decides how often it matters.

### 2026-11-14 — Categories tab at full size: a long "Reset <name> to default" overlaps Delete

**What:** In the bags' Categories editor, the Reset button's label is `Reset <category name> to default`. For a long name the button is wider than its half-line slot and overlaps Delete beside it. The shipped default "Death Knight/Warlock/Demon Hunter" does it, and so does any default the player renames to a long name (renaming keeps the Reset row).

**Why noticed:** Review of the Categories tab at half width (window sizes work, Task 8). At half the label was shortened to "Reset to default" (the button above the editor names the category), but full size was left as it was, to keep it unchanged. Measured at full: under Thick the label is 375 wide in a 264 slot and spills about 55 px over Delete (which spans 276..540); under Blizzard the 403 wide button sits over Delete (290..370). The parent commit of that task (`7cc5acb`) behaves the same, so it isn't a regression.

**Anchors:** `SaftUI-Bags/categoriestab.lua` (`INV:CategoryEditorOptions`, `args.reset`), `SaftUI-Core/Config/optionsbody.lua` (a floating line's buttons fill their slots, `Body:ButtonSlotRect`), `tests/bags/categories_half_test.lua` (the half-width case).

**What's been considered:** Use the same short label at full (the editor's Name box above already shows the category). Or let the body cap a shared-slot button's label to its slot with an ellipsis. Either changes full size, so it is the owner's call.

**Shape of work:** One-line label change plus a test, or a small body change for the cap.

**Open questions:** Short label at full too, or keep the name and truncate?

### 2026-11-14 — Copy from writes default tables into keys the source unit doesn't have

**What:** Unit frames' Copy from lists the destination unit's settings, but the source unit may not have them. Reading a key the source lacks gives AceDB's `['**']` default (a fresh table), so the copy writes that junk table onto the destination and also creates the key on the source.

**Why noticed:** Reviewing Task 7 of the edit mode bar plan (Copy from as one undoable step). The reviewer's probe: "Copy to Party from Target" with Layout ticked, `spacing` and `growthDirection` ticked, put `number`/`string` values on Party's side as old and element-default tables as new, and made `target.spacing` appear. Pre-existing behaviour of Copy from, not caused by the history work (Undo now restores the destination exactly, but the source keeps the created keys).

**Anchors:** `SaftUI-Unitframes/config/config.lua` (`UF:CopySettings`, `UF:OpenCopyTable`, `CopyNames`); `SaftUI-Unitframes/config/default.lua` (the `['**']` defaults at unit level); `tests/unitframes/copy_from_history_test.lua`.

**What's been considered:** Offering only keys both units have (the dialog already lists only parts the destination's page names), or skipping a key whose source value is not stored (`rawget` nil) so nothing is written.

**Shape of work:** small change in `UF:CopySettings` and the dialog's list, plus a test per case (a group unit as destination, a single unit as source).

**Open questions:** whether a key the source never stored should copy the source's default (what the player sees there) or be left alone.

### 2026-11-13 — Design decisions waiting to be built

**What:** The design system's Decisions page (`docs/design-system/05-decisions.md`) records choices the owner has made that no task has built yet. This entry is the list, so none is lost between sessions. Each line names its decision number there.

**Why noticed:** The design system was written on 2026-11-13 and the owner answered its questions the same day, faster than the work could be queued.

**Anchors:** `docs/design-system/05-decisions.md`, `10-discrepancies.md`, `25-colour-roles.md`, `30-code-changes.md`.

**Not yet built, with no task running:**

- 1: the options window's controls' lines follow the theme's, and the in-world close button is drawn in its window's theme. 2: built for the config windows (the `/sui` window, edit mode's bar and History list and the small dialogs follow the theme's Background, with Global settings > Theme > Options windows to turn it off, 2026-11-14; decision 44); what remains of 2 is checking that every other panel follows the theme's Background and nothing is left drawn solid by mistake.
- 3: every colour-plus-opacity pair becomes one colour control (the pairs still need listing).
- 4, 19: one button component at one size and font; the close button and the window's small buttons the same height as buttons, icons centred.
- 7: the accent as a theme colour with its own swatch; "on" drawn in the accent everywhere (the edit mode bar's plan covers its own toggles).
- 8: `/sui` tooltips' descriptions in the normal text colour, not Blizzard's gold.
- 14: hue-named colours renamed by role (waiting on the owner's answers on the Colour roles page), with a migration.
- 21: the docs spell "color".
- 22: SaftUI's font on every line of item and compare tooltips (find why they show Blizzard's).
- 24: a written spacing scale, and unexplained values moved onto it.
- The loot feed's and other hand-drawn glyphs still to become Lucide icons (the audit's list).
- Remaining section Reset buttons (bags' Categories "Reset ... to default" and "Reset all").

**Being built or planned elsewhere:** 5, 15, 31 to 33 (the edit mode bar: `docs/superpowers/specs/2026-11-13-saftui-edit-mode-bar-design.md`); 9, 13, 17 (the colour control as a field, Copy from beside the Unit dropdown: branch `fb-kit2`); 11, 12 (scaling and the small-text font: their own followup); 25 (overlapping mover labels: in the edit mode bar's plan).

**Shape of work:** Several small tasks (20, 21, 28, 29, 30, 8, 22 are each small) and two projects (the theme-following options window with the accent and one button; the colour roles rename). Group the small ones into one or two passes.

### 2026-11-13 — Objective tracker skin: in-game checks and what was left out

**What:** SaftUI now skins Blizzard's objective tracker and moves it in `/sui edit` (merged into `modular` at 89cf68a; the user: "can we look at skinning the blizzard objective tracker?", "definitely want it movable at least with /sui edit"). It was built and reviewed three times on stubs and has never run in game. This entry is its in-game checks and the parts left for later.

**Why noticed:** The task's reports and reviews (2026-11-13). The tracker is easy to break in combat: a layout that runs tainted makes the quest item buttons it creates tainted for the session, and using an item in combat is then blocked.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua` (the skin), `Blizzard_ObjectiveTrackerPosition.lua` (the mover: `OTP:PlaceTracker`, `OTP:CapturePosition`, `OTP:KeepPlacement`), `.agents/taint.md` rule 5, `tests/misc/objective_tracker_*_test.lua` and `tests/misc/fixtures/objective_tracker.lua`.

**In-game checks (Forever), most important first:**

1. `/console taintLog 1`, `/reload`. With no quest item shown yet: switch the theme Thick, Blizzard, Thick; change the tracker's font in `/sui`; drag the tracker in `/sui edit`. Then, in combat, accept or track a quest with an item, and use the item in combat. No "Interface action failed"; `Logs/taint.log` has no "blocked" line and nothing tainted by SaftUI naming `dirty`, `charges`, `rangeTimer`, `OnClick` or an `ObjectiveTracker` field.
2. `/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"GetBlock"),issecurevariable(ObjectiveTrackerFrame,"SetPoint"))` prints `true true true`, also after a drag, a theme switch and a dungeon.
3. The look, out of combat: headers with no banners and a thin line; titles and objectives in SaftUI's font with no overlapping lines; collapse buttons as small boxes with a chevron that flips; a scenario or dungeon's progress bar flat with SaftUI's border; a quest item button square with SaftUI's border and a blue hover.
4. `/sui edit`: the "Objective Tracker" outline sits on the tracker's header; drag it, `/reload`, it stays. Blizzard's Edit Mode shows no box for the tracker; saving a layout there doesn't move it. A tracker moved in Blizzard's Edit Mode before this build stays where it was on first load.
5. Theme to Blizzard: exactly Blizzard's look; back to Thick with no reload. Skinning > Objective tracker off: Blizzard's look at once, and still movable.
6. Whether frames Blizzard stacks above the tracker in its right column (the durability figure, vehicle seats, widgets under the minimap) draw over its header now that its top is pinned.
7. After a dungeon run, BugGrabber has nothing from SaftUI.

**Seen in game 2026-11-13:** the owner: "Objective tracker skin is looking good". No report yet on the quest item in combat (check 1).

**Asked for next (the owner, 2026-11-13):** "I'll probably want some additional enhancements like zone grouping, objective status coloring, is it possible to set a max height and a scroll frame on it? I'd also love the mover to fill the full height of the tracker not just the header."
- ~~*The mover filling the tracker's height*~~ **Built 2026-11-13** (`OTP:UpdateFootprint`): in edit mode the outline is as tall as the tracker, from the holder's top; the holder and what is saved are unchanged.
- ~~*Objective status colouring*~~ **Built 2026-11-13** (completed and failed lines): two colours on the tracker's page, Objective colors (Completed default Blizzard's dim green, Failed the text red). In-game: a failed line shows Blizzard's brighter red while hovered; "in progress" keeps Blizzard's normal color, as there is no third state to colour.
- *Zone grouping:* Blizzard's tracker groups by module (Quests, Campaign, ...), not zone. Regrouping its blocks means changing its layout, which the skin never does today (taint: a tainted layout makes the quest item buttons it creates tainted). Needs a design and a taint study; it may only be safe as a SaftUI-drawn list beside or in place of Blizzard's.
- *A max height and a scroll frame:* the same hazard. Blizzard already limits the tracker's height (its Edit Mode Height) and collapses modules that don't fit; putting its container in a scroll frame means re-parenting or sizing it from addon code. To be studied with zone grouping.

**Left out, for later:** a Height setting (sizing the tracker from addon code may taint its layout; only the game can show whether it is safe) and Blizzard's Opacity and Text Size, which SaftUI's edit mode now hides; the large art panels (auto quest popups, the scenario stage, challenge mode and proving grounds banners), the bars' round reward icon, the map pin and find group buttons; standing down for another tracker addon; a default spot clear of SaftUI's minimap and experience bars.

**Shape of work:** The checks first. Then small tasks as the user asks for them; the art panels need a design pass.

### 2026-11-13 — Scale SaftUI across resolutions and stay pixel perfect

**What:** SaftUI sets UIParent's scale to 768 over the screen's physical height, so one unit is one physical pixel on every display. Sizes are therefore in pixels: a 45 button is 45 pixels whether the screen is 1080, 1440 or 2160 tall. The user tuned their sizes on a 1440p monitor, so the UI is large on 1080p and tiny on 4K and Retina displays. Wanted: the UI scales with the display and stays pixel perfect.

**Why noticed:** The user, 2026-11-13: "Another thing I'd like to look at is being able to scale saft UI to work well across different resolutions and maintain pixel perfection. since I've configured the sizing to make sense on a 1440p monitor things look blown up on a 1080 monitor and tiny on higher resolution monitors like mac retina displays or 4k monitors".

**Anchors:** `SaftUI-Core/constants.lua` (`st.scale = 768/st.screenHeight`), `SaftUI-Core/init.lua` (`UIParent:SetScale(st.scale)`), `SaftUI-Core/api.lua` (`st:GetPixelSize`, `st:RoundToPixel`), every `edgeSize = 1`, 1-unit line and inset in the code (they assume a unit is a pixel; the options body's hairlines and dividers say so), `SaftUI-Unitframes/nameplates/pixels.lua`, the README's Installation section; related: [UIParent's scale is set once, at login](#2026-11-11--uiparents-scale-is-set-once-at-login-so-plates-leave-whole-pixels-after-a-ui-scale-or-display-change).

**What's been considered:** Not yet discussed with the user beyond the request. The shape of the problem:

- A scale factor k on top of today's scale (UIParent at 768/height times k): k = height/1440 makes a layout take the same share of any screen (0.75 at 1080p, 1.5 at 4K), or the user picks k.
- With k not 1 a unit is k pixels, so "1" is no longer one pixel: every border, hairline, inset and gap written as 1 must become "one pixel" (1/k units, `st:GetPixelSize`) or a whole number of pixels, and every size and offset must be rounded to whole pixels (`st:RoundToPixel` exists and the bars and plates already use it; most of the code does not).
- Whole-number k (2 on 4K and Retina) needs none of that and is crisp today's way, with 2-pixel borders; it can't serve 1080p (0.75).
- Whether borders stay one pixel at every scale (thin on 4K) or grow with k rounded to whole pixels (2 at 4K) is a look decision.
- Fonts scale with k; the pixel fonts (Pixel, Pixel Med) are only crisp at whole multiples of their design size.
- Saved positions are in units, so they keep their place relative to the screen when k follows the height; a profile shared between machines would then look alike on each. Width differs by aspect ratio (ultrawide), which k doesn't address.
- The scale is set once at login (the linked followup); a display change needs it set again.

**Shape of work:** A project: a design round with the user (automatic or chosen scale, border thickness, pixel fonts, per-machine or per-profile), then an audit of every place that assumes a unit is a pixel, a "one pixel" token and rounding helpers used everywhere (this meets the design system's tokens table), and in-game checks at 1080p, 1440p and 4K. Best done after the design system's tokens and spacing are in code, since that work touches the same constants.

**Decided so far (2026-11-13):** The user plays at 1440p; the problem is their friends': "I have friends who play at different resolutions including 1080p and 3456x2234 (mac) that are having scaling issues I'd like to resolve for them". So it must work on the addon's defaults with no setup. Proposed and accepted ("I like that fix, lets do that"): the scale is automatic, the screen's height over 1440 (0.75 at 1080p, about 1.55 on that Mac), with a "UI size" slider in Global Settings to override it; borders are whole pixels, the scale rounded to a whole number and never under 1 (1 at 1080p and 1440p, 2 on the Mac); every size and position rounded to whole pixels.

**Fonts:** The user: "I almost wonder if this would be a good time to move away from pixel fonts anyways, maybe we can find a non pixel font that looks good at smaller sizes, agency fb is a great font but looks a bit rough when really small". A shortlist of free condensed faces is mocked up at every place the Pixel font is used (`.superpowers/brainstorm/46409-1794604463/content/small-fonts-v1.html`); the two or three the user likes get tried in game at each scale before one is chosen. This joins the font roles followup ("Fonts: separate the fonts users pick per kind of text from SaftUI's internal font objects").

**Open questions:** Which small-text face. Whether Agency FB stays for labels. The Mac's taller aspect ratio (less width than 16:9).

### 2026-11-13 — Bags: a general sort order of draggable blocks, with a per-category override

**What:** Bag sorting should be richer: one general sort order, built from blocks the user drags into order (as the category rules are), and each bag category able to override it with a sort order of its own.

**Why noticed:** The user, 2026-11-13, while the action bars' shared settings were being designed: "once this is done I want to talk about beefing up bag sorting functionality, similarly to the action bar I think we should have a general sorting order that can be modified using dragable blocks, and each category can override the sort order with a different one". "Similarly to the action bar" means the shared-with-override model: a general value everything follows, and a part that can own its own (`docs/superpowers/specs/2026-11-13-saftui-actionbars-shared-settings-design.md`).

**Anchors:** `SaftUI-Bags/layout.lua` and `container.lua` (where items are ordered today), `categories.lua`, `categoriestab.lua`, `ruleeditor.lua` and `dragparts.lua` (the Categories tab and the drag handle, ghost and drop line to reuse), `rules.lua` (the block rules).

**Shape of work:** A design round with the user first (they asked to talk about it): which sort keys exist (quality, item level, name, type, count, recency, ...), ascending or descending per block, where the general order is edited, how a category shows that it overrides. Then a spec and plan. The own/shared marks and menu items the action bars work adds to Core's options kit may fit.

**Open questions:** All of the above; not yet discussed. Start it once the action bars' shared settings are built.

### 2026-11-13 — Unit frames: shared settings across units, and small parts as menu items

**What:** The action bars' shared-settings model (an "All" entry, own marks, the diff icon, "Apply to: All | Multiple") applied across unit frames, and a unit's texts, icons and small parts drawn as one-line menu items on its General page, cutting Player's tabs from about thirteen to five.

**Why noticed:** The user, 2026-11-13: the Apply to idea "is widely used for options across the action bars (we could also use it elsewhere, like a lot of unit frames changes)", and of the unit frame mockup: "the unitframe change is great". They asked to see the menu with the full unit frame position block (the TO dropdown) "to make sure that's also planned out"; it fits a 400 wide menu (the block is 351 wide).

**Anchors:** `.superpowers/brainstorm/46409-1794604463/content/actionbars-shared-v4.html` (part 2, the mockup), `docs/superpowers/specs/2026-11-13-saftui-actionbars-shared-settings-design.md` ("Later"), `SaftUI-Unitframes/config/`, `SaftUI-Core/Config/optionsposition.lua`.

**Shape of work:** A project of its own, after the action bars prove the kit pieces. Health, Power, Cast bar and Auras keep tabs. Needs its own design round: what "All units" means when units differ so much by default, and whether sharing is per unit group (party and raid) instead.

### 2026-11-13 — Character frame slots: SaftUI writes fields onto Blizzard's buttons

**What:** The character frame's skin calls `Util:SetItemQuality` and `Util:ClearItemQuality` on Blizzard's equipment slot buttons. Those helpers write fields onto the button (`alwaysShowProfessionsQuality`, `isProfessionItem`, `professionQualityOverlayOverride`, and a `qualityText` font string stored on it) and run Blizzard's `SetItemCraftingQualityOverlay`, `SetItemCraftingQualityOverlayOverride` and `ClearItemCraftingQualityOverlay` on it. That breaks `.agents/taint.md`'s rules 1 (write nothing onto a Blizzard frame) and 3 (don't run Blizzard's functions on its frames from addon code). The same helpers are fine on SaftUI's own bag slots and loot feed items.

**Why noticed:** The reviewer of the character frame's item level change (branch `fb-ilvl`, merged 58a646a, 2026-11-13). It was there before that change and was left alone as out of scope.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua` (the two calls, in the slot update); `SaftUI-Core/Utilities/itemupgrades.lua` (`Util:SetItemQuality`, `Util:ClearItemQuality`, `Util:SetItemUpgradeQuality`, `Util:SetItemQualityLevelText`); other callers `SaftUI-Bags/slot.lua` and `SaftUI-Loot/Feed/feed.lua` (SaftUI's own frames); `.agents/taint.md`.

**What's been considered:** No error has been traced to it. The equipment slots are secure buttons used in combat (swapping a weapon), so a tainted field on one is the kind of thing that ends in `ADDON_ACTION_BLOCKED`. The item level text beside it already shows the pattern to follow: SaftUI's own frame over the slot, with its state kept in a table keyed by the button.

**Shape of work:** Small: draw the upgrade tier and the crafting quality on a SaftUI overlay per slot, keep the state in the skin's own table, and stop calling the helpers on Blizzard's buttons. Tests beside the item level's (`tests/misc/`). An in-game check that the tier icon and the level text still show.

### 2026-11-13 — Loot rolls: the roll bar doesn't hold after a choice

**What:** After a choice on a group loot roll, SaftUI should show its own bar in Blizzard's place, locked on the choice, until the roll ends (the held rolls feature, built 2026-11-10). In game it doesn't: the user reports the bars "don't seem to be staying up after selecting a choice" (Forever, the night of 2026-11-12).

**Why noticed:** Step 32 of the cleanup's in-game checks. The feature was built from Blizzard's source and has never been seen working in game ([Loot rolls: confirm the client assumptions in game](#2026-11-08--loot-rolls-confirm-the-client-assumptions-in-game)), so it may never have worked there.

**Anchors:** `SaftUI-Loot/rollinfo.lua` (`OnRollChosen`, the `RollOnLoot` post-hook that notes the choice; `OnBarHide`, which calls `LT:HoldRoll`; `LT:UpdateRollBars`, which releases a held bar whose drop isn't open); `SaftUI-Loot/roll.lua` (`LT:HoldRoll`, `LT:ReleaseHeldRoll`, `LT:UpdateHeldRolls`); `SaftUI-Loot/Feed/loothistory.lua` (`LT:GetOpenDrops`, `HasEnded`, `RollTimeOver`); `tests/loot/roll_held_test.lua` (19 tests, all passing on stubs); Forever's `Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua` and `.xml`.

**What's been considered:** A read of the code against Forever's source (2026-11-13) found no cause:

- The cleanup didn't change the logic. 81bf0b4 swapped Loot's local plain-value helpers for Core's (`st.PlainNumber`, the same test), and the other commits only moved code between files. `LT.PlainNumber` is set before anything runs.
- Blizzard's source matches what the code assumes: a roll button's click calls `RollOnLoot(rollID, rollType)`; `CANCEL_LOOT_ROLL` leads to `GroupLootFrame_Remove`, `GroupLootContainer_RemoveFrame` and `frame:Hide()`, which is where `OnBarHide` runs; a main spec Need plays its dice for 5 seconds first.
- The timer's values are plain: the timer draws in game.

What's left needs evidence from the game. In the order they'd be checked:

1. An error inside `LT:HoldRoll` or `OnBarHide`. It would be in BugGrabber's log.
2. The held bar is shown and released at once, because its drop isn't in `LT:GetOpenDrops()` when `LT:UpdateRollBars` runs right after the hide. That is by design when everyone else has already chosen (the roll is over). Otherwise `HasEnded` or `RollTimeOver` reads Forever's drop wrongly (the units of `startTime` and `duration`, or `winner` being a table before the roll ends).
3. `chosen[rollID]` is never set: the frame's `rollID` or the timer's values aren't plain at the click, or the click doesn't go through the global `RollOnLoot`.
4. `LT:HoldRoll` returns early: `skins[frame].shown` is missing or for another roll, or under a second is left.
5. The bar is up, but off screen or behind something.

**Shape of work:** Evidence first: BugGrabber's log for Loot errors, and what the user saw (which button, whether others were still rolling, whether the bar went at once or after a Need's dice). If that doesn't settle it, a debug print at each decision in the list above, off by default, for the next group run. Then a failing test and a small fix.

**Open questions:** Was anyone else still rolling when the bar went? If not, the bar going is the design, and the question becomes whether a finished roll should hold for a moment to show its result.

**In game 2026-11-13:** BugGrabber's log has no Loot error, so cause 1 is out. The user: "I was pressing greed, it went away as soon as I clicked. It could very well be that I was the last one to roll, I wasn't paying much attention." That fits cause 2's by-design case: the last to choose, so the roll resolved at the click and the held bar was released in the same update.

**Decided 2026-11-13:** The user: "I like the hold for a finished roll, we can hold it for a few seconds and fade out after. the debug print is a good idea, lets add that as well." Being built on branch `fb-rollhold`: a held bar that finishes (its drop resolved, or its time ran out) stays 3 seconds, locked on the choice with its final counts, fades over half a second, then goes; and `/sui debug` turns on `st:Debug('Loot', ...)` lines at each decision in the list above, for the next group run. The 3 seconds and the half second are the builder's numbers, not the user's. This entry stays Active until the held bar has been seen in game with others still rolling.

**Merged 2026-11-13 (7c2ab54):** built and reviewed, with one fix round. Beyond the above, a finished bar keeps showing later results for the drop it finished on (counts and tooltip only), so a roll that times out can show its auto-passes and winner before it fades. The finish line under `/sui debug` reads `held roll finished: <id> <why> waiting <n> <winner | all passed | no winner | no summary>`: a `winner` with others still waiting, a second or two after your click, means Forever's drop fields are misread (cause 2 above). Not yet seen in game.

### 2026-11-13 — Test mode: choose which elements the previews show

**What:** Let Test mode show or hide each kind of element on its preview frames: buffs, debuffs, raid markers and so on. Today a group's Test mode (`/sui` → Unitframes → Party, Raid 10, Raid 40 or Boss → Layout → Test mode) draws a fixed set: size, theme, health and power bars, name, role corner and range alpha. It draws no auras, castbars, portraits, raid targets, ready checks or leader icons, so those can't be placed or sized without a real group.

**Why noticed:** The user, after checking the group previews in game (step 7 of the cleanup's in-game checks, 2026-11-13): "Looks good, but can we geet a follow up to improve test mode by being able to show/hide certain elements in test mode? I'm thinking about being able to toggle testing buffs, debuffs, raid markers, etc."

**Anchors:** `SaftUI-Unitframes/grouppreview.lua` (the previews; its header comment lists what is and isn't drawn; `UF:SetGroupTestMode`, `UF.testGroups`, `UF.previews`); `SaftUI-Unitframes/config/groupoptions.lua` (`test_mode`); the element files in `SaftUI-Unitframes/elements/`; `tests/unitframes/` (the group preview tests).

**What's been considered:** The previews are SaftUI's own plain frames, built from the element helpers with made-up data. No unit is faked, so nothing secure is touched and they work in combat. Adding an element means giving the preview that element's frames and made-up data for it: a few sample buffs and debuffs with durations and stacks (a dispellable and a purgeable one, to see the filters' borders), a raid marker on some members, a cast in progress, a ready check, a leader. The single unit frames (player, target, focus, pet) have no Test mode at all; whether they should get one is part of the same question.

**Shape of work:** A design pass first: which elements, whether the choice is one list of checkboxes beside Test mode or per element, whether it's saved in the profile or lasts until `/reload` like Test mode itself, and whether the single frames get previews. Then likely two or three tasks: preview data and frames per element, the options, and tests.

**Open questions:** The ones in the design pass above. Should the sample auras follow each aura group's real filter, or always show?

### 2026-11-13 — Unit frame profiles are hard to find in /sui

**What:** The unit frame profiles (New, Copy, Rename, Export, Import, Delete) are in `/sui` → Unitframes as the last entry, "Profile", of the Unit dropdown, under every unit. Nothing on the page says so, and the user looked for them and didn't find them.

**Why noticed:** Step 6 of the cleanup's in-game checks (2026-11-13). The user: "I actually don't see the unitframes profile optoin anywhere, did that get missed when moving to the new GUI?" It wasn't missed: `UF:GetConfigTable` (`SaftUI-Unitframes/config/config.lua`) adds `profile = UF.GenerateProfileConfigGroup()` to the page's groups, the page is `childGroups = 'select'` with `pickerLabel = 'Unit'`, and the group's order (-99) puts it at the end of the list.

**Anchors:** `SaftUI-Unitframes/config/config.lua` (`UF:GetConfigTable`), `SaftUI-Unitframes/config/profiles.lua` (`UF.GenerateProfileConfigGroup`), `SaftUI-Core/Config/optionsnav.lua` and `optionsselect.lua` (the picker); the sidebar's own Profiles page (the AceDB profiles, a different thing).

**What's been considered:** Three places it could go: (a) a "Unit frame profile" dropdown at the top of the Unitframes page, beside Unit, with a button that opens the manage page; (b) first in the Unit dropdown, set apart from the units; (c) a section of the sidebar's Profiles page, next to SaftUI's own profiles. (a) is the most visible and says which profile is being edited.

**Shape of work:** Small once chosen: one options change and its tests.

**Open questions:** Which of the three, or another.

**Mocked 2026-11-13:** Drawn on the real window for the user to pick from. Round 1: A, a "Unit frame profile" dropdown and Manage button on the Unit row; B, the same in the title row; C, first in the Unit dropdown, set apart; D, a section of the sidebar's Profiles page. The user then asked whether A sat where search is (it didn't: search is at the right end of the first tab line, `SEARCH_WIDTH` in `SaftUI-Core/Config/optionswindow.lua`), and proposed moving search: "the search might be better suited above the editmode and keybind mode buttons on the left. With that change lets see what the profile item looks like where search is currently positioned, but lets also get an option where the unit profile is centered on the footer." Round 2, both with search moved into the sidebar above Edit mode and Keybind mode: E, the profile control where search is today (it is wider than the search box, so the first tab line holds fewer tabs: Unitframes' 13 tabs wrap 4, 7, 2 instead of 9, 4); F, the control centred in the footer between Reload UI and Close, drawn only while the Unitframes page is open (the builder's assumption).

**Decided 2026-11-13:** The user chose F: "Lets go with F for the unit frame profiles and search bar position, looks good". Being built on branch `fb-profile`: search moves into the sidebar above the Edit mode and Keybind mode buttons; the Unitframes page declares a footer control (label, dropdown, a Manage button that opens the profile actions in the window's small dialog) through a SaftUI-only field on its option group, so Core doesn't know about Unitframes; "Profile" leaves the Unit dropdown. The builder's rulings, not the user's: the control is centred while that keeps it clear of edit mode's footer buttons, otherwise it sits beside Close and drops its label first; the status line stops short of it. This entry stays Active until it is seen in game.

**Merged 2026-11-13 (aea1cdf):** built, reviewed (all PASS) and given one fix round. The page declares the control through a `footer` group on its option table. While the status line shows an error, the control drops its label and moves beside Close, and hides if edit mode's buttons still leave the error no room (the builder's call: an error to read beats the control's place). The footer's dropdown and Manage have tooltips; a search result for them opens Unitframes without changing its unit or tab. To check in game: the gap between edit mode's "+" and the footer dropdown under Thick or Thin (the dropdown could narrow from 170 if they touch); the search box under Blizzard leaves about 47px to its right (widening it means working out both it and the command buttons from the sidebar's width).

### 2026-11-13 — Colour swatches read as checkboxes, and the colour picker

**What:** Two things about colours in `/sui`. The colour swatches are small squares that are hard to tell from checkboxes. And the colour picker is Blizzard's, unskinned, without the opacity and RGB values the user wants.

**Why noticed:** The user's in-game pass (2026-11-13): "can we explore different visuals for the color swatches? it can be difficult to differentiate them from checkboxes sometimes, maybe we can make them larger with the text inside of it or something? I'd also like to skin the color picker and enhance it with opacity and rgb values."

**Anchors:** `SaftUI-Core/Config/optionswidgets.lua` and `optionstypes.lua` (the `color` option's widget and the checkbox beside it); `ColorPickerFrame` (Blizzard's; `Blizzard_ColorPickerFrame` on both clients); `SaftUI-Misc/Skinning/blizzard/` (where a Blizzard frame's skin goes); `.agents/taint.md`.

**What's been considered:** For the swatch, the user's own idea: a wider swatch with the option's name written inside it. Others to draw: a wide bar the width of a dropdown, a swatch with a hex value beside it, a round swatch. For the picker: skin Blizzard's frame (backdrop, buttons, edit boxes), and add what it lacks: number boxes for red, green and blue, a hex box, and an opacity slider with its value. Retail's picker already has a hex box and an alpha slider; Forever's has to be read first.

**Shape of work:** A design round with mockups of the swatch options for the user to pick from, then two tasks: the swatch in Core's options kit, and the picker's skin and additions in Misc's Skinning (a taint review, since the picker is Blizzard's and is shared with other addons).

**Open questions:** Which swatch look. Whether the picker's additions are SaftUI's own controls on Blizzard's frame, or a SaftUI picker of its own that replaces it.

**Mocked and decided 2026-11-13:** Forever's picker was read: it already has an opacity strip and a hex box; it lacks number boxes for red, green and blue and a number for opacity, and it is unskinned. Swatches drawn: today's 22px square; A, a bar as wide as a dropdown with the colour's hex code written in it, and its opacity when it has one (the code is for reading; a click opens the picker); B, a wider chip with a hex box you can type into; C, the option's name inside the colour; D, a circle. **The user chose A** ("Lets go with A for the color choice"). Pickers drawn: P1, Blizzard's frame in SaftUI's look with nothing added; P2, the same, a little wider, with boxes for red, green, blue and opacity (SaftUI controls on a frame Blizzard and other addons share, so the usual taint care); P3, a picker of SaftUI's own that only `/sui` opens. P2 is the builder's recommendation; the user hasn't picked. Swatch A merged into `modular` 2026-11-13 (d2794fb): the bar is as wide and tall as a dropdown (170 by 24), the code is `#RRGGBB`, black or white by the brightness of what's drawn (luma times opacity over a half), with `· 60%` after it when the option has opacity under 100%. Colour rows are now half-line rows (two to a line, not four), so Global Settings → Colors grows from 23 lines to 42; the review found no in-keeping way to fit more at this window's width (the body has only quarter, half and full cells). Not yet seen in game. The picker (P1 to P3) still waits on the user.

### 2026-11-13 — Codebase cleanup: small things left over

**What:** Small things the cleanup's workers and reviewers noticed and set aside, because they were outside the task in hand, needed a call, or needed a look in game. None changes what the user sees unless its line says so. The items that need the user's decision are in [Codebase cleanup: the items waiting on a decision](#2026-11-12--codebase-cleanup-the-items-waiting-on-a-decision), not here.

**Why noticed:** The reviews of the cleanup's 21 tasks and five waves (2026-11-12). They were kept in the run's ledger, which is not versioned, so this entry is their only record.

**Anchors:** Each item names its file. The plan is `docs/superpowers/plans/2026-11-12-saftui-cleanup.md`; the report is `docs/reports/2026-11-12-codebase-cleanup-analysis.md`.

**What's been considered:**

*Tests*
- The nameplate tests copy the whole defaults table for each case; a cheaper `copy_defaults` would speed them up. Test timings were measured across two filesystems and should be measured again on one before anyone tunes them.
- `st:OnBlizzardAddon` (`SaftUI-Core/api.lua`) keeps its waiting list across test cases; the harness has no reset for it.
- `SaftUI-Loot/rollinfo.lua` has two `if not PlainNumber then return end` guards that exist only because `tests/loot/roll_skin_test.lua` loads `rollinfo.lua` without `Feed/rolls.lua`. Load both in the test and the guards can go.
- `st:RoundToPixel`: the tests' locked stub could raise stricter errors (and string offsets could be an error).
- `tests/core/options_kit_test.lua`'s 'redefining a built-in type is an error' keeps a fixed list of ten types, which a new built-in type won't join by itself.
- A test that loads one file of a split set by path runs the addon with part of its code. A drift check for that was parked: it needs a change to the harness.
- `tests/unitframes/secret_texts_test.lua` is still on its own setup, not the shared helpers. The cleanup left it unopened, because its name falls under the user's rule about files named `secret`. The user cleared it and `tests/lib/secrets.lua` on 2026-11-13 (they test against Blizzard's secret values and hold no credentials), so it can be moved onto the shared helpers like the rest.
- The split options and categories tests each carry their own copies of small readers (`rgba`, `size_of`, `yes`/`no`, `cell`, `same_rgb`, `inside`, `shown_textures`, `atlases_of`, `coords_of`, `corners`); the four-line load sequence for the options window is repeated in twelve files; `tests/core/options_frames_pages_test.lua` has its own copy of `INV.IndexOf`.
- `tests/lib/theme_helpers.lua`: `T.check_theme_page` covers 7 pages and could cover the rest; `T.round_trip` has one caller and a `switch` parameter nothing uses.
- `tests/misc/restedxp_fixes_test.lua` is named after a review wave, not after what it tests.
- The `theme_blizzard_*_test.lua` files' "Real:" headers name `themeart.lua` but not `themeart_data.lua`, which they also load.

*Code*
- Nil guards: `HideBlizzardClock` (`SaftUI-Minimap/clockbutton.lua`) uses `TimeManagerClockButton` unguarded, and `BF:SkinFrames` (`SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFrame.lua`) does the same with Blizzard's buff frames. Neither has raised an error.
- Should the action bars' skin anchor a button's `Flash` to its icon, as `SaftUI-Misc/totemskin.lua` does? That would change what the user sees, so it wasn't done.
- `st:SkinCooldown` (`SaftUI-Core/skinning.lua`) makes a FontString and stores it as `cooldown.text`, a field on what is often Blizzard's cooldown, though its comment says nothing is written onto the cooldown. Whether anything reads `cooldown.text` is not verified; if nothing does, both the FontString and the write can go.
- The nameplate subtext's `'updated'` callback (`SaftUI-Unitframes/nameplates/subtext.lua`) calls `frame:UpdateTags()` on every plate it knows, including one the game has taken away. Harmless so far.
- `SaftUI-Unitframes/nameplates/target.lua`'s comment says the `nameplatetarget` art is in `themeart.lua`; it is in `themeart_data.lua`.

*Copies left apart, because they differ*
- Chat: the local `KeepHidden` (`SaftUI-Chat/chatframe.lua`, one caller) stays local; the edit box setup, which uses `st:SkinEditBox` in one place and `st:StyleEditBox` in another.
- Bags: `WINDOW_NAMES` (`categoriestab.lua`) and `INV.windowLabels` (`movers.lua`) differ in casing; the bank's open and close bodies; the two warband money updaters' guards; `INV.IndexOf` (`inventory.lua`) kept the views copy's nil guard.
- `FIELD_HEIGHT` is 22 in `SaftUI-Bags/ruleeditor.lua` and 24 in `SaftUI-Core/Config/optionswidgets.lua`.
- Key catching: `optionskeybinding.lua`'s key handler and EditMode's mover catcher stand beside `Kit.CatchKeys` (`SaftUI-Core/Config/optionsdialog.lua`).
- Unit frames: health's own `PostUpdateColor`, which adds the nameplate threat tint, beside `UF.PostUpdatePowerColor` (`updaters.lua`); the private `ResolveTarget` in `SaftUI-Unitframes/config/position.lua`, kept on purpose, with a comment to keep it in step with `SaftUI-Core/Config/generators.lua`.

*Renames not done*
- The Utilities module, which Bags (`slot.lua`), Loot (`Feed/feed.lua`), Misc (`characterframe.lua`) and six tests reach by name.
- The `ItemQuality` names in `SaftUI-Core/Utilities/itemupgrades.lua`.

*The report itself*
- Section 4.1 calls `optionsbar.lua` "the button bar"; it is Blizzard's minimal scroll bar on SaftUI's frames (`W.BlizzardBar`).
- "The nine-slice code `mover.lua` has twice" is stale: there was nothing to merge.
- "Micro menu options in `config.lua:239-324`" matches no file.

**Shape of work:** None is urgent. Fold one in when working nearby. The nil guards are a few lines each; the test items are an hour or two together.

### 2026-11-13 — Chat's dock hook runs only on forced updates

**What:** `CHT:FCFDock_UpdateTabs(dock, forceUpdate)` (`SaftUI-Chat/chatframe.lua`) starts with `if not (dock.isDirty or forceUpdate) then return end`. It is a post-hook (`self:SecureHook('FCFDock_UpdateTabs')`), and Blizzard's `FCFDock_UpdateTabs` clears `dock.isDirty` before the post-hook runs. So SaftUI's tab layout runs only on forced updates, and after a plain dirty update the docked tabs may be left where Blizzard put them.

**Why noticed:** The review of the cleanup's wave 1 (2026-11-12), which touched Chat, read the hook against Forever's `FloatingChatFrame.lua`. The behaviour is older than the cleanup, which didn't change it.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:FCFDock_UpdateTabs`, and the `SecureHook` in the module's enable); Blizzard's `FCFDock_UpdateTabs` in `FloatingChatFrame.lua`; `tests/chat/dock_test.lua`, which sets `isDirty` by hand before calling the hook, so it can't see this.

**What's been considered:** Dropping the guard makes the hook run on every call, which Blizzard makes often (each tab flash and each resize), so it may want its own cheap "has anything moved" check. Whether anything is wrong on screen is not known: the game may force an update in every case that matters.

**In game 2026-11-13:** the user checked step 35 and the docked tabs sit right, so the guard does no harm on screen. What's left is the test.

**Shape of work:** First the in-game check: step 35 of [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks). If the tabs are right after a drag and dock and after a plain tab switch, the guard is harmless and only the test needs to stop setting `isDirty` by hand. If not, a small fix in `chatframe.lua` and a test that calls the hook the way the game does.

### 2026-11-13 — Bag search box is made multi-line

**What:** `INV:InitializeSearch` (`SaftUI-Bags/search.lua`) calls `st:CreateEditBox(container:GetName()..'Search', container.footer, 'SearchBoxTemplate')`. But `st:CreateEditBox(name, parent, lines)` (`SaftUI-Core/Widgets/editbox.lua`) always creates from `'InputBoxTemplate'` and takes its third argument as `lines`: `if lines then editbox:SetMultiLine(true) end`. So the search box gets no `SearchBoxTemplate` (no magnifier, no clear button) and is a multi-line box. It is also skinned twice, once inside `st:CreateEditBox` and once by the caller.

**Why noticed:** The cleanup's Task 16 moved the search code into `search.lua` (2026-11-12) without changing it, and its reviewer read the call against `st:CreateEditBox`. The behaviour is older than the cleanup.

**Anchors:** `SaftUI-Bags/search.lua` (`INV:InitializeSearch`); `SaftUI-Core/Widgets/editbox.lua` (`st:CreateEditBox`). The search box has no test file of its own.

**Shape of work:** Small. Either drop the third argument, or give `st:CreateEditBox` a template parameter and pass `'SearchBoxTemplate'` properly (then the skin has to deal with the template's own art, on both clients). Check in game what Enter does in the box today (step 16 of [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks)).

**In game 2026-11-13:** the user checked step 16 and the box behaves fine as it is. The call is still wrong as written.

**Open questions:** Does the user want the search template's magnifier and clear button, or SaftUI's plain box?

### 2026-11-12 — Codebase cleanup: the items waiting on a decision

**What:** The cleanup report (`docs/reports/2026-11-12-codebase-cleanup-analysis.md`) found bugs, dead code and refactors. Everything with a clear fix was done under `docs/superpowers/plans/2026-11-12-saftui-cleanup.md` (21 tasks in five waves, merged into `modular`, 343aee8 to 1d69905). What that work set aside is in [Codebase cleanup: small things left over](#2026-11-13--codebase-cleanup-small-things-left-over), and what it needs seen in game is in [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks). The items below were left untouched, because each needs the user's choice or an in-game check first.

**Why noticed:** The user asked for an analysis of the code base (dead code, organization), then said: "Lets work on all the items with subagents that have clear fixes, as for the ones that need my decison for now lets leave them and take a look at them later". This entry is the "later" list.

**Anchors:** the report's sections in brackets.

- **Possible bugs, need an in-game check:**
  - Bags: `INV:SelectBankCategory` (`SaftUI-Bags/inventory.lua`) sets the Character bank type for the `warband` container and Account for `bank`. They look swapped. [1, bug 6]
  - Bags: the `combinedbank` window is offered only when `HasWarbandBank()` is true (`categoriestab.lua`). Intended? [1, bug 7]
  - Core: `TaintFix:OnInitalize` (`SaftUI-Core/taintfix.lua`) is misspelled and never runs. Fixing the spelling alone would error at login (`ClickBindingFrame` is load-on-demand). Fix it properly, or delete the file? [1, bug 11]
- **Writes onto Blizzard frames (taint rule 1), not traced:** `Blizzard_WeeklyRewards.lua`'s `ShouldShowOverlay`, `st:EnableResizing` on `WorldMapFrame`, `st:Kill`'s other callers (see also "st:Kill and st:SkinIcon still write onto Blizzard pieces"), the totem bar's setup on classes with no totems. [1]
- **Migrations that may be finished** (delete once every profile has passed through them): Bags `categories.lua` and `movers.lua`, `CHT:MigratePosition`, `st:ResolveLegacyTemplate` with its seven "defaults look as they did" tests and `T.old_names`. [2.3, 6.3]
- **Features that look unused, keep or delete:**
  - the loot window popup (`SaftUI-Loot/popup.lua`, with its two accidental globals);
  - the honor feed;
  - the keybinding widget (`SaftUI-Core/Config/optionskeybinding.lua`);
  - the old bag Edit view;
  - time played in Core's `init.lua`;
  - Unitframes' `arena` unit, Portrait and AuraWatch;
  - the aura `filter`, whitelist, blacklist and `spellIds` default tables (tied to "Unit frame defaults that nothing reads").

  [3]
- **Packaging:** unused Ace libraries' TOC lines, `OptionalDeps`, unused media files, one Core TOC where there are two (needs a load check in game). [5]
- **Two widget sets:** Bags' `ruleeditor.lua` and `categoriestab.lua` draw their own controls beside Core's options widgets. Moving them over is a design choice. [4.5]
- **Renames with no obvious target:** the two `theme.lua` and two `skinning.lua` files, the Media options tabs; regrouping `OW.Seam` and `W.Seam`. [4, 6.6]
- **Test stubs:** more `CLIENT_ONLY` entries, getters that return secrets, `IsForbidden` answering true. [6.5]

**What's been considered:** Each item's detail, with file and line, is in the report. The report labels each finding Certain, Likely or Decide; these are the Decide ones plus the Likely ones whose right fix depends on what the game does.

**Shape of work:** A sitting with the user to go down the list (keep, delete, fix), then one small plan for what they choose. Most answers are a deletion of 50 to 400 lines.

**Open questions:** Each bullet is one.

### 2026-11-12 — Cooldown Manager skin: in-game checks

**What:** SaftUI now skins Blizzard's Cooldown Manager (`Blizzard_CooldownViewer`) as SaftUI's action buttons, and its tracked bars as SaftUI's bars (branch `cdm`). It was built from both clients' source and tested on stubs, which model neither the game's drawing and frame order, its pixel grid, Edit Mode's layout, combat protection and taint, nor secret aura data. These steps need a look in game, on Forever first and on retail where marked, with BugSack on.

**Why noticed:** The skin was built straight from the user's ask ("no need for planning, just standard action button skinning"), so this list is the only in-game check it gets. The run's report is `.superpowers/sdd/cooldown-manager-skin/report.md` (not versioned).

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_CooldownViewer.lua`, `SaftUI-Misc/Skinning/skinning.lua` (the Skinning page's Cooldown Manager toggle), `SaftUI-Misc/config.lua` (`skinning.cooldown_manager`); `tests/misc/cooldown_viewer_test.lua`, `tests/misc/fixtures/cooldown_viewer.lua`; `.agents/taint.md` (rules 1, 2 and 11), `.agents/clients.md` (Cooldown Manager).

**What's been considered:** Blizzard's layout puts the items Icon Padding less 4 apart (`GetAdditionalPaddingOffset`), so its round icons, about 2px inside each item, touch. SaftUI's backdrop sits 2px inside the item, where that icon was, so neighbours are Icon Padding apart: 2px at Blizzard's default for Essential and Utility (the presets Forever loads), 5px for the tracked buffs. The skin doesn't change the layout: Edit Mode owns it. Under Blizzard the action ring is a texture of the item over the icon (moved to BACKGROUND), the totem bar's way, so every frame Blizzard puts on the item (the cooldown, the count, the debuff border, the proc and pandemic glows) stays where Blizzard made it, over the ring. Icon Size scales each item, and SaftUI's border with it, so at a size other than 100% the border is no longer whole pixels; counter-scaling SaftUI's backdrop was left out until it's seen. The Cooldown Manager's settings window keeps Blizzard's look.

**Shape of work:** A pass by the user, then a small fix per step that fails. The steps:

*Setup, both clients*
1. Turn the Cooldown Manager on (Blizzard's Options, or `/console cooldownViewerEnabled 1`) and `/reload`. `/dump C_AddOns.IsAddOnLoaded('Blizzard_CooldownViewer')` is true at login. Track a few spells in the Essential and Utility rows (one with charges, one with a range, one that gives you a buff), a few tracked buffs as icons, and one as a bar.

*Under Thick, out of combat*
2. Each Essential and Utility icon is square, with Thick's border where Blizzard's round icon was, no round corners, no Blizzard frame round it and no gap between the border and the icon. Neighbouring icons are 2px apart (at Blizzard's default Icon Padding), their borders not touching. Cast a spell with a cooldown: a flat, dark, square swipe over the icon (not round), the countdown in Pixel Med on the Essential row and in Pixel on the Utility row. A spell with charges shows its count in the icon's bottom right corner, 3px in from the border's outer edge, in the Skinning font (Pixel). The GCD flash plays over the icon, not past its border.
3. Target something out of a ranged spell's range: the icon tints red, and no dark round shadow shows on it (SaftUI fades Blizzard's; the tint alone shows it, as on SaftUI's action bars). A spell that buffs you: while the buff is up its swipe is Blizzard's gold, flat and square.
4. Tracked buffs (icons): the same square look; the swipe counts down dark and square; stacks in the icon's corner. A tracked debuff on your target shows Blizzard's dispel-colored border round the icon, over SaftUI's: say how it reads (the followup "Cooldown Manager skin: a tracked debuff's dispel type on SaftUI's border").
5. Tracked bars: the icon as above; the bar a flat orange fill with Thick's border just outside it, no Blizzard bar background or shadow under it, a 2px white line at the fill's end the bar's full height (only while the buff is up), the name and the duration in Pixel. A 2px gap between the icon's border and the bar's. Stacks show in the bar icon's corner, whole, also with `/sui` → Skinning → Font set to Normal (Blizzard made that text 10px tall). In Edit Mode set Bar Content to Name only: the icon and its stacks hide; Icon only: the name hides. The bar viewer spaces its items 2px tighter than the icon viewers and its icon has no round inset, so SaftUI's 2px inset leaves about 6px between the icon's border and the bar's, and 2px more between rows than Icon Padding: say whether it looks too loose (the fix would be no inset on bar items).
6. Proc glows (a spell that lights up) and Blizzard's pandemic glow on a DoT still show round the skinned icons, bright, not dimmed by a cooldown's swipe: cast a spell whose proc lights another that's on cooldown, and compare with the same spell on SaftUI's action bars.

*Edit Mode, both clients*
7. Open Blizzard's Edit Mode: the placeholder icons are skinned too. Icon Padding 2 (Blizzard's default): a 2px gap between neighbouring borders; 0: the borders touch; 3: SaftUI's 3px (measure each in a screenshot). Icon Size 50% and 150%: the border scales with the item; say whether it looks soft or uneven (see What's been considered). Vertical orientation, Icon Limit wrapping and Icon Direction keep every icon skinned. Changing these after the viewer was laid out once (Blizzard releases and acquires its items again) gives no doubled borders.

*In combat*
8. Set a viewer's Visibility to In Combat, and tracked buffs to hide while inactive. Pull: the viewer appears skinned, and a tracked buff that comes up in combat appears skinned, with no ADDON_ACTION_BLOCKED, no "Interface action failed" and no Lua error. `/reload` in combat with the viewers up: still skinned, no errors. If BugSack ever shows an error from SaftUI's skin, the viewer should still lay its icons out and they should work, in Blizzard's look where the skin failed (it reports the error instead of stopping Blizzard's layout): say which, with the error.
9. Retail, in content where aura data is secret (Mythic+ or a raid, in combat): tracked buffs and their swipes and stacks keep working, with no Lua error from `Blizzard_CooldownViewer.lua` in SaftUI-Misc or from Blizzard's Cooldown Manager.
10. `/console taintLog 1`, play a while with the Cooldown Manager (pulls, Edit Mode changes, its settings window, a talent or spec change), then `/reload`: nothing in `Logs/taint.log` blames SaftUI for `Blizzard_CooldownViewer` or the viewers.

*Themes*
11. `/sui` → Global Settings → Theme → Thin: a 1px border, the icon 1px inside it, the bar's border 1px outside the bar. Blizzard: each icon in Blizzard's action button art (its slot behind the icon and the ring round it, over the icon's edge), and the swipe, the countdown, the charges, a tracked debuff's border and the glows over the ring, not under it; a bar's stacks over its icon's ring; the bar in Blizzard's tooltip border. Back to Thick: none of Blizzard's art left. Each switch applies at once, in and out of combat.
12. `/sui` → Skinning → Theme None: bare square icons where the border would be, and bare bars; Thin overrides the global theme there; Font Normal changes the charges, stacks and the bars' texts at once. Switch to a profile with another theme: the Cooldown Manager follows with no reload.

*The toggle*
13. `/sui` → Skinning → Cooldown Manager off: chat says "Reload your UI to apply."; after `/reload` the Cooldown Manager is Blizzard's own again (round icons, its frame, its round swipe and fonts, its bar art). On and `/reload`: SaftUI's look is back.

**Open questions:** Should the skin counter-scale SaftUI's border at Icon Sizes other than 100% (step 7)?

### 2026-11-12 — Cooldown Manager skin: a tracked debuff's dispel type on SaftUI's border

**What:** The Cooldown Manager skin leaves Blizzard's debuff border (`DebuffBorder`, `CooldownViewerItemDebuffBorderTemplate`) as Blizzard draws it: 3px round the icon, over SaftUI's border, in the debuff's dispel color. The buff skin instead colors SaftUI's own border by the dispel type under Thick and Thin and shows Blizzard's art only under Blizzard.

**Why noticed:** Out of scope for the Cooldown Manager skin ("standard action button skinning"), noticed while reading `Blizzard_CooldownViewer` for it. Tracked buffs and bars show a debuff border for a harmful aura they track (a DoT you put on your target, read from the player's and the target's auras).

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_CooldownViewer.lua`; the buff skin's way, `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFrame.lua` (`SkinBorders`, `BuildAtlasColors`); Blizzard's `CooldownViewerItemDebuffBorderMixin:UpdateFromAuraData` and `AuraUtil.SetAuraBorderAtlasFromAura` (`Blizzard_FrameXMLUtil/AuraUtil.lua`, both clients).

**What's been considered:** The buff skin's way carries over: post-hook the border texture's `SetAtlas` and its frame's `Show` and `Hide`, map the atlas to a color through `AuraUtil.GetDebuffDisplayInfoTable()`, put it on SaftUI's border with `st:SetBorderColor` and again in `OnColorsChanged('theme')`, fade Blizzard's art by alpha under Thick and Thin, and fall back on it for a secret atlas (on retail the aura data, and so the atlas, can be secret in combat).

**Shape of work:** Small: one function and a test on the fixture, after the in-game check (step 4 of "Cooldown Manager skin: in-game checks") says whether Blizzard's border over SaftUI's reads badly.
### 2026-11-12 — Nameplates: a plate page's Position editor checks anchors against whichever plate has the lowest number

**What:** A Position editor on Enemy nameplates or Friendly nameplates checks a new anchor against live frames: `st:ValidateAnchor` (`SaftUI-Core/api.lua`), from the `validate` of `uf_element_position` (`SaftUI-Unitframes/config/position.lua`), asks whether the part chosen to anchor to already depends on the part being moved, on the frame `UF:GetConfigFrame(unit)` gives, which for either plate key is the frame on the lowest-numbered plate (`SaftUI-Unitframes/config/config.lua`), whichever page that plate draws from now. So with an enemy on the lowest plate, the Friendly page refuses Health → Name with "Anchor would create a loop", though the friendly config has none (it's the enemy's name that sits on its bar). With a friend there, the Enemy page accepts Health → Name, which does loop in the enemy config (its name is on its bar), and every update of an enemy plate then errors. Which answer you get depends on which plate has the lowest number. Anchors that loop only across the two pages no longer error at run time (the final fix wave places a switching plate's parts afresh), so the refusal is only a wrong answer in the options; the acceptance lets a loop inside one config through.

**Why noticed:** The final review of the friendly nameplates build (2026-11-12, its M1), filed here by that build's final fix wave, which changed no code for it.

**Anchors:** `SaftUI-Unitframes/config/config.lua` (`UF:GetConfigFrame`, `UF:ConfigTarget`), `SaftUI-Unitframes/config/position.lua` (`generators.uf_element_position`: `ResolveTarget`, `UnitFrame`, `GetElementNames`, `validate`), `SaftUI-Core/api.lua` (`st:ValidateAnchor`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF.nameplates`, `frame.base_unit`, `ClearPlacedPoints`), `tests/unitframes/nameplate_page_test.lua` and `friendly_page_test.lua` (the plate pages).

**What's been considered:** For a plate page, return the lowest plate whose `base_unit` is that page's key, and nil when there's none, so the validator allows, as it does before any plate exists. With nil, the element dropdown falls back to every registered element (`GetElementNames`), Power and Class power among them, so it may want the lowest plate of either kind for the list and only the page's for the check. A check against the page's config (the anchors as its positions set them, not the live frame's) would give the same answer whatever plates are up, and would suit every unit's editor.

**Shape of work:** Small: `UF:GetConfigFrame` (or a variant for the validator) and a test in `nameplate_page_test.lua` with an enemy and a friend up in either order.

**Partly fixed 2026-11-14 (branch fb-plateanchor):** the check no longer measures the live plate (a plate part's anchors are read from its config, `UF.PlatePartAnchors`, since the game refuses `GetPoint` on one), and `UF:GetConfigFrame(unit)` now picks the lowest plate that draws from that page, with an enemy and a friend up in either order (`tests/unitframes/nameplate_anchor_test.lua`). What's left: with only the other kind of plate up, the part's config is still that plate's (`frame:GetConfig()` reads its `base_unit`), so the Enemy page checks against the friendly config. A check on the page's own config, whatever plates are up, would close it.

### 2026-11-12 — Unit frames: a profile switch places a frame's parts against the old profile's anchors

**What:** A full update places a unit frame's parts one by one in `pairs()` order (`UF:UpdateUnitFrame`, `SaftUI-Unitframes/unitframes.lua`), each `SetPoint` made against the others where they are then. So two parts anchored each way round across two profiles (Name on Health in one, Health under Name in the other) close an anchor loop on a profile switch whenever the one placed first is anchored to the other: the game errors "Cannot anchor to a region dependent on it", `SafeUpdateUnitFrame` reports it, and the rest of that frame's update is cut short, its later parts keeping the old profile's look until its next full update. `UF:ApplyConfig` with no unit clears only the frames' points first (`ClearUnitFramePoints`), not their parts'. A plate's parts are cleared before a switch between Enemy and Friendly nameplates (`ClearPlacedPoints` in `nameplates/nameplates.lua`), but not on a profile switch that keeps a plate's config unit. Pre-existing for every unit.

**Why noticed:** The friendly nameplates' final fix wave (2026-11-12) resolved "Nameplates: a plate switching config can trip an anchor loop in a user's config" (now under Resolved) for a switch between the two plate configs only, as its brief ruled. That entry's open question (clear on a config switch only, or before every full update?) and its note that a profile switch does the same to any unit are what's left, kept here.

**Anchors:** `SaftUI-Unitframes/unitframes.lua` (`UF:UpdateUnitFrame`, `UF:ApplyConfig`, `ClearUnitFramePoints`, `SafeUpdateUnitFrame`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`ClearPlacedPoints`, `UF:ApplyPlateConfig`), `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`), `tests/unitframes/friendly_plate_size_test.lua` (the switch's tests, whose helpers say which parts an update places).

**What's been considered:** Clear each frame's parts in `UF:ApplyConfig`'s full pass, out of combat where it clears the frames', with `ClearPlacedPoints`' rule for which texts and icons; or clear a plate's parts before every full update of it, which covers the plates alone. Either way a part whose update then fails, and the parts after it, are left with no points (as a plate's are today when a switch's update fails, say on a loop inside one config), where `UF:ApplyConfig` gives a failed frame its old points back (`st:RestorePoints`).

**Shape of work:** Small: the clearing in the full pass, and a test with two parts anchored each way round across two profiles.

### 2026-11-12 — Nameplates: the Friendly page's aura borders and cooldown never reach plate buttons

**What:** An aura area's group is made once per frame, on its first update with the area on, and a plate's frame always gets its first update from Enemy nameplates (`nameplate`, its unit token's config). Which borders a button shows (Buffs' Stealable border, Debuffs' Dispel type border) and whether it has a cooldown swipe (Cooldown → Show) are baked into each button by oUF's `CreateButton` from the group's options. So while Enemy nameplates has an aura area on (both are, by default), Friendly nameplates' border and Cooldown → Show for that area never reach a plate's buttons, not even after a reload. With the Enemy page's area off, the group is made from whichever config first turns it on on that frame, so the Enemy page's can be the ones left out. With the Enemy page's box checked (enemies drawn from the Friendly page) the Enemy page's area Enable still decides, though the page hides it then: to make the Friendly page's reach the plates, uncheck the box, turn the Enemy page's area off, check the box again and reload. Since the final fix wave the two options' notes on both plate pages say which page's settings a plate's buttons take (`ReloadNote`); before, they said "Reload to apply", untrue on the Friendly page.

**Why noticed:** The fix round of Task 3 of the friendly nameplates plan (2026-11-12) made an aura area's max count and button size follow a plate's kind live (`SetAuraGroupMaxFrameCount`, and `StyleButton` setting the size), and its concerns named the two options that can't. Ruling N2 in the run's ledger (`.superpowers/sdd/2026-11-12-saftui-friendly-nameplates/progress.md`, not versioned): the final fix wave reworded the two notes, on the Friendly page to say they only apply while the Enemy page's area is off, and on the Enemy page to say its settings make every plate's buttons while its area is on; this entry holds the real fix.

**Anchors:** `SaftUI-Unitframes/elements/auras.lua` (`AddGroup`'s `showDebuffBorder`, `showStealableBorder` and `disableCooldown`; `StyleButton`; `RestyleButtons`; `ReloadNote` and `NeedsReload` on the tabs; the header comment), `SaftUI-Unitframes/Libraries/oUF/elements/auras.lua` (`CreateButton`), `tests/unitframes/plate_auras_test.lua`, `.agents/architecture.md` (Aura filters). The older aura entries: "Aura filters and per-aura styling lost in the oUF aura-container rewrite" and "Profile settings that still need a /reload after a profile switch" (item 1).

**What's been considered:** The container can't remove or remake a group. Hiding or showing the border and cooldown a button already has, in the restyle, works only one way: a button made without them can't gain them. So a plate's groups could be made with every border and the cooldown on, and the restyle hide what the config in use turns off (out of combat, as the restyle already waits: `.agents/taint.md` rule 11), which also makes both options live everywhere else. Two groups per area, one per config, would double the buttons.

**Shape of work:** Small to medium in `auras.lua`: check how oUF's `CreateButton` builds the border and cooldown and whether hiding them is enough, then the restyle and tests in `plate_auras_test.lua`, and the notes (`ReloadNote`) brought in line.

**Open questions:** Does a hidden dispel or stealable border stay hidden when the container updates the button's aura, or does Blizzard's code show it again?

### 2026-11-12 — Nameplates: what a kind change costs in oUF updates

**What:** A plate the game hands to the other kind (with the boxes off) gets oUF's `UpdateAllElements` three or four times on that add: `OnAttributeChanged` (oUF, before the added callback, still with the old config), `OnShow` (the full update `UF:ApplyPlateConfig` runs from the new config, inside the first `'added'` callback), a second `OnShow` when that update's `'updated'` callback enabled a part in oUF (an enemy after a friend: the castbar), then `NAME_PLATE_UNIT_ADDED` (oUF, after the added callbacks). A `UNIT_FACTION` that changes the kind is the full update and `UpdateAllElements('UNIT_FACTION')`. A friend's first add on a new plate is two full updates of SaftUI's: `UF.InitUnit`'s, from `nameplate` (its unit token's config), then `UF:ApplyPlateConfig`'s from `friendlynameplate`. A reuse of the kind the plate last showed adds none, since the look is applied again only when the config unit changes. In a city, or a pull among friendly NPCs, plates change kind often. The aura scan isn't part of the cost: it was checked against Blizzard's source, and a kind change's two scans fold into one parse (Blizzard's managed container only marks itself dirty and parses once on its next frame: the Abandoned entry "Nameplates: a plate handed to the other kind scans its auras twice"), so what's left is oUF's updates.

**Why noticed:** The review of Task 3 of the friendly nameplates plan (its minor 4), deferred to the final review by the controller. The counts are pinned by `nameplate_kind_test.lua` (a plate reused for an enemy) and `friendly_plate_test.lua` ("a re-applied look only when the key changes").

**Anchors:** `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF:ApplyPlateConfig`, `UF:ApplyPlateKind`, the `'updated'` callback that enables parts, `UpdatePlateKind`), `SaftUI-Unitframes/unitframes.lua` (`UF.InitUnit`, `UF:UpdateUnitFrame`), `SaftUI-Unitframes/Libraries/oUF/ouf.lua` (the nameplate driver's add), `.agents/architecture.md` (Plate callbacks).

**What's been considered:** Skip `UF:UpdateUnitFrame`'s own `UpdateAllElements('OnShow')`, and the `'updated'` callback's second one, when they run inside an add, since oUF's `NAME_PLATE_UNIT_ADDED` update follows; give a new plate's frame its first update from its kind's config, so a friend's first add is one update. Each changes an order the tests pin, and oUF's castbar `Enable` hides the bar until an update, so the second `OnShow` may have to stay.

**Shape of work:** Measure first: only worth it if plates changing kind show up in a profile (`debugprofilestop` round `UF:ApplyPlateKind` in a busy city or a pull). Then small changes in `nameplates.lua` and `unitframes.lua`, with the pinned orders updated.

**Open questions:** Does it show in game?

### 2026-11-12 — Nameplates: a box toggled in combat leaves shown plates on the old config until combat ends

**What:** Setting either nameplate page's box (Use friendly nameplates' settings, Use enemy nameplates' settings) runs `UF:UpdateConfig('nameplate')`. In combat that waits for the end of combat (`QueueAfterCombat('Unitframes')`) and only points the cached configs at the profile again (`UF:RefreshConfigReferences`), which keeps each plate's `base_unit`. So the plates up keep the old config until combat ends, while a plate added, or whose unit changes faction, in the meantime takes the new one at once (`UF:ApplyPlateKind` reads `UF.PlateConfigKey`): both looks on screen for one kind for the rest of the fight. The plate size waits for the end of combat anyway. `/sui` closes as combat starts and won't open in it, so no box can be clicked in combat today: this is latent, for any other path that changes a box in combat.

**Why noticed:** The review of Task 3 of the friendly nameplates plan (its minor 5). Task 4's end-to-end box test runs out of combat (ruling P1), and the controller parked the in-combat case.

**Anchors:** `SaftUI-Unitframes/nameplates/options.lua` (`PlateBox`'s `set`), `SaftUI-Unitframes/unitframes.lua` (`UF:UpdateConfig`, `UF:RefreshConfigReferences`, `UF:ApplyConfig`'s plate branch), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF:ApplyPlateConfig`), `SaftUI-Core/Config/config.lua` (`Config:Open` refusing in combat, and closing `/sui` on `PLAYER_REGEN_DISABLED`).

**What's been considered:** In `UF:UpdateConfig`'s combat branch, also run `UF:ApplyPlateConfig` on every plate (a plate's frame isn't secure), leaving the rest to the queued update. Or leave it while nothing can change a box in combat.

**Shape of work:** Small, if a path to it ever appears: a few lines and an in-combat case in `friendly_plate_size_test.lua`'s box test.

**Open questions:** None until something can change a box in combat.

### 2026-11-12 — Nameplates: a neutral unit turning hostile keeps its name's old color

**What:** A plate's name is drawn again on a faction change only when the change flips the plate's kind (`UpdatePlateKind` in `nameplates.lua` ends in `UpdateAllElements('UNIT_FACTION')`, which runs the tags). A neutral unit turning hostile, or hostile back to neutral, stays an enemy plate, so its name keeps its old color (yellow for red, or red for yellow) until the `st:name` tag's next event (`UNIT_NAME_UPDATE`, `UNIT_LEVEL`, `PLAYER_LEVEL_UP`, `PLAYER_TARGET_CHANGED`: in practice the next target change). Its health bar recolors at once (oUF's Health registers `UNIT_FACTION` for `colorReaction`). Every unit frame's name works the same way, since the tag has no faction event: pre-existing, not caused by the friendly nameplates build.

**Why noticed:** Task 3's report of the friendly nameplates plan (its friendly↔hostile name redraw covers a kind change only), after Task 2's review noted the tag has no `UNIT_FACTION` refresh (Color hostile too).

**Anchors:** `SaftUI-Unitframes/tags.lua` (`UF.oUF.Tags.Events['st:name']`, `NameColor`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UpdatePlateKind`, `OnPlateEvent`), `tests/unitframes/friendly_plate_test.lua` (the `UNIT_FACTION` case), `tests/unitframes/name_color_test.lua`. The entry "Nameplates: small items left after the build" proposes dropping `PLAYER_TARGET_CHANGED` from the same list, which would also drop the redraw on a target change.

**What's been considered:** Add `UNIT_FACTION` to the tag's events (a unit event, so oUF updates only the frames showing that unit), or update the name's tag in `UpdatePlateKind` when the kind didn't change (plates only). The first fixes every unit frame and pairs with dropping `PLAYER_TARGET_CHANGED`.

**Shape of work:** Small: one event in the tag's list, and a test.

### 2026-11-12 — Nameplates: friendly players and friendly NPCs configured apart

**What:** Friendly players' plates and friendly NPCs' plates share one config, and one on/off (the game's two friendly settings, `nameplateShowFriendlyPlayers` and `nameplateShowFriendlyNpcs`, set together). The user may want them split later: separate settings, or at least a separate on/off for NPCs.

**Why noticed:** During the 2026-11-12 brainstorm on configuring friendly plates apart from enemy plates, the user found friendly NPC plates everywhere in cities overwhelming. The agreed design gives friendly plates their own page (name only by default, players' names in class color) with a "use enemy nameplates' settings" box. Asked whether players and NPCs should be switchable apart, the user said: "for now lets keep friendly npcs and friendly players in the same config but I might want to split them out later".

**Anchors:** the friendly nameplates spec (`docs/superpowers/specs/2026-11-12-saftui-friendly-nameplates-design.md`) and plan (`docs/superpowers/plans/2026-11-12-saftui-friendly-nameplates.md`), `SaftUI-Unitframes/config/units/friendlynameplate.lua` (the friendly config), `UF.PlateConfigKey` (`SaftUI-Unitframes/unitframes.lua`: which config a plate draws from), `SaftUI-Unitframes/nameplates/cvars.lua` (`UF.NAMEPLATE_CVARS`: both friendly settings from one toggle), `SaftUI-Unitframes/nameplates/nameplates.lua` (`IsFriendlyPlate`).

**What's been considered:** The game already has a separate setting for each. A split on/off is small. Split looks would be a third plate config, chosen per plate by `UnitIsPlayer`, and the "use the other's settings" boxes would need a rule for three pages.

**Shape of work:** Small for a separate NPC on/off (one more toggle, one more CVar entry). A design pass for split configs.

**Open questions:** Only an on/off for NPCs, or a full third page?

### 2026-11-11 — Nameplates: in-game checks

**What:** SaftUI's nameplates (the nameplates plan, branch `np`, and the friendly nameplates plan, branch `fnp`) were built and tested on stubs, which model neither the game's plates on screen, its layout and pixel grid, combat protection and taint, secret values in restricted content, nor what the game reports for several settings and auras. These steps need a look in game, on Forever (the user's client) first and on retail where marked, with BugSack on.

**Why noticed:** The plan's in-game check list (its Task 13), every task's report and review, and the run's ledger (`.superpowers/sdd/2026-11-11-saftui-nameplates/`, task-N-report.md and progress.md, not versioned) named what the stubs can't show. This entry merges them, grouped by area, so the user can run them in one pass. The friendly nameplates' (the spec's five, then what that run's reports and ledger named, `.superpowers/sdd/2026-11-12-saftui-friendly-nameplates/`) are steps 26 to 36, and the steps before them were brought in line with the two pages. The purge filters keep their own entry ("Purge filters: in-game checks"), which step 5 points to.

**Anchors:** `docs/superpowers/plans/2026-11-11-saftui-nameplates.md`, `docs/superpowers/specs/2026-11-11-saftui-nameplates-design.md`; `SaftUI-Unitframes/nameplates/` (`nameplates.lua`, `cvars.lua`, `target.lua`, `threat.lua`, `subtext.lua`, `pixels.lua`), `docs/superpowers/plans/2026-11-12-saftui-nameplate-subtext.md` (the subtext, steps 37 to 44; merged into `modular` at 06f2754), `SaftUI-Unitframes/config/units/nameplate.lua`, `SaftUI-Unitframes/config/units/friendlynameplate.lua`, `SaftUI-Unitframes/nameplates/options.lua` (the Enemy and Friendly nameplates pages), `docs/superpowers/specs/2026-11-12-saftui-friendly-nameplates-design.md`, `docs/superpowers/plans/2026-11-12-saftui-friendly-nameplates.md`, `SaftUI-Unitframes/aurafilters.lua`, `SaftUI-Unitframes/elements/health.lua` (`SHORT`), `elements/name.lua` (Max width), `elements/indicators.lua` (the quest icon), `SaftUI-Core/themeart.lua` (`ART.nameplatetarget`); `.agents/architecture.md` (Nameplates), `.agents/taint.md` (rule 13), `.agents/clients.md` (Nameplates).

**What's been considered:** Where a check fails the fix is usually small: the target art's offsets in `themeart.lua`, a folder name in `UF.NAMEPLATE_ADDONS`, `AbbreviateNumbers`' options (without SaftUI's breakpoints the game's own give 12K for 12.5K), an event in `threat.lua`. Two have a fallback named already. If the plates' borders still shimmer after a `/reload` (step 2), they could be built from SaftUI's own textures sized in whole pixels instead of the theme engine's backdrop; the plan kept the engine's borders unless this check shows shimmer. If the personal resource display turns out to be a nameplate after all (step 16), SaftUI's frame must stay off the player's own plate, as a patch to the bundled oUF did before it was reverted (ruling N5 in the ledger).

**Shape of work:** A pass by the user, then one small fix per area that fails. The steps:

*The plan's ten, with what the tasks added to each*
1. Both clients. With a plate up, `/dump NamePlate1:GetParent()==WorldFrame, NamePlate1:GetEffectiveScale(), UIParent:GetEffectiveScale()`: true, WorldFrame's scale, then 768 over your screen's height. Then `/dump SaftUI_NamePlate1:GetParent()==NamePlate1, SaftUI_NamePlate1:GetEffectiveScale()`: true, and UIParent's scale. With the default 200 by 20, a screenshot of a plate's health bar measures 200 by 20 pixels. Clicking just inside the bar's edges targets the unit; clicking just outside doesn't. Then `/reload` standing next to a pack, and as soon as the plates are up click near the edges of plates that sit close together: each click targets the plate under the cursor, never its neighbour (Blizzard's own click area, which SaftUI puts back to the bar after Blizzard sets it, reaches past the bar and up to where its name would be).
2. Both clients. Strafe and turn past a pack under Thick, Thin and Blizzard: the 1px borders round the health bar, the castbar and its icon, and the debuff and purge buttons stay whole, with no shimmer or doubling, and the name and health text don't jitter against the bar. Under Thick, a debuff's dark inner line stays whole, exactly 1px inside its border, while the plate moves. If Blizzard's UI scale setting or the window's size changed this session, `/reload` first: after a UI scale change the plates may only be fully sharp once you reload (the followup "UIParent's scale is set once, at login, so plates leave whole pixels after a UI scale or display change").
3. Change Blizzard's Interface → Nameplates size or style with plates up: SaftUI's size comes back at once. Then, in a pack, click near the edges of plates that sit close together, after each of these: a change of a Blizzard nameplate option (size, style, class colors); a resize of the game's window; toggling `/sui` → Unitframes → Friendly nameplates → General → Friendly plates off and on; toggling friendly plates with Blizzard's key binding (or Interface → Nameplates' friendly options); and, with friendly players' plates up, toggling Interface → Nameplates' option to show only friendly players' names. Each time the click targets the plate under the cursor. Do each in combat too: Blizzard's size shows until combat ends, then SaftUI's; the click area is SaftUI's at once after an option change or a resize, and after a friendly plate or show-only-names toggle once combat ends; and none of these, done in combat, gives an ADDON_ACTION_BLOCKED or a Lua error. `/sui` → Unitframes → Enemy nameplates → General → Width and Height resize every plate and an enemy's click area (a friend's name box is Friendly nameplates' Width and Height: step 26).
4. In a dungeon pull, `/run print(C_Secrets.ShouldUnitThreatStateBeSecret('player','nameplate1'))`, on retail too. As damage or healing: under the tank's threat the bar keeps its color and the percent above its right end is in the normal text color; near pulling both go orange; when the mob attacks you, red. As a tank with the tank role: a mob on you, no tint and 100%; tanking with someone else higher, orange; a mob taken from you, red; a mob another tank in the group holds, no tint (on a boss with two tanks, the off-tank sees no red on the boss the main tank holds); a mob that goes to the healer before you've touched it, red with no percent. On your own there's no tint or percent until Enemy nameplates → General → Threat when solo is on. Friendly plates never show either, and a mob that turns friendly mid-fight loses both at once. Global Settings → Colors → Threat: dragging Bad's picker recolors tinted plates and their percent live, and Reset puts them back. On Forever without a role, a warrior in Defensive Stance or a druid in Bear Form counts as a tank, and so does a party member in one holding the mob; changing stance or form changes the tint at once (`UPDATE_SHAPESHIFT_FORM`). `/dump PlayerUtil.IsPlayerEffectivelyTank()` with no role assigned, in a tank spec: the stubs take it that Forever never falls back to a spec's role. On retail in restricted content (Mythic+ or a raid): no Lua errors; where the threat state is secret, no tint or percent; where only the values are, the percent still shows. Through a long pull the percent keeps following your threat (it's written only when it, its tint or its color changes), and as a raid's tank, idle hostile plates around you stay untinted (their mobs aren't in combat, so the raid isn't read for them).
5. Purge, on enemy plates (their purge row is on by default): a shaman or priest sees an enemy's magic buff right of the bar, and a Forever hunter with Tranquilizing Shot (or a retail druid with Soothe) an enrage. On Forever, on a mob with a Frenzy, `/dump C_UnitAuras.GetAuraDataByIndex('target', 1, 'HELPFUL').dispelName` (the buff's index in place of 1): `""`, `nil` or `"Enrage"`? As a retail character who isn't a mage, see which buffs `isStealable` picks out; a retail mage with only Spellsteal sees only stealable buffs. On Target → Buffs → Buttons, Only buffs I can purge sits after Only mine with no reload note in its tooltip; on, as a warrior with no purge, the target's buffs go, and off they come back without a reload; Only mine on Target → Debuffs applies at once. The rest is the entry "Purge filters: in-game checks".
6. Under Blizzard, on each client, the target's art sits round the bronze box, lined up (Forever's yellow cooldown-manager selection, retail's nameplate selection; the offsets, (-5, 5, 6, -4) and (-3, 4, 3, -3), are starting values). Blizzard tints its own target art with `NAMEPLATE_BORDER_TARGET_COLOR` and SaftUI's keeps the atlas's own color: compare them, and say if SaftUI's reads wrong. Under Thick and Thin the target's health bar has a white 1px border and the others the theme's; retarget and it moves; clear the target and no white is left. Edit a theme color or Opacity on the Theme tab while targeting: the white stays.
7. Friendly plates show outside an instance, and inside one they're Blizzard's (forbidden plates), with no errors. Note your Interface → Nameplates friendly players and friendly NPCs settings, then turn Friendly plates (Friendly nameplates' General) off: friendly units lose their plates and both settings show unticked; on, they come back. Turn Nameplates off: the dialog asks "Nameplates change after a reload. Reload now?", and before you answer, Interface → Nameplates shows your own friendly, scale and simplified settings again; Yes reloads with Blizzard's plates. Nameplates on and a reload give SaftUI's plates and settings back. While you're here, judge Friendly plates' default (on, players and NPCs) with real data, and say if any of these should change: (a) outside instances every friendly NPC gets a plate, every vendor and guard in a city among them (a full plate was too much, and the friendly nameplates build answered it: a friend's plate is its name alone by default, step 26); (b) inside an instance the game shows its own forbidden friendly plates (Blizzard's look) over every group member, 39 of them in a 40-player raid; (c) the aura icons on enemy plates take the mouse, as Blizzard's own plate auras do: hovering one shows its tooltip, and a click on one doesn't reach the plate under it or the camera.
8. With Plater loaded (or another listed addon), `/reload`: that addon's plates, no SaftUI frames, no errors, your nameplate settings untouched, and Unitframes → Enemy nameplates and Friendly nameplates each show "Nameplates are drawn by Plater. Turn it off to use SaftUI's." over greyed-out options, the boxes greyed out too. With ElvUI loaded and its nameplates off, SaftUI's plates show. If you have Platynator, check its folder in `Interface/AddOns` is named `Platynator` (the code takes that name on trust) and that it stands SaftUI down the same way.
9. Quest progress widgets and the soft target icon show on plates, also once plates have been reused. A capture bar's or quest object's plate (widgets only) shows its widget at full size, sitting on the plate's bottom, not squashed; an enemy with a widget shows it hanging under its plate. Toggle Friendly plates while a quest object's or a friendly NPC's widget is on screen: the widget stays on its plate, placed right for its kind (and note whether a friendly NPC's plate switches between widgets only and whole in place: the followup "Nameplates: a plate that turns widgets-only, or back, without a new add").
10. Target a caster: an interruptible cast is the castbar's normal color, one that can't be interrupted grey, and the icon shows. The quest icon shows left of the bar on mobs your quests need (on Forever too) and on quest bosses, and goes at once when the quest is done or handed in.

*Spawning, combat and the game's settings*
11. `/reload` in the middle of a fight with plates up: no "Interface action failed" or ADDON_ACTION_BLOCKED (oUF sets the plates' size and their click area's insets itself when it makes its driver, without waiting for the end of combat as SaftUI's own size call does), and the friendly and scale settings change once the fight ends.
12. Pull a pack so new plates appear in combat: no ADDON_ACTION_BLOCKED for `SetIgnoreParentScale`, `SetScale` or `SetRoundLayoutToNearestPixel`, and the new plates are sharp at once. No `theme.lua` "forbidden object" error from the plates' aura buttons and no threat.lua "Font not set" (both seen 2026-11-11 and fixed: the aura buttons were styled again while aura data was secret, which stopped the plate's first update); the new plates' debuffs show in SaftUI's style, and their threat percent shows. Same for a party or raid member joining in combat.
13. Both clients. A boss's or an elite's plate, and the target's, are the same size as any other, near and far, and `/dump NamePlate1:GetScale()` is 1. With SaftUI's plates on, Interface → Nameplates shows no simplified types ticked. `/dump C_CVar.GetCVar('nameplateSimplifiedTypes')` before turning Nameplates on, and again after turning it off and reloading, shows the same text.
14. With plates up, change Blizzard's UI scale setting (or the window's size): the plates keep their size and their click area matches it. In combat they're pinned to the new scale at once and their size settles once combat ends. Their right and bottom edges may flicker by a pixel until a `/reload` (the UIParent scale followup).
15. `/dump C_CVar.GetCVarInfo('nameplateShowFriendlyPlayers')`, and the same for `'nameplateShowFriendlyNpcs'`: report the 3rd to 6th returns (isStoredServerAccount, isStoredServerCharacter, isLockedFromUser, isSecure). If they're kept per account, a second character that logs in while SaftUI's plates are on records SaftUI's values as its own, and turning Nameplates off there puts back SaftUI's values, not yours. Check both settings exist on both clients (neither `/dump C_CVar.GetCVar(...)` is nil), and whether Blizzard sets them again by itself at login, or on entering or leaving an instance (Friendly plates and the game would then disagree until the next toggle).
16. With Interface → Nameplates → Personal Resource Display on (on Forever, if the game allows it), `/dump C_NamePlate.GetNamePlateForUnit('player')` prints nil (ruling N5: the display is `PersonalResourceDisplayFrame`, not a plate), the display shows as usual with SaftUI's plates on, and targeting yourself adds nothing. If it finds a plate, the personal display needs looking at again.
17. `/dump SaftUI_NamePlate1Auras1:GetObjectType(), SaftUI_NamePlate1Auras1:IsObjectType('AuraContainer')`, and the same for `SaftUI_NamePlate1Auras2` (a plate's two aura rows, buffs and debuffs in either order): note what the game says. The rounding walk skips SaftUI's own containers by identity, so this only says whether its `IsObjectType` fallback would work.
18. `/console taintLog 1`, play a while with plates (pulls, a dungeon, Friendly plates toggled), then `/reload`: nothing in `Logs/taint.log` blamed on SaftUI from the plates, the widget moves, the size and options hooks, the click area calls or the setting callbacks.

*The page*
19. `/sui` → Unitframes: Enemy nameplates and Friendly nameplates are listed after Raid 40, in that order. Enemy nameplates' General has Nameplates, Threat when solo and Use friendly nameplates' settings, then Theme and Background, then Width and Height (step 31 has the rest of both pages); neither page has a Position section or a Copy from button, and Player's Copy from lists neither. With a plate on screen, an element tab's Position (Health's, say) lists the plate's elements and takes a typed frame.

*Layout and texts*
20. An enemy's plate: the bar 200 by 20, the name inside on the left, the health inside on the right as a short value (`12.5K`, no percent), the castbar under it with its icon at the left, the icon's left edge on the bar's; up to 6 of your debuffs above the bar from its left, growing right; purgeable buffs right of the bar; the raid mark centred above the debuff row; the threat percent above the bar's right end, clear of the debuffs, the raid mark and, under Blizzard, the bronze box (if it touches the box, raise its Position's Y). A friendly plate shows its name and raid mark alone by default (step 26), and a friendly NPC casting shows no castbar while Friendly nameplates has the castbar off. Pull a group with friendly NPCs on screen and turn the camera so plates are reused: enemy plates show their castbar, debuffs and purgeable buffs, in place, and no friendly plate shows an enemy's part. An NPC that turns hostile (a quest mob going aggressive) gains the castbar and auras at once, with no empty castbar. In `/sui`, turning Enemy nameplates' castbar or quest icon off and on follows at once on enemy plates, and leaves friendly ones as Friendly nameplates has them.
21. A mob with a long name, and one with a long health value (a boss's `1.2M`): the name is cut before the health text and doesn't run under it, and a short name sits at the bar's left, not centred. Does the cut end in an ellipsis or just clip? Either is fine; say which. `/sui` → Unitframes → Target → Name → Max width 100 with a long-named target cuts it; 0 gives the whole name back, as before (the code takes `SetWidth(0)` to mean as wide as its text).
22. Short with a secret health: on retail, in content where enemy health is secret (Mythic+, in combat), the plates still show a short value, with no Lua error from `elements/health.lua` (an "AbbreviationDataError" or "invalid breakpoint" error would mean the game refuses SaftUI's own breakpoints for a secret). On Forever, with Target → Health → Text → Short on, mobs of about 999, 1,500, 12,500 and over a million health show `999`, `1.5K`, `12.5K` and `1.2M`; note whether 12,490 shows `12.4K` (rounded down) or `12.5K`. On retail, a target frame with Percent on shows a whole number such as `72` in restricted content.
23. Names: a hostile mob's name is red and a neutral one's yellow; in restricted content, where names, levels or reactions are secret, the name still shows, with no level part or color, and nothing errors from `tags.lua`; no `<` follows the target's name on any frame.

*Themes*
24. Switch Thick, Thin, Blizzard and back to Thick with the same target. Under Blizzard each plate's health bar and castbar sit in the bronze box, health on Blizzard's raid bar fill in reaction colors, the cast icon with no border of its own, and the debuff and purgeable buff icons in Blizzard's aura art. Back under Thick no bronze piece, raid fill or target art is left, and the target's white line is back. With a tinted plate (step 4) the tint stays through each switch, on the raid fill under Blizzard, and the bar goes back to its plain reaction color on the same fill when the threat is good. Optional: Enemy nameplates → General → Theme Blizzard, with SaftUI's theme Blizzard, gives each plate one bronze box, the plate's, with the target's art still round it.

*Other unit frames this build changed*
25. A hostile mob tagged by a player outside your group turns your target frame's health bar the tapped grey at once. Party and raid frames build as before after a `/reload` in a group, and when someone joins: size, backdrop, bars, texts, raid mark and role corners, with no errors, and out-of-range members fade to Range → Outside range. A party Buffs area turned off stays off after a `/reload`. A party member's castbar shows only while they cast, and not empty after a `/reload`. Blizzard's player castbar stays hidden whether SaftUI's player castbar is on or off.

*Friendly nameplates (2026-11-12): the spec's five first*
26. In a city with default settings, friendly NPCs and players show only their names, centred where their plates are and about a name's size: players in their class color, NPCs green. Enemies look as before. Click a name: you target that unit. Click just beside its ends, inside where a 200 by 20 plate would reach: nothing is targeted through it. Target a friend: no border round its name under Thick or Thin, and no art under Blizzard. Judge whether a targeted name-only plate needs a mark of its own (the spec left it to this check).
27. Enemy nameplates looks and behaves as the old Nameplates page did, with your old settings, and enemy plates look as before.
28. Check Friendly nameplates → General → Use enemy nameplates' settings with plates up: the page keeps only Friendly plates, the box and the line under it, with no other tabs; friendly plates look like enemy plates at once (bars, castbars), with no threat tint or percent; Enemy nameplates' box is greyed out, with its line. Uncheck it: the Friendly page's settings and tabs come back as they were, and friends go back to their names.
29. Check Enemy nameplates → General → Use friendly nameplates' settings with plates up: the page keeps Nameplates, Threat when solo, the box, its line and the Threat tab; Friendly nameplates' box is greyed out, with its line. Every plate becomes 150 by 16 at once, the stacking too; enemies fill it, in the friendly look, and clicks follow. In a group the threat percent still shows on enemies (the tint goes on the hidden health bar unless Friendly nameplates turns Health on). Uncheck it: enemies go back to 200 by 20, friends to their centred name box.
30. Mobs and friendly NPCs together (pull a mob next to a friendly guard, and turn the camera so plates are reused mid-fight), and a duel or a unit turning hostile or friendly: each plate switches cleanly between an enemy's full plate and a friend's name box, in and out of combat, with no part left from the other look (no castbar, aura or threat on a friend, no missing castbar on an enemy) and no Lua error. A duelled party member's plate takes the enemy look at once, its name red, and goes back to the name alone after the duel. After combat, clicking a friend's name targets it and clicking beside it doesn't.

*Friendly nameplates: what the run's reports added*
31. `/sui` → Unitframes: Enemy nameplates and Friendly nameplates follow Raid 40. Enemy nameplates' General has Nameplates, Threat when solo and its box on one line and no Friendly plates; Friendly nameplates' General has Friendly plates and its box, and the page has no Threat tab. The long box labels and the lines under them fit their rows in SaftUI's window.
32. Does the game's click area follow a frame's rect after oUF's two hit-test calls, or take a snapshot of it when they're made? SaftUI sets it again after every change of a plate frame's place or size (`UF:RestorePlateHitTest`, ruling R1 of that plan's Task 4) in case it's a snapshot, but in combat the game refuses that after a `UNIT_FACTION`. So duel someone, or watch a unit turn hostile in combat: its plate grows from the name box to the enemy size at once. Mid-combat, click near the grown plate's edge, outside where the name box was: if that doesn't target it until combat ends, the game takes a snapshot; if it does, the area follows the frame. Say which.
33. No ADDON_ACTION_BLOCKED (BugSack, or `/console taintLog 1` and then `Logs/taint.log`) when a plate changes kind or size in combat: pull a pack near friendly NPCs so plates are reused between the kinds, and turn a mob friendly or the reverse if you can (a duel). This build is the first to move and size SaftUI's plate frame in combat while the plate's click area is set to it, and the stubs can't show whether the game then treats the frame as protected.
34. Friendly nameplates: turn on the castbar and the debuffs with Health still off. On a friend, the castbar hangs 6 under the name box at its right edge and the debuffs sit 6 above its left edge, not shifted (they hang off the hidden health bar, which still fills the name box).
35. Friendly nameplates → Debuffs on, Size 30, Max 2. Among friendly units with debuffs (or in a duel area), a friend's debuffs are 30 and at most 2; on enemies they're 20 and up to 6. Out of combat, changing Size or Max applies at once, with no reload. In combat, with plates reused between a friendly guard and a mob, there's no Lua error, and the aura sizes catch up when combat ends (mixed sizes until then are expected). Friendly nameplates' debuff border and Cooldown → Show don't apply to plates while Enemy nameplates has its debuffs on (the followup on the Friendly page's aura borders and cooldown), and their tooltips on Friendly nameplates → Debuffs say so; on Enemy nameplates → Debuffs theirs say they make every plate's buttons.
36. Under Blizzard: target a friendly NPC (name only): no target art. Target an enemy: the art round its bar. Turn Health on on Friendly nameplates, then target a friend: the art round its bar. Then, on another unit: `/sui` → Unitframes → Target → Name → Color friendly on: a friendly NPC targeted has a green name, a player keeps their class color with Class color on, and with Color friendly off the NPC's name is uncolored, as before.

*Subtext (2026-11-12): the second line under a name, an NPC's title or a player's guild*
37. With default settings in a city: a vendor's or innkeeper's plate shows its title under its name in light grey angle brackets, once (`<Innkeeper>`, not `<<Innkeeper>>`), centred. A guard with no title has no second line and its name sits where it did. No plate shows a level line ("Level 80 Humanoid") or a pet's or guardian's owner line ("So-and-so's Pet").
38. A player in a guild shows `<Guild Name>` under their name, and one without a guild shows nothing. A guilded player the client hasn't seen this session: the guild appears on its own a moment later, without the plate leaving and coming back (`PLAYER_GUILD_UPDATE`). On Forever this is also the check that `GetGuildInfo(unit)` works there.
39. `/sui` → Unitframes → Friendly nameplates → Subtext (the tab after Name): NPC titles and Player guilds each turn their lines off and on at once; Font, Color, Opacity, Max width (a long guild name is cut) and Position all change the line with plates up.
40. Enemy nameplates → Subtext: both boxes start off. Turn NPC titles on: an enemy NPC with a title shows it centred under the castbar's row (is that the right place for it, or should it sit elsewhere?).
41. Enemy nameplates → General → Use friendly nameplates' settings checked: enemy NPCs' titles show under their names, from Friendly nameplates' Subtext settings. Friendly nameplates' Use enemy nameplates' settings checked instead: friends' subtext follows Enemy nameplates' boxes (off by default, so none).
42. A friendly NPC whose plate carries one of Blizzard's widgets (a quest progress bar, a capture bar): does the widget overlap the subtext? If it does, say which should move.
43. In combat, with plates reused between friendly NPCs and mobs: no Lua error from `nameplates/subtext.lua`, and no plate keeps another unit's title.
44. Restricted content (a dungeon with friendly NPC plates; a battleground with Enemy nameplates' NPC titles on): no Lua error from `subtext.lua` or `C_TooltipInfo.GetUnit`; a line the game hides is simply missing. Does a friendly NPC's title go missing and stay missing after such content ends, until its plate is re-added? (The tag checks the unit's kind each time it runs, and a secret answer blanks the line until the next name or guild event or full update.)

**Open questions:** Are the friendly plate settings kept per account (step 15)? If the borders still shimmer after a reload (step 2), are borders built from SaftUI's own textures worth it? Does a targeted name-only plate need a mark (step 26)? Does the game's click area follow the frame, or take a snapshot (step 32)? Is under the castbar's row the right default place for an enemy's subtext (step 40)? Does a plate widget overlap the subtext (step 42)?

### 2026-11-11 — Nameplates: a profile switch doesn't set the game's friendly plates

**What:** Friendly plates (`/sui` → Unitframes → Friendly nameplates → General since 2026-11-12, saved as `nameplate.friendly`) is a unit frame profile setting, but the game's two friendly plate settings it drives (`nameplateShowFriendlyPlayers`, `nameplateShowFriendlyNpcs`) are set only at login (`UF:OnEnable` runs `UF:ApplyNameplateCVars`) and when the toggle is clicked. Switching to a profile (a SaftUI profile or a unit frame profile) whose Friendly plates differs leaves the game's friendly plates as they were until the toggle is clicked or the UI reloads. Nameplates itself changes only at a reload anyway, since oUF makes its nameplate driver once. A related gap: Blizzard's own friendly plate options (Interface → Nameplates) and its key binding for them change the same settings without SaftUI's toggle following, and the next login or toggle sets them back to the toggle.

**Why noticed:** Task 6 of the nameplates plan (branch `np-6`), its concerns 2 and 3. Its brief named only the toggle and login as the places to set them, and Task 11 was changing the same part of `UF:ApplyConfig` at the time, so the profile switch was left out.

**Anchors:** `SaftUI-Unitframes/nameplates/cvars.lua` (`UF:ApplyNameplateCVars`), `SaftUI-Unitframes/unitframes.lua` (`UF:ApplyConfig`'s plate branch, which sets the plates' size again when no element is named; `UF:OnEnable`), `SaftUI-Unitframes/nameplates/options.lua` (`FriendlyNameplateGeneral`, Friendly plates' `set`), `tests/unitframes/nameplate_page_test.lua`.

**What's been considered:** One `UF:ApplyNameplateCVars()` in `UF:ApplyConfig`'s plate branch with no element, beside `UF:ApplyPlateSize()`, makes it follow every profile switch, copy and reset (`UF:UpdateConfig()` runs `UF:ApplyConfig()`, which includes the plates). It does nothing without SaftUI's driver or with Nameplates off, and waits out combat. For Blizzard's own toggle: leave it (SaftUI's toggle wins at the next login), or have SaftUI's toggle follow the game's setting (a `CVAR_UPDATE` listener writing the profile), which would make a key press change the profile.

**Shape of work:** Small: one call, and a profile switch case in `nameplate_page_test.lua`.

**Open questions:** Should Blizzard's friendly plate key binding change SaftUI's Friendly plates, or be undone at the next login?

### 2026-11-11 — UIParent's scale is set once, at login, so plates leave whole pixels after a UI scale or display change

**What:** Core works out `st.scale` once, as 768 over the screen's physical height when `SaftUI-Core/constants.lua` loads (`GetPhysicalScreenSize`), and sets it on UIParent once, in `SaftUI:OnEnable` (`SaftUI-Core/init.lua`), so that one UIParent unit is one pixel. Nothing sets it again. After Blizzard's UI scale setting changes, or the display does (a resolution or window size change), UIParent may no longer be at 768 over the screen's height. The nameplates pin each plate's frame to UIParent's effective scale, and pin every plate again on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (`SaftUI-Unitframes/nameplates/pixels.lua`), so they follow UIParent; but then a plate isn't a whole number of pixels wide or tall, and its right and bottom edges can flicker by a pixel either way as it moves, until a `/reload` sets SaftUI's scale again. Everything else of SaftUI's, laid out with one unit to a pixel, is off the grid the same way until then, so the README's "ignores Blizzard's UI Scale setting" holds only from one login to the next.

**Why noticed:** The review of Task 11 of the nameplates plan (whole-pixel plates, branch `np-11`). Its test for a UI scale change re-pins the plates, which keeps them on UIParent's scale, but whole pixels need UIParent itself at 768 over the screen's height.

**Anchors:** `SaftUI-Core/constants.lua` (`st.screenWidth`, `st.screenHeight`, `st.scale`), `SaftUI-Core/init.lua` (`SaftUI:OnEnable`), `SaftUI-Unitframes/nameplates/pixels.lua` (`UF:PinPlateScale` and its event frame), `UF.PlateDriverSize` (`SaftUI-Unitframes/nameplates/nameplates.lua`), `tests/unitframes/nameplate_pixel_test.lua` ("a UI scale change re-pins every plate and re-applies the size"), the README's Installation section.

**What's been considered:** Re-pinning the plates can't fix it alone: they follow UIParent, whatever its scale. The fix belongs in Core: on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`, work `st.scale` out again from `GetPhysicalScreenSize()` and set it on UIParent, then pin the plates again after it. Two frames' handlers for one event run in no set order, so the plates must be pinned after Core's handler (Core could call `UF:PinPlateScale` through the unit frames, or the plates could pin on the next frame). Whether Blizzard's own handling of its UI scale setting sets UIParent's scale after SaftUI's, and whether `UIParent:SetScale` is allowed in combat, decide the details.

**Shape of work:** Small, in Core: one event frame that re-applies `st.scale` on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (waiting out combat if it must), the plates pinned after it, a test with the stubbed screen size, and an in-game check (step 14 of "Nameplates: in-game checks").

**Open questions:** Does a change to Blizzard's UI scale setting set UIParent's scale over SaftUI's, on each client? Is `UIParent:SetScale` refused in combat?

### 2026-11-11 — Nameplates: a plate that turns widgets-only, or back, without a new add

**What:** oUF hides SaftUI's frame on a plate and pauses its elements only at an add, for a unit whose plate shows only widgets (`UnitNameplateShowsWidgetsOnly`) or a game object. When the game's friendly NPC plates setting changes (SaftUI's Friendly plates sets it), Blizzard runs `UpdateWidgetsOnlyMode` again on the plates already up, so a plate may switch to showing only widgets, or back, with no remove and add. oUF then leaves SaftUI's frame shown over a plate that shows only widgets, or hidden on one that's whole again, until the plate's next add; `UF:RefreshPlateWidgets`, which now also runs on the frame after anyone changes that setting, only places the widgets again and puts SaftUI's click area back on the plates SaftUI still shows (so a plate turned widgets-only in place takes clicks over SaftUI's frame, which still shows, where Blizzard's would take none). Separately, a config update while a plate shows only widgets runs each aura area's `SetEnabled(UF:ElementWanted(...))` on its paused container with the previous unit's kind (`frame.friendly`). That frame is hidden and the next add sets it right, and it was so before the nameplates too (it was `config.enable`).

**Why noticed:** Task 5 of the nameplates plan (branch `np-5`), its report's followups (a) and (c), after its review asked for `UF:RefreshPlateWidgets` and the stubs modelled the switch (`stub.set_nameplate_widgets_only`).

**Anchors:** `SaftUI-Unitframes/nameplates/nameplates.lua` (`PlaceWidgets`, `UF:RefreshPlateWidgets`, `OnPlateEvent`), `SaftUI-Unitframes/nameplates/cvars.lua` (`UF:ApplyNameplateCVars`), `SaftUI-Unitframes/elements/auras.lua` (`UpdateConfig`'s `SetEnabled`), `SaftUI-Unitframes/Libraries/oUF/ouf.lua` (the nameplate driver's widgets-only branch of `NAME_PLATE_UNIT_ADDED`), `tests/unitframes/nameplate_kind_test.lua`, `tests/wow/game.lua` (`stub.set_nameplate_widgets_only`).

**What's been considered:** `UF:RefreshPlateWidgets` could also pause and hide SaftUI's frame on a plate that turned widgets-only, and resume, show and re-apply the kind on one that turned whole, as oUF's add does, through oUF's own `PauseAllElements` and `ResumeAllElements`. Worth it only if the game really switches plates in place.

**Shape of work:** Small, after the in-game check (step 9 of "Nameplates: in-game checks").

**Open questions:** Does a friendly NPC's plate switch modes in place when friendly NPC plates is turned on or off, or does the game remove it and add it again?

### 2026-11-11 — Nameplates: small items left after the build

**What:** Small things the nameplates build noticed and left:
- `st:name`'s tag events (`SaftUI-Unitframes/tags.lua`) still list `PLAYER_TARGET_CHANGED`, which was there for the old nameplate target mark, now gone (the target's border replaces it). oUF's target frame updates its own tags on a target change (`Libraries/oUF/units.lua`), so the event now only makes every `st:name`, up to 40 plates' among them, run again on each target change. Task 2's ruling 10 left it; dropping it is one word.
- Every unit's castbar default (`SaftUI-Unitframes/config/default.lua`) has string offsets (`x_off = "0"`), which the game takes but the strict stubbed `SetPoint` refuses, so tests convert them (`blizzard_look_test.lua`'s `number_offsets`, the world in `nameplate_kind_test.lua`). The plates' defaults replace them. Worth making them numbers for every unit.
- Threat when solo's desc (Enemy nameplates' General, once the Nameplates page) says it tints the bars, but it also turns on the threat percent; the text's own Enable says so (Task 9's ruling 12). Its exact wording is tested in `nameplate_page_test.lua`.
- Copy from leaves the nameplates out both ways (Task 6's ruling 3): the game places every plate and gives them one size, and Nameplates and Friendly plates change the game's settings and need a reload, so a copy of General would be wrong, and a unit frame's layout doesn't fit a 200 by 20 bar. A user who wants the target's Health look on the plates sets it by hand. A Copy from limited to the element tabs, without their positions, could be added.

**Why noticed:** The reports of Tasks 2, 5, 6 and 9 of the nameplates plan (`.superpowers/sdd/2026-11-11-saftui-nameplates/`, not versioned).

**Anchors:** as each item names.

**Shape of work:** Each is small and stands alone: the first three a line or two with a test, the fourth a design question first.

### 2026-11-11 — Health text's Boss percent and Hide full with a secret health

**What:** Two of the health text's paths still read a secret health as a plain number, and error when the game hands them one (enemy nameplates and other units in restricted content). Boss percent (`boss_percent`, on by default for the units that can show a skull-level unit) compares `UnitLevel(unit)`, which can be secret, with `-1`, then `format`s the health (or its Short form) and the percent, both secret, into "1234567 | 45.6" (`getHealthPercentText`'s `format` and `floor`). Hide full (`hide_full`, on by default for raid10 and raid40) compares the game's secret deficit string (`C_StringUtil.TruncateWhenZero(UnitHealthMissing(unit))`) with `0`; that string is `''` at full health, so even where the comparison doesn't error it never hides the text.

**Why noticed:** The nameplates plan's Task 2 (`docs/superpowers/plans/2026-11-11-saftui-nameplates.md`) made the health text's Percent and value paths take a secret health: Percent draws the game's `UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)` through `SetFormattedText('%.0f', ...)`, as `UF:SetPowerPercentText` does; the value is passed to `SetText` as it is, or shortened by the game's `AbbreviateNumbers` with Short on. Plates show the value in short form (the user's answer 9 in the spec) with Boss percent and Hide full off, so they never reach these two paths, which were left out of scope. Before Task 2 the value path was safe without Boss percent, and the Percent path errored on `floor`.

**Anchors:** `SaftUI-Unitframes/elements/health.lua` (`PostUpdateHealth`, `getHealthPercentText`, `SHORT`); `SaftUI-Unitframes/updaters.lua` (`UF:SetPowerPercentText`, the pattern); `tests/unitframes/secret_texts_test.lua`; `tests/lib/secrets.lua`; `SaftUI-Unitframes/config/units/raid10.lua` and `raid40.lua` (`hide_full = true`).

**What's been considered:** Boss percent could join the parts in the game: `SetFormattedText('%s | %.1f', text, UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))`, with the skull check made only on a plain level (or on `UnitClassification(unit) == 'worldboss'`, whose documentation marks no secret return on either client, though a boss frame's unit may still differ in game). Hide full has no game function that answers "is this secret zero" to an addon; a step curve through `UnitHealthPercent` into the text's alpha might, if the alpha setter takes a secret from an addon.

**Shape of work:** Small: two branches of `PostUpdateHealth` and cases in `tests/unitframes/secret_texts_test.lua`, after checking in game which unit values are secret on a boss frame and a raid frame on each client.

**Open questions:** Is a boss's level secret on the boss frames in restricted content, on Forever and on retail? Does any text setter take a secret alpha or shown state from an addon, for Hide full?

### 2026-11-11 — Purge filters: in-game checks

**What:** "Only buffs I can purge" (a toggle on every unit's Buffs, on by default for nameplates) builds Blizzard's aura container filters from facts the stubs can't confirm: which dispel name an enrage reports on each client, whether `RAID_PLAYER_DISPELLABLE` lets a Frenzy through for a Forever hunter, and whether the pet's spellbook is ready when the filters are first built at login.

**Why noticed:** Task 10 of the nameplates plan (branch `np-10`) and its review. Blizzard's candidate filter matches `includeDispelTypes[auraData.dispelName]`, and an aura's dispel name is its type's internal name in `SpellDispelType`. Type 9 (an enrage; "Frenzy" on Forever) has no internal name on Forever 1.60.1.70888, and had none on retail before 12.1 (empty at 12.0.7.68974 and 11.2.7.64978, "Enrage" at 12.1.5.70783, wago.tools). Blizzard's own `Blizzard_PrivateAurasUI.lua` checks `dispelName ~= ""` on both clients, so an empty name most likely reports `''`. `aurafilters.lua` therefore matches an enrage as both `'Enrage'` and `''`, on both clients. If a client reports `nil` instead, no candidate filter can pick enrages out, and a player whose only remover is an enrage one (a Forever hunter's Tranquilizing Shot, a retail druid's Soothe, a rogue's Shiv) sees no buffs with the toggle on.

**Anchors:** `SaftUI-Unitframes/aurafilters.lua` (`DispelNames`, `UF.PurgeFilter`, `UF:KnownRemovals`, `UF:RefreshPurgeFilters` and its event frame), `SaftUI-Unitframes/elements/auras.lua` (`AddGroup`, `UpdateConfig`), `tests/unitframes/purge_test.lua`; `.superpowers/sdd/2026-11-11-saftui-nameplates/task-10-report.md` (not versioned).

**What's been considered:** Matching `''` too costs nothing: `RAID_PLAYER_DISPELLABLE` keeps only auras someone in the group can dispel, so `''` can't let in a buff with no dispel type. If a client reports `nil`, the choice is between dropping the dispel type filter for players who remove only enrages (showing everything `RAID_PLAYER_DISPELLABLE` lets through, which in a group includes other classes' magic dispels) or showing them nothing.

**Shape of work:** A pass by the user, out of combat (aura data is secret in combat), then a small fix in `aurafilters.lua` if a check fails:
1. Forever, as a hunter with Tranquilizing Shot, Target's Buffs with Only buffs I can purge on: target a mob with a Frenzy buff (Molten Core's Magmadar or Flamegor, or a beast that frenzies). Does the buff show? `/dump C_UnitAuras.GetAuraDataByIndex('target', 1, 'HELPFUL').dispelName` (the buff's index in place of 1): `""`, `nil` or `"Enrage"`?
2. If it doesn't show: `/dump C_UnitAuras.IsAuraFilteredOutByInstanceID('target', <its auraInstanceID>, 'HELPFUL|RAID_PLAYER_DISPELLABLE')` (false means the filter string lets it through, so the dispel name is what blocks it).
3. Retail, as a druid with Soothe or a rogue with Shiv: the same two checks on an enrage (most dungeon enrages).
4. Either client, as a warlock with the felhunter out: `/reload` with the toggle on, and the target's magic buffs show right after login. Dismiss the felhunter and summon it again: they go and come back.
5. Forever, a protection warrior with Shield Slam: magic buffs show.

**Open questions:** If Forever reports `nil` for a Frenzy, should a Forever hunter see every buff the group can dispel, or none?

### 2026-11-11 — Purge table: retail gaps

**What:** Retail class spells that take a buff off an enemy but aren't in `UF.PURGE_SPELLS`: the monk's Paralysis 115078 (its effect #2 dispels an Enrage; a talent) and the priest's Mass Dispel 32375 (a talent; its dispel effect, Magic, is aimed at an area, `ImplicitTarget` 31, so whether it reaches enemies directly or through another spell needs a look). Mass Dispel matters only for a priest without Dispel Magic. Racials (the Blood Elves' Arcane Torrent, an area Magic dispel) are out of scope: the table is by class.

**Why noticed:** The review of Task 10 of the nameplates plan (branch `np-10`) swept wago.tools' `SpellEffect` at 12.1.5.70783 for every dispel or steal effect on a spell with a class skill line or a talent, beyond the spec's list. Neither spell exists on Forever 1.60.1.70888.

**Anchors:** `SaftUI-Unitframes/aurafilters.lua` (`UF.PURGE_SPELLS.live`, and the comment above it on how each spell was checked), `tests/unitframes/purge_test.lua` (`VERIFIED`, which pins the table: a new spell goes in both).

**Shape of work:** Small: check each spell's effects (and Mass Dispel's triggered spells) at the current build, add `MONK = { { id = 115078, removes = { 'Enrage' } } }` and Mass Dispel to `PRIEST` if it dispels enemies, and add them to `VERIFIED`.

**Open questions:** Should Paralysis count? It's a crowd control that happens to remove an enrage, not a purge a monk would think of.

### 2026-11-11 — Blizzard theme round 2: in-game checks

**What:** Round 2 of the Blizzard theme (`/sui` as Blizzard's Settings window, unit frame borders, the micro menu bar) was built and tested on stubs, which model neither the game's layout, frame levels, draw order, texel snapping, slicing, the cursor nor combat protection. These steps need a look in game. Run each under Blizzard on Forever (the user's client) and, where marked, on retail, then under Thick to check nothing moved. Fix what is found; every value named here is a starting value from the plan or the spec, tuned in game.

**Why noticed:** The plan's "In-game check list" and every task's report and review (`.superpowers/sdd/2026-11-11-saftui-blizzard-theme-round2/`, task-N-report.md and progress.md, not versioned) named what the stubs can't show. This entry merges them, grouped by area, so the user can run them in one pass.

**Anchors:** `docs/superpowers/plans/2026-11-11-saftui-blizzard-theme-round2.md` (the check list at its end), `docs/superpowers/specs/2026-11-11-saftui-blizzard-theme-round2-design.md`, branch `round2`; `SaftUI-Core/themeart_data.lua` (the art tables: `unitframe`, `groupborder`, `unitbars`, `microbar`, `resizegrip`), `SaftUI-Core/Config/optionslayout.lua` (`OW.LAYOUT`), `SaftUI-Core/Config/optionswidgets.lua`, `SaftUI-Core/Config/optionsbody.lua`, `SaftUI-Bags/categoriestab.lua`, `SaftUI-Unitframes/groups.lua`, `SaftUI-Unitframes/updaters.lua`, `SaftUI-Minimap/micromenu.lua`.

**What's been considered:** Where a check fails the fix is usually a number in the art tables or the layout (offsets, slice margins, outsets), or one of the fallbacks the spec names: cutting the micro menu strip's pieces by texture coordinates as the bronze box is, cutting the scroll thumb's middle instead of stretching it, offsetting the select list by the c-bg's outset.

**Shape of work:** A pass by the user, then one small fix task per area that fails. The steps:

*`/sui`'s frame (both clients)*
1. Switch to Blizzard with `/sui` open: it grows to 1110 x 728 without a reload; the metal's frame has "SaftUI Options" centred in its title bar in the window-title font, and the red close button sits in the socket and closes the window on a click (not a drag). The socket spot is right on Forever (0, 3 from the window's top right) and on retail (1, 0).
2. The inner frame's bronze rim and dark edge run from under the title bar to just above the Reload UI / Close row over the sidebar and the settings; its drawn divider is on the sidebar's right edge (242 wide) and its vignette isn't over any text. Reload UI and Close are 16 in from the window's bottom corners, clear of the metal's bottom, and the footer's buttons are clear too.
3. The window fits your screen inside the edge margin, and dragged to the screen's top, the metal's top (16 above the window) isn't cut off: it stops at the margin. Set Global Settings > General > Screen edge margin to 0 and try again: the metal's rim still stays on screen.
4. Drag the window by its title bar, close it and reopen it: it opens where you left it. Under Thick, drag by the brand: the same.
5. Under Blizzard: no "SAFTUI / Options" brand; Edit mode and Keybind mode buttons at the sidebar's top; the profile's name at the sidebar's bottom inside the inner frame.
6. Scroll a long page (Unitframes > Player) part way and switch Thick to Blizzard and back: the same page at the same scroll. On Bags > Categories, switch: the editor still fills the tab. Switch to a profile whose theme is Blizzard and back with `/sui` open: it lays out again each time.
7. Thick: exactly as before: 1040 x 700, the brand top left, the close X top right, the footer under the main column.

*The sidebar*
8. FRAMES, COMBAT and INFO are on the Settings banners (cycling 1, 2, 3); each banner's art hangs below the header without covering the first entry's text (the banner is 144 tall).
9. Entry names are gold; the open page's and the one under the mouse are white; the open page is on the active art and the hovered one on the hover art. A disabled entry doesn't light white.
10. Under Blizzard there is no section rule in any page, no footer line and no sidebar fill; the tab row's line is Blizzard's divider; the vertical dividers between halves stay. Under Thick the fill, the lines and the grey 29-tall headers are back.
11. Make the sidebar overflow (raise the UI scale): a narrow scroll bar sits left of the divider, its arrows scroll two rows. Under Thick it has none.

*Controls*
12. Nested clipping on Bags > Categories: the editor's bar is inside the body's clip; the rule editor's dropdown faces aren't cut at the editor's edges; a dropdown in the body's right column shows its glow whole at the body's right edge (a select's 7px glow may be clipped 2px at the body's or a dialog's first and last row and on the left at x = 0: say if it shows).
13. Dropdown faces: a select (Global Settings > Theme > the Theme select is the long one) shows the bronze Settings button, text centred; hover lights the face and shows the small arrow under it; press shows the pressed face and nudges the text; the face looks open while its list shows. The face's rounded ends stretch cleanly at 109 and 170 wide. A compact dropdown (Unitframes > Player > Health > Text > TO, and the rule editor's fields in Bags > Categories) has the smaller glow, no hover arrow and clears the box under it.
14. Open a select's list: it sits on Blizzard's menu art (bronze border and shadow) with no tooltip border; rows light on hover. The c-bg reaches 12 above the list, over the button's bottom (22 when the list opens upward): if the opaque part covers the button, the list should sit lower under Blizzard.
15. Steppers: a select with short choices has the bronze back and next steppers at its ends with the face between at 109; hover, press (the triangle nudges 2 right, 1 down) and let go look right; the face doesn't light while the mouse is on a stepper or in the 4 to 5px gap beside it. Click next until the last choice: the setting changes each click exactly as picking it does, next greys at the end, back works the same, nothing wraps. A disabled select has both steppers grey and clicks do nothing.
16. The Theme select ("Use SaftUI's theme") has no steppers and its face is the full 170. Unitframes' unit picker (longest name "TargetTarget") and Action Bars' extras ("Zone ability"): say whether they came out with or without steppers, and whether that's what you expect (83 of room for the text). Global Settings > Fonts: every font select has no steppers and opening the page doesn't hitch.
17. The Profiles page, with a second profile: Copy From and Delete show the full 170 face with no steppers (only their list picks; Delete still asks first), so no click copies or deletes a profile by itself. The current profile's select (Choose) keeps its steppers when every name it lists fits (a long "Character - Realm" name won't, and then it has none).
18. Check boxes at 30 x 29: lined up with their labels, spilling left and up past the 18 box as Settings' do; a click on the box's left edge toggles it; the multiselect's and check list's rows are 23 x 22 with their hover. The 12px spill overlaps the label's last 2px only on a full-width label (say if it shows).
19. Slider arrows: each arrow steps the value and the box updates; greyed at the ends; both greyed on a disabled slider; under Thick no arrows and the track runs full width.
20. Scroll bars: on a long page (Unit Frames) a gold-rimmed minimal bar 12 right of the rows, its arrows at the body's top and bottom, clear of the inner frame's right rim. Drag the thumb; click both arrows (two rows each); click the track above and below the thumb (a page each); the wheel scrolls two rows, also over the bar. Hover and press the thumb and arrows. The thumb's middle (an 8 x 715 stretch) doesn't look squashed when tall. The arrows and track don't repeat while held (Blizzard's do): say if it matters. A page with nothing to scroll shows no bar. The narrow bars: the sidebar's, the Categories list's and a long dropdown list's (a font list: an arrow moves a row, a drag scrolls it). The 3px bars are back under Thick.

*Growing taller (every theme)*
21. The bottom edge (the 6px strip left of the corner) and the grip both drag; the top stays put; it stops at 700 (728 under Blizzard) and with its bottom at the edge margin. Hover the grip under Thick: the corner arrow takes the hover color.
22. The height comes back after `/reload`, and after a theme switch. A move alone saves no height: with none saved (`/run SaftUI.config.global.optionsWindow = nil`), move /sui under Blizzard and switch to Thick: it is 700 tall, not 728.
23. Under Blizzard the inner frame stretched taller (its vignette and rim) looks right; Blizzard's grip in the metal's bottom right corner shows, takes the mouse, lights on hover, darkens when pressed and stays clear of Close.
24. On a long page the scroll bar follows the drag (and the sidebar's); on the Categories tab nothing redraws while the mouse is held, then once on release with the list and editor taller.
25. A product call: under Blizzard the most height leaves room for the metal (1016 on Forever and 1020 on retail, against 1040 for the window alone) and `/sui` stops 16 further from the screen's top. Say if that is acceptable. A centred window at its most height may be pushed 4 down by the game's clamp.
26. A lower resolution or a raised UI scale, then `/reload`: `/sui` opens no taller than the screen allows and never under its least.
27. Open `/sui` at its most height (drag the grip as far as it goes), then raise Global Settings > General > Screen edge margin: the window shrinks at once, its scroll bar following; lower it again and it grows back, up to the saved height.
28. On Bags > Categories, drag the grip up and down slowly: no scroll bar of the page's own flashes over the tab's list, editor or footer bars while the mouse is held; let go and the tab draws once at the new height.

*Bags > Categories*
29. The list: the picked row has the gold-bordered active art and a white name, the others are gold and show the hover art, an off category is grey and struck, the drag line shows when dragging, and Thick brings back the blue bar and tint. Its handles and counts are as before.
30. The footer: pick Grays/Auto Vendor. The editor ends at Reset; a line across the editor's column (a 1px line, or Blizzard's divider under Blizzard) with Caught now above Pinned items under it at the tab's bottom. Scroll the rule with the wheel: the footer stays put and the lit block and the icon are in view together. Hover a gray: its rule block lights and its tooltip opens beside the window. A pin's X unpins it and the footer shrinks.
31. A category that catches many items (or 80 pins): the footer stops at half the tab with its own bar and the wheel over it scrolls only it; another category starts at the top. Under Blizzard the footer's bar is Blizzard's minimal bar ending at the footer's bottom and the editor's ends at the footer's top line. The icon ring and X on the footer's icons draw over the icons (see "Blizzard theme: in-game checks"), and nothing in the footer is clipped at its edge.
32. A bag update while the Categories tab is open and a scroll thumb is held doesn't end the drag.
33. Under Blizzard, hover a Caught now or a Pinned items icon: its tooltip sits 4 out from the metal's edge (the metal reaches 8 past the window's left, 2 on Forever and 4 on retail past its right), not on its rim; under Thick 4 from the window as before.

*Unit frames (both clients)*
34. The bronze box: the player's frame at 301 x 34, a 120-wide pet or target of target, and the player's 299 x 20 power bar: the corners meet the edges with no step or gap, no blur or seam on the top and bottom edges, the dark Background inside. Forever shows bronze (its Camelot member's file), retail grey and gold. Resize a frame: the corners stay 8 x 8 and the edges stretch. If a seam shows, the rectangles in `ART.unitframe` are the values to tune.
35. One box per edge: the player frame with its own Theme set to "Use SaftUI's theme" has one bronze box and no doubled rim where health sits in it. Player > Health: Height -4 (Relative on) shows a second box inside the frame's; back to 0 and one box again; the same with Y offset -1.
36. A bar under 12 on a side draws a thin 1px line with a dark fill and no bronze corners (the 5-tall power bar, Target > Power with Enable on); at 12 or more it becomes the bronze box. Say whether the thin bar looks wrong beside its boxed neighbours.
37. The separate power bar and the castbar have their own box; the target's castbar has a box; the boss castbars (Thin) show a 1px line. Boss test mode: the previews have boxes like the real frames.
38. The group border around party, raid10 and raid40 (57 x 30 members, 3 apart): a thin rounded border about 2px outside at the left, top and right and 3 below, and members show no border of their own. Someone joining or leaving in combat moves the border with the frames and BugGrabber shows no `ADDON_ACTION_BLOCKED`. Check the corners and edges are crisp with no seam and no stray dark band inside the frames (Forever's dark inner 4px in the party's gaps); tune `ART.groupborder`'s offsets and 6px slice if the rim reads too far in or out. Raid40 with a partial last column.
39. Which Theme turns the border on: Party > General > Theme: Thick removes it and each member shows Thick's border; back to None, then Health > Theme: Thick removes it; Health back to "Use SaftUI's theme" brings it back. Party test mode out of a group sits in the same border; Thick and Thin show none.
40. With the Party's Show player off, invite someone and leave the invite pending: no bronze strip where the party frames go; once they join the border shows around their frame.
41. Bar fills: class colors on `RaidFrame-Hp-Fill` read as class colors and not muddy (and by reaction on a target); the resource fill on power; a picked health texture stays; health Theme None is flat; under Thick a bar on SaftUI Flat is flat with a flat, untiled background (a picked texture shows under every theme); the castbar is unchanged; power stays filled while ticking; party and raid power too. After a Blizzard to Thick switch the background is flat.
42. The bar fills are an atlas set on each bar's own status bar texture (`GetStatusBarTexture():SetAtlas`): at 30% health and at part power the fill is cropped, not squashed, and `_RaidFrame-Resource-Fill` shows no art of its atlas neighbours at the end. If it squashes or bleeds, set the bar's texture with `SetStatusBarTexture(atlas)` instead (`UF:SetBarFill`, `SaftUI-Unitframes/updaters.lua`).
43. The health background `raidframe-hp-bg-white` tiles both ways behind the fill with no stray art and no seams at the frame's size.
44. A power texture you picked (Player > Power > Texture) now shows under every theme, Thick included: before round 2 each power update put the flat one back under Thick.

*The micro menu bar*
45. Forever: the zone, clock, latency and FPS boxes each show the bronze header button, 23 tall and centred in the row, with the text readable on it; the tight cases are the 48-wide latency and FPS boxes (its two ends leave 4 between them if the margins are halved) and the header's art at 200, 60 and 48 wide.
46. Forever: the addon compartment ("18"), expansion, mail, difficulty and queue eye stand on the bronze square (mail's icon fills its whole box today and may cover the square: say if it should shrink). Search shows Blizzard's tracking button with its magnifier drawn in and no second one; the flat hover shows over each box.
47. Forever: the bronze strip behind the micro buttons is 33 tall on the 25 row, 4 above and below the boxes, with a crisp rim and chamfered ends not squashed (its slice margins, 16 and 20, are taken to be the `-2x` member's texels, 8 and 10 UI units: if the ends look squeezed, cut the pieces by texture coordinates instead, as the spec allows), its background 2 inside the rim, under Blizzard's buttons with their own bronze squares on top, and clear of the FPS box and the square after it.
48. Hide a micro button (change level or region): the strip shrinks to the shown run. Mail and the queue eye coming and going close the bar up and their boxes go with them. In combat, a mail or queue pop: the strip and boxes follow with no `ADDON_ACTION_BLOCKED`.
49. In a vehicle and in a pet battle, where Blizzard moves its buttons out of the bar but the holders stay: nothing of Blizzard's frame art shows, and say whether an empty strip there looks wrong.
50. Switch to Thick and back with `/reload` first: Thick brings back today's small frames and removes the strip; Blizzard brings everything back with no reload.
51. Retail: the grey minimap button kit on every box, at each box's size (the 200 wide zone, the 60 clock, the 48 latency and FPS boxes, the 25 squares), its corners whole and its edges stretched, and no strip; the tracking icon is Blizzard's own; the instance difficulty button's own purple fill covers its box (left as it is).

*A theme switch in combat*
52. Switch the theme (Global Settings > Theme, or a profile switch to a profile with another theme) just before a pull so it lands in combat: the unit frames, the group border, the bar fills and the micro menu art change together once combat ends, with nothing blocked (BugGrabber, `/console taintLog 1`); `/sui` re-lays at once (closed by combat, it opens in the new look).

*Thick and Thin, last*
53. Switch to Thick, then Thin: `/sui`, every unit frame, the group frames and the micro menu bar look exactly as they did before round 2 (the 5-tall power bar's drawn kind is now `small`, which looks as a bar).

**Open questions:** Items 14, 16, 25, 36 and 46 ask the user for a call, not only a pass or a fail.

### 2026-11-11 — Blizzard theme: a border per real raid group, not per header

**What:** Under Blizzard the group border is one frame around each secure header: one around the party, one around the whole raid (raid10 or raid40). A border around each real raid group (the five players of group 1, of group 2, ...) as Blizzard's raid frames draw with Keep Groups Together on isn't there. A raid header fills rows of five in group order, so a row is only a real raid group while every earlier group is full.

**Why noticed:** The round 2 spec's "My call: one group border per group header" (`docs/superpowers/specs/2026-11-11-saftui-blizzard-theme-round2-design.md`, Party and raid frames), which names a border per real raid group as "a followup if wanted". Task 14 built the one-per-header border.

**Anchors:** `docs/superpowers/specs/2026-11-11-saftui-blizzard-theme-round2-design.md` (Party and raid frames); `SaftUI-Unitframes/groups.lua` (`UF:CreateGroupHeaders`, `UF:GroupBorder`, `UF:UpdateGroupBorder`, `UF.GroupBorderShown`); `SaftUI-Core/themeart.lua` (`ART.groupborder`, `ThemeArt.PaintCut`); `.agents/architecture.md` (Unit frames).

**What's been considered:** A border per real group needs a secure header per group (a header with `groupFilter` set to one group, for eight headers in raid40), which is a rework of how the raid frames are made, laid out and moved in edit mode (`UF:ApplyGroupLayout`, the group's holder and mover), not a change to the border.

**Shape of work:** A design pass first (eight headers or one with its rows split, the layout sums, the holder and the mover), then a task for the headers and one for the border per header, which would reuse `UF:GroupBorder` unchanged.

**Open questions:** Does the user want the border per real raid group at all, given a single border around the raid already reads as Blizzard's with Keep Groups Together off?

### 2026-11-11 — /sui: no resize cursor on the grip and the bottom edge

**What:** `/sui` grows taller by its grip and its bottom edge, but neither shows a resize cursor on hover. The 6px bottom edge has no visual cue at all, and the grip's only cue is its highlight.

**Why noticed:** Round 2's Task 10. Blizzard's `PanelResizeButtonMixin:OnEnter` calls `SetCursor('UI_RESIZE_CURSOR')`; the task's brief didn't ask for it and `SetCursor` isn't stubbed.

**Anchors:** `SaftUI-Core/Config/optionsresize.lua` (`F.grip`, `F.sizer`, `StartResize`); `tests/wow/` (no `SetCursor` stub); `SaftUI-Core/skinning.lua` (`st:EnableResizing`, which also sets none).

**What's been considered:** `SetCursor` on `OnEnter` and `SetCursor(nil)` on `OnLeave` and while the resize is held, on both handles, with a `SetCursor` stub that remembers the last cursor. Whether to do the same for `st:EnableResizing`'s windows is a question for the same change.

**Shape of work:** A few lines in `optionswindow.lua`, a `SetCursor` stub in `tests/wow/widgets.lua` or `game.lua`, and one test.

**Open questions:** Do the in-game checks show the edge needs a cue at all?

### 2026-11-11 — Screen edge margin: art reach only for /sui

**What:** `st:KeepInScreenMargin(frame, reach)` can keep a frame's art, not just its rect, inside the margin, but only `/sui`'s window passes a `reach` (the metal's, under Blizzard). The bag, bank and combined bank windows, whose header sits in the metal's title bar above the window, still clamp their rect only, so at a margin under 20 their title bar can go off the top of the screen. *Update 2026-11-11 (round 2's final fix wave):* the entry's second loose end, a margin change while `/sui` is open at its most height not shrinking it until the next open, is fixed: `optionswindow.lua`'s `Build` hooks `st:UpdateScreenMargin` to `ApplyHeight` (`optionsresize.lua`), tested in `tests/core/options_resize_test.lua`. What is left is the art reach for the bag windows.

**Why noticed:** Round 2's Task 2 carried the art reach to Task 10, which did it for `/sui` only (the window's resize also stops where the metal meets the margin) and found the height not re-applied on a margin change (its ruling 12); its review parked "hook `st:UpdateScreenMargin` to re-apply `WindowHeight`", which the final fix wave did.

**Anchors:** `SaftUI-Core/api.lua` (`st:KeepInScreenMargin`, `st:UpdateScreenMargin`); `SaftUI-Core/Config/optionslayout.lua` (`ArtReach`, `Margins`, `OW.MaxHeight`, `OW.WindowHeight`); `SaftUI-Core/Config/optionswindow.lua` (`Relayout`); `SaftUI-Core/panels.lua` (`st:CreateHeader`, `st:HeaderInTitleBar`); `SaftUI-Core/themeart.lua` (`ThemeArt.MetalReach`); `tests/core/screen_margin_test.lua`; "Blizzard theme: in-game checks" (the bags' margin item).

**What's been considered:** `st:CreateHeader`'s windows could pass `ThemeArt.MetalReach` while the header is in the title bar and re-apply on a theme change, which also needs the bags' mover anchor and edit mode's outline to agree (the existing in-game-checks entry names that).

**Shape of work:** A small change in `panels.lua` plus the bags' anchors, with an in-game look.

**Open questions:** Does a margin under 20 matter to the user enough to do it?

### 2026-11-11 — Blizzard theme round 2: test gaps and small items parked in review

**What:** Small items the round 2 reviews found and parked for a final fix wave. Strike the ones the wave took. *Update 2026-11-11:* the final fix wave took the struck ones. Three are left: an optional test, and two behaviours of Blizzard's that SaftUI's bars don't copy.
- ~~`ThemeArt.Cut` (`SaftUI-Core/themeart.lua`) guards a missing file but not nil texture coordinates in the atlas info: it should hide the texture, not error. The test "a cut with no atlas file hides its pieces" should restore `C_Texture.GetAtlasInfo` itself.~~ Done.
- ~~Micro menu: `tests/minimap/blizzard_look_test.lua` has no Thin check (one line), and `micromenu.lua` should say in a comment that the strip is deliberately unprotected (SaftUI's own frame, never protected, so the `SafeReposition` function always runs at once).~~ Done.
- ~~Check boxes: the sizes test (`tests/core/options_widgets_test.lua`) lacks an unchecked and a disabled toggle pass and the multiselect's unchecked row, and doesn't pin the hover's size at 23 x 22.~~ Done.
- ~~Dropdown: a comment on `LookDropdown` that the compact face and `HoverArrow` are created once per look change.~~ Done.
- Slider arrows: ~~tests for a failing validator blocking a step, 0.1 x 10 landing on 1, a `bigStep`-only option~~ (done), and an off-grid value stepping to the next grid point by direction (left: today a value off the grid steps by the step and then snaps, so 5 on a grid of 10 goes forward to 20, not 10; a test would pin a behaviour change, not today's).
- Scroll bars: ~~tests for a rows-unit drag, `OnHide` mid-drag and the nav with nothing to scroll~~ (done; a theme switch can't hide a bar mid-drag, since the render waits for the held thumb, so the `OnHide` test is combat closing `/sui` mid-drag); left: the pressed arrow's 1, -1 displacement (`ButtonStateBehaviorMixin`) isn't drawn, and a track click pages once per press where Blizzard's repeats while held (the round 2 in-game checks ask whether the repeat matters).
- ~~Categories list: a test pinning one tinted row only, and the Thick hover's color and alpha plus `OnLeave`.~~ Done.
- ~~`/sui` resize: skip `SetScroll` mid-drag on a fill page (`filledTo`); a test that `OnHide` ends a resize; `tests/core/options_window_test.lua` near line 2059 should stand alone and `tests/core/options_settings_test.lua` near line 889 calls `st:UpdateScreenMargin()` for its own setup.~~ Done.

**Why noticed:** The reviews of Tasks 4, 5, 7, 8, 9, 10, 12 and 17 of the round 2 plan (`docs/superpowers/plans/2026-11-11-saftui-blizzard-theme-round2.md`), each Approved with these left for the final fix wave. The review notes live in the plan's ledger (`.superpowers/sdd/2026-11-11-saftui-blizzard-theme-round2/progress.md`, not versioned), so they are recorded here.

**Anchors:** the files named above; `tests/core/theme_blizzard_draw_test.lua`, `tests/minimap/blizzard_look_test.lua`, `tests/core/options_*_test.lua` (the widget tests, on `tests/core/options_widgets_helpers.lua`), `tests/bags/categories_*_test.lua` (the Categories tab's tests, on `tests/bags/categories_world.lua`).

**Shape of work:** What's left: the off-grid step is a small behaviour call (step to the next grid point by direction, as Blizzard's slider does?) with its test; the arrow displacement and the held repeat wait on the in-game checks.

### 2026-11-11 — Categories tab: the scrolled editor's two gaps

**What:** Since the Categories tab's list and editor scroll on their own, two things in the editor were left as they were. The rule editor's block drag has no edge scroll: the list scrolls while a dragged category is held near its top or bottom edge, but a dragged block held near the editor's edge doesn't (the wheel does scroll the editor mid-drag). And hovering a Caught now icon lights the block that caught it without scrolling the editor to it (on purpose: a scroll on hover would move the icon away from the mouse), so the lit block can be out of view. *Update 2026-11-11 (Blizzard theme round 2, Task 11):* Caught now and Pinned items now sit in a fixed footer at the editor's bottom, so Caught now stays in view under the rule and the icon no longer scrolls with the editor; with the editor scrolled to the block, the block and the icon are in view together. What is left of the second gap: a lit block can still be out of the editor's view when the rule is taller than the editor's view (the tab less the footer), and the wheel over the icon scrolls the footer, not the editor.

**Why noticed:** The 2026-11-11 change that gave the tab its two scroll areas (user feedback, screenshot 112: scrolling the list down to Quest scrolled Quest's editor out of view). The brief asked for the list's edge scroll only, and for the hover not to scroll. Measured then, on the shipped categories at the default window size: the tab is 483 high; only Grays/Auto Vendor (653 on Forever, 697 on retail) and Container (523, 567) need the editor to scroll, and every shipped rule plus the Caught now strip spans at most 457 (Grays), so both fit in view together, but only with the editor scrolled to show both. Those figures are out of date since the footer (the editor's view is the tab less the footer, at most half the tab). A longer rule of the user's still makes the lit block go out of view.

**Anchors:** `SaftUI-Bags/categoriestab.lua` (`EdgeScroll`, `DrawDrag`, `ScrollEditor`, `ScrollFooter`, `SplitFooter`, `HighlightWhy`); `SaftUI-Bags/ruleeditor.lua` (`DrawDrag`, `StartDrag`, the `bagrule` type); `tests/bags/categories_scroll_test.lua` (the scrolling tests; two scrolled drags are in `categories_drag_test.lua`).

**What's been considered:** The edge scroll could be the tab's: while `EditorDragging(w)`, an OnUpdate on the tab's frame runs the same band test against `w.editorScroll` and calls `ScrollEditor`; the rule editor's own `DrawDrag` already redraws its line from the rows each frame, so the line follows. For the hover, an arrow or a mark at the editor's top or bottom edge when the lit block is out of view would say where it is without moving anything.

**Shape of work:** A small change in `categoriestab.lua` for the edge scroll, with a test like the list's. The hover marker is a small design question first.

**Open questions:** Does the user want the hover to show anything when the lit block is out of view?

### 2026-11-11 — Blizzard theme: in-game checks

**What:** The Blizzard theme (branch `blizzardtheme`, spec `docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md`, plan `docs/superpowers/plans/2026-11-10-saftui-blizzard-theme.md`) was built and tested on stubs (`tests/run`), which model neither the game's layout, frame levels, draw order, texel snapping nor combat protection. These need a look in game, and a fix for what's found. The user plays Forever, so the retail items need a retail session.

Both clients, measured values the spec left to the builder (`SaftUI-Core/themeart.lua`, `KINDS` and `ART`, read per client at call time):
- each kind's inset (window 2, panel, bar, tooltip, action and slot 3, aura 0, small 1) and the metal's corner offsets and title bar (20 on Forever, 21 on retail): the art should meet the content with no gap and no overlap;
- the ring's layer: on a button of SaftUI's it's a texture in ARTWORK below 0, so it should lie over the icon's edge and under the count, texts and cooldown; the item ring is cropped to Blizzard's 37-in-64 fit, so check it on every slot size the bags can have;
- texel snapping is off on the metal (Blizzard's `disableSharpening`): the pieces should show no seams and no shimmer at the user's UI scale;
- the size of SaftUI's check boxes and panel buttons (the Settings box 1px outside the 12px button, the panel button's ends 12/22 of its height): Blizzard's art should fit the space SaftUI's look had;
- class power art at the row's height (`config.height`): the empty and filled art; with a point full, no flat bar over the art, at value 0, and after a color change (the flat fill is hidden by alpha, `ApplyArt` in `SaftUI-Unitframes/elements/classpower.lua`);
- the edit box alpha check: chat's edit box and an input box show their own border under Blizzard and none under Thick and Thin, with `SetAlpha` only (`st:SkinEditBox`), and the focus textures chat shows and hides still behave;
- a theme switch in and out of combat: switching Theme, or a profile switch to another theme, with a bag open, chat shown and unit frames up, both out of combat and in it (it waits for the end of combat and runs once); nothing errors and no `ADDON_ACTION_BLOCKED` blames SaftUI (`/console taintLog 1`).

Buttons and controls (both clients):
- the HIGHLIGHT and Pushed texture layers on SaftUI's buttons and the panel button's `PostClick` on real clicks;
- the radio group's flipped tab art at 140x30;
- `GetAtlas` after `SetTexCoord` on a piece that has been cropped;
- the scroll track against its steppers (anchored TOP -2 and BOTTOM 2);
- `InputBoxTemplate`'s left end sits 5px outside the bags' search box;
- `/sui`'s range slider under Blizzard: its track and thumb are centred on half pixels (`LookRange`, `SaftUI-Core/Config/optionswidgets.lua`), so check them for blur.

Slots under Thick and Thin (both clients): the hover on a bag, bank, currency or bags bar slot is a blue tint over the icon, not an opaque blue square. `st:SkinActionButton` (`SaftUI-Core/skinning.lua`) now puts back the blend `SetHighlightTexture` gave the hover when it was made, which the stubs take to be ADD (the final review found it forced to BLEND); check that's the client's default too. 2026-11-11: in game every slot and action button showed the blue all the time, not just under the mouse, because the theme work had moved the hover out of the HIGHLIGHT layer (fixed in 8b4ef2f, every look); recheck the tint under the mouse after that fix.

Window headers in the metal's title bar (both clients; `st:HeaderInTitleBar`, `SaftUI-Core/panels.lua`, and `INV:SizeHeaderButtons` / `INV:SpaceViewButtons`, `SaftUI-Bags/header.lua`; 2026-11-11). Open the bags, the bank and the combined bank under Blizzard:
- the header is the title bar's strip, 20 tall with its bottom on the window's top (`st.ThemeArt.TitleStrip()`): on Forever the whole title bar, centred on its dark band (measured in a screenshot: the band runs 1 to 18 below the drawn frame's top, the lip from 19); on retail its bottom 20, under a 1px rim, where Blizzard's TitleContainer sits. The title and every button should look centred on the band, clear of the rim and the lip;
- the view buttons, Bag Slots and the Edit toggle are 16 tall (the strip less 4), the view buttons' 12px glyphs sharp in their 16px panel buttons, and "Bag Slots" readable at 16;
- the view buttons end 4px short of the close button in its socket (26px in from the window's right edge on Forever, 21 on retail, `st:SocketReach`), and the title doesn't run into them at the window's narrowest;
- the window's content (the search box, the slots) starts right under the title bar, with no empty strip, and nothing of it hides under the metal's lip;
- a theme switch Thick, Blizzard, Thick and a profile switch between a Blizzard and a Thick profile put it all back with no `/reload`, Bag Slots included, and dragging the window by its title bar works;
- the bags' own Theme (Bags > Look) set to Thick under SaftUI's Blizzard puts the header back in the window at once, and to Blizzard under SaftUI's Thick leaves it in the window, under the metal's empty title bar;
- Bag Slots' bar (and the bank's) sits above the title bar, 3 over the metal's top as its art's table gives it (16 over the drawn frame, `st.ThemeArt.MetalAbove()`). In the user's Forever screenshot the metal's visible rim reaches only about 6 over the drawn frame, so the bar may float about 10px above the rim: if that looks too far, lower the clearance to the visible rim (`st:ArtAboveHeader`, `SaftUI-Core/panels.lua`). It should cover none of the title bar, and its slots should take their own clicks;
- a profile switch from a Blizzard profile to a Thick one in combat with the bags open: nothing blocked (`/console taintLog 1`, BugGrabber), the header stays in the title bar until combat ends and then drops back into the window at the Thick profile's height. The stubs block a protected frame's moves only for frames a test marks protected, so whether a bag window's header and footer really are protected in combat (its scroll frame, holding Blizzard's item buttons, is anchored under the header, and the search box anchored to the header is the footer's child) is what this checks.

Bags, Forever:
- the close button in its socket: its ADD highlight, and whether it draws and clicks above the metal and the header now in the title bar;
- the screen edge margin clamps the window, not the metal above it, so at the top screen edge the socket's top may sit 1-3px off screen (the spec's "whether the title bar above a window needs keeping on screen"). Since 2026-11-11 the window's header (its title, buttons and drag handle) sits in that title bar too, so at a margin under 20 it goes off the top of the screen with the bar; if that bites, the margin could count the title bar while the header is in it (`st:HeaderInTitleBar`), which would also need the bags' mover anchor and edit mode's outline to agree (round 2 did this for `/sui` alone: see "Screen edge margin: art reach only for /sui");
- the ring on the Pinned items and Caught now icons in `/sui` → Bags → Categories: `LayItems` (`SaftUI-Bags/categoriestab.lua`) re-levels each icon and its border's frame on every draw, so the ring may end up level with the icon.

Unit frames (both clients): under Blizzard a debuff shows its dispel type as Blizzard's white icon border over the icon's edge, which the aura container tints (`StyleButton`, `SaftUI-Unitframes/elements/auras.lua`). Check it shows in the dispel type's color, sits over the icon, against the cooldown swipe, and isn't there for a debuff with no dispel type.

Totem bar (Forever):
- the doubled slot art behind a totem element (the slot button's and the action button's ring) may look too opaque;
- change a totem element in combat under Blizzard: the slot button's own-color piece is a texture made on Blizzard's secure button the first time it's colored (the one exception in `.agents/taint.md` rule 12), so check the color shows and nothing is blocked (`/console taintLog 1`);
- the action button's ring holder (`StyleRing`, `SaftUI-Misc/totemskin.lua`) sits one level over the button, the same level as its cooldown, so check the ring's rim against the cooldown swipe.

Micro menu: Blizzard's micro button art is 22x28, centred on SaftUI's 20x25 buttons (the icons' scale), so check it's neither too big nor too small, and that the performance bar (`MainMenuBarPerformanceBar`, left at its template anchors) sits on the button.

Hekili (if installed): SaftUI's backdrop strata is set LOW after the first draw (`SaftUI-Misc/Skinning/addons/hekili.lua`). If Hekili's buttons sit higher, the ring draws under their icon.

Loot feed, retail: the item's `n/m` quality text and the profession overlay under the ring (see "Loot feed: retail item quality text and profession overlay sit under the Blizzard ring").

`/sui`, an open question for the user: under Blizzard the multiselect's box is a 1px line and its rows sit 2px in from it (the theme's `small` look, as there's no Blizzard equivalent). Does it look right?

### 2026-11-11 — st:SetBackdrop and st:SetBackdropIn do arithmetic on frame levels that can be Blizzard's

**What:** `SaftUI-Core/theme.lua` levels each backdrop one below the frame it sits behind with `max(0, parent:GetFrameLevel() - 1)` (`st:SetBackdrop`) and `max(0, frame:GetFrameLevel() - 1)` (`st:SetBackdropIn`). Both frames can be Blizzard's: tooltips, the bags bar's slots, Hekili's buttons, the aura container's buttons. If retail ever hands back a secret frame level for one of them, the subtraction errors on every draw.

**Why noticed:** The Blizzard theme's final fix wave (2026-11-11) guarded the same read in the code the branch added: `Holder` in `SaftUI-Core/themeart.lua` and the roll icon's level in `SaftUI-Loot/roll.lua`. Both now skip the re-level when the level is secret, following `SaftUI-Minimap/microbuttons.lua`. The reviewer and the implementer both noted that `theme.lua`'s two reads are older than the branch and stay unguarded. No live path is known to give a secret level today, so this is hardening.

**Anchors:** `SaftUI-Core/theme.lua` (`st:SetBackdrop`, `st:SetBackdropIn`: the two `SetFrameLevel(max(0, ...GetFrameLevel() - 1))` lines); the guarded reads in `themeart.lua` `Holder` and `SaftUI-Loot/roll.lua`, and their tests, which pass a `newproxy` secret; `.agents/clients.md` (secret values).

**Shape of work:** Small. Add an `issecretvalue` guard to both lines (on a secret level, leave the backdrop at the level it was made with), plus a test per function using the existing secret stand-in.

### 2026-11-11 — Edit Mode snapping under Blizzard measures the frames' borders, not the selection art

**What:** Under the Blizzard theme a mover shows Blizzard's Edit Mode selection art (`editmode-actionbar-highlight` and `-selected` kits) around a frame, which sits about 8px outside it. Snapping (`EM.GetOutlineRect`, `EM.OutlineOutset`, `SaftUI-Core/EditMode/snap.lua`) still measures the frame's own border line, so two frames snapped to touch show their selection art overlapping by up to 16px, and a frame snapped to a grid line has its art, not its edge, off it.

**Why noticed:** The Blizzard theme's spec left it to the builder: "Whether Edit Mode's snapping should measure Blizzard's selection, which sits 8px outside a frame, under Blizzard. Today it measures the frames' own borders." The builder kept today's behavior (`EM.OutlineOutset()` is unchanged under Blizzard, and `tests/core/theme_blizzard_editmode_test.lua` locks that) because snapping to the border keeps frames that are placed edge to edge in game flush, which is what the user sees outside edit mode.

**Anchors:** `SaftUI-Core/EditMode/snap.lua` (`EM.OutlineOutset`, `EM.GetOutlineRect`, `EM.GetSnapLines`); `SaftUI-Core/EditMode/mover.lua` (the overlay's art, `st.ThemeArt.Control('mover')`); `tests/core/theme_blizzard_editmode_test.lua`; `docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md` ("Left to the builder").

**What's been considered:** Measuring the selection art (outset 8) under Blizzard would line the art up and leave frames 16px apart in the real UI, so it fights what the user wants outside edit mode. Keeping the border is the safe call, and costs only edit mode's looks.

**Shape of work:** Small: look at it in game under Blizzard and decide. If the overlap bothers, give `EM.OutlineOutset` the art's reach for the picker only, or draw the art inside the border.

**Open questions:** Does the overlap look wrong in game?

### 2026-11-11 — Per-dispel-type debuff art on SaftUI's own aura buttons

**What:** Blizzard's buff frame skin shows Blizzard's own `DebuffBorder` (a border by dispel type: `ui-debuff-border-magic-noicon`, `-curse-`, `-disease-`, `-poison-`, `-bleed-` and `-default-`) and `TempEnchantBorder` under the Blizzard theme. SaftUI's own aura buttons (the unit frames' buffs and debuffs, WeakAuras) don't get that art. The unit frames' debuffs show their dispel type on `button.Border`, the texture oUF hands the aura container, which tints it by dispel type (oUF's dispel colors, built from Blizzard's `AuraUtil.GetDebuffDisplayInfoTable`) with a secret color and shows and hides it itself. SaftUI only restyles it (`StyleButton`): under Blizzard it's the white icon border (`Interface\Common\WhiteIconFrame`) in OVERLAY over the whole button, so the color rings the icon's edge; under Thick and Thin it's a flat fill behind the icon, showing in the gap around it. SaftUI never reads the color. WeakAuras' icons show no dispel color in any theme.

**Why noticed:** The Blizzard theme's spec listed it as out of scope ("Per-dispel-type debuff art on SaftUI's own aura buttons (unit frames, WeakAuras). They take the white icon border in SaftUI's colors."), to keep the first version to one art per kind. The final branch review (2026-11-11) found that wasn't so for the unit frames: under Blizzard an aura's inset is 0, so the flat fill sat wholly behind the icon and debuffs lost their dispel color; `StyleButton` now draws the white border instead.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFrame.lua` (`ShowBorder`, `UpdateBorderColor`); `SaftUI-Unitframes/elements/auras.lua` (`StyleButton`, the dispel border fill and `ColorInnerLine`); `SaftUI-Misc/Skinning/addons/weakauras.lua`; `SaftUI-Core/themeart.lua` (the `aura` art); `.agents/taint.md` rule 11 (what can be done to the unit frame aura buttons).

**What's been considered:** The unit frame aura buttons are Blizzard's (`AuraContainer`), so rule 11 limits it: a texture handed to a button for the dispel border gets secret alpha, vertex color and shown aspects, and the container's own `SetAtlas` calls are what pick the dispel type's art. WeakAuras' icons are SaftUI's to draw on but know a dispel type only if the aura has one.

**Shape of work:** Needs a design pass on the unit frames (what the container exposes), then a small change for WeakAuras.

**Open questions:** Is the white border in the dispel color enough?

### 2026-11-11 — Blizzard bag-bar slots and the Hekili skin write onto frames that aren't SaftUI's

**What:** `SaftUI-Bags/containers/bag.lua` (the bags bar's Blizzard bag slots) writes `.backdrop`, `.thick` and a hover texture onto them through `st:SetBackdrop` and `st:SkinActionButton`, and `SaftUI-Misc/Skinning/addons/hekili.lua` does the same to Hekili's buttons (`st:SetBackdrop`, `button.backdrop:SetFrameStrata('LOW')`, `button.skinned`). That breaks `.agents/taint.md` rule 1 for Blizzard's slots, and writes onto another addon's frames for Hekili. Both are `st:MarkForeign` now, so the Blizzard theme puts none of its art on them, but the old field writes are still there.

**Why noticed:** The Blizzard theme's reviews (2026-11-11). Task 3 had to mark both foreign so the ring went on a frame of SaftUI's, and carried the writes forward as pre-existing.

**Anchors:** `SaftUI-Bags/containers/bag.lua` (`RestyleBagSlot`, the `st:MarkForeign(slot)` and `st:SkinActionButton` lines); `SaftUI-Misc/Skinning/addons/hekili.lua` (`HK:SkinIcon`, `HK:UpdateConfig`); `SaftUI-Core/theme.lua` (`st:MarkForeign`, `st:SetBackdropIn`); `.agents/taint.md` rule 1.

**What's been considered:** Move both to `st:SetBackdropIn(backdrops, frame, ...)` with a weak table of their own, keep the hover and pushed textures as `st:SkinActionButton` makes them but in a side table, and read `backdrops[button]` where `button.backdrop` is read now (Hekili's strata line).

**Shape of work:** One small task, two files, with a locked-frame test for each as `tests/lib/locked_widget.lua` gives.

### 2026-11-11 — Loot feed: retail item quality text and profession overlay sit under the Blizzard ring

**What:** Under the Blizzard theme, `Util:SetItemQualityLevelText` (`SaftUI-Core/Utilities/itemupgrades.lua`) and the crafting quality overlay are regions of the feed entry. The ring's holder is a child frame at the entry's frame level + 1, so the ring clips the outer 1-3px of the `n/m` text and the pip at the entry icon's top-right corner. Retail only, Blizzard theme only.

**Why noticed:** The Blizzard theme's reviews (2026-11-11), reading `SaftUI-Loot/Feed/feed.lua`: the count already sits on a frame at level + 2 (`over:SetFrameLevel(item:GetFrameLevel() + 2)`), the quality text doesn't. Not checked in game: the user plays Forever, which has no upgrade tracks or crafting quality.

**Anchors:** `SaftUI-Core/Utilities/itemupgrades.lua` (`Util:SetItemQualityLevelText`, `Util:SetItemQuality`); `SaftUI-Loot/Feed/feed.lua` (`Util:SetItemQuality(item, ...)`, the `over` frame); `SaftUI-Bags/slot.lua` (the other caller); `SaftUI-Core/themeart.lua` (`Holder`, the ring's frame).

**What's been considered:** Move the quality text and the overlay to the +2 frame the count uses. `Util:SetItemQualityLevelText` is shared with the bag slots, so the change is wider than the feed: it needs the host frame passed in, and the bag slots' own layering checked.

**Shape of work:** Small, one helper and its two callers; an in-game check on retail.

### 2026-11-11 — The disabled loot popup writes nametext onto Blizzard's LootButton

**What:** `SaftUI-Loot/popup.lua` (~38) sets `button.nametext = _G['LootButton'..ID..'Text']` on Blizzard's loot buttons, and elsewhere `st:Kill`s their `IconBorder` and `IconOverlay`. That writes a field onto a Blizzard frame (`.agents/taint.md` rule 1). The popup is disabled (`SaftUI-Loot/init.lua`, `-- self:InitializeLootFrame()` is commented out), so it never runs today.

**Why noticed:** The Blizzard theme's reviews (2026-11-11): the popup's draw calls were re-tagged and a scan of Loot for writes onto Blizzard frames found it. Related to the older "SaftUI-Loot writes onto Blizzard frames and globals" entry in Resolved.

**Anchors:** `SaftUI-Loot/popup.lua`; `SaftUI-Loot/init.lua` (~17); `.agents/taint.md` rule 1.

**What's been considered:** Keep the font strings in a weak table keyed by the button, and replace `st:Kill` with `SetAlpha(0)` where Blizzard never sets the alpha.

**Shape of work:** Fix it before re-enabling the popup; no work while it stays off.

### 2026-11-11 — Class power types with no Blizzard art draw a borderless flat bar under Blizzard

**What:** Each class power point is drawn as kind `control`, which is bare under Blizzard (`SaftUI-Unitframes/elements/classpower.lua`, the `st:SetBackdrop(point, ..., 'control')` line). A power type with no Blizzard art (retail's demon hunter soul fragments, icicles and tip of the spear; the art exists for combo points, holy power, soul shards, chi, arcane charges and essence) draws only its flat status bar, with no border. Before, kind `small` gave them a 1px line. Forever has combo points only, which have art, so the user's client isn't affected.

**Why noticed:** The Blizzard theme's reviews (2026-11-11), reading Task 11's class power change: `ApplyArt` falls back to the flat bar for a type with no art, but the point's backdrop kind is fixed at `control`.

**Anchors:** `SaftUI-Unitframes/elements/classpower.lua` (`ApplyArt`, the draw call); `SaftUI-Core/themeart.lua` (`ThemeArt.ClassPower`, `KINDS.control`); `tests/unitframes/classpower_blizzard_test.lua`.

**What's been considered:** Pick the kind by whether art exists (`ThemeArt.ClassPower(powerType, ...)` returns nil for a type with none): `small` then, `control` otherwise, drawn again on every power type change (the art is chosen per power type there already).

**Shape of work:** Small, in the one element, with a test per kind.

### 2026-11-11 — Blizzard theme: the bags' rule editor and Categories list keep the options window's own look

**What:** Under SaftUI's theme Blizzard, `/sui` → Bags → Categories is only partly in Blizzard's Settings art. What it borrows from Core takes the Blizzard look: the editor's ordinary rows (Name, On, Show in, Reset, Delete), the lists and check lists its pickers open, the Reset all confirm, and the item strips' icon borders (kind `action`). *Update 2026-11-11 (Blizzard theme round 2, Tasks 5 and 9):* the rule editor's value fields now follow too (the compact Settings dropdown, `W.LookDropdown(field, blizzard, true)`), and the category list's rows are the Settings category list (`Options_List_Active` and `Options_List_Hover`, gold names, white when picked). Still in the options window's `Box` look: the rule editor's text and number boxes, the "whole word" check box, the NOT toggles and the AND/OR badges (`bagrule`); the list's drag handles keep their look.

**Why noticed:** Merging `modular` (the bag categories project) into `blizzardtheme` (2026-11-11). Both were built from modular 8dc348c in parallel: the Blizzard theme gave `/sui`'s built-in widgets Blizzard's Settings art (its spec's ruling 2), while the bag categories added three custom widget types (`W.Define`) that draw their own frames with `W.Box`. The merge brief said to leave them as they were, apart from what follows from the shared helpers, and to note the gap. The merge did give the check list's boxes the Settings check box, since the check list is Core's (`W.OpenCheckList`) and the spec's ruling 3 is one check box look everywhere.

**Anchors:** `SaftUI-Bags/ruleeditor.lua` (`MakeBox`, `MakeField`, `MakeCheck`, the NOT box, `GroupParts`' badge, `MakeAdd`); `SaftUI-Bags/categoriestab.lua` (`ListRow`, `Action`); `SaftUI-Core/Config/optionslook.lua` (`LookInput`, `LookDropdown`, `LookCheckBox`, `LookLine`, `W.LookButton`, `W.BlizzardLook`); `SaftUI-Core/themeart_data.lua` (the sidebar's `Options_List_Active` and `Options_List_Hover`, drawn by `SaftUI-Core/Config/optionsnav.lua`); `docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md` ("`/sui`'s controls under Blizzard"); `.agents/edit-mode.md` (Options window widgets).

**What's been considered:** Most of Core's look helpers are locals of `optionswidgets.lua`. Exporting them on `W` (as `W.LookButton` and `W.LookSearch` already are) would let the bags' widgets call them when they bind: a box as `LookInput`, a field as `LookDropdown` (which wants `button.caret` and `DropdownStates`), the check box as `LookCheckBox`, and the selected category row as the sidebar's `Options_List_Active` with `Options_List_Hover` under the mouse. The NOT toggle and the AND/OR badge have no Blizzard equivalent, so they would take the 1px line the multiselect's box takes.

**Shape of work:** One small task for what is left: the boxes as `LookInput` (exported on `W` as `LookDropdown` was), the check box as `LookCheckBox`, and the NOT toggle and AND/OR badge as the multiselect's 1px line, called from `ruleeditor.lua` at bind, with a Blizzard-and-back test per control in `tests/bags/rule_editor_test.lua` and every cell's rect unchanged under Thick and Thin.

**Open questions:** Should the AND/OR badges keep their blue and orange under Blizzard, since the colors carry the operator?

Also check in game, under Blizzard: the item strips' (Pinned items, Caught now) action ring sits over each icon. `LayItems` (`categoriestab.lua`) moves each icon and its border's frame to new levels on every draw, and the ring's holder is a child of that border frame (`themeart.lua`, `Holder`), so it may end up level with the icon rather than above it. The stubs don't model frame level stacking.

### 2026-11-11 — Grays/Auto Vendor: a finished edit that broadens its rule sells at the next merchant

**What:** Auto vendor sells whatever Grays/Auto Vendor's rule catches, and every editor change saves at once. A half-built rule can no longer widen it (an AND holding a block or group that isn't filled in catches nothing), but a finished edit that says "everything but" does, at the next merchant: NOT on an Old gear or Protected block in its inner OR (both are complete the moment they're added), flipping its root AND to OR (one click on the badge), removing its inner OR group with the X, or "Has vendor price: yes" in the inner OR. Each sells every priced item that `INV:IsAutoVendorItem` doesn't refuse (Protected, Cosmetic, fishing, account-bound, in a set, tooltip missing). Selling can't be undone, and buyback holds 12 items.

**Why noticed:** The bag categories final review (2026-11-11), under "Declined to judge": these are deliberate edits, and the spec says auto vendor follows the rule, but the reviewer called a confirm on the selling category's root flip or group removal "a cheap product decision for the user". The fix for the review's C-1 (half-built rules) left them as they are, and `tests/bags/category_store_test.lua` ("a half-edited Grays/Auto Vendor rule never sells more than the shipped one") skips NOT Old gear and NOT Protected in the inner OR for this reason.

**Anchors:** `SaftUI-Bags/ruleeditor.lua` (the badge's flip, the X, NOT, `Edit`); `SaftUI-Bags/categories.lua` (`INV:IsAutoVendorItem`); `SaftUI-Bags/autovendor.lua` (`INV:AutoVendor`); the slot's junk coin and the tab's Caught now, which already show what would sell before a merchant is opened.

**What's been considered:** A confirm in the editor before an edit widens the selling category's rule (the root flip, removing a group, NOT); a cap on what one merchant visit sells, with a prompt above it; or nothing, since the coins show the change first.

**Shape of work:** A product decision first, then a small change in the editor or in auto vendor, with tests.

**Open questions:** Which of these, if any?

### 2026-11-11 — Rule editor: a level mode picked before a number is typed does nothing

**What:** A new Item level or Required level block has no number, so it can't be read and catches nothing until it has one. Its mode list (at least, at most, between) moves the number typed to the bound the mode needs. With no number yet there's nothing to move, so picking "at most" or "between" on a new block changes nothing, and it still shows "at least". The user has to type a number first, then pick the mode.

**Why noticed:** The fix for the bag categories final review's C-1 (2026-11-11). New level blocks used to start as `{ min = 0 }`, "at least 0", which caught every item the moment the block was added; in Grays/Auto Vendor's inner OR that sold every priced item at the next merchant. They now start as `{}`, and the mode switch no longer invents a 0 for a block with no number, so it has nothing to carry over.

**Anchors:** `SaftUI-Bags/ruleeditor.lua` (`LevelMode`, `LevelFields`); `SaftUI-Bags/rules.lua` (`R.BLOCKS`' `new`, `level_block`); `tests/bags/rule_editor_test.lua` ("a new Item level, Required level, Crafting reagent or Has vendor price block shows nothing set ...").

**What's been considered:**
- Writing 0 again: that is what made a new block catch everything.
- Keeping the picked mode in the saved block (a `mode` key, or `false` in the bound it means): new data in the profile for something only the editor shows.
- Keeping it in the editor only, by the row's path, until a number is typed: no data change, but a row's path shifts when rows are added or moved above it, so it has to be dropped on any other edit.

**Shape of work:** Small: the editor-only option in `LevelFields`, and a test.

**Open questions:** Is it worth doing, or is "type the number, then pick the mode" fine?

### 2026-11-11 — Bag categories: in-game checks

**What:** What the bag categories project could only be compile-checked and stub-tested for, to confirm in game on Forever and retail, and what to do with each answer. The first eight are the plan's own list (`docs/superpowers/plans/2026-11-10-saftui-bag-categories.md`, "In-game checks"); the rest are what the reviews and tests couldn't settle.

**Why noticed:** The bag categories project (branch `bagcategories`, 2026-11-11) tests everything outside the game against stubs (`tests/bags/bag_world.lua`), and its design notes name several client behaviors it assumed rather than saw. The user plays Forever, so the check is theirs.

**Anchors:** `docs/superpowers/specs/2026-11-10-saftui-bag-categories-design.md`; `docs/superpowers/plans/2026-11-10-saftui-bag-categories.md` ("In-game checks"); `SaftUI-Bags/tooltipscanner.lua` (`INV.TOOLTIP_TRIES`, `INV.TOOLTIP_RETRY`), `SaftUI-Bags/itemclasses.lua`, `SaftUI-Bags/categories.lua` (`EquipmentSet`, `INV:IsAutoVendorItem`), `SaftUI-Bags/categoriestab.lua`, `SaftUI-Bags/ruleeditor.lua`, `SaftUI-Bags/slot.lua` (the slot menu and the tooltip lines); `.agents/clients.md` (item classes).

**Shape of work:** One sitting in game, a note per check. A wrong answer becomes a small fix or its own followup.

The plan's list:
1. **Forever, cold login:** after `/reload` with the bags open, every item lands where it did before this change, and the loading bar clears.
2. **Forever device:** `/run print(C_Item.GetItemSubClassInfo(0, 14))` prints `Devices`, and a device item's subclass in `GetItemInfo` is `Devices`. Forever's Devices subclass resolves through `GetItemSubClassInfo`, which is how the Devices category finds it.
3. **Delves:** a "Curious ..." item is no longer in Delves, and a Combat Curio still is.
4. **Equipment sets on Forever:** an item in a set shows as `Set: <name>`, or the Equipment sets entry does nothing there. Note which.
5. **The tab:** reorder by drag; add a category with `Subclass is Tradeskill: Herb, Metal & Stone` and move it above Trade Goods; rename it; turn it off; delete it; restore a default; Reset all.
6. **The tooltip** of a bag item shows `Category: ... (nth)` and `Caught by: ...`, and the lines stay after the tooltip refreshes (hold Shift).
7. **The slot menu:** Ctrl + right click, Add to category... moves the item; Auto Vendor and Protected clear each other; Edit this category opens the tab.
8. **At a vendor,** with Grays/Auto Vendor renamed and moved, the junk sells; turned off, nothing sells.

What the plan's list doesn't cover:
9. **A placeholder tooltip.** A tooltip that says "Retrieving item information" would be cached as the item's real text, and the item filed by it for good. Confirm what `C_TooltipInfo.GetBagItem` returns for an item that isn't cached yet (nil, an empty `lines`, or placeholder lines), on both clients, and that the scanner treats it as not arrived.
10. **The Categories tab:**
    - the drag ghost and the insertion line, in the list and in the rule editor;
    - dragging in the list with it scrolled (it and the editor scroll on their own since 2026-11-11): the wheel scrolls it mid-drag, holding the row near its top or bottom edge scrolls it (resting on the first or last row in view doesn't), and the line and the drop land on the row under the cursor;
    - with Shift held, or `alwaysCompareItems` on, hovering an equippable item in Pinned items or Caught now (legacy gear in Grays/Auto Vendor): Blizzard's comparison tooltips open on the side of the item tooltip with more screen room (`TooltipComparisonManager:AnchorShoppingTooltips`), which for a centred `/sui` is over the window, covering the editor. SaftUI only places GameTooltip itself; the comparison tooltips are Blizzard's and the public API can't move them, so note how much they cover and whether it matters;
    - icon borders under the item art in Pinned items and Caught now;
    - text at real font sizes: nothing clipped or overlapping in the rows or the editor (the tests lay it out at the default size only).
11. **`SetBagItem` and `SetItemByID`** on both clients: the tooltip the tab's icons show (item tooltips are `GameTooltip`'s), and the slot's own hover.
12. **The tooltip's `Category` and `Caught by` lines' placement:** where they land in the tooltip on both clients (after the item's own lines, before an addon's?), and that they aren't added twice.
13. **The slot menu's look:** how the menu and its `...` entry look on both clients, and whether it closes after a checkbox click (Auto Vendor, Protected) or stays open.
14. **An item whose tooltip never arrives:** it waits about 5 seconds, then it's filed (marked `tooltipMissing`), and it's never sold until its text arrives. Hard to provoke; an item link from another realm's character may do it.
15. **Auto vendor after a rename, a move or turning off:** it still sells, and the junk coin follows it (`INV:IsAutoVendorItem` finds the seller by its `sells` flag, not its name), after Grays/Auto Vendor is renamed or moved; turned off, nothing sells and no coin shows.

**Open questions:** None until the answers come in.

### 2026-11-11 — Bag settings: the reagent section nothing reads

**What:** `SaftUI-Bags/config.lua:58` still defines a `reagent` section (a position anchored to the bank's anchor, and its settings), but no reagent window exists any more. `SaftUI-Bags/movers.lua` lists the windows that can have a position as `bag`, `bank`, `combinedbank` and `warband` (`WINDOW_IDS`, line 16), and still calls `self:MigratePosition('reagent')` (line 97) "no window yet, but it has a config entry". Neither client has a reagent bank any more (`.agents/clients.md`).

**Why noticed:** The bag categories project's doc pass (2026-11-11), reading the bags' config for a stale `filters.lua` reference.

**Anchors:** `SaftUI-Bags/config.lua` (`reagent`), `SaftUI-Bags/movers.lua` (`WINDOW_IDS`, `MigratePosition('reagent')`); the followup "Settings with no /sui option, settings nothing reads, and frames with no edit mode mover" is the same kind of cleanup.

**Shape of work:** Small: remove the section and the migration call, after checking nothing else reads `config.reagent` (grep for `.reagent`), and that a saved profile with the key is harmless. Leave the bag family `'reagent'` kinds in `category.lua` and `autovendor.lua` alone: they are about the reagent bag, not this window.

### 2026-11-11 — ItemRack is still an optional dependency, and nothing reads it

**What:** Core's TOCs, `SaftUI-Core/SaftUI-Core_Forever.toc` and `SaftUI-Core/SaftUI-Core_Mainline.toc`, still say `## OptionalDeps: RealMobHealth, ItemRack, WoWUnit, WeakAuras`, but no SaftUI Lua reads ItemRack. The bags' equipment set categories used to read it; they read the client's own equipment sets now (`C_Container.GetContainerItemEquipmentSetInfo`).

**Why noticed:** The bag categories project's doc pass (2026-11-11), while checking what the old set lookup depended on.

**Anchors:** the two Core TOCs; `grep -rn ItemRack SaftUI-*` (Libraries aside); `SaftUI-Bags/categories.lua` (`EquipmentSet`).

**Shape of work:** One line in each of two TOCs. Check first that no other addon or WeakAuras-side code relies on ItemRack loading before SaftUI (OptionalDeps only orders the load).

### 2026-11-11 — Bag categories: a default added in a later version can duplicate a user category's name

**What:** A default category added in a later SaftUI version, whose name a user category already has, makes two categories with one name. `INV:RestoreCategory` and `INV:ResetCategory` number the name (`Toys (2)`), but the list build (`INV:GetCategoryList`) doesn't number a default it finds new.

**Why noticed:** The bag categories project's final review (2026-11-11). Category frames, ranks and hide flags go by id, and a default's id is the name it shipped with, so the ids stay apart but two categories show one header, and a user can't tell them apart in the list or the tooltip lines.

**Anchors:** `SaftUI-Bags/categories.lua` (`INV:GetCategoryList`, the numbering in `RestoreCategory` and `ResetCategory`); `SaftUI-Bags/categorydefaults.lua`; `tests/bags/category_store_test.lua` (the `Toys (2)` cases).

**What's been considered:** Numbering the default in the list build (`UniqueName`), as Restore and Reset do, is the obvious fix. A user category's id is `custom:<n>`, so ids never clash and it's only the name. Renaming the user's category instead would change their data.

**Shape of work:** Small: the same numbering in the list build, plus a test with a profile that has a custom category named like a default the version adds. Matters only when a later version ships a new default.

### 2026-11-11 — Bag categories: a Set checkbox is dead while the Equipment sets entry hides the window

**What:** In the Edit view's Show in checkboxes, a `Set: <name>` checkbox unchecked while the Equipment sets entry already hides that window changes nothing. `INV:IsCategoryHidden` returns true for a `Set: ...` key as soon as the sets entry's `hide[windowId]` is set, before it looks at the set's own flag (`filters.categories[windowId]`), so the box is a dead control.

**Why noticed:** The bag categories project's review of Show in (2026-11-11).

**Anchors:** `SaftUI-Bags/categories.lua` (`INV:IsCategoryHidden` and `INV:SetCategoryHidden`, the "Show in" section, `IsSetKey`); the Edit view's checkbox in `SaftUI-Bags/category.lua` (~422-425).

**What's been considered:** Disable or hide the set's checkbox while the entry hides the window, or let a set's own flag win. The first changes less.

**Shape of work:** Small, with a test in `tests/bags/category_migration_test.lua` next to the Equipment sets entry's Show in cases.

### 2026-11-11 — Old gear's tabard and shirt exclusion never matched

**What:** The old Old gear filter meant to leave tabards and shirts out. It compared the localized slot name with an `INVTYPE_` token, so the test never matched and every tabard and shirt that met the other tests was caught. The category blocks leave the test out, so nothing changes for the user.

**Why noticed:** The bag categories project's plan (Global Constraints and "What can't be written exactly in blocks", item 5, `docs/superpowers/plans/2026-11-10-saftui-bag-categories.md`), reading `filters.lua` at `8dc348c`.

**Anchors:** `git show 8dc348c:SaftUI-Bags/filters.lua` (`isLegacyGear`); `SaftUI-Bags/categorydefaults.lua` (Old gear); `tests/bags/fixtures/old_filters.lua` (the oracle, which keeps the old behavior).

**Shape of work:** Only if the user wants tabards and shirts kept out of Old gear: a block on the item's equipment slot (an `INVTYPE_` token compared with `GetItemInfoInstant`'s equip slot), and a fixture.

**Open questions:** Does the user want that exclusion at all? It has never worked, so nobody has missed it.

### 2026-11-11 — Auto Vendor pins now beat Grays' exclusions and equipment sets

**What:** The old Auto Vendor list wasn't a filter: a listed item still had to get past Grays/Auto Vendor's exclusions, and equipment sets came before it. As a pin, the same entry beats both, so a listed item that is Cosmetic, has the "Fishing" or "Blizzard Account Bound" text, or is in an equipment set now shows in Grays/Auto Vendor rather than in the category it showed in before. Only where it shows changed, not what is sold: whatever an item's pin or rule says, `INV:IsAutoVendorItem` never sells an item that is Cosmetic, has the "Fishing" or "Blizzard Account Bound" text, is in an equipment set, or whose tooltip never arrived (so those words can't be read), nor one that is Protected or has no vendor price.

**Why noticed:** The bag categories project's plan (`docs/superpowers/plans/2026-11-10-saftui-bag-categories.md`, "What can't be written exactly in blocks", item 7), when the Auto Vendor list became pins.

**Anchors:** `SaftUI-Bags/categories.lua` (`INV:MigrateCategories`, `INV:GetItemCategory`'s pin branch, `INV:IsAutoVendorItem`); `tests/bags/category_migration_test.lua`.

**Shape of work:** Only if the user wants such items shown where they were before: have a pin to the selling category lose to the exclusions that used to apply (a rule check in the pin branch, or in the migration), and a test. Selling needs no change.

**Open questions:** Does the user mind a listed Cosmetic, fishing, account-bound or equipment set item showing, unsold, in Grays/Auto Vendor rather than in its old category?

### 2026-11-10 — Fonts: separate the fonts users pick per kind of text from SaftUI's internal font objects

**What:** SaftUI's fonts are a handful of named font objects (Pixel, Pixel Med, Pixel Huge, Normal, Normal Med, Title (Colus), Subtitle), each a face, size, outline, shadow and spacing together. Code picks an object by key, and the user's options pick objects too. So restyling one kind of text means changing an object every other user of it shares. The user wants it split the way the template strings became Theme: what the user chooses per kind of text, apart from SaftUI's internal font objects.

**Why noticed:** The user, 2026-11-10: "I'd also like to queue up another piece of work restructuring how fonts are managed, similar to template I'd like to separate internal font usage from user facing font usage - a good example of why I want this is I'd like to change my bag category labels to Colus but don't currently have a good way of doing that without also changing the font of my unit frames as well as anything else that uses the "Normal" font object. we can explore that subject deeper after but that's some starter context."

Today the bag category titles already have a font choice (`inventory.fonts.titles`, `SaftUI-Bags/options.lua`), but it picks a whole object: choosing Title gives Colus at the title's size, and the only way to get Colus at label size is to change Normal's face, which every unit frame and anything else on Normal shares.

**Anchors:**
- `SaftUI-Core/Media/fonts.lua`: `FN:UpdateFontConfig` (a font object per `st.config.profile.fonts` entry, `SaftUI_<name>Font`), `st:GetFont(key)`, the Fonts tab (a Kinds of text section: `headers.font`, `buttons.font`, `panels.font`; then a section per font object).
- `SaftUI-Core/Config/defaults.lua`: `st.defaults.fonts` (the objects and their derived sizes).
- Per-module font keys: e.g. `inventory.fonts.titles` (`SaftUI-Bags/category.lua:432`, `inventory.lua:209,228`), and every `st:GetFont(...)` and `st:CreateFontString(parent, '<key>')` across the modules.
- The precedent: the Themes project (`docs/superpowers/specs/2026-11-10-saftui-themes-design.md`): internal names hidden, a global choice that every module inherits, per-module overrides only.

**What's been considered:** Nothing yet beyond the user's framing. The Themes precedent suggests a global font that kinds of text inherit by default, with per-kind overrides (face, size, outline) that don't touch the shared objects.

**Shape of work:** A brainstorm (which kinds of text the user sees, what a choice holds: face only, or face, size and outline; inherit and override, as Themes), then a spec and a plan. Probably one project: a font-choice layer over the objects, a migration for saved font keys, and the options.

**Open questions:**
- What does a per-kind choice hold: a face only, or face, size and outline?
- Which kinds of text get their own choice, and how are they grouped in `/sui`?
- Do the named objects stay user-visible at all, or become internal like the template strings?

### 2026-11-10 — Zone level and faction line: in-game checks

**What:** The zone text's new line under the zone name (level range and faction, e.g. "Level 10–20 · Alliance") and the world map's faction line under a hovered zone's name were built from Blizzard's source and checked only in `tests/`. To check in game, Forever first:
- **PvP status on Forever.** `C_PvP.GetZonePVPInfo()` gives `friendly` or `hostile` with the holder's name in starting zones and cities (Elwynn Forest, Durotar, Stormwind), `contested` in Stranglethorn Vale and `sanctuary` on Zephras Isle, so the line shows Alliance in blue, Horde in red and Neutral in yellow. Whether Forever reports these on a PvE realm, or with the PvP flag off, is unconfirmed.
- **Level ranges.** `C_Map.GetMapLevels` gives Forever's zones their ranges (Elwynn Forest 1–10), and a cave its zone's. Forever's DB2 tables can't tell: its UiMap and AreaTable carry no level data (ContentTuningID 0 on every row). The quickest check is whether Blizzard's own world map label on Forever reads "Elwynn Forest (1-10)" when you hover it; if not, the zone text will never show a level on Forever. First sighting (2026-11-10): entering Alterac Mountains (Lordamere Internment Camp) on Forever showed "Neutral" with no level, so Forever most likely gives none. A city with none shows only the faction. In a dungeon: the level if the game gives one, no faction, and the difficulty line, which now shows while the zone name is up (see the resolved "Zone text replaces Blizzard's OnEvent script" entry). In a battleground (an orphan map under the zone outside, such as Warsong Gulch under The Barrens): no level, not the outdoor zone's.
- **Glyphs.** The en dash and the middle dot draw in SaftUI's subtitle font, not as boxes.
- **Blizzard's PvP line hidden.** No "(Contested Territory)" under the zone name. The subzone name sits 6 below SaftUI's line when you enter a zone (the two subtitle lines touched with no gap; the user asked for room, 2026-11-10), and right under the zone name, where Blizzard puts it, when there's no line or only the subzone changes. Free-for-all and combat zone text (`PVPArenaTextString`, under the subzone name) still shows. The flourishes take the new zone name's color. When a world quest's or PvP objective's banner plays over the zone text (Blizzard's `ZoneText_Clear`), SaftUI's line and the difficulty line clear with Blizzard's, and the lines either side of the zone name hide until the next zone shows a name.
- **Map label.** On a continent map, the faction word shows under Blizzard's "Zone (10-20)" label, 10 units below, in the label's description font (`SubZoneTextFont`) at its scale; on retail, under the wild battle pet levels line when that shows. Nothing over a point of interest, the map's own areas or a zone not in the table. The zone you stand in follows the live status, or the table when the game gives no status (an empty pvpType). With the gamepad UI on the line may never show: SaftUI finds the hovered zone by the mouse cursor and shows nothing when that isn't the zone the label names.
- **No taint.** Open the world map in combat and through a loading screen: no `ADDON_ACTION_BLOCKED` and no Lua errors. Use `/console taintLog 1` (`.agents/taint.md`) if anything is off.

**Why noticed:** The zone level and faction feature (2026-11-10). The stubs run no OnUpdate, layout pass or fonts, and stand in for the game's map and PvP answers, so placement, glyphs and the live API are in-game checks.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/ZoneText.lua` (`ZT:ZoneLine`, `ZT:UpdateZoneLine`, `ZT:UpdateMapLine`, `ZT:HookWorldMap`), `SaftUI-Misc/Skinning/blizzard/ZoneFactions.lua`; Blizzard's `Blizzard_FrameXML/Mainline/ZoneText.lua` and `Blizzard_SharedMapDataProviders/AreaLabelDataProvider.lua`; `tests/misc/zone_text_test.lua`, `tests/misc/zone_map_test.lua` and `tests/misc/zone_helpers.lua`.

**Shape of work:** An in-game pass. Fixes, if any, are likely offsets or a font.

### 2026-11-10 — Zone faction line edge cases: a PvP subzone's status, same-named zones on the map

**What:** Three narrow cases where the zone line can be off:
- **A PvP subzone's status.** When `C_PvP.GetZonePVPInfo()` says `isSubZonePvP`, its status is the subzone's (Blizzard shows it on `PVPArenaTextString`, under the subzone name), but SaftUI takes it for the zone's. Entering a faction's zone while standing in a free-for-all or sanctuary subzone, the zone text says Neutral, and so does the map for that zone. Most such subzones are in contested zones, where Neutral is right anyway.
- **A subzone during a cleared banner.** After a world quest or PvP objective banner clears the zone name (`ZoneText_Clear`), crossing into a subzone during the same fade brings SaftUI's level and faction line and the difficulty line back under the blank name, while the flourishes stay hidden. Blizzard's own PvP line, which this line replaces, does the same in the default UI.
- **Same-named zones on the map.** The map line is worked out again only when the label's text changes (or on a zone event or a color change). Retail has same-named copies of a zone with different factions (Eversong Woods 94 is Horde, 2395 and 2567 Neutral; Silvermoon City 110 Horde, 2393 Neutral). Switching between maps that show both, with the cursor never leaving the zone and the label's text identical, keeps the first answer.

**Why noticed:** The review of the zone level and faction feature (2026-11-10, minors 4 and 6), left as they are; the subzone case from its re-review (N1), left as it is because Blizzard's own PvP line behaves the same.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/ZoneText.lua` (`ZT:LiveFaction`, `ZT:MapFaction`, `ZT:UpdateMapLine`'s `mapLineFor`); `tests/misc/zone_map_test.lua`.

**What's been considered:** For the subzone: when `isSubZonePvP`, use the table's word for the zone, at least on the map. For a cleared banner: `ZT:UpdateZoneLine` and `ZT:SetZoneDifficultyText` also require a non-blank `ZoneTextString`. For the map: key the cache on the map's ID and the label text (`map:GetMapID() .. name`), which costs nothing.

**Shape of work:** Small: a few lines each, with a test each.

### 2026-11-10 — Zone text's fade times are written onto Blizzard's frames

**What:** `ZT:OnEnable` gives the zone text SaftUI's timing (fade in over 1s, hold 2s, fade out over 2s; Blizzard's is 0.5, 1 and 2) through Blizzard's `FadingFrame_SetFadeInTime`, `FadingFrame_SetHoldTime` and `FadingFrame_SetFadeOutTime` on `ZoneTextFrame` and `SubZoneTextFrame`. The setters write `fadeInTime`, `holdTime` and `fadeOutTime` onto Blizzard's frames from SaftUI's code, which `.agents/taint.md` rules 1 and 3 ask against.

**Why noticed:** Resolving "Zone text replaces Blizzard's OnEvent script with AceHook's HookScript" (2026-11-10, see Resolved). That entry asked about the `ZoneFadeInDuration` globals, which are now left alone; the setters behind them are the write that's left. They stay for now because dropping them changes what the user sees: the zone text would leave sooner.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/ZoneText.lua` (`FADE_IN`, `HOLD`, `FADE_OUT`, `ZT:OnEnable`); Blizzard's `Blizzard_FrameXMLUtil/FadingFrame.lua`; `.agents/taint.md` rules 1 and 3.

**What's been considered:** The fields' only reader is the frames' own OnUpdate, `FadingFrame_OnUpdate`, which turns tainted at the first read and then only sets the frames' alpha and hides them. Nothing protected hangs off either frame, so no blocked action is expected. The one way it could: another addon anchoring a protected frame to either one, which would make the tainted `Hide` a blocked action in combat, blamed on SaftUI. There's no way to change the timing that writes nothing onto them. The choices: keep it, and name it in `.agents/taint.md` as a known exception; drop the setters for Blizzard's shorter timing; or have SaftUI show zone text frames of its own instead of Blizzard's (a bigger change).

**Shape of work:** A decision, then a few lines, or a design pass for SaftUI's own frames.

**Open questions:** Is SaftUI's longer timing worth the exception?

### 2026-11-10 — The zone faction table is a snapshot of two builds

**What:** `SaftUI-Misc/Skinning/blizzard/ZoneFactions.lua` lists each client's zones by uiMapID as of Forever build 1.60.1.70888 and retail build 12.1.5.70783. A zone a later build adds gets no faction line on the world map (unless you stand in it) until the table is made again. Forever adds zones of its own: Riverglades, Shen'dralas and Zephras Isle are in this one.

**Why noticed:** Building the table (2026-11-10).

**Anchors:** the file's header, which gives the method; wago.tools' DB2 exports (`https://wago.tools/db2/<Table>/csv?build=<version>`, the builds at `https://wago.tools/api/builds`, where Forever is product `wowf`) of the UiMap, UiMapAssignment and AreaTable tables.

**What's been considered:** The table came from a throwaway Python script over those exports, following the header's rules (zone maps with a parent, minus test maps; AreaTable's FactionGroupMask 2 Alliance and 4 Horde, the sanctuary flag 0x800 or mask 6 Neutral, mask 0 taking the parent area's; then the named capitals and starting zones). Committing the script would make a refresh one command, but the repo has no tooling folder. Not covered: Forever's Darkspear Islands (2524, an orphan map the game marks contested), and retail's dungeon-type maps, among them Broken Isles Dalaran (627, a sanctuary) and Oribos (1670, which has no UiMapAssignment row, so it would need a named entry like the capitals). Those two are hoverable on their continents' maps and among the most visited places there; adding dungeon-type maps whose parent is a continent would cover them. The housing districts are in, as Neutral (sanctuaries), though each is one faction's.

**Shape of work:** Small: rerun against the new builds, diff, review the named overrides.

### 2026-11-10 — Chat writes fields and scripts onto Blizzard's chat frames

**What:** `SaftUI-Chat/chatframe.lua` (`CHT:SkinChatFrame`, `CHT:UpdateChatFrameDisplay`) writes Lua fields onto Blizzard's chat frames and replaces their scripts, which `.agents/taint.md` rules 1 and 2 forbid:
- `st:SetBackdrop` on each `ChatFrameN` (~73, ~128) writes `.backdrop` and `.thick` onto it. Its edit box no longer gets them: since the Blizzard theme's Task 8 (2026-11-11), `st:SkinEditBox` / `st:StyleEditBox` draw through `st:SetBackdropIn` with a table of their own, and conceal the box's border textures by alpha instead of `st:Kill`.
- `frame.EditBox`, `frame.EditBox.Header` and `.HeaderSuffix` (~96-98), `frame.Tab` (~113), and `frame.Tab.SetAlpha = UIFrameFadeRemoveFrame` (~121, when tab fading is off) are written onto Blizzard's frames.
- `frame:SetScript('OnMouseWheel', onMouseScroll)` on `ChatFrameN` (~85), and `SetScript('OnShow')` / `SetScript('OnHide')` on its edit box (~107-108, hiding and showing `GeneralDockManager`), replace Blizzard's handlers.
- On retail, `st:SkinScrollBar(frame.ScrollBar)` (~79) skins Blizzard's `MinimalScrollBar` through `SaftUI-Core/Widgets/scrollbar.lua` (`st:SkinNewScrollBar`), which still writes `.backdrop` and `.thick` (`st:SetBackdrop(thumb, ...)`, ~64) and `.entered` and `.pressed` (the thumb's hover and press state, ~35-50, read by `ColorThumb`) onto the bar's thumb, and `HookScript`s four of its scripts. Under the Blizzard theme the thumb is a control, so SaftUI draws nothing on it and shows MinimalScrollBar's own layers (`DrawScrollBar`), but the writes are unchanged. Core's own scroll frames (`st:CreateScrollFrame`, `SaftUI-Core/Widgets/scrollframe.lua`) are SaftUI's frames, where the writes are fine.

Since Themes there's also a new trigger for one of these writes. `st:RedrawThemed` (`SaftUI-Core/theme.lua`, `DrawBackdrop`, the `owner.thick = ...` line, ~349) runs the `owner.thick` write again on every theme change and every profile switch, copy or reset (ruling R13), for each `st:SetBackdrop` owner that isn't SaftUI's: `ChatFrame1` and the other chat frames, the chat edit boxes, and the unit frames' aura buttons (Blizzard's, `SaftUI-Unitframes/elements/auras.lua`, `StyleButton`). It's the same write the module's own `UpdateConfig` already made; only the trigger is new.

**Why noticed:** The Themes project's reviews (2026-11-10). Task 6, which converted chat's draw calls to Theme and Background, carried the chat writes forward as pre-existing; the final review (`008527b..8250a53`) confirmed them and traced the new `owner.thick` trigger to R13's redraw on every profile change. None of the writes was introduced by Themes, which only changed the draw calls' arguments.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:SkinChatFrame`, `CHT:UpdateChatFrameDisplay`, `onMouseScroll`, `CHT:UpdateFootprint`); `SaftUI-Core/skinning.lua` (`st:SkinEditBox`, `st:StyleEditBox`, `DrawEditBox`, `ColorFocused`); `SaftUI-Core/Widgets/scrollbar.lua` (`st:SkinNewScrollBar`, `ColorThumb`, `thumbOnEnter`, `thumbOnMouseDown`); `SaftUI-Core/theme.lua` (`DrawBackdrop`, `st:SetBackdropIn`, `st:RedrawThemed`); `SaftUI-Unitframes/elements/auras.lua` (`StyleButton`, `ColorInnerLine`); `.agents/taint.md` rules 1, 2 and 11; `tests/chat/theme_test.lua`. The tooltip and roll bar skins already moved to side tables (see Resolved), and `tests/lib/locked_widget.lua` locks a frame so a skin that writes onto it fails.

**What's been considered:**
- Draw the chat frames and edit boxes with `st:SetBackdropIn(backdrops, frame, ...)`, and keep the backdrop, edit box, header and tab references in weak side tables keyed by the chat frame. Everything that reads `frame.backdrop` (the retail scroll bar's anchors, the edit box's anchors, `UpdateChatFrameDisplay`'s padding) reads the side table instead.
- Done for the edit boxes (2026-11-11): `st:SkinEditBox` draws through `st:SetBackdropIn`, for every box.
- Replace the `SetScript`s with post-hooks (native `HookScript`). Check whether `onMouseScroll` (Ctrl to the bottom, Shift a page, Alt a line, else several lines) can run after Blizzard's own wheel handler without scrolling twice. Replace the `Tab.SetAlpha` override with a post-hook that puts alpha 1 back after Blizzard's fade.
- The aura buttons are the same pattern on Blizzard's frames, but `.agents/taint.md` rule 11 limits what can be anchored there, so they're a separate step.

**Shape of work:** One task for chat (side tables, `st:SetBackdropIn`, post-hooks), with `tests/chat/theme_test.lua` locking Blizzard's chat frames as the misc fixtures do. A smaller second task for the aura buttons. Then an in-game check of chat scrolling, the edit box hiding the dock, and tab fading.

**Open questions:** Can `onMouseScroll`'s behavior be added on top of Blizzard's wheel handler, or does it need to replace it (which would need another approach than a script)?

### 2026-11-10 — The Hekili and WeakAuras skins error when Skinning's Theme is None

**What:** With Skinning's Theme set to None, `st:SetBackdrop` makes no backdrop (None only clears, and a frame never drawn has nothing to clear), but both skins use it on the next line:
- `SaftUI-Misc/Skinning/addons/hekili.lua:16`, `button.backdrop:SetFrameStrata('LOW')`;
- `SaftUI-Misc/Skinning/addons/weakauras.lua:11` and `:14`, `region.backdrop:SetFrameLevel(...)` and `:SetFrameStrata('LOW')`.

Each new Hekili button or WeakAuras icon then errors. The error comes before `skinned = true` and the `tinsert` into `skinnedButtons` / `skinnedRegions`, so it errors again on every call, and a later switch away from None doesn't reach those frames through `UpdateConfig`.

**Why noticed:** The Themes project's reviews (2026-11-10): Task 6 converted these skins to Theme and Background and carried this forward as pre-existing, and the final review confirmed it. The old `none` template behaved the same, so it predates Themes.

**Anchors:** `SaftUI-Misc/Skinning/addons/hekili.lua` (`HK:SkinIcon`, `HK:UpdateConfig`), `SaftUI-Misc/Skinning/addons/weakauras.lua` (`WA:SkinIcon`, `WA:UpdateConfig`), `SaftUI-Core/theme.lua` (`st:SetBackdrop`, which returns without making a backdrop for None); `tests/misc/theme_test.lua` (the Skinning page). There's no Hekili or WeakAuras stand-in in `tests/misc/fixtures/` yet.

**What's been considered:** Guard each `.backdrop` use, and still mark the frame skinned and record it, so `UpdateConfig` draws it once the theme isn't None. The strata and level then need setting after every draw, in `UpdateConfig` too, or a backdrop first made there sits at the default level. Both skins also write `.skinned` and `.backdrop` onto another addon's frames. Rule 1 doesn't bind third-party frames, but `.agents/taint.md` asks for side tables there anyway, and the same pass could move them.

**Shape of work:** Small: guards and a strata and level step after each draw in both files, with a test per skin over minimal Hekili and WeakAuras fixtures.

### 2026-11-10 — Edit box focus borders lost on a theme switch, and two ways of keeping colors

**What:**
- A focused chat or bag search box loses its white focus border on a theme switch, and on a profile switch, copy or reset. `Config:UpdateConfig` runs `st:RedrawThemed`, whose last step puts the colors kept with `st:KeepOwnColors` back on (the box's white, `ColorFocused`). Then it runs every module's `UpdateConfig`, and Chat and Bags restyle their boxes (`st:StyleEditBox`, which draws the box's backdrop again), painting the theme's border over the white. Nothing puts it back: `st:ColorsChanged('theme')`, which ends the update, calls modules' `OnColorsChanged` but not the kept colors.
- Colors a frame's own code puts on its backdrop are kept two ways. Modules use `OnColorsChanged('theme')`: edit mode's movers (`EM:OnColorsChanged`), and Bags, ActionBars, Loot's feed, Tooltip, the totem bar and Skinning's skins. Core's widgets and the unit frames' aura buttons register with `st:KeepOwnColors`. They run at different points of a profile update, which is what lets the first problem through. Unify them.

**Why noticed:** The Themes project's reviews (2026-11-10). Task 3's review found the focused box losing its border (deferred as minor), and the final review asked for the two mechanisms to become one. `st:KeepOwnColors` came out of ruling R8, which had Core's widgets keep their own colors "as the movers do", without a module to hang `OnColorsChanged` on.

**Anchors:** `SaftUI-Core/theme.lua` (`st:KeepOwnColors`, `PutOwnColors`, `st:RecolorThemed`, `st:RedrawThemed`); `SaftUI-Core/Config/config.lua` (`Config:UpdateConfig`, `RedrawTheme`); `SaftUI-Core/skinning.lua` (`ColorFocused`, `st:SkinEditBox`, `st:StyleEditBox`); `SaftUI-Core/Media/colors.lua` (`st:ColorsChanged`); `SaftUI-Core/EditMode/mover.lua` (`EM:OnColorsChanged`); `SaftUI-Chat/chatframe.lua` and `SaftUI-Bags/inventory.lua` (their `st:StyleEditBox` calls); `.agents/architecture.md`, Themes, "Colors a frame's own code puts on its backdrop".

**What's been considered:**
- The narrow fix: run the kept colors again at the end of `Config:UpdateConfig`, next to `ColorsChanged('theme')`, or have `st:StyleEditBox` run `ColorFocused` after it draws.
- Unifying: one moment, after every module's `UpdateConfig`, when owned colors go back on. Either `st:ColorsChanged('theme')` also runs the `st:KeepOwnColors` registry (and modules register per-frame callbacks instead of walking their frames in `OnColorsChanged`), or the registry becomes a Core module's `OnColorsChanged('theme')`.

**Shape of work:** Small for the edit box. A small refactor in Core for the unification, with each module's kept-color tests as the guard (`tests/core/theme_core_frames_test.lua`, `tests/bags/theme_test.lua`, `tests/actionbars/theme_test.lua`, `tests/misc/theme_test.lua`, `tests/loot/theme_test.lua`, `tests/unitframes/theme_test.lua`).

**Open questions:** Unify toward per-frame callbacks, or toward per-module hooks?

### 2026-11-10 — Retail bank leftovers after Themes: category selector, selected window's border, radio group under None

**What:** Three retail-only issues in the bank windows (they use retail's `BankFrame.BankPanel` and the warband bank):
- **The combined bank's category selector** (Bank / Warband, `st:CreateRadioGroup` in `INV:InitializeBankCategorySelection`, `SaftUI-Bags/containers/combinedbank.lua:~28`) takes the Bags Theme and Background once, when it's made. A later change to the Bags Theme override reaches it only after a reload. A change to SaftUI's own theme does reach it, since its buttons are recorded and redrawn with the arguments they were made with.
- **The selected bank window's blue border** (`INV:SelectBankCategory`, `SaftUI-Bags/inventory.lua:~84-86`, for the separate bank and warband windows) is a plain `SetBackdropBorderColor`. No `OnColorsChanged('theme')` or `st:KeepOwnColors` puts it back, so a recolor or redraw turns it into the theme's border, and every Bags `UpdateConfig` resets it too.
- **The radio group's `ColorPicked`** (`SaftUI-Core/Widgets/radiogroup.lua:~19-21`) indexes `button.backdrop`, which a group drawn with a Theme of None (a Bags Theme of None) doesn't have, so clicking a selector button errors. The old `none` template did the same.

**Why noticed:** The Themes project's reviews (2026-11-10). Task 5 (Bags) found all three and deferred them: the selector as minor, the blue border and the None error as already so before Themes. All three are retail-only, and the user plays Forever, so none could be checked in game during the project.

**Anchors:** `SaftUI-Bags/containers/combinedbank.lua` (`INV:InitializeBankCategorySelection`), `SaftUI-Bags/inventory.lua` (`INV:SelectBankCategory`, `INV:UpdateConfig`), `SaftUI-Bags/container.lua` (the header `OnClick` hook that calls `SelectBankCategory`), `SaftUI-Core/Widgets/radiogroup.lua` (`st:CreateRadioGroup`, `ColorPicked`); `tests/bags/theme_test.lua`, `tests/core/theme_core_frames_test.lua` (the radio group cases).

**What's been considered:**
- The selector: give the radio group a way to restyle (`radioGroup:SetTheme(theme, background)`, redrawing its buttons and keeping the pick), called from the Bags `UpdateConfig`.
- The blue border: register it with `st:KeepOwnColors` on the selected window (forgetting the others), as the radio group does for its pick, or color it again in a Bags `OnColorsChanged('theme')`. This depends on how the "two ways of keeping colors" followup is unified.
- `ColorPicked`: guard `button.backdrop`.

**Shape of work:** Small, three pieces, with tests where the stubs reach (the radio group is tested; the bank windows need retail's `BankFrame`), and a retail in-game check.

### 2026-11-10 — Themes: in-game checks for what was only compile-checked

**What:** Parts of the Themes project can't be loaded by `tests/run` (they need Blizzard frames, globals or other addons the stubs lack), so they were only compile-checked and read through. Check them in game, and fix what's found.

On both clients:
- the Blizzard micro buttons' panels (`SaftUI-Minimap/microbuttons.lua`, `SkinButton`, drawn with `st:SetBackdropIn`) moving from Thick's border to Thin's on a theme switch, with no gap or overlap;
- zone text (`SaftUI-Misc/Skinning/blizzard/ZoneText.lua`): the flourish lines drawn Thin, keeping the zone name's color after a recolor;
- the character frame's gem slots (`SaftUI-Misc/Skinning/blizzard/characterframe/gems.lua`) in SaftUI's theme;
- the Hekili and WeakAuras skins (`SaftUI-Misc/Skinning/addons/hekili.lua`, `weakauras.lua`) following Skinning's Theme and Background, and a profile switch;
- the loot roll previews (`SaftUI-Loot/roll.lua`, `LT:CreateRollPreviews`) drawn like real roll bars.

On retail:
- the unit frames' aura buttons. `st:SetBackdrop` gives each of Blizzard's aura buttons a backdrop (`SaftUI-Unitframes/elements/auras.lua`, `StyleButton`), and `st:RedrawThemed` places it again on a theme switch and on every profile switch, copy or reset, while it still sits where it was drawn. Check, with auras up, in and out of combat, that this doesn't error or upset the aura container's layout (`.agents/taint.md` rule 11: a frame anchored to the container, or to anything anchored to it, must carry its layout aspect);
- `SetBackdropBorderColor` on a cleared backdrop: an action button holding an equipped item while the action bars' Theme is None (`AB:UpdateEquippedBorder` → `ColorEquipped`, `SaftUI-ActionBars/skin.lua`). Retail's backdrop mixin may error on a frame whose backdrop was cleared.

**Why noticed:** The Themes project's reviews (2026-11-10): Task 6 listed the micro buttons, zone text, gems, Hekili, WeakAuras and the roll previews as compile-checked only, and its review flagged the micro buttons' Thick → Thin switch; Task 4's review flagged the aura buttons' re-placing on a redraw; Task 5's review flagged the cleared backdrop. The final review gathered them into this list. The user plays Forever, so the retail items need a retail session.

**Anchors:** per item above; `tests/minimap/theme_test.lua`, `tests/misc/theme_test.lua`, `tests/loot/theme_test.lua`, `tests/unitframes/theme_test.lua` and `tests/actionbars/theme_test.lua` cover what the stubs reach.

**Shape of work:** An in-game pass on each client through the list, then a small fix for each problem found, with a test where the stubs allow.

### 2026-11-10 — Bag views: the bank windows build a full button pool per view

**What:** One bag and Multi bag give each section an item button for every slot of its bags, made out of combat (`INV:EnsureSlotPools`, `SaftUI-Bags/category.lua`), so a section never needs a new button in combat. That's right for the bag window, where loot lands mid-fight. The bank windows get the same full pools, though nothing lands in a bank in combat: a full retail combined bank is about 1,078 buttons per view, made in one burst the first time it's laid out in that view. In combat, `INV:FitSlots` already shows a section no more items than it has buttons, so smaller bank pools would still never make a button in combat.

**Why noticed:** The bag views branch's final review (2026-11-10), judging the fix for its I3 (One bag and Multi bag made item buttons in combat): fine for the bag window, a possible hitch for the banks.

**Anchors:** `SaftUI-Bags/category.lua` (`INV:EnsureSlotPools`, `INV:FitSlots`, `INV:QueueSlotTopUp`); `SaftUI-Bags/views.lua`; `tests/bags/views_layout_test.lua`, `tests/bags/views_onebag_multibag_test.lua`.

**What's been considered:** Sharing one pool across section frames would re-anchor item buttons between frames in combat, which Compact never does: rejected. Filling full pools only for the bag window and letting the bank windows' sections grow as Compact's categories do (`FitSlots` capping them in combat) keeps the guarantee.

**Shape of work:** Small: limit the full fill to `bag`, with a test; then an in-game look at opening a full combined bank in One bag or Multi bag for a hitch.

### 2026-11-10 — Bank eye toggle doesn't re-apply the bag search

**What:** In the combined bank, toggling a bank's eye (showing or hiding the bank or the warband bank, `INV:UpdateContainerBagIds`) lays the window out again but doesn't re-apply the bag window's search, so items can be lit or dimmed against a stale search until the next search change. It predates the bag views; a view switch now re-applies it (`INV:ApplyView`).

**Why noticed:** The bag views branch's final-review fix wave (2026-11-10), which made `ApplyView` re-apply the search and left the eye toggle as it was.

**Anchors:** `SaftUI-Bags/containers/combinedbank.lua` (`INV:UpdateContainerBagIds`, called from the eye buttons), `SaftUI-Bags/layout.lua` (`INV:ApplyView`), `SaftUI-Bags/search.lua` (`INV:UpdateSearchFilter`).

**Shape of work:** One line (call `INV:UpdateSearchFilter` after the toggle's layout) and a test.

### 2026-11-10 — Bag views: in-game checks for what the stubs can't show

**What:** The bag views (One bag, Multi bag, Compact, Rows, the title-bar switch, and View and Empty slots in `/sui`) were checked by `tests/run` and by reading the code. Some of it needs the real client. Check it in game and fix what's found.

On both clients:
- the four view buttons' icon art at title-bar size: legible, centered, not cropped, at the default Title bar height and at the extremes;
- the header fit in all four windows (bags, bank, warband bank, combined bank), with a 3px gap showing between the view buttons' borders, and to the close button's outline, under Thick and Thin, including a one-column window that widened so its centered title clears the buttons;
- the scroll bar of a window that scrolls, in every view: inside the window's right edge with the same padding as the content has on the left, and gone from a window that fits everything;
- the lit button in Buttons → Blue against Thick and Thin borders, and after a theme or color change;
- the secure item buttons in each view, in and out of combat: left and right click, use, shift-click, drag, and the tooltip;
- switching views in combat: the button lights and the view saves at once, and the window lays out when combat ends;
- the scroll position across a view switch, and across a switch back;
- Forever's bags: a profession bag or a quiver in One bag (under the main grid) and in Multi bag (its own section), and a profession bag in a bank bag slot in the bank's One bag;
- a special bag's title with its type in grey (`Name · Reagent Bag (n / m)`; Forever's herb bag, quiver and ammo pouch; a profession bag in a bank bag slot): the type is the client's localized item subtype, and a bag whose item gives none shows no type;
- a bag or bank tab the client gives no name (`C_Container.GetBagName` answers `''`, never nil): its Multi bag title is the fallback (Backpack, Bank tab N, Bag N), not blank;
- a long fight's loot in One bag and Multi bag: every item shows at once on a button made beforehand, with no "is tainted" error in chat;
- the junk coin (`bags-junkcoin`, Blizzard's `JunkIcon` on the item button) on auto vendor items: in the top left of the icon, inside the border, a gray, legacy gear or an item marked Auto Vendor showing it in all four views at and away from a merchant, a Protected item not, the coin not covering the item level or the crafting quality pip, it following the slot menu's Protected and Auto Vendor marks on the next update, and on retail that the template has the key (a missing one is skipped, so the coin just never shows); and at a merchant, Auto sell junk selling every stack in One bag and Multi bag, with the footer's Vendor profit line matching what was sold.

On retail:
- the bank tabs' names (`C_Bank` tab names) as Multi bag section titles, in the bank and the warband bank, including a tab the player has renamed.

**Confirmed in game (Forever, 2026-11-10):** the four view buttons' icon art and their spacing (a visible gap between borders, after the polish fix), the lit Blue border under Thick, Multi bag's sections in the bag window, the scroll bar inside the window's right edge when it scrolls, and a special bag's title naming its type ("Shipwright's Satchel · Reagent Bag", the middle dot drawn). Still open: the rest of the list above.

**Why noticed:** The bag views project's final task (2026-11-10). Its tests run on stubbed bags and frames (`tests/bags/bag_world.lua`, `container_helpers.lua`), so the icon art, real widths, secure buttons, combat lockdown and retail's tab names were only compile-checked and read through. The user plays Forever, so the retail item needs a retail session.

**Anchors:** `SaftUI-Bags/views.lua` (`INV:GetBagInfo`, the tab names), `SaftUI-Bags/layout.lua` (`INV:LayoutSections`, `INV:ApplyView`), `SaftUI-Bags/header.lua` (`INV:SetView`, `INV:HeaderMinWidth`, the view buttons), `SaftUI-Bags/category.lua` (`INV:EnsureSlotPools`, `INV:FitSlots`: the buttons made before a fight, and what shows in one), `SaftUI-Bags/slot.lua`; `tests/bags/views_switch_test.lua`, `views_layout_test.lua`, `views_onebag_multibag_test.lua`, `views_data_test.lua`; `docs/superpowers/specs/2026-11-10-saftui-bag-views-design.md`.

**Shape of work:** An in-game pass on Forever through the list, a retail pass for the tab names, then a small fix for each problem found, with a test where the stubs allow.

### 2026-11-10 — Bag item sort compares item levels as text, and should be built from blocks

**What:** SaftUI's item sort within a bag category builds a `sortString` that starts with the item level glued onto the name as text, then sorts it in descending text order (`GetInventoryItemInfo` and `sortCategory` in `SaftUI-Bags/category.lua`). So item level 80 sorts before 600, which sorts before 1: by first digit, not by number.

**Why noticed:** The builder check of the bag views design (2026-11-10) pointed it out while asking how Multi bag should order a whole bag. Within one category of similar items it rarely shows. On retail, where item levels run into the hundreds, gear of mixed levels in one category can come out in a surprising order.

**Anchors:** `SaftUI-Bags/category.lua` (`GetInventoryItemInfo`'s `sortString`, `sortCategory`); `docs/superpowers/specs/2026-11-10-saftui-bag-views-design.md`, whose views all use this sort.

**Also, from the user (2026-11-10):** while designing configurable bag categories (filter blocks combined with AND, OR and groups, edited in game), the user agreed the within-category sort stays as it is for that project, and said: "great point about sorting - we should tackle that later and do some work on the sort string to build it from blocks as well". So the sort itself should become configurable the same way: an ordered list of sort keys (item level, quality, name, expansion, stack count, …), each ascending or descending, edited in game like the category rules, with today's order as the default.

**Research already done:** the bag categories research (2026-11-10) found that `sortString`'s last two parts are always 0 because of field-name typos (`itemCount`, `itemId`), besides the item-level-as-text bug. It was a scratchpad report, not committed; its findings on the sort are summarized here. *The typos were fixed on 2026-11-12 (codebase cleanup, Task 3, the report's bug 5): `sortString` now ends with the stack count and the item ID, so within one item the bigger stack sorts first (as text still, so 9 before 10).*

**Shape of work:**
- Small now: compare the fields in turn (item level as a number, then name, quality and so on) instead of one concatenated string (the typos are fixed). Add a test of mixed item levels. Check with the user which order they want: highest level first, as the descending string intends.
- Later: sort keys as blocks, on top of the configurable categories project's data model and editor. It needs a brainstorm and a spec after that project lands.

### 2026-11-10 — The minimap has no SaftUI holder, so the screen edge margin only holds it in edit mode

**What:** Every frame the user can move is now kept inside the screen edge margin (`misc.clamp_inset`, General → Layout) by the game's clamp, except the minimap. Its mover's frame is Blizzard's `Minimap`, moved with no SaftUI holder (`SaftUI-Minimap/minimap.lua`, `blizzardFrame = true`), and SaftUI never clamps a Blizzard frame. So edit mode drags and nudges stop at the margin, but a Position typed in `/sui`, a position saved before the margin, or a larger margin leaves the minimap where it is.

**Why noticed:** The screen edge margin sweep (2026-11-10). The user asked for the margin to guard every frame "the same way bags do"; the decided design ruled out clamping Blizzard's frames (`.agents/taint.md`), and the minimap is the one mover without a holder.

**Anchors:** `SaftUI-Minimap/minimap.lua` (`OnEnable`, `UpdateConfig`, the `minimap` mover), `SaftUI-Core/api.lua` (`st:KeepInScreenMargin`), `.agents/edit-mode.md` (Screen edge margin, the holder pattern). Other frames anchored to the minimap: the experience bar's default (`SaftUI-Misc/config.lua`, `frame = 'Minimap'`).

**What's been considered:**
- A SaftUI holder, as the other takeovers have: the holder is the mover and is clamped, and `Minimap` is anchored to it. Frames anchored to `Minimap` keep working. Needs a check that nothing of Blizzard's re-anchors `Minimap` once it's out of the cluster.
- Clamping `Minimap` itself: it isn't an Edit Mode system (MinimapCluster is), and Blizzard's minimap code sets no clamp (`Blizzard_Minimap`'s `Mainline/Minimap.lua`, `Minimap.xml` and `Camelot/Minimap.lua` on `forever` have no `Clamp`), so `SetClampRectInsets` wouldn't fight Blizzard. But it goes against the rule of never clamping a Blizzard frame, and its rect can be secret on retail.

**Shape of work:** Small: a holder in `minimap.lua` and its mover pointing at it, then an in-game check on both clients.

**Open questions:** Holder, or an exception to the rule for `Minimap`?

### 2026-11-10 — panels.tab_height has no option, because nothing live reads it

**What:** `panels.tab_height` (21, in `st.defaults.panels`, `SaftUI-Core/Config/defaults.lua`) is the one leftover Core setting that got no `/sui` option when Global Settings gained its General tab and the Fonts tab's new rows. Since 2026-11-12 nothing reads it at all: the codebase cleanup's Task 5 deleted the dead tab helpers that were its only readers. Either remove the key, or keep it for a future tab skin and give it an option then.

**Why noticed:** Options project 3 (Core's leftover settings, `coresettings` branch, approved by the user 2026-11-10). The approved design gave every other Core setting an option (icon trim, title bar height, clamp inset, font shadow and spacing, and the header, button and panel fonts) and said `panels.tab_height` gets none, to be treated like chat's `linespacing`: a setting nothing applies gets no option, only a followup to wire it up or drop it. Chat's `linespacing` is in the Chat line of [Settings with no /sui option](#2026-11-09--settings-with-no-sui-option-settings-nothing-reads-and-frames-with-no-edit-mode-mover). `linespacing` itself was removed on 2026-11-12 (codebase cleanup, Task 4).

**Anchors:**
- `tab_height = 21` in `st.defaults.panels` (`SaftUI-Core/Config/defaults.lua`). No addon code and no test reads it.
- Its readers were `SK:UpdateTab`, `SK:SkinTab`, `SK:SkinTabHeader` and `SK:SkinBlizzardPanel` in `SaftUI-Misc/Skinning/skinning.lua`, which nothing called. The cleanup deleted them (Task 5, 2026-11-12). They also wrote fields onto Blizzard's tabs, which `.agents/taint.md` rule 1 forbids, so a future tab skin starts fresh, through side tables.
- `panels.font`, which the same helpers read, stays alive through check box labels (`SaftUI-Core/Widgets/checkbutton.lua`), the reader its Fonts → Kinds of text → Check box labels option names.

**What's been considered:**
- Removing the key: saved values are harmless (the 2026-11-09 audit settled that dead keys can be dropped from the defaults). The dead helpers that read it are already gone (2026-11-12).
- Wiring it up: only worth it once SaftUI skins a Blizzard window with tabs again, through side tables. Its option would then sit in General → Layout, with Title bar height.

**Shape of work:** Small. Removal: one default, plus the line in the options-coverage entry's Core list. Wiring it up belongs with whichever skin first needs tabs.

**Open questions:** Remove now, or keep it for a Blizzard panel skin the Themes project might bring?

### 2026-11-10 — Colors tab: role and rune colors, and a switch for Blizzard's class colors

**What:** Two additions to the Colors tab of Global Settings (spec `docs/superpowers/specs/2026-11-10-saftui-colors-tab-design.md`), left out of its first version: editable role colors (tank, healer, damage) and death knight rune colors (blood, frost, unholy), and a switch to use Blizzard's class colors instead of SaftUI's own muted palette.

**Why noticed:** Drafting the Colors tab design (2026-11-10). The draft listed both as non-goals; the user answered "we should follow up with this".

**Anchors:** `UF:UpdateColors` (`SaftUI-Unitframes/unitframes.lua`): `UF.oUF.colors.roles = st.config.profile.colors.roles or DEFAULT_ROLE_COLORS`, and the same for `runes`. The profile (`st.defaults.colors`, `SaftUI-Core/Config/defaults.lua`) has neither table, so oUF's colors are used. SaftUI has no Runes element yet, so rune colors need one first (`colors.power.RUNES` stays in the defaults, but nothing draws it and the tab has no row for it). `colors.class` in the same defaults is SaftUI's palette; Blizzard's is `RAID_CLASS_COLORS` (or `C_ClassColor.GetClassColor`).

**What's been considered:** Roles and runes would be two more sections of the Colors tab, which needs their defaults added to the profile (oUF's values) so there's something to edit; `UF:UpdateColors` then drops the fallback. The class switch is a toggle at the top of the Class section that greys the swatches out while on. Everything that reads `colors.class` (unit frames through `UF.oUF.colors.class`, the group previews, the unit tooltip) would then need to read through one helper, so the switch reaches them all.

**Shape of work:** Small to medium, after the Colors tab ships: two sections with defaults, plus a toggle and a single class color lookup.

**Open questions:** Whether the Blizzard switch also covers reaction colors (Blizzard's `FACTION_BAR_COLORS`).

### 2026-11-09 — st:Kill and st:SkinIcon still write onto Blizzard pieces (roll bars and elsewhere)

**What:** Two Core helpers write fields onto the frames they're given:
- `st:Kill` writes `Show`, `_Show` and `SetAtlas`;
- `st:SkinIcon` wrote `__stTexCoord`, plus a hook. *Update 2026-11-11 (commit 28c0448):* it keeps its crop and its hooked flag in weak tables of `skinning.lua`'s, so it now writes nothing onto the icon but its hook. `st:Kill` still writes.

The roll bar skin (`SaftUI-Loot/roll.lua`) calls them on Blizzard pieces: `IconFrame.Border`, `Timer.Background`, `NameFrame`, `Corner`, `IconFrame.Count`, `IconFrame.Icon`. That breaks `.agents/taint.md` rule 1. Other skins likely do the same. Separately, `SaftUI-Loot/popup.lua` writes `LootFrame.skinned`, but that file isn't loaded; it goes away with the loot window reskin.

**Why noticed:** The roll bar side-table fix (2026-11-09) left these alone, because the followup it fixed didn't list them. Both its implementer and its reviewer flagged them.

**Anchors:** `SaftUI-Core` (`st:Kill`, `st:SkinIcon`), `SaftUI-Loot/roll.lua`; grep `st:Kill(` and `st:SkinIcon(` across the repo for Blizzard targets.

**What's been considered:**
- For art: hide with `SetAlpha(0)` or `Hide()` plus a post-hook, instead of replacing `Show` (taint rule 4 and the totem skin's pattern).
- For icons: keep the tex-coord state in a weak table, keyed by the texture (done for `st:SkinIcon` in 28c0448; what is left of it is the hook it puts on the icon).

**Shape of work:** An audit of the callers, then a side-table version of `st:Kill` for Blizzard targets (and a look at `st:SkinIcon`'s hook).

### 2026-11-09 — Loot feed: a merge while scrolled shifts the scroll offset

**What:** `LootFeedPush` (`SaftUI-Loot/Feed/feed.lua`) still does `offset = offset + 1` when the feed is scrolled, even when the push merges into an existing entry (gold, or the same item) instead of adding one. A merge adds no entry, so the view probably shifts by one line for no reason.

**Why noticed:** The review of the "Older loot feed quirks" fix (2026-11-09) noticed it. It was outside that fix's scope.

**Anchors:** `SaftUI-Loot/Feed/feed.lua` (`LootFeedPush`, the merge branches, `offset`); `tests/loot/feed_test.lua`.

**Shape of work:** Small: bump the offset only on an insert, with a test.

### 2026-11-09 — st:CreateHeader writes title and close_button onto the Blizzard panels it skins

**What:** `st:CreateHeader(frame, title, close_button)` (`SaftUI-Core/panels.lua`) writes `frame.title`, `frame.close_button` and `frame.header` onto the frame it's given. That frame can be a Blizzard panel: the unloaded loot window code (`SaftUI-Loot/popup.lua`) hands it `LootFrame`, and is the only such caller left since the codebase cleanup deleted `SK:SkinBlizzardPanel` (2026-11-12). Its other callers pass SaftUI's own frames (`SaftUI-Bags/container.lua`, and `st:CreatePanel` in `SaftUI-Core/panels.lua`). Writing them breaks `.agents/taint.md` rule 1. It also keeps the frame inside the screen edge margin (`st:KeepInScreenMargin`), which is meant for SaftUI's own frames only (2026-11-10). The loot window code isn't loaded, so no Blizzard frame gets these writes today.

**Why noticed:** The options window rework (2026-11-09) fixed the same class of write in `st:CreateCloseButton`, which now uses a weak side table and `st:GetCloseButton(frame)`. Its re-reviewer pointed out that `CreateHeader` still does it. That's old code, outside that task.

**Anchors:** `SaftUI-Core/panels.lua` (`CreateHeader`, `closeOf`, `headerTitles`), `SaftUI-Loot/popup.lua`.

**What's been considered:** Use the same pattern: weak side tables keyed by frame, with accessors such as `st:GetHeader(frame)`. Then find every reader of `.header`, `.title` and `.close_button` and switch it over.

**Shape of work:** A small refactor in `panels.lua`, plus its readers.

### 2026-11-09 — st:CreateButton's SetText and SetFont aliases break when called as methods

**What:** `st:CreateButton` aliases `SetText` and `SetFont` onto its button, and both break when called the normal way, as methods (`button:SetText(x)`, `button:SetFont('pixel')`).

**Why noticed:** The final review of the edit mode grid/snap branch found the footer's Grid size label calling `sizeLabel:SetText(...)`, which would error in game. That call was fixed in the branch to use `sizeLabel.text:SetText(...)`; `button.lua` was left alone because it has other callers.

**Anchors:**
- `SaftUI-Core/Widgets/button.lua:8-9`. `button.SetText = button.text.SetText` passes the button, not the FontString, as `self` when called as `button:SetText(x)`, which errors. `button.SetFont = function(font) ... end` receives the button as `font` when called as `button:SetFont('pixel')`.
- `SaftUI-Bags/header.lua` calls `filterButton:SetFont('pixel')`, so the bag filter buttons' font is probably never set as intended.
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
- The element position editor `generators.uf_element_position` in `SaftUI-Unitframes/config/position.lua`.
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

**Progress 2026-11-10 (Themes, `themes` branch):** the templates are done. Global Settings has a Theme tab (Thick or Thin, the chosen theme's colors, Transparent background and Opacity, Reset), and every module's template option is a Theme and Background override that follows it by default; saved template choices migrate by themselves. That closes the Core list. **Next:** the Blizzard theme (project 2 of the templates split, its own spec), which builds on the kinds of frame every draw call now names. **Still open here:** `loot.popup.*`, Chat's `linespacing`, and the broken-option, mover and unit frame items below.

**Read by the code, no option in `/sui`:**
- **Core** (`SaftUI-Core/Config/defaults.lua`). Core's settings are under Global Settings in `/sui`.
  - `misc.icon_trim`, `misc.clamp_inset`. *Done 2026-11-10 (options project 3, `coresettings` branch): General → Icons → Icon zoom, and General → Windows (now Layout) → Screen edge margin.*
  - `fonts.<key>.shadow_offset` and `.spacing`. *Done 2026-11-10: each font's Shadow offset X, Shadow offset Y and Line spacing on the Fonts tab.*
  - `headers.font` and `.height`; `buttons.font` and `.template`; `panels.font`, `.template` and `.tab_height`. *Done 2026-11-10: `headers.height` is General → Windows (now Layout) → Title bar height, and `headers.font`, `buttons.font` and `panels.font` are Fonts → Kinds of text (Window titles, Button text, Check box labels). `buttons.template` and `panels.template` wait on the Themes project (*done 2026-11-10: they're `buttons.theme`/`background` and `panels.theme`/`background`, following Global Settings → Theme; a module's own look is set on its page*). `panels.tab_height` gets no option, since nothing live reads it: see [its own entry](#2026-11-10--panelstab_height-has-no-option-because-nothing-live-reads-it).*
  - `templates.*` can be picked from a dropdown but not edited. *Done 2026-11-10 (Themes): Global Settings → Theme edits the chosen theme's colors (`templates.thick` and `.thin`), its transparency and opacity; the dropdown is gone, and each module has a Theme and Background instead.*
  - `colors.text`, `.button`, `.item_quality`, `.power`, `.class`, `.reaction`, `.status` and `.renown`. Only `colors.experience` has pickers (Experience → General, since 2026-11-09). *Done 2026-11-10: the Colors tab of Global Settings.*
- **Misc** (`SaftUI-Misc/config.lua`): `tooltip.template` and `.font`, `skinning.font` and `.template` (the new Skinning page, `SK:GetConfigTable`) and `totembar.colors.*` now have options (Task 4 of the options layout project, 2026-11-09).
- **Action bars:** `actionbars.template`.
- **Bags:** `inventory.enable`, `template`, `padding`, `categoryTitleHeight`, `scrollSpeed`, `autorepair`, `autovendor`, `combinedBank`, `inverted`, `fonts.titles` and `fonts.icons` now have options (Task 5 of the options layout project, 2026-11-09): Bags → General and Look.
- **Chat:** ~~`chat.linespacing` is left without an option, because nothing applies it. Only `CHT:ChatFrame_OnUpdate` (`SaftUI-Chat/chatframe.lua`) reads it, and its `SecureHook` is commented out, so the setting is read by nothing. Either hook it back up (the function sets each line's spacing once, so a change would also need the lines un-marked `handled`, and it writes a field onto Blizzard's chat lines, which `.agents/taint.md` forbids, so it needs a side table) and give it an option, or remove the key.~~ *Done 2026-11-12 (codebase cleanup, Task 4): the key and `CHT:ChatFrame_OnUpdate`, its only reader, were removed.*
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
    - the nameplate table (the user: "almost everyone just uses plater"). *2026-11-11: the nameplates plan brought SaftUI's plates back, as a `nameplate` unit (`SaftUI-Unitframes/config/units/nameplate.lua`, `nameplates/`).*
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
- **The zone text banner,** fixed at `TOP, 0, -300` (`SaftUI-Misc/Skinning/blizzard/ZoneText.lua:51`). The user said to leave it for now.
- **The loot window.** Blizzard places it, and SaftUI's skin isn't loaded (see Loot above). The user said to leave its position for now.
- ~~**`Blizzard_WatchFrame.lua`** returns early on `st.retail`, which is true on both supported clients, so it is dead code rather than a gap.~~ *Deleted 2026-11-12 (codebase cleanup, Task 5).*
- Everything else SaftUI places has a mover.

**Why noticed:** On 2026-11-09 the user asked to "go through all of the existing config settings in saftui and see what all hasn't been setup in the config gui yet as well as what modules haven't been setup on edit mode". Three read-only agents audited the defaults by area (unit frames; Core, minimap and misc; action bars, bags, chat and loot). The session checked the edit mode side, and spot-checked the dead-setting and broken-option claims with greps.

**Anchors:**
- Defaults: `SaftUI-Core/Config/defaults.lua`, `SaftUI-*/config.lua`, `SaftUI-Unitframes/config/default.lua`, `SaftUI-Unitframes/config/units/*.lua`.
- Options: each module's `GetConfigTable`; the shared generators in `SaftUI-Core/Config/generators.lua`.
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
- Should global colors and templates be editable at all? *Answered 2026-11-10: yes. Colors are the Colors tab; templates became themes, edited on the Theme tab.*

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

**What:** Three of SaftUI's Blizzard Edit Mode takeovers anchor the Blizzard frame straight to SaftUI's holder: `GameTooltipDefaultContainer` to `SaftUITooltipHolder` (`SaftUI-Misc/tooltipposition.lua`, `UpdateTooltipAnchor`), `BuffFrame`/`DebuffFrame` to their holders (`SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua`, around line 449), and the swing timer bars to theirs (`Blizzard_SwingTimerPosition.lua`, around line 79). Blizzard's Edit Mode can read such a frame's anchor and write it into the active layout (`EditModeManagerFrameMixin:UpdateSystemAnchorInfo`, which stores `relativeTo:GetName()`), and a layout save keeps it. Wherever the holder doesn't exist (an alt with that SaftUI addon off, or the module disabled), Blizzard's `ApplySystemAnchor` would then anchor the frame to a frame that isn't there.

**Why noticed:** The totem bar mover's review (fix round 1, 2026-11-08, `.superpowers/sdd/2026-11-08-totem-mover/review-1.md`) found the same exposure for the totem bar. There the bar is snapped to MainActionBar in its default position; entering a vehicle out of combat hides MainActionBar, `BreakSnappedFrames` runs the bar's `BreakFrameSnap`, which re-anchors it (SaftUI's post-hooks put it on the holder) and then calls `OnSystemPositionChange` → `UpdateSystemAnchorInfo`, reading `GetPoint(1)`. The totem bar was fixed by placing the bar on UIParent at the holder's spot instead (`TB:AnchorBar`, re-run from a post-hook on the holder's `SetPoint`), and `.agents/edit-mode.md`'s takeover bullet now says to do that. The three older takeovers predate the rule and weren't checked.

**Anchors:** `SaftUI-Misc/tooltipposition.lua`, `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua`, `SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimerPosition.lua`, `SaftUI-Misc/totemposition.lua` (`TB:AnchorBar`, the pattern to copy), Blizzard source in `Blizzard_EditMode/Shared/EditModeSystemTemplates.lua` (`BreakFrameSnap`, `BreakSnappedFrames`, `SetSnappedToFrame`, `PrepareForSave`) and `EditModeManager.lua` (`UpdateSystemAnchorInfo`, `OnSystemPositionChange`). Related: the chat entry below (item 2), where ChatFrame1 copies its holder's anchor, so the layout names UIParent by default.

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
- **Held rolls** (`roll.lua`'s held rolls, `rollinfo.lua`'s `OnRollChosen` and `OnBarHide`), from Blizzard's source, not the game:
  - choosing (any button) makes the server send `CANCEL_LOOT_ROLL`, so Blizzard's bar hides at once, and a main spec Need hides it after its 5 second dice animation;
  - a roll's time: `START_LOOT_ROLL`'s rollTime and `GetLootRollTimeLeft` share a unit (Blizzard's `GroupLootFrame_OnUpdate` clamps one to the other) and `GetLootRollTimeLeft` is documented in milliseconds, so the live bars' countdown, which showed it as seconds, was wrong. `LT.RollSeconds` takes a length over 1000 as milliseconds, and the live and held countdowns both read through it. Look at the countdown in game;
  - `GameTooltip:SetHyperlink` takes the roll's full item link (a held bar's tooltip);
  - does `GetLootRollItemInfo(rollID)` still return the item after you've rolled, until the roll ends? If so, it could end a held roll with no loot history drop when the roll ends. Today such a held roll stays until its time runs out, even once the item is awarded;
  - `/reload` with a roll held drops it: held state isn't saved, and after the reload nothing links the roll to a drop. Decide whether that's acceptable;
  - visuals: a held bar sits exactly where its roll was, at Blizzard's DIALOG strata; its buttons are Blizzard's roll button art (the `lootroll-toast-icon-*-up` atlases), with only your choice's bordered, in Buttons > Blue, its art inset inside the border; the label sits before the timer; a new roll goes after every bar already up.

**Why noticed:** The loot rolls plan's final review (2026-11-08) listed these as unverifiable outside the game.

**Anchors:**
- `SaftUI-Loot/Feed/rolls.lua`: `RollTimeOver`, `GetOpenDrops`, `CatchUp`, `EstimateWhen`.
- `SaftUI-Loot/rollinfo.lua`: `UpdateRollBars`, `OnRollChosen`, `OnBarHide`.
- `SaftUI-Loot/roll.lua`: `LT.RollSeconds`, `LT:HoldRoll`, `LT:LayoutRollFrames`.
- `.agents/clients.md` "Loot rolls".
- `docs/superpowers/specs/2026-11-08-saftui-loot-rolls-history-design.md`.

**Shape of work:**
- In game (Forever, group loot): watch counts through a whole roll, roll two copies at once, `/reload` mid-roll and after, relog, roll on trash. Choose on a roll (each button, and a main spec Need) and watch the held bar until the item is awarded, and let one run out.
- Fix whatever doesn't hold.
- Record what's confirmed in `.agents/clients.md`.

**In game 2026-11-13:** the held bar doesn't stay up after a choice. See [Loot rolls: the roll bar doesn't hold after a choice](#2026-11-13--loot-rolls-the-roll-bar-doesnt-hold-after-a-choice).

### 2026-11-08 — Saved loot feed size in SaftUI_DB

**What:** The loot feed is saved per character in `SaftUI_DB` (AceDB char namespace), which is account-wide, so every character's feed is loaded at every login. 500 roll results with full roll lists come to about 1.6 MB per character at 20 players and 2.8 MB at 40, by the final reviewer's estimate. Several raiding characters could push `SaftUI_DB.lua` to 10 MB or more, parsed at every login and written at every reload.

**Why noticed:** The loot rolls plan's final review (2026-11-08), finding 4.

**Anchors:** `SaftUI-Loot/Feed/history.lua` (`SAVED_FIELDS`, `CopyRolls`), `SaftUI-Loot/Feed/loothistory.lua` (`LT:SummarizeDrop`'s trimmed lists). The reviewer's size estimate script is gone with the session scratchpad.

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

**Anchors:** `SaftUI-Minimap/minimap.lua` (`OnEnable`), `micromenuitems.lua` (mail and tracking hosting), `zonetextbutton.lua`, `instancedifficulty.lua`, `queuebutton.lua`, `addoncompartmentframe.lua`; Blizzard's `Blizzard_Minimap/Mainline/Minimap.xml` (`MinimapCluster` inherits `ResizeLayoutFrame`, `enableMouse="true"`) and `Minimap.lua` (`MinimapClusterMixin`), on `forever` and `live`.

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

### 2026-11-07 — Unit frame defaults that nothing reads, or that break when turned on

**What:** Adding `/sui` tabs for the remaining unit frame elements turned up defaults (`SaftUI-Unitframes/config/default.lua`, `config/units/*.lua`) that do nothing, or that error once turned on. They were left out of the options:
- **Read by nothing:**
  - Auras: `font` (the count always has its own `count.font`), `showDebuffType`, `horizontal_growth`, `showBar` (player buffs) and `border` (target buffs). Also the `filter` tables and `desaturateOthers`, which the aura-container followup below covers.
  - Additional power: `colorClass` (oUF's AdditionalPower only knows `colorPower`), `text.hide_full`, `text.percent`. *2026-11-09 (0308977): `colorClass` removed; `text.hide_full` and `text.percent` hooked up.*
  - Class power: `show_empty` is read (`elements/classpower.lua`) but changes nothing, since oUF already shows every point up to the max.
  - Focus `castbar.colors.normal = { .5, .9, .7 }`: a list, but `GetRGB` reads the `r`/`g`/`b` that the base default's color fills in, so the focus castbar uses the base color. *Fixed 2026-11-09 (options layout project, Task 9): now `{ r = .5, g = .9, b = .7 }`.*
  - Raid target `position.element = 'Portrait'`: Portrait isn't registered, so the marker anchors to the unit frame.
  - `widget` (`widget.lua` is commented out of `elements/elements.xml`, and it has no `UpdateConfig`), `portrait` and `aurawatch` (their `RegisterElement` calls are commented out).
- **Errors once on** (*both fixed 2026-11-09:* `colorCustom` reads either color shape through `UF.UnpackColor`, and is applied in `PostUpdateColor` after oUF's recolor on health, power and additional power, with power backgrounds following it. The castbar's `bg` has `alpha`/`multiplier` defaults and is colored from the bar. `tests/unitframes/bar_colors_test.lua`. Still open: `grouppreview.lua`'s preview path (Test mode's previews, moved out of `groups.lua` on 2026-11-12) applies the custom power color without `UF.SetPowerBackgroundColor`):
  - `castbar.bg.enable`: the castbar's `bg` has no `alpha` or `multiplier`, so `UF:UpdateStatusBarElement` calls `bg:SetAlpha(nil)`. Nothing colors the background either.
  - `colorCustom` on health, power and additional power: the `customColor` defaults are plain `{ r, g, b }` lists, and `config.customColor:GetRGB()` errors on them.
- **Half done:** `additionalpower.manaAsPrimary` swaps the size, texture and text settings of the Power and AdditionalPower bars (`UF:UpdateElement`'s `configOverride`). It didn't swap their positions. *Fixed 2026-11-12 (codebase cleanup, Task 2): `UF:UpdateElementPosition(element, configOverride)` now gets the override, so the two bars trade places too. The commented-out `Override` and power's `GetDisplayPower`, which never ran, are gone. What's left is a look in game, by a profile edit: the setting has no `/sui` control.*
- **Looks broken:** additional power defaults to `colorPower = false`, and nothing else colors the bar or its background, so it's white once enabled. Its `/sui` option says so. *Fixed 2026-11-09 (options layout project, Task 9): the default is `colorPower = true`.*

**Progress 2026-11-09:** the additional power bar's color (`colorPower = true`), the focus castbar color (now `{ r, g, b }`) and the health text Deficit defaults (on every unit) are fixed (options layout project 2, Task 9, `e5e4426`), and `colorCustom` and the castbar background were fixed earlier the same day. What's left is the "read by nothing" keys, `show_empty`, Raid target's `Portrait` anchor, and a look at `manaAsPrimary` in game (its position half was fixed on 2026-11-12).

**Why noticed:** On 2026-11-07, while adding Castbar, Class power, Additional power, Buffs, Debuffs and indicator tabs to `/sui` → Unitframes (the user asked to "start adding other UF elements to the config"). The rule for that pass was to expose only settings the element code reads, and note the rest.

**Anchors:** `SaftUI-Unitframes/config/default.lua`, `config/units/focus.lua`, `config/units/player.lua` (`manaAsPrimary`); `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`, `UF:UpdateStatusBarElement`, `UF.UnpackColor`); `SaftUI-Unitframes/elements/additionalpower.lua`, `power.lua`, `health.lua` (`PostUpdateHealth`), `classpower.lua`, `auras.lua`, `elements/elements.xml`; `SaftUI-Unitframes/grouppreview.lua` (the preview path).

**What's been considered:**
- Keys nothing reads can simply be dropped from the defaults. Saved values of them are harmless.
- `customColor`: store it as a color (`CreateColor`), or read it with something like `updaters.lua`'s `UF.UnpackColor`, which takes either shape. Then `colorCustom` and a color picker could go into the Health and Power tabs.
- Castbar background: give it `alpha` and `multiplier` defaults and color it from the bar color, or drop `bg` from the castbar defaults.
- Additional power: default `colorPower = true`, or color the bar in `PostUpdateColor` when oUF passes no color.

**Shape of work:** A small cleanup of the defaults, plus two small fixes (`customColor`, the castbar background). `manaAsPrimary` only needs a look in game now.

**Open questions:** `manaAsPrimary` works as of 2026-11-12, but has no `/sui` control: give it one, or remove it? Should the focus castbar get its own color back? *(The second was settled by the options layout spec: yes, fixed 2026-11-09.)*

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

**What:** Minor items left after the chat frame became a mover (Task 12, `2ad2e90`) and SaftUI took over its size (`ccfcaa2`):
1. `SaftUI-Chat` re-anchors the edit mode mover's overlay (`mover.overlay`, a Core internal) to cover the chat plus padding. A Core API for a mover's footprint (e.g. `def.footprint` or an `overlayInsets` field) would replace that reach-in.
2. Blizzard's `UpdateSystemAnchorInfo` copies ChatFrame1's current anchor into Blizzard's saved Edit Mode layout. A Blizzard Save can store SaftUI's placement there. It's harmless while SaftUI-Chat is on, but with it off the chat comes back at that spot instead of Blizzard's.
3. Blizzard clamps the chat frame about 32px from the screen's left and bottom edges (`UpdateClampOffsets`). SaftUI's holder isn't clamped, so dragging the outline into that band leaves the outline and the chat apart.
   *Update 2026-11-10:* the holder is now kept inside SaftUI's screen edge margin (20 by default), and ChatFrame1 follows where it shows (`st:GetClampShift`), so drags stop at the margin. Where the margin is narrower than Blizzard's band, the outline and the chat can still be apart by the difference (about 12px at the left and bottom with the default margin). Not yet confirmed in game.
   *Update 2026-11-13:* fixed (6f12ab9): the chat's holder stops where ChatFrame1's own clamp stops it (`st:KeepHolderInScreenMargin`, which reads the frame's clamp live and hooks `UpdateClampOffsets`), so the outline and the chat stop together. Not yet seen in game. Chat's border sits 10px outside its clamped area, and its default place (30, 30) shows at 32.
4. `CHT:SkinChatFrame` still calls `frame:SetClampRectInsets(0,0,0,0)` on every chat frame, ChatFrame1 included (`SaftUI-Chat/chatframe.lua:67`). Blizzard writes ChatFrame1's clamp again on every layout apply (`UpdateClampOffsets`), so until then the chat and its holder can reach the margin, and then both jump to Blizzard's 32. Nothing splits (the holder reads the clamp live), but it goes against `.agents/taint.md` rule 5 and the comment in `st:KeepHolderInScreenMargin`. Leave ChatFrame1 out of that call, so its band is always Blizzard's. Found by the screen margin fix's review (2026-11-13).

**Why noticed:** The Task 12 review and the fix round (`.superpowers/sdd/2026-11-06-saftui-edit-mode/task-12-review.md`).

**Anchors:** `SaftUI-Chat/chatframe.lua` (holder, `PlaceChatFrame`, overlay re-anchor); `SaftUI-Core/EditMode/mover.lua` (overlay creation).

**Shape of work:** Small. A footprint option in `st:RegisterMover`; keep the holder at least Blizzard's insets in (e.g. the larger of them and the margin); item 2 may just be documented.

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
1. Aura group options on unit frames: filter (`onlyShowPlayer`), `max`, button `size`, which borders show, and whether buttons get a cooldown. They're baked into the `AuraContainer` group when it's made. Their `/sui` options (the Buffs and Debuffs tabs) say "Reload to apply". This is the open question in the aura-container followup below. *Update 2026-11-12: the filter (2026-11-11), `max` and the button `size` now apply live (`SaftUI-Unitframes/elements/auras.lua`, the friendly nameplates build); only which borders show and the cooldown still need a reload, and on a plate they're the Enemy page's while it has the area on ("Nameplates: the Friendly page's aura borders and cooldown never reach plate buttons").*
2. `chat.tabs.fade`: turning fading off replaces `Tab.SetAlpha` on Blizzard's chat tabs at enable. Undoing or redoing that live would mean more writes onto Blizzard frames.
3. Module on/off switches such as `inventory.enable`, and `minimap.compartment_buttons` (its option already says it needs a reload).
4. ~~Party and raid group headers: their size and layout attributes are set at spawn.~~ **Resolved 2026-11-07** (edit mode Task 15): `UF:ApplyGroupLayout` (`SaftUI-Unitframes/groups.lua`) re-applies every header attribute, resizes the buttons, and re-registers the visibility on option edits and profile switches. In combat it waits for combat to end. Nothing in the headers needs a reload now.
5. ~~Templates, colors, headers and buttons have no options UI, so they're the same in every profile unless the saved variables are edited by hand. Modules re-apply their own templates on a switch, but frames styled once at creation with a fixed template (header bars, close buttons, edit mode overlays, the /sui window) don't pick up a profile's different template colors. `st.template_cache` and `Config:UpdateTemplateConfig` look meant for this, but `UpdateTemplateConfig` reads `self.template_cache` on the Config module (it lives on `st`) and loops without `pairs`, so it never worked.~~ **Resolved 2026-11-10** (Themes): `st.template_cache` and `UpdateTemplateConfig` are gone. Colors have the Colors tab and the theme the Theme tab, and `SaftUI-Core/theme.lua` records every drawn frame. `Config:UpdateConfig`, which every profile switch, copy and reset runs (and the Theme tab, through `st:ThemeChanged`), redraws them all in the profile's theme before the modules update (`st:RedrawThemed`; after combat if in it) and ends with `st:ColorsChanged('theme')`, so the borders modules color themselves come back (`OnColorsChanged('theme')`, `st:KeepOwnColors`). Frames drawn once at creation (header strips, the /sui window, edit mode's overlays, Core's buttons) take a switched-to profile's theme and colors with no reload (`tests/core/theme_core_frames_test.lua`).

**Why noticed:** On 2026-11-07, while making profile switches apply live across all modules and unit frames. The user asked for "update steps for those modules and for unit frames so that everything cleanly changes" on a profile switch, instead of needing a `/reload`. These were the pieces that couldn't be made live cleanly in that pass.

**Anchors:** `SaftUI-Core/Config/config.lua` (`Config:UpdateConfig`), `SaftUI-Unitframes/elements/auras.lua` (`AddGroup`), `SaftUI-Chat/chatframe.lua` (`SkinChatFrame`, `tabs.fade`), `SaftUI-Bags/inventory.lua` (`OnEnable`), `SaftUI-Core/theme.lua` (`st:SetTemplate` and the other draw calls, the drawn-frame record, `st:RecolorThemed`, `st:RedrawThemed`), `SaftUI-Core/Media/theme.lua` (`st:ThemeChanged`).

**What's been considered:**
- Item 3 matches the rest of the UI: module toggles generally need a reload. A "Reload to apply" message on a switch that changes one would be enough.
- For item 2, a `hooksecurefunc` on each tab's `SetAlpha` that re-applies alpha 1 while fading is off would be taint-safe and could follow the profile.
- For item 5, fixing `UpdateTemplateConfig` (`pairs(st.template_cache)`, and recording the latest template per frame) would re-color every templated frame. But it would also reset borders that modules recolor after `SetBackdrop` (bag slot quality, the edit mode overlay, the unit tooltip), so those would need re-applying after it. *Superseded 2026-11-10: the Themes project built that (the drawn-frame record and its recolor and redraw, with those borders put back), and runs it on every profile switch, copy and reset.*

**Shape of work:** Small items, separable: a reload hint for 3 and a tab `SetAlpha` hook for 2 (5 is done). Item 1 depends on the aura-container research.

**Open questions:** Will templates or colors ever get options? *Answered 2026-11-10: both did (the Colors and Theme tabs).*

### 2026-11-05 — Aura filters and per-aura styling lost in the oUF aura-container rewrite

**What:** Buffs/Debuffs were rebuilt on oUF master's Auras meta element (Blizzard `AuraContainer`). Several aura config options no longer do anything: the `filter.whitelist`, `filter.blacklist` and `filter.time` settings, `desaturateOthers`, and changing group options (`max`, `size`, `onlyShowPlayer`, borders) without a `/reload`.

**Why noticed:** Swapping SaftUI-Unitframes from the old bundled oUF copies to oUF-wow/oUF master (`c5ff6e4`). Master removed the classic `Buffs`/`Debuffs` element and its `FilterAura`/`PostUpdateButton` callbacks. The new containers process auras natively and don't hand aura data to Lua, which is consistent with Midnight's secret values. So SaftUI's Lua filters had nothing to run against. All of the lost filters were disabled in the defaults at the time, so no default behaviour changed.

**Anchors:** `SaftUI-Unitframes/elements/auras.lua` (commit `255a5ae`), `SaftUI-Unitframes/config/default.lua` (`auras` / `buffs` / `debuffs` tables), `SaftUI-Unitframes/Libraries/oUF/elements/auras.lua` (`AddGroup`, `AddSlot`, `CreateButton`).

**What's been considered:**
- Group options include a `candidateFilters` table (the oUF docs show `includeSpellIDs` on `AddSlot`). That could replace the spell whitelist, and possibly the blacklist, if the group options support the same keys. Verify against `CustomAuraContainerGroupDefaultOptions` on warcraft.wiki.gg.
- Duration filtering may be expressible through the container's processing `policy` (`CustomAuraContainerAuraProcessingPolicy`).
- Live updates to group options would need either an AuraContainer API to remove or clear groups, or recreating the container on config change.
- Found 2026-11-07 (review of the unit frame element options): groups can't be removed, but `CustomAuraContainerSharedMixin` (`Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua`, on `live` and `forever`) has `SetAuraGroupMaxFrameCount(key, n)`, `SetAuraGroupFilterString(key, filter)` and `SetAuraGroupLayout(key, layout)`. `elements/auras.lua` now keeps the key oUF's `AddGroup` returns as `auras.groupKey` and re-applies the spacing with `SetAuraGroupLayout` (`af25f66`). `max` and `onlyShowPlayer` could go live the same way and lose their "Reload to apply". Size, borders and cooldown are button options, set when a button is made, so they still need a reload.
- Update 2026-11-11: the filter string and candidate filters now go live (`UF:ApplyAuraFilter`, `SaftUI-Unitframes/aurafilters.lua`, nameplates Task 10), so `onlyShowPlayer` lost its "Reload to apply". `max` still needs a reload.
- Update 2026-11-12: `max` now goes live through `SetAuraGroupMaxFrameCount` on every update, and the button size through `StyleButton` setting each button's size from the config in use, so Size, Relative size and Max lost their "Reload to apply" (the friendly nameplates build: a plate's aura count and size follow its kind). Borders and the cooldown are still baked into each button when it's made ("Nameplates: the Friendly page's aura borders and cooldown never reach plate buttons").

**Shape of work:** A research pass on the AuraContainer API (group options, policies, removing groups), then a small change in `elements/auras.lua` that maps config to options. It may also need a config-schema cleanup to drop options that can't be supported.

**Open questions:** Which of the old filter options are worth keeping at all? (Removing groups isn't supported; changing a group's filter, max and layout is.)

## Resolved

### 2026-11-13 — Theme change errors in the theme engine: can't measure restricted regions

**What:** Picking another theme in `/sui` throws "Can't measure restricted regions" from `IsPlaced` in `SaftUI-Core/theme.lua`, at its `backdrop:GetPoint(i)`, 40 times in one session on Forever. The redraw of that frame's backdrop stops there, so some themed frame may keep the old theme's look until a `/reload`.

**Why noticed:** BugGrabber's log, read on 2026-11-13 while looking for a Loot error. The user hasn't reported a symptom.

**Anchors:** `SaftUI-Core/theme.lua` (`IsPlaced`, called from `DrawBackdrop` on a redraw; `RedrawThemed`); the stack runs from the theme dropdown's pick (`optionsselect.lua`, `optionswidgets.lua` Commit and Apply, `optionsmodel.lua` Set) through `SaftUI-Core/Media/theme.lua` (`ThemeChanged`), `SaftUI-Core/Config/config.lua` (`UpdateConfig`) and `RedrawThemed` to `DrawBackdrop` and `IsPlaced`; the backdrop frame is one made by `st:CreateFrame` (`SaftUI-Core/panels.lua`); `.agents/taint.md`, `.agents/clients.md` (secret values).

**What's been considered:** `IsPlaced` asks whether the backdrop still sits where the engine put it (two points, the placed offsets), so a redraw doesn't move a backdrop someone else placed. It already returns false when `GetPoint`'s results are secret values (`issecretvalue`). But for a restricted region `GetPoint` itself throws, before there is a value to test. Which themed frame is restricted isn't known: likely one whose backdrop is anchored to, or parented under, a frame the client restricts (a nameplate, or a frame showing secret values), which would also explain 40 at once (one per plate). No cause has been confirmed.

**Shape of work:** A debugging pass first (`superpowers:systematic-debugging`): which owner frames the 40 errors belong to, and whether a region is restricted for good or only at times (in combat, while it shows a secret value). Then a failing test with a `GetPoint` that throws, and a small fix: most likely a way to know the backdrop's placement without measuring it (the engine remembering that it placed it), or a protected call that treats a throw as "not placed".

**Open questions:** Which frames. Whether skipping the re-place on a restricted backdrop leaves it visibly wrong after a theme change.

**Resolved 2026-11-14:** the frames were the themed backdrops on SaftUI's nameplates (each plate's health bar, castbar and cast icon, and its aura buttons), seen again as 195 errors in one switch. The game's plates are anchor restricted, and so is everything anchored to one, for as long as it stays anchored there, in combat or out: addon code can't measure it (`GetPoint`, `GetRect`, the edges), though it can set its anchors. The error stopped the redraw of each such backdrop before it was placed and painted, so the redraw left it in the old theme's place, border and colors; the unit frames' update that follows in a switch drew each shown part anew, so no plate kept the old look, but every switch reported the errors. The engine now knows whether it still placed a backdrop from its own record and never measures one: post-hooks on the backdrop's anchor setters forget the record when anyone else moves it (`SaftUI-Core/theme.lua`, `Watch`). The stubs make every plate anchor restricted (`stub.restrict_anchors`, `tests/wow/widgets.lua`).

### 2026-11-13 — Action bars: shared settings for all bars, and Cooldown numbers as an Enable box

**What:** `/sui` → Action Bars sets text (hotkey, stack count, macro name, cooldown numbers: font, size, outline, position) per bar, and the Cooldown numbers box (Blizzard's own "Show Numbers for Cooldowns", `countdownForCooldowns`) sits loose at the top of the page beside Theme and Background. The user wants the settings every bar shares set in one place, with a single bar able to override.

**Why noticed:** The user's in-game look at the cooldown numbers change (072b9a3), 2026-11-13: "The cooldown numbers checkbox just being randomly placed at the top seems kind of weird, that checkbox should be an Enable checkbox in the Cooldown numbers section. Also a lot of these settings in the action bar (theme, font, size, are most likely things we want to have a shared config across all bars, we should have an option to have those common settings modifiable in one place for all bars." Asked which settings should differ per bar: "things like button count, per row, growth direction, spacing, size, position, combat fade, now that I think about it really the text and theme are the things that should be grouped for all action bars". On overrides: "I think a single bar should be able to override, but by default they all take the same configs". (The same message's third point, the Reset button's tooltip, was fixed in a5e8ea6 and b4e218c.)

**Anchors:** `SaftUI-ActionBars/options.lua` (header comment, `AB:GetTextOptions`, the Cooldown numbers toggle, `COUNTDOWN_NOTE`, the Reset), `SaftUI-ActionBars/config.lua` (`text = { hotkey, count, macro, countdown }` per bar), `skin.lua` (`AB:GetCountdownFont`, the CVar), `bars.lua` (`AB:UpdateBar`, the layout: no growth direction today), `AB.barTypes` (the pet and stance bars have only the hotkey and cooldown numbers). Precedent for "use the shared settings": the nameplate pages' "Use the other's settings" boxes (`SaftUI-Unitframes/nameplates/options.lua`).

**What's been considered:** Played back to the user 2026-11-13, awaiting their correction (the brainstorm was mid-way; the calls marked as the builder's are not the user's):

- An **All bars** entry, first in the bar picker. Its General tab holds Theme and Background (moved from the top of the page). Its Text tab holds the four texts. The Cooldown numbers section gets an **Enable** box at its top (Blizzard's setting, so all-bars only) and its Reset.
- Each bar's **General** and **Visibility** tabs stay per bar: enable, button count, buttons per row, size, spacing, position, combat fade.
- Each bar's **Text** tab: each of the four texts gets a "Same as All bars" box, checked by default. While it's checked the text's settings are hidden and it follows All bars. Unchecking shows them, starting from All bars' values. Checking again follows All bars but keeps the bar's own values for later. (Builder's call: per text, not one box per bar.)
- Theme and Background: all bars only, no per-bar override. (Builder's call.)
- Migration: All bars' text starts from Bar 1's. A bar whose text differs from Bar 1's starts with that text unchecked, so nothing changes on upgrade. (Builder's call.)
- Pet and stance bars show only the hotkey and cooldown numbers in their Text tab, as today.

**Shape of work:** A project. **Designed 2026-11-13:** the user chose from mockups (an All bars entry with marks only where a bar differs, Lucide's diff icon with a tooltip, texts as one-line menu items, no tabs on a bar, growth direction included, overrides per setting extended to layout and visibility) and said "Looks good, lets send it". The design is `docs/superpowers/specs/2026-11-13-saftui-actionbars-shared-settings-design.md`, which replaces the "What's been considered" list above where they differ. Next: the plan, then subagent implementation.

**Resolved 2026-11-13:** built as designed (spec `docs/superpowers/specs/2026-11-13-saftui-actionbars-shared-settings-design.md`, plan `docs/superpowers/plans/2026-11-13-saftui-actionbars-shared-settings.md`, six tasks): All bars first in the Bar picker, every shared setting followed until a bar owns it (`SaftUI-ActionBars/shared.lua`), the growth direction (First button), the kit's shareable options, menu items and per-setting resets in Core, and the page rebuilt on them (`SaftUI-ActionBars/options.lua`, `textoptions.lua`): no tabs on a bar, the four texts as menu items, and the cooldown numbers' box Blizzard's setting on All bars' Cooldown item. The "Same as All bars" box per text considered above gave way to per-setting own marks. The unit frames' version is its own followup, still active ("Unit frames: shared settings across units, and small parts as menu items").

### 2026-11-13 — In-game pass: five small changes asked for

**What:** The user's in-game pass over the cleanup's 39 checks (2026-11-13) turned up five small changes, each clear enough to build without a design round. They are being built on `modular` in the same session; this entry is the record in case the session is lost.

**Why noticed:** The user's own words, by the step each came from:

1. *Step 2, the character frame's item levels (Forever):* "Character frame item level doesn't seem to be skinned in foreveer". The screenshot shows a slot's item level in Blizzard's outlined number font. That has been so since the character frame was unskinned (e8ff3f6, 2026-11-07): `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua` makes the text from `NumberFontNormalSmall`. Wanted: SaftUI's icon text, as on bag slots (`SaftUI-Bags/slot.lua`).
2. *Step 31, `/sui edit`:* "Works but I noticed that I can drag the mover past the screen edge margin, looks kinda weird". The screenshot is the Chat mover dragged into the bottom left corner: its outline sits about 10px left of and 10px below the chat panel, which stopped short of it. Wanted: the mover's outline and the frame it moves stop at the same place.
3. *Step 9, the nameplate pages:* "the "use enemy/friendly nameplates" checkboxes work great, but instead of removing the tabs can we just fade them out and disable them? I don't love that it shifts everything up. Instead of the "Friendly nameplates use the enemy nameplates..." text can we replace it with centered text on the page that says "Sourced from enemy nameplates"? also when one of the swap buttons is disabled because the other one is enable can mousing over the checkbox explain why its disabled?"
4. *Step 21, the action bars:* "Can we add a setting for cooldown numbers that maps to the blizzard setting in sui's config? I'd also like options for the font and its position". Blizzard's setting is the `countdownForCooldowns` CVar ("Show Numbers for Cooldowns"), which the bars already follow (`SaftUI-ActionBars/skin.lua`, `buttons.lua`).
5. *Step 25, the Copy from dialog:* "Copy from is truncated on the popup can we remove the dividers from the all and non buttons and just shove them far right to expand the label? Can we also put a cancel button next to the confirm copy button and center them like most blizzard popup dialogs?" The screenshot shows the label cut to "Copy fr...".

**Anchors:** `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua`; `SaftUI-Core/EditMode/mover.lua` (`EM.MarginCorrection`, `Where`), `SaftUI-Core/api.lua` (`st:KeepInScreenMargin`, `st:GetClampShift`), `SaftUI-Chat/chatframe.lua` (the holder, `CHT:UpdateFootprint`); `SaftUI-Unitframes/nameplates/options.lua` (`PLATE_PAGES`, `HideWhileChecked`, `PlateBox`); `SaftUI-ActionBars/options.lua` (`AB:GetTextOptions`), `config.lua`, `skin.lua`; `SaftUI-Unitframes/config/config.lua` (`UF:OpenCopyTable`), `SaftUI-Core/Config/optionsdialog.lua`.

**Shape of work:** Five small tasks, one worktree each, a reviewer each, then an in-game check of each.

**Resolved 2026-11-13:** all five built on `modular`, each in its own worktree with a reviewer, and merged: the character frame's item levels in SaftUI's icon text (58a646a); the Copy from dialog with a full label, All and None at the right, and Confirm copy and Cancel centred (5eac40d); the nameplate pages' tabs faded and disabled, the centred "Sourced from enemy nameplates" and the tooltip on the disabled box (dc5ce76); a Cooldown numbers setting on Blizzard's own, and each bar's font, place and Reset for the numbers (072b9a3); a mover stops where its Blizzard frame's own clamp stops it, for chat, the tooltip and the swing timers (6f12ab9; buffs keep to the margin alone, on purpose). None has been seen in game yet. Calls left for the user there: the Copy from dialog's buttons scroll with the list rather than sitting in a fixed footer, and Confirm copy is wider than Cancel; the item level's backing slightly darkens the quality border's inner corner; whether a cooldown's number keeps its place when a cooldown starts (the client may re-place it).


### 2026-11-13 — Codebase cleanup: in-game checks

**What:** The codebase cleanup (`docs/superpowers/plans/2026-11-12-saftui-cleanup.md`, 21 tasks, merged into `modular` at 1d69905) fixed bugs, deleted dead code, merged copies of the same code and split large files, in every addon. Its tests (128 files) run on stubs, so none of it has been seen in game. Most steps below are "this still works as before". The steps marked *New* are where what the user sees was meant to change.

**Why noticed:** The user asked for every item with a clear fix in the cleanup report to be done with subagents (2026-11-12). Each task's report listed the in-game checks it needed; this entry is those lists put together. The per-task reports were in the run's workspace under `.superpowers/sdd/`, which is not versioned.

**Anchors:** `docs/reports/2026-11-12-codebase-cleanup-analysis.md` (the report), `docs/superpowers/plans/2026-11-12-saftui-cleanup.md` (the plan). The five merges on `modular`: 343aee8 (wave 1, fixes and removals), f70f24c (wave 2, shared Core helpers), 9fa3221 (wave 3, Core's Config), b829ad2 (wave 4, each addon's files), 1d69905 (wave 5, the tests). The followups [Chat's dock hook runs only on forced updates](#2026-11-13--chats-dock-hook-runs-only-on-forced-updates) (step 35) and [Bag search box is made multi-line](#2026-11-13--bag-search-box-is-made-multi-line) (step 16).

**Shape of work:** A pass by the user, a group at a time, then a small fix per step that fails. Keep BugSack on throughout: any Lua error or `ADDON_ACTION_BLOCKED` is a fail, whichever step it turns up in. Wave 5 changed tests only, so it has no steps. The steps:

*Login, both clients*
1. `/reload` with BugSack on: no Lua errors. On Forever, no "Frame not found: TransmogFrame". On retail, no error from `DoesAddOnExist`, and the transmog window still drags.
2. The skins all load: buffs and debuffs, the Cooldown Manager, the world map (drag it, resize it), the zone text with its level and faction line, the character frame's item levels and gems (and the item upgrade text on bag slots), Hekili, WeakAuras and RestedXP if installed, and `/sui` → Skinning lists them as before.
3. Forever, on a melee class: the swing timer bars are skinned, sized and movable as before.
4. The minimap's mail icon, tracking button, queue eye and clock (Blizzard's clock hidden), the reputation and renown bars, and tooltips look as before.

*Unit frames*
5. *New:* Mana as primary. Set `additionalpower.manaAsPrimary` in a unit frame profile (a profile edit; there is no `/sui` control) on a shaman, druid or priest in a form or spec that shows the Additional power bar. The Power and Additional power bars now trade places as well as sizes; before, only the sizes swapped. Say whether trading places is what's wanted.
6. `/sui` → Unitframes → Profile: New, Copy, Rename, Export, Import and Delete each work.
7. Party, Raid 10, Raid 40 and Boss: the Layout and Range settings apply, Test mode shows its previews, and the group border draws under the Blizzard theme.
8. Blizzard's raid frames stay hidden while a SaftUI raid group is on and come back when both are off. Changing that in a raid prints its note in chat ("Blizzard's raid frames will hide after you leave the raid.").
9. The Enemy and Friendly nameplate pages work, and "Use friendly nameplates' settings" and "Use enemy nameplates' settings" each still hide the rest of their page.
10. Power and Additional power with a Custom colour draw the darker background; Copy from works; the name text's placement, the health deficit text, the target's level hiding at max level, and the indicators are as before.

*Bags*
11. *New:* with the bags closed, change the bag's view in `/sui` → Bags, then open the bags: the items sit in the new view's sections. Do it once in combat too: the view applies when the fight ends.
12. *New:* within one item, the bigger stack sorts first. The count is still compared as text, so a stack of 9 sorts before a stack of 10.
13. *New:* Shift-click a currency in the bag's currency row with a chat box open: it links the currency. A plain click still opens the transfer menu where there is one.
14. The reagent bag's slots, and the item level and crafting quality overlays on slots, as before.
15. The gold footer and its tooltip, on both clients.
16. Search: typing fades the slots that don't match, and the fading is kept when the view changes. Type a few words and press Enter: say whether the box behaves as one line (see "Bag search box is made multi-line"). The view buttons and the title bar sit right under each theme and title height, and Compact holds.
17. Bank: open and close, the Deposit and Withdraw popups, the warband bank (retail), the combined bank. With the bank open, B closes both windows and ends the talk with the banker.
18. `/sui` → Bags → Categories: drag a category, and drag a rule block inside the rule editor.
19. Merge stacks, auto sell junk, and closing the bags with new items in them, on both clients.

*Fonts and outlines*
20. *New:* every outline list shows "None" where it showed a blank line: `/sui` → Fonts, the Buffs and Debuffs text, the action bars' text. Set Normal and Title to outline None: `/sui`'s own text draws with no outline.
21. Action bars: the button count and buttons per row still clamp to each other; the extra action button's size; the large cooldown numbers.

*The `/sui` window*
22. The sidebar's groups, the tabs and subtabs, the page picker; search, then click a result.
23. Switch the theme with the window open: it redraws in the new theme.
24. Resize by the grip and by the bottom edge; the height survives closing and reopening; a screen margin change applies while the window is open; the mouse wheel scrolls.
25. The Edit mode button's colour, and the unit frames' Copy from dialog.
26. Esc closes the window, a small dialog, a confirm and a dropdown, each on its own; in a text box it clears the focus first; with the colour picker open it closes only the picker. Enter confirms a dialog. Entering combat closes the window, and it refuses to open in combat.
27. Every kind of widget under Thick and under Blizzard; the Position blocks; the unit frame Profiles prompts; the rule editor's value picker.

*Blizzard's Edit Mode and SaftUI's holders*
28. Open Blizzard's Edit Mode: no selection boxes on the action bars, the pet bar, Extra Abilities, the minimap, the micro menu or the status bars. Close it and open it again: still none.
29. Buffs and debuffs stay on SaftUI's holders after Blizzard's Edit Mode opens and closes, and through a fight (no `ADDON_ACTION_BLOCKED`).
30. The swing timer bars cover their holders; chat keeps its size and spot; the tooltip grows from its holder's corner; the totem bar sits on its holder (a Forever shaman); entering a vehicle in combat raises no error.
31. `/sui edit`: drag each mover, `/reload`, and each frame is where it was left. Switch profile: the frames move to that profile's spots.

*Loot, action bars, chat*
32. Roll bars are skinned and their timer runs; after a choice the SaftUI bar holds until the roll ends; Loot → Test mode shows its previews.
33. The loot feed's lines (item, gold, currency, skill-up, reputation, experience) and a rolled item's entry.
34. `/sui kb`: hover a button and press a key to bind it, right-click clears it, Esc or combat leaves the mode. The pet and stance bars redraw. Chat's fonts. Blizzard's action bars stay hidden.
35. Chat's docked tabs, with three or more windows docked: tabs 2, 3 and 4 each sit to the right of the one before with no overlap, and tab 1 sits above its window. Check after dragging a tab off and docking it again, and after only clicking between tabs (see "Chat's dock hook runs only on forced updates").

*Misc, minimap, Core*
36. The totem bar's options apply (button size and spacing, the timers). Hide totem bar hides Blizzard's bar, and turning it off brings it back (after a `/reload` if the bar was on screen). A class with no totems: no bar, no error.
37. The experience bar's defaults (width 250) on a new profile and after Reset profile.
38. The micro menu's contents, its Blizzard theme art (the bronze strip on Forever), and `/sui` → Micro Menu → Position.
39. The Blizzard theme's art on `/sui`, the bags, the character frame and the unit frames; class power and name sizing; the loot feed's test interval.

**Resolved 2026-11-13:** the user went through the list in game and confirmed every step but the ones named here ("Every item I didn't comment on is considered confirmed working fine"). Step 5: the bars trading places is accepted. Step 16: the search box behaves fine (its code is still odd, see [Bag search box is made multi-line](#2026-11-13--bag-search-box-is-made-multi-line)). Step 35: the docked tabs sit right. Step 17, the bank, wasn't tested ("can't test right now but I'll let you know if anything is off later. Assume it's fine for now"). Step 32 failed in part: the roll bar doesn't hold after a choice, see [Loot rolls: the roll bar doesn't hold after a choice](#2026-11-13--loot-rolls-the-roll-bar-doesnt-hold-after-a-choice). Step 6 worked but the profiles were hard to find, see [Unit frame profiles are hard to find in /sui](#2026-11-13--unit-frame-profiles-are-hard-to-find-in-sui). What the pass asked for beyond that is in [In-game pass: five small changes asked for](#2026-11-13--in-game-pass-five-small-changes-asked-for) (steps 2, 9, 21, 25 and 31), [Test mode: choose which elements the previews show](#2026-11-13--test-mode-choose-which-elements-the-previews-show) (step 7) and [Colour swatches read as checkboxes, and the colour picker](#2026-11-13--colour-swatches-read-as-checkboxes-and-the-colour-picker).

### 2026-11-11 — UF:UpdateElement passes its config override into the wrong argument of UpdateElementPosition (Mana as primary)

**What:** `UF:UpdateElement` calls `self:UpdateElementPosition(element, configOverride)`, but the signature is `UF:UpdateElementPosition(element, unitframe, configOverride)`. The override lands in the `unitframe` slot, which is then overwritten, so an element is always placed by its own config. With Mana as primary, power and additional power are sized by each other's config (`UF:UpdateElementSize`) but placed by their own. Commit f0dda64 meant the override to place the element too.

**Why noticed:** The Blizzard theme round 2's Task 13 gave `UF:ElementKind` and `UF:ElementTheme` a `configOverride` so a bar's kind follows the size it is drawn at, and `UF.FillsFrame(configOverride or config)` then checks the override's position while the bar is placed by its own. That only matters if a user makes the player's power fill the unit frame and also turns Mana as primary on. Pre-existing; found in review, not caused by round 2.

**Anchors:** `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`, `UF:UpdateElementSize`, `UF:ElementKind`, `UF:ElementTheme`, `UF.FillsFrame`); commit f0dda64; `SaftUI-Unitframes/elements/name.lua` (passes the string `'Name'` as its override).

**What's been considered:** Fixing the call changes where those two bars sit (they would take the other bar's position) and would break `name.lua`, which passes a string as its override, so it needs its own look at which callers mean what. Not fixed in round 2 for that reason.

**Shape of work:** Small: audit the callers of `UpdateElementPosition` and of the override, fix the argument, and pin the result with a test in `tests/unitframes/`.

**Open questions:** Should the other bar's config place the element with Mana as primary, as f0dda64 intended, or does each bar keep its own spot?

**Update 2026-11-12:** the friendly nameplates build added a second call of the same shape, for a plate's part that's off (`UF:UpdateElement`'s off branch, `self:UpdateElementPosition(element, configOverride)`). It places by the element's own config, as the first does, and the plates pass no override. Fix both together.

**Resolved 2026-11-12:** fixed by the codebase cleanup's Task 2 (the report's bug 9). `name.lua` no longer passes a string as its override (16eb1e6), the signature is `UF:UpdateElementPosition(element, configOverride)`, and `UF:UpdateElement` hands the override over in both branches (`SaftUI-Unitframes/updaters.lua`). So with Mana as primary the Power and Additional power bars now trade places as well as sizes, as f0dda64 intended. Still owed: a look in game, and the user's word that trading places is wanted (a profile edit; the setting has no `/sui` control). It is step 5 of [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks).

### 2026-11-07 — Fonts outline dropdowns show None as a blank entry

**What:** `FN.outlines` in `SaftUI-Core/Media/fonts.lua` is the `values` table for every font outline dropdown, and its `NONE` entry is `st.retail and '' or 'NONE'`. `st.retail` is true on both clients, so the None choice shows as a blank line in `/sui` → Fonts and in the Auras text options. It looks like the `''` was meant as the font flag to pass to `SetFont` rather than the label. `FN:UpdateFontConfig` passes the saved `'NONE'` straight to `SetFont`.

**Why noticed:** Building the action bars' Text options (Task 3 of `docs/superpowers/plans/2026-11-07-saftui-action-bars.md`). `SaftUI-ActionBars/options.lua` copies the table and names None itself, and `skin.lua` maps `'NONE'` to `''` for `SetFont`, as `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua` (`OutlineFlags`) already does.

**Anchors:** `SaftUI-Core/Media/fonts.lua` (`FN.outlines`, `FN:UpdateFontConfig`); `OutlineFlags` in `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua` and `SaftUI-ActionBars/skin.lua`; `OutlineValues` in `SaftUI-ActionBars/options.lua`.

**Shape of work:** Small: label `NONE` as 'None', map `'NONE'` to `''` in `FN:UpdateFontConfig`, then drop the local copies in the action bars and auras.

**Resolved 2026-11-12:** fixed by the codebase cleanup's Tasks 1 and 8. `FN.outlines.NONE` is labelled 'None', and one shared `st.OutlineFlag(outline)` gives `SetFont` its flag (`''` for `'NONE'` or nil), both in `SaftUI-Core/Media/fonts.lua`. The fonts module, `SaftUI-ActionBars/skin.lua`, `Blizzard_BuffFramePosition.lua` and the options window's own text all use it, and the local `OutlineFlags` and `OutlineValues` copies are gone (the action bars' options take the Fonts module's `outlines`). Still owed: a look at the lists in game, step 20 of [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks).

### 2026-11-12 — Nameplates: a plate switching config can trip an anchor loop in a user's config

**What:** Since the friendly nameplates build, a plate's part that its own config turns off is still sized and placed by that config on every full update (`UF:UpdateElement`'s branch for a part that's off, `SaftUI-Unitframes/updaters.lua`: rulings C1 and C2 of that plan's Task 4), and a plate's frame gets a full update whenever its unit's kind moves it to the other config (`UF:ApplyPlateConfig`). The parts are updated in `pairs()` order, each `SetPoint` made against the others where they are then. So a user's config can trip an anchor loop: part B anchors to part A in the old config, A anchors to B in the new one, and A is off in the new one. If A is updated first, its `SetPoint` onto B (still anchored to A) forms a loop and errors. The `xpcall` in `UF:ApplyPlateConfig` reports it, and the rest of that frame's update is cut short: the parts after it keep the old config's places and look until the plate's next full update. Before the build a part that was off was never placed, so a hidden part couldn't do this. The default configs are loop-free.

**Why noticed:** The review of Task 4 of the friendly nameplates plan (2026-11-12), passed on by the controller. Task 4's report named the risk too (its concern 2: a hidden part anchored into a loop with a shown one now errors, where before it was silent).

**Anchors:** `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF:ApplyPlateConfig`), `SaftUI-Unitframes/unitframes.lua` (`UF:UpdateUnitFrame`'s element loop; `ClearUnitFramePoints` and `UF:ApplyConfig` with no unit, the same fix for frames), `tests/unitframes/friendly_plate_size_test.lua`.

**What's been considered:** Clear a plate's part anchors before placing them again on a config switch, as `ClearUnitFramePoints` clears the unit frames' before a full `UF:ApplyConfig`: a plate's parts aren't secure, so in combat too. Placing the parts in anchor order instead would need an order worked out per config. Two shown parts of any unit can loop the same way across a profile switch, since only frames are cleared first; the plates make it happen without one.

**Shape of work:** Small: clear the plate's parts' points at the start of the update `UF:ApplyPlateConfig` runs, and a test with two parts anchored each way round across the two configs, one of them off in the new one.

**Open questions:** Clear only on a config switch, or before every full update of a plate?

**Resolved 2026-11-12:** In the friendly nameplates' final fix wave (its final review's I1). `UF:ApplyPlateConfig` clears the points of everything the switch's update places before it runs (`ClearPlacedPoints` in `nameplates.lua`: every part, and the texts and icons that are on in a part that's on), so the parts can be placed in any order, in combat too. The review found the scope wider than this entry said: no part needs to be off, and an existing enemy layout against the untouched Friendly page reaches it (the name beside a raid mark the Friendly page hangs over the name), erroring on every switch one way, with the plate left half in each look. Tested in `tests/unitframes/friendly_plate_size_test.lua` ("a switch places every part afresh", both ways round, on both clients). The open question went to a switch only: a profile switch is the entry "Unit frames: a profile switch places a frame's parts against the old profile's anchors".

### 2026-11-09 — Unit frame color flags are set after oUF enables the bars, so their recolor events are never registered

**What:** oUF's Health and Power register `UNIT_FACTION` (for `colorTapping` and `colorReaction`), `UNIT_FLAGS` (`colorSelection`) and `UNIT_THREAT_LIST_UPDATE` (`colorThreat`) in their `Enable`, and only if the flag is already on then; turning a flag on later is meant to go through the element's `SetColorTapping` / `SetColorReaction` / ..., which register the event. SaftUI assigns the flags straight onto the element in each element's `UpdateConfig` (`elements/health.lua`, `elements/power.lua`). For single units (player, target, focus, ...) that first runs in `UF:ApplyConfig`, after `oUF:Spawn` has enabled the elements, so the flags were nil at `Enable` and those events are never registered, even for the defaults (Health's `colorTapping` and `colorReaction` are on). Group buttons are fine: `UF.ConstructUnit` updates them inside the style function, before `Enable`.

**Why noticed:** Task 9 of the options layout project (2026-11-09) exposed the color flags in `/sui` and checked that oUF re-reads them. It does, on every health or power update (`Path` runs `ColorPath`), and SaftUI's option set ends in `UpdateAllElements`, so each option works at once. What's missed is a recolor between updates: a target someone else tags without damaging it (no `UNIT_HEALTH`) stays its old color until its next health or power change, or until it's targeted again.

**Anchors:** `SaftUI-Unitframes/elements/health.lua` and `power.lua` (`UpdateConfig`); `SaftUI-Unitframes/Libraries/oUF/elements/health.lua` and `power.lua` (`Enable`, `SetColorTapping`, `SetColorReaction`); `SaftUI-Unitframes/Libraries/oUF/ouf.lua` (`initObject`: the style function, then `EnableElement`); `UF.ConstructUnit`, `UF:ApplyConfig` (`unitframes.lua`).

**What's been considered:** Call `element:SetColorTapping(config.colorTapping, true)` and `SetColorReaction` in `UpdateConfig` instead of assigning those two (the forced call registers or unregisters the event to match). Plain table writes stay fine in combat; registering an event on a unit frame is too. **A guard is needed (Task 9's review, 2026-11-09):** `SetColorTapping` and `SetColorReaction` only exist after oUF's `Enable`, and group buttons run `UpdateConfig` inside the style function, before `Enable`, so calling them unguarded errors on party and raid frames. Check for a nil `element.SetColorTapping`: when it's nil, assign the flag directly (as now), and `Enable` registers the event itself.

**Shape of work:** A few lines in health.lua and power.lua, and an in-game check: tag a target with a debuff from another player and watch it go grey.

**Resolved 2026-11-11:** Health and power set the two flags through oUF's setters once the bar has them (`UF.SetFactionColorFlags`), and group buttons now get their first update from oUF's init callback (`UF.InitUnit`), after oUF's Enable; tested in `tests/unitframes/unit_init_test.lua`, the in-game check above still to do.

### 2026-11-11 — Blizzard theme: the bag slot bars sit over the metal's title bar

**What:** Under the Blizzard theme the bag window's bag slot bar (Bag Slots: `INV.containers.bag.bagSlotContainer`, `SaftUI-Bags/containers/bag.lua`) and the bank's (`SaftUI-Bags/containers/bank.lua`) are anchored by their BOTTOMLEFT to the window's TOPLEFT, `buttonspacing` up. The metal's title bar reaches 20 (retail 21) above the window and its top corners 16 more, so a shown bar lies over the title bar, which now holds the window's title, view buttons and Bag Slots itself. The bar is a child of the window, one level over it and one under the header, so where it overlaps the title bar it hides the metal there, and the title and the header's buttons draw over it.

**Why noticed:** Moving the window headers into the metal's title bar (2026-11-11, the user's in-game feedback on the Blizzard theme: "Can we put these header items on the actual title bar on the blizzard theme?"). Before that the title bar was empty but for the close button, and the bar already covered it; it wasn't in scope to move the bars.

**Anchors:** `SaftUI-Bags/containers/bag.lua` (`bagSlotContainer:SetPoint('BOTTOMLEFT', self.containers.bag, 'TOPLEFT', 0, self.config.buttonspacing)`), `SaftUI-Bags/containers/bank.lua` (the same for the bank's bar), `INV:UpdateBagSlotBars` (`SaftUI-Bags/inventory.lua`); `st:DrawnFrame(window)` (the window's backdrop, whose top is the metal's), `st.ThemeArt.ART.metal` (the top corners' y, 16).

**What's been considered:** Anchor each bar to the window's drawn frame (`st:DrawnFrame`) under Blizzard, above the metal's top corners (16 over its top), and to the window under Thick and Thin, re-anchored where the bags already follow a theme switch (`INV:UpdateConfig(id)`). Whether 16 is where the metal's art visibly ends needs a look in game.

**Shape of work:** Small: one anchor per bar and its re-anchoring on a theme switch, a test in `tests/bags/theme_test.lua`, and an in-game look on both clients.

**Resolved 2026-11-11:** In the title bar work's first review fix round. Each bar is placed by `INV:PlaceBagSlotBar` (`SaftUI-Bags/inventory.lua`), when made (`containers/bag.lua`, `containers/bank.lua`) and on every `INV:UpdateBagSlotBars`: its bottom left on the window's header's top left, `buttonspacing` up, plus `st:ArtAboveHeader` (`SaftUI-Core/panels.lua`), how far the metal reaches above the header: `st.ThemeArt.MetalAbove()` (16, the top corners' y) over the drawn frame, whose top is the title bar's. Under Thick and Thin the header's top is the window's and the extra is 0, so nothing moved; under Blizzard the bar sits 3 over the metal's top whether the header is in the title bar or, under the bags' own Blizzard and SaftUI's Thick, in the window. `UpdateBagSlotBars` runs only out of combat (`INV:UpdateConfig` waits for it), and the header the bar hangs from waits for the end of combat to move. Tested on both clients in `tests/bags/theme_test.lua`. Whether 16 leaves too wide a gap over the metal's visible rim is an in-game check ("Blizzard theme: in-game checks").

### 2026-11-11 — Blizzard theme: test gaps left after the final review

**What:** Two gaps in the Blizzard theme's tests, left by the whole-branch review's fix wave (2026-11-11). No bags test draws a bag window for the first time under Blizzard: every case in `tests/bags/theme_test.lua` that builds a window builds it under Thick and then switches (the bank's bag-slot buttons are the only part drawn first under Blizzard). And one test checks the bags' Edit toggle by reading a line of source rather than by what it does.

**Why noticed:** The final review of branch `blizzardtheme` (`4254164..023b2b8`) listed both as test gaps; the fix wave left them here rather than widen its scope. A window first drawn under Blizzard takes a different path from one switched to it (the first draw of the metal, the close button's socket and the slots' rings, rather than a redraw of each), and it's how a user who picked Blizzard sees the bags after every `/reload`.

**Anchors:** `tests/bags/theme_test.lua`: its `fresh()` and `bags()` helpers, which start under Thick, and the case "the Edit toggle is a panel button, pressed while checked" (Task 8), which asserts `container.lua` contains the exact line `local filterButton = st:CreateCheckButton(nil, container.header, 'button')` and then builds its own check button the same way; `SaftUI-Bags/container.lua` (`INV:CreateContainer`, the Edit toggle, `container.header.filterButton`); `tests/bags/container_helpers.lua` (`H.window`, which builds a window as `INV:CreateContainer` does, as far as the layout reads it).

**What's been considered:** The Edit toggle test reads source because `INV:CreateContainer` needs Blizzard templates the stubs lack (`UICheckButtonTemplate` among them), and the bags' tests build their windows by hand (`bags()` here, `H.window` in the views world) rather than through it. As it stands, rewording the line (or renaming the local) fails the test with no change in behaviour, and the button it checks is one it made, not the window's. To make it behavioural, either run `INV:CreateContainer` in a world with stand-ins for its templates (the views world already stands in for `UICheckButtonTemplate` and the slot templates), or move the toggle's making out of `INV:CreateContainer` into a function the test can call on its window. Then check the window's own toggle (`container.header.filterButton`): styled `'button'`, Blizzard's panel button under Blizzard, pressed while checked.

**Shape of work:** Small, tests only. A case that sets SaftUI's theme to Blizzard before the bag window is built, then checks the metal, the close button in its socket, the view buttons from the header's right edge, the slots' rings and the window's fill, as the Thick, Blizzard, Thick case does after its switch. And the Edit toggle case rewritten to take the real window's toggle.

**Resolved 2026-11-11:** Both, with the Blizzard theme's title bar work (window headers in the metal's title bar). `tests/bags/theme_test.lua`'s `bags()` takes a theme and a client, and "a bag window first drawn under Blizzard" builds the window under Blizzard on both clients and checks the metal, its fill, the close button in its socket, the header and its buttons in the title bar, the slots' rings and the art behind them, and an Epic item's white icon border, then a switch to Thick. The Edit toggle is made by `INV:CreateEditToggle(container)` (`SaftUI-Bags/container.lua`), which `INV:CreateContainer` calls, and the test takes the window's own toggle from it (with `UICheckButtonTemplate` stood in), no source read.

### 2026-11-11 — Blizzard theme: dark grey everywhere

**What:** Under the Blizzard theme SaftUI's windows take Blizzard's dark grey (`templates.blizzard.windowcolor`, `{ 0.12, 0.12, 0.13, 1 }`) and everything else (panels, bars, tooltips, small frames) its navy (`templates.blizzard.backdropcolor`, `{ 0.09, 0.09, 0.19, 1 }`). The user may later want dark grey everywhere.

**Why noticed:** The user, choosing the Blizzard theme's backgrounds in the brainstorm (2026-11-10): "Lets go with alternative, potentially we'll end up with dark grey everywhere." The spec records it as ruling 2 of "The user's answers".

**Anchors:** `SaftUI-Core/Config/defaults.lua` (`st.defaults.templates.blizzard`); `SaftUI-Core/themeart.lua` (`KINDS`, each kind's `fill`: `windowcolor` or `backdropcolor`); `SaftUI-Core/Media/theme.lua` (the Theme tab's Window background and Background rows); the spec's "The user's answers".

**What's been considered:** It's one default to change: `templates.blizzard.backdropcolor`. A profile that never set it follows the new default, since AceDB only saves a value that differs from the default; a profile that picked its own Background color keeps it, and Reset on the Theme tab puts the defaults back. Nothing else hard-codes either color, by design.

**Shape of work:** One value in `defaults.lua`, plus the tests that name the default (`tests/core/theme_blizzard_test.lua`). If windows and the rest should then be one color, the Window background row and `windowcolor` could go, or stay as an override.

**Open questions:** Whether to change the default, and whether to keep the Window background row once the two match.

**Resolved 2026-11-11:** The user, after checking the theme in game: "The navy background is pretty ugly, lets go with dark gray everywhere." `templates.blizzard.backdropcolor` now defaults to the window's dark grey, `{ 0.12, 0.12, 0.13, 1 }`. Both settings stay (Window background and Background on the Theme tab), each still coloring its own frames, so the user can set them apart again; the tests that named the navy now check the grey default and the two set apart.

### 2026-11-10 — Two ways to reset a border to the theme's (bag slots and action buttons)

**What:** When a module takes its own color off a border (an item's quality off an emptied bag slot, the green off an action button that no longer holds an equipped item), it puts the theme's border back in one of two ways:
- Bags set it by hand. `INV:SetSlotThemeBorder` (`SaftUI-Bags/slot.lua:~68-76`) resolves the Slot theme and calls `SetBackdropBorderColor(unpack(look.colors.bordercolor))`, or a clear border for None.
- Action bars draw the button again: `st:SetTemplate(backdrop, skin.theme, skin.background, 'action')` (`SaftUI-ActionBars/skin.lua:~387`, in `AB:UpdateEquippedBorder`).

Both give the same border today, since under Thick and Thin a border is just `bordercolor`. Once the Blizzard theme (project 2) draws each kind its own way, the by-hand path will show the wrong border. Unify them before project 2.

**Why noticed:** The Themes project's review of Task 5 (Bags, 2026-11-10), deferred as minor, and the final review, which asked for this entry.

**Anchors:** `SaftUI-Bags/slot.lua` (`INV:SetSlotThemeBorder`, `INV:SetSlotQualityBorder`, `INV:AssignEmptySlot`); `SaftUI-ActionBars/skin.lua` (`AB:UpdateEquippedBorder`, `ColorEquipped`, `AB:OnColorsChanged`); `SaftUI-Core/theme.lua` (`Color`, `Paint`, the drawn-frame record); `docs/superpowers/specs/2026-11-10-saftui-themes-design.md` (project 2).

**What's been considered:**
- An engine call that puts a recorded frame's theme colors back, moving nothing (for example `st:ResetThemeColors(frame)`, running `Color` with the frame's recorded arguments), used by both modules. That suits a slot whose quality just went.
- Or Bags redraw with `st:SetTemplate` as the action bars do, which costs a full draw per slot on bag updates.

**Shape of work:** Small: one engine call and two call sites, with the Review Focus 2 and equipped-border tests as the guard (`tests/bags/theme_test.lua`, `tests/actionbars/theme_test.lua`).

**Open questions:** Should the engine call put back only the border, or the fill and alpha too?

**Resolved 2026-11-11:** `st:SetBorderColor(frame, r, g, b, a)` (`SaftUI-Core/theme.lua`) is the one call a module colors a drawn frame's border with, and with no color it puts the look's own border back. Under Thick and Thin it is the backdrop's border (the theme's `bordercolor` with no color); under Blizzard it is the look's own (`st.ThemeArt.SetBorder`): the tooltip and metal pieces tinted, the action button's equipped border or the slot's and aura's white icon border shown in the color, a small frame's line, and nothing for a control. It puts the border back without a draw, so the action bars no longer redraw with `st:SetTemplate` and the bags no longer resolve the Slot theme by hand (`INV:SetSlotThemeBorder` is `st:SetBorderColor(slot.backdrop)`). Every module call that colored a drawn backdrop's border moved to it, and `tests/core/theme_kinds_test.lua` scans every loaded file so a new `:SetBackdropBorderColor(` on a drawn backdrop fails. The open question was answered: it puts back only the border, since a recolor or redraw already puts the fill back.

### 2026-11-10 — Bag categories: make the category rules configurable in /sui

**What:** The bag categories (which items go where, and in what order) are hard-coded Lua. The user wants them exposed in `/sui`, so categories can be added, removed, reordered and given their own rules there.

**Why noticed:** The user, 2026-11-10, while asking for new bag views: "I'd like to expose the category configurations in the config, we have a lot of complexity to the filters right now and it's hard coded, we should do some analysis on the different mechanisms for sorting and build a UI that allows this customization to extend to the config. This will need some research and design passes and should be worked separately from the other views."

For prior art they shared Ellesmere's bag window. Its left sidebar lists the categories, some nested (The Armory → Weapons / Trinkets and Armor; Adventure Prep → Consumables and Camp Items), with counts and an "Add Category" entry. They noted that sidebar "takes up quite a bit of room with all of the text".

**Anchors:**
- **The category rules:** `SaftUI-Bags/filters.lua`. `INV:AddFilter(name, func, options)` builds `INV.filters.categories` in order, and the first matching filter wins. The filters include Grays/Auto Vendor (`autoVendor`, with protection and legacy-gear rules), class-tier token groups matched on tooltip text, Secrets of Azeroth, and `customItemLists`.
- **How an item gets its category:** `SaftUI-Bags/category.lua`, `INV:GetItemCategory`. Retail equipment-set items go to `Set: <name>`, reagent bag items go by subclass, then the filters run in order, and anything left falls back to Miscellaneous. Also `INV:GetSortedInventory`, and `sortCategory` (by `sortString`).
- **Per-container toggles:** `filters.categories[id]` (`SaftUI-Bags/inventory.lua` ~line 96).
- **Auto vendor:** `SaftUI-Bags/autovendor.lua` and `INV.AUTO_VENDOR_CATEGORIES`.
- **Related:** the bag views (One bag, Multi bag, Compact, Rows) have shipped (`docs/superpowers/specs/2026-11-10-saftui-bag-views-design.md`). Every view orders its categories through the shared `INV:CategoryRank` and `INV:CategoryBefore` in `SaftUI-Bags/views.lua` (the filters' order, Miscellaneous and Empty Slots last, sets first), which this project will make configurable: a user-defined order should replace what `CategoryRank` reads. `tests/bags/views_data_test.lua` covers that order.

**What's been considered:** Nothing yet. The user asked for an analysis of the current mechanisms (first-match filter order, tooltip-text matching, item lists, equipment sets, reagent subclasses, auto vendor, the sort keys) before any UI design.

**Shape of work:** A research pass that maps every mechanism and what a configurable form of each would need. Then a design pass for the `/sui` UI (and maybe an in-bag sidebar or editor). Then a spec and a plan. Probably more than one project: a data model and migration for saved categories, then the UI.

**Open questions:**
- Which mechanisms stay code-only (e.g. tooltip scanning)?
- Do nested categories (Ellesmere-style groups) come in?
- How do user categories interact with SaftUI's built-in ones and their order?
- Where does the UI live: `/sui`, the bag window, or both?

**Resolved 2026-11-11:** The category rules are data in the profile, edited in `/sui` -> Bags -> Categories (add, rename, reorder, turn off, delete, restore, reset, block rules, pins), with today's filters as the defaults and old profiles migrated. Spec `docs/superpowers/specs/2026-11-10-saftui-bag-categories-design.md`, plan `docs/superpowers/plans/2026-11-10-saftui-bag-categories.md`, branch `bagcategories`. The in-game checks are in the followup "Bag categories: in-game checks".

### 2026-11-10 — Zone text replaces Blizzard's OnEvent script with AceHook's HookScript

**What:** `ZT:OnEnable` (`SaftUI-Misc/Skinning/ZoneText.lua:63`) hooks `ZoneTextFrame`'s `OnEvent` with AceHook's `ZT:HookScript(ZoneTextFrame, 'OnEvent')`. AceHook's `HookScript` installs its closure with `SetScript`, replacing Blizzard's handler on a Blizzard frame, which `.agents/taint.md` rule 2 forbids. Use the native post-hook, `ZoneTextFrame:HookScript('OnEvent', function(frame, event, ...) ZT:OnEvent(frame, event, ...) end)`, or AceHook's `SecureHookScript`.

**Why noticed:** The Themes project's reviews (2026-11-10). Task 6 moved the zone text's flourish lines off `ZoneTextFrame` into `ZT.flourishes` and gave them a Theme; its review, reading the same file, found the hook and deferred it to a followup. It predates Themes.

**Anchors:** `SaftUI-Misc/Skinning/ZoneText.lua` (`ZT:OnEnable`, `ZT:OnEvent`, `ZT:ColorFlourishes`, `ZT:OnColorsChanged`); `.agents/taint.md` rules 2 and 9. The same `OnEnable` also registers `PLAYER_ENTERING_WORLD` on `ZoneTextFrame`, calls its `SetPoint`, and assigns `ZoneFadeInDuration`, `ZoneHoldDuration` and `ZoneFadeOutDuration`, which look like Blizzard's own globals (rule 9). That's not yet checked against Blizzard's source.

**Shape of work:** A one-line hook change, and a look at the other writes in the same function. Then an in-game check that the flourishes still take the zone name's color and the difficulty text still updates on entering a zone.

**Resolved 2026-11-10:** `ZT:OnEnable` hooks `ZoneTextFrame`'s `OnEvent` with the native `ZoneTextFrame:HookScript`, so Blizzard's `ZoneText_OnEvent` stays the frame's script and runs first, untainted. Checked against Blizzard's `Blizzard_FrameXML/Mainline/ZoneText.lua` (forever and live are the same):
- `ZoneFadeInDuration`, `ZoneHoldDuration` and `ZoneFadeOutDuration` are Blizzard's globals, read only in the two frames' OnLoad, before SaftUI loads. SaftUI's assignments changed nothing but broke rule 9, so they're gone, and SaftUI passes its own times to the FadingFrame setters. Those setters still write the frames' fade fields from SaftUI's code: that's [its own followup](#2026-11-10--zone-texts-fade-times-are-written-onto-blizzards-frames), since dropping them shortens the zone text.
- `ZoneTextFrame:RegisterEvent('PLAYER_ENTERING_WORLD')` and `ZoneTextFrame:SetPoint` are widget calls that write no Lua: the game still runs Blizzard's handler itself on the event, and the frame is a plain one (no Edit Mode system) that Blizzard places only in its XML. Neither breaks a rule; both stay.
- AceHook's hook had run SaftUI's handler before Blizzard's. Two things relied on that: the difficulty line compared `GetZoneText()` with the frame's `zoneText` before Blizzard updated it, and now shows while the zone name is up; and the flourishes took the zone name's color before Blizzard set it (the previous zone's), and now take the new zone's.

Done with the zone level and faction line, in `SaftUI-Misc/Skinning/ZoneText.lua`. `tests/misc/zone_text_test.lua` locks Blizzard's zone text frames (a `SetScript` or a new field fails) and checks the globals keep Blizzard's values. The in-game checks are under "[Zone level and faction line: in-game checks](#2026-11-10--zone-level-and-faction-line-in-game-checks)".

### 2026-11-10 — Loot rolls stay shown, locked, after you choose (approved, queued after Themes)

**What:** After you choose on a loot roll, the roll stays on screen until the roll ends, showing everything it showed before plus your choice. The buttons are locked.

**Why noticed:** The user, 2026-11-10: "can we make the loot roll frame not disappear once I've made a selection for a loot roll? just signal that the buttons are locked in but still show them so I can see who has rolled on what so far". Asked what they'd want to see: "all the info I can see prior to rolling plus some signal of what selection I made on the roll". They approved the description below ("that's all good"), seeing a mockup (`.superpowers/brainstorm/…/roll-locked.html`).

**Approved description (a small change, in chat):**
- **What stays:** everything the bar shows before you choose:
  - the item icon and name (with BoE and count);
  - the timer bar and countdown;
  - the four roll buttons with their live counts (`SaftUI-Loot/rollinfo.lua`);
  - the hover tooltip listing everyone's choices so far (`LT:AddRollLines`).
- **Your choice:** your button stays bright with a lit border (Buttons → Blue) and the other three dim, and a small label in the bar names your choice. No button can be clicked.
- **When it goes:** when the roll ends: its timer runs out, or the game awards the item (the loot feed already shows the result).
- **Where it sits:** in the same place in the roll stack. New rolls stack as now.
- **How it's built:**
  - Blizzard removes its own frame when you choose (`CANCEL_LOOT_ROLL` → `GroupLootFrame_Remove`), and preventing that would mean replacing Blizzard code (`.agents/taint.md`, rule 2).
  - So SaftUI shows its own copy of the bar in that spot, built like Test mode's bars (`CreatePreviewBar`, `SaftUI-Loot/roll.lua`) and fed by the same live roll data. Nothing of Blizzard's is changed.
- **When the game can't match the roll:** a roll with no matched loot-history drop still shows the item, timer and choice, without counts. Whether trash rolls appear in `C_LootHistory` on Forever is unknown; see the trash-rolls item in this file.
- **Test mode** shows a locked bar too.

**Anchors:** `SaftUI-Loot/roll.lua` (`LT:LayoutRollFrames`, `LT:GroupLootFrame_OnShow`, the preview bars), `SaftUI-Loot/rollinfo.lua` (`bars`, `UpdateRollBars`, `OnBarHide`, the drop matching and `StillYours`), `SaftUI-Loot/Feed/rolls.lua` (`LT:GetOpenDrops`).

**Shape of work:** Small to medium, one implementation task with tests:
- on the player's choice (the Blizzard bar hiding while its matched drop is still open), show a SaftUI held bar in its slot carrying the drop;
- update its counts on loot-history updates;
- remove it when the drop resolves or its timer ends;
- lay held bars out with the live ones;
- give Test mode a locked bar.

Build it after the Themes branch merges, since Themes also edits `roll.lua`, drawing the held bar the Themes way (with a kind).

**Resolved 2026-11-10:** built as approved. `SaftUI-Loot/rollinfo.lua` notes your choice and its time left from a post-hook on `RollOnLoot`; when Blizzard's bar hides itself with a choice noted, `LT:HoldRoll` (`roll.lua`) shows a held bar in its place in the stack, carrying the roll's drop. `LT:UpdateRollBars` matches and updates held rolls with the live bars (a held roll takes only a drop you've chosen on, a live bar keeps its drop through a Need's dice animation) and releases one whose drop resolved; `LT:UpdateHeldRolls` releases one whose time ran out. Held bars and Test mode's previews share one builder (`CreateBar`, `ApplyBarConfig`), drawing Blizzard's roll button art, with only your choice's button bordered; the second preview (Drakefire Amulet) is locked on Greed. A new roll goes after every bar already up, so a roll starting never moves one. `CANCEL_ALL_LOOT_ROLLS` ends every held roll, and a roll with under a second left isn't held. Without a loot history drop, a held roll goes when its time runs out. The label sits before the timer rather than under the name as in the mockup. `tests/loot/roll_held_test.lua`. In-game checks are under "Loot rolls: confirm the client assumptions in game".

### 2026-11-09 — st:SetBackdropIn duplicates st:SetBackdrop

**What:** `st:SetBackdropIn` (`SaftUI-Core/api.lua`, added by the tooltip side-table fix) copies the body of `st:SetBackdrop` (`SaftUI-Core/panels.lua`), but returns the backdrop frame without storing it on its target. If `SetBackdrop`'s offset or frame-level rules change, the two will drift.

**Why noticed:** The review of the tooltip fix (2026-11-09). That fix wasn't allowed to touch `panels.lua` while the options window work was changing it.

**Anchors:** `SaftUI-Core/api.lua` (`SetBackdropIn`), `SaftUI-Core/panels.lua` (`SetBackdrop`).

**Shape of work:** Small, once the options window branch has landed: make `SetBackdrop` call `SetBackdropIn` and then store the result, or share one inner function.

**Resolved 2026-11-10:** the Themes project (Task 1) moved both into `SaftUI-Core/theme.lua`, where `st:SetBackdrop` and `st:SetBackdropIn` draw through one shared `DrawBackdrop`; they differ only in where the backdrop frame is kept (`frame.backdrop`, or the caller's table).

### 2026-11-08 — TemplateInset is duplicated between SaftUI-ActionBars and SaftUI-Misc

**What:** The helper that works out how far a template's border insets the icon exists in `SaftUI-ActionBars/skin.lua` and again as `TB.TemplateInset` in `SaftUI-Misc/totemskin.lua`, which `totemtimers.lua` shares. If one copy changes, the totem bar and the action bars drift apart.

**Why noticed:** The totem bar plan's Task 1 review (2026-11-08) parked it. SaftUI-Misc must not depend on SaftUI-ActionBars, so it couldn't call the ActionBars copy.

**Anchors:** `SaftUI-ActionBars/skin.lua` (`TemplateInset`), `SaftUI-Misc/totemskin.lua` (`TB.TemplateInset`).

**Shape of work:** Small: move it into SaftUI-Core (next to `st:CalculateSpacing` / the template helpers) as `st:TemplateInset(template)` and use it from both.

**Resolved 2026-11-10:** the Themes project (Tasks 5 and 6) replaced both copies with Core's `st:ThemeInset(theme, background)` (`SaftUI-Core/theme.lua`), which the action bars, the totem bar and its timers, the minimap, the micro menu, the loot feed and the buff skin read.

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

### 2026-11-11 — Nameplates: a plate handed to the other kind scans its auras twice

**What:** When the game hands a plate from a friend to an enemy (or back), `UF:ApplyPlateKind` turns the plate's two aura areas on (or off) in the added callback, and Blizzard's container scans the auras at once on that change, for the unit token it still has from the plate's last unit. oUF's update right after then sets the new unit and scans again. An add of the same kind as the plate's last makes no extra scan: Blizzard's container ignores a `SetEnabled` that changes nothing.

**Why noticed:** The final review of the nameplates build (its M4) took every add to scan twice; the final fix wave found Blizzard's guard (`AuraContainerSharedMixin:SetEnabled`, `Blizzard_AuraContainer.lua`, both clients), so only a kind change does.

**Anchors:** `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF:ApplyPlateKind`), `SaftUI-Unitframes/Libraries/oUF/elements/auras.lua` (`Update`: `SetUnit`, else `ForceUpdate`), `tests/unitframes/nameplate_kind_test.lua` (the scan-count case), `tests/unitframes/fixtures/ouf.lua` (the container's `__scans`).

**What's been considered:** Setting the container's unit before turning it on doesn't help, since oUF's update then forces a scan anyway. Turning the areas on after oUF's update (from the aura element's `PostUpdate`) would save the first scan, at the cost of a less obvious kind pass. A kind change is much rarer than an add, so the cost is small.

**Shape of work:** Small, only if a profile shows it: move the aura areas' turn-on after oUF's update, with the scan-count test changed to one per area.

**Abandoned 2026-11-11:** There is no second scan to save. oUF's container is Blizzard's managed one, whose full update only marks it dirty (`ManagedAuraContainerSharedMixin:UpdateAllAuras`, `Blizzard_ManagedAuraContainer.lua`, both clients), and the parse runs once on its next frame, so the kind pass's `SetEnabled` and oUF's `SetUnit` in one tick fold into one (the final fix wave's re-review).
