local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The General options only some units have: Layout (with Test mode) on
	party, the raid groups and boss, Range on party and the raid groups, and
	the raid groups' Enable saying that they hide Blizzard's raid frames.
	UF:GetConfigTable (config.lua) adds them to each unit's General with
	UF:AddGroupOptions.
]]

-- Group header 'point' / 'columnAnchorPoint' values, named for the way the
-- frames (or columns) grow from them.
local GROWTH_DIRECTIONS = { TOP = 'Down', BOTTOM = 'Up', LEFT = 'Right', RIGHT = 'Left' }

-- Party, raid and boss: how the frames are laid out (a party or raid header's
-- attributes; boss frames by UF.GetUnitGroupLayout, one line, so boss has only
-- Growth and Spacing), and test mode. The values sit
-- on the unit's own config, so General's get and set handle them, and set
-- re-places the frames, the holder and any test previews (UF:UpdateConfig(unit),
-- which waits for the end of combat).
local TEST_MODE_DESCS = {
	group = "Fills this group's spot with made-up members, styled and laid out like the real frames, so the layout can be checked without a group. Hidden while a real group of this kind is showing. Not saved: it's off after a /reload.",
	boss = "Fills the boss frames' spot with made-up bosses, styled and laid out like the real frames, so the layout can be checked out of an encounter. Hidden while a real boss frame is showing. Not saved: it's off after a /reload.",
}
local function GetGroupLayoutConfig(unit, order)
	local G = st.Config.generators
	local args = {
		growthDirection = {
			order = 2,
			name = 'Growth',
			desc = 'Which way each unit frame follows the one before it.',
			type = 'select',
			values = GROWTH_DIRECTIONS,
		},
		spacing = G.range(4, 'Spacing', 0, 50, 1, 'The gap between one unit frame and the next.'),
		test_mode = {
			order = 0,
			name = 'Test mode',
			desc = TEST_MODE_DESCS[unit] or TEST_MODE_DESCS.group,
			type = 'toggle',
			size = 'small',
			-- Not a config value: a plain module field, never saved.
			get = function() return UF.testGroups[unit] and true or false end,
			set = function(_, value) UF:SetGroupTestMode(unit, value) end,
		},
	}
	if unit ~= 'boss' then
		-- Boss is always one line, so these are party and raid's.
		args.initialAnchor = {
			order = 3,
			name = 'Column growth',
			desc = 'Which way each new column follows the one before it. A column runs the way the frames grow, so it is a row when they grow sideways.',
			type = 'select',
			values = GROWTH_DIRECTIONS,
		}
		args.columnSpacing = G.range(5, 'Column spacing', 0, 50, 1, 'The gap between one column and the next.')
		args.unitsPerColumn = G.range(6, 'Units per column', 1, 40, 1, 'How many unit frames fill a column before the next column starts.')
		args.maxColumns = G.range(7, 'Max columns', 1, 40, 1, 'The most columns shown. Unit frames past the last column are not shown.')
	end
	if unit == 'party' then
		args.showPlayer = G.toggle(1, 'Show player', 'Shows you as the first unit frame of the party.', 'small')
	end
	return {
		order = order,
		name = 'Layout',
		type = 'group',
		inline = true,
		args = args,
	}
end

-- An alpha option under its own name.
local function RangeAlpha(order, name, desc)
	local option = st.Config.generators.alpha(order, desc)
	option.name = name
	return option
end

-- Adds unit's own options from above to its General, in config_table (its
-- page, as UF:GetConfigTable builds it): nothing for a unit with none.
function UF:AddGroupOptions(unit, config_table)
	-- Looked up on every get/set: a profile change replaces these tables.
	local function UnitConfig() return UF:GetProfileConfig()[unit] end

	if (unit == 'boss' or (self.groups and self.groups[unit])) then
		config_table.args.general.args.layout = GetGroupLayoutConfig(unit, 6)
	end

	-- Range alpha only does anything on group members' frames: oUF's range
	-- element is enabled only on header children.
	if self.groups and self.groups[unit] then
		config_table.args.general.args.range_alpha = {
			order = 500,
			name = 'Range',
			type = 'group',
			inline = true,
			get = function(info)
				return UnitConfig().range_alpha[info[#info]]
			end,
			set = function(info, value)
				UnitConfig().range_alpha[info[#info]] = value
				UF:UpdateConfig(unit)
			end,
			args = {
				inside = RangeAlpha(0, 'Inside range', "How solid a group member's unit frame is while the member is within range."),
				outside = RangeAlpha(1, 'Outside range', "How solid a group member's unit frame is while the member is out of range."),
			},
		}
	end

	-- Either raid group being on hides Blizzard's raid frames (blizzardraid.lua).
	if self.groups and self.groups[unit] and unit ~= 'party' then
		config_table.args.general.args.enable.desc = "While either raid group is on, Blizzard's raid frames are hidden. Blizzard's raid manager tab at the left edge of the screen stays. Turning both raid groups off brings Blizzard's raid frames back. In a raid, hiding them waits until you leave the raid, and bringing them back waits until you leave it or /reload."
	end
end
