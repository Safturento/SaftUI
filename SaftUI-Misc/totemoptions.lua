local st = SaftUI
local TB = st:GetModule('TotemBar')

-- The Totem Bar section in the /sui tree. Absent until the bar exists, so never shown
-- on retail. On a shaman it's General (these options, then the Position option), the
-- leaf group the edit mode mover's configPath opens. On other classes the bar has no
-- mover, and the section is these options alone.
function TB:GetConfigTable()
	if not self.bar then return end

	local generators = st.Config.generators

	-- Button size and Spacing (TB:ApplyButtonLayout), then the timers above the element
	-- buttons (totemtimers.lua), then Hide. /sui doesn't open in combat, so these always
	-- apply straight away.
	local buttonSize = generators.range(1, 'Button size', 20, 60, 1,
		"Every button on the bar, its border included. The totem choices that open above a button are 6 smaller, so the flyout is as wide as the button. Blizzard's are 30.")
	local buttonSpacing = generators.range(2, 'Spacing', 0, 20, 1, 'The gap between buttons.')

	local timerBar = generators.toggle(3, 'Show timer bar',
		"A bar above each element button that drains, in the element's colour, as that element's totem runs out. It turns red in the last 10 seconds.",
		'small')
	local timerText = generators.toggle(4, 'Show timer text',
		"How long each element's totem has left, above its button. It turns red in the last 10 seconds.",
		'small')

	-- Text alone sits just above the button either way, so this only matters with both on.
	local timerTextPosition = {
		order = 5,
		name = 'Text position',
		desc = 'Where the time goes while both the bar and the text show: above a thin bar, or on a taller one.',
		type = 'select',
		values = { above = 'Above the bar', on = 'On the bar' },
		sorting = { 'above', 'on' },
		disabled = function() return not (self.config.timer_bar and self.config.timer_text) end,
	}

	-- Offsets for the time, from the spot Text position puts it in.
	local timerTextX = generators.range(6, 'Text X offset', -20, 20, 1,
		'Moves the time left or right from the middle of its button, in pixels.')
	timerTextX.disabled = function() return not self.config.timer_text end
	local timerTextY = generators.range(7, 'Text Y offset', -20, 20, 1,
		'Moves the time up or down from where Text position puts it, in pixels. Moving it up also moves the flyout arrow up to make room.')
	timerTextY.disabled = function() return not self.config.timer_text end

	local timerBarHeight = generators.range(8, 'Timer bar height', 2, 20, 1,
		"The timer bar's height, its border included. It always leaves room for the bar inside its border, and with the text on the bar it's never shorter than the text needs.")
	timerBarHeight.disabled = function() return not self.config.timer_bar end

	local hide = generators.toggle(9, 'Hide totem bar',
		"Hides Blizzard's totem bar. Turning this off shows it again whenever Blizzard would show it. If the bar is on screen when you change this, it applies after a /reload.")

	local args = {
		button_size = buttonSize,
		button_spacing = buttonSpacing,
		timer_bar = timerBar,
		timer_text = timerText,
		timer_text_position = timerTextPosition,
		timer_text_x = timerTextX,
		timer_text_y = timerTextY,
		timer_bar_height = timerBarHeight,
		hide = hide,
		element_colors = { order = 10, type = 'header', name = 'Element colors' },
	}

	-- One color per element, in config.colors (read each time one is asked for, see
	-- TB:GetElementColor): the element's button border, its flyout choice and its timer
	-- bar. Setting one re-skins the buttons and redraws the timers at once.
	for i, element in ipairs({ 'earth', 'fire', 'water', 'air' }) do
		args['color_' .. element] = {
			order = 10 + i,
			name = element:sub(1, 1):upper() .. element:sub(2),
			desc = ('The %s totem: its button border, its choice in the flyout and its timer bar.'):format(element),
			type = 'color',
			size = 'small',
			get = function()
				local color = self.config.colors[element]
				return color[1], color[2], color[3]
			end,
			set = function(_, r, g, b)
				local color = self.config.colors[element]
				color[1], color[2], color[3] = r, g, b
				self:ApplySkin()
				self:ApplyTimerLayout()
			end,
		}
	end

	local general = {
		name = 'General',
		type = 'group',
		order = 1,
		get = function(info) return self.config[info[#info]] end,
		set = function(info, value)
			local key = info[#info]
			self.config[key] = value
			if key == 'hide' then
				self:Apply()
			elseif key == 'button_size' or key == 'button_spacing' then
				self:ApplyButtonLayout()
			else
				self:ApplyTimerLayout()
			end
		end,
		args = args,
	}

	if not self.holder then
		general.name = 'Totem Bar'
		general.order = nil
		return general
	end

	-- The holder's position (TB:ApplyHolder), last in General. A change saves the table
	-- GetPosition hands out, so a first change from the waiting spot saves a position too.
	local position = st.Config.generators.position(1000, true,
		function(key) return self:GetPosition()[key] end,
		function(key, value)
			local pos = self:GetPosition()
			pos[key] = value
			self.config.position = pos
			self:ApplyHolder()
		end,
		function() return self.holder end
	)
	-- The buttons go on the holder and the bar goes to its spot, so the holder anchored to
	-- any of them would be a loop, or the bar would chase the holder. Checked by parent as
	-- well as by st:ValidateAnchor's walk of the anchors: the bar itself is never anchored
	-- to the holder, and until the profile has a position the buttons aren't either, so the
	-- walk can't see either coming.
	local validate = position.validate
	position.validate = function(info, part, value)
		local frame = part == 'frame' and st:ResolveFrame(value)
		while frame do
			if frame == self.bar then
				return "The totem bar's position can't be anchored to the totem bar or its buttons."
			end
			frame = frame.GetParent and frame:GetParent()
		end
		return validate(info, part, value)
	end
	general.args.position = position

	return {
		name = 'Totem Bar',
		type = 'group',
		category = 'Combat', -- the /sui sidebar's group (optionslayout.lua)
		childGroups = 'tab',
		args = {
			general = general,
		},
	}
end
