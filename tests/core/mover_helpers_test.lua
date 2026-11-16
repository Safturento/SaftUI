-- Core's two helpers for a movable frame: st:PlaceAtPosition (api.lua, which
-- the addons' tests have without edit mode) clears a frame's points and sets
-- it from a saved position table, as the sites that did it by hand;
-- st:RegisterConfigMover (EditMode/editmode.lua) registers a mover whose
-- position is read from and written to a table in the profile.
--
-- Real: Core's edit mode (st:RegisterMover and the movers it makes). The
-- config the movers read is a hand-made table in `holder`, replaced as a
-- profile switch replaces the profile's tables. The frames are the stubs'.

load_test_file('core/config_helpers.lua')
local st = SaftUI

stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600)

-- Every point a frame has, as { point, relativeTo, relativePoint, x, y } rows.
local function Points(frame)
	local out = {}
	for i = 1, frame:GetNumPoints() do
		out[i] = { frame:GetPoint(i) }
	end
	return out
end

local function Frame(name)
	local frame = CreateFrame('Frame', name, UIParent)
	frame:SetSize(50, 20)
	return frame
end

test('PlaceAtPosition sets the frame from a full position, offsets on whole pixels', function()
	local frame = Frame()
	st:PlaceAtPosition(frame, { point = 'TOPLEFT', rel_point = 'BOTTOM', x_off = 12, y_off = -7 })
	local points = Points(frame)
	eq(#points, 1, 'one point')
	eq(points[1][1], 'TOPLEFT', 'point')
	eq(points[1][3], 'BOTTOM', 'relative point')
	eq(points[1][4], 12, 'x, as saved at one pixel a unit')
	eq(points[1][5], -7, 'y')
end)

test('PlaceAtPosition anchors to the frame the position names', function()
	local other = Frame('MoverHelpersOther')
	local frame = Frame()
	st:PlaceAtPosition(frame, { point = 'CENTER', frame = other, rel_point = 'CENTER', x_off = 1, y_off = 2 })
	eq(frame:GetPoint(1), 'CENTER', 'point')
	eq(select(2, frame:GetPoint(1)), other, 'anchored to that frame')
	local named = Frame()
	st:PlaceAtPosition(named, { point = 'CENTER', frame = 'MoverHelpersOther', rel_point = 'CENTER' })
	eq(select(2, named:GetPoint(1)), other, 'a frame named by its global name')
end)

test('PlaceAtPosition fills what a partial position leaves out as UnpackPoint does', function()
	local frame = Frame()
	st:PlaceAtPosition(frame, { point = 'LEFT' })
	local p = Points(frame)[1]
	eq(p[1], 'LEFT', 'point')
	eq(p[3], 'LEFT', 'no relative point is the point')
	eq(p[4], 0, 'no x is 0')
	eq(p[5], 0, 'no y is 0')
end)

test('PlaceAtPosition clears the points the frame had', function()
	local frame = Frame()
	frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 5, 5)
	frame:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -5, -5)
	st:PlaceAtPosition(frame, { point = 'CENTER', x_off = 3, y_off = 4 })
	local points = Points(frame)
	eq(#points, 1, 'only the new point is left')
	eq(points[1][1], 'CENTER', 'it is the new one')
	st:PlaceAtPosition(frame, { point = 'TOP', x_off = 0, y_off = 0 })
	eq(#Points(frame), 1, 'placing again leaves one')
end)

test('PlaceAtPosition anchors to the frame\'s own parent when no frame is named', function()
	local parent = Frame()
	local frame = CreateFrame('Frame', nil, parent)
	st:PlaceAtPosition(frame, { point = 'CENTER' })
	eq(select(2, frame:GetPoint(1)), parent, 'the parent, not UIParent')
end)

test('PlaceAtPosition errors for a frame name no frame has, as SetPoint does', function()
	local frame = Frame()
	check(not pcall(st.PlaceAtPosition, st, frame, { point = 'CENTER', frame = 'NoSuchFrame' }), 'errors')
end)

test('PlaceAtPosition hands an offset that is not a number to SetPoint as saved, even a string', function()
	local frame = Frame()
	local got
	frame.SetPoint = function(_, ...) got = { ... } end
	st:PlaceAtPosition(frame, { point = 'CENTER', x_off = '5', y_off = '-3' })
	eq(got[4], '5', 'x as saved')
	eq(got[5], '-3', 'y as saved')
end)

test("PlaceAtPosition: at k 1 whole offsets are today's numbers and a saved 1.3333 lands at 1; at 0.75 a saved 5 lands at 4 pixels", function()
	use_scale(1)
	local frame = Frame()
	for _, case in ipairs({ { 0, 0 }, { 5, -7 }, { 12, 300 }, { -157, -130 }, { 1.3333, -1.3333 }, { 0.3, 0.7 }, { 2560, -1440 } }) do
		st:PlaceAtPosition(frame, { point = 'CENTER', x_off = case[1], y_off = case[2] })
		local p = Points(frame)[1]
		local wx, wy = math.floor(math.abs(case[1]) + 0.5), math.floor(math.abs(case[2]) + 0.5)
		wx, wy = case[1] < 0 and -wx or wx, case[2] < 0 and -wy or wy
		eq(p[4], wx, case[1] .. ' x')
		eq(p[5], wy, case[2] .. ' y')
	end
	-- Whole offsets come out as the very numbers they went in (no float is made).
	st:PlaceAtPosition(frame, { point = 'CENTER', x_off = -157, y_off = 130 })
	check(rawequal(Points(frame)[1][4], -157) and rawequal(Points(frame)[1][5], 130), 'to the bit')
	st:PlaceAtPosition(frame, { point = 'CENTER', x_off = 0, y_off = 0 })
	check(rawequal(Points(frame)[1][4], 0) and rawequal(Points(frame)[1][5], 0), 'zero stays zero')
	use_scale(0.75)
	local pixel = st:GetPixelSize(frame)
	st:PlaceAtPosition(frame, { point = 'CENTER', x_off = 5, y_off = -5 })
	local p = Points(frame)[1]
	eq(math.floor(p[4] / pixel + 0.5), 4, 'a saved 5 lands at 4 pixels')
	eq(math.floor(p[5] / pixel + 0.5), -4, 'and a saved -5 at -4 pixels')
	check(p[4] < 5.34 and p[4] > 5.33, 'which is 5.3333 units')
	use_scale(1)
end)

scaled_test('PlaceAtPosition: a saved position is never written, and goes through a scale change and back with no drift', function()
	local frame = Frame()
	local position = { point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 157.5, y_off = -130.3333 }
	local saved = { x = position.x_off, y = position.y_off }
	local first
	for round = 1, 10 do
		for _, k in ipairs({ 1.55, 0.75, test_scale() }) do
			use_scale(k)
			st:PlaceAtPosition(frame, position)
			eq(position.x_off, saved.x, 'x is still as saved')
			eq(position.y_off, saved.y, 'y is still as saved')
		end
		local p = Points(frame)[1]
		if round == 1 then first = p[4] .. ',' .. p[5] end
		eq(p[4] .. ',' .. p[5], first, 'round ' .. round .. ' lands where round 1 did')
	end
	-- Where it lands: whole pixels at this scale.
	local pixel = st:GetPixelSize(frame)
	local p = Points(frame)[1]
	check(math.abs(p[4] / pixel - math.floor(p[4] / pixel + 0.5)) < 1e-3, 'x on whole pixels')
	check(math.abs(p[5] / pixel - math.floor(p[5] / pixel + 0.5)) < 1e-3, 'y on whole pixels')
	-- A drag's save (rounded to pixels by the edit mode, 1e-4 kept) placed again lands on itself.
	position.x_off = st:RoundToPixel(157.5, frame)
	st:PlaceAtPosition(frame, position)
	eq(Points(frame)[1][4], position.x_off, 'a position the edit mode saved is placed where it was saved')
	use_scale(1)
	stub.screen_width, stub.screen_height = 1000, 600
	UIParent:SetScale(768 / 600)
	st.UIScale:SetTokens()
end)

-- A profile table for the movers to read, replaced as a profile switch does.
local holder
local function Register(key, extra)
	local frame = Frame()
	local calls = { apply = 0 }
	local spec = {
		key = key,
		config = function() return holder.config end,
		apply = function() calls.apply = calls.apply + 1 end,
	}
	for k, v in pairs(extra or {}) do spec[k] = v end
	local mover = st:RegisterConfigMover(frame, spec)
	return mover, frame, calls
end

test('RegisterConfigMover registers a mover for the frame under the key', function()
	holder = { config = { position = { point = 'CENTER' } } }
	local mover, frame = Register('mh_basic', { label = 'Basic', configPath = { 'Basic', 'general' } })
	eq(mover.def.frame, frame, 'the frame')
	eq(st.EditModeFrames.movers.mh_basic, mover, 'registered under its key')
	eq(mover.def.label, 'Basic', 'label passed through')
	eq(mover.def.configPath[2], 'general', 'configPath passed through')
end)

test('the mover reads the position fresh from the config on every call', function()
	local first = { point = 'CENTER', x_off = 1, y_off = 2 }
	holder = { config = { position = first } }
	local mover = Register('mh_read')
	eq(mover.def.getPosition(), first, 'the profile\'s own table')
	local second = { point = 'TOP', x_off = 9, y_off = 8 }
	holder.config = { position = second } -- a profile switch replaces the table
	eq(mover.def.getPosition(), second, 'the new profile\'s table')
	holder.config.position = nil
	eq(mover.def.getPosition(), nil, 'whatever the config holds')
end)

test('setPosition writes the position field of the current config, and only that', function()
	holder = { config = { position = { point = 'CENTER' }, size = 40 } }
	local mover, _, calls = Register('mh_write')
	local old = holder.config
	local new = { point = 'LEFT', x_off = 3, y_off = 4 }
	mover.def.setPosition(new)
	eq(holder.config.position, new, 'the table given is stored')
	eq(calls.apply, 0, 'setPosition does not apply')
	local keys = {}
	for k in pairs(holder.config) do keys[#keys + 1] = k end
	table.sort(keys)
	eq(table.concat(keys, ','), 'position,size', 'no field is added')
	eq(holder.config.size, 40, 'no other field changes')
	holder.config = { position = { point = 'TOP' } } -- a profile switch
	mover.def.setPosition(new)
	eq(holder.config.position, new, 'written to the new profile')
	eq(old.position, new, 'the old one keeps what it was given')
end)

test('apply is the one the site gave, and other fields pass through untouched', function()
	holder = { config = { position = { point = 'CENTER' } } }
	local fn = function() end
	local mover, _, calls = Register('mh_apply', { blizzardFrame = true, extra = fn })
	mover.def.apply()
	eq(calls.apply, 1, 'apply runs the site\'s function')
	eq(mover.def.blizzardFrame, true, 'blizzardFrame')
	eq(mover.def.extra, fn, 'a field RegisterMover does not know')
	eq(mover.def.key, nil, 'key and config are not part of the def')
	eq(mover.def.config, nil, 'config is not part of the def')
end)

test('RegisterConfigMover leaves the caller\'s spec as it was', function()
	holder = { config = { position = {} } }
	local spec = { key = 'mh_spec', config = function() return holder.config end, apply = function() end, label = 'L' }
	local before = {}
	for k, v in pairs(spec) do before[k] = v end
	st:RegisterConfigMover(Frame(), spec)
	local n = 0
	for k, v in pairs(spec) do n = n + 1; eq(v, before[k], k) end
	eq(n, 4, 'no field added, frame included')
end)

test('RegisterConfigMover needs a key, a config getter and an apply', function()
	holder = { config = { position = {} } }
	local frame = Frame()
	check(not pcall(st.RegisterConfigMover, st, frame, { config = function() return {} end, apply = function() end }), 'no key')
	check(not pcall(st.RegisterConfigMover, st, frame, { key = 'mh_x', apply = function() end }), 'no config')
	check(not pcall(st.RegisterConfigMover, st, frame, { key = 'mh_y', config = function() return {} end }), 'no apply')
end)

test('a dragged position is placed by apply through PlaceAtPosition', function()
	holder = { config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } } }
	local frame = Frame()
	st:RegisterConfigMover(frame, {
		key = 'mh_drag',
		config = function() return holder.config end,
		apply = function() st:PlaceAtPosition(frame, holder.config.position) end,
	})
	local mover = st.EditModeFrames.movers.mh_drag
	holder.config.position = { point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 0 }
	st.EditModeFrames:CommitPosition(mover, 30, -40) -- what a drag's end or a nudge does
	local p = Points(frame)[1]
	eq(p[1], 'TOPLEFT', 'placed at the saved point')
	eq(p[4], 30, 'x')
	eq(p[5], -40, 'y')
end)

test('RegisterConfigMover passes module, isDisabled, isHidden and noDefaultReason through, and makes getDefaultPosition from defaults', function()
	local isDisabled, isHidden = function() return false end, function() return true end
	local defaults = { position = { point = 'CENTER', x_off = 4, y_off = 8 } }
	local mover = st:RegisterConfigMover(Frame(), {
		key = 'helpers_fields', config = function() return {} end, apply = function() end,
		module = 'Chat', isDisabled = isDisabled, isHidden = isHidden, noDefaultReason = 'why',
		defaults = function() return defaults end,
	})
	local def = mover.def
	eq(def.module, 'Chat', 'module')
	eq(def.isDisabled, isDisabled, 'isDisabled as given')
	eq(def.isHidden, isHidden, 'isHidden as given')
	eq(def.noDefaultReason, 'why', 'noDefaultReason')
	eq(def.defaults, nil, 'defaults is not passed on')
	local position = def.getDefaultPosition()
	eq(position.x_off, 4, 'the default position')
	check(position ~= defaults.position, 'a copy')
	position.x_off = 50
	eq(defaults.position.x_off, 4, 'a write into the copy leaves the defaults')
	local none = st:RegisterConfigMover(Frame(), {
		key = 'helpers_nodefaults', config = function() return {} end, apply = function() end,
	})
	eq(none.def.getDefaultPosition, nil, 'no defaults, no getDefaultPosition')
	local ok, err = pcall(st.RegisterConfigMover, st, Frame(), {
		key = 'helpers_both', config = function() return {} end, apply = function() end,
		defaults = function() return {} end, getDefaultPosition = function() end,
	})
	eq(ok, false, 'both is an error')
	check(tostring(err):find('give defaults or getDefaultPosition, not both', 1, true), 'naming both')
end)
