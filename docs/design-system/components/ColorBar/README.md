# ColorBar

A colour option: a bar as wide and tall as a dropdown, filled with the colour and reading its hex code in white, `#RRGGBB`, or `#RRGGBB · 60%` when it has opacity under 100%.

## When to use

Every colour option (Ace `color`). A click opens Blizzard's colour picker, raised over the window.

## What the consumer provides

`get`/`set` of r, g, b (and a), `hasAlpha = true` when opacity matters, `name`, `desc`. A colour is never `'small'`: its bar is a dropdown's width.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Bar | 170 x 24, Box edge and outside line | `control-width`, `field-height`, `kit-edge`, `kit-alt` |
| Inside the edge | a 1px black line, then the colour from 2 in | `text-outline` |
| Opacity | the colour drawn at its alpha over the black, so a see-through colour looks darker | |
| Code | `field`, centred, always `white`, with the font's black outline | `white`, `text-outline` |
| Code format | `#` and six uppercase hex digits; with `hasAlpha` under 100%, " · " and the whole percent | |

## States

- Under the mouse: the edge turns `accent`.
- Disabled: `alpha-disabled`, label `text-grey`.
- While Blizzard's picker is open the bar follows the picked colour live.

## Legibility

The code is always white and relies on the outline. On light colours (`text` #E6E6CC, `white`, `text-grey`) white on the fill is under 3:1 and only the outline carries it; the Colors tab shows this on its Text and Buttons sections. A followup once said the code turns black or white by the fill's brightness; the code never did. Whether to change it is an open question.

## Blizzard theme

Blizzard's `ColorSwatchTemplate` art, stretched to the bar's shape; the code stays.

## Do and don't

- Do give a colour a half cell; its label says what it colours ("Custom color", "Border").
- Do put a per-setting `ResetIcon` beside it when it differs from its default, not a section Reset button.
- Don't draw a swatch square: the bar replaced swatches because they read as check boxes.
