local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Constructor(unitframe)
	return UF:AddTextElement(unitframe, 'Name')
end

-- Max width: the name gets that width on one line, so the game cuts a longer
-- one, a secret name too, which the tag can't shorten (tags.lua). 0, every
-- unit's default but the plates', leaves a name that was never sized as it
-- is, and gives one sized before no width again (0: as wide as its text),
-- wrapping as a font string does. Align (UF.ApplyJustify) is set after, in
-- either case: the caller's ApplyFont has just put the font's back.
local function SetMaxWidth(name, config)
	local width = tonumber(config.max_width) or 0
	if width > 0 then
		name:SetWidth(width)
		name:SetWordWrap(false)
		name.sizedByMaxWidth = true
	elseif name.sizedByMaxWidth then
		name:SetWidth(0)
		name:SetWordWrap(true)
		name.sizedByMaxWidth = nil
	end
	UF.ApplyJustify(name, config)
end
-- Shared with the nameplates' subtext line (nameplates/subtext.lua).
UF.SetMaxWidth = SetMaxWidth

local function UpdateConfig(unitframe)
	UF:UpdateElement(unitframe.Name)

	st:ApplyFont(unitframe.Name, unitframe.config.name.font)
	SetMaxWidth(unitframe.Name, unitframe.config.name)
    unitframe.Name.overrideUnit = true

	-- The tag names the config unit it reads (tags.lua), so it's bound again
	-- when the frame's changes: a plate's frame draws from Enemy or Friendly
	-- nameplates by its unit's kind (nameplates.lua's UF:ApplyPlateConfig).
	-- oUF's update after this one (UF:UpdateUnitFrame's) writes the name
	-- from the new config.
	local name = unitframe.Name
	if name.taggedUnit ~= unitframe.base_unit then
		if name.taggedUnit then unitframe:Untag(name) end
		unitframe:Tag(name, '[st:name(' .. unitframe.base_unit .. ')]')
		name.taggedUnit = unitframe.base_unit
	end
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
		color_hostile = G.toggle(8, 'Color hostile', 'Colors the names of hostile units in the Danger color, and of unfriendly and neutral ones in the Caution color (Global settings > Colors > Text).', 'small'),
		maxLength = G.range(9, 'Max length', 1, 100, 1, 'Cuts the name to this many letters.'),
		max_width = G.range(9.5, 'Max width', 0, 600, 1, "Cuts the name at this many pixels, so it can't run under the health text. 0: no limit."),
		justify = G.justify(9.7, 'Lines the name up inside its Max width. Only has an effect while Max width is above 0.'),
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
			"Where the name sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
			nil, UF.SavedAt(unit, 'name', 'position')
		),
	}
	-- The st:name tag (tags.lua) marks rare, elite and world boss units, and
	-- colors players by class: only where the unit's frames can show them.
	if UF.CanShow(unit, 'mobs') then
		args.show_classification = G.toggle(6, 'Classification',
			'Marks rare (R), rare elite (R+), elite (+) and world boss (B) units, after the level and before the name.', 'small')
	end
	if UF.CanShow(unit, 'npcs') then
		args.color_friendly = G.toggle(8.5, 'Color friendly', "Colors friendly units' names in the friendly reaction color.", 'small')
	end
	if UF.CanShow(unit, 'players') then
		args.colorClass = G.toggle(7, 'Class color', "Colors players' names in their class color, over Color hostile.", 'small')
	end

	return {
		type = 'group',
		name = 'Name',
		order = 5,
		saved = UF.SavedIn(unit, 'name'),
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