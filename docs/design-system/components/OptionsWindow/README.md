# OptionsWindow

The `/sui` window: a sidebar of pages on the left, and on the right the page's title, its tabs, an optional picker, the page body and a footer.

## When to use

There is one. A module adds a page by returning an Ace options group from `GetConfigTable` (its `category`, Frames, Combat or Info, places it in the sidebar); you never draw the window. Build a page's content from `Section`, `Row` and the controls.

## What the consumer provides

- The page: `name` (the title, sidebar entry and search group), `desc` (the grey line under the title; many pages have none), child groups as tabs, or `childGroups = 'select'` with `pickerLabel` ('Unit', 'Bar') for a picker.
- Options, each with a `desc`. No Ace `width`; use `size` (`'small'`, normal, `'wide'`).
- A `/sui` command with its own sidebar button: `st.Config:AddCommand`.

## Anatomy and sizes

| Part | Size | Tokens |
| --- | --- | --- |
| Window | 1040 wide, 700 tall at least, drawn `window` kind, solid | `window-width`, `backdrop` |
| Sidebar | 208 plus a 1px edge | `sidebar-width`, `sidebar`, `line` |
| Brand | 73 tall: "SaftUI" in `brand`, "Options" in `small` grey, 18 in | `brand-height`, `brand-pad` |
| Search and commands | search box over Edit mode and Keybind mode, 24 tall, 6 apart, 8 under the search | `field-height`, `action-gap`, `search-gap`, `action-pad` |
| Entries | 26 tall, `label`, 18 in (Global settings, Profiles) or 22 | `nav-item` |
| Group headers | `group-title` in `text-grey`, 29 tall | `nav-group` |
| Selected entry | `accent-fill` with a 2px `accent` bar at its left | `accent-fill`, `mark-width` |
| Entry under the mouse | `sidebar-hover` | `sidebar-hover` |
| Title | `page-title`, 20 from the top, 28 in | `head-top`, `window-pad` |
| Description | `field` in `text-grey`, 4 under the title | `note-gap` |
| Tabs | `tab`, 22 apart, top at 87; current in `text` with a 2px `accent` underline, others `text-grey`, disabled at `alpha-disabled`; a `line` rule under them; wrap at the body's width with 6 between lines | `tabs-top`, `tab-gap`, `tab-wrap-gap` |
| Picker | its label in `field`, a `Select` 10 after it, 12 under the tabs; a pick's control after it on the same line, 12 apart: a button as it is, any other control with its name in `field` (`text`) and its widget 10 after it. A piece that would pass the body's width starts a new line at the left, 8 under the last (24 tall each) | `picker-gap`, `label-gap`, `picker-line-gap` |
| Body | 774 wide (388 at half), scrolls; the kit's scroll bar 3 wide, 10 outside | `content-width`, `scrollbar-width`, `scrollbar-out` |
| Footer | 46 tall under a `line`: Close at the right end, Reload UI 12 left of it, and from 28 in to 12 before Reload UI a status line in `text-red` (two lines at most) | `footer-height` |
| Close | `CloseButton`, 16 in and 14 down, with its tooltip | `window-close-x`, `window-close-y` |
| Size buttons | the close X's 24, `minimize-2` (shrink, at full and half) and `maximize-2` (grow, at half) at 16, shrink at the left of the pair and the button beside the X shrink at full and grow at half, 6 apart and from the X, top-aligned with it; the drag strip stops 18 short of the leftmost and the title 8 | `close-size` |
| Resize grip | bottom right, 16 x 16 | |

The profile line at the sidebar's foot reads "Profile: Default", the label in `text-grey`.

## States

- The window is dragged by its header or brand and grows taller by the grip or its bottom edge; its size is saved account-wide.
- Full and half: the arrow left of the X shrinks the window to half (654 wide under Thick and Thin, the page in one column, 388 wide body); it stays anchored by its top right corner, so its left edge moves and the X and the shrink arrow stay under the mouse. Grow, which then appears 6 left of it, goes back to full. The title takes the narrow room (the brand font when it won't fit), the description wraps, and the row first in view stays first in view. The size is remembered; a screen too narrow for full opens it at half and says why in Grow's tooltip (red). While the color picker is open the arrows are disabled, with the red line "Close the color picker first." At half the same arrow (now shown) takes the second step, to the bar.
- The sidebar toggle (W2 and W4): `panel-left-open` (pointing right, "Collapse the sidebar", 26 square with a 16 icon) at the right of the sidebar's foot, 8 in, centred on its 30, with the profile line ending 8 before it. It collapses the sidebar at full and at half: the window narrows from its left (208 narrower under Thick and Thin, 242 under Blizzard), so the page, the close X and the top right corner stay where they are, and the sidebar's state is kept apart from the size, the bar keeping it. The button then sits at the footer's left (`panel-left-close`, pointing left, "Show the sidebar"), 28 in from the main column and centred on the footer under Thick and Thin and 16 in and 16 up from the window's bottom left under Blizzard (on Blizzard's panel button, where only the settings part of the inner frame shows, from the window's left), and the footer's region starts 12 after it. The search in progress is kept and the keyboard leaves its box; open menus, lists and dialogs close. It is disabled, with the red line "Close the color picker first.", while the color picker is open, and with "The screen is too narrow for the sidebar at full size. Shrink to half first." when showing the sidebar would pass the screen. Remembered account-wide.
- Collapsed, what the sidebar offered moves (W2 and W4; none at the bar):
  - The footer: after the toggle, 6 apart and level with it, Search (`search`), Edit mode (`move`) and each command that has an icon as a 26 square icon button with a 16 icon while it fits before Reload UI, grey and accent under the mouse, each with its tooltip ("Search settings", "Edit mode", "Keybind mode" with `keyboard`). A command with no icon, and any that doesn't fit, is under one last `ellipsis` button ("More") that opens the Select's list of their labels; there are no text buttons in the footer, and nothing overlaps Reload UI or Close. Search and Edit mode are `accent` while a search or edit mode is on. Under Blizzard each is on Blizzard's panel button. The region (status line, a page's footer control) starts 12 after the last; when it has no room the status line goes, then the control, never a button.
  - Search: its icon opens the sidebar's own box in a small `panel` over the footer (the box and 8 round it, its bottom left 6 over the icon's top left) with the keyboard in it. It closes on Enter, Esc (which clears the search), any mouse down outside it (that click only closes it, as the Select's list does) and the icon again; the search stays, so its results page stays on screen, and a result opens its page and ends the search with the sidebar still collapsed.
  - The page list: the page's title gets a `chevron-down` (16, `text-grey`, `accent` under the mouse) 8 after its text, in the title's room (24 less than with the sidebar), and the title with it opens the Select's list of pages: the groups as grey captions, a disabled page dim, the open page in `accent`, up to 12 rows then a scroll; a pick opens that page as a click in the sidebar does. Tooltip "Choose a page".
- The bar (W5): the window made a small panel, 42 tall and as wide as its parts, at its top right corner, with the sidebar, the page, the footer and the grip gone. Left to right, 12 in and 8 apart: "SaftUI" in the `brand-mini` style (Colus 18; "Saft" in `text-normal`, "UI" in `accent`), the page's name in `group-title` and the tab's name in `field`, both `text-grey` (a page with one tab shows no tab name; a search shows "Search" and the text in quotes), then Grow (`maximize-2`, "Grow to half", the size buttons' 24 square with a 16 icon) and the close X, 8 in from the right, both centred on the 42. The width is rounded up to even and at most 400, the tab's name cut first and then the page's. Dragging the bar anywhere but its buttons moves it; a click on the names or Grow goes back to half, at the page, tab and scroll it had (the names' tooltip gives the path and "Click to grow to half. Drag to move."). Esc, the X and combat close it; it opens again at half. Opening a page from elsewhere grows it to half on that page.
- Edit mode on: its controls are not in the footer; they are on edit mode's bar (a small two-row bar on the top edge of the screen, or a floating window).
- Search: results grouped by page, a row per match, `accent-fill` under the mouse.

## Blizzard theme

1110 wide, 728 tall at least, in the character frame's metal with "SaftUI Options" in its title bar (Window titles font). The sidebar is 242 wide with the Settings list art (`Options_List_Active`, `_Hover`), gold names and banners for the groups; the brand is gone. Tabs take `Options_Tab_*` with `Options_HorizontalDivider`; the search box is `SearchBoxTemplate`; Close is a panel button 16 from the bottom right corner and Reload UI one 12 left of it; the close button sits in the metal's socket and the size arrows sit on the title bar 6 left of it, centred on it, wearing Blizzard's own red expand (grow) and condense (shrink) buttons, `RedButton-Expand` and `RedButton-Condense` with their pressed and disabled art and the additive `RedButton-Highlight`, at 24 square as `MaximizeMinimizeButtonFrameTemplate` draws them, on both clients (a client without them would keep Lucide chevrons on Blizzard's panel button; the in-game check keeps the better). The bar is a panel in the tooltip border's art, at the metal's top right corner (where the window's metal was), with Blizzard's red close button in it, centred, 8 in from the right, and Grow, in Blizzard's expand art, 8 left of it. The inner frame is cut at its divider into the list's part over the sidebar and the settings' part over the main column, which squeezes at half (watch its right rim: if it thins too much it wants a third cut).

## Do and don't

- Do put Position last on a page, in its own section.
- Do give every option a `desc`; the label's tooltip shows it.
- Don't add tabs to a page that fits on one; fold small parts into `MenuItem`s first.
- Don't draw your own controls on a page: the Bags' Categories tab does, and it is listed under Discrepancies.
