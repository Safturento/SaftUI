-- The durability figure's mover (SaftUI-Misc/durability.lua):
--   - the holder (60 by 75, the figure's own size) is an edit mode mover under
--     Misc, its Edit Mode box hidden, Reset explained by noDefaultReason;
--   - until the player moves it SaftUI moves nothing: the figure stays where
--     Blizzard's container puts it, and the holder follows it;
--   - once a position is saved the figure's top right corner hangs from the
--     holder, anchored to its own parent (the right container, or UIParent once
--     moved in Blizzard's Edit Mode), never to the holder, with the plain widget
--     methods (Edit Mode's overrides never called by SaftUI), and is put back
--     after each of Blizzard's re-places;
--   - nothing is written onto Blizzard's frames or tables;
--   - in combat: put back at once while it isn't protected, and, should it be,
--     left where Blizzard puts it until combat ends, with stub.blocked empty;
--   - with Move the durability figure off, nothing of Blizzard's is touched, and
--     turned off after being on it goes back where Blizzard last put it;
--   - the Durability page and the addon loading after SaftUI.
-- On both clients (the files are the same on both).
--
-- Real: SaftUI-Misc's config.lua, durability.lua and durabilitytooltip.lua (loaded as the game does), Core's helpers and edit
-- mode. Blizzard's figure is fixtures/durability_frame.lua, every frame of it
-- locked.
local st, DF, DUR, profile

-- One UIParent unit per physical pixel; the screen 1000 by 600. The right
-- container is at TOPRIGHT -5, -260: its top right is 995, 340.
local function world(client, build, opts)
	opts = opts or {}
	use_client(client, function()
		stub.screen_width, stub.screen_height = 1000, 600
		stub.installed_addons.Blizzard_DurabilityFrame = true
	end)
	load_core_helpers()
	load_editmode()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua') -- the page's saved fields (st.Config.SavedIn)
	load_saftui('SaftUI-Core/Config/optionsdefault.lua')
	UIParent:SetScale(768 / 600)
	st = SaftUI
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.position then profile.durability.position = opts.position end
	if opts.move == false then profile.durability.move = false end
	DF = load_test_file('misc/fixtures/durability_frame.lua')
	if not opts.late then DF.build(build) end
	if opts.shown then DF.show() end
	if opts.scale then UIParent:SetScale(opts.scale) end
	load_saftui('SaftUI-Misc/durability.lua')
	load_saftui('SaftUI-Misc/durabilitytooltip.lua')
	DUR = st:GetModule('Durability')
	DUR:Enable()
	stub.run_timers()
end

local function clean() eq(#take_errors(), 0, 'no errors') end

local function top_right(frame) return ('%d,%d'):format(frame:GetRight(), frame:GetTop()) end

local function anchored_to(frame)
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	local name = relativeTo and relativeTo:GetName() or 'nil'
	return ('%s %s %s %s,%s'):format(point, name, relativePoint, tostring(x), tostring(y))
end

-- A place for the figure's top right corner: 40 in from the screen's right, 100 down. A new table each time (Position writes into the one it's given).
local function SAVED() return { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -40, y_off = -100 } end

-- The keys of a table, sorted, to compare before and after.
local function keys(t)
	local out = {}
	for key in pairs(t) do out[#out + 1] = tostring(key) end
	table.sort(out)
	return table.concat(out, ',')
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': until the player moves it, the figure stays where Blizzard puts it and the holder follows it', function()
		world(client)
		local holder, frame = DUR.holder, DF.frame
		eq(holder:GetName(), 'SaftUIDurabilityHolder', 'the holder')
		eq(('%d,%d'):format(holder:GetSize()), '60,75', "the figure's size")
		local calls = DF.calls.SetPoint + DF.calls.ClearAllPoints
		DF.show()
		stub.run_timers()
		eq(anchored_to(frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,0', "Blizzard's own anchor, never SaftUI's")
		eq(frame:GetNumPoints(), 1, 'by one point')
		check(frame:GetParent() == DF.container, "still the right container's child")
		eq(DF.calls.SetPoint + DF.calls.ClearAllPoints, calls + 3, 'only the three of Blizzard: its container clears, then its layout clears and sets')
		eq(holder:GetTop(), frame:GetTop(), "the holder at the figure's top")
		eq(top_right(holder), '995,340', "the holder on the figure's top right")
		eq(profile.durability.position, nil, 'nothing saved')

		-- The column above it takes more room: the figure moves, the holder follows.
		DF.above = 50
		DF.manage(-30)
		stub.run_timers()
		eq(top_right(frame), '970,290', "Blizzard's new place")
		eq(top_right(holder), '970,290', 'the holder follows')
		eq(anchored_to(frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,-50', 'still Blizzard\'s anchor')

		check(not frame.Selection:IsShown(), "Blizzard's Edit Mode box hidden")
		frame.Selection:Show()
		check(not frame.Selection:IsShown(), 'and kept hidden when Blizzard shows it')

		local mover = st.EditModeFrames.movers.durability
		check(mover ~= nil and mover.def.frame == holder, 'the holder is an edit mode mover')
		eq(table.concat(mover.def.configPath, '.'), 'Durability.general', 'opening its page')
		eq(st.EditModeFrames:MoverModule(mover), 'Misc', 'under Misc')
		eq(mover.def.getDefaultPosition, nil, 'no default place')
		check(type(mover.def.noDefaultReason) == 'string' and mover.def.noDefaultReason ~= '', 'Reset says why not')
		eq(st.EditModeFrames:IsMoverDisabled(mover), false, 'on')
		eq(st.EditModeFrames:IsMoverHidden(mover), false, 'on screen')
		clean()
	end)

	test(client .. ': hidden, the mover is hidden and the holder stays where it last was', function()
		world(client)
		local mover = st.EditModeFrames.movers.durability
		eq(st.EditModeFrames:IsMoverHidden(mover), true, 'hidden while no gear is damaged')
		local before = top_right(DUR.holder)
		check(DUR.holder:IsShown(), 'the holder shows, so the mover has a footprint')
		DF.show()
		stub.run_timers()
		local shown = top_right(DUR.holder)
		DF.hide()
		stub.run_timers()
		eq(top_right(DUR.holder), shown, "hiding the figure leaves the holder where it was seen")
		eq(st.EditModeFrames:IsMoverHidden(mover), true, 'hidden again')
		check(before ~= nil, 'a footprint from the start')
		clean()
	end)

	test(client .. ': a saved place: the figure hangs from the holder by its parent and is put back after Blizzard re-places it', function()
		world(client, nil, { position = SAVED() })
		local holder, frame = DUR.holder, DF.frame
		eq(top_right(holder), '960,500', 'the holder from the profile')
		DF.show()
		eq(top_right(frame), top_right(holder), "the figure's top right on the holder's")
		eq(anchored_to(frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT -35,160', 'anchored to its parent, not the holder')
		eq(frame:GetNumPoints(), 1, 'by one point')
		check(frame:GetParent() == DF.container, "still the container's child, so its layout still counts it")

		DF.above = 50
		DF.manage(-50)
		eq(top_right(frame), top_right(holder), 'a ManageFramePositions: back on the holder')
		eq(anchored_to(frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 10,160', 'anchored to the container where it is now')

		local calls = DF.calls.SetPoint + DF.calls.ClearAllPoints
		DUR:ApplyHolder()
		eq(DF.calls.SetPoint + DF.calls.ClearAllPoints, calls, "SaftUI never calls Edit Mode's overrides")

		-- A nudge saved in the profile; the figure follows.
		local mover = st.EditModeFrames.movers.durability
		local position = mover.def.getPosition()
		position.x_off = position.x_off - 1
		mover.def.setPosition(position)
		mover.def.apply()
		eq(frame:GetRight(), 959, 'a pixel left')

		DUR:GetConfigTable().args.general.args.position.set({}, 'y_off', -300)
		eq(profile.durability.position.y_off, -300, 'Position saved')
		eq(frame:GetTop(), 300, 'the figure follows Position')

		-- Undo's setPosition(nil) and apply: back at Blizzard's place at once, with no help from Blizzard's layout.
		mover.def.setPosition(nil)
		mover.def.apply()
		eq(profile.durability.position, nil, 'none saved again')
		eq(anchored_to(frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,-50', "Blizzard's own anchor again, unaided")
		stub.run_timers()
		eq(top_right(DUR.holder), top_right(frame), 'and the holder back on the figure')
		clean()
	end)

	test(client .. ': Undo of the first move, and a profile with no position, give the figure back to Blizzard', function()
		world(client)
		DF.show()
		stub.run_timers()
		local mover = st.EditModeFrames.movers.durability
		local blizzard = top_right(DF.frame)
		local position = mover.def.getPosition()
		position.x_off, position.y_off = -40, -100
		mover.def.setPosition(position)
		mover.def.apply()
		eq(top_right(DF.frame), '960,500', 'moved')
		mover.def.setPosition(nil)
		mover.def.apply()
		eq(top_right(DF.frame), blizzard, 'Undo: back where Blizzard has it, at once')
		stub.run_timers()
		eq(top_right(DUR.holder), blizzard, 'the holder with it')

		profile.durability.position = SAVED()
		DUR:UpdateConfig()
		eq(top_right(DF.frame), '960,500', 'a profile with a position')
		profile.durability.position = nil
		DUR:UpdateConfig()
		eq(top_right(DF.frame), blizzard, 'a profile switch to one with none: back where Blizzard has it')
		stub.run_timers()
		eq(top_right(DUR.holder), blizzard, 'the holder with it')
		clean()
	end)

	test(client .. ': a figure shown at load with Move off is left alone; Move on at runtime hides the box; no needless re-anchor', function()
		world(client, nil, { position = SAVED(), move = false, shown = true })
		eq(anchored_to(DF.frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,0', "shown at load, Move off: Blizzard's")
		DUR:PlaceFigure()
		eq(anchored_to(DF.frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,0', 'and a placement call changes nothing')

		DF.frame.Selection:Show()
		profile.durability.move = true
		DUR:UpdateConfig()
		check(not DF.frame.Selection:IsShown(), 'Move turned on at runtime hides the box')
		DF.frame.Selection:Show()
		check(not DF.frame.Selection:IsShown(), 'and keeps it hidden')

		-- An unchanged layout makes no C-level re-anchor.
		local methods = getmetatable(DF.frame).__index
		local set, clear, n = methods.SetPoint, methods.ClearAllPoints, 0
		methods.SetPoint = function(self, ...) if self == DF.frame then n = n + 1 end return set(self, ...) end
		methods.ClearAllPoints = function(self, ...) if self == DF.frame then n = n + 1 end return clear(self, ...) end
		DUR:PlaceFigure()
		DUR:ApplyHolder()
		methods.SetPoint, methods.ClearAllPoints = set, clear
		eq(n, 0, 'already in place: no SetPoint or ClearAllPoints')
		clean()
	end)

	test(client .. ': the following holder is whole pixels at a scale where one unit is not one pixel', function()
		world(client, nil, { scale = 1 })
		DF.show()
		stub.run_timers()
		local x = DUR:GetPosition().x_off
		local pixel = st:GetPixelSize(DUR.holder)
		check(pixel > 1.01, 'a pixel is more than a unit here')
		check(math.abs(x / pixel - math.floor(x / pixel + 0.5)) < 1e-3, 'x_off is a whole number of pixels: ' .. tostring(x))
		clean()
	end)

	test(client .. ': an unmoved figure\'s outline sits on the figure, not the screen margin; a saved place keeps the margin', function()
		world(client)
		DF.show()
		stub.run_timers()
		local left, right = st:GetScreenMargin(DUR.holder)
		eq(right, 5, "the figure is 5 from the screen's right edge: the holder may go that near")
		eq(left, 20, 'the other edges keep the margin')
		eq(DUR.holder:GetRight(), DF.frame:GetRight(), 'the outline on the figure')
		profile.durability.position = SAVED()
		DUR:UpdateConfig()
		eq(select(2, st:GetScreenMargin(DUR.holder)), 20, 'a saved place: the margin again')
		clean()
	end)

	test(client .. ': moved in Blizzard\'s Edit Mode, the figure follows that spot, and a saved place still wins', function()
		world(client, { moved = { point = 'TOPLEFT', relativePoint = 'TOPLEFT', offsetX = 100, offsetY = -100 } })
		DF.show()
		stub.run_timers()
		check(DF.frame:GetParent() == UIParent, 'on UIParent, as Blizzard put it')
		eq(top_right(DF.frame), '160,500', "Blizzard's Edit Mode spot")
		eq(top_right(DUR.holder), '160,500', 'the holder follows it')
		profile.durability.position = SAVED()
		DUR:UpdateConfig()
		eq(top_right(DF.frame), '960,500', 'a saved place is applied')
		eq(anchored_to(DF.frame), 'TOPRIGHT UIParent TOPRIGHT -40,-100', 'anchored to UIParent, its parent')
		DF.apply_layout()
		eq(top_right(DF.frame), '960,500', "and kept after Blizzard's layout apply")
		clean()
	end)

	test(client .. ': nothing is written onto Blizzard\'s frames', function()
		local function snapshot() return { keys(DF.frame), keys(DF.container), keys(DF.frame.Selection) } end
		world(client, nil, { late = true })
		DF.build()
		local before = snapshot()
		stub.loaded_addons.Blizzard_DurabilityFrame = true
		stub.fire_event('ADDON_LOADED', 'Blizzard_DurabilityFrame')
		profile.durability.position = SAVED()
		DUR:UpdateConfig()
		DF.show()
		DF.manage(-20)
		stub.run_timers()
		local after = snapshot()
		for i = 1, 3 do eq(after[i], before[i], 'the same keys, frame ' .. i) end
		clean()
	end)

	test(client .. ': in combat, put back at once; a protected figure waits for the end of combat', function()
		world(client, nil, { position = SAVED() })
		DF.show()
		stub.in_combat, stub.blocked = true, {}
		DF.manage(-50)
		eq(top_right(DF.frame), top_right(DUR.holder), 'not protected: back on the holder in combat')
		eq(#stub.blocked, 0, 'nothing blocked')
		stub.in_combat = false

		world(client, { protected = true }, { position = SAVED() })
		DF.show()
		stub.in_combat, stub.blocked = true, {}
		DF.manage(-60)
		eq(DF.frame:GetRight(), 940, 'protected: where Blizzard put it, in combat')
		eq(#stub.blocked, 0, 'nothing blocked')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(top_right(DF.frame), top_right(DUR.holder), 'back on the holder once combat ends')
		clean()
	end)

	test(client .. ': with Move the durability figure off, SaftUI touches none of it, and turning it off gives it back', function()
		world(client, nil, { position = SAVED(), move = false })
		local calls = DF.calls.SetPoint + DF.calls.ClearAllPoints
		DF.show()
		DF.manage(-30)
		eq(anchored_to(DF.frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,0', "Blizzard's, whatever the saved position says")
		eq(DF.calls.SetPoint + DF.calls.ClearAllPoints, calls + 5, 'only the container layouts')
		DF.frame.Selection:Show()
		check(DF.frame.Selection:IsShown(), "Blizzard's Edit Mode box left to Blizzard")
		eq(st.EditModeFrames:IsMoverDisabled(st.EditModeFrames.movers.durability), true, 'the mover is disabled')

		-- On, then off again: back where Blizzard last put it.
		profile.durability.move = true
		DUR:UpdateConfig()
		eq(top_right(DF.frame), '960,500', 'on: placed')
		profile.durability.move = false
		DUR:UpdateConfig()
		eq(anchored_to(DF.frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,0', "off: where Blizzard last put it")
		DF.manage(-10)
		eq(anchored_to(DF.frame), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 0,0', 'and left alone')
		clean()
	end)
end

test('the Durability page: the settings, then Position', function()
	world('forever')
	load_test_file('lib/options_walk.lua')
	local R = load_test_file('lib/reset_walk.lua')
	local tree = DUR:GetConfigTable()
	R.check_page({ Durability = tree }, 'Durability')
	eq(tree.category, 'Info', 'in the Info group')
	eq(tree.name, 'Durability', 'the page')
	local general = tree.args.general
	eq(general.args.move.type, 'toggle', 'the toggle')
	eq(general.args.move.name, 'Move the durability figure', 'named')
	eq(general.args.position.type, 'position', 'Position')
	for key, option in pairs(general.args) do
		if key ~= 'position' then check(option.order < general.args.position.order, 'Position is after ' .. key) end
	end
	each_option(tree, function(option, path)
		local where = table.concat(path, '.')
		check(option.width == nil, where .. ' has no Ace width')
		if option.type ~= 'group' then
			check(type(option.desc) == 'string' and option.desc ~= '', where .. ' has a desc')
		end
	end)
	eq(general.get({ 'move' }), true, 'on by default')
	general.set({ 'move' }, false)
	eq(profile.durability.move, false, 'writes durability.move')
	check(general.args.position.validate({}, 'frame', 'DurabilityFrame') ~= true, "Position can't be anchored to the figure")
	clean()
end)

test("the durability figure's Position has a mover but no default place: no reset, however far it is moved", function()
	world('forever')
	local OM = st.OptionsModel
	local root = { Durability = DUR:GetConfigTable() }
	local position = root.Durability.args.general.args.position
	local row = { option = position, path = { 'Durability', 'general', 'position' }, type = 'position', key = 'position' }
	eq(OM.DefaultSource(root, row), 'mover', 'the mover is its source')
	position.set({}, 'y_off', -300)
	check(not OM.DefaultDiffers(root, row), "moved: still no icon (the mover's noDefaultReason)")
	clean()
end)

test('the addon loading after SaftUI', function()
	world('forever', nil, { late = true })
	check(DUR.holder == nil, 'nothing until the figure exists')
	eq(DUR:GetConfigTable(), nil, 'and no page')
	DF.build()
	stub.loaded_addons.Blizzard_DurabilityFrame = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_DurabilityFrame')
	check(DUR.holder ~= nil, 'the holder once it loads')
	clean()
end)
