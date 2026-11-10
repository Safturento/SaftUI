local st = SaftUI

function st:SkinCheckButton(button)
	self:StripTextures(button)

	button:SetSize(12, 12)
	local panels = st.config.profile.panels
	st:SetBackdrop(button, panels.theme, panels.background, 'small')

	button:SetFrameLevel(button:GetFrameLevel()+1)

	local checked = button:CreateTexture(nil, 'OVERLAY')
	checked:SetTexture(self.BLANK_TEX)
	checked:SetVertexColor(self.config.profile.colors.button.hover:GetRGB())
	checked:SetAllPoints(button)
	button:SetCheckedTexture(checked)

	local hover = button:CreateTexture(nil, 'OVERLAY')
	hover:SetTexture(self.BLANK_TEX)
	hover:SetVertexColor(self.config.profile.colors.button.normal:GetRGB())
	hover:SetAllPoints(button)
	button:SetHighlightTexture(hover)

	local name = button:GetName()
	local text = button.Text or button.Label or name and _G[name..'Text']
	if text then
		text:SetFontObject(self:GetFont(self.config.profile.panels.font))
		text:SetDrawLayer('OVERLAY', 7)
		button.text = text
		button.SetFont = function(self, font) text:SetFontObject(st:GetFont(font)) end
		button.SetText = function(self, value) text:SetText(value) end
	end
end

function st:CreateCheckButton(name, parent)
	local button = self:CreateFrame('CheckButton', name, parent,  'UICheckButtonTemplate')

	st:SkinCheckButton(button)

	return button
end