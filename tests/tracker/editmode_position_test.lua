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
local function near(a, b) return math.abs(a - b) <= 0.01 end

local saved_globals
local function stub_edit_mode(client, GetLayouts)
	saved_globals = {
		C_EditMode = _G.C_EditMode,
		system = Enum.EditModeSystem,
		meta = Enum.EditModePresetLayoutsMeta,
	}
	_G.C_EditMode = GetLayouts and { GetLayouts = GetLayouts } or nil
	Enum.EditModeSystem = { ObjectiveTracker = 12 }
	Enum.EditModePresetLayoutsMeta = { NumValues = client == 'forever' and 3 or 2 }
end

local function restore()
	_G.C_EditMode = saved_globals.C_EditMode
	Enum.EditModeSystem = saved_globals.system
	Enum.EditModePresetLayoutsMeta = saved_globals.meta
end

local function presets(client) return client == 'forever' and 3 or 2 end

-- A layouts table whose one saved layout holds the tracker as `tracker` says
-- (nil: no ObjectiveTracker system in it), active (a saved one) unless `preset`.
local function layouts(client, tracker, preset)
	local systems = { { system = 3, anchorInfo = { point = 'TOPLEFT', relativeTo = 'UIParent', relativePoint = 'TOPLEFT', offsetX = 1, offsetY = -1 }, isInDefaultPosition = true } }
	if tracker then
		systems[#systems + 1] = { system = 12, anchorInfo = tracker.anchor, isInDefaultPosition = tracker.default or false, settings = {} }
	end
	return {
		layouts = { { layoutName = 'Mine', layoutType = 1, systems = systems } },
		activeLayout = preset and 1 or presets(client) + 1,
	}
end

local function anchor(point, relativeTo, relativePoint, x, y)
	return { point = point, relativeTo = relativeTo, relativePoint = relativePoint, offsetX = x, offsetY = y }
end

local function build(client, GetLayouts, enabling)
	local st, TR = TW.world({ client = client, on = true, enabling = enabling, before = function()
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

		-- By its top left (a point that needs the tracker's width, 260) and a screen point.
		local st2, TR2 = build(client, function()
			return layouts(client, { anchor = anchor('TOPLEFT', 'UIParent', 'TOPLEFT', 40, -90) })
		end)
		restore()
		local width = UIParent:GetRight() - UIParent:GetLeft()
		check(near(TR2.config.position.x_off, 40 + 260 - width), 'a top left spot is converted by the width: ' .. TR2.config.position.x_off)
		eq(TR2.config.position.y_off, -90, 'and its top is kept')
		eq(TR2.config.position.point, 'TOPRIGHT', 'as the top right form')
		check(near(TR2.holder:GetRight(), UIParent:GetLeft() + 40 + 260), "SaftUI's holder's right edge is where the left-anchored tracker's was")
	end)

	test(client .. ": a tracker not moved, a preset layout, another frame, a point without a known top: Blizzard's default spot", function()
		local cases = {
			['not moved'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120), default = true }) end,
			['a preset layout'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'UIParent', 'TOPRIGHT', -300, -120) }, true) end,
			['no tracker in the layout'] = function() return layouts(client, nil) end,
			['another frame'] = function() return layouts(client, { anchor = anchor('TOPRIGHT', 'MinimapCluster', 'BOTTOMRIGHT', -3, -12) }) end,
			['a centre point'] = function() return layouts(client, { anchor = anchor('CENTER', 'UIParent', 'CENTER', 10, 10) }) end,
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
end
