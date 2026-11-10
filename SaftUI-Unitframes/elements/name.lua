local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(unitframe)
	return UF:AddTextElement(unitframe, 'Name')
end

local function UpdateConfig(unitframe)
	unitframe.Name.config = unitframe.config.name
	UF:UpdateElement(unitframe.Name, 'Name')

	unitframe.Name:SetFontObject(st:GetFont(unitframe.config.name.font))
    unitframe.Name.overrideUnit = true
	unitframe:Tag(unitframe.Name, '[st:name('.. unitframe.base_unit..')]')
end

local function GetConfigTable(unit)
	local G = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function UnitConfig() return UF:GetProfileConfig()[unit] end

	local args = {
		enable = G.toggle(0, 'Enable', "Shows the unit's name.", 'small'),
		allCaps = G.toggle(1, 'All caps', 'Writes the name in capital letters.', 'small'),
		font = G.font(2, "The name's font."),
		showLevel = G.toggle(3, 'Show level', 'Shows the level before the name, colored by how hard the unit is for you.', 'small'),
		showSameLevel = G.toggle(4, 'Show same level', 'Shows the level even when it is the same as yours. Needs Show level.', 'small'),
		showMaxLevel = G.toggle(5, 'Show max level', 'Shows the level even when it is the highest level there is. Needs Show level.', 'small'),
		color_hostile = G.toggle(8, 'Color hostile', 'Colors the names of hostile units red, and of unfriendly and neutral ones yellow.', 'small'),
		maxLength = G.range(9, 'Max length', 1, 100, 1, 'Cuts the name to this many letters.'),
		alpha = G.alpha(10, 'How solid the name is, from see-through to opaque.'),
		-- Last in the tab.
		position = G.uf_element_position(1000,
			function(index) return
				UnitConfig().name.position[index]
			end,
			function(index, value)
				UnitConfig().name.position[index] = value
				UF:UpdateConfig(unit, 'Name')
			end,
			UF:ConfigTarget(unit, 'Name'),
			"Where the name sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
		),
	}
	-- The st:name tag (tags.lua) marks rare, elite and world boss units, and
	-- colors players by class: only where the unit's frames can show them.
	if UF.CanShow(unit, 'mobs') then
		args.show_classification = G.toggle(6, 'Classification',
			'Marks rare (R), rare elite (R+), elite (+) and world boss (B) units, after the level and before the name.', 'small')
	end
	if UF.CanShow(unit, 'players') then
		args.colorClass = G.toggle(7, 'Class color', "Colors players' names in their class color, over Color hostile.", 'small')
	end

	return {
		type = 'group',
		name = 'Name',
		order = 5,
		get = function(info)
			return UnitConfig().name[info[#info]]
		end,
		set = function(info, value)
			UnitConfig().name[info[#info]] = value
			UF:UpdateConfig(unit, 'Name')
		end,
		args = args,
	}
end

UF:RegisterElement('Name', Constructor, UpdateConfig, GetConfigTable)