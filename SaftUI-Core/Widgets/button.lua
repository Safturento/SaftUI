local st = SaftUI

-- Core's Button text setting (Global settings > Fonts), read when a button's
-- label is drawn or follows.
local function ButtonsFont() return st.config.profile.buttons.font end

-- Makes a label a SaftUI button shows (a font string of the module's own, not the
-- button's own text) follow Button text, one line, centred between the button's
-- sides: it takes its own height, so a larger font can't leave it shorter than a
-- line, and a label too wide for the button is cut at the sides, never blanked
-- or growing the button.
function st:SkinButtonLabel(label, button)
	label:ClearAllPoints()
	label:SetPoint('LEFT', button, 'LEFT', 2, 0)
	label:SetPoint('RIGHT', button, 'RIGHT', -2, 0)
	label:SetWordWrap(false)
	st:FollowFont(label, ButtonsFont)
end

-- Puts a font object on a button's own normal, highlight and disabled states,
-- which is what draws its label. Passed to st:FollowFont, since a Button has
-- no SetFontObject to follow with.
local function ApplyStates(button, fontObject)
	if button.SetNormalFontObject then
		button:SetNormalFontObject(fontObject)
		button:SetHighlightFontObject(fontObject)
		button:SetDisabledFontObject(fontObject)
	end
end

-- Makes a SaftUI button with its label in button.text. font, if given (a
-- shared font's key or a typeface), is the label's own and follows nothing but
-- that font; by default the label is Button text and follows its changes at
-- once (the micro menu's clock is given Small text, which the bar keeps).
function st:CreateButton(name, parent, text, theme, background, font)
	local button = self:CreateFrame('Button', name and 'SaftUI_'..name or nil, parent)
	button.text = self:CreateFontString(button, font or ButtonsFont(), text)
	if font then
		button.text:SetPoint('LEFT', button, 'LEFT', 2, 0)
		button.text:SetPoint('RIGHT', button, 'RIGHT', -2, 0)
		button.text:SetWordWrap(false)
	else
		st:SkinButtonLabel(button.text, button)
	end

    self:SkinButton(button, theme, background, font)

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
	  - st:SkinButton draws it on the buttons it skins, pressed while
	    st:SetButtonPressed says so (the bags' current view), or Blizzard's
	    top tabs on a radio group's (st:SetButtonTab); a button of Blizzard's
	    panel button template shows its own Left, Middle and Right again
	    instead.
	Every piece is a texture of SaftUI's on a button of SaftUI's, inside the
	button's own rect, kept in this file's tables, never in a field
	(.agents/taint.md). It's made the first time the button shows it, so a
	button never drawn under Blizzard has none.
]]

-- button -> its art: { Left, Middle, Right, Highlight, mode, look, picked,
-- pressed, disabled, down }. mode is 'button' (the panel button), 'tab', or
-- nil while hidden; look is st.ThemeArt.Control(mode), read when the mode
-- changes.
local arts = setmetatable({}, { __mode = 'k' })

local PIECES = { 'Left', 'Middle', 'Right' }
local ENDS = { 'Left', 'Right' }

-- A tab's art as Blizzard's top tabs draw it (PanelTopTabButtonMixin): upside
-- down, the art's last quarter, which would lie over the window, cut off.
local TAB_COORDS, TAB_SHARE = { 0, 1, 1, 0.25 }, 0.75

-- How wide an end piece (key, Left or Right) is on a button width by height:
-- the panel's endShare of its height (Blizzard's 12 on 22), a tab's as wide
-- as its cut art (the picked or the other, from the look) is at that height,
-- and at most half the width, so a narrow button's middle isn't turned
-- inside out.
local function EndWidth(art, key, width, height)
	local share = art.look.endShare
	if art.mode == 'tab' then
		local set = art.picked and art.look.picked or art.look.other
		local info = C_Texture.GetAtlasInfo(set[key:lower()])
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
	for _, key in ipairs(ENDS) do
		art[key]:SetWidth(EndWidth(art, key, width, height))
	end
end

-- Puts the art for the button's state on its pieces: a tab picked or not,
-- the panel button up, down (under the mouse, or pressed) or disabled (its
-- button disabled, or disabled says so).
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
		if not button:IsEnabled() or (art.disabled and art.disabled(button)) then
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
-- pressed and disabled as st:ShowPanelButton takes them), or hides it (mode
-- nil).
local function ShowArt(button, mode, picked, pressed, disabled)
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
	art.picked, art.pressed, art.disabled = picked, pressed, disabled
	Paint(button, art)
	SizeEnds(button, art)
end

-- Shows Blizzard's panel button on a button of SaftUI's (shown true), or
-- hides it. pressed, a function(button), says when it shows pressed besides
-- under the mouse: a check button styled 'button' while checked. disabled,
-- one too, says when it shows disabled besides while its button is: a /sui
-- widget, which the window dims instead. Call it again to show a change they
-- hear of no other way.
function st:ShowPanelButton(button, shown, pressed, disabled)
	ShowArt(button, shown and 'button' or nil, nil, pressed, disabled)
end

local function Pressed()
	return true
end

-- button -> how st:SkinButton keeps it: { button, theme, background, own,
-- tab, pressed, blizzard, hooked }. own is the Left, Middle and Right of a
-- button of Blizzard's panel button template, tab nil or whether it's the
-- picked tab (st:SetButtonTab), pressed whether its panel button shows pressed
-- (st:SetButtonPressed), blizzard the look it wears now. The button's states
-- (hover, pushed, selected, disabled) are the helpers' (Widgets/states.lua),
-- registered in st:SkinButton.
local skins = setmetatable({}, { __mode = 'k' })

-- Whether a skinned button shows disabled (Alpha d): it is disabled, and not on
-- Blizzard's art, whose -Disabled art is the whole look (a panel button of
-- Blizzard's, skin.own, keeps its game alpha under Blizzard and is dimmed under
-- SaftUI's looks, where its art is faded).
local function SyncDisabled(skin)
	local button = skin.button
	local want = not button:IsEnabled() and not st:IsBlizzardLook(skin.theme, skin.background)
	if st:GetState(button, 'disabled') ~= want then st:SetState(button, 'disabled', want) end
end

-- Puts a skinned button's look on for its Theme and Background: under
-- Blizzard (st:IsBlizzardLook) Blizzard's art shown, and under any other
-- SaftUI's; and when the look flipped, its states drawn again for it
-- (st:RestyleStates, last, and the disabled state, which Blizzard's art draws
-- itself). Runs again after every recolor and redraw (st:KeepOwnColors), which
-- lay nothing out unless the look flipped (a theme inset change is the
-- helper's own, theme-edge, restyle). It's kept under the skin, not the button:
-- a module keeps its own colors under the button (the bags' lit view button),
-- and st:KeepOwnColors holds one per key.
local function Draw(skin)
	local button = skin.button
	local blizzard = st:IsBlizzardLook(skin.theme, skin.background)
	local flipped = blizzard ~= skin.blizzard
	if flipped then
		skin.blizzard = blizzard
		for _, texture in ipairs(skin.own or {}) do texture:SetAlpha(blizzard and 1 or 0) end
	end
	if not skin.own then
		local mode = blizzard and (skin.tab == nil and 'button' or 'tab') or nil
		ShowArt(button, mode, skin.tab, skin.pressed and Pressed or nil)
	end
	if flipped then
		st:RestyleStates(button)
		if skin.hooked then SyncDisabled(skin) end
	end
end

-- The font strings that are a button's label: the button's own, and the label
-- SaftUI's buttons keep in .text (st:CreateButton).
local function Labels(button)
	local list = {}
	local own = button.GetFontString and button:GetFontString()
	if own then list[#list + 1] = own end
	local text = button.text
	if type(text) == 'table' and text ~= own and text.GetObjectType and text:GetObjectType() == 'FontString' then
		list[#list + 1] = text
	end
	if #list == 0 then
		for _, region in pairs({ button:GetRegions() }) do
			if region:GetObjectType() == 'FontString' then list[#list + 1] = region end
		end
	end
	return list
end

-- A button of Blizzard's own templates has its own highlight, pushed and
-- disabled textures, which SaftUI's states replace: cleared, none made.
local function ClearStateTextures(button)
	for _, state in ipairs({ 'Highlight', 'Pushed', 'Disabled' }) do
		local get, set = button['Get' .. state .. 'Texture'], button['Set' .. state .. 'Texture']
		if get and set and get(button) then set(button, '') end
	end
end

-- Enable, Disable and SetEnabled set the disabled state, as post-hooks: the
-- button's own methods stay as they are.
local function SetDisabledState(button)
	local skin = skins[button]
	if skin then SyncDisabled(skin) end
end

-- A module's SetScript on a state script drops the helpers' mouse hooks (as in the
-- game): a post-hook on SaftUI's own button hooks them again, so hover shows
-- whatever order the module did it in.
local WIRED = { OnEnter = true, OnLeave = true, OnMouseDown = true, OnMouseUp = true, OnHide = true }
local function Rehook(button, script)
	if WIRED[script] then st:RestyleStates(button) end
end

-- button -> { r, g, b, painted }: the color its label has at rest, which the helper puts back after a state.
local rests = setmetatable({}, { __mode = 'k' })

-- The labels as the helper paints them, each behind a stand-in that notes the label's color at
-- rest. A label's rest color is the one it has just before a state first draws on it: the font
-- object's white to begin with, and whatever its module set since (the bank's Buy in
-- Text > Danger). The helper paints it under a state and puts that back (textRest). No hook on
-- any label (a hooked SetTextColor would cost every pass's paint).
local function RestLabels(button, labels)
	local rest = rests[button]
	if not rest then
		rest = { 1, 1, 1, false }
		rests[button] = rest
	end
	local list = {}
	for i, label in ipairs(labels) do
		list[i] = {
			GetTextColor = function() return label:GetTextColor() end,
			SetTextColor = function(_, r, g, b)
				local lit = st:GetState(button, 'hover') or st:GetState(button, 'pushed') or st:GetState(button, 'selected')
				if lit then
					if not rest[4] then
						rest[4] = true
						local rr, rg, rb = labels[1]:GetTextColor()
						if type(rr) == 'number' then rest[1], rest[2], rest[3] = rr, rg, rb end
					end
				else
					rest[4] = false
				end
				label:SetTextColor(r, g, b)
			end,
		}
	end
	return list
end

-- Draws button's backdrop in theme and background (Use SaftUI's theme and
-- Solid by default) as a control, and gives it font and SaftUI's states
-- (st:AddStates 'box': hover, pushed, selected, disabled). font is a shared font's key or a typeface; with
-- none the button's label is Button text and follows it (its normal,
-- highlight and disabled font objects, or its font strings on a frame with no
-- states). Under the Blizzard theme it's Blizzard's panel
-- button instead (see above), which follows a theme switch.
function st:SkinButton(button, theme, background, font)
	assert(button)
	theme, background = theme or 'theme', background or 'solid'
	st:SetBackdrop(button, theme, background, 'control')

	local fontObject = st:FontObject(font or ButtonsFont())
	if button.SetNormalFontObject then
		button:SetNormalFontObject(fontObject)
		button:SetHighlightFontObject(fontObject)
		button:SetDisabledFontObject(fontObject)
		button:SetPushedTextOffset(0, 0)
		-- Button text follows from here on; a font of its own stops it.
		st:FollowFont(button, font == nil and ButtonsFont or nil, ApplyStates)
	else
		for _,region in pairs({ button:GetRegions() }) do
			if region:GetObjectType() == 'FontString' then
				if font == nil then
					st:FollowFont(region, ButtonsFont)
				else
					st:FollowFont(region, nil)
					region:SetFontObject(fontObject)
				end
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
	ClearStateTextures(button)

	-- Hover and pushed tint the body under the label, selected is the theme's edge
	-- in the Accent with the fade, disabled dims it. The disabled hooks go on once,
	-- but not on a Blizzard panel button, whose game art and alpha stay.
	local labels = Labels(button)
	st:AddStates(button, 'box', {
		edge = 'theme',
		text = RestLabels(button, labels),
		textRest = function() local r = rests[button] return r[1], r[2], r[3] end,
		blizzard = function() return st:IsBlizzardLook(skin.theme, skin.background) end,
	})
	if not skin.hooked and button.IsEnabled then
		skin.hooked = true
		if skin.own then
			-- Blizzard's button: script hooks only (nothing written onto it, no method hooked)
			button:HookScript('OnEnable', SetDisabledState)
			button:HookScript('OnDisable', SetDisabledState)
		else
			for _, method in ipairs({ 'Enable', 'Disable', 'SetEnabled' }) do
				if button[method] then hooksecurefunc(button, method, SetDisabledState) end
			end
			hooksecurefunc(button, 'SetScript', Rehook)
		end
	end

	skin.theme, skin.background, skin.blizzard = theme, background, nil
	Draw(skin)
	if skin.hooked then SyncDisabled(skin) end
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

-- Shows a button st:SkinButton skinned pressed (-Down) under the Blizzard
-- theme while pressed is true, as its own state, kept through every recolor
-- and redraw: the bags' view button for the window's view, which Thick and
-- Thin light with a border of the bags' own (a control's border under
-- Blizzard is left alone, st:SetBorderColor). Under Thick and Thin it changes
-- nothing.
function st:SetButtonPressed(button, pressed)
	local skin = skins[button]
	if not skin then return end
	skin.pressed = pressed and true or false
	Draw(skin)
	st:SetState(button, 'selected', skin.pressed)
end
