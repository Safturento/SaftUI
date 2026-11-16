-- Whole-pixel nameplates (SaftUI-Unitframes/nameplates/pixels.lua), the plates'
-- size in UIParent's pixels (UF.PlateDriverSize, nameplates.lua) and the game's
-- scale settings (nameplates/cvars.lua):
--   - every frame and region of SaftUI's on a plate rounds its layout to whole
--     pixels, its textures unsnapped, through SaftUI's own walk, which stops
--     at Blizzard's aura containers and at forbidden frames; nothing of
--     Blizzard's plate is touched; each aura button's backdrop (SaftUI's frame
--     on the container's button) is rounded where it's drawn, on plates only;
--     a config update rounds what it drew anew;
--   - each plate's frame is pinned to UIParent's effective scale, whatever its
--     plate's, on every add and after every scale change (Core's
--     UIScale:OnChanged, not an event of the plates' own), and the plates'
--     size is set again (out of combat; in combat both wait for its end);
--   - the size handed to the game is the config's, in UIParent's pixels: the
--     plate and SaftUI's frame on it are the config's width and height in
--     physical pixels;
--   - the plates' scale settings are 1 and simplified plates off while
--     SaftUI's plates are on, recorded and put back as the friendly ones are;
--   - every sized part of the default plate is an even number of pixels.
--
-- The world is nameplate_world.lua's (see its top): the real unit frame files
-- over oUF's stand-in (fixtures/ouf.lua), whose aura containers make a button
-- when a test asks (container:_AddButton()). The stubs don't lay anything out
-- by pixels (tests/wow/widgets.lua): rounding is checked by what each region
-- was told (stub.state(region).round_layout, snap_to_pixel_grid,
-- texel_snapping_bias), and what the client makes of it is an in-game check.
local NP = load_test_file('unitframes/nameplate_world.lua')
local S = load_test_file('lib/secrets.lua')

-- A world with the plates spawned, in theme where one is given. Returns st,
-- UF, the nameplate's config, and a list that fills with every Blizzard frame
-- the game makes for the plates (each plate, and each pooled UnitFrame with
-- its children), as it makes them.
local function world(client, theme)
	local st, UF = NP.world(client or 'forever')
	if theme then st.config.profile.theme.name = theme end
	st.config.char = {}
	local blizzard = {}
	local lock = stub.on_nameplate_frame
	stub.on_nameplate_frame = function(frame)
		lock(frame)
		blizzard[#blizzard + 1] = frame
	end
	UF:SpawnNameplates()
	return st, UF, UF:GetProfileConfig().nameplate, blizzard
end

-- An enemy on a plate (opts are stub.add_nameplate's). Returns SaftUI's frame on it.
local function enemy(unit, opts)
	stub.units[unit] = { name = 'Kobold', level = 22, reaction = 2, friend = false, attackable = true }
	return NP.add(unit, opts)
end

-- Aura containers a test names, for a container that doesn't answer to its
-- type (the stand-in's containerIsIntrinsic).
local containersByName = setmetatable({}, { __mode = 'k' })

-- region and everything under it, parents first, each as { region, path },
-- stopping at an aura container (not listed; returned second).
local function walk(region, path, out, containers)
	out, containers = out or {}, containers or {}
	if containersByName[region] or region:IsObjectType('AuraContainer') then
		containers[#containers + 1] = region
		return out, containers
	end
	out[#out + 1] = { region = region, path = path }
	if region:IsObjectType('Frame') then
		local function under(i, child)
			walk(child, path .. '>' .. (child:GetName() or (child:GetObjectType() .. i)), out, containers)
		end
		for i, child in ipairs({ region:GetRegions() }) do under(i, child) end
		for i, child in ipairs({ region:GetChildren() }) do under(i, child) end
	end
	return out, containers
end

-- Whether a region is rounded as SaftUI rounds: its layout to whole pixels,
-- and a texture unsnapped with its texel snapping bias at 0.
local function rounded(region)
	local s = stub.state(region)
	if s.round_layout ~= true then return false end
	if region:IsObjectType('Texture') then
		return s.snap_to_pixel_grid == false and s.texel_snapping_bias == 0
	end
	return true
end

-- The paths of the parts under root (walk) that aren't rounded, space-joined.
local function unrounded(root)
	local list = {}
	for _, part in ipairs((walk(root, 'root'))) do
		if not rounded(part.region) then list[#list + 1] = part.path end
	end
	return table.concat(list, ' ')
end

-- How many textures are under root (walk).
local function textures(root)
	local n = 0
	for _, part in ipairs((walk(root, 'root'))) do
		if part.region:IsObjectType('Texture') then n = n + 1 end
	end
	return n
end

local function driver(UF, width, height)
	return table.concat({ UF.PlateDriverSize(width, height) }, 'x')
end
local function size()
	return stub.nameplate_size and table.concat(stub.nameplate_size, 'x')
end

------------------------------------------------------------------ the stubs

test("the stubs: a layout's rounding takes a boolean and is remembered; a widget ignoring its parent's scale has its own", function()
	local st = NP.world('forever')
	local parent = CreateFrame('Frame', nil, UIParent)
	parent:SetScale(0.5)
	local child = CreateFrame('Frame', nil, parent)
	child:SetScale(2)
	local grandchild = CreateFrame('Frame', nil, child)
	local texture = grandchild:CreateTexture()
	check(near(child:GetEffectiveScale(), 768 / stub.screen_height), "the parents' scales multiply")
	eq(child:IsIgnoringParentScale(), false, 'not ignored until set')

	child:SetIgnoreParentScale(true)
	eq(child:IsIgnoringParentScale(), true, 'ignored')
	eq(child:GetEffectiveScale(), 2, 'its own scale')
	eq(grandchild:GetEffectiveScale(), 2, 'and the frames under it build on it')
	eq(texture:GetEffectiveScale(), 2, 'their textures too')
	texture:SetIgnoreParentScale(true)
	texture:SetScale(3)
	eq(texture:GetEffectiveScale(), 3, "a texture ignoring its parent's: its own")

	local text = grandchild:CreateFontString()
	for _, region in ipairs({ child, texture, text }) do
		eq(stub.state(region).round_layout, nil, region:GetObjectType() .. ': not rounded until set')
		region:SetRoundLayoutToNearestPixel(true)
		eq(stub.state(region).round_layout, true, region:GetObjectType() .. ': rounded')
	end
	child:SetRoundLayoutToNearestPixel(false)
	eq(stub.state(child).round_layout, false, 'turned off')
	local ok, err = pcall(child.SetRoundLayoutToNearestPixel, child, nil)
	check(not ok and tostring(err):find('boolean', 1, true), 'nil errors: ' .. tostring(err))
	ok, err = pcall(child.SetRoundLayoutToNearestPixel, child, 1)
	check(not ok, 'a number errors')

	-- Protected functions: refused on a protected frame in combat.
	child.IsProtected = function() return true, true end
	stub.in_combat = true
	child:SetIgnoreParentScale(false)
	child:SetRoundLayoutToNearestPixel(true)
	stub.in_combat = false
	eq(child:IsIgnoringParentScale(), true, 'unchanged in combat')
	eq(stub.state(child).round_layout, false, 'unchanged in combat')
	eq(#stub.blocked, 2, 'both blocked')
	eq(stub.blocked[1][2] .. ',' .. stub.blocked[2][2], 'SetIgnoreParentScale,SetRoundLayoutToNearestPixel', 'named')
end)

------------------------------------------------------------------ rounding

for _, client in ipairs({ 'forever', 'retail' }) do
	for _, theme in ipairs({ 'thick', 'blizzard' }) do
		test(client .. ', ' .. theme .. ": every frame and region of SaftUI's on a plate rounds its layout, textures unsnapped; nothing of Blizzard's", function()
			local st, UF, P, blizzard = world(client, theme)
			local one = enemy('nameplate1')
			local two = enemy('nameplate2')
			-- The target's art made and shown (Blizzard's look).
			stub.nameplate_target = 'nameplate1'
			stub.fire_event('PLAYER_TARGET_CHANGED')

			for _, frame in ipairs({ one, two }) do
				local parts, containers = walk(frame, frame:GetName())
				check(#parts > 20, 'a plate has its many parts: ' .. #parts)
				check(textures(frame) > 5, 'textures among them: ' .. textures(frame))
				eq(unrounded(frame), '', frame:GetName() .. ': every part rounded, textures unsnapped')

				-- The texts sit centred on the 20-tall bar: rounded, an odd font
				-- height can't leave them on a half pixel.
				eq(stub.state(frame.Name).round_layout, true, 'the name rounds')
				eq(stub.state(frame.Health.text).round_layout, true, 'the health text rounds')
				eq(stub.state(UF:PlateTargetArt(frame).texture).round_layout, true, "the target's art rounds")

				-- Blizzard's aura containers, and what's under them, are left alone.
				eq(#containers, 2, 'the buffs and debuffs')
				for _, container in ipairs(containers) do
					eq(stub.state(container).round_layout, nil, 'an aura container is not rounded')
				end
			end

			-- Blizzard's plates: none of their frames is touched.
			check(#blizzard >= 10, "Blizzard's frames for two plates: " .. #blizzard)
			for _, frame in ipairs(blizzard) do
				eq(stub.state(frame).round_layout, nil, "Blizzard's " .. tostring(frame:GetName() or frame:GetObjectType()) .. ' is not rounded')
				for _, region in ipairs({ frame:GetRegions() }) do
					eq(stub.state(region).round_layout, nil, "nor a region of Blizzard's")
				end
			end
			local plate = C_NamePlate.GetNamePlateForUnit('nameplate1')
			eq(stub.state(plate).round_layout, nil, 'NamePlate1')
			local unitFrame = rawget(plate, 'UnitFrame')
			for _, f in ipairs({ unitFrame, rawget(unitFrame, 'WidgetContainer'), rawget(unitFrame, 'SoftTargetFrame') }) do
				eq(stub.state(f).round_layout, nil, "its UnitFrame, WidgetContainer and SoftTargetFrame")
			end
			eq(stub.state(NamePlateDriverFrame).round_layout, nil, 'NamePlateDriverFrame')
			eq(#take_errors(), 0, 'no error')
		end)

		test(client .. ', ' .. theme .. ": a plate's aura buttons round their own backdrops; the container and its buttons are left alone", function()
			local st, UF = world(client, theme)
			local frame = enemy('nameplate1')
			local buff = frame.Buffs:_AddButton()
			local debuff = frame.Debuffs:_AddButton()

			local function checkButtons(when)
				for _, button in ipairs({ buff, debuff }) do
					check(button.backdrop ~= nil, when .. ': the button has its backdrop')
					check(#walk(button.backdrop, 'backdrop') >= 1, when .. ': the backdrop')
					eq(unrounded(button.backdrop), '', when .. ': the backdrop and everything on it round')
					eq(stub.state(button).round_layout, nil, when .. ": Blizzard's button is not rounded")
					for _, key in ipairs({ 'Icon', 'Count', 'Border' }) do
						eq(stub.state(button[key]).round_layout, nil, when .. ': nor its ' .. key)
					end
				end
				eq(stub.state(frame.Buffs).round_layout, nil, when .. ': nor the buffs container')
				eq(stub.state(frame.Debuffs).round_layout, nil, when .. ': nor the debuffs container')
			end
			checkButtons('made')
			-- Thick's dark lines are on it; under Blizzard an aura is bare
			-- (SaftUI-Core/themeart.lua).
			if theme == 'thick' then
				check(textures(buff.backdrop) > 0, 'the backdrop has textures: ' .. textures(buff.backdrop))
			end

			-- The plate walked again on a config update: still left alone.
			UF:UpdateConfig('nameplate')
			checkButtons('after a config update')
			eq(#take_errors(), 0, 'no error')
		end)
	end
end

test("another unit's aura buttons keep the game's layout: only a plate's round", function()
	local st, UF = world('forever')
	local target = NP.ouf:Spawn('target', 'SaftUI_Target')
	check(target.Buffs ~= nil, 'the target has buffs')
	local button = target.Buffs:_AddButton()
	check(button.backdrop ~= nil, 'drawn')
	for _, part in ipairs((walk(button.backdrop, 'backdrop'))) do
		eq(stub.state(part.region).round_layout, nil, part.path .. ' is not rounded')
	end
	eq(#take_errors(), 0, 'no error')
end)

test('a forbidden frame on a plate is skipped, with everything under it', function()
	local st, UF = world('forever')
	local frame = enemy('nameplate1')
	-- As the game does with a forbidden object: addon code can only ask it
	-- whether it's forbidden.
	local forbidden = CreateFrame('Frame', nil, frame)
	local inner = CreateFrame('Frame', nil, forbidden)
	local texture = forbidden:CreateTexture()
	forbidden.IsForbidden = function() return true end
	for _, name in ipairs({ 'SetRoundLayoutToNearestPixel', 'GetRegions', 'GetChildren', 'IsObjectType' }) do
		forbidden[name] = function() error('forbidden: ' .. name, 2) end
	end

	UF.RoundLayout(frame, true)
	eq(stub.state(frame).round_layout, true, "the plate's frame rounds")
	eq(stub.state(frame.Health).round_layout, true, 'and its parts')
	eq(stub.state(forbidden).round_layout, nil, 'the forbidden frame is skipped')
	eq(stub.state(inner).round_layout, nil, 'with its children')
	eq(stub.state(texture).round_layout, nil, 'and its regions')
	eq(#take_errors(), 0, 'no error')
end)

for _, client in ipairs({ 'forever', 'retail' }) do
	for _, switch in ipairs({ { 'thick', 'blizzard' }, { 'blizzard', 'thick' } }) do
		local from, to = switch[1], switch[2]
		test(('%s: rounding is applied again after a config update (%s to %s)'):format(client, from, to), function()
			local st, UF = world(client, from)
			local frame = enemy('nameplate1')
			local button = frame.Debuffs:_AddButton()
			eq(unrounded(frame) .. unrounded(button.backdrop), '', 'all rounded under ' .. from)

			-- The theme switches (Config:UpdateConfig: every drawn frame drawn
			-- again, then the modules updated). The redraw makes the new look's
			-- art: new textures, not rounded yet. Thick's lines go on the aura
			-- button's backdrop too; under Blizzard an aura is bare.
			local plateBefore, auraBefore = textures(frame), textures(button.backdrop)
			st.config.profile.theme.name = to
			st:RedrawThemed()
			check(textures(frame) > plateBefore, "the redraw made the plate's new art")
			if to == 'thick' then
				check(textures(button.backdrop) > auraBefore, "and Thick's lines on the aura button's backdrop")
				check(unrounded(button.backdrop) ~= '', 'the backdrop not rounded before the update')
			end
			check(unrounded(frame) ~= '', 'the plate not rounded before the update')

			UF:UpdateConfig()
			eq(unrounded(frame), '', "the plate's new parts round")
			eq(unrounded(button.backdrop), '', "and the aura button's backdrop's")

			-- One element's update (its Theme changed on the Enemy nameplates page).
			UF:GetProfileConfig().nameplate.castbar.theme = from
			UF:UpdateConfig('nameplate', 'Castbar')
			eq(unrounded(frame), '', 'after an element update too')
			eq(#take_errors(), 0, 'no error')
		end)
	end
end

-- A texture SaftUI made on an aura button: Thick's dark line over the dispel
-- fill (auras.lua's StyleButton), the button's one texture that isn't its
-- Icon or Border.
local function innerLine(button)
	for _, region in ipairs({ button:GetRegions() }) do
		if region:IsObjectType('Texture') and region ~= button.Icon and region ~= button.Border then
			return region
		end
	end
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": an aura container that doesn't answer to its type is still skipped: SaftUI knows its own", function()
		local st, UF = world(client, 'thick')
		NP.ouf.containerIsIntrinsic = true
		local frame = enemy('nameplate1')
		eq(frame.Buffs:IsObjectType('AuraContainer'), false, 'the container answers as a plain frame')
		check(UF.auraContainers[frame.Buffs] and UF.auraContainers[frame.Debuffs], 'SaftUI knows both containers')
		containersByName[frame.Buffs], containersByName[frame.Debuffs] = true, true

		-- With auras secret, the container's buttons refuse an addon's access
		-- (.agents/taint.md, rule 11): a walk reaching one errors.
		local buttons = { frame.Buffs:_AddButton(), frame.Debuffs:_AddButton() }
		for _, button in ipairs(buttons) do
			for _, region in ipairs({ button, button.Icon, button.Border }) do
				region.SetRoundLayoutToNearestPixel = function() error('tainted access to an aura button', 2) end
			end
		end

		UF:UpdateConfig('nameplate')
		eq(#take_errors(), 0, 'no error: nothing of the containers was walked')
		for _, container in ipairs({ frame.Buffs, frame.Debuffs }) do
			eq(stub.state(container).round_layout, nil, 'the container is not rounded')
		end
		for _, button in ipairs(buttons) do
			eq(stub.state(button).round_layout, nil, 'nor its button')
			eq(unrounded(button.backdrop), '', "the button's backdrop rounds, from auras.lua")
		end
		eq(unrounded(frame), '', 'every other part of the plate rounds')
	end)

	test(client .. ": a plate's art drawn after its walk (a theme switch's queues run in any order after combat) rounds", function()
		for _, switch in ipairs({ { 'thick', 'blizzard' }, { 'blizzard', 'thick' } }) do
			local from, to = switch[1], switch[2]
			local st, UF = world(client, from)
			local frame = enemy('nameplate1')
			local button = frame.Debuffs:_AddButton()
			local label = client .. ', ' .. from .. ' to ' .. to

			-- Config:UpdateConfig in combat queues the theme's redraw
			-- (st:RedrawThemed, then ColorsChanged('theme')) and the unit frames'
			-- update apart, and the end of combat runs its queue in no set order:
			-- here the update (with its walk) first, then the redraw.
			-- Blizzard's redraw makes pieces the update's draw didn't (Thick's
			-- lines are all made by the update itself).
			st.config.profile.theme.name = to
			UF:UpdateConfig()
			st:RedrawThemed()
			if to == 'blizzard' then
				check(unrounded(frame) ~= '', label .. ": the redraw's new art isn't rounded yet")
			end
			st:ColorsChanged('theme')
			eq(unrounded(frame), '', label .. ': rounded once the theme has changed')
			-- The re-round's walk stops at the aura container, so it never
			-- reaches the button's backdrop: that one was rounded where the
			-- update drew it (auras.lua's StyleButton). The redraw after it makes
			-- no art there and turns no snapping back on: under Blizzard an aura
			-- is bare (no border or cut to lay again, themeart.lua), and Thick's
			-- lines are made by the first draw, which a redraw paints again
			-- without making new ones or touching their rounding.
			eq(unrounded(button.backdrop), '', label .. ": the aura button's backdrop, rounded by the update, untouched by the redraw")

			-- And in the order Config:UpdateConfig runs them out of combat
			-- (nameplate_theme_test.lua's theme_changed).
			st.config.profile.theme.name = from
			st:RedrawThemed()
			UF:UpdateConfig()
			st:ColorsChanged('theme')
			eq(unrounded(frame) .. unrounded(button.backdrop), '', label .. ': and back again')
			eq(#take_errors(), 0, label .. ': no error')
		end
	end)

	test(client .. ": Thick's inner line on a plate's aura button rounds; on another unit's it doesn't", function()
		local st, UF = world(client, 'thick')
		local frame = enemy('nameplate1')
		local button = frame.Debuffs:_AddButton()
		local inner = innerLine(button)
		check(inner ~= nil, 'the line is made')
		check(rounded(inner), "it rounds, unsnapped: SaftUI made it, though it's on Blizzard's button")
		eq(stub.state(button).round_layout, nil, 'the button itself is not rounded')
		eq(stub.state(button.Icon).round_layout, nil, 'nor its icon')
		eq(stub.state(button.Border).round_layout, nil, 'nor its border')

		-- Made later, by a theme switch to Thick: rounded too.
		st, UF = world(client, 'blizzard')
		frame = enemy('nameplate1')
		button = frame.Debuffs:_AddButton()
		eq(innerLine(button), nil, 'no line under Blizzard')
		st.config.profile.theme.name = 'thick'
		st:RedrawThemed()
		UF:UpdateConfig()
		st:ColorsChanged('theme')
		check(innerLine(button) ~= nil and rounded(innerLine(button)), 'made by the switch, and rounded')

		-- Another unit's: the game's layout.
		local target = NP.ouf:Spawn('target', 'SaftUI_Target')
		local other = target.Debuffs:_AddButton()
		check(innerLine(other) ~= nil, "the target's line is made")
		eq(stub.state(innerLine(other)).round_layout, nil, "the target's is not rounded")
		eq(#take_errors(), 0, 'no error')
	end)
end

------------------------------------------------------------------ the scale

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": the plate frame is pinned to UIParent's effective scale, whatever its plate's", function()
		local st, UF = world(client)
		local made = stub.on_nameplate_frame
		stub.on_nameplate_frame = function(f)
			made(f)
			if f:GetName() == 'NamePlate1' then f:SetScale(0.8) end
		end
		local frame = enemy('nameplate1')
		eq(C_NamePlate.GetNamePlateForUnit('nameplate1'):GetEffectiveScale(), 0.8, 'the game scaled the plate')
		eq(frame:IsIgnoringParentScale(), true, "the frame ignores its plate's scale")
		eq(frame:GetEffectiveScale(), UIParent:GetEffectiveScale(), "and has UIParent's")
		eq(frame.Health:GetEffectiveScale(), UIParent:GetEffectiveScale(), 'as do its parts')

		-- Reused, with the plate scaled anew and UIParent's scale changed
		-- without an event: pinned again on the add.
		NP.remove('nameplate1')
		NamePlate1:SetScale(1.2)
		UIParent:SetScale(0.5)
		local again = enemy('nameplate2', { plate = 1 })
		eq(again, frame, 'the same frame')
		eq(frame:GetEffectiveScale(), 0.5, "UIParent's scale at the add")
		eq(#take_errors(), 0, 'no error')
	end)
end

test('a secret scale leaves the frame as it is, and the size as the config has it', function()
	local st, UF = world('forever')
	local restore = S.install()
	UIParent.GetEffectiveScale = function() return S.secret('UI scale') end
	local ok, err = pcall(function()
		local frame = enemy('nameplate1')
		eq(frame:IsIgnoringParentScale(), false, 'not pinned')
		eq(frame:GetScale(), 1, 'its scale untouched')
		eq(driver(UF, 200, 20), '200x20', "the driver's size is the config's")
		eq(#take_errors(), 0, 'no error')
	end)
	UIParent.GetEffectiveScale = nil
	restore()
	check(ok, tostring(err))

	-- A zero scale (WorldFrame's) gives the config's too.
	WorldFrame:SetScale(0)
	eq(driver(UF, 200, 20), '200x20', 'a zero scale')
	WorldFrame:SetScale(1)

	-- Readable again, the next scale change pins it.
	start_uiscale({ mode = 'auto', size = 1 })
	st.UIScale:Apply({ mode = 'auto', size = 1.25 })
	local frame = UF:PlateForUnit('nameplate1')
	eq(frame:GetEffectiveScale(), UIParent:GetEffectiveScale(), 'pinned')
end)

test('a scale change re-pins every plate and re-applies the size, after the pass; in combat both wait for its end (Ruling 5)', function() -- Review Focus 5
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		start_uiscale({ mode = 'auto', size = 1 })
		local order = {}
		st.Config.UpdateConfig = function() order[#order + 1] = 'pass' end
		st.UIScale:OnChanged(function() order[#order + 1] = 'late' end)
		local one, two = enemy('nameplate1'), enemy('nameplate2')
		-- A plate showing no unit now is pinned too, for its next add.
		local three = enemy('nameplate3')
		NP.remove('nameplate3')

		-- The player's choice.
		st.UIScale:Apply({ mode = 'auto', size = 1.25 })
		local scale = UIParent:GetEffectiveScale()
		check(near(scale, 768 / 1080 * 0.75 * 1.25, 1e-9), client .. ': UIParent is at 1.25')
		for _, frame in ipairs({ one, two, three }) do
			eq(frame:GetEffectiveScale(), scale, client .. ': ' .. frame:GetName() .. ' re-pinned')
		end
		eq(size(), driver(UF, 200, 20), client .. ': the size set again')
		eq(order[1], 'pass', client .. ': after the pass')
		check(near(one:GetWidth(), 200) and near(one:GetHeight(), 20), client .. ': still 200 by 20 of its own units')

		-- The display, with the engine setting UIParent over SaftUI's: the check
		-- puts it back and the plates are pinned to that.
		stub.engine_resets_scale = true
		stub.change_display(2560, 1440)
		stub.run_timers()
		check(near(UIParent:GetEffectiveScale(), 768 / 1440 * 1.25, 1e-9), client .. ': SaftUI\'s scale is back')
		eq(one:GetEffectiveScale(), UIParent:GetEffectiveScale(), client .. ': the plate is pinned to it')
		eq(size(), driver(UF, 200, 20), client .. ': and the size follows')
		stub.engine_resets_scale = false

		-- In combat: the engine moves UIParent and nothing of SaftUI's runs; both
		-- the pin and the size wait for the end of it.
		local pinned, inCombat = one:GetEffectiveScale(), size()
		stub.in_combat = true
		stub.engine_set_scale(0.5)
		stub.run_timers()
		eq(one:GetEffectiveScale(), pinned, client .. ': not pinned in combat')
		eq(size(), inCombat, client .. ': the size waits')
		eq(#stub.blocked, 0, client .. ': nothing tried in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		check(near(UIParent:GetEffectiveScale(), 768 / 1440 * 1.25, 1e-9), client .. ': SaftUI\'s scale after combat')
		eq(one:GetEffectiveScale(), UIParent:GetEffectiveScale(), client .. ': pinned once combat ends')
		eq(size(), driver(UF, 200, 20), client .. ': the size set once combat ends')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('the plates no longer hear the screen events themselves', function()
	local source = read_saftui_source('SaftUI-Unitframes/nameplates/pixels.lua')
	check(not source:find('UI_SCALE_CHANGED', 1, true) and not source:find('DISPLAY_SIZE_CHANGED', 1, true), "pixels.lua names neither event")
	check(source:find('UIScale:OnChanged', 1, true), 'it hears the scale interface')
	local st, UF = world('forever')
	local frame = enemy('nameplate1')
	-- No scale runtime started: UIParent moves and the events fire, and nothing re-pins.
	local pinned = frame:GetEffectiveScale()
	UIParent:SetScale(0.6)
	stub.fire_event('UI_SCALE_CHANGED')
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	stub.run_timers()
	eq(frame:GetEffectiveScale(), pinned, 'the plate is not pinned by an event of its own')
end)

test("the plate size is the config's in UIParent pixels", function()
	local st, UF, P = world('forever')
	eq(WorldFrame:GetEffectiveScale(), 1, "WorldFrame's scale")
	eq(UIParent:GetEffectiveScale(), 768 / stub.screen_height, "UIParent's: one unit a pixel")
	local frame = enemy('nameplate1')
	local plate = C_NamePlate.GetNamePlateForUnit('nameplate1')
	check(near(stub.nameplate_size[1], 200 * 768 / stub.screen_height) and near(stub.nameplate_size[2], 20 * 768 / stub.screen_height),
		'the size in WorldFrame units: ' .. size())

	-- In physical pixels: a unit times its effective scale is 768ths of the
	-- screen's height.
	local function pixels(region, side)
		return side * region:GetEffectiveScale() * stub.screen_height / 768
	end
	local function checkPixels(when)
		check(near(pixels(frame, frame:GetWidth()), 200) and near(pixels(frame, frame:GetHeight()), 20),
			when .. ": SaftUI's frame is 200 by 20 pixels")
		check(near(pixels(plate, plate:GetWidth()), 200) and near(pixels(plate, plate:GetHeight()), 20),
			when .. ': and so is the plate, where the game takes clicks')
	end
	checkPixels('WorldFrame at 1')

	-- WorldFrame at another scale: the same pixels.
	WorldFrame:SetScale(1.25)
	UF:ApplyPlateSize()
	checkPixels('WorldFrame at 1.25')

	-- The config's own size.
	P.width, P.height = 160, 14
	UF:ApplyPlateSize()
	check(near(pixels(plate, plate:GetWidth()), 160) and near(pixels(plate, plate:GetHeight()), 14), 'the config\'s 160 by 14')
	WorldFrame:SetScale(1)
end)

------------------------------------------------------------------ the game's settings

local MIN, MAX, SELECTED, SIMPLIFIED = 'nameplateMinScale', 'nameplateMaxScale', 'nameplateSelectedScale', 'nameplateSimplifiedTypes'

-- nameplateSimplifiedTypes is a bit array the game keeps as text: a version
-- character, then six bits to a character, each with 0x40 set
-- (CVarCallbackRegistry:SetCVarBitfieldMask, CvarUtil.lua, both clients).
-- '1C' is version '1' with minions and minor mobs simplified (bits 1 and 2:
-- 0x40 + 0x03); '1' alone is nothing simplified, what Blizzard's settings write
-- when every type is unticked.
local SOME_SIMPLIFIED = '1' .. string.char(0x43)

test("the scale settings are 1 and simplified plates off while SaftUI's plates are on, and put back when Nameplates is off", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.cvars[MIN], stub.cvars[MAX], stub.cvars[SELECTED], stub.cvars[SIMPLIFIED] = '0.8', '1', '1.2', SOME_SIMPLIFIED
		local function values()
			return table.concat({ stub.cvars[MIN], stub.cvars[MAX], stub.cvars[SELECTED], stub.cvars[SIMPLIFIED] }, ',')
		end

		UF:ApplyNameplateCVars()
		eq(values(), '1,1,1,1', client .. ": SaftUI's: every scale 1, nothing simplified (the version kept)")
		local record = st.config.char.nameplateCVars
		eq(table.concat({ record[MIN], record[MAX], record[SELECTED], record[SIMPLIFIED] }, ','),
			'0.8,1,1.2,' .. SOME_SIMPLIFIED, client .. ": the user's recorded")
		UF:ApplyNameplateCVars()
		eq(values(), '1,1,1,1', client .. ': applied again: the same')
		eq(st.config.char.nameplateCVars[SIMPLIFIED], SOME_SIMPLIFIED, client .. ': the record unchanged')

		UF:RestoreNameplateCVars()
		eq(values(), '0.8,1,1.2,' .. SOME_SIMPLIFIED, client .. ': put back exactly')
		eq(st.config.char.nameplateCVars, nil, client .. ': the record cleared')

		-- In combat they wait, as the friendly plates do.
		stub.in_combat = true
		UF:ApplyNameplateCVars()
		eq(values(), '0.8,1,1.2,' .. SOME_SIMPLIFIED, client .. ': nothing in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(values(), '1,1,1,1', client .. ': set once combat ends')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('a client without the simplified plates setting skips it', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		stub.cvars[MIN], stub.cvars[MAX], stub.cvars[SELECTED] = '0.8', '1', '1.2'
		UF:ApplyNameplateCVars()
		eq(stub.cvars[SIMPLIFIED], nil, client .. ': still none')
		eq(st.config.char.nameplateCVars[SIMPLIFIED], nil, client .. ': nothing recorded for it')
		eq(stub.cvars[MIN] .. stub.cvars[SELECTED], '11', client .. ': the scales set')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ even sizes

test('every sized part of a plate is an even number of pixels on both sides', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		local frame = enemy('nameplate1')
		local sizes = { plate = { P.width, P.height } }
		for name, element in pairs(frame.elements) do
			local width, height = UF:ElementSize(element)
			if width or height then sizes[name] = { width, height } end
			for i, icon in ipairs(element.icons or {}) do
				sizes[name .. ' icon ' .. i] = { UF:ElementSize(icon) }
			end
		end
		-- The aura areas, laid out by their buttons' size and spacing.
		for _, name in ipairs({ 'Buffs', 'Debuffs' }) do
			sizes[name .. ' area'] = { frame[name]:GetWidth(), frame[name]:GetHeight() }
		end
		for _, name in ipairs({ 'plate', 'Health', 'Castbar', 'Castbar icon 1', 'Buffs', 'Debuffs', 'Buffs area',
				'Debuffs area', 'QuestIndicator', 'RaidTargetIndicator' }) do
			check(sizes[name] ~= nil, client .. ': ' .. name .. ' is sized')
		end
		for name, sides in pairs(sizes) do
			for side = 1, 2 do
				if sides[side] then
					eq(sides[side] % 2, 0, ('%s: %s %s is %s'):format(client, name, side == 1 and 'width' or 'height', tostring(sides[side])))
				end
			end
		end
	end
end)
