# Bag Views Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each bag-type window (bags, bank, warband bank, combined bank) can switch on the fly between four views: One bag, Multi bag, Compact (today's) and Rows. The switch is four icon buttons in the title bar, and every view keeps the existing sort.

**Architecture:**
- **Compact stays exactly as it is.** The other three views share one layout: a vertical stack of full-width sections in the window's scroll frame.
- **A section is an ordinary category frame** (`INV:CreateCategory`/`INV:UpdateCategory`), with a title or none, whose slots run in lines as wide as the window.
- **A pure data step turns the window's items into an ordered list of sections for a view,** using one shared category-priority order.
- **Slots are secure buttons,** so re-anchoring them to a new line width happens only out of combat. A view switch made in combat waits for combat's end.

**Tech Stack:** Lua 5.1 (WoW), Ace3 option tables, SaftUI's options window; tests on lupa's Lua 5.1 through `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-10-saftui-bag-views-design.md` (approved 2026-11-10). Read it; its "My call" items are binding.

**Starting point:** `modular` after the Themes plan (`docs/superpowers/plans/2026-11-10-saftui-themes.md`) has merged. Any new frame with a border is drawn the Themes way: `st:SetTemplate`/`st:SetBackdrop` with `(theme, background, kind)`, in the `st:` form. New options use `st.Config.generators`.

**Code map:**
- Containers and layout: `SaftUI-Bags/container.lua` (`INV:CreateContainer` ~9, `INV:UpdateContainer` ~296, `INV:UpdateContainerLayout` ~565, `INV:CompactCategories` ~464, held layout ~514-563).
- Data: `SaftUI-Bags/category.lua` (`INV:GetSortedInventory` ~206, `INV:GetItemCategory` ~23, `INV:CreateCategory` ~302, `INV:UpdateCategory` ~347, empty slots ~164-199).
- Slots: `SaftUI-Bags/slot.lua` (`INV:SetSlotPosition` ~5, `INV:CreateSlot` ~259, `INV:AssignSlot` ~87).
- Columns: `SaftUI-Bags/inventory.lua` (`INV:UpdateConfig` ~125-189).
- Currencies: `SaftUI-Bags/currencies.lua` (`INV:UpdateCurrencyCategory` ~232).
- Options: `SaftUI-Bags/options.lua` (`BuildWindow` ~9).
- Test helpers: `tests/bags/container_helpers.lua`.

## Global Constraints

- **Clients:** WoW Forever (16001) and retail (120000).
  - `st.retail` is true on both. Forever has no reagent bag and no warband bank, and has profession bags, quivers, ammo pouches and soul bags.
  - The bank's bag IDs are `Enum.BagIndex.CharacterBankTab_N` on both; the warband bank's are `AccountBankTab_N` (retail only).
- **Combat:** item slots are secure (`ContainerFrameItemButtonTemplate`).
  - Never call `SetPoint`, `ClearAllPoints`, `SetParent`, `SetSize`, `Show` or `Hide` on a slot, or on a frame a slot is anchored to, from code that runs only because of a view switch while `InCombatLockdown()`.
  - A view switch in combat is applied by `st:QueueAfterCombat('InventoryView', …)`, with one pending run.
  - `.agents/taint.md`: no fields on Blizzard frames.
- **Settings:**
  - `config[id].view` for `id` in `bag`, `bank`, `warband` and `combinedbank`. Values: `'onebag'`, `'multibag'`, `'compact'`, `'rows'`. Default `'compact'`.
  - `config[id].emptySlots` for the same four windows. Values: `'off'`, `'grouped'`, `'all'`. Default `'off'`; `bag` keeps its existing key.
- **Words the user sees:**
  - views: "One bag", "Multi bag", "Compact", "Rows" (button tooltips and `/sui`);
  - `/sui` options: "View" and "Empty slots", with the existing labels Off / Grouped / Every slot;
  - section titles: a bag's name, then " (used / total)", e.g. `Backpack (16 / 20)`; categories as today, `Name (n)`.
- **Order of the title-bar buttons:** One bag, Multi bag, Compact, Rows, to the left of the close button. The current view's button is lit with Buttons → Blue (`st.config.profile.colors.button.blue`).
- **Line width** (One bag, Multi bag, Rows): a section's slots run in lines of `perrow * maxColumns` slots.
  - The section is `(btnW + spacing) * perrow * maxColumns - spacing` wide, the window's full content width: the same width as Compact with all its columns in use.
  - Compact keeps today's behaviour, narrower only when it uses fewer columns.
- **Every option has a desc and SaftUI's `size`, and no Ace `width`.**
- **Files:** keep line endings; never `sed -i` a CRLF file.
- **`tests/run` passes at the end of every task.**
- **Commit trailers:**
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsM3V6p9vWPEFz7WA9o
  ```

## Review Focus

1. **A view switch in combat** waits and is applied after combat, with no protected call in combat (Task 4 test).
2. **Loot arriving while a section view is open** updates the sections in place, and the window doesn't shrink while open (Task 2 test).
3. **A bag with no items in Multi bag and Empty slots off** keeps its titled section, e.g. `Bag (0 / 10)`, with no slots, so the bag is still visible (Task 3 test).
4. **Switching views back and forth** leaves Compact exactly as before: the same category frames, slot counts and layout. No slots or frames leak beyond the pools (Task 2 test).
5. **Search while in a section view** dims non-matching items in every section, as in Compact (Task 3 test).

## Order

- Task 1 comes first.
- Task 2 after 1.
- Tasks 3 and 4 can run in parallel after 2: 3 touches the data and layout files, 4 the title bar and options.
- Task 5 runs last.

---

### Task 1: Category priority, bag info and view sections (data only)

**Files:**
- Create: `SaftUI-Bags/views.lua`, after `category.lua` in `SaftUI-Bags.toc`.
- Modify:
  - `SaftUI-Bags/config.lua`: `view = 'compact'` for `bag`, `bank`, `warband` and `combinedbank`; `emptySlots = 'off'` for `bank`, `warband` and `combinedbank`.
  - `SaftUI-Bags/category.lua`: empty-slot building reads `config[id].emptySlots` for every window, not just `bag`.
- Test: `tests/bags/views_data_test.lua` (new). Add a `C_Container` stub to `tests/bags/container_helpers.lua` (or a new `tests/bags/bag_world.lua`): bags with slots, items, free counts, a bag family, and `C_Container.GetBagName`.

**Interfaces (produces):**
- `INV:CategoryRank(name) -> number`: one order shared by every view.
  - `Set: …` categories first, alphabetically: rank `0 + i/1000`.
  - Then `INV.filters.categories` in their order: rank `i`.
  - Then `'Miscellaneous'`: rank `#filters + 1`.
  - Then `INV.EMPTY_SLOTS_CATEGORY`: rank `#filters + 2`.
  - Any other name: rank `#filters + 1`, alphabetically after Miscellaneous.
- `INV:SortByPriority(items) -> items`. Sorts in place by `CategoryRank(GetItemCategory(info))`, then the existing item comparator (`sortString` descending, `category.lua` `sortCategory`). Empty-slot infos go last.
- `INV:GetBagInfo(bagID) -> { id, name, total, free, special }`.
  - `name`: `C_Container.GetBagName(bagID)`, else a tab name where the client has one, else `BAG_NAME_BACKPACK`/`"Bag N"`/`"Bank tab N"`.
  - `special`: `INV:IsReagentBag(bagID)` or a non-zero bag family, the second return of `C_Container.GetContainerNumFreeSlots`. The backpack and bank tabs are never special.
- `INV:GetViewSections(id, view) -> sections`. An ordered array of `{ key, title, items, kind }`, where `kind` is `'main'`, `'bag'`, `'category'` or `'currencies'`, and `title` is a string, or `false` for no heading. It reads the same items as `GetSortedInventory`, honouring `stackItems` and loading. By view:
  - **`'onebag'`:**
    - one `'main'` section (`title = false`) with every item in non-special bags, `SortByPriority`;
    - then one `'bag'` section per special bag, titled `"<name> (<used> / <total>)"`, `SortByPriority`;
    - then `'currencies'` (bag window only, when the Currencies category exists).
  - **`'multibag'`:** one `'bag'` section per bag ID of the window, in the window's bag order, titled as above, `SortByPriority`; then `'currencies'`.
  - **`'rows'`:** one `'category'` section per non-empty category, ordered by `CategoryRank`, titled as Compact titles it (`"Name (n)"`); Empty Slots last if any; then `'currencies'` last.
  - **`'compact'`:** not used; Compact keeps `GetSortedInventory`.
- **Empty slots by mode,** read from `config[id].emptySlots`:
  - `'off'`: none.
  - `'all'`: one per free slot, at the end of the section that owns its bag. In Rows that's the Empty Slots section.
  - `'grouped'`: one info with `.count = free`:
    - Multi bag: one per bag, in its section.
    - One bag: one for the main section, and one per special bag section.
    - Rows and Compact: one per kind, as Compact does today for the bag window (normal and reagent). For the bank windows, one for the bank; the combined bank gets one for the bank and one for the warband bank.

- [ ] **Step 1: Write the failing tests** in `tests/bags/views_data_test.lua`, on the stubbed world. Backpack 20 slots; bag 1 (10 slots, family 0); on retail, a reagent bag (36); on Forever, a herb bag (family 32), with items across categories.
  - `'CategoryRank: sets, then the rules in order, then Miscellaneous, then Empty Slots'`.
  - `'onebag: one untitled main section in priority order, then a section per special bag, then currencies'`. Check the herb bag's items aren't in main; titles `"Herb Bag (2 / 12)"` from the stub's names.
  - `'multibag: a section per bag in bag order, titled name (used / total), each in priority order'`.
  - `'multibag: a bag with no items keeps its titled section'`, as in `Bag (0 / 10)` (Review Focus 3).
  - `'rows: a section per category in priority order, Empty Slots then Currencies last'`.
  - `'empty slots per mode, per view'`: off, grouped and all for each of onebag, multibag and rows, and the bank window (`id = 'bank'`) in grouped, as one per bank, and multibag, as one per tab.
  - `'Forever: no reagent bag; a profession bag is special'`. `'retail: the reagent bag is special'`.
  - `'defaults: every window is compact with empty slots off'`.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/bags/views_data_test.lua` fails on missing functions.
- [ ] **Step 3: Implement** `views.lua` and the config and empty-slot changes. Compact's output from `GetSortedInventory` must stay identical for the bag window. The existing bag tests are the check.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `bags: view sections: a shared category priority, bag info, and One bag, Multi bag and Rows section lists; empty slots for every window`

### Task 2: The section layout, and Rows

**Files:**
- Modify:
  - `SaftUI-Bags/container.lua`: `INV:UpdateContainer` and `INV:UpdateContainerLayout` dispatch on `config[id].view`. Compact keeps today's path untouched; the other views go to `INV:LayoutSections`.
  - `SaftUI-Bags/category.lua`: `INV:UpdateCategory` takes an optional title, and a line width.
  - `SaftUI-Bags/slot.lua`: `INV:SetSlotPosition` takes the line width, and handles `perrow == 1`.
  - `SaftUI-Bags/currencies.lua`: the currency slots wrap at the given line width.
- Test: `tests/bags/views_layout_test.lua` (new), using `container_helpers.lua` (`H.container`, `H.layout`, `H.cat`).

**Interfaces:**
- Consumes `INV:GetViewSections` (Task 1).
- Produces:
  - `INV:LineSlots(id, view) -> number`: `perrow` for `'compact'`, else `perrow * maxColumns`.
  - `INV:LayoutSections(container, sections)`. It shows one category frame per section, keyed `section.key`: Rows reuses the category frames, named by category, and the other kinds make `'view:'..key` frames through `INV:CreateCategory`.
    - Each frame is full width and stacked top to bottom, `buttonspacing` apart, in the scroll child.
    - Its header is hidden and takes no height when `title == false`.
    - Its slots are positioned for `LineSlots`.
    - Category frames not in `sections` are hidden. Compact's columns hide in section views and come back for Compact.
  - Window size: the width is the line width plus padding. The height is as Compact's: header, search, footer, and a scroll frame of at most `maxRows` rows.
  - While open, the window doesn't shrink: keep `heldSize` as Compact does, released on hide and on a view switch.
  - `INV:ApplyView(id)`. Re-anchors every slot of the window to the current view's line width (`SetSlotPosition`), then lays out. Out of combat only: in combat it queues `st:QueueAfterCombat('InventoryView', …)`, and the next layout still uses the old line width.
  - `INV:UpdateCategory(id, name, items, title, lineSlots)`. With no `title`, the header text is today's `"%s (%d)"`; `title == false` hides the header. `numRows = ceil(#items / lineSlots)`.

- [ ] **Step 1: Write the failing tests** in `tests/bags/views_layout_test.lua`:
  - `'rows: each category full width, stacked in priority order, wrapping at perrow * maxColumns'`: 3 × 3 = 9 per line; a category of 12 has 2 rows.
  - `'rows: the window is as wide as Compact with every column in use'`.
  - `'rows: categories hidden in the profile (filters.categories[id]) stay hidden'`.
  - `'switching compact → rows → compact restores Compact exactly'`: the same `H.where`, the same slot counts, and no new frames on the second switch (Review Focus 4).
  - `'loot arriving in rows view updates the section and the window does not shrink while open'` (Review Focus 2).
  - `'an untitled section has no header height'`.
  - `'SetSlotPosition with perrow 1 stacks slots vertically'`.
  - `'ApplyView in combat queues, and applies after combat'`: `stub.in_combat`, then regen.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.** Rows goes through `LayoutSections` with `GetViewSections(id, 'rows')`. `'onebag'` and `'multibag'` use the same path, with Task 1's sections; they are only tested in Task 3.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `bags: section layout for full-width views, and the Rows view`

### Task 3: One bag and Multi bag

**Files:**
- Modify: `SaftUI-Bags/views.lua` and `SaftUI-Bags/container.lua`, only as needed beyond Task 2. Currencies' section (`SaftUI-Bags/currencies.lua`) gets its place last, with its Filter button on the section's header.
- Test: `tests/bags/views_onebag_multibag_test.lua` (new), combining Task 1's world with Task 2's layout helpers.

**Interfaces:** consumes `INV:GetViewSections`, `INV:LayoutSections`, `INV:ApplyView` and `INV:UpdateCategory(…, title, lineSlots)`.

- [ ] **Step 1: Write the failing tests:**
  - `'onebag: the main grid has no heading; special bag sections and Currencies follow, titled'`.
  - `'multibag: a titled section per bag; the bank window shows a section per tab'`.
  - `'multibag: an empty bag with Empty slots off still shows its title'` (Review Focus 3).
  - `'combined bank multibag: the bank's sections, then the warband bank's'`.
  - `'search dims non-matching items in every section'` (Review Focus 5). Use the existing search path (`INV:UpdateSearchFilter`/`SearchMatches`).
  - `'Currencies is the last section in each view, its Filter button on its header, hidden when its hide flag is set'`.
  - `'onebag and multibag show items of categories hidden in the profile'`.
  - `'onebag and multibag are as wide as rows'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `bags: One bag and Multi bag views`

### Task 4: The switch: title-bar buttons and options

**Files:**
- Modify:
  - `SaftUI-Bags/container.lua`: the four buttons in each window's header, made in `INV:CreateContainer`. Remove the hidden Edit button's `TOPRIGHT -30` anchor clash by anchoring the view buttons to the close button's left. The Edit button stays hidden; its checked state is still read.
  - `SaftUI-Bags/options.lua`: `BuildWindow` gets View (select) for every window, and Empty slots for every window (today `bag` only).
- Test: `tests/bags/views_switch_test.lua` (new), plus `tests/core/options_frames_pages_test.lua` updates if it lists the Bags options.

**Interfaces:**
- Consumes `INV:ApplyView(id)` (Task 2).
- Produces `INV:SetView(id, view)`. It saves `config[id].view`, lights the button, then `INV:ApplyView(id)`. In combat the button lights at once, and the layout follows after combat.

**The buttons:**
- Each is a small square button, the header height minus 8.
- Its icon is drawn with plain textures as in the mockup: a square, four squares, a dot grid, lines. They need nothing from the client, so they look the same on both. Art is the builder's, within this.
- Bordered with `st:SetBackdrop(button, 'theme', 'theme', 'small')`.
- Lit (Buttons → Blue border) when current.
- A tooltip names the view.

**The options:**
- **View** select: values in the order and words above; `set` → `INV:SetView(id, value)`.
- **Empty slots** select: off / grouped / all, as today's bag option, for every window. `set` → `INV:QueueUpdate(true)`.

- [ ] **Step 1: Write the failing tests:**
  - `'each window has the four view buttons in order left of the close button, with tooltips'`.
  - `'a click switches the view, saves it per window, and lights its button'`.
  - `'the /sui View select and the buttons stay in step'`.
  - `'a switch in combat lights the button at once and lays out after combat, with no slot moved in combat'` (Review Focus 1).
  - `'every window offers Empty slots; the bank windows default to off'`.
  - `'View and Empty slots have descs, a size, and no width'`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes.
- [ ] **Step 5: Commit.** `bags: view buttons in the title bar, and View and Empty slots for every window in /sui`

### Task 5: The currency Filter icon, and docs

**Files:**
- Modify: `SaftUI-Bags/currencies.lua`. The Currencies Filter button shows an icon in place of its "Filter" text. Use the icon the user picks from `/suiicons`, recorded in the SDD ledger at execution time; if none is recorded, keep the text and note it.
  - The button keeps its toggle behaviour, gains a tooltip "Filter", and is sized to the icon.
  - It reads the same on both clients: if the picked atlas is missing on one client (`C_Texture.GetAtlasInfo`), fall back to the text.
- **Docs:**
  - `README.md` (Bags: the four views, the title-bar switch, Empty slots for the banks);
  - `.agents/testing.md` (the new bags tests and the `C_Container` stub);
  - `.agents/architecture.md`, if the module list or file roles change (`views.lua`);
  - `docs/followups.md`, cross-linking the bag views from the category configuration followup.
- Test: extend `tests/bags/slot_quality_test.lua` or `views_switch_test.lua`: `'the currency Filter button shows the icon, keeps its toggle, and falls back to text when the atlas is missing'`.

- [ ] **Step 1: Write the failing test.**
- [ ] **Step 2: Run it; it fails.**
- [ ] **Step 3: Implement,** and update the docs.
- [ ] **Step 4: Run all tests.** `tests/run`: everything passes. Run `agents-doc-parity-check` and `readme-freshness-check`.
- [ ] **Step 5: Commit.** `bags: an icon for the currency Filter button; docs for the bag views`
