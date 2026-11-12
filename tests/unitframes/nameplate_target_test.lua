-- The target's border on the nameplates (nameplates/target.lua).
local T = load_test_file('lib/theme_helpers.lua')
local NP = load_test_file('unitframes/nameplate_world.lua')

local ATLAS = { forever = 'UI-HUD-CoolDownManager-Selected-yellow', retail = 'UI-HUD-Nameplates-Selected' }

local function setup(client, theme)
	local st, UF = NP.world(client)
	if theme then st.config.profile.theme.name = theme end
	UF:SpawnNameplates()
	return st, UF
end

-- The target changes: the game's answer, then its event.
local function target(unit)
	stub.nameplate_target = unit
	stub.fire_event('PLAYER_TARGET_CHANGED')
end

local WHITE = '1.00,1.00,1.00'

test("Thick: the target plate's health border is white; the others keep the theme's", function()
	local st, UF = setup('forever', 'thick')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	check(own ~= WHITE, "the theme's own colour is not white")
	target('nameplate2')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), WHITE, 'the target: white')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, "the other: the theme's")
	eq(UF:PlateTargetArt(two):IsShown(), false, 'no art under Thick')
end)

test('Thin: the same white line', function()
	local st, UF = setup('retail', 'thin')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	target('nameplate1')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'the target: white')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), own, "the other: Thin's")
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": Blizzard: Blizzard's target art round the target's health bar; the bronze box keeps its colour", function()
		local st, UF = setup(client, 'blizzard')
		local one, two = NP.add('nameplate1'), NP.add('nameplate2')
		target('nameplate2')
		local art, other = UF:PlateTargetArt(two), UF:PlateTargetArt(one)
		eq(art:IsShown(), true, 'shown on the target')
		eq(other:IsShown(), false, 'hidden on the other')
		local texture = art.texture
		eq(texture:GetAtlas(), ATLAS[client], 'its atlas')
		local control = st.ThemeArt.Control('nameplatetarget')
		eq(control.atlas, ATLAS[client], "the control's atlas")
		eq(T.text(texture:GetVertexColor()), '1.00,1.00,1.00,1.00', 'white')
		local left, top, right, bottom = unpack(control.offsets)
		local found = {}
		for i = 1, texture:GetNumPoints() do
			local point, rel, _, x, y = texture:GetPoint(i)
			found[point] = { rel, x, y }
		end
		eq(found.TOPLEFT[1], two.Health, 'TOPLEFT on Health')
		eq(found.TOPLEFT[2] .. ',' .. found.TOPLEFT[3], left .. ',' .. top, 'TOPLEFT offsets')
		eq(found.BOTTOMRIGHT[1], two.Health, 'BOTTOMRIGHT on Health')
		eq(found.BOTTOMRIGHT[2] .. ',' .. found.BOTTOMRIGHT[3], right .. ',' .. bottom, 'BOTTOMRIGHT offsets')
		eq(art:GetFrameLevel(), two.Health:GetFrameLevel() + 2, 'two levels over the bar')
		eq(art:GetParent(), two, "a child of the plate's frame")
		-- The bronze box is not turned white.
		local border = UF.PlateBorderFrame(two)
		local before = T.art(border)
		check(before ~= '', 'the box is there')
		target('nameplate1')
		eq(T.art(border), before, 'the box keeps its art through the target change')
		eq(T.art(UF.PlateBorderFrame(one)), before, "and the other plate's box is the same")
		eq(art:IsShown(), false, 'hidden once the target moves')
		eq(other:IsShown(), true, 'and shown on the new target')
	end)
end

test('the Forever and retail target art differ and are on their clients only', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = T.client(client)
		eq(st.ThemeArt.Control('nameplatetarget').layer, 'OVERLAY', client .. ': layer')
		local atlases = st:ThemeAtlases()
		eq(atlases['UI-HUD-CoolDownManager-Selected-yellow'], 'forever', 'forever only')
		eq(atlases['UI-HUD-Nameplates-Selected'], 'live', 'live only')
	end
end)

test("the border follows PLAYER_TARGET_CHANGED and is found on a plate's add", function()
	local st, UF = setup('forever', 'thick')
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	target('nameplate2')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), WHITE, 'two white')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, 'one not')
	target('nameplate1')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'one white')
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), own, 'two back')
	-- A plate added as the target is white at once.
	stub.nameplate_target = 'nameplate3'
	local three = NP.add('nameplate3')
	eq(T.edge_rgb(UF.PlateBorderFrame(three)), WHITE, 'a new target plate')
end)

test('the target is found by its plate frame: UnitIsUnit is never read', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	local realUnitIsUnit = UnitIsUnit
	UnitIsUnit = function() error('UnitIsUnit read') end
	target('nameplate1')
	UF:UpdatePlateTarget(one)
	UnitIsUnit = realUnitIsUnit
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'white')
	eq(#take_errors(), 0, 'no error')
	eq(UF:IsPlateTarget(one), true, 'is the target')
end)

test('no target, or a target with no SaftUI plate: no plate is marked', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	local own = T.edge_rgb(UF.PlateBorderFrame(one))
	target(nil)
	eq(UF:IsPlateTarget(one), false, 'no target')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, 'no white')
	-- A forbidden plate is the target's: C_NamePlate gives nothing for it.
	NP.add('nameplate2', { forbidden = true })
	target('nameplate2')
	eq(UF:IsPlateTarget(one), false, 'a forbidden plate as the target')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), own, 'still none')
	eq(UF:PlateTargetArt(one):IsShown(), false, 'no art')
end)

test("the border keeps its colour through one recolor function, the same for every plate and every update (no new closure each time)", function()
	local st, UF = setup('forever', 'thick')
	local kept = {}
	local real = st.KeepOwnColors
	st.KeepOwnColors = function(self, frame, color)
		kept[#kept + 1] = color
		return real(self, frame, color)
	end
	local ok, err = pcall(function()
		local one, two = NP.add('nameplate1'), NP.add('nameplate2')
		target('nameplate1')
		target('nameplate2')
		UF:UpdateConfig('nameplate')
	end)
	st.KeepOwnColors = real
	check(ok, tostring(err))
	check(#kept > 4, 'kept on every add, target change and update: ' .. #kept)
	local same = 0
	for _, color in ipairs(kept) do
		if color == kept[1] then same = same + 1 end
	end
	eq(same, #kept, 'one function every time')
	check(type(kept[1]) == 'function', 'a function')
end)

test('a config update keeps the white border on the target', function()
	local st, UF = setup('forever', 'thick')
	local one = NP.add('nameplate1')
	target('nameplate1')
	UF:UpdateConfig('nameplate')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'still white')
	st.config.profile.theme.name = 'thin'
	UF:UpdateConfig('nameplate')
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'white under Thin')
	st:RecolorThemed()
	eq(T.edge_rgb(UF.PlateBorderFrame(one)), WHITE, 'and through a theme recolour')
end)

test("health drawn None: the white goes on the plate frame's border when that is drawn", function()
	local st, UF = setup('forever', 'thick')
	local P = UF:GetProfileConfig().nameplate
	P.health.theme = 'none'
	P.theme = 'thick'
	local one, two = NP.add('nameplate1'), NP.add('nameplate2')
	UF:UpdateConfig('nameplate')
	target('nameplate2')
	eq(UF.PlateBorderFrame(two), st:DrawnFrame(two), "the plate frame's")
	eq(T.edge_rgb(UF.PlateBorderFrame(two)), WHITE, 'white on the target')
	check(T.edge_rgb(UF.PlateBorderFrame(one)) ~= WHITE, 'not on the other')
	-- Neither drawn: nothing.
	P.theme = 'none'
	UF:UpdateConfig('nameplate')
	eq(UF.PlateBorderFrame(two), nil, 'no border frame')
	eq(UF:PlateTargetArt(two):IsShown(), false, 'no art')
end)

-- The game reuses a plate's frame for unit after unit.
for _, theme in ipairs({ 'thick', 'blizzard' }) do
	test('a reused plate frame: ' .. theme .. ': the border follows the unit it now shows', function()
		local st, UF = setup('forever', theme)
		local function marked(frame)
			if theme == 'blizzard' then return UF:PlateTargetArt(frame):IsShown() end
			return T.edge_rgb(UF.PlateBorderFrame(frame)) == WHITE
		end
		local one = NP.add('nameplate1')
		target('nameplate1')
		eq(marked(one), true, 'the target is marked')
		NP.remove('nameplate1')
		stub.nameplate_target = nil
		local again = NP.add('nameplate2', { plate = 1 })
		eq(again, one, 'the same plate frame')
		eq(marked(again), false, 'a non-target unit on it: not marked')
		NP.remove('nameplate2')
		stub.nameplate_target = 'nameplate3'
		again = NP.add('nameplate3', { plate = 1 })
		eq(marked(again), true, 'the target on it again: marked')
	end)
end
