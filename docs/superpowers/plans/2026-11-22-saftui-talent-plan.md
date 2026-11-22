# SaftUI Talent Plan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A leveling plan docked to Blizzard's talent window on WoW Forever. It is an ordered, phased list of talent steps, filled by pasting a guide or by clicking nodes. Each row shows its state from the character's real ranks. A hover lights the row's node, and the waiting step glows in the tree. The talent window itself becomes movable.

**Architecture:**
- **Pure parts, tested on stubs.**
  - `model.lua`: the plan, ranks per step, row states, off-plan count, entries and moves.
  - `store.lua`: saved plans and each character's choice.
  - `parser.lua`: pasted text to steps, and the import summary.
  - `data.lua`: the class tree read from `C_Traits` into plain tables.
- **Frame parts, SaftUI's own frames anchored to Blizzard's.**
  - `panel.lua`: the docked panel, its rows, the collapse strip and the menus.
  - `import.lua`: the import dialog.
  - `overlays.lua`: the tree's light, glow, dim and planning-mode click catchers.
  - `drag.lua`: row and header dragging.
- **Wiring.** `talentplan.lua` is the module. It waits for `Blizzard_PlayerSpells` with `st:OnBlizzardAddon` and follows the window with post-hooks and `EventRegistry` callbacks only. Every change asks for one `TP:Refresh()` on the next frame. The refresh reads the data, works out the states, then draws the rows and the overlays.

**Tech Stack:**
- Lua 5.1 on WoW Forever (16001).
- AceDB-3.0's `profile`, `global` and `char` namespaces.
- Blizzard's `Blizzard_PlayerSpells` and `Blizzard_SharedTalentUI` (load on demand), `C_Traits`, `C_ClassTalents`, `C_SpecializationInfo`, `C_Spell` and `MenuUtil`.
- SaftUI's theme, widgets and options kit (`st:SetBackdrop`, `st:SetTemplate`, `st:CreateButton`, `st:CreateScrollFrame`, `st:CreateEditBox`, `st:CreateRadioGroup`, `st:AddStates` / `st:SetState`, `st.OptionsWidgets.Confirm` / `Prompt`, `st.Config.generators`).
- Tests: `tests/run` (lupa, Lua 5.1).

**Spec:** `docs/superpowers/specs/2026-11-22-saftui-talent-plan-design.md` (approved). Blizzard names below were checked on 2026-11-22 against Gethe/wow-ui-source `forever` at `734f065`: `Blizzard_PlayerSpells` (with `Camelot/`), `Blizzard_SharedTalentUI`, `Blizzard_APIDocumentationGenerated` (`SharedTraitsDocumentation.lua`, `ClassTalentsDocumentation.lua`, `SpecializationInfoDocumentation.lua`).

## Blizzard facts this plan rests on

These were all read in the forever source.

- `PlayerSpellsFrame` (`Camelot/Blizzard_PlayerSpellsFrame.xml`) is a `toplevel`, `enableMouse` frame on UIParent, at TOP 0, -41. Its talents size is 1218 by 708 (`talentsWidth`, `talentsHeight`). It has `TalentsFrame` (`ClassTalentsFrameTemplate`, 1212 by 681), `SpellBookFrame` and `SpecFrame`, and calls `SetFrameLevelsFromBaseLevel(5000)`. Camelot's `IsTabSystemAvailable` is false, so the Talents and Spellbook are toggled like separate windows. Nothing in it is a secure template.
- Inspecting: `PlayerSpellsFrameMixin:IsInspecting()`, `SetInspecting(...)` and `ClearInspectUnit()`. `OnHide` calls `ClearInspectUnit`.
- The spec tab: `ClassTalentsFrameMixin:GetTab()` (TabSystemOwner) is the spec group, because Camelot's `SetTab(tabID)` passes `tabID` straight to `C_SpecializationInfo.GetCombatConfigIDForSpecGroup(tabID)`. A tab with no config shows the disabled overlay and keeps the previous config.
- Talent buttons (`TalentFrameBaseMixin`):
  - `GetTalentButtonByNodeID(nodeID)`, `EnumerateAllTalentButtons()`, `GetConfigID()` and `GetTalentTreeID()`.
  - `button:GetNodeID()`.
  - Buttons are pooled and re-bound (`SetNodeID`, `ReleaseAndReinstantiateTalentButton`).
  - `LoadTalentTreeInternal` and `OnUpdate` (after dirty nodes are updated, which includes a staged purchase) end in `EventRegistry:TriggerEvent("TalentFrameBase.ButtonsUpdated", treeID)`.
  - `OnTraitConfigUpdated` (commit done) triggers `"TalentFrameBase.ConfigUpdated"`.
- Node data comes from `C_Traits.GetNodeInfo(configID, nodeID)`. The fields are `ranksPurchased`, `activeRank`, `currentRank`, `maxRanks`, `entryIDs`, `canPurchaseRank`, `isAvailable`, `isVisible`, `meetsEdgeRequirements`, `conditionIDs`, `subTreeID` and `type`. Other calls:
  - `C_Traits.GetEntryInfo(configID, entryID)`: `definitionID`, `maxRanks`.
  - `C_Traits.GetDefinitionInfo(definitionID)`: `spellID`, `overrideName`, `overrideIcon`.
  - `C_Traits.GetStagedChanges(configID)`: `nodeIDsWithPurchases`, `nodeIDsWithRefunds`, `nodeIDsWithSelectionSwaps`.
  - `C_Traits.GetConditionInfo(configID, condID)`: `isGate`, `isMet`, `spentAmountRequired`.
  - `C_Traits.GetConfigInfo(configID).treeIDs` and `C_Traits.GetTreeNodes(treeID)`.
  - `C_ClassTalents.GetActiveConfigID()` and `C_ClassTalents.HasUnspentTalentPoints()`.
  - `C_SpecializationInfo.GetActiveSpecGroup()` and `GetCombatConfigIDForSpecGroup(group)`.
- Names and icons are worked out the way Blizzard does it (`TalentUtil.GetTalentName`, `TalentButtonUtil.CalculateIconTexture`). The name is `overrideName` when it isn't empty, else `C_Spell.GetSpellName(spellID)`. The icon is `overrideIcon`, else `select(2, C_Spell.GetSpellTexture(spellID))`.
- **Not confirmed in source: which field is the committed rank.** `ranksPurchased` includes staged ranks. Blizzard's `IsMaxed` reads `activeRank`, which suggests that `activeRank` includes staged ranks too. So this plan reads the committed rank through `GetStagedChanges` and a snapshot (Task 4). The in-game check E1 in Task 9 settles it.

## How the tasks are cut

| # | Task | Needs | Owner can try in game |
| --- | --- | --- | --- |
| 1 | The talent window is movable | — | drag the talent window |
| 2 | The module, its defaults, the model and the store | — | nothing visible |
| 3 | The paste parser and the import summary | 2 | nothing visible |
| 4 | The talent data reader, trait stubs and the shaman fixture | 2 | nothing visible |
| 5 | The docked panel | 2, 4 | the panel, its states, collapse, plan menu |
| 6 | The import dialog | 3, 5 | paste the guide |
| 7 | Tree overlays and planning mode | 5 | hover light, glow, dim, click to plan |
| 8 | Drag reorder and phases | 5 | drag rows, add phases |
| 9 | The `/sui` page, docs and the in-game checklist | all | the settings page |

The tasks run in order. Each one from 5 on edits `talentplan.lua` or `panel.lua`, which the task before it also edited. Task 1 shares no file with 2 to 4, so it can run beside them.

## Global Constraints

- **Client.** The talent plan runs on Forever only: `TP:OnEnable` returns at once unless `st.forever`, and `TP:GetConfigTable` returns nil on retail. Task 1's movable window applies on both clients, wherever `PlayerSpellsFrame` exists.
- **Libraries.** Nothing under any `Libraries/` folder changes. No Blizzard source changes.
- **Taint (`.agents/taint.md` rules 1 to 4; the spec's Constraints).**
  - **Never written onto any Blizzard frame or table:** no field, no method, no `SetScript`, no `SetAlpha`, no texture, no `Show`/`Hide`, no `SetParent`, no `EnableMouse`. That covers `PlayerSpellsFrame`, `TalentsFrame`, `ButtonsParent` and every talent button.
  - **Blizzard calls allowed, and nothing else:**
    - post-hooks: `HookScript('OnShow'|'OnHide')` on `PlayerSpellsFrame.TalentsFrame`; `HookScript('OnHide'|'OnMouseUp')` on `PlayerSpellsFrame`; `hooksecurefunc(TalentsFrame, 'SetTab', fn)`; `hooksecurefunc(PlayerSpellsFrame, 'SetInspecting', fn)` and `('ClearInspectUnit', fn)`;
    - `EventRegistry:RegisterCallback('TalentFrameBase.ButtonsUpdated', fn, TP)` and `('TalentFrameBase.ConfigUpdated', fn, TP)`;
    - the read-only getters `IsShown`, `IsVisible`, `IsInspecting`, `GetTab`, `GetConfigID`, `EnumerateAllTalentButtons`, `GetTalentButtonByNodeID`, `GetNodeID`, `GetFrameLevel`, `GetLeft`, `GetRight`, `GetEffectiveScale`;
    - and Task 1's `st:EnableMoving(PlayerSpellsFrame)`.
  - **Never called by SaftUI:** `C_Traits.PurchaseRank`, `RefundRank` and `CommitConfig`, and any method of the talent frame that writes (`SetTab`, `SetConfigID`, `PurchaseRank`, `UpdateTreeInfo`, ...).
  - **SaftUI's frames** may be parented to `TalentsFrame` and anchored (`SetPoint`) to Blizzard's frames. Every hook body runs inside `xpcall(fn, geterrorhandler())`.
- **Clicks.** In planning mode each visible node has a catcher. A catcher is a SaftUI `Button`, mouse enabled, with `SetAllPoints(button)` and a frame level of `button:GetFrameLevel() + 10`, registered for `LeftButtonUp` and `RightButtonUp`. Outside planning mode every catcher is hidden with `EnableMouse(false)`. Light, glow and dim frames never take the mouse.
- **Combat.** Nothing is secure. Editing the plan works in combat. No `InCombatLockdown` gates are added.
- **Saved data. These shapes are exact.**
  - Profile: `st.defaults.talentplan = { enable = true, dim = true }`.
  - Account-wide: `st.config.global.talentplan = { nextID = n, plans = { [classFile] = { [id] = plan } } }`, with `plan = { id, name, steps = { nodeID, ... }, phases = { { at, name, color }, ... } }`. `at` is the index of the step a phase starts before; `#steps + 1` is an empty phase at the end.
  - Per character: `st.config.char.talentplan = { active = { [specGroup] = id }, collapsed = false }`.
- **Constants.** `TP.Model.FIRST_LEVEL = 10`, in that one place. The panel is 250 wide (`TP.Layout.WIDTH`), with a 2-unit gap from the window (`TP.Layout.GAP`). Rows are 20 high (`TP.Layout.ROW_HEIGHT`) and icons 16. The phase colors, in this order, are `blue {0.31,0.60,0.96}`, `orange {0.96,0.58,0.20}`, `yellow {0.96,0.84,0.27}`, `red {0.90,0.30,0.30}` and `green {0.40,0.80,0.40}`.
- **Theme and states.**
  - The panel is drawn with `st:SetBackdrop(panel, st.config.profile.panels.theme, st.config.profile.panels.background, 'window')`. Its title and footer strips use `st:SetTemplate(strip, 'theme', 'theme', 'header')`.
  - Rows are `st:AddStates(row, 'row')`: `hover` under the mouse and `selected` on the waiting row. Every other state is drawn through `st:SetState` too.
  - Fonts come from `st:CreateFontString(parent, 'normal')`; the title uses `'heading'`. Colors are `st:Color('text','normal')`, `('text','muted')`, `('text','danger')` and `st:Color('accent')`.
  - The new files must pass `tests/core/states_scan_test.lua`, `setfont_scan_test.lua` and `theme_kinds_test.lua`, which scan every file the TOC loads. So: no `SetFont`, no `SetBackdropBorderColor`, no `'ADD'` blend, no `ColorRGBA('accent', x)`, and no color setter inside `OnEnter`/`OnLeave`.
- **Copy.** Every string is plain English, written as below in the task that owns it: no jargon, no "Please", and sentence case.
- **Repo rules.**
  - Never `git stash` or `sed -i`. Stage by explicit path. Commit subjects are `misc: ...`, lowercase (`docs: ...` for Task 9's doc-only commit).
  - Every commit ends with these two lines:

    ```
    Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
    Claude-Session: https://claude.ai/code/session_01PYgFsKN5VTQeaHQpvA43E9
    ```
  - Keep each file's line endings.
  - Run `tests/run` before each task's last commit; it must pass.
- **Stubs (`.agents/testing.md`).**
  - Stubs are strict and faithful: a missing widget method is added to `tests/wow/widgets.lua`, never faked in a test.
  - WoW API stubs go in `tests/wow/traits.lua`, loaded at the end of `tests/wow/game.lua` after `quests.lua`.
  - Blizzard's frames are a fixture, `tests/misc/fixtures/player_spells_frame.lua`, locked with `tests/lib/locked_widget.lua`.
  - The shell has no `st.config.global` or `st.config.char`. Each test world sets both to `{}`.

## Review Focus

1. **A plan step whose node is gone from the tree.** That can come from a client patch, the wrong class, or a hand-edited SavedVariables file. The row reads "Missing talent" in Text > Danger and can still be deleted. It never becomes the waiting row, and the counts, the collapse strip and the overlays carry on past it. Tests: Task 2 (`States` with a nil node), Task 5 (the missing row's text and menu) and Task 7 (no overlay for it).
2. **Text pasted as it comes from a website.** That means CRLF line ends, tabs, non-breaking spaces, bullets, a dot or colon after the level ("10. Flurry", "Level 10: Flurry"), "(Rank 1)" in brackets, apostrophes ("Nature's Guardian" against "Natures Guardian"), and a name that is the tail of a longer one. All of these must still match in order. Test: Task 3, `parser reads web-shaped text`.
3. **The window opened in an unusual state.** It may be opened on a spec tab with no config (dual spec not bought), while inspecting, or when `Blizzard_PlayerSpells` is already loaded before SaftUI's module enables. In each case the panel shows the right thing and nothing errors: with no config every step is upcoming, and while inspecting the panel is hidden. Tests: Task 4 (`Read` of a tab with no config) and Task 5 (the inspect hide, and the addon already loaded).
4. **Staged and refunded ranks.** Two ranks may be staged on one node, or Blizzard's Reset may refund ranks before Apply. The step stays learned until the refund is applied, and a staged rank shows pending without moving the waiting row. Test: Task 4 (`CommittedRank` with a snapshot, a purchase and a refund) and Task 2 (`pending` keeps `waiting`).
5. **Plan names and choices.** Renaming, duplicating or deleting a plan that this character's other spec tab uses must work. So must an empty name or a name already taken. Each spec tab keeps its own choice, and a deleted plan leaves its tabs empty rather than broken. Tests: Task 2, `store renames, duplicates and deletes`.

---

### Task 1: The talent window is movable

**Files:**
- Modify: `SaftUI-Misc/movable.lua:7-11` (the `frames` list)
- Test: `tests/misc/movable_test.lua`

**Interfaces:**
- Consumes: `st:EnableMoving(frame)`, `st:OnBlizzardAddon(name, fn)` (Core).
- Produces: `PlayerSpellsFrame` movable once `Blizzard_PlayerSpells` loads. Task 5 relies on `st:EnableMoving`'s `OnMouseUp` hook running before its own `OnMouseUp` hook. TOC order puts `movable.lua` before `TalentPlan\load.xml`, and both waits run in registration order.

- [ ] **Step 1: Write the failing test.** Append two cases that mirror the Transmog ones:

```lua
test("PlayerSpellsFrame is movable once Blizzard_PlayerSpells loads, with no print", function()
	local talents = window('PlayerSpellsFrame')
	check(not talents:IsMovable(), 'not movable before its addon loads')
	local lines = printed_by(function() stub.fire_event('ADDON_LOADED', 'Blizzard_PlayerSpells') end)
	eq(#take_errors(), 0, 'no errors')
	check(talents:IsMovable(), 'movable when Blizzard_PlayerSpells loads')
	eq(#lines, 0, 'nothing printed')
end)

test('PlayerSpellsFrame already there at login is movable at once', function()
	reset_world()
	load_saftui('SaftUI-Misc/movable.lua')
	local talents = CreateFrame('Frame', 'PlayerSpellsFrame', UIParent)
	window('SettingsPanel'); window('AddonList')
	SaftUI:GetModule('Movable'):Enable()
	check(talents:IsMovable(), 'movable at enable')
end)
```

Also update the file's header comment to name `Blizzard_PlayerSpells`.

- [ ] **Step 2: Run it to verify it fails.** Run `tests/run tests/misc/movable_test.lua`. Expected: FAIL, with "movable when Blizzard_PlayerSpells loads" and "movable at enable".

- [ ] **Step 3: Add `{ name = 'PlayerSpellsFrame', addon = 'Blizzard_PlayerSpells' }` to `frames` in `SaftUI-Misc/movable.lua`, after Transmog.** Update the comment above the list: Blizzard_PlayerSpells is LoadOnDemand, checked in the forever source on 2026-11-22.

- [ ] **Step 4: Run it to verify it passes.** Run `tests/run tests/misc/movable_test.lua`. Expected: PASS (5 cases).

- [ ] **Step 5: Commit.**

```bash
git add SaftUI-Misc/movable.lua tests/misc/movable_test.lua
git commit -m "misc: make the talent window movable"
```

In-game check (goes into Task 9's list): open talents, drag the window by its frame, release it, close it and open it again. It is back in Blizzard's spot, and nothing in BugGrabber.

---

### Task 2: The module, its defaults, the model and the store

**Files:**
- Create: `SaftUI-Misc/TalentPlan/load.xml`. It lists, in order, `talentplan.lua`, `model.lua`, `store.lua`, `parser.lua`, `data.lua`, `drag.lua`, `panel.lua`, `import.lua`, `overlays.lua` and `options.lua`. Add each file to it in the task that creates it.
- Create: `SaftUI-Misc/TalentPlan/talentplan.lua` (the module, `OnEnable` a stub for now), `SaftUI-Misc/TalentPlan/model.lua`, `SaftUI-Misc/TalentPlan/store.lua`
- Modify: `SaftUI-Misc/SaftUI-Misc.toc`: add `TalentPlan\load.xml` after `movable.lua`, before `Skinning\load.xml`
- Modify: `SaftUI-Misc/config.lua`: append `st.defaults.talentplan`, with a comment
- Test: `tests/misc/talentplan_model_test.lua`, `tests/misc/talentplan_store_test.lua`

**Interfaces:**
- Produces, in `talentplan.lua`: `local TP = st:NewModule('TalentPlan')` (later files use `st:GetModule('TalentPlan')`). Also `TP:OnEnable()`, which calls `st:BindModuleConfig(self, 'talentplan')` and returns unless `st.forever`.
- Produces, in `model.lua` (`TP.Model`, pure, no WoW API):
  - `M.FIRST_LEVEL = 10`; `M.PHASE_COLORS = { 'blue','orange','yellow','red','green' }`; `M.PHASE_RGB[color] = { r, g, b }` (the Global Constraints values).
  - `M.NewPlan(id, name) -> plan`
  - `M.Level(index) -> FIRST_LEVEL + index - 1`
  - `M.Ranks(steps) -> { [index] = rank }`. A step's rank is how many times its node has come so far.
  - `M.PlannedRanks(plan, nodeID) -> n`
  - `M.StepsOf(plan, nodeID) -> { { index, rank, level }, ... }`
  - `M.AddStep(plan, nodeID, after) -> index`. With `after` nil it appends and shifts nothing. With `after = k` it inserts at k + 1, and every phase with `at > k` gets `at + 1`.
  - `M.RemoveStep(plan, index)`. Every phase with `at > index` gets `at - 1`.
  - `M.RemoveLastOf(plan, nodeID) -> index|nil`
  - `M.States(plan, nodes, level) -> rows, summary`. `nodes[nodeID] = { committed, staged, maxRanks, block }`; a node that isn't there is a missing step.
    - Each row is `{ index, nodeID, rank, level, state, waiting, block }`. `state` is one of `'learned'|'pending'|'upcoming'|'missing'`.
    - `summary = { learned, total, waiting }`. `total` counts the steps that aren't missing.
    - With `level` nil, nothing is waiting.
  - `M.OffPlan(plan, nodes) -> n`: the sum over nodes of `max(0, committed - PlannedRanks)`.
  - `M.UniqueName(names, base) -> name`, where `names` is a set of names in use: `base`, then `base .. ' 2'`, `' 3'`, ...
- Produces, in `store.lua` (`TP.Store`; reads `st.config.global` and `st.config.char` at call time):
  - `S.ClassFile() -> select(2, UnitClass('player'))`
  - `S.Plans() -> { [id] = plan }` for this class, made on first use.
  - `S.Char() -> { active, collapsed }`, made on first use.
  - `S.List() -> { plan, ... }` sorted by `name:lower()`.
  - `S.Active(specGroup) -> plan|nil`
  - `S.SetActive(specGroup, id|nil)`
  - `S.New(name, specGroup) -> plan`. It makes the name unique, takes `id = nextID` (starting at 1) and makes the plan active for `specGroup`.
  - `S.Rename(plan, name) -> true | false, reason`. It trims the name. `reason` is `'empty'` or `'taken'`, and keeping the same name is fine.
  - `S.Duplicate(plan, specGroup) -> copy`. The copy is a deep copy named `UniqueName(name .. ' copy')`, active for `specGroup`.
  - `S.Delete(plan)`. It removes the plan and clears every `char.active` entry that points at its id.

- [ ] **Step 1: Write the failing model tests in `tests/misc/talentplan_model_test.lua`.** The world: `load_saftui` on `talentplan.lua` and then `model.lua`, and `local M = SaftUI:GetModule('TalentPlan').Model`. The cases, with their assertions:

```lua
test('ranks count each node so far, and renumber when steps swap', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 7, 7, 9, 7 }
	local r = M.Ranks(plan.steps)
	eq(r[1], 1); eq(r[2], 2); eq(r[3], 1); eq(r[4], 3)
	plan.steps = { 7, 9, 7, 7 } -- a rank 2 moved below another node
	r = M.Ranks(plan.steps); eq(r[3], 2, 'renumbered in list order')
	eq(M.Level(1), 10); eq(M.Level(51), 60)
end)

test('AddStep appends without shifting a trailing phase, and inserts after a row shifting later phases', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3 }
	plan.phases = { { at = 2, name = 'B', color = 'blue' }, { at = 4, name = 'C', color = 'red' } }
	eq(M.AddStep(plan, 5), 4); eq(plan.phases[2].at, 4, 'trailing phase now holds the appended step')
	eq(M.AddStep(plan, 6, 1), 2); eq(plan.steps[2], 6)
	eq(plan.phases[1].at, 3, 'phase after the row moves down'); eq(plan.phases[2].at, 5)
end)

test('RemoveStep and RemoveLastOf shift phases up', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 1, 3 }
	plan.phases = { { at = 3, name = 'B', color = 'blue' } }
	eq(M.RemoveLastOf(plan, 1), 3); eq(#plan.steps, 3); eq(plan.phases[1].at, 3)
	M.RemoveStep(plan, 1); eq(plan.phases[1].at, 2)
	eq(M.RemoveLastOf(plan, 99), nil)
end)

test('States: learned, waiting, pending, upcoming, missing, blocked', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 1, 2, 3, 4, 2 }
	local nodes = {
		[1] = { committed = 2, staged = 2, maxRanks = 2 },
		[2] = { committed = 0, staged = 1, maxRanks = 2 },         -- rank 1 staged
		[3] = { committed = 0, staged = 0, maxRanks = 1, block = 'Needs the talent above it first.' },
		-- 4 is missing
	}
	local rows, sum = M.States(plan, nodes, 13)
	eq(rows[1].state, 'learned'); eq(rows[2].state, 'learned')
	eq(rows[3].state, 'pending'); check(rows[3].waiting, 'a staged step is still the waiting one')
	eq(rows[4].state, 'upcoming'); check(not rows[4].waiting)
	eq(rows[5].state, 'missing'); eq(rows[6].state, 'upcoming')
	eq(sum.learned, 2); eq(sum.total, 5, 'missing steps are not counted'); eq(sum.waiting, 3)
	nodes[2].staged = 0
	rows, sum = M.States(plan, nodes, 13)
	eq(rows[3].state, 'upcoming'); check(rows[3].waiting); eq(rows[3].block, nil)
	nodes[2].committed, nodes[2].staged = 1, 1
	rows, sum = M.States(plan, nodes, 13)
	eq(sum.waiting, 4); eq(rows[4].block, 'Needs the talent above it first.', 'the waiting row carries its block')
	rows, sum = M.States(plan, nodes, 12); eq(sum.waiting, nil, 'step 4 is level 13: nothing waits at 12')
	rows, sum = M.States(plan, nodes, nil); eq(sum.waiting, nil, 'no level: no config, all upcoming')
end)

test('a missing step is never waiting, and the next one is', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 4, 2 }
	local rows, sum = M.States(plan, { [2] = { committed = 0, staged = 0, maxRanks = 1 } }, 60)
	eq(rows[1].state, 'missing'); eq(sum.waiting, 2)
end)

test('OffPlan counts ranks beyond the plan', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2 }
	eq(M.OffPlan(plan, { [1] = { committed = 3 }, [2] = { committed = 1 }, [5] = { committed = 1 } }), 3)
end)

test('StepsOf and UniqueName', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 1 }
	local s = M.StepsOf(plan, 1)
	eq(#s, 2); eq(s[2].index, 3); eq(s[2].rank, 2); eq(s[2].level, 12)
	eq(M.UniqueName({ Imported = true, ['Imported 2'] = true }, 'Imported'), 'Imported 3')
end)
```

- [ ] **Step 2: Write the failing store tests in `tests/misc/talentplan_store_test.lua`.** The world: `stub.class = 'SHAMAN'`, `SaftUI.config.global = {}`, `SaftUI.config.char = {}`, then load the module, the model and the store. The case `store renames, duplicates and deletes` (Review Focus 5):

```lua
local a = S.New('Enhancement', 1); eq(a.id, 1); eq(S.Active(1), a)
local b = S.New('Enhancement', 2); eq(b.name, 'Enhancement 2'); eq(S.Active(2), b)
eq(select(2, S.Rename(b, '  ')), 'empty'); eq(select(2, S.Rename(b, 'Enhancement')), 'taken')
check(S.Rename(a, 'Enhancement'), 'same name is fine'); check(S.Rename(a, 'Enh leveling'))
eq(S.Active(1).name, 'Enh leveling', 'the tab follows by id')
local c = S.Duplicate(a, 2); eq(c.name, 'Enh leveling copy'); eq(S.Active(2), c)
check(c.steps ~= a.steps, 'a deep copy')
S.SetActive(1, c.id); S.Delete(c)
eq(S.Active(1), nil); eq(S.Active(2), nil, 'both tabs that used it are empty')
eq(#S.List(), 2); eq(S.List()[1].name, 'Enh leveling')
eq(SaftUI.config.global.talentplan.plans.SHAMAN[a.id], a, 'saved by class and id')
```

A second case, `a choice pointing at a plan that is gone reads as none`: set `S.Char().active[1] = 42` and check `S.Active(1) == nil`.

- [ ] **Step 3: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_model_test.lua tests/misc/talentplan_store_test.lua`. Expected: FAIL, because `SaftUI-Misc/TalentPlan/talentplan.lua` can't be read.

- [ ] **Step 4: Implement.**
  - Create `talentplan.lua`, `model.lua` and `store.lua` with the Interfaces above.
  - Create `load.xml` and the TOC line.
  - Append the defaults to `config.lua`: `st.defaults.talentplan = { enable = true, dim = true }`, with a comment saying the plans live in `global` and `char`, and where.
  - `M.States`: first mark learned (`committed >= rank`), then missing, then pending (`staged >= rank`). Then the waiting row is the first row that is neither learned nor missing and has `level <= level`. Only the waiting row copies `node.block`. A waiting row keeps its `pending` state.

- [ ] **Step 5: Run them to verify they pass.** Run the same command, then the whole `tests/run`. Expected: PASS everywhere.

- [ ] **Step 6: Commit.**

```bash
git add SaftUI-Misc/TalentPlan/load.xml SaftUI-Misc/TalentPlan/talentplan.lua SaftUI-Misc/TalentPlan/model.lua SaftUI-Misc/TalentPlan/store.lua SaftUI-Misc/SaftUI-Misc.toc SaftUI-Misc/config.lua tests/misc/talentplan_model_test.lua tests/misc/talentplan_store_test.lua
git commit -m "misc: add the talent plan's model and saved plans"
```

---

### Task 3: The paste parser and the import summary

**Files:**
- Create: `SaftUI-Misc/TalentPlan/parser.lua` (add it to `load.xml`)
- Create: `tests/misc/fixtures/talentplan_shaman.lua`: the shaman tree as names. Task 4 extends it into the trait stubs.
- Test: `tests/misc/talentplan_parser_test.lua`

**Interfaces:**
- Consumes: `TP.Model` (`FIRST_LEVEL`, `Level`).
- Produces:
  - `TP.Parse(text, names) -> result`
    - `names` is `{ { name, nodeID, maxRanks }, ... }`, the shape of Task 4's `tree.names`.
    - `result = { steps = { nodeID, ... }, warnings = { { line, text } }, unmatched = { { line, text } } }`.
  - `TP.ImportSummary(result, maxLines) -> { string, ... }`
  - `TP.Normalize(s) -> string`
- Produces, in the fixture: `SH.NAMES`, the list for `TP.Parse`. It holds the 20 talents of the guide plus three decoys, `Improved Lightning Shield`, `Nature's Guardian` and `Totemic Focus`. The node IDs are 101 to 123 and the max ranks are fixture data:
  - Thundering Strikes 5, Mental Dexterity 3, Ancestral Knowledge 5, Shamanistic Focus 1, Elemental Weapons 3;
  - Stormstrike 1, Improved Ghost Wolf 2, Flurry 5, Improved Stormstrike 2, Mental Quickness 3;
  - Spirit Weapons 1, Maelstrom Weapon 5, Tidal Focus 5, Mindfulness 3, Concussion 5;
  - Call of Flame 3, Elemental Devastation 3, Elemental Focus 1, Reverberation 5, Trial by Fire 3;
  - the decoys 3, 5 and 5.
  - `SH.ID[name]` gives each name's node ID.

The parser's rules. The spec fixes them, and this plan settles the parts in **bold**:
- `TP.Normalize`: lowercase; drop `'` and `’`; every other character that isn't `%w` becomes a space; spaces are squeezed and trimmed. A name and the text are normalized the same way.
- **Before normalizing**, each `N/M` (digits) becomes ` rank N ` and each `\r` becomes nothing.
- The text is read line by line, as words, with the line number kept for every word. At each word:
  1. Try the names, longest first (by word count, then by length). A match takes its words.
  2. After a match, `rank N`, `r N`, `rankN` or `rN` is the given rank, on that line or at the start of the next. It is used only to check.
  3. A number word that isn't a rank is a level. It is checked against the last level seen, then becomes the last level seen.
  4. Any other word is unmatched.
- **The words `level`, `lvl` and `rank` are never unmatched.**
- **Lines before the first match are a preamble and skipped silently.** This is how the fixture's "Talent Order" header goes unreported. After the first match, a line holding an unmatched word goes into `unmatched` once, as its trimmed original text.
- A name found adds `nodeID`, with rank = planned so far + 1. If it is already at `maxRanks`, it is left out with a warning. The warning copy is exact:
  - `('Line %d: %s says rank %d, but it is rank %d in the plan.'):format(line, name, given, rank)`
  - `('Line %d: %s has only %d ranks, so this one is left out.'):format(line, name, maxRanks)`
  - `('Line %d: level %d comes after level %d.'):format(line, level, previous)`, for a level that doesn't follow `previous + 1`. The first level found isn't checked against `FIRST_LEVEL`.
- `TP.ImportSummary` returns, in order:
  - `('%d steps, levels %d to %d.'):format(n, 10, Level(n))`, or `'No talents found.'` when n is 0;
  - the warnings' texts, up to `maxLines`, then `('and %d more'):format(rest)`;
  - for each unmatched line, `('Not matched, line %d: %s'):format(line, text)`, up to `maxLines`, then `('and %d more'):format(rest)`.

- [ ] **Step 1: Write the failing tests.** Read the fixture text with `read_test_source('misc/fixtures/talentplan_guide_enhancement.txt')`.

```lua
test("the owner's guide: 51 steps, levels 10 to 60, nothing reported", function()
	local r = TP.Parse(GUIDE, SH.NAMES)
	eq(#r.steps, 51); eq(#r.warnings, 0); eq(#r.unmatched, 0, 'the "Talent Order" header is skipped silently')
	eq(r.steps[1], SH.ID['Thundering Strikes']); eq(r.steps[11], SH.ID['Shamanistic Focus'])
	eq(r.steps[16], SH.ID['Stormstrike']); eq(r.steps[21], SH.ID['Improved Stormstrike'])
	eq(r.steps[15], SH.ID['Ancestral Knowledge'], 'rank 3 after a gap'); eq(M.Ranks(r.steps)[15], 3)
	eq(TP.ImportSummary(r, 3)[1], '51 steps, levels 10 to 60.')
end)

test('one line per step reads the same', function()
	local r = TP.Parse('10 Thundering Strikes Rank 1\n11 Thundering Strikes Rank 2\n12 Flurry 1/5', SH.NAMES)
	eq(#r.steps, 3); eq(#r.warnings, 0); eq(r.steps[3], SH.ID['Flurry'])
end)

test('longest name first, unmatched lines and warnings', function()
	local r = TP.Parse('10 Improved Stormstrike\n11 Stormstrike\n12 Totem Twisting\n14 Flurry Rank 3\n15 Spirit Weapons\n16 Spirit Weapons', SH.NAMES)
	eq(r.steps[1], SH.ID['Improved Stormstrike']); eq(r.steps[2], SH.ID['Stormstrike'])
	eq(#r.unmatched, 1); eq(r.unmatched[1].line, 3); eq(r.unmatched[1].text, '12 Totem Twisting')
	eq(r.warnings[1].text, 'Line 4: level 14 comes after level 12.')
	eq(r.warnings[2].text, 'Line 4: Flurry says rank 3, but it is rank 1 in the plan.')
	eq(r.warnings[3].text, 'Line 6: Spirit Weapons has only 1 ranks, so this one is left out.')
	eq(#r.steps, 4)
end)

test('parser reads web-shaped text', function() -- Review Focus 2
	local text = 'Leveling order\r\n\t10.\194\160Thundering Strikes (Rank 1)\r\n• Level 11: thundering strikes r2\r\n12 - Natures Guardian\r\n'
	local r = TP.Parse(text, SH.NAMES)
	eq(#r.steps, 3); eq(#r.warnings, 0); eq(#r.unmatched, 0)
	eq(r.steps[3], SH.ID["Nature's Guardian"])
end)

test('a guide from another class reports, never guesses', function()
	local r = TP.Parse('10 Improved Fireball\n11 Ignite', SH.NAMES)
	eq(#r.steps, 0); eq(#r.unmatched, 0, 'no match at all: all preamble')
	eq(TP.ImportSummary(r, 3)[1], 'No talents found.')
end)

test('the summary cuts long lists', function()
	local r = { steps = { 1 }, warnings = {}, unmatched = {} }
	for i = 1, 5 do r.unmatched[i] = { line = i, text = 'x' .. i } end
	local s = TP.ImportSummary(r, 3)
	eq(s[2], 'Not matched, line 1: x1'); eq(s[5], 'and 2 more'); eq(#s, 5)
end)
```

The `\194\160` is a non-breaking space. Normalization turns it and the bullet's UTF-8 bytes into spaces, and the word `level` on line 3 is never unmatched, so the case's `eq(#r.unmatched, 0)` pins both rules.

- [ ] **Step 2: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_parser_test.lua`. Expected: FAIL (`parser.lua` missing).

- [ ] **Step 3: Implement `parser.lua` and the fixture's `SH.NAMES`/`SH.ID`** by the rules above. Use string patterns only, since Lua 5.1 has no `utf8`.

- [ ] **Step 4: Run them to verify they pass.** Run the same command, then `tests/run`. Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add SaftUI-Misc/TalentPlan/parser.lua SaftUI-Misc/TalentPlan/load.xml tests/misc/fixtures/talentplan_shaman.lua tests/misc/talentplan_parser_test.lua
git commit -m "misc: parse a pasted talent order into plan steps"
```

---

### Task 4: The talent data reader, trait stubs and the shaman fixture

**Files:**
- Create: `tests/wow/traits.lua`, loaded with `load_test_file('wow/traits.lua')` as the last line of `tests/wow/game.lua`
- Create: `SaftUI-Misc/TalentPlan/data.lua` (add it to `load.xml`)
- Modify: `tests/misc/fixtures/talentplan_shaman.lua`: add `SH.install(opts)`
- Test: `tests/misc/talentplan_data_test.lua`

**Interfaces:**
- Produces, in `tests/wow/traits.lua`, a fresh `stub.traits` per world. Its shape:

  ```
  stub.traits = { active_group = 1,
    group_configs = { [1] = configID, [2] = nil },
    configs = { [configID] = { treeIDs = { treeID } } },
    trees = { [treeID] = { nodeID, ... } },
    nodes = { [configID] = { [nodeID] = TraitNodeInfo } },
    entries = { [entryID] = { definitionID, maxRanks, type = 1 } },
    definitions = { [definitionID] = { spellID, overrideName, overrideIcon } },
    spells = { [spellID] = { name, icon } },
    conditions = { [condID] = { isGate, isMet, spentAmountRequired } },
    staged = { [configID] = { purchases = {}, refunds = {} } },
    unspent = false, calls = {} }
  ```

  The functions, faithful to the documentation signatures:
  - `C_Traits.GetConfigInfo`, `GetTreeNodes`, `GetNodeInfo`, `GetEntryInfo`, `GetDefinitionInfo`, `GetConditionInfo` and `GetStagedChanges` (it returns three tables);
  - `C_Traits.PurchaseRank`, `RefundRank` and `CommitConfig`, each appending its name to `stub.traits.calls`. A test asserts the list stays empty.
  - `C_ClassTalents.GetActiveConfigID` (the active group's config) and `HasUnspentTalentPoints`;
  - `C_SpecializationInfo.GetActiveSpecGroup` and `GetCombatConfigIDForSpecGroup`;
  - `C_Spell.GetSpellName` and `GetSpellTexture` (it returns `icon, icon`). Use `C_Spell = C_Spell or {}`.
  - `GetNodeInfo` of an unknown node returns nil, and the reader must cope. What the real API returns there is unverified; say so in the file's header.
  - Each function errors with Blizzard's usage text on a non-number argument.
- Produces, in the fixture: `SH.install(opts) -> SH.world`. It fills `stub.traits` with config 1001 (group 1) and tree 501, holding the 23 nodes of `SH.NAMES`.
  - Each node gets `isVisible = true`, `canPurchaseRank = true`, `meetsEdgeRequirements = true`, `isAvailable = true` and one entry.
  - Also: one choice node (two entryIDs, ID 130) and one invisible node (ID 131), which the reader skips.
  - `opts.ranks[name] = n` sets `ranksPurchased`. `opts.second = true` adds config 1002 for group 2.
- Produces, in `data.lua` (`TP.Data`):
  - `D.Read(specGroup) -> tree|nil`. `tree = { specGroup, configID|nil, treeID, active, level, nodes = { [nodeID] = { nodeID, name, icon, maxRanks, committed, staged, block } }, names = { { name, nodeID, maxRanks } } }`.
    - The tree ID comes from the group's config, else from `C_ClassTalents.GetActiveConfigID()`'s. It is nil when neither exists.
    - With no config, every rank is 0 and `level` is nil. That is the spec's "every step upcoming".
    - Nodes are skipped when they aren't visible, have `#entryIDs ~= 1`, have a `subTreeID`, or have no name.
  - `D.CommittedRank(purchased, stagedKind, known) -> n`. With `stagedKind` nil it is `purchased`. With a `known` snapshot it is `known`. Without one, `'purchase'` gives `max(0, purchased - 1)` and `'refund'` gives `purchased + 1`.
  - `D.BlockReason(info, gates, active) -> string|nil`. The exact copy:
    - nil when `info.canPurchaseRank`;
    - `'Switch to this spec to learn it.'` when the tab isn't active;
    - `'Needs the talent above it first.'` when `not info.meetsEdgeRequirements`;
    - `('Needs %d points spent in the tree first.'):format(n)`, using the first unmet gate's `spentAmountRequired`, when `not info.isAvailable`;
    - `'Not available yet.'` when that gate gives no number;
    - otherwise `'No talent points to spend.'`.
  - `D.ResetSnapshots()` is for tests. The snapshot is `snapshots[configID][nodeID] = ranksPurchased`, written on every read of a node that has no staged change.

- [ ] **Step 1: Write the failing tests.**

```lua
test('Read gives names, icons, ranks and skips choice and hidden nodes', function()
	SH.install({ ranks = { ['Thundering Strikes'] = 3 } })
	local t = D.Read(1)
	eq(t.configID, 1001); eq(t.treeID, 501); check(t.active); eq(t.level, stub.level)
	local n = t.nodes[SH.ID['Thundering Strikes']]
	eq(n.name, 'Thundering Strikes'); eq(n.maxRanks, 5); eq(n.committed, 3); eq(n.staged, 3)
	eq(t.nodes[130], nil); eq(t.nodes[131], nil); eq(#t.names, 23)
	eq(#stub.traits.calls, 0, 'nothing bought or committed')
end)

test('an override name wins, and a spell name is the fallback', function() --[[ set overrideName on one definition, then check ]] end)

test('a tab with no config: tree from the active config, ranks 0, no level', function() -- Review Focus 3
	SH.install({ ranks = { Flurry = 2 } })
	local t = D.Read(2)
	eq(t.configID, nil); eq(t.treeID, 501); eq(t.level, nil); check(not t.active)
	eq(t.nodes[SH.ID.Flurry].committed, 0)
end)

test('no config anywhere: nil', function() stub.traits.group_configs = {}; stub.traits.active_group = 1; eq(D.Read(1), nil) end)

test('staged purchases and refunds keep the committed rank', function() -- Review Focus 4
	eq(D.CommittedRank(2, nil, nil), 2); eq(D.CommittedRank(3, 'purchase', 1), 1, 'two staged, snapshot wins')
	eq(D.CommittedRank(3, 'purchase', nil), 2); eq(D.CommittedRank(0, 'refund', 2), 2); eq(D.CommittedRank(1, 'refund', nil), 2)
	SH.install({ ranks = { Flurry = 1 } }); D.ResetSnapshots(); D.Read(1)        -- snapshot 1
	stub.traits.nodes[1001][SH.ID.Flurry].ranksPurchased = 3
	stub.traits.staged[1001].purchases = { SH.ID.Flurry }
	local n = D.Read(1).nodes[SH.ID.Flurry]; eq(n.committed, 1); eq(n.staged, 3)
end)

test('BlockReason copy', function()
	eq(D.BlockReason({ canPurchaseRank = true }, {}, true), nil)
	eq(D.BlockReason({ canPurchaseRank = false }, {}, false), 'Switch to this spec to learn it.')
	eq(D.BlockReason({ meetsEdgeRequirements = false }, {}, true), 'Needs the talent above it first.')
	eq(D.BlockReason({ meetsEdgeRequirements = true, isAvailable = false }, { { isGate = true, isMet = false, spentAmountRequired = 8 } }, true), 'Needs 8 points spent in the tree first.')
	eq(D.BlockReason({ meetsEdgeRequirements = true, isAvailable = true }, {}, true), 'No talent points to spend.')
end)
```

Fill the override-name case with real assertions: set `stub.traits.definitions[...].overrideName = 'Renamed'`, then `eq(D.Read(1).nodes[id].name, 'Renamed')`. Also add a `tests/lib/harness_self_test.lua` case: in a fresh world, `C_Traits.GetNodeInfo('x', 1)` errors, which pins the strict usage errors.

- [ ] **Step 2: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_data_test.lua`. Expected: FAIL (`C_Traits` is nil).

- [ ] **Step 3: Implement `tests/wow/traits.lua`, the fixture's `SH.install` and `data.lua`.** `D.Read` reads the gates for `BlockReason` from `info.conditionIDs` through `C_Traits.GetConditionInfo(configID, id)`. It builds `staged` sets from `GetStagedChanges(configID)` once per read.

- [ ] **Step 4: Run them to verify they pass.** Run the same command, then `tests/run` and `tests/run --self-check`. Expected: PASS. The self-check is there because `game.lua` changed.

- [ ] **Step 5: Commit.**

```bash
git add tests/wow/traits.lua tests/wow/game.lua tests/lib/harness_self_test.lua SaftUI-Misc/TalentPlan/data.lua SaftUI-Misc/TalentPlan/load.xml tests/misc/fixtures/talentplan_shaman.lua tests/misc/talentplan_data_test.lua
git commit -m "misc: read the class talent tree for the talent plan"
```

---

### Task 5: The docked panel

**Files:**
- Create: `SaftUI-Misc/TalentPlan/panel.lua` (add it to `load.xml`)
- Modify: `SaftUI-Misc/TalentPlan/talentplan.lua`: `OnEnable` waits for the addon, plus the hooks, the events and `TP:Refresh`
- Create: `tests/misc/fixtures/player_spells_frame.lua`
- Test: `tests/misc/talentplan_panel_test.lua`

**Interfaces:**
- Consumes: Tasks 2 and 4 (`M.States`, `M.OffPlan`, the `S.*` functions, `D.Read`); `st:OnBlizzardAddon`; `MenuUtil.CreateContextMenu(owner, fn(owner, root))`, with `root:CreateButton(text, fn)`, `root:CreateRadio(text, isSelected, setSelected)` and `root:CreateDivider()`; `st.OptionsWidgets.Prompt` and `Confirm`.
- Produces, in `talentplan.lua`:
  - `TP:SetupBlizzard()` runs once, from `st:OnBlizzardAddon('Blizzard_PlayerSpells', ...)`. It installs only the hooks named in Global Constraints. Each hook asks for `TP:QueueRefresh()`; the `OnMouseUp` hook asks for `TP:QueueDock()`.
  - `TP:QueueRefresh()` coalesces to one `C_Timer.After(0, ...)`.
  - `TP:Refresh()` is the one place that reads (`D.Read(TP:ViewedGroup())`) and draws: the panel, and from Task 7 the overlays.
  - `TP:ViewedGroup() -> PlayerSpellsFrame.TalentsFrame:GetTab()`
  - `TP:ShouldShow() -> bool`: `config.enable`, `TalentsFrame:IsShown()` and `not PlayerSpellsFrame:IsInspecting()`.
  - `TP.view = { tree, plan, rows, summary }`, the last refresh's result, for Tasks 6 to 8.
  - Its own event frame, registered while the panel shows, takes `PLAYER_LEVEL_UP`, `TRAIT_CONFIG_UPDATED` and `TRAIT_NODE_CHANGED`, each into `QueueRefresh`.
- Produces, in `panel.lua`:
  - `TP.Layout.WIDTH = 250`, `GAP = 2`, `ROW_HEIGHT = 20`.
  - `TP.Layout.Side(left, right, screenWidth, width) -> 'RIGHT'|'LEFT'`. It takes the side with more room, and RIGHT on a tie.
  - `TP.Layout.ScrollOffset(index, rowHeight, viewHeight, contentHeight) -> offset`. The row's top sits a third of the view down, clamped to `[0, max(0, contentHeight - viewHeight)]`, in whole units.
  - `TP.StepLabel(row, node) -> string`. It is `'27 Improved Ghost Wolf R2'`; the ` R%d` part is dropped when `maxRanks == 1`, and a missing node gives `'Missing talent'`.
  - `TP.StripText(view) -> string`. It is the waiting row's `StepLabel`, else `'Plan complete'` when all steps are learned, else `('Next: %s'):format(StepLabel(first upcoming))`, else `'No plan'`.
  - `TP:BuildPanel()` (lazy, on first show), `TP:DrawPanel(view)`, `TP:Dock()`, `TP:SetCollapsed(on)`, `TP:ScrollToWaiting()` and `TP.panel` (the frame). The rows are `TP.panel.rows[i] = { frame, kind, index }`, for Task 8's drag. A selected row is `TP.selected`, a step index or nil, for Task 7.

What the panel is (spec, "The panel"; the settled parts are in bold):
- **Frames.**
  - The panel is a SaftUI frame parented to `TalentsFrame`, so it hides with the Talents tab, `WIDTH` wide.
  - It hangs by two points from `PlayerSpellsFrame`. For RIGHT that is `TOPLEFT` to `TOPRIGHT` and `BOTTOMLEFT` to `BOTTOMRIGHT`, at `GAP`; LEFT mirrors it. It is clamped to the screen with `SetClampedToScreen(true)`.
  - `Dock()` reads the window's left and right in UIParent's units and calls `Side`. It runs on show, on the next frame (the panel layout moves the window after `OnShow`), and on `OnMouseUp` on the next frame.
- **Title strip.**
  - From left to right: the collapse arrow (`st.icons.chevronRight` on the RIGHT side, `chevronLeft` on the LEFT), `'Leveling plan'`, the plan select button (the plan's name, or `'No plan'`), and the count `('%d/%d'):format(learned, total)`.
  - Under it, while planning (Task 7), the line `"Click talents in the order you'll take them"`.
- **Rows.** The rows sit in `st:CreateScrollFrame(panel)`.
  - A step row: the level, tabular (`'%2d'`); the icon at 16; the name; and on the right, `'R2'` for a node with more than one rank, or the state tag `'pending'` or `'blocked'`.
  - A learned row shows a check (`Interface\\RaidFrame\\ReadyCheck-Ready`, 12) and its name in Text > Muted.
  - The waiting row is `st:SetState(row, 'selected', true)`. A blocked row's tooltip is its `block`. A pending row's tooltip is `'Staged. Press Apply in the talent window to learn it.'`.
  - A missing row reads `'Missing talent'` in Text > Danger, and its tooltip is `"This talent isn't in your class's tree any more. Right-click to delete the step."`.
  - A left click selects the row, or clears the selection if it was selected: an Accent line 2 high under the row, the new steps' place. Right-click opens a menu with `'Remove step'`.
- **Footer.** `st:CreateFooter(panel)`.
  - Buttons: `'Plan'` (Task 7 makes it work; until then it toggles nothing), `'Import'` (Task 6), `'Phases'` (Task 8), and the dots (`st.icons.ellipsis`).
  - The dots open a menu: `'Rename'` (`Prompt('Rename the plan', name, ...)`; `'empty'` and `'taken'` print `'A plan needs a name.'` and `'There is already a plan with that name.'` through `st:Print`), `'Duplicate'`, `'Delete plan'` (`Confirm(('Delete the plan "%s"? This can\'t be undone.'):format(name), ...)`) and `'Clear steps'` (`Confirm(('Clear every step of "%s"?'):format(name), ...)`).
  - Above the footer is the off-plan line: `'1 point off plan'`, `('%d points off plan'):format(n)`, or hidden at 0.
- **The plan select menu.** A radio item per plan in `S.List()` (checked when it is the active plan), a divider, then `'New plan'`, which calls `S.New('New plan', group)`.
- **Empty state.** With no plan for the tab, the rows are replaced by `"No leveling plan for this spec tab. Import a guide's talent order, or press Plan and click talents in the order you'll take them."`. Import and Plan stay. Plan with no plan first calls `S.New('New plan', group)`.
- **Collapse.** `SetCollapsed(true)` saves `S.Char().collapsed`. It hides the body and footer and leaves a strip `WIDTH` wide and as tall as the title (`st.config.profile.headers.height`), on the same side. The strip holds `TP.StripText(view)` and the expand arrow. The saved state is applied on every show.
- **On show.** Dock, refresh, then `ScrollToWaiting()` on that show only, not on later refreshes.

- [ ] **Step 1: Write the fixture `tests/misc/fixtures/player_spells_frame.lua`.**
  - `PSF.build(opts)` makes what loading `Blizzard_PlayerSpells` makes, as far as the talent plan reads it:
    - `PlayerSpellsFrame` (1218 by 708, TOP of UIParent at 0, -41, hidden), with `IsInspecting`, `SetInspecting(unit)` and `ClearInspectUnit` (`_inspecting`);
    - `.TalentsFrame` (1212 by 681, BOTTOM 0, 4, hidden), with `GetTab` (`_tab`, 1), `SetTab(tab)`, `GetConfigID`, `GetTalentTreeID`, `GetTalentButtonByNodeID`, `EnumerateAllTalentButtons` (an iterator over `_buttons`) and `.ButtonsParent`;
    - one 40 by 40 Button per node of `SH.world`, under `ButtonsParent`, laid in a grid, at frame level 5110, with `GetNodeID` (`_node`) and an `OnClick` that counts `PSF.clicks[nodeID]`.
  - Every one of these is locked with `tests/lib/locked_widget.lua` (owner `'Blizzard'`).
  - `PSF.load()` sets `stub.loaded_addons.Blizzard_PlayerSpells = true` and fires `ADDON_LOADED`.
  - `PSF.open()` shows both frames, the way Blizzard's `ShowUIPanel` and `SetTab` do.
  - `PSF.redraw()` triggers `EventRegistry:TriggerEvent('TalentFrameBase.ButtonsUpdated', 501)`.
  - `PSF.rebind(button, nodeID)` re-binds a button the way the pool does.
  - The header comment names the forever files each piece mirrors.

- [ ] **Step 2: Write the failing tests in `tests/misc/talentplan_panel_test.lua`.** The world:
  - `stub.class = 'SHAMAN'`, `stub.level = 27`, `SaftUI.config.global = {}` and `SaftUI.config.char = {}`;
  - `load_core_helpers()`, `load_options_widgets()` (for Confirm and Prompt), Misc's `config.lua` and `apply_defaults()`;
  - the TalentPlan files through `parser.lua`, `data.lua` and `panel.lua` in `load.xml` order;
  - `SH.install(...)`, `PSF.build()`, `TP:Enable()`, `PSF.load()`;
  - a `MenuUtil` stand-in like `tests/tracker/clicks_test.lua`'s, with `CreateRadio` and `CreateDivider` added.

  The cases (name: assertions):
  - `the panel shows with the Talents tab and hides while inspecting` (Review Focus 3): after `PSF.open(); stub.run_timers()`, `TP.panel:IsShown()`. After `PlayerSpellsFrame:SetInspecting('target'); stub.run_timers()`, it is hidden. After `ClearInspectUnit()` it shows again. After hiding `TalentsFrame` it is hidden.
  - `the addon already loaded at enable`: in a fresh world, `PSF.build(); PSF.load()` runs before `TP:Enable()`, and the panel still builds on open. Then `eq(#take_errors(), 0)`.
  - `Side picks the roomier side`: `eq(TP.Layout.Side(300, 1518, 1920, 250), 'RIGHT')`, `eq(TP.Layout.Side(1000, 1900, 1920, 250), 'LEFT')`, `eq(TP.Layout.Side(100, 1820, 1920, 250), 'RIGHT', 'a tie')`.
  - `it docks to the left after a drop at the right edge`: move `PlayerSpellsFrame` so its right edge is at 1900, `stub.fire_script(PlayerSpellsFrame, 'OnMouseUp')` and `stub.run_timers()`. Then `T.anchor(TP.panel, {...})` names `TOPRIGHT PlayerSpellsFrame TOPLEFT -2,0`.
  - `rows show the plan's states`: a plan of the guide's first 20 steps, with ranks Thundering Strikes 5, Mental Dexterity 3, Ancestral Knowledge 2, Shamanistic Focus 1 and Elemental Weapons 1 (12 learned), at level 27. Check: the count text is `'12/20'`; row 13 has `st:GetState(frame, 'selected')`; row 1's check is shown; and row 14 (Elemental Weapons, rank 3) reads `'R3'`.
  - `missing steps read as missing and can be deleted` (Review Focus 1): put node 999 in the plan. Its row text is `'Missing talent'`, and its menu's `'Remove step'` removes it from `plan.steps`.
  - `off-plan line`: one rank in a node the plan never takes reads `'1 point off plan'`, and two read `'2 points off plan'`.
  - `empty state and New plan`: with no plan, the empty text shows exactly as written above. The select menu's `'New plan'` makes `S.Active(1).name == 'New plan'`.
  - `collapse keeps the waiting step in the strip, per character`: With the plan and ranks of `rows show the plan's states`, `TP:SetCollapsed(true)` makes the strip text `'22 Elemental Weapons R2'`. `S.Char().collapsed` is true. Hide and show: still collapsed.
  - `StepLabel and StripText` (pure): a one-rank node has no `R`, and an all-learned view gives `'Plan complete'`.
  - `ScrollOffset`: `eq(TP.Layout.ScrollOffset(30, 20, 600, 1020), 380)`, `eq(TP.Layout.ScrollOffset(1, 20, 600, 1020), 0)`, `eq(TP.Layout.ScrollOffset(51, 20, 600, 1020), 420)`.
  - `nothing is written onto Blizzard's frames, and nothing is bought`: the lock gives no errors (`eq(#take_errors(), 0)`) across the cases above, and `eq(#stub.traits.calls, 0)`.

- [ ] **Step 3: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_panel_test.lua`. Expected: FAIL (`panel.lua` missing).

- [ ] **Step 4: Implement `panel.lua` and the wiring in `talentplan.lua`** as above.
  - `TP:OnColorsChanged(group, key)` recolors the muted, danger and accent texts and the selection line.
  - Add any widget method the stubs lack to `tests/wow/widgets.lua` (stub rule 2).

- [ ] **Step 5: Run them to verify they pass.** Run the same command, then `tests/run`. Expected: PASS. That includes the states, SetFont and theme scans over the new file.

- [ ] **Step 6: Commit.**

```bash
git add SaftUI-Misc/TalentPlan/panel.lua SaftUI-Misc/TalentPlan/talentplan.lua SaftUI-Misc/TalentPlan/load.xml tests/misc/fixtures/player_spells_frame.lua tests/misc/talentplan_panel_test.lua
git commit -m "misc: dock the leveling plan panel to the talent window"
```

Plus any `tests/wow/widgets.lua` change.

---

### Task 6: The import dialog

**Files:**
- Create: `SaftUI-Misc/TalentPlan/import.lua` (add it to `load.xml`)
- Modify: `SaftUI-Misc/TalentPlan/panel.lua`: the Import buttons call `TP:OpenImport()`
- Test: `tests/misc/talentplan_import_test.lua`

**Interfaces:**
- Consumes: `TP.Parse`, `TP.ImportSummary` (Task 3), `S.New`, `S.Active` (Task 2), `TP.view.tree.names` (Task 5), `st:CreateEditBox(name, parent, true)`, `st:CreateScrollFrame`, `st:CreateRadioGroup`, `st:CreateButton`.
- Produces:
  - `TP:ApplyImport(result, mode, name, group) -> plan`. `mode` is `'replace'` or `'new'`. Replace sets the active plan's steps and clears its phases; with no active plan it acts as `'new'`. New is `S.New(name ~= '' and name or 'Imported', group)` with the steps set. Both end in `TP:QueueRefresh()`.
  - `TP:OpenImport()`, `TP:CloseImport()`, `TP.importFrame`.

The dialog (the spec's Import section):
- It is a SaftUI frame on UIParent, `DIALOG` strata, 420 by 460, drawn with `st:SetTemplate(frame, 'theme', 'options', 'panel')` and centered on the panel's window.
- From top to bottom:
  - the title `'Import a talent order'`;
  - a multi-line edit box in a scroll frame, with the empty-text hint `"Paste a guide's talent order"` (a muted font string shown while the box is empty);
  - the radio group `'Replace this plan'` and `'New plan'`, with `'New plan'` chosen when there is no active plan, and a name box beside it, default `'Imported'`;
  - the summary: `TP.ImportSummary(result, 3)`, joined by `\n`, worked out again on every `OnTextChanged`;
  - the `'Import'` and `'Cancel'` buttons. Import is disabled while the result has 0 steps.
- Esc and Cancel close it. Import applies the result and closes. It closes when the talent window hides.

- [ ] **Step 1: Write the failing tests.** Same world as Task 5.
  - `replace keeps the plan and clears phases`: `eq(plan.id, before.id)`, `eq(#plan.steps, 51)` and `eq(#plan.phases, 0)`.
  - `new makes a named, active plan`: `TP:ApplyImport(r, 'new', '', 1).name == 'Imported'`, and a second one is `'Imported 2'`.
  - `replace with no plan makes one`: the same as new.
  - `the summary text the dialog shows`: run `TP:OpenImport()`, then set the box's text to the guide through `SetText` and `stub.fire_script(box, 'OnTextChanged', true)`. The summary font string's first line is `'51 steps, levels 10 to 60.'`, and Import is enabled. With an empty text, Import is disabled. This needs `SetMultiLine` and whatever the edit box stub lacks in `tests/wow/widgets.lua`; add them faithfully (stub rule 3).

- [ ] **Step 2: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_import_test.lua`. Expected: FAIL.

- [ ] **Step 3: Implement `import.lua`.**

- [ ] **Step 4: Run them to verify they pass.** Run the same command, then `tests/run`. Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add SaftUI-Misc/TalentPlan/import.lua SaftUI-Misc/TalentPlan/panel.lua SaftUI-Misc/TalentPlan/load.xml tests/misc/talentplan_import_test.lua
git commit -m "misc: import a pasted talent order into a plan"
```

Plus any `tests/wow/widgets.lua` change.

---

### Task 7: Tree overlays and planning mode

**Files:**
- Create: `SaftUI-Misc/TalentPlan/overlays.lua` (add it to `load.xml`)
- Modify: `SaftUI-Misc/TalentPlan/talentplan.lua`: `Refresh` calls `TP:DrawOverlays(view)`; hiding sets planning off
- Modify: `SaftUI-Misc/TalentPlan/panel.lua`: row `OnEnter`/`OnLeave` call `TP:Light(nodeID)` and `TP:Light(nil)`; the Plan button calls `TP:SetPlanning(not TP.planning)` and wears `st:SetButtonPressed(button, TP.planning)`; the planning line
- Test: `tests/misc/talentplan_overlays_test.lua`

**Interfaces:**
- Consumes: `TP.view` (Task 5), `M.AddStep`, `M.RemoveLastOf`, `M.PlannedRanks`, `M.StepsOf` (Task 2), `TP.selected` (Task 5).
- Produces:
  - `TP:DrawOverlays(view)`. It maps `nodeID` to button through `TalentsFrame:EnumerateAllTalentButtons()` and `button:GetNodeID()` on every draw, never cached across `ButtonsUpdated`. It keeps one record per button in a weak table of SaftUI's: `{ light, glow, dim, catcher }`, all children of one layer frame parented to `TalentsFrame`.
  - `TP:Light(nodeID|nil)`
  - `TP:SetPlanning(on)`, `TP.planning`
  - `TP:PlanClick(nodeID, mouse) -> 'added'|'removed'|'maxed'|nil`
  - `TP.CatcherLines(plan, nodeID, node) -> { string, ... }`. The first line is the node's name. Then a line per planned rank, `('Rank %d at level %d'):format(rank, level)`. Last comes `('All %d ranks are planned.'):format(maxRanks)` when maxed, else `'Click: add the next rank. Right-click: remove the last one.'`.

What each overlay is. All of them have `SetAllPoints(button)` and are mouse-disabled except the catcher.
- **light**: four 2-line textures in Text > Normal around the node, shown for `TP:Light(nodeID)` only. The level is `button:GetFrameLevel() + 6`.
- **glow**: four 2-line textures in the Accent, shown on the waiting row's node while the panel shows. The level is `+ 5`. Changed 2026-11-22: under the Blizzard theme (the panel's `config.panels.theme`, via `st:IsBlizzardLook`) the glow is instead one ADD-blend texture of `talents-node-circle-greenglow` with a looping 0.36 s Alpha in and out, on the glow frame itself, and the edges are hidden; `TP:PaintOverlays` sets it on every draw and theme change.
- **dim**: a black texture at alpha 0.6 (`SetColorTexture(0, 0, 0, 0.6)`), shown on every node with `PlannedRanks == 0` while the panel shows and `config.dim` is on. The level is `+ 4`. A plan with no steps dims nothing.
- **catcher**: a Button at level `+ 10`, `RegisterForClicks('LeftButtonUp', 'RightButtonUp')`. It is shown and mouse-enabled only while planning; otherwise it is hidden and `EnableMouse(false)`.
  - `OnClick` calls `TP:PlanClick(nodeID, mouse)`.
  - `OnEnter` shows `GameTooltip` owned by the catcher with `TP.CatcherLines`.
- **`PlanClick`.**
  - `LeftButton` adds `M.AddStep(plan, nodeID, TP.selected)`, unless the node is maxed or the click is a no-op. With a selection, the selection moves to the new step, so the next click goes after it.
  - `RightButton` is `M.RemoveLastOf`.
  - With no plan, it first runs `S.New('New plan', group)`.
- Planning turns off on `TalentsFrame`'s `OnHide` and on `PlayerSpellsFrame`'s. Turning it off hides every catcher.

- [ ] **Step 1: Write the failing tests.** Same world as Task 5, with the overlays.
  - `catchers cover their buttons only while planning`: for each fixture button, `rec.catcher:IsShown()` is false and `rec.catcher:IsMouseEnabled()` is false. After `TP:SetPlanning(true)`, each catcher is shown and mouse-enabled, its `GetFrameLevel()` is `button:GetFrameLevel() + 10`, and its `GetRect()` equals the button's. The light, glow and dim are never mouse-enabled.
  - `a planning click plans and never reaches Blizzard's button`: `stub.click(rec.catcher, 'LeftButton')` on Flurry twice gives a plan with two Flurry steps (ranks 1 and 2). Right-click gives one. Then `eq(PSF.clicks[SH.ID.Flurry], nil)` and `eq(#stub.traits.calls, 0)`.
  - `a click goes after the selected row`: with `TP.selected = 1` and two clicks, the steps are `{ a, x, y, b... }`.
  - `a maxed node does nothing and says so`: Shamanistic Focus clicked twice gives one step, and the second click returns `'maxed'`. `TP.CatcherLines(...)` ends with `'All 1 ranks are planned.'`.
  - `glow on the waiting node, dim on unplanned ones, light on hover`: glow is shown only on the waiting step's button. Dim is shown on the decoys and not on a planned node, and with `config.dim = false` no dim shows. `stub.fire_script(row.frame, 'OnEnter')` shows that row node's light, and `OnLeave` hides it.
  - `overlays follow a re-bound button`: run `PSF.rebind(btnA, SH.ID.Flurry)`, `PSF.rebind(btnB, oldA)`, `PSF.redraw()` and `stub.run_timers()`. The glow and dim follow the node IDs, not the buttons. A missing step's node has no overlay (Review Focus 1).
  - `planning turns off when the window hides`: after `TalentsFrame:Hide()`, `TP.planning` is false and every catcher is hidden.

- [ ] **Step 2: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_overlays_test.lua`. Expected: FAIL.

- [ ] **Step 3: Implement `overlays.lua` and the panel wiring.**

- [ ] **Step 4: Run them to verify they pass.** Run the same command, then `tests/run`. Expected: PASS.

- [ ] **Step 5: Commit.**

```bash
git add SaftUI-Misc/TalentPlan/overlays.lua SaftUI-Misc/TalentPlan/talentplan.lua SaftUI-Misc/TalentPlan/panel.lua SaftUI-Misc/TalentPlan/load.xml tests/misc/talentplan_overlays_test.lua
git commit -m "misc: light, glow and dim talent plan nodes, and plan by clicking"
```

---

### Task 8: Drag reorder and phases

**Files:**
- Modify: `SaftUI-Misc/TalentPlan/model.lua`: the entries, moves and phases
- Create: `SaftUI-Misc/TalentPlan/drag.lua` (add it to `load.xml` before `panel.lua`)
- Modify: `SaftUI-Misc/TalentPlan/panel.lua`: the phase headers, the Phases button, the drag
- Test: `tests/misc/talentplan_model_test.lua` (append), `tests/misc/talentplan_phases_test.lua`

**Interfaces:**
- Produces, in `model.lua`:
  - `M.Entries(plan) -> { { kind = 'phase', phase = k } | { kind = 'step', index = i }, ... }`. In display order, the phases with `at == i` come before step i (in `plan.phases` order), and the phases with `at > #steps` come at the end.
  - `M.MoveEntry(plan, from, to)`. `from` and `to` are entry positions, and `to` is where the entry ends up. It rebuilds `plan.steps` and `plan.phases` from the moved list, giving each phase `at` = the index of the next step after it, and keeps the phases in display order. With `from == to` nothing changes.
  - `M.AddPhase(plan, at, name, color) -> k`, `M.RemovePhase(plan, k)`, `M.NextColor(plan)` (the first of `PHASE_COLORS` not in use, else `PHASE_COLORS[(#phases % 5) + 1]`), `M.PhaseOf(plan, index) -> k|nil` (the last phase in display order whose `at <= index`) and `M.PhaseRange(plan, k) -> firstLevel, lastLevel|nil`.
- Produces, in `drag.lua`: `TP.DragParts`, the shape of `SaftUI-Bags/dragparts.lua`, copied (the spec leaves this to the builder; Misc can't depend on Bags):
  - `Handle(parent, height)`, `InView(frame)`, `UnderCursor(rows) -> i, lower`, `ShowGhost(w, label, height)`, `PlaceGhost(ghost)`, `StopDrag(w)`, `HANDLE_WIDTH = 10`;
  - its fonts from `st:CreateFontString(parent, 'normal')` instead of the options window's.
  - Add a followup in Task 9 to move both copies to Core.
- Panel behavior:
  - A phase header row: a 8 by 8 dot in the phase's color, the name, and on the right `('%d-%d'):format(first, last)` muted. It shows `''` while the phase is empty.
  - The level numbers of a phase's rows are tinted in its color. Rows before the first phase keep Text > Normal.
  - Right-click on a header opens a menu: `'Rename'` (`Prompt('Name the phase', name, ...)`), `'Color'` (a submenu with a radio per color, the names capitalised), and `'Remove phase'`.
  - The `'Phases'` button adds a phase at the selected row (`at = TP.selected`), or at step 1 with no selection. It asks `Prompt('Name the phase', ('Phase %d'):format(#phases + 1), ...)` and takes the color from `M.NextColor`.
  - Every row and header has a `Handle` at its left. Dragging works as in the bags: the ghost, the Accent insert line, and on release `M.MoveEntry` then `TP:QueueRefresh()`. A release outside the list, where `UnderCursor` gives nil, changes nothing.

- [ ] **Step 1: Write the failing model tests**, appended to `talentplan_model_test.lua`:

```lua
test('Entries put phases before their first step and empty ones last', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3 }
	plan.phases = { { at = 1, name = 'A', color = 'blue' }, { at = 3, name = 'B', color = 'red' }, { at = 4, name = 'C', color = 'green' } }
	local e = M.Entries(plan)
	eq(#e, 6); eq(e[1].kind, 'phase'); eq(e[2].index, 1); eq(e[4].phase, 2); eq(e[6].phase, 3)
end)

test('moving a rank 2 above its rank 1 renumbers; moving a header regroups', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 7, 8, 7 }
	plan.phases = { { at = 2, name = 'B', color = 'blue' } }
	-- entries: step1(7) | phase B | step2(8) | step3(7)
	M.MoveEntry(plan, 4, 1)
	eq(plan.steps[1], 7); eq(M.Ranks(plan.steps)[1], 1); eq(M.Ranks(plan.steps)[2], 2)
	eq(plan.phases[1].at, 3, 'the header stays before 8')
	M.MoveEntry(plan, 3, 1) -- the header to the top
	eq(plan.phases[1].at, 1); eq(M.PhaseOf(plan, 3), 1)
	local before = table.concat(plan.steps, ','); M.MoveEntry(plan, 2, 2); eq(table.concat(plan.steps, ','), before)
end)

test('phases: add, colors, range, remove', function()
	local plan = M.NewPlan(1, 'p'); plan.steps = { 1, 2, 3, 4 }
	eq(M.NextColor(plan), 'blue'); M.AddPhase(plan, 1, 'A', 'blue'); eq(M.NextColor(plan), 'orange')
	M.AddPhase(plan, 3, 'B', 'orange')
	local a, b = M.PhaseRange(plan, 1); eq(a, 10); eq(b, 11)
	M.RemovePhase(plan, 1); eq(#plan.phases, 1); eq(M.PhaseOf(plan, 1), nil)
end)
```

- [ ] **Step 2: Write the failing panel tests in `tests/misc/talentplan_phases_test.lua`.** Task 5's world, with `W.Prompt` answered by `W.PromptBox():SetText(...)` and then the accept, as `tests/core/options_dialog_test.lua` does.
  - `the Phases button adds a named, colored header at the selection`: with `TP.selected = 3`, click Phases and answer `'Core'`. On a 20-step plan, the plan's phase is `{ at = 3, name = 'Core', color = 'blue' }`, and the header row reads `'Core'` with the range `'12-29'`.
  - `a phase's rows wear its color on the level`: the level font string's color equals `M.PHASE_RGB.blue`, and a row before the phase is Text > Normal.
  - `the header menu renames, recolors and removes`.
  - `a drag release with nothing under the cursor changes nothing`: set `w.drag`, put the cursor outside, and run the release handler. `plan.steps` is unchanged.

- [ ] **Step 3: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_model_test.lua tests/misc/talentplan_phases_test.lua`. Expected: FAIL.

- [ ] **Step 4: Implement the model functions, `drag.lua` and the panel's headers, menus and drag.**

- [ ] **Step 5: Run them to verify they pass.** Run the same command, then `tests/run`. Expected: PASS.

- [ ] **Step 6: Commit.**

```bash
git add SaftUI-Misc/TalentPlan/model.lua SaftUI-Misc/TalentPlan/drag.lua SaftUI-Misc/TalentPlan/panel.lua SaftUI-Misc/TalentPlan/load.xml tests/misc/talentplan_model_test.lua tests/misc/talentplan_phases_test.lua
git commit -m "misc: drag talent plan rows and group them into phases"
```

---

### Task 9: The `/sui` page, docs and the in-game checklist

**Files:**
- Create: `SaftUI-Misc/TalentPlan/options.lua` (add it to `load.xml`)
- Modify: `tests/core/reset_coverage_test.lua`: add `['SaftUI-Misc/TalentPlan/options.lua'] = { page = 'TalentPlan', test = 'misc/talentplan_options_test.lua' }` to `PAGES`
- Test: `tests/misc/talentplan_options_test.lua`
- Modify (docs):
  - `AGENTS.md`: the SaftUI-Misc row gains the talent plan (`TalentPlan/`, its files and what each does) and the movable talent window.
  - `.agents/architecture.md`: the module list gains `TalentPlan`. "Config, defaults and profiles" names `talentplan` in `global` (plans by class and id, `nextID`) and in `char` (`active`, `collapsed`).
  - `.agents/taint.md`: a new rule 23, "The talent plan" (`SaftUI-Misc/TalentPlan/`). It states the hooks and getters allowed, the catchers' rule, the never-called list and the tests that pin them.
  - `.agents/edit-mode.md`: Info's page list gains Talent plan.
  - `.agents/testing.md`: `tests/wow/traits.lua` and the two fixtures, and the new test files in Misc's list.
  - `README.md`: one line for the feature, if it lists features (run `readme-freshness-check`).
  - `docs/followups.md`: the entries below, with the ToC updated.

**Interfaces:**
- Consumes: `st.Config.generators.toggle`, `st.Config.SavedIn('talentplan')`, `R.check_page` (`tests/lib/reset_walk.lua`).
- Produces: `TP:GetConfigTable()`, which returns nil unless `st.forever`:

```lua
{ name = 'Talent plan', type = 'group', category = 'Info', childGroups = 'tab', args = {
	general = { name = 'General', type = 'group', order = 1, saved = st.Config.SavedIn('talentplan'),
		get = function(info) return self.config[info[#info]] end,
		set = function(info, value) self.config[info[#info]] = value; self:UpdateConfig() end,
		args = { enable = <toggle 1 'Enable'>, dim = <toggle 2 'Dim talents not in the plan'> } } } }
```

  The copy for the two descs:
  - Enable: `"Shows your leveling plan beside Blizzard's talent window: the order to take talents in, which ones you have, and the next one. Off, the talent window is Blizzard's alone."`
  - Dim: `"Darkens the talents in the tree that your plan never takes, while the plan shows."`
  - `TP:UpdateConfig()` runs `TP:QueueRefresh()`. With `enable` off, the next refresh hides the panel and every overlay and turns planning off.

The page goes under **Info**. The spec says "under Misc", but the sidebar's groups are only Frames, Combat and Info (`optionslayout.lua`'s `CATEGORIES`), and the other Misc frame additions, such as Durability, sit under Info.

- [ ] **Step 1: Write the failing tests.**
  - `the page reads and writes its keys and resets`: run `R.check_page({ TalentPlan = TP:GetConfigTable() }, 'TalentPlan')`. Setting `dim` to false through the group's `set` gives `profile.talentplan.dim == false`, and one refresh queued.
  - `Enable off hides the panel and overlays`.
  - `no page on retail`: after `use_client('retail')` and loading the files, `eq(TP:GetConfigTable(), nil)`.

- [ ] **Step 2: Run them to verify they fail.** Run `tests/run tests/misc/talentplan_options_test.lua tests/core/reset_coverage_test.lua`. Expected: FAIL.

- [ ] **Step 3: Implement `options.lua`.**

- [ ] **Step 4: Run them to verify they pass.** Run the same command, then `tests/run` and `tests/run --scales=all tests/misc`. Expected: PASS.

- [ ] **Step 5: Commit the code.**

```bash
git add SaftUI-Misc/TalentPlan/options.lua SaftUI-Misc/TalentPlan/load.xml tests/core/reset_coverage_test.lua tests/misc/talentplan_options_test.lua
git commit -m "misc: add the talent plan's settings page"
```

- [ ] **Step 6: Write the docs and followups. Run the `agents-doc-parity-check` and `readme-freshness-check` skills and act on what they find.** The followups:
  - **Remember the talent window's spot.** Today it goes back to Blizzard's spot on every open (spec, "A movable talent window").
  - **Check a whole plan against the tree.** Point gates and prerequisites, offline (spec non-goal).
  - **Choice nodes and hero talents in a plan.** Skipped by `D.Read` today.
  - **Move the drag parts to Core.** `SaftUI-Bags/dragparts.lua` and `SaftUI-Misc/TalentPlan/drag.lua` are two copies of one shape.
  - **Experiment E1: which node field is the committed rank.** If `activeRank` is the committed rank, replace the snapshot rule in `D.CommittedRank` with it.
  - **`C_Traits.GetNodeInfo` of a node not in the tree.** The stub returns nil; it is unverified.

- [ ] **Step 7: Write the in-game checklist** at the end of this plan file, under the heading below. Then commit:

```bash
git add AGENTS.md .agents/architecture.md .agents/taint.md .agents/edit-mode.md .agents/testing.md README.md docs/followups.md docs/superpowers/plans/2026-11-22-saftui-talent-plan.md
git commit -m "docs: the talent plan in the agent docs, followups and checklist"
```

Leave out `README.md` if the freshness check left it unchanged.

## In-game checklist (for the owner, Forever)

1. Open the talent window: the panel docks on the right, in the theme, as tall as the window. Switch to the Spellbook: the panel goes. Inspect a player: the panel goes.
2. Drag the window to the right edge and drop it: the panel moves to the left. Close the window and open it again: the window is back in Blizzard's spot.
3. Import the shaman guide: "51 steps, levels 10 to 60." and nothing unmatched. If a name doesn't match, note it: Forever's name differs from the guide's.
4. Planning mode: click and right-click nodes. Steps are added and removed, and no rank is ever bought, even with unspent points.
5. Level up and learn the waiting talent, but don't Apply yet: the row says pending. Apply: it is checked, and the next row waits and glows.
6. **E1**: with `/dump C_Traits.GetNodeInfo(C_ClassTalents.GetActiveConfigID(), <a node ID>)`, compare `activeRank`, `currentRank` and `ranksPurchased` before and after staging a rank, and tell the builder.
7. Collapse the panel: the strip shows the waiting step. `/reload`: still collapsed.
8. Drag a rank 2 above its rank 1: the R numbers swap. Add a phase, rename it, recolor it and drag it.
9. Set Dim talents not in the plan off: the dim goes at once. Set Enable off: the panel and every overlay go.
10. Compact talent window: the gaps at the window's sides and between the three specs equal the gap between talents.
11. The headers are centred over their trees.
12. Switch to the Spellbook tab: it keeps Blizzard's width.
13. Turn off Compact talent window (`/sui` > Talent plan > General) and `/reload`: Blizzard's layout is back.
14. The import dialog: Esc closes it, and keybinds still work while it is open.
15. Compact window: the arrows (straight and diagonal) still join their nodes.
16. Compact window: learning a talent, Apply and switching spec tabs keep the layout.
17. Compact window: the art looks right at the narrower width.
18. Compact window: dragging the window works, and the talent plan panel docks beside the narrower window.
19. Click the panel's empty space (between and below the rows): it doesn't clear your target. Collapse the panel while planning: planning ends and the tree's talents take clicks again.
20. `/console taintLog 1`, use all of the above, learn a talent, `/reload`: nothing in `Logs/taint.log` blames SaftUI for `Blizzard_PlayerSpells` or `Blizzard_SharedTalentUI`.
21. The waiting talent's highlight: under the Blizzard theme it is a pulsing green glow (`talents-node-circle-greenglow`, added light) with no border; under Thick and Thin it is the 2 line Accent border. Switch the theme in `/sui` with the talent window open: the highlight changes at once. Look at a square (active) talent too: the glow is the circle art, so say if it looks wrong there.

## Execution

Plan complete. Recommended: **subagent-driven**. The tasks build on each other's interfaces (`TP.view`, the store and the model), Tasks 5 and 7 touch Blizzard's frames where a shipped taint bug is the costliest mistake, and each task's reviewer should check taint against the forever source as `.agents/workflow.md` asks.

---

### Task 10: A compact talent window

Added 2026-11-22 at the owner's request: "there's so much empty space currently on the frame, can we reduce it a bit so that the spacing between the talents and the edges separating the specs (and the side of the window) is the same as the spacing between talents?" Spec: "A compact talent window" (Revised note). Independent of Tasks 5 to 9; built in parallel on branch `tp-compact`.

How Blizzard lays the window out on Forever (forever source, 2026-11-22; paths under `Interface/AddOns/`):
- Each button: `ClassTalentsFrameMixin:UpdateTalentButtonPosition(button)` (`Blizzard_PlayerSpells/ClassTalents/Blizzard_ClassTalentsFrame.lua:712-728`) does `ClearAllPoints`, `SetPoint('CENTER', ButtonsParent, 'TOPLEFT')` and `TalentButtonUtil.ApplyPosition` (`Blizzard_SharedTalentUI/Blizzard_SharedTalentUtil.lua:501-516`): x = posX/10 − panOffsetX, y = −posY/10 + panOffsetY. Zoom is fixed at 1. Every path (pool acquire in `InstantiateTalentButton`, `UpdateAllTalentButtonPositions`, tab switch, commit reload) ends in that method.
- Edges and arrows are anchored to button centers, so they follow a sideways move. Gates anchor RIGHT to the button's LEFT.
- Tree headers: `ClassTalentsFrameMixin:RefreshTreeHeaders` (`Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua:79-109`) anchors `treeHeaders[i]` CENTER on `BackgroundBorder` TOPLEFT at x = 140 + (i−1)·400, y = −100, on every `UpdateTreeCurrencyInfo`.
- Art is XML only (`Camelot/ClassTalents/Blizzard_ClassTalentsFrame.xml` ~295-341): `Background`, `ClassBackground`, `BackgroundBorder`, horizontal dividers, and `DividerVerticalLeft` / `DividerVerticalRight` at the horizontal dividers' CENTER ±95, y −60 (read the XML for exact names and anchors).
- Size: `talentsWidth` 1218 (`Camelot/Blizzard_PlayerSpellsFrame.xml:9-10`), applied by `PlayerSpellsFrameMixin:UpdateSize` (`Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua:433-443`) from `TalentsFrame:OnShow`; `TalentsFrame` is 1212×681 in XML.
- Purchase and commit (`C_Traits.PurchaseRank`, `CommitConfig`) are not protected (`AllowedWhenUntainted` arguments only). Nothing in the window is secure.

**Files:**
- Create: `SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsLayout.lua` (add it to `SaftUI-Misc/Skinning/load.xml` after `Blizzard_WorldMap.lua`)
- Modify: `SaftUI-Misc/config.lua`: append `st.defaults.talentwindow = { compact = true }` with a comment
- Test: `tests/misc/talent_window_layout_test.lua`

**Interfaces:**
- Produces: `TW.Layout(trees, size)` (pure; `TW` is the module `st:GetModule('TalentWindow')`): `trees` is a list, left to right, of lists of button center x offsets (Blizzard's, relative to ButtonsParent TOPLEFT); `size` the button width. Returns `{ gap, pitch, cols, region, dx = { [i] = number }, dividers = { x1, x2, ... }, width }`, where `pitch` is the smallest distinct x step over all trees (equal within 1px), `gap = pitch − size`, `cols` the largest column count of any tree, a tree's region `= cols·size + (cols−1)·gap + 2·gap`, tree i's leftmost button center lands at `(i−1)·region + gap + size/2`, the dividers sit at region boundaries, and `width = #trees · region`. Returns nil when there are no buttons or fewer than two distinct x values.
- Produces: `TW:Apply()`: reads the buttons (`TalentsFrame:EnumerateAllTalentButtons()`, each one's tree from `button:GetNodeInfo().groupIDs[1]` read only, ordered by the headers' order or by mean x), runs `TW.Layout`, then re-anchors with the plain C methods only.
- A setting `st.config.profile.talentwindow.compact` (default true). Off: nothing is moved (a `/reload` puts Blizzard's layout back; say so in a comment). Task 9's page gets a check box for it ("Compact talent window").

- [ ] **Step 1: Write the failing test** `tests/misc/talent_window_layout_test.lua`: three trees of 4 columns at Blizzard-like positions (pitch 60, size 40, trees starting at x 70, 470, 870) give `gap = 20`, `cols = 4`, region `= 4·40 + 3·20 + 2·20 = 260`, `dx[1] = (0 + 20 + 20) − 70 = −30`, `dx[2] = (260 + 40) − 470 = −170`, `dx[3] = (520 + 40) − 870 = −310`, dividers `{ 260, 520 }`, width 780; a tree with only 2 columns used still gets the same region (cols is the max); nil for no buttons. Plus a frame test on stubs: after `TW:Apply()` each fake button's CENTER x moved by its tree's dx, `PlayerSpellsFrame`'s width is the compact one, and with `compact = false` nothing moves.
- [ ] **Step 2: Run it** — `tests/run tests/misc/talent_window_layout_test.lua`: FAIL (module missing).
- [ ] **Step 3: Implement** the module with `st:OnBlizzardAddon('Blizzard_PlayerSpells', ...)` and post-hooks only (`.agents/taint.md` rules 1 to 3): `hooksecurefunc(TalentsFrame, 'UpdateTalentButtonPosition', ...)` adds the button's tree dx to the anchor Blizzard just set (read it with `GetPoint`, set it again with the plain `SetPoint`); `hooksecurefunc(TalentsFrame, 'RefreshTreeHeaders', ...)` centers each header over its region; the vertical dividers move to the region boundaries; a post-hook on `PlayerSpellsFrame:UpdateSize` sets the frame's width to Blizzard's width minus (Blizzard's tree area width − `width`), and `TalentsFrame`'s width the same way. The layout is worked out once per tree load from Blizzard's own positions (before the shift), never from shifted ones. Never write a Lua field onto a Blizzard frame or table; keep per-button state in a weak table of SaftUI's. Never call `GetAndCacheNodeInfo`.
- [ ] **Step 4: Run the test**: PASS; then `tests/run -j4`.
- [ ] **Step 5: Commit** `misc: a compact talent window`.

In-game checks (Task 9's list): T1 the gaps between talents, dividers and window sides look equal on each spec tab; T2 arrows (straight and diagonal) still join their talents; T3 learning, Apply and switching spec tabs keep the layout; T4 the art reads fine at the narrower width; T5 dragging the window still works, and the talent plan panel docks beside the narrower window; T6 `/console taintLog 1` then using the window: no SaftUI blame.
