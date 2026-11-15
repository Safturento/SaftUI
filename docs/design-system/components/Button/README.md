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
- Disabled: the button at `alpha-disabled`, its label `text-muted`; it takes no mouse, so the row's tooltip says why.
- "On" (a button that stays lit, as the bag window's current view): an `accent` edge.

## Blizzard theme

Blizzard's panel button (`st:ShowPanelButton`), with its own pressed and disabled art; the window's Close sits 16 from the bottom right corner and Reload UI 12 left of it.

## Icon button

`W.IconButton`: a 26 x 26 button with only its 16 x 16 icon in the middle (edges at 5 and 21) in `text-muted`, in the same raised fill, edge and `accent` hover as the labelled one; the icon moves down 1px while pressed. It needs a tooltip, since an icon says nothing alone (the edit mode bar's buttons). `W.IconButton(parent, icon, tip, size, iconSize)` takes optional sizes, `(size - iconSize) / 2` whole: the `/sui` header's arrows are the close X's 24 with a 20 chevron, and the icon turns `accent` under the mouse with the edge. `W.IconLink` is the same icon with no box, `text-muted` at rest and `accent` under the mouse. A labelled button given an icon (`W.Button`'s `opts.icon`, `iconWithLabel`) draws it 16 before the label, 6 apart, the pair centred, 80 wide at least (icon + 6 + text + 28); `W.SetCompact` turns it into the icon alone, 26 square, for a narrow bar.

- "On" (the bar's lit buttons): the `accent` edge, kept when the mouse leaves, and the icon in `accent`. Under Blizzard's panel button the icon, or a text button's label, is `accent`, since it has no lit state.
- Disabled on the bar: the button at `alpha-disabled`, no hover edge, a click that does nothing, and the mouse kept so its tooltip says why.

## Other buttons in the code (not the standard)

Six kinds and five heights today: Core's `st:CreateButton`/`st:SkinButton` (drawn `control` in the theme, Pixel 10, `button-normal` highlight, `button-pushed` when held, black 40% when disabled) used by keybind mode's Done (60 x 16), the loot feed's F and V (20 x 20), the bag header's buttons (23). (Edit mode's footer buttons, 22 tall with `text-success` text when on, were of this kind until the edit mode bar replaced them with the kit's icon buttons.) The code changes propose one button component with two or three sizes; until then, build kit buttons with this look.

## Do and don't

- Do float a section's closing buttons; keep a line of buttons inside a section on the panel.
- Do keep labels to one to three words.
- Don't add a section or page Reset button: reset is per setting (`ResetIcon`).
- Don't signal "on" with green text.
