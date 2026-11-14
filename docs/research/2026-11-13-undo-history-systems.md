# Undo/redo history: how well-regarded tools define "one step" and show history

Research for the SaftUI edit mode history design. Several vendor pages returned HTTP 403 (Adobe help, Blender manual, Unity's old docs URL). Where I could not read the primary page, the item is marked **[secondary]** (third-party or search snippet), **[memory]** (my recollection, not re-verified) or **[inference]**. Nothing below is padded; gaps are stated.

## 0. Short answer to the owner's worry

Yes, in a naive design 16 nudges become 16 entries. Tools that do well avoid this with one of two mechanisms, and the best use both:

1. **Interaction boundaries.** A drag is one step from mouse-down to mouse-up. Unity says "mouse down events split undo groups" and records are flushed "right after mouse-up". Liveblocks documents the same pattern for Figma-style editors: pause history on pointer-down, resume on pointer-up.
2. **Merge keys.** The new command may merge into the top of the stack only if it has the same kind of command on the same target, with no other action in between. Optionally it also needs to be within a time window. Qt, ProseMirror and CodeMirror all work this way.

Tools that rely on neither, such as Photoshop and Blender, are the ones where users complain about flooded history. See section 7.

---

## 1. Coalescing rules in practice

| Tool | Rule | Values | Source |
|---|---|---|---|
| **Qt `QUndoStack`** | Merge when the new command's `id()` equals the top command's `id()` and is not -1, and `mergeWith()` returns true. The merge hook is where the command decides whether the *target* is the same. The merged command must behave exactly like both originals together. | No time component. Default `mergeWith()` returns false, so merging is opt-in per command type. | [QUndoCommand](https://doc.qt.io/qt-6/qundocommand.html), [QUndoStack](https://doc.qt.io/qt-6/qundostack.html) |
| **CodeMirror 6 history** | Join the previous undo event only if (a) the edit kind is typing or deleting (`/^(input\.type\|delete)($\|\.)/`), (b) the time gap is under `newGroupDelay`, and (c) the changes are adjacent (touch the previous event's changed ranges). IME composition always joins. `isolateHistory` (`"before"`, `"after"`, `"full"`) forces a boundary. | `newGroupDelay` = **500 ms**, `minDepth` = **100** | [source: history.ts](https://raw.githubusercontent.com/codemirror/commands/main/src/history.ts), read directly |
| **ProseMirror history** | A step starts a new group if there is no previous one, or if more than `newGroupDelay` has passed, or if the change is not adjacent to the previous group's ranges. Its docs add: "when changes aren't adjacent, a new group is always started". `closeHistory(tr)` forces a boundary. | `newGroupDelay` = **500 ms**, `depth` = **100** | [source: history.ts](https://raw.githubusercontent.com/ProseMirror/prosemirror-history/master/src/history.ts), read directly |
| **VS Code / Monaco** | No time gap in the edit stack. An edit appends to the last element if it is still open for that model. A boundary exists only when `pushStackElement()` is called (closes the element) or when a caller supplies a different `group`. The cursor layer tracks the previous edit type (typing, deleting left, deleting right, other) and sets "push stack element before/after" flags. The actual type-to-boundary mapping lives in `cursorTypeOperations.ts`, which I did not read. From memory [memory], a boundary comes from switching edit type (typing to delete) and from word or whitespace boundaries, not from a timer. | No timer in `editStack.ts` | [editStack.ts](https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/editor/common/model/editStack.ts), [cursor.ts](https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/editor/common/cursor/cursor.ts), read directly |
| **Emacs** | Consecutive self-insert commands are grouped into one record. Any non-undo command breaks the sequence. | The manual says "usually grouped". I recall a 20-character cap [memory]. | [Emacs manual, Undo](https://www.gnu.org/software/emacs/manual/html_node/emacs/Undo.html) |
| **Vim** | One undo block is one *typed command*, however many changes it makes. `:undojoin` merges into the previous block. `CTRL-G u` in Insert mode starts a new block. | None | [undo.txt](https://vimhelp.org/undo.txt.html) |
| **Krita (Cumulative Undo)** | Time-based merging of paint strokes. Never merges strokes that differ in colour, brush preset or blend mode. Settings: wait before merging (minimum age), exclude last N strokes from merge, max interval between strokes in a group, max group duration. | The page gives setting names but no default values. | [Krita undo history docker](https://docs.krita.org/en/reference_manual/dockers/undo_history.html) |
| **Unity Editor** | Groups by an integer group index. "Undo operations automatically combine together based on events. For example, mouse down events split undo groups." `Undo.RecordObject` records changes since the call, and the record is flushed "right after mouse-up and certain other events". Manual control: `IncrementCurrentGroup`, `CollapseUndoOperations(groupIndex)`, `SetCurrentGroupName`. | None | [Unity Undo](https://docs.unity.com/en-us/engine/current/script-reference/unityeditor/undo) |
| **Unreal Editor** | Scoped transactions that nest. The developer notes in forum threads are that stacked transactions fold into one undo. Slider drags are wrapped in a transaction opened at drag start and closed at drag end. Nothing in official docs confirmed the exact slider mechanism. | None | [forum: transactions can be stacked](https://forums.unrealengine.com/t/slate-and-transactions-for-undo-redo-system/112591), [forum: slider transaction](https://forums.unrealengine.com/t/sequencer-stuck-undo-buffer-when-using-autokey-cant-undo-while-setkey-value-is-in-progress/2582934) **[secondary]** |
| **Figma** | Per-user undo stacks. Plugin API calls can be grouped by `figma.commitUndo()`. Drags are one step (consistent with the pointer-down to pointer-up pattern). I found no official statement on whether repeated arrow-key nudges collapse. | None | [Figma widget undo docs](https://developers.figma.com/docs/widgets/undo-redo), [Liveblocks on multiplayer undo](https://liveblocks.io/blog/how-to-build-undo-redo-in-a-multiplayer-environment) **[secondary]** for drag grouping |
| **Photoshop** | No coalescing documented. Each operation is a state. I could not confirm how arrow-key nudges are recorded, only that the panel is a flat list of states. | n/a | [secondary]: see section 3 |
| **Blender** | Each operator is a step. The "Adjust Last Operation" panel re-runs the last operator with new parameters in place instead of adding steps. I could not load the manual page to confirm wording. | n/a | [memory], not verified |
| **Google Docs / Sheets** | Nothing documented on grouping rules. Not covered. | n/a | n/a |

### Patterns, summarized

- **By time gap.** Text editors only: 500 ms (CodeMirror and ProseMirror, both defaults). Krita uses user-configurable seconds. Note that CodeMirror and ProseMirror require adjacency *and* a time gap together. A timer alone is never the rule.
- **By "same command id and same target".** Qt's `id()` plus `mergeWith()`. This is the cleanest fit for "nudge Player frame" repeats.
- **By interaction.** Unity, Figma and Liveblocks use mouse-down to mouse-up. Vim uses one typed command.
- **Until the target or kind changes.** CodeMirror and ProseMirror's adjacency, Krita's "different colour, preset or blend mode", Qt's id mismatch and VS Code's edit-type change are all versions of this.
- **Until another action intervenes.** Implicit in Qt: merging is only with the top of the stack, so any other push breaks the run.
- **Explicit stops.** ProseMirror `closeHistory`, CodeMirror `isolateHistory`, VS Code `pushStackElement`, Vim `CTRL-G u`.

I found no documented tool that merges *key-repeat* nudges with a specific interval. [inference] The text-editor 500 ms window is the closest analogue and a sensible starting point for key nudges.

## 2. Labelling a merged step

What the sources show:

- Qt's `QUndoCommand` carries a text label, and `QUndoView` lists them. The merge hook is also the place to update the label. The docs say nothing about showing counts. [inference] A count label such as "(16 steps)" is something you would build yourself.
- Unity: the name comes from "a hardcoded ordering of the different kinds of actions" in the group unless `SetCurrentGroupName` is used. Grouped operations "appear and work as a single undo". (Source: Unity Undo page above.)
- VS Code labels every edit stack element the same ("Typing"), so there is effectively no merged-step label. (editStack.ts.)
- GIMP's Undo History dialog lists actions each with a **small thumbnail sketch of the change**, supports clicking a row to revert to that point, and has a search field. ([GIMP docs](https://docs.gimp.org/3.0/en/gimp-undo-dialog.html))
- Photoshop and Krita show a flat vertical list; Photoshop has snapshots at the top ([secondary](https://www.tipsquirrel.com/using-non-linear-history-in-photoshop/)). I could not confirm timestamps or icons in either from primary sources.
- Vim's `:undolist` shows change number, count of changes, time, and "saved" marker. The "saved" marker is the clean-state idea, same as Qt `setClean()`.

I found no doc that specifies "Move X (16 steps)" wording. That form is [inference] from Qt's design of letting `mergeWith` update the command, not from a cited example. The common practice among the tools I could read is a **verb plus target, with the net effect or final value**, not a count.

## 3. History limits

| Tool | Limit | Drop policy | Source |
|---|---|---|---|
| Qt | `undoLimit` default **0 = unlimited**. Count-based. A macro counts as one. Settable only on an empty stack. | "Commands are deleted from the bottom of the stack" (oldest first) | [QUndoStack](https://doc.qt.io/qt-6/qundostack.html) |
| CodeMirror | `minDepth` **100** events | Oldest dropped | history.ts |
| ProseMirror | `depth` **100** events | Oldest discarded | history.ts |
| Emacs | **Byte-based**: `undo-limit` 160000, `undo-strong-limit` 240000, `undo-outer-limit` 24 MB | Strong limit forgets older commands | [Emacs manual](https://www.gnu.org/software/emacs/manual/html_node/emacs/Undo.html) |
| Vim | `'undolevels'` change count. Default not stated on the page I read. | Oldest become unreachable | [undo.txt](https://vimhelp.org/undo.txt.html) |
| GIMP | Undo levels in preferences, plus a memory setting. Defaults not stated in the page. | Not stated | GIMP docs |
| Photoshop | History States preference. Default **50** (earlier versions 20), reported max **1000**; more states hurt performance. | Oldest dropped; the original-document state and snapshots survive. | [secondary](https://jkost.com/blog/2021/02/working-with-undo-the-history-panel-history-and-art-history-brushes-in-photoshop.html), [secondary](https://www.thegraphicmac.com/working-with-history-states-in-photoshop) |
| Blender | "Undo Steps" plus "Undo Memory Limit" (MB, 0 = unlimited). Count and memory both. Old wiki: default 32, max 64 (outdated, treat as unverified). | Not stated | [Blender 3.6 System prefs](https://docs.blender.org/manual/en/3.6/editors/preferences/system.html) **[secondary]** |
| Krita | Not covered on the pages I read. | n/a | n/a |

Takeaways: count-based limits with oldest-first dropping are universal. Memory-based limits appear where snapshots are big (image editors, Emacs byte counts). [inference] For a layout editor whose steps are tiny settings deltas, a count limit alone is sufficient, and 100 matches the CodeMirror and ProseMirror defaults.

## 4. Selective revert of one older step

- **Photoshop non-linear history.** Off by default. With it off, deleting a state deletes it **and all later states**. With it on, "a changed state is appended to the bottom ... rather than erasing the later states", and deleting a state deletes only that one. Third-party tutorials call it "very memory intensive" and confusing. ([secondary](https://www.tipsquirrel.com/using-non-linear-history-in-photoshop/)) I could not retrieve Adobe's own wording or any conflict warning text.
- **Emacs selective undo.** With an active region, `undo` "undoes the most recent change within the region". Otherwise `C-u C-/`. It exists but is a specialist feature; redo is "undo of undo" (a non-undo command breaks the sequence, and the undos themselves become undoable). ([Emacs manual](https://www.gnu.org/software/emacs/manual/html_node/emacs/Undo.html))
- **Vim.** Does not revert one step in isolation. It keeps a **branching undo tree** where you move to any text state with `g-`, `g+`, `:earlier`, `:later`. Navigation, not selective removal. ([undo.txt](https://vimhelp.org/undo.txt.html))
- **Multiplayer tools (Figma, Google Slides, Liveblocks).** Each user undoes only their own inverse commands. When the target was changed or deleted by someone else, Figma and Google Slides **do nothing**; Pitch ends up in an invalid state. ([Liveblocks](https://liveblocks.io/blog/how-to-build-undo-redo-in-a-multiplayer-environment)) This is the best-documented example of a dependency conflict handled by "skip silently".
- **GIMP, Krita, Photoshop (default), Blender, Qt `QUndoView`.** Clicking a history row **jumps** to that state (undoing everything after it, which stays redoable until a new action). That is not selective revert. For GIMP: "Moving between states doesn't lose information or consume extra resources".
- **Why most avoid selective revert.** [inference, standard in the literature, not a quote from the pages I read] A later step may assume the earlier step's result (for example a "copy all settings" that depended on a prior value), so removing the older step makes the later one's recorded inverse wrong. Qt's own contract (`mergeWith` must equal doing both, undo in reverse order) assumes strict stack order.

I found no tool wording for a "this step conflicts with a later one" warning. The only documented outcomes are silent no-op (Figma, Slides), invalid state (Pitch), or appending rather than erasing (Photoshop non-linear).

## 5. Bulk or compound actions as one step

- **Qt:** `beginMacro(text)` / `endMacro()`, "all of which are undone and redone in one go". Nestable (each `beginMacro` needs a matching `endMacro`). The macro counts as one command toward `undoLimit`. While composing, the stack is disabled. Alternatively, child commands under a parent command. ([QUndoStack](https://doc.qt.io/qt-6/qundostack.html), [QUndoCommand](https://doc.qt.io/qt-6/qundocommand.html))
- **Unity:** group index with a settable group name; `CollapseUndoOperations` collapses everything down to a group index into one step.
- **Unreal:** nested scoped transactions fold into the outer one ([secondary]).
- **Vim:** one typed command is one block regardless of how many changes. `:undojoin` merges explicitly.
- **VS Code:** `executeCommands` disables both "push stack element" flags so a caller's batch is not split.
- **Figma plugins:** `figma.commitUndo()` groups a set of actions. A forum report notes that a plugin making several calls from one button press otherwise created several entries ([secondary](https://forum.figma.com/archive-21/enable-a-single-undo-for-multiple-operations-31082)).

Common rule: the **initiating user gesture** (one click, one drop, one command) is one step, labelled by that gesture.

## 6. Persistence

- **Qt:** the stack has a "clean state" index for the saved point. `cleanIndex()` becomes -1 if it can no longer be reached (for example undo, then push a new command). History is in-memory; Qt does not persist it.
- **Vim:** `:earlier {N}f` / `:later` navigate by file writes, and `:undolist` shows a "saved" marker. Persistent undo files exist via `'undofile'` [memory], not on the page I read.
- **GIMP:** only manual clearing documented ("Clear Undo History", with confirmation). Not documented elsewhere.
- **Photoshop:** history is session-only and, as I recall, clears on closing the document [memory]. Snapshots do not survive either. I could not confirm this from Adobe's page.
- I found no documentation of any editor persisting history across reloads by default. [inference] For a game addon that reloads the UI (`/reload`) the cheap and common choice is to clear on reload.

## 7. What goes wrong (documented or reported)

- **Flooding by tiny edits.** The Figma forum asks for undo of "changes not clicks or selections"; the plugin-grouping report above is the same class. Photoshop panels fill with states and users raise the limit up to 1000 at a performance cost ([secondary](https://www.thegraphicmac.com/working-with-history-states-in-photoshop)). Slider callbacks fire "lots of times" in Unreal's details panel (forum, [secondary](https://forums.unrealengine.com/t/how-to-avoid-invoking-property-update-callback-function-when-a-property-is-changed-in-the-editor-until-the-slider-is-released/411415)).
- **Stuck or corrupt undo buffer when a long interaction is not closed properly.** Unreal Sequencer threads ("Can't Undo while 'SetKey Value' is in progress"). [Lesson, inference: always close a pending step when the interaction ends or the mode exits, including on errors.]
- **Surprising merges.** Qt requires the merged result to be exactly equal to both applied, and Krita explicitly refuses to merge strokes of different colour, preset or blend mode. Both show that over-eager merging is a known risk: merge only when kind and target match.
- **Redo lost after a new edit.** Qt: pushing after undo "deletes the undone commands above the current index". Vim keeps them as a branch. Emacs keeps them as undo-of-undo. Photoshop's non-linear option exists because of this. ([QUndoStack](https://doc.qt.io/qt-6/qundostack.html))
- **Undo of something off screen.** Figma restores the previously selected page when you undo a navigation, to keep context consistent. Liveblocks notes selection, page and zoom can be part of history. ([Liveblocks](https://liveblocks.io/blog/how-to-build-undo-redo-in-a-multiplayer-environment))
- **Undoing someone else's work / a deleted target.** See section 4.

---

## Recommendation for the SaftUI edit mode

This is a proposal; each rule says which source supports it and which parts are my inference.

### What is one step

1. **A drag** is one step, from mouse-down to mouse-up. The recorded step is the original position and the final position. Intermediate positions are not recorded. *(Unity mouse-down/mouse-up grouping; Liveblocks pause/resume.)* If the frame ends up where it started, record nothing.
2. **Arrow-key nudges.** Merge consecutive nudges into the top step when all of these hold: same frame, same kind ("move"), no other action pushed since, and the gap since the last nudge is at most about **1 s** (my number, [inference]; the documented 500 ms from ProseMirror and CodeMirror suits typing cadence, and nudging is slower. Make it a single constant and tune it in game). Any of these closes the run: selecting a different frame, a different kind of action, leaving edit mode, or an explicit close. The merged step stores the *original* position (before the first nudge) and the *latest* position, so one undo puts the frame back where it was before the run. *(Qt `id()` + `mergeWith`; CodeMirror and ProseMirror time plus adjacency; Krita "do not merge when properties differ".)* Optional: a cap on run duration like Krita's "max group duration" [Krita], so a long fiddling session still yields more than one step. I would skip that at first.
3. **A reset** is its own step, never merged, labelled with the frame and what was reset. It stores the previous values. It closes any open nudge or typing run. *(Qt id mismatch breaks merging; Vim/Emacs: another command ends the group.)*
4. **A value typed or slider dragged in the options window.** One step per interaction: for a slider, mouse-down to mouse-up; for a typed number, commit (Enter or focus loss) is one step. Several commits to the same option on the same frame within the merge window may merge (same rule as nudges). The step stores the value before the interaction and the final value. Do not record intermediate slider values; this is the Unreal/Unity slider lesson. Make sure the step is closed if the options window closes mid-drag (Unreal stuck-buffer reports).
5. **Toggles and dropdown picks.** One step each, never merged, because the user made a discrete choice. Exception [inference]: toggling the same checkbox twice in a row on the same option could be left as two steps; it is rare and merging would be surprising (Krita's lesson on surprising merges).
6. **A bulk copy** ("copy all of this unit frame's settings from another") is one compound step, like a Qt macro or Unity group, labelled with the source and target. It stores the full set of previous values it changed. *(Qt `beginMacro`/`endMacro`; Unity group name.)* Nested compounds are allowed but unlikely to be needed; the macro rule "counts as one toward the limit" applies.

### What the list shows per step

- **Label:** verb + target + net result, for example "Move Player frame (12, -4) to (28, -4)" or "Player: scale 1.0 to 1.2" or "Copy Party settings from Raid". Show the *net* delta or final value, not a count; if you want a hint, add "x16" for merged runs, but treat that as optional [inference]. *(GIMP lists each row with a thumbnail of the change; Unity names groups; Qt lets the command own its text.)*
- **Per row:** a small icon for the kind (move, reset, setting, bulk) so a long list is scannable [inference, GIMP's thumbnails are the nearest analogue]. A relative time ("12 s ago") is optional and low priority [inference]; Vim's `:undolist` is the nearest documented example showing time.
- **Current position marker** and greyed-out redo entries below it. Clicking a row jumps to that state (undo or redo as many steps as needed), as in GIMP, Krita and Qt `QUndoView`.
- A "saved/clean" marker is not needed unless profile saving becomes explicit (Qt `setClean`).

### Limit

- **100 steps, count-based, oldest dropped first.** *(CodeMirror `minDepth` 100, ProseMirror `depth` 100; Qt drops from the bottom.)* Steps are small, so no memory-based limit is needed [inference]. Bulk steps hold more data; keep an eye on them but do not special-case yet.
- Pushing a new action after undoing discards the redo steps (Qt, ProseMirror). That is the simple, expected behaviour. Do not build a branching tree: the Photoshop non-linear history is described as memory-heavy and confusing, and the Vim tree needs dedicated UI.

### Persistence

- Keep history in memory for the edit mode session. Clear it on `/reload` and on leaving edit mode, or at least on reload [inference; no tool documents cross-session persistence by default]. Because merging runs are closed on leaving edit mode, nothing is left half-open.

### Reverting a single older step

- **Primary behaviour: click a row to jump to that state** (undo everything after it, kept redoable). This is what every tool with a visible history list does (GIMP, Krita, Qt).
- **Do not offer true "remove just this step" in the first version.** Reasons: every documented selective-undo case has conflict problems (Figma and Slides silently do nothing; Pitch goes invalid; Photoshop's version is memory-heavy and confusing), and it is easy to build wrongly when a later step touched the same frame or setting.
- If you later want it, a safe narrow form [inference]: allow reverting a step only if **no later step touches the same frame and setting**. Otherwise disable the row's action with a reason, for example "Changed again later: undo back to here instead". This follows the Figma/Slides "refuse rather than corrupt" outcome but with an explanation. I found no documented wording to cite for the message.
- A bulk step reverted selectively would need the same check across every setting it touched, so leave it out entirely.

### Things to implement defensively (from the failure reports)

- Always close any pending merge run on: selection change, mode exit, options window close, a different action kind, and errors.
- A step that results in no net change should not be recorded.
- Make undo of a step whose target frame is hidden or off screen select that frame, or at least report which frame changed, so the user sees what happened (Figma restores the page on navigation undo).
- Make the merge constant a single named value so it can be tuned in game.

## Sources not retrievable or weakly sourced (be careful relying on these)

- Adobe's History panel help page, the Blender undo manual page and Unity's old docs URL returned 403. Photoshop and Blender numbers come from third-party pages and a search snippet.
- Figma: no official statement found about arrow-key nudge grouping.
- Unreal: slider-drag coalescing mechanism inferred from forum posts only.
- Krita setting defaults, Google Docs/Sheets grouping, GIMP undo-level defaults and VS Code's exact type-to-boundary mapping were not established.
- Any claim marked [memory] or [inference] above was not checked against a source in this session.

## Source index

- Qt: https://doc.qt.io/qt-6/qundocommand.html , https://doc.qt.io/qt-6/qundostack.html
- CodeMirror history source: https://raw.githubusercontent.com/codemirror/commands/main/src/history.ts
- ProseMirror history source: https://raw.githubusercontent.com/ProseMirror/prosemirror-history/master/src/history.ts
- VS Code: https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/editor/common/model/editStack.ts , https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/editor/common/cursor/cursor.ts
- Unity: https://docs.unity.com/en-us/engine/current/script-reference/unityeditor/undo
- Krita: https://docs.krita.org/en/reference_manual/dockers/undo_history.html
- GIMP: https://docs.gimp.org/3.0/en/gimp-undo-dialog.html
- Emacs: https://www.gnu.org/software/emacs/manual/html_node/emacs/Undo.html
- Vim: https://vimhelp.org/undo.txt.html
- Figma widgets: https://developers.figma.com/docs/widgets/undo-redo
- Liveblocks: https://liveblocks.io/blog/how-to-build-undo-redo-in-a-multiplayer-environment
- Photoshop (secondary): https://www.tipsquirrel.com/using-non-linear-history-in-photoshop/ , https://jkost.com/blog/2021/02/working-with-undo-the-history-panel-history-and-art-history-brushes-in-photoshop.html , https://www.thegraphicmac.com/working-with-history-states-in-photoshop
- Blender (secondary): https://docs.blender.org/manual/en/3.6/editors/preferences/system.html
- Unreal (forums): https://forums.unrealengine.com/t/slate-and-transactions-for-undo-redo-system/112591 , https://forums.unrealengine.com/t/sequencer-stuck-undo-buffer-when-using-autokey-cant-undo-while-setkey-value-is-in-progress/2582934 , https://forums.unrealengine.com/t/how-to-avoid-invoking-property-update-callback-function-when-a-property-is-changed-in-the-editor-until-the-slider-is-released/411415
- Figma forum: https://forum.figma.com/archive-21/enable-a-single-undo-for-multiple-operations-31082
