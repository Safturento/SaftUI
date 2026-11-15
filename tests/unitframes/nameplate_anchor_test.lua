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

-- The check reads the config of the page being edited, not the plate's own:
-- whatever plates are up, the Enemy page checks against the enemy config and
-- the Friendly page against the friendly one (UF.PlatePartAnchors reads the
-- page the editor's target names while validate runs, and not after).
for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the Enemy page checks the enemy config with only friendly plates up', function()
		local st, UF = plate_world(client)
		NP.friend('nameplate1')
		local friend = NP.add('nameplate1')
		eq(friend.base_unit, 'friendlynameplate', 'only a friend is up')
		local option, P = editor(st, UF, 'Castbar')
		local F = UF:GetProfileConfig().friendlynameplate

		-- A loop that is in the enemy config only: Health on the Castbar.
		P.health.position = { point = 'TOP', element = 'Castbar', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		local ok, res = validate(option, 'Health')
		is(ok, res, true, 'Anchor would create a loop', 'the enemy config has Health on the Castbar: refused')
		ok, res = validate(option, 'Name')
		is(ok, res, true, 'Anchor would create a loop', 'and Name, which sits on Health')

		-- A loop in the friendly config only.
		P.health.position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 }
		F.health.position = { point = 'TOP', element = 'Castbar', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		ok, res = validate(option, 'Health')
		is(ok, res, true, true, 'only the friendly config loops: accepted')
		eq(UF.anchorPage, nil, 'the page is not kept after the check')
	end)

	test(client .. ': the Friendly page checks the friendly config with only an enemy up', function()
		local st, UF = plate_world(client)
		NP.enemy('nameplate1')
		NP.add('nameplate1')
		local P = UF:GetProfileConfig().friendlynameplate
		local config = P.castbar
		local option = st.Config.generators.uf_element_position(1,
			function(k) return config.position[k] end,
			function(k, v) config.position[k] = v end,
			UF:ConfigTarget('friendlynameplate', 'Castbar'))
		local E = UF:GetProfileConfig().nameplate
		-- The default Enemy config has Name on Health: the Friendly page's
		-- Castbar relative to Name is no loop there.
		P.health.position = { point = 'TOP', element = 'Name', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		eq(E.name.position.element, 'Health', "the enemy's name is on its bar")
		local ok, res = validate(option, 'Health')
		is(ok, res, true, true, 'Castbar on Health: the friendly Health is under the Name, no loop')
		ok, res = validate(option, 'Name')
		is(ok, res, true, true, 'Castbar on Name: no loop in the friendly config')
		-- The other way: Name on the Castbar in the friendly config.
		P.name.position = { point = 'TOP', element = 'Castbar', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
		ok, res = validate(option, 'Name')
		is(ok, res, true, 'Anchor would create a loop', 'Name on the Castbar in the friendly config: refused')
	end)

	test(client .. ': the page is cleared when the check errors', function()
		local st, UF = plate_world(client)
		NP.friend('nameplate1')
		NP.add('nameplate1')
		local option = editor(st, UF, 'Castbar')
		local validate_anchor = st.ValidateAnchor
		st.ValidateAnchor = function() error('boom') end
		local ok = pcall(option.validate, {}, 'relative_to', 'Health')
		st.ValidateAnchor = validate_anchor
		eq(ok, false, 'the error comes through')
		eq(UF.anchorPage, nil, 'and the page is not kept')
	end)
end

-- The Threat text's config is the Enemy page's on every plate (threat.lua),
-- the Friendly page has none: a part hung on it from the Friendly page is a
-- loop when the Threat text hangs on that part, and the check never writes
-- into a profile (AceDB makes a table for a key it is asked for).
for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the Friendly page refuses Health relative to Threat, with an enemy up and with a friend up', function()
		for _, up in ipairs({ 'enemy', 'friend' }) do
			local st, UF = plate_world(client)
			NP[up]('nameplate1')
			NP.add('nameplate1')
			local P = UF:GetProfileConfig()
			eq(P.nameplate.threat.position.element, 'Health', up .. ': the Threat text hangs on Health')
			local config = P.friendlynameplate.health
			local option = st.Config.generators.uf_element_position(1,
				function(k) return config.position[k] end,
				function(k, v) config.position[k] = v end,
				UF:ConfigTarget('friendlynameplate', 'Health'))
			eq(rawget(P.friendlynameplate, 'threat'), nil, up .. ': no threat table before the check')
			local ok, res = validate(option, 'Threat')
			is(ok, res, true, 'Anchor would create a loop', up .. ': Health on Threat, which hangs on Health: refused')
			eq(rawget(P.friendlynameplate, 'threat'), nil, up .. ': no threat table made on the Friendly page')

			-- The Enemy page refuses it too, and writes nothing either.
			local enemyConfig = P.nameplate.health
			local enemyOption = st.Config.generators.uf_element_position(1,
				function(k) return enemyConfig.position[k] end,
				function(k, v) enemyConfig.position[k] = v end,
				UF:ConfigTarget('nameplate', 'Health'))
			ok, res = validate(enemyOption, 'Threat')
			is(ok, res, true, 'Anchor would create a loop', up .. ': the Enemy page refuses it')
			eq(rawget(P.friendlynameplate, 'threat'), nil, up .. ': still no table made')
		end
	end)
end
