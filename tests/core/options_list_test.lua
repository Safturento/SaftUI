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
	eq(anchor(list.rows[1], { [list.frame] = 'frame' }), 'TOPLEFT frame TOPLEFT 1,-1', 'Thick: the rows 1 in')
	for i = 1, 2 do
		local box = list.rows[i].box
		check_box(box, 'Thick: row ' .. i .. "'s box", nil, true)
		eq(atlases_of(box), '', 'Thick: row ' .. i .. ' has no Blizzard art')
		check(box.mark:IsShown(), 'Thick: row ' .. i .. "'s blue mark")
	end
	W.CloseList()
	eq(#take_errors(), 0, 'no errors')
end)
