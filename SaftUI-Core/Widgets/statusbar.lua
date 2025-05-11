local st = SaftUI

function st:CreateStatusBar(name, parent, text, template)
	local statusbar = self:CreateFrame('StatusBar', name and 'SaftUI_'..name or nil, parent)
	statusbar.text = self:CreateFontString(statusbar, 'pixel', text)
	statusbar.text:SetAllPoints()

	statusbar.SetFont = function(font) statusbar.text:SetFontObject(st:GetFont(font)) end
	statusbar.SetText = statusbar.text.SetText

    statusbar:SetStatusBarTexture(st.BLANK_TEX)
    self:SkinStatusBar(statusbar, template, font)

	return statusbar
end

function st:SkinStatusBar(statusbar, template, font)
	assert(statusbar)
	st:SetBackdrop(statusbar, template or 'thick')

    statusbar.text:SetFontObject(st:GetFont(font or 'pixel'))
	statusbar:SetStatusBarTexture(st.BLANK_TEX)
end