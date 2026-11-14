-- The objective tracker's mover (SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua):
--   - the holder: the tracker's width and its header's height, placed from the
--     profile at Blizzard's default spot, an edit mode mover, its Edit Mode box
--     hidden;
--   - the tracker hung from it by its top right corner, anchored to its own
--     parent (the right container in Blizzard's default position, UIParent once
--     moved in Blizzard's Edit Mode), never to the holder, with the plain widget
--     methods (Blizzard's Edit Mode overrides never called), so Blizzard's
--     height still reaches its own bottom line;
--   - put back after each of Blizzard's re-places: the right container's layout
--     and ManageRightFrameContainer, a layout apply, a snap break, whose
--     recorded anchor names a frame of Blizzard's;
--   - a nudge saved in the profile and the tracker following, /sui's Position,
--     a profile change;
--   - in combat: put back at once while it isn't protected, and, should it be,
--     left where Blizzard puts it until combat ends, with stub.blocked empty;
--   - the holder going no lower than the tracker's own clamp lets it go, its
--     reach read again after Blizzard's UpdateHeight;
--   - the Objective Tracker page: the fonts and Position, Position last;
--   - the addon loading after SaftUI.
-- On both clients (the tracker sits 15 lower in its container on Forever).
--
-- Real: SaftUI-Misc's config.lua and Blizzard_ObjectiveTrackerPosition.lua,
-- Core's helpers and edit mode. Blizzard's tracker is
-- fixtures/objective_tracker.lua, every frame of it locked.
local st, OT, OTP, profile

-- One UIParent unit per physical pixel; the screen 1000 by 600. The right
-- container is then 300 tall, from 260 under the top to 40 over the bottom.
local function world(client, build, opts)
	opts = opts or {}
	use_client(client, function()
		stub.screen_width, stub.screen_height = 1000, 600
		stub.installed_addons.Blizzard_ObjectiveTracker = true
	end)
	load_core_helpers()
	load_editmode()
	UIParent:SetScale(768 / 600)
	st = SaftUI
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.position then profile.objectivetracker.position = opts.position end
	OT = load_test_file('misc/fixtures/objective_tracker.lua')
	if not opts.late then OT.build(build) end
	if opts.watch then OT.watch_size() end
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTrackerPosition.lua')
	OTP = st:GetModule('ObjectiveTracker')
	OTP:Enable()
end

-- No error, and nothing of Blizzard's state-writing Lua (MarkDirty, Update,
-- SetCollapsed, UpdateHeight) run from SaftUI's code, which would run the
-- tracker's layout tainted (.agents/taint.md rule 5).
local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(table.concat(OT.stray, ','), '', "SaftUI ran none of the tracker's state-writing methods")
end

-- A layout of Blizzard's that has the tracker's top left at 100 across and 100
-- down: its top right on screen is 360, 500.
local MOVED = { point = 'TOPLEFT', relativePoint = 'TOPLEFT', offsetX = 100, offsetY = -100 }

local function top_right(frame) return ('%d,%d'):format(frame:GetRight(), frame:GetTop()) end

local function anchored_to(frame)
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	local name = relativeTo and relativeTo:GetName() or 'nil'
	return ('%s %s %s %s,%s'):format(point, name, relativePoint, tostring(x), tostring(y))
end

local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

local function SetMargin(value)
	profile.misc.clamp_inset = value
	st:UpdateScreenMargin()
end

-- Where Blizzard's default puts the tracker's top: 260 under the screen's top,
-- 15 more on Forever.
local function default_top(client) return client == 'forever' and 600 - 275 or 600 - 260 end

-- The tracker's height in its default position, hung from the default holder:
-- down to the container's bottom (40 over the screen's).
local function default_height(client) return default_top(client) - 40 end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": the tracker hangs from the holder at Blizzard's default spot, its box hidden", function()
		world(client)
		local holder, tracker = OTP.holder, OT.tracker
		eq(holder:GetName(), 'SaftUIObjectiveTrackerHolder', 'the holder')
		eq(('%d,%d'):format(holder:GetSize()), '260,32', "the tracker's width and its header's height")
		eq(top_right(holder), '980,' .. default_top(client), "Blizzard's spot, the screen edge margin in from the right")
		eq(top_right(tracker), top_right(holder), "the tracker's top right on the holder's")
		check(tracker:GetParent() == OT.container, 'still the right container\'s child')
		local offset = client == 'forever' and '-15' or '0'
		eq(anchored_to(tracker), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT -15,' .. offset, 'anchored to its parent, not the holder')
		eq(tracker:GetNumPoints(), 1, 'by one point')
		eq(tracker:GetHeight(), default_height(client), "Blizzard's height: down to the container's bottom")
		eq(tracker:GetBottom(), OT.container:GetBottom(), 'its bottom on the container\'s')

		check(not tracker.Selection:IsShown(), "Blizzard's Edit Mode box hidden")
		tracker.Selection:Show()
		check(not tracker.Selection:IsShown(), 'and kept hidden when Blizzard shows it')

		local mover = st.EditModeFrames.movers.objectivetracker
		check(mover ~= nil and mover.def.frame == holder, 'the holder is an edit mode mover')
		eq(table.concat(mover.def.configPath, '.'), 'ObjectiveTracker.general', 'opening its page')

		local calls = OT.calls.SetPoint + OT.calls.ClearAllPoints
		OTP:ApplyHolder()
		eq(OT.calls.SetPoint + OT.calls.ClearAllPoints, calls, "SaftUI never calls Edit Mode's overrides")
		clean()
	end)

	test(client .. ": Blizzard's re-places are put back; a snap break records a frame of Blizzard's", function()
		world(client, { height = 400 })
		local holder, tracker = OTP.holder, OT.tracker
		-- The holder placed by the user (a position saved), so a snap break
		-- doesn't count as a first load (see the capture tests below).
		profile.objectivetracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT',
			x_off = -20, y_off = -(600 - default_top(client)) }
		OTP:ApplyHolder()
		OT.manage(-50)
		eq(top_right(tracker), top_right(holder), 'ManageRightFrameContainer: back on the holder')
		eq(anchored_to(tracker), 'TOPRIGHT RightManagedFrameContainer TOPRIGHT 30,' .. (client == 'forever' and '-15' or '0'),
			'anchored to the container where it is now')
		OT.show()
		eq(top_right(tracker), top_right(holder), 'showing again: back on the holder')
		OT.apply_layout()
		eq(top_right(tracker), top_right(holder), 'a layout apply: back on the holder')

		OT.break_snap()
		eq(top_right(tracker), top_right(holder), 'a snap break: back on the holder')
		check(OT.recorded.relativeTo == 'RightManagedFrameContainer' or OT.recorded.relativeTo == 'UIParent',
			'the anchor Blizzard records names a frame of its own: ' .. tostring(OT.recorded.relativeTo))

		-- Out of its default position now: on UIParent, Blizzard's Height.
		OT.apply_layout()
		check(tracker:GetParent() == UIParent, 'on UIParent')
		eq(top_right(tracker), top_right(holder), 'back on the holder')
		eq(anchored_to(tracker), 'TOPRIGHT UIParent TOPRIGHT -20,' .. -(600 - default_top(client)), 'anchored to UIParent')
		eq(tracker:GetHeight(), 400, "Blizzard's Height setting")
		clean()
	end)

	test(client .. ": moved in Blizzard's Edit Mode before: first load keeps that spot, saved as the position", function()
		world(client, { moved = MOVED, height = 400 })
		local tracker = OT.tracker
		check(tracker:GetParent() == UIParent, 'on UIParent')
		eq(top_right(tracker), '360,500', "where Blizzard's layout has it: the first load moved nothing")
		eq(top_right(OTP.holder), '360,500', 'the holder there')
		local position = profile.objectivetracker.position
		check(position ~= nil, 'its spot saved as the profile\'s position')
		eq(('%s %s %d,%d'):format(position.point, position.rel_point, position.x_off, position.y_off), 'TOPRIGHT TOPRIGHT -640,-100',
			"as its top right corner on UIParent's")
		eq(tracker:GetHeight(), 400, "Blizzard's Height")
		clean()
	end)

	test(client .. ": in Blizzard's default position nothing is saved: the holder waits at Blizzard's spot", function()
		world(client)
		eq(profile.objectivetracker.position, nil, 'no position saved by loading')
		eq(top_right(OTP.holder), '980,' .. default_top(client), "the holder at Blizzard's default spot")
		stub.run_timers()
		eq(profile.objectivetracker.position, nil, 'and none from the next frame either')
		clean()
	end)

	test(client .. ': a saved position is kept over a tracker moved in Blizzard\'s Edit Mode', function()
		local saved = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 40, y_off = -100 }
		world(client, { moved = MOVED, height = 400 }, { position = saved })
		eq(top_right(OT.tracker), '300,500', 'the tracker on the saved spot (its top left 40 in)')
		eq(profile.objectivetracker.position.x_off, 40, 'the position untouched')
		eq(profile.objectivetracker.position.point, 'TOPLEFT', 'whole')
		clean()
	end)

	test(client .. ': Blizzard moving the tracker after SaftUI loaded: its spot is captured on the next frame', function()
		world(client)
		OT.edit_mode_moves(MOVED)
		eq(top_right(OT.tracker), '360,500', "left where Blizzard's layout put it")
		eq(profile.objectivetracker.position, nil, 'not read yet: Blizzard may still be placing it')
		stub.run_timers()
		eq(top_right(OT.tracker), '360,500', 'still there')
		eq(top_right(OTP.holder), '360,500', 'the holder on it')
		eq(profile.objectivetracker.position.x_off, -640, 'saved')
		clean()
	end)

	test(client .. ': a nudge is saved and the tracker follows; Position and a profile change too', function()
		world(client)
		local mover = st.EditModeFrames.movers.objectivetracker
		st.EditModeFrames:Nudge(mover, 'LEFT')
		eq(profile.objectivetracker.position.x_off, -21, 'the nudge saved')
		eq(top_right(OT.tracker), top_right(OTP.holder), 'the tracker follows')
		eq(OT.tracker:GetRight(), 979, 'a pixel left')

		local general = OTP:GetConfigTable().args.general
		general.args.position.set({}, 'y_off', -300)
		eq(profile.objectivetracker.position.y_off, -300, 'Position saved')
		eq(OT.tracker:GetTop(), 300, 'the tracker follows Position')

		profile.objectivetracker.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 40, y_off = -100 }
		OTP:UpdateConfig()
		eq(('%d,%d'):format(OT.tracker:GetLeft(), OT.tracker:GetTop()), '40,500', 'a profile change places it')
		clean()
	end)

	test(client .. ': in combat, put back at once; a protected tracker waits for the end of combat', function()
		world(client)
		stub.in_combat, stub.blocked = true, {}
		OT.manage(-50)
		eq(top_right(OT.tracker), top_right(OTP.holder), 'not protected: back on the holder in combat')
		eq(#stub.blocked, 0, 'nothing blocked')
		stub.in_combat = false

		world(client, { protected = true })
		stub.in_combat, stub.blocked = true, {}
		OT.manage(-60)
		eq(OT.tracker:GetRight(), 940, "protected: where Blizzard put it, in combat")
		eq(#stub.blocked, 0, 'nothing blocked')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(top_right(OT.tracker), top_right(OTP.holder), 'back on the holder once combat ends')
		clean()
	end)

	test(client .. ': SaftUI reads the tracker\'s size with ignoreRect only, so no OnSizeChanged can run in its call', function()
		world(client, { height = 400 }, { watch = true })
		local reads = OT.size_reads
		OT.manage(-50)
		OT.show()
		OT.break_snap()
		OT.apply_layout()
		SetMargin(0)
		OTP:ApplyHolder()
		OTP:KeepInMargin()
		-- A capture too: Blizzard's layout moves the tracker, nothing saved yet.
		profile.objectivetracker.position = nil
		OT.edit_mode_moves(MOVED)
		stub.run_timers()
		check(profile.objectivetracker.position ~= nil, 'the capture ran')
		local plain = {}
		for name, count in pairs(reads.plain) do plain[#plain + 1] = name .. '=' .. count end
		eq(table.concat(plain, ','), '', "no plain GetWidth, GetHeight or GetSize on the tracker or a module")
		check((reads.ignore.GetWidth or 0) > 0 and (reads.ignore.GetHeight or 0) > 0, 'the reach and Setup read the size with ignoreRect')
		-- ...and still follow Blizzard's height.
		eq(Insets(OTP.holder), '0,0,0,-368', 'the holder\'s reach: a 400 tall tracker 368 below it')
		clean()
	end)

	test(client .. ': a tracker already where it should be is not re-anchored', function()
		world(client)
		local calls = 0
		local clear, set = st.ClearAllPointsDirect, st.SetPointDirect
		st.ClearAllPointsDirect = function(self, frame, ...)
			if frame == OT.tracker then calls = calls + 1 end
			return clear(self, frame, ...)
		end
		st.SetPointDirect = function(self, frame, ...)
			if frame == OT.tracker then calls = calls + 1 end
			return set(self, frame, ...)
		end
		OTP:PlaceTracker()
		OTP:KeepInMargin()
		eq(calls, 0, 'placing it where it is changes nothing')
		-- Blizzard's re-place: cleared, then set to its own spot. Each is put back
		-- (two anchors made) and the UpdateHeight that follows finds it in place.
		OT.manage(-50)
		eq(calls, 4, 'one clear and one set after the clear, and one clear and one set after the set')
		calls = 0
		OTP:KeepInMargin()
		eq(calls, 0, 'and again nothing')
		st.ClearAllPointsDirect, st.SetPointDirect = clear, set
		clean()
	end)

	test(client .. ": the holder goes no lower than the tracker's own clamp lets the tracker go", function()
		world(client, { height = 400 })
		local below = default_height(client) - 32
		eq(Insets(OTP.holder), '-20,20,20,' .. -below, 'the margin, and the tracker reaching ' .. below .. ' below')
		SetMargin(0)
		eq(Insets(OTP.holder), '0,0,0,' .. -below, 'at 0: the tracker reaches the bottom edge and no further')
		SetMargin(20)
		-- Moved: Blizzard's Height, read again after its UpdateHeight.
		OT.break_snap()
		OT.apply_layout()
		eq(Insets(OTP.holder), '-20,20,20,-368', 'a 400 tall tracker: 368 below the holder')
		clean()
	end)
end

-- Profile changes: a profile with no position keeps the spot the tracker was
-- last placed at, whether Blizzard's layout has it moved or not, and the
-- capture never reads that as Blizzard's.
local A = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -100, y_off = -50 }
local function pos(p) return p and ('%s %d,%d'):format(p.point, p.x_off, p.y_off) or 'nil' end
for _, moved in ipairs({ false, true }) do
	for _, how in ipairs({ 'profile change', 'profile reset' }) do
		test(('%s to a profile with no position keeps the spot, layout moved=%s'):format(how, tostring(moved)), function()
			world('forever', moved and { moved = MOVED, height = 400 } or nil)
			stub.run_timers()
			profile.objectivetracker.position = { point = A.point, frame = A.frame, rel_point = A.rel_point, x_off = A.x_off, y_off = A.y_off }
			OTP:UpdateConfig()
			eq(top_right(OT.tracker), '900,550', 'profile A places it')
			profile.objectivetracker.position = nil -- B, or a reset
			OTP:UpdateConfig()
			eq(top_right(OT.tracker), '900,550', 'nothing moved at once')
			eq(top_right(OTP.holder), '900,550', 'the holder with it')
			stub.run_timers()
			eq(top_right(OT.tracker), '900,550', 'nor on the next frame')
			eq(pos(profile.objectivetracker.position), 'TOPRIGHT -100,-50', "kept as B's position, not Blizzard's")
			clean()
		end)
	end
end

test('a nudge before a profile change is the spot the next profile keeps', function()
	world('forever', { moved = MOVED, height = 400 })
	stub.run_timers()
	st.EditModeFrames:Nudge(st.EditModeFrames.movers.objectivetracker, 'LEFT')
	local nudged = top_right(OT.tracker)
	profile.objectivetracker.position = nil
	OTP:UpdateConfig()
	stub.run_timers()
	eq(top_right(OT.tracker), nudged, 'the nudged spot')
	check(profile.objectivetracker.position ~= nil, 'saved')
	clean()
end)

test('a position saved without some keys is filled from the default spot', function()
	world('forever', nil, { position = { x_off = -21 } })
	local position = OTP:GetPosition()
	eq(('%s %s %s %d,%d'):format(position.point, position.frame, position.rel_point, position.x_off, position.y_off),
		'TOPRIGHT UIParent TOPRIGHT -21,-275', 'x_off kept, the rest the default spot')
	check(OTP.holder:GetNumPoints() == 1 and OTP.holder:GetPoint(1) == 'TOPRIGHT', 'the holder is placed')
	clean()
end)

test('the Objective Tracker page: the fonts, then Position', function()
	world('forever')
	load_test_file('lib/options_walk.lua')
	local tree = OTP:GetConfigTable()
	eq(tree.category, 'Info', 'in the Info group')
	eq(tree.name, 'Objective tracker', 'sentence case, as the sidebar shows it')
	local general = tree.args.general
	eq(general.args.font.type, 'select', 'Font')
	eq(general.args.header_font.name, 'Header font', 'Header font')
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
	eq(general.get({ 'font' }), 'normal', 'Font reads objectivetracker.font')
	general.set({ 'header_font' }, 'pixel')
	eq(profile.objectivetracker.header_font, 'pixel', 'Header font writes objectivetracker.header_font')
	check(general.args.font.disabled(), 'the fonts are disabled without the skin')
	eq(general.args.position.get({}, 'point'), 'TOPRIGHT', 'Position reads the profile')
	check(general.args.position.validate({}, 'frame', 'ObjectiveTrackerFrame') ~= true,
		"Position can't be anchored to the tracker")
	clean()
end)

test('the addon loading after SaftUI', function()
	world('forever', nil, { late = true })
	check(OTP.holder == nil, 'nothing until the tracker exists')
	eq(OTP:GetConfigTable(), nil, 'and no page')
	OT.build()
	stub.loaded_addons.Blizzard_ObjectiveTracker = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_ObjectiveTracker')
	check(OTP.holder ~= nil, 'the holder once it loads')
	eq(top_right(OT.tracker), top_right(OTP.holder), 'and the tracker on it')
	clean()
end)
