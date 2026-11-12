local st = SaftUI

function st:CreateEditBox(name, parent, lines)
    local editbox = CreateFrame('EditBox', name, parent, 'InputBoxTemplate')
    editbox:ClearFocus()
    editbox:SetAutoFocus(false)
    editbox:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
    editbox:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)

    editbox:SetSize(200, 20)

    if lines then
        editbox:SetMultiLine(true)
    end
    st:SkinEditBox(editbox)

    return editbox
end