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
| Tabs | `tab`, 22 apart, top at 87; current in `text` with a 2px `accent` underline, others `text-grey`, disabled at `alpha-disabled`; a `line` rule under them; wrap at 774 with 6 between lines | `tabs-top`, `tab-gap`, `tab-wrap-gap` |
| Picker | its label in `field`, a `Select` 10 after it, 12 under the tabs | `picker-gap`, `label-gap` |
| Body | 774 wide, scrolls; the kit's scroll bar 3 wide, 10 outside | `content-width`, `scrollbar-width`, `scrollbar-out` |
| Footer | 46 tall under a `line`: Reload UI left, Close right, a status line in `text-red` | `footer-height` |
| Close | `CloseButton`, 16 in and 14 down | `window-close-x`, `window-close-y` |
| Resize grip | bottom right, 16 x 16 | |

The profile line at the sidebar's foot reads "Profile: Default", the label in `text-grey`.

## States

- The window is dragged by its header or brand and grows taller by the grip or its bottom edge; its size is saved account-wide.
- Edit mode on: Grid, Snap to grid and Snap to frames join the footer between Reload UI and Close (today as Core buttons, see Discrepancies).
- Search: results grouped by page, a row per match, `accent-fill` under the mouse.

## Blizzard theme

1110 wide, 728 tall at least, in the character frame's metal with "SaftUI Options" in its title bar (Window titles font). The sidebar is 242 wide with the Settings list art (`Options_List_Active`, `_Hover`), gold names and banners for the groups; the brand is gone. Tabs take `Options_Tab_*` with `Options_HorizontalDivider`; the search box is `SearchBoxTemplate`; Reload UI and Close are panel buttons 16 from the corners; the close button sits in the metal's socket.

## Do and don't

- Do put Position last on a page, in its own section.
- Do give every option a `desc`; the label's tooltip shows it.
- Don't add tabs to a page that fits on one; fold small parts into `MenuItem`s first.
- Don't draw your own controls on a page: the Bags' Categories tab does, and it is listed under Discrepancies.
