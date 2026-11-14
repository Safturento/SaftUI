# ResetIcon

Lucide's `rotate-ccw` in accent, beside a control whose value differs from its default (or, on a member page, in its hover line), that puts that one setting back; it shows only while there is something to reset.

## When to use

The owner's rule, for every page: reset is per setting. A setting whose value differs from its default gets the icon; one at its default has none. On a member page of a shared setting the icon sits in the `OwnMark`'s hover line and makes the member follow the All entry again. There are no section or page Reset buttons; the Colors tab's section Resets, the Theme tab's Reset, the cooldown numbers' Reset and the Categories "Reset to default" are to move to this (see Discrepancies).

## What the consumer provides

What "default" is for the setting (AceDB's default, or the shared value), the reset function, and the tooltip text: "Reset" as the title and one line saying what happens ("Buttons per row follows All bars again. Bar 3's own value is dropped.", "Green goes back to its default, #3CF03C.").

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Icon | `rotate-ccw` drawn 14, `accent`; `white` under the mouse | `icon-reset`, `accent`, `white` |
| Beside a control | 6 before the control; on a `MenuItem`, right against its dots (their button has room round the glyph), so the name gives up only the icon and 4 | `reset-gap` |
| In the hover line | after "Own", 6 either side | `reset-gap` |
| Tooltip | title "Reset" in `white`, the line under it | `white` |

## States

Hidden at the default; shown and `accent` once the value differs; `white` under the mouse; a click resets and the icon goes.

## Status

Built for shared settings (`optionsshare.lua:286`). Beside a plain control is the rule, not yet built: this preview shows where it goes.

## Blizzard theme

Same icon and colours.

## Do and don't

- Do give it a tooltip; it replaces a word.
- Do let it go when the value is back at its default, so its presence means "changed".
- Don't reset a whole section with one button.
