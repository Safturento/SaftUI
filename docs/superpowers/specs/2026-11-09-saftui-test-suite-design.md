# SaftUI test suite: permanent, runnable Lua tests

Date: 2026-11-09. Status: draft for the user's review.

## Intent

SaftUI has no test runner, and changes are checked in game by the user. During development, agents have still been writing logic tests: Lua harnesses that load SaftUI's real files over hand-written WoW API stubs and check things that can be computed outside the game. Examples are pixel math, grid lines, snapping, bag packing, and settings mappings.

Those harnesses live in the agent session's scratch folder under `/tmp`, so they vanish with the session. Every "passes in the harness" claim is lost, and nothing protects already-tested logic from a later change.

The user wants them committed and permanent, "so we can always have them runnable".

## What the user decided

- **Who they're for:** "mostly for you": agents (implementers and reviewers) run them while developing. The user isn't expected to run them, and in-game checks stay the final word.
- **Where they live:** a root `tests/` folder, outside every `SaftUI-*` addon folder: "just a root test folder that is only used for development when agents are running". Nothing in it is ever linked into the game's AddOns folder or loaded by the game.
- **Accepted as played back in chat:**
  - one command;
  - real Lua 5.1;
  - shared, faithful WoW stubs, with the real SaftUI helpers loaded instead of fakes;
  - tests grouped by addon;
  - the existing harnesses migrated;
  - docs in `.agents/`, `AGENTS.md` and the README.

## Goals

- **One command from the repo root** runs every test, or only the file or folder given. It prints a pass/fail summary and exits non-zero on any failure.
- **Tests run on real Lua 5.1,** the language version WoW uses.
- **Setup is automatic and local:** the first run prepares what it needs inside `tests/`, git-ignored. Nothing is installed system-wide, and no sudo is needed.
- **Each test file runs in a fresh Lua state,** so files can't leak state into each other.
- **Shared WoW API stubs** live in one place and are reused by every test.
- **The six existing harnesses** move in and pass.
- **Agents know when and how to write tests,** and run the suite before claiming work complete.

## Non-goals

- CI (GitHub Actions or similar). It can come later.
- Coverage reports or a test framework dependency (busted, luarocks).
- A complete WoW API emulator. Stubs cover what the tests use.
- Testing Blizzard's code, or anything only the game can show: look, layout on screen, taint.
- Tests the user has to run.

## Anti-goals (what would make this a failure even if it technically works)

- **Anything from `tests/` reaching the game:** linked into AddOns, listed in a TOC, or loaded by an addon.
- **Stubs kinder than the real code,** giving false confidence. The footer bug on 2026-11-09 is the example: a `st:CreateButton` stub had a working `SetText` the real helper lacks, so tests passed while the game would have errored.
- **A setup so slow, fragile or manual that agents skip it.**
- **Tests that pass on Lua 5.5 but would fail on WoW's 5.1,** or the reverse.

## Constraints

- **Environment:** WSL (Linux), Python 3.12 with pip, no `lua` binary installed, no sudo assumed.
- **Interpreter:** Python's `lupa` package ships genuine Lua 5.1 (`lupa.lua51`), checked on this machine with lupa 2.8. It's the interpreter the existing harnesses used, in 5.5 mode.
- **Line endings:** the repo stores text as LF (`.gitattributes`). Some working-copy files are CRLF. Tests must load SaftUI files either way.
- **The existing harnesses are temporary.** They were written in an agent session's scratch folder under `/tmp`. Copies are kept in the git-ignored `.superpowers/harness-archive/` in the repo, which survives a reboot. Build from those. The archive can be deleted once the migration lands. Each harness hard-codes paths to SaftUI files (including one old worktree path in `rxpsim/run.py`), which the runner replaces:
  - `emsim/`: edit mode grid and snapping (`stubs.lua`, `test_grid.lua`, `test_snap.lua`, `run.py`);
  - `rxpsim/`: the RestedXP skin (`mocks.lua`, `rxp_mock.lua`, `timers_mock.lua`, and `test_*.lua` for task1/2/3, fixes, timers and title; its `run.py` takes the skin path from `RXP_SKIN`);
  - `bagsim/`: bag layout hold and packing (`run.py <container.lua> <test>`);
  - `xpsim/`: XP bar layering and color options;
  - `ufsim2/`: unit frame smoothing and power percent text;
  - `ufprofsim/`: unit frame profile Rename, Import and Export popups.

  Ignore the `*.orig` and `*.log` files and `xpsim/old_experience.lua`.
- **Repo conventions apply** (`AGENTS.md`, `.agents/`), including:
  - the `covers:` frontmatter on topic docs;
  - the completion checks;
  - commit attribution.

## Design (my calls, marked so the user can reject any)

- **Layout:**
  - `tests/run`: the one command, a small shell script.
  - A runner in Python that uses `lupa.lua51`.
  - Shared Lua helpers (a minimal `test`/assert API, and a loader that runs a SaftUI file the way WoW does, with the addon name and namespace as `...`).
  - WoW stubs in their own folder.
  - Test files in one folder per addon (`tests/core/`, `tests/bags/`, `tests/misc/`, `tests/unitframes/`, …), named `*_test.lua`.
- **Setup:** on first run, the runner creates a git-ignored virtual environment in `tests/` and installs a pinned `lupa` (2.8). Later runs reuse it. If the install fails (no network), the error says what to run by hand.
- **The stub rule:** where SaftUI has its own helper (`st:CreateButton`, `st:SetBackdrop`, `st:RoundToPixel`, the edit mode framework…), tests load the real SaftUI file. WoW API stubs mimic the real API's behavior, including how it fails. A stub that's kinder than the real thing is a bug in the stub. Where a behavior can't be mimicked, the test says so in a comment.
- **Migration:**
  - Each harness's checks become test files, with their WoW stubs merged into the shared ones.
  - Tests keep their assertions. Where a check only made sense against the old harness's quirks, it's rewritten or dropped, and the rewrite or drop is noted in the commit.
  - Moving from Lua 5.5 to 5.1 may surface real differences. A real SaftUI bug found that way is reported to the controller, not hidden by the test.
- **When tests are written:**
  - **Required:** any change to logic that can be checked outside the game (math, layout and ordering, state, settings get/set mappings, pure helpers) comes with tests in `tests/`.
  - **Bug fixes:** a fix in tested logic starts with a failing test.
  - **Not required:** visuals and Blizzard frame interaction stay in-game checks. Tests never replace the user's in-game check list.
- **Docs:**
  - **`.agents/testing.md`** (with `covers: 'tests/**'`): how to run the suite, how to write a test, the stub rule, when tests are required.
  - **`AGENTS.md`:**
    - a row in "When you need it" for tests;
    - in "Before claiming work complete", run `tests/run` and have it pass;
    - fix its "What this is" claim that there's no test runner.
  - **README Development:** a line on `tests/run`. Its "There's no test runner" bullet changes.
  - **`.agents/workflow.md`:** its subagent section points workers at `tests/` instead of a scratchpad harness.

## Builder's calls after the builder check

These answer the builder check's questions. They're marked so the user can reject any of them.

- **How faithful the migration is:**
  - **The real files.** Tests load the real SaftUI files that hold the logic they check, plus the real Core helper files that logic calls, where that's practical (e.g. `SaftUI-Core/api.lua`'s pixel and anchor helpers, `SaftUI-Core/Widgets/button.lua`).
  - **Not all of Core.** Loading all of SaftUI-Core (Ace3, the AceDB profile, media, the `/sui` window) isn't required.
  - **A shared "core shell" stub.** One shared stub stands in for the module plumbing: `SaftUI` itself, `NewModule`/`GetModule`, `BindModuleConfig`, `Print`, `st.config.profile`, `st.Config:Refresh`. It's fine as long as it never fakes behavior a test checks.
  - **No inline fakes.** The tests that build their own inline `SaftUI = {...}` (xpsim, ufsim2, ufprofsim) move onto the shared shell.
- **The frame stubs are strict.** Shared WoW frames, textures and font strings implement methods explicitly. Calling a method the stub doesn't define is an error naming the method, so a test can't pass by silently swallowing a call. The permissive "any capitalized name is a no-op" fakes in the old harnesses go away. Methods are added to the stubs as tests need them, and they mimic the real API, including WoW's wrong-`self` error for a font string method called on a button.
- **Loading a file:**
  - **Paths are pinned.** Each test names the real repo file it loads, by path from the repo root. The old harnesses' path variables (`UPD`, `PATH`, `EMDIR`, `SKIN_PATH`, `arg_path`) go away.
  - **Bags:** `bagsim` ran the same tests against `SaftUI-Bags/container.lua` before and after a change; the migrated bag tests pin today's `container.lua`.
  - **Arguments:** the loader passes `...` as the addon folder name and a per-addon namespace table, the way WoW does. The shared shell provides the global `SaftUI`.
- **RestedXP tests run against the main tree's `SaftUI-Misc/Skinning/restedxp.lua`.** Its old worktree path is gone.
- **Isolation:** each test file gets a fresh Lua state. The test API also offers a way to rebuild a file's stubbed world between cases, like rxpsim's `Fresh()`, for the files that need it. Per-case isolation isn't required otherwise.
- **The runner's Python:** by default it makes and reuses a git-ignored virtual environment in `tests/` with `lupa==2.8`. An environment variable can point it at another Python that already has lupa. If setup fails (no network, no wheel), it stops with a message saying what to run by hand. It never falls back silently to a different Lua version.
- **When a migrated test goes red.** The committed suite must pass.
  - A test that fails only because the new stubs are stricter or more faithful gets its setup fixed, not its assertion.
  - A test asserting behavior that was later changed on purpose, as recorded in git history or docs, is updated to the current behavior.
  - Anything else is a possible real SaftUI bug. The builder stops on that harness and reports it with the failing output, and the controller decides. Assertions are never loosened to make a run pass.
  - If SaftUI uses syntax WoW's Lua 5.1 lacks, that's a real bug: report it.

## Left to the builder

- The runner's internals: discovery, output format, the Lua-side test API names.
- How the shared stubs are split into files.
- Exact folder names per addon.
- Whether the shell script or the Python runner owns the virtual environment setup.
