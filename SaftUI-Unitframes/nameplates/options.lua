local st = SaftUI
local UF = st:GetModule('Unitframes')

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

-- Makes unit's page (config_table, as UF:GetConfigTable in config/config.lua
-- builds it) its nameplate page, before the element tabs go on: its own
-- General, no Copy from (see UF:OpenCopyTable), and everything disabled while
-- another nameplate addon draws the plates. Any other unit's page is left as
-- it is.
function UF.SetUpPlatePage(unit, config_table)
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
end

-- A nameplate page's tabs hide while its box is checked, but those it keeps:
-- UF:GetConfigTable calls it once the element tabs are on. Any other unit's
-- page is left as it is.
function UF.HidePlatePageTabs(unit, config_table)
	local plate = PLATE_PAGES[unit]
	if plate then
		HideWhileChecked(unit, config_table.args, plate.kept)
	end
end
