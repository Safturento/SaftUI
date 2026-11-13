local st = SaftUI

--[[
	The Position option for a unit frame's parts (generators.uf_element_position,
	in st.Config.generators with Core's other option generators in
	SaftUI-Core/Config/generators.lua). Unit frames' elements and the nameplates'
	parts call it from their config tables, when the options are built.
]]
local generators = st.Config.generators

-- target is the frame being placed, or a function returning it (or nil while
-- it doesn't exist). A copy of ResolveTarget in Core's generators.lua: keep it
-- in step with that one.
local function ResolveTarget(target)
	if type(target) == 'function' then
		return target()
	end
	return target
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
