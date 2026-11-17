# Followups

A queue between "noticed it" and "decided what to do about it." Items might become Jira tickets, get fixed inline during related work, or be explicitly abandoned. Triage periodically.

Format: see the user-level `~/.claude/CLAUDE.md` "Followup detection" section.

## Contents

- [Active](#active)
  - [2026-11-17 — Micro buttons' hover: one alpha a texture or two](#2026-11-17--micro-buttons-hover-one-alpha-a-texture-or-two)
  - [2026-11-17 — Scroll bar thumbs: the same solid hover reads soft on chat and opaque on the tracker](#2026-11-17--scroll-bar-thumbs-the-same-solid-hover-reads-soft-on-chat-and-opaque-on-the-tracker)
  - [2026-11-16 — The loot window's opaque hover on the first open: nothing found that writes it](#2026-11-16--the-loot-windows-opaque-hover-on-the-first-open-nothing-found-that-writes-it)
  - [2026-11-16 — The /sui slider's knob shows no hover or held state in the game: cause not found](#2026-11-16--the-sui-sliders-knob-shows-no-hover-or-held-state-in-the-game-cause-not-found)
  - [2026-11-16 — Redesign the loot window](#2026-11-16--redesign-the-loot-window)
  - [2026-11-16 — The tracker's wrapped text, one line short: the cause is inferred, not seen in the game](#2026-11-16--the-trackers-wrapped-text-one-line-short-the-cause-is-inferred-not-seen-in-the-game)
  - [2026-11-16 — Unit frames shared settings: dead code, stale comments, names with two meanings, and shared.lua at 1293 lines](#2026-11-16--unit-frames-shared-settings-dead-code-stale-comments-names-with-two-meanings-and-sharedlua-at-1293-lines)
  - [2026-11-16 — Search stops at 100 results, so a part's name cuts the last pages](#2026-11-16--search-stops-at-100-results-so-a-parts-name-cuts-the-last-pages)
  - [2026-11-16 — All units: small rules left open](#2026-11-16--all-units-small-rules-left-open)
  - [2026-11-16 — Nameplates and All units](#2026-11-16--nameplates-and-all-units)
  - [2026-11-16 — The states scan misses hand-rolled states it should catch](#2026-11-16--the-states-scan-misses-hand-rolled-states-it-should-catch)
  - [2026-11-16 — A Buttons color saved by an older build after a downgrade stays as an orphan key](#2026-11-16--a-buttons-color-saved-by-an-older-build-after-a-downgrade-stays-as-an-orphan-key)
  - [2026-11-16 — The tracker's whole pixels at other scales](#2026-11-16--the-trackers-whole-pixels-at-other-scales)
  - [2026-11-16 — `optionsOf` keeps every page root alive: the reset walk's options table holds its own key](#2026-11-16--optionsof-keeps-every-page-root-alive-the-reset-walks-options-table-holds-its-own-key)
  - [2026-11-16 — The full-UI Accent pass is about 2,500 setters, and the bag slots are 1,400 of them](#2026-11-16--the-full-ui-accent-pass-is-about-2500-setters-and-the-bag-slots-are-1400-of-them)
  - [2026-11-16 — The Hue shift setting reads "20", not "20 degrees"](#2026-11-16--the-hue-shift-setting-reads-20-not-20-degrees)
  - [2026-11-16 — The keybind field's "Press a key" in the Accent on the selected look is 2.9 to 4.3:1](#2026-11-16--the-keybind-fields-press-a-key-in-the-accent-on-the-selected-look-is-29-to-431)
  - [2026-11-16 — With the History list open, a Theme recolor restyles its twelve rows](#2026-11-16--with-the-history-list-open-a-theme-recolor-restyles-its-twelve-rows)
  - [2026-11-16 — The `/sui` color picker is laid out in units, not whole pixels, at 0.75 and 1.25](#2026-11-16--the-sui-color-picker-is-laid-out-in-units-not-whole-pixels-at-075-and-125)
  - [2026-11-15 — Auto Vendor: stop the unasked sales once the player buys or buys back](#2026-11-15--auto-vendor-stop-the-unasked-sales-once-the-player-buys-or-buys-back)
  - [2026-11-15 — UI scale phase 2: the options kit and SaftUI's windows](#2026-11-15--ui-scale-phase-2-the-options-kit-and-saftuis-windows)
  - [2026-11-15 — UI scale phase 3: edit mode](#2026-11-15--ui-scale-phase-3-edit-mode)
  - [2026-11-15 — UI scale phase 4: each addon, 4a to 4g](#2026-11-15--ui-scale-phase-4-each-addon-4a-to-4g)
  - [2026-11-15 — UI scale phase 5: crispness on dense screens](#2026-11-15--ui-scale-phase-5-crispness-on-dense-screens)
  - [2026-11-15 — UI scale: the docked edit mode bar is off whole pixels away from k = 1](#2026-11-15--ui-scale-the-docked-edit-mode-bar-is-off-whole-pixels-away-from-k--1)
  - [2026-11-15 — UI scale: a nameplate's inner parts are not yet even in pixels](#2026-11-15--ui-scale-a-nameplates-inner-parts-are-not-yet-even-in-pixels)
  - [2026-11-15 — UI scale: EvenIfCentred and st:EvenPixels disagree for negative counts](#2026-11-15--ui-scale-evenifcentred-and-stevenpixels-disagree-for-negative-counts)
  - [2026-11-15 — UI scale: the Blizzard theme's art is not on whole pixels in a scaled frame](#2026-11-15--ui-scale-the-blizzard-themes-art-is-not-on-whole-pixels-in-a-scaled-frame)
  - [2026-11-15 — UI scale: E4, SetScale in combat, still to run](#2026-11-15--ui-scale-e4-setscale-in-combat-still-to-run)
  - [2026-11-15 — UI scale: E0, the friends' check of the default UI size and its range](#2026-11-15--ui-scale-e0-the-friends-check-of-the-default-ui-size-and-its-range)
  - [2026-11-15 — UI scale: E6 and deleting the font demo](#2026-11-15--ui-scale-e6-and-deleting-the-font-demo)
  - [2026-11-15 — UI scale: E1 on the friends' screens](#2026-11-15--ui-scale-e1-on-the-friends-screens)
  - [2026-11-15 — UI scale: the owner's standing calls](#2026-11-15--ui-scale-the-owners-standing-calls)
  - [2026-11-15 — UI scale: the Keep prompt's line weight at 150% and the Esc order](#2026-11-15--ui-scale-the-keep-prompts-line-weight-at-150-and-the-esc-order)
  - [2026-11-15 — The options kit's keybinding widget commits mouse buttons 6 to 31 raw](#2026-11-15--the-options-kits-keybinding-widget-commits-mouse-buttons-6-to-31-raw)
  - [2026-11-13 — Loot rolls: the roll bar doesn't hold after a choice](#2026-11-13--loot-rolls-the-roll-bar-doesnt-hold-after-a-choice)
  - [2026-11-15 — UI scale: the kit's buttons and labels are off whole pixels on every screen that is not 1440p](#2026-11-15--ui-scale-the-kits-buttons-and-labels-are-off-whole-pixels-on-every-screen-that-is-not-1440p)
  - [2026-11-15 — UI scale: a kit confirm dialog or an open select list can cover the Keep prompt](#2026-11-15--ui-scale-a-kit-confirm-dialog-or-an-open-select-list-can-cover-the-keep-prompt)
  - [2026-11-15 — An addon's direct RollOnLoot on a roll with no confirmation is not held](#2026-11-15--an-addons-direct-rollonloot-on-a-roll-with-no-confirmation-is-not-held)
  - [2026-11-15 — The color picker's preview copies other widgets' geometry](#2026-11-15--the-color-pickers-preview-copies-other-widgets-geometry)
  - [2026-11-15 — UI scale: a frame drawn parentless and parented later into a frame with a scale of its own keeps UIParent's line](#2026-11-15--ui-scale-a-frame-drawn-parentless-and-parented-later-into-a-frame-with-a-scale-of-its-own-keeps-uiparents-line)
  - [2026-11-15 — UI scale: the bags' loading overlay holds st.BACKDROP and needs SetBackdrop(nil) to take a new line](#2026-11-15--ui-scale-the-bags-loading-overlay-holds-stbackdrop-and-needs-setbackdropnil-to-take-a-new-line)
  - [2026-11-15 — `/sui` following during a color drag](#2026-11-15--sui-following-during-a-color-drag)
  - [2026-11-15 — The Theme tab's color drag recolors every drawn frame](#2026-11-15--the-theme-tabs-color-drag-recolors-every-drawn-frame)
  - [2026-11-15 — Edit mode: a Theme pass with edit mode on still does the full look and list refresh](#2026-11-15--edit-mode-a-theme-pass-with-edit-mode-on-still-does-the-full-look-and-list-refresh)
  - [2026-11-15 — Unit frames: a Warrior class pick updates every Warrior NPC plate](#2026-11-15--unit-frames-a-warrior-class-pick-updates-every-warrior-npc-plate)
  - [2026-11-15 — Unit frames: what a color pass's real element updates cost](#2026-11-15--unit-frames-what-a-color-passs-real-element-updates-cost)
  - [2026-11-15 — A Position reset runs a unit frame's update once for every part it writes](#2026-11-15--a-position-reset-runs-a-unit-frames-update-once-for-every-part-it-writes)
  - [2026-11-15 — After a UI scale change, a reset half-pixel Position can show its icon again](#2026-11-15--after-a-ui-scale-change-a-reset-half-pixel-position-can-show-its-icon-again)
  - [2026-11-15 — Shipped category names shown numbered: no test pins that they show no reset icon](#2026-11-15--shipped-category-names-shown-numbered-no-test-pins-that-they-show-no-reset-icon)
  - [2026-11-15 — Reset walk: the profile compare is most of a unit page's cost](#2026-11-15--reset-walk-the-profile-compare-is-most-of-a-unit-pages-cost)
  - [2026-11-15 — Nameplates: Blizzard's friendly plates key binding and the next login](#2026-11-15--nameplates-blizzards-friendly-plates-key-binding-and-the-next-login)
  - [2026-11-15 — Bag search box: the magnifier and the clear button](#2026-11-15--bag-search-box-the-magnifier-and-the-clear-button)
  - [2026-11-15 — Tracker: an Edit Mode anchor to a frame other than UIParent gives the default spot](#2026-11-15--tracker-an-edit-mode-anchor-to-a-frame-other-than-uiparent-gives-the-default-spot)
  - [2026-11-15 — The bag bar and Hekili: what still writes onto Blizzard's frames](#2026-11-15--the-bag-bar-and-hekili-what-still-writes-onto-blizzards-frames)
  - [2026-11-15 — With IM chat style the tab row is always hidden](#2026-11-15--with-im-chat-style-the-tab-row-is-always-hidden)
  - [2026-11-15 — Temporary chat windows (whispers, pet battle log) are never skinned](#2026-11-15--temporary-chat-windows-whispers-pet-battle-log-are-never-skinned)
  - [2026-11-15 — Chat's scroll bar loses SaftUI's anchor at every dock or lock change](#2026-11-15--chats-scroll-bar-loses-saftuis-anchor-at-every-dock-or-lock-change)
  - [2026-11-15 — Chat's dock hook leaves Blizzard's tab layout after a resize, an overflow-list pick or an undock](#2026-11-15--chats-dock-hook-leaves-blizzards-tab-layout-after-a-resize-an-overflow-list-pick-or-an-undock)
  - [2026-11-15 — A font Size drag restyles too much on the action bars, unit frames and tracker](#2026-11-15--a-font-size-drag-restyles-too-much-on-the-action-bars-unit-frames-and-tracker)
  - [2026-11-15 — Hide full with a secret health: lift the limit with a Step curve into the text's alpha](#2026-11-15--hide-full-with-a-secret-health-lift-the-limit-with-a-step-curve-into-the-texts-alpha)
  - [2026-11-15 — Option descriptions that say "red" or "yellow" for what Danger and Caution color](#2026-11-15--option-descriptions-that-say-red-or-yellow-for-what-danger-and-caution-color)
  - [2026-11-15 — Check box labels: no font setting until a SaftUI check box has a visible label](#2026-11-15--check-box-labels-no-font-setting-until-a-saftui-check-box-has-a-visible-label)
  - [2026-11-15 — A window title font per theme](#2026-11-15--a-window-title-font-per-theme)
  - [2026-11-15 — The tooltip lines take SaftUI's shadow and spacing](#2026-11-15--the-tooltip-lines-take-saftuis-shadow-and-spacing)
  - [2026-11-15 — Title bar height beside Window titles on the Theme tab](#2026-11-15--title-bar-height-beside-window-titles-on-the-theme-tab)
  - [2026-11-15 — Search into the dots menus](#2026-11-15--search-into-the-dots-menus)
  - [2026-11-15 — SaftUI's tracker: what the in-game pass left open](#2026-11-15--saftuis-tracker-what-the-in-game-pass-left-open)
  - [2026-11-15 — SaftUI's tracker phase 2: task quests (bonus objectives and world quests)](#2026-11-15--saftuis-tracker-phase-2-task-quests-bonus-objectives-and-world-quests)
  - [2026-11-15 — SaftUI's tracker phase 3: scenarios and dungeons](#2026-11-15--saftuis-tracker-phase-3-scenarios-and-dungeons)
  - [2026-11-15 — SaftUI's tracker phase 4: Mythic+](#2026-11-15--saftuis-tracker-phase-4-mythic)
  - [2026-11-15 — SaftUI's tracker phase 5: other tracking](#2026-11-15--saftuis-tracker-phase-5-other-tracking)
  - [2026-11-15 — SaftUI's tracker phase 6: zone widgets](#2026-11-15--saftuis-tracker-phase-6-zone-widgets)
  - [2026-11-15 — SaftUI's tracker: do quest items work under [vehicleui] and [overridebar]?](#2026-11-15--saftuis-tracker-do-quest-items-work-under-vehicleui-and-overridebar)
  - [2026-11-15 — Chat's font size against Blizzard's per-window Font Size](#2026-11-15--chats-font-size-against-blizzards-per-window-font-size)
  - [2026-11-14 — Position rows of secure frames can anchor to a frame that is moved in combat](#2026-11-14--position-rows-of-secure-frames-can-anchor-to-a-frame-that-is-moved-in-combat)
  - [2026-11-14 — A first-run setup dialog: UI size, theme, unit frame layout](#2026-11-14--a-first-run-setup-dialog-ui-size-theme-unit-frame-layout)
  - [2026-11-14 — /sui at half with the sidebar collapsed: a validation error is cut or hidden in the footer](#2026-11-14--sui-at-half-with-the-sidebar-collapsed-a-validation-error-is-cut-or-hidden-in-the-footer)
  - [2026-11-13 — Design decisions waiting to be built](#2026-11-13--design-decisions-waiting-to-be-built)
  - [2026-11-13 — Objective tracker skin: in-game checks and what was left out](#2026-11-13--objective-tracker-skin-in-game-checks-and-what-was-left-out)
  - [2026-11-13 — Scale SaftUI across resolutions and stay pixel perfect](#2026-11-13--scale-saftui-across-resolutions-and-stay-pixel-perfect)
  - [2026-11-13 — Bags: a general sort order of draggable blocks, with a per-category override](#2026-11-13--bags-a-general-sort-order-of-draggable-blocks-with-a-per-category-override)
  - [2026-11-13 — Test mode: choose which elements the previews show](#2026-11-13--test-mode-choose-which-elements-the-previews-show)
  - [2026-11-13 — Unit frame profiles are hard to find in /sui](#2026-11-13--unit-frame-profiles-are-hard-to-find-in-sui)
  - [2026-11-13 — Codebase cleanup: small things left over](#2026-11-13--codebase-cleanup-small-things-left-over)
  - [2026-11-12 — Codebase cleanup: the items waiting on a decision](#2026-11-12--codebase-cleanup-the-items-waiting-on-a-decision)
  - [2026-11-12 — Cooldown Manager skin: in-game checks](#2026-11-12--cooldown-manager-skin-in-game-checks)
  - [2026-11-12 — Cooldown Manager skin: a tracked debuff's dispel type on SaftUI's border](#2026-11-12--cooldown-manager-skin-a-tracked-debuffs-dispel-type-on-saftuis-border)
  - [2026-11-12 — Nameplates: the Friendly page's aura borders and cooldown never reach plate buttons](#2026-11-12--nameplates-the-friendly-pages-aura-borders-and-cooldown-never-reach-plate-buttons)
  - [2026-11-12 — Nameplates: what a kind change costs in oUF updates](#2026-11-12--nameplates-what-a-kind-change-costs-in-ouf-updates)
  - [2026-11-12 — Nameplates: a box toggled in combat leaves shown plates on the old config until combat ends](#2026-11-12--nameplates-a-box-toggled-in-combat-leaves-shown-plates-on-the-old-config-until-combat-ends)
  - [2026-11-12 — Nameplates: friendly players and friendly NPCs configured apart](#2026-11-12--nameplates-friendly-players-and-friendly-npcs-configured-apart)
  - [2026-11-11 — Nameplates: in-game checks](#2026-11-11--nameplates-in-game-checks)
  - [2026-11-11 — Nameplates: a plate that turns widgets-only, or back, without a new add](#2026-11-11--nameplates-a-plate-that-turns-widgets-only-or-back-without-a-new-add)
  - [2026-11-11 — Nameplates: small items left after the build](#2026-11-11--nameplates-small-items-left-after-the-build)
  - [2026-11-11 — Purge filters: in-game checks](#2026-11-11--purge-filters-in-game-checks)
  - [2026-11-11 — Purge table: retail gaps](#2026-11-11--purge-table-retail-gaps)
  - [2026-11-11 — Blizzard theme round 2: in-game checks](#2026-11-11--blizzard-theme-round-2-in-game-checks)
  - [2026-11-11 — Blizzard theme: a border per real raid group, not per header](#2026-11-11--blizzard-theme-a-border-per-real-raid-group-not-per-header)
  - [2026-11-11 — /sui: no resize cursor on the grip and the bottom edge](#2026-11-11--sui-no-resize-cursor-on-the-grip-and-the-bottom-edge)
  - [2026-11-11 — Screen edge margin: art reach only for /sui](#2026-11-11--screen-edge-margin-art-reach-only-for-sui)
  - [2026-11-11 — Blizzard theme round 2: test gaps and small items parked in review](#2026-11-11--blizzard-theme-round-2-test-gaps-and-small-items-parked-in-review)
  - [2026-11-11 — Categories tab: the scrolled editor's two gaps](#2026-11-11--categories-tab-the-scrolled-editors-two-gaps)
  - [2026-11-11 — Blizzard theme: in-game checks](#2026-11-11--blizzard-theme-in-game-checks)
  - [2026-11-11 — Edit Mode snapping under Blizzard measures the frames' borders, not the selection art](#2026-11-11--edit-mode-snapping-under-blizzard-measures-the-frames-borders-not-the-selection-art)
  - [2026-11-11 — Per-dispel-type debuff art on SaftUI's own aura buttons](#2026-11-11--per-dispel-type-debuff-art-on-saftuis-own-aura-buttons)
  - [2026-11-11 — Loot feed: retail item quality text and profession overlay sit under the Blizzard ring](#2026-11-11--loot-feed-retail-item-quality-text-and-profession-overlay-sit-under-the-blizzard-ring)
  - [2026-11-11 — Blizzard theme: the bags' rule editor and Categories list keep the options window's own look](#2026-11-11--blizzard-theme-the-bags-rule-editor-and-categories-list-keep-the-options-windows-own-look)
  - [2026-11-11 — Bag categories: in-game checks](#2026-11-11--bag-categories-in-game-checks)
  - [2026-11-11 — Auto Vendor pins now beat Grays' exclusions and equipment sets](#2026-11-11--auto-vendor-pins-now-beat-grays-exclusions-and-equipment-sets)
  - [2026-11-10 — Zone level and faction line: in-game checks](#2026-11-10--zone-level-and-faction-line-in-game-checks)
  - [2026-11-10 — Zone text's fade times are written onto Blizzard's frames](#2026-11-10--zone-texts-fade-times-are-written-onto-blizzards-frames)
  - [2026-11-10 — The zone faction table is a snapshot of two builds](#2026-11-10--the-zone-faction-table-is-a-snapshot-of-two-builds)
  - [2026-11-10 — Chat writes fields and scripts onto Blizzard's chat frames](#2026-11-10--chat-writes-fields-and-scripts-onto-blizzards-chat-frames)
  - [2026-11-10 — Edit box focus borders lost on a theme switch, and two ways of keeping colors](#2026-11-10--edit-box-focus-borders-lost-on-a-theme-switch-and-two-ways-of-keeping-colors)
  - [2026-11-10 — Retail bank leftovers after Themes: category selector, selected window's border, radio group under None](#2026-11-10--retail-bank-leftovers-after-themes-category-selector-selected-windows-border-radio-group-under-none)
  - [2026-11-10 — Themes: in-game checks for what was only compile-checked](#2026-11-10--themes-in-game-checks-for-what-was-only-compile-checked)
  - [2026-11-10 — Bag views: the bank windows build a full button pool per view](#2026-11-10--bag-views-the-bank-windows-build-a-full-button-pool-per-view)
  - [2026-11-10 — Bag views: in-game checks for what the stubs can't show](#2026-11-10--bag-views-in-game-checks-for-what-the-stubs-cant-show)
  - [2026-11-10 — Bag item sort compares item levels as text, and should be built from blocks](#2026-11-10--bag-item-sort-compares-item-levels-as-text-and-should-be-built-from-blocks)
  - [2026-11-10 — The minimap has no SaftUI holder, so the screen edge margin only holds it in edit mode](#2026-11-10--the-minimap-has-no-saftui-holder-so-the-screen-edge-margin-only-holds-it-in-edit-mode)
  - [2026-11-10 — panels.tab_height has no option, because nothing live reads it](#2026-11-10--panelstab_height-has-no-option-because-nothing-live-reads-it)
  - [2026-11-10 — Colors tab: role and rune colors, and a switch for Blizzard's class colors](#2026-11-10--colors-tab-role-and-rune-colors-and-a-switch-for-blizzards-class-colors)
  - [2026-11-09 — st:Kill and st:SkinIcon still write onto Blizzard pieces (roll bars and elsewhere)](#2026-11-09--stkill-and-stskinicon-still-write-onto-blizzard-pieces-roll-bars-and-elsewhere)
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
  - [2026-11-16 — The Sourced-from line on a plate page could link to the other page](#2026-11-16--the-sourced-from-line-on-a-plate-page-could-link-to-the-other-page)
  - [2026-11-16 — The TO dropdown names parts by key](#2026-11-16--the-to-dropdown-names-parts-by-key)
  - [2026-11-16 — All units' Position offers anchors some units lack (pre-flight ruling L7 was never built)](#2026-11-16--all-units-position-offers-anchors-some-units-lack-pre-flight-ruling-l7-was-never-built)
  - [2026-11-13 — Unit frames: shared settings across units, and small parts as menu items](#2026-11-13--unit-frames-shared-settings-across-units-and-small-parts-as-menu-items)
  - [2026-11-11 — Old gear's tabard and shirt exclusion never matched](#2026-11-11--old-gears-tabard-and-shirt-exclusion-never-matched)
  - [2026-11-15 — A bag window's least width ignores a Window titles change](#2026-11-15--a-bag-windows-least-width-ignores-a-window-titles-change)
  - [2026-11-11 — Bag categories: a Set checkbox is dead while the Equipment sets entry hides the window](#2026-11-11--bag-categories-a-set-checkbox-is-dead-while-the-equipment-sets-entry-hides-the-window)
  - [2026-11-11 — Rule editor: a level mode picked before a number is typed does nothing](#2026-11-11--rule-editor-a-level-mode-picked-before-a-number-is-typed-does-nothing)
  - [2026-11-15 — Auto Vendor's second question overstates the earlier stacks that leave](#2026-11-15--auto-vendors-second-question-overstates-the-earlier-stacks-that-leave)
  - [2026-11-15 — Auto Vendor counts a fresh purchase in a just-sold slot as a refused sale](#2026-11-15--auto-vendor-counts-a-fresh-purchase-in-a-just-sold-slot-as-a-refused-sale)
  - [2026-11-15 — Forever: Show in > Bank does nothing for the default bank (the combined bank)](#2026-11-15--forever-show-in--bank-does-nothing-for-the-default-bank-the-combined-bank)
  - [2026-11-14 — The options kit's keybinding widget doesn't know META or Blizzard's ignored keys](#2026-11-14--the-options-kits-keybinding-widget-doesnt-know-meta-or-blizzards-ignored-keys)
  - [2026-11-15 — Reset walks: the feed's, Minimap's and Micro menu's movers are registered inline, so the tests pin a copy](#2026-11-15--reset-walks-the-feeds-minimaps-and-micro-menus-movers-are-registered-inline-so-the-tests-pin-a-copy)
  - [2026-11-15 — Blizzard's tracker: the Position reset is tested on Forever only](#2026-11-15--blizzards-tracker-the-position-reset-is-tested-on-forever-only)
  - [2026-11-15 — Buffs and debuffs: Size and Outline keep hand defaults a derived one would replace](#2026-11-15--buffs-and-debuffs-size-and-outline-keep-hand-defaults-a-derived-one-would-replace)
  - [2026-11-15 — Buffs and debuffs: Wrap's hand reset copies the General group's set](#2026-11-15--buffs-and-debuffs-wraps-hand-reset-copies-the-general-groups-set)
  - [2026-11-15 — Buffs and debuffs: one helper for the wrap the layout keeps, so the layout and Wrap's default cannot drift](#2026-11-15--buffs-and-debuffs-one-helper-for-the-wrap-the-layout-keeps-so-the-layout-and-wraps-default-cannot-drift)
  - [2026-11-15 — A roll result line's All passed and winner color are baked in at push](#2026-11-15--a-roll-result-lines-all-passed-and-winner-color-are-baked-in-at-push)
  - [2026-11-15 — Chat's Fade tabs: ChatFrameUtil.GetTabAlphas isn't in the retail source](#2026-11-15--chats-fade-tabs-chatframeutilgettabalphas-isnt-in-the-retail-source)
  - [2026-11-15 — Chat: the dock hook adds a second anchor to docked tabs 2 to n, and the dock test can't see it](#2026-11-15--chat-the-dock-hook-adds-a-second-anchor-to-docked-tabs-2-to-n-and-the-dock-test-cant-see-it)
  - [2026-11-15 — Chat's edit box can sit off the top of the screen when the chat Theme is None](#2026-11-15--chats-edit-box-can-sit-off-the-top-of-the-screen-when-the-chat-theme-is-none)
  - [2026-11-15 — getHealthPercentText's floor branch is never used](#2026-11-15--gethealthpercenttexts-floor-branch-is-never-used)
  - [2026-11-15 — Two lines of the profile switch fix that no test pins](#2026-11-15--two-lines-of-the-profile-switch-fix-that-no-test-pins)
  - [2026-11-15 — Unit frame defaults: string offsets left outside the castbars](#2026-11-15--unit-frame-defaults-string-offsets-left-outside-the-castbars)
  - [2026-11-15 — Unit frames: a part switched off in the new profile keeps its old points](#2026-11-15--unit-frames-a-part-switched-off-in-the-new-profile-keeps-its-old-points)
  - [2026-11-15 — Unit frames: a vehicle power type with no oUF color falls back to Mana](#2026-11-15--unit-frames-a-vehicle-power-type-with-no-ouf-color-falls-back-to-mana)
  - [2026-11-15 — Unit frames: a color oUF lacks is set to the profile's own table](#2026-11-15--unit-frames-a-color-ouf-lacks-is-set-to-the-profiles-own-table)
  - [2026-11-15 — Two Misc readers break "a pass only colors"](#2026-11-15--two-misc-readers-break-a-pass-only-colors)
  - [2026-11-11 — UIParent's scale is set once, at login, so plates leave whole pixels after a UI scale or display change](#2026-11-11--uiparents-scale-is-set-once-at-login-so-plates-leave-whole-pixels-after-a-ui-scale-or-display-change)
  - [2026-11-15 — A reset on every font row](#2026-11-15--a-reset-on-every-font-row)
  - [2026-11-14 — Categories tab at full size: a long "Reset <name> to default" overlaps Delete](#2026-11-14--categories-tab-at-full-size-a-long-reset-name-to-default-overlaps-delete)
  - [2026-11-11 — Grays/Auto Vendor: a finished edit that broadens its rule sells at the next merchant](#2026-11-11--graysauto-vendor-a-finished-edit-that-broadens-its-rule-sells-at-the-next-merchant)
  - [2026-11-11 — The disabled loot popup writes nametext onto Blizzard's LootButton](#2026-11-11--the-disabled-loot-popup-writes-nametext-onto-blizzards-lootbutton)
  - [2026-11-09 — st:CreateHeader writes title and close_button onto the Blizzard panels it skins](#2026-11-09--stcreateheader-writes-title-and-close_button-onto-the-blizzard-panels-it-skins)
  - [2026-11-11 — Nameplates: a profile switch doesn't set the game's friendly plates](#2026-11-11--nameplates-a-profile-switch-doesnt-set-the-games-friendly-plates)
  - [2026-11-12 — Unit frames: a profile switch places a frame's parts against the old profile's anchors](#2026-11-12--unit-frames-a-profile-switch-places-a-frames-parts-against-the-old-profiles-anchors)
  - [2026-11-14 — Copy from writes default tables into keys the source unit doesn't have](#2026-11-14--copy-from-writes-default-tables-into-keys-the-source-unit-doesnt-have)
  - [2026-11-12 — Nameplates: a plate page's Position editor checks anchors against whichever plate has the lowest number](#2026-11-12--nameplates-a-plate-pages-position-editor-checks-anchors-against-whichever-plate-has-the-lowest-number)
  - [2026-11-09 — st:CreateButton's SetText and SetFont aliases break when called as methods](#2026-11-09--stcreatebuttons-settext-and-setfont-aliases-break-when-called-as-methods)
  - [2026-11-13 — Colour swatches read as checkboxes, and the colour picker](#2026-11-13--colour-swatches-read-as-checkboxes-and-the-colour-picker)
  - [2026-11-13 — Character frame slots: SaftUI writes fields onto Blizzard's buttons](#2026-11-13--character-frame-slots-saftui-writes-fields-onto-blizzards-buttons)
  - [2026-11-11 — Bag categories: a default added in a later version can duplicate a user category's name](#2026-11-11--bag-categories-a-default-added-in-a-later-version-can-duplicate-a-user-categorys-name)
  - [2026-11-11 — Bag settings: the reagent section nothing reads](#2026-11-11--bag-settings-the-reagent-section-nothing-reads)
  - [2026-11-13 — Bag search box is made multi-line](#2026-11-13--bag-search-box-is-made-multi-line)
  - [2026-11-10 — Bank eye toggle doesn't re-apply the bag search](#2026-11-10--bank-eye-toggle-doesnt-re-apply-the-bag-search)
  - [2026-11-13 — Chat's dock hook runs only on forced updates](#2026-11-13--chats-dock-hook-runs-only-on-forced-updates)
  - [2026-11-10 — Zone faction line edge cases: a PvP subzone's status, same-named zones on the map](#2026-11-10--zone-faction-line-edge-cases-a-pvp-subzones-status-same-named-zones-on-the-map)
  - [2026-11-09 — Loot feed: a merge while scrolled shifts the scroll offset](#2026-11-09--loot-feed-a-merge-while-scrolled-shifts-the-scroll-offset)
  - [2026-11-11 — Class power types with no Blizzard art draw a borderless flat bar under Blizzard](#2026-11-11--class-power-types-with-no-blizzard-art-draw-a-borderless-flat-bar-under-blizzard)
  - [2026-11-11 — Blizzard bag-bar slots and the Hekili skin write onto frames that aren't SaftUI's](#2026-11-11--blizzard-bag-bar-slots-and-the-hekili-skin-write-onto-frames-that-arent-saftuis)
  - [2026-11-10 — The Hekili and WeakAuras skins error when Skinning's Theme is None](#2026-11-10--the-hekili-and-weakauras-skins-error-when-skinnings-theme-is-none)
  - [2026-11-14 — Tracker: a tracker moved in Blizzard's Edit Mode isn't the first position](#2026-11-14--tracker-a-tracker-moved-in-blizzards-edit-mode-isnt-the-first-position)
  - [2026-11-15 — Keybind mode's hint line could read Muted](#2026-11-15--keybind-modes-hint-line-could-read-muted)
  - [2026-11-11 — st:SetBackdrop and st:SetBackdropIn do arithmetic on frame levels that can be Blizzard's](#2026-11-11--stsetbackdrop-and-stsetbackdropin-do-arithmetic-on-frame-levels-that-can-be-blizzards)
  - [2026-11-12 — Nameplates: a neutral unit turning hostile keeps its name's old color](#2026-11-12--nameplates-a-neutral-unit-turning-hostile-keeps-its-names-old-color)
  - [2026-11-11 — Health text's Boss percent and Hide full with a secret health](#2026-11-11--health-texts-boss-percent-and-hide-full-with-a-secret-health)
  - [2026-11-11 — ItemRack is still an optional dependency, and nothing reads it](#2026-11-11--itemrack-is-still-an-optional-dependency-and-nothing-reads-it)
  - [2026-11-14 — Three copies of the source lexer in tests](#2026-11-14--three-copies-of-the-source-lexer-in-tests)
  - [2026-11-15 — SaftUI's tracker: experiments and in-game checks before the switch turns on](#2026-11-15--saftuis-tracker-experiments-and-in-game-checks-before-the-switch-turns-on)
  - [2026-11-14 — Tracker: a refresh allocates about 175 KB, measure it in game](#2026-11-14--tracker-a-refresh-allocates-about-175-kb-measure-it-in-game)
  - [2026-11-13 — Objective tracker skin: zone grouping, max height and a scroll frame](#2026-11-13--objective-tracker-skin-zone-grouping-max-height-and-a-scroll-frame)
  - [2026-11-15 — The action bars' and buffs' texts default to Small text](#2026-11-15--the-action-bars-and-buffs-texts-default-to-small-text)
  - [2026-11-15 — All bars' Cooldown diff icon misses a bar that owns a size or outline alone](#2026-11-15--all-bars-cooldown-diff-icon-misses-a-bar-that-owns-a-size-or-outline-alone)
  - [2026-11-10 — Fonts: separate the fonts users pick per kind of text from SaftUI's internal font objects](#2026-11-10--fonts-separate-the-fonts-users-pick-per-kind-of-text-from-saftuis-internal-font-objects)
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

### 2026-11-17 — Micro buttons' hover: one alpha a texture or two

**What:** the micro buttons' hover was fixed (commit `6567f8c9`, branch `r2-opaque-fill`) by painting the state colors again after Blizzard's `SetNormal` and `SetPushed`, on the theory that the client keeps one alpha for a texture, so Blizzard's `highlight:SetAlpha(1)` / `SetAlpha(.5)` after the atlas swap wipes the hover's 16% vertex alpha. The order of the writes is established from Blizzard's source and the buttons' pattern (Professions to Shop broke; Character has no alpha write; the game menu button is repaired by its `OnUpdate` swap, at once under the mouse because `OnEnter` zeroes `updateInterval`). The alpha model itself is unverified: the lines below decide it. With two alphas the hook changes nothing that shows.

**Why noticed:** the owner's in-game pass, 2026-11-16, flat theme, purple Accent: a hover that should be a faint 16% tint was a solid Accent block on the micro buttons from Professions to Shop.

**Anchors:** `SaftUI-Minimap/microbuttons.lua` (`PaintButton`, the hooks in `SkinButton`, `StyleArt`); `tests/minimap/interaction_states_test.lua` (`one_alpha` and the case after it: this entry decides which model is real); `.agents/taint.md` rule 20; `.agents/testing.md` rule 4.

**What's been considered:** the one-alpha variants: (i) one value that `SetAlpha` and an explicit vertex alpha both write, which a 3-argument `SetVertexColor` leaves alone (what `one_alpha` models, and what the repo's evidence allows: SaftUI fades the game menu's performance bar and each reused loot row's art once with `SetAlpha(0)` while Blizzard recolors them every second or every open with a 3-argument `SetVertexColor`, and they stay faded); (ii) the same but a 3-argument `SetVertexColor` resets the alpha to 1 (the documented default), which the evidence argues against; (iii) two multiplied alphas, under which the symptom cannot come from this path and the fix is a no-op.

**Shape of work:** the owner pastes these in game, in order. (a), on a test texture (186 characters; a red square in the middle of the screen):

`/run T=T or UIParent:CreateTexture()T:SetColorTexture(1,1,1)T:SetSize(200,200)T:SetPoint("CENTER")T:SetVertexColor(1,0,0,.16)T:SetAlpha(1)print(T:GetAlpha(),select(4,T:GetVertexColor()))`

A faint red square printing `1 0.16` means two alphas (iii). A solid red square printing `1 1` means `SetAlpha` wrote the vertex alpha (one alpha). Then (b), the variant (98 characters):

`/run T:SetAlpha(.5)T:SetVertexColor(1,0,0)print(T:GetAlpha(),select(4,T:GetVertexColor()))T:Hide()`

`0.5 1` means two alphas. `0.5 0.5` means one value that an omitted alpha leaves (variant i, the test's model). `1 1` means an omitted alpha resets it (variant ii): then also check the loot rows' and the game menu's art for coming back after an open. Then (c), on the fixed build, with a window open and closed (132 characters):

`/run local h=ProfessionMicroButton:GetHighlightTexture()print(h:GetAlpha(),h:GetVertexColor())print(h:GetBlendMode(),h:GetTexture())`

`GetAlpha()` reads about 0.16 under one alpha and 1 under two; the blend should be `BLEND` and the texture the flat white one. Put the answer into `tests/minimap/interaction_states_test.lua` (~131) and `.agents/testing.md` rule 4, and drop the model that is not real. **If one alpha is confirmed**, check the other Blizzard textures SaftUI paints for a Blizzard alpha write after the paint: the tracking, queue and expansion buttons (`micromenuitems.lua:27`), the totem buttons (`totemskin.lua:461`), the Blizzard tracker skin's item button (`Blizzard_ObjectiveTracker.lua:475`), the bag slots (`bag.lua:284`), and `StyleArt`'s `highlight:SetVertexColor(1, 1, 1, 1)` on a switch to the Blizzard look (`microbuttons.lua:155-160`), which writes alpha 1 over Blizzard's 0.5 while a window is open, until the next `SetPushed`.

### 2026-11-17 — Scroll bar thumbs: the same solid hover reads soft on chat and opaque on the tracker

**What:** a scroll thumb's hover is the spec's solid light tone and every thumb uses the same code, but the whole bar's alpha differs: Blizzard fades chat's bar to 0.6 (`FCF_FadeInScrollbar`, `FloatingChatFrame.lua`, and out to 0 on leave), the tracker's sits at 1 (0.4 while locked, 0 when hidden: `TR:UpdateBar`, `SaftUI-Tracker/window.lua`) and the bags' sits at 1. So the same fill reads as a soft tint on chat and as an opaque block on the tracker and the bags. The owner should pick the rule: all bars faded like chat's, all at full, or the thumb's fill lighter. No code change made.

**Why noticed:** the owner's in-game pass, 2026-11-16: "the slider seems to have inconsistent fade opacity", one of the three reports of the opaque-fill round (`r2-opaque-fill`). Not a bug in the thumb itself: both thumbs get the spec's solid from `st:SkinNewScrollBar` (`SaftUI-Core/Widgets/scrollbar.lua`), which chat reaches through `st:SkinScrollBar` and the tracker and the bags through `st:CreateScrollFrame`.

**Anchors:** `SaftUI-Core/Widgets/scrollbar.lua` (`st:SkinNewScrollBar`, `DrawScrollBar`); `SaftUI-Tracker/window.lua` (`TR:UpdateBar`, `BAR_LINGER`); `SaftUI-Chat/` (the chat bar); Blizzard's `FCF_FadeInScrollbar`; `docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md` (the thumb's row: Solids, `hover` is T+, solid; says nothing about the bar's alpha) and `docs/design-system/README.md`.

**What's been considered:** the three rules above; the spec's Layers mix the Accent in at 0.6, so a bar at 0.6 happens to match that strength on chat.

**Shape of work:** one decision, then a small change in the one place that sets the bar's alpha (Core's thumb, the tracker's `UpdateBar`) and a line in the spec's thumb row and the design system.

**Open questions:** which rule; whether a locked tracker's 0.4 stays.

### 2026-11-16 — The loot window's opaque hover on the first open: nothing found that writes it

**What:** on the first open of the loot window after a `/reload`, a row's hover (the card's Layer, `SaftUI-Loot/popup.lua` `StyleCard`/`HoverCard`) drew as a solid block of the hover tone; later hovers were a 16% tint. The micro buttons' same-looking symptom was fixed by repainting after Blizzard's alpha write (branch `r2-opaque-fill`), but for the loot rows no writer exists, in either alpha model (see "Micro buttons' hover: one alpha a texture or two"), so the suspects are draw order and frame levels, not a stored alpha.

**Why noticed:** the owner's in-game pass of the interaction states checks on 2026-11-16 (check 28). Measured in their screenshot: the card is the hover tone (`a978ff` there) at full strength, inside the Layer's inset and over the slot's backdrop, the same color the 16% tints elsewhere carry, so it is the Layer drawn solid, not another piece.

**Anchors:** `SaftUI-Core/Widgets/states.lua` (`Restyle`, `Refresh`, `Colors`); `SaftUI-Loot/popup.lua` (`StyleCard`, `HoverCard`, `Sweep`, the scroll box `Update` post-hook; `LT.PopupCards`, element -> holder, read-only, for the `/run` below); `tests/loot/fixtures/loot_frame.lua` (it has neither the row's `ShowAnim` nor SpeedyAutoLoot's reparent); Blizzard's `LootFrame.lua`/`.xml` (forever); SpeedyAutoLoot, an addon the owner runs.

**What's been considered:** established from the code (no writer): the card Layer is made at `AddStates`, never lazily on hover; `Restyle` sets its alpha to 1 and then `Refresh` hides it; the hover paints (`SetVertexColor(T+, 0.16)`) in the same call that shows it, so no frame is drawn between; the theme walkers skip it (`KeptAll` takes only `edgeKind == 'theme'` records and the card is `edge = false`; `RecolorThemed` and `RedrawThemed` color `holder.backdrop`, not the holder's textures); the state color cache is stamped by the Accent, the states table and a serial, so there is no first-use error; Blizzard's loot code writes only Blizzard regions and the ScrollBox only manages the row frames. So no code path writes the Layer's alpha after its paint, whether the client keeps one alpha a texture or two. What differs on the first open: (1) SaftUI builds the card's pieces (holder, `holder.backdrop`, the Layer, the slot backdrop) inside the scroll box `Update` post-hook, after Blizzard's `Init` has started the row's 0.1 s fade-in (`ShowAnim`, alpha 0 to 1); later opens skip it because the row is already styled (`styled[element] == generation`). (2) The holder and the slot's backdrop are both one level below the row (`popup.lua` `SetLevel(holder, element, -1)` and the slot's; the holder is made first), so which draws on top is the client's choice, and the owner's screenshot has the solid tone over the slot's backdrop. (3) SpeedyAutoLoot reparents `LootFrame` to UIParent at HIGH strata, raises it and re-anchors it on `LOOT_READY`, moves it back to its hidden frame on `LOOT_CLOSED`, and on Forever post-hooks `LootFrame.UpdateShownState` to do the same; that re-levels the whole tree around the first-open creation. Neither the fade-in nor the reparent is in the fixture. Not ruled out: a draw quirk of a texture made while its row's alpha animation runs.

**Shape of work:** an in-game probe first. With the window just opened after a reload and a row showing opaque, with the mouse on it, paste this (208 characters; it needs `LT.PopupCards`, in this branch):

`/run for e,h in pairs(SaftUI:GetModule("Loot").PopupCards)do if e:IsShown()then local l=SaftUI:StateLook(h)local y=l.layer print(l.hover,y.shown,y.a,y.alpha,y.blend,h:GetFrameLevel()-e:GetFrameLevel())end end`

It prints, for each shown row: the card's hover state, whether the Layer shows, its vertex alpha, its texture alpha, its blend mode, and the holder's frame level minus its row's (a row should print `-1`). Read it so: hover `true`, shown `true`, vertex alpha `0.16` and texture alpha `1` with a solid block on screen means the stored values are right and it is draw order or levels (compare the level with the slot backdrop's, `SaftUI:StateLook` has no slot; read `LootFrame.ScrollBox.ScrollTarget:GetChildren()` and their `.Item` children's levels); a vertex alpha or texture alpha of `1` means something wrote it (hook the Layer's `SetAlpha` and `SetVertexColor` with `debugstack`); a blend of `ADD` points at the blend mode. Then hover off and on and run it again.

**Open questions:** whether it happens on a later open whose rows are new (a corpse with more items than any before); whether it happens with SpeedyAutoLoot off.

### 2026-11-16 — The /sui slider's knob shows no hover or held state in the game: cause not found

**What:** in the game on the flat theme the owner sees no hover and no held state on a `/sui` range's knob (in-game check 6: expected light blue under the mouse, darker while dragged, the fill staying blue), while the scroll bar's thumb shows its states. Every test passes, in the stubs and in the real window with the mouse played, so the cause is a difference between the stubs and the client that nothing here shows.

**Why noticed:** the owner's round 2 in-game check of the interaction states, 2026-11-16. The fix round (branch `r2-slider`) read the code and ran it in the stubs without finding the cause.

**Anchors:** `SaftUI-Core/Config/optionsrange.lua` (`st:AddStates(slider, 'knob', ...)`, `LookRange`), `SaftUI-Core/Widgets/states.lua` (`Rewire`, `Colors`, `PutSolid`), `tests/core/kit_states_test.lua` ("the range: the fill stays the accent..."), `tests/core/options_range_mouse_test.lua`.

**What's been considered:** ruled out in the stubs: the helper's hooks after the slider's own scripts, a later `SetScript` dropping them, the 'knob' paint (rest, hover and pushed differ in Thick and Thin), the real window with the mouse moved row then slider, a covering frame (the slider and the value box are the mouse focus at their centres once a reparent moves the children above their parent). Not ruled out, needs the game: the client's Slider not firing OnEnter, OnLeave, OnMouseDown or OnMouseUp to hooks, or the client drawing the thumb without its vertex color. Under Blizzard the knob has no hover art by design.

**Shape of work:** the owner pastes the `/run` line from `r2-slider-report.md` while holding the mouse over a knob; its numbers decide between the two.

### 2026-11-16 — Redesign the loot window

**What:** the owner wants the loot window (Blizzard's scroll box `LootFrame`, skinned by `SaftUI-Loot/popup.lua`) redesigned. Today it is Blizzard's layout in SaftUI's theme: a small titled panel ("Items", a close cross) with one row per item (icon, name, the quality word at the right).

**Why noticed:** the owner's in-game pass of the interaction states checks on 2026-11-16 (check 28, "The loot window and the feed"). While reporting that a row's hover fill was fully opaque on the first open after a reload, they added: "Also can you add a follow up to redesign this loot window?" They gave no direction for the new design. Their screenshot showed two rows (a Poor and a Common item) in a panel about 215 wide under the mouse.

**Anchors:** `SaftUI-Loot/popup.lua` (the skin: post-hooks and weak tables only), `.agents/taint.md` rule 18 (what the skin may and may not do to `LootFrame`), the Loot window page in `/sui` (Enable, Theme, Background, Font), `SaftUI-Loot/Feed/` and `rollbar.lua` (SaftUI's own loot looks, for a shared language), `docs/design-system/`.

**Shape of work:** a design pass first (brainstorm with the owner, mockups in a private artifact), then a plan. The size depends on whether the redesign can stay a skin of Blizzard's frame (rule 18's limits: no reparenting, no sizes on its secure parts in combat) or needs SaftUI's own window, which is a larger piece (looting in combat, the secure click).

**Open questions:** what the owner dislikes about today's window and what they want from it (compact rows, quality color instead of the quality word, item level or price, where it opens); a skin or SaftUI's own frame.

### 2026-11-16 — The tracker's wrapped text, one line short: the cause is inferred, not seen in the game

**What:** a quest's text that wraps to three lines was laid out as two, so the third line drew over the next quest's title. The fix keeps the rows' kept heights per scale; whether that was the whole cause is for the game to say.

**Why noticed:** the owner's screenshot (Duskwood, a quest whose one text line wraps to three at the tracker's width, no Lua error), a week after testing `/sui scale`. Branch `fb-tracker-wrap`.

**Anchors:** `SaftUI-Tracker/rows.lua` (`TR:Measure`, `TR:CheckFonts`), `tests/tracker/wrap_test.lua`, `SaftUI-Core/uiscale.lua` (`UIScale:OnChanged`).

**What's been considered:** `TR:Measure` keeps a height per text and width, valid for `fontStamp`, which `CheckFonts` bumped only on a font change. A UI scale change moves glyph widths (the game snaps them to whole pixels), so the same text at the same width can wrap to another count while the kept height stays: the scale is now in the key. Ruled out by reading: the width measured is the width drawn (only `Measure` sets a row text's width; `Width` is the zone title's), and a no-objective quest's line takes the same width path as an objective's. Not ruled out without the game: a font file not loaded at the first measure, and `GetStringHeight` read before the client has laid the text out.

**Shape of work:** the owner pastes the `/run` line from the report on a wrong row; if the numbers show the string height is 3 lines and the layout used 2 at the same scale as the last draw, the cause is another one (then measure by `GetNumLines` and `GetLineHeight`).

### 2026-11-16 — Unit frames shared settings: dead code, stale comments, names with two meanings, and shared.lua at 1293 lines

**What:** A cleanup of the shared settings code that the final review found and left: stale comments, code no source path calls, a duplicate, names that mean two things, and one file holding six concerns.

**Why noticed:** The final review of the plan "unit frames: parts and sharing" (`.superpowers/sdd/2026-11-15-saftui-unitframes-parts-and-sharing/final-review.md`, Minor 4).

**Anchors:**
- Stale comments: `SaftUI-Unitframes/config/shared.lua:8` ("Nothing calls the conversion or the sync at login yet"); `SaftUI-Unitframes/config/config.lua:821` ("Elements (General, Health, Name, Power, ...) as tabs"); `SaftUI-Unitframes/config/profiles.lua:8-11` (the pick line reads "Unit, Copy from, Profile, Manage" with only the nameplates lacking Copy from: All units lacks it too).
- Code no source path calls: `UF.PartShare` (`SaftUI-Unitframes/config/sharedoptions.lua:181-186`: the decorator shares a part row through its `saved` path); `UF.PartFor` and `UF.UnitParts` (`SaftUI-Unitframes/config/parts.lua:78, 97`, used by tests only).
- Duplication: `config.lua:351`'s local `UnitName` duplicates `UF.UnitPageName`.
- Names that mean two things: in `shared.lua` the local `PARTS` (`:498`, a position's fields) beside `UF.PARTS` (unit frame parts); `part` is a position field or `'toggle'`/`'color'` in `SetShared` and `WriteValue`, but a unit frame part in `entry.part`.
- Size: `shared.lua` is 1293 lines holding six concerns (the entries, compare and copy, the API, the ticker, the conversion, backup, restore and state).

**Shape of work:** remove or rename the above; move `shared.lua:918-1293` (backup, restore, states, `PrepareShared`, `EnableShared`) to `SaftUI-Unitframes/config/sharedsetup.lua`, and let the file allowlist in `tests/unitframes/shared_guard_test.lua` follow (and `config/load.xml`, and `.agents/architecture.md`).

**Done 2026-11-17, left open:** `shared.lua`'s second half (backup, restore, the conversion, states, `PrepareShared`, `EnableShared`) is `config/sharedsetup.lua` (it reads the locals it needs through `UF.sharedLocals`); the three stale comments are fixed; `config.lua`'s `UnitName` is `UF.UnitPageName`; the local `PARTS` is `POSITION_FIELDS`; `UF.PartShare` is gone. Left for the owner:
- `UF.PartFor` and `UF.UnitParts` (`config/parts.lua`) are called by tests only (`parts_test.lua`, `config_test.lua`: they are the oracle of what each page shows). Options: A, remove them and move the same two functions into `tests/unitframes/page_world.lua` as test helpers (about ten call sites change); B, keep them in `parts.lua` (now commented as test-only). Recommendation: B, since a test needs a list of parts per unit that does not go through the pages it checks, and the cost of keeping is two small functions.
- `part` means a position field or `'toggle'`/`'color'` in `SetShared` and `WriteValue` (shared.lua), but a unit frame part in `entry.part`. The entry names no target. Options: A, rename the parameter to `field` in both (the signature in `.agents/architecture.md` follows; no caller changes, as it is positional); B, leave. Recommendation: A, a mechanical rename.

### 2026-11-16 — Search stops at 100 results, so a part's name cuts the last pages

**What:** `/sui`'s search lists at most 100 results (`MAX_RESULTS` in `OM.Search`, `SaftUI-Core/Config/optionsmodel.lua`). A part's name matches its whole menu on every page, so searching a part by name over all fourteen picks (`Health text`, `Cast bar`) fills the 100 with the first pages (All units and the first eleven units) and never lists Raid 40's menu or the nameplates'.

**Why noticed:** Task 7 of the unit frames parts and sharing plan wrote `tests/unitframes/search_test.lua`. Its brief's example, `Health text`, could not list a result per unit: the cap cut it. The test pins the cut as a fact; the per-unit cases use `Quest` and `Deficit`, whose matches fit.

**Anchors:** `SaftUI-Core/Config/optionsmodel.lua` (`MAX_RESULTS`, `OM.Search`); `tests/unitframes/search_test.lua` (case 2, the cap); `docs/superpowers/plans/2026-11-15-saftui-unitframes-parts-and-sharing.md` (Task 7).

**What's been considered:** Group the results per page and show a count ("Raid 40: 12 results"), so a page is never silently missing; rank a part row above its menu's settings, so the row of each page comes first and the menu's settings after; raise the cap (the cost is the results list's rows, and a list of 300 reads badly). The cap is Core's documented behavior and not unit-frame-specific, so a change is Core's and every page's search changes with it.

**Shape of work:** Small model change in `OM.Search` (the order and a per-page cap or count) with the existing search tests updated, then the unit page cases in `search_test.lua` flipped from "pinned as a fact" to the new rule.

**Open questions:** The owner's call: grouping with a count, ranking, or a higher cap. Whether a follower should be listed beside All units at all (search lists both today and knows no owner).

### 2026-11-16 — All units: small rules left open

**What:** Four small rules of the All units wiring that the owner has not decided or that no test pins:
- A slider dragged away from the value a unit follows and back to it ends the drag as the unit's own setting, because the first step away made it own. A single set to the value it already shows keeps it following.
- A Custom color picked while its box is unticked keeps the unit following, and the unit's hidden color is replaced if All units later ticks its box (0.9 became 0.3 in the review). Ticking the unit's own box first keeps it.
- ~~The rule that an owner stays an owner when it sets All units' value (the spec says an owner counts as differing even when equal) has no test: a mutant that makes it follow survives.~~ *Pinned 2026-11-17 (`tests/unitframes/shared_test.lua`, "an owner stays an owner when All units is set to the value it holds").*
- From the second login AceDB's wildcard leaves empty tables under the saved `backup` (`debuffs`, `grouproleindicator`, `questindicator`, `raidroleindicator`, `raidtargetindicator`, `range_alpha`). No value, harmless; storing the backup out of the wildcard's reach would avoid it.
- ~~The paused notice's wording, "a Reset there follows All units when sharing resumes": the paused Reset writes All units' value at once.~~ *Said truly now (the in-game checklist, section H).*

**Why noticed:** The reviews of Task 6 (`.superpowers/sdd/2026-11-15-saftui-unitframes-parts-and-sharing/task-6-review.md`, the last two rounds): all Minor or Nit, left open when the owner said go to merge on 2026-11-16.

**Anchors:** `SaftUI-Unitframes/config/shared.lua` (`UF:OwnShared`, the set rule, `MakeBackup`, the notices); `SaftUI-Unitframes/config/sharedoptions.lua` (`DecorateShares`, `UF.SharedText`); `tests/unitframes/shared_page_test.lua`, `shared_guard_test.lua`; `task-6-review.md` ("New findings", "Final residual risks").

**What's been considered:** A drag's own flag could be decided at the end of the drag, when the value is compared (the kit's `applyOnRelease` is the hook); a color's hidden value could be kept apart from its box; the owner rule needs only a test.

**Shape of work:** One small round: a test for the owner rule, the wording of the notice, then the two behaviors if the owner wants them changed. The backup's empty tables are optional.

**Open questions:** Whether a slider dragged back to the followed value should follow again; whether a Custom color should be kept when its box is later ticked on All units.

**Left 2026-11-17 (the owner's calls, with a recommendation):**
- *Slider dragged back to the followed value.* A: leave it (a drag that left the value made the unit own it; honest to what the owner did). B: decide at the end of a drag by comparing, through the kit's `applyOnRelease`, so a drag that ends on the followed value keeps following. Recommendation: B, one small change in the slider's apply path, and it matches what a click that sets the shown value already does.
- *A Custom color's hidden value when All units later ticks its box.* A: leave (the unit's hidden color is replaced). B: keep the hidden color apart from its box so the unit's own pick survives. Recommendation: A unless the owner has lost a color this way in use; B needs a second stored value per color.
- *The backup's empty tables after the second login.* Harmless; storing the backup out of AceDB's wildcard's reach is optional. Recommendation: leave.

### 2026-11-16 — Nameplates and All units

**What:** The nameplates (Enemy and Friendly) are not members of All units: their settings are their own, and a change on All units never reaches them. The plate pages have Parts rows and shared-looking settings (Theme, Background, Name, Health text) that a unit frame page would share.

**Why noticed:** Ruling 4 of the unit frames parts and sharing plan (`.superpowers/sdd/2026-11-15-saftui-unitframes-parts-and-sharing/progress.md`), made while the owner slept: plates differ from frames by default (a 200 by 20 bar, a name inside, short health), so one "most units show" value would give every plate an own mark and every plate setting a diff on All units. It is cheap to reverse and was told to the owner.

**Anchors:** `SaftUI-Unitframes/config/shared.lua` (`UF.SHARE_MEMBERS`: eleven members, no plate); `SaftUI-Unitframes/config/units/all.lua`; `SaftUI-Unitframes/nameplates/options.lua` (the plate pages); the spec's 4.9.

**What's been considered:** Making each plate kind a member (Enemy and Friendly), with the plates' own defaults held in their own entries; or a second All entry for plates; or a note on the plate pages saying All units does not reach them (they have none today).

**Shape of work:** A design pass first: which settings the plates share with the frames and what a plate's own default should read as. Then a members' list change, the plate pages' decorator (plate pages are built in `nameplates/options.lua`, not `GetUnitConfig`) and the conversion's tests over the plate profiles.

**Open questions:** Whether the owner wants plates in All units at all; if yes, as one member or two.

### 2026-11-16 — The states scan misses hand-rolled states it should catch

**What:** `tests/core/states_scan_test.lua` is the brief's S1 to S5, which is narrow. The final review planted seven hand-rolled states in scratch copies of real files and the scan caught one: a `SetBackdropBorderColor(st:ColorRGBA('accent'))` in an `OnEnter` hook (`SaftUI-Loot/popup.lua`), a `HIGHLIGHT` texture colored from `st:Color('accent')` (`SaftUI-Bags/containers/bag.lua`), a hardcoded grey `SetColorTexture(0.2, 0.2, 0.2, 1)` on `OnEnter` (`SaftUI-Minimap/micromenu.lua`), a `button:SetAlpha(enabled and 1 or 0.35)` disabled dim (`SaftUI-Loot/rollbar.lua`), an ADD blend in a file that does not use the helpers and a `ColorRGBA('accent')` then `SetVertexColor(r, g, b, 0.4)` (both `SaftUI-Misc/durability.lua`) were all missed; only the ADD blend in a helper file (`SaftUI-Tracker/rows.lua`) failed S3. The spec's anti-goal, that a module that colors a state any other way fails the source scan, holds only for the forms the brief names.

**Why noticed:** the final review of the interaction states plan (Task 11), `.superpowers/sdd/2026-11-15-saftui-interaction-states/final-review.md`, A3.

**Anchors:** `tests/core/states_scan_test.lua` (`Scan`, `ALLOWED`, `UsesHelpers`), `tests/lib/source_lex.lua`.

**What's been considered:** widen S3 to every file but `themeart_data.lua` and `skinning.lua`'s Blizzard branch (ADD appears nowhere else today, so no false positive); pin `CreateTexture(nil, 'HIGHLIGHT')` (six sites) the way S2 pins the setters; flag a color setter (`SetBackdropBorderColor`, `SetColorTexture`, `SetVertexColor`, `SetTextColor`) inside an `OnEnter` or `OnLeave` handler body that does not go through `st:SetState` (a heuristic run found only Danger meanings, Blizzard-branch text and the AND / OR badge, now fixed); flag a `SetAlpha` with a literal under 1 beside `Enable` or `disabled`; list S2's allowed calls by line text, kind and reason, not by a count per file, since removing one call and adding another in the same file passes today and one kind per file mislabels `skinning.lua` (three kinds).

**Shape of work:** one test-only task, small to medium: the widenings above with a fixture line for each and a run over the tree to settle what is real.

**Open questions:** how much the hover-handler heuristic may flag before it needs an allow list.

### 2026-11-16 — A Buttons color saved by an older build after a downgrade stays as an orphan key

**What:** migration step 8 retires Buttons > Normal, Hover, Pushed and Checked, and a profile's `colors.version` only rises. If the owner runs an older build (version 7) after this one, that build can save a Buttons color again into a profile already at version 8; the newer build then never runs step 8 on it, and the key stays in the saved variables as an orphan. It is harmless: nothing iterates `colors.button`, and `st:Color('button', 'hover')` errors only if something calls it, which nothing does.

**Why noticed:** the final review of the interaction states plan (Task 11), A1, probing downgrade then upgrade.

**Anchors:** `SaftUI-Core/Media/colors.lua` (`CO.MIGRATION_STEPS[8]`, `st:MigrateColors`), `tests/core/color_migration_test.lua` (the step 8 cases).

**What's been considered:** leave it (a downgrade is not a supported path); or a later step 9 that retires the four again, which runs once for a profile at 8 and drops what an older build saved, at the cost of one more entry in the list.

**Shape of work:** none unless a downgrade is ever expected; then one step and its case. Small.

**Open questions:** whether downgrades are supported at all.

### 2026-11-16 — The tracker's whole pixels at other scales

**What:** SaftUI's tracker is off whole pixels at 0.75, 1.25 and 1.55: in the test world its window had 30 off edges before the interaction states plan and 32 after at 0.75. The two new ones are the hover Layer's left and right edges, at half pixels, because a row's Layer reaches `L.HOVER_PAD` (2 units) past the row on every side and 2 units is 1.5 pixels at 0.75; the Layer's top was already off vertically. The sides do not show (the rows are exactly as wide as the scroll frame, which clips its child), so the overhang at the sides is never drawn.

**Why noticed:** the interaction states plan's review of the tracker's states (Task 8, L5), with a probe that put a hovered row on the window at each scale. No file in `tests/tracker` or `tests/misc` has a `scaled_test` case, so `tests/run --scales=all` runs nothing scaled there.

**Anchors:** `SaftUI-Tracker/layout.lua` (`HOVER_PAD`), `SaftUI-Tracker/rows.lua` (the row records, `inset = -L.HOVER_PAD`), `SaftUI-Tracker/window.lua`, `SaftUI-Core/Widgets/states.lua` (the Layer's `Place`); the UI scale entries below (phase 4, each addon); `.superpowers/sdd/2026-11-15-saftui-interaction-states/task-8-review.md` (L5).

**What's been considered:** pixel-snapping `HOVER_PAD` (2 units rounded to whole pixels at the frame's scale, as the other sizes are), or padding only vertically, which needs the states helper to take per-side insets.

**Shape of work:** small, with the tracker's phase of the UI scale work: snap the pad, and add `scaled_test` cases that put a hovered row, a selected row and the window on whole pixels at 0.75, 1.25 and 1.55.

**Open questions:** whether the pad stays at 2 units or becomes 2 pixels.

### 2026-11-16 — `optionsOf` keeps every page root alive: the reset walk's options table holds its own key

**What:** `SaftUI-Core/Config/optionsdefault.lua` keeps `optionsOf`, a weak-keyed table from a page's root (the options tree a `/sui` render was built from) to a wrapper `{ type = 'group', args = root }`, so the reset's default lookup walks a row's path without making a table per row. The wrapper's `args` is its own key, and Lua 5.1 does not free a weak-keyed entry whose value refers to its key, so no root is ever freed. `OM.ForgetRoot(root)` lets one go, and `optionsmodel.lua` calls it for a menu's root when the menu's cache is freed, but nothing calls it for a page root. Config:Open builds a new tree each time (`Config:GetOptionsTable`), so every open of `/sui` that asks the reset about a row leaves a whole option tree (every module's config table and its closures) alive for the session.

**Why noticed:** reading `optionsdefault.lua` while folding the interaction states docs (Task 11), after the menu's cache fix (`bf9b4a6a`) found the same pattern for a menu's root. Not measured in game.

**Anchors:** `SaftUI-Core/Config/optionsdefault.lua` (`optionsOf`, `OptionsFor`, `OM.ForgetRoot`), `SaftUI-Core/Config/optionsmodel.lua` (the menu cache that calls `ForgetRoot`), `SaftUI-Core/Config/config.lua` (`Config:Open`, `RegisterOptions`), `SaftUI-Core/Config/optionswindow.lua` (`Open`, `Draw`).

**What's been considered:** calling `OM.ForgetRoot(root)` when the window opens on a new root and when it closes (the old root is the one `pageBody:SetRoot` replaces); or keying the wrapper by a weak proxy so the value no longer holds the key; or building the wrapper only for the walk's duration (a table per walk, not per row).

**Shape of work:** small: one call at `/sui`'s open and close, a case that opens the window twice and counts live roots (`collectgarbage` and a weak sentinel), in `tests/core/options_default_test.lua`.

### 2026-11-16 — The full-UI Accent pass is about 2,500 setters, and the bag slots are 1,400 of them

**What:** one pass of the Accent paints every state frame on screen. Over the full UI (bags and bank open, the action bars, the micro menu, the tracker, `/sui`) Task 5 measured about 2,495 setters a pass against the 2,500 the spec budgets for 2 ms, and with the Accent row's dots menu open about 2,505. The bag slots are 1,400 of it (a hover and a pushed setter on each slot), painted whether or not their window shows. The helper does not skip a hidden host (that needs an `OnShow` repaint on every record, which a `SetScript` would drop), so a closed bank's slots are painted by every pass.

**Why noticed:** the interaction states plan's Bags review and fix round (Task 5, the budget), and Task 10's review of the menu (G11, the owner's in-game `/sui debug` pass time). The in-game number decides whether this is needed: the owner reads each line's slowest pass; over 2 ms is this entry's trigger.

**Anchors:** `SaftUI-Core/Widgets/states.lua` (`PaintRecord`, `Colors`), `SaftUI-Bags/containers/bag.lua` and `slot.lua` (the slots' `'icon'` records), `SaftUI-Core/Media/colors.lua` (`CO.PASS_BUDGET_MS`, `EditStats`), `tests/lib/color_cost.lua`, `tests/bags/live_colors_test.lua` (the slot pass), `.agents/architecture.md` (the states engine's guarantees: "A pass does not skip a hidden frame").

**What's been considered:** painting a window's slots only while it shows: a window's `OnShow` repaints them from the cache (`st:PaintStates` per slot, or one call that walks a container's records), and the pass skips a record whose host is hidden (`IsVisible`), so the helper keeps no `OnShow` hook of its own; the bag windows' own `OnShow` is the place for a container whose frames the module owns. Dropping the pushed texture's paint for a slot until it is pressed (a pushed piece is painted only while pushed) saves half of it.

**Shape of work:** one engine task: a hidden-host skip with a repaint on show, tests for each (a hidden slot costs a pass nothing, shown it is painted at once, a pass while hidden and a show gives the new color), and the bags' windows calling it from their show. Medium.

**Open questions:** none left on the trigger: see the in-game number below.

**In game 2026-11-16:** with every bag and the bank open and the Accent dragged, `/sui debug`'s slowest pass was 5.2 ms (the check's line was 2 ms). The owner could not notice it and said to optimize if there is an opportunity but not to worry much about it. So the trigger is met and the work above is worth doing when the states engine is next open, not urgently.

### 2026-11-16 — The Hue shift setting reads "20", not "20 degrees"

**What:** in the Accent row's dots menu the Hue shift slider and its typed box show a bare number (20), where the mockup shows "20°" (and the Chroma change, a percent, shows "10%"). The description says "in degrees", so it reads, but a unit beside the value is the mockup's and clearer.

**Why noticed:** Task 10's review (the menu) and its fix round: the nit was left because the range widget has no unit suffix.

**Anchors:** `SaftUI-Core/Media/states.lua` (`ST.MenuGroup()`, the `shift` setting), `SaftUI-Core/Config/optionsrange.lua` (the value box, its typed-value parse and `isPercent`), `SaftUI-Core/Config/optionsmodel.lua` (the Ace validation list of an option's fields), `docs/design-system/tokens.json` (`state-shift`).

**What's been considered:** a new option field (`unit = '°'` or `unitText = ' degrees'`) read by the range's value box: shown after the number, stripped when a value is typed, listed with the model's known fields so the options validator accepts it; `isPercent` is the model for it.

**Shape of work:** small: one field in the range widget and the model's validation list, the `shift` setting using it, and tests for the shown text, a typed "30°" and "30", and the search and reset walks. Needs no design call.

**Open questions:** "°" or " degrees" (Colus and Agency may not have the glyph; the options kit avoids glyphs for that reason: say "degrees").

### 2026-11-16 — The keybind field's "Press a key" in the Accent on the selected look is 2.9 to 4.3:1

**What:** a keybinding button waiting for a key is selected (the Accent edge and the fade), and its "Press a key" prompt stays in the Accent, as the spec's mapping (A1) says. Over the fill the Accent text is 4.33:1 at the fade's start at the default Accent and about 5.1 a quarter across; right after the click that starts the wait the mouse is still on the button, and under the hover tint it is 2.87 at the start, 3.4 a quarter across and 4.1 at the middle; with the violet preset 2.1 to 3.6. Before the interaction states plan the prompt was 6.5:1 over the plain body.

**Why noticed:** Task 3's review (the options kit, L1), which called it the owner's call (G-K in the checklist: click a keybinding button and say whether the prompt reads).

**Anchors:** `SaftUI-Core/Config/optionskeybinding.lua` (the waiting state and its text), `SaftUI-Core/Widgets/states.lua` (the text pick, `textKeep`), `tests/core/kit_states_test.lua` (the keybinding case), `docs/superpowers/plans/2026-11-15-saftui-interaction-states-in-game-checklist.md`.

**What's been considered:** keep the prompt in the Accent only at rest and draw it in Text > Strong (white) while the button is selected, or hand the label to the helper (`textKeep`, which already picks the dark text where the light does not read) and give the prompt the Accent only where it passes 4.5:1. Both are one line.

**Shape of work:** small, after the owner has looked at it in game.

**Open questions:** whether it reads well enough in game to leave it.

*Update 2026-11-16:* the text pick (`textKeep` writing the dark text) is gone; a label never flips to dark, so the "dark text where the light does not read" option above no longer exists, and `ST.Contrast` is gone too, so the 4.5:1 option needs it back.

### 2026-11-16 — With the History list open, a Theme recolor restyles its twelve rows

**What:** the edit mode bar's History list has twelve pooled rows, each a state frame (`'row'`), and a Theme recolor restyles each of them while the list is open (`LookList` and `RecolorList`), the same pattern as the movers' fill and fade that Task 4's review (I1) found at 365 layout calls a pass. After the engine's small task (a restyle of an unchanged frame makes no table and moves no piece) it is cheap, but it still does the work: the rows' looks do not change on a Theme recolor, only their kept colors.

**Why noticed:** Task 4's fix round (the movers), carried in the interaction states ledger when the History list was found to do the same.

**Anchors:** `SaftUI-Core/EditMode/Bar/historylist.lua` (`LookList`, `RecolorList`), `tests/core/editmode_states_test.lua` and `tests/core/editmode_colors_test.lua` (the cost cases with the History list open), and the entry "Edit mode: a Theme pass with edit mode on still does the full look and list refresh" below, whose pass this is part of.

**What's been considered:** `RecolorList` painting only the rows' own colors (`st:PaintStates`) and leaving the look to a redraw, as the movers' Theme pass now does.

**Shape of work:** small, with the entry above: measure the pass with the list open first; the cost cases already pin the setters.

**Open questions:** none.

### 2026-11-16 — The `/sui` color picker is laid out in units, not whole pixels, at 0.75 and 1.25

**What:** at 0.75 and 1.25 the color picker as a whole (every preview kind, the text kind that was there before the interaction states plan included) is laid out in units, not whole pixels: its right edge lands at 442.5. It predates the states plan, which added the `states` and `danger` kinds on the same layout.

**Why noticed:** Task 9's review (the previews). No `scaled_test` covers the picker's previews, and Task 10's fix round found the same for a plain Colors row of the options window at 0.75 and 1.25 (119 edges off), so the menu's whole-pixel case stayed a plain `test`.

**Anchors:** `SaftUI-Core/Config/optionscolorpicker.lua`, `SaftUI-Core/Config/optionspreview.lua`, `tests/core/options_color_preview_test.lua`, `tests/core/accent_menu_test.lua` (the menu's layout at the scales); the UI scale entries below (phase 2, the options kit and SaftUI's windows, and "the kit's buttons and labels are off whole pixels on every screen that is not 1440p").

**What's been considered:** nothing separate: it goes with the kit's whole-pixel phase.

**Shape of work:** part of UI scale phase 2: round the picker's placements to the pixel as the kit's, and add `scaled_test` cases for each preview kind (the strip's tiles, the held states, the menu).

### 2026-11-15 — Auto Vendor: stop the unasked sales once the player buys or buys back

**What:** Auto Vendor's unasked sales go on for the whole visit, whatever the player does at the merchant. A stack the player buys back is sold again on the next pass (up to 3 tries a slot) while the visit is within 12 non-gray stacks, which undoes the buyback. A purchase of a caught item (the same item the merchant sells) can be sold again too, asked or not by the count. The question is whether buying or buying back should end the unasked part of the visit (every later stack then asks), and what a bought-back stack should do.

**Why noticed:** The review of the bags package's fix round (2026-11-15, probes P2 and P3), after the GUID fix made a purchase count. The entry about a fresh purchase in a just-sold slot had it as an open question; the promise (every non-gray stack sold unasked is among the last 12 sold) holds without it.

**Anchors:** `SaftUI-Bags/autovendor.lua` (`Account`, `Sell`, `VendorPass`); `tests/bags/autovendor_sale_test.lua`; Blizzard's `BuyMerchantItem` and `BuybackItem`.

**What's been considered:** A post-hook (`hooksecurefunc`, `.agents/taint.md` rule 2) on `BuyMerchantItem` and `BuybackItem` that marks the visit as touched by the player and sends every later non-gray stack to a question. A bought-back stack could also be added to the visit's "do not sell again" list by its GUID (kept or new on the buyback, so by slot and item as well). Neither is needed for the promise.

**Shape of work:** Small: the hooks and a flag on the visit, or the list; tests with a stand-in `BuybackItem`.

**Open questions:** Should buying or buying back end the unasked sales for the visit, or only keep a bought-back stack from being sold again? Which is less surprising at a merchant?

### 2026-11-15 — UI scale phase 2: the options kit and SaftUI's windows

**What:** The second of the scaling work's five phases: the options kit (`SaftUI-Core/Config`) and SaftUI's own windows put on whole pixels at any scale, so a kit control on a 1080p or Mac screen is no longer a fraction of a pixel off. Phase 1 made every line the theme engine draws whole and put the scale under the game's; this makes the controls drawn on top of those lines whole too.

**The one place a friend's screen is worse than before phase 1:** on a screen that is not 1440p, in Automatic, the options kit's own one-unit lines (the three literal `edgeSize = 1` in `optionslook.lua`, the color picker's two) are 0.75 px at 1080p, where before this phase they were a whole pixel at the old scale (every screen was pixel for pixel then). Under the game's snapping a box can lose a side. `/sui scale pixel` restores the old look until this phase lands, so do not put it off for long.

**Why noticed:** The spec's Phasing section (`docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`) cuts it from phase 1, and the phase 1 reviews (Tasks 3, 5, 6 and 7) each found the same thing from the other side: the Keep prompt's buttons and the UI scale section's boxes are the first pages a friend sees, and they are off whole pixels on every screen but 1440p. The existing entry [the kit's buttons and labels](#2026-11-15--ui-scale-the-kits-buttons-and-labels-are-off-whole-pixels-on-every-screen-that-is-not-1440p) is this phase's first symptom.

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` ("Phasing", "The audit" A4, A5, A6, A9, A12), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md` (the notes on what phase 1 leaves), `SaftUI-Core/Config/optionslook.lua` (`Box`, `LINE`), `optionscontrols.lua` (`W.Button`, `Layout`), `optionsbody.lua` (hairlines, dividers), `optionscolorpicker.lua` (the rings), `optionswidgets.lua` (lists and menus, `LIST_STRATA`), `SaftUI-Core/EditMode/Bar/`, `tests/lib/pixels.lua` (`P.off`), `tests/core/general_tab_test.lua` (the section's whole-pixel case, the model for the others).

**What's been considered:** E5 and E5b (the owner, 2026-11-15) showed a line a whole number of pixels wide is drawn whole at a fractional scale wherever it sits once its textures are unsnapped, and that the game's layout rounding is a nicety, not a need. So the kit needs its one-unit lines to be `st:GetLineSize(frame)` and its sizes and offsets to go through `st:RoundToPixel`, and probably not `SetRoundLayoutToNearestPixel` over the whole window. The spec's list: the kit's boxes (`Box`, `LookLine`), the color picker's rings, every hairline and divider, the one-unit offsets, the kit's pure layouts on the grid, icons in even pixels (the Lucide files stay 32 pixels), lists and menus with their own scale. Also named for this phase: `OW.MaxHeight` should win over the window's least height when the screen is shorter (the body scrolls), for The game's UI scale at 1.15 on a short screen (668 units); `TitleHeight`'s unrounded readers in `panels.lua`; `OW.MaxWidth` and the margin's reach on `/sui`. Nothing the friends have reported yet: E0, E1 and E6 are not run (see the entries for them).

**Shape of work:** One plan, after the friends have looked at phase 1. A pass over `optionslook.lua`, `optionscontrols.lua`, `optionsbody.lua`, the dialogs and `EditMode/Bar/` with `scaled_test` cases that run `P.off` over the open window at 0.75, 1.25 and 1.55, and the scan in `theme_kinds_test.lua` extended to `SetHeight(1)` and `SetWidth(1)` in the finished areas (the spec's test 3).

**Open questions:** Whether text height is rounded to pixels too, or left to the game; whether the layout rounding is worth adding after all if a friend's screen shows a gap.

### 2026-11-15 — UI scale phase 3: edit mode

**What:** The third phase of the scaling work: edit mode's grid lines and snap guides at one line, snapping's border rule with `line`, the outline, the Position editor's boxes showing one decimal at most, and the picker's list. Arrow-key nudges stay one pixel, Shift ten.

**Why noticed:** The spec's Phasing section (`docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`, "Phase 3: edit mode"; audit A7). Phase 1 moved edit mode's bar, floating window, grid and Coordinates label onto the scale change's callback and made placement round to whole pixels, but left the grid's and the guides' own one-unit lines, and two gaps its reviews named (the entries for [the docked bar](#2026-11-15--ui-scale-the-docked-edit-mode-bar-is-off-whole-pixels-away-from-k--1) and the Coordinates label below).

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` ("Phasing", A7), `SaftUI-Core/EditMode/grid.lua` (`EM.GridLinePositions`, `EM:GetGridCenter`), `snap.lua` (`EM.SNAP_REACH`, the outline's border rule), `coordinates.lua` (`EM.CoordinatesText`, which prints the stored position, in stored units), `picker.lua`, `Bar/`, `.agents/edit-mode.md`, `tests/core/editmode_*`.

**What's been considered:** The Coordinates label shows stored units, so at a scale other than 1 a frame dragged to "120" shows 120 while it sits on a position that is a whole number of pixels and not 120 of them. Showing pixels instead changes a number the owner reads; showing units rounded keeps it. Not decided.

**Shape of work:** One plan after phase 2 (the bar's controls are the kit's). The grid and guides to `st.line`, the snap rule onto it, the Position editor's boxes to one decimal, the Coordinates label decided, with the edit mode tests under the scale parameter.

**Open questions:** What the Coordinates label should say at a scale other than 1 (stored units, or pixels).

### 2026-11-15 — UI scale phase 4: each addon, 4a to 4g

**What:** The fourth phase of the scaling work, one plan per addon, in the order the friends look at them (the spec's call 26): 4a unit frames and nameplates (the plates' even pixels, the auras' inner line), 4b action bars and their extras (onto `st:EvenPixels`), 4c bags (the Categories tab's and rule editor's lines, the loading overlay), 4d Misc (experience bars, tooltip, totem bar, durability) and the skins (the buff frame's `+ 1`, the objective tracker's line), 4e loot (the timer lines, the feed's progress line), 4f minimap and micro menu, 4g chat and SaftUI's tracker. Each: its one-unit lines to one line (`st:GetLineSize`), its sizes and offsets that meet a border onto the grid, its centred frames even, and its layout tests under the scale parameter. The spec's scan (`tests/core/theme_kinds_test.lua`) bans a literal `edgeSize = 1` outside an allow-list that shrinks as each plan lands, and from phase 2 `SetHeight(1)` and `SetWidth(1)` in finished areas.

**Why noticed:** The spec's Phasing section (`docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`) and the audit; the phase 1 plan (`docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md`) lists what each addon still has. Until each lands, that addon's one-unit lines are `1` unit (a fraction of a pixel away from 1440p) wherever the theme engine doesn't draw them.

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` ("Phasing", "The audit"), the entries for the leftovers that belong here: [a nameplate's inner parts](#2026-11-15--ui-scale-a-nameplates-inner-parts-are-not-yet-even-in-pixels), [EvenIfCentred](#2026-11-15--ui-scale-evenifcentred-and-stevenpixels-disagree-for-negative-counts), [the bags' loading overlay](#2026-11-15--ui-scale-the-bags-loading-overlay-holds-stbackdrop-and-needs-setbackdropnil-to-take-a-new-line) and [the parentless frame and the two `st:ThemeInset` readers](#2026-11-15--ui-scale-a-frame-drawn-parentless-and-parented-later-into-a-frame-with-a-scale-of-its-own-keeps-uiparents-line) (`SaftUI-Misc/totemskin.lua`, `SaftUI-Bags/categoriestab.lua`).

**What's been considered:** E5's outcome sizes this: a whole-width line is whole wherever it sits, so an addon's work is the widths and the grid-meeting offsets, not the game's layout rounding. Nothing the friends have reported yet. The scaling followup ("Scale SaftUI across resolutions and stay pixel perfect") stays Active until 4g ends.

**Shape of work:** Seven plans (4a to 4g), each a small audit-and-convert like phase 1's Task 3 on one addon, each with its in-game check at the friends' scales. 4a first: the plates are what a friend sees most.

**Open questions:** Whether the order should change once a friend says which addon looks worst.

### 2026-11-15 — UI scale phase 5: crispness on dense screens

**What:** The fifth phase of the scaling work, done only if the in-game checks ask for it: a rule for Homespun at the Mac's scale (from E6 and the Mac friend's G3), a second size of the Lucide icons (they are 32 pixel files drawn at even whole pixels, so at 1.55 they scale up softly), and anything else the Mac friend reports.

**Why noticed:** The spec's Phasing section (`docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`, "Phase 5"; calls 8 and 22). Phase 1 takes the spec's default font call, fonts follow the scale unrounded, and awaits E6; the friends' checks of both are not in.

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` ("Fonts", "Icons, textures and Blizzard's art", calls 8 and 22), `SaftUI-Core/Media/fonts.lua`, `tools/lucide-to-tga.cjs`, [E6 and deleting the font demo](#2026-11-15--ui-scale-e6-and-deleting-the-font-demo), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md`.

**What's been considered:** If Homespun is rough at 15.5 (10 at 1.55), a rule rounds its size to whole pixels or to a multiple it was drawn for. If the Lucide icons are soft, a 64 pixel set drawn at the scale's nearest size. If neither is, this phase is closed unwritten.

**Shape of work:** Decided by the Mac friend's answer: a rule in `Media/fonts.lua`, and `tools/lucide-to-tga.cjs` run for a second size with `st.icons` choosing by k; or nothing.

**Open questions:** All of it, until E6 and G3 are in.

### 2026-11-15 — UI scale: the docked edit mode bar is off whole pixels away from k = 1

**What:** The docked edit mode bar is centred in units by `floor`, so away from k = 1 its left edge is a fraction of a pixel off the grid (756.75 pixels at 0.75, 1307.82 on the Mac's screen in the probe). Its border is whole (the theme engine unsnaps it), but its contents may not be.

**Why noticed:** The Task 5 review (`sc-task5`, n2) of the scale's placement work, from a probe at 0.75 and on the Mac's screen. Cut from phase 1 by the spec: it is edit mode's ground.

**Anchors:** `SaftUI-Core/EditMode/Bar/` (the docked bar's placement and `EM.BarLayout`), `.agents/edit-mode.md`, `tests/core/editmode_bar_test.lua`.

**Shape of work:** Phase 3 (see [UI scale phase 3: edit mode](#2026-11-15--ui-scale-phase-3-edit-mode)): place the bar through `st:RoundToPixel` with an even width, and a `scaled_test` that runs `P.off` over the open bar.

**Open questions:** None.

### 2026-11-15 — UI scale: a nameplate's inner parts are not yet even in pixels

**What:** Phase 1 makes a plate's driver size a whole, even number of pixels, so a plate's centred parts land on whole pixels at the owner's scale and at every other. The parts inside a plate (the name and health texts, the castbar and its icon, the auras' rows, the threat text and the raid mark) still take sizes and offsets from their configs in units, so away from k = 1 an odd one is a fraction of a pixel off.

**Why noticed:** The Task 5 review (`sc-task5`), which listed it with the leftovers that already had owners.

**Anchors:** `SaftUI-Unitframes/nameplates/pixels.lua` (`UF.PlateDriverSize`, `UF.RoundLayout`), `SaftUI-Unitframes/elements/auras.lua`, `SaftUI-Unitframes/config/units/nameplate.lua`, `tests/unitframes/nameplate_pixel_test.lua`.

**Shape of work:** Phase 4a ([UI scale phase 4](#2026-11-15--ui-scale-phase-4-each-addon-4a-to-4g)): each inner part's size and offset through `st:RoundToPixel`, centred ones even, with the plate's in-game check at the friends' scales.

**Open questions:** None.

### 2026-11-15 — UI scale: EvenIfCentred and st:EvenPixels disagree for negative counts

**What:** `EvenIfCentred` in `SaftUI-ActionBars/bars.lua` and `st:EvenPixels` in `SaftUI-Core/api.lua` both make a centred frame an even number of pixels long, but an odd negative count goes toward zero in the first and away from it in the second (-45 pixels gives -44 and -46). Phase 4b moves the action bars, and the totem bar's `EvenPixels`, onto `st:EvenPixels`, and that move changes a result for a negative input.

**Why noticed:** Phase 1 Task 1's review (`sc-task1`, n4 and r4): `st:EvenPixels` rounds away from zero on purpose, and a comment at it says the two must not be assumed to agree. Negative lengths are rare (an offset, not a size), so no current setting is known to hit it.

**Anchors:** `SaftUI-Core/api.lua` (`st:EvenPixels`, the comment on negative counts), `SaftUI-ActionBars/bars.lua` (`EvenIfCentred`, `AB:PlaceFrame`), `SaftUI-Misc/totemlayout.lua` (`EvenPixels`), `.agents/architecture.md` ("Half pixels from centred anchors").

**Shape of work:** Phase 4b ([UI scale phase 4](#2026-11-15--ui-scale-phase-4-each-addon-4a-to-4g)): move both onto `st:EvenPixels` with a case for a negative odd count, or pick which direction is right for an offset first.

**Open questions:** Which direction a negative odd count should go.

### 2026-11-15 — UI scale: the Blizzard theme's art is not on whole pixels in a scaled frame

**What:** Under the Blizzard theme the atlas corners and edges, the ring and slot art, and the like scale with k as Blizzard's own UI does, and are not placed on whole pixels in a frame that carries a scale. The plan's Ruling 11 allows it: only the lines SaftUI draws itself are whole.

**Why noticed:** Phase 1's design (call 21: "the Blizzard theme's art scales with k like Blizzard's own UI, its offsets rounded, with no line weight") and the Task 3 review (`sc-task3`). Whether it looks wrong is the owner's eye, not a measurement.

**Anchors:** `SaftUI-Core/themeart.lua` and `themeart_data.lua` (`ThemeArt.WholeInset`, `WholeTop`, `LayBorder`), `.agents/architecture.md` ("Borders are whole pixels"), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md` (Ruling 11).

**What's been considered:** Setting `SetSnapToPixelGrid(false)` on the art as for the lines (it would only unsnap, not make the art whole); drawing the art at a whole multiple of its own size, which is not what an atlas is for.

**Shape of work:** Look at it at 0.75, 1.25 and 1.55 under Blizzard (the checklist asks); only if a friend or the owner finds a seam, a pass over `ThemeArt` placing each piece on whole pixels.

**Open questions:** Whether it looks wrong at all.

### 2026-11-15 — UI scale: E4, SetScale in combat, still to run

**What:** Experiment E4: is `UIParent:SetScale` refused in combat? It is inferred to be (`SetScale` is a protected function and UIParent is protected in combat, since protection spreads to a secure frame's parents), so SaftUI builds as if it were: a scale change in combat waits for the end of the fight (`.agents/taint.md`, rule 6; `.agents/clients.md`, F8, "inferred"). E4 was not run.

**Why noticed:** The scaling design's experiments; the owner ran E1 to E3, E5 and E5b on 2026-11-15 and said to go on without E4.

**Anchors:** `.agents/clients.md` ("Screen and UI scale", F8), `.agents/taint.md` rule 6, `SaftUI-Core/uiscale.lua` (`UIScale:Check`, `st:QueueAfterCombat('UIScale', ...)`), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md` (the check, first).

**What's been considered:** What each outcome changes: nothing unsafe either way. If `SetScale` in combat is blocked (an "Interface action failed" or `ADDON_ACTION_BLOCKED`, UIParent's scale unchanged), F8 is confirmed and the docs drop "inferred". If it is allowed, the wait could in principle go, but the pass still cannot run in combat (it moves protected frames), so the scale would change in a fight with SaftUI's frames at the old line until the end of it: the wait stays and only the docs change.

**Shape of work:** The owner's two commands in a fight on a dummy (the checklist has them), then update F8 and rule 6 from "inferred" to "confirmed" with the result.

**Open questions:** The result, on Forever and, if possible, on retail.

### 2026-11-15 — UI scale: E0, the friends' check of the default UI size and its range

**What:** Experiment E0: each friend looks at SaftUI's automatic size on their own screen and says whether 100% is right and whether 70% to 150% is the right range. It was not run: the owner said to finish phase 1 without it ("if it's just fine tuning that would change we can get feedback from him later"), so the spec's defaults ship: Automatic at 100%, a UI size of 70% to 150% in 5% steps.

**Why noticed:** The phase 1 plan placed E0 before Task 7; the owner's ruling (the plan's ledger, 2026-11-15) shipped Task 7 without it.

**Anchors:** `SaftUI-Core/uiscale.lua` (`UIScale.DEFAULT`, `UIScale.SIZE` with its `min`, `max` and `step`), `SaftUI-Core/Config/general.lua` (the UI size row), `.agents/clients.md`, `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` ("The default and the choice", call 4), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md`.

**What's been considered:** The change is one line if a friend wants another default or range: `UIScale.DEFAULT.size` (1) for the default and `UIScale.SIZE` for the range, with the tests that pin 70% and 150% (`tests/core/uiscale_test.lua`, `general_tab_test.lua`) and the row's description. A default other than 100% makes every screen a size other than the design's, so it would change the owner's own screen only if the owner moved it too.

**Shape of work:** Ask each friend (the checklist's questions); retune if they say so.

**Open questions:** The friends' answers.

### 2026-11-15 — UI scale: E6 and deleting the font demo

**What:** Experiment E6: the Mac friend looks at Homespun at the Mac's scale in the font demo (`/suifonts`) and says whether it is crisp. Not run: phase 1 takes the spec's default (fonts follow the scale, unrounded) and leaves the font demo in place so the Mac friend can still run E6. Once E6 is in, delete the demo, and if Homespun is rough at 1.55 open phase 5's font rule ([UI scale phase 5](#2026-11-15--ui-scale-phase-5-crispness-on-dense-screens)). Homespun stays either way (design-system decision 41).

**Why noticed:** The phase 1 plan's Task 8 deleted the demo; the owner's ruling (2026-11-15) kept it for E6.

**Anchors:** `SaftUI-Core/Dev/fontdemo.lua` (its header lists what goes), `docs/design-system/05-decisions.md` (decisions 41 and 59), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md`.

**Shape of work:** Small, once E6 is in. By the demo's own five steps (its header): (1) delete `SaftUI-Core/Dev/fontdemo.lua`, `SaftUI-Core/Dev/load.xml` and the `Dev` folder; (2) the `Dev\load.xml` line in `SaftUI-Core/SaftUI-Core_Forever.toc` and `SaftUI-Core_Mainline.toc`; (3) the folder `SaftUI-Core/Media/Fonts/Candidates/` (every candidate and its `OFL.txt`; none is kept, Homespun stays); (4) the LibSharedMedia registrations (the loop over `CANDIDATES` in `fontdemo.lua`, which go with step 1; Global settings > Fonts then lists no "Candidate:" faces); (5) `tests/core/fontdemo_test.lua`, the demo's sentence in `AGENTS.md`'s Core row, the `/suifonts` line in `README.md`, the mention in `.agents/testing.md`, the demo's exception in `tests/core/setfont_scan_test.lua` (line 31) and its entry in the allow-list of `tests/core/theme_kinds_test.lua` (line 371). Then run `tests/run`, `tests/run --scales=all` and `tests/run --self-check`; `git grep -n -e "Candidate: " -e "fontdemo" -e "suifonts" -- 'SaftUI-*' tests/ AGENTS.md README.md` and `git grep -n "Dev" -- 'SaftUI-Core/*.toc'` print nothing (the tracker's own `Candidates` don't match).

**Open questions:** The Mac friend's answer.

### 2026-11-15 — UI scale: E1 on the friends' screens

**What:** Experiment E1 (what the game reports: `GetPhysicalScreenSize()`, the default scale, render scale, the scales read back) was run on the owner's 2560 x 1440 screen only. The two friends' screens (1080p and the Mac's 3456 x 2234) are not run: F2 (the physical size on a Retina display is device pixels) and F4 (render scale does not change it) stay inferred, and nothing says yet whether either screen has an odd notch in Automatic's size (a size whose line weight or pixel jumps where a friend's window or resolution puts it).

**Why noticed:** The phase 1 plan's experiments and the owner's results (`experiments-results.md`, E1).

**Anchors:** `.agents/clients.md` (F2, F4, F5), `SaftUI-Core/uiscale.lua` (`UIScale.ReadScreen`, `Resolve`, the snap band), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md` (the command to ask each friend to run).

**What's been considered:** If a friend's E1 shows an odd notch (a size that falls between lines, or a physical size that is not what Automatic assumed), the fix is half pixels from it: a snap or a line weight chosen from that reading, in `Resolve`.

**Shape of work:** Each friend runs the command and pastes the line; update F2 and F4 from "inferred" to "confirmed", or open the half pixel work.

**Open questions:** The friends' lines.

### 2026-11-15 — UI scale: the owner's standing calls

**What:** Two calls the owner made while phase 1 was built, kept here so a later reader does not reopen them by accident. (1) One-pixel lines stay one pixel on frames Blizzard scales (the Cooldown Manager and buffs at an Edit Mode Icon size other than 100%, the swing timers at a Scale other than 100%): their lines are now exact, where they used to be as thick as the frame's scale made them; the alternative, weighting a line by the frame's own scale, needs a spec ruling and the owner declined it (2026-11-15). (2) An odd nameplate Width or Height is one pixel larger at the owner's scale (201 by 21 becomes 202 by 22), because a plate is a whole, even number of pixels so its centred parts land on whole pixels; the default 200 by 20 is unchanged. The owner was told; no objection is recorded.

**Why noticed:** The phase 1 ledger (the Task 3 and Task 5 reviews).

**Anchors:** `SaftUI-Core/theme.lua` (`st:GetLineSize`, `st:DrawingFrame`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF.PlateDriverSize`), `docs/design-system/05-decisions.md` (decisions 58 and 61), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md`.

**Shape of work:** None unless the owner changes a call. The checklist asks the owner to look at both once.

### 2026-11-15 — UI scale: the Keep prompt's line weight at 150% and the Esc order

**What:** Two small open points on the Keep prompt, both only visible in the game. (1) A 150% preview on a 1440p screen gives the prompt 2 pixel lines (Thick 6), since a line is `st.lineWeight` pixels of UIParent's scale and the prompt ignores its parent's scale only for size: whole, but the weight jumps at the preview. The owner's line-weight call (one pixel lines stay on frames the game scales) stands, so this is a note, not a bug. (2) With `/sui` and the prompt both up, Esc should go back and leave `/sui` open, and a second Esc closes `/sui`. That order is inferred from WoW's top-down keyboard order and no test can show it; if the game gives `/sui`'s catcher the key first, one Esc closes `/sui` and leaves the prompt, which still goes back at 0, so nothing keeps by accident.

**Why noticed:** The Task 6 review (`sc-task6`, concern 1 and m2) and the Task 7 review.

**Anchors:** `SaftUI-Core/Config/uiscaleprompt.lua` (`Build`'s `OnKeyDown`, `Fit`), `docs/design-system/components/KeepPrompt/README.md` ("Known gaps"), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1-in-game-checklist.md` (the Esc check).

**Shape of work:** The owner's check settles (2); if one Esc closes `/sui` first, raise the prompt's catcher or have `/sui`'s Esc handler skip while the prompt shows. Close this entry on the owner's word.

**Open questions:** The Esc order, in the game.

### 2026-11-15 — The options kit's keybinding widget commits mouse buttons 6 to 31 raw

**What:** The `keybinding` widget (`SaftUI-Core/Config/optionskeybinding.lua`) converts only `MiddleButton`, `Button4` and `Button5` (its `MOUSE_BUTTONS` table). Mouse buttons 6 to 31 reach `Press` as `Button6` and so on and are committed raw, where the game's binding names are `BUTTON6`. `/sui kb` converts every button with `GetConvertedKeyOrButton` (`SaftUI-ActionBars/keybindmode.lua`).

**Why noticed:** Review of the small-followups package (2026-11-15), reading the widget's new use of Blizzard's binding helpers. The gap is older than that change; it is rare (a mouse with more than five buttons).

**Anchors:** `SaftUI-Core/Config/optionskeybinding.lua` (`MOUSE_BUTTONS`, the `OnMouseDown` script), `SaftUI-ActionBars/keybindmode.lua` (`BindingKey`), `Blizzard_SharedXML/BindingUtil.lua` (`GetConvertedKeyOrButton`, the same on both clients), `tests/core/options_fields_test.lua`.

**Shape of work:** small: in `OnMouseDown`, convert through `GetConvertedKeyOrButton` where the client has it, keeping `MOUSE_BUTTONS` as the fallback; a test that `Button6` commits `BUTTON6`.

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

**Fixed in code 2026-11-15, awaiting an in-game roll:** the cause was that a plain click's roll is cancelled inside `RollOnLoot`, so Blizzard's bar hid before the post-hook noted the choice and nothing was held (the owner's debug lines from before the fix: `bar hid: ... choice noted false frame hidden true`, then `choice not noted: ... no shown bar with that roll`). Fixed on `fb-rollhold` (merged 2026-11-15, 357f415f, 5b9411c5): each roll button's `PreClick` notes the click as pending (roll, type, time left) before `RollOnLoot`, the bar's hide holds the roll with it, and the post-hook still notes a choice that leaves the bar up (a confirmation, a Need's dice). `tests/loot/roll_held_test.lua`'s `RollOnLoot` stub answers inside the call as the game does. Not yet seen in game. A real roll with `/sui debug` on should print, in order: `choice pending: <id> <type> seconds left <n>`, `bar hid: <id> choice noted false pending true ...`, `held roll <id> choice <type> ...`, `choice held at the bar hiding: <id> <type>`. Close this entry once the held bar has been seen in game with others still rolling. See also [Loot rolls: confirm the client assumptions in game](#2026-11-08--loot-rolls-confirm-the-client-assumptions-in-game). An addon's direct `RollOnLoot` is its own entry.

### 2026-11-15 — UI scale: the kit's buttons and labels are off whole pixels on every screen that is not 1440p

**What:** The kit's buttons, text boxes, hairlines and labels (`W.Button`, `Box`, the dialogs' text) are sized in whole UIParent units, so on any screen where a unit is not a whole number of pixels (1080p at 0.75, the Mac at 1.55, any window) their edges and text fall between pixels. Only their borders are whole (Task 3's unsnapping). The Keep prompt is the visible case: it draws at the automatic size of every screen but 1440p, not only while previewing, so on 1080p its buttons are 19.5 pixels tall.

**Why noticed:** The Task 6 review of the Keep prompt (`sc-task6`, `454d3fcf`): the prompt's own frame is whole pixels (placed and sized by `st:RoundToPixel`), its `W.Button`s are not. The plan names this as phases 2 to 4 ("the options kit's boxes, hairlines and dividers (the Keep prompt's buttons among them)"). The UI scale section (Global settings > General, Task 7) is the first page a friend sees it on: its Scale box, UI size box and the reset icons are kit boxes, so ask each friend to look at them for blur (the checklist does). The phase entry is [UI scale phase 2](#2026-11-15--ui-scale-phase-2-the-options-kit-and-saftuis-windows).

**Anchors:** `SaftUI-Core/Config/optionscontrols.lua` (`W.Button`, `Layout`), `optionslook.lua` (`Box`, `LINE`), `optionsdialog.lua`, `SaftUI-Core/Config/uiscaleprompt.lua` (`Fit`), `docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md` ("What an existing install sees at upgrade"), `docs/design-system/components/KeepPrompt/README.md`.

**What's been considered:** building the prompt's two buttons with pixel-rounded sizes of its own: refused, because the owner asked for the kit's button as it is. The fix belongs to the kit (sizes in pixels through `st:RoundToPixel`, the 1 px `edgeSize` in `Box` as `st:GetLineSize`), which then fixes every dialog and window at once.

**Shape of work:** the later scaling phase for the options kit: one pass over `optionscontrols.lua`, `optionslook.lua` and the dialogs, with `scaled_test` cases that run `P.off` over the open window at 0.75, 1.25 and 1.55.

**Open questions:** whether text height is rounded to pixels too, or left to the game.

### 2026-11-15 — UI scale: a kit confirm dialog or an open select list can cover the Keep prompt

**What:** The kit's confirm dialog and open select lists are in `TOOLTIP` strata with a full-screen click catcher, so while one is open it covers the Keep prompt (level 9900, `FULLSCREEN_DIALOG`): the prompt can't be clicked and doesn't get Esc, though its countdown still goes back at 0.

**Why noticed:** The Task 6 review (`sc-task6`, `454d3fcf`), concern 3: acceptable today, because both are modal answers the user opened and the prompt reverts on its own.

**Anchors:** `SaftUI-Core/Config/optionswidgets.lua` (`LIST_STRATA = 'TOOLTIP'`), `optionsdialog.lua` (`BuildDialog`), `SaftUI-Core/Config/uiscaleprompt.lua` (`KP.LEVEL`), `docs/design-system/components/KeepPrompt/README.md`.

**What's been considered:** moving the prompt to `TOOLTIP` strata above them: it would then sit over the game's tooltip and the lists' catchers, and edit mode's picker list. Closing an open list or confirm when the prompt shows (`W.CancelConfirm`, the list's close): simple, and what the answer to a change should do.

**Shape of work:** small: `KP:Ask` closes the kit's open dialog and list first, with a test; or leave as is.

**Open questions:** whether to close them at all, since a Task 7 row's own select list is what asked and closes on its pick.

### 2026-11-15 — An addon's direct RollOnLoot on a roll with no confirmation is not held

**What:** A held roll (`SaftUI-Loot/rollinfo.lua`) is held at the bar's hide from the choice a roll button's `PreClick` noted. A call to `RollOnLoot` with no click on a Blizzard roll button (another addon's) has no PreClick, and on a roll with no confirmation the client cancels the roll inside the call, so the bar hides with no choice known and is not held. Only the post-hook's own case (a confirmation, a Need's animation: the bar stays up) works for such a call. (The gamepad UI is not a case: with it on, on Forever, Blizzard's own cards show the rolls and SaftUI's frames never show one.)

**Why noticed:** Fixing "loot roll didn't stay open" (the owner's debug lines were `bar hid: ... choice noted false frame hidden true`, then `choice not noted: ... no shown bar with that roll`): the cause was that a plain click's roll is cancelled inside `RollOnLoot`, before the post-hook runs. The fix covers a button click through PreClick; this is the part it leaves.

**Anchors:** `SaftUI-Loot/rollinfo.lua` (`OnBarHide`, `OnRollPreClick`, `OnRollChosen`), `SaftUI-Loot/roll.lua` (`LT:HoldRoll`, `LT:LayoutRollFrames`), `tests/loot/roll_held_test.lua` (the `RollOnLoot` stub), `.agents/taint.md` rule 19.

**What's been considered:** keeping a snapshot at hide time (the bar's state, a copy of `skin.shown` and the frame's stack slot) for the rest of the call, for the post-hook to hold from. It needs `LT:HoldRoll` to take a saved `shown` and a saved stack position: the frame can show a waiting roll right after the hide (overwriting `skin.shown`), and `LT:LayoutRollFrames` drops the frame's stack entry on the container update, so a hold done from the post-hook has to restore both. That is a larger change to roll.lua than the button case needed. Wrapping or replacing `RollOnLoot` is out (`.agents/taint.md` rule 9 and 2).

**Shape of work:** one small ticket: snapshot at `OnBarHide` when no choice is known (the bar's state, `skin.shown`, stack index, the timer read at hide), keep it until the post-hook of that roll or the next frame, hold from it if the post-hook names that roll. The time left could not be read before the call, so it comes from the timer at hide (the Need animation case does not reach this path).

**Open questions:** whether addons that roll for you (auto-roll addons) are common enough among the owner's setups to matter; a plain call cancelling inside is inferred from the debug order, not read from C code: confirm with the next real roll's debug lines first.

### 2026-11-15 — The color picker's preview copies other widgets' geometry

**What:** `SaftUI-Core/Config/optionspreview.lua`'s `bar` and `border` kinds draw tiles by copying other addons' defaults, since Core cannot read them (the `accent` kind that copied the kit's widgets' geometry is gone: the `states` kind that replaced it uses the kit's own buttons, held in each state by `st:SetState`) (Unitframes, Misc and Loot load after it): the role corner's size 16 and offset 2 (`SaftUI-Unitframes/config/default.lua`'s `grouproleindicator`), the class power points' spacing 7 (`config/units/player.lua`'s `classpower`), the nameplate's 200 by 20 and the threat text's 6 above the bar (`config/units/nameplate.lua`), the experience bar's height 13 (`SaftUI-Misc/config.lua`), the loot feed entry's height 32 (`SaftUI-Loot/config.lua`'s `item_height`), the icon texture stand-in and the unit frame bar's, raid frame's and tooltip's sizes (200 by 28, 80 by 40, 74 by 44, the spec's). The bars are the experience bar's kind (`bar`), not a unit frame's `unitframe` box with Blizzard's tinted fill art (`UF.BlizzardFill`), which Core cannot call.

**Why noticed:** Task 10 of the live colors plan (review M3). The copies drift from the real defaults unless they are changed with them. (The interaction states plan, 2026-11-15, replaced the `accent` kind, which copied the range's, the sidebar row's, the own mark's and the grid's geometry, with the `states` kind: that half of this entry is closed.)

**Anchors:** `SaftUI-Core/Config/optionspreview.lua` (the `bar` and `border` kinds); the UI scaling plan (`sc-task3`).

**Shape of work:** small: read the defaults where Core can, or export a size from each addon that the preview calls.

### 2026-11-15 — UI scale: a frame drawn parentless and parented later into a frame with a scale of its own keeps UIParent's line

**What:** `st:DrawingFrame` measures a frame that hangs under no parent (a pooled widget) or under WorldFrame (a plate's frame) in UIParent's pixel. One drawn parentless and then parented into a frame with a scale of its own (0.8, say) keeps UIParent's line until the next theme pass, then takes the frame's. The engine can't know the parent changed without hooking `SetParent` on frames it does not own.

**Why noticed:** review of UI scaling phase 1, Task 3 (m4). The pooled widgets of `/sui` (`options_states_test`) need the rule; the plates are pinned to UIParent's scale, so it is right for them.

**Anchors:** `SaftUI-Core/theme.lua` (`st:DrawingFrame`), `.agents/architecture.md` (Borders are whole pixels), `tests/core/theme_scale_test.lua`.

**What's been considered:** a `hooksecurefunc(frame, 'SetParent')` on every drawn frame (cost on every drawn frame, and rule 1 for frames not SaftUI's); a redraw from the pool's acquire. Neither is cheap. Draw after parenting is the rule for now.

**Shape of work:** small: the pool's acquire (`SaftUI-Core/Config/optionswidgets` family) redraws its frame once parented, if a case shows a wrong line. Also named here: the other `st:ThemeInset` readers inside frames that may carry a scale of their own (`SaftUI-Misc/totemskin.lua:275`, `SaftUI-Bags/categoriestab.lua:1507`), which should pass the frame as the Cooldown Manager's, the buffs' and `optionstypes.lua`'s now do.

### 2026-11-15 — UI scale: the bags' loading overlay holds st.BACKDROP and needs SetBackdrop(nil) to take a new line

**What:** `SaftUI-Bags/container.lua` sets `st.BACKDROP` on the loading overlay. `UIScale:SetTokens` changes that table in place, and Blizzard's `SetBackdrop` returns at once on the table a frame already holds, so the overlay keeps its old line after a scale change until `SetBackdrop(nil)` and then `SetBackdrop(st.BACKDROP)`.

**Why noticed:** review of UI scaling phase 1, Task 3 (n4), after the close button's same trap (fixed with a new table). Ruling 12 of the plan says the frame takes the table again; it must clear first.

**Anchors:** `SaftUI-Bags/container.lua:81`, `SaftUI-Core/uiscale.lua` (`SetTokens`), plan phase 4c.

**Shape of work:** small: clear and set again in the bags' pass after a scale change (phase 4c).


### 2026-11-15 — `/sui` following during a color drag

**What:** While the color picker is open, every SaftUI frame follows the color as it is dragged except the `/sui` window itself, which redraws once when the picker closes (Okay or Cancel). Making the window follow during the drag is a larger change across the options kit.

**Why noticed:** The live colors design's Question 2 for the owner (`docs/superpowers/specs/2026-11-15-saftui-live-colors-design.md`, "What stays as it is, and why" and "Questions for the owner"): is `/sui` following when the picker closes all right? The plan built "at close" and the owner has not said otherwise. The reason it waits: a redraw while the picker is open releases the field the picker writes through, and repainting in place means touching the widget files of the options kit, which other branches were editing and the reset-on-every-setting design was reworking. The kit's field font does follow at once (its font objects), and Part B's preview (Tasks 9 to 11 of the plan) shows the text roles and the Accent on SaftUI's panels and controls meanwhile.

**Anchors:** `docs/superpowers/specs/2026-11-15-saftui-live-colors-design.md` ("What stays as it is, and why", Question 2); `docs/superpowers/plans/2026-11-15-saftui-live-colors.md`; `SaftUI-Core/Config/optionscolorpicker.lua` (the edit's begin and end); `SaftUI-Core/Config/config.lua` (`Config:OnColorsChanged`, the redraw at close); the kit: `SaftUI-Core/Config/optionswidgets.lua`, `optionsbody.lua`, `optionstypes.lua`, `optionsmodel.lua` and the rows' own files; `tests/core/color_live_test.lua`.

**What's been considered:** Repaint in place: every kit widget registers a follower for the colors it draws (`st:FollowColor`), as Core's buttons and check boxes already do, instead of the window being rebuilt. The branches in flight when this was written were the resets plan's last task (the options kit and `tests/lib/harness.lua`) and the UI scaling design (`optionsresize.lua`, `panels.lua`); the change is best made after they land.

**Shape of work:** a design pass over the kit (which widgets draw a Colors-page color and where), then one ticket per widget family; each with a cost case (`tests/lib/color_cost.lua`).

**Open questions:** Whether the owner wants it at all once the preview shows the text roles and the Accent beside the picker; whether the window should follow only for the color being dragged, or for every Colors page group.

### 2026-11-15 — The Theme tab's color drag recolors every drawn frame

**What:** A color picked on the Theme tab (its background and border colors, the templates' colors) runs `st:RecolorThemed()`, which recolors every frame drawn by the theme engine, on each pass of the drag. It is not made cheaper by the live colors work: the pass is timed (`theme` in the debug line) and nothing more.

**Why noticed:** The live colors design left the Theme tab's colors out of scope (its call 11: "their recolor is timed in the debug line, a followup if over budget"). Whether it is over budget only the game can say: the spec's target is 2 ms a pass and the guard waits one frame per 8 ms over, three at most.

**Anchors:** `SaftUI-Core/Media/theme.lua` (`Recolor()`, which runs `st:RecolorThemed()` through `CO.Timed('theme', nil, fn)`), `SaftUI-Core/theme.lua` (`st:RecolorThemed`), `SaftUI-Core/Media/colors.lua` (`CO.Timed`, `CO.EditStats`, the `<DEBUG:Colors>` line), `docs/superpowers/plans/2026-11-15-saftui-live-colors-in-game-checklist.md` (the debug line check).

**What's been considered:** Act on it only if the owner's debug line, after a Theme tab color drag in a full UI (bags and the bank open, a 40-player raid or Test mode with Raid 40, the tracker), shows `theme` over 8 ms. Then: recolor only the frames whose look reads the color (by template and by key, as the Colors page's passes filter by group and key), or throttle the drag's passes.

**Shape of work:** a read of the debug line first; if slow, one ticket in Core to filter `st:RecolorThemed` by the template key that changed.

**Open questions:** The slowest `theme` pass the owner sees in game.

### 2026-11-15 — Edit mode: a Theme pass with edit mode on still does the full look and list refresh

**What:** With edit mode on, a Theme color pass (`st:ColorChanged('theme')`) still runs `EM:RefreshBar()`, the History list's `LookList()` and `EM:RefreshHistoryList()`: the Show filter re-anchors and sets its insets, rows are placed, shown and hidden. With the list open that is about 139 setter calls, 51 forbidden calls (`ClearAllPoints`, `SetPoint`, `Hide`, `Show`, `SetWidth`, `SetHeight`, `SetTextInsets`, `SetTexture`, `SetSize`) and about 6.4 KB per pass, and a drag on the Theme tab's colors runs one every frame. Text and Accent passes are already color-only.

**Why noticed:** The review of live colors Task 2 (Core's widgets and edit mode), finding m3, probe P6. The brief and the spec ("`theme` and `accent` as today", the Theme tab's recolor timed, not changed) kept Theme's full look, so it was left.

**Anchors:** `SaftUI-Core/EditMode/Bar/bar.lua` (`EM:RefreshBar`, `EM:RecolorBar`, the `ColorsChanged` listener), `SaftUI-Core/EditMode/Bar/historylist.lua` (`LookList`, `RecolorList`, the `ColorsChanged` listener), `SaftUI-Core/EditMode/mover.lua` (`EM:OnColorsChanged`), `tests/core/editmode_colors_test.lua`, `.superpowers/sdd/2026-11-15-saftui-live-colors/task-2-review.md`.

**What's been considered:** On `'theme'`, run `EM:RecolorBar()` and the list's recolor when `W.BlizzardLook()` has not changed since the last look, and the full look only when it has (a switch to or from Blizzard). The profile update's `SettingsChanged` already refreshes the list, so the list refresh on Theme could go.

**Shape of work:** Small: remember the last look in `bar.lua` and `historylist.lua`, branch the Theme listeners, and run the edit mode cost cases for a Theme pass under Thick, Thin and Blizzard.

**Open questions:** Whether a Theme pass can change anything but the look's color while the art stays the same (a Background change reaches the bar's backdrop through the theme's own recolor, not here).

### 2026-11-15 — Unit frames: a Warrior class pick updates every Warrior NPC plate

**What:** `UF.ColorReaches` for Class matches the unit's class token for any unit, so a Class > Warrior (or Paladin, Rogue, Mage) pick also updates every NPC plate whose unit carries that token, though a plate's bar and name don't show NPC class (`colorClassNPC` is off on plates). The spec's L3 ("nothing else updates") doesn't hold near a pack. Nothing visible changes; it is only cost.

**Why noticed:** Review of the live colors Task 3 (unit frames and nameplates), `.superpowers/sdd/2026-11-15-saftui-live-colors/task-3-review.md`, m1. A probe in the cost test's world had Class > Warrior reach 49 frames (35 of 40 plates): Health 49, Power 14, tags 49, 112 calls, against 23 for a Mage.

**Anchors:** `SaftUI-Unitframes/unitframes.lua` (`UF.ColorReaches`, `ColorFrame`), `tests/unitframes/color_cost_test.lua`, `SaftUI-Unitframes/config/default.lua` (`colorClassNPC`, `colorClassPet`).

**What's been considered:** Token matching never misses a frame (party and raid frames color NPCs and pets by class: `colorClassNPC`, `colorClassPet`, on in `party.lua`, `raid10.lua`, `raid40.lua`). The cheap fix is to reach an NPC only if the frame's Health or Power has `colorClassNPC`, and a pet only with `colorClassPet`, read from the frame's own fields as the Reputation rule reads its flags.

**Shape of work:** a small change in `UF.ColorReaches` with a cost case on a plate with the flag off.

**Open questions:** whether `/sui debug` shows the pass costing enough near a pack to be worth it.

### 2026-11-15 — Unit frames: what a color pass's real element updates cost

**What:** The unit frame color pass's cost is measured only with counting stand-ins for oUF's elements, so the tests' `forbidden 0` and `kb < 4` cover the handler, not the real `ForceUpdate`s it calls. The reviewer's probe with real SaftUI callbacks on stub widgets: Health and Power make 1 to 2 setters and no garbage; ClassPower calls `SetShown` once and `SetWidth` five times and makes about 76 KB over 100 calls (two tables in `PostUpdateClassPower`, plus oUF's `unpack(chargedPoints or {})`); the role corner calls `SetTexture` once (oUF adds `SetAtlas` and `Show` or `Hide`). None is protected, and oUF runs them all in combat on its own events. Rough time from counting C calls: Class > Mage 0.3 to 0.5 ms, Text > Danger in a raid with plates 1.5 to 3 ms, a Warrior pick near a pack 1.5 to 3 ms, a whole Class pass of a 40 raid 1 to 2.5 ms.

**Why noticed:** Review of the live colors Task 3, `.superpowers/sdd/2026-11-15-saftui-live-colors/task-3-review.md`, m3. Only `/sui debug` can say whether a pass passes 2 ms, and Test mode with Raid 40 (`UF:UpdateGroupPreview` restyles and lays out 40 preview frames on every pass of Roles and Text too) is probably the heaviest case.

**Anchors:** `SaftUI-Unitframes/unitframes.lua` (`ColorFrame`), `SaftUI-Unitframes/elements/classpower.lua` (`PostUpdateClassPower`), `SaftUI-Unitframes/elements/indicators.lua` (the role corner's `postUpdate`), `SaftUI-Unitframes/grouppreview.lua`, the `<DEBUG:Colors>` line.

**What's been considered:** The spec allows an oUF element's `ForceUpdate` in a pass, so this is not a violation. Possible cuts: a color-only update for ClassPower and the role corner (no `SetShown`, `SetWidth` or `SetTexture`), or a throttle of the previews.

**Shape of work:** an in-game read of the debug line first (Class and Text > Normal in a raid, Test mode with Raid 40), then a ticket only if one is slow.

**Open questions:** the slowest pass the owner sees in game.

### 2026-11-15 — A Position reset runs a unit frame's update once for every part it writes

**What:** A reset of a unit frame part's Position whose anchor and offsets all differ writes point, rel_point, `relative_to` (twice, for a Global frame) and the offsets, and each part's own `set` calls `UF:UpdateConfig(unit)`: six updates for one click.

**Why noticed:** Review of reset-every-setting Task 3 (nit N1), picked up in Task 8: the kit writes a position through the row's own `set`, one part at a time (`PositionWrites` and `WritePosition` in `SaftUI-Core/Config/optionsdefault.lua`), so the row's `set(info, part, value)` contract is what it is.

**Anchors:** `SaftUI-Core/Config/optionsdefault.lua` (`WritePosition`), `SaftUI-Unitframes/config/position.lua` (`generators.uf_element_position`), the part pages' `set` in `SaftUI-Unitframes/elements/*.lua`.

**What's been considered:** Batching in the kit needs a way to tell the row's `set` to hold its update (a flag the unit frame sets read, or a `set` that takes a "last part" argument), which changes the row's contract. In combat one queued update absorbs them all, and out of combat six updates are cheap, so nothing is wrong on screen.

**Shape of work:** Small if the unit frame `set` learns a batching flag (`OM.batching`), but it touches every part page's set. Worth doing only if a reset of a unit frame Position is ever seen to hitch.

**Update 2026-11-16:** an All units change reaches every follower, so the once-a-frame update (`UF:UpdateConfig('all')` propagating to each unit once a frame) is what bounds it; a Position reset on All units is still one write per part, and each runs its update. Not made worse by the sharing, not fixed by it.

### 2026-11-15 — After a UI scale change, a reset half-pixel Position can show its icon again

**What:** A default whose offset is half a pixel (the player's Power at x 0.5) resets to the rounded value the position set stores. At the scale it was reset at it shows no icon, but after a UI scale change the rounding differs and the icon can come back; one more click clears it.

**Why noticed:** Review of reset-every-setting Task 3 (nit N4); the spec accepts the rounding (R1).

**Anchors:** `SaftUI-Core/Config/optionsdefault.lua` (`Offset`, `SamePart`), `SaftUI-Unitframes/config/default.lua` (the half-pixel offsets).

**What's been considered:** Comparing offsets within half a pixel at the current scale would hide it, but would also hide a real half-pixel move. Changing the default to a whole pixel changes what a fresh profile holds.

**Shape of work:** Small if wanted: decide the tolerance, then a test at two scales.

### 2026-11-15 — Shipped category names shown numbered: no test pins that they show no reset icon

**What:** A default category whose name another category has is shown with a number after it (`Toys (2)`), and with no edit saved the Name row shows no icon. Nothing pins that decision.

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `SaftUI-Bags/categories.lua` (`UniqueName`, the numbering in `GetCategoryList`), `SaftUI-Bags/categoriestab.lua` (`args.name.default.differs`, which reads only a saved edit), `tests/bags/categories_editor_test.lua`.

**Shape of work:** One case: a user category called like a shipped one, the list numbers the shipped one, and its Name icon is absent until the name is edited. Small.

### 2026-11-15 — Reset walk: the profile compare is most of a unit page's cost

**What:** `tests/unitframes/config_test.lua` takes 12 s: each probed row diffs the whole profile twice, which is almost all of it.

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `tests/lib/reset_walk.lua` (`Changes`, `RoundTrip`, `ctx.base`), `tests/unitframes/config_test.lua`.

**Shape of work:** A cheaper way to see a write outside a row's saved path: a write log on the profile table, or comparing only the saved path's top-level key plus one whole-profile compare at the end of a page.
















### 2026-11-15 — Nameplates: Blizzard's friendly plates key binding and the next login

**What:** Blizzard's own friendly plate options (Interface > Nameplates) and its key binding for them change `nameplateShowFriendlyPlayers` and `nameplateShowFriendlyNpcs`, the settings SaftUI's Friendly plates drives, without Friendly plates following. Since the profile switch fix, a key press stands until Friendly plates itself changes, and the next login sets the game's plates to the profile's value again.

**Why noticed:** Left open by the first entry of the fu-p2 fix (a profile switch not setting the game's friendly plates, now under Resolved), whose open question it was.

**Anchors:** `SaftUI-Unitframes/nameplates/cvars.lua` (`UF:ApplyNameplateCVars`, `UF.appliedFriendly`), `SaftUI-Unitframes/unitframes.lua` (`UF:ApplyConfig`'s plate branch), `tests/unitframes/profile_switch_test.lua`.

**What's been considered:** Leave it (SaftUI's value wins at the next login), or have Friendly plates follow the game's setting through a `CVAR_UPDATE` listener that writes the profile, which would make a key press change the profile.

**Shape of work:** Small if left; a listener and a test if Friendly plates follows the game.

**Open questions:** Should Blizzard's friendly plates key binding change SaftUI's Friendly plates, or be undone at the next login?

### 2026-11-15 — Bag search box: the magnifier and the clear button

**What:** The bag search box is now a plain single-line `InputBoxTemplate` box (merge fu-p5). The original call asked for `'SearchBoxTemplate'`, which has a magnifier and a clear button, but that never took effect: the argument was read as `lines`. Does the owner want the magnifier and clear button, or SaftUI's plain box?

**Why noticed:** The cleanup's Task 16 reviewer read the call against `st:CreateEditBox` (2026-11-12); the multi-line bug was fixed in merge fu-p5 and the question was left for the owner. In game (2026-11-13) the box behaved fine as it was.

**Anchors:** `SaftUI-Bags/search.lua` (`INV:InitializeSearch`); `SaftUI-Core/Widgets/editbox.lua` (`st:CreateEditBox`); `tests/bags/search_box_test.lua`; `docs/design-system/10-discrepancies.md` (discrepancy 7).

**Shape of work:** Small if wanted: give `st:CreateEditBox` a template parameter and pass `'SearchBoxTemplate'` properly, then the skin deals with the template's own art on both clients. Or a SaftUI clear button of its own (a Lucide icon with a tooltip).

**Open questions:** Magnifier and clear button, or the plain box?

### 2026-11-15 — Tracker: an Edit Mode anchor to a frame other than UIParent gives the default spot

**What:** SaftUI's tracker's first position reads Blizzard's Edit Mode layout (`EditModeSpot`, `SaftUI-Tracker/window.lua`). A tracker Edit Mode anchored to a frame other than UIParent (for example under `MinimapCluster`) gives Blizzard's default spot, because the offsets are relative to that frame and SaftUI does not resolve it.

**Why noticed:** The limit named when [a tracker moved in Blizzard's Edit Mode](#2026-11-14--tracker-a-tracker-moved-in-blizzards-edit-mode-isnt-the-first-position) was resolved (merge fu-p4).

**Anchors:** `SaftUI-Tracker/window.lua` (`EditModeSpot`, the `anchor.relativeTo ~= 'UIParent'` test); `tests/tracker/editmode_position_test.lua`; `.agents/clients.md`, Objective tracker.

**What's been considered:** Resolving the named frame needs a global lookup of a Blizzard frame and its rect, a read; the default spot is a safe fallback.

**Shape of work:** Small if wanted; probably not worth it.

**Recommendation 2026-11-15 (left for the owner):** abandon. A resolved offset is only right if the other frame's rect at login is the one Blizzard's Edit Mode applied: `EditModeSpot` runs as `EDIT_MODE_LAYOUTS_UPDATED` fires, which may come before Edit Mode has placed that frame (a nil or stale rect), and SaftUI's Minimap module moves parts of that area, so the answer could be worse than the default spot, with nothing outside the game to check it. If wanted: read `GetLeft/GetRight/GetTop/GetBottom` of `_G[anchor.relativeTo]`, scale them by its effective scale over UIParent's, and fall back to the default spot on any nil.

**Open questions:** Not confirmed in game: the preset-layout offset (`activeLayout` counts the preset layouts in front of the saved ones, from Blizzard's source), and what `GetLayouts` answers before the layouts load (the gate no longer depends on it). Checks: a character whose Blizzard tracker was dragged (right edge snap, bottom corner, free drag) on a new profile starts at that spot; a Modern or Classic preset with the tracker undragged starts at the default spot; a `/reload` with a saved SaftUI position leaves it unmoved; a fresh login where the layouts arrive after SaftUI builds.

### 2026-11-15 — The bag bar and Hekili: what still writes onto Blizzard's frames

**What:** After the bag-bar slots and the Hekili and WeakAuras skins moved to side tables (merge fu-p7), these writes onto Blizzard's frames remain, all `st:Kill` (it sets `_Show`, `Show`, `_SetAtlas`, `SetAtlas` and calls `UnregisterAllEvents`, `SetParent(st.HiddenFrame)`, `StripTextures`, `SetAlpha(0)`, `Hide`):
- `st:Kill(MainMenuBarBackpackButton)` and `st:Kill(BagBarExpandToggle)` (`SaftUI-Bags/containers/bag.lua`). Blizzard's bag code never calls the replaced keys; leave them, or conceal by alpha with `EnableMouse(false)`.
- `st:Kill(slot.AnimIcon)`. Not replaceable by `SetAlpha(0)`: the slot's FlyIn animation drives its alpha. A write-free way: `slot.FlyIn:HookScript('OnPlay', function(group) group:GetParent().AnimIcon:Hide() end)`.
- `st:Kill(slot.CircleMask)` (retail only). A write-free way: `slot.searchOverlay:RemoveMaskTexture(mask)` and `slot.ItemContextOverlay:RemoveMaskTexture(mask)`; `st:SkinIcon` already removes it from the icon.
Also older: Hekili's first-build button is not skinned until its second build (a `Hekili_<id>_B<n>` global lookup would fix it).

**Why noticed:** The fu-p7 report and review, when the two entries about the bag bar's slots and the Hekili skin were resolved.

**Anchors:** `SaftUI-Bags/containers/bag.lua` (`SkinBagSlot`); `SaftUI-Misc/Skinning/addons/hekili.lua`; `st:Kill` in `SaftUI-Core/api.lua`; the larger entry [st:Kill and st:SkinIcon still write onto Blizzard pieces](#2026-11-09--stkill-and-stskinicon-still-write-onto-blizzard-pieces-roll-bars-and-elsewhere); `tests/bags/bag_bar_slot_test.lua`.

**What's been considered:** The write-free ways above. The bag slots are plain ItemButtons, not secure.

**Shape of work:** Small each. Could fold into the `st:Kill` entry's own fix, since `st:Kill` is Core's helper.

### 2026-11-15 — With IM chat style the tab row is always hidden

**What:** In `chatStyle` "im" Blizzard keeps the last active edit box shown at alpha 0.35 (`ChatFrameUtil.SetLastActiveWindow`: `editBox:Show()` then `Deactivate()`, both clients), so SaftUI's `OnShow` hook on the edit box, which hides `GeneralDockManager` (the tab row) while the box shows, keeps the tab row hidden all the time. The hook is there because SaftUI anchors the box right above the chat's backdrop, where the tab row sits, so the two overlap while a box shows; in the classic style the box shows only while typing, but in IM style it is always there. Predates the chat work.

**Why noticed:** The fu-p11 review (its P3 point). The dock overflow button's fade, its other half, was fixed 2026-11-15 (`CHT:HoldOverflowAlpha`).

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:SkinChatFrame`, the edit box's `HookScript('OnShow')` and `OnHide`); Blizzard's `ChatFrameUtil.lua` `SetLastActiveWindow` and `Deactivate`, `ChatFrameEditBox.lua` `OnShow`.

**What's been considered:** (a) hide the tab row only while the box is active (typing: `editbox:HasFocus()`), leaving the tab row shown with an inactive box over it, which overlaps in IM style; (b) in IM style anchor the box elsewhere (below the chat, or over the chat's bottom), so both show, a layout change; (c) leave it, as now: IM style users lose the tab row. Not chosen: needs the owner's call on whether IM style is supported at all and what it should look like.

**Shape of work:** Small for (a) and (c), a layout pass for (b).

**Review of fu-chat (2026-11-15):** option (c) costs more than a look: IM players then have no tab row at all (no clicking a tab, no whisper flash), and so does classic style while a voice transcription window is selected (`IsVoiceTranscription` in `SetLastActiveWindow`). Whether `chatStyle` can default to "im" for new accounts is not in the Lua source and is unverified (`/dump C_CVar.GetCVarDefault("chatStyle")` on both clients); if it does, every player on default settings hits this and it should not wait. Recommend (a) with `OnEditFocusGained` and `OnEditFocusLost` hooks instead of `OnShow` and `OnHide`: in classic, show and focus come together (`ShouldDeactivateChatOnEditFocusLost` hides the box), so classic is unchanged, and in IM the row hides only while typing. Check in game that the tabs stay clickable over the dimmed, inactive box.

**Open questions:** Does the owner use IM style, and which of (a), (b) and (c) should it be?

### 2026-11-15 — Temporary chat windows (whispers, pet battle log) are never skinned

**What:** Windows made by `FCF_OpenTemporaryWindow` (ChatFrame11 and up) never go through `SkinChatFrame` or `ApplyAppearance`. They keep Blizzard's art and tab, their tabs fade whatever Fade tabs says, and their backdrop comes only from the `FloatingChatFrame_UpdateBackgroundAnchors` hook during their `OnLoad`. Older than the chat work.

**Why noticed:** The fu-p11 review: the in-game checks for a whisper window expected a SaftUI look, which these windows never had.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:OnEnable`, the `NUM_CHAT_WINDOWS` loop); Blizzard's `FCF_OpenTemporaryWindow`.

**Shape of work:** A design pass: skin on a post-hook of `FCF_OpenTemporaryWindow`, or leave Blizzard's look on purpose.

**Review of fu-chat (2026-11-15):** `FCF_OpenTemporaryWindow` reuses closed temporary windows (it picks one that is "not inUse and not isDocked"), so a post-hook skin must be idempotent (`SkinChatFrame` already guards its hooks with `hooked`). `FCF_CopyChatSettings` gives them ChatFrame1's Blizzard-saved size and the template's face, and docked, their edit boxes sit under the chat while ChatFrame1's sits above it.

**Open questions:** Should a whisper window look like SaftUI's chat or like Blizzard's?

### 2026-11-15 — Chat's scroll bar loses SaftUI's anchor at every dock or lock change

**What:** SaftUI anchors each skinned chat window's scroll bar to the backdrop (or the window under None) in `CHT:UpdateChatFrameDisplay`. Blizzard's `FCF_UpdateScrollbarAnchors` puts the bar back on its own anchors at every dock, lock or uninteractable change (it is reached from `FCF_DockFrame` and `FCF_SetLocked`), possibly at login too. ChatFrame3 and up then stay on Blizzard's anchors until the next theme or profile change, and so does ChatFrame1 if `UPDATE_CHAT_WINDOWS` arrives after `OnEnable`.

**Why noticed:** The review of the fu-chat package (2026-11-15). Older than that package: the anchor always came only from `SkinChatFrame`.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:UpdateChatFrameDisplay`, the `pieces` table); Blizzard's `FloatingChatFrame.lua` `FCF_UpdateScrollbarAnchors`, `FCF_DockFrame`, `FCF_SetLocked`; `tests/chat/fixtures/chat_window.lua`.

**Shape of work:** Small: a `hooksecurefunc('FCF_UpdateScrollbarAnchors', ...)` that re-anchors a skinned window (`pieces[frame]`), testable with the fixture.

**Open questions:** In game, after a `/reload`, scroll up in a docked window other than General: is the bar 5 outside SaftUI's border, or on the window's edge inside it?

### 2026-11-15 — Chat's dock hook leaves Blizzard's tab layout after a resize, an overflow-list pick or an undock

**What:** `CHT:FCFDock_UpdateTabs` returns when `not (dock.isDirty or forceUpdate)`, but it is a post-hook, so Blizzard has already cleared `isDirty`: it acts only on forced updates (`FCF_DockUpdate`: a tab click, docking). After a resize of ChatFrame1 (`/sui` Width or Height, a profile switch: `FCFDock_OnPrimarySizeChanged`), after a pick from the overflow list (`FCFDockOverflowListButton_OnClick`) or after an undock (`FCFDock_RemoveChatFrame`), the tab row stays on Blizzard's layout (about 7 lower and 2 left, because the dock hangs on ChatFrame1's `Background`, which `st:Kill` leaves anchored at -2, +3, and 1px gaps) until the next forced update.

**Why noticed:** The review of the fu-chat package (2026-11-15). Older than the package; `tests/chat/dock_test.lua`'s "a plain update leaves the tabs where Blizzard put them" pins today's behavior.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:FCFDock_UpdateTabs`); Blizzard's `FloatingChatFrame.lua` `FCFDock_UpdateTabs`, `FCFDock_OnPrimarySizeChanged`, `FCFDock_OnUpdate`; `tests/chat/dock_test.lua`.

**What's been considered:** Re-anchoring on every call is idempotent and cheap (a few `ClearAllPoints` and `SetPoint` on tabs), so the guard can go. The catch is the owner's: the test above would flip.

**Shape of work:** Small: drop the guard, change the test, a case for each unforced path.

**Open questions:** In game, change chat's Width in `/sui` or switch profiles: do the tabs drop about 7 and shift 2 left until a tab is clicked? Drop the guard if so.

### 2026-11-15 — A font Size drag restyles too much on the action bars, unit frames and tracker

**What:** A Size (or any field) drag in a font row's dots menu, or in an action bar or unit frame text's Font menu, runs the page's whole update on every step. The bags were fixed to restyle texts only (`INV:ApplyFonts`, merge fb-fontbugs); the action bars, unit frames and tracker still pay per step.

**Why noticed:** The owner's lag spike dragging the bags' Title font Size. The reviewer of fb-fontbugs measured the same cause on the other pages in the test harness (`fb-fontbugs` review, 2026-11-15).

**Anchors:** `SaftUI-ActionBars/textoptions.lua:199` (`update`), then `options.lua:303` `AB:UpdateFor` and `bars.lua:406-420`; `SaftUI-Unitframes/elements/castbar.lua:105`, `elements/auras.lua:351`, `unitframes.lua:414-447` (`UF:UpdateConfig(unit, element)`, `frame:UpdateAllElements('OnShow')`); `SaftUI-Tracker/options.lua:303-306` and `init.lua:138` (`TR:UpdateConfig`, a direct `Refresh`); the bags' fix in `SaftUI-Bags/inventory.lua` (`INV:ApplyFonts`).

**What's been considered:** The reviewer's measurements. Action bars on All bars: 8 bar updates, 96 button restyles and 8 binding rebuilds per step (about 20 ms in the harness with stand-in buttons, one bar about 1.2 ms; in game more, since LibActionButton's `UpdateAction(true)` runs per button and `UpdateBindings` rebuilds over every bar once per bar). Unit frames: one full oUF update per frame of the unit per step: 5 for a party, 40 for a raid or for nameplates. Tracker: a full refresh per step, about 1.5 ms (a stall is unlikely).

**Shape of work:** A font change restyles texts only, as the bags now do. For the action bars a text-only path (set the text config of each affected button and restyle HotKey, Count and Name, with no `LayoutBar`, `UpdateVisibility`, `UpdateBindings`, `SetBackdrop` or `SkinIcon`; at least run `UpdateBindings` once in `UpdateBars`); for the unit frames a font-only flag through `UF:UpdateConfig` and `UpdateUnitFrame` that skips `UpdateAllElements`; for the tracker a redraw from the cached model. Three small tickets or one.

**Open questions:** Whether a held slider should also coalesce to one restyle per frame.

**Update 2026-11-16:** a font Size drag on All units now reaches every unit that follows it, but through `UF:UpdateConfig('all')`, once per follower per frame (pinned by `tests/unitframes/shared_page_test.lua`: a held slider's cost is under 4 KB a step and nothing runs in combat). The element's full update on each step is still the cost named here.

### 2026-11-15 — Hide full with a secret health: lift the limit with a Step curve into the text's alpha

**What:** Hide full still shows a secret full health's value when Deficit is off (value, Short or Percent). The idea: `Region:SetAlpha` takes a secret (`AllowedWhenTainted`), and `UnitHealthPercent(unit, usePredicted, curve)` takes any curve, so a curve made once at load (`C_CurveUtil.CreateCurve()`, `SetType(Enum.LuaCurveType.Step)`, `AddPoint(0, 1)`, `AddPoint(1, 0)`, or a point just under 1) lets `health.text:SetAlpha(UnitHealthPercent(unit, true, HIDE_FULL))` hide the text at full health, with `SetAlpha(1)` on every other path. Nothing else sets the health text's alpha.

**Why noticed:** Fixing [Health text's Boss percent and Hide full with a secret health](#2026-11-11--health-texts-boss-percent-and-hide-full-with-a-secret-health) (merge fu-p1) could only make Hide full apply to a plain health: no game function tells an addon whether a secret is zero. The author of the fix wrote the curve idea down instead of building it.

**Anchors:** `SaftUI-Unitframes/elements/health.lua` (`PostUpdateHealth`), `tests/unitframes/secret_texts_test.lua`.

**What's been considered:** With Deficit on the limit does not apply: `TruncateWhenZero` and `WrapString` already blank a zero deficit (the raid10 and raid40 defaults have both on). So only value, Short and Percent texts on a secret health are affected.

**Shape of work:** Small: one curve at load, one `SetAlpha` call per update, and `SetAlpha(1)` on the other branches, with a test in `secret_texts_test.lua`.

**Open questions:** How Step behaves at exactly 1.0 (check in game), and whether the game rounds a near-full health to 1.

### 2026-11-15 — Option descriptions that say "red" or "yellow" for what Danger and Caution color

**What:** Two unit frame descriptions still name a hue for a color that is now a role the player can change, so they can stop being true: "Color hostile" ("names of hostile units red, and of unfriendly and neutral ones yellow", `SaftUI-Unitframes/elements/name.lua:71`) and the Color by reaction description ("red when hostile, yellow when neutral, green when friendly", `SaftUI-Unitframes/config/config.lua:125`). They could say "in the Danger color" and "in the Caution color" (Global settings > Colors > Text). The totem bar's two timer descriptions, the tracker's out of range row (now named "Tint out of range") and the README's totem line were reworded 2026-11-15 and are done.

**Why noticed:** Color roles Task 4 moved those readers to Text > Danger and Text > Caution (the hue-named keys went), and its rule for the Colors page's own descriptions is that they name what a color colors, never its hue. These option descriptions sit outside that page, so the task left them.

**Anchors:** `SaftUI-Unitframes/elements/name.lua:71`; `SaftUI-Unitframes/config/config.lua:125` (the Color by reaction description names the Reputation colors for neutral and friendly, which are not roles, so only the hostile part is a role: check which of the three the reader uses before rewording); `docs/design-system/25-colour-roles.md`.

**Shape of work:** a wording pass over two strings in Unitframes (left because another package was editing that addon); the tests that pin a description's text change with them. The power color's "blue for mana, red for rage" and the health gradient's "red through yellow to green" describe resource and health colors, not roles: they stay.

### 2026-11-15 — Check box labels: no font setting until a SaftUI check box has a visible label

**What:** Global settings > Fonts > Kinds of text had a Check box labels row (`panels.font`). It was removed in the feedback round because nothing visible reads it: the only SaftUI check box with a label is the bags' Edit toggle, which is never shown, and it is styled as a button, so it follows Button text. `panels.font` stays in `st.defaults.panels` and `st:SkinCheckButton` still follows it, so a saved value does no harm. When a SaftUI check box gets a visible label, put the row back in `TEXT_FONTS` (`SaftUI-Core/Media/fonts.lua`: `{ 'checkbox_labels', 'panels', 'Check box labels', 'normal', desc }`) with a test that the label follows it.

**Why noticed:** The owner's in-game test (2026-11-15): "The 'Check box labels' item doesn't seem to change anything". Every `st:CreateCheckButton` call site is in `SaftUI-Bags` and none has a visible label; `/sui`'s own check boxes are the kit's and don't read it.

**Anchors:** `SaftUI-Core/Widgets/checkbutton.lua` (`PanelsFont`, `st:SkinCheckButton`, `button.SetTextFont`), `SaftUI-Core/Config/defaults.lua` (`st.defaults.panels.font`), `SaftUI-Bags/header.lua` (`INV:CreateEditToggle`), `tests/core/fonts_tab_test.lua`, `tests/core/button_text_test.lua`.

**What's been considered:** Hiding the row, or keeping it with a description that says it does nothing: both leave a dead control. Removing it and keeping the setting's reader costs nothing and lets the row come back with the first label.

**Shape of work:** Small: one `TEXT_FONTS` entry and its tests, with the first visible label.

### 2026-11-15 — A window title font per theme

**What:** Theme > Window titles sets one font for every window title under every theme. Let each theme (Thick, Thin, Blizzard) have its own, falling back to Window titles where it sets none.

**Why noticed:** The fonts design's "Later" list; the owner moved Window titles to the Theme tab (decision 5) and left a per-theme font for later.

**Anchors:** `SaftUI-Core/Media/theme.lua` (the Window titles section and its Font row), `SaftUI-Core/Media/fonts.lua` (`headers.font`, the Kinds of text key that Window titles keeps), `SaftUI-Core/panels.lua` (`HeaderFont`, `st:CreateHeader`).

**What's been considered:** Nothing beyond the one line. The themes' other settings (Accent, Options windows) are one choice for all themes, so a per-theme font would be the first that is not.

**Shape of work:** Needs a design pass (which of the three looks differ enough to want their own, and where the rows go), then small work in the Theme tab and `HeaderFont`.

**Open questions:** Whether it is a row per theme or a "per theme" switch on the one row.

### 2026-11-15 — The tooltip lines take SaftUI's shadow and spacing

**What:** The tooltip's lines take the Font row's face, size and outline (its dots menu lists Size and Outline only), and leave Blizzard's shadow and line spacing alone. Let them take SaftUI's shadow and spacing too, for the consistency decision 22 of the fonts design asks for.

**Why noticed:** The fonts design's "Later" list. The plan kept the tooltip's menu to the two fields its reader applies (Ruling 7), so no row in a menu does nothing.

**Anchors:** `SaftUI-Misc/tooltip.lua` (the lines' `SetFont`, the changed-only compare on each Show), `SaftUI-Misc/tooltipposition.lua` (the Font row's `fields`), `docs/superpowers/plans/2026-11-14-saftui-fonts.md` (Ruling 7).

**What's been considered:** Chat keeps Blizzard's line spacing for the same reason (its frames draw at 0 where Text's is 4), so the tooltip's own spacing would be a look change for everyone, not only a consistency fix. The lines are Blizzard's font strings, copied onto on each Show, so the compare would grow two fields.

**Shape of work:** Small: the reader and the row's `fields`, tests for the lines, and an in-game look at the tooltip's spacing.

**Open questions:** Whether the tooltip's line spacing should follow Text's 4 or stay Blizzard's.

### 2026-11-15 — Title bar height beside Window titles on the Theme tab

**What:** Under the Blizzard theme a window's header sits in the metal's title bar (a fixed strip of 20). A Window titles font taller than that strip has no way to give it more room. Add a Title bar height setting beside Window titles on the Theme tab.

**Why noticed:** The fonts design's "Later" list, from the Window titles move (decision 5).

**Anchors:** `SaftUI-Core/Media/theme.lua` (the Window titles section), `SaftUI-Core/themeart.lua` and `st.ThemeArt.TitleStrip()` (the 20), `st:HeaderInTitleBar`, `st:HeaderButtonSize` and `st:HeaderRoom` in `SaftUI-Core/panels.lua`.

**What's been considered:** Every window that places things above its header reads `st:ArtAboveHeader` and `st:HeaderRoom`, so a height that varies needs them to read the setting, and the bags' window (protected in combat) re-lays out through the combat queue.

**Shape of work:** A design pass (a size range, whether Thick and Thin have a header height too), then medium work across the header helpers and the windows that hang from them.

**Open questions:** Whether it applies to all three looks or only to Blizzard's title bar.

### 2026-11-15 — Search into the dots menus

**What:** `/sui`'s search lists a font row but never the Size, Outline, Shadow offset and Line spacing rows behind a typeface's dots, because the menu is built from the row's value when it opens and no option holds it. Searching "Size" finds only real Size rows.

**Why noticed:** The fonts design's "Later" list; the plan's Task 4 pinned the current behavior in a test ("search finds no row of a dots menu").

**Anchors:** `SaftUI-Core/Config/optionsfont.lua` (`w:Menu()`), `SaftUI-Core/Config/optionsmodel.lua` (`CollectMenu`, `OM.Search`), `tests/core/options_font_test.lua` (the search case).

**What's been considered:** A font row has no `menu` field, so search's walk of item menus never sees it. A row whose value is a shared font has no menu to list, and one whose value is a typeface has a different menu per value, so a hit would have to open the row's menu on the right typeface or name the row only.

**Shape of work:** Needs a design pass on what a hit is (the row, or the menu open on it), then a small model change and tests.

**Open questions:** Whether a hit on a row whose value is a shared font should still list the typeface fields.

### 2026-11-15 — SaftUI's tracker: what the in-game pass left open

**What:** SaftUI's tracker went on by default after the owner's in-game pass on Forever (see the Resolved entry "SaftUI's tracker: experiments and in-game checks before the switch turns on"). Three things were not settled by it.

**Why noticed:** The owner's pass, 2026-11-15, recorded in the checklist's "Results so far" (`docs/superpowers/plans/2026-11-15-saftui-tracker-phase-1-in-game-checklist.md`). The owner said everything looked good and approved the default, skipping some experiments.

**Anchors:** that checklist's P4, P6, P7 and "Results so far"; `SaftUI-Tracker/probes.lua` (`TR.SectionHandsOver`), `SaftUI-Tracker/clicks.lua` (`TR.WatchChangeAllowed`, popup clicks), `SaftUI-Tracker/groups.lua` (the current zone first).

**Shape of work:**
- **P4 inside a dungeon and a battleground** (and with an achievement or recipe tracked): which Blizzard sections fill in, for `TR.SectionHandsOver`. Only the open world was run.
- **P6 and P7 were skipped by the owner.** Their seams stay as built: watch changes out of combat only; popup clicks allowed in combat. Run them if a taint line ever names them.
- **The current zone first when the zone text is a sub-area name.** The owner's zone text printed "Shen'dralas" while the quests' header was "Desolace", so a match on the zone text may not list the current zone first. Check what `groups.lua` compares and whether it should use the parent zone.

**Open questions:** Whether the current-zone match needs the parent zone's name.

### 2026-11-15 — SaftUI's tracker phase 2: task quests (bonus objectives and world quests)

**What:** SaftUI's tracker draws tasks in the area (bonus objectives) and watched world quests, with their progress bars, time left and rewards in the tooltip, and gives their quest items the same secure buttons as quests'. It removes the most common handover on retail (today a bonus objective or a watched world quest hands the tracker to Blizzard's).

**Why noticed:** The spec's Phasing section (`docs/superpowers/specs/2026-11-14-saftui-objective-tracker-design.md`) lists six phases; Phase 1 (quests) is built and each later phase is a followup so it is not only in the spec. The owner isn't particular about the order after version one ("I'm not picky with where to start"); call 35 gives the order task quests, scenarios and dungeons, Mythic+, other tracking, zone widgets, with scenarios first if P4 shows Forever's dungeons are scenarios.

**Anchors:** The spec's Phasing and "How SaftUI knows a section has content"; `SaftUI-Tracker/probes.lua` (`TR.SECTIONS` entries `bonus` and `world`: Phase 2 stops these handing over, by drawing them), `SaftUI-Tracker/model.lua` (where tasks join the model: `GetTasksTable`, `GetTaskInfo`, `C_QuestLog.IsWorldQuest`, `GetNumWorldQuestWatches`), `SaftUI-Tracker/items.lua` (task quests have special items too); `.agents/clients.md` ("The objective tracker's sections").

**What's been considered:** Mostly retail; on Forever only if P4 shows it has any. Phase 1 already shows Blizzard's tracker for them through the handover, so nothing is lost meanwhile. A task quest's progress bar and timer are the existing row lines; the new parts are reading the tasks and world quest watches into the model and the tooltip's rewards.

**Shape of work:** One plan of its own: the model (tasks and watched world quests, with the display rules), rows and bars, the tooltip, item buttons through the existing layer, and `TR.SECTIONS`'s two entries no longer handing over.

**Open questions:** What P4 finds on Forever. Whether task quests group under their zone's header or a section of their own.

### 2026-11-15 — SaftUI's tracker phase 3: scenarios and dungeons

**What:** SaftUI's tracker draws a scenario's name, stage, criteria and their bars, stage timers, delves (tier, lives), proving grounds and warfronts, the scenario's spell buttons (secure, like item buttons, under the same rules) and its bonus steps, and the Maw's buffs (read out of combat only, or kept handing over for them). Secret criteria values (`GetUnitCriteriaProgressValues`) are passed to widgets, never compared.

**Why noticed:** The spec's Phasing section. A dungeon today hands the tracker to Blizzard's; this phase replaces that in the most common content. It moves ahead of Phase 2 if P4 shows Forever's dungeons are scenarios.

**Anchors:** The spec's Phasing and "Secret values"; `SaftUI-Tracker/probes.lua` (`TR.SECTIONS` entry `scenario`, `TR.Probes.Scenario`), `SaftUI-Tracker/handover.lua`; `.agents/taint.md` rules 5, 6 and 15 (the buttons would be secure); `.agents/clients.md`.

**What's been considered:** The Maw's buffs read aura data, which is secret in combat, so they are read out of combat or kept handing over. The spell buttons follow the item buttons' rules exactly (made, placed and given attributes only out of combat, never under a frame that moves in combat).

**Shape of work:** One plan: the scenario reader (pure, secret-safe), its rows and bars, the stage timer, delves and proving grounds, the spell buttons through the item layer's mechanism, then `TR.SECTIONS`'s `scenario` entry no longer handing over (the seam `TR.SectionHandsOver`).

**Open questions:** Whether Forever's dungeons are scenarios (P4).

### 2026-11-15 — SaftUI's tracker phase 4: Mythic+

**What:** SaftUI's tracker draws the challenge mode: the key level, affixes, the timer with its +2 and +3 marks, deaths and the enemy forces bar. Retail.

**Why noticed:** The spec's Phasing section. It needs Phase 3 (a Mythic+ run is a scenario). Until then Blizzard's tracker shows for a key through the handover (`C_ChallengeMode.IsChallengeModeActive`).

**Anchors:** The spec's Phasing; `SaftUI-Tracker/visibility.lua` (the Mythic+ trigger already reads `C_ChallengeMode.IsChallengeModeActive`), `SaftUI-Tracker/probes.lua`; `.agents/clients.md` ("Boss fights and Mythic+").

**Shape of work:** One plan, after Phase 3: the challenge mode reader, the rows (timer, deaths, forces bar), and the handover no longer applying for a key.

**Open questions:** None yet; the secret-value rules are Phase 3's.

### 2026-11-15 — SaftUI's tracker phase 5: other tracking

**What:** SaftUI's tracker draws achievements, tracked recipes with reagent counts, monthly activities, endeavors and collection tracking, each as a section of its own under the window's header, with a section header showing once more than one section has content.

**Why noticed:** The spec's Phasing section. Today each of these hands the tracker to Blizzard's through the probes (`TR.SECTIONS`: `achievements`, `professions`, `activities`, `endeavors`, `collections`). On retail a tracked recipe or a Traveler's Log activity in the open world replaces SaftUI's tracker, which is the reason to do this early on retail.

**Anchors:** The spec's Phasing; `SaftUI-Tracker/probes.lua` (`TR.Probes`: `Achievements`, `Professions`, `Activities`, `Endeavors`, `Collections`), `SaftUI-Tracker/handover.lua`.

**What's been considered:** Small, independent parts; each can be split into its own plan.

**Shape of work:** A section framework in the window (a section header, per-section collapse), then one small task per section, each removing its entry from the handover.

**Open questions:** Whether each section collapses on its own or the whole tracker does; the section header's look.

### 2026-11-15 — SaftUI's tracker phase 6: zone widgets

**What:** SaftUI's tracker draws the objective tracker's widget set (`C_UIWidgetManager.GetObjectiveTrackerWidgetSetID()`), which removes the last reason to show Blizzard's tracker.

**Why noticed:** The spec's Phasing section. After this phase the handover stays only as a safety net for a section a later patch adds, and the concealment stays for good (Blizzard's tracker keeps auto-tracking accepted quests and sorting the watch list for SaftUI's).

**Anchors:** The spec's Phasing; `SaftUI-Tracker/probes.lua` (`TR.SECTIONS` entry `widgets`, `ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing()`).

**What's been considered:** Blizzard's widget frames are pooled and shared with the screen's other widget containers, so hosting them in a SaftUI container could taint those. It needs its own taint study first.

**Shape of work:** A taint study (a design note and an in-game experiment like P2/P3), then a plan only if the study passes.

**Open questions:** Whether hosting the widget set is safe at all; if not, the handover for widgets stays.

### 2026-11-15 — SaftUI's tracker: do quest items work under [vehicleui] and [overridebar]?

**What:** The item layer's visibility driver is `[petbattle] hide; show` plus the player's triggers; it has no `[vehicleui]` or `[overridebar]`, which SaftUI's action bars hide on by default. Phase 1 chose to leave both out (the plan's Ruling 21). The question is whether quest items can be used in a vehicle or on an override bar; if they can't, the buttons should hide there like the action bars do.

**Why noticed:** The spec leaves it to the builder ("Whether the item layer's driver also hides on `[vehicleui]` and `[overridebar]` (the action bars' defaults), after checking that quest items can't be used then"), and the plan ruled it out of Phase 1 with this followup.

**Anchors:** `SaftUI-Tracker/items.lua` (`TR.ITEM_DRIVER`, `TR.PET_BATTLE_HIDE`), `SaftUI-Tracker/visibility.lua` (`Visibility.Driver`: the one place the layer's string is built), `SaftUI-Tracker/nearest.lua` (`TR.NearestDriver()`: its own driver, the pet battle's alone), `SaftUI-ActionBars/` (the bars' visibility drivers), `tests/tracker/visibility_test.lua` (the pinned strings).

**What's been considered:** The layer's and the nearest button's drivers are separate strings, so either can change alone. A quest item shown over a vehicle's bar that does nothing is the cost of leaving it.

**Shape of work:** First the check in game: use a quest item on a vehicle and on an override bar (a quest with a vehicle or a possess), with the item buttons shown. If it works, nothing changes. If not, add the two conditions to `Visibility.Driver` (and `TR.NearestDriver()`), with the test strings.

**Open questions:** The result of the in-game check.

### 2026-11-15 — Chat's font size against Blizzard's per-window Font Size

**What:** Blizzard sets a chat window's font size itself, and SaftUI sets it from chat's font setting, so the two can pull against each other. Blizzard's own code runs `SetFont` on every chat frame on `UPDATE_CHAT_WINDOWS` (size from its chat-cache, face and flags the frame's current ones), the tab menu's Font Size (`FCF_SetChatWindowFontSize`) sets one window's size and saves it, and temporary whisper windows (ChatFrame11 and up) are never skinned by SaftUI and take Blizzard's saved size.

**Why noticed:** Review of fonts Task 5 (`.superpowers/sdd/2026-11-14-saftui-fonts/task-5-review.md`, m1). The Task replaced chat's Font size row with chat's font (Text, or a typeface whose dots hold Size), so a typeface in the dots is now the only SaftUI way to give chat its own size. The Blizzard sources read: `Blizzard_ChatFrameBase/Mainline/ChatFrameOverrides.lua` (`UPDATE_CHAT_WINDOWS`) and `FloatingChatFrame.lua` (the tab menu), both branches.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:ApplyChatFont`, `CHT:OnFontsChanged`), `tests/chat/font_test.lua` (the changed-only case), `.agents/taint.md` (rule 2: post-hooks only).

**What happens today:** chat applies its font on enable, on a profile change and on chat's own options (always), and on a Fonts tab change only for a window whose values from chat have changed since SaftUI last set them (the changed-only rule in `ApplyChatFont`), so a Heading size change leaves a size picked in Blizzard's tab menu alone and a Text size change (chat's own font) replaces it. If `UPDATE_CHAT_WINDOWS` fires after SaftUI enables, Blizzard's saved size shows at login, before and after the upgrade alike, so G5 compares like with like.

**What's been considered:** (a) post-hook `FCF_SetChatWindowFontSize` and `HookScript('OnEvent')` for `UPDATE_CHAT_WINDOWS` on the skinned frames to put chat's font back, so SaftUI's size always wins; (b) let Blizzard's per-window size win and drop Size from chat's dots; (c) leave it, as now. Not chosen yet: it needs the in-game check below first.

**Shape of work:** small: a hook pair in `chatframe.lua` for (a), or removing `'font_size'` from chat's `fields` and the conversion for (b), plus a test either way.

**Review of fu-chat (2026-11-15):** for (a), prefer SaftUI's own event frame for `UPDATE_CHAT_WINDOWS` (it registers after Blizzard's chat frames) over `HookScript('OnEvent')` on each window, which would run on every chat message. The source confirms the entry: the handler calls `SetFont` with the cached size and the frame's own face and flags, so under (b) SaftUI's face and outline survive Blizzard's size. Check both a `/reload` and a full relog: the handler's own comment says the event "can be received before settings have been downloaded", so it may fire more than once.

**Open questions:** does `UPDATE_CHAT_WINDOWS` fire after `PLAYER_LOGIN`, and is chat at SaftUI's size or Blizzard's chat-cache size after login? Does a Fonts tab change that does not touch chat undo a size picked from the tab menu (it should not now)? Which of (a) and (b) does the owner want?

### 2026-11-14 — Position rows of secure frames can anchor to a frame that is moved in combat

**What:** A holder with a secure child is protected, and protection spreads to the frames it is anchored to. The Position row of any mover whose holder carries secure buttons accepts any frame name (`generators.position(..., true, ...)`, which only refuses loops), so a player can anchor it to a frame SaftUI sizes or moves in combat, which then gets `ADDON_ACTION_BLOCKED`. The tracker's nearest button's row now refuses the tracker's window (`TR.NearestAnchorRefusal`); the others don't.

**Why noticed:** Review of Task 10 of the objective tracker (`docs/superpowers/plans/2026-11-14-saftui-objective-tracker-phase-1.md`), finding I2: the nearest holder could be attached to `SaftUITracker`, which `TR:LayoutWindow` resizes in combat.

**Anchors:** `SaftUI-Tracker/nearest.lua` (`TR.NearestAnchorRefusal`), `SaftUI-Core/Config/generators.lua` (`generators.position`), `st:MovesWith` and `st:ValidateAnchor` (`SaftUI-Core/api.lua`), the action bars' extras and the totem bar's Position rows (`SaftUI-ActionBars/options.lua`, `SaftUI-Misc/totemoptions.lua`), `.agents/taint.md` rule 6 and 16.

**Shape of work:** Small design pass, then one change: let a mover say which frames its holder may not be anchored to (a `refuseAnchor(frame)` hook on `generators.position`'s target, or a registry of frames SaftUI moves in combat), use it in the secure holders' rows, and a test per row.

**A case the tracker's row can't see:** the refusal runs when the nearest row is set and each time the holder is placed (a saved anchor that now reaches the window falls back to UIParent at the next placement, out of combat), not when another frame's anchor changes. A player can attach the nearest holder to frame X (accepted), then attach X to `SaftUITracker` through X's own Position row, which only refuses loops: the window is protected through the chain until the next placement. A backstop would be `TR:LayoutWindow` skipping `SetSize` while `not st:CanMoveNow(window)` and queuing it.

**Open questions:** whether to refuse by a registry of "moves in combat" frames or by asking each row's owner.

### 2026-11-14 — A first-run setup dialog: UI size, theme, unit frame layout

**What:** A dialog shown the first time SaftUI runs that walks a new player through a few choices and introduces the UI: the UI size (a default worked out from their resolution, which they can override), the theme (Thick, Thin, Blizzard, and any added later), and which unit frame layout to use, from a few the owner will make.

**Why noticed:** The owner, while the UI scaling design was being written (2026-11-14): "I wonder if it would be worth having an initial setup dialog that can work through a few steps and introduce the UI, this scaling could be a good first candidate - set a default based on the user's resolution but allow them to override it. I'm probably going to setup a few different unitframe configurations, so a follow up setup could be choosing which unitframe theme to choose (also picking which theme from thick, thin, blizzard, and any other that gets added)". The friends who play at 1080p and on a Mac at 3456x2234 are the people it is for: they get SaftUI's defaults, tuned on the owner's 1440p screen, with no guided way to fit them.

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md` (the scale's interface a setup step calls: computed default, preview, apply, revert); `SaftUI-Core/Media/theme.lua` (the theme setting); `SaftUI-Unitframes/config/profiles.lua` (unit frame profiles, the natural home for shipped layouts); `SaftUI-Core/Config/optionssmalldialog.lua` and `optionsdialog.lua` (the kit's dialogs); `SaftUI-Core/Config/` (AceDB: where "setup done" would be recorded).

**What's been considered:** The scaling design keeps "the default worked out from the resolution" apart from "what the player chose" so this dialog can show one and save the other, and ships usable without the dialog. Nothing else is designed.

**Shape of work:** A design first. Likely pieces: the dialog itself (steps, back and next, skip, a live preview behind it); a way to ship unit frame layouts as data (presets the owner authors in game and exports, loaded as named unit frame profiles); each step's content; when it shows (first login with no SaftUI settings; offered again from `/sui`).

**Settled 2026-11-14:** the owner builds each unit frame layout in game as a unit frame profile, and it is migrated from the game's saved settings (SaftUI's SavedVariables in the WTF folder) into built-in defaults that ship with the addon. "yep I'd build them myself in game and you can just migrate the settings from the wtf folder to actual defaults". When migrating, only the settings go into the repo: no account, realm or character names from the file or its path.

**Open questions:** How a shipped layout is stored and named (data files under `SaftUI-Unitframes/config/`, listed beside the player's own profiles and not editable in place?), and how one is refreshed when the owner changes it. Whether existing players see it after the update or only fresh installs. Whether it is per account or per character. What else belongs in it (action bar layout, bags view, the tracker switch).

**Update 2026-11-16:** a shipped unit frame layout (a preset) now carries All units: the unit frame profile's `all` table, each unit's own flags and the marker are part of a profile (`SaftUI-Unitframes/config/shared.lua`, `UF.CopyProfileData`), and Copy and Export carry them, so a preset is converted as it is loaded. A preset must be made on this build, since an older export is converted at the next login.

### 2026-11-14 — /sui at half with the sidebar collapsed: a validation error is cut or hidden in the footer

**What:** With the sidebar collapsed at half width (W4), the footer's status line, where a validation error such as "Size: a number, please" shows, has a region about 54 wide under Thick and Thin (96 under Blizzard), so the message is cut after two lines, and with one more icon command registered the region is 22, under `FOOTER_MIN_ROOM` (24), so the status line is hidden and no message shows anywhere. The page's field then keeps only the typed text.

**Why noticed:** Review of the footer's collapsed tools (window sizes work, Task 6). The plan's Ruling 7 expected about 65 wide and a wrapped status line; the real room is smaller because Search, Edit mode, the toggle and the "More" button are the floor and take the footer. The task's report had said errors still show in the field itself, which they don't: the field shows the typed text, not the error (`optionswidgets.lua`, the field's validation path).

**Anchors:** `SaftUI-Core/Config/optionswindow.lua` (`PlaceFooter`, `FOOTER_MIN_ROOM`, the status line), `SaftUI-Core/Config/optionsnav.lua` (`S.DrawTools`), `SaftUI-Core/Config/optionswidgets.lua` (a field's error), `tests/core/options_footer_tools_test.lua`, `tests/core/options_sidebar_test.lua` (the footer never overlaps).

**What's been considered:** Show the error in the field's tooltip, or on a line over the footer (or over the page's bottom) while the footer's region is short; or let the status line borrow the room of the tools that follow Reload UI. None is built. The owner's rule that nothing overlaps (the footer's tools stop short of Reload UI) means the status line can only give way, so the message needs another place.

**Shape of work:** A small design pass on where an error shows when the region is short (a tooltip on the field is the smallest), then a change in `PlaceFooter` or the field plus a test at W4 with the real command set and with one more icon command.

**Open questions:** Where should the message show when the footer has no room: the field's tooltip, a line over the footer, or both? An in-game check at W4 with Keybind mode only (54 wide) decides how often it matters.

**Recommendation 2026-11-15 (left for the owner, a look):** show the message without the mouse on the field: a tooltip anchored to the field, opened by the failed commit itself (the value is committed from the keyboard, so the mouse can be anywhere), only while the status line has no room for the message. It closes on the next edit of the field, on focus lost, or after a few seconds. It adds no line, so nothing can overlap; the status line stays as it is when it has room.

### 2026-11-13 — Design decisions waiting to be built

**What:** The design system's Decisions page (`docs/design-system/05-decisions.md`) records choices the owner has made that no task has built yet. This entry is the list, so none is lost between sessions. Each line names its decision number there.

**Why noticed:** The design system was written on 2026-11-13 and the owner answered its questions the same day, faster than the work could be queued.

**Anchors:** `docs/design-system/05-decisions.md`, `10-discrepancies.md`, `25-colour-roles.md`, `30-code-changes.md`.

**Not yet built, with no task running:**

- 1: the options window's controls' lines follow the theme's, and the in-world close button is drawn in its window's theme. 2: built for the config windows (the `/sui` window, edit mode's bar and History list and the small dialogs follow the theme's Background, with Global settings > Theme > Options windows to turn it off, 2026-11-14; decision 44); what remains of 2 is checking that every other panel follows the theme's Background and nothing is left drawn solid by mistake.
- 3: every colour-plus-opacity pair becomes one colour control (the pairs still need listing).
- 4, 19: one button component at one size and font; the close button and the window's small buttons the same height as buttons, icons centred.
- 8: `/sui` tooltips' descriptions in the normal text colour, not Blizzard's gold.
- 21: the docs spell "color".
- 22: SaftUI's font on every line of item and compare tooltips (find why they show Blizzard's).
- 24: a written spacing scale, and unexplained values moved onto it.
- The loot feed's and other hand-drawn glyphs still to become Lucide icons (the audit's list).

**Being built or planned elsewhere:** 5, 15, 31 to 33 (the edit mode bar: `docs/superpowers/specs/2026-11-13-saftui-edit-mode-bar-design.md`); 9, 13, 17 (the colour control as a field, Copy from beside the Unit dropdown: branch `fb-kit2`); 11, 12 (scaling and the small-text font: their own followup); 25 (overlapping mover labels: in the edit mode bar's plan).

**Shape of work:** Several small tasks (20, 21, 28, 29, 30, 8, 22 are each small) and two projects (the theme-following options window with the accent and one button; the colour roles rename, which is built: decisions 7, 14 and 48, color roles Tasks 1 to 5). Group the small ones into one or two passes.

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
- *Zone grouping, a max height and a scroll frame:* taken up 2026-11-15 by SaftUI's own tracker (`SaftUI-Tracker`) and resolved with its switch on by default; see the Resolved entry "Objective tracker skin: zone grouping, max height and a scroll frame".

**Left out, for later:** a Height setting (sizing the tracker from addon code may taint its layout; only the game can show whether it is safe) and Blizzard's Opacity and Text Size, which SaftUI's edit mode now hides; the large art panels (auto quest popups, the scenario stage, challenge mode and proving grounds banners), the bars' round reward icon, the map pin and find group buttons; standing down for another tracker addon; a default spot clear of SaftUI's minimap and experience bars.

**Shape of work:** The checks first. Then small tasks as the user asks for them; the art panels need a design pass.

### 2026-11-13 — Scale SaftUI across resolutions and stay pixel perfect

**Taken up by** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`. Phase 1 (`docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md`) shipped on 2026-11-15: the scale is set at login and after every change, every line the theme engine draws is whole pixels, and `/sui` has the UI scale section and `/sui scale`. It stays Active until phase 4 ends; what is left is the entries for [phase 2](#2026-11-15--ui-scale-phase-2-the-options-kit-and-saftuis-windows), [phase 3](#2026-11-15--ui-scale-phase-3-edit-mode), [phase 4](#2026-11-15--ui-scale-phase-4-each-addon-4a-to-4g) and [phase 5](#2026-11-15--ui-scale-phase-5-crispness-on-dense-screens), and the friends' checks (E0, E1, E6) and E4.

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

### 2026-11-13 — Test mode: choose which elements the previews show

**What:** Let Test mode show or hide each kind of element on its preview frames: buffs, debuffs, raid markers and so on. Today a group's Test mode (`/sui` → Unitframes → Party, Raid 10, Raid 40 or Boss → Layout → Test mode) draws a fixed set: size, theme, health and power bars, name, role corner and range alpha. It draws no auras, castbars, portraits, raid targets, ready checks or leader icons, so those can't be placed or sized without a real group.

**Why noticed:** The user, after checking the group previews in game (step 7 of the cleanup's in-game checks, 2026-11-13): "Looks good, but can we geet a follow up to improve test mode by being able to show/hide certain elements in test mode? I'm thinking about being able to toggle testing buffs, debuffs, raid markers, etc."

**Anchors:** `SaftUI-Unitframes/grouppreview.lua` (the previews; its header comment lists what is and isn't drawn; `UF:SetGroupTestMode`, `UF.testGroups`, `UF.previews`); `SaftUI-Unitframes/config/groupoptions.lua` (`test_mode`); the element files in `SaftUI-Unitframes/elements/`; `tests/unitframes/` (the group preview tests).

**What's been considered:** The previews are SaftUI's own plain frames, built from the element helpers with made-up data. No unit is faked, so nothing secure is touched and they work in combat. Adding an element means giving the preview that element's frames and made-up data for it: a few sample buffs and debuffs with durations and stacks (a dispellable and a purgeable one, to see the filters' borders), a raid marker on some members, a cast in progress, a ready check, a leader. The single unit frames (player, target, focus, pet) have no Test mode at all; whether they should get one is part of the same question.

**Shape of work:** A design pass first: which elements, whether the choice is one list of checkboxes beside Test mode or per element, whether it's saved in the profile or lasts until `/reload` like Test mode itself, and whether the single frames get previews. Then likely two or three tasks: preview data and frames per element, the options, and tests.

**Open questions:** The ones in the design pass above. Should the sample auras follow each aura group's real filter, or always show?

**Update 2026-11-16:** the unit frame pages now have a Parts section (`SaftUI-Unitframes/config/parts.lua`), and the group pages' Test mode previews follow a part's settings changed in its menu (pinned by `tests/unitframes/group_preview_test.lua`). Which elements a preview draws is still this entry's: the part rows are where a per-element Show for Test mode would sit.

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

### 2026-11-13 — Codebase cleanup: small things left over

**What:** Small things the cleanup's workers and reviewers noticed and set aside, because they were outside the task in hand, needed a call, or needed a look in game. None changes what the user sees unless its line says so. The items that need the user's decision are in [Codebase cleanup: the items waiting on a decision](#2026-11-12--codebase-cleanup-the-items-waiting-on-a-decision), not here.

**Why noticed:** The reviews of the cleanup's 21 tasks and five waves (2026-11-12). They were kept in the run's ledger, which is not versioned, so this entry is their only record.

**Anchors:** Each item names its file. The plan is `docs/superpowers/plans/2026-11-12-saftui-cleanup.md`; the report is `docs/reports/2026-11-12-codebase-cleanup-analysis.md`.

**What's been considered:**

*Tests*
- The nameplate tests copy the whole defaults table for each case; a cheaper `copy_defaults` would speed them up. Test timings were measured across two filesystems and should be measured again on one before anyone tunes them.
- `st:OnBlizzardAddon` (`SaftUI-Core/api.lua`) keeps its waiting list across test cases; the harness has no reset for it.
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
- ~~`SaftUI-Unitframes/nameplates/target.lua`'s comment says the `nameplatetarget` art is in `themeart.lua`; it is in `themeart_data.lua`.~~ *Fixed 2026-11-15 (merge fu-p12).* (The two `PlainNumber` guards in `rollinfo.lua` went the same day, merge fu-p10: the test loads what supplies them.)

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

### 2026-11-12 — Codebase cleanup: the items waiting on a decision

**What:** The cleanup report (`docs/reports/2026-11-12-codebase-cleanup-analysis.md`) found bugs, dead code and refactors. Everything with a clear fix was done under `docs/superpowers/plans/2026-11-12-saftui-cleanup.md` (21 tasks in five waves, merged into `modular`, 343aee8 to 1d69905). What that work set aside is in [Codebase cleanup: small things left over](#2026-11-13--codebase-cleanup-small-things-left-over), and what it needs seen in game is in [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks). The items below were left untouched, because each needs the user's choice or an in-game check first.

**Why noticed:** The user asked for an analysis of the code base (dead code, organization), then said: "Lets work on all the items with subagents that have clear fixes, as for the ones that need my decison for now lets leave them and take a look at them later". This entry is the "later" list.

**Anchors:** the report's sections in brackets.

- **Possible bugs, need an in-game check:**
  - Bags: `INV:SelectBankCategory` (`SaftUI-Bags/inventory.lua`) sets the Character bank type for the `warband` container and Account for `bank`. They look swapped. [1, bug 6]
  - Bags: the `combinedbank` window is offered only when `HasWarbandBank()` is true (`categoriestab.lua`). Intended? [1, bug 7]
  - ~~Core: `TaintFix:OnInitalize` (`SaftUI-Core/taintfix.lua`) is misspelled and never runs. Fixing the spelling alone would error at login (`ClickBindingFrame` is load-on-demand). Fix it properly, or delete the file? [1, bug 11]~~ *Deleted 2026-11-15 (the owner's decision): the file and both Core TOC lines are gone, and `tests/core/toc_files_test.lua` checks that every TOC line names a file that exists.*
- **Writes onto Blizzard frames (taint rule 1), not traced:** `Blizzard_WeeklyRewards.lua`'s `ShouldShowOverlay`, `st:EnableResizing` on `WorldMapFrame`, `st:Kill`'s other callers (see also "st:Kill and st:SkinIcon still write onto Blizzard pieces"), the totem bar's setup on classes with no totems. [1]
- **Migrations that may be finished** (delete once every profile has passed through them): Bags `categories.lua` and `movers.lua`, `CHT:MigratePosition`, `st:ResolveLegacyTemplate` with its seven "defaults look as they did" tests and `T.old_names`. [2.3, 6.3]
- **Features that look unused, keep or delete:**
  - ~~the loot window popup (`SaftUI-Loot/popup.lua`, with its two accidental globals);~~ *Kept and rebuilt 2026-11-15 (the owner's decision, `fb-lootpopup`): it is on again by default, with an Enable, Theme, Background and Font on the Loot window page.*
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

**Checked 2026-11-15:** by design for now, and still latent: nothing can change a box in combat. `/sui` closes as combat starts and won't open in it, and a profile switch by an addon or a macro in combat waits for the end of combat like every unit frame switch (the cached configs point at the new profile at once and the full update follows). Revisit if a path to a box in combat appears.

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
2. Both clients. Strafe and turn past a pack under Thick, Thin and Blizzard: the 1px borders round the health bar, the castbar and its icon, and the debuff and purge buttons stay whole, with no shimmer or doubling, and the name and health text don't jitter against the bar. Under Thick, a debuff's dark inner line stays whole, exactly 1px inside its border, while the plate moves. Make the same check at the friends' scales (1080p, and the Mac's screen), where a line is one pixel at 1080p and two on the Mac and the plates' borders must be whole there too; a UI scale or display change needs no `/reload` now, since SaftUI sets its scale again and pins the plates after it (see step 14).
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
14. With plates up, change Blizzard's UI scale setting (or the window's size): SaftUI puts its scale back on the next frame and pins the plates after it, so they keep their size, their borders stay whole and their click area matches. In combat nothing changes until the fight ends, and then the scale is put back, the plates pinned and their size set once (`.agents/architecture.md`, "The UI scale"). No `/reload` is needed.
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

### 2026-11-11 — Nameplates: a plate that turns widgets-only, or back, without a new add

**What:** oUF hides SaftUI's frame on a plate and pauses its elements only at an add, for a unit whose plate shows only widgets (`UnitNameplateShowsWidgetsOnly`) or a game object. When the game's friendly NPC plates setting changes (SaftUI's Friendly plates sets it), Blizzard runs `UpdateWidgetsOnlyMode` again on the plates already up, so a plate may switch to showing only widgets, or back, with no remove and add. oUF then leaves SaftUI's frame shown over a plate that shows only widgets, or hidden on one that's whole again, until the plate's next add; `UF:RefreshPlateWidgets`, which now also runs on the frame after anyone changes that setting, only places the widgets again and puts SaftUI's click area back on the plates SaftUI still shows (so a plate turned widgets-only in place takes clicks over SaftUI's frame, which still shows, where Blizzard's would take none). Separately, a config update while a plate shows only widgets runs each aura area's `SetEnabled(UF:ElementWanted(...))` on its paused container with the previous unit's kind (`frame.friendly`). That frame is hidden and the next add sets it right, and it was so before the nameplates too (it was `config.enable`).

**Why noticed:** Task 5 of the nameplates plan (branch `np-5`), its report's followups (a) and (c), after its review asked for `UF:RefreshPlateWidgets` and the stubs modelled the switch (`stub.set_nameplate_widgets_only`).

**Anchors:** `SaftUI-Unitframes/nameplates/nameplates.lua` (`PlaceWidgets`, `UF:RefreshPlateWidgets`, `OnPlateEvent`), `SaftUI-Unitframes/nameplates/cvars.lua` (`UF:ApplyNameplateCVars`), `SaftUI-Unitframes/elements/auras.lua` (`UpdateConfig`'s `SetEnabled`), `SaftUI-Unitframes/Libraries/oUF/ouf.lua` (the nameplate driver's widgets-only branch of `NAME_PLATE_UNIT_ADDED`), `tests/unitframes/nameplate_kind_test.lua`, `tests/wow/game.lua` (`stub.set_nameplate_widgets_only`).

**What's been considered:** `UF:RefreshPlateWidgets` could also pause and hide SaftUI's frame on a plate that turned widgets-only, and resume, show and re-apply the kind on one that turned whole, as oUF's add does, through oUF's own `PauseAllElements` and `ResumeAllElements`. Worth it only if the game really switches plates in place.

**Shape of work:** Small, after the in-game check (step 9 of "Nameplates: in-game checks").

**Open questions:** Does a friendly NPC's plate switch modes in place when friendly NPC plates is turned on or off, or does the game remove it and add it again?

### 2026-11-11 — Nameplates: small items left after the build

**What:** Small things the nameplates build noticed and left. One is still open:
- Copy from leaves the nameplates out both ways (Task 6's ruling 3): the game places every plate and gives them one size, and Nameplates and Friendly plates change the game's settings and need a reload, so a copy of General would be wrong, and a unit frame's layout doesn't fit a 200 by 20 bar. A user who wants the target's Health look on the plates sets it by hand. A Copy from limited to the element tabs, without their positions, could be added.

*Fixed 2026-11-15:* the `st:name` tag no longer lists `PLAYER_TARGET_CHANGED` (it gained `UNIT_FACTION`; merge fu-p1); Threat when solo's description now says it also shows the threat percent, in a party or raid both always show (`nameplates/options.lua`, merge fu-p1); the castbar defaults' text offsets are numbers (merge fu-p3). String offsets outside the castbars remain: [Unit frame defaults: string offsets left outside the castbars](#2026-11-15--unit-frame-defaults-string-offsets-left-outside-the-castbars).

**Why noticed:** The reports of Tasks 2, 5, 6 and 9 of the nameplates plan (`.superpowers/sdd/2026-11-11-saftui-nameplates/`, not versioned).

**Anchors:** as each item names.

**Shape of work:** A design question first: whether a Copy from limited to the element tabs, without their positions, is worth adding for the plates.

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

**What:** Since the Categories tab's list and editor scroll on their own, two things in the editor were left as they were. ~~The rule editor's block drag has no edge scroll: the list scrolls while a dragged category is held near its top or bottom edge, but a dragged block held near the editor's edge doesn't.~~ **Fixed 2026-11-15 (merge fu-p6):** a dragged block held near the editor's edge now scrolls it, steadily and in whole pixels, with the list's band and speed (`EdgeStep`, `EditorEdgeScroll` and `w.editorDriver` in `categoriestab.lua`; `tests/bags/categories_drag_test.lua`). And hovering a Caught now icon lights the block that caught it without scrolling the editor to it (on purpose: a scroll on hover would move the icon away from the mouse), so the lit block can be out of view. *Update 2026-11-11 (Blizzard theme round 2, Task 11):* Caught now and Pinned items now sit in a fixed footer at the editor's bottom, so Caught now stays in view under the rule and the icon no longer scrolls with the editor; with the editor scrolled to the block, the block and the icon are in view together. What is left of the second gap: a lit block can still be out of the editor's view when the rule is taller than the editor's view (the tab less the footer), and the wheel over the icon scrolls the footer, not the editor.

**Why noticed:** The 2026-11-11 change that gave the tab its two scroll areas (user feedback, screenshot 112: scrolling the list down to Quest scrolled Quest's editor out of view). The brief asked for the list's edge scroll only, and for the hover not to scroll. Measured then, on the shipped categories at the default window size: the tab is 483 high; only Grays/Auto Vendor (653 on Forever, 697 on retail) and Container (523, 567) need the editor to scroll, and every shipped rule plus the Caught now strip spans at most 457 (Grays), so both fit in view together, but only with the editor scrolled to show both. Those figures are out of date since the footer (the editor's view is the tab less the footer, at most half the tab). A longer rule of the user's still makes the lit block go out of view.

**Anchors:** `SaftUI-Bags/categoriestab.lua` (`EdgeScroll`, `DrawDrag`, `ScrollEditor`, `ScrollFooter`, `SplitFooter`, `HighlightWhy`); `SaftUI-Bags/ruleeditor.lua` (`DrawDrag`, `StartDrag`, the `bagrule` type); `tests/bags/categories_scroll_test.lua` (the scrolling tests; two scrolled drags are in `categories_drag_test.lua`).

**What's been considered:** The edge scroll is built (a driver frame on the tab runs the band test while the rule editor reports a drag, and calls the editor's `drawDrag()` after each scroll so the line follows). For the hover, an arrow or a mark at the editor's top or bottom edge when the lit block is out of view would say where it is without moving anything.

**Shape of work:** The edge scroll is done. The hover marker is a small design question first.

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

### 2026-11-11 — Loot feed: retail item quality text and profession overlay sit under the Blizzard ring

**What:** Under the Blizzard theme, `Util:SetItemQualityLevelText` (`SaftUI-Core/Utilities/itemupgrades.lua`) and the crafting quality overlay are regions of the feed entry. The ring's holder is a child frame at the entry's frame level + 1, so the ring clips the outer 1-3px of the `n/m` text and the pip at the entry icon's top-right corner. Retail only, Blizzard theme only.

**Why noticed:** The Blizzard theme's reviews (2026-11-11), reading `SaftUI-Loot/Feed/feed.lua`: the count already sits on a frame at level + 2 (`over:SetFrameLevel(item:GetFrameLevel() + 2)`), the quality text doesn't. Not checked in game: the user plays Forever, which has no upgrade tracks or crafting quality.

**Anchors:** `SaftUI-Core/Utilities/itemupgrades.lua` (`Util:SetItemQualityLevelText`, `Util:SetItemQuality`); `SaftUI-Loot/Feed/feed.lua` (`Util:SetItemQuality(item, ...)`, the `over` frame); `SaftUI-Bags/slot.lua` (the other caller); `SaftUI-Core/themeart.lua` (`Holder`, the ring's frame).

**What's been considered:** Move the quality text and the overlay to the +2 frame the count uses. `Util:SetItemQualityLevelText` is shared with the bag slots, so the change is wider than the feed: it needs the host frame passed in, and the bag slots' own layering checked.

**Shape of work:** Small, one helper and its two callers; an in-game check on retail.

### 2026-11-11 — Blizzard theme: the bags' rule editor and Categories list keep the options window's own look

**What:** Under SaftUI's theme Blizzard, `/sui` → Bags → Categories is only partly in Blizzard's Settings art. What it borrows from Core takes the Blizzard look: the editor's ordinary rows (Name, On, Show in, Reset, Delete), the lists and check lists its pickers open, the Reset all confirm, and the item strips' icon borders (kind `action`). *Update 2026-11-11 (Blizzard theme round 2, Tasks 5 and 9):* the rule editor's value fields now follow too (the compact Settings dropdown, `W.LookDropdown(field, blizzard, true)`), and the category list's rows are the Settings category list (`Options_List_Active` and `Options_List_Hover`, gold names, white when picked). Still in the options window's `Box` look: the rule editor's text and number boxes, the "whole word" check box, the NOT toggles and the AND/OR badges (`bagrule`); the list's drag handles keep their look.

**Why noticed:** Merging `modular` (the bag categories project) into `blizzardtheme` (2026-11-11). Both were built from modular 8dc348c in parallel: the Blizzard theme gave `/sui`'s built-in widgets Blizzard's Settings art (its spec's ruling 2), while the bag categories added three custom widget types (`W.Define`) that draw their own frames with `W.Box`. The merge brief said to leave them as they were, apart from what follows from the shared helpers, and to note the gap. The merge did give the check list's boxes the Settings check box, since the check list is Core's (`W.OpenCheckList`) and the spec's ruling 3 is one check box look everywhere.

**Anchors:** `SaftUI-Bags/ruleeditor.lua` (`MakeBox`, `MakeField`, `MakeCheck`, the NOT box, `GroupParts`' badge, `MakeAdd`); `SaftUI-Bags/categoriestab.lua` (`ListRow`, `Action`); `SaftUI-Core/Config/optionslook.lua` (`LookInput`, `LookDropdown`, `LookCheckBox`, `LookLine`, `W.LookButton`, `W.BlizzardLook`); `SaftUI-Core/themeart_data.lua` (the sidebar's `Options_List_Active` and `Options_List_Hover`, drawn by `SaftUI-Core/Config/optionsnav.lua`); `docs/superpowers/specs/2026-11-10-saftui-blizzard-theme-design.md` ("`/sui`'s controls under Blizzard"); `.agents/edit-mode.md` (Options window widgets).

**What's been considered:** Most of Core's look helpers are locals of `optionswidgets.lua`. Exporting them on `W` (as `W.LookButton` and `W.LookSearch` already are) would let the bags' widgets call them when they bind: a box as `LookInput`, a field as `LookDropdown` (which wants `button.caret` and `DropdownStates`), the check box as `LookCheckBox`, and the selected category row as the sidebar's `Options_List_Active` with `Options_List_Hover` under the mouse. The NOT toggle and the AND/OR badge have no Blizzard equivalent, so they would take the 1px line the multiselect's box takes.

**Shape of work:** One small task for what is left: the boxes as `LookInput` (exported on `W` as `LookDropdown` was), the check box as `LookCheckBox`, and the NOT toggle and AND/OR badge as the multiselect's 1px line, called from `ruleeditor.lua` at bind, with a Blizzard-and-back test per control in `tests/bags/rule_editor_test.lua` and every cell's rect unchanged under Thick and Thin.

**Open questions:** Should the AND/OR badges keep their blue and orange under Blizzard, since the colors carry the operator?

Also check in game, under Blizzard: the item strips' (Pinned items, Caught now) action ring sits over each icon. `LayItems` (`categoriestab.lua`) moves each icon and its border's frame to new levels on every draw, and the ring's holder is a child of that border frame (`themeart.lua`, `Holder`), so it may end up level with the icon rather than above it. The stubs don't model frame level stacking.

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

### 2026-11-11 — Auto Vendor pins now beat Grays' exclusions and equipment sets

**What:** The old Auto Vendor list wasn't a filter: a listed item still had to get past Grays/Auto Vendor's exclusions, and equipment sets came before it. As a pin, the same entry beats both, so a listed item that is Cosmetic, has the "Fishing" or "Blizzard Account Bound" text, or is in an equipment set now shows in Grays/Auto Vendor rather than in the category it showed in before. Only where it shows changed, not what is sold: whatever an item's pin or rule says, `INV:IsAutoVendorItem` never sells an item that is Cosmetic, has the "Fishing" or "Blizzard Account Bound" text, is in an equipment set, or whose tooltip never arrived (so those words can't be read), nor one that is Protected or has no vendor price.

**Why noticed:** The bag categories project's plan (`docs/superpowers/plans/2026-11-10-saftui-bag-categories.md`, "What can't be written exactly in blocks", item 7), when the Auto Vendor list became pins.

**Anchors:** `SaftUI-Bags/categories.lua` (`INV:MigrateCategories`, `INV:GetItemCategory`'s pin branch, `INV:IsAutoVendorItem`); `tests/bags/category_migration_test.lua`.

**Shape of work:** Only if the user wants such items shown where they were before: have a pin to the selling category lose to the exclusions that used to apply (a rule check in the pin branch, or in the migration), and a test. Selling needs no change.

**Open questions:** Does the user mind a listed Cosmetic, fishing, account-bound or equipment set item showing, unsold, in Grays/Auto Vendor rather than in its old category?

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

**What:** `SaftUI-Chat/chatframe.lua` wrote Lua fields onto Blizzard's chat frames and replaced their scripts, which `.agents/taint.md` rules 1 and 2 forbid. Most of it is fixed (below). What remains:
- `frame:SetScript('OnMouseWheel', onMouseScroll)` on `ChatFrameN` replaces Blizzard's wheel handler. The owner's call.
- On retail, `st:SkinScrollBar(frame.ScrollBar)` (~79) skins Blizzard's `MinimalScrollBar` through `SaftUI-Core/Widgets/scrollbar.lua` (`st:SkinNewScrollBar`), which still writes `.backdrop` and `.thick` (`st:SetBackdrop(thumb, ...)`, ~64) and `.entered` and `.pressed` (the thumb's hover and press state, ~35-50, read by `ColorThumb`) onto the bar's thumb, and `HookScript`s four of its scripts. Under the Blizzard theme the thumb is a control, so SaftUI draws nothing on it and shows MinimalScrollBar's own layers (`DrawScrollBar`), but the writes are unchanged. Core's own scroll frames (`st:CreateScrollFrame`, `SaftUI-Core/Widgets/scrollframe.lua`) are SaftUI's frames, where the writes are fine.
- `st:Kill` and `st:StripTextures` on `ChatFrameNBackground`, `RightTexture`, `ButtonFrame`, the scroll-to-bottom button, the menu and channel buttons and `QuickJoinToastButton` still write `_Show`, `Show`, `_SetAtlas` and `SetAtlas` onto them (Core's `api.lua`); that is the entry [st:Kill and st:SkinIcon still write onto Blizzard pieces](#2026-11-09--stkill-and-stskinicon-still-write-onto-blizzard-pieces-roll-bars-and-elsewhere).

**Fixed 2026-11-15 (merge fu-p11):** the chat frames' backdrop is drawn through `st:SetBackdropIn` into a weak table of chat's (nothing is written onto the frame; the backdrop is still SaftUI's child frame one level under it), the edit box and tab references are in a weak `pieces[frame]` (the Header and HeaderSuffix writes were never read and are gone), the edit box's `OnShow` and `OnHide` are `HookScript`s so Blizzard's own handlers run first, and tab fading is a `hooksecurefunc` post-hook on the tab's `SetAlpha` that reads `chat.tabs.fade` live (the old override wrote a `SetAlpha` field that Blizzard's fade loop read, tainting it). The `owner.thick` write that `st:RedrawThemed` repeated on every profile switch no longer reaches the chat frames or their edit boxes; the unit frames' aura buttons still take it. `tests/chat/theme_test.lua` locks Blizzard's chat window, edit box and tab (`tests/chat/fixtures/chat_window.lua`) so a skin that writes a field fails. Still to check in game: the taint log, chat in combat, a protected slash command, a whisper window, Edit Mode. Blizzard's `OnShow` now runs again, so a stale PARTY, RAID or GUILD chat type resets to SAY when the edit box opens.

**Why noticed:** The Themes project's reviews (2026-11-10). Task 6, which converted chat's draw calls to Theme and Background, carried the chat writes forward as pre-existing; the final review (`008527b..8250a53`) confirmed them and traced the new `owner.thick` trigger to R13's redraw on every profile change. None of the writes was introduced by Themes, which only changed the draw calls' arguments.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:SkinChatFrame`, `CHT:UpdateChatFrameDisplay`, `onMouseScroll`, `CHT:UpdateFootprint`); `SaftUI-Core/skinning.lua` (`st:SkinEditBox`, `st:StyleEditBox`, `DrawEditBox`, `ColorFocused`); `SaftUI-Core/Widgets/scrollbar.lua` (`st:SkinNewScrollBar`, `ColorThumb`, `thumbOnEnter`, `thumbOnMouseDown`); `SaftUI-Core/theme.lua` (`DrawBackdrop`, `st:SetBackdropIn`, `st:RedrawThemed`); `SaftUI-Unitframes/elements/auras.lua` (`StyleButton`, `ColorInnerLine`); `.agents/taint.md` rules 1, 2 and 11; `tests/chat/theme_test.lua`. The tooltip and roll bar skins already moved to side tables (see Resolved), and `tests/lib/locked_widget.lua` locks a frame so a skin that writes onto it fails.

**What's been considered:**
- The wheel: post-hook Blizzard's own handler and add only the Ctrl and Alt cases, if `onMouseScroll`'s behavior (Ctrl to the bottom, Shift a page, Alt a line, else several lines) can run after Blizzard's without scrolling twice; otherwise it needs another approach than a script.
- The aura buttons are the same pattern on Blizzard's frames, but `.agents/taint.md` rule 11 limits what can be anchored there, so they're a separate step.

**Shape of work:** The wheel handler is the one open chat item; the thumb writes are Core's; the aura buttons are a smaller second task. Then an in-game check of chat scrolling.

**Open questions:** Can `onMouseScroll`'s behavior be added on top of Blizzard's wheel handler, or does it need to replace it?

### 2026-11-10 — Edit box focus borders lost on a theme switch, and two ways of keeping colors

**What:**
- ~~A focused chat or bag search box loses its white focus border on a theme switch, and on a profile switch, copy or reset.~~ **Fixed 2026-11-15 (merge fu-p8):** `st:StyleEditBox` runs `ColorFocused` after it redraws the backdrop (`SaftUI-Core/skinning.lua`, `tests/core/skinning_test.lua`). What follows is how it happened. `Config:UpdateConfig` runs `st:RedrawThemed`, whose last step puts the colors kept with `st:KeepOwnColors` back on (the box's white, `ColorFocused`). Then it runs every module's `UpdateConfig`, and Chat and Bags restyle their boxes (`st:StyleEditBox`, which draws the box's backdrop again), painting the theme's border over the white. Nothing puts it back: `st:ColorsChanged('theme')`, which ends the update, calls modules' `OnColorsChanged` but not the kept colors.
- Colors a frame's own code puts on its backdrop are kept two ways. Modules use `OnColorsChanged('theme')`: edit mode's movers (`EM:OnColorsChanged`), and Bags, ActionBars, Loot's feed, Tooltip, the totem bar and Skinning's skins. Core's widgets and the unit frames' aura buttons register with `st:KeepOwnColors`. They run at different points of a profile update, which is what lets the first problem through. Unify them.

**Why noticed:** The Themes project's reviews (2026-11-10). Task 3's review found the focused box losing its border (deferred as minor), and the final review asked for the two mechanisms to become one. `st:KeepOwnColors` came out of ruling R8, which had Core's widgets keep their own colors "as the movers do", without a module to hang `OnColorsChanged` on.

**Anchors:** `SaftUI-Core/theme.lua` (`st:KeepOwnColors`, `PutOwnColors`, `st:RecolorThemed`, `st:RedrawThemed`); `SaftUI-Core/Config/config.lua` (`Config:UpdateConfig`, `RedrawTheme`); `SaftUI-Core/skinning.lua` (`ColorFocused`, `st:SkinEditBox`, `st:StyleEditBox`); `SaftUI-Core/Media/colors.lua` (`st:ColorsChanged`); `SaftUI-Core/EditMode/mover.lua` (`EM:OnColorsChanged`); `SaftUI-Chat/chatframe.lua` and `SaftUI-Bags/inventory.lua` (their `st:StyleEditBox` calls); `.agents/architecture.md`, Themes, "Colors a frame's own code puts on its backdrop".

**What's been considered:**
- The narrow fix, done 2026-11-15: `st:StyleEditBox` runs `ColorFocused` after it draws.
- Unifying: one moment, after every module's `UpdateConfig`, when owned colors go back on. Either `st:ColorsChanged('theme')` also runs the `st:KeepOwnColors` registry (and modules register per-frame callbacks instead of walking their frames in `OnColorsChanged`), or the registry becomes a Core module's `OnColorsChanged('theme')`.

**Shape of work:** The edit box is fixed. A small refactor in Core for the unification, with each module's kept-color tests as the guard (`tests/core/theme_core_frames_test.lua`, `tests/bags/theme_test.lua`, `tests/actionbars/theme_test.lua`, `tests/misc/theme_test.lua`, `tests/loot/theme_test.lua`, `tests/unitframes/theme_test.lua`).

**Open questions:** Unify toward per-frame callbacks, or toward per-module hooks?

### 2026-11-10 — Retail bank leftovers after Themes: category selector, selected window's border, radio group under None

**What:** Three retail-only issues in the bank windows (they use retail's `BankFrame.BankPanel` and the warband bank):
- **The combined bank's category selector** (Bank / Warband, `st:CreateRadioGroup` in `INV:InitializeBankCategorySelection`, `SaftUI-Bags/containers/combinedbank.lua:~28`) takes the Bags Theme and Background once, when it's made. A later change to the Bags Theme override reaches it only after a reload. A change to SaftUI's own theme does reach it, since its buttons are recorded and redrawn with the arguments they were made with.
- **The selected bank window's blue border** (`INV:SelectBankCategory`, `SaftUI-Bags/inventory.lua:~84-86`, for the separate bank and warband windows) is a plain `SetBackdropBorderColor`. No `OnColorsChanged('theme')` or `st:KeepOwnColors` puts it back, so a recolor or redraw turns it into the theme's border, and every Bags `UpdateConfig` resets it too.
- ~~**The radio group's `ColorPicked`** (`SaftUI-Core/Widgets/radiogroup.lua:~19-21`) indexes `button.backdrop`, which a group drawn with a Theme of None (a Bags Theme of None) doesn't have, so clicking a selector button errors. The old `none` template did the same.~~ **Fixed 2026-11-15 (interaction states plan, Task 2):** a radio group's pick is `st:SetState(button, 'selected', picked)`, and nothing indexes `button.backdrop` any more, so a None group has no error (`tests/core/widget_states_test.lua`).

**Why noticed:** The Themes project's reviews (2026-11-10). Task 5 (Bags) found all three and deferred them: the selector as minor, the blue border and the None error as already so before Themes. All three are retail-only, and the user plays Forever, so none could be checked in game during the project.

**Anchors:** `SaftUI-Bags/containers/combinedbank.lua` (`INV:InitializeBankCategorySelection`), `SaftUI-Bags/inventory.lua` (`INV:SelectBankCategory`, `INV:UpdateConfig`), `SaftUI-Bags/container.lua` (the header `OnClick` hook that calls `SelectBankCategory`), `SaftUI-Core/Widgets/radiogroup.lua` (`st:CreateRadioGroup`, `ColorPicked`); `tests/bags/theme_test.lua`, `tests/core/theme_core_frames_test.lua` (the radio group cases).

**What's been considered:**
- The selector: give the radio group a way to restyle (`radioGroup:SetTheme(theme, background)`, redrawing its buttons and keeping the pick), called from the Bags `UpdateConfig`.
- The blue border: register it with `st:KeepOwnColors` on the selected window (forgetting the others), as the radio group does for its pick, or color it again in a Bags `OnColorsChanged('theme')`. This depends on how the "two ways of keeping colors" followup is unified.
- `ColorPicked`: guard `button.backdrop`.

**Shape of work:** Small, two pieces left (the radio group's None error is fixed), with tests where the stubs reach (the bank windows need retail's `BankFrame`), and a retail in-game check.

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

### 2026-11-10 — Bag views: in-game checks for what the stubs can't show

**What:** The bag views (One bag, Multi bag, Compact, Rows, the title-bar switch, and View and Empty slots in `/sui`) were checked by `tests/run` and by reading the code. Some of it needs the real client. Check it in game and fix what's found.

On both clients:
- the four view buttons' icon art at title-bar size: legible, centered, not cropped, at the default Title bar height and at the extremes;
- the header fit in all four windows (bags, bank, warband bank, combined bank), with a 3px gap showing between the view buttons' borders, and to the close button's outline, under Thick and Thin, including a one-column window that widened so its centered title clears the buttons;
- the scroll bar of a window that scrolls, in every view: inside the window's right edge with the same padding as the content has on the left, and gone from a window that fits everything;
- the lit button in the accent against Thick and Thin borders, and after a theme or color change;
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

**Confirmed in game (Forever, 2026-11-10):** the four view buttons' icon art and their spacing (a visible gap between borders, after the polish fix), the lit accent border under Thick, Multi bag's sections in the bag window, the scroll bar inside the window's right edge when it scrolls, and a special bag's title naming its type ("Shipwright's Satchel · Reagent Bag", the middle dot drawn). Still open: the rest of the list above.

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

**Update 2026-11-14:** The role colors were built: Colors > Roles (`colors.roles`: `TANK`, `HEALER`, `DAMAGER`), read by the role corner and the group test previews through `st:Color('roles', role)`, and `UF:UpdateColors` no longer sets oUF's role colors (`docs/superpowers/plans/2026-11-14-saftui-color-roles.md`, Task 1). Rune colors and the class switch stay, and this entry stays Active.

### 2026-11-09 — st:Kill and st:SkinIcon still write onto Blizzard pieces (roll bars and elsewhere)

**What:** Two Core helpers write fields onto the frames they're given:
- `st:Kill` writes `Show`, `_Show` and `SetAtlas`;
- `st:SkinIcon` wrote `__stTexCoord`, plus a hook. *Update 2026-11-11 (commit 28c0448):* it keeps its crop and its hooked flag in weak tables of `skinning.lua`'s, so it now writes nothing onto the icon but its hook. `st:Kill` still writes.

The roll bar skin (`SaftUI-Loot/roll.lua`) calls them on Blizzard pieces: `IconFrame.Border`, `Timer.Background`, `NameFrame`, `Corner`, `IconFrame.Count`, `IconFrame.Icon`. That breaks `.agents/taint.md` rule 1. Other skins likely do the same. Separately, `SaftUI-Loot/popup.lua` wrote `LootFrame.skinned`; *fixed 2026-11-15: the popup is rewritten and calls neither helper (`fb-lootpopup`).*

**Why noticed:** The roll bar side-table fix (2026-11-09) left these alone, because the followup it fixed didn't list them. Both its implementer and its reviewer flagged them.

**Anchors:** `SaftUI-Core` (`st:Kill`, `st:SkinIcon`), `SaftUI-Loot/roll.lua`; grep `st:Kill(` and `st:SkinIcon(` across the repo for Blizzard targets.

**What's been considered:**
- For art: hide with `SetAlpha(0)` or `Hide()` plus a post-hook, instead of replacing `Show` (taint rule 4 and the totem skin's pattern).
- For icons: keep the tex-coord state in a weak table, keyed by the texture (done for `st:SkinIcon` in 28c0448; what is left of it is the hook it puts on the icon).

**Shape of work:** An audit of the callers, then a side-table version of `st:Kill` for Blizzard targets (and a look at `st:SkinIcon`'s hook).

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

**Update 2026-11-16:** the parts are now rows in each unit's Parts section, each with a Position block as the last thing in its menu (`UF.PARTS`); a part placed against the screen is still moved by typing its offsets there, since no mover exists for it. A mover would sit beside the part row.

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
- **Loot:** *(done 2026-11-15, `fb-lootpopup`: the popup is rewritten for today's window and reads `loot.popup.enable`, `.theme`, `.background` and `.font`; `width`, `button_height`, `spacing` and `name_wrap` are gone, since Blizzard sizes the window and its rows.)* `loot.popup.*` (template, font, name_wrap, width, button_height, spacing) was in fact read by nothing. `SaftUI-Loot/popup.lua` isn't in the TOC, and `LT:InitializeLootFrame()` has been commented out of `init.lua` since the Loot addon was added. The skin is also written for the classic loot window (`LootButton1`-`4`, `LootFrameInset`), which current clients don't have, and it writes onto `LootFrame`. Skinning the loot window means a new skin for today's `LootFrame`, with these settings.
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
  - a plain click with no confirmation: **seen in game 2026-11-15** (the owner's debug lines, one click; which choice it was is not known): the bar hid before the post-hook ran (`bar hid: ... choice noted false frame hidden true`, then `choice not noted: ... no shown bar with that roll`), so the client cancels the roll inside `RollOnLoot` (inferred from that order; not read from C code). Not yet seen: the hold working after the fix (`PreClick`, `OnRollPreClick`), each choice, a main spec Need (its 5 second dice animation before the bar hides) and a choice that asks for a confirmation (bind on pickup), where the bar stays up and the post-hook notes the choice;
  - a roll's time: `START_LOOT_ROLL`'s rollTime and `GetLootRollTimeLeft` share a unit (Blizzard's `GroupLootFrame_OnUpdate` clamps one to the other) and `GetLootRollTimeLeft` is documented in milliseconds, so the live bars' countdown, which showed it as seconds, was wrong. `LT.RollSeconds` takes a length over 1000 as milliseconds, and the live and held countdowns both read through it. Look at the countdown in game;
  - `GameTooltip:SetHyperlink` takes the roll's full item link (a held bar's tooltip);
  - does `GetLootRollItemInfo(rollID)` still return the item after you've rolled, until the roll ends? If so, it could end a held roll with no loot history drop when the roll ends. Today such a held roll stays until its time runs out, even once the item is awarded;
  - `/reload` with a roll held drops it: held state isn't saved, and after the reload nothing links the roll to a drop. Decide whether that's acceptable;
  - visuals: a held bar sits exactly where its roll was, at Blizzard's DIALOG strata; its buttons are Blizzard's roll button art (the `lootroll-toast-icon-*-up` atlases), with only your choice's bordered, in the accent, its art inset inside the border; the label sits before the timer; a new roll goes after every bar already up.

**Why noticed:** The loot rolls plan's final review (2026-11-08) listed these as unverifiable outside the game.

**Anchors:**
- `SaftUI-Loot/Feed/rolls.lua`: `RollTimeOver`, `GetOpenDrops`, `CatchUp`, `EstimateWhen`.
- `SaftUI-Loot/rollinfo.lua`: `UpdateRollBars`, `OnRollPreClick`, `OnRollChosen`, `OnBarHide`.
- `SaftUI-Loot/roll.lua`: `LT.RollSeconds`, `LT:HoldRoll`, `LT:LayoutRollFrames`.
- `.agents/clients.md` "Loot rolls".
- `docs/superpowers/specs/2026-11-08-saftui-loot-rolls-history-design.md`.

**Shape of work:**
- In game (Forever, group loot): watch counts through a whole roll, roll two copies at once, `/reload` mid-roll and after, relog, roll on trash. Choose on a roll (each button, and a main spec Need) and watch the held bar until the item is awarded, and let one run out.
- Fix whatever doesn't hold.
- Record what's confirmed in `.agents/clients.md`.

**In game 2026-11-13 and 2026-11-15:** the held bar did not stay up after a choice; fixed (see Resolved: [Loot rolls: the roll bar doesn't hold after a choice](#2026-11-13--loot-rolls-the-roll-bar-doesnt-hold-after-a-choice)). **Next real roll:** with others still rolling, watch the held bar and read `/sui debug`'s lines: first the ones that prove the fix, in order (`choice pending: <id> <type> seconds left <n>`, `bar hid: <id> choice noted false pending true ...`, `held roll <id> choice <type> ...`, `choice held at the bar hiding: <id> <type>`), then (`held roll finished: <id> <why> waiting <n> <winner | all passed | no winner | no summary>`): a `winner` with others waiting, a second or two after the click, means Forever's drop fields are misread. Also look at the countdown (its unit) and the held bar's tooltip, and try a Need and a bind on pickup choice.

### 2026-11-08 — Saved loot feed size in SaftUI_DB

**What:** The loot feed is saved per character in `SaftUI_DB` (AceDB char namespace), which is account-wide, so every character's feed is loaded at every login. 500 roll results with full roll lists come to about 1.6 MB per character at 20 players and 2.8 MB at 40, by the final reviewer's estimate. Several raiding characters could push `SaftUI_DB.lua` to 10 MB or more, parsed at every login and written at every reload.

**Why noticed:** The loot rolls plan's final review (2026-11-08), finding 4.

**Anchors:** `SaftUI-Loot/Feed/history.lua` (`SAVED_FIELDS`, `CopyRolls`), `SaftUI-Loot/Feed/loothistory.lua` (`LT:SummarizeDrop`'s trimmed lists). The reviewer's size estimate script is gone with the session scratchpad.

**What's been considered:** Store each choice's names as one compact string, Pass especially. Cap roll lists. Keep fewer entries for other players' results.

**Shape of work:** Measure first: check `SaftUI_DB.lua`'s size after a raid night. Shrink the saved roll format only if it's large.

**Measured 2026-11-15:** the owner's whole saved file (`SaftUI-Core.lua`, which holds `SaftUI_DB`) is 173 KB; the busiest character's `feed` is 500 entries and 125 KB (about 250 bytes an entry), and only one saved entry holds a roll list so far, so a raid night's cost is still unmeasured. Computed 2026-11-15 by serializing a roll result as SavedVariables writes it (tab-indented, five fields a player, 20-character names): 5 players about 1.0 KB an entry (0.5 MB a character at 500), 20 players about 2.9 KB (1.5 MB), 40 players about 5.5 KB (2.7 MB). This replaces the untested estimate. Left open on purpose: shrinking changes the saved format (a compact Pass string, a cap on roll lists), which wants a number from a real raid night first. Measure again after one: if the file passes about 1 MB, shrink; the cheapest first step is one compact string for Pass names.

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

**What:** The bag window marks the reagent bag's items and empty slots (a green corner wedge), and the Empty Slots category's Grouped mode has one slot for the normal bags and one for the reagent bag. A specialty bag (herb, mining, enchanting, etc.) is treated as a normal bag: its items get no marker, and its free slots are counted in the normal group even though they only take that profession's items. (Part-closed 2026-11-15: Grouped's normal slot used to point at the first free normal-kind slot, which could be in a specialty bag, so dropping a non-matching item on it failed with the game's "That item doesn't go in that container" error. It now prefers a free slot in a bag that takes any item, `INV:GetEmptySlots` in `SaftUI-Bags/category.lua`, with a test in `tests/bags/views_data_test.lua`; the count still includes the specialty bags' free slots.)

**Why noticed:** Brainstorming the reagent marker and Empty Slots category (2026-11-08). The user's problem was telling reagent bag items apart when moving reagents into a new reagent bag and swapping which items stay there. Specialty bags have the same "only some items fit" shape, but the user only raised the reagent bag, so they were left out to keep the change small.

**Anchors:** `SaftUI-Bags/category.lua` (`GetSortedInventory`, the empty slot groups), `SaftUI-Bags/slot.lua` (`AssignSlot`, the marker). `C_Container.GetContainerNumFreeSlots(bagID)` returns the bag's family as its second value (0 for a normal bag).

**What's been considered:** Grouping empty slots by bag family instead of normal/reagent would handle specialty bags with no special cases, and the first free slot of a normal-family bag would then always take any item. The marker would need a colour or shape per family, or one shared "special bag" marker.

**Shape of work:** Small: group by bag family in the empty slot code (so the count says what a normal item can use), and decide the marker for specialty bags.

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
  - ~~Class power: `show_empty` is read (`elements/classpower.lua`) but changes nothing, since oUF already shows every point up to the max.~~ *Fixed 2026-11-15 (merge fu-p3): removed from `config/units/player.lua` and `classpower.lua`; a profile that saved it keeps a harmless leftover.*
  - Focus `castbar.colors.normal = { .5, .9, .7 }`: a list, but `GetRGB` reads the `r`/`g`/`b` that the base default's color fills in, so the focus castbar uses the base color. *Fixed 2026-11-09 (options layout project, Task 9): now `{ r = .5, g = .9, b = .7 }`.*
  - ~~Raid target `position.element = 'Portrait'`: Portrait isn't registered, so the marker anchors to the unit frame.~~ *Fixed 2026-11-15 (merge fu-p3): the key is gone from `config/default.lua`; `UF:GetFrame` falls back to the unit frame as before (`tests/unitframes/unit_defaults_test.lua`).*
  - `widget` (`widget.lua` is commented out of `elements/elements.xml`, and it has no `UpdateConfig`), `portrait` and `aurawatch` (their `RegisterElement` calls are commented out).
- **Errors once on** (*both fixed 2026-11-09:* `colorCustom` reads either color shape through `UF.UnpackColor`, and is applied in `PostUpdateColor` after oUF's recolor on health, power and additional power, with power backgrounds following it. The castbar's `bg` has `alpha`/`multiplier` defaults and is colored from the bar. `tests/unitframes/bar_colors_test.lua`. *Fixed 2026-11-15 (merge fu-p3):* `grouppreview.lua`'s preview path (Test mode's previews) now sets the custom power color's background through `UF.SetPowerBackgroundColor` too):
  - `castbar.bg.enable`: the castbar's `bg` has no `alpha` or `multiplier`, so `UF:UpdateStatusBarElement` calls `bg:SetAlpha(nil)`. Nothing colors the background either.
  - `colorCustom` on health, power and additional power: the `customColor` defaults are plain `{ r, g, b }` lists, and `config.customColor:GetRGB()` errors on them.
- **Half done:** `additionalpower.manaAsPrimary` swaps the size, texture and text settings of the Power and AdditionalPower bars (`UF:UpdateElement`'s `configOverride`). It didn't swap their positions. *Fixed 2026-11-12 (codebase cleanup, Task 2): `UF:UpdateElementPosition(element, configOverride)` now gets the override, so the two bars trade places too. The commented-out `Override` and power's `GetDisplayPower`, which never ran, are gone. What's left is a look in game, by a profile edit: the setting has no `/sui` control.*
- **Looks broken:** additional power defaults to `colorPower = false`, and nothing else colors the bar or its background, so it's white once enabled. Its `/sui` option says so. *Fixed 2026-11-09 (options layout project, Task 9): the default is `colorPower = true`.*

**Progress 2026-11-09:** the additional power bar's color (`colorPower = true`), the focus castbar color (now `{ r, g, b }`) and the health text Deficit defaults (on every unit) are fixed (options layout project 2, Task 9, `e5e4426`), and `colorCustom` and the castbar background were fixed earlier the same day. What's left is the "read by nothing" keys, `show_empty`, Raid target's `Portrait` anchor, and a look at `manaAsPrimary` in game (its position half was fixed on 2026-11-12).

**Progress 2026-11-15 (merge fu-p3):** `show_empty`, Raid target's `Portrait` and the preview's power background are fixed. What's left is the aura keys in the first bullet's list and `manaAsPrimary`, which are the owner's call.

**Why noticed:** On 2026-11-07, while adding Castbar, Class power, Additional power, Buffs, Debuffs and indicator tabs to `/sui` → Unitframes (the user asked to "start adding other UF elements to the config"). The rule for that pass was to expose only settings the element code reads, and note the rest.

**Anchors:** `SaftUI-Unitframes/config/default.lua`, `config/units/focus.lua`, `config/units/player.lua` (`manaAsPrimary`); `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`, `UF:UpdateStatusBarElement`, `UF.UnpackColor`); `SaftUI-Unitframes/elements/additionalpower.lua`, `power.lua`, `health.lua` (`PostUpdateHealth`), `classpower.lua`, `auras.lua`, `elements/elements.xml`; `SaftUI-Unitframes/grouppreview.lua` (the preview path).

**What's been considered:**
- Keys nothing reads can simply be dropped from the defaults. Saved values of them are harmless.
- `customColor`: store it as a color (`CreateColor`), or read it with something like `updaters.lua`'s `UF.UnpackColor`, which takes either shape. Then `colorCustom` and a color picker could go into the Health and Power tabs.
- Castbar background: give it `alpha` and `multiplier` defaults and color it from the bar color, or drop `bg` from the castbar defaults.
- Additional power: default `colorPower = true`, or color the bar in `PostUpdateColor` when oUF passes no color.

**Shape of work:** What remains is dropping or wiring the aura keys, and the owner's call on `manaAsPrimary` (a look in game, then a `/sui` control or removal).

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
2. Blizzard's `UpdateSystemAnchorInfo` copies ChatFrame1's current anchor into Blizzard's saved Edit Mode layout. A Blizzard Save can store SaftUI's placement there. It's harmless while SaftUI-Chat is on, but with it off the chat comes back at that spot instead of Blizzard's. *Decided 2026-11-15 (fu-p11): left as it is, and documented here.*
3. Blizzard clamps the chat frame about 32px from the screen's left and bottom edges (`UpdateClampOffsets`). SaftUI's holder isn't clamped, so dragging the outline into that band leaves the outline and the chat apart.
   *Update 2026-11-10:* the holder is now kept inside SaftUI's screen edge margin (20 by default), and ChatFrame1 follows where it shows (`st:GetClampShift`), so drags stop at the margin. Where the margin is narrower than Blizzard's band, the outline and the chat can still be apart by the difference (about 12px at the left and bottom with the default margin). Not yet confirmed in game.
   *Update 2026-11-13:* fixed (6f12ab9): the chat's holder stops where ChatFrame1's own clamp stops it (`st:KeepHolderInScreenMargin`, which reads the frame's clamp live and hooks `UpdateClampOffsets`), so the outline and the chat stop together. Not yet seen in game. Chat's border sits 10px outside its clamped area, and its default place (30, 30) shows at 32.
4. `CHT:SkinChatFrame` still calls `frame:SetClampRectInsets(0,0,0,0)` on every chat frame, ChatFrame1 included (`SaftUI-Chat/chatframe.lua:67`). Blizzard writes ChatFrame1's clamp again on every layout apply (`UpdateClampOffsets`), so until then the chat and its holder can reach the margin, and then both jump to Blizzard's 32. Nothing splits (the holder reads the clamp live), but it goes against `.agents/taint.md` rule 5 and the comment in `st:KeepHolderInScreenMargin`. Leave ChatFrame1 out of that call, so its band is always Blizzard's. Found by the screen margin fix's review (2026-11-13).
   *Fixed 2026-11-15 (merge fu-p11):* `CHT:SkinChatFrame` skips ChatFrame1 (`if frame ~= ChatFrame1`), so its band is always Blizzard's; the other windows keep their zero insets (`tests/chat/theme_test.lua`).

**Why noticed:** The Task 12 review and the fix round (`.superpowers/sdd/2026-11-06-saftui-edit-mode/task-12-review.md`).

**Anchors:** `SaftUI-Chat/chatframe.lua` (holder, `PlaceChatFrame`, overlay re-anchor); `SaftUI-Core/EditMode/mover.lua` (overlay creation).

**Shape of work:** Items 3 and 4 are fixed and item 2 is documented and left. Item 1 remains: a footprint option in `st:RegisterMover`, small.

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
2. ~~`chat.tabs.fade`: turning fading off replaces `Tab.SetAlpha` on Blizzard's chat tabs at enable. Undoing or redoing that live would mean more writes onto Blizzard frames.~~ **Fixed 2026-11-15 (merge fu-p11):** tab fading is a post-hook on each tab's `SetAlpha` that reads `chat.tabs.fade` live; a profile switch (`CHT:ApplyChatFrameConfig`) and the `/sui` Fade tabs toggle (`CHT:ApplyTabFading`) apply at once, and turning fading on hands a held tab Blizzard's own alpha back.
3. Module on/off switches such as `inventory.enable`, and `minimap.compartment_buttons` (its option already says it needs a reload).
4. ~~Party and raid group headers: their size and layout attributes are set at spawn.~~ **Resolved 2026-11-07** (edit mode Task 15): `UF:ApplyGroupLayout` (`SaftUI-Unitframes/groups.lua`) re-applies every header attribute, resizes the buttons, and re-registers the visibility on option edits and profile switches. In combat it waits for combat to end. Nothing in the headers needs a reload now.
5. ~~Templates, colors, headers and buttons have no options UI, so they're the same in every profile unless the saved variables are edited by hand. Modules re-apply their own templates on a switch, but frames styled once at creation with a fixed template (header bars, close buttons, edit mode overlays, the /sui window) don't pick up a profile's different template colors. `st.template_cache` and `Config:UpdateTemplateConfig` look meant for this, but `UpdateTemplateConfig` reads `self.template_cache` on the Config module (it lives on `st`) and loops without `pairs`, so it never worked.~~ **Resolved 2026-11-10** (Themes): `st.template_cache` and `UpdateTemplateConfig` are gone. Colors have the Colors tab and the theme the Theme tab, and `SaftUI-Core/theme.lua` records every drawn frame. `Config:UpdateConfig`, which every profile switch, copy and reset runs (and the Theme tab, through `st:ThemeChanged`), redraws them all in the profile's theme before the modules update (`st:RedrawThemed`; after combat if in it) and ends with `st:ColorsChanged('theme')`, so the borders modules color themselves come back (`OnColorsChanged('theme')`, `st:KeepOwnColors`). Frames drawn once at creation (header strips, the /sui window, edit mode's overlays, Core's buttons) take a switched-to profile's theme and colors with no reload (`tests/core/theme_core_frames_test.lua`).

**Why noticed:** On 2026-11-07, while making profile switches apply live across all modules and unit frames. The user asked for "update steps for those modules and for unit frames so that everything cleanly changes" on a profile switch, instead of needing a `/reload`. These were the pieces that couldn't be made live cleanly in that pass.

**Anchors:** `SaftUI-Core/Config/config.lua` (`Config:UpdateConfig`), `SaftUI-Unitframes/elements/auras.lua` (`AddGroup`), `SaftUI-Chat/chatframe.lua` (`SkinChatFrame`, `tabs.fade`), `SaftUI-Bags/inventory.lua` (`OnEnable`), `SaftUI-Core/theme.lua` (`st:SetTemplate` and the other draw calls, the drawn-frame record, `st:RecolorThemed`, `st:RedrawThemed`), `SaftUI-Core/Media/theme.lua` (`st:ThemeChanged`).

**What's been considered:**
- Item 3 matches the rest of the UI: module toggles generally need a reload. A "Reload to apply" message on a switch that changes one would be enough.
- For item 2, a `hooksecurefunc` on each tab's `SetAlpha` that re-applies alpha 1 while fading is off would be taint-safe and could follow the profile.
- For item 5, fixing `UpdateTemplateConfig` (`pairs(st.template_cache)`, and recording the latest template per frame) would re-color every templated frame. But it would also reset borders that modules recolor after `SetBackdrop` (bag slot quality, the edit mode overlay, the unit tooltip), so those would need re-applying after it. *Superseded 2026-11-10: the Themes project built that (the drawn-frame record and its recolor and redraw, with those borders put back), and runs it on every profile switch, copy and reset.*

**Shape of work:** Small items, separable: a reload hint for 3 (2 and 5 are done). Item 1 depends on the aura-container research.

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

### 2026-11-16 — The Sourced-from line on a plate page could link to the other page

**What:** With "Use friendly nameplates' settings" checked, the Enemy page shows a centred "Sourced from friendly nameplates" line (and the Friendly page the same for the enemy's). The line is text; it could be a link that opens the other plate page.

**Why noticed:** An owner question from Task 5's review (`task-5-review.md`, "Left for the owner").

**Anchors:** `SaftUI-Unitframes/nameplates/options.lua` (`sourced`, the line at order 2001); `SaftUI-Core/Config/optionsmodel.lua` (a way to reveal a path: `OW:Reveal`).

**What's been considered:** The line's option is a description today; a link needs a row type or a `desc` with a click that selects the other pick through the window (`OW:Reveal` takes a path and opens the unit's page).

**Shape of work:** Small: the line becomes a link row that reveals `Unitframes.friendlynameplate.general` (or the enemy's). A test that the click lands on the right pick.

**Open questions:** Whether a link is wanted, or the line is enough.

**Resolved 2026-11-17:** the line is an `execute` button (same key `sourced`, text, order and hidden rule) whose click calls `OW:Reveal` on the other plate page's own box (Enemy to `friendlynameplate.general.use_enemy`, Friendly to `nameplate.general.use_friendly`). Pinned in `tests/unitframes/friendly_page_test.lua`. It is now a button in General's toggles' panel, no longer a centred fill line: how it looks is the owner's check.


### 2026-11-16 — The TO dropdown names parts by key

**What:** A Position block's TO dropdown on a unit frame lists the unit's parts by their element key ("ReadyCheckIndicator", "RaidTargetIndicator", "AdditionalPower"), not by the names the pages use ("Ready check", "Raid target", "Additional power"). The dropdown is now 136 wide (`selectWidth`), 4 less than it was, so a long key may be cut.

**Why noticed:** An owner question from Task 5's review, with the in-game check "is AdditionalPower cut in the TO dropdown" (checklist section I, step 14).

**Anchors:** `SaftUI-Core/Config/optionsposition.lua` (`toWidth`, `selectWidth`); `SaftUI-Unitframes/config/position.lua` (the anchor choices); `UF.ELEMENT_NAMES` in `SaftUI-Unitframes/config/parts.lua` (the page names); `tests/unitframes/parts_test.lua` (N1: select 136, name box the same, gap 12).

**What's been considered:** Naming the list by `UF.ELEMENT_NAMES` while keeping the saved key (what the part summaries and tooltips already do, "Right of Cast bar: 2, 3"); the name box for a global frame is typed and unchanged.

**Shape of work:** Small: the anchor list's display names, with the keys saved as before, plus a test that every key has a name.

**Open questions:** Whether the owner saw a name cut in game; if not, the keys can stay until someone asks.

**Resolved 2026-11-17:** the dropdown lists an element by `UF.ELEMENT_NAMES` (an element with no name there shows its key) and sorts by the name shown; the saved key is unchanged. Pinned in `tests/unitframes/uf_element_position_test.lua`. The in-game check that "Additional power" fits the 136-wide dropdown is the owner's.


### 2026-11-16 — All units' Position offers anchors some units lack (pre-flight ruling L7 was never built)

**What:** Ruling L7, adopted in the pre-flight, says that on All units a Position's TO list is the elements every member having the part has, and that validate refuses another element. It was never built: no brief carried it and no test pins it. On All units the TO list is every registered element, and `CheckFollowers` only checks for loops.

**Why noticed:** The final review of the plan "unit frames: parts and sharing" (`.superpowers/sdd/2026-11-15-saftui-unitframes-parts-and-sharing/final-review.md`, Minor 1). What the player would see: All units > Name's Position offers Threat, Subtext, ClassPower, AdditionalPower and ReadyCheckIndicator. Picking Cast bar places TargetTarget's, FocusTarget's and PetTarget's names against their unit frame instead, silently (`UF:GetFrame` falls back), and their summaries say "Unit frame".

**Anchors:** `SaftUI-Unitframes/config/position.lua:79-114` (with no unit frame for `'all'` the TO list is every registered element); `SaftUI-Unitframes/config/sharedoptions.lua:261-285` (`CheckFollowers`, loops only); `preflight.md` L7 in the plan's folder under `.superpowers/sdd/2026-11-15-saftui-unitframes-parts-and-sharing/`; `UF.SHARE_MEMBERS`.

**Shape of work:** small. On `'all'`, build the TO list from `UF.SHARE_MEMBERS` that have the part (the intersection of their elements), and in `validate` refuse another element with "TargetTarget, FocusTarget and PetTarget have no Cast bar." A test for each.

**Resolved 2026-11-17:** built (ruling L7): on All units a Position's TO list is the elements every member having the part has (`UF.MembersWith` in `config/sharedoptions.lua`, read by `config/position.lua`), and validate refuses another element naming the units that lack it. Pinned in `tests/unitframes/shared_page_test.lua`.


### 2026-11-13 — Unit frames: shared settings across units, and small parts as menu items

**What:** The action bars' shared-settings model (an "All" entry, own marks, the diff icon, "Apply to: All | Multiple") applied across unit frames, and a unit's texts, icons and small parts drawn as one-line menu items on its General page, cutting Player's tabs from about thirteen to five.

**Why noticed:** The user, 2026-11-13: the Apply to idea "is widely used for options across the action bars (we could also use it elsewhere, like a lot of unit frames changes)", and of the unit frame mockup: "the unitframe change is great". They asked to see the menu with the full unit frame position block (the TO dropdown) "to make sure that's also planned out"; it fits a 400 wide menu (the block is 351 wide).

**Anchors:** `.superpowers/brainstorm/46409-1794604463/content/actionbars-shared-v4.html` (part 2, the mockup), `docs/superpowers/specs/2026-11-13-saftui-actionbars-shared-settings-design.md` ("Later"), `SaftUI-Unitframes/config/`, `SaftUI-Core/Config/optionsposition.lua`.

**Shape of work:** A project of its own, after the action bars prove the kit pieces. Health, Power, Cast bar and Auras keep tabs. Needs its own design round: what "All units" means when units differ so much by default, and whether sharing is per unit group (party and raid) instead.

**Resolved 2026-11-16:** built as the plan `docs/superpowers/plans/2026-11-15-saftui-unitframes-parts-and-sharing.md` (spec `docs/superpowers/specs/2026-11-15-saftui-unitframes-parts-and-sharing-design.md`): a unit's texts, icons and small parts are half rows in a Parts section on its General page (`SaftUI-Unitframes/config/parts.lua`) and each unit has five tabs; an All units entry first in the Unit picker holds the settings the units share (`SaftUI-Unitframes/config/shared.lua`, `sharedoptions.lua`, `units/all.lua`), with own marks, the diff icon, Apply to and `/sui uf restore` and `/sui uf share`; Health text and Power text are in two places; search, the group and nameplate pages are pinned by tests. The owner's decisions are 64 to 70 in `docs/design-system/05-decisions.md`; the in-game checklist is `docs/superpowers/plans/2026-11-15-saftui-unitframes-parts-and-sharing-in-game-checklist.md`. What was left over is in the entries "Search stops at 100 results, so a part's name cuts the last pages", "All units: small rules left open", "Nameplates and All units", "The Sourced-from line on a plate page could link to the other page" and "The TO dropdown names parts by key".


### 2026-11-11 — Old gear's tabard and shirt exclusion never matched

**What:** The old Old gear filter meant to leave tabards and shirts out. It compared the localized slot name with an `INVTYPE_` token, so the test never matched and every tabard and shirt that met the other tests was caught. The category blocks left the test out, and the Old gear block is one of the three ORs of Grays/Auto Vendor's rule, the category that sells: an old uncommon, rare or epic tabard or shirt was sold at the next merchant (the review of the bags package, 2026-11-15, probed it on both clients).

**Why noticed:** The bag categories project's plan (Global Constraints and "What can't be written exactly in blocks", item 5, `docs/superpowers/plans/2026-11-10-saftui-bag-categories.md`), reading `filters.lua` at `8dc348c`.

**Anchors:** `git show 8dc348c:SaftUI-Bags/filters.lua` (`isLegacyGear`); `SaftUI-Bags/categorydefaults.lua` (Old gear); `tests/bags/fixtures/old_filters.lua` (the oracle, which keeps the old behavior).

**Shape of work:** Only if the user wants tabards and shirts kept out of Old gear: a block on the item's equipment slot (an `INVTYPE_` token compared with `GetItemInfoInstant`'s equip slot), and a fixture.

**Open questions:** Does the user want that exclusion at all? It has never worked, so nobody has missed it.

**Resolved 2026-11-15:** the shipped Grays/Auto Vendor rule now ANDs its Old gear block with NOT(Equip slot is `INVTYPE_TABARD`, `INVTYPE_BODY`) (`SaftUI-Bags/categorydefaults.lua`), so a tabard or a shirt is never in Old gear and never sold through it (a gray one is a gray, as before). A profile that has not edited the category's rule picks it up (an edit is stored against the shipped default, and a rename or On edit leaves the rule alone); one that edited the rule keeps its own. Test: `tests/bags/category_defaults_test.lua` (both clients), with fixtures in `fixtures/category_items.lua` marked changed, since the oracle keeps the old behavior.

### 2026-11-15 — A bag window's least width ignores a Window titles change

**What:** A bag window's least width counts its title's width (`INV:HeaderMinWidth`, `SaftUI-Bags/header.lua`), and nothing lays the window out again when Window titles changes. The title itself follows at once (Task 5), so after a change to a wider font the title can run over the buttons until the window is next laid out.

**Why noticed:** Review of fonts Task 5, m6. It already behaved this way for a Fonts tab change to Text; it is more visible now that Window titles applies at once.

**Anchors:** `SaftUI-Bags/header.lua` (`INV:HeaderMinWidth`), `SaftUI-Bags/layout.lua:284` and `:355`, `INV:UpdateContainer`.

**What's been considered:** fonts Task 7 (2026-11-15) looked at it and left it, because the one-line `INV:OnFontsChanged() self:UpdateConfig() end` (which already waits for the end of combat through `st:QueueAfterCombat('Inventory')`) also runs `CategoriesChanged`, a full re-sort of every item, on each step of a Size drag on any font (`st:FontsChanged()` fires on every step), and a narrower re-fit of the least width alone needs `layout.lua`'s held layout (`ReleaseLayout`, `layoutPending`) understood and checked in game. A debounce to one run a frame would cut it but not the re-sort. Task 7 did move the bags' footer texts and search box to Text, so Window titles no longer reaches anything in a window but its title.

**Shape of work:** small, but needs a design look at the layout first: an `INV:OnFontsChanged` that re-fits each open container's least width only (out of combat; a bag window can be protected, so it goes through the combat queue), with a test, and only when the title's font is what changed (its value, or a shared font it names, changed since the last run).

**Resolved 2026-11-15:** `INV:OnFontsChanged` (`SaftUI-Bags/inventory.lua`) asks for a layout with `INV:QueueUpdate(true)`: one update a frame however many steps a font drag takes, which re-lays the window out to its least width (`SizeWindow`, `SectionLineSlots`) with no category rebuild or re-sort, and is held in combat as any layout is. Test: `tests/bags/views_width_test.lua`. Needs an in-game look.

### 2026-11-11 — Bag categories: a Set checkbox is dead while the Equipment sets entry hides the window

**What:** In the Edit view's Show in checkboxes, a `Set: <name>` checkbox unchecked while the Equipment sets entry already hides that window changes nothing. `INV:IsCategoryHidden` returns true for a `Set: ...` key as soon as the sets entry's `hide[windowId]` is set, before it looks at the set's own flag (`filters.categories[windowId]`), so the box is a dead control.

**Why noticed:** The bag categories project's review of Show in (2026-11-11).

**Anchors:** `SaftUI-Bags/categories.lua` (`INV:IsCategoryHidden` and `INV:SetCategoryHidden`, the "Show in" section, `IsSetKey`); the Edit view's checkbox in `SaftUI-Bags/category.lua` (~422-425).

**What's been considered:** Disable or hide the set's checkbox while the entry hides the window, or let a set's own flag win. The first changes less.

**Shape of work:** Small, with a test in `tests/bags/category_migration_test.lua` next to the Equipment sets entry's Show in cases.

**Resolved 2026-11-15:** The Edit view's checkbox of a `Set: ...` category is disabled (still checked, with a tooltip saying why) while the Equipment sets entry hides that window (`INV:IsSetHiddenBySetsEntry`, `INV:UpdateFilterCheckbox`), the first of the entry's two options. Test: `tests/bags/category_migration_test.lua`.

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

**Resolved 2026-11-15:** A mode picked on a level block with no number is kept in the editor alone (`w.levelPick` in `SaftUI-Bags/ruleeditor.lua`, no data change): the row shows it and its boxes, a number typed goes to the bound it needs (between sets both), and any other edit forgets it. Test: `tests/bags/rule_editor_test.lua`.

### 2026-11-15 — Auto Vendor's second question overstates the earlier stacks that leave

**What:** The second question of a visit says how many stacks sold earlier this visit will leave the buyback ("... and N stacks sold earlier this visit will leave the buyback"). Once a visit has already sold more than 12 (after a Sell them to 13 stacks, say) the number is too high: with a 14th stack the question says 2 and the true number is 1. The formula `min(earlier + in flight, earlier + in flight + its own - size)` is right while `earlier + in flight` is 12 or fewer.

**Why noticed:** The re-review of Auto Vendor's fix round 1 (probe N7b, 2026-11-15). It errs on the safe side (the question warns of more than will happen), so it was left for later.

**Anchors:** `SaftUI-Bags/autovendor.lua` (`QuestionText`, the `pushed` figure); `tests/bags/autovendor_sale_test.lua` ("N-2").

**Shape of work:** Small. With `e = tailSold + pendingTail` and `n` the new stacks, only `min(e, size)` of the earlier stacks are still in the buyback, so the number that leave is `min(e, size) - min(min(e, size), max(0, size - n))`; or cap it at `min(n, ...)`. Add a test for a visit past 12.

**Resolved 2026-11-15:** `QuestionText` now counts only the earlier stacks still in the buyback (`min(earlier, size)`) that the new ones push out, so a visit past 12 says 1 where it said 2. Test: `tests/bags/autovendor_sale_test.lua` ("N-2: past 12").

### 2026-11-15 — Auto Vendor counts a fresh purchase in a just-sold slot as a refused sale

**What:** `Account` (`SaftUI-Bags/autovendor.lua`) decides a stack was sold when its slot is empty or holds another item or count. A stack bought from the merchant that is the same item in the same count as one just sold, landing in the slot that stack left before the next pass (2 seconds), reads as a refused sale. `tailSold` is one short, the purchase is sold again with no question, and at a visit already at 12 one stack leaves the buyback list unasked.

**Why noticed:** The re-review of Auto Vendor's fix round 1 (probe L3, "Check of fix round 2", 2026-11-15). All five conditions must hold together: a caught item the merchant sells, the same count, the first free slot being the one just emptied, inside one pass window, and a visit already at 12. The reviewer called it rare and costing one stack, and the owner accepted it for the merge.

**Anchors:** `SaftUI-Bags/autovendor.lua` (`Account`, `Sell`); `tests/bags/autovendor_sale_test.lua`.

**What's been considered:** A bought-back stack in the same slot is harmless to the count (its buyback entry is removed, so the list still matches) but it is sold again, which undoes the buyback. A fresh purchase removes no entry, which is why only it breaks the promise.

**Shape of work:** Small. Record `C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(bag, slot))` in `Sell` and compare it in `Account`: a different GUID counts as sold. `GetItemGUID` is in `ItemDocumentation.lua` on both branches. A purchase has a new GUID; a bought-back stack keeps its GUID (counted as now, correct) or gets a new one (counted twice, which only asks sooner), so the count is never short. Tests need a stub GUID per item. (The optional post-hook on `BuyMerchantItem` and `BuybackItem` is its own entry now: "Auto Vendor: stop the unasked sales once the player buys or buys back".)

**Resolved 2026-11-15:** `Sell` records the stack's `C_Item.GetItemGUID` (in ItemDocumentation on both clients' branches) and `Account` counts a stack in its slot with another GUID as sold, so a fresh purchase landing in a just-sold slot no longer reads as a refused sale and the tail count is never short. The part about ending the unasked sales once the player buys is its own Active entry. Test: `tests/bags/autovendor_sale_test.lua`.

### 2026-11-15 — Forever: Show in > Bank does nothing for the default bank (the combined bank)

**What:** On Forever the bank opens as the combined bank by default (`combinedBank` is on), and that window reads the category's `hide.combinedbank` flag. But Show in in `/sui` > Bags > Categories lists only Bags and Bank there (the warband bank and Combined bank are listed only where `INV:HasWarbandBank()`), so unticking Bank sets `hide.bank`, which the combined bank never reads: the category still shows in the bank the player sees. The flag the combined bank does read can be set only by the window's own Edit view checkbox on a category header (`category.lua`, `INV:SetCategoryHidden(id, categoryName, ...)`), or by a migrated profile.

**Why noticed:** Review of the reset-every-setting Task 5 (2026-11-15). Show in's reset first covered only the listed windows, so a category hidden in the combined bank on Forever stayed "edited" with no reset; the fix there makes Show in's reset and "differs" cover every window a category is hidden in. The older bug (Show in cannot hide a category in the bank Forever actually shows) is separate and unfixed.

**Anchors:** `SaftUI-Bags/categoriestab.lua` (`INV:CategoryEditorOptions`: `windows`, `sorting`), `SaftUI-Bags/categories.lua` (`INV:SetCategoryHidden`, `INV:IsCategoryHidden`, `INV:ShowCategoryEverywhere`), `SaftUI-Bags/category.lua` (the header checkbox), `SaftUI-Bags/movers.lua` (`INV:GetMoverIds`), `tests/bags/categories_editor_test.lua` (Show in's reset test).

**What's been considered:** List the window the bank really is on each client: on Forever, Combined bank in place of (or beside) Bank. Or have Show in > Bank write both `bank` and `combinedbank` while the bank is combined. The reviewer preferred adding the combined bank to Show in on Forever.

**Shape of work:** Small change in `INV:CategoryEditorOptions` (which windows Show in lists and what its labels say) plus a test on Forever that unticking the window the bank is in hides the category there.

**Open questions:** Does Forever's Show in list Combined bank alone, or Bank and Combined bank? What does Bank mean while the bank is combined?

**Resolved 2026-11-15:** Show in (`INV:CategoryEditorOptions`) now lists Combined bank on every client, between Bank and (on retail) the warband bank, so on Forever, where the combined bank is the default bank, unticking it hides the category there; Bank stays for the separate-bank layout. Test: `tests/bags/categories_editor_test.lua`.

### 2026-11-14 — The options kit's keybinding widget doesn't know META or Blizzard's ignored keys

**What:** The `keybinding` widget (`SaftUI-Core/Config/optionskeybinding.lua`) builds a key from `Is*KeyDown` in ALT-CTRL-SHIFT order and a short ignore list; unlike `/sui kb` (`GetConvertedKeyOrButton`, `IsKeyPressIgnoredForBinding`, `CreateKeyChordStringUsingMetaKeyState`) it has no META and doesn't use Blizzard's ignore list, so a Mac player can't bind META chords there and a key Blizzard refuses to bind is tried anyway (the game then refuses it, and the nearest button's Key row says "Can't bind ...").

**Why noticed:** Review of Task 10 of the objective tracker, which uses the widget for its Key row. Pre-existing Core behaviour, out of that task's scope.

**Anchors:** `SaftUI-Core/Config/optionskeybinding.lua` (`Press`, `IGNORED_KEYS`), `SaftUI-ActionBars/keybindmode.lua`, `SaftUI-Tracker/options.lua` (the `key` row).

**Shape of work:** Small: build the key through Blizzard's own functions where they exist, guarded by presence; extend `tests/core/options_fields_test.lua`.

**Resolved 2026-11-15:** the widget's `Press` asks `IsKeyPressIgnoredForBinding` and builds the chord with `CreateKeyChordStringUsingMetaKeyState` where the client has them (META included), keeping the short ignore list and the plain chord (plus META when `IsMetaKeyDown` exists) as the fallback. Test in `tests/core/options_fields_test.lua`; in-game check on a Mac client not possible here.

### 2026-11-15 — Reset walks: the feed's, Minimap's and Micro menu's movers are registered inline, so the tests pin a copy

**What:** The loot feed, the minimap and the micro menu register their movers inside their setup functions, so the walks register copies and a source check pins the key, `configPath` and `defaults` text.

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `SaftUI-Loot/Feed/feed.lua` (`st:RegisterConfigMover(feed, ...)`), `SaftUI-Minimap/minimap.lua`, `SaftUI-Minimap/micromenu.lua`; `tests/loot/theme_test.lua` and `tests/minimap/theme_test.lua` (the `feedSource` and `PinnedTo` checks).

**Shape of work:** Move each registration into a method (`LT:RegisterFeedMover()`, as `LT:RegisterRollMover()` and `CHT:RegisterChatMover()` are) that the world calls. Three small changes and the source checks go.

**Resolved 2026-11-15:** the registrations are methods now (`LT:RegisterFeedMover`, `MM:RegisterMinimapMover`, `MicroMenu:RegisterMicroMenuMover`), called by the setup and by the walks in `tests/loot/theme_test.lua` and `tests/minimap/theme_test.lua`; the source checks are gone.

### 2026-11-15 — Blizzard's tracker: the Position reset is tested on Forever only

**What:** The default differs by client (`y_off` -275 or -260); the test runs on Forever. A retail run on the scratch check gave -260, which is right.

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua` (`st:DefaultTrackerPosition()`), `tests/misc/objective_tracker_position_test.lua` ("Blizzard's tracker's Position resets to Blizzard's spot").

**Shape of work:** Run that case for both clients, as the walk cases of Action bars and the Tracker now are.

**Resolved 2026-11-15:** the case in `tests/misc/objective_tracker_position_test.lua` runs on both clients and pins each one's `y_off` (-275 Forever, -260 retail).

### 2026-11-15 — Buffs and debuffs: Size and Outline keep hand defaults a derived one would replace

**What:** The Duration and Stack count Font rows take their default from where they are saved; their Size and Outline rows still have hand `default` tables over `st.defaults`.

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua` (`AP:GetTextOptions`, the `for _, field in ipairs({ 'size', 'outline' })` loop), `tests/misc/buff_text_font_default_test.lua` (the Size and Outline resets case).

**Shape of work:** Delete the loop; the group's `saved` (`SavedIn('auras', key, kind)`) derives both, and a derived reset runs the group's `set` (`Apply`), as the hand one does. The case in `buff_text_font_default_test.lua` moves to the kit's calls.

**Resolved 2026-11-15:** the hand `default` tables are gone; both rows reset from the group's `saved` (derived), through the group's `set`. `tests/misc/buff_text_font_default_test.lua`'s Size and Outline case now reads the kit's `OM.DefaultSource`, `DefaultDiffers`, `SourceState` and `DefaultReset`.

### 2026-11-15 — Buffs and debuffs: Wrap's hand reset copies the General group's set

**What:** Wrap's hand `reset` repeats the body of the General group's `set` instead of calling it.

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua` (`default` on `args.wrap`), `tests/misc/options_pages_test.lua`.

**Shape of work:** A shared local function for the write and the refresh, called by `set` and by the reset.

**Resolved 2026-11-15:** the General group's `set` and Wrap's reset both call one local `SetGeneral(option, value)` (the write and the refresh).

### 2026-11-15 — Buffs and debuffs: one helper for the wrap the layout keeps, so the layout and Wrap's default cannot drift

**What:** `GetGeometry`, `WrapForGrow`'s last line and `DefaultWrap` each repeat the fallback (`horizontal and 'DOWN' or 'LEFT'`).

**Why noticed:** Reviews of the reset-every-setting plan (Tasks 3 to 8); the plan's Task 8 left it, as small and independent of the plan.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua` (lines about 129, 163-170 and 203-209), `tests/misc/options_pages_test.lua` (the Wrap cases).

**Shape of work:** One local `WrapInUse(grow, wrap)` used in all three; the existing Wrap and Grow cases pin it.

**Resolved 2026-11-15:** `WrapInUse(grow, wrap)` in `Blizzard_BuffFramePosition.lua` is the one fallback; `GetGeometry`, `WrapForGrow` and `AP:DefaultWrap` all call it. The Wrap and Grow cases in `tests/misc/options_pages_test.lua` pin it.

### 2026-11-15 — A roll result line's All passed and winner color are baked in at push

**What:** A roll result's feed line (`Feed/rolls.lua`, `ResultText`) builds its right text once, at push: "All passed" in Loot > Pass, or the winner's name in their class color. A shown line, and a saved one after a reload, never follows a change to Loot > Pass or to a class color, though the Pass row's description names "All passed (on the feed line and in its roll tooltip)".

**Why noticed:** Review of the live colors Task 6 (Loot). The audit and the brief didn't list this reader, so the task made the feed's item names and progress bars live and left this one. Context: the plan's goal is that every Colors page color reaches every SaftUI reader on screen as the picker is dragged.

**Anchors:** `SaftUI-Loot/Feed/rolls.lua` (`ResultText`, `BuildRollEntry`), `SaftUI-Loot/Feed/feed.lua` (`LT:ColorFeed`, `LT.FeedItemName`), `docs/superpowers/plans/2026-11-15-saftui-live-colors.md` Ruling 15, `.superpowers/sdd/2026-11-15-saftui-live-colors/task-6-review.md` (m4).

**What's been considered:** The same shape as the item names: the entry already keeps `rolls`, so keep it and build the right text at draw (`LT.RollResultText(info)`), and have `ColorFeed` set it again for `loot` (nil or `pass`) and `class`. A class color change then reaches only the lines with a winner.

**Shape of work:** Small: one function moved out of the push, one branch in `ColorFeed`, a test beside `live_colors_test.lua`'s feed cases; saved entries already hold `rolls`, so restored lines follow too.

**Open questions:** Whether the roll tooltip's lines (colored when shown) need a change: they read the color each time they open, so probably not.

**Resolved 2026-11-15:** a roll result's entry keeps its `rolls` and no `rightText`; the line's right text is built as it draws (`LT.RollResultText`, `Feed/rolls.lua`), and `LT:ColorFeed` sets it again for Class and Loot > Pass (only the lines it names), so shown, new and restored lines follow. Tests in `tests/loot/live_colors_test.lua` (the cost case includes both passes).

### 2026-11-15 — Chat's Fade tabs: ChatFrameUtil.GetTabAlphas isn't in the retail source

**What:** Turning Fade tabs on hands a tab SaftUI was holding at alpha 1 Blizzard's own alpha back, read with `ChatFrameUtil.GetTabAlphas(tab)` (`CHT:HoldTabAlpha`, `SaftUI-Chat/chatframe.lua`). The function is in Forever's source (`Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua`, `origin/forever`) but a search of the local clone of Blizzard's `origin/live` (checked 2026-11-15) finds no `GetTabAlphas`; retail keeps the alphas in the tab's own `mouseOverAlpha` field instead. The code is guarded (`if ChatFrameUtil and ChatFrameUtil.GetTabAlphas`), so on retail the tab would stay at 1 until Blizzard's next fade rather than error.

**Why noticed:** The fu-p11 review said the function exists on both clients; the implementer had not checked, and the merge's doc pass did.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:HoldTabAlpha`), `tests/chat/theme_test.lua` (the profile and toggle cases); Blizzard's `FloatingChatFrame.lua` `FCFTab_UpdateAlpha`.

**Shape of work:** Small: on a client without the function, read the tab's `mouseOverAlpha` and `noMouseAlpha` fields, or let Blizzard's next fade restore it (today's behavior).

**Open questions:** Confirm in game on retail that turning Fade tabs on restores the alpha at once. The local `origin/live` clone may be older than the client.

**Resolved 2026-11-15:** not a gap: the retail source (12.1.5.70783) has `ChatFrameUtil.GetTabAlphas` and `SetTabAlphas` in `Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua`, the same file as Forever's (1.60.1.70938), and `FCFTab_UpdateAlpha` fills them on both; the earlier search was of an old clone, and retail has no `mouseOverAlpha` tab field. `.agents/clients.md` is corrected. The existence guard in `CHT:HoldTabAlpha` stays (harmless). The Fade tabs tooltip ('lets them fade from the next time you hover the chat') is accurate, not a reload warning: the toggle gives the tab Blizzard's alpha at once and `tests/chat/theme_test.lua` pins that it never says reload. Not yet seen in game on retail.

### 2026-11-15 — Chat: the dock hook adds a second anchor to docked tabs 2 to n, and the dock test can't see it

**What:** `CHT:FCFDock_UpdateTabs` (`SaftUI-Chat/chatframe.lua`) calls `tab:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 0, 0)` on tabs 2 to n without `ClearAllPoints`, after Blizzard's own `ClearAllPoints` and `SetPoint('LEFT', prev, 'RIGHT', 1, 0)` on a forced update, so those tabs carry two anchors. It predates the chat work.

**Why noticed:** The fu-p11 review. `tests/chat/dock_test.lua` now runs a stand-in of Blizzard's `FCFDock_UpdateTabs` before the hook, but the stand-in sets no anchors, so the test cannot see the second one. The owner found the tabs right in game on 2026-11-13, so it looks harmless.

**Anchors:** `chatframe.lua` `CHT:FCFDock_UpdateTabs`; Blizzard's `FloatingChatFrame.lua` `FCFDock_UpdateTabs` (Forever about 2342-2368); `tests/chat/dock_test.lua`.

**Shape of work:** Small: make the test's stand-in set Blizzard's anchors and assert `GetNumPoints()`; if two anchors matter, `tab:ClearAllPoints()` for every tab in the hook.

**Resolved 2026-11-15:** `CHT:FCFDock_UpdateTabs` clears every tab's points before its own anchor, so a docked tab has the one anchor instead of Blizzard's `LEFT` one and SaftUI's `BOTTOMLEFT`; `tests/chat/dock_test.lua`'s stand-in now sets Blizzard's anchors and the cases assert `GetNumPoints() == 1`. Not yet seen in game: the gap between tabs is the hook's 0, where Blizzard's anchor had 1. A tab Blizzard anchors to the dock's scroll child (the first one past the static ones) keeps that anchor, so an overflowing row still scrolls.

### 2026-11-15 — Chat's edit box can sit off the top of the screen when the chat Theme is None

**What:** At first skin under chat Theme None `backdrops[frame]` is nil, so the edit box is anchored `SetPoint('BOTTOMLEFT', nil, 'TOPLEFT', 0, 1)`. A nil relative frame means the box's parent, which Blizzard sets to UIParent (it reparents the box in `ChatFrameEditBoxMixin:OnLoad`), so the box sits above the top of the screen. A later switch to another theme makes the backdrop but never re-anchors the edit box or the scroll bar: only `SkinChatFrame` anchors them.

**Why noticed:** The fu-p11 review. The code before it behaved the same (`frame.backdrop` was nil), so it is older than the chat work.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:SkinChatFrame`, `UpdateChatFrameDisplay`).

**Shape of work:** Small: anchor the box and the scroll bar from `UpdateChatFrameDisplay` (to the backdrop, or to the chat frame under None) so every theme change places them.

**Open questions:** Needs an in-game look first: chat Theme None, `/reload`, where is the box?

**Resolved 2026-11-15:** `CHT:UpdateChatFrameDisplay` now anchors the edit box and the scroll bar, to the backdrop when a look is drawn and to the chat window under None (`SkinChatFrame` no longer does, with a nil relative frame), so every theme change places them; `tests/chat/theme_test.lua`, whose fixture now parents the edit box to UIParent as Blizzard does. Not yet seen in game.

### 2026-11-15 — getHealthPercentText's floor branch is never used

**What:** `getHealthPercentText(perc, precision)` in `SaftUI-Unitframes/elements/health.lua` has a branch for no precision that floors the value, but its only caller passes precision 1 (Boss percent). Since Percent on a plain health now rounds with `'%.0f'` to agree with the secret path, nothing floors anywhere.

**Why noticed:** The fu-p1 review (merge fu-p1).

**Anchors:** `SaftUI-Unitframes/elements/health.lua`.

**Shape of work:** A one-line cleanup: drop the branch, or make the function the one place both percent paths round through.

**Resolved 2026-11-15:** the function is gone: its one caller (Boss percent) formats the value with one decimal in place; no behavior change.

### 2026-11-15 — Two lines of the profile switch fix that no test pins

**What:** Two lines of the fu-p2 fix round pass every test when removed. (1) `RestoreNameplateCVars` clearing `UF.appliedFriendly` (`SaftUI-Unitframes/nameplates/cvars.lua`): the case it guards is Nameplates turned off with the reload declined (the user's values go back), then a switch to a profile with Nameplates on and the same Friendly plates; SaftUI's settings should be set again, and without the line they stay the user's while SaftUI's plates are up. (2) `RefreshFrameConfig` before `UF.ClearPlacedPoints` in the plate loop of `UF:ApplyConfig` (`SaftUI-Unitframes/unitframes.lua`): without it the clear reads the old profile's cached Enable for a text or icon, which matters only for a loop through a text or icon (typed by frame name), so it is low value.

**Why noticed:** The fu-p2 re-review of the fix round (its N2). The code is right in both cases; only the tests are missing.

**Anchors:** `tests/unitframes/profile_switch_test.lua`, `tests/unitframes/nameplate_page_test.lua`, `tests/unitframes/friendly_plate_test.lua`, `tests/unitframes/friendly_plate_size_test.lua`.

**Shape of work:** Small: the Nameplates off then on case in `profile_switch_test.lua`, and a case where a text is on in one profile and off in the other.

**Resolved 2026-11-15:** `profile_switch_test.lua` pins both: the Nameplates off then on case (the restore forgetting `UF.appliedFriendly`) and a text switched on by a switch that replaces the bar's config table (the refresh before `UF.ClearPlacedPoints`); each fails with its line removed.

### 2026-11-15 — Unit frame defaults: string offsets left outside the castbars

**What:** The castbar defaults' text offsets are numbers now (merge fu-p3), but other defaults still have string offsets, which the game accepts and the strict stubbed `SetPoint` refuses: the portrait and the additional power position in `SaftUI-Unitframes/config/default.lua`, and buffs in `config/units/arena.lua` (boss's are numbers now: the resets task). A profile that saved the string form keeps it.

**Why noticed:** The fu-p3 report, finishing item 2 of [Nameplates: small items left after the build](#2026-11-11--nameplates-small-items-left-after-the-build) for the castbars only (the brief named only those).

**Anchors:** `SaftUI-Unitframes/config/default.lua`, `config/units/arena.lua`; `tests/unitframes/unit_defaults_test.lua` (checks every unit's castbar offsets are numbers).

**Shape of work:** Small: make them numbers and extend the test over every position in the defaults.

**Resolved 2026-11-15:** the portrait's and additional power's positions in `config/default.lua` and arena's buffs are numbers; `unit_defaults_test.lua` now checks every position offset in every unit's defaults.

### 2026-11-15 — Unit frames: a part switched off in the new profile keeps its old points

**What:** A part switched off in the new profile keeps its old points on a unit frame and can still close an anchor loop (profile A: Power on, under Health; profile B: Power off, Health hung from Power: Health's `SetPoint` errors and it is left with no points). Pre-existing. Test mode's previews have the opposite edge: `StylePreviewFrame` clears every preview element and all its texts, but a preview places only the parts that are on, so a preview part hung from a switched-off part is left anchored to a region with no points and won't draw (inferred: the stubs don't model the rect), while the real boss frame keeps the old points and shows that part. Test mode only, and it needs a part hung from a switched-off one.

**Why noticed:** The fu-p2 review (finding m1, and N1 of its re-review), after the fix that clears each frame's enabled parts before a profile switch places them. The comment at `grouppreview.lua:160` ("as for the real frames") doesn't hold for it.

**Anchors:** `SaftUI-Unitframes/unitframes.lua` (`ClearPartPoints`, `ClearAllPartPoints`), `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, the `unitframe.isNamePlate` condition), `SaftUI-Unitframes/nameplates/nameplates.lua` (`ClearPlacedPoints`), `SaftUI-Unitframes/grouppreview.lua` (`StylePreviewFrame`), `tests/unitframes/profile_switch_test.lua`, `tests/unitframes/boss_preview_test.lua`.

**What's been considered:** Place a disabled named part by its config on unit frames too (drop the `unitframe.isNamePlate` condition in `UF:UpdateElement`) and clear every element, as `ClearPlacedPoints` does for plates. For the previews, use the real frames' rule: clear an element only when `element:GetConfig().enable` is true, and its texts only when theirs is (export `ClearPartPoints` and call it on the preview frame, whose elements would need to be `previewElements`); or only note the case here.

**Shape of work:** Small: one rule for which parts a clear touches, shared by frames and previews, and a test with a part hung from a switched-off one.

**Open questions:** Whether a disabled part should be placed at all, or the clear should skip it as the real frames do.

**Resolved 2026-11-15:** `UF:UpdateElement` now sizes and places a switched-off named part by its config on unit frames and previews as on plates, and `ClearPartPoints` clears every element, so no part keeps the old profile's points; pinned in `profile_switch_test.lua` and `boss_preview_test.lua`. The owner's open question is answered as the entry recommended (place it).

### 2026-11-15 — Unit frames: a vehicle power type with no oUF color falls back to Mana

**What:** Power reaches a frame by its unit's power token. A unit whose token oUF has no color for (a vehicle's power type) falls back to Mana's color in oUF's `power.lua`, so a Mana pick misses that frame. Rare; the edit's whole pass covers it.

**Why noticed:** Review of the live colors Task 3, `.superpowers/sdd/2026-11-15-saftui-live-colors/task-3-review.md`, n4.

**Anchors:** `UF.ColorReaches` (the `power` branch), oUF's `Libraries/oUF/elements/power.lua` (read only).

**What's been considered:** Treat a token with no oUF color as `MANA`.

**Shape of work:** one line in `UF.ColorReaches` and a test.

**Open questions:** none.

**Resolved 2026-11-15:** `UF.ColorReaches`' power branch reads a token oUF has no color for (and no game color) as `MANA`; `tests/unitframes/color_cost_test.lua` pins it (its stand-in oUF now holds the colors and oUF's power-type aliases for the tokens it uses). Fix round 1: it follows oUF's whole order (the token's color, the game's own color, the power type's, Mana's) by comparing oUF's tables, guarded against secret values.

### 2026-11-15 — Unit frames: a color oUF lacks is set to the profile's own table

**What:** `CopyColor` (`SaftUI-Unitframes/unitframes.lua`) sets a color oUF has none of to the profile's own table, as `st.tablemerge` did. A later profile switch's merge then writes the new profile's values into the table of the old profile. It matters only if oUF lacks a SaftUI color key in game (the test world lacks every key); which keys, if any, is unchecked.

**Why noticed:** Review of the live colors Task 3, `.superpowers/sdd/2026-11-15-saftui-live-colors/task-3-review.md`, n3. The behavior is older than the task; the commit kept it.

**Anchors:** `UF:UpdateColors`, `CopyColor`, oUF's `Libraries/oUF/colors.lua` (read only), `st.config.profile.colors`.

**What's been considered:** Copying into a new color object (`UF.oUF:CreateColor`) instead of aliasing would make it safe.

**Shape of work:** list the keys SaftUI's Colors page has that oUF's table lacks, and make the fallback a copy.

**Open questions:** whether any key is missing in game.

**Resolved 2026-11-15:** `UF:UpdateColors` (the whole pass's merge and `CopyColor`) now copies a color oUF lacks instead of aliasing the profile's table; `tests/unitframes/colors_test.lua` pins both paths and the old profile staying untouched after a switch. The copy is made by `oUF:CreateColor` (it has oUF's methods, so a Gradient on a token oUF lacks, such as Steam, Pyrite or Alt power, doesn't error), and the whole pass is pinned to merge in place. Left: the by-key `CopyColor` assumes a color-shaped (r, g, b) profile table, which AceDB always fills and every default is; a list-shaped one would write nils.

### 2026-11-15 — Two Misc readers break "a pass only colors"

**What:** the zone text's color handler calls `SetPoint` on Blizzard's `SubZoneTextString` and makes about 1 KB a pass; the experience bar's Reputation handler calls `Show` and makes about 1.1 KB a pass. Both break the live colors spec's rule that a pass only colors, and no task owns either file.

**Why noticed:** the review of live colors Task 7 (Misc's skins, the tooltip and SaftUI's tracker) probed every Misc reader with the cost helper (`tests/lib/color_cost.lua`). The spec calls both readers "as today", so neither task 7 nor any other task of that plan changed them.

**Anchors:** `ZT:OnColorsChanged` in `SaftUI-Misc/Skinning/blizzard/ZoneText.lua` (on any Text key or Factions, while the zone text shows, it runs `UpdateZoneLine`: a `SetPoint` on `SubZoneTextString`, a `SetText`, about 1.07 KB a pass, `SetPoint` 100 times over 100 passes); `XP:OnColorsChanged` in `SaftUI-Misc/experience.lua` (on Reputation it runs `UpdateReputation`: `Show`, `SetMinMaxValues`, `SetValue`, about 1.1 KB a pass, `Show` 100 times over 100 passes); `.agents/taint.md` rule 1 on Blizzard frames; the plan `docs/superpowers/plans/2026-11-15-saftui-live-colors.md` ("A pass only colors").

**What's been considered:** neither frame is secure or tainting, so nothing is broken in the game today; the cost is the point. A zone line that only needs its color could set the font string's color (the color is the only thing a Factions or Text pass changes) instead of laying the line out again, and the reputation bar's pass could set the bar's color without `Show` or its range.

**Shape of work:** small: two handlers cut down to color setters, each with a cost case (`C.measure`, forbidden 0, `kb < 4`) in `tests/misc/zone_text_test.lua` and `tests/misc/experience_test.lua`.

**Open questions:** whether the zone line's color is held apart from its text (it may be one `SetText` with an escape), which would decide if the pass can color alone.

**Resolved 2026-11-15:** live colors Task 11's fix round. `XP:OnColorsChanged` recolors the shown reputation bar only (it keeps the group and standing the bar wears: no `Show`, range or value, nothing made); `ZT:RecolorZoneLine` (Text and Factions passes) sets the line's color and makes the faction text again only when its color changed, and never calls `SetPoint`. Cost cases in `tests/misc/experience_test.lua` and `tests/misc/zone_text_test.lua` (nothing forbidden, nothing made, under 4 KB over 100 passes).

### 2026-11-11 — UIParent's scale is set once, at login, so plates leave whole pixels after a UI scale or display change

**What:** Core works out `st.scale` once, as 768 over the screen's physical height when `SaftUI-Core/constants.lua` loads (`GetPhysicalScreenSize`), and sets it on UIParent once, in `SaftUI:OnEnable` (`SaftUI-Core/init.lua`), so that one UIParent unit is one pixel. Nothing sets it again. After Blizzard's UI scale setting changes, or the display does (a resolution or window size change), UIParent may no longer be at 768 over the screen's height. The nameplates pin each plate's frame to UIParent's effective scale, and pin every plate again on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (`SaftUI-Unitframes/nameplates/pixels.lua`), so they follow UIParent; but then a plate isn't a whole number of pixels wide or tall, and its right and bottom edges can flicker by a pixel either way as it moves, until a `/reload` sets SaftUI's scale again. Everything else of SaftUI's, laid out with one unit to a pixel, is off the grid the same way until then, so the README's "ignores Blizzard's UI Scale setting" holds only from one login to the next.

**Why noticed:** The review of Task 11 of the nameplates plan (whole-pixel plates, branch `np-11`). Its test for a UI scale change re-pins the plates, which keeps them on UIParent's scale, but whole pixels need UIParent itself at 768 over the screen's height.

**Anchors:** `SaftUI-Core/constants.lua` (`st.screenWidth`, `st.screenHeight`, `st.scale`), `SaftUI-Core/init.lua` (`SaftUI:OnEnable`), `SaftUI-Unitframes/nameplates/pixels.lua` (`UF:PinPlateScale` and its event frame), `UF.PlateDriverSize` (`SaftUI-Unitframes/nameplates/nameplates.lua`), `tests/unitframes/nameplate_pixel_test.lua` ("a UI scale change re-pins every plate and re-applies the size"), the README's Installation section.

**What's been considered:** Re-pinning the plates can't fix it alone: they follow UIParent, whatever its scale. The fix belongs in Core: on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED`, work `st.scale` out again from `GetPhysicalScreenSize()` and set it on UIParent, then pin the plates again after it. Two frames' handlers for one event run in no set order, so the plates must be pinned after Core's handler (Core could call `UF:PinPlateScale` through the unit frames, or the plates could pin on the next frame). Whether Blizzard's own handling of its UI scale setting sets UIParent's scale after SaftUI's, and whether `UIParent:SetScale` is allowed in combat, decide the details.

**Shape of work:** Small, in Core: one event frame that re-applies `st.scale` on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (waiting out combat if it must), the plates pinned after it, a test with the stubbed screen size, and an in-game check (step 14 of "Nameplates: in-game checks").

**Open questions:** Does a change to Blizzard's UI scale setting set UIParent's scale over SaftUI's, on each client? Is `UIParent:SetScale` refused in combat?

**Resolved 2026-11-15:** the scaling design's phase 1, Task 4. UIParent's scale is set again on every change, and the plates pin after it, from `UIScale:OnChanged`.

### 2026-11-15 — A reset on every font row

**What:** `generators.font` takes no default, so a font row has a reset icon only where its page builds `default` by hand (`FN.FontSettingDefault`: the Fonts tab's Kinds of text rows, Theme > Window titles, and All bars' texts through the action bars' own `TextDefault`). Every other Font row (the tooltip's, chat's, Skinning's, the bags', the loot's, the tracker's, the unit frame elements') has none. The buffs' Duration and Stack count rows and the totem bar's Timer font row got one in the feedback round (2026-11-15). Give `generators.font` the default, and have it build `default` through the inherited `get` and `set`, as the number inputs do.

**Why noticed:** The fonts design's "Later" list. The rule is a reset per setting (`docs/design-system/10-discrepancies.md`, 17), and a font row is a setting like any other.

**Anchors:** `SaftUI-Core/Config/generators.lua` (`generators.font`, the number inputs' `default`), `SaftUI-Core/Media/fonts.lua` (`FN.FontSettingDefault`), `SaftUI-Core/Config/optionsshare.lua` (`DefaultText`'s `font` branch), and each page's `generators.font(` call (grep it).

**What's been considered:** The row's `differs` is any value but the default (a table always differs), its `reset` writes the default and runs `st:FontsChanged()`, and its `text` is `st:FontLabel(default)`: `FN.FontSettingDefault` already does that. What's missing is each page's default value, which `st.defaults` holds, and a rule for rows that read a copy (the action bars' and buffs' texts, face only).

**Shape of work:** Small to medium: the generator, then each page's call with its default; tests per page that the icon shows only when the value differs. One ticket.

**Open questions:** What the face-only rows (the action bars' and buffs' texts) reset to, which follows the Small text followup above.

**Resolved 2026-11-15:** every font row takes its default from where it is saved (reset-every-setting, Tasks 1 to 7).

### 2026-11-14 — Categories tab at full size: a long "Reset <name> to default" overlaps Delete

**What:** In the bags' Categories editor, the Reset button's label is `Reset <category name> to default`. For a long name the button is wider than its half-line slot and overlaps Delete beside it. The shipped default "Death Knight/Warlock/Demon Hunter" does it, and so does any default the player renames to a long name (renaming keeps the Reset row).

**Why noticed:** Review of the Categories tab at half width (window sizes work, Task 8). At half the label was shortened to "Reset to default" (the button above the editor names the category), but full size was left as it was, to keep it unchanged. Measured at full: under Thick the label is 375 wide in a 264 slot and spills about 55 px over Delete (which spans 276..540); under Blizzard the 403 wide button sits over Delete (290..370). The parent commit of that task (`7cc5acb`) behaves the same, so it isn't a regression.

**Anchors:** `SaftUI-Bags/categoriestab.lua` (`INV:CategoryEditorOptions`, `args.reset`), `SaftUI-Core/Config/optionsbody.lua` (a floating line's buttons fill their slots, `Body:ButtonSlotRect`), `tests/bags/categories_half_test.lua` (the half-width case).

**What's been considered:** Use the same short label at full (the editor's Name box above already shows the category). Or let the body cap a shared-slot button's label to its slot with an ellipsis. Either changes full size, so it is the owner's call.

**Shape of work:** One-line label change plus a test, or a small body change for the cap.

**Open questions:** Short label at full too, or keep the name and truncate?

**Resolved 2026-11-15:** the button is gone; each field has its own reset (reset-every-setting, Task 5).

### 2026-11-11 — Grays/Auto Vendor: a finished edit that broadens its rule sells at the next merchant

**What:** Auto vendor sells whatever Grays/Auto Vendor's rule catches, and every editor change saves at once. A half-built rule can no longer widen it (an AND holding a block or group that isn't filled in catches nothing), but a finished edit that says "everything but" does, at the next merchant: NOT on an Old gear or Protected block in its inner OR (both are complete the moment they're added), flipping its root AND to OR (one click on the badge), removing its inner OR group with the X, or "Has vendor price: yes" in the inner OR. Each sells every priced item that `INV:IsAutoVendorItem` doesn't refuse (Protected, Cosmetic, fishing, account-bound, in a set, tooltip missing). Selling can't be undone, and buyback holds 12 items.

**Why noticed:** The bag categories final review (2026-11-11), under "Declined to judge": these are deliberate edits, and the spec says auto vendor follows the rule, but the reviewer called a confirm on the selling category's root flip or group removal "a cheap product decision for the user". The fix for the review's C-1 (half-built rules) left them as they are, and `tests/bags/category_store_test.lua` ("a half-edited Grays/Auto Vendor rule never sells more than the shipped one") skips NOT Old gear and NOT Protected in the inner OR for this reason.

**Anchors:** `SaftUI-Bags/ruleeditor.lua` (the badge's flip, the X, NOT, `Edit`); `SaftUI-Bags/categories.lua` (`INV:IsAutoVendorItem`); `SaftUI-Bags/autovendor.lua` (`INV:AutoVendor`); the slot's junk coin and the tab's Caught now, which already show what would sell before a merchant is opened.

**What's been considered:** A confirm in the editor before an edit widens the selling category's rule (the root flip, removing a group, NOT); a cap on what one merchant visit sells, with a prompt above it; or nothing, since the coins show the change first.

**Shape of work:** A product decision first, then a small change in the editor or in auto vendor, with tests.

**Open questions:** Which of these, if any?

**Resolved 2026-11-15:** The owner decided against a prompt on every broadened edit: "what if we order the sales by priority so that grays are sold first, then only show that prompt if permanent losses would be risky (like if there's over 12 non-gray items". `SaftUI-Bags/autovendor.lua` now sells grays first, then everything else the rules catch, the cheapest stack first (so the merchant's buyback list, which keeps the last 12 sales, ends up holding the most valuable), and when more than `INV:BuybackSize()` (the game's `BUYBACK_ITEMS_PER_PAGE`, 12) non-gray stacks would sell, it sells the grays and asks Sell them or Keep them before the rest; Keep sells nothing more at that merchant and the question returns at the next. Tests: `tests/bags/autovendor_sale_test.lua`.

### 2026-11-11 — The disabled loot popup writes nametext onto Blizzard's LootButton

**What:** `SaftUI-Loot/popup.lua` (~38) sets `button.nametext = _G['LootButton'..ID..'Text']` on Blizzard's loot buttons, and elsewhere `st:Kill`s their `IconBorder` and `IconOverlay`. That writes a field onto a Blizzard frame (`.agents/taint.md` rule 1). The popup is disabled (`SaftUI-Loot/init.lua`, `-- self:InitializeLootFrame()` is commented out), so it never runs today.

**Why noticed:** The Blizzard theme's reviews (2026-11-11): the popup's draw calls were re-tagged and a scan of Loot for writes onto Blizzard frames found it. Related to the older "SaftUI-Loot writes onto Blizzard frames and globals" entry in Resolved.

**Anchors:** `SaftUI-Loot/popup.lua`; `SaftUI-Loot/init.lua` (~17); `.agents/taint.md` rule 1.

**What's been considered:** Keep the font strings in a weak table keyed by the button, and replace `st:Kill` with `SetAlpha(0)` where Blizzard never sets the alpha.

**Shape of work:** Fix it before re-enabling the popup; no work while it stays off.

**Resolved 2026-11-15:** the owner asked for the popup back (`fb-lootpopup`). `SaftUI-Loot/popup.lua` is rewritten for today's scroll box `LootFrame` (the `LootButton1`-`4` code, `nametext` and the `st:Kill` calls are gone): SaftUI's pieces live in weak tables keyed by Blizzard's frames, only post-hooks, no script replaced, and `tests/loot/popup_test.lua` locks every Blizzard widget so a field write fails.

### 2026-11-09 — st:CreateHeader writes title and close_button onto the Blizzard panels it skins

**What:** `st:CreateHeader(frame, title, close_button)` (`SaftUI-Core/panels.lua`) writes `frame.title`, `frame.close_button` and `frame.header` onto the frame it's given. That frame can be a Blizzard panel: the unloaded loot window code (`SaftUI-Loot/popup.lua`) hands it `LootFrame`, and is the only such caller left since the codebase cleanup deleted `SK:SkinBlizzardPanel` (2026-11-12). Its other callers pass SaftUI's own frames (`SaftUI-Bags/container.lua`, and `st:CreatePanel` in `SaftUI-Core/panels.lua`). Writing them breaks `.agents/taint.md` rule 1. It also keeps the frame inside the screen edge margin (`st:KeepInScreenMargin`), which is meant for SaftUI's own frames only (2026-11-10). The loot window code isn't loaded, so no Blizzard frame gets these writes today.

**Why noticed:** The options window rework (2026-11-09) fixed the same class of write in `st:CreateCloseButton`, which now uses a weak side table and `st:GetCloseButton(frame)`. Its re-reviewer pointed out that `CreateHeader` still does it. That's old code, outside that task.

**Anchors:** `SaftUI-Core/panels.lua` (`CreateHeader`, `closeOf`, `headerTitles`), `SaftUI-Loot/popup.lua`.

**What's been considered:** Use the same pattern: weak side tables keyed by frame, with accessors such as `st:GetHeader(frame)`. Then find every reader of `.header`, `.title` and `.close_button` and switch it over.

**Shape of work:** A small refactor in `panels.lua`, plus its readers.

**Resolved 2026-11-15:** its only Blizzard caller, the loot popup, no longer calls `st:CreateHeader` (it leaves Blizzard's title and close button and restyles them without writing fields, `fb-lootpopup`). The remaining callers pass SaftUI's own frames (`SaftUI-Bags/container.lua`, `st:CreatePanel`), where the writes are fine. The helper itself is unchanged: it still writes onto the frame it is given, so a future Blizzard caller would need the side-table refactor described above.

### 2026-11-11 — Nameplates: a profile switch doesn't set the game's friendly plates

**What:** Friendly plates (`/sui` → Unitframes → Friendly nameplates → General since 2026-11-12, saved as `nameplate.friendly`) is a unit frame profile setting, but the game's two friendly plate settings it drives (`nameplateShowFriendlyPlayers`, `nameplateShowFriendlyNpcs`) are set only at login (`UF:OnEnable` runs `UF:ApplyNameplateCVars`) and when the toggle is clicked. Switching to a profile (a SaftUI profile or a unit frame profile) whose Friendly plates differs leaves the game's friendly plates as they were until the toggle is clicked or the UI reloads. Nameplates itself changes only at a reload anyway, since oUF makes its nameplate driver once. A related gap: Blizzard's own friendly plate options (Interface → Nameplates) and its key binding for them change the same settings without SaftUI's toggle following, and the next login or toggle sets them back to the toggle.

**Why noticed:** Task 6 of the nameplates plan (branch `np-6`), its concerns 2 and 3. Its brief named only the toggle and login as the places to set them, and Task 11 was changing the same part of `UF:ApplyConfig` at the time, so the profile switch was left out.

**Anchors:** `SaftUI-Unitframes/nameplates/cvars.lua` (`UF:ApplyNameplateCVars`), `SaftUI-Unitframes/unitframes.lua` (`UF:ApplyConfig`'s plate branch, which sets the plates' size again when no element is named; `UF:OnEnable`), `SaftUI-Unitframes/nameplates/options.lua` (`FriendlyNameplateGeneral`, Friendly plates' `set`), `tests/unitframes/nameplate_page_test.lua`.

**What's been considered:** One `UF:ApplyNameplateCVars()` in `UF:ApplyConfig`'s plate branch with no element, beside `UF:ApplyPlateSize()`, makes it follow every profile switch, copy and reset (`UF:UpdateConfig()` runs `UF:ApplyConfig()`, which includes the plates). It does nothing without SaftUI's driver or with Nameplates off, and waits out combat. For Blizzard's own toggle: leave it (SaftUI's toggle wins at the next login), or have SaftUI's toggle follow the game's setting (a `CVAR_UPDATE` listener writing the profile), which would make a key press change the profile.

**Shape of work:** Small: one call, and a profile switch case in `nameplate_page_test.lua`.

**Open questions:** Should Blizzard's friendly plate key binding change SaftUI's Friendly plates, or be undone at the next login?

**Resolved 2026-11-15:** a profile switch sets the game's friendly plates when the new profile's Friendly plates differs from what was last set (`UF.appliedFriendly`; `UF:ApplyConfig`'s plate branch, `SaftUI-Unitframes/unitframes.lua`, `tests/unitframes/profile_switch_test.lua`, merge fu-p2). The Blizzard key binding question is [its own entry](#2026-11-15--nameplates-blizzards-friendly-plates-key-binding-and-the-next-login).

### 2026-11-12 — Unit frames: a profile switch places a frame's parts against the old profile's anchors

**What:** A full update places a unit frame's parts one by one in `pairs()` order (`UF:UpdateUnitFrame`, `SaftUI-Unitframes/unitframes.lua`), each `SetPoint` made against the others where they are then. So two parts anchored each way round across two profiles (Name on Health in one, Health under Name in the other) close an anchor loop on a profile switch whenever the one placed first is anchored to the other: the game errors "Cannot anchor to a region dependent on it", `SafeUpdateUnitFrame` reports it, and the rest of that frame's update is cut short, its later parts keeping the old profile's look until its next full update. `UF:ApplyConfig` with no unit clears only the frames' points first (`ClearUnitFramePoints`), not their parts'. A plate's parts are cleared before a switch between Enemy and Friendly nameplates (`ClearPlacedPoints` in `nameplates/nameplates.lua`), but not on a profile switch that keeps a plate's config unit. Pre-existing for every unit.

**Why noticed:** The friendly nameplates' final fix wave (2026-11-12) resolved "Nameplates: a plate switching config can trip an anchor loop in a user's config" (now under Resolved) for a switch between the two plate configs only, as its brief ruled. That entry's open question (clear on a config switch only, or before every full update?) and its note that a profile switch does the same to any unit are what's left, kept here.

**Anchors:** `SaftUI-Unitframes/unitframes.lua` (`UF:UpdateUnitFrame`, `UF:ApplyConfig`, `ClearUnitFramePoints`, `SafeUpdateUnitFrame`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`ClearPlacedPoints`, `UF:ApplyPlateConfig`), `SaftUI-Unitframes/updaters.lua` (`UF:UpdateElement`, `UF:UpdateElementPosition`), `tests/unitframes/friendly_plate_size_test.lua` (the switch's tests, whose helpers say which parts an update places).

**What's been considered:** Clear each frame's parts in `UF:ApplyConfig`'s full pass, out of combat where it clears the frames', with `ClearPlacedPoints`' rule for which texts and icons; or clear a plate's parts before every full update of it, which covers the plates alone. Either way a part whose update then fails, and the parts after it, are left with no points (as a plate's are today when a switch's update fails, say on a loop inside one config), where `UF:ApplyConfig` gives a failed frame its old points back (`st:RestorePoints`).

**Shape of work:** Small: the clearing in the full pass, and a test with two parts anchored each way round across two profiles.

**Resolved 2026-11-15:** a full `UF:ApplyConfig` clears every enabled part of each unit frame, boss and arena frame and group button before placing them (`ClearAllPartPoints`), plates that keep their config unit are cleared too (`UF.ClearPlacedPoints`), and test mode's previews clear in `StylePreviewFrame` (`tests/unitframes/profile_switch_test.lua`, `boss_preview_test.lua`, merge fu-p2). A part the new profile switches off is [its own entry](#2026-11-15--unit-frames-a-part-switched-off-in-the-new-profile-keeps-its-old-points).

### 2026-11-14 — Copy from writes default tables into keys the source unit doesn't have

**What:** Unit frames' Copy from lists the destination unit's settings, but the source unit may not have them. Reading a key the source lacks gives AceDB's `['**']` default (a fresh table), so the copy writes that junk table onto the destination and also creates the key on the source.

**Why noticed:** Reviewing Task 7 of the edit mode bar plan (Copy from as one undoable step). The reviewer's probe: "Copy to Party from Target" with Layout ticked, `spacing` and `growthDirection` ticked, put `number`/`string` values on Party's side as old and element-default tables as new, and made `target.spacing` appear. Pre-existing behaviour of Copy from, not caused by the history work (Undo now restores the destination exactly, but the source keeps the created keys).

**Anchors:** `SaftUI-Unitframes/config/config.lua` (`UF:CopySettings`, `UF:OpenCopyTable`, `CopyNames`); `SaftUI-Unitframes/config/default.lua` (the `['**']` defaults at unit level); `tests/unitframes/copy_from_history_test.lua`.

**What's been considered:** Offering only keys both units have (the dialog already lists only parts the destination's page names), or skipping a key whose source value is not stored (`rawget` nil) so nothing is written.

**Shape of work:** small change in `UF:CopySettings` and the dialog's list, plus a test per case (a group unit as destination, a single unit as source).

**Open questions:** whether a key the source never stored should copy the source's default (what the player sees there) or be left alone.

**Resolved 2026-11-15:** `UF:CopySettings` skips any key not named by both units' pages and the dialog hides settings the chosen source's page lacks (`SaftUI-Unitframes/config/config.lua`, `tests/unitframes/copy_from_history_test.lua`, merge fu-p2).

### 2026-11-12 — Nameplates: a plate page's Position editor checks anchors against whichever plate has the lowest number

**What:** A Position editor on Enemy nameplates or Friendly nameplates checks a new anchor against live frames: `st:ValidateAnchor` (`SaftUI-Core/api.lua`), from the `validate` of `uf_element_position` (`SaftUI-Unitframes/config/position.lua`), asks whether the part chosen to anchor to already depends on the part being moved, on the frame `UF:GetConfigFrame(unit)` gives, which for either plate key is the frame on the lowest-numbered plate (`SaftUI-Unitframes/config/config.lua`), whichever page that plate draws from now. So with an enemy on the lowest plate, the Friendly page refuses Health → Name with "Anchor would create a loop", though the friendly config has none (it's the enemy's name that sits on its bar). With a friend there, the Enemy page accepts Health → Name, which does loop in the enemy config (its name is on its bar), and every update of an enemy plate then errors. Which answer you get depends on which plate has the lowest number. Anchors that loop only across the two pages no longer error at run time (the final fix wave places a switching plate's parts afresh), so the refusal is only a wrong answer in the options; the acceptance lets a loop inside one config through.

**Why noticed:** The final review of the friendly nameplates build (2026-11-12, its M1), filed here by that build's final fix wave, which changed no code for it.

**Anchors:** `SaftUI-Unitframes/config/config.lua` (`UF:GetConfigFrame`, `UF:ConfigTarget`), `SaftUI-Unitframes/config/position.lua` (`generators.uf_element_position`: `ResolveTarget`, `UnitFrame`, `GetElementNames`, `validate`), `SaftUI-Core/api.lua` (`st:ValidateAnchor`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UF.nameplates`, `frame.base_unit`, `ClearPlacedPoints`), `tests/unitframes/nameplate_page_test.lua` and `friendly_page_test.lua` (the plate pages).

**What's been considered:** For a plate page, return the lowest plate whose `base_unit` is that page's key, and nil when there's none, so the validator allows, as it does before any plate exists. With nil, the element dropdown falls back to every registered element (`GetElementNames`), Power and Class power among them, so it may want the lowest plate of either kind for the list and only the page's for the check. A check against the page's config (the anchors as its positions set them, not the live frame's) would give the same answer whatever plates are up, and would suit every unit's editor.

**Shape of work:** Small: `UF:GetConfigFrame` (or a variant for the validator) and a test in `nameplate_page_test.lua` with an enemy and a friend up in either order.

**Partly fixed 2026-11-14 (branch fb-plateanchor):** the check no longer measures the live plate (a plate part's anchors are read from its config, `UF.PlatePartAnchors`, since the game refuses `GetPoint` on one), and `UF:GetConfigFrame(unit)` now picks the lowest plate that draws from that page, with an enemy and a friend up in either order (`tests/unitframes/nameplate_anchor_test.lua`). What's left: with only the other kind of plate up, the part's config is still that plate's (`frame:GetConfig()` reads its `base_unit`), so the Enemy page checks against the friendly config. A check on the page's own config, whatever plates are up, would close it.

**Resolved 2026-11-15:** a plate page's Position editor checks a part against that page's own config whatever plates are up (`UF.anchorPage`, set by `WithAnchorPage` in `SaftUI-Unitframes/config/position.lua`; a part's `GetConfig(unit)` takes the page), and the Threat text keeps the Enemy page's config (`tests/unitframes/nameplate_anchor_test.lua`, merge fu-p2).

### 2026-11-09 — st:CreateButton's SetText and SetFont aliases break when called as methods

**What:** `st:CreateButton` aliases `SetText` and `SetFont` onto its button, and both break when called the normal way, as methods (`button:SetText(x)`, `button:SetFont('pixel')`).

**Why noticed:** The final review of the edit mode grid/snap branch found the footer's Grid size label calling `sizeLabel:SetText(...)`, which would error in game. That call was fixed in the branch to use `sizeLabel.text:SetText(...)`; `button.lua` was left alone because it has other callers.

**Anchors:**
- `SaftUI-Core/Widgets/button.lua:8-9`. `button.SetText = button.text.SetText` passes the button, not the FontString, as `self` when called as `button:SetText(x)`, which errors. `button.SetFont = function(font) ... end` receives the button as `font` when called as `button:SetFont('pixel')`.
- `SaftUI-Bags/header.lua` calls `filterButton:SetFont('pixel')`, so the bag filter buttons' font is probably never set as intended.
- `SaftUI-Core/Widgets/checkbutton.lua:30`, the pattern to copy: `function(self, v) self.text:SetText(v) end`.

**What's been considered:** Make both aliases take `self` first, like `checkbutton.lua:30`. Changing them changes what existing callers do (for example the bag buttons would start getting their font), so check every `st:CreateButton` caller before changing it.

**Shape of work:** Small fix in `button.lua`, plus a pass over every `st:CreateButton` caller for `SetText` / `SetFont` use, then a check in game that the bag filter buttons look right.

**Resolved 2026-11-15:** the aliases went in 9f6fae58 (`SaftUI-Core/Widgets/button.lua` has none); the bag caller was a `SetTextFont` call on a check button, whose method takes `self`.

### 2026-11-13 — Colour swatches read as checkboxes, and the colour picker

**What:** Two things about colours in `/sui`. The colour swatches are small squares that are hard to tell from checkboxes. And the colour picker is Blizzard's, unskinned, without the opacity and RGB values the user wants.

**Why noticed:** The user's in-game pass (2026-11-13): "can we explore different visuals for the color swatches? it can be difficult to differentiate them from checkboxes sometimes, maybe we can make them larger with the text inside of it or something? I'd also like to skin the color picker and enhance it with opacity and rgb values."

**Anchors:** `SaftUI-Core/Config/optionswidgets.lua` and `optionstypes.lua` (the `color` option's widget and the checkbox beside it); `ColorPickerFrame` (Blizzard's; `Blizzard_ColorPickerFrame` on both clients); `SaftUI-Misc/Skinning/blizzard/` (where a Blizzard frame's skin goes); `.agents/taint.md`.

**What's been considered:** For the swatch, the user's own idea: a wider swatch with the option's name written inside it. Others to draw: a wide bar the width of a dropdown, a swatch with a hex value beside it, a round swatch. For the picker: skin Blizzard's frame (backdrop, buttons, edit boxes), and add what it lacks: number boxes for red, green and blue, a hex box, and an opacity slider with its value. Retail's picker already has a hex box and an alpha slider; Forever's has to be read first.

**Shape of work:** A design round with mockups of the swatch options for the user to pick from, then two tasks: the swatch in Core's options kit, and the picker's skin and additions in Misc's Skinning (a taint review, since the picker is Blizzard's and is shared with other addons).

**Open questions:** Which swatch look. Whether the picker's additions are SaftUI's own controls on Blizzard's frame, or a SaftUI picker of its own that replaces it.

**Mocked and decided 2026-11-13:** Forever's picker was read: it already has an opacity strip and a hex box; it lacks number boxes for red, green and blue and a number for opacity, and it is unskinned. Swatches drawn: today's 22px square; A, a bar as wide as a dropdown with the colour's hex code written in it, and its opacity when it has one (the code is for reading; a click opens the picker); B, a wider chip with a hex box you can type into; C, the option's name inside the colour; D, a circle. **The user chose A** ("Lets go with A for the color choice"). Pickers drawn: P1, Blizzard's frame in SaftUI's look with nothing added; P2, the same, a little wider, with boxes for red, green, blue and opacity (SaftUI controls on a frame Blizzard and other addons share, so the usual taint care); P3, a picker of SaftUI's own that only `/sui` opens. P2 is the builder's recommendation; the user hasn't picked. Swatch A merged into `modular` 2026-11-13 (d2794fb): the bar is as wide and tall as a dropdown (170 by 24), the code is `#RRGGBB`, black or white by the brightness of what's drawn (luma times opacity over a half), with `· 60%` after it when the option has opacity under 100%. Colour rows are now half-line rows (two to a line, not four), so Global Settings → Colors grows from 23 lines to 42; the review found no in-keeping way to fit more at this window's width (the body has only quarter, half and full cells). Not yet seen in game. The picker (P1 to P3) still waits on the user.

**Resolved 2026-11-15:** built before today: swatch A in d2794fb and SaftUI's own color picker (red, green, blue, opacity and hex boxes) in ef87de0b (`SaftUI-Core/Config/optionscolorpicker.lua`). The later ask, colors applied live with a preview, is its own agreed design.

### 2026-11-13 — Character frame slots: SaftUI writes fields onto Blizzard's buttons

**What:** The character frame's skin calls `Util:SetItemQuality` and `Util:ClearItemQuality` on Blizzard's equipment slot buttons. Those helpers write fields onto the button (`alwaysShowProfessionsQuality`, `isProfessionItem`, `professionQualityOverlayOverride`, and a `qualityText` font string stored on it) and run Blizzard's `SetItemCraftingQualityOverlay`, `SetItemCraftingQualityOverlayOverride` and `ClearItemCraftingQualityOverlay` on it. That breaks `.agents/taint.md`'s rules 1 (write nothing onto a Blizzard frame) and 3 (don't run Blizzard's functions on its frames from addon code). The same helpers are fine on SaftUI's own bag slots and loot feed items.

**Why noticed:** The reviewer of the character frame's item level change (branch `fb-ilvl`, merged 58a646a, 2026-11-13). It was there before that change and was left alone as out of scope.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua` (the two calls, in the slot update); `SaftUI-Core/Utilities/itemupgrades.lua` (`Util:SetItemQuality`, `Util:ClearItemQuality`, `Util:SetItemUpgradeQuality`, `Util:SetItemQualityLevelText`); other callers `SaftUI-Bags/slot.lua` and `SaftUI-Loot/Feed/feed.lua` (SaftUI's own frames); `.agents/taint.md`.

**What's been considered:** No error has been traced to it. The equipment slots are secure buttons used in combat (swapping a weapon), so a tainted field on one is the kind of thing that ends in `ADDON_ACTION_BLOCKED`. The item level text beside it already shows the pattern to follow: SaftUI's own frame over the slot, with its state kept in a table keyed by the button.

**Shape of work:** Small: draw the upgrade tier and the crafting quality on a SaftUI overlay per slot, keep the state in the skin's own table, and stop calling the helpers on Blizzard's buttons. Tests beside the item level's (`tests/misc/`). An in-game check that the tier icon and the level text still show.

**Resolved 2026-11-15:** each equipment slot has one plain child frame of SaftUI's (`slots[button].overlay` in `SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua`) that the tier icon, n/m text and crafting pip are set on, so no field is written onto Blizzard's slot button; Blizzard's own pip (Professions window open) sits under SaftUI's (`tests/misc/characterframe_test.lua`, merge fu-p9). The slots were never protected: the harm was Blizzard's update reading SaftUI's fields.

### 2026-11-11 — Bag categories: a default added in a later version can duplicate a user category's name

**What:** A default category added in a later SaftUI version, whose name a user category already has, makes two categories with one name. `INV:RestoreCategory` and `INV:ResetCategory` number the name (`Toys (2)`), but the list build (`INV:GetCategoryList`) doesn't number a default it finds new.

**Why noticed:** The bag categories project's final review (2026-11-11). Category frames, ranks and hide flags go by id, and a default's id is the name it shipped with, so the ids stay apart but two categories show one header, and a user can't tell them apart in the list or the tooltip lines.

**Anchors:** `SaftUI-Bags/categories.lua` (`INV:GetCategoryList`, the numbering in `RestoreCategory` and `ResetCategory`); `SaftUI-Bags/categorydefaults.lua`; `tests/bags/category_store_test.lua` (the `Toys (2)` cases).

**What's been considered:** Numbering the default in the list build (`UniqueName`), as Restore and Reset do, is the obvious fix. A user category's id is `custom:<n>`, so ids never clash and it's only the name. Renaming the user's category instead would change their data.

**Shape of work:** Small: the same numbering in the list build, plus a test with a profile that has a custom category named like a default the version adds. Matters only when a later version ships a new default.

**Resolved 2026-11-15:** `INV:GetCategoryList` numbers a default's shipped name (`Toys (2)`) against the user's categories and renamed defaults, case-insensitively, as `UniqueName` does; display only, nothing written, and a default the user renamed is never renumbered (`SaftUI-Bags/categories.lua`, `tests/bags/category_store_test.lua`, merge fu-p5).

### 2026-11-11 — Bag settings: the reagent section nothing reads

**What:** `SaftUI-Bags/config.lua:58` still defines a `reagent` section (a position anchored to the bank's anchor, and its settings), but no reagent window exists any more. `SaftUI-Bags/movers.lua` lists the windows that can have a position as `bag`, `bank`, `combinedbank` and `warband` (`WINDOW_IDS`, line 16), and still calls `self:MigratePosition('reagent')` (line 97) "no window yet, but it has a config entry". Neither client has a reagent bank any more (`.agents/clients.md`).

**Why noticed:** The bag categories project's doc pass (2026-11-11), reading the bags' config for a stale `filters.lua` reference.

**Anchors:** `SaftUI-Bags/config.lua` (`reagent`), `SaftUI-Bags/movers.lua` (`WINDOW_IDS`, `MigratePosition('reagent')`); the followup "Settings with no /sui option, settings nothing reads, and frames with no edit mode mover" is the same kind of cleanup.

**Shape of work:** Small: remove the section and the migration call, after checking nothing else reads `config.reagent` (grep for `.reagent`), and that a saved profile with the key is harmless. Leave the bag family `'reagent'` kinds in `category.lua` and `autovendor.lua` alone: they are about the reagent bag, not this window.

**Resolved 2026-11-15:** the default `reagent` section, its old-array default and its migration are gone; a profile that saved one keeps an inert table (`tests/bags/reagent_section_test.lua`, merge fu-p5).

### 2026-11-13 — Bag search box is made multi-line

**What:** `INV:InitializeSearch` (`SaftUI-Bags/search.lua`) calls `st:CreateEditBox(container:GetName()..'Search', container.footer, 'SearchBoxTemplate')`. But `st:CreateEditBox(name, parent, lines)` (`SaftUI-Core/Widgets/editbox.lua`) always creates from `'InputBoxTemplate'` and takes its third argument as `lines`: `if lines then editbox:SetMultiLine(true) end`. So the search box gets no `SearchBoxTemplate` (no magnifier, no clear button) and is a multi-line box. It is also skinned twice, once inside `st:CreateEditBox` and once by the caller.

**Why noticed:** The cleanup's Task 16 moved the search code into `search.lua` (2026-11-12) without changing it, and its reviewer read the call against `st:CreateEditBox`. The behaviour is older than the cleanup.

**Anchors:** `SaftUI-Bags/search.lua` (`INV:InitializeSearch`); `SaftUI-Core/Widgets/editbox.lua` (`st:CreateEditBox`). The search box has no test file of its own.

**Shape of work:** Small. Either drop the third argument, or give `st:CreateEditBox` a template parameter and pass `'SearchBoxTemplate'` properly (then the skin has to deal with the template's own art, on both clients). Check in game what Enter does in the box today (step 16 of [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks)).

**In game 2026-11-13:** the user checked step 16 and the box behaves fine as it is. The call is still wrong as written.

**Open questions:** Does the user want the search template's magnifier and clear button, or SaftUI's plain box?

**Resolved 2026-11-15:** `st:CreateEditBox` no longer gets `'SearchBoxTemplate'` as its `lines` argument, so the box is single-line, and the second `st:SkinEditBox` became one `st:StyleEditBox(search, 'theme', 'theme')` (`SaftUI-Bags/search.lua`, `tests/bags/search_box_test.lua`, merge fu-p5). The magnifier and clear button question is [its own entry](#2026-11-15--bag-search-box-the-magnifier-and-the-clear-button).

### 2026-11-10 — Bank eye toggle doesn't re-apply the bag search

**What:** In the combined bank, toggling a bank's eye (showing or hiding the bank or the warband bank, `INV:UpdateContainerBagIds`) lays the window out again but doesn't re-apply the bag window's search, so items can be lit or dimmed against a stale search until the next search change. It predates the bag views; a view switch now re-applies it (`INV:ApplyView`).

**Why noticed:** The bag views branch's final-review fix wave (2026-11-10), which made `ApplyView` re-apply the search and left the eye toggle as it was.

**Anchors:** `SaftUI-Bags/containers/combinedbank.lua` (`INV:UpdateContainerBagIds`, called from the eye buttons), `SaftUI-Bags/layout.lua` (`INV:ApplyView`), `SaftUI-Bags/search.lua` (`INV:UpdateSearchFilter`).

**Shape of work:** One line (call `INV:UpdateSearchFilter` after the toggle's layout) and a test.

**Resolved 2026-11-15:** `INV:UpdateContainerBagIds` re-runs the bag search after laying out the combined bank, so slots made since the last search change stay dimmed (`SaftUI-Bags/containers/combinedbank.lua`, `tests/bags/search_box_test.lua`, merge fu-p5).

### 2026-11-13 — Chat's dock hook runs only on forced updates

**What:** `CHT:FCFDock_UpdateTabs(dock, forceUpdate)` (`SaftUI-Chat/chatframe.lua`) starts with `if not (dock.isDirty or forceUpdate) then return end`. It is a post-hook (`self:SecureHook('FCFDock_UpdateTabs')`), and Blizzard's `FCFDock_UpdateTabs` clears `dock.isDirty` before the post-hook runs. So SaftUI's tab layout runs only on forced updates, and after a plain dirty update the docked tabs may be left where Blizzard put them.

**Why noticed:** The review of the cleanup's wave 1 (2026-11-12), which touched Chat, read the hook against Forever's `FloatingChatFrame.lua`. The behaviour is older than the cleanup, which didn't change it.

**Anchors:** `SaftUI-Chat/chatframe.lua` (`CHT:FCFDock_UpdateTabs`, and the `SecureHook` in the module's enable); Blizzard's `FCFDock_UpdateTabs` in `FloatingChatFrame.lua`; `tests/chat/dock_test.lua`, which sets `isDirty` by hand before calling the hook, so it can't see this.

**What's been considered:** Dropping the guard makes the hook run on every call, which Blizzard makes often (each tab flash and each resize), so it may want its own cheap "has anything moved" check. Whether anything is wrong on screen is not known: the game may force an update in every case that matters.

**In game 2026-11-13:** the user checked step 35 and the docked tabs sit right, so the guard does no harm on screen. What's left is the test.

**Shape of work:** First the in-game check: step 35 of [Codebase cleanup: in-game checks](#2026-11-13--codebase-cleanup-in-game-checks). If the tabs are right after a drag and dock and after a plain tab switch, the guard is harmless and only the test needs to stop setting `isDirty` by hand. If not, a small fix in `chatframe.lua` and a test that calls the hook the way the game does.

**Resolved 2026-11-15:** test only, as the entry said: `tests/chat/dock_test.lua` now runs a stand-in of Blizzard's `FCFDock_UpdateTabs` (which clears `isDirty`) and then SaftUI's hook with the same arguments, in the game's order, and pins both the early return and the forced update (merge fu-p11). The stand-in sets no anchors, which hides a second anchor on tabs 2 to n: [its own entry](#2026-11-15--chat-the-dock-hook-adds-a-second-anchor-to-docked-tabs-2-to-n-and-the-dock-test-cant-see-it).

### 2026-11-10 — Zone faction line edge cases: a PvP subzone's status, same-named zones on the map

**What:** Three narrow cases where the zone line can be off:
- **A PvP subzone's status.** When `C_PvP.GetZonePVPInfo()` says `isSubZonePvP`, its status is the subzone's (Blizzard shows it on `PVPArenaTextString`, under the subzone name), but SaftUI takes it for the zone's. Entering a faction's zone while standing in a free-for-all or sanctuary subzone, the zone text says Neutral, and so does the map for that zone. Most such subzones are in contested zones, where Neutral is right anyway.
- **A subzone during a cleared banner.** After a world quest or PvP objective banner clears the zone name (`ZoneText_Clear`), crossing into a subzone during the same fade brings SaftUI's level and faction line and the difficulty line back under the blank name, while the flourishes stay hidden. Blizzard's own PvP line, which this line replaces, does the same in the default UI.
- **Same-named zones on the map.** The map line is worked out again only when the label's text changes (or on a zone event or a color change). Retail has same-named copies of a zone with different factions (Eversong Woods 94 is Horde, 2395 and 2567 Neutral; Silvermoon City 110 Horde, 2393 Neutral). Switching between maps that show both, with the cursor never leaving the zone and the label's text identical, keeps the first answer.

**Why noticed:** The review of the zone level and faction feature (2026-11-10, minors 4 and 6), left as they are; the subzone case from its re-review (N1), left as it is because Blizzard's own PvP line behaves the same.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/ZoneText.lua` (`ZT:LiveFaction`, `ZT:MapFaction`, `ZT:UpdateMapLine`'s `mapLineFor`); `tests/misc/zone_map_test.lua`.

**What's been considered:** For the subzone: when `isSubZonePvP`, use the table's word for the zone, at least on the map. For a cleared banner: `ZT:UpdateZoneLine` and `ZT:SetZoneDifficultyText` also require a non-blank `ZoneTextString`. For the map: key the cache on the map's ID and the label text (`map:GetMapID() .. name`), which costs nothing.

**Shape of work:** Small: a few lines each, with a test each.

**Resolved 2026-11-15:** a subzone's PvP status is no longer taken as the zone's (`LiveFaction` returns nil for it, and the zone line reads the table's word through `ZT:SubZoneZoneFaction`), a blank `ZoneTextString` draws no line, and the map's label is keyed by map id and name, so same-named zones on different maps stay apart (`SaftUI-Misc/Skinning/blizzard/ZoneText.lua`, merge fu-p10).

### 2026-11-09 — Loot feed: a merge while scrolled shifts the scroll offset

**What:** `LootFeedPush` (`SaftUI-Loot/Feed/feed.lua`) still does `offset = offset + 1` when the feed is scrolled, even when the push merges into an existing entry (gold, or the same item) instead of adding one. A merge adds no entry, so the view probably shifts by one line for no reason.

**Why noticed:** The review of the "Older loot feed quirks" fix (2026-11-09) noticed it. It was outside that fix's scope.

**Anchors:** `SaftUI-Loot/Feed/feed.lua` (`LootFeedPush`, the merge branches, `offset`); `tests/loot/feed_test.lua`.

**Shape of work:** Small: bump the offset only on an insert, with a test.

**Resolved 2026-11-15:** `LootFeedPush` bumps `feed.offset` only when it inserts a row, not on a merge (`SaftUI-Loot/Feed/feed.lua`, `tests/loot/feed_test.lua`, merge fu-p10).

### 2026-11-11 — Class power types with no Blizzard art draw a borderless flat bar under Blizzard

**What:** Each class power point is drawn as kind `control`, which is bare under Blizzard (`SaftUI-Unitframes/elements/classpower.lua`, the `st:SetBackdrop(point, ..., 'control')` line). A power type with no Blizzard art (retail's demon hunter soul fragments, icicles and tip of the spear; the art exists for combo points, holy power, soul shards, chi, arcane charges and essence) draws only its flat status bar, with no border. Before, kind `small` gave them a 1px line. Forever has combo points only, which have art, so the user's client isn't affected.

**Why noticed:** The Blizzard theme's reviews (2026-11-11), reading Task 11's class power change: `ApplyArt` falls back to the flat bar for a type with no art, but the point's backdrop kind is fixed at `control`.

**Anchors:** `SaftUI-Unitframes/elements/classpower.lua` (`ApplyArt`, the draw call); `SaftUI-Core/themeart.lua` (`ThemeArt.ClassPower`, `KINDS.control`); `tests/unitframes/classpower_blizzard_test.lua`.

**What's been considered:** Pick the kind by whether art exists (`ThemeArt.ClassPower(powerType, ...)` returns nil for a type with none): `small` then, `control` otherwise, drawn again on every power type change (the art is chosen per power type there already).

**Shape of work:** Small, in the one element, with a test per kind.

**Resolved 2026-11-15:** `PointKind` in `SaftUI-Unitframes/elements/classpower.lua` picks kind `small` for a power type with no Blizzard art and `control` otherwise, and `ApplyArt` redraws a point only when its kind changed (`tests/unitframes/classpower_blizzard_test.lua`, merge fu-p3). Retail only; seen in game when a mage's icicles or a demon hunter's soul fragments under Blizzard show a 1px line.

### 2026-11-11 — Blizzard bag-bar slots and the Hekili skin write onto frames that aren't SaftUI's

**What:** `SaftUI-Bags/containers/bag.lua` (the bags bar's Blizzard bag slots) writes `.backdrop`, `.thick` and a hover texture onto them through `st:SetBackdrop` and `st:SkinActionButton`, and `SaftUI-Misc/Skinning/addons/hekili.lua` does the same to Hekili's buttons (`st:SetBackdrop`, `button.backdrop:SetFrameStrata('LOW')`, `button.skinned`). That breaks `.agents/taint.md` rule 1 for Blizzard's slots, and writes onto another addon's frames for Hekili. Both are `st:MarkForeign` now, so the Blizzard theme puts none of its art on them, but the old field writes are still there.

**Why noticed:** The Blizzard theme's reviews (2026-11-11). Task 3 had to mark both foreign so the ring went on a frame of SaftUI's, and carried the writes forward as pre-existing.

**Anchors:** `SaftUI-Bags/containers/bag.lua` (`RestyleBagSlot`, the `st:MarkForeign(slot)` and `st:SkinActionButton` lines); `SaftUI-Misc/Skinning/addons/hekili.lua` (`HK:SkinIcon`, `HK:UpdateConfig`); `SaftUI-Core/theme.lua` (`st:MarkForeign`, `st:SetBackdropIn`); `.agents/taint.md` rule 1.

**What's been considered:** Move both to `st:SetBackdropIn(backdrops, frame, ...)` with a weak table of their own, keep the hover and pushed textures as `st:SkinActionButton` makes them but in a side table, and read `backdrops[button]` where `button.backdrop` is read now (Hekili's strata line).

**Shape of work:** One small task, two files, with a locked-frame test for each as `tests/lib/locked_widget.lua` gives.

**Resolved 2026-11-15:** the bags bar's five Blizzard slots have their own `SkinBagSlot` (`SaftUI-Bags/containers/bag.lua`), which keeps SaftUI's backdrop, state textures and icon in weak tables and no longer calls `st:SkinActionButton`; Hekili keeps its backdrop and skinned flag in weak tables too (`tests/bags/bag_bar_slot_test.lua`, `tests/misc/addon_skins_test.lua`, merge fu-p7). What still writes onto the bag bar's frames is [its own entry](#2026-11-15--the-bag-bar-and-hekili-what-still-writes-onto-blizzards-frames).

### 2026-11-10 — The Hekili and WeakAuras skins error when Skinning's Theme is None

**What:** With Skinning's Theme set to None, `st:SetBackdrop` makes no backdrop (None only clears, and a frame never drawn has nothing to clear), but both skins use it on the next line:
- `SaftUI-Misc/Skinning/addons/hekili.lua:16`, `button.backdrop:SetFrameStrata('LOW')`;
- `SaftUI-Misc/Skinning/addons/weakauras.lua:11` and `:14`, `region.backdrop:SetFrameLevel(...)` and `:SetFrameStrata('LOW')`.

Each new Hekili button or WeakAuras icon then errors. The error comes before `skinned = true` and the `tinsert` into `skinnedButtons` / `skinnedRegions`, so it errors again on every call, and a later switch away from None doesn't reach those frames through `UpdateConfig`.

**Why noticed:** The Themes project's reviews (2026-11-10): Task 6 converted these skins to Theme and Background and carried this forward as pre-existing, and the final review confirmed it. The old `none` template behaved the same, so it predates Themes.

**Anchors:** `SaftUI-Misc/Skinning/addons/hekili.lua` (`HK:SkinIcon`, `HK:UpdateConfig`), `SaftUI-Misc/Skinning/addons/weakauras.lua` (`WA:SkinIcon`, `WA:UpdateConfig`), `SaftUI-Core/theme.lua` (`st:SetBackdrop`, which returns without making a backdrop for None); `tests/misc/theme_test.lua` (the Skinning page). There's no Hekili or WeakAuras stand-in in `tests/misc/fixtures/` yet.

**What's been considered:** Guard each `.backdrop` use, and still mark the frame skinned and record it, so `UpdateConfig` draws it once the theme isn't None. The strata and level then need setting after every draw, in `UpdateConfig` too, or a backdrop first made there sits at the default level. Both skins also write `.skinned` and `.backdrop` onto another addon's frames. Rule 1 doesn't bind third-party frames, but `.agents/taint.md` asks for side tables there anyway, and the same pass could move them.

**Shape of work:** Small: guards and a strata and level step after each draw in both files, with a test per skin over minimal Hekili and WeakAuras fixtures.

**Resolved 2026-11-15:** each skin draws through `st:SetBackdropIn` with a side table of its own and sets strata and level only when a backdrop came back, so Theme None no longer errors and a backdrop first made after leaving None gets its strata too (`SaftUI-Misc/Skinning/addons/hekili.lua`, `weakauras.lua`, `tests/misc/addon_skins_test.lua`, merge fu-p7).

### 2026-11-14 — Tracker: a tracker moved in Blizzard's Edit Mode isn't the first position

**What:** While SaftUI's tracker is on, Misc's mover stands down, so it never captures where a player had moved Blizzard's tracker in Blizzard's own Edit Mode (and never saved a skin position for). SaftUI's tracker then starts at Blizzard's default spot for that player, not where their tracker was (the design's "first enable starts where Blizzard's tracker was").

**Why noticed:** Task 6 review of the Blizzard's-tracker concealment (`.superpowers/sdd/2026-11-14-saftui-objective-tracker-phase-1/task-6-review.md`, Minor 7): the capture used to run a frame after `TR:Build` had already saved the default, and depended on module order.

**Anchors:** `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua` (`OTP:CapturePosition`, `Owned()`), `SaftUI-Tracker/window.lua` (`FirstPosition`).

**Shape of work:** small: read `ObjectiveTrackerFrame.systemInfo`'s anchor (reads only) once Edit Mode has applied its layout, before SaftUI first conceals it, and convert like `ConvertSkinPosition`.

**Resolved 2026-11-15:** SaftUI's tracker's first position reads Edit Mode's layout through `C_EditMode.GetLayouts()` only (`EditModeSpot` in `SaftUI-Tracker/window.lua`, never a field of Blizzard's tracker frame), for any anchor point: a top point is copied, any other is converted to TOPRIGHT from the width and Edit Mode's own Height setting. A preset layout or a tracker in its default position gives Blizzard's default spot; if Blizzard's manager has not applied the layouts yet the default is written and the first `EDIT_MODE_LAYOUTS_UPDATED` moves it, once, only while the position is still the one written (`tests/tracker/editmode_position_test.lua`, merge fu-p4). The limit that remains is [its own entry](#2026-11-15--tracker-an-edit-mode-anchor-to-a-frame-other-than-uiparent-gives-the-default-spot).

### 2026-11-15 — Keybind mode's hint line could read Muted

**What:** The line "Press a key to bind it. Right-click clears." that keybind mode adds to its tooltip is drawn at a literal 0.7, 0.7, 0.7. It is a dimmed hint, the role Text > Muted names, so it could read `st:Color('text', 'muted')` and follow the player's choice.

**Why noticed:** Review of color roles Task 3 (Muted): the task moved SaftUI's own dimmed tooltip lines (`SaftUI-Tracker/clicks.lua`, `items.lua`) to Muted and left this one, because the spec's call 18 keeps every other hardcoded color. At the defaults it is 178.5 against Muted's 180, so nothing would visibly change.

**Anchors:** `SaftUI-ActionBars/keybindmode.lua:65`; `docs/superpowers/specs/2026-11-14-saftui-color-roles-design.md` (call 18); `docs/design-system/tokens.json` (`text-muted`).

**Shape of work:** one line plus a test that sets Muted to a non-default value; it belongs with Task 4's pass over direct reads, or after it.

**Resolved 2026-11-15:** the hint line takes `st:Color('text', 'muted')`, read each time the tooltip shows (`SaftUI-ActionBars/keybindmode.lua`, `tests/actionbars/keybind_command_test.lua`, merge fu-p8).

### 2026-11-11 — st:SetBackdrop and st:SetBackdropIn do arithmetic on frame levels that can be Blizzard's

**What:** `SaftUI-Core/theme.lua` levels each backdrop one below the frame it sits behind with `max(0, parent:GetFrameLevel() - 1)` (`st:SetBackdrop`) and `max(0, frame:GetFrameLevel() - 1)` (`st:SetBackdropIn`). Both frames can be Blizzard's: tooltips, the bags bar's slots, Hekili's buttons, the aura container's buttons. If retail ever hands back a secret frame level for one of them, the subtraction errors on every draw.

**Why noticed:** The Blizzard theme's final fix wave (2026-11-11) guarded the same read in the code the branch added: `Holder` in `SaftUI-Core/themeart.lua` and the roll icon's level in `SaftUI-Loot/roll.lua`. Both now skip the re-level when the level is secret, following `SaftUI-Minimap/microbuttons.lua`. The reviewer and the implementer both noted that `theme.lua`'s two reads are older than the branch and stay unguarded. No live path is known to give a secret level today, so this is hardening.

**Anchors:** `SaftUI-Core/theme.lua` (`st:SetBackdrop`, `st:SetBackdropIn`: the two `SetFrameLevel(max(0, ...GetFrameLevel() - 1))` lines); the guarded reads in `themeart.lua` `Holder` and `SaftUI-Loot/roll.lua`, and their tests, which pass a `newproxy` secret; `.agents/clients.md` (secret values).

**Shape of work:** Small. Add an `issecretvalue` guard to both lines (on a secret level, leave the backdrop at the level it was made with), plus a test per function using the existing secret stand-in.

**Resolved 2026-11-15:** both draw calls read the frame's level once and re-level the backdrop only when it is not secret; a secret level leaves the backdrop at the level it was made with, one over the frame (`SaftUI-Core/theme.lua`, `tests/core/theme_test.lua`, merge fu-p8).

### 2026-11-12 — Nameplates: a neutral unit turning hostile keeps its name's old color

**What:** A plate's name is drawn again on a faction change only when the change flips the plate's kind (`UpdatePlateKind` in `nameplates.lua` ends in `UpdateAllElements('UNIT_FACTION')`, which runs the tags). A neutral unit turning hostile, or hostile back to neutral, stays an enemy plate, so its name keeps its old color (yellow for red, or red for yellow) until the `st:name` tag's next event (`UNIT_NAME_UPDATE`, `UNIT_LEVEL`, `PLAYER_LEVEL_UP`, `PLAYER_TARGET_CHANGED`: in practice the next target change). Its health bar recolors at once (oUF's Health registers `UNIT_FACTION` for `colorReaction`). Every unit frame's name works the same way, since the tag has no faction event: pre-existing, not caused by the friendly nameplates build.

**Why noticed:** Task 3's report of the friendly nameplates plan (its friendly↔hostile name redraw covers a kind change only), after Task 2's review noted the tag has no `UNIT_FACTION` refresh (Color hostile too).

**Anchors:** `SaftUI-Unitframes/tags.lua` (`UF.oUF.Tags.Events['st:name']`, `NameColor`), `SaftUI-Unitframes/nameplates/nameplates.lua` (`UpdatePlateKind`, `OnPlateEvent`), `tests/unitframes/friendly_plate_test.lua` (the `UNIT_FACTION` case), `tests/unitframes/name_color_test.lua`. The entry "Nameplates: small items left after the build" proposes dropping `PLAYER_TARGET_CHANGED` from the same list, which would also drop the redraw on a target change.

**What's been considered:** Add `UNIT_FACTION` to the tag's events (a unit event, so oUF updates only the frames showing that unit), or update the name's tag in `UpdatePlateKind` when the kind didn't change (plates only). The first fixes every unit frame and pairs with dropping `PLAYER_TARGET_CHANGED`.

**Shape of work:** Small: one event in the tag's list, and a test.

**Resolved 2026-11-15:** `st:name`'s tag events gained `UNIT_FACTION` (`SaftUI-Unitframes/tags.lua`), so the name redraws, and recolors, the moment a neutral unit turns hostile; the test pins the event list (merge fu-p1).

### 2026-11-11 — Health text's Boss percent and Hide full with a secret health

**What:** Two of the health text's paths still read a secret health as a plain number, and error when the game hands them one (enemy nameplates and other units in restricted content). Boss percent (`boss_percent`, on by default for the units that can show a skull-level unit) compares `UnitLevel(unit)`, which can be secret, with `-1`, then `format`s the health (or its Short form) and the percent, both secret, into "1234567 | 45.6" (`getHealthPercentText`'s `format` and `floor`). Hide full (`hide_full`, on by default for raid10 and raid40) compares the game's secret deficit string (`C_StringUtil.TruncateWhenZero(UnitHealthMissing(unit))`) with `0`; that string is `''` at full health, so even where the comparison doesn't error it never hides the text.

**Why noticed:** The nameplates plan's Task 2 (`docs/superpowers/plans/2026-11-11-saftui-nameplates.md`) made the health text's Percent and value paths take a secret health: Percent draws the game's `UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)` through `SetFormattedText('%.0f', ...)`, as `UF:SetPowerPercentText` does; the value is passed to `SetText` as it is, or shortened by the game's `AbbreviateNumbers` with Short on. Plates show the value in short form (the user's answer 9 in the spec) with Boss percent and Hide full off, so they never reach these two paths, which were left out of scope. Before Task 2 the value path was safe without Boss percent, and the Percent path errored on `floor`.

**Anchors:** `SaftUI-Unitframes/elements/health.lua` (`PostUpdateHealth`, `getHealthPercentText`, `SHORT`); `SaftUI-Unitframes/updaters.lua` (`UF:SetPowerPercentText`, the pattern); `tests/unitframes/secret_texts_test.lua`; `tests/lib/secrets.lua`; `SaftUI-Unitframes/config/units/raid10.lua` and `raid40.lua` (`hide_full = true`).

**What's been considered:** Boss percent could join the parts in the game: `SetFormattedText('%s | %.1f', text, UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))`, with the skull check made only on a plain level (or on `UnitClassification(unit) == 'worldboss'`, whose documentation marks no secret return on either client, though a boss frame's unit may still differ in game). Hide full has no game function that answers "is this secret zero" to an addon; a step curve through `UnitHealthPercent` into the text's alpha might, if the alpha setter takes a secret from an addon.

**Shape of work:** Small: two branches of `PostUpdateHealth` and cases in `tests/unitframes/secret_texts_test.lua`, after checking in game which unit values are secret on a boss frame and a raid frame on each client.

**Open questions:** Is a boss's level secret on the boss frames in restricted content, on Forever and on retail? Does any text setter take a secret alpha or shown state from an addon, for Hide full?

**Resolved 2026-11-15:** `PostUpdateHealth` (`SaftUI-Unitframes/elements/health.lua`) no longer compares, formats or floors a secret health: Boss percent tests the level only when it is not secret and, with a secret health, joins the text and the game's own percent (`UnitHealthPercent`); Hide full applies to a plain health only. Percent on a plain health now rounds (99.6 shows 100) to agree with the secret path, and a plain full health with Deficit on shows nothing, not `-0` (`tests/unitframes/secret_texts_test.lua`, merge fu-p1). Known limit: no game function says whether a secret is zero, so with a secret health the text still shows at full when Deficit is off (value, Short or Percent); with Deficit on (the raid10 and raid40 defaults) the game already blanks a zero deficit. Lifting the limit is [its own entry](#2026-11-15--hide-full-with-a-secret-health-lift-the-limit-with-a-step-curve-into-the-texts-alpha).

### 2026-11-11 — ItemRack is still an optional dependency, and nothing reads it

**What:** Core's TOCs, `SaftUI-Core/SaftUI-Core_Forever.toc` and `SaftUI-Core/SaftUI-Core_Mainline.toc`, still say `## OptionalDeps: RealMobHealth, ItemRack, WoWUnit, WeakAuras`, but no SaftUI Lua reads ItemRack. The bags' equipment set categories used to read it; they read the client's own equipment sets now (`C_Container.GetContainerItemEquipmentSetInfo`).

**Why noticed:** The bag categories project's doc pass (2026-11-11), while checking what the old set lookup depended on.

**Anchors:** the two Core TOCs; `grep -rn ItemRack SaftUI-*` (Libraries aside); `SaftUI-Bags/categories.lua` (`EquipmentSet`).

**Shape of work:** One line in each of two TOCs. Check first that no other addon or WeakAuras-side code relies on ItemRack loading before SaftUI (OptionalDeps only orders the load).

**Resolved 2026-11-15:** both Core TOCs now read `## OptionalDeps: RealMobHealth, WoWUnit, WeakAuras`; nothing else in the tree named ItemRack (merge fu-p12).

### 2026-11-14 — Three copies of the source lexer in tests

**What:** Three test files each carry their own copy of the Lua source lexer (`Lex`, which blanks comments and string contents, and `LineAt`): `tests/lib/source_lex.lua` (new, used by `tests/core/color_reads_test.lua`), `tests/core/theme_kinds_test.lua` and `tests/tracker/source_scan_test.lua`. They should share the one in `tests/lib/source_lex.lua`.

**Why noticed:** Writing the color scan (Task 1 of `docs/superpowers/plans/2026-11-14-saftui-color-roles.md`, Ruling 18). The scan needed the lexer, and the other two files were being edited by other work (the objective tracker's tasks), so the new file is a copy and the two older ones were left untouched to avoid merge conflicts.

**Anchors:** `tests/lib/source_lex.lua`, `tests/core/theme_kinds_test.lua` (`Lex`, `LineAt`), `tests/tracker/source_scan_test.lua`, `.agents/testing.md` (the `tests/lib/` rows).

**Shape of work:** Small: delete the local copies, load `lib/source_lex.lua` in each of the two files, and run the suite. Do it once the tracker's tasks have landed.

**Resolved 2026-11-15:** `tests/lib/source_lex.lua` is the one lexer: `theme_kinds_test.lua` and `tracker/source_scan_test.lua` load it as `color_reads_test.lua` and `setfont_scan_test.lua` already did (merge fu-p12; the Lex bodies were byte-identical, so no test's result changed).

### 2026-11-15 — SaftUI's tracker: experiments and in-game checks before the switch turns on

**What:** SaftUI's own objective tracker (`SaftUI-Tracker`, Phase 1: quests) is built, reviewed and green on stubs, and ships **off** (`tracker.enable = false`). Nothing about either tracker changes until the owner has run the experiments and checks below in game and flipped the default. The steps for each are in `docs/superpowers/plans/2026-11-15-saftui-tracker-phase-1-in-game-checklist.md`, in the order a player does them, with what to look for and, for each experiment, the one function that changes on a failure. **Flipping the default (`enable = true` in `SaftUI-Tracker/config.lua`) is the last step, a one-line change** (the checklist's Part 7 lists what moves with it).

**Why noticed:** The owner approved the design with the switch off and building before the experiments ("if you want to start building the core quest tracker we can handle the finer details after", the spec's Settled 4). The last task of the Phase 1 plan (`docs/superpowers/plans/2026-11-14-saftui-objective-tracker-phase-1.md`, Task 13) wrote the checklist and this entry. The parts that decide whether the tracker is safe (the secure item buttons, the concealment of Blizzard's tracker, the handover) can only be confirmed in the game, and a taint bug there blocks quest items in combat for the session.

**Anchors:** `docs/superpowers/specs/2026-11-14-saftui-objective-tracker-design.md` ("What only the game can confirm", "Experiments to run before the build"), the plan's "Experiment seams" table, `.agents/taint.md` rules 5 and 14 to 17, `tests/tracker/states_test.lua`, the task reports and reviews in `.superpowers/sdd/2026-11-14-saftui-objective-tracker-phase-1/` (git-excluded).

**Shape of work:** Run in order, Forever first and then retail, with `/console taintLog 1`. Each experiment is one function, so a failure is a small change plus its tests.

Experiments, before turning the switch on (with today's skin and mover), each with the task that built what it decides:
1. **P1.** A quest item used in combat from Blizzard's tracker with today's skin, and `issecurevariable` on `dirty` and `isDirty`. The baseline everything else assumes. A failure stops the work. (Task 6's concealment depends on it.)
2. **P2.** Concealing Blizzard's tracker by the C methods only (clamp off, one `SetPoint` off screen), quest progress and a quest item in combat while it is concealed. Built in Task 6 (`TR:PlaceBlizzard`); on failure only its `'concealed'` branch changes.
3. **P3.** A secure `item` button made before combat uses a quest item in combat, and by a key. Built in Tasks 8 to 10; on failure `TR.ItemAttributes` (`items.lua`) returns the `macro` form.
4. **P4.** What Forever has: which Blizzard sections fill in the open world and in a dungeon, that headers match `GetRealZoneText()`, that distance and the quest area answer. Used by Tasks 11 (`TR.SectionHandsOver`, `probes.lua`) and 10 (`TR.ChooseNearest`, `nearest.lua`); on failure each seam is one function. Decides which Phase comes next.
5. **P5.** Opening the map, quest details and Abandon from addon code, in and out of combat. Built in Task 7 (`TR.ShowOnMapAllowed`, `TR.QuestDetailsAllowed`, `TR.AbandonAllowed`, `clicks.lua`); on failure the one constant becomes false.
6. **P6.** Track and untrack from SaftUI's clicks leave no lasting taint (Task 7, `TR.WatchChangeAllowed`, `clicks.lua`); run with the tracker on. (Added by Task 7's review; the spec has P1 to P5.)

Then, with the switch on, the spec's G1 to G12, each with the task that built it:
- **G1** a quest item used from a row button, the column and the nearest button by its key, with nothing in the taint log (Tasks 8, 9, 10).
- **G2** `issecurevariable` on `dirty`, `isDirty` and `isCollapsed` prints `true true true` after an hour of questing, a dungeon and a handover in combat (Tasks 6, 11).
- **G3** the handover: Blizzard's tracker in place and beside, and in combat (Task 11).
- **G4** row buttons and the column in combat: dimming, the wheel (Tasks 8, 9).
- **G5** every visibility trigger and choice, with Hide quest items on and off (Task 12).
- **G6** the look under Thick, Thin and Blizzard, Width, Max height, Grow up, the scroll bar, zone groups, collapse states after `/reload` (Tasks 4, 5).
- **G7** `/reload` in combat (Task 8).
- **G8** an auto quest popup clicked in combat, and an auto-complete quest (Tasks 5, 7).
- **G9** the right-click menu, Abandon's confirm, Share (Task 7).
- **G10** edit mode: the outline, drag, `/reload`, the first position (Task 4).
- **G11** the Colors tab's Objectives colors recolor both trackers, old custom colors carried over (Task 2).
- **G12** the right column's frames against the tracker's header at the default spot (Task 4).

**Open questions:** The results. Rulings made for the owner to check are in the checklist's Part 5: the spot's floor (Ruling 33), the hover area including Blizzard's revealed tracker, watch changes held out of combat, Shift-click on an item button using the item, the nearest button's refused anchors, numbers counting only expanded groups, the column clamped to the scroll view, and the menu using the game's strings.

**Resolved 2026-11-15:** the owner ran the checks in game on Forever and approved the switch on by default ("Everything looks good ... we can enable it by default"): P1, P3 and P5 passed, P2 passed (the owner had misread the step: with SaftUI's tracker on, Blizzard's is off screen), G2 printed `true true true` with it on, and `SaftUI-Tracker/config.lua` now has `enable = true`. What is still open moved to the entry "SaftUI's tracker: what the in-game pass left open". Results: the checklist's "Results so far".

### 2026-11-14 — Tracker: a refresh allocates about 175 KB, measure it in game

**What:** SaftUI's tracker (`SaftUI-Tracker`) allocates about 175 KB of Lua tables per refresh in the stub world with 25 tracked quests of 3 objectives (about 240 KB with 6 objectives each). At the throttle's ceiling of ten refreshes a second (`TR.REFRESH_GAP` 0.1 s) that is about 2 MB/s of garbage while quest events stream, for example in a fight. An idle refresh (nothing changed) allocates no frame and sets no text. The question is whether the real numbers matter in game.

**Why noticed:** Review of tracker Task 5 (rows and the refresh), `.superpowers/sdd/2026-11-14-saftui-objective-tracker-phase-1/task-5-review.md`, which measured it and recommended accepting it for Phase 1 and measuring in game. The split in the stub world: the model read (`TR.Model.Read`) about 150 KB, of which about 70 KB is the stub's own API tables (30 `C_QuestLog.GetInfo` results, 25 `GetQuestObjectives` results), which the game makes too; the redraw (`TR.QuestLines`, `TR.Groups.Build`, title strings) about 25 KB.

**Anchors:** `SaftUI-Tracker/model.lua` (`Model.Read`, `ReadQuest`, `ReadObjectives`, `TR.QuestLines`), `SaftUI-Tracker/groups.lua` (`Groups.Build`), `SaftUI-Tracker/init.lua` (`TR:MarkDirty`, `TR:Refresh`, `TR:Redraw`), `tests/tracker/refresh_test.lua`.

**What's been considered:** Skipping the read when an event can't have changed the model, or reading only the quests an event names, does little in a fight: the stream there is `QUEST_LOG_UPDATE`, which names no quest and can change any of them. `PLAYER_REGEN_ENABLED` and `PLAYER_REGEN_DISABLED` need no re-read until the item buttons (Task 8) use them, a free micro-cut. The cheapest real cut, if the numbers call for one: `TR.Model.Read` fills last refresh's per-quest and objective tables in place, keyed by quest ID, instead of making new ones (most of the model's own share), and `TR.QuestLines` and `TR.Groups.Build` reuse their line and group tables (the redraw's share).

**Shape of work:** First measure: with a full log in a fight, run `/run local m=collectgarbage('count') local t=debugprofilestop() SaftUI.Tracker:Refresh() print(debugprofilestop()-t, collectgarbage('count')-m)` a few times and note the milliseconds and KB, here. If they are small (a refresh well under a millisecond, garbage collected without a visible hitch), resolve this as accepted. If not, one small change in `model.lua` and `groups.lua` (reuse the tables), with the idle-refresh test kept.

**Open questions:** The in-game milliseconds and KB per refresh on the owner's client with a full log, in and out of a fight.

**Resolved 2026-11-15:** accepted. The owner measured a refresh in game with a full log: "the cost is basically nothing". No table reuse needed.

### 2026-11-13 — Objective tracker skin: zone grouping, max height and a scroll frame

**What:** Asked for on the skin of Blizzard's objective tracker: group quests by zone, set a max height and put the list in a scroll frame. Blizzard's tracker groups by module and putting its container in a scroll frame or sizing it from addon code risks taint, so these were left to a design and taint study.

**Why noticed:** The owner, 2026-11-13: "I'll probably want some additional enhancements like zone grouping, objective status coloring, is it possible to set a max height and a scroll frame on it?" The rest of that entry (the in-game checks, what was left out) stays in Active: [Objective tracker skin: in-game checks and what was left out](#2026-11-13--objective-tracker-skin-in-game-checks-and-what-was-left-out).

**Anchors:** `SaftUI-Tracker/` (`groups.lua`, `window.lua`, `rows.lua`), `docs/superpowers/specs/2026-11-14-saftui-objective-tracker-design.md`.

**Resolved 2026-11-15:** SaftUI's own tracker draws a list grouped by zone (the current zone first), with Width and Max height and a scroll frame with its bar shown under the mouse; Blizzard's tracker is never put in a scroll frame. It ships on by default after the owner's in-game pass.

### 2026-11-15 — The action bars' and buffs' texts default to Small text

**What:** The action bars' hotkey, stack count and macro name, and the buffs' and debuffs' duration and stack count, still ship a copy of Small text's look (Homespun 10, Monochrome outline) saved as a face name, a size and an outline. Their Font rows now list SaftUI's fonts (the fonts design, Task 8), so a player can pick Small text and follow it, but an untouched profile does not. Make Small text the default (the key `pixel`), with a conversion that writes today's copy into any text that set one of font, size or outline, so those keep their look.

**Why noticed:** The fonts design's "Later" list (`docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`), kept out of the plan on purpose: the owner decided the texts keep their saved shape and copied faces (call 23). It would settle Discrepancy 2 by default instead of by a pick.

**Anchors:**
- `SaftUI-ActionBars/config.lua` (`Text()`, the shipped copy), `SaftUI-ActionBars/shared.lua` (`AB:ConvertProfile`, the profile `version` flag: the model for a one-time conversion), `SaftUI-ActionBars/skin.lua` (`TextConfig`, `AB:OnFontsChanged`).
- `SaftUI-Misc/config.lua` (`st.defaults.auras`: `duration` and `count` of `buffs` and `debuffs`), `SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua` (`AP:UpdateFont`).
- `docs/design-system/10-discrepancies.md` (2) and `docs/research/2026-11-14-fonts-audit.md` (the recommendation).

**What's been considered:** The audit recommended it. AceDB saves only what differs from a default, so a profile that never saved a text's font, size or outline would move to Small text by itself, and one that saved any of them must be converted to keep its copy. A text on Small text takes Small text's own shadow where the copy has none (the action bars' and buffs' copies are shadowless), so an owner who gave Small text a shadow would see it on hotkeys and timers.

**Shape of work:** Small: two defaults, a conversion for each module with its marker, tests for an untouched profile, a profile that saved one field and a profile switch, and the docs. One ticket.

**Open questions:** Whether the conversion should also keep the look of a text that saved only its position (it saved no font field, so it follows). Whether the macro names on bars 1 to 8 keep their old shadow (the in-game check of the fonts plan) before this builds on it.

**Resolved 2026-11-15:** The action bars' hotkey, stack count and macro name and the buffs' and debuffs' duration and stack count ship the shared font Small text (`'pixel'`); their size and outline defaults stay the old copy's, shown only once a typeface is picked. Small text's shadow is 0, 0, as the copies' was, so an untouched profile draws exactly what it did; a profile that customised Small text itself now sees that on these texts (what the change is for). A one-time step per module (`AB:ConvertFonts`, `actionbars.fontsVersion`; `AP:ConvertFonts`, `auras.fontsVersion`) keeps the look of a text that saved a size or an outline without a face (it becomes the old face, Homespun, as a typeface); in a profile already converted to All bars a bar that owned only a size or an outline owns the face too. A saved face stays. One shape is read the other way: a text that picked Small text in the old build while keeping a size or an outline saved beside it (indistinguishable from "never set" once AceDB has put the defaults back) is converted to Homespun at that size. A position-only customisation follows Small text, as it drew the same face. Tests: `tests/actionbars/text_font_default_test.lua`, `tests/misc/buff_text_font_default_test.lua`.

### 2026-11-15 — All bars' Cooldown diff icon misses a bar that owns a size or outline alone

**What:** On All bars, the Cooldown item's diff icon and its Apply to list come from the menu's Size and Outline rows. While All bars' cooldown font is the shared font by button size, those two rows are hidden, and the model skips a hidden option, so a bar that set its own cooldown Size or Outline (which makes that bar draw a typeface) is not named on All bars' Cooldown.

**Why noticed:** Found while moving the action bars' text menus onto the font row (fonts plan, Task 8): `tests/actionbars/page_test.lua` ("the cooldown numbers: Show is Blizzard's setting...") used to expect "Bar 3: Size" and now expects no difference.

**Anchors:** `SaftUI-ActionBars/textoptions.lua` (`SharedFont`, which hides Size and Outline), `SaftUI-Core/Config/optionsmodel.lua` (`OM.ShareState`, which skips a hidden `inner` at the `share and not IsHidden` test), `AB:OwnersOf` in `SaftUI-ActionBars/shared.lua`.

**What's been considered:** The same happens to a hotkey, count or macro name on All bars while All bars' font is a shared font and a bar owns its own size or outline. Fixing it in the model (an item's diff counts hidden options that carry a share) is a Core change that touches every page's items; fixing it in the action bars (keep the rows visible and disable them) changes what the player sees.

**Shape of work:** Small in the model, with a test per page that hides a shared option; or a decision to accept it.

**Open questions:** Which side fixes it, and whether a hidden option's own mark and diff should still count.

**Resolved 2026-11-15:** on All bars a text's Size and Outline stay shown while any bar owns one (`SaftUI-ActionBars/textoptions.lua`, `Hidden`), so the diff icon and Apply to name that bar; a bar's own page still hides them while its font is shared. Tests in `tests/actionbars/page_test.lua`.

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

**Resolved 2026-11-14:** the fonts design, Tasks 1 to 8 (`docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`, `docs/superpowers/plans/2026-11-14-saftui-fonts.md`): six shared fonts named for their jobs, a Heading font, a font row that lists them and every typeface with a typeface's own size, outline, shadow and line spacing behind its dots, every font setting applying at once, and the action bars' and buffs' Font rows on SaftUI's fonts. Its leftovers are the Active entries dated 2026-11-15.

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
- **Your choice:** your button stays bright with a lit border (the accent) and the other three dim, and a small label in the bar names your choice. No button can be clicked.
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
