local st = SaftUI

function st:CreateButton(name, parent, text, template)
	local button = self:CreateFrame('Button', name and 'SaftUI_'..name or nil, parent)
	button.text = self:CreateFontString(button, 'pixel', text)
	button.text:SetAllPoints()

	button.SetFont = function(font) button.text:SetFontObject(st:GetFont(font)) end
	button.SetText = button.text.SetText

    self:SkinButton(button, template)

	return button
end

function st:SkinButton(button, template, font)
	st:SetBackdrop(button, template or 'thick')

    local fontObject = st:GetFont(font or 'pixel')
    for _,region in pairs({ button:GetRegions() }) do
        if region:GetObjectType() == 'FontString' then
            region:SetFontObject(fontObject)
        end
    end

    if button.SetNormalTexture then
		button:SetNormalTexture('')
	end

	if button.SetHighlightTexture and not button.hover then
		local hover = button:CreateTexture(nil, 'OVERLAY')
        hover:SetTexture(self.BLANK_TEX)
        hover:SetVertexColor(unpack(self.config.profile.colors.button.normal))
        hover:SetAllPoints(button)

        button:SetHighlightTexture(hover)
        button.hover = hover
	end

	if button.SetPushedTexture and not button.pushed then
		local pushed = button:CreateTexture(nil, 'OVERLAY')
        pushed:SetTexture(self.BLANK_TEX)
        pushed:SetVertexColor(unpack(self.config.profile.colors.button.pushed))
        pushed:SetAllPoints(button)

        button:SetPushedTexture(pushed)
		button.pushed = pushed
	end

	if button.SetDisabledTexture and not button.disabled then
		local disabled = button:CreateTexture(nil, 'OVERLAY')
		disabled:SetTexture(st.BLANK_TEX)
		disabled:SetVertexColor(0, 0, 0, .4)
		disabled:SetAllPoints(button)

		button:SetDisabledTexture(disabled)
        button.disabled = disabled
	end
end