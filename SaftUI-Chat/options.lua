local st = SaftUI
local CHT = st:GetModule('Chat')

local generators = st.Config.generators

-- The chat section in the /sui tree. Clicking the chat frame in edit mode selects its
-- General group (the mover's configPath). Absent until the chat frame is taken over.
function CHT:GetConfigTable()
	if not self.holder then return end

	-- Getters and setters go through self.config, which a profile change re-points at
	-- the new profile's table.
	--
	-- The relative frame is validated against ChatFrame1, since that is the frame the
	-- position is applied to: ValidateAnchor rejects anchoring it to itself, to its
	-- children (tabs, edit box) and to anything anchored back to it.
	local position = generators.position(2, true,
		function(key) return self.config.position[key] end,
		function(key, value)
			self.config.position[key] = value
			self:ApplyPosition()
		end,
		ChatFrame1
	)
	position.inline = false -- a tree section, not an inline box

	local font = generators.font()
	font.order = 2

	return {
		name = 'Chat',
		type = 'group',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:ApplyAppearance()
				end,
				args = {
					template = generators.template(1),
					font = font,
					fontsize = generators.range(3, 'Font size', 8, 32, 1),
					padding = generators.range(4, 'Padding', 0, 30, 1),
					editbox_height = {
						order = 5,
						name = 'Edit box height',
						type = 'range',
						min = 15,
						max = 60,
						step = 1,
						get = function() return self.config.editbox.height end,
						set = function(_, value)
							self.config.editbox.height = value
							self:ApplyAppearance()
						end,
					},
					tabs_fade = {
						order = 6,
						name = 'Fade tabs',
						desc = 'Let the chat tabs fade out. Requires a reload.',
						type = 'toggle',
						width = 'full',
						get = function() return self.config.tabs.fade end,
						set = function(_, value)
							self.config.tabs.fade = value
							st:Print('Reload your UI to apply.')
						end,
					},
				},
			},
			position = position,
		},
	}
end
