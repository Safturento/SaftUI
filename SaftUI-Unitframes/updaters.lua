local st = SaftUI
local UF = st:GetModule('Unitframes')

-- oUF's smoothing for a bar's Smooth setting: eased while on, immediate while
-- off (oUF's own default).
function UF:GetSmoothing(smooth)
	return smooth and Enum.StatusBarInterpolation.ExponentialEaseOut or Enum.StatusBarInterpolation.Immediate
end

-- A power bar's text as a whole percent. With secret values the game works the
-- percent out through Blizzard's 0-100 curve, and the FontString formats it
-- without Lua reading it.
function UF:SetPowerPercentText(text, unit, current, max, powerType)
	if issecretvalue(current) or issecretvalue(max) then
		text:SetFormattedText('%.0f', UnitPowerPercent(unit, powerType, false, CurveConstants.ScaleTo100))
	elseif max > 0 then
		text:SetFormattedText('%.0f', current / max * 100)
	else
		text:SetText('')
	end
end

function UF:UpdateElement(element, configOverride)
    element.config = element:GetConfig()

    local config = element.config or configOverride

    local enabled = self:SetElementEnabled(element, configOverride)
    if not enabled then
        -- An element's texts usually live on the unit frame's TextOverlay, not
        -- on the element, so they don't hide with it. Enabling it again shows
        -- them through UpdateText below, each by its own config.
        if element.textElements then
            for _, text in pairs(element.textElements) do
                text:Hide()
            end
        end
        return false
    end

    if element.config.template then
        st:SetBackdrop(element, config.template)
    end

    element:SetAlpha(config.alpha or 1)
    self:UpdateElementSize(element, configOverride)
    self:UpdateElementPosition(element, configOverride)
    self:UpdateElementLevel(element, configOverride)

    if element:IsObjectType('StatusBar') then
        self:UpdateStatusBarElement(element, configOverride)
    end

    if element:IsObjectType('FontString') then
        element:SetFontObject(st:GetFont(config.font))
    end

    if element.textElements then
        for key, text in pairs(element.textElements) do
            self:UpdateText(text, configOverride and configOverride[key] or nil)
        end
    end

    if element.icons then
        for _,icon in pairs(element.icons) do
            self:UpdateIcon(icon)
        end
    end

    return true
end

function UF:SetElementEnabled(element)
        element:SetShown(element.config.enable)

-- TODO: Figure out why EnableElement is breaking on nameplates

--     if hideOnly then
--         element:SetShown(element.config.enable)
--     else
--         local unitframe = element.__owner or element:GetParent()
--
--         if element.config.enable then
--             unitframe:EnableElement(element.name)
--         else
--             unitframe:DisableElement(element.name)
--         end
--     end

    return element.config.enable
end

function UF:UpdateElementSize(element, configOverride)
    if element.noSize then return end
    local config = configOverride or element.config

    local unitframe = element.unitframe or element:GetParent()

    if config.size then
        local size = config.relative_size
                        and unitframe.config.height + config.size
                        or config.size
        st:SetSize(element, size)
    end

    if config.height then
        if config.relative_height then
            st:SetHeight(element, unitframe.config.height + config.height)
        else
            st:SetHeight(element, config.height)
        end
    end

    if config.width then
        if config.relative_width then
            st:SetWidth(element, unitframe.config.width + config.width)
        else
            st:SetWidth(element, config.width)
        end
    end
end

function UF:UpdateElementPosition(element, unitframe, configOverride)
    local config = configOverride or element.config
    unitframe = element.unitframe or element:GetParent()

    local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(config.position)
    local frame = self:GetFrame(unitframe, config.position)
    element:ClearAllPoints()
    element:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
end

function UF:UpdateElementLevel(element, configOverride)
    local config = configOverride or element.config
    if config.framelevel and element.SetFrameLevel then
        element:SetFrameLevel(config.framelevel)
    end
end

function UF:UpdateStatusBarElement(element, configOverride)
    local config = configOverride or element.config

    if not element:IsObjectType('StatusBar') then
        return st:Error(element:GetName(), 'is not a status bar')
    end

    element:SetStatusBarTexture(st:GetStatusBarTexture(config.texture))
    element:SetReverseFill(config.reverse_fill or false)
	element:SetOrientation(config.vertical_fill and "VERTICAL" or "HORIZONTAL")

    if config.colorCustom then
		element:SetStatusBarColor(config.customColor:GetRGB())
	end

    if element.bg and config.bg then
        if config.bg.enable then
            element.bg:Show()
            element.bg:SetAlpha(config.bg.alpha)
            element.bg.multiplier = config.bg.multiplier
        else
            element.bg:Hide()
        end
    end
end

function UF:UpdateText(text, configOverride)
    local config = configOverride or text:GetConfig()
    if not text:IsObjectType('FontString') then
        return st:Error(text:GetName(), 'is not a text object')
    end

    UF:UpdateElement(text, configOverride)
    text:SetFontObject(st:GetFont(config.font))
end

function UF:UpdateIcon(icon)
    UF:UpdateElement(icon)
    st:SkinIcon(icon.texture)
end