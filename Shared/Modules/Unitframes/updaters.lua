local st = SaftUI
local UF = st:GetModule('Unitframes')

function UF:UpdateElement(element)

    local enabled = self:SetElementEnabled(element, hideOnly)
    if not enabled then return false end

    st:SetBackdrop(element, element.config.template)
    element:SetAlpha(element.config.alpha or 1)
    self:UpdateElementSize(element)
    self:UpdateElementPosition(element)
    self:UpdateElementLevel(element)


    if element:IsObjectType('StatusBar') then
        self:UpdateStatusBarElement(element)
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
    unitframe = element.unitframe or element:GetParent()

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
    if not element.config.framelevel then return end
    if element.SetFrameLevel then
        element:SetFrameLevel(element.config.framelevel)
    elseif element.SetDrawLayer then
        element:SetDrawlayer(element.config.framelevel)
    end
end

function UF:UpdateStatusBarElement(element)
    if not element:IsObjectType('StatusBar') then
        return st:Error(element:GetName(), 'is not a status bar')
    end

    element:SetStatusBarTexture(st:GetStatusBarTexture(element.config.texture))
    element:SetReverseFill(element.config.reverse_fill or false)
	element:SetOrientation(element.config.vertical_fill and "VERTICAL" or "HORIZONTAL")

    if element.config.colorCustom then
		element:SetStatusBarColor(unpack(element.config.customColor))
	end

    if element.bg and element.config.bg then
        if element.config.bg.enable then
            element.bg:Show()
            element.bg:SetAlpha(element.config.bg.alpha)
            element.bg.multiplier = element.config.bg.multiplier
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