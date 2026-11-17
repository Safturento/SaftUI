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
	test(client .. ": Blizzard: Blizzard's target art round the target's health bar; the box keeps its colour", function()
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
		-- The box is not turned white.
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

------------------------------------------------------------------ friendly plates

-- A unit the game shows: a friend, whose plate is the friendly config's name
-- alone by default (its health bar off, the frame's Theme None), or an enemy.
local friend, enemy = NP.friend, NP.enemy

-- The two points the target art's texture hangs from: their frames.
local function art_on(art)
	local on = {}
	for i = 1, art.texture:GetNumPoints() do
		local point, relativeTo = art.texture:GetPoint(i)
		on[point] = relativeTo
	end
	return on.TOPLEFT, on.BOTTOMRIGHT
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": Blizzard: a targeted friend's name-only plate has no art; an enemy's has, and a friend's with its bar turned on", function()
		local st, UF = setup(client, 'blizzard')
		friend('nameplate1')
		enemy('nameplate2')
		local ally, foe = NP.add('nameplate1'), NP.add('nameplate2')
		target('nameplate1')
		eq(UF.PlateBorderFrame(ally), nil, 'a name-only friend: no border frame (its bar is off, its frame None)')
		eq(UF:PlateTargetArt(ally):IsShown(), false, 'and no art round its hidden bar')
		target('nameplate2')
		eq(UF:PlateTargetArt(foe):IsShown(), true, 'an enemy: the art')
		eq(UF:PlateTargetArt(ally):IsShown(), false, 'the friend, no longer the target: none')

		UF:GetProfileConfig().friendlynameplate.health.enable = true
		UF:UpdateConfig('friendlynameplate', 'Health')
		target('nameplate1')
		eq(UF:PlateTargetArt(ally):IsShown(), true, 'a friend with its bar turned on: the art')
		local topLeft, bottomRight = art_on(UF:PlateTargetArt(ally))
		eq(topLeft, ally.Health, 'round its bar: TOPLEFT')
		eq(bottomRight, ally.Health, 'round its bar: BOTTOMRIGHT')
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ': Blizzard: a targeted plate handed from an enemy to a friend loses the art', function()
		local st, UF = setup(client, 'blizzard')
		enemy('nameplate1')
		stub.nameplate_target = 'nameplate1'
		local frame = NP.add('nameplate1')
		eq(UF:PlateTargetArt(frame):IsShown(), true, 'the targeted enemy: the art')

		-- The same plate for the next target, a friend.
		NP.remove('nameplate1')
		friend('nameplate2')
		stub.nameplate_target = 'nameplate2'
		eq(NP.add('nameplate2', { plate = 1 }), frame, 'the same frame')
		eq(UF:PlateTargetArt(frame):IsShown(), false, 'the targeted friend: none')

		-- And a targeted enemy turning friendly where it stands.
		NP.remove('nameplate2')
		enemy('nameplate3')
		stub.nameplate_target = 'nameplate3'
		NP.add('nameplate3', { plate = 1 })
		eq(UF:PlateTargetArt(frame):IsShown(), true, 'a targeted enemy again: the art')
		friend('nameplate3')
		stub.fire_event('UNIT_FACTION', 'nameplate3')
		eq(UF:PlateTargetArt(frame):IsShown(), false, 'turned friendly: none')
		eq(#take_errors(), 0, 'no error')
	end)

	test(client .. ": Blizzard: a friend's bar off but its frame drawn: the art goes round the frame", function()
		local st, UF = setup(client, 'blizzard')
		UF:GetProfileConfig().friendlynameplate.theme = 'theme'
		friend('nameplate1')
		local ally = NP.add('nameplate1')
		target('nameplate1')
		eq(UF.PlateBorderFrame(ally), st:DrawnFrame(ally), "the frame's border")
		eq(UF:PlateTargetArt(ally):IsShown(), true, 'the art')
		local topLeft, bottomRight = art_on(UF:PlateTargetArt(ally))
		eq(topLeft, ally, 'round the frame, not its hidden bar: TOPLEFT')
		eq(bottomRight, ally, 'BOTTOMRIGHT')
		eq(#take_errors(), 0, 'no error')
	end)
end

test("Thick: a targeted friend's name-only plate turns nothing white, its hidden bar included", function()
	local st, UF = setup('forever', 'thick')
	enemy('nameplate1')
	stub.nameplate_target = 'nameplate1'
	local frame = NP.add('nameplate1')
	local bar = st:DrawnFrame(frame.Health)
	eq(T.edge_rgb(bar), WHITE, 'the targeted enemy: its bar white')
	NP.remove('nameplate1')
	friend('nameplate2')
	stub.nameplate_target = 'nameplate2'
	NP.add('nameplate2', { plate = 1 })
	eq(UF.PlateBorderFrame(frame), nil, 'the targeted friend: no border frame')
	check(T.edge_rgb(bar) ~= WHITE, 'its hidden bar not left white')
	eq(#take_errors(), 0, 'no error')
end)
