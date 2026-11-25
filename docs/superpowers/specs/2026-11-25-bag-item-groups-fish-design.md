# Bag item groups: Fish (design)

Date: 2026-11-25. Status: approved by the user on 2026-11-25.

## Why

Blizzard's item class and subclass scatter related items. On WoW Forever (build 1.60.1.71091), raw fish land in five places: Trade Goods > Meat (7/8, most `Raw ...` fish), Trade Goods > Other (7/11: Oily Blackmouth, Firefin Snapper, Stonescale Eel, Lightning Eel, Whimsyfin), Consumable > Food & Drink (0/5: Deviate Fish, Raw Winter Squid, Large Raw Mightfish), Quest (12/0: Raw Plated Armorfish), and so on. No class or subclass rule can gather them. The user wants useful categories, and wants to prove the idea on one group first: **Fish, raw catch only**. Later groups (Cooking ingredients, per-profession mats, fishing gear) come after this works well in game.

## Goals

- A Fish category in the bags that holds the raw fish you catch, and nothing else, on Forever.
- The fish list is generated from Forever's own game data (wago.tools DB2 exports), not typed by hand, with a small checked-in file of corrections.
- A new rule block, "Item group is", that any category can use, so later groups need only data, not code.
- Cheap at runtime: one table lookup per item and rule, with no tooltip scan.

## Non-goals

- Trophy fish ("17 Pound Catfish"), Bloated fish, cooked fish food, fishing gear and bait. These keep their current categories.
- Retail data. On retail, the group has no items, so the block matches nothing and the Fish category stays empty.
- Other groups (Cooking, professions). These are noted as a followup.
- Any runtime download or scraping. Wowhead is out (its terms forbid scraping).

## Anti-goals

- A cooked fish, potion, feather or trophy showing up in Fish. A wrong item there is worse than a missing one, so the list leans exclusive.
- A rerun of the generator silently bringing back an item the corrections removed.
- A noticeable cost on bag updates.

## Approaches considered

1. **Hand-kept ID list in `categorydefaults.lua`** (like `ARCHAEOLOGY`). Cheapest, but it goes stale and doesn't grow into more groups.
2. **Generated item-group data plus a new rule block (picked).** A script pulls Forever's tables and writes a Lua data file. The block reads it. More groups are just more data.
3. **Our own category for every item.** The most complete, but several days of work, most of which is approach 2 anyway.

The user picked 2 on 2026-11-25, scoped to Fish, raw only.

## Design

### Data: how Fish is chosen

From the Forever build's `Item`, `ItemSparse` (names), `ManifestInterfaceData` (icon paths), `SpellReagents`, `SkillLineAbility` and `SkillLine`, a candidate is an item that:

- has class 0, 7, 12 or 15, and
- has a fish icon (path contains `fish`) or a fish word in its name (`fish` anywhere, or one of eel, snapper, salmon, squid, blackmouth, lobster, trout, mackerel, yellowtail, loach, grouper, bass, cod, halibut, albacore as a whole word, so Wild Steelbloom is no eel), and
- is a reagent of a Cooking, Alchemy or Fishing recipe, or has a name starting `Raw `, and
- has no name match on `Deprecated|Monster|Test|Recipe|Writ|Pound|Bloated|Waylaid|Potion|Rune`.

This gives 30 items on build 1.60.1.71091. The corrections file then removes 3 and adds 1:

- remove 5468 Soft Frenzy Flesh (a mob drop), 6370 Blackmouth Oil (made from fish), 273295 Seasonal Fish Steaks (processed)
- add 13757 Lightning Eel (a raw catch no recipe uses)

That leaves **28 fish**: 4603, 6289, 6291, 6303, 6308, 6317, 6358, 6359, 6361, 6362, 6522, 8365, 8959, 13422, 13754, 13755, 13756, 13757, 13758, 13759, 13760, 13888, 13889, 13890, 13893, 21071, 21153, 251524.

### Generator

- `tools/item-groups.cjs` (Node, no dependencies, like the other `tools/*.cjs`). It takes a Forever build (the latest `wowf` build from `https://wago.tools/api/builds` by default), fetches the six CSVs, applies the rules above and `tools/item-groups/fish.overrides.txt`, and writes `SaftUI-Bags/itemgroups_data.lua`.
- It also takes a folder of already-downloaded CSVs (`--from <dir>`), because wago.tools isn't reachable from every machine (it is blocked from the cloud sandbox).
- The overrides file has one line per item: `+13757 Lightning Eel` or `-5468 Soft Frenzy Flesh`. A `-` line always wins, so a rerun never brings a removed item back.
- The data file is committed. Nothing runs at load or build time. Its header names the build it came from, and each ID has its item name in a comment so a diff is readable.
- Rerun it after a content patch. A stale file is only incomplete, never wrong.

### Runtime

- `SaftUI-Bags/itemgroups.lua` (module `INV.ItemGroups`) loads after `itemgroups_data.lua`. Its data is `{ forever = { fish = { [itemID] = true, ... } } }`, and it serves this client's groups: `IG.Set(group)` returns the set, or an empty table. `IG.Groups()` returns the group ids and labels in order (`{ { id = 'fish', label = 'Fish' } }`).
- At ~28 IDs the whole table is a few KB, so it loads with the addon. On-demand loading isn't worth it yet. With many groups it stays one hash lookup per item per block, since each block holds only its own set.

### Rule block

- `group` in `rules.lua`: `{ block = 'group', group = 'fish' }`. The compiler takes `IG.Set(node.group)` once and returns `function(info) return info.itemID ~= nil and set[info.itemID] == true end`. An unknown group id compiles to nil, the way an unfilled block does today.
- Its describer reads "Item group is Fish". It's added to `R.BLOCKS` as "Item group is", and it's new with no group set.
- The rule editor gets a field for it: a pick-one list of `IG.Groups()`, in the style of the existing pickers.

### Default category

- New default `{ id = 'Fish', rule = OR({ block = 'group', group = 'fish' }) }`, placed right before `Flasks/Potions/Food`. It has to come before Food because three raw fish are class Food, and before Trade Goods and Quest, which come later already.
- Existing profiles get it through the defaults' current merge, which places a new default after the default before it in the shipped order.

## Tests (the builder's to finish)

- The block: matches an item in the set, refuses one outside it, and treats an unknown group as unfilled. The describer works too.
- The data: the file loads, every key is a number, and spot checks pass (6303 in, 6292 trophy and 13935 Baked Salmon out).
- Defaults: Fish sits before Flasks/Potions/Food, and a raw fish of class Food files into Fish.
- The generator: its rule and override logic is a pure function, tested on a few CSV rows (a removed item stays out after a rerun).

## Docs

- `.agents/architecture.md` (Bags), plus a line in `.agents/clients.md` on generating the data from `wowf`.
- A followup for the next groups (Cooking ingredients, per-profession mats, fishing gear, trophies), in the full template.

## In-game check

Open the bags on Forever with raw fish, a trophy fish, a Bloated fish and a cooked fish. Only the raw fish should be in Fish.

## Left to the builder

- Field layout in the rule editor, file names within reason, how the generator's CSV parsing is structured, and test file names.
