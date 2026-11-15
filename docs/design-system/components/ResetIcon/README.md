# ResetIcon

Lucide's `rotate-ccw` in `text-muted`, turning `accent` under the mouse, beside a control whose value differs from its default (or, on a member page, in its hover line), that puts that one setting back; it shows only while there is something to reset.

## When to use

The owner's rule, for every page: reset is per setting. A setting whose value differs from its default gets the icon; one at its default has none. On a member page of a shared setting the icon sits in the `OwnMark`'s hover line and makes the member follow the All entry again. There are no section or page Reset buttons; the Colors tab's section Resets, the Theme tab's Reset, the cooldown numbers' Reset and the Categories "Reset to default" are to move to this (see Discrepancies).

## What the consumer provides

Where the setting is saved, or a hand default, or why it has none. A group says where its settings are saved once, beside its `get` (`saved = st.Config.SavedIn('chat')`; an option with a `get` of its own `saved = st.Config.SavedAt('chat', 'position')`), and the kit reads the AceDB default at that path, so a page never writes a default twice. A value that is not one profile key (a colour with a toggle, a CVar, the bags' categories) gives a hand `default`; a mover's Position takes its mover's own default; a row with no default by its nature says why in `noReset` (Test mode: not saved; Chat's size). The reset function and the tooltip text are the kit's: "Reset" as the title and one line saying what happens ("Buttons per row follows All bars again. Bar 3's own value is dropped.", "Green goes back to its default, #3CF03C.", "Show in goes back to its default: Bags, Bank.", "Position goes back to its default: Top right of the screen: -320, -275.").

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Icon | `rotate-ccw` drawn 14, `text-muted` at rest; `accent` under the mouse | `icon-reset`, `text-muted`, `accent` |
| Beside a control | 6 before the control; on a `MenuItem`, right against its dots (their button has room round the glyph), so the name gives up only the icon and 4 | `reset-gap` |
| In the hover line | after "Own", 6 either side | `reset-gap` |
| Tooltip | title "Reset" in `text-strong`, the line under it | `text-strong` |

## States

Hidden at the default; shown in `text-muted` once the value differs; `accent` under the mouse; a click resets and the icon goes.

## The History list's revert

A relative of this icon: a row of the edit mode bar's History list ends in a 14px `rotate-ccw` that puts that one step's change back on its own, as a new step. It is grey at rest and `accent` under the mouse (the icon's usual hover is `text-strong`; here the accent matches the list's row fill), and it is dim and disabled, with its reason in red in the tooltip, when a later step touched the same frame ("Changed again later: go back to this point instead.") or the step was a bulk copy. It shows only for a step that is applied. It is the same per-change idea as a setting's reset, not a section Reset.

## Status

Built for every value row in `/sui` (decision 50): a derived default, a mover Position's, or a hand one, with the icon where the control draws, in an item's menu and beside a titled row's title (6 after its text). The kit, `optionsdefault.lua`, is built; each page declares its `saved` as its task lands (`tests/core/reset_coverage_test.lua` lists the pages not yet walked).

## Blizzard theme

Same icon and colours.

## Do and don't

- Do give it a tooltip; it replaces a word.
- Do let it go when the value is back at its default, so its presence means "changed".
- Don't reset a whole section with one button.
