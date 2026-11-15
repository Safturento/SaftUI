-- SaftUI's tracker's first position from Blizzard's Edit Mode layout
-- (SaftUI-Tracker/window.lua, FirstPosition): where the player's tracker was
-- when Blizzard's Edit Mode moved it, read through the C_EditMode API alone
-- (never a field or method of Blizzard's tracker frame), only for a profile with
-- no tracker position yet, and never an error or a move of a saved one.
--
-- C_EditMode and the two Enum tables are stubbed here, not in tests/wow/: the
-- shapes are Gethe/wow-ui-source's EditModeManagerDocumentation.lua and
-- EditModeManagerConstantsDocumentation.lua (the same on both clients): the raw
-- C_EditMode.GetLayouts() returns the SAVED layouts only and `activeLayout` is an
-- index into the preset layouts (2 on retail, 3 on Forever) followed by them.
local TW = load_test_file('tracker/tracker_world.lua')

local function default_y(st) return st.forever and -275 or -260 end
local function near(a, b, tolerance) return math.abs(a - b) <= (tolerance or 0.01) end
local MISC = { skinning = true, skin = true, otp = true }

local saved_globals
local function stub_edit_mode(client, GetLayouts)
	saved_globals = {
		C_EditMode = _G.C_EditMode,
		system = Enum.EditModeSystem,
		meta = Enum.EditModePresetLayoutsMeta,
		setting = Enum.EditModeObjectiveTrackerSetting,
		manager = _G.EditModeManagerFrame,
	}
	_G.C_EditMode = GetLayouts and { GetLayouts = GetLayouts } or nil
	Enum.EditModeSystem = { ObjectiveTracker = 12 }
	Enum.EditModePresetLayoutsMeta = { NumValues = client == 'forever' and 3 or 2 }
	Enum.EditModeObjectiveTrackerSetting = { Height = 0 }
end

local function restore()
	_G.C_EditMode = saved_globals.C_EditMode
	Enum.EditModeSystem = saved_globals.system
	Enum.EditModePresetLayoutsMeta = saved_globals.meta
	Enum.EditModeObjectiveTrackerSetting = saved_globals.setting
	_G.EditModeManagerFrame = saved_globals.manager
end

local function presets(client) return client == 'forever' and 3 or 2 end

-- A layouts table whose one saved layout holds the tracker as `tracker` says
-- (nil: no ObjectiveTracker system in it), active (a saved one) unless `preset`.
local function layouts(client, tracker, preset)
	local systems = { { system = 3, anchorInfo = { point = 'TOPLEFT', relativeTo = 'UIParent', relativePoint = 'TOPLEFT', offsetX = 1, offsetY = -1 }, isInDefaultPosition = true } }
	if tracker then
		systems[#systems + 1] = { system = 12, anchorInfo = tracker.anchor, isInDefaultPosition = tracker.default or false, settings = tracker.settings or {} }
	end
	return {
		layouts = { { layoutName = 'Mine', layoutType = 1, systems = systems } },
		activeLayout = preset and 1 or presets(client) + 1,
	}
end

local function anchor(point, relativeTo, relativePoint, x, y)
	return { point = point, relativeTo = relativeTo, relativePoint = relativePoint, offsetX = x, offsetY = y }
end

local function build(client, GetLayouts, enabling, misc)
	local st, TR = TW.world({ client = client, on = true, enabling = enabling, misc = misc, before = function()
		stub_edit_mode(client, GetLayouts)
	end })
	return st, TR
end

local function made(TR)
	local p = TR.config.position
	return ('%s %s %s %s'):format(p.point, p.rel_point, tostring(p.x_off), tostring(p.y_off))
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": a tracker moved in Blizzard's Edit Mode: the first position is where it was", function()
		local st, TR = build(client, function()
			return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) })
		end)
		restore()
		eq(made(TR), 'TOPRIGHT TOPRIGHT -300 -120', 'the top right corner, from the screen top right')
		eq(#take_errors(), 0, 'no errors')

		-- A top point is copied as it is, whatever the width (the same rule as the skin's saved position).
		local st2, TR2 = build(client, function()
			return layouts(client, { anchor = anchor('TOPLEFT', 'UIParent', 'TOPRIGHT', -400, -90) })
		end)
		restore()
		eq(made(TR2), 'TOPLEFT TOPRIGHT -400 -90', 'a top left anchor kept as it is')
		check(near(TR2.holder:GetLeft(), UIParent:GetRight() - 400), "the holder's left edge is where it was")
		eq(TR2.config.position.frame, 'UIParent', 'by the screen')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ": a tracker anchored by a point that isn't a top one is converted with Edit Mode's own Height", function()
		local function spot(a, settings)
			local st, TR = build(client, function()
				return layouts(client, { anchor = a, settings = settings })
			end)
			restore()
			eq(#take_errors(), 0, 'no errors')
			return TR.config.position
		end
		local H = UIParent:GetTop() - UIParent:GetBottom()
		local W = UIParent:GetRight() - UIParent:GetLeft()
		-- A snap to the screen's right edge alone: RIGHT to RIGHT, Height raw 40 = 800 tall.
		local p = spot(anchor('RIGHT', 'UIParent', 'RIGHT', -5, 30), { { setting = 0, value = 40 } })
		eq(p.point .. p.rel_point, 'TOPRIGHTTOPRIGHT', 'RIGHT: the top right form')
		check(near(p.x_off, -5, 1), 'RIGHT: x ' .. p.x_off)
		check(near(p.y_off, -H / 2 + 30 + 400, 1), 'RIGHT: the top is the centre + offset + half of 800: ' .. p.y_off)
		-- By the bottom right, Height raw 0 = 400.
		p = spot(anchor('BOTTOMRIGHT', 'UIParent', 'BOTTOMRIGHT', -12, 60), { { setting = 0, value = 0 } })
		check(near(p.x_off, -12, 1) and near(p.y_off, 60 + 400 - H, 1), 'BOTTOMRIGHT: ' .. p.x_off .. ',' .. p.y_off)
		-- A raw value past the top is clamped to 1000 (raw 100 = 1400).
		p = spot(anchor('BOTTOMRIGHT', 'UIParent', 'BOTTOMRIGHT', 0, 0), { { setting = 0, value = 100 } })
		check(near(p.y_off, 1000 - H, 1), 'clamped to 1000: ' .. p.y_off)
		-- No Height setting in the layout: 800.
		p = spot(anchor('BOTTOMRIGHT', 'UIParent', 'BOTTOMRIGHT', 0, 0), {})
		check(near(p.y_off, 800 - H, 1), 'no setting: 800: ' .. p.y_off)
		-- CENTER: the width (260) puts its right edge 130 right of the centre.
		p = spot(anchor('CENTER', 'UIParent', 'CENTER', 10, -20), { { setting = 0, value = 40 } })
		check(near(p.x_off, -W / 2 + 10 + 130, 1) and near(p.y_off, -H / 2 - 20 + 400, 1), 'CENTER: ' .. p.x_off .. ',' .. p.y_off)
		-- A point that differs from its relativePoint (a snap under the top's middle by the left): LEFT to CENTER.
		p = spot(anchor('LEFT', 'UIParent', 'CENTER', 50, 0), { { setting = 0, value = 40 } })
		check(near(p.x_off, -W / 2 + 50 + 260, 1) and near(p.y_off, -H / 2 + 400, 1), 'LEFT to CENTER: ' .. p.x_off .. ',' .. p.y_off)
	end)

	test(client .. ": a TOP anchor (the double snap) is copied as it is", function()
		local st, TR = build(client, function()
			return layouts(client, { anchor = anchor('TOP', 'UIParent', 'CENTER', 0, -40) })
		end)
		restore()
		local p = TR.config.position
		eq(p.point .. p.rel_point .. p.x_off .. ',' .. p.y_off, 'TOPCENTER0,-40', 'as it is')
	end)

	test(client .. ": a tracker not moved, a preset layout, another frame, an unknown point: Blizzard's default spot", function()
		local cases = {
			['not moved'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120), default = true }) end,
			['a preset layout'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }, true) end,
			['no tracker in the layout'] = function() return layouts(client, nil) end,
			['another frame'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'MinimapCluster', 'BOTTOMRIGHT', -3, -12) }) end,
			['an unknown point'] = function() return layouts(client, { anchor = anchor('MIDDLE', 'UIParent', 'CENTER', 10, 10) }) end,
			['a number that is not one'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', 'x', nil) }) end,
		}
		for name, GetLayouts in pairs(cases) do
			local st, TR = build(client, GetLayouts)
			restore()
			eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), name)
			eq(#take_errors(), 0, name .. ': no errors')
		end
	end)

	test(client .. ': a client or moment without the API, or an API that errors or answers nothing usable: the default, no error', function()
		local cases = {
			['no C_EditMode'] = false,
			['an error'] = function() error('boom') end,
			['nothing'] = function() return nil end,
			['no layouts'] = function() return { layouts = {}, activeLayout = presets(client) + 1 } end,
			['not a table'] = function() return 5 end,
		}
		for name, GetLayouts in pairs(cases) do
			local st, TR = build(client, GetLayouts or nil)
			restore()
			eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), name)
			eq(#take_errors(), 0, name .. ': no errors')
		end
		-- Enum tables missing (an older client): the same.
		local st, TR = TW.world({ client = client, on = true, before = function()
			_G.C_EditMode = { GetLayouts = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }) end }
		end })
		_G.C_EditMode = nil
		eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), 'no Enum.EditModeSystem')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ": a profile that has a position saved is never moved, at login or when Edit Mode's layouts arrive", function()
		local mine = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 33, y_off = -44 }
		local ready = false
		local function GetLayouts()
			if ready then return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }) end
		end
		local st, TR = build(client, GetLayouts, function(st) st.config.profile.tracker.position = mine end)
		eq(made(TR), 'TOPLEFT TOPLEFT 33 -44', 'saved, at login')
		ready = true
		stub.fire_event('EDIT_MODE_LAYOUTS_UPDATED', layouts(client, nil))
		restore()
		eq(made(TR), 'TOPLEFT TOPLEFT 33 -44', 'and after the layouts arrive')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ": layouts that arrive after the first position was written move it, once, unless the player moved it first", function()
		for _, moved in ipairs({ false, true }) do
			local ready = false
			local function GetLayouts()
				if ready then return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }) end
			end
			local st, TR = build(client, GetLayouts)
			local where = moved and 'the player moved it first: ' or 'untouched: '
			eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), where .. 'the default at login')
			if moved then
				-- The edit mode mover's write, or the Position fields'.
				TR.config.position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -77, y_off = -88 }
			end
			ready = true
			stub.fire_event('EDIT_MODE_LAYOUTS_UPDATED', {})
			if moved then
				eq(made(TR), 'TOPRIGHT TOPRIGHT -77 -88', where .. 'left alone')
			else
				eq(made(TR), 'TOPRIGHT TOPRIGHT -300 -120', where .. "moved to Edit Mode's spot")
				check(near(TR.holder:GetRight(), UIParent:GetRight() - 300) and near(TR.holder:GetTop(), UIParent:GetTop() - 120), "and the holder follows")
				-- A later layout change (the player's switch of layout) does not move it again.
				TR.config.position.x_off = -150
				stub.fire_event('EDIT_MODE_LAYOUTS_UPDATED', {})
				eq(TR.config.position.x_off, -150, 'not again')
			end
			restore()
			eq(#take_errors(), 0, where .. 'no errors')
		end
	end)
	test(client .. ": login order: GetLayouts answers an empty default first (Blizzard's manager has no layouts yet), then the event", function()
		local moved = false
		local function GetLayouts()
			if moved then return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }) end
			return { layouts = {}, activeLayout = 1 } -- looks like a preset being active
		end
		local st, TR = build(client, GetLayouts, function() _G.EditModeManagerFrame = { layoutInfo = nil } end)
		eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), 'the default at login')
		check(TR.layoutsFrame and TR.layoutsFrame:IsEventRegistered('EDIT_MODE_LAYOUTS_UPDATED'), 'the layouts are waited for')
		moved = true
		-- The event fires before Blizzard's own handler has set layoutInfo: the event is the signal.
		stub.fire_event('EDIT_MODE_LAYOUTS_UPDATED', {})
		eq(made(TR), 'TOPRIGHT TOPRIGHT -300 -120', "moved to Edit Mode's spot")
		check(not TR.layoutsFrame:IsEventRegistered('EDIT_MODE_LAYOUTS_UPDATED'), 'and the watch is over')
		restore()
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ": a manager that has applied the layouts, active on a preset: the default, and no watch", function()
		local st, TR = build(client, function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }, true) end,
			function() _G.EditModeManagerFrame = { layoutInfo = {} } end)
		restore()
		eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), 'the default')
		check(not TR.layoutsFrame, 'nothing to wait for')
	end)

	test(client .. ": with Misc's skin: its saved position comes first, then Edit Mode's spot", function()
		local anchored = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }) end
		local st, TR = build(client, anchored, function(st)
			st.config.profile.objectivetracker.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 }
		end, MISC)
		restore()
		eq(made(TR), 'TOPLEFT TOPLEFT 30 -80', "the skin's spot wins over a moved Edit Mode tracker")
		local st2, TR2 = build(client, anchored, nil, MISC)
		restore()
		eq(made(TR2), 'TOPRIGHT TOPRIGHT -300 -120', "no skin position: Edit Mode's spot")
		-- A non-top Edit Mode anchor with the skin loaded converts through its width (260 here: no tracker to read one from).
		local st3, TR3 = build(client, function() return layouts(client, { anchor = anchor('LEFT', 'UIParent', 'LEFT', 40, 0) }) end, nil, MISC)
		restore()
		check(near(TR3.config.position.x_off, 40 + 260 - (UIParent:GetRight() - UIParent:GetLeft()), 1), 'converted by the width')
		eq(#take_errors(), 0, 'no errors')
	end)

	test(client .. ": a profile reset or switch while the watch waits: the new profile's first position is asked again, a saved one never moved", function()
		local moved = false
		local function GetLayouts()
			if moved then return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }) end
		end
		-- A reset: no position again; it is written afresh and the event moves that one.
		local st, TR = build(client, GetLayouts)
		st.config.profile.tracker.position = nil
		TR:UpdateConfig()
		eq(made(TR), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st), 'the reset profile gets a first position')
		moved = true
		stub.fire_event('EDIT_MODE_LAYOUTS_UPDATED', {})
		eq(made(TR), 'TOPRIGHT TOPRIGHT -300 -120', "and it takes Edit Mode's spot")
		-- A switch to a profile with a position saved that equals the default's values: its own table, never moved.
		restore()
		moved = false
		local st2, TR2 = build(client, GetLayouts)
		st2.config.profile.tracker.position = st2:DefaultTrackerPosition()
		TR2:UpdateConfig()
		moved = true
		stub.fire_event('EDIT_MODE_LAYOUTS_UPDATED', {})
		eq(made(TR2), 'TOPRIGHT TOPRIGHT -20 ' .. default_y(st2), "another profile's saved position is left alone")
		restore()
		eq(#take_errors(), 0, 'no errors')
	end)

end
