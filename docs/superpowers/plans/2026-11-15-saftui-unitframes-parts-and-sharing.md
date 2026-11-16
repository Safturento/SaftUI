# SaftUI Unit Frames Parts and Sharing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/sui` > Unit frames gets an All units entry every unit follows until it owns a setting, and each unit's page drops from up to 13 tabs to five, its texts, icons and small parts drawn as half rows in a Parts section on General, each with a summary, a reset and a menu of its settings, with nothing on screen changing at the upgrade.

**Architecture:**
- **The kit's part row** (Core, generic): the menu item gains a `summary`, a reset that covers its menu (`resetsMenu`), a share that stands for the whole part (`share.whole`), a hover line that takes the summary's place, a click that opens its menu, and menus laid out two small rows to a line; a group's `mirrorOf` lets one set of option tables be drawn in two places and found and walked once.
- **The effective config is materialized**: each member's stored values keep holding what it shows (so no reader, oUF element or hot path changes); All units' values live in `unitframes.profiles.<profile>.all`, own flags in `<unit>.own`; one function defines the effective value (`UF:SharedValue`), every write goes through one API (`config/shared.lua`), and a sync after the upgrade and on every profile load puts right any drift.
- **The pages** are rebuilt from the elements' existing option tables: `UF.PARTS` (`config/parts.lua`) says which element is a part row and which a tab; Health text and Power text are drawn twice from the same tables; a decorator (`config/sharedoptions.lua`) gives every shared row its share.

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0 (its `'**'` wildcards hold the unit frame defaults); the bundled oUF, unchanged; SaftUI's options kit (`st.OptionsModel`, `st.OptionsWidgets`, `st.OptionsBody`, `st.OptionsWindow`); tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-15-saftui-unitframes-parts-and-sharing-design.md`. Its calls are taken as accepted. Its questions don't block: this plan builds each recommended answer and says, at the ruling that builds it, what the other answer changes (Rulings 23, 26, 30, 31, 33).

## Global Constraints

- **Before this plan:** the "Position second on every page" change is merged (the spec assumes it). Task 3 starts from it.
- **Libraries.** Nothing under any `Libraries/` folder changes (oUF included).
- **Core knows no unit frame.** No file under `SaftUI-Core/` names a unit, a part, `UF` or "All units"; every word comes through the option fields.
- **Secure frames.** Nothing new runs a layout, a size, a show or a hide on a frame. The shared API is table writes only; frames change only through `UF:UpdateConfig`, whose combat queue is unchanged (`.agents/taint.md`).
- **Privacy.** No account, realm or character name anywhere: code, tests, docs, commits.
- **Commits.** Lowercase `module: imperative summary` (`core: ...`, `unitframes: ...`, `docs: ...`). Stage by explicit path, never `git add -A`, `.` or a folder. End with the session's `Co-Authored-By` line.
- **Line endings.** Keep each file's endings (`file <path>`); never `sed -i`.
- **Words.** Sentence case, American spelling ("color"), plain and direct. Name a path with ">".
- **Resets.** Per setting. A part row's reset is its row's (the spec's 2.4); no section or page Reset button.
- **Icons.** Lucide's (`st.icons`). An icon-only control always has a tooltip. Nothing new is needed.
- **Scripts.** The game calls `OnEnter`/`OnLeave` with a second argument: wrap each as `function(self) ... end`, and fire hover scripts in tests with `true`.
- **Whole pixels.** Every new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard with `stub.size_noise` at `2 ^ -14`, `-2 ^ -14` and `0`.
- **New SaftUI fields** go in `SAFTUI_FIELDS` (`tests/lib/options_walk.lua`) and `.agents/edit-mode.md`.
- **Tests.** Each task ends green on `tests/run -j2`, running single files while working. An earlier assertion changes only where this work changes what it pins, and the report lists each one changed with why.
- **Docs.** Each task updates the docs its files make stale, in the same commit: `AGENTS.md`, the `.agents/*.md` whose `covers:` list its files, file header comments. Then it runs `agents-doc-parity-check` and `readme-freshness-check`. Task 8 does the design system and the followups.
- **In game.** Each task ends with its in-game checks for the owner; nothing counts as verified until he confirms it.

### The standing checks (every task runs all three before its commit)

- **S1. Resets.** `tests/run tests/core/reset_coverage_test.lua tests/unitframes/config_test.lua tests/core/reset_walk_test.lua` pass: the coverage scan strict, every unit page walked (`R.check_page`), no row without a source.
- **S2. Nothing changes on screen.** On an untouched profile and on a customized one, every member's effective config is equal before and after the task's operations. From Task 2 on: `tests/run tests/unitframes/shared_upgrade_test.lua` (its `SW.snapshot` over every member and every key of `UF.SHARED`, and the frame's own keys). Tasks 1 and 3, before it exists: a deep copy of `st.config.profile.unitframes` taken before building every page, drawing it and opening every part's menu equals one taken after (`rawget` walk: no table AceDB's wildcard made).
- **S3. Combat.** Every write the task adds, run with `stub.in_combat = true` inside `C.measure` (`tests/lib/color_cost.lua`), makes `forbidden.total == 0` and `made == 0`; the frames change only after `stub.fire_event('PLAYER_REGEN_ENABLED')`, through `UF:UpdateConfig`'s queue.

## Review Focus

1. **The upgrade on a customized profile** (a font changed on every unit, Party's names with levels, a typeface table on one unit, a color object and a color list on two cast bars, a position with no element, string offsets): after the first login every unit shows exactly what it did, through a real AceDB logout and a second login, and the own flags are exactly where a unit differs from what most units show. Task 2 (`shared_upgrade_test.lua`), and again wired in Task 6.
2. **A follower drifting from All units.** Every page write and share action leaves `stored == UF:SharedValue` for every member and key; a hand drift is put right by the sync and nothing else is written. Tasks 2 and 6.
3. **The same option tables in two places** (Health text): one change shows in both, one reset, search lists it once, the walk counts it once, and the decorator wraps each leaf once. Tasks 1, 3, 6.
4. **The part row under the mouse:** nothing moves or grows, the hover line takes the summary's place and goes on leave, a click opens the menu but not on the box, dots, reset icon or links. Task 1.
5. **A held slider on All units** (a Name font size, a Health text Position X): followers update once per frame, nothing in combat. Task 6.

---

## How the tasks are cut

| # | Task | Spec part | Needs | Runs beside | Owner can try in game |
| --- | --- | --- | --- | --- | --- |
| 1 | The kit's part row | 2, 3, 5, 6 (K1 to K7) | — | 2 | nothing yet (no page uses it) |
| 2 | Shared storage and the effective config (not wired) | 4.2 to 4.6 | — | 1, 3 | nothing yet |
| 3 | The unit pages: Parts, five tabs, the two-place texts | 1, 2.7, 3 | 1 | 2 | the new pages, no All units yet |
| 4 | Group pages | 1 (General), 4.8 | 3 | 5, 6, 7 | Party, Raid, Boss General |
| 5 | Nameplate pages | 4.9 | 3 | 4, 6, 7 | the plate pages, the box |
| 6 | All units: the pick, the shares, the wiring, Copy from | 4.6, 4.7, 4.10, 4.11 | 2, 3 | 4, 5, 7 | All units, own marks, Apply to |
| 7 | Search | 5 | 3 | 4, 5, 6 | search on the unit pages |
| 8 | Docs, design system, followups, the in-game checklist | 8 | 1 to 7 | — | the whole list |

**Parallel:** Tasks 1 and 2 at once. Task 3 after 1, beside 2. Tasks 4, 5, 6 and 7 after 3 (6 also after 2), side by side: none of them shares a source file with another (4 `groupoptions.lua`, 5 `nameplates/options.lua`, 6 `config.lua`, `elements/auras.lua`, `unitframes.lua` and its new files, 7 tests only). Merged by hand, keeping both sides: `SaftUI-Unitframes/config/load.xml` (Tasks 2, 3, 6 each add a line), `.agents/edit-mode.md` and `.agents/architecture.md` (each task edits its own sentences), `tests/unitframes/config_test.lua` (Tasks 3, 6: each its own cases).

## Files shared with work in flight

| Task | Shared with |
| --- | --- |
| 1 | the interaction states plan (`docs/superpowers/plans/2026-11-15-saftui-interaction-states.md`): `SaftUI-Core/Config/optionsbody.lua`, `optionsitem.lua`, `optionsshare.lua`, `optionsmenu.lua`. Task 1 lands after it, or merges by hand; Ruling 20 covers its helpers not being in yet. |
| 3 | the Position-second change: `SaftUI-Unitframes/config/config.lua`, the element files' Position orders. Task 3 starts after it. |
| others | — |

## Rulings on the spec

1. **Names** (the spec leaves most to the builder): the functions and fields of the Interfaces below, as written there, and no others for the same jobs.
2. **The members**, in this order (the mode's tie-break and every list's order): `UF.SHARE_MEMBERS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' }`, and `UF.IsShareMember(unit)`.
3. **A shared entry** in `UF.SHARED` (a list; `UF.SHARED_BY_KEY[key]` and `UF.SHARED_BY_PATH['<any of its paths joined by .>']` index it): `{ key = 'name.font', part = 'name' | nil, element = 'Name' | nil, name = 'Font', type = 'toggle' | 'range' | 'select' | 'font' | 'color' | 'colortoggle' | 'position' | 'input', paths = { { 'name', 'font' } }, shows = nil | 'players' | 'npcs' | 'pets' | 'mobs' | 'offline', since = 1 }`. A part's Enable is named `'Show'`, as the kit names an item's box. The frame's two: `frame.theme` (`paths = { { 'theme' } }`), `frame.background`, element nil. The six hand-default rows: `health.customColor` and `power.customColor` (`colortoggle`, paths `colorCustom` and `customColor`), `health.text.customColor` and `power.text.customColor` (the same under `text`), `buffs.border` (`toggle`, paths `friend.colorStealable` and `enemy.colorStealable`), `debuffs.border` (`colorTypes`). Built by loops where parts share a shape (the five indicators; Health's and Power's colors). 187 entries on this commit; Task 2's test pins the list against the pages.
4. **A member has a setting** (`UF:HasShared(unit, key)`): `UF.IsShareMember(unit)`, and the entry's element is nil or registered with a `ValidUnit` that passes (`UF.elements[element]`, read at call time), and `shows` is nil or `UF.CanShow(unit, shows)`. `UF:HasShared('all', key)` is true for every entry.
5. **Own flags**: `local own = rawget(unitConfig, 'own')`; made with `rawset(unitConfig, 'own', {})` on the first write; read as `own and own[key] == true`. Cleared to `false`, never nil.
6. **The marker**: `rawget(profile.all, 'version')`, a number; a non-number counts as 0. Written with `rawset` after the steps run.
7. **The mode** (step 1): among the members that have the key, the value most of them show (`UF.SameShared` groups the values); a tie goes to All units' default (`st:DefaultAt('unitframes', 'profiles', <profile name>, 'all', unpack(path))`, its first path) when it is among the tied values, else to the first member in `UF.SHARE_MEMBERS` order among the tied.
8. **Compare** (`UF.SameShared(entry, a, b)`, a and b each a unit's config table): every path compared with `st.OptionsModel.SameValue(<type>, x, y, { relative = true })` (a position by its parts, offsets as whole pixels, `"0"` as 0, an anchor of nil, false or UIParent the screen; a color as bytes; a font key or typeface), but `colortoggle`: the same when both are unticked, or both ticked with the same color; `toggle` nil and false the same.
9. **Copy** (`UF.CopyShared(entry, from, to)`, config tables): a position part by part, every part: `point`, `rel_point`, `x_off`, `y_off` as numbers, `element` and `frame` as the source's or `false`; a color into the destination's own table in place, in its shape (a color object's `r`, `g`, `b`; a list's 1 to 3; a map's `r`, `g`, `b`), a new `{ r, g, b }` where it has none; a table value (a typeface) as `st.tablecopy(value, true)`; a plain value assigned.
10. **The once-a-frame update**: `UF.sharedTicker`, a hidden `CreateFrame('Frame')`. `UF:UpdateShared(units, element)` marks `pending[unit][element or '*'] = true` and shows it; its `OnUpdate` hides it, takes the marks (cleared in place) and runs `UF:UpdateConfig(unit, element)` (nil for `'*'`) for each, members in `UF.SHARE_MEMBERS` order. Tests step it as `C.step` steps `CO.ticker`.
11. **Steps**: `UF.SHARED_VERSION = 1`; an entry's `since` (default 1) says which step converts it. `UF:ConvertShared(profile)` runs every step above the marker, a step converting the entries with that `since`.
12. **All units' defaults** (`config/units/all.lua`): `st.defaults.unitframes.profiles['**'].all = { debuffs = { enable = true } }`, with the comment the spec gives (the one majority that is not the every-unit default). Task 2's test pins that a fresh profile's conversion writes nothing into `all`.
13. **The wiring** (Task 6, `unitframes.lua`): first in `UF:OnEnable`, before any frame is spawned: `UF:TryConvertShared()` then `UF:SyncShared()`. In `UF:UpdateConfig(unit, element_name)`, after `if not self.units then return end`: `if unit == 'all' then return self:PropagateShared(element_name) end`; then `if not unit then self:TryConvertShared(); self:SyncShared() end`, before the combat queue.
14. **`UF.PARTS`** (`config/parts.lua`), in the spec's order: `{ key, name, element, config, sub, place, under, mirror }`:

    | key | name | element | config (sub) | place | mirror |
    | --- | --- | --- | --- | --- | --- |
    | `name` | Name | `Name` | `name` | row | |
    | `subtext` | Subtext | `Subtext` | `subtext` | row | |
    | `healthtext` | Health text | `Health` | `health` (`text`) | row | `Health` |
    | `threat` | Threat | `Threat` | `threat` | row | |
    | `powertext` | Power text | `Power` | `power` (`text`) | row | `Power` |
    | `classpower` | Class power | `ClassPower` | `classpower` | row | |
    | `additionalpower` | Additional power | `AdditionalPower` | `additionalpower` | tab, `under = 'Power'` | |
    | `raidtarget` | Raid target | `RaidTargetIndicator` | `raidtargetindicator` | row | |
    | `raidrole` | Raid role | `RaidRoleIndicator` | `raidroleindicator` | row | |
    | `grouprole` | Group role | `GroupRoleIndicator` | `grouproleindicator` | row | |
    | `readycheck` | Ready check | `ReadyCheckIndicator` | `readycheckindicator` | row | |
    | `quest` | Quest | `QuestIndicator` | `questindicator` | row | |

    A part with a `sub` is the element tab's `args[sub]` group; any other is the element's whole group.
15. **A part row** (`UF.PartRow(unit, part, group, order)`): `{ type = 'item', name = part.name, desc = <the group's Enable desc>, order, get = <the part's enable from its config path>, set = <write it, then UF:UpdateConfig(unit, part.element)>, saved = UF.SavedAt(unit, <config>, [sub], 'enable'), menu = <a group: the same leaf tables but enable, name = part.name, no inline>, menuTitle = part.name, summary = UF.PartSummary(unit, part), resetsMenu = true }`; Subtext (no Enable) has `get = false, reserveBox = true` and no `saved`.
16. **A part as a tab** (`UF.PartTab(unit, part, group)`): the group as it is (its Enable first), `inline = false`, `name = part.name`, keyed by its element (`AdditionalPower`); with `under`, set as a child of that tab, whose own options move into a child `bar` named `'Power bar'` (order 1, the part order 2) and which takes `childGroups = 'tab'`.
17. **The summary** (`UF.PartSummary(unit, part)` gives `function(info) -> word, tip`): `UF.PartAnchorWord(unit, position)` by the spec's 2.3 (an element by `UF.ELEMENT_NAMES[element]`: `Health = 'Health'`, `Power = 'Power'`, `Castbar = 'Cast bar'`, `Name = 'Name'`, `Buffs`, `Debuffs`, `ClassPower = 'Class power'`, `AdditionalPower = 'Additional power'`, the indicators' labels; `frame == 'UIParent'` gives `'Screen'`; `SaftUI_<Label>` gives the label's unit name; another name itself; else `'Unit frame'`), the tip `st.OptionsBody.PositionText(position, true)`.
18. **General's sections** (Task 3): `general.args.frame` (an inline group named `'Frame'`, order 1: enable, theme, background, width, height; All units: theme, background), the frame's Position where the Position-second change put it (not on All units), Layout (order 6) and Range (order 500) as today, `general.args.parts` (inline, order 1000, name `'Parts'`, desc the spec's note), its items at the `UF.PARTS` index as order.
19. **The tabs** (Task 3): `Health`, `Power`, `Castbar` (`name = 'Cast bar'`), `Auras` (`childGroups = 'tab'`, `args = { Buffs = <Buffs group, order 1>, Debuffs = <Debuffs group, order 2> }`, order 7). The Health and Power tabs keep `args.text`, which gets `mirrorOf = { 'general', 'parts', 'healthtext' }` (`'powertext'`).
20. **The part row's hover look** takes the states design's helpers (`st:AddStates(frame, 'row', { bar = false })`, `st:SetState(frame, 'hover', on)`, `st:RemoveStates` on release). If they are not merged when Task 1 runs, the row gets no hover look (the click still works) and a dated line in the followup "the part row's hover look waits for the states helpers"; the states plan's own task then adds it.
21. **The menu's layout** (K4): `M.body:SetWidth(BODY_WIDTH, true)` in place of `oneColumn = true`, so `OB.HalfSize` applies (small to normal, normal and none to wide).
22. **The menu reset** (K2): `OM.DefaultSource(root, row)` returns `'menu'` for an item with `resetsMenu` (after `'default'`, before `'mover'`); the menu's rows are `OM.BuildView(OM.MenuRoot(option), OM.MENU_KEY).sections`' rows that are value rows and neither hidden nor disabled, plus the item's own box by its `saved`. `OM.DefaultDiffers` asks each (built once per tree in a weak cache keyed by the option, so a draw makes no table); `OM.DefaultReset` writes each that differs through `OM.DefaultReset` of that row, the box first, then the menu's order; the tooltip "Reset: <name> goes back to its defaults: <names joined by ', '>." in the same order, the box named "Show" (after five names, ", and <n> more").
23. **Whole share** (K3): `share.whole = true`. If the owner answers question 2 "only its check box", K2's `resetsMenu` is dropped from part rows and the row's reset is the box's derived one; nothing else changes.
24. **The inline line** (K5): an item with a `summary` sets `cell.lineInline = true` and `cell.lineX` (label end, or its diff icon's right, plus 12); `LiftTop` gives 0 for it; `ShowLine` hides the summary and `HideLine` shows it again.
25. **The row's click** (K6): the pooled row frame's `OnMouseUp(self, button)`: `button == 'LeftButton'`, the row is a part row (`frame.partRow`, set by `PlaceRow` and cleared on every other row), and none of the box, the dots, the reset icon or the line's links `IsMouseOver()`: `widget:OpenMenu()`.
26. **The rule's number**: the test reads `st.OptionsWindow.LAYOUT.own.height` (700). If the owner moves Additional power to a row (question 1), `UF.PARTS` says `place = 'row'` and the rule's test takes an `oversize = { additionalpower = '<his words>' }` exception; nothing else changes.
27. **Decorating** (Task 6, `UF.DecorateShares(unit, page)`): walks the page with the model's paths; a value row maps to an entry by its saved path (`saved` of its get node, less `'unitframes', 'profiles', <name>, <unit>`, looked up in `UF.SHARED_BY_PATH`); a part row by its `UF.PARTS` key. Task 6 gives the six hand-default rows a `saved` (`UF.SavedAt` of the entry's first path: `UF.CustomColorOption` from its `spec.unit` and `spec.path`, the aura border in `elements/auras.lua`), which their reset doesn't read: `OM.DefaultSource` takes their hand `default` first. On a member it sets `share = UF.SettingShare(unit, entry)` (or `UF.PartShare(unit, part)`) and wraps the row's effective `set` (its own, else the nearest group's found on the page's path) as `function(info, ...) UF:OwnShared(unit, key); return set(info, ...) end`, and a `toggle.set` the same; on `'all'` only `share`. A leaf is decorated once per tree (`decorated[option] = true`, a weak set), so a mirrored leaf isn't wrapped twice. Rows of an entry the unit doesn't have are left alone.
28. **The shares' words** (Task 6): `source = 'All units'`, `page` and `pageText` the unit's page name (`'Player'`, `'Raid 10'`), `noun = { 'unit frame', 'unit frames' }`; `shared(info)` and `differs` values by `UF.SharedText(entry, value)` (on/off, a select's label, `st:FontLabel`, a color's hex, a position by `st.OptionsBody.PositionText`, a number as it is). A whole share's differs: `{ name = <owner's page name>, value = <its own settings' names joined by ', '> }` per owner in member order.
29. **All units' page** (Task 6): `config.args.all = GetUnitConfig('all')`, `UNIT_ORDER.all = 0`, `name = 'All units'`; an element is on it when any member has it (`UF.SharesElement(element)`), so Ready check is and Class power, Additional power, Subtext and Threat aren't; its pick control is Profile and Manage. `UF.CanShow('all', kind)` is true for every kind (no `UNIT_SHOWS` entry), as today for an unknown unit.
30. **Copy from** goes (Task 6): `pickerControl.copy`, `UF:OpenCopyTable`, `UF:CopySettings`, `CopyNames`, `UF:PositionCopyProblem`, the `ufsetting` kind and `History()`; `tests/unitframes/copy_from_history_test.lua` and `copy_from_position_test.lua` are deleted. If the owner keeps it (question 3): it stays, and `UF:CopySettings` writes each copied key that is a shared entry through `UF:SetShared(unit, key, ...)` (the unit owns it) and the rest as today; its two tests stay and gain an own-flag assertion.
31. **The plates' kept parts** (Task 5): `PLATE_PAGES.nameplate.keptParts = { threat = true }`, `PLATE_PAGES.friendlynameplate.keptParts = {}`; `kept` loses `Threat` (it is no tab now) and the Enemy page's `keptGeneral` gains `parts`; `UF.DisablePlatePageTabs` also sets `hidden = <checked>` on each part row its `keptParts` doesn't name, and on the Friendly page on `general.args.parts` itself. If the owner wants the plates in All units (question 4), they join `UF.SHARE_MEMBERS` by a step 2 and their boxes' disable rules take the share rows too; a followup, not this plan.
32. **An All units Position's anchor** (Task 6): its `validate` runs `st:ValidateAnchor` against each follower's `UF:ConfigTarget(follower, ...)` target that exists, and refuses with "<unit> would be anchored to itself through <frame>." for the first that fails.
33. **The rows that keep still** (question 5): only part rows (K5). If he says every shared row, a followup "Every shared row keeps still on hover" is written in Task 8 for a kit task of its own.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Config/optionsitem.lua`, `optionsbody.lua`, `optionsshare.lua`, `optionsmodel.lua`, `optionsdefault.lua`, `optionsmenu.lua` | K1 to K7 | 1 |
| `tests/lib/reset_walk.lua`, `tests/lib/options_walk.lua` | `'menu'` source, `mirrorOf`, the new fields | 1 |
| `SaftUI-Unitframes/config/shared.lua` (new) | `UF.SHARED`, members, the API, the conversion, the sync, the propagation, the ticker | 2 |
| `SaftUI-Unitframes/config/units/all.lua` (new) | All units' own defaults | 2 |
| `tests/unitframes/shared_world.lua` (new) | `SW`: snapshot, customize, a real AceDB login and logout | 2 |
| `SaftUI-Unitframes/config/parts.lua` (new) | `UF.PARTS`, part rows and tabs, summaries | 3 |
| `SaftUI-Unitframes/config/config.lua` | General's sections, the tabs, the Parts section (3); All units, the decorator's call, Copy from out (6) | 3, 6 |
| `SaftUI-Unitframes/elements/castbar.lua` | the tab's name | 3 |
| `SaftUI-Unitframes/elements/auras.lua` | the border row's `saved` | 6 |
| `SaftUI-Unitframes/config/groupoptions.lua` | the raid Enable desc's path (3); the group sections' order (4) | 3, 4 |
| `SaftUI-Unitframes/nameplates/options.lua` | kept parts, the Parts section while a box is checked | 5 |
| `SaftUI-Unitframes/config/sharedoptions.lua` (new) | the decorator, the shares, their words | 6 |
| `SaftUI-Unitframes/unitframes.lua` | the wiring (Ruling 13) | 6 |
| `SaftUI-Unitframes/config/load.xml` | `shared.lua` and `units/all.lua` (2), `parts.lua` (3), `sharedoptions.lua` (6), each before `config.lua` | 2, 3, 6 |

---

### Task 1: The kit's part row

**Files:**
- Modify: `SaftUI-Core/Config/optionsitem.lua` (the summary's font string, the row click's checks), `optionsbody.lua` (`PlaceRow`'s item branch: the summary's place and room, `frame.partRow`, `cell.lineInline`, `cell.lineX`), `optionsshare.lua` (the inline line, the whole share's tooltips, the menu reset's tooltip, `OB.PositionText` exported from `DefaultText`'s position words), `optionsmodel.lua` (`OM.ShareState` for `whole`; `OM.Search` skips `mirrorOf`; `OM.MirrorOf`), `optionsdefault.lua` (the `'menu'` source), `optionsmenu.lua` (Ruling 21).
- Modify: `tests/lib/reset_walk.lua` (`'menu'` is a source; a `mirrorOf` group's rows are skipped after the rawequal check), `tests/lib/options_walk.lua` (`summary`, `resetsMenu`, `mirrorOf` in `SAFTUI_FIELDS`).
- Create: `tests/core/options_part_row_test.lua`.
- Test, modify: `tests/core/options_menu_test.lua` (the half layout), `tests/core/options_share_test.lua` (whole), `tests/core/options_default_test.lua` (menu source), `tests/core/reset_walk_test.lua` (menu, mirrors).
- Docs: `.agents/edit-mode.md` (Menu items: summary, part rows, the click, the inline line, `resetsMenu`; Shareable options: `whole`; A setting's own reset: `'menu'`; Search: `mirrorOf`; the menu's half layout), `.agents/testing.md` (the new test).

**Interfaces:**
- Consumes: the states design's `st:AddStates`, `st:SetState`, `st:RemoveStates` (Ruling 20).
- Produces:

```lua
-- option fields (SaftUI's, read raw, never inherited)
item.summary = function(info) -> text, tip      -- a part row
item.resetsMenu = true                          -- OM.DefaultSource -> 'menu'
share.whole = true                              -- on an item's share: it stands for the whole part
group.mirrorOf = { '<key>', ... }               -- the canonical item's path in the page
OM.MirrorOf(root, path) -> mirrorPath | nil     -- the first group on path with mirrorOf
OB.PositionText(position, relative) -> text     -- "Right of Health: -7, -1", "Bottom of the unit frame: 0, 0"
-- tests/lib/reset_walk.lua: source 'menu' accepted; problem text for a mirror leaf that isn't the part's:
--   "<path>: the mirror's <key> is not the part's own option"
```

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/options_part_row_test.lua (the window world of options_item_test.lua; a page of four
-- items: 'name' with summary returning 'Health', 'Right of Health: -7, -1', a menu of All caps
-- (small toggle), Font (font), Max length (range), Position; resetsMenu; saved for its box)
test('a part row lays out its box, label, summary and dots in a half cell, under Thick', function()
	-- full size: the cell 14 to 373 of the 387 slot; box left 14; label left 40; dots right 373;
	-- summary right == dots left - 6 == 351 with no reset icon; its text 'Health'
end)
test('the summary gives way: cut to the room after the label and 12, hidden under 24', function()
	-- a label 300 wide: summary hidden; a label 260 wide: summary width <= 359 - 26 - 260 - 12 - 22
end)
test("the summary's tooltip is its tip", ...)        -- GameTooltip line 1 'Right of Health: -7, -1'
test('at half size a part row is a whole line', ...)  -- cell 360 wide (388 - 28); Blizzard 368
test("a menu reset: source 'menu', differs once anything in it does, resets each through its set", function()
	-- OM.DefaultSource(root, row) == 'menu'; OM.DefaultDiffers false on the fresh profile
	-- set Max length 12 and the box off: differs true; the reset icon shows
	-- OM.DefaultReset: Max length's set called once with 30, the box's once with its default; differs false
	-- tooltip 'Reset: Name goes back to its defaults: Show, Max length.' (the box first, then the menu's order)
	-- OM.DefaultDiffers makes no table (collectgarbage('count') unchanged over 1000 asks)
end)
test('a refused menu reset stops and puts its message on the status line', ...)
test("a whole share: own from its own, no 'Show' entry, the part named in its tooltips", function()
	-- member: share = { whole = true, own = -> true, source = 'All units', page = 'Player', pageText = 'Player',
	--   noun = { 'unit frame', 'unit frames' }, reset, applyAll, apply, targets }; menu rows with shares own
	--   false: OM.ShareState(...).marked == true, offers == true
	-- Reset's tooltip 'Name follows All units again. Player's own values are dropped.'
	-- All's 'All units takes Name from Player, and no unit frame keeps its own any more.'
	-- source page: differs = -> { { name = 'Party', value = 'Show level, Position' } }: differs has that one entry
end)
test("the hover line takes the summary's place: nothing moves", function()
	-- hover the member part row (frame:GetScript('OnEnter')(frame, true)): the label's top and left unchanged,
	-- the line's left == label right + 12, the summary hidden; the row's height unchanged
	-- leave: the summary shown again, the line hidden
end)
test('in a narrow cell the inline line drops Own, then "· Apply to:"', ...)
test('a click on the row opens its menu; on the box, the dots, the reset icon or a link it does not', function()
	-- OnMouseUp(frame, 'LeftButton') with the mouse over the label: OW:IsMenuShown(widget) true
	-- with the box IsMouseOver: false; a right click: false
	-- an action bars item (no summary): no menu on a row click
end)
test('the row has the Row hover and is never selected', ...)  -- st:GetState(frame, 'hover') on enter; 'selected' never
test('whole pixels: the part row under Thick, Thin and Blizzard', ...)  -- #P.off(root) == 0, three noises

-- tests/core/options_menu_test.lua
test('a menu lays out small rows two to a line', function()
	-- four small toggles and a range: toggles 1 and 2 share a y, 3 and 4 the next, the range a line of its own;
	-- every cell inside the 376 body
end)
test("the action bars' text menus are laid out as before", ...)  -- each row's rect equal to the pinned values
test('a Position block fits the menu body under Thick, Thin and Blizzard', ...)  -- its right <= body right
-- tests/core/reset_walk_test.lua
test("a mirror's rows are walked once, at their part", ...)       -- walked count equals the part's alone
test("a mirror holding a copy of a leaf fails", ...)               -- the problem text above
test("an item with resetsMenu has a source", ...)
-- OM.Search (tests/core/options_menu_test.lua's search cases)
test('search lists a mirrored setting once, at its part, opening the menu', ...)  -- one result, menu = true
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/core/options_part_row_test.lua tests/core/options_menu_test.lua tests/core/reset_walk_test.lua`. Expected: FAIL (no summary drawn, `'menu'` unknown, the menu one column).
- [ ] **Step 3: Implement** K1 to K7 as the Interfaces and Rulings 20 to 25 say, and export `OB.PositionText`.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS; no page uses a part row yet, so every page test passes unchanged.
- [ ] **Step 5: The standing checks.** S1 (the walk takes `'menu'` and `mirrorOf`); S2 (`tests/run tests/unitframes` unchanged: the kit adds fields and changes no unit frame data); S3 (`OW:OpenMenu` still returns false in combat: `tests/core/options_menu_test.lua`'s combat case).
- [ ] **Step 6: Docs** as listed under Files.
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Core/Config/optionsitem.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/Config/optionsshare.lua SaftUI-Core/Config/optionsmodel.lua SaftUI-Core/Config/optionsdefault.lua SaftUI-Core/Config/optionsmenu.lua tests/lib/reset_walk.lua tests/lib/options_walk.lua tests/core/options_part_row_test.lua tests/core/options_menu_test.lua tests/core/options_share_test.lua tests/core/options_default_test.lua tests/core/reset_walk_test.lua .agents/edit-mode.md .agents/testing.md
git commit -m "core: draw part rows with a summary, a menu reset and a whole-part share, and lay menus out two to a line"
```

**In-game checks:** both clients load with no Lua errors; the action bars' text menus look as before; their items' hover lines lift as before.

---

### Task 2: Shared storage and the effective config

Not wired: nothing calls the conversion or the sync at login yet (Task 6 does), so nothing in game changes.

**Files:**
- Create: `SaftUI-Unitframes/config/shared.lua`, `SaftUI-Unitframes/config/units/all.lua`, `tests/unitframes/shared_world.lua`, `tests/unitframes/shared_test.lua`, `tests/unitframes/shared_upgrade_test.lua`.
- Modify: `SaftUI-Unitframes/config/load.xml` (`units\all.lua` after `units\friendlynameplate.lua`; `shared.lua` after it, before `profiles.lua`); `tests/core/default_at_acedb_test.lua` (`'all'` in its unit list); `tests/unitframes/uf_world.lua` (`'all'` in `UW.UNITS`).
- Docs: `.agents/architecture.md` (Unit frames: the storage, the effective config, the API; the converting-once bullet: the marker `all.version`), `.agents/testing.md`, `AGENTS.md` (the Unitframes row: `config/shared.lua`, `config/units/all.lua`).

**Interfaces:**
- Consumes: `st.OptionsModel.SameValue`, `st:DefaultAt`, `st.tablecopy`, `UF.CanShow` and `UF.elements` (read at call time), `UF:GetProfileConfig`, `UF:UpdateConfig`.
- Produces:

```lua
UF.SHARE_MEMBERS, UF.IsShareMember(unit) -> boolean
UF.SHARED, UF.SHARED_BY_KEY, UF.SHARED_BY_PATH, UF.SHARED_VERSION   -- Rulings 3, 11
UF:HasShared(unit, key) -> boolean
UF:IsOwn(unit, key) -> boolean
UF:OwnShared(unit, key)                          -- the member owns key; nothing else written
UF:SharedValue(unit, key) -> value               -- the first path's value (a position its table)
UF:SetShared(unit, key, value, part) -> changedUnits
UF:FollowAll(unit, key) -> changedUnits
UF:ApplyToAll(unit, key) -> changedUnits
UF:ApplyTo(unit, key, targets) -> changedUnits
UF:OwnersOf(key) -> { unit, ... }
UF:PartKeys(part, unit) -> { key, ... }          -- the part's entries the unit has ('all': every one)
UF:PartIsOwn(unit, part) -> boolean
UF:FollowAllPart(unit, part) -> changedUnits
UF:ApplyPartToAll(unit, part) -> changedUnits
UF:ApplyPartTo(unit, part, targets) -> changedUnits
UF:PartOwners(part) -> { { unit = unit, keys = { key, ... } }, ... }
UF.SameShared(entry, a, b) -> boolean            -- Ruling 8
UF.CopyShared(entry, from, to)                   -- Ruling 9
UF:ConvertShared(profile)                        -- a unit frame profile table; Rulings 6, 7, 11
UF:TryConvertShared() -> ok                      -- the profile in use, in xpcall(geterrorhandler())
UF:SyncShared(profile) -> writes                 -- profile defaults to the one in use
UF:PropagateShared(element)                      -- All units -> followers for element's entries (nil: the frame's)
UF:UpdateShared(units, element)                  -- Ruling 10
UF.sharedTicker
-- tests/unitframes/shared_world.lua (no globals): local SW = load_test_file('unitframes/shared_world.lua')
SW.world(opts) -> st, UF, P                      -- UW.world with config/shared.lua and every unit file, 'all' too
SW.snapshot(profile) -> plain table              -- every member's every UF.SHARED path, and enable, width, height, position
SW.same(a, b) -> ok, { '<unit>.<path>', ... }    -- the shared compare, per path
SW.customize(profile)                            -- the fixed changes below
SW.acedb(saved) -> db                            -- a real AceDB:New(SV, { profile = st.defaults }), as default_at_acedb_test.lua builds one
SW.relog(db) -> db                               -- stub.fire_event('PLAYER_LOGOUT'), then AceDB:New on the stripped SV
```

`SW.customize(profile)` sets, on the unit frame profile in use: `name.font = 'pixel'` on all eleven members; `party.name.showLevel = true`; `raid40.health.text.enable = true`; `target.buffs.size = 30`; `focus.castbar.colors.normal` to `{ r = 1, g = 0, b = 0 }` (a map) and `target.castbar.colors.normal` with `SetRGB(0, 1, 0)` (a color object); `boss.raidtargetindicator.position.x_off = '5'` (a string); `player.theme = 'thin'`; `pet.power.enable = true`; `target.name.font = { font_name = 'Homespun', font_size = 12, font_outline = 'MONOCHROMEOUTLINE' }` (a typeface); `focus.name.position = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 2, element = false }`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/shared_test.lua (SW.world())
test('UF.SHARED is every row the member pages show under a part or a bar, and the frame Theme and Background', function()
	-- build each member's page (UF:GetConfigTable()), collect every value row's saved path under the unit, and
	-- the six hand-default rows (found anywhere on the page: a value row with a hand default keyed customColor or
	-- border, so the test holds before and after Task 3 moves the tabs): the set equals UF.SHARED's, #UF.SHARED == 187
	-- no entry for enable, width, height, position, Layout's, range_alpha, classpower.*, additionalpower.*
end)
test('a member has a setting where its page shows the row', function()
	-- HasShared('player', 'name.show_classification') false; ('target', ...) true
	-- ('targettarget', 'castbar.enable') false; ('party', 'readycheckindicator.enable') true; ('player', ...) false
	-- ('nameplate', 'name.font') false; ('all', 'readycheckindicator.enable') true
	-- for every member and entry: HasShared == the member's page has a row for it
end)
test('a fresh profile converts to the spec: All units at its defaults, 156 owned settings', function()
	-- UF:ConvertShared(P): rawget(P.all, 'version') == 1
	-- every entry: SameShared(all, <All units' AceDB default>) (nothing written into all)
	-- own counts: player 29, target 19, targettarget 2, focus 21, focustarget 2, pet 2, pettarget 2, boss 10,
	--   party 19, raid10 25, raid40 25
	-- party owns exactly { 'buffs.cooldown.alpha', 'buffs.cooldown.timer.enable', 'buffs.enable', 'buffs.framelevel',
	--   'buffs.initial_anchor', 'buffs.onlyShowPlayer', 'buffs.position', 'buffs.size', 'debuffs.framelevel',
	--   'debuffs.grow_right', 'debuffs.initial_anchor', 'debuffs.position', 'debuffs.size',
	--   'grouproleindicator.enable', 'health.text.deficit', 'health.text.enable', 'name.maxLength',
	--   'name.position', 'name.showLevel' }
	-- OwnersOf('name.position') == { 'party', 'raid10', 'raid40' }; OwnersOf('debuffs.enable') ==
	--   { 'targettarget', 'focustarget', 'pet', 'pettarget', 'raid40' }
	-- (a different count is a finding: report it, don't adjust the numbers)
end)
test('a tie goes to the default, then to the first member', ...)   -- castbar.enable 4 on, 4 off: all false
test('the conversion runs once and writes nothing into a member', function()
	-- before = SW.snapshot(P); ConvertShared; SW.same(before, SW.snapshot(P)) true; ConvertShared again: own unchanged
end)
test('SetShared on All units writes every follower and skips an owner', function()
	-- SetShared('target', 'name.font', 'normal') -> target owns it
	-- SetShared('all', 'name.font', 'pixel') -> every member that has it and doesn't own it stores 'pixel'; target 'normal'
	-- changedUnits lists the ten followers in member order
end)
test('FollowAll, ApplyToAll, ApplyTo and the part forms', function()
	-- FollowAll('target', 'name.font'): own false, stored 'pixel'
	-- ApplyToAll('party', 'name.showLevel'): all false, every member own false, stored false
	-- ApplyTo('target', 'health.text.percent', { 'focus', 'boss' }) with target true: focus and boss own it, true
	-- ApplyTo with the value equal to All units': the targets follow (own false)
	-- ApplyPartToAll('party', 'name'): All units takes party's name.* (the keys party has), nobody owns name.*
	-- PartOwners('name') on a fresh profile: { party = 3 keys, raid10, raid40, player (enable), ... } in member order
end)
test('a position is copied part by part; a missing anchor written as false', function()
	-- SetShared('all', 'name.position', { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 2 })
	-- target.name.position.element == false, .frame == false, .x_off == 0 (a number)
end)
test('a color is copied in place in each shape', function()
	-- SetShared('all', 'castbar.colors.normal', { r = 1, g = 0, b = 0 }): target's object keeps its identity and
	-- GetRGB() == 1, 0, 0; focus's map keeps its identity
end)
test('a typeface is copied, never shared', ...)                 -- rawequal(target.name.font, all.name.font) false
test('a colortoggle row: both unticked are the same whatever the hidden color', ...)
test('the sync puts right a drift and writes nothing else', function()
	-- converted fresh: SyncShared(P) == 0
	-- rawset target.name 'font' to 'pixel' with target following 'normal': SyncShared(P) == 1, stored 'normal'
end)
test('the invariant: after every API call stored equals SharedValue for every member and key', ...)
test('a key no step covers fails', ...)                          -- an entry with since = 2 and SHARED_VERSION 1: error text
test('UpdateShared runs each changed unit once on the next frame, however many changes came', function()
	-- UF:UpdateConfig spied: 50 x SetShared('all', 'name.max_width', n) + UpdateShared(changed, 'Name'):
	-- nothing yet; step the ticker: one call per follower with 'Name'; step again: none
end)
test('PropagateShared copies one element\'s entries and marks only the units that changed', ...)
test('in combat every API call is table writes only (S3)', function()
	-- stub.in_combat = true; C.measure over SetShared, ApplyToAll, ConvertShared, SyncShared, the ticker's step:
	-- forbidden.total == 0, made == 0
end)

-- tests/unitframes/shared_upgrade_test.lua (SW.world(); SW.acedb)
test('an untouched profile: every member shows the same after the upgrade, through a logout and a login', function()
	-- db = SW.acedb({}); before = SW.snapshot(<db's unit frame profile>); ConvertShared; SyncShared
	-- SW.same(before, after) true; db = SW.relog(db): ConvertShared does nothing (marker), SyncShared == 0,
	-- SW.same(before, SW.snapshot(...)) true; every own flag survived; rawget(all, 'version') == 1
end)
test('a customized profile: the same, and the owns are exactly where a member differs', function()
	-- SW.customize, then as above; All units' name.font == 'pixel' and nobody owns name.font but target (its typeface);
	-- party no longer owns name.showLevel; raid10 and raid40 still do; boss's raid target x_off '5' unchanged
	-- (owned: it differs from 0); focus owns name.position with element false
end)
test('a unit frame profile of another name converts by itself', ...)   -- Healer converted, SaftUI untouched
test('a fresh profile writes nothing into All units', ...)              -- Ruling 12
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/unitframes/shared_test.lua tests/unitframes/shared_upgrade_test.lua`. Expected: FAIL, `UF.SHARED` is nil.
- [ ] **Step 3: Implement** `config/shared.lua` and `config/units/all.lua` as the Interfaces and Rulings 2 to 12 say. The header comment of `shared.lua` states the model: what shares, where it is stored, that each member's stored values are its effective ones, the steps, and that nothing here applies a change.
- [ ] **Step 4: Run** `tests/run tests/unitframes tests/core/default_at_acedb_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: The standing checks.** S1 unchanged (no page changed); S2 the upgrade test itself; S3 the combat case.
- [ ] **Step 6: Docs** as listed under Files.
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Unitframes/config/shared.lua SaftUI-Unitframes/config/units/all.lua SaftUI-Unitframes/config/load.xml tests/unitframes/shared_world.lua tests/unitframes/shared_test.lua tests/unitframes/shared_upgrade_test.lua tests/core/default_at_acedb_test.lua tests/unitframes/uf_world.lua .agents/architecture.md .agents/testing.md AGENTS.md
git commit -m "unitframes: keep settings shared across units, each unit's stored values its effective ones"
```

**In-game checks:** both clients load with no Lua errors; nothing on screen changes (nothing is wired yet).

---

### Task 3: The unit pages

**Files:**
- Create: `SaftUI-Unitframes/config/parts.lua`, `tests/unitframes/parts_test.lua`.
- Modify: `SaftUI-Unitframes/config/config.lua` (`GetUnitConfig`: Rulings 18 and 19; the element loop places each element by `UF.PARTS`: a part row into `general.args.parts`, a part tab by `UF.PartTab`, Buffs and Debuffs under `Auras`, every other element a tab; then `mirrorOf` on the Health and Power tabs' `text`), `SaftUI-Unitframes/elements/castbar.lua` (`name = 'Cast bar'`), `SaftUI-Unitframes/config/groupoptions.lua` (one line: the raid groups' Enable desc is set at its new path, `general.args.frame.args.enable`), `SaftUI-Unitframes/config/load.xml` (`parts.lua` before `config.lua`).
- Test, modify: `tests/unitframes/config_test.lua` (each unit's tabs, the Parts rows, the walk), every test that reads General's Enable, Theme, Background, Width or Height by path (now under `general.frame`), and every test that opens a tab that moved (`grep -l "'Name'\|'Castbar'\|RaidTargetIndicator\|QuestIndicator\|'Buffs'\|'Debuffs'\|ClassPower\|'Subtext'\|'Threat'" tests/unitframes/*.lua`: their paths change to `general.parts.<key>.menu...`, `Auras.Buffs...`; the report lists each).
- Docs: `.agents/edit-mode.md` (the unit frame section: tabs, General's sections, Parts, the declaration, the two-place texts), `.agents/architecture.md` (the element registration bullet: a part's options are its row's menu), `AGENTS.md` (the Unitframes row: `config/parts.lua`).

**Interfaces:**
- Consumes: Task 1's `summary`, `resetsMenu`, `mirrorOf`, `OB.PositionText`; each element's `GetConfigTable(unit)` as it is.
- Produces:

```lua
UF.PARTS                                          -- Ruling 14
UF.PartFor(key) -> part
UF.UnitParts(unit) -> { part, ... }               -- the parts the unit has (its elements' ValidUnit), in order
UF.PartRow(unit, part, group, order) -> item      -- Ruling 15
UF.PartTab(unit, part, group) -> tab              -- Ruling 16
UF.PartSummary(unit, part) -> function(info) -> word, tip
UF.PartAnchorWord(unit, position) -> word
UF.ELEMENT_NAMES                                   -- Ruling 17
```

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/parts_test.lua (config_test.lua's world)
test("each unit's tabs", function()
	-- player: { 'general', 'Health', 'Power', 'Castbar', 'Auras' }; Power's children { 'bar', 'AdditionalPower' }
	--   ('Power bar', 'Additional power'); target, focus, pet, boss, party, raid10, raid40: the five
	-- targettarget, focustarget, pettarget: no Castbar; nameplate, friendlynameplate: { general, Health, Castbar, Auras }
	-- Auras' children { 'Buffs', 'Debuffs' }; Castbar's name 'Cast bar'
end)
test("each unit's Parts rows, in order", function()
	-- player: name, healthtext, powertext, classpower, raidtarget, raidrole, grouprole, quest
	-- party, raid10, raid40: name, healthtext, powertext, raidtarget, raidrole, grouprole, readycheck, quest
	-- target...boss: name, healthtext, powertext, raidtarget, raidrole, grouprole, quest
	-- nameplate: name, subtext, healthtext, threat, raidtarget, quest; friendlynameplate: the same but threat
	-- each an item, no size (a half), resetsMenu, its menuTitle its name
end)
test("General's sections: Frame, Position, Parts", ...)          -- OM.BuildView(...).sections titles in order
test('a part row is its element\'s options: the box its Enable, the menu every other row, the same tables', function()
	-- rawequal(item.menu.args.font, <Name tab's font option as the element built it>)
	-- item.menu.args.enable == nil; item:get() reads name.enable; its set writes it and UF:UpdateConfig(unit, 'Name')
	-- Subtext: get == false, reserveBox
end)
test("every row of today's pages has a home", function()
	-- for every unit: the multiset of saved paths of value rows before (a pinned list from this commit's pages,
	-- built by the audit's walk) equals the one after (parts' menus and boxes included, mirrors counted once)
end)
test('Health text and Power text: the tab\'s Text section is the part\'s very tables', function()
	-- Health.args.text.mirrorOf == { 'general', 'parts', 'healthtext' }
	-- for each key but enable: rawequal(Health.args.text.args[key], healthtext item.menu.args[key])
	-- a set through the menu's Font: the tab's Font reads it (OM.Get)
end)
test('the summary names the anchor', function()
	-- player Health text 'Health' (tip 'Right of Health: -7, -1'); player Class power 'Screen';
	-- party Name 'Health'; Raid target 'Unit frame'; a part anchored to SaftUI_Player: 'Player'
end)
test('each part menu fits the rule on every unit (Ruling 26)', function()
	-- under Thick at full size, OW:OpenMenu(<the row's widget>) for every part row of every unit:
	-- OW.GetMenuFrames().frame:GetHeight() <= st.OptionsWindow.LAYOUT.own.height (700)
	-- failure text: '<Part>'s menu is <h> tall on <Unit>, over the 700 rule: declare it a tab in UF.PARTS'
end)
test('declaring a part a tab moves it and nothing else', function()
	-- UF.PartFor('classpower').place = 'tab': player's tabs gain ClassPower, Parts loses it; the option tables
	-- are the same (rawequal); put back
end)
test('whole pixels: Player General and its Name menu under Thick, Thin and Blizzard', ...)
-- tests/unitframes/config_test.lua
test('every unit frame row has a reset', ...)   -- as today over the new pages: R.check_page(Page(), 'Unitframes', { probe = false })
-- the round-trip cases as today, for player, target, party, raid10, boss, nameplate, friendlynameplate
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/unitframes/parts_test.lua tests/unitframes/config_test.lua`. Expected: FAIL, `UF.PARTS` is nil.
- [ ] **Step 3: Implement** `config/parts.lua` and the page as Rulings 14 to 19 say. The element files stay as they are but `castbar.lua`'s name.
- [ ] **Step 4: Run** `tests/run tests/unitframes`, update the tests whose paths moved (listing each), then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: The standing checks.** S1 (the walk over 13 pages, parts' menus and mirrors once); S2 (the deep copy before and after building every page, drawing General and opening every part's menu, on the fresh and a customized profile); S3 (no page code runs in combat: `/sui` closes; a part row's box set in combat, by `OM.Set`, only writes and calls `UF:UpdateConfig`, which queues: `C.measure` forbidden 0).
- [ ] **Step 6: Docs** as listed under Files.
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Unitframes/config/parts.lua SaftUI-Unitframes/config/config.lua SaftUI-Unitframes/elements/castbar.lua SaftUI-Unitframes/config/groupoptions.lua SaftUI-Unitframes/config/load.xml tests/unitframes/parts_test.lua tests/unitframes/config_test.lua .agents/edit-mode.md .agents/architecture.md AGENTS.md
git add <each moved test file, by path>
git commit -m "unitframes: draw each unit's small parts as rows on General, five tabs, the texts in two places"
```

**In-game checks:** `/sui` > Unit frames: Player has five tabs, Power with Power bar and Additional power; General reads Frame, Position, Parts; the parts two to a line at full, one at half; hover a part row: it lights and nothing moves; its dots and a click on it open its menu, two small rows to a line, inside the screen; Health text in Parts and on the Health tab: a change in one shows in the other.

---

### Task 4: Group pages

**Files:**
- Modify: `SaftUI-Unitframes/config/groupoptions.lua` (Layout and Range's orders under General's new sections, so General reads Frame, Position, Layout, Range, Parts; boss's Layout the same). Where the orders already read so after Task 3, this task is its tests.
- Create: `tests/unitframes/group_pages_test.lua`.
- Docs: `.agents/edit-mode.md` (the group General's order).

**Interfaces:**
- Consumes: Task 3's General (`frame`, the Position, `parts`).
- Produces: nothing new.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/group_pages_test.lua (config_test.lua's world)
test("a group's General reads Frame, Position, Layout, Range, Parts", ...)   -- party, raid10, raid40; boss: no Range
test('Ready check is a part on the groups only', ...)                          -- party, raid10, raid40 yes; boss no
test("Layout, Range and Test mode keep their own resets; Test mode its noReset", ...)
test('the raid groups\' Enable keeps its desc about Blizzard\'s raid frames', ...)
test("a group's previews read its stored values", function()
	-- grouppreview world: set party.name.font through its part's menu row: the preview's name takes it after
	-- UF:UpdateConfig('party', 'Name')
end)
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/unitframes/group_pages_test.lua`. Expected: FAIL on the order.
- [ ] **Step 3: Implement** the orders.
- [ ] **Step 4: Run** `tests/run tests/unitframes`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: The standing checks.** S1; S2 (`shared_upgrade_test.lua`, unchanged by this task); S3 (no write added).
- [ ] **Step 6: Docs.**
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Unitframes/config/groupoptions.lua tests/unitframes/group_pages_test.lua .agents/edit-mode.md
git commit -m "unitframes: order the group pages' General as Frame, Position, Layout, Range, Parts"
```

**In-game checks:** Party, Raid 10, Raid 40 and Boss: General's sections in that order; Test mode still fills the spot; Ready check in Parts on the groups.

---

### Task 5: Nameplate pages

**Files:**
- Modify: `SaftUI-Unitframes/nameplates/options.lua` (Ruling 31).
- Test, modify: `tests/unitframes/nameplate_page_test.lua`, `tests/unitframes/friendly_page_test.lua`.
- Docs: `.agents/edit-mode.md` (the nameplate pages: Parts, `keptParts`).

**Interfaces:**
- Consumes: Task 3's plate General with `parts`.
- Produces: `PLATE_PAGES[unit].keptParts`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/nameplate_page_test.lua
test("the Enemy page's Parts: Name, Subtext, Health text, Threat, Raid target, Quest", ...)
test('with Use friendly nameplates\' settings checked only Threat stays in Parts', function()
	-- check the box: every part row hidden but threat; threat enabled; the other tabs disabled; General's own hidden
	-- uncheck: every part row back, as it was
end)
test('the plate part rows have no share and a menu reset', ...)   -- OM.ShareState nil; OM.DefaultSource 'menu'
-- tests/unitframes/friendly_page_test.lua
test('with Use enemy nameplates\' settings checked the Parts section hides', ...)
test('another nameplate addon: every part row is disabled, the stand-down line reads at full strength', ...)
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/unitframes/nameplate_page_test.lua tests/unitframes/friendly_page_test.lua`. Expected: FAIL (Threat hidden with the rest).
- [ ] **Step 3: Implement** Ruling 31.
- [ ] **Step 4: Run** `tests/run tests/unitframes`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: The standing checks.** S1 (the two plate pages round-trip); S2; S3 (the box's set: writes and `UF:UpdateConfig('nameplate')`, as today).
- [ ] **Step 6: Docs.**
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Unitframes/nameplates/options.lua tests/unitframes/nameplate_page_test.lua tests/unitframes/friendly_page_test.lua .agents/edit-mode.md
git commit -m "unitframes: keep Threat on the Enemy plate page's Parts while it uses the friendly page"
```

**In-game checks:** Enemy and Friendly nameplates: Parts on General; check Use friendly nameplates' settings: only Threat stays in Parts; uncheck: everything back.

---

### Task 6: All units

**Files:**
- Create: `SaftUI-Unitframes/config/sharedoptions.lua`, `tests/unitframes/shared_page_test.lua`.
- Modify: `SaftUI-Unitframes/config/config.lua` (Ruling 29: the `all` pick; `UF.DecorateShares(unit, config_table)` last in `GetUnitConfig`; Ruling 27: `UF.CustomColorOption`'s `saved`; Ruling 30: Copy from out), `SaftUI-Unitframes/elements/auras.lua` (Ruling 27: the border row's `saved`), `SaftUI-Unitframes/unitframes.lua` (Ruling 13), `SaftUI-Unitframes/config/load.xml` (`sharedoptions.lua` before `config.lua`).
- Test, modify: `tests/unitframes/config_test.lua` (the walk over 14 picks; All units' round trip with `allow` for every follower's copy of the row's key: `allow = { ['Unitframes.all.<row path>'] = { 'unitframes.profiles.<name>.<member>.<path>', ... } }` built from `UF.SHARED`), `tests/unitframes/shared_upgrade_test.lua` (the wired login: `UF:OnEnable` on the customized AceDB profile, then a profile switch, then `SW.relog`), `tests/unitframes/profile_switch_test.lua` (a switch converts and syncs the new profile, in combat too), `tests/unitframes/profiles_test.lua` (New, Copy, Import: each has its own All units). Delete: `tests/unitframes/copy_from_history_test.lua`, `tests/unitframes/copy_from_position_test.lua`.
- Docs: `.agents/edit-mode.md` (All units, the shares on unit pages, resets on unit pages, Copy from gone), `.agents/architecture.md` (the wiring; profile changes convert unit frames), `AGENTS.md` (the Unitframes row: `config/sharedoptions.lua`, no Copy from).

**Interfaces:**
- Consumes: Task 2's API; Task 3's pages; Task 1's `share.whole`.
- Produces:

```lua
UF.DecorateShares(unit, page)                     -- Ruling 27
UF.SettingShare(unit, entry) -> share             -- member or 'all'; Ruling 28
UF.PartShare(unit, part) -> share                 -- whole = true
UF.SharedText(entry, value) -> text
UF.SharesElement(element) -> boolean              -- any member has it (Ruling 29)
```

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/shared_page_test.lua (config_test.lua's world, with config/shared.lua and sharedoptions.lua; converted)
test('the picker starts with All units; its page has five tabs and the union of the members\' parts', function()
	-- picks: all first; All units' General: frame { theme, background } and parts (name, healthtext, powertext,
	-- raidtarget, raidrole, grouprole, readycheck, quest); no position; Health shows every color flag
end)
test("a member's shared row: own after a set, the hover line's Reset follows again", function()
	-- party Name > Show level: OM.ShareState(...).own false; OM.Set(true) -> UF:IsOwn('party', 'name.showLevel'),
	-- the Name part row marked; OM.ShareCall(..., 'reset') -> own false, stored = All units' (true)
end)
test("a member's own rows keep their derived resets", ...)   -- Width, Height, Position, Layout: OM.DefaultSource 'derived' / 'mover'
test("All units' row: the diff icon lists each owner and its value", function()
	-- All units Name > Show level: differs { { name = 'Party', value = 'off' }, { 'Raid 10', 'off' }, { 'Raid 40', 'off' } }
	-- ShareCall 'applyAll': nobody owns it; every member stores true
end)
test('a part row acts on the whole part', function()
	-- party's Name row: whole share; own while any name.* is own; Reset -> FollowAllPart: no name.* owned by party
	-- target's Health text row Apply to Multiple { 'focus', 'boss' }: both own and store target's health.text.*
	-- All units' Name row differs: { name = 'Party', value = 'Show level, Max length, Position' } (names by UF.SHARED)
end)
test('a set on All units reaches each follower once on the next frame', function()
	-- OM.Set All units Name > Max width 120 x 20 (a drag): UF:UpdateConfig spied per (unit, 'Name'): nothing until the
	-- ticker steps, then once per follower
end)
test('the invariant after every page set and share action', ...)   -- stored == UF:SharedValue, every member and key
test('a mirrored leaf is decorated once', ...)                     -- Health text's Font: its set wrapped once (one own call)
test("an All units Position that would loop through a follower is refused", ...)   -- Ruling 32's text
test('Copy from is gone from every pick line', ...)                -- pickerControl args: profile, manage
test('in combat a share action is table writes only (S3)', ...)
-- tests/unitframes/config_test.lua
test('every unit frame row has a reset, All units included', ...)
test("All units' derived resets round-trip, reaching every follower", ...)
-- tests/unitframes/shared_upgrade_test.lua
test('wired: OnEnable converts and syncs before anything is spawned; the frames are built from what they showed', ...)
test('a SaftUI profile switch, copy, reset and import convert the new profile, in combat too', ...)
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/unitframes/shared_page_test.lua tests/unitframes/config_test.lua tests/unitframes/shared_upgrade_test.lua`. Expected: FAIL, `UF.DecorateShares` is nil.
- [ ] **Step 3: Implement** as the Interfaces and Rulings 13 and 27 to 32 say. Delete the two Copy from tests.
- [ ] **Step 4: Run** `tests/run tests/unitframes tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: The standing checks.** S1 (14 picks; All units' rows derived with `allow`; members' shared rows `'share'`, their part rows `'share'`); S2 (the upgrade test wired, on the untouched and the customized profile, through a relog); S3 (share actions and All units sets in combat: forbidden 0 until combat ends).
- [ ] **Step 6: Docs** as listed under Files.
- [ ] **Step 7: Commit**

```bash
git add SaftUI-Unitframes/config/sharedoptions.lua SaftUI-Unitframes/config/config.lua SaftUI-Unitframes/elements/auras.lua SaftUI-Unitframes/unitframes.lua SaftUI-Unitframes/config/load.xml tests/unitframes/shared_page_test.lua tests/unitframes/config_test.lua tests/unitframes/shared_upgrade_test.lua tests/unitframes/profile_switch_test.lua tests/unitframes/profiles_test.lua .agents/edit-mode.md .agents/architecture.md AGENTS.md
git rm tests/unitframes/copy_from_history_test.lua tests/unitframes/copy_from_position_test.lua
git commit -m "unitframes: add All units, which every unit follows until it owns a setting"
```

**In-game checks:** G1, G2, G5, G6, G7, G11, G12 of the spec.

---

### Task 7: Search

**Files:**
- Create: `tests/unitframes/search_test.lua`.
- Modify, only if a case fails for a reason in the model: `SaftUI-Core/Config/optionsmodel.lua` (`OM.Search`).
- Docs: `.agents/edit-mode.md` (Search on the unit pages), `.agents/testing.md`.

**Interfaces:**
- Consumes: `OM.Search`, `OW:Reveal`, Task 3's pages.
- Produces: nothing new.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/unitframes/search_test.lua (config_test.lua's world, the window built)
test('a part by its name', ...)                     -- 'Health text': a result per unit, path general.parts.healthtext, no menu
test("a setting in a part's menu, which opens the menu", function()
	-- 'Show level': Player's result has menu = true, sectionTitle 'Name'; OW:Reveal(result path, menu) opens
	-- General, scrolls to the row, OW:IsMenuShown(<the Name widget>) true
end)
test('a two-place text setting is listed once per unit, at its part', ...)   -- 'Deficit': one result per unit
test('a part declared a tab is searched as its tab', ...)                    -- 'Spacing' on Player's Additional power? its tab
test('a disabled plate tab is skipped, and a hidden part row', ...)          -- box checked: no Name results on the Enemy page
```

- [ ] **Step 2: Run them to see them fail.** `tests/run tests/unitframes/search_test.lua`. Expected: FAIL where the model needs a fix, else PASS at once (then the step is the tests).
- [ ] **Step 3: Implement** any fix in `OM.Search`, generic.
- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: The standing checks.** S1, S2 (search reads, writes nothing: the deep copy before and after a search), S3 (none added).
- [ ] **Step 6: Docs.**
- [ ] **Step 7: Commit**

```bash
git add tests/unitframes/search_test.lua .agents/edit-mode.md .agents/testing.md
git commit -m "unitframes: test search over the parts, their menus and the two-place texts"
```

**In-game checks:** G13.

---

### Task 8: Docs, design system, followups, the in-game checklist

**Files:**
- Modify: `docs/design-system/README.md`, `05-decisions.md`, `tokens.json`, `components/MenuItem/README.md` and `preview.html`, `components/Row/README.md`, `components/OwnMark/README.md`, `components/DiffIcon/README.md`, `components/ResetIcon/README.md`, `components/ApplyList/README.md`, `components/PositionBlock/README.md`, `components/OptionsWindow/README.md` (the spec's section 8).
- Modify: `docs/followups.md` (resolve "2026-11-13 — Unit frames: shared settings across units, and small parts as menu items", moving it to Resolved with `**Resolved 2026-11-15:**` and the ToC; a dated line on "Test mode: choose which elements the previews show", "Edit mode movers for unit frame parts placed on the screen", "A first-run setup dialog: UI size, theme, unit frame layout", "A font Size drag restyles too much on the action bars, unit frames and tracker", "A Position reset runs a unit frame's update once for every part it writes"; new entries "Nameplates and All units" and, if Ruling 33 calls for it, "Every shared row keeps still on hover"; "the part row's hover look waits for the states helpers" if Ruling 20 applied).
- Create: `docs/superpowers/plans/2026-11-15-saftui-unitframes-parts-and-sharing-in-game-checklist.md` (the spec's G1 to G14, each with what to do, what to see and where to look if it fails).
- Re-read: `AGENTS.md`, `.agents/architecture.md`, `.agents/edit-mode.md`, `.agents/testing.md` end to end against the merged code.

**Interfaces:** none.

- [ ] **Step 1:** Decisions for `05-decisions.md`, under "2026-11-15, the unit frame pages", numbered from the file's last: the Parts section and half rows; Position second; the two-place texts; the too-big rule (700) and its declaration; All units (model B); a row never moves on hover; the summary is the anchor; each with his words from the spec's "What the owner decided".
- [ ] **Step 2:** The design system files as listed; `tokens.json` gains `menu-max-height` 700 with its usage note (`OW.LAYOUT.own.height`).
- [ ] **Step 3:** The followups and the checklist.
- [ ] **Step 4: Run** `tests/run -j2` (the docs tests, if any read these files). Expected: PASS. Then `agents-doc-parity-check` and `readme-freshness-check`.
- [ ] **Step 5: Commit**

```bash
git add docs/design-system/README.md docs/design-system/05-decisions.md docs/design-system/tokens.json docs/design-system/components/MenuItem/README.md docs/design-system/components/MenuItem/preview.html docs/design-system/components/Row/README.md docs/design-system/components/OwnMark/README.md docs/design-system/components/DiffIcon/README.md docs/design-system/components/ResetIcon/README.md docs/design-system/components/ApplyList/README.md docs/design-system/components/PositionBlock/README.md docs/design-system/components/OptionsWindow/README.md docs/followups.md docs/superpowers/plans/2026-11-15-saftui-unitframes-parts-and-sharing-in-game-checklist.md
git commit -m "docs: unit frame parts and All units in the design system, followups and the in-game checklist"
```

The report says the design system changed: the controller republishes the Design System artifact.

**In-game checks:** the whole checklist, G1 to G14.
