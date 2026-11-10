local st = SaftUI

function st:CreateStatusBar(name, parent, text, theme, background)
	local statusbar = self:CreateFrame('StatusBar', name and 'SaftUI_'..name or nil, parent)
	statusbar.text = self:CreateFontString(statusbar, 'pixel', text)
	statusbar.text:SetAllPoints()

	statusbar.SetFont = function(font) statusbar.text:SetFontObject(st:GetFont(font)) end
	statusbar.SetText = statusbar.text.SetText

    statusbar:SetStatusBarTexture(st.BLANK_TEX)
    self:SkinStatusBar(statusbar, theme, background, font)

	return statusbar
end

-- Draws statusbar's backdrop in theme and background (Use SaftUI's theme and
-- Solid by default), as st:SkinButton does a button's, and gives it font and a
-- flat texture.
function st:SkinStatusBar(statusbar, theme, background, font)
	assert(statusbar)
	st:SetBackdrop(statusbar, theme or 'theme', background or 'solid', 'bar')

    statusbar.text:SetFontObject(st:GetFont(font or 'pixel'))
	statusbar:SetStatusBarTexture(st.BLANK_TEX)
end