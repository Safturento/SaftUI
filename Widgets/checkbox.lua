local st = select(2, ...)
local Widgets = st.Widgets

local boxSize = 20

function Widgets:CheckBox(name, parent, label)
    local checkBox = CreateFrame("CheckButton", name, parent or UIParent)
    st:SetSize(checkBox, boxSize, boxSize)
    checkBox.Label = checkBox:CreateFontString(nil, 'OVERLAY')
    st:SkinCheckButton(checkBox)
    checkBox.SetLabel = function(self, text) self.Label:SetText(text) end
    checkBox:SetLabel(label)
    checkBox.Label:SetPoint('LEFT', checkBox, 'RIGHT', 10, 0)
    return checkBox
end
