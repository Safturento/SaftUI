local st = SaftUI
local UF = st:GetModule('Unitframes')

UF.oUF.Tags.Events['st:name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP PLAYER_TARGET_CHANGED'
UF.oUF.Tags.Methods['st:name'] = function(unit, realUnit, baseUnit)
	local level = UnitLevel(unit)
	local playerLevel = UnitLevel('player')
	local name = UnitName(unit)
	local reaction = UnitReaction(unit, 'player')
	local classification = UnitClassification(unit)
	local string = ''

	if not UF:GetProfileConfig()[baseUnit] then return '' end
	local config = UF:GetProfileConfig()[baseUnit].name
	if not config.enable then return '' end

	-- mob level relative to you
	local levelDiff = level - playerLevel;
	
	local color
	if (levelDiff >= 5) then
		color = st.config.profile.colors.text.red
	elseif ( levelDiff >= 3 ) then
		color = st.config.profile.colors.text.orange
	elseif ( levelDiff >= -3 ) then
		color = st.config.profile.colors.text.yellow
	elseif ( levelDiff >= -10 ) then
		color = st.config.profile.colors.text.green
	else
		color = st.config.profile.colors.text.grey
	end

	local levelString = ''
	if config.showLevel then
		if level < 0 then
			levelString = '??'
		elseif (config.showSameLevel or level ~= playerLevel) then
			levelString = level
		end

		if (not config.showMaxLevel and level == (st.retail and GetMaxLevelForLatestExpansion() or GetMaxPlayerLevel())) then
			levelString = ''
		end
	end
	
	if config.show_classification then
		if(classification == 'rare') then
			levelString = levelString .. 'R'
		elseif(classification == 'eliterare') then
			levelString = levelString .. 'R+'
		elseif(classification == 'elite') then
			levelString = levelString .. '+'
		elseif(classification == 'worldboss') then
			levelString = levelString .. 'B'
		end
	end

	levelString = st.StringFormat:ColorString(levelString, unpack(color)) .. (strlen(levelString) > 0 and ' ' or '')
	string = string .. levelString
	
	if config.allCaps then
		name = strupper(name)
	end

	if not issecretvalue(name) then
		name = st.StringFormat:UTF8strsub(name or '', config.maxLength)
	end
	if config.color_hostile and reaction then
		if reaction < 3 then
			name = st.StringFormat:ColorString(name, unpack(st.config.profile.colors.text.red))
		elseif reaction < 5 then
			name = st.StringFormat:ColorString(name, unpack(st.config.profile.colors.text.yellow))
		end
	end
	string = string .. name

	if baseunit == 'nameplate' and UnitIsUnit(unit, 'target') then
		string = string .. ' <'
	end

	return string
end