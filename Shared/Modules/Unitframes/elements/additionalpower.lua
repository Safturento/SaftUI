local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Update(self, event, unit, powerType)
	if(self.unit ~= unit) then return end
	local element = self.AdditionalPower

	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	--TODO: Override powertype to maelstrom for ele/enh shamans in ghost wolf

	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	element.cur = cur
	element.max = max

	if(element.PostUpdate) then
		element:PostUpdate(cur, max)
	end
end

local function PostUpdate(self, curr, max)
	self.text:SetText(curr)
end

local function PostVisibility(self, enabled)
	--TODO: Override visibility for ele/enh shaman in ghost wolf to show anyways

	self.text:SetShown(enabled)
end

local function Constructor(self)
	if not ALT_MANA_BAR_PAIR_DISPLAY_INFO[st.my_class] then return end

	local power = CreateFrame('StatusBar', nil, self)
	power.config = self.config.additionalPower

	power.bg = power:CreateTexture(nil, 'BACKGROUND')
	power.bg:SetAllPoints(power)
	power.bg:SetTexture(st.BLANK_TEX)

	power.text = self.TextOverlay:CreateFontString(nil, 'OVERLAY')
	-- We have to set this here since PostUpdatePower can run before UpdateConfig
	power.text:SetFontObject(st:GetFont(self.config.power.text.font))

	power.PostVisibility = PostVisibility
	power.PostUpdate = PostUpdate
	self.AdditionalPower = power
	return power
end

local function UpdateConfig(self)
	local element = self.AdditionalPower
	element.config = self.config.additionalPower

	if not element.config.enable then
		element:Hide()
		return
	else
		element:Show()
	end

	element.Override = element.config.manaAsPrimary and Update or nil

	if element.config.relative_height then
		element:SetHeight(self.config.height + element.config.height)
	else
		element:SetHeight(element.config.height)
	end

	if element.config.relative_width then
		element:SetWidth(self.config.width + element.config.width)
	else
		element:SetWidth(element.config.width)
	end

	st:SetBackdrop(element, element.config.template)

	element:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(element.config.position)
	local frame = UF:GetFrame(self, element.config.position)
	element:SetPoint(anchor, frame, rel_anchor, x_off, y_off)


	element:SetFrameLevel(element.config.framelevel)
	element:SetStatusBarTexture(st.BLANK_TEX)

	if element.config.colorCustom then
		element:SetStatusBarColor(unpack(element.config.customColor))
	end

	if element.config.bg.enable then
		element.bg:Show()
		element.bg:SetAlpha(element.config.bg.alpha)
		element.bg.multiplier = element.config.bg.multiplier
		element.bg:SetTexture(st.BLANK_TEX)
	else
		element.bg:Hide()
	end

	if element.config.text.enable then
		element.text:Show()
		element.text:SetFontObject(st:GetFont(element.config.text.font))
		element.text:ClearAllPoints()
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(element.config.text.position)
		local frame = UF:GetFrame(self, element.config.text.position)
		element.text:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	else
		element.text:Hide()
	end

	element:SetReverseFill(element.config.reverse_fill)
	element:SetOrientation(element.config.vertical_fill and "VERTICAL" or "HORIZONTAL")

	element.Smooth = true
	element.colorPower			= element.config.colorPower
	element.colorClass			= element.config.colorClass
	element.colorCustom			= element.config.colorCustom
	element.customColor 			= element.config.customColor
end

UF:RegisterElement('AdditionalPower', Constructor, UpdateConfig)