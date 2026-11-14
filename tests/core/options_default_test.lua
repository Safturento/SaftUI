-- A setting's own reset: SaftUI's default field (SaftUI-Core/Config/
-- optionsmodel.lua's OM.DefaultState and OM.DefaultReset) and its reset icon
-- by the control (optionsshare.lua's OB.PlaceDefault, from the body's
-- PlaceRow and its Refresh), on every built-in row type, under Thick and
-- Blizzard, in an item's menu, through a drag, and on Global Settings' Colors
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
		-- The item: before its dots, its label ending before it.
		local item = by.item
		check(shown(item), 'item: its reset shows')
		eq(icon_of(item):GetRight(), item.widget.dots:GetLeft() - 6, 'item: 6 before its dots')
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
		for key, line in pairs(want) do
			local icon = icon_of(by[key])
			stub.fire_script(icon, 'OnEnter', true)
			eq(tip.lines[1], 'Reset', key .. ': titled Reset')
			eq(tip.lines[2], line, key)
			eq(string.format('%.2f,%.2f,%.2f', icon.icon:GetVertexColor()), '1.00,1.00,1.00', key .. ': white under the mouse')
			stub.fire_script(icon, 'OnLeave', true)
			eq(tip.owner, nil, key .. ': its tooltip goes')
		end
		local blue = string.format('%.2f,%.2f,%.2f', st.config.profile.colors.button.blue:GetRGB())
		eq(string.format('%.2f,%.2f,%.2f', icon_of(by.range).icon:GetVertexColor()), blue, 'Button > Blue')

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

------------------------------------------------------------------ Global Settings' Colors and Theme

-- The drawn color row of group (the Colors tab's section key) and key.
local function colorCell(group, key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key and c.row.path[#c.row.path - 1] == group then return c end
	end
end

test("Global Settings' Colors and Theme: no Reset buttons; a changed color's own reset by its bar puts it back", function()
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
		for i = #changed, 1, -1 do changed[i] = nil end
		stub.click(icon_of(c))
		eq(mage.r .. ',' .. mage.g .. ',' .. mage.b, r .. ',' .. g .. ',' .. b, 'Mage back to its default')
		eq(table.concat(changed, ','), 'class', 'its group told, as the section Reset did')
		check(not shown(cell('MAGE')), 'drawn again: none')
		probe.OnColorsChanged = nil

		-- A Buttons color names its opacity.
		local blue = st.config.profile.colors.button.blue
		colorCell('button', 'blue').widget:Commit(blue.r, blue.g, blue.b, 0.5)
		stub.fire_script(icon_of(colorCell('button', 'blue')), 'OnEnter', true)
		local db = st.defaults.colors.button.blue
		eq(tip.lines[2], ('Blue goes back to its default: %s.'):format(W.HexText(db.r, db.g, db.b, db.a, true)), 'with its opacity')
		check(tip.lines[2]:find('%%') ~= nil, 'a percent in it')
		stub.click(icon_of(colorCell('button', 'blue')))
		eq(blue.a, db.a, 'its opacity back')

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
