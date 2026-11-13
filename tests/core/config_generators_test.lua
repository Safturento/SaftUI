-- SaftUI-Core/Config/generators.lua's option generators (st.Config.generators):
-- the Position option for a frame placed anywhere, and the generators of the
-- other settings, which take desc and size. The unit frame part's Position
-- option is in tests/unitframes/uf_element_position_test.lua.
--
-- Real: Core's helpers (load_core_helpers, Config/generators.lua among them)
-- and st:ValidateAnchor and st:RoundToPixel (api.lua).

load_core_helpers()
local st = SaftUI
local generators = st.Config.generators

local info = {} -- the position option's get/set/validate don't read info

test('position generator: one position option reading and writing the same keys', function()
	local store = { point = 'TOPLEFT', rel_point = 'TOPRIGHT', x_off = '-6', y_off = 0, frame = 'UIParent' }
	local o = generators.position(9, true, store)
	eq(o.type, 'position', 'a single option of type position')
	eq(o.args, nil, 'not a group')
	eq(o.target, 'name', 'a typed frame name for its TO part')
	eq(o.order, 9, 'its order')
	eq(o.name, 'Position', 'its name')
	check(type(o.desc) == 'string' and o.desc ~= '', 'a default tooltip')
	eq(o.width, nil, 'no Ace width')

	eq(o.get(info, 'point'), 'TOPLEFT', 'reads point')
	eq(o.get(info, 'rel_point'), 'TOPRIGHT', 'reads rel_point')
	eq(o.get(info, 'frame'), 'UIParent', 'reads frame')
	eq(o.get(info, 'x_off'), -6, 'a string offset reads as a number')
	eq(o.get(info, 'y_off'), 0, 'a number offset as itself')
	store.y_off = nil
	eq(o.get(info, 'y_off'), 0, 'a missing offset reads as 0')

	o.set(info, 'x_off', 3.4)
	eq(type(store.x_off), 'number', 'an offset is stored as a number')
	eq(store.x_off, st:RoundToPixel(3.4), 'rounded to the pixel')
	check(store.x_off ~= 3.4, 'not the raw value: ' .. tostring(store.x_off))
	o.set(info, 'y_off', '-7')
	eq(store.y_off, -7, 'a string offset is stored as a number too')
	o.set(info, 'point', 'TOP')
	eq(store.point, 'TOP', 'point is written to the same key')
	o.set(info, 'frame', 'Minimap')
	eq(store.frame, 'Minimap', 'and frame')

	-- Functions in place of the table: get(key) and set(key, value).
	local sets = {}
	local fo = generators.position(1, true,
		function(key) return store[key] end,
		function(key, value) sets[#sets + 1] = key .. '=' .. tostring(value) end)
	eq(fo.get(info, 'point'), 'TOP', 'a get function is called with the key')
	fo.set(info, 'rel_point', 'LEFT')
	eq(sets[1], 'rel_point=LEFT', 'a set function with the key and value')
	eq(store.rel_point, 'TOPRIGHT', 'and the table is left alone')

	eq(generators.position(1, false, store).target, nil, 'without a global frame, no TO part')
	eq(generators.position(1, true, store, nil, nil, 'Where the bar sits.').desc, 'Where the bar sits.', 'a desc passed in')
	eq(generators.position(1, true, store).name, 'Position', 'a frame\'s own is named Position')
	eq(generators.position(1, true, store, nil, nil, nil, 'Count position').name, 'Count position', 'a part\'s says what it places')
end)

test('position generator: frame validate rejects a missing frame and an anchor loop, accepts a good name', function()
	local store = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 0, frame = 'UIParent' }
	local o = generators.position(1, true, store)
	eq(o.validate(info, 'frame', 'NoSuchFrame'), "Frame doesn't exist", 'no target: the name must be a frame')
	eq(o.validate(info, 'frame', 'UIParent'), true, 'a frame that exists')

	local placed = CreateFrame('Frame', 'GeneratorsPlaced', UIParent)
	local child = CreateFrame('Frame', 'GeneratorsPlacedChild', placed)
	o = generators.position(1, true, store, nil, placed)
	local _, loop = st:ValidateAnchor(placed, 'GeneratorsPlacedChild')
	check(loop ~= nil, "st:ValidateAnchor's message: " .. tostring(loop))
	eq(o.validate(info, 'frame', 'GeneratorsPlacedChild'), loop, "its own child: st:ValidateAnchor's message")
	local _, itself = st:ValidateAnchor(placed, 'GeneratorsPlaced')
	eq(o.validate(info, 'frame', 'GeneratorsPlaced'), itself, 'itself')
	eq(o.validate(info, 'frame', 'NoSuchFrame'), "Frame doesn't exist", 'a missing one')
	eq(o.validate(info, 'frame', 'UIParent'), true, 'a good name')
	eq(o.validate(info, 'point', 'TOP'), true, 'the other parts are not checked')
	eq(o.validate(info, 'x_off', 5), true, 'nor an offset')

	-- A target given as a function is looked up when the name is checked.
	local current
	o = generators.position(1, true, store, nil, function() return current end)
	eq(o.validate(info, 'frame', 'GeneratorsPlacedChild'), true, 'no frame yet: only that the name exists')
	current = placed
	eq(o.validate(info, 'frame', 'GeneratorsPlacedChild'), loop, 'then against the frame')
	check(child ~= nil, 'the child exists')
end)

test('the other generators take desc and size, and carry no Ace width', function()
	local range = generators.range(1, 'Spacing', 0, 30, 1, 'Gap between bars.', 'small')
	check(range.type == 'range' and range.min == 0 and range.max == 30 and range.step == 1, 'a range')
	eq(range.desc, 'Gap between bars.', 'its desc')
	eq(range.size, 'small', 'its size')
	eq(range.width, nil, 'no Ace width')

	local toggle = generators.toggle(1, 'Enable', 'Shows it.')
	check(toggle.type == 'toggle' and toggle.name == 'Enable' and toggle.order == 1, 'a toggle')
	eq(toggle.desc, 'Shows it.', 'its desc')
	eq(toggle.size, nil, 'normal when no size is given')
	eq(toggle.width, nil, 'no Ace width')
	eq(generators.toggle(1, 'Show', nil, 'wide').size, 'wide', 'a toggle takes a size')
	eq(generators.toggle(1, 'Show').desc, nil, 'no desc when none is given')

	local cases = {
		{ 'enable', generators.enable(2, 'D'), 'toggle' },
		{ 'alpha', generators.alpha(2, 'D'), 'range' },
		{ 'framelevel', generators.framelevel(2, 'D'), 'range' },
		{ 'height', generators.height(2, 'D'), 'input' },
		{ 'width', generators.width(2, 'D'), 'input' },
		{ 'background', generators.background(2, 'D'), 'select' },
		{ 'font', generators.font(2, 'D'), 'select' },
	}
	for _, case in ipairs(cases) do
		local name, option, otype = case[1], case[2], case[3]
		eq(option.type, otype, name .. ' type')
		eq(option.order, 2, name .. ' order')
		eq(option.desc, 'D', name .. ' takes a desc')
		eq(option.width, nil, name .. ' has no Ace width')
	end
end)

test("the Theme builder offers Use SaftUI's theme, Thick, Thin, Blizzard and None, in that order", function()
	local o = generators.theme(3, 'Which frames.')
	eq(table.concat(o.sorting, ','), 'theme,thick,thin,blizzard,none')
	eq(o.values.blizzard, 'Blizzard')
	eq(o.values.theme, "Use SaftUI's theme")
	eq(o.values.none, 'None')
end)
