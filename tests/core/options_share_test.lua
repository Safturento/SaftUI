-- Shareable options (SaftUI's share field): the model's side in
-- SaftUI-Core/Config/optionsmodel.lua (OM.ShareState, OM.ShareCall,
-- OM.ShareTargets, OM.MenuRoot and a position section's shareRow), and the
-- drawing in optionsshare.lua (the own mark, the diff icon and its tooltip, the
-- hover line with Reset and Apply to: All | Multiple, and a section title's
-- marks), on bodies made with OB.New.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window's files, as
-- options_window_helpers.lua loads them. The pages are synthetic: a member page
-- (Bar 3, whose share has own and reset) and a source page (All bars, whose
-- share has differs), each recording what its share functions are asked. The
-- mouse is played with stub.cursor_x and stub.cursor_y and by firing the
-- frames' scripts, OnEnter and OnLeave with true as the game passes them.
load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

------------------------------------------------------------------ the synthetic pages

local calls -- every reset, applyAll and apply the shares took: { action, key, keys }
local own -- the member page's own settings, by key
local differs -- the source page's differing pages, by key
local SHARED = { spacing = '3', show = 'Always', hotkey = 'Shown', size = '10', pos = 'Top left', position = 'Top left' }
local TARGETS = { { key = 'bar2', label = 'Bar 2' }, { key = 'bar4', label = 'Bar 4' }, { key = 'bar5', label = 'Bar 5' } }

local function fresh()
	calls, own, differs = {}, {}, {}
end
fresh()

local function record(action, info, keys)
	calls[#calls + 1] = { action = action, key = info[#info], keys = keys and table.concat(keys, ',') or nil }
end

local function common(share)
	share.source = 'All bars'
	share.shared = function(info) return SHARED[info[#info]] end
	share.targets = function() return TARGETS end
	share.applyAll = function(info) record('applyAll', info) end
	share.apply = function(info, keys) record('apply', info, keys) end
	return share
end

local function MemberShare()
	return common({
		page = 'Bar 3',
		own = function(info) return own[info[#info]] end,
		reset = function(info) record('reset', info) end,
	})
end

local function SourceShare()
	return common({ differs = function(info) return differs[info[#info]] or {} end })
end

-- A page of spacing (a range) and show (a select), each shareable, and extra.
local function Page(kind, extra)
	local share = kind == 'member' and MemberShare or SourceShare
	local values = { spacing = kind == 'member' and 6 or 3, show = 'always', small = true }
	local args = {
		spacing = { type = 'range', name = 'Spacing', order = 1, min = 0, max = 10, step = 1, share = share() },
		show = { type = 'select', name = 'Show', order = 2, values = { always = 'Always', faded = 'Faded' }, share = share() },
	}
	for key, option in pairs(extra or {}) do
		if option.share == true then option.share = share() end
		args[key] = option
	end
	return { page = {
		type = 'group', name = kind == 'member' and 'Bar 3' or 'All bars', args = args,
		get = function(info) return values[info[#info]] end, set = function() end,
	} }
end

-- An item: a Show (the item's own share) and a menu holding a range and a position.
local function Item(kind, showShare)
	local share = kind == 'member' and MemberShare or SourceShare
	return {
		type = 'item', name = 'Hotkey', order = 3, share = showShare ~= false and share() or nil,
		menu = { type = 'group', name = 'Hotkey', args = {
			size = { type = 'range', name = 'Size', order = 1, min = 6, max = 20, step = 1, share = share() },
			position = { type = 'position', name = 'Position', order = 2, share = share() },
		} },
	}
end

local function row_of(root, key)
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return row end
		end
	end
	error('no row ' .. key)
end

local function state_of(root, key) return OM.ShareState(root, row_of(root, key)) end

local function diff_text(list)
	local out = {}
	for i, entry in ipairs(list) do out[i] = entry.name .. '=' .. entry.value end
	return table.concat(out, ';')
end

------------------------------------------------------------------ drawing helpers

-- A body 774 wide on a content frame at the screen's top left, the page drawn
-- under look, its cells by key.
local function draw(root, onChanged)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 600)
	local body = OB.New(content, root, onChanged, 774)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- GameTooltip, as a stand-in that notes each line it's given.
local function watch_tooltip()
	local tip = { lines = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines = {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		Show = function() end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner = nil end,
	}
	return tip, function() _G.GameTooltip = saved end
end

-- fn(tip) under look, with GameTooltip watched (tip, watch_tooltip's); the
-- look, the cursor, the tooltip and the list put back after.
-- The body drawn again from root (released first), its cells by key.
local function redraw(body, root)
	body:Release()
	body:SetRoot(root)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return by
end

local function in_look(look, fn)
	st.config.profile.theme.name = look
	local tip, restore = watch_tooltip()
	local ok, err = pcall(fn, tip)
	W.CloseList()
	restore()
	st.config.profile.theme.name = 'thick'
	stub.cursor_x, stub.cursor_y = 0, 0
	if not ok then error(err, 0) end
end

-- The cursor on the middle of a region, or at x in from its left, in screen units.
local function hover(region, x)
	local scale = region:GetEffectiveScale()
	local left = x and region:GetLeft() + x or (region:GetLeft() + region:GetRight()) / 2
	stub.cursor_x = left * scale
	stub.cursor_y = (region:GetTop() + region:GetBottom()) / 2 * scale
end

local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local OWN = rgb(unpack(OB.OWN_TEXT))
local function text_rgb(fs) return rgb(fs:GetTextColor()) end
local function normal() return rgb(st.config.profile.colors.text.normal:GetRGB()) end
local function grey() return rgb(st.config.profile.colors.text.grey:GetRGB()) end

local function shown(parts, key) return parts ~= nil and parts[key]:IsShown() end

local function point(region)
	local p, rel, relPoint, x, y = region:GetPoint(1)
	return p, rel, relPoint, x, y
end

-- Fires the line's watcher once, as the game runs OnUpdate on a shown frame.
local function watch(parts) stub.fire_script(parts.line, 'OnUpdate', 0.01) end

------------------------------------------------------------------ the model

test('ShareState: a member page marks and offers an own row, and leaves a following row plain', function()
	fresh()
	own.spacing = true
	local root = Page('member', { plain = { type = 'range', name = 'Plain', order = 4, min = 0, max = 1, step = 1 } })
	local s = state_of(root, 'spacing')
	eq(s.member, true, 'a member page')
	eq(s.own, true, 'spacing is its own')
	eq(s.marked, true, 'marked')
	eq(s.offers, true, 'and offers Reset and Apply to')
	eq(s.source, 'All bars'); eq(s.page, 'Bar 3'); eq(s.shared, '3', "the source's value, as text")
	eq(#s.differs, 0, 'a member page has no differs')
	eq(s.item, false)
	local follow = state_of(root, 'show')
	eq(follow.member, true); eq(follow.own, false); eq(follow.marked, false); eq(follow.offers, false)
	eq(state_of(root, 'plain'), nil, 'no share: no state')
	eq(#calls, 0, 'nothing acted')
end)

test('ShareState: the source page offers a row some page owns, with who and what', function()
	fresh()
	differs.spacing = { { name = 'Bar 2', value = '2' }, { name = 'Bar 4', value = 1 } }
	local root = Page('source')
	local s = state_of(root, 'spacing')
	eq(s.member, false, 'the source page')
	eq(s.own, false); eq(s.marked, false)
	eq(s.offers, true, 'it offers Apply to')
	eq(diff_text(s.differs), 'Bar 2=2;Bar 4=1', 'differs as given, values as text')
	eq(s.shared, '3'); eq(s.source, 'All bars'); eq(s.page, nil)
	local plain = state_of(root, 'show')
	eq(#plain.differs, 0, 'none differs on show')
	eq(plain.offers, false, 'so it offers nothing')
end)

test("ShareState: an item is marked by its Show or anything in its menu; it offers for its Show alone", function()
	fresh()
	eq(OM.MENU_KEY, 'menu')
	local item = Item('member')
	check(OM.MenuRoot(item).menu == item.menu, "MenuRoot: the tree the item's menu is read from")

	-- Member: Show follows, the menu's Size is own.
	own.size = true
	local root = Page('member', { hotkey = item })
	local s = state_of(root, 'hotkey')
	eq(s.item, true); eq(s.member, true)
	eq(s.own, false, 'its Show is not own')
	eq(s.marked, true, 'marked by its menu')
	eq(s.offers, false, 'it offers for its Show alone')
	own.size, own.hotkey = nil, true
	s = state_of(root, 'hotkey')
	eq(s.own, true); eq(s.marked, true); eq(s.offers, true, 'its own Show offers')
	eq(s.shared, 'Shown', "its Show's shared value")

	-- Source: Show differs on Bar 3; Size on Bar 3 and Bar 5.
	fresh()
	differs.hotkey = { { name = 'Bar 3', value = 'Hidden' } }
	differs.size = { { name = 'Bar 3', value = '8' }, { name = 'Bar 5', value = '9' } }
	root = Page('source', { hotkey = Item('source') })
	s = state_of(root, 'hotkey')
	eq(diff_text(s.differs), 'Bar 3=Show, Size;Bar 5=Size', 'grouped by page, the setting names joined')
	eq(s.offers, true, 'its Show differs')
	-- Show on none, Size on Bar 5: the diff shows, nothing offered.
	differs.hotkey, differs.size = nil, { { name = 'Bar 5', value = '9' } }
	differs.position = { { name = 'Bar 5', value = 'Center' }, { name = 'Bar 2', value = 'Top' } }
	s = state_of(root, 'hotkey')
	eq(diff_text(s.differs), 'Bar 5=Size, Position;Bar 2=Position', 'in the menu\'s order')
	eq(s.offers, false, 'its Show offers nothing')

	-- No shareable Show: marked and diffed by its menu alone; no share anywhere: nil.
	fresh()
	own.size = true
	root = Page('member', { hotkey = Item('member', false) })
	s = state_of(root, 'hotkey')
	check(s ~= nil, 'a menu share is enough')
	eq(s.marked, true); eq(s.offers, false); eq(s.source, 'All bars')
	local bare = Item('member', false)
	bare.menu.args.size.share, bare.menu.args.position.share = nil, nil
	eq(state_of(Page('member', { hotkey = bare }), 'hotkey'), nil, 'no share anywhere: nil')
end)

test('ShareCall and ShareTargets call the option with its info; an erroring share counts as none', function()
	fresh()
	local root = Page('member')
	local row = row_of(root, 'spacing')
	eq(OM.ShareCall(root, row, 'apply', { 'bar2' }), true, 'it ran')
	eq(#calls, 1)
	eq(calls[1].action, 'apply'); eq(calls[1].key, 'spacing', "info[#info] is the option's key"); eq(calls[1].keys, 'bar2')
	eq(OM.ShareCall(root, row, 'reset'), true); eq(calls[2].action, 'reset')
	eq(OM.ShareCall(root, row, 'applyAll'), true); eq(calls[3].action, 'applyAll')
	local targets = OM.ShareTargets(root, row)
	eq(#targets, 3)
	eq(targets[1].key .. '=' .. targets[1].label, 'bar2=Bar 2')

	-- The source page has no reset: nothing runs.
	local sourceRoot = Page('source')
	eq(OM.ShareCall(sourceRoot, row_of(sourceRoot, 'spacing'), 'reset'), false, 'no reset on the source page')

	-- Erroring functions: the error is taken, the answer is false or empty.
	local broken = Page('member')
	local share = broken.page.args.spacing.share
	share.own = function() error('own broke') end
	share.targets = function() error('targets broke') end
	share.reset = function() error('reset broke') end
	local brokenRow = row_of(broken, 'spacing')
	eq(OM.ShareState(broken, brokenRow).own, false, 'own erroring counts as false')
	eq(#take_errors(), 1, 'one error taken')
	eq(#OM.ShareTargets(broken, brokenRow), 0, 'targets erroring: none')
	eq(#take_errors(), 1)
	eq(OM.ShareCall(broken, brokenRow, 'reset'), false, 'an erroring action gives false')
	eq(#take_errors(), 1)
	share.targets = nil
	eq(#OM.ShareTargets(broken, brokenRow), 0, 'no targets: none')
end)

test("a position option's section carries its row for the title's marks", function()
	fresh()
	local root = Page('member', {
		pos = { type = 'position', name = 'Position', order = 10, share = true },
	})
	local found
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		if section.title == 'Position' then found = section end
	end
	check(found ~= nil, 'a Position section')
	check(found.shareRow == found.rows[1], 'shareRow is its position row')
	root.page.args.pos.share = nil
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		if section.title == 'Position' then eq(section.shareRow, nil, 'none without share') end
	end
end)

------------------------------------------------------------------ marks

test('Thick: an own row has the mark in the padding and a light blue label; a following row has neither', function()
	in_look('thick', function()
		fresh()
		own.spacing = true
		local body, by, content = draw(Page('member'))
		local spacing, show = by.spacing, by.show
		local parts = spacing.frame.share
		check(shown(parts, 'mark'), 'the mark shows')
		eq(parts.mark:GetWidth(), 2, '2 wide')
		eq(parts.mark:GetHeight(), 38 - 12, '6 in from the row\'s top and bottom')
		local p, rel, relPoint, x, y = point(parts.mark)
		check(rel == spacing.frame, 'on its row')
		eq(p .. ' ' .. relPoint .. ' ' .. x .. ',' .. y, 'TOPLEFT TOPLEFT -9,-6', '9 left of the row frame')
		eq(parts.mark:GetLeft() - content:GetLeft(), 5, 'at 5 in the slot: inside the panel\'s padding')
		eq(rgb(unpack(stub.state(parts.mark).color_texture)), rgb(st.config.profile.colors.button.blue:GetRGB()), 'in Button > Blue')
		eq(text_rgb(spacing.label), OWN, 'its label light blue')
		eq((select(4, point(spacing.label))), 0, 'no shift under Thick')
		check(not shown(show.frame.share, 'mark'), 'a following row has no mark')
		eq(text_rgb(show.label), normal(), 'and its label in Text > Normal')

		-- A redraw of a page with no share on the same frames leaves nothing behind.
		body:Release()
		local plain = { page = { type = 'group', name = 'P', args = {
			a = { type = 'range', name = 'A', order = 1, min = 0, max = 1, step = 1, get = function() return 0 end, set = function() end },
			b = { type = 'range', name = 'B', order = 2, min = 0, max = 1, step = 1, get = function() return 0 end, set = function() end },
		} } }
		body:SetRoot(plain)
		body:Draw(OM.BuildView(plain, 'page').sections)
		for _, c in ipairs(body.cells) do
			local share = c.frame.share
			check(not (shown(share, 'mark') or shown(share, 'diff') or shown(share, 'line')), c.row.key .. ': no stray piece')
			eq(text_rgb(c.label), normal(), c.row.key .. ': its label in Text > Normal')
		end
		body:Release()
	end)
end)

test("Blizzard: the mark at the cell's edge, the label 6 to its right", function()
	in_look('blizzard', function()
		fresh()
		own.spacing = true
		local body, by, content = draw(Page('member'))
		local parts = by.spacing.frame.share
		check(shown(parts, 'mark'), 'the mark shows')
		eq(parts.mark:GetLeft() - content:GetLeft(), 0, "at the row frame's left: content x 0")
		eq(parts.mark:GetWidth() .. 'x' .. parts.mark:GetHeight(), '2x' .. (34 - 12))
		local p, rel, relPoint, x = point(by.spacing.label)
		eq(p .. ' ' .. relPoint .. ' ' .. x, 'LEFT LEFT 6', 'its label 6 to the right')
		check(rel == by.spacing.frame)
		eq(text_rgb(by.spacing.label), OWN)
		eq((select(4, point(by.show.label))), 0, "a following row's label at 0")

		-- An own row in the second column: its mark at 407.
		own.spacing, own.show = nil, true
		by = redraw(body, Page('member'))
		eq(by.show.frame.share.mark:GetLeft() - content:GetLeft(), 407, 'the second column\'s cell edge')
		eq((select(4, point(by.show.label))), 6)
		check(not shown(by.spacing.frame.share, 'mark'), 'the first row, no longer own, has none')
		eq((select(4, point(by.spacing.label))), 0, 'and its label back at 0')
		body:Release()
	end)
end)

test('a disabled own row keeps its mark, its label grey, and offers no line', function()
	in_look('thick', function()
		fresh()
		own.spacing = true
		local root = Page('member')
		root.page.args.spacing.disabled = true
		local body, by = draw(root)
		local c = by.spacing
		check(shown(c.frame.share, 'mark'), 'the mark')
		eq(text_rgb(c.label), grey(), 'its label in Text > Grey')
		stub.fire_script(c.frame, 'OnEnter', true)
		check(not shown(c.frame.share, 'line'), 'no line')
		eq((point(c.label)), 'LEFT', 'the label stays')
		stub.fire_script(c.frame, 'OnLeave', true)
		body:Release()
	end)
end)

test("the diff icon follows the label's text and lists who differs", function()
	in_look('thick', function(tip)
		fresh()
		differs.spacing = { { name = 'Bar 2', value = '2' }, { name = 'Bar 4', value = '1' } }
		local body, by = draw(Page('source'))
		local c = by.spacing
		local diff = c.frame.share.diff
		check(diff:IsShown(), 'the diff icon shows')
		eq(diff.icon:GetTexture(), st.icons.diff, "Lucide's diff")
		eq(diff:GetWidth() .. 'x' .. diff:GetHeight(), '16x16')
		eq(rgb(diff.icon:GetVertexColor()), rgb(unpack(OB.DIFF_COLOR)), 'orange')
		check(diff:IsMouseEnabled(), 'it takes the mouse')
		local p, rel, relPoint, x = point(diff)
		check(rel == c.label, 'after the label')
		eq(p .. ' ' .. relPoint .. ' ' .. x, 'LEFT LEFT ' .. (math.ceil(c.label:GetUnboundedStringWidth()) + 4), "4 after the label's text")
		check(not shown(c.frame.share, 'mark'), 'no mark on the source page')
		eq(text_rgb(c.label), normal())
		check(by.show.frame.share == nil or not by.show.frame.share.diff:IsShown(), 'none on a row nothing differs on')

		stub.fire_script(diff, 'OnEnter', true)
		check(tip.owner == diff, 'its own tooltip')
		eq(table.concat(tip.lines, '|'), 'Spacing|All bars: 3|Bar 2: 2|Bar 4: 1', 'the name, the source, a line per page')
		stub.fire_script(diff, 'OnLeave', true)
		check(tip.owner == nil, 'gone on leaving')

		-- A long label is cut to leave the icon its room.
		local root = Page('source')
		root.page.args.spacing.name = string.rep('Long ', 30)
		by = redraw(body, root)
		c = by.spacing
		local labelRight = c.label:GetLeft() + c.label:GetWidth()
		check(c.frame.share.diff:GetRight() <= c.widget.frame:GetLeft(), 'the icon ends before the control')
		check(c.frame.share.diff:GetLeft() >= labelRight, 'after the cut label')
		body:Release()
	end)
end)

------------------------------------------------------------------ the hover line

test('the hover line: it shows on an offering row and stays while the mouse is on the row, its control or the line', function()
	in_look('thick', function()
		fresh()
		own.spacing = true
		local body, by = draw(Page('member'))
		local c = by.spacing
		local parts = c.frame.share
		check(not parts.line:IsShown(), 'hidden until the mouse comes')
		eq((point(c.label)), 'LEFT')

		hover(c.frame, 10) -- on the label
		stub.fire_script(c.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'the line shows')
		local p, rel, _, x, y = point(c.label)
		eq(p, 'TOPLEFT', 'the label lifted')
		check(rel == c.frame)
		eq(x .. ',' .. y, '0,-4', 'it and the line centred in the 38 row')
		local lp, lrel, _, lx, ly = point(parts.line)
		eq(lp .. ' ' .. lx .. ',' .. ly, 'TOPLEFT 0,-20', 'the line under it')
		check(lrel == c.frame)
		check(parts.ownText:IsShown() and parts.reset:IsShown(), 'Own and the reset icon on a member page')
		eq(parts.ownText.text:GetText(), 'Own')
		eq(rgb(parts.ownText.text:GetTextColor()), OWN)
		eq(parts.reset.icon:GetTexture(), st.icons.rotateCcw)
		eq(parts.reset:GetWidth() .. 'x' .. parts.reset:GetHeight(), '14x14')
		eq(parts.all.text:GetText() .. '|' .. parts.multiple.text:GetText(), 'All|Multiple')
		eq(rgb(parts.all.text:GetTextColor()), rgb(st.config.profile.colors.text.blue:GetRGB()), 'links in Text > Blue')
		check(parts.all:IsMouseEnabled() and parts.multiple:IsMouseEnabled() and parts.reset:IsMouseEnabled(), 'links take the mouse')
		check(parts.all:GetFrameLevel() > c.frame:GetFrameLevel(), 'over the row frame')

		-- Onto the slider: the row loses the focus, the watcher keeps the line.
		hover(c.widget.frame)
		stub.fire_script(c.frame, 'OnLeave', true)
		watch(parts)
		check(parts.line:IsShown(), 'still shown over the control')

		-- Onto Multiple, then into its list.
		hover(parts.multiple)
		watch(parts)
		check(parts.line:IsShown(), 'still shown over the line')
		stub.click(parts.multiple)
		check(W.ListOwner() == parts.multiple, "Multiple opened the Apply list")
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(parts)
		check(parts.line:IsShown(), 'still shown while its list is open')
		W.CloseList()
		watch(parts)
		check(not parts.line:IsShown(), 'gone once the mouse is off the row and the list closed')
		eq((point(c.label)), 'LEFT', 'the label back')
		eq((select(4, point(c.label))), 0)

		-- A plain row never moves.
		local plain = by.show
		hover(plain.frame, 10)
		stub.fire_script(plain.frame, 'OnEnter', true)
		check(not shown(plain.frame.share, 'line'), 'no line on a row that offers nothing')
		eq((point(plain.label)), 'LEFT', 'its label unmoved')
		stub.fire_script(plain.frame, 'OnLeave', true)

		-- The source page: Apply to alone.
		fresh()
		differs.spacing = { { name = 'Bar 2', value = '2' } }
		by = redraw(body, Page('source'))
		c = by.spacing
		parts = c.frame.share
		hover(c.frame, 10)
		stub.fire_script(c.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'shown on the source page')
		check(not parts.ownText:IsShown() and not parts.reset:IsShown(), 'no Own or reset there')
		eq(parts.sep:GetText(), 'Apply to:')
		eq((select(4, point(parts.sep))), 0, 'Apply to: first')
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(parts)
		check(not parts.line:IsShown(), 'and gone when the mouse leaves')
		body:Release()
	end)
end)

test('Reset, All and Multiple act through the share and draw the page again', function()
	in_look('thick', function(tip)
		fresh()
		own.spacing = true
		local changed = {}
		local body, by = draw(Page('member'), function(...) changed[#changed + 1] = { ... } end)
		local parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)

		stub.fire_script(parts.reset, 'OnEnter', true)
		eq(table.concat(tip.lines, '|'), "Reset|Spacing follows All bars again. Bar 3's own value is dropped.", "Reset's tooltip")
		stub.click(parts.reset)
		eq(#calls, 1, 'one call')
		eq(calls[1].action .. ' ' .. calls[1].key, 'reset spacing')
		eq(#changed, 1, 'the body told once')
		eq(changed[1][1], true, 'onChanged(true)')
		check(tip.owner == nil, 'its tooltip gone')

		stub.fire_script(parts.ownText, 'OnEnter', true)
		eq(table.concat(tip.lines, '|'), 'Spacing|All bars: 3', "Own's tooltip: the name and the source's value")
		stub.fire_script(parts.ownText, 'OnLeave', true)
		stub.fire_script(parts.all, 'OnEnter', true)
		check(#tip.lines >= 2, 'All says what it does')
		stub.fire_script(parts.all, 'OnLeave', true)

		stub.click(parts.all)
		eq(calls[2].action .. ' ' .. calls[2].key, 'applyAll spacing')
		eq(#changed, 2)

		stub.click(parts.multiple)
		local list = W.GetListFrames()
		eq(W.ListOwner(), parts.multiple)
		eq(list.rows[1].text:GetText() .. ',' .. list.rows[3].text:GetText(), 'Bar 2,Bar 5', "the share's targets")
		stub.click(list.rows[1]); stub.click(list.rows[3])
		eq(#calls, 2, 'nothing until Apply')
		stub.click(list.apply)
		eq(calls[3].action .. ' ' .. calls[3].key .. ' ' .. calls[3].keys, 'apply spacing bar2,bar5', 'apply got the picked keys')
		eq(#changed, 3)
		eq(W.ListOwner(), nil, 'the list closed')
		body:Release()
	end)
end)

------------------------------------------------------------------ a section title

test("a section title carries its block's marks and the line beside it", function()
	in_look('thick', function()
		fresh()
		own.pos = true
		local root = Page('member', { pos = { type = 'position', name = 'Position', order = 10, share = true } })
		local body, by = draw(root)
		eq(#body.shareTitles, 1, 'one titled block')
		local entry = body.shareTitles[1]
		eq(entry.title:GetText(), 'Position')
		eq(entry.section.title, 'Position')
		eq(text_rgb(entry.title), OWN, 'the title light blue')
		check(shown(by.pos.frame.share, 'mark'), "the block's row has the mark")
		eq(by.pos.frame.share.mark:GetHeight(), by.pos.height - 12, 'down the block')
		check(not shown(by.pos.frame.share, 'line'), 'the row itself has no line')
		check(not entry.parts.line:IsShown(), 'hidden until hovered')

		local titleWidth = math.ceil(entry.title:GetUnboundedStringWidth())
		hover(entry.hover)
		stub.fire_script(entry.hover, 'OnEnter', true)
		check(entry.parts.line:IsShown(), 'the line shows')
		eq(entry.parts.line:GetLeft() - entry.title:GetLeft(), titleWidth + 8, '8 right of the title\'s text')
		-- Onto the block: it stays; off everything: it goes.
		hover(by.pos.frame)
		watch(entry.parts)
		check(entry.parts.line:IsShown(), 'kept over the block')
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(entry.parts)
		check(not entry.parts.line:IsShown(), 'gone off the title, block and line')
		-- The block's own hover brings it too.
		by.pos.widget.onTip(true)
		check(entry.parts.line:IsShown(), "the block's parts show it")
		by.pos.widget.onTip(false)
		watch(entry.parts)

		-- Reset from the title's line acts on the block's option.
		stub.click(entry.parts.reset)
		eq(calls[1].action .. ' ' .. calls[1].key, 'reset pos')

		-- The source page: the diff icon after the title, the line after it.
		fresh()
		differs.pos = { { name = 'Bar 3', value = 'Center' } }
		redraw(body, Page('source', { pos = { type = 'position', name = 'Position', order = 10, share = true } }))
		entry = body.shareTitles[1]
		eq(text_rgb(entry.title), grey(), 'a title nothing owns stays grey')
		check(entry.parts.diff:IsShown(), 'the diff icon')
		eq(entry.parts.diff:GetLeft() - entry.title:GetLeft(), titleWidth + 4, "4 after the title's text")
		stub.fire_script(entry.hover, 'OnEnter', true)
		eq(entry.parts.line:GetLeft() - entry.title:GetLeft(), titleWidth + 4 + 16 + 8, '8 after the icon')
		body:Release()
		eq(#body.shareTitles, 0, 'a release forgets them')
	end)
end)

------------------------------------------------------------------ Blizzard

test('Blizzard: every piece draws, and no line runs past the body', function()
	in_look('blizzard', function()
		fresh()
		own.spacing, own.title = true, true
		local root = Page('member', {
			a = { type = 'toggle', name = 'A', order = 3, size = 'small', share = true },
			b = { type = 'toggle', name = 'B', order = 4, size = 'small', share = true },
			c = { type = 'toggle', name = 'C', order = 5, size = 'small', share = true },
			d = { type = 'toggle', name = 'D', order = 6, size = 'small', share = true },
			pos = { type = 'position', name = 'Position', order = 10, share = true },
		})
		own.d, own.pos = true, true
		local body, by, content = draw(root)
		local parts = by.spacing.frame.share
		check(shown(parts, 'mark'), 'the mark')
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'the line')
		eq((select(4, point(parts.line))), 6, 'under the shifted label')
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(parts)

		-- D sits in the last quarter: its line, wider than its room, ends at the body's width.
		local d = by.d
		eq(d.frame:GetLeft() - content:GetLeft(), 774 - 171, 'the last quarter')
		local line = d.frame.share.line
		check(line:GetWidth() > 171 - 6, 'a line wider than its room')
		stub.fire_script(d.frame, 'OnEnter', true)
		check(line:IsShown())
		eq(line:GetRight() - content:GetLeft(), 774, "its right edge at the body's width")
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(d.frame.share)

		-- The block moves 6 right under its mark, the title too.
		local block = by.pos
		eq((select(4, point(block.widget.frame))), 6, 'the block moves markShift right')
		local entry = body.shareTitles[1]
		eq(entry.title:GetLeft() - content:GetLeft(), 6, 'and its title')
		eq(text_rgb(entry.title), OWN)

		-- The source page: the diff icon.
		fresh()
		differs.spacing = { { name = 'Bar 2', value = '2' } }
		by = redraw(body, Page('source'))
		check(by.spacing.frame.share.diff:IsShown(), 'the diff icon')
		eq((select(4, point(by.spacing.label))), 0, 'no shift without a mark')
		body:Release()
	end)
end)
