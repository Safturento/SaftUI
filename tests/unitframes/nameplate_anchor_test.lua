-- The nameplate pages' Position editor, "relative to": the game refuses to
-- measure a nameplate's parts (GetPoint errors "Can't measure restricted
-- regions", in combat and out), so st:ValidateAnchor can't walk their live
-- anchors. For a plate's parts it reads the anchors SaftUI's config gives them
-- (UF:GetFrame's rule: position.element, else position.frame, else the unit
-- frame), through the anchor source the unit frames register
-- (st:RegisterAnchorSource, api.lua; UF.PlatePartAnchors).
--
-- Real: nameplate_world.lua's world (the real config, generator and
-- ValidateAnchor), whose stubs refuse any measuring call a SaftUI file makes on
-- a plate's region. An ordinary frame keeps the live walk
-- (editmode_snap_test.lua has that).
local NP = load_test_file('unitframes/nameplate_world.lua')

local function plate_world(client)
	local st, UF = NP.world(client or 'forever')
	UF:SpawnNameplates()
	return st, UF
end

-- The Castbar's Position editor as the page builds it, on the enemy page, and
-- the config it reads and writes.
local function editor(st, UF, element)
	local P = UF:GetProfileConfig().nameplate
	local config = P[element:lower()]
	local option = st.Config.generators.uf_element_position(1,
		function(k) return config.position[k] end,
		function(k, v) config.position[k] = v end,
		UF:ConfigTarget('nameplate', element))
	return option, P
end

-- validate's result: whether it ran without error, and what it answered.
local function is(ok, res, want_ok, want_res, msg)
	eq(ok, want_ok, msg .. ' (no error' .. (ok and '' or ': ' .. tostring(res)) .. ')')
	eq(res, want_res, msg)
end

local function validate(option, choice)
	local ok, res = pcall(option.validate, {}, 'relative_to', choice)
	return ok, res
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': a plate on screen, relative to another part: accepted when no loop, refused when one, no error', function()
		local st, UF = plate_world(client)
		NP.enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check(UF:GetConfigFrame('nameplate') == frame, 'the editor targets the plate on screen')
		local option, P = editor(st, UF, 'Castbar')

		local ok, res = validate(option, 'Health')
		is(ok, res, true, true, 'Castbar relative to Health (its default): no error, accepted')
		ok, res = validate(option, '__unitframe')
		is(ok, res, true, true, 'the unit frame')
		ok, res = validate(option, '__global')
		is(ok, res, true, true, 'Global frame')
		ok, res = validate(option, 'Name')
		is(ok, res, true, true, 'Name sits on the Health bar: no loop')

		-- Health on the Castbar: the Castbar on Health would loop.
		P.health.position = { point = 'TOP', element = 'Castbar', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		ok, res = validate(option, 'Health')
		is(ok, res, true, 'Anchor would create a loop', 'Health is on the Castbar: refused, no error')
		-- Through another part: Name on Health on the Castbar.
		ok, res = validate(option, 'Name')
		is(ok, res, true, 'Anchor would create a loop', 'Name is on Health, which is on the Castbar: refused')
		ok, res = validate(option, '__unitframe')
		is(ok, res, true, true, 'the unit frame still fine')

		-- A part anchored to a global frame ends the walk: no loop.
		P.health.position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 }
		ok, res = validate(option, 'Health')
		is(ok, res, true, true, 'Health on a global frame: no loop')

		-- A loop that doesn't pass through the part being placed ends too.
		P.health.position = { point = 'TOP', element = 'Name', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		P.name.position = { point = 'TOP', element = 'Health', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		ok, res = validate(option, 'Health')
		eq(ok, true, 'a loop among other parts ends the walk')

		-- Itself.
		ok, res = validate(option, 'Castbar')
		is(ok, res, true, "Can't anchor a frame to itself", 'the part itself')
	end)

	test(client .. ': a text of a plate part, relative to its own part, is a loop; to the unit frame is not', function()
		local st, UF = plate_world(client)
		NP.enemy('nameplate1')
		NP.add('nameplate1')
		local P = UF:GetProfileConfig().nameplate
		local config = P.castbar.time
		local option = st.Config.generators.uf_element_position(1,
			function(k) return config.position[k] end,
			function(k, v) config.position[k] = v end,
			UF:ConfigTarget('nameplate', 'Castbar', 'time'))
		local ok, res = validate(option, '__unitframe')
		is(ok, res, true, true, 'the unit frame')
		ok, res = validate(option, 'Health')
		is(ok, res, true, true, 'Health, which the Castbar sits on')
		-- The Castbar on its own time text would loop (the text is on the Castbar).
		ok, res = validate(option, 'Castbar')
		is(ok, res, true, true, 'the Castbar: the text is anchored to it, nothing anchors it to the text')
		P.castbar.position = { point = 'TOP', element = 'Castbar', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		-- Castbar anchored to itself in config: ends, no hang, no error.
		ok = validate(option, 'Health')
		eq(ok, true, 'a part anchored to itself in config does not hang or error')
	end)

	test(client .. ': with no plate on screen the check passes as before', function()
		local st, UF = plate_world(client)
		local option = editor(st, UF, 'Castbar')
		local ok, res = validate(option, 'Health')
		is(ok, res, true, true, 'no plate: nothing to check against')
	end)

	test(client .. ': no measuring call is made on a plate region during the check', function()
		local st, UF = plate_world(client)
		NP.enemy('nameplate1')
		local frame = NP.add('nameplate1')
		-- The stubs refuse a measuring call from a SaftUI file on a restricted
		-- region (the old walk's GetPoint died on this), so a pass here is proof.
		local ok = pcall(st.ValidateAnchor, st, frame.Castbar, frame.Health)
		eq(ok, true, 'ValidateAnchor on two plate parts does not measure')
		ok = pcall(st.ValidateAnchor, st, frame.Castbar, frame)
		eq(ok, true, 'nor against the plate frame')
	end)
end

test("a plate page's editor targets the lowest plate that draws from the page, an enemy and a friend up in either order", function()
	local st, UF = plate_world('forever')
	NP.enemy('nameplate1')
	NP.friend('nameplate2')
	local enemy, friend = NP.add('nameplate1'), NP.add('nameplate2')
	eq(enemy.base_unit, 'nameplate', 'the enemy draws from the Enemy page')
	eq(friend.base_unit, 'friendlynameplate', 'the friend from the Friendly page')
	eq(UF:GetConfigFrame('nameplate'), enemy, 'Enemy page: the enemy')
	eq(UF:GetConfigFrame('friendlynameplate'), friend, 'Friendly page: the friend, though the enemy has the lower number')
	NP.remove('nameplate1')
	NP.remove('nameplate2')
	UF.nameplates = {}
	NP.friend('nameplate1')
	NP.enemy('nameplate2')
	friend, enemy = NP.add('nameplate1'), NP.add('nameplate2')
	eq(UF:GetConfigFrame('nameplate'), enemy, 'Enemy page: the enemy, though the friend has the lower number')
	eq(UF:GetConfigFrame('friendlynameplate'), friend, 'Friendly page: the friend')
end)

test('with only a friend up, the Enemy page targets that plate (the elements still list)', function()
	local st, UF = plate_world('forever')
	NP.friend('nameplate1')
	local friend = NP.add('nameplate1')
	eq(UF:GetConfigFrame('nameplate'), friend, 'the Enemy page falls back to the plate there is')
end)
