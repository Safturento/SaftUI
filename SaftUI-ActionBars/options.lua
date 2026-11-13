local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The action bars' edit mode movers and their /sui section.

	Movers. ab_bar1..ab_bar8, ab_pet and ab_stance move the bars themselves (the
	SaftUI_ActionBar1..8, SaftUI_PetBar and SaftUI_StanceBar headers), as the
	single unit frames' movers do. AB:LayoutBar sizes and places every bar, a
	disabled one too, one its Visibility setting hides, the pet bar without a
	pet and the stance bar without forms (laid out as one button), and the edit
	mode outline is anchored to the bar's edges, so the outline always covers
	the bar's whole layout. Its label says when a bar is off, has nothing to
	show (the stance bar's 'no forms'), is shown only in combat, or is faded.
	Drags and nudges write the bar's position, and AB:LayoutBar places it
	through st:SafeReposition: the bars are secure, so they can't be moved in
	combat. Clicking a bar opens its General tab.

	ab_extra, ab_zone and ab_vehicleleave move the extra buttons' holders
	(extras.lua), which always have a size. Their outlines say when the
	buttons show, as they mostly don't.

	/sui -> Action Bars has the Theme and Background options
	(actionbars.theme and .background, which every button is drawn with) and
	Cooldown numbers, Blizzard's own "Show Numbers for Cooldowns" (skin.lua:
	the game's setting, read and set as it is, never in the profile), then
	one picker entry ('Bar') per bar, each with tabs:
	  - General: enable, buttons (up to the bar's 12 or 10), buttons per row,
	    button size and spacing, and the Position option, last. The relative
	    frame typed there goes through st:ValidateAnchor with the bar, so a bar
	    can't be anchored to itself, its own buttons, or a bar anchored to it.
	  - Text: the hotkey, stack count, macro name and cooldown numbers, each
	    with show, font, size, outline, and a Position block with no TO part:
	    the text's point (THIS), the button's point it sits on (AT ITS) and the
	    offsets. The cooldown numbers have no show (Cooldown numbers, above,
	    shows them on every bar), their font, size and outline show what's
	    drawn until they're set (AB:GetCountdownFont), and their Reset unsets
	    those and puts their place back. The pet and stance bars
	    only have the hotkey and the cooldown numbers (AB.barTypes texts); the
	    extra buttons have no Text tab.
	  - Visibility: always, in combat only, or faded until moused over, with how
	    faded.
	Then one section per extra button, with General: Scale for Blizzard's extra
	action button and zone ability, Size for SaftUI's leave vehicle button, and
	the Position option.
	Every option applies at once through AB:UpdateBar (bars.lua), AB:LayoutExtra
	(extras.lua) or, for the Theme and Background, AB:UpdateConfig (which
	re-skins every bar and the leave vehicle button, skin.lua's StyleBar
	reading actionbars.theme and .background). /sui can't be open in combat,
	so none of this runs in combat lockdown; a profile switch in combat waits
	for the end of combat (AB:UpdateConfig).
]]

local VISIBILITY_VALUES = {
	always = 'Always',
	combat = 'In combat only',
	mouseover = 'Faded until moused over',
}
local VISIBILITY_ORDER = { 'always', 'combat', 'mouseover' }

-- The second line of a bar's outline label, for each way a bar can be hidden.
local HIDDEN_LABELS = {
	combat = 'in combat',
	mouseover = 'mouseover',
}

-- The second line of each extra button's outline label: when it's on screen.
local EXTRA_NOTES = {
	extra = 'when active',
	zone = 'when active',
	vehicleleave = 'vehicles, flights, possess',
}

-- The extra buttons that are Blizzard's, sized by a Scale setting. The others
-- (SaftUI's leave vehicle button) have a Size setting.
local SCALED_EXTRAS = {
	extra = true,
	zone = true,
}

-- Every text setting of a button, in the order of the Text tab: its key in the
-- bar's text table, and its name.
local TEXTS = {
	{ 'hotkey', 'Hotkey' },
	{ 'count', 'Stack count' },
	{ 'macro', 'Macro name' },
	{ 'countdown', 'Cooldown numbers' },
}

function AB:GetBarLabel(id)
	return self.BAR_LABELS[id] or id
end

------------------------------------
--- Movers --------------------------
------------------------------------

-- The bar's name on its outline, and on a second line why it may not be seen:
-- off, nothing to show, only in combat, or faded.
function AB:UpdateMoverLabel(id)
	local mover = self.movers[id]
	local config = self.config[id]
	if not (mover and mover.label and config) then return end
	local state
	if not config.enable then
		state = 'off'
	elseif not self:IsBarAvailable(id) then
		state = self.barTypes[id].unavailableLabel
	else
		state = HIDDEN_LABELS[config.visibility]
	end
	mover.label:SetText(self:GetBarLabel(id) .. (state and ('\n' .. state) or ''))
end

-- Once per bar, when the bars are built (AB:Build).
function AB:RegisterBarMover(id)
	local bar = self.bars[id]
	if not bar or self.movers[id] then return end
	self.movers[id] = st:RegisterConfigMover(bar, {
		key = 'ab_' .. id,
		label = self:GetBarLabel(id),
		-- Read through self.config on every call: a profile change replaces it.
		config = function() return self.config[id] end,
		apply = function() self:LayoutBar(id) end,
		configPath = { 'ActionBars', id, 'general' },
	})
	self:UpdateMoverLabel(id)
end

-- Once per extra button, when they're set up (AB:SetupExtras). The holder
-- always has the button's size, so the outline shows where it will be.
function AB:RegisterExtraMover(id)
	local holder = self.extras[id]
	if not holder or self.movers[id] then return end
	self.movers[id] = st:RegisterConfigMover(holder, {
		key = 'ab_' .. id,
		label = self.EXTRA_LABELS[id] .. '\n' .. EXTRA_NOTES[id],
		-- Read through self.config on every call: a profile change replaces it.
		config = function() return self.config[id] end,
		apply = function() self:LayoutExtra(id) end,
		configPath = { 'ActionBars', id, 'general' },
	})
end

------------------------------------
--- /sui ----------------------------
------------------------------------

-- What each text is, for its tooltips.
-- The titles of the texts' Position sections: the Text tab has one for each.
local TEXT_POSITION_NAMES = {
	hotkey = 'Hotkey position',
	count = 'Count position',
	macro = 'Macro position',
	countdown = 'Numbers position',
}

local TEXT_DESCS = {
	hotkey = 'the key bound to the button',
	count = "the button's stack or charge count",
	macro = "a macro button's name",
	countdown = 'the cooldown numbers',
}

-- The cooldown numbers' section note, and what their Font, Size and Outline
-- add: what's drawn until they're set (AB:GetCountdownFont).
local COUNTDOWN_NOTE = "Cooldown numbers, at the top of this page, shows or hides them on every bar (Blizzard's own setting)."
local COUNTDOWN_UNSET = " Until set here, Pixel Med's on buttons of 36px and up and Pixel's below (Global Settings > Fonts)."

-- What the cooldown numbers' Reset puts back: their place, from the bar's
-- defaults, while their font, size and outline go back to unset.
local COUNTDOWN_PLACE = { 'point', 'rel_point', 'x_off', 'y_off' }

-- One text's options (hotkey, count, macro name or cooldown numbers), a box in
-- the Text tab. Its Position block has no TO part: the text sits inside its
-- own button. It reads and writes the text's point, rel_point, x_off and y_off,
-- and goes last. The cooldown numbers have no Show, their Font, Size and
-- Outline read what's drawn until they're set, and a Reset before the Position
-- block unsets those three and puts the place back (see the top).
function AB:GetTextOptions(id, kind, name, order)
	local generators = st.Config.generators
	local what = TEXT_DESCS[kind]
	local options = {
		name = name,
		type = 'group',
		inline = true,
		order = order,
		get = function(info) return self.config[id].text[kind][info[#info]] end,
		set = function(info, value)
			self.config[id].text[kind][info[#info]] = value
			self:UpdateBar(id)
		end,
		args = {
			show = generators.toggle(1, 'Show', 'Show ' .. what .. ' on the buttons.', 'small'),
			font = {
				order = 2,
				name = 'Font',
				desc = 'The font of ' .. what .. '.',
				type = 'select',
				dialogControl = 'LSM30_Font',
				values = st.LSM:HashTable('font'),
			},
			size = generators.range(3, 'Size', 6, 32, 1, 'The size of ' .. what .. ', in points.'),
			outline = {
				order = 4,
				name = 'Outline',
				desc = 'The outline drawn around ' .. what .. '.',
				type = 'select',
				values = st:GetModule('Fonts').outlines,
			},
			position = generators.position(5, false,
				function(key) return self.config[id].text[kind][key] end,
				function(key, value)
					self.config[id].text[kind][key] = value
					self:UpdateBar(id)
				end,
				nil,
				'Where ' .. what .. ' sits on the button: the point of the text that is anchored (THIS), the point of the button it is anchored to (AT ITS), and how far it is moved from there.',
				TEXT_POSITION_NAMES[kind]
			),
		},
	}
	if kind == 'countdown' then
		options.desc = COUNTDOWN_NOTE
		options.args.show = nil
		for _, key in ipairs({ 'font', 'size', 'outline' }) do
			options.args[key].desc = options.args[key].desc .. COUNTDOWN_UNSET
		end
		options.args.position.desc = 'Where the cooldown numbers sit on the button: the point of the numbers that is anchored (THIS), the point of the button it is anchored to (AT ITS), and how far they are moved from there.'
		options.get = function(info)
			local font, size, outline = self:GetCountdownFont(self.config[id])
			return ({ font = font, size = size, outline = outline })[info[#info]]
		end
		options.args.reset = {
			type = 'execute',
			size = 'small',
			order = 4.5,
			name = 'Reset',
			desc = "Puts the cooldown numbers' font, size, outline and place back to SaftUI's default: Pixel Med on buttons of 36px and up and Pixel below, following Global Settings > Fonts, in the middle of the button.",
			confirm = true,
			confirmText = ("Reset %s's cooldown numbers to SaftUI's defaults?"):format(self:GetBarLabel(id)),
			func = function()
				local countdown = self.config[id].text.countdown
				countdown.font, countdown.size, countdown.outline = nil, nil, nil
				local default = st.defaults.actionbars[id].text.countdown
				for _, key in ipairs(COUNTDOWN_PLACE) do
					countdown[key] = default[key]
				end
				self:UpdateBar(id)
			end,
		}
	end
	return options
end

-- One bar's section: General (Position last), Text and Visibility tabs. The
-- ranges go up to the bar's own number of buttons, and the Text tab has the
-- texts its buttons use.
function AB:GetBarOptions(id, order)
	local generators = st.Config.generators
	local numButtons = #self.bars[id].buttons
	local barType = self.barTypes[id]

	local texts = {}
	local used = barType and barType.texts
	for i, text in ipairs(TEXTS) do
		local kind, name = text[1], text[2]
		if not used or used[kind] then
			texts[kind] = self:GetTextOptions(id, kind, name, i)
		end
	end

	-- Options of the bar's own table (General and Visibility).
	local get = function(info) return self.config[id][info[#info]] end
	local set = function(info, value)
		self.config[id][info[#info]] = value
		self:UpdateBar(id)
	end

	-- Every SetPoint parameter is editable, the relative frame included. Passing
	-- the bar makes a typed frame go through st:ValidateAnchor. Last in General.
	local position = generators.position(1000, true,
		function(key) return self.config[id].position[key] end,
		function(key, value)
			self.config[id].position[key] = value
			self:LayoutBar(id)
		end,
		self.bars[id]
	)

	local enable = generators.enable(1, 'A disabled bar is hidden and its keys do nothing.')
	enable.size = 'small'

	local buttonsDesc = ('How many of the bar\'s %d buttons it shows. The keys of the others do nothing.'):format(numButtons)
	if barType and barType.buttonsNote then
		buttonsDesc = buttonsDesc .. ' ' .. barType.buttonsNote
	end
	local buttons = generators.range(2, 'Buttons', 1, numButtons, 1, buttonsDesc)

	local perrow = generators.range(3, 'Buttons per row', 1, numButtons, 1,
		'How many buttons sit in a row before the next row starts. 1 makes a column.')

	local size = generators.range(4, 'Button size', 16, 80, 1, 'The whole button, its border included.')

	local spacing = generators.range(5, 'Spacing', 0, 20, 1, 'The gap between buttons.')

	local fade = generators.range(2, 'Faded opacity', 0, 1, 0.05,
		"How visible the bar is while the mouse isn't over it.")
	fade.hidden = function() return self.config[id].visibility ~= 'mouseover' end

	return {
		name = self:GetBarLabel(id),
		type = 'group',
		order = order,
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = get,
				set = set,
				args = {
					enable = enable,
					buttons = buttons,
					perrow = perrow,
					size = size,
					spacing = spacing,
					position = position,
				},
			},
			text = {
				name = 'Text',
				type = 'group',
				order = 2,
				args = texts,
			},
			visibility = {
				name = 'Visibility',
				type = 'group',
				order = 3,
				get = get,
				set = set,
				args = {
					visibility = {
						order = 1,
						name = 'Show',
						desc = 'Keybind mode (/sui kb) shows every enabled bar while it\'s on.',
						type = 'select',
						values = VISIBILITY_VALUES,
						sorting = VISIBILITY_ORDER,
					},
					fade_alpha = fade,
				},
			},
		},
	}
end

-- One extra button's section: General with its Scale or Size, then the
-- Position option.
function AB:GetExtraOptions(id, order)
	local generators = st.Config.generators

	local size
	if SCALED_EXTRAS[id] then
		size = generators.range(1, 'Scale', 0.5, 2, 0.05,
			"The size of Blizzard's button and the art around it. 100% is Blizzard's size.")
		size.isPercent = true
	else
		size = generators.range(1, 'Button size', 16, 80, 1, 'The whole button, its border included.')
	end

	-- Every SetPoint parameter is editable, the relative frame included. Passing
	-- the holder makes a typed frame go through st:ValidateAnchor, which rejects
	-- what's anchored to the holder (the extra action button) too.
	local position = generators.position(1000, true,
		function(key) return self.config[id].position[key] end,
		function(key, value)
			self.config[id].position[key] = value
			self:LayoutExtra(id)
		end,
		self.extras[id]
	)

	return {
		name = self.EXTRA_LABELS[id],
		type = 'group',
		order = order,
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[id][info[#info]] end,
				set = function(info, value)
					self.config[id][info[#info]] = value
					self:LayoutExtra(id)
				end,
				args = {
					[SCALED_EXTRAS[id] and 'scale' or 'size'] = size,
					position = position,
				},
			},
		},
	}
end

-- The Action Bars section of /sui: one section per bar, then one per extra
-- button. Clicking one in edit mode selects its General tab (the mover's
-- configPath). Absent until the bars are built.
function AB:GetConfigTable()
	if not self.built then return end
	local generators = st.Config.generators
	local args = {}
	-- The Theme and Background of every bar button and of the leave vehicle
	-- button. skin.lua reads them each time a bar is styled, so AB:UpdateConfig
	-- (every bar, then the extras) applies them at once; it waits for the end of
	-- combat if need be.
	args.theme = generators.theme(0, 'The border of every action button, the leave vehicle button too.')
	args.background = generators.background(0.5)
	for key in pairs({ theme = true, background = true }) do
		args[key].get = function() return self.config[key] end
		args[key].set = function(_, value)
			self.config[key] = value
			self:UpdateConfig()
		end
	end
	-- Blizzard's own setting, read and set at call time, so this and Blizzard's
	-- option are one and the profile keeps nothing (skin.lua). Every bar
	-- follows a change at once.
	args.countdown = {
		order = 1,
		type = 'toggle',
		name = 'Cooldown numbers',
		desc = "Show the time left on a button's cooldown, on every bar. This is Blizzard's own Show Numbers for Cooldowns (Options > Gameplay > Action Bars), so it changes there too, and SaftUI's profiles don't keep it. Each bar's Text tab sets the numbers' font and place.",
		get = function() return self:ShowsCooldownNumbers() end,
		set = function(_, value) self:SetShowCooldownNumbers(value) end,
	}
	for i, id in ipairs(self.BAR_IDS) do
		if self.bars[id] then
			args[id] = self:GetBarOptions(id, i)
		end
	end
	for i, id in ipairs(self.EXTRA_IDS) do
		if self.extras[id] then
			args[id] = self:GetExtraOptions(id, #self.BAR_IDS + i)
		end
	end
	return {
		name = 'Action Bars',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
		-- The bars and extra buttons are the page's picker; each one's General,
		-- Text, ... are its tabs.
		childGroups = 'select',
		pickerLabel = 'Bar',
		args = args,
	}
end
