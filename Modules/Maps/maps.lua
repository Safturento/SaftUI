local ADDON_NAME, st = ...
local MP = st:NewModule('Maps', 'AceHook-3.0', 'AceEvent-3.0')

function MP:OnInitialize()
	self.config = st.config.profile.maps
	self:InitializeMinimap()
end

function MP:GetConfigTable()
	local config = st.config.profile.maps

	local config_table = {
		name = 'Maps',
		type = 'group',
		args = {
			minimap = {
				name = 'Minimap',
				type = 'group',
				inline = true,
				get = function(info) return config.minimap[info[#info]] end,
				set = function(info, value) config.minimap[info[#info]] = value; self:UpdateMinimap() end,
				args = {
					font = st.CF.generators.font(0),
					template = st.CF.generators.template(1),
					size = st.CF.generators.range(2, 'Size', 30, 500, 1),
					position = st.CF.generators.position(6, true, 
						function(key) return config.minimap.position[key] end,
						function(key, value) 
							config.minimap.position[key] = value
							self:UpdateMinimap()
						end
					),
				}
			}
		}
	}

	return config_table
end