-- The player's class power points under the Blizzard theme
-- (SaftUI-Unitframes/elements/classpower.lua): each point draws as a control,
-- and under Blizzard shows Blizzard's empty art behind and its filled art while
-- full, each as tall as the row's height and centred on the point; a power type
-- with no art keeps the flat bar; Thick and Thin draw flat bars again.
--
-- The world and the unit frame stand-in are those of theme_test.lua (see its
-- top): real Core, defaults, unitframes.lua, constructors and updaters and the
-- class power element; a SaftUI button for the unit frame. What oUF does for
-- class power (its Update) is stood in for by ClassPower:PostUpdate called with
-- the arguments oUF gives it: cur, max, hasCurChanged, hasMaxChanged, power type
-- and the charged points' indices.
local T = load_test_file('lib/theme_helpers.lua')
local UW = load_test_file('unitframes/uf_world.lua')

local st, UF, P, drawn

-- A fresh world on client (uf_world.lua's, with the player's config and the
-- class power element) for a player of class. Only the class power points
-- read st.my_class, when they're drawn.
local function fresh(client, class)
	st, UF, P = UW.world({ client = client, units = { 'player' }, elements = { 'classpower' } })
	st.my_class = class
	drawn = T.watch()
end

-- A unit frame for a config unit, with the named elements built by their own
-- constructors (see the top of this file).
local make_unit_frame = UW.unit_frame


-- The player's unit frame with a class power row of height 20, drawn.
local function player_frame(theme)
	st.config.profile.theme.name = theme
	P.player.classpower.enable = true
	P.player.classpower.height = 20
	local frame = make_unit_frame('SaftUI_ClassPowerPlayer', 'player', { 'ClassPower' })
	UF:UpdateUnitFrame(frame)
	frame.ClassPower:SetWidth(100)
	return frame
end

-- What oUF does: shows max points, fills cur of them, then PostUpdate.
local function power(frame, powerType, cur, max, ...)
	local row = frame.ClassPower
	for i = 1, max do
		row[i]:Show()
		row[i]:SetValue(i <= cur and 1 or 0)
	end
	row:PostUpdate(cur, max, true, true, powerType, ...)
end

-- The regions of a point that are textures with an atlas, by atlas.
local function atlases(point)
	local out = {}
	for _, region in ipairs({ point:GetRegions() }) do
		local atlas = region.GetAtlas and region:GetAtlas()
		if atlas then out[atlas] = region end
	end
	return out
end

local function shown(point, atlas)
	local region = atlases(point)[atlas]
	return region ~= nil and region:IsShown()
end

test("on Forever a rogue's points show uf-roguecp-bg, and uf-roguecp-icon-red while full, each 20 square and centred in its slot", function()
	fresh('forever', 'ROGUE')
	local frame = player_frame('blizzard')
	power(frame, 'COMBO_POINTS', 3, 5)
	for i = 1, 5 do
		local point = frame.ClassPower[i]
		eq(shown(point, 'uf-roguecp-bg'), true, 'point ' .. i .. ' shows the empty art')
		eq(shown(point, 'uf-roguecp-icon-red'), i <= 3, 'point ' .. i .. (i <= 3 and ' is full' or ' is empty'))
		for _, atlas in ipairs({ 'uf-roguecp-bg', 'uf-roguecp-icon-red' }) do
			local region = atlases(point)[atlas]
			eq(region:GetWidth() .. 'x' .. region:GetHeight(), '20x20', atlas .. ' is 20 square')
			eq(T.offset(region, 'CENTER'), '0.00,0.00', atlas .. ' is centred on its point')
		end
		eq(point:GetStatusBarTexture():GetAlpha(), 0, 'point ' .. i .. "'s flat fill is hidden")
	end
	eq(frame.ClassPower[1]:GetWidth() ~= frame.ClassPower[1]:GetHeight(), true, 'the slot is not square, so the art is sized by the height')
	eq(drawn(frame.ClassPower[1]), 'theme,theme,control', 'each point draws as a control')
	eq(#take_errors(), 0, 'no errors')
end)

test('a charged rogue point shows the blue icon', function()
	fresh('forever', 'ROGUE')
	local frame = player_frame('blizzard')
	power(frame, 'COMBO_POINTS', 3, 5, 2)
	local two, three = frame.ClassPower[2], frame.ClassPower[3]
	eq(shown(two, 'uf-roguecp-icon-blue'), true, 'the charged point is blue')
	eq(shown(two, 'uf-roguecp-icon-red'), false, 'and not red')
	eq(shown(three, 'uf-roguecp-icon-red'), true, 'another full point stays red')
	eq(shown(three, 'uf-roguecp-icon-blue'), false, 'and not blue')
	power(frame, 'COMBO_POINTS', 3, 5)
	eq(shown(two, 'uf-roguecp-icon-blue'), false, 'the charge ending takes the blue away')
	eq(shown(two, 'uf-roguecp-icon-red'), true, 'and it is red again')
	eq(#take_errors(), 0, 'no errors')
end)

test("a druid's combo points take the druid art", function()
	fresh('forever', 'DRUID')
	local frame = player_frame('blizzard')
	power(frame, 'COMBO_POINTS', 2, 5)
	eq(shown(frame.ClassPower[1], 'UF-DruidCP-BG-Active'), true, 'the druid empty art')
	eq(shown(frame.ClassPower[1], 'UF-DruidCP-Icon'), true, 'the druid filled art while full')
	eq(shown(frame.ClassPower[4], 'UF-DruidCP-Icon'), false, 'not while empty')
	eq(#take_errors(), 0, 'no errors')
end)

test('on retail a paladin\'s third point is rune 3, and rune3-active while full', function()
	fresh('retail', 'PALADIN')
	local frame = player_frame('blizzard')
	power(frame, 'HOLY_POWER', 3, 5)
	local third = frame.ClassPower[3]
	eq(shown(third, 'uf-holypower-rune3'), true, 'rune 3 behind')
	eq(shown(third, 'uf-holypower-rune3-active'), true, 'rune3-active while full')
	eq(shown(frame.ClassPower[4], 'uf-holypower-rune4-active'), false, 'the fourth is not full')
	power(frame, 'HOLY_POWER', 2, 5)
	eq(shown(third, 'uf-holypower-rune3-active'), false, 'losing the third takes its active art away')
	eq(#take_errors(), 0, 'no errors')
end)

test('a power type with no art keeps the flat bar', function()
	fresh('retail', 'MAGE')
	local frame = player_frame('blizzard')
	power(frame, 'ICICLES', 3, 5)
	for i = 1, 5 do
		local point = frame.ClassPower[i]
		eq(point:GetStatusBarTexture():GetAlpha(), 1, 'point ' .. i .. ' keeps its flat fill')
		eq(next(atlases(point)), nil, 'point ' .. i .. ' has no art showing')
		for _, region in ipairs({ point:GetRegions() }) do eq(region.GetAtlas and region:GetAtlas() and region:IsShown(), nil, 'no atlas shown') end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('under Thick the points are flat bars again, the art hidden', function()
	fresh('forever', 'ROGUE')
	local frame = player_frame('blizzard')
	power(frame, 'COMBO_POINTS', 3, 5)
	eq(shown(frame.ClassPower[1], 'uf-roguecp-bg'), true, 'the art shows under Blizzard')
	-- A theme switch, with no power event after it.
	st.config.profile.theme.name = 'thick'
	UF:UpdateUnitFrame(frame)
	for i = 1, 5 do
		local point = frame.ClassPower[i]
		eq(point:GetStatusBarTexture():GetAlpha(), 1, 'point ' .. i .. ' has its flat fill')
		eq(shown(point, 'uf-roguecp-bg') or shown(point, 'uf-roguecp-icon-red'), false, 'point ' .. i .. ' has no art')
	end
	-- A power event under Thick leaves it so, and back to Blizzard shows it again.
	power(frame, 'COMBO_POINTS', 4, 5)
	eq(shown(frame.ClassPower[1], 'uf-roguecp-icon-red'), false, 'a power event under Thick shows no art')
	st.config.profile.theme.name = 'blizzard'
	UF:UpdateUnitFrame(frame)
	eq(shown(frame.ClassPower[4], 'uf-roguecp-icon-red'), true, 'back to Blizzard: the art is back')
	eq(frame.ClassPower[1]:GetStatusBarTexture():GetAlpha(), 0, 'and the fill hidden')
	eq(#take_errors(), 0, 'no errors')
end)

test("a later SetValue and SetStatusBarColor leave a full point's fill at alpha 0", function()
	fresh('forever', 'ROGUE')
	local frame = player_frame('blizzard')
	power(frame, 'COMBO_POINTS', 3, 5)
	local point = frame.ClassPower[1]
	point:SetValue(1)
	point:SetStatusBarColor(1, 0, 0, 1)
	eq(point:GetStatusBarTexture():GetAlpha(), 0, "the fill's alpha stays 0")
	eq(#take_errors(), 0, 'no errors')
end)

test('points a shrinking max hides draw nothing', function()
	fresh('forever', 'ROGUE')
	local frame = player_frame('blizzard')
	power(frame, 'COMBO_POINTS', 5, 5)
	-- oUF hides the points past max itself.
	for i = 4, 5 do frame.ClassPower[i]:Hide() end
	frame.ClassPower:PostUpdate(3, 3, true, true, 'COMBO_POINTS')
	for i = 4, 5 do
		local point = frame.ClassPower[i]
		eq(point:IsShown(), false, 'point ' .. i .. ' is hidden')
		eq(point:IsVisible(), false, 'so its art is not visible')
	end
	eq(shown(frame.ClassPower[3], 'uf-roguecp-icon-red'), true, 'point 3 still draws')
	eq(#take_errors(), 0, 'no errors')
end)
