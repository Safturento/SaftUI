local st = SaftUI
local SK = st:GetModule('Skinning')
local ZT = SK:NewModule('ZoneText')

-- The zone text that shows when you enter a zone, in SaftUI's fonts, with a
-- line under the zone name giving its level range and who holds it, and the
-- same faction on the world map's zone label. The faction table is
-- ZoneFactions.lua's.

local colors = {
	lfr    = '68de57',
	normal = 'ffeac2',
	heroic = '5794de',
	mythic = 'a357de',
}

-- How long the zone text fades in, holds and fades out, in seconds. Blizzard's
-- are 0.5, 1 and 2.
local FADE_IN, HOLD, FADE_OUT = 1, 2, 2

local EN_DASH = '\226\128\147' -- U+2013, between the ends of a level range
local MIDDLE_DOT = '\194\183' -- U+00B7, between the level range and the faction

function ZT:SetZoneDifficultyText()
	local name, instanceType, difficultyID, difficultyName,
		maxPlayers, dynamicDifficulty, isDynamic, instanceID,
		instanceGroupSize, LfgDungeonID = GetInstanceInfo()

	local name, groupType, isHeroic, isChallengeMode, displayHeroic,
		displayMythic, toggleDifficultyID, isLFR, minPlayers,
		_ = GetDifficultyInfo(difficultyID)

	-- The difficulty shows with the zone name, which Blizzard's handler (run
	-- before this) shows when you enter a zone.
	if maxPlayers == 0 or not ZoneTextFrame:IsShown() then
		self.DifficultyTextString:SetText("")
		return
	end

	local color
	if displayMythic then
		color = colors.mythic
	elseif isHeroic or displayHeroic then
		color = colors.heroic
	elseif isLFR then
		color = colors.lfr
	else
		color = colors.normal
	end

	self.DifficultyTextString:SetText(st.StringFormat:ColorString(difficultyName, color))
end

------------------------------------------------------------------ the faction

-- The three words for who holds a zone, and the Colors tab text color of each.
ZT.FACTION_COLORS = { Alliance = 'blue', Horde = 'red', Neutral = 'yellow' }

local OTHER_FACTION = { Alliance = 'Horde', Horde = 'Alliance' }

-- Who holds a zone, from the game's PvP status there (C_PvP.GetZonePVPInfo's
-- pvpType and factionName): a 'friendly' or 'hostile' zone is held by the
-- faction factionName names; anything else (contested, sanctuary, arena,
-- combat, none) is Neutral. factionName is in the client's language, so where
-- it isn't the English word, a friendly zone is the player's own faction's and
-- a hostile one the other's.
function ZT.FactionFromPvP(pvpType, factionName)
	if pvpType ~= 'friendly' and pvpType ~= 'hostile' then return 'Neutral' end
	if OTHER_FACTION[factionName] then return factionName end
	local mine = UnitFactionGroup('player')
	if not OTHER_FACTION[mine] then return 'Neutral' end
	return pvpType == 'friendly' and mine or OTHER_FACTION[mine]
end

-- Who holds the zone the player stands in, by the game's live PvP status; nil
-- when the game gives none (an empty pvpType, or nothing at all). Both clients
-- have it as C_PvP's (neither has a global GetZonePVPInfo).
function ZT:LiveFaction()
	local pvpType, _, factionName = C_PvP.GetZonePVPInfo()
	if pvpType == nil or pvpType == '' then return nil end
	return ZT.FactionFromPvP(pvpType, factionName)
end

local function Byte(value)
	return math.floor(value * 255 + 0.5)
end

-- A faction's word in its Colors tab text color, as a color-coded string.
function ZT:ColorFaction(faction)
	local r, g, b = st.config.profile.colors.text[ZT.FACTION_COLORS[faction]]:GetRGB()
	return ('|cff%02x%02x%02x%s|r'):format(Byte(r), Byte(g), Byte(b), faction)
end

------------------------------------------------------------------ where the player is

-- Whether the player's map is climbed out of to reach the map it's in: always
-- out of a cave, building or dungeon floor (Micro); out of a map outside the
-- usual tree (Orphan, such as a garrison) only outside an instance, since the
-- game files many instances (battlegrounds, some dungeons and raids) as orphan
-- maps under the zone outside them.
local function Climbs(mapType, inInstance)
	return mapType == Enum.UIMapType.Micro or (mapType == Enum.UIMapType.Orphan and not inInstance)
end

-- The maps the player stands in, from the game's best map for them up to the
-- zone it's in, never up to a continent. A dungeon is a map of its own.
local function PlayerMaps()
	local maps = {}
	local inInstance = IsInInstance()
	local mapID = C_Map.GetBestMapForUnit('player')
	while mapID do
		local info = C_Map.GetMapInfo(mapID)
		if not info or info.mapType < Enum.UIMapType.Zone then break end
		maps[#maps + 1] = mapID
		if not Climbs(info.mapType, inInstance) then break end
		mapID = info.parentMapID
	end
	return maps
end

-- The level range of the zone the player is in: the first of their maps the
-- game gives one for. Nothing without one.
function ZT:PlayerZoneLevels()
	for _, mapID in ipairs(PlayerMaps()) do
		local minLevel, maxLevel = C_Map.GetMapLevels(mapID)
		if minLevel and maxLevel and minLevel > 0 and maxLevel > 0 then
			return minLevel, maxLevel
		end
	end
end

-- Whether the player stands in map, or in a cave or orphan map within it.
function ZT:IsPlayerIn(mapID)
	for _, playerMapID in ipairs(PlayerMaps()) do
		if playerMapID == mapID then return true end
	end
	return false
end

-- 'Level 10-20' (with an en dash), or 'Level 70' when both ends match; nil
-- without a range (the game gives 0s for a map it has none for).
function ZT.FormatLevels(minLevel, maxLevel)
	if not (minLevel and maxLevel and minLevel > 0 and maxLevel > 0) then return nil end
	if minLevel == maxLevel then return 'Level ' .. maxLevel end
	return 'Level ' .. minLevel .. EN_DASH .. maxLevel
end

------------------------------------------------------------------ the zone text

-- The line under the zone name: the zone's level range and who holds it, e.g.
-- 'Level 10-20 . Alliance' (an en dash, a middle dot), or either part alone.
-- With no PvP status the faction is Neutral. In an instance there's no
-- faction: the difficulty line under the subzone says what kind it is. ''
-- when there's neither.
function ZT:ZoneLine()
	local levels = ZT.FormatLevels(self:PlayerZoneLevels())
	local faction = not IsInInstance() and self:ColorFaction(self:LiveFaction() or 'Neutral') or nil
	if levels and faction then
		return levels .. ' ' .. MIDDLE_DOT .. ' ' .. faction
	end
	return levels or faction or ''
end

-- The line and the subzone name are both subtitle text, whose height leaves
-- them touching; the zone name's taller font leaves room above the line.
local LINE_GAP = 6

-- Sets the line, and puts the subzone name under it, LINE_GAP below, while
-- the zone name shows. Blizzard puts the subzone name under its own PvP line,
-- which SaftUI's replaces, or under the zone name; this runs after it, each time.
function ZT:UpdateZoneLine()
	local line = self:ZoneLine()
	self.ZoneLineString:SetTextColor(st.config.profile.colors.text.normal:GetRGB())
	self.ZoneLineString:SetText(line)
	if line ~= '' and ZoneTextFrame:IsShown() then
		SubZoneTextString:SetPoint('TOP', self.ZoneLineString, 'BOTTOM', 0, -LINE_GAP)
	else
		SubZoneTextString:SetPoint('TOP', ZoneTextString, 'BOTTOM', 0, 0)
	end
end

-- The lines either side of the zone name show only while it has a name to
-- flank: a banner can clear it (ZoneText_Clear) while its frame fades on.
function ZT:SetFlourishesShown(shown)
	for _, flourish in pairs(self.flourishes) do
		flourish:SetShown(shown)
	end
end

-- The lines either side of the zone name take its color.
function ZT:ColorFlourishes()
	local zoneTextColor = { ZoneTextString:GetTextColor() }
	for _, flourish in pairs(self.flourishes) do
		flourish.backdrop:SetBackdropColor(unpack(zoneTextColor))
	end
end

-- After Blizzard's own handler for the event (a post-hook): it has set the
-- zone and subzone names and their color. A new zone or subzone can change
-- the live status of the zone the map's cursor is on, so the map's line is
-- worked out again too.
function ZT:OnEvent(frame, event, ...)
	self:SetFlourishesShown((ZoneTextString:GetText() or '') ~= '')
	self:ColorFlourishes()
	self:SetZoneDifficultyText()
	self:UpdateZoneLine()
	self.mapLineFor = nil
end

------------------------------------------------------------------ the world map

-- The zone under the world map's cursor, when it's the one the map's zone
-- label names (Blizzard's label adds the zone's levels after its name), so a
-- label made from another cursor (a gamepad's) gets no line.
function ZT:HoveredZone(labelName)
	local map = self.worldMap
	local mapID = map:GetMapID()
	local x, y = map:GetNormalizedCursorPosition()
	local info = mapID and x and y and C_Map.GetMapInfoAtPosition(mapID, x, y)
	if info and info.mapID ~= mapID and info.name and labelName:sub(1, #info.name) == info.name then
		return info.mapID
	end
end

-- Who holds a zone on the map: for the zone the player is in, the game's live
-- PvP status when it gives one; otherwise ZoneFactions.lua's table. nil for a
-- zone the table doesn't list.
function ZT:MapFaction(mapID)
	if not mapID then return nil end
	return self:IsPlayerIn(mapID) and self:LiveFaction() or self:GetZoneFaction(mapID)
end

-- After the zone label's OnUpdate, each frame: while it shows a zone's name
-- (its AREA_NAME label, rather than a point of interest's), the faction line
-- shows under the name, or under the description when there is one. Worked out
-- again only when the name changes.
function ZT:UpdateMapLine(label)
	local line = self.mapLine
	local info = label.labelInfoByType and label.labelInfoByType[MAP_AREA_LABEL_TYPE.AREA_NAME]
	local name = info and info.name
	if not name or label.Name:GetText() ~= name then
		self.mapLineFor = nil
		line:Hide()
		return
	end
	if name == self.mapLineFor then return end
	self.mapLineFor = name

	local faction = self:MapFaction(self:HoveredZone(name))
	if not faction then
		line:Hide()
		return
	end
	line:SetText(self:ColorFaction(faction))
	local description = label.Description:GetText()
	local above = (description and description ~= '') and label.Description or label.Name
	line:SetPoint('TOP', above, 'BOTTOM', 0, -10)
	line:Show()
end

-- Finds the world map's zone label, Blizzard's AreaLabelFrameTemplate frame that
-- the map's area label data provider made, and adds SaftUI's line to it. Its
-- methods were copied onto it from AreaLabelFrameMixin, so the hook goes on
-- the frame's own OnUpdate script, not on the mixin.
function ZT:HookWorldMap()
	local map, mixin = WorldMapFrame, AreaLabelDataProviderMixin
	if self.mapLine or not (map and map.dataProviders and mixin) then return end
	local label
	for provider in pairs(map.dataProviders) do
		if provider.OnSetAreaLabel == mixin.OnSetAreaLabel and provider.Label then
			label = provider.Label
		end
	end
	if not label then return end

	self.worldMap = map
	self.mapLine = label:CreateFontString(nil, 'OVERLAY')
	self.mapLine:SetFontObject(SubZoneTextFont) -- as the label's description
	self.mapLine:Hide()
	label:HookScript('OnUpdate', function(frame) self:UpdateMapLine(frame) end)
end

function ZT:ADDON_LOADED(event, addon)
	if addon == 'Blizzard_WorldMap' then
		self:UnregisterEvent('ADDON_LOADED')
		self:HookWorldMap()
	end
end

-- After a theme recolor (st:RecolorThemed gave the lines Thin's colors): the zone
-- name's color goes back on. After a text color change, the faction takes its
-- new color: on the zone text at once, on the map on its next frame. Skinning
-- passes it on.
function ZT:OnColorsChanged(group)
	if group == 'theme' and self.flourishes then
		self:ColorFlourishes()
	elseif group == 'text' and self.ZoneLineString then
		self.mapLineFor = nil
		if ZoneTextFrame:IsShown() then self:UpdateZoneLine() end
	end
end

function ZT:OnEnable()
	-- Blizzard's handler shows the zone text on loading screens too (/reload,
	-- entering an instance). Registering is a widget call: nothing is written
	-- onto the frame, and the game still runs Blizzard's handler itself.
	ZoneTextFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- A post-hook (taint.md rule 2): Blizzard's handler stays the frame's
	-- script, untainted, and runs first.
	ZoneTextFrame:HookScript('OnEvent', function(frame, event, ...) self:OnEvent(frame, event, ...) end)
	-- A plain frame, not an Edit Mode system, that Blizzard places only in its XML.
	ZoneTextFrame:SetPoint('TOP', 0, -300)

	ZoneTextString:SetFontObject(st:GetFont('title'))
	SubZoneTextString:SetFontObject(st:GetFont('subtitle'))
	PVPArenaTextString:SetFontObject(st:GetFont('subtitle'))
	-- SaftUI's line takes the place of Blizzard's PvP line ("(Contested
	-- Territory)"), which Blizzard keeps writing. It stays where it is, unseen:
	-- alpha is a widget setting, so nothing is written onto it, and Blizzard
	-- never sets it.
	PVPInfoTextString:SetAlpha(0)
	self.ZoneLineString = st:CreateFontString(ZoneTextFrame, 'subtitle')
	self.ZoneLineString:SetPoint('TOP', ZoneTextString, 'BOTTOM')
	self.DifficultyTextString = st:CreateFontString(SubZoneTextFrame, 'subtitle', 'test')
	self.DifficultyTextString:SetPoint('TOP', SubZoneTextString, 'BOTTOM', 0, -7)
	-- A banner played over the zone text (a world quest's, a PvP objective's)
	-- clears Blizzard's strings with ZoneText_Clear while the frames fade on.
	-- SaftUI's lines go with them, and its flourishes hide until a zone change
	-- shows a zone name again (ZT:OnEvent). A post-hook: the banner's call
	-- stays Blizzard's, and only SaftUI's own font strings and frames change.
	if ZoneText_Clear then
		hooksecurefunc('ZoneText_Clear', function()
			self.ZoneLineString:SetText('')
			self.DifficultyTextString:SetText('')
			self:SetFlourishesShown(false)
		end)
	end

	-- SaftUI's fade times. Blizzard keeps them in fields on the two frames, set
	-- through its FadingFrame setters; its ZoneFadeInDuration and the other
	-- globals are read only when the frames load, so they're left alone. The
	-- setters still write those fields from SaftUI's code, which taint.md rule 1
	-- asks against. Only the frames' own FadingFrame_OnUpdate reads them, to
	-- fade and hide the frames, which nothing protected depends on
	-- (docs/followups.md, "Zone text's fade times are written onto Blizzard's frames").
	for _, frame in ipairs({ ZoneTextFrame, SubZoneTextFrame }) do
		FadingFrame_SetFadeInTime(frame, FADE_IN)
		FadingFrame_SetHoldTime(frame, HOLD)
		FadingFrame_SetFadeOutTime(frame, FADE_OUT)
	end

	-- SaftUI's lines either side of the zone name, kept here: nothing is written onto
	-- Blizzard's ZoneTextFrame.
	self.flourishes = {}
	for _,side in pairs({'Left', 'Right'}) do
		local flourish = st:CreateFrame('Frame', nil, ZoneTextFrame)
		flourish:SetSize(100, 2)
		st:SetBackdrop(flourish, 'thin', 'solid', 'small')
		ZoneTextString:SetWidth(0)
		if side == 'Left' then
			flourish:SetPoint('RIGHT', ZoneTextString, 'LEFT', -20, 0)
		else
			flourish:SetPoint('LEFT', ZoneTextString, 'RIGHT', 20, 0)
		end
		self.flourishes[side] = flourish
	end

	-- The world map's zone label. Blizzard_WorldMap is loaded before SaftUI on
	-- both clients; should it load later, it's hooked then.
	if WorldMapFrame then
		self:HookWorldMap()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
