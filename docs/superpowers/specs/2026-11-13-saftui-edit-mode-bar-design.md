# Edit mode bar: edit mode's controls in a bar across the top of the screen

Design, 2026-11-13. Approved by the owner from the mockup in the session ("Everything else
on that bar looks great, you can go ahead and start the work"). The mockup is
`.superpowers/brainstorm/46409-1794604463/content/window-and-editmode-v3.html`, part 2
("Edit mode: a bar across the top"). Part 1 (the colour control) and part 3 (collapsing the
`/sui` sidebar and shrinking the window) are other work and not part of this design.

Inline marks: **(owner)** is a decision the owner made; **(builder's call)** is one made
while writing this, all of them listed again at the end.

## Why

Edit mode's controls live in the `/sui` window's footer today:

- `SaftUI-Core/EditMode/footer.lua` lays Grid, Snap to grid, Snap to frames, `-`, the grid
  size and `+` into the footer region between Reload UI and Close
  (`st.OptionsWindow:GetFooter()`, `optionswindow.lua` `BuildFooter`). They are Core's old
  buttons (`st:CreateButton`), 22 tall in the Pixel font, beside the kit's 26 tall buttons
  in the field font, and "on" is green text (`settings.lua` `EM:UpdateFooterToggles`).
- They show only while edit mode is on **and** `/sui` is open (`EM:UpdateFooter`). With
  `/sui` closed, edit mode has no controls at all.
- The unit frame profile control now shares the footer (the page's `footer` group,
  `OW.FooterPlace` in `optionslayout.lua`), so `OW:SetFooterInset` squeezes the status
  line and the control to make room, and they collide.

The owner, on the footer: "those buttons in the footer are a great example of
inconsistency caused by the lack of a design system - the size and fonts are differeent. I
also noticed that the footer is extremely busy and has overlapping items now. I think we
should consider moving the edit mode grid items to a different location. ... ellesmere has
this top bar that's really nice, maybe we can design something similar to that. it could
also be nice to have a module toggle there so that we can selectively enable edit mode,
for example if we're only working on unitframes we can have it only show edit mode movers
for those and not everything else. if you have any other ideas of things to add on that
window let me know."

There is also no way to undo a move, put a frame back where it shipped, read a mover's
position without opening `/sui`, or thin out the 40-odd movers that pile up where frames
overlap (the design system's Discrepancy 5 and Unknown 11, "Overlapping mover labels").

## What the owner decided

1. **A bar of edit mode's own across the top of the screen, shown while edit mode is on,**
   modelled on Ellesmere's top bar. (The first quote above; design system decision 5 and
   15, `docs/design-system/05-decisions.md`.)
2. **A module filter on the bar,** so only the chosen modules' movers show: "if we're only
   working on unitframes we can have it only show edit mode movers for those".
3. **The module choice is one dropdown with a check list,** not a row of chips: "the show
   toggle buttons are feeling a bit busy, maybe we move that into a dropdown multiselect?"
4. **Undo, Redo and a per-mover Reset stay:** "I looove the undo/redo/reset buttons, great
   call on those."
5. **Grid size is on the bar,** a number box with up and down arrows beside the Grid
   toggle: "one thing I noticed in this edit mode bar mockup, the grid size config seems
   to be missing".
6. **Snap is two toggles, Snap to grid and Snap to frames,** as today: "I like having them
   as two separate options so lets get them both back in."
7. **Everything else as mocked:** Exit; Dim world; Coordinates; Show hidden; the "Filter
   movers..." box; Options. "Everything else on that bar looks great, you can go ahead and
   start the work".
8. From the design system decisions the owner made the same day, which bind this work:
   **one button, one size** ("The edit mode footer's mixed sizes and fonts are the example
   of what this ends", decision 4); **"on" is the accent colour, never green text**
   (decision 7); **panels follow the theme's see-through or solid setting** (decision 2);
   Lucide icons with a tooltip wherever an icon stands for a word, and resets per item with
   `rotate-ccw` (`docs/design-system/README.md`, Rules 1 and 2).

## Goals

- Every edit mode control reachable whenever edit mode is on, with `/sui` open or closed.
- One button look and size on the bar, the kit's, in the field font, in every theme.
- A way to show only some modules' movers, or find one mover by name.
- Undo and Redo for moves, and Reset for the selected mover, all moving frames through the
  same path a drag uses.
- A `/sui` footer that holds only Reload UI, the status line, a page's footer control and
  Close, so nothing in it overlaps.

## Non-goals

- Part 3 of the mockup (the `/sui` sidebar collapse, the half and mini window sizes, Reload
  UI moving beside Close).
- A new button component for all of SaftUI (the design system's code change 4) or the icon
  helper (code change 5). The bar builds on the kit's button and adds the icon button it
  needs (see What's left to the builder).
- Movers for unit frame parts placed on the screen (`docs/followups.md`, "Edit mode movers
  for unit frame parts placed on the screen"). They would join the Unit frames module when
  they come.
- Changing how a drag, a nudge, snapping, the margin or the Alt picker work.
- Blizzard's Edit Mode: SaftUI still only listens to it.

## Anti-goals

- A control that moves a secure frame in combat, or moves anything by a path other than the
  mover's own `setPosition` and `apply`.
- Core knowing module names or which frames a module has: every name comes from the mover's
  registration.
- A frame silently moved by Undo, Redo or Reset that the player can't see named first (each
  button's tooltip names the mover it will move).
- State shown only on hover: which modules show, which toggles are on and whether Undo has
  anything to undo are visible on the bar.

## The bar

A SaftUI frame across the top of the screen, 40 tall (the mockup's), drawn as a `panel` in
the theme (below, Themes). Its controls sit in groups, left to right, with a 1px `hairline`
divider between groups and 4 between the controls inside one (the mockup's spacing;
builder's call to keep it over the kit's 12 `button-gap`, so the icon toggles read as one
set). Buttons are the kit's button at its one height, 26 (`button-height`; the mockup drew
24). Icon-only buttons are 26 x 26 squares, each Lucide icon drawn 16 (`icon-chevron`'s
size, which is the mockup's 16px), tinted `text-grey` at rest. (builder's call: the
sizes.)

Toggles show "on" with the Button component's "on" look, an `accent` edge, and their icon
tinted `accent`; off is the plain button with its icon in `text-grey`. Under the mouse the
edge turns `accent` as on every kit control, so the icon's colour is what tells on from off
while hovering. (builder's call: the icon tint, since an accent edge alone can't be told
from hover.)

Every tooltip uses the kit's tooltip (Blizzard's tooltip frame, a white title, the line in
SaftUI's normal text colour, a disabled control's reason in `text-red`; decision 8),
anchored under the control because the bar is at the screen's top (builder's call). The
tooltip texts below are the builder's call unless the mockup gave them; the builder may
tune the wording.

New icons are made with `tools/lucide-to-tga.cjs` (pinned to lucide-static 0.460.0; check
each name exists in that version, as `filter` stood in for `funnel`) and registered in
`st.icons` (`SaftUI-Core/constants.lua`), which `tests/core/icons_test.lua` checks. Already
registered: `chevronDown`, `chevronUp`, `rotateCcw`, `settings`. New: `log-out`,
`grid-3x3`, `magnet`, `align-start-vertical`, `layers`, `map-pin`, `eye`, `search`,
`undo-2`, `redo-2`.

### 1. Exit

- **Does:** turns edit mode off (`EM:Deactivate`). Every move is already saved, so there is
  no "Save and exit".
- **Look:** a kit button with the `log-out` icon then the word "Exit" (the mockup's).
- **Tooltip:** "Exit", "Turns edit mode off. Your moves are already saved." While
  Blizzard's Edit Mode is open, a second line: "Blizzard's Edit Mode stays open; close it
  with its own button." (Exit can't close Blizzard's: calling its code from SaftUI's would
  run it tainted, `.agents/taint.md` rule 3.)
- **Saved:** nothing.

### 2. Grid

- **Does:** shows or hides the grid (`EM:UpdateGrid`, `grid.lua`), as the footer's Grid
  does today.
- **Icon:** `grid-3x3`. **Tooltip:** "Grid", "Draws a grid over the screen, centred on its
  middle." **States:** on, off.
- **Saved:** `editmode.grid` in the profile, as today (default off).

### 3. Grid size

- **Does:** sets the gap between the grid's lines, 8 to 128 (today's `MIN_GRID_SIZE`,
  `MAX_GRID_SIZE`, `settings.lua`). The up and down arrows step it by 4 (today's
  `GRID_STEP`; the mockup stepped 8; builder's call to keep 4). The number can be typed:
  Enter commits a whole number clamped to the range, Esc puts back the old one. The grid
  redraws at once, and an open `/sui` shows the new value (`st.Config:Refresh`, as
  `EM:StepGridSize` does).
- **Look:** the position block's X/Y box with its nudge pair (`optionsposition.lua`,
  `NudgePair`), 54 wide as mocked, its arrows Lucide `chevron-up` and `chevron-down` in
  place of the hand-drawn triangles (the Icons component lists those for replacement).
  Directly after the Grid toggle.
- **Tooltip:** "Grid size", "The gap between the grid's lines, in pixels. The arrows step
  it by 4."
- **States:** enabled while Grid or Snap to grid is on; disabled (at `alpha-disabled`)
  when both are off, the tooltip adding "Turn on Grid or Snap to grid to use it." The
  mockup dimmed the box whenever Grid was off, but Snap to grid uses the grid's lines with
  the grid hidden (`snap.lua` `EM:GetSnapLines`), so the size still matters then
  (builder's call).
- **Saved:** `editmode.grid_size` in the profile, as today (default 32).

### 4. Snap to grid

- **Does:** a dragged mover snaps to the grid's lines, shown or not (today's `snap_grid`).
- **Icon:** `magnet` (the mockup's Snap icon). **Tooltip:** "Snap to grid", "A dragged
  frame snaps to the grid's lines, shown or not. Hold Ctrl to drag without snapping."
- **Saved:** `editmode.snap_grid`, as today (default off).

### 5. Snap to frames

- **Does:** a dragged mover snaps to the edges and middles of the other shown movers and
  the screen's middle (today's `snap_frames`).
- **Icon:** `align-start-vertical` (bars flush against a line: edges meeting). (builder's
  call: the mockup had one Snap and one magnet; two magnets can't be told apart.)
- **Tooltip:** "Snap to frames", "A dragged frame snaps to the edges and middles of the
  other frames shown, and to the screen's middle. Hold Ctrl to drag without snapping."
- **Saved:** `editmode.snap_frames`, as today (default off).

### 6. Dim world

- **Does:** darkens the game world behind the UI while edit mode is on, so outlines and
  frames stand out. A full-screen black texture on a SaftUI frame at `BACKGROUND` strata
  under the grid (`strata-grid`), taking no mouse, at 50% (builder's call: the level). It
  shows only while edit mode is on and Dim world is on.
- **Icon:** `layers`. **Tooltip:** "Dim world", "Darkens the game world behind your frames
  while edit mode is on."
- **Saved:** new `editmode.dim` in the profile, **default on**, as the mockup drew it
  (builder's call).

### 7. Coordinates

- **Does:** shows the selected mover's position next to it (see Coordinates, below).
- **Icon:** `map-pin`. **Tooltip:** "Coordinates", "Shows the selected frame's position by
  the corner it's anchored by." (The mockup's: "Show the selected mover's position".)
- **Saved:** new `editmode.coordinates`, default off, as mocked.

### 8. Show hidden

- **Does:** shows the movers of frames that are turned off or hidden by a setting (see Show
  hidden, below).
- **Icon:** `eye`. **Tooltip:** "Show hidden", "Shows the movers of frames that are turned
  off or hidden by a setting." (The mockup's: "Show movers of hidden frames".)
- **Saved:** new `editmode.show_hidden`, default off, as mocked (builder's call to ship
  the mocked state: today every mover shows, so this hides some on update).

### 9. Show

- **Does:** picks which modules' movers show (see The module filter, below).
- **Look:** the caption "Show" (`caption`, Colus 11, `text-grey`; Colus sets it as small
  capitals, as the mockup's "SHOW"), then a kit select face 150 wide (the mockup's) with
  the `chevron-down` caret. Its face reads "All modules", one module's name when one is
  ticked, "3 modules" for several, and "Nothing" for none (the mockup's script). A click
  opens SaftUI's check list under it (`W.OpenCheckList`, `optionslist.lua`): a row per
  module, each click applying at once, with **All** and **None** buttons under the rows.
- **Tooltip:** "Show", "Which modules' movers edit mode shows."
- **Saved:** see The module filter.

### 10. Filter movers

- **Does:** narrows the shown movers to those whose name holds the typed text (case
  ignored, the label's first line, as the picker names them: `picker.lua` `Name`). It
  narrows inside the module choice and Show hidden; it never shows a mover they hide.
  Enter selects the first match (by name) and clears the box's focus; Esc clears the text
  and the focus, as `/sui`'s search box does (`optionswindow.lua` `BuildSearch`). (builder's
  call: Enter selecting, which also reaches a mover the bar covers, below.)
- **Look:** a kit input 150 wide (the mockup's) with the `search` icon at its left and the
  grey hint "Filter movers...". Under Blizzard, `/sui`'s search box look
  (`W.LookSearch`, `SearchBoxTemplate`'s art and its own glass).
- **Tooltip:** "Filter movers", "Shows only the movers whose name has this text. Enter
  selects the first one, Esc clears it."
- **Saved:** no. The text is cleared when edit mode turns off (builder's call).

### 11. Undo, 12. Redo, 13. Reset

At the bar's right end, after a flexible gap. See Undo, Redo and Reset, below.

- **Undo:** `undo-2`. Tooltip "Undo", then the step it undoes: "Puts Player back where it
  was before the last move." (the mockup's "Undo the last move", made to name the mover).
  Disabled with "Nothing to undo." when the history is empty.
- **Redo:** `redo-2`. Tooltip "Redo", "Moves Player again." Disabled with "Nothing to
  redo."
- **Reset:** `rotate-ccw`, tinted as the bar's other icons rather than the `ResetIcon`'s
  accent, since it is a button on the bar and not an icon beside a control (builder's
  call). Tooltip "Reset", "Player goes back to its default place." (the mockup's "Put the
  selected mover back to its default place"). Disabled, with the reason, when no mover is
  selected ("Select a frame first."), when the selected one has no default ("The totem bar
  has no default place: SaftUI took its place from Blizzard's Edit Mode."), or when it is
  already there ("Player is already in its default place.").
- **Saved:** nothing (the history is the session's).

### 14. Options

- **Does:** opens `/sui` on the selected mover's page (`EM:ShowSettings`, its
  `configPath`). With no mover selected it opens Global Settings > Edit mode (builder's
  call; the mockup didn't say).
- **Look:** a kit button with the word "Options".
- **Tooltip:** "Options", "Opens Player's page in /sui." or, with none selected, "Opens
  edit mode's settings in /sui."

## Behaviour

- **Shown** while SaftUI's edit mode is on (`EM.active`), with `/sui` open or closed. It
  shows on the `Enabled` event and hides on `Disabled` (`EM:On`, `editmode.lua`), as the
  footer and the grid do today. It is a SaftUI frame, so showing and hiding it is safe in
  combat.
- **Turning edit mode on:** `/sui edit` (the slash handler in `SaftUI-Core/Config/config.lua`)
  and the sidebar's Edit mode button (`optionsnav.lua` `DrawActions`) toggle it as today.
  Blizzard's Edit Mode opening and closing still turns it on and off (`EM:OnInitialize`
  listens to `EventRegistry`'s `EditMode.Enter` and `EditMode.Exit`, and touches nothing
  of Blizzard's). The bar's Exit turns it off.
- **The sidebar's Edit mode button** shows "on" as the Button component's on look, an
  `accent` edge, in place of today's green text (`UpdateEditModeButton` uses
  `colors.text.green`), per decision 7. Under Blizzard it is Blizzard's panel button,
  which has no lit state, so its label turns `accent` while edit mode is on (builder's
  call).
- **The `/sui` footer** loses edit mode's buttons and keeps Reload UI, the status line, the
  open page's footer control (the unit frame profile) and Close. `EditMode/footer.lua`
  goes; `OW:GetFooter`, `OW:SetFooterInset` and the inset branch of `OW.FooterPlace` lose
  their only caller and go with it, so the footer control is always centred and the
  status line always starts at the region's left (builder's call: remove rather than leave
  unused).
- **The Edit mode tab** (Global Settings, `EM:GetConfigTable` in `settings.lua`) stays, so
  search still finds the settings: Show grid, Grid size, Snap to grid, Snap to frames, and
  it gains Dim world, Coordinates and Show hidden. Grid size's desc stops naming the `-`
  and `+` buttons ("The bar's arrows change it too."). The module choice and the filter are
  the bar's only. (builder's call)
- **Selecting a mover still opens `/sui` at its page** (`EM:On('Selected')` runs
  `EM:ShowSettings`), unchanged; Options is the way back to it once `/sui` is closed.
- **Chat prints:** "Edit mode on." and "Edit mode off." (`EM:Activate`, `EM:Deactivate`)
  are dropped now that the bar shows the state; the refusals and "Edit mode closed:
  entering combat." stay (builder's call).
- **In combat:** unchanged. Edit mode refuses to open (`EM:Activate`) and closes on
  `PLAYER_REGEN_DISABLED`, which fires before the lockdown starts, so a drag in progress is
  committed out of combat (`EM:StopDrag`). The bar hides with it, its Show list closes and
  its filter box loses focus. Its buttons also check `InCombatLockdown()` before acting.
- **While a mover is dragged** the bar fades to a low alpha and takes no mouse, so a frame
  dragged up under it stays visible (builder's call; the drag itself is held by the
  overlay's `OnUpdate` wherever the cursor goes).
- **Escape,** in order of what has the keyboard: the filter box clears and loses focus; an
  open Show list closes (the list's own catcher, `optionslist.lua`); an open `/sui` closes
  (its catcher, `optionswindow.lua` `EscapeKeys`); then edit mode's catcher (`mover.lua`)
  deselects the selected mover, and with none selected turns edit mode off. All of this is
  today's order; the bar adds only the filter box and its list.
- **Strata:** the bar sits in `FULLSCREEN_DIALOG` (`strata-options`) at a level above the
  movers' whole range (they climb from 10 to at most 9000, `picker.lua` `LEVEL_MAX`), so no
  mover covers its controls. That also puts it over the `/sui` window (level 100), its
  small dialog and an item's menu, and under everything in `TOOLTIP` strata: the kit's
  lists, the confirm dialog, the Alt picker's list and the game's tooltip. (builder's
  call)
- **The top of the screen.** The bar covers the screen's top 40 pixels across its width,
  where SaftUI's micro menu, the top of the minimap and the buffs sit in the owner's layout
  (the screen edge margin keeps frames 20 in, `misc.clamp_inset`). The nearest thing to
  the mockup that keeps those reachable (builder's call):
  - the bar's panel takes no mouse; only its controls do, so a click between controls (the
    wide gap before Undo especially) reaches the mover under it, and the Alt picker works
    there;
  - the bar fades while a mover is dragged (above);
  - Enter in the filter selects a covered mover, which the arrow keys then nudge, Reset
    resets and Options opens.
  Whether to keep the bar full width is the first question for the owner (end of this
  document).

## The module filter

**The modules** are the mockup's seven, one per SaftUI addon that registers movers. What
each holds today (every `st:RegisterMover` and `st:RegisterConfigMover` call):

| Module | Movers (key, registered in) |
| --- | --- |
| Action bars | bars 1 to 8, pet and stance bars, the extra action button, zone ability and leave vehicle button (`ab_<id>`, `SaftUI-ActionBars/options.lua`) |
| Bags | each bag and bank window (`bags_<id>`, `SaftUI-Bags/movers.lua`) |
| Chat | chat (`chat`, `SaftUI-Chat/chatframe.lua`) |
| Loot | loot rolls and the loot feed (`lootroll`, `SaftUI-Loot/roll.lua`; `lootfeed`, `Feed/feed.lua`) |
| Minimap | the minimap and the micro menu (`minimap`, `SaftUI-Minimap/minimap.lua`; `micromenu`, `micromenu.lua`) |
| Misc | experience, the totem bar, the objective tracker, the tooltip, buffs and debuffs, the swing timers (`SaftUI-Misc`) |
| Unit frames | every unit, and the party, raid and boss groups (`uf_<unit>`, `SaftUI-Unitframes/unitframes.lua`) |

**How a mover is assigned.** Nothing on a mover names its module today: its definition is
`frame`, `label`, `getPosition`, `setPosition`, `apply`, `configPath` and `blizzardFrame`
(`editmode.lua`, `st:RegisterMover`), and `configPath`'s first key is a `/sui` page
(`ActionBars`, `Inventory`, `TotemBar`, ...), finer than the seven. So each registration
gives a new field, `module`, the name the Show list shows ("Unit frames"). The word is the
owner's ("module toggle"); it is not an AceAddon module (the totem bar's AceAddon module is
`TotemBar`, its Show module is Misc). `st:RegisterConfigMover` passes it through like its
other fields. A mover with none is listed under "Other", last, so a mover added later is
never unreachable. (builder's call: the field, and "Other")

**The list** shows only modules that have a registered mover (a disabled addon has none),
in alphabetical order with Other last (builder's call; the mockup listed Unit frames
first, which needs an order Core would have to know).

**What a mover outside the choice does:** its overlay hides (`overlay:Hide()` where
`EM:Activate` and `EM:CreateMover` show it today). Then:

- **Selection:** a selected mover that is hidden by the module choice, the filter or Show
  hidden is deselected (`EM:Select(nil)`), so the arrow keys never nudge a mover you can't
  see.
- **Snapping:** it is no longer a target. `EM:GetSnapLines` already takes only movers whose
  overlay is shown, so what's outlined is what snaps (builder's call to keep that, rather
  than snapping to frames whose outlines are hidden).
- **The Alt picker:** it no longer appears; `picker.lua`'s `Scan` already takes only shown
  overlays.
- **The filter box** narrows inside the choice; it never brings back a hidden mover.
- **Undo and Redo** still move it (a step names its mover in the tooltip), since its frame
  is on screen even when its outline isn't (builder's call).

**Remembered:** yes, in the profile beside the grid settings, as
`editmode.hidden_modules`, the set of modules unticked (builder's call: storing what's
hidden means a module added later shows; per profile, as `grid` and the snaps are).

## Undo, Redo and Reset

**A step** is one change to one mover's position, recorded as copies of its whole position
table before and after (point, relative frame, relative point, offsets):

- a **drag**, from the press to the release, when it moved (a click records nothing). The
  "before" is copied at `EM:StartDrag`: the drag's ticks write into the very table
  `getPosition` returns (`EM:UpdateDrag`), so a reference would change with it;
- a **nudge**; presses on the same mover with no other step between them and less than a
  second apart join one step, so ten Shift+arrows undo together (builder's call);
- a **Reset**;
- a **position set in `/sui`** (typed X or Y, the nudge arrows, the point dots, the anchor),
  whether edit mode is on or off. No `/sui` option knows its mover, so edit mode keeps a
  copy of each mover's last known position and, after each set the options window commits
  (the body's `onChanged`, `optionsbody.lua` `OB.New`, not while a slider is still being
  dragged), records a step for each mover whose position differs. The `/sui` nudge arrows
  join as keyboard nudges do. (builder's call: the snapshot compare)

Grid, snap and the other bar toggles are not steps; the bar's Undo is for moves (the
mockup's "Undo the last move").

**Depth:** the last 50 steps across all movers (builder's call). A new step clears Redo.

**Lifetime:** the session's. Kept when edit mode turns off (so an Exit or a pull doesn't
lose it); cleared on a reload and on a profile change, copy or reset, whose positions are
another profile's (`EM:UpdateConfig`). Not saved. (builder's call)

**Undo and Redo** put the step's before (or after) back on its mover through the same path
a drag's end uses: `setPosition` with a fresh copy, then `apply`, then `PositionChanged`
(`EM:CommitPosition`). The selection doesn't change. Before applying, two checks:

- the mover is still where the step left it; if something else moved it since (a module's
  own placement, say), that step and the mover's older steps are dropped and nothing moves;
- a restored anchor that names another frame passes `st:ValidateAnchor(frame, name)`
  (`api.lua`), since that frame may have been anchored to this one since; a refused one is
  dropped with a chat line saying why.

**Reset and "default place".** No mover records a default today. The defaults live in
each module's `st.defaults` table (e.g. `st.defaults.chat.position`), which Core can't
find from a mover. So a mover says where it ships (builder's call: the names):

- `st:RegisterConfigMover`'s spec takes `defaults`, the twin of `config`: a function
  returning the defaults table that holds `position` (`function() return st.defaults.chat
  end`). Core copies `position` from it on each Reset, never handing out the defaults'
  own table (a later drag would write into it).
- `st:RegisterMover`'s definition takes `getDefaultPosition`, returning a fresh table or
  nil.
- The **objective tracker** (`Blizzard_ObjectiveTrackerPosition.lua`) has no saved default
  (its position is captured from Blizzard's layout on first load), but it has Blizzard's
  default spot, `DefaultPosition()`: Reset puts it there, saved as the profile's position.
- The **totem bar** (`totemposition.lua`) has none: with no saved position it waits at a
  temporary spot (`WAITING_POSITION`) until it captures where Blizzard's Edit Mode put
  it, and the capture overwrites the profile's position. So its Reset is disabled with
  the reason. (Keeping the captured spot as its default is in Later.)
- **Unit frames** read their positions from the unit frame profile
  (`UF:GetProfileConfig()`), so their defaults come from that profile's defaults; the
  experience bar's from its default after its position migration (`XP:MigratePosition`).
  The builder finds each.

Reset is disabled while the selected mover already matches its default (offsets compared
as numbers, since older profiles saved them as strings, `mover.lua` `GetAnchor`).

## Coordinates

While on, the selected mover shows its position as a small label outside its outline, at
the corner (or edge middle, or centre) its position is anchored by, kept on screen (it
flips inside the outline where there's no room). It reads the stored position, in words,
because the design system forbids showing internal keys: "Top left 250, -250" (the mockup
drew "TOPLEFT 250, -250"), with "to Player" added when the anchor is another frame
(builder's call: the wording). It is drawn in the mover label's font (the pixel font
today, `mover.lua`) in `accent`. During a drag it follows the drag's live offsets, for the
dragged mover whether selected or not. It shows the stored offsets, as `/sui`'s Position
does, not where a margin-clamped frame shows. (builder's call)

## Show hidden

Nothing on a mover says its frame is hidden today: every overlay shows while edit mode is
on, and a few say so in their label's second line ("off", `AB:UpdateMoverLabel`; "(hidden
by Blizzard setting)", the swing timers). So a mover's definition takes `isHidden`, a
function read whenever edit mode decides what shows (builder's call: the name).

**Hidden means turned off or hidden by a setting**, SaftUI's or Blizzard's: a bar or unit
frame that is disabled, a bar with nothing to show by its settings, a swing timer Blizzard's
setting hides. It does **not** mean "not on screen right now": a closed bag window, the
pet bar without a pet, boss frames out of a fight, the extra buttons, a bar shown only in
combat or faded. Those are frames the player places before they appear, and their outlines
keep saying when they show, as today. (builder's call: the line between the two; each
module decides its movers against it.)

With Show hidden on, hidden movers show as today, labels included.

## Options

Opens `/sui` at the selected mover's page through `EM:ShowSettings` (its `configPath`, which
`.agents/edit-mode.md` requires to end at a leaf `general` group), or at Global Settings >
Edit mode with none selected. `st.Config:Open` refuses in combat as today.

## Layout at narrow screen widths

The bar is the screen's width, its left groups from the left and Undo to Options from the
right. All of it needs roughly 1000 pixels, so it fits a 1024 wide screen at SaftUI's
scale (one unit per physical pixel). When the bar is narrower than its controls (a smaller
screen, or a UI scale change; it lays out again on `UI_SCALE_CHANGED`,
`DISPLAY_SIZE_CHANGED` and its own size change, as the grid does), these give way in
order (builder's call):

1. the filter box narrows from 150 to 100;
2. the "Show" caption goes;
3. the Show face narrows from 150 to 110;
4. Exit and Options drop their words and become icon buttons (`log-out` and `settings`),
   their tooltips naming them.

Every size and offset stays a whole pixel (`st:RoundToPixel`), icons on whole-pixel centres.

## Themes

- **The bar's panel** is drawn with `st:SetBackdrop(bar, 'theme', 'theme', 'panel')`: the
  profile's theme and its see-through or solid Background (decision 2), a `panel` as chat
  and the minimap are. Under Thick, `backdrop` inside the three lines; under Thin, one
  line; under Blizzard, the `panel` kind's Blizzard art, the tooltip border
  (`themeart_data.lua` `ThemeArt.KINDS`). It is placed its theme's inset past the screen's
  top, left and right edges, so only its bottom line shows, as the mockup draws it
  (builder's call). It redraws with the theme like every drawn frame
  (`st:RedrawThemed`).
- **Controls** under Thick and Thin are the kit's: `Box` buttons and fields, the `accent`
  hover edge, the field font. Under Blizzard each takes the art the kit already gives its
  kind: Exit and Options are Blizzard's panel button (`W.LookButton`); the Show face is the
  Settings dropdown (`W.LookDropdown`); its check list takes the Settings menu and check
  box (the list does this itself); the filter box takes `SearchBoxTemplate`
  (`W.LookSearch`); the grid size box takes `InputBoxTemplate` and its arrows
  `MinimalScrollBar`'s steppers, as the position block's X and Y do.
- **The icon buttons** have no Blizzard kit equivalent: under Blizzard they are the panel
  button's art at 26 x 26 with the Lucide icon over it, "on" shown by the icon in
  `accent` alone (builder's call).
- **Group dividers** are `hairline` under Thick and Thin; under Blizzard the bar keeps them
  (Blizzard has no art for one; builder's call).
- **Colours** are read from the profile at draw time (`accent` is a theme colour the
  player can change, decision 7), so a Colors change reaches the bar, through
  `EM:OnColorsChanged` or the window's equivalent.

## What's left to the builder

- **Where the code goes.** A sketch, the builder's to better: `EditMode/bar.lua` for the
  bar (replacing `footer.lua`, and the footer half of `settings.lua`), the shown/hidden
  rule (module choice, filter, Show hidden) in one function every overlay goes through,
  the history in a file of its own, the dim layer beside the grid. `EM:UpdateConfig`'s
  `UpdateFooterToggles` becomes the bar's refresh.
- **The icon button.** The bar needs a square kit button holding a Lucide icon and
  requiring its tooltip. That is the design system's code change 5 ("an icon button that
  requires its tooltip text"); build it in Core as the first piece of that, not as a
  bar-only widget, and the text buttons from the kit's button (`optionswindow.lua`'s local
  `Button` and `W.LookButton`), which will need lifting out of the window file.
- **The check list's All and None.** `W.OpenCheckList` has no buttons; the Apply list has
  one (`W.OpenApplyList`). Give the check list optional buttons under its rows, drawn as
  the Apply list's. Two kit buttons at the Button component's 80 minimum plus their gap
  are wider than the list's 170, so the list grows to fit them.
- **The number box.** `NudgePair` and the X/Y box are local to `optionsposition.lua`; lift
  what the grid size box needs.
- **Per-module work:** every registration gets `module`; those that can be turned off get
  `isHidden`; every one gets `defaults` or `getDefaultPosition` where it has a default.
- **Docs:** `.agents/edit-mode.md` (the footer bullet, the new mover fields, the bar), the
  design system's `Mover` and `Button` pages (the footer example), and this repo's checks
  (`agents-doc-parity-check`).
- Tooltip wording, exact gaps, the fade's alpha, the dim's opacity, within the kit's style.

## Risks to check

1. **Taint and combat.** The bar is SaftUI's own frame, so drawing, showing and hiding it is
   safe at any time. But Undo, Redo and Reset move secure frames (action bars, unit frames
   and their group headers, and anything anchored to them). They must go through the mover's
   `setPosition` and `apply`, whose `apply` is required to go through `st:SafeReposition`
   (`.agents/edit-mode.md`), never a `SetPoint` of their own, so a protected frame's move
   waits for the end of combat. Edit mode is closed in combat, but the buttons still check
   `InCombatLockdown()`. Nothing on the bar may touch a Blizzard frame or call Blizzard's
   Edit Mode code (`.agents/taint.md` rules 1 and 3): Exit leaves Blizzard's Edit Mode
   alone.
2. **The Blizzard-frame takeovers** (objective tracker, totem bar, chat, buffs, swing timers,
   tooltip container) place Blizzard's frames from SaftUI's holders through post-hooks.
   Undo and Reset must move only the holder through `setPosition` and `apply`, as a drag
   does. The objective tracker's `setPosition` also records where it was placed
   (`placedAt`); a Reset to `DefaultPosition()` must save a copy, not leave the position
   empty, or `OTP:KeepPlacement` would put the old spot back on the next profile change.
3. **AceDB's tables.** History and Reset store copies, never the table `getPosition`
   returns (a drag writes into it) and never a defaults table (AceDB's defaults would then
   change for the session).
4. **Anchor loops.** Undo, Redo and Reset can change a mover's anchor, not just its
   offsets; validate with `st:ValidateAnchor` before applying, as the Position editor does.
5. **The keyboard.** While the filter box has focus, edit mode's catcher passes every key
   on (`GetCurrentKeyBoardFocus()`, `mover.lua`), so the arrows don't nudge. The box must
   lose focus on Enter, Esc, a click on a mover and the start of a drag, or nudging seems
   broken. The catcher's `SetPropagateKeyboardInput` is protected in combat, as today.
6. **Movers under the bar.** Check in game that the micro menu, minimap and buffs movers in
   the owner's layout can be selected and dragged with the bar up, through its gaps and the
   filter's Enter, and that the bar's fade during a drag reads well.
7. **Hover scripts.** The game calls `OnEnter` and `OnLeave` with a second argument; a
   tooltip helper bound straight as a script took it for an owner before (b4e218c). Tests
   fire hover scripts as the game does.
8. **The dim layer** sits at `BACKGROUND` strata under the grid. Check that nameplates,
   other addons' lowest-strata frames and Blizzard's world text look right with it on, on
   both clients.
9. **Blizzard's Edit Mode.** Open it with the bar up: its manager window and its own grid
   don't collide with the bar, Blizzard's Exit still turns SaftUI's edit mode off, and the
   bar's Exit leaves Blizzard's open.
10. **Tests to update:** the footer's (`tests/core/options_frame_test.lua` uses
   `OW:GetFooter` and the inset), `editmode_grid_test.lua` and `editmode_snap_test.lua` for
   hidden overlays, `theme_blizzard_editmode_test.lua` for the bar under Blizzard; new ones
   for the module filter, the history (a drag, a nudge burst, a `/sui` set, staleness, a
   profile change) and Reset per mover.

## Later (not this work)

- Ellesmere's "Hover Top Bar": the bar slides away until the mouse reaches the screen's top,
  or a choice of top or bottom, if the covered movers prove a nuisance.
- Keyboard shortcuts for Undo and Redo (Ctrl+Z, Ctrl+Y) while edit mode is on, once it's
  clear they don't take a player's own bindings.
- The totem bar keeping its captured spot as its default, so Reset can return there.
- A list of every mover to pick from (a "Go to" dropdown beside the filter), which would
  also settle the overlapping labels (design system Unknown 11).
- Undo history kept across a reload.
- The "Show" choice per character rather than per profile, if switching profiles while
  working on one module proves annoying.

## Calls made while writing this

Most likely to matter to the owner first.

1. The bar stays full width as mocked and covers the screen's top 40 pixels; its panel takes
   no mouse, it fades during a drag, and Enter in the filter selects a covered mover.
2. Snap to frames' icon is `align-start-vertical`; Snap to grid keeps the mockup's `magnet`.
3. Show hidden means "turned off or hidden by a setting", not "not on screen right now", and
   ships off as mocked, so disabled frames' movers stop showing until it's pressed.
4. New toggles' defaults follow the mockup: Dim world on, Coordinates off, Show hidden off;
   Grid and the snaps keep today's defaults (all off).
5. A step for Undo: a drag, a run of nudges on one mover under a second apart, a Reset, or a
   `/sui` Position set (found by comparing snapshots); 50 deep; kept across Exit, cleared
   on reload and profile change.
6. Undo and Redo don't change the selection and still move movers that are filtered out.
7. Reset reads a new per-mover default (`defaults` or `getDefaultPosition`); the objective
   tracker resets to Blizzard's default spot; the totem bar's Reset is disabled.
8. The seven modules are assigned by a new `module` field on each registration, listed
   alphabetically, with "Other" for a mover without one; only modules with movers list.
9. The module choice is saved per profile as the modules unticked; the filter text isn't
   saved and clears when edit mode turns off.
10. Movers outside the choice are not snap targets and drop out of the Alt picker, and a
    selected one is deselected.
11. Selecting a mover still opens `/sui`; Options with nothing selected opens Global
    Settings > Edit mode.
12. "On" on the bar is an accent edge plus the icon in accent; the sidebar's Edit mode
    button turns accent instead of green (its label, under Blizzard).
13. Grid size steps by 4 (today's) rather than the mockup's 8, and is disabled only when
    Grid and Snap to grid are both off.
14. The "Edit mode on/off" chat lines are dropped.
15. Coordinates reads the stored anchor in words ("Top left 250, -250", "to Player" when
    anchored to a frame) at the anchoring corner, in the mover label's font, in accent.
16. Enter in the filter box selects the first match.
17. Reset's icon is tinted like the bar's other icons, not the ResetIcon's accent.
18. The bar is drawn as a `panel` following the theme's Background, placed past the screen
    edges so only its bottom line shows.
19. Under Blizzard the icon toggles use the panel button's art, on shown by the icon's
    colour; the group dividers stay.
20. The bar sits in `FULLSCREEN_DIALOG` above the movers' level range, over `/sui` and under
    lists and tooltips.
21. Narrow screens give way in order: filter box, Show caption, Show face, then Exit and
    Options lose their words.
22. The footer's edit mode API (`OW:GetFooter`, `OW:SetFooterInset`, the inset in
    `OW.FooterPlace`) is removed, not kept unused.
23. The Edit mode tab in `/sui` keeps its rows and gains Dim world, Coordinates and Show
    hidden.
24. Buttons are the kit's 26 (not the mockup's 24), icons drawn 16, 4 apart inside a group,
    tooltips anchored under the controls; Dim world at 50%.

## Settled with the owner after the first draft (2026-11-13)

These override anything above that they contradict. The owner's words are quoted.

1. **The bar can be detached.** "Lets add an option to detached it from the top of the screen, we can turn it into a floating window that can be moved around as needed." Docked is the full-width bar; a button at its right end turns it into a small movable window holding the same controls in groups, and the same button on the window docks it again. Which of the two it is, and where the window sits, are remembered. Mockup: `editmode-floating-v1.html`, awaiting the owner's look.
2. **Which movers show is a switch, not one toggle.** "maybe a three way toggle that allows you to toggle disabled vs hidden vs all?" Drawn as four positions (builder's reading, to confirm): movers of frames that are showing; plus disabled ones; plus ones hidden right now; all.
3. **Selecting a mover still opens `/sui` on its page.** "I'm fine with it opening the options menu on mover click, if its in the way we can minimize it easily now."
4. **Dim world stays, on by default.** "dim world is cool, send it. On by default is fine for now."
5. **Every choice on the bar is saved** across reloads and relaunches: "these selections (dim, show grid, grid size, etc.) should also persist across reload/relaunches."
6. **A bulk action is one step.** "if a user performs a bulk action like copying an entire unitframe config from a different unitframe that should count as one step in the history, and a single undo click should undo the full action." So a step can hold more than a position: Copy from's step restores everything the copy changed on that unit.
7. **A Reset can be undone.** "lets make sure you can undo a reset."
8. **A History list.** "should we also have a button to show the history and selectively be able to revert individual changes? that could be really cool." A History button beside Undo and Redo opens the list of steps, newest first, each with a revert control.
9. **The history's length can be set:** 50 by default, up to 1000. "50's a sane default but if I'm modifying a lot of stuff I might want to backup further. Maybe a hard cap at 1000?"
10. **Grid size:** the arrows step by 4, and any size can be typed into the box. "Grid steps of 4 are fine, lets also allow a user to input any grid size manually in the input box."
11. **Coordinates name the anchor's parent:** "should we also include the anchor parent? might get confusing otherwise." For example "Top left of the screen: 120, -330" or "Bottom of Bar 2: 0, 3".

12. **Which movers show is two toggles, "Show disabled" and "Show hidden",** replacing point 2's switch: "is 'All' not the same as 'Shown + Disabled + Hidden'? thinking about it I can't imagine a reason why someone would hide 'Shown' frames, what if this is actually just two buttons". Disabled means a frame the player has turned off; hidden means one not on screen right now (closed bags, no pet, no boss). Both off by default (builder's call, as the single toggle was).
13. **The history tracks everything, built in two parts.** "I think it should track everything, if you want to split it into two parts that's totally fine with me." Part one, with the bar: what edit mode changes (moves, nudges, resets) and bulk actions such as Copy from, each restored whole. Part two, its own piece of work after: every setting changed in `/sui`, with Undo, Redo and History reachable from the options window too. Part one's history store must take part two's steps without a redesign: a step is a label, a time and a list of (where, old value, new value), applied through the same setters a player's change uses.
14. **What counts as one step is provisional.** "if someone decides to nudge the frame 16 pixels one pixel at a time does that become 16 entries in the history? that could flood it and wipe out meaningful changes easily. maybe this is worth exploring other examples on the internet of well designed history systems. For now we can start building and adjust what we consider a 'step' based on the results of that research." The first definition stands for building (a drag; a run of nudges on one mover with under a second between them; a reset; a bulk action); research into how other tools group steps is under way and the grouping rule is kept in one place so it can change.
15. **Reverting one older step** (builder's call until the research is in): it puts back what that step changed to the values from before it, as a new step that can itself be undone; if a later step changed the same thing, that later change is overwritten and the list says so.

## The history's rules, confirmed (2026-11-13)

The owner read the research (`docs/research/2026-11-13-undo-history-systems.md`) and the rules drawn from it: "All of your decisions from the history research are sound, lets build it!" These replace points 14 and 15 above as provisional.

- A drag is one step, storing its start and end; a drag or any step with no net change records nothing.
- Nudges merge into the top step while it is the same mover, the same kind of change, nothing else has been recorded since, and each comes within about a second of the last (one named constant, to tune in game). One Undo puts the frame back to where it was before the first nudge.
- A reset is its own step and never merges. A bulk action is one step holding everything it changed.
- Labels say what happened and the net result, not a count.
- A new change after undoing discards the redo steps. No branching.
- In the History list, clicking a row jumps to that point: later steps are undone and stay redoable until a new change. Each row also has a revert control for just that step, which works only while no later step touched the same mover or setting; otherwise it is disabled and its tooltip says to jump back to that point instead. A bulk step has no single-step revert.
- Undoing or redoing a step whose mover is filtered out or off screen selects or names that mover.
- The limit is 50 steps by default, settable up to 1000, oldest dropped first.
- The floating window is approved as mocked, with the two Show toggles in place of the mockup's switch ("Floating window looks great, just swap out those few buttons in the implementation").
