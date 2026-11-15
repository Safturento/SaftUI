# SaftUI's own objective tracker

Design, 2026-11-14. It rests on the study `docs/research/2026-11-14-objective-tracker-enhancements.md`
(called "the study" below): what Blizzard's tracker is on both clients, what is safe to do to it, and
what other tracker addons do. The owner read the study's summary and chose this route. This design is
not yet approved as written: every decision below that the owner didn't make is marked **call** and
listed again at the end, under "Calls made while writing this".

Checked against Blizzard's source for **Forever 1.60.1 (70938)** and **retail 12.1.5 (70783)**
(Gethe/wow-ui-source, branches `forever` and `live`), as the study was. "Re-checked in Blizzard's
source" below lists what this design depends on that the study marked inferred, and what the source
says.

## Why

SaftUI skins Blizzard's objective tracker and moves it (`SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua`
and `Blizzard_ObjectiveTrackerPosition.lua`). The owner asked for more than a skin can give: "zone
grouping, objective status coloring, is it possible to set a max height and a scroll frame on it?"
Status colors are built. The study found that zone grouping, any order, hiding single sections and a
scrolling list can't be had from Blizzard's tracker without running its layout tainted, and a tainted
layout breaks the quest item buttons in combat (taint.md rule 5) and, since 12.x and on Forever, can
freeze the whole tracker in a dungeon (study §1.6). Only a tracker SaftUI draws itself can do them.

The price, which the owner accepted, is that SaftUI's tracker has to rebuild what Blizzard's shows,
and its quest item buttons live under the game's combat rules for secure buttons. This design keeps
Blizzard's tracker alive, untouched and off screen, and hands back to it whenever it has something
SaftUI doesn't draw yet, so the player loses nothing while the rest is rebuilt in phases.

## What the owner decided

1. **Build SaftUI's own tracker.** After reading the study's summary: "Definitely worth it, lets make
   a separate traacker - that'll give us freedom to improve in any other way we want going forward."
2. **Hide Blizzard's tracker while SaftUI's is on:** "lets hide the blizzard tracker when the saftui
   one is enabled".
3. **A visible scroll bar, shown under the mouse:** "I think we should have a visible bar, maybe have
   it hidden when not mousing over the tracker?"
4. **Width and height, not scale:** "for size just a height and width adjustment, not scaling."
5. **Item buttons by a setting:** "item buttons we can have a setting with different options." The
   study's options: inside the row on the right; outside the tracker's edge; one big "nearest quest
   item" button with a keybind.
6. **Fading and hiding by every trigger:** "Fading/hiding lets just give options for everything." The
   study's triggers: out of combat, mouse-off, in combat, in instances, boss fights, Mythic+.
7. **The controller's proposals, all accepted** ("all of that sounds good to me"):
   - zones are the quest log's own headers, the current zone first, headers collapsible;
   - the two combat limits of any own tracker: a quest item picked up mid-fight gets its button when
     combat ends, and buttons stay where they were during combat rather than following their rows;
   - the owner's client (Forever, interface 16001) first, retail following;
   - Blizzard's tracker is never pulled apart or mixed with SaftUI's.
8. **In-game tests on request:** "if you need me to test anything in game let me know".
9. **Carried over from earlier requests:** the objective status colors, finished and failed, already
   built for the skin ("reuse the settings"); the mover covering the tracker's full height ("I'd also
   love the mover to fill the full height of the tracker not just the header."); and zone grouping, a
   max height and a scroll frame.

## Goals

- Quests grouped under the quest log's headers, the zone you're in first, each group collapsible.
- A tracker as wide and as tall as the player sets, scrolling past its height, with a bar under the
  mouse.
- Quest item buttons that work in combat, in the placement the player picks, plus a keybound
  "nearest quest item" button.
- Fading and hiding by combat, mouse, instance, boss fight and Mythic+, each its own option.
- Nothing a player sees in Blizzard's tracker today missing at any phase: what SaftUI doesn't draw
  yet, Blizzard's own tracker shows.
- The same on Forever and retail, guarded by feature checks; Forever checked first.
- SaftUI's look: the theme, its Background, whole pixels, Lucide icons with tooltips, per-setting
  resets.

## Non-goals

- Rebuilding scenarios, dungeons, delves, Mythic+, bonus objectives, world quests, achievements,
  recipes, monthly activities, endeavors, collection tracking or zone widgets in version one. They
  come in the named phases (Phasing, below); until then Blizzard's tracker shows them.
- Scale (the owner: "not scaling").
- Manual drag ordering, pinned quests, quest type filters, a to-do mode, a zone progress bar, tabs:
  the features EQ Objective Tracker has. The tracker is built so they can come later.
- Showing quests the player doesn't track (an automatic "this zone's quests" list). See Questions.
- The find-group button on group quests, the quest POI map integration beyond focusing, gamepad
  navigation, Blizzard's slide, fade and flash animations.
- Any change to how quests get tracked: the watch list stays the game's, so the map, the quest log's
  check boxes and Blizzard's auto-track on accept all keep working.

## Anti-goals

What would make this a failure even if it works:

- **Any taint of Blizzard's tracker or its quest items.** No call SaftUI makes may run a line of
  Blizzard's tracker Lua or Edit Mode Lua, or write a field Blizzard reads.
- **An item button that fails in combat**, or one that is invisible but still takes clicks.
- **Lost information:** a section with content that neither tracker shows, or a quest the player
  tracks that SaftUI leaves out.
- **A tracker that stutters** when the quest log updates many times a second.
- A SaftUI frame that turns protected in combat because a secure button is its child (the window, the
  scroll frame), so it can no longer move, size or scroll.
- Two trackers listing the same quests without the player asking for it.

## Re-checked in Blizzard's source

What this design depends on that the study marked inferred, or didn't cover, read again in both
branches:

| Claim | Where | Found |
| --- | --- | --- |
| Turning the tracker's clamp off is needed to move it off screen, and nothing turns it back on | `Blizzard_EditMode/Shared/EditModeSystemTemplates.xml`: `EditModeSystemTemplate` has `clampedToScreen="true"`; no `SetClampedToScreen` call in the tracker's files, `EditModeSystemTemplates.lua` or `EditModeManager.lua` | **Confirmed.** Set once by the XML, never by Lua. |
| Edit Mode overrides only some methods | `EditModeSystemMixin:OnSystemLoad` and `SetupVisibilityFunctionOverrides` | `SetScale`, `SetPoint`, `ClearAllPoints`, `SetShown`, `Hide` are Lua overrides. `SetAlpha`, `SetClampedToScreen`, `EnableMouse` and `Show` are the plain C methods. |
| `SetClampedToScreen`, `EnableMouse` are protected | `SimpleFrameAPIDocumentation`, `SimpleScriptRegionAPIDocumentation` | Both are protected functions, blocked only on a protected frame in combat. Blizzard's tracker isn't protected (no secure template, study §1.6). SaftUI's secure buttons are. |
| Blizzard's tracker auto-tracks accepted quests and sorts the watch list | `ObjectiveTrackerFrameMixin:OnEvent` (`Blizzard_ObjectiveTracker.lua`) | **Confirmed**, and it matters: `QUEST_ACCEPTED` adds the quest to the watch list (with `autoQuestWatch` on, under the 25 limit), and `ZONE_CHANGED_NEW_AREA` and a map change call `C_QuestLog.SortQuestWatches()`. Both keep working only while the tracker keeps its events, which is why SaftUI never unregisters them. |
| The tracker shows and hides itself | `ObjectiveTrackerContainerMixin:Update` | It calls its own `Show` when a module displays and `Hide` when none does (outside Edit Mode). Its `OnShow` runs `UpdateHeight`. Blizzard's own calls, untainted while SaftUI never calls them. |
| A module's state says whether it has content, except when it got no room | `ObjectiveTrackerModuleMixin:Update`, `ObjectiveTrackerModuleState` | States `Skipped`, `NoObjectives`, `NotShown`, `ShownPartially`, `ShownFully`. A module the height budget never reached is `Skipped` whatever it holds, so its state can't be trusted alone (below). Scenario and Bonus objectives have `hasDisplayPriority`. |
| The container's dirty update can't be hooked through its `Update` field | `ObjectiveTrackerContainerMixin:OnLoad`: `SetDirtyMethod(GenerateClosure(self.Update, self, dirtyUpdate))` | The closure holds the function itself, so a hook on `ObjectiveTrackerFrame.Update` misses dirty updates. Each module's `Update` is looked up at call time (`module:Update(...)`) and can be post-hooked. |
| The right column sets the tracker's alpha and parent | `ManagedFrameSystem.lua` | `UpdateFrame` re-parents it to the column; `AnimOutManagedFrames` and `AnimInManagedFrames` set its alpha 0 and 1. SaftUI re-applies after Blizzard (Fading, below). |
| The quest log lists quests under collapsed headers | `QuestLogQuests_BuildSingleQuestInfo` (`QuestMapFrame.lua`) | **Confirmed.** `C_QuestLog.GetInfo` returns every entry; a quest's header is the last header line above it, collapsed or not. `C_QuestLog.GetHeaderIndexForQuest(questID)` gives it directly (both clients). |
| Quest APIs and their secret values | `QuestLogDocumentation`, `SuperTrackManagerDocumentation`, `QuestTaskInfoDocumentation`, `ScenarioInfoDocumentation` | The same on both clients but for two Forever-only functions, `C_QuestLog.IsEliteQuest` and `C_QuestLog.GetQuestTimers`. No quest function marks a return secret; their arguments are `AllowedWhenUntainted` (SaftUI passes none secret). The only secret return in these is the scenario's `GetUnitCriteriaProgressValues` (phase 3). |
| The probes' APIs exist on both clients | API docs | `C_TradeSkillUI.GetRecipesTracked`, `C_PerksActivities.GetTrackedPerksActivities`, `C_NeighborhoodInitiative.GetTrackedInitiativeTasks`, `C_ContentTracking.GetTrackedIDs`, `C_ChallengeMode.IsChallengeModeActive`, `C_Minimap.IsInsideQuestBlob`, `C_UIWidgetManager.GetObjectiveTrackerWidgetSetID`: all on both. Whether Forever's servers ever fill them is a game question (experiment P4). |
| The zone widget count is a read | `UIWidgetContainerMixin:GetNumWidgetsShowing` (`Blizzard_UIWidgetManager.lua`) | `return self.numWidgetsShowing or 0`: a read, safe to call. |
| The scenario's layout reads a secret aura | `ScenarioObjectiveTrackerMixin:LayoutContents` | Calls `ShouldShowMawBuffs()` on every layout. SaftUI never calls it (it errors from tainted code in combat). |
| A secure `item` button uses an item by link | `SECURE_ACTIONS.item` (`SecureTemplates.lua`), `SecureCmdItemParse`, `SecureCmdUseItem` | A link or `item:ID` goes to `C_Item.UseItemByName`. **An equippable item is equipped, not used** (`C_Item.IsEquippableItem` check). Blizzard's button uses `UseQuestLogSpecialItem` instead. |
| The watch limit | `QuestConstantsDocumentation` | `Constants.QuestWatchConsts.MAX_QUEST_WATCHES` is 25 on both clients. |
| Forever's titles | `Camelot/Blizzard_QuestObjectiveTrackerOverride.lua`, `Blizzard_FrameXMLUtil/Camelot/QuestUtilsOverrides.lua` | Forever's tracker adds a tag ("(Elite)", "(Dungeon)", "(PvP)", "(Raid)") and runs `SetQuestTitleLevelAndDifficultyColor`; Camelot's `GetQuestTitlePrefix` always gives "[level] " with "+" for elite. Where `SetQuestTitleLevelAndDifficultyColor` is defined wasn't found in the files read, so whether Blizzard's title shows the prefix stays inferred (study E5). It no longer matters: SaftUI builds its own titles (Quest rows). |
| Blizzard's click and menu | `QuestObjectiveTrackerMixin:OnBlockHeaderClick` | Listed under Clicks, below. |
| `QuestMapFrame_OpenToQuestDetails` from addon code | BetterWorldQuests #70 (study §2.5) | Its ping acquires a map pin, whose `SetPassThroughButtons` is blocked when that runs tainted in combat. Whether a tainted open out of combat leaves the map's pins tainted for later is not known: experiment P5. |

## Where it lives

### A new addon: SaftUI-Tracker

The tracker is its own addon, `SaftUI-Tracker`, as SaftUI-Loot is: each SaftUI addon owns one area of
the UI, and this one is several thousand lines once its phases land (the open-source replacements are
330 KB to 1.1 MB of Lua, study §0). A module of SaftUI-Misc would bury it among the skins. **Call.**

- **TOC.** One `SaftUI-Tracker.toc` listing both clients (`## Interface: 120000, 16001`), as every
  addon but Core and Unitframes has: nothing in it differs by client at load; the differences are
  feature checks at run time. `## RequiredDeps: SaftUI-Core`, `## OptionalDeps: SaftUI-Misc` (so Misc,
  when present, loads first), `## Group: SaftUI-Core`, title `|cff00adefSaftUI Tracker|r`. **Call.**
- **`Bindings.xml`** at the folder's root (the game reads it without a TOC line): one binding,
  `CLICK SaftUITrackerNearestItem:LeftButton`, header `SAFTUI`, category `BINDING_HEADER_SAFTUI` (so Key Bindings lists it in a section titled SaftUI); the strings
  `BINDING_HEADER_SAFTUI = 'SaftUI'` and the binding's name, "Use the nearest quest item", are set in
  `config.lua`.
- **Module** `Tracker` (`st:NewModule('Tracker')`), profile key `tracker` (`st.defaults.tracker`,
  defined in `config.lua` at file load), per-character data in `st.config.char.tracker`. Its `/sui`
  page is "Tracker", in the sidebar's Info group.
- **Files** (the builder may split or merge; the pure parts stay apart so tests can load them):
  `config.lua` (defaults, binding strings), `init.lua` (module, events, the refresh), `model.lua`
  (reads the game into a plain table: pure over the API), `groups.lua` (zone groups and order: pure),
  `layout.lua` (row placement math: pure), `probes.lua` (which sections have content), `blizzard.lua`
  (Blizzard's tracker: concealing it and the handover), `window.lua` (the window, header, scroll),
  `rows.lua` (the row pools and drawing), `items.lua` (the secure item buttons), `nearest.lua` (the
  nearest item button), `visibility.lua` (fading and hiding: a pure resolver and its applier),
  `clicks.lua` (clicks, menu, tooltips), `options.lua` (the page).
- The owner links the folder into both flavors' `Interface/AddOns` with `mklink /D`, as the others.

### The skin and the mover of Blizzard's tracker stay in SaftUI-Misc

They keep their job for players who turn SaftUI's tracker off, and the skin keeps styling Blizzard's
tracker whenever it shows during a handover (below). Their settings stay separate from the tracker's,
except the two status colors, which move to Global settings (below). **Call.**

What changes in them:

- **The mover stands down while SaftUI's tracker owns Blizzard's.** `OTP:PlaceTracker`,
  `OTP:KeepInMargin`, `OTP:UpdateFootprint` and `OTP:CapturePosition` return at once while
  `st:GetModule('Tracker', true)` exists and says it owns Blizzard's tracker (a read at call time; Misc
  never loads anything of SaftUI-Tracker's). The mover's `isDisabled` returns true then, so its
  outline shows only under Show disabled, and its Position option is disabled with the reason
  "SaftUI's tracker is on (Tracker page): Blizzard's tracker shows in its place when it's needed."
- **Renamed** so the two pages read apart: the page "Objective tracker" becomes **"Blizzard's
  tracker"**, its desc "Blizzard's objective tracker: its fonts, and its place while SaftUI's tracker
  is off. Its fonts also style it while it fills in for SaftUI's (Tracker page).", and the mover's
  label "Objective Tracker" becomes "Blizzard's tracker". The Skinning page's toggle keeps its name.
  **Call.**
- **Its Objective colors section goes** (moved, below), replaced by a description row: "Finished and
  failed objectives take Global settings > Colors > Objectives."

Without SaftUI-Misc, SaftUI-Tracker conceals Blizzard's tracker the same way on its own (it installs
the post-hooks itself; nothing else places the tracker then), and a handover shows Blizzard's tracker
in Blizzard's look.

### The switch

**SaftUI's tracker** (`tracker.enable`), first on the Tracker page's General tab. Read once, at login:
its `set` saves, then asks "SaftUI's tracker changes after a reload. Reload now?"
(`st.OptionsWidgets.Confirm`, Yes runs `ReloadUI`), as Nameplates does. Off, SaftUI-Tracker builds no
frame, registers no mover, hooks nothing, and Blizzard's tracker behaves exactly as today. **Call.**

**Default: off in the build that lands; the owner flips it to on once the in-game checks pass, before
anyone else gets it.** It replaces a working tracker on every SaftUI install, and the parts that
decide whether it's safe (the secure buttons, the concealment) can only be confirmed in game. Off,
landing it changes nothing for anyone until the owner turns it on and runs the checks; flipping the
default is then a one-line change. **Call.**

**Standing down.** While another tracker addon is loaded, SaftUI's tracker builds nothing and the
page's switch is disabled with "Quests are tracked by <name>. Turn it off to use SaftUI's.", as the
nameplates stand down (`UF:NameplateAddon`). The list, by folder name: `!KalielsTracker`,
`EQObjectiveTracker`, `KaLiQuest`, `AuraQuestor`, `ForeverQuestTracker`. Kaliel's, EQ and Aura
Questor's names are their repositories'; KaLi Quest's and ForeverQuestTracker's are unconfirmed, as
Platynator's is for the plates. **Call.**

### The objective colors move to Global settings > Colors

Both trackers color the same lines, so the two colors move to where SaftUI keeps colors that several
frames share: a new group **Objectives** on the Colors tab (`SaftUI-Core/Media/colors.lua`), with
**Completed** and **Failed**, defaults as today (`CreateColor(0.251, 0.753, 0.251)` and
`CreateColor(220/255, 100/255, 100/255)` in `st.defaults.colors.objectives`), each with its own reset
like every color there. A change runs `st:ColorsChanged('objectives')`; the skin (through
`SK:OnColorsChanged`) and the tracker recolor their lines. **Call.**

The skin's `OT:StatusColor` reads `colors.objectives[state]` (a color object, so `:GetRGB()`). OTP
converts the old saved values once: in `OTP:OnEnable` after `st:BindModuleConfig`, and at the start of
`OTP:UpdateConfig`, if `objectivetracker.status_colors` holds saved values and the marker
`objectivetracker.colorsMoved` isn't set, it copies them into `colors.objectives`, filling any slot
AceDB didn't save from the old defaults (AceDB keeps only the slots that differed), clears
`status_colors` and sets the marker. The `status_colors` default leaves `SaftUI-Misc/config.lua`.

## Blizzard's tracker while SaftUI's is on

### Concealed, never hidden

Blizzard's tracker stays loaded, registered, shown when it has content and laying out on its own
events, exactly as without SaftUI. SaftUI only moves it off screen. That keeps everything Blizzard's
tracker does untainted, keeps its own item buttons working for when it comes back, and keeps its two
jobs nothing else does: auto-tracking an accepted quest and sorting the watch list by distance on
every zone change (re-checked above). Its sounds keep playing too.

How SaftUI conceals it (the study's recommendation, made exact):

- **Off screen by its one anchor.** Its top right corner goes where it would go when revealed (below),
  moved left until its right edge is 100 left of UIParent's left edge. Only the x offset changes, so
  in Blizzard's default position its height, which Blizzard works out from its anchor's y offset
  (`UpdateHeight`), stays what it would be when revealed. Anchored to its own parent (UIParent, or the
  right column in its default position) by `TOPRIGHT`, never to a SaftUI frame, as OTP does today
  (`.agents/edit-mode.md`: Blizzard's Edit Mode can record the anchor).
- **Clamp off while concealed**, so the game doesn't pull it back on screen; back on when revealed.
- **Only C widget methods**, called through `getmetatable(frame).__index`: `ClearAllPoints` and
  `SetPoint` (`st:ClearAllPointsDirect`, `st:SetPointDirect`) and `SetClampedToScreen`. None of them
  runs Lua, writes a field or changes the tracker's size or visibility, so none fires a script.
- **Kept there** by post-hooks (`hooksecurefunc`) on the tracker's own `SetPoint`, `ClearAllPoints`
  and `UpdateHeight`, the three OTP hooks today: after each of Blizzard's re-places, SaftUI puts it
  back where its state says, skipping the call when its one point is already that (OTP's `PlacedAt`).
  Each hook runs in `xpcall` to `geterrorhandler()`.
- **Its Edit Mode box stays hidden** (`st:HideEditModeSelection`), so Blizzard's Edit Mode can't
  select or drag it.
- No alpha change and no mouse change are needed: off screen, nothing of it can be seen or clicked,
  and its rewards toasts hang from its blocks. (Alpha alone would leave it taking clicks; BigWigs'
  "XXX FIXME", study §3.)

The corner math is OTP's (`OTP:PlaceTracker`: the target corner in screen pixels, less the parent's,
over the tracker's effective scale, rounded with `st:RoundToPixel`); the builder moves it into a Core
helper both use rather than copying it (name left to the builder).

### What SaftUI must never do to Blizzard's tracker

Each of these runs Blizzard's Lua in SaftUI's call, writes state Blizzard reads, or changes the
tracker's visibility or size, and so taints its layout (study §1.7):

- `Show`, `Hide`, `SetShown` (Edit Mode overrides, and `OnShow` runs `UpdateHeight`, which sizes it
  and marks its layout dirty). The study records another addon, ForeverQuestTracker, breaking the
  tracker in combat on the owner's client by hiding it this way; EQ's own comment on the same
  approach: "This stops the LAYOUT, never the taint."
- `SetParent` (a visibility change and a fight with the right column, which re-parents it).
- `SetScale`, `SetSize`, `SetWidth`, `SetHeight` (Edit Mode's override; `OnSizeChanged` marks it
  dirty).
- `SetRolesets` or `AddRoleset` (taint.md rule 8 allows it only for a frame off screen, and taking it
  back would change its visibility).
- `UnregisterEvent` or `UnregisterAllEvents` on it or its modules (auto-track and the distance sort
  live there).
- `RemoveModule`, `SetModuleContainer`, `RemoveAllModules`, `MarkDirty`, `Update`, `UpdateHeight`,
  `SetCollapsed`, `ToggleCollapsed`, `Collapse`, `Expand`, `ForceExpand`, `SetOpacity`, `SetTextSize`,
  or any other method of the tracker, its modules or `ObjectiveTrackerManager`.
- Writing any field on them.
- Reading its rect (`GetRect`, `GetLeft`, `GetTop`, `IsMouseOver`...): a rect resolve can run a
  pending `OnSizeChanged` inside SaftUI's call (taint.md rule 5). Only `GetPoint`, `GetNumPoints`,
  `GetParent`, `GetWidth(true)` and `GetHeight(true)` are read.
- Calling `ShouldShowMawBuffs` or anything else that reads aura data.

Allowed, and nothing else: the three C methods above, `SetAlpha` through the C method during a
handover that fades (Fading, below), the post-hooks named in this design, reading module fields
(`state`, `hasContents`), `ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing()`, and
`st:HideEditModeSelection`. A test scans SaftUI-Tracker's files for anything else (Testing).

### Which sections SaftUI draws, and which hand over

What Blizzard's tracker shows, by module (`ObjectiveTrackerManager:Init`, both clients), and what
SaftUI does with each:

| Section | Blizzard's module | Version one | Phase that draws it |
| --- | --- | --- | --- |
| Quests, campaign quests, callings, auto quest popups | `QuestObjectiveTracker`, `CampaignQuestObjectiveTracker` | **SaftUI draws them**, by zone | 1 |
| Bonus objectives | `BonusObjectiveTracker` | Hands over | 2 |
| World quests | `WorldQuestObjectiveTracker` | Hands over | 2 |
| Scenarios, dungeons, delves, proving grounds, warfronts, the Maw | `ScenarioObjectiveTracker` | Hands over | 3 |
| Mythic+ (a scenario of the challenge mode type) | `ScenarioObjectiveTracker` | Hands over | 3, its timer and key panel 4 |
| Achievements | `AchievementObjectiveTracker` | Hands over | 5 |
| Professions (tracked recipes) | `ProfessionsRecipeTracker` | Hands over | 5 |
| Monthly activities (Traveler's Log) | `MonthlyActivitiesObjectiveTracker` | Hands over | 5 |
| Endeavors (neighborhood initiative tasks) | `InitiativeTasksObjectiveTracker` | Hands over | 5 |
| Collection tracking (appearances, mounts, decor) | `AdventureObjectiveTracker` | Hands over | 5 |
| Zone widgets | `UIWidgetObjectiveTracker` | Hands over | 6 |
| Anything a later patch adds | a module SaftUI doesn't know | Hands over | none |

**Version one draws every quest the owner's client tracks**: every quest on the game's watch list
that Blizzard's quest and campaign modules would show (they share one rule: not a task, not a bounty
unless complete, not disabled for the session, not hidden), of every kind Forever has (normal, elite,
dungeon, raid, PvP, group, daily and weekly, class, timed, escort, auto-complete, failed,
sequenced), plus the auto quest popups that Blizzard's quest module draws above them. Campaign quests
and callings are watched quests too, so Blizzard's campaign module is covered.

**Which sections exist on Forever.** Forever loads every module (its tracker has the same files as
retail's, plus one quest override), and every API they read is in its API docs. Whether Forever's
servers ever fill them is not in the source. EQ Objective Tracker, tested on Forever "from Forever's
beta through its launch", says "The retail-only sections, such as world quests and scenarios, have
stayed empty there so far." Experiment P4 asks the game which sections have content in a Forever
dungeon and with an achievement or recipe tracked. Version one's own list doesn't depend on it: it
draws every quest kind either client tracks, and hands over for the rest wherever they turn up.

### How SaftUI knows a section has content

Two signals, either of which counts, both of them reads only:

**1. Probes on the game's data.** One function per section in `probes.lua`, each reading the same game
API Blizzard's module reads, guarded by presence (a missing namespace or function answers "no"):

| Section | Has content when |
| --- | --- |
| Scenario (and Mythic+, delves, the Maw's scenarios) | `select(3, C_Scenario.GetInfo())` (its number of stages) is above 0: Blizzard's own test (`isInScenario = numStages > 0`). |
| Zone widgets | `ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing() > 0`. |
| Bonus objectives | A quest in `GetTasksTable()` that isn't a world quest (`C_QuestLog.IsWorldQuest`) or watched, for which `GetTaskInfo(questID)` gives isInArea and a number of objectives (the module's own rule). |
| World quests | `C_QuestLog.GetNumWorldQuestWatches() > 0`, or a world quest in `GetTasksTable()` that `GetTaskInfo` says you're in the area of. |
| Achievements | A `C_ContentTracking.GetTrackedIDs(Enum.ContentTrackingType.Achievement)` ID whose `GetAchievementInfo` 13th return (earned by me) is false. |
| Professions | `C_TradeSkillUI.GetRecipesTracked(false)` or `(true)` isn't empty. |
| Monthly activities | A `C_PerksActivities.GetTrackedPerksActivities().trackedIDs` ID whose `C_PerksActivities.GetPerksActivityInfo(id)` isn't completed. |
| Endeavors | A `C_NeighborhoodInitiative.GetTrackedInitiativeTasks().trackedIDs` ID whose `GetInitiativeTaskInfo(id)` isn't completed. |
| Collection tracking | `C_ContentTracking.GetTrackedIDs(type)` isn't empty for any `Enum.ContentTrackingType` but Achievement. |

**2. Blizzard's own module state, read after each of its layouts.** A post-hook on each module's own
`Update` (looked up at call time, so the hook sees every layout, dirty ones included; the container's
`Update` can't be hooked, re-checked above) reads the module's `state` and `hasContents` and asks for
a probe pass on the next frame. A module counts as having content in state `NotShown`,
`ShownPartially` or `ShownFully`, or with `hasContents` true. This catches what the probes don't name:
the Maw's buffs without a scenario (retail), the scenario's bonus steps, and any module a later patch
adds, which SaftUI finds by walking `ObjectiveTrackerFrame.modules` (read only) for frames it doesn't
know; for those it prints one chat line per session: "Blizzard's tracker has a section SaftUI doesn't
know (<name>); Blizzard's tracker shows while it has content."

The module state alone isn't enough: Blizzard's quests can fill its height, and a module after them
(achievements, recipes, activities) is then `Skipped`, whatever it holds (re-checked above). That's
why the probes exist. The two quest modules are never read: SaftUI draws what they hold.

The probes run on a probe pass: on the events the matching modules listen to (`SCENARIO_UPDATE`,
`SCENARIO_CRITERIA_UPDATE`, `SCENARIO_COMPLETED`, `CHALLENGE_MODE_START`, `CHALLENGE_MODE_COMPLETED`,
`CHALLENGE_MODE_RESET`, `CONTENT_TRACKING_UPDATE`, `TRACKED_ACHIEVEMENT_LIST_CHANGED`,
`TRACKED_ACHIEVEMENT_UPDATE`, `ACHIEVEMENT_EARNED`, `TRACKED_RECIPE_UPDATE`,
`PERKS_ACTIVITIES_TRACKED_LIST_CHANGED`, `PERKS_ACTIVITY_COMPLETED`,
`INITIATIVE_TASKS_TRACKED_LIST_CHANGED`, `NEIGHBORHOOD_INITIATIVE_UPDATED`, `QUEST_LOG_UPDATE`,
`QUEST_WATCH_LIST_CHANGED`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_ENTERING_WORLD`), and after the module
hook; at most one pass a frame.

**Hysteresis.** A section counts as needed the moment it has content, and stops counting only after 2
seconds without any, so a zone widget that flickers at an area's edge doesn't swap the trackers back
and forth.

### What the player sees: the handover

The setting **When Blizzard's tracker is needed** (Tracker page, Blizzard's tracker tab) has two
choices. **Call** on the choices and the default.

**In SaftUI's place** (the default). When a section SaftUI doesn't draw has content:

- *Out of combat:* SaftUI's tracker goes away (its window and its item buttons hidden; the nearest
  item button stays, as it's its own frame) and Blizzard's whole tracker appears, untouched, with its
  top right corner on SaftUI's tracker's top right corner (on the window's, at the holder's top for
  Grow down, at the window's top for Grow up). The skin styles it as usual (Skinning > Objective
  tracker). Inside a dungeon that's Blizzard's dungeon stage above Blizzard's quest list.
- *If the need starts in combat:* SaftUI's secure buttons can't hide in combat, and Blizzard's tracker
  must never show under them, so Blizzard's tracker appears **beside** SaftUI's (the beside spot,
  below) and SaftUI's stays. When combat ends, if it's still needed, it moves into SaftUI's place as
  above.
- *When the need ends* (2 seconds after the last such section emptied): Blizzard's tracker goes back
  off screen and SaftUI's comes back. Out of combat at once. In combat at once too, unless SaftUI's
  item buttons need showing again (they were hidden when it handed over, and can't be shown in
  combat): then Blizzard's tracker, whose own item buttons work in combat, stays until combat ends.

**Beside SaftUI's.** Both show: Blizzard's tracker in the beside spot whenever it's needed, SaftUI's
unchanged. Blizzard's then lists the quests too; the player chose that.

**The beside spot.** On the side of SaftUI's tracker nearer the screen's middle (left of it when its
holder's centre is right of UIParent's centre, else right of it), 12 apart, past the item column when
item buttons sit beside the tracker on that side (the column's width and its 4 gap added), level with
the holder's top. On the left, Blizzard's top right corner goes there; on the right, its top left
(its width read with `GetWidth(true)`). Its own clamp, turned back on, keeps it on screen.

*Ruling made by the controller in Task 11, for the owner to check:* a revealed (and concealed) spot keeps Blizzard's tracker at least 200 above the screen's bottom, even when that moves its top off SaftUI's top, because Blizzard works its height out from its anchor's y down to the right column's bottom (at least 20) and a lower spot leaves its modules no room. A tracker moved in Blizzard's Edit Mode is raised to keep its fixed height on screen. With Grow up it stays at the window's top as it was when the window was hidden.

The Blizzard's tracker tab also shows a line saying what it's doing now: "Not needed now." or
"Showing Blizzard's tracker for: Scenario, Achievements." (the needed sections, by the names in the
table above), refreshed when the page draws.

### The handover's rules

A pure function, `handover.lua` or within `blizzard.lua`, so the tests can walk every case:
`Next(state, needed, inCombat, mode, itemsToShow) -> state, actions`. The states:

- **own**: SaftUI's tracker shows, Blizzard's is concealed.
- **blizzard**: Blizzard's tracker in SaftUI's place; SaftUI's window and item buttons hidden.
- **both**: Blizzard's tracker in the beside spot; SaftUI's shows.

| From | When | To |
| --- | --- | --- |
| own | needed, mode place, out of combat | blizzard (hide SaftUI's item buttons, then the window; reveal Blizzard's in place) |
| own | needed, mode place, in combat | both, with "go in place when combat ends" queued |
| own | needed, mode beside | both |
| both | not needed (in or out of combat) | own (conceal Blizzard's) |
| both | combat ends, still needed, mode place | blizzard |
| blizzard | not needed, out of combat | own (conceal Blizzard's; show the window, then the item buttons) |
| blizzard | not needed, in combat, no item buttons to show | own |
| blizzard | not needed, in combat, item buttons to show | stays blizzard; own when combat ends |
| any | mode changed in `/sui` | re-run the table from own (`/sui` is closed in combat) |

"Item buttons to show" means placement In the row or Beside the tracker and at least one tracked
quest with an item. A `/reload` starts from own, whatever the state was.

## The data

### What the tracker reads

Everything comes from the game's own quest API, the same calls Blizzard's quest module makes, read
fresh on each refresh into a plain table (the model) that the rest of the tracker draws from:

| What | API (both clients unless noted) |
| --- | --- |
| Tracked quests, in the game's order | `C_QuestLog.GetNumQuestWatches()`, `C_QuestLog.GetQuestIDForQuestWatchIndex(i)`. Blizzard's comparator, kept: callings first, then `overridesSortOrder`, then the watch index. |
| The quest itself | `C_QuestLog.GetLogIndexForQuestID`, `C_QuestLog.GetInfo(logIndex)`: title, `level`, `difficultyLevel`, `frequency`, `isTask`, `isBounty`, `isHidden`, `isAutoComplete`, `campaignID`, `questClassification`, `overridesSortOrder`; `C_QuestLog.IsQuestDisabledForSession`, `C_QuestLog.IsQuestCalling` |
| Its zone header | `C_QuestLog.GetHeaderIndexForQuest(questID)`, then `C_QuestLog.GetInfo(headerIndex).title` (and its `campaignID` for a campaign header) |
| Objectives | `C_QuestLog.GetQuestObjectives(questID)`: `text`, `type`, `finished`, `numFulfilled`, `numRequired`; a `progressbar` objective's percent from `GetQuestProgressBarPercent(questID)`; `IsQuestSequenced(questID)` |
| Complete, failed | `C_QuestLog.IsComplete`, `C_QuestLog.IsFailed`, `C_QuestLog.ReadyForTurnIn`; the completion line from `GetQuestLogCompletionText(logIndex)`, else `QUEST_WATCH_QUEST_READY` |
| Money needed | `C_QuestLog.GetRequiredMoney(questID)` against `GetMoney()` |
| Timer | `C_QuestLog.GetTimeAllowed(questID)` (total and elapsed); Forever also has `C_QuestLog.GetQuestTimers()`, read only where present |
| Level and elite | `difficultyLevel`; elite from `C_QuestLog.IsEliteQuest` where present (Forever), else `C_QuestLog.GetQuestTagInfo(questID).isElite` |
| Tags | `C_QuestLog.GetQuestTagInfo(questID).tagName`, and `frequency` (the strings `DAILY`, `WEEKLY`) |
| Difficulty color | `GetDifficultyColor(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID))` |
| Quest icon | `QuestUtil.GetQuestIconActiveForQuestID(questID, isComplete, ...)` (Blizzard's util, which only computes an atlas name) |
| The quest's item | `GetQuestLogSpecialItemInfo(logIndex)`: link, texture, charges, show-when-complete; `QuestUtil.QuestShowsItemByIndex`'s rule; `GetQuestLogSpecialItemCooldown(logIndex)`; `IsQuestLogSpecialItemInRange(logIndex)` (0 out, 1 in, nil no range) |
| Inside the quest's area | `C_Minimap.IsInsideQuestBlob(questID)`, event `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED` |
| Distance | `C_QuestLog.GetDistanceSqToQuest(questID)`: distance squared and onContinent; may return nothing |
| The focused quest | `C_SuperTrack.GetSuperTrackedQuestID()`; its waypoint line from `C_QuestLog.GetNextWaypointText(questID)` |
| Auto quest popups | `GetNumAutoQuestPopUps()`, `GetAutoQuestPopUp(i)` (questID, `'OFFER'` or `'COMPLETE'`), skipped while `SplashFrame` is shown, as Blizzard does |
| Counts | `C_QuestLog.GetNumQuestLogEntries()` (its second return: quests in the log), `C_QuestLog.GetMaxNumQuestsCanAccept()`, `Constants.QuestWatchConsts.MAX_QUEST_WATCHES` |
| The current zone | `C_Map.GetBestMapForUnit('player')` climbed to its zone (`Enum.UIMapType.Zone`, stopping at an Orphan map, as `PlayerMaps` in `ZoneText.lua` does) and that map's name; `GetRealZoneText()`; `GetZoneText()` |
| Arena | `IsInInstance()`: no quests in an arena, as Blizzard's quest module |

The old globals (`GetQuestLogSpecialItemInfo`, `GetNumAutoQuestPopUps`, `GetTasksTable` and the
rest) aren't in the generated API docs; Blizzard's own tracker calls them on both clients. Every read
is guarded by presence: a missing function makes that part of the row absent, never an error.

**Campaign quests on retail** sit under their campaign's log header. **Bonus objectives and world
quests** (task quests) are not on the watch list and aren't drawn in version one; the probes hand
over for them.

### Events and the refresh

The refresh: read the model, group it, lay it out, draw what changed, then the item buttons, the
probes, the handover and the visibility. Events only mark it dirty:

- `QUEST_LOG_UPDATE`, `QUEST_WATCH_LIST_CHANGED`, `QUEST_WATCH_UPDATE`, `QUEST_ACCEPTED`,
  `QUEST_REMOVED`, `QUEST_TURNED_IN`, `QUEST_AUTOCOMPLETE`, `QUEST_POI_UPDATE`,
  `QUEST_LOG_CRITERIA_UPDATE`, `UNIT_QUEST_LOG_CHANGED` (player), `SUPER_TRACKING_CHANGED`,
  `SUPER_TRACKING_PATH_UPDATED`, `ZONE_CHANGED`, `ZONE_CHANGED_INDOORS`, `ZONE_CHANGED_NEW_AREA`,
  `PLAYER_ENTERING_WORLD`, `PLAYER_LEVEL_UP` (difficulty colors), `PLAYER_MONEY` (only while a quest
  needs money), `BAG_UPDATE_DELAYED` (item counts), `BAG_UPDATE_COOLDOWN` (cooldowns only),
  `PLAYER_REGEN_ENABLED` and `PLAYER_REGEN_DISABLED`.

**Throttling.** Dirty marks fold into one refresh on the next frame (`C_Timer.After(0)`), and
`QUEST_LOG_UPDATE`, which can fire many times a second while killing, refreshes at most every 0.1
seconds. The refresh never makes a frame once its pools hold enough: rows, lines and bars are pooled
and reused, a font string's text is set only when it changed, and a row is measured again only when
its text or width changed. Thirty-five quests is the most the log holds, so a whole read is cheap; the
drawing is what the diff saves. Three small tickers run only while they're needed: the timer line (1
second, while a timed quest shows), the item buttons' range (0.2 seconds, Blizzard's
`TOOLTIP_UPDATE_TIME`, while a SaftUI item button shows), and the nearest item (1 second, out of
combat, while that button is on). The mouse check for fading is the action bars' fader pattern
(`SaftUI-ActionBars/bars.lua`): one `OnUpdate`, running only while a setting needs it.

### Secret values

No quest API on either client marks a return as secret (re-checked above), so nothing the tracker
reads in version one is expected to be secret. The reader still treats one as missing: it keeps only
plain values (`st.PlainNumber`, `st.PlainString`, `st.Plain`; `.agents/clients.md`), except a title,
which goes to `SetText` as it is and sorts last. Sizes the tracker reads are its own frames' and its
own font strings', never Blizzard's (but `GetWidth(true)` of Blizzard's tracker for the beside spot,
guarded). The scenario's criteria (`GetUnitCriteriaProgressValues`, `SecretWhenUnitIdentityRestricted`)
are phase 3's to handle.

## The window

### Frames

- **The holder** (`SaftUITrackerHolder`, a SaftUI frame on UIParent): Width by Max height, placed
  from `tracker.position` with `st:PlaceHolder` and kept inside the screen edge margin
  (`st:KeepInScreenMargin`). It draws nothing; it's the mover's frame, so edit mode's outline covers
  the whole height the tracker may take.
- **The window** (`SaftUITracker`, a SaftUI frame on UIParent, strata `LOW` as Blizzard's tracker,
  level 10): anchored by its top right to the holder's top right (Grow down) or by its bottom right
  to the holder's bottom right (Grow up), as tall as its contents up to the holder's height. It holds
  the header and a scroll frame (`st:CreateScrollFrame`, the bags' scroll frame), whose child holds
  the rows. **No secure frame is ever its child or anchored to it**, so it is never protected: it
  moves, sizes, scrolls, shows and hides in combat.
- **The item layer** (`SaftUITrackerItems`, `SecureHandlerStateTemplate`, on UIParent, strata `LOW`,
  level 30): the parent of the row and column item buttons. Quest item buttons, below.
- **The nearest item button** and its holder, on UIParent. Below.

Every size and offset is a whole pixel (`st:RoundToPixel`). The window is anchored by a corner, so no
length needs to be even.

### Layout (exact values)

- Padding 8 inside the window on every side.
- **Header** 24 tall at the window's top: the title "Objectives" (Header font) at the left; the count
  ("12/35": quests in the log over the most you can hold) right-aligned 6 left of the collapse button,
  in Text > Grey; the collapse button, 16 by 16, Lucide's `chevron-up` while the list shows and
  `chevron-down` while collapsed, drawn 16 (an 8 px glyph), Text > Grey at rest and white under the
  mouse (the skin's chevrons). A 1 px line along the header's bottom in the theme's border color at
  50%, as the skin draws it. The header's tooltip: "Objectives" in white, then "12 of 35 quests in
  your quest log, 8 tracked (up to 25)."; the button's: "Collapse" or "Expand". With Header off there
  is no header (and no whole-tracker collapse).
- 6 between the header and the first row.
- **Zone header** rows 20 tall, 10 above each but the first: the collapse chevron (16, as the header's)
  at the left, the header's title (Header font) 2 after it, Text > Normal for the current zone and Text
  > Grey for the rest, Lucide's `map-pin` (16, an 8 px glyph, in the accent) after the current zone's
  name, and the number of its quests right-aligned in Text > Grey. 4 below each.
- **Quest rows**, `spacing` (8) apart: the quest icon (14 by 14) at the row's left when Quest icons is
  on, the title 4 after it (or at the left), objectives indented 12 under the title's left edge, 2
  between the title and the first objective and between objectives. A progress bar 12 tall with 3
  above and below, as wide as the objectives. The row's text width is the scroll child's width less
  the indent, less the item button and 4 when the quest's button sits in the row.
- **Pixel tags**: the column's numbers (below) in the Pixel font.
- **Scroll bar room**: 14 on the right while the list scrolls (`st:ScrollBarRoom`: the bar's 6 gap and
  8 width), so text doesn't re-flow when the bar shows under the mouse.

### Zone groups

- **A group per quest log header**, its title the header's own text: zone names for most quests,
  categories (Dungeon, Raid, a class, a holiday) for some, a campaign's name on retail. A quest whose
  header the log doesn't give (`GetHeaderIndexForQuest` returns nothing) goes in a last group,
  "Other".
- **Order of groups:** the current zone's group first (Current zone first), then campaign groups
  (retail: a header with a `campaignID`), then the rest in the quest log's own header order. **Call.**
- **The current zone:** a group whose title equals the zone map's name, `GetRealZoneText()` or
  `GetZoneText()`. Forever's headers are zone names, as EQ found ("on WoW Forever a quest under that
  heading counts as well").
- **Order inside a group** (Order): *The game's order* (the default: the watch list as Blizzard sorts
  it, nearest first, re-sorted as you change zones), *Quest log order* or *Level* (low first, then the
  game's order). With Finished quests first, ready-to-turn-in quests go first in their group, keeping
  that order otherwise.
- **Collapsing:** a click on a zone header collapses or expands it; a collapsed group keeps its header
  and count. The state is kept **per character** (`st.config.char.tracker.zones[title] = true`), as the
  quest log keeps its own headers per character, and survives reloads. The whole tracker's collapse
  (the header's chevron) is per character too (`st.config.char.tracker.collapsed`). **Call.**
- **Group by zone off:** one list, in the chosen order, with no zone headers.

### Quest rows

- **Title:** with Level on, "[12] " before it, "[12+] " for an elite quest (Forever's own form, from
  `GetQuestTitlePrefix`); with Tags on, the tags after it in brackets ("(Elite)", "(Dungeon)",
  "(Daily)"). In the difficulty color with Color by difficulty on, else Text > Normal; in Completed
  while ready to turn in, in Failed when failed. Level defaults to on on Forever and off on retail,
  each client's own look (`st.forever` in the default). **Call.**
- **Objectives:** a dash and the objective's text (the game's own "3/8 Boars slain"), in Text > Normal;
  a finished one in Completed (or left out with Hide finished objectives); a failed quest gets one line
  "Failed" in Failed. A sequenced quest shows its objectives up to the first unfinished one, as
  Blizzard's does.
- **Finished quests:** the completion line (`GetQuestLogCompletionText`, else "Ready for turn-in") in
  Completed, and its objectives only with Objectives of finished quests on. An auto-complete quest
  that's complete shows "Quest complete" and "Click to complete" (`QUEST_WATCH_QUEST_COMPLETE`,
  `QUEST_WATCH_CLICK_TO_COMPLETE`).
- **Progress bars** for a `progressbar` objective: SaftUI's bar (a backdrop drawn as kind `bar`, the
  flat texture) in Blizzard's progress blue (0.26, 0.42, 1), the template's `BarColor`, which the skin
  keeps, with the percent centred on it in the Pixel font.
- **Timer:** "Time left: 4:32" while a timed quest runs, in Failed under a minute. Forever's own
  tracker shows no timer bar (`CanShowTimerBar` is false there); SaftUI shows the line on both.
- **Money:** "<have> / <need>" (`GetMoneyString`) while the quest needs more money than you carry.
- **Waypoint:** for the focused quest, its waypoint line ("Waypoint: Take the boat") when the game
  gives one, as Blizzard's does.
- **Item slot:** where the quest's button sits in the row (Quest item buttons, below). A quest whose
  item came in combat shows the item's icon there, desaturated at 40%, with the tooltip "Its button
  comes when combat ends.": the item isn't lost from view, only its button waits.
- **Hover:** the row fills with the accent at `st.TINT_ROW` (25%) under the mouse, 2 beyond its text
  above and below.

### Auto quest popups

Each popup Blizzard's quest module would show is a row above the zone groups, 22 tall: a 2 px accent
bar at its left, "Quest discovered" or "Quest complete" (Header font, accent) over the quest's title.
A click shows the quest (`ShowQuestOffer(questID)` or `ShowQuestComplete(questID)`) and removes the
popup (`RemoveAutoQuestPopUp(questID)`), as Blizzard's does. These are game functions that open the
quest frame through the game's own events, so no Blizzard Lua runs in SaftUI's call; allowed in
combat. That they aren't blocked in combat is an in-game check. **Call.** While popups show, the
window expands if it was collapsed (Blizzard's `ForceExpand` does the same for its own).

### Clicks

Blizzard's block header click (`QuestObjectiveTrackerMixin:OnBlockHeaderClick`), and what SaftUI
does for each:

| Click | Blizzard's | SaftUI's |
| --- | --- | --- |
| Any, while a chat box is open | Puts the quest's link in it (`ChatFrameUtil.TryInsertQuestLinkForQuestID`) | Same call, where it exists. |
| Shift (the QUESTWATCHTOGGLE modifier) | Stops tracking it (`C_QuestLog.RemoveQuestWatch`, unless New Player Experience forbids it: `QuestUtil.CanRemoveQuestWatch`) | Same. |
| Left, on a complete auto-complete quest | `ShowQuestComplete`, and removes its popup | Same. |
| Left | Opens it on the map (`QuestMapFrame_OpenToQuestDetails`) | By the setting Left click: *Show on map* (the default) does Blizzard's out of combat and focuses it in combat; *Focus* focuses it always. |
| Right | The menu, below | The menu. |
| The quest icon | (Blizzard's POI button) focuses it | Focuses it, or stops focusing it when it is. |

"Focus" is the game's super-track (`C_SuperTrack.SetSuperTrackedQuestID`, 0 to stop): a game call, no
Lua of Blizzard's. Opening the map runs Blizzard's map Lua in SaftUI's call: in combat its pin setup is
blocked (study §2.5), and whether an open out of combat leaves the map tainted for later is experiment
P5. If P5 shows lasting taint, Show on map leaves the click and the menu, and Left click is Focus only.
**Call.**

A zone header's left click collapses or expands it; a right click does nothing.

### The right-click menu

Blizzard's menu (Forever's, which adds Share in chat for gamepads only), in its order, through
Blizzard's `MenuUtil.CreateContextMenu` as the bags' slot menu already does (`SaftUI-Bags/slot.lua`),
with Blizzard's own strings:

| Entry (Blizzard's string) | Does | SaftUI |
| --- | --- | --- |
| The quest's title (title row) | | Kept. |
| Focus / Stop focusing (`SUPER_TRACK_QUEST`, `STOP_SUPER_TRACK_QUEST`) | `C_SuperTrack.SetSuperTrackedQuestID` | Kept. |
| Open quest details / Hide quest details (`OBJECTIVES_VIEW_IN_QUESTLOG`, `OBJECTIVES_HIDE_VIEW_IN_QUESTLOG`) | `QuestUtil.OpenQuestDetails` | Kept, out of combat only (disabled in combat). |
| Show on map (`OBJECTIVES_SHOW_QUEST_MAP`) | `QuestMapFrame_OpenToQuestDetails` | Kept, out of combat only; dropped if P5 fails. |
| Stop tracking (`OBJECTIVES_STOP_TRACKING`) | `C_QuestLog.RemoveQuestWatch` | Kept, by `QuestUtil.CanRemoveQuestWatch`. |
| Share quest (`SHARE_QUEST`), when it can be shared and you're in a group | `QuestUtil.ShareQuest` | Kept. |
| Share in chat (gamepad mode only, Forever) | Puts the link in chat | Dropped: SaftUI's tracker has no gamepad mode. |
| Abandon (`ABANDON_QUEST_ABBREV`) | `QuestMapQuestOptions_AbandonQuest` (Blizzard's confirm) | Kept, out of combat only; Blizzard's own confirm, as SaftUI already shows Blizzard's popups elsewhere (`SaftUI-Core/utilities.lua`, the warband bank). |

The menu is SaftUI's to open from its own click; every entry that runs Blizzard UI Lua (details, map,
abandon) is out of combat only, its disabled line saying "Out of combat only". **Call.**

### Tooltips

With Tooltips on, hovering a quest row shows the game's quest tooltip (`GameTooltip:SetHyperlink` of
`GetQuestLink(questID)`), with the party's progress when grouped (`GameTooltip:SetQuestPartyProgress`
where it exists), anchored to the left of the window (`ANCHOR_NONE`, its top right 8 left of the
row's top left) as Blizzard's. A last line in Text > Grey names the clicks: "Click: show on map
(focus in combat). Shift-click: stop tracking. Right-click: more." (or "Click: focus." with Left click
Focus). An item button shows the item (`GameTooltip:SetQuestLogSpecialItem(logIndex)`), and the
nearest button names its quest under the item.

### The focused quest

The super-tracked quest gets a 2 px accent bar 4 left of its row, as tall as the row, and its
waypoint line. When the focus changes, or a newly tracked quest appears, the list scrolls it into view
(out of combat, or while scrolling isn't locked). **Call.**

### Theme

The window takes the page's Theme and Background (`generators.theme` and `generators.background`,
defaults "Use SaftUI's theme" for both), drawn as kind `panel`: see-through by the theme's Background
unless the player picks Solid; Theme None draws no panel (text over the world, as Blizzard's). Under
the Blizzard theme the panel is Blizzard's tooltip-border look for `panel`, the header's line stays,
and the scroll bar shows Blizzard's minimal bar art (`st:SkinScrollBar` already does). The item
buttons draw as kind `action` in the same Theme and Background. A theme change redraws them (the
module's `UpdateConfig`), and `OnColorsChanged` puts back what the module colors itself: the header
line, chevrons, the focus bar, the hover, the zone count, the status colors (`objectives`).

## Size and scroll

- **Width** (default 260, Blizzard's, 180 to 600) and **Max height** (default 560, 120 to 1600): the
  owner's "just a height and width adjustment, not scaling". Max height is the most the tracker grows
  to, its header included: the window is as tall as its contents up to it, then scrolls. The holder,
  and so edit mode's outline, is always Width by Max height. **Call** on 560.
- **Grow:** *Down* (the default: the top stays put, as Blizzard's) or *Up* (the bottom stays put, for a
  tracker placed low on the screen).
- **The scroll bar** is the bags' (`st:CreateScrollFrame`: Blizzard's minimal bar with SaftUI's thumb
  under Thick and Thin and Blizzard's art under Blizzard, hidden when there's nothing to scroll),
  draggable, its room kept while the list scrolls. With **Scroll bar under the mouse only** (on by
  default) it shows only while the mouse is over the window or the item column, and for 0.3 seconds
  after it leaves, so it can be reached. **Call** on the bags' bar over the options kit's: the kit's is
  a 3 px marker under Thick and Thin that can't be dragged, and the owner asked for a visible bar.
- **The mouse wheel** over the window scrolls 40 per notch (two lines), clamped to the content.
- **In combat:** the window isn't protected, so it scrolls. **But while an item button sits in a row,
  the wheel and the bar don't scroll in combat**: the buttons can't follow their rows, and a scrolled
  list would leave them floating over other rows or past the window's edges. The bar shows at 40%
  then, its tooltip saying "Scrolling waits for the end of combat while quest item buttons sit in the
  rows." With buttons beside the tracker or off, it scrolls in combat. **Call.**
- **Keeping place:** a refresh keeps the scroll offset, clamped to the new content, and scrolls the
  focused quest or a newly tracked one into view (above).
- **Collapsed:** the window is its header only.
- **Hide when empty** (on): with no tracked quests and no popups the window hides; with it off, the
  header stays.

## Quest item buttons

### Why they're SaftUI's own secure buttons

`UseQuestLogSpecialItem` is protected, and Blizzard's button can call it only because Blizzard's code
makes and runs it untainted. SaftUI's code can't call it at all ("A tainted button fails even out of
combat", study §1.5), and can't borrow Blizzard's buttons (pooled, re-assigned on every layout, and
concealed). So each item button is SaftUI's own `SecureActionButtonTemplate` button, type `item`, its
`item` attribute the quest item's link from `GetQuestLogSpecialItemInfo`. Using the link, not the
quest log index, keeps a button right when the log's indexes shift. An equippable quest item is
equipped by a secure `item` button rather than used (re-checked above); a rare case, left as an
in-game check. **Call.**

The game's rules for them, and how the design keeps them:

- **Made, placed, shown, hidden and given attributes only out of combat.** Every such change in
  combat waits for the end of combat (`st:QueueAfterCombat('tracker_items', ...)`), which makes the
  whole set right again in one pass. SaftUI never creates a secure button in combat.
- **Never a child of, or anchored to, a frame that must move in combat.** They are children of the
  item layer on UIParent and placed by offsets from UIParent's corner, worked out from their rows'
  rects (SaftUI's own frames, safe to read) out of combat. Protection spreads to parents and to anchor
  targets (taint.md rule 6), so the window, the scroll frame and the rows stay free.
- **Never invisible while they can be clicked.** Alpha isn't protected, but a button at alpha 0 still
  takes clicks, and in combat `Hide` and `EnableMouse` are blocked on it. So a button is either
  hidden properly (out of combat by `Hide`, in combat only by the item layer's state driver) or
  visible at 25% or more. **Call:** `BUTTON_MIN_ALPHA = 0.25`.
- **Pooled:** buttons are reused, never freed; a spare one is hidden. The pool grows by need out of
  combat (at most 25, the watch limit).

The look: the item's icon cropped by Icon zoom (`st:IconTexCoords`), a backdrop drawn as kind `action`
in the tracker's Theme and Background, a hover in the HIGHLIGHT layer in the accent, a cooldown
(`CooldownFrameTemplate`), the count in the Pixel font at the bottom right when the item has charges,
the icon tinted Text > Red while `IsQuestLogSpecialItemInRange` says out of range, and the accent
border lit while you're inside the quest's area (`C_Minimap.IsInsideQuestBlob`, Blizzard's glow, made
calm). All of that is drawing, which runs in combat. Buttons register `AnyUp` and `AnyDown`, as
SaftUI's pet and stance buttons do, so the "cast on key down" setting is honored.

### The item layer

A `SecureHandlerStateTemplate` frame with a visibility state driver (`RegisterStateDriver(layer,
'visibility', driver)`, set out of combat, queued in combat). The driver is built from the settings
(Fading and hiding, below): always `[petbattle] hide`, plus `[combat] hide` when In combat is Hide and
Hide quest items with the tracker is on, `[nocombat] hide` for Out of combat the same way, and
`[@boss1,exists] hide` for Boss fights, then `show`. That's how buttons hide in combat without addon
code.

### Item buttons: In the row (the default)

The button (Button size, default 24) sits at its quest row's top right, the row's text narrowed to
make room, as Blizzard's does. Out of combat it follows its row on every refresh and scroll; a button
whose row is collapsed, scrolled out of view (its centre outside the scroll frame) or gone is hidden.

In combat buttons stay where they were. A button whose row has moved by more than 2 (a quest above it
finished and left, a group was collapsed) or is gone dims to 40% (above 25%: still seen), its tooltip
naming its quest, and it still uses its own quest's item. The wheel and bar don't scroll (above). When
combat ends, every button goes back over its row, or hides. **Call** on 40%.

### Item buttons: Beside the tracker

A column of buttons 4 outside the window, on the side nearer the screen's middle (the beside spot's
rule), each button level with its quest's title out of combat, none overlapping (a button that would
overlap the one above moves down to sit 2 under it), hidden when its row is out of view. Each quest
with a button gets a number, 1 to n in list order: in the Pixel font at the button's bottom left, and
in the accent at the right end of its row's title. In combat the column stays as it was and the list
scrolls freely; the numbers keep each button tied to its quest. This is Kaliel's "separate column"
with its numbered tags (study §3). **Call** on the numbers.

### Item buttons: Off

No row or column buttons; the quest's item shows in the row as a plain icon (no click), so the player
still sees there is one. The nearest button can still be on.

### The nearest quest item button

One bigger button (Nearest button size, default 40) for the quest item you most likely want, with a
key. Its own SaftUI secure button, `SaftUITrackerNearestItem`, type `item`, its own holder and mover,
not in the item layer (it never hides with the tracker: it's an action button). Off by default (Nearest
quest item button). Shown only while it has an item, out of combat.

**Which item** (a pure function, `nearest.lua`), among tracked quests with an item that can be used
(`QuestUtil.QuestShowsItemByIndex`'s rule):

1. a quest whose area you're inside (`C_Minimap.IsInsideQuestBlob`);
2. else the focused quest, if it has one;
3. else the one with the smallest `GetDistanceSqToQuest`, on your continent;
4. ties go to the game's order. A quest with no distance counts as farthest.

It's chosen again every second out of combat, and on the quest events, `SUPER_TRACKING_CHANGED`,
`PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED` and the zone events. **In combat it keeps the item it had**
(its attribute can't change); a change waits for the end of combat. Its look is the row buttons', plus
its key in the Pixel font at the top right (`GetBindingKey`), refreshed on `UPDATE_BINDINGS`.

**The key:** a `CLICK SaftUITrackerNearestItem:LeftButton` binding, listed in Blizzard's Key Bindings
in the section titled SaftUI ("Use the nearest quest item") through `Bindings.xml`, and set from the Items
tab with the options kit's keybinding widget: its `get` is `GetBindingKey` of that command, its `set`
`SetBinding(key, command)` (clearing the old key first) and `SaveBindings(GetCurrentBindingSet())`, out
of combat (queued in combat, as `SaftUI-ActionBars/bindings.lua` does). The key is the game's binding,
saved by the game, not a SaftUI setting. **Call.**

### In combat, the accepted limits

Said plainly on the Items tab (a description row) and here:

- A quest item that appears in combat (a new quest, an item picked up) has no button until combat
  ends; its row shows the item's icon greyed meanwhile.
- Buttons stay where they were; one whose row moved dims.
- The nearest button keeps its item.

Blizzard's tracker had none of these limits; its buttons aren't secure. During a handover its buttons
are the ones on screen, and they work in combat.

## Fading and hiding

### Triggers

Each trigger is a setting with a choice of what the tracker does while it applies. **Call** on all
defaults being Show (the owner: "options for everything", nothing on by default):

| Trigger | Setting | Choices | Applies while |
| --- | --- | --- | --- |
| In combat | `visibility.combat` | Show, Fade, Hide | `PLAYER_REGEN_DISABLED` to `PLAYER_REGEN_ENABLED` (`InCombatLockdown()` at load) |
| Out of combat | `visibility.nocombat` | Show, Fade, Hide | the rest of the time |
| Mouse off | `visibility.mouseoff` | Show, Fade | the mouse isn't over the window or the item column |
| In instances | `visibility.instance` | Show, Fade, Hide | `IsInInstance()` (a dungeon, raid, battleground, arena or scenario) |
| Boss fights | `visibility.boss` | Show, Fade, Hide | `ENCOUNTER_START` to `ENCOUNTER_END` (`IsEncounterInProgress()` at load) |
| Mythic+ | `visibility.mythic` | Show, Fade, Hide | `C_ChallengeMode.IsChallengeModeActive()` (`CHALLENGE_MODE_START`, `COMPLETED`, `RESET`); shown only where the function exists |

And with them:

- **Faded opacity** (`fade_alpha`, 0% to 100%, default 30%).
- **Show fully under the mouse** (`hover`, on): a faded tracker comes back to full while the mouse is
  over it (a hidden one can't be hovered).
- **Background under the mouse only** (`background_hover`, off): the panel shows only under the mouse;
  the text always.
- **Scroll bar under the mouse only** (`scrollbar_hover`, on): above.
- **Hide quest items with the tracker** (`items`, off): whether the item buttons go with the window.

### How they combine

The strongest of the triggers that apply wins: Hide over Fade over Show. Then Show fully under the
mouse turns Fade into Show while hovered. In combat and Out of combat always have one applying, so
they're the base. The resolver is a pure function (`visibility.lua`): from the triggers that apply,
the settings and the hover, it gives the window's state and alpha, the item buttons' alpha, which of
them hide out of combat, and the item layer's driver string. Fades move at the action bars' pace
(0.2 seconds from faded to full), alpha only.

### What hidden means for a tracker with secure buttons

- **The window:** Fade sets its alpha; Hide hides it (it's not protected, so in combat too). A hidden
  or faded-to-0 window's rows take no clicks: hidden by `Hide`, faded rows by `EnableMouse(false)` on
  SaftUI's own rows (not protected).
- **The item buttons, with Hide quest items with the tracker off** (the default): they stay at full
  alpha whatever the window does. Quest items stay usable; the row buttons then hang where their rows
  were.
- **With it on:** Fade fades them too, never under 25%. Hide hides them: out of combat by `Hide`; in
  combat only for In combat, Out of combat and Boss fights, which the item layer's driver can express;
  In instances and Mythic+ start out of combat (a loading screen, a key's start), so SaftUI hides them
  directly then. Mouse off never hides them.

### Blizzard's tracker during a handover

The triggers apply to whichever tracker shows. On Blizzard's, in SaftUI's place or beside it: Hide
conceals it (off screen, as above); Fade sets its alpha through the C `SetAlpha`, put back after each
of Blizzard's own `SetAlpha` calls (the right column's, re-checked above) by a post-hook on the
tracker's `SetAlpha`; Show fully under the mouse reads the mouse over SaftUI's holder (in place) or
the beside spot's numbers, never over Blizzard's frame (no rect reads, above). **Call.** Blizzard's
own item buttons there are Blizzard's: they fade with it, and a faded-to-0 one still takes clicks, as
it does in BigWigs' boss block today; the beside spot and in-place spot never sit under SaftUI's
buttons.

## The mover and the /sui page

### Movers

- **`tracker`**: frame the holder (Width by Max height, so the outline covers the tracker's full
  height, as the owner asked), label "Tracker", `module = 'Tracker'`, `configPath = { 'Tracker',
  'general' }`, `isHidden` while the window isn't shown (empty, hidden by a trigger, or handed over),
  `getDefaultPosition` Blizzard's default spot (OTP's `DefaultPosition`: `TOPRIGHT` of UIParent,
  `-st.CLAMP_INSET`, -275 on Forever and -260 on retail, a fresh table each call), `getSavedPosition`
  for the history. Registered only while SaftUI's tracker is on, so there's never a disabled mover for
  it. `apply` places the holder with `st:PlaceHolder` (through `st:SafeReposition`).
  `tracker.position` has no AceDB default: on the first load with the tracker on, it takes OTP's saved
  `objectivetracker.position` if the player had moved Blizzard's tracker, else Blizzard's default spot,
  so SaftUI's tracker starts where the player's tracker was. **Call.**
- **`trackernearest`**: frame the nearest button's holder (its size), label "Nearest quest item",
  `module = 'Tracker'`, `configPath = { 'Tracker', 'items' }`, `isDisabled` while the button is off,
  `isHidden` while it has no item, default `TOPRIGHT` of UIParent at (-320, -275 on Forever / -260 on
  retail): left of the tracker's default spot, past a column. The button is anchored to its holder, so
  the holder is protected in combat and placed through `st:SafeReposition`.
- **Blizzard's tracker's mover** (OTP's): disabled while SaftUI's tracker owns it (above).

### The Tracker page

Category Info, tabs General, Quests, Items, Visibility, Blizzard's tracker. Every value option has a
desc and a per-setting reset (the options kit's `default` field: the rotate-ccw icon while it differs
from `st.defaults.tracker`; a small helper in `options.lua` builds `{ differs, reset, value }` from a
key path, as the action bars' `SharedDefault` does). No section or page Reset. Each `set` saves and
runs the module's `UpdateConfig`. Sizes save numbers (`generators.width`/`height` or ranges).

**General** (its `general` group; Position last at `order = 1000`):

| Setting | Key | Type | Default | Desc (gist) |
| --- | --- | --- | --- | --- |
| SaftUI's tracker | `enable` | toggle | off | "Draws your quests in SaftUI's own tracker, grouped by zone, in place of Blizzard's objective tracker. Changes after a reload." |
| Theme, Background | `theme`, `background` | `generators.theme`/`background` | `'theme'`, `'theme'` | "The tracker's panel and its item buttons." |
| Width | `width` | range 180 to 600, step 1 | 260 | "How wide the tracker is." |
| Max height | `height` | range 120 to 1600, step 1 | 560 | "The tallest the tracker grows. Past it the list scrolls." |
| Grow | `grow` | select Down, Up | Down | "Which way the tracker grows from its position." |
| Header | `header` | toggle | on | "The Objectives line at the top, with the count and the collapse button." |
| Count | `count` | toggle | on | "The number of quests in your quest log in the header." |
| Hide when empty | `hide_empty` | toggle | on | "Hides the tracker while you track no quests." |
| Font | `font` | `generators.font` | `'normal'` | "Quest titles and objectives." |
| Header font | `header_font` | `generators.font` | `'normal'` | "The header and the zone headers." |
| Position | `position` | `generators.position` | Blizzard's spot | "Where the tracker's top right corner is (bottom right with Grow up)." Anchoring it to the tracker itself is refused, as OTP's. |

Font and Header font sit in a Text section; the rest as listed.

**Quests:**

| Setting | Key | Type | Default |
| --- | --- | --- | --- |
| Group by zone | `quests.zones` | toggle | on |
| Current zone first | `quests.current_first` | toggle | on (disabled with Group by zone off) |
| Order | `quests.order` | select: The game's order, Quest log order, Level | The game's order |
| Finished quests first | `quests.finished_first` | toggle | off |
| Level | `quests.level` | toggle | on on Forever, off on retail |
| Tags | `quests.tags` | toggle | on |
| Color by difficulty | `quests.difficulty` | toggle | on |
| Quest icons | `quests.icons` | toggle | on |
| Hide finished objectives | `quests.hide_finished` | toggle | off |
| Objectives of finished quests | `quests.finished_objectives` | toggle | off |
| Progress bars | `quests.bars` | toggle | on |
| Timers | `quests.timers` | toggle | on |
| Waypoint | `quests.waypoint` | toggle | on |
| Tooltips | `quests.tooltips` | toggle | on |
| Left click | `quests.left_click` | select: Show on map, Focus | Show on map |
| Spacing | `quests.spacing` | range 0 to 20 | 8 |

Then a description row: "Finished and failed objectives take Global settings > Colors > Objectives."

**Items** (its `items` group, the nearest button's Position last):

| Setting | Key | Type | Default |
| --- | --- | --- | --- |
| Item buttons | `items.placement` | select: In the row, Beside the tracker, Off | In the row |
| Button size | `items.size` | range 16 to 40, step 2 | 24 |
| Cooldown | `items.cooldown` | toggle | on |
| Count | `items.count` | toggle | on |
| Out of range in red | `items.range` | toggle | on |
| Nearest quest item button | `items.nearest` | toggle | off |
| Nearest button size | `items.nearest_size` | range 24 to 64, step 2 | 40 |
| Key | (the game's binding) | keybinding | none |
| Position | `items.nearest_position` | `generators.position` | (-320, -275 / -260) |

A description row, "In combat a quest item that appears gets its button when combat ends, buttons stay
where they were, and the nearest button keeps its item. Changes to buttons wait for the end of combat.",
and the item settings' sets queue in combat like the buttons (`/sui` is closed in combat anyway).

**Visibility:** the six triggers, Faded opacity (`isPercent`), Show fully under the mouse, Background
under the mouse only, Scroll bar under the mouse only, Hide quest items with the tracker, all under
`tracker.visibility` with the defaults above.

**Blizzard's tracker:** When Blizzard's tracker is needed (`blizzard.mode`: In SaftUI's place,
Beside SaftUI's; default In SaftUI's place), the "Now:" line, and a note: "SaftUI's tracker draws your
quests. While something it doesn't draw yet has content (a scenario or dungeon, Mythic+, bonus
objectives, world quests, a tracked achievement, recipe or activity, zone widgets), Blizzard's own
tracker shows in its place, with everything in it, and SaftUI's comes back when that ends. Its look is
set on Blizzard's tracker page and Skinning."

While SaftUI's tracker is off, every tab but General is disabled, its `disabledDesc` "Turn on SaftUI's
tracker (General) and reload." While another tracker addon is loaded, the page is disabled with the
stand-down line above the tabs, as the nameplate pages.

### Settings that move over from the skin's page

None move: the skin's Font and Header font keep styling Blizzard's tracker (during a handover, and
while SaftUI's is off); SaftUI's tracker has its own pair with the same defaults. The status colors
move to the Colors tab for both. Blizzard's Edit Mode Height, Opacity and Text Size stay unreachable,
as today; SaftUI's tracker has Width and Max height of its own. **Call.**

## Edge cases

- **No tracked quests:** the window hides (Hide when empty), or shows its header with "No tracked
  quests." in Text > Grey.
- **Many quests:** at most 25 tracked plus popups; rows and lines are pooled, the read is per refresh,
  the drawing per change. The header's tooltip says when the watch list is full (25 of 25); tracking a
  26th is Blizzard's own refusal.
- **A quest completes:** its objectives finish in Completed, then the completion line; it moves first
  with Finished quests first. Its row button hides out of combat unless the item shows when complete.
- **Fails:** the title and "Failed" in Failed.
- **Abandoned or turned in** (`QUEST_REMOVED`, `QUEST_TURNED_IN`): the row goes; out of combat its
  button hides at once, in combat it stays dimmed until combat ends (a click then gets the game's own
  "item not found" if it's gone).
- **Zone change:** Blizzard re-sorts the watch list (its own handler, kept alive), and the current zone
  group moves first on the next refresh.
- **Entering and leaving instances:** In instances applies; in an arena there are no quest rows; a
  scenario or dungeon with stages hands over. All on the loading screen's side of combat.
- **`/reload` in combat:** the window, rows and concealment are built at once (none are protected);
  the item layer, its driver, every secure button and the nearest button are made when combat ends
  (`st:QueueAfterCombat`), the rows showing the greyed item icons meanwhile. The handover starts from
  own. Whether the game counts the load as in combat is an in-game check (G7).
- **A quest whose header the log doesn't give:** the "Other" group, last.
- **Two groups with the same title:** the log's headers are its own; if a title repeats, the groups
  merge under it in the first one's place.
- **Task quests appear and vanish** (bonus objectives, world quests in an area): not drawn in version
  one; the probe hands over while you're in the area, with the 2 second hysteresis.
- **The watch limit (25):** Blizzard's auto-track on accept stops at it, as today; SaftUI tracks
  nothing itself.
- **A quest whose data isn't loaded yet** (no title): skipped until a later refresh has it.
- **An equippable quest item:** the secure `item` click equips it (re-checked above); in-game check if
  one turns up.
- **Collapsing in combat:** rows collapse at once; their row buttons stay, dimmed, until combat ends.
- **A tracked quest with an item in a collapsed group or scrolled out of view, out of combat:** its row
  button hides; the nearest button can still offer it.
- **Blizzard's right column** stacks frames (durability figure, vehicle seats) where SaftUI's tracker's
  default spot is; they may overlap its header (as followup check 6 for the skin). The player moves
  the tracker; G-check.
- **Blizzard's Edit Mode open:** Blizzard's tracker shows even when empty (its own rule), off screen.
  SaftUI's edit mode opens with it, as always.
- **Another addon touching Blizzard's tracker** (BigWigs sets its alpha in boss fights, study §3):
  SaftUI doesn't fight it; concealed, it's off screen anyway.
- **A profile switch:** `UpdateConfig` re-applies everything; `enable` is read at login only, so a
  profile that differs there says "SaftUI's tracker changes after a reload." in chat. The collapsed
  groups are per character and stay.
- **SaftUI-Misc not loaded:** SaftUI-Tracker conceals Blizzard's tracker itself; a handover shows it in
  Blizzard's look.

## Testing

### Lua tests (`tests/tracker/`)

What the harness can check, with SaftUI-Tracker's real files loaded over the stubs (`.agents/testing.md`):

- `model_test.lua`: the reader against a stubbed quest log on both clients (`T.client('forever')`,
  `'retail'`): headers and quests, the watch list in order with callings first, level and the "+" for
  elite (through `IsEliteQuest` on Forever, the tag's `isElite` on retail), tags and frequency,
  objectives (a sequenced quest cut after its first unfinished one), complete, failed, auto-complete,
  money, timer, the item and show-when-complete, tasks, bounties, hidden and disabled quests left out,
  popups (none while `SplashFrame` shows), the counts, a header the log doesn't give, a missing
  function making its part absent, a secret value treated as missing.
- `groups_test.lua`: groups by header, the current zone first by each of its three names, campaign
  groups next, log order, the three orders and Finished quests first, collapsed groups from the
  character's table, Group by zone off, the Other group.
- `layout_test.lua`: row offsets from measured heights (a measure function the test gives, since the
  stubs don't wrap text), the narrowed width with a row button, spacing, the content height, the Max
  height clamp, the scroll range, Grow up, whole pixels.
- `refresh_test.lua`: twenty `QUEST_LOG_UPDATE`s in one frame make one refresh, and a burst refreshes
  at most every 0.1 seconds (a stubbed clock); a second refresh makes no new frame; a font string's
  text is set only when it changed.
- `probes_test.lua`: each probe on stubbed APIs (`C_Scenario.GetInfo`, `GetTasksTable`/`GetTaskInfo`,
  `C_ContentTracking`, `C_TradeSkillUI`, `C_PerksActivities`, `C_NeighborhoodInitiative`, the widget
  container), each answering no when its API is missing; the module state signal through the post-hook
  (a stand-in module whose `Update` sets `state`); a `Skipped` module with content found by its probe;
  an unknown module with content; the one chat line; the 2 second hysteresis.
- `handover_test.lua`: every row of the handover table, in and out of combat, both modes, the combat
  end transitions, a mode change, a `/reload`.
- `conceal_test.lua`, on `tests/misc/fixtures/objective_tracker.lua`: the concealed spot (right edge
  100 left of the screen, y unchanged) and the in-place and beside spots for both Grow settings and
  both screen halves; Blizzard's re-places (its `SetPoint`, `ClearAllPoints`, `UpdateHeight` through
  the fixture) put it back; the clamp off while concealed and on while shown; no call is made when it's
  already placed; OTP stands down while owned (no `SetPointDirect` of its own, its mover disabled);
  with SaftUI-Misc absent, SaftUI-Tracker's hooks alone keep it concealed.
- `source_scan_test.lua`: every SaftUI-Tracker file the TOC loads, scanned for calls on Blizzard's
  tracker, its modules or `ObjectiveTrackerManager` outside the allowed list (the C methods through
  `getmetatable(...).__index`, the named post-hooks, the field reads, `GetNumWidgetsShowing`), and for
  `ShouldShowMawBuffs`, `UseQuestLogSpecialItem`, `RemoveModule`, `MarkDirty`, `UnregisterAllEvents`
  on any of them; as `tests/core/theme_blizzard_draw_test.lua` scans for `NineSliceUtil`.
- `items_test.lua`: no secure button is made, placed, shown, hidden or given an attribute while
  `stub.in_combat` (the test counts `CreateFrame` calls with a secure template, and `stub.blocked`
  stays empty); the queued pass at combat end; row placement from row rects and hiding out of view; the
  2 px move rule and the 40% dim in combat; the column's order, numbers and no-overlap rule; the scroll
  lock only with row buttons; the driver strings for each setting; no button ever below 25% while not
  hidden; the greyed icon for an item that came in combat.
- `nearest_test.lua`: the choice rule's four steps; frozen in combat and caught up after; the key's
  `get` and `set` (`SetBinding`, `SaveBindings`, queued in combat).
- `visibility_test.lua`: the resolver over every trigger and choice, hover, and the items setting,
  including both trackers during a handover.
- `options_test.lua`: the page tree passes the AceConfig validator (`tests/lib/options_walk.lua`'s
  `ace_ready`), every option has a desc and no `width`, every value option a `default` that resets to
  `st.defaults.tracker`, each `set` writes its key, the switch's reload prompt, the disabled tabs while
  off, the stand-down.
- `tests/core/colors_test.lua` (extended): the Objectives group and its resets;
  `tests/misc/objective_tracker_status_test.lua` (updated): the skin reads `colors.objectives`, and
  OTP's one-time conversion fills slots AceDB didn't save and sets its marker.
- `tests/core/editmode_movers_test.lua` already checks every registration's fields.

**Stubs** (`tests/wow/`, for every test, faithful to the real API as the stub rules require):
`C_QuestLog`'s functions above (a `stub.quests` world: log entries with headers, the watch list,
objectives, items, distances, the focused quest, popups), with `IsEliteQuest` and `GetQuestTimers`
only under `use_client('forever')`; the old quest globals; `C_SuperTrack`; `C_Minimap.IsInsideQuestBlob`;
`C_Scenario.GetInfo`; `GetTasksTable`, `GetTaskInfo`; `C_ContentTracking.GetTrackedIDs`;
`C_TradeSkillUI.GetRecipesTracked`; `C_PerksActivities`; `C_NeighborhoodInitiative`;
`C_ChallengeMode.IsChallengeModeActive`; `IsInInstance`; `IsEncounterInProgress`; `GetBindingKey`,
`SetBinding`, `SaveBindings`, `GetCurrentBindingSet` (refused in combat into `stub.blocked`);
`Constants.QuestWatchConsts`; `Enum.QuestClassification`, `Enum.ContentTrackingType`,
`Enum.UIMapType`. In `tests/wow/widgets.lua`: the templates `SecureActionButtonTemplate` and
`SecureHandlerStateTemplate`, making a frame that answers `IsProtected()` with true, so its moves,
shows and attributes are blocked in combat as the stubs already do for a frame a test marks
protected. The scroll frame is the bags' stand-in (`tests/bags/container_helpers.lua`), reused or
copied beside the tracker's tests (builder's call), since `st:CreateScrollFrame` needs Blizzard's
template.

### What only the game can confirm

The in-game checks, to give the owner with the build (Forever first, then retail):

- **G1.** `/console taintLog 1`, `/reload`. Track a quest with an item. Use it from a row button in
  combat, from the column, and from the nearest button by its key. No "Interface action failed";
  `Logs/taint.log` has no "blocked" line and nothing tainted by SaftUI naming `ObjectiveTracker`,
  `dirty`, `charges` or `OnClick`.
- **G2.** `/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"isDirty"),issecurevariable(ObjectiveTrackerFrame,"isCollapsed"))`
  prints `true true true` after an hour's questing with SaftUI's tracker on, after a dungeon, and after
  a handover in combat.
- **G3.** A handover: in a dungeon or with a tracked achievement (whatever P4 found Forever has),
  Blizzard's tracker in SaftUI's place, skinned; leaving it brings SaftUI's back. Then the same need
  starting in combat: Blizzard's beside SaftUI's, moving in place after combat. Blizzard's item button
  used in combat during a handover.
- **G4.** Row buttons in combat: finish a quest above one with an item; the lower button stays and
  dims; after combat it's back on its row. The wheel doesn't scroll in combat with row buttons; it
  does with the column.
- **G5.** Every visibility trigger and choice, with Hide quest items with the tracker on and off; a
  hidden button never clicks.
- **G6.** The look under Thick, Thin and Blizzard; Width, Max height, Grow up; the scroll bar under the
  mouse; zone groups with the current zone first and a map pin; collapse states surviving `/reload`.
- **G7.** `/reload` in combat: quests show at once, buttons when combat ends, nothing blocked.
- **G8.** An auto quest popup clicked in combat (if Forever has any); an auto-complete quest's "Click
  to complete".
- **G9.** The right-click menu's entries; Abandon's confirm; Share in a group.
- **G10.** Edit mode: the outline covers Width by Max height; drag, `/reload`, it stays; first enable
  starts where Blizzard's tracker was.
- **G11.** The Colors tab's Objectives colors recolor both trackers; old custom colors carried over.
- **G12.** The right column's frames (durability, vehicle seats) against the tracker's header at the
  default spot.

### Experiments to run before the build

In this order; each gives exact steps, what to paste, and what the result decides. Run them with
SaftUI as it is today (the skin and its mover on), taint log on: `/console taintLog 1`, then `/reload`
before each, and `/reload` after each (a test can taint the session).

**P1. The baseline: a quest item used in combat with today's skin.** Followup check 1, still without a
report; everything else assumes it passes. Track a quest with an item; in combat, use the item from
Blizzard's tracker. Then
`/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"isDirty"))`.
*Passes:* the item is used, `true true`, no "blocked" line in `Logs/taint.log`. *Fails:* stop; the
skin's hooks taint already, and the handover would show a tainted tracker. Report the log first.

**P2. Concealing Blizzard's tracker the way this design does.**
1. Track a quest with an item, near where it can be used.
2. Conceal it (C methods only, as SaftUI will):
   `/run local f=ObjectiveTrackerFrame local m=getmetatable(f).__index local p,r,rp,x,y=f:GetPoint(1) m.SetClampedToScreen(f,false) m.ClearAllPoints(f) m.SetPoint(f,p,r,rp,x-3000,y) print("concealed",p,x,y)`
   The tracker leaves the screen. (Today's mover puts it back the next time Blizzard re-places it, such
   as when a quest updates; if it comes back, paste the line again.)
3. Make quest progress while it's concealed (kill a quest mob), in and out of combat.
4. `/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"isDirty"))`
5. Bring it back:
   `/run local f=ObjectiveTrackerFrame getmetatable(f).__index.SetClampedToScreen(f,true) SaftUI:GetModule("ObjectiveTracker"):PlaceTracker()`
6. In combat, use the quest item from Blizzard's tracker.
*Passes:* step 4 prints `true true`, the item works in step 6, no "blocked" line. Then concealment is
safe as designed. *Fails:* the concealment design changes before the build: report the taint log.

**P3. A SaftUI secure item button, made before combat.**
1. Track a quest with an item. Make a blue square in the screen's middle that uses it:
   `/run local link for n=1,C_QuestLog.GetNumQuestWatches() do local q=C_QuestLog.GetQuestIDForQuestWatchIndex(n) local i=q and C_QuestLog.GetLogIndexForQuestID(q) if i and GetQuestLogSpecialItemInfo(i) then link=GetQuestLogSpecialItemInfo(i) break end end local b=SUIXQ or CreateFrame("Button","SUIXQ",UIParent,"SecureActionButtonTemplate") b:SetSize(40,40) b:SetPoint("CENTER") b:RegisterForClicks("AnyUp") b:SetAttribute("type","item") b:SetAttribute("item",link) local t=b.t or b:CreateTexture(nil,"ARTWORK") b.t=t t:SetAllPoints() t:SetColorTexture(0,0.6,1,0.6) print("item:",link)`
2. Give it a key: `/run SetOverrideBindingClick(SUIXQ,true,"CTRL-F12","SUIXQ")`
3. In combat, click the square, then press Ctrl-F12.
4. If you have a second quest with an item, repeat with it, and with an item that has charges.
*Passes:* the item is used both ways, in combat, with no error: SaftUI's buttons work as designed.
*Fails:* note the error text; a quest item a secure `item` button can't use (one not in your bags, or
an equippable one) changes the button's type (to `macro` with `/use`), and that's decided before the
build.

**P4. What Forever has: sections and quest data.** Paste each line in the open world with quests
tracked, then again inside a dungeon, a battleground, and with an achievement and a recipe tracked if
Forever has those.
- `/run for _,m in ipairs(ObjectiveTrackerFrame.modules or {}) do print(m:GetName() or "?",m.state,m.hasContents and "content" or "-") end`
- `/run local n,s,t=C_Scenario.GetInfo() print("scenario",n,s,t,"widgets",ObjectiveTrackerUIWidgetContainer and ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing(),"popups",GetNumAutoQuestPopUps(),"tasks",#GetTasksTable(),"wq",C_QuestLog.GetNumWorldQuestWatches())`
- `/run for n=1,C_QuestLog.GetNumQuestWatches() do local q=C_QuestLog.GetQuestIDForQuestWatchIndex(n) local h=C_QuestLog.GetHeaderIndexForQuest(q) local d=C_QuestLog.GetDistanceSqToQuest(q) local g=C_QuestLog.GetQuestTagInfo(q) print(q,h and C_QuestLog.GetInfo(h).title,d and floor(sqrt(d)),g and g.tagName,C_Minimap.IsInsideQuestBlob(q)) end print("zone",GetRealZoneText())`
*Decides:* which sections hand over on Forever (a dungeon whose scenario line shows stages above 0
means every Forever dungeon hands over in version one, and phase 3 moves up); that headers are zone
names matching `GetRealZoneText()`; that distance and the quest area answer on Forever (else the
nearest button falls back to the game's order). Send the output.

**P5. Opening the map from addon code.**
1. Out of combat: `/run QuestMapFrame_OpenToQuestDetails(C_QuestLog.GetQuestIDForQuestWatchIndex(1))`.
   The map opens on the quest. Close it.
2. Start a fight. Open the map with M; click a quest in its list; click a quest's pin on the map;
   shift-click a quest in its list to stop and start tracking it.
3. After the fight, `/reload` and check `Logs/taint.log`.
*Passes:* nothing blocked, no `SetPassThroughButtons` line: Left click's Show on map stays (out of
combat only). *Fails:* SaftUI never opens the map; Left click is Focus only and Show on map leaves the
menu.

## Phasing

Each phase is a whole, shippable step, planned on its own. Every phase keeps the handover for what's
still left, so nothing is lost at any point.

**Phase 1 (version one): quests.** The new addon; the window, header, zone groups, quest rows, popups,
clicks, menu and tooltips; Width, Max height, Grow and the scroll bar; the three item placements and
the nearest button with its key; every fading and hiding trigger; the movers and the Tracker page;
Blizzard's tracker concealed, with the probes and the handover for every other section; the colors on
the Colors tab; OTP standing down; the tests and stubs above. What the owner gets first: all his
quests by zone, sized and scrolling as he likes, with Blizzard's tracker filling in for dungeons and
the rest.

**Phase 2: task quests (bonus objectives and world quests).** Tasks in the area appearing and leaving,
watched world quests, their progress bars, time left and rewards in the tooltip; their item buttons as
quests' (task quests have special items too). Mostly retail; on Forever only if P4 shows any. Removes
the most common retail handover.

**Phase 3: scenarios and dungeons.** The scenario's name, stage, criteria and their bars, stage
timers, delves (tier, lives), proving grounds and warfronts, the scenario's spell buttons (secure,
like item buttons, under the same rules), the scenario's bonus steps, the Maw's buffs (they read
aura data, secret in combat: read out of combat only, or keep handing over for them). Secret criteria
values (`GetUnitCriteriaProgressValues`) passed to widgets, never compared. Moves ahead of phase 2 if
P4 shows Forever's dungeons are scenarios.

**Phase 4: Mythic+.** The challenge mode's key level, affixes, timer with its +2 and +3 marks, deaths
and the enemy forces bar. Retail. Needs phase 3.

**Phase 5: other tracking.** Achievements, tracked recipes with reagent counts, monthly activities,
endeavors and collection tracking: each a section of its own under the window's header, with a
section header showing once more than one section has content. Small, independent parts; can be
split.

**Phase 6: zone widgets.** The objective tracker's widget set
(`C_UIWidgetManager.GetObjectiveTrackerWidgetSetID()`) drawn in SaftUI's tracker. It needs its own
taint study first: Blizzard's widget frames are pooled and shared with the screen's other widget
containers, so hosting them in a SaftUI container could taint those.

**Phase 6 removes the last reason to show Blizzard's tracker.** After it, the handover stays only as a
safety net for a section a later patch adds, and the concealment stays for good: Blizzard's tracker
keeps auto-tracking accepted quests and sorting the watch list for SaftUI's.

## What's left to the builder

- The file split inside SaftUI-Tracker, and the names of its helpers and private functions.
- Where the shared corner math goes in Core, and its name.
- The model's exact table shape, so long as the pure parts (model, groups, layout, probes, handover,
  visibility, nearest) load in the harness without frames.
- How rows, lines and bars are pooled, and how the diff decides what changed.
- Exact text of descs and tooltips, within the gist above and the design system's rules.
- Whether the item layer's driver also hides on `[vehicleui]` and `[overridebar]` (the action bars'
  defaults), after checking that quest items can't be used then.
- Reusing or copying the bags' scroll frame stand-in for the tests.
- **Docs:** a row for SaftUI-Tracker in `AGENTS.md`'s layout table; `.agents/architecture.md` (the
  addon, its module and profile keys, the colors group), `.agents/taint.md` (rule 5's objective
  tracker part: concealment and the never list; the secure item buttons), `.agents/edit-mode.md`
  (the two movers, OTP standing down, the page), `.agents/clients.md` (the quest API differences:
  `IsEliteQuest`, `GetQuestTimers`, Forever's titles and timers), `.agents/testing.md` (the new stubs
  and templates); the design system's README if a new icon (`map-pin`) is registered: add it with
  `tools/lucide-to-tga.cjs` and `st.icons.mapPin`.
- **Followups:** the followup "Objective tracker skin: in-game checks and what was left out" lists zone
  grouping, a max height and a scroll frame as asked for next: mark them taken up by this design, and
  move them to Resolved when phase 1 ships. Phases 2 to 6 get one followup each when phase 1 lands, so
  they're not only in this document.

## Risks

1. **Taint of Blizzard's tracker through the concealment.** Contained: only three C widget methods and
   post-hooks, the never list, the source scan test, P2 before the build and G1 and G2 after.
2. **SaftUI's secure buttons misbehaving in combat.** Contained: made and changed only out of combat,
   on a layer no moving frame depends on, never invisible while clickable, hidden in combat only by a
   state driver; P3 before the build, G1, G4, G5 after.
3. **The world map tainted by Show on map.** Contained: out of combat only, and P5 decides whether it
   stays at all; Focus is always one setting away.
4. **Stutter on quest log updates.** Contained: one refresh a frame, at most ten a second for
   `QUEST_LOG_UPDATE`, pooled frames, text set and measured only when it changed; `refresh_test.lua`.
5. **A section with content that neither tracker shows.** Contained: probes for every known section,
   Blizzard's module state for the rest and for unknown modules, the chat line for an unknown module,
   and the hysteresis only delaying the return, never the handover.
6. **Trackers swapping back and forth** (a widget flickering, a task area's edge). Contained: 2
   seconds without content before SaftUI's comes back.
7. **Blizzard's tracker under SaftUI's buttons during a handover in combat.** Contained: beside, never
   in place, until combat ends.
8. **Forever lacking data retail has** (distance, quest areas, sections). Contained: every read
   guarded by presence; the nearest rule falls back; P4.
9. **A Blizzard patch changing the tracker** (a renamed module, a new one, a moved field). Contained:
   SaftUI reads two fields of its modules and hooks four of its methods; each hook is guarded by
   `type(...) == 'function'` and runs in `xpcall`; an unknown module hands over.
10. **The right column's frames over the tracker's header** at the default spot. Contained: the player
    moves it; G12.
11. **Another addon also hiding Blizzard's tracker.** Contained: the stand-down list.
12. **The colors' move losing a player's custom colors.** Contained: OTP's one-time conversion with its
    marker, and its test.
13. **The enable switch read once.** Contained: the reload prompt, and the chat line on a profile switch
    that changes it.
14. **Equippable quest items equipped by the click.** Accepted as rare; G-check if one turns up, and
    P3's fallback to a `macro` button type if a real quest needs it.

## Later

Beyond the phases, worth a followup each when the owner asks: manual drag ordering and pinned quests;
an automatic "this zone's quests" list (Questions); a find-group button; sounds of SaftUI's own; a
test mode with sample quests for edit mode; filters by quest type.

## Questions only the owner can answer

1. **Only tracked quests, or also the zone's?** SaftUI's tracker shows the game's watch list, as
   Blizzard's does, grouped by zone. Some trackers (EQ) also list every quest of the zone you're in,
   tracked or not. Assumed: the watch list only; a "this zone's quests too" option could come later.
2. **Which phase after version one?** It depends on what P4 finds on Forever and on what you play.
   Assumed order: task quests, scenarios and dungeons, Mythic+, other tracking, zone widgets, with
   scenarios first if Forever's dungeons turn out to be scenarios.

## Calls made while writing this

Ordered by how much the owner is likely to care.

1. **The handover:** Blizzard's whole tracker shows in SaftUI's place while a section SaftUI doesn't
   draw has content; beside SaftUI's if the need starts in combat, moving in place when combat ends;
   SaftUI's returns 2 seconds after the need ends (after combat when its item buttons need showing).
   "Beside SaftUI's" is the other choice of the setting.
2. **Blizzard's tracker is concealed, never hidden:** moved off screen by its one anchor with the C
   `SetPoint` and its clamp off; never `Hide`, `SetShown`, `SetParent`, `SetScale`, a roleset, a size
   or an unregistered event; it keeps laying out, auto-tracking and sorting.
3. **Section content** is read from the game's own data per section plus Blizzard's module state,
   reads only, with a chat line for an unknown section.
4. **The switch is off in the build that lands**, flipped to on once the in-game checks pass; it's read
   at login with a reload prompt.
5. **A new addon, SaftUI-Tracker** (module `Tracker`, profile `tracker`, page "Tracker"), one TOC for
   both clients, optional dependency on SaftUI-Misc.
6. **The skin and mover of Blizzard's tracker stay in SaftUI-Misc**, the mover standing down while
   SaftUI's tracker owns Blizzard's; the skin styles it during a handover.
7. **The two objective colors move to Global settings > Colors > Objectives**, shared by both
   trackers, converted once from the skin's settings.
8. **Blizzard's tracker's page and mover are renamed "Blizzard's tracker".**
9. **Item buttons:** In the row (the default), Beside the tracker (numbered), or Off, plus a separate
   nearest quest item button (off by default) with a key. Each is SaftUI's own
   `SecureActionButtonTemplate` button of type `item`, given the item's link, on a secure layer on
   UIParent that no moving frame depends on.
10. **In combat with row buttons the list doesn't scroll**; with the column or none it does.
11. **A button whose row moved in combat dims to 40%**; no button is ever under 25% while it can be
    clicked.
12. **The nearest item:** inside the quest's area, else the focused quest, else the nearest by
    distance on your continent, else the game's order; chosen every second out of combat; frozen in
    combat.
13. **The key** is the game's own binding (Blizzard's Key Bindings and the Items tab), not a SaftUI
    setting.
14. **Left click:** Show on map out of combat and Focus in combat by default, or Focus always;
    dropped to Focus only if P5 fails.
15. **The menu** keeps Blizzard's entries but gamepad's Share in chat, through `MenuUtil` as the bags
    do; entries that run Blizzard UI Lua are out of combat only.
16. **Every fading trigger defaults to Show**; Faded opacity 30%; Show fully under the mouse on; the
    scroll bar under the mouse only on; quest items stay usable by default.
17. **During a handover the triggers apply to Blizzard's tracker:** Hide conceals it, Fade sets its
    alpha (re-applied after the right column's), hover read from SaftUI's own frames.
18. **Zone groups:** the current zone first, then campaign groups, then the log's order; an "Other"
    group last; collapse states per character.
19. **Order inside a group:** the game's order by default (nearest first, re-sorted by Blizzard on zone
    changes), or quest log order, or level; Finished quests first off.
20. **Titles:** "[level(+)] Title (Tags)", level on by default on Forever and off on retail; difficulty
    colors on; the title in Completed or Failed when finished or failed.
21. **Timers are a line on both clients**, though Forever's own tracker shows none.
22. **Auto quest popups** are rows above the zones, clickable in combat (an in-game check).
23. **The focused quest** gets an accent bar and its waypoint line, and the list scrolls it into view.
24. **The scroll bar is the bags'** (draggable, themed), not the options kit's marker.
25. **Default size:** Width 260, Max height 560, Grow down; the window's header "Objectives" with the
    log count "12/35".
26. **The tracker's first position** is Blizzard's tracker's saved one if the player had moved it, else
    Blizzard's default spot; the nearest button's default is left of it.
27. **The mover's outline is Width by Max height**, the most the tracker can take.
28. **Stand down for other tracker addons** by folder name, two of them unconfirmed.
29. **No settings move from the skin's page:** SaftUI's tracker has its own Font and Header font;
    Blizzard's Edit Mode Height, Opacity and Text Size stay unreachable.
30. **Exact layout numbers:** padding 8, header 24, zone headers 20 with 10 above and 4 below, quest
    spacing 8, objectives indented 12, button size 24, column 4 out, the beside spot 12 out, scroll 40
    a notch.
31. **Hysteresis of 2 seconds** before a handover ends.
32. **The item layer always hides in pet battles.**
33. **A quest item that came in combat shows greyed in its row** until its button comes.
34. **Blizzard's progress blue for bars** (0.26, 0.42, 1), as the skin keeps it.
35. **Phase order** as listed, with scenarios moving up if P4 finds Forever's dungeons are scenarios.

## Settled with the owner after the draft (2026-11-14)

These override anything above that they contradict.

1. **The design is approved.** "All those calls are good". The 35 calls stand as written.
2. **Which quests it shows is a setting:** the tracked quests (the game's watch list) by default, with a toggle to also show every quest in the current zone. "toggleable, but by default only tracked quests". The setting is "Show: Tracked quests | Tracked and the current zone's" on the Tracker page; a current-zone quest that isn't tracked is drawn like any other in its zone group, with nothing to mark it but its place; untracking or tracking it through the menu works as for any quest.
3. **Phase order after version one** stays as call 35 has it; the owner isn't particular. "I'm not picky with where to start".
4. **Building starts before the in-game experiments.** "if you want to start building the core quest tracker we can handle the finer details after". The switch lands off (call 4), so nothing changes for the player until the experiments P1 to P5 have been run and their results folded in. A result that fails changes the part it decides (the concealment for P2, the item button's type for P3, the handover's sections and the nearest button's fallback for P4, Show on map for P5); the plan keeps each of those behind one function so the change is local.
5. (2026-11-14, from Blizzard's constants) The quest log's maximum is read from the game (40 on the owner's client), not assumed to be 35; the item button pool is sized by it.
6. (2026-11-14, the controller's ruling, not the owner's, in the spirit of the anti-goal "a tracker that stutters on quest log updates") Every event goes through one throttle, not only `QUEST_LOG_UPDATE`: the first event after a quiet period refreshes on the next frame, so a single change shows at once; events within `TR.REFRESH_GAP` (0.1 s) of the last refresh are coalesced into one refresh at the end of that gap; a pending refresh is never pushed back by new events, so a steady stream refreshes at most ten times a second and is never starved. This replaces "`QUEST_LOG_UPDATE` ... refreshes at most every 0.1 seconds" in Events and the refresh, which let the events that come with each kill (`UNIT_QUEST_LOG_CHANGED`, `QUEST_WATCH_UPDATE`) through at one refresh a frame.
7. (2026-11-14, the controller's ruling after review) The event list gains `QUEST_DETAIL` (Blizzard's `QuestFrame` adds the offer popup of a quest-starting item in its handler and then closes the quest frame, so no other event fires for it) and `QUEST_DATA_LOAD_RESULT` (a quest's data the log lacked, a title or a popup's, arrives). Both are in `QuestLogDocumentation.lua` on both clients (Forever and retail, read 2026-11-14); each is registered only where the game says the event is valid (`C_EventUtils.IsEventValid`), and both go through the one throttle.
