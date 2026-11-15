# ColorBar

A color option: a field as wide and tall as a dropdown, a swatch at its left and the color's hex code beside it in the normal text color, `#RRGGBB`, or `#RRGGBB · 60%` when it has opacity under 100%. (The folder keeps its name from when the control was a bar filled with the color; decision 13 made it this field.)

## When to use

Every color option (Ace `color`). A click anywhere on the field opens Blizzard's color picker, raised over the window.

## What the consumer provides

`get`/`set` of r, g, b (and a), `hasAlpha = true` when opacity matters, `name`, `desc`. A color is never `'small'`: its field is a dropdown's width.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Field | 170 x 24, Box: the field's fill, edge and outside line, as an input | `control-width`, `field-height`, `kit-field`, `kit-edge`, `kit-alt` |
| Swatch | 40 wide, the field's inner height (22), inside the edge: a 1px black line, the color a pixel in | `text-outline` |
| Line | 1px in the edge's color after the swatch | `kit-edge` |
| Opacity | a see-through color (under 100%) drawn at its alpha over a checker of 4px squares in two greys (#5A5A5A under, #8A8A8A every other square), so the opacity shows; a solid color over none | |
| Code | `field` in `text`, left-aligned 8 after the line (the field's text inset), ending 8 from the right | `field`, `text`, `list-text` |
| Code format | `#` and six uppercase hex digits; with `hasAlpha` under 100%, " · " and the whole percent | |

## With a toggle

A color option can carry a `toggle` (`get(info)`, `set(info, value)`, `offText`, optional `desc`): "use a custom color" and the color as one control, in place of a check box and a color field side by side. A check box (18 square, 4 in from the field's left, the kit's; Blizzard's check art under Blizzard) sits inside the field at its left, and the swatch and code start 30 further in (the swatch's black line 31 in from the field's left under Thick and Thin, its white square 33 in under Blizzard).

| State | The field shows |
| --- | --- |
| Ticked | box ticked, swatch and code as above; a click on the swatch or code opens the picker |
| Unticked | box empty; the swatch and code gone, `offText` in `text-muted` from where the swatch began (what the setting falls back to: "Class", "White"); a click on the field ticks the box and opens nothing |

The box takes its own click and has its own tooltip, which says what unticked means. The per-setting `ResetIcon` covers both the toggle and the color: it shows when either differs, and puts both back.

## States

- Under the mouse: the edge turns `accent`, as an input's.
- Disabled: `alpha-disabled`, label `text-muted`; it takes no mouse.
- While Blizzard's picker is open the swatch, the checker and the code follow the picked color live.

## Legibility

The code is ordinary field text, `text` on the field's dark fill (14.5:1 on `kit-field`), the same on every color (decision 9). It never sits on the color.

## Blizzard theme

The Settings dropdown's face (`common-dropdown-c-button`, with its hover, pressed and disabled states), outset 7 round the field as a select's, with no hover arrow (no list opens). Inside it, 3 in from the face's edge, Blizzard's `ColorSwatchTemplate` swatch at 40 x 18: a white square, a black one a pixel in, the color (and the checker) a pixel in again; the code 8 after it. The dropdown's face, not an input's art: the field opens something, as the selects beside it do, and an input's art would ask to be typed in.

## Do and don't

- Do give a color a half cell; its label says what it colors ("Custom color", "Border").
- Do put a per-setting `ResetIcon` beside it when it differs from its default, not a section Reset button. It sits where a select's does.
- Don't draw the code on the color, or color it by the fill's brightness: it is one color everywhere.
- Don't draw a bare swatch square: a swatch alone reads as a check box; the field reads as a control.
