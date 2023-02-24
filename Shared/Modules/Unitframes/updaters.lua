local st = SaftUI
local UF = st:GetModule('Unitframes')

function UF:UpdateElementConfig(element, hideOnly)

    local enabled = self:SetElementEnabled(element, hideOnly)
    if not enabled then return end

    st:SetBackdrop(element, element.config.template)
    self:UpdateElementSize(element)
    self:UpdateElementPosition(element)

    if element:IsObjectType('StatusBar') then
        self:UpdateStatusBarElement(element)
    end

    for _,textElement in pairs(element.textElements) do
        self:UpdateTextElement(textElement)
    end
end

function UF:SetElementEnabled(element, hideOnly)
    if hideOnly then
        element:SetShown(element.config.enable)
    else
        local unitframe = element:GetParent()

        if element.config.enable then
            unitframe:EnableElement(element.name)
        else
            unitframe:DisableElement(element.name)
        end
    end

    return element.config.enable
end

function UF:UpdateElementSize(element)
    local unitframe = element:GetParent()

    if element.config.relative_height then
		st:SetHeight(element, unitframe.config.height + element.config.height)
	else
		st:SetHeight(element, element.config.height)
	end

	if element.config.relative_width then
		st:SetWidth(element, unitframe.config.width + element.config.width)
	else
		st:SetWidth(element, element.config.width)
	end
end

function UF:UpdateElementPosition(element)
    local unitframe = element:GetParent()

    local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(element.config.position)
    local frame = self:GetFrame(unitframe, element.config.position)
    element:ClearAllPoints()
    element:SetPoint(anchor, frame, rel_anchor, x_off, y_off)

    element:SetFrameLevel(element.config.framelevel)
end

function UF:UpdateStatusBarElement(element)
    if not element:IsObjectType('StatusBar') then
        return st:Error(element:GetName(), 'is not a status bar')
    end

    element:SetStatusBarTexture(st:GetStatusBarTexture(element.config.texture))
    element:SetReverseFill(element.config.reverse_fill)
	element:SetOrientation(element.config.vertical_fill and "VERTICAL" or "HORIZONTAL")

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

function UF:UpdateTextElement(textElement)
    if not textElement:IsObjectType('FontString') then
        return st:Error(textElement:GetName(), 'is not a text object')
    end

    if textElement.config.enable then
        textElement:Show()
		textElement:SetFontObject(st:GetFont(textElement.config.font))

		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(textElement.config.position)
		local frame = self:GetFrame(textElement.element, textElement.config.position)
		textElement:ClearAllPoints()
		textElement:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
    else
        textElement:Hide()
    end
end

