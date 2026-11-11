# Bag Categories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The bag categories stop being hard-coded Lua. They become an ordered list in the profile. Each category has a rule built from blocks. Today's 33 filters are the defaults, and they catch exactly what they catch today. The list is edited in a new `/sui` → Bags → Categories tab. An item's tooltip says which category it is in and why, and the slot menu can pin an item to a category.

**Architecture:**
- **Data, Tasks 1-5:**
  - item facts for the blocks;
  - a pure rule evaluator (`rules.lua`);
  - the defaults, written with English class and subclass names that are resolved against this client (`categorydefaults.lua`);
  - the list the bags use, which is the defaults plus the profile's edits (`categories.lua`);
  - `INV:GetItemCategory`, which checks pins first and then the list in order.
- **Ids:** a default's id is today's name. Frames, `CategoryRank`, held layouts and hide flags keep their keys. A rename changes only the name.
- **UI, Tasks 6-9:**
  - Core gets custom widget types, "bare" rows and a check list.
  - SaftUI-Bags defines the Categories tab as one wide composite widget: the list on the left, and an options body for the selected category on the right.
  - The outline rule editor and an item strip are widget types of their own.
  - The tooltip lines come from a `TooltipDataProcessor` post-call.
  - The slot menu is Blizzard's `MenuUtil`.

**Tech Stack:** Lua 5.1 (WoW), an AceDB profile, and SaftUI's options window (model, body, widgets), plus Blizzard's `MenuUtil` and `TooltipDataProcessor`. Tests run on lupa's Lua 5.1 through `tests/run`.

**Spec:** `docs/superpowers/specs/2026-11-10-saftui-bag-categories-design.md`, approved 2026-11-10. Read it first. Every "my call" in it is binding. It describes the approved mockups:
- the rule editor (option C): `/mnt/c/Github/wow-addons/SaftUI-Modular/.superpowers/brainstorm/21258-1794371813/content/filter-blocks.html`;
- the tab and the tooltip: `.../content/categories-tab.html`, in the same folder.

**Starting point:** branch `bagcategories` at `8dc348c` (`modular`), in `.claude/worktrees/bagcategories`.

**Code map (line numbers at `8dc348c`):**
- `SaftUI-Bags/filters.lua`:
  - the 33 filters;
  - the Archaeology IDs, 17-62;
  - `isLegacyGear`, 98-128;
  - `INV:IsAutoVendorItem`, 150-158.
- `SaftUI-Bags/category.lua`:
  - `GetItemCategory`, 23-44;
  - `GetInventoryItemInfo`, 75-155;
  - `ReadBags`, 288-329;
  - `CreateCategory`, 415-458 (the hidden Edit view's checkbox is 443-453);
  - `UpdateCategory`, 465-516;
  - `InitializeAllCategories`, 536-548.
- `SaftUI-Bags/tooltipscanner.lua`.
- `SaftUI-Bags/views.lua`: `CategoryRank` and `CategoryBefore`, 45-65; Rows in `GetViewSections`, 231-265.
- `SaftUI-Bags/container.lua`: the Edit button, 54-73; `FlushIfFiltered`, 407-412; the held layout, 536-586.
- `SaftUI-Bags/slot.lua`: `UpdateTooltip`, 194-220; the slot menu, 222-295; `CreateSlot`, 297-404.
- `SaftUI-Bags/inventory.lua`:
  - `EnsureConfigTables`, 95-103;
  - `UpdateConfig`, 127-153;
  - `UpdateHandler`, 283-300;
  - the ItemRack hooks, 309-314 and 376-378;
  - `OnEnable`, 339-402.
- `SaftUI-Bags/options.lua`: `GetConfigTable`.
- Core:
  - `Config/optionswidgets.lua`: `define`, `W.Create`, `W.OpenList`, `W.Box`;
  - `Config/optionsbody.lua`: `Body:RowCell`, `PlaceRow`;
  - `Config/optionsmodel.lua`: `OM.BuildView`;
  - `Config/optionswindow.lua`: `Busy` and `Changed`, the drag protocol.
- Tests: `tests/bags/bag_world.lua`, `tests/bags/container_helpers.lua`, `tests/core/options_walk.lua`.

## Global Constraints

**Clients and exactness**
- **Clients:** WoW Forever (16001, the user's) and retail (120000). `st.retail` is true on both. Forever has no warband bank (`INV:HasWarbandBank()`).
- **Exactness is measured on English clients.** Today's filters compare English class and subclass names and English tooltip text, so on other languages their class tests already match nothing.
- **Class and subclass lists come from the client** (`INV.ItemClasses`, Task 1), never from a hard-coded list.

**The rule tree** (stored in the profile; plain tables)
```lua
group = { op = 'and' | 'or', negate = true | nil, items = { node, ... } }
block = { block = '<type id>', negate = true | nil, ...params }
```
- A node with `op` is a group, and a node with `block` is a block. A rule's root is always a group.
- An empty group matches nothing. `negate` applies after that, so NOT of an empty group matches everything. The editor never offers NOT on the root.
- A **path** is the `items` indices from the root: `{}` is the root, and `{3, 2}` is `root.items[3].items[2]`.
- A block of a type this version doesn't know, or with missing or wrongly typed params, matches nothing and never errors. A rule that isn't a table matches nothing.

**Blocks** (type id, label, params, a new block's params, matches when)

| id | Label | Params | New | Matches when |
|----|-------|--------|-----|--------------|
| `tooltip` | Tooltip contains | `text` string, `word` bool | `{ text = '' }` | the text matches the tooltip (see Text matching) |
| `name` | Name contains | `text`, `word` | `{ text = '' }` | the same, on the item's name |
| `nameis` | Name is | `text` | `{ text = '' }` | `info.nameLower == strlower(text)` |
| `class` | Class is | `class` number | `{}` | `info.classID == class` |
| `subclass` | Subclass is | `class` number, `subclasses` array of numbers | `{ subclasses = {} }` | `classID == class` and `subclassID` is in `subclasses` |
| `quality` | Quality is | `qualities` array of 0-7 | `{ qualities = {} }` | `info.quality` is in it |
| `ilvl` | Item level | `min`, `max` (numbers, either or both) | `{ min = 0 }` | `info.ilvl or 0` is at least `min` and at most `max`, where each is set |
| `reqlevel` | Required level | `min`, `max` | `{ min = 0 }` | the same, on `info.reqLevel or 0` |
| `slot` | Equip slot is | `slots` array of `INVTYPE_*` tokens | `{ slots = {} }` | `info.equipLoc` is in it |
| `binding` | Binding is | `states` array of `'soulbound'`, `'boe'`, `'warbound'`, `'none'` | `{ states = {} }` | any listed state holds: `isSoulbound`, `isBoE`, `isWarbound`, or none of the three |
| `expansion` | Expansion is | `expansions` array of numbers | `{ expansions = {} }` | `info.expacID` is in it |
| `reagent` | Crafting reagent | `value` bool | `{ value = true }` | `(info.isCraftingReagent and true or false) == value` |
| `vendorprice` | Has vendor price | `value` bool | `{ value = true }` | `((info.vendorPrice or 0) > 0) == value` |
| `items` | Item is one of | `ids` array of item IDs | `{ ids = {} }` | `info.itemID` is in it |
| `oldgear` | Old gear for my level | `levels` (10), `expansion` (9), `share` (0.9) | those values | today's `isLegacyGear`, below |
| `protected` | Protected | none | `{}` | `INV:IsProtected(info.itemID)` |

Old gear, as `isLegacyGear` at `filters.lua:98-128`, with the thresholds taken from the block:
- the item is Armor or Weapon (`INV.ItemClasses.IsGear(info)`) and not `isWarbound`;
- `UnitLevel('player') - reqLevel >= levels`;
- `expacID <= expansion`;
- `ilvl <= GetAverageItemLevel() * share`;
- its quality is 2 to 4;
- its stripped tooltip has none of `you may trade this item with players`, `account bound` or `cosmetic`.

A nil `reqLevel`, `expacID` or `ilvl` doesn't match. Today's tabard and shirt test is left out. It compared the localized slot name with an `INVTYPE_` token, so it never matched, and leaving it out changes nothing.

**Text matching**
- `R.Strip(s) = strlower(string.unmagic(s))`. `string.unmagic` is Core's: it turns `%` into a space and removes `^ $ ( ) . [ ] * + - ?`.
- **Contains** (`word` false): a plain find of `R.Strip(text)` in the item's stripped text (`nameStripped`, `tooltipStripped`). That is the subject today's `string.matchnocase` builds, but the text is plain, never a Lua pattern.
- **Whole word** (`word` true): a plain find of `strlower(text)` in the item's lowercased raw text (`nameLower`, `tooltipLower`), at a place where the character before it and the character after it are not letters (`%a`), or are the ends. Every occurrence is tried. Today's Keys test `%f[%a]key%f[%A]` is exactly this.
- A text that is empty, or strips to empty, matches nothing.
- Needles are stripped once, when the rule is compiled. Subjects are stripped once per item per update, in `GetInventoryItemInfo` (Task 1). The evaluator strips nothing per block.

**Ids, keys and names**
- **Ids:**
  - A default's id is today's name, exactly: `'Grays/Auto Vendor'`, `'Armor (Warbound)'`, `'Miscellaneous'`, and so on.
  - The Equipment sets entry's id is `'Equipment sets'`.
  - A category of the user's is `'custom:<n>'`, from `categories.nextId`.
- **Keys:** a key is a list id, or `'Set: <set name>'` for an equipment set (as today). `'Empty Slots'` and `'Currencies'` stay pseudo keys. Keys are what `INV:GetItemCategory` returns and what category frames, `CategoryRank`, held layouts and hide flags use.
- **Display names:** `INV:CategoryName(key)` is the entry's name for a list id, and the key itself otherwise. Headers and titles show it.
- **Constants:** `INV.SELL_CATEGORY = 'Grays/Auto Vendor'`, `INV.SETS_ENTRY = 'Equipment sets'`, `INV.MISC_CATEGORY = 'Miscellaneous'`.

**Profile keys** (under `st.config.profile.inventory`)

They have no AceDB defaults. `INV:EnsureConfigTables` makes them. Read them through `INV.config` at call time, never from a captured table.
```lua
categories = {
	version = 1,                    -- set once by INV:MigrateCategories (Task 5)
	order   = nil | { id, ... },    -- the whole list's order, written by the first move, create or restore
	edits   = { [defaultId] = { name = s?, enabled = b?, hide = { [windowId] = true }?, rule = group? } },
	custom  = { [customId] = { name = s, enabled = b, hide = { ... }, rule = group } },
	deleted = { [defaultId] = true },
	nextId  = 1,
}
categoryPins  = { [itemID] = id }   -- one category per item
protectFilter = { [itemID] = true } -- unchanged
```
- `edits` holds only fields that differ from the shipped default. A setter given the default's value removes the field, and an empty edit is removed. A default with an edit is "edited".
- `hide` names the windows that don't show the category: `bag`, `bank`, `warband`, `combinedbank`. Show in is its inverse.
- The migration (Task 5) removes `autoVendorFilter`, and the list categories' names from `filters.categories[windowId]`. `filters.categories[windowId]` keeps the `'Empty Slots'`, `'Currencies'` and `'Set: …'` keys, and `filters.currencies` stays as it is.

**The list** (`INV:GetCategoryList()`)
- Start from `order`, or the default order when there is none. Keep each id once, if it exists: a default that isn't deleted, or a category in `custom`.
- A default missing from `order` and not deleted (new in this version, or just restored) goes after the nearest default before it in the default order that is in the list. When there is none, it goes first.
- Miscellaneous is always last and always on. Grays/Auto Vendor and Equipment sets can't be deleted.
- An entry is `{ id, name, enabled, hide, rule, kind = 'sets' | 'rule' | 'misc', default, sells, edited, place }`, with `hide` never nil.

**Evaluation** (`INV:GetItemCategory(info) -> key, why`)
1. **A pin:** a pin to a list category that exists, is on and isn't the sets entry gives that id, with `why = { kind = 'pin' }`.
2. **The list, in order, skipping entries that are off:**
   - The sets entry gives `'Set: <first set>'` for Armor or Weapon (`IsGear`) that `C_Container.GetContainerItemEquipmentSetInfo` puts in a set (the call is feature-checked). `why = { kind = 'set' }`.
   - A rule entry whose compiled rule matches gives its id, with `why = { kind = 'rule', path = <deciding node's path> }`.
   - Miscellaneous gives `'Miscellaneous'`, with `why = { kind = 'misc' }`. There is no fallback after the loop.
- **Compiling:** each rule is compiled once per list change. `INV:CategoriesChanged()` drops the compiled rules, the list and the ranks.
- **The deciding node:**
  - in an OR, the first child that matched (its own deciding node);
  - in an AND, the first child that isn't negated (its own deciding node);
  - a block is its own deciding node;
  - a negated group, or an AND whose children are all negated, decides itself.

**Selling**
- Only Grays/Auto Vendor (`sells`) sells.
- `INV:IsAutoVendorItem(info, key)` never sells an empty slot, an item with no vendor price or a Protected item. Past those, it sells when `key == INV.SELL_CATEGORY` and that entry is on.
- **Marks:** marking an item Auto Vendor pins it to Grays/Auto Vendor. Protected and that pin exclude each other: setting one clears the other.

**Words the user sees**

These are exact.
- **Tab:** `Categories`.
- **List markers:** `edited` and `yours`.
- **Buttons:** `+ New category`, `Reset all`, `New category`, `Restore a default...`, `Reset <name> to default`, `Delete`, `+ Block`, `+ Group`.
- **Editor rows:** `Name`, `On`, `Show in` (`Bags`, `Bank`, `Warband bank`, `Combined bank`), `Catches an item when`, `Pinned items`, `Caught now`.
- **Slot menu:** `Edit this category`, `Add to category…`, `None (follow the rules)`, `Auto Vendor`, `Protected`.
- **Glyphs:** text in SaftUI's fonts never uses `…`, `✕` or `⋮⋮`. Write `...`, and draw the remove X (`st.textures.close`) and the drag handle (dots) as textures. Blizzard's menu may use `…`.

**Combat and taint**
- Nothing in the editor touches a secure frame, and `/sui` closes in combat.
- Category frames and their slot buttons are made out of combat (`INV:EnsureCategoryFrames`, with `st:QueueAfterCombat('InventoryCategoryFrames', …)`).
- **Tooltip lines:** added from `TooltipDataProcessor.AddTooltipPostCall` only to `GameTooltip` while one of SaftUI's own item slots owns it.
- Nothing is written onto a Blizzard frame or table (`.agents/taint.md` rule 1).
- The slot menu is `MenuUtil.CreateContextMenu`.

**Theme and options**
- **Theme:**
  - Controls inside the options window use its box look, `st.OptionsWidgets.Box`, as every options widget does.
  - Item icons are drawn as the description's image is: `st:SetBackdrop(icon, 'theme', 'theme', 'action')`.
  - Any other new bordered frame, such as the drag ghost, is drawn with `st:SetBackdrop(frame, 'theme', 'solid', 'small')`.
- **Options:** every option has a `desc`, SaftUI's `size` where it takes one, and no Ace `width`.

**Files, tests and commits**
- **Files:**
  - Keep each file's line endings, and never `sed -i` a CRLF file.
  - The final `SaftUI-Bags/SaftUI-Bags.toc` order (one TOC for both clients): `config, inventory, itemclasses, rules, currencies, categorydefaults, categories, tooltipscanner, category, views, container, containers\*, slot, utilities, autovendor, movers, options, ruleeditor, categoriestab`.
  - The test worlds that load `category.lua` to lay out or categorize items load each new data file as its task adds it (`itemclasses.lua`, `rules.lua`, `categorydefaults.lua`, `categories.lua`). Those worlds are `bag_world.lua`, `container_helpers.lua`'s `H.fresh` and `tests/bags/theme_test.lua`.
- **Tests:** `tests/run` passes at the end of every task.
- **Commits:** the subject is `bags: …`, `core: …` or `docs: …`. Stage by explicit path. End every commit message with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01PYgFsM3V6p9vWPEFz7WA9o
  ```

## Review Focus

1. **A cold login whose tooltips don't arrive.** An item waits as loading for at most 10 reads of its link. Then it is filed with no tooltip text, and it moves once its text arrives. No window is stuck behind the loading bar (Task 1 test).
2. **A profile switch, copy or reset.** The bags read the new profile's categories, edits and pins at once, with the caches dropped. An old profile switched to is migrated (Task 5 test).
3. **Rule data this version can't read** (an unknown block type, a block missing its params, a rule that isn't a table) errors nowhere: not in the evaluator, not in "Caught by", and not in the editor, which shows the block as Unknown block and lets it be removed (Task 2 and Task 7 tests).
4. **Pinning from the slot menu in combat.** Pinning to a category made since login, or to a renamed one, makes no frame or slot in combat. The item shows there on the next update (Task 4 test).
5. **Grays/Auto Vendor renamed, moved down the list or turned off.** It is still the only category that sells, and the junk coin follows it. Turned off, it sells nothing (Task 4 test).

## Order

- **Data first:** Tasks 1 → 2 → 3 → 4 → 5, each reviewed before the next. No UI task starts before Task 5 is approved.
- **Task 6** (Core widgets) needs none of 1-5. Run it after 5.
- **Then:** Task 7 after 2 and 6. Task 8 after 4, 5 and 7. Task 9 after 8. Task 10 last.

---

### Task 1: Item facts for the blocks, and items that wait for their tooltip

**Files:**
- Create: `SaftUI-Bags/itemclasses.lua` (in the TOC after `inventory.lua`).
- Modify:
  - `SaftUI-Bags/tooltipscanner.lua`;
  - `SaftUI-Bags/category.lua`: `GetInventoryItemInfo`, and `ReadBags`'s loading.
- Test:
  - `tests/bags/item_facts_test.lua` (new);
  - `tests/bags/bag_world.lua`;
  - `tests/bags/fixtures/item_classes.lua` (new);
  - `tests/wow/game.lua`: `C_Timer.After`, and `stub.run_timers()`, which runs the callbacks due by `stub.time`.

**Interfaces:**
- Produces:
  - **`INV.ItemClasses` (`IC`):**
    - `IC.ClassIDs(name) -> { [id] = true }`
    - `IC.SubclassIDs(name) -> { [classID] = { subclassID, ... } }`, ascending
    - `IC.ClassName(id) -> string | nil`
    - `IC.SubclassName(classID, subclassID) -> string | nil`
    - `IC.Classes() -> { { id, name }, ... }`, by id
    - `IC.Subclasses(classID) -> { { id, name }, ... }`
    - `IC.IsGear(info) -> bool`: the classID is in `ClassIDs('Armor')` or `ClassIDs('Weapon')`
    - `IC.Reset()`, for tests

    It reads `(C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo`, and the `GetItemSubClassInfo` equivalent, for IDs 0 to 39 of each, once, on first use. Each call is in `pcall`, and nil or `''` names are skipped.
  - **`INV:ScanBagItem(bagID, slotID) -> text, raw, ready`:**
    - `text` is today's joined lines through `string.unmagic`, and `raw` the same lines joined as the client gave them. Both are cached per link.
    - `ready` is false while `C_TooltipInfo` exists, the slot has a link, and `GetBagItem` gives no data or no `lines`. Nothing is cached then.
    - After `INV.TOOLTIP_TRIES = 10` reads of one link that weren't ready, `ready` is true with `''`, still uncached, so a later read can fill it in.
    - No `C_TooltipInfo`, or no link: `'', '', true`.
  - **`GetInventoryItemInfo` adds to the info:**
    - `classID`, `subclassID`, `bindType`, `isCraftingReagent`;
    - `equipLoc`, the raw `INVTYPE_` token (`equipSlot` stays the localized name);
    - `nameLower = strlower(name)`, `nameStripped = strlower(string.unmagic(name))`;
    - `tooltipLower = strlower(raw)`, `tooltipStripped = strlower(text)` (`tooltipText` is unchanged).

    It returns `{ loading = true, tooltip = true }` while the tooltip isn't ready.
  - **Synthesized classes:** a keystone gets `classID = Enum.ItemClass.Key or 13`, and a caged pet `Enum.ItemClass.Battlepet or 17`.
  - **`INV:QueueTooltipRetry()`:** `ReadBags` calls it when it meets an item waiting for its tooltip. There is one pending `C_Timer.After(INV.TOOLTIP_RETRY = 0.5, …)` at a time, which runs `INV:QueueUpdate(true)`.

**The test world (`bag_world.lua`):**
- **Links:** `C_Container.GetContainerItemLink` returns the item's link: `item.link`, else `|Hitem:<id>|h[<name>]|h`. Tooltips are cached by link, so items with different tooltips need different IDs.
- **Tooltips:** `C_TooltipInfo.GetBagItem` builds `{ lines = { { leftText, rightText } } }` from `item.tooltip`, a list of strings or `{ left, right }` pairs. It returns nil while `item.tooltipLoading` is set.
- **`C_Item.GetItemInfo`** returns all 17 values from the item: `quality`, `reqLevel`, `class`, `subclass`, `equipLoc`, `vendorPrice` (10 by default), `classID`, `subclassID`, `bindType`, `expacID`, `isCraftingReagent`.
  - Given IDs, the class and subclass names come from the world's client in `fixtures/item_classes.lua`.
  - Given names, the IDs are looked up there, and in the other client's table when this one lacks the name. So today's `W.item(id, name, 'Trade Goods')` still works in a retail world.
- **Item classes:** `C_Item.GetItemClassInfo` and `GetItemSubClassInfo` read the fixture for the world's client.
- **Binding:** `C_Item.IsBound` and `IsBoundToAccountUntilEquip` read `item.isBound` and `item.accountUntilEquip`.

**`fixtures/item_classes.lua`:**
- It returns `{ forever = { classes = { [id] = name }, subclasses = { [classID] = { [subclassID] = name } } }, retail = { … } }`.
- Make it from wago.tools' ItemClass and ItemSubClass tables, for builds `1.60.1.70888` (Forever) and `12.1.5.70783` (retail):
  ```
  curl -s "https://wago.tools/db2/ItemClass/csv?build=<build>"
  curl -s "https://wago.tools/db2/ItemSubClass/csv?build=<build>"
  ```
  Save the downloads to a scratch directory of their own.
- **Names:** a class's name is `ClassName_lang`. A subclass's name is `VerboseName_lang` when that isn't empty, else `DisplayName_lang`, because that is what `GetItemInfo` and `GetItemSubClassInfo` return. Leave out `SubClassID` -1.
- **Rows the tests rely on** (checked in those tables on 2026-11-10):

  | | Forever | Retail |
  |--|--|--|
  | Class 3 | Jewelry(OBSOLETE) | Gem |
  | Class 7 | Trade Goods | Tradeskill |
  | Class 8 | Generic(OBSOLETE) | Item Enhancement |
  | Class 17 | (none) | Battle Pets |
  | Class 20 | (none) | Housing |
  | 0/1, 0/3, 0/5 | Potions, Flasks, Food & Drink | Potions, Flasks & Phials, Food & Drink |
  | 0/6 | Permanent | Item Enhancement (OBSOLETE) |
  | 0/14 | Devices (display name "Device") | RESERVED 14 |
  | 7/3 | Devices (OBSOLETE) | Devices (OBSOLETE) |
  | 15/2 | Pet | Companion Pets |
  | 4/5, 15/5 | Cosmetic, Mount | Cosmetic, Mount |

- [ ] **Step 1: Write the failing tests** in `tests/bags/item_facts_test.lua`:
  - **`'item classes: names resolve to this client's IDs'`:**
    - On Forever: `ClassIDs('Trade Goods')` is `{7}`; `ClassIDs('Tradeskill')`, `ClassIDs('Gem')`, `SubclassIDs('Flasks & Phials')` and `SubclassIDs('Companion Pets')` are empty; `SubclassIDs('Devices')` is `{ [0] = {14} }`.
    - On retail: `ClassIDs('Tradeskill')` is `{7}`, `ClassIDs('Gem')` `{3}` and `ClassIDs('Housing')` `{20}`; `SubclassIDs('Flasks & Phials')` is `{ [0] = {3} }`; `SubclassIDs('Item Enhancement')` and `SubclassIDs('Devices')` are empty.
  - **`'GetInventoryItemInfo gives the IDs and the text the blocks read'`:** for `Flawless Battle-Stone`, `nameStripped` is `'flawless battlestone'` and `nameLower` is `'flawless battle-stone'`. The tooltip's `tooltipText` is as today, and `tooltipLower` and `tooltipStripped` are filled. `classID`, `subclassID`, `equipLoc` and `isCraftingReagent` come through.
  - **`'a keystone and a caged pet get the Key and Battle Pet classes'`:** 13 and 17.
  - **`'an item whose tooltip has not loaded is loading, and is filed once it loads'`:** `ReadBags` gives `numLoading` 1 and no category; after `tooltipLoading = nil` and another read, the item is filed.
  - **`'a tooltip that never loads holds its item for 10 reads, then it is filed without text, and moves when the text arrives'`** (Review Focus 1).
  - **`'with no C_TooltipInfo, items are filed with no tooltip text, never loading'`**.
  - **`'a waiting tooltip queues one retry'`:** two reads queue one timer, and `stub.run_timers()` queues an update.
- [ ] **Step 2: Run them; they fail.** `tests/run tests/bags/item_facts_test.lua` fails on the missing `INV.ItemClasses`.
- [ ] **Step 3: Implement** `itemclasses.lua`, the scanner and the info fields, as in the Interfaces above.
- [ ] **Step 4: Run all tests.** `tests/run` passes, the existing bag tests unchanged.
- [ ] **Step 5: Commit.** `bags: item facts for category blocks: class and subclass IDs, text to match, and items that wait for their tooltip`

### Task 2: The rule evaluator

**Files:**
- Create: `SaftUI-Bags/rules.lua` (in the TOC after `itemclasses.lua`).
- Test: `tests/bags/rules_test.lua` (new), on `bag_world.lua`'s `W.fresh` for the class tables and `UnitLevel` (`stub.level`).

**Interfaces:**
- Consumes: Task 1's info fields, `INV.ItemClasses`, and `INV:IsProtected` (`slot.lua`).
- Produces `INV.Rules` (`R`):
  - **Block types:**
    - `R.BLOCKS`: `{ { id, label, new = function() -> params } }`, in the Blocks table's order, which is the block picker's order;
    - `R.BlockType(id) -> type | nil`.
  - **Evaluating:**
    - `R.Compile(rule) -> fn(info) -> matched, path`. The path is the deciding node's; there is none when nothing matched.
    - `R.Describe(rule, path) -> string`, in the copy below.
  - **Text:**
    - `R.Strip(s)`;
    - `R.HasWord(lowerSubject, lowerWord) -> bool`.
  - **Tree helpers:** `R.Copy(node)`, `R.Equal(a, b)` (deep), `R.NodeAt(rule, path)`.
  - **Labels:**
    - `R.QUALITY_LABELS` (0-7: `Poor`, `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary`, `Artifact`, `Heirloom`);
    - `R.BINDING_STATES`: `{ { 'soulbound', 'Soulbound' }, { 'boe', 'Bind on equip' }, { 'warbound', 'Warbound' }, { 'none', 'Not bound' } }`;
    - `R.SLOTS`: the equippable `INVTYPE_` tokens, labeled `_G[token]` or the token;
    - `R.ExpansionLabel(n)`: `_G['EXPANSION_NAME' .. n]`, or `Expansion <n>`.

**`R.Describe` copy:**
- **Text blocks:**
  - `Tooltip contains "<text>"`, with ` (whole word)` when `word` is set;
  - `Name contains "<text>"`, likewise;
  - `Name is "<text>"`.
- **Lists:**
  - `Class is <name>` (or `Class is class <id>` when the client has no name);
  - `Subclass is <names, joined by ", ">`;
  - `Quality is <labels>`;
  - `Equip slot is <labels>`;
  - `Binding is <labels>`;
  - `Expansion is <labels>`.
- **Levels:** `Item level at least <min>`, `Item level at most <max>`, `Item level <min> to <max>`, and `Required level …` the same way.
- **Yes or no:** `Crafting reagent: yes` or `no`; `Has vendor price: yes` or `no`.
- **Others:**
  - `Item is one of <n> items` (`1 item` for one);
  - `Old gear for my level`;
  - `Protected`;
  - `Unknown block`.
- **NOT:** a negated node starts with `NOT `.
- **Groups:**
  - A block that isn't a child of the root ends with its groups, outermost first, each named by its operator and its place in its parent's items: ` (in OR #1)`, or ` (in OR #1 > AND #2)` deeper.
  - The root, when it decides itself, is `its rule as a whole`.
  - A nested group that decides itself is `<NOT >OR #i`, with its parents' suffix.

- [ ] **Step 1: Write the failing tests** in `tests/bags/rules_test.lua`. One case per item below. Each block type's case covers each of its inputs.
  - `'AND, OR and NOT'`
  - `'nested groups: x AND (y OR z)'`
  - `'an empty group matches nothing, and NOT of one matches everything'`
  - `'tooltip and name: plain, case-insensitive, and whole word'`:
    - `Battle-Stone` catches `Flawless Battle-Stone`;
    - `100%` catches a tooltip `Increases it by 100% for`;
    - `%d+` catches nothing in `Use: Grants 250 reputation`, and nothing errors;
    - `Curio` as a whole word catches `Combat Curio` and `Curio.`, but not `Curious`;
    - `key` as a whole word catches `Rusty Key` and `Key-Ring`, but not `Keystone` or `Monkey`.
  - `'Name is: exact, any case'`
  - `'class and subclass by ID'`
  - `'quality'`
  - `'item level and required level: at least, at most, between'`
  - `'equip slot'`
  - `'binding: each state, and not bound'`
  - `'expansion'`
  - `'crafting reagent and vendor price: yes and no'`
  - `'item is one of'`
  - `'old gear: today's thresholds, and edited ones'`: at level 80 with an average item level of 300, 270 is caught and 271 isn't; an edited `share` moves the line.
  - `'protected: the Protected list'`
  - `'the deciding node: OR's first match, AND's first non-negated child, nested'`: the path each one returns.
  - `'Describe: every block type, NOT, and the group path'`: the exact strings.
  - `'unknown block types and malformed params match nothing and never error'` (Review Focus 3):
    - `{ block = 'future' }`;
    - a `tooltip` block with no text;
    - `class = 'x'`;
    - `{ op = 'xor' }`;
    - `items` that isn't a table;
    - `R.Compile(nil)`.
  - `'evaluating strips no text'`: wrap `string.unmagic` and `strlower`, and evaluate a 20-block rule over an info. There are no calls.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement `rules.lua`.** Compile the tree into closures. Strip the needles and build the sets (`subclasses`, `ids`, …) at compile time.
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `bags: a rule evaluator for category blocks`

### Task 3: The default categories replace filters.lua

**Files:**
- Create, in the TOC in place of `filters.lua`, in this order:
  - `SaftUI-Bags/categorydefaults.lua`;
  - `SaftUI-Bags/categories.lua`: the list and its reads, `GetItemCategory`'s pins and order, and `IsAutoVendorItem`.
- Modify:
  - `SaftUI-Bags/category.lua`:
    - `GetItemCategory` delegates to the list;
    - `ReadBags` also sets `item.categoryWhy`;
    - `InitializeAllCategories` reads the list;
    - delete the reagent-bank branch, the fallback, the commented ItemRack block and `upgradeQualities`.
  - `SaftUI-Bags/views.lua`: `CategoryRank`.
  - `SaftUI-Bags/inventory.lua`: delete the ItemRack hooks in `ADDON_LOADED` and the `OnEnable` call. Drop the `ADDON_LOADED` registration if nothing else uses it.
- Delete: `SaftUI-Bags/filters.lua`, including its unused `expacAbbreviations`, `INV.filters` and `INV.AUTO_VENDOR_CATEGORIES`.
- Test:
  - `tests/bags/category_defaults_test.lua` (new);
  - `tests/bags/fixtures/old_filters.lua` (new);
  - `tests/bags/fixtures/category_items.lua` (new);
  - `tests/bags/views_data_test.lua`: rewrite the `CategoryRank` case;
  - the test worlds' load lists.

**Interfaces:**
- Consumes `INV.Rules` and `INV.ItemClasses`.
- Produces:
  - **The defaults:** `INV.CategoryDefaults.Build() -> entries`, resolved for this client and cached, and `INV.CategoryDefaults.Reset()`.
  - **The list:**
    - `INV:CategoryStore()`: the `categories` table, made with its sub-tables when missing;
    - `INV:GetCategoryList()`, with `list.byId[id]`, per Global Constraints;
    - `INV:GetDefaultCategory(id)`: the shipped, resolved entry;
    - `INV:CategoryName(key)` and `INV:CategoryPlace(key) -> n | nil` (the sets entry's place for `'Set: …'`);
    - `INV:CategoriesChanged()`: drops the caches and `QueueUpdate(true)`s.
  - **Categorizing:** `INV:GetItemCategory(info) -> key, why`, and `INV:IsAutoVendorItem(info, key)`, which keeps `filters.lua`'s comment.
  - **Ranks:** `INV:CategoryRank(key)` is the key's place. A `'Set: …'` key ranks as the sets entry; `'Empty Slots'` as `#list + 1`; any other key (a deleted category still on screen) as Miscellaneous's place minus 0.5. `CategoryBefore` is unchanged.
  - The read side of every profile key, so tests can set `edits`, `order`, `custom`, `deleted` and `categoryPins` directly.

**How the defaults are written.** `categorydefaults.lua` holds the list below as data, in rule-tree form. Class and subclass blocks name their class differently:
- `{ block = 'class', className = '<English name>' }`, or `{ block = 'class', classEnum = '<Enum.ItemClass key>' }`;
- `{ block = 'subclass', subclassNames = { '<English name>', ... } }`.

`Build` resolves them with `INV.ItemClasses`:
- **Class names:** a `className` gives one `class` block per ID. Several IDs are OR'ed in a group. A `classEnum` gives `Enum.ItemClass[key]`, with the synthesized fallbacks from Task 1.
- **Subclass names:** `subclassNames` give one `subclass` block per class the names resolve in, OR'ed when there are several.
- **A name that resolves to nothing** is simplified so the rule still matches exactly what the name test matched:
  - in an OR, it's dropped;
  - negated inside an AND, it's dropped;
  - plain inside an AND, it makes that AND match nothing (an empty group).

  A root left with no blocks matches nothing.
- **Duplicates:** a block that comes out twice in one OR is kept once.
- **Notation in the table:**
  - `TT "x"` is Tooltip contains, and `word` marks whole word.
  - `NAME` is Name contains, and `NAMEIS` is Name is.
  - `CLASS X` names the class by English name, and `CLASS #X` by `Enum.ItemClass` key.
  - `SUB` lists English subclass names.
  - The other blocks are their id in capitals with their params: `QUALITY 0`, `OLDGEAR 10 9 0.9`, `BINDING soulbound`, `ITEMS …`, `PROTECTED`, `VENDORPRICE yes`.
  - `!` is NOT.
  - The outer `AND(…)` or `OR(…)` is the root.

| # | Id | Rule | Resolves to (Forever / retail) | Fixtures (caught, then not) |
|---|----|------|--------------------------------|-----------------------------|
| 1 | Equipment sets | built in, no rule | | plate helm in set "Tank" → `Set: Tank` |
| 2 | Grays/Auto Vendor | `AND( OR( QUALITY 0, OLDGEAR 10 9 0.9, AND( BINDING soulbound, TT "cffff2020Classes:" ) ), !PROTECTED, !SUB Cosmetic, !TT "Fishing", !TT "Blizzard Account Bound", VENDORPRICE yes )`, with `sells` | Cosmetic → Armor 5, both | **Caught:** grey "Broken Fang"; plate quality 3, required level 30, expansion 2, item level 60, at level 80 with an average of 300; a soulbound robe with the line `\|cffff2020Classes: Mage\|r`. **Not caught:** a Protected grey; grey Cosmetic armor; a grey with "Fishing"; a grey with "Blizzard Account Bound"; a grey with no vendor price |
| 3 | Rogue/DK/Mage/Druid | `OR( TT "Rogue, Death Knight, Mage, Druid" )` | | a token with "Classes: Rogue, Death Knight, Mage, Druid" |
| 4 | Warrior/Hunter/Shaman | `OR( TT "Warrior, Hunter, Shaman" )` | | a mail helm with that Classes line (not Armor) |
| 5 | Paladin/Priest/Warlock | `OR( TT "Paladin, Priest, Warlock" )` | | its Classes line |
| 6 | Warrior/Rogue/Monk | `OR( TT "Warrior, Rogue, Monk" )` | | its Classes line |
| 7 | Hunter/Mage/Druid | `OR( TT "Hunter, Mage, Druid" )` | | its Classes line |
| 8 | Paladin/Priest/Shaman | `OR( TT "Paladin, Priest, Shaman" )` | | its Classes line |
| 9 | Death Knight/Warlock/Demon Hunter | `OR( TT "Death Knight, Warlock, Demon Hunter" )` | | its Classes line |
| 10 | Secrets of Azeroth | `OR( TT "Secrets of Azeroth" )` | | its tooltip line |
| 11 | Reputation | `AND( TT "Use: Grants ", TT " reputation" )` (not exact, below) | | "Use: Grants 1,500 reputation with the Dream Wardens." |
| 12 | Delves | `OR( TT "Curio" word, NAMEIS "Delver's Bounty", NAMEIS "Trovehunter's Bounty" )` | | **Caught:** right text "Combat Curio"; "Delver's Bounty". **Not caught (new):** "Curious Coin", tooltip "Curious" |
| 13 | Container | `AND( OR( TT "Right Click to Open", TT "Open the container", TT "Open the sack", TT "Use: collect", TT "Use: Open", TT "Flightstones" ), !CLASS Armor, !CLASS Weapon )` | | **Caught:** "<Right Click to Open>". **Not caught:** armor with "Use: Open" (→ Armor) |
| 14 | Toys | `OR( TT "Adds this toy to your Toy Box" )` | | its line |
| 15 | Anima | `OR( TT "stored Anima into your covenant's Reservoir" )` | | its line |
| 16 | Conduits | `OR( TT "Add this Conduit to your collection" )` | | its line |
| 17 | Blueprints | `OR( NAME "Blueprint: " )` | | "Blueprint: Mechagon Tinkering" |
| 18 | Pets | `OR( NAME "Battle-Stone", NAME "Battle-Training Stone", SUB Companion Pets, CLASS #Battlepet )` | Companion Pets: none on Forever (15/2 is "Pet"); Miscellaneous 2 on retail | "Flawless Battle-Stone"; "Ultimate Battle-Training Stone"; a caged pet; a retail 15/2 item |
| 19 | Housing | `OR( CLASS Housing )` | none (empty) / 20 | a retail class-20 item |
| 20 | Mounts | `OR( SUB Mount )` | Miscellaneous 5, both | a 15/5 item |
| 21 | Flasks/Potions/Food | `OR( SUB Flasks & Phials, Potions, Food & Drink )` | Consumable 1, 5 / Consumable 1, 3, 5 | a potion; food; a retail flask. **Not caught:** a Forever flask (0/3, "Flasks") → Consumables |
| 22 | Gems/Enchants | `OR( CLASS Gem, SUB Item Enhancement )` | none (empty) / Class Gem | a retail gem (not Trade Goods) |
| 23 | Consumables | `OR( CLASS Consumable )` | 0 | a 0/8 item |
| 24 | Armor (Warbound) | `AND( CLASS Armor, BINDING warbound )` | | a chest warbound until equipped |
| 25 | Armor | `OR( CLASS Armor )` | | a cloth chest |
| 26 | Weapons | `OR( CLASS Weapon )` | | a sword |
| 27 | Archaeology | `OR( ITEMS <the 40 IDs>, TT "Carefully crate the restored artifact" )` | | item 52843; the crate line |
| 28 | Professions/Recipes | `OR( ITEMS 191784, TT "Use: Study to increase your", CLASS Recipe )` | | 191784; the study line; a recipe |
| 29 | Emerald Dream | `OR( NAME "dreamseed", NAME "dreamsurge" )` | | a trade good "Emerald Dreamseed" (not Trade Goods) |
| 30 | Trade Goods | `OR( CLASS Trade Goods, CLASS Gem, CLASS Tradeskill )` | 7 / 7, 3 | a 7/9 herb "Peacebloom" |
| 31 | Devices | `OR( SUB Devices )` | Consumable 14 / none | a Forever 0/14 item → Consumables, which comes first, as today |
| 32 | Quest | `OR( CLASS Quest )` | 12 | a quest item named "Rusty Key" (not Keys) |
| 33 | Keys | `OR( CLASS Key, NAME "key" word )` | 13 | "Skeleton Key" (class 13); a keystone; a Miscellaneous item "Key-Ring of Doom" |
| 34 | Miscellaneous | built in, catches the rest | | "Lucky Rock" |

Archaeology's 40 IDs, from `filters.lua:17-62`: 52843, 63127, 63128, 64392, 64394, 64395, 64396, 64397, 154990, 154989, 79868, 79869, 95373, 108439, 109584, 109585, 130904, 130905, 130903, 87399, 87533, 87534, 87535, 87536, 87537, 87538, 87539, 87540, 87541, 117386, 117387, 117388, 142113, 142114, 142115, 164625, 164626, 164627, 183834, 183835.

**What can't be written exactly in blocks, and what changes.** On English clients, only these differ from today:
1. **Reputation:** today it is the Lua pattern `Use: Grants ([,%d]+) reputation`. The blocks catch everything it catches, plus a tooltip with both phrases not joined by a number ("Use: Grants a random amount of reputation").
2. **Delves (the deliberate fix):** `" Curio"` becomes `Curio` as a whole word. "Curious" and "curiosity" stop matching, and "Curio" right after punctuation ("(Curio") starts to.
3. **Battle-Stone and Battle-Training Stone:** today the `-` worked only as a pattern quantifier. Now they are plain text on the same stripped subject, the same for every real name. The only change is a name with extra e's, such as "Battleestone".
4. **Delves' names:** Name is ignores case where today it doesn't. No item's name differs from these only by case.
5. **Old gear's tabard and shirt exclusion** never matched, and is left out (Global Constraints). Nothing changes.
6. **Off English:** keystones reach Keys only through the class name, so on other languages they go to Miscellaneous. Today the synthesized string sends them to Keys. Caged pets go by the enum, as today.
7. **The Auto Vendor list** isn't a filter, but its migration (Task 5) changes Grays/Auto Vendor. Today a listed item still had to get past Grays' exclusions, and equipment sets came before it. As a pin it beats both. A listed item that is Cosmetic, has the "Fishing" or account-bound text, or is in an equipment set now goes to Grays/Auto Vendor and is sold. A listed item with no vendor price goes there but isn't sold.

**The oracle (`fixtures/old_filters.lua`).** It is a copy of `git show 8dc348c:SaftUI-Bags/filters.lua`, the constants, `matchesAny`, `isLegacyGear` and the 33 filters, plus `category.lua:24-29`'s set test. `INV:AddFilter` collects into a local list instead. `INV:IsProtected` and `INV:ShouldAutoVendor` read the fixture's own `protected` and `autoVendor` sets. It returns `{ categorize = function(info) -> name, protected = {}, autoVendor = {} }`, and runs on the infos `GetInventoryItemInfo` builds, whose `class`, `subclass` and `tooltipText` are today's.

**The fixtures (`fixtures/category_items.lua`).** It is a list of `{ label, item = <W.item fields, IDs given>, expect = '<id>' }`, covering the table's column. A fixture whose result changes on purpose carries `changed = true`.

- [ ] **Step 1: Write the failing tests** in `tests/bags/category_defaults_test.lua`:
  - **`'the default list is today's, in today's order, after Equipment sets'`:** the 34 ids, in order.
  - **`'forever: every default catches what today's filter catches'`, and `'retail: …'`:** put each fixture in the bag world for that client and read it through `GetInventoryItemInfo`.
    - For every fixture not marked `changed`, the new key equals both `OLD.categorize(info)` and `expect`.
    - The `changed` fixtures are asserted in their own cases, below.
  - **`'forever: names resolve for this client'`, and `'retail: …'`:** the resolved rules in the table's fourth column.
  - **`'Delves: "Curious" is not Delves; "Combat Curio" is'`**.
  - **`'Reputation: catches every "Use: Grants N reputation", and a "Use: Grants" with "reputation" apart'`**.
  - **`'today's overlaps keep their order'`:**
    - a retail gem → Gems/Enchants;
    - a Warrior/Hunter/Shaman mail helm → its tier group;
    - a grey sword → Grays;
    - a flask → Flasks on retail and Consumables on Forever;
    - "Rusty Key", a quest item → Quest;
    - warbound armor → Armor (Warbound);
    - a "Dreamseed" trade good → Emerald Dream.
  - **`'first match wins; Miscellaneous is last, always on, and catches the rest'`**.
  - **`'equipment sets come first; turned off, set items go by the rules'`:** set `edits['Equipment sets'] = { enabled = false }` directly.
  - **`'a pin beats the rules and the order; a pin to a category that is off or missing, or to the sets entry, is ignored'`**.
  - **`'GetItemCategory says why: pin, set, rule with its path, misc'`**.
  - **`'IsAutoVendorItem sells only from the selling category, and never a Protected or priceless item, whatever the rule'`**.
  - **`'the list reads the store'`:** a saved order; a user category in `custom`; a deleted default; a default missing from a saved order, which appears at its default place (after its predecessor); and Miscellaneous last whatever `order` says.
  - **`'CategoryRank follows the list'`:** rewritten in `views_data_test.lua`. Sets, then the list, then an unknown key, then Miscellaneous, then Empty Slots.
  - **`'filters.lua is gone, and nothing reads INV.filters'`:** a scan with `read_saftui_source` of the TOC and every `SaftUI-Bags` Lua file.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement** the defaults, `categories.lua`'s read side, `GetItemCategory`, `IsAutoVendorItem`, `CategoryRank` and `InitializeAllCategories` (every entry but the sets entry). Remove `filters.lua` and the dead code. Update the test worlds' load lists.
- [ ] **Step 4: Run all tests.** `tests/run` passes. The Auto Vendor list is carried over by Task 5's migration.
- [ ] **Step 5: Commit.** `bags: categories are a list of block rules, with today's filters as its defaults`

### Task 4: Editing the categories, and pins

**Files:**
- Modify:
  - `SaftUI-Bags/categories.lua`: the write side, pins, Protected, and `EnsureCategoryFrames`;
  - `SaftUI-Bags/category.lua`: `CreateCategory`'s header, and `UpdateCategory`'s default title, show `CategoryName`;
  - `SaftUI-Bags/views.lua`: Rows' titles show `CategoryName`;
  - `SaftUI-Bags/slot.lua`:
    - the existing menu's Auto Vendor and Protected entries go through the new API;
    - delete `ShouldAutoVendor`;
    - move `IsProtected` to `categories.lua`.
- Test: `tests/bags/category_store_test.lua` (new), on `container_helpers.lua`'s views world.

**Interfaces:**
- Consumes Task 3.
- Produces these. Every write calls `INV:CategoriesChanged()`, which now also runs `INV:EnsureCategoryFrames()`.
  - **Adding:** `INV:AddUserCategory() -> id`.
    - It is named `New category`, or `New category 2`, `3`, … when that name is taken.
    - It is on, shown in every window, and its rule is `{ op = 'and', items = {} }`.
    - It goes just above Miscellaneous.
  - **Renaming:** `INV:RenameCategory(id, name) -> ok`. The name is trimmed; an empty one is refused.
  - **On and off:** `INV:SetCategoryEnabled(id, on)`. Refused for Miscellaneous.
  - **The rule:** `INV:SetCategoryRule(id, rule)`. It stores a copy, and is refused for the sets entry and Miscellaneous.
  - **Moving:** `INV:MoveCategory(id, place)`. The place is 1 to `#list - 1`. Miscellaneous can't move, nothing can go below it, and the whole order is written.
  - **Removing:** `INV:RemoveCategory(id)`.
    - A user category is removed. A default goes to `deleted`, and its edits are cleared.
    - Pins to it are removed.
    - Refused for Miscellaneous, Grays/Auto Vendor and Equipment sets.
  - **Restoring:** `INV:RestoreCategory(id)` brings a deleted default back at its default place, as shipped. `INV:GetDeletedDefaults() -> entries`, in the default order.
  - **Resetting:**
    - `INV:ResetCategory(id)` clears a default's edit: its name, on or off, Show in and rule.
    - `INV:ResetAllCategories()` clears `order`, `edits`, `custom` and `deleted`, and removes the pins to user categories.
    - Neither touches other pins or `protectFilter`.
  - **Pins:**
    - `INV:GetPin(itemID)`;
    - `INV:PinItem(itemID, id)` (pinning to Grays/Auto Vendor clears Protected);
    - `INV:UnpinItem(itemID)`;
    - `INV:GetPinnedItems(id) -> itemIDs`, ascending.
  - **Marks:**
    - `INV:IsProtected(itemID)`, moved here;
    - `INV:SetProtected(itemID, on)` (on clears a pin to Grays/Auto Vendor);
    - `INV:IsAutoVendorMarked(itemID)` and `INV:SetAutoVendorMark(itemID, on)`, which pin to and unpin from Grays/Auto Vendor.
  - **Frames:** `INV:EnsureCategoryFrames()` gives every list category but the sets entry a frame in every window made so far, as `InitializeAllCategories` does. In combat it queues itself (`'InventoryCategoryFrames'`).

- [ ] **Step 1: Write the failing tests** in `tests/bags/category_store_test.lua`:
  - `'AddUserCategory: "New category" just above Miscellaneous, catching nothing, with a frame in every made window'`
  - `'RenameCategory keeps the key, frame, place, held layout and pins; the header and the Rows title show the new name'`
  - `'an empty name is refused'`
  - `'SetCategoryEnabled: off, its items go to the next category; Miscellaneous cannot be turned off'`
  - `'SetCategoryRule applies on the next update; an edited default is edited, and setting the shipped rule back clears the edit'`
  - `'MoveCategory reorders Rows, One bag and Multi bag; Miscellaneous stays last; Compact still packs by height'`: Compact's columns are the same before and after the move.
  - `'RemoveCategory: yours goes with its pins; a default goes to deleted with its pins; Miscellaneous, Grays/Auto Vendor and Equipment sets cannot be removed'`
  - `'RestoreCategory: a deleted default back at its default place, as shipped'`
  - `'ResetCategory and ResetAllCategories: as shipped; your categories and their pins gone; other pins and Protected kept'`
  - `'pins: one category per item; pinning again moves it; unpinning returns it to the rules'`
  - `'Auto Vendor and Protected clear each other; a protected item is never sold, pinned or not'`
  - `'auto vendor and the junk coin follow an edited Grays/Auto Vendor rule'`: `OR( QUALITY 1 )` sells the common items and puts the coin on them.
  - `'Grays/Auto Vendor renamed and moved still sells; turned off, nothing is sold and no coin shows'` (Review Focus 5)
  - `'a category made out of combat has its frames; pinning to it in combat makes no frame or slot, and the item shows there after the update'` (Review Focus 4). Use `H.frames_made`.
  - `'every write drops the caches and queues one update with layout'`
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement**, normalizing every edit against `INV:GetDefaultCategory(id)` (Global Constraints).
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `bags: add, rename, move, turn off, delete, restore and reset categories, and pin items to them`

### Task 5: Old profiles, and Show in

**Files:**
- Modify:
  - `SaftUI-Bags/categories.lua`: `MigrateCategories`, `IsCategoryHidden`, `SetCategoryHidden`;
  - `SaftUI-Bags/inventory.lua`: `EnsureConfigTables` makes `categories` and `categoryPins`. `OnEnable`, and `UpdateConfig()` with no id, run `MigrateCategories` and then `CategoriesChanged` after `EnsureConfigTables`;
  - `SaftUI-Bags/container.lua`: `FlushIfFiltered`, and the Edit button's loop;
  - `SaftUI-Bags/category.lua`: the hidden checkbox in `CreateCategory`;
  - `SaftUI-Bags/views.lua`: Rows' hidden test.
- Test:
  - `tests/bags/category_migration_test.lua` (new);
  - update the cases that write `filters.categories.bag.<name>` for a list category: in `views_layout_test.lua` and `views_onebag_multibag_test.lua` they use `INV:SetCategoryHidden`, and one case keeps an old flag and runs the migration. `container_hold_test.lua`'s `Hidden` is a pseudo key and stays.

**Interfaces:**
- Produces:
  - **`INV:MigrateCategories()`** does nothing once `categories.version` is set. Otherwise:
    - every `filters.categories[w][name] = true`, for `w` in `bag`, `bank`, `warband` and `combinedbank` and `name` a default's id, becomes that default's `edits.hide[w]`, and is removed from `filters`;
    - every `autoVendorFilter[itemID]` becomes `categoryPins[itemID] = 'Grays/Auto Vendor'`, unless the item is Protected;
    - `autoVendorFilter` is removed, and `version` is set to 1.
  - **`INV:IsCategoryHidden(windowId, key)`:**
    - a list id: `entry.hide[windowId]`;
    - a `'Set: …'` key: the sets entry's `hide[windowId]`, or its old flag in `filters.categories`;
    - any other key: `filters.categories[windowId][key]`.
  - **`INV:SetCategoryHidden(windowId, key, hidden)`:** the same split, normalized as an edit.
- Consumes Tasks 3 and 4.

- [ ] **Step 1: Write the failing tests** in `tests/bags/category_migration_test.lua`:
  - `'an old profile sees today's categories in today's order'`: a profile with no `categories` gets the shipped list after the migration, and the same categories for the Task 3 fixtures.
  - `'hide flags become Show in, per window; Empty Slots, Currencies and Set: flags stay where they were'`
  - `'the Auto Vendor list becomes pins to Grays/Auto Vendor; an item on both stays Protected and loses its pin; the list is gone'`
  - `'the Protected list carries over unchanged'`
  - `'the migration runs once'`
  - `'Show in hides a category in Compact and Rows, not in One bag or Multi bag; a hidden category still catches its items'`
  - `'renaming a category keeps its Show in'`
  - `'the Edit view's checkbox reads and writes Show in'`
  - `'Equipment sets' Show in hides every Set: category; an old Set: flag still hides its set'`
  - `'a profile switch, copy and reset re-read the categories, edits and pins, and migrate an old profile'` (Review Focus 2). Point `st.config.profile` at another table, `st:BindModuleConfig(INV, 'inventory')`, `INV:UpdateConfig()`.
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `bags: old profiles keep their categories: hide flags become Show in, and the Auto Vendor list becomes pins`

### Task 6: Custom widget types, bare rows and a check list (Core)

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua`, `SaftUI-Core/Config/optionsbody.lua`, `tests/core/options_walk.lua`.
- Test: `tests/core/options_widgets_test.lua`, `tests/core/options_window_test.lua`.

**Interfaces:**
- Produces:
  - **`W.Define(rowType, { width = n, bare = bool, build = function(w) end, methods = { Refresh = …, OnRelease = …, ... } })`:**
    - It registers a type through the same machinery as `define`, and sets `W.WIDTH[rowType]` and `W.CUSTOM[rowType] = { bare = bare }`.
    - Redefining a built-in type is an error. A custom type may be defined again.
  - **Bare rows** (`OB`), for a row whose type `W.CUSTOM` marks bare:
    - no label;
    - the widget gets the body's width (`widget:SetWidth`, when it has one) before its height is read;
    - it sits at the cell's top left, 6 down;
    - the cell is `ceil(height) + 12` tall;
    - the row frame takes no mouse. Every row sets `EnableMouse` as it's acquired.

    A bare row's option sets `size = 'wide'`.
  - **`W.OpenCheckList(owner, entries, isChecked, onToggle)`:**
    - `entries` are `{ key, label }`;
    - each row shows a check box, and a click calls `onToggle(key)` and redraws the marks, leaving the list open;
    - a click outside or Esc closes it, and so does `W.CloseList`;
    - `W.ListOwner()` reports it, so the window waits to re-render.

    It reuses the select list's frames.
  - **`options_walk.lua`:** a global `SAFTUI_TYPES = { position = true, bagcategories = true, bagrule = true, bagitems = true }`. `ace_ready` leaves out options of those types.

- [ ] **Step 1: Write the failing tests:**
  - `'W.Define: W.Create gives the type from its pool, and Bind, Refresh and Release run its methods'`
  - `'redefining a built-in type is an error'`
  - `'a bare row: no label, the body's width, at the cell's top left, its widget's height plus 12, and no mouse on its row'`: in the options window, a page with a bare row between normal rows.
  - `'W.OpenCheckList: rows show their marks; a click toggles one and the list stays open; Esc and a click outside close it; ListOwner reports it'`
  - `'ace_ready leaves out SaftUI's own types'`
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `core: options widgets: custom widget types, bare rows, and a check list`

### Task 7: The outline rule editor

**Files:**
- Create: `SaftUI-Bags/ruleeditor.lua` (in the TOC after `options.lua`).
- Modify: `SaftUI-Bags/rules.lua`: the tree edits and the outline model.
- Test:
  - `tests/wow/game.lua`: `GetCursorInfo()`, which gives `'item', id, link` from `stub.cursor_item = { id, link }` and nothing when it's nil, and `ClearCursor()`, which clears it;
  - `tests/bags/rule_edit_test.lua` (new, pure);
  - `tests/bags/rule_editor_test.lua` (new), with the widget bound to a synthetic option over a stored rule. Load the model, widgets and body as `tests/core/options_widgets_test.lua` does, and stub `C_Item.GetItemClassInfo` and `GetItemSubClassInfo` from `fixtures/item_classes.lua` (Forever's tables).

**Interfaces:**
- Consumes `R` (Task 2), `INV.ItemClasses`, `W.Define`, `W.OpenList`, `W.OpenCheckList`, `W.Box` and `W.Edge`.
- Produces, in `rules.lua`:
  - **New nodes:**
    - `R.NewBlock(typeId)`: the type's new params;
    - `R.NewGroup(parentOp)`: `{ op = <the other operator>, items = {} }`.
  - **Edits:**
    - `R.Insert(rule, parentPath, index, node)`;
    - `R.Remove(rule, path) -> node`;
    - `R.Move(rule, fromPath, toParentPath, toIndex) -> ok`: false for a move into the node itself or its own subtree, and for no move at all;
    - `R.Flip(rule, path)` and `R.ToggleNot(rule, path)`.
  - **The outline:**
    - `R.Outline(rule) -> rows`. In order, each row is `{ kind = 'block' | 'group' | 'add', path, depth, node, op }`, where `op` is the operator of the group it hangs off. A nested group has a title row (`kind = 'group'`), and every group ends with an `'add'` row.
    - `R.DropAt(rows, i, lower) -> parentPath, index`, for dropping over row `i`:
      - the upper half of a block or group row puts the node before it;
      - the lower half of a block row puts it after;
      - the lower half of a group title row puts it first in that group;
      - an add row puts it at that group's end.
- Produces the widget type `bagrule` (bare, wide):
  - **Option:** `{ type = 'bagrule', size = 'wide', name, desc, get = function(info) -> rule end, set = function(info, rule) end }`.
  - **Commits:** every change commits the whole new rule (`self:Commit(rule)`), on a copy of `get`'s rule.
  - **`widget:SetHighlight(path | nil)`**.
  - **What tests read:** `widget.rows[i] = { frame, path, kind, handle, notBox, remove, badge, fields = { ... } }`.

**The look (option C):**
- **Rows:** each row is 26 high. Each level of nesting indents 34.
- **Group lines:** a group's line is 2px, at its indent plus 12. AND is `colors.button.blue` and OR `colors.text.orange`.
- **Badges:** an `AND` or `OR` badge (`W.Box`) sits on the line at its middle. A click flips it.
- **Connectors:** an 18px connector runs from the line to each row.
- **A block row:** the handle (6 dots, textures), the NOT box, the grey label, the fields, and the remove X (`st.textures.close`) at the right.
- **A group title row:** the handle, NOT, `group` in grey, and X.
- **The add row:** `+ Block` and `+ Group` in blue, at the end of every group.
- **The highlight:** the row tinted `colors.text.orange` at alpha 0.15.

**Fields per block** (boxes and fields use `W.Box`):
- **`tooltip` and `name`:** a 150 box, and a check box labeled `whole word`.
- **`nameis`:** a 150 box.
- **`class`:** a field that opens `W.OpenList` over `IC.Classes()`, leaving out names with `OBSOLETE`. It shows `Pick a class` until one is picked.
- **`subclass`:** that class field, plus a subclasses field that opens `W.OpenCheckList` over `IC.Subclasses(class)`. The field shows the names joined, or `Pick subclasses`.
- **`quality`, `slot`, `binding` and `expansion`:** a field and a check list. Expansions run from 0 to `GetNumExpansions() - 1`, or 0 to 11 without it.
- **`ilvl` and `reqlevel`:** a mode list (`at least`, `at most`, `between`) and one or two 50 boxes.
- **`reagent` and `vendorprice`:** a `Yes` or `No` list.
- **`items`:**
  - a field `<n> items`, whose check list shows `<name> (<id>)` (`C_Item.GetItemNameByID`, else `Item <id>`), where unchecking one removes it;
  - a 50 box, `ID`, where Enter adds a number;
  - the row takes an item from the cursor (`GetCursorInfo()` gives `'item'`) on `OnReceiveDrag` or a click, adds it, and calls `ClearCursor()`.
- **`oldgear`:** three 40 boxes, `levels below me`, `expansion up to` and `% of my item level`. The share is shown and typed as a percent.
- **`protected`:** the grey note `items marked Protected`.
- **Unknown:** `Unknown block`, with only the X.
- **Text boxes** commit on Enter. Esc or leaving the box puts the stored value back, as the options window's inputs do.

**Dragging:**
- `OnMouseDown` on a handle starts the drag. It calls `onChanged(true, nil, true, widget)`, so the window waits to re-render (`Busy`).
- `OnMouseUp` finds the row under the cursor (`IsMouseOver`, and `GetCursorPosition` against the row's middle for the half), then runs `R.DropAt`, then `R.Move`, then commits.
- An `OnUpdate` runs only while dragging, and only draws the insertion line and the ghost. The commit never depends on it.

- [ ] **Step 1: Write the failing tests:**
  - `rule_edit_test.lua`:
    - `'Insert, Remove, Flip and ToggleNot at a path'`
    - `'NewGroup takes the other operator; NewBlock gives each type its new params'`
    - `'Move within a group, between groups and into an empty group, never into itself'`
    - `'Outline: rows in order with their depths, group title rows and add rows'`
    - `'DropAt: before or after a block, first in a group, at a group's end'`
  - `rule_editor_test.lua`:
    - `'a row per block and group, a badge per group, AND blue and OR orange'`
    - `'+ Block lists every block type in order; a pick adds it at the group's end'`
    - `'+ Group adds an empty group with the other operator'`
    - `'NOT toggles, the X removes, the badge flips'`
    - `'each block type's fields set its params'`: a case per type.
    - `'a text box commits on Enter only'`
    - `'dragging a block into another group moves it'`
    - `'an ID typed, and an item dropped from the cursor, join Item is one of'`
    - `'SetHighlight tints the row at a path'`
    - `'an unknown block shows as Unknown block and can be removed'` (Review Focus 3)
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `bags: the outline rule editor`

### Task 8: The Categories tab

**Files:**
- Create: `SaftUI-Bags/categoriestab.lua` (in the TOC after `ruleeditor.lua`).
- Modify:
  - `SaftUI-Bags/options.lua`: `args.categories`, after the window tabs;
  - `SaftUI-Bags/inventory.lua`: `UpdateHandler` re-renders an open tab.
- Test:
  - `tests/wow/widgets.lua`: a tooltip's `SetBagItem(bag, slot)` and `SetItemByID(id)`, each making one line, as `SetHyperlink` does;
  - `tests/bags/categories_tab_test.lua` (new), on the views world with the widgets;
  - `tests/core/options_frames_pages_test.lua`: the Bags page has the tab.

**Interfaces:**
- Consumes Tasks 3-7.
- Produces:
  - **Widget types:** `bagcategories` (bare, wide, the tab's one row) and `bagitems` (bare, wide; an option field `items = function() -> { { itemID, info } } end`, plus `onRemove(itemID)` or `onHover(entry | nil)`).
  - **`INV:CategoryEditorOptions(id) -> group`:** the selected category's options.
  - **`INV:CountCategories(windowId) -> counts, items`:** by key, read with `ReadBags` as Compact reads the window, so the count is what its header shows.
  - **`INV.categoryEditor = { selected = id }`:** session state.
  - **`INV:EditCategory(key)`:** selects the key's entry (the sets entry for `'Set: …'`) and runs `st.Config:Open('Inventory', 'categories')`.
  - **`INV.categoriesTabShown`:** true while a `bagcategories` widget is bound.

**The tab row:** `categories = { type = 'bagcategories', size = 'wide', name = 'Categories', desc = 'Every bag category in the order they claim items: an item goes to the first one that catches it. Drag a category by its handle to move it, and select one to edit it.' }`.

**The composite** (the body's 774 width):
- **The list pane**, 210 wide:
  - Rows are 22 high, each with a handle, the name, the marker (`edited` or `yours`, `colors.text.orange`) and the count (grey, at the right, when above 0).
  - The selected row has a blue tint and a 3px `colors.button.blue` bar at its left.
  - A row that is off is grey, with a 1px line through its name.
  - Under the list: `+ New category` and `Reset all`, both in blue.
- **The editor pane** starts at x 234 and is 540 wide. It is an options body, `st.OptionsBody.New(pane, root, forward, 540)`, drawing `OM.BuildView(root, 'category').sections`, where `root = { category = INV:CategoryEditorOptions(id) }`.
  - **Forwarding:** `forward` passes each `onChanged` on to the composite's own, with the composite as the dragged widget whenever a drag is reported.
- **Height:** the composite is as tall as its taller pane.

**The editor's options** (order, key, type, name, desc):

| Order | Key | Type | Name | Desc / notes |
|-------|-----|------|------|--------------|
| 1 | `name` | input | Name | "What the category is called in the bag windows. Renaming it keeps its place, its Show in choices and its pinned items." It validates as not empty. |
| 2 | `enabled` | toggle, small | On | "Turned off, the items it would catch go to the next category that catches them." Grays/Auto Vendor adds " Turned off, auto vendor sells nothing." Hidden for Miscellaneous. |
| 3 | `show` | multiselect | Show in | "The windows that show this category. A hidden category still catches its items; One bag and Multi bag show every item." `Warband bank` and `Combined bank` only with `INV:HasWarbandBank()`. |
| 10 | `rule` | bagrule | Catches an item when | "An item goes to the first category, from the top of the list, whose rule it matches. AND needs every block, OR any one. Click AND or OR to flip it, and drag a block by its handle to move it." For rule entries. |
| 10 | `note` | description | | Equipment sets: `Makes a category for each equipment set, "Set: <name>", for the armor and weapons in it. It has no rule.` Miscellaneous: `Catches every item no category above it catches. It is always last.` |
| 20 | `pins` | bagitems | Pinned items | "Items you added to this category from the slot menu (Ctrl + right click an item). They go here whatever the rules say. Click the X on one to unpin it." Hidden when there are none. |
| 30 | `caught` | bagitems | Caught now | "The items in your bags this category catches now. Hover one to see which block caught it." |
| 40 | `reset` | execute | Reset <name> to default | "Put this category back as SaftUI ships it: its name, on or off, Show in and rule. Its pinned items stay." Defaults only, and disabled unless edited. |
| 41 | `delete` | execute | Delete | "Delete this category. Its items go to the next category that catches them." Not for Miscellaneous, Grays/Auto Vendor or Equipment sets. It confirms with `Delete <name>? You can bring it back with + New category > Restore a default..., or Reset all.` for a default, or `Delete <name>? Items pinned to it go back to the rules.` for one of yours. |

**Behaviours:**
- **Selecting:** a click on a row selects it.
- **Reordering:** dragging a row's handle reorders the list, with the same protocol as the outline (`MoveCategory`). Miscellaneous has no handle, and a drop below it lands just above it.
- **`+ New category`:** with no deleted defaults, it adds one at once and selects it. With deleted defaults, it opens a list of `New category` and `Restore a default...`, and the second opens a list of their names.
- **`Reset all`:** it asks `Reset all categories to SaftUI's defaults? Your own categories are deleted. Pinned and Protected items are kept.` (`W.Confirm`), then runs `ResetAllCategories`.
- **The selection:** after a delete, it moves to the entry now in that place. When the selected id no longer exists (a profile switch), it moves to the first entry.
- **The highlight:** hovering a `Caught now` icon highlights its `why.path` in the rule widget.
- **Live counts:** a bag update while `INV.categoriesTabShown` is true calls `st.Config:Refresh()`, so the counts and `Caught now` stay live.
- **Icons:** each icon's tooltip is `GameTooltip:SetBagItem` for an item in the bags, else `SetItemByID`.

- [ ] **Step 1: Write the failing tests:**
  - `'the Bags page has a Categories tab after the windows: one wide row with a desc'`, also checked in `options_frames_pages_test.lua`.
  - `'the list: every category in order, counts from the bag window, the edited and yours markers, struck through when off, the selected row'`
  - `'dragging a row's handle reorders the list; Miscellaneous stays last'`
  - `'+ New category adds one above Miscellaneous and selects it; with a deleted default it offers Restore a default...'`
  - `'Reset all asks first, then resets'`
  - `'the editor has its rows, each with a desc'`: Name, On, Show in (Warband and Combined only with a warband bank), the rule, Pinned items, Caught now, Reset and Delete. Use `each_option` over `CategoryEditorOptions`.
  - `'Equipment sets and Miscellaneous have no rule; Miscellaneous has no On or Delete; Grays/Auto Vendor has no Delete'`
  - `'Delete asks first; the selection moves to the next category'`
  - `'Caught now shows the items the category catches now; hovering one highlights the block that caught it'`
  - `'pinned items show, and the X unpins one'`
  - `'a bag update while the tab is open refreshes its counts'`
  - `'EditCategory opens the tab with the category selected, the sets entry for a set'`
  - `'a profile switch with the tab open selects a category of the new profile'`
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `bags: the Categories tab in /sui`

### Task 9: Why is this here: the tooltip lines and the slot menu

**Files:**
- Modify:
  - `SaftUI-Bags/slot.lua`: the tooltip lines; the slot menu; and a weak set of SaftUI's item slots, filled by `CreateSlot`;
  - `SaftUI-Bags/inventory.lua`: `OnEnable` registers the tooltip post-call once.
- Test: `tests/bags/category_tooltip_menu_test.lua` (new).

**Interfaces:**
- Consumes Tasks 3, 4 and 8.
- Produces:
  - `INV:CategoryTooltipLines(info) -> { { text, r, g, b }, ... }`. There are none for a free slot, an item still loading, or an info with no category.
  - `INV:AddCategoryTooltipLines(tooltip, info)`.
  - `INV:HookSlotTooltips()`: `TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, fn)`. `fn` adds the lines only when `tooltip == GameTooltip` and its owner is in the weak set with an item. It does nothing without `TooltipDataProcessor`.
  - `INV:SlotMenuEntries(info) -> entries`: `{ kind = 'button' | 'checkbox' | 'radio' | 'submenu', text, checked = fn, onClick = fn, entries }`.
  - `INV:OpenSlotMenu(slot)`: `MenuUtil.CreateContextMenu(slot, generator)`, which translates the entries. `st:CreateCheckboxDropdown` stays, because SaftUI-Loot uses it.

**The copy:**
- **Line 1:** `Category: <name>` in `colors.text.blue`, then ` (<nth>)` in `colors.text.grey`. The place is `INV:CategoryPlace(key)`, written 1st, 2nd, 3rd, 4th…, with 11th to 13th.
- **Line 2:** `Caught by: ` in `colors.text.yellow`, then one of:
  - `R.Describe(rule, why.path)`;
  - `pinned to this category`;
  - `an equipment set`;
  - `no category above it`.
- **The menu,** in order:
  - `Edit this category` (button);
  - `Add to category…` (submenu): the radio `None (follow the rules)`, then every list category that is on, except Equipment sets, in list order, each a radio, checked for the current pin;
  - `Auto Vendor` (checkbox);
  - `Protected` (checkbox).

  It still opens on Ctrl + right click, and a free slot opens nothing.
- **Check the names against the forever source:** `Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua` and `Blizzard_Menu/MenuUtil.lua`.

- [ ] **Step 1: Write the failing tests:**
  - `'tooltip lines: the category, its place and the block that caught it; a nested block names its groups'`
  - `'pinned, set and Miscellaneous items say so'`
  - `'no lines for a free slot or an item still loading'`
  - `'the post-call adds lines only to GameTooltip owned by a SaftUI slot'`: capture the callback with a stand-in `TooltipDataProcessor`.
  - `'the slot menu: Edit this category, Add to category… with every category that is on, in order, and the current pin checked, Auto Vendor and Protected'`
  - `'Add to category… pins, moves and unpins; Auto Vendor and Protected clear each other'`
  - `'Edit this category opens the tab at the item's category'`
- [ ] **Step 2: Run them; they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run all tests.** `tests/run` passes.
- [ ] **Step 5: Commit.** `bags: tooltip lines naming an item's category and why, and Edit this category and Add to category in the slot menu`

### Task 10: Docs

**Files:**
- `README.md`, Bags:
  - the Categories tab;
  - the tooltip lines;
  - the slot menu's new entries;
  - the junk coin's sentence, which now names items in Grays/Auto Vendor rather than items marked Auto Vendor.
- `AGENTS.md`: SaftUI-Bags' row (no `filters.lua`).
- `.agents/testing.md`:
  - the new test files;
  - `bag_world.lua`'s stand-ins: links, tooltip lines, the item class tables, every `GetItemInfo` value;
  - the fixtures (`item_classes.lua`, `old_filters.lua`, `category_items.lua`);
  - the new shared stubs: `C_Timer.After` with `stub.run_timers()`, `GetCursorInfo` with `ClearCursor` and `stub.cursor_item`, and a tooltip's `SetBagItem` and `SetItemByID`.
- `.agents/edit-mode.md`:
  - `W.Define`, bare rows and `W.OpenCheckList`;
  - Bags' Categories tab (the composite widget and its editor body);
  - `SAFTUI_TYPES` in `options_walk.lua`.
- `docs/followups.md`:
  - move "Bag categories: make the category rules configurable in /sui" to Resolved;
  - update the bag sort entry's anchors (`filters.lua` is gone; the categories are in `categories.lua`);
  - add "Old gear's tabard and shirt exclusion never matched";
  - add "Bag categories: in-game checks" (the list below);
  - add "Auto Vendor pins now beat Grays' exclusions and equipment sets" (item 7 of Task 3's list, should the user want a guarantee).

- [ ] **Step 1: Update the docs.**
- [ ] **Step 2: Run all tests and the doc audits.** `tests/run` passes. Run `agents-doc-parity-check` and `readme-freshness-check`.
- [ ] **Step 3: Commit.** `docs: bag categories: README, agent docs and followups`

## In-game checks (for the user, after Task 10)

1. **Forever, cold login:** after `/reload` with the bags open, every item lands where it did before this change, and the loading bar clears.
2. **Forever device:** `/run print(C_Item.GetItemSubClassInfo(0, 14))` prints `Devices`, and a device item's subclass in `GetItemInfo` is `Devices`.
3. **Delves:** a "Curious …" item is no longer in Delves, and a Combat Curio still is.
4. **Equipment sets on Forever:** an item in a set shows as `Set: <name>`, or the set entry does nothing there. Note which.
5. **The tab:** reorder by drag; add a category with `Subclass is Tradeskill: Herb, Metal & Stone` and move it above Trade Goods; rename it; turn it off; delete it; restore a default; Reset all.
6. **The tooltip** of a bag item shows `Category: … (nth)` and `Caught by: …`, and the lines stay after the tooltip refreshes (hold Shift).
7. **The slot menu:** Ctrl + right click → Add to category… moves the item; Auto Vendor and Protected clear each other; Edit this category opens the tab.
8. **At a vendor,** with Grays/Auto Vendor renamed and moved, the junk sells; turned off, nothing sells.
