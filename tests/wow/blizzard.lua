--[[
	Blizzard's own Lua that SaftUI uses: Mixin and CreateFromMixins, colors
	(CreateColor, the color codes), EventRegistry, BackdropTemplateMixin,
	C_Texture.GetAtlasInfo (from tests/wow/atlases.lua), PixelUtil, the
	Enum tables, FadingFrame, GameFontNormal and GameFontWhiteSmall, the zone text and world
	map fonts, and ColorPickerFrame. Each follows its source in Gethe/wow-ui-source (forever
	branch), trimmed to what tests use.
]]

local function pack(...)
	return { n = select('#', ...), ... }
end

-- Blizzard_SharedXMLBase/Mixin.lua (Mixin itself is native now): copies every
-- field of each mixin onto object.
function Mixin(object, ...)
	for i = 1, select('#', ...) do
		for k, v in pairs((select(i, ...))) do
			object[k] = v
		end
	end
	return object
end

function CreateFromMixins(...)
	return Mixin({}, ...)
end

------------------------------------------------------------------ colors

-- Blizzard_SharedXMLBase/Color.lua. A color is a plain table with r, g, b, a
-- and the mixin's methods copied onto it.
ColorMixin = {}

function CreateColor(r, g, b, a)
	local color = CreateFromMixins(ColorMixin)
	color:OnLoad(r, g, b, a)
	return color
end

function ColorMixin:OnLoad(r, g, b, a)
	self:SetRGBA(r, g, b, a)
end

function ColorMixin:IsRGBEqualTo(otherColor)
	return self.r == otherColor.r and self.g == otherColor.g and self.b == otherColor.b
end

function ColorMixin:IsEqualTo(otherColor)
	return self:IsRGBEqualTo(otherColor) and self.a == otherColor.a
end

function ColorMixin:GetRGB()
	return self.r, self.g, self.b
end

function ColorMixin:GetRGBA()
	return self.r, self.g, self.b, self.a
end

function ColorMixin:SetRGBA(r, g, b, a)
	self.r = r
	self.g = g
	self.b = b
	self.a = a or 1
end

function ColorMixin:SetRGB(r, g, b)
	self:SetRGBA(r, g, b, nil)
end

-- Color escape codes. FONT_COLOR_CODE_CLOSE is in
-- Blizzard_SharedXML/SharedColorConstants.lua. The game makes
-- NORMAL_FONT_COLOR_CODE from its color table: NORMAL_FONT_COLOR's gold
-- (1, 0.82, 0).
NORMAL_FONT_COLOR_CODE = '|cffffd200'
FONT_COLOR_CODE_CLOSE = '|r'

------------------------------------------------------------------ EventRegistry

-- Blizzard_SharedXMLBase/CallbackRegistry.lua, as EventRegistry uses it
-- (undefined events allowed). An owner has one callback per event. A callback
-- gets (owner, ...), or with extra arguments (owner, extra..., ...).
-- Closures run before plain callbacks, as in game, and errors go to the error
-- handler.
EventRegistry = {}

local callbacks = {} -- event -> list of { owner, func, extra }
local nextOwnerID = 0

function EventRegistry:RegisterCallback(event, func, owner, ...)
	if type(event) ~= 'string' then
		error("CallbackRegistryMixin::RegisterCallback 'event' requires string type.", 2)
	elseif type(func) ~= 'function' then
		error("CallbackRegistryMixin::RegisterCallback 'func' requires function type.", 2)
	end
	if owner == nil then
		nextOwnerID = nextOwnerID + 1
		owner = nextOwnerID
	elseif type(owner) == 'number' then
		error("CallbackRegistryMixin:RegisterCallback 'owner' as number is reserved internally.", 2)
	end
	self:UnregisterCallback(event, owner)
	callbacks[event] = callbacks[event] or {}
	table.insert(callbacks[event], { owner = owner, func = func, extra = pack(...) })
	return owner
end

function EventRegistry:UnregisterCallback(event, owner)
	for i, callback in ipairs(callbacks[event] or {}) do
		if callback.owner == owner then
			table.remove(callbacks[event], i)
			return
		end
	end
end

function EventRegistry:TriggerEvent(event, ...)
	if type(event) ~= 'string' then
		error("CallbackRegistryMixin:TriggerEvent 'event' requires string type.", 2)
	end
	local eventArgs = pack(...)
	local list = {}
	for _, closures in ipairs({ true, false }) do
		for _, callback in ipairs(callbacks[event] or {}) do
			if (callback.extra.n > 0) == closures then list[#list + 1] = callback end
		end
	end
	for _, callback in ipairs(list) do
		local args = { callback.owner }
		for i = 1, callback.extra.n do args[#args + 1] = callback.extra[i] end
		local n = #args
		for i = 1, eventArgs.n do args[n + i] = eventArgs[i] end
		xpcall(function() callback.func(unpack(args, 1, n + eventArgs.n)) end, geterrorhandler())
	end
end

------------------------------------------------------------------ backdrops

-- Blizzard_SharedXML/Backdrop.lua, trimmed. CreateFrame's BackdropTemplate
-- copies these onto the frame, as Mixin does. The real ApplyBackdrop builds
-- nine textures (NineSliceUtil) and colors them. This one makes none, and
-- keeps the colors in the frame's stub state (backdrop_color and
-- backdrop_border_color), which GetBackdropColor and
-- GetBackdropBorderColor read back.
BackdropTemplateMixin = {}

function BackdropTemplateMixin:OnBackdropLoaded()
	if self.backdropInfo then
		if not self.backdropInfo.edgeFile and not self.backdropInfo.bgFile then
			self.backdropInfo = nil
			return
		end
		self:ApplyBackdrop()
	end
end

function BackdropTemplateMixin:OnBackdropSizeChanged()
	if self.backdropInfo then
		self:SetupTextureCoordinates()
	end
end

-- Lays out the pieces' texture coordinates in game. There are no pieces here.
function BackdropTemplateMixin:SetupTextureCoordinates()
end

function BackdropTemplateMixin:HasBackdropInfo(backdropInfo)
	return self.backdropInfo == backdropInfo
end

function BackdropTemplateMixin:ClearBackdrop()
	if self.backdropInfo then
		local state = stub.state(self)
		state.backdrop_color, state.backdrop_border_color = nil, nil
		self.backdropInfo = nil
	end
end

function BackdropTemplateMixin:ApplyBackdrop()
	self:SetBackdropColor(1, 1, 1, 1)
	self:SetBackdropBorderColor(1, 1, 1, 1)
	self:SetupTextureCoordinates()
end

function BackdropTemplateMixin:SetBackdrop(backdropInfo)
	if backdropInfo then
		if self:HasBackdropInfo(backdropInfo) then
			return
		end
		if not backdropInfo.edgeFile and not backdropInfo.bgFile then
			self:ClearBackdrop()
			return
		end
		self.backdropInfo = backdropInfo
		self:ApplyBackdrop()
	else
		self:ClearBackdrop()
	end
end

-- Like the game's, the color setters do nothing without a backdrop.
function BackdropTemplateMixin:GetBackdropColor()
	if not self.backdropInfo then return end
	return unpack(stub.state(self).backdrop_color)
end

function BackdropTemplateMixin:SetBackdropColor(r, g, b, a)
	if not self.backdropInfo then return end
	stub.state(self).backdrop_color = { r, g, b, a or 1 }
end

function BackdropTemplateMixin:GetBackdropBorderColor()
	if not self.backdropInfo then return end
	return unpack(stub.state(self).backdrop_border_color)
end

function BackdropTemplateMixin:SetBackdropBorderColor(r, g, b, a)
	if not self.backdropInfo then return end
	stub.state(self).backdrop_border_color = { r, g, b, a or 1 }
end

------------------------------------------------------------------ atlases

-- C_Texture.GetAtlasInfo, for the atlases tests/wow/atlases.lua lists (the
-- ones the Blizzard theme names), as the client stub.interface stands for has
-- them: { width, height, tilesHorizontally, tilesVertically }, or nil for a
-- name that client hasn't got. Like the game it ignores the name's case. Not
-- mimicked: the rest of the game's AtlasInfo (its file and texture
-- coordinates), and every atlas the theme doesn't name, which reads as missing.
C_Texture = {}

do
	local atlases = load_test_file('wow/atlases.lua')
	local byClient = {}
	for client, list in pairs(atlases) do
		byClient[client] = {}
		for name, info in pairs(list) do
			byClient[client][name:lower()] = info
		end
	end

	function C_Texture.GetAtlasInfo(name)
		if type(name) ~= 'string' then
			error('Usage: local info = C_Texture.GetAtlasInfo(atlas)', 2)
		end
		local info = byClient[stub.interface == 16001 and 'forever' or 'retail'][name:lower()]
		if not info then return nil end
		local tiles = info[3] or ''
		return {
			width = info[1],
			height = info[2],
			tilesHorizontally = tiles:find('h', 1, true) ~= nil,
			tilesVertically = tiles:find('v', 1, true) ~= nil,
		}
	end
end

------------------------------------------------------------------ pixels

-- The game's Round: halves round away from zero.
function Round(value)
	if value < 0 then return math.ceil(value - 0.5) end
	return math.floor(value + 0.5)
end

-- Blizzard_SharedXML/PixelUtil.lua, less SetRoundLayoutToNearestPixelRecursively
-- (the stub widgets have no such layout rounding).
PixelUtil = {}

function PixelUtil.GetPixelToUIUnitFactor()
	local physicalWidth, physicalHeight = GetPhysicalScreenSize()
	return 768.0 / physicalHeight
end

function PixelUtil.GetNearestPixelSize(uiUnitSize, layoutScale, minPixels)
	if uiUnitSize == 0 and (not minPixels or minPixels == 0) then
		return 0
	end

	local uiUnitFactor = PixelUtil.GetPixelToUIUnitFactor()
	local numPixels = Round((uiUnitSize * layoutScale) / uiUnitFactor)
	if minPixels then
		if uiUnitSize < 0.0 then
			if numPixels > -minPixels then
				numPixels = -minPixels
			end
		else
			if numPixels < minPixels then
				numPixels = minPixels
			end
		end
	end

	return numPixels * uiUnitFactor / layoutScale
end

function PixelUtil.ConvertPixelsToUI(desiredPixels, layoutScale)
	return PixelUtil.GetNearestPixelSize(desiredPixels, layoutScale)
end

function PixelUtil.ConvertPixelsToUIForRegion(desiredPixels, region)
	return PixelUtil.GetNearestPixelSize(desiredPixels, region:GetEffectiveScale())
end

function PixelUtil.SetWidth(region, width, minPixels)
	region:SetWidth(PixelUtil.GetNearestPixelSize(width, region:GetEffectiveScale(), minPixels))
end

function PixelUtil.SetHeight(region, height, minPixels)
	region:SetHeight(PixelUtil.GetNearestPixelSize(height, region:GetEffectiveScale(), minPixels))
end

function PixelUtil.SetSize(region, width, height, minWidthPixels, minHeightPixels)
	PixelUtil.SetWidth(region, width, minWidthPixels)
	PixelUtil.SetHeight(region, height, minHeightPixels)
end

function PixelUtil.SetPoint(region, point, relativeTo, relativePoint, offsetX, offsetY, minOffsetXPixels, minOffsetYPixels)
	region:SetPoint(point, relativeTo, relativePoint,
		PixelUtil.GetNearestPixelSize(offsetX, region:GetEffectiveScale(), minOffsetXPixels),
		PixelUtil.GetNearestPixelSize(offsetY, region:GetEffectiveScale(), minOffsetYPixels)
	)
end

------------------------------------------------------------------ Enum

-- Blizzard_APIDocumentationGenerated (forever branch), the enums SaftUI
-- reads: BagIndexConstants, SimpleStatusBarConstants, PowerTypeConstants
-- (PowerType trimmed to Mana), AuraContainerSharedDocumentation
-- (CustomAuraButtonDispelTypeTextureStyle) and MapConstantsDocumentation
-- (UIMapType). A trimmed table errors on a name
-- that isn't stubbed ("Enum.PowerType.Rage is not stubbed") instead of
-- reading nil, which would pass a test where the game has a value. Add the
-- name when a test needs it. BagIndex, StatusBarInterpolation,
-- CustomAuraButtonDispelTypeTextureStyle and UIMapType are complete, and SaftUI's
-- inventory.lua probes BagIndex past its last tab on purpose, so an absent
-- name there stays nil, as in game.
Enum = {
	BagIndex = {
		Accountbanktab = -3, Characterbanktab = -2, Keyring = -1,
		Backpack = 0, Bag_1 = 1, Bag_2 = 2, Bag_3 = 3, Bag_4 = 4, ReagentBag = 5,
		CharacterBankTab_1 = 6, CharacterBankTab_2 = 7, CharacterBankTab_3 = 8,
		CharacterBankTab_4 = 9, CharacterBankTab_5 = 10, CharacterBankTab_6 = 11,
		CharacterBankTab_7 = 12, CharacterBankTab_8 = 13, CharacterBankTab_9 = 14,
		AccountBankTab_1 = 15, AccountBankTab_2 = 16, AccountBankTab_3 = 17,
		AccountBankTab_4 = 18, AccountBankTab_5 = 19, AccountBankTab_6 = 20,
		AccountBankTab_7 = 21, AccountBankTab_8 = 22, AccountBankTab_9 = 23,
	},
	StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 },
	PowerType = { Mana = 0 },
	CustomAuraButtonDispelTypeTextureStyle = { Border = 0, BorderWithIcon = 1, Icon = 2, PreserveAsset = 3, CustomAsset = 4 },
	UIMapType = { Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 },
}
setmetatable(Enum.PowerType, { __index = function(_, name)
	error(('Enum.PowerType.%s is not stubbed'):format(tostring(name)), 2)
end })

------------------------------------------------------------------ fonts

-- GameFontNormal: Blizzard_Fonts_Shared/Shared/FontStyles.xml gives it
-- SystemFont_Shadow_Med1 (Fonts.xml: FRIZQT__.TTF at 12, shadow offset 1, -1)
-- and NORMAL_FONT_COLOR (1, 0.82, 0). Game fonts not below aren't stubbed.
GameFontNormal = CreateFont('GameFontNormal')
GameFontNormal:SetFont('Fonts\\FRIZQT__.TTF', 12, '')
GameFontNormal:SetShadowOffset(1, -1)
GameFontNormal:SetTextColor(1, 0.82, 0)

-- GameFontWhiteSmall: SystemFont_Shadow_Small (FRIZQT__.TTF at 10, shadow
-- offset 1, -1) in white. st:CreateHeader gives a header's title this font first.
GameFontWhiteSmall = CreateFont('GameFontWhiteSmall')
GameFontWhiteSmall:SetFont('Fonts\\FRIZQT__.TTF', 10, '')
GameFontWhiteSmall:SetShadowOffset(1, -1)
GameFontWhiteSmall:SetTextColor(1, 1, 1)

-- The zone text's and the world map's area label's fonts
-- (Blizzard_Fonts_Shared/Shared/GameFontStyles.xml, from GameFonts.xml's
-- thick-outlined FRIZQT__.TTF families): ZoneTextFont and WorldMapTextFont
-- at 32 in a pale gold, SubZoneTextFont at 26 and PVPInfoTextFont at 22.
for name, size in pairs({ ZoneTextFont = 32, WorldMapTextFont = 32, SubZoneTextFont = 26, PVPInfoTextFont = 22 }) do
	local font = CreateFont(name)
	font:SetFont('Fonts\\FRIZQT__.TTF', size, 'THICKOUTLINE')
	if size == 32 then font:SetTextColor(1.0, 0.9294, 0.7607) end
end

------------------------------------------------------------------ FadingFrame

-- Blizzard_FrameXMLUtil/FadingFrame.lua: a frame that fades in, holds and
-- fades out, its times kept in its own fields. FadingFrame_OnUpdate isn't
-- here: the stubs run no OnUpdate.
function FadingFrame_SetFadeInTime(fadingFrame, time) fadingFrame.fadeInTime = time end
function FadingFrame_SetHoldTime(fadingFrame, time) fadingFrame.holdTime = time end
function FadingFrame_SetFadeOutTime(fadingFrame, time) fadingFrame.fadeOutTime = time end
function FadingFrame_OnLoad(fadingFrame)
	assert(fadingFrame)
	fadingFrame.fadeInTime = 0
	fadingFrame.holdTime = 0
	fadingFrame.fadeOutTime = 0
	fadingFrame:Hide()
end
function FadingFrame_Show(fadingFrame)
	assert(fadingFrame)
	fadingFrame.startTime = GetTime()
	fadingFrame:Show()
end

------------------------------------------------------------------ ColorPickerFrame

-- Blizzard_ColorPickerFrame (forever branch, Mainline family): the public
-- API addons use, with opacity as alpha (1 is solid). SetupColorPickerAndShow
-- stores the callbacks and sets the color, which makes the picker's color
-- select fire swatchFunc and opacityFunc once while it opens (with the alpha
-- the picker still had from before, as GetColorAlpha gives it), then shows it;
-- OnShow sets the alpha when hasOpacity. A user picking a color calls both
-- functions; Okay calls both and hides; Cancel calls cancelFunc(previousValues)
-- and hides. stub.pick_color, stub.color_picker_okay and stub.color_picker_cancel
-- play the user. Not mimicked: the wheel, the hex box, GLOBAL_MOUSE_DOWN
-- (which cancels when the user clicks elsewhere), or the older picker's
-- fields (func, opacityFunc, ...) that Classic-family clients use.
do
	local picker = CreateFrame('Frame', 'ColorPickerFrame', UIParent)
	picker:Hide()
	local color = { r = 1, g = 1, b = 1, a = 1 }

	local function select_color()
		if picker.swatchFunc then picker.swatchFunc() end
		if picker.opacityFunc then picker.opacityFunc() end
	end

	function picker:SetupColorPickerAndShow(info)
		self.swatchFunc = info.swatchFunc
		self.hasOpacity = info.hasOpacity
		self.opacityFunc = info.opacityFunc
		self.opacity = info.opacity
		self.previousValues = { r = info.r, g = info.g, b = info.b, a = info.opacity }
		self.cancelFunc = info.cancelFunc
		self.extraInfo = info.extraInfo
		color.r, color.g, color.b = info.r, info.g, info.b
		select_color()
		self:Show()
		if self.hasOpacity then
			color.a = self.opacity
			select_color()
		end
	end
	function picker:GetColorRGB() return color.r, color.g, color.b end
	function picker:GetColorAlpha() return color.a end
	function picker:GetExtraInfo() return self.extraInfo end
	function picker:GetPreviousValues()
		local p = self.previousValues
		return p.r, p.g, p.b, p.a
	end

	function stub.pick_color(r, g, b, a)
		color.r, color.g, color.b = r, g, b
		if a ~= nil then color.a = a end
		select_color()
	end
	function stub.color_picker_okay()
		picker.swatchFunc()
		if picker.opacityFunc then picker.opacityFunc() end
		picker:Hide()
	end
	function stub.color_picker_cancel()
		if picker.cancelFunc then picker.cancelFunc(picker.previousValues) end
		picker:Hide()
	end
	-- What alpha the picker still holds, for a test of the stale value a
	-- picker opened without opacity reads.
	function stub.set_color_picker_alpha(a) color.a = a end
end
