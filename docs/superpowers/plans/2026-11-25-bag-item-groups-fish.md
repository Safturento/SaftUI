# Bag item groups: Fish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Fish bag category that holds exactly the raw fish you catch on WoW Forever, driven by a generated item-group data file and a new "Item group is" rule block.

**Architecture:** A Node script (`tools/item-groups.cjs`) reads six wago.tools DB2 CSVs of the latest `wowf` build, picks the fish, applies a checked-in overrides file and writes `SaftUI-Bags/itemgroups_data.lua`. `SaftUI-Bags/itemgroups.lua` (`INV.ItemGroups`) serves this client's sets; `rules.lua` gains a `group` block that compiles to one hash lookup; `categorydefaults.lua` gains a Fish default before Flasks/Potions/Food; the rule editor gets a pick-one field.

**Tech Stack:** Lua 5.1 (WoW addon; tests via `tests/run`, lupa), Node 24 with no dependencies (`node --test` for the generator's tests).

**Spec:** `docs/superpowers/specs/2026-11-25-bag-item-groups-fish-design.md`

## Global Constraints

- Node has no dependencies (like the other `tools/*.cjs`). On this machine Node is `~/.local/share/fnm/aliases/default/bin/node` (not on a non-interactive PATH).
- The data file is committed; nothing runs at load or build time. Its header names the build; each ID has its item name in a comment.
- Overrides: one line per item, `+13757 Lightning Eel` or `-5468 Soft Frenzy Flesh`. A `-` line always wins.
- Runtime data shape: `{ forever = { fish = { [itemID] = true, ... } } }`. `IG.Set(group)` returns the set or an empty table; `IG.Groups()` returns `{ { id = 'fish', label = 'Fish' } }`.
- Block: `{ block = 'group', group = 'fish' }`; describer "Item group is Fish"; `R.BLOCKS` label "Item group is"; new with no group set; unknown group compiles to nil (unreadable).
- Default: `{ id = 'Fish', rule = OR({ block = 'group', group = 'fish' }) }`, right before `Flasks/Potions/Food`.
- Repo rules: commits `module: imperative summary` lowercase with the `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` line; stage by explicit path; never `git stash`, never `sed -i`, never edit any `Libraries/`; keep each file's line endings (all Bags `.lua` are LF except `utilities.lua`).
- Fish selection (on `Item`, `ItemSparse.Display_lang`, `ManifestInterfaceData` FilePath+FileName lowercased keyed by `Item.IconFileDataID`, `SpellReagents.Reagent_0..7`, `SkillLineAbility.SkillLine/Spell`, `SkillLine.DisplayName_lang`):
  - `ClassID` in {0, 7, 12, 15};
  - icon path contains `fish`, or the name matches `/fish/i`, or one of eel, snapper, salmon, squid, blackmouth, lobster, trout, mackerel, yellowtail, loach, grouper, bass, cod, halibut, albacore as a whole word (case-insensitive; "Wild Steelbloom" must not match);
  - is a reagent of a spell taught by a SkillLine whose `DisplayName_lang` is Cooking, Alchemy or Fishing (parent and child lines), or the name starts `Raw `;
  - the name doesn't match `/Deprecated|Monster|Test|Recipe|Writ|Pound|Bloated|Waylaid|Potion|Rune/`.
  On 1.60.1.71091 that is 30 items; with the overrides (`-5468`, `-6370`, `-273295`, `+13757`) it is the spec's 28. (Checked by the planner against the real CSVs.)

## Review Focus

- A CSV field with a quoted comma or `""` in an item name (e.g. `"Gnomish ""Fixer"""`), and rows shorter than the header (wago omits trailing columns): the parser must not shift columns. Test in Task 1.
- An override that both adds and removes the same ID, or a removed ID that the rules select: removal wins. Test in Task 1.
- A saved profile with its own category named "Fish", or a saved order that predates Fish: the new default still appears, placed after Mounts, and the names don't collide (existing numbering). Test in Task 2.
- A `group` block with `group` a non-string, or an id no group has, inside an AND or negated: unreadable, never matches everything. Test in Task 2.
- Retail: the Fish category is empty and nothing errors; the editor list still offers Fish. Test in Task 2.

---

### Task 1: The generator

Independent of Task 2 (separate worktree).

**Files:**
- Create: `tools/item-groups.cjs`
- Create: `tools/item-groups/fish.overrides.txt`
- Test: `tests/tools/item_groups.test.cjs`

**Interfaces:**
- Produces (`module.exports` of `tools/item-groups.cjs`; the CLI runs only when `require.main === module`):
  - `parseCSV(text: string) -> Array<object>` rows keyed by the header; missing trailing fields are `''`.
  - `selectFish(tables: { Item, ItemSparse, ManifestInterfaceData, SpellReagents, SkillLineAbility, SkillLine }: each Array<object>) -> Array<{ id: number, name: string }>`.
  - `parseOverrides(text: string) -> { add: Map<number,string>, remove: Set<number> }` (blank lines and `#` comments ignored; any other malformed line throws naming its line number).
  - `applyOverrides(candidates, overrides) -> Array<{id,name}>` sorted by id, removals winning over both rules and `+` lines.
  - `renderLua({ build: string, groups: { fish: Array<{id,name}> } }) -> string`.
  - CLI: `node tools/item-groups.cjs [--build <version>] [--from <dir>] [--out <path>]`. Default build: the first `wowf` entry of `https://wago.tools/api/builds` (its `version`). CSVs from `https://wago.tools/db2/<Table>/csv?build=<version>`, or `<dir>/<Table>.csv` with `--from` (then `--build` is required, since it goes in the header). Default out: `SaftUI-Bags/itemgroups_data.lua`. Prints the build and the count per group.

- [ ] **Step 1: Write the failing tests** (`node:test` + `node:assert/strict`, requiring `../../tools/item-groups.cjs`)
  - `parseCSV`: quoted comma and `""` in a name; a short row gets `''` for missing columns; CRLF input.
  - `selectFish` on a hand-built mini table set: picks `Raw Slitherskin Mackerel` (class 7, `Raw `), `Oily Blackmouth` (class 7, monsterhead icon, Cooking reagent), `Deviate Fish` (class 0, reagent); refuses `Wild Steelbloom` (Alchemy reagent, no fish icon, "eel" only inside a word), `17 Pound Catfish` (Pound), `Baked Salmon` (class 0, not a reagent, not `Raw `), a class 4 item named `Raw Fish Helm`.
  - `parseOverrides`: `+13757 Lightning Eel`, `-5468 Soft Frenzy Flesh`, comment and blank lines; `x123` throws with "line 3".
  - `applyOverrides`: `-5468` removes a selected item; an ID in both `+` and `-` stays out; a `+` adds with its name; output sorted.
  - `renderLua`: contains `wowf 1.60.1.71091`, `INV.ItemGroupsData = {`, `forever = {`, `fish = {`, and `[13757] = true, -- Lightning Eel`.
- [ ] **Step 2: Run** `~/.local/share/fnm/aliases/default/bin/node --test tests/tools/` — expect FAIL (module missing).
- [ ] **Step 3: Implement** `tools/item-groups.cjs` with a header comment in the style of `tools/fade-to-tga.cjs` (what it makes, how to run it from the repo root, `--from` for machines that can't reach wago.tools, "rerun after a content patch"). Rendered file:

```lua
-- Generated by tools/item-groups.cjs from wowf <build>. Don't edit by hand:
-- change tools/item-groups/<group>.overrides.txt and run it again.
local INV = SaftUI:GetModule('Inventory')

INV.ItemGroupsData = {
	forever = {
		fish = {
			[4603] = true, -- Raw Spotted Yellowtail
			...
		},
	},
}
```
  Use `fetch` (Node 24) for the network path. Item names in comments: strip newlines.
- [ ] **Step 4: Write `tools/item-groups/fish.overrides.txt`** with a comment header and the four lines from the spec (`-5468 Soft Frenzy Flesh`, `-6370 Blackmouth Oil`, `-273295 Seasonal Fish Steaks`, `+13757 Lightning Eel`), each with a `#` reason line above it.
- [ ] **Step 5: Run** the tests again — expect PASS.
- [ ] **Step 6: Commit** `tools: generate the bag item groups from the forever build's tables` (the three files).

### Task 2: Item groups at runtime, the group block and the Fish default

Independent of Task 1 (separate worktree). The real data file comes in Task 4; tests here set `INV.ItemGroupsData` themselves before loading `itemgroups.lua`.

**Files:**
- Create: `SaftUI-Bags/itemgroups.lua`
- Modify: `SaftUI-Bags/rules.lua` (compiler, describer, `R.BLOCKS` entry after `items`, header comment)
- Modify: `SaftUI-Bags/categorydefaults.lua` (Fish before Flasks/Potions/Food)
- Modify: `SaftUI-Bags/SaftUI-Bags.toc` (`itemgroups_data.lua` then `itemgroups.lua`, after `itemclasses.lua`, before `rules.lua`)
- Modify: `tests/bags/bag_world.lua`, `tests/bags/container_helpers.lua` and any other loader of `rules.lua` (`grep -rn "rules" tests/bags/*.lua tests/lib`) to load `itemgroups.lua` before `rules.lua` (only that: the data file doesn't exist until Task 4, which adds its load; tests here set `INV.ItemGroupsData` themselves).
- Modify: `tests/bags/category_defaults_test.lua` (the expected list gains Fish; Fish joins Devices as exempt from "every default has an item it catches" on retail, or gets a forever fixture), and any other test counting the defaults.
- Test: `tests/bags/item_groups_test.lua`

**Interfaces:**
- Consumes: `INV.ItemGroupsData` (Task 4 writes the real one; may be nil).
- Produces:
  - `INV.ItemGroups` = `IG`; `IG.Groups() -> { { id = 'fish', label = 'Fish' } }` (the list lives in `itemgroups.lua`); `IG.Label(id) -> string | nil` (nil for an unknown id or a non-string); `IG.Set(id) -> table` (this client's set: `INV.ItemGroupsData.forever[id]` when `st.forever`, else `.retail[id]`; an empty table when missing). Read `INV.ItemGroupsData` at call time, not at load, so tests and load order can't strand it.
  - `compilers.group(node)`: nil unless `IG.Label(node.group)`; else `local set = IG.Set(node.group)` once and `function(info) return info.itemID ~= nil and set[info.itemID] == true end`.
  - `describers.group(node)`: `'Item group is ' .. (IG.Label(node.group) or tostring(node.group))`.
  - `R.BLOCKS` entry `{ id = 'group', label = 'Item group is', new = function() return {} end }`.

- [ ] **Step 1: Write the failing tests** in `tests/bags/item_groups_test.lua` (world from `bags/bag_world.lua`; set `INV.ItemGroupsData = { forever = { fish = { [6303] = true } } }` and reset the defaults cache):
  - `IG.Groups()` is the one Fish entry; `IG.Label('fish') == 'Fish'`, `IG.Label('nope') == nil`, `IG.Label(5) == nil`.
  - forever: `IG.Set('fish')[6303] == true`; retail world: `next(IG.Set('fish')) == nil`; `IG.Set('nope')` is an empty table; no `INV.ItemGroupsData` at all → empty table, no error.
  - Block: `OR(group fish)` matches itemID 6303, not 6292, not an info with no itemID; `{ block = 'group' }` (no group), `group = 'nope'` and `group = 5` are unreadable: `OR` of it matches nothing, `AND(it, anything)` matches nothing, `NOT` of it matches nothing.
  - `R.Describe` of a group block → `Item group is Fish`; `R.NewBlock('group')` is `{ block = 'group' }` and unreadable; `R.BlockType('group').label == 'Item group is'`.
  - Defaults (forever): `Fish` sits immediately before `Flasks/Potions/Food`; a class Food item (Consumable 0/5) with itemID 6303 files into `Fish`, one with itemID 13935 files into `Flasks/Potions/Food`; a class 7/8 itemID 6303 files into Fish, not Trade Goods.
  - Retail: itemID 6303 class 7 files into Trade Goods; `#take_errors() == 0`.
  - Profiles: a saved `order` without Fish (the full old order) puts Fish right after Mounts; a custom category named "Fish" beside it keeps both, the default numbered per the existing rule (assert whatever `GetCategoryList` names it today: not two entries with the same name).
- [ ] **Step 2: Run** `tests/run tests/bags/item_groups_test.lua` — expect FAIL.
- [ ] **Step 3: Implement** `itemgroups.lua` (header comment in the repo's style), the block in `rules.lua`, the default, the TOC lines, and the test loaders.
- [ ] **Step 4: Run** the new file, then `tests/run tests/bags`, and fix the tests that count or list the defaults (update the expected list; don't weaken unrelated assertions). Then the full `tests/run -j2` — expect PASS.
- [ ] **Step 5: Commit** `bags: an item group rule block, and a Fish category before food`.

### Task 3: The rule editor's group field

Depends on Task 2.

**Files:**
- Modify: `SaftUI-Bags/ruleeditor.lua` (`GroupEntries()`, `FIELDS.group`, the header's field-name list gains `group`)
- Test: `tests/bags/rule_editor_test.lua` (add cases in its existing style)

**Interfaces:**
- Consumes: `INV.ItemGroups.Groups()`, `IG.Label`.
- Produces: `FIELDS.group(lay, node)`: one `lay:Field('group', FIELD_WIDTH, text, open)` like `ClassField`: text is `IG.Label(node.group)` or `'Pick a group'`; open is `W.OpenList(field, GroupEntries(), now and now.group, pick)`, where a pick sets `n.group` (returning false when unchanged).

- [ ] **Step 1: Write the failing tests**: a rule with a new group block draws a `group` field reading `Pick a group`; opening it lists `Fish`; picking it commits `{ block = 'group', group = 'fish' }` and the field then reads `Fish`; picking it again changes nothing (no commit). Follow how the file tests `class`.
- [ ] **Step 2: Run** `tests/run tests/bags/rule_editor_test.lua` — expect FAIL.
- [ ] **Step 3: Implement** `GroupEntries()` and `FIELDS.group`.
- [ ] **Step 4: Run** the file, then `tests/run -j2` — expect PASS.
- [ ] **Step 5: Commit** `bags: pick an item group in the rule editor`.

### Task 4: Generate the data

Depends on Tasks 1 and 2. Controller-run (needs wago.tools).

**Files:**
- Create: `SaftUI-Bags/itemgroups_data.lua` (generated)
- Modify: `tests/bags/bag_world.lua` / `container_helpers.lua` to load the real data file before `itemgroups.lua`
- Test: `tests/bags/item_groups_data_test.lua`

- [ ] **Step 1: Write the failing test**: the real file loads; `INV.ItemGroupsData.forever.fish` exists; every key is a number and every value `true`; 6303 in; 6292 (trophy) and 13935 (Baked Salmon) out; `tests/bags/item_groups_test.lua`'s own data still overrides it.
- [ ] **Step 2: Run** it — expect FAIL (file missing).
- [ ] **Step 3: Run** `node tools/item-groups.cjs` (latest `wowf`, 1.60.1.71091 or newer). Expect `fish: 28`. If the build changed and the count differs, diff against the spec's list and report; never hand-type data. If wago.tools is unreachable, stop and report.
- [ ] **Step 4: Run** `tests/run -j2` and `node --test tests/tools/` — expect PASS.
- [ ] **Step 5: Commit** `bags: the fish item group from wowf <build>`.

### Task 5: Docs

- Modify: `.agents/architecture.md` (Bags: the item groups, the block, the data file and its generator), `.agents/clients.md` (generating the data from `wowf`; Forever-only data), `.agents/testing.md` (the generator's `node --test tests/tools/`), `AGENTS.md` repo layout (`tools/` row: `item-groups.cjs`; `SaftUI-Bags/` row: `itemgroups.lua`), `README.md` if its Bags or tools sections are affected, `docs/followups.md` (full-template entry for the next groups: Cooking ingredients, per-profession mats, fishing gear, trophies; ToC updated).
- [ ] Run `agents-doc-parity-check` and `readme-freshness-check`; commit `docs: the bag item groups`.
