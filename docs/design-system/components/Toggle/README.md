# Toggle

The kit's check box: an 18px Box that shows "on" as an accent square 3px inside it.

## When to use

Any on/off option (Ace `toggle`), the Show box of a `MenuItem`, and the rows of a multiselect and a `CheckList`. Right-aligned in its cell like every control.

## What the consumer provides

`get` and `set` of a boolean, the row's `name` and `desc`. A toggle may be `'small'` (a quarter).

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Box | 18 x 18: `kit-field` inside a 1px `kit-edge`, a 1px `kit-alt` line outside | `toggle-size`, `kit-field`, `kit-edge`, `kit-alt` |
| Mark | an `accent` square 3 in from the box's outer edge (12 x 12) | `accent`, `check-inset` |

## States

- Off: the empty box. On (selected): the `accent` edge, the mark and the fade inside the box (`state-selected`).
- Under the mouse (the box itself): the body tints in the lighter tone (`state-hover`); the edge stays.
- Disabled: the box at `alpha-disabled`, the label `text-muted`; the box takes no mouse, so the row's tooltip shows and says why.
- Click toggles; while held the body tints darker (`state-pushed`).

## Blizzard theme

The Settings check box (30 x 29 art), in every place the kit draws a check box (rows, multiselects, check lists, the Show box of a menu item).

## Other check boxes in the code (not the standard)

- Core's `st:SkinCheckButton`: 12 x 12, a 2 in `accent` mark, the edge and the fade when checked, the hover tint under the mouse: the same states as the kit's (there is no Checked color).
- The bags' rule editor: 14 x 14.
- A bag category's filter box: 8 x 8 (hidden today).

New work uses this one; the others are listed under Discrepancies.

## Do and don't

- Do let the label say what "on" means ("Reverse fill", not "Fill direction").
- Don't use a toggle for a choice of more than two; use `Select`.
- Don't show on as green text or a filled box: "on" is the accent square.
