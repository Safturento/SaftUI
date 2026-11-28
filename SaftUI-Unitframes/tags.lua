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

-- The colour code that starts the name, or nil to leave it uncoloured. info is
-- NameParts': isPlayer (false for a non-player, nil when unknown: colorClassNPC
-- needs the false), isPet, class and reaction, each nil when unknown.
local function NameColor(config, info)
	local reaction = info.reaction
	if (config.colorClass and info.isPlayer)
			or (config.colorClassNPC and info.isPlayer == false)
			or (config.colorClassPet and info.isPet) then
		-- A secret class can't index the colors (as oUF's health element notes,
		-- the class can be secret on retail): the caller passes none then and
		-- the name is left uncoloured.
		local class = info.class
		local classColor = class and UF.oUF.colors.class[class]
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

-- What goes around a unit's name: the level part, then the colour code and its
-- end. config is a unit's name table; info = { level, playerLevel,
-- classification, reaction, isPlayer, isPet, class }, plain values, nil for
-- one unknown or secret. The preview and the tag both come here.
function UF.NameParts(config, info)
	local prefix, suffix = LevelPart(config, info.level, info.playerLevel, info.classification), ''
	local color = NameColor(config, info)
	if color then
		prefix, suffix = prefix .. color, '|r'
	end
	return prefix, suffix
end

-- The plain name between its parts: in capitals when asked, cut to maxLength.
function UF.FormatName(config, name, prefix, suffix)
	name = name or ''
	if config.allCaps then
		name = strupper(name)
	end
	return prefix .. st.StringFormat:UTF8strsub(name, config.maxLength) .. suffix
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

	-- Read only behind the flags that use them, as the game can hand these
	-- back secret on an enemy plate: a secret one counts as unknown (nil).
	local isPlayer, isPet, class
	if config.colorClass or config.colorClassNPC or config.colorClassPet then
		local function plain(value)
			if issecretvalue(value) then return nil end
			return value
		end
		local player, ai = plain(UnitIsPlayer(unit)), plain(UnitInPartyIsAI(unit))
		if player ~= nil then
			isPlayer = (player or ai) and true or false
		elseif ai then
			isPlayer = true
		end
		local controlled = plain(UnitPlayerControlled(unit))
		if controlled ~= nil and player ~= nil then
			isPet = controlled and not player
		end
		class = plain(select(2, UnitClass(unit)))
	end
	local prefix, suffix = UF.NameParts(config, {
		level = level, playerLevel = playerLevel, classification = classification, reaction = reaction,
		isPlayer = isPlayer, isPet = isPet, class = class,
	})

	local name = UnitName(unit)
	if issecretvalue(name) then
		return C_StringUtil.WrapString(name, prefix, suffix)
	end

	return UF.FormatName(config, name, prefix, suffix)
end
