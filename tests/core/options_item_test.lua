-- The menu item, SaftUI's own option type 'item' (SaftUI-Core/Config/
-- optionsitem.lua): a Show box, the item's name and Lucide's ellipsis-vertical
-- dots that open its menu, drawn as a row by the body's PlaceRow (its item
-- branch, optionsbody.lua) with the shareable marks of optionsshare.lua; and
-- the body's oneColumn, widget.rowBody, and four small items making one line.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window's files, as
-- options_window_helpers.lua loads them. The pages are synthetic: item rows on
-- bodies made with OB.New, a member page (Bar 3) and a source page (All bars)
-- for the marks. The mouse is played by firing the frames' scripts, OnEnter
-- and OnLeave with true as the game passes them, and with stub.cursor_x and
-- stub.cursor_y.
load_test_file('core/options_window_helpers.lua')
local st = SaftUI
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

------------------------------------------------------------------ the synthetic pages

local shows, sets, own, differs -- each item's Show; the sets it took; the member page's own; the source page's differs

local function fresh()
	shows = { hotkey = true, count = true, macro = false, cooldown = true }
	sets, own, differs = {}, {}, {}
end
fresh()

local function MemberShare()
	return {
		source = 'All bars', page = 'Bar 3',
		own = function(info) return own[info[#info]] end,
		reset = function() end, applyAll = function() end, apply = function() end,
		shared = function() return 'Shown' end,
		targets = function() return {} end,
	}
end

local function SourceShare()
	return {
		source = 'All bars',
		differs = function(info) return differs[info[#info]] or {} end,
		shared = function() return 'Shown' end,
		applyAll = function() end, apply = function() end,
		targets = function() return {} end,
	}
end

-- An item: its Show (get and set on shows, under its key), its menu a Size
-- range. share is 'member', 'source' or nil (no share anywhere); showShare
-- false leaves its Show unshared.
local function Item(name, order, share, showShare)
	local make = share == 'member' and MemberShare or share == 'source' and SourceShare or nil
	return {
		type = 'item', name = name, desc = name .. '.', order = order, size = 'small',
		get = function(info) return shows[info[#info]] end,
		set = function(info, value)
			shows[info[#info]] = value
			sets[#sets + 1] = info[#info] .. '=' .. tostring(value)
		end,
		share = make and showShare ~= false and make() or nil,
		menu = { type = 'group', name = name, args = {
			size = { type = 'range', name = 'Size', desc = 'Its size.', order = 1, min = 6, max = 20, step = 1,
				get = function() return 10 end, set = function() end, share = make and make() or nil },
		} },
	}
end

-- The four texts, each a quarter, as the action bars' Text line will be.
local function FourItems(share)
	return {
		hotkey = Item('Hotkey', 1, share),
		count = Item('Stack count', 2, share),
		macro = Item('Macro name', 3, share),
		cooldown = Item('Cooldown', 4, share),
	}
end

local function Page(args)
	return { page = { type = 'group', name = 'Page', args = args } }
end

------------------------------------------------------------------ drawing helpers

-- A body 774 wide on a content frame at the screen's top left, the page drawn,
-- its cells by key.
local function draw(root, onChanged, opts)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 600)
	local body = OB.New(content, root, onChanged, 774, opts)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- GameTooltip, as a stand-in (the world has none): a row's OnEnter shows its tip.
local function quiet_tooltip()
	local saved, owner = _G.GameTooltip, nil
	_G.GameTooltip = {
		SetOwner = function(_, frame) owner = frame end,
		AddLine = function() end, AddDoubleLine = function() end, Show = function() end,
		IsOwned = function(_, frame) return owner == frame end,
		Hide = function() owner = nil end,
	}
	return function() _G.GameTooltip = saved end
end

-- fn under look, with GameTooltip stood in; the look, the cursor, the tooltip
-- and the list put back after.
local function in_look(look, fn)
	st.config.profile.theme.name = look
	local restore = quiet_tooltip()
	local ok, err = pcall(fn)
	W.CloseList()
	restore()
	st.config.profile.theme.name = 'thick'
	stub.cursor_x, stub.cursor_y = 0, 0
	if not ok then error(err, 0) end
end

local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function text_rgb(fs) return rgb(fs:GetTextColor()) end
local function vertex(texture) return rgb(texture:GetVertexColor()) end
local function color(group, key) return rgb(st.config.profile.colors[group][key]:GetRGB()) end
local OWN = rgb(st:Color('accent'):GetRGB())

local function x_in(region, frame) return region:GetLeft() - frame:GetLeft() end

------------------------------------------------------------------ the line of items

test('four small items make one line of quarters', function()
	local function check_line(look, xs, width, height)
		in_look(look, function()
			fresh()
			local body, by, content = draw(Page(FourItems()))
			local top
			for i, key in ipairs({ 'hotkey', 'count', 'macro', 'cooldown' }) do
				local c = by[key]
				local where = look .. ' ' .. key
				eq(x_in(c.frame, content), xs[i], where .. ': its quarter')
				eq(c.frame:GetWidth(), width, where .. ': a quarter wide')
				eq(c.height, height, where .. ': a row tall')
				top = top or c.frame:GetTop()
				eq(c.frame:GetTop(), top, where .. ': on the one line')
				eq(c.widget.frame:GetWidth(), width, where .. ': the widget spans its cell')
				eq(c.widget.frame:GetLeft(), c.frame:GetLeft(), where .. ': from its left')
				-- Its name fits beside the box and the dots.
				check(math.ceil(c.label:GetUnboundedStringWidth()) <= c.label:GetWidth(), where .. ': its name fits')
			end
			body:Release()

			-- With a diff icon after each name (the source page: every menu's Size
			-- differs on Bar 2), the names still fit.
			fresh()
			differs.size = { { name = 'Bar 2', value = '8' } }
			body, by = draw(Page(FourItems('source')))
			for _, key in ipairs({ 'hotkey', 'count', 'macro', 'cooldown' }) do
				local c = by[key]
				check(c.frame.share.diff:IsShown(), look .. ' ' .. key .. ': its diff icon')
				check(math.ceil(c.label:GetUnboundedStringWidth()) <= c.label:GetWidth(), look .. ' ' .. key .. ': its name fits beside it')
				check(c.frame.share.diff:GetRight() <= c.widget.dots:GetLeft(), look .. ' ' .. key .. ': short of the dots')
			end
			body:Release()
		end)
	end
	check_line('thick', { 14, 208, 401, 595 }, 165, 38)
	check_line('blizzard', { 0, 196, 407, 603 }, 171, 34)
end)

------------------------------------------------------------------ an item

test('an item: its Show box, its name, its dots', function()
	in_look('thick', function()
		fresh()
		local told = {}
		local root = Page(FourItems())
		local body, by = draw(root, function(ok) told[#told + 1] = tostring(ok) end)
		local c = by.hotkey
		local w = c.widget
		eq(w.type, 'item')
		check(w.box:IsShown(), 'its Show box')
		eq(x_in(w.box, c.frame), 0, "at the cell's left")
		eq(w.box:GetWidth() .. 'x' .. w.box:GetHeight(), '18x18', 'the 18 check box')
		eq(w.box:GetChecked(), true, 'checked from its get')
		check(not w.frame:IsMouseEnabled(), 'the widget takes no mouse: the row under it does')
		check(w.box:IsMouseEnabled(), 'its box does')
		check(w.dots:IsMouseEnabled(), 'and its dots')

		stub.click(w.box)
		eq(table.concat(sets, ','), 'hotkey=false', 'a click sets not the value')
		eq(table.concat(told, ','), 'true', 'then onChanged(true)')
		eq(w.box:GetChecked(), false, 'and it shows it')

		eq(c.label:GetText(), 'Hotkey', "the row's name")
		eq((select(4, c.label:GetPoint(1))), 26, 'the label 26 in')
		eq(c.labelX, 26, "the cell's labelX")
		eq(c.label:GetWidth(), 165 - 26 - 16 - 6, 'it ends 6 before the dots')

		local dots = w.dots
		eq(c.frame:GetRight() - dots:GetRight(), 0, "the dots at the cell's right end")
		eq(dots:GetWidth() .. 'x' .. dots:GetHeight(), '16x24', 'a 16 x 24 button')
		eq(dots.icon:GetTexture(), st.icons.ellipsisVertical, "Lucide's ellipsis-vertical")
		eq(dots.icon:GetWidth() .. 'x' .. dots.icon:GetHeight(), '16x16', 'at 16x16')
		eq(vertex(dots.icon), color('text', 'muted'), 'Text > Muted')
		stub.fire_script(dots, 'OnEnter', true)
		eq(vertex(dots.icon), rgb(st:StateColor('edgeHover')), 'the lighter tone under the mouse')
		stub.fire_script(dots, 'OnLeave', true)
		eq(vertex(dots.icon), color('text', 'muted'), 'grey again')

		eq(w.rowBody, body, 'widget.rowBody: the body that drew it')
		eq(by.count.widget.rowBody, body, 'every widget')
		body:Release()
		eq(w.rowBody, nil, 'cleared on release')

		-- An item with no get (get = false stops an inherited one): no box, the label at the left.
		fresh()
		local args = FourItems()
		args.cooldown.get, args.cooldown.set = false, nil
		body, by = draw(Page(args))
		c = by.cooldown
		check(not c.widget.box:IsShown(), 'no box')
		eq((select(4, c.label:GetPoint(1))), 0, "the label at the cell's left")
		eq(c.label:GetWidth(), 165 - 16 - 6, 'and wider by the box')
		body:Release()
	end)
end)

test("an item with no box that says reserveBox keeps the box's room: its name lines up with its neighbours', under both looks", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			fresh()
			local args = FourItems()
			args.cooldown.get, args.cooldown.set, args.cooldown.reserveBox = false, nil, true
			local body, by = draw(Page(args))
			local c, beside = by.cooldown, by.macro
			check(not c.widget.box:IsShown(), look .. ': no box')
			eq(c.labelX, 26, look .. ": the cell's labelX keeps the box's room")
			eq(c.label:GetLeft() - c.frame:GetLeft(), beside.label:GetLeft() - beside.frame:GetLeft(),
				look .. ": the name as far in as the next item's")
			eq(c.label:GetWidth(), beside.label:GetWidth(), look .. ': and as wide')
			body:Release()

			-- Drawn again from the pool without the field: back at the left.
			fresh()
			args = FourItems()
			args.cooldown.get, args.cooldown.set = false, nil
			body, by = draw(Page(args))
			eq(by.cooldown.labelX, 0, look .. ': without reserveBox, at the left')
			body:Release()
		end)
	end
end)

test("an item's label is grey while its Show is off, and while it's disabled", function()
	in_look('thick', function()
		fresh()
		local args = FourItems()
		args.count.disabled = true
		local body, by = draw(Page(args))
		eq(text_rgb(by.hotkey.label), color('text', 'normal'), 'shown: the text color')
		eq(text_rgb(by.macro.label), color('text', 'muted'), 'its Show off: grey')
		eq(text_rgb(by.count.label), color('text', 'muted'), 'disabled: grey')
		check(not by.count.widget.box:IsMouseEnabled(), "a disabled item's box takes no mouse")
		check(not by.count.widget.dots:IsMouseEnabled(), 'nor its dots')
		body:Release()
	end)
end)

test("an item's marks: own-marked by its menu, its diff icon short of the dots", function()
	in_look('thick', function()
		-- A member page: the menu's Size is own, its Show follows.
		fresh()
		own.size = true
		local body, by = draw(Page({ hotkey = Item('Hotkey', 1, 'member') }))
		local c = by.hotkey
		local parts = c.frame.share
		check(parts and parts.mark:IsShown(), 'marked by its menu')
		eq(text_rgb(c.label), OWN, 'its label light blue')
		eq((select(4, c.label:GetPoint(1))), 26, 'no shift under Thick')
		eq(x_in(c.widget.box, c.frame), 0, 'nor of its box')
		stub.fire_script(c.frame, 'OnEnter', true)
		check(not parts.line:IsShown(), 'no hover line: its Show is not its own')
		stub.fire_script(c.frame, 'OnLeave', true)
		body:Release()

		-- Its Show own too: the line, under the label, short of the dots. In a
		-- quarter the whole line doesn't fit, so Own and the words go: the reset
		-- icon and All | Multiple, whole.
		own.hotkey = true
		body, by = draw(Page({ hotkey = Item('Hotkey', 1, 'member') }))
		c = by.hotkey
		parts = c.frame.share
		stub.fire_script(c.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'its line')
		eq(x_in(parts.line, c.frame), 26, 'under the label')
		check(parts.line:GetRight() <= c.widget.dots:GetLeft() - 6, 'it ends 6 before the dots')
		check(not parts.ownText:IsShown() and not parts.sep:IsShown(), 'Own and the words dropped')
		check(parts.reset:IsShown() and parts.all:IsShown() and parts.multiple:IsShown(), 'the reset icon, All and Multiple')
		check(not parts.line:DoesClipChildren(), 'and they fit: nothing cut')
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(parts.line, 'OnUpdate', 0.01)
		body:Release()

		-- The source page: a long name, its Show differing.
		fresh()
		differs.hotkey = { { name = 'Bar 3', value = 'Hidden' } }
		local long = Item('A rather long name for an item', 1, 'source')
		body, by = draw(Page({ hotkey = long }))
		c = by.hotkey
		local diff = c.frame.share.diff
		check(diff:IsShown(), 'the diff icon')
		check(diff:GetRight() <= c.widget.dots:GetLeft() - 6, 'it never reaches the dots')
		check(c.label:GetWidth() < math.ceil(c.label:GetUnboundedStringWidth()), 'the name is cut to leave it room')
		body:Release()
	end)
end)

------------------------------------------------------------------ Blizzard

test('Blizzard: the box is the Settings check box at the row size, the dots white under the mouse, the last item\'s line inside the body', function()
	in_look('blizzard', function()
		fresh()
		local body, by, content = draw(Page(FourItems()))
		local c = by.hotkey
		local box = c.widget.box
		local art = box.art and box.art.normal
		check(art and art:IsShown(), "the Settings panel's check box")
		eq(art:GetWidth() .. 'x' .. art:GetHeight(), table.concat({ W.CheckArtSize(22) }, 'x'), 'at the check list\'s row size')
		eq(art:GetWidth() .. 'x' .. art:GetHeight(), '23x22')
		eq(art:GetLeft() - box:GetLeft(), 0, "from the box's left")
		eq(art:GetTop() - box:GetTop(), 2, 'and 2 over its top')
		check(not box.mark:IsShown(), 'no blue square')
		eq(vertex(c.widget.dots.icon), color('text', 'muted'), 'the dots grey')
		stub.fire_script(c.widget.dots, 'OnEnter', true)
		eq(vertex(c.widget.dots.icon), '1.00,1.00,1.00', 'white under the mouse')
		-- an Accent pass (the record's own follow) leaves the dots to the Blizzard rule: white, not the lighter tone
		st.config.profile.theme.accent:SetRGB(0.9, 0.2, 0.6)
		st:ColorChanged('accent')
		eq(vertex(c.widget.dots.icon), '1.00,1.00,1.00', 'white through an Accent pass')
		check(st:StateLook(c.widget.dots).blizzard, "the slot's record wears the Blizzard rule")
		stub.fire_script(c.widget.dots, 'OnLeave', true)
		st:ColorChanged('accent')
		eq(vertex(c.widget.dots.icon), color('text', 'muted'), 'grey again after leaving and a pass')
		st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
		body:Release()

		-- Marked: the box moves the shift with its label.
		fresh()
		own.size = true
		body, by = draw(Page({ hotkey = Item('Hotkey', 1, 'member') }))
		c = by.hotkey
		eq(x_in(c.widget.box, c.frame), OB.FLAT.markShift, 'the box moves markShift right')
		eq((select(4, c.label:GetPoint(1))), 26 + OB.FLAT.markShift, 'and the label')
		body:Release()

		-- The source page, Show differing on the fourth: its line inside the body,
		-- short of its dots.
		fresh()
		differs.cooldown = { { name = 'Bar 3', value = 'Hidden' } }
		body, by, content = draw(Page(FourItems('source')))
		c = by.cooldown
		eq(x_in(c.frame, content), 603, 'the last quarter')
		local line = c.frame.share.line
		stub.fire_script(c.frame, 'OnEnter', true)
		check(line:IsShown(), 'its line')
		check(line:GetRight() - content:GetLeft() <= 774, 'not past the body')
		check(line:GetRight() <= c.widget.dots:GetLeft() - 6, 'short of its dots')
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(line, 'OnUpdate', 0.01)
		body:Release()
	end)
end)

------------------------------------------------------------------ fix round 1

test("an item's box and dots sit centred on its row, under both looks", function()
	local function mid(region) return (region:GetTop() + region:GetBottom()) / 2 end
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		in_look(look, function()
			fresh()
			local body, by = draw(Page(FourItems()))
			for _, key in ipairs({ 'hotkey', 'cooldown' }) do
				local c = by[key]
				eq(c.widget.frame:GetHeight(), c.height, look .. ' ' .. key .. ': the widget as tall as the row')
				eq(mid(c.widget.box), mid(c.frame), look .. ' ' .. key .. ': the box centred')
				eq(mid(c.widget.dots), mid(c.frame), look .. ' ' .. key .. ': the dots centred')
			end
			body:Release()
		end)
	end
end)

test("an item's box takes the mouse over Blizzard's art under Blizzard, and on itself again under Thick", function()
	local insets = function(box) return table.concat({ box:GetHitRectInsets() }, ',') end
	local boxes = {}
	in_look('blizzard', function()
		fresh()
		local body, by = draw(Page(FourItems()))
		for key, c in pairs(by) do
			boxes[key] = c.widget.box
			-- The art is 23 x 22 from the box's left, 2 over its top: the box reaches it.
			eq(insets(c.widget.box), '0,-5,-2,-2', key .. ': over the art')
		end
		body:Release()
	end)
	in_look('thick', function()
		fresh()
		local body, by = draw(Page(FourItems()))
		local reused = 0
		for key, c in pairs(by) do
			for _, box in pairs(boxes) do
				if box == c.widget.box then reused = reused + 1 end
			end
			eq(insets(c.widget.box), '0,0,0,0', key .. ': on itself again')
		end
		eq(reused, 4, 'the same pooled boxes')
		body:Release()
	end)
end)

test("an item's dots take Text > Muted as each draw binds them; an item with no menu has none", function()
	in_look('thick', function()
		fresh()
		local body, by = draw(Page(FourItems()))
		body:Release()
		local grey = st.config.profile.colors.text.muted
		local r, g, b = grey.r, grey.g, grey.b
		grey.r, grey.g, grey.b = 0.2, 0.4, 0.6
		body, by = draw(Page(FourItems()))
		eq(vertex(by.hotkey.widget.dots.icon), '0.20,0.40,0.60', 'the new grey')
		grey.r, grey.g, grey.b = r, g, b
		body:Release()

		-- No menu: no dots, and the name and its line go on to the cell's right edge.
		fresh()
		local args = FourItems()
		args.cooldown.menu = nil
		body, by = draw(Page(args))
		local c = by.cooldown
		check(not c.widget.dots:IsShown(), 'no dots')
		eq(c.widget.hasMenu, false)
		eq(c.label:GetWidth(), 165 - 26, "the label on to the cell's right edge")
		eq(c.lineEnd, 165, 'and its line')
		eq(st.OptionsWindow:OpenMenu(c.widget), false, 'no menu to open')
		check(by.hotkey.widget.dots:IsShown(), 'an item with a menu has its dots')
		body:Release()
		-- The same pooled widget drawn with a menu again: its dots back.
		body, by = draw(Page(FourItems()))
		for key, each in pairs(by) do check(each.widget.dots:IsShown(), key .. ': dots') end
		body:Release()
	end)
end)

test("an item's label through a drag: enabled by a dragged slider it stays grey while its Show is off, and follows its Show", function()
	in_look('thick', function()
		fresh()
		local level = 3
		local args = FourItems()
		args.macro.disabled = function() return level < 5 end
		args.level = { type = 'range', name = 'Level', desc = 'Level.', order = 5, min = 0, max = 10, step = 1,
			get = function() return level end, set = function(_, v) level = v end }
		local body, by
		body, by = draw(Page(args), function(ok, err, isDragging, widget)
			if isDragging then body:Refresh(widget) end
		end)
		local macro = by.macro
		check(macro.widget.disabled, 'Macro name disabled at 3')
		eq(text_rgb(macro.label), color('text', 'muted'), 'grey')
		local slider = by.level.widget
		stub.mouse_buttons.LeftButton = true
		slider.dragging = true
		slider:Commit(6)
		check(not macro.widget.disabled, 'enabled mid-drag')
		eq(text_rgb(macro.label), color('text', 'muted'), 'its label stays grey: its Show is off')
		shows.macro = true -- its Show turned on meanwhile
		slider:Commit(7)
		eq(text_rgb(macro.label), color('text', 'normal'), 'its Show on: the text color')
		shows.macro = false
		slider:Commit(6)
		eq(text_rgb(macro.label), color('text', 'muted'), 'off again: grey')
		slider:Commit(4)
		check(macro.widget.disabled, 'disabled again')
		eq(text_rgb(macro.label), color('text', 'muted'))
		stub.mouse_buttons.LeftButton = nil
		slider.dragging = nil
		body:Release()
	end)
end)

------------------------------------------------------------------ the body

test('OB.New with oneColumn lays every row as wide, a button line still on its own', function()
	in_look('thick', function()
		fresh()
		local args = {
			a = { type = 'toggle', name = 'A', desc = 'A.', order = 1, size = 'small', get = function() return true end, set = function() end },
			b = { type = 'range', name = 'B', desc = 'B.', order = 2, min = 0, max = 1, step = 1, get = function() return 0 end, set = function() end },
			go = { type = 'execute', name = 'Go', desc = 'Go.', order = 3, align = 'center', func = function() end },
		}
		local body, by, content = draw(Page(args), nil, { oneColumn = true })
		eq(body.oneColumn, true)
		for _, key in ipairs({ 'a', 'b' }) do
			eq(x_in(by[key].frame, content), 14, key .. ': at the padding')
			eq(by[key].frame:GetWidth(), 774 - 28, key .. ': the whole line')
		end
		check(by.a.frame:GetTop() > by.b.frame:GetTop(), 'each on a line of its own')
		local go = by.go.widget.frame
		eq(math.floor(x_in(go, content) + go:GetWidth() / 2), 387, 'the centred button in the middle')
		body:Release()

		-- Without it, two halves.
		body, by, content = draw(Page(args))
		eq(by.b.frame:GetWidth(), 387 - 28, 'a half')
		body:Release()
	end)
end)
