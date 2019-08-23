local ADDON_NAME, st = ...

local UF = st:GetModule('Unitframes')

UF.oUF.Tags.Events['st:name'] = 'UNIT_NAME_UPDATE UNIT_LEVEL PLAYER_LEVEL_UP'
UF.oUF.Tags.Methods['st:name'] = function(unit)
	local level = UnitLevel(unit)
	local playerLevel = UnitLevel('player')
	local name = UnitName(unit)
	local classification = UnitClassification(unit)
	local string = ''

	local baseunit = unit == 'vehicle' and 'player' or strmatch(unit, '%D+')
	if not st.Saved.profile.UnitFrames.units[baseunit] then return '' end
	local config = st.Saved.profile.UnitFrames.units[baseunit].name
	if not config.enable then return '' end

	-- Set level coloring based on level difference between unit and player
	local levelDiff = level - playerLevel;

	local color
	if ( levelDiff >= 3 ) then
		color = st.Saved.profile.Colors.textred
	elseif ( levelDiff >= -4 ) then
		color = st.Saved.profile.Colors.textyellow
	elseif ( -levelDiff >= GetQuestGreenRange() ) then
		color = st.Saved.profile.Colors.textgreen
	else
		color = st.Saved.profile.Colors.textgrey
	end

	local levelString = ''
	if config.showlevel then
		if level < 0 then
			levelString = '??'
		elseif not (not config.showsamelevel and level == playerLevel) then
			levelString = level
		end
	end
	
	if config.showclassification then
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

	return st.StringFormat:ColorString(levelString, unpack(color)) .. (strlen(levelString) > 0 and ' ' or '') .. st.StringFormat:UTF8strsub(name or '', config.maxlength)
end