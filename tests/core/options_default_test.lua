-- A setting's own reset: SaftUI's default field (SaftUI-Core/Config/
-- optionsmodel.lua's OM.DefaultState and OM.DefaultReset) and its reset icon
-- by the control (optionsshare.lua's OB.PlaceDefault, from the body's
-- PlaceRow and its Refresh), on every built-in row type, under Thick and
-- Blizzard, in an item's menu, through a drag, and on Global settings' Colors
-- and Theme tabs, whose section Resets it replaces.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window's files, as
-- options_window_helpers.lua loads them, with the real Colors and Theme
-- modules. The pages are synthetic but those two tabs: rows on bodies made
-- with OB.New, and an item whose menu has a setting with a default, in the
-- window. The mouse is played by firing the frames' scripts, OnEnter and
-- OnLeave with true as the game passes them.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
-- With the derived defaults loaded, as in the game: every case below must pass
-- as it did without them (the hand defaults, the shares).
local OM, W, OB, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local click, cell, close_all = H.click, H.cell, H.close_all

------------------------------------------------------------------ the synthetic page

local differs, resets, values -- which settings differ, the resets run, the values shown

local function fresh()
	differs, resets = {}, {}
	values = { toggle = true, range = 0.5, select = 'b', input = 'Words', color = { 1, 0, 0, 0.5 }, keybinding = 'F',
		multi = { a = true }, item = true }
end
fresh()

-- A default whose differs reads differs[key] and whose reset notes the key.
local function Default(extra)
	local default = {
		differs = function(info) return differs[info[#info]] and true or false end,
		reset = function(info)
			resets[#resets + 1] = info[#info]
			differs[info[#info]] = nil
		end,
	}
	for k, v in pairs(extra or {}) do default[k] = v end
	return default
end

local pos = { point = 'CENTER', rel_point = 'CENTER', x_off = 0, y_off = 0 }

-- Every built-in type, each with a default naming its value.
local function Args()
	return {
		toggle = { type = 'toggle', name = 'A toggle', desc = 'x', order = 1,
			default = Default({ value = function() return false end }) },
		range = { type = 'range', name = 'A range', desc = 'x', order = 2, min = 0, max = 1, step = 0.01, isPercent = true,
			default = Default({ value = function() return 0.25 end }) },
		select = { type = 'select', name = 'A select', desc = 'x', order = 3, values = { a = 'Apple', b = 'Banana' },
			default = Default({ value = function() return 'a' end }) },
		input = { type = 'input', name = 'An input', desc = 'x', order = 4,
			default = Default({ value = function() return 'Text' end }) },
		color = { type = 'color', name = 'A color', desc = 'x', order = 5, hasAlpha = true,
			get = function() return unpack(values.color) end, set = function() end,
			default = Default({ value = function() return 1, 0, 0, 0.5 end }) },
		keybinding = { type = 'keybinding', name = 'A key', desc = 'x', order = 6,
			default = Default({ text = 'Not bound' }) },
		multi = { type = 'multiselect', name = 'A multiselect', desc = 'x', order = 7, values = { a = 'A', b = 'B', c = 'C' },
			get = function(_, key) return values.multi[key] end, set = function() end,
			default = Default({ text = 'A only' }) },
		item = { type = 'item', name = 'Hotkey', desc = 'x', order = 8, size = 'small',
			get = function() return values.item end, set = function() end,
			menu = { type = 'group', name = 'Hotkey', args = {} },
			default = Default({ value = function() return true end }) },
		go = { type = 'execute', name = 'Go', desc = 'x', order = 9, func = function() end, default = Default() },
		words = { type = 'description', name = 'Some words', order = 10, default = Default() },
		position = st.Config.generators.position(11, false, function(part) return pos[part] end,
			function(part, value) pos[part] = value end, nil, 'Where it sits.', 'Position'),
	}
end

local function Page(args)
	args.position.default = args.position.default or Default({ text = 'the middle' })
	return { page = { type = 'group', name = 'Page', args = args,
		get = function(info) return values[info[#info]] end, set = function() end } }
end

------------------------------------------------------------------ drawing helpers

local function draw(root, onChanged)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 900)
	local body = OB.New(content, root, onChanged, 774)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- GameTooltip, as a stand-in that notes each line.
local function watch_tooltip()
	local tip = { lines = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines = {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		AddDoubleLine = function(_, left) tip.lines[#tip.lines + 1] = left end,
		Show = function() end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner = nil end,
	}
	return tip, function() _G.GameTooltip = saved end
end

local function in_look(look, fn)
	st.config.profile.theme.name = look
	local tip, restore = watch_tooltip()
	local ok, err = pcall(fn, tip)
	W.CloseList()
	restore()
	st.config.profile.theme.name = 'thick'
	if not ok then error(err, 0) end
end

local function icon_of(c) return c.frame.defaultReset end
local function shown(c) local icon = icon_of(c); return icon ~= nil and icon:IsShown() end
local function mid(region) return (region:GetTop() + region:GetBottom()) / 2 end

-- The leftmost of anything region shows: itself, its regions, its children's.
local function leftmost(region, left)
	if not region:IsShown() then return left end
	local l = region:GetLeft()
	if l and (not left or l < left) then left = l end
	if region.GetRegions then
		for _, part in ipairs({ region:GetRegions() }) do left = leftmost(part, left) end
		for _, child in ipairs({ region:GetChildren() }) do left = leftmost(child, left) end
	end
	return left
end

local CONTROLS = { 'toggle', 'range', 'select', 'input', 'color', 'keybinding', 'multi' }

------------------------------------------------------------------ the model

test('OM.DefaultState and OM.DefaultReset read and run the default field, with its info', function()
	fresh()
	local root = Page(Args())
	local view = OM.BuildView(root, 'page')
	local rows = {}
	for _, section in ipairs(view.sections) do
		for _, row in ipairs(section.rows) do rows[row.key] = row end
	end
	local s = OM.DefaultState(root, rows.range)
	eq(s.differs, false, 'differs: false')
	eq(s.value.n, 1); eq(s.value[1], 0.25, 'its value packed')
	differs.range = true
	eq(OM.DefaultState(root, rows.range).differs, true, 'true once it differs')
	eq(OM.DefaultState(root, rows.color).value.n, 4, "a color's four")
	eq(OM.DefaultState(root, rows.keybinding).text, 'Not bound', 'a text')
	eq(OM.DefaultState(root, rows.keybinding).value, nil, 'which leaves the value unread')
	eq(OM.DefaultReset(root, rows.range), true, 'a reset runs')
	eq(table.concat(resets, ','), 'range', 'with the option\'s info')

	-- No default; a function that errors is reported and counts as nothing.
	rows.range.option.default = nil
	eq(OM.DefaultState(root, rows.range), nil, 'none: nil')
	eq(OM.DefaultReset(root, rows.range), false, 'and no reset')
	rows.range.option.default = { differs = function() error('boom') end, reset = function() error('bang') end, text = function() return 7 end }
	local state = OM.DefaultState(root, rows.range)
	eq(state.differs, false, 'an erroring differs counts as false')
	eq(state.text, '7', 'a text function, as text')
	eq(OM.DefaultReset(root, rows.range), false, 'an erroring reset: false')
	eq(#take_errors(), 2, 'both reported')
end)

test('a hand reset that returns false and a message refuses: false and the message; nothing else it returns counts', function()
	fresh()
	local root = Page(Args())
	local view = OM.BuildView(root, 'page')
	local row
	for _, section in ipairs(view.sections) do
		for _, each in ipairs(section.rows) do if each.key == 'range' then row = each end end
	end
	row.option.default = { differs = function() return true end, reset = function() return false, 'Not now.' end }
	local ok, message = OM.DefaultReset(root, row)
	eq(ok, false, 'refused')
	eq(message, 'Not now.', 'with its message')
	row.option.default.reset = function() return 'done', 'x' end
	eq(OM.DefaultReset(root, row), true, 'any other answer is done')
	row.option.default.reset = function() end
	eq(OM.DefaultReset(root, row), true, 'so is none')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ drawn

test('the reset icon shows by a control only while its setting differs, on every built-in type with a value', function()
	in_look('thick', function(tip)
		fresh()
		local body, by = draw(Page(Args()))
		for _, key in ipairs(CONTROLS) do check(not shown(by[key]), key .. ': at its default, none') end
		check(not shown(by.item) and not shown(by.position), 'nor on the item or the block')
		body:Release()

		for _, key in ipairs({ 'toggle', 'range', 'select', 'input', 'color', 'keybinding', 'multi', 'item', 'position', 'go', 'words' }) do
			differs[key] = true
		end
		body, by = draw(Page(Args()))
		for _, key in ipairs(CONTROLS) do
			local c = by[key]
			local icon = icon_of(c)
			check(shown(c), key .. ': its reset shows')
			eq(icon.icon:GetTexture(), st.icons.rotateCcw, key .. ": Lucide's rotate-ccw")
			eq(icon:GetWidth() .. 'x' .. icon:GetHeight(), '14x14', key .. ': 14x14, as the hover line\'s')
			local left = leftmost(c.widget.frame)
			eq(icon:GetRight() - c.frame:GetLeft(), math.floor(left - c.frame:GetLeft()) - 6, key .. ': 6 left of what the control draws')
			check(c.label:GetLeft() + c.label:GetWidth() <= icon:GetLeft() - 4, key .. ': the label ends before it')
			if key == 'multi' then
				eq(mid(icon), c.frame:GetTop() - math.floor(c.rowHeight / 2), 'multi: centred on its first band')
			else
				eq(mid(icon), mid(c.frame), key .. ': centred on the row')
			end
			check(icon:GetFrameLevel() > c.frame:GetFrameLevel(), key .. ': over its row')
		end
		-- The item: against its dots, its label ending before it.
		local item = by.item
		check(shown(item), 'item: its reset shows')
		eq(icon_of(item):GetRight(), item.widget.dots:GetLeft(), 'item: right against its dots')
		check(item.label:GetLeft() + item.label:GetWidth() <= icon_of(item):GetLeft() - 4, 'item: its label ends before it')
		eq(item.lineEnd, icon_of(item):GetLeft() - 4 - item.frame:GetLeft(), 'and its hover line')
		-- The block: no label; after the block, on its first line.
		local block = by.position
		check(shown(block), 'position: its reset shows')
		eq(icon_of(block):GetLeft() - block.frame:GetLeft(), math.ceil(block.widget:GetWidth()) + 6, 'position: 6 after the block')
		eq(block.frame:GetTop() - icon_of(block):GetTop(), 11, 'on its first line')
		-- Nothing to reset on a button or a description.
		check(not shown(by.go), 'execute: none')
		check(not shown(by.words), 'description: none')
		body:Release()
	end)
end)

test("the icon's tooltip says what it does and names the default by the row's type; a click resets with no confirm and draws again", function()
	in_look('thick', function(tip)
		fresh()
		for _, key in ipairs({ 'toggle', 'range', 'select', 'input', 'color', 'keybinding', 'multi', 'item', 'position' }) do differs[key] = true end
		local told = {}
		local body, by = draw(Page(Args()), function(ok) told[#told + 1] = tostring(ok) end)
		local want = {
			toggle = 'A toggle goes back to its default: off.',
			range = 'A range goes back to its default: 25%.',
			select = 'A select goes back to its default: Apple.',
			input = 'An input goes back to its default: Text.',
			color = 'A color goes back to its default: #FF0000 \194\183 50%.',
			keybinding = 'A key goes back to its default: Not bound.',
			multi = 'A multiselect goes back to its default: A only.',
			item = "Hotkey's Show goes back to its default: on.",
			position = 'Position goes back to its default: the middle.',
		}
		-- Text > Muted at rest; under the mouse it lights, in the lighter tone of the accent (a glyph, the states helper's).
		local function rgb(icon) return string.format('%.2f,%.2f,%.2f', icon.icon:GetVertexColor()) end
		local grey = string.format('%.2f,%.2f,%.2f', st.config.profile.colors.text.muted:GetRGB())
		local blue = string.format('%.2f,%.2f,%.2f', st:StateColor('edgeHover'))
		check(grey ~= blue, 'two colors')
		for key, line in pairs(want) do
			local icon = icon_of(by[key])
			eq(rgb(icon), grey, key .. ': Text > Muted at rest')
			stub.fire_script(icon, 'OnEnter', true)
			eq(tip.lines[1], 'Reset', key .. ': titled Reset')
			eq(tip.lines[2], line, key)
			eq(rgb(icon), blue, key .. ': the lighter tone under the mouse')
			stub.fire_script(icon, 'OnLeave', true)
			eq(tip.owner, nil, key .. ': its tooltip goes')
			eq(rgb(icon), grey, key .. ': grey again')
		end

		stub.click(icon_of(by.color))
		eq(table.concat(resets, ','), 'color', 'its reset ran')
		eq(W.ConfirmText(), nil, 'with no confirm')
		eq(table.concat(told, ','), 'true', 'then onChanged(true): the page draws again')
		body:Release()
		body, by = draw(Page(Args()))
		check(not shown(by.color), 'drawn again: at its default, none')
		body:Release()
	end)
end)

test("a font list's reset tooltip names the face, not the file its list maps the name to", function()
	in_look('thick', function(tip)
		fresh()
		differs.font = true
		local args = { font = { type = 'select', name = 'Typeface', desc = 'x', order = 1, dialogControl = 'LSM30_Font',
			values = { Homespun = 'Interface\\AddOns\\SaftUI-Core\\Media\\Fonts\\homespun.ttf', Colus = 'colus.otf' },
			get = function() return 'Colus' end, set = function() end,
			default = Default({ value = function() return 'Homespun' end }) } }
		local body, by = draw({ page = { type = 'group', name = 'Page', args = args } })
		local icon = icon_of(by.font)
		stub.fire_script(icon, 'OnEnter', true)
		eq(tip.lines[1], 'Reset')
		eq(tip.lines[2], 'Typeface goes back to its default: Homespun.')
		stub.fire_script(icon, 'OnLeave', true)
		body:Release()
	end)
end)

test('no reset on a disabled row, nor on a member page row (its share Resets it); a source page row has it, its hover line short of it', function()
	in_look('thick', function()
		fresh()
		differs.range, differs.select = true, true
		local args = Args()
		args.range.disabled = true
		local member = { source = 'Everything', page = 'Third', own = function() return true end, reset = function() end,
			shared = function() return '1' end, targets = function() return {} end }
		args.select.share = member
		local body, by = draw(Page(args))
		check(not shown(by.range), 'disabled: none')
		check(not shown(by.select), 'a member page row: none')
		check(by.select.frame.share.mark:IsShown(), "its share's mark instead")
		body:Release()

		args = Args()
		args.select.share = { source = 'Everything', differs = function() return { { name = 'Third', value = 'Apple' } } end,
			shared = function() return 'Banana' end, targets = function() return {} end, applyAll = function() end, apply = function() end }
		body, by = draw(Page(args))
		local c = by.select
		check(shown(c), 'a source page row: its own reset')
		eq(c.lineEnd, icon_of(c):GetLeft() - 4 - c.frame:GetLeft(), 'its hover line ends before it')
		stub.fire_script(c.frame, 'OnEnter', true)
		check(c.frame.share.line:IsShown(), 'its line')
		check(c.frame.share.line:GetRight() <= icon_of(c):GetLeft() - 4, 'short of the icon')
		check(c.frame.share.diff:GetRight() <= icon_of(c):GetLeft(), 'and so is the diff icon')
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(c.frame.share.line, 'OnUpdate', 0.01)
		body:Release()
	end)
end)

test("Blizzard: the same icon, left of the control's art", function()
	in_look('blizzard', function()
		fresh()
		for _, key in ipairs(CONTROLS) do differs[key] = true end
		local body, by = draw(Page(Args()))
		local reaches = 0
		for _, key in ipairs(CONTROLS) do
			local c = by[key]
			check(shown(c), key .. ': shown')
			local left = leftmost(c.widget.frame)
			if left < c.widget.frame:GetLeft() then reaches = reaches + 1 end
			eq(icon_of(c):GetRight() - c.frame:GetLeft(), math.floor(left - c.frame:GetLeft()) - 6, key .. ": 6 left of its art")
		end
		check(reaches >= 1, "some art reaches past its frame (the dropdown's glow), and the icon keeps clear of it")
		body:Release()
	end)
end)

-- A page of one quarter item named name, its menu's dots, its reset showing
-- while differs.on, and with diffs a source page's share whose diff icon shows.
local function ItemPage(name, differs, diffs)
	local item = { type = 'item', name = name, desc = 'x', order = 1, size = 'small',
		get = function() return true end, set = function() end,
		menu = { type = 'group', name = name, args = {} },
		default = { differs = function() return differs.on end, reset = function() end, value = function() return false end } }
	if diffs then
		item.share = { source = 'All bars', shared = function() return 'on' end,
			differs = function() return { { name = 'Bar 3', value = 'off' } } end }
	end
	return { page = { type = 'group', name = 'Page', args = { item = item } } }
end

test("an item's reset sits against its dots: its label gives up only the icon and its gap (12), so a quarter's Macro name isn't cut", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			-- The label's width with the reset and without: 12 apart (the icon's 14
			-- and its gap of 4, less the 6 the label already keeps from the dots).
			local differs = { on = false }
			local body, by = draw(ItemPage('Hotkey', differs))
			check(not shown(by.item), look .. ': at its default, no reset')
			local without = by.item.label:GetWidth()
			body:Release()
			differs.on = true
			body, by = draw(ItemPage('Hotkey', differs))
			local c = by.item
			check(shown(c), look .. ': differing, its reset')
			eq(icon_of(c):GetRight(), c.widget.dots:GetLeft(), look .. ': right against its dots')
			eq(without - c.label:GetWidth(), 12, look .. ': the label 12 shorter')
			eq(c.lineEnd, icon_of(c):GetLeft() - 4 - c.frame:GetLeft(), look .. ': its hover line ends where the label does')
			body:Release()

			-- A quarter with a long name, the reset and the diff icon showing.
			body, by = draw(ItemPage('Macro name', differs, true))
			c = by.item
			check(shown(c), look .. ': the reset shows')
			check(c.frame.share and c.frame.share.diff:IsShown(), look .. ': and the diff icon')
			eq(c.label:GetStringWidth(), c.label:GetUnboundedStringWidth(), look .. ': Macro name is not cut')
			check(c.frame.share.diff:GetRight() <= icon_of(c):GetLeft(), look .. ': its diff icon short of the reset')
			body:Release()
		end)
	end
end)

test("an item with no menu has no dots: its reset sits 6 in from the cell's edge, and the label gives up its room", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			local differs = { on = true }
			local page = ItemPage('Hotkey', differs)
			page.page.args.item.menu = nil
			local body, by = draw(page)
			local c = by.item
			check(shown(c), look .. ': its reset shows')
			check(not c.widget.hasMenu, look .. ': no menu')
			eq(c.frame:GetRight() - icon_of(c):GetRight(), 6, look .. ": 6 from the cell's right edge")
			body:Release()
		end)
	end
end)

test("a color field's reset sits where a select's does, under Thick and Blizzard", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			fresh()
			differs.select, differs.color = true, true
			local body, by = draw(Page(Args()))
			local function from_right(c) return c.frame:GetRight() - icon_of(c):GetRight() end
			check(shown(by.color) and shown(by.select), look .. ': both show')
			eq(from_right(by.color), from_right(by.select), look .. ': the same place from the cell\'s right')
			body:Release()
		end)
	end
end)

test("a color with a toggle: one reset for both, left of the field with its box; it shows when either differs and puts both back", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			local on, color = false, { 0.5, 0.5, 0.5 }
			local function page()
				return Page({
					tint = { type = 'color', name = 'Tint', desc = 'x', order = 1,
						get = function() return unpack(color) end,
						set = function(_, r, g, b) color = { r, g, b } end,
						toggle = { get = function() return on end, set = function(_, v) on = v end, offText = 'Class' },
						default = {
							differs = function() return on ~= false or color[1] ~= 0.25 end,
							reset = function() on, color = false, { 0.25, 0.25, 0.25 } end,
							value = function() return 0.25, 0.25, 0.25 end,
						} },
					position = st.Config.generators.position(2, false, function(part) return pos[part] end,
						function(part, value) pos[part] = value end, nil, 'Where it sits.', 'Position'),
				})
			end
			local body, by = draw(page())
			check(shown(by.tint), look .. ': the color differs from its default, so the reset shows')
			local icon = icon_of(by.tint)
			eq(icon:GetRight() - by.tint.frame:GetLeft(), math.floor(leftmost(by.tint.widget.frame) - by.tint.frame:GetLeft()) - 6,
				look .. ': 6 left of the field, the box in it included')
			click(icon)
			eq(tostring(on) .. ',' .. color[1], 'false,0.25', look .. ': a click puts the toggle and the color back')
			body:Release()
			on, color = true, { 0.25, 0.25, 0.25 }
			body, by = draw(page())
			check(shown(by.tint), look .. ': the toggle alone differing shows it too')
			body:Release()
			on = false
			body, by = draw(page())
			check(not shown(by.tint), look .. ': both at their defaults: none')
			body:Release()
		end)
	end
end)

test('the icon follows a drag: shown once the dragged value differs, gone back at the default', function()
	in_look('thick', function()
		fresh()
		local level = 3
		local args = Args()
		args.level = { type = 'range', name = 'Level', desc = 'x', order = 0.5, min = 0, max = 10, step = 1,
			get = function() return level end, set = function(_, v) level = v end,
			default = { differs = function() return level ~= 3 end, reset = function() level = 3 end } }
		local body, by
		body, by = draw(Page(args), function(ok, err, isDragging, widget)
			if isDragging then body:Refresh(widget) end
		end)
		check(not shown(by.level), 'at its default')
		local slider = by.level.widget
		stub.mouse_buttons.LeftButton = true
		slider.dragging = true
		slider:Commit(6)
		check(shown(by.level), 'dragged off it: shown')
		slider:Commit(3)
		check(not shown(by.level), 'back: gone')
		stub.mouse_buttons.LeftButton = nil
		slider.dragging = nil
		body:Release()
	end)
end)

-- Mid-drag the body draws nothing again (Body:Refresh), so as another row's
-- icon comes and goes with the dragged value, its label and its open hover
-- line follow it in place: cut short of the icon while it shows, their own
-- width again once it goes. A quarter toggle on a source page, a page
-- differing: its line, 'Apply to: All | Multiple', fits the cell without the
-- icon and not with it, so it drops 'Apply to:' while the icon shows.
test("mid-drag, another row's label and hover line make room for its icon as it comes, and take it back as it goes", function()
	in_look('thick', function()
		fresh()
		local level = 3
		local args = Args()
		args.level = { type = 'range', name = 'Level', desc = 'x', order = 0.5, min = 0, max = 10, step = 1,
			get = function() return level end, set = function(_, v) level = v end }
		args.flag = { type = 'toggle', name = 'Flag', desc = 'x', order = 0.6, size = 'small',
			get = function() return true end, set = function() end,
			share = { source = 'Everything', differs = function() return { { name = 'Third', value = 'off' } } end, shared = function() return 'on' end,
				targets = function() return {} end, applyAll = function() end, apply = function() end },
			default = { differs = function() return level ~= 3 end, reset = function() level = 3 end } }
		-- And a half toggle with no share: its label is what the icon cuts.
		args.plain = { type = 'toggle', name = 'Plain', desc = 'x', order = 0.7,
			get = function() return true end, set = function() end,
			default = { differs = function() return level ~= 3 end, reset = function() level = 3 end } }
		local body, by
		body, by = draw(Page(args), function(ok, err, isDragging, widget)
			if isDragging then body:Refresh(widget) end
		end)
		local c, plain = by.flag, by.plain
		local plainWidth = plain.label:GetWidth()
		check(not shown(c), 'no icon at its default')
		local labelWidth, parts = c.label:GetWidth(), c.frame.share
		stub.fire_script(c.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'its hover line')
		check(parts.sep:IsShown(), "'Apply to:' fits without the icon")
		local lineWidth = parts.line:GetWidth()

		local slider = by.level.widget
		stub.mouse_buttons.LeftButton = true
		slider.dragging = true
		slider:Commit(6)
		check(shown(c), 'dragged: its icon shows')
		local stop = icon_of(c):GetLeft() - 4 - c.frame:GetLeft()
		eq(c.lineEnd, stop, 'its line ends 4 before the icon')
		check(c.label:GetWidth() <= stop, 'and so does its label')
		local plainStop = icon_of(plain):GetLeft() - 4 - plain.frame:GetLeft()
		eq(plain.label:GetWidth(), plainStop, "the plain row's label cut 4 before its icon")
		check(parts.line:GetRight() <= icon_of(c):GetLeft() - 4, 'the line, cut again, short of the icon')
		check(not parts.sep:IsShown(), "'Apply to:' dropped to fit")

		slider:Commit(3)
		check(not shown(c), 'back at the default: gone')
		eq(c.lineEnd, nil, "its line's own end again")
		eq(c.label:GetWidth(), labelWidth, 'its label its own width again')
		eq(plain.label:GetWidth(), plainWidth, "the plain row's label its own width again")
		eq(plain.lineEnd, nil, "and its line's end")
		check(parts.sep:IsShown(), "'Apply to:' back")
		eq(parts.line:GetWidth(), lineWidth, 'the whole line again')
		stub.mouse_buttons.LeftButton = nil
		slider.dragging = nil
		body:Release()
	end)
end)

-- A custom type (W.Define) draws its own frames and leaves a default alone:
-- no icon, though its differs says it differs, bare or with a label; the
-- built-in toggle beside them shows its own.
test('a custom type leaves its default alone: no icon, though it differs', function()
	in_look('thick', function()
		local function build(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(60, 20)
		end
		W.Define('defaultsbare', { bare = true, build = build, methods = { Refresh = function() end } })
		W.Define('defaultsrow', { width = 60, build = build, methods = { Refresh = function() end } })
		local always = { differs = function() return true end, reset = function() end }
		local root = { page = { type = 'group', name = 'Page', get = function() return true end, set = function() end, args = {
			bare = { type = 'defaultsbare', name = 'Bare', size = 'wide', order = 1, default = always },
			row = { type = 'defaultsrow', name = 'Row', order = 2, default = always },
			toggle = { type = 'toggle', name = 'Toggle', order = 3, default = always },
		} } }
		local body, by = draw(root)
		check(by.bare and by.row, 'both drawn')
		check(shown(by.toggle), 'the toggle shows its icon')
		check(not shown(by.bare), 'a bare custom type: none')
		check(not shown(by.row), 'a custom type with a label: none')
		body:Release()
	end)
end)

------------------------------------------------------------------ in a menu

local menuDiffers, menuResets = false, 0
local DMD = st:NewModule('DefaultsMenu')
function DMD:GetConfigTable()
	return {
		name = 'Defaults menu', type = 'group', category = 'Frames',
		args = {
			hotkey = { type = 'item', name = 'Hotkey', desc = 'x', order = 1, size = 'small', get = false,
				menu = { type = 'group', name = 'Hotkey', args = {
					size = { type = 'range', name = 'Size', desc = 'Its size.', order = 1, min = 6, max = 20, step = 1,
						get = function() return 10 end, set = function() end,
						default = { differs = function() return menuDiffers end,
							reset = function() menuDiffers, menuResets = false, menuResets + 1 end,
							value = function() return 12 end } },
				} } },
		},
	}
end

test('in an item\'s menu: the icon by its control, and a click resets and draws the menu again', function()
	menuDiffers, menuResets = true, 0
	local _, restore = watch_tooltip()
	st.Config:Open('DefaultsMenu')
	click(cell('hotkey').widget.dots)
	local M = OW.GetMenuFrames()
	local size
	for _, c in ipairs(M.body.cells) do if c.row.key == 'size' then size = c end end
	check(shown(size), 'shown in the menu')
	check(icon_of(size):GetRight() < size.widget.frame:GetLeft(), 'left of the control')
	stub.click(icon_of(size))
	eq(menuResets, 1, 'its reset ran')
	check(OW:IsMenuShown(), 'the menu stays')
	for _, c in ipairs(M.body.cells) do if c.row.key == 'size' then size = c end end
	check(not shown(size), 'drawn again: none')
	close_all()
	restore()
end)

------------------------------------------------------------------ Global settings' Colors and Theme

-- The drawn color row of group (the Colors tab's section key) and key.
local function colorCell(group, key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key and c.row.path[#c.row.path - 1] == group then return c end
	end
end

test("Global settings' Colors and Theme: no Reset buttons; a changed color's own reset by its bar puts it back", function()
	local tip, restore = watch_tooltip()
	local ok, err = pcall(function()
		st.Config:Open('Fonts', 'colors')
		for _, c in ipairs(OW.GetDrawnRows()) do
			check(c.row.type ~= 'execute', 'colors: no button: ' .. tostring(c.row.key))
			check(not shown(c), 'colors: every color at its default: no reset')
		end
		local mage = st.config.profile.colors.class.MAGE
		local r, g, b = mage.r, mage.g, mage.b
		local changed = {}
		local probe = st:NewModule('DefaultsColorsProbe')
		probe.OnColorsChanged = function(_, group) changed[#changed + 1] = group end
		cell('MAGE').widget:Commit(0.1, 0.2, 0.3)
		local c = cell('MAGE')
		check(shown(c), "Mage's reset shows")
		eq(icon_of(c):GetRight(), math.floor(leftmost(c.widget.frame)) - 6, 'left of its bar')
		stub.fire_script(icon_of(c), 'OnEnter', true)
		local d = st.defaults.colors.class.MAGE
		eq(tip.lines[2], ('Mage goes back to its default: %s.'):format(W.HexText(d.r, d.g, d.b, 1, false)), 'naming its hex')
		stub.fire_script(icon_of(c), 'OnLeave', true)
		-- Its colors are read as it's painted: a new Text > Muted at rest once
		-- drawn again, a new Theme > Accent lit on its next hover.
		local function rgb(icon) return string.format('%.2f,%.2f,%.2f', icon.icon:GetVertexColor()) end
		local accent = st.config.profile.theme.accent
		colorCell('text', 'muted').widget:Commit(0.3, 0.6, 0.9)
		eq(rgb(icon_of(cell('MAGE'))), '0.30,0.60,0.90', 'a new Text > Muted at rest, drawn again')
		accent:SetRGB(0.9, 0.1, 0.2)
		colorCell('text', 'muted').widget:Commit(0.3, 0.6, 0.9) -- drawn again
		eq(rgb(icon_of(cell('MAGE'))), '0.30,0.60,0.90', 'still grey at rest')
		stub.fire_script(icon_of(cell('MAGE')), 'OnEnter', true)
		eq(rgb(icon_of(cell('MAGE'))), string.format('%.2f,%.2f,%.2f', st:StateColor('edgeHover')), 'the new accent\'s lighter tone under the mouse')
		stub.fire_script(icon_of(cell('MAGE')), 'OnLeave', true)
		stub.click(icon_of(colorCell('text', 'muted')))
		accent:SetRGB(0, 0.68, 0.94)
		c = cell('MAGE')
		for i = #changed, 1, -1 do changed[i] = nil end
		stub.click(icon_of(c))
		eq(mage.r .. ',' .. mage.g .. ',' .. mage.b, r .. ',' .. g .. ',' .. b, 'Mage back to its default')
		eq(table.concat(changed, ','), 'class', 'its group told, as the section Reset did')
		check(not shown(cell('MAGE')), 'drawn again: none')
		probe.OnColorsChanged = nil

		-- A Buttons color names its opacity when its default is under 100%; the defaults are 100% now.
		local hover = st.config.profile.colors.button.hover
		colorCell('button', 'hover').widget:Commit(hover.r, hover.g, hover.b, 0.5)
		stub.fire_script(icon_of(colorCell('button', 'hover')), 'OnEnter', true)
		local db = st.defaults.colors.button.hover
		eq(tip.lines[2], ('Hover goes back to its default: %s.'):format(W.HexText(db.r, db.g, db.b, db.a, true)), 'with its opacity')
		check(tip.lines[2]:find('%%') == nil, "no percent: the default is Buttons' own 100%")
		stub.click(icon_of(colorCell('button', 'hover')))
		eq(hover.a, db.a, 'its opacity back')

		-- Theme: no Reset; Background names its opacity.
		OW:Navigate('Fonts', { tab = 'theme' })
		for _, each in ipairs(OW.GetDrawnRows()) do check(each.row.type ~= 'execute', 'theme: no button') end
		local theme = st.config.profile.theme
		local was = theme.opacity
		local back = cell('background')
		local br, bg, bb = back.widget.r, back.widget.g, back.widget.b
		back.widget:Commit(br, bg, bb, 0.5)
		check(shown(cell('background')), "Background's reset shows for its opacity")
		stub.fire_script(icon_of(cell('background')), 'OnEnter', true)
		check(tip.lines[2]:find(math.floor(st.defaults.theme.opacity * 100 + 0.5) .. '%%') ~= nil, 'naming the default opacity: ' .. tostring(tip.lines[2]))
		stub.click(icon_of(cell('background')))
		eq(theme.opacity, was, 'its opacity back')
		check(not shown(cell('background')), 'none')
	end)
	restore()
	close_all()
	if not ok then error(err, 0) end
end)

------------------------------------------------------------------ derived defaults

-- A page whose defaults are derived from where it is saved (optionsdefault.lua),
-- one row of every built-in type with a value but a font.
local DERIVED = {
	toggle = true, range = 0.25, select = 'a', input = '', keybinding = '',
	color = { r = 1, g = 0, b = 0, a = 0.5 }, multi = { a = true, b = true }, item = true,
	position = { point = 'TOPRIGHT', rel_point = 'TOPRIGHT', frame = 'UIParent', x_off = -320, y_off = -275 },
}
local dv
local function derived_reset()
	st.defaults.dv_ = st.tablecopy(DERIVED, true)
	dv = st.tablecopy(DERIVED, true)
	st.config.profile.dv_ = dv
end
local function DerivedPage()
	return { page = { type = 'group', name = 'Page', args = {
		toggle = { type = 'toggle', name = 'A toggle', desc = 'x', order = 1 },
		range = { type = 'range', name = 'A range', desc = 'x', order = 2, min = 0, max = 1, step = 0.01, isPercent = true },
		select = { type = 'select', name = 'A select', desc = 'x', order = 3, values = { a = 'Apple', b = 'Banana' } },
		input = { type = 'input', name = 'Name', desc = 'x', order = 4 },
		keybinding = { type = 'keybinding', name = 'Key', desc = 'x', order = 5 },
		color = { type = 'color', name = 'A color', desc = 'x', order = 6, hasAlpha = true,
			get = function() local c = dv.color; return c.r, c.g, c.b, c.a end,
			set = function(_, r, g, b, a) dv.color = { r = r, g = g, b = b, a = a } end,
			saved = st.Config.SavedAt('dv_', 'color') },
		multi = { type = 'multiselect', name = 'Show in', desc = 'x', order = 7, values = { a = 'Bags', b = 'Bank', c = 'Other' },
			get = function(_, key) return dv.multi[key] end,
			set = function(_, key, value) dv.multi[key] = value end,
			saved = st.Config.SavedAt('dv_', 'multi') },
		item = { type = 'item', name = 'Hotkey', desc = 'x', order = 8, size = 'small',
			get = function() return dv.item end, set = function(_, value) dv.item = value end,
			saved = st.Config.SavedAt('dv_', 'item'),
			menu = { type = 'group', name = 'Hotkey', args = {} } },
		position = st.Config.generators.position(9, true, function(part) return dv.position[part] end,
			function(part, value) dv.position[part] = value end, nil, 'Where it sits.', 'Position',
			st.Config.SavedAt('dv_', 'position')),
	}, get = function(info) return dv[info[#info]] end, set = function(info, value) dv[info[#info]] = value end,
		saved = st.Config.SavedIn('dv_') } }
end
local DERIVED_KEYS = { 'toggle', 'range', 'select', 'input', 'keybinding', 'color', 'multi', 'item', 'position' }
local function change_all()
	dv.toggle, dv.range, dv.select, dv.input, dv.keybinding = false, 0.5, 'b', 'Bob', 'F'
	dv.color = { r = 0, g = 1, b = 0, a = 1 }
	dv.multi = { a = false, b = true }
	dv.item = false
	dv.position = { point = 'CENTER', rel_point = 'CENTER', frame = 'UIParent', x_off = 10, y_off = 10 }
end

test('a derived row shows the icon only while it differs, on every built-in type, under Thick and Blizzard', function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function(tip)
			derived_reset()
			local body, by = draw(DerivedPage())
			for _, key in ipairs(DERIVED_KEYS) do check(not shown(by[key]), look .. ' ' .. key .. ': at its default, none') end
			body:Release()

			change_all()
			body, by = draw(DerivedPage())
			for _, key in ipairs(DERIVED_KEYS) do
				local c = by[key]
				check(shown(c), look .. ' ' .. key .. ': it differs, its reset shows')
				local icon = icon_of(c)
				eq(icon:GetWidth() .. 'x' .. icon:GetHeight(), '14x14', key .. ': the same icon')
				if key == 'position' then
					eq(icon_of(c):GetLeft() - c.frame:GetLeft(), math.ceil(c.widget:GetWidth()) + 6, 'position: 6 after the block')
				elseif key == 'item' then
					eq(icon:GetRight(), c.widget.dots and c.widget.dots:GetLeft() or c.frame:GetRight() - 6, 'item: by its dots or the edge')
				else
					local left = leftmost(c.widget.frame)
					eq(icon:GetRight() - c.frame:GetLeft(), math.floor(left - c.frame:GetLeft()) - 6, key .. ': 6 left of what the control draws')
					check(c.label:GetLeft() + c.label:GetWidth() <= icon:GetLeft() - 4, key .. ': the label ends before it')
				end
			end

			-- A click on each puts the default back through its set, and the page draws again.
			for _, key in ipairs(DERIVED_KEYS) do
				local told = {}
				body:Release()
				body, by = draw(DerivedPage(), function(ok) told[#told + 1] = tostring(ok) end)
				stub.click(icon_of(by[key]))
				eq(table.concat(told, ','), 'true', key .. ': then onChanged(true)')
				body:Release()
				body, by = draw(DerivedPage())
				check(not shown(by[key]), look .. ' ' .. key .. ': after its reset, none')
			end
			eq(dv.toggle, true, 'toggle back')
			eq(dv.input, '', 'input back as text')
			eq(dv.multi.a, true, 'multiselect back')
			eq(dv.color.a, 0.5, 'color back, alpha too')
			eq(dv.position.point, 'TOPRIGHT', 'position back')
			check(dv.position ~= st.defaults.dv_.position and dv.color ~= st.defaults.dv_.color, 'tables are copies, not the ones in st.defaults')
			body:Release()
		end)
	end
end)

test("the tooltip's new words: a multiselect's labels or none, an input's text or empty, a key or Not bound, a position in words", function()
	in_look('thick', function(tip)
		derived_reset()
		change_all()
		local body, by = draw(DerivedPage())
		local function line(key)
			stub.fire_script(icon_of(by[key]), 'OnEnter', true)
			local text = tip.lines[2]
			stub.fire_script(icon_of(by[key]), 'OnLeave', true)
			return text
		end
		eq(line('multi'), 'Show in goes back to its default: Bags, Bank.', "a multiselect's ticked labels")
		eq(line('input'), 'Name goes back to its default: empty.', 'an empty input')
		eq(line('keybinding'), 'Key goes back to its default: Not bound.', 'no key')
		eq(line('position'), 'Position goes back to its default: Top right of the screen: -320, -275.', 'a position in words')
		eq(line('toggle'), 'A toggle goes back to its default: on.', 'a toggle')
		eq(line('range'), 'A range goes back to its default: 25%.', 'a percent range')
		eq(line('color'), 'A color goes back to its default: #FF0000 \194\183 50%.', 'a color with its opacity')
		body:Release()

		st.defaults.dv_.multi, st.defaults.dv_.input, st.defaults.dv_.keybinding = {}, 'Words', 'F5'
		dv.multi = { a = true }
		body, by = draw(DerivedPage())
		eq(line('multi'), 'Show in goes back to its default: none.', 'a multiselect with none ticked')
		eq(line('input'), 'Name goes back to its default: Words.', 'an input with text')
		eq(line('keybinding'), 'Key goes back to its default: F5.', 'a key')
		body:Release()
	end)
end)

test('a failed reset says why on the status line and keeps the icon', function()
	in_look('thick', function()
		derived_reset()
		change_all()
		local root = DerivedPage()
		root.page.validate = function(_, value) if value == 'Bob' then return 'nope' end return true end
		-- The input's default is refused by a validate: the page's own.
		st.defaults.dv_.input, dv.input = 'Bob', 'other'
		local told
		local content = CreateFrame('Frame', nil, UIParent)
		content:SetSize(774, 900)
		local body = OB.New(content, root, function(...) told = { ... } end, 774)
		body:Draw(OM.BuildView(root, 'page').sections)
		local cell
		for _, c in ipairs(body.cells) do if c.row.key == 'input' then cell = c end end
		check(shown(cell), 'it differs')
		stub.click(icon_of(cell))
		eq(told and told[1], false, 'onChanged(false, message)')
		eq(told and told[2], 'nope', 'with the validation message')
		eq(dv.input, 'other', 'nothing was written')
		body:Release()
	end)
end)

test('a titled custom row with a default: the icon 6 after its title, the title cut for it', function()
	in_look('thick', function()
		local function build(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(60, 20)
		end
		W.Define('derivedtitled', { bare = true, titled = true, build = build, methods = { Refresh = function() end } })
		local differsNow = true
		local always = { differs = function() return differsNow end, reset = function() end }
		local root = { page = { type = 'group', name = 'Page', args = {
			short = { type = 'derivedtitled', name = 'Rule', size = 'wide', order = 1, default = always },
			long = { type = 'derivedtitled', name = string.rep('A very long title ', 20), size = 'wide', order = 2, default = always },
			none = { type = 'derivedtitled', name = 'No reset', size = 'wide', order = 3 },
		} } }
		local body, by = draw(root)
		local c = by.short
		check(shown(c), 'it differs: its reset shows')
		local text = math.ceil(c.label:GetUnboundedStringWidth())
		eq(icon_of(c):GetLeft() - c.frame:GetLeft(), text + 6, '6 after its title\'s text')
		eq(icon_of(c):GetTop() - c.frame:GetTop(), -7, 'centred on the title line (6 down, a 16 line)')
		check(c.label:GetLeft() + math.min(text, c.label:GetWidth()) <= icon_of(c):GetLeft() - 4, 'the title ends before it')
		local long = by.long
		check(shown(long), 'a long title: its reset shows')
		eq(icon_of(long):GetLeft() - long.frame:GetLeft(), long.frame:GetWidth() - 14, 'at the cell\'s edge when the title fills the line')
		eq(long.label:GetWidth(), long.frame:GetWidth() - 14 - 4, 'the title cut to leave it room and 4')
		check(not shown(by.none), 'a titled row with no default: none')
		differsNow = false
		body:Release()
		body, by = draw(root)
		check(not shown(by.short), 'at its default: none')
		eq(by.short.label:GetWidth(), by.short.frame:GetWidth(), 'and the title is whole again')
		body:Release()
	end)
end)

test('the derived icons and the titled row\'s sit on whole pixels, under Thick, Thin and Blizzard, with size noise', function()
	local P = load_test_file('lib/pixels.lua')
	local function build(w)
		w.frame = CreateFrame('Frame', nil, UIParent)
		w.frame:SetSize(60, 20)
	end
	W.Define('derivedtitled', { bare = true, titled = true, build = build, methods = { Refresh = function() end } })
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		in_look(look, function()
			derived_reset()
			change_all()
			local page = DerivedPage()
			page.page.args.rule = { type = 'derivedtitled', name = 'Rule', size = 'wide', order = 20,
				default = { differs = function() return true end, reset = function() end } }
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				stub.size_noise = noise
				local body, by, content = draw(page)
				check(shown(by.toggle) and shown(by.rule) and shown(by.position), look .. ': the icons show')
				local off = P.off(content)
				eq(#off, 0, look .. ' noise ' .. noise .. ': ' .. P.report(off))
				body:Release()
			end
			stub.size_noise = 0
		end)
	end
end)

test('a derived row\'s icon follows a drag: Body:Refresh places it for every row with a source, and takes it back', function()
	in_look('thick', function()
		derived_reset()
		local body, by = draw(DerivedPage())
		check(not shown(by.range), 'at its default: none')
		dv.range = 0.9 -- what a drag of another row's preview does to this one
		body:Refresh()
		check(shown(by.range), 'after Refresh the derived row shows its icon')
		dv.range = 0.25
		body:Refresh()
		check(not shown(by.range), 'and loses it at its default')
		dv.position = { point = 'CENTER', rel_point = 'CENTER', frame = 'UIParent', x_off = 10, y_off = 10 }
		body:Refresh()
		check(shown(by.position), 'a position row too')
		body:Release()

		-- A mover's Position.
		local frame = CreateFrame('Frame', 'DragMoverFrame', UIParent)
		local cfg = { position = { point = 'CENTER', rel_point = 'CENTER', frame = 'UIParent', x_off = 0, y_off = 0 } }
		st:RegisterConfigMover(frame, { key = 'dv_drag', label = 'Drag', config = function() return cfg end, apply = function() end,
			configPath = { 'page', 'general' }, getDefaultPosition = function() return { point = 'CENTER', rel_point = 'CENTER', frame = 'UIParent', x_off = 0, y_off = 0 } end })
		local root = { page = { type = 'group', name = 'Page', args = { general = { type = 'group', name = 'General', args = {
			position = st.Config.generators.position(1, true, function(part) return cfg.position[part] end,
				function(part, value) cfg.position[part] = value end) } } } } }
		local content = CreateFrame('Frame', nil, UIParent)
		content:SetSize(774, 900)
		body = OB.New(content, root, nil, 774)
		body:Draw(OM.BuildView(root, 'page', { tab = 'general' }).sections)
		local cell
		for _, c in ipairs(body.cells) do if c.row.key == 'position' then cell = c end end
		check(cell and not shown(cell), 'a mover row at its default: none')
		cfg.position.x_off = 40
		body:Refresh()
		check(shown(cell), 'moved: its icon shows on Refresh')
		body:Release()
		st.EditModeFrames.movers.dv_drag = nil
	end)
end)

test('a long title\'s hover frame stops short of the reset icon', function()
	in_look('thick', function()
		local function build(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(60, 20)
		end
		W.Define('derivedtitled', { bare = true, titled = true, build = build, methods = { Refresh = function() end } })
		local root = { page = { type = 'group', name = 'Page', args = {
			long = { type = 'derivedtitled', name = string.rep('A very long title ', 20), size = 'wide', order = 1,
				default = { differs = function() return true end, reset = function() end } },
			short = { type = 'derivedtitled', name = 'Rule', size = 'wide', order = 2,
				default = { differs = function() return true end, reset = function() end } },
		} } }
		local body, by = draw(root)
		for _, key in ipairs({ 'long', 'short' }) do
			local c = by[key]
			local tip = c.frame.titleTip
			check(tip and tip:IsShown(), key .. ': the title has its hover frame')
			check(tip:GetRight() <= icon_of(c):GetLeft(), key .. ': it ends before the icon (' .. tostring(tip:GetRight()) .. ' vs ' .. tostring(icon_of(c):GetLeft()) .. ')')
		end
		body:Release()
	end)
end)

test('placing a shown icon on every drag step builds no tables of its own: DrawnLeft walks regions as varargs', function()
	-- The stubs allocate on every layout read and SetPoint, so bytes can't pin it; the walk's own
	-- tables (one per region, two per control) were the kit's, and the source says there are none.
	local source = read_saftui_source('SaftUI-Core/Config/optionsshare.lua')
	local from = source:find('DrawnLeft = function', 1, true)
	local walk = source:sub(from, source:find('\nend\n', from, true))
	check(not walk:find('{', 1, true), 'DrawnLeft makes no table of a region\'s regions or children')
	check(source:find('DrawnLeftOf(left, region:GetRegions())', 1, true) ~= nil, 'they are walked as varargs')
	in_look('blizzard', function()
		derived_reset()
		change_all()
		local body, by = draw(DerivedPage())
		for _, key in ipairs(DERIVED_KEYS) do
			local left = leftmost(by[key].widget.frame)
			if key ~= 'position' and key ~= 'item' then
				eq(icon_of(by[key]):GetRight() - by[key].frame:GetLeft(), math.floor(left - by[key].frame:GetLeft()) - 6, key .. ': the icon still clears the art')
			end
		end
		body:Release()
	end)
end)

test("the kit's reset icon is exported for the Categories list's order icon: the same button, its own tip and click", function()
	check(type(OB.ResetIcon) == 'function', 'OB.ResetIcon is there')
	in_look('thick', function()
		local parent = CreateFrame('Frame', nil, UIParent)
		local tipped, clicked = 0, 0
		local button = OB.ResetIcon(parent, function() tipped = tipped + 1 end, function() clicked = clicked + 1 end)
		eq(button:GetWidth(), 14, "the kit's 14")
		eq(button.icon:GetTexture(), st.icons.rotateCcw, "Lucide's rotate-ccw")
		stub.fire_script(button, 'OnEnter', true)
		eq(tipped, 1, 'its tip on hover')
		stub.fire_script(button, 'OnClick', true)
		eq(clicked, 1, 'and its click')
	end)
	local source = read_saftui_source('SaftUI-Bags/categoriestab.lua')
	check(source:find('OB.ResetIcon(', 1, true) ~= nil, 'the order icon draws it')
	check(not source:find('st.icons.rotateCcw', 1, true), 'and no copy of it is left')
end)
