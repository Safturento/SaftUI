-- Blizzard's objective tracker while SaftUI's is on (SaftUI-Tracker/blizzard.lua,
-- and the skin's mover standing down, Blizzard_ObjectiveTrackerPosition.lua):
--   - concealed, never hidden: its one TOPRIGHT point on its own parent, its
--     right edge 100 left of UIParent's left, at the y of the spot it would
--     show at; its clamp off; nothing else of it touched;
--   - in place: its top right on the window's (the holder's top for Grow down,
--     the window's top for Grow up), either half of the screen, clamp on;
--   - every call on it is one of the three C methods (taken from the frame's
--     metatable, never Edit Mode's overrides) and the reads the code names;
--     nothing is written onto Blizzard's tables; the fixture's stray list and
--     the overrides' counts stay empty;
--   - Blizzard re-placing it (its container's layout, a layout apply, a snap
--     break, UpdateHeight) is followed by SaftUI putting it back, with one hook
--     of each however often SaftUI sets up or updates;
--   - in combat: put back at once while it isn't protected; a protected one
--     waits for the end of combat, with stub.blocked empty;
--   - the skin's mover standing down while SaftUI's tracker owns it, and
--     behaving as it always did while the switch is off;
--   - the first position: the skin's saved spot converted to a top right
--     anchor when it names another point, a new or reset profile's decided
--     without the modules' order;
--   - a profile switch while concealed; a /reload in each state; the skin still
--     styling Blizzard's tracker; the renames.
-- On both clients, with and without SaftUI-Misc.
--
-- Real: SaftUI-Tracker's files, Core's helpers and edit mode, Misc's where a
-- case asks. Blizzard's tracker is tests/misc/fixtures/objective_tracker.lua,
-- every frame of it locked.
local TW = load_test_file('tracker/tracker_world.lua')

local MISC = { skinning = true, skin = true, otp = true }
local OT, shape_before

-- Every key of Blizzard's tables the tracker owns, and its non-function value:
-- a hook replaces a method on the frame, which isn't a write of a field. SetAlpha
-- is a C method of the frame's metatable, not a field of the frame: the post-hook
-- on it (the fade, Task 12) puts the game's wrapper in a field of that name, the
-- way the hooks on SetPoint, ClearAllPoints and UpdateHeight replace Blizzard's
-- own, so that one key is left out as theirs are by being functions already there,
-- and only when the function is one hooksecurefunc made (stub.hook_wrappers): an
-- addon's own function in that field is a write onto Blizzard's frame and counts.
local function shape()
	local out = {}
	local frames = { tracker = OT.tracker, container = OT.container, header = OT.tracker.Header,
		selection = OT.tracker.Selection, nineslice = OT.tracker.NineSlice }
	for name, module in pairs(OT.modules) do frames[name] = module end
	for label, frame in pairs(frames) do
		local keys = {}
		for key, value in pairs(frame) do
			if type(value) ~= 'function' then
				keys[#keys + 1] = tostring(key) .. '=' .. tostring(value)
			elseif not (key == 'SetAlpha' and stub.hook_wrappers[value]) then
				keys[#keys + 1] = tostring(key)
			end
		end
		table.sort(keys)
		out[label] = table.concat(keys, ' ')
	end
	return out
end

-- A world with the switch on and Blizzard's tracker built. opts are TW.world's
-- (on and blizzard default to true; the screen to 1000 by 600, one unit a
-- pixel); every method called on Blizzard's tracker from the moment SaftUI's
-- tracker enables is recorded (OT.called()).
local function world(opts)
	opts = opts or {}
	if opts.on == nil then opts.on = true end
	if opts.blizzard == nil then opts.blizzard = true end
	opts.screen = opts.screen or { 1000, 600 }
	local enabling = opts.enabling
	opts.enabling = function(st, TR)
		OT = TW.OT
		if OT then
			OT.watch_calls()
			shape_before = shape()
		end
		if enabling then enabling(st, TR) end
	end
	local st, TR = TW.world(opts)
	OT = TW.OT
	-- SaftUI's hooks run inside Blizzard's calls: what they do is SaftUI's.
	if OT then
		local place = TR.PlaceBlizzard
		TR.PlaceBlizzard = function(...) return OT.as_saftui(place, ...) end
	end
	return st, TR
end

local function default_y(st) return st.forever and -275 or -260 end

-- The y a spot is revealed (and concealed) at: its top, kept TR.BLIZZARD_FLOOR
-- above the screen's bottom so Blizzard's tracker keeps room for its modules (its
-- height is its anchor's y down to the column's bottom, 20 at the least).
local function reveal_top(TR, top)
	return math.max(top, UIParent:GetBottom() + TR.BLIZZARD_FLOOR)
end

local function point_of(frame)
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	return point, relativeTo, relativePoint, x, y
end

-- One physical pixel is one unit here, and every offset is rounded to one.
local function near(a, b, tolerance) return math.abs(a - b) <= (tolerance or 0.01) end

-- The tracker concealed: one TOPRIGHT point on its own parent, its right edge
-- 100 left of UIParent's left, its top at top, its clamp off.
local function check_concealed(tracker, top, where)
	eq(tracker:GetNumPoints(), 1, where .. ': one point')
	local point, relativeTo, relativePoint = point_of(tracker)
	eq(point .. ' ' .. relativePoint, 'TOPRIGHT TOPRIGHT', where .. ': by its top right, to its parent\'s')
	check(relativeTo == tracker:GetParent(), where .. ': anchored to its own parent')
	check(near(tracker:GetRight(), UIParent:GetLeft() - 100), where .. ': its right edge 100 left of the screen, not ' .. tostring(tracker:GetRight()))
	if top then check(near(tracker:GetTop(), top), where .. ': at y ' .. top .. ', not ' .. tostring(tracker:GetTop())) end
	eq(tracker:IsClampedToScreen(), false, where .. ': the clamp is off')
end

-- No error, and nothing that Blizzard's tracker must never be given, from
-- SaftUI's code: Edit Mode's overrides and Show weren't called, no size,
-- parent or event call, and none of Blizzard's state-writing Lua.
local function clean(where)
	where = where or ''
	eq(#take_errors(), 0, where .. 'no errors')
	eq(table.concat(OT.stray, ','), '', where .. "SaftUI ran none of the tracker's state-writing methods, sizes, SetParent or Unregister calls")
	local own = {}
	for name, n in pairs(OT.own) do if n > 0 then own[#own + 1] = name .. '=' .. n end end
	eq(table.concat(own, ','), '', where .. "SaftUI called none of Edit Mode's overrides (or Show) on it")
	eq(OT.calls.Show + OT.calls.Hide + OT.calls.SetShown + OT.calls.SetScale, 0, where .. "and Blizzard's own flows never called Show, Hide, SetShown or SetScale either")
	eq(#stub.blocked, 0, where .. 'nothing blocked')
end

for _, client in ipairs({ 'forever', 'retail' }) do
	for _, misc in ipairs({ false, true }) do
		local label = client .. (misc and ', with Misc' or ', without Misc')

		test(label .. ": concealed: its right edge 100 left of the screen, y the spot's, anchored TOPRIGHT to its own parent; clamp off", function()
			local st, TR = world({ client = client, misc = misc and MISC or nil })
			local tracker = OT.tracker
			local top = UIParent:GetTop() + default_y(st)
			check_concealed(tracker, top, 'by default')
			eq(TR:OwnsBlizzard(), true, 'SaftUI owns it')
			eq(TR.blizzardWhere, 'concealed', 'where it is')
			check(tracker:GetParent() == OT.container, 'still the right container\'s child: no reparent')
			check(tracker:IsShown(), 'shown: never hidden')
			eq(tracker:GetAlpha(), 1, 'no alpha')
			eq(tracker:GetScale(), 1, 'no scale')
			check(not tracker.Selection:IsShown(), "Blizzard's Edit Mode box hidden")
			tracker.Selection:Show()
			check(not tracker.Selection:IsShown(), 'and kept hidden when Blizzard shows it')
			-- Blizzard's own height: down to the container's bottom, the y it was given.
			eq(tracker:GetBottom(), OT.container:GetBottom(), 'its bottom on the container\'s: its height is still Blizzard\'s')
			clean()
		end)

		test(label .. ': moved in Blizzard\'s Edit Mode: anchored to UIParent, its own parent', function()
			local st, TR = world({ client = client, misc = misc and MISC or nil,
				blizzard = { moved = { point = 'TOPLEFT', relativePoint = 'TOPLEFT', offsetX = 100, offsetY = -100 } } })
			local tracker = OT.tracker
			check(tracker:GetParent() == UIParent, 'its parent is UIParent')
			-- (a moved tracker has a fixed height, Edit Mode's 800 here, taller than this screen:
			-- its spot is raised to the screen's top, where the game's clamp would put it)
			check_concealed(tracker, UIParent:GetTop(), 'moved')
			clean()
		end)

		test(label .. ": in place: its top right on the window's, for Grow down and up, both screen halves; clamp on", function()
			local st, TR = world({ client = client, misc = misc and MISC or nil })
			local tracker = OT.tracker
			local halves = {
				right = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -40, y_off = -90 },
				left = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 },
			}
			for _, half in ipairs({ 'right', 'left' }) do
				for _, grow in ipairs({ 'down', 'up' }) do
					local where = half .. ', Grow ' .. grow
					TR.config.position = halves[half]
					TR.config.grow = grow
					TR:UpdateConfig()
					TR:SetContentHeight(100)
					TR:PlaceBlizzard('place')
					eq(TR.blizzardWhere, 'place', where .. ': where it is')
					eq(tracker:GetNumPoints(), 1, where .. ': one point')
					local point, relativeTo, relativePoint = point_of(tracker)
					eq(point .. ' ' .. relativePoint, 'TOPRIGHT TOPRIGHT', where .. ': by its top right')
					check(relativeTo == tracker:GetParent(), where .. ': to its own parent')
					check(near(tracker:GetRight(), TR.window:GetRight()), where .. ': its right on the window\'s')
					check(near(tracker:GetTop(), reveal_top(TR, TR.window:GetTop())), where .. ': its top on the window\'s, or the floor when the window is lower')
					if grow == 'down' then
						check(near(tracker:GetTop(), TR.holder:GetTop()), where .. ': the holder\'s top')
					else
						check(not near(TR.window:GetTop(), TR.holder:GetTop()), where .. ': (the window is shorter than the holder, so the tops differ)')
					end
					eq(tracker:IsClampedToScreen(), true, where .. ': the clamp is back on')
					-- And concealed again: the spot's y, off the left.
					TR:PlaceBlizzard('concealed')
					check_concealed(tracker, reveal_top(TR, TR.window:GetTop()), where .. ' concealed')
					TR:PlaceBlizzard('place')
				end
			end
			clean()
		end)

		test(label .. ": beside: 12 out on the side nearer the middle (top right on the left of SaftUI's, top left on its right), clamp on, the C methods only", function()
			local st, TR = world({ client = client, misc = misc and MISC or nil })
			local tracker = OT.tracker
			local halves = {
				right = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -40, y_off = -90 },
				left = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 },
			}
			for _, half in ipairs({ 'right', 'left' }) do
				for _, grow in ipairs({ 'down', 'up' }) do
					local where = half .. ', Grow ' .. grow
					TR.config.position = halves[half]
					TR.config.grow = grow
					TR.config.height = 300
					TR:UpdateConfig()
					TR:SetContentHeight(100)
					OT.watch_calls()
					TR:PlaceBlizzard('beside')
					eq(TR.blizzardWhere, 'beside', where .. ': where it is')
					eq(tracker:GetNumPoints(), 1, where .. ': one point')
					local point, relativeTo, relativePoint = point_of(tracker)
					check(relativeTo == tracker:GetParent(), where .. ': to its own parent')
					if half == 'right' then
						eq(point .. ' ' .. relativePoint, 'TOPRIGHT TOPRIGHT', where .. ': by its top right, on the left of SaftUI\'s')
						check(near(tracker:GetRight(), TR.holder:GetLeft() - 12), where .. ': 12 left of the holder: ' .. tracker:GetRight() .. ' vs ' .. TR.holder:GetLeft())
					else
						eq(point .. ' ' .. relativePoint, 'TOPLEFT TOPLEFT', where .. ': by its top left, on the right of SaftUI\'s')
						check(near(tracker:GetLeft(), TR.holder:GetRight() + 12), where .. ': 12 right of the holder: ' .. tracker:GetLeft() .. ' vs ' .. TR.holder:GetRight())
					end
					check(near(tracker:GetTop(), reveal_top(TR, TR.holder:GetTop())), where .. ': level with the holder\'s top')
					eq(tracker:IsClampedToScreen(), true, where .. ': the clamp is on')
					-- Only the three C methods and the reads.
					for name in OT.called():gmatch('[^,]+') do
						check(name:find('^tracker:ClearAllPoints$') or name:find('^tracker:SetPoint$') or name:find('^tracker:SetClampedToScreen$')
							or name:find('^tracker:Get') or name:find('^tracker:Is'), where .. ': ' .. name .. ' is on the list')
					end
					-- Concealed from beside: the holder's top (Ruling 29), off the left.
					TR.config.blizzard.mode = 'beside'
					TR:PlaceBlizzard('concealed')
					check_concealed(tracker, reveal_top(TR, TR.holder:GetTop()), where .. ' concealed in Beside mode')
					TR.config.blizzard.mode = 'place'
				end
			end
			clean()
		end)

		test(label .. ": beside: past the item column and its 4 on the side it sits", function()
			local st, TR = world({ client = client, misc = misc and MISC or nil })
			local tracker = OT.tracker
			TR.config.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -40, y_off = -90 }
			TR:UpdateConfig()
			-- A column (stubbed here: the item layer is items_test's, handover_test.lua has the whole flow).
			TR.ColumnWidth = function() return 24 end
			TR:PlaceBlizzard('beside')
			check(near(tracker:GetRight(), TR.holder:GetLeft() - 12 - 24 - 4), 'on the left: 12 + the column + 4 out, not ' .. tracker:GetRight())
			TR.config.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 }
			TR:UpdateConfig()
			TR:PlaceBlizzard('beside')
			check(near(tracker:GetLeft(), TR.holder:GetRight() + 12 + 24 + 4), 'on the right: the same past the column, not ' .. tracker:GetLeft())
			clean()
		end)

		test(label .. ": Blizzard's re-places (its SetPoint, ClearAllPoints, UpdateHeight through the fixture) put it back", function()
			local st, TR = world({ client = client, misc = misc and MISC or nil })
			local tracker = OT.tracker
			local top = UIParent:GetTop() + default_y(st)
			local count, place = 0, TR.PlaceBlizzard
			TR.PlaceBlizzard = function(self, ...) count = count + 1 return place(self, ...) end
			-- Blizzard's own calls, one at a time (SaftUI's hooks run after each).
			OT.as_blizzard(function() tracker:ClearAllPoints() end)
			eq(count, 1, 'ClearAllPoints: one place')
			check_concealed(tracker, top, 'after ClearAllPoints')
			count = 0
			OT.as_blizzard(function() tracker:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, -5) end)
			eq(count, 1, 'SetPoint: one place')
			check_concealed(tracker, top, 'after SetPoint')
			count = 0
			OT.as_blizzard(function() tracker:UpdateHeight() end)
			eq(count, 1, 'UpdateHeight: one place')
			check_concealed(tracker, top, 'after UpdateHeight')
			-- Blizzard's own flows.
			OT.manage(-50)
			check_concealed(tracker, top, 'after its container is laid out again')
			OT.show()
			check_concealed(tracker, top, 'after it shows in its default position')
			OT.apply_layout()
			check_concealed(tracker, top, 'after a layout apply')
			OT.break_snap()
			check_concealed(tracker, top, 'after a snap break')
			OT.edit_mode_moves({ point = 'TOPLEFT', relativePoint = 'TOPLEFT', offsetX = 200, offsetY = -50 })
			check(tracker:GetParent() == UIParent, 'Blizzard put it on UIParent')
			top = UIParent:GetTop() -- (see the moved case: its 800 high)
			check_concealed(tracker, top, 'after Edit Mode moved it')
			TR.PlaceBlizzard = place

			-- Never stacked: setting up and updating again adds no hook, so one
			-- Blizzard call is still one place (more on that in the hooks case).
			TR:SetupBlizzard()
			TR:SetupBlizzard()
			for _ = 1, 3 do TR:UpdateConfig() end
			TR.PlaceBlizzard = function(self, ...) count = count + 1 return place(self, ...) end
			count = 0
			OT.as_blizzard(function() tracker:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 7, -7) end)
			eq(count, 1, 'still one place for one SetPoint')
			TR.PlaceBlizzard = place
			check_concealed(tracker, top, 'and put back')
			eq(#take_errors(), 0, 'no errors')
			eq(table.concat(OT.stray, ','), '', 'SaftUI ran none of its state-writing methods')
		end)

		test(label .. ': no call when its one point is already that; only the C methods and the named reads; nothing written onto Blizzard\'s tables', function()
			local st, TR = world({ client = client, misc = misc and MISC or nil })
			local tracker = OT.tracker
			local C_METHODS = 'tracker:ClearAllPoints,tracker:SetClampedToScreen,tracker:SetPoint'
			local READS = 'tracker:GetEffectiveScale,tracker:GetNumPoints,tracker:GetParent,tracker:GetPoint,tracker:IsClampedToScreen'
			local function expected(...)
				local parts = {}
				for _, group in ipairs({ ... }) do parts[#parts + 1] = group end
				local list = {}
				for _, group in ipairs(parts) do
					for name in group:gmatch('[^,]+') do list[#list + 1] = name end
				end
				table.sort(list)
				return table.concat(list, ',')
			end
			eq(OT.called(), expected(C_METHODS, READS), 'concealing: the three C methods and the reads, nothing else')

			-- Already there: no write at all.
			OT.watch_calls()
			TR:PlaceBlizzard('concealed')
			TR:UpdateConfig()
			eq(OT.called(), expected(READS), 'placed again where it is: reads only')

			-- Revealing and concealing again: still only those.
			OT.watch_calls()
			TR:PlaceBlizzard('place')
			TR:PlaceBlizzard('place')
			TR:PlaceBlizzard('concealed')
			TR:PlaceBlizzard('concealed')
			-- (revealed, the hover's rectangle reads the tracker's size, the two reads rule 5 allows)
			eq(OT.called(), expected(C_METHODS, READS, 'tracker:GetHeight,tracker:GetWidth'), 'revealing and concealing: the same set and the size')

			-- Blizzard's re-places do the same.
			OT.watch_calls()
			OT.manage(-50)
			OT.as_blizzard(function() tracker:UpdateHeight() end)
			OT.manage(-50)
			eq(OT.called(), expected('tracker:ClearAllPoints,tracker:SetPoint', READS),
				'after Blizzard re-placed it: its two (the clamp was already off)')

			local after = shape()
			for label_, keys in pairs(shape_before) do
				eq(after[label_], keys, label_ .. ': no key written onto it, no value changed')
			end
			clean()
		end)
	end
end

test('Misc loaded and the mover standing down: nothing of Blizzard\'s is called from outside the three C methods and the reads', function()
	-- The skin and the mover ran their own calls at their enable, before SaftUI's
	-- tracker did; from then on, every call on Blizzard's tracker is the
	-- tracker's or Blizzard's. Edit mode and the page too.
	local st, TR = world({ misc = MISC })
	local EM = st.EditModeFrames
	OT.watch_calls()
	local OTP = TW.OTP
	OTP:ApplyHolder()
	OTP:PlaceTracker()
	OTP:KeepInMargin()
	OTP:UpdateFootprint()
	OTP:CapturePosition()
	OTP:UpdateConfig()
	OTP:GetConfigTable()
	st:UpdateScreenMargin()
	eq(OT.called(), '', 'the skin\'s mover called nothing on Blizzard\'s tracker')
	clean()
end)

test("the skin's mover stands down while owned: no SetPointDirect of its own, its mover disabled, Position disabled with its reason, its saved position kept", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local saved = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -55, y_off = -66 }
		local st, TR = world({ client = client, misc = MISC, before = function(st)
			st.config.profile.objectivetracker.position = saved
		end })
		local OTP, tracker = TW.OTP, OT.tracker
		local where = client .. ': '
		-- SaftUI's first position took the skin's saved spot.
		local top = UIParent:GetTop() + saved.y_off
		local profile = st.config.profile
		check(OTP.holder ~= nil, where .. 'the skin\'s holder exists')
		local EM = st.EditModeFrames
		local mover = EM.movers.objectivetracker
		check(mover ~= nil, where .. 'the skin\'s mover is registered')
		eq(EM:IsMoverDisabled(mover), true, where .. 'and disabled while SaftUI\'s tracker owns Blizzard\'s')
		eq(mover.def.label, "Blizzard's tracker", where .. 'the mover\'s label')

		-- The holder is placed; the tracker doesn't follow.
		local direct = 0
		local clear, set = st.ClearAllPointsDirect, st.SetPointDirect
		st.ClearAllPointsDirect = function(self, frame, ...) if frame == tracker then direct = direct + 1 end return clear(self, frame, ...) end
		st.SetPointDirect = function(self, frame, ...) if frame == tracker then direct = direct + 1 end return set(self, frame, ...) end
		local position = OTP:GetPosition()
		position.x_off = position.x_off - 100
		profile.objectivetracker.position = position
		OTP:ApplyHolder()
		OTP:PlaceTracker()
		OTP:KeepInMargin()
		OT.manage(-50)
		OT.apply_layout()
		eq(direct, 0, where .. 'no SetPointDirect or ClearAllPointsDirect of the skin\'s on the tracker')
		st.ClearAllPointsDirect, st.SetPointDirect = clear, set
		check_concealed(tracker, top, where .. 'it stays concealed')
		eq(profile.objectivetracker.position.x_off, -155, where .. 'the saved position is as the mover set it')
		-- Nudging the skin's holder moves nothing of Blizzard's.
		eq(TR.holder:GetRight(), TR.holder:GetRight(), where .. '(SaftUI\'s holder is its own)')

		-- A new profile with no position: nothing is written for the skin.
		profile.objectivetracker.position = nil
		OTP:UpdateConfig()
		eq(profile.objectivetracker.position, nil, where .. 'a profile with none is not given the tracker\'s spot')

		-- Its page: Position disabled with the reason, the fonts as before.
		local page = OTP:GetConfigTable()
		local position_row = page.args.general.args.position
		eq(position_row.disabled(), true, where .. 'Position is disabled')
		local reason = position_row.disabledDesc
		if type(reason) == 'function' then reason = reason() end
		eq(reason, "SaftUI's tracker is on (Tracker page): Blizzard's tracker shows in its place when it's needed.", where .. 'with its reason')
		eq(page.name, "Blizzard's tracker", where .. 'the page is named for it')
		eq(page.desc, "Blizzard's objective tracker: its fonts, and its place while SaftUI's tracker is off. Its fonts also style it while it fills in for SaftUI's (Tracker page).", where .. 'its desc')
		eq(#take_errors(), 0, where .. 'no errors')
	end
end)

test('the switch off: the skin\'s mover places Blizzard\'s tracker exactly as before, the Tracker module loaded', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = world({ client = client, misc = MISC, on = false })
		local OTP, tracker = TW.OTP, OT.tracker
		local where = client .. ': '
		eq(TR:OwnsBlizzard(), false, where .. 'SaftUI does not own it')
		check(not TR.built and TR.blizzardFrame == nil, where .. 'nothing built, no frame of Blizzard\'s held')
		eq(TW.counts.hooks, 0, where .. 'no hook')
		eq(tracker:GetNumPoints(), 1, where .. 'one point')
		check(near(tracker:GetRight(), OTP.holder:GetRight()) and near(tracker:GetTop(), OTP.holder:GetTop()), where .. 'on the skin\'s holder')
		eq(tracker:IsClampedToScreen(), true, where .. 'its clamp as Blizzard left it')
		-- Blizzard's re-places are put back on the holder.
		OT.manage(-50)
		check(near(tracker:GetRight(), OTP.holder:GetRight()) and near(tracker:GetTop(), OTP.holder:GetTop()), where .. 'put back on the holder')
		-- Its mover, page and nudges work as always.
		local EM = st.EditModeFrames
		local mover = EM.movers.objectivetracker
		eq(EM:IsMoverDisabled(mover), false, where .. 'its mover is not disabled')
		local row = OTP:GetConfigTable().args.general.args.position
		eq(row.disabled(), false, where .. 'Position is not disabled')
		EM:Nudge(mover, 'LEFT', true)
		check(near(tracker:GetRight(), OTP.holder:GetRight()), where .. 'a nudge moves the tracker with its holder')
		check(tracker:GetRight() > 0, where .. 'on screen')
		-- Explicit calls do nothing while SaftUI's tracker is off.
		local before = TW.snapshot(tracker)
		TR:PlaceBlizzard('concealed')
		TR:SetupBlizzard()
		eq(TW.snapshot(tracker), before, where .. 'PlaceBlizzard and SetupBlizzard leave it alone')
		check(tracker:IsClampedToScreen(), where .. 'clamp untouched')
		eq(#take_errors(), 0, where .. 'no errors')
		eq(table.concat(OT.stray, ','), '', where .. 'no stray call')
	end
end)

test('the skin still styles Blizzard\'s tracker while it is concealed', function()
	local st, TR = world({ misc = MISC })
	local skin = st:GetModule('Skinning'):GetModule('Blizzard_ObjectiveTracker')
	local font = st:GetFont(st.config.profile.objectivetracker.font)
	local blocks = OT.layout(OT.modules.QuestObjectiveTracker, {
		{ id = 101, title = 'The First Quest', objectives = { 'Kill 0/8 boars' } },
	})
	eq(blocks[1].HeaderText:GetFontObject(), font, 'the title takes the skin\'s font')
	check(skin:IsActive(), 'the skin is active')
	-- The tracker's own header: Blizzard's banner hidden by the skin.
	check(not OT.tracker.Header.Background:IsShown(), "Blizzard's header banner is hidden by the skin")
	clean()
end)

test("without SaftUI-Misc its own hooks keep it concealed, and Blizzard's tracker loading after SaftUI is set up when it loads", function()
	local st, TR = world({ blizzard = false, before = function() stub.installed_addons.Blizzard_ObjectiveTracker = true end })
	eq(TR:OwnsBlizzard(), false, 'no frame yet, nothing owned')
	TW.OT = load_test_file('misc/fixtures/objective_tracker.lua')
	OT = TW.OT
	OT.build()
	OT.watch_calls()
	local place = TR.PlaceBlizzard
	TR.PlaceBlizzard = function(...) return OT.as_saftui(place, ...) end
	stub.loaded_addons.Blizzard_ObjectiveTracker = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_ObjectiveTracker')
	eq(TR:OwnsBlizzard(), true, 'owned once it exists')
	check_concealed(OT.tracker, UIParent:GetTop() + default_y(st), 'late')
	OT.manage(-50)
	check_concealed(OT.tracker, UIParent:GetTop() + default_y(st), 'late, after Blizzard re-placed it')
	clean('late: ')
end)

------------------------------------------------------------------ combat and /reload

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': concealed at once after a /reload in combat, stub.blocked empty', function()
		for _, misc in ipairs({ false, true }) do
			local st = world({ client = client, misc = misc and MISC or nil, combat = true })
			check_concealed(OT.tracker, UIParent:GetTop() + default_y(st), 'in combat, misc ' .. tostring(misc))
			-- Blizzard re-placing it in combat is followed in combat.
			OT.manage(-50)
			check_concealed(OT.tracker, UIParent:GetTop() + default_y(st), 'after a re-place in combat')
			clean()
		end
	end)

	test(client .. ': a tracker the game counts as protected waits for the end of combat, nothing blocked', function()
		local st, TR = world({ client = client, blizzard = { protected = true }, combat = true })
		local tracker = OT.tracker
		local where = UIParent:GetRight()
		check(not near(tracker:GetRight(), UIParent:GetLeft() - 100), 'still where Blizzard put it')
		eq(#stub.blocked, 0, 'no protected call was made')
		eq(tracker:IsClampedToScreen(), true, 'its clamp untouched')
		OT.manage(-50)
		eq(#stub.blocked, 0, 'a re-place in combat: no protected call')
		TW.combat(false)
		check_concealed(tracker, UIParent:GetTop() + default_y(st), 'after combat')
		-- Revealing in combat waits too, and the last word wins.
		TW.combat(true)
		TR:PlaceBlizzard('place')
		eq(#stub.blocked, 0, 'revealing in combat: no protected call')
		check(near(tracker:GetRight(), UIParent:GetLeft() - 100), 'not moved in combat')
		TW.combat(false)
		check(near(tracker:GetRight(), TR.window:GetRight()) and near(tracker:GetTop(), TR.window:GetTop()), 'in place after combat')
		eq(tracker:IsClampedToScreen(), true, 'clamp on')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ': revealing and concealing in combat, unprotected: at once', function()
		local st, TR = world({ client = client })
		local tracker = OT.tracker
		TW.combat(true)
		TR:PlaceBlizzard('place')
		check(near(tracker:GetRight(), TR.window:GetRight()), 'in place at once in combat')
		eq(tracker:IsClampedToScreen(), true, 'clamp on')
		TR:PlaceBlizzard('concealed')
		check_concealed(tracker, TR.window:GetTop(), 'concealed again in combat')
		TW.combat(false)
		clean()
	end)

	test(client .. ': a /reload in each state: off, on, on in combat, Blizzard moved in its Edit Mode', function()
		-- Off: nothing of SaftUI's touches it.
		local st, TR = world({ client = client, misc = MISC, on = false })
		eq(OT.called(), '', 'off: SaftUI called nothing on it')
		check(OT.tracker:IsClampedToScreen(), 'off: its clamp')
		check(OT.tracker:GetRight() > 0, 'off: on screen')
		-- On: concealed from the start, whatever the last session did.
		for _, combat in ipairs({ false, true }) do
			local st2 = world({ client = client, misc = MISC, combat = combat })
			check_concealed(OT.tracker, UIParent:GetTop() + default_y(st2), 'on, combat ' .. tostring(combat))
			eq(st2.config.profile.objectivetracker.position, nil, 'the skin\'s saved position untouched')
			clean()
		end
		-- Moved in Blizzard's Edit Mode (its layout puts it at its saved spot first).
		local st3 = world({ client = client, misc = MISC, blizzard = { moved = { point = 'TOPLEFT', relativePoint = 'TOPLEFT', offsetX = 100, offsetY = -100 } } })
		check_concealed(OT.tracker, UIParent:GetTop(), 'moved')
		eq(st3.config.profile.objectivetracker.position, nil, 'the skin saved nothing of the tracker\'s Edit Mode spot')
		clean()
	end)
end

------------------------------------------------------------------ profile

test('a profile switch while concealed: the same one point, no skin move, a first position for a profile with none, collapsed groups kept', function()
	for _, order in ipairs({ 'skin first', 'tracker first' }) do
		local st, TR = world({ misc = MISC })
		local OTP, tracker = TW.OTP, OT.tracker
		local profile = st.config.profile
		TR:CharData().zones['Elwynn Forest'] = true
		TR:CharData().collapsed = true
		local before = TW.snapshot(tracker)
		OT.watch_calls()
		-- A new profile: nothing saved for either module.
		profile.tracker.position = nil
		profile.objectivetracker.position = nil
		if order == 'skin first' then
			OTP:UpdateConfig()
			TR:UpdateConfig()
		else
			TR:UpdateConfig()
			OTP:UpdateConfig()
		end
		eq(TW.snapshot(tracker), before, order .. ': the same one point')
		eq(OT.called():find('SetPoint', 1, true), nil, order .. ': nothing written: not even a re-place')
		eq(profile.objectivetracker.position, nil, order .. ': the skin saved no position of the tracker\'s')
		local position = profile.tracker.position
		check(position ~= nil, order .. ': a profile with none gets its first position')
		eq(position.point .. position.x_off .. ',' .. position.y_off, 'TOPRIGHT-20,' .. default_y(st), order .. ": Blizzard's default spot")
		eq(TR:CharData().zones['Elwynn Forest'], true, order .. ': collapsed groups kept')
		eq(TR:CharData().collapsed, true, order .. ': and the whole tracker')

		-- A profile with another position: SaftUI's holder moves, Blizzard's tracker follows by its y.
		profile.tracker.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -300, y_off = -50 }
		if order == 'skin first' then
			OTP:UpdateConfig()
			TR:UpdateConfig()
		else
			TR:UpdateConfig()
			OTP:UpdateConfig()
		end
		check_concealed(tracker, UIParent:GetTop() - 50, order .. ': another profile, still concealed at its y')
		clean(order .. ': ')
	end
end)

test('a profile reset while on: the first position is the skin\'s saved spot or the default, whatever the modules\' order', function()
	for _, order in ipairs({ 'skin first', 'tracker first' }) do
		for _, skin_has in ipairs({ false, true }) do
			local st, TR = world({ misc = MISC })
			local OTP = TW.OTP
			local profile = st.config.profile
			-- A reset clears both modules' positions; the skin's own may come back with the profile.
			profile.tracker.position = nil
			profile.objectivetracker.position = skin_has
				and { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 } or nil
			if order == 'skin first' then
				OTP:UpdateConfig()
				TR:UpdateConfig()
			else
				TR:UpdateConfig()
				OTP:UpdateConfig()
			end
			local position = profile.tracker.position
			local where = order .. ', skin ' .. (skin_has and 'has one' or 'has none') .. ': '
			if skin_has then
				eq(position.point .. position.x_off .. ',' .. position.y_off, 'TOPLEFT30,-80', where .. "the skin's spot")
			else
				eq(position.point .. position.x_off .. ',' .. position.y_off, 'TOPRIGHT-20,' .. default_y(st), where .. 'the default')
				eq(profile.objectivetracker.position, nil, where .. 'and the skin\'s still none')
			end
			clean(where)
		end
	end
end)

test("the first position: a skin's saved point that isn't a top one is converted to a top right anchor from where the skin's holder shows", function()
	local saved = {
		{ point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = -30, y_off = 200 },
		{ point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 40, y_off = -20 },
		{ point = 'LEFT', frame = 'UIParent', rel_point = 'LEFT', x_off = 25, y_off = 60 },
		{ point = 'BOTTOMLEFT', frame = 'UIParent', rel_point = 'BOTTOMLEFT', x_off = 70, y_off = 90 },
		{ point = 'RIGHT', frame = 'UIParent', rel_point = 'RIGHT', x_off = -35, y_off = -15 },
	}
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, position in ipairs(saved) do
			local st, TR = world({ client = client, misc = MISC, before = function(st)
				st.config.profile.objectivetracker.position = position
			end })
			local OTP = TW.OTP
			local where = client .. ' ' .. position.point .. ': '
			local made = st.config.profile.tracker.position
			eq(made.point .. made.frame .. made.rel_point, 'TOPRIGHTUIParentTOPRIGHT', where .. 'a top right anchor')
			check(near(TR.holder:GetRight(), OTP.holder:GetRight()), where .. "SaftUI's holder's right on the skin's holder's, not " .. TR.holder:GetRight() .. ' vs ' .. OTP.holder:GetRight())
			check(near(TR.holder:GetTop(), OTP.holder:GetTop()), where .. "and its top on the skin's holder's, not " .. TR.holder:GetTop() .. ' vs ' .. OTP.holder:GetTop())
			eq(st.config.profile.objectivetracker.position, position, where .. "the skin's own position untouched")
			clean(where)
		end
	end
	-- A top point is kept as it is, even with the holder there.
	local top = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 }
	local st, TR = world({ misc = MISC, before = function(st) st.config.profile.objectivetracker.position = top end })
	local made = st.config.profile.tracker.position
	eq(made.point .. made.x_off .. ',' .. made.y_off, 'TOPLEFT30,-80', 'a top point is copied as it is')
	-- Without the skin's holder (Blizzard's tracker not loaded yet) there is nowhere to read: the default.
	local st2, TR2 = world({ misc = MISC, blizzard = false, before = function(st)
		st.config.profile.objectivetracker.position = saved[1]
	end })
	local made2 = st2.config.profile.tracker.position
	eq(made2.point .. made2.x_off .. ',' .. made2.y_off, 'TOPRIGHT-20,' .. default_y(st2), "no holder to read it from: Blizzard's default spot")
end)

------------------------------------------------------------------ the helper and the seam

test('st:CornerOffset: the offsets that put a frame\'s point at a screen spot, anchored to its parent\'s point; nil for a value it can\'t use', function()
	local st = TW.world({ screen = { 1000, 600 } })
	local s = UIParent:GetEffectiveScale() -- a spot in screen pixels is a UIParent unit times this
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	local function offsets(...)
		local x, y = st:CornerOffset(...)
		return tostring(x) .. ',' .. tostring(y)
	end
	eq(offsets(frame, UIParent, 'TOPRIGHT', 900 * s, 500 * s), '-100,-100', 'top right to top right')
	eq(offsets(frame, UIParent, 'TOPLEFT', 30 * s, 500 * s), '30,-100', 'top left to top left')
	eq(offsets(frame, UIParent, 'BOTTOMRIGHT', 900 * s, 80 * s), '-100,80', 'bottom right to bottom right')
	eq(offsets(frame, UIParent, 'CENTER', 500 * s, 300 * s), '0,0', 'centre to centre')
	eq(offsets(frame, UIParent, 'TOP', 520 * s, 500 * s), '20,-100', 'top to top')
	-- The frame's scale divides the offset.
	frame:SetScale(2)
	eq(offsets(frame, UIParent, 'TOPRIGHT', 900 * s, 500 * s), '-50,-50', "over the frame's effective scale")
	frame:SetScale(1)
	-- Rounded to a pixel (a pixel is a unit here).
	eq(offsets(frame, UIParent, 'TOPRIGHT', 900.4 * s, 500.6 * s), '-100,-99', 'to whole pixels')
	-- Anchored to another frame's point, not UIParent's.
	local parent = CreateFrame('Frame', nil, UIParent)
	parent:SetSize(200, 100)
	parent:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 300, 200)
	eq(offsets(frame, parent, 'TOPRIGHT', 450 * s, 330 * s), '-50,30', "the parent's own corner")
	-- Nil for a zero scale, an unknown point, a missing or secret value.
	local zero = CreateFrame('Frame', nil, UIParent)
	zero.GetEffectiveScale = function() return 0 end
	eq(offsets(zero, UIParent, 'TOPRIGHT', 900 * s, 500 * s), 'nil,nil', 'a zero scale gives nothing')
	eq(offsets(frame, UIParent, 'NOWHERE', 900 * s, 500 * s), 'nil,nil', 'an unknown point gives nothing')
	eq(offsets(frame, UIParent, 'TOPRIGHT', nil, 500 * s), 'nil,nil', 'a missing screen value gives nothing')
	eq(offsets(frame, UIParent, 'TOPRIGHT', 900 * s, nil), 'nil,nil', 'a missing y gives nothing')
	local S = load_test_file('lib/secrets.lua')
	local restore = S.install()
	eq(offsets(frame, UIParent, 'TOPRIGHT', S.secret('x'), 500 * s), 'nil,nil', 'a secret screen value gives nothing')
	local secret_scale = CreateFrame('Frame', nil, UIParent)
	secret_scale.GetEffectiveScale = function() return S.secret('scale') end
	eq(offsets(secret_scale, UIParent, 'TOPRIGHT', 900 * s, 500 * s), 'nil,nil', 'a secret scale gives nothing')
	restore()
	eq(#take_errors(), 0, 'no errors')
end)

test('TR:BlizzardTarget and the seam: where is concealed or place; anything else is left alone', function()
	local st, TR = world({})
	local tracker = OT.tracker
	local parent, point, x, y = TR:BlizzardTarget('concealed')
	check(parent == tracker:GetParent(), 'its own parent')
	eq(point, 'TOPRIGHT', 'by TOPRIGHT')
	eq(type(x) .. type(y), 'numbernumber', 'offsets')
	local _, _, px, py = TR:BlizzardTarget('place')
	check(px ~= x and py == y, 'in place: the same y, another x')
	eq(TR:BlizzardTarget('somewhere'), nil, 'an unknown place has no target')
	local before = TW.snapshot(tracker)
	TR:PlaceBlizzard('somewhere')
	eq(TW.snapshot(tracker), before, 'and places nothing')
	eq(TR.blizzardWhere, 'concealed', 'the last real place is kept')
	eq(TR:OwnsBlizzard(), true, 'owned')
	clean()
end)

------------------------------------------------------------------ the hooks' safety properties

test('the hooks re-apply the current place: a revealed tracker stays revealed when Blizzard re-places it', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = world({ client = client, misc = MISC })
		local tracker = OT.tracker
		TR:PlaceBlizzard('place')
		local function in_place(where)
			eq(tracker:GetNumPoints(), 1, where .. ': one point')
			check(near(tracker:GetRight(), TR.window:GetRight()) and near(tracker:GetTop(), TR.window:GetTop()), where .. ': on the window\'s top right')
			eq(tracker:IsClampedToScreen(), true, where .. ': clamp on')
			eq(TR.blizzardWhere, 'place', where .. ': still the current place')
		end
		in_place(client .. ' revealed')
		OT.manage(-50)
		in_place(client .. ' after its container is laid out')
		OT.apply_layout()
		in_place(client .. ' after a layout apply')
		OT.as_blizzard(function() tracker:UpdateHeight() end)
		in_place(client .. ' after UpdateHeight')
		OT.as_blizzard(function() tracker:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, -5) end)
		in_place(client .. ' after a SetPoint')
		OT.break_snap()
		in_place(client .. ' after a snap break')
		-- And concealing again is the same hooks, the other place.
		TR:PlaceBlizzard('concealed')
		OT.manage(-50)
		check_concealed(tracker, TR.holder:GetTop(), client .. ' concealed again')
		clean()
	end
end)

test('an error inside a hook is reported once, Blizzard\'s call goes on and finishes, and the next re-place conceals', function()
	local st, TR = world({ misc = MISC })
	local tracker = OT.tracker
	local target, failed = TR.BlizzardTarget, false
	TR.BlizzardTarget = function(...)
		if not failed then
			failed = true
			error('a broken hook')
		end
		return target(...)
	end
	local height = OT.container:GetHeight()
	local ok = pcall(OT.manage, -50)
	eq(ok, true, "Blizzard's layout was not stopped by the hook's error")
	local errors = take_errors()
	eq(#errors, 1, 'one error reported')
	check(tostring(errors[1]):find('a broken hook', 1, true) ~= nil, "the hook's error")
	eq(select(4, OT.container:GetPoint(1)), -50, "the column's layout ran to its end: it is where Blizzard put it")
	eq(OT.container:GetHeight(), height, 'and sized')
	TR.BlizzardTarget = target
	OT.manage(-50)
	check_concealed(tracker, TR.holder:GetTop(), 'the next re-place conceals')
	clean()
end)

test("SaftUI's mover (a nudge, a drag) places Blizzard's concealed tracker again: its y follows the holder", function()
	local st, TR = world({ misc = MISC })
	local tracker = OT.tracker
	local EM = st.EditModeFrames
	local mover = EM.movers.tracker
	-- A holder that fits below its spot, or the margin pushes the nudge back up.
	TR.config.height = 200
	TR:UpdateConfig()
	local before = TR.holder:GetTop()
	EM:Nudge(mover, 'DOWN', true)
	check(TR.holder:GetTop() < before, 'the holder moved down')
	check_concealed(tracker, TR.holder:GetTop(), 'a nudge: the concealed y follows')
	local position = mover.def.getPosition()
	position.y_off = position.y_off + 40
	mover.def.setPosition(position)
	mover.def.apply()
	check_concealed(tracker, TR.holder:GetTop(), 'a drag: and again')
	clean()
end)

test('Grow up: the concealed y follows the window as its contents change height', function()
	local st, TR = world({ misc = MISC })
	local tracker = OT.tracker
	TR.config.grow = 'up'
	TR:UpdateConfig()
	for _, height in ipairs({ 100, 300, 60 }) do
		TR:SetContentHeight(height)
		check_concealed(tracker, reveal_top(TR, TR.window:GetTop()), 'content ' .. height)
	end
	clean()
end)

test('no hook stacks: a second enable, a profile switch, a settings toggle and a repeated setup add none', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = world({ client = client, misc = MISC })
		local tracker = OT.tracker
		local fields = { 'SetPoint', 'ClearAllPoints', 'UpdateHeight' }
		local wrappers = {}
		for _, name in ipairs(fields) do wrappers[name] = rawget(tracker, name) end
		TW.count_from_now()
		TR:OnEnable()
		TR:Build()
		TR:SetupBlizzard()
		TR:UpdateConfig()
		-- A profile switch: a new profile with nothing saved, then another.
		st.config.profile.tracker.position = nil
		st.config.profile.objectivetracker.position = nil
		TW.OTP:UpdateConfig()
		TR:UpdateConfig()
		-- Settings of the tracker's page.
		for _, change in ipairs({ { 'grow', 'up' }, { 'grow', 'down' }, { 'width', 300 }, { 'header', false }, { 'header', true } }) do
			TR.config[change[1]] = change[2]
			TR:UpdateConfig()
		end
		eq(TW.counts.hooks, 0, client .. ': no hook added')
		TW.count_stop()
		for _, name in ipairs(fields) do
			check(rawget(tracker, name) == wrappers[name], client .. ': ' .. name .. ' is still the one wrapper')
		end
		-- One Blizzard call is still one place.
		local count, place = 0, TR.PlaceBlizzard
		TR.PlaceBlizzard = function(self, ...) count = count + 1 return place(self, ...) end
		OT.as_blizzard(function() tracker:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 7, -7) end)
		TR.PlaceBlizzard = place
		eq(count, 1, client .. ': one SetPoint, one place')
		clean(client .. ': ')
	end
end)

test('while the switch is off an explicit TR:SetupBlizzard() hooks nothing', function()
	local st, TR = world({ misc = MISC, on = false })
	local tracker = OT.tracker
	local wrappers = { rawget(tracker, 'SetPoint'), rawget(tracker, 'ClearAllPoints'), rawget(tracker, 'UpdateHeight') }
	TR:SetupBlizzard()
	TR:PlaceBlizzard('concealed')
	eq(TR.blizzardFrame, nil, 'no frame held')
	check(rawget(tracker, 'SetPoint') == wrappers[1] and rawget(tracker, 'ClearAllPoints') == wrappers[2]
		and rawget(tracker, 'UpdateHeight') == wrappers[3], 'its three fields untouched')
end)

------------------------------------------------------------------ the first position, from the profile

local SKIN_SPOTS = {
	{ saved = { point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = -30, y_off = 200 }, x = -30, y = -368 },
	{ saved = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 40, y_off = -20 }, x = -330, y = -304 },
	{ saved = { point = 'BOTTOMLEFT', frame = 'UIParent', rel_point = 'BOTTOMLEFT', x_off = 70, y_off = 90 }, x = -670, y = -478 },
	{ saved = { point = 'LEFT', frame = 'UIParent', rel_point = 'LEFT', x_off = 25, y_off = 60 }, x = -715, y = -224 },
	-- a point that differs from its relative point
	{ saved = { point = 'BOTTOM', frame = 'UIParent', rel_point = 'CENTER', x_off = 10, y_off = 5 }, x = -360, y = -263 },
}

test('the first position converted from a non-top point is the same in either module order, after a profile switch, copy and reset', function()
	for _, spot in ipairs(SKIN_SPOTS) do
		for _, how in ipairs({ 'switch', 'copy', 'reset' }) do
			local results = {}
			for _, order in ipairs({ 'skin first', 'tracker first' }) do
				local st, TR = world({ misc = MISC })
				local OTP, EM, profile = TW.OTP, st.EditModeFrames, st.config.profile
				-- The old profile's spot is where both holders are now; the new profile has the skin's saved spot only.
				profile.tracker.position = nil
				local copy = {}
				for k, v in pairs(spot.saved) do copy[k] = v end
				profile.objectivetracker.position = copy
				if how ~= 'copy' then EM:ClearPositions() end
				if order == 'skin first' then
					OTP:UpdateConfig()
					TR:UpdateConfig()
				else
					TR:UpdateConfig()
					OTP:UpdateConfig()
				end
				EM:UpdateConfig()
				local position = profile.tracker.position
				results[order] = position.point .. ' ' .. position.x_off .. ',' .. position.y_off
				eq(results[order], 'TOPRIGHT ' .. spot.x .. ',' .. spot.y, spot.saved.point .. '/' .. how .. '/' .. order .. ': the skin holder\'s top right, from the profile')
				check(near(TR.holder:GetRight(), spot.x + UIParent:GetRight()) and near(TR.holder:GetTop(), spot.y + UIParent:GetTop()),
					spot.saved.point .. '/' .. how .. '/' .. order .. ': and the holder is there')
				check(near(OTP.holder:GetRight(), TR.holder:GetRight()) and near(OTP.holder:GetTop(), TR.holder:GetTop()),
					spot.saved.point .. '/' .. how .. '/' .. order .. ': on the skin holder\'s own, which the player saw')
				eq(profile.objectivetracker.position.point, spot.saved.point, 'the skin\'s saved position is untouched')
				clean()
			end
			eq(results['skin first'], results['tracker first'], spot.saved.point .. '/' .. how .. ': the same in both orders')
		end
	end
end)

test('the first position from a position relative to another frame, or unreadable, is the default spot', function()
	local st, TR = world({ misc = MISC })
	local profile = st.config.profile
	local function first(saved)
		profile.tracker.position = nil
		profile.objectivetracker.position = saved
		TR:UpdateConfig()
		local p = profile.tracker.position
		return p.point .. ' ' .. p.x_off .. ',' .. p.y_off
	end
	local default = 'TOPRIGHT -20,' .. default_y(st)
	eq(first({ point = 'BOTTOMRIGHT', frame = 'MinimapCluster', rel_point = 'BOTTOMRIGHT', x_off = 1, y_off = 2 }), default, 'relative to another frame')
	eq(first({ point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = 'x', y_off = 2 }), default, 'an offset that is no number')
	eq(first({ point = 'NOWHERE', frame = 'UIParent', x_off = 1, y_off = 2 }), default, 'a point that is no point')
	TW.OTP.width = nil
	eq(first({ point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = 1, y_off = 2 }), default, 'a skin that has not set up')
end)
