local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

UF.oUF.Tags.Events['st:name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP PLAYER_TARGET_CHANGED'
UF.oUF.Tags.Methods['st:name'] = function(unit)
	local level = UnitLevel(unit)
	local playerLevel = UnitLevel('player')
	local name = UnitName(unit)
	local reaction = UnitReaction('player', unit)
	local classification = UnitClassification(unit)
	local string = ''

	local baseunit = unit == 'vehicle' and 'player' or strmatch(unit, '%D+')
	if not st.config.profile.unitframes.profiles[UF:GetProfile()][baseunit] then return '' end
	local config = st.config.profile.unitframes.profiles[UF:GetProfile()][baseunit].name
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
	if config.show_level then
		if level < 0 then
			levelString = '??'
		elseif config.show_samelevel or level ~= playerLevel then
			levelString = level
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
	
	if config.all_caps then
		name = strupper(name)
	end

	if config.color_hostile and reaction then
		if reaction < 3 then
			name = st.StringFormat:ColorString(name, unpack(st.config.profile.colors.text.red))
		elseif reaction < 5 then
			name = st.StringFormat:ColorString(name, unpack(st.config.profile.colors.text.yellow))
		end
	end
	string = string .. st.StringFormat:UTF8strsub(name or '', config.max_length)

	if baseunit == 'nameplate' and UnitIsUnit(unit, 'target') then
		string = string .. ' <'
	end

	return string
end