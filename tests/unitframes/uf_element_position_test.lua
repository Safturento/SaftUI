-- The Position option for a unit frame's parts, generators.uf_element_position
-- (SaftUI-Unitframes/config/position.lua): its TO part's dropdown (Unit frame,
-- the unit's other elements, Global frame), what each choice reads and writes
-- (position.element and position.frame, cleared with false), and the choices
-- checked with st:ValidateAnchor.
--
-- Real: Core's helpers (load_core_helpers), st:ValidateAnchor and
-- st:RoundToPixel (api.lua), the options model (Config/optionsmodel.lua), which
-- reads a select's values and sorting as the Position block's dropdown lists
-- them, and the generator itself. The unit frame and its elements are plain
-- frames standing in for oUF's: the generator reads only unitframe[name],
-- unitframe.elements (a set of element names) and the part's .unitframe.

load_core_helpers()
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Unitframes/config/position.lua')
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

test('unit frame position: the dropdown names an element as the pages do and keeps the key it saves', function()
	local UF = SaftUI:GetModule('Unitframes', true) or SaftUI:NewModule('Unitframes')
	local realNames = UF.ELEMENT_NAMES
	UF.ELEMENT_NAMES = { Castbar = 'Cast bar', ReadyCheckIndicator = 'Ready check', Health = 'Health' }
	local unitframe = CreateFrame('Frame', 'GeneratorsNamesUnit', UIParent)
	for _, name in ipairs({ 'Name', 'Castbar', 'ReadyCheckIndicator', 'Health', 'Portrait' }) do
		unitframe[name] = CreateFrame('Frame', nil, unitframe)
	end
	unitframe.elements = { Name = unitframe.Name, Castbar = unitframe.Castbar, ReadyCheckIndicator = unitframe.ReadyCheckIndicator,
		Health = unitframe.Health, Portrait = unitframe.Portrait }
	unitframe.Name.unitframe = unitframe
	local store = { element = false, frame = false }
	local o = generators.uf_element_position(50,
		function(key) return store[key] end,
		function(key, value) store[key] = value end,
		function() return unitframe.Name end)
	local root, r = row_of(o)
	local listed = {}
	for i, entry in ipairs(OM.Values(root, r)) do listed[i] = entry.key .. '=' .. entry.name end
	-- Sorted by the name shown; an element the pages have no name for shows its key.
	eq(table.concat(listed, ','),
		'__unitframe=Unit frame,Castbar=Cast bar,Health=Health,Portrait=Portrait,ReadyCheckIndicator=Ready check,__global=Global frame')
	o.set(info, 'relative_to', 'ReadyCheckIndicator')
	eq(store.element, 'ReadyCheckIndicator', 'the saved key is the element key, not its name')
	UF.ELEMENT_NAMES = realNames
end)
