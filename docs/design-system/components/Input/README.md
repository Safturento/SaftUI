# Input

A one-line text box: a 170 x 24 Box with its text 8 in, its edge in accent while it has focus, and its body tinted under the mouse.

## When to use

Free text (a name, a frame to anchor to) and numbers with no sensible range (width, height: use the `width`/`height` generators, which show and save numbers). The window's and the sidebar's search box is the same look with a grey hint.

## What the consumer provides

`get`/`set` (an Ace `input` is text both ways: its `set` gets a string), `validate` for what it can't take, `name`, `desc`, `size = 'small'` for a 60-wide box.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Box | 170 x 24 (small: 60), Box look | `control-width`, `input-small`, `field-height` |
| Text | `field` in `text`, 8 in from each side | `list-text` |
| Hint (search only) | `field` in `text-muted` | `text-muted` |

## States

- Under the mouse: the body tints in the lighter tone (`state-hover`); the edge stays. While focused: the edge turns `accent`. Enter commits, Esc reverts; both clear focus.
- A value `validate` refuses shows its message in the window's status line, `text-danger`.
- Disabled: `alpha-disabled`; it loses focus.

## Blizzard theme

`InputBoxTemplate` art across whatever width the box has; the search box takes `SearchBoxTemplate` with its glass icon.

## Other text boxes in the code (not the standard)

Core's `st:CreateEditBox` (the bag window's search, the chat edit box) is drawn as `control` in the theme, 20 tall, with an `accent` focus border (it was white), and the bag search takes the bag title font. The bags' rule editor fields are 22 tall. See Discrepancies.

## Do and don't

- Do use a small input for short numbers in a quarter cell.
- Don't use an input where a range or select fits.
- Don't mark focus in white: focus is `accent`.
