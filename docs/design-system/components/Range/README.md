# Range

A slider and its value box: a 116px track filled in accent to the value, a light 6 x 14 knob, and a 46px box showing the number.

## When to use

Any number with a sensible range (Ace `range`): sizes, counts, spacing, opacity. A number with no range (a width that may be anything, an offset) is an `Input` that saves numbers.

## What the consumer provides

`min`, `max`, `step` (and `softMin`/`softMax`, `bigStep`), `isPercent` for a 0-1 value shown as a percent, `get`/`set`, `name`, `desc`. SaftUI's `applyOnRelease` for a setting too heavy to change at every step of a drag (the UI size).

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Whole | 168 x 24: track, 6 gap, value box | `range-width`, `range-gap` |
| Track | 116 x 6: a 1px `kit-edge` round a 4px `kit-field`, a `kit-alt` line outside (8 tall) | `range-track`, `range-track-height` |
| Fill | `accent`, inside the edge, from the left to the value | `accent` |
| Knob | 6 x 14 in `text`; under the mouse and while dragged a solid in the lighter tone of the Accent | `knob-width`, `knob-height`, `text`, `accent-light` |
| Value box | 46 x 24 Box, the number centred in `field`; typing a value sets it | `range-value` |

## States

- Dragging sets as it goes; the window's other rows follow, and a dialog re-renders after the drag.
- With `applyOnRelease` a drag only moves the knob, fill and box, and the value is set once when the mouse button comes up (not at all if it came back to where it began). An arrow's click and a typed value set at once.
- Disabled: the whole range at `alpha-disabled`, label `text-muted`.
- A percent reads "30%"; numbers show without float drift (0.065, 12, 33.5).

## Mockup difference

The approved mockup drew the knob in `accent` with no fill (`actionbars-shared-v6.html:49`). The code and the window's first mockup (11-09) draw a `text` knob over an `accent` fill; this preview shows the code's.

## Blizzard theme

Blizzard's minimal slider: its track ends and middle, its thumb, and step arrows at both ends (coloured while they can step, desaturated while not); the value box takes `InputBoxTemplate` art.

## Do and don't

- Do pick a `step` that gives whole pixels for any size or offset.
- Don't use a range for a value players type exactly (a frame's width); use an input.
