# Button

The kit's button: a 26px Box in the raised fill, its label centred in the field font, at least 80 wide and 14 wider than its text on each side.

## When to use

An action (Ace `execute`): Copy from, Place..., New, Delete, Reload UI, Close. Settings are never buttons. A line that holds only buttons has no panel behind it; a section's or dialog's closing buttons float under the panel.

## What the consumer provides

`name` (the label: a verb, or a verb and its object, sentence case: "Confirm copy", "Reload UI"), `func`, `desc`, `confirm` when it can't be undone, `size = 'small'` for a quarter cell, and SaftUI's `align` (`'right'` or `'center'`) to line it up with the aligned buttons next to it.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Button | 26 tall; text width + 28, 80 at least | `button-height`, `execute-pad`, `execute-min` |
| Look | `kit-bg` inside a 1px `kit-edge`, a `kit-alt` line outside | `kit-bg`, `kit-edge`, `kit-alt` |
| Label | `field` in `text`, centred | `field` |
| In a line | 12 apart | `button-gap` |
| Confirm's buttons | 80 x 24 in `kit-field` | `execute-min`, `field-height`, `kit-field` |
| Floating line | `float-gap` under its panel and before what follows; centred in the body, or ending at its right edge | `float-gap` |

## States

- Under the mouse: the edge turns `accent`.
- Pressed: the label moves down 1px (`line-width`).
- Disabled: the button at `alpha-disabled`, its label `text-grey`; it takes no mouse, so the row's tooltip says why.
- "On" (a button that stays lit, as the bag window's current view): an `accent` edge.

## Blizzard theme

Blizzard's panel button (`st:ShowPanelButton`), with its own pressed and disabled art; the window's Reload UI and Close sit 16 from the corners.

## Other buttons in the code (not the standard)

Six kinds and five heights today: Core's `st:CreateButton`/`st:SkinButton` (drawn `control` in the theme, Pixel 10, `button-normal` highlight, `button-pushed` when held, black 40% when disabled) used by the edit mode footer (22 tall, on = `text-green` text, off = `text-grey`), keybind mode's Done (60 x 16), the loot feed's F and V (20 x 20), the bag header's buttons (23). The code changes propose one button component with two or three sizes; until then, build kit buttons with this look.

## Do and don't

- Do float a section's closing buttons; keep a line of buttons inside a section on the panel.
- Do keep labels to one to three words.
- Don't add a section or page Reset button: reset is per setting (`ResetIcon`).
- Don't signal "on" with green text.
