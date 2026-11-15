# SaftUI Color Roles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every color on Global settings > Colors is named for what it is for:
- Text: Text, Muted, Strong, Danger, Warning, Caution, Success, Shared.
- Blue leaves the page for one Accent swatch on Global settings > Theme.
- Loot rolls, factions and roles get groups of their own.
- The Buttons section's opacity is drawn.

Every player's customized colors carry into the new roles, on every profile, the first time each is used. Nothing a player sees changes except the spec's short list.

**Architecture:**
- **One accessor.** `st:Color(group, key)` and `st:ColorRGBA(group, key, strength)` in `SaftUI-Core/Media/colors.lua`. They read the profile at call time, fall back to `st.defaults`, and error on a key with no default. Every Text, Buttons, Roles, Factions and Loot read, and every read of the accent, goes through them by the end (Task 4 for all but Buttons, Task 5 for Buttons).
- **One versioned migration.** `st:MigrateColors(profile)`, beside `st:MigrateTemplateKeys`'s call sites (login and every `Config:UpdateConfig`). `colors.version` is the marker. There is one numbered step per task: a key's default, its readers, its migration step and its retirement land together, so every saved profile stays intact between tasks.
- **One scan.** `tests/core/color_reads_test.lua` reads every file the TOCs load. It fails on a retired key, on a literal `st:Color` key with no default, and from Task 4 on any read that bypasses the accessor. Its rules grow with each task (The scan, below).
- **Five tasks, the spec's phases 1 to 5.** Its Phase 6 (the design system's pages) is folded into each task: Ruling 1.

**Tech Stack:**
- Lua 5.1, on WoW Forever (16001) and retail (120000).
- AceDB-3.0's profiles: defaults copied in with their methods, and on a switch or at logout only the channels that differ are kept (`removeDefaults`).
- `CreateColor` color objects.
- The options kit's `default` field (per-setting resets).
- Tests on stubs, with `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-14-saftui-color-roles-design.md`. Its last section, "Settled with the owner after the draft (2026-11-14)", records the owner's approval: "I'm good with all of those suggestions, if any feel off we can adjust". That settles four things:
- Question 1: "Category: <name>" takes the accent.
- Question 2: the rule editor's AND takes the accent, and OR takes Warning.
- Question 3: the bags' loading bar and the loot roll timer bars take the accent.
- Question 4: the three game blues stay.

All 22 calls stand. The audit, `docs/design-system/25-colour-roles.md`, is the source for every use. Line numbers below are at `42452b9`.

**Assumed state.** `modular` at `42452b9`.
- SaftUI-Tracker's tasks 1 to 6 are merged, and 7 to 13 are in flight (`docs/superpowers/plans/2026-11-14-saftui-objective-tracker-phase-1.md`).
- A fonts plan is being written in parallel from `docs/superpowers/specs/2026-11-14-saftui-fonts-design.md`.
- `st.TINT_ROW` (0.25), `st.TINT_OBJECT` (0.15), `st.StringFormat:ToHex`, `T.saftui_files()` (`tests/lib/theme_helpers.lua`) and `theme_migration_test.lua`'s real-AceDB `fresh(saved)` world all exist.

## How the tasks are cut

| # | Task | Spec phase | Step | Needs | Owner can try in game |
| --- | --- | --- | --- | --- | --- |
| 1 | The accessor, the migration, and Roles, Factions and Loot | 1 | 1 | — | loot letters, feed, zone text, role corners as before; Pass, Horde, Damage each move alone |
| 2 | The accent | 2 | 2 | 1 | Theme > Accent recolors everything blue; own marks and the equipped border in the accent |
| 3 | Muted | 3 | 3 | 2 | hints and disabled rows as before; the diff icon grey |
| 4 | The state colors, and every read through the accessor | 4 | 4 | 3 | errors, timers, tags, stats, durability, item levels as before; the Error prefix in Danger |
| 5 | Opacity | 5 | 5 | 4 | Buttons at 100% as before; a lower Hover fades check boxes and micro buttons |

The tasks run in order. Each one edits `Media/colors.lua`, `Config/defaults.lua`, `tests/core/colors_test.lua`, `color_migration_test.lua`, `color_reads_test.lua` and `docs/design-system/tokens.json` after the one before it.

### Files other work in flight touches

Each task's shared files are listed, so this plan, the tracker's tasks 7 to 13 and the fonts plan can be sequenced. Whichever lands second merges by hand, keeping both sides.

A tracker or fonts task that lands **after** one of these tasks and adds a color read must use the role keys through `st:Color`. The scan fails on any other read: on a retired key from the task that retires it, and on any direct read from Task 4.

| Task | Shared with the tracker (tasks 7–13) | Shared with the fonts plan |
| --- | --- | --- |
| 1 | `.agents/architecture.md` (doc only) | `SaftUI-Core/Config/defaults.lua`; `.agents/architecture.md`, `.agents/testing.md`, `docs/design-system/tokens.json`, `docs/followups.md` |
| 2 | `SaftUI-Tracker/rows.lua`, `tests/tracker/rows_test.lua` | `SaftUI-Core/Media/theme.lua` and `tests/core/theme_tab_test.lua` (fonts phase 5 adds Window titles after Options windows; Accent goes before it at order 5.5, Ruling 3); `Config/defaults.lua`; `Config/optionsbody.lua`, `optionsshare.lua`, `optionslist.lua`, `optionslook.lua`, `optionsposition.lua`, `optionswindow.lua`; `SaftUI-ActionBars/skin.lua`; `SaftUI-Misc/totemskin.lua`; `SaftUI-Tracker/rows.lua`; the design-system docs, `.agents/edit-mode.md`, `.agents/testing.md` |
| 3 | `SaftUI-Tracker/rows.lua`, `window.lua`, `tests/tracker/rows_test.lua`, `window_test.lua` | `Config/defaults.lua`; `Config/optionsbody.lua`, `optionsshare.lua`, `optionslist.lua`, `optionsmenu.lua`, `optionsposition.lua`, `optionswindow.lua`; `SaftUI-Core/panels.lua`; `SaftUI-Misc/Skinning/addons/restedxp.lua`; `SaftUI-Tracker/rows.lua`, `window.lua`; the design-system docs, `.agents/edit-mode.md` |
| 4 | `SaftUI-Tracker/rows.lua`, `window.lua` and their tests | `Config/defaults.lua`; `Config/optionsbody.lua`, `optionsshare.lua`, `optionslist.lua`, `optionslook.lua`, `optionsposition.lua`, `optionswindow.lua`; `panels.lua`; `SaftUI-Misc/totemtimers.lua`, `totemskin.lua`; `SaftUI-Tracker/rows.lua`, `window.lua`; the design-system docs (`30-code-changes.md` too), `.agents/edit-mode.md` |
| 5 | none | `Config/defaults.lua`; `SaftUI-ActionBars/skin.lua`; `SaftUI-Misc/totemskin.lua`; `tokens.json`, `docs/design-system/README.md` |

Task 1 shares no code file with the tracker, so it can run beside the tracker's tasks. Tasks 2 to 4 are best run after the tracker's task 13, or between two of its tasks, rebasing by hand.

The fonts plan's phases 2, 3 and 5 and this plan's Tasks 2 to 4 rewrite the same options-kit files. Run them one after another, never side by side.

## Global Constraints

- **Libraries.** Nothing under any `Libraries/` folder is modified (Ace3, oUF, LibActionButton and the rest).
- **Work in flight.** SaftUI-Tracker's tasks 7 to 13 and the fonts plan share files with Tasks 1 to 5. "Files other work in flight touches", above, lists them per task. A task never runs side by side with work that shares a code file with it.
- **No account, realm or character names** anywhere: code, tests, docs, commit messages or fixtures. Test profiles are named `Old`, `Two`, `Three`, and `char_key()` comes from the stubs.
- **Commits.** Lowercase `module: imperative summary` (`core: ...`, `bags: ...`, `docs: ...`). Stage by explicit path, never `git add -A`, `.` or a directory. End with the session's `Co-Authored-By` line.
- **Line endings.** Never `sed -i`: some files are CRLF. Edit with the editor, keeping each file's endings (`file <path>`). None of the files named here is CRLF at `42452b9`; check before editing anyway.
- **Player-facing text** says "color", in sentence case, in American spelling. Descriptions name what a color colors, never its hue.
- **Resets** are per setting, with the options kit's `default` field. There are no section or page Reset buttons.
- **Icons** are Lucide's (`st.icons`), and an icon-only control has a tooltip. No task here adds one.
- **Taint.** Nothing here hooks Blizzard code, calls a new method on a Blizzard frame or touches a protected frame in a new way. Each reader change only swaps where its color comes from. The migration is table writes only, and runs in combat. Reviewers of a task that touches `SaftUI-Misc/Skinning/**`, `SaftUI-ActionBars/skin.lua` or `SaftUI-Minimap/**` still check `.agents/taint.md` against the forever source.
- **Nothing changes at the defaults** but the spec's "What a player sees change":
  - own marks: light blue to the accent;
  - the diff icon and the bag category's marker: orange to Muted;
  - the equipped border: green to the accent;
  - the Error prefix: pure red to Danger;
  - the chat prefix: #00adef to #00adf0.

  Every other reader keeps its color and strength. Each listed change has a test case of its own.
- **Read at call time.** No reader caches a color object or a group table across a profile switch or a color change.
- **Tests.** Each task ends green on `tests/run -j2`; run single files while working. An earlier test's assertion changes only where this work changes what it pins, and the report lists each one. Tests may read profile tables directly, with the new keys (Ruling 20).
- **Docs.** Each task updates, in the same commit:
  - the `.agents/*.md` docs whose `covers:` lists its files, and `AGENTS.md` where its layout rows go stale;
  - `docs/design-system/` (tokens, components, decisions, discrepancies, code changes);
  - `docs/followups.md`.

  It then runs `agents-doc-parity-check` and `readme-freshness-check`, and hands back its in-game checks. After each merge, the controller (not the worker) republishes the changed `docs/design-system/` files to the Design System artifact.

## Review Focus

1. **Saved data the migration doesn't expect.** Examples: a `colors` or group that isn't a table, a saved color that's a number, a channel that's a string, a `version` that's a string or above the last step. Login completes, no error is raised, no version is lowered, and readers draw the defaults. Tests: Task 1, `'saved data the migration does not expect'` and `'a group that is not a table reads as the default'`.
2. **A profile switch or copy to an unmigrated profile in combat.** The version and every destination are written at once. The theme redraw, `'theme'` and then `'accent'` wait for the end of combat together, and `stub.blocked` stays empty. Test: Task 2, `'a profile update in combat: migrated at once, theme then accent after combat'`.
3. **A print while Core is still loading** (`st.defaults` not yet holding the accent or Danger). `st:Print` and `st:Error` never error: they use the shipped hex until the defaults exist. Tests: Task 2, `'a print before the defaults exist'`; Task 4 extends it to the Error prefix.
4. **A handler still listening on the old group.** After a Theme > Accent change, everything that recolored live on a Buttons > Blue change recolors on `'accent'`, and nothing recolors on `'button'` for the accent any more:
   - a held roll's lit border and label;
   - the bags' lit view buttons;
   - the feed's lit buttons;
   - a selected mover (Ruling 13);
   - the edit mode bar;
   - the tracker's rows.

   Test: Task 2, `'every live recolor of the accent'` (one case in each addon's test file).
5. **A profile migrated step by step across builds.** A profile at version 1 has a Text > Red changed after step 1 ran. It reaches Danger at step 4, and Pass keeps what step 1 gave it. Test: Task 4, `'step by step across builds'`, and Task 2's `'a profile at version 1 runs step 2 alone'`.

## Rulings on the spec

1. **Phase 6 is folded into Tasks 1 to 5.** This departs from call 22 ("docs of the design system last"): the brief for this plan requires each task to update the docs it makes stale, so the design system follows the code task by task, not at the end. Each task:
   - renames its tokens in `tokens.json`, `components/bundle.css` and every component page that names them;
   - marks the decisions it builds;
   - updates discrepancy 26 and code change 11 where it covers them.

   Task 5 adds the "built by" line at the top of `25-colour-roles.md`. The audit is otherwise a record and isn't rewritten.
2. **Buttons' Normal, Hover, Pushed and Danger readers move to the accessor in Task 5, not Task 4.** Task 5 must rewrite each of them to `st:ColorRGBA` with its strength, so moving them in Task 4 would edit about 20 sites twice. Task 4's no-direct-read rule therefore covers Text, Roles, Factions, Loot and the accent, and Task 5 extends it to Buttons.

   Buttons > Red's three readers change key in Task 4 (`st:Color('button', 'danger'):GetRGB()`), then strength in Task 5.
3. **The Accent row is built in `colors.lua`** (`CO:AccentOption(order)`), so the scan's one exempt file is `Media/colors.lua`. The Theme tab places it at `order = 5.5`, between Background (5) and Options windows (6), so no other row's order moves (the fonts plan adds rows after Options windows).
4. **`'accent'` fires after every `'theme'` of the profile update.** `Config:UpdateConfig` fires `st:ColorsChanged('accent')` right after each `st:ColorsChanged('theme')`:
   - in `RedrawTheme`, the path queued in combat;
   - in the out-of-combat call at its end.

   So in combat both wait for the end of it together. `st:ThemeChanged` runs the same update, so a theme change fires it too.
5. **The accessor's value and error.**
   - **The error.** The default decides the error. `st.defaults.colors[group][key]` (for `'accent'`, `st.defaults.theme.accent`) must exist, or `error(('SaftUI: no color %s.%s'):format(tostring(group), tostring(key)), 2)` is raised (`'SaftUI: no color accent'` for the accent). This holds whatever the profile holds.
   - **The value.** The profile's entry when `st.config.profile`, its group (or `theme`) and the entry are all tables; else the default object.
   - **The key.** `'accent'` takes no key: one passed is ignored.
6. **The migration runs in `xpcall`** to `geterrorhandler()`, at login and in `Config:UpdateConfig`, so a profile it can't read is reported and the UI still loads. Its reads check types (Review Focus 1), so no profile should ever reach the handler.
7. **`colors.version` only rises.** A non-number counts as 0. A version at or above the last step runs nothing and is left as it is.
8. **`CO.OLD_COLORS` holds all fourteen retired keys from Task 1:** today's shipped values, alpha included, keyed by path. It is never edited after Task 1. `CO.MIGRATION_STEPS` gets one entry per task.
9. **Step paths** are strings, `'group.key'` under `profile.colors`, plus `'accent'` for `profile.theme.accent`.
10. **Loot and faction data hold the new keys.**
    - The roll buttons' `color` (`rollbar.lua:12-15`), `PAIRED` (`rollinfo.lua:76-79`) and `CHOICES` (`Feed/rolls.lua:39-43`) hold Loot keys: `'pass'`, `'greed'`, `'transmog'`, `'need'`.
    - `ZT.FACTION_COLORS` goes: the faction word (`Alliance`, `Horde`, `Neutral`) is the Factions key.
    - `Feed/rolls.lua`'s `TextRGB` goes. Loot lines read `st:Color('loot', key)`. The winner's line keeps Text > Green until Task 4 makes it Success.
11. **`UF:UpdateColors` drops its roles line** (`unitframes.lua:221`) and `DEFAULT_ROLE_COLORS` (`:8`). No code in the bundled oUF reads `colors.roles`, and the corners read `st:Color('roles', role)`. The runes line stays.
12. **Wrappers are renamed for their role.**
    - Task 2: `OB.Blue` and `S.Blue` become `OB.Accent` and `S.Accent`, each returning `r, g, b`. `LinkBlue` goes, and links use `OB.Accent`.
    - Task 3: `OB.Grey`, `S.Grey`, `D.Grey`, `GreyRGB` and the local `Grey()`s become `OB.Muted`, `S.Muted`, `D.Muted`, `MutedRGB` and `Muted()`.
    - `OB.Normal` and `S.Normal` keep their names: the key is `normal`, and no hue.
    - The tracker's paint states follow the roles: `'grey'` becomes `'muted'` (Task 3) and `'white'` becomes `'strong'` (Task 4). `'accent'` stays.
    - A `Colors` local left unused is removed.
13. **A selected mover follows the accent live.** `EM:OnColorsChanged` recolors the movers' borders on `'accent'` as it does on `'theme'`. This is one condition, needed for the spec's in-game check 2 ("a selected mover").

    No other new live recolor is added: the role corners and the mount entries follow on reload, as their sections' notes say. The zone text recolors on `'factions'` (spec).
14. **A tooltip line takes no alpha.** The diff tooltip's per-page values use the accent's `r, g, b`. `OB.OWN_STRENGTH` applies where a region takes an alpha (labels, titles, the hover line's Own).
15. **Prints before the defaults.** While `st.defaults.theme.accent` is missing, `st:Print` uses `00adf0`. From Task 4, while `st.defaults.colors.text.danger` is missing, `st:Error` uses `dc6464`. Both read the accessor once the defaults exist.
16. **TOC titles keep `|cff00adef`**: the game reads them before any profile exists.
17. **The tip line field** `{ text = ..., red = true }` becomes `{ text = ..., danger = true }` in Task 4. `W.ShowTip` reads `line.danger`.
18. **The scan's lexer** goes in a new `tests/lib/source_lex.lua`, a copy of `theme_kinds_test.lua`'s `Lex` and `LineAt`. `theme_kinds_test.lua` and `tests/tracker/source_scan_test.lua` keep their own copies, untouched here (other work edits them); Task 1 adds a followup to fold them in.
19. **New tokens** are named like the existing per-group ones (`class-mage`, `power-mana`): `role-tank`, `role-healer`, `role-damage`, `faction-alliance`, `faction-horde`, `faction-neutral`, `loot-need`, `loot-greed`, `loot-transmog`, `loot-pass`, `loot-mount`. The renames are listed per task.
20. **Tests may read profile tables directly**, since they pin what is saved. The scan reads only the files the TOCs load.
21. **The rule editor's orange stays orange as Warning:** its OR rail and badge, and the Caught now highlight (`ruleeditor.lua:824`). Task 2 moves only AND.
22. **The Text and Buttons rows after each task** (labels land with their keys):

    | After | Text | Buttons |
    | --- | --- | --- |
    | today | Text, Grey, Red, Orange, Yellow, Green, Blue, Purple, Cyan, White | Normal, Hover, Pushed, Red, Green, Blue, Yellow, Grey |
    | Task 1 | Text, Grey, Red, Orange, Yellow, Green, Blue, Cyan, White | Normal, Hover, Pushed, Red, Green, Blue, Grey |
    | Task 2 | Text, Grey, Red, Orange, Yellow, Green, Cyan, White | Normal, Hover, Pushed, Red, Grey |
    | Task 3 | Text, Muted, Red, Orange, Yellow, Green, Cyan, White | Normal, Hover, Pushed, Red |
    | Task 4 | Text, Muted, Strong, Danger, Warning, Caution, Success, Shared | Normal, Hover, Pushed, Danger |

## The migration, exactly

`st:MigrateColors(profile)` and its data live in `SaftUI-Core/Media/colors.lua`, after `st:ColorRGBA`.

```lua
-- Today's shipped value of every retired key, frozen (AceDB saves only the
-- channels that differ from a default; once a default is gone, the rest come
-- from here). Never edited after it lands.
CO.OLD_COLORS = {
	['text.grey'] = { r = 150/255, g = 150/255, b = 150/255 },
	['text.white'] = { r = 1, g = 1, b = 1 },
	['text.red'] = { r = 220/255, g = 100/255, b = 100/255 },
	['text.orange'] = { r = 220/255, g = 150/255, b = 100/255 },
	['text.yellow'] = { r = 200/255, g = 200/255, b = 100/255 },
	['text.green'] = { r = 60/255, g = 240/255, b = 60/255 },
	['text.blue'] = { r = 0, g = 0.68, b = 0.94, a = 1 },
	['text.purple'] = { r = 197/255, g = 128/255, b = 255/255 },
	['text.cyan'] = { r = 120/255, g = 202/255, b = 250/255 },
	['button.red'] = { r = 0.6, g = 0.1, b = 0.1, a = 0.8 },
	['button.green'] = { r = 0.1, g = 0.6, b = 0.1, a = 0.8 },
	['button.blue'] = { r = 0, g = 0.68, b = 0.94, a = 0.8 },
	['button.yellow'] = { r = 0.6, g = 0.6, b = 0.1, a = 0.8 },
	['button.grey'] = { r = 150/255, g = 150/255, b = 150/255 },
}
```

`CO.MIGRATION_STEPS[n] = { copy = { { source, destination, ... }, ... }, retire = { path, ... }, opacity = { path, ... } }`. Each task appends its step:

| Step | Task | `copy` | `retire` | `opacity` |
| --- | --- | --- | --- | --- |
| 1 | 1 | `{ 'text.white', 'loot.need' }`, `{ 'text.yellow', 'loot.greed', 'factions.Neutral' }`, `{ 'text.purple', 'loot.transmog' }`, `{ 'text.red', 'loot.pass', 'roles.DAMAGER', 'factions.Horde' }`, `{ 'text.green', 'roles.HEALER' }`, `{ 'text.blue', 'roles.TANK', 'factions.Alliance' }`, `{ 'button.yellow', 'loot.mount' }` | `'text.purple'`, `'button.yellow'` | |
| 2 | 2 | `{ 'button.blue', 'accent' }` | `'button.blue'`, `'text.blue'`, `'button.green'` | |
| 3 | 3 | `{ 'text.grey', 'text.muted' }` | `'text.grey'`, `'button.grey'` | |
| 4 | 4 | `{ 'text.white', 'text.strong' }`, `{ 'text.red', 'text.danger' }`, `{ 'text.orange', 'text.warning' }`, `{ 'text.yellow', 'text.caution' }`, `{ 'text.green', 'text.success' }`, `{ 'text.cyan', 'text.shared' }`, `{ 'button.red', 'button.danger' }` | the seven sources | |
| 5 | 5 | | | `'button.normal'`, `'button.hover'`, `'button.pushed'`, `'button.danger'` |

The rules:

- **M1.** If `profile` isn't a table, or `profile.colors` isn't a table, return and write nothing.
- **M2.** `from` is `profile.colors.version` when it is a number, else 0. `last` is `#CO.MIGRATION_STEPS`. Every step `n` with `from < n <= last` runs, in order. Each step runs its copies, then its retirements, then its opacities. After that, if `last > from`, `profile.colors.version = last`. Nothing else ever writes the version.
- **M3. Reading a source.**
  - The saved table is `profile.colors[group][key]`, found only through tables. A source that isn't a table is not customized.
  - Its color is, for each of `r`, `g`, `b`, the saved channel when it is a number, else `CO.OLD_COLORS[source]`'s.
  - If the three channels equal the old value's as whole bytes (`math.floor(v * 255 + 0.5)`, the Colors page's `SameColor`), the source is not customized.
  - A source that is not customized copies nothing, and its destinations keep their own defaults.
- **M4. Writing a destination.**
  - Only `r`, `g`, `b` are copied, never `a`.
  - If the destination (`profile.colors[group][key]`, or `profile.theme.accent`) is a table, the channels are written into it in place. In the active profile that is AceDB's filled color, so it keeps its methods.
  - Otherwise a table `{ r = r, g = g, b = b }` is made. Its group (or `profile.theme`) is made first when it isn't a table.
- **M5. Retiring** sets `profile.colors[group][key] = nil` when the group is a table.
- **M6. Opacity** sets `t.a = st.defaults.colors[group][key].a or 1` on each destination that is a table. It never sets nil and never makes a table.
- **M7. Calls.**
  - In `Config:InitializeAceConfig` (`config.lua:88`), right after `st:MigrateTemplateKeys(st.config.profile)`: `xpcall(st.MigrateColors, geterrorhandler(), st, st.config.profile)`.
  - In `Config:UpdateConfig` (`config.lua:266`), right after its `st:MigrateTemplateKeys`: `Safely(function() st:MigrateColors(st.config.profile) end)`.
  - Never in `Config:Import`: it carries only unit frame layouts (spec, call 20).
- **M8.** It runs in combat (table writes only), and running it twice changes nothing.

## The scan

`tests/core/color_reads_test.lua` scans every file `T.saftui_files()` returns, read with `read_saftui_source` and lexed by `tests/lib/source_lex.lua` (`code`: comments blanked; `mask`: comments and string contents blanked). Its world is `core/config_helpers.lua`, so `st.defaults.colors` and `st.defaults.theme` are Core's real defaults. `SaftUI-Core/Media/colors.lua` is exempt from every rule but C.

| Rule | From task | Fails on |
| --- | --- | --- |
| **A. Retired keys** | 1 (the list grows: Task 1 `text.purple`, `button.yellow`; Task 2 `text.blue`, `button.blue`, `button.green`; Task 3 `text.grey`, `button.grey`; Task 4 `text.white`, `red`, `orange`, `yellow`, `green`, `cyan`, `button.red`) | `%f[%w_]group%s*%.%s*key%f[^%w_]` in `mask`; `%f[%w_]group%s*%[%s*(['"])key%1%s*%]` in `code` |
| **B. Group aliases** | 1 | a statement `local NAME = <expression ending in colors.text, colors.button, Colors().text or Colors().button>` binds NAME to a group, and the rest of the file may not read `NAME.key` or `NAME['key']` for a retired key of that group. From Task 4 a binding of `text` fails itself, and from Task 5 one of `button` |
| **C. Literal keys** | 1 | an `st:Color(` or `st:ColorRGBA(` whose first argument is a string literal naming neither `'accent'` nor a table of `st.defaults.colors`; a string-literal second argument with no `st.defaults.colors[group][key]`; any second argument with `'accent'` other than `nil` |
| **D. Direct reads** | 4 (`text`, `roles`, `factions`, `loot`, the accent); 5 adds `button` | in `mask`: `colors%s*%.%s*G%f[^%w_]` and `Colors%s*%(%s*%)%s*%.%s*G%f[^%w_]`; in `code`: `colors%s*%[%s*['"]G['"]`; for the accent, `theme%s*%.%s*accent%f[^%w_]` and `Theme%s*%(%s*%)%s*%.%s*accent%f[^%w_]` |
| **E. Hue names in code** | 2 (`Blue`, `LinkBlue`, `OWN_TEXT`); 3 adds `Grey`, `GreyRGB`, `DIFF_COLOR`; 4 adds the tip field `red%s*=%s*true` | the identifier, word-bounded (`%f[%w_]Blue%f[^%w_]`), in `mask` |
| **F. Buttons at their strength** | 5 | `st:Color%s*%(%s*['"]button['"]` (every Buttons read is `st:ColorRGBA`) |

Each failure prints `path:line: rule: the line`. The first case runs every rule on samples, one failing and one passing each. The passing samples include a comment and a string that name a retired key, and `config.text` (an action bar text table, which is not a color group).

## File structure

| File | Responsibility | Task |
| --- | --- | --- |
| `SaftUI-Core/Media/colors.lua` | the accessor; `OLD_COLORS`, the steps, `st:MigrateColors`; the Colors page's sections; `CO:AccentOption` | 1–5 |
| `SaftUI-Core/Config/defaults.lua` | `st.defaults.colors` (new groups and keys), `st.defaults.theme.accent` | 1–5 |
| `SaftUI-Core/Config/config.lua` | the migration's two calls; `'accent'` after `'theme'` | 1, 2 |
| `SaftUI-Core/Media/theme.lua` | the Theme tab's Accent row | 2 |
| `SaftUI-Core/api.lua` | the chat prefix, DEBUG, the Error prefix at print time | 2, 4 |
| the readers | each task's list | 1–5 |
| `tests/lib/source_lex.lua` (new) | the lexer the scan uses | 1 |
| `tests/core/color_access_test.lua` (new) | the accessor, the prefix, the update's `'accent'` | 1, 2, 4 |
| `tests/core/color_migration_test.lua` (new) | every step, on a real AceDB | 1–5 |
| `tests/core/color_reads_test.lua` (new) | the scan | 1–5 |
| `tests/core/colors_test.lua`, `theme_tab_test.lua` | the two pages | 1–5, 2 |
| `tests/loot/loot_colors_test.lua`, `tests/unitframes/role_colors_test.lua` (new) | Task 1's readers | 1, 4 |
| `tests/core/accent_test.lua`, `muted_test.lua`, `state_colors_test.lua`, `button_opacity_test.lua` (new) | each task's Core readers, in the options window's world (`options_window_helpers.lua`) | 2, 3, 4, 5 |

---

### Task 1: The accessor, the migration, and Roles, Factions and Loot

**Files:**
- Modify:
  - `SaftUI-Core/Media/colors.lua`: `st:Color`, `st:ColorRGBA`, `CO.OLD_COLORS`, `CO.MIGRATION_STEPS` (step 1), `st:MigrateColors`. `CO.SECTIONS` gains Roles, Factions and Loot. Text loses Purple and Buttons loses Yellow, and their descriptions drop the moved uses (and Text > Green's stale "edit mode being on"). The `st:ColorsChanged` header names the new groups.
  - `SaftUI-Core/Config/defaults.lua`: `roles`, `factions` and `loot`; drop `text.purple` and `button.yellow`.
  - `SaftUI-Core/Config/config.lua:88,266`: M7.
  - `SaftUI-Loot/rollbar.lua:12-15`, `roll.lua:89`, `rollinfo.lua:76-79,113`, `Feed/rolls.lua:39-43,57-63,127,141,165,196`, `Feed/feed.lua:139-150`.
  - `SaftUI-Misc/Skinning/blizzard/ZoneText.lua:55-58,88-92,287-293`: `ZT.FACTION_COLORS` goes. `ZT:ColorFaction` reads `st:Color('factions', faction)`. `ZT:OnColorsChanged` refreshes the zone line on `'factions'` as on `'text'`.
  - `SaftUI-Unitframes/elements/indicators.lua:44-48,60-66`: the two descriptions name no hue.
  - `SaftUI-Unitframes/grouppreview.lua:173,293-298`; `SaftUI-Unitframes/unitframes.lua:8,218-222` (Ruling 11).
- Create: `tests/lib/source_lex.lua`, `tests/core/color_access_test.lua`, `tests/core/color_migration_test.lua`, `tests/core/color_reads_test.lua`, `tests/loot/loot_colors_test.lua`, `tests/unitframes/role_colors_test.lua`.
- Test (modify):
  - `tests/core/colors_test.lua`: sections, rows, notes.
  - `tests/misc/zone_text_test.lua:131-142,285-` (words in Factions), `tests/misc/zone_map_test.lua`, `tests/misc/zone_helpers.lua`.
  - `tests/loot/theme_test.lua`, wherever it reads Buttons > Yellow or `'purple'`.
- Docs:
  - `AGENTS.md`: the Core row says `Media/colors.lua` holds the color accessor and the colors' migration.
  - `.agents/architecture.md`:
    - covers gains `'SaftUI-Core/Media/colors.lua'`;
    - the `OnColorsChanged` groups (line 53) gain `roles`, `factions`, `loot`;
    - "Colors other than the theme's live in `st.config.profile.colors`" (line 63) becomes "are read through `st:Color(group, key)` and `st:ColorRGBA(group, key, strength)` (`Media/colors.lua`), which error on a key with no default";
    - the profile update's step 1 (line 92) gains `st:MigrateColors`;
    - "A module that converts its profile once" (line 104) gains `colors.version`, `CO.OLD_COLORS`, the steps and the rules above in brief.
  - `.agents/edit-mode.md:183`: the Colors tab's twelve sections, in order.
  - `.agents/testing.md`: the new files in the `tests/core/`, `tests/loot/`, `tests/unitframes/` and `tests/lib/` rows.
  - `docs/design-system/tokens.json`: `text-purple` becomes `loot-transmog`, and `button-yellow` becomes `loot-mount` (usage: a mount's entry in the loot feed). Add `loot-need`, `loot-greed`, `loot-pass`, `role-tank`, `role-healer`, `role-damage`, `faction-alliance`, `faction-horde` and `faction-neutral`, each with its value and a one-line usage.
  - `docs/followups.md`:
    - "Colors tab: role and rune colors, and a switch for Blizzard's class colors" gets `**Update 2026-11-14:**` saying the role colors were built (Roles section, `colors.roles`); rune colors and the class switch stay, and the entry stays Active.
    - Add an entry (template, ToC link), "Three copies of the source lexer in tests", anchored on `tests/lib/source_lex.lua`, `tests/core/theme_kinds_test.lua` and `tests/tracker/source_scan_test.lua`.

**Interfaces:**
- Produces:
  - `st:Color(group: string, key: string|nil) -> color`, by Ruling 5.
  - `st:ColorRGBA(group: string, key: string|nil, strength: number|nil) -> r, g, b, a`, where `a = (strength or 1) * (color.a or 1)`.
  - `CO.OLD_COLORS`, `CO.MIGRATION_STEPS` and `st:MigrateColors(profile: table) -> nil`, as under The migration. `CO` is `st:GetModule('Colors')`.
  - In `st.defaults.colors`:

```lua
roles = { TANK = CreateColor(0, 0.68, 0.94), HEALER = CreateColor(60/255, 240/255, 60/255), DAMAGER = CreateColor(220/255, 100/255, 100/255) },
factions = { Alliance = CreateColor(0, 0.68, 0.94), Horde = CreateColor(220/255, 100/255, 100/255), Neutral = CreateColor(200/255, 200/255, 100/255) },
loot = { need = CreateColor(1, 1, 1), greed = CreateColor(200/255, 200/255, 100/255), transmog = CreateColor(197/255, 128/255, 1), pass = CreateColor(220/255, 100/255, 100/255), mount = CreateColor(0.6, 0.6, 0.1) },
```

  - Sections: `{ key = 'roles', name = 'Roles', note = RELOAD_NOTE }` after Class, `{ key = 'factions', name = 'Factions', note = RELOAD_NOTE }` after Reputation, and `{ key = 'loot', name = 'Loot', note = RELOAD_NOTE }` after Item quality. Their rows:
    - Roles: `TANK` Tank, `HEALER` Healer, `DAMAGER` Damage.
    - Factions: `Alliance`, `Horde`, `Neutral`, labeled as their keys.
    - Loot: `need` Need, `greed` Greed, `transmog` Transmog, `pass` Pass, `mount` Mount.

    Each row's description comes from the spec's "What each role colors" (the builder words them).
  - The group names `st:ColorsChanged` passes gain `'roles'`, `'factions'` and `'loot'`.

- [ ] **Step 1: Write the failing tests**

`color_access_test.lua` (the `core/config_helpers.lua` world):

```lua
test("Color: the profile's own object, read at call time; after a switch, the new profile's", function()
	check(st:Color('loot', 'pass') == st.config.profile.colors.loot.pass)
	st.config:SetProfile('Two'); check(st:Color('loot', 'pass') == st.config.profile.colors.loot.pass)
end)
test('before st.config exists, the default', function()
	local keep = st.config; st.config = nil
	check(st:Color('roles', 'TANK') == st.defaults.colors.roles.TANK); st.config = keep
end)
test('a group or key with no default raises its name', function()
	local ok, err = pcall(st.Color, st, 'text', 'purple'); check(not ok and err:find('SaftUI: no color text.purple', 1, true))
	ok, err = pcall(st.Color, st, 'hues', 'x'); check(not ok and err:find('SaftUI: no color hues.x', 1, true))
	st.config.profile.colors.text.purple = CreateColor(1, 0, 0)
	check(not pcall(st.Color, st, 'text', 'purple'), 'a saved table with no default is still an error')
	st.config.profile.colors.text.purple = nil
end)
test('a group that is not a table reads as the default', function() -- Review Focus 1
	local keep = st.config.profile.colors.loot; st.config.profile.colors.loot = 'x'
	check(st:Color('loot', 'pass') == st.defaults.colors.loot.pass); st.config.profile.colors.loot = keep
end)
test('ColorRGBA: strength times opacity, a nil alpha as 1', function()
	eq(select(4, st:ColorRGBA('text', 'normal')), 1)
	eq(select(4, st:ColorRGBA('text', 'normal', 0.25)), 0.25)
	st.config.profile.colors.button.hover.a = 0.5
	eq(select(4, st:ColorRGBA('button', 'hover', 0.4)), 0.2)
end)
```

`color_migration_test.lua` (`fresh(saved)`, `char_key()` and the module defaults copied from `theme_migration_test.lua:29-53`):

```lua
local function on(profile) return { profileKeys = { [char_key()] = 'Old' }, profiles = { Old = profile } } end
local function rgb(c) return T.rgb(c.r, c.g, c.b) end
local function LAST() return #st:GetModule('Colors').MIGRATION_STEPS end
local RED, YELLOW, BLUE = T.rgb(220/255, 100/255, 100/255), T.rgb(200/255, 200/255, 100/255), T.rgb(0, 0.68, 0.94)

test('nothing saved: only the version, every destination at its default, nothing saved for them', function()
	fresh(on({}))
	local colors = st.config.profile.colors
	eq(colors.version, LAST())
	eq(rgb(colors.loot.pass), RED); eq(rgb(colors.roles.TANK), BLUE); eq(rgb(colors.factions.Neutral), YELLOW)
	st.config:SetProfile('Two')
	eq(SaftUI_DB.profiles.Old.colors.version, LAST()); eq(SaftUI_DB.profiles.Old.colors.loot, nil)
end)
test('one saved channel: the rest from OLD_COLORS, into every destination of the split, methods kept', function()
	fresh(on({ colors = { text = { red = { r = 1 } } } }))
	for _, d in ipairs({ { 'loot', 'pass' }, { 'roles', 'DAMAGER' }, { 'factions', 'Horde' } }) do
		local c = st.config.profile.colors[d[1]][d[2]]
		eq(rgb(c), T.rgb(1, 100/255, 100/255), d[2]); eq(type(c.GetRGB), 'function', d[2])
	end
	st.config:SetProfile('Two')
	local saved = SaftUI_DB.profiles.Old.colors.loot.pass
	eq(saved.r, 1); eq(saved.g, nil, 'AceDB keeps only the channel that differs')
end)
test('retired sources move and go: Text > Purple to Transmog, Buttons > Yellow to Mount, never its alpha', function()
	fresh(on({ colors = { text = { purple = { g = 0 } }, button = { yellow = { b = 0.5, a = 0.3 } } } }))
	local colors = st.config.profile.colors
	eq(rgb(colors.loot.transmog), T.rgb(197/255, 0, 1)); eq(rgb(colors.loot.mount), T.rgb(0.6, 0.6, 0.5))
	eq(colors.loot.mount.a, nil)
	eq(rawget(colors.text, 'purple'), nil); eq(rawget(colors.button, 'yellow'), nil)
end)
test('a source equal to its old value to the byte copies nothing (raw data)', function()
	local raw = { colors = { text = { red = { r = 220/255 + 0.001 } } } }
	st:MigrateColors(raw)
	eq(raw.colors.loot, nil); eq(raw.colors.roles, nil); eq(raw.colors.factions, nil); eq(raw.colors.version, LAST())
end)
test('raw data: a group and a destination are made only where a copy lands', function()
	local raw = { colors = { text = { blue = { b = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.roles.TANK), T.rgb(0, 0.68, 0.5)); eq(rgb(raw.colors.factions.Alliance), T.rgb(0, 0.68, 0.5))
	eq(raw.colors.loot, nil); eq(raw.colors.roles.HEALER, nil)
end)
test('run twice: no change', function()
	local raw = { colors = { text = { red = { r = 1 }, purple = { g = 0 } } } }
	st:MigrateColors(raw); local once = Dump(raw)
	st:MigrateColors(raw); eq(Dump(raw), once)
	check(pcall(st.MigrateColors, st, nil), 'a nil profile is left alone')
	local empty = {}; st:MigrateColors(empty); eq(next(empty), nil, 'no colors table: nothing written')
end)
test('a switch to, a copy from and a reset of an unmigrated profile', function()
	fresh(on({}))
	SaftUI_DB.profiles.Two = { colors = { text = { red = { r = 1 } } } }
	SaftUI_DB.profiles.Three = { colors = { text = { yellow = { r = 1 } } } }
	st.config:SetProfile('Two'); eq(st.config.profile.colors.loot.pass.r, 1); eq(st.config.profile.colors.version, LAST())
	st.config:SetProfile('Old'); st.config:CopyProfile('Three')
	eq(st.config.profile.colors.factions.Neutral.r, 1); eq(st.config.profile.colors.version, LAST())
	check(st.config.profile.colors.factions.Neutral.GetRGB, 'a copied profile keeps the methods')
	st.config.profile.colors.loot.pass.r = 0.5; st.config:ResetProfile()
	eq(rgb(st.config.profile.colors.loot.pass), RED); eq(st.config.profile.colors.version, LAST())
end)
test('in combat a switch migrates at once', function()
	fresh(on({})); SaftUI_DB.profiles.Two = { colors = { text = { red = { r = 1 } } } }
	stub.in_combat = true; st.config:SetProfile('Two')
	eq(st.config.profile.colors.loot.pass.r, 1); eq(#stub.blocked, 0); stub.in_combat = false
end)
test('saved data the migration does not expect: nothing errors and nothing is lowered', function() -- Review Focus 1
	for _, raw in ipairs({ { colors = 'x' }, { colors = { text = 'x' } }, { colors = { text = { red = 5 } } },
		{ colors = { text = { red = { r = 'x', g = 0 } } } }, { colors = { version = 'x' } } }) do
		check(pcall(st.MigrateColors, st, raw))
	end
	local raw = { colors = { text = { red = { r = 'x', g = 0 } } } }; st:MigrateColors(raw)
	eq(rgb(raw.colors.loot.pass), T.rgb(220/255, 0, 100/255), "a channel that isn't a number takes the old default's")
	raw = { colors = { version = 99, text = { red = { r = 1 } } } }; st:MigrateColors(raw)
	eq(raw.colors.version, 99); eq(raw.colors.loot, nil)
	fresh(on({ colors = { text = { red = 5 }, version = 'x' } })); eq(#take_errors(), 0)
	eq(st.config.profile.colors.version, LAST())
end)
```

(`Dump(t) -> string` is the test file's own: keys sorted with `tostring`, tables recursed, so two equal tables give one string. `tests/lib/` has none.)

Also in `color_migration_test.lua`, a fixture that every later task extends:

```lua
-- A profile as today's build saves it, every hue customized in part.
local function OLD_SAVED()
	return { colors = {
		text = { red = { r = 1 }, orange = { g = 0.2 }, yellow = { b = 0 }, green = { r = 0.5 }, grey = { r = 0.4 },
			blue = { g = 0.1 }, purple = { r = 0.3 }, cyan = { b = 0.2 }, white = { g = 0.9 } },
		button = { red = { r = 0.9, a = 0.5 }, green = { g = 0.9 }, blue = { r = 0.7, a = 0.2 }, yellow = { b = 0.4 },
			grey = { r = 0.2 }, normal = { a = 0.3 }, hover = { r = 0.6 }, pushed = { a = 0.1 } },
	} }
end
-- path -> T.rgb of what it holds after every step; each task adds its rows.
local EXPECTED = {
	['loot.need'] = T.rgb(1, 0.9, 1), ['loot.greed'] = T.rgb(200/255, 200/255, 0), ['loot.transmog'] = T.rgb(0.3, 128/255, 1),
	['loot.pass'] = T.rgb(1, 100/255, 100/255), ['loot.mount'] = T.rgb(0.6, 0.6, 0.4),
	['roles.TANK'] = T.rgb(0, 0.1, 0.94), ['roles.HEALER'] = T.rgb(0.5, 240/255, 60/255), ['roles.DAMAGER'] = T.rgb(1, 100/255, 100/255),
	['factions.Alliance'] = T.rgb(0, 0.1, 0.94), ['factions.Horde'] = T.rgb(1, 100/255, 100/255), ['factions.Neutral'] = T.rgb(200/255, 200/255, 0),
}
test('a profile saved before any of this runs every step at once, in order', function()
	fresh(on(OLD_SAVED()))
	for path, want in pairs(EXPECTED) do eq(rgb(Slot(st.config.profile, path)), want, path) end
	eq(st.config.profile.colors.version, LAST())
end)
```

(`Slot(profile, path)` is the test's own copy of M4's lookup.)

`color_reads_test.lua`: the samples case and the scan, for rules A, B and C (The scan), plus `'the scan reads every file the TOCs load, colors.lua among them'` (more than 200 files, `SaftUI-Tracker/rows.lua` and `SaftUI-Core/Media/colors.lua` included).

`colors_test.lua`:

```lua
-- the sections case
eq(table.concat(names, ','), 'Text,Buttons,Class,Roles,Reputation,Factions,Power,Item quality,Loot,Status,Threat,Objectives')
-- expected gains:
--   text = 'Text,Grey,Red,Orange,Yellow,Green,Blue,Cyan,White'
--   button = 'Normal,Hover,Pushed,Red,Green,Blue,Grey'
--   roles = 'Tank,Healer,Damage'; factions = 'Alliance,Horde,Neutral'
--   loot = 'Need,Greed,Transmog,Pass,Mount'
-- the notes case: text, button, roles, factions, loot carry NOTE; the other seven none
test("a Roles, Factions or Loot set and reset write the profile's own object and say their group", ...)
-- the zone-word assertions at :233-235 move to Factions' descs (each names the zone text)
```

`loot_colors_test.lua` (the Loot world `roll_skin_test.lua` builds):

```lua
test('each roll letter takes its Loot color, and a changed Text color reaches none of them', function()
	-- defaults: Pass RED, Greed YELLOW, Transmog 197/128/255, Need white (T.rgb of each letter's vertex color)
	-- colors.text.red, .yellow, .white set to 0,0,0 before a roll is skinned: the letters keep their Loot defaults
	-- colors.loot.pass set to 0,1,0: the next skinned Pass letter is 0,1,0
end)
test("the paired counts and the feed's roll tooltip read Loot: All passed and Pass: in Pass", ...)
test("a mount's feed entry: border and icon border in Loot > Mount, its fill at 60%", ...)
```

`role_colors_test.lua` (the unit frames world `boss_preview_test.lua` builds):

```lua
test('the role corner takes Roles: Tank, Healer, and Damage with Show damage dealers', ...)
-- postUpdate with UnitGroupRolesAssigned TANK / HEALER / DAMAGER: the corner's vertex color is roles.<role>
-- colors.text.blue, .green, .red changed: no corner changes
test("the party preview's corners take Roles too", ...)
test('UF:UpdateColors leaves oUF its own role colors', function()
	-- UF.oUF.colors.roles is the table oUF loaded with, before and after UF:UpdateColors()
end)
```

`zone_text_test.lua`: `"each word takes its Factions color: Alliance blue, Horde red, Neutral yellow"`. `'a Factions change recolors a line still on screen, and a Text > Red change does not'` fires `st:ColorsChanged('factions')`, then `'text'`.

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/color_access_test.lua tests/core/color_migration_test.lua tests/core/color_reads_test.lua tests/core/colors_test.lua tests/loot/loot_colors_test.lua tests/unitframes/role_colors_test.lua tests/misc/zone_text_test.lua`. Expected: FAIL, `attempt to call method 'Color' (a nil value)`.
- [ ] **Step 3: Implement** the accessor, the migration with step 1, the defaults, the sections, the readers and M7, as the Interfaces say.
- [ ] **Step 4: Run** the same files, then `tests/run -j2`. Expected: PASS. Each changed assertion is listed in the report.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit**

```bash
git add SaftUI-Core/Media/colors.lua SaftUI-Core/Config/defaults.lua SaftUI-Core/Config/config.lua SaftUI-Loot/rollbar.lua SaftUI-Loot/roll.lua SaftUI-Loot/rollinfo.lua SaftUI-Loot/Feed/rolls.lua SaftUI-Loot/Feed/feed.lua SaftUI-Misc/Skinning/blizzard/ZoneText.lua SaftUI-Unitframes/elements/indicators.lua SaftUI-Unitframes/grouppreview.lua SaftUI-Unitframes/unitframes.lua tests/lib/source_lex.lua tests/core/color_access_test.lua tests/core/color_migration_test.lua tests/core/color_reads_test.lua tests/core/colors_test.lua tests/loot/loot_colors_test.lua tests/unitframes/role_colors_test.lua tests/misc/zone_text_test.lua tests/misc/zone_map_test.lua tests/misc/zone_helpers.lua tests/loot/theme_test.lua AGENTS.md .agents/architecture.md .agents/edit-mode.md .agents/testing.md docs/design-system/tokens.json docs/followups.md
git commit -m "core: add the color accessor and its migration, with Roles, Factions and Loot of their own"
```

(Add any other test file the run showed reading `text.purple` or `button.yellow`, by path.)

**In-game checks (both clients):**
- Log in on a profile with colors set before this build: no Lua error. A customized Text > Red now shows on Pass, Damage and Horde as well.
- Loot roll letters and counts, the feed's roll tooltip and a mount entry look as before.
- The zone text in a friendly, a hostile and a contested zone looks as before.
- Role corners in a group and in test mode look as before.
- Change Pass, Horde and Damage on the Colors page and see each move alone (Damage after a reload). Text > Red still colors errors.
- Switch profiles and back: the colors follow.

---

### Task 2: The accent

**Files:**
- Modify (Core):
  - `Media/colors.lua`: step 2, `CO:AccentOption`, the sections (Text loses Blue; Buttons loses Green and Blue), the header's `'accent'`.
  - `Config/defaults.lua`: `theme.accent`; drop `text.blue`, `button.blue`, `button.green`.
  - `Media/theme.lua:160-231`: the `accent` row at 5.5.
  - `Config/config.lua:247-250,320`: Ruling 4.
  - `api.lua:207-215`: the prefix at print time, Ruling 15.
  - `skinning.lua:266`; `Widgets/radiogroup.lua:27`.
  - `Config/optionsbody.lua:226-241,765`: `OB.Accent`, and `OB.OWN_STRENGTH = 1` in place of `OB.OWN_TEXT`.
  - `optionscontrols.lua:107,118`; `optionsitem.lua:60`; `optionskeybinding.lua:154`; `optionslayout.lua:367`; `optionslist.lua:70,172,206`; `optionslook.lua:81,475`; `optionsnav.lua:24,113-114,131,242,748`; `optionsposition.lua:43`; `optionsrange.lua:131`; `optionsshare.lua:115,151,189,273-274,406,409,537,550,635`; `optionswindow.lua:222,847,1707`.
  - `EditMode/mover.lua:100,357-363` (Ruling 13); `grid.lua:74`; `snap.lua:250`; `coordinates.lua:205`; `picker.lua:121`; `Bar/bardock.lua:294`; `Bar/historylist.lua:196,199`.
- Modify (others):
  - Bags:
    - `header.lua:51,226-234` (lit on `'accent'`);
    - `slot.lua:107-110` (the handler), `:229-234` (Question 1);
    - `inventory.lua:84`;
    - `categoriestab.lua:643-645,1002`;
    - `dragparts.lua:119`;
    - `ruleeditor.lua:91-93` (Question 2: AND), `:497,529,712`;
    - `container.lua:85` (Question 3);
    - `containers/bag.lua:76`.
  - Loot: `rollbar.lua:99,120,195` (Question 3); `roll.lua:225` (Question 3) and `:592-600` (on `'accent'`); `Feed/feed.lua:36-40` (lit) and `:160-172` (on `'text'` and `'accent'`).
  - ActionBars: `skin.lua:486` (answer 5); `keybindmode.lua:254`.
  - Misc: `totemskin.lua:296`; `Skinning/blizzard/Blizzard_ColorPicker.lua:334`; `Skinning/blizzard/Blizzard_ObjectiveTracker.lua:433`.
  - Tracker: `rows.lua:110-122` (`StateColor('accent')`).
- Create: `tests/core/accent_test.lua`.
- Test (modify):
  - `tests/core/color_access_test.lua`, `color_migration_test.lua`, `color_reads_test.lua` (rule E, the retired list), `colors_test.lua`, `theme_tab_test.lua`.
  - `tests/lib/harness_self_test.lua:109`.
  - Every other test that reads `text.blue`, `button.blue`, `button.green`, `OWN_TEXT`, `OB.Blue` or `LinkBlue`, read instead as `st.config.profile.theme.accent` or `st:Color('accent')`:
    - `tests/actionbars/page_test.lua`, `theme_test.lua`;
    - `tests/bags/category_tooltip_menu_test.lua`, `theme_test.lua`, `views_switch_test.lua`;
    - `tests/core/editmode_bar_changes_test.lua`, `editmode_bar_hide_test.lua`, `editmode_bar_test.lua`, `editmode_coordinates_test.lua`, `editmode_filter_test.lua`, `editmode_snap_world_test.lua`;
    - `tests/core/options_body_test.lua`, `options_color_picker_test.lua`, `options_controls_test.lua`, `options_default_test.lua`, `options_fields_test.lua`, `options_item_test.lua`, `options_list_test.lua`, `options_menu_test.lua`, `options_mini_test.lua`, `options_position_test.lua`, `options_share_test.lua`, `options_sidebar_test.lua`, `options_sizes_test.lua`, `options_widget_look_test.lua`;
    - `tests/core/theme_blizzard_controls_test.lua`, `theme_blizzard_editmode_test.lua`, `theme_core_frames_test.lua`;
    - `tests/loot/roll_held_test.lua`;
    - `tests/misc/color_picker_skin_test.lua`, `theme_test.lua`;
    - `tests/tracker/rows_test.lua`.
- Docs:
  - `.agents/architecture.md`: the groups gain `accent` (Theme > Accent, `theme.accent`); the profile update's step 8 fires `'accent'` after `'theme'`.
  - `.agents/edit-mode.md`:
    - line 184: the Theme tab's rows with Accent;
    - every "Button > Blue", "Buttons > Blue" and "Text > Blue" that means the accent says "the accent (Theme > Accent)";
    - `OB.OWN_TEXT` becomes `OB.OWN_STRENGTH`, and `OB.Blue` becomes `OB.Accent`.
  - `.agents/testing.md`: `accent_test.lua`.
  - `docs/design-system/`:
    - `tokens.json`: `accent`'s usage (Theme > Accent, `theme.accent`, `st:Color('accent')`), and `accent-fill`, `accent-tint`, `grid-centre`'s usage. Remove `own` (the own marks are the accent at `OB.OWN_STRENGTH`) and `button-green`.
    - `components/bundle.css`: drop `--own` and use `--accent`.
    - Every page `grep -rlE -- '--own|button-green|Buttons? > (Blue|Green)|Text > Blue' docs/design-system` lists (at `42452b9`: `README.md` and the Cover, DiffIcon, Tooltip, OwnMark, ActionButton and Mover pages), except `25-colour-roles.md`, which is a record (Ruling 1).
    - `05-decisions.md`: 7 gets "Built: Theme > Accent (color roles, Task 2)".
    - `10-discrepancies.md` 26: the two light blues and two blues are one accent now.
    - `30-code-changes.md` 11: the chat prefix item done.
  - `docs/followups.md`: "Design decisions waiting to be built" drops the 7 line.

**Interfaces:**
- Consumes: Task 1's `st:Color`, `st:ColorRGBA`, `CO.MIGRATION_STEPS` and the scan.
- Produces:
  - `st.defaults.theme.accent = CreateColor(0, 0.68, 0.94)` (no alpha).
  - `CO:AccentOption(order: number) -> option`. It is `type = 'color'`, `size = 'small'`, `name = 'Accent'`, with no `hasAlpha`.
    - `get` returns `st:Color('accent'):GetRGB()`.
    - `set` writes `r, g, b` into `st.config.profile.theme.accent` in place, then `st:ColorsChanged('accent')`.
    - `default` is `{ differs, reset, value }` against `st.defaults.theme.accent`, by bytes. `reset` writes in place and fires `'accent'`.
    - Desc gist: "SaftUI's accent under every theme: what is on, picked, current or under the mouse in SaftUI's frames and windows, its links, and the chat prefix." Then the reload note.
  - `TH:GetConfigTable().args.accent = st:GetModule('Colors'):AccentOption(5.5)`.
  - `OB.Accent() -> r, g, b`, exported as `S.Accent` too, and `OB.OWN_STRENGTH = 1`. Own labels, titles and the hover line's Own draw with `SetTextColor(st:ColorRGBA('accent', nil, OB.OWN_STRENGTH))`; the tooltip values take `st:Color('accent'):GetRGB()` (Ruling 14).
  - Tints at `st.TINT_ROW` read `st:ColorRGBA('accent', nil, st.TINT_ROW)`. A selected mover's fill (a literal 0.15 today, `mover.lua:101`) reads `st:ColorRGBA('accent', nil, st.TINT_OBJECT)`.
  - `st:Print(...)`: `'[|cff' .. hex .. 'SaftUI|r]: '`, where `hex` is `st.StringFormat:ToHex(st:Color('accent'):GetRGB())`, read at each call (Ruling 15). `st:Error` builds the same prefix.
  - The handlers:
    - `LT:ColorRollBars` runs on `'accent'`;
    - `INV:OnColorsChanged` runs `ColorViewButtons` on `'accent'` (lit) and `'text'` (glyphs), not `'button'`;
    - `LT:ColorFeed` tints its buttons on `'text'` and `'accent'`;
    - `EM:OnColorsChanged` recolors movers on `'accent'` as on `'theme'`.
  - Rule E's Task 2 list and Rule A's Task 2 keys.

- [ ] **Step 1: Write the failing tests**

```lua
-- color_migration_test.lua
test('step 2: the accent takes Buttons > Blue, never Text > Blue; Buttons > Green is dropped', function()
	fresh(on({ colors = { text = { blue = { r = 0.9 } }, button = { blue = { g = 0.2, a = 0.3 }, green = { r = 1 } } } }))
	local p = st.config.profile
	eq(rgb(p.theme.accent), T.rgb(0, 0.2, 0.94)); eq(p.theme.accent.a, nil); eq(type(p.theme.accent.GetRGB), 'function')
	eq(rgb(p.colors.roles.TANK), T.rgb(0.9, 0.68, 0.94), 'Text > Blue went to Tank and Alliance at step 1')
	eq(rawget(p.colors.text, 'blue'), nil); eq(rawget(p.colors.button, 'blue'), nil); eq(rawget(p.colors.button, 'green'), nil)
end)
test('a profile at version 1 runs step 2 alone', function()
	local raw = { colors = { version = 1, text = { blue = { r = 0.9 } }, button = { blue = { r = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.theme.accent), T.rgb(0.5, 0.68, 0.94)); eq(raw.colors.roles, nil, 'step 1 is not run again'); eq(raw.colors.version, LAST())
end)
-- EXPECTED gains ['accent'] = T.rgb(0.7, 0.68, 0.94)

-- color_access_test.lua
test("Color('accent') is the profile's theme.accent; a key passed is ignored", ...)
test('a profile update fires accent after theme', function()
	-- record st:ColorsChanged; st.config:SetProfile('Two'): '...theme,accent' at the end of the list
end)
test('a profile update in combat: migrated at once, theme then accent after combat', function() -- Review Focus 2
	-- stub.in_combat = true; SetProfile to an unmigrated profile: colors.version set and destinations written now;
	-- neither 'theme' nor 'accent' recorded yet; end combat (fire PLAYER_REGEN_ENABLED): 'theme' then 'accent'; #stub.blocked == 0
end)
test("st:Print's prefix is the accent at print time", function()
	-- capture print: '[|cff00adf0SaftUI|r]: ' at the defaults (the listed one-step change from 00adef)
	-- accent set to 1, 0, 0: the next print starts '[|cffff0000SaftUI|r]'
end)
test('a print before the defaults exist', function() -- Review Focus 3
	local keep = st.defaults; st.defaults = nil
	check(pcall(st.Print, st, 'x')); check(printed:find('|cff00adf0SaftUI|r', 1, true)); st.defaults = keep
end)

-- theme_tab_test.lua
-- the rows case: 'Theme,Border,Outer border,Window background,Background,Accent,Options windows'
test('Accent: one color for every theme, no opacity, its own reset, and it says accent', function()
	-- set 0.1, 0.2, 0.3: st:Color('accent') is the same table with those channels; recorded 'accent'
	-- switch to Blizzard and Thin: get returns 0.1, 0.2, 0.3 under each; hasAlpha nil
	-- differs true; reset: back to 0, 0.68, 0.94, 'accent' recorded, differs false
end)

-- accent_test.lua (the options window world, options_window_helpers.lua)
test('the kit draws the accent where it drew Buttons > Blue and Text > Blue: same color at the defaults', function()
	-- slider fill, check mark, the open page's sidebar bar, the tab underline, a list row's hover,
	-- the found label, "Press a key", the picked position dot: each T.rgb == T.rgb(0, 0.68, 0.94)
end)
test('a changed accent reaches each of them after the window draws again, and Roles > Tank stays', ...)
test("own marks are the accent (a listed change from light blue), at OB.OWN_STRENGTH", function()
	-- an own label's text color == accent; OB.OWN_STRENGTH = 0.5 for the case: its alpha 0.5
end)
test('edit mode: a selected mover, the snap guide, the Coordinates label, the hide strip, the History list current step', ...)
test('every live recolor of the accent: a selected mover and the edit mode bar follow at once', ...) -- Review Focus 4

-- each addon's own test file, one case each
-- tests/bags/category_tooltip_menu_test.lua: "the Category: line is the accent (Question 1)"
-- tests/bags/views_switch_test.lua: "a lit view button follows an accent change at once, and a 'button' change no longer moves it" (Review Focus 4)
-- tests/bags/theme_test.lua: "the loading bar fills in the accent (Question 3)"
-- tests/bags/rule_editor_test.lua: "AND's line, connector and badge in the accent; OR keeps its orange (Question 2)"
-- tests/loot/roll_held_test.lua: "a held roll's border and label follow an accent change at once; the timer bars fill in the accent (Question 3)"
-- tests/loot/feed_buttons_test.lua: "a lit feed button follows an accent change" (Review Focus 4)
-- tests/actionbars/theme_test.lua: "an equipped item's border is the accent (answer 5, a listed change from green)"
-- tests/tracker/rows_test.lua: "the focus bar, row hover, current-zone pin and popup bar follow the accent on st:ColorsChanged('accent')"
```

`color_reads_test.lua`: Rule A gains the Task 2 keys and Rule E its first list, each with its samples.

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/color_migration_test.lua tests/core/color_access_test.lua tests/core/theme_tab_test.lua tests/core/accent_test.lua tests/core/color_reads_test.lua`. Expected: FAIL, `SaftUI: no color accent`.
- [ ] **Step 3: Implement** the default, step 2, the Accent row, the update's `'accent'`, the prefix, the readers and the handlers, as the Interfaces say.
- [ ] **Step 4: Run** the same files and every test file under Files, then `tests/run -j2`. Expected: PASS. Each changed assertion is listed in the report.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit.** Stage every path under Files explicitly.

```bash
git commit -m "core: make Blue one accent on the Theme tab, read by everything blue"
```

**In-game checks (both clients):**
- At the defaults, everything blue looks as before. Own labels and the own mark are both the accent. An equipped item's border is the accent. The chat prefix is the accent.
- Theme > Accent sits between Background and Options windows and recolors, at once:
  - `/sui`'s sidebar, tabs, sliders and checks;
  - the edit mode bar and a selected mover;
  - the tracker's focus bar;
  - a held roll's border.
- After a reload it also recolors bag and totem hover and an equipped item's border.
- Roles > Tank and Factions > Alliance stay put.
- "Category:" in a bag tooltip, the rule editor's AND and the bags' loading bar are the accent. The roll timer bars are the accent.
- On a profile with a customized Buttons > Blue, the accent is that color.

---

### Task 3: Muted

**Files:**
- Modify:
  - Core:
    - `Media/colors.lua`: step 3; Grey becomes Muted (key `muted`, label Muted); Buttons loses Grey.
    - `Config/defaults.lua`: `text.muted = CreateColor(150/255, 150/255, 150/255)`; drop `text.grey`, `button.grey`.
    - `panels.lua:367`.
    - `Config/optionsbody.lua:229,239-241,764-766,795,824,915,923,1226` (`OB.Muted`, and `OB.DIFF_STRENGTH = 1` in place of `OB.DIFF_COLOR`).
    - `optionscolorpicker.lua:894`; `optionscontrols.lua:107,182,306,376,387`; `optionsitem.lua:56`; `optionskeybinding.lua:160`; `optionslist.lua:68`; `optionsmenu.lua:92,189`; `optionsnav.lua:24,203,250,289,709,746,752,755`; `optionsposition.lua:251`; `optionsselect.lua:30`; `optionsshare.lua:114,140,187,412,413,562,642`; `optionssizes.lua:76,386-387`; `optionstypes.lua:379`; `optionswindow.lua:222,1302,1365,1384,1419,1456,1490,1707`.
    - `EditMode/picker.lua:128` (Buttons > Grey); `Bar/barchanges.lua:96,144`; `Bar/barshow.lua:131-132`; `Bar/barwindow.lua:338`; `Bar/historylist.lua:187-189,201,238`.
  - Bags: `dragparts.lua:14,44,72`; `categoriestab.lua:140,654,659` (the marker, from Text > Orange), and its other `Grey` uses; `ruleeditor.lua:88` and its `Grey` uses; `views.lua:192`; `containers/combinedbank.lua:51` (Buttons > Grey); `slot.lua:233`.
  - Misc: `Skinning/addons/restedxp.lua:168-169,180,238,316` (`MutedRGB`); `Skinning/blizzard/Blizzard_ObjectiveTracker.lua:189`.
  - Tracker: `rows.lua:118,508,510,530` (state `'muted'`); `window.lua:108,490`.
  - Unitframes: `tags.lua:9-21` (a far lower level's tag).
- Create: `tests/core/muted_test.lua`.
- Test (modify):
  - `color_migration_test.lua`, `color_reads_test.lua`, `colors_test.lua`.
  - Every test that reads `text.grey`, `button.grey`, `DIFF_COLOR`, `OB.Grey` or `GreyRGB`:
    - `tests/bags/categories_list_test.lua`, `category_tooltip_menu_test.lua`, `views_data_test.lua`;
    - `tests/core/editmode_bar_changes_test.lua`, `editmode_bar_test.lua`;
    - `tests/core/options_color_picker_test.lua`, `options_controls_test.lua`, `options_default_test.lua`, `options_fields_test.lua`, `options_item_test.lua`, `options_kit_test.lua`, `options_list_test.lua`, `options_menu_test.lua`, `options_mini_test.lua`, `options_position_test.lua`, `options_range_test.lua`, `options_rerender_test.lua`, `options_settings_test.lua`, `options_share_test.lua`, `options_sidebar_test.lua`, `options_sizes_test.lua`, `options_window_look_test.lua`;
    - `tests/misc/restedxp_helpers.lua`;
    - `tests/tracker/rows_test.lua`, `window_test.lua`.
- Docs:
  - `.agents/edit-mode.md`: every "Text > Grey" becomes "Text > Muted", `OB.Grey` becomes `OB.Muted`, and `OB.DIFF_COLOR` becomes `OB.DIFF_STRENGTH`.
  - `.agents/testing.md` lines naming `text.grey`, and `muted_test.lua`.
  - `docs/design-system/`:
    - `tokens.json`: `text-grey` becomes `text-muted` (usage Text > Muted). Remove `diff` (the diff icon is Muted at `OB.DIFF_STRENGTH`).
    - `components/bundle.css`: `--text-grey` becomes `--text-muted`, and `--diff` goes.
    - Every page `grep -rlE -- 'text-grey|--diff|Text > Grey|Buttons? > Grey' docs/design-system` lists, except `25-colour-roles.md` (at `42452b9`: `README.md`, `10-discrepancies.md` and the Button, CloseButton, ColorBar, Cover, Icons, Input, MenuItem, Mover, OptionsWindow, OwnMark, PositionBlock, Range, Row, Section, Select, Toggle and DiffIcon pages).
    - `10-discrepancies.md` 26: the diff orange is Muted now.
  - `docs/followups.md`: nothing.

**Interfaces:**
- Consumes: Task 1's accessor and scan; Task 2's `OB.Accent` beside the new wrappers.
- Produces:
  - `OB.Muted() -> r, g, b`, exported as `S.Muted`; `D.Muted()` in `dragparts.lua`; `MutedRGB()` in `restedxp.lua`; local `Muted()`s.
  - `OB.DIFF_STRENGTH = 1`. The diff icon draws with `SetVertexColor(st:ColorRGBA('text', 'muted', OB.DIFF_STRENGTH))`.
  - The tracker's paint state `'muted'`.

- [ ] **Step 1: Write the failing tests**

```lua
-- color_migration_test.lua
test('step 3: Muted takes Text > Grey; Buttons > Grey is dropped', function()
	fresh(on({ colors = { text = { grey = { r = 0.4 } }, button = { grey = { r = 0.9 } } } }))
	local colors = st.config.profile.colors
	eq(rgb(colors.text.muted), T.rgb(0.4, 150/255, 150/255)); check(colors.text.muted.GetRGB)
	eq(rawget(colors.text, 'grey'), nil); eq(rawget(colors.button, 'grey'), nil)
end)
-- EXPECTED gains ['text.muted'] = T.rgb(0.4, 150/255, 150/255)

-- muted_test.lua (the options window world)
test('section titles, hints, captions and a disabled label are Muted, the same grey at the defaults', ...)
test('the diff icon is Muted at OB.DIFF_STRENGTH (a listed change from orange)', function()
	-- T.rgb of the icon == T.rgb(150/255, 150/255, 150/255); OB.DIFF_STRENGTH = 0.5 for the case: alpha 0.5
end)
test("edit mode's picker hint line is Muted (was Buttons > Grey, the same grey)", ...)
test('a changed Muted reaches them after the window draws again', ...)
-- tests/bags/categories_list_test.lua: "the edited and yours marker is Muted (a listed change from orange)"
-- tests/bags/views_switch_test.lua: "the combined bank's eye toggle is Muted (was Buttons > Grey)"
-- tests/tracker/rows_test.lua: the 'grey' state's cases read 'muted'
```

`colors_test.lua`: text `'Text,Muted,Red,Orange,Yellow,Green,Cyan,White'`, button `'Normal,Hover,Pushed,Red'`. `color_reads_test.lua`: the Task 3 keys and names.

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/color_migration_test.lua tests/core/muted_test.lua tests/core/colors_test.lua tests/core/color_reads_test.lua`. Expected: FAIL, `colors.text.muted` is nil.
- [ ] **Step 3: Implement** the default, step 3, the rows, the wrappers and the readers.
- [ ] **Step 4: Run** the same files and every test file under Files, then `tests/run -j2`. Expected: PASS. Each changed assertion is listed in the report.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit.** Stage every path under Files explicitly.

```bash
git commit -m "core: rename Text > Grey to Muted, with Buttons > Grey, the diff icon and the category marker"
```

**In-game checks (both clients):** hints, captions, section titles and disabled rows look as before. The diff icon beside a differing setting is grey, and so is the bag category's edited marker. The edit mode picker's hint line and the combined bank's eye look as before. A customized Text > Grey is now Muted.

---

### Task 4: The state colors, and every read through the accessor

**Files:**
- Modify:
  - Core:
    - `Media/colors.lua`: step 4; Text's final rows, labels and descriptions; Buttons > Danger.
    - `Config/defaults.lua`: `text.strong`, `danger`, `warning`, `caution`, `success` and `shared` in place of `white`, `red`, `orange`, `yellow`, `green` and `cyan`; `button.danger = CreateColor(0.6, 0.1, 0.1, 0.8)` in place of `red`.
    - `api.lua:213-221` (Error and DEBUG).
    - `panels.lua:358-368` (the close hover's fill from `templates.close.backdropcolor`, and its Danger).
    - `Config/optionsbody.lua:238,697,795,824`; `optionscontrols.lua:55-66` (Ruling 17), `:383`; `optionssmalldialog.lua:190`; `optionswindow.lua:1480`; `optionsshare.lua:268-269` (Strong); `optionsnav.lua:108,392,396`; `optionssizes.lua:105,108`.
    - Every Text > Text read: `optionscolorpicker.lua:897`, `optionskeybinding.lua:157`, `optionslist.lua:72`, `optionslook.lua:37`, `optionsposition.lua:41,284`, `optionsrange.lua:69,144`, `optionstypes.lua:382,656`.
    - `EditMode/Bar/barchanges.lua:121-125,253,272,305`; `Bar/bargroups.lua:148`; `Bar/historylist.lua:151,238`.
  - Bags: `slot.lua:139-143,229-260` (Caution for "Caught by:"), `:483,506`; `currencies.lua:172,263,265`; `header.lua:57`; `containers/bank.lua:56,84,165`; `containers/bag.lua:199`; `containers/combinedbank.lua:131`; `categoriestab.lua:189,574,1390`; `ruleeditor.lua:92,782,824` (Warning, Ruling 21).
  - Loot: `rollbar.lua:204-206` (Danger, Strong); `roll.lua:228-230`; `Feed/rolls.lua:157` (Success); `Feed/feed.lua:39`.
  - Minimap: `microbuttons.lua:139` (Caution); `stats.lua:7-20`.
  - Misc: `durabilitytooltip.lua:54-58`; `totemtimers.lua:155,238,248,316`; `totemskin.lua:304` (`st:Color('button', 'danger')`), `:365`; `Skinning/blizzard/characterframe/characterframe.lua:70,118`; `Skinning/blizzard/ZoneText.lua:173`.
  - Unitframes: `tags.lua:9-62`; `nameplates/threat.lua:153-154`.
  - ActionBars: `skin.lua:445` (`st:Color('button', 'danger')`).
  - Tracker: `rows.lua:119,122` (state `'strong'`); `window.lua:54,106,489`.
- Create: `tests/core/state_colors_test.lua`.
- Test (modify):
  - `color_access_test.lua`, `color_migration_test.lua`, `color_reads_test.lua` (rule D, the retired list, Rule B's text failing, rule E's tip field), `colors_test.lua`; `tests/loot/loot_colors_test.lua`, `tests/unitframes/role_colors_test.lua`, `tests/misc/zone_text_test.lua` (Danger recolors none of them).
  - Every test that reads the seven retired keys or `red = true`:
    - `tests/bags/category_tooltip_menu_test.lua`, `container_pack_test.lua`;
    - `tests/core/editmode_bar_changes_test.lua`, `editmode_bar_test.lua`, `options_body_test.lua`, `options_controls_test.lua`, `options_kit_test.lua`, `options_window_look_test.lua`, `theme_blizzard_windows_test.lua`;
    - `tests/loot/roll_skin_test.lua`;
    - `tests/misc/characterframe_test.lua`, `durability_tooltip_test.lua`;
    - `tests/unitframes/boss_preview_test.lua`, `friendly_plate_test.lua`, `nameplate_layout_test.lua`, `name_color_test.lua`, `secret_texts_test.lua`, `threat_test.lua`;
    - `tests/tracker/rows_test.lua`, `window_test.lua`.
- Docs:
  - `.agents/architecture.md`: the accessor paragraph says every Text, Roles, Factions, Loot and accent read goes through it.
  - `.agents/edit-mode.md`: every Text > Red, White, Orange, Yellow, Green, Cyan becomes its role, and `red = true` becomes `danger = true`.
  - `.agents/testing.md`: `state_colors_test.lua`, and the lines naming the old keys.
  - `docs/design-system/`:
    - `tokens.json`: `white` becomes `text-strong`, `text-red` becomes `text-danger`, `text-orange` becomes `text-warning`, `text-yellow` becomes `text-caution`, `text-green` becomes `text-success`, `text-cyan` becomes `text-shared`, and `button-red` becomes `button-danger`. `flash-fill`'s usage names Buttons > Danger. `close-fill`'s usage says the hover reads `templates.close`.
    - `components/bundle.css`: `--white` and `--text-red` renamed.
    - Every page `grep -rlE -- 'text-(red|orange|yellow|green|cyan)|--white|button-red|Text > (Red|Orange|Yellow|Green|Cyan|White)|Buttons? > Red' docs/design-system` lists, except `25-colour-roles.md` (at `42452b9`: `README.md`, `10-discrepancies.md`, and the CloseButton, Dialog, Icons, Input, OptionsWindow, Tooltip, DiffIcon, ResetIcon, BagSlot, Button, AuraButton, ColorBar, Mover and UnitFrameBar pages).
    - `05-decisions.md` 14: "Built (color roles, Tasks 1–4)".
    - `10-discrepancies.md` 26: resolved, with the Error prefix in Danger.
    - `30-code-changes.md` 11: the close hover and the error prefix done.
  - `docs/followups.md`: "Design decisions waiting to be built" drops the 14 line.

**Interfaces:**
- Consumes: Tasks 1–3.
- Produces:
  - The Text rows: `normal` Text, `muted` Muted, `strong` Strong, `danger` Danger, `warning` Warning, `caution` Caution, `success` Success, `shared` Shared. Buttons: `danger` Danger.
  - `W.ShowTip` reads `line.danger`.
  - `st:Error(...)`: the accent prefix, then `'|cff' .. hex(Danger) .. 'Error|r'`, read at each call, `dc6464` before the defaults (Ruling 15).
  - The tracker's paint state `'strong'`.

- [ ] **Step 1: Write the failing tests**

```lua
-- color_migration_test.lua
test('step 4: each state color takes its hue, and Buttons > Danger takes Buttons > Red, never its alpha', function()
	fresh(on({ colors = { text = { white = { g = 0.9 }, red = { r = 1 }, orange = { g = 0.2 }, yellow = { b = 0 },
		green = { r = 0.5 }, cyan = { b = 0.2 } }, button = { red = { r = 0.9, a = 0.5 } } } }))
	local c = st.config.profile.colors
	eq(rgb(c.text.strong), T.rgb(1, 0.9, 1)); eq(rgb(c.text.danger), T.rgb(1, 100/255, 100/255))
	eq(rgb(c.text.warning), T.rgb(220/255, 0.2, 100/255)); eq(rgb(c.text.caution), T.rgb(200/255, 200/255, 0))
	eq(rgb(c.text.success), T.rgb(0.5, 240/255, 60/255)); eq(rgb(c.text.shared), T.rgb(120/255, 202/255, 0.2))
	eq(rgb(c.button.danger), T.rgb(0.9, 0.1, 0.1)); eq(c.button.danger.a, st.defaults.colors.button.danger.a)
	eq(c.loot.pass.r, 1, 'the same source fed step 1'); eq(c.roles.HEALER.r, 0.5)
	for _, k in ipairs({ 'white', 'red', 'orange', 'yellow', 'green', 'cyan' }) do eq(rawget(c.text, k), nil, k) end
	eq(rawget(c.button, 'red'), nil)
end)
test('step by step across builds', function() -- Review Focus 5
	local raw = { colors = { version = 1, loot = { pass = { r = 0.3 } }, text = { red = { g = 0.5 } } } }
	st:MigrateColors(raw)
	eq(rgb(raw.colors.text.danger), T.rgb(220/255, 0.5, 100/255))
	eq(raw.colors.loot.pass.r, 0.3); eq(raw.colors.loot.pass.g, nil, 'step 1 is not run again')
end)
-- EXPECTED gains text.strong 1/0.9/1, danger 1/100/100, warning 220/0.2/100, caution 200/200/0,
-- success 0.5/240/60, shared 120/202/0.2, button.danger 0.9/0.1/0.1

-- color_access_test.lua
test('the Error prefix is Danger at print time (a listed change from pure red); before the defaults dc6464', ...) -- Review Focus 3
test('DEBUG is Danger', ...)

-- state_colors_test.lua (the options window world)
test('a status line and a tip line given danger = true are Danger, the same red at the defaults', ...)
test("the share line's links and icons under the mouse are Strong", ...)
test("the close button's hover fill is templates.close's, its edge and cross Danger", ...)
test('Text through the accessor: labels, fields and knobs in Text, the same at the defaults', ...)
-- each addon's own test file, one case each, at the defaults equal to the old key's default,
-- then after a change of the new role drawn there:
-- tests/unitframes/name_color_test.lua: level tags (Danger, Warning, Caution, Success, Muted)
-- tests/misc/durability_tooltip_test.lua: Success from 50%, Warning from 20%, Danger under
-- tests/misc/characterframe_test.lua: item levels in Strong
-- tests/bags/*: item levels Strong, Success (Bind on Equip), Shared (Warbound); a price you can't afford Danger;
--   'Caught by:' Caution; the rule editor's OR and its Caught now highlight Warning
-- tests/loot/roll_skin_test.lua: the timer text Strong over a minute, Danger under
-- tests/tracker/rows_test.lua: the progress percent Strong; window_test.lua: the chevron under the mouse Strong
-- loot_colors_test.lua, role_colors_test.lua, zone_text_test.lua:
test('Danger recolors no Pass, Damage or Horde', ...) -- colors.text.danger set: Pass, the Damage corner and Horde keep theirs
```

`colors_test.lua`: text `'Text,Muted,Strong,Danger,Warning,Caution,Success,Shared'`, button `'Normal,Hover,Pushed,Danger'`. The `set` case's `args.red` becomes `args.danger`. No Text, Buttons, Roles, Factions or Loot desc names a hue as a color's name. `color_reads_test.lua`: rule D's Task 4 groups, the retired keys, rule B's text bindings, rule E's tip field.

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/color_migration_test.lua tests/core/color_access_test.lua tests/core/state_colors_test.lua tests/core/colors_test.lua tests/core/color_reads_test.lua`. Expected: FAIL, `colors.text.danger` is nil and rule D lists the direct reads.
- [ ] **Step 3: Implement** the defaults, step 4, the rows, the folds and every remaining Text read through `st:Color`, until rule D lists none.
- [ ] **Step 4: Run** the same files and every test file under Files, then `tests/run -j2`. Expected: PASS. Each changed assertion is listed in the report.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit.** Stage every path under Files explicitly.

```bash
git commit -m "core: name the state colors for their roles and read every text color through st:Color"
```

**In-game checks (both clients):** these look as before:
- errors and refusals: status lines, a disabled row's why, the edit mode bar's refusal;
- loot roll timers and expiring totems;
- level tags, the micro menu's stats, the durability tooltip;
- item levels in bags and on the character frame;
- "Caught by:", and the rule editor's OR.

The chat Error prefix is the soft red. Change Danger and see errors move while Pass, Damage and Horde stay. A customized Text > Red is now Danger.

---

### Task 5: Opacity

**Files:**
- Modify:
  - `SaftUI-Core/Config/defaults.lua`: `button.normal = CreateColor(0.1, 0.1, 0.1, 1)`, `hover = CreateColor(0.3, 0.5, 0.7, 1)`, `pushed = CreateColor(0.3, 0.4, 0.5, 1)`, `danger = CreateColor(0.6, 0.1, 0.1, 1)`.
  - `SaftUI-Core/Media/colors.lua`: step 5, and the Buttons note gains "Opacity sets how strongly each is drawn: 100% is SaftUI's own." (the builder may word it).
  - The readers, each at its strength:

    | Color | Reader | Call |
    | --- | --- | --- |
    | Normal | `SaftUI-Core/Widgets/button.lua:253` | `st:ColorRGBA('button', 'normal')` |
    | Normal, Hover | `Widgets/checkbutton.lua:81-84,109,115` | `'normal'`, `'hover'`, 1 |
    | Normal, Hover, Pushed | `Widgets/scrollbar.lua:9-10` | each 1 |
    | Pushed | `Widgets/button.lua:263` | 1 |
    | Hover | `SaftUI-Core/skinning.lua:443,446`, `Config/optionsresize.lua:163-167` | 1 |
    | Normal, Pushed, Hover | `SaftUI-Minimap/micromenuitems.lua:33-43,97` | 1 |
    | Hover | `expansionbutton.lua:51`, `queuebutton.lua:44` | 1 |
    | Hover | `microbuttons.lua:181` | `HOVER_ALPHA` (0.4) |
    | Pushed | `microbuttons.lua:123` | `PUSHED_ALPHA` (0.6) |
    | Danger | `SaftUI-Bags/containers/bank.lua:56` | 1 on the vertex; the region's 0.3 kept |
    | Danger | `SaftUI-ActionBars/skin.lua:445`, `SaftUI-Misc/totemskin.lua:304` | 0.4 |

- Create: `tests/core/button_opacity_test.lua`.
- Test (modify):
  - `color_migration_test.lua`, `color_reads_test.lua` (rule D's `button`, rule F, rule B's button bindings), `colors_test.lua` (the Buttons note; the alpha `set` case at :111-112 on `hover`).
  - `tests/minimap/theme_test.lua`, `tests/actionbars/theme_test.lua`, `tests/bags/theme_test.lua` and `tests/misc/theme_test.lua`, wherever they pin these alphas, and each gains its case below.
- Docs:
  - `.agents/architecture.md`: the accessor paragraph names Buttons too, and its strength rule.
  - `.agents/edit-mode.md:183`: Buttons' opacity is drawn.
  - `docs/design-system/`:
    - `tokens.json`: `button-normal`, `button-hover`, `button-pushed`, `button-danger` at alpha 1, each usage saying "drawn at the reader's strength times its opacity".
    - `README.md` and the Button, Toggle and ColorBar pages where they give those alphas.
    - `05-decisions.md` 48: "Built (color roles, Tasks 1–5)".
    - `30-code-changes.md` 9: Normal and Hover keep their names (the color roles design's non-goal), and their opacity is drawn.
    - A line at the top of `25-colour-roles.md`: "Built by `docs/superpowers/specs/2026-11-14-saftui-color-roles-design.md` (2026-11-14); this page is the audit it started from."

**Interfaces:**
- Consumes: Tasks 1–4; `st:ColorRGBA(group, key, strength)`.
- Produces: every Buttons read is `st:ColorRGBA('button', key, strength)` (rules D and F).

- [ ] **Step 1: Write the failing tests**

```lua
-- color_migration_test.lua
test('step 5: every saved Buttons opacity goes back to 100%, in place, never nil', function()
	fresh(on({ colors = { button = { normal = { a = 0.3 }, hover = { r = 0.6, a = 0.1 }, pushed = { a = 0.5 }, red = { a = 0.5 } } } }))
	local b = st.config.profile.colors.button
	for _, k in ipairs({ 'normal', 'hover', 'pushed', 'danger' }) do eq(b[k].a, 1, k); check(b[k].GetRGB, k) end
	eq(b.hover.r, 0.6, 'its color kept')
	local raw = { colors = { version = 4, button = { hover = { a = 0.2 } } } }; st:MigrateColors(raw)
	eq(raw.colors.button.hover.a, 1); eq(raw.colors.button.normal, nil, 'no table made')
end)

-- button_opacity_test.lua (Core's widgets and the resize handles)
test('at 100% every reader draws the alpha it drew before', function()
	-- a SkinButton's highlight and pushed, a check box's highlight and checked fill, a scroll thumb at rest, hovered
	-- and pushed, a resize handle: each texture's alpha (select(4, tex:GetVertexColor())) == its strength (1)
end)
test('at 50% each draws half its strength', ...)
-- tests/minimap/theme_test.lua: a micro button's highlight 0.4 at 100%, 0.2 at 50%; pushed 0.6 and 0.3; micromenu items 1 and 0.5
-- tests/actionbars/theme_test.lua: the flash 0.4 and 0.2
-- tests/bags/theme_test.lua: an unbought slot's vertex 1 and 0.5, its region 0.3 either way
-- tests/misc/theme_test.lua: the totem button's flash 0.4 and 0.2
```

`colors_test.lua`: `eq(Section('button').desc, NOTE .. ' Opacity sets how strongly each is drawn: 100% is SaftUI\'s own.')`, or the builder's wording, pinned. `color_reads_test.lua`: rules D (button) and F, rule B's button bindings.

- [ ] **Step 2: Run them to see them fail.** Run `tests/run tests/core/color_migration_test.lua tests/core/button_opacity_test.lua tests/core/colors_test.lua tests/core/color_reads_test.lua`. Expected: FAIL, the alphas are 0.6, 0.8 and the rule F list is not empty.
- [ ] **Step 3: Implement** the defaults, step 5, the note and the readers.
- [ ] **Step 4: Run** the same files and every test file under Files, then `tests/run -j2`. Expected: PASS. Each changed assertion is listed in the report.
- [ ] **Step 5: Docs** as listed under Files.
- [ ] **Step 6: Commit.** Stage every path under Files explicitly.

```bash
git commit -m "core: draw the Buttons colors at their opacity, reset once to 100%"
```

**In-game checks (both clients):** at the defaults (100%), buttons, check boxes, scroll bars, micro buttons, the bank's unbought slots and the action and totem flash look as before. Lower Hover to 50%, reload, and check boxes and micro button highlights fade. Its reset puts 100% back.

---

## Spec coverage check

| Spec section | Task |
| --- | --- |
| What the owner decided 1 (names) | 3, 4 |
| 2 (Blue to the accent) | 2 |
| 3 (groups of their own) | 1 |
| 4 (no Own or Edited) | 2 (own), 3 (diff, marker) |
| 5 (equipped border) | 2 |
| 6 (opacity) | 5 |
| 7 (Strong apart) | 4 |
| Earlier decisions 7, 10, 20, 21, 23, 29 | 2; Global Constraints; 2 (rule editor under Blizzard keeps SaftUI's); 2 (`st.TINT_ROW`, `st.TINT_OBJECT`) |
| Goals and anti-goals | 1–5; Review Focus; the scan |
| The Colors page and the Theme tab (order, notes, Accent's place) | 1, 2, 4, 5; Ruling 3 |
| What each role colors (every table) | 1 (Roles, Factions, Loot), 2 (accent), 3 (Muted), 4 (Text, Buttons > Danger) |
| What a player sees change | 2 (own, equipped, prefix), 3 (diff, marker), 4 (Error) |
| Keys, and the migration (where, version, old defaults, source, destination, retiring, steps) | The migration, exactly; 1–5 |
| What happens to a player's colors | 1, 2 (Buttons > Blue only), 2/3 (drops), 5 (opacity), 1 (other profiles) |
| How code reaches a role (the accessor, the wrappers, the aliases, the tip field) | 1, 2, 3, 4; Rulings 5, 12, 17 |
| Change notifications | 1 (`'factions'`), 2 (`'accent'`, the handlers, Ruling 13) |
| Opacity (the rule, the table, own and diff strengths, tints) | 5; 2 (`OB.OWN_STRENGTH`, tints); 3 (`OB.DIFF_STRENGTH`) |
| Blue that isn't theme coloring | 1 (Tank, Alliance); 2 (Questions 1–3); Question 4 left |
| The hardcoded colors | 2 (prefix, own), 3 (diff), 4 (Error, DEBUG, share, timers, tracker, close fill); the rest stay |
| Phases 1–5 | Tasks 1–5 |
| Phase 6 | folded into 1–5 (Ruling 1) |
| Testing (accessor, migration, scan, pages, readers, opacity, test moves) | each task's Step 1 |
| In-game checks | each task |
| What's left to the builder (followups) | 1 (roles), 2 (7), 4 (14) |
| Calls 1–22 | 2 (1, 3), 1 (2, 5, 12, 15, 19, 20, 22), 4 (4, 8, 10, 18, 21), 5 (6), 3 (7, 9), 1–4 (11, 13, 14), 2 (16), 2/3 (17) |
| Settled 1–7 | 2 (Questions 1–3), Question 4 left, all |

**Where the spec is silent or the code disagrees** (each is a Ruling above):
- **The code disagrees.**
  - Ruling 4: `UpdateConfig` fires `'theme'` from two places, one deferred in combat.
  - Ruling 11: oUF reads no `colors.roles`.
  - Ruling 13: movers recolor only on `'theme'` today, while the spec's in-game check expects one to follow the accent.
  - Ruling 15: `st:Print` can run before `defaults.lua` loads.
  - Ruling 18: the lexer is a local of each scan test.
- **The user's brief overrides the spec.** Ruling 1: Phase 6 is folded into each task, so each task leaves no doc stale.
- **Sequencing the spec leaves open.** Ruling 2 (Buttons readers move once, in Task 5) and Ruling 3 (order 5.5, out of the fonts plan's way).
- **The spec leaves open:** Rulings 5–10, 12, 14, 16, 17 and 19–22.
