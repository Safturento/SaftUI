# The /sui window: a collapsible sidebar and three sizes

Design, 2026-11-13. Approved by the owner from mockups in the session ("the /sui window
sizing looks great ... feel free to start the work on that as well"). The approved mockup
is part 3 of `.superpowers/brainstorm/46409-1794604463/content/window-and-editmode-v4.html`
(its switch, W1 to W5); `-v1.html` to `-v3.html` are the rounds before it. Part 2 of the
same file, an edit mode bar across the top of the screen, has its own design. This one
assumes it lands, so edit mode's controls are no longer in `/sui`'s footer
(`SaftUI-Core/EditMode/footer.lua`, `OW:GetFooter`, `OW:SetFooterInset`). Part 1, the
colour control, is out of scope.

Every decision below that the owner didn't make is marked **builder's call** and listed
again at the end, under "Calls made while writing this".

## Why

`/sui` is one size today: 1040 wide and at least 700 tall under Thick and Thin, 1110 by
728 under Blizzard (`OW.LAYOUT`, `SaftUI-Core/Config/optionslayout.lua`), with its sidebar
always shown. While it is open it covers the middle of the screen, so a player tuning a
unit frame or a bar can't see much of what they are changing, and the only way to see the
whole UI is to close the window and find the page again. The owner:

- "I also thing being able to expand and collapse the /sui window would be really useful.
  we could make the sidebar collapsible (think PR file tree collapse) I also think being
  able to collapse the settings window into a half size window would be nice, we could put
  a chevron-left up in the right corner near the x close button, we could collapse it to
  half the first time and the second time it could collapse into a very small floating
  widget for when you want to just see the whole UI but not close the window completely.
  we'd also have a grow button to go the othe way."

Their reference for the sidebar is GitHub's pull request file tree, whose toggle collapses
the tree to nothing and gives its width to the diff.

## What the owner decided

1. **The sidebar collapses, and the window loses its width.** "I think the sidebar collapse
   should actually just shrink the total window size by removing the sidebar and keeping
   the rest the same." The page keeps its width and layout, and the window's right edge
   stays where it is.
2. **The sidebar's toggle sits by the sidebar.** "Can we move the sidebar collapse button
   to be near the sidebar? It feels a bit unintuitive being all the away across the panel.
   maybe we put it in the bottom right of the sidebar when it's open and put it where the
   ReloadUI button is when it's closed?"
3. **Reload UI moves beside Close.** "we can probably move the reload button next to the
   close button so we don't have to shift it on toggle."
4. **Three sizes.** Full, then half, then a small floating bar, and back: "we could
   collapse it to half the first time and the second time it could collapse into a very
   small floating widget". The size arrows sit "in the right corner near the x close
   button".
5. **The sidebar at half too.** "I think that sidebar should also be available in half
   mode."
6. **The mini bar keeps the name and is a little taller.** "for the mini floating bar lets
   keep the SaftUI label as well, we can make it slightly taller to fit it"
7. **Approved, with a note on the arrows.** "the /sui window sizing looks great, just a note
   the sidebar collapse icon feels flipped and the grow shrink arrows are also flipped when
   both present ... mark those fixes and feel free to start the work on that as well".

**The arrows, as the builder read that note.** This reading is recorded as decision 18 in
`docs/design-system/05-decisions.md` and drawn in the v4 mockup; it is the builder's, to be
confirmed in game. Every arrow points the way the window's left edge will move, since the
right edge stays put. Grow is Lucide's `chevron-left` and shrink is `chevron-right`; where
both show (half), grow is at the left of the pair. The sidebar's toggle points right to
collapse (the left edge moves right) and left to show. This keeps the shrink arrow beside
the close X at full and at half, so pressing the same spot twice goes full, half, mini, as
the owner first described it. It also turns round the owner's first idea of `chevron-left`
for shrinking; see the questions at the end.

The design system records the feature as decisions 6, 16 and 18 (`05-decisions.md`).

## Goals

- See more of the game while `/sui` is open: some more (the sidebar), much more (half),
  nearly all of it (the mini bar), without losing the page.
- Nothing under the mouse moves when the size changes: the window's top right corner, its
  close X and the arrow beside it stay where they are.
- Every setting reachable at full and at half, with the same rows, marks, hover lines and
  menus. A page at half is the same page in one column.
- The size and the sidebar remembered, so a player who likes half gets half.
- Whole pixels in every state, under both layouts (Thick and Thin, and Blizzard).

## Non-goals

- Edit mode's bar (its own design) and the colour control.
- A width the player drags. Only the height grows by the grip, as today.
- Changing any module's option table. The half layout is the window's, read from the rows'
  sizes.
- Getting around with the sidebar collapsed (a page menu on the title, search elsewhere,
  keys); see Later.
- Animation. Each change is instant (builder's call: a width that slides passes through
  half pixels and lays the page out on every frame).

## Anti-goals

- A size change that loses what the player was doing: the page, tab, pick, scroll, a
  search.
- A border on a half pixel in any state: the window's, or a dialog's placed on it.
- A row at half that is narrower than the same row today, or a setting that half drops.
- A mini bar that is more than a bar: no settings on it, nothing opens from it but the
  window.
- A state the player can't read: the window always shows its size and the way back.

## The states

Five, as the mockup's switch: full with the sidebar (W1), full without (W2), half with
(W3), half without (W4), and mini (W5). The sidebar's state and the size are separate: a
sidebar collapsed at full stays collapsed at half, and the mini bar, which has none,
remembers it.

**Widths** come from each layout's own numbers in `OW.LAYOUT`: the layout's `width`, less
`sideWidth` while the sidebar is collapsed, less what the body loses at half. The half body
is one column: 388 wide under Thick and Thin and 368 under Blizzard, one pixel more than a
column is today (387 and 367), so that every width is even (see Moving between states;
builder's call). A new number per layout, say `halfBody`, holds it.

| State | Thick and Thin | Blizzard |
| --- | --- | --- |
| W1 full | 1040 (today) | 1110 (today) |
| W2 full, no sidebar | 832: 1040 less the sidebar's 208 | 868: 1110 less the sidebar's 242 |
| W3 half | 654: 1040 less 386 (the 774 body becomes 388) | 704: 1110 less 406 (774 becomes 368) |
| W4 half, no sidebar | 446 | 462 |
| W5 mini | its contents, rounded up to even; 42 tall | the same |

Full and half take the saved height as today (`OW.WindowHeight`); the mini bar is 42.

**W1, full.** As today, with three changes. The sidebar's foot gets the sidebar toggle at
its right, beside "Profile: name" (Lucide `panel-left-open`, pointing right, "Collapse the
sidebar"). The header gets one arrow left of the close X: shrink (`chevron-right`, "Shrink
to half"). Reload UI sits beside Close at the footer's right end, and the footer's left is
free. Everything stays where it is.

**W2, full without the sidebar.** The sidebar goes and the window is 208 narrower (242
under Blizzard) from the left. The main column keeps its width (828 under Thick and Thin)
and its place on screen, so the page doesn't move at all: title, tabs, rows and footer stay
exactly where they were. The toggle is at the footer's left, where Reload UI is today
(`panel-left-close`, pointing left, "Show the sidebar"). Header: shrink and close, as W1.

**W3, half.** The page in one column (Half size, below), the sidebar as at full. Header:
grow (`chevron-left`, "Grow to full"), shrink (`chevron-right`, "Shrink to a bar"), close.
The shrink arrow is where it was at full, so a second press on that spot goes on to mini.
What stays: the window's top right corner, the close X, the shrink arrow, the page's right
edge.

**W4, half without the sidebar.** The narrowest working size: one column, the toggle at
the footer's left. Header as W3.

**W5, mini.** A bar 42 tall at the window's top right corner: "SaftUI", the page's name,
the tab's name, grow (`chevron-left`, "Grow to half") and close. See Mini, below.

**The new buttons.** Each is an icon button the size of the close X it sits by
(`CloseButton`: a 24 by 24 Box, `kit-field` inside a `kit-edge` line with a `kit-alt` line
outside). The icon rests `text-grey` and turns `accent` under the mouse with the box's
edge; it moves down 1px while pressed; the kit's disabled look applies. The chevrons are
drawn 20 (a chevron 10 tall, as tall as the X's 10px cross) and the panel icons 16 (a 12px
panel); builder's call, within the icon rules (even sizes on whole centres). Each has a
tooltip in the mockup's words: "Shrink to half", "Grow to full", "Shrink to a bar", "Grow
to half", "Collapse the sidebar", "Show the sidebar". The window's close X gets its
missing "Close" tooltip with them (the CloseButton component lists that gap). In the header
they sit 6 apart (the mockup's), right to left from the close X, which keeps its place (16
in, 14 down); the header's drag strip, which stops 56 short of the main column's right
today (`BuildMain`, `optionswindow.lua`), stops short of the leftmost.

The one-size rule (decision 4) asks for one button height; these take the close X's 24,
which the kit's 26 tall Button doesn't share today. When the one-button work sets the
height, they follow it with the close X.

**The icons** are four new Lucide icons, made with `tools/lucide-to-tga.cjs` and
registered in `st.icons` (`chevronLeft`, `chevronRight`, `panelLeftOpen`,
`panelLeftClose`), which `tests/core/icons_test.lua` checks. Lucide names the panel icons
for the sidebar, not the arrow: the collapse button wears `panel-left-open` (its arrow
points right) and the show button `panel-left-close` (its arrow points left), as the
owner's flip note asks. Check each name in the pinned Lucide 0.460.0, which calls the
funnel `filter`.

## The sidebar toggle

**Where it sits.**
- Open, Thick and Thin: in the sidebar's foot (`F.foot`, 30 tall), at its right, centred on
  it. The profile line (`F.profile`, today `sideWidth - 37` wide, from 18 in) ends 8 before
  it, so a long profile name is cut sooner than today.
- Open, Blizzard: the same foot, inside the inner frame, left of its divider line.
- Collapsed, Thick and Thin: the footer's left, `PAD` (28) in from the main column's left,
  where `Relayout` puts Reload UI today.
- Collapsed, Blizzard: 16 from the window's bottom left corner (`footerX`, `footerY`),
  where Reload UI is today.

**What collapsing hides.** All of `F.side`: the brand ("SaftUI / Options", also a drag
handle under Thick and Thin; the header still is one), the search box, Edit mode and
Keybind mode (`DrawActions`, `optionsnav.lua`), the page list (`OW.SidebarEntries`) and the
profile line. Builder's call: none of it moves elsewhere. With the sidebar collapsed the
player changes page by showing it again, one click. Pages still open from outside it: a
click on a mover in edit mode (`EM:ShowSettings`, `SaftUI-Core/EditMode/editmode.lua`),
`/sui` with a path, a bag's Edit category (`INV:EditCategory`, `categoriestab.lua`), and a
search result already on screen. Edit mode and keybind mode stay reachable by `/sui edit`
and `/sui kb`, and edit mode by its own bar. The sidebar stays collapsed through all of
these.

**Search.** Collapsing takes the keyboard off the search box and leaves the search as it
is: a results page on screen stays, and a result still opens its page (which ends the
search, as `GoTo` does today). Showing the sidebar shows the box with its text. Builder's
call. The sidebar's scroll (`S.navOffset`) is kept.

## Half size

**The body.** At half the page is drawn by the same body (`st.OptionsBody`) at the half
width, each row read one size larger: a quarter takes half of the narrow body, which is a
quarter of today's; a half row takes the whole line, which is a half of today's; a wide row
stays the whole line. `OB.LayoutRows` already takes a `sizeOf`, and `Body:Draw` already
passes one (`Wide`, for an item's menu, `optionsbody.lua`), so this is one more mapping, not
a new layout.

- **Halves stack in reading order.** A line's left half, then its right, each a line of its
  own, so the rows run in their `order`, as the mockup draws them (Enable, Theme, Width,
  Height, Background, Texture). Each row is as wide as a half row today (a 360 cell against
  359 under Thick and Thin), so no label or control gets narrower.
- **Quarters pair up.** Two quarters still share a line: the action bars' four text items
  make two lines of two (Hotkey and Stack count, then Macro name and Cooldown), and the unit
  frames' Health toggles likewise. Each is as wide as a quarter today (194 against 193), so
  a quarter item's hover line and dots fit as they do now. A lone quarter keeps its width
  with the rest of its line empty, as today. A small input keeps its 60 box
  (`SMALL_INPUT_WIDTH` reads the row's own size).
- **Wide rows** stay a line of their own at the narrower width. A description wraps to its
  cell (`RowCell` gives it the cell's width). A position block (at most 351 wide: THIS, TO,
  AT ITS, OFFSET, `optionsposition.lua`) fits the 360 cell, and the 368 one under Blizzard.
  A bare row is given the narrower width.
- **Lines of buttons.** A right-aligned group joins the line of the wide row before it only
  when that row was wide at full; a half row made wide by the mapping keeps the buttons on a
  line of their own, so its control isn't cut (`OB.LayoutRows`' `wide` has to know the row's
  own size). Builder's call. No page in the window has aligned groups today (Copy from's
  and Unit frame profiles' are in the small dialog). Floating closing lines work as today.
- **Panels, hairlines, dividers** as today (`OB.Dividers`, `OB.Hairlines`): a divider
  between two quarters on a line, none on a line of one row, a hairline between lines.
- **A row too wide for one column.** The Bags' Categories tab is one fill row: a 210 list
  beside a 540 editor, laid out at 774 (`LIST_WIDTH`, `EDITOR_X`, `EDITOR_WIDTH` and
  `frame:SetSize(OB.WIDTH, MIN_HEIGHT)`, `SaftUI-Bags/categoriestab.lua`). It can't be one
  column without a redesign of its own. Nearest: a custom type can say it needs the full
  width (a new `W.Define` field), and at half a page holding one shows, in its place, the
  window's placeholder ("This tab needs the full window.") and a Grow to full button that
  does what the header's grow does. Builder's call, rather than growing the window by
  itself when such a page opens.
- **Search results** are one to a line at half (`DrawResults` makes each a half, too narrow
  at half for a setting's name). Builder's call.

**The header.** The page title is Colus 34 (`page-title`), up to 734 wide today
(`F.title:SetWidth(CONTENT_WIDTH - 40)`). At half it has about 300 left of the arrows, and
"Global Settings" needs about 330 (estimated from the in-game window, where "Unitframes" is
about 225). Builder's call: a title that doesn't fit is drawn at the brand size (26), which
only Global Settings needs today. The description (`F.desc`, set 774 wide) wraps at the
half width, and the tab row, today always 87 from the main column's top (`TABS_TOP`),
starts under its last line when it wraps. Builder's call.

**The tabs** wrap at the body's width, not 774 (`DrawTabRow` wraps at the constant
`CONTENT_WIDTH`, `optionsnav.lua`). Unitframes' 13 tabs, two lines today (9 and 4), take
four or five at half; the page under them scrolls as any page. A single tab still isn't
drawn. **The picker row** (its label, a 170 select, and Copy from beside it once decision
17 lands) fits 388.

**The footer.** At half the main column is 442 wide under Thick and Thin. Close (80) and
Reload UI (about 82), 12 apart, take about 174 at the right; with the sidebar collapsed the
toggle and its gap take 36 at the left. The region between, for the status line and a
page's footer control, is about 200 wide, or about 165.
- The status line (validate errors, `OW:SetStatus`) may wrap to two lines there; two lines
  of the field font fit the 46 tall footer. Builder's call.
- A page's footer control doesn't fit. Unitframes' (`UF.GenerateProfileFooter`, its label
  "Unit frame profile", a 170 select and Manage, 8 apart) is about 370 wide with its label
  and 258 without, and `OW.FooterPlace` can only drop the label. It can't move into the
  page's body either: the body binds every row to the page's own tree (`Body:RowCell`),
  and the control has a tree of its own. Nearest: at half, a page with a footer control
  gets a second footer line for it, above the buttons, the control centred on it with its
  label, drawn as today. The footer grows by that line (34; builder's call) and the body
  ends above it (`bodyBottom`; under Blizzard the inner frame, the sidebar and the main
  column end above the taller footer, as they follow `L.footer`).

**Dialogs and menus at half.**
- The small dialog (568 wide, `optionssmalldialog.lua`) is placed over the window's centre:
  by its own centre on `modular` (`OW:OpenDialog`), by its corner half its size from that
  centre on `fb-pixfix` (commit 215a2df, `W.PlaceCentred`, not merged into `modular` yet).
  It stays so at half. It is wider than W4 (446) and hangs about 61 past each side: fine
  for a dialog over the window. Builder's call. The confirm dialog is placed on the window
  the same way (`optionsdialog.lua`, `W.dialogAnchor`).
- An item's menu (400 wide, `optionsmenu.lua`) hangs from its dots, kept on screen by
  `OW.MenuPlace`, which knows the screen and not the window. A menu from a left-column item
  at W4 can hang up to about 190 past the window's left edge: fine for a popup. Builder's
  call; if it looks wrong in game, `OW.MenuPlace` can learn to prefer the window's edges.
- A dropdown's list hangs from its control, as today.

## Mini

**What shows.** A bar 42 tall (the mockup's, and even). Left to right, 12 in from its left
and 8 apart, ending 8 in from its right (the mockup's): "SaftUI" in Colus 18; the page's
name in `group-title` (Colus 13, `text-grey`); the tab's name in `field`, `text-grey`; grow
(`chevron-left`, "Grow to half"); the close X ("Close"). The buttons are centred on the bar,
9 above and 9 below. The 18 is the mockup's and no type role today: builder's call, add it
to the design system's type table as the mini bar's brand. The page's name is what the
title shows; a page with one tab shows no tab name; with a picker the pick isn't on the
bar but is in the names' tooltip; a search shows "Search" and the searched text. The bar is
as wide as its contents, rounded up to even, at most 400 (the tab's name cut first, then
the page's). Builder's call.

**It is the window.** The bar is the window's own frame, made 42 tall with its sidebar,
main column, footer, grip and edge hidden (`F.side`, `F.main`, `F.footer`, `F.grip`,
`F.sizer`) and the bar's parts shown. `OW:IsShown()` stays true; its Esc catcher, its place
in the screen edge margin, its level (FULLSCREEN_DIALOG, 100), its closing on Close and on
combat all keep working. Builder's call.

**Dragging.** Anywhere on the bar but its buttons moves it, as the header moves the window,
and where it's left is saved the same way (below). The bar's top right corner is the
window's, so a moved bar grows back from where it was left.

**A click on its names** grows it to half, as the grow arrow does: the names are the bar's
biggest target and name the page the player returns to. A drag isn't a click: the bar
tells them apart the way edit mode's movers do (`mover.dragged`,
`SaftUI-Core/EditMode/mover.lua`), since the game can send a click at the end of a drag.
The names' tooltip gives the page's path ("Unitframes > Player > General") and "Click to
grow to half. Drag to move." Builder's call.

**Shrinking to mini closes** an item's menu (`OW:CloseMenu`), the small dialog
(`OW:CloseDialog`) and an open dropdown list (`W.CloseList`), takes the keyboard from any
box, and clears the status line (`OW:SetStatus(nil)`). A confirm can't be open (its catcher
takes the click). The page, tab, pick, scroll and a search stay, as state, and growing back
to half draws them again at the scroll they had, the mockup's "It remembers the page and
scroll position". Builder's call. A render while the bar shows draws no page;
`S.FollowMenu` already closes a menu whose item isn't drawn.

**While Blizzard's color picker is open** the size buttons and the toggle are disabled,
their tooltip saying why (the picker's Cancel needs its row still drawn), as a render waits
for the picker today (`Busy`, `optionswindow.lua`). Builder's call.

## Moving between states

**The right edge and the top stay put.** Today the window is placed and saved by its centre:
`SavePosition` writes `{ point = 'CENTER', x, y, height }`, `RestorePosition` sets it, and
`StartResize` and `UpdateResize` re-anchor by the centre, moving it down by half of each
height change (`optionswindow.lua`, `optionsresize.lua`). Narrowed, it would shrink from
both sides. Builder's call: anchor the window by its top right corner (TOPRIGHT on
UIParent's TOPRIGHT, whole offsets) and save that corner. A size change then moves nothing
at the right or the top, growing taller needs no re-anchoring (the top is the anchor), and
the mini bar sits at the corner by the same anchor. `SavedPosition` already accepts any of
the nine points, so a centre saved by today's version restores as it is, and the first open
converts it to the corner from where the window shows.

**Whole pixels.** With the corner on whole offsets every edge of the window is on a whole
pixel at any width. Every width and height is even all the same, because the small dialog
and the confirm are placed on the window's centre: `W.PlaceCentred` (on `fb-pixfix`) puts
the dialog's corner half its size from that centre, rounded down, and relies on the centre
being whole ("an even size on whole units"). An odd width would put them back on half
pixels, the bug that commit fixed. Hence the 388 and 368 half bodies, the mini bar rounded
up to even, and heights even as today. The main column's parts keep their places from its
top left, which moves by whole numbers only (2 or 210, 17 or 259). The whole-pixel checks
(`tests/lib/pixels.lua`, on `fb-pixfix`) cover the window, its body, the dialog and a menu
in each state, under both layouts.

**Near a screen edge.** The game's clamp keeps the window inside the screen edge margin
(`st:KeepInScreenMargin(window, reach)`, the metal's reach under Blizzard). Grown near the
screen's left edge, the window would pass the margin: the game shows it inside, moved
right, and leaves its anchor alone (`st:GetClampShift`). Builder's call: a size change
never moves the saved corner, so shrinking again brings the window back where it was; only
a drag saves a new corner, from where the window shows, as `SavePosition` does today. The
same at the bottom: a mini bar dragged low grows into a window the clamp lifts into the
margin.

**The height grip.** Full and half share one saved height (builder's call) and both have
the grip and the bottom edge. The mini bar has neither and is always 42; `ApplyHeight` (a
margin change) and `OW.WindowHeight` leave it alone, and `ArtReach` gives it no metal under
Blizzard.

**Scroll.** Between full and half the rows reflow, so the offset can't carry over: the
first row in view stays first in view, at its new place. Half and mini share a layout, so
the exact offset comes back. Builder's call.

**One change at a time.** Each change lays the window out again (today `Relayout` runs only
when the look changes, `laidOut`) and renders once, keeping page, tab, pick and search. A
size button ignores clicks for about a third of a second after the size changed: the mini
bar's grow arrow sits about where half's shrink arrow appears, so a double click would go
to half and straight back to mini. Builder's call.

## What is remembered

- **Where.** `st.config.global.optionsWindow`, beside the corner and the height it holds
  already: `size` (`'half'`, or nil for full) and `sidebar` (`false` while collapsed, nil
  while shown). Account-wide like the window's place and height, never in a profile, so a
  profile switch, copy or reset leaves it (`.agents/architecture.md`, account-wide saved
  values). Kept across `/reload` and logins. Builder's call.
- **Opening `/sui`** opens at the remembered size and sidebar. The mini bar isn't
  remembered: a window closed as a bar, by Close, Esc or combat, opens at half. Builder's
  call: opening to a bar would look like `/sui` had failed.
- **`/sui` typed while the bar shows** grows it to half, on its page.
- **Opening a page while the bar shows** (a click on a mover in edit mode, `/sui` with a
  path, a bag's Edit category) grows it to half on that page, the sidebar as it was. Today
  a click on the mover already selected reopens `/sui` only when it's closed (`mover.lua`:
  "if it's open, leave the user on whatever section they're in"); the bar counts as closed
  there, so that click grows it. Builder's call.
- **The page, tab, pick and scroll** are kept for the session as today (the window's
  `state` and `S.scrollOffset`), across sizes. Nothing new survives a reload.

## Escape and combat

- **Esc** closes the window in every state, the bar too, through its keyboard catcher
  (`EscapeKeys`), on while the window is shown. With a list, menu or dialog open, Esc
  closes that first, as today. Esc never changes the size.
- **Combat** closes the window in every state, the bar too (`Config:PLAYER_REGEN_DISABLED`,
  `SaftUI-Core/Config/config.lua`); `/sui` and edit mode's click refuse in combat as today
  (`OW:Open`, `Config:Open`). Builder's call: the bar holds nothing that can't wait, and
  keeping it would make it the one part of `/sui` shown in combat, with buttons that must
  refuse. It reopens at half or full, as above.
- A state change touches only the window's own frames: no Blizzard frame, nothing secure.

## The Blizzard layout

Under Blizzard's look (`OW.LAYOUT.blizzard`) the window is the character frame's metal with
a title bar; the Settings panel's inner frame (`Options_InnerFrame`) is stretched over a 242
sidebar and the main column; the footer runs across the window under it (`Relayout`). Every
state exists there too. Builder's call: the design system keeps Blizzard's art where the
kit has an equivalent, and the sizes are the kit's.

- **The inner frame is one bitmap**, 886 wide, with the line between the category list and
  the settings drawn in at 199 (`optionswindow` in `SaftUI-Core/themeart_data.lua`),
  stretched so that line lands on the sidebar's edge (`OW.SidebarWidth`). Stretched over a
  narrower window the line moves into the page, and with no sidebar it crosses it.
  Nearest: cut the bitmap at its line with `ThemeArt.Cut`, as the bronze box and the group
  border are cut, into the list part, drawn at the sidebar's 242 as today, and the settings
  part, drawn over the main column at its width. With the sidebar collapsed only the
  settings part shows, its line then the frame's left edge. If its right rim thins too far
  when squeezed to half (687 of the bitmap into 428), cut the rim off too and draw it at its
  own width. To check in game on both clients.
- **W2** is 868 wide, the main column at `innerX` (17).
- **W3 and W4** are 704 and 462, the half body 368 in the flat look (`OB.FLAT`: no panels,
  rows 34 tall), its two columns as far apart as today's quarters (24), so each is as wide
  as a quarter is today (172 against 171).
- **The size arrows** sit on the metal's title bar left of the close button's socket, where
  Blizzard's world map puts its maximize and minimize button. Builder's call: they wear that
  button's red art (`MaximizeMinimizeButtonFrameTemplate`'s expand and condense, names to
  find in wow-ui-source for both clients, each atlas marked per client and checked by
  `tests/core/theme_blizzard_test.lua`), else the Lucide chevrons on the same red face; the
  builder picks after seeing both.
- **The sidebar toggle** has no Blizzard equivalent: the Lucide panel icon on Blizzard's
  panel button (`W.LookButton`), square. Builder's call.
- **Reload UI and Close** are Blizzard's panel buttons: Close 16 from the bottom right
  corner as today, Reload UI left of it, 12 apart; the collapsed toggle 16 from the bottom
  left.
- **W5.** The metal can't be a 42 tall bar (its title bar alone is taller), so the bar is
  drawn as kind `panel`, the tooltip border the small dialog and menus already wear under
  Blizzard (`ThemeArt.KINDS.panel`), with Blizzard's red close button in it rather than in
  a socket, and grow drawn as the size arrows above. The metal reaches 16 above the window's
  frame and 2 (Forever) or 4 (retail) past its right (`st.ThemeArt.MetalReach`): the bar's
  top right goes where the metal's showed, and growing puts the window back under it.
  Builder's call. A theme change while the bar shows keeps it a bar (`st:RedrawThemed`
  draws each frame with its last kind), and growing draws the window's kind again.

## What's left to the builder

- **The half body.** One body whose width follows the size, or one body per width. A body's
  width is fixed when it's made today (`OB.New(content, root, Changed, CONTENT_WIDTH)`),
  and its pooled section titles and notes take that width once, when the pool makes them
  (`title:SetWidth(body.width)`); the scroll child (`F.content`), the title and the
  description are set 774 wide once in `BuildMain`; the tab row wraps at the constant. Each
  has to follow the size.
- **The numbers.** `halfBody` and the footer's control line in `OW.LAYOUT`, and the width
  as a pure function beside `OW.WindowHeight` in `optionslayout.lua`, so tests can call it.
- **The footer** without edit mode: the region runs from the footer's left (or the toggle)
  to Reload UI. `OW.FooterPlace` keeps its rules (centred; else at the right end, beside
  Reload UI; else without its label) with edit mode's inset gone.
- **"Reload UI, bottom left"** in three notes (`ICONS_NOTE` in
  `SaftUI-Core/Config/general.lua`, `TEXT_FONTS_NOTE` in `SaftUI-Core/Media/fonts.lua`,
  `RELOAD_NOTE` in `SaftUI-Core/Media/colors.lua`) and in the design system's README example
  becomes "bottom right".
- Exact gaps and insets, tooltips' second lines, the bar's spacing, within the kit's tokens.
- **Docs.** `.agents/edit-mode.md` (the options window), the design system's
  `OptionsWindow` (states, sizes, the Blizzard theme), `Icons` (the four icons in use) and
  its type table (the bar's 18).
- **Tests.** Each state's width under both layouts; the right edge and top staying; the half
  mapping (a pure function, beside `OB.LayoutRows`' tests); the saved state and its
  conversion from a centre; the bar's contents and its click against a drag; whole pixels
  in each state.

## Risks to check

- Today's tests pin the centre: `tests/core/options_frame_test.lua` and
  `options_resize_test.lua` set and expect `point = 'CENTER'`; `screen_margin_test.lua`
  covers the window's clamp.
- The dialogs on the window's centre: land `fb-pixfix` (215a2df) first, or make the same fix
  here. One odd width anywhere puts the small dialog and the confirm back on half pixels.
- `Relayout` runs only when the look changes; a size change must run the same steps (size,
  inner frame, sidebar, main column, footer) and keep the page, and a theme change must keep
  the size.
- `ApplyHeight`, `RestorePosition` and `StopResize` each set the height or the anchor; each
  must know the bar and the corner.
- The Categories tab's fill row redraws when the body's height changes (`F.body`'s
  `OnSizeChanged`); at half it is the placeholder, and growing back must draw the fill row
  at the view's height again.
- The shared settings work (the action bars' All bars, hover lines, diff icons on section
  titles, `optionsshare.lua`) at half: the cells are today's sizes, but a section title's
  marks and hover line sit in a narrower body.
- If this lands before the edit mode bar, edit mode's buttons still go into the footer
  region (`EditMode/footer.lua`), which has no room at half. Land after it, or hide them at
  half.
- The double click at mini (above), and the arrows' reading itself: confirm both in game.
- Blizzard: the inner frame's cut on both clients, the title bar's maximize and minimize art
  on Forever, the red close button inside a 42 bar.
- Keybind mode closes `/sui` a frame after it starts (`SaftUI-ActionBars/keybindmode.lua`):
  check the bar goes with it.

## Later

- Changing page with the sidebar collapsed: the title as a page menu, or search in the
  header.
- Keys for the sizes and the sidebar.
- The mini bar kept through combat, its buttons refusing until combat ends.
- The Categories tab laid out for one column (its list over its editor).
- Separate heights for full and half, if half wants to be taller.
- A width the player drags between half and full.

## Questions only the owner can answer

1. **The arrows.** Is grow the left-pointing arrow at the left of the pair, with shrink
   pointing right beside the X (the builder's reading, v4)? Or did "flipped when both
   present" mean swapping the two at half only, keeping your first idea of `chevron-left`
   to shrink? Assumed: the builder's reading, as v4 draws it.
2. **The collapsed sidebar.** Should search or the page list stay reachable somewhere while
   it's collapsed? Assumed: no; show the sidebar to change page, as GitHub's file tree.
3. **Reopening.** Should `/sui` open at the size you left it (half stays half; a bar comes
   back as half), or always at full? Assumed: remembered, account-wide; a bar comes back as
   half.
4. **Combat.** Should the mini bar stay on screen through combat? Assumed: no, combat closes
   it as it closes the window.
5. **The Categories tab at half.** Show a "This tab needs the full window" placeholder with
   a Grow to full button, or grow the window by itself when that tab opens? Assumed: the
   placeholder and button.

## Calls made while writing this

Ordered by how much the owner is likely to care.

1. With the sidebar collapsed nothing of it moves elsewhere; the player shows it again to
   change page. Pages still open from edit mode, `/sui` with a path, Edit category and a
   search result on screen.
2. The size and the sidebar are remembered account-wide across reloads, and `/sui` opens at
   them; the mini bar isn't remembered and comes back as half.
3. Combat closes the window in every state, the mini bar included.
4. `/sui`, or opening a page from edit mode or a bag, while the bar shows grows it to half
   on that page; the selected mover's click counts the bar as closed.
5. A click on the bar's names grows it to half; a drag anywhere but its buttons moves it.
6. At half, a page that needs the full width (the Categories tab) shows a placeholder and
   Grow to full, rather than growing by itself.
7. At half, a page's footer control (the unit frame profile) gets a footer line of its own
   above the buttons.
8. Every state exists under Blizzard: the inner frame cut at its line, the arrows on the
   title bar in Blizzard's maximize and minimize art, the bar drawn as a panel at the
   metal's top right.
9. Shrinking to mini closes a menu, the small dialog and a list and clears the status line;
   page, tab, pick, scroll and search stay.
10. At half, a title that doesn't fit (only Global Settings) is drawn at the brand size;
    the description wraps and the tabs start under it.
11. A size button ignores clicks for about a third of a second after a change, so a double
    click on the bar's grow doesn't land on half's shrink.
12. No animation.
13. The window is anchored and saved by its top right corner; a saved centre is converted
    on the first open.
14. Every width and height is even; the half body is 388 (Thick and Thin) and 368
    (Blizzard), a pixel over today's column.
15. The half layout reads each row one size larger; right-aligned buttons join only rows
    that were wide at full.
16. A size change never moves the saved corner; near a screen edge the clamp shows the
    window inside the margin, and shrinking brings it back.
17. Full and half share one saved height; the bar is always 42 and has no grip.
18. Between full and half the first row in view stays first; half to mini and back keeps
    the exact scroll.
19. Search results are one to a line at half.
20. The status line may wrap to two lines at half.
21. The new buttons are the close X's 24 box, chevrons drawn 20 and panel icons 16, grey at
    rest and accent under the mouse; the window's close X gets a "Close" tooltip.
22. The bar's "SaftUI" is the mockup's Colus 18, added to the type table.
23. The bar shows the page and the tab (the pick and the path in its tooltip; a search as
    "Search" and its text), as wide as its contents, at most 400.
24. The small dialog stays centred on the window at half, hanging past a narrow window;
    menus keep hanging from their dots.
25. While Blizzard's color picker is open the size buttons and the toggle are disabled.
26. Collapsing the sidebar leaves a search as it is and takes the keyboard off the box.
27. The bar is the window's own frame with its parts hidden, not a second frame.
28. Under Blizzard the sidebar toggle is the Lucide panel icon on Blizzard's panel button.
