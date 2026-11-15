# Mover

Edit mode's overlay on a movable frame: a 1px white outline where the frame's border line sits, a dim fill and the frame's name in the pixel font; blue when selected.

## When to use

Every frame the player can move registers one with `st:RegisterMover` or `st:RegisterConfigMover` (a holder for frames that can be empty, have no size or are Blizzard's). Edit mode (`/sui edit`, the `/sui` Edit mode button, or Blizzard's Edit Mode) shows them all, with its small two-row bar on the top edge of the screen (Exit, the grid and snaps, Options; it slides along the top and can hide until the mouse reaches the edge; Detach turns it into a small floating window with the same controls, which Dock turns back, the choice and the window's place being remembered; the bar or window fades and takes no mouse while a mover is dragged, so a frame dragged up under it shows through; an outline's mouse-down is edit mode's `Pressed` event); dragging moves, arrow keys nudge 1, Shift+arrows 10, and a click opens the frame's `/sui` page.

## What the consumer provides

The frame (or holder) with a real size, a `label` (the frame's name as the sidebar says it: "Player", "Pet bar"), get and set of its position, `apply`, and a `configPath` to its page. It also tells the edit mode bar which `module` it belongs to (the Show list's name, sentence case), whether its frame is disabled by a setting (`isDisabled`) or on but not on screen (`isHidden`), and its default position (`getDefaultPosition`, or `noDefaultReason` when it has none and Reset can't run). Label the outline when the frame may be hidden ("Bar 8 off", "Extra action button, when active").

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Outline | 1px `white`, outside the frame's rect by the theme's inset (2 under Thick, between the dark lines; 1 under Thin) | `white`, `line-width` |
| Fill | black at 30% | `mover-fill` |
| Label | `pixel`, white, centred | `pixel` |
| Selected | outline `accent`, fill `accent-tint` (accent at 15%), label `accent` | `accent`, `accent-tint` |
| Others under the picker | at 0.4 | `alpha-disabled` |
| Picker list | by the cursor where movers overlap: `tooltip` kind, `pixel`, 6 in; the one a click gets as "> name" in the accent (Theme > Accent), "Alt: next" in Buttons > Grey | `accent`, `text-grey` |
| Grid | 1px white at 12% every grid size (32 by default), two centre lines in accent at 90%, at `strata-grid` | `grid-line`, `grid-centre`, `grid-size` |
| Layer | `strata-options`, levels from 10 in steps of 2 | `level-mover` |

## States

Idle, selected (the last one clicked or nudged), dimmed (another is picked where they overlap), dragging (snaps to grid lines and other movers' edges within 8, Ctrl suspends). Reset puts the selected mover in its default place (a step that can be undone); it is offered only when the mover has a default and isn't there already, and its tooltip says why not ("Player is already in its default place.", the totem bar's "has no default place").

The bar's Undo, Redo, History and Reset (the changes group, at the right end of the bar's first row) are 26 square icon buttons, `undo-2`, `redo-2`, `history` and `rotate-ccw`, tinted like the bar's others (grey, accent while History's list is open), each with a tooltip; a disabled one says why in red ("Nothing to undo."). A tooltip under the control pressed (the bar's own, so it stays when the mouse leaves) says what the last Undo, Redo, jump or revert did, and clears after 6 seconds (in the floating window it is a line under Changes). The History list opens 6 under the bar, its right edge on its button's: a 300 wide `panel`, "History" in the group font, up to 12 rows of 26 (newest first, a hairline between), the current step marked by a 2px accent bar at the row's left, its label in the field font (grey when undone), its age or "undone" or "<n> settings" small and grey, a 14px `rotate-ccw` revert (grey, accent under the mouse; disabled with its reason when a later step touched the same frame), the last row "Before these changes", and a foot, "Keep the last" with a number box (1 to 1000) and "steps (up to 1000)". A row under the mouse is filled at 25% accent (the dropdown list's hover art under Blizzard).

The bar's Detach (a 26 square `picture-in-picture-2` icon button at the end of the bar's second row, "Turns the bar into a small window you can move anywhere.") turns the bar into a 312 wide floating window: a `panel` in the theme with the title "Edit mode" (section font) at its left and Dock (`panel-top`) and Exit, compact, at its right, then the controls under three captions, Grid and snap, Show and Changes, with a 1px line between sections, the Show section's face and filter on a line of their own, Options at the right end of Changes, and the status line under it. It is dragged by its title, kept inside the screen edge margin, sits over `/sui` and under the History list (which opens beside it) and the lists, fades while a mover is dragged, and its place and mode are remembered. The floating window covers none of the screen's top, so a Coordinates label may sit there.

## Blizzard theme

No line or fill: Blizzard's Edit Mode selection art, the highlight kit on every mover and the selected kit on the selected one.

## Known gaps

Settled (decision 25): where movers overlap (bars 4 to 8, the extra buttons) only the mover under the mouse shows its label, and the picker list still names them all. Which movers show at all (Show disabled, Show hidden, the module list, the filter) is the edit mode bar's, `EditMode/filter.lua`; Show hidden is on to start with and Show disabled off.

## Do and don't

- Do label a mover with the frame's name as the player knows it.
- Don't colour the mover's dark lines: that widens the outline past the frame's border.
