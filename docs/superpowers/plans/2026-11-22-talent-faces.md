# Talent Faces and Planning Simulation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Talent buttons wear a SaftUI face (icon in SaftUI's border, state colors, Blizzard's dimming), and planning mode shows the plan's tree instead of the real one: planned ranks top-left, real ranks faded, the planned total in the window's top-left, the tree's gates and prerequisites enforced on planning clicks, and each node's look following its simulated state.

**Architecture:**
- **Pure:** `SaftUI-Misc/TalentPlan/simulate.lua` (`TP.Sim`): from the tree's shape and the plan's steps, the simulated ranks, spent points per tree, each step's legality and each node's state.
- **Frames:** `SaftUI-Misc/Skinning/blizzard/Blizzard_TalentFaces.lua` (module `TalentFaces`, `TF`): one face per talent button, SaftUI look when `PS:IsActive()`, Blizzard art in planning under the Blizzard look; a plan source seam, `TF:SetPlanSource(fn)`.
- **Wiring:** `data.lua` reads the shape; `TP:Refresh` runs the simulation and feeds the faces; `TP:PlanClick` asks the simulation first.

**Tech Stack:** Lua 5.1 on WoW Forever (16001); `C_Traits`; SaftUI's theme engine (`st:SetTemplate`, `st:SetBorderColor`, `st:AddStates`/`st:SetState`, `st:IconTexCoords`, `st:FontObject`); `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-22-talent-faces-design.md`. Blizzard names checked on 2026-11-22 against Gethe/wow-ui-source at `734f065` (forever): `Blizzard_SharedTalentUI/Blizzard_TalentButtonArt.lua` and `.xml`, `Blizzard_TalentButtonBase.lua`, `Blizzard_TalentDisplay.lua`, `Blizzard_SharedTalentUtil.lua`, `Blizzard_SharedTalentFrame.lua`, `Blizzard_PlayerSpells/ClassTalents/Blizzard_ClassTalentButtonTemplates.lua` and `.xml`, `Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua`, `Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua` and `TraitConstantsDocumentation.lua`.

## How the tasks are cut

| # | Task | Needs | Files it owns |
| --- | --- | --- | --- |
| 1 | The simulation model | — | `TalentPlan/simulate.lua`, `TalentPlan/load.xml`, `tests/misc/talentplan_simulate_test.lua` |
| 2 | The node faces | — | `Skinning/blizzard/Blizzard_TalentFaces.lua`, `Skinning/load.xml`, `tests/misc/fixtures/player_spells_frame.lua`, `tests/misc/talent_faces_test.lua` |
| 3 | Integration, the shape reader, docs | 1, 2 | `TalentPlan/data.lua`, `talentplan.lua`, `overlays.lua`, `panel.lua`, `tests/wow/traits.lua`, `tests/misc/fixtures/talentplan_shaman.lua`, the plan tests, `.agents/*`, `AGENTS.md`, `docs/followups.md` |

Tasks 1 and 2 share no file and run in parallel. Task 3 runs after both.

## Global Constraints

- **Client.** Forever only. `TF:OnEnable` returns before hooking anything unless `st.forever` (a retail test pins it). `TP.Sim` is pure and loads on both, unused on retail.
- **Libraries and Blizzard source.** Nothing under `Libraries/` changes.
- **Taint (`.agents/taint.md` rules 1 to 3, 6, 23; the spec's "Blizzard reads and writes, exactly").**
  - The only writes to Blizzard: `SetAlpha` on a faced button's `SpendText`, `spendTextShadows[i]`, `Shadow` and `SelectableIcon`, each alpha read first into a weak table and put back when the face goes. Every other Blizzard frame, region and table is read only. The locked fixture fails any other write.
  - Hooks: `hooksecurefunc(button, 'ApplyVisualState' | 'UpdateSpendText', fn)` and `button:HookScript('OnEnter' | 'OnLeave', fn)`, once per button (weak `hooked` table); `TalentsFrame:HookScript('OnShow' | 'OnHide')`; `EventRegistry:RegisterCallback('TalentFrameBase.ButtonsUpdated' | 'TalentFrameBase.ConfigUpdated', fn, TF)`. Each in `xpcall` to `geterrorhandler()`; each only queues a draw (`C_Timer.After(0)`), never draws inside Blizzard's call.
  - Never called: `C_Traits.PurchaseRank`, `RefundRank`, `CommitConfig`, any button `OnClick`, `PurchaseRank`, `SetSelection`, `UpdateVisualState`, `ApplyVisualState`. Every planning test ends with `eq(#stub.traits.calls, 0)`.
  - In combat no face is made (`st:QueueAfterCombat`); existing faces still update.
- **States.** The face's hover is `st:AddStates(face, 'icon', { wire = false, pieces = { hover = ... } })` plus `st:SetState`; the overlay and border colors are meanings, not states. `tests/core/states_scan_test.lua` must pass.
- **Stubs (`.agents/testing.md`).** Strict: a missing widget method goes in `tests/wow/widgets.lua`; trait API stubs in `tests/wow/traits.lua` with the shapes in SharedTraitsDocumentation; Blizzard frames only in the locked fixture.
- **Commits.** `module: imperative summary`, lowercase; stage by explicit path; keep each file's line endings; end with
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsKN5VTQeaHQpvA43E9
  ```
  `tests/run` passes before each commit.

## Review Focus

1. **Gate scope.** Per group when the node has a displayed group, else the tree (spec, open question 1). Test: Task 1 `gates count the node's own tree`, `a tree with no groups gates on the total`; Task 3 `Check` on the fixture.
2. **Order matters.** A rank is legal by the ranks before it, not by the plan's end. A right-click that breaks a later step is refused; a drag that breaks one is allowed and flagged. Tests: Task 1 `CanRemove refuses a rank a later step needs`, `a moved step is flagged, still counted`.
3. **Pooled buttons.** A button re-bound to another node shows the new node's face; a released button shows none; hooks are installed once per button. Test: Task 2 `faces follow a re-bound button`.
4. **Fades come back.** Skin off, Theme to Blizzard, planning off under Blizzard, window hidden: every faded region has its old alpha. Test: Task 2 `fades are put back`.
5. **Nothing written.** The locked fixture plus `stub.traits.calls` empty. Tests: every Task 2 and Task 3 case.

---

### Task 1: The simulation model

**Files:**
- Create: `SaftUI-Misc/TalentPlan/simulate.lua` (in `load.xml` after `model.lua`)
- Test: `tests/misc/talentplan_simulate_test.lua` (loads `talentplan.lua`, `model.lua`, `simulate.lua` only)

**Interfaces (produces):**
- `TP.Sim.EDGE = { REQUIRED = 3, SUFFICIENT = 2 }` (`Enum.TraitEdgeType` values, literal: pure).
- Shape, as the spec: `{ groups = { { id, name, order } }, budget, hideSingle, nodes = { [id] = { maxRanks, cost, group, gates = { { required } }, parents = { { nodeID, type } }, plannable, name } } }`.
- `Sim.Run(shape, steps) -> { ranks, spent = { total, [groupID] }, steps = { [i] = { ok, reason } }, nodes = { [id] = { rank, state, reason } } }`; states `'error' | 'maxed' | 'selectable' | 'partial' | 'gated' | 'locked' | 'disabled'` in that order of priority.
- `Sim.CanAdd(shape, steps, nodeID, after) -> ok, reason`
- `Sim.CanRemove(shape, steps, nodeID) -> ok, reason`
- `Sim.Check(shape, real) -> { { nodeID, field = 'gated'|'locked', game, sim } }`, `real[id] = { rank, isAvailable, meetsEdgeRequirements }`.
- `Sim.ShowCount(shape, nodeID, rank, state) -> boolean` (Blizzard's `GetSpendText` rule: rank > 0 or selectable; false for a 1-rank node when `shape.hideSingle` and rank <= 1).
- Reasons: `('Needs %d points in %s first.'):format(required, groupName or 'the tree')`, `('Needs %s first.'):format(parentName)`, `('All %d ranks are planned.'):format(maxRanks)`, `'No points left at this level.'`, `'Other planned talents need this rank.'`, `'This talent can't be planned.'`.

- [ ] **Step 1: Write the failing tests** on a hand-made shape: three groups A, B, C; A has row 1 (`a1` 5 ranks, `a2` 3 ranks, no gate), row 2 (`a3`, gate 5), row 3 (`a4` gate 10, required parent `a3` at 1 rank); B has `b1` (no gate), `b2` gate 5; an ungrouped shape for the tree scope.
  - `an empty plan: row one selectable, the rest gated`: `Run(shape, {})`: `a1`, `a2`, `b1` `selectable`; `a3`, `b2` `gated`; `a4` `gated` (gate before edge, Blizzard's order).
  - `gates count the node's own tree`: 5 steps of `a1` make `a3` `selectable` and leave `b2` `gated`; `spent.total == 5`, `spent[A] == 5`, `spent[B] == nil or 0`.
  - `a tree with no groups gates on the total`: ungrouped shape, 5 points anywhere open the gate.
  - `required and sufficient edges`: `a4` stays `locked` with the gate met until `a3` is maxed; a node with two sufficient parents opens on either.
  - `cost counts`: a node with `cost = 2` adds 2 to spent.
  - `ranks, maxed and partial`: `a2` x3 is `maxed`; x1 `selectable`; with `budget = 1` and one step, `a2` is `partial` and `b1` `disabled`.
  - `a moved step is flagged, still counted`: steps `{ a3, a1 x5 }`: `steps[1].ok == false`, its reason `'Needs 5 points in A first.'`, `ranks[a3] == 1`, `nodes[a3].state == 'error'`.
  - `CanAdd follows the order`: `CanAdd(shape, {a1 x4}, a3)` is false with the gate reason; with `{a1 x5}` true; `CanAdd(shape, {a1 x5}, a3, 0)` (inserted first) false; a maxed node gives `'All 3 ranks are planned.'`; an unplannable node gives `"This talent can't be planned."`.
  - `CanRemove refuses a rank a later step needs`: `{a1 x5, a3}`: `CanRemove(.., a1)` false, `'Other planned talents need this rank.'`; `{a1 x6, a3}` true (the sixth was after).
  - `Check names the nodes the game disagrees on`: real ranks `a1 = 5`, game `a3.isAvailable = false`: one entry `{ nodeID = a3, field = 'gated', game = false, sim = true }`; agreeing data gives `{}`.
  - `ShowCount`: rank 0 not selectable false; rank 0 selectable true; 1-rank node rank 1 with `hideSingle` false.
- [ ] **Step 2: Run** `tests/run tests/misc/talentplan_simulate_test.lua`. Expected: FAIL (no `TP.Sim`).
- [ ] **Step 3: Implement** `simulate.lua`. One internal `Legal(shape, ranks, spent, nodeID)` used by `Run`, `CanAdd` and the final states, so the three never disagree. No WoW API, no `st:` calls.
- [ ] **Step 4: Run** the file, then `tests/run`. Expected: PASS.
- [ ] **Step 5: Commit** `misc: simulate a talent plan by the tree's gates and prerequisites`.

---

### Task 2: The node faces

**Files:**
- Create: `SaftUI-Misc/Skinning/blizzard/Blizzard_TalentFaces.lua` (in `Skinning/load.xml` after `Blizzard_PlayerSpellsSkin.lua`)
- Modify: `tests/misc/fixtures/player_spells_frame.lua`: `PSF.build` buttons gain Blizzard's art, per `Blizzard_TalentButtonArt.xml`: regions `Icon` (a texture with a fileID), `IconMask` (a MaskTexture, atlas `talents-node-circle-mask`, hidden for squares), `DisabledOverlay`, `StateBorder`, `Shadow`, `SelectableIcon`, `SpendText` and four `spendTextShadows`, rawset fields `visualState` (default 5) and `artSet` (the Square set's atlas names), and methods `ApplyVisualState(state)` and `UpdateSpendText()` that set `visualState`, the border atlas and the text the way Blizzard's do, plus `PSF.set_state(button, state, text)` calling both. Every new region locked. Also `GetNodeInfo()` (`{ type = 0 }`; a test sets 2 for a choice node).
- Test: `tests/misc/talent_faces_test.lua`

**Interfaces (produces):**
- `TF.STATE = { [1] = 'partial', [2] = 'gated', [3] = 'disabled', [4] = 'locked', [5] = 'selectable', [6] = 'maxed', [8] = 'error', [9] = 'error' }` (7, Invisible, hides), read from `TalentButtonUtil.BaseVisualState` when it exists.
- `TF.Paint(state) -> { border = { group, key } | 'accent' | nil, text = { group, key }, overlay = alpha | nil, desaturate, red }` (the spec's table).
- `TF.BlizzardArt(state) -> artSet key` (`selectable`, `normal`, `maxed`, `locked`, `disabled`, `displayError`).
- `TF:SetPlanSource(fn)`: `fn(nodeID) -> { state, planned } | nil`; `TF:Queue()`; `TF:Draw()`; `TF:Look() -> 'saftui' | 'blizzard' | nil` (`'blizzard'` only while a source is set and gives displays); `TF:Hover(nodeID, on)`.
- `TF.faces`: weak by button, `{ face, icon, overlay, rank, planned, mask, art, nodeID }`, for tests.

- [ ] **Step 1: Write the failing tests** (world: the skin's test world from `player_spells_skin_test.lua` plus `PSF.build`, Skinning > Talent window on, Theme Thick):
  - `a face per button, in SaftUI's border`: after `PSF.open()` and `stub.run_timers()`, each button has a shown face with `GetRect()` equal to the button's, level `button:GetFrameLevel() + 2`, not mouse-enabled; its icon's texture is the button's `Icon:GetTexture()`; the face is drawn `action` (theme engine record).
  - `the real state, as Blizzard's button says`: `PSF.set_state(b, 2, '')` gives overlay alpha 0.7 and a desaturated icon; state 5 with `'0'` gives the rank text `'0'` in Text > Success and no overlay; state 6 the Accent border; state 7 hides the face.
  - `Blizzard's numbers are faded, and put back`: under a face `SpendText:GetAlpha() == 0` and each shadow, `Shadow`, `SelectableIcon` too; `DisabledOverlay`, `StateBorderHover`, the button's own alpha untouched. Turning Skinning > Talent window off (or Theme Blizzard) puts every alpha back and hides every face (Review Focus 4).
  - `a hook only queues`: calling the button's `ApplyVisualState(4)` changes nothing until `stub.run_timers()`, then the face is `locked`. Hooks are installed once per button (call `TF:Draw()` twice, a hook counter stays 1).
  - `faces follow a re-bound button`: `PSF.rebind` then `PSF.redraw()`; a choice node (`GetNodeInfo().type == 2`) has no face.
  - `the plan source drives the face`: `TF:SetPlanSource(function(id) return { state = 'gated', planned = 2 } end)` gives the planned text `'2'` at the face's top-left, the real rank at alpha 0.3, overlay 0.7; returning nil for a node shows its real state.
  - `Blizzard art face while planning only`: Theme Blizzard and no source: no face. With a source: a face whose border texture has the atlas `artSet.selectable` for `'selectable'`, anchored to `StateBorder`, whose icon mask (when `IconMask:IsShown()`) has the button's mask atlas; clearing the source hides them and puts the fades back.
  - `hover`: `stub.fire_script(button, 'OnEnter')` sets the face's hover state, `OnLeave` clears it; `TF:Hover(nodeID, true)` does the same.
  - `no face made in combat`: `InCombatLockdown` true, a new button: no face until `PLAYER_REGEN_ENABLED`; an existing face still updates.
  - `nothing on retail`: `st.forever = false`, enable: no hooks (the fixture's hook counters 0).
- [ ] **Step 2: Run** `tests/run tests/misc/talent_faces_test.lua`. Expected: FAIL.
- [ ] **Step 3: Implement** `Blizzard_TalentFaces.lua`: the header comment states the taint contract (the spec's reads, writes and hooks); `OnEnable` waits for `Blizzard_PlayerSpells` (`st:OnBlizzardAddon`); the layer is a frame of SaftUI's on `TalentsFrame`; `TF:Draw` rebuilds the button map each pass; colors follow `st:FollowColor`/`OnColorsChanged` and fonts `OnFontsChanged` as the skin does; `PS:UpdateConfig` (or the skin's look change) calls `TF:Queue()`.
- [ ] **Step 4: Run** the file, `tests/run tests/core/states_scan_test.lua tests/misc`, then `tests/run`. Expected: PASS.
- [ ] **Step 5: Commit** `misc: draw talent buttons as SaftUI faces`.

---

### Task 3: Integration, the shape reader, docs

**Files:**
- Modify: `tests/wow/traits.lua`: `C_Traits.GetTreeInfo(configID, treeID)` (from `stub.traits.tree_info[treeID]`, `{ ID, gates = {}, hideSingleRankNumbers = false }` by default), `GetGroupDisplayInfoByTreeID(treeID)` (`stub.traits.groups[treeID]` or `{}`), `GetNodeCost(configID, nodeID)` (`stub.traits.costs[nodeID]` or `{}`), `GetTreeCurrencyInfo(configID, treeID, excludeStaged)` (`stub.traits.currency` or `{}`); argument checks as the others. Update its header's source list.
- Modify: `tests/misc/fixtures/talentplan_shaman.lua`: `opts.shape = true` gives the 23 nodes three groups (Elemental, Enhancement, Restoration), `posY` rows, a gate condition of 5 per row in each group (`isGate = true`, `spentAmountRequired`), and two prerequisite edges (fixture data, type 3: `Stormstrike` requires `Spirit Weapons`, `Improved Stormstrike` requires `Stormstrike`), and the choice node 130 as the parent of one decoy.
- Modify: `SaftUI-Misc/TalentPlan/data.lua`: `tree.shape` (spec), built in `D.Read`'s pass; `hideSingle` from `GetTreeInfo`; when no node carries an `isGate` condition but `GetTreeInfo().gates` has gates, each gate goes to the nodes of its top-left node's group at or below its `posY` (open question 2).
- Modify: `SaftUI-Misc/TalentPlan/talentplan.lua`: `Refresh` sets `view.sim = TP.Sim.Run(tree.shape, plan and plan.steps or {})`; `OnEnable` calls `TF:SetPlanSource(function(id) return TP:PlanDisplay(id) end)` when `st:GetModule('TalentFaces', true)` exists; `TRAIT_NODE_CHANGED_PARTIAL` joins `EVENTS`; `st.Config:AddSubcommand('tp', ...)` for `/sui tp check` (prints `Sim.Check`'s list, or "The plan's rules agree with the game.").
- Modify: `SaftUI-Misc/TalentPlan/overlays.lua`: `TP:PlanDisplay(nodeID)` (nil unless planning and the node is in the shape); `PlanClick` asks `Sim.CanAdd` / `Sim.CanRemove` first and returns `'refused', reason` with nothing changed; the catcher's tooltip adds the reason in Text > Danger (`TP.CatcherLines(plan, nodeID, node, refusal)`); the catcher's OnEnter and OnLeave call `TF:Hover`; the dim is off while planning; `SetPlanning` calls `TF:Queue()`; the window total: a font string on the layer at `TalentsFrame`'s TOPLEFT, `('Planned: %d points'):format(total)` then `name n` per group joined by `' · '`, shown only while planning.
- Modify: `SaftUI-Misc/TalentPlan/panel.lua`: a step whose `view.sim.steps[i].ok` is false draws as a blocked row with that reason.
- Test: `tests/misc/talentplan_data_test.lua`, `talentplan_overlays_test.lua`, `talentplan_panel_test.lua`.
- Docs: `.agents/taint.md` rule 23 (the faces' module, reads, the one write, the hooks), `.agents/architecture.md` (the module and `TP.Sim`), `AGENTS.md`'s SaftUI-Misc row (`Blizzard_TalentFaces.lua`, `simulate.lua`), `.agents/testing.md` if it lists the talent plan tests, `docs/followups.md` (the edges in planning mode; the covered search icon).

**Interfaces:** consumes Task 1's `TP.Sim` and Task 2's `TF:SetPlanSource`, `TF:Queue`, `TF:Hover`. Produces `TP:PlanDisplay(nodeID) -> { state, planned } | nil`, `TP:PlanClick -> 'added' | 'removed' | 'maxed' | 'refused', reason | nil`.

- [ ] **Step 1: Write the failing tests.**
  - data: `the shape holds groups, gates, edges and costs`: `SH.install({ shape = true })`, `D.Read(1).shape`: three groups in order, Stormstrike's `parents` has Spirit Weapons with type 3, a row-2 node has `gates[1].required == 5` and its group, the choice node is in the shape with `plannable = false`; `gates from GetTreeInfo when nodes carry none`.
  - overlays: `a planning click the tree forbids is refused`: planning, click a row-2 Enhancement node first: returns `'refused'`, the plan is unchanged, the catcher's tooltip's last line is `'Needs 5 points in Enhancement first.'`; five row-1 clicks then the row-2 click: `'added'`.
  - `a right-click a later step needs is refused`.
  - `planning shows the plan, not the real tree`: real ranks give Flurry 5/5; plan empty; planning: `TP:PlanDisplay(Flurry)` is `{ state = 'gated' or 'selectable', planned = 0 }` per its row, and its face shows the plan; planning off: the real `maxed`.
  - `the window total`: after 6 planned points, the text is `'Planned: 6 points'` with `'Elemental 0 · Enhancement 6 · Restoration 0'`; hidden when planning ends.
  - `no plan dim while planning`.
  - panel: `an out-of-order step shows blocked with its reason` (a plan imported in the wrong order).
  - every test ends with `eq(#stub.traits.calls, 0)` and `PSF.clicks` empty.
- [ ] **Step 2: Run** `tests/run tests/misc`. Expected: FAIL on the new cases.
- [ ] **Step 3: Implement** the files above.
- [ ] **Step 4: Run** `tests/run`. Expected: PASS. Then the `agents-doc-parity-check` and `readme-freshness-check` skills.
- [ ] **Step 5: Commit** `misc: plan talents by the tree's rules and show the plan on the faces`.

## In-game checklist (for the owner, Forever)

1. Talent window, Skinning > Talent window on, Theme Thick: every talent is a square SaftUI icon in a SaftUI border; learned ranks bottom right; available nodes green-edged, maxed in the Accent, gated rows dark and grey, prerequisite-locked ones lighter grey. No Blizzard number or shadow peeks out.
2. Hover a talent: the face lights; Blizzard's tooltip still shows. Buy a rank and Apply: the face follows at once.
3. Planning on, empty plan: every node shows the plan's state (row 1 available, the rest gated), real ranks faded, no planned numbers but on available nodes ("0"). Top-left of the window: "Planned: 0 points" with three tree names.
4. Click a row-2 talent first: nothing is added, the tooltip says "Needs 5 points in ... first." Put five points in row 1: row 2 lights up. Right-click a row-1 rank a row-2 step needs: refused with its reason.
5. A talent with a prerequisite arrow stays locked until the prerequisite is maxed in the plan.
6. `/sui tp check` on a character with points in two trees: "The plan's rules agree with the game." (Anything listed answers open questions 1, 2 and 4.)
7. Skinning > Theme Blizzard: normal mode is Blizzard's tree untouched; planning mode shows the plan in Blizzard's node art, with the planned number top-left.
8. Turn Skinning > Talent window off in a session: faces go, Blizzard's numbers come back.
9. Open the window in combat for the first time in a session: no error; faces appear after combat. `Logs/taint.log` blames nothing of SaftUI's for `Blizzard_SharedTalentUI`.
10. Search a talent name: note whether the match is still visible (the followup).
