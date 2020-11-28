local st = SaftUI

function st.CF:UpdateTemplateConfig(template)
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

st.CF.options = {
	type = 'group',
	name = st.name,
	inline = true,
	args = {
	},
}

function st.CF:GetFrameTemplates()
	local templates = {}
	for k,v in pairs(st.config.profile.templates) do
		templates[k] = v.name
	end

	templates.none = 'None'

	return templates
end

function st.CF:GetFontObjects()
	local font_objects = {}
	for k,v in pairs(st.config.profile.fonts) do
		font_objects[k] = v.name
	end

	return font_objects
end

st.CF.generators = {}

function st.CF.generators.position(order, global_frame, get, set)
	local table = {
		order = order or 0,
		name = 'Position',
		type = 'group',
		inline = true,
		get = function(info)
			if type(get) == 'function' then
				return get(info[#info])
			end
			return get[info[#info]]
		end,
		set = function(info, value)
			if set then
				set(info[#info], value)
			else
				get[info[#info]] = value
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
				pattern = '%d+',
				width = 0.4
			},
			y_off = {
				order = 6,
				name = 'Y Offset',
				type = 'input',
				pattern = '%d+',
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
				return _G[name] and true or "Frame doesn't exist"
			end
		}
	end

	return table
end

function st.CF.get_frame(self, config)
	local frame = self
	if config.frame_type == false then
		frame = self[config.anchor_element]
	elseif config.frame_type == true then
		frame = _G[config.anchor_frame]
	end
	return frame
end

function st.CF.generators.uf_element_position(order, get, set)
	local table = st.CF.generators.position(order, true, get, set)
	local values = {}
	for key,_ in pairs(st:GetModule('Unitframes').elements) do
		values[key] = key
	end

	table.args.frame_type = {
		name = 'Anchor type',
		type = 'toggle',
		desc = 'unchecked: element selection \nchecked: global frame \ngrayed: self',
		order = 0,
		width = 'full',
		tristate = true,
		get = function(info)
			local value = get('frame_type')
			if value == false then
				table.args.frame.values = values
				table.args.frame.type = 'select'
			elseif value == true then
				table.args.frame.type = 'input'
			end
			return value
		end,
		set = function(info, value)
			set('frame_type', value)
			if value == false then
				table.args.frame.values = values
				table.args.frame.type = 'select'
			elseif value == true then
				table.args.frame.type = 'input'
			end
		end
	}

	table.args.frame.hidden = function(info)
		return get('frame_type') == nil
	end

	table.args.frame.get = function(info)
		local frame_type = get('frame_type')
		if frame_type == false then
			return get('anchor_element')
		elseif frame_type == true then
			return get('anchor_frame')
		end
	end
	table.args.frame.set = function(info, value)
		local frame_type = get('frame_type')
		if frame_type == false then
			set('anchor_element', value)
		elseif frame_type == true then
			set('anchor_frame', value)
		end
	end

	table.args.frame.validate = function(info, name)
		if get('frame_type') == nil then
			return _G[name] and true or "Frame doesn't exist"
		end
		return true
	end

	return table
end

function st.CF.generators.toggle(order, name, width)
	return {
		order = order,
		name = name,
		type = 'toggle',
		width = width or 0.5
	}
end

function st.CF.generators.enable(order)
	return st.CF.generators.toggle(order, 'Enable')
end

function st.CF.generators.range(order, name, min, max, step, width)
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

function st.CF.generators.framelevel(order)
	return st.CF.generators.range(order, 'Frame level', 0, 99, 1)
end

function st.CF.generators.alpha(order)
	return st.CF.generators.range(order, 'Alpha', 0, 1, 0.05)
end

function st.CF.generators.height(order)
	return {
		order = order,
		name = 'Height',
		type = 'input',
		pattern = '%d+',
		width = 0.5,
	}
end

function st.CF.generators.width(order)
	return {
		order = order,
		name = 'Width',
		type = 'input',
		pattern = '%d+',
		width = 0.5,
	}
end

function st.CF.generators.template(order)
	return {
		order = order,
		name = 'Template',
		type = 'select',
		values = CF:GetFrameTemplates(),
	}
end

function st.CF.generators.font(order)
	return {
		name = 'Font',
		type = 'select',
		order = 1,
		values = CF:GetFontObjects(),
	}
end