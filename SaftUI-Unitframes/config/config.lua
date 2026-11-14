local st = SaftUI
local UF = st:GetModule('Unitframes')

-- One spawned frame of a config unit, for its options to look at: the unit's
-- frame, boss (or arena) 1, a party or raid group's first button, or, for
-- either nameplate page, the frame on the plate with the lowest number
-- (nameplates/nameplates.lua). nil while a group has no buttons, or no plate
-- has had a unit yet.
function UF:GetConfigFrame(unit)
	if UF.IsPlateUnit(unit) then
		local lowest
		for id in pairs(self.nameplates or {}) do
			if not lowest or id < lowest then lowest = id end
		end
		return lowest and self.nameplates[lowest] or nil
	end
	local frame = self.units and self.units[unit]
	if frame then
		-- boss and arena are a list of five frames.
		return frame.GetConfig and frame or frame[1]
	end
	local header = self.groups and self.groups[unit]
	if header then
		for i = 1, header:GetNumChildren() do
			local child = select(i, header:GetChildren())
			if child and child.GetConfig then
				return child
			end
		end
	end
end

-- The target of an element's Position editor (generators.uf_element_position):
-- a function returning the element (or the text or icon at element[key]) on
-- UF:GetConfigFrame(unit), or nil. Looked up on every call, as group buttons
-- come and go.
function UF:ConfigTarget(unit, element, key)
	return function()
		local frame = self:GetConfigFrame(unit)
		local target = frame and frame[element]
		if target and key then
			target = target[key]
		end
		return target
	end
end

-- An element's size (UF:UpdateElementSize), on one line: Width and its
-- Relative, Height and its Relative. Untitled, so it reads as part of the
-- options above it.
function UF.GenerateRelativeSizeConfigGroup(order)
	local G = st.Config.generators
	local width = G.width(1, "The width in pixels. With Relative on, it's added to the unit frame's width: 0 is as wide as the unit frame, -4 is 4 narrower.")
	width.size = 'small'
	local height = G.height(3, "The height in pixels. With Relative on, it's added to the unit frame's height: 0 is as tall as the unit frame, -4 is 4 shorter.")
	height.size = 'small'
	return {
		order = order,
		name = '',
		type = 'group',
		inline = true,
		args = {
			width = width,
			relative_width = G.toggle(2, 'Relative', 'Width follows the unit frame: it is added to the unit frame\'s width.', 'small'),
			height = height,
			relative_height = G.toggle(4, 'Relative', 'Height follows the unit frame: it is added to the unit frame\'s height.', 'small'),
		},
	}
end

-- What each config unit's frames show, for the options that only work on
-- some kinds of unit. Player shows you, pet your pet, boss frames bosses,
-- party and raid frames players (party AI followers count as players, as oUF
-- counts them), and nameplates any unit but an offline player (the game shows
-- no plate for one): either page's, since each page's box can draw the other
-- kind with it. Any other unit (target, focus and their targets, the pet's
-- target) can show anything. The kinds:
--   players  a player (oUF's UnitIsPlayer or UnitInPartyIsAI)
--   npcs     anything that isn't a player, pets too
--   pets     a unit a player controls that isn't a player
--   mobs     an NPC no player controls: tapped, rare, elite or skull level
--   offline  a player who can be offline
local UNIT_SHOWS = {
	player = { players = true },
	pet = { npcs = true, pets = true },
	boss = { npcs = true, mobs = true },
	party = { players = true, offline = true },
	raid10 = { players = true, offline = true },
	raid40 = { players = true, offline = true },
	nameplate = { players = true, npcs = true, pets = true, mobs = true },
	friendlynameplate = { players = true, npcs = true, pets = true, mobs = true },
}

-- Whether unit's frames can ever show a unit of kind (above).
function UF.CanShow(unit, kind)
	local shows = UNIT_SHOWS[unit]
	return not shows or shows[kind] or false
end

-- oUF's color flags, as its health and power elements check them: the
-- option's name and desc, and the kind of unit it needs (UF.CanShow), if any.
local COLOR_FLAGS = {
	colorDisconnected = { name = 'Disconnected', shows = 'offline',
		desc = 'Grey while the unit is offline.' },
	colorTapping = { name = 'Tapped', shows = 'mobs',
		desc = "Grey while someone else has tagged the unit, so it won't give you loot or experience." },
	colorPower = { name = 'Power type',
		desc = 'By the power the bar shows: blue for mana, red for rage, yellow for energy and so on.' },
	colorClass = { name = 'Class', shows = 'players',
		desc = 'Players in their class color.' },
	colorClassNPC = { name = 'NPC class', shows = 'npcs',
		desc = "Units that aren't players, pets included, in their class color." },
	colorClassPet = { name = 'Pet class', shows = 'pets',
		desc = "Pets and other units players control, in their class color." },
	colorReaction = { name = 'Reaction',
		desc = 'By how the unit stands with you: red when hostile, yellow when neutral, green when friendly.' },
	colorSmooth = { name = 'Gradient',
		desc = 'From red at low health through yellow to green at full health.' },
	colorHealth = { name = 'Health color',
		desc = 'Plain green, for when none of the colors above fits.' },
}

--[[
	A bar's Colors section (health, power, additional power): the color flags
	in flags' order, which is the order oUF checks them in, then Custom and
	its color on a line of their own (an untitled group, args.custom). A flag
	the unit's frames never show the kind of unit for (UF.CanShow) is left
	out. The toggles read and write the element's config through the tab's
	get and set; descs overrides a flag's desc. config() returns the
	element's config, and update() re-applies it.
]]
function UF.GenerateColorsConfigGroup(order, unit, flags, config, update, descs)
	local G = st.Config.generators
	local args, i = {}, 0
	for _, key in ipairs(flags) do
		local flag = COLOR_FLAGS[key]
		if not flag.shows or UF.CanShow(unit, flag.shows) then
			i = i + 1
			args[key] = G.toggle(i, flag.name, descs and descs[key] or flag.desc, 'small')
		end
	end
	args.custom = {
		order = i + 1,
		name = '',
		type = 'group',
		inline = true,
		args = {
			colorCustom = G.toggle(1, 'Custom', 'Colors the bar with Custom color, over every color above.', 'small'),
			-- customColor is a { r, g, b } list in the defaults, and can be a
			-- color object in a saved profile (UF.UnpackColor reads both); it's
			-- written in the shape it has.
			customColor = {
				order = 2,
				name = 'Custom color',
				desc = 'The color Custom gives the bar.',
				type = 'color',
				size = 'small',
				get = function() return UF.UnpackColor(config().customColor) end,
				set = function(_, r, g, b)
					local color = config().customColor
					if type(color) == 'table' and color.GetRGB then
						color.r, color.g, color.b = r, g, b
					else
						color[1], color[2], color[3] = r, g, b
					end
					update()
				end,
			},
		},
	}
	return {
		order = order,
		name = 'Colors',
		desc = 'The bar takes the first of these that fits the unit, in this order.',
		type = 'group',
		inline = true,
		args = args,
	}
end


-- A unit's name, as its page in /sui is named.
local function UnitName(unit)
	return UF.unit_strings[unit] or UF.group_strings[unit] or unit
end

-- What Copy from calls the parts of a unit frame no page in /sui names (no
-- element registers a tab for them).
local COPY_NAMES = {
	aurawatch = 'Aura watch',
	portrait = 'Portrait',
}

-- A key's name made from the key itself, for one nothing else names: its
-- words apart and in sentence case ('range_alpha', 'growthDirection').
local function KeyName(key)
	local words = tostring(key):gsub('_', ' '):gsub('(%l)(%u)', '%1 %2'):lower()
	return (words:gsub('^%l', string.upper))
end

-- What Copy from calls each key of a unit's config: the name /sui shows for
-- that part, read from the unit frames' pages (the units' own page first,
-- then the others by key; never a nameplate page's, which Copy from leaves
-- out): an element's tab by its key in lower case (the config's key for it),
-- and General's options, sections and the options in them by their keys
-- (Layout's settings, the Range section). Then COPY_NAMES, else KeyName.
local function CopyNames(self, unit)
	local names = {}
	local function Add(key, name)
		if names[key] == nil and type(key) == 'string' and type(name) == 'string' and name ~= '' then
			names[key] = name
		end
	end
	local function AddGeneral(args)
		for key, option in pairs(args) do
			Add(key, option.name)
			if option.type == 'group' and type(option.args) == 'table' then AddGeneral(option.args) end
		end
	end
	local pages = self:GetConfigTable().args
	local order = {}
	for key in pairs(pages) do
		if key ~= unit and not UF.IsPlateUnit(key) then order[#order + 1] = key end
	end
	table.sort(order)
	table.insert(order, 1, unit)
	for _, key in ipairs(order) do
		for tabKey, tab in pairs(pages[key] and pages[key].args or {}) do
			if tabKey == 'general' then AddGeneral(tab.args or {}) else Add(tabKey:lower(), tab.name) end
		end
	end
	return setmetatable(names, { __index = function(_, key) return COPY_NAMES[key] or KeyName(key) end })
end

-- The Copy from dialog: copies the ticked settings of another unit (in the
-- current unit frame profile) onto unit, after asking. SaftUI's options window
-- draws it as a small dialog (st.OptionsWindow:OpenDialog). The table is made
-- anew each time, so nothing carries over from the last unit. Each setting is
-- named as /sui names that part elsewhere (CopyNames), and they sort by that
-- name; the units are named as their pages are. Copy from takes
-- a line of its own, so its label has room, with All and None at the line's
-- right end; Confirm copy and Cancel are a pair in the middle of the last
-- line, as Blizzard's popup dialogs place their buttons (align, the options
-- body's line of buttons).
-- The nameplates, enemy and friendly, are left out both ways (their pages have
-- no Copy from, and they're never offered here): the game places each plate
-- and gives every plate one size, Nameplates and Friendly plates change the
-- game's settings and need a reload, and a unit frame's layout doesn't fit a
-- plate's bar. Each nameplate page's box shares the other's look instead.
function UF:OpenCopyTable(unit)
	local copy = { from = nil, settings = {} }
	local settingArgs = {}
	local names = CopyNames(self, unit)
	for key in pairs(self:GetProfileConfig()[unit]) do
		copy.settings[key] = false
		settingArgs[key] = st.Config.generators.toggle(0, names[key],
			'Copies this setting from the other unit frame onto this one.')
	end
	local function SetAll(value)
		for key in pairs(copy.settings) do copy.settings[key] = value end
	end

	local options = {
		name = 'Copy from',
		type = 'group',
		args = {
			copy_from = {
				order = 0,
				name = 'Copy from',
				desc = 'The unit frame to copy settings from.',
				type = 'select',
				size = 'wide',
				values = function()
					local units = {}
					-- The current profile's, in case the profile changed since opening
					for key in pairs(UF:GetProfileConfig()) do
						if key ~= unit and not UF.IsPlateUnit(key) then
							units[key] = UnitName(key)
						end
					end
					return units
				end,
				get = function() return copy.from end,
				set = function(_, from) copy.from = from end,
			},
			toggle_all = {
				order = 1,
				name = 'All',
				desc = 'Ticks every setting below.',
				align = 'right',
				type = 'execute',
				func = function() SetAll(true) end,
			},
			toggle_none = {
				order = 1,
				name = 'None',
				desc = 'Clears every tick below.',
				align = 'right',
				type = 'execute',
				func = function() SetAll(false) end,
			},
			settings = {
				order = -99,
				name = 'Settings',
				type = 'group',
				inline = true,
				get = function(info) return copy.settings[info[#info]] end,
				set = function(info, value) copy.settings[info[#info]] = value end,
				args = settingArgs,
			},
			accept = {
				order = -95,
				name = 'Confirm copy',
				desc = 'Copies the ticked settings onto this unit frame, after asking.',
				align = 'center',
				type = 'execute',
				disabled = function() return not copy.from end,
				confirm = function()
					return 'Are you sure you want to copy the ticked settings to ' .. UnitName(unit)
						.. ' from ' .. UnitName(copy.from) .. '?'
				end,
				func = function()
					local profile = UF:GetProfileConfig()
					for key, ticked in pairs(copy.settings) do
						if ticked then
							local value = profile[copy.from][key]
							if type(value) == 'table' then
								profile[unit][key] = st.tablecopy(value, true)
							else
								profile[unit][key] = value
							end
						end
					end
					UF:UpdateConfig()
					st.Config:Refresh()
					st.OptionsWindow:CloseDialog()
				end,
			},
			cancel = {
				order = -94,
				name = 'Cancel',
				desc = 'Closes Copy from without copying anything.',
				align = 'center',
				type = 'execute',
				func = function() st.OptionsWindow:CloseDialog() end,
			},
		},
	}

	st.OptionsWindow:OpenDialog(function()
		return 'Copy to ' .. UnitName(unit) .. ' from' .. (copy.from and (' ' .. UnitName(copy.from)) or '')
	end, options)
end

-- The units' order in /sui's unit picker (their keys are UF.unit_strings',
-- UF.group_strings' and the nameplates'); the page opens on the first. A unit
-- not listed sorts after these.
local UNIT_ORDER = {}
for i, unit in ipairs({
	'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate',
}) do
	UNIT_ORDER[unit] = i
end

function UF:GetConfigTable()
	local config = {
		name = 'Unitframes',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
		-- The units are the page's picker; each unit's elements are its tabs.
		childGroups = 'select',
		pickerLabel = 'Unit',
		-- The unit frame profile, in /sui's footer while the page is open
		-- (SaftUI's footer field; config/profiles.lua).
		footer = UF.GenerateProfileFooter(),
		args = {},
	}

	local function GetUnitConfig(unit)
		if not unit then return end

		-- Looked up on every get/set: a profile change replaces these tables.
		local function UnitConfig() return UF:GetProfileConfig()[unit] end

		local function frame_position_set(key, value)
			UnitConfig().position[key] = value
			UF:UpdateConfig(unit)
		end
		local function frame_position_get(key)
			return UnitConfig().position[key]
		end

		local config_table = {
			name = self.unit_strings[unit] or self.group_strings[unit] or unit,
			order = UNIT_ORDER[unit],
			type = 'group',
			inline = false,
			-- Elements (General, Health, Name, Power, ...) as tabs, not a dropdown.
			childGroups = 'tab',
			-- Copy from, on the picker's line right of the Unit dropdown, so it's
			-- there from every tab (Core's pickerControl field). A nameplate
			-- page has none (UF.SetUpPlatePage).
			pickerControl = {
				type = 'group',
				name = '',
				args = {
					copy = {
						order = 1,
						name = 'Copy from',
						desc = "Copies chosen settings from another unit frame onto this one.",
						type = 'execute',
						func = function()
							UF:OpenCopyTable(unit)
						end,
					},
				},
			},
			args = {
				-- Clicking the unit's frame in edit mode selects this group (the
				-- mover's configPath, UF:RegisterMovers).
				general = {
					order = 0,
					name = 'General',
					type = 'group',
					get = function(info)
						return UnitConfig()[info[#info]]
					end,
					set = function(info, value)
						UnitConfig()[info[#info]] = value
						UF:UpdateConfig(unit)
					end,
					args = {
						-- A half, so Theme sits beside it with no empty quarter
						-- between (as Class power's).
						enable = st.Config.generators.enable(0, 'Shows this unit frame. When off, the unit frame is hidden.'),
						theme = st.Config.generators.theme(1, "How this unit frame's border and background are drawn."),
						background = st.Config.generators.background(1.5),
						width = st.Config.generators.width(2, "The unit frame's width."),
						height = st.Config.generators.height(3, "The unit frame's height."),
						-- Every SetPoint parameter, the relative frame included.
						-- Passing the mover's frame makes a typed frame go through
						-- st:ValidateAnchor, which rejects the frame itself and
						-- anything anchored back to it (e.g. Pet for Player).
						-- Last in General, after a group's Layout too.
						position = st.Config.generators.position(1000, true, frame_position_get, frame_position_set,
							self:GetMoverFrame(unit)),
					}
				}
			}
		}

		-- Party's, the raid groups' and boss's own General options
		-- (groupoptions.lua).
		self:AddGroupOptions(unit, config_table)

		-- The nameplate pages (nameplates/options.lua): their own General, no
		-- Copy from (see UF:OpenCopyTable), and everything disabled while another
		-- nameplate addon draws the plates.
		UF.SetUpPlatePage(unit, config_table)

		-- One tab per element the unit has (ValidUnit, as in UF.ConstructUnit).
		for element_name, element in pairs(UF.elements) do
			if element.GetConfigTable and (not element.ValidUnit or element.ValidUnit(unit)) then
				config_table.args[element_name] =
					element.GetConfigTable(unit)
			end
		end

		-- A nameplate page's tabs are disabled while its box is checked, but
		-- those it keeps.
		UF.DisablePlatePageTabs(unit, config_table)

		return config_table
	end

	for unit,frame in pairs(self.units) do
		config.args[unit] = GetUnitConfig(unit)
	end

	for unit in pairs(self.groups or {}) do
		config.args[unit] = GetUnitConfig(unit)
	end

	-- Always there, whether SaftUI draws the plates or not: their pages turn
	-- them on, or say which addon draws them.
	config.args.nameplate = GetUnitConfig('nameplate')
	config.args.friendlynameplate = GetUnitConfig('friendlynameplate')

	return config
end