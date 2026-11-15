# CloseButton

SaftUI's close button: a 24px square Box with Lucide's `x` in grey, which turns red on a dark red fill under the mouse.

## When to use

The top right of every SaftUI window and dialog that can close: bag, bank and combined bank windows, the item ref tooltip, `/sui`, the small dialog. Make it with `st:CreateCloseButton(frame)`; a header places it `close-inset` (10) in from its right.

## What the consumer provides

The frame it closes. The icon rule asks for a tooltip, "Close". The `/sui` window's X has it ("Close", "Closes the options window. Esc does too."); the other windows' show none yet (`panels.lua`, OnEnter only changes the look).

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Button | 24 x 24 Box: `kit-field` inside a 1px `kit-edge`, a `kit-alt` line outside | `close-size` |
| Icon | `x` drawn 20 (a 10px cross), `text-muted` | `icon-close`, `text-muted` |
| Under the mouse | fill `close-fill`, edge and X `text-danger` | `close-fill`, `text-danger` |
| Pressed | the X moves down 1px | `line-width` |
| In a header | 10 in from its right | `close-inset` |
| On `/sui` | 16 in, 14 down; on the small dialog 14 and 14 | `window-close-x`, `window-close-y` |

## Blizzard theme

Blizzard's red close button, 28 on Forever and 24 on retail, sitting in the metal's socket (`st:CloseButtonInSocket`).

## Known gaps

- It paints the options kit's fixed palette on every window, so under Thin (and under a recoloured Thick) it keeps Thick's default colours while the view buttons beside it follow the theme (Discrepancies, first).
- Its red fill is a copy of `templates.close`, which has no option.
- The mockup drew a 20 box with a 12px cross on the window's fill; the code's 24 box with a 10px cross is shown.
- The loot popup still hands Blizzard's button to `st:CreateHeader`, which draws the old 20 x 10 red strip.

## Do and don't

- Do use `st:CreateCloseButton`; don't draw a close of your own.
- Don't use a letter or another glyph for close: it is Lucide's `x`.
