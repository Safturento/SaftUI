# Select

A dropdown: a 170 x 24 Box showing the current choice with a grey `chevron-down` caret, opening a list of choices under it.

## When to use

A choice of three or more (Ace `select`), the page picker, the position block's TO. Two choices that read as on/off are a `Toggle`.

## What the consumer provides

`values` (key to shown name, or a function), `sorting` if the order matters, `get`/`set`, `name`, `desc`. `dialogControl = 'LSM30_Font'` lists each font in its own face (a list entry's `font` is the face it is drawn in, at 15 with no outline; an entry with none is in the field font). A font setting that holds a shared font or a typeface is a Font row, below.

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
- Caption entry (`caption = true`, a heading such as the page list's groups or the font list's "SaftUI fonts" and "Typefaces"): its label in `text-grey` in the headings' style (the sidebar's group font, set on the row outright so a face drawn in that row before never shows), no row under the mouse, a click does nothing and the list stays open. A list opens on its picked entry, or on the nearest caption above it when both fit the rows, so a shared font opens under "SaftUI fonts" with the fonts above it.
- Disabled entry (`disabled = true`): the row at `alpha-disabled`, no row under the mouse, not to be picked; the list stays open.

## Blizzard theme

The Settings dropdown (WowStyle2): its face follows the mouse, press, open and disabled; its glow spills 7 outside (4 on the position block's compact one); Blizzard's steppers sit either side where the choices fit (26 x 24). The list takes the Settings menu's border and background.

## Do and don't

- Do name choices as the player thinks of them ("Faded until moused over", "Top left").
- Do use the picker select only for "which thing is this page about" (Unit, Bar).
- Don't use a triangle or any other arrow: the caret is `chevron-down`.
- Don't copy the caret code: the bags' rule editor has its own copy today (see Discrepancies).

## Font row

A font setting (`generators.font`, type `font`; `SaftUI-Core/Config/optionsfont.lua`) holds a shared font's key or a typeface (a table of a shared font's fields). Its control is a select face with one slot after it:

| Part | Value | Tokens |
| --- | --- | --- |
| Face | the Select box, 170 x 24, showing the font's name drawn in its own face at 15, no outline | `control-width`, `field-height` |
| Slot | 16 x 24 at the row's right edge, a 16 icon in the middle: the `link` for a shared font, the three dots (Lucide `ellipsis-vertical`, as a menu item's) for a typeface, hidden with its room kept on a face-only row | `text-grey`, `accent` (white under Blizzard) |
| Gap | the face ends 4 before the slot (8 under Blizzard, whose dropdown art reaches 7 past the face); the control is 190 wide (194 under Blizzard) | |

- **The list** has two parts: a caption "SaftUI fonts" over the six shared fonts, each in its own face, then a caption "Typefaces" over every face LibSharedMedia lists, each in its own face. The picked entry is `accent`: the shared font, or the typeface by its face.
- **Picking** a shared font saves its key. Picking a typeface saves a table filled from what the row showed (a shared font's look, or the typeface's own fields) with the new face, so a face swap keeps the typeface's size and outline.
- **The link**'s tooltip names the font, says it is a shared font set on Global settings > Fonts and changes every text that uses it, and says "Click to go there." A click opens that font's Typeface row, its label in `accent`.
- **The dots** (a typeface picked) have the tooltip "Size, outline, shadow and line spacing for <face>" (only the fields the row's menu shows: chat's reads "Size, outline and shadow for <face>"). A click opens a menu as an item's dots do (400 wide, hanging from the dots, closed by Esc, a click outside, navigation and combat) titled "<row name>: <face>", with Size (1 to 100), Outline, Shadow offset X and Y (-5 to 5) and Line spacing (0 to 20), one to a line. A row may show fewer (chat's: no line spacing; the tooltip's: Size and Outline only). A change saves a whole new table, never an edit of the saved one. The menu closes when a shared font is picked.
- **A face-only row** (`faceOnly = true`, used inside an item's menu) has the same list, saves a typeface as its face's name alone, and never has a menu icon.
- A face LibSharedMedia no longer lists reads in the field font, with no entry picked.
- A reset by the row names the default by its font's name ("Header font goes back to its default: Heading."), never a file path.
