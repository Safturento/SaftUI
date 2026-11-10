local st = SaftUI

st.defaults.minimap = {
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

-- The minimap's panel: a SaftUI frame kept here. st:SetBackdrop would store it
-- on Blizzard's Minimap frame as .backdrop (and .thick). One frame level down,
-- so it draws under the map.
local backdrop
local function UpdateBackdrop(template)
	if template == nil or template == 'none' or template == '' then
		if backdrop then st:SetTemplate(backdrop, 'none') end
		return
	end

	if not backdrop then
		backdrop = st:CreateFrame('Frame', nil, Minimap)
		local level = Minimap:GetFrameLevel()
		if not issecretvalue(level) then
			backdrop:SetFrameLevel(math.max(0, level - 1))
		end
	end

	st:SetTemplate(backdrop, template)
	local offset = st:ThemeInset(template)
	backdrop:ClearAllPoints()
	backdrop:SetPoint('TOPLEFT', Minimap, 'TOPLEFT', -offset, offset)
	backdrop:SetPoint('BOTTOMRIGHT', Minimap, 'BOTTOMRIGHT', offset, -offset)
end

function MM:UpdateConfig()
	-- Minimap is owned by SaftUI (parented to UIParent), so it is sized and
	-- placed directly. MinimapCluster stays wherever Blizzard's Edit Mode puts it.
	-- In combat it can't move if a protected frame (e.g. a unit frame) is
	-- anchored to it; then its size and position wait for the end of combat.
	st:SafeReposition(Minimap, 'minimap', function()
		local size = st:RoundToPixel(self.config.size, Minimap)
		Minimap:SetSize(size, size)
		Minimap:ClearAllPoints()
		Minimap:SetPoint(st:UnpackPoint(self.config.position))
	end)

	-- Only SaftUI's backdrop frame is touched, so this is fine in combat.
	UpdateBackdrop(self.config.template)
end

-- The minimap's section in the /sui tree: General, with the Position option
-- last. Clicking the minimap in edit mode selects its General group (the
-- mover's configPath).
function MM:GetConfigTable()
	-- Getters and setters go through self.config, which a profile change
	-- re-points at the new profile's table.
	local position = st.Config.generators.position(1000, true,
		function(key) return self.config.position[key] end,
		function(key, value)
			self.config.position[key] = value
			self:UpdateConfig()
		end,
		Minimap
	)
	return {
		name = 'Minimap',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value) self.config[info[#info]] = value; self:UpdateConfig() end,
				args = {
					template = st.Config.generators.template(1,
						"The look of the minimap's border and background. None draws no frame around it."),
					size = st.Config.generators.range(2, 'Size', 30, 500, 1, "The minimap's width and height, in pixels."),
					compartment_buttons = {
						order = 3,
						name = 'Addon buttons in compartment',
						desc = 'Move addon minimap buttons into the addon compartment menu. Requires a reload.',
						type = 'toggle',
						set = function(info, value) self.config[info[#info]] = value; st:Print('Reload your UI to apply.') end,
					},
					position = position,
				}
			},
		}
	}
end
