local st = SaftUI

function st.Config:UpdateTemplateConfig(template)
	if not template then
		for template,_ in pairs(st.config.profile.templates) do
			self:UpdateTemplateConfig(template)
		end
		return
	end

	for frame, t in self.template_cache do
		if t == template then
			st:SetTemplate(frame, t)
		end
	end
end

st.Config.options = {
	type = 'group',
	name = st.name,
	inline = true,
	args = {
	},
}

function st.Config:GetFrameTemplates()
	local templates = {}
	for k,v in pairs(st.config.profile.templates) do
		templates[k] = v.name
	end

	templates.none = 'None'

	return templates
end

function st.Config:GetFontObjects()
	local font_objects = {}
	for k,v in pairs(st.config.profile.fonts) do
		font_objects[k] = v.name
	end

	return font_objects
end

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

function generators.position(order, global_frame, get, set, target)
	local table = {
		order = order or 0,
		name = 'Position',
		type = 'group',
		inline = true,
		get = function(info)
			local key = info[#info]
			local value
			if type(get) == 'function' then
				value = get(key)
			else
				value = get[key]
			end
			if key == 'x_off' or key == 'y_off' then
				return tostring(value or 0)
			end
			return value
		end,
		set = function(info, value)
			local key = info[#info]
			if key == 'x_off' or key == 'y_off' then
				value = tonumber(st:RoundToPixel(tonumber(value) or 0))
			end
			if set then
				set(key, value)
			else
				get[key] = value
			end
		end,
		args = {
			point = {
				order = 1,
				name = 'Anchor',
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 0.65,
			},
			rel_point = {
				order = 4,
				name = 'Relative',
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 0.65,
			},
			x_off = {
				order = 5,
				name = 'X Offset',
				type = 'input',
				pattern = '^%-?%d+%.?%d*$',
				width = 0.4
			},
			y_off = {
				order = 6,
				name = 'Y Offset',
				type = 'input',
				pattern = '^%-?%d+%.?%d*$',
				width = 0.4
			},
		}
	}

	if global_frame then
		table.args.frame = {
			order = 3,
			name = 'Frame',
			type = 'input',
			validate = function(info, name)
				local frame = ResolveTarget(target)
				if frame then
					local ok, err = st:ValidateAnchor(frame, name)
					return ok or err
				end
				return _G[name] and true or "Frame doesn't exist"
			end
		}
	end

	return table
end

-- The Frame choices that aren't an element name.
local UNIT_FRAME, GLOBAL_FRAME = '__unitframe', '__global'

--[[
	The Position editor for a unit frame element, or for an element's text or
	icon. UF:GetFrame places it relative to another element of the same unit
	frame (position.element) if that unit frame has it, else to a global frame
	(position.frame), else to its own unit frame. The Frame select shows and
	sets that choice from those two keys. It clears a key by writing false, not
	nil: AceDB would fill a nil key with its default again at the next login.

	target is the frame being placed, or a function returning it (nil while it
	doesn't exist). The elements offered come from its unit frame, and every
	picked or typed anchor is checked with st:ValidateAnchor against it.
]]
function generators.uf_element_position(order, get, set, target)
	local options = generators.position(order, true, get, set, target)

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

	options.args.relative_to = {
		order = 2,
		name = 'Frame',
		type = 'select',
		width = 0.75,
		values = function()
			local values = { [UNIT_FRAME] = 'Unit frame', [GLOBAL_FRAME] = 'Global frame' }
			for _, name in ipairs(GetElementNames()) do
				values[name] = name
			end
			return values
		end,
		sorting = function()
			local sorting = { UNIT_FRAME }
			for _, name in ipairs(GetElementNames()) do
				tinsert(sorting, name)
			end
			tinsert(sorting, GLOBAL_FRAME)
			return sorting
		end,
		get = function()
			return GetRelativeTo()
		end,
		-- Picking Global frame starts at UIParent; its name is typed below.
		validate = function(info, value)
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
		end,
		set = function(info, value)
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
		end,
	}

	-- generators.position's input, for the global frame's name.
	options.args.frame.name = 'Frame name'
	options.args.frame.hidden = function()
		return GetRelativeTo() ~= GLOBAL_FRAME
	end

	return options
end

function generators.toggle(order, name, width)
	return {
		order = order,
		name = name,
		type = 'toggle',
		width = width or 0.5
	}
end

function generators.enable(order)
	return generators.toggle(order, 'Enable')
end

function generators.range(order, name, min, max, step, width)
	return {
		order = order,
		name = name,
		type = 'range',
		min = min or 1,
		max = max or 99,
		step = step or 1,
		width = width or 1,
	}
end

function generators.framelevel(order)
	return generators.range(order, 'Frame level', 0, 99, 1)
end

function generators.alpha(order)
	return generators.range(order, 'Alpha', 0, 1, 0.05)
end

-- AceConfigDialog shows an input box empty unless its get returns a string,
-- and hands back whatever was typed as a string. So numeric inputs (e.g. a
-- default width of 200) showed blank. These delegate to the nearest parent
-- group's get/set (the one the option would otherwise inherit), converting the
-- value to text for the box and back to a number for the profile.
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

function generators.height(order)
	return {
		order = order,
		name = 'Height',
		type = 'input',
		pattern = '%d+',
		width = 0.5,
		get = NumberInputGet,
		set = NumberInputSet,
	}
end

function generators.width(order)
	return {
		order = order,
		name = 'Width',
		type = 'input',
		pattern = '%d+',
		width = 0.5,
		get = NumberInputGet,
		set = NumberInputSet,
	}
end

function generators.template(order)
	return {
		order = order,
		name = 'Template',
		type = 'select',
		values = st.Config:GetFrameTemplates(),
	}
end

function generators.font(order)
	return {
		name = 'Font',
		type = 'select',
		order = order,
		values = st.Config:GetFontObjects(),
	}
end