local st = SaftUI

function st:CreateButton(name, parent, text, theme, background)
	local button = self:CreateFrame('Button', name and 'SaftUI_'..name or nil, parent)
	button.text = self:CreateFontString(button, 'pixel', text)
	button.text:SetAllPoints()

	button.SetFont = function(font) button.text:SetFontObject(st:GetFont(font)) end
	button.SetText = button.text.SetText

    self:SkinButton(button, theme, background)

	return button
end

-- Draws button's backdrop in theme and background (Use SaftUI's theme and
-- Solid by default), and gives it font and SaftUI's hover, pushed and disabled
-- looks. A caller not yet moved to themes passes an old template name as
-- theme with no background, and the button draws as before.
function st:SkinButton(button, theme, background, font)
	assert(button)
	if background then
		st:SetBackdrop(button, theme, background, 'small')
	elseif theme then
		st:SetBackdrop(button, theme)
	else
		st:SetBackdrop(button, 'theme', 'solid', 'small')
	end

    local fontObject = st:GetFont(font or 'pixel')
	if button.SetNormalFontObject then
		button:SetNormalFontObject(fontObject)
		button:SetHighlightFontObject(fontObject)
		button:SetDisabledFontObject(fontObject)
		button:SetPushedTextOffset(0, 0)
	else
		for _,region in pairs({ button:GetRegions() }) do
			if region:GetObjectType() == 'FontString' then
				region:SetFontObject(fontObject)
			end
		end
	end

    for _,region in pairs({ button:GetRegions() }) do
		if region:GetObjectType() == 'Texture' then
			region:SetAlpha(0)
        end
    end

    if button.SetNormalTexture then
		button:SetNormalTexture('')
	end

	if button.SetHighlightTexture and not button.hover then
		local hover = button:CreateTexture(nil, 'OVERLAY')
        hover:SetTexture(self.BLANK_TEX)
        hover:SetVertexColor(self.config.profile.colors.button.normal:GetRGB())
        hover:SetAllPoints(button)

        button:SetHighlightTexture(hover)
        button.hover = hover
	end

	if button.SetPushedTexture and not button.pushed then
		local pushed = button:CreateTexture(nil, 'OVERLAY')
        pushed:SetTexture(self.BLANK_TEX)
        pushed:SetVertexColor(self.config.profile.colors.button.pushed:GetRGB())
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