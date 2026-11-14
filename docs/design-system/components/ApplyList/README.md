# ApplyList

The list "Apply to: Multiple" opens: the members with a check box each and an Apply button under them; nothing changes until Apply.

## When to use

From a shared setting's hover line, "Multiple", through `W.OpenApplyList(owner, entries, onApply)`. On a member's page it lists the other members (the chosen ones take this value as their own, or simply follow when it equals the All value); on the All page it lists the members that own the setting (the chosen ones follow All again). It leaves out members a setting doesn't exist on (stack count and macro name on the pet and stance bars).

## What the consumer provides

The owner (the "Multiple" link), the entries (members, by name, in picker order) and `onApply(keys)`.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| List | the check list's frame and rows: 22 tall, an 18 box 6 in, the name 8 after | `list-row`, `toggle-size` |
| Apply | 80 x 24 in `kit-field`, as the confirm's buttons; 6 under the rows and 6 over the list's bottom edge | `execute-min`, `field-height`, `apply-gap` |
| Row under the mouse | `accent-fill` | `accent-fill` |

## States

- Checking rows changes nothing; Apply applies to every checked member and closes the list.
- The list closes with its row (a redraw that drops the row closes it), on Esc and on a click outside.

## Blizzard theme

The Settings check boxes and menu background; Apply is a panel button.

## Do and don't

- Do name members as the picker does ("Bar 4", "Pet").
- Don't apply on each click: that is the `CheckList`, for lists that change things at once.
