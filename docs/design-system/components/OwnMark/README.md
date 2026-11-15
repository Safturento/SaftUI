# OwnMark

The mark on a member's own setting: a 2px accent bar at the row's left and its label in the accent too (at `OB.OWN_STRENGTH`, 1), always visible, with a hover line under the label offering Own, reset and Apply to.

## When to use

Shared settings: a page of an "All" entry that members follow (All bars, later all units), and each member's page. On a member page, a setting the member has changed is its own and carries the mark until it is reset or applied to all. The kit draws it for any option that says it is shareable.

## What the consumer provides

The option's SaftUI-only share fields: whether it is the member's own, how to reset it, who differs and with what, who it can be applied to, and how to apply it (`SAFTUI_FIELDS`, `.agents/edit-mode.md`); and, for the tooltips' sentences, what a member is (`noun`, "bar"/"bars": "Every bar that keeps its own Spacing follows All bars again") and the page's name as a sentence reads it (`pageText`, "the Pet bar"). Row types that carry every piece: toggle, range, select, input, color; a position block carries the mark on its section title.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Mark | 2px wide, `accent`, 6 in from the row's top and bottom, 5 in from the cell's left (inside the panel's padding) | `mark-width`, `mark-inset`, `mark-x`, `accent` |
| Label | `accent` while the row isn't disabled | `accent` |
| Hover line | `small` 13 on a 14 line under the label, which lifts so both are centred in the row | `small`, `hover-line` |
| Line content | "Own" in `accent` (its tooltip: the name and the All value), the reset icon (`ResetIcon`), "· Apply to:" in `text-muted`, the links "All" and "Multiple" in `accent`, white under the mouse, "\|" in `text-muted`; 4 between words | `accent`, `white`, `text-muted`, `diff-gap`, `reset-gap` |

## States

- At rest: the mark and the accent label, no hover line.
- Under the mouse (anywhere on the row, its control and the line's links included): the hover line shows.
- A `MenuItem` is marked when its Show or anything in its menu is own.
- Disabled: the label goes `text-muted` like any disabled row's.

## Blizzard theme

Same colours. The mark sits at the cell's edge (`OB.FLAT.markX` 0) and the label moves 6 right to make room (`mark-shift-flat`).

## Do and don't

- Do keep state visible: the mark and the label colour are the state; the hover line only offers actions.
- Do show the hover line only on rows that offer something, so plain rows never move under the mouse.
- Don't use this mark for anything but a shared setting's own value.
- Don't show "own" on the All page: there the sign is the `DiffIcon`.
