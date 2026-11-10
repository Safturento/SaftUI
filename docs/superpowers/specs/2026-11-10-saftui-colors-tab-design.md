# SaftUI options, project 3a: the Colors tab of Global Settings

Date: 2026-11-10. Status: revised with the user's answers (2026-11-10), for review.

This is the first part of project 3 in the options redesign the user asked for on 2026-11-09. Projects 1 (the `/sui` window) and 2 (setting sizes, the Position block, every page re-sorted) are done and on `modular`. Project 3 is the Global Settings page with editable fonts, colors and templates. Fonts is already a tab there. **This spec is the colors.** Templates, and Core's other settings with no option yet (such as `misc.icon_trim`, headers, buttons and panels), get their own spec after this one (project 3b).

## Intent

After checking project 2 in game, the user wrote (2026-11-10): "global settings look good, though we still need the colors config here with class colors, rep colors, etc." They skipped the design questions: "you can go ahead and draft the design, just group them by their logical chunks (general, class, rep, etc.)".

Today the profile holds a palette (`st.defaults.colors`, `SaftUI-Core/Config/defaults.lua`) that nothing in `/sui` can edit, apart from the two experience colors on the Experience page. The Colors tab makes the rest of it editable, one titled section per logical chunk. A change should show where you'd look for it. Changes to the colors you'd watch while editing (unit frame class, reputation, power and status colors, and item quality borders) show at once.

## Goals

- **A Colors tab in Global Settings,** between Fonts and Edit mode: Fonts | Colors | Edit mode. Global Settings' desc becomes "Fonts and colors used across SaftUI, and edit mode's grid and snapping."
- **One section per chunk,** in this order, every color a small swatch (four to a line). The user named the text palette's section Text: "If General is just for text colors lets just name it Text".

  | Section | Profile key | Colors, in order |
  | ------- | ----------- | ---------------- |
  | Text | `colors.text` | Text (`normal`), Grey, Red, Orange, Yellow, Green, Blue, Purple, Cyan, White |
  | Buttons | `colors.button` | Normal, Hover, Pushed, Red, Green, Blue, Yellow, Grey, with opacity (`hasAlpha`) |
  | Class | `colors.class` | Death Knight, Demon Hunter, Druid, Evoker, Hunter, Mage, Monk, Paladin, Priest, Rogue, Shaman, Warlock, Warrior |
  | Reputation | `colors.reaction` [1]-[8], `colors.renown` | Hated, Hostile, Unfriendly, Neutral, Friendly, Honored, Revered, Exalted, Renown |
  | Power | `colors.power` | Mana, Rage, Focus, Energy, Runic power, Combo points, Holy power, Chi, Soul shards, Astral power (`LUNAR_POWER`), Insanity, Maelstrom, Fury, Pain, Arcane charges, Runes, then the vehicle and encounter ones: Alternate power (`ALTPOWER`), Ammo (`AMMOSLOT`), Fuel, Steam (`POWER_TYPE_STEAM`), Pyrite (`POWER_TYPE_PYRITE`) |
  | Item quality | `colors.item_quality` [0]-[8] | Poor, Common, Uncommon, Rare, Epic, Legendary, Artifact, Heirloom, WoW Token |
  | Status | `colors.status` | Disconnected, Tapped |

- **Each section ends with a small Reset button.** It asks "Reset the <section> colors to SaftUI's defaults?" (the execute row's `confirm`, through `W.Confirm`), then puts every color of that section back to `st.defaults.colors`.
- **Every color has a tooltip** saying where SaftUI shows it, written from the code's reads of it (e.g. Buttons → Blue: "The accent color: hovered and active controls, and the options window's tabs and slider fill."). The Reset button's tooltip: "Puts every color in this section back to SaftUI's default."
- **A change shows at once where it can** (next section). Where it can't, the section says so in its note (the inline group's `desc`).

## When a change shows

Core tells the modules a color changed, and each module that shows colors redraws what it can.

- **`st:ColorsChanged(group)`** (Core), with `group` the profile key that changed: `'text'`, `'button'`, `'class'`, `'reaction'`, `'renown'`, `'power'`, `'item_quality'` or `'status'`. A set or a Reset calls it. It calls `module:OnColorsChanged(group)` on every module in `st.modules` that has one, each through `Safely` like `Config:UpdateConfig` does, so one module's error doesn't stop the rest.
- **Unit frames** (`UF:OnColorsChanged`, for class, reaction, power and status): `UF:UpdateColors()` (the existing merge of the profile's colors into `UF.oUF.colors`), then for every unit frame (`UF:ForEachUnitFrame`) a `ForceUpdate` of its Health, Power and AdditionalPower elements where it has them, and `UpdateTags` (class-colored names read `UF.oUF.colors.class`). The group test previews are drawn again (`UF:UpdateGroupPreview` for each group in test mode), since they read the profile's colors themselves. This is lighter than `UF:UpdateConfig`, as the picker sets a color on every move of its cursor. `/sui` closes in combat, so this never runs in combat from the window.
- **Bags** (for item quality): every slot's quality border is set again, open or not.
- **The loot feed** reads item quality, reputation, renown and experience colors when it adds a line: new lines take the new colors, and lines already shown keep theirs. No hook.
- **The unit tooltip** reads class and reputation colors each time it shows (next section): the next tooltip takes the new colors. No hook.
- **Text and Buttons:** most of SaftUI reads these when it builds its frames, so these two sections' note says: "Most of SaftUI reads these when it builds its frames: reload (Reload UI, bottom left) to see a change everywhere." No module hook for them.

A profile switch already runs `UF:UpdateConfig`, which calls `UF:UpdateColors`, so unit frames follow a profile's colors as they do today. The tab's getters and setters read `st.config.profile.colors` at call time, never a cached table, as AceDB swaps tables on a profile change.

## Fixes that come with it

Editing these colors would change nothing today, so the tab fixes them.

- **Status colors are stored the wrong shape.** `colors.status.disconnected` and `.tapped` are arrays (`{ 0.6, 0.6, 0.6 }`). `UF:UpdateColors` merges them into oUF's color objects, which read `r`, `g`, `b`, so they have never taken effect. They become `CreateColor(0.6, 0.6, 0.6)` like the other colors. No saved profile can hold an edited one, as no option ever wrote them, so nothing needs migrating.
- **Everything SaftUI skins uses SaftUI's colors.** The user's rule: "Lets get everything in sync for item quality colors, if we skin it use our colors."
  - Item quality: bag, bank and combined bank slots (`SaftUI-Bags/slot.lua`), currencies (`SaftUI-Bags/currencies.lua`) and loot rolls, the real ones and the test ones (`SaftUI-Loot/roll.lua`, twice), use Blizzard's `ITEM_QUALITY_COLORS` today. They take the profile's `colors.item_quality[quality]`, as the loot feed and the minimap's difficulty badge already do. Blizzard's stays only as the fallback for a quality the profile has no color for (none, once Heirloom and WoW Token have defaults).
  - Class and reputation: the unit tooltip's name and border (`SaftUI-Misc/tooltip.lua`) use Blizzard's `RAID_CLASS_COLORS` and `FACTION_BAR_COLORS`. They take the profile's `colors.class` and `colors.reaction`, with the same lookups as now.
  - The character frame isn't skinned (it keeps Blizzard's look, and SaftUI only adds item levels and gems on top), so its item borders stay Blizzard's.
- **Heirloom and WoW Token** (`item_quality[7]` and `[8]`) get defaults: Blizzard's, `CreateColor(0, 0.8, 1)` for both.
- **Arcane charges' default blue is 1.94** (`CreateColor(0.00, 0.67, 1.94)`), above 1; it becomes 0.94.

## Constraints

- **Storage stays AceDB's.** Colors live where they are (`st.config.profile.colors`), as `CreateColor` objects. AceDB copies the defaults' fields, functions included, into each profile's table and strips the ones equal to the default on logout. A set writes `r`, `g`, `b` (and `a` for Buttons) onto the profile's object, as the Experience page's colors already do (`SaftUI-Misc/experience.lua`), and never replaces the table. Reset copies the default's fields the same way.
- **Experience and totem bar colors stay on their own pages** (Experience, Totem bar), not repeated here: a setting in two places shows twice in search.
- **The tab is a Core module's page,** like Fonts (`SaftUI-Core/Media/fonts.lua`): a new `SaftUI-Core/Media/colors.lua` with `GetConfigTable`, loaded after `fonts.lua` in both Core TOCs. `Config:GetOptionsTable` (`SaftUI-Core/Config/config.lua`) puts it in Global Settings' tabs with Fonts and Edit mode.
- **The finished-page rules from project 2:** every option has a desc, SaftUI's `size` and no Ace `width`. `tests/core/options_desc_test.lua` checks the built pages; the Colors tab is one of them.
- **No Blizzard frame is touched,** apart from the color picker, used as today through the color widget.

## Non-goals

- **Live Text and Buttons colors.** That would need every module to restyle from the palette; reloading is enough for colors set once.
- **Templates and Core's other settings:** project 3b.
- **Role and rune colors, and a "use Blizzard's class colors" switch.** The profile has no role or rune colors (`UF:UpdateColors` falls back to oUF's), and SaftUI has its own muted class palette. The user wants both followed up: `docs/followups.md`, "Colors tab: role and rune colors, and a switch for Blizzard's class colors".
- **Recoloring loot feed lines already shown.**

## Anti-goals

- A color on the tab that changes nothing when you edit it. That's why the status fix, and the bag, roll, currency and tooltip switch to the profile's colors, are in scope.
- Anything that changes how existing profiles are saved or read.

## Tests

- The Colors tab sits between Fonts and Edit mode in Global Settings. Its sections, their titles and their colors' names are as in the table above, in that order. Every color is a small `color` row with a desc; Buttons' have `hasAlpha`.
- A color's get returns the profile's color. Its set writes it onto the profile's object (the same table, so its methods stay) and calls `st:ColorsChanged` with its group. After a profile switch, get and set reach the new profile's colors.
- Reset puts a section's defaults back and calls `st:ColorsChanged` once.
- `st:ColorsChanged` calls `OnColorsChanged` on each module that has it; one module's error doesn't stop the others.
- `UF:OnColorsChanged('class')` leaves `UF.oUF.colors.class` matching the profile, and force-updates each frame's Health and Power and its tags.
- After `UF:UpdateColors`, `UF.oUF.colors.disconnected` and `.tapped` match the profile's status colors (the array regression).
- A bag slot's quality border, a currency's and a loot roll's are the profile's color for its quality, and Blizzard's for a quality the profile has no color for.
- The unit tooltip's name and border take the profile's class color for a player and its reaction color for an NPC.

## Left to the builder

- Each color's tooltip text, from where the code reads it.
- How Bags sets every slot's quality border again, through the code it already uses to color one.
- Whether the section data (keys, names, order) is a table in `colors.lua` that the tab and its tests both read.
