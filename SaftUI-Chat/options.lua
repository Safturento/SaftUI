local st = SaftUI
local CHT = st:GetModule('Chat')

local generators = st.Config.generators

-- Blizzard's own minimum chat size. A whole number at least this big is required:
-- the text box would otherwise accept 0, negatives or text like "12abc", and a
-- non-numeric size silently turns off SaftUI's sizing.
local MIN_WIDTH, MIN_HEIGHT = 250, 120

local function SizeInput(option, minimum)
	option.pattern = nil
	option.validate = function(_, value)
		local number = tonumber(value)
		if not (value and value:match('^%s*%d+%s*$') and number and number >= minimum) then
			return ('Enter a whole number of at least %d.'):format(minimum)
		end
		return true
	end
	return option
end

-- The chat section in the /sui tree. Clicking the chat frame in edit mode selects its
-- General group (the mover's configPath). Absent until the chat frame is taken over.
function CHT:GetConfigTable()
	if not self.holder then return end

	-- Getters and setters go through self.config, which a profile change re-points at
	-- the new profile's table.
	--
	-- The position is applied to the holder and copied to ChatFrame1 (PlaceChatFrame), so
	-- the relative frame is validated against both: ValidateAnchor rejects anchoring
	-- either to itself, to its children and to anything anchored back to it (e.g.
	-- ChatFrame1's tabs, edit box and docked chat windows).
	local position = generators.position(2, true,
		function(key) return self.config.position[key] end,
		function(key, value)
			self.config.position[key] = value
			self:ApplyHolder()
		end,
		self.holder
	)
	position.inline = false -- a tree section, not an inline box
	local validateForHolder = position.args.frame.validate
	position.args.frame.validate = function(info, name)
		local ok, err = st:ValidateAnchor(ChatFrame1, name)
		if not ok then return err end
		return validateForHolder(info, name)
	end

	local font = generators.font()
	font.order = 4

	return {
		name = 'Chat',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					local key = info[#info]
					self.config[key] = value
					if key == 'width' or key == 'height' then
						-- A profile without a size yet takes the other one from the chat frame.
						self:CaptureSize(true)
						self:ApplyHolder()
					else
						self:ApplyAppearance()
					end
				end,
				args = {
					-- Text boxes; the size is rounded to the pixel when it's applied.
					width = SizeInput(generators.width(1), MIN_WIDTH),
					height = SizeInput(generators.height(2), MIN_HEIGHT),
					template = generators.template(3),
					font = font,
					fontsize = generators.range(5, 'Font size', 8, 32, 1),
					padding = generators.range(6, 'Padding', 0, 30, 1),
					editbox_height = {
						order = 7,
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
						order = 8,
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
