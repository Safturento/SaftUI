-- The docked edit mode bar as two rows, only as wide as its controls
-- (SaftUI-Core/EditMode/Bar/bar.lua): which controls are on which row and in
-- what order, the pure layout (EM.BarLayout), the bar's width (the wider row
-- plus its padding, even) and height (two rows of 26, a gap, the padding),
-- each row centred, the bar fitting the narrowest screen with no stage giving
-- way, whole pixels under each look and screen with the game's read-back
-- noise, and the status line, which has no room on the bar and is shown as a
-- tooltip under the pressed control.
--
-- Real: the /sui window's world, edit mode's files and the bar's. The mouse
-- is played by firing scripts; the screen by stub.screen_width and UIParent's
-- scale.

local P = load_test_file('lib/pixels.lua')

local H, st, EM, W

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, W = st.EditModeFrames, st.OptionsWidgets
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local settings, control, frame_of, set_screen, look = EMH.settings, EMH.control, EMH.frame_of, EMH.set_screen, EMH.look

local function reset()
	if EM.active then EM:Deactivate() end
	EM:SetBarFloating(false)
	st.config.global.editModeBar = nil
	EM:SetBarStatus('')
	stub.in_combat = false
	stub.size_noise = 0
	stub.time = 1000
	set_screen(1920, 1080)
	look('thick')
	H.close_all()
end

local ROW_ONE = { 'exit', 'grid', 'gridSize', 'snapGrid', 'snapFrames', 'dim', 'coordinates', 'undo', 'redo', 'history', 'reset' }
local ROW_TWO = { 'showDisabled', 'showHidden', 'modules', 'filter', 'options', 'hide', 'detach' }

-- A control's row is the one its top is in (row 1 starts 7 down, row 2 starts 37 down).
local function row_of(key)
	local _, _, _, _, y = frame_of(key):GetPoint(1)
	return -y < 37 and 1 or 2
end

-- The keys of the controls on a row of the bar, left to right.
local function keys_on(row)
	local out = {}
	for _, c in ipairs(EM:BarControls()) do
		if c.frame:IsShown() and row_of(c.key) == row then out[#out + 1] = c end
	end
	table.sort(out, function(a, b) return a.frame:GetLeft() < b.frame:GetLeft() end)
	local keys = {}
	for i, c in ipairs(out) do keys[i] = c.key end
	return keys
end

local function whole(v) return math.floor(v + 0.5) end
local function tip_on(owner) return GameTooltip:IsShown() and GameTooltip:IsOwned(owner) end

------------------------------------------------------------------ the pure layout

test('EM.BarLayout: each row from its own groups, controls 4 apart, 8 + 1 + 8 between groups, the bar as wide as the wider row plus 10 each side made even, each row centred', function()
	local rows = {
		{ { widths = { 80 } }, { widths = { 26, 54 } } },                         -- 80, 17, 84: 181
		{ { widths = { 100, 0, 20 } }, { widths = { 0 } }, { widths = { 40 } } }, -- 124, then 17 + 40: 181 as well
	}
	local xs, dividers, width = EM.BarLayout(rows)
	eq(width, 202, 'the wider row (181) plus 20, made even')
	eq(xs[1][1][1], 10, 'row 1 starts at floor((202 - 181) / 2)')
	eq(xs[1][2][1], 107, 'the next group after 8, 1 and 8')
	eq(xs[1][2][2], 137, '4 after its first control')
	eq(table.concat(dividers[1], ','), '98', 'a divider between the groups')
	eq(xs[2][1][1], 10, 'row 2 starts there too')
	eq(xs[2][1][2], nil, 'a width of 0 has no place')
	eq(xs[2][1][3], 114, 'and takes no gap')
	eq(xs[2][3][1], 151, 'the group after an empty one is placed as if it were not there')
	eq(table.concat(dividers[2], ','), '142', 'one divider, not two')

	-- A narrower row is centred in the bar.
	xs, dividers, width = EM.BarLayout({ { { widths = { 100 } } }, { { widths = { 30 } } } })
	eq(width, 120, 'the wider row 100 plus 20')
	eq(xs[1][1][1], 10, 'the wider row is at PAD')
	eq(xs[2][1][1], 45, 'the narrower one centred: (120 - 30) / 2')

	-- An odd total is made even.
	xs, dividers, width = EM.BarLayout({ { { widths = { 101 } } }, { { widths = { 30 } } } })
	eq(width, 122, '121 made even')
	eq(xs[1][1][1], 10, 'the wider row starts at floor((122 - 101) / 2)')
	eq(xs[2][1][1], 46, 'the other is centred in the even width: floor((122 - 30) / 2)')
	_, _, width = EM.BarLayout({ { { widths = { 99 } } }, {} })
	eq(width, 120, '119 made even; an empty row takes nothing')
	for r, row in ipairs(xs) do
		for g, group in pairs(row) do
			for c, x in pairs(group) do eq(x, math.floor(x), ('x[%d][%d][%d] whole'):format(r, g, c)) end
		end
	end
end)

------------------------------------------------------------------ the rows

test('row one is Exit, the grid group and the changes; row two is what shows, the filter, then Options, the hide toggle and Detach', function()
	reset()
	EM:Activate()
	eq(table.concat(keys_on(1), ' '), table.concat(ROW_ONE, ' '), 'row one, left to right')
	eq(table.concat(keys_on(2), ' '), table.concat(ROW_TWO, ' '), 'row two, left to right')
	check(EM:BarControl('caption') == nil, 'the Show caption is gone: nothing shows it in either mode')
	reset()
end)

test('the bar is two rows tall (7, 26, 4, 26, 7) and as wide as its wider row plus 10 each side, even; each row is centred', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	eq(EM.BAR.HEIGHT, 70, 'the number')
	eq(bar:GetHeight(), 70, 'two rows of 26, a gap of 4 and 7 above and below')
	eq(bar:GetTop(), UIParent:GetTop(), 'at the top')
	check(bar:GetWidth() < UIParent:GetWidth() / 2, 'a bar, not a strip across the screen: ' .. bar:GetWidth())
	eq(bar:GetWidth() % 2, 0, 'an even width')
	local widest = 0
	for row = 1, 2 do
		local keys = keys_on(row)
		local first, last = frame_of(keys[1]), frame_of(keys[#keys])
		widest = math.max(widest, whole(last:GetRight()) - whole(first:GetLeft()))
		local left = first:GetLeft() - bar:GetLeft()
		local right = bar:GetRight() - last:GetRight()
		check(math.abs(left - right) <= 1, ('row %d is centred: %s in on the left, %s on the right'):format(row, left, right))
		check(left >= 10 and right >= 10, ('row %d keeps 10 at each end'):format(row))
	end
	eq(bar:GetWidth(), widest + 20 + (widest % 2), 'the wider row plus the padding, made even')
	eq(frame_of('exit'):GetTop(), bar:GetTop() - 7, 'row one starts 7 down')
	local filter = frame_of('filter')
	eq(filter:GetTop(), bar:GetTop() - (37 + math.floor((26 - filter:GetHeight()) / 2)), 'row two starts 37 down, a shorter box centred in its 26')
	eq(frame_of('gridSize'):GetTop(), bar:GetTop() - 9, 'the number box (22) centred in row one')
	reset()
end)

test('the dividers are 1 x 26 lines between the groups of a row: two on row one, one on row two', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local one, two = 0, 0
	for _, region in ipairs({ bar:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetWidth() == 1 and region:GetHeight() == 26 then
			local top = bar:GetTop() - region:GetTop()
			if top == 7 then one = one + 1 elseif top == 37 then two = two + 1 end
		end
	end
	eq(one .. ',' .. two, '2,1', 'two on the first row, one on the second')
	reset()
end)

test('the bar fits the narrowest screen at full labels, and nothing gives way: Exit and Options keep their words at every screen', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local exit, options = frame_of('exit'), frame_of('options')
	for _, screen in ipairs({ { 1024, 768 }, { 800, 600 }, { 1366, 768 }, { 1920, 1080 }, { 2560, 1440 } }) do
		set_screen(screen[1], screen[2])
		stub.fire_event('DISPLAY_SIZE_CHANGED')
		local where = screen[1] .. ': '
		check(bar:GetWidth() <= UIParent:GetWidth() - 20, where .. 'the bar fits with room: ' .. bar:GetWidth())
		check(exit:GetWidth() > 26 and options:GetWidth() > 26, where .. 'Exit and Options with their words')
		check(exit.text:IsShown() and options.text:IsShown(), where .. 'their labels show')
		check(frame_of('filter'):IsShown(), where .. 'the filter box shows')
		eq(frame_of('modules'):GetWidth(), 150, where .. 'the Show face is full')
		eq(frame_of('filter'):GetWidth(), 150, where .. 'and so is the filter')
	end
	check(EM.BAR.STAGES == nil and EM.BarWidthAt == nil, 'no stages: the dead width stages are gone')
	reset()
end)

test("the bar's size does not depend on the screen", function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local width = bar:GetWidth()
	for _, screen in ipairs({ { 1024, 768 }, { 2560, 1440 } }) do
		set_screen(screen[1], screen[2])
		stub.fire_event('UI_SCALE_CHANGED')
		eq(bar:GetWidth(), width, screen[1] .. ': the same width')
		eq(bar:GetHeight(), 70, screen[1] .. ': the same height')
	end
	reset()
end)

test("every piece of the two-row bar is on whole pixels under Thick, Thin and Blizzard, at 1024, 1920 and 2560 wide, with the read-back noise up, down and off", function()
	local HAIR = 2 ^ -14
	reset()
	EM:Activate()
	EM:SetSetting('grid', true)
	local bar = EM:GetBar()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name)
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1024, 768 }, { 1920, 1080 }, { 2560, 1440 } }) do
				set_screen(screen[1], screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED')
				local where = ('%s noise %s at %dx%d: '):format(name, noise, screen[1], screen[2])
				local off = P.off(bar)
				eq(#off, 0, where .. P.report(off))
				eq(whole(bar:GetWidth()) % 2, 0, where .. 'an even width')
				stub.fire_script(frame_of('exit'), 'OnMouseDown', 'LeftButton')
				off = P.off(bar)
				eq(#off, 0, where .. 'pressed: ' .. P.report(off))
				stub.fire_script(frame_of('exit'), 'OnMouseUp', 'LeftButton')
			end
		end
	end
	reset()
end)

test("at a scale that is not SaftUI's the controls still sit whole from the bar", function()
	reset()
	EM:Activate()
	set_screen(1920, 1080)
	UIParent:SetScale(0.71)
	stub.fire_event('UI_SCALE_CHANGED')
	for _, c in ipairs(EM:BarControls()) do
		if c.frame:IsShown() then
			local _, _, _, x, y = c.frame:GetPoint(1)
			eq(x, math.floor(x), c.key .. ': x whole from the bar')
			eq(y, math.floor(y), c.key .. ': y whole from the bar')
		end
	end
	set_screen(1920, 1080)
	reset()
end)

------------------------------------------------------------------ the status line

test('the docked bar has no status line: a message is shown as a tooltip under the control pressed (or under the bar), red for a refusal, for 6 seconds', function()
	reset()
	EM:Activate()
	local bar = EM:GetBar()
	local undo = frame_of('undo')
	EM:SetBarStatus('Undid: Player', undo)
	check(EM.statusCut, 'a message with no room on the bar')
	check(tip_on(undo), 'a tooltip under the control')
	check(not EM.statusText:IsShown(), 'no line drawn on the bar')
	eq(#P.off(bar), 0, 'the bar is as it was, on whole pixels')
	eq(bar:GetHeight(), 70, 'and no taller')
	stub.time = stub.time + 7
	stub.run_timers()
	check(not tip_on(undo), 'gone after 6 seconds')
	EM:SetBarStatus('Nothing to do', nil, true)
	check(tip_on(bar), 'with no control to put it under, under the bar')
	EM:SetBarStatus('')
	check(not tip_on(bar), 'cleared')
	stub.in_combat = true
	EM:SetBarStatus('Undid: Player', undo)
	check(not GameTooltip:IsShown(), 'never in combat')
	stub.in_combat = false
	reset()
end)
