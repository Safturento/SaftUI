# SaftUI UI Scaling, Phase 1 (the scale and whole borders) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SaftUI sizes itself to the screen. There are three modes: Automatic (the default), Pixel for pixel (today's) and The game's UI scale. Automatic works from the screen's height against 1440, with a UI size over it. The scale is set at login and again after every display or UI scale change, out of combat only. Every border the theme engine draws is a whole number of pixels at any scale. The owner's 1440p screen stays bit for bit as it is today. Players change the scale in Global settings > General > UI scale or with `/sui scale`, through a 15 second Keep prompt.

**Architecture:**
- **One pure model.** `st.UIScale.Resolve(choice, screen, gameScale)` is in a new `SaftUI-Core/uiscale.lua`. From a choice and a screen it works out k, UIParent's scale, one pixel and the line weight. Nothing else computes a scale.
- **Tokens and helpers.** After every applied change, `UIScale:SetTokens()` measures `st.pixel`, `st.lineWeight` and `st.line` from UIParent. The helpers in `api.lua` read them: `st:GetLineSize(frame)`, `st:RoundToPixel(value, frame, minPixels)`, `st:FloorToPixel`, `st:CeilToPixel` and `st:EvenPixels`.
- **One check.** One frame of Core's hears the three screen events and runs `UIScale:Check()` on the next frame. The check:
  - sets UIParent's scale out of combat, or waits for the end of combat;
  - measures the tokens;
  - on a real change, runs the profile update (`st.Config:UpdateConfig()`) as the pass;
  - then runs the change callbacks (`UIScale:OnChanged`): the plates, edit mode's bar, window, grid and label, and `/sui`'s size.
- **The engine in lines.** Thick and Thin keep a count of lines (2 and 1). Every edge, inset, Thick strip and placement is that many lines in the drawn frame's own units. Under Blizzard, every inset is a whole number of pixels. At k = 1 every number is today's.
- **Settings and recovery.** Global settings > General > UI scale (a Scale select, and a UI size slider that applies on release) and `/sui scale` go through one Keep prompt (`st.UIScalePrompt`). The prompt previews the change, then keeps it or goes back after 15 s. `/sui scale reset` is the way out, with no prompt.

**Tech Stack:** Lua 5.1; the WoW API on WoW Forever (16001) and retail (120000); AceDB-3.0's `global` namespace; SaftUI's options kit (`st.OptionsModel`, `st.OptionsWidgets`, AceConfig tables with SaftUI's `default` field); BackdropTemplate; tests on stubs, run with `tests/run` (`tests/runner.py` over lupa's Lua 5.1).

**Spec:** `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`. Its last section, "Settled with the owner after the draft (2026-11-15)", overrides anything above it:
- Settled 1 approves the design and its 26 calls.
- Settled 2: Automatic for everyone, existing installs included.
- Settled 3: the line weight is `max(1, floor(k + 0.5))`, so lines are 2 pixels from k = 1.5. "High-density screens" means this rule.
- Settled 4: screens under 1080 pixels high take the 1080p size (the floor of 0.75).

This plan covers the spec's Phase 1 only. Phases 2 to 5 get plans of their own.

**Assumed state.**
- `modular` at `12859a99`, with the spec's Settled section added.
- The spec was checked at `f13a2b7`, and its line numbers have drifted. This plan's line numbers are at `12859a99`.
- None of the experiments E0 to E6 is assumed to have been run. "Experiments and seams" says which must come back before which task.

## How the tasks are cut

| # | Task | Needs | Experiments first | Owner can try in game |
| --- | --- | --- | --- | --- |
| 1 | The scale model, its tokens and the pixel helpers | — | — | nothing changes: the same UIParent scale, tokens of 1 |
| 2 | Tests at several scales | 1 | — | nothing (tests only) |
| 3 | Whole borders: the theme engine | 2 | E5 | 1440p unchanged; a simulated 1080p and Mac from `/run`, with whole borders |
| 4 | The scale at login and on every change | 3 | E1, E2, E3 (E4 before its in-game checks) | a size from `/run`; Blizzard's slider set back; the plates |
| 5 | What follows a change: the margin, placements, the plates' size, edit mode, `/sui` | 4 | — | after a size from `/run`: the bar, the grid, the margin |
| 6 | The Keep prompt and `/sui scale` | 4 | — | `/sui scale 90`, Keep, Go back, Esc, the timer, combat, reset |
| 7 | The UI scale section in `/sui`, and its two chat lines | 5, 6 | E0 | Global settings > General > UI scale |
| 8 | Followups, the font demo, and the phase's checklist | 7 | E6 (and E0 for the friends' build) | G1 to G9 |

The tasks run in that order, with one exception: 5 and 6 may run side by side. Task 5 owns `api.lua`, `nameplates.lua`, `EditMode/` and `optionssizes.lua`. Task 6 owns `uiscaleprompt.lua`, `config.lua` and `load.xml`. Both edit `.agents/edit-mode.md`: merge it by hand, keeping both sides.

The friends get Task 8's build and nothing before it. Each earlier task leaves the owner's screen as it is (k = 1) and the addon working on both clients.

## What an existing install sees at upgrade

The friends get the build of Task 8.
- **Every install.** Nothing is saved for anyone yet (`st.config.global.uiScale` is new), so every install starts in Automatic at 100% (Settled 2). No profile holds a scale, so a profile switch, copy, reset or import never changes it.
- **The owner (2560 x 1440).** Nothing changes. UIParent's scale is the same float, and every border, inset, position, margin and plate size is the same. No chat line. The only new things are the UI scale section and `/sui scale`.
- **The 1080p friend.**
  - Size: SaftUI, and everything else under UIParent, draws at 75% of today's pixel size. That is the owner's layout at the share of the screen it has on the owner's.
  - Places: positions keep their anchors and their offsets in units. So every frame stays where it was relative to its anchor, at three quarters of the distance. Nothing leaves the screen or piles up, and frames the friend moved or resized shrink the same way.
  - Look: borders are 1 pixel. Homespun 10 is 7.5 pixels, the size the owner approved.
  - Other frames: Blizzard's own windows and other addons' frames are a quarter smaller too. UIParent at 0.533 is under Blizzard's 0.65 minimum (spec Risk 10).
  - Chat says once per account that SaftUI now sizes itself, "here it draws at 75% of its 1440p size". `/sui scale pixel` brings back exactly today's sizes.
- **The Mac friend (3456 x 2234, if E1 confirms that height).**
  - Size: 155% of today's pixel size. Lines are 2 pixels, so Thick's border is 6. Homespun 10 is 15.5 pixels.
  - Width: UIParent is 2228 units wide, against the owner's 2560. Frames anchored to the left and right edges are each up to 166 units nearer the middle. With the defaults, nothing crosses.
  - The same chat line, at 155%.
- **Anyone who set Blizzard's UI Scale.** SaftUI already overrode it at every login. Now it also sets it back on the next frame after the slider moves, with one chat line a session. To use the slider, choose The game's UI scale.
- **Not whole yet away from k = 1 (phases 2 to 4).** These can draw 0 or 2 pixels wide, or a pixel uneven, until their phase. Nothing else breaks.
  - the options kit's boxes, hairlines and dividers (the Keep prompt's buttons among them);
  - some gaps between frames;
  - the addons' own one-unit lines (spec A4).

## Experiments and seams

Every experiment is run on a build from before Task 4 lands in that player's game, which is the build the friends have now. There are two reasons:
- From Task 4, SaftUI sets UIParent's scale back on the next frame.
- From Task 4, the font demo's scale buttons no longer show the Mac's size.

The controller writes each result into the brief of the task it gates.

| Exp | Who | Before | The one function | As designed | If it says otherwise |
| --- | --- | --- | --- | --- | --- |
| **E5** (layout rounding, texture snapping) | the owner, then each friend | Task 3 | `st:SnapDrawn(frame)` in `theme.lua`, switched by `st.SNAP_DRAWN` | `'round'`: rows 3 and 5 clean while 2 and 4 aren't. The game's layout rounding goes on for every drawn frame and its own regions (call 18). | Every row clean: `'none'`, since texture snapping alone holds the lines. Rows 3 and 5 not clean: `'none'`, and stop. The controller and the owner then add a task that rounds each drawn frame's rect in Lua, before Task 4, and phases 2 and 4 grow. |
| **E3** (who sets UIParent's scale, and when) | the owner | Task 4 | `UIScale:ScheduleCheck()` | One `C_Timer.After(0, ...)` however many events come in a frame. | The engine sets the scale later than the next frame (E3's "1s" line): `UIScale.RECHECK` becomes that many seconds, for a second check. Step 4 (whether SaftUI's own `SetScale` fires the event) changes nothing either way: the comparison and the callbacks cover both. |
| **E1** (the screen as the game sees it) | the owner, both friends | Task 4 | `UIScale.ReadScreen()` and `UIScale.GameScale()` | ReadScreen is `GetPhysicalScreenSize()`, or nil for a height that isn't a positive number. GameScale is `tonumber(uiScale)` while `useUiScale` is `'1'`, else `GetDefaultScale()` where the client has it, else nil. | Render scale moves the physical size: ReadScreen divides by the `RenderScale` setting. `GetDefaultScale()` isn't the game's default: GameScale gives nil while `useUiScale` is off, and switching to The game's UI scale then sets nothing and says it shows after a reload. The Mac's height changes only the worked values, in docs. |
| **E2** (a window) | the owner | Task 4 | `UIScale.ReadScreen()` | The window's drawing size. | The physical size doesn't follow the window: no code changes, since the owner is at k = 1 either way. `.agents/clients.md` records it. |
| **E4** (the scale in combat) | the owner | Task 4's in-game checks (G5, G7) | `UIScale:Check()`'s combat wait | UIParent's `SetScale` waits for the end of combat. | It isn't blocked in combat: nothing changes, since the wait stays (spec E4). G5's in-combat case then only needs no error. |
| **E0** (the new size, seen) | both friends | Task 7, and the friends' build (Task 8) | `UIScale.DEFAULT.size` and `UIScale.SIZE` (Task 1) | 100%; 70% to 150% in steps of 5%. | Both friends name one other percent: `DEFAULT.size` takes it, with the reset's text, the first-login line and the tests. They differ, or the range is too short: the owner decides before Task 7. |
| **E6** (Homespun on the Mac) | the Mac friend (the 1080p friend optional) | Task 8's deletion of the font demo | `FN:UpdateFontConfig` (phase 5's per-face rule) | Fonts follow the scale unrounded. Phase 1 changes no font. | Homespun is rough at 15.5: Task 8 writes a followup for phase 5's rule. Nothing in phase 1 changes. |

## Files shared with work in flight

Branches open today:
- **fb-fontbugs:** `SaftUI-Core/Config/optionscontrols.lua`, `optionslist.lua`, `optionsmenu.lua`, `Media/fonts.lua`, `skinning.lua`, `SaftUI-Bags/`, `.agents/architecture.md`, `edit-mode.md` and `testing.md`.
- **fb-fontfeat:** `Media/fonts.lua`, `Widgets/button.lua`, `SaftUI-ActionBars/`, `SaftUI-Bags/`, `SaftUI-Misc/`, `README.md` and the same three `.agents/` docs.
- **fu-p1:** `SaftUI-Unitframes/nameplates/nameplates.lua`.
- **fu-p2:** `tests/unitframes/nameplate_world.lua`.
- **fu-p4:** `SaftUI-Tracker/window.lua`.
- **fu-p11:** `SaftUI-Chat/chatframe.lua` and `tests/chat/screen_margin_test.lua`.
- **fb-lootpopup and fb-vendor:** no work committed yet. Treat `SaftUI-Loot/popup.lua` and the rest of `Config/options*.lua` as theirs.

Two designs are being written at the same time:
- **A reset on every setting.** It touches every options generator, and General's rows.
- **Colors applied live, with a preview in the color picker.** It touches `Config/optionscolorpicker.lua` and `Media/colors.lua`.

| Task | Shared with branches | Shared with the designs |
| --- | --- | --- |
| 1 | `.agents/architecture.md`, `.agents/testing.md` | — |
| 2 | `.agents/testing.md` | — |
| 3 | `.agents/architecture.md` | `docs/design-system/README.md`, which the colors design may edit |
| 4 | `README.md`, `.agents/architecture.md`, `.agents/testing.md`; `tests/unitframes/nameplate_pixel_test.lua` is on `nameplate_world.lua` (fu-p2) | — |
| 5 | `SaftUI-Unitframes/nameplates/nameplates.lua` (fu-p1), `Config/optionssizes.lua` (the `options*` family), `.agents/edit-mode.md` | — |
| 6 | `README.md`, `.agents/edit-mode.md` | The colors design's preview keeps or goes back too. Nothing is shared in code. |
| 7 | `Config/optionsrange.lua` (the `options*` family), `tests/lib/options_walk.lua`, `.agents/edit-mode.md`, `README.md` | The reset design adds `default` to General's own rows in `general.lua`. The UI scale rows bring their own and sit in a section of their own, so the two land beside each other. |
| 8 | `AGENTS.md`, `README.md`, `.agents/testing.md`, `docs/followups.md` | — |

Where both sides touch a file, merge by hand and keep both. Phase 1 deliberately leaves alone four files the spec names:
- `SaftUI-Bags/container.lua`, because `st.BACKDROP` stays a table (Ruling 12).
- `SaftUI-ActionBars/bars.lua` and `SaftUI-Misc/totemlayout.lua`, which move onto `st:EvenPixels` in phase 4.
- `Media/fonts.lua`, because fonts follow the scale by construction.

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder changes.
- **Privacy.** No account, realm or character name anywhere: code, tests, docs, commits, and experiment results copied into docs.
- **Commits.** Lowercase `module: imperative summary` (`core:`, `unitframes:`, `editmode:`, `options:`, `tests:`, `docs:`). Stage by explicit path, never `git add -A`, `.` or a folder. End with the session's `Co-Authored-By` line.
- **Line endings.** Some working-tree files are CRLF. Never `sed -i`. Edit with the editor, and keep each file's endings (`file <path>`).
- **The owner's screen, bit for bit.** At k = 1 every number is today's:
  - UIParent's scale is `768 / 1440`, the same float (`rawequal`);
  - every edge is 1, every inset 2 or 1, and Thick's strips sit 1 out and are 3 wide;
  - every placement, margin and plate size is as today.

  Each task that touches a number keeps a k = 1 case that pins today's value exactly.
- **Whole pixels.**
  - A size or offset SaftUI hands the game goes through the helpers: `st:RoundToPixel`, `st:FloorToPixel`, `st:CeilToPixel` or `st:EvenPixels`.
  - A line goes through `st:GetLineSize(frame)`, and is never trimmed.
  - A frame centred on an axis is an even number of pixels on that axis.
  - A size read back is rounded, never ceiled.
  - Every new layout gets a `tests/lib/pixels.lua` check (`#P.off(root) == 0`) under Thick, Thin and Blizzard, with `stub.size_noise` at `2 ^ -14`, `-2 ^ -14` and `0`.
- **Combat.**
  - `UIParent:SetScale` is called only from `UIScale:Start()` and `UIScale:Check()`, and only out of combat.
  - Nothing protected is called on a protected frame in combat, `SetRoundLayoutToNearestPixel` and `SetIgnoreParentScale` included. What `st:CanMoveNow` refuses waits for `st:QueueAfterCombat`.
  - SaftUI writes no game setting here: it only reads `useUiScale` and `uiScale`.
  - Every combat case ends with `stub.blocked` empty.
- **Both clients.** Every task's tests run on `T.client('forever')` and `'retail'`. `GetDefaultScale` is read only where it exists. `NOTCHED_DISPLAY_MODE_CHANGED` is registered in `pcall`.
- **Colors and fonts.**
  - Colors go through `st:Color` and `st:ColorRGBA` (`tests/core/color_reads_test.lua`).
  - Fonts go through `st:ApplyFont` and `st:FontObject` (`tests/core/setfont_scan_test.lua`). This includes the Keep prompt's texts.
- **Words.** Sentence case for every name, label, desc and chat line, in American spelling. Name a path with ">": "Global settings > General".
- **Resets.** Per setting (the option's `default` field), never a section's or a page's Reset button.
- **Icons.** Lucide's (`st.icons`), drawn at twice the glyph. An icon-only control has a tooltip. Phase 1 adds no icon.
- **Scripts.** Kit controls take `control.onClick`. `OnEnter` and `OnLeave` are wrapped as `function(self)`, and fired in tests with `true`.
- **The font demo.** `/suifonts` (`SaftUI-Core/Dev/fontdemo.lua`) is deleted in Task 8, after E6 has come back, by the five steps its header lists. Until then nothing in it changes; it is on the `edgeSize` scan's allow-list.
- **Tests.**
  - Each task ends green on `tests/run -j2`, after running single files while working.
  - From Task 2, a task that adds `scaled_test` cases also runs `tests/run --scales=all` on its files.
  - An earlier assertion changes only where this work changes what it pins, and the report lists each one changed.
- **Docs.** Each task updates the docs its files make stale, in the same commit: `AGENTS.md`, `README.md`, the `.agents/*.md` whose `covers:` list its files, and `docs/design-system/`. Then it runs `agents-doc-parity-check` and `readme-freshness-check`. A task that changes `docs/design-system/` says so in its report, so that the controller republishes the Design System artifact.
- **In game.** Each task ends with its owner checklist. Nothing counts as verified until the owner confirms it.

## Review Focus

1. **A scale on a line weight's edge, read back with float noise.** Three cases: 3840 x 2160 at 100% (k is 1.5, and measured from UIParent it is 1.4999999999999998); 5120 x 2880 at 75% (k 1.5); a game scale that gives k 2.49999. They must give two pixel lines, two, and three, never one less because a float landed a hair under the half. Test: Task 1, `'the line weight at its edges, from the choice and from UIParent read back'`.
2. **A login or `/reload` in combat** (`InCombatLockdown()` true in `SaftUI:OnEnable`), in Automatic on a 1080p screen.
   - During combat: no `SetScale`, nothing in `stub.blocked`, and no layout rounding on a protected frame. The modules build at the game's scale.
   - At `PLAYER_REGEN_ENABLED`: one `SetScale`, one pass, and the callbacks once.

   Tests: Task 4, `'login in combat waits for the end of it'`; Task 3, `'SnapDrawn leaves a protected frame alone in combat, and does it after'`.
3. **The engine or Blizzard's slider setting UIParent's scale under SaftUI's.** The conditions: a display change with `stub.engine_resets_scale`; SaftUI's own `SetScale` firing `UI_SCALE_CHANGED` (`stub.scale_fires_event`); ten events in one frame. Expected: one check a frame, the scale back on the next frame, one pass for each real change, and no loop. Tests: Task 4, `"the engine resets the scale, and SaftUI's own SetScale fires the event: no loop"`; Task 7, `"Blizzard's slider: one line a session, only when the setting changed and SaftUI set the scale back"`.
4. **A preview that never ends cleanly.** The cases: a `/reload` or logout while the Keep prompt shows; combat starting while it shows; its timer ending in combat; a second change while it shows. Expected:
   - the next login is at the saved choice;
   - the prompt takes no key in combat;
   - the revert waits for the end of combat;
   - going back returns to the saved choice, not to the first preview.

   Tests: Task 4, `'a preview is never saved: the next login comes back at the saved choice'`; Task 6, `'the prompt through combat'` and `'a second change restarts it for the new choice; going back then returns to the saved choice'`.
5. **A saved choice that isn't one.** `st.config.global.uiScale` holds `true`, `{ mode = 'huge' }`, `{ size = '90' }`, `{ size = 5 }` or `{ mode = 'game', size = 0 }`, from a hand edit or from another version. Each reads as the default, or is held to the range. Nothing errors, nothing is written until the player changes it, and `/sui` shows what is in effect. Tests: Task 1, `'a malformed choice'`; Task 4, `'a malformed save is read, never rewritten'`.

## Rulings on the spec

1. **Files and names.**
   - `SaftUI-Core/uiscale.lua` holds `st.UIScale`: the model, the tokens and the runtime. It loads after `api.lua` in both TOCs, and in the test shell.
   - The pixel helpers live in `api.lua`, beside `st:GetPixelSize`.
   - The Keep prompt has a file of its own, `Config/uiscaleprompt.lua` (`st.UIScalePrompt`), loaded after `general.lua`. It needs the kit's buttons, and it must outlive `/sui`.
   - Two calls are added to the spec's interface: `UIScale.Normalize` (the one reader of a saved choice) and `UIScale:Applied()` (what is in effect, which the rows and `Describe` show).
2. **The line weight comes from a trimmed k.** `UIScale.LineWeight(k)` is `max(1, floor(Trim(k) + 0.5))`, with k trimmed to 1e-4 first: 3840 x 2160 measures k as 1.4999999999999998, and must give 2. The tokens are measured from UIParent (`st:GetPixelSize(UIParent)`), never taken from the choice, so they match what is drawn even while a set waits for combat. Lines (`st.line`, `st:GetLineSize`) are never trimmed.
3. **The snap band is worked in whole pixels:** `abs(H - n * 1440) <= 72`. In floats, the spec's `abs(raw - n) <= 0.05` leaves out the band's own edges, 1368 and 1512 (`0.050000000000000044`). The spec's text and its test list put them in.
4. **The size.**
   - `Normalize`: a choice that isn't a table reads as the default, an unknown mode as `'auto'`, and a size that isn't a number as `DEFAULT.size`.
   - `Resolve` rounds the size to the nearest 5% step from 70% and holds it between 70% and `sizeMax`.
   - `sizeMax` is the largest step at or under `min(150%, H / (auto * 768))`: 768 gives 130%, 863 gives 145% and 864 gives 150%.
   - `Preview` refuses what `Normalize` would have to fix (`'size'`, `'mode'`), so only saved values are forgiven.
5. **The pass never runs in combat.** A check in combat waits whole (`QueueAfterCombat('UIScale')`): no `SetScale`, no tokens and no pass. The spec has steps 3 and 4 run in combat in The game's UI scale. But in combat the profile update prints "Profile changed in combat…", which is the wrong line here, and a scale change in combat is rare (a display change). The plates' pin waits with it. Today they re-pin in combat to whatever UIParent is. In Automatic and Pixel for pixel, SaftUI puts UIParent back after combat, so the pin they keep is the right one. Only in The game's UI scale are they off until the fight ends.
6. **Start runs no pass.** At login nothing is built yet. `Start` sets the scale (or waits for the end of combat), the tokens and its record, and registers the events. It runs in `xpcall`, so an error in it still lets the rest of `OnEnable`, and every module, run.
7. **When the check runs.** `Preview`, `Apply` and `Revert` run the check at once. The events' check is coalesced to the next frame (the E3 seam).
   - `Apply` saves in any state, combat included, since it only writes a table. So `/sui scale reset` in combat saves at once, and the scale follows when the fight ends.
   - `Apply` ends a preview. `Apply(nil)` and `Apply(DEFAULT)` both remove the save.
   - `Preview` is refused in combat.
8. **The shell and the old tests stay pixel for pixel.**
   - The shell sets UIParent through `Resolve({ mode = 'pixel' }, screen)`. It never calls `Start`, whose events would set back the scales the old tests set.
   - The shell gains `st.config.global = {}`, as AceDB has.
   - `set_screen` keeps meaning one unit a pixel. A test opts in to the runtime with `start_uiscale(choice)` (Task 4).
   - `st.scale`, `st.screenWidth` and `st.screenHeight` go in Task 1. The spec names only the shell as a reader of `st.scale`, but three tests read it too; they read `768 / stub.screen_height` instead.
9. **Scaled runs.**
   - The runner gives a scaled run's k as the Lua global `TEST_SCALE`, as it gives `REPO_ROOT`.
   - `SAFTUI_TEST_SCALE`, the spec's variable, set in `tests/run`'s environment, puts every file's scaled run at that scale.
   - A file's scale is `ROTATION[(sum of the bytes of its repo-relative path) % 3 + 1]`.
   - The scaled worlds are 1920 x 1080, 3200 x 1800 and 3456 x 2234, each in Automatic. k = 1 is today's stub screen, 1920 x 1080, in Pixel for pixel.
10. **Phase 1 converts no existing case to `scaled_test`.** The spec says phase 1 converts the theme cases, but no theme test uses the pixel checker. Phase 1's scaled cases are new ones: the theme engine's, the margin's and the plates' size. Each later phase converts its area's layout cases.
11. **Insets.**
    - Thick and Thin: `lines * st:GetLineSize(frame)`, in the drawn frame's units.
    - Blizzard: the kind's art inset in whole pixels. With `n = ThemeArt.Inset(kind)`, the inset is 0 when n is 0, else `max(1, floor(n * k + 0.5))` pixels of the frame. So `small`'s inset of 1 is always its one line. `ThemeArt.Top(kind)` is made whole the same way.
    - The art's own sizes scale with k, unrounded (call 21).
12. **`st.BACKDROP` stays a table.** Every `SetTokens` sets its `edgeSize` and insets to `st.line`, so its one reader (`SaftUI-Bags/container.lua:76`, in flight) needs no change. A frame that took the table before a change keeps the old line until it takes it again: the bags' loading overlay, phase 4c.
13. **E5's seam.** `st:SnapDrawn(frame)`, switched by `st.SNAP_DRAWN` (`'round'` or `'none'`), set from E5 before Task 3 starts.
    - `'round'` turns on the game's layout rounding on the drawn frame and on its own regions, and leaves texture snapping as the game has it. That is exactly what E5's row 3 tests.
    - It never calls `SetRoundLayoutToNearestPixel` on a frame `st:CanMoveNow` refuses. It keeps those, and one queued pass does them when combat ends.
14. **The close button** takes one line on every draw, not only when its look switches. Its pressed cross moves one line down.
15. **Copy.** The spec leaves exact text to the builder, within its gist. Here it is.
    - `Describe`, by mode:
      - Automatic: "This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines."
      - Pixel for pixel: "This screen is 1920 x 1080: SaftUI draws pixel for pixel, at 100% of its 1440p size, with 1 pixel lines."
      - The game's UI scale: "This screen is 2560 x 1440: the game's UI scale draws SaftUI at 120% of its 1440p size, with 1 pixel lines."

      The percent is `floor(k * 100 + 0.5)`, and the screen is `ReadScreen`'s.
    - The first-login line and the slider line are the spec's words, with the percent filled in.
    - The Keep prompt: the title "Keep this UI size?", then "Going back in 15 s." (counting down) or "Goes back when combat ends.", and the buttons "Keep" and "Go back".
    - `/sui scale`'s lines are in Task 6.
16. **The Blizzard slider line** prints when the check sets the scale back in Automatic or Pixel for pixel, and `useUiScale` or `uiScale` reads differently from the check before. That tells a setting change from a display change. Once a session.
17. **The first-login marker** is a version number, `st.config.global.uiScaleNotice = 1`. It is set only when the line is shown, so the owner, at k = 1, gets none, and would still be told on another screen.
18. **The game's UI scale.** Switching to it sets `UIScale.GameScale()` once (the E1 seam). When GameScale gives nil, nothing is set, and chat says the game's size shows after `/reload`.
19. **The notch.** `NOTCHED_DISPLAY_MODE_CHANGED` is registered in `pcall`. It is in both clients' source; a client without it would lose only that event. The notch's stubs (`C_UI`, `stub.notch`) and `GetScreenDPIScale` wait for the phase that reads them: no phase 1 code reads either.
20. **The Keep prompt.**
    - It is not modal: it has no catcher, so clicks elsewhere go through.
    - It stays when `/sui` closes.
    - It takes only Esc, and only out of combat. The kit's `SetPropagateKeyboardInput` is protected in combat, so in combat it takes no key at all.
    - It sits at `FULLSCREEN_DIALOG`, level 9900.
    - It ignores its parent's scale, and takes the default's `uiScale` on every show.
21. **The range applies on release** through a kit field, `applyOnRelease` (`optionsrange.lua`), rather than through a set that waits for the mouse. The kit already tracks the drag (`w.dragging`, `OnMouseUp`), and the field is testable and can be reused.
    - The row's `max` is a number read when the tree is built (`UIScale:Default().sizeMax`), which AceConfig's validator accepts.
    - Every pass rebuilds an open `/sui`, so a new screen's top shows at once.
22. **What follows a change.**
    - The four edit mode handlers keep their own events, and are also given to `UIScale:OnChanged`. E3 may show that SaftUI's own `SetScale` fires no event.
    - The plates' event frame goes, as the spec orders. Their callback is registered when `pixels.lua` loads.
    - `/sui`'s height already follows the margin (`hooksecurefunc(st, 'UpdateScreenMargin', S.ApplyHeight)`, `optionswindow.lua:1536`), and the pass runs `st:UpdateScreenMargin()`.
    - `/sui`'s size gets `OW:FitToScreen()` on the callback. Today `OW.Fits` is checked only when the window opens.
23. **The screen margin** is rounded where it is read, in `st:GetScreenMargin`. The reach is added as it is: phase 2 rounds `/sui`'s metal reach. `OW.MaxWidth` reads the margin itself, and stays unrounded until phase 2.
24. **`UF.PlateDriverSize`** counts pixels with `st:GetPixelSize(UIParent)`, which is 1 at k = 1, so today's floats come out to the bit.
25. **The login order test.** It reads `init.lua`'s source, since AceAddon isn't loaded in the test worlds. It proves the rest by running `InitializeAceConfig`, `Start` and a module's enable, in that order, on the real AceDB.
26. **The pass** is `st.Config:UpdateConfig()` wherever Config has one; the shell's Config has none. The callbacks run either way.

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/uiscale.lua` (new) | the model and tokens; `st.BACKDROP`'s line; the start, the check, the interface; the two chat lines | 1, 3, 4, 7 |
| `SaftUI-Core/api.lua` | the pixel helpers; the margin and `st:PlaceAtPosition` rounded | 1, 5 |
| `SaftUI-Core/constants.lua`, `init.lua`, both Core TOCs | the screen constants go; the login order; the file's line; the demo's line | 1, 4, 8 |
| `SaftUI-Core/theme.lua`, `themeart.lua`, `panels.lua` | the engine in lines; `st:SnapDrawn`; the close button | 3 |
| `SaftUI-Unitframes/nameplates/pixels.lua`, `nameplates.lua` | the plates pinned from the callback; the driver's even pixels | 4, 5 |
| `SaftUI-Core/EditMode/Bar/bar.lua`, `barwindow.lua`, `coordinates.lua`, `settings.lua` | follow the callback | 5 |
| `SaftUI-Core/Config/optionssizes.lua` | `OW:FitToScreen` | 5 |
| `SaftUI-Core/Config/uiscaleprompt.lua` (new), `load.xml`, `config.lua` | the Keep prompt; `/sui scale` | 6 |
| `SaftUI-Core/Config/general.lua`, `optionsrange.lua` | the UI scale section; `applyOnRelease` | 7 |
| `SaftUI-Core/Dev/`, `Media/Fonts/Candidates/` | deleted | 8 |
| `tests/runner.py`, `tests/lib/harness.lua`, `shell.lua`, `pixels.lua`, `tests/wow/game.lua`, `widgets.lua` | the scale model in tests; scaled runs; stubs | 1, 2, 4 |
| `tests/core/uiscale_test.lua`, `theme_scale_test.lua`, `uiscale_runtime_test.lua`, `uiscale_prompt_test.lua` (new) | the tests | 1, 3, 4, 6 |

---

### Task 1: The scale model, its tokens and the pixel helpers

**Files:**
- Create: `SaftUI-Core/uiscale.lua`.
- Modify:
  - `SaftUI-Core/SaftUI-Core_Forever.toc` and `SaftUI-Core_Mainline.toc`: `uiscale.lua` on the line after `api.lua`.
  - `SaftUI-Core/constants.lua:14-15`: `st.screenWidth`, `st.screenHeight` and `st.scale` go.
  - `SaftUI-Core/init.lua:13`: `UIParent:SetScale(st.scale)` becomes `st.UIScale:Start()`, in the same place.
  - `SaftUI-Core/api.lua:26-49`: `st:RoundToPixel` gains `minPixels`. `st:GetLineSize`, `st:FloorToPixel`, `st:CeilToPixel` and `st:EvenPixels` go beside it.
- Test:
  - Create `tests/core/uiscale_test.lua`, on the shell.
  - Modify:
    - `tests/lib/shell.lua`: load `uiscale.lua` after `api.lua`. Set UIParent's scale from `Resolve` in Pixel for pixel, then call `SetTokens`. Add `st.config.global = {}`, `use_scale(k)` and `SCALE_SCREENS`, and update the header's list.
    - `tests/core/editmode_helpers.lua:20-23`: `set_screen` goes through `Resolve` in Pixel for pixel, then `SetTokens`.
    - `tests/lib/pixels.lua`: edges are measured in pixels.
    - `tests/lib/harness_self_test.lua`: the shell's Core files, and `P.off` at 0.75.
    - `tests/core/options_resize_test.lua:318` and `tests/unitframes/nameplate_pixel_test.lua:122,515,518`: `st.scale` becomes `768 / stub.screen_height`.
- Docs:
  - `.agents/architecture.md`: `covers:` gains `'SaftUI-Core/uiscale.lua'`. Core's helpers list gains the helpers and `st.UIScale.Resolve`. "Half pixels from centred anchors" speaks of pixels, not units, and names `st:EvenPixels`. `constants.lua`'s sentence drops the screen constants.
  - `.agents/clients.md`, which covers `constants.lua`: nothing reads the screen at file load.
  - `.agents/testing.md`: the shell's scale (Pixel for pixel through `Resolve`), `use_scale`, `set_screen`, and `P.off` in pixels. The `tests/core/` row gains `uiscale_test.lua`.
  - `AGENTS.md`: Core's row names `uiscale.lua`, the scale model.

**Interfaces:**
- Produces:

```lua
-- SaftUI-Core/uiscale.lua
local UIScale = {}
st.UIScale = UIScale
UIScale.DESIGN_HEIGHT = 1440
UIScale.SNAP = 72                                  -- pixels either side of a whole multiple of 1440 (5%)
UIScale.FLOOR = 0.75                               -- the automatic part's least
UIScale.SIZE = { min = 0.70, max = 1.50, step = 0.05 }
UIScale.MODES = { 'auto', 'pixel', 'game' }        -- the Scale select's order
UIScale.DEFAULT = { mode = 'auto', size = 1 }      -- E0 may change size
st.pixel, st.lineWeight, st.line = 1, 1, 1         -- at file load, until the first SetTokens
```

  - `UIScale.ReadScreen() -> { width, height } | nil`: the E1 and E2 seam (`GetPhysicalScreenSize()`).
  - `UIScale.Normalize(choice) -> { mode, size }`: a fresh table, by Ruling 4. It never writes.
  - `UIScale.Resolve(choice, screen, gameScale) -> resolved | nil`. `resolved` is `{ mode, auto, size, k, uiScale, pixel, lineWeight, line, width, height, unitsWide, unitsTall, sizeMax }`. It gives nil with no screen, or in `'game'` without a positive `gameScale`. The algorithm the signature leaves open:

```lua
-- H, W from screen; n = floor(H / 1440 + 0.5)
-- auto = (n >= 1 and abs(H - n * 1440) <= UIScale.SNAP) and n or H / 1440   -- Ruling 3; n stays an integer
-- auto = max(auto, UIScale.FLOOR)
-- sizeMax, size: Ruling 4
-- k: 'auto' -> auto * size; 'pixel' -> 1; 'game' -> gameScale * H / 768
-- uiScale: 'auto' and 'pixel' -> (768 / H) * k (k the integer 1 at 1440: the float 768 / 1440); 'game' -> gameScale
-- pixel = 1 / k; lineWeight = UIScale.LineWeight(k); line = lineWeight * pixel
-- unitsTall = 768 / uiScale; unitsWide = W * unitsTall / H
```

  - `UIScale.LineWeight(k) -> integer`, by Ruling 2.
  - `UIScale:SetTokens() -> pixel, lineWeight, line`, measured: `st.pixel = st:GetPixelSize(UIParent)`, `st.lineWeight = UIScale.LineWeight(1 / st.pixel)`, `st.line = st.lineWeight * st.pixel`. With no screen, the tokens are left as they are.
  - `UIScale:Start()`, as it is in Task 1: `UIParent:SetScale(UIScale.Resolve({ mode = 'pixel' }, UIScale.ReadScreen()).uiScale)`, then `SetTokens()`. With no screen, nothing. Task 4 replaces the body.
  - `st:GetLineSize(frame) -> number | nil` is `st.lineWeight * st:GetPixelSize(frame)`, never trimmed.
  - `st:RoundToPixel(value, frame, minPixels) -> number`: as today, except that a non-zero value under `minPixels` pixels gives `minPixels` pixels, with its sign kept.
  - `st:FloorToPixel(value, frame)` and `st:CeilToPixel(value, frame) -> number`: to the whole pixel below or above. A value within 1e-6 of a pixel stays on it. Trimmed as `RoundToPixel` trims.
  - `st:EvenPixels(value, frame) -> number`: round to the nearest whole pixel, then add one when that is odd, counting as `EvenIfCentred` counts; trimmed.
  - Shell: `SCALE_SCREENS = { [0.75] = { 1920, 1080, 'auto' }, [1] = { 1920, 1080, 'pixel' }, [1.25] = { 3200, 1800, 'auto' }, [1.55] = { 3456, 2234, 'auto' } }`. `use_scale(k) -> resolved` sets the screen, UIParent's scale and the tokens on the current world and resets nothing; any other k is an error.

- [ ] **Step 1: Write the failing tests** (in `tests/core/uiscale_test.lua`, unless named)

```lua
test('Resolve over the worked values', function()
	-- each { W, H } -> k, uiScale, unitsWide x unitsTall, pixel, lineWeight (near 1e-9 unless said):
	-- 1366x768 0.75, 0.75, 1821.33x1024, 4/3, 1 | 1920x1080 0.75, 768/1440, 2560x1440, 4/3, 1
	-- 1920x1200 0.8333, 2304x1440 | 2560x1377 1 (snap), 768/1377, 2560x1377 | 3440x1440 1, 3440x1440
	-- 2560x1600 1.1111, 0.9 | 3024x1964 1.3639, 1 | 3456x2234 1.5514, 2227.6x1440, 2 | 3840x2160 1.5, 2 | 5120x2880 2, 2
end)
test("the owner's 1440p is today's float: uiScale rawequal 768 / 1440, k the integer 1, pixel and line exactly 1", ...)
test('Pixel for pixel is k 1 and 768 / H on any screen, to the bit', ...)
test('the snap band in whole pixels: 1367 and 1513 unsnapped, 1368 and 1512 at 1, 2808 and 2952 at 2, 2807 unsnapped', ...)
test('the floor: 768 and 900 high are 0.75', ...)
test('the UI size: 0.69 is 0.70, 1.6 is 1.50, 0.93 is 0.95; sizeMax 1.30 at 768 high, 1.45 at 863, 1.50 at 864 and 1080', ...)
test("The game's UI scale: 0.64 at 1440 high is k 1.2 with 1 pixel lines; 1.15 at 2160 is k 3.234 with 3; no game scale is nil", ...)
test('a malformed choice (Review Focus 5)', function()
	-- Normalize(true), Normalize(nil), Normalize('auto') -> { mode = 'auto', size = 1 }
	-- { mode = 'huge' } -> 'auto'; { size = '90' } -> 1; Resolve({ size = 5 }, ...).size -> 1.5; { mode = 'game', size = 0 }.size -> 0.7
	-- the table passed in is unchanged (same keys, same values)
end)
test('a screen with no height: ReadScreen and Resolve give nil, Start and SetTokens leave everything as it is', ...)
test('the line weight at its edges, from the choice and from UIParent read back (Review Focus 1)', function()
	-- LineWeight(1.4999999999999998) == 2; LineWeight(1.49) == 1; LineWeight(2.49999) == 3; LineWeight(0.525) == 1
	-- Resolve({ mode = 'auto', size = 0.75 }, 5120x2880).lineWeight == 2 (k 2 * 0.75)
	-- a world at 3840x2160 with UIParent at (768 / 2160) * 1.5: SetTokens() -> lineWeight 2
end)
test('the tokens: 1, 1, 1 at load and at k 1; at 0.75 pixel 4/3 and line == pixel; at 1.55 line == 2 * pixel', ...)
test('the helpers at 0.75 and on a frame with a scale of its own; at k 1 every one is today\'s whole number', function()
	-- at 0.75: GetLineSize(UIParent) 4/3; a frame at SetScale(0.8): (4/3) / 0.8
	-- RoundToPixel(0.3) == 0, RoundToPixel(0.3, nil, 1) == 4/3, RoundToPixel(0, nil, 1) == 0, RoundToPixel(-0.3, nil, 1) == -4/3
	-- FloorToPixel(2) == 4/3, CeilToPixel(2) == 8/3, FloorToPixel(8/3 - 1e-9) == 8/3; EvenPixels(45) == 34 px (45.3333)
	-- at k 1: EvenPixels(45) == 46, EvenPixels(44) == 44, RoundToPixel(5) == 5, FloorToPixel(5) == 5 (rawequal)
end)
test('use_scale(k): each k gives its screen and Resolve\'s k, without resetting the world; another k errors', ...)
-- tests/lib/harness_self_test.lua
test('the shell sets UIParent pixel for pixel through Resolve: 768 / 1080, the tokens 1; set_screen(2560, 1440) is 768 / 1440', ...)
test('P.off measures pixels: at 0.75 a frame at 4/3 units is whole and one at 1 unit is not; at k 1 as before', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/uiscale_test.lua tests/lib/harness_self_test.lua`. Expected: FAIL, `st.UIScale` is nil.
- [ ] **Step 3: Implement** what the Interfaces say, and update the three tests that read `st.scale`. A `P.off` case that set UIParent to a scale other than `768 / H` now measures pixels rather than units. None is expected: the two cases at 0.71 check offsets, not `P.off`. List any found in the report.
- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs**, as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/uiscale.lua SaftUI-Core/SaftUI-Core_Forever.toc SaftUI-Core/SaftUI-Core_Mainline.toc SaftUI-Core/constants.lua SaftUI-Core/init.lua SaftUI-Core/api.lua tests/core/uiscale_test.lua tests/lib/shell.lua tests/core/editmode_helpers.lua tests/lib/pixels.lua tests/lib/harness_self_test.lua tests/core/options_resize_test.lua tests/unitframes/nameplate_pixel_test.lua .agents/architecture.md .agents/clients.md .agents/testing.md AGENTS.md
git commit -m "core: work out the UI scale from one model, with pixel and line tokens and helpers"
```

**In-game checks:**
- On both clients, log in with no Lua errors.
- G1, first part: `/run print(UIParent:GetScale(), 768/1440)` prints the same number twice. `/run print(SaftUI.pixel, SaftUI.lineWeight, SaftUI.line)` prints `1 1 1`.
- A screenshot of one scene from before this build and one from after, compared: nothing moved.

---

### Task 2: Tests at several scales

**Files:**
- Modify:
  - `tests/runner.py`: the scaled run, the rotation, `--scales=all`, `SAFTUI_TEST_SCALE`, `FIXTURE_EXPECTED`.
  - `tests/lib/harness.lua`: `scaled_test`, `test_scale`, `run_file(path, shown, scale)` and `result.scaled`.
  - `tests/lib/shell.lua`: at load, `use_scale(TEST_SCALE)` when the runner gave one.
  - `tests/lib/harness_self_test.lua`.
- Create:
  - `tests/lib/runner_fixtures/scaled_ok.lua`: one `test` and one `scaled_test` checking `test_scale()`.
  - `tests/lib/runner_fixtures/scaled_fail_155.lua`: a scaled case that fails only at 1.55.
- Docs: `.agents/testing.md`.
  - Running the suite: the scaled run, the rotation, `--scales=all` and the variable.
  - Writing tests: when a case is a `scaled_test`. It asserts whole pixels, no overlap, inside its window or fixed corners, and never a number of units.
  - The `tests/lib/` rows.

**Interfaces:**
- Consumes: Task 1's `use_scale(k)` and `SCALE_SCREENS`.
- Produces:
  - `scaled_test(name, fn)`: a case of the file's normal run (k = 1, as `test` is), run again in the file's scaled run. Its names share `test`'s namespace.
  - `TEST_SCALE`: the global the runner sets in a scaled run's Lua state (0.75, 1.25 or 1.55); nil in a normal run. `test_scale() -> k` gives 1 when it is nil.
  - The shell: while `TEST_SCALE` is set, every world (`reset_world`, `use_client`) is built at `use_scale(TEST_SCALE)`.
  - `run_file(path, shown, scale)`: with a scale, only the scaled cases run. Every result carries `scaled`, the file's number of scaled cases.
  - The runner:
    - after a file's normal run, when `scaled > 0`, it runs the file again at its scale, by Ruling 9. Under `--scales=all`, it runs it at each of the three;
    - a scaled case is reported as `<name> [at 0.75]` and counted in the totals;
    - `--timings` adds the scaled runs' seconds to the file's;
    - an unknown value of `SAFTUI_TEST_SCALE` exits 2, as a bad `-j` does.

- [ ] **Step 1: Write the failing tests and fixtures**

```lua
-- tests/lib/harness_self_test.lua
test('test_scale() is 1 in a normal run, and the world is at k 1', ...)
test('scaled_test registers a case of the normal run; a name test() already took errors', ...)
-- tests/lib/runner_fixtures/scaled_ok.lua: test('plain') checks test_scale() == 1;
--   scaled_test('scaled') checks st.UIScale.Resolve's k for SCALE_SCREENS[test_scale()] equals the world's
-- tests/lib/runner_fixtures/scaled_fail_155.lua: scaled_test('fails at 1.55') checks test_scale() ~= 1.55
-- runner.py FIXTURE_EXPECTED:
--   scaled_ok: exit 0, both cases, and the scaled case again as 'scaled [at <its rotation scale>]'
--   scaled_ok with --scales=all: exit 0, '[at 0.75]', '[at 1.25]' and '[at 1.55]'
--   scaled_fail_155 with --scales=all, and with SAFTUI_TEST_SCALE=1.55: exit 1, naming '[at 1.55]'
--   scaled_fail_155 with SAFTUI_TEST_SCALE=0.75: exit 0
--   SAFTUI_TEST_SCALE=2: exit 2
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run --self-check` and `tests/run tests/lib/harness_self_test.lua`. Expected: FAIL, `scaled_test` is not defined.
- [ ] **Step 3: Implement** what the Interfaces say.
- [ ] **Step 4: Run** `tests/run --self-check`, then `tests/run -j2`. Expected: PASS. The case count is unchanged: no real file has a scaled case yet.
- [ ] **Step 5: Docs**, as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add tests/runner.py tests/lib/harness.lua tests/lib/shell.lua tests/lib/harness_self_test.lua tests/lib/runner_fixtures/scaled_ok.lua tests/lib/runner_fixtures/scaled_fail_155.lua .agents/testing.md
git commit -m "tests: run each file's scaled cases again at one other UI scale"
```

**In-game checks:** none. This task changes only tests.

---

### Task 3: Whole borders: the theme engine

Before starting, the controller writes E5's outcome into this task's brief: `st.SNAP_DRAWN = 'round'` or `'none'`. If rows 3 and 5 were not clean, the task lands with `'none'`, and the task E5 then calls for goes into this plan before Task 4.

**Files:**
- Modify:
  - `SaftUI-Core/theme.lua`:
    - `INSETS` (`:67`) becomes `LINES = { thick = 2, thin = 1 }`, and `st:ResolveTheme` (`:94-131`) gives `look.lines` and `look.inset`;
    - one local `InsetIn(look, kind, frame)`, which `Record` (`:231`) and `Redraw` (`:664`) use to record the inset in the drawn frame's units;
    - `Paint` (`:405-445`) draws `edgeSize` one line and the insets `InsetIn` of the frame;
    - `CreateAltBorder` (`:318-349`) only makes the four strips, and a new local `LayAltBorder(frame, line)` anchors and sizes them on every Thick draw: one line outside the frame, three lines wide;
    - `Placement(look, kind, owner)` (`:450`) puts the backdrop `lines` lines of the owner's outside it, and under Blizzard its top at `ThemeArt.Top(kind)` in whole pixels;
    - `st:SnapDrawn(frame)` and `st.SNAP_DRAWN`, after every `Paint`.
  - `SaftUI-Core/themeart.lua:590-606`: `ThemeArt.Paint`'s edge is one line of the frame's. Its insets come from `st:DrawnInset(frame)` (the record `theme.lua` just made), and its top is `ThemeArt.Top(kind)` in whole pixels.
  - `SaftUI-Core/uiscale.lua`: `SetTokens` also sets `st.BACKDROP.edgeSize` and its four insets to `st.line`.
  - `SaftUI-Core/panels.lua:330-410`: in the close button's `Draw`, its backdrop and its dark line (`outline`) take one line of `close`'s on every draw. The backdrop is set again only when the line changed. The pressed cross moves one line down.
- Test:
  - Create `tests/core/theme_scale_test.lua`.
  - Modify `tests/core/theme_kinds_test.lua`: the `edgeSize` scan.
- Docs:
  - `.agents/architecture.md`, Themes, "The engine": insets as lines and `look.lines`; `st:DrawnInset` in the frame's own units, whole pixels; Thick's strips laid on each draw; `st:SnapDrawn` and E5; Blizzard's insets in whole pixels.
  - `.agents/testing.md`: the `tests/core/` row gains `theme_scale_test.lua`; the scan and its allow-list.
  - `docs/design-system/tokens.json`: `line-width` becomes "one line: `lineWeight` pixels (1 up to k 1.49, 2 from 1.5)", `mark-width` "two lines", and `thick-width` "three lines".
  - `docs/design-system/README.md:58`, "Whole pixels": round in pixels, not units, through the helpers; draw lines with `st:GetLineSize`.

**Interfaces:**
- Consumes: Task 1's `st.line`, `st.lineWeight`, `st:GetLineSize`, `st:GetPixelSize` and `use_scale(k)`; Task 2's `scaled_test`.
- Produces:
  - `st:ResolveTheme(...) -> { name, lines, inset, alpha, colors, kind }`. `lines` is 2 for Thick, 1 for Thin and nil for Blizzard. `inset` is in UIParent's units: `lines * st.line`, or under Blizzard the kind's art inset in whole pixels (Ruling 11).
  - `st:ThemeInset(theme, background, kind)` keeps its signature and gives that `inset`.
  - `st:DrawnInset(frame)` is in the frame's own units and a whole number of its pixels.
  - `st:SnapDrawn(frame)` and `st.SNAP_DRAWN`, by Ruling 13. They run after every draw and redraw.
  - `st.BACKDROP.edgeSize` and `st.BACKDROP.insets.*` equal `st.line` after every `SetTokens`.

- [ ] **Step 1: Write the failing tests** (in `tests/core/theme_scale_test.lua`, unless named)

```lua
test("k 1: today's numbers exactly, for every kind under Thick, Thin and Blizzard, on both clients", function()
	-- rawequal, never near: edgeSize 1; insets 2 (Thick), 1 (Thin), ThemeArt.Inset(kind) (Blizzard); small's edge 1
	-- Thick's LEFT strip: TOPLEFT -1, 1, BOTTOMLEFT -1, -1, width 3 (and the other three likewise)
	-- the backdrop: TOPLEFT -2, 2 and BOTTOMRIGHT 2, -2 (Thick), 1 (Thin); top ThemeArt.Top(kind) under Blizzard
	-- st:DrawnInset(owner) 2, 1, ThemeArt.Inset(kind); st:ThemeInset('thick', 'theme', 'panel') == 2
	-- st.BACKDROP: edgeSize 1, insets 1; the close button's edge 1 and its dark line 1 outside it
end)
test("k 0.75, 1.25 and 1.55: one-line edges, insets in lines, the strips one line out and three wide, placement in the owner's lines", function()
	-- for each k (use_scale) and each kind under Thick and Thin:
	--   edgeSize == st:GetLineSize(backdrop); insets == look.lines * that
	--   strip offset == line, width == 3 * line; the backdrop look.lines * st:GetLineSize(owner) outside the owner
	-- at 1.55: line == 2 * st.pixel, and Thick's three lines are 6 pixels (3 * edgeSize * k, near 1e-9)
end)
test("Blizzard's kinds: each inset a whole number of pixels at every k, small's one line", ...)
test('a frame with a scale of its own draws in its own lines, and records its inset in its own units', function()
	-- frame:SetScale(0.8) (a list matched to its owner): edgeSize == st.lineWeight * st:GetPixelSize(frame)
end)
test('a redraw after a scale change draws every frame at the new line weight; a backdrop its caller placed stays put', ...)
scaled_test('every kind drawn on a whole-pixel owner has its edges, strips and backdrop on whole pixels', function()
	-- P.off(owner) == 0 under Thick, Thin and Blizzard, with stub.size_noise 2 ^ -14, -2 ^ -14 and 0
end)
test('the close button: its edge and dark line one line, its pressed cross one line down, back from Blizzard too', ...)
test('st.BACKDROP takes one line on every SetTokens', ...)
test("SnapDrawn 'round': the drawn frame and its own regions round their layout; texture snapping is left as it was", ...)
test("SnapDrawn 'none': nothing is rounded", ...)
test('SnapDrawn leaves a protected frame alone in combat, and does it after (Review Focus 2)', function()
	-- a protected owner drawn in combat: #stub.blocked == 0; PLAYER_REGEN_ENABLED: rounded once
end)
-- tests/core/theme_kinds_test.lua
test('no literal edgeSize = 1 outside the allow-list, and nothing on the list without one', function()
	-- over T.saftui_files() with L.Lex's mask; the allow-list, each with its phase:
	--   SaftUI-Core/Config/optionslook.lua 3 (phase 2), Config/optionscolorpicker.lua 2 (phase 2), Dev/fontdemo.lua 1 (Task 8)
end)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/theme_scale_test.lua tests/core/theme_kinds_test.lua`. Expected: FAIL. At 0.75 the edge is 1 unit, not one line; `look.lines` is nil.
- [ ] **Step 3: Implement** what the Interfaces and Rulings 11 to 14 say.
- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes tests/misc`, then `tests/run --scales=all tests/core/theme_scale_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs**, as listed under Files. The report says `docs/design-system/` changed.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/theme.lua SaftUI-Core/themeart.lua SaftUI-Core/uiscale.lua SaftUI-Core/panels.lua tests/core/theme_scale_test.lua tests/core/theme_kinds_test.lua .agents/architecture.md .agents/testing.md docs/design-system/tokens.json docs/design-system/README.md
git commit -m "core: draw every theme border in whole lines of the frame's own pixels"
```

**In-game checks:**
- G1: the same scene at 1440p, under Thick, Thin and Blizzard, compared with Task 1's screenshots. No border moved or changed width.
- A simulated 1080p, out of combat: `/run UIParent:SetScale(768/1440*0.75) SaftUI.UIScale:SetTokens() SaftUI:ThemeChanged()`. Under Thick, Thin and Blizzard, every border the theme draws is one pixel on every side: unit frames, action bars, bags, the minimap, the tooltip, and `/sui`'s window frame and panels. The kit's boxes and hairlines may not be yet (phase 2). `/reload` puts everything back.
- The Mac, simulated the same way with `*1.5514`: two-pixel borders, and Thick's is 6 pixels.
- A `/reload` in combat with a training dummy: no "Interface action failed".

---

### Task 4: The scale at login and on every change

**Files:**
- Modify:
  - `SaftUI-Core/uiscale.lua`: the runtime, below.
  - `SaftUI-Core/init.lua`: `SaftUI:OnEnable` runs `self:GetModule('Config'):InitializeAceConfig()`, then `xpcall(st.UIScale.Start, geterrorhandler(), st.UIScale)`, then the rest as now. No `SetScale` is left in it.
  - `SaftUI-Unitframes/nameplates/pixels.lua:89-102`: the event frame goes. `st.UIScale:OnChanged(...)` pins every plate (`UF:ForEachPlate(function(frame) UF:PinPlateScale(frame) end)`) and runs `UF:ApplyPlateSize()`. The header's comment says so.
  - `README.md:17`, Installation.
- Test:
  - Create `tests/core/uiscale_runtime_test.lua`, on `core/config_helpers.lua`'s real AceDB.
  - Modify:
    - `tests/wow/game.lua`: `useUiScale = '0'` and `uiScale = '1'` in `stub.cvars`; `GetDefaultScale()`, giving `stub.default_scale` (1); `stub.change_display(width, height)`, which sets the screen, sets UIParent to the game's own value while `stub.engine_resets_scale`, and fires `DISPLAY_SIZE_CHANGED` (and `UI_SCALE_CHANGED` when it reset the scale).
    - `tests/wow/widgets.lua`: in combat, UIParent's `SetScale` from a SaftUI file (found as `refuse_measure` finds its caller) is refused into `stub.blocked` as `{ UIParent, 'SetScale' }`, while a test's own call still sets it; `UIParent:IsProtected()` is true in combat; `SetScale` on UIParent fires `UI_SCALE_CHANGED` at once while `stub.scale_fires_event`.
    - `tests/lib/shell.lua`: `start_uiscale(choice)`.
    - `tests/lib/harness_self_test.lua`: those stubs.
    - `tests/unitframes/nameplate_pixel_test.lua`: the two cases that fired the screen events (`:454-510`) start the scale and change it instead.
- Docs:
  - `.agents/architecture.md`:
    - a new section, "The UI scale": `st.UIScale`; the choice and the marker in `st.config.global`; the order at login; the check and its steps; the pass; `OnChanged` and who listens; the three modes;
    - "Account-wide saved values" gains `uiScale` and `uiScaleNotice`;
    - Nameplates' "Whole pixels" bullet: the plates pin from the change callback, and its last sentence (the scale is SaftUI's from login only) goes.
  - `.agents/taint.md`: `covers:` gains `'SaftUI-Core/uiscale.lua'`. Rule 6: `UIParent:SetScale` is protected in combat (inferred; E4). Only the check calls it, out of combat. A change in combat waits for the end of it, and the pass never runs in combat.
  - `.agents/clients.md`: a "Screen and UI scale" part, with the spec's F2 to F10 as facts, each marked confirmed or inferred, and E1 to E5's results as they came back.
  - `.agents/testing.md`: the new stubs and `start_uiscale`.
  - `AGENTS.md`: Core's row calls `uiscale.lua` the scale interface.
  - `README.md:17`: "SaftUI sizes itself to your screen: it is laid out for a screen 1440 pixels high and drawn at the same share of yours, with every line on whole pixels. It sets Blizzard's UI Scale setting back after it moves." Task 7 adds where to choose the game's UI scale instead.
  - `docs/design-system/tokens.json`, the `size` note: "One unit is a pixel of a 1440p screen. SaftUI scales it to the screen (`st.UIScale`)." And `docs/design-system/README.md:3`, to match.
  - `docs/followups.md`: move "2026-11-11 — UIParent's scale is set once, at login, so plates leave whole pixels after a UI scale or display change" to Resolved, with "**Resolved 2026-11-15:** the scaling design's phase 1, Task 4. UIParent's scale is set again on every change, and the plates pin after it, from `UIScale:OnChanged`." Update both ToC links.

**Interfaces:**
- Consumes: Task 1's model and tokens; Task 3's redraw, which the pass runs.
- Produces:

```lua
UIScale.EVENTS = { 'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED', 'NOTCHED_DISPLAY_MODE_CHANGED' }
UIScale.RECHECK = nil   -- E3: seconds to a second check, nil for none
```

  - `UIScale:Start()`:
    - reads the saved choice and resolves it on `ReadScreen()`;
    - in `'auto'` and `'pixel'`, sets `UIParent:SetScale(uiScale)`, unless in combat, when it queues the check instead. In `'game'` it sets nothing;
    - runs `SetTokens()` and records what it applied. It runs no pass and no callbacks;
    - registers `EVENTS` on its own frame (the third in `pcall`), each running `ScheduleCheck()`.
  - `UIScale:Saved() -> choice | nil`: `Normalize(st.config.global.uiScale)` when that is a table, else nil. It never writes.
  - `UIScale:Current() -> choice`: the preview's, else `Saved()`, else `Normalize(DEFAULT)`. A copy.
  - `UIScale:Default() -> resolved | nil` is `Resolve(DEFAULT, ReadScreen())`. `UIScale:Applied() -> resolved | nil` is what the last finished check applied. `UIScale:IsPreviewing() -> boolean`.
  - `UIScale:Preview(choice) -> ok, why`:
    - why is `'combat'`, `'size'`, `'mode'` or `'screen'` (Ruling 4);
    - on success it keeps the choice in effect before the first preview, for `Revert`, makes the new choice current, and runs `Check()`.
  - `UIScale:Apply(choice | nil) -> ok, why`: by Ruling 7. In combat it gives `true, 'combat'`. The saved table is exactly `{ mode, size }`.
  - `UIScale:Revert() -> ok`: ends a preview and runs `Check()`.
  - `UIScale:Describe(resolved) -> string`, by Ruling 15.
  - `UIScale:OnChanged(fn)`: `fn(resolved)` runs after every pass, in the order the functions were registered, each in `xpcall` to `geterrorhandler()`.
  - `UIScale:ScheduleCheck()`: the E3 seam.
  - `UIScale.GameScale() -> number | nil`: the E1 seam.
  - `UIScale:Check()`:
    1. `Resolve(Current(), ReadScreen(), UIParent:GetScale())`. Nil: return.
    2. In combat: `st:QueueAfterCombat('UIScale', ...)` with the check, then return (Ruling 5).
    3. In `'auto'` and `'pixel'`, when `abs(UIParent:GetScale() - uiScale) > 1e-5`: `UIParent:SetScale(uiScale)`. Just switched to `'game'`: `UIParent:SetScale(GameScale())` once (Ruling 18).
    4. `SetTokens()`. Then, when UIParent's scale, the pixel or the line weight differs from `Applied()`'s: the pass (Ruling 26), then the `OnChanged` functions. Otherwise only `st:UpdateScreenMargin()`.
  - Shell: `start_uiscale(choice)` saves `choice` (when given) into `st.config.global.uiScale`, then runs `st.UIScale:Start()`.

- [ ] **Step 1: Write the failing tests** (in `tests/core/uiscale_runtime_test.lua`, unless named)

```lua
test('SaftUI:OnEnable makes the AceDB, then starts the scale, before any module', function()
	-- init.lua's source: 'InitializeAceConfig' before 'UIScale.Start', and no 'SetScale' in the file
	-- 2560x1440, global.uiScale = { mode = 'auto', size = 1.25 }, Start(): UIParent (768 / 1440) * 1.25 (near 1e-12), st.pixel 0.8
	-- a module enabled after reads st.pixel 0.8
end)
test("the owner's screen: UIParent rawequal 768 / 1440, the tokens exactly 1, no pass, no callback", ...)
test('login in combat waits for the end of it (Review Focus 2)', function()
	-- 1920x1080, stub.in_combat: Start() leaves UIParent's scale; #stub.blocked == 0; no pass
	-- PLAYER_REGEN_ENABLED: UIParent 768 / 1440 (near 1e-12), one pass, the callbacks once
end)
test('the check: once a frame however many events; nothing set when equal; nothing set in The game\'s UI scale', ...)
test('a display change in Automatic: no SetScale, one pass, the callbacks with the new line weight', function()
	-- 2560x1440 -> stub.change_display(3840, 2160): SetScale not called; st.lineWeight 2; 1 pass; the callback's resolved.lineWeight 2
end)
test("the engine resets the scale, and SaftUI's own SetScale fires the event: no loop (Review Focus 3)", function()
	-- stub.engine_resets_scale and stub.scale_fires_event; ten events in one frame; stub.run_timers() until none is due
	-- one SetScale, one pass; another run_timers: nothing
end)
test("Blizzard's slider in Automatic and Pixel for pixel: set back on the next frame; in The game's UI scale: followed, its lines measured", function()
	-- useUiScale '1', uiScale '0.8', the game sets UIParent 0.8, UI_SCALE_CHANGED: back on the next frame
	-- mode game at 2560x1440: UIParent stays 0.8, st.lineWeight == LineWeight(0.8 * 1440 / 768), one pass
end)
test('Preview, Apply, Revert and Apply(nil): what is saved, and when', function()
	-- Preview({ mode = 'auto', size = 1.25 }): Saved() nil, IsPreviewing(), UIParent at 1.25; Revert(): back, not previewing
	-- Apply(it): global.uiScale is exactly { mode = 'auto', size = 1.25 }; Apply(nil) and Apply(DEFAULT): global.uiScale nil
	-- in combat: Preview false, 'combat'; Apply saves and gives true, 'combat'; the scale after combat
	-- Preview({ mode = 'auto', size = 2 }) false, 'size'; Preview({ mode = 'huge' }) false, 'mode'
end)
test('a preview is never saved: the next login comes back at the saved choice (Review Focus 4)', ...)
test("The game's UI scale: switching sets UIParent once to GameScale(); later logins set nothing", function()
	-- useUiScale '1', uiScale '0.9': Apply({ mode = 'game' }) sets 0.9; Start() again: no SetScale
	-- useUiScale '0', stub.default_scale 0.64: the switch sets 0.64; GetDefaultScale missing: sets nothing, one chat line
end)
test('a malformed save is read, never rewritten (Review Focus 5)', function()
	-- each of true, { mode = 'huge' }, { size = '90' }, { size = 5 }, { mode = 'game', size = 0 }: Current() as Normalize gives it;
	-- global.uiScale is the same value, with the same keys; Start() and Check() raise nothing
end)
test('a profile switch, copy or reset leaves the choice and the scale, and runs no scale pass of its own', ...)
test('OnChanged: each fn runs after the pass with the resolved table; one that errors is reported and the rest run', ...)
test('a scale change adds no history step', ...)
-- tests/unitframes/nameplate_pixel_test.lua (replacing ':480' and the end of ':454')
test('a scale change re-pins every plate and re-applies the size, after the pass; in combat both wait for its end (Ruling 5)', ...)
test('the plates no longer hear the screen events themselves', ...)
-- tests/lib/harness_self_test.lua
test("UIParent's SetScale: refused in combat from a SaftUI file, set by a test's own call; protected in combat", ...)
test('stub.change_display: with and without engine_resets_scale; scale_fires_event; GetDefaultScale', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/uiscale_runtime_test.lua tests/unitframes/nameplate_pixel_test.lua`. Expected: FAIL, `UIScale.Preview` is nil.
- [ ] **Step 3: Implement** what the Interfaces and Rulings 5 to 7, 16 to 19 and 26 say.
- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs**, as listed under Files. The report says `docs/design-system/` changed.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/uiscale.lua SaftUI-Core/init.lua SaftUI-Unitframes/nameplates/pixels.lua tests/core/uiscale_runtime_test.lua tests/wow/game.lua tests/wow/widgets.lua tests/lib/shell.lua tests/lib/harness_self_test.lua tests/unitframes/nameplate_pixel_test.lua .agents/architecture.md .agents/taint.md .agents/clients.md .agents/testing.md AGENTS.md README.md docs/design-system/tokens.json docs/design-system/README.md docs/followups.md
git commit -m "core: set the UI scale at login and after every display or scale change"
```

**In-game checks** (E4 first):
- On both clients, log in with no Lua errors. G1: `/run print(UIParent:GetScale(), 768/1440)` prints the same number twice.
- `/run SaftUI.UIScale:Apply({ mode = 'auto', size = 1.25 })`: everything is a quarter larger at once, with no reload, and the borders are whole. `/run SaftUI.UIScale:Apply(nil)` puts back exactly what was there.
- G6: in Options > Graphics, turn on Use UI Scale, move the slider and apply. SaftUI's size comes back on the next frame. Then `/run SaftUI.UIScale:Apply({ mode = 'game' })`: the slider's size, with whole borders. `Apply(nil)` to go back.
- G5: resize the window, or change the resolution, out of combat and in combat. No error, and the size comes back on the next frame, or after combat.
- G7: a `/reload` in combat: no "Interface action failed", and the scale is right by the end of the fight.
- G8: plates after `Apply` at 1.25 and back: whole borders while strafing past a pack, with no reload.
- G9: `/console taintLog 1`, then the checks above: no "blocked" line naming SaftUI in `Logs/taint.log`.

---

### Task 5: What follows a change: the margin, placements, the plates' size, edit mode, `/sui`

**Files:**
- Modify:
  - `SaftUI-Core/api.lua`: `st:GetScreenMargin` (`:613-619`) and `st:PlaceAtPosition` (`:552-555`).
  - `SaftUI-Unitframes/nameplates/nameplates.lua:479-486`: `UF.PlateDriverSize`.
  - `SaftUI-Core/EditMode/Bar/bar.lua:385-390`, `Bar/barwindow.lua:386-394`, `EditMode/coordinates.lua:153-155` and `EditMode/settings.lua:56-57`: each handler becomes a named function, also given to `st.UIScale:OnChanged`.
  - `SaftUI-Core/Config/optionssizes.lua`: `OW:FitToScreen()`, registered on `st.UIScale:OnChanged` when the file loads.
- Test: modify `tests/core/screen_margin_test.lua`, `tests/core/mover_helpers_test.lua`, `tests/unitframes/nameplate_pixel_test.lua`, `tests/core/editmode_bar_test.lua`, `editmode_bar_window_test.lua`, `editmode_grid_test.lua`, `editmode_coordinates_test.lua` and `tests/core/options_sizes_test.lua`.
- Docs:
  - `.agents/edit-mode.md`:
    - Screen edge margin: the margin is in whole pixels of the frame, so 20 is 31 pixels on the Mac;
    - `st:PlaceAtPosition` rounds;
    - the bar, the floating window, the grid and the label also follow `UIScale:OnChanged`;
    - `/sui` shows half when full no longer fits after a change, and leaves the save as it is.
  - `.agents/architecture.md`: the position helpers (`st:PlaceAtPosition` puts offsets on whole pixels); Nameplates' Size bullet (the driver's size is a whole, even number of pixels).

**Interfaces:**
- Consumes: Task 4's `st.UIScale:OnChanged(fn)`; Task 1's helpers.
- Produces:
  - `st:GetScreenMargin(frame) -> left, right, top, bottom`: `st:RoundToPixel(margin, frame)`, plus the reach as it is (Ruling 23).
  - `st:PlaceAtPosition(frame, position)`: the offsets go through `st:RoundToPixel(x, frame)` and `st:RoundToPixel(y, frame)`.
  - `UF.PlateDriverSize(width, height) -> w, h`: `Even(width / pixel) * pixel * ratio`, where `pixel = st:GetPixelSize(UIParent)`, `Even(n) = 2 * floor(n / 2 + 0.5)`, and `ratio` and the secret and zero cases are as today (Ruling 24).
  - `OW:FitToScreen()`: while the window shows at full and `not OW.Fits(S.layout, 'full', S.sidebar)`, it shows half (`S.size = 'half'`, then a render) and saves nothing. It opens at the saved size next time, as `OW:Open` does.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/screen_margin_test.lua
scaled_test("every kept frame's clamp insets are the profile's margin in whole pixels", ...)
test('at 1.55 a margin of 20 is 31 pixels; at k 1 it is 20, rawequal', ...)
-- tests/core/mover_helpers_test.lua
test("PlaceAtPosition: at k 1 whole offsets are today's numbers and a saved 1.3333 lands at 1; at 0.75 a saved 5 lands at 4 pixels", ...)
-- tests/unitframes/nameplate_pixel_test.lua
test("the driver's size: 200 x 20 is 150 x 16 pixels at 0.75 and 310 x 32 at 1.55; at k 1 today's floats, rawequal", ...)
-- tests/core/editmode_bar_test.lua, editmode_bar_window_test.lua, editmode_grid_test.lua, editmode_coordinates_test.lua
test('the change callback lays the bar out and places it on the next frame, with no screen event', ...)
test('the change callback puts the floating window and the History list back inside the margin', ...)
test('the change callback redraws the grid', ...)
test('the change callback places the Coordinates label', ...)
-- tests/core/options_sizes_test.lua
test('a scale change that leaves the full window no room shows it at half and saves nothing', function()
	-- 1024x768, Automatic at 1.30: UIParent 1050 units wide; full (1040 + the margins) doesn't fit -> half; optionsWindow.size unchanged
end)
```

- [ ] **Step 2: Run them to see them fail.** Run those files. Expected: FAIL. At 1.55 the clamp inset is 20 units, and the callback is never heard.
- [ ] **Step 3: Implement** what the Interfaces and Rulings 22 to 24 say.
- [ ] **Step 4: Run** `tests/run tests/core tests/unitframes tests/loot tests/minimap tests/misc tests/chat`, then `tests/run --scales=all tests/core/screen_margin_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs**, as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/api.lua SaftUI-Unitframes/nameplates/nameplates.lua SaftUI-Core/EditMode/Bar/bar.lua SaftUI-Core/EditMode/Bar/barwindow.lua SaftUI-Core/EditMode/coordinates.lua SaftUI-Core/EditMode/settings.lua SaftUI-Core/Config/optionssizes.lua tests/core/screen_margin_test.lua tests/core/mover_helpers_test.lua tests/unitframes/nameplate_pixel_test.lua tests/core/editmode_bar_test.lua tests/core/editmode_bar_window_test.lua tests/core/editmode_grid_test.lua tests/core/editmode_coordinates_test.lua tests/core/options_sizes_test.lua .agents/edit-mode.md .agents/architecture.md
git commit -m "core: round the margin and saved positions to pixels, and follow scale changes in edit mode, plates and /sui"
```

**In-game checks:**
- At 100%, the unit frames, the loot feed and rolls, the minimap, the micro menu, the experience bar and the group holders are where they were.
- Turn on edit mode (`/sui edit`), then `/run SaftUI.UIScale:Apply({ mode = 'auto', size = 1.25 })`:
  - the docked bar sits against the top edge, inside the margin;
  - the floating window and the History list are inside the screen;
  - the grid redraws, and the Coordinates label follows;
  - a frame dragged to the edge stops 25 pixels from it.

  `Apply(nil)` to go back.
- Nameplates after the same: whole borders, and the plates stacked as before, a quarter larger.

---

### Task 6: The Keep prompt and `/sui scale`

**Files:**
- Create: `SaftUI-Core/Config/uiscaleprompt.lua`.
- Modify:
  - `SaftUI-Core/Config/load.xml`: `uiscaleprompt.lua` after `general.lua`.
  - `SaftUI-Core/Config/config.lua:105-123`: `scale` is parsed before `FindCommand`, as `edit` and `debug` are.
- Test: create `tests/core/uiscale_prompt_test.lua`, on `core/options_window_helpers.lua`'s world, with `uiscaleprompt.lua` loaded after it, and `load_editmode_bar()` for the levels case.
- Docs:
  - `.agents/edit-mode.md`: `covers` gains `'SaftUI-Core/Config/uiscaleprompt.lua'`; a paragraph on the Keep prompt; `/sui scale` beside `edit` and `debug`.
  - `README.md`: a usage line for `/sui scale`.
  - `AGENTS.md`: Core's row names the Keep prompt, `Config/uiscaleprompt.lua`.

**Interfaces:**
- Consumes: Task 4's `Preview`, `Apply`, `Revert`, `Current`, `Default`, `Applied` and `Describe`.
- Produces:

```lua
local KP = {}
st.UIScalePrompt = KP
KP.SECONDS = 15
KP.LEVEL = 9900   -- FULLSCREEN_DIALOG: over /sui, the edit mode bar (9500), the label (9600) and the History list (9700)
```

  - `KP:Ask(choice) -> ok, why`: runs `st.UIScale:Preview(choice)`, and on success shows the prompt for it, restarting the countdown if it was already showing. Otherwise it passes the refusal on.
  - `KP:Keep()`: `st.UIScale:Apply(st.UIScale:Current())`, then hides.
  - `KP:GoBack()`: `st.UIScale:Revert()`. Out of combat it hides. In combat its line reads "Goes back when combat ends.", its buttons hide, and it hides once the revert has applied.
  - `KP:IsShown() -> boolean` and `KP:GetFrames() -> { frame, title, line, keep, back } | nil`.
  - The frame:
    - `st:CreateFrame` on UIParent, with `SetIgnoreParentScale(true)`, and `SetScale(st.UIScale:Default().uiScale)` on every show;
    - drawn with `st:SetTemplate(frame, 'theme', 'options', 'panel')` and centred with `W.PlaceCentred`;
    - its buttons are `W.Button`s, worn as `W.LookButton` under Blizzard;
    - Ruling 20 for keys, modality and level.
  - `/sui scale`, its forms:
    - `/sui scale` prints "UI scale: Automatic at 100%." (the mode's name and the size), then `Describe(Applied())`.
    - `/sui scale reset` runs `Apply(nil)`, with no prompt. It prints "UI scale back to Automatic at 100%.", or in combat "UI scale goes back to Automatic at 100% when combat ends."
    - `/sui scale <n>` and `/sui scale <n>%` run `KP:Ask({ mode = 'auto', size = n / 100 })`, with the size first held between `SIZE.min` and `Default().sizeMax`.
    - `/sui scale auto`, `pixel` and `game` run `KP:Ask({ mode = m, size = Current().size })`.
    - Anything else prints "Type /sui scale, then reset, auto, pixel, game or a size from 70 to 150."
    - An `Ask` refused in combat prints "The UI size can't change in combat."

- [ ] **Step 1: Write the failing tests** (in `tests/core/uiscale_prompt_test.lua`)

```lua
test('Ask: the preview at once, then the prompt: "Keep this UI size?", "Going back in 15 s.", Keep and Go back', ...)
test('the countdown ticks each second, and at 0 it goes back: hidden, the scale as saved', ...)
test('Keep saves the previewed choice; Go back restores the saved one', ...)
test('Esc goes back, and every other key goes on to the game', ...)
test('a second change restarts it for the new choice; going back then returns to the saved choice (Review Focus 4)', ...)
test('the prompt through combat (Review Focus 4)', function()
	-- PLAYER_REGEN_DISABLED: it stays; IsKeyboardEnabled() false; SetPropagateKeyboardInput never called in combat
	-- the timer reaches 0 in combat: the line reads 'Goes back when combat ends.', the buttons hidden, UIParent unchanged
	-- PLAYER_REGEN_ENABLED: reverted, hidden; #stub.blocked == 0
end)
test('it draws at the automatic size of this screen at 100%, whatever is previewed', function()
	-- 1920x1080, previews at 70% and 150%: frame:GetEffectiveScale() == st.UIScale:Default().uiScale; IsIgnoringParentScale()
end)
test('over /sui, the edit mode bar and the History list; in the theme on the options Background; centred; whole pixels', ...)
test('it stays when /sui closes, and a click outside it reaches what is under it', ...)
test('/sui scale: the line; reset at once with no prompt, and in combat after it; 90 and 90%; 200 and 10 held to the range; 150 on a 768 high screen held to 130; auto, pixel and game; anything else gives the forms', ...)
test('/sui scale reset during a preview ends it and hides the prompt', ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/uiscale_prompt_test.lua`. Expected: FAIL, `st.UIScalePrompt` is nil.
- [ ] **Step 3: Implement** what the Interfaces and Rulings 15 and 20 say.
- [ ] **Step 4: Run** `tests/run tests/core`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs**, as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/uiscaleprompt.lua SaftUI-Core/Config/load.xml SaftUI-Core/Config/config.lua tests/core/uiscale_prompt_test.lua .agents/edit-mode.md README.md AGENTS.md
git commit -m "core: add the keep prompt and /sui scale"
```

**In-game checks:**
- `/sui scale` prints the size and the screen.
- G4:
  - `/sui scale 90`: the size changes at once, and "Keep this UI size?" counts down. Keep, then `/reload`: still 90%.
  - `/sui scale 120`, then Go back: back to 90%.
  - Esc goes back, and so does leaving it until 0.
  - `/sui scale reset` from 150 and from 70: Automatic at 100% at once, with no prompt.
  - `/sui scale pixel`, `game` and `auto`, each with the prompt.
- In combat with a training dummy: the prompt stays, and your keys reach your bars. Its timer ends with "Goes back when combat ends.", and the size goes back after the fight.
- With `/sui` and edit mode open: the prompt shows over both, at the same size whatever is previewed.

---

### Task 7: The UI scale section in `/sui`, and its two chat lines

**Files:**
- Modify:
  - `SaftUI-Core/Config/general.lua`: `args.uiscale`, at order 0.
  - `SaftUI-Core/Config/optionsrange.lua:168-182` and `:245-252` (`Dragged`): `applyOnRelease`.
  - `SaftUI-Core/uiscale.lua`: the first-login line, in `Start`, and the slider line, in `Check` (Rulings 16 and 17).
  - `tests/lib/options_walk.lua:30-35`: `applyOnRelease` in `SAFTUI_FIELDS`.
- Test: modify `tests/core/general_tab_test.lua`, `tests/core/options_range_test.lua` and `tests/core/uiscale_runtime_test.lua`.
- Docs:
  - `.agents/edit-mode.md`: General's tab, with the UI scale section first; the range's `applyOnRelease`.
  - `.agents/testing.md`: `options_walk.lua`'s fields.
  - `README.md`, Installation, adds: "Global settings > General > UI scale has a UI size over the automatic size, Pixel for pixel (every size that many pixels, as before), and The game's UI scale, which leaves the size to Blizzard's setting."

**Interfaces:**
- Consumes: Task 6's `st.UIScalePrompt:Ask`; Task 4's `Current`, `Applied`, `Default` and `Describe`.
- Produces:
  - The range field `applyOnRelease = true`:
    - while the slider is dragged, the value shown follows it and `set` isn't called;
    - when the button comes up, `set` runs once with the value shown, if it changed;
    - an arrow's click and a typed value set at once;
    - a range without the field is as today.
  - `args.uiscale`: inline, order 0, named "UI scale", with the spec's section description. Its rows:
    - **`scale`** (order 1), a select of `{ auto = 'Automatic', pixel = 'Pixel for pixel', game = "The game's UI scale" }`, with `sorting = UIScale.MODES` and the spec's desc.
      - get: `Current().mode`. set: `KP:Ask({ mode = value, size = Current().size })`.
      - `default`: `differs` while the mode isn't `'auto'`; `reset` is `KP:Ask({ mode = 'auto', size = Current().size })`; `text = 'Automatic'`.
    - **`size`** (order 2), a range named "UI size", with the spec's desc.
      - `min = UIScale.SIZE.min`, `max = UIScale:Default().sizeMax` (Ruling 21), `step = UIScale.SIZE.step`, `isPercent`, `applyOnRelease`.
      - `disabled` while `Current().mode ~= 'auto'`.
      - get: `Current().size`. set: `KP:Ask({ mode = 'auto', size = value })`.
      - `default`: `differs` while the size isn't `DEFAULT.size`; `reset` is `KP:Ask({ mode = Current().mode, size = DEFAULT.size })`; `text = '100%'`.
    - **`describe`** (order 3), a description whose name is `function() return UIScale:Describe(UIScale:Applied()) end`.

- [ ] **Step 1: Write the failing tests**

```lua
-- tests/core/general_tab_test.lua (the cases that pick load uiscaleprompt.lua and the kit)
test('the UI scale section is first: Scale, UI size and the line; then Icons and Layout as before', ...)
test("Scale lists Automatic, Pixel for pixel and The game's UI scale in that order; its reset goes back to Automatic through the prompt", ...)
test('UI size: 70% to 150% in 5% steps, its top 130% on a 768 high screen, disabled unless Automatic, its reset to 100% through the prompt', ...)
test('a pick previews and asks; Keep saves it; Go back puts the row back', ...)
test('the line says what is applied: "This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines."', ...)
test('the rows read and write st.UIScale, never the profile: a profile switch changes nothing they show', ...)
test('the section on whole pixels under Thick, Thin and Blizzard, with stub.size_noise up, down and off', ...)
-- tests/core/options_range_test.lua
test('applyOnRelease: a drag sets nothing until the button comes up, then once with the last value; an arrow and a typed value set at once; without it every step sets, as before', ...)
-- tests/core/uiscale_runtime_test.lua
test("the first login where the automatic size isn't 1: one line, once per account; none with a saved choice; none, and no marker, at k 1", function()
	-- 1920x1080, nothing saved: the spec's line with '75%'; global.uiScaleNotice == 1; Start() again: nothing printed
end)
test("Blizzard's slider: one line a session, only when the setting changed and SaftUI set the scale back (Review Focus 3)", ...)
```

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/general_tab_test.lua tests/core/options_range_test.lua tests/core/uiscale_runtime_test.lua`. Expected: FAIL. General has no `uiscale` section, and a drag sets at every step.
- [ ] **Step 3: Implement** what the Interfaces and Rulings 15 to 17 and 21 say. Copy the descriptions from the spec's "The rows", word for word.
- [ ] **Step 4: Run** `tests/run tests/core`, including `options_validate_test.lua`, then `tests/run -j2`. Expected: PASS.
- [ ] **Step 5: Docs**, as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Config/general.lua SaftUI-Core/Config/optionsrange.lua SaftUI-Core/uiscale.lua tests/lib/options_walk.lua tests/core/general_tab_test.lua tests/core/options_range_test.lua tests/core/uiscale_runtime_test.lua .agents/edit-mode.md .agents/testing.md README.md
git commit -m "options: add the UI scale section to Global settings > General"
```

**In-game checks:**
- Global settings > General: UI scale comes first, then Icons and Layout, under Thick, Thin and Blizzard, at full and half size.
- UI size, dragged: nothing changes while dragging. On release the size changes and the prompt asks; Keep. An arrow, and a typed 115, do the same.
- G4: the largest size the screen allows. `/sui` still fits, and its rows can be reached. `/sui scale reset` from there.
- Scale set to Pixel for pixel: UI size greys out. Set to The game's UI scale: the game's size. Then back to Automatic.
- A row's reset icon shows while the row differs from its default, and puts it back through the prompt.
- The line under the rows names this screen, the percent and the line weight.
- G6's chat line: once this session, after the first slider move.

---

### Task 8: Followups, the font demo, and the phase's checklist

Before starting, E6's answer is in. So is E0's: the friends get this build.

**Files:**
- Delete: `SaftUI-Core/Dev/fontdemo.lua`, `SaftUI-Core/Dev/load.xml`, every file in `SaftUI-Core/Media/Fonts/Candidates/`, and `tests/core/fontdemo_test.lua`.
- Modify:
  - `SaftUI-Core/SaftUI-Core_Forever.toc` and `SaftUI-Core_Mainline.toc`: the `Dev\load.xml` line goes.
  - `tests/core/setfont_scan_test.lua:31`: its exception for the demo goes.
  - `tests/core/theme_kinds_test.lua`: the allow-list loses `Dev/fontdemo.lua`.
  - `AGENTS.md`: Core's row loses the demo's sentence.
  - `README.md:28`: the `/suifonts` line goes.
  - `.agents/testing.md`: the mention of `fontdemo_test.lua` goes.
  - `docs/followups.md`.

**Interfaces:**
- Consumes: Tasks 1 to 7, all landed.
- Produces: nothing later work calls.

- [ ] **Step 1: The followups** (`docs/followups.md`, with the ToC kept in step):
  - "2026-11-13 — Scale SaftUI across resolutions and stay pixel perfect" gains a line: "Taken up by `docs/superpowers/specs/2026-11-14-saftui-ui-scaling-design.md`. Phase 1 (`docs/superpowers/plans/2026-11-15-saftui-ui-scaling-phase-1.md`) shipped on <date>." It stays Active until phase 4 ends.
  - "2026-11-11 — Nameplates: in-game checks", step 2: the check is also made at the friends' scales, and the `/reload` caveat about a UI scale change goes.
  - One new Active entry for each later phase: 2 (the options kit and SaftUI's windows), 3 (edit mode), 4 (each addon, 4a to 4g, in call 26's order) and 5 (crispness on dense screens). Each is written from the spec's Phasing text, with E5's outcome (which sizes phases 2 and 4) and anything the friends reported.
  - One entry for each experiment that left work. If E6 found Homespun rough at 15.5: phase 5's rule. If E1 found an odd notch: half pixels from it.
- [ ] **Step 2: Delete the font demo** by the five steps its header lists. No candidate is kept: Homespun stays (decision 41).
- [ ] **Step 3: Run** `tests/run -j2`, `tests/run --scales=all` and `tests/run --self-check`. Expected: PASS. Then `git grep -n "Dev" -- 'SaftUI-Core/*.toc'` and `git grep -n -e "Candidate: " -e "fontdemo" -e "suifonts" -- 'SaftUI-*' tests/ AGENTS.md README.md`. Expected: nothing printed. The tracker's own `Candidates` don't match.
- [ ] **Step 4: Docs.** Run `agents-doc-parity-check` and `readme-freshness-check`.
- [ ] **Step 5: Commit**

```bash
git rm SaftUI-Core/Dev/fontdemo.lua SaftUI-Core/Dev/load.xml tests/core/fontdemo_test.lua
git rm $(git ls-files SaftUI-Core/Media/Fonts/Candidates)   # each candidate file by its path
git add SaftUI-Core/SaftUI-Core_Forever.toc SaftUI-Core/SaftUI-Core_Mainline.toc tests/core/setfont_scan_test.lua tests/core/theme_kinds_test.lua AGENTS.md README.md .agents/testing.md
git commit -m "core: remove the font demo now that the small text font is settled"
git add docs/followups.md
git commit -m "docs: file the scaling work's later phases and phase 1's followups"
```

**In-game checks** (the phase's, from the spec's "What only the game can confirm"):
- G1, the owner: before and after screenshots of the same scene at 1440p, compared. `/run print(UIParent:GetScale(), 768/1440)` prints the same number twice.
- G2, the 1080p friend: the size matches what E0 showed. Under Thick, Thin and Blizzard, every border on the unit frames, bars, bags and windows is one pixel on every side. Homespun looks as it did in the font demo.
- G3, the Mac friend: the same with 2 pixel borders. Homespun and the Lucide icons at 1.55, judged crisp or soft; that decides phase 5.
- G4 to G9, as in Tasks 4, 6 and 7, on each friend's machine too.
- `/suifonts` does nothing, and Global settings > Fonts lists no "Candidate:" faces.

---

## Spec coverage check

| Spec section, decision or call | Task |
| --- | --- |
| Why; decided 1 to 3 and 5 (automatic, slider, whole-pixel borders) | 1, 3, 4, 7 |
| Decided 4 (Homespun stays), Fonts, call 8 | none needed (fonts follow by construction); E6 → 8 |
| Decided 6 and 7 (one interface for `/sui` and a setup dialog) | 4 (the interface), 6, 7 (its users) |
| Goals: same share of the screen; whole lines under every theme; 1440p unchanged; three modes and recovery; following changes without combat errors; one interface; tests at four scales | 1, 4; 3; every task's k 1 case; 4, 6, 7; 4, 5; 4; 1, 2, 3 |
| Anti-goals | 3 (borders), the Global Constraints (owner), the upgrade section and 5 (layouts), 4 (combat), 6 and 7 (recovery) |
| How SaftUI scales today; What the game does F1 to F12 | 1 (the model replaces it), 4 (clients.md takes F2 to F10) |
| The scale model: where, default and choice, the formula, the three modes, worked values | 1, 4 (Rulings 3, 4, 18) |
| Whole pixels: the grid, tokens and helpers, the line weight, the table of what scales | 1, 3, 5 |
| The theme engine (A1 to A3), `st.BACKDROP`, the close button | 3 (Rulings 11 to 14) |
| Placement; `st:PlaceAtPosition` (call 19); gaps at least one pixel | 5; 1 (`minPixels`; its users are in phases 2 and 4) |
| Icons, textures, Blizzard's art (calls 21, 22) | 3 (insets whole); icons unchanged (phases 2 and 4) |
| Nameplates' three changes | 4 (the pin from the callback), 5 (the driver's even pixels) |
| The audit A1, A2, A3, A8 (helper), A13, A15, A16 | 3, 3, 3, 1, 1, 3 and 4, 1 and 2 |
| Saved positions: nothing converted; what is placed again, and when | 5 (rounding where placed), 4 (the pass), 5 (the followers) |
| When the scale is set: at login, on a change, in combat, Blizzard's slider, the order with the plates | 4 (Rulings 5 to 7), 7 (the slider's line) |
| The scale interface | 1, 4 (Ruling 1 adds `Normalize` and `Applied`) |
| Settings and UI: where, the rows, applying, the Keep prompt, `/sui scale`, the first login | 7, 7, 7, 6, 6, 7 |
| Phasing: phase 1's docs and its followup | 1, 3, 4, 5, 6, 7 (each its own), 4 (the followup), 8 (the rest) |
| Testing: tests 1 to 6, several scales, the scan; G1 to G9; E0 to E6 | 1 to 7; 2; 3; each task's checks and 8; Experiments and seams |
| What's left to the builder | Rulings 1, 15, 17, 20, 21 |
| Risks 1 to 13 | 1: 4. 2: 4 and the Global Constraints. 3: the upgrade section and 7 (the line). 4: the k 1 cases. 5: E1. 6: 1 (the floor). 7: 6, 7, and `OW:FitToScreen` in 5. 8: 1 and 3. 9: E1 and 5. 10: the upgrade section. 11: 4. 12: 5. 13: E6 and 8. |
| Calls 1 to 26 | 1: 1, 4. 2 to 4: 1. 5: 1, 4. 6: 4. 7: 1, 3. 8: none. 9: 5. 10: 4. 11: 6, 7. 12: 6. 13: 6. 14: 7. 15: 4. 16: 1, 4. 17: 7. 18: 3 (E5). 19: 1, 5. 20: none (nudges unchanged). 21: 3. 22: none (phase 2). 23: 7 (UI size's desc). 24: 1. 25: 2. 26: 8 (the phase 4 followup). |

## Where the spec is silent, contradicted by the code, or out of date

Each item here is a Ruling above, or a fact the tasks rely on.

- **Contradicted.**
  - The snap band's float edges (Ruling 3).
  - The line weight at k = 1.5 measured with float noise (Ruling 2).
  - Three tests read `st.scale`, beside the shell (Ruling 8).
  - No theme test uses the pixel checker (Ruling 10).
  - `st.BACKDROP`'s one reader is in SaftUI-Bags (Ruling 12).
  - `OW.Fits` is checked only when `/sui` opens, so a margin change doesn't hold the size "as today" (Ruling 22).
  - The kit's range sets at every drag step (`Dragged` calls `Commit`; Ruling 21).
  - The kit's confirm dialog can't serve as the Keep prompt: it is modal, a click outside it answers No, it closes with `/sui`, and its keys need `SetPropagateKeyboardInput`, which is protected in combat (Ruling 20).
- **Silent.** Rulings 1, 4 to 7, 9, 13 to 19 and 22 to 26.
- **Out of date** (checked at `f13a2b7`; this plan is at `12859a99`).
  - 240 test files, not 194, so the spec's timings are stale. 36 files use the pixel checker, not 31.
  - Line numbers have moved:

    | File | The spec says | Now |
    | --- | --- | --- |
    | `Config/optionslook.lua`, the `edgeSize` lines | 61, 71, 296 | 67, 77, 302 |
    | `panels.lua`, the close button's backdrop and dark line | 335, 343 | 333, 341 |
    | `tests/lib/shell.lua`, UIParent's scale | 585-587 | 586-588 |
    | `theme.lua`, Thick's strips | 316-347 | 318-349 |
  - The General tab's rows have no per-setting resets yet; the reset design will add them.
  - `NP.world` already sets `st.config.global`, but the shell doesn't.
