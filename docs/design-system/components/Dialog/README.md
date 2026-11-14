# Dialog

Two dialogs float over the `/sui` window: the small dialog, a titled panel of rows for a task of its own (Unit frame profiles, Copy from), and the confirm, a sentence with Yes and No (or a prompt with a text box).

## When to use

- **Small dialog** (`OW:OpenDialog(title, options)`, `optionssmalldialog.lua`): a task with several settings that shouldn't crowd the page, opened from a button on it.
- **Confirm / prompt** (`W.Confirm`, `W.Prompt`, `optionsdialog.lua`): before something that can't be undone (an option's `confirm`), or to ask for one word (a profile's name).

## What the consumer provides

- Small dialog: a title and an Ace options table drawn by the same body as a page, so `Section` and `Row` rules apply; closing buttons as execute rows at the end, which float.
- Confirm: the question (one or two sentences, ending in a question mark) and the answer callback. Prompt: also the starting text.

## Sizes

| | Small dialog | Confirm |
| --- | --- | --- |
| Width | 568, two columns of 240 inside 24 padding (`dialog-width`, `dialog-pad`) | 320, text 290 wide (`confirm-width`) |
| Drawn as | `panel` kind in the theme (a `sui-frame`) | a Box in `kit-bg` with its `kit-alt` line (fixed palette) |
| Title | `brand` (Colus 26), 24 in, 18 down (`dialog-title-top`), a `line` rule at 52 | none |
| Head | 58 (`dialog-head`), close 14 in and 14 down | text 16 from the top (`confirm-top`) |
| Body | up to 600, then it scrolls | the text, then a prompt's box 290 x 24 |
| Buttons | float under the panel, centred | Yes and No, 80 x 24 in `kit-field`, 12 apart (`button-gap`), 14 from the bottom |
| Foot | 24 under the buttons, 30 while the status line shows | |
| Layer | `strata-options`, `level-small-dialog` | `strata-popups`, `level-confirm`, over a click catcher |

## States

- The small dialog's status line (a failed validate) shows at its foot in `text-red`, and the foot grows to 30.
- Esc, the close X, closing the window and entering combat close the small dialog; it refuses to open in combat.
- A confirm button under the mouse takes the `accent` edge.

## Blizzard theme

The small dialog is drawn in the theme's `panel` art with flat rows (34, no panels, nothing floats) and a foot of 30. The confirm is drawn as a panel in the theme with Blizzard's panel buttons.

## Do and don't

- Do end a small dialog with its closing buttons on a line of their own, so they float.
- Do write the confirm as a question about the thing, naming it: 'Delete the profile "Raid"?'.
- Don't show internal keys as labels: name a setting as the page names it (the Copy from dialog's "Group role" and "Range", once "grouproleindicator" and "range_alpha").
- Don't put a panel behind the closing buttons.
