# Talent faces and a planning simulation

Date: 2026-11-22. Status: draft for the owner's review. Lines marked "My call" are the designer's, for the owner to check. Forever only, like the rest of the talent plan.

## Intent

The owner, verbatim: "can we skin the icons and borders to match saft ui? Also when I'm editing a plan I want the points to actually match the plan, not just show what I currently have talented. when in planning mode fade out the currently allocated points and put the planned point count in the top left. I also want the talents to be correctly restricted (you must fill in enough of previous rows to select talents) in planning mode just like if I was putting in actual points. the talent opacity should also behave similarly to when I'm dealing with real talents."

So two things: (A) the talent buttons wear SaftUI's look, and (B) planning mode stops showing the character's real tree and shows the plan's tree instead, with the game's own rules (row gates, prerequisites) applied to the plan and the game's own way of dimming what can't be taken.

## Goals

1. **A SaftUI face on every talent button** while the talent window skin is active (Skinning > Talent window on, Skinning's Theme not Blizzard: `PS:IsActive()`): the icon cropped square in SaftUI's border, its rank in the Skinning font, the border colored by the node's state, and the node dimmed and desaturated as Blizzard dims it.
2. **Planning mode shows the plan.** Each node shows its planned rank in its top-left corner; its real rank is faded; the planned point total (and the planned points per tree) shows in the window's top-left; and each node's color, dim and desaturation follow the plan's simulated state, as Blizzard's follow the real state.
3. **Planning obeys the tree's rules.** A click that adds a rank the game would refuse at that point of the plan (a row gate not yet reached in that tree, a prerequisite not maxed, the node maxed) is refused and the tooltip says why. A right-click that would leave a later planned rank illegal is refused the same way.
4. **Normal mode is unchanged in meaning:** the face shows the real state, read from Blizzard's own button.
5. Under the Blizzard look (skin off, or Skinning's Theme Blizzard), normal mode is Blizzard's buttons untouched; planning mode still shows goals 2 and 3, drawn in Blizzard's own node art.

## Non-goals

- The lines (edges) between nodes keep Blizzard's real state in planning mode. My call: a later followup if the owner wants them simulated; drawing them means SaftUI's own lines over Blizzard's pooled edge frames.
- Choice (selection) and hero sub tree nodes get no face and are not simulated as plannable: the plan can't hold them (`data.lua` skips them). Forever's classic trees are not expected to have any (open question 3).
- Blizzard's search match icon (`button.SearchIcon`, a child frame of the button) is covered by the SaftUI face. My call: accepted for now, logged as a followup (SaftUI's own mark from `SearchIcon:IsShown()`).
- Retail: nothing here runs there.

## A. The node face

### Where it lives

A new module, `TalentFaces` (`st:NewModule`, like `TalentWindow`), in `SaftUI-Misc/Skinning/blizzard/Blizzard_TalentFaces.lua`, loaded after `Blizzard_PlayerSpellsSkin.lua`. It is not part of `TalentPlan`, because the SaftUI face must show with the plan panel off; and not part of `Blizzard_PlayerSpellsSkin`, because the Blizzard-look planning face must show with the skin off. The plan feeds it through one seam, `TF:SetPlanSource(fn)`: while the source gives a display for a node, the face draws that; otherwise the real state.

| Look | Normal mode | Planning mode |
| --- | --- | --- |
| SaftUI (`PS:IsActive()`) | SaftUI face, real state | SaftUI face, simulated state |
| Blizzard (skin off or Blizzard theme) | no face: Blizzard's buttons as they are | Blizzard-art face, simulated state |

### The SaftUI face

One frame of SaftUI's per talent button, a child of the module's own layer frame on `TalentsFrame` (as the plan's overlays are), `SetAllPoints(button)`, mouse-disabled, at `button:GetFrameLevel() + 2` (under the plan's dim +4, glow +5, light +6 and catcher +10, so those still draw over it). Parts:

- the backdrop: `st:SetTemplate(face, theme, background, 'action')` with Skinning's Theme and Background, as the totem skin draws its buttons;
- the icon: a texture of SaftUI's inside the border, the texture read from `button.Icon:GetTexture()` (or `GetAtlas()`), cropped with `st:IconTexCoords(st.config.profile.misc.icon_trim, w, h)`;
- the overlay: a black texture over the icon, shown with Blizzard's alphas (below);
- the rank: a font string at the bottom right in the Skinning font (`st:FontObject(profile.skinning.font)`), the real rank;
- the planned count: a font string at the top left, same font, shown only in planning mode;
- hover: `st:AddStates(face, 'icon', { wire = false, ... })` and `st:SetState(face, 'hover', on)` from a `HookScript` OnEnter and OnLeave on the button (normal mode) or from the plan's catcher (planning mode: `TF:Hover(nodeID, on)`), so the states scan (`tests/core/states_scan_test.lua`) passes.

The face's colors, by state (the table is pure, `TF.Paint(state)`; the alphas are Blizzard's `TalentButtonArtMixin:ApplyVisualState`):

| State | Blizzard's state | Border (SaftUI) | Rank text | Overlay alpha | Desaturated |
| --- | --- | --- | --- | --- | --- |
| `selectable` | Selectable | Text > Success | Text > Success | none | no |
| `partial` | Normal | Text > Caution | Text > Caution | none | no |
| `maxed` | Maxed | Accent | Text > Caution | none | no |
| `gated` | Gated | theme's own | Text > Muted | 0.7 | yes |
| `locked` | Locked | theme's own | Text > Muted | 0.25 | yes |
| `disabled` | Disabled | theme's own | Text > Muted | 0.25 | yes |
| `error` | RefundInvalid, DisplayError | Text > Danger | Text > Danger | 0.3 | no, icon tinted red |
| (hidden) | Invisible | the face hides | | | |

My call: Blizzard's green and yellow become Success and Caution, and a maxed node's border the Accent ("what is on"), so the face follows the owner's colors.

**The real state** (normal mode, and any node the plan source doesn't know): `button.visualState` (a number of `TalentButtonUtil.BaseVisualState`, read) mapped to the keys above, and the rank text `button.SpendText:GetText()` (read), so the face says exactly what Blizzard's button says, including Blizzard's choice to show no number.

### The Blizzard-art face (Blizzard look, planning mode only)

The same record, drawn in Blizzard's art on SaftUI's own textures, each anchored with `SetAllPoints` to the Blizzard region it copies (SaftUI's anchored to Blizzard's, never the other way): the icon (`button.Icon`'s texture; masked by a MaskTexture of SaftUI's with the atlas `button.IconMask:GetAtlas()` when `button.IconMask:IsShown()`), the overlay (over `button.DisabledOverlay`'s rect), the state border (over `button.StateBorder`, atlas `button.artSet[key]`: selectable to `selectable`, partial to `normal`, maxed to `maxed`, gated to `locked`, locked and disabled to `disabled`, error to `displayError`), and the two texts in `button.SpendText:GetFontObject()`, the real one centered on `button.SpendText`.

### Blizzard's art, faded

While a face shows on a button, these regions of it are faded with `SetAlpha(0)`, their alpha read once into a weak table and put back when the face goes: `SpendText` and each of `spendTextShadows` (the real number: the face draws its own), `Shadow` (it reaches outside the button) and `SelectableIcon` (the colorblind plus). Blizzard never sets the alpha of these (it sets their text, color, atlas or shown state only: `TalentButtonArtMixin:OnLoad`, `ApplyVisualState`, `TalentButtonUtil.SetSpendText`), so the fade holds. Never hidden, moved or resized.

Left alone, because Blizzard writes their alpha itself: `DisabledOverlay`, `StateBorderHover`, `BorderSheen`, `Glow`, `SelectableGlow` (an animation) and the button itself (`TalentDisplayMixin:SetVisualState` sets it 0 or 1). The ones inside the button are covered by the face's opaque icon. `SelectableGlow` (61 square, alpha at most 0.15) and `BorderSheen` can show a faint halo past the face's edge that follows the real state; accepted, an in-game check.

### Updates

The face is redrawn on the next frame (`C_Timer.After(0)`, one pass) after: `EventRegistry` `TalentFrameBase.ButtonsUpdated` and `.ConfigUpdated`, `TalentsFrame`'s OnShow, the plan source's change (`TF:Queue()`), a look or color change, and a post-hook on each button's own `ApplyVisualState` and `UpdateSpendText` (hooked once per button, in a weak table; a pooled button is hooked once, whatever node it gets). The hooks only mark the queue; nothing is drawn inside Blizzard's call. `TalentsFrame`'s OnHide hides every face. The node-to-button map is rebuilt on every draw from `EnumerateAllTalentButtons()`, as the overlays do.

### Taint

`.agents/taint.md` rules 1 to 3, 6 and 23 (rule 23 gains this module). Post-hooks only (`hooksecurefunc` and `HookScript`), each in `xpcall` to `geterrorhandler()`. Nothing is written onto a Blizzard frame or table but the `SetAlpha` fades above. In combat, an existing face is updated, but a face is not made: a draw that would make one waits for the end of combat (`st:QueueAfterCombat`), as the skin's `PS:Deferred` does (the window is protected on Forever).

## B. The planning simulation

### The tree's shape (read by `data.lua`)

`D.Read` gains `tree.shape`, plain tables, built in the same pass:

```
shape = {
  groups = { { id, name, order }, ... },          -- C_Traits.GetGroupDisplayInfoByTreeID(treeID), by orderIndex
  budget = nil,                                   -- never read: a plan runs to max level (Sim honours one when set)
  nodes = { [nodeID] = {
    maxRanks, cost,                               -- cost: GetNodeCost's amount (1 when empty)
    group,                                        -- the first of info.groupIDs that is a displayed group, else nil
    gates = { { required, currency } },           -- the node's conditions with isGate and spentAmountRequired
    parents = { { nodeID, type } },               -- incoming edges: every visible node's visibleEdges, turned round
    plannable,                                    -- the node is in tree.nodes (one entry, no sub tree, named)
    posY,
  } },
}
```

Every visible, non sub tree node goes in the shape, plannable or not, so a node whose prerequisite is a choice node is (correctly) never available to the plan.

### `TP.Sim` (`SaftUI-Misc/TalentPlan/simulate.lua`, pure, no WoW API)

`Sim.Run(shape, steps)` walks the steps in order and gives:

```
{ ranks = { [nodeID] = n },
  spent = { total = n, [groupID] = n },
  steps = { [i] = { ok = bool, reason = string|nil } },
  nodes = { [nodeID] = { rank, state, reason } } }
```

The rules, each the game's:

- **Spent.** A rank adds its node's `cost` to `spent.total` and to `spent[group]` when the node has one.
- **Gate (a row).** A gate `{ required }` is met when the spent in the node's scope is at least `required`. The scope is the node's group when it has one (Camelot's three trees: the header counts `currencyInfo.spent` per group, `GetGroupCurrencyInfo`, and the gate tooltip names the group, `GetTraitTreeName(treeID, groupIDs)`), else the whole tree. My call, checked in game (open question 1).
- **Prerequisite (an edge).** `RequiredForAvailability` (3) parents must all be maxed; of `SufficientForAvailability` (2) parents at least one must be; `VisualOnly`, `MutuallyExclusive` and the deprecated types don't gate. A parent counts as maxed at `rank >= maxRanks`.
- **A step** is `ok` when, with the ranks before it, its node is plannable, under `maxRanks`, its gates are met, its prerequisites are met and the budget (when there is one) isn't spent. A step that isn't ok still counts (the plan says it), and its reason is kept: `'Needs %d points in %s first.'`, `'Needs %s first.'` (the parent's name is the caller's), `'All %d ranks are planned.'`, `'No points left at this level.'`.
- **A node's state**, after the last step, in Blizzard's order (`TalentButtonBaseMixin:CalculateVisualState`): `error` (a step of it isn't ok), `maxed`, `selectable` (one more rank would be ok), `partial` (has ranks), `gated`, `locked`, else `disabled`.

`Sim.CanAdd(shape, steps, nodeID, after)` gives `ok, reason`: the step inserted after `after` (appended with nil) is ok and no later step stops being ok. `Sim.CanRemove(shape, steps, nodeID)` gives `ok, reason`: removing the node's last step leaves every step that was ok still ok, else `'Other planned talents need this rank.'`. `Sim.Check(shape, real)` runs the rules over the real ranks (`real[nodeID] = { rank, isAvailable, meetsEdgeRequirements }`) and gives the nodes where the rules and the game disagree: the self-check for open question 1, behind `/sui tp check`.

### What planning mode shows

`TP:Refresh` runs `Sim.Run(tree.shape, plan.steps)` into `TP.view.sim` (no plan: an empty run). While planning, `TP:PlanDisplay(nodeID)` (the source given to `TF:SetPlanSource`) gives `{ state, planned }` from the run, and nil for a node the shape doesn't know (it shows its real state).

- The face draws the simulated `state` (colors, overlay, desaturation, table above) and the planned rank in the top-left (Blizzard's rule for the number: shown when the rank is above 0 or the node is selectable; no number for a 1-rank node when the tree's `hideSingleRankNumbers`). The real rank stays at its place at alpha 0.3, in Text > Muted.
- The window's top-left, on the plan's layer: `Planned: 31 points` and the per-tree counts in the groups' order (`Elemental 0 · Enhancement 26 · Restoration 5`), in the Skinning font. Hidden outside planning.
- The plan's dim of unplanned nodes is off while planning (the simulated state is the dim then). The waiting glow and the row light stay.
- A refused click plays no sound and changes nothing; the catcher's tooltip ends with the reason in Text > Danger. A step that isn't ok (an import or a drag can make one: drags are not refused) shows in the panel with its reason, as a blocked row does.

Normal mode: `TP:PlanDisplay` gives nil, so the face shows the real state; the overlays are as today.

## Blizzard reads and writes, exactly

**Read only** (new to rule 23's getters): `C_Traits.GetTreeInfo(configID, treeID)` (`gates`, `hideSingleRankNumbers`), `GetGroupDisplayInfoByTreeID(treeID)` (`groupID`, `displayName`, `orderIndex`), `GetNodeCost(configID, nodeID)` (`amount`), `GetTreeCurrencyInfo(configID, treeID, false)` (`maxQuantity`); the node info's `visibleEdges` (`targetNode`, `type`), `groupIDs`, `posY`, `type`; the condition info's `isGate`, `spentAmountRequired`, `traitCurrencyID`; on a talent button: `GetNodeID`, `GetNodeInfo` (its `type`, to skip choice and sub tree nodes), `GetFrameLevel`, the fields `visualState`, `artSet`, `Icon`, `IconMask`, `DisabledOverlay`, `StateBorder`, `SpendText`, `spendTextShadows`, `Shadow`, `SelectableIcon`, and `GetTexture`, `GetAtlas`, `IsShown`, `GetText`, `GetFontObject`, `GetAlpha` on those regions; the global `TalentButtonUtil.BaseVisualState`.

**Written:** only `SetAlpha` on `SpendText`, `spendTextShadows`, `Shadow` and `SelectableIcon` of a button wearing a face (and the restore). No field, method, script, texture, point, size, shown state or mouse state of any Blizzard frame; no Blizzard function called but the reads; never `C_Traits.PurchaseRank`, `RefundRank`, `CommitConfig` or any other writer (the plan's existing rule).

**Hooks:** `hooksecurefunc` on each talent button's `ApplyVisualState` and `UpdateSpendText`; `HookScript` OnEnter and OnLeave on each talent button and OnShow and OnHide on `TalentsFrame`; `EventRegistry` `TalentFrameBase.ButtonsUpdated` and `.ConfigUpdated` with the module as owner.

## Testing

- `tests/misc/talentplan_simulate_test.lua`: the rules on hand-made shapes (gates per group, the tree scope, required and sufficient edges, cost, budget, order, CanAdd, CanRemove, Check).
- `tests/misc/talent_faces_test.lua`: the fixture's buttons gain Blizzard's art regions and `visualState`; faces under both looks, the fades and restores, a re-bound button, combat, nothing written (the locked fixture).
- `tests/misc/talentplan_overlays_test.lua` grows the planning cases (a refused click, a refused right-click, the window's total, the dim off); `talentplan_data_test.lua` the shape.

## Open questions

1. **Gate scope on Forever (a guess).** Is a row gate's `spentAmountRequired` counted in the node's own tree (group) or the whole class tree? The design guesses the group, from Camelot's per-group header counts and the tooltip that names the group. `/sui tp check` lists any node where the rules disagree with the game; the owner runs it once on a character with points in two trees.
2. **Do Forever's nodes carry their gate as a condition?** The reader already relies on it (`D.BlockReason`); if Forever puts the gate only in `GetTreeInfo().gates` (by `topLeftNodeID` and `posY`), the reader maps each gate to the nodes at or below its top-left node's `posY` in the same group. The check shows which.
3. **Choice and sub tree nodes on Forever.** Assumed absent from Camelot's class trees; if one exists it keeps Blizzard's art.
4. **Prerequisites need the parent maxed?** Classic's rule, and Blizzard's `isActive` edges on Forever are expected to agree; the check shows it.
5. **The budget.** Decided: none. A plan runs to max level, so `data.lua` never reads `GetTreeCurrencyInfo` and nothing is refused for points (the plan's length is the owner's). `Sim` still honours a `shape.budget` when one is set; nil turns it off.
7. **Granted (free) nodes.** Some nodes may be granted by the game (a free first rank, a starting talent) and carry ranks that cost no point or can't be refunded. The simulation counts every planned rank at its cost and doesn't know which nodes are granted; `/sui tp check` and the face of such a node may disagree with the game. Unchecked.
6. **"Top left".** Read as each node's top-left corner for its planned count, and the window's top-left for the total. If the owner meant only one, the other goes.
