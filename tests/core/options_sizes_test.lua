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
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
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

test('OW.MiniLayout: the bar is its parts and their gaps, rounded up to even, at most 400, the tab cut first and then the page', function()
	local function layout(...) return table.concat({ OW.MiniLayout(...) }, ' ') end
	eq(layout(54, 90, 70, 56), '90 70 314', '12 + 54 + 8 + 90 + 8 + 70 + 8 + 56 + 8')
	local _, _, width = OW.MiniLayout(54, 90, 0, 56)
	eq(width, 236, 'no tab: its gap goes too')
	eq(layout(54, 90, 0, 56), '90 0 236')
	eq(layout(55, 90, 70, 56), '90 70 316', '315 rounded up to even')
	eq(layout(53.99997, 90.00002, 69.99999, 56), '90 70 314', 'each width is rounded first')
	eq(layout(54, 90, 70, 56.4), '90 70 314')
	-- Too wide for MINI_MAX: the tab is cut first, to what is left, and dropped with its gap when none is.
	eq(layout(54, 100, 300, 56), '100 146 400', 'the tab cut to the room')
	-- A tab cut under MIN_TAB (24) is dropped with its gap; the page then keeps its room.
	eq(layout(54, 240, 30, 56), '240 0 386', 'a 6 wide sliver of a tab is dropped, the page uncut')
	eq(layout(54, 200, 20, 56), '200 20 374', 'a tab that fits whole is never dropped, however narrow')
	eq(layout(54, 100, 100, 56), '100 100 354', 'a tab that fits')
	eq(layout(54, 100, 300, 76), '100 126 400', 'a tab cut to 126 stays')
	eq(layout(54, 200, 100, 46), '200 56 400', 'cut to 56')
	eq(layout(54, 200, 100, 78), '200 24 400', 'cut to exactly 24 stays')
	eq(layout(54, 200, 100, 79), '200 0 370', 'cut to 23 goes: 369 rounded up to even')
	eq(layout(54, 260, 30, 56), '254 0 400', 'dropped, then the page is cut to the room')
	eq(layout(54, 300, 300, 56), '254 0 400', 'the tab goes, then the page is cut')
	eq(layout(54, 400, 0, 56), '254 0 400', 'a page alone is cut to the room')
	eq(layout(54, 254, 0, 56), '254 0 400', 'a page that just fits')
	eq(layout(54, 255, 0, 56), '254 0 400', 'one over is cut')
	for _, args in ipairs({ { 54, 90, 70, 56 }, { 61, 117, 33, 56 }, { 61, 117, 331, 60 }, { 40, 500, 500, 60 } }) do
		local _, _, w = OW.MiniLayout(unpack(args))
		eq(w % 2, 0, 'even'); check(w <= OW.MINI_MAX, 'at most MINI_MAX')
	end
end)

test('OW.MiniShift: under Blizzard the metal\'s right and top reach, else nothing; OW.BrandText is Saft and the accent\'s UI', function()
	local _, reach_right, reach_top = st.ThemeArt.MetalReach()
	local dx, dy = OW.MiniShift(OW.LAYOUT.blizzard)
	eq(dx .. ' ' .. dy, reach_right .. ' ' .. reach_top, 'the metal\'s right and top reach')
	check(dx > 0 and dy > 0, 'some')
	dx, dy = OW.MiniShift(OW.LAYOUT.own)
	eq(dx .. ' ' .. dy, '0 0', 'none under Thick and Thin')
	local blue = st.config.profile.theme.accent
	local hex = ('%02x%02x%02x'):format(math.floor(blue.r * 255 + 0.5), math.floor(blue.g * 255 + 0.5), math.floor(blue.b * 255 + 0.5))
	eq(OW.BrandText(), 'Saft|cff' .. hex .. 'UI|r')
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
	set_screen(1365, 767)
	eq(OW.MaxWidth(own), 1324, 'an odd screen: the room (1325) made even')
	eq(OW.MaxWidth(blizzard) % 2, 0, 'even under Blizzard too')
	reset_screen()
	check(OW.Fits(own, 'full', true), 'a 1920 screen holds W1')
end)

test('OW.CentredCorner: centred by its top right corner, in whole units', function()
	eq(table.concat({ OW.CentredCorner(1920, 1080, 1040, 700) }, ','), '-440,-190')
	eq(table.concat({ OW.CentredCorner(1365, 767, 1040, 700) }, ','), '-162,-33', 'an odd screen rounds down')
	eq(table.concat({ OW.CentredCorner(1040, 700, 1040, 700) }, ','), '0,0', 'a window as big as the screen: no minus zero')
end)

test('OW.CornerOf: the top right corner of a window placed by any point, in whole units', function()
	local function corner(...) return table.concat({ OW.CornerOf(...) }, ',') end
	-- 1920 x 1080 screen; Thick and Thin 1040 x 700, Blizzard 1110 x 728.
	eq(corner('CENTER', -200, 50, 1040, 760, 1920, 1080), '-640,-110', 'Thick CENTER')
	eq(corner('CENTER', 120, -40, 1110, 728, 1920, 1080), '-285,-216', 'Blizzard CENTER')
	eq(corner('TOPLEFT', 100, -50, 1040, 700, 1920, 1080), '-780,-50', 'Thick TOPLEFT')
	eq(corner('TOPLEFT', 100, -50, 1110, 728, 1920, 1080), '-710,-50', 'Blizzard TOPLEFT')
	eq(corner('BOTTOMLEFT', 100, 40, 1040, 700, 1920, 1080), '-780,-340', 'Thick BOTTOMLEFT')
	eq(corner('BOTTOMLEFT', 100, 40, 1110, 728, 1920, 1080), '-710,-312', 'Blizzard BOTTOMLEFT')
	eq(corner('TOPRIGHT', -37, -21, 1040, 700, 1920, 1080), '-37,-21', 'TOPRIGHT is itself')
	eq(corner('BOTTOMRIGHT', -10, 30, 1110, 728, 1920, 1080), '-10,-322', 'Blizzard BOTTOMRIGHT')
	eq(corner('TOP', 0, -5, 1040, 700, 1920, 1080), '-440,-5', 'TOP')
	eq(corner('LEFT', 10, 0, 1040, 700, 1920, 1080), '-870,-190', 'LEFT')
	eq(corner('RIGHT', -10, 0, 1040, 700, 1920, 1080), '-10,-190', 'RIGHT')
	eq(corner('BOTTOM', 0, 0, 1040, 700, 1920, 1080), '-440,-380', 'BOTTOM')
	eq(corner('CENTER', 0, 0, 1040, 700, 1365, 767), '-162,-33', 'odd screen: the same as OW.CentredCorner, rounded')
	eq(corner('CENTER', 0.4, -0.6, 1040, 700, 1920, 1080), '-440,-191', 'rounded to whole units')
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

	-- A drag that ends between pixels rounds to whole units.
	stub.fire_script(frames().header, 'OnDragStart')
	w:ClearAllPoints(); w:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 300.4, -100.6)
	stub.fire_script(frames().header, 'OnDragStop')
	saved = st.config.global.optionsWindow
	eq(saved.x .. ' ' .. saved.y, '-580 -101', 'rounded, not cut')
	w:ClearAllPoints(); w:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 300, -100)
	stub.fire_script(frames().header, 'OnDragStop')
	saved = st.config.global.optionsWindow

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

test('a saved offset that is not whole is rounded when the window is placed', function()
	theme('thick')
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = -200.4, y = -49.6 }
	st.Config:Close(); st.Config:Open()
	local _, _, _, x, y = frames().window:GetPoint(1)
	eq(x .. ' ' .. y, '-200 -50', 'whole units')
	st.config.global.optionsWindow = nil
	close_all()
end)

test('an older save is converted by arithmetic: a window with no rect before it shows still opens where it was', function()
	for _, name in ipairs({ 'thick', 'blizzard' }) do
		theme(name)
		local w = frames().window or (st.Config:Open() and frames().window)
		st.Config:Close()
		for _, edge in ipairs({ 'GetRight', 'GetTop', 'GetLeft', 'GetBottom', 'GetCenter' }) do w[edge] = function() return nil end end
		local width, height = name == 'thick' and 1040 or 1110, 760
		st.config.global.optionsWindow = { point = 'CENTER', x = -200, y = 50, height = height }
		st.Config:Open()
		local saved = st.config.global.optionsWindow
		eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y .. ' ' .. saved.height,
			('TOPRIGHT %d %d 760'):format(-200 + (width - 1920) / 2, 50 + (760 - 1080) / 2), name .. ': rewritten as the corner')
		local point, _, _, px, py = w:GetPoint(1)
		eq(point .. ' ' .. px .. ' ' .. py, 'TOPRIGHT ' .. saved.x .. ' ' .. saved.y, name .. ': anchored there')
		st.Config:Close()
		for _, edge in ipairs({ 'GetRight', 'GetTop', 'GetLeft', 'GetBottom', 'GetCenter' }) do w[edge] = nil end
		st.config.global.optionsWindow = nil
		close_all()
	end
	theme('thick')
end)

test('a Blizzard look picked while the window is closed opens centred for that look', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open(); st.Config:Close()
	st.config.profile.theme.name = 'blizzard'
	st.Config:Open()
	local w = frames().window
	local cx = w:GetCenter()
	eq(cx, 960, 'centred at 1110 wide')
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
end)

------------------------------------------------------------------ full and half: the header's arrows

local click = H.click
local OB, W = st.OptionsBody, st.OptionsWidgets
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local function color_of(c) return string.format('%.2f,%.2f,%.2f', c:GetRGB()) end
local function vertex(texture) return string.format('%.2f,%.2f,%.2f', texture:GetVertexColor()) end

-- A button's tooltip lines as 'title | line | danger:line'.
local function tip_text(button)
	local title, lines = button.tip(button)
	local out = { title }
	for _, line in ipairs(lines or {}) do
		out[#out + 1] = type(line) == 'table' and ((line.danger and 'danger:' or '') .. line.text) or line
	end
	return table.concat(out, ' | ')
end

-- Time passes past the size guard (OW.SIZE_GUARD).
local function wait() stub.time = stub.time + 0.31 end

-- Modules for the cases below: 'Many' (sixty toggles, a page that scrolls),
-- 'Wide' (a page named with 20 characters, four tabs and a description) and
-- 'Items' (one item with a menu).
local manyValue = {}
local MANY = st:NewModule('Many')
function MANY:GetConfigTable()
	local args = {}
	for i = 1, 60 do
		args['t' .. i] = { order = i, type = 'toggle', name = 'Toggle ' .. i, desc = 'Toggle ' .. i,
			get = function() return manyValue[i] end, set = function(_, v) manyValue[i] = v end }
	end
	return { name = 'Many', type = 'group', category = 'Frames', args = args }
end

local wideDesc = 'A short description.'
local WIDE = st:NewModule('Wide')
function WIDE:GetConfigTable()
	local function tab(name, order)
		return { order = order, name = name, type = 'group', args = { on = { type = 'toggle', name = name .. ' on',
			get = function() return true end, set = function() end } } }
	end
	return {
		name = 'ABCDEFGHIJKLMNOPQRST', type = 'group', category = 'Frames', childGroups = 'tab', desc = wideDesc,
		args = { a = tab('First tab here', 1), b = tab('Second tab here', 2), c = tab('Third tab here', 3), d = tab('Fourth tab here', 4) },
	}
end

local itemValue = true
local ITEMS = st:NewModule('Items')
function ITEMS:GetConfigTable()
	return {
		name = 'Items', type = 'group', category = 'Frames',
		args = { texts = { order = 1, type = 'group', name = 'Texts', args = {
			hotkey = { order = 1, type = 'item', name = 'Hotkey', desc = 'The key.', size = 'small', menuTitle = 'Hotkey text',
				get = function() return itemValue end, set = function(_, v) itemValue = v end,
				menu = { type = 'group', name = 'Hotkey', args = {
					size = { order = 1, type = 'range', name = 'Size', desc = 'Its size.', min = 6, max = 20, step = 1,
						get = function() return 10 end, set = function() end },
				} } },
		} } },
	}
end

test('Shrink to half: 386 narrower from the left; the corner, the close X and the shrink arrow stay', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames(); local w = F.window
	check(F.shrink:IsShown() and not F.grow:IsShown(), 'full: shrink shows, grow does not')
	local right, top, closeLeft, shrinkLeft = w:GetRight(), w:GetTop(), F.close:GetLeft(), F.shrink:GetLeft()
	click(F.shrink)
	eq(OW:GetWindowSize(), 'half', 'half')
	eq(w:GetWidth(), 654, '1040 less 386'); eq(w:GetRight(), right, 'the right edge stays'); eq(w:GetTop(), top, 'and the top')
	eq(F.close:GetLeft(), closeLeft, 'the close X stays'); eq(F.grow:GetLeft(), shrinkLeft, 'and grow takes the place shrink had, beside the close X')
	check(F.grow:IsShown(), 'grow at half'); eq(F.shrink:GetRight(), F.grow:GetLeft() - 6, 'shrink 6 left of grow')
	check(F.shrink:IsShown(), 'shrink shows at half, left of grow')
	eq(F.content:GetWidth(), 388, 'the body one column')
	local state = OW:GetState()
	eq(state.page .. '/' .. state.pick .. '/' .. state.tab, 'Unitframes/player/general', 'the page, pick and tab kept')
	eq(st.config.global.optionsWindow.size, 'half', 'remembered')
	wait()
	click(F.grow)
	eq(w:GetWidth(), 1040); eq(w:GetRight(), right); eq(st.config.global.optionsWindow.size, nil, 'full saves nil')
	eq(OW:GetWindowSize(), 'full')
	eq(F.content:GetWidth(), 774)
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the arrows: the close X's size, minimize-2 and maximize-2 at 16, grey at rest and accent under the mouse, each with its tooltip", function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	eq(F.shrink:GetWidth() .. 'x' .. F.shrink:GetHeight(), '24x24', 'the close X\'s size')
	eq(F.shrink.icon:GetTexture(), st.icons.minimize2, 'shrink wears minimize-2')
	eq(F.shrink.icon:GetWidth() .. 'x' .. F.shrink.icon:GetHeight(), '16x16', 'at 16')
	eq(F.grow.icon:GetTexture(), st.icons.maximize2, 'grow wears maximize-2')
	eq(F.grow.icon:GetWidth() .. 'x' .. F.grow.icon:GetHeight(), '16x16', 'at 16')
	eq(F.shrink:GetTop(), F.close:GetTop(), 'top-aligned with the close X')
	eq(F.shrink:GetRight(), F.close:GetLeft() - 6, '6 left of the close X')
	eq(vertex(F.shrink.icon), color_of(st.config.profile.colors.text.muted), 'grey at rest')
	stub.fire_script(F.shrink, 'OnEnter', true)
	eq(vertex(F.shrink.icon), color_of(st.config.profile.theme.accent), 'accent under the mouse')
	check(GameTooltip:IsOwned(F.shrink) and GameTooltip:IsShown(), 'its tooltip, owned by it')
	eq(stub.state(GameTooltip).texts[1], 'Shrink to half', 'shown with its title')
	eq(tip_text(F.shrink), "Shrink to half | The page in one column. The window's right edge stays.")
	stub.fire_script(F.shrink, 'OnLeave', true)
	eq(vertex(F.shrink.icon), color_of(st.config.profile.colors.text.muted), 'grey again')
	check(not GameTooltip:IsShown(), 'the tooltip is gone')
	-- At half.
	click(F.shrink)
	stub.fire_script(F.grow, 'OnEnter', true)
	check(GameTooltip:IsOwned(F.grow), "grow's tooltip")
	stub.fire_script(F.grow, 'OnLeave', true)
	eq(tip_text(F.grow), 'Grow to full | The page in two columns.')
	eq(tip_text(F.shrink), 'Shrink to a bar | A small bar, to see the whole UI. It keeps the page.', "shrink at half is the bar's (Task 4)")
	-- The header stops 18 short of the leftmost arrow, at full and at half.
	eq(F.header:GetRight(), F.shrink:GetLeft() - 18, 'half: 18 short of shrink, the leftmost')
	wait(); click(F.grow)
	eq(F.header:GetRight(), F.shrink:GetLeft() - 18, 'full: 18 short of shrink')
	-- The close X's tooltip.
	stub.fire_script(F.close, 'OnEnter', true)
	check(GameTooltip:IsOwned(F.close) and GameTooltip:IsShown(), 'the close X has a tooltip')
	eq(GameTooltip:GetOwner(), F.close)
	local shown = stub.state(GameTooltip).texts
	eq(shown[1] .. ' | ' .. shown[2], 'Close | Closes the options window. Esc does too.', "the close X's words")
	stub.fire_script(F.close, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone when it leaves')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

-- The pair is [shrink][grow][X] at half and [shrink][X] at full: the button
-- beside the close X is shrink at full and grow at half, so a click on that
-- spot toggles full and half. Every edge whole, with the read-back's noise.
test('the arrows: [shrink][grow][X] at half, [shrink][X] at full, whole pixels under Thick, Thin and Blizzard', function()
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(look)
		st.config.global.optionsWindow = nil
		st.Config:Open('Unitframes', 'player', 'general')
		local F = frames()
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local where = look .. ' noise ' .. noise
			-- Full: shrink is beside the close X.
			check(F.shrink:IsShown() and not F.grow:IsShown(), where .. ' full: only shrink shows')
			eq(F.shrink:GetRight(), F.close:GetLeft() - 6, where .. ' full: shrink 6 left of the close X, no empty slot')
			-- Ruling 6's title room (under Blizzard the title is the body's width less 40, whatever the arrows).
			if look ~= 'blizzard' then eq(F.title:GetRight(), F.shrink:GetLeft() - 8, where .. ' full: the title ends 8 short of the leftmost button') end
			local off = P.off(F.window)
			eq(#off, 0, where .. ' full: ' .. P.report(off))
		end
		stub.size_noise = 0
		wait(); click(F.shrink)
		eq(OW:GetWindowSize(), 'half', look .. ': half')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local where = look .. ' noise ' .. noise
			check(F.shrink:IsShown() and F.grow:IsShown(), where .. ' half: both show')
			eq(F.grow:GetRight(), F.close:GetLeft() - 6, where .. ' half: grow 6 left of the close X')
			eq(F.shrink:GetRight(), F.grow:GetLeft() - 6, where .. ' half: shrink 6 left of grow')
			eq(F.shrink:GetTop(), F.grow:GetTop(), where .. ' half: level')
			if look ~= 'blizzard' then eq(F.title:GetRight(), F.shrink:GetLeft() - 8, where .. ' half: the title ends 8 short of the leftmost button') end
			local off = P.off(F.window)
			eq(#off, 0, where .. ' half: ' .. P.report(off))
		end
		stub.size_noise = 0
		-- The spot beside the close X toggles: grow there at half goes to full.
		wait(); click(F.grow)
		eq(OW:GetWindowSize(), 'full', look .. ': a click beside the close X at half grows to full')
		wait(); click(F.shrink)
		eq(OW:GetWindowSize(), 'half', look .. ': and shrink at full goes back to half')
		st.config.global.optionsWindow = nil
		close_all()
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('a size button ignores clicks for a third of a second after a change', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	wait()
	click(F.shrink)
	eq(OW:GetWindowSize(), 'half')
	click(F.grow)
	eq(OW:GetWindowSize(), 'half', 'a click at the same moment does nothing')
	eq(OW:Grow(), false, 'nor does Grow')
	stub.time = stub.time + 0.29
	click(F.grow)
	eq(OW:GetWindowSize(), 'half', 'still inside the guard')
	stub.time = stub.time + 0.02
	click(F.grow)
	eq(OW:GetWindowSize(), 'full', 'a third of a second on')
	eq(OW.SIZE_GUARD, 0.3)
	st.config.global.optionsWindow = nil
	close_all()
end)

test('OW:SetWindowSize: false in combat, for no change, for a jump from full to the bar, for a size that does not fit', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	wait()
	eq(OW:SetWindowSize('full'), false, 'no change')
	eq(OW:SetWindowSize('mini'), false, 'full to the bar is two steps')
	stub.in_combat = true
	eq(OW:SetWindowSize('half'), false, 'refused in combat')
	stub.in_combat = false
	eq(OW:GetWindowSize(), 'full')
	eq(OW:SetWindowSize('half'), true)
	eq(OW:Shrink(), false, 'inside the size guard')
	wait()
	eq(OW:Shrink(), true, 'then half shrinks to the bar')
	eq(OW:GetWindowSize(), 'mini')
	st.config.global.optionsWindow = nil
	close_all()
end)

test('between full and half the first row in view stays first in view, in one render', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Many')
	local F = frames()
	local t11 = H.cell('t11')
	OW.S.SetScroll(t11.y)
	eq(F.body:GetVerticalScroll(), t11.y, 'scrolled to t11')
	eq(select(1, OW.FirstInView(OW.GetDrawnRows(), F.body:GetVerticalScroll())), H.cell('t11').row.path, 't11 first in view')
	local renders = OW.GetRenderCount()
	wait()
	eq(OW:SetWindowSize('half'), true)
	eq(OW.GetRenderCount(), renders + 1, 'one render')
	local path = OW.FirstInView(OW.GetDrawnRows(), F.body:GetVerticalScroll())
	eq(path[#path], 't11', 'half: t11 is first in view')
	eq(F.body:GetVerticalScroll(), H.cell('t11').y, 'and at the top')
	check(F.body:GetVerticalScroll() > 0, 'a scrolled page')
	renders = OW.GetRenderCount()
	wait()
	eq(OW:SetWindowSize('full'), true)
	eq(OW.GetRenderCount(), renders + 1, 'one render back')
	path = OW.FirstInView(OW.GetDrawnRows(), F.body:GetVerticalScroll())
	eq(path[#path], 't11', 'full: t11 first again')
	eq(OW.S.keepRow, nil, 'the kept row is used up')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('OW.FirstInView and OW.OffsetFor: by the row\'s path, pure', function()
	local function cell(y, height, key) return { y = y, height = height, row = { path = { 'p', key } } } end
	local cells = { cell(0, 40, 'a'), cell(0, 40, 'b'), cell(40, 40, 'c'), cell(80, 60, 'd') }
	local path, delta = OW.FirstInView(cells, 0)
	eq(path[2] .. ' ' .. delta, 'a 0', 'the first cell at the top')
	path, delta = OW.FirstInView(cells, 30)
	eq(path[2] .. ' ' .. delta, 'a 30', 'a cell showing its last 10 pixels is first in view')
	path, delta = OW.FirstInView(cells, 40)
	eq(path[2] .. ' ' .. delta, 'c 0', 'a cell above the offset is out')
	path, delta = OW.FirstInView(cells, 100)
	eq(path[2] .. ' ' .. delta, 'd 20')
	eq(OW.FirstInView(cells, 140), nil, 'past the end: nothing')
	eq(OW.FirstInView({}, 0), nil, 'no cells: nothing')
	eq(OW.OffsetFor(cells, { 'p', 'd' }, 20), 100, 'back to where it was')
	eq(OW.OffsetFor(cells, { 'p', 'c' }, -10), 30, 'a delta under the cell')
	eq(OW.OffsetFor(cells, { 'p', 'a' }, -10), 0, 'never under 0')
	eq(OW.OffsetFor(cells, { 'p', 'zz' }, 0), nil, 'a row that is gone: nil')
	eq(OW.OffsetFor(cells, nil, 0), nil, 'no path: nil')
end)

test('OW.InnerCuts: the inner frame cut at its divider, from the atlas height', function()
	local look = { divider = 199, width = 886 }
	local list, settings = OW.InnerCuts(look, 618)
	eq(table.concat(list, ','), '0,199,0,618', 'the list part')
	eq(table.concat(settings, ','), '199,886,0,618', 'the settings part')
end)

test('at half the title, the description and the tabs follow the narrow body', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Wide')
	local F = frames()
	local function tabs_end() local out = 0; for _, t in ipairs(F.tabs) do out = math.max(out, t:GetRight() - F.main:GetLeft()) end return out end
	-- Full: the title in its font, in 724; the tabs on one line.
	eq(F.title:GetWidth(), 724, 'full: 724 of room')
	eq(F.title:GetFontObject(), OB.Font('title'), 'full: the title font')
	eq(F.desc:GetWidth(), 774, 'the description as wide as the body')
	check(F.desc:CanWordWrap(), 'it wraps')
	eq(F.main:GetTop() - F.tabs[1]:GetTop(), 87, 'a one-line description: the first tab line at 87')
	eq(F.tabs[1]:GetTop(), F.tabs[4]:GetTop(), 'four tabs on a line at full')
	check(tabs_end() <= 28 + 774, 'inside 774')
	wait(); click(F.shrink)
	eq(F.title:GetWidth(), 308, 'half: 308 of room')
	eq(F.title:GetFontObject(), OB.Font('brand'), '20 characters in the title font would not fit: the brand font')
	eq(F.desc:GetWidth(), 388, 'the description as wide as the narrow body')
	check(F.tabs[4]:GetTop() < F.tabs[1]:GetTop(), 'the tabs wrap at half')
	check(tabs_end() <= 28 + 388, 'each line ends inside 388 (' .. tabs_end() .. ')')
	eq(F.main:GetTop() - F.tabs[1]:GetTop(), 87, 'one line: 87')
	-- A wrapped description (its height as a wrapped one reads in game): 14 under its bottom.
	F.desc.GetStringHeight = function() return 45 end
	OW:Render()
	eq(F.main:GetTop() - F.tabs[1]:GetTop(), 20 + 26 + 4 + 45 + 14, 'wrapped (the brand title is 26 tall): 14 under its last line')
	F.desc.GetStringHeight = nil
	-- A page with a short name keeps the title font at half.
	st.Config:Open('Items')
	eq(F.title:GetFontObject(), OB.Font('title'), 'a short title keeps its font at half')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("Reload UI sits beside Close at every size; the region from the footer's left; the status wraps to two lines", function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		theme(name)
		st.config.global.optionsWindow = nil
		st.Config:Open('Unitframes', 'player', 'general')
		local F = frames()
		for _, size in ipairs({ 'full', 'half' }) do
			if size == 'half' then wait(); click(F.shrink) end
			local where = name .. ' ' .. size .. ': '
			eq(F.reloadButton:GetRight(), F.closeButton:GetLeft() - 12, where .. 'Reload UI 12 left of Close')
			eq(F.footerRegion:GetLeft(), F.footer:GetLeft() + 28, where .. "the region from the footer's left, PAD in")
			eq(F.footerRegion:GetRight(), F.reloadButton:GetLeft() - 12, where .. 'to 12 before Reload UI')
			eq(F.closeButton:GetRight(), F.footer:GetRight() - 26, where .. 'Close 26 in')
			check(F.status:CanWordWrap(), where .. 'the status wraps')
			eq(F.status:GetMaxLines(), 2, where .. 'to at most two lines')
		end
		st.config.global.optionsWindow = nil
		close_all()
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('opens at the remembered size; one the screen cannot hold opens at half, and Grow says why', function()
	theme('thick')
	st.config.global.optionsWindow = { size = 'half' }
	st.Config:Open('Unitframes', 'player', 'general')
	eq(OW:GetWindowSize(), 'half', 'a saved half opens at half')
	eq(frames().window:GetWidth(), 654)
	check(frames().grow:IsShown(), 'grow shows')
	st.Config:Close()
	st.config.global.optionsWindow = nil
	set_screen(1024, 768)
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	eq(OW:GetWindowSize(), 'half', 'a full the screen cannot hold opens at half')
	eq(F.window:GetWidth(), 654)
	eq(type(st.config.global.optionsWindow) == 'table' and st.config.global.optionsWindow.size or nil, nil, 'the save still has no size')
	check(F.grow.disabled, 'Grow is disabled')
	local _, lines = F.grow.tip(F.grow)
	local last = lines[#lines]
	check(type(last) == 'table' and last.danger and last.text == 'The screen is too narrow for the full window.', 'its last line, Danger, says why')
	eq(tip_text(F.grow), 'Grow to full | The page in two columns. | danger:The screen is too narrow for the full window.')
	wait(); click(F.grow)
	eq(OW:GetWindowSize(), 'half', 'a click does nothing')
	eq(OW:Grow(), false)
	st.Config:Close()
	reset_screen()
	st.Config:Open('Unitframes', 'player', 'general')
	eq(OW:GetWindowSize(), 'full', '1920 again: full')
	check(not frames().grow.disabled or not frames().grow:IsShown(), 'nothing disabled')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a saved sidebar and size are kept apart: a saved size does not touch the sidebar state', function()
	theme('thick')
	st.config.global.optionsWindow = { size = 'half', sidebar = false }
	st.Config:Open('Unitframes', 'player', 'general')
	eq(OW:GetWindowSize(), 'half')
	eq(OW.S.sidebar, false, 'the sidebar state is read from the save')
	eq(frames().window:GetWidth(), 446, 'W4')
	st.Config:Close()
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	eq(OW.S.sidebar, true, 'nothing saved: shown')
	st.config.global.optionsWindow = nil
	close_all()
end)

test('a size change never moves the corner, even where the full window passes the margin', function()
	theme('thick')
	st.config.global.optionsWindow = { point = 'TOPRIGHT', x = -1300, y = -50, size = 'half' }
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames(); local w = F.window
	local function corner() local _, _, _, x, y = w:GetPoint(1); return x .. ',' .. y end
	eq(corner(), '-1300,-50', 'opened at the saved corner')
	wait(); click(F.grow)
	eq(OW:GetWindowSize(), 'full')
	eq(corner(), '-1300,-50', 'Grow: the anchor is where it was')
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'half')
	eq(corner(), '-1300,-50', 'Shrink: and still')
	local saved = st.config.global.optionsWindow
	eq(saved.x .. ',' .. saved.y, '-1300,-50', 'the saved corner unchanged')
	eq(OW.S.corner.x .. ',' .. OW.S.corner.y, '-1300,-50', 'S.corner too')
	st.config.global.optionsWindow = nil
	close_all()
end)

test('while the color picker is open the arrows do nothing and say why', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	check(not F.shrink.disabled, 'enabled to start')
	check(W.OpenColorPicker(F.window, { r = 1, g = 0, b = 0, onChange = function() end }), 'the picker opens')
	check(W.ColorPickerShown(), 'it is shown')
	check(F.shrink.disabled, 'the arrow is disabled at once')
	stub.fire_script(F.shrink, 'OnEnter', true)
	check(GameTooltip:IsOwned(F.shrink), 'it still shows its tooltip')
	eq(tip_text(F.shrink), "Shrink to half | The page in one column. The window's right edge stays. | danger:Close the color picker first.")
	stub.fire_script(F.shrink, 'OnLeave', true)
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'full', 'a click does nothing')
	check(W.ColorPickerShown(), 'and the picker stays open: the guard wins over the body closing it')
	eq(OW:SetWindowSize('half'), false)
	W.CloseColorPicker()
	check(not F.shrink.disabled, 'enabled again when it closes')
	wait(); click(F.shrink)
	eq(OW:GetWindowSize(), 'half', 'and it works')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("whole pixels at full and at half, and the small dialog and an item's menu over the half window", function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		theme(name)
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			st.config.global.optionsWindow = nil
			st.Config:Close(); st.Config:Open('Unitframes', 'player', 'general')
			local F = frames()
			local where = name .. ' noise ' .. noise .. ': '
			local off = P.off(F.window)
			eq(#off, 0, where .. 'full ' .. P.report(off))
			wait(); click(F.shrink)
			eq(OW:GetWindowSize(), 'half')
			off = P.off(F.window)
			eq(#off, 0, where .. 'half ' .. P.report(off))
			-- Long strings on the status line: wrapped, still whole.
			OW:SetStatus('An error long enough to need a second line in the footer region of the half window, so it wraps')
			off = P.off(F.window)
			eq(#off, 0, where .. 'a wrapped status ' .. P.report(off))
			OW:SetStatus(nil)
		end
		stub.size_noise = 0
	end
	-- The small dialog and an item's menu at half.
	theme('thick')
	stub.size_noise = 2 ^ -14
	st.config.global.optionsWindow = { size = 'half' }
	st.Config:Close(); st.Config:Open('Items', 'texts')
	local F = frames()
	check(OW:OpenDialog('A dialog', { type = 'group', name = 'A dialog', args = { on = { type = 'toggle', name = 'On',
		get = function() return true end, set = function() end } } }), 'the dialog opens')
	local frame = OW.GetDialogFrames and OW.GetDialogFrames().frame
	check(frame ~= nil, 'its frame')
	local cx, cy = frame:GetCenter(); local wx, wy = F.window:GetCenter()
	check(math.abs(cx - wx) <= 1 and math.abs(cy - wy) <= 1, 'centred on the window')
	local off = P.off(frame)
	eq(#off, 0, 'the dialog: ' .. P.report(off))
	OW:CloseDialog()
	click(H.cell('hotkey').widget.dots)
	check(OW:IsMenuShown(), "the item's menu opens")
	local menu = OW.GetMenuFrames().frame
	off = P.off(menu)
	eq(#off, 0, 'the menu: ' .. P.report(off))
	local inset = st.config.profile.misc.clamp_inset
	check(menu:GetLeft() >= inset and menu:GetRight() <= UIParent:GetWidth() - inset, 'kept in the screen margin')
	OW:CloseMenu()
	stub.size_noise = 0
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ fix round 1

test("at half the unit frames' profile control hides where its region can't hold it, and never overlaps the sidebar", function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(name)
		st.config.global.optionsWindow = nil
		st.Config:Close(); st.Config:Open('Unitframes', 'player', 'general')
		local F = frames()
		local where = name .. ': '
		local function widths() local w = 0; for _, wd in ipairs(F.footerWidgets) do w = w + wd:GetWidth() + 8 end return w - 8 end
		check(F.footerControl:IsShown(), where .. 'full: shown')
		wait(); click(F.shrink)
		local room = F.footerRegion:GetRight() - F.footerRegion:GetLeft()
		if widths() > room then
			check(not F.footerControl:IsShown(), where .. 'half: too wide for ' .. room .. ', hidden')
		else
			check(F.footerControl:IsShown(), where .. 'half: it fits, shown')
		end
		if name ~= 'blizzard' then
			check(not F.footerControl:IsShown(), where .. 'under Thick and Thin the 258 does not fit 188')
			check(F.footerControl:GetLeft() >= F.main:GetLeft() or not F.footerControl:IsShown(), where .. 'never over the sidebar')
		else
			check(F.footerControl:IsShown(), where .. 'under Blizzard it fits')
		end
		check(F.status:IsShown(), where .. 'the status line has the region')
		wait(); click(F.grow)
		check(F.footerControl:IsShown(), where .. 'back at full: shown again')
		st.config.global.optionsWindow = nil
		close_all()
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('the half body is one column: a normal row takes a line of its own, at full it shares one', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	local function line_of(key) return H.cell(key).frame:GetTop() end
	eq(line_of('enable'), line_of('width'), 'full: two normal rows on one line')
	wait(); click(F.shrink)
	check(line_of('enable') ~= line_of('width'), 'half: each on its own line')
	check(H.cell('width').frame:GetWidth() > 194, 'half: a normal row is wider than a half of the half body')
	st.config.global.optionsWindow = nil
	close_all()
end)

test("under Blizzard the footer's region sits on the buttons' middle line", function()
	theme('blizzard')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	for _, size in ipairs({ 'full', 'half' }) do
		if size == 'half' then wait(); click(F.shrink) end
		eq(select(2, F.footerRegion:GetCenter()), select(2, F.closeButton:GetCenter()), size .. ': region on the buttons\' line')
		local _, _, _, _, y = F.footerRegion:GetPoint(1)
		eq(y, 6, size .. ': its left anchor carries the 6 that puts it on the buttons\' line (the footer\'s middle is 6 under it)')
	end
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
end)

test('a collapsed sidebar (a saved one, until Task 5) hides the list part of the inner frame and starts the main column at the sidebar\'s place', function()
	theme('blizzard')
	st.config.global.optionsWindow = { sidebar = false }
	st.Config:Close(); st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	check(not F.innerList:IsShown(), 'no list part')
	check(F.innerSettings:IsShown(), 'the settings part stays')
	check(not F.side:IsShown(), 'no sidebar')
	eq(F.main:GetLeft() - F.window:GetLeft(), OW.LAYOUT.blizzard.sideX, 'the main column at the sidebar\'s place')
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
end)

test('a cell that never got its place does not stop a size change from drawing', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Many')
	local rows = OW.GetDrawnRows()
	rows[#rows + 1] = { row = { path = { 'x' } }, height = 10 } -- no y, as a cell a failed draw leaves
	wait()
	eq(OW:SetWindowSize('half'), true, 'it changes')
	eq(frames().window:GetWidth(), 654, 'and the window follows')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('the arrows carry no reason the brief does not give: none for a size that fits; Task 4 owns the bar\'s', function()
	theme('thick')
	st.config.global.optionsWindow = nil
	st.Config:Open('Unitframes', 'player', 'general')
	local F = frames()
	eq(tip_text(F.shrink), "Shrink to half | The page in one column. The window's right edge stays.")
	set_screen(300, 768) -- not even half fits
	OW:Render()
	eq(tip_text(F.shrink), "Shrink to half | The page in one column. The window's right edge stays.", 'no invented red line')
	reset_screen()
	st.config.global.optionsWindow = nil
	close_all()
end)

------------------------------------------------------------------ the picker's line

test('OW.PickerFlow: pieces 12 apart, wrapping at the width, a line 24 tall and 8 under the last', function()
	eq(OW.PICKER_LINE_GAP, 8, 'the gap between lines')
	local function show(places)
		local out = {}
		for i, p in ipairs(places) do out[i] = ('(%d,%d)'):format(p.x, p.y) end
		return table.concat(out, ' ')
	end
	local places, height = OW.PickerFlow({ 210, 90, 225, 84 }, 774)
	eq(show(places), '(0,0) (222,0) (324,0) (561,0)', 'one line at full')
	eq(height, 24, 'a line is 24 tall')
	places, height = OW.PickerFlow({ 210, 90, 225, 84 }, 388)
	eq(show(places), '(0,0) (222,0) (0,32) (237,32)', 'two lines at half')
	eq(height, 56, 'two lines: 24 + 8 + 24')
	places, height = OW.PickerFlow({ 210, 400 }, 388)
	eq(show(places), '(0,0) (0,32)', 'a piece wider than the line goes alone on one')
	eq(height, 56)
	places = OW.PickerFlow({ 210, 100, 54 }, 388)
	eq(show(places), '(0,0) (222,0) (334,0)', 'a piece ending exactly at the width stays on the line')
	places = OW.PickerFlow({ 210, 100, 55 }, 388)
	eq(show(places), '(0,0) (222,0) (0,32)', 'one a unit wider wraps')
	places, height = OW.PickerFlow({ 210 }, 388)
	eq(show(places), '(0,0)', 'the picker alone')
	eq(height, 24)
	places, height = OW.PickerFlow({ 210, 90, 90, 90, 90, 90, 90 }, 388)
	eq(show(places), '(0,0) (222,0) (0,32) (102,32) (204,32) (0,64) (102,64)', 'three lines')
	eq(height, 88, 'three lines: 3 * 24 + 2 * 8')
end)
