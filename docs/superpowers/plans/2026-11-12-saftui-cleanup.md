# SaftUI Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Act on every item in the cleanup report that has a clear fix: the bugs, the dead code, the `st.retail` flag, the repeated setup, the oversized files and the slow test run. Items that need the user's decision stay untouched.

**Architecture:**
- Five waves. Each wave is built on its own branch from `modular` and lands as one `--no-ff` merge, so a wave can be reverted alone.
- Wave 1 removes and fixes (per addon, in parallel). Wave 2 adds shared Core helpers and adopts them. Wave 3 splits the two big Config files. Wave 4 splits and renames per addon (in parallel). Wave 5 tidies the tests.
- No wave changes what the user sees, except the bug fixes Wave 1 names.

**Tech Stack:** Lua 5.1 for WoW Forever (16001) and retail (120000). No build step. Tests run on stubs with `tests/run` (Python `lupa.lua51`).

**Spec:** `docs/reports/2026-11-12-codebase-cleanup-analysis.md` (the report). Section numbers below are the report's. Line numbers in the report and in this plan are as of `modular` cb95022: find each item by name, not by line.

## Global Constraints

- **Libraries are off limits.** Nothing under `SaftUI-Core/Libraries/`, `SaftUI-Unitframes/Libraries/` or `SaftUI-ActionBars/Libraries/` is modified, moved or deleted.
- **Work only in the worktree path you were given.** Never `git stash`, never push, never switch branches, never dispatch subagents.
- **No behaviour change** beyond what the task names. A refactor task moves code; it doesn't rewrite it. Function names, saved variable keys, option keys and option labels stay as they are unless the task names the change.
- **Out of scope (leave exactly as it is, even if it looks dead):**
  - Bags bank types (`inventory.lua` `SelectBankCategory`), `combinedbank` and `HasWarbandBank`, the old Edit view (`CreateEditToggle`, the edit branches in `container.lua`, `category.lua`, `categories.lua`), the profile migrations in `categories.lua` and `movers.lua`.
  - `SaftUI-Core/taintfix.lua`, time played (`init.lua`), the keybinding widget in `optionswidgets.lua`, AceConfig contract leftovers, `st:ResolveLegacyTemplate` and its tests, `T.old_names`.
  - `SaftUI-Loot/popup.lua` and everything that only serves it; the honor feed.
  - Unitframes `arena`, Portrait, AuraWatch, and the aura `filter`, whitelist, blacklist and `spellIds` default tables.
  - `CHT:MigratePosition`.
  - `Blizzard_WeeklyRewards.lua`'s overlay write, `st:EnableResizing`, `st:Kill`, the totem bar's setup on classes with no totems.
  - TOC `OptionalDeps`, library lines in TOCs, media files, merging Core's TOCs.
  - `SaftUI-Bags/ruleeditor.lua` and `categoriestab.lua` moving onto Core's widgets.
- **Before deleting anything,** search the whole repo for it: every `SaftUI-*` folder, `tests/`, XML and TOC files, and names built at run time (`self[...]`, `_G[...]`, a string key in an option table, a method called through `xpcall` or a mixin). If anything live still uses it, leave it and say so in the report file.
- **Tests:**
  - Each bug fix gets a test that fails before the fix (see `.agents/testing.md`).
  - A test that only covers deleted code is deleted with it. A test seam (a field or function only tests read) is kept unless the task names it.
  - No other assertion changes, unless the task says which and why.
  - `tests/run` passes at the end of every task (it takes about two minutes; in a worktree it reuses the main checkout's `tests/.venv`).
- **Blizzard frames:** read `.agents/taint.md` before changing any code that touches one. Check a Blizzard name against the client source as `.agents/clients.md` says before relying on it.
- **Clients:** `st.retail` is true on both clients, so its `else` branches and every `not st.retail` guard never run. Only `st.forever` tells the clients apart.
- **Files:**
  - Keep each file's line endings (check with `file`). Never `sed -i` a CRLF file.
  - An addon with per-client TOCs gets every TOC edited.
  - A new Lua file goes into the TOC (or the XML the TOC loads) at the place that keeps load order working, and into the `tests/` loader calls that load its old home.
- **Docs:**
  - Update any `.agents/*.md` doc whose `covers:` matches a file you changed and whose text your change makes wrong, and bump its `last_updated`. Add a new file to the `covers:` list that named its old home.
  - Update `AGENTS.md`'s layout table when a file it names moves or is renamed.
  - Don't edit `docs/followups.md`. Name in your report any followup your change settles; the controller moves it.
- **Privacy:** no WoW account folder name or character name in any file.
- **Commits:** `module: imperative summary` in lower case, staged by explicit path (never `git add -A`, `git add .` or a directory), each ending with:

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsM3V6p9vWPEFz7WA9o
  ```
- **Report file:** lists each item as done or left (with the reason), the test run's last line, and the in-game checks the change needs.

## Review Focus

1. **A deleted name still used through a string.** A method reached by `self[name]`, an option table's `get`/`set` string, an XML `mixin=` or `inherits=`, a TOC line. The reviewer greps each deleted name across the repo.
2. **Load order after a split.** A moved function used at file scope by a file that now loads before its new home. The reviewer reads each TOC (both clients) top to bottom against the new files.
3. **An upvalue left behind.** A function moved to a new file that still reads a `local` of its old file. Lua makes that a silent global read of `nil`. The reviewer checks every free name in moved code.
4. **A dead-branch removal that kept the wrong side.** `st.retail and A or B` must become `A`; `if not st.retail then X end` must lose `X`; `if st.retail then A else B end` keeps `A`.
5. **A Blizzard frame touched in a new way** by a helper that replaces several hand-written copies: a field written, a hook that isn't a post-hook, a protected frame moved in combat.

---

## Wave 1: fixes and removals

Tasks 1 to 6 run in parallel, one worktree each. Task 7 runs after they're integrated.

### Task 1: Core and Core's Config: dead code, two globals, the font labels

**Spec:** sections 1 (accidental globals), 2.1, 3.1, 3.2.

**Files:** `SaftUI-Core/**` except `Libraries/`, `taintfix.lua`, `init.lua`'s time played and `Config/optionswidgets.lua`'s keybinding widget. Tests in `tests/core/`.

- [ ] **Step 1: globals.** `EditMode/grid.lua` `function Draw()` becomes local (keep every caller working). `api.lua`'s `debug = st.StringFormat:ColorString(` becomes a local with another name.
- [ ] **Step 2: `st.retail` sites.** `Media/fonts.lua` (`FN.outlines.NONE`), `Utilities/itemupgrades.lua` (three sites). Keep the live side. Leave `constants.lua`'s definition (Task 7 removes it).
- [ ] **Step 3: font labels.** In `FN.outlines`: `NONE = 'None'`, and `MONOCHROMETHICKOUTLINE = 'Monochrome Thick Outline'`. In `FN:UpdateFontConfig`, a saved `'NONE'` is passed to `SetFont` as `''`. Test: the outline values table labels None as `None`, and a font saved with `NONE` reaches `SetFont` with `''`.
- [ ] **Step 4: dead code (section 3.1).** After the repo-wide search, remove:
  - `api.lua`: the eleven `st:Snap*` functions and `st:Hide` (keep `st:CalculateSpacing`).
  - `utilities.lua`: `string.findnocase`, `st:createBarrier` and `isBlocking`, `st.tableinvert`, `st.imap`, `st.tablepurge`, `string.escape`, `st:ScanEquippedItem` with its file-scope `ScanningTooltip` frame.
  - `Utilities/tooltipscanner.lua` and `Utilities/itemupgrades.lua`: the unused functions the report names; the `st.util` alias.
  - `Widgets/scrolllist.lua`, its `templates.xml` template and `SaftUIScrollListItemMixin`, with their TOC or XML lines; `st:CreateScrollBar` if nothing calls it; the unused aliases in `button.lua` and `statusbar.lua`; the dead lines in `editbox.lua`.
  - `skinning.lua`: the dead functions and the stray `print` the report names (not `st:EnableResizing`). `theme.lua`'s stray `print`.
  - `panels.lua`: the arrow helpers nothing calls (keep `st:CreatePanel`).
  - Constants nothing reads: `st.mult`, `st.my_race`, `st.my_faction`, `st.ICON_COORDS`, `st.INVERSE_ANCHORS`, `st.TAB_HEIGHT`, `st.textures.mail`, `st.textures.glow`. `EM:IsActive`. `sharedmedia.lua`'s second Righteous registration.
- [ ] **Step 5: dead code (section 3.2).** `Config/widgets.lua`'s `st.Config.options`, `optionswidgets.lua`'s unused `tconcat`, `optionsbody.lua`'s `OB.COLUMN_GAP`, `QUARTER_GAP`, `SMALL_INPUT_WIDTH`. `config.lua`'s `SAFTUI` is the `/sui` handler: keep it.
- [ ] **Step 6:** `tests/run` passes. Commit per step.

### Task 2: Unitframes: dead code, a global, two bugs

**Spec:** sections 1 (bugs 9, 10; the `r, g, b` global), 2.1, 3.3.

**Files:** `SaftUI-Unitframes/**` except `Libraries/`. Tests in `tests/unitframes/`.

- [ ] **Step 1: bug 9, test first.** `UF:UpdateElementPosition(element, unitframe, configOverride)` is called as `(element, configOverride)` twice in `updaters.lua`. Read both callers and the function, decide which is right from what each caller has in hand, and make the override reach the position. The test drives one of the two callers with an override and asserts the element is placed by it.
- [ ] **Step 2: bug 10.** `config/units/pet.lua` has two `power` keys. Merge them so the table says what Lua already does today (the second wins); the pet's defaults must not change. Test: the pet's `power` defaults equal today's.
- [ ] **Step 3: global.** `elements/health.lua`'s `r, g, b = health:GetStatusBarColor()` becomes local.
- [ ] **Step 4: `st.retail` sites.** `elements/health.lua`, `power.lua`, `additionalpower.lua` (two), `tags.lua`.
- [ ] **Step 5: dead code (section 3.3).** `elements/powerprediction.lua` (empty, in no TOC), `UF.RMH`, `self.unitLabel`, `power.lua`'s `GetDisplayPower` and unused local, `additionalpower.lua`'s unused local `Update`, `indicators.lua`'s `DEBUG` hooks, the two identical castbar functions made one, `config/config.lua`'s extra `GetConfigTable` arguments, the dead lines in `name.lua` and `updaters.lua`. Keep `UF.allUnits` and `UF:SetProfile` (test seams).
- [ ] **Step 6:** `tests/run` passes. Commit per step.

### Task 3: Bags: five bugs and dead code

**Spec:** sections 1 (bugs 2, 3, 4, 5, 8), 2.1, 3.4.

**Files:** `SaftUI-Bags/**`. Tests in `tests/bags/`.

Each bug gets a failing test first.

- [ ] **Step 1: bug 2.** `INV:HideBags` (`containers/bag.lua`) loops `self.containers.bag.slots`, which is never filled. Loop the slots of every category, as `inventory.lua` does (`for _, category in pairs(container.categories)` then `category.slots`), so `C_NewItems.RemoveNewItem(bagID, slotID)` runs for each slot. Test: closing the bags calls it for a new item's slot.
- [ ] **Step 2: bug 3.** `INV:CurrencyOnClick(slot)` reads `self.currencyIndex`; use `slot.currencyIndex`. Test: a shift-click on a currency slot links that currency.
- [ ] **Step 3: bug 4.** `INV:UpdateContainer`: `if not container and container:IsShown() then return end` becomes `if not (container and container:IsShown()) then return end`. Check every caller first: if one relies on a hidden container being updated, keep that working and say so. Test: a nil container id returns without an error; a hidden one isn't laid out.
- [ ] **Step 4: bug 5.** `category.lua`'s sort key reads `item.itemCount` and `item.itemId`; the fields are `stackCount` and `itemID`. Test: two stacks of one item order by count, and two items equal on the earlier keys order by ID. This changes the bags' sort order in game: put it in the report's in-game checks.
- [ ] **Step 5: bug 8.** `INV:CreateSlot`: the `assert(categoryFrame, ...)` moves above the line that reads `categoryFrame.slots`.
- [ ] **Step 6: `st.retail` sites.** `inventory.lua`, `containers/bag.lua`, `slot.lua`, `currencies.lua`.
- [ ] **Step 7: dead code (section 3.4).** `INV:GetAutoVendorProfit`; the fields nothing reads (`INV.OnUseItems`, `slot.type`, `unitPrice`, `bindType`, the dead block near the end of `container.lua`, the dead lines in `rules.lua`). `container.slots` goes only if Step 1 leaves nothing reading it. Keep `INV.ItemClasses.Reset` and `INV.CategoryDefaults.Reset` (test seams).
- [ ] **Step 8:** `tests/run` passes. Commit per step.

### Task 4: Loot, ActionBars, Chat: one bug and dead code

**Spec:** sections 1 (bug 1), 2.1, 3.5.

**Files:** `SaftUI-Chat/**`, `SaftUI-Loot/**` (not `popup.lua`, not the honor feed), `SaftUI-ActionBars/**` except `Libraries/`. Tests in `tests/chat/`, `tests/loot/`, `tests/actionbars/`.

- [ ] **Step 1: bug 1, test first.** `CHT:FCFDock_UpdateTabs` sets `prev` only in the `else`, so the third and later docked tabs anchor to tab 1. Each docked tab anchors to the one before it. Check Blizzard's `FCFDock_UpdateTabs` in the Forever source for which tabs are docked and shown. Test: with three docked tabs, tab 3 is anchored to tab 2.
- [ ] **Step 2: `st.retail` sites.** `SaftUI-Loot/Feed/feed.lua` (two), `SaftUI-Chat/chatframe.lua`.
- [ ] **Step 3: dead code (section 3.5).** `CHT:ChatFrame_OnUpdate` and the `linespacing` default; `hideblizzard.lua`'s unused `'MainMenuBar'` entry and `AB.blizzardBars`; the dead line in `ActionBars/skin.lua`; `LT.DEBUG`; the unused `categories` tables in `Feed/feed.lua` (not the honor entries' own code); the unused locals in `roll.lua`; the dead lines in `Feed/filter.lua`.
- [ ] **Step 4:** `tests/run` passes. Commit per step.

### Task 5: Misc and Minimap: dead code, the swing timer's event, the movable list

**Spec:** sections 1 (bugs 12, 13; the `MiniMapMailFrame_UpdatePosition` global), 2.1, 3.6.

**Files:** `SaftUI-Misc/**`, `SaftUI-Minimap/**`. Tests in `tests/misc/`, `tests/minimap/`.

- [ ] **Step 1: bug 13, test first.** `ST:OnEnable` (`Skinning/Blizzard_SwingTimer.lua`) registers `ADDON_LOADED` whenever `SwingTimerMainHandFrame` is missing. Register only when the client has a `Blizzard_SwingTimer` addon to wait for (`C_AddOns.DoesAddOnExist`, checked against both clients' source). Test: with no such addon, nothing is registered; with it not yet loaded, the wait still works.
- [ ] **Step 2: bug 12.** `SaftUI-Misc/movable.lua` prints `Frame not found: TransmogFrame` at login. Find `TransmogFrame`'s owning addon in both clients' source. If it's a load-on-demand addon on both (or missing on one), give the list entry its addon and make the frame movable when that addon loads, with no print. If the source doesn't settle it, leave the file alone and say so. Test first if fixed.
- [ ] **Step 3: `st.retail` sites.** Misc: `experience.lua` (two), `Skinning/Blizzard_BuffFrame.lua`, `Skinning/Blizzard_WatchFrame.lua` (the whole file never runs: delete it and its TOC lines). Minimap: `instancedifficulty.lua`, `killblizz.lua`, `minimap.lua`, `micromenu.lua` (with the dead `MiniMapMailFrame_UpdatePosition` global), `queuebutton.lua`, `zonetextbutton.lua`.
- [ ] **Step 4: dead code (section 3.6).** `Skinning/skinning.lua`'s `SkinBlizzardPanel`, `SkinTab`, `UpdateTab`, `SkinTabHeader` with the cases in `tests/misc/theme_test.lua` that only call them; the dead lines in `tooltip.lua`; the four `issecretvalue` shims (the global exists on both clients: check the source); the dead lines in `experience.lua`.
- [ ] **Step 5:** `tests/run` passes. Commit per step.

### Task 6: a faster test run

**Spec:** section 6.1.

**Files:** `tests/runner.py`, `tests/run`, `tests/wow/widgets.lua`, `tests/unitframes/nameplate_world.lua`, `tests/lib/harness_self_test.lua`, `.agents/testing.md`.

- [ ] **Step 1: measure.** Time `tests/run` three times; note the median and the ten slowest files.
- [ ] **Step 2: run files in parallel.** `tests/run -jN` (default: the CPU count; `-j1` is today's serial run). Each file still gets its own Lua state, in its own process. The report prints in file order whatever order the files finish in, with the same text and exit codes as today (0, 1, 2, 70). A worker process that dies makes the run exit 70 naming the file. `tests/run --self-check` passes, and gains a check that `-j1` and the default give the same report for the fixtures.
- [ ] **Step 3: the stub's cheap wins.** In `tests/wow/widgets.lua`: `Show`, `Hide` and `SetShown` return early when the frame's shown state doesn't change (only where the game does the same: `OnShow` and `OnHide` don't fire for a no-op); `SetPoint` skips `depends_on` when `relativeTo` is the frame's parent, if the check it feeds can't differ. Leave the scale and rect caching alone. Every existing test passes unchanged.
- [ ] **Step 4: the doubled defaults.** `NP.world` (`tests/unitframes/nameplate_world.lua`) calls `apply_defaults()` after `T.client` already did. Drop the second call if the world it builds is the same.
- [ ] **Step 5: measure again.** Same three runs. Put before and after in the report file, and the new flag in `.agents/testing.md`.
- [ ] **Step 6:** `tests/run` and `tests/run --self-check` pass. Commit per step.

### Task 7: remove `st.retail`

**Spec:** section 2.1. Runs after Tasks 1 to 5 are integrated.

**Files:** `SaftUI-Core/constants.lua`, `tests/core/theme_blizzard_test.lua`, `tests/bags/fixtures/old_filters.lua`, `.agents/clients.md`, `.agents/architecture.md`, any site left.

- [ ] **Step 1:** grep `st.retail` and `%.retail` across `SaftUI-*` (not `Libraries/`) and `tests/`. Resolve each site left by keeping the live side. `tests/bags/fixtures/old_filters.lua`'s `if st.retail and (...)` loses `st.retail and`; `tests/core/theme_blizzard_test.lua`'s two `st.retail` assertions go.
- [ ] **Step 2:** delete `st.retail` from `constants.lua`. Test: `st.retail` is nil on both clients and `st.forever` is true only on Forever.
- [ ] **Step 3:** `.agents/clients.md` and `.agents/architecture.md` say the flag is gone and that `st.forever` is the only client test.
- [ ] **Step 4:** `tests/run` passes. Commit.

---

## Wave 2: shared Core helpers

Tasks 8 and 9 run in parallel. Tasks 10 and 11 follow in order (they share Misc files with Task 9).

### Task 8: pure helpers in Core, and their copies gone

**Spec:** section 2.2.

**Interfaces (produces, in `SaftUI-Core/utilities.lua` unless said):**
- `st.Plain(value)`: `value`, or nil when `issecretvalue(value)`. `st.PlainNumber(value)` and `st.PlainString(value)` with the bodies `SaftUI-Loot/Feed/rolls.lua` has today.
- `st.Clamp(value, low, high)`: the body `SaftUI-ActionBars/bars.lua` has today.
- `st.OutlineFlag(outline)`: the font flag for a saved outline key (`'NONE'` gives `''`), in `SaftUI-Core/Media/fonts.lua`.

- [ ] **Step 1:** tests for each helper in `tests/core/`, then the helpers.
- [ ] **Step 2: adopt.** Replace a local copy only where its body does the same thing for every input (read each one: `ActionBars/extras.lua`'s `Clamp` takes a default, so it stays or wraps `st.Clamp`). Copies: `Plain`/`IsPlain`/`PlainNumber`/`PlainString` in `SaftUI-Loot/roll.lua`, `Feed/history.lua`, `Feed/rolls.lua` and `SaftUI-Unitframes/tags.lua`; `Clamp` in `ActionBars/bars.lua` and `Misc/Skinning/Blizzard_BuffFramePosition.lua`; `OutlineFlags` in `Misc/Skinning/Blizzard_BuffFramePosition.lua` and `ActionBars/skin.lua`, and `OutlineValues` in `ActionBars/options.lua` (now `FN.outlines`, which labels None since Task 1).
- [ ] **Step 3:** the tooltip text join in `SaftUI-Core/Utilities/tooltipscanner.lua` and `SaftUI-Bags/tooltipscanner.lua` becomes one Core function both use, if the two bodies agree.
- [ ] **Step 4:** the action-button state textures set up in both `ActionBars/skin.lua` and `Misc/totemskin.lua` become one Core function both call, if the two bodies agree. `LARGE_COUNTDOWN_SIZE` and `BLIZZARD_SIZE` become one constant each, in Core.
- [ ] **Step 5:** Bags' `CopyTree`/`SameTree` and `R.Copy`/`R.Equal`: one pair, if they agree for every input the callers give.
- [ ] **Step 6:** `tests/run` passes. Commit per step.

### Task 9: `st:OnBlizzardAddon`

**Spec:** sections 2.2, 4.3.

**Interface (produces, `SaftUI-Core/api.lua`):** `st:OnBlizzardAddon(name, fn)`: calls `fn()` now if the addon `name` is loaded (`C_AddOns.IsAddOnLoaded`), otherwise once when its `ADDON_LOADED` fires. One shared event frame; nothing stays registered once no wait is left.

- [ ] **Step 1:** tests: already loaded runs at once; not loaded runs once on its event and not on another addon's; two waits on one addon both run; the frame unregisters when the last wait is done.
- [ ] **Step 2:** the helper.
- [ ] **Step 3: adopt** in the ten hand-written `ADDON_LOADED` handlers the report lists (Misc's skins and others). Keep each one's timing: a handler that also does work at login keeps doing it. A handler that waits on more than a Blizzard addon stays as it is.
- [ ] **Step 4:** `tests/run` passes. Commit per step.

### Task 10: Edit Mode holder helpers

**Spec:** sections 2.2, 4.3. Taint-sensitive: read `.agents/taint.md` first.

**Interfaces (produces, `SaftUI-Core/api.lua` or a new `SaftUI-Core/holders.lua`):**
- `st:HideEditModeSelection(frame)`: keeps a Blizzard frame's Edit Mode `Selection` hidden with a post-hook on its `OnShow`, writing no field on the frame. Today's `AB:HideEditModeSelection` is the model.
- `st:HoldFrame(frame, holder)` and `st:PlaceHolder(...)`: the snippet the report says is copied nine times across six sites. Read all nine first and write down, in the report file, how each differs. Only copies that do the same thing move onto the helper.

- [ ] **Step 1:** tests for each helper on a stub Blizzard frame: no field written on it, protected frames queued until combat ends, the selection stays hidden when shown again.
- [ ] **Step 2:** the helpers.
- [ ] **Step 3: adopt** at the sites that match: `ActionBars/hideblizzard.lua` and `extras.lua`, `Chat/chatframe.lua`, `Minimap/microbuttons.lua` and `minimap.lua`, `Misc/tooltipposition.lua`, `totembar.lua`, `experience.lua`, `Skinning/Blizzard_BuffFramePosition.lua`, `Skinning/Blizzard_SwingTimerPosition.lua`. Every existing test passes unchanged.
- [ ] **Step 4:** `tests/run` passes. Commit per step.

### Task 11: mover helpers

**Spec:** sections 2.2, 4.3. Read `.agents/edit-mode.md` first.

**Interfaces (produces, `SaftUI-Core/EditMode/`):**
- `st:PlaceAtPosition(frame, position)`: clears a frame's points and sets it from a saved position table, as the roughly 20 `UnpackPoint` sites do by hand.
- `st:RegisterConfigMover(frame, spec)`: registers a mover whose `getPosition` and `setPosition` read and write a config path, as the 14 hand-written closures do.

Settle the exact arguments from the sites: read them all first and list the variants in the report file.

- [ ] **Step 1:** tests, then the helpers.
- [ ] **Step 2: adopt** where a site does exactly what the helper does. A site with its own extra work keeps it.
- [ ] **Step 3:** `.agents/edit-mode.md` names the helpers.
- [ ] **Step 4:** `tests/run` passes. Commit per step.

---

## Wave 3: Core's Config

In order.

### Task 12: split `optionswidgets.lua`

**Spec:** section 4.1 (the file table and the pitfalls are binding).

- [ ] **Step 1:** add `load_options_widgets()` to `tests/lib/shell.lua` and use it wherever a test loads `optionswidgets.lua` by path. `tests/run` passes. Commit.
- [ ] **Step 2:** split the file as section 4.1's table says, sharing one `W.Kit` table for the names the files need from each other. Each move is cut and paste: no body changes. The loader from Step 1 loads the new files in TOC order. Keep the keybinding widget's code as it is (it moves whole into its file).
- [ ] **Step 3:** both Core TOCs (or a `Config/load.xml` both name) list the files in dependency order. `.agents/edit-mode.md`'s `covers:` and text name the new files.
- [ ] **Step 4:** `tests/run` passes with no assertion changed. Commit per file moved.

### Task 13: split `optionswindow.lua`

**Spec:** section 4.2.

- [ ] **Step 1:** add `load_options_window()` to `tests/core/config_helpers.lua` (or `tests/lib/shell.lua`) and use it wherever a test loads `optionswindow.lua` by path. Commit.
- [ ] **Step 2:** split into `optionslayout.lua`, `optionsresize.lua`, `optionsnav.lua`, `optionssmalldialog.lua` and the core, as section 4.2 says. The file-scope upvalues the pieces share move onto one table (`OW.S`). No body changes beyond reading those names from it.
- [ ] **Step 3:** TOCs, `.agents/edit-mode.md`.
- [ ] **Step 4:** `tests/run` passes with no assertion changed. Commit per file moved.

### Task 14: Config's duplicates, and `Config/widgets.lua` renamed

**Spec:** sections 3.2, 4.8.

- [ ] **Step 1:** one colour getter where three files have their own; one Esc catcher where there are five copies; one `ColorPickerFrame:IsShown()` check; one `FIELD_HEIGHT`. Only where the copies agree.
- [ ] **Step 2:** `SaftUI-Core/Config/widgets.lua` becomes `Config/generators.lua` (`git mv`), with TOCs, test loaders and docs following. `generators.uf_element_position` moves to Unitframes' config if nothing else uses it.
- [ ] **Step 3:** `tests/run` passes. Commit per step.

---

## Wave 4: per-addon organization

Tasks 15 to 19 run in parallel. Each is moves and renames only. Every existing test passes with no assertion changed (only loader paths change).

### Task 15: Unitframes

**Spec:** section 4.4.

- [ ] `config/config.lua`: the profile code and the plate pages move out (the plate pages to `nameplates/options.lua`); the group options to their own file.
- [ ] `groups.lua` into `grouplayout.lua`, `blizzardraid.lua`, `grouppreview.lua` and what's left.
- [ ] `purge.lua` renamed `aurafilters.lua`.
- [ ] The two `PostUpdateColor` bodies made one, if they agree.
- [ ] TOCs (both clients), test loaders, `.agents/` docs, `AGENTS.md`'s layout row. `tests/run` passes.

### Task 16: Bags

**Spec:** section 4.5.

- [ ] `container.lua` into header, layout and search files and what's left.
- [ ] The open and close, gold frame and deposit button code that `containers/*.lua` repeat becomes shared functions, where the copies agree.
- [ ] `INV.DragParts` to `dragparts.lua`. `StackGroup`, `IndexOf` and `WINDOW_NAMES` defined once.
- [ ] TOC, test loaders, `.agents/` docs, `AGENTS.md`'s layout row. `tests/run` passes.

### Task 17: Loot, ActionBars, Chat

**Spec:** section 4.6.

- [ ] `SaftUI-Loot/roll.lua` into `rollbar.lua`, `rolltest.lua` and what's left. `Feed/rolls.lua`'s loot history to `Feed/loothistory.lua`. `Feed/feed.lua`'s message parsing to `Feed/parse.lua`.
- [ ] `SaftUI-ActionBars/bindings.lua`'s hover binding mode to `keybindmode.lua`. The pet and stance bars' `RefreshAll` shared, if they agree.
- [ ] Chat's `SkinChatFrame` and `ApplyChatFrameConfig`: the setup both repeat becomes one function.
- [ ] TOCs, test loaders, `.agents/` docs, `AGENTS.md`'s layout rows. `tests/run` passes.

### Task 18: Misc and Minimap

**Spec:** section 4.7.

- [ ] `SaftUI-Misc/Skinning/` into `Skinning/blizzard/` and `Skinning/addons/` (`git mv`; file names kept).
- [ ] `totembar.lua` into its four jobs; `TB.PostHook` defined in a file that loads before its first user.
- [ ] `st.defaults.experience` in one place (Misc).
- [ ] `SaftUI-Minimap/micromenu.lua` into its four jobs, with its options beside it out of `config.lua`.
- [ ] TOCs (both clients where there are two), test loaders, `.agents/` docs, `AGENTS.md`'s layout rows. `tests/run` passes.

### Task 19: Core outside Config

**Spec:** section 4.8.

- [ ] `themeart.lua`'s data tables to `themeart_data.lua`.
- [ ] The nine-slice code `EditMode/mover.lua` has twice becomes one function.
- [ ] `st:SetHeight` and `st:SetWidth` pass-throughs: callers call the frame's own method, and the two go, if they add nothing.
- [ ] `st:barrier(self, ...)`'s shadowed `self` renamed.
- [ ] The `Utilities/` module gets the name the report suggests (`ItemQuality`), if nothing outside Core reaches it by its old name through a string.
- [ ] TOCs, test loaders, `.agents/` docs. `tests/run` passes.

---

## Wave 5: the tests

In order.

### Task 20: shared test setup

**Spec:** section 6.2.

- [ ] One `use_client(name)` in `tests/lib/` where `T.client`, `W.fresh` and `tests/bags/theme_test.lua` each have their own.
- [ ] `tests/unitframes/uf_world.lua`, `load_string_format()`, `load_editmode()`, `stub.click`, `tick`, `near`, `rgb`, `T.theme(name, after)`, `T.anchor`, `T.check_theme_page(spec)`, `T.round_trip`: each defined once and used where a test has its own copy.
- [ ] `tests/misc/fixtures/locked_widget.lua` and `tests/core/options_walk.lua` move to `tests/lib/`.
- [ ] No assertion changes. `tests/run` passes with the same number of checks as before. `.agents/testing.md` lists the helpers.

### Task 21: big test files, names, the alpha clamp

**Spec:** sections 6.4, 6.5.

- [ ] `tests/core/options_widgets_test.lua`, `tests/core/options_window_test.lua` and `tests/bags/categories_tab_test.lua` split by subject, along the source files' new boundaries. The check count stays the same.
- [ ] `restedxp_task1_test.lua`, `_task2_`, `_task3_` renamed for what they check.
- [ ] The stub clamps alpha to 0 to 1 as the game does (`tests/wow/widgets.lua`, both `SetAlpha` places), with a self-test case. Fix any test that relied on an out-of-range alpha, and say which.
- [ ] `.agents/testing.md`. `tests/run` passes.
