local st = SaftUI

--[[
	st:CreateCheckButton(name, parent, style) makes a check button from
	UICheckButtonTemplate and skins it, st:SkinCheckButton(button, style), in
	one of three styles:
	  - nil, a check box: SaftUI's 12px box (panels' Theme and Background,
	    drawn as a control) with a flat check, or under the Blizzard theme the
	    Settings panel's box (st.ThemeArt.Control('checkbox'), ruling 3), drawn
	    1px outside the button so the art's box is the 12px;
	  - 'button', a check button used as a button (the bags' Edit toggle, the
	    currencies' funnel): SaftUI's box, or under Blizzard Blizzard's panel
	    button (st:ShowPanelButton), pressed while checked;
	  - 'bare', no box: no backdrop, and SaftUI's flat check and highlight in
	    every theme, which its caller restyles (a currency's hidden overlay,
	    the combined bank's eye).
	The look follows a theme switch (st:KeepOwnColors). Blizzard's art is on
	SaftUI's own check button: its check and highlight textures, and a box
	texture of its own kept here.
]]

-- check button -> { button, style, theme, background, checked, hover,
-- hoverBlend, box, blizzard }: its flat check and highlight textures (and the
-- highlight's blend as made), the Settings box's texture once made, and the
-- look it wears now.
local skins = setmetatable({}, { __mode = 'k' })

-- How far outside the button a check box's art is drawn: the art's box is 26
-- of its 30 with 2 clear all round, so 1px out shows it at SaftUI's 12px.
local BOX_OUT = 1

local function Checked(button)
	return button:GetChecked()
end

local function Outside(texture, button)
	texture:ClearAllPoints()
	texture:SetPoint('TOPLEFT', button, 'TOPLEFT', -BOX_OUT, BOX_OUT)
	texture:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', BOX_OUT, -BOX_OUT)
end

-- SaftUI's flat look on one of the textures: blank, filling the button, in color.
local function Flat(texture, button, color, blend)
	texture:SetTexture(st.BLANK_TEX)
	texture:SetTexCoord(0, 1, 0, 1)
	texture:ClearAllPoints()
	texture:SetAllPoints(button)
	texture:SetVertexColor(color:GetRGB())
	if blend then texture:SetBlendMode(blend) end
end

-- Puts a check button's look on, when its Theme and Background
-- (st:IsBlizzardLook) changed between Blizzard and the rest.
local function Draw(skin)
	local button = skin.button
	local blizzard = st:IsBlizzardLook(skin.theme, skin.background)
	if blizzard == skin.blizzard then return end
	skin.blizzard = blizzard

	if skin.style == 'button' then
		skin.checked:SetAlpha(blizzard and 0 or 1)
		skin.hover:SetAlpha(blizzard and 0 or 1)
		st:ShowPanelButton(button, blizzard, Checked)
		return
	end

	if blizzard then
		local look = st.ThemeArt.Control('checkbox')
		skin.box = skin.box or button:CreateTexture(nil, 'ARTWORK')
		skin.box:SetAtlas(look.normal)
		Outside(skin.box, button)
		skin.box:Show()
		skin.checked:SetAtlas(look.checked)
		skin.checked:SetVertexColor(1, 1, 1, 1)
		Outside(skin.checked, button)
		skin.hover:SetAtlas(look.highlight)
		skin.hover:SetVertexColor(1, 1, 1, 1)
		skin.hover:SetBlendMode(look.highlightBlend)
		Outside(skin.hover, button)
	else
		local colors = st.config.profile.colors.button
		if skin.box then skin.box:Hide() end
		Flat(skin.checked, button, colors.hover)
		Flat(skin.hover, button, colors.normal, skin.hoverBlend)
	end
end

-- The panel button's pressed look follows the check: set by code, or by a
-- click (which the game checks in its own code, before OnClick; callers set
-- their own OnClick, so it's heard after, in PostClick).
local function Repaint(button)
	local skin = skins[button]
	if skin and skin.blizzard then st:ShowPanelButton(button, true, Checked) end
end

function st:SkinCheckButton(button, style)
	self:StripTextures(button)

	button:SetSize(12, 12)
	local panels = st.config.profile.panels
	if style ~= 'bare' then
		st:SetBackdrop(button, panels.theme, panels.background, 'control')
	end

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

	if style == 'bare' then return end
	-- It wears SaftUI's flat look, just made.
	local skin = {
		button = button, style = style, theme = panels.theme, background = panels.background,
		checked = checked, hover = hover, hoverBlend = hover:GetBlendMode(), blizzard = false,
	}
	skins[button] = skin
	if style == 'button' then
		hooksecurefunc(button, 'SetChecked', Repaint)
		button:HookScript('PostClick', Repaint)
	end
	st:KeepOwnColors(skin, Draw)
	Draw(skin)
end

function st:CreateCheckButton(name, parent, style)
	local button = self:CreateFrame('CheckButton', name, parent,  'UICheckButtonTemplate')

	st:SkinCheckButton(button, style)

	return button
end
