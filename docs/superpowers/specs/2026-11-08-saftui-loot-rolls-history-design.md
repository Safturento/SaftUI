# Loot rolls on the roll bars and in the feed, and a saved loot feed

Status: approved in conversation, 2026-11-08.

## Intent

Blizzard's Loot Rolls window (`GroupLootHistoryFrame`, built on `C_LootHistory`)
shows who chose what on each drop and who won. On Forever it never opens by
itself (`Blizzard_FrameXML/Camelot/LootHistory.lua`: `ShouldAutoOpen` returns
false). The user wants that information where they already look: SaftUI's roll
bars and its loot feed. In their words: "I want to be able to see who has rolled
on each item so far to make a decision on what to roll as well as see
historically who rolled on what and who won what items." They also want the loot
feed as a whole to survive `/reload` and logging out: "can we keep track of loot
info across reloads? including the loot feed results in general".

That's three parts:
1. **While a roll is open:** the roll bar shows who has chosen what so far.
2. **After a roll:** the feed has an entry for every rolled item, naming the winner, and hovering it shows everyone's rolls.
3. **Saved feed:** the whole feed, roll results included, is kept per character across `/reload` and logout.

## Background (read first)

- `SaftUI-Loot/roll.lua` skins Blizzard's `GroupLootFrame`s as SaftUI's roll bars:
  - an icon, the item name, a thin timer, and the roll buttons with letters P / G / DE / N
  - test previews (`CreateRollPreviews`, `SetTestRolls`)
- `SaftUI-Loot/Feed/feed.lua` builds the loot feed from chat messages (`CHAT_MSG_LOOT`, `CHAT_MSG_MONEY`, …) into an in-memory `feed_stack` of plain tables:
  - capped at `MAX_HISTORY = 500`
  - newest first
  - merging repeats in `LT:LootFeedPush`
  - fresh entries show for `fade_time`, and older ones are reachable by scrolling
  - hover shows the item tooltip (`ShowTooltip`)
- `Feed/filter.lua` has the F dropdown of entry types. "Self Only" (`filters.Self`, on by default) hides other players' loot.
- `C_LootHistory` (Forever's `Blizzard_APIDocumentationGenerated/LootHistoryDocumentation.lua`; also on retail):
  - Drops are keyed by `(encounterID, lootListKey)`.
  - `GetSortedInfoForDrop` returns an `EncounterLootDropInfo`:
    - `itemHyperlink`, `playerRollState`
    - `rollInfos` (each: `playerName`, `playerClass`, `isSelf`, `state`, `isWinner`, `roll`)
    - `currentLeader`, `isTied`, `winner`, `allPassed`, `startTime`, `duration`
  - Events:
    - `LOOT_HISTORY_UPDATE_DROP(encounterID, lootListKey)` as choices and rolls come in
    - `LOOT_HISTORY_UPDATE_ENCOUNTER`
    - `LOOT_HISTORY_CLEAR_HISTORY`
  - `state` is `EncounterLootDropRollState`: NeedMainSpec, NeedOffSpec, Transmog, Greed, NoRoll (hasn't chosen yet), Pass.
  - A drop is still being rolled while it has neither `winner` nor `allPassed`.
- Blizzard's own tooltip for a drop (`Blizzard_FrameXML/Mainline/LootHistory.lua`, around lines 50–100) is the model for what to list:
  - choices, with roll numbers when known
  - "Waiting on: …" for NoRoll
  - all passed, the current leader or a tie
  - "(off spec)" for NeedOffSpec (`LOOT_HISTORY_OFF_SPEC_FMT`)

## Goals (decided with the user)

### 1. Live choices on the roll bar
- Each roll button (Need, Greed, Transmog, Pass) shows how many players have picked that choice so far. NeedMainSpec and NeedOffSpec both count as Need.
- Hovering the roll bar shows the item tooltip with the rolls added below it:
  - each player who has chosen, class-coloured, under their choice, with their roll number once the game has it
  - "Waiting on:" with everyone who hasn't chosen
  - the current leader (or a tie) once there are roll numbers
- It updates live as people choose (`LOOT_HISTORY_UPDATE_DROP`), while the tooltip is open too.
- Matching a roll bar to its drop: the game doesn't link a roll (`rollID`) to a history drop. Match by item link, `GetLootRollItemLink(rollID)` against `itemHyperlink`, among drops still being rolled. Each drop matches at most one bar, and duplicates go first come, first served. Two identical items rolled at once can be swapped; that's accepted. A bar with no match shows no counts and no roll lines (just the item tooltip).
- The test previews show sample counts and a sample roll tooltip, so the look can be checked without a group.

### 2. Roll results in the feed
- When a drop's roll ends (`winner` or `allPassed` appears on `LOOT_HISTORY_UPDATE_DROP`), the feed gets an entry for it:
  - the item's icon and name
  - on the right, the winner's name class-coloured, or "All passed"
- Exactly one entry per rolled item (my call). When the winner then loots it, the feed shows no second entry. The matching `CHAT_MSG_LOOT` message (same item link, same player, shortly after) is folded into the roll result instead of pushed. Folding a message never hides an entry that has no roll result.
- Hovering a roll result shows the item tooltip with everyone's choice and roll added, the winner marked, or "All passed".
- Roll results show even with "Self Only" on, since seeing who won what is the point. Other players' ordinary loot stays hidden by Self Only as before.
- The F dropdown gets a "Rolls" entry, on by default, to hide roll results (my call).

### 3. The feed is saved
- Every feed entry, whatever its type (loot, gold, currency, experience, reputation, honor, skill ups, roll results with their rolls), is saved per character and restored at login and after `/reload`.
- The cap stays at 500 entries, newest first. The oldest are dropped.
- Restored entries never show as new. They don't appear as fresh feed lines at login or after a reload; they're there when you scroll back.
- Each entry records the real time it happened (`time()`). Every feed tooltip ends with how long ago that was ("2 hours ago"), entries without an item link included. Those get a small tooltip with their text and time.
- Test-mode entries are never saved.
- Merging (gold grouped, repeats counted) only happens with entries from the current session, never into a restored one.
- "Clear history" in `/sui` → Loot empties the saved feed and the feed on screen, after a confirmation.

## Non-goals

- A separate history window, encounter grouping, or opening Blizzard's Loot Rolls window.
- Account-wide history (it's per character).
- Rebuilding roll results from `C_LootHistory` after a reload. The saved feed already carries them.
- Fixing the existing field writes in `roll.lua` (`frame.skinned`, `frame.InfoFrame`, `button.Text`, …). Logged as a followup; new code doesn't add more.

## Constraints

- **Taint (`.agents/taint.md`).** The roll frames and their buttons are Blizzard's. New code writes no fields onto them and keeps its own pieces (count font strings, the bar's matched drop) in tables of its own, keyed by the Blizzard frame. Post-hooks only. Nothing here is protected or combat-blocked, but it must not error in combat.
- **Saved data.**
  - Store it in the AceDB char namespace (`st.config.char`, from `SaftUI-Core/Config/config.lua`), under one key owned by the loot module.
  - Only plain data: strings, numbers, booleans and tables of them. No frames, functions or colour objects.
  - Never a secret value (`issecretvalue`): the feed already skips secret chat messages, and roll data gets the same check.
  - Keep each saved entry small. 500 entries with roll lists for a full raid is the worst case, so store only what the tooltip and the feed line need.
- **Freshness.** Feed freshness uses `GetTime()`, which doesn't carry across sessions. Restored entries have to be marked not fresh. `time()` is only for the "ago" text.
- **Both clients.** `C_LootHistory` and the roll frames exist on Forever and retail. Forever first: the user plays it. Check each API on Forever's docs before relying on it.
- Existing behaviour stays as is:
  - feed filters
  - scrolling
  - the test entries' tagging and removal
  - roll bar layout options and the roll mover
- Comments in plain language that say why, in the file's tone.

## Settled after the builder check (my calls, 2026-11-08)

- **Which drops get a roll result:** a drop that ended (`winner` or `allPassed`) and that someone actually rolled on, meaning at least one `rollInfos` entry has a state other than NoRoll. That excludes master-looted, personal-loot and auto-assigned drops. It doesn't matter whether this client showed a roll bar for it: a drop you were ineligible for still records who won.
- **No duplicates, no replays.**
  - Keep a saved set of recorded drops next to the saved feed, keyed by `encounterID`, `lootListKey` and `itemHyperlink`.
  - Record a result only if its key isn't in the set.
  - At login and after a reload, drop keys that are no longer in `C_LootHistory`, so keys can't collide once Blizzard's history moves on. On `LOOT_HISTORY_CLEAR_HISTORY`, empty the set.
  - Any drop that has ended and isn't recorded yet when the addon loads (say, a roll that ended during a reload) is added then:
    - as a restored entry, not a fresh one
    - with its real time estimated as `time() - (C_LootHistory.GetLootHistoryTime() - drop.startTime)`
  - So a reload mid-roll loses nothing, and the first use after install adds what's in Blizzard's history without flashing it.
- **Folding and the filters.**
  - Folding works in either order:
    - If the winner's loot message is already in the feed when the roll ends, that entry becomes the roll result where it stands.
    - If the roll ends first, the loot message that follows is absorbed.
  - Either way it's one entry, marked as looted, with the loot message's count and `notSelf`.
  - The entry's type is `Rolls`. It shows if the Rolls filter is on, or if it was looted and the ordinary Loot rules would show that loot (the Loot filter on, and Self Only allowing it). So turning Rolls off never hides an item you looted.
- **Same player.**
  - The self-loot messages (no name) match a winner with `isSelf`.
  - Other players match by name with the realm stripped on both sides (`Ambiguate(name, 'short')`).
  - A secret name or link never folds.
  - Stacks (`…MULTIPLE` messages) fold too, keeping the count.
- **Timestamps.**
  - A merge into a current-session entry moves its real time to the latest gain, as `time` does today.
  - Only the restore itself mustn't make an entry fresh. Hovering or scrolling a restored entry behaves like any entry today. The real time doesn't change on hover or scroll, only on a merge.
- **Test mode.** The feed's test mode (`Feed/test.lua`) adds a sample roll result with sample rolls, tagged `test` so it's never saved. That way the roll tooltip in the feed can be checked without a group.
- **Hover target on the roll bar.** Blizzard's roll frame has no OnEnter; its icon frame shows the item tooltip. The roll lines go into the item tooltip wherever the bar shows one, and SaftUI's own info frame (the bar's body) shows the same tooltip. Names show as the game gives them.

## Left to the builder

- Where the count sits on a roll button, and its font and colour (readable next to the button's letter at the default 30px height).
- The exact tooltip layout. Follow Blizzard's LootHistory tooltip content above.
- The time window for folding the winner's loot message into a roll result.
- The saved table's shape and key name. File structure (new files in `SaftUI-Loot/` are fine; add them to `SaftUI-Loot.toc`).
- Docs:
  - `README.md` Usage gets the roll info, roll results and saved feed.
  - `.agents/` docs only if a new rule or pattern needs recording, for example the saved-data rules if they generalise.
  - The followup for the existing `roll.lua` field writes.
