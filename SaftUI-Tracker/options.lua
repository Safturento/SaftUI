local st = SaftUI
local TR = st:GetModule('Tracker')

local generators = st.Config.generators

-- Every tab but General is disabled while SaftUI's tracker is off for the
-- session (its switch off, or another tracker addon loaded), since there is
-- nothing for it to change until it's on and the game reloaded.
function TR.TrackedByText(label)
	return ("Quests are tracked by %s. Turn it off to use SaftUI's."):format(label)
end

-- Why a tab is off: another tracker addon is loaded, else the switch.
function TR.OffDesc()
	local addon = TR:TrackerAddon()
	if addon then return TR.TrackedByText(addon) end
	return "Turn on SaftUI's tracker (General) and reload."
end

function TR.TabOff() return not TR:IsOn() end

-- A tab's table with what every tab but General shares; the tab's task gives
-- it its own get and set.
function TR.Tab(order, name, args)
	return {
		order = order,
		name = name,
		type = 'group',
		disabled = TR.TabOff,
		disabledDesc = TR.OffDesc,
		args = args,
	}
end

-- The Tracker page in /sui, under Info: General first, with the switch, then
-- a tab for each part of the tracker as it's built (each task adds its own).
function TR:GetConfigTable()
	local general = {
		order = 1,
		name = 'General',
		type = 'group',
		get = function(info) return TR.config[info[#info]] end,
		set = function(info, value)
			TR.config[info[#info]] = value
		end,
		args = {
			enable = generators.toggle(1, "SaftUI's tracker",
				"Draws your quests in SaftUI's own tracker, grouped by zone, in place of Blizzard's objective tracker. Changes after a reload."),
		},
	}
	-- The switch is read once, so saving it, by the box or by its reset,
	-- asks for a reload.
	local function Save(value)
		TR:SwitchSaved(value)
		st.OptionsWidgets.Confirm("SaftUI's tracker changes after a reload. Reload now?", function() ReloadUI() end)
	end
	local default = TR.SettingDefault(nil, 'enable')
	default.reset = function() Save(default.value()) end
	general.args.enable.default = default
	general.args.enable.set = function(_, value) Save(value) end

	local page = {
		name = 'Tracker',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionslayout.lua)
		childGroups = 'tab',
		args = {
			general = general,
		},
	}

	-- Another tracker addon draws the quests: the page is read-only, and says
	-- which.
	local addon = TR:TrackerAddon()
	if addon then
		page.disabled = function() return TR:TrackerAddon() ~= nil end
		page.args.tracked_by = {
			order = 0,
			name = TR.TrackedByText(addon),
			type = 'description',
			-- Read at full strength while everything under it is dimmed.
			disabled = false,
		}
	end
	return page
end
