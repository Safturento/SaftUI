# SaftUI bags: switchable views (One bag, Multi bag, Compact, Rows)

Date: 2026-11-10. Status: approved by the user (2026-11-10), after a builder check. Calls marked "my call" are mine, not the user's.

## Intent

The user wants to switch the bag windows between four ways of laying out their items, on the fly, from the window itself: "I'd like to be able to toggle between different bag views", and, asked when they'd switch, "I'd like to be able to switch it on the fly".

Their prior art is Ellesmere's bag window (OneBag, MultiBag and categorised rows). They don't want its sidebar: "that sidebar takes up quite a bit of room with all of the text". Of four mocked placements for the switch, they chose small icons in the title bar.

Making the categories themselves configurable is a separate, later project (`docs/followups.md`, "Bag categories: make the category rules configurable in /sui"). This design uses the categories as they are.

## The views

The user's descriptions, then what was agreed in the review of the mockups (2026-11-10, "this looks great"):

1. **One bag.** "1 bag which shows all items in the same big bag (special bags kept separate underneath) kind of like the blizzard combined bags."
   - Every item in one grid with no category headings, ordered by category priority ("one bag should sort by category priority"), and within a category by SaftUI's existing item sort.
   - Special bags sit underneath, separately.
2. **Multi bag.** "Multi bag, grouped by bags".
   - A section per bag, titled with the bag's name and how full it is, as used / total ("Backpack (16 / 20)").
   - Items sorted within each bag by SaftUI's existing item sort.
   - Within each bag, items are ordered as One bag orders them: by category priority, then the existing item sort within a category. A flat item sort across a whole bag would interleave gear, consumables and trade goods. My call.
3. **Compact.** "Compact view we have today": unchanged.
4. **Rows.** "use the categories that compact does but instead each category gets its own row (with wrap)… In this view the category order should be consistent."
   - Each shown category is a full-width section, its title above its slots, wrapping to further lines as needed.
   - Categories run in category priority order, with empty slots last.

**For every view:** "keep the bags auto sorted according to our existing sort algorithm" (`INV:GetSortedInventory`; the item comparator `sortCategory` on `sortString`, `SaftUI-Bags/category.lua`).

**Empty slots.** "I think the three empty slot options should work here as well". The existing Empty slots setting (`inventory.bag.emptySlots`: `'off'`, `'grouped'`, `'all'`, `SaftUI-Bags/config.lua`) applies in every view:
- **Off:** no empty slots.
- **Grouped:** one empty slot with a count. In Multi bag that's one per bag ("show one per bag with stack count"). In One bag, one for the regular bags and one per special bag section.
- **All:** every empty slot. In Multi bag, each bag's own ("show all for each bag").

Today the setting exists for the bag window only. The bank windows get it too: "banks should also get empty slot options" (the user, 2026-11-10).
- Each of the bank, warband bank and combined bank windows has its own Empty slots setting (`inventory.<window>.emptySlots`), with the same three choices.
- It applies in every view.
- It's shown in `/sui` → Bags beside that window's other settings.
- The bank windows default to `'off'`, how they look today.
- For a bank, "grouped" means one empty slot with a count per bank bag or tab in Multi bag, and one for the whole bank in the other views (one each for the bank and the warband bank in the combined bank).

## The switch

- **Four small icon buttons in each window's title bar,** to the left of the close button, in the order One bag, Multi bag, Compact, Rows.
  - The current view's button is lit.
  - One click switches.
  - Each has a tooltip naming its view.
  - The Bag Slots button and the title stay where they are.
- **Icon art** is the builder's: legible at title-bar size, and no text. The mockup's glyphs (a square, four squares, a dot grid, lines) are placeholders.
- **Every bag-type window gets the switch:** the bags, the bank, the warband bank and the combined bank. Each remembers its own view, saved in the profile, so a reload keeps it. The default is Compact, so nothing changes until the user switches.
- **`/sui` → Bags shows the same choice** as a View select for each window, kept in step with the buttons, so it's searchable and visible in settings. My call.

## How each view is laid out

- **Width.** A window keeps the same width in every view, so switching doesn't make it jump. One bag, Multi bag and Rows lay slots out in lines as wide as the Compact window's column area. My call; the user approved "the same width" in the playback.
- **Height and scrolling** follow today's limits (`maxRows`): past them the window scrolls, as Compact does.
- **Steadiness while open.** Compact holds its layout while a window is open (`INV:HoldLayout`), so selling or moving items doesn't rearrange it. The other views keep the window from shrinking while open, and let items close up within their grid or section. The layout settles afresh when the window closes or the view is switched.
- **Special bags in One bag.** Any bag that only holds certain items gets its own section underneath the main grid, titled as in Multi bag: the reagent bag, and on Forever profession bags, quivers, ammo pouches and soul bags. Their items don't join the main grid. My call, from "special bags kept separate underneath".
- **Banks in Multi bag.** A section per bank bag, or per bank tab where the client has tabs (retail's bank and warband bank tabs). The combined bank shows its bank's sections, then its warband bank's.
- **Currencies.** The bag window's Currencies category keeps its own titled section in every view, laid out as it is today: its counts, its click menu and its Filter button on the section's header. The user: "one bag treat it like a special bag, it should have category headings for those. same with multibag, same with rows".
   - **One bag:** underneath the main grid, with the special-bag sections, each titled.
   - **Multi bag:** after the bag sections.
   - **Rows:** its own row.
   - Its slots wrap at the view's line width.
   - It's always the last section, after empty slots in Rows. My call: "treat it like a special bag" puts it with the sections that sit underneath.
- **Category visibility.** Categories hidden in the profile (`filters.categories[id]`) stay hidden in Compact and Rows, the two category views. One bag and Multi bag show every item: they're about bags, not categories. My call.
   - The Edit view's toggles that set these flags have been unreachable since the user hid the Edit button (commit `aad3671`, May 2025, "remove filter button from bag"). It stays hidden. The view buttons take the title-bar space it was anchored to. My call.
- **Search** works the same in every view: non-matching items dim as they do today.
- **Category priority order** is defined once and shared by One bag and Rows. It's the order SaftUI's category rules run in (`INV.filters.categories`, `SaftUI-Bags/filters.lua`), with the categories that don't come from those rules placed by one fixed rule the builder writes down: equipment sets, reagent-bag subclasses, Miscellaneous, then empty slots last. It lives in one place, because the category configuration project will later make it configurable.

## Constraints

- **Combat.** Bag windows hold Blizzard's item buttons, so moving them can be blocked in combat (`.agents/taint.md`). A view switch must never cause an `ADDON_ACTION_BLOCKED`. Where a layout can't change in combat, the switch is applied when combat ends, and the button shows the chosen view meanwhile. Follow what `INV:UpdateContainerLayout` and the bag code already do for combat.
- **Taint:** no fields written on Blizzard's frames (`.agents/taint.md`, rule 1).
- **Both clients:** Forever (16001) and retail (120000). Forever has no reagent bag and no warband bank; it has profession bags, quivers and so on.
- **Options:** every option has a desc, SaftUI's `size`, and no Ace `width` (project 2's finished-page rules, checked by the Bags page tests).
- **Themes run in parallel** (`docs/superpowers/plans/2026-11-10-saftui-themes.md`). Its Task 5 converts the bag code's draw calls. If this work lands after Themes, new frames (the view buttons, section headers) are drawn the Themes way, with a kind. If before, the old way, and Themes' scan catches them.

## Non-goals

- **Configurable categories,** user categories and nested categories: the separate followup.
- **An Ellesmere-style text sidebar.**
- **Physically sorting items in the bags.** The views sort what's shown, as today.
- **The item sort's text comparison of item levels** (`sortString`, `SaftUI-Bags/category.lua:147`): a followup, not changed here.

## Anti-goals

- Switching views that rearranges or resizes the window in a jarring way, or loses the scroll position for no reason.
- Any view that doesn't match the existing sort.
- A default that changes how anyone's bags look today (Compact stays the default).
- A blocked-action error from switching in combat.

## Tests

- **The buttons:** each window's title bar has the four buttons in order, with tooltips; the current one is lit; a click switches and saves the view per window; `/sui`'s View select stays in step.
- **One bag:**
  - one grid in category priority order, then the existing item order within a category;
  - special bags in their own sections underneath, with their items not in the main grid;
  - each Empty slots mode;
  - Forever and retail bag sets.
- **Multi bag:**
  - a section per bag with "name (used / total)";
  - items sorted within each bag;
  - the empty-slot modes per bag;
  - bank sections per bag or tab;
  - the combined bank's order.
- **Currencies:** in every view, its own titled section in the place above, with its counts, click menu and Filter button working; hidden when its hide flag is set.
- **Rows:**
  - a section per shown category in priority order, empty slots last;
  - wrapping at the window's line width;
  - hidden categories stay hidden.
- **Bank empty slots:** each bank window's own setting, defaulting to off, in each view, for each of the three modes.
- **Width:** the same window width in all four views.
- **Combat:** a switch in combat waits, then applies, with no protected call made in combat.
- **Compact:** unchanged, and the existing bag tests still pass.

## Left to the builder

- The icon art.
- The exact name, place and contents of the shared category priority order (within the rule above).
- How the layout code is split between the four views. Compact's code (`INV:CompactCategories`, `HoldLayout`, `PlaceHeldCategories`) stays as is.
- How Multi bag finds each bag's or tab's name, and how fullness is counted.
- Descs for the View select and the button tooltips.
