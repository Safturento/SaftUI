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

-- The minimap's options as shared pieces: the /sui tree and the edit mode
-- sidebar (GetMoverOptions) are both built from these.
function MM:GetOptionPieces()
	local config = st.config.profile.minimap
	local general = {
		name = 'General',
		type = 'group',
		order = 1,
		get = function(info) return config[info[#info]] end,
		set = function(info, value) config[info[#info]] = value; self:UpdateConfig() end,
		args = {
			template = st.Config.generators.template(1),
			size = st.Config.generators.range(2, 'Size', 30, 500, 1),
			compartment_buttons = {
				order = 3,
				name = 'Addon buttons in compartment',
				desc = 'Move addon minimap buttons into the addon compartment menu. Requires a reload.',
				type = 'toggle',
				width = 'full',
				set = function(info, value) config[info[#info]] = value; st:Print('Reload your UI to apply.') end,
			},
		}
	}
	local position = st.Config.generators.position(2, true,
		function(key) return config.position[key] end,
		function(key, value)
			config.position[key] = value
			self:UpdateConfig()
		end,
		Minimap
	)
	return general, position
end

-- Sidebar sections for the edit mode settings window.
function MM:GetMoverOptions()
	local general, position = self:GetOptionPieces()
	position.inline = false -- a sidebar section, not an inline box
	return {
		name = 'Minimap',
		type = 'group',
		args = {
			general = general,
			position = position,
		}
	}
end

function MM:GetConfigTable()
	local general, position = self:GetOptionPieces()
	-- Flat inline group, as before: General's controls first, then Position.
	local args = {}
	for key, option in pairs(general.args) do args[key] = option end
	position.order = 6
	args.position = position
	return {
		name = 'Maps',
		type = 'group',
		args = {
			minimap = {
				name = 'Minimap',
				type = 'group',
				inline = true,
				get = general.get,
				set = general.set,
				args = args,
			}
		}
	}
end
