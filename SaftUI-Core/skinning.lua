local st = SaftUI

function st:StripTextures(frame, kill)
	if frame.SetNormalTexture    then frame:SetNormalTexture('')    end
	if frame.SetHighlightTexture then frame:SetHighlightTexture('') end
	if frame.SetPushedTexture    then frame:SetPushedTexture('')    end
	if frame.SetDisabledTexture  then frame:SetDisabledTexture('')  end

	local name = frame.GetName and frame:GetName()
	if name then
		if _G[name..'Left'] then st:StripTextures(_G[name..'Left']) end
		if _G[name..'Middle'] then st:StripTextures(_G[name..'Middle']) end
		if _G[name..'Right'] then st:StripTextures(_G[name..'Right']) end
	end

	if frame.Left then frame.Left:SetAlpha(0) end
	if frame.Right then frame.Right:SetAlpha(0) end
	if frame.Middle then frame.Middle:SetAlpha(0) end

	if frame.NineSlice then st:Kill(frame.NineSlice) end

	if frame.GetNumRegions then
		for i=1, frame:GetNumRegions() do
			local region = select(i, frame:GetRegions())
			if region:GetObjectType() == 'Texture' then
				if kill then
					st:Kill(region)
				else
					region:SetTexture(nil)
				end
			end
		end
	end
end

-- The tex coords (left, right, top, bottom) SaftUI crops an icon width by
-- height to: trim, a fraction of the art, off each edge, after a wide or tall
-- icon's art is cut to its shape around the middle so it isn't stretched. A
-- square icon, or one with no size yet, just loses trim off each edge.
-- st:SkinIcon crops with these, and so does Icon zoom's preview in /sui
-- (Config/general.lua), so the preview shows what the icons will.
function st:IconTexCoords(trim, width, height)
	if width and height and width ~= height then
		local biggest = max(width, height)
		local halfWidth = 0.5 * width / biggest - trim
		local halfHeight = 0.5 * height / biggest - trim
		return 0.5 - halfWidth, 0.5 + halfWidth, 0.5 - halfHeight, 0.5 + halfHeight
	end
	return trim, 1 - trim, trim, 1 - trim
end

-- icon -> { left, right, top, bottom }, the crop st:SkinIcon last gave it,
-- and icon -> true once its SetTexCoord is hooked to keep that crop. Kept
-- here, not on the icon, which is often Blizzard's (.agents/taint.md).
local iconCrops = setmetatable({}, { __mode = 'k' })
local hookedIcons = setmetatable({}, { __mode = 'k' })

function st:SkinIcon(icon, customTrim, anchorFrame)
	if anchorFrame then
		icon:SetAllPoints(anchorFrame)
		icon:SetSize(anchorFrame:GetSize())
	end

	-- Modern item/action buttons mask their icons (e.g. ItemButton.Mask rounds the
	-- corners), which SetTexCoord can't undo. Strip them so the trim shows square.
	if icon.GetNumMaskTextures then
		for i = icon:GetNumMaskTextures(), 1, -1 do
			icon:RemoveMaskTexture(icon:GetMaskTexture(i))
		end
	end

	if icon.SetTexCoord then
		local w, h = icon:GetSize()
		local trim = customTrim or st.config.profile.misc.icon_trim
		local left, right, top, bottom
		if issecretvalue(w) or issecretvalue(h) then
			-- Icons inside restricted frames (e.g. aura containers) have secret
			-- sizes that can't be compared; assume a square icon.
			left, right, top, bottom = trim, 1 - trim, trim, 1 - trim
		else
			left, right, top, bottom = st:IconTexCoords(trim, w, h)
		end

		-- Recorded before the set: the hook below reads it.
		local crop = iconCrops[icon]
		if not crop then
			crop = {}
			iconCrops[icon] = crop
		end
		crop[1], crop[2], crop[3], crop[4] = left, right, top, bottom
		icon:SetTexCoord(left, right, top, bottom)

		-- Blizzard's SetItemButtonTexture resets icons to full tex coords (0, 1, 0, 1)
		-- every time it assigns a texture, which would undo our trim. Put it back.
		-- Not when the crop is the full texture itself (Icon zoom 0): putting it
		-- back would set (0, 1, 0, 1) again and run this hook forever.
		if not hookedIcons[icon] then
			hookedIcons[icon] = true
			hooksecurefunc(icon, 'SetTexCoord', function(self, l, r, t, b, ...)
				local c = iconCrops[self]
				if not c or issecretvalue(l) or select('#', ...) ~= 0 then return end
				if l == 0 and r == 1 and t == 0 and b == 1
					and not (c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 1) then
					self:SetTexCoord(c[1], c[2], c[3], c[4])
				end
			end)
		end
	else
		print('function SetTexCoord does not exist for', icon:GetName() or icon)
	end
end

local function OnSetCooldown(self, start, duration, modRate)
	self.startTime = start
	self.duration = duration
	self.endTime = start + duration
end

local function OnUpdateCooldown(self)
	local remaining = self.endTime and (self.endTime - GetTime()) or 0
	if remaining <= 0 then
		self.text:SetText('')
	else
		self.text:SetText(st.StringFormat:ToTime(remaining))
	end
end
-- Cooldowns st:SkinCooldown has done, so skinning a button again (e.g. on a
-- profile change) doesn't add another text. Weak keys: nothing is written onto
-- the (often Blizzard) cooldown to remember it.
local skinnedCooldowns = setmetatable({}, { __mode = 'k' })

function st:SkinCooldown(button, cooldown)
	if skinnedCooldowns[cooldown] then return end
	skinnedCooldowns[cooldown] = true
	cooldown:SetHideCountdownNumbers(true)
	local text = cooldown:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(st:GetFont('pixel'))
	text:SetAllPoints(cooldown)
	cooldown.text = text
	--cooldown:SetScript('OnUpdate', OnUpdateCooldown)
	--hooksecurefunc(cooldown, 'SetCooldown', OnSetCooldown)
end

-- hover -> the blend button:SetHighlightTexture gave the flat hover
-- st:SkinActionButton made, so it goes back on after Blizzard's state art
-- (which sets its own). Kept here, not on the texture.
local hoverBlends = setmetatable({}, { __mode = 'k' })

-- Skins button with config (the profile's buttons by default): its backdrop in
-- config.theme and config.background, drawn as kind ('action' by default; a
-- bag slot is a 'slot'), and config.font and config.trueSize.
function st:SkinActionButton(button, config, kind)
	config = config or st.config.profile.buttons

	st:SetBackdrop(button, config.theme, config.background, kind or 'action')

    local inset = config.trueSize and st:CalculateSpacing(button) or 0
    if config.trueSize then
        button.backdrop:ClearAllPoints()
        button.backdrop:SetAllPoints()
    end

	local name = button:GetName() or ''

	local icon = _G[name.."Icon"] or _G[name..'IconTexture'] or button.icon or button.Icon
	local count = _G[name.."Count"] or button.count or button.Count
	local flash = _G[name.."Flash"] or button.flash or button.Flash
	local hotkey = _G[name.."HotKey"] or button.hotkey or button.HotKey
	local border = _G[name.."Border"] or button.border or button.Border
	local normal = _G[name.."NormalTexture"] or button.NormalTexture
	local item_level = button.item_level
	local bg = _G[name..'FloatingBG']
	local cooldown = _G[name..'Cooldown'] or button.cooldown or button.Cooldown

	for _,region in pairs({
		'Left', 'Middle', 'Right',
		'TopLeft', 'TopMiddle', 'TopRight',
		'MiddleLeft', 'MiddleMiddle', 'MiddleRight',
		'BottomLeft', 'BottomMiddle', 'BottomRight',
		'LeftSeparator', 'RightSeparator',
	}) do if button[region] then button[region]:SetAlpha(0) end end

	if bg then
		bg:SetTexture(nil)
	end

	if flash then
		flash:SetTexture('')
		st:SetInside(flash, inset)
	end

	if icon then
		st:SkinIcon(icon)
		st:SetInside(icon, inset)
	end

	st:Kill(button.CircleMask)

	if config.font then
		local font_object = st:GetFont(config.font)

		for _,region in pairs({button:GetRegions()}) do
			if region:GetObjectType() == 'FontString' then
				region:SetFontObject(font_object)
			end
		end

		if cooldown then
			st:SkinCooldown(button, cooldown)
		end

		if count and type(count) == 'table' then
			count:ClearAllPoints()
			count:SetPoint('BOTTOMRIGHT', 2 - inset, 1 + inset)
			count:SetJustifyH('RIGHT')
			count:SetJustifyV('BOTTOM')
		end

		if item_level then
			item_level:ClearAllPoints()
			item_level:SetPoint('BOTTOMRIGHT', 2 - inset, 1 + inset)
			item_level:SetJustifyH('RIGHT')
			item_level:SetJustifyV('BOTTOM')
		end

		if hotkey then
			hotkey:ClearAllPoints()
			hotkey:SetPoint('TOPRIGHT', 2, 2)
			hotkey:SetPoint("TOPLEFT", 4, 0)
			hotkey:SetJustifyH('RIGHT')
			hotkey:SetJustifyV('TOP')
		end

		if button.SetNormalFontObject then
			button:SetNormalFontObject(font_object)
			button:SetHighlightFontObject(font_object)
			button:SetDisabledFontObject(font_object)
			button:SetPushedTextOffset(0, 0)
		end
	end

	if normal and button.SetNormalTexture then
		button:SetNormalTexture('')
		st:SetInside(normal, inset)
	end

	-- These are made once; skinning again (e.g. on a profile change) only
	-- re-applies their color and inset, which follow the theme. Under Blizzard
	-- the pushed and highlight textures are Blizzard's state art for the kind
	-- (st.ThemeArt.State), over the ring's footprint, the whole button, with no
	-- tint; otherwise SaftUI's flat textures over the icon.
	kind = kind or 'action'
	local look = st:ResolveTheme(config.theme, config.background, kind)
	local state = look and look.name == 'blizzard' and st.ThemeArt.State(kind) or nil
	local hoverArt = state and (state.hover or state.highlight)

	if button.SetHighlightTexture and not button.hover then
		local hover = button:CreateTexture(nil, 'OVERLAY')
		hover:SetTexture(st.BLANK_TEX)
		button.hover = hover
		button:SetHighlightTexture(hover)
		hoverBlends[hover] = hover:GetBlendMode()
	end
	if button.hover then
		if hoverArt then
			local blend = state.highlightBlend or 'ADD'
			-- The setter first, then the art, kept in the hover's layer, where
			-- the client shows it only under the mouse (HOVER_LAYER).
			button:SetHighlightTexture(button.hover, blend)
			st.ThemeArt.StyleState(button.hover, hoverArt, button, blend, st.ThemeArt.HOVER_LAYER)
		else
			button.hover:SetTexture(st.BLANK_TEX)
			button.hover:SetTexCoord(0, 1, 0, 1)
			-- Shown only under the mouse in this layer; moved out, all the time.
			button.hover:SetDrawLayer(st.ThemeArt.HOVER_LAYER, 0)
			-- The blend the hover was made with (most likely the client's
			-- additive default), which Blizzard's art changed: a tint over the
			-- icon, as before the Blizzard theme. BLEND would make it opaque.
			if hoverBlends[button.hover] then
				button.hover:SetBlendMode(hoverBlends[button.hover])
			end
			button.hover:ClearAllPoints()
			-- button.hover:SetVertexColor(1, 1, 1, .1)
			button.hover:SetVertexColor(st.config.profile.colors.button.blue:GetRGB())
			st:SetInside(button.hover, inset)
		end
	end

	if button.SetPushedTexture and not button.pushed then
		local pushed = button:CreateTexture(nil, 'OVERLAY')
		pushed:SetTexture(st.BLANK_TEX)
		pushed:SetVertexColor(0, 0, 0, .1)
		button.pushed = pushed
		button:SetPushedTexture(pushed)
	end
	if button.pushed then
		if state and state.pushed then
			-- A caller may have cleared the pushed texture under Thick
			-- (the bags' slots do): it's Blizzard's art again. The setter first,
			-- then the layer (see the hover's).
			button:SetPushedTexture(button.pushed)
			st.ThemeArt.StyleState(button.pushed, state.pushed, button)
		else
			button.pushed:SetTexture(st.BLANK_TEX)
			button.pushed:SetTexCoord(0, 1, 0, 1)
			button.pushed:SetDrawLayer('OVERLAY', 0)
			button.pushed:SetVertexColor(0, 0, 0, .1)
			button.pushed:ClearAllPoints()
			st:SetInside(button.pushed, inset)
		end
	end

	if button.SetDisabledTexture and not button.disabled then
		local disabled = button:CreateTexture(nil, 'OVERLAY')
		disabled:SetTexture(st.BLANK_TEX)
		disabled:SetVertexColor(0, 0, 0, .4)
		button.disabled = disabled
		button:SetDisabledTexture(disabled)
	end
	if button.disabled then
		st:SetInside(button.disabled, inset)
	end
end

-- editbox -> { theme, background } it was last styled with, so losing focus
-- draws it again. Kept here, not on the box: chat's is Blizzard's.
local editBoxLooks = setmetatable({}, { __mode = 'k' })

-- editbox -> the backdrop of SaftUI's drawn behind it (st:SetBackdropIn):
-- nothing is written onto the box, as chat's is Blizzard's.
local editBoxBackdrops = setmetatable({}, { __mode = 'k' })

-- editbox -> its own border textures: an input box's Left, Middle and Right
-- (InputBoxTemplate, SearchBoxTemplate), chat's Left, Mid and Right and its
-- focus textures (ChatFrameEditBoxTemplate).
local editBoxBorders = setmetatable({}, { __mode = 'k' })
local BORDER_KEYS = { 'Left', 'Right', 'Middle', 'Mid', 'focusLeft', 'focusRight', 'focusMid' }
local NO_BORDERS = {}

-- A focused box's white border, kept through a theme recolor. A box drawn
-- with None has no backdrop to color, and a control's border under the
-- Blizzard theme is left alone (st:SetBorderColor), so none there.
local function ColorFocused(editbox)
	local backdrop = editBoxBackdrops[editbox]
	if editbox:HasFocus() and backdrop then
		st:SetBorderColor(backdrop, 1, 1, 1, 1)
	end
end

-- Shows the box's own border textures while it's drawn in the Blizzard
-- theme, and conceals them (alpha 0) in any other look. Alpha alone hides
-- them: Blizzard never sets these regions' alpha (InputBoxTemplates and
-- ChatFrameEditBox, on both clients; chat shows and hides its focus textures
-- and sets the box's own alpha), and nothing is written onto them. A box
-- st:StyleEditBox draws that st:SkinEditBox never skinned has none.
local function ShowBorders(editbox)
	local alpha = st:DrawnTheme(editbox) == 'blizzard' and 1 or 0
	for _, region in ipairs(editBoxBorders[editbox] or NO_BORDERS) do
		region:SetAlpha(alpha)
	end
end

local function DrawEditBox(editbox, look)
	st:SetBackdropIn(editBoxBackdrops, editbox, look[1], look[2], 'control')
	ShowBorders(editbox)
end

-- After a recolor or redraw: the borders for the look the box is drawn in
-- now, and its focus color.
local function RedrawEditBox(editbox)
	ShowBorders(editbox)
	ColorFocused(editbox)
end

-- Skins an edit box: its own border textures concealed, SaftUI's backdrop in
-- theme and background (Use SaftUI's theme and Solid by default), drawn as a
-- control, font for its text, and a white border while it has focus. Under
-- the Blizzard theme the box's own border textures show instead, and there's
-- no backdrop of SaftUI's.
function st:SkinEditBox(editbox, theme, background, font)
	local name = editbox:GetName()

	local borders = {}
	for _,region_name in pairs(BORDER_KEYS) do
		local region = name and _G[name..region_name] or editbox[region_name]
		if region then
			table.insert(borders, region)
		end
	end
	editBoxBorders[editbox] = borders


	if editbox.searchIcon then
		editbox.searchIcon:ClearAllPoints()
		editbox.searchIcon:SetPoint('LEFT', editbox, 5, -1)
	end

	if editbox.Instructions then
		editbox.Instructions:ClearAllPoints()
		editbox.Instructions:SetPoint('LEFT', editbox, 'LEFT', editbox.searchIcon and 20 or 5, 0)
	end

	st:StyleEditBox(editbox, theme, background, font)

	editbox:HookScript('OnEditFocusGained', ColorFocused)
	st:KeepOwnColors(editbox, RedrawEditBox)

	-- Restore the look the box has now (st:StyleEditBox may have changed it
	-- since), not the one it was skinned with.
	editbox:HookScript('OnEditFocusLost', function(self)
		DrawEditBox(self, editBoxLooks[self])
	end)
end

-- Applies a theme, background and font to an edit box st:SkinEditBox skinned,
-- as st:SkinEditBox takes them. Safe to call again (e.g. on a profile change):
-- it adds no hooks or regions.
function st:StyleEditBox(editbox, theme, background, font)
	local look = { theme or 'theme', background or 'solid' }
	editBoxLooks[editbox] = look
	DrawEditBox(editbox, look)

	if font then
		local fontObject = st:GetFont(font)
		if editbox.Instructions then
			editbox.Instructions:SetFontObject(fontObject)
		end
		local text, _, _, _, header = editbox:GetRegions()
		text:SetFontObject(fontObject)
		-- if header then
		-- 	header:SetFontObject(fontObject)
		-- end
	end
end

function st:EnableHorizontalResizing(frame, ...)
	st:EnableResizing(frame, ...)
	frame.ResizeButton:SetScript()
end

function st:EnableResizing(frame, resizeButton, callback)
	if resizeButton then
		frame.ResizeButton = resizeButton
	else
		local resize = st:CreateFrame('Button', nil, frame)
		resize:SetScript('OnMouseDown', function(self)
			if frame.PreResize then frame:PreResize() end
			frame:StartSizing()
		end)
		resize:SetScript('OnMouseUp', function(self)
			frame:StopMovingOrSizing()
			if frame.PostResize then frame:PostResize() end
		end)
		resize:SetFrameStrata("HIGH")
		frame.ResizeButton = resize
	end

	frame:SetResizable(true)
	frame.ResizeButton:ClearAllPoints()
	st:SetSize(frame.ResizeButton, 16, 16)
	frame.ResizeButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

	frame.ResizeButton:SetNormalTexture(st.textures.cornerbr)

	frame.ResizeButton:SetPushedTexture(st.textures.cornerbr)
	frame.ResizeButton:GetPushedTexture():SetVertexColor(st.config.profile.colors.button.hover:GetRGB())

	frame.ResizeButton:SetHighlightTexture(st.textures.cornerbr)
	frame.ResizeButton:GetHighlightTexture():SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
	frame.ResizeButton:GetHighlightTexture():SetBlendMode('BLEND')

	frame.ResizeButton:SetFrameLevel(4)
end