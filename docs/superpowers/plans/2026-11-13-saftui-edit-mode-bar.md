# Edit Mode Bar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Edit mode gets a bar of its own across the top of the screen, which can be detached into a floating window. It holds every edit mode control: Exit, Grid and its size, the two snaps, Dim world, Coordinates, which movers show (Show disabled, Show hidden, a module list, a filter box), Undo, Redo, History, Reset and Options. Edit mode's buttons leave `/sui`'s footer, and the history (part one) records moves, nudges, resets and Copy from.

**Architecture:** Each addon's mover registration gains data: a `module` name, disabled and hidden predicates, and a default position. Core never names a module. The bar is a list of groups of controls built on the options kit's components, which this work lifts out of the window into standalone kit pieces (a button, an icon button, a select face, a number box). One layout pass places that list docked across the top, and another places it in a floating window. One function decides which movers show. The history is a generic store: a step is a label, a time and a list of changes (kind, where, old, new), applied through setters registered per kind. Edit mode registers the position kind, and Unitframes registers a settings kind for Copy from. Part two (every `/sui` setting) will register one more kind, with no redesign.

**Tech Stack:** Lua 5.1, the WoW API on WoW Forever (16001) and retail (120000), AceDB-3.0 profiles, SaftUI's options kit (`st.OptionsWidgets` `W`, `st.OptionsBody` `OB`), Lucide icons (lucide-static 0.460.0, made with `tools/lucide-to-tga.cjs`), and tests on stubs with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-13-saftui-edit-mode-bar-design.md`. Its last section, "Settled with the owner after the first draft", overrides anything earlier that it contradicts. Points 12 to 15 replace point 2 and every mention of a single "Show hidden" toggle. This plan covers part one of the history only (Settled 13). The rules for what a step is come from `docs/research/2026-11-13-undo-history-systems.md` ("Recommendation for the SaftUI edit mode"), as the coordinator folded them in (Ruling 8). They stay provisional until the owner confirms them, and each lives in one named place. The looks are in `.superpowers/brainstorm/46409-1794604463/content/editmode-floating-v1.html` (docked, floating, the History list) and in `window-and-editmode-v4.html` part 2 (the Show check list). Where a mockup and the spec differ, the spec wins.

## How the tasks are cut

The six tasks asked for became eight, with three changes:

- **The kit's controls are a task of their own (Task 2).** The bar needs a square icon button that requires its tooltip (the design system's code change 5), the window's button lifted out of `optionswindow.lua`, a standalone select face, the position block's number box and nudge pair lifted out of `optionsposition.lua`, buttons under the check list, and fourteen new icons. The spec asks for these as shared Core pieces, not bar-only widgets. Building them first keeps the bar task reviewable, gives them their own tests, and lets them run beside Task 1, since the two share no code file.
- **Dim world and Coordinates are their own task (Task 4).** Coordinates carries its own text and placement geometry, and a reviewer could reject it while approving the bar.
- **The history store comes after the bar and the filter (Task 6).** The store has no UI, so the bar (Task 3) is the first thing the owner can try in game. Reset's default reader comes earlier, in Task 1.

| # | Task | Needs | Owner can try in game |
| --- | --- | --- | --- |
| 1 | Mover registration data | — | nothing visible |
| 2 | Kit controls and icons | — | the position block's arrows are Lucide chevrons |
| 3 | The docked bar; `/sui`'s footer cleared | 2 | the bar, its grid controls, Exit, Options |
| 4 | Dim world and Coordinates | 3 | both toggles |
| 5 | What shows: Show disabled, Show hidden, modules, filter, overlapping labels | 1, 3 | the filter controls |
| 6 | The history store, fed by drags, nudges and resets | 1 | nothing visible (stub tests only) |
| 7 | Undo, Redo, Reset and History on the bar; Copy from as one step | 3, 6 | the history |
| 8 | The floating window | 3, 5, 7 | detach and dock |

**Side by side.** Tasks 1 and 2 share no code or test file:
- Task 1 owns `SaftUI-Core/EditMode/editmode.lua`, the registration files in every addon, `tests/core/editmode_movers_test.lua` and the addon tests it names.
- Task 2 owns `SaftUI-Core/Config/optionscontrols.lua`, `optionsposition.lua`, `optionslist.lua`, `optionswindow.lua`, `Config/load.xml`, `SaftUI-Core/constants.lua`, the new TGAs, `tests/lib/shell.lua` and its own tests.

Both still have to update `.agents/edit-mode.md` (Task 1 the "Registering a mover" section, Task 2 the widgets paragraphs and `covers:`) and `.agents/testing.md`. In `testing.md` the `tests/core/` row is one line, so that merge needs a hand: keep both sides, as `.agents/workflow.md` says for parallel tasks. If no file may be shared at all, run 1 and then 2. Every later task edits a file its neighbour also edits (`EditMode/load.xml`, `tests/lib/shell.lua`, `mover.lua`, the bar's files, the same two docs), so Tasks 3 to 8 run one after another, in the order above.

## Global Constraints

- Nothing under any `Libraries/` folder may change.
- Movers move secure frames (action bars, unit frames) and Blizzard frames SaftUI has taken over (the objective tracker, totem bar, buffs, chat): Undo, Redo, Reset and reverting a history step move a frame only through the same path a drag uses (the mover's own setter and the repo's deferring helpers), never directly, and never in combat. `.agents/taint.md` applies.
- The game calls `OnEnter`/`OnLeave` with a second argument (`motion`); never bind a function with an optional second parameter straight as a script, and fire hover scripts in tests with `true`.
- The game reads a frame's size back with float noise: heights and widths read back are rounded (`OB.WholeHeight` is the kit's helper; see `.agents/testing.md` on `stub.size_noise`), and everything the bar and the floating window place sits on whole pixels; tests use `tests/lib/pixels.lua`.
- Icons are Lucide's, registered in `st.icons`; a new one is made with `tools/lucide-to-tga.cjs` (the pinned Lucide version names the funnel `filter`: check each icon's file name exists at that version). Every name this plan uses was checked at 0.460.0: `log-out`, `grid-3x3`, `magnet`, `align-start-vertical`, `layers`, `map-pin`, `eye`, `power-off`, `search`, `undo-2`, `redo-2`, `history`, `picture-in-picture-2`, `panel-top`.
- One button component at one size and font; "on" is the accent colour; an icon-only control has a tooltip. The accent is `st.config.profile.colors.button.blue`, read at draw time; disabled is alpha 0.4.
- Both looks: under the Blizzard theme say how each piece draws. Both clients (Forever 16001, retail 120000).
- New SaftUI-only option fields go in `SAFTUI_FIELDS` and `.agents/edit-mode.md`. This plan adds none: the bar isn't drawn from option tables, and the Edit mode tab's new rows are plain Ace fields.
- Core never names a module or lists a module's frames: every name comes from a mover's registration (spec anti-goal).
- Nothing on the bar touches a Blizzard frame or calls Blizzard's Edit Mode code (`.agents/taint.md` rules 1 and 3): reading `EditModeManagerFrame:IsShown()` is the only contact.
- Commits: lowercase `module: imperative summary`; stage by explicit path; never `git add -A`. End each with the session's `Co-Authored-By` line.
- Keep the user's account and character names out of everything.
- Each task updates the docs its change makes wrong (`.agents/*.md`, file headers, `README.md`, the design system's source under `docs/design-system/` where a component it documents changes) and hands back an in-game checklist. Then it runs the `agents-doc-parity-check` and `readme-freshness-check` skills (AGENTS.md).
- Each task ends green on `tests/run -j2`. Run single files while working (`tests/run tests/<area>/<file>`). Keep each file's line endings. An assertion an earlier test made is changed only where this work changes the behaviour it pins, and the report lists each one with why.

## Review Focus

1. **Movers under the docked bar** (the micro menu, the top of the minimap and the buffs sit in the screen's top 40 or so pixels): a click in a gap between the bar's controls reaches the mover under it, and the Alt picker works there. The filter's Enter selects a covered mover, which the arrow keys then nudge. The Coordinates label never draws under the bar. Tests: Task 3 (the bar's frame takes no mouse, only its controls do), Task 4 (the label flips below the bar), Task 5 (Enter selects a mover whose rect is under the bar).
2. **Undo of a move on a secure frame while in combat, or around it:** in combat nothing writes or moves, and nothing is blocked. Edit mode closing for combat mid-drag still records the drag. Out of combat, an undo moves the frame through its `apply` (and so `st:SafeReposition`) once. Tests: Task 6.
3. **Reset on a frame whose default isn't in `st.defaults`:** the objective tracker resets to Blizzard's default spot, saved as a copy, and `OTP:KeepPlacement` keeps it across a profile change. The totem bar's Reset is disabled with its reason. No reset ever hands out, or writes into, an AceDB defaults table. Tests: Task 1 (the data) and Task 6 (the reset).
4. **History after a profile switch:** the history clears on a profile change, copy or reset, and on a unit frame profile switch. It is kept across a theme change (which also runs `Config:UpdateConfig`) and across Exit. A drag in progress at a profile change records nothing. Tests: Task 6 and Task 7.
5. **A narrow game window, another UI scale, a window off screen:** the bar gives way in order and stays on whole pixels at 1920, 1366, 1024 and 800 wide, with `stub.size_noise`, and again after `UI_SCALE_CHANGED`. The floating window can't be dragged off screen. A saved place the screen no longer has comes back inside the margin. The window and the History list sit over `/sui` and under the kit's lists. Tests: Task 3 and Task 8.

## Rulings on the spec

Each is a call the spec leaves open or the code forces. The tasks assume them, and the report lists them for the owner.

1. **Shown, disabled, hidden.** Disabled means turned off by a setting, SaftUI's or Blizzard's (a disabled bar or unit frame, a swing timer Blizzard's setting hides). Hidden means on but not on screen right now: a closed bag window, no pet, no target, no boss, solo party and raid frames, an extra button not active, a bar shown only in combat, no loot roll. A faded bar is shown. One rule, `EM:IsMoverShown`, applies them: a disabled mover shows only with Show disabled on; an enabled, hidden one only with Show hidden on. Both toggles ship off (Settled 12). *Note 2026-11-13 (controller's ruling, pending the owner's confirmation): Show hidden ships on and Show disabled off; overlap is by the frames' own rects with a 1 px tolerance, not the outlines.* Most movers then stay hidden until Show hidden is pressed: target, focus, pet, party, raid, boss, bags and loot rolls.
2. **Icons.** Show disabled is `power-off` and Show hidden is `eye`. History is `history`, as the mockup draws it, Detach is `picture-in-picture-2` and Dock is `panel-top` (the mockup's two drawings).
3. **The docked bar, left to right:** [Exit] | [Grid, Grid size, Snap to grid, Snap to frames, Dim world, Coordinates] | [the "Show" caption, Show disabled, Show hidden, the module face] | [Filter movers], then a flexible gap, then [Undo, Redo, History, Reset] | [Options, Detach]. The spec's widths stay (face 150, filter 150; the newest mockup's 128 and 140 are only its own guess). The spec's four give-way steps keep their order, and a fifth hides the filter box. Below that (under about 680 pixels) the docked bar overlaps, and the floating window is the answer.
4. **Grid size typed** takes any whole number from 8 to 128, not only steps of 4 (Settled 10, "any grid size manually"). The range stays the grid's. The arrows step by 4 from whatever the value is.
5. **The Coordinates text** names the parent (Settled 11): `'<Point> of <parent>: x, y'`, or `'<Point> to <relative point> of <parent>: x, y'` when the two points differ. A point reads as `Top left` (sentence case, "Center" as the UI spells it), and the relative point is lowercase. The parent is "the screen" for UIParent or none, a mover's name when it is another mover's frame, else the stored name. Offsets show as whole numbers, or with one decimal at another scale. The label never draws under the docked bar.
6. **When the history clears:** on AceDB's `OnProfileChanged`, `OnProfileCopied` and `OnProfileReset`, registered by the store itself, and on a unit frame profile switch. It does not clear on `EM:UpdateConfig`, which also runs on every theme change through `Config:UpdateConfig`. It is kept across Exit, and it is never saved.
7. **Position sets in `/sui` are not steps** in part one: they are a setting changed in `/sui`, which is part two. A step that one leaves stale is dropped on undo, by the spec's staleness check.
8. **Step rules** (the coordinator's, provisional, each in a named place):
   - (a) a drag is one step, press to release, start and end only;
   - (b) a step with no net change records nothing;
   - (c) nudges merge only into an open top step of the same mover, of kind nudge, with nothing pushed since and at most `History.MERGE_GAP` (1) seconds since the last. The merged step keeps the position from before the first nudge and the latest one. A run closes on a change of selection, any other kind of action, leaving edit mode, a profile change or an error;
   - (d) a reset is its own step, never merged, and closes any run;
   - (e) Copy from is one bulk step, counted once toward the limit;
   - (f) labels are verb, target and net result: `Moved Player`, `Nudged Bar 3 by 16, 0`, `Reset Chat`, `Copied Target to Focus`, `Reverted: Moved Player`;
   - (g) a new step after undoing discards the redo steps, with no branching;
   - (h) the History list lists newest first (spec Settled 8), so the undone steps sit at the top, greyed with "undone", and the current step carries an accent mark. A last row, "Before these changes", jumps to before every step. Clicking a row jumps to that state, and every step stays redoable until a new one. A row's revert shows only on an applied step. It is enabled only when no later applied step touched the same place and the place isn't stale, and it pushes a new step. A bulk step has no revert;
   - (i) rule 8 (the step's mover filtered out or off screen) is met by the bar's status line naming it, not by selecting it: a selected mover hidden by the filter is deselected (spec);
   - (j) the limit is 50 by default, settable from 1 to 1000, oldest dropped first.
9. **History length** lives in the profile as `editmode.history_limit`. It is set in the History list's foot (a number box whose arrows step by 10) and in a row on the Edit mode tab.
10. **Where choices are saved.** The grid, the snaps, Dim world, Coordinates, the Show toggles, the module choice and the history length go in the profile's `editmode`, beside today's. Docked or floating, and the window's place, go in `st.config.global.editModeBar`: they place a window, as `/sui`'s `st.config.global.optionsWindow` does, so a profile switch doesn't move it.
11. **Strata.** The bar and the floating window are at `FULLSCREEN_DIALOG` level 9500: over the movers (10 to 9000), `/sui` (100), its dialog (300) and its menus (410). The History list is at 9700 and the Coordinates label at 9100. The kit's lists, the confirm dialog and the game's tooltip stay in `TOOLTIP`, over all of them.
12. **A disabled button on the bar keeps the mouse,** so its tooltip can say why: the bar has no row to show it, as a kit row does. Its clicks do nothing.
13. **The nudge pair is lifted into the kit, drawing Lucide chevrons,** for the grid size box and the position block alike (the Icons component lists the drawn triangles for replacement), so the position block's arrows change look too.
14. **Options with no mover selected** opens `st.Config:Open('Fonts', 'editmode')` (Global Settings > Edit mode).
15. **The floating window** (the mockup): 312 wide. Its title row holds "Edit mode", Dock and Exit, as icons. Its three sections are Grid and snap, Show and Changes, with Options at the right of Changes. It is drawn as a `panel`, as the bar is.
16. **During a drag** the bar (or window) goes to alpha 0.25 and its controls take no mouse. The status line clears after 6 seconds.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/EditMode/editmode.lua` | The mover fields and their readers; chat lines; `UpdateConfig` firing `SettingsChanged` | 1, 3 |
| Every addon's registration file (Task 1's table) | `module`, predicates, defaults | 1 |
| `SaftUI-Core/Config/optionscontrols.lua` (new, after `optionsitem.lua`) | `W.Button`, `W.IconButton`, `W.IconLink`, `W.SelectFace`, `W.NumberBox`, `Kit.NudgePair`, `W.ShowTip`, `W.SetOn`, `W.SetEnabled` | 2 |
| `SaftUI-Core/Config/optionsposition.lua`, `optionslist.lua`, `optionswindow.lua` | the lifted pieces used; the check list's buttons; the window's button; the footer API removed | 2, 3 |
| `SaftUI-Core/EditMode/footer.lua` | deleted | 3 |
| `SaftUI-Core/EditMode/settings.lua` | `EM:SetSetting`, the grid size setters, the Edit mode tab | 3, 4, 5, 7 |
| `SaftUI-Core/EditMode/Bar/load.xml`, `bar.lua`, `bargroups.lua` (new) | the bar frame, the group list, the docked layout; Exit, the grid group, Options | 3, 4, 8 |
| `SaftUI-Core/EditMode/grid.lua`, `coordinates.lua` (new) | Dim world; Coordinates | 4 |
| `SaftUI-Core/EditMode/filter.lua` (new), `Bar/barshow.lua` (new), `picker.lua`, `mover.lua` | which movers show, labels where movers overlap; the Show and filter groups | 5 |
| `SaftUI-Core/EditMode/history.lua`, `moves.lua` (new), `mover.lua` | the store; the position kind, records, Reset | 6 |
| `SaftUI-Core/EditMode/Bar/barchanges.lua`, `historylist.lua` (new) | Undo, Redo, History, Reset, the status line; the History list | 7 |
| `SaftUI-Unitframes/config/config.lua`, `config/profiles.lua` | Copy from as a step; clearing on a unit frame profile switch | 7 |
| `SaftUI-Core/EditMode/Bar/barwindow.lua` (new) | the floating window | 8 |
| `tests/lib/shell.lua`, `tests/lib/harness_self_test.lua` | the new files in the loaders' lists; `editmode_bar_files()`, `load_editmode_bar()` | 2, 3, 4, 5, 6, 7, 8 |

---

### Task 1: Mover registration data

**Files:**
- Modify: `SaftUI-Core/EditMode/editmode.lua`: `st:RegisterMover`'s and `st:RegisterConfigMover`'s comments, the `defaults` field, and the new readers after `st:RegisterConfigMover`.
- Modify each registration in the table below. Also `SaftUI-Unitframes/unitframes.lua` gains `UF.DefaultUnitConfig`.
- Test: create `tests/core/editmode_movers_test.lua`. Add cases where a world already builds the module's mover: `tests/misc/objective_tracker_position_test.lua`, `tests/misc/theme_test.lua` (it loads `totemposition.lua`), `tests/misc/experience_test.lua`, `tests/chat/screen_margin_test.lua`, `tests/actionbars/layout_test.lua`, and `tests/core/mover_helpers_test.lua` (pass-through).
- Docs: `.agents/edit-mode.md` ("Registering a mover": the code block gains the fields, and a bullet per field with the shown/disabled/hidden line of Ruling 1), `docs/design-system/components/Mover/README.md` ("What the consumer provides"), `.agents/testing.md`, `editmode.lua`'s comments.

**Interfaces:**
- Produces:
  - Definition fields, read by `st:RegisterMover` and passed through by `st:RegisterConfigMover` as its other fields are:
    - `module`: a string, the name the Show list shows for the mover's addon, in sentence case. The seven are `'Action bars'`, `'Bags'`, `'Chat'`, `'Loot'`, `'Minimap'`, `'Misc'` and `'Unit frames'`, and only registrations name them.
    - `isDisabled`: `function() -> boolean`, true when the frame is turned off by a setting.
    - `isHidden`: `function() -> boolean`, true when the frame is on but not on screen now. Read only when `isDisabled` is false.
    - `getDefaultPosition`: `function() -> table | nil`.
    - `noDefaultReason`: a string, why Reset can't run when there is no default.
  - `st:RegisterConfigMover`'s spec takes `defaults`: `function() -> table`, the twin of `config`, holding `position`. It becomes `def.getDefaultPosition = function() local d = defaults(); return d and d.position and st.tablecopy(d.position, true) or nil end`. A spec with both `defaults` and `getDefaultPosition` errors: `'RegisterConfigMover: give defaults or getDefaultPosition, not both'`.
  - `EM.OTHER_MODULE = 'Other'`.
  - `EM:MoverModule(mover) -> string`: `def.module`, or `EM.OTHER_MODULE`.
  - `EM:IsMoverDisabled(mover) -> boolean` and `EM:IsMoverHidden(mover) -> boolean`: the predicate run with `xpcall` to `geterrorhandler()`. No predicate, an error, a secret (`issecretvalue`) or a value that isn't `true` all give `false`.
  - `EM:GetDefaultPosition(mover) -> table | nil`: a fresh deep copy on every call, so a caller's writes never reach `st.defaults`.
  - `UF.DefaultUnitConfig(unit) -> table`: `st.defaults.unitframes.profiles['**'][unit]` when it holds a `position`, else `st.defaults.unitframes.profiles['**']['**']`.

Every registration gets its data. Each `isHidden` and `isDisabled` only reads (`IsShown`, the module's config, a field of Blizzard's), never calls Blizzard code that writes (taint rule 3). Reading `IsShown` on a secure frame is fine. A dash means the field isn't given. The implementer confirms each predicate against the module's own code.

| Mover key | Registered in | `module` | `isDisabled` | `isHidden` | Default |
| --- | --- | --- | --- | --- | --- |
| `ab_bar1`..`ab_bar8`, `ab_pet`, `ab_stance` | `SaftUI-ActionBars/options.lua` `AB:RegisterBarMover` | Action bars | `not AB:GetBarConfig(id).enable` | `not AB:IsBarAvailable(id) or not bar:IsShown()` | `defaults = function() return st.defaults.actionbars[id] end` |
| `ab_extra`, `ab_zone`, `ab_vehicleleave` | `AB:RegisterExtraMover` | Action bars | its enable setting, if it has one | the button its holder holds isn't shown | `st.defaults.actionbars[id]` |
| `bags_<id>` | `SaftUI-Bags/movers.lua` `INV:RegisterMovers` | Bags | — | the window isn't open | `st.defaults.inventory[id]` |
| `chat` | `SaftUI-Chat/chatframe.lua` `CHT:RegisterChatMover` | Chat | — | — | `st.defaults.chat` |
| `lootroll` | `SaftUI-Loot/roll.lua` `LT:RegisterRollMover` | Loot | — | no roll bar shows | `st.defaults.loot.roll` |
| `lootfeed` | `SaftUI-Loot/Feed/feed.lua` | Loot | its enable setting, if it has one | — | `st.defaults.loot.feed` |
| `minimap` | `SaftUI-Minimap/minimap.lua` | Minimap | — | — | `st.defaults.minimap` |
| `micromenu` | `SaftUI-Minimap/micromenu.lua` | Minimap | — | — | `st.defaults.micromenu` |
| `experience` | `SaftUI-Misc/experience.lua` | Misc | — | no bar shows | `getDefaultPosition`: a copy of `st.defaults.experience.position` |
| `totembar` | `SaftUI-Misc/totemposition.lua` | Misc | — | Blizzard's totem bar isn't shown | none; `noDefaultReason = "The totem bar has no default place: SaftUI took its place from Blizzard's Edit Mode."` |
| `objectivetracker` | `Blizzard_ObjectiveTrackerPosition.lua` `OTP:Setup` | Misc | — | the tracker isn't shown | `getDefaultPosition = DefaultPosition` (the file's local) |
| `tooltip` | `SaftUI-Misc/tooltipposition.lua` | Misc | — | — | `st.defaults.tooltip` |
| `auras_<key>` | `Blizzard_BuffFramePosition.lua` `AP:RegisterAuraMover` | Misc | — | — | `st.defaults.auras[key]` |
| `swingtimer_<key>` | `Blizzard_SwingTimerPosition.lua` `STP:RegisterBarMover` | Misc | Blizzard's saved visibility is Hidden (the read `STP:UpdateMoverLabel` makes) | — | `st.defaults.swingtimer[key]` |
| `uf_<unit>`, `uf_<group>` | `SaftUI-Unitframes/unitframes.lua` `UF:RegisterMovers` | Unit frames | `not UF:GetProfileConfig()[unit].enable` | the unit's frame, or the group's header, isn't shown (test mode previews count as shown) | `defaults = function() return UF.DefaultUnitConfig(unit) end` |

- [ ] **Step 1: Write the failing tests** in `tests/core/editmode_movers_test.lua` (world: `load_core_helpers()`, `load_editmode()`, `local T = load_test_file('lib/theme_helpers.lua')`; a local `add_mover(key, extra)` as `theme_blizzard_editmode_test.lua` has it, through `st:RegisterConfigMover`)

```lua
test('RegisterConfigMover passes module, the predicates and noDefaultReason through; defaults gives a fresh copy', function()
	local defaults = { position = { point = 'TOP', frame = 'UIParent', rel_point = 'TOP', x_off = 0, y_off = -40 } }
	local mover = add_mover('m1', { module = 'Chat', isHidden = function() return true end,
		defaults = function() return defaults end })
	eq(EM:MoverModule(mover), 'Chat', 'module')
	eq(EM:IsMoverHidden(mover), true, 'isHidden')
	local copy = EM:GetDefaultPosition(mover)
	eq(copy.y_off, -40, 'the default position')
	copy.y_off = 99
	eq(defaults.position.y_off, -40, 'a write into the copy never reaches the defaults')
	check(EM:GetDefaultPosition(mover) ~= copy, 'a new copy each call')
end)

test("a mover without a module is Other; a missing, failing, secret or non-boolean predicate is false", function()
	-- add_mover('m2'): MoverModule 'Other', IsMoverDisabled false, GetDefaultPosition nil
	-- isDisabled erroring: false, #take_errors() == 1
	-- isHidden returning S.secret('shown') (tests/lib/secrets.lua, S.install()): false, no error
	-- isHidden returning 1: false
	-- RegisterConfigMover with defaults and getDefaultPosition both: an error naming both
end)

test('every mover SaftUI registers names one of the seven modules, and a default or the reason it has none', function()
	-- For every file in T.saftui_files() but SaftUI-Core/EditMode/editmode.lua: each st:RegisterMover( and
	-- st:RegisterConfigMover( call, its text up to the first line that is only `})` after it, holds
	-- `module = '<name>'` with <name> one of this test's own list (Core has none), and one of
	-- `defaults =`, `getDefaultPosition =` or `noDefaultReason =`. Message names file and line.
	-- At least 15 call sites are found (a scan that finds none must fail).
end)
```

In the module worlds:
- `objective_tracker_position_test.lua`: the `objectivetracker` mover's `EM:GetDefaultPosition` equals `DefaultPosition()`'s values, `x_off = -st.CLAMP_INSET`, with `y_off` -275 on Forever and -260 on retail.
- `theme_test.lua` (the totem bar): `EM:GetDefaultPosition` is nil, and `def.noDefaultReason` is the table's text.
- `experience_test.lua`: the default position is a copy of `st.defaults.experience.position`.
- `screen_margin_test.lua` (chat): the module is `Chat`, and the default is a copy of `st.defaults.chat.position`.
- `layout_test.lua`: bar 2's `IsMoverDisabled` follows its `enable`, and the pet bar is hidden while `IsBarAvailable` is false.
- `mover_helpers_test.lua`: the new fields pass through `st:RegisterConfigMover`, and `getDefaultPosition` is made from `defaults`.

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/editmode_movers_test.lua`
Expected: FAIL: `EM:MoverModule` is nil.

- [ ] **Step 3: Implement the Core side** in `editmode.lua`: the conversion, the assert and the readers, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core/editmode_movers_test.lua tests/core/mover_helpers_test.lua`. Expected: the first two cases PASS, and the scan FAILs, naming every call site.

- [ ] **Step 5: Give each registration its data** as the table says. Use the existing readers each module already has: no new state, and no module code changed beyond the registration and `UF.DefaultUnitConfig`.

- [ ] **Step 6: Run** the addon tests the step touched, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 7: Docs** as listed under Files.

- [ ] **Step 8: Commit**

```bash
git add SaftUI-Core/EditMode/editmode.lua SaftUI-ActionBars/options.lua SaftUI-Bags/movers.lua SaftUI-Chat/chatframe.lua SaftUI-Loot/roll.lua SaftUI-Loot/Feed/feed.lua SaftUI-Minimap/minimap.lua SaftUI-Minimap/micromenu.lua SaftUI-Misc/experience.lua SaftUI-Misc/tooltipposition.lua SaftUI-Misc/totemposition.lua SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimerPosition.lua SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua SaftUI-Unitframes/unitframes.lua tests/core/editmode_movers_test.lua <each addon test changed> .agents/edit-mode.md .agents/testing.md docs/design-system/components/Mover/README.md
git commit -m "core: give every mover its module, its disabled and hidden checks, and its default place"
```

**In-game checks:** nothing should look different. On both clients, log in with no Lua errors (BugGrabber). Then turn edit mode on: every mover shows as before, and dragging, nudging and `/sui`'s Position work on a unit frame, a bar, chat and the objective tracker.

---

### Task 2: Kit controls and icons

**Files:**
- Create: `SaftUI-Core/Config/optionscontrols.lua`, listed in `SaftUI-Core/Config/load.xml` after `optionsitem.lua` and before `optionsposition.lua`, and in `options_widget_files()` (`tests/lib/shell.lua`) in the same place.
- Modify: `SaftUI-Core/Config/optionsposition.lua`: `PaintNudge`, `NudgeButton`, `NudgePair` and `LookNudges` move into the new file, and `builders.position` and `define('position')`'s `Bind` call the kit's.
- Modify: `SaftUI-Core/Config/optionslist.lua`: `W.OpenCheckList` gains `buttons`.
- Modify: `SaftUI-Core/Config/optionswindow.lua`: the local `Button` goes, `W.Button` takes its place, and `S.Button = W.Button`.
- Modify: `SaftUI-Core/constants.lua` (`st.icons`). Create the 14 TGAs under `SaftUI-Core/Media/Textures/` with `NODE_PATH=... node tools/lucide-to-tga.cjs log-out grid-3x3 magnet align-start-vertical layers map-pin eye power-off search undo-2 redo-2 history picture-in-picture-2 panel-top`.
- Test: create `tests/core/options_controls_test.lua`, on `tests/core/options_widgets_helpers.lua`'s world. Modify `tests/core/icons_test.lua` (`NAMES`), `tests/core/options_position_test.lua` (the arrow assertions at lines 99 to 108 become the chevron's texture, size and offsets), `tests/core/options_list_test.lua` (the check list's buttons) and `tests/lib/shell.lua`.
- Docs: `.agents/edit-mode.md` (`covers:` gains `optionscontrols.lua`; the widgets paragraphs gain the standalone controls, the nudges' chevrons and the check list's buttons; the file count of `st.OptionsWidgets`), `.agents/testing.md`, and the design system's `components/Button/README.md` (the icon button; "on" and disabled on the bar). Also `components/Icons/README.md` (the new icons and what uses them; the nudges leave "To replace"), `components/CheckList/README.md` (All and None) and `components/PositionBlock/README.md` (the chevrons).

**Interfaces:**
- Produces (all in `optionscontrols.lua` unless said):
  - `W.Button(parent, label, onClick, opts) -> button`: the window's former local, with the same look and size. Its text comes through `Kit.NewText`, since `OB` loads after the widgets, with word wrap off. It is a Box in `st.BOX_COLORS.bg`, `button.text` in the field font, centred, `max(80, text + 28)` x 26. Its edge is accent under the mouse, and its label moves 1 down while pressed. `opts` is optional:
    - `icon`: a texture path. `iconWithLabel = true` draws it (16) before the label, 6 apart, the pair centred, with width `max(80, 16 + 6 + text + 28)`;
    - `tip`: `function(button) -> title, lines`.
  - `W.IconButton(parent, icon, tip) -> button`: 26 x 26, with `button.icon` a 16 x 16 texture of `icon` centred (its edges at 5 and 21) in Text > Grey. `tip` is required: without it, `error('W.IconButton needs its tooltip')`.
  - `W.IconLink(parent, icon, size, tip) -> link`: an icon with no box, on a frame `size` square that takes the mouse. It is Text > Grey at rest and accent under the mouse, and `tip` is required.
  - `W.SetCompact(button, compact) -> width`: a `W.Button` with an `icon` shows only that icon, 26 x 26, while compact (it needs `opts.tip`), and its label otherwise.
  - `W.SetOn(button, on)`, which sets `button.on`:
    - under Thick and Thin, the accent edge, kept when the mouse leaves, and the icon in accent;
    - under Blizzard, the icon in accent, or a text button's label in accent (it has no lit state).
  - `W.SetEnabled(control, enabled)`, which sets `control.disabled`: disabled is alpha 0.4, no hover edge, and a click that runs nothing. The control keeps the mouse, so its tooltip shows (Ruling 12). It works on every control in this file, and a `W.NumberBox`'s edit box also drops focus and stops taking text.
  - `W.LookControl(control, blizzard)`: puts on `W.LookButton(control, blizzard, st.BOX_COLORS.bg)`, then its `on` and `disabled` again. An icon is drawn in `OVERLAY`, over Blizzard's panel button art.
  - `W.ShowTip(owner, title, lines, anchor)`: `GameTooltip:SetOwner(owner, anchor or 'ANCHOR_BOTTOM')`, the title in white, and each line Text > Normal (design decision 8). A line given as `{ text = ..., red = true }` is Text > Red. `W.HideTip(owner)` hides it if `owner` owns it. The controls show their `tip` on `OnEnter` through a script that takes `(self)` only.
  - `W.SelectFace(parent, width, onClick) -> face`: a `FIELD_HEIGHT` (24) tall Box button with `face.text` (8 in from the left, -22 from the right) and `Kit.Caret`, through `W.DropdownStates`. Its `OnHide` closes a list it owns. `W.LookSelectFace(face, blizzard)` is `W.LookDropdown(face, blizzard, false)`.
  - `Kit.NudgePair(owner, parent, onUp, onDown) -> pair, up, down`: today's pair, 14 x 22 with its divider, reading `owner.disabled` and calling `owner:Tip(on)` as the position widget does. Each half's arrow is now one texture, `button.arrow` (which replaces `button.arrows`): `st.icons.chevronUp` or `chevronDown`, 12 x 12, on a whole-pixel offset so the glyph's middle sits where today's three rows do. It is Text > Grey, and Text > Normal under the mouse while enabled. `Kit.LookNudges(pairs, blizzard)` is today's `LookNudges` over a list of pairs: Blizzard's `MinimalScrollBar` steppers, with the chevron hidden.
  - `W.NumberBox(parent, opts) -> box`: `opts = { width = 54, min, max, step, get = function() -> number, set = function(number), tip = function(box) -> title, lines }`.
    - `box.edit` is a `width - 13` x 22 edit box with centred text in the field font. `box.pair` overlaps its right edge by 1.
    - Enter commits `floor(n + 0.5)` clamped to min and max, and drops focus. A value that isn't a number puts the old one back, and so do Esc and losing focus.
    - The arrows call `set(clamp(get() +/- step))`.
    - `box:Refresh()` shows `get()`. `W.LookNumberBox(box, blizzard)` puts on `Kit.LookInput(box.edit, blizzard, 22)` and the nudges' look.
  - `W.OpenCheckList(owner, entries, isChecked, onToggle, buttons)` (`optionslist.lua`): `buttons` is optional, `{ { label = 'All', onClick = fn }, ... }`. The buttons are drawn as the Apply list's button: 80 x `FIELD_HEIGHT`, 6 apart, centred, 6 under the rows, through `W.LookButton` under Blizzard. A click runs `onClick` and draws the marks again, and the list stays open. The list is at least `#buttons * 80 + (#buttons - 1) * 6` plus its insets wide. Without buttons it is as today.
  - `st.icons`: `logOut`, `grid3x3`, `magnet`, `alignStartVertical`, `layers`, `mapPin`, `eye`, `powerOff`, `search`, `undo2`, `redo2`, `history`, `pictureInPicture2` and `panelTop`, each `st:TexturePath('lucide-<name>.tga')`.

- [ ] **Step 1: Write the failing tests** in `tests/core/options_controls_test.lua` (`local P = load_test_file('lib/pixels.lua')`; the GameTooltip stub as `options_frame_test.lua` makes it)

```lua
test("W.Button is the window's button: 26 tall, 80 at least, the field font, an accent edge under the mouse", function()
	local b = W.Button(UIParent, 'Reload UI', function() end)
	eq(b:GetHeight(), 26, '26 tall')
	eq(b:GetWidth(), math.max(80, math.ceil(b.text:GetStringWidth()) + 28), 'the text and 28, 80 at least')
	stub.fire_script(b, 'OnEnter', true)
	-- the border is Colors().button.blue; OnLeave: st.BOX_COLORS.edge
end)

test('W.IconButton: a 26 square with its 16 icon in the middle, grey; it needs its tooltip', function()
	-- icon 16x16, CENTER on the button; vertex color Text > Grey; P.off(button) empty
	-- W.IconButton(UIParent, st.icons.magnet) errors 'W.IconButton needs its tooltip'
	-- OnEnter(true): GameTooltip owned by it, anchored ANCHOR_BOTTOM, title white, a line in Text > Normal
end)

test('W.SetOn: an accent edge that stays after the mouse leaves and an accent icon; under Blizzard the icon (or label) alone', function()
	-- Thick: on -> edge blue, icon blue; OnEnter(true)/OnLeave(true): still blue; off -> edge, icon grey
	-- theme blizzard, W.LookControl(b, true): panel button art shown (st:ShowPanelButton), icon blue when on
	-- a W.Button 'Edit mode' on under Blizzard: its label Colors().button.blue
end)

test('W.SetEnabled: a disabled control at 0.4 runs no click and still shows its tooltip', function()
	-- clicked counter stays 0 after stub.click; OnEnter(true) shows the tip; no blue edge
end)

test('W.SetCompact: a button with an icon drops its label for a 26 square', function()
	-- W.Button(UIParent, 'Exit', fn, { icon = st.icons.logOut, iconWithLabel = true, tip = tip }):
	-- the icon 16 left of the label, the pair centred, width >= 80; SetCompact(b, true) -> 26, label hidden
end)

test('W.NumberBox: typed whole numbers clamped, Esc and focus loss put the old one back, the arrows step', function()
	local value = 32
	local box = W.NumberBox(UIParent, { width = 54, min = 8, max = 128, step = 4,
		get = function() return value end, set = function(v) value = v end, tip = function() return 'Grid size', {} end })
	eq(box:GetWidth(), 54, '54 wide, the pair inside it')
	box.edit:SetText('30.6'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 31, 'a whole number')
	box.edit:SetText('500'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 128, 'clamped')
	box.edit:SetText('abc'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 128, 'not a number: unchanged'); eq(box.edit:GetText(), '128', 'and shown again')
	-- OnEscapePressed after typing '9': value unchanged, text '128'; stub.click(box.pair.down): 124
	-- W.SetEnabled(box, false): a click on up changes nothing; the edit box takes no focus
end)

test('the nudge pair draws Lucide chevrons, on whole pixels, and Blizzard steppers under Blizzard', function()
	-- up.arrow:GetTexture() == st.icons.chevronUp, 12x12; down.arrow chevronDown; P.off(pair) empty
	-- Kit.LookNudges({ pair }, true): 'minimal-scrollbar-arrow-top' on up, chevrons hidden
end)

test('W.SelectFace: the dropdown face with its caret; under Blizzard the Settings dropdown', function()
	-- 150 wide, 24 tall, Kit.Caret texture st.icons.chevronDown; hiding it closes a list it owns
end)
```

In `options_list_test.lua`:

```lua
test('a check list with buttons: All and None under the rows, each applying at once and leaving it open', function()
	-- W.OpenCheckList(owner, { a, b, c }, isChecked, onToggle, { { label = 'All', onClick = all }, { label = 'None', onClick = none } })
	-- two buttons 80 wide, 6 apart, centred under the rows; the list >= 166 + insets wide;
	-- click All: all() ran, every box marked, W.ListOwner() == owner; Esc closes; without buttons none show
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/options_controls_test.lua tests/core/options_list_test.lua`
Expected: FAIL: `W.Button` is nil.

- [ ] **Step 3: Make the icons** (the tool's comment says how), register them, and add them to `icons_test.lua`'s `NAMES`.

- [ ] **Step 4: Implement** the file, the check list's buttons, and the moves out of `optionsposition.lua` and `optionswindow.lua`, as the Interfaces say. The position block keeps its 14 x 22 pairs and their place.

- [ ] **Step 5: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS, after the position test's arrow assertions are changed to the chevrons. Every other window and position test passes unchanged, which shows the lift kept the look.

- [ ] **Step 6: Docs** as listed under Files.

- [ ] **Step 7: Commit**

```bash
git add SaftUI-Core/Config/optionscontrols.lua SaftUI-Core/Config/load.xml SaftUI-Core/Config/optionsposition.lua SaftUI-Core/Config/optionslist.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/constants.lua SaftUI-Core/Media/Textures/lucide-log-out.tga <the other 13 lucide-*.tga> tests/core/options_controls_test.lua tests/core/icons_test.lua tests/core/options_position_test.lua tests/core/options_list_test.lua tests/lib/shell.lua .agents/edit-mode.md .agents/testing.md docs/design-system/components/Button/README.md docs/design-system/components/Icons/README.md docs/design-system/components/CheckList/README.md docs/design-system/components/PositionBlock/README.md
git commit -m "core: add the kit's standalone controls, its icon button and the edit mode bar's icons"
```

**In-game checks:**
- `/sui` looks as before: Reload UI, Close and the sidebar's buttons are unchanged.
- In any Position block, the X and Y nudges show small chevrons, crisp, not blurred, at your UI scale. They still nudge by 1, and they light under the mouse.
- Under the Blizzard theme they are Blizzard's scroll arrows, as before.
- Check both clients.

---

### Task 3: The docked bar; `/sui`'s footer cleared

**Files:**
- Delete: `SaftUI-Core/EditMode/footer.lua`.
- Create: `SaftUI-Core/EditMode/Bar/load.xml` (`bar.lua`, `bargroups.lua`), `Bar/bar.lua` (the frame, the group list, the layout and the events) and `Bar/bargroups.lua` (the Exit, grid and options groups).
- Modify: `SaftUI-Core/EditMode/load.xml`: `footer.lua` out, and `<Include file="Bar\load.xml"/>` last.
- Modify: `editmode.lua`: the "Edit mode on." and "Edit mode off." prints go, and `EM:UpdateConfig` fires `SettingsChanged` in place of `UpdateFooterToggles`.
- Modify: `mover.lua`: the events, `EM.MoverName`, and `EM:OnColorsChanged` firing `ColorsChanged`.
- Modify: `picker.lua`: its local `Name` is `EM.MoverName`.
- Modify: `grid.lua`: it redraws on `SettingsChanged`.
- Modify: `settings.lua`: the footer half goes; it gains `EM:SetSetting` and `EM:SetGridSize`, and the Edit mode tab's set goes through `EM:SetSetting`, with Grid size's desc "The gap between the grid's lines. The bar's arrows change it too."
- Modify: `SaftUI-Core/Config/optionswindow.lua` (`OW:GetFooter`, `OW:SetFooterInset`, `footerInset` and both `UpdateFooter` calls go, along with the header lines about them), `optionslayout.lua` (`OW.FooterPlace` loses its inset) and `optionsnav.lua` (`UpdateEditModeButton` uses `W.SetOn`).
- Modify: `tests/lib/shell.lua` (`editmode_files()` loses `footer.lua`; new `editmode_bar_files()` and `load_editmode_bar()`) and `tests/lib/harness_self_test.lua` (`editmode_bar_files()` against `Bar/load.xml`, and `EditMode/load.xml` including it last).
- Test: create `tests/core/editmode_bar_test.lua`.
- Modify tests:
  - `tests/core/options_frame_test.lua`: delete the three edit mode footer cases (lines 283 to 325, 438 to 490 and 492 to 522); drop the inset halves of the validate-error and leave-the-page cases and the edit mode half of the frame-level case; read the region as `frames().footerRegion`.
  - `tests/core/editmode_grid_test.lua`: its header, the `StepGridSize` case without the footer, and a `SetGridSize` case.
  - `tests/core/options_window_look_test.lua:316` and `tests/unitframes/profile_footer_test.lua:143`: `frames().footerRegion`.
- Docs:
  - `.agents/edit-mode.md`: the footer bullet becomes the bar bullet; the window's Footer bullet loses the region API; the footer control's paragraph loses the inset; the Edit mode tab.
  - `.agents/testing.md`; root `README.md` line 29 (the bar, not the footer); `docs/design-system/components/Mover/README.md` and `Button/README.md` (the footer example becomes history); `docs/design-system/05-decisions.md` needs nothing.
  - The header comments of every file touched.

**Interfaces:**
- Consumes: `W.Button`, `W.IconButton`, `W.SetOn`, `W.SetEnabled`, `W.SetCompact`, `W.LookControl`, `W.ShowTip`, `W.NumberBox`, `W.LookNumberBox`, and `st.icons.logOut`, `grid3x3`, `magnet`, `alignStartVertical` and `settings` (Task 2).
- Produces:
  - `EM.MIN_GRID_SIZE, EM.MAX_GRID_SIZE, EM.GRID_STEP = 8, 128, 4` (`settings.lua`).
  - `EM:SetSetting(key, value)`: it writes `EM:GetSettings()[key]`, with `grid_size` clamped to a whole number from 8 to 128. Then `EM:Fire('SettingsChanged', key)` and `st.Config:Refresh()`.
  - `EM:SetGridSize(n)` is `EM:SetSetting('grid_size', n)`. `EM:StepGridSize(delta)` stays.
  - Events, with `EM:On`:
    - `'SettingsChanged'`, carrying `key`, or nil for all of them (a profile change);
    - `'Pressed'`, with the mover (the overlay's `OnMouseDown`);
    - `'DragStarted'` and `'DragStopped'`, with the mover (`EM:StartDrag`, and `EM:StopDrag` or a drag dropped by `EM:UpdateConfig`);
    - `'ColorsChanged'`, with the group (from `EM:OnColorsChanged` for every group).
  - `EM.MoverName(mover) -> string` (`mover.lua`): the label's first line, else the key.
  - `EM:IsBlizzardEditModeOpen() -> boolean` (`bar.lua`): `_G.EditModeManagerFrame ~= nil and EditModeManagerFrame:IsShown() == true`.
  - `EM.BAR = { HEIGHT = 40, PAD = 10, GAP = 4, GROUP_PAD = 8, FLEX_MIN = 12, LEVEL = 9500, DRAG_ALPHA = 0.25, STAGES = 6 }` (`bar.lua`).
  - `EM:AddBarGroup(group)`, called at file load by the groups' files. `group` is `{ key, order, side = 'left' | 'right', section = 'title' | 'grid' | 'show' | 'changes', controls = function(parent) -> { control, ... } }`. The `section` is the floating window's (Task 8).
  - A control is `{ key, frame, Lay = function(control, stage, floating) -> width, Refresh = function(control) | nil, section = <overrides the group's> | nil, align = 'right' | nil }`. `Lay` lays the control out for the stage and returns its width, where 0 means not shown. The stages give way cumulatively: 1 shrinks the filter box to 100; 2 hides the Show caption; 3 shrinks the Show face to 110; 4 makes Exit and Options compact; 5 hides the filter box.
  - `EM.BarLayout(width, groups) -> xs, dividers, fits`. It is pure. `groups` is `{ { side, widths = { w, ... } }, ... }` in order, and a width of 0 is skipped (a group with none is skipped whole). It returns `xs[g][c]`, each control's x from the bar's left, whole; `dividers`, a list of x; and `fits`.
    - The left groups run from `PAD`, the controls `GAP` apart, with `GROUP_PAD`, a 1px divider and `GROUP_PAD` between groups.
    - The right groups end at `width - PAD`, and the first of them has a divider at its left.
    - `fits` is true when the left end plus `FLEX_MIN` is at most the divider before the right groups.
  - `EM:GetBar() -> frame` (built once, on first use), `EM:LayoutBar() -> stage` (the first stage that fits, else the last), `EM:BarWidthAt(stage) -> number`, `EM:RefreshBar()` and `EM:BarControl(key) -> control`.
  - Groups and their control keys: `'exit'` (left, order 10, section `'title'`) holds `exit`. `'grid'` (left, order 20, section `'grid'`) holds `grid`, `gridSize`, `snapGrid` and `snapFrames`; Task 4 adds `dim` and `coordinates`. `'options'` (right, order 90, section `'changes'`) holds `options` (align right); Task 8 adds `detach`.
  - `OW.FooterPlace(regionWidth, labelWidth, widgetsWidth) -> x, labelShown` (`optionslayout.lua`). It is centred while the control fits, and at the right end without its label otherwise.
  - Shell: `editmode_bar_files()` returns `Bar/load.xml`'s files in order. `load_editmode_bar()` loads them; load the options window's world (`tests/core/options_window_helpers.lua`) first.

**The bar.**
- **Frame and look:**
  - A `st:CreateFrame('Frame', nil, UIParent)` at `FULLSCREEN_DIALOG` level `EM.BAR.LEVEL`, `TOPLEFT`/`TOPRIGHT` on UIParent, `HEIGHT` tall, `EnableMouse(false)`.
  - It is drawn with `st:SetBackdrop(bar, 'theme', 'theme', 'panel')`. Its backdrop already sits the theme's inset outside the frame, so with the frame flush at the screen's top, left and right only its bottom line shows.
  - Controls are children at `bar:GetFrameLevel() + 2`, vertically centred on whole pixels: y -7 for 26, -8 for 24, -9 for 22. Dividers are 1 x 26 textures in `OB.HAIRLINE`, kept under Blizzard.
- **When it lays out again:** the width is read as `OB.WholeHeight(bar:GetWidth())`. It lays out on `UI_SCALE_CHANGED`, on `DISPLAY_SIZE_CHANGED` (its own frame's events) and on its own `OnSizeChanged`.
- **Show, hide and drags:** it shows on `Enabled` (lay out, refresh, show) and hides on `Disabled`. On `DragStarted` it goes to `DRAG_ALPHA` and every control takes no mouse; on `DragStopped` it comes back.
- **Looks and refresh:** on `SettingsChanged` and `ColorsChanged` it runs `EM:RefreshBar()`, which puts on every control's `W.LookControl` for `W.BlizzardLook()` and runs its `Refresh`.
- **Combat:** every control's click returns at once when `InCombatLockdown()`.

**The controls.**
- Tooltips sit under the control, through `W.ShowTip`, in the spec's wording (its sections 1 to 5 and 14), which may be tuned.
- The constructors below are written without their parent (the bar), their `onClick` (the "Does" column) and their `tip`.
- An icon toggle's tooltip is the spec's title and line. An icon toggle's `Refresh` runs `W.SetOn(control.frame, settings[key])`.

| Key | Control | Does | State |
| --- | --- | --- | --- |
| `exit` | `W.Button('Exit', { icon = st.icons.logOut, iconWithLabel = true })`, compact at stage 4 | `EM:Deactivate()` | Tooltip "Exit", "Turns edit mode off. Your moves are already saved."; while `EM:IsBlizzardEditModeOpen()` also "Blizzard's Edit Mode stays open; close it with its own button." |
| `grid` | `W.IconButton(st.icons.grid3x3)` | `EM:SetSetting('grid', not grid)` | on = `grid` |
| `gridSize` | `W.NumberBox` 54, 8..128, step 4, set `EM:SetGridSize` | — | enabled while `grid` or `snap_grid`; disabled tip adds red "Turn on Grid or Snap to grid to use it." |
| `snapGrid` | `W.IconButton(st.icons.magnet)` | toggles `snap_grid` | on = `snap_grid` |
| `snapFrames` | `W.IconButton(st.icons.alignStartVertical)` | toggles `snap_frames` | on = `snap_frames` |
| `options` | `W.Button('Options', { icon = st.icons.settings })`, compact at stage 4 | `EM:ShowSettings(EM.selected)`, or `st.Config:Open('Fonts', 'editmode')` with none | Tooltip "Options", "Opens <name>'s page in /sui." or "Opens edit mode's settings in /sui." |

**The `/sui` side.**
- The sidebar's Edit mode button is `W.SetOn(button, EM.active)`, never green.
- `/sui`'s footer holds Reload UI, the status line from the region's left, the page's footer control centred, and Close.
- `PlaceFooter` keeps its hide branch as a guard for a region narrower than the control.
- The Edit mode tab keeps its rows, its set calling `EM:SetSetting(info[#info], value)`.

- [ ] **Step 1: Write the failing tests** in `tests/core/editmode_bar_test.lua` (world: `local H = load_test_file('core/options_window_helpers.lua')`, `load_editmode_bar()`, `local P = load_test_file('lib/pixels.lua')`, `local T = load_test_file('lib/theme_helpers.lua')`; `EM:Enable()` once; a local `add_mover` as Task 1's test; screens set as `editmode_grid_test.lua`'s `set_screen`)

```lua
test('the bar shows while edit mode is on, with /sui open or closed, and hides when it turns off', function()
	EM:Activate()
	local bar = EM:GetBar()
	check(bar:IsShown(), 'on, /sui closed: shown')
	st.Config:Open('Loot'); check(bar:IsShown(), '/sui open: still shown'); H.close_all()
	EM:Deactivate(); check(not bar:IsShown(), 'off: hidden')
end)

test('across the top, 40 tall, drawn as a panel in the theme; the bar itself takes no mouse, its controls do', function()
	EM:Activate()
	local bar = EM:GetBar()
	eq(bar:GetHeight(), 40, '40 tall'); eq(bar:GetTop(), UIParent:GetTop(), 'at the top'); eq(bar:GetWidth(), UIParent:GetWidth(), 'full width')
	eq(st:DrawnKind(bar), 'panel', 'a panel')
	check(not bar:IsMouseEnabled(), 'a click between controls reaches the mover under it')
	check(EM:BarControl('grid').frame:IsMouseEnabled(), 'the controls take it')
	eq(bar:GetFrameStrata() .. bar:GetFrameLevel(), 'FULLSCREEN_DIALOG9500', 'over the movers and /sui')
	EM:Deactivate()
end)

test('Grid, Snap to grid and Snap to frames toggle their settings, show on in the accent, and are saved in the profile', function()
	-- stub.click(grid.frame): settings.grid true, grid.frame.on true, EM.gridFrame shown; again: off
	-- the same for snapGrid -> snap_grid, snapFrames -> snap_frames; st.config.profile.editmode holds each
end)

test('Grid size: the arrows step by 4 within 8 to 128, any whole size can be typed, and it is off while Grid and Snap to grid are', function()
	-- 32 up -> 36; typed '30' -> 30, the grid redraws (a line at cx + 30); '7' -> 8; '200' -> 128
	-- grid and snap_grid off: gridSize.frame.disabled, its tooltip's last line red 'Turn on Grid or Snap to grid to use it.'
	-- an open /sui's Grid size slider shows the new value after a render (st.Config:Refresh)
end)

test('Exit turns edit mode off; with Blizzard Edit Mode open its tooltip says that one stays open', function()
	-- _G.EditModeManagerFrame = CreateFrame('Frame'): shown -> the tooltip's third line; stub.click(exit.frame): EM.active false
end)

test('Options opens the selected mover\'s page, or Global Settings > Edit mode with none selected', function()
	-- none: OW:GetState().page == 'Fonts', tab 'editmode'; EM:Select(mover with configPath { 'Loot', 'roll', 'general' }): the Loot page
end)

test('the bar fades and takes no mouse while a mover is dragged', function()
	-- EM:StartDrag(m): bar alpha 0.25, no control mouse-enabled; EM:StopDrag(m): alpha 1, controls again
end)

test('in combat the bar hides with edit mode and its buttons do nothing', function()
	-- Activate, stub.fire_event('PLAYER_REGEN_DISABLED'): bar hidden; stub.in_combat = true, stub.click(grid.frame): grid unchanged
end)

test('turning edit mode on or off prints nothing; the combat refusal still does', function()
	-- printed(EM:Activate) == '' and printed(EM:Deactivate) == ''; in combat Activate prints "Can't open edit mode in combat."
end)

test('a narrow screen gives way in order: the filter, the caption, the face, then Exit and Options lose their words', function()
	-- EM.BarLayout on synthetic groups: { left 80 } { left 26, 54 } { right 26, 26 }: xs and dividers whole,
	--   left from 10, controls 4 apart, 8 + 1 + 8 between groups, a divider before the first right group, fits iff gap >= 12
	-- the real bar: width EM:BarWidthAt(0) -> stage 0; one less than that -> stage >= 1;
	--   less than EM:BarWidthAt(3) -> stage 4: exit and options 26 wide, their labels hidden, their tooltips name them
end)

test('every piece of the bar sits on whole pixels, at any screen, with the game\'s read-back noise, and after a UI scale change', function()
	-- for 1920x1080, 1366x768, 1024x768, 800x600: set_screen, stub.size_noise = 2 ^ -14, EM:Activate():
	--   #P.off(EM:GetBar()) == 0 (P.report in the message); then UIParent:SetScale(0.71),
	--   stub.fire_event('UI_SCALE_CHANGED'): laid out again, still none off; stub.size_noise = 0 after
end)

test('hover with the game\'s motion argument shows each control\'s tooltip under it', function()
	-- for each control: stub.fire_script(frame, 'OnEnter', true): GameTooltip owned by frame, ANCHOR_BOTTOM; OnLeave(true) hides it
end)

test("under Blizzard, on both clients: the panel's art, Blizzard's panel buttons, the icons in accent when on, the box's art", function()
	-- for client in forever, retail (T.client): theme blizzard, EM:Activate(): T.art(bar) is the panel kind's Blizzard art;
	-- exit and options wear st:ShowPanelButton's art; grid on: icon blue, no blue edge; gridSize: InputBoxTemplate pieces and
	-- 'minimal-scrollbar-arrow-top'; dividers still shown; back to Thick: Box edges again
end)

test("/sui's footer: Reload UI, the status line from the left, the page's control centred, Close; no edit mode buttons", function()
	-- OW.GetFooter == nil and OW.SetFooterInset == nil; EM:Activate() with /sui on Unitframes: the control centred
	-- (from_left == from_right within 1), status from the region's left; OW.FooterPlace(400, 60, 200) == 70, true;
	-- OW.FooterPlace(200, 60, 180) == 20, false
end)

test("the sidebar's Edit mode button is on in the accent while edit mode is, never green", function()
	-- frames().actions[1].on true while EM.active; its text never Colors().text.green; under Blizzard its label blue
end)
```

- [ ] **Step 2: Run them to see them fail**

Run: `tests/run tests/core/editmode_bar_test.lua`
Expected: FAIL: `load_editmode_bar` is nil.

- [ ] **Step 3: Implement** the shell's lists and the self test, then `bar.lua`, `bargroups.lua`, the events, the settings and the `/sui` side, as the Interfaces say.

- [ ] **Step 4: Update the existing tests** under Files so each keeps its meaning. Delete the edit mode footer cases. Read the region as `frames().footerRegion`.

- [ ] **Step 5: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 6: Docs** as listed under Files. `.agents/edit-mode.md` describes:
  - the bar, its groups and controls, the stages, and its strata and level;
  - the events;
  - `EM:SetSetting`;
  - the footer as it is now.

- [ ] **Step 7: Commit**

```bash
git rm SaftUI-Core/EditMode/footer.lua
git add SaftUI-Core/EditMode/Bar/load.xml SaftUI-Core/EditMode/Bar/bar.lua SaftUI-Core/EditMode/Bar/bargroups.lua SaftUI-Core/EditMode/load.xml SaftUI-Core/EditMode/editmode.lua SaftUI-Core/EditMode/mover.lua SaftUI-Core/EditMode/picker.lua SaftUI-Core/EditMode/grid.lua SaftUI-Core/EditMode/settings.lua SaftUI-Core/Config/optionswindow.lua SaftUI-Core/Config/optionslayout.lua SaftUI-Core/Config/optionsnav.lua tests/lib/shell.lua tests/lib/harness_self_test.lua tests/core/editmode_bar_test.lua tests/core/options_frame_test.lua tests/core/editmode_grid_test.lua tests/core/options_window_look_test.lua tests/unitframes/profile_footer_test.lua .agents/edit-mode.md .agents/testing.md README.md docs/design-system/components/Mover/README.md docs/design-system/components/Button/README.md
git commit -m "core: move edit mode's controls from the /sui footer to a bar across the top of the screen"
```

**In-game checks:**
- `/sui edit`: the bar shows across the top with `/sui` closed and with it open, crisp at your UI scale, its bottom line only. Grid, Snap to grid and Snap to frames light in the accent. The Grid size arrows step by 4, and typing 30 and Enter gives a grid of 30. The box dims with Grid and Snap to grid both off.
- Click in the gap before Options on a mover under the bar (the micro menu, the minimap's top): it selects. Drag a frame up under the bar: the bar fades and the frame shows through.
- Exit leaves edit mode. Options opens the selected frame's page, or Global Settings > Edit mode.
- `/sui`'s footer has no edit mode buttons, and the Unitframes profile control is centred.
- The sidebar's Edit mode button lights in the accent, not green.
- Blizzard's Edit Mode: the bar shows with it, and Exit's tooltip says it stays open.
- A reload keeps every choice.
- Under the Blizzard theme, on both clients, the buttons are Blizzard's.

---

### Task 4: Dim world and Coordinates

**Files:**
- Create: `SaftUI-Core/EditMode/coordinates.lua`, in `EditMode/load.xml` after `settings.lua` and in `editmode_files()`.
- Modify: `grid.lua` (the dim layer), `Bar/bargroups.lua` (`dim` and `coordinates` in the grid group), `settings.lua` (Dim world and Coordinates rows on the Edit mode tab) and `SaftUI-Core/Config/defaults.lua` (`dim = true`, `coordinates = false`).
- Test: create `tests/core/editmode_coordinates_test.lua`. Add the dim cases to `tests/core/editmode_grid_test.lua` and the two toggles to `tests/core/editmode_bar_test.lua`.
- Docs: `.agents/edit-mode.md` (the grid bullet gains the dim; a Coordinates bullet), `.agents/testing.md` and `README.md` line 29.

**Interfaces:**
- Consumes: `EM:AddBarGroup`'s grid group, `EM:SetSetting`, the `'SettingsChanged'`, `'DragStarted'` and `'DragStopped'` events, and `EM.MoverName` (Task 3); `st.icons.layers` and `mapPin` (Task 2).
- Produces:
  - `EM.DIM_ALPHA = 0.5` and `EM:UpdateDim()` (`grid.lua`). `EM.dimFrame` is a SaftUI frame on all of UIParent at `BACKGROUND` strata, one level under `EM.gridFrame`, taking no mouse, with one black texture at `DIM_ALPHA`. It shows while `EM.active` and `dim` are both on.
  - `EM.CoordinatesText(position, nameOf) -> string`: `position` is a stored position (Ruling 5). Its `frame` field reads "the screen" when it is nil, `'UIParent'` or UIParent. Otherwise it reads as `nameOf(ref)`, or as the stored name when that gives nil. Offsets are read as numbers. `EM:UpdateCoordinates` passes `EM.MoverNameOf(ref) -> string | nil`, the `EM.MoverName` of the mover whose `def.frame` is `st:ResolveFrame(ref)`.
  - `EM.CoordinatesSpot(point, rect, width, height, screenWidth, screenTop) -> x, y`: the label's bottom left in UIParent units, whole. `rect` is the outline's `{ left, right, bottom, top }`.
  - `EM:ScreenTop() -> number`: UIParent's height, less the bar's height and its drawn inset while the bar is shown docked.
  - `EM.COORD_GAP = 2` and `EM:UpdateCoordinates()`. `EM.coordinates` is the label's frame (`.text`), at `FULLSCREEN_DIALOG` level 9100, taking no mouse, in `st:GetFont('pixel')` and the accent.
  - Bar controls `dim` (`W.IconButton(st.icons.layers)`, toggling `dim`) and `coordinates` (`W.IconButton(st.icons.mapPin)`, toggling `coordinates`), with the spec's tooltips.

**`EM.CoordinatesSpot`** places the label outside the outline at the mover's own `point`:
- **Across:** a LEFT point aligns the label's left with the rect's, a RIGHT point its right, and the rest centre it. A plain `LEFT` or `RIGHT` puts it beside the rect, `COORD_GAP` out.
- **Up and down:** a TOP point puts it `COORD_GAP` above, a BOTTOM point `COORD_GAP` below, and the rest centre it.
- **No room:** where that leaves the screen (`x < 0`, `x + width > screenWidth`, `y < 0`, `y + height > screenTop`), that axis flips inside the outline, `COORD_GAP` in. `CENTER` sits centred inside. The result is clamped into the screen below `screenTop`.

**What it shows:** the selected mover's, and during a drag the dragged mover's, whether or not it is selected. While a mover is dragged an `OnUpdate` on `EM.coordinates` follows `mover.drag.x` and `mover.drag.y`. It is hidden while Coordinates is off, with nothing selected or dragged, outside edit mode, or when the outline's rect can't be read (`EM.GetOutlineRect` gives nil, as for the Minimap's secret edges).

- [ ] **Step 1: Write the failing tests** in `tests/core/editmode_coordinates_test.lua` (world as Task 3's bar test)

```lua
test('the text names the corner and the parent, in words', function()
	local function nameOf(ref) return ref == 'SaftUIBar2' and 'Bar 2' or nil end
	eq(EM.CoordinatesText({ point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 120, y_off = -330 }, nameOf),
		'Top left of the screen: 120, -330', 'the screen')
	eq(EM.CoordinatesText({ point = 'BOTTOM', rel_point = 'TOP', frame = 'SaftUIBar2', x_off = 0, y_off = 3 }, nameOf),
		'Bottom to top of Bar 2: 0, 3', 'another mover by its name, both points when they differ')
	-- no frame -> 'of the screen'; offsets '12' and '-4' as strings -> 12, -4; 12.53 -> '12.5';
	-- a frame no mover has -> its stored name ('Top of ChatFrame1: 0, 0'); CENTER -> 'Center of the screen: 0, 0'
	-- EM.MoverNameOf: a registered mover's frame (by object and by its global name) -> its mover's name; another frame -> nil
end)

test('the label sits outside the outline at the anchoring corner, and flips inside where the screen ends or the bar covers it', function()
	-- EM.CoordinatesSpot('TOPLEFT', { left = 100, right = 260, bottom = 400, top = 428 }, 120, 10, 1920, 1040) == 100, 430
	-- 'BOTTOMRIGHT' -> 140, 388; 'CENTER' -> 120, 409; 'RIGHT' -> 262, 409
	-- 'TOPLEFT' with top = 1035 under screenTop 1040: flipped inside -> 100, 1023
	-- 'BOTTOMLEFT' with bottom = 4: inside -> 100, 6; 'RIGHT' at the right edge: inside
	-- EM:ScreenTop() with the bar docked and shown: UIParent height - 40 - its inset; hidden: UIParent height
end)

test('Coordinates shows the selected mover\'s position, follows a drag, and hides when off', function()
	-- settings off: hidden; on with none selected: hidden; EM:Select(m): shown, text from its position, font pixel, color button.blue
	-- EM:StartDrag(m2) (not selected), cursor moved, stub.fire_script(EM.coordinates, 'OnUpdate', 0.01): m2's live drag.x, drag.y
	-- EM:StopDrag(m2): back to the selected one; EM:Deactivate(): hidden; P.off(EM.coordinates) empty
end)
```

In `editmode_grid_test.lua`:

```lua
test('Dim world: a full-screen black layer at 50%, under the grid, only while edit mode and Dim are on', function()
	-- defaults dim true: EM.active -> EM.dimFrame shown, BACKGROUND, level < EM.gridFrame's, not mouse-enabled, alpha 0.5 texture
	-- EM:SetSetting('dim', false): hidden; EM:Deactivate(): hidden; on again with dim: shown
end)
```

- [ ] **Step 2: Run them to see them fail.** Run: `tests/run tests/core/editmode_coordinates_test.lua tests/core/editmode_grid_test.lua`. Expected: FAIL: `EM.CoordinatesText` is nil.

- [ ] **Step 3: Implement** the dim layer, `coordinates.lua`, the two controls, the tab rows and the defaults, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/EditMode/coordinates.lua SaftUI-Core/EditMode/load.xml SaftUI-Core/EditMode/grid.lua SaftUI-Core/EditMode/Bar/bargroups.lua SaftUI-Core/EditMode/settings.lua SaftUI-Core/Config/defaults.lua tests/lib/shell.lua tests/core/editmode_coordinates_test.lua tests/core/editmode_grid_test.lua tests/core/editmode_bar_test.lua .agents/edit-mode.md .agents/testing.md README.md
git commit -m "core: add Dim world and Coordinates to the edit mode bar"
```

**In-game checks:**
- Dim world, on by default, darkens the world behind the frames, nameplates included, on both clients. Check that other addons' lowest frames and Blizzard's world text still read (spec risk 8).
- With Coordinates on, select a frame: its position shows by its anchoring corner, for example "Top left of the screen: 120, -330", or "of Bar 2" for a bar anchored to Bar 2. It follows a drag. For a frame near the top it sits below the bar, not under it, and it stays on screen at every edge.

---

### Task 5: What shows: Show disabled, Show hidden, modules, the filter, overlapping labels

**Files:**
- Create: `SaftUI-Core/EditMode/filter.lua`, in `EditMode/load.xml` after `coordinates.lua` and in `editmode_files()`.
- Create: `SaftUI-Core/EditMode/Bar/barshow.lua`, in `Bar/load.xml` after `bargroups.lua` and in `editmode_bar_files()`.
- Modify: `editmode.lua` (`EM:Activate` shows overlays through `EM:UpdateShown()`), `mover.lua` (`EM:CreateMover`'s `overlay:Show()` becomes `overlay:SetShown(self.active and self:IsMoverShown(mover))`), `picker.lua` (`EM:UpdateLabels(top)` from `Scan` when the top mover changes; `EM.GetPickerState()` for tests), `settings.lua` (Show disabled and Show hidden rows) and `SaftUI-Core/Config/defaults.lua` (`show_disabled = false`, `show_hidden = false`, `hidden_modules = {}`).
- Test: create `tests/core/editmode_filter_test.lua`. Add the `hidden overlays are no snap target` case to `tests/core/editmode_snap_test.lua`.
- Docs: `.agents/edit-mode.md` (what shows, the rule, labels where overlapping, the picker), `.agents/testing.md`, `README.md` line 29, and `docs/design-system/components/Mover/README.md` (Known gaps: overlapping labels settled, decision 25).

**Interfaces:**
- Consumes: `EM:MoverModule`, `EM:IsMoverDisabled`, `EM:IsMoverHidden` and `EM.OTHER_MODULE` (Task 1); `W.SelectFace`, `W.LookSelectFace`, `W.OpenCheckList(..., buttons)`, `W.IconButton`, `W.LookSearch`, and `st.icons.powerOff`, `eye` and `search` (Task 2); `EM:AddBarGroup`, `EM:SetSetting`, `'SettingsChanged'`, `'Pressed'`, `'DragStarted'` and `EM.MoverName` (Task 3).
- Produces (`filter.lua` unless said):
  - `EM:GetModules() -> { name, ... }`: the modules with at least one registered mover, in alphabetical order, with `EM.OTHER_MODULE` last.
  - `EM:IsModuleShown(name) -> boolean` (`not hidden_modules[name]`), `EM:SetModuleShown(name, shown)` and `EM:SetAllModulesShown(shown)`. Each writes the profile through `EM:SetSetting('hidden_modules', ...)`; a module's key is cleared, never set to false.
  - `EM.ShowFaceText(modules, isShown) -> string`: `'All modules'`, the one name, `'<n> modules'` or `'Nothing'`.
  - `EM:SetFilter(text)`: `EM.filterText`, kept lowercase, `''` for none, not saved, and cleared on `Disabled`. `EM:MatchesFilter(mover) -> boolean` is a plain, case-ignored find in `EM.MoverName(mover)`.
  - `EM:IsMoverShown(mover) -> boolean`, the one rule:

    ```lua
    -- (a mover outside the module choice or the filter never shows)
    if not EM:IsModuleShown(EM:MoverModule(mover)) or not EM:MatchesFilter(mover) then return false end
    if EM:IsMoverDisabled(mover) then return settings.show_disabled end
    if EM:IsMoverHidden(mover) then return settings.show_hidden end
    return true
    ```

  - `EM:UpdateShown()`: every overlay is `SetShown(EM.active and EM:IsMoverShown(mover))`. A selected mover that doesn't show is deselected (`EM:Select(nil)`). Then the overlaps and labels are updated and `EM:Fire('ShownChanged')` runs.
  - `EM.SHOWN_INTERVAL = 0.5`: while edit mode is on, a frame of `filter.lua`'s runs `EM:UpdateShown()` that often, since bags open and pets come and go. It also runs on `Enabled`, on `SettingsChanged` and when the filter changes.
  - `EM:SelectFirstMatch() -> mover | nil`: the first shown mover by `EM.MoverName`, ignoring case.
  - `EM.RectsOverlap(a, b) -> boolean`: rects `{ left, right, bottom, top }` that share more than an edge.
  - `mover.overlaps`: it overlaps another shown mover's outline (`EM.GetOutlineRect`), recomputed in `EM:UpdateShown()` and on `PositionChanged`.
  - `EM:UpdateLabels(hovered)`: each shown mover's label shows when it doesn't overlap, or when it is `hovered`, the top mover under the cursor (design decision 25).
  - `EM.GetPickerState() -> { stack = { mover, ... }, list = frame }` (`picker.lua`, for tests): the movers under the cursor as `Scan` last found them, and the list by the cursor.
  - Bar groups (`barshow.lua`):
    - `'show'` (left, order 30, section `'show'`): `caption` ("Show", `OB.Font('caption')`, Text > Grey, gone at stage 2 and when floating); `showDisabled` (`W.IconButton(st.icons.powerOff)`, on = `show_disabled`, tooltip "Show disabled", "Shows the movers of frames you've turned off."); `showHidden` (`W.IconButton(st.icons.eye)`, on = `show_hidden`, tooltip "Show hidden", "Shows the movers of frames that aren't on screen right now: closed bags, no pet, no boss."); `modules` (`W.SelectFace`, 150 wide, 110 from stage 3, 140 when floating, its text `EM.ShowFaceText`, opening `W.OpenCheckList` with a row per `EM:GetModules()` and the buttons All and None).
    - `'filter'` (left, order 40, section `'show'`): `filter`, a kit input 150 wide (100 from stage 1, 0 at stage 5, 140 floating), `FIELD_HEIGHT` tall, `st.icons.search` (16) 6 in at its left and its text inset past it, with the grey hint "Filter movers...". Under Blizzard it is `W.LookSearch` with the Lucide glass hidden. `OnTextChanged` runs `EM:SetFilter`. Enter runs `EM:SelectFirstMatch()` and drops focus, and Esc clears the text and focus. It drops focus on `'Pressed'`, `'DragStarted'` and `Disabled`.

- [ ] **Step 1: Write the failing tests** in `tests/core/editmode_filter_test.lua` (world as Task 3's bar test; `add_mover(key, { module, isDisabled, isHidden, label })`)

```lua
test('one rule: the module choice and the filter first, then disabled under Show disabled, hidden under Show hidden', function()
	local a = add_mover('a', { module = 'Chat', label = 'Chat' })
	local d = add_mover('d', { module = 'Unit frames', label = 'Boss', isDisabled = function() return true end })
	local h = add_mover('h', { module = 'Unit frames', label = 'Target', isHidden = function() return true end })
	EM:Activate()
	check(a.overlay:IsShown() and not d.overlay:IsShown() and not h.overlay:IsShown(), 'both toggles off: only the shown one')
	EM:SetSetting('show_hidden', true)
	check(h.overlay:IsShown() and not d.overlay:IsShown(), 'Show hidden: the hidden one')
	EM:SetSetting('show_disabled', true)
	check(d.overlay:IsShown(), 'Show disabled: the disabled one')
	EM:SetModuleShown('Unit frames', false)
	check(not d.overlay:IsShown() and not h.overlay:IsShown() and a.overlay:IsShown(), 'a module unticked hides its movers whatever the toggles')
	-- profile: hidden_modules['Unit frames'] == true; SetModuleShown(.., true): the key is nil
end)

test('the module list holds only modules with movers, alphabetical, Other last; the face says what shows', function()
	-- GetModules() == { 'Chat', 'Unit frames', 'Other' } for movers of those (one without module)
	-- ShowFaceText: all -> 'All modules'; only Chat -> 'Chat'; two of three -> '2 modules'; none -> 'Nothing'
	-- click the face: W.ListOwner() == face; rows Chat, Unit frames, Other; None: every row unchecked, the list open;
	--   All: every row checked; a row click applies at once (overlay hidden) and keeps the list open
end)

test('the filter narrows inside the choice, never brings one back, and Enter selects the first match', function()
	-- SetFilter('TAR'): only 'Target' shows; a hidden-by-module mover named 'Target 2' stays hidden
	-- filter box: text 'bar', OnEnterPressed: EM.selected is the first shown mover named with 'bar' by name; focus dropped
	-- OnEscapePressed: text '', every mover back; Disabled clears it
	-- a mover whose rect is under the bar (top at UIParent's top): Enter selects it, EM:Nudge works on it (Review Focus 1)
end)

test('a selected mover that stops showing is deselected; an Alt pick and snapping leave it out', function()
	-- EM:Select(h); SetSetting('show_hidden', false): EM.selected nil
	-- GetMouseFoci stub returning a's overlay, cursor over a and h: EM.GetPickerState().stack holds a only
	-- EM:GetSnapLines(a) has no line from h's outline (editmode_snap_test.lua holds the same case)
end)

test('a frame that comes on screen in edit mode gets its mover within half a second', function()
	-- hidden = true -> not shown; hidden = false; stub.time += 0.5 and the ticker's OnUpdate: shown
end)

test('where movers overlap, only the one under the mouse shows its label', function()
	-- p and q overlapping, r apart: p.label and q.label hidden, r.label shown; EM:UpdateLabels(p): p's shown, q's hidden
	-- q dragged clear (EM:CommitPosition to a far x): both labels shown again
end)

test('the Show group and the filter under Blizzard: the Settings dropdown and the search box art', function()
	-- theme blizzard: modules face wears LookDropdown; the filter LookSearch with st.icons.search hidden; the toggles' icons blue when on
end)
```

- [ ] **Step 2: Run them to see them fail.** Run: `tests/run tests/core/editmode_filter_test.lua`. Expected: FAIL: `EM:IsMoverShown` is nil.

- [ ] **Step 3: Implement** `filter.lua`, `barshow.lua` and the changes to `editmode.lua`, `mover.lua`, `picker.lua`, `settings.lua` and `defaults.lua`, as the Interfaces say. The picker's `Scan` keeps taking only shown overlays, and `EM:GetSnapLines` keeps taking only shown overlays, unchanged.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS. The cases of `editmode_snap_test.lua` and `theme_blizzard_editmode_test.lua` that activate edit mode see every test mover shown: those movers have no predicates.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/EditMode/filter.lua SaftUI-Core/EditMode/Bar/barshow.lua SaftUI-Core/EditMode/Bar/load.xml SaftUI-Core/EditMode/load.xml SaftUI-Core/EditMode/editmode.lua SaftUI-Core/EditMode/mover.lua SaftUI-Core/EditMode/picker.lua SaftUI-Core/EditMode/settings.lua SaftUI-Core/Config/defaults.lua tests/lib/shell.lua tests/core/editmode_filter_test.lua tests/core/editmode_snap_test.lua .agents/edit-mode.md .agents/testing.md README.md docs/design-system/components/Mover/README.md
git commit -m "core: choose which edit mode movers show by module, by name and by whether their frame is off or hidden"
```

**In-game checks:**
- With both Show toggles off (the default), disabled bars, the pet bar without a pet, closed bags and target, focus and boss frames with nothing to show have no mover. Show hidden brings the ones not on screen back; Show disabled the turned-off ones.
- Open a bag in edit mode: its mover appears within half a second.
- The Show dropdown: untick Unit frames and its movers go. All and None work, and the face reads "All modules", "Unit frames", "3 modules" or "Nothing". A reload keeps the choice.
- Type "bar" in the filter: only bars show. Enter selects the first, and the arrow keys nudge it. Esc clears.
- Where bars 4 to 8 overlap, only the one under the mouse shows its name. Alt still cycles them.

---

### Task 6: The history store, fed by drags, nudges and resets

**Files:**
- Create: `SaftUI-Core/EditMode/history.lua` (the generic store) and `SaftUI-Core/EditMode/moves.lua` (edit mode's side: the position kind, recording, Reset). Both go in `EditMode/load.xml` after `filter.lua`, history first, and in `editmode_files()`.
- Modify: `mover.lua`. `EM:StartDrag` copies the position before anything else. `EM:StopDrag` records after its commit. `EM:Nudge` copies, commits and records. `EM:Select` closes the run when the selection changes.
- Test: create `tests/core/editmode_history_test.lua` (the store, on a test kind, in `tests/core/config_helpers.lua`'s world for AceDB) and `tests/core/editmode_moves_test.lua` (movers). Add the reset cases to `tests/misc/objective_tracker_position_test.lua` and `tests/misc/theme_test.lua` (the totem bar).
- Docs: `.agents/edit-mode.md` (a History section: a step, the kinds, the grouping rule and where it lives, the limit, undo and redo, staleness, revert, when it clears, and how part two adds a kind; the Offsets bullet gains the before copy), `.agents/testing.md`, and `docs/design-system/components/Mover/README.md` (States: Reset).

**Interfaces:**
- Consumes: `EM:GetDefaultPosition` and `def.noDefaultReason` (Task 1); `EM.MoverName` and the `'Disabled'` event (Task 3).
- Produces (`history.lua`), `EM.History = History`:
  - `History.MERGE_GAP = 1`, `History.LIMIT_MIN, History.LIMIT_MAX = 1, 1000`, and `History.limit` (default 50), set by `History:SetLimit(n)` (a whole number, clamped). Lowering the limit drops the oldest steps at once.
  - `History:RegisterKind(name, handler)`. `handler` is:
    - `read(where) -> value`: a copy of what is stored now;
    - `write(where, value)`: stores a copy, through the setter a player's change uses;
    - `finish(wheres)`, optional: once after a step's writes, with the list of its wheres of this kind;
    - `same(a, b) -> boolean`, optional, default `History.Same`;
    - `place(where) -> string`, optional, default `name .. ':' .. tostring(where)`;
    - `check(where, value) -> ok, why`, optional;
    - `name(where) -> string`.
  - A step is `{ kind = 'move' | 'nudge' | 'reset' | 'bulk' | 'revert', label = string | function(step) -> string, time = GetTime(), target = <mover key> | nil, changes = { { kind = <handler name>, where, old, new }, ... }, open = true | nil, last = <time of its last merge> }`.
  - `History:Push(step) -> step | nil`: it records an action already made. It drops the changes with no net change (`same(old, new)`), and records nothing if none is left. It merges into the top step when `History.Merges(top, step, GetTime())` is true, keeping the top's `old` and taking the step's `new`, and pops a merged step left with no net change. Otherwise it appends, after discarding the redo steps, and trims to the limit. `step.open` is set for a nudge only, and any push closes the earlier run. On the first push it registers AceDB's `OnProfileChanged`, `OnProfileCopied` and `OnProfileReset` on `st.config` to `History:Clear()`, where `st.config.RegisterCallback` exists. The shell's plain profile has none, and AceDB's worlds (`config_helpers.lua`) do.
  - `History.Merges(top, step, now) -> boolean`: the grouping rule, in one place (Ruling 8c): `top.open`, both kinds `'nudge'`, the same `target`, `History:Position() == #steps`, and `now - top.last <= History.MERGE_GAP`.
  - `History:CloseRun()` clears `open` on the top step.
  - `History:Steps() -> list` (oldest first; read only) and `History:Position() -> n` (steps 1 to n are applied).
  - `History:CanUndo()`, `History:CanRedo() -> boolean`.
  - `History:Undo() -> ok, message` and `History:Redo() -> ok, message`. Each refuses in combat (`false, "Can't undo in combat."` or `"Can't redo in combat."`) and writes nothing. Otherwise:
    - **Stale:** every change's current `read(where)` must equal the step's `new` (`old` for a redo). If one doesn't, the step and every older step that touches one of its places are dropped, nothing is written, and the message is `'<name> was changed since; its earlier steps are dropped.'`.
    - **Check:** every `check(where, old)` must pass. A refusal drops the step and returns the reason.
    - **Write:** then it writes in reverse order (in order for a redo), runs each kind's `finish` with `xpcall` to `geterrorhandler()` (an error closes the run), moves the position and fires `HistoryChanged`.
  - `History:JumpTo(n) -> ok, message`: undo or redo, one step at a time, until `Position() == n` (0 is before every step). It stops at the first refusal.
  - `History:CanRevert(i) -> ok, why`. A step that isn't applied (`i > Position()`) gives `false, nil` and shows no control. A bulk step gives `"A copy can't be reverted on its own: go back to this point instead."`. A later applied step touching one of its places gives `'Changed again later: go back to this point instead.'`, and a stale place gives `'<name> was changed since.'`.
  - `History:Revert(i) -> ok, message`: writes the step's `old` values (after its checks), runs `finish`, then pushes `{ kind = 'revert', label = 'Reverted: ' .. History.Label(step), target = step.target, changes = { { kind, where, old = <what was there>, new = <step's old> } } }`.
  - `History:Clear()` and `History.Same(a, b) -> boolean`: deep equality in which a number and a string of the same number are equal (within 1e-4) and nil equals only nil.
  - `History.Label(step) -> string` (a string label, or the function's result) and `History.Places(step) -> { [place] = true }`.
  - The event `EM:Fire('HistoryChanged')` fires on every push, merge, undo, redo, jump, revert, trim and clear.
- Produces (`moves.lua`):
  - The `'position'` kind. `where` is a mover key.
    - `read` is `EM.CopyPosition(def.getPosition())`, and `write` is `def.setPosition(EM.CopyPosition(value))`.
    - `finish` runs `def.apply` (through `xpcall`), then `EM:Fire('PositionChanged', mover)` for each.
    - `same` is `EM.SamePosition`, and `name` is `EM.MoverName`.
    - `check` refuses an anchor `st:ValidateAnchor(def.frame, value.frame)` refuses, unless the frame is UIParent or none; a refused anchor also prints its reason to chat (`st:Print`).
  - `EM.CopyPosition(position) -> table` (deep).
  - `EM.SamePosition(a, b) -> boolean`: the same `point`; the same `rel_point`, a missing one being its `point`; the same `frame`, where nil, `'UIParent'` and UIParent are one; and `x_off` and `y_off` equal as numbers (missing is 0, within 1e-4).
  - `EM.MoveLabel(kind, name, old, new) -> string`: `'Moved <name>'`, `'Nudged <name> by <dx>, <dy>'` (net offsets, whole or one decimal) or `'Reset <name>'`.
  - `EM:RecordMove(mover, kind, before)`: it pushes `{ kind, target = mover.key, label, changes = { { kind = 'position', where = mover.key, old = before, new = <read now> } } }`. A nudge's label is a function of its first change, so a merged run reads its net offset.
  - `EM:CanReset(mover) -> ok, why`:
    - nil gives `'Select a frame first.'`;
    - no default gives `def.noDefaultReason` or `'<name> has no default place.'`;
    - `EM.SamePosition(current, default)` gives `'<name> is already in its default place.'`;
    - combat gives `"Can't reset in combat."`.
  - `EM:Reset(mover) -> ok, message`: if `CanReset`, it copies the position before, calls `def.setPosition(EM:GetDefaultPosition(mover))`, runs `def.apply` (`xpcall`) and fires `PositionChanged`. Then it calls `EM:RecordMove(mover, 'reset', before)`.
  - On `'Disabled'`, `History:CloseRun()`.

- [ ] **Step 1: Write the failing tests.** `tests/core/editmode_history_test.lua` uses a test kind `'value'` over a table `store` (`read = function(k) return store[k] end`, `write = function(k, v) store[k] = v; writes[#writes + 1] = k end`, `finish = function(ws) finishes[#finishes + 1] = #ws end`, `name = function(k) return k end`) and a `push(kind, target, k, old, new)` helper. The helper writes `new` first, as a real action has already happened, then pushes `{ kind, target, label = 'Set ' .. k, changes = { { kind = 'value', where = k, old = old, new = new } } }`.

```lua
test('Push records a step with its label, time and changes; a step with no net change records nothing', function()
	stub.time = 10
	local step = push('move', 'a', 'a', 1, 2)
	eq(History.Label(step), 'Set a', 'its label'); eq(step.time, 10, 'its time'); eq(#History:Steps(), 1, 'one step')
	eq(push('move', 'a', 'a', 2, '2'), nil, "a change to the same number as a string is no change")
	eq(#History:Steps(), 1, 'nothing recorded')
end)

test('nudges merge only by the grouping rule; the merged step keeps the first old and the latest new', function()
	-- three nudges on 'a' at 10, 10.5, 11.4 -> one step, old 1, new 4, open
	-- a gap of 1.01 -> a new step; another target -> a new step; a 'move' between -> a new step;
	-- History:CloseRun() -> the next nudge a new step; undone top (Position < #steps) -> no merge
	-- nudges back to the start (1 -> 2 -> 1) -> the step is gone
end)

test('a new step after an undo discards the redo steps; the limit drops the oldest first', function()
	-- push 3, Undo, push: #Steps == 3, CanRedo false
	-- SetLimit(2): oldest dropped at once; SetLimit(0) -> 1; SetLimit(5000) -> 1000; 1.6 -> 2
end)

test('Undo and Redo write through the kind and run finish once per step; in combat they refuse and write nothing', function()
	-- Undo: store.a == old, writes in reverse change order, #finishes == 1; Redo: store.a == new
	-- stub.in_combat = true: Undo() == false, "Can't undo in combat.", #writes unchanged
end)

test('a stale step is dropped with the older steps on its place, and nothing is written', function()
	-- steps on a (1->2), b, a (2->3); store.a = 9 outside the history; Undo: false, 'a was changed since; its earlier steps are dropped.'
	-- #Steps == 1 (b's), store.a == 9
end)

test('JumpTo goes to any state and every step stays redoable until a new one', function()
	-- 4 steps; JumpTo(1): Position 1, store as after step 1; JumpTo(4): all back; JumpTo(0): before every step
end)

test('Revert puts back one older step as a new step, only when nothing later touched its place and it is not stale', function()
	-- steps a(1->2), b(5->6): CanRevert(1) true; Revert(1): store.a == 1, a new top 'Reverted: Set a', b untouched
	-- steps a, a: CanRevert(1) == false, 'Changed again later: go back to this point instead.'
	-- a bulk step: false, "A copy can't be reverted on its own: go back to this point instead."
	-- an undone step: false, nil
end)

test('the history clears on a profile change, copy or reset, not on a theme change and not on leaving edit mode', function()
	-- config_helpers world: push one; st:ThemeChanged(): still 1; EM:Activate(); EM:Deactivate(): still 1
	-- st.config:SetProfile('Other'): 0; push; st.config:CopyProfile('Default'): 0; push; st.config:ResetProfile(): 0
end)

test('Same: numbers and their strings, nested tables, nil', function()
	-- Same({ x = '12', y = { 1 } }, { x = 12, y = { 1 } }) true; Same(nil, false) false; Same(1, 1.00001) true; Same(1, 1.1) false
end)
```

`tests/core/editmode_moves_test.lua` (world: `load_core_helpers()`, `load_editmode()`; movers through `st:RegisterConfigMover` on a profile table, `apply` counting its calls; the cursor through `stub.cursor_x`/`cursor_y`; `stub.time` for the gaps):

```lua
test('a drag from press to release is one step "Moved Player"; a click or a drag back to the start records nothing', function()
	-- StartDrag, cursor +40, UpdateDrag ticks, StopDrag: one step, label 'Moved Player', old x 0, new x 40
	-- the step's old is not the table getPosition returns (the ticks wrote into that one)
	-- StartDrag, StopDrag with no move: none; a drag out and back: none
end)

test('a run of nudges under a second apart is one step, "Nudged Player by 3, 0"; selecting another, a drag or Exit starts a new one', function()
	-- EM:Select(p); Nudge RIGHT x3 at 0.3s apart: one step 'Nudged Player by 3, 0'
	-- EM:Select(q), EM:Select(p), Nudge: a new step; a drag between: a new step; Deactivate/Activate: a new step
end)

test('Reset puts the default copy through setPosition and apply, is its own step, closes a run, and can be undone', function()
	-- nudge then Reset: two steps, the second 'Reset Player', never merged; apply called; Undo: back to the nudged spot
	-- the stored position is not the defaults table, and a nudge after it leaves st.defaults unchanged
end)

test('CanReset says why not: none selected, no default, already there (strings and numbers alike)', function()
	-- nil -> 'Select a frame first.'; no default and a reason -> the reason; none -> 'Thing has no default place.'
	-- current { x_off = '0' } vs default { x_off = 0 } -> 'Player is already in its default place.'
end)

test('undo of a move on a secure frame: refused in combat with nothing blocked; out of combat it moves through apply only', function()
	-- the mover's frame IsProtected true (a stand-in as tests/core/holders_test.lua marks one); a drag recorded;
	-- stub.in_combat = true: Undo false, position unchanged, #stub.blocked == 0, apply not called
	-- out of combat: Undo true, apply called once, the frame placed by apply (its SafeReposition), not by the history
end)

test('edit mode closing for combat mid-drag commits the drag and records it; a profile change mid-drag records nothing', function()
	-- StartDrag, cursor +20, UpdateDrag, stub.fire_event('PLAYER_REGEN_DISABLED'): one step 'Moved Player'
	-- (config_helpers world) StartDrag, SetProfile('Other'): EM:UpdateConfig drops the drag, #Steps == 0
end)

test('an undo that would anchor a frame to one now anchored to it is refused, dropped, and said in chat', function()
	-- p's step restores frame = q's frame name; q anchored to p since; Undo: false, the step gone, printed "Anchor would create a loop"
end)
```

In `objective_tracker_position_test.lua`: `EM:Reset` on the moved tracker saves a copy of `DefaultPosition()` (not nil, not the same table twice). `OTP:KeepPlacement` then keeps it across a profile change to a profile with no position. Undo puts the moved spot back. On a profile with no position, `EM:CanReset` gives "already in its default place".

In `theme_test.lua`: the totem bar's `EM:CanReset` gives `false` and its reason.

- [ ] **Step 2: Run them to see them fail.** Run: `tests/run tests/core/editmode_history_test.lua tests/core/editmode_moves_test.lua`. Expected: FAIL: `EM.History` is nil.

- [ ] **Step 3: Implement** `history.lua`, `moves.lua` and the four changes to `mover.lua`, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core tests/misc`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files. Name `History.Merges` and `History.MERGE_GAP` as the one place the grouping rule lives, provisional until the owner confirms the research.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/EditMode/history.lua SaftUI-Core/EditMode/moves.lua SaftUI-Core/EditMode/load.xml SaftUI-Core/EditMode/mover.lua tests/lib/shell.lua tests/core/editmode_history_test.lua tests/core/editmode_moves_test.lua tests/misc/objective_tracker_position_test.lua tests/misc/theme_test.lua .agents/edit-mode.md .agents/testing.md docs/design-system/components/Mover/README.md
git commit -m "core: keep a history of edit mode's moves, nudges and resets"
```

**In-game checks:** nothing new to see. Drags, nudges, Alt picks and `/sui`'s Position still work as before, with no Lua errors. Entering combat mid-drag drops the frame where it was let go.

---

### Task 7: Undo, Redo, Reset and History on the bar; Copy from as one step

**Files:**
- Create: `SaftUI-Core/EditMode/Bar/barchanges.lua` (the changes group and the status line) and `Bar/historylist.lua` (the History list), in `Bar/load.xml` after `barshow.lua` and in `editmode_bar_files()`.
- Modify: `settings.lua` (`history_limit` through `EM:SetSetting`, clamped from 1 to 1000, which calls `History:SetLimit`; the History length row on the Edit mode tab) and `SaftUI-Core/Config/defaults.lua` (`history_limit = 50`).
- Modify: `SaftUI-Unitframes/config/config.lua`. Accept's `func` calls `UF:CopySettings`, and the file registers the `'ufsetting'` kind at load.
- Modify: `SaftUI-Unitframes/config/profiles.lua`. `History:Clear()` runs wherever `config_profile` is written: `SwitchProfile`, `UF:SetProfile`, and the delete and rename prompts.
- Test: create `tests/core/editmode_bar_changes_test.lua` and `tests/unitframes/copy_from_history_test.lua` (`UW.world()`, `tests/unitframes/uf_world.lua`, with edit mode loaded).
- Docs:
  - `.agents/edit-mode.md`: the bar's changes group, the status line and the History list; Copy from as a step; the unit frame profile switch clearing the history.
  - `.agents/testing.md`; `README.md` (line 29, and the Copy from mention around line 54 if it names the dialog's behaviour).
  - The design system: `docs/design-system/components/Mover/README.md`, and `components/ResetIcon/README.md` (the History list's revert is a reset-like icon, grey with an accent hover).

**Interfaces:**
- Consumes: `EM.History` and its API, `EM:CanReset`, `EM:Reset` and `'HistoryChanged'` (Task 6); `EM:IsMoverShown` (Task 5); `W.IconButton`, `W.IconLink`, `W.NumberBox` and `W.ShowTip`, and `st.icons.undo2`, `redo2`, `history` and `rotateCcw` (Task 2); `EM:AddBarGroup`, `EM:SetSetting` and `EM:RefreshBar` (Task 3).
- Produces:
  - A bar group `'changes'` (right, order 80, section `'changes'`) with:
    - `undo` (`st.icons.undo2`): enabled while `History:CanUndo()`. Tooltip "Undo", then "Puts <name> back where it was before." for a step with a target, or "Undoes <label>." Disabled with red "Nothing to undo.";
    - `redo` (`st.icons.redo2`): "Moves <name> again." or "Redoes <label>." Disabled with "Nothing to redo.";
    - `history` (`st.icons.history`): on while the list is open. Tooltip "History", "Lists your changes, newest first: go back to any of them, or revert one on its own.";
    - `reset` (`st.icons.rotateCcw`, tinted as the others): `EM:CanReset(EM.selected)` sets its state and reason. Tooltip "Reset", "<name> goes back to its default place.".
  - Each refreshes on `HistoryChanged`, `Selected` and `PositionChanged`.
  - `EM.STATUS_SECONDS = 6` and `EM:SetBarStatus(text)`. Docked, it is a `small`-font, Text > Grey line in the flexible gap, right-aligned 12 short of the first right group's divider, cut to the room, taking no mouse. It clears after `STATUS_SECONDS`, on a new status, and on `Disabled`.
  - `EM:UndoStep()`, `EM:RedoStep()`, `EM:JumpToStep(n)` and `EM:RevertStep(i)`. Each runs its `History` call, then posts `'Undid: <label>'`, `'Redid: <label>'`, `'Went back to: <label>'` or `'Reverted: <label>'` (or the refusal's message). When the step's target mover's overlay isn't shown, or its outline is off screen, it adds `' Its mover is hidden by Show or the filter.'` (Ruling 8i). The selection doesn't change.
  - `EM.HISTORY = { WIDTH = 300, PAD = 12, ROW = 26, ROWS = 12, LEVEL = 9700, WHEEL = 3 }`, and `EM:GetHistoryList()`, `EM:ToggleHistoryList()` and `EM:IsHistoryListShown()` (`historylist.lua`).
    - **Placement:** docked, its top right is 6 under the History button's bottom right. It is drawn as a `panel` in the theme, with `st:KeepInScreenMargin`.
    - **Title:** "History" in `OB.Font('group')`, Text > Grey.
    - **Rows:** newest first, `ROW` tall with `OB.HAIRLINE` between them, up to `ROWS` shown with the wheel scrolling `WHEEL` rows and `OB.ScrollBar(list, set, { narrow = true })` when there are more. Each row has:
      - a 2px accent mark at its left when it is the current step;
      - its label in the field font (Text > Grey when undone);
      - a detail in `small` grey: `'undone'`, `'<n> settings'` for a bulk step, else `EM.Ago(GetTime() - step.time)`;
      - a revert `W.IconLink(rotateCcw, 14)`, shown only for `CanRevert`'s non-nil answers, enabled or with its reason.
    - **Row clicks and hover:** a click on a row runs `EM:JumpToStep`. A row under the mouse is filled at 25% accent, or with the dropdown list's `rowHover` under Blizzard. Its tooltip is the label, then "Goes back to just after this step; the steps after it stay until you make a new change."
    - **The last row:** "Before these changes" jumps to 0.
    - **Foot:** "Keep the last", a `W.NumberBox` (54, from 1 to 1000, step 10, setting `history_limit`), then "steps (up to 1000)".
    - **Closing:** Esc closes it, through its own key catcher, a child of the list, so it comes before `/sui`'s and edit mode's. So do History again, `Disabled` and combat.
  - `EM.Ago(seconds) -> string`: `'now'` under 5, `'<n>s ago'`, `'<n>m ago'`, `'<n>h ago'`.
  - The `'ufsetting'` kind (`SaftUI-Unitframes/config/config.lua`). `where` is `{ profile = <UF profile name>, unit, key }`.
    - `read` is a deep copy of `profiles[profile][unit][key]`, and `write` stores a deep copy there.
    - `finish` runs `UF:UpdateConfig()` and then `st.Config:Refresh()`.
    - `place` is `'ufsetting:' .. profile .. ':' .. unit .. ':' .. key`, and `name` is the unit's label (`UF.unit_strings` or `UF.group_strings`).
    - `check` refuses a profile that isn't current: `'The unit frame profile changed since.'`.
  - `UF:CopySettings(unit, from, keys) -> step | nil`. It copies, as Accept's `func` does today, each key's deep copy from `from` onto `unit`. The old values are copied first. Then it calls `UF:UpdateConfig()` and pushes one step: `{ kind = 'bulk', label = 'Copied <from label> to <unit label>', changes = <one per key whose value changed> }`. Accept's `func` becomes `UF:CopySettings(unit, copy.from, <the ticked keys>)`, then `st.Config:Refresh()` and `CloseDialog`, as before.

- [ ] **Step 1: Write the failing tests** in `tests/core/editmode_bar_changes_test.lua` (world as Task 5's; `add_mover` with defaults)

```lua
test('Undo, Redo and Reset are enabled by what they can do, and their tooltips name the mover they will move', function()
	-- empty: undo/redo disabled, tooltips red 'Nothing to undo.' / 'Nothing to redo.'; reset 'Select a frame first.'
	-- drag Player: undo enabled, 'Puts Player back where it was before.'; select Player: reset 'Player goes back to its default place.'
	-- Player at its default: 'Player is already in its default place.'
end)

test('Undo moves the frame back and says so in the status line, naming a mover the filter hides', function()
	-- drag Player; stub.click(undo): position back, apply called, status 'Undid: Moved Player'; redo: 'Redid: Moved Player'
	-- SetFilter('zzz') then undo: the status adds ' Its mover is hidden by Show or the filter.'; EM.selected unchanged
	-- stub.time + 6, the status's clock: cleared
end)

test('Reset resets the selected mover and can be undone from the bar', function()
	-- select Player, nudge, click reset: at its default, step 'Reset Player'; click undo: the nudged spot again
end)

test('the History list: newest first, the current step marked, undone ones grey, a row click goes back to it', function()
	-- three steps; click history: list shown, history.on; rows labels newest first, then 'Before these changes'
	-- the first row has the mark; undo: the mark on the second, the first grey with 'undone'
	-- click the third row: Position 1; click 'Before these changes': Position 0; redo still possible
end)

test("a row's revert shows on applied steps, enabled only when nothing later touched its mover, with the reason when not", function()
	-- moves Player, Target: Player's revert enabled; click it: a new top 'Reverted: Moved Player'
	-- moves Player, Player: the older one's revert disabled, its tooltip 'Changed again later: go back to this point instead.'
	-- a bulk step: its revert disabled with "A copy can't be reverted on its own: go back to this point instead."
end)

test('the History list scrolls past 12 rows, sets its length, and closes on Esc, History, Exit and combat', function()
	-- 20 steps: 12 rows shown, wheel -1 scrolls 3; the box typed '5': history_limit 5, 5 steps left; '2000' -> 1000
	-- keys catcher OnKeyDown 'ESCAPE': hidden, /sui (open) still shown; open again, EM:Deactivate(): hidden
	-- P.off(list) empty; strata FULLSCREEN_DIALOG level 9700; under Blizzard drawn as the panel kind
end)

test('the History length row on the Edit mode tab', function()
	-- st.Config:GetOptionsTable().Fonts.args.editmode.args.general.args.history_limit: range 1..1000, set -> History.limit
end)
```

In `tests/unitframes/copy_from_history_test.lua`:

```lua
test('Copy from is one step that a single Undo takes back whole, and Redo does again', function()
	-- target and focus with different health and position; UF:CopySettings('focus', 'target', { 'health', 'position', 'width' }):
	-- one step, kind bulk, label 'Copied Target to Focus', a change per differing key; Undo: every key back (deep), UF:UpdateConfig ran
	-- Redo: copied again; a key equal on both: no change listed; none differing: no step
end)

test("the dialog's Confirm copy records the step; a unit frame profile switch clears the history", function()
	-- open UF:OpenCopyTable('focus'), set from, tick two, accept's func: #History:Steps() == 1
	-- SwitchProfile (via the profile footer's set) to another: #Steps == 0
end)
```

- [ ] **Step 2: Run them to see them fail.** Run: `tests/run tests/core/editmode_bar_changes_test.lua tests/unitframes/copy_from_history_test.lua`. Expected: FAIL: `EM:UndoStep` is nil.

- [ ] **Step 3: Implement** `barchanges.lua`, `historylist.lua`, the setting, `UF:CopySettings`, the kind and the clears, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/EditMode/Bar/barchanges.lua SaftUI-Core/EditMode/Bar/historylist.lua SaftUI-Core/EditMode/Bar/load.xml SaftUI-Core/EditMode/settings.lua SaftUI-Core/Config/defaults.lua SaftUI-Unitframes/config/config.lua SaftUI-Unitframes/config/profiles.lua tests/lib/shell.lua tests/core/editmode_bar_changes_test.lua tests/unitframes/copy_from_history_test.lua .agents/edit-mode.md .agents/testing.md README.md docs/design-system/components/Mover/README.md docs/design-system/components/ResetIcon/README.md
git commit -m "core: add undo, redo, reset and a history list to the edit mode bar, with Copy from as one step"
```

**In-game checks:**
- Drag a frame, then Undo: it goes back, and Redo moves it again.
- Nudge a frame 16 times quickly: one step, "Nudged ... by 16, 0".
- Reset a frame, then Undo the reset.
- Undo a move of an action bar and of a unit frame, then enter combat right after: no blocked-action error.
- Reset the objective tracker: it goes to Blizzard's spot and stays there after switching profiles and back. The totem bar's Reset is dim and says why.
- History: newest first, the current step marked, undone ones grey. Click an older row: everything after it undoes, and Redo brings it back. A row's revert works when nothing later moved that frame, and says why when not.
- Set the length to 5: only five steps remain.
- Unitframes > Copy from (Target onto Focus, several settings): one step. A single Undo puts every copied setting back.
- Switch the unit frame profile, or the profile: the history empties. Switch theme: it doesn't.
- Under the Blizzard theme, on both clients, the list and buttons draw.

---

### Task 8: The floating window

**Files:**
- Create: `SaftUI-Core/EditMode/Bar/barwindow.lua`, last in `Bar/load.xml` and in `editmode_bar_files()`.
- Modify: `Bar/bar.lua` (the mode: the docked bar or the window holds the controls; layout and fade for both), `Bar/bargroups.lua` (`detach` in the options group; `dock` in the window's title), `Bar/barchanges.lua` (the status line's place in the window) and `Bar/historylist.lua` (placed beside the window).
- Test: create `tests/core/editmode_bar_window_test.lua`.
- Docs: `.agents/edit-mode.md` (the floating window, its saved place and mode), `.agents/testing.md`, `README.md` line 29, and `docs/design-system/components/Mover/README.md` if it names the bar's place.

**Interfaces:**
- Consumes: every bar group and control, with `section` and `align` (Tasks 3, 4, 5, 7); `EM:SetBarStatus` and `EM:GetHistoryList` (Task 7); `W.IconButton`, and `st.icons.pictureInPicture2` and `panelTop` (Task 2).
- Produces:
  - `st.config.global.editModeBar = { floating = boolean, x = number, y = number }`, written on a mode change and a window drag. `x` and `y` are the window's top left offsets from UIParent's top left, whole.
  - `EM:IsBarFloating() -> boolean` and `EM:SetBarFloating(floating)`. The latter saves the mode, moves every control into the bar or the window (`SetParent`), lays out, and keeps the shown state. The History list, the kit's list and the filter's focus close.
  - `EM.WINDOW = { WIDTH = 312, PAD = 12, TITLE = 42, CAPTION = 13, CAPTION_GAP = 4, SECTION_PAD = 8, GAP = 4 }` and `EM.WINDOW_SECTIONS = { { key = 'grid', caption = 'Grid and snap' }, { key = 'show', caption = 'Show' }, { key = 'changes', caption = 'Changes' } }`.
  - `EM.WindowLayout(width, sections) -> rows, height`. It is pure. `sections` holds `{ { widths = { w, ... }, aligns = { 'right' | nil, ... } }, ... }`. Each section's controls wrap into lines `GAP` apart within `width - 2 * PAD`, and right-aligned ones end the line. It returns each control's x and y from the window's top left, whole, and the total height, from `TITLE`, each section's `SECTION_PAD`, caption and lines, and a 1px `OB.LINE` between sections.
  - `EM:GetBarWindow() -> frame`:
    - **Frame:** `st:CreateFrame` on UIParent at `FULLSCREEN_DIALOG` level `EM.BAR.LEVEL`, drawn `st:SetBackdrop(window, 'theme', 'theme', 'panel')`, and `SetMovable(true)` with `st:KeepInScreenMargin(window)`.
    - **Title row:** "Edit mode" in `OB.Font('section')` at x 12. It is dragged by its title row only (`StartMoving`, then `StopMovingOrSizing` and saving the place). It holds `dock` (`W.IconButton(st.icons.panelTop)`, "Dock", "Puts the controls back in a bar across the top of the screen.") and Exit, compact, at its right, 8 in, 4 apart.
    - **Placement:** with no saved place it sits at `x = floor((UIParent width - 312) / 2)`, `y = -80`. It is laid out again on `UI_SCALE_CHANGED`, `DISPLAY_SIZE_CHANGED` and a screen edge margin change, and placed back inside the margin.
    - **Status and fade:** its status line is under the Changes section. It fades during a drag as the bar does.
  - The bar control `detach` (`W.IconButton(st.icons.pictureInPicture2)`, at the docked options group's end): "Detach", "Turns the bar into a small window you can move anywhere.". It is `section = 'title'`, where Task 8's window shows `dock` in its place and hides `detach`.
  - The History list, floating: its top left 8 right of the window's top right, or its top right 8 left of the window's top left when there's no room, kept in the margin.

- [ ] **Step 1: Write the failing tests** in `tests/core/editmode_bar_window_test.lua` (world as Task 7's; `local P = load_test_file('lib/pixels.lua')`)

```lua
test('Detach turns the bar into a window holding the same controls in sections; Dock puts them back', function()
	EM:Activate()
	stub.click(EM:BarControl('detach').frame)
	local window = EM:GetBarWindow()
	check(window:IsShown() and not EM:GetBar():IsShown(), 'the window, not the bar')
	eq(window:GetWidth(), 312, '312 wide')
	eq(EM:BarControl('grid').frame:GetParent(), window, 'the controls moved into it')
	eq(st.config.global.editModeBar.floating, true, 'the mode saved')
	-- sections in order Grid and snap, Show, Changes; options right-aligned in Changes; exit compact in the title; no Show caption
	-- stub.click(dock): the bar again, controls on it, floating false
end)

test('the window lays out on whole pixels, wraps each section, and is as tall as its contents', function()
	-- EM.WindowLayout(312, { { widths = { 26, 54, 26, 26, 26, 26 } }, { widths = { 26, 26, 140, 140 } },
	--   { widths = { 26, 26, 26, 26, 80 }, aligns = { nil, nil, nil, nil, 'right' } } }):
	--   section 2's face and filter on a second line; the 80 ends at 300; every x, y whole; height whole
	-- the real window: P.off(window) empty at 1920x1080 and 1024x768 with stub.size_noise = 2 ^ -14
end)

test('dragged by its title it stays inside the screen margin, and keeps its place across a reload', function()
	-- StartMoving/StopMovingOrSizing through the title's OnDragStart/OnDragStop with the window moved past the left edge:
	--   left >= the margin; saved x, y whole; a new world with st.config.global.editModeBar set: floating, at x, y
end)

test("a saved place the screen no longer has comes back inside the margin", function()
	-- saved x 3000 on a 1024-wide screen: the window's right <= 1024 - margin after it shows; DISPLAY_SIZE_CHANGED: again
end)

test('the window sits over /sui and under the lists; the History list opens beside it', function()
	-- /sui open: window level 9500 > OW frame's 100; the face's check list in TOOLTIP strata
	-- History list: left = window right + 8; with the window at the right edge: right = window left - 8
end)

test('the window under Blizzard on both clients, and while a mover is dragged', function()
	-- T.client forever/retail, theme blizzard: panel kind's Blizzard art; dock and exit panel-button art
	-- EM:StartDrag(m): window alpha 0.25, controls take no mouse
end)
```

- [ ] **Step 2: Run them to see them fail.** Run: `tests/run tests/core/editmode_bar_window_test.lua`. Expected: FAIL: `EM:GetBarWindow` is nil.

- [ ] **Step 3: Implement** `barwindow.lua`, the mode in `bar.lua`, `detach` and `dock`, and the status line's and History list's places, as the Interfaces say.

- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.

- [ ] **Step 5: Docs** as listed under Files.

- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/EditMode/Bar/barwindow.lua SaftUI-Core/EditMode/Bar/load.xml SaftUI-Core/EditMode/Bar/bar.lua SaftUI-Core/EditMode/Bar/bargroups.lua SaftUI-Core/EditMode/Bar/barchanges.lua SaftUI-Core/EditMode/Bar/historylist.lua tests/lib/shell.lua tests/core/editmode_bar_window_test.lua .agents/edit-mode.md .agents/testing.md README.md
git commit -m "core: let the edit mode bar detach into a floating window"
```

**In-game checks:**
- Detach: a small window with the same controls under Grid and snap, Show and Changes. Drag it by its title: it can't leave the screen.
- Reload: it is floating, where you left it. Dock: the bar is back. Reload: docked.
- Drag it over `/sui`: it sits over `/sui`. The Show list and tooltips still draw over it.
- History opens beside it.
- Change the window size or UI scale with the window near an edge: it stays on screen, crisp.
- Under the Blizzard theme, on both clients, it draws in Blizzard's art.
