local st = SaftUI
local LT = st:GetModule('Loot')

local generators = st.Config.generators

-- A "Test mode" toggle. It is not a config value: `get`/`set` read and write
-- a plain module field (via `setter`), so it is never saved to the profile.
local function TestModeToggle(desc, field, setter)
	return {
		order = 0,
		name = 'Test mode',
		desc = desc,
		type = 'toggle',
		size = 'small',
		get = function() return LT[field] and true or false end,
		set = function(_, value) setter(LT, value) end,
	}
end

-- Builds the General group for one of the loot movers. `config_key` is the
-- loot config table ('roll' or 'feed'), `apply` re-applies it live.
local function BuildGeneral(config_key, args, apply)
	return {
		name = 'General',
		type = 'group',
		order = 1,
		get = function(info) return LT.config[config_key][info[#info]] end,
		set = function(info, value)
			LT.config[config_key][info[#info]] = value
			apply()
		end,
		args = args,
	}
end

-- Every SetPoint parameter is editable, the relative frame included (a user
-- requirement). Passing `target` makes the typed frame go through
-- st:ValidateAnchor, which rejects anchoring to the target itself, to anything
-- whose anchors lead back to it (the roll frames) and to its own children.
-- Section puts it last in General.
local function BuildPosition(config_key, target, apply)
	return generators.position(1000, true,
		function(key) return LT.config[config_key].position[key] end,
		function(key, value)
			LT.config[config_key].position[key] = value
			apply()
		end,
		target
	)
end

-- A loot mover's section: its General group, with the Position option last.
local function Section(name, order, general, position)
	general.args.position = position
	return {
		name = name,
		type = 'group',
		order = order,
		childGroups = 'tab',
		args = {
			general = general,
		}
	}
end

function LT:GetRollOptions()
	local apply = function() LT:UpdateGroupLootConfig() end
	local font = generators.font(6, 'The font of the text on the roll bars.')

	local general = BuildGeneral('roll', {
		test_mode = TestModeToggle(
			'Show sample roll bars so you can tune the rolls without waiting for loot. ' ..
			'Not saved: off again after a reload or profile change. Hidden while a real roll is up.',
			'testRolls', LT.SetTestRolls),
		width = generators.range(1, 'Width', 100, 1000, 1, "Each roll bar's width."),
		height = generators.range(2, 'Height', 16, 80, 1, "Each roll bar's height."),
		spacing = generators.range(3, 'Spacing', 0, 30, 1, 'The gap between roll bars.'),
		template = generators.template(4, 'The look of the roll bars: their background and border.'),
		font = font,
		grow_down = {
			order = 7,
			name = 'Grow down',
			desc = 'Stack new rolls downward from the anchor instead of upward.',
			type = 'toggle',
		},
	}, apply)

	return Section('Rolls', 1, general, BuildPosition('roll', LT.rollAnchor, apply))
end

function LT:GetFeedOptions()
	local apply = function() LT:UpdateLootFeedConfig() end
	local font = generators.font(7, 'The font of the feed text.')

	local general = BuildGeneral('feed', {
		test_mode = TestModeToggle(
			'Keep the feed filled with sample entries (items, gold, currency, skill ups, ' ..
			'experience, reputation, honor, roll results). Turning it off removes only the samples. ' ..
			'Not saved: off again after a reload or profile change.',
			'testFeed', LT.SetTestFeed),
		width = generators.range(1, 'Width', 100, 1000, 1, "The feed's width."),
		item_height = generators.range(2, 'Item height', 16, 80, 1, "Each entry's height."),
		spacing = generators.range(3, 'Spacing', 0, 30, 1, 'The gap between entries.'),
		max_items = generators.range(4, 'Max items', 1, 30, 1, 'How many entries the feed shows at once.'),
		fade_time = generators.range(5, 'Fade time', 1, 60, 1,
			'How many seconds an entry stays on screen before it fades out. At least 1.'),
		template = generators.template(6, 'The look of the feed entries: their background and border.'),
		font = font,
		clear_history = {
			order = 8,
			name = 'Clear history',
			desc = 'Empties the loot feed, including what is saved for this character.',
			type = 'execute',
			size = 'small',
			confirm = true,
			func = function() LT:ClearFeedHistory() end,
		},
	}, apply)

	return Section('Feed', 2, general, BuildPosition('feed', LT.feed, apply))
end

-- Loot's section in the /sui tree: Rolls and Feed, each a General group with
-- the Position option last. Clicking either frame in edit mode selects its
-- General group (the mover's configPath). A section is only there once its
-- frame exists (the roll frames need GroupLootContainer).
function LT:GetConfigTable()
	local args = {}
	if self.rollAnchor then args.roll = self:GetRollOptions() end
	if self.feed then args.feed = self:GetFeedOptions() end
	if not next(args) then return end
	return {
		name = 'Loot',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionswindow.lua)
		args = args,
	}
end
