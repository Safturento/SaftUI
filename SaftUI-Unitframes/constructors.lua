local st = SaftUI
local UF = st:GetModule('Unitframes')

function UF:AddElement(frameType, unitframe, elementName)
    local element = CreateFrame(frameType, ('%s_%s'):format(unitframe:GetName(), elementName), unitframe)
    element.config = unitframe.config[string.lower(elementName)]
    element.GetConfig = function(self) return unitframe:GetConfig()[string.lower(elementName)] end
    element.name = elementName
    element.unitframe = unitframe
    unitframe[elementName] = element

    return element
end

function UF:AddStatusBarElement(unitframe, elementName)
    local statusbar = self:AddElement('StatusBar', unitframe, elementName)
    statusbar:SetStatusBarTexture(st.BLANK_TEX)

	statusbar.bg = statusbar:CreateTexture(nil, 'BACKGROUND')
	statusbar.bg:SetAllPoints(statusbar)
	statusbar.bg:SetTexture(st.BLANK_TEX)

	statusbar.Smooth = true

	return statusbar
end

function UF:AddTextElement(unitframe, elementName)
    local text = unitframe.TextOverlay:CreateFontString(nil, 'OVERLAY')
    text.config = unitframe.config[string.lower(elementName)]
    text.GetConfig = function(self) return unitframe:GetConfig()[string.lower(elementName)] end
    text.name = elementName
	text.unitframe = unitframe
    text.noSize = true
	unitframe[elementName] = text

    return text
end

function UF:AddText(unitframe, element, key, parent)
    if not unitframe.TextOverlay then st:Error('Cannot create text before TextOverlay is created') return end
    key = key or 'text'

    local text = (parent or unitframe.TextOverlay):CreateFontString(('%s_%s'):format(element:GetName(), key), 'OVERLAY')
    text.config = element.config[string.lower(key)]
    text.GetConfig = function() return element:GetConfig()[string.lower(key)] end
    text.element = element
    text.unitframe = unitframe

    text:SetFontObject(GameFontNormal)

    -- Allow for easy bi-directional access for all text elements
    if not element.textElements then element.textElements = {} end
    tinsert(element.textElements, text)

    element[key] = text

    return text
end

function UF:AddIcon(unitframe, element, key)
    key = key or 'icon'

    local icon = CreateFrame('frame', ('%s_%s'):format(element:GetName(), key), element)
    icon.config = element.config[string.lower(key)]
    icon.GetConfig = function() return element:GetConfig()[string.lower(key)] end
    icon.element = element
    icon.unitframe = unitframe

	icon.texture = icon:CreateTexture(('%s_%s'):format(icon:GetName(), 'Texture'), 'OVERLAY')
	icon.SetTexture = function(self, tex) self.texture:SetTexture(tex) end
	icon.texture:SetAllPoints(icon)

    if not element.icons then element.icons = {} end
    tinsert(element.icons, icon)

    element[key] = icon
    return icon
end