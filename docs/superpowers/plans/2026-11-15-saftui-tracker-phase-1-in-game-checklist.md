# SaftUI's tracker, Phase 1: the in-game checklist

The one list to run before the switch turns on. Everything SaftUI's own objective tracker (`SaftUI-Tracker`) can't prove on stubs is here, in the order a player does it. It folds in every task's checks (Tasks 1 to 12), the experiments P1 to P7 (`docs/superpowers/specs/2026-11-14-saftui-objective-tracker-design.md`, "Experiments to run before the build"; the plan's "Experiment seams") and the spec's G1 to G12 ("What only the game can confirm").

The tracker shipped **off** (`tracker.enable = false`) until these passed; it is now on by default (2026-11-15, see "Results so far" at the end). The text below is the list as it was run.

**Marks.** `[F]` is WoW Forever (interface 16001, the client you play), `[R]` is retail (Midnight, 120000), `[F+R]` is both. Check Forever first, then retail. A step with no mark is for both clients.

**What to paste back.** For an experiment, the lines it prints and any "blocked" lines in the taint log. For a check that fails, which step, the client, and what you saw. Nothing needs an account, realm or character name: leave them out of anything you paste.

---

## Part 0. Set up once per client

1. Link the addon into the client's AddOns folder with a Windows directory link (`mklink /D`, not WSL `ln -s`; see the README's Installation), the same way as the other `SaftUI-*` folders: `SaftUI-Tracker` into `_forever_` and into `_retail_`. `SaftUI-Misc` and `SaftUI-Core` are already there; `SaftUI-Tracker` lists `SaftUI-Misc` as an optional dependency, so enable it on the character select screen.
2. Have BugSack (or BugGrabber) running so a Lua error is kept. Every check below ends with "no Lua errors".
3. **Taint log.** Where a step says *taint log*, do this: `/console taintLog 1`, then `/reload` (the setting applies after a reload), do the steps, then `/reload` again. The log is `Logs/taint.log` under the client's folder (`_forever_` or `_retail_`). What you look for is any line that says `blocked`, any `ADDON_ACTION_BLOCKED` or `ADDON_ACTION_FORBIDDEN` naming SaftUI, and any line naming SaftUI that mentions `ObjectiveTracker`, `dirty`, `charges`, `isDirty`, `isCollapsed` or `OnClick`. A clean log has none. `/console taintLog 0` turns it off after.
4. A quest with a quest item you can use, and a second one if you have it (one with charges is a bonus). Several quests in two or three zones, one of them where you are standing. A group, for the Share check, if you have one.

---

## Part 1. With the switch off: nothing changes (Task 1, Task 2, Task 6)

The switch is off. Reload and check on `[F+R]`:

1. No Lua errors. `/sui` has **Tracker** under Info, and its General tab has the switch "SaftUI's tracker", off. No other tab is usable while it is off.
2. Blizzard's tracker, its skin and its mover in `/sui edit` behave as before. The skin's page now reads **Blizzard's tracker** (it was "Objective tracker"; Task 6's rename).
3. Key Bindings → **SaftUI** (its own section, not under AddOns) lists "Use the nearest quest item" (Task 1).
4. **The colors moved (Task 2, G11).** Global Settings → Colors → Objectives has Completed and Failed. If you had custom Completed or Failed colors on the old skin page, they are there now, and Blizzard's tracker's lines keep them. Change a swatch: Blizzard's tracker's lines recolor at once; its reset icon returns the default; no blocked-action message in combat. The skin's page has no color section any more, only a line pointing to Colors → Objectives; Font, Header font and Position are as before. With the skin off or under the Blizzard theme, Blizzard's own colors, as before.
5. With the switch off, tick it and answer **No** to the reload question: nothing changes, and a later theme change doesn't ask again. (Untick it afterwards if you want it off for the experiments.)

---

## Part 2. Experiments P1 to P5 (switch off, today's skin and mover on)

Run these before turning the switch on. Taint log on (Part 0, step 3), and `/reload` before each experiment and after it: a test can taint the session. Each experiment decides one thing, and each thing is behind **one function**, so a failure changes one function and its tests. P1 to P5 are for `[F]` first; run them on `[R]` too where the step is possible there.

### P1. The baseline: a quest item used in combat with today's skin `[F+R]`

Everything else assumes this passes.

1. Track a quest with an item. In combat, use the item from Blizzard's tracker.
2. `/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"isDirty"))`

*Passes:* the item is used, the line prints `true true`, no "blocked" line in the taint log. *Fails:* stop. The skin's hooks already taint, and the handover would show a tainted tracker. Paste the log first; nothing else is worth running.

### P2. Concealing Blizzard's tracker the way this design does `[F+R]`

Seam on failure: **`TR:PlaceBlizzard(where)`** in `SaftUI-Tracker/blizzard.lua`; only its `'concealed'` branch changes (to the C `SetAlpha(0)` plus `EnableMouse(false)` of `.agents/taint.md` rule 8, or whatever the log points to), with `tests/tracker/conceal_test.lua`'s spot cases.

1. Track a quest with an item, near where it can be used.
2. Conceal it, C methods only, as SaftUI will:
   `/run local f=ObjectiveTrackerFrame local m=getmetatable(f).__index local p,r,rp,x,y=f:GetPoint(1) m.SetClampedToScreen(f,false) m.ClearAllPoints(f) m.SetPoint(f,p,r,rp,x-3000,y) print("concealed",p,x,y)`
   The tracker leaves the screen. (Today's mover puts it back the next time Blizzard re-places it, such as when a quest updates; if it comes back, paste the line again.)
3. Make quest progress while it is concealed (kill a quest mob), in and out of combat.
4. `/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"isDirty"))`
5. Bring it back: `/run local f=ObjectiveTrackerFrame getmetatable(f).__index.SetClampedToScreen(f,true) SaftUI:GetModule("ObjectiveTracker"):PlaceTracker()`
6. In combat, use the quest item from Blizzard's tracker.

*Passes:* step 4 prints `true true`, the item works in step 6, no "blocked" line. Concealment is then safe as designed. *Fails:* paste the taint log; the concealment changes before the switch turns on.

### P3. A SaftUI secure item button, made before combat `[F+R]`

Seam on failure: **`TR.ItemAttributes(item)`** in `SaftUI-Tracker/items.lua`. It returns `{ type = 'macro', macrotext = '/use item:' .. id }` (id from the link), for every item or for the kinds P3 names. Nothing else changes: every row, column and nearest button sets its attributes through `TR:SetButtonItem`.

1. Track a quest with an item. Make a blue square in the middle of the screen that uses it:
   `/run local link for n=1,C_QuestLog.GetNumQuestWatches() do local q=C_QuestLog.GetQuestIDForQuestWatchIndex(n) local i=q and C_QuestLog.GetLogIndexForQuestID(q) if i and GetQuestLogSpecialItemInfo(i) then link=GetQuestLogSpecialItemInfo(i) break end end local b=SUIXQ or CreateFrame("Button","SUIXQ",UIParent,"SecureActionButtonTemplate") b:SetSize(40,40) b:SetPoint("CENTER") b:RegisterForClicks("AnyUp","AnyDown") b:SetAttribute("type","item") b:SetAttribute("item",link) local t=b.t or b:CreateTexture(nil,"ARTWORK") b.t=t t:SetAllPoints() t:SetColorTexture(0,0.6,1,0.6) print("item:",link)`
2. Give it a key: `/run SetOverrideBindingClick(SUIXQ,true,"CTRL-F12","SUIXQ")`
3. In combat, click the square, then press Ctrl-F12.
4. If you have a second quest with an item, repeat with it, and with an item that has charges.
5. Run step 3 with `/console ActionButtonUseKeyDown 1` and again with `0` (as section E, step 4, does).

The button registers for **both** halves of a click (`"AnyUp","AnyDown"`), as SaftUI's own secure buttons do: an addon's secure action button is never given `isKeyPress` or `isSecureAction`, so with `ActionButtonUseKeyDown` on (its default) it acts on the press and, registered for `AnyUp` alone, it would never act on a mouse click at all (`.agents/taint.md` rule 15), while the Ctrl-F12 binding, which delivers the press, would work.

*Passes:* the item is used both ways, in combat, with no error, once per click with the setting on and off. *Fails:* note the error text. **If the click does nothing but the key works, the button's registration is wrong, not its type: check `RegisterForClicks` before touching `TR.ItemAttributes`.** A quest item a secure `item` button can't use (one not in your bags, or an equippable one, which is equipped rather than used) changes the button's type to `macro` with `/use`.

### P4. What Forever has: sections and quest data `[F]` (then `[R]` if you want its answers too)

Seams on failure:
- **`TR.SectionHandsOver(key)`** in `SaftUI-Tracker/probes.lua`: a section P4 finds always filled on Forever (in the open world) returns `not st.forever` for it.
- **`TR.ChooseNearest(candidates, focusedID)`** in `SaftUI-Tracker/nearest.lua`: where distance or the quest area don't answer on Forever, its steps 1 and 3 are skipped on Forever, leaving focus, then the game's order.

Paste each line in the open world with quests tracked, then again inside a dungeon, a battleground, and with an achievement and a recipe tracked if Forever has those.

- `/run for _,m in ipairs(ObjectiveTrackerFrame.modules or {}) do print(m:GetName() or "?",m.state,m.hasContents and "content" or "-") end`
- `/run local n,s,t=C_Scenario.GetInfo() print("scenario",n,s,t,"widgets",ObjectiveTrackerUIWidgetContainer and ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing(),"popups",GetNumAutoQuestPopUps(),"tasks",#GetTasksTable(),"wq",C_QuestLog.GetNumWorldQuestWatches())`
- `/run for n=1,C_QuestLog.GetNumQuestWatches() do local q=C_QuestLog.GetQuestIDForQuestWatchIndex(n) local h=C_QuestLog.GetHeaderIndexForQuest(q) local d=C_QuestLog.GetDistanceSqToQuest(q) local g=C_QuestLog.GetQuestTagInfo(q) print(q,h and C_QuestLog.GetInfo(h).title,d and floor(sqrt(d)),g and g.tagName,C_Minimap.IsInsideQuestBlob(q)) end print("zone",GetRealZoneText())`

*Decides:*
- Which sections hand over on Forever. If a section is "content" all the time in the open world (an always-filled one), `TR.SectionHandsOver` returns false for it on Forever. If a dungeon's scenario line shows stages above 0, every Forever dungeon hands over in version one, and Phase 3 moves up (the followups).
- That the quest log's headers are zone names matching `GetRealZoneText()` (zone grouping and "current zone first").
- That distance and the quest area answer on Forever (else the nearest button falls back to the game's order).

### P5. Opening the map and other Blizzard UI from addon code `[F+R]`

Seams on failure (one function each): **`TR.ShowOnMapAllowed()`**, **`TR.QuestDetailsAllowed()`** and **`TR.AbandonAllowed()`** in `SaftUI-Tracker/clicks.lua`. The failed one's constant (`TR.SHOW_ON_MAP`, `TR.QUEST_DETAILS`, `TR.ABANDON`) becomes `false`.

1. Out of combat: `/run QuestMapFrame_OpenToQuestDetails(C_QuestLog.GetQuestIDForQuestWatchIndex(1))`. The map opens on the quest. Close it.
2. Start a fight. Open the map with M; click a quest in its list; click a quest's pin on the map; Shift-click a quest in its list to stop and start tracking it.
3. After the fight, `/reload` and read the taint log.

*Passes:* nothing blocked, no `SetPassThroughButtons` line. Left click's Show on map stays (out of combat only). *Fails:* SaftUI never opens the map; Left click is Focus only (a saved "show on map" reads as focus), the menu drops Show on map, and the hint reads "Click: focus.". Details and Abandon are covered the same way in Part 4's click checks: open each out of combat, close or cancel it, then in combat open the map, the bags and the spellbook and accept a summon, a resurrection or a queue pop, with the taint log on.

*(P6, watch changes, needs SaftUI's tracker, so it is in Part 4, section D.)*

---

## Part 3. Switch it on `[F+R]`

1. `/console taintLog 1`, then `/reload`.
2. `/sui` → Info → **Tracker** → General → tick **SaftUI's tracker**. It asks "SaftUI's tracker changes after a reload. Reload now?": answer Yes.
3. After the reload, only SaftUI's tracker shows; Blizzard's is off screen (concealed, not hidden). No Lua errors.
4. In `/sui edit` there is a **Tracker** outline and no Blizzard tracker mover (the skin's mover stands down; it shows only with Show disabled).
5. If another tracker addon is loaded, the switch is greyed with "Quests are tracked by <name>. Turn it off to use SaftUI's." and nothing builds. (Only if you have one.)
6. To go back at any time: untick it, reload, and the old behaviour returns.

---

## Part 4. With it on, in the order you would play

Taint log on for all of Part 4. Do the steps on `[F]`, then `[R]`.

### A. First look and the window (Task 4; G6, G10) `[F+R]`

1. An empty-looking window if you have no tracked quests ("No tracked quests." or hidden, by Hide when empty). It sits where you had moved the skin's tracker, else where you had moved Blizzard's tracker in Blizzard's Edit Mode (read from the Edit Mode layout, for any anchor point; a preset layout, an undragged tracker or one anchored to another frame than the screen gives Blizzard's usual spot), on a profile with no tracker position (the first position; a skin position saved from a non-top point is converted so the spot you saw is kept). A `/reload` leaves a saved position where it is.
2. `/sui edit`: a "Tracker" outline covers **Width by Max height** (260 by 560 to start). Drag it, `/reload`: it stays. Reset goes to Blizzard's default spot.
3. Width, Max height and Grow change the outline and the window at once; **Grow up** keeps the bottom edge put.
4. The header's chevron collapses the whole tracker to the header (40 tall); its tooltip says Collapse and Expand; it survives a reload. With **Header** off the header and its collapse go; **Count** off hides the count.
5. Theme and Background under **Thick, Thin, Blizzard and None** (None drops the panel; the header line stays), Solid and Transparent. Switch the global theme to Blizzard and back with the window open: the panel, line and chevron redraw.
6. The right column's frames (the durability figure, vehicle seats) against the tracker's header at the default spot (G12). Note any overlap.
7. Mouse over the header: tooltip "Objectives" with the counts line, and at the watch limit the second line ("12 of 40 quests in your quest log, 25 tracked: the most you can track" on Forever, where the log holds 40).

### B. The list (Task 3, Task 5; G6) `[F+R]`

1. Every tracked quest shows under its zone header. The **current zone first with the map pin**; campaigns next; then the log's header order; Other last. Compare the list, order, titles (level, tags, colors) with Blizzard's tracker (still readable by switching it on briefly in the skin's page, or from memory).
2. `[F]` P4's check lives here too: the headers are the zone names, and the current zone matches.
3. Collapse a zone with its chevron (tooltip Collapse/Expand), reload: it stays; the count stays. Collapse Other too.
4. Lines: objectives (a dash before each; a wrapped one hangs under its text), finished ones in the Completed color, a failed quest "Failed", a ready quest's completion line, money, a timed quest's "Time left" counting down (red under a minute), a progress bar with its percent, a waypoint line on the focused quest only.
5. Focus a quest from the map or Blizzard's list: the accent bar to the left of its row; the list scrolls it in view. Track a new quest: the list scrolls to it only if the mouse is off the tracker and you have not scrolled in the last few seconds.
6. Log out fully and back in: the list opens at the top or at the focused quest, not scrolled into the middle; titles that arrive late don't move it. Scroll to the bottom, turn in a quest, accept the follow-up at once: it scrolls into view.
7. Kill quest mobs fast (an AoE pack): no stutter, no flicker. After a quiet moment, one change shows at once. **Allocation (the followup "Tracker: a refresh allocates about 175 KB, measure it in game"; Ruling 36 says it is measured in game first):** with a full quest log, out of combat and then in a fight, run a few times `/run local m=collectgarbage('count') local t=debugprofilestop() SaftUI.Tracker:Refresh() print(debugprofilestop()-t, collectgarbage('count')-m)` and paste the milliseconds and KB, in and out of a fight, so the followup is resolved as accepted or its table reuse is done.
8. Hover a row: accent tint. Change Objectives on the Colors tab, and the Accent on Global settings → Theme: rows recolor at once (G11).
9. **Auto quest popups (G8)** `[F]` if Forever has any, `[R]` otherwise: accept an auto quest or finish one: a popup row above the zones, its label over its title with no overlap. Click it in and out of combat: the quest frame opens and the popup goes; no blocked-action message (P7, section D, step 11, with the taint log on). Right-click an item that begins a quest: its "Quest discovered" row appears at once. An auto-complete quest's "Click to complete" turns it in.
10. Collapse the whole tracker with a timed quest, expand: the timer counts again. With a popup showing, the header chevron does nothing and the window shows expanded.
11. Untrack everything: the window hides (Hide when empty) or shows "No tracked quests.".
12. Quests tab: every row live. **Show: Tracked and the current zone's** adds the zone's untracked quests; a zone change doesn't make the list jump. Spacing, Width and the Fonts tab reflow rows at once. Hide when empty on and off; Width 180 and 600; Spacing 0 and 20.
13. `[F]` Whether quests under a header you collapsed in the quest log are read in the "current zone's" mode (the model reads every entry; this is a check of that source reading).
14. Test under Thick, Thin and Blizzard: no Lua errors, no blocked actions.

### C. Blizzard's tracker is running unseen (Task 6; G2) `[F+R]`

1. Make quest progress, accept and turn in quests, change zones, enter and leave combat: no Lua errors, no `ADDON_ACTION_BLOCKED` or `ADDON_ACTION_FORBIDDEN` blaming SaftUI. SaftUI's list keeps updating. Accepted quests still auto-track and the watch list still re-sorts on a zone change (Blizzard's tracker is doing both, off screen).
2. `/reload` in combat: Blizzard's tracker is off screen at once and SaftUI's quests show at once.
3. Drag SaftUI's tracker, change Grow, switch profiles, reset the profile: Blizzard's tracker stays off screen; the skin's saved position is untouched; Blizzard's tracker page's Position reads disabled with its reason.
4. With a skin position saved from a non-top point (rare), SaftUI's window starts where Blizzard's tracker was.
5. **G2:** after an hour of questing, after a dungeon, and after a handover in combat (section H), run `/run print(issecurevariable(ObjectiveTrackerFrame,"dirty"),issecurevariable(QuestObjectiveTracker,"isDirty"),issecurevariable(ObjectiveTrackerFrame,"isCollapsed"))`. It must print `true true true`.
6. Open Blizzard's own Edit Mode: it can't select the objective tracker, and saving a layout doesn't move it.

### D. Clicks, the menu and tooltips (Task 7; P5, P6, G9) `[F+R]`

1. **P5 with SaftUI's own Show on map:** click a quest out of combat (Left click is Show on map by default), close the map, then in combat open the map, the quest log, the spellbook and the bags and act in them. No blocked action blamed on SaftUI. If it fails, set `TR.SHOW_ON_MAP = false` (Part 2, P5's seams).
2. The menu on a tracked and on an untracked (Show: current zone's) quest: Focus / Remove Focus, Open Quest Details / Close Quest Details (toggles the text), Open Quest Map, Untrack / Track Quest, Share Quest (only in a group, and enabled in combat), Abandon with its confirmation. The menu's strings read right on both clients (the stubs' English is from memory).
3. **Shift-click** stops tracking (not in the new player experience); with the chat box open it only inserts the link; a plain click with the chat box open opens the map. At the watch limit (25) the red error line says "You can't track any more quests."
4. **P6, watch changes (Seam: `TR.WatchChangeAllowed()` in `clicks.lua`).** `/console taintLog 1`: Shift-click to track and untrack, with the world map open too. Then in combat: open the map and use a quest item from Blizzard's revealed tracker (section H gives you one, or use Part 2's P1 with SaftUI on). *Passes:* no lasting taint, nothing blocked. *Fails:* `TR.WatchChangeAllowed()` returns `false` (no watch changes from SaftUI) and you decide the fallback, for example the quest log opened at the quest. If the game allows watch changes in combat and nothing taints, it can return `true`.
5. In combat: Left click focuses (no map); the menu shows details, map, Share and Abandon greyed with "Out of combat only"; Focus, Track/Stop tracking, Shift-click and the quest icon work, no blocked-action message. Confirm the game really allows focus, track and untrack calls in combat (this is the same as P6's second half).
6. **Abandon's confirm; Share in a group.**
7. Complete an auto-complete quest: a click opens the turn-in and the popup goes, in and out of combat (P7, step 11).
8. Tooltip: the quest link, the party's progress when grouped (the link is not cleared), a grey hint, anchored 8 left of the window; Tooltips off removes them; the quest icon has its own tooltip; moving between the icon and the row doesn't flicker. After a late tooltip update the hint is still there.
9. Left click setting: both values (Show on map, Focus); a reload keeps them. A zone header's click collapses; its right click does nothing.
10. Whether focusing an untracked zone quest also adds a watch.
11. **P7, popup and auto-complete clicks in combat (Seam: `TR.PopupClickAllowed()` in `clicks.lua`; the constant `TR.POPUP_CLICK_IN_COMBAT`).** `ShowQuestOffer` and `ShowQuestComplete` run no Lua of Blizzard's themselves, but `QUEST_DETAIL` and `QUEST_COMPLETE` are `SynchronousEvent`s: if the client fires them inside our call, `QuestFrame`'s handlers (`ShowUIPanel`) run in SaftUI's. The seam allows the clicks in combat today (the owner's ruling: finishing a quest from its popup in combat is the point of the popup). `/console taintLog 1`, then click an auto quest's popup (an offer, then a turn-in) and an auto-complete quest's row, out of combat and then in combat; then, in combat, open the map, the bags and a quest giver's dialog, and read the taint log for `QuestFrame`, `ShowUIPanel` or `blocked` lines. *Passes:* nothing blocked, no such lines; the seam stays as it is. *Fails:* set `TR.POPUP_CLICK_IN_COMBAT = false` in `clicks.lua`: both clicks then do nothing in combat and say "Out of combat only" (out of combat they always run), and the popup waits for the end of the fight. Paste the lines.

### E. Quest item buttons in the rows (Task 8; G1, G4, G7) `[F+R]`

Items tab: placement **In the row** (the default), Button size 24.

1. **P3 in the real thing:** out of combat, click the button of a quest with an item: it uses the item. Then in combat. An equippable quest item is the rare case to try. Seam on failure: `TR.ItemAttributes` (Part 2, P3).
2. **G1:** `/console taintLog 1`, `/reload`. Track a quest with an item. Use it from a row button in combat. No "Interface action failed"; the log has no `blocked` line and nothing from SaftUI naming `ObjectiveTracker`, `dirty`, `charges` or `OnClick`.
3. The button sits at the row's top right and the title is narrowed; the cooldown swipe, the count (an item with charges), red while out of range (an item with a range), the accent border inside the quest's area, the hover. Changing the theme or Button size redraws it. Scroll a long list: buttons follow and hide when their row's centre leaves the view.
4. **Once per click:** with `/console ActionButtonUseKeyDown 1` and then `0` (the game's "cast action keys on key down" setting), a click uses the item once. Shift-click uses the item (it does not link it: a secure button can't see the chat box).
5. **G4, combat:** with buttons shown, start combat: the list and bar do not scroll, the bar shows at 40% with the lock tooltip over it. Complete or abandon a quest above one (or collapse a group): the lower buttons stay and **dim to 40%**, still usable, tooltip names the quest; when combat ends they are back on their rows. Pick up or accept a quest item in combat: its row shows a greyed icon with "Its button comes when combat ends.", then a button.
6. **G7:** `/reload` in combat: quests show at once, the rows show greyed item icons, and the buttons come when combat ends; nothing blocked.
7. Under the **Blizzard theme**, walk into a quest's area in combat: nothing blocked (this also settles whether a region of a protected frame can be made or anchored there). The button's ring and border draw over the icon and under the count.
8. A pet battle: the item layer hides (its driver is `[petbattle] hide; show`).
9. Item buttons **Off**: the item shows as a plain icon in the row, no button. Tooltips off: no tooltips on the buttons or the greyed icon.
10. A hidden window's rows still report their position (so a window hidden by Hide quest items off still has its buttons at its rows): see section I.

### F. The column beside the tracker (Task 9; G1, G4) `[F+R]`

Items tab: placement **Beside the tracker**.

1. Buttons sit 4 outside the window, level with their titles, numbered 1 to n, and the same numbers show in the accent at the end of each title.
2. The tracker on the right half of the screen puts the column on its left, and on the left half on its right. Drag it across the middle in `/sui edit`: the column follows and changes side. Width, Max height, Grow up, UI scale and a resolution change move the column with the window.
3. With 40 px buttons and tight spacing, a button that would overlap the one above sits 2 px under it; one stacked past the window's bottom hides, and its row shows the plain icon.
4. Scroll the list: buttons whose titles leave the view hide, and the numbers on the rest do not change.
5. **G4, second half:** in combat the wheel and the scroll bar scroll with the column (no lock tooltip, bar at full strength); the column stays put; a click uses the quest's own item. At combat end the column is placed again.
6. In combat, complete a quest: its button dims to 40% and stays, with a tooltip naming the quest; the others keep their numbers. A new quest with an item has a greyed icon where the number goes until combat ends.
7. Taint log: nothing blocked when a quest completes, an item appears, a group collapses or the window resizes in combat with the column shown.
8. **A profile switch in combat (decided in Task 13):** switch profiles (or change the placement through a profile) between In the row, Beside the tracker and Off while in combat. Nothing is blocked; the buttons stay where they were (dimmed to 40% if their place is no longer their row's, never invisible); at combat end every button is where the new placement says.
9. Under the Blizzard theme the column buttons' ring and border draw over the icon as in the rows, and the number is readable over the icon.

### G. The nearest quest item button and its key (Task 10; G1) `[F+R]`

Items tab: **Nearest quest item button** on, with a tracked quest that has an item.

1. The button shows at its spot with the item's icon. In `/sui edit` its outline ("Nearest quest item") appears only with the setting on and only while it has an item; the Position row and Reset work; a reload keeps the spot.
2. Set the key on the Items tab: the key shows at the button's top right (Pixel font); Key Bindings → SaftUI → "Use the nearest quest item" shows it; set it from there too and the button's text follows. Esc on the Items tab's Key row clears it. A key already bound to another action is taken and says so in chat ("F bound to Use the nearest quest item (was Action Button 1)."; a key the game refuses says "Can't bind F to ...").
3. **G1 by the key:** with `ActionButtonUseKeyDown` 1 and 0, one press uses the item once, not twice and not zero times, out of combat and in it. In combat the key works with the button shown.
4. Walk into a quest's area: it switches to that quest's item (accent border); out again, to the focus or the nearest. Focus another quest: it follows when no area is entered.
5. **P4 on Forever:** whether `C_Minimap.IsInsideQuestBlob` and `GetDistanceSqToQuest` answer in the open world; if not, `TR.ChooseNearest` skips steps 1 and 3 on Forever (Part 2, P4).
6. In combat: change nearest (walk, focus another): the button keeps its item and the key uses it; use up or hand in its quest's item: it dims to 40%, the tooltip names the quest; at combat end it changes. Nothing blocked. Change the key in combat: it applies at combat end. `/reload` in combat with the button on: it appears when combat ends.
7. Thin, Thick and Blizzard: the button restyles; the quest-area border shows under Blizzard.
8. A pet battle: the button hides (its own driver).

### H. The handover to Blizzard's tracker (Task 11; G2, G3, P4) `[F+R]`

Blizzard's tracker draws what SaftUI's doesn't (dungeons and scenarios, achievements, recipes, Mythic+, the rest). Blizzard's tab on the Tracker page has a "Now" line saying what is showing.

1. **P4 first** (Part 2): which sections fill on Forever.
2. Out of combat: a dungeon, or a tracked achievement `[F]` where Forever has them: Blizzard's tracker appears **in SaftUI's place**, skinned; SaftUI's window and item buttons go. Leave: 2 seconds after the need ends SaftUI's comes back with its buttons. The Now line before, during and after.
3. **G3 in combat:** zone into or pull in a dungeon, start Mythic+ `[R]` (or a scenario) in combat: Blizzard's tracker appears **beside** SaftUI's; after combat it moves into place. Taint log: nothing blocked, no taint from the module hooks or the moves. A need that ends in combat with a quest item button to show: Blizzard's stays until combat ends, then SaftUI's returns with the buttons.
4. **Use a quest item** (G1/G2) from SaftUI's buttons after a handover in combat, and from Blizzard's own buttons while it is shown. Run the G2 line (section C, step 5) after.
5. Blizzard's tab: Beside SaftUI's mode on both screen halves; with item buttons Beside the tracker Blizzard's steps out past the column; change the mode while handed over.
6. A tracker low on the screen (Grow up near the bottom): Blizzard's tracker appears at least 200 above the screen's bottom, with room, its modules not all empty (Ruling 33).
7. A layout of Blizzard's own Edit Mode with a system snapped to the tracker: a handover in combat waits for the end of combat; SaftUI's tracker alone shows meanwhile.
8. The nearest item button while Blizzard's tracker is shown: it stays (it may overlap).
9. A profile switch while handed over: Blizzard's tracker stays, nothing moves. Beside mode with the column: collapse a group or complete a quest in combat; Blizzard's tracker must not cover the dimmed buttons. Grow up in a dungeon, accept or complete a quest: Blizzard's tracker must not move. An Edit-Mode-moved tracker revealed low on the screen.
10. `[R]` with a recipe or a Traveler's Log activity tracked in the open world: how often SaftUI's tracker is replaced (your P4 call).
11. That the game never blocks the `objectives` roleset in some content (SaftUI sets none).

### I. Fading and hiding (Task 12; G5) `[F+R]`

Visibility tab. For each of the six triggers (In combat, Out of combat, Mouse off, In instances, Boss fights, Mythic+ `[R]`; the row is hidden where the client has no such function), set Show, Fade and Hide (Mouse off has no Hide), with **Hide quest items with the tracker** on and off:

1. Window, rows and quest item buttons do what the table in `.agents/taint.md` rule 17 says. A hidden button never clicks; a faded one is at 25% or more.
2. With the items setting off, hide the window by Out of combat Hide: the buttons stay where they were, usable. A quest picked up meanwhile gets its button.
3. In combat with In combat Hide and the setting on: the buttons and the window hide; leaving combat brings both back. Change a setting in combat: nothing blocked, and the layer's driver follows at combat end.
4. In an instance (In instances Hide, items on): the buttons are hidden as you zone in. Start a Mythic+ key `[R]` and a boss fight with their rules set. A boss frame outside an encounter (a quest boss) hides the buttons with Boss fights Hide and the items on; the window stays: is that acceptable?
5. **Fade at 0%:** click through where the tracker sits (the world is clicked, not the rows), including the scroll bar's strip, and zoom the camera with the cursor over it. Move the mouse onto it: it comes back and takes clicks. The empty-list line takes no click after a fade cycle.
6. Background under the mouse only: the panel appears under the mouse, the text always shows. Scroll bar under the mouse only.
7. The nearest button is shown under every trigger and hides only in a pet battle.
8. **Handover:** with a scenario or dungeon showing Blizzard's tracker, Fade fades it and Hide conceals it, in place and beside; Blizzard's right column re-applying its own alpha (on a layout) does not undo the fade; the mouse over its spot brings it back. Alt+Z twice while Blizzard's tracker is concealed leaves the next reveal faded. **Another addon's alpha:** during a faded handover (Mouse off Fade, the mouse away), have BigWigs set it in a boss pull, or `/run ObjectiveTrackerFrame:SetAlpha(0)` and then `/run ObjectiveTrackerFrame:SetAlpha(1)`: the 0 stands (SaftUI does not fight another addon, the spec's edge case) and the 1 puts the fade back (`TR:OnBlizzardAlpha`, `.agents/taint.md` rule 17).
9. Taint log: nothing from the `SetAlpha` hook or the fade; nothing blocked in combat. `/sui edit` drag while handed over with Grow up: Blizzard's tracker follows the holder, x and y.
10. `[F+R]` Boss fights: `[@boss1,exists]` hides the buttons in a fight that has boss frames, and the direct Hide covers one that has none. A `/reload` in a boss fight with `/console loadDeprecationFallbacks 0` still hides the tracker for Boss fights Hide.
11. `[R]` In your house or neighborhood with In instances Hide: whether the game says you are in an instance there (instance types `neighborhood` and `interior`).

### J. The colors and the look (Task 2, Task 5; G6, G11) `[F+R]`

1. The Colors tab's Objectives colors recolor both trackers, at once; old custom colors carried over (Part 1).
2. The look under **Thick, Thin and Blizzard** (every part above under each); Width, Max height, Grow up; the scroll bar under the mouse (shown when the mouse is over the tracker, at 40% with row buttons in combat); zone groups with the current zone first and its map pin; collapse states surviving `/reload`.

---

## Part 5. Rulings made for you to check

Short list. Each was decided while building, and each is easy to change; say if you disagree.

1. **Ruling 33: the spot's floor.** A revealed or concealed Blizzard tracker is kept at least **200 above the screen's bottom** (`TR.BLIZZARD_FLOOR`), even if that puts its top above SaftUI's, because its height runs from its anchor's y down to the right column's bottom and a lower spot leaves its modules no room. Check in section H, step 6.
2. **The hover area includes Blizzard's revealed tracker.** While handed over, "mouse over the tracker" (Mouse off, hover) means SaftUI's holder **and** the rectangle Blizzard's tracker was placed in.
3. **Watch changes are held out of combat.** Shift-click, Track Quest and Untrack do nothing in combat (the game runs Blizzard's tracker, the map and the super track frame synchronously inside the call) and say "Out of combat only". Settled by P6; Focus stays allowed in combat.
4. **Shift-click on an item button uses the item.** A secure button can't see whether a chat box is open, so it never links the item.
5. **The nearest button's refused anchors.** Its Position row won't anchor to the tracker's window, Blizzard's tracker or anything that moves with them (a secure holder anchored to a frame that moves in combat would protect that frame); a refused saved anchor is placed on UIParent without writing the profile.
6. **Numbers count only expanded groups.** The column's numbers run over the quests the list draws; collapsing a group renumbers the column.
7. **The column is clamped to the scroll view.** A button the stacking pushes below the window's bottom is hidden out of combat, and its row shows the plain icon.
8. **The menu uses the game's strings** ("Open Quest Map", "Untrack"), while the hints and the Left click values use SaftUI's wording ("show on map", "stop tracking").
9. Also for your eye: the Left click "Focus" hint is the literal "Click: focus." (should it keep the Shift and Right-click parts?); the quest icon's tooltip ignores the Tooltips setting (icon-only rule); a boss frame outside an encounter hides the buttons with Boss fights Hide; a profile switch between item placements in combat applies at combat end (section F, step 8); the nearest key stays bound while the nearest setting is off (the button then uses nothing).

---

## Part 6. Wrap-up checks

1. **G2 once more**, after the whole session (an hour of questing, a dungeon, a handover in combat): `true true true`.
2. Read `Logs/taint.log` for the session. A clean log has no `blocked` line, and nothing naming SaftUI with `ObjectiveTracker`, `dirty`, `charges`, `isDirty`, `isCollapsed` or `OnClick`. BugGrabber has nothing from SaftUI.
3. `/console taintLog 0`.

## Part 7. If it all passes

1. Fold each experiment's result into its seam (a failed one changes one function, Part 2; a passed one changes nothing).
2. Flip the default: in `SaftUI-Tracker/config.lua`, `enable = false` becomes `enable = true`. One line. Then run `tests/run`: `tests/tracker/switch_test.lua` pins the default, and every test that builds a world with `TW.world` and no `on` expects it off, so make `TW.world` pass `on = false` unless a test asks (and keep one test of the real default). Everything that says it is off by default changes with it, in the same commit: `AGENTS.md` (the layout row's "switched off by default" and the first paragraph's "an objective tracker that is off by default"), `.agents/architecture.md` (the SaftUI-Tracker bullet's "It lands switched off"), the comment in `SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua` ("SaftUI-Tracker, switched off by default"), and the README's lines that say the tracker is off (the nearest button's own "off by default" stays). **AceDB drops a value equal to the default** from the saved profile, so a profile that had the switch off before the flip is on after it (a profile that chose off while the default was off never saved it); only the owner has the build, so this is a note, not a migration. Say it in the commit.
3. In `docs/followups.md`, move the entry "SaftUI's tracker: experiments and in-game checks before the switch turns on" and the "Objective tracker skin" entry's zone grouping, max height and scroll frame to Resolved.

---

## Which check is which of the spec's G1 to G12

| G | Where | Built in |
| --- | --- | --- |
| G1 | E (rows), F (column), G (nearest key), H step 4 | 8, 9, 10 |
| G2 | C step 5, H step 4, Part 6 | 6, 11 |
| G3 | H | 11 |
| G4 | E step 5, F step 5 | 8, 9 |
| G5 | I | 12 |
| G6 | A, B, J | 4, 5 |
| G7 | E step 6 | 8 |
| G8 | B step 9, D step 7 | 5, 7 |
| G9 | D | 7 |
| G10 | A steps 1 and 2 | 4 |
| G11 | Part 1 step 4, B step 8, J | 2 |
| G12 | A step 6 | 4 |

---

## Results so far (the owner's pass on Forever, 2026-11-15)

- **P1: passed.** The item was used in combat and the line printed `true true` (the third value, `nil`, is "tainted by nobody").
- **P2: not settled by the script.** The paste-in conceal did not move the tracker (today's mover most likely put it straight back). With SaftUI's tracker switched on, the G2 line printed `true true true`, so the real concealment left Blizzard's tracker secure in that session. Still to confirm by eye: Blizzard's tracker is off screen while SaftUI's is on. Seen along the way: a quest item button of Blizzard's that first appears during combat is disabled until combat ends, then works in and out of combat.
- **P3: passed.** Click and key, in combat, with the key-down setting both ways.
- **P4, open world: only `QuestObjectiveTracker` had content.** Every other module (scenario, widgets, campaign, adventure, achievement, monthly activities, initiative tasks, recipes, bonus, world quests) was empty, with no scenario, popups, tasks, world quest watches or widgets. So nothing hands over in the open world on Forever with only quests tracked, and `TR.SectionHandsOver` needs no change for it. Quest headers are zone names. `GetDistanceSqToQuest` answers for some quests and gives nil for others; `C_Minimap.IsInsideQuestBlob` answers (true for the quest 30 yards away); `GetQuestTagInfo` gave no tag names. `TR.ChooseNearest` needs no change. Still to run: inside a dungeon and a battleground, and with an achievement or recipe tracked.
- **P5: nothing from SaftUI was blocked.** No `Logs/taint.log` was written (the file had not appeared by the end of the session), so this rests on BugGrabber: its only blocked action that session named another addon's quest log, not SaftUI.
- **P6 and P7: skipped by the owner.** The seams stay as built: watch changes out of combat only; popup clicks allowed in combat.
- **G2 with the tracker on: `true true true`.** The refresh's time and allocation were "basically nothing"; the allocation followup can be closed as accepted.
- **2026-11-15: the default is on.** P2 passed (the owner had misread the step: with SaftUI's tracker on, Blizzard's is off screen). The owner approved switching the tracker on by default ("Everything looks good ... we can enable it by default"), and `SaftUI-Tracker/config.lua` now has `enable = true` (Part 7 done). Still to do: P4's dungeon and battleground runs. At upgrade: AceDB drops a saved value equal to the default, so a profile that had the switch off while the default was off has nothing saved and is on after the flip, and one that had ticked it on has `true` saved, now dropped, and stays on; only the owner has this build, so there is no migration.
