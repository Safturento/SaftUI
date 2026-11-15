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
local SHARED = { spacing = '3', show = 'Always', hotkey = 'Shown', size = '10', pos = 'Top left', position = 'Top left', a = 'On' }
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

-- GameTooltip, as a stand-in that notes each line it's given: a double line's
-- left text in lines, its right in rights and the right's color (as rgb text)
-- in rightColors, by line.
local function watch_tooltip()
	local tip = { lines = {}, rights = {}, rightColors = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines, tip.rights, tip.rightColors = {}, {}, {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		AddDoubleLine = function(_, left, right, _, _, _, r, g, b)
			tip.lines[#tip.lines + 1] = left
			tip.rights[#tip.lines] = right
			tip.rightColors[#tip.lines] = r and string.format('%.2f,%.2f,%.2f', r, g, b) or nil
		end,
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
local OWN = rgb(st:Color('accent'):GetRGB())
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

test('Thick: an own row has the mark in the padding and an accent label; a following row has neither', function()
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
		eq(rgb(unpack(stub.state(parts.mark).color_texture)), rgb(st.config.profile.theme.accent:GetRGB()), 'in the accent')
		eq(text_rgb(spacing.label), OWN, 'its label in the accent')
		eq((select(4, point(spacing.label))), 0, 'no shift under Thick')
		check(not shown(show.frame.share, 'mark'), 'a following row has no mark')
		eq(text_rgb(show.label), normal(), 'and its label in Text > Normal')
		do -- a non-default accent: the mark and the label follow it when drawn again
			local accent = st.config.profile.theme.accent
			accent:SetRGB(0.9, 0.1, 0.2)
			local _, again = draw(Page('member'))
			eq(rgb(unpack(stub.state(again.spacing.frame.share.mark).color_texture)), '0.90,0.10,0.20', 'the mark in the accent')
			eq(text_rgb(again.spacing.label), '0.90,0.10,0.20', 'the label in the accent')
			accent:SetRGB(0, 0.68, 0.94)
		end

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
		-- Two columns, as the mockup draws them: the page on the left, its value on the right in the accent.
		eq(table.concat(tip.lines, '|'), 'Spacing|All bars: 3|Bar 2|Bar 4', 'the name, the source, a line per page')
		eq(tostring(tip.rights[3]) .. '|' .. tostring(tip.rights[4]), '2|1', 'each value on the right')
		eq(tostring(tip.rightColors[3]) .. '|' .. tostring(tip.rightColors[4]), OWN .. '|' .. OWN, 'in the accent')
		eq(tip.rights[1], nil, 'the title a line of its own')
		eq(tip.rights[2], nil, "and the source's line")
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
		eq(rgb(parts.all.text:GetTextColor()), rgb(st.config.profile.theme.accent:GetRGB()), 'links in the accent')
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
		eq(text_rgb(entry.title), OWN, 'the title in the accent')
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
		-- (the reset is part of the hover line, hidden once the cursor moved off: press it unchecked)
		stub.click_unchecked(entry.parts.reset)
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

		-- D sits in the last quarter: its whole line is wider than its room, so it
		-- drops Own and the words before All, and the rest fits: it starts under
		-- its label (not moved back into C's cell) and ends inside the cell,
		-- here short of the body's width, uncut.
		local d = by.d
		eq(d.frame:GetLeft() - content:GetLeft(), 774 - 171, 'the last quarter')
		local dp = d.frame.share
		local line = dp.line
		stub.fire_script(d.frame, 'OnEnter', true)
		check(line:IsShown())
		check(not dp.ownText:IsShown() and not dp.sep:IsShown(), 'Own and the words dropped')
		check(dp.reset:IsShown() and dp.all:IsShown() and dp.multiple:IsShown(), 'the reset icon and All | Multiple kept')
		eq(line:GetLeft() - content:GetLeft(), 774 - 171 + 6, 'under its shifted label')
		eq(line:GetRight(), dp.multiple:GetRight(), 'it ends at Multiple')
		check(line:GetRight() - content:GetLeft() <= 774, 'not past the body')
		check(not line:DoesClipChildren(), 'whole: nothing cut')
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

test('at half: the own mark markX in from each slot, a row\'s hover line ending inside its cell, a title\'s line whole', function()
	in_look('thick', function()
		fresh()
		own.spacing, own.a, own.b, own.pos = true, true, true, true
		local root = Page('member', {
			a = { type = 'toggle', name = 'A', order = 3, size = 'small', share = true },
			b = { type = 'toggle', name = 'B', order = 4, size = 'small', share = true },
			pos = { type = 'position', name = 'Position', order = 10, share = true },
		})
		local content = CreateFrame('Frame', nil, UIParent)
		content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
		content:SetSize(388, 600)
		local body = OB.New(content, root, nil, 774)
		body:SetWidth(388, true)
		body:Draw(OM.BuildView(root, 'page').sections)
		local by = {}
		for _, c in ipairs(body.cells) do by[c.row.key] = c end
		local function markAt(key) return by[key].frame.share.mark:GetLeft() - content:GetLeft() end
		eq(markAt('spacing'), 5, 'a half row: 5 in from the slot at 0')
		eq(markAt('a'), 5, 'a quarter in the left slot')
		eq(markAt('b'), 194 + 5, 'a quarter in the right slot, 194 in')
		check(by.a.frame:GetTop() == by.b.frame:GetTop(), 'A and B on one line')
		for _, key in ipairs({ 'spacing', 'show', 'a', 'b' }) do
			local c = by[key]
			stub.fire_script(c.frame, 'OnEnter', true)
			local parts = c.frame.share
			if parts and parts.line:IsShown() then
				check(parts.line:GetRight() <= c.frame:GetRight(), key .. ': the line ends inside its cell')
				check(parts.line:GetLeft() >= c.frame:GetLeft(), key .. ': and starts inside it')
			end
			stub.fire_script(c.frame, 'OnLeave', true)
			stub.cursor_x, stub.cursor_y = 0, 0
		end
		-- The whole 360 cell's line shows all of it, ending at its last link.
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		local sp = by.spacing.frame.share
		check(sp.line:IsShown(), "spacing's line shows")
		eq(sp.line:GetRight(), sp.multiple:GetRight(), 'it ends at its last link')
		stub.fire_script(by.spacing.frame, 'OnLeave', true)
		stub.cursor_x, stub.cursor_y = 0, 0

		local entry = body.shareTitles[1]
		eq(entry.title:GetWidth(), 388, 'the title takes the narrow width')
		stub.fire_script(entry.hover, 'OnEnter', true)
		check(entry.parts.line:IsShown(), "the title's line shows")
		check(not entry.parts.line:DoesClipChildren(), 'whole: nothing cut')
		check(entry.parts.line:GetRight() - content:GetLeft() <= 388, 'inside the body')
		body:Release()
	end)
end)

------------------------------------------------------------------ fix round 1

-- Every frame under frame (frame first, then its children and theirs).
local function frames_under(frame, list)
	list = list or {}
	list[#list + 1] = frame
	for _, child in ipairs({ frame:GetChildren() }) do frames_under(child, list) end
	return list
end

-- A tooltip's text: its lines joined with |, a double line as 'left = right'.
local function tip_text(tip)
	local out = {}
	for i, line in ipairs(tip.lines) do out[i] = tip.rights[i] and (line .. ' = ' .. tip.rights[i]) or line end
	return table.concat(out, '|')
end

-- The tooltip a piece of a line shows, as text (its OnEnter, then its OnLeave).
local function read_tip(tip, piece)
	stub.fire_script(piece, 'OnEnter', true)
	local text = tip_text(tip)
	stub.fire_script(piece, 'OnLeave', true)
	return text
end

-- An item's row is the real one now (optionsitem.lua, 'row' in
-- OB.SHARE_KINDS): its label after its Show box (labelX 26, the page's get
-- giving it one), ending 6 before its 16 wide dots.
local ITEM_LABEL_X, ITEM_STOP = 26, 16 + 6

test('the Apply list closes when its row is drawn again or released, and its Apply acts on the row it was opened for', function()
	in_look('thick', function()
		fresh()
		own.spacing, own.show = true, true
		local body, by = draw(Page('member'))
		local frame = by.spacing.frame
		stub.fire_script(frame, 'OnEnter', true)
		stub.click(frame.share.multiple)
		local list = W.GetListFrames()
		eq(W.ListOwner(), frame.share.multiple, 'open')
		stub.click(list.rows[1]) -- Bar 2
		local apply = list.onApply -- what its Apply button runs
		-- Drawn again with the rows the other way round: the same frame now holds Show.
		local swapped = Page('member')
		swapped.page.args.spacing.order, swapped.page.args.show.order = 2, 1
		redraw(body, swapped)
		eq(frame.shareCell.row.key, 'show', 'the pooled frame holds another shareable row')
		eq(W.ListOwner(), nil, 'the list closed with the row it was opened on')
		-- Had its Apply still been clicked, it acts on Spacing, the row it opened for.
		apply()
		eq(#calls, 1, 'one call')
		eq(calls[1].action .. ' ' .. calls[1].key .. ' ' .. calls[1].keys, 'apply spacing bar2', 'on the row it was opened for')

		-- Released with nothing drawn on its frame again (a page of fewer rows): closed too.
		fresh()
		own.spacing, own.show = true, true
		by = redraw(body, Page('member'))
		local last = by.show.frame
		stub.fire_script(last, 'OnEnter', true)
		stub.click(last.share.multiple)
		eq(W.ListOwner(), last.share.multiple, 'open on the second row')
		body:Release()
		eq(W.ListOwner(), nil, 'closed when its row is released')
		eq(#calls, 0, 'nothing applied')
	end)
end)

test('a row entered through its control shows its line: from the column beside it, and from above onto the slider', function()
	in_look('thick', function()
		fresh()
		own.spacing, own.show = true, true
		local body, by = draw(Page('member'))
		local spacing, show = by.spacing, by.show

		-- From above, straight onto the slider: the row frame never hears of it.
		hover(spacing.widget.slider)
		stub.fire_script(spacing.widget.slider, 'OnEnter', true)
		check(spacing.frame.share.line:IsShown(), "the slider's hover is the row's")
		eq((point(spacing.label)), 'TOPLEFT', 'the label lifted')
		watch(spacing.frame.share)
		check(spacing.frame.share.line:IsShown(), 'kept while the mouse is on the slider')

		-- From the column beside it: from Show's half leftwards onto Spacing's value box.
		hover(show.frame, 10)
		stub.fire_script(show.frame, 'OnEnter', true)
		watch(spacing.frame.share)
		check(not spacing.frame.share.line:IsShown(), "Spacing's line gone once the mouse is on Show")
		hover(spacing.widget.edit)
		stub.fire_script(spacing.widget.edit, 'OnEnter', true)
		check(spacing.frame.share.line:IsShown(), "the value box's hover is the row's too")
		watch(show.frame.share)
		check(not show.frame.share.line:IsShown(), "Show's line gone")
		-- And back right, onto Show's dropdown.
		hover(show.widget.frame)
		stub.fire_script(show.widget.frame, 'OnEnter', true)
		check(show.frame.share.line:IsShown(), "the dropdown's hover is its row's")
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(show.frame.share)
		watch(spacing.frame.share)

		-- Hooked once each, however often the row is drawn.
		local slider = spacing.widget.slider
		local hooks = #(stub.state(slider).hooks.OnEnter or {})
		check(hooks >= 1, 'the slider is hooked')
		for _ = 1, 3 do by = redraw(body, Page('member')) end
		check(by.spacing.widget.slider == slider, 'the same slider, from its pool')
		eq(#stub.state(slider).hooks.OnEnter, hooks, 'no hook added by a redraw')

		-- A row that offers nothing: its control's hover shows nothing, and its label stays.
		own.show = nil
		by = redraw(body, Page('member'))
		hover(by.show.widget.frame)
		stub.fire_script(by.show.widget.frame, 'OnEnter', true)
		check(not shown(by.show.frame.share, 'line'), 'no line')
		eq((point(by.show.label)), 'LEFT', 'its label unmoved')
		body:Release()
	end)
end)

test("the line sits above the control, its links over every part of it; in a quarter cell it drops Own and the words, and only past that is it cut", function()
	in_look('thick', function(tip)
		fresh()
		own.spacing, own.a = true, true
		local function quarters(size)
			return Page('member', {
				a = { type = 'toggle', name = 'A', order = 3, size = size, share = true },
				b = { type = 'toggle', name = 'B', order = 4, size = size, share = true },
			})
		end
		local body, by = draw(quarters('small'))
		-- Levels: the line 4 over its row, its links one over the line, over every part of the control.
		for _, key in ipairs({ 'spacing', 'a' }) do
			local c = by[key]
			local parts, top = c.frame.share, 0
			for _, f in ipairs(frames_under(c.widget.frame)) do top = math.max(top, f:GetFrameLevel()) end
			eq(parts.line:GetFrameLevel(), c.frame:GetFrameLevel() + 4, key .. ': the line 4 over its row')
			for _, piece in ipairs({ 'ownText', 'reset', 'all', 'multiple' }) do
				eq(parts[piece]:GetFrameLevel(), parts.line:GetFrameLevel() + 1, key .. ': ' .. piece .. ' one over the line')
				check(parts[piece]:GetFrameLevel() > top, key .. ': ' .. piece .. ' over every part of the control')
			end
		end

		-- A half's line fits: whole, not cut.
		local sp = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		check(not sp.line:DoesClipChildren(), 'a line that fits is not cut')
		eq(sp.line:GetRight(), sp.multiple:GetRight(), 'it ends at its last link')
		for _, piece in ipairs({ 'ownText', 'reset', 'all', 'multiple' }) do
			check(sp[piece]:IsShown(), piece .. ' shown')
			eq((select(2, sp[piece]:GetHitRectInsets())), 0, piece .. ' takes the mouse whole')
		end
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(sp)

		-- Own's tooltip names the source's value; Reset's doesn't need to.
		stub.fire_script(sp.reset, 'OnEnter', true)
		eq(#tip.lines, 2, "a whole line's Reset: its title and what it does")
		stub.fire_script(sp.reset, 'OnLeave', true)

		-- A, in the first quarter: its whole line is wider than the cell, so it
		-- drops Own, then the words before All; the rest fits, uncut, ending
		-- inside the cell, never in B's.
		local a = by.a
		local parts = a.frame.share
		hover(a.frame, 5)
		stub.fire_script(a.frame, 'OnEnter', true)
		check(parts.line:IsShown())
		eq(a.frame:GetWidth(), 165, 'a quarter cell')
		check(not parts.ownText:IsShown(), 'Own dropped')
		check(not parts.sep:IsShown(), "'\194\183 Apply to:' dropped")
		for _, piece in ipairs({ 'reset', 'all', 'multiple' }) do
			check(parts[piece]:IsShown(), piece .. ' kept')
			eq((select(2, parts[piece]:GetHitRectInsets())), 0, piece .. ' takes the mouse whole')
		end
		eq(parts.line:GetLeft(), a.frame:GetLeft(), 'it starts under the label')
		eq(parts.reset:GetLeft(), parts.line:GetLeft(), 'with the reset icon')
		eq(parts.all:GetLeft() - parts.reset:GetRight(), 6, 'All 6 after it')
		eq(parts.line:GetRight(), parts.multiple:GetRight(), 'it ends at Multiple')
		check(parts.line:GetRight() <= a.frame:GetRight(), 'inside its cell')
		check(parts.line:GetRight() < by.b.frame:GetLeft(), "not in B's cell")
		check(not parts.line:DoesClipChildren(), 'whole: not cut')
		-- Own's tooltip line moves to Reset's.
		stub.fire_script(parts.reset, 'OnEnter', true)
		eq(tip.lines[1], 'Reset', "Reset's tooltip")
		eq(tip.lines[3], 'All bars: On', "with Own's line: the source and its value")
		stub.fire_script(parts.reset, 'OnLeave', true)
		eq(tip.owner, nil, 'gone with the mouse')
		stub.fire_script(parts.all, 'OnEnter', true)
		eq(tip.lines[1], 'Apply to: All', "the dropped words title All's tooltip")
		stub.fire_script(parts.all, 'OnLeave', true)
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(parts)

		-- Narrower still, the cut is the last resort. A dialog's 520 body: a
		-- quarter is 102 inside its padding, under the line left: Multiple runs
		-- past the cut and takes no mouse there.
		local function narrow_a(width)
			local narrowContent = CreateFrame('Frame', nil, UIParent)
			narrowContent:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
			narrowContent:SetSize(width, 600)
			local root = quarters('small')
			local narrow = OB.New(narrowContent, root, nil, width)
			narrow:Draw(OM.BuildView(root, 'page').sections)
			for _, each in ipairs(narrow.cells) do
				if each.row.key == 'a' then
					stub.fire_script(each.frame, 'OnEnter', true)
					return narrow, each, each.frame.share
				end
			end
		end
		local narrow, na, np = narrow_a(520)
		eq(na.frame:GetWidth(), 102, 'a narrow quarter')
		check(not np.ownText:IsShown() and not np.sep:IsShown(), 'Own and the words dropped first')
		check(np.multiple:GetRight() > na.frame:GetRight(), 'still wider than its room')
		eq(np.line:GetRight(), na.frame:GetRight(), "cut at the narrow cell's right edge")
		check(np.line:DoesClipChildren(), 'cut: what runs past is clipped')
		local cut = na.frame:GetRight()
		for _, piece in ipairs({ 'reset', 'all', 'multiple' }) do
			local p = np[piece]
			check(p:IsShown() and p:GetLeft() < cut, piece .. ' starts before the cut')
			eq((select(2, p:GetHitRectInsets())), math.max(0, p:GetRight() - cut), piece .. ' takes no mouse past the cut')
		end
		check(select(2, np.multiple:GetHitRectInsets()) > 0, 'Multiple is cut')
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(np)
		narrow:Release()

		-- A 300 body: a quarter is 47, and a piece wholly past the cut is
		-- hidden, taking no mouse at all.
		narrow, na, np = narrow_a(300)
		eq(na.frame:GetWidth(), 47, 'a narrower quarter')
		check(not np.multiple:IsShown(), 'Multiple hidden')
		check(np.multiple:GetLeft() >= na.frame:GetRight(), 'wholly past the cut')
		check(np.reset:IsShown() and np.all:IsShown(), 'what starts before it shows')
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(np)
		narrow:Release()

		-- The same frames drawn as halves: whole again.
		by = redraw(body, quarters(nil))
		parts = by.a.frame.share
		stub.fire_script(by.a.frame, 'OnEnter', true)
		check(not parts.line:DoesClipChildren(), 'a half: not cut')
		for _, piece in ipairs({ 'ownText', 'reset', 'all', 'multiple' }) do
			check(parts[piece]:IsShown(), piece .. ' shown again')
			eq((select(2, parts[piece]:GetHitRectInsets())), 0, piece .. ' takes the mouse whole again')
		end
		stub.cursor_x, stub.cursor_y = 0, 0
		watch(parts)
		body:Release()
	end)
end)

test("the line goes once the mouse leaves the body's view, though its row runs on past the view's edge", function()
	in_look('thick', function()
		fresh()
		own.spacing = true
		-- A view 40 tall over the content: the first row (20 to 58) is half out of it.
		local view = CreateFrame('Frame', nil, UIParent)
		view:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
		view:SetSize(774, 40)
		local content = CreateFrame('Frame', nil, view)
		content:SetPoint('TOPLEFT', view, 'TOPLEFT', 0, 0)
		content:SetSize(774, 600)
		local root = Page('member')
		local body = OB.New(content, root, nil, 774)
		body:Draw(OM.BuildView(root, 'page').sections)
		local c = body.cells[1]
		eq(c.row.key, 'spacing')
		local parts = c.frame.share
		local scale = c.frame:GetEffectiveScale()
		local function at(y) -- the cursor 10 into the row, y down its content
			stub.cursor_x = (c.frame:GetLeft() + 10) * scale
			stub.cursor_y = (content:GetTop() - y) * scale
		end
		at(c.y + 6) -- in the row, in the view
		stub.fire_script(c.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'shown')
		watch(parts)
		check(parts.line:IsShown(), 'kept in the view')
		at(c.y + c.height - 2) -- still on the row (under its line), past the view's edge
		check(c.frame:IsMouseOver() and not view:IsMouseOver(), 'on the row, off the view')
		watch(parts)
		check(not parts.line:IsShown(), 'gone once the view is not under the mouse')
		eq((point(c.label)), 'LEFT', 'its label back')
		body:Release()
	end)
end)

-- OB.OWN_STRENGTH is the owner's knob for the own marks: every site that draws
-- an own label or title takes it, so a lower strength is the label's alpha.
test('OB.OWN_STRENGTH is the alpha of an own label, across Refresh, of the hover line\'s Own and of an own title', function()
	local OB = st.OptionsBody
	local function alpha(fs) return string.format('%.2f', (select(4, fs:GetTextColor()))) end
	OB.OWN_STRENGTH = 0.5
	local ok, err = pcall(function()
		in_look('thick', function()
			fresh()
			own.spacing = true
			local disabled = false
			local root = Page('member')
			root.page.args.spacing.disabled = function() return disabled end
			local body, by = draw(root)
			eq(alpha(by.spacing.label), '0.50', 'the own label')
			check(by.spacing.frame.share.ownText ~= nil, "the hover line's Own exists")
			eq(alpha(by.spacing.frame.share.ownText.text), '0.50', "the hover line's Own")
			disabled = true
			body:Refresh()
			disabled = false
			body:Refresh()
			eq(alpha(by.spacing.label), '0.50', 'the label across Refresh')
			body:Release()

			own.pos = true
			local titled = draw(Page('member', { pos = { type = 'position', name = 'Position', order = 10, share = true } }))
			eq(alpha(titled.shareTitles[1].title), '0.50', 'the own title')
		end)
	end)
	OB.OWN_STRENGTH = 1
	if not ok then error(err, 0) end
end)

test('an own row keeps its accent label across Refresh: disabled then enabled again, or drawn disabled and enabled mid-drag', function()
	in_look('thick', function()
		fresh()
		own.spacing = true
		local disabled = false
		local root = Page('member')
		root.page.args.spacing.disabled = function() return disabled end
		local body, by = draw(root)
		eq(text_rgb(by.spacing.label), OWN, 'the accent')
		disabled = true
		body:Refresh()
		eq(text_rgb(by.spacing.label), grey(), 'grey while disabled')
		disabled = false
		body:Refresh()
		eq(text_rgb(by.spacing.label), OWN, 'the accent again')
		-- Drawn while disabled, then enabled mid-drag.
		disabled = true
		by = redraw(body, root)
		eq(text_rgb(by.spacing.label), grey(), 'drawn disabled: grey')
		check(shown(by.spacing.frame.share, 'mark'), 'with its mark')
		disabled = false
		body:Refresh()
		eq(text_rgb(by.spacing.label), OWN, 'enabled mid-drag: the accent, not Text > Normal')
		body:Release()
	end)
end)

test("no tooltip builds s's: All and Multiple name no page's or source's own, the rest put just an apostrophe after an s", function()
	in_look('thick', function(tip)
		fresh()
		own.spacing = true
		local root = Page('member')
		root.page.args.spacing.share.page = 'Totems'
		local body, by = draw(root)
		local parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		local texts = {}
		local function read(piece)
			local text = read_tip(tip, parts[piece])
			texts[#texts + 1] = text
			return text
		end
		eq(read('reset'), "Reset|Spacing follows All bars again. Totems' own value is dropped.")
		eq(read('all'), 'Apply to: All|All bars takes Spacing from Totems, and nothing keeps its own any more.')
		eq(read('multiple'), 'Apply to: Multiple|Pick which take Spacing from Totems as their own.')
		eq(read('ownText'), 'Spacing|All bars: 3')
		-- A page with no name of its own.
		root.page.args.spacing.share.page = nil
		by = redraw(body, root)
		parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		eq(read('reset'), 'Reset|Spacing follows All bars again. Its own value is dropped.')
		eq(read('all'), 'Apply to: All|All bars takes Spacing from this page, and nothing keeps its own any more.')

		-- The source page, whose name ends in s.
		fresh()
		differs.spacing = { { name = 'Totems', value = '2' } }
		by = redraw(body, Page('source'))
		parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		eq(read('all'), 'Apply to: All|Everything that keeps its own Spacing follows All bars again.')
		eq(read('multiple'), 'Apply to: Multiple|Pick which follow All bars again for Spacing.')
		texts[#texts + 1] = read_tip(tip, parts.diff)
		for _, text in ipairs(texts) do
			check(not text:find("s's", 1, true), "no s's: " .. text)
		end
		body:Release()
	end)
end)

test("a share's noun and pageText: the tooltips name the members ('every bar', 'which bars') and the page with its article", function()
	in_look('thick', function(tip)
		-- A member page whose name reads as a common noun: the module says how
		-- it reads in a sentence (pageText); Core only starts a sentence with a
		-- capital.
		fresh()
		own.spacing = true
		local root = Page('member')
		local share = root.page.args.spacing.share
		share.page, share.pageText, share.noun = 'Pet bar', 'the Pet bar', { 'bar', 'bars' }
		local body, by = draw(root)
		local parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		eq(read_tip(tip, parts.reset), "Reset|Spacing follows All bars again. The Pet bar's own value is dropped.")
		eq(read_tip(tip, parts.all), 'Apply to: All|All bars takes Spacing from the Pet bar, and no bar keeps its own any more.')
		eq(read_tip(tip, parts.multiple), 'Apply to: Multiple|Pick which bars take Spacing from the Pet bar as their own.')
		eq(read_tip(tip, parts.ownText), 'Spacing|All bars: 3', 'Own names no page')

		-- A name that reads as a name: pageText is the name itself.
		share.page, share.pageText = 'Bar 3', 'Bar 3'
		by = redraw(body, root)
		parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		eq(read_tip(tip, parts.reset), "Reset|Spacing follows All bars again. Bar 3's own value is dropped.")
		eq(read_tip(tip, parts.all), 'Apply to: All|All bars takes Spacing from Bar 3, and no bar keeps its own any more.')

		-- A noun that isn't two strings is no noun: the wording as without one.
		share.noun = { 'bar' }
		by = redraw(body, root)
		parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		eq(read_tip(tip, parts.multiple), 'Apply to: Multiple|Pick which take Spacing from Bar 3 as their own.')

		-- The source page.
		fresh()
		differs.spacing = { { name = 'Pet bar', value = '2' } }
		root = Page('source')
		root.page.args.spacing.share.noun = { 'bar', 'bars' }
		by = redraw(body, root)
		parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		eq(read_tip(tip, parts.all), 'Apply to: All|Every bar that keeps its own Spacing follows All bars again.')
		eq(read_tip(tip, parts.multiple), 'Apply to: Multiple|Pick which bars follow All bars again for Spacing.')
		body:Release()
	end)
end)

test('OM.ShareState hands on the noun and pageText, as text, or nil without them', function()
	fresh()
	local root = Page('member')
	local share = root.page.args.spacing.share
	local function state() return OM.ShareState(root, row_of(root, 'spacing')) end
	eq(state().noun, nil, 'no noun')
	eq(state().pageText, nil, 'no pageText')
	share.noun, share.pageText = { 'bar', 'bars' }, 'the Pet bar'
	eq(table.concat(state().noun, ','), 'bar,bars', 'the noun, singular and plural')
	eq(state().pageText, 'the Pet bar', 'the page in a sentence')
	share.noun, share.pageText = { 'bar', 7 }, ''
	eq(state().noun, nil, 'a noun of anything but two strings is none')
	eq(state().pageText, nil, 'an empty pageText is none')
end)

test("an item's row: its line's tooltips name its Show, its diff tooltip has no source line, and its label sits labelX in", function()
	in_look('thick', function(tip)
		do
			fresh()
			own.hotkey = true
			local body, by = draw(Page('member', { hotkey = Item('member') }))
			local c = by.hotkey
			local parts = c.frame.share
			-- labelX: the label 26 in, lifted and put back there, the line under it.
			eq((select(4, point(c.label))), ITEM_LABEL_X, 'the label 26 in')
			eq(c.label:GetWidth(), c.frame:GetWidth() - ITEM_LABEL_X - ITEM_STOP, 'its width the rest, up to 6 before the dots')
			hover(c.frame, 40)
			stub.fire_script(c.frame, 'OnEnter', true)
			check(parts.line:IsShown(), 'its line')
			local p, _, _, x, y = point(c.label)
			eq(p .. ' ' .. x .. ',' .. y, 'TOPLEFT 26,-4', 'lifted where it sits')
			eq(parts.line:GetLeft() - c.frame:GetLeft(), ITEM_LABEL_X, 'the line under it')
			eq(read_tip(tip, parts.ownText), "Hotkey's Show|All bars: Shown")
			eq(read_tip(tip, parts.reset), "Reset|Hotkey's Show follows All bars again. Bar 3's own value is dropped.")
			eq(read_tip(tip, parts.all), "Apply to: All|All bars takes Hotkey's Show from Bar 3, and nothing keeps its own any more.")
			eq(read_tip(tip, parts.multiple), "Apply to: Multiple|Pick which take Hotkey's Show from Bar 3 as their own.")
			stub.cursor_x, stub.cursor_y = 0, 0
			watch(parts)
			check(not parts.line:IsShown(), 'gone')
			local lp, _, _, lx = point(c.label)
			eq(lp .. ' ' .. lx, 'LEFT 26', 'the label back at 26')
			-- (the reset is part of the hover line, hidden once the cursor moved off: press it unchecked)
			stub.click_unchecked(parts.reset)
			eq(calls[1].action .. ' ' .. calls[1].key, 'reset hotkey', "Reset acts on the item's own share, its Show")

			-- Under Blizzard the mark's shift adds to it.
			in_look('blizzard', function()
				by = redraw(body, Page('member', { hotkey = Item('member') }))
				eq((select(4, point(by.hotkey.label))), ITEM_LABEL_X + 6, 'Blizzard: 26 and the shift of 6')
				stub.fire_script(by.hotkey.frame, 'OnEnter', true)
				eq(by.hotkey.frame.share.line:GetLeft() - by.hotkey.frame:GetLeft(), ITEM_LABEL_X + 6, 'the line under it')
				stub.cursor_x, stub.cursor_y = 0, 0
				watch(by.hotkey.frame.share)
			end)

			-- The source page: its diff tooltip, two columns, no source line.
			fresh()
			differs.hotkey = { { name = 'Bar 3', value = 'Hidden' } }
			differs.size = { { name = 'Bar 5', value = '9' } }
			by = redraw(body, Page('source', { hotkey = Item('source') }))
			c = by.hotkey
			eq(read_tip(tip, c.frame.share.diff), 'Hotkey|Bar 3 = Show|Bar 5 = Size', 'the name, then a line per page')
			eq(c.frame.share.diff:GetLeft() - c.label:GetLeft(), math.ceil(c.label:GetUnboundedStringWidth()) + 4, 'the icon after the label')
			stub.fire_script(c.frame, 'OnEnter', true)
			eq(read_tip(tip, c.frame.share.multiple), "Apply to: Multiple|Pick which follow All bars again for Hotkey's Show.")
			stub.cursor_x, stub.cursor_y = 0, 0
			watch(c.frame.share)
			body:Release()
		end
	end)
end)

test("a shareable position row's state is asked once a draw, its title reusing it", function()
	in_look('thick', function()
		fresh()
		own.pos = true
		local root = Page('member', { pos = { type = 'position', name = 'Position', order = 10, share = true } })
		local asked = 0
		local share = root.page.args.pos.share
		local ownOf = share.own
		share.own = function(info)
			asked = asked + 1
			return ownOf(info)
		end
		local body = draw(root)
		eq(#body.shareTitles, 1, 'its title drawn')
		eq(text_rgb(body.shareTitles[1].title), OWN, 'and marked')
		eq(asked, 1, 'own asked once: the row and its title share one state')
		body:Release()
	end)
end)

test('a pooled frame drawn for a plain row keeps nothing of the shareable row it last held', function()
	in_look('thick', function()
		fresh()
		own.spacing = true
		local body, by = draw(Page('member'))
		local frame = by.spacing.frame
		stub.fire_script(frame, 'OnEnter', true)
		check(frame.share.line:IsShown(), 'its line up')
		local plain = { page = { type = 'group', name = 'P', get = function() return 1 end, set = function() end, args = {
			a = { type = 'range', name = 'A', order = 1, min = 0, max = 10, step = 1 },
		} } }
		by = redraw(body, plain)
		check(by.a.frame == frame, 'the same frame')
		check(not frame.share.line:IsShown(), 'its line hidden')
		hover(by.a.frame, 10)
		stub.fire_script(by.a.frame, 'OnEnter', true)
		check(not frame.share.line:IsShown(), 'no line on entering')
		eq((point(by.a.label)), 'LEFT', 'its label unmoved')
		stub.fire_script(by.a.widget.slider, 'OnEnter', true)
		check(not frame.share.line:IsShown(), 'nor through its control')
		eq((point(by.a.label)), 'LEFT', 'still unmoved')
		body:Release()
	end)
end)

test("a title's hover frame drawn again keeps nothing of its last title and goes with a release; a disabled block's title offers no line", function()
	in_look('thick', function()
		fresh()
		differs.pos = { { name = 'Bar 3', value = 'Center' } }
		local function pos() return { type = 'position', name = 'Position', order = 10, share = true } end
		local body = draw(Page('source', { pos = pos() }))
		local hover = body.shareTitles[1].hover
		check(body.shareTitles[1].parts.diff:IsShown(), 'the source title has its diff icon')
		fresh()
		own.pos = true
		redraw(body, Page('member', { pos = pos() }))
		check(body.shareTitles[1].hover == hover, 'the same hover frame')
		check(not body.shareTitles[1].parts.diff:IsShown(), 'its diff icon gone: nothing differs on a member page')
		local entry = body.shareTitles[1]
		check(entry.hover:IsShown(), 'shown while drawn')
		body:Release()
		check(not entry.hover:IsShown(), 'a release hides it')

		local root = Page('member', { pos = pos() })
		root.page.args.pos.disabled = true
		redraw(body, root)
		entry = body.shareTitles[1]
		check(entry ~= nil, 'a disabled own block still marks its title')
		stub.fire_script(entry.hover, 'OnEnter', true)
		check(not entry.parts.line:IsShown(), 'but offers no line')
		body:Release()
	end)
end)

test("the diff icon's hover shows its row's line too", function()
	in_look('thick', function()
		fresh()
		differs.spacing = { { name = 'Bar 2', value = '2' } }
		local body, by = draw(Page('source'))
		local parts = by.spacing.frame.share
		hover(parts.diff)
		stub.fire_script(parts.diff, 'OnEnter', true)
		check(parts.line:IsShown(), 'reached straight onto the icon: the line shows')
		stub.fire_script(parts.diff, 'OnLeave', true)
		body:Release()
	end)
end)

test("a link's click takes its tooltip away, and leaving a link puts its accent back", function()
	in_look('thick', function(tip)
		fresh()
		own.spacing = true
		local body, by = draw(Page('member'))
		local parts = by.spacing.frame.share
		stub.fire_script(by.spacing.frame, 'OnEnter', true)
		local textBlue = rgb(st.config.profile.theme.accent:GetRGB())
		local buttonBlue = rgb(st.config.profile.theme.accent:GetRGB())
		for _, key in ipairs({ 'all', 'multiple' }) do
			stub.fire_script(parts[key], 'OnEnter', true)
			eq(rgb(parts[key].text:GetTextColor()), '1.00,1.00,1.00', key .. ' white under the mouse')
			stub.fire_script(parts[key], 'OnLeave', true)
			eq(rgb(parts[key].text:GetTextColor()), textBlue, key .. ' in the accent again')
		end
		-- The reset icon: Text > Grey at rest, lit in the accent under the mouse.
		local textGrey = rgb(st.config.profile.colors.text.grey:GetRGB())
		eq(rgb(parts.reset.icon:GetVertexColor()), textGrey, 'the reset icon Text > Grey at rest')
		stub.fire_script(parts.reset, 'OnEnter', true)
		eq(rgb(parts.reset.icon:GetVertexColor()), buttonBlue, 'the reset icon in the accent under the mouse')
		stub.fire_script(parts.reset, 'OnLeave', true)
		eq(rgb(parts.reset.icon:GetVertexColor()), textGrey, 'and grey again')
		for _, key in ipairs({ 'all', 'multiple' }) do
			stub.fire_script(parts[key], 'OnEnter', true)
			check(tip.owner == parts[key], key .. ' shows its tooltip')
			stub.click(parts[key])
			check(tip.owner == nil, key .. "'s click takes it away")
			W.CloseList()
		end
		body:Release()
	end)
end)

test("ShareState: a hidden option in an item's menu neither marks nor diffs it", function()
	fresh()
	own.size = true
	local item = Item('member')
	item.menu.args.size.hidden = true
	eq(state_of(Page('member', { hotkey = item }), 'hotkey').marked, false, 'its hidden Size marks nothing')
	fresh()
	differs.size = { { name = 'Bar 5', value = '9' } }
	item = Item('source')
	item.menu.args.size.hidden = true
	eq(#state_of(Page('source', { hotkey = item }), 'hotkey').differs, 0, 'nor diffs')
end)

test('ShareCall refuses an action it has no name for; ShareTargets leaves out a target with no key', function()
	fresh()
	local root = Page('member')
	local row = row_of(root, 'spacing')
	local ok, err = pcall(OM.ShareCall, root, row, 'bogus')
	check(not ok, 'an unknown action errors')
	check(tostring(err):find('no share action', 1, true) ~= nil, 'naming it')
	eq(#calls, 0, 'nothing ran')
	root.page.args.spacing.share.targets = function()
		return { { label = 'No key' }, { key = 'bar2', label = 'Bar 2' }, 'junk' }
	end
	local targets = OM.ShareTargets(root, row)
	eq(#targets, 1, 'only the target with a key')
	eq(targets[1] and targets[1].key, 'bar2')
end)
