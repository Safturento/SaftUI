local st = SaftUI
local UF = st:GetModule('Unitframes')

-- The classification marks the level part ends with.
local MARKS = { rare = 'R', rareelite = 'R+', elite = '+', worldboss = 'B' }

-- A level's colour, by its difference from the player's.
local function LevelColor(levelDiff)
	if levelDiff >= 5 then
		return st:Color('text', 'danger')
	elseif levelDiff >= 3 then
		return st:Color('text', 'warning')
	elseif levelDiff >= -3 then
		return st:Color('text', 'caution')
	elseif levelDiff >= -10 then
		return st:Color('text', 'success')
	end
	return st:Color('text', 'muted')
end

-- What goes before the name: the level and the classification mark, in the
-- level's colour, and a space; '' when there's neither. A level left out (a
-- secret one) leaves the mark in the text's own colour.
local function LevelPart(config, level, playerLevel, classification)
	local text = ''
	if config.showLevel and level and playerLevel then
		if level < 0 then
			text = '??'
		elseif config.showSameLevel or level ~= playerLevel then
			text = tostring(level)
		end
		if not config.showMaxLevel and level == GetMaxLevelForLatestExpansion() then
			text = ''
		end
	end
	if config.show_classification then
		text = text .. (MARKS[classification] or '')
	end
	if text == '' then return '' end

	if level and playerLevel then
		text = st.StringFormat:ColorString(text, LevelColor(level - playerLevel):GetRGB())
	end
	return text .. ' '
end

-- The colour code that starts the name, or nil to leave it uncoloured.
local function NameColor(config, unit, reaction)
	if (config.colorClass and (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
			or (config.colorClassNPC and not (UnitIsPlayer(unit) or UnitInPartyIsAI(unit)))
			or (config.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		-- A secret class can't index the colors (as oUF's health element notes,
		-- the class can be secret on retail): the name is then left uncoloured.
		local _, class = UnitClass(unit)
		local classColor = not issecretvalue(class) and class and UF.oUF.colors.class[class]
		return classColor and '|cff' .. st.StringFormat:ToHex(classColor:GetRGB())
	elseif reaction then
		if config.color_hostile and reaction < 3 then
			return '|cff' .. st.StringFormat:ToHex(st:Color('text', 'danger'):GetRGB())
		elseif config.color_hostile and reaction < 5 then
			return '|cff' .. st.StringFormat:ToHex(st:Color('text', 'caution'):GetRGB())
		elseif config.color_friendly and reaction >= 5 then
			local reactionColor = UF.oUF.colors.reaction[reaction]
			return reactionColor and '|cff' .. st.StringFormat:ToHex(reactionColor:GetRGB())
		end
	end
end

UF.oUF.Tags.Events['st:name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP UNIT_FACTION'
-- The unit's name, after its level part, in its class or hostile colour. The
-- name can be secret: it isn't cut or put in capitals then, and the game joins
-- the parts around it (C_StringUtil.WrapString), so the tag returns a secret.
UF.oUF.Tags.Methods['st:name'] = function(unit, realUnit, baseUnit)
	local units = UF:GetProfileConfig()
	if not units[baseUnit] then return '' end
	local config = units[baseUnit].name
	if not config.enable then return '' end

	-- The game hands an addon a unit's level, reaction or classification as a
	-- secret in restricted content (enemy nameplates above all); a secret one
	-- is left out of the text.
	local level, playerLevel = st.Plain(UnitLevel(unit)), st.Plain(UnitLevel('player'))
	local reaction = st.Plain(UnitReaction(unit, 'player'))
	local classification = st.Plain(UnitClassification(unit))

	local prefix, suffix = LevelPart(config, level, playerLevel, classification), ''
	local color = NameColor(config, unit, reaction)
	if color then
		prefix, suffix = prefix .. color, '|r'
	end

	local name = UnitName(unit)
	if issecretvalue(name) then
		return C_StringUtil.WrapString(name, prefix, suffix)
	end

	name = name or ''
	if config.allCaps then
		name = strupper(name)
	end
	return prefix .. st.StringFormat:UTF8strsub(name, config.maxLength) .. suffix
end
