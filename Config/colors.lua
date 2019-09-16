local ADDON_NAME, st = ...

function st.CF:GetColorConfig()
	local colors = {
		order = 2,
		type = 'group',
		name = 'Colors',
		-- childGroups = 'tabs',
		args = {},
		get = function(info)
			return unpack(st.config.profile.colors[info[#info-1]][info[#info]])
		end,
	}

	for k,v in pairs(st.config.profile.colors) do
		colors.args[k] = {
			type = 'group',
			name = k,
			args = {}
		}
		for group, color in pairs(v) do
			-- colors.args[k].args[group] = {
			-- 	name = group,
			-- 	type = 'color',
			-- }
		end
	end


	return colors
end
