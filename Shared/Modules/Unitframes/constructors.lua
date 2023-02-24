local st = SaftUI
local UF = st:GetModule('Unitframes')

function UF:AddStatusBarElement(unitframe, elementName)
    local statusbar = CreateFrame('StatusBar', ('%s_%s'):format(unitframe:GetName(), elementName), unitframe)
	statusbar.config = unitframe.config[string.lower(elementName)]

	statusbar.bg = statusbar:CreateTexture(nil, 'BACKGROUND')
	statusbar.bg:SetAllPoints(statusbar)
	statusbar.bg:SetTexture(st.BLANK_TEX)

	statusbar.Smooth = true

    unitframe[elementName] = statusbar
	return statusbar
end

function UF:AddText(unitframe, element, textKey)
    if not unitframe.TextOverlay then st:Error('Cannot create text before TextOverlay is created') return end
    textKey = textKey or 'text'

    local text = unitframe.TextOverlay:CreateFontString(('%s_%s'):format(unitframe:GetName(), textKey), 'OVERLAY')
    text:SetFontObject(GameFontNormal)
    text:SetPoint('CENTER', element, 'CENTER')

    text.config = element.config[string.lower(textKey)]

    -- Allow for easy bi-directional access for all text elements
    text.element = element
    if not element.textElements then element.textElements = {} end
    tinsert(element.textElements, text)

    element[textKey or 'text'] = text
return text
end