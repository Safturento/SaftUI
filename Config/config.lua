local ADDON_NAME, st = ...

st.CF = st:NewModule('Config')

function st.CF:InitializeConfigGUI()
	local config = LibStub('AceConfig-3.0')
	local dialog = LibStub('AceConfigDialog-3.0')

	config:RegisterOptionsTable(ADDON_NAME, self.options)
	dialog:AddToBlizOptions(ADDON_NAME, ADDON_NAME)
	
	
	
	for name, module in pairs(st.modules) do
		if module.GetConfigTable then
			config:RegisterOptionsTable(ADDON_NAME..' '..name, module:GetConfigTable())
			dialog:AddToBlizOptions(ADDON_NAME..' '..name, name, ADDON_NAME)
		end
	end
	
	config:RegisterOptionsTable(ADDON_NAME..' '..'Profiles', LibStub('AceDBOptions-3.0'):GetOptionsTable(st.config))
	dialog:AddToBlizOptions(ADDON_NAME..' '..'Profiles', 'Profiles', ADDON_NAME)

	st.config_initialized = true
end

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
	name = ADDON_NAME,
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

function st.CF.generators.position(order, config_table, global_frame, set_func)
	local table = {
		order = order or 0,
		name = 'Position',
		type = 'group',
		inline = true,
		get = function(info)
			return config_table[info.option.order]
		end,
		set = function(info, value)
			config_table[info.option.order] = value
			if set_func then set_func() end
		end,
		args = {
			point = {
				order = 1,
				name = 'Anchor', 
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 'normal',
			},
			rel_point = {
				order = 4,
				name = 'Relative', 
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 'normal',
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

function st.CF.generators.uf_element_position(order, config_table, set_func)
	local table = st.CF.generators.position(order, config_table, true)
	local values = {}
	for key,_ in pairs(st:GetModule('Unitframes').elements) do
		values[key] = key
	end

	table.args.frame_type = {
		name = 'Anchor type',
		type = 'toggle',
		desc = 'unchecked: self \nchecked: element selection \ngrayed: global frame',
		order = 2,
		tristate = true,
		get = function(info)
			local value = config_table.frame_type
			if value then
				table.args.frame.values = values
				table.args.frame.type = 'select'
			elseif value == nil then
				table.args.frame.type = 'input'
			end
			return value
		end,
		set = function(info, value)
			config_table.frame_type = value
			if value then
				table.args.frame.values = values
				table.args.frame.type = 'select'
			elseif value == nil then
				table.args.frame.type = 'input'
			end
			if set_func then set_func() end
		end
	}

	table.args.frame.hidden = function(info)
		return config_table.frame_type == false
	end

	table.args.frame.get = function(info)
		if config_table.frame_type then
			return config_table.anchor_element
		elseif config_table.frame_type == nil then
			return config_table.anchor_frame
		end
	end
	table.args.frame.set = function(info, value)
		if config_table.frame_type then
			config_table.anchor_element = value
		elseif config_table.frame_type == nil then
			config_table.anchor_frame = value
		end
		if set_func then set_func() end
	end

	table.args.frame.validate = function(info, name) 
		if config_table.frame_type == nil then
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
		values = st.CF:GetFrameTemplates(),
	}
end

function st.CF.generators.font(order)
	return {
		name = 'Font',
		type = 'select',
		order = 1,
		values = st.CF:GetFontObjects(),
	}
end

