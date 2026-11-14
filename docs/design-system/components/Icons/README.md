# Icons

SaftUI's icons are Lucide's (lucide.dev, ISC licence), drawn at twice the glyph's size and tinted with a colour token, each standing in for a word and so carrying a tooltip.

## When to use

Wherever an icon fits (the owner's rule, from 2026-11-13 on): close, dropdown carets, reset, diff, menus, and every hand-drawn glyph or letter that stands for an action.

## What the consumer provides

The icon's name from `st.icons` (`x`, `chevronDown`, `chevronUp`, `rotateCcw`, `diff`, `ellipsis`, `ellipsisVertical`, `settings`, `funnel`, `arrowDownToLine`, and for the edit mode bar `logOut`, `grid3x3`, `magnet`, `alignStartVertical`, `layers`, `mapPin`, `eye`, `powerOff`, `search`, `undo2`, `redo2`, `history`, `pictureInPicture2`, `panelTop`, `squareMousePointer`, `squareDashedMousePointer`), its size, its colour, and a tooltip naming what it does.

## Rules

- **Files.** Each icon is `Media/Textures/lucide-<name>.tga`: 32 x 32, white on transparent, Lucide's 24 grid with the glyph in its middle half. Add one with `tools/lucide-to-tga.cjs` (its header says how), register it in `st.icons`; `tests/core/icons_test.lua` checks the files.
- **Size.** Draw at twice the glyph's size: `icon-close` 20 for a 10px cross, `icon-chevron` 16 for an 8 x 4 caret, `icon-diff` 16, `icon-reset` 14. Use an even size on a whole-pixel centre, so its edges are whole pixels.
- **Colour.** Tint with `SetVertexColor` from a token, never in the file: carets and the close X at rest `text-grey`; close X under the mouse `text-red`; reset `accent`, `white` under the mouse; diff `diff`; the menu icon `text-grey`, `accent` under the mouse.
- **Tooltip.** An icon that replaces a word says what it does in a tooltip ("Reset", "Close").
- **In HTML.** Inline the SVG on a 24 viewBox, stroke 2, round caps and joins, no fill; size and colour it with the same tokens.

## In use and registered

| Icon | Where | Drawn | Tint |
| --- | --- | --- | --- |
| `x` | close button; the rule editor's remove (20 in a 16 box); a pinned item's remove (16, an 8px cross, in a 14 box) | 20 | `text-grey`, `text-red` |
| `chevron-down` | dropdown caret; the rule editor's field (a copy) | 16 | `text-grey` |
| `rotate-ccw` | reset | 14 | `accent`, `white` |
| `diff` | diff icon | 16 | `diff` |
| `ellipsis-vertical` | the menu item's icon (spec; in the `sb-task5` build) | 16 | `text-grey`, `accent` |
| `chevron-up`, `chevron-down` | the position nudges (12 x 12, one texture per arrow) | 12 | `text-grey`, `text` |
| `log-out`, `grid-3x3`, `magnet`, `align-start-vertical`, `layers`, `map-pin`, `eye`, `power-off`, `search`, `undo-2`, `redo-2`, `history`, `picture-in-picture-2`, `panel-top`, `square-mouse-pointer`, `square-dashed-mouse-pointer` | the edit mode bar (registered with the kit's icon button; see Button) | 16 | `text-grey`, `accent` |
| `minimize-2`, `maximize-2` | the window's size buttons: shrink and grow, in the header and (grow) on the bar | 16 | `text-grey`, `accent` |
| `chevron-left`, `chevron-right` | the Categories tab's previous and next (the size buttons wore them until 2026-11-14) | 16 in the Categories tab's buttons | `text-grey`, `accent` |
| `panel-left-open`, `panel-left-close` | the /sui sidebar's toggle (registered; used by the window's sizes work) | 16 | `text-grey`, `accent` |
| `move` | the Edit mode button in /sui's collapsed footer (registered; used by the window's sizes work) | 16 | `text-grey`, `accent` |
| `keyboard` | the keybind mode command in /sui's collapsed footer (registered; used by the window's sizes work) | 16 | `text-grey`, `accent` |
| `list` | the Categories tab's category button (registered; used by the window's sizes work) | 16 | `text-grey`, `accent` |
| `map-pin` | SaftUI's tracker: after the current zone's name on its zone header | 16 (an 8 px glyph) | `accent` |
| `chevron-up`, `chevron-down` | SaftUI's tracker: the header's collapse button and each zone header's (up while it shows, down while collapsed; a 16 square button, hover white) | 16 (an 8 px glyph) | `text-grey`, `white` under the mouse |
| `ellipsis`, `settings` | registered, unused | | |

## To replace with Lucide

These are hand-made today and should become Lucide icons with tooltips: the loot feed's "F" and "V" letter buttons (`funnel`, `chevrons-down`), the bag view glyphs drawn from rectangles (`square`, `layout-grid`, `grip`, `rows-3`), the drag handle's 2 x 2 dots (`grip-vertical`), the resize corner, and the hand-made funnel, eye open and closed, and mail TGAs (`funnel`, `eye`, `eye-off`, `mail`).

## Do and don't

- Do keep icons line icons, in Lucide's stroke; never mix in a filled or emoji glyph.
- Don't bake colour into a TGA.
- Don't use an icon without a tooltip where it stands for a word.
