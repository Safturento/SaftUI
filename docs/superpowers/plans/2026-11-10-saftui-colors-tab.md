# SaftUI Colors Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Colors tab in Global Settings that edits the profile's palette in seven sections, with unit frames and bag borders showing a change at once and every SaftUI skin using the profile's colors.

**Architecture:** A new Core module (`SaftUI-Core/Media/colors.lua`, module `Colors`) holds the section data, builds the tab, and owns two helpers: `st:ColorsChanged(group)`, which calls `OnColorsChanged(group)` on every module that has one, and `st:QualityColor(quality)`. `Config:GetOptionsTable` nests the tab between Fonts and Edit mode. Unit frames and Bags implement `OnColorsChanged`; bags, currencies, loot rolls and the unit tooltip switch from Blizzard's color tables to the profile's.

**Tech Stack:** Lua 5.1 WoW addon, Ace3 (AceDB-3.0 profile), SaftUI's own options window; tests on Lua 5.1 via `tests/run` (`.agents/testing.md`).

**Spec:** `docs/superpowers/specs/2026-11-10-saftui-colors-tab-design.md`

## Global Constraints

- Both clients: WoW Forever (interface 16001) and retail (120000). No build step.
- Colors stay in `st.config.profile.colors` as `CreateColor` objects. A set writes `r`, `g`, `b` (and `a` for Buttons) onto the profile's object and never replaces the table. Getters and setters read `st.config.profile.colors` at call time, never a cached table.
- Every option has a `desc`, SaftUI's `size`, and no Ace `width`.
- No Lua field is written onto a Blizzard frame (`.agents/taint.md`). The tooltip and roll changes only change where a color comes from.
- Exact copy:
  - Global Settings desc: `Fonts and colors used across SaftUI, and edit mode's grid and snapping.`
  - Text and Buttons section note: `Most of SaftUI reads these when it builds its frames: reload (Reload UI, bottom left) to see a change everywhere.`
  - Reset button: name `Reset`, desc `Puts every color in this section back to SaftUI's default.`, confirm text `Reset the <section name> colors to SaftUI's defaults?` (e.g. `Reset the Class colors to SaftUI's defaults?`).
- `tests/run` must pass. Don't use the shared git stash. Check a file's line endings (`file <path>`) before any `sed -i`; never run it on a CRLF file.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Dragging the picker over a raid's class colors:** the refresh must stay light (Health, Power, AdditionalPower, tags), never `UF:UpdateConfig` or `UF:ApplyConfig`. Task 3 tests this.
2. **Unit frames not enabled** (module off, or before `OnEnable`): a color change does nothing and raises nothing. Task 3 tests this.
3. **Empty and locked bag slots** keep their border when quality colors change. Task 4 tests this.
4. **A profile switch while the tab is open:** get and set reach the new profile's colors. Task 2 tests this.
5. **A quality with no color anywhere** (unknown, or nil) gives no error and a black border. Tasks 1 and 4 test this.

---

### Task 1: Core: default fixes, `st:ColorsChanged`, `st:QualityColor`

**Files:**
- Modify: `SaftUI-Core/Config/defaults.lua` (`st.defaults.colors`)
- Create: `SaftUI-Core/Media/colors.lua`
- Modify: `SaftUI-Core/SaftUI-Core_Forever.toc`, `SaftUI-Core/SaftUI-Core_Mainline.toc` (`Media\colors.lua` right after `Media\fonts.lua`)
- Modify: `tests/lib/shell.lua` (`load_core_helpers` loads `SaftUI-Core/Media/colors.lua` right after `Media/fonts.lua`)
- Test: `tests/core/colors_test.lua` (new; sets up with `load_test_file('core/config_helpers.lua')`)
- Docs: `.agents/architecture.md` (the module hook), `.agents/testing.md` (the new test file's row)

**Interfaces:**
- Produces:
  - `local CO = st:NewModule('Colors')` in `colors.lua`.
  - `st:ColorsChanged(group)` (`group` a string: `'text'`, `'button'`, `'class'`, `'reaction'`, `'renown'`, `'power'`, `'item_quality'` or `'status'`). It calls `module:OnColorsChanged(group)` for every module in `st.modules` that has one, each in `xpcall(..., geterrorhandler())`.
  - `st:QualityColor(quality)` returns `st.config.profile.colors.item_quality[quality]`. Without one, it returns `ITEM_QUALITY_COLORS[quality]`. Without either, or for a nil quality, it returns nil. Either object has `r`, `g`, `b`.

- [ ] **Step 1: Write the failing tests** in `tests/core/colors_test.lua`:

```lua
test('the status colors are colors with r, g and b, not lists, so unit frames read them', function()
	for _, key in ipairs({ 'disconnected', 'tapped' }) do
		local c = st.config.profile.colors.status[key]
		eq(c.r, 0.6, key); eq(c.g, 0.6, key); eq(c.b, 0.6, key)
		eq(c[1], nil, key .. ' is not a list')
		check(c.GetRGB, key .. ' has the color methods')
	end
end)

test('Heirloom and WoW Token have colors, and Arcane charges is in range', function()
	for _, q in ipairs({ 7, 8 }) do
		local r, g, b = st.config.profile.colors.item_quality[q]:GetRGB()
		eq(r .. ',' .. g .. ',' .. b, '0,0.8,1', 'quality ' .. q)
	end
	eq(st.config.profile.colors.power.ARCANE_CHARGES.b, 0.94)
end)

test("QualityColor: the profile's color, else Blizzard's, else nil", function()
	check(st:QualityColor(3) == st.config.profile.colors.item_quality[3], "the profile's own object")
	_G.ITEM_QUALITY_COLORS = { [9] = { r = 1, g = 0, b = 0 } }
	eq(st:QualityColor(9).r, 1, "Blizzard's for a quality the profile has no color for")
	eq(st:QualityColor(10), nil, 'no color anywhere')
	eq(st:QualityColor(nil), nil, 'no quality')
end)

test('ColorsChanged calls OnColorsChanged with the group on every module that has one, past one that errors', function()
	local got = {}
	st:NewModule('ColorsTestA').OnColorsChanged = function() error('boom') end
	st:NewModule('ColorsTestB').OnColorsChanged = function(_, group) got[#got + 1] = group end
	st:ColorsChanged('class')
	eq(table.concat(got, ','), 'class')
	eq(#take_errors(), 1, 'the error is reported, not raised')
end)
```

- [ ] **Step 2: Run `tests/run tests/core/colors_test.lua`.** Expected: FAIL (the status colors are lists, there's no `st:QualityColor` or `st:ColorsChanged`).

- [ ] **Step 3: Make the default fixes** in `defaults.lua`:
  - `status.disconnected` and `status.tapped` become `CreateColor(0.6, 0.6, 0.6)`;
  - `item_quality[7]` and `item_quality[8]` become `CreateColor(0, 0.8, 1)`, with `-- Heirloom` and `-- WoW Token` comments;
  - `ARCANE_CHARGES` becomes `CreateColor(0.00, 0.67, 0.94)`.

  Then create `colors.lua` with the module and the two helpers, and add it to both TOCs and to `load_core_helpers`.

- [ ] **Step 4: Run `tests/run`.** Expected: every file passes.

- [ ] **Step 5: Docs.**
  - `.agents/architecture.md`: a module that shows profile colors can define `OnColorsChanged(group)`. `st:ColorsChanged(group)` calls it after a Colors tab change (the groups listed above). Anything that colors by item quality uses `st:QualityColor`.
  - `.agents/testing.md`: a row for `tests/core/colors_test.lua`.
  - Bump `last_updated` on each doc you change.

- [ ] **Step 6: Commit:** `core: st:ColorsChanged and st:QualityColor; status colors are colors, Heirloom and WoW Token get defaults, Arcane charges in range`

---

### Task 2: The Colors tab

**Files:**
- Modify: `SaftUI-Core/Media/colors.lua` (`CO.SECTIONS`, `CO:GetConfigTable()`)
- Modify: `SaftUI-Core/Config/config.lua` (`Config:GetOptionsTable`: nest Colors, new desc)
- Test: `tests/core/colors_test.lua`, `tests/core/options_window_test.lua` (the "Global Settings has Fonts and Edit mode tabs" test)
- Docs: `.agents/edit-mode.md` ("Sidebar groups": three tabs), `README.md` (the `/sui` line: Global Settings → Colors, and which colors show at once)

**Interfaces:**
- Consumes: `st:ColorsChanged(group)` (Task 1).
- Produces:
  - `CO.SECTIONS`, an array of sections, each `{ key, name, note, hasAlpha, colors }`:
    - `key` is the section group's key: `text`, `button`, `class`, `reaction`, `power`, `item_quality`, `status`.
    - `note` is the Global Constraints note for Text and Buttons, else nil.
    - `hasAlpha` is true for Buttons only.
    - `colors` is an array of `{ group, key, name, desc }`. `group` is the profile key passed to `st:ColorsChanged`. `key` is the subkey, nil for `renown`, which is `colors.renown` itself.
  - `CO:GetConfigTable()` returns the tab: `{ type = 'group', name = 'Colors', order = 2, args = { [section.key] = section group } }`.
    - Each section group is an inline group: `inline = true`, `order` = its index, `name`, and `desc` = its note.
    - Its args are one `color` row per color, keyed `tostring(key)` (`'renown'` for renown), plus `reset`.
    - A color row: `size = 'small'`, `order` = its index, the color's `name` and `desc`, `hasAlpha` for Buttons, and its own `get` and `set`.
    - `reset` is an execute row: `size = 'small'`, order after the colors, `confirm = true`, `confirmText`.

The sections, in order (names verbatim; the profile key is in brackets where it differs):

| Section | Colors |
| ------- | ------ |
| Text (`text`) | Text (`normal`), Grey, Red, Orange, Yellow, Green, Blue, Purple, Cyan, White |
| Buttons (`button`) | Normal, Hover, Pushed, Red, Green, Blue, Yellow, Grey |
| Class (`class`) | Death Knight (`DEATHKNIGHT`), Demon Hunter (`DEMONHUNTER`), Druid, Evoker, Hunter, Mage, Monk, Paladin, Priest, Rogue, Shaman, Warlock, Warrior |
| Reputation (`reaction`) | Hated (1), Hostile (2), Unfriendly (3), Neutral (4), Friendly (5), Honored (6), Revered (7), Exalted (8), then Renown (group `renown`, no key) |
| Power (`power`) | Mana, Rage, Focus, Energy, Runic power (`RUNIC_POWER`), Combo points (`COMBO_POINTS`), Holy power (`HOLY_POWER`), Chi, Soul shards (`SOUL_SHARDS`), Astral power (`LUNAR_POWER`), Insanity, Maelstrom, Fury, Pain, Arcane charges (`ARCANE_CHARGES`), Runes, Alternate power (`ALTPOWER`), Ammo (`AMMOSLOT`), Fuel, Steam (`POWER_TYPE_STEAM`), Pyrite (`POWER_TYPE_PYRITE`) |
| Item quality (`item_quality`) | Poor (0), Common (1), Uncommon (2), Rare (3), Epic (4), Legendary (5), Artifact (6), Heirloom (7), WoW Token (8) |
| Status (`status`) | Disconnected (`disconnected`), Tapped (`tapped`) |

Behavior:
- **get** returns the profile color's `GetRGBA()`.
- **set** `(info, r, g, b, a)` writes `r`, `g`, `b`, and `a` only where `hasAlpha`, onto the profile's object. Then it calls `st:ColorsChanged(group)`.
- **Reset** copies `r`, `g`, `b`, `a` from `st.defaults.colors` onto each of the section's profile colors. Then it calls `st:ColorsChanged` once per distinct group in the section, in order: Reputation gives `'reaction'`, then `'renown'`.
- **Tooltips:** each color's `desc` says where SaftUI shows it, from the code's reads of it. Write them from a grep of each color's uses. Example: Buttons → Blue: "The accent color: hovered and active controls, and the options window's tabs and slider fill."

- [ ] **Step 1: Write the failing tests.** In `tests/core/colors_test.lua`, the tab's table comes from `st.Config:GetOptionsTable().Fonts.args.colors`, with its sections and rows sorted by `order`. Tests:
  - `'the sections and their colors, in order, as small color swatches with tooltips'`:
    - the section names joined: `'Text,Buttons,Class,Reputation,Power,Item quality,Status'`;
    - each section's color names joined, exactly as in the table above;
    - every color row is type `color`, size `small`, with a non-empty `desc`;
    - `hasAlpha` is true exactly in Buttons;
    - every section's last row is `reset`: an `execute`, size `small`, with `confirm == true`;
    - Class's `confirmText` is `Reset the Class colors to SaftUI's defaults?`.
  - `'Text and Buttons say a change shows after a reload; the others have no note'`: the two groups' `desc` equal the exact note, and the other five are nil.
  - `'a set writes onto the profile color itself and says which group changed'`:
    - Replace `st.ColorsChanged` with a recorder, and restore it after.
    - Mage: set `0.1, 0.2, 0.3` and check the profile table is the same object, `GetRGB()` gives the new values, and the recorder got `'class'`.
    - Buttons → Blue: set with alpha `0.5`; `a` is `0.5`.
    - Text → Red: set with alpha `0.5`; `a` is unchanged.
    - Renown: set; it writes `st.config.profile.colors.renown`, and the recorder got `'renown'`.
  - `'after a profile switch, get and set reach the new profile'`:
    - Set Mage in the first profile, then `st.config:SetProfile('ColorsTestTwo')`.
    - get gives the default Mage color.
    - A set there leaves the first profile's value as it was when you switch back.
  - `'Reset puts a section back to the defaults and says so once per group'`:
    - Change two class colors and run Class's `reset.func`: both equal `st.defaults.colors.class`, and the recorder got `'class'` once.
    - Reputation's reset gives the recorder `'reaction,renown'`.

  In `options_window_test.lua`, change the Global Settings test:
  - tab keys `'fonts,colors,editmode'`;
  - tab names `'Fonts,Colors,Edit mode'`;
  - `root.Colors == nil`;
  - `root.Fonts.desc` is the exact Global Settings desc.

- [ ] **Step 2: Run `tests/run tests/core/colors_test.lua tests/core/options_window_test.lua`.** Expected: FAIL (there's no Colors tab).

- [ ] **Step 3: Implement** `CO.SECTIONS` and `CO:GetConfigTable()`. In `Config:GetOptionsTable`:
  - take `options.Colors` into Global Settings' tabs as `colors` (order 2), with Edit mode at order 3;
  - set `options.Colors = nil`;
  - use the new desc.

  Update the comment above `GetOptionsTable` to name the three tabs.

- [ ] **Step 4: Run `tests/run`.** Expected: every file passes, `options_desc_test.lua` and `options_validate_test.lua` included. They build the tree with the Colors tab in it.

- [ ] **Step 5: Docs.**
  - `.agents/edit-mode.md` "Sidebar groups": Global Settings has three tabs, Fonts, Colors (from `SaftUI-Core/Media/colors.lua`, tab key `colors`) and Edit mode. Colors' getters and setters bind each row to its color, and don't read `info`.
  - `README.md`: in the `/sui` paragraph, Global Settings → Colors edits SaftUI's colors, in sections Text, Buttons, Class, Reputation, Power, Item quality and Status. Unit frames and bags show a change at once; text and button colors show after a reload.
  - Bump `last_updated`.

- [ ] **Step 6: Commit:** `config: a Colors tab in Global Settings, between Fonts and Edit mode`

---

### Task 3: Unit frames show a color change at once

**Files:**
- Modify: `SaftUI-Unitframes/unitframes.lua` (new `UF:OnColorsChanged`, next to `UF:UpdateColors`)
- Test: `tests/unitframes/colors_test.lua` (new)
- Docs: `.agents/testing.md` (the new test file's row)

**Interfaces:**
- Consumes: `st:ColorsChanged(group)` calls `OnColorsChanged(group)` (Task 1). The profile's status colors are `CreateColor` objects (Task 1).
- Produces: `UF:OnColorsChanged(group)`. It does nothing unless `self.units` is set (the module is enabled) and `group` is `'class'`, `'reaction'`, `'power'` or `'status'`. Otherwise:
  1. `self:UpdateColors()`.
  2. For every frame of `self:ForEachUnitFrame`, `frame[name]:ForceUpdate()` for each of `Health`, `Power` and `AdditionalPower` where `frame:IsElementEnabled(name)`, then `frame:UpdateTags()`.
  3. `self:UpdateGroupPreview(group)` for each key of `self.testGroups`.

  It never calls `UpdateConfig` or `ApplyConfig`.

- [ ] **Step 1: Write the failing tests.** Load `unitframes.lua` after `load_core_helpers()`, with a stand-in oUF set as `addon_namespace('SaftUI-Unitframes').oUF` before the load. Its `colors` holds:
  - `class = { MAGE = CreateColor(1, 1, 1) }`, `reaction = {}`, `power = {}`;
  - `disconnected` and `tapped`, each `CreateColor(1, 1, 1)`;
  - `roles = {}` and `runes = {}`.

  For frames, use stand-in tables with `Health`, `Power` and `AdditionalPower` (each counts its `ForceUpdate` calls), `IsElementEnabled(name)` and a counting `UpdateTags`. Set `UF.units = { player = a, boss = { [1] = b } }` and `UF.groups = {}`. Tests:
  - `'UpdateColors puts the profile status colors on oUF'` (the list regression): set the profile's `status.disconnected` to `0.2, 0.3, 0.4`, call `UF:UpdateColors()`, and check `UF.oUF.colors.disconnected:GetRGB()` is `0.2, 0.3, 0.4`. Do the same for `tapped`.
  - `'a class color change recolors every unit frame lightly'`:
    - Frame `a` has AdditionalPower disabled.
    - Replace `UF.UpdateConfig` and `UF.ApplyConfig` with functions that fail the test.
    - Set the profile's Mage to `0.1, 0.2, 0.3`, then call `UF:OnColorsChanged('class')`.
    - `UF.oUF.colors.class.MAGE:GetRGB()` is `0.1, 0.2, 0.3`.
    - Each frame's Health and Power were force-updated once, and its tags once.
    - `a`'s AdditionalPower 0 times, and `b`'s once.
  - `'the test previews are drawn again'`: with `UF.testGroups = { party = true }` and a recording `UF.UpdateGroupPreview`, it is called with `'party'`.
  - `'a change to colors unit frames do not use recolors nothing'`: `'text'`, `'button'`, `'item_quality'` and `'renown'` force-update nothing.
  - `'before unit frames are enabled a change does nothing'`: with `UF.units = nil` and a recording `UF.UpdateColors`, no error and no call.

- [ ] **Step 2: Run `tests/run tests/unitframes/colors_test.lua`.** Expected: the four `OnColorsChanged` tests fail (there's no `UF:OnColorsChanged`). The `UpdateColors` test passes once Task 1's defaults are in; it guards the fix.

- [ ] **Step 3: Implement `UF:OnColorsChanged(group)`** with a comment: it is lighter than `UF:UpdateConfig` because the picker sets a color on every move of its cursor.

- [ ] **Step 4: Run `tests/run`.** Expected: every file passes.

- [ ] **Step 5: Docs:** `.agents/testing.md` row for `tests/unitframes/colors_test.lua` (bump `last_updated`).

- [ ] **Step 6: Commit:** `unitframes: a class, reputation, power or status color change recolors the frames at once`

---

### Task 4: Every SaftUI skin on the profile's colors

**Files:**
- Modify: `SaftUI-Bags/slot.lua`:
  - new `INV:SetSlotQualityBorder(slot)`, holding what `INV:AssignSlot` does today from `if not slot.info.locked and slot.info.quality then` to its `end`, and called from there;
  - new `INV:OnColorsChanged(group)`.
- Modify: `SaftUI-Bags/currencies.lua` (around line 247)
- Modify: `SaftUI-Loot/roll.lua` (`LT:GroupLootFrame_OnShow` around line 169, and the test roll around line 414)
- Modify: `SaftUI-Misc/tooltip.lua` (`TT:GameTooltip_OnTooltipSetUnit`'s color lookups)
- Test: `tests/bags/slot_quality_test.lua` (new), `tests/loot/roll_skin_test.lua`, `tests/misc/tooltip_skin_test.lua`
- Docs: `.agents/testing.md` (the new `tests/bags/` folder and file)

**Interfaces:**
- Consumes: `st:QualityColor(quality)` and `OnColorsChanged` (Task 1).
- Produces:
  - **`INV:SetSlotQualityBorder(slot)`:**
    - For a slot whose info isn't locked and has a quality: quality above -1 sets the border to `st:QualityColor(quality)`, or black (`0, 0, 0`) when that is nil. Quality -1 sets it to black.
    - Any other slot, it leaves alone.
  - **`INV:OnColorsChanged(group)`:** for `'item_quality'` only, it runs `SetSlotQualityBorder` on every slot of `self.containers[*].categories[*].slots` that has `info` and isn't `info.empty`.
  - **Currencies and rolls** take `st:QualityColor(quality)` where they read `ITEM_QUALITY_COLORS[quality]`. A currency with no color gets a black border, as for quality -1. A roll with no color keeps its nil check.
  - **The tooltip** reads `st.config.profile.colors.class[...]` where it read `RAID_CLASS_COLORS[...]`, both lookups, and `st.config.profile.colors.reaction[...]` where it read `FACTION_BAR_COLORS[...]`.

- [ ] **Step 1: Write the failing tests.**
  - **`tests/bags/slot_quality_test.lua`:**
    - Setup: `load_core_helpers()`; stand-in `Inventory` and `Utilities` modules (`st:NewModule`) before `load_saftui('SaftUI-Bags/slot.lua')`. A slot is `{ info = ..., backdrop = <a table whose SetBackdropBorderColor records r, g, b> }`.
    - `'a slot border is the profile color for its quality'`: quality 3 gives the profile's `item_quality[3]` values, and `ITEM_QUALITY_COLORS[3]` stubbed to another color isn't used.
    - `'quality -1, and a quality with no color, give black'`: quality -1 and quality 20 (no color anywhere) both give `0, 0, 0`, with no error.
    - `'a locked slot, and a slot with no quality, are left alone'`: no recorded call.
    - `'OnColorsChanged item_quality redraws filled slots only'`:
      - `INV.containers = { bag = { categories = { A = { slots = { filled, empty, bare } } } } }`, where `empty.info = { empty = true }` and `bare` has no info.
      - `OnColorsChanged('item_quality')` recolors `filled` only.
      - `OnColorsChanged('class')` recolors nothing.
  - **`tests/loot/roll_skin_test.lua`:** `'a roll takes the profile quality color for its name and timer'`. Follow the file's existing setup. Stub `ITEM_QUALITY_COLORS` with a different color for the roll's quality, so the test proves the source.
  - **`tests/misc/tooltip_skin_test.lua`:**
    - Change `'a unit tooltip colors the border of the tooltip and the status bar'`: set the profile's `colors.class.MAGE` to the expected color and `RAID_CLASS_COLORS.MAGE` to another.
    - Add `'an NPC tooltip takes the profile reaction color'`: `UnitPlayerControlled` false, `UnitReaction` returning 2, `FACTION_BAR_COLORS[2]` set to another color. Both borders get the profile's `reaction[2]`.

- [ ] **Step 2: Run `tests/run tests/bags tests/loot/roll_skin_test.lua tests/misc/tooltip_skin_test.lua`.** Expected: FAIL (the code reads Blizzard's tables, and there's no `INV:SetSlotQualityBorder`).

- [ ] **Step 3: Implement** the four changes above. Keep `AssignSlot`'s behavior otherwise unchanged.

- [ ] **Step 4: Run `tests/run`.** Expected: every file passes, the runner's self-check included.

- [ ] **Step 5: Docs:** `.agents/testing.md`, the `tests/bags/` row (bump `last_updated`).

- [ ] **Step 6: Commit:** `bags, loot, tooltip: SaftUI's own quality, class and reputation colors wherever SaftUI skins; bag borders follow a quality color change`

---

## Order

Task 1 first. Tasks 2, 3 and 4 each depend only on Task 1, and run in that order (one implementer at a time). After Task 4, run the `agents-doc-parity-check` and `readme-freshness-check` audits before the final review.
