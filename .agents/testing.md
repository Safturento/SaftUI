---
name: testing
description: SaftUI's Lua test suite in tests/ - running it, writing tests, the WoW stub rules, and when tests are required
last_updated: 2026-11-09
covers:
  - 'tests/**'
---

# Testing

`tests/` holds SaftUI's Lua tests. They check logic that can be computed outside the game (math, layout and ordering, state, settings get/set mappings, pure helpers) by loading SaftUI's real files on WoW's Lua 5.1, over stubbed WoW API. They're for agents and development. Nothing in `tests/` is linked into AddOns, listed in a TOC or loaded by the game, and the user's in-game check stays the final word.

## Running the suite

- `tests/run` from the repo root runs every `tests/**/*_test.lua`. `tests/run PATH...` runs those files, or the `*_test.lua` files in those folders. Paths are relative to where you are, so `cd SaftUI-Core && ../tests/run ../tests/core` works. `-v` lists every case and shows what the tests printed.
- It exits 0 only if every file loaded, ran at least one check and had no failures. A file that errors while loading, registers no `test()` cases, or has a case that runs no checks fails the run.
- Each file runs in its own fresh Lua state, so files can't leak into each other.
- The first run makes `tests/.venv` (git-ignored) with lupa 2.8, Python's binding to genuine Lua 5.1. If that fails (no network), the message names the commands to run by hand, or set `SAFTUI_TEST_PYTHON` to a Python that already has lupa (made in a virtual environment, not the system Python). It never falls back to another Lua version.
- A git worktree with no `tests/.venv` of its own uses the main checkout's (`<git common dir>/../tests/.venv`) when that exists, and makes its own only if neither does.
- A file's loading, and each of its cases, may run 4 billion Lua instructions (the biggest unit today runs about 300 million, a few seconds), then the harness stops it with an error naming the file and case, so an endless loop fails instead of hanging the run.
- `tests/run --self-check` checks the runner itself: it runs each file in `tests/lib/runner_fixtures/` (no `_test` suffix, so discovery skips them) and asserts the passing one exits 0 and every broken one (a syntax error, no cases, a case with no checks, a failing check, an error in a case, an endless loop) exits non-zero. Run it after touching `runner.py`, `harness.lua`'s `run_file` or `tests/run`; a new failure mode gets a fixture and a line in `FIXTURE_EXPECTED` in `runner.py`.

| Path | What it is |
| ---- | ---------- |
| `tests/run`, `tests/runner.py` | The command, and the Python runner it starts: discovery, one Lua state per file, the report and exit status. |
| `tests/lib/harness.lua` | The test API and the loader. |
| `tests/lib/shell.lua` | The core shell (below). |
| `tests/lib/harness_self_test.lua` | The harness's own checks: Lua 5.1, strict and faithful stubs, the loader, the shell. If these fail, trust nothing else. |
| `tests/lib/runner_fixtures/` | Deliberately broken (and one passing) files for `tests/run --self-check`. Not run as tests. |
| `tests/wow/` | WoW API stubs, shared by every test: `lua.lua` (WoW's Lua additions), `game.lua` (game state API and the `stub` controls), `widgets.lua` (frames, buttons, edit boxes, status bars, sliders, scroll frames, textures, font strings, fonts), `blizzard.lua` (Blizzard's Lua: mixins, colors, EventRegistry, backdrops, PixelUtil, the `Enum` tables, `GameFontNormal`). |
| `tests/<area>/` | Tests by addon (`core/`, `bags/`, `misc/`, `unitframes/`, …), named `*_test.lua`. Stand-ins for third-party addons go in `tests/<area>/fixtures/`. A file without the `_test` suffix (a helper the area's tests share) isn't run. |
| `tests/bags/` | The bag layout tests (`container_hold_test.lua`, `container_pack_test.lua`), with `container_helpers.lua` (the world with the real `container.lua`, `inventory.lua`, `movers.lua`, `category.lua` and the module's defaults, and the container and category frames the layout works on). |
| `tests/unitframes/` | `power_text_test.lua` (smoothing, power percent text, the additional power bar's text, secret values) and `profiles_test.lua` (the unit frame profile popups), with `fixtures/ace_libs.lua` (the Ace3 libraries `config/config.lua` takes from LibStub). |
| `tests/misc/` | `experience_test.lua` (the XP bar's frame levels and colors). The RestedXP skin's tests (`restedxp_*_test.lua`), with `restedxp_helpers.lua` (the world they build and the readers they share), `fixtures/restedxp_world.lua` (RestedXP's guide window), `fixtures/libcandybar.lua` (LibCandyBar and RestedXP's timers) and `fixtures/locked_widget.lua` (the lock both fixtures put on their frames, so a skin that writes a field onto, or `SetScript`s, another addon's frame fails). `restedxp_fixtures_test.lua` checks the fixtures' own behavior. |

## Writing a test

```lua
-- What this file checks, and the real files it loads.
load_core_helpers()
load_saftui('SaftUI-Core/EditMode/editmode.lua')
load_saftui('SaftUI-Core/EditMode/grid.lua')
local EM = SaftUI.EditModeFrames

test('GridLinePositions repeats out from the center', function()
	local p = EM.GridLinePositions(960, 0, 1920, 32)
	eq(#p, 61, 'line count')
	check(p[1] == 0 and p[#p] == 1920, 'first and last lines on the edges')
end)
```

The API (globals, defined in `tests/lib/harness.lua`):

| Call | Does |
| ---- | ---- |
| `test(name, fn)` | Registers a case. Cases run in order once the file has loaded. An error in `fn` fails the case with its traceback, and the next case still runs. |
| `check(cond, message)` | Records a pass, or a failure with `message` and its file:line. Doesn't stop the case. Returns `cond` as a boolean. Only inside a case. |
| `eq(actual, expected, message)` | `check(actual == expected)`, failing with `expected <e>, got <a>`. |
| `load_saftui(path)` | Runs a SaftUI file by its path from the repo root (`'SaftUI-Core/api.lua'`), as WoW does: `...` is the addon folder name and that addon's namespace table, one per addon. Returns what the file returns. |
| `load_test_file(path)` | Runs a helper or fixture by its path from `tests/`. |
| `addon_namespace(addon)` | The namespace table `load_saftui` gives that addon's files (e.g. `addon_namespace('SaftUI-Unitframes').oUF`). |
| `reset_world()` | Rebuilds the stubs and the shell in the same Lua state, for files that want a fresh world per case. Globals made since the harness loaded are removed, and a base global or `string` / `table` / `math` member a test replaced (`print`, `pairs`, `string.format`) gets its value back; the test file's locals survive. Load SaftUI files again after it. |
| `apply_defaults()` | Fills `st.config.profile` from `st.defaults` as AceDB's `copyDefaults` does (same conditions: a `false` under a table default is replaced by a table, a truthy non-table value stays): missing keys get deep copies, existing values stay, and the `['*']` / `['**']` wildcard keys work (never keys of the profile; a `'**'` table's defaults fill every sibling key, including keys made later by reading them, so `rawget` tells whether a key was made). Load the defaults files first. |
| `load_core_helpers()` | Loads Core's frame helpers for real: LibSharedMedia, `Widgets/button.lua`, `panels.lua`, the media and fonts, `Config/defaults.lua` (then `apply_defaults()`) and `Config/widgets.lua`, and enables the Fonts module. Use it before anything that calls `st:CreateFrame`, `st:SetBackdrop`, `st:CreateButton`, `st:GetFont` or `st.Config.generators`. |
| `take_errors()` | The errors reported to the game's error handler so far in this case, as a list, cleared. |
| `debugprofilestop()` | WoW's timer, in milliseconds (the process's CPU time), for a check on how long code takes. |
| `REPO_ROOT`, `TESTS_DIR` | Absolute paths. |

- Cases share the file's world and run in order. A case may build on the one before, or call `reset_world()` for a clean start.
- Keep test state in locals: `reset_world()` removes globals.
- The parts of Lua's library WoW lacks aren't there: `io`, `os`, `require`, `dofile`, `loadfile`, `package` and `module` are nil, for test files and SaftUI files alike. Load files with `load_saftui` or `load_test_file`, never end a run yourself (the runner owns the exit status), and add WoW's own `time` or `date` to `tests/wow/lua.lua` if SaftUI code needs them.
- `print` output is captured, and shown for a failing case (or with `-v`).
- The game shows an error passed to `geterrorhandler()` and carries on. So the stubbed handler records it, the code goes on as in game, and the case fails unless the test takes it with `take_errors()`. AceAddon-style `Enable`, event dispatch, scripts and `EventRegistry` callbacks all report errors this way.

## The test world

Every file starts with the WoW stubs and the core shell loaded.

- **The core shell** (`tests/lib/shell.lua`) stands in for `init.lua` and Ace3's plumbing, mimicking their behavior:
  - `SaftUI`, which is SaftUI-Core's namespace, as in game;
  - `NewModule` / `GetModule` / `IterateModules`, and on each module `Enable` (every `OnInitialize` in the module's subtree first, as AceAddon does at ADDON_LOADED, then `OnEnable`, then its modules', once each, errors to the error handler), `IsEnabled` (AceAddon's: true by default), `RegisterEvent` / `UnregisterEvent` (AceEvent's calling conventions; handlers run in registration order, but real CallbackHandler iterates with `pairs`, so **tests must not rely on handler order**), `SecureHook` and `HookScript` (AceHook's); `SetDefaultModuleLibraries` (AceAddon's, before any module exists);
  - `st.config.profile` (empty until `apply_defaults()`), `st:BindModuleConfig`, and `st.Config` with `Refresh` and `GetWindow` (no `/sui` window, so `nil`).

  It then loads Core's real `constants.lua`, `api.lua` and `utilities.lua` in TOC order, and sets UIParent's scale to `st.scale`, as `init.lua` does.
- **The `stub` table** puts the game in a state: `stub.interface` (16001, Forever), `stub.screen_width` / `screen_height` (UIParent follows them and its scale), `stub.in_combat`, `stub.cursor_x` / `cursor_y`, `stub.time`, `stub.shift_down` / `ctrl_down` / `alt_down`, and `stub.loaded_addons` (a set of names for `C_AddOns.IsAddOnLoaded`), and the player's experience: `stub.max_level`, `level`, `xp`, `xp_max` and `rested_xp` (nil for none). Its helpers:
  - `stub.state(widget)` reads what the API has no getter for (e.g. `.color_texture`);
  - `stub.fire_event(event, ...)` fires a game event to every registered frame, and so to shell modules;
  - `stub.fire_script(widget, script, ...)` runs a script handler and its hooks.
- **Layout.** Frames are laid out from their anchors and sizes, so `GetLeft`, `GetWidth`, `GetRect` and the rest work as in game. `UIParent` fills the screen.

## The stub rules

1. **Real SaftUI helpers.** Where SaftUI has its own helper (`st:CreateButton`, `st:SetBackdrop`, `st:RoundToPixel`, the edit mode framework, …), load its real file with `load_saftui`. Never fake a SaftUI function in a test or a stub. The shell stands in only for plumbing (Ace3, AceDB) and never fakes behavior a test checks. One narrow exception, for a file whose real code can't load here (it needs a library or Blizzard frames that aren't stubbed): a stand-in models only the contract the code under test consumes and says in a comment what the real code does beyond it. The stand-ins are:
   - `H.make_chat` in `tests/misc/restedxp_helpers.lua` (SaftUI-Chat: `ApplyAppearance` exists and is hookable, and `UpdateConfig` and the option setter end in it);
   - in `tests/bags/container_helpers.lua`, the scroll frame (`st:CreateScrollFrame` needs Blizzard's `ScrollFrameTemplate` and the scroll bar skin; the layout only calls its `SetContentSize`);
   - in `tests/unitframes/profiles_test.lua`, `UF:UpdateConfig` (needs oUF), `st.Config:Export` / `Import` (`Config/config.lua` needs AceDB and AceConfigDialog, and the shell already makes the Config module) and the popup frame with `GetEditBox`;
   - in `tests/unitframes/power_text_test.lua`, `UF:RegisterElement` (a copy of unitframes.lua's table store) and the secret value (see rule 4).

   `LibStub` itself is never faked; third-party library stand-ins are fixtures (see rule 6). Load the real `LibStub` and register a fixture per library (`tests/unitframes/fixtures/ace_libs.lua`) with only the methods the loaded files call, so an unknown library, or a method nothing gave it, errors.
2. **Strict.** A stub widget answers only the methods `tests/wow/` defines. Any other name is nil, so calling it errors with the method's name. Never add a catch-all `__index` that turns unknown names into no-ops. When a test needs a method, add it.
3. **Faithful.** A stub behaves like the real API, including how it fails:
   - a widget method called with the wrong type of self errors "Wrong object type" (a FontString's `SetText` on a Button);
   - `SetText` on a font string with no font errors "Font not set";
   - `SetFontObject(nil)`, an unknown template, point, strata or script name, and an anchor loop all error.

   A stub kinder than the real thing is a bug in the stub: it lets a test pass where the game errors. Check real behavior in Blizzard's source (Gethe/wow-ui-source, `forever` branch; widget methods in `Blizzard_APIDocumentationGenerated`), as `.agents/clients.md` describes.
4. **Say what can't be mimicked.** The stubs don't run the game's layout pass (so `OnSizeChanged` never fires by itself, and a font string is one line, never wrapped), `OnUpdate`, secret values or taint. They are also kinder than the game in three ways a test can't see: `RegisterEvent` takes any event name (the game errors "Attempt to register unknown event"), `SetFont` and `SetTexture` always succeed (a missing file fails in game), and the trimmed `Enum.PowerType` errors on a name nobody stubbed while the game has the value. A test that needs one drives it by hand (`stub.fire_script`, a method overridden on one frame), with a comment saying so. A secret value is a `newproxy` userdata that errors on indexing, calling, `#`, `..`, arithmetic and ordering (`tests/unitframes/power_text_test.lua`). Lua 5.1 can't catch `==` against a number (`__eq` only fires between two tables or two userdata), so `secret == 5` quietly gives false where the game errors: code must guard with `issecretvalue` before any `==`, and a green test doesn't prove it did. A test that passes one to a font string overrides `SetText` / `SetFormattedText` on that one font string, since the stub's take only strings and numbers. The mouse is a position (`stub.cursor_x` / `cursor_y`): `IsMouseOver` is the rectangle test, and `IsMouseMotionFocus` is true for the topmost visible mouse-enabled frame under it.
5. **Pinned paths.** Tests name the real files they load, by path from the repo root.
6. **Shared stubs, local fixtures.** WoW's API goes in `tests/wow/`, for every test. Stand-ins for other addons (RestedXP, LibCandyBar) are fixtures beside their tests.

## When tests are required

- **Required:** any change to logic that can be checked outside the game (math, layout and ordering, state, settings get/set mappings, pure helpers) comes with tests in `tests/`.
- **Bug fixes:** a fix in tested logic starts with a failing test.
- **Not required:** visuals and interaction with Blizzard's frames stay in-game checks. Tests never replace the user's in-game check list.
- Before claiming work complete, run `tests/run`. It must pass.

## When a check goes red

1. Read it. A failure gives the file:line and message, and an error gives its traceback. An error the game would have shown is listed as reported to the error handler.
2. **Your change caused it:** fix the code. If the behavior changed on purpose, update the check to the new behavior and say why in the commit.
3. **Stricter or more faithful stubs caused it** (a stub now fails like the game): fix the test's setup, not its assertion.
4. **Otherwise it may be a real SaftUI bug** (including syntax Lua 5.1 lacks): stop, and report it with the failing output.
5. Never loosen an assertion, delete a failing check, or make a stub kinder to get a green run.

The design is in `docs/superpowers/specs/2026-11-09-saftui-test-suite-design.md`, and the plan in `docs/superpowers/plans/2026-11-09-saftui-test-suite.md`.
