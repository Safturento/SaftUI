-- A friendly look's own size, the plate size and the click area
-- (SaftUI-Unitframes/nameplates/nameplates.lua's UF:PlacePlateFrame,
-- UF:RestorePlateHitTest, UF:ApplyPlateSize and UF:ApplyPlateConfig;
-- unitframes.lua's UF:PlaceUnitFrame, UF:UpdateUnitFrame, UF:ApplyConfig and
-- UF:RefreshFrameConfig; updaters.lua's UF:UpdateElement):
--   - a plate's frame drawn from the enemy look's config (UF.PlateConfigKey
--     of an enemy) fills its plate; one drawn from the other config sits on
--     the plate's centre at that config's Width and Height: a friend's 150 by
--     16 by default;
--   - the plate size, one for every plate, is the enemy look's: Enemy
--     nameplates', or Friendly nameplates' while the enemy box is checked;
--   - a kind change resizes the frame, in combat too;
--   - a place that errored isn't noted as made, so the next update places
--     the frame;
--   - the click area follows the frame: oUF's two hit-test calls run again
--     once the frame's place or size changed, at once where the game allows
--     it (out of combat, or on the add's tick in combat), else when combat
--     ends; and on every plate once the plate size alone is set (out of
--     combat, as the size);
--   - the rounding walk and Blizzard's widgets after a resize;
--   - a part the plate's config turns off is still sized and placed by that
--     config, so the parts anchored to it sit where they would if it were
--     shown (the friendly config hangs the castbar, the aura areas and the
--     quest icon off its health bar, which is off by default);
--   - after a kind change every cached config on the frame is the new
--     kind's, the texts' and icons' of a part that's off too;
--   - a switch to the other config places every part afresh: what the
--     update places loses its old points first, so two parts anchored each
--     way round across the two configs place with no anchor loop, whichever
--     way the plate switches;
--   - a box set on its page, out of combat, moves a shown plate: its config,
--     its frame's size and place, and the plate size (ruling P1).
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua). The plates, their size and their click
-- area are tests/wow/game.lua's. A plate's frame is pinned to UIParent's scale
-- (pixels.lua) and its plate is the WorldFrame's child, so rects are compared
-- in the screen's units (screen, below), and a frame's own size is in
-- UIParent's units, where one is a pixel.
local NP = load_test_file('unitframes/nameplate_world.lua')

local CLIENTS = { 'forever', 'retail' }

-- A world with the plates spawned. Returns st, UF and the profile's units.
-- st.config.char is AceDB's per-character table, which the shell doesn't
-- have: {} for each world, as for a new character.
local function world(client)
	local st, UF = NP.world(client)
	st.config.char = {}
	UF:SpawnNameplates()
	return st, UF, UF:GetProfileConfig()
end

local enemy, friend = NP.enemy, NP.friend

-- A region's left, bottom, width and height in the screen's units: its own
-- times its effective scale.
local function screen(region)
	local l, b, w, h = region:GetRect()
	local s = region:GetEffectiveScale()
	return l * s, b * s, w * s, h * s
end

local function size_text(w, h) return ('%gx%g'):format(w, h) end

-- The size handed to the game for every plate, and the one width by height
-- gives through oUF's driver (UF.PlateDriverSize).
local function plate_size() return stub.nameplate_size and size_text(stub.nameplate_size[1], stub.nameplate_size[2]) end
local function driver(UF, width, height) return size_text(UF.PlateDriverSize(width, height)) end

-- Checks frame fills plate: oUF's two points, on the plate's corners, and
-- the plate's rect, at width by height of its own units.
local function check_fills(frame, plate, width, height, label)
	eq(frame:GetNumPoints(), 2, label .. ': two points')
	for p = 1, frame:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = frame:GetPoint(p)
		eq(relativeTo, plate, label .. ': on its plate')
		eq(point, relativePoint, label .. ': ' .. tostring(point) .. ' to the same point')
		check(x == 0 and y == 0, label .. ': no offset')
	end
	local fl, fb, fw, fh = screen(frame)
	local pl, pb, pw, ph = screen(plate)
	check(near(fl, pl) and near(fb, pb) and near(fw, pw) and near(fh, ph), label .. ": its plate's rect")
	check(near(frame:GetWidth(), width) and near(frame:GetHeight(), height),
		label .. (': %s, got %s'):format(size_text(width, height), size_text(frame:GetWidth(), frame:GetHeight())))
end

-- Checks frame sits on plate's centre, by one point, at width by height of
-- its own units.
local function check_centred(frame, plate, width, height, label)
	eq(frame:GetNumPoints(), 1, label .. ': one point')
	local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
	eq(point, 'CENTER', label .. ': its centre')
	eq(relativeTo, plate, label .. ': on its plate')
	eq(relativePoint, 'CENTER', label .. ": on the plate's centre")
	check(x == 0 and y == 0, label .. ': no offset')
	check(near(frame:GetWidth(), width) and near(frame:GetHeight(), height),
		label .. (': %s, got %s'):format(size_text(width, height), size_text(frame:GetWidth(), frame:GetHeight())))
	local fl, fb, fw, fh = screen(frame)
	local pl, pb, pw, ph = screen(plate)
	check(near(fl + fw / 2, pl + pw / 2) and near(fb + fh / 2, pb + ph / 2), label .. ': centred in its plate')
end

-- What a plate's click area covers: the one region every anchor is on, 'none'
-- for no anchors, 'mixed' for anchors on different regions.
local function clicks(plate)
	local points = plate:GetHitTestPoints()
	if #points == 0 then return 'none' end
	local region = points[1].relativeTo
	for _, a in ipairs(points) do
		if a.relativeTo ~= region then return 'mixed' end
	end
	return region
end

-- Records the hit-test calls on plate that go through, from now on: 'Clear',
-- or 'Set' with the size, in its own units, of the region handed to it at the
-- time ('frame' for SaftUI's frame on the plate). Whether the game's click
-- area follows the region's rect afterwards, or takes it when the call is
-- made, isn't documented, so the size at the call is what a test checks. The
-- plate's own methods still run.
local function watch_clicks(plate, frame)
	local log = {}
	local clear, set = plate.ClearAllHitTestPoints, plate.SetAllHitTestPoints
	rawset(plate, 'ClearAllHitTestPoints', function(...)
		clear(...)
		log[#log + 1] = 'Clear'
	end)
	rawset(plate, 'SetAllHitTestPoints', function(self, region)
		set(self, region)
		log[#log + 1] = ('Set %s %s'):format(region == frame and 'frame' or tostring(region), size_text(region:GetWidth(), region:GetHeight()))
	end)
	return log
end

------------------------------------------------------------------ each kind's place

test('a friendly plate is 150 by 16, centred', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		friend('nameplate1')
		local frame = NP.add('nameplate1')
		eq(frame.base_unit, 'friendlynameplate', client .. ': drawn from Friendly nameplates')
		check_centred(frame, NamePlate1, 150, 16, client)
		eq(plate_size(), driver(UF, 200, 20), client .. ": the plate is the enemy look's size")
		local fl, fb, fw, fh = screen(frame)
		local pl, pb, pw, ph = screen(NamePlate1)
		check(fl > pl and fb > pb and fl + fw < pl + pw and fb + fh < pb + ph, client .. ': inside its plate')

		-- The Friendly page's Width and Height.
		P.friendlynameplate.width, P.friendlynameplate.height = 120, 12
		UF:UpdateConfig('friendlynameplate')
		check_centred(frame, NamePlate1, 120, 12, client .. ': 120 by 12')
		eq(plate_size(), driver(UF, 200, 20), client .. ': the plate size unchanged')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('an enemy plate fills its plate', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		eq(frame.base_unit, 'nameplate', client .. ': drawn from Enemy nameplates')
		check_fills(frame, NamePlate1, 200, 20, client)

		-- The Enemy page's Width and Height: the plate's size, which the frame
		-- fills.
		P.nameplate.width, P.nameplate.height = 240, 24
		UF:UpdateConfig('nameplate')
		eq(plate_size(), driver(UF, 240, 24), client .. ': the plate 240 by 24')
		check_fills(frame, NamePlate1, 240, 24, client .. ': 240 by 24')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("a place that fails isn't taken as made: the next update places the frame", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF = world(client)
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check_fills(frame, NamePlate1, 200, 20, client .. ': an enemy')

		-- The plate handed to a friend, its frame's SetPoint failing once.
		rawset(frame, 'SetPoint', function() rawset(frame, 'SetPoint', nil) error('refused') end)
		friend('nameplate1')
		stub.fire_event('UNIT_FACTION', 'nameplate1')
		eq(#take_errors(), 1, client .. ': the failure reported')
		eq(frame.base_unit, 'friendlynameplate', client .. ': drawn from Friendly nameplates')

		-- Its next full update places it.
		UF:UpdateConfig('friendlynameplate')
		check_centred(frame, NamePlate1, 150, 16, client .. ': placed by the next update')
		eq(clicks(NamePlate1), frame, client .. ': its click area the frame')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the plate size

test('the plate size follows the enemy look', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		eq(plate_size(), driver(UF, 200, 20), client .. ": Enemy nameplates' size")

		P.nameplate.use_friendly = true
		UF:ApplyPlateSize()
		eq(plate_size(), driver(UF, 150, 16), client .. ": the enemy box: Friendly nameplates' size")
		eq(size_text(UF.plateDriver.plateWidth, UF.plateDriver.plateHeight), driver(UF, 150, 16), client .. ": through oUF's driver")
		P.friendlynameplate.width, P.friendlynameplate.height = 160, 18
		UF:ApplyPlateSize()
		eq(plate_size(), driver(UF, 160, 18), client .. ": the Friendly page's Width and Height")

		P.nameplate.use_friendly = false
		UF:ApplyPlateSize()
		eq(plate_size(), driver(UF, 200, 20), client .. ": off again: Enemy nameplates' size")

		-- The friendly box draws friends from the Enemy page: the enemy look,
		-- and the size, stay the Enemy page's.
		P.friendlynameplate.use_enemy = true
		UF:ApplyPlateSize()
		eq(plate_size(), driver(UF, 200, 20), client .. ": the friendly box: still Enemy nameplates' size")
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ a kind change

test('a kind change in combat resizes the frame', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF = world(client)
		stub.in_combat = true
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check_fills(frame, NamePlate1, 200, 20, client .. ': an enemy')

		-- The plate handed to a friend.
		NP.remove('nameplate1')
		friend('nameplate2')
		eq(NP.add('nameplate2', { plate = 1 }), frame, client .. ': the same frame for the friend')
		check_centred(frame, NamePlate1, 150, 16, client .. ': the friend')

		-- The friend turned hostile, and back.
		enemy('nameplate2')
		stub.fire_event('UNIT_FACTION', 'nameplate2')
		check_fills(frame, NamePlate1, 200, 20, client .. ': turned hostile')
		friend('nameplate2')
		stub.fire_event('UNIT_FACTION', 'nameplate2')
		check_centred(frame, NamePlate1, 150, 16, client .. ': friendly again')

		-- And to the next enemy.
		NP.remove('nameplate2')
		enemy('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		check_fills(frame, NamePlate1, 200, 20, client .. ': the next enemy')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
		eq(#take_errors(), 0, client .. ': no error')
		stub.in_combat = false
	end
end)

------------------------------------------------------------------ the click area

for _, client in ipairs(CLIENTS) do
	test(client .. ': the click area is the frame after a resize', function()
		local st, UF = world(client)
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		local log = watch_clicks(NamePlate1, frame)

		-- Out of combat: set again at once.
		friend('nameplate1')
		stub.fire_event('UNIT_FACTION', 'nameplate1')
		eq(table.concat(log, ', '), 'Clear, Set frame 150x16', 'out of combat: set again on the frame at its new size')
		eq(clicks(NamePlate1), frame, 'out of combat: the frame')

		-- In combat, on the add's tick: at once, after oUF's own two calls.
		stub.in_combat = true
		NP.remove('nameplate1')
		stub.run_timers() -- a later tick
		enemy('nameplate2')
		for i = #log, 1, -1 do log[i] = nil end
		NP.add('nameplate2', { plate = 1 })
		eq(table.concat(log, ', '), "Clear, Set frame 150x16, Clear, Set frame 200x20", "the add's tick: oUF's calls, then SaftUI's at the new size")
		eq(clicks(NamePlate1), frame, "the add's tick: the frame")
		eq(#take_errors(), 0, "the add's tick: no error")

		-- In combat after UNIT_FACTION: the game refuses it, so it waits for
		-- the end of combat, asked first, with no error.
		stub.run_timers()
		for i = #log, 1, -1 do log[i] = nil end
		friend('nameplate2')
		stub.fire_event('UNIT_FACTION', 'nameplate2')
		check_centred(frame, NamePlate1, 150, 16, 'UNIT_FACTION in combat: resized at once')
		eq(table.concat(log, ', '), '', 'UNIT_FACTION in combat: nothing tried')
		eq(#take_errors(), 0, 'UNIT_FACTION in combat: no error')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(table.concat(log, ', '), 'Clear, Set frame 150x16', 'combat over: set again on the frame at its new size')
		eq(clicks(NamePlate1), frame, 'combat over: the frame')

		-- A plate handed to a unit of the same kind keeps its place, and gets
		-- only oUF's calls.
		NP.remove('nameplate2')
		friend('nameplate3')
		for i = #log, 1, -1 do log[i] = nil end
		NP.add('nameplate3', { plate = 1 })
		eq(table.concat(log, ', '), 'Clear, Set frame 150x16', "the same kind: only oUF's calls")
		eq(#take_errors(), 0, 'no error')
	end)
end

test('a plate size set on its own sets every click area again: out of combat, and once combat ends', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		enemy('nameplate1')
		local foe = NP.add('nameplate1')
		friend('nameplate2')
		local ally = NP.add('nameplate2')
		local logs = { watch_clicks(NamePlate1, foe), watch_clicks(NamePlate2, ally) }
		local function joined(log) return table.concat(log, ', ') end
		local function reset() for _, log in ipairs(logs) do for i = #log, 1, -1 do log[i] = nil end end end

		-- The size alone, as after a UI scale change or Blizzard's own size
		-- (UF:ApplyPlateSize, with no frame placed again).
		P.nameplate.width, P.nameplate.height = 240, 24
		UF:ApplyPlateSize()
		eq(plate_size(), driver(UF, 240, 24), client .. ': the plates 240 by 24')
		eq(joined(logs[1]), 'Clear, Set frame 240x24', client .. ": the enemy's click area set again at its plate's new size")
		eq(joined(logs[2]), 'Clear, Set frame 150x16', client .. ": the friend's too")
		eq(clicks(NamePlate1), foe, client .. ": the enemy's click area the frame")

		-- In combat the size waits, and so do the click areas.
		reset()
		stub.in_combat = true
		P.nameplate.width, P.nameplate.height = 200, 20
		UF:ApplyPlateSize()
		eq(joined(logs[1]) .. joined(logs[2]), '', client .. ': in combat: nothing yet')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(plate_size(), driver(UF, 200, 20), client .. ': combat over: the plates 200 by 20')
		eq(joined(logs[1]), 'Clear, Set frame 200x20', client .. ": combat over: the enemy's click area at the new size")
		eq(joined(logs[2]), 'Clear, Set frame 150x16', client .. ": combat over: the friend's")
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the rounding and the widgets

test('the rounding walk and the widgets after a resize', function()
	for _, client in ipairs(CLIENTS) do
		local st, UF = world(client)
		friend('nameplate1')
		local frame = NP.add('nameplate1')
		local widgets = rawget(rawget(NamePlate1, 'UnitFrame'), 'WidgetContainer')

		local function check_after(label)
			eq(stub.state(frame).round_layout, true, label .. ': the frame rounded')
			eq(stub.state(frame.Name).round_layout, true, label .. ': its name rounded')
			eq(stub.state(frame.Health).round_layout, true, label .. ': its health bar rounded')
			eq(widgets:GetParent(), NamePlate1, label .. ': the widgets on the plate')
			eq(widgets:GetNumPoints(), 1, label .. ': by one point')
			local point, relativeTo, relativePoint = widgets:GetPoint(1)
			check(point == 'TOP' and relativeTo == NamePlate1 and relativePoint == 'BOTTOM', label .. ": the widgets' top on the plate's bottom")
			local _, wb, _, wh = screen(widgets)
			local _, pb = screen(NamePlate1)
			check(near(wb + wh, pb), label .. ': under the plate')
		end
		check_after(client .. ': a friend')

		for _, kind in ipairs({ 'hostile', 'friendly' }) do
			for _, region in ipairs({ frame, frame.Name, frame.Health }) do stub.state(region).round_layout = nil end
			if kind == 'hostile' then enemy('nameplate1') else friend('nameplate1') end
			stub.fire_event('UNIT_FACTION', 'nameplate1')
			check_after(client .. ': turned ' .. kind)
		end
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ a part off

-- left, bottom, width and height of a region in its unit frame's units (each
-- part is the frame's child at scale 1).
local function rect(region) return region:GetRect() end

test("a part turned on in the friendly config while its health bar stays off sits where it would on the bar", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		local F = P.friendlynameplate
		friend('nameplate1')
		local fresh = NP.add('nameplate1')
		-- A frame that showed an enemy first, its bar laid out from the enemy config.
		enemy('nameplate2')
		local reused = NP.add('nameplate2')
		friend('nameplate2')
		stub.fire_event('UNIT_FACTION', 'nameplate2')

		F.castbar.enable = true
		UF:UpdateConfig('friendlynameplate', 'Castbar')
		F.debuffs.enable = true
		UF:UpdateConfig('friendlynameplate', 'Debuffs')
		F.buffs.enable = true
		UF:UpdateConfig('friendlynameplate', 'Buffs')
		F.questindicator.enable = true
		UF:UpdateConfig('friendlynameplate', 'QuestIndicator')

		for _, case in ipairs({ { fresh, 'a friend' }, { reused, 'a friend after an enemy' } }) do
			local frame, label = case[1], client .. ': ' .. case[2]
			eq(frame.Health:IsShown(), false, label .. ': the health bar hidden')
			local l, b, w, h = rect(frame)
			check(near(w, 150) and near(h, 16), label .. ': the frame 150 by 16')
			-- The bar where its config puts it: filling the frame.
			local hl, hb, hw, hh = rect(frame.Health)
			check(near(hl, l) and near(hb, b) and near(hw, 150) and near(hh, 16),
				label .. (': the hidden bar fills the frame, got %g,%g %gx%g on %g,%g'):format(hl, hb, hw, hh, l, b))
			-- The castbar 6 under the bar, at its right edge, 132 by 12.
			local cl, cb, cw, ch = rect(frame.Castbar)
			check(near(cl + cw, l + w) and near(cb + ch, b - 6) and near(cw, 132) and near(ch, 12),
				label .. (': the castbar 6 under the bar, got %g,%g %gx%g'):format(cl, cb, cw, ch))
			-- The debuffs 6 above the bar from its left edge.
			local dl, db = rect(frame.Debuffs)
			check(near(dl, l) and near(db, b + h + 6), label .. (': the debuffs 6 above the bar, got %g,%g'):format(dl, db))
			-- The buffs 6 right of the bar, level with its top.
			local bl, bb, _, bh = rect(frame.Buffs)
			check(near(bl, l + w + 6) and near(bb + bh, b + h), label .. (': the buffs 6 right of the bar, got %g,%g'):format(bl, bb + bh))
			-- The quest icon 6 left of the bar, on its middle.
			local ql, qb, qw, qh = rect(frame.QuestIndicator)
			check(near(ql + qw, l - 6) and near(qb + qh / 2, b + h / 2), label .. (': the quest icon 6 left of the bar, got %g,%g'):format(ql + qw, qb + qh / 2))
		end
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

-- The cached configs on frame that don't point at config (a plate's config
-- unit's), space-joined: each element's (Threat's is always Enemy
-- nameplates' threat, threat.lua), and each of its texts' and icons', which
-- UF:UpdateElement doesn't reach on a part that's off.
local function stale_configs(UF, frame, config)
	local P = UF:GetProfileConfig()
	local stale = {}
	for name, element in pairs(frame.elements) do
		local own = name == 'Threat' and P.nameplate.threat or config[name:lower()]
		if element.config ~= own then stale[#stale + 1] = name end
		for key, text in pairs(element.textElements or {}) do
			if text.config ~= own[key:lower()] then stale[#stale + 1] = name .. '.' .. key end
		end
		for _, icon in ipairs(element.icons or {}) do
			local key
			for k, v in pairs(element) do
				if v == icon then key = k end
			end
			if icon.config ~= own[key:lower()] then stale[#stale + 1] = name .. '.' .. key end
		end
	end
	table.sort(stale)
	return table.concat(stale, ' ')
end

test("after a kind change every cached config is the new kind's: the parts', and the texts' and icons' of parts that are off", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check(frame.Health.text and frame.Castbar.Text and frame.Castbar.Time and frame.Castbar.Icon, client .. ': the texts and the icon there')
		eq(stale_configs(UF, frame, P.nameplate), '', client .. ': an enemy: Enemy nameplates')

		friend('nameplate1')
		stub.fire_event('UNIT_FACTION', 'nameplate1')
		eq(frame.config, P.friendlynameplate, client .. ': a friend: the frame')
		eq(stale_configs(UF, frame, P.friendlynameplate), '', client .. ': a friend: Friendly nameplates')

		-- Handed back to an enemy on an add, in combat.
		stub.in_combat = true
		NP.remove('nameplate1')
		enemy('nameplate2')
		NP.add('nameplate2', { plate = 1 })
		eq(stale_configs(UF, frame, P.nameplate), '', client .. ': an enemy again, in combat')
		stub.in_combat = false
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ the boxes, through the pages

-- A world with SaftUI's options window, model and widgets loaded, so the
-- pages are read and set through UF:GetConfigTable() and st.OptionsModel as
-- the window does (friendly_page_test.lua's).
local function page_world(client)
	local st, UF, P = world(client)
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	load_test_file('lib/options_walk.lua')
	ReloadUI = function() end
	return st, UF, P
end

-- Sets key on pick's General as the window does (the row's set, inherited
-- where it has none of its own). Returns what OM.Set does.
local function set(UF, pick, key, value)
	local root = { Unitframes = UF:GetConfigTable() }
	local view = SaftUI.OptionsModel.BuildView(root, 'Unitframes', { pick = pick, tab = 'general' })
	assert(view.picker.selected == pick, 'no ' .. pick .. ' page')
	for _, section in ipairs(view.sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return SaftUI.OptionsModel.Set(root, row, value) end
		end
	end
	error('no row ' .. key .. ' on ' .. pick)
end

test("a box set on its page moves a shown plate: its config, its frame's size and place, and the plate size", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = page_world(client)
		enemy('nameplate1')
		local foe = NP.add('nameplate1')
		friend('nameplate2')
		local ally = NP.add('nameplate2')
		local logs = { [foe] = watch_clicks(NamePlate1, foe), [ally] = watch_clicks(NamePlate2, ally) }

		-- Each frame's config, place and size, the plate size, and its click
		-- area: the frame, set again at its new size where its place changed.
		local function check_plates(label, foeBase, allyBase, plateW, plateH, allyMoved)
			eq(foe.base_unit, foeBase, label .. ": the enemy's config")
			eq(ally.base_unit, allyBase, label .. ": the friend's config")
			eq(plate_size(), driver(UF, plateW, plateH), label .. ': the plate size')
			check_fills(foe, NamePlate1, plateW, plateH, label .. ': the enemy')
			if allyBase == UF.PlateConfigKey(false) then
				check_fills(ally, NamePlate2, plateW, plateH, label .. ': the friend')
			else
				check_centred(ally, NamePlate2, 150, 16, label .. ': the friend')
			end
			eq(clicks(NamePlate1), foe, label .. ": the enemy's click area")
			eq(clicks(NamePlate2), ally, label .. ": the friend's click area")
			local log = logs[ally]
			if allyMoved then
				eq(log[#log], 'Set frame ' .. size_text(ally:GetWidth(), ally:GetHeight()), label .. ": the friend's set again at its new size")
			end
			for _, l in pairs(logs) do
				for i = #l, 1, -1 do l[i] = nil end
			end
		end

		check(set(UF, 'nameplate', 'use_friendly', true), client .. ': the enemy box checked')
		check_plates(client .. ': the enemy box', 'friendlynameplate', 'friendlynameplate', 150, 16, true)
		check(set(UF, 'nameplate', 'use_friendly', false), client .. ': the enemy box unchecked')
		check_plates(client .. ': the enemy box off', 'nameplate', 'friendlynameplate', 200, 20, true)

		check(set(UF, 'friendlynameplate', 'use_enemy', true), client .. ': the friendly box checked')
		check_plates(client .. ': the friendly box', 'nameplate', 'nameplate', 200, 20, true)
		check(set(UF, 'friendlynameplate', 'use_enemy', false), client .. ': the friendly box unchecked')
		check_plates(client .. ': the friendly box off', 'nameplate', 'friendlynameplate', 200, 20, true)
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

------------------------------------------------------------------ a switch places every part afresh

-- The parts a plate's full update places (UF:UpdateElement), each as
-- { region, label }: every element, one its config has off too (a plate's
-- part that's off is still placed, so the parts anchored to it sit right),
-- and the texts and icons that are on in a part that's on.
local function placed_parts(frame)
	local parts = {}
	for name, element in pairs(frame.elements) do
		parts[#parts + 1] = { element, name }
		if element.config.enable then
			for key, text in pairs(element.textElements or {}) do
				if text.config.enable then parts[#parts + 1] = { text, name .. '.' .. key } end
			end
			for i, icon in ipairs(element.icons or {}) do
				if icon.config.enable then parts[#parts + 1] = { icon, name .. '.icon' .. i } end
			end
		end
	end
	return parts
end

-- The labels of the parts the update places that aren't anchored where the
-- frame's config puts them, sorted and space-joined: '' when each has one
-- point, its position's point on what UF:GetFrame finds for it (another part,
-- a frame by its name, or the plate's frame), at its offsets.
local function misplaced(st, UF, frame)
	local wrong = {}
	for _, part in ipairs(placed_parts(frame)) do
		local region, position = part[1], part[1].config.position
		local point, _, relativePoint, x, y = st:UnpackPoint(position)
		local p, relativeTo, rp, px, py = region:GetPoint(1)
		if region:GetNumPoints() ~= 1 or p ~= point or relativeTo ~= UF:GetFrame(frame, position)
				or rp ~= relativePoint or px ~= x or py ~= y then
			wrong[#wrong + 1] = part[2]
		end
	end
	table.sort(wrong)
	return table.concat(wrong, ' ')
end

-- Each part a full update of frame would place that has a point now, sorted
-- and space-joined.
local function anchored(frame)
	local list = {}
	for _, part in ipairs(placed_parts(frame)) do
		if part[1]:GetNumPoints() > 0 then list[#list + 1] = part[2] end
	end
	table.sort(list)
	return table.concat(list, ' ')
end

-- The checks after a switch: no error, the frame's config unit, each part
-- where that config puts it, and the name's tag bound to it.
local function check_switched(st, UF, frame, base, label)
	eq(#take_errors(), 0, label .. ': no error')
	eq(frame.base_unit, base, label .. ': drawn from ' .. base)
	eq(misplaced(st, UF, frame), '', label .. ": every part where its config puts it")
	eq(NP.ouf.tags[frame.Name], '[st:name(' .. base .. ')]', label .. ": the name's tag bound to it")
end

-- The parts are placed one by one in pairs() order, each against the others
-- where they are then. Two parts anchored each way round across the two
-- configs would close a loop on a switch one way or the other, whatever the
-- order, so each test switches both ways.
test("a switch places every part afresh: the Friendly page's health bar under the name, the Enemy page's name on the bar", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		local F = P.friendlynameplate
		F.health.enable = true
		F.health.relative_width, F.health.width = false, 100
		F.health.relative_height, F.health.height = false, 4
		F.health.position = { point = 'TOP', element = 'Name', rel_point = 'BOTTOM', x_off = 0, y_off = -2 }
		eq(P.nameplate.name.position.element, 'Health', client .. ": the Enemy page's name on its bar")

		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check_switched(st, UF, frame, 'nameplate', client .. ': an enemy')
		NP.remove('nameplate1')
		friend('nameplate2')
		eq(NP.add('nameplate2', { plate = 1 }), frame, client .. ': the same frame, for a friend')
		check_switched(st, UF, frame, 'friendlynameplate', client .. ': enemy to friend')
		eq(select(2, frame.Health:GetPoint(1)), frame.Name, client .. ": the friend's bar under its name")
		eq(frame.Health:IsShown(), true, client .. ": the friend's bar shown")
		NP.remove('nameplate2')
		enemy('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		check_switched(st, UF, frame, 'nameplate', client .. ': friend to enemy')
		eq(select(2, frame.Name:GetPoint(1)), frame.Health, client .. ": the enemy's name on its bar")

		-- In combat, by the unit's faction.
		stub.in_combat = true
		friend('nameplate3')
		stub.fire_event('UNIT_FACTION', 'nameplate3')
		check_switched(st, UF, frame, 'friendlynameplate', client .. ': turned friendly in combat')
		enemy('nameplate3')
		stub.fire_event('UNIT_FACTION', 'nameplate3')
		check_switched(st, UF, frame, 'nameplate', client .. ': turned hostile in combat')
		stub.in_combat = false
	end
end)

test("a switch places every part afresh: an Enemy page with the name beside the raid mark, the Friendly page as it comes", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		-- An enemy layout from before friendly nameplates: the raid mark at
		-- the bar's left end and the name right of it. The Friendly page's
		-- default hangs the raid mark over the name.
		local E = P.nameplate
		E.raidtargetindicator.position = { point = 'LEFT', element = 'Health', rel_point = 'LEFT', x_off = 2, y_off = 0 }
		E.name.position = { point = 'LEFT', element = 'RaidTargetIndicator', rel_point = 'RIGHT', x_off = 2, y_off = 0 }
		eq(P.friendlynameplate.raidtargetindicator.position.element, 'Name', client .. ": the Friendly page's raid mark over the name")

		-- A friend's first add: the frame is built on the Enemy page, then
		-- switched.
		friend('nameplate1')
		local frame = NP.add('nameplate1')
		check_switched(st, UF, frame, 'friendlynameplate', client .. ": a friend's first add")
		NP.remove('nameplate1')
		enemy('nameplate2')
		NP.add('nameplate2', { plate = 1 })
		check_switched(st, UF, frame, 'nameplate', client .. ': friend to enemy')
		eq(frame.Name:IsShown(), true, client .. ": the enemy's name drawn")
		eq(select(2, frame.Name:GetPoint(1)), frame.RaidTargetIndicator, client .. ": beside the raid mark")
		NP.remove('nameplate2')
		friend('nameplate3')
		NP.add('nameplate3', { plate = 1 })
		check_switched(st, UF, frame, 'friendlynameplate', client .. ': enemy to friend')
		eq(select(2, frame.RaidTargetIndicator:GetPoint(1)), frame.Name, client .. ": the friend's raid mark over its name")
	end
end)

-- A text or an icon is never another part's anchor by its place in the frame
-- (UF:GetFrame finds only the frame's own parts), but can be by its frame
-- name, typed into a Position, so a switch clears theirs too.
test("a switch's update starts with nothing it places anchored: every part, and the texts and icons it shows", function()
	for _, client in ipairs(CLIENTS) do
		local st, UF, P = world(client)
		-- The Friendly page with its bar, the bar's text and its castbar on,
		-- so texts and an icon are placed on both sides of a switch.
		local F = P.friendlynameplate
		F.health.enable, F.health.text.enable, F.castbar.enable = true, true, true
		-- And the castbar's time on the Enemy page only: a text the update
		-- hides keeps its points.
		P.nameplate.castbar.time.enable = true
		P.nameplate.castbar.time.position = { point = 'RIGHT', element = 'Castbar', rel_point = 'RIGHT', x_off = -4, y_off = 0 }
		enemy('nameplate1')
		local frame = NP.add('nameplate1')
		check(frame.Health.text:GetNumPoints() > 0 and frame.Castbar.Text:GetNumPoints() > 0 and frame.Castbar.Icon:GetNumPoints() > 0
			and frame.Castbar.Time:GetNumPoints() > 0, client .. ': the texts and the icon placed for the enemy')

		local update, atStart = UF.UpdateUnitFrame, nil
		UF.UpdateUnitFrame = function(self, f, ...)
			if f == frame and atStart == nil then atStart = anchored(frame) end
			return update(self, f, ...)
		end
		for _, case in ipairs({ { friend, 'friendlynameplate' }, { enemy, 'nameplate' } }) do
			atStart = nil
			case[1]('nameplate1')
			stub.fire_event('UNIT_FACTION', 'nameplate1')
			eq(frame.base_unit, case[2], client .. ': switched to ' .. case[2])
			eq(atStart, '', client .. ': to ' .. case[2] .. ': nothing anchored when the update starts')
			eq(misplaced(st, UF, frame), '', client .. ': to ' .. case[2] .. ': then every part placed')
			if case[2] == 'friendlynameplate' then
				eq(frame.Castbar.Time:GetNumPoints(), 1, client .. ": the time the Friendly page has off keeps its place")
			end
		end
		UF.UpdateUnitFrame = update

		-- A part's update with no switch leaves the others where they are.
		UF:UpdateConfig('nameplate', 'Name')
		eq(misplaced(st, UF, frame), '', client .. ': an update of one part')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)
