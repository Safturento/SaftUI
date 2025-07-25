local st = SaftUI
local UF = st:GetModule('Unitframes')

function UF:UpdateElement(element)
    element.config = element:GetConfig()
    local enabled = self:SetElementEnabled(element)
    if not enabled then return false end

    if element.config.template then
        st:SetBackdrop(element, element.config.template)
    end

    element:SetAlpha(element.config.alpha or 1)
    self:UpdateElementSize(element)
    self:UpdateElementPosition(element)
    self:UpdateElementLevel(element)

    if element:IsObjectType('StatusBar') then
        self:UpdateStatusBarElement(element)
    end

    if element:IsObjectType('FontString') then
        element:SetFontObject(st:GetFont(element.config.font))
    end

    if element.textElements then
        for _,text in pairs(element.textElements) do
            self:UpdateText(text)
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

function UF:UpdateElementSize(element)
    if element.noSize then return end

    local unitframe = element.unitframe or element:GetParent()

    if element.config.size then
        local size = element.config.relative_size
                        and unitframe.config.height + element.config.size
                        or element.config.size
        st:SetSize(element, size)
    end

    if element.config.height then
        if element.config.relative_height then
            st:SetHeight(element, unitframe.config.height + element.config.height)
        else
            st:SetHeight(element, element.config.height)
        end
    end

    if element.config.width then
        if element.config.relative_width then
            st:SetWidth(element, unitframe.config.width + element.config.width)
        else
            st:SetWidth(element, element.config.width)
        end
    end
end

function UF:UpdateElementPosition(element, unitframe)
    unitframe = element.unitframe or element:GetParent()

    local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(element.config.position)
    local frame = self:GetFrame(unitframe, element.config.position)
    element:ClearAllPoints()
    element:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
end

function UF:UpdateElementLevel(element)
    if element.config.framelevel and element.SetFrameLevel then
        element:SetFrameLevel(element.config.framelevel)
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
		element:SetStatusBarColor(unpack(config.customColor))
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

function UF:UpdateText(text)
    if not text:IsObjectType('FontString') then
        return st:Error(text:GetName(), 'is not a text object')
    end

    UF:UpdateElement(text)
    text:SetFontObject(st:GetFont(text.config.font))
end

function UF:UpdateIcon(icon)
    UF:UpdateElement(icon)
    st:SkinIcon(icon.texture)
end