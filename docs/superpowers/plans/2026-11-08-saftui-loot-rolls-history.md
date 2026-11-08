# Loot Rolls and Saved Feed Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Save the loot feed per character across reloads, add a feed entry with everyone's rolls for every rolled item, and show live choices on SaftUI's roll bars.

**Architecture:** Three layers in `SaftUI-Loot`, built in order:
1. The feed gets a saved store in the AceDB char namespace, restored at load (`Feed/history.lua`).
2. A `C_LootHistory` watcher turns ended rolls into feed entries and owns the roll tooltip lines (`Feed/rolls.lua`).
3. The roll bars match their drop and show counts and the same tooltip lines (`rollinfo.lua`).

**Tech Stack:** WoW addon Lua for Forever (16001) and retail (120000); AceDB, AceEvent, AceConfig; `C_LootHistory`. There's no test runner: verify by reading the code, and the user checks in game.

**Spec:** `docs/superpowers/specs/2026-11-08-saftui-loot-rolls-history-design.md`. Read all of it, including "Settled after the builder check". It's the authority.

## Global Constraints

- **Taint:** no field writes on Blizzard frames or tables. Keep new pieces in local tables keyed by the Blizzard frame. Post-hooks only.
- **Saved data:**
  - It lives in `st.config.char.loot`, as `{ feed = { entries newest first }, drops = { [key] = true } }`.
  - Plain data only. Never a secret value (`issecretvalue`). Never test entries.
- **Cap:** `MAX_HISTORY = 500` entries (the existing constant).
- **Recorded-drop key:** `encounterID .. ':' .. lootListKey .. ':' .. itemString`, where `itemString` is the `item:…` part of `itemHyperlink`, and `lootListKey` falls back to retail's `lootListID` (spec, Revised 2026-11-08).
- **Real time:** `info.when = time()`. Restored entries are never fresh at restore.
- **Copy, verbatim:**
  - "All passed"
  - "Waiting on:" (use Blizzard's `LOOT_HISTORY_WAITING_ON` if it exists, else that text)
  - the F dropdown entry "Rolls"
  - `/sui` → Loot button "Clear history"
- **Defaults:** `st.defaults.loot.feed.filters.Rolls = true`.
- **Both clients:** check every `C_LootHistory` and roll API you use in Forever's `Blizzard_APIDocumentationGenerated` (copies in the scratchpad's `loothist/`).

## Review Focus

1. **A reload or relog mid-roll, or after rolls ended:** no roll result is lost or recorded twice, and none flashes up as new at load. This is Task 2's recorded-drop handling.
2. **The winner's loot message before or after the roll ends, with the Rolls or Loot filter off:**
   - The item shows exactly once.
   - It never vanishes when the item was yours (Task 2's folding and `ShouldAddItem`).
3. **A full raid's rolls on many items:**
   - The saved store stays at 500 entries.
   - Only the fields the line and the tooltip need are saved, and nothing secret (Tasks 1 and 2).
4. **Two identical items rolled at once, or a roll bar with no matching drop:** no Lua error, and a bar with no drop shows no counts (Task 3).
5. **Clear history and test mode:**
   - Clear empties the saved store and the feed on screen, but keeps the recorded-drop set, so cleared results don't come back at the next load.
   - Test entries are never saved (Tasks 1 and 2).

---

### Task 1: Save and restore the loot feed

**Files:**
- Create: `SaftUI-Loot/Feed/history.lua` (the saved store, restore at load, the "ago" text)
- Modify:
  - `SaftUI-Loot/Feed/feed.lua`:
    - `LT:LootFeedPush` stamps `when`, merges only into current-session entries, and saves.
    - Freshness skips restored entries.
    - `ShowTooltip` ends every feed tooltip with the "ago" line, and entries without a link get a small tooltip with their text.
  - `SaftUI-Loot/options.lua`: "Clear history".
  - `SaftUI-Loot/SaftUI-Loot.toc`: `Feed/history.lua` before `Feed/feed.lua`.
  - `README.md`: Usage, "the loot feed is kept per character across reloads".

**Interfaces:**
- Produces:
  - `LT:GetHistoryStore() -> table`: `st.config.char.loot`, created with `feed = {}` and `drops = {}` if missing.
  - `LT:SaveFeedEntry(info)`: writes the entry's plain-data copy to the front of `store.feed` and trims it to 500. It skips `info.test` and any secret value. It's called by `LootFeedPush` and on merges (which update the saved copy in place).
  - `LT:RestoreFeed()`: once at load, before the feed's first draw. It fills `feed_stack` from `store.feed`, each entry marked `restored = true` and not fresh.
  - `LT:InsertRestoredEntry(info)`: inserts a non-fresh entry by its `when` (newest first), without merging, and saves it. Task 2 uses it for drops that ended while the addon wasn't watching.
  - `LT:FormatAgo(when) -> string`: "just now", "5 minutes ago", "2 hours ago", "3 days ago".
  - Entry fields added: `when` (number), `restored` (session-only, not saved).

- [ ] **Step 1: Read.**
  - The spec.
  - All of `Feed/feed.lua`, `Feed/filter.lua`, `Feed/test.lua`, `init.lua`, `options.lua`, `config.lua`.
  - How `st.config.char` is created (`SaftUI-Core/Config/config.lua`).
- [ ] **Step 2: Write `Feed/history.lua`** with the interfaces above.
  - The saved copy holds only the fields a feed line and its tooltip use. Check every reader in `feed.lua`, and leave out `time`, `test` and `restored`.
- [ ] **Step 3: Wire it into `feed.lua` and `options.lua`.**
  - "Clear history" is an `execute` with `confirm = true`. It empties `store.feed` and `feed_stack` and redraws the feed. It leaves `store.drops` alone.
- [ ] **Step 4: Verify by reading.**
  - Walk a reload: restored entries appear only when scrolling back.
  - Walk a merge of new gold after a reload: it makes a new entry, not a merge into a restored one.
  - Walk test mode: nothing is saved.
  - Walk 501 pushes: the store stays at 500.
  - Check that a profile switch doesn't touch the store (char namespace).
- [ ] **Step 5: Commit** `loot: keep the loot feed per character across reloads`.

### Task 2: Roll results in the feed

**Files:**
- Create: `SaftUI-Loot/Feed/rolls.lua` (the `C_LootHistory` watcher, roll summaries, tooltip lines, recorded drops, folding)
- Modify:
  - `SaftUI-Loot/Feed/feed.lua`:
    - `LootFeedAddItem` offers each loot message to the folding first.
    - `ShowTooltip` adds roll lines for entries with `rolls`.
  - `SaftUI-Loot/Feed/filter.lua`: the "Rolls" entry, and the `ShouldAddItem` rule from the spec.
  - `SaftUI-Loot/Feed/test.lua`: a sample roll result.
  - `SaftUI-Loot/config.lua`: `filters.Rolls = true`.
  - `SaftUI-Loot/SaftUI-Loot.toc`: `Feed/rolls.lua` after `Feed/feed.lua`.
  - `README.md`: Usage, roll results in the feed.

**Interfaces:**
- Consumes (Task 1): `LT:GetHistoryStore()`, `LT:LootFeedPush(info)`, `LT:InsertRestoredEntry(info)`, `LT:SaveFeedEntry(info)`.
- Produces:
  - `LT:SummarizeDrop(dropInfo) -> rolls`: a plain-data table, `{ allPassed = bool, winner = index|nil, leader = index|nil, tied = bool, list = { { name, class, state, roll, isSelf, isWinner }, ... } }`, with no secrets. Stored on the entry as `info.rolls`.
  - `LT:AddRollLines(tooltip, rolls, live)`: appends the lines Blizzard's LootHistory tooltip shows:
    - choices, with "(off spec)" and roll numbers
    - the winner marked, or "All passed"
    - when `live`: "Waiting on:" and the current leader or tie
  - Roll entries: `type = 'Rolls'`, `rightText` = the class-coloured winner or "All passed", `rolls`, `looted` (true once folded with a loot message), `notSelf` taken from the folded message.
  - After handling `LOOT_HISTORY_UPDATE_DROP`, it calls `self:UpdateRollBars()` if that exists (Task 3 defines it).

- [ ] **Step 1: Read.**
  - The spec's parts 2 and 3 and its settled points.
  - The `C_LootHistory` docs and Blizzard's `Mainline/LootHistory.lua` tooltip code (in the scratchpad's `loothist/`).
  - Task 1's `Feed/history.lua`.
- [ ] **Step 2: Write `Feed/rolls.lua`.**
  - The watcher (`LOOT_HISTORY_UPDATE_DROP`, `LOOT_HISTORY_CLEAR_HISTORY`), and at load:
    - prune `store.drops` against the live history
    - add any ended, unrecorded drops with `InsertRestoredEntry` and an estimated `when`
  - The "someone rolled" rule and the recorded-drop set.
  - Folding, in both orders, inside a short window of your choosing. Name it as a constant with a comment.
  - `SummarizeDrop` and `AddRollLines`.
- [ ] **Step 3: Wire it in.** Update `feed.lua`, `filter.lua`, `test.lua`, `config.lua`, the TOC and the README.
- [ ] **Step 4: Verify by reading.**
  - Walk Review Focus 1 and 2 against the code: each order of loot message and roll end, with each filter state.
  - Walk Review Focus 3: no secret is ever saved, and the summary stays small.
  - Check that the test sample is never saved.
- [ ] **Step 5: Commit** `loot: roll results in the loot feed, with everyone's rolls on hover`.

### Task 3: Live choices on the roll bars

**Files:**
- Create: `SaftUI-Loot/rollinfo.lua` (match bars to drops, counts on the buttons, the roll tooltip on the bar)
- Modify:
  - `SaftUI-Loot/roll.lua`: create the count text through `rollinfo.lua`'s functions, hook the bar's tooltips, and give the previews sample counts.
  - `SaftUI-Loot/SaftUI-Loot.toc`: `rollinfo.lua` after `roll.lua`.
  - `README.md`: Usage, roll counts on the roll bars.

**Interfaces:**
- Consumes (Task 2): `LT:SummarizeDrop(dropInfo)`, `LT:AddRollLines(tooltip, rolls, live)`, and the `LT:UpdateRollBars()` call after each drop update.
- Produces:
  - `LT:UpdateRollBars()`: re-matches every shown roll bar to a drop still being rolled. The match uses `GetLootRollItemLink(frame.rollID)` against `itemHyperlink`, with each drop matched at most once. It then refreshes the bar's button counts and any open roll tooltip.
  - Pieces on Blizzard's frames are kept in a local table keyed by the frame: count font strings and the matched drop. The new code writes no fields onto them.

- [ ] **Step 1: Read.**
  - The spec's part 1 and its hover-target point.
  - `roll.lua` in full: skin, update, previews.
  - Blizzard's GroupLootFrame code on Forever: where `rollID` lives, the icon frame's OnEnter, and when frames show and hide.
- [ ] **Step 2: Write `rollinfo.lua`.**
  - Matching, the counts (Need includes off spec), and the tooltip on the icon frame and on SaftUI's info frame.
  - Also call `UpdateRollBars` when a bar shows and when one hides, so a freed drop can match a new bar.
- [ ] **Step 3: Wire it into `roll.lua`.** Previews get sample counts and a sample roll tooltip built from a hand-made `rolls` table passed to `AddRollLines`. Update the TOC and the README.
- [ ] **Step 4: Verify by reading.**
  - Walk Review Focus 4: identical items, and a bar with no drop.
  - Check that counts clear when a bar is reused for a new roll.
  - Run the field-write grep on `rollinfo.lua`: `grep -nE "(frame|button|IconFrame|Timer)\.[A-Za-z_]+ *= " SaftUI-Loot/rollinfo.lua` must have no hits on Blizzard objects.
- [ ] **Step 5: Commit** `loot: show who has chosen what on the roll bars`.
