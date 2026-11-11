-- SaftUI-Core/Config/widgets.lua's option generators (st.Config.generators):
-- the Position option, for a frame placed anywhere and for a unit frame part,
-- and the generators of the other settings, which take desc and size.
--
-- Real: Core's helpers (load_core_helpers, Config/widgets.lua among them),
-- st:ValidateAnchor and st:RoundToPixel (api.lua), and the options model
-- (Config/optionsmodel.lua), which reads a select's values and sorting as the
-- Position block's dropdown lists them. The unit frame and its elements are
-- plain frames standing in for oUF's: the generator reads only unitframe[name],
-- unitframe.elements (a set of element names) and the part's .unitframe.

load_core_helpers()
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local st = SaftUI
local OM = st.OptionsModel
local generators = st.Config.generators

local info = {} -- the position option's get/set/validate don't read info

-- The row the options model makes of option, on a page of its own.
local function row_of(option)
	local root = { Page = { type = 'group', name = 'Page', args = { pos = option } } }
	for _, section in ipairs(OM.BuildView(root, 'Page').sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'pos' then return root, r end
		end
	end
end

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

test('unit frame position: relative_to reads the element, the global frame or the unit frame, and clears with false', function()
	-- A unit frame with Health and Power; the part placed is its Power.
	local unitframe = CreateFrame('Frame', 'GeneratorsUnit', UIParent)
	unitframe.Health = CreateFrame('Frame', nil, unitframe)
	unitframe.Power = CreateFrame('Frame', nil, unitframe)
	unitframe.elements = { Health = unitframe.Health, Power = unitframe.Power }
	unitframe.Power.unitframe = unitframe

	-- Raid target's default: an element this unit doesn't have.
	local store = { point = 'CENTER', rel_point = 'TOP', x_off = '0', y_off = '-6', element = 'Portrait', frame = false }
	local o = generators.uf_element_position(50,
		function(key) return store[key] end,
		function(key, value) store[key] = value end,
		function() return unitframe.Power end)
	eq(o.type, 'position', 'a position option')
	eq(o.target, 'select', 'with a dropdown for its TO part')
	eq(o.nameKey, '__global', 'whose Global frame choice shows the name box')
	eq(o.order, 50, 'its order')
	check(type(o.desc) == 'string' and o.desc ~= '', 'a default tooltip')
	eq(o.get(info, 'y_off'), -6, 'offsets read as numbers')

	eq(o.get(info, 'relative_to'), '__unitframe', 'an element not on this unit, and no frame: Unit frame')
	o.set(info, 'relative_to', 'Health')
	check(store.element == 'Health' and store.frame == false, 'picking an element from there works')
	eq(o.get(info, 'relative_to'), 'Health', 'and reads back')

	o.set(info, 'relative_to', '__global')
	check(store.element == false and store.frame == 'UIParent', 'Global frame: element false, frame UIParent')
	eq(o.get(info, 'relative_to'), '__global', 'reads Global frame')
	eq(o.get(info, 'frame'), 'UIParent', 'and the name box reads the frame')
	o.set(info, 'frame', 'Minimap')
	eq(store.frame, 'Minimap', 'a typed name is stored as frame')

	o.set(info, 'relative_to', '__unitframe')
	check(store.element == false and store.frame == false, 'Unit frame: both false, never nil')
	eq(o.get(info, 'relative_to'), '__unitframe', 'reads Unit frame')

	o.set(info, 'relative_to', 'Health')
	check(store.frame == false and store.element == 'Health', 'an element: frame false, element set')

	-- The dropdown: Unit frame, the unit's other elements, Global frame.
	local root, r = row_of(o)
	check(r ~= nil, 'the model makes a row of it')
	local listed = {}
	for i, entry in ipairs(OM.Values(root, r)) do listed[i] = entry.key .. '=' .. entry.name end
	eq(table.concat(listed, ','), '__unitframe=Unit frame,Health=Health,__global=Global frame',
		'Unit frame first, the elements (not the part itself), Global frame last')

	-- The choices are checked against the part with st:ValidateAnchor, as
	-- typed names are.
	eq(o.validate(info, 'relative_to', 'Health'), true, 'another element is fine')
	eq(o.validate(info, 'relative_to', '__unitframe'), true, 'and the unit frame')
	eq(o.validate(info, 'relative_to', '__global'), true, 'and Global frame (UIParent)')
	unitframe.Health:SetPoint('TOP', unitframe.Power, 'BOTTOM')
	local _, loop = st:ValidateAnchor(unitframe.Power, unitframe.Health)
	check(loop ~= nil, "st:ValidateAnchor's message: " .. tostring(loop))
	eq(o.validate(info, 'relative_to', 'Health'), loop, 'an element anchored to the part would loop')
	eq(o.validate(info, 'frame', 'NoSuchFrame'), "Frame doesn't exist", 'a typed name that is no frame')
	eq(o.validate(info, 'point', 'TOP'), true, 'the points are not checked')
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
