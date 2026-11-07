local st = SaftUI

st.defaults.minimap = {
    font = 'pixel',
    enable = true,
    template = 'thick',
    size = 250,
    compartment_buttons = true,
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
	-- Minimap is owned by SaftUI (parented to UIParent), so it is sized and
	-- placed directly. MinimapCluster stays wherever Blizzard's Edit Mode puts it.
	local size = st:RoundToPixel(self.config.size, Minimap)
	Minimap:SetSize(size, size)
	st:SetBackdrop(Minimap, self.config.template)

	Minimap:ClearAllPoints()
	Minimap:SetPoint(st:UnpackPoint(self.config.position))
end

-- The minimap's section in the /sui tree. Clicking the minimap in edit mode
-- selects its General group (the mover's configPath).
function MM:GetConfigTable()
	-- Getters and setters go through self.config, which a profile change
	-- re-points at the new profile's table.
	local position = st.Config.generators.position(2, true,
		function(key) return self.config.position[key] end,
		function(key, value)
			self.config.position[key] = value
			self:UpdateConfig()
		end,
		Minimap
	)
	position.inline = false -- a tree section, not an inline box
	return {
		name = 'Minimap',
		type = 'group',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value) self.config[info[#info]] = value; self:UpdateConfig() end,
				args = {
					template = st.Config.generators.template(1),
					size = st.Config.generators.range(2, 'Size', 30, 500, 1),
					compartment_buttons = {
						order = 3,
						name = 'Addon buttons in compartment',
						desc = 'Move addon minimap buttons into the addon compartment menu. Requires a reload.',
						type = 'toggle',
						width = 'full',
						set = function(info, value) self.config[info[#info]] = value; st:Print('Reload your UI to apply.') end,
					},
				}
			},
			position = position,
		}
	}
end
