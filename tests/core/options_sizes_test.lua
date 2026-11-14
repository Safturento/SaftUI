-- SaftUI-Core/Config/optionslayout.lua's numbers for /sui's three sizes (the
-- widths, the main column's left, the body's width, the next size, the saved
-- state, the most width and the centred corner) and optionswindow.lua's saved
-- place: the window anchored and saved by its top right corner, an older save
-- by another point converted on its first open.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model, the widgets, the body and the window (the
-- world options_window_helpers.lua loads). The mouse and the frame clock are
-- played by firing scripts (stub.fire_script).
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OW = st.OptionsWindow
local theme, close_all, frames = H.theme, H.close_all, H.frames

local SCALE = UIParent:GetScale()

local function set_screen(width, height)
	stub.screen_width, stub.screen_height = width, height
	UIParent:SetScale(768 / height)
end

local function reset_screen()
	stub.screen_width, stub.screen_height = 1920, 1080
	UIParent:SetScale(SCALE)
end

------------------------------------------------------------------ the numbers

test('OW.WindowWidth, OW.MainLeft and OW.BodyWidth: each state of each layout, every width even', function()
	local own, blizzard = OW.LAYOUT.own, OW.LAYOUT.blizzard
	local function widths(L)
		return ('%d %d %d %d'):format(OW.WindowWidth(L, 'full', true), OW.WindowWidth(L, 'full', false),
			OW.WindowWidth(L, 'half', true), OW.WindowWidth(L, 'half', false))
	end
	eq(widths(own), '1040 832 654 446', 'Thick and Thin: W1 to W4')
	eq(widths(blizzard), '1110 868 704 462', 'Blizzard: W1 to W4')
	eq(own.halfBody .. ' ' .. blizzard.halfBody, '388 368', 'the half bodies')
	for _, L in ipairs({ own, blizzard }) do
		for _, size in ipairs({ 'full', 'half' }) do
			for _, sidebar in ipairs({ true, false }) do
				eq(OW.WindowWidth(L, size, sidebar) % 2, 0, ('%s %s %s: even'):format(L == own and 'own' or 'blizzard', size, tostring(sidebar)))
			end
		end
	end
	eq(OW.MainLeft(own, true) .. ' ' .. OW.MainLeft(own, false), '210 2', 'the main column moves by whole numbers')
	eq(OW.MainLeft(blizzard, true) .. ' ' .. OW.MainLeft(blizzard, false), '259 17')
	eq(OW.BodyWidth(own, 'full') .. ' ' .. OW.BodyWidth(own, 'half') .. ' ' .. OW.BodyWidth(blizzard, 'half'), '774 388 368')
	eq(OW.BodyWidth(own, 'mini'), 388, 'the bar has the half body')
	-- The main column (width - MainLeft - mainRight): 828 at W1 and W2, 442 at W3 and W4; Blizzard 834 and 428.
	eq(OW.WindowWidth(own, 'full', true) - OW.MainLeft(own, true) - own.mainRight, 828)
	eq(OW.WindowWidth(own, 'half', false) - OW.MainLeft(own, false) - own.mainRight, 442)
	eq(OW.WindowWidth(blizzard, 'full', true) - OW.MainLeft(blizzard, true) - blizzard.mainRight, 834)
	eq(OW.WindowWidth(blizzard, 'half', false) - OW.MainLeft(blizzard, false) - blizzard.mainRight, 428)
	eq(OW.MINI_HEIGHT .. ' ' .. OW.MINI_MAX, '42 400')
end)

test('OW.NextSize steps full, half, mini and back, and stops at each end', function()
	local function steps(...)
		local out = {}
		for i = 1, select('#', ...), 2 do
			local size, step = select(i, ...)
			out[#out + 1] = tostring(OW.NextSize(size, step))
		end
		return table.concat(out, ' ')
	end
	eq(steps('full', 1, 'half', 1, 'mini', 1, 'mini', -1, 'half', -1, 'full', -1), 'half mini nil half full nil')
end)

test('OW.SavedState reads an older save, bad values and a saved bar safely', function()
	local function state(saved)
		st.config.global.optionsWindow = saved
		local size, sidebar = OW.SavedState()
		return size .. ' ' .. tostring(sidebar)
	end
	eq(state(nil), 'full true', 'nothing saved')
	eq(state({ size = 'half' }), 'half true')
	eq(state({ size = 'mini' }), 'half true', 'a bar comes back as half')
	eq(state({ size = 'huge' }), 'full true')
	eq(state({ size = 7 }), 'full true')
	eq(state({ sidebar = false }), 'full false')
	eq(state({ sidebar = 0 }), 'full true')
	eq(state({ sidebar = 'no' }), 'full true')
	eq(state({ point = 'CENTER', x = 1, y = 2, height = 760 }), 'full true', 'an older save')
	eq(state('junk'), 'full true', 'not a table')
	st.config.global.optionsWindow = nil
end)

test('OW.MaxWidth and OW.Fits: the screen less the margin, and the metal under Blizzard', function()
	local own, blizzard = OW.LAYOUT.own, OW.LAYOUT.blizzard
	local inset = st.config.profile.misc.clamp_inset
	set_screen(1024, 768)
	eq(OW.MaxWidth(own), 1024 - 2 * inset, 'the screen less the margin each side')
	eq(OW.MaxWidth(own), 984)
	check(not OW.Fits(own, 'full', true), 'W1 (1040) does not fit')
	check(OW.Fits(own, 'full', false), 'W2 (832) fits')
	check(OW.Fits(own, 'half', true), 'W3 (654) fits')
	local left, right = st.ThemeArt.MetalReach()
	eq(OW.MaxWidth(blizzard), 2 * math.floor((1024 - 2 * inset - left - right) / 2), 'Blizzard: less the metal at both sides, made even')
	eq(OW.MaxWidth(blizzard) % 2, 0)
	st.config.profile.misc.clamp_inset = -10
	eq(OW.MaxWidth(own), 1024, 'a margin under 0 counts as 0, as in OW.MaxHeight')
	st.config.profile.misc.clamp_inset = inset
	set_screen(10, 768)
	eq(OW.MaxWidth(own), 0, 'a screen narrower than its margins: 0, never negative')
	reset_screen()
	check(OW.Fits(own, 'full', true), 'a 1920 screen holds W1')
end)

test('OW.CentredCorner: centred by its top right corner, in whole units', function()
	eq(table.concat({ OW.CentredCorner(1920, 1080, 1040, 700) }, ','), '-440,-190')
	eq(table.concat({ OW.CentredCorner(1365, 767, 1040, 700) }, ','), '-162,-33', 'an odd screen rounds down')
	eq(table.concat({ OW.CentredCorner(1040, 700, 1040, 700) }, ','), '0,0', 'a window as big as the screen: no minus zero')
end)

------------------------------------------------------------------ the corner

test('the window is anchored and saved by its top right corner, read from where it shows', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open()
	local w = frames().window
	local point, relative, relPoint, x, y = w:GetPoint(1)
	eq(table.concat({ point, relPoint, x, y }, ' '), 'TOPRIGHT TOPRIGHT -440 -190', 'centred, by its corner')
	eq(relative, UIParent)
	eq(st.config.global.optionsWindow, nil, 'a window never moved saves nothing')
	stub.fire_script(frames().header, 'OnDragStart')
	w:ClearAllPoints(); w:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 300, -100) -- as StopMovingOrSizing leaves it
	stub.fire_script(frames().header, 'OnDragStop')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'TOPRIGHT -580 -100', 'saved from where it shows')
	eq(OW.S.corner.x .. ' ' .. OW.S.corner.y, '-580 -100', 'S.corner follows')
	point, _, relPoint, x, y = w:GetPoint(1)
	eq(table.concat({ point, relPoint, x, y }, ' '), 'TOPRIGHT TOPRIGHT -580 -100', 'anchored by the corner again')

	-- Another drag keeps the size, the sidebar and the height.
	saved.size, saved.sidebar, saved.height = 'half', false, 760
	stub.fire_script(frames().header, 'OnDragStart')
	w:ClearAllPoints(); w:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 500, -60)
	stub.fire_script(frames().header, 'OnDragStop')
	saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'TOPRIGHT -380 -60', 'the new corner')
	eq(tostring(saved.size) .. ' ' .. tostring(saved.sidebar) .. ' ' .. saved.height, 'half false 760', 'size, sidebar and height kept')

	-- Reopened: the same corner.
	st.Config:Close(); st.Config:Open()
	point, _, relPoint, x, y = w:GetPoint(1)
	eq(table.concat({ point, relPoint, x, y }, ' '), 'TOPRIGHT TOPRIGHT -380 -60', 'reopened where it was left')

	-- A small odd screen, with the game's read-back noise: every edge whole.
	st.config.global.optionsWindow = nil
	st.Config:Close()
	set_screen(1365, 767)
	for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
		stub.size_noise = noise
		st.Config:Close(); st.Config:Open()
		local off = P.off(w)
		eq(#off, 0, 'noise ' .. noise .. ': ' .. P.report(off))
	end
	stub.size_noise = 0
	reset_screen()
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('an older save by the centre restores where it was, and is converted to the corner on the first open', function()
	theme('thick')
	st.config.global.optionsWindow = { point = 'CENTER', x = -200, y = 50, height = 760 }
	st.Config:Open()
	local w = frames().window
	local cx, cy = w:GetCenter()
	eq((cx - 960) .. ',' .. (cy - 540), '-200,50', 'where the older version left it')
	local saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y .. ' ' .. saved.height, 'TOPRIGHT -640 -110 760', 'converted, the height kept')
	local point, _, relPoint, x, y = w:GetPoint(1)
	eq(table.concat({ point, relPoint, x, y }, ' '), 'TOPRIGHT TOPRIGHT -640 -110', 'anchored by the corner')
	eq(saved.size, nil, 'no size written')
	eq(saved.sidebar, nil, 'no sidebar written')

	-- Another point converts the same way.
	st.Config:Close()
	st.config.global.optionsWindow = { point = 'BOTTOMLEFT', x = 100, y = 40, height = 700 }
	st.Config:Open()
	local left, bottom = w:GetLeft(), w:GetBottom()
	eq(left .. ',' .. bottom, '100,40', 'placed as it was saved')
	saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y .. ' ' .. saved.height, 'TOPRIGHT -780 -340 700', 'converted from where it showed')
	eq(w:GetLeft() .. ',' .. w:GetBottom(), '100,40', 'and still there')

	-- A save that names no point opens centred and writes nothing.
	st.Config:Close()
	st.config.global.optionsWindow = { point = 'NOWHERE', x = 'a' }
	st.Config:Open()
	cx, cy = w:GetCenter()
	eq((cx - 960) .. ',' .. (cy - 540), '0,0', 'centred')
	saved = st.config.global.optionsWindow
	eq(saved.point .. ' ' .. tostring(saved.x), 'NOWHERE a', 'nothing written')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a window saved by a corner keeps its place across the looks, and every edge is whole under each', function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(name)
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			st.config.global.optionsWindow = { point = 'TOPRIGHT', x = -37, y = -21, height = 760 }
			st.Config:Close(); st.Config:Open()
			local w = frames().window
			local where = name .. ' noise ' .. noise .. ': '
			eq(w:GetRight(), 1920 - 37, where .. 'its right edge at the corner')
			eq(w:GetTop(), 1080 - 21, where .. 'its top at the corner')
			local off = P.off(w)
			eq(#off, 0, where .. P.report(off))
		end
	end
	stub.size_noise = 0
	theme('thick')
	st.config.global.optionsWindow = nil
	close_all()
end)
