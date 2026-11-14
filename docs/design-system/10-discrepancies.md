# Discrepancies

Places where SaftUI does one thing two or more ways, ranked by how often a player sees them: first what shows in the world every session, then what shows each time `/sui` opens, then the mockups and docs against the code, then the code's own housekeeping. Each says where it is, the ways it is done, and the standard this system recommends. Paths are repo-relative.

## Seen in the world, every session

**1. The close button wears the options kit's colours, not the theme's.**
Where: `st:CreateCloseButton` (`SaftUI-Core/panels.lua:330-414`) on every bag, bank and combined bank window (`SaftUI-Bags/container.lua:30`) and the item ref tooltip (`SaftUI-Misc/tooltip.lua:186`).
Two ways: the close X paints the fixed `kit-field`/`kit-edge`/`kit-alt` while the view buttons beside it in the same title bar are drawn `control` in the window's theme (`SaftUI-Bags/header.lua:141`). Under Thin, and under a recoloured Thick, the X keeps Thick's default colours. Its hover red is a literal copy (`panels.lua:361`) of `templates.close` (`defaults.lua:89`), which has no option.
Standard: draw it in the window's theme (`close` kind for the fill, the theme's border), read the red from `close-fill`. Decide with unknown 1.

**2. Fonts don't follow the font they were copied from.**
Where: action bar hotkey, count and macro texts (`SaftUI-ActionBars/config.lua:101-111`) and buff and debuff duration and count (`SaftUI-Misc/config.lua:125-135`) copy Pixel's face, size and outline at file load. The Fonts tab's "Button text" reaches only the totem bar (`SaftUI-Core/Media/fonts.lua:102-103`); every `st:CreateButton` is Pixel, hard-coded (`SaftUI-Core/Widgets/button.lua:5,215`).
Two ways: a font object key that follows the Fonts tab, against a copied face that doesn't. Changing Pixel changes unit frames, bags and chat tabs but not hotkeys or buff timers.
Standard: every text names a role that follows by default (the font roles followup, `docs/followups.md:1166`; Code changes 3).

**3. Hover, pressed and "on" have about nine looks.**
Where: listed in the audit's state colours. Hover: an `accent` edge (kit), `accent-fill` at 25% (kit lists, sidebar), `#222` (sidebar), 10% and 15% blue (Categories, rule editor), Buttons > Normal (Core buttons), Buttons > Hover at 40% (micro buttons), Buttons > Blue added (icon buttons), grey to red (close), grey to white (links, nudges). Pressed: text down 1px, Buttons > Pushed, black 10%, Buttons > Pushed at 60%. On: an accent square (kit), a box filled in Buttons > Hover (Core check box), green text (edit mode footer), an accent border (bag view button). Focus: white (`SaftUI-Core/skinning.lua:328`) against `accent` (`optionsdialog.lua:120`).
Standard: the kit's set (README, States): hover `accent` edge or `accent-fill`; pressed 1px down; on the accent square or an `accent` edge; focus `accent`. Icon buttons keep their own set. Rename Buttons > Normal and Hover in the UI for what they do (Code changes 9).

**4. Letters and hand-drawn glyphs where Lucide is the rule, mostly without tooltips.**
Where: the loot feed's "F" (filter) and "V" (scroll to newest), 20 x 20 (`SaftUI-Loot/Feed/filter.lua:52-53`, `Feed/feed.lua:618-619`); the bag view glyphs drawn from rectangles (`SaftUI-Bags/header.lua:38-47`); the drag handle's dots (`SaftUI-Bags/dragparts.lua:68-73`); the resize corner (`skinning.lua:440`, `optionsresize.lua:176`); hand-made funnel, eye and mail TGAs (`constants.lua:58-63`); the position nudges' triangles (`optionsposition.lua:97-107`).
Standard: Lucide with a tooltip: `funnel`, `chevrons-down`, `square`, `layout-grid`, `grip`, `rows-3`, `grip-vertical`, `eye`, `eye-off`, `mail`, `chevron-up`/`chevron-down` (Code changes 5).

**5. Edit mode labels pile up where movers overlap.**
Where: bars 4 to 8 and the extra buttons in edit mode; labels in Pixel centred on each mover (`EditMode/mover.lua`).
Two ways: a label per mover, and the picker list by the cursor that names every mover under it.
Standard: keep the picker as the way through; consider hiding a mover's label while another overlapping mover is under the mouse. An open question for the owner, not yet a rule.

**6. Three scroll bar looks.**
Where: the kit's 3px `kit-edge` bar (`optionsbody.lua:263-271`, and a copy in the select list, `optionslist.lua:176-179`); Core's skinned MinimalScrollBar with a Buttons-coloured thumb on bags and chat (`Widgets/scrollbar.lua:7-11,54-76`, `chatframe.lua:57`); RestedXP's 4px bar on black 50% (`restedxp.lua:277-287`).
Standard: the kit's bar everywhere SaftUI owns the scroll frame (Code changes 8).

**7. Two search boxes.**
Where: the kit's (Box, `field` 15, grey hint) and the bag window's (`st:CreateEditBox` with `SearchBoxTemplate` passed as the multi-line flag, 20 tall, white focus border, the bag titles' font: `SaftUI-Bags/search.lua:9-12`, `Widgets/editbox.lua:3-13`; followup "Bag search box is made multi-line", `docs/followups.md:349`).
Standard: the kit's `Input` look, `accent` focus, `field-height`.

**8. Menus in the world are Blizzard's, unskinned.**
Where: the bag slot menu (`SaftUI-Bags/slot.lua:381`) and the loot feed filter (`Widgets/dropdown.lua:4`) use `MenuUtil`; the kit's list and the planned item menu are SaftUI's.
Standard: SaftUI's list look (`Select`'s open list) for SaftUI's own menus; leave Blizzard's context menus where Blizzard owns them.

**9. Chat tabs have no selected or hover look.**
Where: `SaftUI-Chat/chatframe.lua:88-91`: textures stripped, Pixel text in Blizzard's tab colours (yellow in the screenshots).
Standard: the tab's text in `text` when current and `text-grey` otherwise, with a 2px `accent` underline, as `/sui`'s tabs.

**10. Disabled and dim have three values.**
Where: alpha 0.4 (kit, picker), 0.35 (locked roll buttons, `SaftUI-Loot/rollbar.lua:27`), a black 40% overlay (`Widgets/button.lua:273`, `skinning.lua:298`, `micromenuitems.lua:49`).
Standard: `alpha-disabled` (0.4) on the whole control.

**11. Icon button states are written three times.**
Where: action buttons (`SaftUI-ActionBars/skin.lua:349-450`), totem buttons (`SaftUI-Misc/totemskin.lua:270-310`), `st:SkinActionButton` for slots (`skinning.lua:134-310`), with the same literals; the countdown size rule three times (`ActionBars/skin.lua:283-285`, `totemskin.lua:325`, `Blizzard_CooldownViewer.lua:163-167`); roll bar layout twice (`rollbar.lua:125-210`, `roll.lua:105-235`).
Two ways: identical today, so the player sees one look; they will drift.
Standard: one state skin (Code changes 6).

**12. The item tooltip's lines.**
Where: Misc's skin sets the Normal font on every line (`SaftUI-Misc/tooltip.lua:46-58`), including the compare tooltips; the screenshot notes read the lines as Blizzard's. The Bags add "Category:" in `accent` and "Caught by:" in `text-yellow` (`SaftUI-Bags/slot.lua:215-250`).
Standard: unsettled; see unknown 9.

## Seen in /sui, every time it opens

**13. Grey and red text miss contrast under Thin.**
Where: `text-grey` (#969696) on Thin's `backdrop` (#333333) is 4.3:1 and `text-red` 3.6:1: the page description, section titles and notes outside the panels, and the status line. On `panel-fill` grey passes (5.2:1) and red is still short (4.4:1).
Two ways: the colours were chosen against Thick's #1f1f1f (5.6:1, 4.8:1).
Standard: keep the colours exact (they are the profile's); if the owner wants Thin readable, lighten Thin's backdrop a step or let small grey text sit on panels only.

**14. The kit's controls are Thick's colours, frozen.**
Where: every control, the list, the confirm and the close X use `st.BOX_COLORS` (`SaftUI-Core/constants.lua:32-37`; `optionslook.lua:17`), equal to Thick's default colours but not linked to them.
Two ways: under Thin the window is drawn in Thin's #333333 with a black line (`optionswindow.lua:676`) while every control inside keeps Thick's two-line edge; a recoloured Thick border changes the window and not the controls.
Standard: decide with unknown 1; until then this system documents the kit palette as fixed.

**15. Six buttons, five heights.**
Where: the footer with edit mode on: Grid and Snap as Core buttons (Pixel 10, 22 tall, green or grey text: `EditMode/footer.lua:10,70-72`, `settings.lua:22-25`) beside Reload UI and Close (Box, `field` 15, 26 tall: `optionswindow.lua:227-240`). Elsewhere: execute 26 in `kit-bg`; the confirm's Yes and No 80 x 24 in `kit-field`; keybind mode's Done 60 x 16 Pixel (`keybindmode.lua:220-221`); loot F and V 20 x 20; bag header buttons 23.
Standard: `Button` at `button-height` in `/sui`; one button component with an in-world size (Code changes 4).

**16. The colour bar's white code is hard to read on light colours.**
Where: Global Settings > Colors: Text > Normal (#E6E6CC), White, Grey; any light class or quality colour. White on those fills is 1.3:1 to 3:1; only the black outline carries it.
Two ways: the code is always white (`optionstypes.lua:171-174`, `.agents/edit-mode.md`); a followup paragraph says it turns black or white by brightness (`docs/followups.md:285`), which the code never did.
Standard: unsettled (unknown 10). Fix the followup paragraph either way.
Settled (decisions 9 and 13) and built: the control is a field, the code beside the swatch in `text` on `kit-field` (`ColorBar`).

**17. Section Reset buttons against per-setting reset, and where they sit.**
Where: Colors' Text, Buttons, Status and Threat Resets float left under the panel; Class, Reaction, Power and Item quality keep theirs on the panel in the right half beside the last colour (`SaftUI-Core/Media/colors.lua:196-218`); Theme's Reset (`Media/theme.lua:145-160`); the cooldown numbers' Reset (`ActionBars/options.lua:237`); Categories' "Reset to default" and "Reset all".
Standard: the owner's rule: a `ResetIcon` per setting, shown only while it differs; no section or page Reset buttons.

**18. The Copy from dialog shows internal keys.**
Where: Unitframes > General > Copy from (`SaftUI-Unitframes/config/config.lua:205-300`): the settings list's labels are profile keys ("additionalpower", "grouproleindicator", "range_alpha"), and the title reads "Clone Player from.." (`:294`).
Standard: labels as the page names them ("Additional power", "Group role", "Range"); a title such as "Copy to Player".
Built (decision 17): each setting named as `/sui` names that part, sorted by name; the title "Copy to Player from"; the button right of the Unit dropdown.

**19. Empty cells beside lone rows.**
Where: Unitframes > General: Height alone with the divider beside an empty half; Health: "Custom" in a quarter, an empty quarter, then "Custom color" in a half.
Standard: acceptable by the layout rules, but order and size options so a line fills where it can; play it by ear.

**20. "Font" means two things, and the Fonts tab's labels are Title Case.**
Where: 15 pages' "Font" lists SaftUI's font objects (`generators.font`, `SaftUI-Core/Config/generators.lua:231-239`), while Action Bars' Text and Auras' texts list typefaces (`LSM30_Font`, `ActionBars/options.lua:196-199`, `Blizzard_BuffFramePosition.lua:641-644`). The Fonts tab says "Font Name", "Font Size", "Font Outline" (`fonts.lua:168,172,177`) beside "Shadow offset X" and "Line spacing".
Standard: one meaning per word after the font roles work; sentence case now ("Font", "Size", "Outline").

**21. Sidebar page names mix cases.**
Where: "Action Bars", "Micro Menu", "Totem Bar", "Swing Timer", "Global Settings" against "Unitframes" as one word (`Unitframes/config/config.lua:311`) and sentence-case nameplate pages; descs say "unit frames" (63 strings).
Standard: see unknown 7.

**22. Three check box sizes and two marks.**
Where: the kit's 18 with an accent square (`optionslook.lua:471-477`), the rule editor's 14 (`ruleeditor.lua:78`), Core's 12 filled in Buttons > Hover (`Widgets/checkbutton.lua:99,107-111`), a bag category filter's 8 (hidden).
Standard: `Toggle` (18, accent square) everywhere.

**23. The Bags' Categories tab speaks a second visual language.**
Where: `SaftUI-Bags/categoriestab.lua`, `ruleeditor.lua`: Box text boxes 22 tall (kit 24), 14 check boxes, a copied caret (`ruleeditor.lua:99-104`), its own selected row (a 3px bar, `categoriestab.lua:121,480`, against the sidebar's 2px), its own hovers (10%, 25%, 15%), two X sizes with no tooltips, blue "+ Block + Group" links, AND (blue) and OR (`text-orange`) rails and chips. Under Blizzard it keeps Box (`docs/followups.md:1015-1030`).
Standard: the kit's controls through exported looks (Code changes 7); the rails and chips may stay as the editor's own, in tokens.

**24. Dialog paddings and frames.**
Where: window pad 28 and close 16/14 (`optionswindow.lua:121,689`); small dialog pad 24, close 14/14, drawn `panel` not `window`, title Colus 26 not 34 (`optionssmalldialog.lua:57,144-152`); confirm 15 at the sides and 16 at the top (`optionsdialog.lua:100-107`); a header's close 10 in (`constants.lua:30`).
Standard: a written spacing scale (Code changes 10); until then use the tokens as they are.

**25. Closing buttons float 6 under the panel; the rule says 24.**
Where: `OB.FLOAT_GAP` = 6, the title's gap (`optionsbody.lua:133`); the small dialog then ends 24 under them (`optionssmalldialog.lua:39-40`).
Standard: the owner's rule, `float-gap` 24 above and below.

**26. Two oranges, two light blues, five reds, two blues.**
Where: diff #e0a040 (`optionsbody.lua:157`) against Text > Orange #dc9664 (rule editor OR, Categories "edited") and the Cooldown Manager's #ff8040 (`Blizzard_CooldownViewer.lua:86`); own #8fd8ff against Text > Cyan #78cafa; red as Text > Red, Buttons > Red, threat bad, the close fill and `|cFFFF0000` (`api.lua:129`); blue as the profile's 0/0.68/0.94 and the chat prefix `|cff00adef` (`api.lua:122`). None of the kit's own colours is on the Colors tab or follows the theme.
Standard: `diff` only for the diff icon, `own` only for own values, `accent` read from the profile everywhere (the chat prefix included), `text-red` for every error.

**27. Two divider colours on one Thick page.**
Where: `line` #2e2e2e for the tab rule, sidebar edge, footer and dialog lines (`optionsbody.lua:163,217`); `hairline` (white 7%) inside panels (`:150`); the position nudge divider in `kit-edge` (`optionsposition.lua:147`).
Standard: `line` for the window's structure, `hairline` inside panels; both are intended.

**28. Tooltip anchors vary.**
Where: the kit `ANCHOR_TOPLEFT` (3 sites); elsewhere `ANCHOR_RIGHT` (7), `ANCHOR_TOP` (3), `ANCHOR_NONE` (5), `ANCHOR_LEFT`, `ANCHOR_BOTTOMRIGHT`, `ANCHOR_BOTTOMLEFT`.
Standard: `ANCHOR_TOPLEFT` in `/sui`; in the world, wherever keeps the tooltip off the frame it explains.

**29. Icons without tooltips.**
Where: the close X (`panels.lua`, OnEnter changes only the look), the rule editor's and Categories' remove X, the loot feed's F and V.
Standard: every icon that replaces a word has a tooltip (the owner's rule).

## The mockups, spec and docs against the code

**30. The approved mockup against the code** (`actionbars-shared-v6.html`, the code wins in this system):
- Range knob: `accent` with no fill in the mockup (`:49`); `text` over an `accent` fill in the code (`optionsrange.lua:69,131,144`) and the 11-09 mockup.
- Close X: 20 with a 12px cross on the window's fill (`:135-136`); 24 with a 10px cross on `kit-field` (`panels.lua:334,349`).
- TO list: an `accent` border on #101010 (`:119`); the kit's list, `kit-edge` on `kit-bg` (`optionslist.lua:171`).
- Tooltip: a #101010 box with a grey source line (`:79-84`); GameTooltip with the desc in Blizzard's gold (`optionsbody.lua:546-547`).
- Picker: a segmented button row (`:27-29`); a dropdown.
- Menu rows 30 (`:70`) against page rows 38; menu 330 wide (part 1) against 400 (spec).
- Position captions 10 (`:88`) against 11; offset boxes 60 x 24 against 46 x 22; diff icon 15 against 16; reset 13 against 14.
- Fields: a 1px edge only (`:44`); the code's Box adds the `kit-alt` line outside every control.
- Hover line: Agency regular 13 (`:39`); the code's `small` is AgencyFB Bold 13.
- Accent: #00adef in the mockup and the audit; the profile's 0/0.68/0.94 is #00adf0, as the Colors tab reads it.
- Colus titles: letter-spaced 1px in the mockup; not in the code.

**31. The Action Bars page still has tabs.** General, Text, Visibility (`ActionBars/options.lua:332-360`) and a loose Cooldown numbers toggle at the top (`:454`); spec decisions 4 and 6 say no tabs and an Enable inside the Cooldown numbers item. Probably done in the `sb-task5` worktree.

**32. Registered icons with no use.** `chevronUp`, `ellipsis`, `ellipsisVertical`, `settings` (`constants.lua:74,77-79`); the nudges draw their own triangles beside the unused `chevronUp`.

**33. A stale followup.** "Colour swatches read as checkboxes" says the hex is "black or white by the brightness" (`docs/followups.md:285`); the code and `.agents/edit-mode.md` say always white.

**34. Spelling.** UI strings say "color" but one desc, "in the element's colour" (`SaftUI-Misc/totemoptions.lua:21`); 85 Lua comments say "colour"; the README has 5 "colour" to 22 "color", the followups 21 to 163.

**35. The loot popup's old close.** It hands Blizzard's close button to `st:CreateHeader`, which draws the old 20 x 10 red strip (`SaftUI-Loot/popup.lua:74`, `panels.lua:233-241`); the popup is on the "looks unused" list (`docs/followups.md:378`).

## The Blizzard theme, handled ad hoc

**36.** 33 files test for Blizzard themselves (`IsBlizzardLook`, `BlizzardLook()`, `look.name == 'blizzard'`, `DrawnTheme`), modules included: `Blizzard_BuffFrame.lua` (5), `nameplates/target.lua` (4), `updaters.lua` (3), `microbuttons.lua` (3), `categoriestab.lua` (3), and others. The kit asks with `'theme','theme'` (`optionslook.lua:135-137`), the mover with `'theme','solid'` (`mover.lua:92`).
Standard: one question, asked through the engine, per kind.

**37.** The toggle passes a literal 34 for the Blizzard row height (`optionstypes.lua:36`), not `OB.FLAT.rowHeight`.

## Contrast pairs kept exact

These are the code's colours and stay as they are here; the owner decides whether to change them.

| Pair | Thick | Thin | Floor |
| --- | --- | --- | --- |
| `text-grey` on `backdrop` | 5.6:1 | 4.3:1 | 4.5:1 |
| `text-red` on `backdrop` | 4.8:1 | 3.6:1 | 4.5:1 |
| `border` against `backdrop` | 1.9:1 | 1.7:1 | 3:1 for a line that carries meaning |
| `kit-edge` against `kit-field` | 2.2:1 | 2.2:1 | 3:1 for a control border |
| `dot-grey` on `kit-field` | 2.5:1 | 2.5:1 | 3:1 for a mark |
| `text` code on `kit-field`, beside a `ColorBar`'s swatch (was `white` on the colour, 1.3:1 and up) | 14.5:1 | same | 4.5:1 |
