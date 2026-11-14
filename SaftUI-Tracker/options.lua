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

-- The Quests tab: which quests show and how a quest row reads. Every row saves
-- into tracker.quests and runs TR:UpdateConfig, which draws the rows again.
function TR.QuestsTab()
	local function toggle(order, key, name, desc)
		local option = generators.toggle(order, name, desc)
		option.default = TR.SettingDefault('quests', key)
		return option
	end
	local args = {
		show = {
			order = 1,
			name = 'Show',
			desc = "Which quests the tracker lists: the ones you track, or those and every other quest of the zone you're in.",
			type = 'select',
			values = { tracked = 'Tracked quests', zone = "Tracked and the current zone's" },
			sorting = { 'tracked', 'zone' },
			default = TR.SettingDefault('quests', 'show'),
		},
		zones = toggle(2, 'zones', 'Group by zone',
			"Groups the quests under their zone's header, which collapses. Off lists them all in one list."),
		current_first = toggle(3, 'current_first', 'Current zone first',
			"Puts the zone you're in first in the list, with a map pin."),
		order = {
			order = 4,
			name = 'Order',
			desc = "How the quests of a group are ordered: as the game sorts your tracked quests (nearest first), as your quest log has them, or by level, low first.",
			type = 'select',
			values = { game = "The game's order", log = 'Quest log order', level = 'Level' },
			sorting = { 'game', 'log', 'level' },
			default = TR.SettingDefault('quests', 'order'),
		},
		finished_first = toggle(5, 'finished_first', 'Finished quests first',
			'Puts the quests you can turn in first in their group.'),
		level = toggle(6, 'level', 'Level', "The quest's level before its title."),
		tags = toggle(7, 'tags', 'Tags', "The quest's tags (Elite, Dungeon, Daily...) after its title."),
		difficulty = toggle(8, 'difficulty', 'Color by difficulty',
			"Colors a title by how hard the quest is for you. Off, titles are in the normal text color."),
		icons = toggle(9, 'icons', 'Quest icons', "The quest's icon before its title."),
		hide_finished = toggle(10, 'hide_finished', 'Hide finished objectives',
			'Leaves out the objectives of a quest you have already finished.'),
		finished_objectives = toggle(11, 'finished_objectives', 'Objectives of finished quests',
			'Lists a finished quest\'s objectives above its turn-in line.'),
		bars = toggle(12, 'bars', 'Progress bars',
			"Draws a quest's progress objective as a bar. Off, it is a line of text."),
		timers = toggle(13, 'timers', 'Timers', 'The time left of a timed quest.'),
		waypoint = toggle(14, 'waypoint', 'Waypoint', "The next waypoint's line under the quest you are following."),
		tooltips = toggle(15, 'tooltips', 'Tooltips',
			"The quest's tooltip when the mouse is over its row, with the party's progress in a group and what the clicks do."),
		left_click = {
			order = 16,
			name = 'Left click',
			desc = "What a click on a quest does. Show on map opens the quest on the map out of combat and focuses it in combat; Focus focuses it always. Shift-click stops tracking, right-click opens the menu.",
			type = 'select',
			-- Read again on every call: Show on map is left out while it isn't allowed.
			values = function() return TR.LeftClickValues() end,
			sorting = { 'map', 'focus' },
			get = function() return TR.LeftClick() end,
			default = TR.SettingDefault('quests', 'left_click'),
		},
		spacing = generators.range(17, 'Spacing', 0, 20, 1, 'The space between two quests.'),
		colors = {
			order = 18,
			type = 'description',
			name = 'Finished and failed objectives take Global settings > Colors > Objectives.',
		},
	}
	args.spacing.default = TR.SettingDefault('quests', 'spacing')
	-- With Group by zone off there is no zone to put first.
	args.current_first.disabled = function() return not TR.config.quests.zones end
	local tab = TR.Tab(2, 'Quests', args)
	tab.get = function(info) return TR.config.quests[info[#info]] end
	tab.set = function(info, value)
		TR.config.quests[info[#info]] = value
		TR:UpdateConfig()
	end
	return tab
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
			TR:UpdateConfig()
		end,
		args = {
			enable = generators.toggle(1, "SaftUI's tracker",
				"Draws your quests in SaftUI's own tracker, grouped by zone, in place of Blizzard's objective tracker. Changes after a reload."),
			theme = generators.theme(2, "The tracker's panel and its item buttons."),
			background = generators.background(2.5),
			width = generators.range(3, 'Width', 180, 600, 1, 'How wide the tracker is.'),
			height = generators.range(4, 'Max height', 120, 1600, 1, 'The tallest the tracker grows. Past it the list scrolls.'),
			grow = {
				order = 5,
				name = 'Grow',
				desc = 'Which way the tracker grows from its position: down from its top, or up from its bottom.',
				type = 'select',
				values = { down = 'Down', up = 'Up' },
				sorting = { 'down', 'up' },
			},
			header = generators.toggle(6, 'Header',
				'The Objectives line at the top, with the count and the collapse button.'),
			count = generators.toggle(7, 'Count',
				'The number of quests in your quest log in the header.'),
			hide_empty = generators.toggle(8, 'Hide when empty',
				'Hides the tracker while you track no quests.'),
			text = { order = 9, type = 'header', name = 'Text' },
			font = generators.font(10, 'Quest titles and objectives.'),
			header_font = generators.font(11, 'The header and the zone headers.'),
		},
	}
	general.args.header_font.name = 'Header font'
	-- Each value row resets by itself (the rotate-ccw icon while it differs).
	for key, option in pairs(general.args) do
		if key ~= 'enable' and key ~= 'text' then option.default = TR.SettingDefault(nil, key) end
	end

	-- Where the tracker's box is (the holder: Width by Max height). The tracker
	-- hangs from the holder, so the holder anchored to the tracker, or to a
	-- frame inside it, would chase itself: refused here by name (the frames
	-- don't exist while the switch is off) and by parent.
	local position = generators.position(1000, true,
		function(key) return TR:GetPosition()[key] end,
		function(key, value)
			local current = TR:GetPosition()
			current[key] = value
			TR.config.position = current
			TR:ApplyHolder()
		end,
		function() return TR.holder end,
		"Where the tracker's box is (its top right corner by default). The list grows down from its top, or up from its bottom with Grow up.")
	local validate = position.validate
	position.validate = function(info, part, value)
		if part == 'frame' then
			local frame = st:ResolveFrame(value)
			while frame do
				if frame == TR.window or frame == TR.holder then
					return "The tracker's position can't be anchored to the tracker itself."
				end
				frame = frame.GetParent and frame:GetParent()
			end
			if value == 'SaftUITracker' or value == 'SaftUITrackerHolder' then
				return "The tracker's position can't be anchored to the tracker itself."
			end
		end
		return validate(info, part, value)
	end
	general.args.position = position

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
			quests = TR.QuestsTab(),
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
