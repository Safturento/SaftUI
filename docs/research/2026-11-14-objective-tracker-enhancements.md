# Objective tracker: zone groups, height, scroll and size. What can be done

A feasibility study for a design conversation, 2026-11-14. Read only: nothing in the repo was changed.

Checked against Blizzard's source for **Forever 1.60.1 (70938)** and **retail 12.1.5 (70783)** (Gethe/wow-ui-source, branches `forever` and `live`). Also checked against SaftUI's skin and mover (`SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua`, `Blizzard_ObjectiveTrackerPosition.lua`), `.agents/taint.md` rule 5, and the source and issue trackers of the tracker addons named in section 3.

How each fact is marked:

- **[src]**: read in Blizzard's source (linked).
- **[addon]**: seen in another addon's code or issue tracker (linked).
- **[inferred]**: my reading. No source shows it.
- **[game]**: only the game can confirm it.

---

## At a glance

| Request | Options | Taint risk | Effort | My pick |
|---|---|---|---|---|
| **Zone grouping** | A. Move Blizzard's quest blocks under SaftUI zone headers after each layout. B. Make Blizzard's own order come out by zone. C. Show only the current zone's quests (auto-track). D. SaftUI draws its own quest list. | A: low taint, very fragile. B: not possible. C: none. D: none, but it brings new limits. | A: L. B: n/a. C: S–M. D: L. | **D**, if real headers are wanted. **C** now as a cheap stand-in. Not A or B. |
| **Max height** | A. Blizzard's own Height setting (400–1000), reached through Blizzard's Edit Mode. B. SaftUI sets the tracker's height itself. C. Write Edit Mode's saved layout from `/sui`. D. Clip the tracker. | A: none. B: **unknown, one in-game test decides (E1)**. C: medium. D: useless. | A: S. B: S. C: M. | **A** now. **B** if E1 passes (it also allows heights under 400). |
| **Scroll bar** | A. Move Blizzard's modules (not the tracker) into a SaftUI scroll frame below the tracker's header. B. Put the whole tracker in a scroll frame. C. Clip without re-parenting. D. Own tracker. | A: low–medium, needs an in-game proof (E3). B: high (Blizzard re-parents it back). C: not possible. D: scrolling locks in combat unless the item buttons sit outside. | A: M. B: n/a. C: n/a. D: part of L. | **A**, behind a toggle, after E3. Built in with D. |
| **Size: text** | SaftUI font objects at the tracker's own size. The skin already sets fonts before Blizzard measures. | none | S | **Yes** |
| **Size: width** | A. Widen Blizzard's modules, which have no size script, and leave the tracker frame at 260. B. `SetWidth` on the tracker. | A: low (except the scenario module). B: same unknown as height (E1). | A: S–M | **A** |
| **Size: scale** | A. `SetScale` through Edit Mode's override. B. The C `SetScale` directly. C. No scale: font, width and item size instead. | A: taints. B: unknown (E2), and Blizzard's height maths goes wrong in the default spot. C: none. | B: S | **C**. Do B only if you want the icons to scale too. |
| **Other stuff** | Fade or hide by alpha, header counts, quest tooltips, sort by distance, item button size, a "nearest quest item" button, SaftUI's own background, a key to collapse | Mostly none | S each | See §2.5 |

**The one decision.** Keep skinning Blizzard's tracker and add only taint-free things, or build SaftUI's own. The first delivers everything above except zone grouping, reordering and per-section hiding. Only the second delivers those (§0).

---

## 0. The one decision: keep Blizzard's tracker, or build SaftUI's own

| | Keep skinning Blizzard's, add taint-free pieces | SaftUI's own tracker |
|---|---|---|
| Zone grouping with real headers | **No.** "Only this zone's quests" is possible. | Yes |
| Any order (completed first, by zone, by level) | **No.** Only "re-sort by distance now". | Yes |
| Hide or collapse single sections | **No.** Blizzard's collapse can only be clicked by the player. | Yes |
| Max height | Yes. Blizzard's own (≥400) now, any value if E1 passes. | Yes |
| Scroll | Probably, if E3 passes. | Yes, but not in combat if the item buttons are inside it (§2.3) |
| Text size, width, item size, fades, counts, tooltips | Yes | Yes |
| Quest item **picked up mid-fight** | Works at once. Blizzard's button isn't secure and is made in combat. | **No button until the fight ends.** Secure buttons can't be made or set up in combat ([addon]: Kaliel's, EQ, KaLi Quest). |
| Item buttons following their rows in combat | Yes | **No.** They freeze or dim (KaLi Quest), or sit in a separate column (Kaliel's). |
| Scenarios, Mythic+, world quests, bonus objectives, widgets, popups | Free, and kept current by Blizzard every patch | Rebuild them, or hand over to Blizzard's tracker when one has content |
| Cost | S per feature | L. The open-source replacements are 330 KB to 1.1 MB of Lua, against Blizzard's own 213 KB (6,500 lines on Forever). It also needs upkeep every patch on both clients. |
| Taint exposure | Only what SaftUI already does: post-hooks and widget calls | None in Blizzard's tracker if it is left alone. Opening the world map from SaftUI's own click is a known taint path in combat (§2.5). |

My answer is in the reply. In short: do the taint-free set now. If zone grouping still matters after that, build SaftUI's own quest list. Leave Blizzard's tracker untouched underneath it: concealed, never hidden, never unmounted.

---

## 1. Blizzard's tracker, as far as these requests go

### 1.1 One tracker on both clients **[src]**

`Blizzard_ObjectiveTracker` has the same files on both branches. It loads at startup (no LoadOnDemand in either TOC). The differences that matter:

- **Forever only.** Forever adds [`Camelot/Blizzard_QuestObjectiveTrackerOverride.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Camelot/Blizzard_QuestObjectiveTrackerOverride.lua): no timer bars in the quest module, plus Forever's quest tags.
- **Forever's quest titles.** They go through `SetQuestTitleLevelAndDifficultyColor` with Forever's tag text ("(Elite)", "(Dungeon)", "(PvP)", "(Raid)": [`QuestUtilsOverrides.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/QuestUtilsOverrides.lua)). Forever's `GetQuestTitlePrefix` gives "[level] " with a "+" for elite. That this is the prefix the tracker shows is **[inferred]**, so check it in game.
- **Retail.** Shows the plain title.
- **Forever's gamepad pieces and padding.** Forever adds gamepad navigation and top-padding providers that push the header down. Retail has a fixed `topModulePadding` of 38.

The managed right column and the Edit Mode system are shared code on both.

### 1.2 How it's built **[src]**

- **Container.** [`ObjectiveTrackerFrame`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.xml) inherits the right managed frame, the Edit Mode system and the container template. It is 260 wide, has a header ("All Objectives") and a background (`NineSlice`). Its XML carries `roleset="objectives"`, which Blizzard's own UI modes use to hide it.
- **Modules, in this fixed order** ([`ObjectiveTrackerManager:Init`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerManager.lua#L190-L216)): Scenario, UI widgets, Campaign, Quests, Adventure, Achievements, Monthly activities, Initiative tasks, Professions, Bonus objectives, World quests.
  - Each module is a frame with a header and a `ContentsFrame`.
  - Each is added to the container **once**, at login (after `PLAYER_ENTERING_WORLD` and `VARIABLES_LOADED`). `SetContainer` re-parents it to the container then.
- **Blocks and lines.**
  - A block is one quest, achievement and so on. It is anchored under the previous block and stretched to the module's right edge.
  - A line is one objective, anchored under the previous line.
  - Blocks, lines, bars and item buttons all come from one frame pool per template (`ObjectiveTrackerManager:AcquireFrame`, `CreateFramePoolCollection`), shared across modules.
- **Layout.**
  - Any change calls `MarkDirty`. That sets `dirty` and schedules `Update` for the next frame with `RunNextFrame` ([`DirtiableMixin`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/MixinUtil.lua#L337-L352)).
  - `Update` lays out every dirty module from scratch: it hands out blocks and lines, sets their text, measures each text's height, and anchors them.

### 1.3 Height, and what happens when it overflows **[src]**

- **In its default spot** (where SaftUI's mover keeps it, unless the player once moved it in Blizzard's Edit Mode): its height is its parent's height plus its top offset. So it always reaches down to the bottom of Blizzard's right column ([`UpdateHeight`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua#L207-L228)).
- **Once moved in Blizzard's Edit Mode:** its height is Edit Mode's **Height** setting, 400 to 1000 in steps of 10, or 800 if none is set ([setting](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSettingDisplayInfo.lua#L607-L618)). Edit Mode shows the slider **only while the tracker is out of its default position** (`ShouldShowSetting`).
- **The cap is a layout budget, not a visible box.**
  - The modules get the tracker's height less the top padding (`GetAvailableHeight`). Bonus objectives and Scenario go first ("display priority").
  - Each module adds blocks while they fit (`CanFitBlock`). The first block that doesn't fit ends that module ("shown partially").
  - **Every module after it gets no room and isn't shown at all.**
  - The background ends at the last shown module.
- **No "more quests below" indicator** exists in either client's source. Objectives that don't fit simply aren't there.
- `mustFit` (a module that can stretch a custom height) exists, but no module sets it.

### 1.4 Width **[src]**

- **The tracker is 260 wide**, and so is every module frame ([template](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerModule.xml#L78-L80)). The container anchors each module only at its top and left.
- **Fixed sizes.** Module headers are fixed at 260 with a 200-wide title, and the tracker's header at 260 with a 208-wide title.
- **Blocks and lines.** Blocks stretch to the module's right edge. Lines stretch to the block's right edge, less the room the item button takes.
- **Heights are re-measured on every layout.** Each line's text is set and measured on every layout (`SetStringText`), so a width change re-flows at Blizzard's next update.
- **Only one frame has `OnSizeChanged`: the tracker itself.** It calls `MarkDirty` ([here](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua#L30-L32)).
  - Modules and blocks have none.
  - The exception is the scenario module's two widget containers, which `MarkDirty` the scenario module when they resize (`Blizzard_ScenarioObjectiveTracker.lua` lines 98–99).

### 1.5 Quest item buttons **[src]**

- **Template.** `QuestObjectiveItemButtonTemplate` is a **plain Button**. No secure template exists anywhere in the tracker's XML on either client.
- **Click.** Its `OnClick`, Blizzard's own code, calls `UseQuestLogSpecialItem` ([`Blizzard_ObjectiveTrackerShared.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerShared.lua#L94-L104)).
- **When it's made: inside the quest module's layout.**
  - `UpdateSingle` → `block:AddRightEdgeFrame` → `module:GetRightEdgeFrame` → `AcquireFrame` → the pool's `CreateFrame` ([quest module](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua#L311-L313)).
  - **So the layout's taint becomes the button's.** The pool then hands that same button out for the rest of the session (taint.md rule 5).
- **`AddRightEdgeFrame` reads the button's width** (`frame:GetWidth()`) to know how much room the title and lines leave.
- **The item is called through attributes since 11.0.7.** The button now keeps its quest log index in **attributes** (`SetAttribute("questLogIndex")`), where it used to keep it in `self.questLogIndex` ([Blizzard's 11.0.7 commit](https://github.com/Gethe/wow-ui-source/commit/ec9e859b83c8c21c65b609556ff74fe5282f6184)). PetTracker and Todoloo report their "taints the quest item" bugs gone with 11.0.7 **[addon]**.
- **Lua fields remain.** `charges`, `rangeTimer` and the mixin's methods are still Lua fields. Its range check `OnUpdate` calls `QuestObjectiveTracker:MarkDirty()`.
- **A tainted button fails even out of combat.** Addons that tainted it got `ADDON_ACTION_FORBIDDEN` for `UseQuestLogSpecialItem`, not `..._BLOCKED`. The game never lets addon code make that call: [PetTracker #395](https://github.com/Jaliborc/PetTracker/issues/395), [#406](https://github.com/Jaliborc/PetTracker/issues/406), [Todoloo #52](https://github.com/Todoloo-WoW/Todoloo/issues/52), [ElvUI_WindTools #529](https://github.com/wind-addons/ElvUI_WindTools/issues/529), [AngrierWorldQuests #86](https://github.com/GurliGebis/WoWAddon-AngrierWorldQuests/issues/86) **[addon]**.
- **Scenario spell buttons** are plain buttons as well. Their `OnClick` calls `CastSpellByID`.

### 1.6 Combat **[src]**

- **No combat checks.** The tracker has no `InCombatLockdown` check anywhere. It lays out, and makes item buttons, in combat.
- **Nothing in it is secure, so nothing is protected.** The widget methods the docs mark as protected functions (`SetPoint`, `SetHeight`, `SetWidth`, `SetParent`, `SetScale`, `SetVerticalScroll`, `SetScrollChild`) are only blocked on protected frames ([API docs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScrollFrameAPIDocumentation.lua)). So the tracker can be moved, sized and scrolled in combat. **The only danger is taint**, not a block.
- **New since 12.x, and on Forever.** A layout that runs tainted **in combat now errors**. The scenario module calls `ShouldShowMawBuffs`, which reads a player aura that is secret in combat, and the read fails for tainted code. **The tracker then stops updating** ([WoWUIBugs #882](https://github.com/Stanzilla/WoWUIBugs/issues/882) **[addon]**). On Forever, ForeverQuestTracker hit exactly this on 2026-11-13. Its cause: it hid the stock tracker with `Hide`/`Show` and an `OnShow` hook ([ForeverAddons-Issues #2](https://github.com/Forever-Addons/ForeverAddons-Issues/issues/2) **[addon]**).
- **What this changes.** A tainted layout now costs more than the quest item: it can also freeze the whole tracker in a dungeon.

### 1.7 What taints, if SaftUI does it

| If SaftUI… | Blizzard then runs, tainted | Result |
|---|---|---|
| calls the tracker's own `Show`, `Hide`, `SetShown`, `SetPoint`, `ClearAllPoints` or `SetScale` | Edit Mode's Lua overrides ([`EditModeSystemMixin:OnSystemLoad`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua#L9-L36)). The `SetScale` override also re-anchors the tracker and calls `ObjectiveTrackerFrame:Update()` | Tainted Edit Mode state, and a tainted full layout **[src]**. Carrot Objective Tracker's `SetScale(0.001)` produced "tainted by Carrot" errors ([changelog](https://www.curseforge.com/wow/addons/carrot-objective-tracker/files/7951634)) **[addon]** |
| shows the tracker, or re-parents it so its visibility changes | `OnShow` → `UpdateHeight` → `SetHeight` → `OnSizeChanged` → `MarkDirty` | A tainted layout on the next frame **[src]** |
| sizes the tracker, even with the C method (`st:SetSizeDirect`) | `OnSizeChanged` → `MarkDirty`, **if the game runs that script inside SaftUI's call** | **Unknown [game]**: experiment E1 |
| calls `MarkDirty`, `Update`, `UpdateAll`, `SetCollapsed`, `ToggleCollapsed`, `UpdateHeight`, `RemoveModule`, `SetModuleContainer`, `SetOpacity` or `SetTextSize` | The layout | A tainted layout **[src]** |
| writes a field on a module or block (`lineSpacing`, `blockOffsetX`, `fromBlockOffsetY`, `headerText`…) | Every later layout reads it | **Every** layout runs tainted (rule 1) |
| removes all modules so nothing lays out (EQ, aura-questor) | `RemoveModule`: a tainted table edit and `MarkDirty` | "Stops the LAYOUT, never the taint" (EQ's own comment). Fine only when Blizzard's tracker is never used again **[addon]** |
| does what SaftUI does today: post-hooks, its own textures and frames on Blizzard's, `SetAlpha` and fonts on regions, C `SetPoint` on the tracker | Nothing of Blizzard's | Clean by source. **Still not confirmed with an item used in combat** (followup check 1 has no report yet) |

### 1.8 What else moves the tracker **[src]**

- **The right column.** While the tracker is in its default spot, the column takes it as **its child** (`SetParent(column)`) and lays it out on every update. It also fades its frames with `SetAlpha(0)`/`SetAlpha(1)`: under an override action bar, and back in after a cinematic ([`ManagedFrameSystem.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ManagedFrameSystem/Shared/ManagedFrameSystem.lua#L46-L55)).
- **Edit Mode.** Edit Mode's layout apply moves a moved tracker back to UIParent (`BreakFromFrameManager`: `SetParent(UIParent)`, [here](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua#L335-L348)).
- **What this means for SaftUI.** Blizzard undoes any parent or alpha SaftUI gives the tracker. SaftUI must re-apply after Blizzard, as the mover already does for position.

### 1.9 Quest order

- **How the quest module orders quests.** It lists the game's watch list in the game's order, with calling quests first **[src]** ([`BuildQuestWatchInfos`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua#L168-L197)).
- **Blizzard re-sorts on every zone change.** It calls `C_QuestLog.SortQuestWatches()` on every new zone and every map change within one **[src]** ([`OnEvent`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.lua#L23-L31)). That sorts "watched quests by proximity to the player character" ([wiki](https://warcraft.wiki.gg/wiki/API_C_QuestLog.SortQuestWatches)).
- **No API sets the order.** There is only add, remove and that sort **[src]** ([`QuestLogDocumentation.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)).
- **Campaign quests sit in their own module**, above Quests.
- **Where "zone" comes from.** The quest log groups quests under header lines (`isHeader`). Most headers are zone names; some are categories (Dungeon, Raid, class, seasonal). That header is what Kaliel's Tracker's zone filter and EQ Objective Tracker's zone headers read **[addon]**.

---

## 2. Each request

### 2.1 Zone grouping

| Option | What you'd see | Taint | Cost | Survives patches |
|---|---|---|---|---|
| **A. Re-anchor Blizzard's quest blocks under SaftUI zone headers after each layout** | Headers inside Blizzard's tracker | Low: widget calls only **[inferred]** | **L, and fragile.** Blizzard counts heights without the headers. The quest module would overlap the module below it. The background and height cap would be off by the headers' height, and Blizzard would drop blocks by its own count. Every layout, slide and fade animation, cached block and partially shown module would have to be redone after Blizzard. | Poorly: breaks with any layout change (11.0 rewrote the tracker, 11.0.7 changed it again) |
| **B. Make Blizzard's own order come out by zone** | n/a | n/a | **Not possible.** Blizzard re-sorts by distance on every zone change, and no API sets the order (§1.9). There's also no room for labels: the gap between blocks is 10 px. | n/a |
| **C. Show only this zone's quests**: auto-track the quests under the current zone's log header, untrack the others | Blizzard's tracker, listing the zone you're in, plus campaign and any quests you pin | **None** **[inferred]**: `C_QuestLog.AddQuestWatch`/`RemoveQuestWatch` are game functions, and Blizzard's own event handlers redraw. Kaliel's Tracker's "Zone" filter does exactly this ([`Filters.lua`](https://github.com/manueltollis/wow-addons/blob/main/Interface/AddOns/!KalielsTracker/Modules/Filters.lua)) **[addon]** | S–M. To decide: does "this zone" mean the log header or the map? What happens to quests you tracked by hand? Is it auto, or a button? | Good: data API only |
| **D. SaftUI's own quest list** | Real zone headers, collapsible, in any order | None, if Blizzard's tracker is left untouched underneath (§4) | **L** (§0) | Data APIs change less than Blizzard's frames |

- **Prior art for D.**
  - [EQ Objective Tracker](https://github.com/wheelbarrel00/EQObjectiveTracker) supports Forever and has zone headers (`Data/ZoneGroups.lua`: "the first sighting of a heading is its place in the quest log").
  - [KaLi Quest](https://github.com/Ikar-Rahl/Wow-KaLi-Quest) is Forever only. It has your own groups plus a Journal "by zone and kind" **[addon]**.
- **Others' view of A.** Blizzard-forum regular Gello called rearranging the blocks without taint "extremely challenging" and advised "create your own objective tracker" ([forum, 2024-07](https://us.forums.blizzard.com/en/wow/t/objective-tracker-adjustment/1889498)).

### 2.2 Max height

| Option | What you'd see | Taint | Cost |
|---|---|---|---|
| **A. Blizzard's own Height, set in Blizzard's Edit Mode** | The tracker stops 400–1000 px below its top. Objectives that don't fit are dropped, with no scroll. | **None**: Blizzard's own UI calling Blizzard's code | **S.** SaftUI hides the tracker's Edit Mode box today, so add a `/sui` button that lets Blizzard's Edit Mode select it. The slider only appears after the tracker has been moved once in Blizzard's Edit Mode (§1.3). That move makes Blizzard re-parent it to UIParent, and SaftUI's mover keeps placing it at the holder. **[game]**: check the two cooperate. |
| **B. SaftUI sets the height** (C `SetHeight`, re-applied after each of Blizzard's `UpdateHeight`) | Any height, from a `/sui` slider, under 400 included | **Unknown**: decided by **E1** (does `OnSizeChanged` run inside SaftUI's call?) | **S**, if E1 passes |
| **B′. Two anchors** (the tracker's top to the holder, its bottom to a SaftUI "floor" frame) | Same as B, and Blizzard's own `SetHeight` stops fighting it | Same unknown as B | S–M. The mover's maths assumes one anchor point. |
| **C. Write Edit Mode's saved layout** (`C_EditMode.SaveLayouts`) | A `/sui` slider for Blizzard's own Height | The save is a game call. Getting Blizzard to apply it without a `/reload` goes through Edit Mode's Lua, which would run tainted **[inferred]**. It also rewrites the account's Edit Mode layout. | M, fragile |
| **D. Clip the tracker** (`SetClipsChildren` on it) | A cut through the middle of a block | None | Useless: the clip is the tracker's own rect, which is already Blizzard's cap |

What other addons do: ElvUI's "Objective Frame Height" option is **hidden on modern clients**. It only appears for Wrath and Mists ([`General.lua` L268](https://github.com/tukui-org/ElvUI/blob/main/ElvUI_Options/Game/Shared/General.lua#L268)) **[addon]**.

### 2.3 Scroll bar

| Option | What you'd see | Taint | Cost |
|---|---|---|---|
| **A. Move Blizzard's *modules* into a SaftUI scroll frame** below the tracker's header. The tracker frame itself stays where it is. | "All Objectives" stays fixed. Quests scroll with the mouse wheel, plus a thin bar, in a window of the height you choose. Blizzard still drops what doesn't fit its own cap (≈ the column's bottom, or Height ≤ 1000), so the window must be shorter than that. | **Low–medium [inferred]**. C `SetParent` writes nothing. Modules are added once, at login, and nothing of Blizzard's re-parents them later **[src]**. They have no size script. Their `OnHide` (it ends a slide animation) must not fire from SaftUI, so re-parent only while visibility doesn't change, and out of combat (rule 4). Scrolling in combat is allowed: nothing in it is protected **[inferred]**. KaLi Quest re-parents Blizzard's modules the same way, under a hidden frame, on Forever **[addon]**. | **M**, behind a toggle |
| **[game] for A** | Whether a scrolled-out (clipped) item button or quest title **still takes clicks** where it can't be seen. Whether Blizzard's anchoring of the first module ("TOP" of its parent) and Forever's top padding come out right. | | |
| **B. The whole tracker in a scroll frame** (Kaliel's 6.x did this to its own copy) | n/a | **High.** Blizzard re-parents the tracker to the right column on every column update, and to UIParent on every Edit Mode layout apply (§1.8). SaftUI would fight it, with `OnShow` and `OnHide` running in its calls. BigWigs dropped re-parenting the 11.0 tracker after "objective tracker not showing after encounter combat" ([commit](https://github.com/BigWigsMods/BigWigs/commit/8c652057af208487e15765831b291a85c56a1451)) **[addon]**. | n/a |
| **C. A SaftUI clip frame with the tracker's anchor moved, no re-parenting** | n/a | **Not possible**: a frame only clips its own children, and the tracker isn't SaftUI's child **[inferred]** | n/a |
| **D. Own tracker** | Natural | Secure item buttons inside the scroll frame make it **protected in combat**. Protection spreads to parents (taint.md rule 6), and `SetVerticalScroll` is a protected function **[src]**. So either scrolling locks in combat (EQ: "every size and anchor call on that chain stays combat-protected"), or the buttons live outside the scroll frame: on UIParent over their rows, frozen and dimmed in combat (KaLi Quest), or in a column beside the tracker (Kaliel's) **[addon]**. | Part of L |

### 2.4 Size

- **Text size.**
  - Status: **already within reach. S, no taint.**
  - Why it works: the skin sets SaftUI's font objects on every title and line the moment Blizzard hands them out. That is before Blizzard sets the text and measures its height, so the tracker lays out in SaftUI's font.
  - The work: today the font is one of SaftUI's shared fonts. A tracker-specific size means SaftUI-owned font objects at that size.
  - Effect on Blizzard's setting: Blizzard's own Text Size (12–20) is replaced while the skin is on.
- **Line spacing.**
  - Inside a wrapped line: yes, through the font's `SetSpacing`.
  - Between objectives and between quests: **no**. Those gaps are Lua fields on Blizzard's module tables (`lineSpacing` 4, `fromBlockOffsetY` −10, `blockOffsetX` 20), and writing them taints every layout.
- **Width.**
  - **Option A: widen each module and its header** with the C `SetWidth`. The tracker frame stays 260.
    - Why it's safe: modules have no size script **[src]**, so nothing of Blizzard's runs. Texts re-flow at Blizzard's next update.
    - What changes:
      - SaftUI's holder width and its mover maths, so the tracker grows to the left instead of off the right edge.
      - SaftUI's own background, since Blizzard's stays 260.
    - Exception: the scenario module. Its widget containers mark it dirty when they resize, so leave it at 260, or prove it safe in game.
    - **S–M, low risk [inferred].**
  - **Option B: `SetWidth` on the tracker.** Same unknown as height (E1).
- **Scale.**
  - Through the tracker's own `SetScale`: **no**. That is Edit Mode's Lua, which re-lays-out the tracker tainted (§1.7).
  - Through the C `SetScale` directly:
    - Unknown whether it fires `OnSizeChanged` (**E2**).
    - Blizzard never sets the tracker's scale (this system has no scale setting **[src]**), so SaftUI's would stay.
    - The mover's maths already uses effective scale.
    - In the default spot, Blizzard's `UpdateHeight` adds the parent's height to the tracker's scaled offset, so the tracker would stop short of, or run past, the column's bottom **[inferred]**.
  - What I'd do: offer size as font, width and item size, and keep scale for later.
- **Quest item button size.**
  - **S, no taint.** Use the C `SetSize` at the moment the skin styles the button. That is in the `GetRightEdgeFrame` post-hook, which runs before `AddRightEdgeFrame` reads its width, so titles get the right room **[src]**.
  - ElvUI sets 24×24 **[addon]**.

### 2.5 Other stuff a player would want

| Idea | Feasible? One line on how |
|---|---|
| Fade out of combat, on mouse-off, or hide in combat, instances or boss fights | **Yes, S.** `SetAlpha` on the tracker: a C call, not an Edit Mode override, and allowed in combat. BigWigs hides the 11.0 tracker in boss fights this way ([`BossBlock.lua`](https://github.com/BigWigsMods/BigWigs/blob/master/Plugins/BossBlock.lua)), but not in Mythic+, nor while tracking certain achievements **[addon]**. Blizzard's column resets the alpha (§1.8), so re-apply it after Blizzard's `SetAlpha` (post-hook). An invisible tracker **still takes clicks** (BigWigs' own "XXX FIXME"), so also move it off screen with the mover's C `SetPoint`. Edit Mode never sets its clamp, so turn the clamp off first **[inferred]**. Decide what happens to a quest item you need mid-fight. |
| Auto-collapse in combat or instances (Blizzard's own collapse) | **No.** The collapse is Blizzard Lua, and a secure state driver can't click a button (the restricted frame handle has no `Click` **[src]**). A key binding that clicks the collapse button through a secure `click` proxy is possible (the rule 6 pattern) **[inferred]**. |
| Show or hide single modules (achievements, professions…) | **No** in Blizzard's tracker: removing a module taints the rest (§1.7), and alpha or re-parenting leaves its gap because the container still counts its height. **Yes** in an own tracker. |
| Hide the header or the background | Header: alpha only. Blizzard shows it on every update, and its space (the top padding) stays. Background: **yes, S.** SaftUI draws its own themed background, and Blizzard's Opacity (now unreachable) can stay 0. |
| Quest level and tags in titles | **Forever already shows them** (§1.1). On retail, adding text after Blizzard measured a title can wrap it over the next line, so only in an own tracker. |
| Percent-complete numbers | Progress bars already show it. For "3/8" lines it would mean an overlay competing with Blizzard's measured width: own tracker. |
| Progress bar style | **Done** (the skin). |
| Count in a header ("Quests 7/25") | **Yes, S.** A font string of SaftUI's on the module header (the skin already makes textures there). The count comes from `C_QuestLog`. |
| Item button on the left, or outside the tracker | **Possible, M, cosmetic gap.** Re-anchor it in a post-hook of each block's `AddRightEdgeFrame` (C `SetPoint`). Blizzard still keeps room for it on the right, and the map pin sits on the left. |
| One big "nearest quest item" button with a key | **Yes, M.** A SaftUI secure button (type `item`) for the closest quest with an item (`C_QuestLog.GetDistanceSqToQuest`), updated out of combat only. This is Kaliel's "Active button" ([`ActiveButton.lua`](https://github.com/manueltollis/wow-addons/blob/main/Interface/AddOns/!KalielsTracker/Modules/ActiveButton.lua)) **[addon]**. It doesn't touch the tracker. |
| Click behaviour (left click to super-track instead of opening the map…) | **Limited.** Blizzard's click handler can't be replaced (no `SetScript` on its frames). A SaftUI overlay could super-track safely (`C_SuperTrack` isn't protected). Opening the world map from SaftUI's code is a known taint path in combat (`SetPassThroughButtons` blocked: [DialogKey #14](https://github.com/NumyAddon/DialogKey_Numy/issues/14), [BetterWorldQuests #70](https://github.com/p3lim-wow/BetterWorldQuests/issues/70)) **[addon]**. |
| Quest tooltips (description, rewards, party progress) | **Yes, S.** Blizzard fires `EventRegistry` "OnQuestBlockHeader.OnEnter" on every quest-title hover **[src]**, and the registry runs callbacks through `secureexecuterange` ([`CallbackRegistry.lua`](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXMLBase/CallbackRegistry.lua#L184-L214)), so SaftUI's callback taints nothing **[src]**. |
| Sort by distance | **Yes, S.** Call `C_QuestLog.SortQuestWatches()` more often than Blizzard does, out of combat (Kaliel's calls it) **[inferred]**. Quests then reshuffle while you read. |
| Completed quests to the top | **No** in Blizzard's tracker (no order API). **Yes** in an own tracker. |
| A dungeon or Mythic+ layout | Restyle Blizzard's scenario module: skin work, S–M. A separate M+ timer is own-tracker work and retail only (EQ has one). |
| "Only this zone's quests" | See §2.1 C. **S–M, no taint.** |

---

## 3. What other addons do (evidence)

| Addon | Approach | What it shows |
|---|---|---|
| **Kaliel's Tracker 7.5.0** (11.0.2, Oct 2024; source from a [mirror](https://github.com/manueltollis/wow-addons/tree/main/Interface/AddOns/!KalielsTracker), since the official source isn't on GitHub) | A **forked copy** of Blizzard's whole tracker (`KT_` prefixed). It stops Blizzard's from starting (`EventRegistry:UnregisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", ObjectiveTrackerManager)`) and hides it (`Core/Main.lua`). Its copy sits in a `ScrollFrame` with `SetClipsChildren`, an 8000-high child, a max height, the mouse wheel and a 2 px indicator. **Item buttons are its own `SecureActionButtonTemplate` (type `item`) in a separate column on UIParent, made and re-anchored only out of combat.** The quest row gets a numbered tag linking it to its button. | A full replacement works, at the price of a parallel item column and no new buttons in combat. Its changelog also lists a "Tainted frames hack" and a "World Map hack": the replacement still fights taint elsewhere. Note it hides Blizzard's tracker with `Hide`, which 12.x punishes (§1.6). |
| **ElvUI** ([module](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Modules/Blizzard/ObjectiveFrame.lua), [skin](https://github.com/tukui-org/ElvUI/blob/main/ElvUI/Game/Shared/Skins/ObjectiveTracker.lua)) | On modern clients: the skin, plus auto-hide in boss and arena fights. Auto-hide re-parents the tracker to a hidden frame from a secure state driver's `OnShow`/`OnHide`. **Height and the mover exist only for Wrath and Mists.** Auto-hide is skipped when BigWigs or DBM is loaded. It also replaces `SplashFrame`'s `OnHide` "to prevent taint on the Quest Button". | The biggest UI suite offers **no height** on the modern tracker. |
| **BigWigs** ([`BossBlock.lua`](https://github.com/BigWigsMods/BigWigs/blob/master/Plugins/BossBlock.lua)) | Hides the tracker in boss fights with `SetAlpha(0)` on modern clients (re-parenting only on Classic). The switch came in 2024-08 ([commit](https://github.com/BigWigsMods/BigWigs/commit/8c652057af208487e15765831b291a85c56a1451)). It doesn't hide in Mythic+. | Alpha is the safe hide. Clicks still go through ("XXX FIXME"). |
| **EQ Objective Tracker** ([repo](https://github.com/wheelbarrel00/EQObjectiveTracker); supports **Forever**) | A full replacement. Zone headers come from quest log headings. Secure item buttons (type `item`) are anchored to the container, never to the row, "or Show, Hide and SetPoint on the row … blocked in combat". Blizzard's tracker gets alpha 0, `Hide`, and **every module removed**, so its layout never runs. The reason given: a hidden tracker's layout ran tainted and hit the secret-aura error ([`UI/Blizzard.lua`](https://github.com/wheelbarrel00/EQObjectiveTracker/blob/main/UI/Blizzard.lua)). | The 12.x/Forever failure mode, documented. Its README says retail-only sections "have stayed empty" on Forever. |
| **KaLi Quest** ([repo](https://github.com/Ikar-Rahl/Wow-KaLi-Quest); **Forever only**, 0.1.0-dev) | Draws its own rows: your own groups, plus a Journal by zone and kind. It keeps Blizzard's tracker as the host, for Edit Mode and the timer panel, and parks its modules under a hidden frame with `SetParent`. **Item buttons sit on UIParent over each row's slot**, follow rows out of combat, and freeze and dim in combat ([`UI/Items.lua`](https://github.com/Ikar-Rahl/Wow-KaLi-Quest/blob/main/KaLiQuest/UI/Items.lua)). "If … a tracker section it doesn't draw fills, Blizzard's tracker comes back." | The closest model for SaftUI's own list on Forever, with the fallback to Blizzard's. Early version. |
| **Aura Questor** ([`BlizzardTracker.lua`](https://github.com/lucascodev/aura-questor/blob/main/Source/Game/BlizzardTracker.lua)) | A full replacement. Blizzard's tracker gets "alpha and mouse input only. Hide, SetScale and SetPoint are blocked or taint-prone … that is what broke Carrot Objective Tracker on 12.1", plus parked modules. It notes that Blizzard's right column sets the alpha back after cinematics and vehicles. | Same lesson as EQ |
| **Carrot Objective Tracker** ([changelog](https://www.curseforge.com/wow/addons/carrot-objective-tracker/files/7951634)) | Hid Blizzard's tracker with `SetScale(0.001)`, which tainted. Then used alpha only, and deferred its re-hide out of Blizzard's `Show` hook with `C_Timer.After(0)`. | `SetScale` on the tracker taints. Hooks that change Blizzard's frame from inside Blizzard's call are risky. |
| **Others** | [QuestLogCollapse #23](https://github.com/ChadAPSheridan/QuestLogCollapse/issues/23) and [#32](https://github.com/ChadAPSheridan/QuestLogCollapse/issues/32): calling modules' `SetCollapsed` and writing fields onto `ObjectiveTrackerFrame` caused blocked `Show` and secret-width errors. [HideTrackerForever](https://github.com/jrpbuilds/HideTrackerForever) (Forever) hides with `Hide` plus an `OnShow` hook, the pattern that broke ForeverQuestTracker. | |

---

## 4. Recommendation

### 4.1 Order of work

0. **The baseline first.** Followup check 1 (a quest item used in combat with today's skin, taint log on) has no report yet. Everything below assumes it passes.
1. **Taint-free now, S each:**
   - the tracker's own text size;
   - quest item button size;
   - a count in each header;
   - SaftUI's own background;
   - quest tooltips;
   - fades by alpha (out of combat, mouse-off, boss fights), with the off-screen move for clicks.
   - Optionally: "only this zone's quests" (§2.1 C), and a nearest-quest-item button (§2.5).
2. **One in-game session for the experiments** (§4.2): E1, E2, E4.
3. **Height.** If E1 passes, a `/sui` Max height slider (any value). If not, Blizzard's own Height through Blizzard's Edit Mode (§2.2 A, minimum 400).
4. **Width:** widen the modules (§2.4), leaving the scenario module alone until checked.
5. **Scroll:** move the modules into a SaftUI scroll frame, behind a toggle, and ship only if E3 is clean.
6. **Zone grouping:** if it still matters, a design round for SaftUI's own quest list (§0).
   - Forever first. The case for SaftUI's own list is stronger there: retail-only sections stay empty on Forever (EQ's README) **[inferred]**.
   - Blizzard's tracker stays untouched underneath (concealed by alpha and off-screen, never hidden or unmounted). It comes back whenever a section SaftUI doesn't draw has content, as KaLi Quest does.
   - **Never a hybrid** that pulls Blizzard's quest modules out of its container: the rest of its layout would run tainted.

### 4.2 In-game experiments (decisive ones first)

- **E1. Does a size change made by SaftUI run Blizzard's `OnSizeChanged` inside SaftUI's call?** This decides max height (B), width on the tracker, and scale (B).
  1. `/console taintLog 1`, then `/reload`.
  2. `/run local f=ObjectiveTrackerFrame; getmetatable(f).__index.SetHeight(f, f:GetHeight(true)-40); print("now", issecurevariable(f,"dirty"))`
  3. `/run print("later", issecurevariable(ObjectiveTrackerFrame,"dirty"))`
  4. Both print `true` (or `nil`/`true`): the game ran the script later, untainted, so SaftUI may size the tracker. Confirm by using a quest item in combat and checking `Logs/taint.log`.
  5. `now false`: it ran inside the call, so options B are out.
  6. **`/reload` afterwards** either way: the test itself may taint the tracker for the session.
- **E2. The same for scale:** `getmetatable(f).__index.SetScale(f, 0.9)`, the two prints, then set it back to 1 and `/reload`.
- **E3. Modules in a scroll frame** (needs a dev build).
  - After a layout, `issecurevariable(QuestObjectiveTracker, "isDirty")` is `true`.
  - An item used in combat works.
  - Clicking where a scrolled-out item button or title would be does nothing.
  - The first module lines up under the header, on Forever too.
- **E4. Blizzard's own Height while SaftUI anchors the tracker.** Let Blizzard's Edit Mode select it, move it once, and set Height 400. The tracker should stop 400 below SaftUI's holder and stay on the holder after `/reload`.
- **E5. Forever's quest titles.** Check whether the level prefix is already shown (§1.1).

### 4.3 What I wouldn't do

- Re-anchor Blizzard's blocks to fake zone headers (§2.1 A).
- Re-parent the tracker itself (§2.3 B).
- Call any of Blizzard's tracker methods.
- Write any field on its modules (the spacing).
- Hide it with `Hide`/`Show`.
- Scale it through its own `SetScale`.

---

## 5. Questions for you before a design

1. **Zone grouping.** How much is it worth?
   - Enough for SaftUI to draw its own quest list, with these regressions: a quest item picked up mid-fight has no button until the fight ends, and item buttons don't follow their rows in combat?
   - Or is "show only the quests of the zone I'm in" (Blizzard's tracker, auto-tracking) enough?
2. **If SaftUI's own list:** quests only, with Blizzard's tracker coming back for scenarios, dungeons and the rest? Or everything? Forever only, or retail too?
3. **What a "zone" is.**
   - The quest log's headers, which include Dungeon, Raid, Class and seasonal headers? Or the map zone?
   - Current zone first? Collapsible headers? Campaign quests separate?
4. **Max height.** Should what's past it scroll, or just be cut (Blizzard drops it)? Is a 400 px minimum (Blizzard's Height) acceptable? Should the cap be a number, or "down to a frame" (e.g. above the action bars)?
5. **Scroll.** Mouse wheel only, or a visible bar? Must it scroll in combat?
6. **Size.** Do you want everything bigger or smaller, item and map-pin icons included (scale)? Or wider text with your own font size (width and font)?
7. **Item button.** Keep it on the right inside the tracker, move it outside the edge, or add one big "nearest quest item" button with a key?
8. **Fades and hiding.** Which triggers: out of combat, mouse-off, in combat, instances, boss fights, Mythic+? While hidden, must quest items still be usable?
9. **Experiments.** Can you run E1, E2 and E4 in one session (taint log on, a few `/run` lines, then a `/reload`)?

---

## Sources

**Blizzard's source** (Gethe/wow-ui-source, `forever` = 1.60.1.70938, `live` = 12.1.5.70783):

- Tracker files:
  - [ObjectiveTrackerContainer.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua)
  - [ObjectiveTrackerModule.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerModule.lua) and [.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerModule.xml)
  - [ObjectiveTrackerManager.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerManager.lua)
  - [ObjectiveTrackerBlock.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerBlock.lua)
  - [ObjectiveTrackerShared.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerShared.lua) and [.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerShared.xml)
  - [QuestObjectiveTracker.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua)
  - [ObjectiveTracker.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.lua) and [.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.xml)
  - [ScenarioObjectiveTracker.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ScenarioObjectiveTracker.lua)
  - [Camelot override](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Camelot/Blizzard_QuestObjectiveTrackerOverride.lua)
  - Retail copies under [`live`](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_ObjectiveTracker)
- Edit Mode: [EditModeSystemTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua), [EditModeSettingDisplayInfo.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSettingDisplayInfo.lua)
- [ManagedFrameSystem.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ManagedFrameSystem/Shared/ManagedFrameSystem.lua)
- [MixinUtil.lua (DirtiableMixin)](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/MixinUtil.lua#L337-L352)
- [CallbackRegistry.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXMLBase/CallbackRegistry.lua)
- [RestrictedFrames.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua)
- [Camelot QuestUtilsOverrides.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/QuestUtilsOverrides.lua)
- API docs: [QuestLog](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua), [SimpleFrame](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua), [SimpleScrollFrame](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScrollFrameAPIDocumentation.lua), [SimpleScriptRegion](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua), [EditModeManager](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/EditModeManagerDocumentation.lua)
- [11.0.7 item button change](https://github.com/Gethe/wow-ui-source/commit/ec9e859b83c8c21c65b609556ff74fe5282f6184)

**Wiki and forum:**

- [warcraft.wiki.gg: C_QuestLog.SortQuestWatches](https://warcraft.wiki.gg/wiki/API_C_QuestLog.SortQuestWatches)
- [Blizzard forum: Objective Tracker Adjustment (Gello)](https://us.forums.blizzard.com/en/wow/t/objective-tracker-adjustment/1889498)

**Addons:**

- [Kaliel's Tracker 7.5.0 mirror](https://github.com/manueltollis/wow-addons/tree/main/Interface/AddOns/!KalielsTracker)
- [ElvUI](https://github.com/tukui-org/ElvUI)
- [BigWigs BossBlock](https://github.com/BigWigsMods/BigWigs/blob/master/Plugins/BossBlock.lua)
- [EQ Objective Tracker](https://github.com/wheelbarrel00/EQObjectiveTracker)
- [KaLi Quest](https://github.com/Ikar-Rahl/Wow-KaLi-Quest)
- [Aura Questor](https://github.com/lucascodev/aura-questor)
- [Carrot Objective Tracker changelog](https://www.curseforge.com/wow/addons/carrot-objective-tracker/files/7951634)
- [HideTrackerForever](https://github.com/jrpbuilds/HideTrackerForever)

**Issues:**

- [PetTracker #395](https://github.com/Jaliborc/PetTracker/issues/395), [#406](https://github.com/Jaliborc/PetTracker/issues/406)
- [Todoloo #52](https://github.com/Todoloo-WoW/Todoloo/issues/52)
- [ElvUI_WindTools #529](https://github.com/wind-addons/ElvUI_WindTools/issues/529)
- [AngrierWorldQuests #86](https://github.com/GurliGebis/WoWAddon-AngrierWorldQuests/issues/86)
- [WoWUIBugs #882](https://github.com/Stanzilla/WoWUIBugs/issues/882)
- [ForeverAddons-Issues #2](https://github.com/Forever-Addons/ForeverAddons-Issues/issues/2)
- [QuestLogCollapse #23](https://github.com/ChadAPSheridan/QuestLogCollapse/issues/23), [#32](https://github.com/ChadAPSheridan/QuestLogCollapse/issues/32)
- [DialogKey #14](https://github.com/NumyAddon/DialogKey_Numy/issues/14)
- [BetterWorldQuests #70](https://github.com/p3lim-wow/BetterWorldQuests/issues/70)
