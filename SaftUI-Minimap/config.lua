local st = SaftUI

st.defaults.minimap = {
    font = 'pixel',
    enable = true,
    template = 'thick',
    size = 250,
    position = {
        point = 'TOPRIGHT',
        frame = 'UIParent',
        rel_point = 'TOPRIGHT',
        x_off = -st.CLAMP_INSET,
        y_off = -st.CLAMP_INSET
    },
}

st.defaults.micromenu = {
    position = {
        point = 'TOPLEFT',
        frame = 'UIParent',
        rel_point = 'TOPLEFT',
        x_off = st.CLAMP_INSET,
        y_off = -st.CLAMP_INSET,
    },
}

local MM = st:GetModule('Minimap')

function MM:UpdateConfig()
    Minimap:SetSize(self.config.size, self.config.size)
    MinimapCluster:SetSize(self.config.size, self.config.size)
    st:SetBackdrop(Minimap, self.config.template)

    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint(st:UnpackPoint(self.config.position))
	Minimap:ClearAllPoints()
	Minimap:SetPoint(st:UnpackPoint(self.config.position))
end

function MM:GetConfigTable()
	local config = st.config.profile.minimap
	return {
		name = 'Maps',
		type = 'group',
		args = {
			minimap = {
				name = 'Minimap',
				type = 'group',
				inline = true,
				get = function(info) return config[info[#info]] end,
				set = function(info, value) config[info[#info]] = value; self:UpdateConfig() end,
				args = {
					template = st.Config.generators.template(1),
					size = st.Config.generators.range(2, 'Size', 30, 500, 1),
					position = st.Config.generators.position(6, true,
						function(key) return config.position[key] end,
						function(key, value)
							config.position[key] = value
							self:UpdateConfig()
						end
					),
				}
			}
		}
	}
end