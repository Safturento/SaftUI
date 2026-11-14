# Decisions

Answers the owner has given to the questions and discrepancies. Each stands as a rule from its date; the pages below it (Discrepancies, Questions, Code changes) and the components are updated as the work lands, and until then this page wins where they differ.

## 2026-11-13

1. **The options window follows the theme.** Its controls' lines follow the theme's (Thin's under Thin, a recoloured Thick's under that) while fields stay dark, and the in-world close button is drawn in its window's theme. (Question 1, option C.)
2. **Panels are see-through or solid across the whole UI from one theme setting, and `/sui` follows it too.** The theme's Background carries the opacity; every panel follows it, the options window included; an individual panel can still override. (New.)
3. **A colour and its opacity are one control.** Wherever a setting has both a colour and an opacity today (two rows, or a colour beside an Alpha slider), they become one colour control whose picker sets the opacity, as the theme's Background does. (New; the pairs still to convert are listed under Code changes once audited.)
4. **One button, one size.** A single button component for `/sui` and the world, at one height and in one font; no second size. The edit mode footer's mixed sizes and fonts are the example of what this ends. (Question 2, stricter than either option.)
5. **Edit mode's controls leave `/sui`'s footer** for a bar of their own across the top of the screen while edit mode is on, with toggles for which modules' movers show. Being designed (mockup `window-and-editmode-v1.html`). (New.)
6. **The `/sui` window collapses:** its sidebar can be collapsed, and the window shrinks to a half-width, one-column size and then to a small floating bar, and grows back. Being designed (same mockup). (New.)
7. **"On" is the accent colour,** never green text. **The accent is a theme colour** the player can change, with its own swatch in the Theme section. (Question 3, option A, plus the swatch.)
8. **`/sui` tooltips stay Blizzard's tooltip frame, with the description in SaftUI's normal text colour** in place of Blizzard's gold. (Question on tooltips.)
9. **The colour control's code is one colour everywhere.** Not black or white by brightness. The control is being redrawn with the code beside the swatch on the control's own dark field (mockup, part 1). (Question on the hex code's legibility.)
10. **Resets are per setting:** a `rotate-ccw` icon beside a control whose value differs from its default; no section or page Reset buttons. Built in the kit as the `default` option field. (Was already a rule; confirmed as general.)
11. **SaftUI scales with the display:** automatic from the screen's height against 1440, with a "UI size" slider to override; borders in whole pixels. A project, after the tokens are in code. (New; see the repo's followups.)
12. **The pixel font is likely to go** in favour of a face that reads well small at any scale; candidates are being compared in game (`/suifonts`). (New; undecided which.)

## 2026-11-13, later

13. **The colour control is a field with the swatch at its left and the code beside it** (mockup option C1): as wide as a dropdown, the code in the normal text colour on the field's dark fill, `· NN%` after it for an opacity, a see-through colour shown over a checker in the swatch. Replaces the bar with the code inside it.
14. **Colours named after a hue get role names.** The Colors page lets the player change "Blue", "Red" and the rest, which can then stop being blue or red. The owner: "maybe we should analyze how those specific entries are being used and consider renaming them accordingly? let the user decide what color truly belongs to that type of text." An analysis of every use is under way; the renames follow from it.
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
