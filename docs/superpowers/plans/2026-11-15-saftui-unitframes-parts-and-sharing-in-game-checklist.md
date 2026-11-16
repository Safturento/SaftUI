# Unit frames: parts and All units, the in-game checklist

One list for the whole plan (`docs/superpowers/plans/2026-11-15-saftui-unitframes-parts-and-sharing.md`, Tasks 1 to 8), in the order to play it. Nothing here counts as verified until the owner confirms it in game. The tests run on stubs: they cover what is saved, which rows a page holds, the order and the widths. They cannot see how it looks, how it feels under the mouse, or what the game does with a frame. This list is those things.

G1 to G14 are the spec's checks (`docs/superpowers/specs/2026-11-15-saftui-unitframes-parts-and-sharing-design.md`, "In-game checks"), marked where they come up. Section A is the one thing to do before installing. Sections B to G are in play order. Section H is the All units step list from Task 6, section I the page by page checks G1 to G14 do not already cover.

Check on WoW Forever (the client played) first, then once on retail where a line says so. Turn on BugGrabber's log, so a Lua error is kept. Everything is at SaftUI's defaults unless a line says to change it. Wherever "Unit frames" or "Unitframes" is named it is `/sui` > Unit frames (the sidebar says "Unitframes").

## A. Before you install: copy your profile

The first login with this build converts the unit frame profile in use, at once, before you could copy it. So make the copy on your CURRENT build.

1. `/sui` > Unit frames > Manage > Copy (the Manage button is beside the Unit dropdown). Name the copy, then switch to it (Profile dropdown, beside Manage).
2. Log out. Install the new build. Log in: only the copy is converted. Your real profile stays as it was until you switch to it (section H, step 5).
3. This protects ONE SaftUI profile. Another character on another SaftUI profile converts its own unit frame profile at its first login with this build. Either copy on each of them first, or know that each has its own backup and its own `/sui uf restore` (a restore affects the profile in use only). Try it on one character first.

## B. Logging in: nothing looks different (G1, G2)

Do this with `/sui` closed. Anything that moved here is a bug.

1. **G1, an untouched profile.** Log in on both clients on a profile with no changes (a new SaftUI profile, or a fresh unit frame profile made with Manage > New). Every unit frame (player, target, target of target, focus, pet, boss), the party and raid frames (in a group, or with Test mode on), and the nameplates (enemy and friendly) look exactly as before: same size, place, colors, texts, icons and auras. One chat line says sharing is set up for the unit frame profile, once.
   - If it fails: check the BugGrabber log first. Then `/sui uf restore`, then `/sui uf restore confirm`, which puts every unit's shared settings back. The conversion is `UF:ConvertShared` and `UF:PrepareShared` in `SaftUI-Unitframes/config/shared.lua`, called from `OnEnable` in `SaftUI-Unitframes/unitframes.lua`.
2. **G2, your own profile (the copy of it).** The same, on the copy you made in section A: your fonts, positions, colors, Party's names, the cast bars, everything as you left it. Take the same scene before (the old build, in a screenshot) and after, and compare unit by unit.
   - If it fails: say which unit and which setting. `/sui uf restore` then `/sui uf restore confirm` puts it back without a reload. It does NOT undo a unit's place, size, Enable, layout, Class power or nameplates (those were never converted).
3. **A second login.** Log out and in again: no chat line, nothing changes. (Only the first login of a profile converts.)
4. **Both clients, no Lua error** at login or on opening `/sui`.

## C. The pages: five tabs, Parts, the part row (G3, G4, G8, G9, G13, G14)

`/sui` > Unit frames.

1. **G3, the page.** The Unit dropdown starts on All units (section H). Pick Player: five tabs, General, Health, Power, Cast bar, Auras. General reads three sections in this order: Frame (Enable, Theme, Background, Width, Height), Position, Parts. Parts are two to a line at full size: Name, Health text, Power text, Class power, Raid target, Raid role, Group role, Quest, each a check box, a name, a word (what its position is attached to: Health, Power, Screen, Unit frame) and a dots button. Click the size button to go to half: one to a line. At half, press the size arrow once more: `/sui` becomes the bar, its smallest size, and shows no page.
   - If it fails: `SaftUI-Unitframes/config/parts.lua` (`UF.PARTS`, which part is a row or a tab) and `SaftUI-Unitframes/config/config.lua`.
2. **G4, a part row.** Player > General > Parts > Name.
   - Hover the row (its label, box, dots or the word): the row lights. Player's Name box is Player's own on a fresh profile (its names are off where most units' are on), so the word gives way to a short line: Own, a reset arrow, Apply to: All | Multiple. A row whose box follows All units (Player's Health text) keeps its word on hover. Nothing moves, nothing grows, no row below it shifts. (Don't press that reset arrow unless you want Player's names on: it makes the box follow All units.)
   - Click the row, or the dots: Name's menu opens, inside the screen. Its small rows (the toggles) sit two to a line; the Font row has its link to the Fonts tab; the Position block is last, with its TO dropdown. All of it fits inside the menu with no row cut at the right.
   - Esc closes the menu. A click on the check box, on the dots or on a piece of the hover line does what that control does, and does not open the menu a second time.
   - If it fails: `SaftUI-Core/Config/optionsitem.lua` (the row), `optionsbody.lua` (hover and click), `optionsmenu.lua` (the menu), `optionsshare.lua` (the inline line).
3. **The dots' light.** Player > General > Parts > Name's menu: untick Show level. Close the menu: the dots are now in the normal text color (brighter than the others), and their tooltip reads "1 setting here is Player's own." Open the menu, hover Show level and press Reset in its line: it follows All units again (levels back on) and the dots dim. On All units, or on Player's Class power (which is not shared), the tooltip counts settings that differ from their defaults instead ("1 setting here differs from its default."), and the row's own reset arrow puts only its Show box back to its default.
4. **The word and its tooltip.** Hover the word at the right of a row (before the hover line replaces it): the tooltip gives the full position, for example "Right of Health: -7, -1". Class power's reads against the unit frame or the screen as set.
5. **G8, Health text in two places.** Player > General > Parts > Health text > its menu shows Hide full, Short, Deficit and the rest. Player > Health > Text section shows the same settings. Change one in either place: the other shows the change. On Player both places then carry the own mark (the accent bar, the label in the accent); a unit's shared rows have no reset arrow: the Reset in either place's hover line makes it follow All units again, in both. On All units the same setting has a reset arrow in both places while it differs from All units' default. `/sui` search for `Deficit`: ONE result per page, at Health text (not also at the Health tab). The same for Power text and the Power tab.
   - If it fails: the tab's Text section says `mirrorOf` in `SaftUI-Unitframes/config/parts.lua`, and `OM.Search` skips it in `SaftUI-Core/Config/optionsmodel.lua`.
6. **G9, Additional power.** Player > Power: a second tab row under the tabs (Power bar, Additional power), above the Unit dropdown. Additional power is a page there, not a row in Parts, because its menu would be taller than the 700 rule (a part's menu fits the window's least height). Pick Target, then back to Player: Additional power is still the open sub tab. The same under Auras: Buffs and Debuffs as a second row.
   - If it fails: `UF.PARTS` says `place = 'tab', under = 'Power'` for it; the third level of tabs is in `SaftUI-Core/Config/optionsmodel.lua` (`OM.BuildView`).
7. **G13, search.** In the search box type `Show level`. The first result is "Show level" under All units > General (section Name), then one for each unit in the Unit dropdown's order: Player, Target, TargetTarget, Focus, FocusTarget, Pet, PetTarget, Boss, Party, Raid 10, Raid 40, Enemy nameplates, Friendly nameplates. Click Player's: Player's General opens, scrolled to Name, and Name's menu is open with Show level in it. Then `Reverse fill`: Player has three results, Player > Health, Player > Power > Power bar and Player > Power > Additional power; the last opens Power with its Additional power sub tab.
   - If it fails: `OM.Search` in `SaftUI-Core/Config/optionsmodel.lua`; `tests/unitframes/search_test.lua` pins the order.
8. **G14, under the Blizzard theme.** Global settings > Theme > Blizzard, then repeat steps 1, 2 and 6 above: the part row's hover tint, its menu, and the second tab row. Then Thick and Thin: the same. The tint should be visible on the row under Blizzard too (the kit's rows are SaftUI's own there).
   - If it fails: `SaftUI-Core/Widgets/states.lua` (the states), `SaftUI-Core/Config/optionsbody.lua` (`OB.RowHover`, the row watch).

## D. The nameplate pages (G10)

1. **G10.** Enemy nameplates > General: Nameplates, Threat when solo, the box "Use friendly nameplates' settings", Theme, Background, Width, Height, then Parts: Name, Subtext (no box), Health text, Threat, Raid target, Quest. Check the box: Name, Subtext, Health text, Raid target and Quest disappear (hidden, not greyed). Threat stays, directly under the box's section, with the "Sourced from friendly nameplates" line under it. The Health, Cast bar and Auras tabs are greyed out. Uncheck: everything is back at once, with your values.
   - If it fails: `SaftUI-Unitframes/nameplates/options.lua` (`PLATE_PAGES[unit].keptParts`, `UF.DisablePlatePageTabs`).
2. Your plates look exactly as before on both clients; nothing in the game's own nameplate settings changed (friendly plates, plate scale, simplified plates are as you left them).

## E. All units, a first look (G5, G6, G7)

Section H has the whole step list for the profile you converted. These are the spec's three checks.

1. **G5.** All units > General > Parts > Name > its menu > Font: pick another font. Every unit's names change, but a unit that owns its font (marked on its own page) keeps its own. The party and raid frames and the boss frames change too.
2. **G6.** Party > General > Parts > Name > menu > Show level. On a fresh profile Party already owns this setting (it is off, where All units' is on), so the row and the setting in the menu carry the own mark (an accent bar at the left and the label in the accent). On All units the Name row has a small diff icon; its tooltip has a line for each unit that owns something in Name: Player, TargetTarget, FocusTarget and Pet ("Show": their names are off), and Party, Raid 10 and Raid 40 ("Show level, Max length, Position"). Hover Party's Show level row and press its Reset (in the line): the setting follows All units again, and levels come ON (All units' value). That is expected: a shared row's Reset means "use All units' value".
3. **G7.** A unit's hover line shows only on what that unit owns, so make Target own them first. Target > General > Parts > Health text's menu: tick Short (Target now owns it; its health shows short numbers). Hover Short: Apply to > Multiple > tick Focus and Pet > Apply: both show short numbers, each marked as its own. Then untick Target's Health text box (its health text hides; the row takes the own mark), hover the row: Apply to > Multiple > Focus and Pet > Apply: their health texts hide too, marked. To undo: on Target, Focus and Pet, hover each marked row (the Health text row, and Short in its menu) and press Reset (each follows All units again: text on, Short off).
   - If any fail: `SaftUI-Unitframes/config/sharedoptions.lua` (the shares, the page) and `config/shared.lua` (the storage, the sync).

## F. Profiles (G11, G12)

1. **G11.** Unit frame profiles (the Profile dropdown beside the Unit dropdown, Manage beside it): make a New one, Copy one, switch between them. Each has its own All units page. Nothing on screen moves on a switch (the frames look the same, unless the two profiles differ). The copy shows the source's look.
   - If it fails: `SaftUI-Unitframes/config/profiles.lua` (`SwitchProfile`, `UF.CopyProfileData`).
2. **G12, a switch in combat.** Make a second SaftUI profile first (Profiles page, "New" and a name; call it Other, any name will do). Back on the first profile, make a macro whose one line is `/run SaftUI.config:SetProfile("Other")` (put the second profile's name where Other is) and press it while in combat (a target dummy fight will do). Nothing errors, nothing taints. The frames change when combat ends (the switch waits for combat), and `/sui` was shut by combat as usual.
   - If it fails: BugGrabber's log; `UF:PrepareShared` in `config/shared.lua` and the combat queue in `SaftUI-Unitframes/unitframes.lua`.

## G. Restore and share again

1. `/sui uf restore` says what it would do, naming the backup's day. `/sui uf restore confirm` does it: the units' shared settings (look, parts, bars, auras) are back as before the first conversion, with no reload. It does not touch places, sizes, Enable, layout, Class power or nameplates.
2. Log out and in: sharing is still off, one line says so, and All units says so on its page.
3. `/sui uf share` says what turning it on would do and what it replaces. `/sui uf share confirm` does it (or the "Turn on shared settings" button on the All units page, which asks). Sharing is back; the backup is now of this moment.
   - If it fails: `SaftUI-Unitframes/config/sharedoptions.lua` (`RestoreSharedCommand`, `ShareCommand`).

## H. All units, in plain words (from Task 6)

**What happens at the first login.** For each profile it converts, SaftUI works out, for every setting the units can share, the value most units show and puts it in All units; a unit that shows something else keeps its own (marked). Nothing is written into any unit's own values, so every unit shows what it did. Before it writes anything it keeps a backup of every unit's shared settings. One chat line says sharing is set up. The second login converts nothing and writes nothing. A new profile, and a copy made with Manage > Copy, are converted at once (a copy from its own values). Only an IMPORTED profile waits for the next login: it is not shared until then, and edits you make to it before then are kept.

**Picking the value a setting already has** changes nothing: a unit that follows All units keeps following. Picking a different value makes the setting the unit's own (marked); its Reset then follows All units again. Dragging a slider away and back to the same value also makes the setting the unit's own (the step away owned it); the own mark shows it and Reset makes it follow again. A Custom color picked while its box is unticked keeps the unit following, and is replaced if All units later ticks its box: tick the unit's own box first to keep the color.

**What a unit's Reset now means.** On a unit's page a shared setting's Reset (hover its row) means "use All units' value", not "this unit's own default". On a fresh profile 155 settings are already a unit's own (Party's Show level is off, for example); their Reset changes what you see (Party's Reset on Show level turns levels ON, All units' value).

**What could go wrong, and what you would see.** Each case writes nothing, builds your frames from the values already saved, says one plain line in chat, and the pages draw no sharing controls (All units says why instead):
- A part of the unit frames did not load: "sharing is paused". Edits you make then are still marked as the unit's own and are kept. A Reset on such a row follows All units' value at once (it does not wait for sharing to resume).
- A profile saved by a newer SaftUI (you went back and forward): left as it is; edits are marked as the unit's own.
- An error while converting: one Lua error and one chat line; not retried that session. An error in a later sync: the same, once, and sharing is paused for that profile for the session.
- A restored profile (section G).

Known residue: shared settings you change in an older SaftUI after upgrading are put back by the next upgrade (an edit made in this version is marked and kept). A cast bar width of 0, or Relative width on (Player, Target, Focus), now stays after a logout; before, the old code put it back.

**Going back.** Section G. `/sui uf restore` undoes the shared settings and nothing else. After a restore no login converts the profile again. `/sui uf share confirm` converts from what the units show NOW and REPLACES the old backup, so a later restore returns to that moment, not to before sharing was first turned on.

**The five in-game steps, in order**, on the copy made in section A:
1. Log in: every frame, group, boss frame and plate looks the same; `/sui` > Unit frames opens on All units.
2. Change a font on All units, and a font on one unit: the unit gets the own mark and its Reset follows All units.
3. Party > Name > Show level: hover the row; Reset turns levels on. Expected, worth seeing once.
4. `/sui uf restore`, then `/sui uf restore confirm`: the look is the same with no reload; log out and in: still off (one line, once); `/sui uf share`, read what it says, `/sui uf share confirm`: back on.
5. Only then switch to your real profile (Profile dropdown beside the Unit dropdown): it converts at that moment, with its own backup.

## I. The pages, one by one (what G1 to G14 do not already cover)

From the Task 3 and Task 5 reviews. Both clients, under Thick and Blizzard where a line says so.

1. **Health tab (Player).** The bar's rows (Enable, the bar settings), then the size line (Width, Relative, Height, Relative) in the same first panel, then Position as the next panel, then Colors, Text, Bar background. (Position is second, after the size line, not before it.)
2. **Power tab (Player).** The same layout as Health, on Power bar and on Additional power: rows, size line, Position, then the rest.
3. **Cast bar (Player).** Enable, Position, Bar, Spell name, Time, Icon. The tab is called "Cast bar" (it read "Castbar"); a search for `Castbar` still finds it.
4. **Auras (Player).** Buffs and Debuffs as a second row; each: Enable, Position, Layout, Buttons, and the rest. The target of target, focus target and pet target pages have no Cast bar tab.
5. **Every other unit.** Target, Focus, Pet, Boss, Party, Raid 10 and Raid 40 have the same five tabs. Boss, Party and the raids keep Layout between Position and Parts (Range too on Party and the raids; Boss has none). Party and the raids list Ready check in Parts; the others do not.
6. **Class power.** On Player it is a Parts row; its menu is the longest of the rows. Its Position is the menu's third section (the size line is a section of its own).
7. **Copy from (beside the Unit dropdown).** The list reads as before, with "Cast bar" instead of "Castbar". Copy a part between two units (Player to Target), check the change, then Undo: `/sui edit` and press Undo on edit mode's bar (or pick the step in its History list). The copy goes back, and a unit that followed All units follows it again. A copy writes the unit's own settings, so on a shared setting the unit is marked own where the copy differs from All units. Neither nameplate page has Copy from.
8. **Half size and the bar.** At half size the parts are one to a line and the second tab rows still show; the small bar shows no page; growing back keeps the page and the sub tab.
9. **Friendly nameplates.** Check "Use enemy nameplates' settings": the whole Parts section goes, and "Sourced from enemy nameplates" is last. The Enemy page's box is then greyed out, its reason in its tooltip. Uncheck: everything is back.
10. **A menu open when a box is checked.** Open Enemy > Name's menu, then click the box: the first click only closes the menu (an open menu takes any click outside it). Click the box again: Name's row is gone. Uncheck, open Threat's menu and click the box: that click closes the menu too; check the box: Threat's row stays. (A menu that stays open while its row hides can't be reached by a click; the tests pin it.)
11. **The boxes' tooltips.** Hover the Enemy page's box: it says its Health, Cast bar and Auras tabs are disabled, General's other settings and parts are hidden, and Threat when solo and the Threat part stay and still apply. The Friendly box's says Friendly nameplates never show threat.
12. **Search with a box checked.** `Raid target` with the Enemy box checked: nothing from that plate page. Unchecked: it is found.
13. **Another nameplate addon on** (Plater or the like): both plate pages say "Nameplates are drawn by ..." at full strength, every part row is greyed out, and Auras opens Buffs greyed out.
14. **The Position block, anywhere** (Player > General > Parts > Name's menu, or Player > Health), with Global frame chosen in TO. The name box under the TO dropdown is exactly as wide as the dropdown (the dropdown is 136 wide in a unit frame block), the AT square and the offsets sit in the block's own columns, and the gap after the dropdown matches the others. Pick `AdditionalPower`, `ReadyCheckIndicator` and `RaidTargetIndicator` in TO: is any name cut where it was whole before? (The dropdown is 4 less wide than it was: tell me if a name is cut.)
15. **The summary on a narrow cell.** At half size, with a long position (Name's menu changed to a different anchor), the word at the right of a row gives way to nothing when the cell is too narrow, and the row is never taller or wider.
16. **No saved setting changes by looking.** Open every unit's General and every part's menu, change nothing, `/reload`: the pages open the same, and no own mark appeared on a row you did not change.
