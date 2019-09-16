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

function st.CF.generators.position(config_table, global_frame, order, name, set_func)
	local table = {
		order = order or 0,
		name = name or 'Position',
		type = 'group',
		inline = true,
		get = function(info)
			return config_table[info.option.order]
		end,
		set = function(info, value)
			config_table[info.option.order] = value
			if set_func then
				set_func()
			end
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
				order = 2,
				name = 'Relative', 
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 'normal',
			},
			x_off = {
				order = 3,
				name = 'X Offset', 
				type = 'input',
				pattern = '%d+',
				width = 0.4
			},
			y_off = {
				order = 4,
				name = 'Y Offset', 
				type = 'input',
				pattern = '%d+',
				width = 0.4
			},
		}
	}

	if global_frame then
		table.args.frame = {
			order = 2,
			name = 'Frame',
			type = 'input',
			validate = function(info, name) 
				return _G[name] and true or "Frame doesn't exist"
			end
		}

		table.args.rel_point.order = 3
		table.args.x_off.order = 4
		table.args.y_off.order = 5
	end

	return table
end


function st.CF.generators.enable(order)
	return  {
		order = order,
		name = 'Enable',
		type = 'toggle',
		width = 0.5
	}
end

function st.CF.generators.toggle(order, name, width)
	return {
		order = order,
		name = name,
		type = 'toggle',
		width = width or 0.5
	}
end

function st.CF.generators.range(order, name, min, max, step, width)
	return {
		order = order,
		name = name,
		type = 'range',
		min = 1,
		max = 99,
		step = step or 1,
		width = width or 1,
	}
end

function st.CF.generators.framelevel(order)
	return {
		order = order,
		name = 'Frame Level',
		type = 'range',
		min = 0,
		max = 99,
		step = 1,
		width = 1,
	}
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

function st.CF.generators.alpha(order)
	return {
		order = order,
		name = 'Alpha',
		type = 'range',
		min = 0,
		max = 1,
		step = 0.05,
		width = 1,
	}
end

