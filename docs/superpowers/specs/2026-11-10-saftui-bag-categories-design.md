# SaftUI bags: categories you can see and edit in game

Date: 2026-11-10. Status: draft for the user's approval, after a builder check. Calls marked "my call" are mine, not the user's.

## Intent

The bag categories (which items go where, and in what order) are hard-coded Lua today (`SaftUI-Bags/filters.lua`). The user wants them in the game: "I'd like to expose the category configurations in the config, we have a lot of complexity to the filters right now and it's hard coded".

Their examples:
- "I might want to separate herbs and ore from other trade goods using the item subclass."
- "I've also noticed an item or two showing up under the 'Delve' category in forever but it's not obvious why without digging into the filter code - being able to see that in game and adjust it would be great."

The Delves mystery has a cause: the Delves filter matches any item whose tooltip contains " Curio", lowercased and as a substring, so "Curious" and "curiosity" match too. Nothing in the game shows that.

On scope: "just take a look at how deep the existing filters are and what item info is available from the table to see what sort of filter blocks we could build."

Prior art: Ellesmere's bag window. The user liked its categories but not its text sidebar ("takes up quite a bit of room").

The research behind this design is summarised under "Today" below.

## What the user decided

- **Rules are built from blocks** combined with AND and OR, with grouping: "some blocks will be somewhat freeform ('tooltip text matching <input box>') while others might be a drop down ('item from expansion <dropdown with checkboxes>') these can be combined with and and or operators and of course a visual equivalent of parenthesis for grouping need to exist as well ( x and (y or z) )".
- **The rule editor is option C, an outline with connector lines** (mockups of three options, 2026-11-10):
  - each block is a row;
  - a group's rows hang off one line labelled AND (blue) or OR (orange);
  - a nested group indents with its own line (that's the parentheses);
  - drag handles move blocks within and between groups;
  - each block can be removed (✕).
- **Today's categories become editable defaults:** "the categories that are currently hardcoded should be migrated to use this system so that they can be viewed and modified in game, they just become a sane list of defaults".
- **The editor is a new tab in `/sui` → Bags:** "I think it should be another tab in the Bags section of the options gui".
- **The Categories tab mockup was approved:** "yep that looks right".
  - Left: the category list in order, with drag handles, live counts, and an "edited" or "yours" marker; turned-off categories struck through. Under it, "+ New category" and "Reset all".
  - Right: the selected category's name, "Show in" checkboxes per window, its rule in the outline, a strip of the items in the bags it catches now, and "Reset <name> to default" and "Delete".
- **Categories are a flat list:** "a flat list is fine for now - if we want to make categories groupings later we can revisit".
- **Order:** "order is fine, just make sure we can drag them to re-order". The list order is how categories claim items, and it can be reordered by dragging.
- **The within-category sort is a later project:** "we should tackle that later and do some work on the sort string to build it from blocks as well" (`docs/followups.md`, the bag item sort entry).
- **Agreed in the playback** ("everything else is great"):
  - plain, case-insensitive text matching with a "whole word" option;
  - an item whose tooltip hasn't loaded waits rather than being misfiled;
  - categories are stored in the profile;
  - the old defaults (class tier-token groups, Anima, Conduits) stay, and can be turned off;
  - the first set of blocks below;
  - Grays/Auto Vendor stays the category that sells;
  - Reset per category and for the whole list.

## Today

Research pass, 2026-11-10.

**How an item gets a category.** `INV:GetItemCategory(info)` (`category.lua:23-44`) is run once per item per update by `INV:ReadBags`. It checks, in order:
1. equipment sets: `Set: <first set name>`, from `C_Container.GetContainerItemEquipmentSetInfo`, on Armor and Weapons;
2. a reagent-bank branch that is dead (neither client has a reagent bank);
3. the 33 ordered filters in `INV.filters.categories` (first match wins);
4. Miscellaneous, which the last filter always catches.

Empty Slots and Currencies are pseudo-categories with no rule.

**What a filter sees.** Each filter is a Lua function of the item info built by `INV:GetInventoryItemInfo` (`category.lua:75-155`):
- `name`, `quality`, `reqLevel`, `class` and `subclass` (localized names; the numeric class and subclass IDs, `bindType`, `itemSetID` and `isCraftingReagent` are read and dropped);
- `equipSlot`, `vendorPrice`, `expacID`;
- `ilvl`;
- `isSoulbound`, `isBoE`, `isWarbound`;
- `tooltipText`: every tooltip line joined, cached per link;
- `loading` when item info hasn't arrived.

**What the 33 filters test** (`filters.lua`):
- About 25 are pure data: class, subclass, name text, tooltip text, item ID lists.
- Two need code:
  - **Grays/Auto Vendor** (#1): grey quality; or old gear, via `isLegacyGear`, which reads `UnitLevel` and `GetAverageItemLevel`; or soulbound with the red "Classes:" text; or the user's Auto Vendor item list. It excludes the Protected list, Cosmetic, fishing and account-bound items, and anything with no vendor price.
  - **Equipment sets.**
- Order decides the overlaps: Gems/Enchants takes Gem before Trade Goods can; the class tier-token groups take class-restricted gear before Armor and Weapons.
- Text matching uses `string.matchnocase`, whose pattern is a raw Lua pattern. A hyphen in "Battle-Stone" works by accident.

**What's configurable today:**
- per-window hide flags, `filters.categories[window][name]`, set by the Edit view's checkboxes, which have been unreachable since the Edit button was hidden;
- the Auto Vendor and Protected item lists (`autoVendorFilter`, `protectFilter`), from the slot menu, which opens on Ctrl+right-click (`slot.lua` `OpenSlotOptions`).

**Order.** The bag views (Rows, One bag, Multi bag) order categories by `INV:CategoryRank` and `INV:CategoryBefore` (`views.lua`): sets first, then filter order, then Miscellaneous, then Empty Slots. Compact packs categories into columns by height and ignores order.

**Identity.** A category's name is its identity everywhere: hide flags, frame names, `CategoryRank`, auto vendor and held layouts.

## The design

### A category

A category has:
- a name;
- whether it's on;
- which windows show it (Bags, Bank, Warband bank, Combined bank);
- a rule: one group of blocks.

Categories form one ordered, flat list. An item pinned to a category goes there; any other item goes to the first category whose rule it matches.

**Pinned items** (the user's choice, 2026-11-10: "Add to category…" moves the item there). The slot menu's "Add to category…" pins an item to a category whatever the rules say: pins are checked before the list order. An item is pinned to one category at a time, so pinning it again moves it. A category's editor lists its pinned items, each removable. A pin to a category that's turned off or deleted is dropped from the bags' point of view (the item falls back to the rules) and removed when the category is deleted (my call). Miscellaneous is always last: it catches anything left, and can't be deleted, turned off or given a rule (my call: something must catch every item). Grays/Auto Vendor can't be deleted either; it can be turned off (auto vendor then sells nothing), renamed and moved (my call: it's the one category that sells). Empty Slots and Currencies stay pseudo-categories, outside the list, placed as today (my call).

**Identity.** Each category has a stable identity separate from its name, so renaming one keeps its hide state, its place in held layouts and anything else keyed to it (my call; today the name is the key).

### A rule

A rule is a group. A group has an operator, AND or OR, and holds blocks and groups, nested to any depth. Any block or group can be negated (NOT). An empty group matches nothing (my call: a new category catches nothing until it has a rule).

### The blocks

All are my call within the user's "take a look at what item info is available". Text blocks match plain text, case-insensitively, with no Lua patterns, and each has a "whole word" option.

| Block | Input |
|-------|-------|
| Tooltip contains | text, whole word option |
| Name contains | text, whole word option |
| Name is | text, exact, case-insensitive |
| Class is | one class, a dropdown |
| Subclass is | subclasses, a dropdown with checkboxes, listing the subclasses of the class picked in the same block |
| Quality is | qualities, a dropdown with checkboxes |
| Item level | at least, at most, or between, as numbers |
| Required level | at least, at most, or between, as numbers |
| Equip slot is | slots, a dropdown with checkboxes |
| Binding is | soulbound, bind on equip, warbound, not bound (dropdown with checkboxes) |
| Expansion is | expansions, a dropdown with checkboxes |
| Crafting reagent | yes or no |
| Has vendor price | yes or no |
| Item is one of | a list of item IDs inside the rule (the defaults' built-in lists, such as Archaeology's; editable by ID or by dragging an item onto it) |
| Old gear for my level | code-backed: today's `isLegacyGear`, with its thresholds as the block's settings (levels below the player, expansion, share of average item level) |
| Protected | code-backed: the Protected list from the slot menu |

- **Class and subclass** are stored as the numeric IDs, so rules survive a client language change. The editor shows the client's localized names, from `C_Item.GetItemClassInfo` and `GetItemSubClassInfo` (my call).
- **Equipment sets** stay a built-in entry in the list: "Equipment sets", which makes a `Set: <name>` category per set, as today. It can be moved or turned off, and it has no rule to edit (my call: sets are a live API per slot, not a property of the item).
- **Tooltip text that hasn't loaded:** an item whose tooltip text hasn't loaded yet counts as loading, as an item with no item info does today, so it isn't filed by its other blocks first (my call; today it's filed as if it had no tooltip, and can move later).

### The defaults

Today's 33 filters become the default list, in today's order, each rule written in blocks so it catches exactly what today's filter catches. There is one deliberate change: Delves' "Tooltip contains Curio" uses whole word, so "Curious" stops matching (my call: the user's mystery).

Within this, the builder picks the closest blocks for each filter. Any filter that can't be written exactly in blocks is listed in the plan with what changes.

Dead branches go: the reagent bank branch, the unreachable `Miscellaneous` fallback, the unused ItemRack hooks and tables (my call).

### Existing profiles

A profile saved before this sees exactly today's categories, in today's order:
- today's hide flags become each category's "Show in" checkboxes;
- the Auto Vendor list becomes pins to Grays/Auto Vendor, and the Protected list carries over unchanged (an item on both stays Protected and loses its pin, which is what Protected does today).

If a later SaftUI version adds a default category, profiles get it at its default place, unless the user deleted it (my call).

"Reset <name> to default" restores one default category: its rule, name, on/off and "Show in". "Reset all" restores the whole list, removing the user's own categories after a confirm (my call: the confirm). Reset never touches the user's pins or the Protected list: those are the user's data, kept beside the categories, not inside a category's rule. Built-in item ID lists that are part of a default's rule (Archaeology's, Professions/Recipes') are restored with it. Adding an item to a category doesn't mark a default as edited (my call).

A deleted default can be restored on its own: "+ New category" also offers "Restore a default…", listing the defaults the user has deleted (my call).

### Auto vendor

Grays/Auto Vendor stays the only category that sells. Two guarantees hold whatever its rule says (my call: selling can't be undone): a Protected item is never sold, and an item with no vendor price is never sold. `INV:IsAutoVendorItem` checks both before the category. Its rule is visible and editable like any other:

> grey OR old gear OR (soulbound AND the red Classes: text), AND NOT the exclusions (Cosmetic, fishing, account-bound)

Items marked Auto Vendor are pinned to it rather than matched by its rule.

`INV:IsAutoVendorItem` and the junk coin follow whatever its rule says.

### The Categories tab

The Categories tab is in `/sui` → Bags, after the window tabs. It is laid out as in the approved mockup.

**The list (left):**
- every category in order, with a drag handle to reorder by dragging;
- each row shows its live item count in the bag window, and a marker for an edited default or one of the user's own;
- a turned-off category is struck through;
- under the list: "+ New category" and "Reset all".

**The editor (right):**
- Name.
- Show in: Bags, Bank, Warband bank, Combined bank (Warband and Combined only on retail).
- On/off.
- The rule, as an outline (option C):
  - AND in blue and OR in orange, on the group's line;
  - drag handles to move blocks within and between groups;
  - "+ Block" (a picker of the block types) and "+ Group";
  - a NOT toggle and ✕ on each row;
  - the AND/OR label is clickable to flip it.
- "Caught now": the items in the bags this category catches now. Hovering one highlights the block that caught it.
- "Reset <name> to default" (defaults only) and "Delete" (with a confirm; defaults can be restored by Reset).

**Saving.** A change applies to the bags at once, by a bag update. It is saved in the profile.

### Why is this here?

**The tooltip.** An item's tooltip in SaftUI's bag windows gets a line naming its category and its place in the list ("Category: Delves (4th)"), and a line naming the block that caught it ("Caught by: Tooltip contains 'Curio'"). Its group path is included when it's nested (my call: the wording).

**The slot menu** (Ctrl+right-click) gains:
- **"Edit this category":** opens `/sui` → Bags → Categories with it selected.
- **"Add to category…":** pins the item to a chosen category (see Pinned items), or unpins it.

Ctrl+right-click is the existing menu; a click with Alt would fight Blizzard's item clicks (my call).

The menu's existing marks change meaning to fit pins:
- **Auto Vendor** pins the item to Grays/Auto Vendor.
- **Protected** marks it never sold.

The two marks exclude each other: setting one clears the other (my call; today they're independent checkboxes, and Protected silently wins).

## Constraints

- **Combat.** Nothing in the editor touches secure slots. A rule change in combat applies through the existing bag update, which already handles combat (the views' `FitSlots` and the combat queue). `/sui` closes in combat, as it does today.
- **Taint:** no fields written on Blizzard frames (`.agents/taint.md`). The tooltip lines are added through a post-hook on SaftUI's own slots' tooltips.
- **Both clients:**
  - Forever (16001) has no warband bank and no reagent bag, and has profession bags.
  - Expansions, classes and subclasses come from the client, so each client's lists are its own.
  - Equipment sets on Forever are unverified (the research flagged it).
- **Performance:** rules run per item on every bag update, as today's filters do. Repeated work per item, such as stripping the tooltip text, is done once per item per update, not once per block (my call: today `matchnocase` re-strips per call, and blocks multiply that).
- **Options window:** the Categories tab is built in SaftUI's own options window (`.agents/edit-mode.md`: model, body, widgets). The list and the outline editor are new widget types there. Every option has a desc, and the existing finished-page rules apply where they fit.
- **Theme:** new frames with borders are drawn the Themes way, with a kind.

## Non-goals

- Category groups (Ellesmere-style nesting): later, if wanted.
- The within-category sort, and sort keys as blocks: `docs/followups.md`, the bag item sort entry.
- Export and import of categories.
- Letting any category sell at vendors.
- A category sidebar in the bag window.

## Anti-goals

- Any change to how anyone's bags look until they change a category. Defaults catch exactly what today's filters catch; the Curio whole-word fix is the one deliberate change.
- A rule editor that needs Lua or Lua patterns to use.
- Losing a user's hide flags, Auto Vendor or Protected lists in the migration.
- An item silently filed by a half-loaded tooltip.

## Tests

- **Every default** catches exactly what today's filter catches: an item fixture per filter, and today's overlaps in order (Gem; tier tokens before Armor).
- **The Curio fix:** "Curious" isn't Delves; "Combat Curio" is.
- **Rule evaluation:**
  - AND, OR, NOT;
  - nested groups;
  - an empty group;
  - each block type and its inputs;
  - text blocks with Lua-magic characters ("Battle-Stone", "100%").
- **Order:** first match wins; dragging reorders; Miscellaneous stays last.
- **Migration:**
  - an old profile's hide flags and lists carry over;
  - an old profile sees today's categories;
  - a new default appears;
  - a deleted default stays deleted;
  - renaming keeps identity.
- **Reset:** one category; and all, with the confirm.
- **Loading:** a missing tooltip makes the item loading, not misfiled.
- **The tab:**
  - the list, counts, markers, reorder;
  - the editor's add, remove, NOT, flip, nest and drag;
  - "Caught now" and its highlight;
  - descs.
- **The tooltip lines and the slot menu entries.**
- **Pins:**
  - a pinned item goes to its category whatever the rules and order say;
  - pinning again moves it;
  - unpinning returns it to the rules;
  - Auto Vendor and Protected exclude each other;
  - a protected item is never sold, pinned or not;
  - a pin to a deleted category is removed.
- **Auto vendor and the junk coin** follow an edited Grays/Auto Vendor rule.
- **The views:** Rows, One bag and Multi bag order by the list; Compact still packs by height; hidden categories hide as today.

## Left to the builder

- The data model and storage shape, and how defaults and the user's edits are stored (whole list, or defaults plus overrides), within "Existing profiles" above.
- How each of today's 33 filters is written in blocks.
- The outline editor's widget code within SaftUI's options window, its drag behaviour, and the block picker.
- How much of the work is one plan or two. The research suggests two: data model, defaults and migration first; then the tab, tooltip and menu.
