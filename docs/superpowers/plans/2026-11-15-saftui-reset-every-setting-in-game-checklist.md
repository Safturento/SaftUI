# A reset on every setting: the in-game checklist

One list for the whole plan (`docs/superpowers/plans/2026-11-15-saftui-reset-every-setting.md`, Tasks 1 to 8), in the order to play it. Nothing here counts as verified until the owner confirms it in game. The tests run on stubs: they cover which value is written, which function is called and what shows when, not what the game draws. Nothing here needs a character, realm or account name.

Check on WoW Forever (the client played) first, then once on retail where a line says so. Turn on BugGrabber's log. Everything is at SaftUI's defaults unless a line says to change it.

G1 to G7 are the spec's checks (`docs/superpowers/specs/2026-11-15-saftui-reset-every-setting-design.md`, "In-game checks"), marked where they come up.

The rule being checked: every setting that differs from its default shows a small rotate arrow just left of its control; hover it for the default, click it to put that back. A setting at its default shows none. There are no Reset buttons on a page or a section. The rows that have no arrow by design are Chat's Width and Height, the Test modes (Unit frames, Loot), the Profile select, and a Position whose mover has no default (the durability figure's, the totem bar's).

## A. Check first: what the tests could not answer

1. **The arrow follows a slider drag (all pages).** On a page with sliders (Unit frames > Player > Health, or Action bars > All bars > Size), drag a slider away from its default and back. The arrow appears as soon as the value leaves the default and goes as soon as it returns, with no lag or stutter, and the label and the hover line follow it.
2. **A reset in combat.** Open `/sui` and change an action bar's or a unit frame's setting, then enter combat (a target dummy). Expected: `/sui` closes in combat and will not open until combat ends, so no arrow can be clicked. With edit mode, make a Position reset out of combat, enter combat and try Undo, Redo and Reset: each refuses with "Can't undo in combat.", "Can't redo in combat." or "Can't reset in combat." and changes nothing. No `ADDON_ACTION_BLOCKED`, and no Blizzard frame moves.
3. **The Loot window, the totem Timer font and the buffs' Duration and Stack count Font** (new in Task 8: their default now comes from where they are saved instead of from a hand-written default). Change each away from its default, click its arrow, and the setting goes back to Small text (or Text for the Loot window's Font) and the thing on screen follows at once: the loot window's names and counts, the totem timers, and the buff timers and stacks. Under Thick, Thin and Blizzard.
4. **Width and Height boxes** (Unit frames > General, each element's Size, the nameplates' General): type another width, the arrow shows; click it and the number goes back to its default, the frame follows. Chat's Width and Height show no arrow however far they are from Blizzard's size.

## B. Global settings (Task 2)

- **G1.** Global settings > Fonts > Kinds of text: pick another font for Button text, the arrow shows; click it, the default comes back and the arrow goes. In Bags, the Title font does the same and Heading comes back.
- Theme tab > Window titles: change a title font, the arrow resets it. The Theme row's arrow puts the theme back to Thick and the fonts follow; no error.
- Colors: change a color, its arrow puts the default back; the sections have no Reset button any more.
- General and Edit mode tabs: change a row, reset it with its own arrow.
- Switch to another profile and back with Global settings open: the arrows follow the profile at once.

## C. Unit frames and nameplates (Task 3)

- **G2.** Player > Health > a size, and Player's Position: change them, the arrows show; click each. The Position goes back to its default place and edit mode's Undo puts it where it was (History shows one Reset step).
- **A part anchored to a Global frame.** Player > Class power (or Focus > Castbar): set its Position to anchor to Global frame with a name, move it, then reset. The anchor, point and offsets all come back together; nothing is half-reset, and there is no Lua error.
- **A second unit frame profile.** Make a second unit frame profile (Unit frames > General, the Profile select), switch to it and change a setting: the arrow shows, and its reset writes that profile only. Switch back: the first profile's value is untouched.
- The Buffs Stealable border and the Debuffs Dispel type border: untick one, the arrow shows; click it and each hostility goes back to its own default (Stealable on for enemies only).
- A plate page's Subtext tab: change NPC titles or the Position, reset each.
- Enemy nameplates > Nameplates: reset it; the game asks to reload, as it does for a change. Friendly nameplates > Friendly plates resets with no question, as its change asks none.
- Boss, Party and Raid pages: a Layout and a Range row each reset. The Test mode rows show no arrow.

## D. Action bars (Task 4)

- **G6.** All bars > Cooldown: untick its Show; the arrow shows; click it and the cooldown numbers come back (Blizzard's own default).
- **G3 (the item menus).** All bars > Text: a text's Size in its dots menu and a toggle in a quarter cell. The arrow sits left of the control and the label is cut, never the control, at full and half size, under Thick, Thin and Blizzard.
- Bar 1: change a setting, then Apply to / the share line: the shared rows' own marks and the new arrows do not collide.
- The extra buttons (zone ability, extra action, leave vehicle): change Scale, reset it, and the button re-lays out at once.
- The pet and stance bars' rows reset as well.

## E. Bags and the Categories tab (Task 5)

- **G4.** (The rule row's arrow tooltip now reads "The rule goes back to its default: the rule SaftUI ships.".) Bags > Categories: rename a shipped category, turn it off, change Show in and its rule. Each row shows its own arrow and resets alone; there is no Reset button and Delete is not covered by anything.
- A rename that another category already uses: the reset is refused with "Another category is already called ..." on the status line and the arrow stays.
- **Show in on Forever's combined bank.** On Forever, hide a category in the combined bank from the bank window's own Edit view. The Show in arrow shows (it covers every window, even one Show in does not list) and its reset shows the category there again.
- **G5 and the order icon.** Drag a shipped category to another place; the order's arrow shows in the list footer. Hover it: "Order goes back to its default: SaftUI's order, with your own categories where they are." Click it and the shipped order comes back with your own categories where they were. The icon looks exactly like the other arrows (it is the same one now). At half width it is in the menu over the editor.
- The Bags page rows (Title font, Icon font, the windows' sizes and positions): each arrow resets. On Forever the combined bank's Position resets through its mover with an Undo step.
- Auto sell junk (Bags page): change it, and its arrow puts it back.

## F. Misc's pages (Task 6)

- Tooltip: Theme, Background and Font reset; with the bag window or the loot feed open the two snap toggles show an arrow when changed. The Position resets through its mover.
- Totem bar: a color, the Timer font and the offsets reset. Its Position has no arrow.
- Buffs and debuffs: Size, Spacing, Grow and Wrap reset. **Grow Up, then Grow's arrow:** Grow goes back, Wrap still shows its arrow (it is on the side Up kept), and one click on it gives a fresh page (two clicks in all).
- The Duration and Stack count Positions reset through the row's own parts. Their Size and Outline show only while the font is a typeface.
- Swing timer: each bar's Position and sizes reset.
- Skinning, Experience bars, Durability: a row each. The durability figure's Position has no arrow.
- Blizzard's tracker (Info): turn on Skinning > Objective tracker, change its Font and Header font, reset each and the tracker restyles. Its Position resets to Blizzard's own spot while SaftUI's tracker is off.

## G. Chat, Loot, Minimap, Micro menu and the Tracker (Task 7)

- **G7.** With resets showing, switch profiles: the arrows follow the new profile at once, on every page above.
- Chat: Font, Padding, Edit box height and Fade tabs reset (Fade tabs applies at once). Width and Height show none. The Position resets through its mover.
- Loot: the rolls' Spacing and Grow down, the feed's Spacing (the feed updates at once), the Loot window's four rows. Test mode shows no arrow.
- Minimap: Size (the minimap resizes), the Position; Micro menu: its rows and Position.
- **The nearest button's Position reset and Undo.** Tracker > Items: drag the nearest quest item button in edit mode, then reset its Position from `/sui`: it goes to its default place (the top right area) and edit mode's Undo puts it back where you dragged it. Do the same with the tracker's own Position.
- Tracker: each tab's rows (General, Items, Visibility, Blizzard's tracker) reset through their hand defaults; the tracker's Position resets with an Undo step.

## H. Layout and look (all pages)

- **G3.** On two or three pages (Unit frames > Player, Action bars > All bars, Bags > Categories), at full and half window size, under Thick, Thin and Blizzard: the arrow sits left of its control, the label is cut and never the control, a check box in a quarter cell keeps its art clear of the arrow, and the title row of a rule shows its arrow 6 after the title's text.
- Hover an arrow: the tooltip says "Reset", then "<name> goes back to its default: <the default in words>." A color shows its hex, a Position says where ("Top right of the screen: -320, -275", "Right of Health: -7, -1"), a font names its face or shared font.
- Resize the window while arrows show: nothing overlaps, nothing clips.
- A `/reload` and a log in on retail: no Lua error from the options window or any page.
