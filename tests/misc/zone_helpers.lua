-- What the zone text and world map tests share: Blizzard's zone text and the
-- world map's area label, built as far as SaftUI-Misc/Skinning/ZoneText.lua
-- reaches them, and the module loaded on top. Not a test (no _test suffix);
-- each zone_*_test.lua loads it with load_test_file('misc/zone_helpers.lua').
--
-- Blizzard's frames are locked (fixtures/locked_widget.lua), so SaftUI writing
-- a new field onto one, or replacing one of its scripts with SetScript, fails
-- the test. Blizzard's own code here writes its fields with rawset, or makes
-- them before the lock, as the RestedXP fixture does for RestedXP's.

local H = {}

local locked = load_test_file('misc/fixtures/locked_widget.lua')

local function lock(...)
	for i = 1, select('#', ...) do locked((select(i, ...)), 'Blizzard') end
end

------------------------------------------------------------------ zone text

-- Blizzard_FrameXML/Mainline/ZoneText.lua and .xml (forever; live is the
-- same), trimmed: ZoneText_OnEvent's check for a toast playing
-- (EventToastManagerFrame) is left out, since none plays here, and the
-- frames' OnUpdate (FadingFrame_OnUpdate) never runs in the stubs.
function H.make_zone_text()
	ZoneFadeInDuration = 0.5
	ZoneHoldDuration = 1.0
	ZoneFadeOutDuration = 2.0
	ZonePVPType = nil

	local zone = CreateFrame('Frame', 'ZoneTextFrame', UIParent)
	zone:SetFrameStrata('LOW')
	zone:SetSize(128, 128)
	zone:SetPoint('TOP', 0, -128)
	local zoneString = zone:CreateFontString('ZoneTextString', 'ARTWORK', 'ZoneTextFont')
	zoneString:SetSize(512, 0)
	zoneString:SetPoint('CENTER')
	local pvpString = zone:CreateFontString('PVPInfoTextString', 'ARTWORK', 'PVPInfoTextFont')
	pvpString:SetSize(512, 0)
	pvpString:SetPoint('TOP', zoneString, 'BOTTOM')

	local sub = CreateFrame('Frame', 'SubZoneTextFrame', UIParent)
	sub:SetFrameStrata('LOW')
	sub:SetSize(128, 128)
	sub:SetPoint('BOTTOM', 0, 512)
	local subString = sub:CreateFontString('SubZoneTextString', 'ARTWORK', 'SubZoneTextFont')
	subString:SetSize(512, 0)
	subString:SetPoint('TOP', zoneString, 'BOTTOM')
	local arenaString = sub:CreateFontString('PVPArenaTextString', 'ARTWORK', 'PVPInfoTextFont')
	arenaString:SetSize(512, 0)
	arenaString:SetPoint('TOP', subString, 'BOTTOM')

	function SetZoneText(showZone)
		local pvpType, isSubZonePvP, factionName = C_PvP.GetZonePVPInfo()
		PVPArenaTextString:SetText('')
		PVPInfoTextString:SetText('')
		local pvpTextString = PVPInfoTextString
		if isSubZonePvP then
			pvpTextString = PVPArenaTextString
		end

		if pvpType == 'sanctuary' then
			pvpTextString:SetText('(Sanctuary)')
			pvpTextString:SetTextColor(0.41, 0.8, 0.94)
			ZoneTextString:SetTextColor(0.41, 0.8, 0.94)
			SubZoneTextString:SetTextColor(0.41, 0.8, 0.94)
		elseif pvpType == 'arena' then
			pvpTextString:SetText('(Free-for-All PvP Zone)')
			pvpTextString:SetTextColor(1.0, 0.1, 0.1)
			ZoneTextString:SetTextColor(1.0, 0.1, 0.1)
			SubZoneTextString:SetTextColor(1.0, 0.1, 0.1)
		elseif pvpType == 'friendly' then
			if factionName and factionName ~= '' then
				pvpTextString:SetFormattedText('(%s Territory)', factionName)
				pvpTextString:SetTextColor(0.1, 1.0, 0.1)
			end
			ZoneTextString:SetTextColor(0.1, 1.0, 0.1)
			SubZoneTextString:SetTextColor(0.1, 1.0, 0.1)
		elseif pvpType == 'hostile' then
			if factionName and factionName ~= '' then
				pvpTextString:SetFormattedText('(%s Territory)', factionName)
				pvpTextString:SetTextColor(1.0, 0.1, 0.1)
			end
			ZoneTextString:SetTextColor(1.0, 0.1, 0.1)
			SubZoneTextString:SetTextColor(1.0, 0.1, 0.1)
		elseif pvpType == 'contested' then
			pvpTextString:SetText('(Contested Territory)')
			pvpTextString:SetTextColor(1.0, 0.7, 0)
			ZoneTextString:SetTextColor(1.0, 0.7, 0)
			SubZoneTextString:SetTextColor(1.0, 0.7, 0)
		elseif pvpType == 'combat' then
			pvpTextString = PVPArenaTextString
			pvpTextString:SetText('(Combat Zone)')
			pvpTextString:SetTextColor(1.0, 0.1, 0.1)
			ZoneTextString:SetTextColor(1.0, 0.1, 0.1)
			SubZoneTextString:SetTextColor(1.0, 0.1, 0.1)
		else
			ZoneTextString:SetTextColor(1.0, 0.9294, 0.7607)
			SubZoneTextString:SetTextColor(1.0, 0.9294, 0.7607)
		end

		if ZonePVPType ~= pvpType then
			ZonePVPType = pvpType
		elseif not showZone then
			PVPInfoTextString:SetText('')
			SubZoneTextString:SetPoint('TOP', 'ZoneTextString', 'BOTTOM', 0, 0)
		end

		if PVPInfoTextString:GetText() == '' then
			SubZoneTextString:SetPoint('TOP', 'ZoneTextString', 'BOTTOM', 0, 0)
		else
			SubZoneTextString:SetPoint('TOP', 'PVPInfoTextString', 'BOTTOM', 0, 0)
		end
	end

	function ZoneText_OnLoad(self)
		FadingFrame_OnLoad(self)
		FadingFrame_SetFadeInTime(self, ZoneFadeInDuration)
		FadingFrame_SetHoldTime(self, ZoneHoldDuration)
		FadingFrame_SetFadeOutTime(self, ZoneFadeOutDuration)
		self:RegisterEvent('ZONE_CHANGED')
		self:RegisterEvent('ZONE_CHANGED_INDOORS')
		self:RegisterEvent('ZONE_CHANGED_NEW_AREA')
		self.zoneText = ''
		ZonePVPType = nil
	end

	function ZoneText_OnEvent(self, event, ...)
		local showZoneText = false
		local zoneText = GetZoneText()
		if zoneText ~= self.zoneText or event == 'ZONE_CHANGED_NEW_AREA' then
			rawset(self, 'zoneText', zoneText)
			ZoneTextString:SetText(zoneText)
			showZoneText = true
			SetZoneText(showZoneText)
			FadingFrame_Show(self)
		end

		local subzoneText = GetSubZoneText()
		if subzoneText == '' and not showZoneText then
			subzoneText = zoneText
		end
		SubZoneTextString:SetText('')

		if subzoneText == zoneText then
			showZoneText = false
			if not self:IsShown() then
				SubZoneTextString:SetText(subzoneText)
				SetZoneText(showZoneText)
				FadingFrame_Show(SubZoneTextFrame)
			end
		else
			if self:IsShown() then
				showZoneText = true
			end
			SubZoneTextString:SetText(subzoneText)
			SetZoneText(showZoneText)
			FadingFrame_Show(SubZoneTextFrame)
		end
	end

	function SubZoneText_OnLoad(self)
		FadingFrame_OnLoad(self)
		FadingFrame_SetFadeInTime(self, ZoneFadeInDuration)
		FadingFrame_SetHoldTime(self, ZoneHoldDuration)
		FadingFrame_SetFadeOutTime(self, ZoneFadeOutDuration)
		PVPArenaTextString:SetTextColor(1.0, 0.1, 0.1)
		SetZoneText(true)
		SubZoneTextString:SetText(GetSubZoneText())
	end

	zone:SetScript('OnEvent', ZoneText_OnEvent)
	ZoneText_OnLoad(zone)
	SubZoneText_OnLoad(sub)
	-- FadingFrame_Show writes startTime, which FadingFrame_OnLoad doesn't make.
	zone.startTime, sub.startTime = 0, 0
	lock(zone, zoneString, pvpString, sub, subString, arenaString)
end

-- Enters a zone: sets the zone's names and fires event (ZONE_CHANGED_NEW_AREA
-- by default) at every frame registered for it, Blizzard's zone text among them.
function H.enter(zoneText, subzoneText, event)
	stub.zone_text, stub.subzone_text = zoneText, subzoneText or ''
	stub.fire_event(event or 'ZONE_CHANGED_NEW_AREA')
end

------------------------------------------------------------------ world map

-- MAP_AREA_LABEL_TYPE, AreaLabelDataProviderMixin and AreaLabelFrameMixin are
-- Blizzard_SharedMapDataProviders/AreaLabelDataProvider.lua and .xml (forever),
-- trimmed:
--   - AreaLabelFrameMixin:OnUpdate leaves out the gamepad cursor, the pet
--     battle levels line (a test puts a description in label._description
--     instead) and the names of a map's own areas
--     (MapUtil.FindBestAreaNameAtMouse); the zone's levels take one color,
--     where Blizzard picks a quest difficulty color for the player's level;
--   - AreaLabelFrameTemplate (scale 0.695, Name, Texture and Description) is
--     built by hand, its OnUpdate calling the frame's own OnUpdate method as
--     the template's method="OnUpdate" does.
-- The map is a frame with what WorldMapMixin and MapCanvasMixin give it as far
-- as these reach (dataProviders, AddDataProvider, GetMapID, the cursor), its
-- cursor set by H.hover.
function H.make_world_map()
	MAP_AREA_LABEL_TYPE = { INVASION = 1, AREA_POI_BANNER = 2, AREA_NAME = 3, POI = 4 }
	local LEVEL_COLOR = '|cffffff00'
	local AREA_NAME_COLOR = CreateColor(1.0, 0.9294, 0.7607)
	local AREA_DESCRIPTION_COLOR = CreateColor(1, 1, 1)

	-- Blizzard_SharedXMLBase/Color.lua's AreColorsEqual.
	local function colors_equal(left, right)
		if left and right then return left:IsEqualTo(right) end
		return left == right
	end

	AreaLabelDataProviderMixin = {}
	function AreaLabelDataProviderMixin:GetMap() return self.owningMap end
	function AreaLabelDataProviderMixin:OnAdded(mapCanvas)
		self.owningMap = mapCanvas
		local label = CreateFrame('Frame', nil, mapCanvas:GetCanvasContainer())
		Mixin(label, AreaLabelFrameMixin)
		label:SetScale(0.695)
		label:SetSize(400, 128)
		label.Name = label:CreateFontString(nil, 'OVERLAY', 'WorldMapTextFont')
		label.Name:SetPoint('TOP', 0, -20)
		label.Texture = label:CreateTexture(nil, 'OVERLAY')
		label.Texture:SetPoint('RIGHT', label.Name, 'LEFT')
		label.Texture:Hide()
		label.Description = label:CreateFontString(nil, 'OVERLAY', 'SubZoneTextFont')
		label.Description:SetPoint('TOP', label.Name, 'BOTTOM', 0, -10)
		label:SetScript('OnUpdate', function(frame, ...) frame:OnUpdate(...) end)
		label:OnLoad()
		self.Label = label
		label:SetPoint('TOP', mapCanvas:GetCanvasContainer(), 0, -10)
		label:SetFrameStrata('HIGH')
		label.dataProvider = self
		label.dirty = false
		label:Show()
	end
	function AreaLabelDataProviderMixin:OnSetAreaLabel(...) self.Label:SetLabel(...) end
	function AreaLabelDataProviderMixin:OnClearAreaLabel(...) self.Label:ClearLabel(...) end

	AreaLabelFrameMixin = {}
	function AreaLabelFrameMixin:OnLoad()
		self.labelInfoByType = {}
	end
	function AreaLabelFrameMixin:OnUpdate()
		self:ClearLabel(MAP_AREA_LABEL_TYPE.AREA_NAME)
		local map = self.dataProvider:GetMap()
		if map:IsCanvasMouseFocus() then
			local name, description
			local mapID = map:GetMapID()
			local normalizedCursorX, normalizedCursorY = map:GetNormalizedCursorPosition()
			local positionMapInfo = C_Map.GetMapInfoAtPosition(mapID, normalizedCursorX, normalizedCursorY)
			if positionMapInfo and positionMapInfo.mapID ~= mapID then
				name = positionMapInfo.name
				local playerMinLevel, playerMaxLevel = C_Map.GetMapLevels(positionMapInfo.mapID)
				if name and playerMinLevel and playerMaxLevel and playerMinLevel > 0 and playerMaxLevel > 0 then
					if playerMinLevel ~= playerMaxLevel then
						name = name .. LEVEL_COLOR .. ' (' .. playerMinLevel .. '-' .. playerMaxLevel .. ')' .. FONT_COLOR_CODE_CLOSE
					else
						name = name .. LEVEL_COLOR .. ' (' .. playerMaxLevel .. ')' .. FONT_COLOR_CODE_CLOSE
					end
				end
				description = self._description
			end
			if name then
				self:SetLabel(MAP_AREA_LABEL_TYPE.AREA_NAME, name, description)
			end
		end
		self:EvaluateLabels()
	end
	function AreaLabelFrameMixin:SetLabel(areaLabelType, name, description, nameColor, descriptionColor, textureInfo)
		if not self.labelInfoByType[areaLabelType] then
			self.labelInfoByType[areaLabelType] = {}
		end
		local areaLabelInfo = self.labelInfoByType[areaLabelType]
		if areaLabelInfo.name ~= name or areaLabelInfo.description ~= description
			or not colors_equal(areaLabelInfo.nameColor, nameColor)
			or not colors_equal(areaLabelInfo.descriptionColor, descriptionColor) then
			areaLabelInfo.name = name
			areaLabelInfo.description = description
			areaLabelInfo.nameColor = nameColor
			areaLabelInfo.descriptionColor = descriptionColor
			areaLabelInfo.textureInfo = textureInfo
			rawset(self, 'dirty', true)
		end
	end
	function AreaLabelFrameMixin:ClearLabel(areaLabelType)
		if self.labelInfoByType[areaLabelType] then
			self:SetLabel(areaLabelType, nil)
		end
	end
	function AreaLabelFrameMixin:GetHighestPriorityLabelInfo()
		local highestPriorityAreaLabelType = nil
		for _, areaLabelType in pairs(MAP_AREA_LABEL_TYPE) do
			local areaLabelInfo = self.labelInfoByType[areaLabelType]
			if areaLabelInfo and areaLabelInfo.name then
				if not highestPriorityAreaLabelType or areaLabelType > highestPriorityAreaLabelType then
					highestPriorityAreaLabelType = areaLabelType
				end
			end
		end
		if highestPriorityAreaLabelType then
			return self.labelInfoByType[highestPriorityAreaLabelType]
		end
	end
	function AreaLabelFrameMixin:IsDirty()
		local areaLabelInfo = self:GetHighestPriorityLabelInfo()
		if areaLabelInfo and type(areaLabelInfo.description) == 'function' then
			return true
		end
		return self.dirty
	end
	function AreaLabelFrameMixin:EvaluateLabels()
		if not self:IsDirty() then
			return
		end
		rawset(self, 'dirty', false)
		local areaLabelInfo = self:GetHighestPriorityLabelInfo()
		if areaLabelInfo then
			self.Name:SetText(areaLabelInfo.name)
			local description = (type(areaLabelInfo.description) == 'function' and areaLabelInfo.description()) or areaLabelInfo.description
			self.Description:SetText(description)
			self.Name:SetVertexColor((areaLabelInfo.nameColor or AREA_NAME_COLOR):GetRGB())
			self.Description:SetVertexColor((areaLabelInfo.descriptionColor or AREA_DESCRIPTION_COLOR):GetRGB())
			self.Texture:Hide()
		else
			self.Name:SetText('')
			self.Description:SetText('')
			self.Texture:Hide()
		end
	end

	local map = CreateFrame('Frame', 'WorldMapFrame', UIParent)
	map:SetSize(1000, 700)
	map:SetPoint('CENTER')
	map.ScrollContainer = CreateFrame('Frame', nil, map)
	map.ScrollContainer:SetAllPoints()
	map.dataProviders = {}
	map.mapID = 1415
	function map:GetCanvasContainer() return self.ScrollContainer end
	function map:AddDataProvider(dataProvider)
		self.dataProviders[dataProvider] = true
		dataProvider:OnAdded(self)
	end
	function map:GetMapID() return self.mapID end
	function map:IsCanvasMouseFocus() return self._mouseFocus == true end
	function map:GetNormalizedCursorPosition() return self._cursorX or 0, self._cursorY or 0 end

	-- Another provider first, as the map has dozens: SaftUI looks for the area label's.
	map:AddDataProvider({ OnAdded = function() end })
	local areaLabelDataProvider = CreateFromMixins(AreaLabelDataProviderMixin)
	map:AddDataProvider(areaLabelDataProvider)
	local label = areaLabelDataProvider.Label
	lock(map, label, label.Name, label.Description)
	H.map, H.label = map, label
	H.label_onupdate = label:GetScript('OnUpdate') -- Blizzard's, to check it stays
	return map, label
end

-- Moves the cursor over the map canvas to (x, y), in the shown map's 0-1
-- coordinates (nil: off the canvas), and runs the label's OnUpdate once, as
-- the next frame would.
function H.hover(x, y)
	rawset(H.map, '_mouseFocus', x ~= nil)
	rawset(H.map, '_cursorX', x)
	rawset(H.map, '_cursorY', y)
	stub.fire_script(H.label, 'OnUpdate', 0.016)
end

------------------------------------------------------------------ SaftUI

-- A fresh world with the module enabled, as at login: Core's helpers and
-- LibStringFormat (st.StringFormat, which init.lua sets), SaftUI-Misc's
-- defaults, Blizzard's zone text and (unless opts.map is false) the world map,
-- then the Skinning module, ZoneText.lua and ZoneFactions.lua, and the
-- ZoneText module enabled. Returns the module.
function H.fresh(opts)
	opts = opts or {}
	reset_world()
	load_core_helpers()
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	SaftUI.StringFormat = LibStub('LibStringFormat-1.0')
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	H.make_zone_text()
	if opts.map ~= false then H.make_world_map() end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/ZoneText.lua')
	load_saftui('SaftUI-Misc/Skinning/ZoneFactions.lua')
	local ZT = SaftUI:GetModule('Skinning'):GetModule('ZoneText')
	ZT:Enable()
	return ZT
end

-- The profile's text color named key ('blue', 'red', 'yellow') as the hex
-- digits of a |cff color code.
function H.hex(key)
	local r, g, b = SaftUI.config.profile.colors.text[key]:GetRGB()
	local function byte(v) return math.floor(v * 255 + 0.5) end
	return ('%02x%02x%02x'):format(byte(r), byte(g), byte(b))
end

-- A faction word in its color, as the zone text and the map show it.
function H.colored(word, key)
	return '|cff' .. H.hex(key) .. word .. '|r'
end

-- The anchor of region at point, as { rel =, relPoint =, x =, y = }, or nil.
function H.pt(region, point)
	for i = 1, region:GetNumPoints() do
		local p, rel, relPoint, x, y = region:GetPoint(i)
		if p == point then return { rel = rel, relPoint = relPoint, x = x, y = y } end
	end
end

return H
