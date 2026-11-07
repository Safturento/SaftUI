local st = SaftUI
local LT = st:GetModule('Loot')

local generators = st.Config.generators

-- Builds the General group for one of the loot movers. `config_key` is the
-- loot config table ('roll' or 'feed'), `apply` re-applies it live.
local function BuildGeneral(config_key, args, apply)
	local config = LT.config[config_key]
	return {
		name = 'General',
		type = 'group',
		order = 1,
		get = function(info) return config[info[#info]] end,
		set = function(info, value)
			config[info[#info]] = value
			apply()
		end,
		args = args,
	}
end

local function BuildPosition(config_key, target, apply)
	local config = LT.config[config_key]
	return generators.position(2, true,
		function(key) return config.position[key] end,
		function(key, value)
			config.position[key] = value
			apply()
		end,
		target
	)
end

local function WrapMoverOptions(name, general, position)
	position.inline = false -- a sidebar section, not an inline box
	return {
		name = name,
		type = 'group',
		args = {
			general = general,
			position = position,
		}
	}
end

function LT:GetRollMoverOptions()
	local apply = function() LT:UpdateGroupLootConfig() end
	local font = generators.font()
	font.order = 6

	local general = BuildGeneral('roll', {
		width = generators.range(1, 'Width', 100, 1000, 1),
		height = generators.range(2, 'Height', 16, 80, 1),
		spacing = generators.range(3, 'Spacing', 0, 30, 1),
		template = generators.template(4),
		font = font,
		grow_down = {
			order = 7,
			name = 'Grow down',
			desc = 'Stack new rolls downward from the anchor instead of upward.',
			type = 'toggle',
			width = 'full',
		},
	}, apply)

	return WrapMoverOptions('Loot Rolls', general, BuildPosition('roll', LT.rollAnchor, apply))
end

function LT:GetFeedMoverOptions()
	local apply = function() LT:UpdateLootFeedConfig() end
	local font = generators.font()
	font.order = 7

	local general = BuildGeneral('feed', {
		width = generators.range(1, 'Width', 100, 1000, 1),
		item_height = generators.range(2, 'Item height', 16, 80, 1),
		spacing = generators.range(3, 'Spacing', 0, 30, 1),
		max_items = generators.range(4, 'Max items', 1, 30, 1),
		fade_time = generators.range(5, 'Fade time', 0, 60, 1),
		template = generators.template(6),
		font = font,
	}, apply)

	return WrapMoverOptions('Loot Feed', general, BuildPosition('feed', LT.feed, apply))
end
