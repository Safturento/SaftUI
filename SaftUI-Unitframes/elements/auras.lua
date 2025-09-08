local st = SaftUI
local UF = st:GetModule('Unitframes')

local function spellInFilter(list, data)
    if not list.spellIds then return false end

    return list.spellIds[data.spellId] or list.spellIds[data.name]
end

local function isWhitelisted(whitelist, data)
    if not whitelist.enable then return true end

    local spellWhitelisted = spellInFilter(whitelist, data)

    if spellWhitelisted and whitelist.yours and isCastByPlayer(data) then return true end
    if spellWhitelisted and whitelist.others and not isCastByPlayer(data) then return true end
    if spellWhitelisted and whitelist.stealable and data.isStealable then return true end
    if spellWhitelisted and whitelist.auras and data.duration > 0 then return true end
    if spellWhitelisted and whitelist.boss and data.isBossAura then return true end

    return false
end

local function isBlacklisted(blacklist, data)
    if not blacklist.enable then return false end

    local spellBlacklisted = spellInFilter(blacklist, data)

    if spellBlacklisted or blacklist.yours and isCastByPlayer(data) then return true end
    if spellBlacklisted or blacklist.others and not isCastByPlayer(data) then return true end
    if spellBlacklisted or blacklist.stealable and data.isStealable then return true end
    if spellBlacklisted or blacklist.auras and data.duration == 0 then return true end
    if spellBlacklisted or blacklist.boss and data.isBossAura then return true end

    return false
end

local function getHostility(unit)
    return UnitIsFriend('player', unit) and 'friend' or 'enemy'
end

function isCastByPlayer(data)
    return data.sourceUnit == 'player'
end

function isStealableBuff(data)
    return not data.isHarmful and data.isStealable
end

-- data = https://wowpedia.fandom.com/wiki/API_C_UnitAuras.GetAuraDataBySlot
function UF.FilterAura(auras, unit, data)
	local filter = auras.config[getHostility(unit)].filter

    if auras.onlyShowPlayer and not data.isFromPlayerOrPlayerPet then
		return false
	end

    if filter.time.enable then
        if filter.time.hideAuras and data.duration == 0 then return end
        if filter.time.max and data.duration > filter.time.max then return end
        if filter.time.min and data.duration < filter.time.min then return end
    end

    return isWhitelisted(filter.whitelist, data) and not isBlacklisted(filter.blacklist, data)
end

function UF.PostUpdateButton(auras, button, unit, data)
    local config = auras.config[getHostility(unit)]
    if config.colorStealable and data.isStealable then
        local c = DebuffTypeColor['Magic']
        button.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
    elseif config.colorTypes and data.dispelName then
        local c = DebuffTypeColor[data.dispelName]
        button.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
    else
        st:SetBackdrop(button, auras.config.template)
    end

    button.Icon:SetDesaturated(config.desaturateOthers and not (data and data.isPlayerAura))
end

function UF.PostCreateButton(auras, button)
	st:SetBackdrop(button, auras.config.template)
	st:SkinIcon(button.Icon)
	button.Count:SetFontObject(st:GetFont(auras.config.font))

    button.Stealable:SetTexture('')
    button.Overlay:SetTexture('')

	button.Cooldown.noOCC = not auras.config.cooldown.timer
	button.Cooldown.noCooldownCount = not auras.config.cooldown.timer
	button.Cooldown:SetReverse(not auras.config.cooldown.reverse)
	button.Cooldown:SetAlpha(auras.config.cooldown.alpha)
	button.Cooldown:SetDrawEdge(false)
	button.Cooldown:SetHideCountdownNumbers(not auras.config.cooldown.timer.enable)
	for _,region in pairs({button.Cooldown:GetRegions()}) do
        if region:GetObjectType() == 'FontString' then
            button.Cooldown.Duration = region
            button.Cooldown.Duration:SetFontObject(st:GetFont('pixel'))
            button.Cooldown.Duration:ClearAllPoints()
            local point, _, relPoint, x, y = st:UnpackPoint(auras.config.cooldown.timer.position)
            button.Cooldown.Duration:SetPoint(point, button, relPoint, x, y)
        end
    end
end

local function UpdateConfig(unitframe, aura_type)
    local auras = unitframe[aura_type]
    local enabled = UF:UpdateElement(auras)

	if enabled then
        unitframe:EnableElement(aura_type)
	else
        unitframe:DisableElement(aura_type)
	end

	local num_rows = ceil(auras.config.max/auras.config.per_row)

	auras:SetHeight(num_rows * auras.config.size + (num_rows - 1) * auras.config.spacing)
	auras:SetWidth(auras.config.per_row * auras.config.size + (auras.config.per_row - 1) * auras.config.spacing)
    st:SetBackdrop(auras, 'none')

    local size = auras.config.relative_size
                and unitframe.config.height + auras.config.size
                or auras.config.size
	auras.size = size
	auras.num = auras.config.max
	auras.numRow = auras.config.per_row
	auras.spacing = auras.config.spacing
	auras.initialAnchor = auras.config.initial_anchor
    auras.tooltipAnchor = 'ANCHOR_TOPLEFT'
    auras.reanchorIfVisibleChanged = true
	auras['growth-y'] = auras.config.grow_up and 'UP' or 'DOWN'
	auras['growth-x'] = auras.config.grow_right and 'RIGHT' or 'LEFT'
	auras.onlyShowPlayer = auras.config.onlyShowPlayer
    auras.showDebuffType = auras.config.showDebuffType
	auras.disableCooldown = not auras.config.cooldown.enable
	auras.FilterAura = UF.FilterAura
end

local function Constructor(unitframe, aura_type)
    local auras = UF:AddElement('Frame', unitframe, aura_type)

	auras.PostCreateButton = UF.PostCreateButton
    auras.PostUpdateButton = UF.PostUpdateButton
	auras.disableCooldown = true

	return auras
end

UF:RegisterElement('Buffs', Constructor, UpdateConfig)
UF:RegisterElement('Debuffs', Constructor, UpdateConfig)

