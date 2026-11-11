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

--[[
	Blizzard's art on SaftUI's buttons, under the Blizzard theme:
	  - st:ShowPanelButton(button, shown, pressed) draws Blizzard's panel button
	    (UIPanelButtonNoTooltipTemplate, st.ThemeArt.Control('button')) on a
	    button of SaftUI's: Left, Middle and Right from UI-Panel-Button-Up,
	    -Down on a mouse down (and while pressed says so), -Disabled while
	    disabled, the ends 12/22 of its height, and the additive highlight
	    under the mouse;
	  - st:SkinButton draws it on the buttons it skins, or Blizzard's top tabs
	    on a radio group's (st:SetButtonTab); a button of Blizzard's panel
	    button template shows its own Left, Middle and Right again instead.
	Every piece is a texture of SaftUI's on a button of SaftUI's, inside the
	button's own rect, kept in this file's tables, never in a field
	(.agents/taint.md). It's made the first time the button shows it, so a
	button never drawn under Blizzard has none.
]]

-- button -> its art: { Left, Middle, Right, Highlight, mode, look, picked,
-- pressed, down }. mode is 'button' (the panel button), 'tab', or nil while
-- hidden; look is st.ThemeArt.Control(mode), read when the mode changes.
local arts = setmetatable({}, { __mode = 'k' })

local PIECES = { 'Left', 'Middle', 'Right' }

-- A tab's art as Blizzard's top tabs draw it (PanelTopTabButtonMixin): upside
-- down, the art's last quarter, which would lie over the window, cut off.
local TAB_COORDS, TAB_SHARE = { 0, 1, 1, 0.25 }, 0.75

-- How wide an end piece is on a button width by height: the panel's endShare
-- of its height (Blizzard's 12 on 22), a tab's as wide as its cut art is at
-- that height, and at most half the width, so a narrow button's middle isn't
-- turned inside out.
local function EndWidth(art, piece, width, height)
	local share = art.look.endShare
	if art.mode == 'tab' then
		local info = C_Texture.GetAtlasInfo(piece:GetAtlas())
		share = info and info.width / (info.height * TAB_SHARE) or 1
	end
	return math.min(math.floor(height * share + 0.5), math.floor(width / 2))
end

-- Sizes the ends to the button as SaftUI sized it; a secret size waits for
-- the next.
local function SizeEnds(button, art)
	if not art.mode then return end
	local width, height = button:GetSize()
	if issecretvalue(width) or issecretvalue(height) then return end
	for _, key in ipairs({ 'Left', 'Right' }) do
		art[key]:SetWidth(EndWidth(art, art[key], width, height))
	end
end

-- Puts the art for the button's state on its pieces: a tab picked or not,
-- the panel button up, down (under the mouse, or pressed) or disabled.
local function Paint(button, art)
	local look = art.look
	if art.mode == 'tab' then
		local set = art.picked and look.picked or look.other
		for _, key in ipairs(PIECES) do
			art[key]:SetAtlas(set[key:lower()])
			art[key]:SetTexCoord(unpack(TAB_COORDS))
		end
	elseif art.mode == 'button' then
		local file = look.up
		if not button:IsEnabled() then
			file = look.disabled
		elseif art.down or (art.pressed and art.pressed(button)) then
			file = look.down
		end
		for _, key in ipairs(PIECES) do
			art[key]:SetTexture(file)
			art[key]:SetTexCoord(unpack(look[key:lower()]))
		end
	end
end

-- A button's pieces, made once, with the scripts that swap them: a mouse down
-- and up, a disable and enable, a size change. Hooked, as callers set their
-- own scripts.
local function MakeArt(button)
	local art = {}
	for _, key in ipairs(PIECES) do art[key] = button:CreateTexture(nil, 'BACKGROUND') end
	art.Left:SetPoint('TOPLEFT', button, 'TOPLEFT')
	art.Left:SetPoint('BOTTOMLEFT', button, 'BOTTOMLEFT')
	art.Right:SetPoint('TOPRIGHT', button, 'TOPRIGHT')
	art.Right:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT')
	art.Middle:SetPoint('TOPLEFT', art.Left, 'TOPRIGHT')
	art.Middle:SetPoint('BOTTOMRIGHT', art.Right, 'BOTTOMLEFT')
	-- In the HIGHLIGHT layer, which the game shows only under the mouse.
	art.Highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	art.Highlight:SetAllPoints(button)
	arts[button] = art

	button:HookScript('OnMouseDown', function(self)
		if art.mode == 'button' and self:IsEnabled() then
			art.down = true
			Paint(self, art)
		end
	end)
	button:HookScript('OnMouseUp', function(self)
		art.down = false
		if art.mode == 'button' then Paint(self, art) end
	end)
	for _, script in ipairs({ 'OnEnable', 'OnDisable' }) do
		button:HookScript(script, function(self)
			if art.mode == 'button' then Paint(self, art) end
		end)
	end
	button:HookScript('OnSizeChanged', function(self) SizeEnds(self, art) end)
	return art
end

-- Shows mode's art on a button of SaftUI's ('button' or 'tab', picked or not;
-- pressed as st:ShowPanelButton takes it), or hides it (mode nil).
local function ShowArt(button, mode, picked, pressed)
	local art = arts[button]
	if not mode then
		if art and art.mode then
			art.mode, art.down = nil, false
			for _, key in ipairs(PIECES) do art[key]:Hide() end
			art.Highlight:Hide()
		end
		return
	end
	art = art or MakeArt(button)
	if art.mode ~= mode then
		art.mode = mode
		art.look = st.ThemeArt.Control(mode)
		for _, key in ipairs(PIECES) do art[key]:Show() end
		art.Middle:SetHorizTile(mode == 'tab')
		if mode == 'button' then
			art.Highlight:SetTexture(art.look.highlight)
			art.Highlight:SetTexCoord(unpack(art.look.highlightCoords))
			art.Highlight:SetBlendMode(art.look.highlightBlend)
			art.Highlight:Show()
		else
			art.Highlight:Hide()
		end
	end
	art.picked, art.pressed = picked, pressed
	Paint(button, art)
	SizeEnds(button, art)
end

-- Shows Blizzard's panel button on a button of SaftUI's (shown true), or
-- hides it. pressed, a function(button), says when it shows pressed besides
-- under the mouse: a check button styled 'button' while checked. Call it
-- again to show a change pressed hears of no other way.
function st:ShowPanelButton(button, shown, pressed)
	ShowArt(button, shown and 'button' or nil, nil, pressed)
end

-- button -> how st:SkinButton keeps it: { button, theme, background, flat,
-- own, tab, blizzard }. flat is SaftUI's flat state textures, own the Left,
-- Middle and Right of a button of Blizzard's panel button template, tab nil
-- or whether it's the picked tab (st:SetButtonTab), blizzard the look it
-- wears now.
local skins = setmetatable({}, { __mode = 'k' })

-- Puts a skinned button's look on for its Theme and Background: under
-- Blizzard (st:IsBlizzardLook) its flat textures hidden and Blizzard's art
-- shown, and under any other the reverse. Runs again after every recolor
-- and redraw (st:KeepOwnColors). It's kept under the skin, not the button: a
-- module keeps its own colors under the button (the bags' lit view button, a
-- radio group's pick), and st:KeepOwnColors holds one per key.
local function Draw(skin)
	local blizzard = st:IsBlizzardLook(skin.theme, skin.background)
	if blizzard ~= skin.blizzard then
		skin.blizzard = blizzard
		for _, texture in ipairs(skin.flat) do texture:SetAlpha(blizzard and 0 or 1) end
		for _, texture in ipairs(skin.own or {}) do texture:SetAlpha(blizzard and 1 or 0) end
	end
	if not skin.own then
		local mode = blizzard and (skin.tab == nil and 'button' or 'tab') or nil
		ShowArt(skin.button, mode, skin.tab)
	end
end

-- Draws button's backdrop in theme and background (Use SaftUI's theme and
-- Solid by default) as a control, and gives it font and SaftUI's hover,
-- pushed and disabled looks. Under the Blizzard theme it's Blizzard's panel
-- button instead (see above), which follows a theme switch.
function st:SkinButton(button, theme, background, font)
	assert(button)
	theme, background = theme or 'theme', background or 'solid'
	st:SetBackdrop(button, theme, background, 'control')

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

	local skin = skins[button]
	if not skin then
		skin = { button = button }
		skins[button] = skin
		for _,region in pairs({ button:GetRegions() }) do
			if region:GetObjectType() == 'Texture' then
				region:SetAlpha(0)
			end
		end
		-- Blizzard's panel button template (retail's bank deposit button)
		-- shows its own art again under Blizzard, by alpha alone.
		if button.Left and button.Middle and button.Right then
			skin.own = { button.Left, button.Middle, button.Right }
		end
		st:KeepOwnColors(skin, Draw)
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

	skin.flat = {}
	for _, key in ipairs({ 'hover', 'pushed', 'disabled' }) do
		if button[key] then table.insert(skin.flat, button[key]) end
	end
	skin.theme, skin.background, skin.blizzard = theme, background, nil
	Draw(skin)
end

-- Draws a button st:SkinButton skinned as one of Blizzard's top tabs under
-- the Blizzard theme (st.ThemeArt.Control('tab')), the picked one active, in
-- place of the panel button: a radio group's buttons. Under Thick and Thin it
-- changes nothing.
function st:SetButtonTab(button, picked)
	local skin = skins[button]
	if not skin then return end
	skin.tab = picked and true or false
	Draw(skin)
end
