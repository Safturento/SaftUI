# Select

A dropdown: a 170 x 24 Box showing the current choice with a grey `chevron-down` caret, opening a list of choices under it.

## When to use

A choice of three or more (Ace `select`), the page picker, the position block's TO. Two choices that read as on/off are a `Toggle`.

## What the consumer provides

`values` (key to shown name, or a function), `sorting` if the order matters, `get`/`set`, `name`, `desc`. `dialogControl = 'LSM30_Font'` lists each font in its own face.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Box | 170 x 24, Box look, text `field` 8 in | `control-width`, `field-height`, `list-text` |
| Caret | Lucide `chevron-down` drawn 16 (an 8 x 4 chevron), centred 12 in from the right, `text-grey` in every state; an open list doesn't flip it | `icon-chevron`, `caret-right`, `text-grey` |
| List | as wide as the box, Box look in `kit-bg` | `kit-bg` |
| List rows | 22 tall, text 8 in; up to 12 rows, then the kit's 3px scroll bar; the wheel moves 3 rows | `list-row`, `scrollbar-width` |
| Row under the mouse | `accent-fill` | `accent-fill` |
| Current choice | its text in `accent` | `accent` |
| Layer | `strata-popups`, over a click catcher (levels 50 and 60) | `level-list-catcher`, `level-list` |

## States

- Under the mouse: the box's edge turns `accent`.
- Disabled: the box at `alpha-disabled`, label `text-grey`.
- Open: a click outside or Esc closes it; a pick sets and closes.

## Blizzard theme

The Settings dropdown (WowStyle2): its face follows the mouse, press, open and disabled; its glow spills 7 outside (4 on the position block's compact one); Blizzard's steppers sit either side where the choices fit (26 x 24). The list takes the Settings menu's border and background.

## Do and don't

- Do name choices as the player thinks of them ("Faded until moused over", "Top left").
- Do use the picker select only for "which thing is this page about" (Unit, Bar).
- Don't use a triangle or any other arrow: the caret is `chevron-down`.
- Don't copy the caret code: the bags' rule editor has its own copy today (see Discrepancies).
