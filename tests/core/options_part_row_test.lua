-- The kit's part row (SaftUI-Core/Config/optionsitem.lua, optionsbody.lua's
-- PlaceRow and optionsshare.lua's PlaceSummary): an item with a `summary`, drawn
-- as a half row with its box, label, summary, reset icon and dots; the summary
-- giving way to the label and its hover line; the click that opens its menu; the
-- Row hover; and the one kit rule that goes with it, the dots resting in
-- Text > Normal while any row of its menu would offer its reset.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0,
-- the model, the widgets, the body and the window's files, as
-- options_window_helpers.lua loads them (options_item_test.lua's world). The
-- pages are synthetic: a part row 'name' (summary 'Health', tip 'Right of Health:
-- -7, -1') whose menu holds All caps (a small toggle), Outline (a select) and Max
-- length (a range), each with a default of its own; shares on a member page
-- (Player) and on the source page (All units). The mouse is played with
-- stub.cursor_x and stub.cursor_y and by firing the frames' scripts, OnEnter and
-- OnLeave with true as the game passes them.
load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local OM, W, OB, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsBody, st.OptionsWindow

------------------------------------------------------------------ the synthetic pages

local v, own, differs, resets -- the values; the member page's own; the source page's differs; the resets run

local function fresh()
	v = { name = true, caps = false, outline = 'none', size = 30, sum = 'Health', tip = 'Right of Health: -7, -1' }
	own, differs, resets = {}, {}, {}
end
fresh()

local function Default(key, default)
	return {
		differs = function() return v[key] ~= default end,
		reset = function() v[key] = default; resets[#resets + 1] = key end,
		value = function() return default end,
	}
end

local function MemberShare(key)
	return {
		source = 'All units', page = 'Player', pageText = 'Player', noun = { 'unit frame', 'unit frames' },
		own = function() return own[key] end,
		reset = function() own[key] = false end, applyAll = function() end, apply = function() end,
		shared = function() return 'on' end, targets = function() return {} end,
	}
end

local function SourceShare(key)
	return {
		source = 'All units', noun = { 'unit frame', 'unit frames' },
		differs = function() return differs[key] or {} end,
		shared = function() return 'on' end, applyAll = function() end, apply = function() end,
		targets = function() return {} end,
	}
end

local function SharedBy(kind, key)
	if kind == 'member' then return MemberShare(key) end
	if kind == 'source' then return SourceShare(key) end
end

-- A part's menu: All caps (small), Outline, Max length, each with a default of its
-- own, and a share of kind (nil, 'member' or 'source') on each.
local function Menu(name, kind)
	return {
		type = 'group', name = name,
		get = function(info) return v[info[#info]] end,
		set = function(info, value) v[info[#info]] = value end,
		args = {
			caps = { type = 'toggle', name = 'All caps', desc = 'Capitals.', order = 1, size = 'small',
				default = Default('caps', false), share = SharedBy(kind, 'caps') },
			outline = { type = 'select', name = 'Outline', desc = 'Its outline.', order = 2,
				values = { none = 'None', thick = 'Thick' }, default = Default('outline', 'none'), share = SharedBy(kind, 'outline') },
			size = { type = 'range', name = 'Max length', desc = 'Its length.', order = 3, min = 1, max = 50, step = 1,
				default = Default('size', 30), share = SharedBy(kind, 'size') },
		},
	}
end

-- A part row: its Show is v.name, its reset the box's own, its summary v.sum
-- (and tip), its menu above. o.kind: the shares ('member', 'source'); o.plain:
-- no summary (an action bars item).
local function Part(name, order, o)
	o = o or {}
	local item = {
		type = 'item', name = name, desc = name .. ' desc.', order = order, menuTitle = name,
		get = function() return v.name end,
		set = function(_, value) v.name = value end,
		default = Default('name', true),
		summary = not o.plain and function() return v.sum, v.tip end or nil,
		menu = Menu(name, o.kind),
		share = SharedBy(o.kind, 'name'),
	}
	return item
end

local function Page(args)
	return { page = { type = 'group', name = 'Page', args = args } }
end

------------------------------------------------------------------ drawing helpers

-- A body on a content frame at the screen's top left, the page drawn, its cells
-- by key; half: the window's half width (body:SetWidth(width, true)).
local function draw(root, width, half)
	width = width or 774
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(width, 700)
	local body = OB.New(content, root, nil, width)
	if half then body:SetWidth(width, true) end
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by, content
end

-- The same body drawn again from root (released first): its pooled frames are used
-- again. Returns its cells by key.
local function redraw(body, root)
	body:Release()
	body:SetRoot(root)
	body:Draw(OM.BuildView(root, 'page').sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return by
end

-- GameTooltip, as a stand-in that notes each line it's given.
local function watch_tooltip()
	local tip = { lines = {} }
	local saved = _G.GameTooltip
	_G.GameTooltip = {
		SetOwner = function(_, frame) tip.owner = frame; tip.lines = {} end,
		ClearLines = function() tip.lines = {} end,
		AddLine = function(_, text) tip.lines[#tip.lines + 1] = text end,
		AddDoubleLine = function(_, left) tip.lines[#tip.lines + 1] = left end,
		Show = function() end,
		IsOwned = function(_, frame) return tip.owner == frame end,
		Hide = function() tip.owner = nil end,
	}
	return tip, function() _G.GameTooltip = saved end
end

-- fn(tip) under look with GameTooltip watched; the look, the cursor, the list, the
-- tooltip, the menu and the sizes put back after.
local function in_look(look, fn)
	st.config.profile.theme.name = look
	local tip, restore = watch_tooltip()
	local ok, err = pcall(fn, tip)
	W.CloseList()
	OW:CloseMenu()
	restore()
	st.config.profile.theme.name = 'thick'
	stub.cursor_x, stub.cursor_y = 0, 0
	stub.size_noise = 0
	if not ok then error(err, 0) end
end

-- The cursor on the middle of a region, or x in from its left, in screen units.
local function hover(region, x)
	local scale = region:GetEffectiveScale()
	local left = x and region:GetLeft() + x or (region:GetLeft() + region:GetRight()) / 2
	stub.cursor_x = left * scale
	stub.cursor_y = (region:GetTop() + region:GetBottom()) / 2 * scale
end

local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function text_rgb(fs) return rgb(fs:GetTextColor()) end
local function vertex(texture) return rgb(texture:GetVertexColor()) end
local function color(group, key) return rgb(st.config.profile.colors[group][key]:GetRGB()) end
local function x_in(region, frame) return region:GetLeft() - frame:GetLeft() end
local function mid(region) return (region:GetTop() + region:GetBottom()) / 2 end
local function width_of(fs) return math.ceil(fs:GetUnboundedStringWidth()) end

-- A name of n characters (8 wide each in the stubs' label font), unique per n.
local function name_of(n) return ('N'):rep(n) end

------------------------------------------------------------------ the layout

test('a part row lays out its box, label, summary and dots in a half cell, under Thick, Thin and Blizzard', function()
	-- cell x and width: the slot 387 less the padding's 14 each side under Thick and
	-- Thin; the whole 367 under Blizzard.
	local function check_row(look, cellX, cellW)
		in_look(look, function()
			fresh()
			local body, by, content = draw(Page({ name = Part('Name', 1) }))
			local c, w = by.name, by.name.widget
			local where = look .. ': '
			eq(x_in(c.frame, content), cellX, where .. 'the cell')
			eq(c.frame:GetWidth(), cellW, where .. 'a half cell')
			eq(x_in(w.box, content), cellX, where .. "the box at the cell's left")
			eq(x_in(c.label, content), cellX + 26, where .. 'the label 26 in')
			eq(x_in(w.dots, content) + w.dots:GetWidth(), cellX + cellW, where .. "the dots at the cell's right")
			local dotsLeft = x_in(w.dots, content)
			check(w.summary:IsShown(), where .. 'the summary shown')
			eq(w.summary:GetText(), 'Health', where .. 'its text')
			eq(w.summary:GetRight() - content:GetLeft(), dotsLeft - 6, where .. 'ending 6 before the dots')
			eq(text_rgb(w.summary), color('text', 'muted'), where .. 'Text > Muted')
			eq(mid(w.summary), mid(c.frame), where .. 'centred on the row')
			eq(c.frame.partRow, w, where .. 'a part row')
			eq(c.lineInline, true, where .. 'its line inline')
			check(c.frame.shareLifts ~= true, where .. 'and never lifts')
			body:Release()
		end)
	end
	check_row('thick', 14, 359)
	check_row('thin', 14, 359)
	check_row('blizzard', 0, 367)
end)

test('an item with no summary is as it was: no summary, no part row', function()
	in_look('thick', function()
		fresh()
		local body, by = draw(Page({ name = Part('Name', 1, { plain = true }) }))
		local c, w = by.name, by.name.widget
		check(not w.summary:IsShown(), 'no summary')
		eq(c.frame.partRow, nil, 'not a part row')
		check(not c.lineInline, 'no inline line')
		eq(c.label:GetWidth(), 359 - 26 - 16 - 6, 'its label as wide as before')
		-- A part row drawn on the same pooled frame after: the flag is set again.
		local frame = by.name.frame
		by = redraw(body, Page({ name = Part('Name', 1) }))
		eq(by.name.frame, frame, 'the same pooled frame')
		eq(by.name.frame.partRow, by.name.widget, 'a part row on the pooled frame')
		check(by.name.widget.summary:IsShown(), 'with its summary')
		by = redraw(body, Page({ name = Part('Name', 1, { plain = true }) }))
		eq(by.name.frame, frame, 'the same pooled frame')
		eq(by.name.frame.partRow, nil, 'and cleared on the next row that is none')
		check(not by.name.widget.summary:IsShown(), 'its summary gone')
		body:Release()
	end)
end)

test('a part with no summary text shows none, and a reset icon makes the summary end 6 before it', function()
	in_look('thick', function()
		fresh()
		v.sum = nil
		local body, by = draw(Page({ name = Part('Name', 1) }))
		check(not by.name.widget.summary:IsShown(), 'a summary of nil: hidden')
		body:Release()
		v.sum = ''
		body, by = draw(Page({ name = Part('Name', 1) }))
		check(not by.name.widget.summary:IsShown(), 'and an empty one')
		body:Release()

		fresh()
		v.name = false -- its box differs from its default: the reset icon, right against the dots
		body, by = draw(Page({ name = Part('Name', 1) }))
		local c, w = by.name, by.name.widget
		local icon = c.frame.defaultReset
		check(icon and icon:IsShown(), "the box's own reset icon")
		eq(icon:GetRight(), w.dots:GetLeft(), 'right against the dots')
		eq(w.summary:GetRight(), icon:GetLeft() - 6, 'the summary ends 6 before it')
		-- The label is Muted while the part is off.
		eq(text_rgb(c.label), color('text', 'muted'), 'its label Text > Muted')
		body:Release()
	end)
end)

test('the summary gives way: cut to the room after the label and 12, hidden under 24', function()
	in_look('thick', function()
		fresh()
		-- The cell 359; the label 26 in; the summary ends 22 before the cell's right edge.
		local function room(n) return 359 - 26 - n * 8 - 12 - 22 end
		local body, by = draw(Page({ name = Part(name_of(38), 1) }))
		check(room(38) < 24, 'the case: a long label leaves under 24')
		check(not by.name.widget.summary:IsShown(), 'a label this long: the summary hidden')
		body:Release()

		body, by = draw(Page({ name = Part(name_of(32), 1) }))
		local w = by.name.widget
		check(room(32) >= 24 and room(32) < width_of(w.summary), 'the case: 43 is room, short of the text')
		check(w.summary:IsShown(), 'a label this long: the summary shown')
		check(w.summary:GetWidth() <= room(32), 'cut to the room (' .. w.summary:GetWidth() .. ' of ' .. room(32) .. ')')
		check(x_in(w.summary, by.name.frame) >= 26 + 32 * 8 + 12, 'starting 12 after the label')
		body:Release()

		-- A short name: the whole text, no wider than it needs.
		body, by = draw(Page({ name = Part('Name', 1) }))
		w = by.name.widget
		eq(w.summary:GetWidth(), width_of(w.summary), 'the whole text when there is room')
		body:Release()

		-- A diff icon after the label takes its room too (the source page).
		fresh()
		differs.name = { { name = 'Party', value = 'Show' } }
		body, by = draw(Page({ name = Part(name_of(20), 1, { kind = 'source' }) }))
		local c = by.name
		local diff = c.frame.share.diff
		check(diff:IsShown(), 'the diff icon')
		check(c.widget.summary:IsShown(), 'the summary beside it')
		check(c.widget.summary:GetLeft() >= diff:GetRight() + 12, 'at least 12 after the diff icon')
		body:Release()
	end)
end)

test("the summary's tooltip is its tip", function()
	in_look('thick', function(tip)
		fresh()
		local body, by = draw(Page({ name = Part('Name', 1) }))
		local w = by.name.widget
		stub.fire_script(w.summaryHit, 'OnEnter', true)
		eq(tip.lines[1], 'Right of Health: -7, -1', 'its tip')
		eq(tip.owner, w.summaryHit, 'owned by the frame over the summary')
		stub.fire_script(w.summaryHit, 'OnLeave', true)
		eq(tip.owner, nil, 'gone on leave')
		-- Over the summary, the row's own tooltip is not shown, but the summary is part of the row: a click opens the menu.
		hover(w.summaryHit)
		stub.fire_script(w.summaryHit, 'OnMouseUp', 'LeftButton')
		check(OW:IsMenuShown(w), 'a click on the summary opens the menu')
		OW:CloseMenu()
		body:Release()
		-- No tip: the summary has no tooltip.
		v.tip = nil
		body, by = draw(Page({ name = Part('Name', 1) }))
		stub.fire_script(by.name.widget.summaryHit, 'OnEnter', true)
		eq(tip.owner, nil, 'a summary with no tip shows none')
		body:Release()
	end)
end)

test('at half size a part row is a whole line', function()
	for _, case in ipairs({ { 'thick', 388, 360, 14 }, { 'thin', 388, 360, 14 }, { 'blizzard', 368, 368, 0 } }) do
		local look, width, cell, x = case[1], case[2], case[3], case[4]
		in_look(look, function()
			fresh()
			local body, by, content = draw(Page({ name = Part('Name', 1), other = Part('Other', 2) }), width, true)
			local c = by.name
			eq(c.frame:GetWidth(), cell, look .. ': the whole line')
			eq(x_in(c.frame, content), x, look .. ': at the padding')
			eq(by.other.frame:GetTop() < c.frame:GetTop(), true, look .. ': one to a line')
			local w = c.widget
			eq(w.summary:GetRight() - content:GetLeft(), x_in(w.dots, content) - 6, look .. ': the summary 6 before the dots')
			eq(w.summary:GetWidth(), width_of(w.summary), look .. ': with room for its whole text')
			body:Release()
		end)
	end
end)

------------------------------------------------------------------ the dots

test('an item with a summary rests its dots in Text > Normal while any row of its menu would offer its reset, with a tooltip saying how many', function()
	in_look('thick', function(tip)
		fresh()
		local function drawn() return draw(Page({ name = Part('Name', 1), plain = Part('Plain', 2, { plain = true }) })) end
		local body, by = drawn()
		eq(vertex(by.name.widget.dots.icon), color('text', 'muted'), 'nothing differs: Text > Muted')
		stub.fire_script(by.name.widget.dots, 'OnEnter', true)
		eq(tip.owner, nil, 'and no tooltip')
		stub.fire_script(by.name.widget.dots, 'OnLeave', true)
		body:Release()

		v.size = 12
		body, by = drawn()
		local dots = by.name.widget.dots
		eq(vertex(dots.icon), color('text', 'normal'), 'Max length differs: Text > Normal')
		eq(vertex(by.plain.widget.dots.icon), color('text', 'muted'), 'an item with no summary stays Muted')
		stub.fire_script(dots, 'OnEnter', true)
		eq(vertex(dots.icon), rgb(st:StateColor('edgeHover')), 'the lighter tone under the mouse')
		eq(tip.lines[1], 'Name', 'the tooltip is titled with the part')
		eq(tip.lines[2], '1 setting here differs from its default.', 'one setting')
		stub.fire_script(dots, 'OnLeave', true)
		eq(vertex(dots.icon), color('text', 'normal'), 'Normal again, not Muted')
		body:Release()

		v.caps = true
		body, by = drawn()
		stub.fire_script(by.name.widget.dots, 'OnEnter', true)
		eq(tip.lines[2], '2 settings here differ from their defaults.', 'two settings')
		stub.fire_script(by.name.widget.dots, 'OnLeave', true)
		body:Release()

		-- The part's own Show differing is the box's reset, not the dots'.
		fresh()
		v.name = false
		body, by = drawn()
		eq(vertex(by.name.widget.dots.icon), color('text', 'muted'), 'its Show differing alone: Muted')
		body:Release()

		-- Back to its default: Muted again, from the same pooled widget.
		fresh()
		body, by = drawn()
		eq(vertex(by.name.widget.dots.icon), color('text', 'muted'), 'back to Muted')
		body:Release()
	end)
end)

test("on a member page the dots are Normal while a row of the menu is the page's own, and say so", function()
	in_look('thick', function(tip)
		fresh()
		own.size, own.caps = true, true
		local body, by = draw(Page({ name = Part('Name', 1, { kind = 'member' }) }))
		local dots = by.name.widget.dots
		eq(vertex(dots.icon), color('text', 'normal'), "two own rows: Text > Normal")
		stub.fire_script(dots, 'OnEnter', true)
		eq(tip.lines[2], "2 settings here are Player's own.", 'named by the page')
		stub.fire_script(dots, 'OnLeave', true)
		body:Release()

		fresh()
		v.size = 12 -- differs from its default, but a member row is judged by its share, not its default
		body, by = draw(Page({ name = Part('Name', 1, { kind = 'member' }) }))
		eq(vertex(by.name.widget.dots.icon), color('text', 'muted'), 'a member row that follows All units: Muted')
		body:Release()

		fresh()
		own.outline = true
		body, by = draw(Page({ name = Part('Name', 1, { kind = 'member' }) }))
		stub.fire_script(by.name.widget.dots, 'OnEnter', true)
		eq(tip.lines[2], "1 setting here is Player's own.", 'one')
		stub.fire_script(by.name.widget.dots, 'OnLeave', true)
		body:Release()

		-- All units: its rows' defaults, as on a page with no sharing.
		fresh()
		v.outline = 'thick'
		body, by = draw(Page({ name = Part('Name', 1, { kind = 'source' }) }))
		eq(vertex(by.name.widget.dots.icon), color('text', 'normal'), 'the source page: a default that differs')
		body:Release()
	end)
end)

test('a hidden or disabled row of the menu offers no reset: it does not light the dots', function()
	in_look('thick', function()
		fresh()
		v.size = 12
		local hide = true
		local item = Part('Name', 1)
		item.menu.args.size.hidden = function() return hide end
		local body, by = draw(Page({ name = item }))
		eq(vertex(by.name.widget.dots.icon), color('text', 'muted'), 'hidden: Muted')
		body:Release()
		hide = false
		item.menu.args.size.disabled = true
		body, by = draw(Page({ name = item }))
		eq(vertex(by.name.widget.dots.icon), color('text', 'muted'), 'disabled: Muted')
		body:Release()
		item.menu.args.size.disabled = nil
		body, by = draw(Page({ name = item }))
		eq(vertex(by.name.widget.dots.icon), color('text', 'normal'), 'shown and enabled: Normal')
		body:Release()
	end)
end)

test('OM.MenuOffers counts the menu rows that offer a reset and makes no table asking', function()
	in_look('thick', function()
		-- Rows whose reset is derived from where they are saved: the icon's own compare makes no table.
		st.defaults.pr_ = { caps = false, size = 30 }
		st.config.profile.pr_ = { caps = true, size = 12 }
		local root = Page({ name = {
			type = 'item', name = 'Name', desc = 'Name.', order = 1,
			get = function() return true end, set = function() end,
			summary = function() return 'Health', nil end,
			menu = { type = 'group', name = 'Name', saved = st.Config.SavedIn('pr_'),
				get = function(info) return st.config.profile.pr_[info[#info]] end,
				set = function(info, value) st.config.profile.pr_[info[#info]] = value end,
				args = {
					caps = { type = 'toggle', name = 'All caps', order = 1 },
					size = { type = 'range', name = 'Max length', order = 2, min = 1, max = 50, step = 1 },
				} },
		} })
		local body, by = draw(root)
		local row = by.name.row
		local count, owned = OM.MenuOffers(root, row)
		eq(count, 2, 'two rows differ')
		eq(owned, 0, 'none of them a share')
		collectgarbage(); collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, 1000 do OM.MenuOffers(root, row) end
		local grown = collectgarbage('count') - before
		collectgarbage('restart')
		check(grown < 40, 'a thousand asks make no table (grew ' .. grown .. ' KB)')
		body:Release()
	end)
end)

test('the dots are drawn selected while their part\'s menu is open, and back after', function()
	in_look('thick', function()
		fresh()
		local body, by = draw(Page({ name = Part('Name', 1), plain = Part('Plain', 2, { plain = true }) }))
		local dots = by.name.widget.dots
		eq(vertex(dots.icon), color('text', 'muted'), 'at rest')
		check(OW:OpenMenu(by.name.widget), 'opens')
		eq(vertex(dots.icon), rgb(st:StateColor('edge')), 'the accent while its menu is open')
		stub.fire_script(dots, 'OnEnter', true)
		stub.fire_script(dots, 'OnLeave', true)
		eq(vertex(dots.icon), rgb(st:StateColor('edge')), 'and after the mouse has been on them')
		OW:CloseMenu()
		eq(vertex(dots.icon), color('text', 'muted'), 'Muted again once it closes')
		check(OW:OpenMenu(by.plain.widget), "an item with no summary: its menu opens")
		eq(vertex(by.plain.widget.dots.icon), color('text', 'muted'), 'its dots are as they were')
		OW:CloseMenu()
		body:Release()
	end)
end)

------------------------------------------------------------------ the hover line

test("the hover line takes the summary's place: nothing moves", function()
	in_look('thick', function()
		fresh()
		own.name = true -- the part's Show is Player's own
		local body, by = draw(Page({ name = Part('Name', 1, { kind = 'member' }) }))
		local c, w = by.name, by.name.widget
		local parts = c.frame.share
		local top, left, height = c.label:GetTop(), c.label:GetLeft(), c.frame:GetHeight()
		check(w.summary:IsShown(), 'the summary shows')
		stub.fire_script(c.frame, 'OnEnter', true)
		check(parts.line:IsShown(), 'the line shows')
		check(not w.summary:IsShown(), 'in its place: the summary hidden')
		check(not w.summaryHit:IsShown(), 'and the frame over it')
		eq(c.label:GetTop(), top, "the label's top is where it was")
		eq(c.label:GetLeft(), left, 'and its left')
		eq(c.frame:GetHeight(), height, 'the row as tall')
		eq(c.frame.shareLifts, false, 'the label never lifts')
		local labelEnd = x_in(c.label, c.frame) + math.min(width_of(c.label), c.label:GetWidth())
		eq(c.lineX, labelEnd + 12, '12 after the label')
		eq(x_in(parts.line, c.frame), c.lineX, "the line starts there")
		eq(mid(parts.line), mid(c.frame), "on the row's middle")
		check(parts.line:GetRight() <= w.dots:GetLeft() - 6, 'ending 6 before the dots')
		check(parts.ownText:IsShown() and parts.reset:IsShown() and parts.all:IsShown(), 'whole in a half cell: Own, the reset icon, Apply to')
		-- Leave.
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(parts.line, 'OnUpdate', 0.01)
		check(not parts.line:IsShown(), 'the line goes')
		check(w.summary:IsShown(), 'and the summary is back')
		check(w.summaryHit:IsShown(), 'with its frame')
		eq(c.label:GetLeft(), left, 'the label never moved')
		body:Release()
	end)
end)

test('the source page: the line follows the diff icon, and a part that offers nothing keeps its summary on hover', function()
	in_look('thick', function()
		fresh()
		differs.name = { { name = 'Party', value = 'Show' } }
		local body, by = draw(Page({ name = Part('Name', 1, { kind = 'source' }), quiet = Part('Quiet', 2) }))
		local c = by.name
		local diff = c.frame.share.diff
		check(diff:IsShown(), 'the diff icon')
		eq(c.lineX, diff:GetRight() - c.frame:GetLeft() + 12, '12 after the diff icon')
		stub.fire_script(c.frame, 'OnEnter', true)
		check(c.frame.share.line:IsShown(), 'the line')
		eq(x_in(c.frame.share.line, c.frame), c.lineX, 'from there')
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(c.frame.share.line, 'OnUpdate', 0.01)
		body:Release()

		fresh()
		body, by = draw(Page({ quiet = Part('Quiet', 2) }))
		stub.fire_script(by.quiet.frame, 'OnEnter', true)
		check(by.quiet.widget.summary:IsShown(), 'nothing to offer: the summary stays')
		body:Release()
	end)
end)

test('in a narrow cell the inline line drops Own, then "· Apply to:"', function()
	in_look('thick', function()
		fresh()
		own.name = true
		local function line(n)
			local body, by = draw(Page({ name = Part(name_of(n), 1, { kind = 'member' }) }))
			local parts = by.name.frame.share
			stub.fire_script(by.name.frame, 'OnEnter', true)
			local state = { own = parts.ownText:IsShown(), sep = parts.sep:IsShown(), clips = parts.line:DoesClipChildren(),
				reset = parts.reset:IsShown(), all = parts.all:IsShown(), multiple = parts.multiple:IsShown(),
				right = parts.line:GetRight(), limit = by.name.widget.dots:GetLeft() - 6 }
			stub.cursor_x, stub.cursor_y = 0, 0
			stub.fire_script(parts.line, 'OnUpdate', 0.01)
			body:Release()
			return state
		end
		local short = line(4)
		check(short.own and short.sep and not short.clips, 'a short name: the whole line')
		local mid_ = line(13)
		check(not mid_.own and mid_.sep and not mid_.clips, '13 characters: Own dropped')
		local long = line(24)
		check(not long.own and not long.sep and not long.clips, '24: "· Apply to:" dropped too')
		check(long.reset and long.all and long.multiple, 'leaving the reset icon, All and Multiple')
		check(long.right <= long.limit, 'inside the cell')
	end)
end)

------------------------------------------------------------------ the click

test('a click on the row opens its menu; on the box, the dots, the reset icon or a link it does not', function()
	in_look('thick', function()
		fresh()
		v.name = false -- the reset icon shows
		own.name = true
		local body, by = draw(Page({ name = Part('Name', 1, { kind = 'member' }), plain = Part('Plain', 2, { plain = true }) }))
		local c, w = by.name, by.name.widget
		local function up(button, frame) stub.fire_script(frame or c.frame, 'OnMouseUp', button or 'LeftButton') end

		hover(c.label, 5)
		up()
		check(OW:IsMenuShown(w), 'a click with the mouse over the label opens the menu')
		OW:CloseMenu()

		hover(w.box)
		up()
		check(not OW:IsMenuShown(), 'on the box: no menu')
		hover(w.dots)
		up()
		check(not OW:IsMenuShown(), 'on the dots: no menu (their own click)')
		local icon = c.frame.defaultReset
		-- Under a member page the share's reset stands in for the box's: the icon is the line's.
		stub.fire_script(c.frame, 'OnEnter', true)
		local parts = c.frame.share
		for _, piece in ipairs({ parts.reset, parts.all, parts.multiple, parts.ownText }) do
			hover(piece)
			up()
			check(not OW:IsMenuShown(), 'on a piece of the hover line: no menu')
		end
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(parts.line, 'OnUpdate', 0.01)
		check(icon == nil or not icon:IsShown(), 'a member page: no reset icon of its own')

		hover(c.label, 5)
		up('RightButton')
		check(not OW:IsMenuShown(), 'a right click does not')
		up('LeftButton')
		check(OW:IsMenuShown(w), 'a left click does')
		OW:CloseMenu()

		hover(by.plain.label, 5)
		up('LeftButton', by.plain.frame)
		check(not OW:IsMenuShown(), 'an item with no summary: no menu on a row click')
		body:Release()

		-- The reset icon on a page with no sharing: a click on it is its own.
		fresh()
		v.name = false
		body, by = draw(Page({ name = Part('Name', 1) }))
		c = by.name
		icon = c.frame.defaultReset
		check(icon and icon:IsShown(), 'the reset icon')
		hover(icon)
		up()
		check(not OW:IsMenuShown(), 'on the reset icon: no menu')
		body:Release()

		-- In combat: the menu does not open.
		fresh()
		body, by = draw(Page({ name = Part('Name', 1) }))
		hover(by.name.label, 5)
		stub.in_combat = true
		stub.fire_script(by.name.frame, 'OnMouseUp', 'LeftButton')
		stub.in_combat = false
		check(not OW:IsMenuShown(), 'in combat: none')
		body:Release()
	end)
end)

------------------------------------------------------------------ the states

test('the row has the Row hover and is never selected', function()
	in_look('thick', function()
		fresh()
		local body, by = draw(Page({ name = Part('Name', 1), plain = Part('Plain', 2, { plain = true }) }))
		local c = by.name
		eq(st:GetState(c.frame, 'hover'), false, 'a state frame, at rest')
		hover(c.label, 5)
		stub.fire_script(c.frame, 'OnEnter', true)
		eq(st:GetState(c.frame, 'hover'), true, 'its hover under the mouse')
		eq(st:GetState(c.frame, 'selected'), false, 'never selected')
		-- Moving onto its box is leaving the frame as the game tells it: the hover stays while the mouse is over the row.
		stub.fire_script(c.frame, 'OnLeave', true)
		eq(st:GetState(c.frame, 'hover'), true, "the row's OnLeave does not clear it: the mouse is still on the row")
		stub.fire_script(c.frame, 'OnUpdate', 0.01)
		eq(st:GetState(c.frame, 'hover'), true, 'the watch keeps it while the mouse is over the row')
		check(OW:OpenMenu(c.widget), 'its menu open')
		eq(st:GetState(c.frame, 'selected'), false, 'an open menu is the dots\' state: the row is not selected')
		OW:CloseMenu()
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(c.frame, 'OnUpdate', 0.01)
		eq(st:GetState(c.frame, 'hover'), false, 'the watch clears it once the mouse is off the row')
		eq(c.frame:GetScript('OnUpdate'), nil, 'and ends')

		-- An item with no summary has no hover look (it never did).
		local plain = by.plain
		hover(plain.label, 5)
		stub.fire_script(plain.frame, 'OnEnter', true)
		eq(st:GetState(plain.frame, 'hover'), false, 'no summary: no hover look')
		stub.cursor_x, stub.cursor_y = 0, 0
		body:Release()

		-- A pooled frame is acquired at rest.
		body, by = draw(Page({ name = Part('Name', 1) }))
		c = by.name
		hover(c.label, 5)
		stub.fire_script(c.frame, 'OnEnter', true)
		eq(st:GetState(c.frame, 'hover'), true)
		check(c.frame:GetScript('OnUpdate') ~= nil, 'with its watch')
		local again = redraw(body, Page({ name = Part('Name', 1, { plain = true }) }))
		eq(again.name.frame, c.frame, 'the same pooled frame')
		eq(st:GetState(again.name.frame, 'hover'), false, 'acquired at rest')
		eq(again.name.frame:GetScript('OnUpdate'), nil, 'with no watch')
		body:Release()
	end)
end)

------------------------------------------------------------------ whole pixels

test('whole pixels: the part row under Thick, Thin and Blizzard, in each size, marked, with its line and its reset icon', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			in_look(look, function()
				stub.size_noise = noise
				for _, half in ipairs({ false, true }) do
					fresh()
					v.name, own.name, own.size = false, true, true
					local width = half and (look == 'blizzard' and 368 or 388) or 774
					local body, by, content = draw(Page({
						name = Part('Name', 1, { kind = 'member' }), other = Part('Other', 2, { kind = 'source' }),
						plain = Part('Plain', 3),
					}), width, half)
					local where = ('%s, noise %s, %s'):format(look, noise, half and 'half' or 'full')
					local off = P.off(content)
					eq(#off, 0, where .. ': ' .. P.report(off))
					stub.fire_script(by.name.frame, 'OnEnter', true)
					off = P.off(content)
					eq(#off, 0, where .. ', the line shown: ' .. P.report(off))
					stub.cursor_x, stub.cursor_y = 0, 0
					stub.fire_script(by.name.frame.share.line, 'OnUpdate', 0.01)
					body:Release()
				end
			end)
		end
	end
end)

------------------------------------------------------------------ OB.PositionText

test('OB.PositionText: the words of a position, relative to its unit frame or in the screen', function()
	local relative = true
	eq(OB.PositionText({ point = 'RIGHT', element = 'Health', x_off = -7, y_off = -1 }, relative), 'Right of Health: -7, -1',
		'an element, named as it is')
	eq(OB.PositionText({ point = 'BOTTOM', x_off = 0, y_off = 0 }, relative), 'Bottom of the unit frame: 0, 0', 'no anchor: the unit frame')
	eq(OB.PositionText({ point = 'RIGHT', element = 'Castbar', x_off = 2, y_off = 3 }, relative, function(key)
		return key == 'Castbar' and 'Cast bar' or nil
	end), 'Right of Cast bar: 2, 3', 'an element by the page\'s namer')
	eq(OB.PositionText({ point = 'TOPLEFT', rel_point = 'BOTTOMLEFT', element = 'Power', x_off = 0, y_off = -4 }, relative),
		'Top left to bottom left of Power: 0, -4', 'a different corner')
	eq(OB.PositionText({ point = 'CENTER', frame = 'UIParent', x_off = 12, y_off = -4 }, relative), 'Center of the screen: 12, -4',
		'the screen')
	eq(OB.PositionText({ point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 120, y_off = -330 }),
		'Top left of the screen: 120, -330', 'not relative: a screen position')
	eq(OB.PositionText('nothing', true), nil, 'not a position: nil')
end)

------------------------------------------------------------------ fix round 1

test("the row's hover lights wherever the mouse enters it: the summary, the box, the dots, and with the hover line", function()
	in_look('thick', function()
		fresh()
		own.name = true -- a member page: entering also shows the line
		local body, by = draw(Page({ name = Part('Name', 1, { kind = 'member' }) }))
		local c, w = by.name, by.name.widget
		local parts = c.frame.share
		for _, entry in ipairs({ { 'the summary', w.summaryHit }, { 'the box', w.box }, { 'the dots', w.dots } }) do
			stub.cursor_x, stub.cursor_y = 0, 0
			stub.fire_script(parts.line, 'OnUpdate', 0.01)
			stub.fire_script(c.frame, 'OnUpdate', 0.01)
			eq(st:GetState(c.frame, 'hover'), false, entry[1] .. ': at rest first')
			hover(entry[2])
			stub.fire_script(entry[2], 'OnEnter', true)
			eq(st:GetState(c.frame, 'hover'), true, entry[1] .. ': the row is lit')
			check(parts.line:IsShown(), entry[1] .. ': and the hover line shows')
		end
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(parts.line, 'OnUpdate', 0.01)
		body:Release()

		-- A page with no sharing: the same, with no line.
		fresh()
		body, by = draw(Page({ name = Part('Name', 1) }))
		hover(by.name.widget.summaryHit)
		stub.fire_script(by.name.widget.summaryHit, 'OnEnter', true)
		eq(st:GetState(by.name.frame, 'hover'), true, 'the summary: lit with no sharing too')
		body:Release()

		-- A row of no summary is not lit from its dots.
		body, by = draw(Page({ plain = Part('Plain', 1, { plain = true }) }))
		hover(by.plain.widget.dots)
		stub.fire_script(by.plain.widget.dots, 'OnEnter', true)
		eq(st:GetState(by.plain.frame, 'hover'), false, 'no summary: no hover look')
		stub.fire_script(by.plain.widget.dots, 'OnLeave', true)
		body:Release()
	end)
end)

test("the row's hover watch ends once the mouse is out of the view, as the line's does", function()
	in_look('thick', function()
		fresh()
		local view = CreateFrame('Frame', nil, UIParent)
		view:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
		view:SetSize(774, 20) -- shows only the top of the row
		local content = CreateFrame('Frame', nil, view)
		content:SetPoint('TOPLEFT', view, 'TOPLEFT', 0, 0)
		content:SetSize(774, 700)
		local root = Page({ name = Part('Name', 1) })
		local body = OB.New(content, root, nil, 774)
		body:Draw(OM.BuildView(root, 'page').sections)
		local c = body.cells[1]
		hover(c.label, 5)
		stub.fire_script(c.frame, 'OnEnter', true)
		eq(st:GetState(c.frame, 'hover'), true, 'lit')
		-- Over the row's lower part, below the view.
		local scale = c.frame:GetEffectiveScale()
		stub.cursor_x = (c.frame:GetLeft() + 5) * scale
		stub.cursor_y = (c.frame:GetBottom() + 3) * scale
		check(c.frame:IsMouseOver() and not view:IsMouseOver(), 'the case: on the row, off the view')
		stub.fire_script(c.frame, 'OnUpdate', 0.01)
		eq(st:GetState(c.frame, 'hover'), false, 'cleared')
		body:Release()
	end)
end)

test('OM.MenuOffers keeps no menu alive: throwaway menus are collected', function()
	local weak = setmetatable({}, { __mode = 'k' })
	local function ask(n)
		local menu = { type = 'group', name = 'M' .. n, args = { a = { type = 'toggle', name = 'A', default = Default('caps', false),
			get = function() return false end, set = function() end } } }
		weak[menu] = true
		OM.MenuOffers({}, { option = { type = 'item', menu = menu }, path = { 'x' } })
	end
	for n = 1, 2000 do ask(n) end
	collectgarbage(); collectgarbage()
	local alive = 0
	for _ in pairs(weak) do alive = alive + 1 end
	check(alive <= 128, 'at most the bounded cache is kept (' .. alive .. ' of 2000 alive)')
end)

test('OM.MenuOffers leaves out a hidden group, a hidden or disabled owned row, and a hidden or disabled menu', function()
	fresh()
	own.size, own.caps, own.extra = true, true, true
	local function offers(edit)
		local item = Part('Name', 1, { kind = 'member' })
		edit(item.menu)
		return (OM.MenuOffers({}, { option = item, path = { 'page', 'name' }, type = 'item' }))
	end
	local function group(extra)
		local g = { type = 'group', name = 'G', inline = true, order = 9, args = { extra = { type = 'toggle', name = 'Extra',
			share = MemberShare('extra'), get = function() return true end, set = function() end } } }
		for k, val in pairs(extra) do g[k] = val end
		return g
	end
	eq(offers(function() end), 2, 'the case: two own rows')
	eq(offers(function(m) m.args.size.hidden = true end), 1, 'a hidden owned row')
	eq(offers(function(m) m.args.size.disabled = true end), 1, 'a disabled owned row')
	eq(offers(function(m) m.args.g = group({}) end), 3, 'a nested group counts')
	eq(offers(function(m) m.args.g = group({ hidden = true }) end), 2, 'a hidden group above an owned row')
	eq(offers(function(m) m.args.g = group({ guiHidden = true }) end), 2, 'a guiHidden one')
	eq(offers(function(m) m.args.g = group({ disabled = true }) end), 2, 'a disabled one')
	eq(offers(function(m) m.hidden = true end), 0, 'a hidden menu')
	eq(offers(function(m) m.guiHidden = true end), 0, 'a guiHidden menu')
	eq(offers(function(m) m.disabled = true end), 0, 'a disabled menu')
	eq(offers(function(m) m.guiDisabled = true end), 0, 'a guiDisabled menu')
end)

test('the summary has 24 of room or it is left out: the boundary, to the unit', function()
	in_look('thick', function()
		fresh()
		-- A 4-character label (32): the room is the cell less 92.
		local function shown(width)
			local body, by = draw(Page({ name = Part('Name', 1) }), width)
			local out = { on = by.name.widget.summary:IsShown(), cell = by.name.frame:GetWidth(),
				room = by.name.frame:GetWidth() - 92 }
			body:Release()
			return out
		end
		local at, under = shown(288), shown(286)
		eq(at.room, 24, 'the case: 24 of room')
		check(at.on, '24: shown')
		eq(under.room, 23, 'the case: 23 of room')
		check(not under.on, '23: left out')
	end)
end)

test('a stale tip does not stay: a later summary with text and no tip has none', function()
	in_look('thick', function(tip)
		fresh()
		local root = Page({ name = Part('Name', 1) })
		local body, by = draw(root)
		eq(by.name.widget.summaryTip, 'Right of Health: -7, -1')
		v.tip = nil
		v.sum = 'Screen'
		body:Release()
		body:Draw(OM.BuildView(root, 'page').sections)
		by = {}
		for _, cell in ipairs(body.cells) do by[cell.row.key] = cell end
		eq(by.name.widget.summaryTip, nil, 'no tip kept')
		eq(by.name.widget.summary:GetText(), 'Screen')
		stub.fire_script(by.name.widget.summaryHit, 'OnEnter', true)
		eq(tip.owner, nil, 'no tooltip')
		body:Release()
	end)
end)

test('a drag: the body\'s Refresh puts the summary by the reset icon that came, and back', function()
	in_look('thick', function()
		fresh()
		local root = Page({ name = Part('Name', 1) })
		local body, by = draw(root)
		local c, w = by.name, by.name.widget
		local before = w.summary:GetRight()
		v.name = false
		body:Refresh()
		local icon = c.frame.defaultReset
		check(icon and icon:IsShown(), 'the reset icon came')
		eq(w.summary:GetRight(), icon:GetLeft() - 6, 'the summary ends 6 before it')
		v.name = true
		body:Refresh()
		eq(w.summary:GetRight(), before, 'and back where it was')
		body:Release()
	end)
end)

test('a pooled frame of a part row is clean for a row that is no item', function()
	in_look('thick', function()
		fresh()
		local body, by = draw(Page({ name = Part('Name', 1) }))
		local frame = by.name.frame
		hover(by.name.label, 5)
		stub.fire_script(frame, 'OnEnter', true)
		local again = redraw(body, Page({ name = { type = 'toggle', name = 'Plain', desc = 'Plain.', order = 1,
			get = function() return true end, set = function() end } }))
		eq(again.name.frame, frame, 'the same pooled frame')
		eq(frame.partRow, nil, 'no part row')
		eq(st:GetState(frame, 'hover'), false, 'not lit')
		eq(frame:GetScript('OnUpdate'), nil, 'no watch')
		stub.fire_script(frame, 'OnMouseUp', 'LeftButton')
		check(not OW:IsMenuShown(), 'a click opens nothing')
		stub.fire_script(frame, 'OnEnter', true)
		eq(st:GetState(frame, 'hover'), false, 'and entering it lights nothing')
		body:Release()
	end)
end)

test("the menu opens on mouse-up only while the mouse is still on the row", function()
	in_look('thick', function()
		fresh()
		local body, by = draw(Page({ name = Part('Name', 1) }))
		local c = by.name
		stub.cursor_x, stub.cursor_y = 0, 0
		stub.fire_script(c.frame, 'OnMouseUp', 'LeftButton')
		check(not OW:IsMenuShown(), 'pressed on the row, let go off it: no menu')
		hover(c.label, 5)
		stub.fire_script(c.frame, 'OnMouseUp', 'LeftButton')
		check(OW:IsMenuShown(c.widget), 'on it: the menu')
		OW:CloseMenu()
		body:Release()
	end)
end)
