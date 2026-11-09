# SaftUI test suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A permanent `tests/` folder at the repo root, with:
- one command that runs every Lua test on real Lua 5.1;
- shared, strict WoW API stubs;
- the six throwaway harnesses migrated into it;
- docs telling agents how and when to use it.

**Architecture:**
- **Runner:** a shell entry point (`tests/run`) prepares a git-ignored Python venv with `lupa`, then runs `tests/runner.py`.
- **Per file:** the runner gives each `*_test.lua` file a fresh `lupa.lua51` state. It loads a Lua harness (test API, loader, core shell and WoW stubs), runs the file's registered cases, and reports.
- **Tests** load SaftUI's real files from the repo by path.

**Tech Stack:** Python 3.12, `lupa==2.8` (`lupa.lua51`), Lua 5.1, bash.

**Spec:** `docs/superpowers/specs/2026-11-09-saftui-test-suite-design.md`. Read it all, including both sets of builder's calls.

## Global Constraints

- **Location:** everything lives under the repo-root `tests/`. Nothing goes in any `SaftUI-*` folder, TOC or XML.
- **Lua 5.1 only:** use `lupa.lua51`. The runner never falls back to another Lua version.
- **Setup:**
  - `tests/run` creates and reuses `tests/.venv`, git-ignored, with `lupa==2.8`.
  - `SAFTUI_TEST_PYTHON=/path/to/python` makes it use that Python instead, which must already import `lupa`.
  - If setup fails, it stops with a message naming the command to run by hand.
- **Exit status:** `tests/run` exits 0 only if every discovered file loaded, ran at least one check, and had no failures. Otherwise it exits non-zero.
- **Strict stubs:** a WoW stub object answers only the methods it defines; an unknown method is nil, so calling it errors.
- **Faithful stubs:** a widget method called with the wrong widget type as `self` errors like WoW's ("Wrong object type"), e.g. a FontString's `SetText` called on a Button.
- **Real SaftUI files:**
  - Tests load real SaftUI files by repo-root path. They load the real Core helpers the code under test calls, where practical: `SaftUI-Core/api.lua`, `SaftUI-Core/utilities.lua` (`st.tablecopy`, `st.normalizeRGB`, the `issecretvalue` shim), `SaftUI-Core/constants.lua` and `SaftUI-Core/Widgets/button.lua`.
  - Module plumbing comes from one shared core shell:
    - `SaftUI`, `NewModule` / `GetModule`, `BindModuleConfig`, `Print`;
    - `st.config.profile`, built from the real defaults files a test loads;
    - `st.Config:Refresh`.
  - It never fakes behavior a test checks.
- **When a migrated check goes red,** follow the spec's rule:
  - fix the setup, not the assertion, when the stricter stubs are the cause;
  - update a check whose behavior was changed on purpose, citing the commit;
  - otherwise stop and report it as a possible SaftUI bug;
  - never loosen an assertion.
- **The harness archive:**
  - The old harnesses are in the git-ignored `.superpowers/harness-archive/` (emsim, rxpsim, bagsim, xpsim, ufsim2, ufprofsim).
  - Migrated tests keep every assertion. Expected counts are at least: grid 134, snap 38, RestedXP 353 across its files, plus the bag, XP, unit frame and profile checks.
- **Commits:** on the branch you're given. Messages end with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Lua test API (shared by every task)

Defined by `tests/lib/harness.lua`, which the runner loads before each test file:

- `test(name, fn)`: registers a case. Cases run in order after the file loads. An error inside `fn` fails that case with the message and a traceback, and the next case still runs.
- `check(cond, message)`: records a pass, or a failure with the message. It doesn't stop the case.
- `eq(actual, expected, message)`: like `check(actual == expected, …)`, but a failure says `expected <e>, got <a>`.
- `load_saftui(path, ...)`: runs the repo file at `path` (from the repo root). WoW's `...` is the addon folder name (the path's first component) and that addon's namespace table, shared within the Lua state. It returns whatever the file returns.
- `load_test_file(path)`: runs a helper or fixture file under `tests/`, by path relative to `tests/`.
- `REPO_ROOT` and `TESTS_DIR`: absolute paths.

## Review Focus

1. **A test file that errors while loading** (syntax error, missing stub) must count as a failure and fail the run, not be skipped. Pinned in Task 1, step 5.
2. **A file that registers no cases or runs no checks** must fail. Otherwise a broken `test()` call passes silently. Pinned in Task 1, step 5.
3. **A stub kinder than the real API** passes tests the game fails. Pinned by Task 1's wrong-self test and the strict-method test.
4. **Running from another directory** (`cd SaftUI-Core && ../tests/run`) must find the repo and the tests. Pinned in Task 1, step 5.
5. **The suite must really run Lua 5.1.** Pinned by Task 1's `_VERSION` test.

---

### Task 1: Runner, harness, core shell, strict stubs, edit mode tests and docs

**Files:**
- Create:
  - `tests/run`: bash, executable.
  - `tests/runner.py`.
  - `tests/lib/harness.lua`: the test API and loader.
  - `tests/lib/shell.lua`: the core shell. Its loaded order is `constants.lua`, then `utilities.lua`, then `api.lua`, as Core's TOC does.
  - `tests/wow/*.lua`: the WoW API stubs. Split them however you like, e.g. `frames.lua`, `globals.lua`, `color.lua`.
  - `tests/lib/harness_self_test.lua`: the harness's own checks, discovered like any other test file.
  - `tests/core/editmode_grid_test.lua` and `tests/core/editmode_snap_test.lua`.
  - `.agents/testing.md`.
- Modify:
  - `.gitignore`: add `tests/.venv/`.
  - `AGENTS.md`:
    - "What this is": replace "there is no build step and no test runner" with a line on `tests/`;
    - add a "When you need it" row: "Writing or running tests" → `.agents/testing.md`;
    - "Before claiming work complete": add "run `tests/run`; it must pass".
  - `README.md` Development: replace "There's no test runner…" with a line on `tests/run`. It's for agents and development; in-game checks are still how changes are verified.
  - `.agents/workflow.md`, "Working with subagents in this repo": workers write tests in `tests/` and run `tests/run`, not a scratchpad harness.

**Interfaces:**
- Produces:
  - the Lua test API above;
  - `tests/run [path ...]`. With no paths it discovers every `tests/**/*_test.lua`; with paths it runs those files, or the `*_test.lua` files inside those folders. Paths are relative to the current directory or absolute.
  - the core shell's `st:NewModule(name)`. It returns a module table with `RegisterEvent`, `UnregisterEvent`, `SecureHook`, `HookScript`, `IsEnabled` and an `Enable` that runs `OnInitialize` / `OnEnable`.
  - `st:GetModule(name, silent)`, plus a module's own `NewModule` / `GetModule` for submodules.
  - `reset_world()`: rebuilds the stubs and the shell in the same Lua state, for files that rebuild between cases (as rxpsim's `Fresh()` does).

- [ ] **Step 1: Self-tests first.** `tests/lib/harness_self_test.lua` checks:
  - `eq(_VERSION, 'Lua 5.1')`.
  - Strict stubs: a frame from `CreateFrame('Frame')` has no `NotAMethod`, and calling it errors.
  - Wrong self: `local b = CreateFrame('Button'); local fs = b:CreateFontString(); local ok = pcall(fs.SetText, b, 'x')` gives `ok == false`.
  - `load_saftui('SaftUI-Core/Widgets/button.lua')` with the shell loaded: `st:CreateButton(nil, UIParent, 'x'):SetText('y')` errors. This is the real helper's alias bug, the same one as the footer bug on 2026-11-09.
  - `load_saftui` passes `...` as `('SaftUI-Core', ns)`, with the same `ns` table for two files from one addon.
- [ ] **Step 2: Run** `tests/run tests/lib`. Expected: it fails, because the runner doesn't exist yet. Then build `tests/run` and `tests/runner.py` until it runs and reports the self-test failures.
- [ ] **Step 3: Build the harness,** the stubs and the shell until the self-tests pass. Grow the stubs from `.superpowers/harness-archive/emsim/stubs.lua` and `rxpsim/mocks.lua`, made strict.
- [ ] **Step 4: Migrate emsim.**
  - `test_grid.lua` becomes `tests/core/editmode_grid_test.lua`, and `test_snap.lua` becomes `tests/core/editmode_snap_test.lua`.
  - They load the real `SaftUI-Core/EditMode/*.lua` and `api.lua` through `load_saftui`.
  - Every assertion is kept: 134 grid checks and 38 snap checks, or more.
  - The footer-label check must use the real `st:CreateButton`. It passes today because `settings.lua` calls `sizeLabel.text:SetText`.
- [ ] **Step 5: Check the runner's failure modes.** Do this by hand in a scratch directory outside the repo, without committing the fixtures, and record the outputs in the report:
  - a `*_test.lua` with a syntax error makes `tests/run <that file>` exit non-zero and name the file;
  - a file with no `test()` cases exits non-zero ("no checks ran");
  - a file whose case calls `check(false, 'x')` exits non-zero and shows `x`;
  - `cd SaftUI-Core && ../tests/run ../tests/core` passes.
- [ ] **Step 6: Run** `tests/run`. Expected: every file passes. Also check that `git status` shows nothing under `tests/.venv`.
- [ ] **Step 7: Docs.** Write `.agents/testing.md` with frontmatter `name: testing`, a description, `last_updated: 2026-11-09` and `covers: ['tests/**']`. Cover:
  - how to run the suite;
  - the test API;
  - the stub rules (strict, faithful, real SaftUI helpers);
  - when tests are required (the spec's "When tests are written");
  - what to do when a check goes red.

  Make the `AGENTS.md`, `README.md` and `.agents/workflow.md` edits listed above.
- [ ] **Step 8: Commit.** Message: `tests: permanent Lua 5.1 test suite with runner, strict WoW stubs and edit mode tests`.

### Task 2: Migrate the RestedXP tests

**Files:**
- Create:
  - `tests/misc/restedxp_*_test.lua`, one per old file: `task1`, `task2`, `task3`, `fixes`, `timers`, `title`.
  - `tests/misc/fixtures/restedxp_world.lua` (from `rxp_mock.lua`) and `tests/misc/fixtures/libcandybar.lua` (from `timers_mock.lua`). Fixtures stand in for third-party addons, not WoW, so they live beside the tests.
- Modify: the shared WoW stubs, merging what `rxpsim/mocks.lua` adds and keeping them strict.

**Interfaces:**
- Consumes: Task 1's test API, `reset_world()`, `load_test_file()`, `load_saftui('SaftUI-Misc/Skinning/restedxp.lua')`, and the core shell's modules.
- Produces: none.

- [ ] **Step 1: Port each file.** `Fresh()` becomes `reset_world()`, then the fixture loads, then `load_saftui` of the skin. Count-based prints become `test()` cases with `check` / `eq`. The skin path is the main tree's `SaftUI-Misc/Skinning/restedxp.lua`.
- [ ] **Step 2: Run** `tests/run tests/misc`. Expected: all pass, with at least 353 checks across the six files. A red check follows the Global Constraints rule.
- [ ] **Step 3: Run** `tests/run`. Expected: everything passes.
- [ ] **Step 4: Commit.** Message: `tests: RestedXP skin tests moved into the suite`.

### Task 3: Migrate the bag, XP bar and unit frame tests

**Files:**
- Create:
  - `tests/bags/container_hold_test.lua` and `tests/bags/container_pack_test.lua` (from bagsim), loading `SaftUI-Bags/container.lua`;
  - `tests/misc/experience_test.lua` (from xpsim), loading `SaftUI-Misc/experience.lua` and the real `SaftUI-Core/Config/defaults.lua` for the colors and the experience defaults;
  - `tests/unitframes/power_text_test.lua` (from ufsim2), loading `SaftUI-Unitframes/updaters.lua` and `elements/additionalpower.lua`;
  - `tests/unitframes/profiles_test.lua` (from ufprofsim), loading `SaftUI-Unitframes/config/config.lua`, and `SaftUI-Core/Config/config.lua`'s `Config:Import` / `Export` if practical.
- Modify: the shared stubs and the shell, as needed.

**Interfaces:**
- Consumes: Task 1's test API and core shell.
- Produces: none.

- [ ] **Step 1: Port each harness.** The inline `SaftUI = {...}` fakes and permissive frame metatables are replaced by the shared shell and strict stubs, as the spec's builder's calls say. Keep every assertion.
- [ ] **Step 2: Run** `tests/run tests/bags tests/misc/experience_test.lua tests/unitframes`. Expected: all pass. A red check follows the Global Constraints rule.
- [ ] **Step 3: Run** `tests/run`. Expected: everything passes.
- [ ] **Step 4: Commit.** Message: `tests: bag, XP bar and unit frame tests moved into the suite`.
