# SaftUI live colors: the in-game checklist

One list for the whole live colors plan (`docs/superpowers/plans/2026-11-15-saftui-live-colors.md`, Tasks 1 to 11), in the order to play it. Nothing here counts as verified until the owner confirms it in game. The tests run on stubs: they cover which calls a pass makes, that it makes no frame and calls nothing forbidden, and the garbage it leaves. They cannot say how long a pass takes in the game, or how a Blizzard frame behaves. Section K is the only way to know the real cost.

Check on WoW Forever (the client played) first, then once on retail where a line says so. Turn on BugGrabber's log, and use a character with a group or a raid to play with where a line asks for one. Most highlights show only under the mouse, and a drag keeps the mouse in the picker, so "as you drag" can be seen on what shows at rest; the rest shows after the picker closes. The picker's hex box lets you change a color while the mouse is elsewhere.

L1 to L9 are the spec's checks (`docs/superpowers/specs/2026-11-15-saftui-live-colors-design.md`, "In-game checks"); each is under the section that covers it.

## A. The Colors page and the picker

1. `/sui` > Global settings > Colors: no "reload" anywhere on the page. A line sits at its top: "A change shows everywhere as you pick it. This window takes it when the picker closes." Buttons' note reads "Opacity sets how strongly each is drawn: 100% is SaftUI's own." and no other section has a note. The Accent's tooltip (Global settings > Theme) ends at "and the chat prefix."
2. Open a color and drag Text > Muted: the picker's own captions and labels follow, and a field's text in `/sui` follows Text > Normal. Drag Class > (any class): that class's chip in the picker follows.
3. Cancel after a drag: the color is back everywhere it went, `/sui` included.
4. Press Okay after a drag: the color stays everywhere, and `/sui` redraws once as the picker closes (its rows show the new color then, not during the drag). Nothing hitches while the picker is open.
5. With `/sui debug` on, one drag and Okay prints one `<DEBUG:Colors>` line. Section K reads it.

## B. Unit frames and nameplates (Task 3)

1. **A class pick (L3).** In a group or raid, drag your class's color: your frame, your name and, in PvP, such plates follow; nothing else flickers (the others' bars don't). If you play a Warrior, Paladin, Rogue or Mage, do it again beside a pack of mobs: their plates update too (a known cost, in `docs/followups.md`); note the debug line.
2. **Test mode.** With Raid 10 or Raid 40 on, drag a class color and Text > Danger: the previews follow, and the offline ones (the 9th and 26th) follow Status > Disconnected. Read the slowest pass of Raid 40: it is probably the heaviest case.
3. **Reputation.** Drag Reputation > Hostile near hostile mobs: their plates follow. With a pet out, drag Reputation > Friendly: the pet's health follows. On the target page set Health > Colors with Class off and Reaction on; target a friendly player, change Reputation > Friendly, then press its reset arrow: the target's bar goes back at once.
4. **Text.** Drag Text > Danger with a much higher mob targeted: its level tag follows. In a group, drag Text > Normal while a plate shows good threat: its threat text follows. In a raid with plates up, read the debug line for Text > Normal.
5. **Roles.** Drag each role: the corners in a group and in Test mode follow as you drag.
6. **Power.** A Druid in cat form: Power > Mana moves the mana bar, and Power > Combo points moves the points.
7. **Status.** Drag Status > Tapped with a tapped enemy in sight: its bar follows.
8. **Retail, in an instance where enemy classes are secret:** drag a class color and a reputation color. No Lua error.

## C. Bags and the bank (Tasks 2 and 4)

On Forever (the combined bank, the default) and on retail, every bag and the bank open.

1. **Item quality > Epic (L4)**, dragged, in each view (Compact, One bag, Multi bag, Rows): only epic items' borders and epic currencies' borders follow. Cancel puts them back. Close the bank, drag Epic, open the bank again: its epic slots wear the new color.
2. **Text > Strong, Success and Shared:** plain, Bind on Equip and Warbound item levels; the reagent markers; the bag window's reagent count in the footer and (retail) the combined bank's warband count; account-wide and ordinary currency counts. After a Success drag, move an item into the reagent bag: its marker is the new color.
3. **Text > Muted** in Multi bag or One bag with a reagent or herb bag: the grey "· type" part of its title follows, its count doesn't change and the title isn't cut differently. The combined bank's eyes (retail) follow.
4. **Text > Normal:** the view buttons' glyphs and the currency funnel.
5. **The combined bank's unbought tabs and price.** Buttons > Danger tints the unbought bank tabs on the combined bank, and Text > Danger and Strong color the next tab's price (an unaffordable price in Danger, an affordable one in Strong).
6. **The Accent:** the loading bar on a fresh open, the bag bar slots' hover, the lit view button, a slot's hover, the selected bank window.
7. **The selected bank window through a theme change.** With the separate bank layout (combined bank off), click a bank window's title so it is selected, then switch the theme Thick > Blizzard > Thick: it stays in the accent. Drag Theme > Border: it keeps its accent highlight.
8. **Footers.** Strong, Success and Shared recolor the footers' counts without the window resizing or re-laying out.
9. **Buttons > Hover at 50% (L2):** a checked category filter box (a bag category's hide box in Edit, the currency funnel while checked) follows as you drag; afterwards a bag window's scroll thumb under the mouse shows it.

## D. Action bars, the totem bar and the micro menu (Task 5)

Thick or Thin first, then Blizzard.

1. **Buttons > Danger.** Drag it while an auto-attack button flashes (attack a target): the flash follows as you drag. Do the same with a totem button's flash. Under Blizzard neither is tinted.
2. **The Accent.** An equipped item (a trinket) on a bar: its border follows, and the other buttons keep the theme's border. Check under Blizzard too. Hover a totem button while dragging: its hover follows (not under Blizzard).
3. **Totem timers, out of combat.** Drop a totem. Text > Danger: under 10 seconds left, the timer's text and bar follow. Text > Normal: its text above 10 seconds follows, and so do the summon button's flyout arrows (the open arrow and, with the flyout open, the close arrow).
4. **A secret timer in combat takes the color at its next refresh.** Drop a totem in combat, then leave combat with it still down. Open `/sui` > Colors with `/sui debug` on and drag Text > Normal: the timer follows within a tenth of a second, with no hitch.
5. **Micro buttons.** Buttons > Hover: hover a micro button. Buttons > Pushed: open the character frame (its button stays pushed). Text > Caution: an alert flash on a micro button. Under Blizzard: unchanged.
6. **Bar items.** The zone text's and the addon compartment's hover follow Buttons > Normal. The tracking button (Forever), the queue eye and the expansion button follow Hover.
7. **Retail, in an instance:** the difficulty badge follows Item quality Common (normal), Rare (Heroic) and Epic (Mythic).

## E. Loot (Task 6)

1. **A real group roll** (a dungeon; Test mode's preview bars have no letters). With the roll up, drag Loot > Need, then Greed, Transmog and Pass: each button's letter follows its own color, and only its own. The small paired count (top right on Greed or Transmog) follows the other choice's color; in Test mode the preview bars' paired counts follow too.
2. **Need and Pass on a held roll.** Choose Need on a roll (or let one stay held), then drag Loot > Need and Loot > Pass: the held bar's letter follows.
3. **Item quality > Epic with an epic roll up:** its name follows. Choose on it: the held bar's name follows too.
4. **The Accent with a held bar:** its timer follows, and so does a finished bar's during its few seconds of linger.
5. **The feed (L6).** Epic item names follow Item quality > Epic as you drag; a rare one doesn't change. A currency line keeps its "(n/max)". A mount line follows Loot > Mount (border and fill). A reputation gain's bar follows its standing's color, and a renown gain's follows Renown.
6. **Feed lines merge after a pick.** Loot the same item twice in a row after changing Item quality > Epic in between: today they show as two identical lines (known, in `docs/followups.md`); note what you see.
7. **A profile switch** to one with other Item quality or Reputation colors: shown feed names and bars take the new profile's.
8. **`/reload`.** Lines saved from now on come back and still follow Item quality and Reputation; lines saved before this version keep the color they were saved in (expected).
9. With `/sui debug` on, drag Item quality > Epic with a full feed: note the slowest pass.

## F. Misc: skins, the tooltip and the tracker (Task 7)

On both clients.

1. **The tooltip on screen.** A drag takes the mouse off the unit and its tooltip fades, so use the picker's hex box: open Global settings > Colors > Class > (a class in sight) and click in the hex box. Put the mouse on a player of that class, or their unit frame. Type a hex and press Enter: the name and the tooltip's and health bar's borders change at once. Another class's color leaves the tooltip as it is. The same with Reputation > Neutral over a neutral NPC.
2. **A secret unit** (retail in an instance, or a Forever world-cursor unit) with its tooltip up: change its class color. No error, and the tooltip keeps Blizzard's color.
3. **The character frame**, open: drag Text > Strong, and the slots' item levels follow. Text > Muted doesn't move them.
4. **RestedXP**, a guide open: drag Text > Muted. The step numbers, the current step's title and the scroll thumb follow.
5. **SaftUI's tracker on.** Text > Normal, Muted, Strong and Danger (an item out of range) and Objectives > Completed follow as you drag. The Accent: the focus bar, a row's hover, an item's border in its quest's area. With `/sui debug` on, drag a class color for a few seconds: the tracker adds nothing to the line. Drag Text > Muted with Blizzard's tracker skin and the picker skin on too, and note the line.
6. **SaftUI's tracker off** (Blizzard's tracker, skinned): Text > Muted and Strong move the chevrons, and Objectives > Completed a finished line. Class moves nothing.
7. **The header lines.** Switch the theme Thick > Blizzard > Thick with either tracker showing: its header line takes the theme's border color each time. Drag Theme > Border: the line follows.
8. **Combat:** start combat with the picker open on Text > Danger while the tracker shows an item button and the nearest button. The picker cancels, the tracker is back on the opening color, and nothing is blocked.

## G. Core's widgets and edit mode (Task 2)

1. **The hidden-currency veil and the bank's eye keep their look.** Open the bags, turn on the currency filter (the funnel) with a currency hidden, and open the combined bank. Switch the theme Thick > Blizzard > Thick, then switch a profile: the dark veil and the grey eyes stay (they do not turn an opaque light blue or the Hover color).
2. **Buttons > Hover at 50%, dragged:** checked check boxes follow at once (see C9); the world map's resize corner under the mouse shows it afterwards. `/sui`'s grip shows it as `/sui` redraws.
3. **Buttons > Normal**, dragged: every scroll thumb at rest follows (a bag window's, the chat's); afterwards a bag header button's highlight. Buttons > Pushed: a held header button after the picker closes.
4. **The Accent**, with `/sui edit` on and Grid on: the two centre lines, the selected mover's border and tint, the docked strip, the Coordinates label and the History list's marks follow at once. Afterwards a bag slot's hover and a radio group's picked tab.
5. **Text > Muted**, dragged: a bag window's close cross at rest; edit mode bar icons at rest, the History list's title, foot and details, an undone row's label; the floating window's captions and status line. Text > Danger: a close cross under the mouse after the picker closes.
6. **The bar docked and floating under each theme.** Under Thick, Thin and Blizzard, with the bar docked and then floating (Detach) and the History list open, drag the Accent and Text > Muted: nothing in the bar's Show dropdown flickers or moves, no hitch.
7. **The Grid size arrow keeps its hover on a click.** In edit mode, hover Grid size's arrow and click it: it keeps the hover color after the click. Then turn edit mode off, change Text > Muted, turn edit mode on: the arrows are the new Muted.
8. **Edit mode off:** change any color: no hitch (nothing runs); `/sui edit`: everything shows the current colors.

## H. Profiles and combat (L8, L9)

1. **A profile switch (L8).** Switch to, copy from and reset a profile with other colors, out of combat: every reader takes the new profile's colors.
2. **In combat.** Make two macros, `/run SaftUI.config:SetProfile("Two")` and `/run SaftUI.config:SetProfile("Old")` (your profile names), and press one in combat: no `ADDON_ACTION_BLOCKED`, and every reader takes the new profile's colors when combat ends. Swap again in combat with the bags, the bars, the totem bar and a unit frame raid open.
3. **Combat with the picker open (L9).** Open the picker on Item quality > Epic (bags open) and start combat (a training dummy): the picker cancels, every reader is back on the opening color, no Lua error and no `ADDON_ACTION_BLOCKED`. Repeat with Text > Danger, a Class color and the Accent.
4. **Taint.** `/console taintLog 1`, play a while with the picker opened and closed during pulls: nothing in `Logs/taint.log` blames SaftUI.

## I. Text and Danger together (L1)

Drag Text > Danger: an error status line, the edit mode bar's refusal, a roll timer under a minute, expiring totems, a level tag on a much higher mob and a tracker item out of range follow as you drag. Cancel: every one goes back.

## J. What stays as it is, by design

These are not bugs. Note them only if they differ.

1. `/sui` redraws once when the picker closes: its rows do not follow during the drag (its field font does).
2. A tooltip takes a color when it next shows; a unit tooltip already on screen follows.
3. Chat lines already printed keep their colors; new ones take the new color.
4. Keybind mode's highlight takes a color when the mode next opens.
5. A roll result line's right text ("All passed", the winner's name) keeps the colors it was built with (`docs/followups.md`).
6. What is built when it shows (a roll that starts later, a new feed line, a plate that appears, a bag opened) reads the color then.
7. After a profile switch the zone faction words take the new profile's colors the next time they are drawn.

## K. The cost: `/sui debug`

This is the only way to know the real cost in a 40-player raid, and the spec's target is 2 ms a pass (L7), with a guard that waits a frame for each 8 ms over, three at most.

1. Turn on `/sui debug`. In a raid (or Test mode with Raid 40) with every bag and the bank open, SaftUI's tracker on and edit mode off, drag Class > (your class), Text > Danger, Item quality > Epic, Buttons > Danger and the Accent for a few seconds each, then press Okay: the `<DEBUG:Colors>` line gives the passes, the slowest and its color, the mean and the frames waited. Note any slowest pass over 2 ms, and every line with frames waited over 0.
2. Drag a color on the Theme tab (its Border or Background) and press Okay: the line names `theme`. If `theme` is over 8 ms, say so: it is the followup "The Theme tab's color drag recolors every drawn frame" in `docs/followups.md`.
3. Repeat with edit mode on and the History list open, and with Raid 40 in Test mode (the heaviest case for the unit frames).

## L. The picker's preview (Tasks 9 to 11)

The strip under the picker's square, with a "Preview" caption. Every color on the Colors page and the Accent have one, except a unit's Custom color (outside the page). On both clients; do each kind under Thick, Thin and Blizzard, and switch the theme on the Theme tab with a picker open where a line says so.

1. **P1, Text.** Global settings > Colors > Text > Danger: the picker is 436 tall with three tiles (Thick, Thin, Options windows), "Text" in your Normal color beside "Danger" in the picked color; drag the square and the sample follows. The Options windows tile is see-through when that background is (a green-brown strip behind it). Text > Normal: the "Text" labels follow it. Factions and Objectives samples wrap to two lines inside their tiles; Loot > Need, Greed, Transmog, Pass show the color's name.
2. **P2, Buttons.** Hover (then Normal, Pushed, Danger): five tiles Rest, Hover, Pressed, Checked, Flash; the tiles the key reaches are captioned in your Text color (Normal: Rest and Hover; Hover: Hover and Checked; Pushed: Pressed; Danger: Flash), the rest in Muted. The lit pieces follow a drag and fade with the opacity strip (0% makes them vanish). Hovering or clicking a tile does nothing. Under Blizzard the pieces are drawn Thick and "Shown as Thick: under Blizzard, SaftUI's buttons wear Blizzard's art." sits at the right of "Preview" without touching it.
3. **P3, bars.** Each picker shows its pieces in the picked color, at the sizes below, under Thick, Thin and Blizzard:
   - Class > (a class): a health bar 200 by 28 (70% filled, the class name at its left, 70% at its right), a raid frame 80 by 40 and a tooltip with the name and border in the color.
   - Status > Disconnected and Tapped: the bar and raid frame only (no tooltip), labeled Offline and Tapped.
   - Roles: a raid frame with the role corner at its bottom right in the color.
   - Reputation (each standing) and Renown: the experience bar's reputation bar and an NPC's health bar.
   - Power > Mana, Rage, Energy and the rest: a health bar with the power bar under it in the color. Combo points, Chi (and on retail Holy power, Soul shards, Arcane charges): five points, three lit. Under Blizzard they are drawn Thick with "Shown as Thick: under Blizzard, class power points wear Blizzard's art."
   - Threat > Warning and Bad: a nameplate 200 by 20 with its name and the percent above its right end, both in the color.
4. **P4, borders and the Accent.**
   - Item quality (any): a bag slot with its border in the color and an icon inside the border, and a loot feed line with the item's name in the color.
   - Loot > Mount: a feed entry with its border, its icon's border and its fill (at 60%) in the color. Compare with a real mount line in the feed.
   - Theme > Accent: four tiles (Field edge, Check box, Slider, Sidebar row) in the accent as you drag; under Blizzard Link, Picked entry, Own mark and Grid centre.
5. **Look at the pieces.** Do the thumbs read as scroll bar thumbs, is the 12 check box too small, should the Flash slots hold an icon, do the bars read as the unit frame's, raid frame's and nameplate's? Under Blizzard the bars here are the experience bar's kind, not the unit frames' bronze box with Blizzard's fill art: say if that misleads.
6. **A long sample in a wide font.** Choose a wide Text font (Colus, for example): the captions ("Options windows", "Sidebar row", "Health and power", "Reputation bar") are cut at their end, never wrapped, and the Blizzard notes are cut at theirs; a long label ("Death Knight", "Demon Hunter", "Disconnected") stays inside the raid frame and tooltip.
7. **The Blizzard notes.** Buttons (any key) and Power > Combo points under Blizzard: the note at the right of "Preview". Under Thick or Thin none. Class, Item quality and the rest have no note under Blizzard.
8. **An opacity.** Buttons colors have an opacity: the strip is 402 wide and the tiles stay whole; the other rows have none and the strip is 370.
9. **Cancel.** Drag any row's color, press Cancel, open it again: the preview shows the saved color; open another row: its pieces show their own saved colors.
10. **A theme flip with the picker open.** With a picker open on Power > Combo points, Buttons > Hover or the Accent, switch the theme on the Theme tab if you can reach it (or open the Colors page from a tab beside it): the pieces and the note change at once, and no tile moves off the strip.
11. **Near the screen's bottom.** Open the picker from a Colors row near the bottom of the window: the 436-tall picker stays on screen and its Last used chips still fill and click.
12. **Nothing is clickable.** The slot, the feed line, the bars and the tooltip in a preview take no mouse: hovering them shows no tooltip and clicking does nothing.
13. **P5, a unit's Custom color** (outside the Colors page): today's picker, no preview, 342 tall.
14. **Placement.** If the strip under the square feels wrong in use, say so: B is Ruling 18.
