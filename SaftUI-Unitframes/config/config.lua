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


-- The Copy from dialog: copies the ticked settings of another unit (in the
-- current unit frame profile) onto unit, after asking. SaftUI's options window
-- draws it as a small dialog (st.OptionsWindow:OpenDialog). The table is made
-- anew each time, so nothing carries over from the last unit.
-- The nameplates, enemy and friendly, are left out both ways (their pages have
-- no Copy from, and they're never offered here): the game places each plate
-- and gives every plate one size, Nameplates and Friendly plates change the
-- game's settings and need a reload, and a unit frame's layout doesn't fit a
-- plate's bar. Each nameplate page's box shares the other's look instead.
function UF:OpenCopyTable(unit)
	local copy = { from = nil, settings = {} }
	local settingArgs = {}
	for key in pairs(self:GetProfileConfig()[unit]) do
		copy.settings[key] = false
		settingArgs[key] = st.Config.generators.toggle(0, key,
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
				values = function()
					local units = {}
					-- The current profile's, in case the profile changed since opening
					for key in pairs(UF:GetProfileConfig()) do
						if key ~= unit and not UF.IsPlateUnit(key) then
							units[key] = key
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
				size = 'small',
				type = 'execute',
				func = function() SetAll(true) end,
			},
			toggle_none = {
				order = 1,
				name = 'None',
				desc = 'Clears every tick below.',
				size = 'small',
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
				type = 'execute',
				disabled = function() return not copy.from end,
				confirm = function()
					return 'Are you sure you want to clone ' .. unit .. ' from ' .. tostring(copy.from) .. '?'
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
		},
	}

	st.OptionsWindow:OpenDialog(function()
		return 'Clone ' .. unit .. (copy.from and (' from ' .. copy.from) or ' from..')
	end, options)
end

-- The units' order in /sui's unit picker (their keys are UF.unit_strings',
-- UF.group_strings' and the nameplates'); the page opens on the first. A unit
-- not listed sorts after these, and the Profile group (a negative order)
-- after everything.
local UNIT_ORDER = {}
for i, unit in ipairs({
	'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate',
}) do
	UNIT_ORDER[unit] = i
end

--[[
	The two nameplate pages (nameplates/): Enemy nameplates (the nameplate
	unit) and Friendly nameplates (friendlynameplate). Each has a box that
	draws its kind of plate with the other page's settings (UF.PlateConfigKey
	reads them).

	While a page's box is checked, the rest of the page is hidden, so nobody
	changes a setting that does nothing there. What stays: the on/off switches
	(Nameplates, Friendly plates), the box and the line under it, the
	stand-down line, and on the Enemy page threat (Threat when solo and the
	Threat tab), since threat is always the Enemy page's (threat.lua reads
	nameplate.threat). The hidden settings stay in the profile, so unchecking
	brings them back as they were. While one box is checked, the other page's
	is disabled, so both are never on, and a line under it says why. All of it
	is read from the profile at call time: a profile change replaces the
	tables.

	Per page: box, the box's key in the page's config; other, the other page;
	kept, the page's options (its tabs) that stay while the box is checked,
	and keptGeneral, General's; checked, the line under the box while it's
	checked, and otherChecked, while the other page's is.
]]
local PLATE_PAGES = {
	nameplate = {
		box = 'use_friendly',
		other = 'friendlynameplate',
		kept = { general = true, drawn_by = true, Threat = true },
		keptGeneral = { enable = true, threat_solo = true, use_friendly = true, box_note = true },
		checked = "Enemy nameplates use the Friendly nameplates page's settings, all but threat, which stays on this page.",
		otherChecked = "Friendly nameplates use this page's settings. To check this box, uncheck Use enemy nameplates' settings on the Friendly nameplates page.",
	},
	friendlynameplate = {
		box = 'use_enemy',
		other = 'nameplate',
		kept = { general = true, drawn_by = true },
		keptGeneral = { friendly = true, use_enemy = true, box_note = true },
		checked = "Friendly nameplates use the Enemy nameplates page's settings. They never show threat.",
		otherChecked = "Enemy nameplates use this page's settings, all but threat. To check this box, uncheck Use friendly nameplates' settings on the Enemy nameplates page.",
	},
}

local function PlateBoxChecked(unit)
	return UF:GetProfileConfig()[unit][PLATE_PAGES[unit].box] and true or false
end

-- While another nameplate addon draws the plates (UF:NameplateAddon), each
-- nameplate page says which, and every option on it is disabled. The line
-- sits on the page above the tabs, not in General: every tab is disabled then,
-- and the window chooses a disabled tab only when it was the tab chosen
-- already (st.OptionsModel), so a line in General would mostly not show.

-- The nameplate addon drawing the plates, or nil: UF:NameplateAddon
-- (nameplates/nameplates.lua), and nil where that isn't loaded, so the page
-- builds without it.
local function OtherNameplateAddon()
	return UF.NameplateAddon and UF:NameplateAddon() or nil
end

local function StandDown(config_table)
	local addon = OtherNameplateAddon()
	config_table.disabled = function() return OtherNameplateAddon() ~= nil end
	if not addon then return end
	config_table.args.drawn_by = {
		order = 0,
		name = ("Nameplates are drawn by %s. Turn it off to use SaftUI's."):format(addon),
		type = 'description',
		-- Read at full strength while everything under it is dimmed.
		disabled = false,
	}
end

-- Hides every option in args that kept doesn't name while unit's box is
-- checked.
local function HideWhileChecked(unit, args, kept)
	local function Checked() return PlateBoxChecked(unit) end
	for key, option in pairs(args) do
		if not kept[key] then option.hidden = Checked end
	end
end

-- A nameplate page's box (name, desc, at order), and the line under it, as
-- General's box and box_note.
local function PlateBox(unit, order, name, desc)
	local plate = PLATE_PAGES[unit]
	local box = st.Config.generators.toggle(order, name, desc)
	-- Disabled while the other page's box is checked and this one isn't (both
	-- checked, from a profile made elsewhere, leaves either free to uncheck),
	-- and while another addon draws the plates: an option's own disabled
	-- replaces the page's (StandDown), which it would otherwise inherit.
	box.disabled = function()
		return OtherNameplateAddon() ~= nil or (PlateBoxChecked(plate.other) and not PlateBoxChecked(unit))
	end
	-- A box moves one kind of plate to the other config, so every plate looks
	-- its config up again and the plates' size follows: UF:ApplyConfig's plate
	-- branch, which does the same for either plate key.
	box.set = function(_, value)
		UF:GetProfileConfig()[unit][plate.box] = value
		UF:UpdateConfig('nameplate')
	end
	local note = {
		order = order + 0.5,
		type = 'description',
		name = function()
			return PlateBoxChecked(unit) and plate.checked or plate.otherChecked
		end,
		hidden = function()
			return not (PlateBoxChecked(unit) or PlateBoxChecked(plate.other))
		end,
	}
	return box, note
end

--[[
	The Enemy nameplates page's General tab (the nameplate unit, nameplates/):
	the plates' own settings, read from the profile at call time. There's no
	Position, Layout or Range: the game places each plate and gives every plate
	one size (UF:ApplyPlateSize), which Width and Height set. Nameplates also
	changes the game's own nameplate settings (nameplates/cvars.lua). It's read
	once, at login (oUF makes its nameplate driver only once), so a change to it
	asks for a reload. Friendly plates is on the Friendly nameplates page.
]]
local function NameplateGeneral()
	local G = st.Config.generators
	local function Config() return UF:GetProfileConfig().nameplate end

	local enable = G.toggle(1, 'Nameplates',
		"Draws nameplates in SaftUI's look: enemies and neutral units, and friendly ones outside instances. Changes after a reload.", 'small')
	enable.set = function(_, value)
		Config().enable = value
		-- SaftUI's plates stay up until the reload: off, the game's settings go
		-- back now; on again, they're SaftUI's again (nothing until the plates
		-- are spawned, at the reload, when they were off at login).
		if value then
			UF:ApplyNameplateCVars()
		else
			UF:RestoreNameplateCVars()
		end
		st.OptionsWidgets.Confirm('Nameplates change after a reload. Reload now?', ReloadUI)
	end

	local box, note = PlateBox('nameplate', 3, "Use friendly nameplates' settings",
		"Draws enemy and neutral nameplates with the Friendly nameplates page's settings, and hides this page's other settings, which are kept for when it's unchecked. Threat when solo and the Threat tab stay, and still apply.")

	local args = {
		enable = enable,
		threat_solo = G.toggle(2, 'Threat when solo',
			"Tints enemy health bars by your threat while you're on your own too. In a party or raid they're always tinted.", 'small'),
		use_friendly = box,
		box_note = note,
		theme = G.theme(4, "How the border and background around each whole enemy nameplate are drawn. Its bars have their own, on their tabs."),
		background = G.background(4.5),
		width = G.width(5, "Enemy nameplates' width: the health bar and the area you click. The game stacks every nameplate at this size."),
		height = G.height(6, "Enemy nameplates' height: the health bar and the area you click. The game stacks every nameplate at this size."),
	}
	HideWhileChecked('nameplate', args, PLATE_PAGES.nameplate.keptGeneral)

	return {
		order = 0,
		name = 'General',
		type = 'group',
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			-- Re-applies every plate, and their size (UF:ApplyConfig).
			UF:UpdateConfig('nameplate')
		end,
		args = args,
	}
end

--[[
	The Friendly nameplates page's General tab (the friendlynameplate unit):
	the friendly plates' frame, at its own Width and Height, centred on its
	plate. Friendly plates, whether the game shows friendly plates at all, is
	the enemy config's friendly (nameplates/cvars.lua reads it there), and is
	here because it's about friendly plates.
]]
local function FriendlyNameplateGeneral()
	local G = st.Config.generators
	local function Config() return UF:GetProfileConfig().friendlynameplate end

	local friendly = G.toggle(1, 'Friendly plates',
		"Shows nameplates over friendly players and NPCs: SaftUI's outside instances, Blizzard's inside them. Off, friendly units have none.", 'small')
	friendly.get = function() return UF:GetProfileConfig().nameplate.friendly end
	friendly.set = function(_, value)
		UF:GetProfileConfig().nameplate.friendly = value
		UF:ApplyNameplateCVars()
	end

	local box, note = PlateBox('friendlynameplate', 2, "Use enemy nameplates' settings",
		"Draws friendly nameplates with the Enemy nameplates page's settings, and hides this page's other settings, which are kept for when it's unchecked. Friendly nameplates never show threat.")

	local args = {
		friendly = friendly,
		use_enemy = box,
		box_note = note,
		theme = G.theme(4, "How the border and background around each whole friendly nameplate are drawn. Its bars have their own, on their tabs."),
		background = G.background(4.5),
		width = G.width(5, "Friendly nameplates' width, centred on the plate: the area you click. While enemy nameplates use this page, the game stacks every nameplate at this size."),
		height = G.height(6, "Friendly nameplates' height, centred on the plate: the area you click. While enemy nameplates use this page, the game stacks every nameplate at this size."),
	}
	HideWhileChecked('friendlynameplate', args, PLATE_PAGES.friendlynameplate.keptGeneral)

	return {
		order = 0,
		name = 'General',
		type = 'group',
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			-- Re-applies every plate, and their size (UF:ApplyConfig).
			UF:UpdateConfig('friendlynameplate')
		end,
		args = args,
	}
end

function UF:GetConfigTable()
	local config = {
		name = 'Unitframes',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
		-- The units (and the Profile group) are the page's picker; each unit's
		-- elements are its tabs.
		childGroups = 'select',
		pickerLabel = 'Unit',
		args = {
			profile = UF.GenerateProfileConfigGroup(),
		}
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
			args = {
				copy = {
					name = 'Copy from',
					desc = "Copies chosen settings from another unit frame onto this one.",
					size = 'small',
					type = 'execute',
					func = function()
						UF:OpenCopyTable(unit)
					end,
					order = -99,
				},
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

		-- The nameplate pages (nameplates/, PLATE_PAGES): their own General, no
		-- Copy from (see UF:OpenCopyTable), and everything disabled while another
		-- nameplate addon draws the plates.
		local plate = PLATE_PAGES[unit]
		if plate then
			config_table.args.copy = nil
			if unit == 'nameplate' then
				config_table.name = 'Enemy nameplates'
				config_table.args.general = NameplateGeneral()
			else
				config_table.name = 'Friendly nameplates'
				config_table.args.general = FriendlyNameplateGeneral()
			end
			StandDown(config_table)
		end

		-- One tab per element the unit has (ValidUnit, as in UF.ConstructUnit).
		for element_name, element in pairs(UF.elements) do
			if element.GetConfigTable and (not element.ValidUnit or element.ValidUnit(unit)) then
				config_table.args[element_name] =
					element.GetConfigTable(unit)
			end
		end

		-- A nameplate page's tabs hide while its box is checked, but those it keeps.
		if plate then
			HideWhileChecked(unit, config_table.args, plate.kept)
		end

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