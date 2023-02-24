local st = SaftUI
local UF = st:GetModule('Unitframes')

local AURAS = {'Buffs', 'Debuffs'}

function isWhitelisted(whitelist, data)
    if not whitelist.enable then return true end
    if whitelist.yours and isCastByPlayer(data) then return true end
    if whitelist.others and not isCastByPlayer(data) then return true end
    if whitelist.stealable and data.isStealable then return true end
    if whitelist.auras and data.duration > 0 then return true end
    if whitelist.boss and data.isBossAura then return true end

    return false
end

function isBlacklisted(blacklist, data)
    if not blacklist.enable then return false end
    if blacklist.yours and isCastByPlayer(data) then return true end
    if blacklist.others and not isCastByPlayer(data) then return true end
    if blacklist.stealable and data.isStealable then return true end
    if blacklist.auras and data.duration == 0 then return true end
    if blacklist.boss and data.isBossAura then return true end

    return false
end

function getHostility(unit)
    return UnitIsFriend('player', unit) and 'friend' or 'enemy'
end

function isCastByPlayer(data)
    return data.sourceUnit == 'player'
end

function isStealableBuff(data)
    return not data.isHarmful and data.isStealable
end

-- data = https://wowpedia.fandom.com/wiki/API_C_UnitAuras.GetAuraDataBySlot
function UF.FilterAura(element, unit, data)
	local filter = element.config[getHostility(unit)].filter

    if filter.time.enable then
        if filter.time.hideAuras and data.duration == 0 then return end
        if filter.time.max and data.duration > filter.time.max then return end
        if filter.time.min and data.duration < filter.time.min then return end
    end

    return isWhitelisted(filter.whitelist, data) and not isBlacklisted(filter.blacklist, data)
end

function UF.PostUpdateButton(element, button, unit, data, position)
    local config = element.config[getHostility(unit)]
    if config.colorStealable and isStealableBuff(data) then
        local c = DebuffTypeColor['Magic']
		button.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
    elseif config.colorTypes and data.dispelName then
        local c = DebuffTypeColor[data.dispelName]
		button.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
    else
		st:SetBackdrop(button, element.config.template)
	end

    button.Icon:SetDesaturated(config.desaturateOthers and not isCastByPlayer(data))
end

function UF.PostCreateButton(auras, button)

	st:SetBackdrop(button, auras.config.template)
	st:SkinIcon(button.Icon)
	button.Count:SetFontObject(st:GetFont(auras.config.font))

	button.Cooldown.noOCC = not auras.config.cooldown.timer
	button.Cooldown.noCooldownCount = not auras.config.cooldown.timer
	button.Cooldown:SetReverse(not auras.config.cooldown.reverse)
	button.Cooldown:SetAlpha(auras.config.cooldown.alpha)
	button.Cooldown:SetHideCountdownNumbers(true)
end

local function UpdateConfig(self, aura_type)
	local auras = self[aura_type]
	auras.config = self.config.auras[string.lower(aura_type)]
	auras.aura_type = aura_type

	if auras.config.enable then
        self:EnableElement(aura_type)
		auras:Show()
	else
        self:DisableElement(aura_type)
		auras:Hide()
		return
	end

	local num_rows = ceil(auras.config.max/auras.config.per_row)

	auras:SetHeight(num_rows*auras.config.size + (num_rows-1)*auras.config.spacing)
	auras:SetWidth(auras.config.per_row*auras.config.size + (auras.config.per_row-1)*auras.config.spacing)
	auras:ClearAllPoints()
	local point, _, relativePoint, xoffset, yoffset = st:UnpackPoint(auras.config.position)
	local frame = UF:GetFrame(self, auras.config.position)
	auras:SetPoint(point, frame, relativePoint, xoffset, yoffset)
	auras:SetFrameLevel(auras.config.framelevel)

	auras.size = auras.config.size
	auras.num = auras.config.max
	auras.numRow = auras.config.per_row
	auras.spacing = auras.config.spacing
	auras.initialAnchor = auras.config.initial_anchor
	auras['growth-y'] = auras.config.grow_up and 'UP' or 'DOWN'
	auras['growth-x'] = auras.config.grow_right and 'RIGHT' or 'LEFT'
	auras.onlyShowPlayer = auras.config.self_only
	auras.disableCooldown = not auras.config.cooldown.enable
	auras.showDispellable = auras.config.show_dispellable
	auras.FilterAura = UF.FilterAura
end

local function Constructor(self, aura_type)
	local auras = CreateFrame('Frame', self:GetName()..aura_type, self)
	auras.config = self.config.auras[string.lower(aura_type)]
	auras.PostCreateButton = UF.PostCreateButton
    auras.PostUpdateButton = UF.PostUpdateButton
	auras.disableCooldown = true
	self[aura_type] = auras
	return auras
end

UF:RegisterElement('Buffs', Constructor, UpdateConfig)
UF:RegisterElement('Debuffs', Constructor, UpdateConfig)

