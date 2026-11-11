-- The outline rule editor (SaftUI-Bags/ruleeditor.lua): the bagrule widget
-- type, bound to a synthetic option over a stored rule. Its rows, lines,
-- badges and connectors, + Block and + Group, NOT, the X, the badge, each
-- block type's fields, the text boxes, dragging a row, the Item is one of
-- block's ID box and cursor drop, SetHighlight, and rule data this version
-- can't read.
--
-- Real: the options window's model, widgets and body (optionsmodel.lua,
-- optionswidgets.lua, optionsbody.lua) on Core's real config.lua
-- (core/config_helpers.lua), as tests/core/options_widgets_test.lua loads
-- them; SaftUI-Bags' config.lua, inventory.lua (the module), itemclasses.lua,
-- rules.lua and ruleeditor.lua. Made by hand: C_Item's GetItemClassInfo and
-- GetItemSubClassInfo, from Forever's tables (fixtures/item_classes.lua), and
-- GetItemNameByID. The mouse is played by firing the frames' scripts and
-- placing the cursor (stub.cursor_x / cursor_y); OnUpdate never runs here,
-- which a drag's commit must not need.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/skinning.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionswidgets.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local OM, W = st.OptionsModel, st.OptionsWidgets

local CLASSES = load_test_file('bags/fixtures/item_classes.lua').forever
local ITEM_NAMES = { [6948] = 'Hearthstone' }
C_Item = {
	GetItemClassInfo = function(classID) return CLASSES.classes[classID] end,
	GetItemSubClassInfo = function(classID, subclassID) return (CLASSES.subclasses[classID] or {})[subclassID] end,
	GetItemNameByID = function(itemID) return ITEM_NAMES[itemID] end,
}

load_saftui('SaftUI-Bags/config.lua')
apply_defaults()
for _, file in ipairs({ 'inventory', 'itemclasses', 'rules', 'ruleeditor' }) do
	load_saftui('SaftUI-Bags/' .. file .. '.lua')
end
local INV = st:GetModule('Inventory')
local R = INV.Rules

------------------------------------------------------------------ helpers

local function blk(id, params, negate)
	local b = { block = id, negate = negate }
	for k, v in pairs(params or {}) do b[k] = v end
	return b
end
local function grp(op, items, negate) return { op = op, items = items, negate = negate } end
local function t(text) return blk('tooltip', { text = text }) end

local function p(path)
	if path == nil then return 'nil' end
	return '{' .. table.concat(path, ',') .. '}'
end

-- A rule as text: AND(a,OR(b,c)), a block by its text (else its type), ! for NOT.
local function shape(node)
	if type(node) ~= 'table' then return tostring(node) end
	local neg = node.negate == true and '!' or ''
	if node.op ~= nil then
		local parts = {}
		for i = 1, #(node.items or {}) do parts[i] = shape(node.items[i]) end
		return neg .. tostring(node.op):upper() .. '(' .. table.concat(parts, ',') .. ')'
	end
	local text = node.text ~= '' and node.text or nil
	return neg .. tostring(text or node.block)
end

local parent = CreateFrame('Frame', nil, UIParent)
parent:SetSize(800, 600)
parent:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)

-- The editor over a stored rule. ed.stored is what get gives (set replaces
-- it), ed.sets every rule set got, ed.told what the window was told.
local function editor(rule)
	local ed = { stored = rule, sets = {}, told = { n = 0 } }
	local option = {
		type = 'bagrule', size = 'wide', name = 'Rule', desc = 'The rule.',
		get = function() return ed.stored end,
		set = function(_, value)
			ed.sets[#ed.sets + 1] = value
			ed.stored = value
		end,
	}
	local root = { page = { type = 'group', name = 'Page', args = { rule = option } } }
	local row
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'rule' then row = r end
		end
	end
	local w = W.Create(parent, 'bagrule')
	w:Bind(root, row, function(ok, err, dragging, widget)
		local told = ed.told
		told.n, told.ok, told.err, told.dragging, told.widget = told.n + 1, ok, err, dragging, widget
	end)
	w:SetWidth(700)
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, 0)
	ed.w = w
	return ed
end

local function click(frame, ...) stub.fire_script(frame, 'OnClick', ...) end

local function Color(group, name) return { st.config.profile.colors[group][name]:GetRGB() } end
local function same_rgb(c, want)
	return math.abs(c[1] - want[1]) < 1e-6 and math.abs(c[2] - want[2]) < 1e-6 and math.abs(c[3] - want[3]) < 1e-6
end

-- The open list's entries' labels (all of them, not only the rows shown).
local function list_labels()
	local out = {}
	for i, entry in ipairs(W.GetListFrames().entries or {}) do out[i] = entry.label end
	return out
end

-- Clicks the open list's row for label, scrolling it into view.
local function pick(label)
	local list = W.GetListFrames()
	for _ = 1, 20 do stub.fire_script(list.frame, 'OnMouseWheel', 1) end
	for _ = 1, 20 do
		for _, row in ipairs(list.rows) do
			if row:IsShown() and row.text:GetText() == label then return click(row) end
		end
		stub.fire_script(list.frame, 'OnMouseWheel', -1)
	end
	error('no list row ' .. label)
end

-- The rows' kinds and paths.
local function outline(w)
	local out = {}
	for i, row in ipairs(w.rows) do out[i] = row.kind .. p(row.path) end
	return table.concat(out, ' ')
end

-- The row at path (a block or title row), and its index.
local function row_at(w, path, kind)
	for i, row in ipairs(w.rows) do
		if p(row.path) == p(path) and row.kind == (kind or row.kind) and (kind or row.kind ~= 'add') then
			return row, i
		end
	end
end

local function add_row(w, path) return row_at(w, path, 'add') end

local function enter(box, text)
	box:SetText(text)
	stub.fire_script(box, 'OnEnterPressed')
end

-- Puts the cursor on the row's upper or lower half.
local function cursor_on(row, lower)
	local l, b, width, h = row.frame:GetRect()
	local scale = row.frame:GetEffectiveScale()
	stub.cursor_x = (l + width / 2) * scale
	stub.cursor_y = (b + (lower and 0.25 or 0.75) * h) * scale
end

------------------------------------------------------------------ the outline

test('a row per block and group, a badge per group, AND blue and OR orange', function()
	local rule = grp('and', {
		blk('class', { class = 7 }),
		grp('or', { blk('subclass', { class = 7, subclasses = { 7, 9 } }), t('Mote of') }),
		blk('expansion', { expansions = { 0, 1 } }),
	})
	local ed = editor(rule)
	local w = ed.w
	eq(outline(w), 'block{1} group{2} block{2,1} block{2,2} add{2} block{3} add{}', 'a row per block, group title and add')
	eq(w:GetHeight(), 7 * 26, 'each row is 26 high')

	local top = w.frame:GetTop()
	for i, row in ipairs(w.rows) do
		eq(top - row.frame:GetTop(), (i - 1) * 26, 'row ' .. i .. ' sits under the one before')
		eq(row.frame:GetHeight(), 26, 'row ' .. i .. ' is 26 high')
	end

	local left = w.frame:GetLeft()
	-- A row's content starts 34 in per level: its handle, or an add row's + Block.
	eq(w.rows[1].handle:GetLeft() - left, 34, 'a root row: 34 in')
	eq(w.rows[3].handle:GetLeft() - left, 68, 'a nested row: 34 more')
	eq(w.rows[2].handle:GetLeft() - left, 34, "a group's title hangs off its parent's line")
	eq(w.rows[5].fields.addBlock:GetLeft() - left, 68, "a group's add row is one of its rows")
	eq(w.rows[7].fields.addBlock:GetLeft() - left, 34, "the root's add row")

	-- A badge per group, on its add row; its line 2 wide at its indent plus 12.
	local badges = 0
	for _, row in ipairs(w.rows) do
		if row.badge then badges = badges + 1 end
	end
	eq(badges, 2, 'a badge per group, the root too')
	local rootBadge, orBadge = w.rows[7].badge, w.rows[5].badge
	eq(rootBadge.text:GetText(), 'AND', "the root's badge")
	eq(orBadge.text:GetText(), 'OR', "the nested group's badge")
	eq(rootBadge.line:GetLeft() - left, 12, "the root's line at 12")
	eq(orBadge.line:GetLeft() - left, 46, "the nested line at 34 + 12")
	eq(rootBadge.line:GetWidth(), 2, 'a line is 2 wide')
	local blue, orange = Color('button', 'blue'), Color('text', 'orange')
	check(same_rgb(stub.state(rootBadge.line).color_texture, blue), 'AND is blue')
	check(same_rgb(stub.state(orBadge.line).color_texture, orange), 'OR is orange')
	check(same_rgb({ rootBadge.text:GetTextColor() }, blue), "AND's badge text is blue")
	check(same_rgb({ orBadge.text:GetTextColor() }, orange), "OR's badge text is orange")
	check(same_rgb({ rootBadge:GetBackdropBorderColor() }, blue), "and its border")

	-- The line runs from its first row's top to its last row's middle, the badge on its middle.
	eq(top - rootBadge.line:GetTop(), 0, "the root's line starts at its first row")
	eq(top - rootBadge.line:GetBottom(), 6 * 26 + 13, "and ends at its add row's middle")
	eq(top - orBadge.line:GetTop(), 2 * 26, "the nested line starts under its title")
	eq(top - orBadge.line:GetBottom(), 4 * 26 + 13, "and ends at its add row's middle")
	local _, lineMid = rootBadge.line:GetCenter()
	local _, badgeMid = rootBadge:GetCenter()
	check(math.abs(lineMid - badgeMid) <= 0.5, 'the badge sits at the middle of its line')
	local lineX = rootBadge.line:GetCenter()
	eq(rootBadge:GetCenter(), lineX, 'centered on it')

	-- An 18 connector from the line to each row, in the color of the group it hangs off.
	for i, row in ipairs(w.rows) do
		local c = row.connector
		eq(c:GetWidth(), 18, 'row ' .. i .. ': an 18 connector')
		eq(c:GetHeight(), 2, 'row ' .. i .. ': 2 high')
		local want = row.op == 'or' and orange or blue
		check(same_rgb(stub.state(c).color_texture, want), 'row ' .. i .. ': the color of its group')
	end
	eq(w.rows[1].connector:GetLeft() - left, 12, 'a root row: from the root line')
	eq(w.rows[3].connector:GetLeft() - left, 46, 'a nested row: from its line')
	local _, rowMid = w.rows[1].frame:GetCenter()
	local _, connectorMid = w.rows[1].connector:GetCenter()
	eq(connectorMid, rowMid, "at the row's middle")

	-- What a row shows.
	eq(w.rows[1].label:GetText(), 'Class is', "a block's label")
	check(same_rgb({ w.rows[1].label:GetTextColor() }, Color('text', 'grey')), 'in grey')
	eq(w.rows[2].label:GetText(), 'group', "a group title's")
	check(w.rows[1].handle:IsShown() and w.rows[1].notBox:IsShown() and w.rows[1].remove:IsShown(),
		'a block: handle, NOT and X')
	check(w.rows[2].handle:IsShown() and w.rows[2].notBox:IsShown() and w.rows[2].remove:IsShown(),
		'a group title: handle, NOT and X')
	check(not w.rows[7].handle:IsShown() and not w.rows[7].notBox:IsShown() and not w.rows[7].remove:IsShown(),
		'an add row: none of them')
	eq(w.rows[7].fields.addBlock.text:GetText(), '+ Block', '+ Block')
	eq(w.rows[7].fields.addGroup.text:GetText(), '+ Group', '+ Group')
	check(same_rgb({ w.rows[7].fields.addBlock.text:GetTextColor() }, Color('text', 'blue')), 'in blue')
	eq(w.rows[1].remove.icon:GetTexture(), st.textures.close, 'the X is the close texture')
	eq(w.rows[1].remove:GetRight(), w.frame:GetRight(), 'at the right')
	local dots = 0
	for _, region in ipairs({ w.rows[1].handle:GetRegions() }) do
		if region:IsObjectType('Texture') and region:IsShown() then dots = dots + 1 end
	end
	eq(dots, 6, 'the handle is 6 dots')
	eq(w.rows[1].notBox.text:GetText(), 'NOT', 'the NOT box')
	eq(#take_errors(), 0, 'no errors')
	w:Release()
end)

test('a row too wide for the editor wraps its fields onto more lines, clear of the X', function()
	local ed = editor(grp('and', { blk('oldgear', { levels = 10, expansion = 9, share = 0.9 }), t('a') }))
	local w = ed.w
	w:SetWidth(900)
	eq(w.rows[1].frame:GetHeight(), 26, 'at 900 Old gear fits one line')
	w:SetWidth(400)
	local old, after, add = w.rows[1], w.rows[2], w.rows[3]
	local height = old.frame:GetHeight()
	check(height > 26 and height % 26 == 0, 'at 400 it takes more lines of 26')
	local top = w.frame:GetTop()
	eq(top - after.frame:GetTop(), height, 'the next row starts under it')
	eq(w:GetHeight(), height + after.frame:GetHeight() + 26, 'the editor is as tall as its rows')
	local limit = old.remove:GetLeft()
	local lines = {}
	for name, control in pairs(old.fields) do
		check(control:GetRight() <= limit, name .. ' ends before the X')
		lines[old.frame:GetTop() - control:GetTop()] = true
	end
	for _, caption in ipairs(old.captions) do
		check(caption:GetLeft() + caption:GetUnboundedStringWidth() <= limit, caption:GetText() .. ' ends before the X')
	end
	check(lines[2] and lines[2 + 26], 'boxes on the first line and the next, 2 down in each')
	-- The handle, NOT, label and X stay on the first line; a wrapped line starts under the label.
	eq(old.frame:GetTop() - old.remove:GetTop(), 5, 'the X in the middle of the first line')
	eq(old.frame:GetTop() - old.handle:GetTop(), 2, 'the handle on the first line')
	local _, labelMiddle = old.label:GetCenter()
	eq(old.frame:GetTop() - labelMiddle, 13, 'the label on the first line')
	local under = math.huge
	for _, control in pairs(old.fields) do
		if old.frame:GetTop() - control:GetTop() > 26 then under = math.min(under, control:GetLeft()) end
	end
	eq(under, old.label:GetLeft(), 'the next line starts under the label')
	-- The root's line runs to its add row's middle, under the taller row.
	eq(top - add.badge.line:GetBottom(), height + after.frame:GetHeight() + 13, "the root's line ends at its add row's middle")
	-- Room again: one line.
	w:SetWidth(900)
	eq(old.frame:GetHeight(), 26, 'wider: one line again')
	eq(w:GetHeight(), 3 * 26, 'and the editor three rows')
	eq(#take_errors(), 0, 'no errors')
	w:Release()
end)

test('+ Block lists every block type in order; a pick adds it at the group\'s end', function()
	local ed = editor(grp('and', { t('a'), grp('or', { t('b') }) }))
	local w = ed.w
	local rootAdd = add_row(w, {})
	click(rootAdd.fields.addBlock)
	eq(W.ListOwner(), rootAdd.fields.addBlock, 'it opens a list')
	local want = {}
	for i, type_ in ipairs(R.BLOCKS) do want[i] = type_.label end
	eq(table.concat(list_labels(), ','), table.concat(want, ','), 'every block type, in order')
	pick('Name contains')
	eq(#ed.sets, 1, 'one set')
	eq(shape(ed.stored), 'AND(a,OR(b),name)', "at the root's end")
	check(R.Equal(ed.stored.items[3], { block = 'name', text = '' }), 'its new params')
	eq(ed.told.ok, true, 'the window is told')
	eq(outline(w), 'block{1} group{2} block{2,1} add{2} block{3} add{}', 'drawn again')

	click(add_row(w, { 2 }).fields.addBlock)
	pick('Protected')
	eq(shape(ed.stored), 'AND(a,OR(b,protected),name)', "at the nested group's end")
	w:Release()
end)

test('+ Group adds an empty group with the other operator', function()
	local ed = editor(grp('and', { t('a'), grp('or', { t('b') }) }))
	local w = ed.w
	click(add_row(w, {}).fields.addGroup)
	eq(shape(ed.stored), 'AND(a,OR(b),OR())', 'an OR under the AND')
	click(add_row(w, { 2 }).fields.addGroup)
	eq(shape(ed.stored), 'AND(a,OR(b,AND()),OR())', 'an AND under the OR')
	eq(outline(w), 'block{1} group{2} block{2,1} group{2,2} add{2,2} add{2} group{3} add{3} add{}', 'drawn')
	w:Release()
end)

test('NOT toggles, the X removes, the badge flips', function()
	local stored = grp('and', { t('a'), grp('or', { t('b'), t('c') }) })
	local before = shape(stored)
	local ed = editor(stored)
	local w = ed.w
	click(w.rows[1].notBox)
	eq(shape(ed.stored), 'AND(!a,OR(b,c))', 'NOT on a block')
	check(same_rgb({ w.rows[1].notBox.text:GetTextColor() }, Color('text', 'blue')), 'the NOT box shows it on')
	click(w.rows[1].notBox)
	eq(shape(ed.stored), 'AND(a,OR(b,c))', 'and off')
	eq(ed.stored.items[1].negate, nil, 'off is nil')
	click(row_at(w, { 2 }, 'group').notBox)
	eq(shape(ed.stored), 'AND(a,!OR(b,c))', 'NOT on a group')

	click(add_row(w, { 2 }).badge)
	eq(shape(ed.stored), 'AND(a,!AND(b,c))', 'the badge flips its group')
	click(add_row(w, {}).badge)
	eq(shape(ed.stored), 'OR(a,!AND(b,c))', 'and the root')

	click(row_at(w, { 2, 1 }).remove)
	eq(shape(ed.stored), 'OR(a,!AND(c))', 'the X removes a block')
	click(row_at(w, { 2 }, 'group').remove)
	eq(shape(ed.stored), 'OR(a)', 'and a group, with its rows')

	eq(shape(stored), before, 'the rule get gave was never changed: each edit sets a copy')
	for i = 2, #ed.sets do
		check(ed.sets[i] ~= ed.sets[i - 1], 'set ' .. i .. ' is a new table')
	end
	eq(#take_errors(), 0, 'no errors')
	w:Release()
end)

------------------------------------------------------------------ the fields

test("each block type's fields set its params", function()
	local refreshes = 0
	local realRefresh = st.Config.Refresh
	st.Config.Refresh = function(...)
		refreshes = refreshes + 1
		return realRefresh(...)
	end

	-- One block in an OR; returns the editor, its row and its fields.
	local function one(block)
		local ed = editor(grp('or', { block }))
		return ed, ed.w.rows[1], ed.w.rows[1].fields
	end
	local function done(ed) W.CloseList(); ed.w:Release() end

	-- A check list: a click toggles, writes and refreshes, and leaves it open.
	local function toggles(ed, field, label)
		local n, refreshed = ed.told.n, refreshes
		pick(label)
		eq(ed.told.n, n, label .. ": a check list's toggle doesn't re-render the editor")
		eq(refreshes, refreshed + 1, label .. ': it calls st.Config:Refresh()')
		eq(W.ListOwner(), field, label .. ': the list stays open')
	end

	-- Tooltip contains and Name contains: a 150 box, and whole word.
	for _, id in ipairs({ 'tooltip', 'name' }) do
		local ed, row, f = one(blk(id, { text = '' }))
		eq(row.label:GetText(), R.BlockType(id).label, id .. ': its label')
		eq(f.text:GetWidth(), 150, id .. ': a 150 box')
		eq(f.text:GetText(), '', id .. ': empty')
		enter(f.text, 'Curio')
		eq(ed.stored.items[1].text, 'Curio', id .. ': Enter sets the text')
		eq(row.fields.word.caption:GetText(), 'whole word', id .. ': the check box is labeled')
		click(ed.w.rows[1].fields.word)
		eq(ed.stored.items[1].word, true, id .. ': whole word on')
		check(ed.w.rows[1].fields.word.mark:IsShown(), id .. ': and checked')
		click(ed.w.rows[1].fields.word)
		eq(ed.stored.items[1].word, nil, id .. ': and off')
		done(ed)
	end

	-- Name is: a 150 box.
	local ed, row, f = one(blk('nameis', { text = 'Hearthstone' }))
	eq(f.text:GetWidth(), 150, 'nameis: a 150 box')
	eq(f.text:GetText(), 'Hearthstone', 'nameis: the text')
	enter(f.text, 'Ruby')
	eq(ed.stored.items[1].text, 'Ruby', 'nameis: set')
	eq(ed.w.rows[1].fields.word, nil, 'nameis: no whole word')
	done(ed)

	-- Class is: Pick a class, a list of the classes but the OBSOLETE ones.
	ed, row, f = one(blk('class'))
	eq(f.class.text:GetText(), 'Pick a class', 'class: none picked')
	click(f.class)
	local labels = list_labels()
	eq(labels[1], 'Consumable', 'class: by id')
	check(not table.concat(labels, ','):find('OBSOLETE', 1, true), 'class: no OBSOLETE class')
	eq(#labels, 13, "class: Forever's classes but its 4 OBSOLETE ones")
	pick('Trade Goods')
	eq(ed.stored.items[1].class, 7, 'class: the id is stored')
	eq(ed.w.rows[1].fields.class.text:GetText(), 'Trade Goods', 'class: shows its name')
	done(ed)

	-- Subclass is: the class, then a check list of its subclasses.
	ed, row, f = one(blk('subclass', { subclasses = {} }))
	eq(f.subclasses.text:GetText(), 'Pick subclasses', 'subclass: none picked')
	click(f.subclasses)
	eq(W.ListOwner(), nil, 'subclass: no class, no list')
	click(f.class)
	pick('Trade Goods')
	eq(ed.stored.items[1].class, 7, 'subclass: the class is set')
	f = ed.w.rows[1].fields
	click(f.subclasses)
	eq(list_labels()[2], 'Parts', "subclass: the class's subclasses")
	toggles(ed, f.subclasses, 'Herb')
	eq(table.concat(ed.stored.items[1].subclasses, ','), '9', 'subclass: Herb')
	eq(f.subclasses.text:GetText(), 'Herb', 'subclass: the field shows it at once')
	toggles(ed, f.subclasses, 'Metal & Stone')
	eq(table.concat(ed.stored.items[1].subclasses, ','), '7,9', 'subclass: in the list\'s order')
	eq(f.subclasses.text:GetText(), 'Metal & Stone, Herb', 'subclass: names joined')
	toggles(ed, f.subclasses, 'Herb')
	eq(table.concat(ed.stored.items[1].subclasses, ','), '7', 'subclass: unchecked')
	W.CloseList()
	click(ed.w.rows[1].fields.class)
	pick('Consumable')
	eq(ed.stored.items[1].class, 0, 'subclass: another class')
	eq(#ed.stored.items[1].subclasses, 0, "subclass: and the other class's subclasses go")
	done(ed)

	-- Quality, Equip slot, Binding and Expansion: a field and a check list.
	local lists = {
		{ 'quality', 'qualities', 'Epic', 4 },
		{ 'slot', 'slots', R.SLOTS[1][2], R.SLOTS[1][1] },
		{ 'binding', 'states', 'Warbound', 'warbound' },
		{ 'expansion', 'expansions', R.ExpansionLabel(1), 1 },
	}
	for _, case in ipairs(lists) do
		local id, param, label, value = case[1], case[2], case[3], case[4]
		ed, row, f = one(blk(id, { [param] = {} }))
		check(f[param].text:GetText():find('^Pick ') ~= nil, id .. ': none picked')
		click(f[param])
		toggles(ed, f[param], label)
		eq(ed.stored.items[1][param][1], value, id .. ': set')
		eq(f[param].text:GetText(), label, id .. ': shown')
		done(ed)
	end
	ed, row, f = one(blk('quality', { qualities = {} }))
	click(f.qualities)
	eq(table.concat(list_labels(), ','), 'Poor,Common,Uncommon,Rare,Epic,Legendary,Artifact,Heirloom', 'quality: 0 to 7')
	done(ed)
	ed, row, f = one(blk('binding', { states = {} }))
	click(f.states)
	eq(table.concat(list_labels(), ','), 'Soulbound,Bind on equip,Warbound,Not bound', 'binding: its states')
	done(ed)
	ed, row, f = one(blk('expansion', { expansions = {} }))
	click(f.expansions)
	eq(#list_labels(), 12, 'expansion: 0 to 11 without GetNumExpansions')
	W.CloseList()
	GetNumExpansions = function() return 3 end
	click(f.expansions)
	eq(table.concat(list_labels(), ','), R.ExpansionLabel(0) .. ',' .. R.ExpansionLabel(1) .. ',' .. R.ExpansionLabel(2),
		'expansion: 0 to GetNumExpansions() - 1')
	GetNumExpansions = nil
	done(ed)

	-- Item level and Required level: at least, at most, between, and one or two 50 boxes.
	for _, id in ipairs({ 'ilvl', 'reqlevel' }) do
		ed, row, f = one(blk(id, { min = 0 }))
		eq(f.mode.text:GetText(), 'at least', id .. ': at least')
		eq(f.min:GetWidth(), 50, id .. ': a 50 box')
		eq(f.max, nil, id .. ': one box')
		enter(f.min, '200')
		eq(ed.stored.items[1].min, 200, id .. ': a number')
		click(ed.w.rows[1].fields.mode)
		eq(table.concat(list_labels(), ','), 'at least,at most,between', id .. ': the modes')
		pick('between')
		check(R.Equal(ed.stored.items[1], blk(id, { min = 200, max = 200 })), id .. ': between keeps the number')
		f = ed.w.rows[1].fields
		check(f.min ~= nil and f.max ~= nil, id .. ': two boxes')
		enter(f.max, '300')
		eq(ed.stored.items[1].max, 300, id .. ': the top')
		click(ed.w.rows[1].fields.mode)
		pick('at most')
		check(R.Equal(ed.stored.items[1], blk(id, { max = 300 })), id .. ': at most')
		f = ed.w.rows[1].fields
		eq(f.min, nil, id .. ': one box again')
		eq(f.max:GetText(), '300', id .. ': its number')
		done(ed)
	end

	-- Crafting reagent and Has vendor price: Yes or No.
	for _, id in ipairs({ 'reagent', 'vendorprice' }) do
		ed, row, f = one(blk(id, { value = true }))
		eq(f.value.text:GetText(), 'Yes', id .. ': Yes')
		click(f.value)
		eq(table.concat(list_labels(), ','), 'Yes,No', id .. ': the choices')
		pick('No')
		eq(ed.stored.items[1].value, false, id .. ': No')
		eq(ed.w.rows[1].fields.value.text:GetText(), 'No', id .. ': shown')
		done(ed)
	end

	-- Item is one of: <n> items.
	ed, row, f = one(blk('items', { ids = { 1, 2, 3 } }))
	eq(f.ids.text:GetText(), '3 items', 'items: the count')
	eq(f.id:GetWidth(), 50, 'items: a 50 box')
	done(ed)

	-- Old gear for my level: three 40 boxes; the share as a percent.
	ed, row, f = one(R.NewBlock('oldgear'))
	eq(f.levels:GetText(), '10', 'oldgear: levels')
	eq(f.expansion:GetText(), '9', 'oldgear: expansion')
	eq(f.share:GetText(), '90', 'oldgear: the share as a percent')
	eq(f.levels:GetWidth(), 40, 'oldgear: 40 boxes')
	local captions = {}
	for i, caption in ipairs(row.captions) do captions[i] = caption:GetText() end
	eq(table.concat(captions, ','), 'levels below me,expansion up to,% of my item level', 'oldgear: the captions')
	enter(f.share, '85')
	eq(ed.stored.items[1].share, 0.85, 'oldgear: a percent typed is stored as the share')
	enter(ed.w.rows[1].fields.levels, '5')
	enter(ed.w.rows[1].fields.expansion, '3')
	check(R.Equal(ed.stored.items[1], { block = 'oldgear', levels = 5, expansion = 3, share = 0.85 }), 'oldgear: set')
	done(ed)

	-- Protected: a note.
	ed, row, f = one(blk('protected'))
	eq(f.note:GetText(), 'items marked Protected', 'protected: the note')
	check(same_rgb({ f.note:GetTextColor() }, Color('text', 'grey')), 'protected: in grey')
	done(ed)

	st.Config.Refresh = realRefresh
	eq(#take_errors(), 0, 'no errors')
end)

test('a text box commits on Enter only', function()
	local ed = editor(grp('or', { t('Curio') }))
	local box = ed.w.rows[1].fields.text
	box:SetFocus()
	box:SetText('Mote')
	eq(#ed.sets, 0, 'typing sets nothing')
	stub.fire_script(box, 'OnEscapePressed')
	eq(#ed.sets, 0, 'nor does Esc')
	eq(box:GetText(), 'Curio', 'which puts the stored text back')
	check(GetCurrentKeyBoardFocus() ~= box, 'and lets go of the keyboard')

	box:SetFocus()
	box:SetText('Mote')
	box:ClearFocus()
	eq(#ed.sets, 0, 'leaving the box sets nothing')
	eq(box:GetText(), 'Curio', 'and puts it back')

	box:SetFocus()
	enter(box, 'Mote')
	eq(#ed.sets, 1, 'Enter sets')
	eq(ed.stored.items[1].text, 'Mote', 'what was typed')
	check(GetCurrentKeyBoardFocus() == nil, 'and lets go of the keyboard')
	ed.w:Release()

	-- A number box: text that isn't a number sets nothing and puts the number back.
	ed = editor(grp('or', { blk('ilvl', { min = 10 }) }))
	box = ed.w.rows[1].fields.min
	enter(box, 'lots')
	eq(#ed.sets, 0, 'not a number: nothing set')
	eq(box:GetText(), '10', 'the stored number back')
	enter(box, '20')
	eq(ed.stored.items[1].min, 20, 'a number sets')
	ed.w:Release()
end)

------------------------------------------------------------------ dragging

test('dragging a block into another group moves it', function()
	local ed = editor(grp('and', { t('a'), grp('or', { t('b'), t('c') }), t('d'), grp('and', {}) }))
	local w = ed.w
	-- 1 a, 2 OR, 3 b, 4 c, 5 OR's add, 6 d, 7 AND, 8 AND's add, 9 root's add.
	eq(outline(w), 'block{1} group{2} block{2,1} block{2,2} add{2} block{3} group{4} add{4} add{}', 'the rows')

	-- d onto b's upper half: first in the OR.
	local handle = w.rows[6].handle
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	eq(ed.told.dragging, true, 'the window is told a drag is on, so it waits to render')
	check(ed.told.widget == w, 'and which widget')
	eq(#ed.sets, 0, 'nothing set yet')
	check(w.ghost and w.ghost:IsShown(), 'a ghost follows the cursor')
	check(w.ghost.backdrop ~= nil, "drawn in SaftUI's theme")
	cursor_on(w.rows[3], false)
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(#ed.sets, 1, 'let go: one set')
	eq(shape(ed.stored), 'AND(a,OR(d,b,c),AND())', 'd first in the OR')
	eq(ed.told.dragging, nil, 'the window renders now')
	check(not w.ghost:IsShown(), 'the ghost is gone')

	-- c onto the empty group's add row: into it.
	handle = row_at(w, { 2, 3 }).handle
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	cursor_on(add_row(w, { 3 }), true)
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(shape(ed.stored), 'AND(a,OR(d,b),AND(c))', 'c in the empty group')

	-- a onto the lower half of the AND's title: first in it.
	handle = row_at(w, { 1 }).handle
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	cursor_on(row_at(w, { 3 }, 'group'), true)
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(shape(ed.stored), 'AND(OR(d,b),AND(a,c))', 'a first in the AND')

	-- A group into its own rows: nothing moves.
	local sets = #ed.sets
	handle = row_at(w, { 2 }, 'group').handle
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	cursor_on(row_at(w, { 2, 1 }), true)
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(#ed.sets, sets, 'a group dropped into itself sets nothing')
	-- Dropped where it is, or off the editor: nothing moves either.
	handle = row_at(w, { 1, 1 }).handle
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	cursor_on(row_at(w, { 1, 1 }), true)
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	stub.cursor_x, stub.cursor_y = 0, 0
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(#ed.sets, sets, 'no move, no set')
	eq(shape(ed.stored), 'AND(OR(d,b),AND(a,c))', 'the rule is as it was')
	check(not w.ghost:IsShown(), 'and no ghost')
	eq(#take_errors(), 0, 'no errors')
	w:Release()
end)

test('an ID typed, and an item dropped from the cursor, join Item is one of', function()
	local ed = editor(grp('or', { blk('items', { ids = {} }) }))
	local w = ed.w
	eq(w.rows[1].fields.ids.text:GetText(), '0 items', 'none yet')
	enter(w.rows[1].fields.id, '6948')
	eq(table.concat(ed.stored.items[1].ids, ','), '6948', 'an ID typed and Entered joins')
	eq(w.rows[1].fields.ids.text:GetText(), '1 item', 'the count')
	eq(w.rows[1].fields.id:GetText(), '', 'the box is empty again')
	enter(w.rows[1].fields.id, 'abc')
	enter(w.rows[1].fields.id, '-4')
	enter(w.rows[1].fields.id, '6948')
	eq(table.concat(ed.stored.items[1].ids, ','), '6948', 'not a number, not an id, or one already in: nothing joins')

	stub.cursor_item = { 2589, '|Hitem:2589|h[Linen Cloth]|h' }
	stub.fire_script(w.rows[1].frame, 'OnReceiveDrag')
	eq(table.concat(ed.stored.items[1].ids, ','), '6948,2589', 'an item dropped on the row joins')
	eq(stub.cursor_item, nil, 'and the cursor is cleared')
	stub.cursor_item = { 4306, '|Hitem:4306|h[Silk Cloth]|h' }
	click(w.rows[1].frame)
	eq(table.concat(ed.stored.items[1].ids, ','), '6948,2589,4306', 'and one clicked onto it')
	eq(stub.cursor_item, nil, 'cleared')
	local sets = #ed.sets
	click(w.rows[1].frame)
	eq(#ed.sets, sets, 'a click with nothing on the cursor adds nothing')
	stub.cursor_item = { 6948, '|Hitem:6948|h[Hearthstone]|h' }
	stub.fire_script(w.rows[1].frame, 'OnReceiveDrag')
	eq(#ed.sets, sets, 'one already in adds nothing')
	eq(stub.cursor_item, nil, 'but the cursor is cleared')

	local field = w.rows[1].fields.ids
	click(field)
	eq(table.concat(list_labels(), ','), 'Hearthstone (6948),Item 2589,Item 4306', 'the check list: name (id), else Item id')
	pick('Hearthstone (6948)')
	eq(table.concat(ed.stored.items[1].ids, ','), '2589,4306', 'unchecking one removes it')
	eq(field.text:GetText(), '2 items', 'the count follows')
	eq(W.ListOwner(), field, 'the list stays open')
	pick('Hearthstone (6948)')
	eq(table.concat(ed.stored.items[1].ids, ','), '6948,2589,4306', "checked again, it is back in its place")
	W.CloseList()

	-- Rows of other blocks take nothing from the cursor.
	ed.w:Release()
	ed = editor(grp('or', { t('a') }))
	stub.cursor_item = { 2589, 'link' }
	stub.fire_script(ed.w.rows[1].frame, 'OnReceiveDrag')
	eq(#ed.sets, 0, 'a tooltip row takes no item')
	eq(stub.cursor_item ~= nil, true, 'and leaves the cursor be')
	stub.cursor_item = nil
	eq(#take_errors(), 0, 'no errors')
	ed.w:Release()
end)

------------------------------------------------------------------ the highlight

test('SetHighlight tints the row at a path', function()
	local ed = editor(grp('and', { t('a'), grp('or', { t('b'), t('c') }) }))
	local w = ed.w
	local function tinted()
		local out = {}
		for i, row in ipairs(w.rows) do
			if row.tint:IsShown() then out[#out + 1] = i end
		end
		return table.concat(out, ',')
	end
	eq(tinted(), '', 'nothing at first')
	w:SetHighlight({ 2, 2 })
	eq(tinted(), '4', 'the row at the path')
	local color = stub.state(w.rows[4].tint).color_texture
	check(same_rgb(color, Color('text', 'orange')) and math.abs(color[4] - 0.15) < 1e-6, 'orange at 0.15')
	w:SetHighlight({ 2 })
	eq(tinted(), '2', "a group's title row")
	click(w.rows[1].notBox)
	eq(tinted(), '2', 'kept when the editor draws again')
	w:SetHighlight(nil)
	eq(tinted(), '', 'nil clears it')
	w:SetHighlight({ 9 })
	eq(tinted(), '', 'a path with no row tints nothing')
	w:SetHighlight({})
	eq(tinted(), '', 'nor does the root')
	w:Release()
end)

------------------------------------------------------------------ unreadable data

test('an unknown block shows as Unknown block and can be removed', function()
	local ed = editor(grp('or', {
		blk('future', { x = 1 }),
		'garbage',
		{ op = 'xor', items = { t('a') } },
		blk('class', { class = 'Trade Goods' }),
		blk('quality', { qualities = 'Epic' }),
		blk('ilvl', { min = 'ten' }),
		blk('items', { ids = 7 }),
		blk('tooltip'),
		t('ok'),
	}))
	local w = ed.w
	eq(outline(w), 'block{1} block{2} block{3} block{4} block{5} block{6} block{7} block{8} block{9} add{}', 'a row each')
	for i = 1, 3 do
		local row = w.rows[i]
		eq(row.label:GetText(), 'Unknown block', 'row ' .. i .. ': Unknown block')
		check(not row.handle:IsShown() and not row.notBox:IsShown(), 'row ' .. i .. ': no handle, no NOT')
		check(row.remove:IsShown(), 'row ' .. i .. ': only the X')
	end
	eq(w.rows[4].fields.class.text:GetText(), 'Pick a class', "a known block with params it can't read shows its fields")
	eq(w.rows[5].fields.qualities.text:GetText(), 'Pick qualities', 'with nothing picked')
	eq(w.rows[7].fields.ids.text:GetText(), '0 items', 'nothing in it')
	eq(w.rows[8].fields.text:GetText(), '', 'an empty box')
	eq(#take_errors(), 0, 'drawn with no errors')

	click(w.rows[5].fields.qualities)
	pick('Epic')
	eq(table.concat(ed.stored.items[5].qualities, ','), '4', 'a pick makes a list of it')
	W.CloseList()
	click(w.rows[2].remove)
	eq(#ed.stored.items, 8, 'the X removes an unknown node')
	click(w.rows[1].remove)
	click(w.rows[1].remove)
	eq(shape(ed.stored), 'OR(class,quality,ilvl,items,tooltip,ok)', 'all three gone, the rest kept')

	-- A rule that isn't a readable group shows as an empty one; an edit starts it afresh.
	for _, odd in ipairs({ 42, { op = 'xor', items = { t('a') } } }) do
		ed.w:Release()
		ed = editor(odd)
		eq(outline(ed.w), 'add{}', tostring(odd) .. ': just the add row')
		click(ed.w.rows[1].fields.addGroup)
		eq(shape(ed.stored), 'AND(OR())', 'an edit makes a rule')
	end
	eq(#take_errors(), 0, 'no errors')
	ed.w:Release()
end)

------------------------------------------------------------------ releasing

test('a released editor closes the list it owns and stops its drag', function()
	local ed = editor(grp('or', { blk('quality', { qualities = {} }), t('a') }))
	click(ed.w.rows[1].fields.qualities)
	check(W.ListOwner() ~= nil, 'its check list is open')
	ed.w:Release()
	eq(W.ListOwner(), nil, 'released, the list closes')

	ed = editor(grp('or', { t('a'), t('b') }))
	local handle = ed.w.rows[1].handle
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	check(ed.w.ghost:IsShown(), 'dragging')
	ed.w:Release()
	check(not ed.w.ghost:IsShown(), 'released, the ghost goes')
	eq(ed.w.frame:GetScript('OnUpdate'), nil, 'and the drag stops')
	cursor_on({ frame = parent }, false)
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
	eq(#ed.sets, 0, 'a mouse up after the release sets nothing')

	-- A list some other frame owns is left open.
	local other = W.Box(st:CreateFrame('Button', nil, UIParent))
	other:SetSize(100, 20)
	other:SetPoint('CENTER')
	ed = editor(grp('or', { t('a') }))
	W.OpenList(other, { { key = 1, label = 'One' } }, nil, function() end)
	ed.w:Release()
	eq(W.ListOwner(), other, "another frame's list stays open")
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
end)
