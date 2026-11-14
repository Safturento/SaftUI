# Row

One option on a page: its label on the left, its control right-aligned in its cell, in a quarter, a half or a whole line.

## When to use

Every option in `/sui` and in the small dialog. The body packs rows into lines by `size` and `order`; you don't place them.

## What the consumer provides

- `name` (the label, sentence case), `desc` (the label's tooltip; required on a finished page), `order`.
- `size`: `'small'` for a quarter (toggles, execute buttons and inputs only; a colour is never small), none for a half, `'wide'` for a line. Descriptions and position blocks always take a line.
- `disabled` and, while it's disabled, `disabledDesc` saying why.
- For a shared setting, the share fields (see `OwnMark`, `DiffIcon`, `ResetIcon`, `ApplyList`).

## Sizes

| Part | Value | Tokens |
| --- | --- | --- |
| Row | 38 tall under Thick and Thin, 34 under Blizzard | `row-height`, `row-height-flat` |
| Cell padding | 14 each side on a panel | `panel-pad` |
| Label | `label` in `text`, a 16 band, centred in the row | `label`, `label-band` |
| Label to control | 10 at least; the label is cut, never the control | `label-gap` |
| Quarter / half / line | 193.5 / 387 / 774 of the body, rounded down to whole pixels | `content-width` |
| Wide row | ends 24 before buttons at its line's end | `stop-gap` |
| Hover line | 14 under the label, which lifts to centre both | `hover-line` |

## States

- **Disabled**: the control at `alpha-disabled` (0.4), the label in `text-grey`; the control takes no mouse, so the row's tooltip shows and says why.
- **Own** (a shared setting): see `OwnMark`. The label turns `own`.
- **Differs**: see `DiffIcon`.
- A plain row never moves under the mouse; only a row with something to offer shows a hover line.

## Blizzard theme

Rows 34 tall in two columns 40 apart, quarters 24 apart, no panel or padding; each control takes its Settings art. An own mark sits at the cell's edge and the label moves 6 right (`mark-shift-flat`).

## Do and don't

- Do keep labels short enough to fit a quarter where the control is a check box ("Cooldown", with the menu titled "Cooldown numbers").
- Do align the control right in its cell, check boxes and colour bars too.
- Don't put a check box straight after its label: that layout was replaced.
- Don't use Ace's `width`.
