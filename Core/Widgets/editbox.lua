local st = SaftUI

function st:CreateEditBox(name, parent, lines)
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


function st:SkinEditBox(editbox, template, font)
	local name = editbox:GetName()
	template = template or 'thick'

	for _,region_name in pairs({'Left', 'Right', 'Middle', 'Mid', 'focusLeft', 'focusRight', 'focusMid'}) do
		local region = _G[name..region_name] or editbox[region_name]
		if region then
			st:Kill(region)
		end
	end


	if editbox.searchIcon then
		editbox.searchIcon:ClearAllPoints()
		editbox.searchIcon:SetPoint('LEFT', editbox, 5, -1)
	end

	if editbox.Instructions then
		editbox.Instructions:ClearAllPoints()
		editbox.Instructions:SetPoint('LEFT', editbox, 'LEFT', editbox.searchIcon and 20 or 5, 0)
		if font then
			editbox.Instructions:SetFontObject(st:GetFont(font))
		end
	end

	st:SetBackdrop(editbox, template)

	local text, _, _, _, header = editbox:GetRegions()
	if font then
		text:SetFontObject(st:GetFont(font or 'normal'))
		-- if header then
		-- 	header:SetFontObject(st:GetFont(font))
		-- end
	end

	editbox:HookScript('OnEditFocusGained', function(self)
		self.backdrop:SetBackdropBorderColor(1, 1, 1, 1)
	end)

	editbox:HookScript('OnEditFocusLost', function(self)
		st:SetBackdrop(self, template)
	end)
end