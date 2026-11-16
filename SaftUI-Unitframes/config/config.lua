local st = SaftUI
local UF = st:GetModule('Unitframes')

-- One spawned frame of a config unit, for its options to look at: the unit's
-- frame, boss (or arena) 1, a party or raid group's first button, or, for
-- either nameplate page, the frame on the plate with the lowest number
-- (nameplates/nameplates.lua) that draws from that page's config (its
-- base_unit), else the lowest plate of either kind. nil while a group has no
-- buttons, or no plate has had a unit yet.
function UF:GetConfigFrame(unit)
	if UF.IsPlateUnit(unit) then
		local lowest, lowestOfPage
		for id, frame in pairs(self.nameplates or {}) do
			if not lowest or id < lowest then lowest = id end
			if frame.base_unit == unit and (not lowestOfPage or id < lowestOfPage) then lowestOfPage = id end
		end
		local id = lowestOfPage or lowest
		return id and self.nameplates[id] or nil
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
-- come and go. Its second return is the page's config unit, which the editor's
-- check reads the anchors of (UF.PlatePartAnchors): a plate's frame can draw
-- from the other page's config.
function UF:ConfigTarget(unit, element, key)
	local target = function()
		local frame = self:GetConfigFrame(unit)
		local part = frame and frame[element]
		if part and key then
			part = part[key]
		end
		return part, unit
	end
	-- What it was made for, so All units' Position can ask each follower's own frame (sharedoptions.lua).
	self.targetSpecs = self.targetSpecs or setmetatable({}, { __mode = 'k' })
	self.targetSpecs[target] = { element = element, key = key }
	return target
end

-- An element's size (UF:UpdateElementSize), on one line: Width and its
-- Relative, Height and its Relative. Untitled, so it reads as part of the
-- options above it. The Width and Height boxes have a get that hands on to the
-- element group's, and the reset kit reads their saved from that group.
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
-- status marks a grey the bar wears only in a state (offline, tapped), which
-- isn't what the bar normally falls back to. covers is the kinds of unit a
-- color is for (UF.CanShow's players, npcs, pets); none means every kind.
local COLOR_FLAGS = {
	colorDisconnected = { name = 'Disconnected', shows = 'offline', status = true,
		desc = 'Grey while the unit is offline.' },
	colorTapping = { name = 'Tapped', shows = 'mobs', status = true,
		desc = "Grey while someone else has tagged the unit, so it won't give you loot or experience." },
	colorPower = { name = 'Power type',
		desc = 'By the power the bar shows: blue for mana, red for rage, yellow for energy and so on.' },
	colorClass = { name = 'Class', shows = 'players', covers = { players = true },
		desc = 'Players in their class color.' },
	colorClassNPC = { name = 'NPC class', shows = 'npcs', covers = { npcs = true, pets = true },
		desc = "Units that aren't players, pets included, in their class color." },
	colorClassPet = { name = 'Pet class', shows = 'pets', covers = { pets = true },
		desc = "Pets and other units players control, in their class color." },
	colorReaction = { name = 'Reaction',
		desc = 'By how the unit stands with you: red when hostile, yellow when neutral, green when friendly.' },
	colorSmooth = { name = 'Gradient',
		desc = 'From red at low health through yellow to green at full health.' },
	colorHealth = { name = 'Health color',
		desc = 'Plain green, for when none of the colors above fits.' },
}

-- A setting's value in the defaults a unit's profile starts from: the unit's
-- own table where it sets the key (config/units/), else the shared '**' one,
-- as AceDB lays them over each other. path is the keys down to the table that
-- holds key ({ 'health', 'text' }); nil when neither sets it. The tables are
-- AceDB's defaults: read, never written.
function UF.DefaultFor(unit, path, key)
	local profiles = st.defaults.unitframes.profiles['**']
	for _, root in ipairs({ profiles[unit], profiles['**'] }) do
		local node = root
		for _, step in ipairs(path) do
			node = type(node) == 'table' and node[step] or nil
		end
		if type(node) == 'table' and node[key] ~= nil then return node[key] end
	end
end

local function Near(a, b) return math.abs(a - b) < 0.0001 end

-- '#RRGGBB' of a color, as the options window writes it.
local function Hex(r, g, b)
	local function byte(v) return math.max(0, math.min(255, math.floor(v * 255 + 0.5))) end
	return ('#%02X%02X%02X'):format(byte(r), byte(g), byte(b))
end

--[[
	A "use a custom color" setting as one row: a color whose check box is the
	setting's colorCustom and whose color is its customColor (SaftUI's toggle
	field on a color, SaftUI-Core/Config/optionstypes.lua). spec:
	  name, desc   the row's
	  offDesc      the check box's tooltip: what unticked means (optional)
	  offText      the word the field shows while unticked: a string, or a
	               function(info) -> string
	  unit, path   where the settings live, for their defaults: the unit's
	               config key, then the keys down to the table holding
	               colorCustom and customColor ({ 'health' }, { 'health', 'text' })
	  config()     that table, looked up on every call (a profile change
	               replaces it)
	  update()     re-applies the unit frames
	The saved keys are the ones the two controls always had. customColor is a
	{ r, g, b } list in the defaults, and can be a color object in a saved
	profile (UF.UnpackColor reads both); it's written in the shape it has. The
	reset puts both back, and names the default as its word while the default
	is unticked, else as the color.
]]
function UF.CustomColorOption(order, spec)
	local config, update = spec.config, spec.update
	local function Default(key) return UF.DefaultFor(spec.unit, spec.path, key) end
	local function Write(settings, r, g, b)
		local color = settings.customColor
		if type(color) == 'table' and color.GetRGB then
			color.r, color.g, color.b = r, g, b
		elseif type(color) == 'table' then
			color[1], color[2], color[3] = r, g, b
		else
			settings.customColor = { r, g, b }
		end
	end
	-- Where the color is saved, which All units' decorator finds the setting by (sharedoptions.lua). The
	-- reset does not read it: the hand default below comes first.
	local savedKeys = { unpack(spec.path) }
	savedKeys[#savedKeys + 1] = 'customColor'
	return {
		order = order,
		name = spec.name,
		desc = spec.desc,
		type = 'color',
		size = 'small',
		saved = UF.SavedAt(spec.unit, unpack(savedKeys)),
		get = function() return UF.UnpackColor(config().customColor) end,
		set = function(_, r, g, b)
			Write(config(), r, g, b)
			update()
		end,
		toggle = {
			get = function() return config().colorCustom and true or false end,
			set = function(_, value)
				config().colorCustom = value
				update()
			end,
			offText = spec.offText,
			desc = spec.offDesc,
		},
		default = {
			differs = function()
				local settings = config()
				if (settings.colorCustom and true or false) ~= (Default('colorCustom') and true or false) then return true end
				-- Unticked, the color isn't shown, so it isn't a difference.
				if not settings.colorCustom then return false end
				local r, g, b = UF.UnpackColor(settings.customColor)
				local dr, dg, db = UF.UnpackColor(Default('customColor'))
				return not (Near(r, dr) and Near(g, dg) and Near(b, db))
			end,
			reset = function()
				local settings = config()
				settings.colorCustom = Default('colorCustom') and true or false
				Write(settings, UF.UnpackColor(Default('customColor')))
				update()
			end,
			text = function(info)
				if Default('colorCustom') then return Hex(UF.UnpackColor(Default('customColor'))) end
				local word = spec.offText
				if type(word) == 'function' then word = word(info) end
				return word
			end,
		},
	}
end

--[[
	A bar's Colors section (health, power, additional power): the color flags
	in flags' order, which is the order oUF checks them in, then Custom on a
	line of its own (an untitled group, args.custom): one row, the color with
	its check box (UF.CustomColorOption). A flag the unit's frames never show
	the kind of unit for (UF.CanShow) is left out. The toggles read and write
	the element's config through the tab's get and set; descs overrides a
	flag's desc. element is the config's key for the element ('health'), for the
	row's defaults. config() returns the element's config, and update()
	re-applies it. The check box's word, while it's unticked, names the colors
	above that are on and the bar can take for this unit, in the order oUF checks
	them, up to the first that colors every kind of unit the frames show: "Class
	or reaction" on a target (Class colors players, Reaction the rest), "Class"
	on a party frame. Disconnected and Tapped are left out, as the bar wears them
	only while the unit is offline or tapped. Default when none is on.
]]
function UF.GenerateColorsConfigGroup(order, unit, element, flags, config, update, descs)
	local G = st.Config.generators
	local args, i = {}, 0
	local shown = {}
	for _, key in ipairs(flags) do
		local flag = COLOR_FLAGS[key]
		if not flag.shows or UF.CanShow(unit, flag.shows) then
			i = i + 1
			args[key] = G.toggle(i, flag.name, descs and descs[key] or flag.desc, 'small')
			shown[#shown + 1] = key
		end
	end
	local function OffText()
		local settings = config()
		-- The kinds of unit this unit's frames can show, not yet colored by a flag above.
		local remaining = {}
		for _, kind in ipairs({ 'players', 'npcs', 'pets' }) do
			if UF.CanShow(unit, kind) then remaining[kind] = true end
		end
		local names = {}
		for _, key in ipairs(shown) do
			local flag = COLOR_FLAGS[key]
			if settings[key] and not flag.status then
				local covers = flag.covers
				local reaches = false
				for kind in pairs(remaining) do
					if not covers or covers[kind] then reaches = true end
				end
				if reaches then
					names[#names + 1] = #names == 0 and flag.name
						or (flag.name:sub(2, 2):match('%u') and flag.name or flag.name:sub(1, 1):lower() .. flag.name:sub(2))
					if not covers then break end
					for kind in pairs(covers) do remaining[kind] = nil end
					if next(remaining) == nil then break end
				end
			end
		end
		if #names == 0 then return 'Default' end
		return table.concat(names, ' or ')
	end
	args.custom = {
		order = i + 1,
		name = '',
		type = 'group',
		inline = true,
		args = {
			customColor = UF.CustomColorOption(1, {
				name = 'Custom color',
				desc = 'Colors the bar with this color, over every color above.',
				offDesc = 'Unticked, the bar takes the first of the colors above that fits.',
				offText = OffText,
				unit = unit,
				path = { element },
				config = config,
				update = update,
			}),
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


-- The name of the unit frame profile in use: a part of a saved path, looked up
-- on every read (a profile change replaces the profile's tables).
local function ProfileName() return UF:GetProfile() end

-- Where a unit frame setting is saved, for the options kit's reset
-- (st.Config.SavedIn and SavedAt, SaftUI-Core/Config/optionsdefault.lua): in the
-- profile in use, `unitframes.profiles.<profile>.<unit>`, then the parts.
--   UF.SavedIn(unit, 'health')            a group whose get reads
--                                         UnitConfig().health[info[#info]]
--   UF.SavedAt(unit, 'health', 'position') an option with a get of its own
-- The default at that path is AceDB's merged one: the unit's own table over
-- the '**' one (st:DefaultAt). Both give a function(info), and are made when
-- the page's table is built.
function UF.SavedIn(unit, ...)
	return st.Config.SavedIn('unitframes', 'profiles', ProfileName, unit, ...)
end

function UF.SavedAt(unit, ...)
	return st.Config.SavedAt('unitframes', 'profiles', ProfileName, unit, ...)
end

-- A unit's name, as its page in /sui is named.
local function UnitName(unit)
	return UF.unit_strings[unit] or UF.group_strings[unit] or unit
end

------------------------------------------------------------------ history

-- Copy from as a step of edit mode's history (SaftUI-Core/EditMode/history.lua).
-- The 'ufsetting' kind is one key of one unit's config in one unit frame
-- profile: where = { profile = <the profile's name>, unit, key }. A value is
-- stored and read as a deep copy, so a step never shares a table with the live
-- config; false and nil are values (a key that was absent is put back absent).
-- Writing is safe to run again on the same place: the history also uses it to
-- roll a failed step back.
local function CopyValue(value)
	if type(value) == 'table' then return st.tablecopy(value, true) end
	return value
end

-- The unit's config in the profile where names, or nil when either is gone. The
-- profile is looked up with rawget: reading a missing one from the profiles
-- would make it.
local function ConfigOf(where)
	local profile = rawget(st.config.profile.unitframes.profiles, where.profile)
	return profile and profile[where.unit]
end

local ufsetting = {
	read = function(where)
		local config = ConfigOf(where)
		if config == nil then return nil end
		return CopyValue(config[where.key])
	end,
	write = function(where, value)
		local config = ConfigOf(where)
		if config == nil then return end
		config[where.key] = CopyValue(value)
	end,
	-- Once, after a step's writes: the frames and /sui follow.
	finish = function()
		UF:UpdateConfig()
		st.Config:Refresh()
	end,
	place = function(where) return 'ufsetting:' .. where.profile .. ':' .. where.unit .. ':' .. where.key end,
	name = function(where) return UF.unit_strings[where.unit] or UF.group_strings[where.unit] or where.unit end,
	-- Only the profile in use is edited: a step of another one is not applied.
	check = function(where)
		if where.profile == UF:GetProfile() then return true end
		return false, 'The unit frame profile changed since.'
	end,
	missing = function(where) return ConfigOf(where) == nil end,
}

-- The history, when edit mode is loaded (it always is in game; the unit
-- frames' tests load this file without it). The kind is registered at load,
-- and again before a step is pushed, so a world that loads edit mode after
-- this file has it too.
local function History()
	local EM = st.EditModeFrames
	local history = EM and EM.History
	if history then history:RegisterKind('ufsetting', ufsetting) end
	return history
end
History()

-- What Copy from calls each setting of a unit, and so which it lists: the
-- name the unit's own /sui page shows for that part. An element by its key in
-- lower case (the config's key for it) and its name (UF.ELEMENT_NAMES), read
-- from the elements the unit has, not from where the page puts them (a tab, a
-- row of General's Parts, a tab under another); and General's options, sections
-- and the options in them by their keys (Layout's settings, the Range section;
-- not its Frame and Parts sections, which hold no key of their own). A key the
-- page names nothing for isn't listed: the config holds it but nothing reads it
-- for this unit (Aura watch and Portrait have no element, a single unit has no
-- Range section), so ticking it would copy nothing.
local function CopyNames(self, unit, tree)
	local names = {}
	local function Add(key, name)
		if names[key] == nil and type(key) == 'string' and type(name) == 'string' and name ~= '' then
			names[key] = name
		end
	end
	local function AddGeneral(args)
		for key, option in pairs(args) do
			if key ~= 'parts' then
				if option.type == 'group' and type(option.args) == 'table' then
					if key ~= 'frame' then Add(key, option.name) end
					AddGeneral(option.args)
				else
					Add(key, option.name)
				end
			end
		end
	end
	local page = (tree or self:GetConfigTable()).args[unit]
	local general = page and page.args.general
	if general then AddGeneral(general.args or {}) end
	for element, registered in pairs(UF.elements) do
		if registered.GetConfigTable and (not registered.ValidUnit or registered.ValidUnit(unit)) then
			Add(element:lower(), UF.ELEMENT_NAMES[element])
		end
	end
	return names
end

-- Why unit's position can't be the one unit from has, or nil when it can. The
-- position anchors the unit's frame (a group's holder) to a frame, and one that
-- is the unit's own frame, or is anchored back to it, would place the frame on
-- itself: the game refuses that (and the Position editor does too, through the
-- same st:ValidateAnchor). The text is a sentence for the player. Nil too while
-- the unit's frame isn't spawned (nothing to be anchored to or from).
function UF:PositionCopyProblem(unit, from)
	local frame = self:GetMoverFrame(unit)
	local position = self:GetProfileConfig()[from].position
	local relative = type(position) == 'table' and position.frame
	-- No frame named: the game places it on UIParent.
	if not frame or not relative or relative == '' then return nil end
	local resolved = st:ResolveFrame(relative)
	if resolved ~= nil and resolved == frame then
		return UnitName(from) .. ' is anchored to ' .. UnitName(unit) .. '.'
	end
	local ok, why = st:ValidateAnchor(frame, relative)
	if ok then return nil end
	return why .. '.'
end

-- Copies each of keys' value from unit from onto unit, in the profile in use,
-- as Copy from does: a deep copy of each (a missing one leaves the key absent).
-- The position is left out when it can't be unit's (PositionCopyProblem): it
-- is never written, and never in the history. The old values are copied first,
-- then the unit frames update, then ONE step goes in edit mode's history:
-- 'Copied <from> to <unit>', with a change for each key whose value changed, so
-- a single Undo puts every one back. Returns the step, or nil when no key
-- changed (or there is no history); and, second, the sentence that says why the
-- position wasn't copied, when it wasn't.
function UF:CopySettings(unit, from, keys)
	local profile = self:GetProfile()
	local config = self:GetProfileConfig()
	local skipped
	local changes = {}
	-- Only a setting both units' pages name: the source's config has no value
	-- for one its page lacks (a read would make AceDB's '**' default, written
	-- onto the destination and created on the source).
	local tree = self:GetConfigTable() -- built once for both
	local named, namedFrom = CopyNames(self, unit, tree), CopyNames(self, from, tree)
	for _, key in ipairs(keys) do
		if named[key] and namedFrom[key] then
			local problem = key == 'position' and self:PositionCopyProblem(unit, from)
			if problem then
				skipped = "Position wasn't copied: " .. problem
			else
				changes[#changes + 1] = {
					kind = 'ufsetting', where = { profile = profile, unit = unit, key = key },
					old = CopyValue(config[unit][key]),
				}
			end
		end
	end
	local copied = {}
	for _, change in ipairs(changes) do
		local key = change.where.key
		change.new = CopyValue(config[from][key])
		config[unit][key] = CopyValue(config[from][key])
		copied[key] = true
	end
	-- Shared settings (sharedoptions.lua): what was copied is the unit's own where it differs from what
	-- All units holds, else the sync would put All units' value back at the next profile load, unmarked.
	-- A setting that came out the same as All units' keeps following it. Table writes only.
	if next(copied) and self:SharedReady() and UF.IsShareMember(unit) then
		local all = rawget(config, 'all')
		for _, entry in ipairs(UF.SHARED) do
			if copied[entry.paths[1][1]] and all and self:HasShared(unit, entry.key)
					and not UF.SameShared(entry, config[unit], all) then
				self:OwnShared(unit, entry.key)
			end
		end
	end
	self:UpdateConfig()
	local history = History()
	if not history or #changes == 0 then return nil, skipped end
	return history:Push({
		kind = 'bulk', label = 'Copied ' .. UnitName(from) .. ' to ' .. UnitName(unit), changes = changes,
	}), skipped
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
		if names[key] then
			copy.settings[key] = false
			settingArgs[key] = st.Config.generators.toggle(0, names[key],
				'Copies this setting from the other unit frame onto this one.')
		end
	end
	-- Position, while the chosen unit frame's can't be this one's (it is
	-- anchored to this frame, or through others): shown disabled, with why.
	local function PositionProblem()
		if not (copy.from and copy.settings.position ~= nil) then return nil end
		local problem = UF:PositionCopyProblem(unit, copy.from)
		return problem and "Can't copy Position: " .. problem
	end
	if settingArgs.position then
		settingArgs.position.disabled = function() return PositionProblem() ~= nil end
		settingArgs.position.disabledDesc = function() return PositionProblem() end
	end
	-- A setting is offered while both units' pages name it (the source's can't
	-- be read for one its page lacks): all of this unit's until a source is
	-- chosen, then the ones that source's page names too.
	local fromNames, fromNamesOf
	local function Offered(key)
		if not copy.from then return true end
		if fromNamesOf ~= copy.from then fromNames, fromNamesOf = CopyNames(UF, copy.from), copy.from end
		return fromNames[key] ~= nil
	end
	for key, arg in pairs(settingArgs) do
		arg.hidden = function() return not Offered(key) end
	end
	local function Ticked(key)
		return copy.settings[key] and Offered(key) and not (key == 'position' and PositionProblem())
	end
	local function SetAll(value)
		for key in pairs(copy.settings) do copy.settings[key] = value and Offered(key) end
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
						-- Only the units that have a page (arena has none)
						if key ~= unit and not UF.IsPlateUnit(key)
							and (UF.unit_strings[key] or UF.group_strings[key]) then
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
				get = function(info) return Ticked(info[#info]) or false end,
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
					local keys = {}
					for key in pairs(copy.settings) do
						if Ticked(key) then keys[#keys + 1] = key end
					end
					table.sort(keys)
					local _, skipped = UF:CopySettings(unit, copy.from, keys)
					st.Config:Refresh()
					st.OptionsWindow:CloseDialog()
					-- Only when the position changed between the dialog's check and the click.
					if skipped then st.OptionsWindow:SetStatus(skipped) end
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
local UNIT_ORDER = { all = 0 }
for i, unit in ipairs({
	'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate',
}) do
	UNIT_ORDER[unit] = i
end

function UF:GetConfigTable()
	local config = {
		name = 'Unit frames',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
		-- The units are the page's picker; each unit's elements are its tabs.
		childGroups = 'select',
		pickerLabel = 'Unit',
		args = {},
	}

	local function GetUnitConfig(unit)
		if not unit then return end
		-- All units: the shared settings every unit follows (sharedoptions.lua). Built by the same code
		-- as a unit's page, with the frame's Theme and Background alone in General (an Enable, a size and
		-- a place are each unit's own), no Position, and the elements any unit has a shared setting of.
		local isAll = unit == 'all'

		local profile = UF.GenerateProfileControl() -- this unit's own copies

		-- Looked up on every get/set: a profile change replaces these tables.
		local function UnitConfig() return UF:GetProfileConfig()[unit] end

		local function frame_position_set(key, value)
			UnitConfig().position[key] = value
			UF:UpdateConfig(unit)
		end
		local function frame_position_get(key)
			return UnitConfig().position[key]
		end

		local pickerArgs = {
			copy = {
				order = 1,
				name = 'Copy from',
				desc = "Copies chosen settings from another unit frame onto this one.",
				type = 'execute',
				func = function()
					UF:OpenCopyTable(unit)
				end,
			},
			profile = profile.profile,
			manage = profile.manage,
		}
		if isAll then pickerArgs.copy = nil end

		local frameArgs = {
			-- A half, so Theme sits beside it with no empty quarter
			-- between (as Class power's).
			enable = st.Config.generators.enable(0, 'Shows this unit frame. When off, the unit frame is hidden.'),
			theme = st.Config.generators.theme(1, "How this unit frame's border and background are drawn."),
			background = st.Config.generators.background(1.5),
			width = st.Config.generators.width(2, "The unit frame's width."),
			height = st.Config.generators.height(3, "The unit frame's height."),
		}
		if isAll then
			frameArgs.enable, frameArgs.width, frameArgs.height = nil, nil, nil
			frameArgs.theme.desc = "How every unit frame's border and background are drawn, unless a unit sets its own."
		end

		local generalArgs = {
			-- General's sections, in order: Frame, Position, then a group's
			-- Layout (6) and Range (500), then the Parts (2000, parts.lua).
			frame = {
				order = 1,
				name = 'Frame',
				type = 'group',
				inline = true,
				args = frameArgs,
			},
		}
		if not isAll then
			-- Every SetPoint parameter, the relative frame included.
			-- Passing the mover's frame makes a typed frame go through
			-- st:ValidateAnchor, which rejects the frame itself and
			-- anything anchored back to it (e.g. Pet for Player).
			-- The second section of General.
			generalArgs.position = st.Config.generators.position(2, true, frame_position_get, frame_position_set,
				self:GetMoverFrame(unit), nil, nil, UF.SavedAt(unit, 'position'))
		end

		local config_table = {
			name = isAll and 'All units' or self.unit_strings[unit] or self.group_strings[unit] or unit,
			order = UNIT_ORDER[unit],
			type = 'group',
			inline = false,
			-- Elements (General, Health, Name, Power, ...) as tabs, not a dropdown.
			childGroups = 'tab',
			-- Copy from, the unit frame profile and Manage, on the picker's line
			-- right of the Unit dropdown, so they're there from every tab (Core's
			-- pickerControl field; config/profiles.lua). A nameplate page has
			-- no Copy from (UF.SetUpPlatePage).
			pickerControl = {
				type = 'group',
				name = '',
				args = pickerArgs,
			},
			args = {
				-- Clicking the unit's frame in edit mode selects this group (the
				-- mover's configPath, UF:RegisterMovers).
				general = {
					order = 0,
					name = 'General',
					type = 'group',
					saved = UF.SavedIn(unit),
					get = function(info)
						return UnitConfig()[info[#info]]
					end,
					set = function(info, value)
						UnitConfig()[info[#info]] = value
						UF:UpdateConfig(unit)
					end,
					args = generalArgs,
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

		-- The groups of the elements the unit has (ValidUnit, as in UF.ConstructUnit),
		-- placed by UF.PARTS (parts.lua): a part as a row of General's Parts or as a
		-- tab, Buffs and Debuffs under Auras, every other element a tab.
		local built = {}
		for element_name, element in pairs(UF.elements) do
			-- All units has the elements some unit has a shared setting of.
			local has = isAll and UF.SharesElement(element_name) or (not isAll and (not element.ValidUnit or element.ValidUnit(unit)))
			if element.GetConfigTable and has then
				built[element_name] = element.GetConfigTable(unit)
			end
		end
		UF.PlaceElements(unit, config_table, built)

		-- A nameplate page's tabs are disabled while its box is checked, but
		-- those it keeps.
		UF.DisablePlatePageTabs(unit, config_table)

		-- The shares (sharedoptions.lua): each shared row of a member's page and of All units, last, once
		-- every row is there. Nothing while the profile in use does not share.
		if UF.DecorateShares then UF.DecorateShares(unit, config_table) end

		return config_table
	end

	for unit,frame in pairs(self.units) do
		config.args[unit] = GetUnitConfig(unit)
	end

	for unit in pairs(self.groups or {}) do
		config.args[unit] = GetUnitConfig(unit)
	end

	-- All units first in the picker: its page while the profile in use shares settings, else a page
	-- that says why it doesn't (and has the button that turns sharing on where it can be asked for).
	if UF.SharedNoticePage then
		config.args.all = UF:SharedReady() and GetUnitConfig('all') or UF.SharedNoticePage()
	end

	-- Always there, whether SaftUI draws the plates or not: their pages turn
	-- them on, or say which addon draws them.
	config.args.nameplate = GetUnitConfig('nameplate')
	config.args.friendlynameplate = GetUnitConfig('friendlynameplate')

	return config
end