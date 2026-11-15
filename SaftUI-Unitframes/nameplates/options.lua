local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The two nameplate pages (nameplates/): Enemy nameplates (the nameplate
	unit) and Friendly nameplates (friendlynameplate). Each has a box that
	draws its kind of plate with the other page's settings (UF.PlateConfigKey
	reads them).

	While a page's box is checked, nobody can change a setting that does
	nothing there. The page's tabs stay where they are, so nothing above the
	page moves, but the ones it doesn't keep are disabled (the window fades
	them and takes no click on them), and General hides its own settings,
	with one centred line in their place saying where the plates' settings
	come from ("Sourced from enemy nameplates"). What stays: General, with the
	on/off switches (Nameplates, Friendly plates) and the box, the stand-down
	line, and on the Enemy page threat (Threat when solo and the Threat tab),
	since threat is always the Enemy page's (threat.lua reads
	nameplate.threat). A disabled tab the window's selection names (one tab
	is kept across the Unitframes picks) opens General instead, and Search
	skips the disabled tabs (st.OptionsModel). The settings set aside stay in
	the profile, so unchecking brings them back as they were. While one box
	is checked, the other page's is disabled, so both are never on, and its
	tooltip says why (disabledDesc). All of it is read from the profile at
	call time: a profile change replaces the tables.

	Per page: box, the box's key in the page's config; other, the other page;
	kept, the page's options (its tabs) that stay usable while the box is
	checked, and keptGeneral, General's that stay shown; sourced, the centred
	line while it's checked; otherChecked, the box's tooltip while it's
	disabled because the other page's is checked.
]]
local PLATE_PAGES = {
	nameplate = {
		box = 'use_friendly',
		other = 'friendlynameplate',
		kept = { general = true, drawn_by = true, Threat = true },
		keptGeneral = { enable = true, threat_solo = true, use_friendly = true, sourced = true },
		sourced = 'Sourced from friendly nameplates',
		otherChecked = "Friendly nameplates use this page's settings. To check this box, uncheck Use enemy nameplates' settings on the Friendly nameplates page.",
	},
	friendlynameplate = {
		box = 'use_enemy',
		other = 'nameplate',
		kept = { general = true, drawn_by = true },
		keptGeneral = { friendly = true, use_enemy = true, sourced = true },
		sourced = 'Sourced from enemy nameplates',
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
-- already and no tab is enabled (st.OptionsModel), so a line in General would
-- mostly not show.

-- The nameplate addon drawing the plates, or nil: UF:NameplateAddon
-- (nameplates/nameplates.lua), and nil where that isn't loaded, so the page
-- builds without it.
local function OtherNameplateAddon()
	return UF.NameplateAddon and UF:NameplateAddon() or nil
end

-- The line naming the addon that draws the plates.
local function DrawnBy(addon)
	return ("Nameplates are drawn by %s. Turn it off to use SaftUI's."):format(addon)
end

local function StandDown(config_table)
	local addon = OtherNameplateAddon()
	config_table.disabled = function() return OtherNameplateAddon() ~= nil end
	if not addon then return end
	config_table.args.drawn_by = {
		order = 0,
		name = DrawnBy(addon),
		type = 'description',
		-- Read at full strength while everything under it is dimmed.
		disabled = false,
	}
end

-- Hides every option in args that kept doesn't name while unit's box is
-- checked: General's own settings.
local function HideWhileChecked(unit, args, kept)
	local function Checked() return PlateBoxChecked(unit) end
	for key, option in pairs(args) do
		if not kept[key] then option.hidden = Checked end
	end
end

-- Disables every option in args that kept doesn't name (the page's tabs)
-- while unit's box is checked, so they stay where they are, faded, and take
-- no click. An option's own disabled replaces the page's (StandDown), which
-- it would otherwise inherit, so another addon drawing the plates disables
-- them too. No element tab sets its own disabled, so nothing is overwritten.
local function DisableWhileChecked(unit, args, kept)
	local function Disabled() return OtherNameplateAddon() ~= nil or PlateBoxChecked(unit) end
	for key, option in pairs(args) do
		if not kept[key] then option.disabled = Disabled end
	end
end

-- Why unit's box is disabled, or nil while it isn't: another addon draws the
-- plates, or the other page's box is checked and this one isn't (both
-- checked, from a profile made elsewhere, leaves either free to uncheck).
local function WhyBoxDisabled(unit)
	local addon = OtherNameplateAddon()
	if addon then return DrawnBy(addon) end
	local plate = PLATE_PAGES[unit]
	if PlateBoxChecked(plate.other) and not PlateBoxChecked(unit) then return plate.otherChecked end
end

-- A nameplate page's box (name, desc, at order), and the centred line that
-- stands in for General's other settings while it's checked, as General's
-- box and sourced.
local function PlateBox(unit, order, name, desc)
	local plate = PLATE_PAGES[unit]
	local box = st.Config.generators.toggle(order, name, desc)
	-- Its own disabled replaces the page's (StandDown), so it checks for
	-- another addon drawing the plates too. Hovered while disabled, its
	-- tooltip says why.
	box.disabled = function() return WhyBoxDisabled(unit) ~= nil end
	box.disabledDesc = function() return WhyBoxDisabled(unit) end
	-- A box moves one kind of plate to the other config, so every plate looks
	-- its config up again and the plates' size follows: UF:ApplyConfig's plate
	-- branch, which does the same for either plate key.
	box.set = function(_, value)
		UF:GetProfileConfig()[unit][plate.box] = value
		UF:UpdateConfig('nameplate')
	end
	-- After General's other settings, which are hidden while it shows: in the
	-- middle of what the switches leave of the page, across and down (a fill
	-- row, as the window draws a description with fill).
	local sourced = {
		order = 100,
		type = 'description',
		name = plate.sourced,
		justifyH = 'CENTER',
		fill = true,
		hidden = function() return not PlateBoxChecked(unit) end,
	}
	return box, sourced
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

	local box, sourced = PlateBox('nameplate', 3, "Use friendly nameplates' settings",
		"Draws enemy and neutral nameplates with the Friendly nameplates page's settings. This page's own are set aside, kept for when it's unchecked: its other tabs are disabled and General's other settings hidden. Threat when solo and the Threat tab stay, and still apply.")

	local args = {
		enable = enable,
		threat_solo = G.toggle(2, 'Threat when solo',
			"Tints enemy health bars by your threat, and shows the threat percent, while you're on your own too. In a party or raid both always show.", 'small'),
		use_friendly = box,
		sourced = sourced,
		theme = G.theme(4, "How the border and background around each whole enemy nameplate are drawn. Its bars have their own, on their tabs."),
		background = G.background(4.5),
		width = G.width(5, "Enemy nameplates' width: the health bar and the area you click. The game stacks every nameplate at this size."),
		height = G.height(6, "Enemy nameplates' height: the health bar and the area you click. The game stacks every nameplate at this size."),
	}
	-- Width and Height have a get of their own, which hands on to the group's.
	args.width.saved = UF.SavedIn('nameplate')
	args.height.saved = UF.SavedIn('nameplate')
	HideWhileChecked('nameplate', args, PLATE_PAGES.nameplate.keptGeneral)

	return {
		order = 0,
		name = 'General',
		type = 'group',
		saved = UF.SavedIn('nameplate'),
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
	-- Read and written on the Enemy page's config, so saved there.
	friendly.saved = UF.SavedAt('nameplate', 'friendly')
	friendly.get = function() return UF:GetProfileConfig().nameplate.friendly end
	friendly.set = function(_, value)
		UF:GetProfileConfig().nameplate.friendly = value
		UF:ApplyNameplateCVars()
	end

	local box, sourced = PlateBox('friendlynameplate', 2, "Use enemy nameplates' settings",
		"Draws friendly nameplates with the Enemy nameplates page's settings. This page's own are set aside, kept for when it's unchecked: its other tabs are disabled and General's other settings hidden. Friendly nameplates never show threat.")

	local args = {
		friendly = friendly,
		use_enemy = box,
		sourced = sourced,
		theme = G.theme(4, "How the border and background around each whole friendly nameplate are drawn. Its bars have their own, on their tabs."),
		background = G.background(4.5),
		width = G.width(5, "Friendly nameplates' width, centred on the plate: the area you click. While enemy nameplates use this page, the game stacks every nameplate at this size."),
		height = G.height(6, "Friendly nameplates' height, centred on the plate: the area you click. While enemy nameplates use this page, the game stacks every nameplate at this size."),
	}
	args.width.saved = UF.SavedIn('friendlynameplate')
	args.height.saved = UF.SavedIn('friendlynameplate')
	HideWhileChecked('friendlynameplate', args, PLATE_PAGES.friendlynameplate.keptGeneral)

	return {
		order = 0,
		name = 'General',
		type = 'group',
		saved = UF.SavedIn('friendlynameplate'),
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			-- Re-applies every plate, and their size (UF:ApplyConfig).
			UF:UpdateConfig('friendlynameplate')
		end,
		args = args,
	}
end

-- Makes unit's page (config_table, as UF:GetConfigTable in config/config.lua
-- builds it) its nameplate page, before the element tabs go on: its own
-- General, the unit frame profile and Manage beside the picker, no Copy from (see UF:OpenCopyTable), and everything disabled while
-- another nameplate addon draws the plates. Any other unit's page is left as
-- it is.
function UF.SetUpPlatePage(unit, config_table)
	local plate = PLATE_PAGES[unit]
	if plate then
		-- The unit frame profile and Manage, without Copy from.
		config_table.pickerControl = { type = 'group', name = '', args = UF.GenerateProfileControl() }
		if unit == 'nameplate' then
			config_table.name = 'Enemy nameplates'
			config_table.args.general = NameplateGeneral()
		else
			config_table.name = 'Friendly nameplates'
			config_table.args.general = FriendlyNameplateGeneral()
		end
		StandDown(config_table)
	end
end

-- A nameplate page's tabs are disabled while its box is checked, but those it
-- keeps: UF:GetConfigTable calls it once the element tabs are on. Any other
-- unit's page is left as it is.
function UF.DisablePlatePageTabs(unit, config_table)
	local plate = PLATE_PAGES[unit]
	if plate then
		DisableWhileChecked(unit, config_table.args, plate.kept)
	end
end
