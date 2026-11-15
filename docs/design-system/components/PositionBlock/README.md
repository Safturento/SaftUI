# PositionBlock

Where a frame or part sits, in one line: THIS (which point of it), TO (what it's anchored to), AT ITS (which point of that), OFFSET (X over Y, with nudges), each part a caption (Heading's face) over a 48px band.

## When to use

Every option of type `position`, always last on its page or in its menu, in a section of its own titled with what it places ("Position", "Text position", "Count position"). A frame's position is also set by dragging its mover in edit mode; the block shows the live numbers.

## What the consumer provides

`get`/`set`/`validate` that take the part first (`'point'`, `'rel_point'`, `'x_off'`, `'y_off'`, `'frame'`, `'relative_to'`), and what TO offers: nothing (no TO part), a name box for a global frame, or a list (the unit frame, a global frame, the frame's other parts). A typed frame name is checked with `st:ValidateAnchor(target, name)`.

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Block | 65 tall: caption 13, gap 4, band 48; 200 wide, 332 with a name target, 351 with a select | `pos-caption-gap`, `pos-band` |
| Parts | 12 apart | `pos-gap` |
| Captions | `caption` (Heading's face, 11) in `text-grey`, centred | `caption`, `text-grey` |
| Dot grid | a 48 Box: nine 14 cells inside a margin of 3; dots 4 x 4 in `dot-grey`, the picked one 8 x 8 in `accent`, a dot under the mouse in `text` | `pos-dot-cell`, `pos-dot-margin`, `pos-dot`, `pos-dot-picked`, `dot-grey` |
| TO | a `Select` 140 wide, or a name box 120 x 24 | `pos-select`, `pos-name` |
| Offset | X and Y (12 wide, 8 gap) each with a 46 x 22 box and a 14 x 22 nudge pair sharing its right edge; up and down split by a `kit-edge` line, each one Lucide chevron (`chevron-up`, `chevron-down`), 12 x 12 in `text-grey`, `text` under the mouse | `range-value`, `pos-box`, `pos-nudge`, `pos-axis-gap` |

## States

- Click a dot to pick it; typing an offset or a nudge sets at once; a drag in edit mode updates the boxes about every 0.1s.
- Disabled: the block at `alpha-disabled`.
- On a shared setting, the block's title carries the own mark, reset icon, hover line and diff icon (a text's Position is one setting).

## Mockup differences

The approved mockup drew 60 x 24 offset boxes, 10px captions, a TO list with an `accent` border on `#101010`, and grids with 4px and 8px dots in a 48 box; the code draws 46 x 22 boxes, 11px captions, and the kit's list in `kit-bg` with a `kit-edge` line. This preview shows the code's.

## Blizzard theme

The dots keep a 1px line in the Blizzard theme's Border round its Background (no Blizzard equivalent); the nudges become MinimalScrollBar's steppers, the chevrons hidden; the TO dropdown is the compact Settings dropdown (glow 4 out); the boxes take `InputBoxTemplate`.

## Do and don't

- Do put Position last, in its own section, every time.
- Do keep offsets whole numbers.
- Don't draw the nudge arrows by hand: they are Lucide's `chevron-up` and `chevron-down` (`Kit.NudgePair`, shared with the number box).
