# Decisions

Answers the owner has given to the questions and discrepancies. Each stands as a rule from its date; the pages below it (Discrepancies, Questions, Code changes) and the components are updated as the work lands, and until then this page wins where they differ.

## 2026-11-13

1. **The options window follows the theme.** Its controls' lines follow the theme's (Thin's under Thin, a recoloured Thick's under that) while fields stay dark, and the in-world close button is drawn in its window's theme. (Question 1, option C.)
2. **Panels are see-through or solid across the whole UI from one theme setting, and `/sui` follows it too.** The theme's Background carries the opacity; every panel follows it, the options window included; an individual panel can still override. (New.)
3. **A colour and its opacity are one control.** Wherever a setting has both a colour and an opacity today (two rows, or a colour beside an Alpha slider), they become one colour control whose picker sets the opacity, as the theme's Background does. (New; the pairs still to convert are listed under Code changes once audited.)
4. **One button, one size.** A single button component for `/sui` and the world, at one height and in one font; no second size. The edit mode footer's mixed sizes and fonts are the example of what this ends. (Question 2, stricter than either option.)
5. **Edit mode's controls leave `/sui`'s footer** for a bar of their own across the top of the screen while edit mode is on, with toggles for which modules' movers show. Built: the bar, docked or floating, with Undo, Redo, Reset and a History list. (New.)
6. **The `/sui` window collapses:** its sidebar can be collapsed, and the window shrinks to a half-width, one-column size and then to a small floating bar, and grows back. Being designed (same mockup). (New.)
7. **"On" is the accent colour,** never green text. **The accent is a theme colour** the player can change, with its own swatch in the Theme section. Built: Theme > Accent (color roles, Task 2). (Question 3, option A, plus the swatch.)
8. **`/sui` tooltips stay Blizzard's tooltip frame, with the description in SaftUI's normal text colour** in place of Blizzard's gold. (Question on tooltips.)
9. **The colour control's code is one colour everywhere.** Not black or white by brightness. The control is being redrawn with the code beside the swatch on the control's own dark field (mockup, part 1). (Question on the hex code's legibility.)
10. **Resets are per setting:** a `rotate-ccw` icon beside a control whose value differs from its default; no section or page Reset buttons. Built in the kit as the `default` option field. (Was already a rule; confirmed as general.)
11. **SaftUI scales with the display:** automatic from the screen's height against 1440, with a "UI size" slider to override; borders in whole pixels. A project, after the tokens are in code. (New; see the repo's followups.)
12. **The pixel font is likely to go** in favour of a face that reads well small at any scale; candidates are being compared in game (`/suifonts`). (New; undecided which.)

## 2026-11-13, later

13. **The colour control is a field with the swatch at its left and the code beside it** (mockup option C1): as wide as a dropdown, the code in the normal text colour on the field's dark fill, `· NN%` after it for an opacity, a see-through colour shown over a checker in the swatch. Replaces the bar with the code inside it.
14. **Colours named after a hue get role names.** The Colors page lets the player change "Blue", "Red" and the rest, which can then stop being blue or red. The owner: "maybe we should analyze how those specific entries are being used and consider renaming them accordingly? let the user decide what color truly belongs to that type of text." Built (color roles, Tasks 1–5): every hue name is a role (Text, Muted, Strong, Danger, Warning, Caution, Success, Shared; Buttons > Danger), with a migration that carries each customized color.
15. **The edit mode bar:** as mocked (`window-and-editmode-v2.html`), with the module toggles in one multiselect dropdown ("Show") rather than a row of chips. Undo, Redo and a per-mover Reset stay ("I looove the undo/redo/reset buttons").
16. **The `/sui` window's sizes:** collapsing the sidebar narrows the window by the sidebar and leaves the page as it is; the sidebar's toggle sits at the sidebar's bottom right while it is open and at the footer's left while it is closed; Reload UI moves beside Close so nothing shifts; the sidebar is available at half size too; the mini bar keeps the SaftUI name and is a little taller.
17. **Copy from on unit frames:** the dialog's settings show readable labels, not internal names ("for the copy from dialog lets clean the labels up"), and the Copy from button sits to the right of the Unit dropdown, on the picker's line, so it is reachable from every tab ("lets actually slot it to the right of the unit selection dropdown").
18. **The `/sui` window's sizes are approved** ("the /sui window sizing looks great"), with its arrows flipped from the first mockup: every arrow points the way the window's left edge will move (the window's right edge stays put), so grow is `chevron-left` and shrink is `chevron-right`, with grow at the left of the pair, and the sidebar's toggle points right to collapse and left to show.

## 2026-11-13, from the owner's comments on the Questions page

19. **The close button is the same height as buttons.** "should we just make it the same height as the buttons? the 1px size different might feel a bit off if they're next to each other. we should test that to see if we can get everything to be the same height and keep text/icons vertically centered here." Close, the window's size arrows and every button share one height, with icons and text centred; to be checked in game.
20. **Sidebar page names are sentence case:** "Action bars", "Unit frames", "Global settings". ("Lets go with Sentence case")
21. **The docs spell it "color",** as the code and the UI do. ("lets keep it inline with the code")
22. **Tooltips are consistent across the board:** SaftUI's Normal font on every line of the item tooltips too. ("Yeah A for sure, tooltips should be consistent across the board") Needs an in-game check of why the item and compare tooltips still show Blizzard's fonts.
23. **Under the Blizzard theme, meaning-carrying colours stay SaftUI's:** the rule editor's AND and OR, the own mark and the diff icon. ("Agreed, maybe if it bothers me later we can change this but it's fine for now")
24. **Unexplained values get tidied toward consistency:** a spacing scale is written down and values move onto it where that changes nothing a player would miss. ("A lot of these could be hard coded years ago by me or recently by you, if you think we can do something to improve consistency go for it")
25. **Overlapping mover labels:** where movers overlap in edit mode, only the one under the mouse shows its label. ("yeah it's pretty unreadable, that's a good call. we can grab the names from the swap tooltip anyways when we need them")

## 2026-11-13, the last four questions

26. **The slider keeps today's look:** a light knob over a blue fill. ("That's fine with me")
27. **Rows inside a menu are the page's rows:** 38 tall, in a 400-wide menu. ("A works for me!")
28. **Thin's default background matches Thick's.** "lets actually just update thin's default background color to match the thick's default to keep everything consistent". This also settles the grey and red text's contrast under Thin.
29. **Hover and selection tints: two strengths, by meaning.** 25% for any hovered or selected row, everywhere; 15% for a selected object's fill, such as a mover. ("Sounds good.")
30. **The action buttons' hover highlight is too strong** and hides the icon: it is dimmed. "the highlight on the action buttons is pretty powerful and makes it hard to see the icon ... we should probably dim it"

## 2026-11-13, edit mode

31. **Which movers show is two toggles, Show disabled and Show hidden,** not a switch: showing frames' movers always show. ("what if this is actually just two buttons 'Show disabled' and 'Show hidden'?")
32. **The history tracks every change,** in two parts: first what edit mode and bulk actions change, then every setting changed in `/sui`. ("I think it should track everything, if you want to split it into two parts that's totally fine with me.")
33. **What counts as one step is to be settled from research** into well-designed history systems, so a run of small nudges can't flood the list; building starts with the first definition and is adjusted. ("if someone decides to nudge the frame 16 pixels one pixel at a time does that become 16 entries in the history? that could flood it and wipe out meaningful changes easily.")

## 2026-11-13, the window's sizes and the colour picker

34. **With the sidebar collapsed, Search, Edit mode and Keybind mode are icon buttons in the footer.** ("I like the sidebar collapse items going to the footer")
35. **The unit frames' profile control leaves the footer** and sits beside the Unit dropdown. ("unitframe profile is probably going to have to move")
36. **The SaftUI name: "Saft" in the text colour, "UI" in the accent.** ("Lets go with accent choice A.")
37. **`/sui` remembers its size,** and everything of the config hides in combat, the mini bar included.
38. **SaftUI gets its own colour picker** (the third drawn), and Blizzard's colour picker is skinned as well. ("That third color picker is awesome, I'm okay with the additional work so lets do it. Lets also skin the blizzard color picker anyways just to make it look nice")
39. **At half size the bags' category list is a menu on a button,** still dragged to reorder there; the rule editor takes the width. ("I really like the 'list in a menu on a button' mockup, lets go with that for the build")
40. **The size buttons wear `minimize-2` (shrink) and `maximize-2` (grow), shrink at the left of the pair.** This replaces the chevrons and their order (decision 1 of the sizes spec). ("can we switch the grow and shrink icons ... to use minimize-2 and maximize-2? keep the minimize button left of the maximize one")

## 2026-11-14, from the in-game pass

41. **The pixel font stays for now.** The candidates load, but "when playing with the scaling while on 1080p homespun actually looks great at .75 so I think we'll stick with it for now." This sets aside decision 12's direction until the scaling work; the font demo (`/suifonts`) stays until then.
42. **Edit mode's defaults are confirmed:** Show hidden on, Show disabled off. ("show hidden and disabled defaults are good")
43. **The bags' category list:** beside the editor at full, a menu on a button at half. ("bags categorie config looks good in both sizes")
44. **SaftUI's config windows are see-through like the rest of the UI:** the `/sui` window, edit mode's bar and window, the History list. ("can we get transparency on the saftui config windows? (settings, edit mode, history, etc.)")
45. **The color picker's two blocks have no words:** the opening color, a chevron-right, the chosen color.
46. **`/sui`'s size buttons wear `minimize-2` and `maximize-2`,** shrink at the left. (decision 40 has the detail)
47. **The docked edit mode bar is two rows, only as wide as it needs, slides along the top from the middle, and can hide until hovered.** "The edit mode bar can probably just shrink down to how ever wide it needs to be, right now it does look really weird overlapping the minimap and micromenu. Having it hideable unless moused over like the windows/mac task bar would be great as well. Maybe we make it two rows tall to minimize it's width and make it slideable along the top?" and, from the mockup, "two rows is good, default to middle and make it draggable, can we get a button to toggle the hide until until hovered? we can alternate the icon between square-mouse-pointer and square-dashed-mouse-pointer as well as the normal blue enabled state". The bar is the wider of its two rows plus padding, and slides along the top edge by its blank parts; the hide toggle wears `square-mouse-pointer` off and `square-dashed-mouse-pointer` on, in the accent while on. While hidden, a 2 px accent strip marks the top edge where it sits; it covers nothing, so `/sui` and the movers keep the strip. (Replaces the full-width bar of decision 5.)
48. **Colors are named for what they are for, not their hue.** Text, Muted, Strong, Danger, Warning, Caution, Success, Shared; Blue becomes the theme's accent; loot rolls, factions and roles get groups of their own; the diff marker is Muted and a bar's own setting is the accent; the equipped item's border is the accent; the Buttons opacity sliders are made to work; Strong (white) stays apart from Text. Built (color roles, Tasks 1–5): Roles, Factions and Loot (Task 1), the accent (Task 2), Muted (Task 3: Text > Grey and Buttons > Grey are one Text > Muted, the diff icon and the bag categories' edited marker take it), the state colors (Task 4: Strong, Danger, Warning, Caution, Success and Shared, and Buttons > Danger; every Text, Roles, Factions, Loot and accent read goes through `st:Color`), and the Buttons opacity (Task 5: the defaults are 100%, every Buttons read is `st:ColorRGBA('button', key, strength)`, and a saved opacity goes back to 100% once, since none was ever drawn). (`25-colour-roles.md` has his answers word for word)
49. **Text > Grey (Muted since color roles, Task 3) is #b4b4b4 (180, 180, 180), and section notes are drawn at 15.** Looking at `/sui`, now see-through over the game world, he said the greyed text "feels a bit dim and the font size of the descriptions for the sections is a bit small", and chose the grey: "#b4b4b4 is good, lets switch to that." Grey was #969696 (150); it reads 8.0:1 on Thick's backdrop and 6.1:1 on Thin's (was 5.6:1 and 4.3:1). Notes under section titles take a `note` style, 15 like values and the page description, in place of `small` (13); the hover line and the other small text stay 13. Buttons > Grey stayed 150 until it folded into Muted (Task 3, which drops a customised Buttons > Grey). A profile that never changed Grey gets the new default; one that customised it keeps its colour, as Muted.

## 2026-11-15, the picker's preview

51. **The color picker's preview sits under the square (placement A),** a strip 64 tall with a "Preview" caption above it; the picker is 94 taller when an option has one (436, not 342).
52. **The picker has no Class colors row.** The Colors page edits those; Last used stays, and moves up into the row's place (248, or 342 under a preview).

## 2026-11-15, the reset

50. **Every setting has a reset.** One rule for every row: a default from the AceDB defaults by where the setting is saved, a reset icon while it differs, and the section Reset buttons that were left (the Categories editor's and Reset all) replaced by per-setting resets. ("Yep that sounds good")
