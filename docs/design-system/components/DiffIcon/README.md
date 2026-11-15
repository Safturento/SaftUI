# DiffIcon

Lucide's `diff` in `text-muted` after a setting's label on the All page, always visible, saying some member has its own value; its tooltip lists who and with what.

## When to use

On the page of an "All" entry (All bars), beside every shared setting that at least one member owns. Never on a member's page (there the sign is the `OwnMark`).

## What the consumer provides

The share fields' "who differs and with what": a list of member names and their values; for a `MenuItem`, each member with the names of the settings that differ ("Bar 3: Size, Position").

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Icon | `diff` drawn 16, tinted `text-muted` (Text > Muted, at `OB.DIFF_STRENGTH`, 1; it was orange until color roles, Task 3), 4 after the label's text; the label is cut to leave it room | `icon-diff`, `text-muted`, `diff-gap` |
| Tooltip | the setting's name in `text-strong`, "All bars: value", then two columns: member names, values in `accent` | `text-strong`, `tooltip-gold`, `accent` |
| Hover line | on the row: "Apply to: All \| Multiple" (here All makes every bar follow; Multiple lists the bars that own it) | `small`, `accent` |

## States

- Always shown while any member differs; it goes when none does.
- The tooltip opens on the icon only; the row's hover line offers Apply to.
- A new profile shows two diff icons on All bars (Buttons per row, Button size): true, and intended.

## Blizzard theme

Same icon and colour.

## Do and don't

- Do keep the full list in the tooltip, so it can be long without growing the row.
- Don't give the diff icon a colour of its own: it is Muted, a dimmed mark beside the label, and has no token of its own. Text > Warning (`text-warning`) is the bags' rule editor's OR, not this.
- Don't hide the icon until hover.
