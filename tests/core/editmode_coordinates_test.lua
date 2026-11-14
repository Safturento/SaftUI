-- Edit mode's Coordinates (SaftUI-Core/EditMode/coordinates.lua): the label that
-- names the selected mover's position by its anchoring corner and parent, where
-- it sits (outside the outline, flipped inside where the screen or the bar
-- leaves no room), what it follows (the selection, a drag) and when it hides.
-- The world is the bar test's: the real window, edit mode's files and the bar's.

local P = load_test_file('lib/pixels.lua')

local H, st, EM

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM = st.EditModeFrames
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

build()

local EMH = load_test_file('core/editmode_helpers.lua')
local settings, set_screen, look = EMH.settings, EMH.set_screen, EMH.look


local function add_mover(key, position, size)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(size and size[1] or 100, size and size[2] or 50)
	frame:SetPoint('CENTER', UIParent, 'CENTER')
	local config = { position = position or { point = 'CENTER', x_off = 0, y_off = 0 } }
	-- A theme change re-applies every mover: apply puts the frame where its position says.
	local function apply()
		local pos = config.position
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.rel_point or pos.point, tonumber(pos.x_off) or 0, tonumber(pos.y_off) or 0)
	end
	apply()
	return st:RegisterConfigMover(frame, { key = key, config = function() return config end, apply = apply }), config
end


local function reset()
	if EM.active then EM:Deactivate() end
	settings().coordinates = false
	settings().dim = true
	stub.in_combat = false
	stub.size_noise = 0
	set_screen(1920, 1080)
	look('thick')
	H.close_all()
end

local function rgb(color) return string.format('%.2f,%.2f,%.2f', color:GetRGB()) end

test('the text names the corner and the parent, in words', function()
	local function nameOf(ref) return ref == 'SaftUIBar2' and 'Bar 2' or nil end
	eq(EM.CoordinatesText({ point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 120, y_off = -330 }, nameOf),
		'Top left of the screen: 120, -330', 'the screen')
	eq(EM.CoordinatesText({ point = 'BOTTOM', rel_point = 'TOP', frame = 'SaftUIBar2', x_off = 0, y_off = 3 }, nameOf),
		'Bottom to top of Bar 2: 0, 3', 'another mover by its name, both points when they differ')
	eq(EM.CoordinatesText({ point = 'TOPLEFT', x_off = 5, y_off = 6 }, nameOf),
		'Top left of the screen: 5, 6', 'no frame: the screen')
	eq(EM.CoordinatesText({ point = 'TOPLEFT', frame = UIParent, x_off = 5, y_off = 6 }, nameOf),
		'Top left of the screen: 5, 6', 'UIParent itself: the screen')
	eq(EM.CoordinatesText({ point = 'CENTER', frame = 'UIParent', x_off = '12', y_off = '-4' }, nameOf),
		'Center of the screen: 12, -4', 'offsets saved as strings read as numbers; CENTER')
	eq(EM.CoordinatesText({ point = 'CENTER', x_off = 12.53, y_off = -0.04 }, nameOf),
		'Center of the screen: 12.5, 0', 'one decimal, no -0')
	eq(EM.CoordinatesText({ point = 'TOP', frame = 'ChatFrame1', x_off = 0, y_off = 0 }, nameOf),
		'Top of ChatFrame1: 0, 0', "a frame no mover has: its stored name")
	eq(EM.CoordinatesText({ point = 'LEFT', rel_point = 'LEFT', frame = 'UIParent' }, nameOf),
		'Left of the screen: 0, 0', 'no offsets: 0, 0')

	-- EM.MoverNameOf: the mover whose frame it is, by object and by global name.
	local mover = add_mover('coord_named')
	mover.label:SetText('Named frame\nsecond line')
	_G.CoordNamedFrame = mover.def.frame
	eq(EM.MoverNameOf(mover.def.frame), 'Named frame', 'by object')
	eq(EM.MoverNameOf('CoordNamedFrame'), 'Named frame', 'by its global name')
	eq(EM.MoverNameOf(CreateFrame('Frame')), nil, 'another frame: nil')
	eq(EM.MoverNameOf('NoSuchFrameAnywhere'), nil, 'no such global: nil')
	_G.CoordNamedFrame = nil
	EM.movers.coord_named = nil
end)

test('the label sits outside the outline at the anchoring corner, and flips inside where the screen ends or the bar covers it', function()
	local rect = { left = 100, right = 260, bottom = 400, top = 428 }
	local function spot(point, r, w, h, sw, st_)
		local x, y = EM.CoordinatesSpot(point, r or rect, w or 120, h or 10, sw or 1920, st_ or 1040)
		return x .. ',' .. y
	end
	eq(EM.COORD_GAP, 2, 'the gap')
	eq(spot('TOPLEFT'), '100,430', 'TOPLEFT: left aligned, above')
	eq(spot('BOTTOMRIGHT'), '140,388', 'BOTTOMRIGHT: right aligned, below')
	eq(spot('CENTER'), '120,409', 'CENTER: centred inside')
	eq(spot('RIGHT'), '262,409', 'RIGHT: beside, centred')
	eq(spot('LEFT'), '102,409', 'LEFT with no room beside: inside, left aligned')
	eq(spot('LEFT', { left = 300, right = 460, bottom = 400, top = 428 }), '178,409', 'LEFT beside the rect')
	eq(spot('TOP'), '120,430', 'TOP: centred, above')
	eq(spot('BOTTOM'), '120,388', 'BOTTOM: centred, below')
	eq(spot('TOPRIGHT'), '140,430', 'TOPRIGHT')
	eq(spot('BOTTOMLEFT'), '100,388', 'BOTTOMLEFT')

	-- No room: that axis flips inside, GAP in.
	eq(spot('TOPLEFT', { left = 100, right = 260, bottom = 1007, top = 1035 }), '100,1023', 'under the bar: inside')
	eq(spot('BOTTOMLEFT', { left = 100, right = 260, bottom = 4, top = 32 }), '100,6', 'at the bottom edge: inside')
	eq(spot('RIGHT', { left = 1700, right = 1919, bottom = 400, top = 428 }), '1797,409', 'RIGHT at the right edge: inside, right aligned')
	eq(spot('LEFT', { left = 50, right = 260, bottom = 400, top = 428 }), '52,409', 'LEFT at the left edge: inside, left aligned')
	-- Never off the screen, even where inside doesn't fit either.
	eq(spot('TOPLEFT', { left = -40, right = 20, bottom = 400, top = 428 }), '0,430', 'clamped to the left')
	eq(spot('CENTER', { left = 1900, right = 1990, bottom = 400, top = 428 }), '1800,409', 'clamped to the right')
	eq(spot('CENTER', { left = 100, right = 260, bottom = 1030, top = 1100 }), '120,1030', 'clamped below the bar')
	-- Whole.
	eq(spot('CENTER', { left = 100, right = 161, bottom = 400, top = 429 }), '71,410', 'rounded')

	-- Beside the docked bar's rect the strip is free; across its width the label stays
	-- under its bottom: the axis flips inside the outline, never onto the bar.
	local avoid = { left = 700, right = 1200, bottom = 1008 }
	local function avoiding(r, w)
		local x, y = EM.CoordinatesSpot('TOPLEFT', r, w or 120, 12, 1920, 1080, avoid)
		return x .. ',' .. y
	end
	eq(avoiding({ left = 100, right = 260, bottom = 1030, top = 1058 }), '100,1060', 'beside the bar: above the outline, in the strip')
	eq(avoiding({ left = 800, right = 960, bottom = 1030, top = 1058 }), '800,996', 'under the bar: flipped inside the outline, then held under the bar (the top is 1008)')
	eq(avoiding({ left = 1190, right = 1350, bottom = 1030, top = 1058 }), '1190,996', 'over the bar by its right end: the same')
	eq(avoiding({ left = 1210, right = 1370, bottom = 1030, top = 1058 }), '1210,1060', 'just past the bar: free')
	eq(avoiding({ left = 600, right = 700, bottom = 1030, top = 1058 }, 120), '600,996', 'a label that reaches over the left end is held under it')
	eq(avoiding({ left = 100, right = 200, bottom = 1030, top = 1058 }, 120), '100,1060', 'one that ends short of it is free')

	-- EM:BarRect is the rect the label reads.
	EM:Activate()
	local inset = st:ThemeInset('theme', 'theme', 'panel')
	check(inset > 0, 'Thick draws an inset')
	local bar = EM:BarRect()
	eq(bar.top - bar.bottom, 70 + inset, 'bar shown: its height and inset')
	EM:Deactivate()
	eq(EM:BarRect(), nil, 'hidden again: no rect')
	reset()
end)

test("Coordinates shows the selected mover's position, follows a drag, and hides when off", function()
	local m1 = add_mover('coord_one', { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 120, y_off = -330 })
	local m2 = add_mover('coord_two', { point = 'BOTTOM', rel_point = 'BOTTOM', x_off = 4, y_off = 8 })
	EM:Activate()
	EM:Select(m1)
	check(EM:GetBar():IsShown(), 'the bar is up')
	check(EM.coordinates and not EM.coordinates:IsShown(), 'off: hidden, with a mover selected')
	eq(EM.coordinates:IsMouseEnabled(), false, 'takes no mouse')
	eq(EM.coordinates:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	eq(EM.coordinates:GetFrameLevel(), 9600, 'level: over the bar and the floating window (9500), under the History list (9700)')

	EM:SetSetting('coordinates', true)
	check(EM.coordinates:IsShown(), 'on with a mover selected: shown')
	eq(EM.coordinates.text:GetText(), 'Top left of the screen: 120, -330', 'its position in words')
	eq(EM.coordinates.text:GetFontObject(), st:GetFont('pixel'), 'the pixel font')
	eq(rgb(CreateColor(EM.coordinates.text:GetTextColor())), rgb(st.config.profile.colors.button.blue), 'in the accent')
	-- Above the outline at the anchoring corner (TOPLEFT: left aligned).
	local l, r, b, t = EM.GetOutlineRect(m1)
	eq(EM.coordinates:GetLeft(), l, 'left aligned with the outline')
	check(EM.coordinates:GetBottom() >= t, 'above it')

	EM:Select(nil)
	check(not EM.coordinates:IsShown(), 'nothing selected: hidden')
	EM:Select(m1)
	check(EM.coordinates:IsShown(), 'selected again: shown')

	-- A drag: the dragged mover's live offsets, selected or not.
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(m2)
	eq(EM.coordinates.text:GetText(), 'Bottom of the screen: 4, 8', 'the dragged one, though m1 is selected')
	stub.cursor_x, stub.cursor_y = 530, 560
	EM:UpdateDrag(m2)
	stub.fire_script(EM.coordinates, 'OnUpdate', 0.01)
	eq(EM.coordinates.text:GetText(), ('Bottom of the screen: %s, %s'):format(m2.drag.x, m2.drag.y), "its live drag.x and drag.y")
	check(m2.drag.x ~= 4, 'which moved')
	EM:StopDrag(m2)
	eq(EM.coordinates.text:GetText(), 'Top left of the screen: 120, -330', 'back to the selected one')
	check(EM.coordinates:GetScript('OnUpdate') ~= nil, 'shown: its throttled OnUpdate runs')

	-- A mover whose outline rect can't be read (a secret edge): hidden.
	local real = EM.GetOutlineRect
	EM.GetOutlineRect = function() return nil end
	EM:UpdateCoordinates()
	check(not EM.coordinates:IsShown(), 'an unreadable rect: hidden')
	EM.GetOutlineRect = real
	EM:UpdateCoordinates()
	check(EM.coordinates:IsShown(), 'readable again: shown')

	-- In combat it hides, as the bar does.
	stub.in_combat = true
	EM:UpdateCoordinates()
	check(not EM.coordinates:IsShown(), 'in combat: hidden')
	stub.in_combat = false
	EM:UpdateCoordinates()

	-- A recolor reaches it.
	local blue = st.config.profile.colors.button.blue
	local r, g, b = blue:GetRGB()
	blue:SetRGB(0.2, 0.9, 0.3)
	st:ColorsChanged('button')
	eq(rgb(CreateColor(EM.coordinates.text:GetTextColor())), '0.20,0.90,0.30', 'the accent follows a recolor')
	blue:SetRGB(r, g, b)
	st:ColorsChanged('button')

	-- Parent named by its mover.
	local pos = m1.def.getPosition()
	pos.frame, pos.rel_point = m2.def.frame, 'TOP'
	EM:UpdateCoordinates()
	check(EM.coordinates.text:GetText():find('Top left to top of ' .. EM.MoverName(m2), 1, true), 'another mover by its name')

	EM:SetSetting('coordinates', false)
	check(not EM.coordinates:IsShown(), 'turned off: hidden')
	eq(EM.coordinates:GetScript('OnUpdate'), nil, 'hidden: no OnUpdate runs')
	EM:SetSetting('coordinates', true)
	EM:Deactivate()
	check(not EM.coordinates:IsShown(), 'edit mode off: hidden')
	eq(#P.off(EM.coordinates), 0, 'nothing off the pixel grid while hidden')
	EM.movers.coord_one, EM.movers.coord_two = nil, nil
	reset()
end)

test("the label's edges are whole pixels under every look, at any screen, with the game's read-back noise", function()
	local HAIR = 2 ^ -14
	local m = add_mover('coord_pixels', { point = 'CENTER', x_off = 0, y_off = 0 })
	EM:Activate()
	EM:SetSetting('coordinates', true)
	EM:Select(m)
	-- The game measures text in fractions: a width 0.37 over what the stub says.
	local text = EM.coordinates.text
	local measure = getmetatable(text).__index.GetStringWidth
	text.GetStringWidth = function(self) return measure(self) + 0.37 end
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name)
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1920, 1080 }, { 1366, 768 }, { 800, 600 } }) do
				set_screen(screen[1], screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED') -- the label follows the event itself
				local where = ('%s noise %s at %dx%d: '):format(name, noise, screen[1], screen[2])
				check(EM.coordinates:IsShown(), where .. 'shown')
				local off = P.off(EM.coordinates)
				eq(#off, 0, where .. P.report(off))
			end
		end
	end
	check(EM.coordinates:GetWidth() >= text:GetStringWidth(), 'the frame is never narrower than its text')
	text.GetStringWidth = nil
	EM.movers.coord_pixels = nil
	reset()
end)

test('an arrow-key nudge moves the label with the frame', function()
	local m = add_mover('coord_nudge', { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 120, y_off = -330 })
	EM:Activate()
	EM:SetSetting('coordinates', true)
	EM:Select(m)
	local left = EM.coordinates:GetLeft()
	EM:Nudge(m, 'RIGHT', false)
	eq(m.def.getPosition().x_off, 121, 'the frame moved a pixel')
	eq(EM.coordinates.text:GetText(), 'Top left of the screen: 121, -330', 'the numbers')
	eq(EM.coordinates:GetLeft(), left + 1, 'and the place')
	EM.movers.coord_nudge = nil
	reset()
end)

test("a position changed in /sui (a module's setter, a reset) reaches the label after the throttle, without PositionChanged", function()
	local m, config = add_mover('coord_sui', { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 120, y_off = -330 })
	EM:Activate()
	EM:SetSetting('coordinates', true)
	EM:Select(m)
	local changed = 0
	EM:On('PositionChanged', function() changed = changed + 1 end)
	local label = EM.coordinates
	local left = label:GetLeft()
	check(label:GetScript('OnUpdate') ~= nil, 'shown: it has an OnUpdate')

	config.position.x_off = 400 -- what the Position block's setter does
	m.def.apply()
	stub.fire_script(label, 'OnUpdate', 0.04)
	eq(label.text:GetText(), 'Top left of the screen: 120, -330', 'not yet: under the throttle')
	stub.fire_script(label, 'OnUpdate', 0.08)
	eq(label.text:GetText(), 'Top left of the screen: 400, -330', 'then the new numbers')
	eq(label:GetLeft(), left + 280, 'and the new place')
	eq(changed, 0, 'PositionChanged never fired')

	config.position.y_off = -100 -- a reset writes the table directly
	m.def.apply()
	stub.fire_script(label, 'OnUpdate', 0.11)
	eq(label.text:GetText(), 'Top left of the screen: 400, -100', 'a second change')
	eq(changed, 0, 'still no PositionChanged')

	EM:Select(nil)
	eq(label:GetScript('OnUpdate'), nil, 'hidden: nothing runs')
	EM:Select(m)
	check(label:GetScript('OnUpdate') ~= nil, 'shown again: it runs')
	EM:Deactivate()
	eq(label:GetScript('OnUpdate'), nil, 'edit mode off: nothing runs')
	EM.movers.coord_sui = nil
	reset()
end)

test('the label follows a new screen size on the screen events alone', function()
	local m = add_mover('coord_screen', { point = 'CENTER', x_off = 0, y_off = 0 })
	EM:Activate()
	EM:SetSetting('coordinates', true)
	EM:Select(m)
	for _, event in ipairs({ 'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED' }) do
		for _, screen in ipairs({ { 1366, 768 }, { 1920, 1080 } }) do
			set_screen(screen[1], screen[2])
			-- The mover's frame is re-placed by the game (anchored to UIParent's middle).
			stub.fire_event(event)
			local l, r = EM.GetOutlineRect(m)
			local mid = (EM.coordinates:GetLeft() + EM.coordinates:GetRight()) / 2
			check(math.abs(mid - (l + r) / 2) <= 1, ('%s at %dx%d: centred on the outline (%s vs %s)'):format(event, screen[1], screen[2], mid, (l + r) / 2))
		end
	end
	EM.movers.coord_screen = nil
	reset()
end)
