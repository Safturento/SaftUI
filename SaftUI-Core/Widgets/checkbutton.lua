local st = SaftUI

--[[
	st:CreateCheckButton(name, parent, style) makes a check button from
	UICheckButtonTemplate and skins it, st:SkinCheckButton(button, style), in
	one of three styles. Its states are the helpers' (Widgets/states.lua):
	  - nil, a check box: SaftUI's 12px box (panels' Theme and Background,
	    drawn as a control), a 'check' whose checked texture is its Mark (an
	    Accent square, floor(12 / 6) = 2 in) and whose border and fade show
	    while it's checked; or under the Blizzard theme the Settings panel's
	    box (st.ThemeArt.Control('checkbox'), ruling 3), drawn 1px outside the
	    button so the art's box is the 12px;
	  - 'button', a check button used as a button (the bags' Edit toggle, the
	    currencies' funnel): a 'box' selected while checked (the border and the
	    fade, no mark), or under Blizzard Blizzard's panel button
	    (st:ShowPanelButton), pressed while checked;
	  - 'bare', no box: no backdrop, and in every theme a 'box' with no edge
	    (the hover's Layer only); its checked texture is its caller's, which no
	    pass repaints (a currency's hidden overlay, the combined bank's eye).
	The look follows a theme switch (st:KeepOwnColors). Blizzard's art is on
	SaftUI's own check button: its check and highlight textures, and a box
	texture of its own kept here.
]]

-- check button -> { button, style, theme, background, checked, hover, box,
-- blizzard }: its checked texture (the Mark of a check box) and highlight
-- texture (a check box's, which draws Blizzard's art under Blizzard and
-- nothing else), the Settings box's texture once made, and the look it wears
-- now.
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

-- Puts a check button's look on, when its Theme and Background
-- (st:IsBlizzardLook) changed between Blizzard and the rest, then its states
-- drawn again (st:RestyleStates, last: the Mark is placed or left to the art,
-- and the mouse hooked again where a module's own SetScript dropped them).
-- Runs after every recolor and redraw (st:KeepOwnColors).
local function Draw(skin)
	local button = skin.button
	local blizzard = st:IsBlizzardLook(skin.theme, skin.background)
	if blizzard ~= skin.blizzard then
		skin.blizzard = blizzard

		if skin.style == 'button' then
			st:ShowPanelButton(button, blizzard, Checked)
		elseif blizzard then
			local look = st.ThemeArt.Control('checkbox')
			skin.box = skin.box or button:CreateTexture(nil, 'ARTWORK')
			skin.box:SetAtlas(look.normal)
			Outside(skin.box, button)
			skin.box:Show()
			skin.checked:SetAtlas(look.checked)
			skin.checked:SetVertexColor(1, 1, 1, 1)
			Outside(skin.checked, button)
			skin.hover:SetAlpha(1)
			skin.hover:SetAtlas(look.highlight)
			skin.hover:SetVertexColor(1, 1, 1, 1)
			skin.hover:SetBlendMode(look.highlightBlend)
			Outside(skin.hover, button)
		else
			if skin.box then skin.box:Hide() end
			-- the Mark again: flat, the helper places and colors it
			skin.checked:SetTexture(st.BLANK_TEX)
			skin.checked:SetTexCoord(0, 1, 0, 1)
			skin.checked:SetVertexColor(1, 1, 1, 1)
			-- the highlight is Blizzard's art alone: the Layer is SaftUI's hover
			skin.hover:SetAlpha(0)
		end
	end
	st:RestyleStates(button)
end

-- The panel button's pressed look follows the check: set by code, or by a
-- click (which the game checks in its own code, before OnClick; callers set
-- their own OnClick, so it's heard after, in PostClick). Selected follows it
-- too, whatever the look.
local function Repaint(button)
	local skin = skins[button]
	if not skin then return end
	if skin.blizzard and skin.style == 'button' then st:ShowPanelButton(button, true, Checked) end
	st:SetState(button, 'selected', button:GetChecked() and true or false)
end

-- The profile's panels font (`panels.font`: it has no row on the Fonts tab, since no
-- check box label is visible), read when a label is drawn or follows.
local function PanelsFont() return st.config.profile.panels.font end

function st:SkinCheckButton(button, style)
	self:StripTextures(button)

	button:SetSize(12, 12)
	local panels = st.config.profile.panels
	if style ~= 'bare' then
		st:SetBackdrop(button, panels.theme, panels.background, 'control')
	end

	button:SetFrameLevel(button:GetFrameLevel()+1)

	local name = button:GetName()
	local text = button.Text or button.Label or name and _G[name..'Text']
	if text then
		-- The panels font (no Fonts tab row): the label follows the font setting,
		-- until a caller gives it a font of its own with SetTextFont.
		st:FollowFont(text, PanelsFont)
		text:SetDrawLayer('OVERLAY', 7)
		button.text = text
		button.SetTextFont = function(self, value)
			st:FollowFont(text, nil)
			st:ApplyFont(text, value)
		end
		button.SetText = function(self, value) text:SetText(value) end
	end

	if style == 'bare' then
		-- A checked texture for its caller to restyle (the bags' currency veil and
		-- bank eye): flat, nothing of SaftUI's follows it.
		local checked = button:CreateTexture(nil, 'OVERLAY')
		checked:SetTexture(self.BLANK_TEX)
		checked:SetAllPoints(button)
		button:SetCheckedTexture(checked)
		-- A hover Layer only, in every theme.
		local skin = { button = button, style = style, theme = 'none', background = 'solid', blizzard = false }
		skins[button] = skin
		st:AddStates(button, 'box', { edge = false, blizzard = function() return false end })
		st:KeepOwnColors(skin, Draw)
		return
	end

	-- The checked texture: a check box's Mark; a 'button' style box shows its
	-- checked state as the box's own (Edge and Fill), so none is drawn.
	local checked, hover
	if style == 'button' then
		button:SetCheckedTexture('')
	else
		checked = button:CreateTexture(nil, 'OVERLAY')
		checked:SetTexture(self.BLANK_TEX)
		checked:SetAllPoints(button)
		button:SetCheckedTexture(checked)
		-- A highlight for Blizzard's art alone (it shows under Blizzard, held at
		-- alpha 0 otherwise): under SaftUI's look the hover is the Layer.
		hover = button:CreateTexture(nil, 'OVERLAY')
		hover:SetTexture(self.BLANK_TEX)
		hover:SetAllPoints(button)
		hover:SetAlpha(0)
		button:SetHighlightTexture(hover, 'BLEND') -- handed no blend mode, a highlight is additive
	end

	-- It wears SaftUI's flat look, just made.
	local skin = {
		button = button, style = style, theme = panels.theme, background = panels.background,
		checked = checked, hover = hover, blizzard = false,
	}
	skins[button] = skin
	st:AddStates(button, style == 'button' and 'box' or 'check', {
		edge = 'theme',
		mark = checked,
		blizzard = function() return st:IsBlizzardLook(skin.theme, skin.background) end,
	})
	hooksecurefunc(button, 'SetChecked', Repaint)
	button:HookScript('PostClick', Repaint)
	st:KeepOwnColors(skin, Draw)
	skin.blizzard = nil
	Draw(skin)
	if button:GetChecked() then st:SetState(button, 'selected', true) end
end

function st:CreateCheckButton(name, parent, style)
	local button = self:CreateFrame('CheckButton', name, parent,  'UICheckButtonTemplate')

	st:SkinCheckButton(button, style)

	return button
end
