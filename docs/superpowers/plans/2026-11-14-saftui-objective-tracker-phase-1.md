# SaftUI Tracker, Phase 1 (Quests) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A new addon, SaftUI-Tracker, draws the player's quests in SaftUI's own objective tracker:
- grouped under the quest log's headers, with the current zone first;
- sized by Width and Max height, scrolling past it, with the bags' scroll bar shown under the mouse;
- clicks, Blizzard's menu and tooltips;
- quest item buttons that work in combat, in the row, beside the tracker or off, plus a keybound nearest quest item button;
- every fading and hiding trigger.

Blizzard's tracker stays alive, untouched and off screen. It comes back in SaftUI's place (or beside it) while a section SaftUI doesn't draw yet has content. The two objective colors move to Global settings > Colors. The skin's mover stands down while SaftUI's tracker owns Blizzard's. The switch lands **off**: until the owner turns it on, nothing about either tracker changes.

**Architecture:**
- **Pure parts.** These load without frames and are tested on stubs:
  - the model (`model.lua`, a plain table read from the quest API);
  - zone groups (`groups.lua`);
  - layout math (`layout.lua`);
  - the probes (`probes.lua`);
  - the handover's rules (`handover.lua`, `Next(state, ...) -> state, actions`);
  - the visibility resolver (`visibility.lua`);
  - the nearest item's choice (`nearest.lua`).
- **Frame parts.**
  - The window (`window.lua`): a holder that is the mover, plus a window that is never protected.
  - The rows (`rows.lua`): pooled, with text set and measured only when it changed.
  - The secure item layer on UIParent (`items.lua`), whose buttons are made, placed and given attributes only out of combat.
  - Blizzard's tracker (`blizzard.lua`): moved only by three C methods and kept there by post-hooks.
- **The refresh.** Events only mark it dirty. It runs once a frame, and at most every 0.1 s for `QUEST_LOG_UPDATE`. Each run goes through model → groups → layout → rows → items → probes → handover → visibility.
- **One function per experiment.** Each of the four things an experiment decides lives behind one named function (see Experiment seams).

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0 (its profile and `char` namespaces); SaftUI's options kit through AceConfig tables (`st.Config.generators`, the `default` field, `st.OptionsWidgets.Confirm`); edit mode (`st:RegisterMover`); Blizzard's `MenuUtil`, `SecureActionButtonTemplate` and `SecureHandlerStateTemplate`; tests on stubs, run with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-14-saftui-objective-tracker-design.md`. Its last section, "Settled with the owner after the draft", overrides anything above it that it contradicts:
- Settled 1 approves the design and its 35 calls.
- Settled 2 adds the setting **Show: Tracked quests | Tracked and the current zone's** (`quests.show`, default tracked).
- Settled 3 keeps call 35's phase order; this plan covers Phase 1 only.
- Settled 4: building starts before the in-game experiments P1 to P5. The switch lands off, and each thing an experiment decides is kept behind one function.

The study `docs/research/2026-11-14-objective-tracker-enhancements.md` is the source for facts. API signatures were checked against Gethe/wow-ui-source `forever` and `live` (`QuestLogDocumentation.lua`, `QuestInfoSharedDocumentation.lua`, `ContentTrackingTypesDocumentation.lua`, `Blizzard_QuestObjectiveTracker.lua`, `Blizzard_ObjectiveTrackerModule.lua`).

**Assumed state.** `modular` at `3630686`, with the edit mode bar and window sizes plans merged. `st.icons.mapPin`, `chevronUp`, `chevronDown` and `rotateCcw` exist, and so do `st:PlaceHolder`, `st:SafeReposition`, `st:QueueAfterCombat`, `st:HideEditModeSelection`, `st:ClearAllPointsDirect`, `st:SetPointDirect`, `st:KeepInScreenMargin`, `st:CreateScrollFrame`, `st:ScrollBarRoom`, `st.Plain*`, `st.TINT_ROW`, `st:IconTexCoords` and `W.Confirm`.

## How the tasks are cut

| # | Task | Needs | Owner can try in game |
| --- | --- | --- | --- |
| 1 | The addon, switched off | — | nothing changes; the Tracker page shows its switch |
| 2 | The objective colors move to Global settings > Colors | — | the colors on the Colors tab; custom ones carried over |
| 3 | The data: quest stubs, the model, zone groups | 1 | nothing visible (stub tests) |
| 4 | The window: holder, mover, header, size, scroll | 3 | switch on: an empty window that sizes, scrolls and moves |
| 5 | Rows and the refresh | 4 | switch on: quests by zone (Blizzard's still shows) |
| 6 | Blizzard's tracker concealed; the mover stands down; the renames | 5 | switch on: only SaftUI's tracker |
| 7 | Clicks, the menu, tooltips | 5 | clicks and the menu |
| 8 | The item layer and row buttons | 6 | items in rows, in combat |
| 9 | The column beside the tracker, and Off | 8 | the other placements |
| 10 | The nearest quest item button and its key | 8 | the big button and its key |
| 11 | Sections and the handover | 6, 8 | dungeons hand over to Blizzard's |
| 12 | Fading and hiding | 11 | every trigger |
| 13 | Every state together; docs; the in-game checklist | all | the full checklist |

**Side by side.** Tasks 1 and 2 share no code file:
- Task 1 owns `SaftUI-Tracker/`, `tests/tracker/` and `tests/lib/theme_helpers.lua`.
- Task 2 owns `SaftUI-Core/Config/defaults.lua`, `Media/colors.lua`, the skin, `SaftUI-Misc/config.lua` and their tests.

Both edit `.agents/architecture.md`, so merge by hand, keeping both sides. Tasks 3 to 13 run in order: each edits `init.lua`, `options.lua`, `tests/tracker/tracker_world.lua` or the TOC that the one before it edits.

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder changes.
- **Blizzard's tracker (`.agents/taint.md`, restated).**
  - **Never called:** `Show`, `Hide`, `SetShown`, `SetParent`, `SetScale`, `SetSize`, `SetWidth` or `SetHeight` on it; `SetRolesets` or `AddRoleset`; `UnregisterEvent` or `UnregisterAllEvents` on it or its modules; `RemoveModule`, `SetModuleContainer`, `RemoveAllModules`, `MarkDirty`, `Update`, `UpdateHeight`, `SetCollapsed`, `ToggleCollapsed`, `Collapse`, `Expand`, `ForceExpand`, `SetOpacity`, `SetTextSize`, or any method of the tracker, its modules or `ObjectiveTrackerManager`; `ShouldShowMawBuffs` or any aura read.
  - **No writes:** no Lua field is ever written onto them.
  - **Rect reads:** only `GetPoint`, `GetNumPoints`, `GetParent`, `GetWidth(true)` and `GetHeight(true)` (no `GetRect`, `GetLeft`, `IsMouseOver`...).
  - **Allowed, and nothing else:**
    - `ClearAllPoints`, `SetPoint` and `SetClampedToScreen` through `getmetatable(frame).__index`;
    - the C `SetAlpha` during a handover that fades;
    - `hooksecurefunc` post-hooks on the tracker's `SetPoint`, `ClearAllPoints`, `UpdateHeight` and `SetAlpha`, and on each module's own `Update`. Each runs in `xpcall` to `geterrorhandler()` and is installed only where `type(...) == 'function'`;
    - reads of module `state` and `hasContents`;
    - `ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing()`;
    - `st:HideEditModeSelection`.

    `tests/tracker/source_scan_test.lua` enforces the list (Task 6).
- **Secure buttons.**
  - Created, anchored, sized, shown, hidden and given attributes only out of combat. In combat, the change is queued with `st:QueueAfterCombat('tracker_items' | 'tracker_nearest' | 'tracker_binding', fn)`, and one pass makes everything right when combat ends.
  - Never a child of, or anchored to, a SaftUI frame that must move in combat. The window, the scroll frame and the rows are never protected, so every combat test ends with `stub.blocked` empty.
  - Never invisible while clickable: a button is either hidden, or at 25% alpha or more.
- **Both clients.** Every API is guarded by presence: a missing function makes its part absent, never an error. Values pass through `st.PlainNumber` / `st.PlainString` / `st.Plain` (or are tested with `issecretvalue`) before any arithmetic or comparison. A title goes to `SetText` as it is.
- **Whole pixels.** Offsets and sizes go through `st:RoundToPixel`. A height read back is rounded (`floor(x + 0.5)`), never `ceil`ed; only a text's width is `ceil`. Frames are placed by a corner. Every new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard, with `stub.size_noise` set to `2 ^ -14`, `-2 ^ -14` and `0`.
- **Scripts.**
  - The game calls `OnEnter` and `OnLeave` with a second argument, `motion`. Wrap each script as `function(self) ... end`, and fire hover scripts in tests with `true`.
  - Kit controls take `control.onClick`, never `SetScript('OnClick')`. The tracker's window uses no kit control: its chevrons and rows are its own plain Buttons, as the skin's are.
- **Look.** Icons are Lucide's (`st.icons`), and an icon-only control has a tooltip. Every reset is per setting (the `default` field); no section or page has a Reset. Names are sentence case, in American spelling.
- **The switch.** It lands **off** (`tracker.enable = false`). It is read once, at login (`TR:IsOn()`). While it's off, SaftUI-Tracker makes no frame, hook, event, mover or binding change, and Blizzard's tracker, the skin and the skin's mover behave as today. Every task's tests keep one case proving it for that task's code.
- **No build step.** The TOC is the file list. `tests/tracker/tracker_world.lua` reads it, so a new file needs only its TOC line.
- **Commits.** Lowercase `module: imperative summary`. Stage by explicit path. End with the session's `Co-Authored-By` line.
- **Docs.** Each task updates the `.agents/*.md` docs whose `covers:` lists its files, plus `AGENTS.md`'s layout row when it adds a file. Then it runs `agents-doc-parity-check` and `readme-freshness-check`, and hands back its in-game checks.
- **Tests.** Each task ends green on `tests/run -j2`. Run single files while working. An earlier test's assertion is changed only where this work changes what it pins, and the report lists each one.

## Review Focus

1. **Combat starting between a dirty mark and its refresh, with item buttons in rows.** `PLAYER_REGEN_DISABLED` fires after a `QUEST_LOG_UPDATE` has queued a refresh, so the refresh runs in lockdown. The rows redraw, no secure call is made, the buttons stay put (one whose row moved dims to 40%), and one pass at combat end puts them right. Test: Task 8, `'combat starting before a queued refresh'`.
2. **A `/reload` in combat with the switch on.** The window, rows and concealment are built at once. Rows show the greyed item icons. No secure frame is made until `PLAYER_REGEN_ENABLED`, when the layer, its driver, the buttons and the nearest button are made once. The handover starts from own. Tests: Task 8, `'a /reload in combat'`, and Task 6, `'concealed at once after a /reload in combat'`.
3. **A quest the log can't place:**
   - `GetHeaderIndexForQuest` returns nil;
   - the index points at an entry `GetInfo` gives nothing for, or one that isn't a header;
   - a secret header title;
   - a quest with no title yet;
   - two headers with the same title.

   None of them errors. The first three go to Other, last. The untitled quest is skipped. The two headers merge in the first one's place. Test: Task 3, `'quests the log can't place'`.
4. **A burst of quest log updates on a full log**, with Show set to Tracked and the current zone's: 200 `QUEST_LOG_UPDATE`s over 2 s, on 25 watched quests plus 10 untracked zone quests of 6 objectives each. At most 21 refreshes run. Only the first makes frames. A refresh with nothing changed sets no text. Test: Task 5, `'a burst on a full log'`.
5. **A profile switch while Blizzard's tracker is concealed or handed over.** Both `OTP:UpdateConfig` and `TR:UpdateConfig` run. Blizzard's tracker stays where SaftUI's state says, and OTP moves nothing. A new profile with no `tracker.position` gets its first position. A profile whose `enable` differs prints the chat line once. Collapsed groups stay (they're per character). Tests: Task 6, `'a profile switch while concealed'`, and Task 11, `'a profile switch during a handover'`.

## Rulings on the spec

1. **The switch off still shows two changes.** The colors move (Task 2) and the renames (Task 6) are spec'd outright and ship visible with the switch off. "Nothing changes" means both trackers' behaviour and look.
2. **Where the colors' defaults live.** `st.defaults.colors` is in `SaftUI-Core/Config/defaults.lua`, not `colors.lua` (the code), so `objectives = { completed, failed }` goes there. The Colors tab's Objectives section is last, after Threat. Its keys are `completed` and `failed`, the skin's state names.
3. **No new icon.** `st.icons.mapPin` is already registered, so the tracker adds none. The Icons README gains the tracker's uses (map-pin and the chevrons).
4. **Files.** The handover's rules get a file of their own, `handover.lua`. The Core helpers are `st:DefaultTrackerPosition()` (Blizzard's default spot, a fresh table) and `st:CornerOffset(frame, parent, point, screenX, screenY) -> x, y | nil` (OTP's corner math), both in `SaftUI-Core/api.lua` and used by OTP and SaftUI-Tracker.
5. **The latch.** `TR:IsOn()` latches on its first call: enable on, and no other tracker addon loaded. OTP may ask before `TR:OnEnable` runs (Misc enables first), so both read one answer all session. `TR:OwnsBlizzard()` is `TR:IsOn() and _G.ObjectiveTrackerFrame ~= nil`, from Task 6.
6. **Position and Grow.** `tracker.position` places the holder (Width by Max height) by whatever point it names, `TOPRIGHT` by default. Grow only picks the holder edge the window hangs from, so a Grow change converts no position. The Position desc reads: "Where the tracker's box is (its top right corner by default). The list grows down from its top, or up from its bottom with Grow up."
7. **First position (call 26).** It is written once into `tracker.position`: a copy of `objectivetracker.position` when Misc is loaded and the profile has one, else `st:DefaultTrackerPosition()`. It is written again for a profile with none (a new or reset profile).
8. **The nearest button's default.** `items.nearest_position` has an AceDB default, since there is nothing to inherit. Its mover is a plain `st:RegisterMover`, because the key isn't `position`.
9. **The current zone's quests (Settled 2).**
   - With Show set to Tracked and the current zone's, the model also reads every log quest whose header is the current zone (by `TR.Groups.IsCurrent`), using the same display rule.
   - Untracked ones come after the tracked in that group, in log order. "The game's order" has no watch index for them.
   - The menu offers `TRACK_QUEST` (or "Track quest" where the client lacks the string) in place of Stop tracking, which calls `C_QuestLog.AddQuestWatch`. Shift-click tracks.
   - They get item buttons as any row does, so the pool's cap is 35, the log's most (`TR.ITEM_POOL_MAX`).
   - The nearest button chooses among tracked quests only.
10. **Bounties.** Blizzard's `ShouldDisplayQuest` tests `quest.isBounty and not isComplete`, where `isComplete` is an undefined global (both branches), so Blizzard never shows a bounty. SaftUI leaves bounties out too. Hidden quests are left out as the spec says.
11. **A quest row's lines, in order:**
    - its objectives, or the completion lines;
    - money;
    - the timer;
    - the waypoint.

    A `progressbar` objective is drawn as the bar in place of its line while Progress bars is on, and as its text line while it's off. A bar takes 3 above and 3 below with no line gap of its own. A row with a button in it is at least Button size tall.
12. **Timers.** Where `C_QuestLog.GetQuestTimers` exists (Forever), the quest's `questTimer` is the time left; else `total - elapsed` from `GetTimeAllowed`. The time is shown as `m:ss`, or `h:mm:ss` from an hour up, counted down from the read by the 1 s ticker.
13. **Titles.** Tags are joined by spaces: `"(Elite) (Daily)"`. Daily and Weekly come from `DAILY` and `WEEKLY`. A secret title is shown as it is, with no level or tags.
14. **The header's tooltip at the watch limit.** Its second line reads "12 of 35 quests in your quest log, 25 tracked: the most you can track."
15. **Collapsed and empty windows.** A collapsed window is 40 tall (8, the header's 24, 8). With Header off there's no whole-tracker collapse, and the saved state is ignored. Popups show the window expanded without changing the saved state.
16. **The Other group.** Its title is "Other" and its collapse key is `TR.OTHER_KEY = '*other'`, so a real header titled "Other" stays apart. A quest whose header title is secret goes to Other: it can't be compared.
17. **The scroll lock.** While it's on, `window.barLock`, a SaftUI frame over the bar, takes its mouse, shows the tooltip and swallows drags, and the wheel handler returns. The bar shows at 40%.
18. **Popups.** They are `spacing` apart, and the first zone header takes its 10 above when popups precede it.
19. **Menu entries that run Blizzard UI Lua** are created disabled in combat (`SetEnabled(false)`), with the tooltip "Out of combat only" where the element description has `SetTooltip`.
20. **The item layer.** It fills UIParent (`SetAllPoints`) and takes no mouse. Each button is anchored by its `TOPLEFT` to UIParent's `BOTTOMLEFT` at the row's or column's rect (left, top).
21. **The driver.** It gets no `[vehicleui]` or `[overridebar]` in Phase 1. A followup checks whether quest items work then (Task 13).
22. **Stand-down labels:** `!KalielsTracker` "Kaliel's Tracker", `EQObjectiveTracker` "EQ Objective Tracker", `KaLiQuest` "KaLi Quest", `AuraQuestor` "Aura Questor", `ForeverQuestTracker` "ForeverQuestTracker".
23. **The profile chat line** prints once per value: when a profile's `enable` differs from the session's and from the last value warned about. `Config:UpdateConfig` also runs on theme changes, which mustn't repeat it.
24. **The scroll frame in tests.** `window.lua` makes it through `TR.NewScrollFrame(parent)`, which is `st:CreateScrollFrame` in game. `tracker_world.lua` sets it to a copy of the bags' stand-in. It goes in `.agents/testing.md`'s rule 1 stand-in list.
25. **Quest stubs.** They go in a new `tests/wow/quests.lua`, which `game.lua` loads as `blizzard.lua` loads `atlases.lua`. `stub.apply_client` gains namespace members (`C_QuestLog.IsEliteQuest`, `GetQuestTimers`: Forever only).
26. **Option rows land with their features.** Task 1's walker case covers every row that exists at each stage.
27. **The beside spot and the column.** The column's width is Button size. Each column button is numbered among the quests with an item in list order, scrolled-out ones included, so a number never changes as the list scrolls.
28. **A mode change** runs `Next` once back to own (out of combat: `/sui` is closed in combat), then once from own.
29. **The concealed spot's y** is the y of the spot the current mode reveals at: in place, or beside.
30. **The row tooltip's anchor.** Its top right sits 8 left of the row's top left, which is the window's left edge (PAD 8).
31. **Faded item buttons** use `max(fade_alpha, TR.BUTTON_MIN_ALPHA)`.
32. **The waypoint line** reads `('Waypoint: %s'):format(text)`, for the focused quest only.

## Experiment seams

| Experiment | The one function | As designed | If the experiment fails |
| --- | --- | --- | --- |
| **P2** (concealment) | `TR:PlaceBlizzard(where)` in `blizzard.lua`, `where` = `'concealed' \| 'place' \| 'beside'` | Clamp off for concealed, on otherwise, by the C `SetClampedToScreen`. Then the C `ClearAllPoints` and C `SetPoint('TOPRIGHT', parent, 'TOPRIGHT', x, y)` (`'TOPLEFT'` beside on the right) to its own parent. Concealed: the spot's y, and an x that puts its right edge 100 left of UIParent's left. Skipped when its one point is already that. The hooks, the handover and visibility only ever call this. | Only the `'concealed'` branch changes (to the C `SetAlpha(0)` plus `EnableMouse(false)` of taint.md rule 8, or whatever the log points to), along with `conceal_test.lua`'s spot cases. |
| **P3** (item button type) | `TR.ItemAttributes(item) -> attributes` in `items.lua` | `{ type = 'item', item = item.link }`. Every row, column and nearest button sets attributes only through `TR:SetButtonItem(button, item)`, which applies this table and clears the attributes it doesn't name. | Returns `{ type = 'macro', macrotext = '/use item:' .. id }` (`id` from the link), for every item or for the kinds P3 names. Nothing else changes. |
| **P4** (sections) | `TR.SectionHandsOver(key) -> boolean` in `probes.lua` | True for every section in `TR.SECTIONS` and every unknown module. | A section P4 finds always filled on Forever (in the open world) returns `not st.forever` for it. |
| **P4** (nearest fallback) | `TR.ChooseNearest(candidates, focusedID) -> quest \| nil` in `nearest.lua` | Inside its area, else the focused quest, else the smallest distance on your continent, else the game's order. | Where distance or the quest area don't answer on Forever, steps 1 and 3 are skipped on Forever (`st.forever`), leaving focus, then the game's order. |
| **P5** (Show on map) | `TR.ShowOnMapAllowed() -> boolean` in `clicks.lua` | `TR.SHOW_ON_MAP` (true) and `type(QuestMapFrame_OpenToQuestDetails) == 'function'`. Read by the click, the menu, the tooltip hint and Left click's values. | `TR.SHOW_ON_MAP = false`. Left click offers Focus only (a saved `'map'` reads as focus), the menu drops Show on map, and the hint reads "Click: focus." |

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Tracker/SaftUI-Tracker.toc`, `Bindings.xml` | load order; the nearest key's binding | 1 (each task adds its line) |
| `SaftUI-Tracker/config.lua` | `st.defaults.tracker`, binding strings | 1 |
| `SaftUI-Tracker/init.lua` | module, latch, stand-down, `Build`, `UpdateConfig`, events, the refresh | 1, 5 |
| `SaftUI-Tracker/model.lua`, `groups.lua` | the model, titles and lines; zone groups | 3 |
| `SaftUI-Tracker/layout.lua` | layout constants and math | 4, 5, 11 |
| `SaftUI-Tracker/window.lua` | holder, mover, window, header, scroll | 4, 8, 9, 12 |
| `SaftUI-Tracker/rows.lua` | row pools and drawing | 5, 7, 8, 9 |
| `SaftUI-Tracker/blizzard.lua` | Blizzard's tracker: concealment, hooks, module watch, alpha | 6, 11, 12 |
| `SaftUI-Tracker/clicks.lua` | clicks, menu, tooltips | 7 |
| `SaftUI-Tracker/items.lua` | the secure layer, row and column buttons | 8, 9, 12 |
| `SaftUI-Tracker/nearest.lua` | the nearest button, its choice and key | 10 |
| `SaftUI-Tracker/probes.lua`, `handover.lua` | section content; the handover | 11 |
| `SaftUI-Tracker/visibility.lua` | the resolver and its applier | 12 |
| `SaftUI-Tracker/options.lua` | the Tracker page | 1, 4, 5, 7–12 |
| `SaftUI-Core/api.lua` | `st:DefaultTrackerPosition`, `st:CornerOffset` | 4, 6 |
| `SaftUI-Core/Config/defaults.lua`, `Media/colors.lua` | the Objectives colors | 2 |
| `SaftUI-Misc/config.lua`, `Skinning/blizzard/Blizzard_ObjectiveTracker.lua`, `Blizzard_ObjectiveTrackerPosition.lua` | colors move; standing down; renames | 2, 4, 6 |
| `tests/wow/quests.lua` (new), `game.lua`, `widgets.lua` | quest, binding, probe stubs; secure templates | 3, 7, 8, 10, 11, 12 |
| `tests/misc/fixtures/objective_tracker.lua` | Edit Mode overrides guarded; modules' state | 6, 11 |
| `tests/tracker/` (new) | the world helper and every tracker test | 1–13 |

---

### Task 1: The addon, switched off

**Files:**
- Create:
  - `SaftUI-Tracker/SaftUI-Tracker.toc`: `## Interface: 120000, 16001`, `## Version: 1.0`, `## Title: |cff00adefSaftUI Tracker|r`, `## RequiredDeps: SaftUI-Core`, `## OptionalDeps: SaftUI-Misc`, `## Group: SaftUI-Core`, then `config.lua`, `init.lua` and `options.lua`. Later files go in before `options.lua`, in the File structure's order.
  - `SaftUI-Tracker/Bindings.xml`: `<Bindings><Binding name="CLICK SaftUITrackerNearestItem:LeftButton" header="SAFTUI" category="ADDONS"/></Bindings>`.
  - `SaftUI-Tracker/config.lua`, `init.lua`, `options.lua`.
- Modify: `tests/lib/theme_helpers.lua`, where `T.ADDONS` gains `'SaftUI-Tracker'` (last), so `theme_kinds_test`, `theme_blizzard_draw_test` and `editmode_movers_test` scan it.
- Test: create `tests/tracker/tracker_world.lua`, `tests/tracker/switch_test.lua` and `tests/tracker/options_test.lua`.
- Docs:
  - `AGENTS.md`: a layout row for `SaftUI-Tracker/`, and "What this is".
  - `.agents/architecture.md`: the addon, its one TOC and OptionalDeps, module `Tracker`, profile `tracker`, `st.config.char.tracker`; covers gains `'SaftUI-Tracker/**'`.
  - `.agents/edit-mode.md`: the Info group gains Tracker; the stand-down.
  - `.agents/testing.md`: the `tests/tracker/` row and `TW`.
  - `README.md` line 3.

**Interfaces:**
- Produces:
  - `st.defaults.tracker` (`config.lua`, at file load):

```lua
st.defaults.tracker = {
	enable = false, theme = 'theme', background = 'theme',
	width = 260, height = 560, grow = 'down', header = true, count = true, hide_empty = true,
	font = 'normal', header_font = 'normal', -- position: no default (Ruling 7)
	quests = {
		show = 'tracked', zones = true, current_first = true, order = 'game', finished_first = false,
		level = st.forever, tags = true, difficulty = true, icons = true, hide_finished = false,
		finished_objectives = false, bars = true, timers = true, waypoint = true, tooltips = true,
		left_click = 'map', spacing = 8,
	},
	items = {
		placement = 'row', size = 24, cooldown = true, count = true, range = true, nearest = false, nearest_size = 40,
		nearest_position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -320, y_off = st.forever and -275 or -260 },
	},
	visibility = {
		combat = 'show', nocombat = 'show', mouseoff = 'show', instance = 'show', boss = 'show', mythic = 'show',
		fade_alpha = 0.3, hover = true, background_hover = false, scrollbar_hover = true, items = false,
	},
	blizzard = { mode = 'place' },
}
```

  - `config.lua` also sets `BINDING_HEADER_SAFTUI = 'SaftUI'` and `_G['BINDING_NAME_CLICK SaftUITrackerNearestItem:LeftButton'] = 'Use the nearest quest item'`.
  - `TR = st:NewModule('Tracker')`, with `st.Tracker = TR` and `TR.NEAREST_COMMAND = 'CLICK SaftUITrackerNearestItem:LeftButton'`.
  - `TR.TRACKER_ADDONS` (`{ addon, label }`, in Ruling 22's order) and `TR:TrackerAddon() -> label | nil`, which reads `C_AddOns.IsAddOnLoaded`.
  - `TR:IsOn() -> boolean`, latched (Ruling 5).
  - `TR:OnEnable()`: `st:BindModuleConfig(self, 'tracker')`, then returns while `not self:IsOn()`, else runs `self:Build()`. `TR:Build()` runs once and makes nothing yet; each later task adds its builder there. No file makes a frame at load.
  - `TR:UpdateConfig()`: the chat line "SaftUI's tracker changes after a reload." (Ruling 23), then returns until built.
  - `TR:CharData() -> { zones = {}, collapsed = false }`, kept in `st.config.char.tracker`.
  - `TR.SettingDefault(group, key) -> { differs, reset, value }`. `group` is nil for General's keys, else `'quests' | 'items' | 'visibility' | 'blizzard'`. It compares against `st.defaults.tracker`, reset writes a copy, and both then run `TR:UpdateConfig()`.
  - `TR:GetConfigTable()`: page `'Tracker'`, `category = 'Info'`, `childGroups = 'tab'`. Tabs `general` (1), `quests` (2), `items` (3), `visibility` (4) and `blizzard` (5) are added by their tasks. Every tab but General is `disabled` while `not TR:IsOn()`, with `disabledDesc` "Turn on SaftUI's tracker (General) and reload.".
    - `general.args.enable`: `generators.toggle(1, "SaftUI's tracker", "Draws your quests in SaftUI's own tracker, grouped by zone, in place of Blizzard's objective tracker. Changes after a reload.")`. Its `set` saves, then calls `st.OptionsWidgets.Confirm("SaftUI's tracker changes after a reload. Reload now?", ReloadUI)`.
    - Standing down: the page is `disabled`, and `tracked_by` (a description, order 0, `disabled = false`) reads "Quests are tracked by <label>. Turn it off to use SaftUI's.".
  - `tests/tracker/tracker_world.lua` returns `TW`:
    - `TW.toc_files()`: the TOC's Lua files, in order.
    - `TW.world(opts) -> st, TR`. `opts` takes `client`, `on`, `misc` (Misc's config, skinning, skin, OTP), `blizzard` (`OT.build()` from the misc fixture), `combat` (`stub.in_combat` at enable), `addons` and `before`. It runs `T.client`, `load_editmode()`, `st.config.char = {}`, the TOC files with `apply_defaults()` after `config.lua`, then `TR:Enable()`.
    - `TW.counts`: frames, hooks, events and secure frames counted after Core loads, by wrapping `CreateFrame`, `hooksecurefunc` and the frame `RegisterEvent`.
    - `TW.combat(on)`: sets `stub.in_combat` and fires `PLAYER_REGEN_DISABLED` / `PLAYER_REGEN_ENABLED`.

- [ ] **Step 1: Write the failing tests**

`switch_test.lua` (each case on both clients where it says so):

```lua
test('the TOC: both clients, Core required, Misc first, every listed file exists; Bindings.xml and its strings', function()
	-- the TOC's six header lines as above; read_saftui_source of each listed file is not nil
	-- Bindings.xml holds the CLICK binding, header SAFTUI, category ADDONS
	-- BINDING_HEADER_SAFTUI == 'SaftUI'; _G['BINDING_NAME_' .. TR.NEAREST_COMMAND] == 'Use the nearest quest item'
end)
test('off by default: enabling builds no frame, hooks nothing, registers no event or mover', function()
	-- TW.world({}): TW.counts.frames == 0, hooks == 0, events == 0; EM.movers.tracker == nil; TR:IsOn() == false
end)
test('the switch is read once: set on in /sui it saves, asks to reload, and builds nothing now', function()
	-- set(true): profile.tracker.enable; W.ConfirmText() == "SaftUI's tracker changes after a reload. Reload now?"; IsOn false
end)
test('on at login, IsOn stays on whatever the profile says later', ...)
test('another tracker addon: on builds nothing; the page is disabled with the line naming it; each folder has its label', ...)
test('a profile whose switch differs says once in chat that it changes after a reload, not again on a theme change', ...)
test('Level is on on Forever and off on retail', ...)
```

`options_test.lua` (Task 1's walker, which every later task's rows pass through):

```lua
test('the page: Tracker under Info, its tabs in order, General first with the switch, the others disabled while off', ...)
test('every option has a desc and no width; every value option has a default that resets it to st.defaults.tracker', function()
	-- each_option: toggle, range, select and color carry default; set a non-default through set ->
	-- differs() true; reset() -> get == st.defaults.tracker's value, differs() false; no execute named Reset
end)
test("the tree passes AceConfigRegistry's validator (ace_ready, in core/config_helpers.lua's world)", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker`. Expected: FAIL, `can't read SaftUI-Tracker/SaftUI-Tracker.toc`.
- [ ] **Step 3: Implement** the files as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker tests/core/theme_kinds_test.lua tests/core/theme_blizzard_draw_test.lua tests/core/editmode_movers_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/Bindings.xml SaftUI-Tracker/config.lua SaftUI-Tracker/init.lua SaftUI-Tracker/options.lua tests/lib/theme_helpers.lua tests/tracker/tracker_world.lua tests/tracker/switch_test.lua tests/tracker/options_test.lua AGENTS.md .agents/architecture.md .agents/edit-mode.md .agents/testing.md README.md
git commit -m "tracker: add SaftUI-Tracker, switched off, with its page and binding"
```

**In-game checks:** link the folder into both flavors with `mklink /D`. On each, log in with no Lua errors. `/sui` shows Tracker under Info with its switch off. Blizzard's tracker, its skin and its mover are as before. Key Bindings > AddOns > SaftUI lists "Use the nearest quest item".

---

### Task 2: The objective colors move to Global settings > Colors

**Files:**
- Modify:
  - `SaftUI-Core/Config/defaults.lua`: `st.defaults.colors.objectives`.
  - `SaftUI-Core/Media/colors.lua`: `CO.SECTIONS` gains Objectives, last.
  - `SaftUI-Misc/config.lua`: `status_colors` leaves `st.defaults.objectivetracker`.
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua`: `OT:StatusColor`, `ColorLine` and `OT:OnColorsChanged`.
  - `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua`: `OTP:MoveStatusColors`, called in `OnEnable` and `UpdateConfig`. The page's Objective colors section becomes a description row.
- Test: modify `tests/core/colors_test.lua` and `tests/misc/objective_tracker_status_test.lua`.
- Docs:
  - `.agents/architecture.md`: `st:ColorsChanged`'s groups gain `objectives`; the conversion marker joins "A module that converts its profile once".
  - `.agents/taint.md` rule 1: the status colors paragraph now names `colors.objectives`.

**Interfaces:**
- Produces:
  - `st.defaults.colors.objectives = { completed = CreateColor(0.251, 0.753, 0.251), failed = CreateColor(220/255, 100/255, 100/255) }`.
  - Objectives is `{ key = 'objectives', name = 'Objectives', colors = Colors('objectives', { { 'completed', 'Completed', desc }, { 'failed', 'Failed', desc } }) }`. Each desc names both trackers' lines: SaftUI's, and Blizzard's while it's skinned.
  - `OT:StatusColor(state) -> color | nil`: `st.config.profile.colors.objectives[state]`, read with `:GetRGB()`.
  - `OT:OnColorsChanged(group)`: as today, plus `self:RecolorLines()` for `'objectives'` and `'theme'`.
  - `OTP.OLD_STATUS_COLORS = { completed = { 0.251, 0.753, 0.251 }, failed = { 220/255, 100/255, 100/255 } }`.
  - `OTP:MoveStatusColors() -> boolean`. Runs in `OTP:OnEnable` after `st:BindModuleConfig` and first in `OTP:UpdateConfig`, in combat too (table writes only). If `config.status_colors` is a table and `config.colorsMoved` isn't set, each saved state gets its missing slots from `OLD_STATUS_COLORS` and is written with `colors.objectives[state]:SetRGB(r, g, b)`. Then `status_colors` is set to nil and `colorsMoved = true`. With nothing saved, only the marker is set.
  - The page's `colors` row: a description, "Finished and failed objectives take Global settings > Colors > Objectives.".

- [ ] **Step 1: Write the failing tests**

```lua
-- colors_test.lua
-- the sections case: 'Text,Buttons,Class,Reputation,Power,Item quality,Status,Threat,Objectives'; expected.objectives = 'Completed,Failed'
-- the notes case's list gains 'objectives'; a reset of Completed puts the default back and fires 'objectives'
-- objective_tracker_status_test.lua (both clients)
test('a profile with the old colors keeps them on the Colors tab, once, slots AceDB dropped filled from the old defaults', function()
	-- profile.objectivetracker.status_colors = { completed = { [2] = 0.9 } } before OTP:Enable
	-- T.rgb(colors.objectives.completed:GetRGB()) == T.rgb(0.251, 0.9, 0.251); failed at its default
	-- status_colors == nil; colorsMoved == true; a Colors-tab change, then OTP:UpdateConfig(): the change stays
end)
test('a profile switched to in combat converts before the next layout, with stub.blocked empty', ...)
test('a profile with nothing saved gets only the marker', ...)
test('a Colors tab change recolors the skin\'s lines at once (st:ColorsChanged("objectives"))', ...)
test('the page: no Objective colors section; a description row names Global settings > Colors > Objectives', ...)
-- the existing cases set colors through profile.colors.objectives instead of status_colors
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/colors_test.lua tests/misc/objective_tracker_status_test.lua`. Expected: FAIL, Objectives is missing.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/core tests/misc`, then `tests/run -j2`. Expected: PASS. Each changed assertion is listed in the report.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/defaults.lua SaftUI-Core/Media/colors.lua SaftUI-Misc/config.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua tests/core/colors_test.lua tests/misc/objective_tracker_status_test.lua .agents/architecture.md .agents/taint.md
git commit -m "core: move the objective colors to Global settings > Colors, converting the old ones once"
```

**In-game checks:** with custom colors set before this build, they show on Colors > Objectives, and the skin's lines keep them. A Colors-tab change recolors Blizzard's tracker at once. The Objective tracker page shows the description row.

---

### Task 3: The data: quest stubs, the model, zone groups

**Files:**
- Create: `tests/wow/quests.lua`, loaded at the end of `tests/wow/game.lua` with `load_test_file('wow/quests.lua')`.
- Modify: `tests/wow/game.lua`. `stub.apply_client` drops `CLIENT_ONLY_MEMBERS`, which holds `{ C_QuestLog, 'IsEliteQuest', 16001 }` and `{ C_QuestLog, 'GetQuestTimers', 16001 }`.
- Create: `SaftUI-Tracker/model.lua` and `groups.lua`, both added to the TOC.
- Test: create `tests/tracker/model_test.lua` and `groups_test.lua`. Add a case to `tests/lib/harness_self_test.lua`: the two Forever-only members exist only under `use_client('forever')`, and a non-number `questID` errors with its `Usage:`.
- Docs:
  - `.agents/testing.md`: the `tests/wow/` row gains `quests.lua` and `stub.quests`.
  - `.agents/clients.md`: Objective tracker gains the quest API differences: `IsEliteQuest` and `GetQuestTimers` are Forever only; Forever's title prefix and its lack of a timer bar; Ruling 10. Covers gains `'SaftUI-Tracker/model.lua'`.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Task 1.
- Produces (stubs):
  - `stub.quests = { log = { entry, ... }, watched = { questID, ... }, focused = 0, popups = { { id, kind } }, max = 35 }`.
  - A header entry is `{ header = true, title, campaignID }`.
  - A quest entry is `{ id, title, level, difficulty, frequency, task, bounty, hidden, auto, campaignID, classification, overrides, calling, disabled, complete, failed, ready, completion, objectives = { { text, type, finished, numFulfilled, numRequired } }, percent, sequenced, money, time = { total, elapsed }, timer, tag = { tagName, tagID, isElite }, elite, item = { link, texture, charges, showWhenComplete, cooldown = { start, duration, enable }, range }, inArea, distance = { sq, onContinent }, waypoint, pushable }`.
  - `stub.money` and `stub.real_zone_text`.
  - `C_QuestLog`: `GetNumQuestWatches`, `GetQuestIDForQuestWatchIndex`, `GetLogIndexForQuestID`, `GetInfo` (the `QuestInfo` fields), `GetHeaderIndexForQuest`, `GetQuestObjectives`, `IsComplete`, `IsFailed`, `ReadyForTurnIn`, `GetRequiredMoney`, `GetTimeAllowed` (MayReturnNothing), `GetQuestTagInfo`, `IsQuestDisabledForSession`, `IsQuestCalling`, `GetDistanceSqToQuest` (MayReturnNothing), `GetNextWaypointText`, `GetNumQuestLogEntries` (numShownEntries, numQuests), `GetMaxNumQuestsCanAccept`, `GetTitleForQuestID`, `IsPushableQuest`, `AddQuestWatch` and `RemoveQuestWatch` (which change `watched`), `GetNumWorldQuestWatches`, `IsWorldQuest`, `IsEliteQuest`, `GetQuestTimers`.
  - The old globals: `GetQuestLogSpecialItemInfo`, `GetQuestLogSpecialItemCooldown`, `IsQuestLogSpecialItemInRange`, `GetQuestLogCompletionText`, `GetQuestProgressBarPercent`, `IsQuestSequenced`, `GetNumAutoQuestPopUps`, `GetAutoQuestPopUp`, `GetQuestLink`, `GetMoney`, `GetMoneyString`, `GetDifficultyColor`, `GetRealZoneText`.
  - Also: `C_PlayerInfo.GetContentDifficultyQuestForPlayer`, `C_SuperTrack.GetSuperTrackedQuestID` and `SetSuperTrackedQuestID`, `C_Minimap.IsInsideQuestBlob`, `QuestUtil.GetQuestIconActiveForQuestID` and `QuestShowsItemByIndex`, `Constants.QuestWatchConsts.MAX_QUEST_WATCHES = 25`, `Enum.QuestClassification` (Important 0 … WorldQuest 10), `Enum.QuestFrequency` (0 to 3), `Enum.UIMapType` where missing, and the strings `DAILY`, `WEEKLY`, `QUEST_WATCH_QUEST_READY`, `QUEST_WATCH_QUEST_COMPLETE` and `QUEST_WATCH_CLICK_TO_COMPLETE`.
  - Every argument is checked as in game. Any value a test puts in may be an `S.secret`.
- Produces (`model.lua`, pure over the API):
  - `TR.Model.ZoneNames() -> { name, ... }`: the zone map's name (`C_Map.GetBestMapForUnit('player')` climbed to `Enum.UIMapType.Zone`, stopping at an Orphan map), then `GetRealZoneText()`, then `GetZoneText()`. Plain strings only, with no repeats.
  - `TR.Model.Shown(info) -> boolean`: not a task, not a bounty (Ruling 10), not disabled for the session, not hidden.
  - `TR.Model.Compare(a, b)`: callings first, then `overridesSortOrder`, then `watchIndex`.
  - `TR.Model.Read(show) -> model`. The model is `{ quests, popups, counts = { inLog, max, watched, watchMax }, zoneNames, focused, arena }`.
    - Each quest is `{ id, logIndex, watchIndex | nil, tracked, title, headerTitle, campaign, level, elite, tags, difficultyColor, complete, failed, ready, auto, completionText, objectives, sequenced, money = { have, need } | nil, timeLeft | nil, item | nil, inArea, distanceSq, onContinent, calling, overrides, waypoint }`.
    - In an arena, `quests` and `popups` are empty. Popups are left out while `SplashFrame` is shown. A quest with no title is skipped.
  - `TR.TitleText(quest, settings) -> text`: `"[12] "` or `"[12+] "` with Level on, and the tags with Tags on (Ruling 13).
  - `TR.QuestLines(quest, settings, now) -> { { kind, text, state, value } ... }`. Kinds: `objective`, `bar`, `failed`, `completion`, `complete`, `click`, `money`, `timer`, `waypoint`, in Ruling 11's order. A sequenced quest stops at its first unfinished objective. `hide_finished` and `finished_objectives` apply.
  - `TR.TimeText(seconds) -> text`.
- Produces (`groups.lua`):
  - `TR.OTHER_KEY = '*other'`.
  - `TR.Groups.IsCurrent(title, zoneNames) -> boolean`.
  - `TR.Groups.Sort(quests, order, finishedFirst)`: `'game'` (Compare, then untracked in log order), `'log'`, or `'level'` (low first, then game order; a missing level last). Finished quests first keeps the order otherwise.
  - `TR.Groups.Build(quests, settings, zoneNames, collapsed) -> { { key, title, current, campaign, collapsed, count, quests } ... }`. Groups come in this order:
    - current first (with `current_first`);
    - then campaign;
    - then log header order;
    - Other last.

    Repeated titles merge in the first one's place. With zones off there is one group, `{ key = '*all' }`.

- [ ] **Step 1: Write the failing tests.** In `model_test.lua`, each on `T.client('forever')` and `'retail'`:

```lua
test('the watch list in the game\'s order with callings first and overridesSortOrder next', ...)
test('the display rule: tasks, bounties, hidden and disabled quests left out; campaign quests kept', ...)
test('level and elite: "[12+] " through IsEliteQuest on Forever, the tag\'s isElite on retail', ...)
test('tags and frequency: "(Elite) (Daily)"; a secret title shown as it is, with no prefix or tags', ...)
test('objectives: a sequenced quest cut after its first unfinished one; Hide finished objectives; Objectives of finished quests', ...)
test('complete, failed, auto-complete: the completion text, else QUEST_WATCH_QUEST_READY; "Failed"; complete then click', ...)
test('money only while more is needed; the timer from GetQuestTimers on Forever, GetTimeAllowed on retail; TimeText 4:32 and 1:04:32', ...)
test('the item and show-when-complete; area, distance (none when the API returns nothing), the focused quest\'s waypoint', ...)
test('popups, none while SplashFrame shows; no quests in an arena; the counts', ...)
test('the current zone\'s quests with Show set to Tracked and the current zone\'s: untracked ones read, tracked = false', ...)
test('a missing function makes its part absent; a secret value (level, numbers, distance) counts as missing', ...)
test("quests the log can't place: no header, a header with no info, a secret header title, no title yet", function()
	-- Review Focus 3: the first three get headerTitle nil (Other); the untitled quest isn't in model.quests; #take_errors() == 0
end)
```

In `groups_test.lua`:

```lua
test('a group per header; the current zone first by the map name, GetRealZoneText or GetZoneText', ...)
test('then campaign groups, then the log\'s header order; Other last, keyed *other', ...)
test('the three orders and Finished quests first, keeping the order otherwise; untracked zone quests after the tracked', ...)
test('collapsed groups from the character\'s table keep their header and count', ...)
test('Group by zone off: one list in the chosen order; two headers with one title merge in the first one\'s place', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/model_test.lua tests/tracker/groups_test.lua tests/lib/harness_self_test.lua`. Expected: FAIL, `TR.Model` is nil.
- [ ] **Step 3: Implement** the stubs, then the two files.
- [ ] **Step 4: Run** the same, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add tests/wow/quests.lua tests/wow/game.lua tests/lib/harness_self_test.lua SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/model.lua SaftUI-Tracker/groups.lua tests/tracker/model_test.lua tests/tracker/groups_test.lua AGENTS.md .agents/testing.md .agents/clients.md
git commit -m "tracker: read the quest log into a model and group it by zone"
```

**In-game checks:** none (stub tests). P4's third line is the check on headers and zone names.

---

### Task 4: The window: holder, mover, header, size, scroll

**Files:**
- Create: `SaftUI-Tracker/layout.lua` and `window.lua` (TOC).
- Modify:
  - `init.lua`: `Build` runs `BuildWindow`; `UpdateConfig` runs `ApplyHolder` and `DrawWindow`.
  - `options.lua`: General's rows.
  - `SaftUI-Core/api.lua`: `st:DefaultTrackerPosition`.
  - `Blizzard_ObjectiveTrackerPosition.lua`: `DefaultPosition` returns `st:DefaultTrackerPosition()`.
- Test:
  - Create `tests/tracker/window_test.lua` and `tests/tracker/layout_test.lua` (the window-level part).
  - `tracker_world.lua` gains `TW.scroll_frame(parent)` (Ruling 24).
  - In `tests/core/editmode_movers_test.lua`, `MODULES` gains `['Tracker'] = true`.
- Docs:
  - `.agents/edit-mode.md`: the `tracker` mover; its first position; the module list's eighth name.
  - `.agents/architecture.md`: the api helper.
  - `.agents/testing.md`: the stand-in.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Task 3's model counts (header).
- Produces:

```lua
TR.LAYOUT = {
	PAD = 8, HEADER = 24, HEADER_GAP = 6, COUNT_GAP = 6, CHEVRON = 16, LINE_ALPHA = 0.5,
	ZONE = 20, ZONE_ABOVE = 10, ZONE_BELOW = 4, ZONE_TITLE_GAP = 2, ICON = 14, ICON_GAP = 4,
	INDENT = 12, LINE_GAP = 2, BAR = 12, BAR_GAP = 3, POPUP = 22, POPUP_BAR = 2,
	FOCUS_BAR = 2, FOCUS_GAP = 4, HOVER_PAD = 2, WHEEL = 40, BAR_LINGER = 0.3,
	ITEM_GAP = 4, COLUMN_GAP = 4, COLUMN_STACK = 2, BESIDE_GAP = 12, BLIZZARD_OFF = 100,
}
```

  - Pure layout functions:
    - `TR.Layout.WindowHeight(content, opts) -> height`. `opts` is `{ header, collapsed, max }`: PAD, then HEADER + HEADER_GAP while the header shows, then the content, then PAD, at most `max`. Collapsed it is 40 (Ruling 15).
    - `TR.Layout.ViewHeight(windowHeight, header)`.
    - `TR.Layout.ChildWidth(width, barRoom)`: `width - 2 * PAD - barRoom`.
    - `TR.Layout.ScrollRange(content, view)`.
    - `TR.Layout.Wheel(offset, delta, range)`: 40 a notch, clamped.
  - `st:DefaultTrackerPosition() -> { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -st.CLAMP_INSET, y_off = st.forever and -275 or -260 }`, a fresh table each call.
  - `TR.NewScrollFrame = function(parent) return st:CreateScrollFrame(parent) end`.
  - `TR:BuildWindow()`:
    - `TR.holder` (`SaftUITrackerHolder`, `st:CreateFrame` on UIParent);
    - `TR.window` (`SaftUITracker`, on UIParent, `LOW`, level 10);
    - `TR.header` (title "Objectives" in the Header font; `count`; `collapse`, `TR:NewChevron`; a 1px line at the drawn theme's border color and `LINE_ALPHA`, the skin's `LineColor` rule);
    - `TR.scroll` with child `TR.content`, and its `OnMouseWheel`;
    - `TR.watcher`, one `OnUpdate` running only while a hover rule needs it.
  - `TR:GetPosition() -> position` (Ruling 7) and `TR:ApplyHolder()`: `st:PlaceHolder(TR.holder, 'tracker_holder', width by height, GetPosition)`, then the window again. The window is anchored `TOPRIGHT` to the holder's `TOPRIGHT` (Grow down) or `BOTTOMRIGHT` to its `BOTTOMRIGHT` (Grow up). `st:KeepInScreenMargin(TR.holder)`.
  - The mover is `st:RegisterMover('tracker', ...)`:
    - frame the holder, label `'Tracker'`, `module = 'Tracker'`, `configPath = { 'Tracker', 'general' }`;
    - `isHidden = function() return not TR.window:IsShown() end`;
    - `getDefaultPosition = st.DefaultTrackerPosition`, wrapped;
    - `getSavedPosition` returns `config.position`;
    - `apply` is `TR:ApplyHolder()`.
  - `TR:SetContentHeight(h)`: window, scroll frame and child sizes. The bar's room is `st:ScrollBarRoom(TR.scroll)` while the list scrolls, else 0. The offset is kept, clamped.
  - `TR:ScrollTo(offset)` and `TR:GetScroll()`. `TR:IsScrollLocked()` returns false until Task 8. `TR:IsHovered()`: the window, or the item column from Task 9, `IsMouseOver`.
  - The bar rule: shown while `visibility.scrollbar_hover` is off, or `TR:IsHovered()`, or within `BAR_LINGER` after the mouse leaves.
  - `TR:UpdateHeader(model)`: "12/35" in Text > Grey, right-aligned `COUNT_GAP` left of the chevron. Its tooltip is "Objectives" in white, then "12 of 35 quests in your quest log, 8 tracked (up to 25)." (Ruling 14 at the limit). The chevron's tooltip is "Collapse" or "Expand".
  - `TR:SetCollapsed(collapsed)` (into `CharData().collapsed`) and `TR:IsCollapsed()`.
  - `TR:NewChevron(parent, getTip) -> button`: 16 square, `chevronUp` or `chevronDown` at 16, Text > Grey at rest and white under the mouse.
  - `TR:DrawWindow()`: `st:SetBackdrop(TR.window, config.theme, config.background, 'panel')`. A theme change redraws it.
  - General rows:
    - `theme` and `background` (`generators.theme(2, "The tracker's panel and its item buttons.")`);
    - `width` (range 180 to 600, step 1) and `height` (120 to 1600);
    - `grow` (select Down, Up);
    - `header`, `count`, `hide_empty`;
    - a Text section with `font` and `header_font` (`generators.font`);
    - `position` (`generators.position(1000, true, ...)`), whose validate refuses `SaftUITracker` and `SaftUITrackerHolder`.

    Each row has the spec's desc gist and `TR.SettingDefault`.

- [ ] **Step 1: Write the failing tests**

```lua
-- layout_test.lua
eq(TR.Layout.WindowHeight(100, { header = true, max = 560 }), 146)
eq(TR.Layout.WindowHeight(2000, { header = true, max = 560 }), 560)
eq(TR.Layout.WindowHeight(100, { header = false, max = 560 }), 116)
eq(TR.Layout.WindowHeight(100, { header = true, collapsed = true, max = 560 }), 40)
eq(TR.Layout.ChildWidth(260, 14), 230); eq(TR.Layout.Wheel(0, -1, 300), 40); eq(TR.Layout.Wheel(290, -1, 300), 300)
-- window_test.lua (TW.world({ on = true }), both clients)
test('the holder is Width by Max height at the saved spot; the mover is the holder, so the outline covers it', ...)
test("first position: the skin's saved one when Misc has one, else Blizzard's default spot (-275 Forever, -260 retail), saved once", ...)
test('the window hangs by its top right (Grow down) or bottom right (Grow up), as tall as its contents up to Max height', ...)
test('the header: Objectives, the count 6 left of the chevron in Text > Grey, a line at 50%; Header off and Count off', ...)
test('past Max height the list scrolls, with the bar\'s room kept; the wheel 40 a notch, clamped; the offset kept on resize', ...)
test('Scroll bar under the mouse only: shown while hovered and 0.3 s after; always with it off', ...)
test('collapsed is the header only, per character, kept in a new world with the same st.config.char', ...)
test('Theme and Background: a panel in the pair; None draws none; a round trip through Blizzard redraws it', ...)
test('whole pixels under Thick, Thin and Blizzard, size noise up, down and off, at Width 261 and Max height 333', ...)
test('UpdateConfig and a theme change make no new frame; off, none of this exists', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/window_test.lua tests/tracker/layout_test.lua`. Expected: FAIL, `TR.Layout` is nil.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker tests/misc/objective_tracker_position_test.lua tests/core/editmode_movers_test.lua`, then `tests/run -j2`. Expected: PASS, with the OTP tests unchanged.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/layout.lua SaftUI-Tracker/window.lua SaftUI-Tracker/init.lua SaftUI-Tracker/options.lua SaftUI-Core/api.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua tests/tracker/window_test.lua tests/tracker/layout_test.lua tests/tracker/tracker_world.lua tests/core/editmode_movers_test.lua AGENTS.md .agents/edit-mode.md .agents/architecture.md .agents/testing.md
git commit -m "tracker: add the window, its header, size, scroll and mover"
```

**In-game checks:** with the switch on and a reload, an empty window shows at Blizzard's tracker's spot, with Blizzard's still showing. In edit mode, the outline is Width by Max height; drag it and reload, and it stays. Width, Max height and Grow change it at once. Collapse survives a reload. Check Thick, Thin and Blizzard.

---

### Task 5: Rows and the refresh

**Files:**
- Create: `SaftUI-Tracker/rows.lua` (TOC).
- Modify:
  - `layout.lua`: the rows.
  - `init.lua`: events, the throttle, `TR:Refresh` and `OnColorsChanged`.
  - `window.lua`: hide when empty, the empty line, popups expanding the window.
  - `options.lua`: the Quests tab, every row but `left_click` and `tooltips` (Task 7), then the description row.
- Test: create `tests/tracker/rows_test.lua` and `tests/tracker/refresh_test.lua`; extend `layout_test.lua`.
- Docs:
  - `.agents/architecture.md`: the refresh and its stages; `st.config.char.tracker.zones`.
  - `.agents/testing.md`.
  - `docs/design-system/components/Icons/README.md`: map-pin and the chevrons in the tracker.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Tasks 3 and 4.
- Produces:
  - `TR.Layout.Rows(entries, metrics, measure) -> placed, height` (pure).
    - Entries are `{ kind = 'popup' | 'zone' | 'quest' | 'empty', first, lines, item = 'row' | nil }`.
    - `metrics = { width, spacing, icons, itemSize }`.
    - `measure(text, width, font) -> height`.
    - Each placed entry is `{ y, height, titleWidth, lineWidth, lines = { { y, height } } }`.
    - Title width is the child width, less 18 with icons, less `itemSize + 4` when the button is in the row. Line width is the title width less `INDENT`. Ruling 11 and Ruling 18 apply.
  - `TR.Layout.IntoView(offset, top, height, view, range) -> offset`.
  - `TR.EVENTS`: the spec's list. `UNIT_QUEST_LOG_CHANGED` is registered for the player only. `PLAYER_MONEY` is registered only while a quest needs money.
  - `TR:MarkDirty(event)`: one `C_Timer.After(0)` refresh. `QUEST_LOG_UPDATE` waits out `TR.REFRESH_GAP = 0.1` since the last refresh.
  - `TR:Refresh()`: model, groups, entries, layout, `TR:DrawRows`, then `RefreshItems`, `RunProbes`, `UpdateHandover` and `ApplyVisibility`, each only once its file defines it.
  - `TR:DrawRows(entries, placed)`. Rows, lines and bars are pooled (`TR:AcquireRow(kind)` / `TR:ReleaseRows()`).
  - `TR.SetText(fs, text) -> changed`: sets the text only when it differs, a secret always.
  - `TR:Measure(row, fs, text, width) -> height`: `floor(GetStringHeight() + 0.5)`, kept per (text, width).
  - Drawing:
    - Zone headers: a chevron (zone collapse into `CharData().zones[key]`); the title in the Header font, 2 after the chevron, Text > Normal for the current zone and Text > Grey for the rest; `st.icons.mapPin` at 16 in the accent after the current zone's name; the count right-aligned in Text > Grey.
    - Quest rows: the icon (`QuestUtil.GetQuestIconActiveForQuestID`, 14); the title in the difficulty color, Text > Normal, Completed or Failed; the lines (bars as kind `bar` in (0.26, 0.42, 1), the percent centred in the Pixel font; the timer in Failed under a minute).
    - The focused quest's 2px accent bar, 4 left of the row.
    - Hover fills the row with the accent at `st.TINT_ROW`, `HOVER_PAD` beyond its text.
    - Popup rows: 22 tall, a 2px accent bar, "Quest discovered" or "Quest complete" in the Header font and the accent over the title. A click runs `ShowQuestOffer` or `ShowQuestComplete`, then `RemoveAutoQuestPopUp`.
    - Empty: "No tracked quests." in Text > Grey, or hidden with Hide when empty.
  - `TR.timerTicker` ticks every 1 s while a timed quest shows. A refresh keeps the scroll offset, and scrolls the focused quest or a newly tracked one into view.
  - `TR:OnColorsChanged(group)` recolors the header line, chevrons, focus bar, hover, zone counts and status colors (`objectives`, `text`, `button`, `theme`).

- [ ] **Step 1: Write the failing tests**

```lua
-- layout_test.lua: zone A, a1 (title 12, two objectives of 12), zone B, b1 (title 12), spacing 8, measure = 12
-- placed y and height: '0 20, 24 40, 74 20, 98 12', height 110; two quests in A: the second at 72
-- a bar after a title: 12 + 3 + 12 + 3 = 30; a row button: the row at least 24, title width 244 - 18 - 28 = 198
-- a popup, then a zone: the zone at 22 + 10; IntoView of a row below the view scrolls to show it whole
-- refresh_test.lua
test('twenty QUEST_LOG_UPDATEs in one frame make one refresh', ...)
test('a burst refreshes at most every 0.1 seconds (stub.time)', ...)
test('a second refresh makes no frame; a refresh with nothing changed sets no text', ...)
test('a burst on a full log', function()
	-- Review Focus 4: 25 watched + 10 untracked zone quests, 6 objectives each, Show 'zone';
	-- 200 events over 2 s: refreshes <= 21; TW.counts.frames unchanged after the first; SetText count 0 on the last
end)
test('off: no event is registered and nothing refreshes', ...)
-- rows_test.lua (both clients)
test('zone headers: the current one first in Text > Normal with the map pin in the accent; the count; collapse per character', ...)
test('titles: level and tags; difficulty color, or Text > Normal; Completed when ready, Failed when failed', ...)
test('lines: objectives, a finished one in Completed, a failed quest\'s "Failed", the completion lines, money, the timer in Failed under a minute', ...)
test('progress bars in Blizzard\'s blue with the percent centred in the Pixel font; off, the objective\'s text', ...)
test('the focused quest\'s accent bar and waypoint; scrolled into view; hover at TINT_ROW', ...)
test('popups above the zones, the window expanded while they show, a click shows the quest and removes the popup', ...)
test('empty: hidden with Hide when empty, else the header and "No tracked quests."', ...)
test('a Colors tab change recolors the status lines (objectives) and the accent pieces (button)', ...)
test('whole pixels under the three looks with size noise up, down and off, scrolled and not', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/rows_test.lua tests/tracker/refresh_test.lua tests/tracker/layout_test.lua`. Expected: FAIL, `TR.Layout.Rows` is nil.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/rows.lua SaftUI-Tracker/layout.lua SaftUI-Tracker/init.lua SaftUI-Tracker/window.lua SaftUI-Tracker/options.lua tests/tracker/rows_test.lua tests/tracker/refresh_test.lua tests/tracker/layout_test.lua AGENTS.md .agents/architecture.md .agents/testing.md docs/design-system/components/Icons/README.md
git commit -m "tracker: draw quests by zone and refresh them on the quest log's events"
```

**In-game checks:** with the switch on, every tracked quest shows under its zone, with the current zone first and its pin. Collapse a zone and reload: it stays. Kill quest mobs quickly: no stutter. Timers, bars, money, the waypoint and popups show where you have them.

---

### Task 6: Blizzard's tracker concealed; the mover stands down; the renames

**Files:**
- Create: `SaftUI-Tracker/blizzard.lua` (TOC).
- Modify:
  - `init.lua`: `Build` runs `SetupBlizzard`; `UpdateConfig` runs `PlaceBlizzard`.
  - `SaftUI-Core/api.lua`: `st:CornerOffset`.
  - `Blizzard_ObjectiveTrackerPosition.lua`: `PlaceTracker` through `st:CornerOffset`, the stand-down, the renames.
- Test:
  - Create `tests/tracker/conceal_test.lua` and `tests/tracker/source_scan_test.lua`.
  - Modify `tests/misc/fixtures/objective_tracker.lua`: Edit Mode's `Show`, `Hide`, `SetShown` and `SetScale` overrides counted in `OT.calls`; `SetSize`, `SetWidth`, `SetHeight`, `SetParent`, `UnregisterEvent` and `UnregisterAllEvents` from SaftUI recorded in `OT.stray`.
  - Modify `tests/misc/objective_tracker_position_test.lua`: the page's name and label assertions at lines 470 and 537 change to the new names, and stand-down cases are added.
- Docs:
  - `.agents/taint.md` rule 5: SaftUI's concealment, the never list and the allowed list; covers gains `'SaftUI-Tracker/blizzard.lua'`.
  - `.agents/edit-mode.md`: OTP standing down; the renames.
  - `AGENTS.md`: the Misc row's "objective tracker" wording and the Tracker row.

**Interfaces:**
- Consumes: Tasks 4 and 5 (the in-place spot: the window's top right).
- Produces:
  - `st:CornerOffset(frame, parent, point, screenX, screenY) -> x, y | nil`: the offsets that put `frame`'s `point` at (screenX, screenY) in screen pixels, anchored by `point` to `parent`'s `point`. The screen point less the parent's, over the frame's effective scale, through `st:RoundToPixel`. Nil for a secret or zero value. OTP's `PlaceTracker` uses it, unchanged in effect.
  - `TR:OwnsBlizzard() -> boolean` (Ruling 5).
  - `TR:SetupBlizzard()`:
    - post-hooks on the tracker's `SetPoint`, `ClearAllPoints` and `UpdateHeight` (each in `xpcall`, only where `type == 'function'`), which re-run `TR:PlaceBlizzard(TR.blizzardWhere)`;
    - `st:HideEditModeSelection(tracker)` and `tracker.Selection:Hide()`;
    - `TR:PlaceBlizzard('concealed')`.

    Through `st:OnBlizzardAddon('Blizzard_ObjectiveTracker', ...)` if it isn't loaded yet.
  - `TR:BlizzardTarget(where) -> parent, point, x, y`. `'place'` is the window's top right (the holder's top for Grow down, the window's top for Grow up). `'concealed'` is Ruling 29's y with an x of `BLIZZARD_OFF` past UIParent's left.
  - `TR:PlaceBlizzard(where)`, the P2 seam (Experiment seams). `TR.blizzardWhere` holds the last `where`.
  - OTP: a local `Owned()` reads `st:GetModule('Tracker', true)` and calls `:OwnsBlizzard()` at call time.
    - `PlaceTracker`, `KeepInMargin`, `UpdateFootprint` and `CapturePosition` return at once while owned.
    - The mover's `isDisabled = Owned`.
    - Position's `disabled = Owned`, with `disabledDesc` "SaftUI's tracker is on (Tracker page): Blizzard's tracker shows in its place when it's needed."
  - Renames:
    - the page name "Blizzard's tracker";
    - its desc "Blizzard's objective tracker: its fonts, and its place while SaftUI's tracker is off. Its fonts also style it while it fills in for SaftUI's (Tracker page).";
    - the mover label "Blizzard's tracker".

    Skinning's toggle keeps its name.

- [ ] **Step 1: Write the failing tests.** In `conceal_test.lua`, on the fixture, both clients, with and without `opts.misc`:

```lua
test('concealed: its right edge 100 left of the screen, y the spot\'s, anchored TOPRIGHT to its own parent; clamp off', ...)
test('in place: its top right on the window\'s, for Grow down and up, both screen halves; clamp on', ...)
test("Blizzard's re-places (its SetPoint, ClearAllPoints, UpdateHeight through the fixture) put it back", ...)
test('no call when its one point is already that; only the C methods; OT.calls and OT.stray empty', ...)
test('the skin\'s mover stands down while owned: no SetPointDirect of its own, its mover disabled, Position disabled with its reason', ...)
test('without SaftUI-Misc its own hooks keep it concealed', ...)
test('concealed at once after a /reload in combat, stub.blocked empty', ...)
test('a profile switch while concealed', function()
	-- Review Focus 5: OTP:UpdateConfig() then TR:UpdateConfig(): the same one point, no OTP move,
	-- a profile with no tracker.position gets its first position, collapsed groups kept
end)
test('switch off: the skin\'s mover places Blizzard\'s tracker exactly as before, the Tracker module loaded', ...)
-- source_scan_test.lua
test("SaftUI-Tracker calls nothing on Blizzard's tracker, its modules or ObjectiveTrackerManager outside the allowed list", function()
	-- every file TW.toc_files() lists, comments and strings stripped (theme_kinds_test.lua's scanner):
	-- no ShouldShowMawBuffs, UseQuestLogSpecialItem, RemoveModule, MarkDirty, UnregisterAllEvents, SetRolesets,
	-- SetParent( on a name bound to ObjectiveTrackerFrame; method calls on it only via getmetatable(...).__index or
	-- hooksecurefunc(tracker, 'SetPoint' | 'ClearAllPoints' | 'UpdateHeight' | 'SetAlpha' | module 'Update'); a scan that finds
	-- no ObjectiveTrackerFrame reference at all fails
end)
```

`objective_tracker_position_test.lua`: the name `"Blizzard's tracker"`; Reset's reason now reads `"Blizzard's tracker is already in its default place."`.

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/conceal_test.lua tests/tracker/source_scan_test.lua`. Expected: FAIL, `TR.PlaceBlizzard` is nil.
- [ ] **Step 3: Implement** as the Interfaces say, Core helper first.
- [ ] **Step 4: Run** `tests/run tests/tracker tests/misc`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/blizzard.lua SaftUI-Tracker/init.lua SaftUI-Core/api.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua tests/tracker/conceal_test.lua tests/tracker/source_scan_test.lua tests/misc/fixtures/objective_tracker.lua tests/misc/objective_tracker_position_test.lua AGENTS.md .agents/taint.md .agents/edit-mode.md
git commit -m "tracker: conceal Blizzard's tracker off screen while SaftUI's is on, and stand its mover down"
```

**In-game checks:** run P1 and P2 first, with this build and the switch off. Then switch on and reload: only SaftUI's tracker shows, and Blizzard's Edit Mode can't select its tracker. Run G2 after questing. The pages read "Blizzard's tracker".

---

### Task 7: Clicks, the menu, tooltips

**Files:**
- Create: `SaftUI-Tracker/clicks.lua` (TOC).
- Modify:
  - `rows.lua`: row and icon scripts, wrapped for `motion`.
  - `options.lua`: Quests gains `tooltips` and `left_click`.
- Stubs:
  - `tests/wow/quests.lua` records each call in `stub.quest_calls`: `ChatFrameUtil.TryInsertQuestLinkForQuestID`, `IsModifiedClick`, `QuestUtil.CanRemoveQuestWatch`, `QuestUtil.IsShowingQuestDetails`, `QuestUtil.OpenQuestDetails`, `QuestUtil.ShareQuest`, `QuestMapFrame_OpenToQuestDetails`, `QuestMapQuestOptions_AbandonQuest`, `ShowQuestOffer`, `ShowQuestComplete` and `RemoveAutoQuestPopUp`.
  - The strings `SUPER_TRACK_QUEST`, `STOP_SUPER_TRACK_QUEST`, `OBJECTIVES_VIEW_IN_QUESTLOG`, `OBJECTIVES_HIDE_VIEW_IN_QUESTLOG`, `OBJECTIVES_SHOW_QUEST_MAP`, `OBJECTIVES_STOP_TRACKING`, `SHARE_QUEST`, `ABANDON_QUEST_ABBREV` and `TRACK_QUEST`.
  - `tests/wow/widgets.lua`: `GameTooltip.SetQuestPartyProgress` and `SetQuestLogSpecialItem`.
- Test: create `tests/tracker/clicks_test.lua`, with a recording `MenuUtil` set there, as `tests/bags/category_tooltip_menu_test.lua` does.
- Docs: `.agents/taint.md` (opening the map, out of combat only, P5 open; covers gains `clicks.lua`) and `AGENTS.md` row.

**Interfaces:**
- Consumes: Task 5's rows; `TR:ToggleFocus` is used by the icon.
- Produces:
  - `TR.SHOW_ON_MAP = true` and `TR.ShowOnMapAllowed()`, the P5 seam.
  - `TR.ClickAction(quest, button, state) -> 'link' | 'untrack' | 'track' | 'complete' | 'map' | 'focus' | 'menu'`. `state = { chat, modified, combat, leftClick }`.
  - `TR:OnQuestClick(row, button)` and `TR:ToggleFocus(questID)`, which calls `C_SuperTrack.SetSuperTrackedQuestID` with the quest or 0.
  - `TR.MenuEntries(quest, state) -> { { kind = 'title' | 'button', text, enabled, tip, onClick } }`, in Blizzard's order: the title, Focus or Stop focusing, details, Show on map (while allowed), Stop tracking or Track (Ruling 9), Share (`IsPushableQuest` and `IsInGroup`), Abandon. Details, the map and Abandon are disabled in combat with "Out of combat only" (Ruling 19).
  - `TR:OpenMenu(row)` through `MenuUtil.CreateContextMenu`. Nothing opens without it.
  - `TR:ShowRowTooltip(row)`: `GameTooltip` at `ANCHOR_NONE`, placed per Ruling 30. It shows `SetHyperlink(GetQuestLink(id))`, then `SetQuestPartyProgress` when grouped where it exists, then `TR.ClickHint(leftClick, allowed)` in Text > Grey: "Click: show on map (focus in combat). Shift-click: stop tracking. Right-click: more." or "Click: focus.".
  - `TR.LeftClickValues() -> { map = 'Show on map', focus = 'Focus' }`, without `map` when not allowed.

- [ ] **Step 1: Write the failing tests**

```lua
test('a chat box open: any click puts the link in it and does nothing else', ...)
test('shift-click stops tracking when QuestUtil.CanRemoveQuestWatch allows it; an untracked zone quest is tracked', ...)
test('left on a complete auto-complete quest: ShowQuestComplete and its popup removed', ...)
test('left: Show on map out of combat, focus in combat; Left click Focus: focus always; the icon toggles focus', ...)
test('the menu: Blizzard\'s entries and strings in order; Share only shareable in a group; no Share in chat', ...)
test('in combat details, Show on map and Abandon are disabled with "Out of combat only"; Focus and Stop tracking work', ...)
test('P5 failed (TR.SHOW_ON_MAP = false): Left click offers Focus only, a saved map reads as focus, the menu drops it, the hint says "Click: focus."', ...)
test('the tooltip: the quest link, party progress when grouped, the click hint; Tooltips off shows none; OnEnter fired with true', ...)
test('a zone header\'s right click does nothing; without MenuUtil nothing opens and nothing errors', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/clicks_test.lua`. Expected: FAIL, `TR.ClickAction` is nil.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/clicks.lua SaftUI-Tracker/rows.lua SaftUI-Tracker/options.lua tests/wow/quests.lua tests/wow/widgets.lua tests/tracker/clicks_test.lua AGENTS.md .agents/taint.md
git commit -m "tracker: add the quest clicks, Blizzard's menu and the quest tooltips"
```

**In-game checks:** P5 first. Then G9: every menu entry; Abandon's confirm; Share in a group. Shift-click, chat-link and focus from the icon.

---

### Task 8: The item layer and row buttons

**Files:**
- Create: `SaftUI-Tracker/items.lua` (TOC).
- Modify:
  - `window.lua`: `TR:IsScrollLocked()` and `window.barLock` (Ruling 17).
  - `rows.lua`: the item slot as a button, a plain icon or a greyed icon.
  - `init.lua`: `Build` and `UpdateConfig` run the items.
  - `options.lua`: the Items tab: `placement`, `size`, `cooldown`, `count`, `range`, then the description row.
- Stubs: `tests/wow/widgets.lua` gains `SecureActionButtonTemplate` and `SecureHandlerStateTemplate` (state `protected = true`, read by `ScriptRegion.IsProtected`) and `CooldownFrameTemplate` (no setup).
- Test: create `tests/tracker/items_test.lua`, and add a case to `harness_self_test.lua`: a secure template frame refuses moves, shows and attributes in combat into `stub.blocked`.
- Docs:
  - `.agents/taint.md`: SaftUI's secure quest item buttons (rules kept, the layer and driver, the 25% floor); covers gains `items.lua`.
  - `.agents/testing.md`: the templates.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Task 5's placed rows (rects read from SaftUI's own row frames).
- Produces:
  - `TR.BUTTON_MIN_ALPHA = 0.25`, `TR.DIM_ALPHA = 0.4`, `TR.MOVE_TOLERANCE = 2`, `TR.ITEM_POOL_MAX = 35` (Ruling 9) and `TR.RANGE_INTERVAL = 0.2`.
  - `TR.ItemAttributes(item)`, the P3 seam, and `TR:SetButtonItem(button, item) -> boolean`, which refuses in combat.
  - `TR:BuildItemLayer()`: `SaftUITrackerItems` (`SecureHandlerStateTemplate`, UIParent, `LOW`, level 30, Ruling 20). Out of combat only; else queued as `'tracker_items'`. The driver comes later (Task 12: `'[petbattle] hide; show'` until then).
  - `TR.Items.RowPlace(rowTop, rowRight, viewTop, viewBottom, size) -> left, top | nil` (pure, whole). Nil while the button's centre is outside the view, or the row is collapsed or gone.
  - `TR.Items.CombatAlpha(placedTop, rowTop) -> 1 | TR.DIM_ALPHA`: dims when the row is gone or has moved more than `MOVE_TOLERANCE`.
  - `TR:RefreshItems()`. Out of combat it assigns pooled buttons (made on need, at most `ITEM_POOL_MAX`, never freed), sets items through `SetButtonItem`, and places, shows or hides them. In combat it only sets alpha and draws, and queues `'tracker_items'`. A quest whose item has no button shows a greyed icon in its row (desaturated, alpha 0.4) with the tooltip "Its button comes when combat ends.".
  - `TR:ItemsToShow() -> boolean`, for the handover: placement row or beside, and a quest with an item.
  - The look:
    - `st:IconTexCoords`;
    - `st:SetBackdrop(button, config.theme, config.background, 'action')`;
    - a HIGHLIGHT hover in the accent;
    - `CooldownFrameTemplate` from `GetQuestLogSpecialItemCooldown`;
    - the count in the Pixel font at the bottom right;
    - Text > Red while `IsQuestLogSpecialItemInRange == 0`, read every 0.2 s while a button shows;
    - the accent border while `C_Minimap.IsInsideQuestBlob`, on `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED`;
    - `RegisterForClicks('AnyUp', 'AnyDown')`;
    - its tooltip `GameTooltip:SetQuestLogSpecialItem(logIndex)`, plus the quest's title while dimmed.
  - `TR:IsScrollLocked()`: in combat with placement row and a row button shown. The wheel and bar hold, and the bar shows at 40% with `barLock`'s tooltip "Scrolling waits for the end of combat while quest item buttons sit in the rows.".

- [ ] **Step 1: Write the failing tests**

```lua
test('no secure button is made, placed, shown, hidden or given an attribute in combat: TW.counts.secure 0, stub.blocked empty', ...)
test('buttons sit at their row\'s top right on whole pixels, the title narrowed, hidden out of view, collapsed or gone', ...)
test('in combat a button whose row moved more than 2 or went dims to 40% and still uses its quest\'s item; at combat end all go back', ...)
test('combat starting before a queued refresh', function()
	-- Review Focus 1: QUEST_LOG_UPDATE, then TW.combat(true), the quest above completes, stub.run_timers():
	-- rows redrawn, the lower button at its old place at 0.4, no secure call, stub.blocked empty; TW.combat(false): one pass, back at 1
end)
test('a /reload in combat', function()
	-- Review Focus 2: TW.world({ on = true, combat = true }): window and rows built, greyed icons with their tooltip,
	-- TW.counts.secure == 0; TW.combat(false): the layer and the buttons made once, attributes from TR.ItemAttributes
end)
test('an item that appears in combat shows greyed in its row until combat ends', ...)
test('the scroll lock: in combat with row buttons the wheel and bar hold, the bar at 40% with its tooltip; out of combat it scrolls', ...)
test('no button below 25% while shown; a spare button hidden; the pool never past 35', ...)
test('the look: icon crop, kind action in the tracker\'s pair, cooldown, count, red out of range, the accent in the area', ...)
test('P3 failed: TR.ItemAttributes giving a macro is what every button gets, and the item attribute is cleared', ...)
test('whole pixels with buttons in rows, under the three looks and size noise', ...)
test('off: no secure frame exists', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/items_test.lua tests/lib/harness_self_test.lua`. Expected: FAIL, the template isn't stubbed.
- [ ] **Step 3: Implement** as the Interfaces say, stubs first.
- [ ] **Step 4: Run** `tests/run tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/items.lua SaftUI-Tracker/window.lua SaftUI-Tracker/rows.lua SaftUI-Tracker/init.lua SaftUI-Tracker/options.lua tests/wow/widgets.lua tests/lib/harness_self_test.lua tests/tracker/items_test.lua AGENTS.md .agents/taint.md .agents/testing.md
git commit -m "tracker: add secure quest item buttons in the rows, kept by the combat rules"
```

**In-game checks:** P3 first. Then G1 for the row buttons and G4. Check G7 with the switch on.

---

### Task 9: The column beside the tracker, and Off

**Files:**
- Modify:
  - `items.lua`: the column.
  - `rows.lua`: the numbers, and Off's plain icon.
  - `window.lua`: `TR:IsHovered()` counts the column.
- Test: extend `tests/tracker/items_test.lua`.
- Docs: `.agents/taint.md`, the column paragraph.

**Interfaces:**
- Consumes: Task 8.
- Produces:
  - `TR.Items.Side(holderCenterX, screenCenterX) -> 'left' | 'right'`: left when the holder's centre is right of the screen's.
  - `TR.Items.Column(entries, size, side, windowLeft, windowRight, viewTop, viewBottom) -> places` (pure). Each place is `{ left, top, number } | nil`.
    - `left` is `windowLeft - COLUMN_GAP - size`, or `windowRight + COLUMN_GAP`.
    - `top` is the title's top, or the place above's bottom less `COLUMN_STACK` when they would overlap.
    - The place is nil when the title is out of view.
    - Numbers run 1 to n in list order (Ruling 27).
  - Numbers show in the Pixel font at each button's bottom left, and in the accent at the right end of its row's title.
  - `TR:ColumnWidth() -> size | 0`, for the beside spot (Task 11).
  - Off shows a plain icon in the slot with no click. `TR:IsScrollLocked()` stays false for beside and off.

- [ ] **Step 1: Write the failing tests**

```lua
test('the column is 4 outside the window on the side nearer the screen\'s middle, each button level with its title', ...)
test('a button that would overlap the one above sits 2 under it; out of view is hidden', ...)
test('numbers 1 to n in list order on the button and in the accent at the title\'s end, unchanged as the list scrolls', ...)
test('in combat the column stays and the list scrolls freely; at combat end the column is placed again', ...)
test('Off: a plain icon in the row, no button, no click; the nearest button can still be on', ...)
test('whole pixels with the column on both sides, under the three looks and size noise', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/items_test.lua`. Expected: FAIL, `TR.Items.Column` is nil.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/items.lua SaftUI-Tracker/rows.lua SaftUI-Tracker/window.lua tests/tracker/items_test.lua .agents/taint.md
git commit -m "tracker: add the numbered item column beside the tracker, and item buttons off"
```

**In-game checks:** G1 for the column; G4's second half (the wheel scrolls in combat with the column); the tracker placed on both screen halves.

---

### Task 10: The nearest quest item button and its key

**Files:**
- Create: `SaftUI-Tracker/nearest.lua` (TOC).
- Modify:
  - `init.lua`: `Build`, `UpdateConfig` and the events.
  - `options.lua`: Items gains `nearest`, `nearest_size`, `key` and `nearest_position` (order 1000).
- Stubs: `tests/wow/game.lua` gains `stub.bindings` (key to command), `GetBindingKey(command) -> key1, key2...`, `SetBinding(key, command)`, `SaveBindings(set)` and `GetCurrentBindingSet()`. In combat, `SetBinding` and `SaveBindings` are refused into `stub.blocked` as `{ SetBinding, key }`. A test fires `UPDATE_BINDINGS` itself.
- Test: create `tests/tracker/nearest_test.lua`.
- Docs:
  - `.agents/edit-mode.md`: the `trackernearest` mover.
  - `.agents/taint.md`: the binding is queued in combat; covers gains `nearest.lua`.
  - `.agents/testing.md`.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Task 8's `TR:SetButtonItem` and look.
- Produces:
  - `TR.ChooseNearest(candidates, focusedID)`, the P4 nearest seam. Candidates are tracked quests with an item that `QuestUtil.QuestShowsItemByIndex`'s rule shows.
  - `TR.NEAREST_INTERVAL = 1`.
  - `TR:BuildNearest()`: `SaftUITrackerNearestHolder`, with `SaftUITrackerNearestItem` (`SecureActionButtonTemplate`, its holder's child, `nearest_size` square). Out of combat only (`'tracker_nearest'`). The holder is placed through `st:SafeReposition`.
  - The mover is `st:RegisterMover('trackernearest', ...)`:
    - label `'Nearest quest item'`, `module = 'Tracker'`, `configPath = { 'Tracker', 'items' }`;
    - `isDisabled = function() return not TR.config.items.nearest end`;
    - `isHidden` is true while it has no item;
    - `getDefaultPosition` is a copy of `st.defaults.tracker.items.nearest_position`.
  - `TR:RefreshNearest()`: chooses every 1 s out of combat, and on the quest events, `SUPER_TRACKING_CHANGED`, `PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED` and the zone events. It is frozen in combat and catches up after. It shows only while it has an item, out of combat. Its key shows at the top right in the Pixel font, refreshed on `UPDATE_BINDINGS`. Its tooltip is the item, then the quest's title.
  - `TR.NearestKey() -> key | nil` and `TR:SetNearestKey(key)`. `''` clears. Old keys are cleared first, then `SetBinding(key, TR.NEAREST_COMMAND)` and `SaveBindings(GetCurrentBindingSet())`. Queued as `'tracker_binding'` in combat.
  - The `key` row: type `'keybinding'`, `get = TR.NearestKey`, `set = TR:SetNearestKey`. Its `default` resets to no key.

- [ ] **Step 1: Write the failing tests**

```lua
test('the choice: inside its area, else the focused quest, else the nearest on your continent, else the game\'s order; no distance is farthest', ...)
test('P4 fallback: with distance and areas not answering, focus then the game\'s order', ...)
test('chosen again each second out of combat; frozen in combat; caught up at combat end, stub.blocked empty', ...)
test('shown only while it has an item; off by default; its mover disabled while off, hidden while it has no item', ...)
test('the key: get is GetBindingKey of the command; set clears the old keys, binds and saves; Esc clears; queued in combat', ...)
test('its key in the Pixel font at the top right, refreshed on UPDATE_BINDINGS; whole pixels under the three looks', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/nearest_test.lua`. Expected: FAIL, `TR.ChooseNearest` is nil.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker tests/core/editmode_movers_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/nearest.lua SaftUI-Tracker/init.lua SaftUI-Tracker/options.lua tests/wow/game.lua tests/tracker/nearest_test.lua AGENTS.md .agents/edit-mode.md .agents/taint.md .agents/testing.md
git commit -m "tracker: add the keybound nearest quest item button"
```

**In-game checks:** G1 for the nearest button by its key. Set the key from the Items tab and from Key Bindings; it shows on the button. Move it in edit mode. P4's distance and area lines decide the fallback.

---

### Task 11: Sections and the handover

**Files:**
- Create: `SaftUI-Tracker/probes.lua` and `handover.lua` (TOC).
- Modify:
  - `blizzard.lua`: `TR:WatchModules()` and `PlaceBlizzard('beside')`.
  - `layout.lua`: `TR.Layout.BesideSpot`.
  - `init.lua`: the probe events and the handover in the refresh.
  - `options.lua`: the Blizzard's tracker tab.
- Fixture: `tests/misc/fixtures/objective_tracker.lua` gains:
  - `tracker.modules` (the eleven), and on each module `state` and `hasContents`;
  - `ObjectiveTrackerModuleState` (`Skipped` 1 to `ShownFully` 5);
  - `ObjectiveTrackerUIWidgetContainer` with `GetNumWidgetsShowing`;
  - `OT.run_update(module, state, hasContents)`, Blizzard's own call to the module's `Update`.
- Stubs (`tests/wow/quests.lua`): `C_Scenario.GetInfo`, `GetTasksTable`, `GetTaskInfo`, `C_ContentTracking.GetTrackedIDs`, `Enum.ContentTrackingType` (Appearance 0, Mount 1, Achievement 2, Decor 3), `GetAchievementInfo`, `C_TradeSkillUI.GetRecipesTracked`, `C_PerksActivities`, `C_NeighborhoodInitiative` and `C_ChallengeMode.IsChallengeModeActive`.
- Test: create `tests/tracker/probes_test.lua` and `handover_test.lua`; extend `conceal_test.lua` (the beside spot) and `source_scan_test.lua` (the module hook).
- Docs:
  - `.agents/taint.md`: the module hooks and reads.
  - `.agents/clients.md`: which sections Forever fills is P4's.
  - `.agents/testing.md`.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Tasks 6 and 8 (`TR:ItemsToShow`) and 9 (`TR:ColumnWidth`).
- Produces:
  - `TR.SECTIONS`, in this order (key, name, module):
    - `scenario`, Scenario, `ScenarioObjectiveTracker`;
    - `widgets`, Zone widgets, `UIWidgetObjectiveTracker`;
    - `bonus`, Bonus objectives, `BonusObjectiveTracker`;
    - `world`, World quests, `WorldQuestObjectiveTracker`;
    - `achievements`, Achievements, `AchievementObjectiveTracker`;
    - `professions`, Professions, `ProfessionsRecipeTracker`;
    - `activities`, Monthly activities, `MonthlyActivitiesObjectiveTracker`;
    - `endeavors`, Endeavors, `InitiativeTasksObjectiveTracker`;
    - `collections`, Collection tracking, `AdventureObjectiveTracker`.

    The two quest modules are never read.
  - `TR.SectionHandsOver(key)`, the P4 sections seam.
  - `TR.Probes.Scenario()`, `Widgets()`, `Bonus()`, `WorldQuests()`, `Achievements()`, `Professions()`, `Activities()`, `Endeavors()` and `Collections()`, each `-> boolean` by the spec's table. A missing API answers no.
  - `TR.ModuleHasContent(state, hasContents)`: true for `NotShown`, `ShownPartially`, `ShownFully`, or `hasContents`.
  - `TR:WatchModules()`: a post-hook on each module's own `Update` (looked up at call time) reads `state` and `hasContents` and asks for a probe pass. It walks `ObjectiveTrackerFrame.modules` for unknown frames. An unknown module with content prints once a session "Blizzard's tracker has a section SaftUI doesn't know (<name>); Blizzard's tracker shows while it has content.".
  - `TR.HOLD = 2` and `TR.Probes.Held(seen, lastSeen, now) -> needed`: a section counts from the moment it has content, until 2 s without any.
  - `TR:RunProbes()`, at most once a frame, on the spec's probe events and after the module hook. `TR:NeededSections() -> { key, ... }`.
  - `TR.Handover.Next(state, needed, inCombat, mode, itemsToShow) -> state, actions`. The actions are `'hide_items'`, `'hide_window'`, `'reveal_place'`, `'reveal_beside'`, `'conceal'`, `'show_window'` and `'show_items'`, in order.
  - `TR:UpdateHandover()` runs the actions; a mode change follows Ruling 28; a `/reload` starts from `'own'`.
  - `TR.Layout.BesideSpot(holderLeft, holderRight, holderTop, side, columnWidth) -> point, x, y` (12 out, past the column and its 4 when the column is on that side). `'TOPRIGHT'` on the left, `'TOPLEFT'` on the right, with the clamp on.
  - `TR:HandoverText()`: "Not needed now." or "Showing Blizzard's tracker for: Scenario, Achievements.".
  - The tab:
    - `blizzard.mode` (select: In SaftUI's place, Beside SaftUI's);
    - the "Now:" description, read when the page draws;
    - the spec's note.

- [ ] **Step 1: Write the failing tests.** In `handover_test.lua`, the spec's table as data:

```lua
local CASES = { -- from, needed, combat, mode, itemsToShow -> to, actions
	{ 'own',      true,  false, 'place',  true,  'blizzard', 'hide_items,hide_window,reveal_place' },
	{ 'own',      true,  true,  'place',  true,  'both',     'reveal_beside' },
	{ 'own',      true,  false, 'beside', true,  'both',     'reveal_beside' },
	{ 'both',     false, true,  'place',  true,  'own',      'conceal' },
	{ 'both',     false, false, 'beside', true,  'own',      'conceal' },
	{ 'both',     true,  false, 'place',  true,  'blizzard', 'hide_items,hide_window,reveal_place' },
	{ 'both',     true,  true,  'place',  true,  'both',     '' },
	{ 'both',     true,  false, 'beside', true,  'both',     '' },
	{ 'blizzard', false, false, 'place',  true,  'own',      'conceal,show_window,show_items' },
	{ 'blizzard', false, true,  'place',  false, 'own',      'conceal,show_window' },
	{ 'blizzard', false, true,  'place',  true,  'blizzard', '' },
	{ 'blizzard', true,  true,  'place',  true,  'blizzard', '' },
	{ 'own',      false, false, 'place',  true,  'own',      '' },
}
-- each case: eq(to .. ' ' .. table.concat(actions, ','), expected, case's label)
test('a mode change goes back to own, then runs the table again; a /reload starts from own', ...)
test('in place: Blizzard\'s top right on the window\'s; beside: 12 out on the side nearer the middle, past the column', ...)
test('a profile switch during a handover', function()
	-- Review Focus 5: in place and beside, OTP:UpdateConfig() then TR:UpdateConfig(): Blizzard's stays at its spot, OTP moves nothing
end)
test('the Now line names the needed sections by the table\'s names; the tab\'s mode, Now and note', ...)
-- probes_test.lua: each probe yes and no on its API, and no with it missing; the module signal through OT.run_update;
-- a Skipped achievements module with content found by its probe; an unknown module with content hands over and prints once;
-- the 2 s hold (stub.time); at most one pass a frame; TR.SectionHandsOver false for one key keeps it from handing over
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/probes_test.lua tests/tracker/handover_test.lua`. Expected: FAIL, `TR.Handover` is nil.
- [ ] **Step 3: Implement** the fixture and stubs, then the two files and the beside spot.
- [ ] **Step 4: Run** `tests/run tests/tracker tests/misc`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/probes.lua SaftUI-Tracker/handover.lua SaftUI-Tracker/blizzard.lua SaftUI-Tracker/layout.lua SaftUI-Tracker/init.lua SaftUI-Tracker/options.lua tests/misc/fixtures/objective_tracker.lua tests/wow/quests.lua tests/tracker/probes_test.lua tests/tracker/handover_test.lua tests/tracker/conceal_test.lua tests/tracker/source_scan_test.lua AGENTS.md .agents/taint.md .agents/clients.md .agents/testing.md
git commit -m "tracker: hand over to Blizzard's tracker while a section SaftUI doesn't draw has content"
```

**In-game checks:** P4 first. Then G3: a dungeon or a tracked achievement, in and out of combat. The Now line. G2 after a handover in combat.

---

### Task 12: Fading and hiding

**Files:**
- Create: `SaftUI-Tracker/visibility.lua` (TOC).
- Modify:
  - `items.lua`: the layer's driver from `TR.Visibility.Driver`.
  - `blizzard.lua`: `TR:SetBlizzardAlpha` and a post-hook on its `SetAlpha`.
  - `window.lua`: Background under the mouse only; faded rows take no mouse.
  - `init.lua`: the events.
  - `options.lua`: the Visibility tab.
- Stubs: `IsEncounterInProgress` (`stub.encounter`).
- Test: create `tests/tracker/visibility_test.lua`; extend `source_scan_test.lua` (`SetAlpha`).
- Docs:
  - `.agents/taint.md`: the fade on Blizzard's tracker; no button invisible while clickable.
  - `.agents/architecture.md`.
  - `AGENTS.md` row.

**Interfaces:**
- Consumes: Tasks 8 and 11.
- Produces:
  - `TR.Visibility.Applies() -> { combat, nocombat, mouseoff, instance, boss, mythic }`. It reads `InCombatLockdown`, `TR:IsHovered`, `IsInInstance`, `IsEncounterInProgress` and `C_ChallengeMode.IsChallengeModeActive` where present.
  - `TR.Visibility.Resolve(applies, settings, hovered) -> { window = 'show' | 'fade' | 'hide', alpha, items = 'show' | 'fade' | 'hide', itemAlpha, hideItemsDirectly, background }` (pure):
    - the strongest trigger wins, Hide over Fade over Show;
    - Show fully under the mouse turns Fade into Show;
    - with `items` off, `itemAlpha` is always 1;
    - faded item buttons follow Ruling 31;
    - Mouse off never hides buttons;
    - In instances and Mythic+ Hide set `hideItemsDirectly`.
  - `TR.Visibility.Driver(settings) -> string`.
  - `TR:ApplyVisibility()`: fades take `TR.FADE_TIME = 0.2` from faded to full, alpha only. The window hides by `Hide`, in combat too. Faded-to-0 rows get `EnableMouse(false)`. The driver is set out of combat, else queued as `'tracker_items'`. During a handover the result goes to Blizzard's tracker: Hide conceals it (`PlaceBlizzard('concealed')`), and Fade calls `TR:SetBlizzardAlpha(alpha)` (the C `SetAlpha`, re-applied after Blizzard's own). Hover is read from SaftUI's holder or the beside spot's numbers.
  - The tab: the six triggers (selects; Mouse off is Show or Fade; Mythic+ hidden where the function is missing), `fade_alpha` (`isPercent`), `hover`, `background_hover`, `scrollbar_hover` and `items`.

- [ ] **Step 1: Write the failing tests**

```lua
local function v(t) return setmetatable(t, { __index = st.defaults.tracker.visibility }) end
eq(TR.Visibility.Driver(v{}), '[petbattle] hide; show')
eq(TR.Visibility.Driver(v{ items = true, combat = 'hide' }), '[petbattle] hide; [combat] hide; show')
eq(TR.Visibility.Driver(v{ items = true, nocombat = 'hide', boss = 'hide' }), '[petbattle] hide; [nocombat] hide; [@boss1,exists] hide; show')
eq(TR.Visibility.Driver(v{ combat = 'hide' }), '[petbattle] hide; show', 'buttons stay with Hide quest items off')
test('each trigger and choice alone; the strongest wins; hover turns Fade into Show, never Hide', ...)
test('items off: full alpha whatever the window does; on: Fade at max(fade_alpha, 0.25), Hide by the driver or directly', ...)
test('a faded-to-0 window takes no clicks; a hidden one is hidden; a button is never under 25% while shown', ...)
test('Background under the mouse only: the panel only while hovered, the text always', ...)
test('during a handover the triggers apply to Blizzard\'s: Hide conceals it, Fade sets its alpha and puts it back after Blizzard\'s', ...)
test('the driver changes out of combat only, queued in combat with stub.blocked empty', ...)
test('the Visibility tab: the six triggers, Mythic+ only where the client has it, the five options', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/tracker/visibility_test.lua`. Expected: FAIL, `TR.Visibility` is nil.
- [ ] **Step 3: Implement** as the Interfaces say.
- [ ] **Step 4: Run** `tests/run tests/tracker`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Tracker/SaftUI-Tracker.toc SaftUI-Tracker/visibility.lua SaftUI-Tracker/items.lua SaftUI-Tracker/blizzard.lua SaftUI-Tracker/window.lua SaftUI-Tracker/init.lua SaftUI-Tracker/options.lua tests/wow/game.lua tests/tracker/visibility_test.lua tests/tracker/source_scan_test.lua AGENTS.md .agents/taint.md .agents/architecture.md
git commit -m "tracker: fade and hide the tracker by combat, mouse, instance, boss fight and Mythic+"
```

**In-game checks:** G5: every trigger and choice, with Hide quest items with the tracker on and off. A hidden button never clicks.

---

### Task 13: Every state together; docs; the in-game checklist

**Files:**
- Test: create `tests/tracker/states_test.lua`.
- Docs:
  - Re-read `.agents/architecture.md`, `taint.md`, `edit-mode.md`, `clients.md` and `testing.md` end to end against the code.
  - `AGENTS.md` row and `README.md` (a features line: SaftUI's own tracker, off until its checks pass).
- `docs/followups.md`:
  - Mark the "Objective tracker skin" entry's zone grouping, max height and scroll frame as taken up here.
  - Add the entry "SaftUI's tracker: experiments and in-game checks before the switch turns on". It holds P1 to P5 in order, then G1 to G12, each with the task that built it. Flipping the default (`tracker.enable = true`) is its last step, a one-line change.
  - Add one entry each for Phases 2 to 6, as the spec's Phasing section names them.
  - Add one for Ruling 21 (`[vehicleui]` and `[overridebar]`).
  - Update the ToC.

**Interfaces:**
- Consumes: everything.
- Produces: nothing new.

- [ ] **Step 1: Write the tests**

```lua
test('every state on every look and client sits on whole pixels with nothing blocked', function()
	-- for client forever/retail, theme thick/thin/blizzard, placement row/beside/off, grow down/up,
	-- handover own/blizzard/both, collapsed and not, scrolled and not, size noise up/down/off (sampled so each value
	-- meets every other once across the two clients): #P.off(window) == 0, #P.off(TR.layer) == 0, stub.blocked empty,
	-- OT.stray empty, #take_errors() == 0
end)
test('combat in and out at every state: no secure call in combat, one pass after', ...)
test('a theme change, a profile switch and /sui changes at every state make no new frame', ...)
test('off at the end: Blizzard\'s tracker, the skin and its mover exactly as with SaftUI-Tracker not loaded', ...)
```

- [ ] **Step 2: Run** `tests/run tests/tracker/states_test.lua`. Expected: PASS (or a failure that names a real bug, fixed in the task that owns it).
- [ ] **Step 3: Docs and followups** as listed under Files.
- [ ] **Step 4: Run** `tests/run`, the whole suite. Expected: PASS.
- [ ] **Step 5: Commit**

```bash
git add tests/tracker/states_test.lua AGENTS.md README.md docs/followups.md .agents/architecture.md .agents/taint.md .agents/edit-mode.md .agents/clients.md .agents/testing.md
git commit -m "tracker: check every state together and list the in-game checks before the switch turns on"
```

**In-game checks:** the followup's list in order, Forever first and then retail. P1 to P5 come before the switch is turned on, with each result folded into its seam (Experiment seams); G1 to G12 come after.

---

## Spec coverage check

| Spec section, call or settled point | Task |
| --- | --- |
| Why; What the owner decided 1, 2, 7; Goals; Anti-goals | 1–13 (anti-goals: 6, 8, 5) |
| Decided 3 (bar under the mouse), 4 (width and height) | 4 |
| Decided 5 (item placements) | 8, 9, 10 |
| Decided 6 (fading and hiding) | 12 |
| Decided 8 (in-game tests) | 13 |
| Decided 9 (colors reused, full-height outline, zones, max height, scroll) | 2, 4, 3, 5 |
| Non-goals | not built; Blizzard's shows the rest: 11 |
| Re-checked in Blizzard's source | 6 (clamp, overrides, hooks), 11 (states, widget count), 3 (headers, APIs), 8 (secure `item`) |
| Where it lives: the addon, TOC, Bindings, module, files | 1 (files grow by task) |
| The skin and mover stay in Misc; stand down; renames; colors section | 6; 2 |
| The switch; default off; standing down | 1 |
| The colors move to Colors; conversion | 2 |
| Concealed, never hidden; never list; allowed list | 6 (source scan), 11, 12 |
| Which sections; content detection; hysteresis; handover; beside spot; Now line; rules | 11 |
| The data: reads, campaign and task quests | 3 |
| Events, throttling, pools and diff, tickers, mouse check | 5, 8 (range), 10 (nearest), 4 and 12 (mouse) |
| Secret values | 3, every reader |
| Frames (holder, window, item layer, nearest) | 4, 8, 10 |
| Layout values; zone groups; quest rows; item slot; hover | 4, 5, 3; 8, 9; 5 |
| Auto quest popups | 5 |
| Clicks; menu; tooltips | 7 |
| The focused quest | 5 |
| Theme | 4, 5, 8 |
| Size and scroll (Width, Max height, Grow, bar, wheel, in combat, keeping place, collapsed, Hide when empty) | 4, 5, 8 (lock) |
| Quest item buttons: why secure, rules, look, layer | 8 (driver: 12) |
| In the row; Beside; Off; Nearest; the key; combat limits | 8; 9; 9; 10; 10; 8, 10 |
| Fading and hiding: triggers, combining, hidden, Blizzard's | 12 |
| Movers (`tracker`, `trackernearest`, OTP's) | 4, 10, 6 |
| The Tracker page: General, Quests, Items, Visibility, Blizzard's tracker | 1 and 4; 5 and 7; 8, 9, 10; 12; 11 |
| Settings that move from the skin's page | 6 (none move; renames) |
| Edge cases | 3 (missing header, repeats, unloaded data, arena), 5 (empty, many, complete, zone change), 8 (abandoned in combat, collapsing in combat, `/reload` in combat), 11 (task quests, Edit Mode open), 6 (another addon touching it, profile switch, Misc absent), 1 (another tracker addon) |
| Testing: Lua tests and stubs | each file's task as named; 13 |
| What only the game can confirm (G1–G12); experiments P1–P5 | 13 (listed per task too) |
| Phasing (Phase 1 only) | this plan; 13 adds the later phases' followups |
| What's left to the builder: docs, followups | every task; 13 |
| Risks 1, 9 / 2 / 3 / 4 / 5, 6 / 7 / 8 / 10 / 11 / 12 / 13 / 14 | 6, 11 / 8 / 7 / 5 / 11 / 11 / 3, 10 / 13 (G12) / 1 / 2 / 1 / 8 (P3 seam) |
| Calls 1, 3, 31 | 11 |
| Calls 2, 6, 8, 29 | 6 |
| Calls 4, 5, 28 | 1 |
| Call 7 | 2 |
| Calls 9, 11, 32, 33 | 8 (9 also 9, 10) |
| Call 10 | 8 |
| Calls 12, 13 | 10 |
| Calls 14, 15 | 7 |
| Calls 16, 17 | 12 |
| Calls 18, 19 | 3, 5 |
| Calls 20, 21, 34 | 3, 5 |
| Calls 22, 23 | 5 |
| Calls 24, 25, 27 | 4 |
| Call 26 | 4 (Ruling 7) |
| Call 30 | 4, 5, 9, 11 |
| Call 35 | 13 (followups in that order) |
| Settled 1 (approved) | all |
| Settled 2 (Show: tracked, or also the current zone's) | 3 (model, groups), 5 (row), 7 (track from the menu) |
| Settled 3 (phase order) | 13 |
| Settled 4 (build first, switch off, one function per experiment) | 1 (off), Experiment seams, 13 (checks before the flip) |

**Where the spec is ambiguous or the code disagrees** (each is a Ruling above):
- The code disagrees: Ruling 2 (where `st.defaults.colors` lives), Ruling 3 (`map-pin` already registered), Ruling 10 (Blizzard's bounty check reads an undefined global), Ruling 25 (`stub.apply_client` handled only globals), and Ruling 8 (`st:RegisterConfigMover` needs a `position` key).
- The tests pin names this work changes: the movers test's seven modules (Task 4), and the OTP tests' page name and label (Task 6).
- The spec leaves open: Rulings 1, 5–7, 9 and 11–32.
