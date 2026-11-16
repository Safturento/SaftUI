# MenuItem

A small part on one line: a Show box, the part's name and Lucide's `ellipsis-vertical`, which opens a menu titled with the part's name holding the part's settings. It comes in two shapes: the quarter item (the action bars' texts) and the **part row** (the unit frames' Parts), a half row with a summary.

## When to use

The owner's rule: a part with three or more settings, or with settings that only apply sometimes, is a menu item. Texts (hotkey, stack count, macro name, cooldown numbers, a unit's name and health text), icons (raid target, group role, ready check) and small parts (portrait, class power) qualify; big parts with their own colours, textures or filters (health, power, cast bar, auras) keep a tab. "Play it by ear" where a page feels crowded.

**The too-big rule (decision 67).** A part's menu, laid out under Thick at full size, is no taller than the options window's least height (`menu-max-height`, 700: `OW.LAYOUT.own.height`). A part over it is a tab, not a row (Additional power: a second row of tabs under Power). The code declares it in one list (`UF.PARTS`, `place = 'row'` or `'tab'`) and a test fails any row over the rule.

## What the consumer provides

- The item: the part's Show option (a toggle, the item's box), a short `name` that fits ("Cooldown"), the menu's title if longer ("Cooldown numbers").
- An item with no Show (no box) whose names should line up with the boxed items beside it: `reserveBox = true`, which keeps the box's room empty (a bar's Cooldown, a unit's Subtext).
- The menu: an option group (Font, Size, Outline, then the part's position block, last). Shared settings inside carry their own marks.
- For a **part row**: `summary`, a function returning the one word and its tooltip (the unit frames' word is what the part's position is attached to, decision 70).
- A part drawn in two places (Health text on General and on the Health tab) gives the second group `mirrorOf`, so the options kit finds, resets and searches the settings once.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Item | a quarter cell: check box, label, menu icon; four to a line, a hairline after each but the last | `toggle-size`, `label`, `hairline` |
| Part row | a half cell, two to a line at full size, one at half: check box, name, then the summary right-aligned in `field` in `text-muted`, then the reset arrow and the dots | `toggle-size`, `label`, `field`, `text-muted` |
| Summary | ends 6 before the reset arrow or the dots; left out when the room is under 24 | `reset-gap` |
| Menu icon | `ellipsis-vertical` 16, `text-muted`, the lighter tone of the Accent under the mouse (the glyph rule) | `icon-chevron`, `text-muted`, `accent-light` |
| Menu | about 400 wide, a frame in the theme above the window, its own click catcher; the body is a half body (376), so small rows (toggles, small ranges) sit two to a line and every other row has a line | `menu-width`, `strata-options` |
| Menu title | the part's name in `group-title`, `text-muted` | `group-title` |
| Menu rows | the body's rows | `row-height` |
| The rule's number | the tallest a menu may be | `menu-max-height` |

## States

- Off: the Show box empty, the label `text-muted`; the menu still opens.
- Own: the item is own-marked when its Show or anything inside its menu is a member's own (`OwnMark`); on the All page a `DiffIcon` follows the name.
- **Hover (part row, decision 69).** The row takes the hover tint (a Layer in the Accent's lighter tone at `state-hover`, under the text), from the row, its box, its dots or its summary. The hover line (Own, the reset arrow, Apply to: All | Multiple) takes the summary's place, in `small`, on the row's middle; the label does not lift, the row does not grow, nothing moves. Only the summary toggles; a row inside a menu keeps the lifting line. The tint is drawn under the Blizzard theme as well.
- **Click.** A left click on the row opens the menu, except on the box, the dots, the reset arrow, the diff icon and the hover line's links, which do what they do. Not in combat.
- **The dots' light (part row).** The dots rest in `text` (not `text-muted`) while any setting in the menu differs from its default (or is the member's own), with a tooltip saying how many ("2 settings here differ from their defaults."). The dots are the Accent while the menu is open.
- **The row's reset** is its Show box's: the arrow shows while the box differs from its default, and puts the box back. Each setting in the menu has its own reset; there is no whole-part reset (decision 50).
- Two levels at most: a row in a menu that has its own dots (a typeface Font row in a part's menu) opens a second menu over the first, which stays open and still; a click on the first menu or outside closes the second, then Esc or a click closes the first. A row of the second opens nothing.
- One first-level menu at a time; it closes on Esc, a click outside, a page change and the window closing; it stays on screen near the window's right and bottom edges; a dropdown or TO list opened inside draws above it.

## Status

Built. The quarter item is on the action bars' texts (hotkey, stack count, macro name, cooldown); the part row is on every unit frame page (Name, Subtext, Health text, Threat, Power text, Class power, Raid target, Raid role, Group role, Ready check, Quest). The preview shows both.

## Blizzard theme

The item's box is the Settings check box (about 12px wider than a quarter allows for "Cooldown numbers", hence "Cooldown"); the menu is drawn in the theme's panel art with flat rows. A part row's tint is SaftUI's own (as a search result's) and shows under Blizzard too.

## Do and don't

- Do put the part's position block last in its menu.
- Do keep the item's label to one or two words.
- Do declare a part whose menu is over `menu-max-height` a tab.
- Don't hang a menu off a setting row named for one of its settings ("Cooldown text size" holding more than size).
- Don't use `ellipsis` (horizontal) or `settings` for this; the owner chose `ellipsis-vertical`.
- Don't let a part row change height or move on hover; show the line in the summary's place.
