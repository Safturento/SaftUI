local st = select(2, ...)
local Widgets = st.Widgets

function Widgets:EditBox(name, parent, lines)
	local editbox = CreateFrame('EditBox', name, parent, 'InputBoxTemplate')
	editbox:ClearFocus()
	editbox:SetAutoFocus(false)
	editbox:SetScript('OnEscapePressed', function(self) self:ClearFocus() end)
	editbox:SetScript('OnEnterPressed', function(self) self:ClearFocus() end)

	editbox:SetSize(200, 20)
	editbox.Label = editbox:CreateFontString(nil, 'OVERLAY')
	editbox.Label:SetPoint('BOTTOMLEFT', editbox, 'TOPLEFT', 3, 5)
	editbox.Label:SetFontObject(st:GetFont('normal'))
	editbox.SetLabel = function(self, text) self.Label:SetText(text) end

	if lines then
		editbox:SetMultiLine(true)
	end
	st:SkinEditBox(editbox)

	return editbox
end