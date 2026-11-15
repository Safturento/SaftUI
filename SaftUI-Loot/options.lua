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
		theme = generators.theme(4, "The roll bars' border and background."),
		background = generators.background(4.5),
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
		theme = generators.theme(6, "The feed entries' border and background."),
		background = generators.background(6.5),
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

-- A popup row's own reset (the options kit's `default` field): the rotate-ccw
-- icon while the setting differs from its default, putting it back and
-- applying it. A font reset also tells the fonts (st:FontsChanged).
local function PopupDefault(key, apply)
	return {
		differs = function() return LT.config.popup[key] ~= st.defaults.loot.popup[key] end,
		reset = function()
			LT.config.popup[key] = st.defaults.loot.popup[key]
			apply()
		end,
		value = function() return st.defaults.loot.popup[key] end,
	}
end

-- The Loot window page: Blizzard's loot window (the one that lists what a
-- corpse or chest holds) in SaftUI's look. There's no Position: the window
-- opens where Blizzard's own setting says (at the cursor, or Edit Mode's).
function LT:GetPopupOptions()
	local apply = function() LT:UpdatePopup() end
	local font = generators.font(4, 'The font of the item names, counts and quality labels in the loot window.')
	local general = BuildGeneral('popup', {
		enable = generators.toggle(1, 'Enable',
			"Draw Blizzard's loot window in SaftUI's look: a panel, a card for each item and the item's quality on its slot's border. " ..
			"Off, the window stays as Blizzard draws it. Where it opens (at the cursor) is Blizzard's setting.",
			'small'),
		theme = generators.theme(2, "The loot window's border and background. Under Blizzard and None the window keeps Blizzard's own look."),
		background = generators.background(3),
		font = font,
	}, apply)
	for key, option in pairs(general.args) do
		option.default = PopupDefault(key, apply)
	end
	-- A font is a shared font's key or a typeface; its reset also tells the fonts.
	local Fonts = st:GetModule('Fonts', true)
	if Fonts and Fonts.FontSettingDefault then
		general.args.font.default = Fonts.FontSettingDefault(
			function() return LT.config.popup.font end,
			function(_, value) LT.config.popup.font = value; apply() end,
			st.defaults.loot.popup.font)
	end
	return {
		name = 'Loot window',
		type = 'group',
		order = 3,
		childGroups = 'tab',
		args = { general = general },
	}
end

-- Loot's section in the /sui tree: Rolls, Feed and the Loot window. Rolls and
-- Feed are each a General group with the Position option last; clicking either
-- frame in edit mode selects its General group (the mover's configPath). Those
-- two are only there once their frame exists (the roll frames need
-- GroupLootContainer); the Loot window's page is always there, since the window
-- is Blizzard's and has no mover.
function LT:GetConfigTable()
	local args = {}
	if self.rollAnchor then args.roll = self:GetRollOptions() end
	if self.feed then args.feed = self:GetFeedOptions() end
	args.popup = self:GetPopupOptions()
	return {
		name = 'Loot',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionslayout.lua)
		args = args,
	}
end
