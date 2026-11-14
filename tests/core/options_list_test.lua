-- SaftUI-Core/Config/optionslist.lua and optionsbar.lua: the select list every
-- select opens (W.OpenList, W.CloseList, W.ListOwner), the check list drawn on
-- its frames (W.OpenCheckList, under Blizzard; its other case is
-- options_select_test.lua's), and Blizzard's minimal scroll bar on SaftUI's
-- frames (W.BlizzardBar), with their art under SaftUI's theme Blizzard.
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua, with a real
-- AceConfigRegistry-3.0). Synthetic AceConfig option tables stand for the
-- options. The mouse and the keyboard are played by firing the frames' scripts
-- (stub.fire_script), and the color picker by stub.pick_color and friends
-- (tests/wow/blizzard.lua). The world and the helpers are
-- options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
local W = st.OptionsWidgets
local check_no_box, check_box, click, parent, around = H.check_no_box, H.check_box, H.click, H.parent, H.around
local BG_RGBA, atlas_exact, anchor, rgba, theme = H.BG_RGBA, H.atlas_exact, H.anchor, H.rgba, H.theme
local bind, atlases_of, rebind, opt, entries_of = H.bind, H.atlases_of, H.rebind, H.opt, H.entries_of
local inside, size_of, atlas_piece = H.inside, H.size_of, H.atlas_piece

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test("the list sits on common-dropdown-c-bg, in place of the tooltip border", function()
	theme('blizzard')
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = { a = 'A', b = 'B' }, get = function() return 'a' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	click(w.frame)
	local list = W.GetListFrames()
	local names = { [list.frame] = 'frame' }
	check_no_box(list.frame, 'Blizzard: the list')
	check(list.skin ~= nil and list.skin:IsShown(), 'its skin shows')
	eq(st:DrawnKind(list.skin), nil, 'the theme draws nothing there: c-bg is its border')
	eq(atlases_of(list.skin), 'common-dropdown-c-bg', 'only c-bg')
	local menu = atlas_exact(list.skin, 'common-dropdown-c-bg')
	eq(around(menu, list.frame), '-17,12,17,-22', "Blizzard's outsets round the list")
	eq(menu:GetAlpha(), 1, 'whole')
	check(list.skin:GetFrameLevel() < list.frame:GetFrameLevel(), 'under the list and its rows')
	eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 3,-6', 'the rows 3 in and 6 down')
	eq(anchor(list.rows[2], names), 'TOPLEFT frame TOPLEFT 3,-28')
	eq(around(list.rows[1], list.frame):match(',(-?%d+),[^,]+$'), '-3', '3 in from the right')
	eq(list.frame:GetHeight(), 2 * 22 + 13, 'two rows, 6 above and 7 below')
	stub.fire_script(list.rows[1], 'OnEnter')
	local hover = list.rows[1].hover
	check(hover:IsShown(), 'a row lights under the mouse')
	eq(hover:GetAtlas(), 'common-dropdown-customize-mouseover', "on the menu's mouseover")
	eq(hover:GetAlpha(), 1, 'whole')
	eq(around(hover, list.rows[1]), '0,0,0,0', 'across the row')
	stub.fire_script(list.rows[1], 'OnLeave')
	check(not hover:IsShown(), 'and goes dark again')
	W.CloseList()

	theme('thick'); rebind(w)
	click(w.frame)
	check_box(list.frame, 'Thick: the list', BG_RGBA)
	check(not list.skin:IsShown(), 'Thick: no c-bg')
	eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 1,-1', 'Thick: the rows 1 in')
	eq(anchor(list.rows[2], names), 'TOPLEFT frame TOPLEFT 1,-23')
	eq(list.frame:GetHeight(), 2 * 22 + 2, 'Thick: two rows and the edge')
	stub.fire_script(list.rows[1], 'OnEnter')
	eq(hover:GetAtlas(), nil, 'Thick: no atlas')
	local r, g, b = st.config.profile.colors.button.blue:GetRGB()
	eq(rgba(unpack(stub.state(hover).color_texture)), rgba(r, g, b, 1), 'Thick: the blue')
	eq(string.format('%.2f', hover:GetAlpha()), '0.25', 'Thick: at 0.25')
	stub.fire_script(list.rows[1], 'OnLeave')
	W.CloseList()
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test("a long list scrolls on Blizzard's narrow scroll bar inside it, in place of the 3px bar", function()
	theme('blizzard')
	local values = {}
	for i = 1, 20 do values[string.format('k%02d', i)] = 'Entry ' .. i end
	local w = bind('select', 'pick', opt('select', 'Pick', {
		values = values, get = function() return 'k01' end, set = function() end,
	}))
	w:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	click(w.frame)
	local list = W.GetListFrames()
	local bar = list.blizzardBar
	check(bar.frame:IsShown(), 'Blizzard: the list has a bar')
	check(not list.bar:IsShown(), 'not the 3px bar')
	eq(size_of(bar.up), '8x5', 'narrow arrows')
	eq(size_of(bar.down), '8x5')
	eq(bar.track:GetWidth(), 8, 'an 8 wide track')
	eq(list.frame:GetRight() - bar.track:GetRight(), 3, 'on its right, 3 in')
	eq(bar.up:GetLeft(), bar.track:GetLeft(), 'the arrows over the track')
	eq(list.frame:GetTop() - bar.up:GetTop(), 6, 'from the top of the rows, 6 down')
	eq(bar.down:GetBottom() - list.frame:GetBottom(), 7, 'to their bottom, 7 up')
	eq(bar.track:GetTop(), bar.up:GetTop() - 9, 'the track 9 in')
	check(inside(bar.frame, list.frame), 'inside the list frame')
	check(bar.frame:GetFrameLevel() > list.rows[1]:GetFrameLevel(), 'over the rows, so it takes the mouse')
	-- Between each narrow arrow and the track, the column itself takes the
	-- click, which would otherwise pick the first or last row under it.
	check(bar.frame:IsMouseEnabled(), 'the column takes the mouse')
	local scale = bar.frame:GetEffectiveScale()
	local cx = bar.track:GetCenter()
	for _, at in ipairs({ { bar.up:GetBottom() - 2, list.rows[1], 'under the up arrow' }, { bar.down:GetTop() + 2, list.rows[12], 'over the down arrow' } }) do
		check(at[1] < bar.up:GetBottom() + 1 and at[1] > bar.track:GetTop() or at[1] > bar.down:GetTop() - 1 and at[1] < bar.track:GetBottom(), at[3] .. ': between the arrow and the track')
		stub.cursor_x, stub.cursor_y = cx * scale, at[1] * scale
		check(at[2]:IsMouseOver(), at[3] .. ': over a row')
		check(bar.frame:IsMouseMotionFocus(), at[3] .. ': the column has the mouse, not the row under it')
	end
	stub.cursor_x, stub.cursor_y = 0, 0
	-- The wheel over the bar: three rows, as over the list.
	check(bar.frame:IsMouseWheelEnabled(), 'the bar takes the wheel')
	stub.fire_script(bar.frame, 'OnMouseWheel', -1)
	eq(entries_of(list)[1], 'Entry 4', 'the wheel over the bar: three rows')
	stub.fire_script(bar.frame, 'OnMouseWheel', 1)
	eq(entries_of(list)[1], 'Entry 1', 'and back')
	local track = bar.track:GetHeight()
	eq(bar.thumb:GetHeight(), math.max(23, math.floor(track * 12 / 20)), "the thumb the share of rows shown")
	eq(entries_of(list)[1], 'Entry 1', 'from the top')
	stub.fire_script(bar.down, 'OnClick', 'LeftButton')
	eq(entries_of(list)[1], 'Entry 2', 'the down arrow: a row')
	stub.fire_script(bar.up, 'OnClick', 'LeftButton')
	eq(entries_of(list)[1], 'Entry 1', 'the up arrow: back')
	stub.fire_script(list.frame, 'OnMouseWheel', -1)
	eq(entries_of(list)[1], 'Entry 4', 'the wheel: three rows, as before')
	eq(bar.thumb:GetTop(), bar.track:GetTop() - math.floor((track - bar.thumb:GetHeight()) * 3 / 8), 'the thumb follows')
	for _ = 1, 10 do stub.fire_script(bar.down, 'OnClick', 'LeftButton') end
	local last = entries_of(list)
	eq(last[#last], 'Entry 20', 'no further than the end')
	eq(bar.thumb:GetBottom(), bar.track:GetBottom(), 'the thumb at the bottom')

	-- The thumb dragged in rows: as far through the 8 the list scrolls as the
	-- thumb through its room, to the nearest row.
	for _ = 1, 10 do stub.fire_script(bar.up, 'OnClick', 'LeftButton') end
	eq(entries_of(list)[1], 'Entry 1', 'back at the top')
	local room = bar.track:GetHeight() - bar.thumb:GetHeight()
	local _, y = bar.thumb:GetCenter()
	stub.cursor_x, stub.cursor_y = cx * scale, y * scale
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	stub.cursor_y = (y - room / 2) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(entries_of(list)[1], 'Entry 5', 'half its room: 4 of the 8 rows')
	stub.cursor_y = (y - room * 5 / 16) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(entries_of(list)[1], 'Entry 4', '2.5 rows: rounded to 3')
	stub.cursor_y = (y - room - 50) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(entries_of(list)[1], 'Entry 9', 'past its room: the last 12')
	eq(bar.thumb:GetBottom(), bar.track:GetBottom(), 'the thumb at the bottom')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar.thumb, 'OnMouseUp', 'LeftButton')
	-- A click on the track: a view (12 rows) toward the click, within the 8.
	stub.cursor_y = (bar.thumb:GetTop() + 2) * scale
	check(bar.thumb:GetTop() + 2 < bar.track:GetTop(), 'room above the thumb')
	stub.fire_script(bar.track, 'OnMouseDown', 'LeftButton')
	eq(entries_of(list)[1], 'Entry 1', 'above the thumb: a view up, at most to the top')
	stub.cursor_y = (bar.thumb:GetBottom() - 2) * scale
	check(bar.thumb:GetBottom() - 2 > bar.track:GetBottom(), 'room below it')
	stub.fire_script(bar.track, 'OnMouseDown', 'LeftButton')
	eq(entries_of(list)[1], 'Entry 9', 'below it: a view down, at most to the end')
	stub.cursor_x, stub.cursor_y = 0, 0
	W.CloseList()

	-- Ten entries fit: no bar.
	local few = {}
	for i = 1, 10 do few[string.format('k%02d', i)] = 'Entry ' .. i end
	local short = bind('select', 'few', opt('select', 'Few', {
		values = few, get = function() return 'k01' end, set = function() end,
	}))
	short:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -50)
	click(short.frame)
	check(not bar.frame:IsShown(), 'nothing to scroll: no bar')
	check(not list.bar:IsShown(), 'nor a 3px one')
	W.CloseList()
	short:Release()

	theme('thick'); rebind(w)
	click(w.frame)
	check(list.bar:IsShown(), 'Thick: the 3px bar, as before')
	check(not bar.frame:IsShown(), 'Thick: no Blizzard bar')
	W.CloseList()
	w:Release()
	eq(#take_errors(), 0, 'no errors')
end)

test('W.BlizzardBar: the column takes the mouse and the wheel; a held thumb asks only when the cursor moves; W.ScrollBarHeld', function()
	local host = CreateFrame('Frame', nil, UIParent)
	host:SetSize(100, 300)
	host:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	local asked = {}
	local bar = W.BlizzardBar(host, function(offset) asked[#asked + 1] = offset end, { step = 10 })
	bar:Set(host, 50, 0, 300, 300, 900, 0)
	check(bar.frame:IsShown(), 'shown')
	check(bar.frame:IsMouseEnabled(), 'the column takes the mouse')

	-- The wheel: a step a turn, unclamped (the caller clamps).
	stub.fire_script(bar.frame, 'OnMouseWheel', -1)
	eq(asked[#asked], 10, 'down a turn: a step')
	stub.fire_script(bar.frame, 'OnMouseWheel', 1)
	eq(asked[#asked], -10, 'up a turn: a step up')
	local turns = W.BlizzardBar(host, function(offset) asked[#asked + 1] = offset end, { step = 1, wheel = 3 })
	turns:Set(host, 70, 0, 300, 12, 20, 0)
	stub.fire_script(turns.frame, 'OnMouseWheel', -1)
	eq(asked[#asked], 3, 'opts.wheel: its own turn')

	-- A held thumb asks only when the cursor has moved.
	asked = {}
	check(not W.ScrollBarHeld(), 'nothing held')
	local scale = bar.frame:GetEffectiveScale()
	local _, y = bar.thumb:GetCenter()
	stub.cursor_x, stub.cursor_y = 0, y * scale
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	check(W.ScrollBarHeld(), 'held')
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(#asked, 0, 'the cursor still: nothing asked')
	stub.cursor_y = (y - 10) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(#asked, 1, 'moved: asked')
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(#asked, 1, 'still again: not again')
	stub.cursor_y = (y - 20) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(#asked, 2, 'moved again: asked again')
	stub.fire_script(bar.thumb, 'OnMouseUp', 'LeftButton')
	stub.mouse_buttons.LeftButton = nil
	check(not W.ScrollBarHeld(), 'let go')

	-- A thumb whose mouse up never came isn't held once its button is up.
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	check(W.ScrollBarHeld(), 'held again')
	stub.mouse_buttons.LeftButton = nil
	check(not W.ScrollBarHeld(), 'its button up: not held')
	asked = {}
	stub.cursor_y = (y - 50) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(#asked, 0, 'and no longer dragging')
	stub.cursor_x, stub.cursor_y = 0, 0
	host:Hide()
	eq(#take_errors(), 0, 'no errors')
end)

test("W.OpenCheckList under Blizzard: drawn as the select list is, its boxes Settings check boxes; under Thick as before", function()
	local owner = W.Box(st:CreateFrame('Button', nil, UIParent))
	owner:SetSize(170, 24)
	owner:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	local checked = { b = true }
	local entries = { { key = 'a', label = 'Alpha' }, { key = 'b', label = 'Bravo' } }
	local function open()
		W.OpenCheckList(owner, entries, function(key) return checked[key] end, function(key)
			checked[key] = not checked[key]
		end)
	end
	local list = W.GetListFrames()
	local function ticked(i) return atlas_piece(list.rows[i].box, 'checkmark-minimal') ~= nil end

	theme('blizzard')
	open()
	-- Drawn as the select list is: on c-bg, the rows 3 in and 6 down, lit on the mouseover.
	check_no_box(list.frame, 'Blizzard: the list')
	check(list.skin ~= nil and list.skin:IsShown(), 'its skin shows')
	eq(atlases_of(list.skin), 'common-dropdown-c-bg', 'on c-bg')
	eq(around(atlas_exact(list.skin, 'common-dropdown-c-bg'), list.frame), '-17,12,17,-22', "at Blizzard's outsets")
	eq(anchor(list.rows[1], { [list.frame] = 'frame' }), 'TOPLEFT frame TOPLEFT 3,-6', 'the rows 3 in and 6 down')
	stub.fire_script(list.rows[1], 'OnEnter')
	eq(list.rows[1].hover:GetAtlas(), 'common-dropdown-customize-mouseover', 'a row lights on the mouseover')
	stub.fire_script(list.rows[1], 'OnLeave')
	for i = 1, 2 do
		local box = list.rows[i].box
		check_no_box(box, 'Blizzard: row ' .. i .. "'s box")
		check(atlas_piece(box, 'checkbox-minimal') ~= nil, 'row ' .. i .. ' is a Settings check box')
		check(not box.mark:IsShown(), 'row ' .. i .. ': no blue mark')
		eq(size_of(box), '18x18', 'row ' .. i .. ': its box keeps its size')
	end
	eq(ticked(1), false, 'Alpha unchecked')
	eq(ticked(2), true, 'Bravo checked')
	click(list.rows[1])
	eq(ticked(1), true, 'a click checks it, the list still open')
	W.CloseList()

	theme('thick')
	open()
	check(not list.skin:IsShown(), 'Thick: no c-bg')
	check_box(list.frame, 'Thick: the list', BG_RGBA)
	eq(anchor(list.rows[1], { [list.frame] = 'frame' }), 'TOPLEFT frame TOPLEFT 5,-5', 'Thick: the rows 5 in (the edge and 4 of air)')
	for i = 1, 2 do
		local box = list.rows[i].box
		check_box(box, 'Thick: row ' .. i .. "'s box", nil, true)
		eq(atlases_of(box), '', 'Thick: row ' .. i .. ' has no Blizzard art')
		check(box.mark:IsShown(), 'Thick: row ' .. i .. "'s blue mark")
	end
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
end)

test('the Apply list: checks change nothing until Apply, which hands over the checked keys', function()
	local owner = W.Box(st:CreateFrame('Button', nil, UIParent))
	owner:SetSize(52, 14)
	owner:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	local got = {}
	local function onApply(keys) got[#got + 1] = table.concat(keys, ',') end
	local entries = { { key = 'a', label = 'A' }, { key = 'b', label = 'B' }, { key = 'c', label = 'C' } }
	local function marks()
		local out = {}
		for i = 1, 3 do out[i] = H.text_of(W.GetListFrames().rows[i].text) .. '=' .. tostring(W.GetListFrames().rows[i].box:GetChecked()) end
		return table.concat(out, ',')
	end

	theme('thick')
	W.OpenApplyList(owner, entries, onApply)
	local list = W.GetListFrames()
	eq(W.ListOwner(), owner, 'open, its owner reported')
	eq(marks(), 'A=false,B=false,C=false', 'every row unchecked to start')
	for i = 1, 3 do check(list.rows[i].box:IsShown(), 'row ' .. i .. ' is a check box') end
	check(list.apply ~= nil and list.apply:IsShown(), 'the Apply button shows')
	eq(list.apply.text:GetText(), 'Apply')
	check(list.apply:GetTop() <= list.rows[3]:GetBottom(), 'under the rows')
	check(inside(list.apply, list.frame), 'inside the list')
	eq(list.frame:GetHeight(), 3 * 22 + 10 + 6 + 24, 'the rows, 5 above and below, and the button with 6 over it')
	check_box(list.apply, 'Thick: the Apply button', nil, true)

	click(list.rows[2]); click(list.rows[3])
	eq(marks(), 'A=false,B=true,C=true', 'a click marks its row')
	eq(W.ListOwner(), owner, 'the list stays open')
	eq(#got, 0, 'nothing applied yet')
	click(list.rows[3]); click(list.rows[3])
	eq(marks(), 'A=false,B=true,C=true', 'a second click unmarks, a third marks again')
	click(list.apply)
	eq(W.ListOwner(), nil, 'Apply closes it')
	eq(#got, 1); eq(got[1], 'b,c', "the checked keys, in the entries' order")

	-- Again: it starts unchecked, and Apply with none checked calls nothing.
	W.OpenApplyList(owner, entries, onApply)
	eq(marks(), 'A=false,B=false,C=false', 'unchecked again')
	click(list.apply)
	eq(W.ListOwner(), nil, 'closed'); eq(#got, 1, 'no call with none checked')
	-- Esc and a click outside close it, calling nothing.
	W.OpenApplyList(owner, entries, onApply)
	click(list.rows[1])
	stub.fire_script(list.catcher, 'OnKeyDown', 'ESCAPE')
	eq(W.ListOwner(), nil, 'Esc closes it'); eq(#got, 1, 'calling nothing')
	W.OpenApplyList(owner, entries, onApply)
	click(list.rows[1])
	stub.fire_script(list.catcher, 'OnMouseDown')
	eq(W.ListOwner(), nil, 'a click outside closes it'); eq(#got, 1)
	W.OpenApplyList(owner, entries, onApply)
	click(list.rows[1])
	W.CloseList()
	eq(#got, 1, 'W.CloseList calls nothing')
	W.OpenApplyList(owner, {}, onApply)
	eq(W.ListOwner(), nil, "an empty list doesn't open")

	-- The list's other uses never show the button.
	W.OpenList(owner, entries, 'a', function() end)
	check(not list.apply:IsShown(), 'no Apply on a select\'s list')
	eq(list.frame:GetHeight(), 3 * 22 + 2, 'nor its room')
	W.CloseList()
	W.OpenCheckList(owner, entries, function() return false end, function() end)
	check(not list.apply:IsShown(), 'nor on the check list')
	W.CloseList()

	-- Under Blizzard the button is the panel button.
	theme('blizzard')
	W.OpenApplyList(owner, entries, onApply)
	check(list.apply:IsShown())
	eq((H.panel_of(list.apply)), 'Left=Up,Middle=Up,Right=Up', "Blizzard's panel button")
	check_no_box(list.apply, 'Blizzard: the Apply button')
	check(inside(list.apply, list.frame), 'inside the list')
	click(list.rows[1]); click(list.apply)
	eq(got[2], 'a', 'and it applies')
	theme('thick')
	W.OpenApplyList(owner, entries, onApply)
	eq((H.panel_of(list.apply)), '', 'Thick: no panel button')
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
end)

test('the check list and the Apply list pad their rows 4 inside the edge on every side; the select list and Blizzard do not change', function()
	local owner = W.Box(st:CreateFrame('Button', nil, UIParent))
	owner:SetSize(170, 24)
	owner:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	local entries = { { key = 'a', label = 'Alpha' }, { key = 'b', label = 'Bravo' } }
	local names = {}
	local list
	for _, name in ipairs({ 'thick', 'thin' }) do
		theme(name)
		W.OpenCheckList(owner, entries, function() return false end, function() end)
		list = W.GetListFrames(); names[list.frame] = 'frame'
		eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 5,-5', name .. ': the first row 5 in and down')
		eq(list.frame:GetRight() - list.rows[1]:GetRight(), 5, name .. ': 5 in from the right')
		eq(list.rows[2]:GetBottom() - list.frame:GetBottom(), 5, name .. ': 5 up from the bottom')
		eq(list.frame:GetHeight(), 2 * 22 + 10, name .. ': two rows and 5 each side')
		eq(list.frame:GetWidth(), 170, name .. ': as wide as its owner')
		eq(list.frame:GetLeft(), owner:GetLeft(), name .. ': still at its owner\'s left')
		check(list.rows[1].box:GetLeft() - list.frame:GetLeft() > 5, name .. ': the box clear of the edge')
		W.CloseList()

		-- The select's list keeps its rows against the edge, so its rows line up with its button.
		W.OpenList(owner, entries, 'a', function() end)
		eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 1,-1', name .. ': the select list: 1 in')
		eq(list.frame:GetHeight(), 2 * 22 + 2, name .. ': two rows and the edge')
		W.CloseList()

		-- Opening a check list does not leave its padding on the next select list.
		W.OpenCheckList(owner, entries, function() return false end, function() end)
		W.CloseList()
		W.OpenList(owner, entries, 'a', function() end)
		eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 1,-1', name .. ': the select list after a check list')
		W.CloseList()

		W.OpenApplyList(owner, entries, function() end)
		eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 5,-5', name .. ': the Apply list: 5 in and down')
		eq(list.frame:GetHeight(), 2 * 22 + 10 + 6 + 24, name .. ': rows, 5 each side, the button and 6 over it')
		eq(list.apply:GetBottom() - list.frame:GetBottom(), 5, name .. ': the button 5 up from the bottom')
		eq(list.rows[2]:GetBottom() - list.apply:GetTop(), 6, name .. ': 6 between the rows and the button')
		W.CloseList()
	end

	theme('blizzard')
	W.OpenApplyList(owner, entries, function() end)
	list = W.GetListFrames(); names[list.frame] = 'frame'
	eq(anchor(list.rows[1], names), 'TOPLEFT frame TOPLEFT 3,-6', "Blizzard: its menu's own insets, no more")
	eq(list.frame:GetHeight(), 2 * 22 + 13 + 36, 'Blizzard: its Apply list as before')
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
end)
