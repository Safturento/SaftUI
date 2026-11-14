# Section

A titled group of rows on a faded panel: the title in `section-title`, an optional note, then the rows in lines, divided by hairlines.

## When to use

Every group of options on a page or in a dialog. An Ace inline group (`inline = true`) or a `header` starts one; options after a nested group continue in an untitled section joined to the panel above.

## What the consumer provides

- `name`: the title (write it in sentence case; Colus shows it in capitals).
- `desc`: the note, a sentence saying what the section's settings do together, or what waits for a reload.
- Its options in `order`, each with a `size`: `'small'` (a quarter, toggles, buttons and inputs only), none (a half), `'wide'` (a line). Description and position rows always take a line.

## Anatomy and sizes (Thick and Thin)

| Part | Value | Tokens |
| --- | --- | --- |
| Gap before the title | 16 | `section-pad` |
| Title | Colus 15 in `text-grey`, 15 tall | `section-title`, `text-grey` |
| Note | 13 in `text-grey`, 4 under the title | `small`, `note-gap` |
| Title to panel | 6 | `title-gap` |
| Panel | black at 28% over the window, as wide as the body | `panel-fill`, `content-width` |
| Rows | 38 tall, padded 14 each side, no gap between columns | `row-height`, `panel-pad` |
| Column divider | a white 7% line between halves, and after each quarter but the last, as tall as its line | `hairline`, `line-width` |
| Line divider | a white 7% line at the top of every line but the first | `hairline` |
| Between sections | 14 | `section-margin` |
| Closing buttons | off the panel, floating `float-gap` under it with the same space after | `float-gap`, `button-gap` |

## The closing line

A line that holds only buttons and ends its section is not on the panel: it floats under it, on the window's fill, as tall as its buttons (`button-height`, not a row's 38), with no hairline or divider. A centred group sits in the body's middle, a right group ends at the body's right edge. A line of buttons in the middle of a section stays on the panel (Unit frame profiles' New to Import). The owner's rule is `float-gap` (24) above and below; the code today floats them 6 under the panel (`OB.FLOAT_GAP`) and the small dialog ends 24 under them.

## Blizzard theme

No panels and no hairlines: rows are 34 tall (`row-height-flat`) in two columns 40 apart (`column-gap-flat`), quarters 24 apart, with a `line` (#2e2e2e) between the halves of a line. Nothing floats.

## Do and don't

- Do keep a section's rows together; a line with an empty half is fine, but don't leave a lone quarter where a half would do.
- Do put a section's Reset where its rule says: per setting, with `ResetIcon`, not a button at the section's end.
- Don't put a panel behind a line of buttons alone.
- Don't stripe rows: the owner chose hairlines (mockup S2) over striped rows (S1).
