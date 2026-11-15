# Tooltip

The game's tooltip in SaftUI's theme: a `tooltip`-kind frame holding a white title line and wrapped lines under it, used for every row, icon and in-world frame that explains itself.

## When to use

- Every option row: its `desc` is its label's tooltip.
- Every icon that stands in for a word (reset, diff, links, close, the loot feed's buttons): the tooltip says what it does.
- A disabled row: the tooltip adds why, in Text > Danger.
- In the world: units, items, buttons, as Blizzard shows them, in SaftUI's frame.

## What the consumer provides

- The title (the option's name, or what the icon does in two or three words).
- The lines: the desc (one or two sentences), and for a disabled option its `disabledDesc`.
- The owner frame and anchor. The kit anchors `ANCHOR_TOPLEFT`; nothing else agrees yet (see Discrepancies).

## How the code draws it

| Part | Value | Tokens |
| --- | --- | --- |
| Frame | GameTooltip drawn as the `tooltip` kind by Misc's skin (`st:SetBackdropIn`), see-through at 0.9 | `backdrop`, `border`, `alpha-theme` |
| Lines | the Normal font object on every line (AgencyFB Bold 16, OUTLINE) | `normal` |
| Title | white (`text-strong`'s value; the game's title, hardcoded) | `text-strong` |
| Desc | GameTooltip's default line colour, Blizzard's gold, because the kit passes none | `tooltip-gold` |
| Why it's disabled | Text > Danger | `text-danger` |
| Diff tooltip | the name, "All bars: value", then two columns: member names, then their values in the accent | `accent` |
| Unit tooltips | the border and status bar in the unit's class or reaction colour | `class-*`, `reaction-*` |
| Item tooltips | the border in the item's quality colour; the Bags add "Category:" in blue and "Caught by:" in yellow | `quality-*`, `accent`, `text-caution` |

Padding and line spacing are Blizzard's.

## The mockup's tooltip (not built)

The approved mockup drew its own tooltip: a `#101010` box with a black outer line, a white 16 title, a grey source line, `text` for the rest (`actionbars-shared-v6.html:79-84`). The code kept GameTooltip. Which one is the standard is an open question; this preview shows the code's.

## Blizzard theme

The tooltip kind takes Blizzard's tooltip border art; lines and colours are unchanged.

## Do and don't

- Do write the desc as what the setting does, in a sentence, not a repeat of its name.
- Do name a path with ">" ("Global settings > Theme").
- Don't rely on hover alone to show a state; a tooltip explains, it never is the only sign.
- Don't colour words in a desc for emphasis.
