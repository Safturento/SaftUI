# SaftUI Options Layout and Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give `/sui` settings three sizes (small, normal, wide), a one-unit Position block, a tooltip on every option, and re-sort every module's page around them. The work includes:
- the settings the 2026-11-09 audit found with no option;
- real boss frame layout;
- Edit mode moving into Global Settings.

**Architecture:**
- **Core first.** The options model (`optionsmodel.lua`) learns a SaftUI `size` field and a SaftUI option type, `position`. The body (`optionsbody.lua`) packs rows into quarters, halves and whole lines. The widgets (`optionswidgets.lua`) draw the Position block. The shared generators (`Config/widgets.lua`) return the new Position option and take `desc` and `size` instead of Ace's `width`.
- **Then each module's table** is rewritten page by page on top of that.
- **Last, Core's reshaping helpers go,** and Edit mode joins Global Settings.

**Tech Stack:** Lua 5.1 WoW addon (Forever 16001 and retail 120000), Ace3 option tables and AceDB. Tests run on Lua 5.1 through lupa: `tests/run`, see `.agents/testing.md`.

**Spec:** `docs/superpowers/specs/2026-11-09-saftui-options-layout-and-pages-design.md`. Mockups:
- `docs/superpowers/specs/assets/2026-11-09-options-position-block-mockup.html`: the Position block, final;
- `docs/superpowers/specs/assets/2026-11-09-options-layout-sizes-mockup.html`: part 1 only, the Experience page and small toggles.

## Global Constraints

- **Saved data:**
  - No saved setting is renamed, moved or reinterpreted. Option tables may change freely, but the AceDB profile keys they read and write may not.
  - The one change in meaning: boss frames now read their layout keys.
- **Clients:** Forever (16001) and retail (120000).
- **Done means** `tests/run` passes and `tests/run --self-check` is clean. Run them before every commit.
- **Repo rules:** read `.agents/taint.md` before touching anything Blizzard. Never write a Lua field onto a Blizzard frame, and never `SetScript` one. `.agents/edit-mode.md`, `.agents/architecture.md` and `.agents/testing.md` apply too.
- **Window geometry:**
  - The window is 1040×700. The body is 774 wide: two 367 columns with a 40 gap (`OB.WIDTH`, `OB.COLUMN_GAP`).
  - A quarter is `(column width − 24) / 2`, with 24 between the two quarters of a half (`OB.QUARTER_GAP = 24`, the approved mockup's pair gap). The dialog's body (two 240 columns) uses the same rule.
- **Sizes:**
  - An option says `size = 'small'` or `size = 'wide'`. No field means normal.
  - Small is honored only for `toggle`, `color`, `execute` and `input`; any other type asking for small is normal.
  - `description` and `position` rows are always wide.
  - Ace's `width` is not read anywhere, and SaftUI's tables carry none when this plan is done (the Profiles page, AceDBOptions', is the only exception).
- **Packing:**
  - A small takes the next quarter, and two smalls fill a half.
  - A normal takes the next whole half. If it would start partway into a half, it skips to the next one.
  - A wide starts a new line and takes all of it.
  - A line is as tall as its tallest cell.
- **Checkbox and swatch placement:** a toggle's checkbox and a color's swatch sit `OB.LABEL_GAP` (10) after the end of their label's text, at every size. Every other control stays at its cell's right edge.
- **Position block:**
  - Parts left to right, 12 apart: THIS [dots], TO [target] (only when the option has a target), AT ITS [dots], OFFSET [X over Y].
  - Each part has a caption above it in Colus at 11px, grey, upper case and centered on the part, with 4 between the caption and the 48 band.
  - Every part is centered on a 48-tall band.
  - A dot square is 48×48. Its nine dots run TOPLEFT, TOP, TOPRIGHT / LEFT, CENTER, RIGHT / BOTTOMLEFT, BOTTOM, BOTTOMRIGHT, drawn 4×4 in #555555. The picked dot is 8×8 in the profile's blue (`colors.button.blue`), and the hovered one is drawn in the text color.
  - OFFSET has X over Y, each label to the left of its box. The boxes are 46 wide and 22 tall, 4 apart. A 14-wide nudge pair is attached flush to each box's right, up over down, the same 22 tall.
  - A nudge moves 1, or 10 with Shift. Enter in a box sets the typed number.
  - The TO part:
    - **`target = 'name'`:** a 120-wide frame name box.
    - **`target = 'select'`:** a 140-wide dropdown on the top row and a 140-wide name box on the bottom row (22 tall, 4 apart). The name box shows only while the dropdown's value is the option's `nameKey`; otherwise the bottom row is empty.
- **Tooltips:** every option apart from groups, headers and descriptions has a `desc`: plain words about what it changes in game.
- **Commit trailer:** every commit message ends with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Line endings:** some files are CRLF. Edit with tools that keep line endings; never use `sed -i` on a CRLF file.

## Review Focus

1. **Offsets saved or defaulted as strings.** `"-6"` and `"0"` are in the unit frame defaults and older profiles. The block shows them as numbers, and nudging from `"-6"` gives `-5`. Test: Task 2 (widget) and Task 3 (generator).
2. **A pooled widget reused in another shape.** An input reused after a small one must not keep the 60-wide box, a label must not keep a previous width, and a Position block reused after a `select` target must not keep its dropdown. Test: Task 1 (small input) and Task 2 (position reuse).
3. **A typed frame name that doesn't exist, or that would anchor a frame to itself or to its own child.** The block shows the validate message in the status line and stores nothing. Test: Task 2 (validate fails, no set) and Task 3 (generator validate).
4. **A unit frame part whose stored element isn't on this unit** (e.g. Raid target's default `Portrait`). The dropdown shows Unit frame, and picking an element from it works. Test: Task 3.
5. **The dialog's narrower body.** Quarters and wides place correctly at a 520-wide body. Test: Task 1.

---

### Task 1: Sizes and packing in the model and the body

**Files:**
- Modify: `SaftUI-Core/Config/optionsmodel.lua` (`Row`, `Feed`, the member tables, the header comment)
- Modify: `SaftUI-Core/Config/optionsbody.lua` (`OB.LayoutRows`, `Body:DrawSections`, `PlaceRow`, `Body:RowCell`, the header comment)
- Modify: `SaftUI-Core/Config/optionswindow.lua`: only if `OW.LayoutRows` or callers need the new placed shape
- Test: `tests/core/options_model_test.lua`, `tests/core/options_window_test.lua`, `tests/core/options_widgets_test.lua`

**Interfaces:**
- **Produces:**
  - Model rows carry `row.size = 'small' | 'normal' | 'wide'`, which replaces `row.width`.
  - `OB.LayoutRows(rows, heightOf) -> placed, height`, where each placed entry is `{ row, col = 1 | 2 | 'full', quarter = 1 | 2 | nil, y }` (`quarter` only for small rows).
  - `OB.QUARTER_GAP = 24`.
  - In the model, a row of type `position` sits in its own section, titled with the row's name, and the rows after it continue in a new untitled section.
  - `OB.SMALL_INPUT_WIDTH = 60`: a small input's box width, set every time a cell is drawn.

- [ ] **Step 1: Write the failing tests**

In `tests/core/options_window_test.lua`, replace the `LayoutRows: normal rows alternate columns…` test with:

```lua
test('LayoutRows: smalls take quarters, two to a half; a normal takes the next whole half; a wide its own line', function()
	local function r(key, size) return { key = key, size = size } end
	local placed, height = OW.LayoutRows({
		r('a'), r('b'),
		r('c', 'small'), r('d', 'small'), r('e'),
		r('f', 'small'), r('g'),
		r('h', 'small'), r('i', 'wide'),
		r('j'), r('k', 'small'), r('l', 'small'), r('m', 'small'),
	})
	local function at(i) local p = placed[i]; return p.col .. '/' .. tostring(p.quarter) .. '@' .. p.y end
	eq(at(1), '1/nil@0'); eq(at(2), '2/nil@0')
	eq(at(3), '1/1@34'); eq(at(4), '1/2@34'); eq(at(5), '2/nil@34')
	eq(at(6), '1/1@68'); eq(at(7), '2/nil@68')          -- a normal after a lone small skips to the next half
	eq(at(8), '1/1@102'); eq(at(9), 'full/nil@136')    -- a wide starts its own line
	eq(at(10), '1/nil@170'); eq(at(11), '2/1@170'); eq(at(12), '2/2@170'); eq(at(13), '1/1@204')
	eq(height, 238)
end)
```

Keep the existing heightOf and empty-rows checks, rewritten to use `size`.

In `tests/core/options_model_test.lua`, add the following tests. Use the file's existing helpers for building a page and its rows.

```lua
test('rows: size is the option\'s small or wide; Ace width is ignored; small only for toggle, color, execute, input', function()
	-- one page with these options, read back through OM.BuildView:
	--   t  = toggle size 'small'      -> 'small'
	--   c  = color  size 'small'      -> 'small'
	--   e  = execute size 'small'     -> 'small'
	--   i  = input  size 'small'      -> 'small'
	--   r  = range  size 'small'      -> 'normal'
	--   s  = select size 'wide'       -> 'wide'
	--   w  = toggle width 'full'      -> 'normal'
	--   h  = toggle size 'huge'       -> 'normal'
	--   d  = description              -> 'wide'
	--   p  = position (type 'position', get/set given) -> 'wide'
end)

test('a position row gets a section of its own, titled with its name; rows after it continue untitled', function()
	-- page args: a (toggle, order 1), pos (position named 'Position', order 2), b (toggle, order 3)
	-- sections: { rows = {a} }, { title = 'Position', rows = {pos} }, { title = nil, rows = {b} }
end)
```

Write the bodies against the comments above. Each expected value is one `eq`.

In `tests/core/options_widgets_test.lua`, or `options_window_test.lua` if the body is easier to build there, add:

```lua
test('a toggle and a color sit 10 past the end of their label, at normal and small size', function()
	-- draw a body (OB.New, 774 wide) with a normal toggle, a small toggle and a small color;
	-- for each cell: the widget frame's first point is LEFT to the label's RIGHT with x offset 10,
	-- and the label's width is its text width (GetStringWidth), not the cell's leftover width.
end)

test('a small input draws a 60-wide box; the same widget reused for a normal input is 170 again', function()
	-- draw a body with one small input, Release it, draw one normal input:
	-- eq(first box width, 60); check(reused widget == first widget); eq(second box width, 170)
end)

test('quarter cells sit at x = column x + (quarter - 1) * (quarter width + 24), in the window and a 520 dialog body', function()
	-- OB.New(content, root, nil, 774): column width 367, quarter width 171.5:
	--   small 1 at x 0, small 2 at x 195.5, normal after them at x 407
	-- OB.New(content, root, nil, 520): column width 240, quarter width 108:
	--   small 1 at x 0, small 2 at x 132, a small in column 2 at x 280
	-- and each small cell's frame width is the quarter width
end)
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/core/options_window_test.lua tests/core/options_model_test.lua tests/core/options_widgets_test.lua`

Expected: FAIL. The new LayoutRows test fails on `quarter`/`size`, the model's size test fails on `row.size` being nil, and the body tests fail.

- [ ] **Step 3: Implement**
- **The model:**
  - `Row` sets `size` from the option's `size` member. Add `size`, `target` and `nameKey` to `stringIsLiteral`.
  - Apply the Global Constraints' size rules. Drop `width` from rows and from the header comment's row contract.
  - `Feed` gives a `position` row its own titled section, as specified in Interfaces.
- **`OB.LayoutRows`** packs by the Global Constraints' rules, with a cursor counted in quarters (0 to 3).
- **`Body:DrawSections`** turns `col`/`quarter` into x and width:
  - half: x = `(col − 1) × (columnWidth + COLUMN_GAP)`, width = `columnWidth`;
  - quarter: within that half, x + `(quarter − 1) × (quarterWidth + QUARTER_GAP)`, width = `quarterWidth`;
  - full: x 0, the body's width.
- **`PlaceRow`** applies the Global Constraints' checkbox and swatch placement rule for `toggle` and `color`. The label's width is `min(label:GetStringWidth(), width − widget width − LABEL_GAP)`.
- **`Body:RowCell`** sets an `input` widget's frame width to `OB.SMALL_INPUT_WIDTH` for small rows, and to `W.WIDTH.input` otherwise, on every draw.
- **Search results** (`DrawResults`) ignore `size`: each result takes a half.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all files pass. Fix any other test that read `row.width` or the old placed shape, so it uses `size` and `col`/`quarter`.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Core/Config/optionsmodel.lua SaftUI-Core/Config/optionsbody.lua SaftUI-Core/Config/optionswindow.lua tests/core/
git commit -m "config: settings are small, normal or wide; smalls pack two to a half; checkboxes and swatches sit by their label"
```

---

### Task 2: The Position block widget

**Files:**
- Modify: `SaftUI-Core/Config/optionswidgets.lua`: a `position` type (builder plus `define`), `W.WIDTH.position = 0`
- Modify: `SaftUI-Core/Config/optionsbody.lua`:
  - a position cell is wide;
  - its height is the widget's height + 12;
  - the label is hidden, since the section title says Position;
  - the row's `desc` tooltip shows on hover over the block;
  - a `caption` font: the profile's title face (Colus) at 11.
- Test: `tests/core/options_widgets_test.lua`

**Interfaces:**
- **Consumes:** Task 1's wide rows and the position section. `Base:Commit(...)` (validate, then confirm, then set, then `onChanged`). `W.OpenList(owner, entries, selected, onPick)` and `OM.Values(root, row)` for the dropdown.
- **Produces:** the `position` option contract, which Task 3's generators return:

```lua
{
	type = 'position', name = 'Position', order = n, desc = '...',
	target = 'name' | 'select' | nil,  -- the TO part; nil: none
	nameKey = '__global',              -- target 'select' only: the dropdown value that shows the name box
	values = ..., sorting = ...,       -- target 'select' only: the dropdown's choices, as a select's
	get = function(info, part) end,    -- part: 'point', 'rel_point', 'x_off', 'y_off', 'frame', 'relative_to'
	set = function(info, part, value) end,
	validate = function(info, part, value) end, -- optional: true, or a message
}
```

- **Widget fields the tests drive:**
  - `w.this[1..9]` and `w.at[1..9]`: dot buttons, in the Global Constraints' order;
  - `w.name`: the name box (an EditBox), or nil for no target;
  - `w.select`: the dropdown button, for `target = 'select'` only;
  - `w.x`, `w.y`: the offset EditBoxes;
  - `w.xUp`, `w.xDown`, `w.yUp`, `w.yDown`: the nudge buttons;
  - `w.captions`: the shown caption font strings, left to right.

- [ ] **Step 1: Write the failing tests** (`tests/core/options_widgets_test.lua`, with the file's `bind`/`click`/`opt` helpers)

```lua
-- A position option over a plain table; sets are recorded.
local function position_option(fields, store)
	store = store or { point = 'TOPRIGHT', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -8, frame = 'Minimap' }
	local sets = {}
	local option = opt('position', 'Position', {
		get = function(info, part) return store[part] end,
		set = function(info, part, value) sets[#sets + 1] = part .. '=' .. tostring(value); store[part] = value end,
	})
	for k, v in pairs(fields or {}) do option[k] = v end
	return option, sets, store
end

test('position: captions read THIS, TO, AT ITS, OFFSET with a name target, and THIS, AT ITS, OFFSET without one', function() end)
test('position: the picked dots show the stored points; clicking a dot sets that point', function()
	-- target 'name'; w.this[3] (TOPRIGHT) and w.at[9] (BOTTOMRIGHT) are the picked ones;
	-- click w.this[2] -> sets ends with 'point=TOP'; click w.at[5] -> 'rel_point=CENTER'
end)
test('position: X and Y show the stored offsets, strings included; Enter sets the typed number', function()
	-- store.x_off = '-6' (a string): eq(w.x:GetText(), '-6'); type '12' + Enter in w.y -> 'y_off=12'
end)
test('position: nudges move 1, or 10 with Shift, from a string offset too', function()
	-- store.x_off = '-6': click w.xUp -> 'x_off=-5'; stub.shift_down = true; click w.yDown -> 'y_off=-18'
end)
test('position: a name typed and Entered sets frame; a failed validate sets nothing and reports its message', function()
	-- target 'name', validate returns "Frame doesn't exist" for 'Nope':
	-- type 'Nope' + Enter -> no set, told.ok == false, told.err == "Frame doesn't exist"
	-- type 'UIParent' + Enter -> 'frame=UIParent'
end)
test('position: a select target shows the dropdown, and the name box only for nameKey', function()
	-- target 'select', nameKey '__global', values { __unitframe = 'Unit frame', Health = 'Health', __global = 'Global frame' },
	-- store.relative_to = 'Health': w.select shows 'Health', w.name hidden;
	-- open the list and pick 'Global frame' -> 'relative_to=__global'; after Refresh w.name shown
end)
test('position: a block reused after a select target has no dropdown, and one reused without a target has no TO part', function()
	-- bind select-target, Release, bind name-target (same widget from the pool): w.select hidden, w.name shown;
	-- Release, bind no-target: w.name hidden and not in w.captions
end)
test('position: disabled dims the block and ignores clicks and nudges', function() end)
```

Fill in each body against its comment. The values in the comments are the assertions.

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/core/options_widgets_test.lua`

Expected: FAIL, with no `position` widget type.

- [ ] **Step 3: Implement the `position` widget** in `optionswidgets.lua`, to the Global Constraints' geometry
- **Commits:** every user change goes through `self:Commit(part, value)`. Point and relative point are the dot's key. X and Y are numbers (`tonumber`), and text that isn't a number reports `'X must be a number'` / `'Y must be a number'` through `onChanged(false, msg)` without a set. The frame is the trimmed text. `relative_to` is the picked key.
- **Refresh:**
  - reads every part through `self:Value(part)` (`OM.Get(root, row, part)`);
  - shows `tonumber(value) or 0` in the offset boxes;
  - re-lays out the parts for `target`/`nameKey`;
  - resets everything a previous bind could have left: captions shown, TO part shown or hidden, name box shown or hidden, widths.
- **Keys:** Esc in a box reverts it from the stored value.
- **Disabled:** alpha 0.4, and the whole block ignores input.

In `optionsbody.lua`, the position cell comes from `Body:RowCell`, as described under Files.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Core/Config/optionswidgets.lua SaftUI-Core/Config/optionsbody.lua tests/core/options_widgets_test.lua
git commit -m "config: the Position block: point pickers, the target, and X over Y with nudges"
```

---

### Task 3: Generators, every call site, and the test helpers

**Files:**
- Modify: `SaftUI-Core/Config/widgets.lua`: every generator
- Modify: every caller of the generators in `SaftUI-*/`; find them with `grep -rn "generators\." SaftUI-* --include=*.lua | grep -v Libraries`
- Modify: `SaftUI-Core/Media/fonts.lua` and `SaftUI-Core/EditMode/settings.lua`: Core's two pages get a `desc` on every option and lose `width`
- Create: `tests/core/options_walk.lua`, a helper shared by tests (no `_test` suffix)
- Create: `tests/core/options_desc_test.lua`
- Create: `tests/core/config_generators_test.lua`
- Modify: `tests/core/options_validate_test.lua`, `tests/unitframes/config_test.lua`: strip SaftUI's fields before Ace validates

**Interfaces:**
- **Consumes:** Task 2's `position` option contract.
- **Produces:**
  - **Generator signatures** (desc and size optional):
    - `generators.toggle(order, name, desc, size)`
    - `generators.enable(order, desc)`
    - `generators.range(order, name, min, max, step, desc, size)`
    - `generators.alpha(order, desc)`
    - `generators.height(order, desc)`, `generators.width(order, desc)`
    - `generators.template(order, desc)`, `generators.font(order, desc)`
  - **`generators.position(order, global_frame, get, set, target, desc)`** returns a `position` option: `target = global_frame and 'name' or nil`. Its desc defaults to `"Where this sits: which of its points goes to which point of what it's attached to, then moved by X and Y."`
  - **`generators.uf_element_position(order, get, set, target, desc)`** returns `target = 'select'`, `nameKey = '__global'`, and the same values and sorting as today's `relative_to` select.
  - **Test helper** `tests/core/options_walk.lua` defines:
    - `each_option(tree, fn)`: calls `fn(option, path)` for every option table under `tree`, groups included, with `path` the key list;
    - `ace_ready(tree)`: a deep copy without SaftUI's fields (`category`, `size`, `target`, `nameKey`) and without `type = 'position'` options, for AceConfigRegistry.
  - **`DESC_PENDING` in `tests/core/options_desc_test.lua`:** a set of page keys whose descriptions aren't written yet. Tasks 4, 5 and 10 remove their pages from it.

- [ ] **Step 1: Write the failing tests**

`tests/core/config_generators_test.lua`, over a plain table `store` and a stand-in target frame:

```lua
test('position generator: one position option reading and writing the same keys', function()
	-- local o = generators.position(9, true, store)   (store = { point = 'TOPLEFT', rel_point = 'TOPRIGHT', x_off = '-6', y_off = 0, frame = 'UIParent' })
	-- eq(o.type, 'position'); eq(o.target, 'name'); eq(o.order, 9); check(o.desc ~= nil)
	-- eq(o.get(info, 'x_off'), -6)            -- a string offset reads as a number
	-- o.set(info, 'x_off', 3.4) -> store.x_off is a number, rounded with st:RoundToPixel
	-- o.set(info, 'point', 'TOP') -> store.point == 'TOP'
	-- generators.position(1, false, store).target == nil
end)
test('position generator: frame validate rejects a missing frame and an anchor loop, accepts a good name', function()
	-- o.validate(info, 'frame', 'NoSuchFrame') == "Frame doesn't exist" (target nil)
	-- with target = a frame F and a child C of F: o.validate(info, 'frame', 'C_name') is st:ValidateAnchor's message
	-- o.validate(info, 'frame', 'UIParent') == true; o.validate(info, 'point', 'TOP') == true
end)
test('unit frame position: relative_to reads the element, the global frame or the unit frame, and clears with false', function()
	-- uf version over a stand-in unit frame with elements Health and Power, target = its Power:
	-- get 'relative_to' with element 'Health' -> 'Health'; with element 'Portrait' (not on this unit) and no frame -> '__unitframe'
	-- set 'relative_to' '__global' -> element false, frame 'UIParent'; set '__unitframe' -> both false; set 'Health' -> frame false, element 'Health'
	-- o.nameKey == '__global'; OM.Values over it lists Unit frame first and Global frame last
end)
test('the other generators take desc and size, and carry no Ace width', function()
	-- generators.range(1, 'Spacing', 0, 30, 1, 'Gap between bars.', 'small'): desc and size set, width nil
	-- generators.toggle(1, 'Enable', 'Shows it.'): width nil
end)
```

`tests/core/options_desc_test.lua` builds the tree the way `options_validate_test.lua` does, with the same files loaded:

```lua
local DESC_PENDING = { Experience = true, Minimap = true, MicroMenu = true }
test('every option on a finished page has a tooltip and no Ace width', function()
	-- for each page key in the tree except 'profile' and DESC_PENDING's:
	-- each_option: options whose type isn't group/header/description have desc (non-empty string or a function),
	-- and no option has a `width` field. Message names the page and path.
end)
test('the check is real: an option without desc fails it', function() end)
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/core/config_generators_test.lua tests/core/options_desc_test.lua`

Expected: FAIL. The generators still return a group with Ace widths, and Fonts and EditMode options have no desc.

- [ ] **Step 3: Implement**
- **The generators** take the signatures in Interfaces. The position generators keep today's behavior on the same profile keys: `st:ValidateAnchor`, Global frame starting at `UIParent`, and `false`, never `nil`, to clear `element`/`frame`.
- **Every call site:**
  - drop the positional `width` arguments and every `width =` field on SaftUI's options;
  - where a `position` group sat beside its frame's `general` group, move the position option into that `general` group's args, last (where `MergePositionIntoGeneral` puts it today), so edit mode's `configPath`s still land on the same tab;
  - code that reached into the old group's `args` (e.g. `options.args.frame.name = …`) is replaced by the new option's fields.
- **Fonts and EditMode** options get a `desc` each.
- **The Ace validation tests** (`options_validate_test.lua`, the unit frames' in `config_test.lua`) validate `ace_ready(tree)` in place of the shallow `category` strip. Keep their "the check is real" cases.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Core/ SaftUI-*/ tests/
git commit -m "config: generators make the Position option and take desc and size; Ace widths dropped; desc check for finished pages"
```

---

### Task 4: Misc pages: Experience, Tooltip, Totem bar, Buffs, Swing timer, and a Skinning page

**Files:**
- Modify: `SaftUI-Misc/experience.lua`, `tooltipposition.lua` (and `tooltip.lua` if its options live there), `totembar.lua`
- Modify: `SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua`, `SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua`
- Create or modify: the Skinning page's `GetConfigTable`. Skinning is a module of its own or a child of Misc; check `SaftUI-Misc/config.lua` and `SaftUI-Core/Config/config.lua:212` for how Config collects pages.
- Test: `tests/misc/experience_test.lua`, `tests/core/options_desc_test.lua` (remove `Experience` from `DESC_PENDING`)

**Interfaces:**
- **Consumes:** Task 1's sizes, Task 2's block, Task 3's generators.
- **Produces:** nothing that other tasks use.

- [ ] **Step 1: Write the failing test** (`tests/misc/experience_test.lua`, building the Experience page through `OM.BuildView` and `OB.LayoutRows`)

```lua
test('the Experience page reads Template | Spacing, Height | Width, the two colors | Rested bar alpha, then Position', function()
	-- General's rows in order, as key:size, then where LayoutRows puts them:
	-- template:normal 1, spacing:normal 2, height:normal 1, width:normal 2,
	-- normal_color:small 1/1, rested_color:small 1/2, rest_alpha:normal 2,
	-- then a section titled 'Position' with the position row (wide)
end)
```

Also remove `Experience` from `DESC_PENDING`.

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/misc/experience_test.lua tests/core/options_desc_test.lua`

Expected: FAIL on the order and sizes, and on missing descs.

- [ ] **Step 3: Implement**
- **Every page in Files:**
  - follows the layout rules, with a `desc` on every option;
  - has Position as its last section (Task 3 put it in place);
  - declares `childGroups` itself wherever it wants tabs, since Task 10 removes `UseTabsForInnermostSections`.
- **Experience** follows the test's order exactly.
- **New options:**
  - **Tooltip:** `tooltip.template` (`generators.template`) and `tooltip.font` (`generators.font`), applied the way the tooltip skin reads them today.
  - **Totem bar:** a color option per key of `totembar.colors`.
  - **Skinning:** a page with `skinning.font` and `skinning.template`, category `Info`.
- **Buffs:** the buff frames' hand-built text positions become `generators.position(order, false, get, set)` over the same keys.
- **Anything that turns out not to work:** if a setting on this list turns out not to be read, or breaks when set, leave it out and add a line to the audit entry in `docs/followups.md`.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Misc/ tests/ docs/followups.md
git commit -m "misc: Experience, Tooltip, Totem bar, Buffs and Swing timer pages re-sorted with tooltips; Skinning page; missing options"
```

---

### Task 5: Bags, Chat, Loot, Minimap and Micro menu pages

**Files:**
- Modify: `SaftUI-Bags/options.lua`, `SaftUI-Chat/options.lua`, `SaftUI-Loot/options.lua`, `SaftUI-Minimap/config.lua`, `SaftUI-Minimap/micromenu.lua`, plus wherever a new option's setting is applied
- Test: `tests/core/options_desc_test.lua` (remove `Minimap` and `MicroMenu` from `DESC_PENDING`); `tests/bags/` for the new bag options' get/set

**Interfaces:**
- **Consumes:** Tasks 1 to 3.

- [ ] **Step 1: Write the failing tests**

Remove `Minimap` and `MicroMenu` from `DESC_PENDING`. In `tests/bags/`, with the existing container helpers, add:

```lua
test('the bag options read and write their profile keys', function()
	-- for each of inventory.enable, template, padding, categoryTitleHeight, scrollSpeed, autorepair,
	-- autovendor, combinedBank, inverted, fonts.titles, fonts.icons:
	-- the option exists on the Bags page, its get returns the profile value, its set writes it
	-- (build the page the way the bag tests build their world; if the page can't build without Blizzard
	-- frames, test the option table the page function returns for a stand-in container)
end)
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/core/options_desc_test.lua tests/bags/`

Expected: FAIL.

- [ ] **Step 3: Implement**
- **Every page in Files:** follows the layout rules, with a `desc` on every option, Position as its last section, and `childGroups` declared where it wants tabs.
- **Loot → Rolls → Test mode** is a small toggle, so its checkbox sits by its label (the user's example).
- **New options:**
  - **Bags:** the eleven settings in the test, each applied the way the code reads it today. A setting that needs a `/reload` says so in its desc.
  - **Chat:** `chat.linespacing`.
- **Anything that turns out not to work:** leave it out and note it in `docs/followups.md`, as in Task 4.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Bags/ SaftUI-Chat/ SaftUI-Loot/ SaftUI-Minimap/ tests/ docs/followups.md
git commit -m "bags, chat, loot, minimap, micro menu: pages re-sorted with tooltips; missing bag and chat options"
```

---

### Task 6: Action bars page, its Text tab and the picker label

**Files:**
- Modify: `SaftUI-ActionBars/options.lua`
- Modify: `SaftUI-Core/Config/optionsmodel.lua` and `optionswindow.lua`: the picker label
- Test: `tests/core/options_window_test.lua`

**Interfaces:**
- **Consumes:** Tasks 1 to 3.
- **Produces:** a page-level field, `pickerLabel`. On a page with `childGroups = 'select'`, the picker's label is `pickerLabel` when set, else the page's name. Add `pickerLabel` to `stringIsLiteral` and to `ace_ready`'s stripped fields. Task 8 sets it to `'Unit'`.

- [ ] **Step 1: Write the failing test** (`tests/core/options_window_test.lua`)

```lua
test('the picker is labelled with the page\'s pickerLabel, else its name', function()
	-- a select page with pickerLabel = 'Bar': the drawn picker label reads 'Bar';
	-- the same page without it reads the page name
end)
```

- [ ] **Step 2: Run it and see it fail**

Run: `tests/run tests/core/options_window_test.lua`

Expected: FAIL.

- [ ] **Step 3: Implement**
- **The picker label:** `pickerLabel` in the model and the window, as specified in Interfaces.
- **The Action bars page:**
  - sets `pickerLabel = 'Bar'`;
  - follows the layout rules, with a `desc` on every option;
  - adds `actionbars.template` (`generators.template`), applied as the bars read it today;
  - converts the Text tab's hotkey, count and macro positions to `generators.position(order, false, get, set)` over the same `text[kind]` keys. Their −50 to 50 sliders become the block's boxes.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-ActionBars/options.lua SaftUI-Core/Config/ tests/
git commit -m "actionbars: page re-sorted with tooltips, template option, text positions as Position blocks; pickers take a label"
```

---

### Task 7: Boss frames laid out like party and raid

**Files:**
- Modify: `SaftUI-Unitframes/groups.lua`: expose the layout math
- Modify: `SaftUI-Unitframes/unitframes.lua`: `UF:PlaceUnitFrame`, `UF:PlaceHolder`
- Modify: `SaftUI-Unitframes/config/units/boss.lua`: `growthDirection = 'TOP'`, which is "Down" in `GROWTH_DIRECTIONS`
- Test: `tests/unitframes/boss_layout_test.lua`

**Interfaces:**
- **Produces:**
  - `UF.GetGroupLayout(config) -> layout`: today's local `GetLayout`.
  - `UF.GetGroupLayoutSize(layout, count) -> width, height, unitsPerColumn, numColumns, shown`: today's `GetLayoutSize`.
  - `UF.GroupAnchor(index, frames, container, layout, unitsPerColumn, numColumns) -> { {point, relativeTo, relativePoint, x, y}, ... }`: the points `ArrangeLikeHeader` sets for `frames[index]`.
  - `ArrangeLikeHeader` becomes `ClearAllPoints` plus `SetPoint` for each entry of `UF.GroupAnchor`.

- [ ] **Step 1: Write the failing tests** (`tests/unitframes/boss_layout_test.lua`, loading `groups.lua` the way existing unit frame tests load what they need)

```lua
test('GroupAnchor: the default boss layout hangs each frame 41 below the one before it', function()
	-- layout = UF.GetGroupLayout({ growthDirection = 'TOP', spacing = 41, unitsPerColumn = 5, maxColumns = 1, width = 200, height = 30 })
	-- GroupAnchor(1, ...) == { {'TOP', container, 'TOP', 0, 0} }
	-- GroupAnchor(2, ...) == { {'TOP', frames[1], 'BOTTOM', 0, -41} }
end)
test('GroupAnchor: two columns of three, growing right, start each column at the first of the last', function()
	-- unitsPerColumn = 3, maxColumns = 2, initialAnchor = 'LEFT', columnSpacing = 10:
	-- GroupAnchor(4) == { {'LEFT', frames[1], 'RIGHT', 10, 0} }
end)
test('the boss holder covers the whole layout: five in a column by default, two columns when set', function()
	-- GetGroupLayoutSize(default layout, 5): 200 x (5*30 + 4*41)
	-- unitsPerColumn 3, maxColumns 2, columnSpacing 10, growing right: 410 x (3*30 + 2*41)
end)
test("boss's default growth is a Layout dropdown key", function()
	-- the boss defaults' growthDirection is a key of the Growth dropdown's values (TOP)
end)
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/unitframes/boss_layout_test.lua`

Expected: FAIL, with no `UF.GroupAnchor`.

- [ ] **Step 3: Implement**
- **`UF:PlaceUnitFrame`,** for a boss or arena frame (`frame.ID`), clears its points and sets `UF.GroupAnchor(frame.ID, self.units[frame.base_unit], holder, UF.GetGroupLayout(config), …)`. That's the column length and count from `UF.GetGroupLayoutSize(layout, #self.units[frame.base_unit])`.
- **`UF:PlaceHolder`** sizes the holder to `UF.GetGroupLayoutSize`.
- **Arena** shares the path. With no layout keys of its own, `GetGroupLayout`'s fallbacks keep it one column growing down with its `spacing`, as today.
- **Combat:** both functions still run only out of combat, as today. Read `.agents/taint.md` rule 6.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/ tests/unitframes/boss_layout_test.lua
git commit -m "unitframes: boss frames laid out by growth, columns and spacing, sharing the party and raid layout math"
```

---

### Task 8: Unit frames page, unit level

**Files:**
- Modify: `SaftUI-Unitframes/config/config.lua`: unit General, Layout, range alpha, picker label, element positions
- Test: `tests/unitframes/config_test.lua`

**Interfaces:**
- **Consumes:** Task 6's `pickerLabel`, Task 7's boss layout, and Task 3's `uf_element_position` and `options_walk.lua`.

- [ ] **Step 1: Write the failing tests** (`tests/unitframes/config_test.lua`)

```lua
test("the unit frames' page: picker labelled Unit; boss has Layout without test mode; range alpha on group units", function()
	-- root Unitframes page: pickerLabel == 'Unit'
	-- boss General has a Layout section with growthDirection, spacing, unitsPerColumn, initialAnchor, columnSpacing, maxColumns,
	--   and no test_mode or showPlayer
	-- each unit with range_alpha in its defaults has inside and outside options (0 to 1) that read and write range_alpha
end)
test('every unit-level option has a tooltip and no Ace width', function()
	-- each_option over the unit frames' table built here, skipping the element tabs (Task 9's):
	-- desc on every non-group option, no `width`
end)
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/unitframes/config_test.lua`

Expected: FAIL.

- [ ] **Step 3: Implement**
- `pickerLabel = 'Unit'`.
- **The Layout group** goes to boss, without `test_mode` and `showPlayer`.
- **Range alpha:** `range_alpha.inside`/`.outside` options, using `generators.alpha` with descs.
- **Unit-level options** follow the layout rules, with a `desc` each.
- **The Profile group's buttons** are small executes.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/config/ tests/unitframes/config_test.lua
git commit -m "unitframes: unit options re-sorted with tooltips; picker labelled Unit; boss Layout; range alpha"
```

---

### Task 9: Unit frame element tabs, their missing options, and defaults that block them

**Files:**
- Modify: `SaftUI-Unitframes/elements/*.lua`: the element option tables
- Modify: `SaftUI-Unitframes/config/default.lua`, `config/units/focus.lua`: the default fixes
- Test: `tests/unitframes/config_test.lua`, `tests/unitframes/bar_colors_test.lua`

**Interfaces:**
- **Consumes:** Tasks 1 to 3 and Task 8's test setup.

- [ ] **Step 1: Write the failing tests**

In `tests/unitframes/config_test.lua`:

```lua
test('every element tab has tooltips, no Ace width, and its missing options', function()
	-- each_option over every element tab: desc on every non-group option, no `width`
	-- options exist (and read/write their keys) for: alpha on every element whose defaults have it;
	-- health.texture, health.text.boss_percent (boss); Health's colorTapping, colorDisconnected, colorHealth,
	-- colorClass, colorClassNPC, colorClassPet, colorReaction, colorSmooth; Power's colorTapping, colorDisconnected,
	-- colorPower, colorClass, colorClassNPC, colorClassPet, colorReaction; colorCustom and customColor on Health,
	-- Power and Additional power; name.show_classification, name.colorClass; the indicators' template
	-- every element position is a 'position' option (target 'select', or nil for aura count and timer spots)
end)
```

In `tests/unitframes/bar_colors_test.lua`:

```lua
test('defaults that block their options are fixed', function()
	-- additional power: colorPower == true
	-- focus castbar colors.normal reads (.5, .9, .7) through its GetRGB/UnpackColor path
	-- health.text.deficit has defaults on every unit (enable false where it was missing)
end)
```

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/unitframes/`

Expected: FAIL.

- [ ] **Step 3: Implement**
- **Every element tab** follows the layout rules, with a `desc` on every option. The color toggles are smalls.
- **The missing options** in the test, each applied the way the element code reads it today.
- **The default fixes** in the test.
- **Anything that turns out not to work:** a listed setting that isn't read, or breaks when set, is left out and noted in `docs/followups.md`; the test lists only what was added.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run`

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Unitframes/ tests/unitframes/ docs/followups.md
git commit -m "unitframes: element tabs re-sorted with tooltips; color toggles, alpha, texture and template options; blocking defaults fixed"
```

---

### Task 10: Edit mode joins Global Settings, the reshaping goes, and the docs

**Files:**
- Modify: `SaftUI-Core/Config/config.lua`: remove `MergePositionIntoGeneral`, `UseTabsForInnermostSections` and their helpers; build the Global Settings page with Fonts and Edit mode tabs
- Modify: `SaftUI-Core/EditMode/settings.lua`: its General group becomes an inline section of its tab
- Modify: `.agents/edit-mode.md`, `.agents/testing.md`, `README.md` (Usage), `docs/followups.md`
- Test: `tests/core/options_window_test.lua`, `tests/core/options_validate_test.lua`, `tests/core/options_desc_test.lua`

**Interfaces:**
- **Consumes:** every earlier task.
- **Produces:**
  - The tree has no `EditMode` page.
  - Page `Fonts`, shown as Global Settings, is `{ type = 'group', childGroups = 'tab', args = { fonts = <Fonts' table>, editmode = <Edit mode's table> } }`.

- [ ] **Step 1: Write the failing tests**

In `tests/core/options_window_test.lua`:

```lua
test('Global Settings has Fonts and Edit mode tabs, and the sidebar has no Other group', function()
	-- OW.SidebarEntries over the built tree: no entry in category 'Other'; no page 'EditMode'
	-- the Global Settings page's tabs are Fonts then Edit mode; setting Show grid there changes EM:GetSettings().grid
end)
```

Then:
- update `options_validate_test.lua`'s expected page list (no `EditMode`);
- `DESC_PENDING` should now be empty: delete it, so every page the test builds is checked.

- [ ] **Step 2: Run them and see them fail**

Run: `tests/run tests/core/`

Expected: FAIL.

- [ ] **Step 3: Implement**
- **Code:** remove the two reshaping helpers, and nest Fonts and Edit mode as tabs of the Global Settings page.
- **`.agents/edit-mode.md`:**
  - the size rules;
  - the `position` option contract and the generator signatures (Task 2 and Task 3 Interfaces);
  - `pickerLabel`;
  - that SaftUI's tables carry no Ace `width`;
  - the Global Settings tabs;
  - bump `last_updated`.
- **`.agents/testing.md`:** the new test files and helper.
- **`README.md` Usage:**
  - the `/sui` line mentions hovering for tooltips, as now;
  - say Edit mode's grid and snap settings are under Global Settings.
- **`docs/followups.md`,** the audit entry ("Settings with no /sui option…"):
  - mark the per-module options this project added;
  - keep Core's (project 3) and `loot.popup.*` open.

  In the 2026-11-07 unit frame defaults entry, mark the additional power color and focus castbar defaults fixed.

- [ ] **Step 4: Run them and see them pass**

Run: `tests/run` and `tests/run --self-check`

Expected: all pass, and the self-check is clean.

- [ ] **Step 5: Commit**

```bash
git add SaftUI-Core/ .agents/ README.md docs/followups.md tests/
git commit -m "config: Edit mode settings under Global Settings; the tree's reshaping helpers removed; docs for sizes and the Position option"
```
