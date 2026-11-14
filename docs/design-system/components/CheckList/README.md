# CheckList

A list of things with a check box each, opened from a control: each click checks or unchecks one and applies at once.

## When to use

Picking several of a set where the page has no room for a row per item, through `W.OpenCheckList(owner, entries, isChecked, onToggle)`. When nothing should change until the player confirms, use the `ApplyList` instead. A multiselect on a page draws the same rows inline in a 170-wide Box (rows 22, inset 2 under Blizzard).

## What the consumer provides

The owner frame (the list opens under it), the entries (key and name), `isChecked(key)` and `onToggle(key)`.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| List | the dropdown list's frame: a Box in `kit-bg` with 1px insets, under its owner | `kit-bg`, `kit-edge`, `kit-alt` |
| Row | 22 tall; an 18 check box 6 in, the label 8 after it in `field` | `list-row`, `toggle-size`, `action-gap`, `list-text` |
| Row under the mouse | `accent-fill` | `accent-fill` |
| Long lists | 12 rows, then the kit's 3px scroll bar | `scrollbar-width` |

## States

Checked rows show the accent mark; a click anywhere on the row toggles it; Esc or a click outside closes the list.

## Blizzard theme

The Settings check box in each row, the list on the Settings menu's border and background.

## Do and don't

- Do keep entries' names as the player knows them.
- Don't use it for a choice of one: that is a `Select`.
