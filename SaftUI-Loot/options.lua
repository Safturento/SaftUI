local st = SaftUI
local LT = st:GetModule('Loot')

local generators = st.Config.generators

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
local function BuildPosition(config_key, target, apply)
	return generators.position(2, true,
		function(key) return LT.config[config_key].position[key] end,
		function(key, value)
			LT.config[config_key].position[key] = value
			apply()
		end,
		target
	)
end

local function Section(name, order, general, position)
	position.inline = false -- a tree section, not an inline box
	return {
		name = name,
		type = 'group',
		order = order,
		args = {
			general = general,
			position = position,
		}
	}
end

function LT:GetRollOptions()
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

	return Section('Rolls', 1, general, BuildPosition('roll', LT.rollAnchor, apply))
end

function LT:GetFeedOptions()
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

	return Section('Feed', 2, general, BuildPosition('feed', LT.feed, apply))
end

-- Loot's section in the /sui tree: Rolls and Feed, each with General and
-- Position. Clicking either frame in edit mode selects its General group (the
-- mover's configPath). A section is only there once its frame exists (the
-- roll frames need GroupLootContainer).
function LT:GetConfigTable()
	local args = {}
	if self.rollAnchor then args.roll = self:GetRollOptions() end
	if self.feed then args.feed = self:GetFeedOptions() end
	if not next(args) then return end
	return {
		name = 'Loot',
		type = 'group',
		args = args,
	}
end
