-- The hovered plate's border, and the target's colour, on the nameplates
-- (nameplates/target.lua).
local T = load_test_file('lib/theme_helpers.lua')
local NP = load_test_file('unitframes/nameplate_world.lua')

local function setup(client, theme)
	local st, UF = NP.world(client)
	if theme then st.config.profile.theme.name = theme end
	UF:SpawnNameplates()
	return st, UF
end

local function target(unit)
	stub.nameplate_target = unit
	stub.fire_event('PLAYER_TARGET_CHANGED')
end

-- The cursor comes onto unit: the game's answer, then its event.
local function hover(unit)
	stub.nameplate_mouseover = unit
	stub.fire_event('UPDATE_MOUSEOVER_UNIT')
end

-- The cursor leaves: the game fires nothing, so only the ticker sees it.
local function leave()
	stub.nameplate_mouseover = nil
	stub.time = stub.time + 0.1
	stub.run_timers()
end

local WHITE = '1.00,1.00,1.00'
local HOVER = '0.40,0.70,1.00'

test('Thick: the hovered plate takes the hover colour, and loses it when the cursor leaves', function()
	local st, UF = setup('forever', 'thick')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	hover('nameplate2')
	eq(UF:IsPlateHovered(two), true, 'two is hovered')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), HOVER, 'the hover colour')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, "the other keeps the theme's")
	leave()
	eq(UF:IsPlateHovered(two), false, 'no longer hovered')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), own, "back to the theme's")
	-- Nothing hovered: the ticker stopped.
	stub.time = stub.time + 1
	eq(stub.run_timers(), 0, 'no ticker left running')
end)

test('the hover moves straight from one plate to the next', function()
	local st, UF = setup('forever', 'thin')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	hover('nameplate1')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), HOVER, 'one')
	-- Onto two with no event between: the ticker finds it.
	stub.nameplate_mouseover = 'nameplate2'
	stub.time = stub.time + 0.1
	stub.run_timers()
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, 'one cleared')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), HOVER, 'two marked')
end)

test("the hovered target keeps the target's colour", function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	target('nameplate1')
	hover('nameplate1')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'still white')
	leave()
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'white after leaving too')
end)

test('the target and hover colours are the config\'s, and hover can be turned off', function()
	local st, UF = setup('forever', 'thick')
	local P = UF:GetProfileConfig().nameplate
	P.target_color = { r = 1, g = 0, b = 0 }
	P.hover_color = { r = 0, g = 1, b = 0 }
	UF:UpdateConfig('nameplate')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	local own = T.edge_rgb(UF.PlateBorderFrame(two))
	target('nameplate1')
	hover('nameplate2')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), '1.00,0.00,0.00', 'the target colour')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), '0.00,1.00,0.00', 'the hover colour')
	P.hover_highlight = false
	UF:UpdateConfig('nameplate')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), own, 'hover off: no colour')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), '1.00,0.00,0.00', 'the target keeps its')
end)

test('a theme recolour keeps the hover colour', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	hover('nameplate1')
	st:RecolorThemed()
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), HOVER, 'kept')
	UF:UpdateConfig('nameplate')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), HOVER, 'and through an update')
end)

test("friendly plates read the Friendly page's colours", function()
	local st, UF = setup('forever', 'thick')
	local F = UF:GetProfileConfig().friendlynameplate
	F.theme = 'thick'
	F.hover_color = { r = 1, g = 1, b = 0 }
	F.target_color = { r = 0, g = 0, b = 1 }
	NP.friend('nameplate1')
	NP.friend('nameplate2')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	eq(one.base_unit, 'friendlynameplate', 'drawn from the Friendly page')
	check(UF.PlateBorderFrame(one) ~= nil, 'a border to colour')
	hover('nameplate1')
	target('nameplate2')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), '1.00,1.00,0.00', "the friendly hover colour")
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), '0.00,0.00,1.00', "the friendly target colour")
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': Blizzard: the target art, tinted, round the hovered plate; white keeps the art as it is', function()
		local st, UF = setup(client, 'blizzard')
		local one, two = NP.add('nameplate1'), NP.add('nameplate2')
		target('nameplate1')
		local art = UF:PlateTargetArt(one)
		eq(art:IsShown(), true, 'the target art')
		eq(art.texture:IsDesaturated(), false, 'white: as Blizzard draws it')
		hover('nameplate2')
		local hart = UF:PlateTargetArt(two)
		eq(hart:IsShown(), true, 'shown on the hovered plate')
		eq(hart.texture:IsDesaturated(), true, 'on its grey')
		eq(T.text(hart.texture:GetVertexColor()), '0.40,0.70,1.00,1.00', 'in the hover colour')
		hover('nameplate1')
		eq(art.texture:IsDesaturated(), false, 'the hovered target keeps the white art')
		eq(T.text(art.texture:GetVertexColor()), '1.00,1.00,1.00,1.00', 'untinted')
		leave()
		eq(hart:IsShown(), false, 'hidden once the cursor leaves')
		eq(art:IsShown(), true, 'the target keeps its art')
	end)
end

test('the hovered plate is found by its plate frame: UnitIsUnit is never read', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	local real = UnitIsUnit
	UnitIsUnit = function() error('UnitIsUnit read') end
	hover('nameplate1')
	leave()
	UnitIsUnit = real
	eq(#take_errors(), 0, 'no error')
end)

test('a hovered unit with no plate, or a forbidden one, marks nothing', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	hover('party1')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, 'no plate: nothing')
	eq(UF:IsPlateHovered(one), false, 'no plate is hovered')
	local plate = stub.add_nameplate('nameplate2', { forbidden = true })
	hover('nameplate2')
	eq(UF:IsPlateHovered(one), false, 'forbidden: nothing')
	for _, child in ipairs({ plate:GetChildren() }) do
		if rawget(child, 'isNamePlate') then eq(UF:IsPlateHovered(child), false, 'not the forbidden plate either') end
	end
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, 'forbidden: no colour')
	-- Nothing hovered: no ticker.
	stub.time = stub.time + 1
	eq(stub.run_timers(), 0, 'no ticker')
end)

test('with Highlight on hover off on both pages, nothing is looked up and no ticker runs', function()
	local st, UF = setup('forever', 'thick')
	local P = UF:GetProfileConfig()
	P.nameplate.hover_highlight = false
	P.friendlynameplate.hover_highlight = false
	local one = NP.add('nameplate1')
	hover('nameplate1')
	eq(UF:IsPlateHovered(one), false, 'not hovered')
	stub.time = stub.time + 1
	eq(stub.run_timers(), 0, 'no ticker')
end)

test('a hovered plate removed and given to another unit loses the colour on the next tick', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	hover('nameplate1')
	NP.remove('nameplate1')
	stub.nameplate_mouseover = nil
	local again = NP.add('nameplate5', { plate = 1 })
	stub.time = stub.time + 0.1
	stub.run_timers()
	eq(UF:IsPlateHovered(again), false, 'not hovered')
	eq(T.edge_rgb(UF.PlateBorderFrame(again)), own, "the theme's own colour")
end)
