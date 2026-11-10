local st = SaftUI

st.Config.options = {
	type = 'group',
	name = st.name,
	inline = true,
	args = {
	},
}

function st.Config:GetFontObjects()
	local font_objects = {}
	for k,v in pairs(st.config.profile.fonts) do
		font_objects[k] = v.name
	end

	return font_objects
end

--[[
	Generators for SaftUI's option tables. Each returns a fresh option. desc is
	its tooltip; size ('small' or 'wide', where a generator takes one) is how
	much of a line SaftUI's options window gives it, and no size is a half.
	They set no Ace width: the window doesn't read it.
]]
local generators = {}
st.Config.generators = generators

-- target is the frame being placed, or a function returning it (or nil while
-- it doesn't exist), looked up each time an anchor is checked.
local function ResolveTarget(target)
	if type(target) == 'function' then
		return target()
	end
	return target
end

local POSITION_DESC = "Where this sits: which of its points goes to which point of what it's attached to, then moved by X and Y."

--[[
	The Position option: one option for every SetPoint parameter, drawn by the
	options window's Position block (type 'position', optionswidgets.lua). Its
	get, set and validate take the part first: 'point', 'rel_point', 'x_off',
	'y_off', and with global_frame 'frame', the name of the frame it's placed
	on (the block's TO part, a name box: target = 'name').

	get and set are the caller's: get(key) and set(key, value) functions, or a
	table read and written by key (then set is nil). The keys are the parts', as
	the profile stores a position. Offsets read as numbers (a profile can hold
	"-6") and are stored as numbers rounded to the pixel.

	target is the frame being placed, or a function returning it (nil while it
	doesn't exist). A typed frame name must be a frame, and with a target it
	goes through st:ValidateAnchor, which rejects the target itself, its own
	children and anything anchored back to it.

	In a mover's section the option goes last in its General group, after every
	other option there: the window gives it a section of its own, and options
	after it would follow on untitled.

	The section is titled with the option's name, 'Position' for a frame's own.
	A Position that places a part of the frame (a text, an icon) passes name,
	such as 'Count position', so no tab has two sections of the same title.
]]
function generators.position(order, global_frame, get, set, target, desc, name)
	local function Read(key)
		if type(get) == 'function' then
			return get(key)
		end
		return get[key]
	end
	local function Write(key, value)
		if set then
			set(key, value)
		else
			get[key] = value
		end
	end

	return {
		order = order or 0,
		name = name or 'Position',
		desc = desc or POSITION_DESC,
		type = 'position',
		target = global_frame and 'name' or nil,
		get = function(info, part)
			local value = Read(part)
			if part == 'x_off' or part == 'y_off' then
				return tonumber(value) or 0
			end
			return value
		end,
		set = function(info, part, value)
			if part == 'x_off' or part == 'y_off' then
				value = tonumber(st:RoundToPixel(tonumber(value) or 0))
			end
			Write(part, value)
		end,
		validate = function(info, part, value)
			if part ~= 'frame' or not global_frame then return true end
			local frame = ResolveTarget(target)
			if frame then
				local ok, err = st:ValidateAnchor(frame, value)
				return ok or err
			end
			return _G[value] and true or "Frame doesn't exist"
		end,
	}
end

-- The relative_to choices that aren't an element name.
local UNIT_FRAME, GLOBAL_FRAME = '__unitframe', '__global'

--[[
	The Position option for a unit frame element, or for an element's text or
	icon. UF:GetFrame places it relative to another element of the same unit
	frame (position.element) if that unit frame has it, else to a global frame
	(position.frame), else to its own unit frame. The block's TO part is a
	dropdown (target = 'select') of those choices, its part 'relative_to': it
	shows and sets that choice from those two keys. Global frame starts at
	UIParent, and while it's picked the name box under the dropdown types the
	frame's name (nameKey). A key is cleared by writing false, not nil: AceDB
	would fill a nil key with its default again at the next login.

	get and set are get(key) and set(key, value) functions. target is the frame
	being placed, or a function returning it (nil while it doesn't exist). The
	elements offered come from its unit frame, and every picked or typed anchor
	is checked with st:ValidateAnchor against it.
]]
function generators.uf_element_position(order, get, set, target, desc, name)
	local option = generators.position(order, true, get, set, target, desc, name)
	local GetPart, SetPart, ValidatePart = option.get, option.set, option.validate

	local function UnitFrame()
		local frame = ResolveTarget(target)
		return frame and frame.unitframe
	end

	-- What UF:GetFrame anchors to: an element name, UNIT_FRAME or GLOBAL_FRAME.
	local function GetRelativeTo()
		local element, frame = get('element'), get('frame')
		local unitframe = UnitFrame()
		if element and (not unitframe or unitframe[element]) then
			return element
		elseif frame then
			return GLOBAL_FRAME
		end
		return UNIT_FRAME
	end

	-- The elements of the target's unit frame, apart from the target itself,
	-- sorted. Every registered element while the unit frame isn't known.
	local function GetElementNames()
		local unitframe, frame = UnitFrame(), ResolveTarget(target)
		local names = {}
		for name in pairs(unitframe and unitframe.elements or st:GetModule('Unitframes').elements) do
			if not (unitframe and unitframe[name] == frame) then
				tinsert(names, name)
			end
		end
		sort(names)
		return names
	end

	option.target = 'select'
	option.nameKey = GLOBAL_FRAME

	-- The dropdown: Unit frame, the elements, Global frame.
	option.values = function()
		local values = { [UNIT_FRAME] = 'Unit frame', [GLOBAL_FRAME] = 'Global frame' }
		for _, name in ipairs(GetElementNames()) do
			values[name] = name
		end
		return values
	end
	option.sorting = function()
		local sorting = { UNIT_FRAME }
		for _, name in ipairs(GetElementNames()) do
			tinsert(sorting, name)
		end
		tinsert(sorting, GLOBAL_FRAME)
		return sorting
	end

	option.get = function(info, part)
		if part == 'relative_to' then
			return GetRelativeTo()
		end
		return GetPart(info, part)
	end

	option.validate = function(info, part, value)
		if part ~= 'relative_to' then
			return ValidatePart(info, part, value)
		end
		local frame, unitframe = ResolveTarget(target), UnitFrame()
		if not (frame and unitframe) then return true end
		local relative
		if value == UNIT_FRAME then
			relative = unitframe
		elseif value == GLOBAL_FRAME then
			relative = UIParent
		else
			relative = unitframe[value]
		end
		if not relative then return true end
		local ok, err = st:ValidateAnchor(frame, relative)
		return ok or err
	end

	option.set = function(info, part, value)
		if part ~= 'relative_to' then
			return SetPart(info, part, value)
		end
		if value == GetRelativeTo() then return end
		if value == UNIT_FRAME then
			set('element', false)
			set('frame', false)
		elseif value == GLOBAL_FRAME then
			set('element', false)
			set('frame', 'UIParent')
		else
			set('frame', false)
			set('element', value)
		end
	end

	return option
end

function generators.toggle(order, name, desc, size)
	return {
		order = order,
		name = name,
		desc = desc,
		type = 'toggle',
		size = size,
	}
end

function generators.enable(order, desc)
	return generators.toggle(order, 'Enable', desc)
end

function generators.range(order, name, min, max, step, desc, size)
	return {
		order = order,
		name = name,
		desc = desc,
		type = 'range',
		min = min or 1,
		max = max or 99,
		step = step or 1,
		size = size,
	}
end

function generators.framelevel(order, desc)
	return generators.range(order, 'Frame level', 0, 99, 1, desc)
end

function generators.alpha(order, desc)
	return generators.range(order, 'Alpha', 0, 1, 0.05, desc)
end

-- An input is text both ways: AceConfig's contract gives its get's value to
-- the box as a string, and its set what was typed, as a string. So a numeric
-- input (e.g. a default width of 200) needs converting. These delegate to the
-- nearest parent group's get/set (the one the option would otherwise
-- inherit), converting the value to text for the box and back to a number for
-- the profile.
local function InheritedHandler(info, key)
	local node = info.options
	local handler = node[key]
	for i = 1, #info - 1 do
		node = node.args and node.args[info[i]]
		if not node then break end
		if node[key] ~= nil then handler = node[key] end
	end
	return handler
end

local function NumberInputGet(info)
	local get = InheritedHandler(info, 'get')
	if type(get) ~= 'function' then return '' end
	local value = get(info)
	return value ~= nil and tostring(value) or ''
end

local function NumberInputSet(info, value)
	local set = InheritedHandler(info, 'set')
	if type(set) == 'function' then
		set(info, tonumber(value) or value)
	end
end

function generators.height(order, desc)
	return {
		order = order,
		name = 'Height',
		desc = desc,
		type = 'input',
		pattern = '%d+',
		get = NumberInputGet,
		set = NumberInputSet,
	}
end

function generators.width(order, desc)
	return {
		order = order,
		name = 'Width',
		desc = desc,
		type = 'input',
		pattern = '%d+',
		get = NumberInputGet,
		set = NumberInputSet,
	}
end

-- A frame's Theme and Background (theme.lua): overrides of SaftUI's theme for
-- the frames the option governs. A profile key of either holds the value; its
-- default is 'theme', which follows SaftUI's.
local THEME_VALUES = {
	{ 'theme', "Use SaftUI's theme" }, { 'thick', 'Thick' }, { 'thin', 'Thin' }, { 'none', 'None' },
}
local BACKGROUND_VALUES = {
	{ 'theme', "Use SaftUI's theme" }, { 'solid', 'Solid' }, { 'transparent', 'Transparent' },
}
local THEME_DESC = "Use SaftUI's theme follows Global Settings > Theme; None draws no border or background."
local BACKGROUND_DESC = "Solid, or see-through by Global Settings > Theme's Opacity. Use SaftUI's theme follows its Transparent background."

-- A select of choices ({ value, name } pairs), listed in their order.
local function OrderedSelect(order, name, desc, choices)
	local values, sorting = {}, {}
	for i, choice in ipairs(choices) do
		values[choice[1]] = choice[2]
		sorting[i] = choice[1]
	end
	return {
		order = order,
		name = name,
		desc = desc,
		type = 'select',
		values = values,
		sorting = sorting,
	}
end

-- desc says which frames it governs; what the choices do is added after it.
function generators.theme(order, desc)
	return OrderedSelect(order, 'Theme', desc and desc .. ' ' .. THEME_DESC or THEME_DESC, THEME_VALUES)
end

function generators.background(order, desc)
	return OrderedSelect(order, 'Background', desc or BACKGROUND_DESC, BACKGROUND_VALUES)
end

function generators.font(order, desc)
	return {
		name = 'Font',
		desc = desc,
		type = 'select',
		order = order,
		values = st.Config:GetFontObjects(),
	}
end
