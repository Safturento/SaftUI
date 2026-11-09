--[[
	Blizzard's own Lua that SaftUI uses: Mixin and CreateFromMixins, colors
	(CreateColor), EventRegistry, BackdropTemplateMixin, PixelUtil, the
	Enum tables and GameFontNormal. Each follows its
	source in Gethe/wow-ui-source (forever branch), trimmed to what tests use.
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
-- reads: BagIndexConstants, SimpleStatusBarConstants and PowerTypeConstants
-- (PowerType trimmed to Mana).
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
}

------------------------------------------------------------------ fonts

-- GameFontNormal: Blizzard_Fonts_Shared/Shared/FontStyles.xml gives it
-- SystemFont_Shadow_Med1 (Fonts.xml: FRIZQT__.TTF at 12, shadow offset 1, -1)
-- and NORMAL_FONT_COLOR (1, 0.82, 0). The other game fonts aren't stubbed.
GameFontNormal = CreateFont('GameFontNormal')
GameFontNormal:SetFont('Fonts\\FRIZQT__.TTF', 12, '')
GameFontNormal:SetShadowOffset(1, -1)
GameFontNormal:SetTextColor(1, 0.82, 0)
