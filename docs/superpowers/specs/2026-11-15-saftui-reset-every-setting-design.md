# A reset on every setting in `/sui`

Design, 2026-11-15. It makes the options kit's per-setting reset (the `ResetIcon`, decision 10) one rule for
every row of `/sui`, with a default the kit takes from the AceDB defaults themselves, and it removes the
section Reset buttons that are left. It takes up the followups "A reset on every font row" (2026-11-15) and
"Categories tab at full size: a long "Reset <name> to default" overlaps Delete" (2026-11-14), and the design
system's discrepancy 17. It is a draft for the owner: every decision he didn't make is marked **call** and
listed again under "Calls made while writing this".

Checked against SaftUI's code on `modular` at `12859a99`. The audit below was run on that commit. Nothing
here has been checked in game; the checks it needs are G1 to G7 under "In-game checks".

Words used below:

- **Row**: one option of a page as the window draws it (`OM.BuildView`'s rows), item menus' options included.
- **Value row**: a row that shows a value a player can change: toggle, range, select, multiselect, input,
  color, keybinding, font, position, and an item with a Show box. Execute, description and header rows, and
  the bags' own types (`W.Define`), are not value rows.
- **Saved path**: the keys from `st.config.profile` down to where a row's value is saved
  (`'chat', 'font'`; `'unitframes', 'profiles', 'SaftUI', 'player', 'health', 'enable'`).
- **AceDB default**: the value `st.defaults` gives a saved path by AceDB-3.0's rules (a key's own default,
  else its table's `'**'`, else `'*'`), which is what a fresh profile holds.

## Why

The owner, testing in game: "I did notice that I don't get a reset option when changing the title font on
the bags, Being able to reset any entry in the config to the default value would be great."

The rule has stood since decision 10 (`docs/design-system/05-decisions.md`): a `rotate-ccw` icon beside a
setting whose value differs from its default, and no section or page Reset buttons. The kit draws that icon
for any option that carries SaftUI's `default` field, but only 283 options carry one (the audit, below), so
the icon shows on the Colors, Theme and Fonts tabs, the tracker's page and All bars, and on a few rows
elsewhere (the buffs' and debuffs' texts, the unit frames' Custom color rows, one of the totem bar's).

## What the owner decided

Asked whether to make it one rule at the generator level, so every row gets a default and a reset, and to
remove the remaining section Reset buttons (the Categories tab's "Reset <name> to default" overlaps Delete
today), he said: "Yep that sounds good". So:

1. Every value row in `/sui` has a reset, unless it has no default by its nature (the exemptions are named,
   below).
2. The section Reset buttons that are left go, each replaced by per-setting resets.

## Goals

- Every value row shows the reset icon while its value differs from its default, on every page, in item
  menus and in the Categories editor, at full and half size, under Thick, Thin and Blizzard.
- A default comes from the same table AceDB was built from, so it can't drift from what a fresh profile
  holds. A page says where its settings are saved once, beside the `get` that reads them.
- A reset goes through the row's own `set`, so everything a player's change runs (the module's update,
  live handlers, validation) runs for a reset too, and a mover's Position resets as edit mode's Reset does,
  as one step its Undo can take back.
- No section or page Reset button is left in SaftUI's own pages.
- A test fails when an option is added with no reset and no stated reason, and when a page is added that no
  reset test walks.

## Non-goals

- AceDBOptions' Profiles page. It is Ace's own table; its Reset Profile resets a whole profile and stays.
- A reset on the edit mode bar's controls (Grid size, the toggles). They are the same settings as the Edit
  mode tab's rows, which get theirs.
- Dialogs' rows: the Copy from dialog's ticks and the Unit frame profiles dialog. They are choices for one
  action, not saved settings.
- Rewriting the hand-written defaults that already work (the shares, Theme's Background, the tracker's
  `TR.SettingDefault`, All bars' text defaults), except where one restates a default as a literal (below).
- The edit mode history's part two (`/sui` settings as Undo steps). A reset takes the same path as a change,
  so it is recorded wherever that part records changes, once it is built.
- Changing any default value. (One exception is recorded as a risk: three positions whose default the set
  can't store.)

## Anti-goals

- A second copy of a default. A row never writes its default as a literal beside `st.defaults`; it says
  where its value is saved and the kit reads `st.defaults`.
- A reset that clears a saved key. AceDB copies plain defaults into the profile at login and only strips
  values equal to a default at logout (only `'*'` and `'**'` tables have metatables), so a cleared key reads
  nil until the next login or profile change, and every reader of `self.config.<key>` would see nil.
- A reset that bypasses the row's `set` (a write straight into the profile). It would skip the module's
  `UpdateConfig`, the live handlers and the validation a player's change runs.
- A reset icon on a row whose value isn't the player's to set back (a session-only Test mode, the profile
  picker).
- Any Reset button for a group of settings.

## The audit

### How it was done

By code, not by guess: a throwaway test file per test world (scratchpad, not committed), each an existing
page test's world (`tests/core/options_desc_test.lua`, `tests/unitframes/config_test.lua`'s first 106
lines, `tests/core/options_frames_pages_test.lua`, `tests/misc/options_pages_test.lua`,
`tests/tracker/options_test.lua`, `tests/misc/objective_tracker_position_test.lua`,
`tests/misc/durability_position_test.lua`) with one case added that builds every page it can
(`st.Config:GetOptionsTable()` and each module's `GetConfigTable()`), walks it with `each_option`, and for
each value row:

1. reads whether it has `default` or a share;
2. probes it: reads its value with `OM.Get`, sets another one with `OM.Set` (a toggle flipped, a range one
   step, another select key, a color's red moved, a position's X moved 3, another font key), takes a deep
   copy of `st.config.profile`, `.char` and `.global` before and after and diffs them, records any
   `SetCVar` or `SetBinding` call, then sets the old value back;
3. looks the written keys up in `st.defaults` by AceDB's rules;
4. checks that the row's `get` gives the saved value (an identity check: a row whose `get` transforms what
   is saved can't take a derived default as it is).

The Unit frames page is counted over its 13 unit pages (each unit draws its own copy of the element tabs).

### The numbers

2959 rows on 18 SaftUI pages and AceDBOptions' Profiles (2307 of them on the 13 unit frame pages, which
have 248 distinct option definitions).

- **2915 value rows.** (The rest: 37 pieces of the unit frames' pick controls, 5 rows of the Profiles page,
  Loot's Clear history and the bags' Categories tab, a fill row of its own type.)
- **523 have a reset today (18%)**: 283 through `default`, 240 through a member page's share (each action
  bar's own settings, whose hover line's Reset is their reset).
- **2392 have none (82%).** Of those:
  - **2370 save one profile key whose AceDB default is known**: they can take a derived default. 2342 of
    them passed the identity check; 18 couldn't be checked because the test world's stand-ins errored after
    the write (the Auras page's 16, two nameplate rows); 3 failed it: the player's Power, Castbar and
    Additional power positions, whose default X is 0.5 while the position `set` stores whole pixels (Risks,
    R1). Seven are counted here though the probe missed them: Theme > Theme (its `set` also marks
    `fonts.version`, which has no default), the Bags' two View rows (the world's `INV:SetView` was a
    counter) and the Auras' four Grow and Wrap rows (a stand-in errored before the write); each saves one
    key with a default (`theme.name`, `inventory.<window>.view`, `auras.<kind>.grow` and `.wrap`).
  - **5 save a key with no AceDB default**: Chat's Width and Height (taken from Blizzard's chat frame on
    first load, `CHT:CaptureSize`), and the Positions of SaftUI's tracker, Blizzard's tracker and the
    durability figure, whose movers' defaults are code (`st:DefaultTrackerPosition()`) or none
    (`noDefaultReason`).
  - **6 session-only Test mode toggles** (party, raid 10, raid 40 and boss; loot rolls and loot feed): not
    saved, off at every login.
  - **11 Cooldown items** on the action bars: All bars' Show is Blizzard's CVar `countdownForCooldowns`; the
    ten bars' items have no Show (`get = false`), so no value of their own.

By who made the 2392: generators set no default anywhere: `generators.theme` 145, `generators.background`
144, `generators.width`/`height` 120, `generators.font` 94, `generators.position` 87,
`uf_element_position` 182 (772 rows). The other 1620 are toggles (992), ranges (534), selects (57),
colors (26) and items (11), written by hand or by `generators.toggle`/`range`, which are indistinguishable
once built.

### By page

| Page | Rows | Reset today | No reset: one key with a default | No reset: other |
| --- | --- | --- | --- | --- |
| Global settings (General, Fonts, Colors, Theme, Edit mode) | 136 | 123 | 13 (General's 3, Edit mode's 9, Theme > Theme) | — |
| Unit frames (13 unit pages; 248 definitions) | 2307 | 50 (6: the Custom color rows of Health, Power, Additional power) | 2216 (238) | 4 Test mode (1); pick controls 37 (3) |
| Action bars | 305 | 288 | 6 (the extra buttons' Position, Scale, Button size) | 11 Cooldown items |
| Bags | 30 | 0 | 29 | the Categories tab (below) |
| Loot | 20 | 0 | 17 | 2 Test mode; Clear history |
| Buffs and debuffs (Auras) | 32 | 12 | 20 | — |
| Chat | 9 | 0 | 7 | Width, Height |
| Swing timer | 18 | 0 | 18 | — |
| Totem bar | 14 | 1 | 13 | — |
| Experience | 9 | 0 | 9 | — |
| Tooltip | 6 | 0 | 6 | — |
| Skinning | 6 | 0 | 6 | — |
| Minimap | 5 | 0 | 5 | — |
| Micro menu | 1 | 0 | 1 (Position) | — |
| Tracker | 50 | 49 | — | Position (its mover's default is code) |
| Blizzard's tracker | 3 | 0 | 2 | Position (as the tracker's) |
| Durability | 3 | 0 | 2 | Position (no default) |
| Profiles (AceDBOptions) | 5 | — | — | Ace's own |

The Categories tab is one row the walk can't see into. Its editor, an options body of its own
(`INV:CategoryEditorOptions`), has per shipped category Name, On, Show in and the rule (a `bagrule` row),
with one execute, "Reset <name> to default", for all four; Pinned items and Caught now, which are lists;
and Delete. Its list has + New category and Reset all.

### The kinds of gap

1. **A generator that sets none**: every generator (`theme`, `background`, `width`, `height`, `font`,
   `position`, `uf_element_position`, `toggle`, `range` and its family).
2. **A hand-written option** with a `get` of its own and no `default` (most selects and colors).
3. **A value that isn't a simple profile key**:
   - a position: a table, and for a mover a default that may live in code;
   - lists: Pinned items, Caught now;
   - the bags' categories and rules: a store with shipped defaults and per-field edits, not AceDB defaults;
   - key bindings: the tracker's Key (it has a hand default today);
   - the unit frame profile: the Profile select chooses which profile is in use;
   - per-character and account-wide data: none in `/sui` today;
   - CVars and game settings: All bars' Cooldown Show (`countdownForCooldowns`). The nameplate CVars are
     set from profile keys (`UF:ApplyNameplateCVars`), so their rows are profile rows;
   - execute buttons;
   - values with no default by their nature: Chat's size, the durability figure's place, Test mode.

### The section Reset buttons left

Read from the code: the Colors tab's section Resets, Theme's Reset and the cooldown numbers' Reset are
already gone (`Media/colors.lua`, `Media/theme.lua`'s header, `textoptions.lua`'s header). Left: the
Categories editor's "Reset <name> to default" (`SaftUI-Bags/categoriestab.lua:384`) and the list's
"Reset all" (`categoriestab.lua:1183`). Not settings resets, and kept: the Profiles page's Reset Profile
(Ace's), Loot's Clear history (data), edit mode's per-mover Reset on its bar (an action on the selected
mover, with the same default as below).

## The design

### 1. Where a default comes from

A default is read from `st.defaults` at the row's saved path, by AceDB's rules. A page says the path once,
beside the `get` that reads it. **call** (against a `default` written on each option, which would be a
second copy of all 2370 defaults, each to be kept in step by hand whenever `st.defaults` changes; the
fonts work of 2026-11-14 changed the bags' and the tracker's title defaults to Heading).

**The field.** `saved` (SaftUI's own field, on a group or an option):
`saved = function(info) -> key1, key2, ...`, the saved path as multiple returns (no table, so no garbage per
row), or `saved = false` (not a profile value). Two builders make the usual shapes, each part a value or a
function of `info`:

- `st.Config.SavedIn(...)`: those parts, then `info[#info]`. The usual group:
  `get = function(info) return self.config[info[#info]] end` gets `saved = st.Config.SavedIn('chat')`.
- `st.Config.SavedAt(...)`: those parts exactly. An option with a `get` of its own:
  `saved = st.Config.SavedAt('chat', 'editbox', 'height')`.

**Where the kit reads it.** From the node that gives the row its `get`: the option itself when it has a
`get`, else the nearest group above it with one, as AceConfig inherits `get`. Never from another node:
`saved` belongs to a `get`, so an option that reads elsewhere with a `get` of its own can't inherit a
group's path that doesn't match it. **call** That node's `saved` false or nil: no derived default.

**The default.** `st:DefaultAt(...) -> found, value` walks `st.defaults` by the keys as AceDB-3.0 fills a
profile: at each level a table's own key, and the `'**'` beside that key in its parent (AceDB copies a
`'**'` into every sibling), before `'**'` of the table itself, and `'*'` only for a key with no explicit
default. It returns the default itself, never a copy (a reset copies). This is the table AceDB was built
from, so a derived default is what a fresh profile holds, by construction.

**What wins.** In order:

1. **A member page's share** (`share.own`): its hover line's Reset, as today. Nothing here changes it.
2. **`default`** (SaftUI's field, as today): a hand default, for a value that is not one profile key: a
   `get` over several keys (Theme's Background: a color and `transparent` and `opacity`), the shares'
   source rows, a color with a toggle, the tracker's Key, a CVar, the bags' categories. A hand default
   reads its value from `st.defaults` (`st:DefaultAt`) or the module's shipped table, never from a literal.
   `FN.FontSettingDefault(read, write, 'normal')`, the one that passes a literal, gives way to a derived
   default on the rows that use it (Kinds of text, Window titles). **call**
3. **A mover's Position.** A `position` row whose group path is a registered mover's `configPath` (and so
   the Position of the section a click on that mover opens) takes the mover's own default and Reset:
   `EM:GetDefaultPosition(mover)`, `EM:CanReset(mover)` and `EM:Reset(mover)`. The movers already hold the
   defaults that live in code (the trackers' `st:DefaultTrackerPosition()`, `UF.DefaultUnitConfig`), and
   `EM:Reset` records a step edit mode's Undo takes back. **call** (a field on each Position naming its mover
   was the other way; `configPath` is already declared once and has to resolve, so it is the link.)
4. **A derived default**: the row's `saved` gives keys and `st:DefaultAt` finds a value.
5. **`noReset`** (SaftUI's field, a string): why the row has none. Read by the test, never drawn.

A row with none of these is an error the walk reports (section 7).

**Rows whose `get` reads several keys.** They keep or get a hand `default` (rule 2), its `differs` and
`value` reading each key's `st:DefaultAt`. Today's: Theme's colors and Background, Accent, Options windows,
the Colors tab, the custom color rows with a toggle, All bars' texts, the tracker's rows.

### 2. What "differs" means

`OM.SameValue(row, a, b)` compares what `get` gives with the default, by the row's type. The default is put
in `get`'s terms first (`OM.AsGet(row, default)`): an input's default as text (`tostring`, nil as `''`), a
color table as its r, g, b, a (`{ r, g, b, a }`, `{ 1, 2, 3, 4 }` and a `CreateColor` alike).

| Type | Same when |
| --- | --- |
| toggle, an item's Show | `not a == not b`: nil and false are the same |
| range | both numbers within 1e-4 (a percent range compares the saved fractions) |
| input | as numbers within 1e-4 when both read as numbers (`'200'` and 200), else the same text |
| select | the same key; numbers within 1e-4 when both are numbers |
| multiselect | for every key of its values, `not a[key] == not b[key]` |
| color | r, g and b the same as whole bytes (`floor(x * 255 + 0.5)`); alpha too when the row `hasAlpha`, a missing alpha being 1 |
| font | the same shared key; two typeface tables the same when `st:FontFields` gives the same fields (shadow per axis); a key against a table always differs, as today |
| position | per part: point; rel_point (missing is the point); the frame (nil, `'UIParent'` and UIParent the same) or the element; the offsets the same after `st:RoundToPixel`, as the position `set` stores them |
| keybinding | the same key; nil and `''` the same |
| a table otherwise | deep, numbers within 1e-4 |

A mover's Position differs while `EM:CanReset(mover)` is true (it compares with `EM.SamePosition`, the
same parts with offsets within 1e-4, and also says no for a default whose anchor would loop, and in
combat). A shared setting on a member
page differs from the shared value, as its share already says: kept.

### 3. What a reset does

A click on the icon runs the row's reset with no confirm, then the body's `onChanged(true)`, which draws the
page again (as today).

- **It writes the default through the row's own `set`**, in `get`'s terms, through `OM.Set` (so `validate`
  runs; `confirm` doesn't, as today): an input's as text, a color's r, g, b, a, a font's key or a deep copy
  of a typeface table, a multiselect's each key that differs (`set(info, key, value)`), a position's parts
  that differ in the order point, rel_point, frame or element, x_off, y_off. A table default is always
  written as a deep copy, never the table in `st.defaults`. **call** (writing, not clearing: see the
  anti-goals. AceDB strips a value equal to its default at logout, field by field in a table, so the saved
  file ends as if the setting was never changed.)
- **A mover's Position** resets by `EM:Reset(mover)`: the mover's default through its `setPosition`, its
  `apply`, `PositionChanged`, and one `reset` step in edit mode's history, which Undo takes back.
- **A set that fails validation** stops the reset: the status line shows the message, as for a change
  (`OW:SetStatus`), and the icon stays.
- **A set that asks inside itself** (the tracker's switch and Enemy nameplates' Nameplates ask to reload)
  asks as it does for a change: the reset is a change.
- **Combat.** `/sui` closes in combat and won't open, so no reset runs then. What a module's `set` defers in
  combat (protected frames, `st:QueueAfterCombat`), it defers for a reset too.
- **Disabled rows** show no icon, as today: their value doesn't apply now and they take no input. The icon
  shows again when the row is enabled. **call**
- **A profile switch** needs nothing: nothing is cached, every row reads the profile at call time.
- **The color picker** open on a row that is reset closes writing nothing, as it already does when a
  setting changes under it.

### 4. Rows with no reset

| Row | Why | How it is said |
| --- | --- | --- |
| Execute, description and header rows | no value | by type |
| An item with no Show (`get = false`: the bars' Cooldown items) | no value of its own; its menu's rows have theirs | by type |
| The bags' own types (`bagcategories`, `bagitems`) | a list; the Categories tab has its own resets (section 6) | by type |
| Unit frames' Profile (the pick control) | chooses which unit frame profile is in use | `noReset` |
| Copy from and Manage | execute | by type |
| Test mode (party, raid 10, raid 40, boss; loot rolls, loot feed) | not saved: off at every login | `noReset` |
| Chat's Width and Height | Blizzard's chat frame's size, taken on first load: no default | `noReset` |
| The durability figure's Position | its mover has no default (Blizzard places it until it is moved) | the mover's `noDefaultReason` |
| A typeface's own rows in a font row's menu | a typeface has no default per field; the font row's reset puts the whole value back | built by the row, not in the tree |
| AceDBOptions' Profiles page | Ace's own table | the walk skips it |

**A game setting** gets a reset when the game gives its default: All bars' Cooldown Show gets a hand
`default` reading `C_CVar.GetCVarDefault('countdownForCooldowns')` (guarded by presence; without it,
`noReset`). **call**

### 5. Where the icon sits, and its tooltip

The kit already places the icon on every built-in type with a value (`OB.PlaceDefault`,
`tests/core/options_default_test.lua`): 6 left of what the control draws (`DrawnLeft`, so under Blizzard
left of its art), centred on the row (a multiselect's first band), an item's against its dots, a position
block's 6 after the block on its first line; the label and the hover line give it room. That covers
toggles, ranges, selects, multiselects, inputs, color fields, font rows, position blocks, key bindings and
items, in the window, in an item's menu and in the small dialog, at full and half size (half makes the
rows one size larger; the icon keeps its place by the control) and under Thick, Thin and Blizzard. Two new
places:

- **A titled custom row** (`W.Define`'s `titled`: the bags' rule) with a reset: the icon 6 after its title's
  text, centred on the title's line, the title cut to leave it room.
- **The Categories list's order** (section 6): in the list's footer where Reset all was.

None: the pick control line (Copy from, Profile, Manage), a page's footer control (unused), dialogs.

**The tooltip** stays "Reset", then "<name> goes back to its default: <default>." (an item's name is
"<item>'s Show"). The default is named by type: on or off; a number as its value box writes it, a percent
range's percent; a select's label; a multiselect's ticked labels joined with ", ", or "none"; an input's
text, or "empty"; a color's code, with its opacity when it `hasAlpha`; a font by `st:FontLabel`; a key by
`GetBindingText`, or "Not bound"; a position in words, by `EM.CoordinatesText` ("Top right of the screen:
-320, -275"), with an element's name for a unit frame part. With nothing to name: "<name> goes back to its
default." The words are worked out when the tooltip opens, not when the row is drawn (section 8).

### 6. The section Reset buttons that remain

**The Categories editor's "Reset <name> to default"** goes. Each of what it reset gets its own reset, a hand
`default` reading the shipped entry (`INV:GetDefaultCategory(id)`), through the setter the row already uses:

- Name: the shipped name, `INV:RenameCategory`; a name another category has now fails its validation and
  says so in the status line.
- On: the shipped `enabled`, `INV:SetCategoryEnabled`.
- Show in: per window, the shipped `hide`, `INV:SetCategoryHidden` for each window that differs.
- The rule: the shipped rule (`R.Equal`), `INV:SetCategoryRule` with a copy; the icon by the rule's title
  (section 5).

A category of the player's own has no shipped version, so its rows have `noReset`. Pinned items stay as
they are (the old button kept them too). This also ends the followup about the button overlapping Delete.

**"Reset all"** goes. It has no single per-setting equivalent; its parts each get one, or are already one
action each: **call**

- each shipped category's fields: their resets above;
- the order: a setting of its own (`categories.order`) with its own reset, a `ResetIcon` in the list's
  footer where Reset all was, shown while the shipped categories are not in their shipped order; its reset
  puts them in it, each of the player's own categories staying right after the category it follows now
  (first when it is first), Miscellaneous last (`INV:CategoryOrderDiffers()`, `INV:ResetCategoryOrder()`);
  its tooltip "Order goes back to its default: SaftUI's order, with your own categories where they are.";
- a deleted shipped category: + New category > Restore a default... (as today);
- the player's own categories: Delete, each (as today). Nothing deletes all of them at once any more.

Delete's confirm, which points at "Reset all", points at Restore a default... alone.

### 7. The test that keeps it whole

Modelled on the page walks (`options_desc_test.lua`'s every-option check, `T.check_no_old_names`) and the
source scans (`theme_kinds_test.lua`, `setfont_scan_test.lua`):

- **`tests/lib/reset_walk.lua`** returns `R`. `R.check_page(root, pageKey, opts)` walks a page (item menus
  and pick controls too) and checks:
  1. every value row has a reset source (section 1's list) or a non-empty `noReset`; a failure names the
     page, path, type and name: "Bags.look.titles (font Title font) has no reset: give the group that gives
     its get `saved`, or the row `default` or `noReset`";
  2. on a fresh profile (`opts.fresh ~= false`), no derived or mover row differs;
  3. a round trip for each derived row (`opts.probe ~= false`): a probe value set as the audit set one makes
     it differ, the profile changes only under its saved path, and its reset makes it the same again with
     the default saved (deep, numbers within 1e-4).
- **Every page is walked.** `tests/core/reset_coverage_test.lua` scans every TOC-loaded file
  (`T.saftui_files()`) for `function <M>:GetConfigTable(`, and checks that each module's page is in its
  table of pages, each naming the test file that walks it, and that the file calls `R.check_page` for that
  page (read with a new harness function, `read_test_source(path)`, the test-file twin of
  `read_saftui_source`). A new page with no walk fails, as does a page whose walk was dropped.

### 8. Cost

The kit asks every value row whether it differs on every draw, and again on every `body:Refresh` while a
slider is dragged.

- **Per row:** finding `saved` (the same walk up the path that finds `get`, at most seven groups), one call
  of it, `st:DefaultAt` (at most eight levels, three reads each, on two scratch lists the file keeps, so no
  table per row), one `get` (the widget made one too) and one compare. A few microseconds; a page of 100 rows
  well under a millisecond, which is also the cost per step of a drag.
- **Kept cheap by:** asking `differs` alone when placing the icon (`OM.DefaultDiffers`), and working out the
  default's words only when its tooltip opens (`OM.DefaultState`, as `DefaultTip` already asks it again);
  `saved` returning keys, not a table; no cache, so nothing can go stale across a set, a share or a
  profile switch.
- A test counts it: a draw calls each row's `saved` once and its `get` at most once more than the widget's
  own read, and no row's default words are worked out before its tooltip opens.

### 9. Docs and followups

- `.agents/edit-mode.md`: "A setting's own reset" becomes the rule for every row (the sources and their
  order, `saved`, `noReset`, the mover link, what differs and what a reset writes); `SaftUI's fields` gains
  `saved` and `noReset`; each page paragraph that names its resets says so.
- `.agents/architecture.md`, "Config, defaults and profiles": `st:DefaultAt`, and the rule that a page says
  where its settings are saved.
- `.agents/testing.md`: `reset_walk.lua`, `read_test_source`, the coverage test.
- `docs/design-system/`: decision 50 (below), discrepancy 17 built, `ResetIcon`'s status and its consumer
  (the page says where it is saved), `Row` and `Section`.
- `docs/followups.md`: "A reset on every font row" and the Categories overlap move to Resolved.

Decision 50, for `05-decisions.md`, dated 2026-11-15: **Every setting has a reset.** One rule for every row:
a default from the AceDB defaults by where the setting is saved, a reset icon while it differs, and the
section Reset buttons that were left (the Categories editor's and Reset all) replaced by per-setting
resets. ("Yep that sounds good")

## Phases

1. **The kit** (`saved`, `noReset`, `st:DefaultAt`, the derived default, the mover link, the compares and
   writes, the tooltip words, a titled custom row's icon, the cost split), the walk helper, the coverage
   test (lenient: it lists the pages still to walk), and the docs.
2. **The pages**, in groups whose files don't overlap, each declaring `saved` on its groups, `noReset` on
   its exemptions, and its walk: Global settings; Unit frames; Action bars; Bags with the Categories tab;
   Misc's pages; Chat, Loot, Minimap, Micro menu and Tracker. They can run side by side.
3. **The coverage test made strict**, and the followups and the design system's statuses closed.

## In-game checks

- G1. The bags' Title font: pick another font, the reset shows; click it, Heading comes back and the icon
  goes. (His report.)
- G2. A unit frame element's setting (Player > Health > a size) and a Position (Player's): the icon shows,
  resets, and for the Position, edit mode's Undo puts it back where it was.
- G3. A row in an item's menu (an action bar text's Size on All bars) and a toggle in a quarter cell: the
  icon sits left of the control and the label is cut, never the control, at full and half, under Thick,
  Thin and Blizzard.
- G4. The Categories editor: rename a shipped category, turn it off, change Show in and its rule: each row
  shows its own icon and resets alone; no Reset button; Delete no longer covered.
- G5. The Categories list: drag a shipped category, the order's icon shows in the footer; click it, the
  shipped order comes back with your own categories where they were.
- G6. All bars' Cooldown: untick its Show, the icon shows; click it, the cooldown numbers come back
  (Blizzard's default).
- G7. A profile switch with resets showing: the icons follow the new profile at once.

## Risks

- **R1. A default the `set` can't store.** The player's Power, Castbar and Additional power positions
  default to X 0.5; the position `set` rounds offsets to whole pixels. The compare rounds as the `set` does
  (section 2), so the reset writes the rounded value and the icon goes. The audit's identity check is where
  this showed; the walk's round trip pins it.
- **R2. A `get` that transforms what is saved** (a value that isn't the saved one) would compare a stored
  default with a shown value. The audit found none but R1's, and the walk's round trip fails such a row.
- **R3. A `saved` that names the wrong key** would reset to another setting's default. The walk checks that
  a probe changes the profile only under the row's saved path.
- **R4. Defaults that change while a page is open** (a migration, an import) are read at the next draw.
- **R5. In-flight work** in the same files (the plan lists them): the kit's changes are mostly in a new
  file, and the page tasks each touch one addon.

## What's left to the builder

- The exact `get`/`set` sites on each page that need a `saved` of their own (the walk names every one it
  misses), and the parts of each unit frame and action bar group's path.
- The words of the `noReset` reasons and of the order reset's tooltip, within the meanings above.
- How a position's element is named in the reset tooltip for a unit frame part.
- Where in `optionsshare.lua` the titled custom row's icon hooks in, and how the Categories footer's icon
  is drawn (`W.IconLink` with the `ResetIcon` look, or the kit's own `ResetIcon`).
- Where `st:DefaultAt` keeps its scratch lists.

## Calls made while writing this

1. **Derive, don't declare.** A default comes from `st.defaults` by the row's saved path, not from a
   `default` written on each option.
2. **`saved` returns the keys as multiple returns** and is built by `st.Config.SavedIn` / `SavedAt`.
3. **`saved` is read only from the node that gives the row its `get`.**
4. **The order of sources**: share, then `default`, then a mover's Position, then derived, then `noReset`.
5. **A hand default never states a literal**; `FN.FontSettingDefault`'s rows take the derived default.
6. **A mover's Position resets through edit mode** (`EM:Reset`, an Undo step), linked by its `configPath`.
7. **The compares in section 2**, among them nil and false the same for toggles, offsets compared after
   pixel rounding, a font key against a table always differing.
8. **A reset writes the default through `set`**, never clears the key; tables as deep copies.
9. **Disabled rows show no icon** (as today).
10. **A game setting gets a reset when the game gives a default** (the Cooldown Show, from
    `C_CVar.GetCVarDefault`).
11. **Test mode, the Profile select, Chat's size and the durability figure's place have no reset.**
12. **The Categories editor's fields reset one by one**, against the shipped category; a category of your
    own has none.
13. **Reset all goes**, with the list's order as a setting with its own reset, and no way left to delete all
    of your own categories at once.
14. **A titled custom row can carry a reset**, by its title.
15. **The tooltip's words** for the types that had none (multiselect, input, key, position).
16. **The test**: a walk helper the page tests call, and a coverage scan, with a new harness function to read
    test files.
17. **The cost split**: `differs` alone when drawing, the words only on hover; no cache.
18. **Decision 50** recorded in the design system with his words.

## Questions for the owner

1. **Reset all** (call 13). Without it there is no one-click way to delete all your own bag categories and
   put the shipped ones back as they were; each part has its own reset or action instead. If you use it,
   it can stay as a list action named for what it does ("Start over"), with its confirm, rather than as a
   Reset. Keep it, or let it go?
