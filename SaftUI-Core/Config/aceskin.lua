local st = SaftUI

-- Scoped reskin of AceGUI. Only widgets inside a window made by
-- AceSkin:CreateWindow get the SaftUI look; every other addon's Ace windows
-- stay stock.
--
-- AceGUI widgets are pooled and shared by every addon, so each change made to a
-- scoped widget records how to undo exactly that change. The undo list runs
-- when the widget is released back to the pool (hooked on AceGUI.Release), so
-- the next addon to get it from the pool sees it as AceGUI built it.

local AceGUI = LibStub('AceGUI-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')

local Skin = {}
st.AceSkin = Skin

local states = {}   -- scoped widget -> { undo = { fn, ... }, saved = {} }
local windows = {}  -- window widget -> { name, onClose }
local apps = {}       -- AceConfig app names that open in SaftUI windows
local owned = setmetatable({}, { __mode = 'k' }) -- host frame -> { key -> object we created }

local FLAT_BACKDROP = {
	bgFile = st.BLANK_TEX,
	edgeFile = st.BLANK_TEX,
	edgeSize = 1,
	tile = false, tileSize = 0,
	insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local Scope, Unscope

--------------------------------------------------------------------------------
-- Recorded changes. Each helper saves the current value, pushes an undo, then
-- applies the new value.
--------------------------------------------------------------------------------

local function Push(state, fn)
	state.undo[#state.undo + 1] = fn
end

local function Font(name)
	return st:GetFont(name) or st:GetFont('pixel')
end

local function TextColor()
	return st.config.profile.colors.text.normal:GetRGB()
end

local function Blue()
	return st.config.profile.colors.button.blue:GetRGB()
end

local function SetAlpha(state, region, alpha)
	if not region then return end
	local old = region:GetAlpha()
	Push(state, function() region:SetAlpha(old) end)
	region:SetAlpha(alpha)
end

-- Undos run after AceGUI:Release has called the widget's OnRelease, and some
-- OnRelease functions reset state themselves (e.g. Dropdown's SetDisabled(false)
-- resets its text colors). So undos never put back a value the widget may have
-- reset since: font undos restore only the font, and color undos restore only
-- if the color is still the one we set.

-- FontStrings and EditBoxes. SetFontObject also applies the font object's
-- color, so the color in place is re-applied after it, both when styling and
-- when restoring: the font changes, the color stays whatever the widget set.
-- GetFontObject() can return an engine-made Font that belongs to the region
-- itself (e.g. after its text color was changed). Setting that back makes the
-- region inherit from itself, which overflows the C stack and crashes the game.
-- So only a named global font object is ever restored as an object; anything
-- else is restored from the recorded file, size and flags.
local function RestoreFont(fs, oldObject, file, size, flags)
	local name = oldObject and oldObject.GetName and oldObject:GetName()
	if name and _G[name] == oldObject then
		fs:SetFontObject(oldObject)
	elseif file then
		fs:SetFont(file, size, flags)
	end
end

local function SetFont(state, fs, font)
	if not fs or not font then return end
	local oldObject = fs:GetFontObject()
	local file, size, flags = fs:GetFont()
	Push(state, function()
		local r, g, b, a = fs:GetTextColor()
		RestoreFont(fs, oldObject, file, size, flags)
		fs:SetTextColor(r, g, b, a)
	end)
	local r, g, b, a = fs:GetTextColor()
	fs:SetFontObject(font)
	fs:SetTextColor(r, g, b, a)
end

local function SameColor(r1, g1, b1, a1, r2, g2, b2, a2)
	local e = 0.005
	return math.abs(r1 - r2) < e and math.abs(g1 - g2) < e
		and math.abs(b1 - b2) < e and math.abs((a1 or 1) - (a2 or 1)) < e
end

local function SetTextColor(state, fs, r, g, b, a)
	if not fs then return end
	a = a or 1
	local or_, og, ob, oa = fs:GetTextColor()
	Push(state, function()
		local cr, cg, cb, ca = fs:GetTextColor()
		if SameColor(cr, cg, cb, ca, r, g, b, a) then
			fs:SetTextColor(or_, og, ob, oa)
		end
	end)
	fs:SetTextColor(r, g, b, a)
end

-- Replaces a texture's image. r == nil keeps its vertex color, and then the
-- undo leaves the vertex color alone too (e.g. a ColorPicker's picked color).
local function Retexture(state, tex, file, r, g, b, a, blend)
	if not tex then return end
	local atlas = tex.GetAtlas and tex:GetAtlas()
	if atlas == '' then atlas = nil end
	local oldFile = tex:GetTexture()
	local coords = { tex:GetTexCoord() }
	local vr, vg, vb, va = tex:GetVertexColor()
	local oldBlend = tex:GetBlendMode()
	Push(state, function()
		if atlas then
			tex:SetAtlas(atlas)
		else
			tex:SetTexture(oldFile)
			if #coords == 8 then tex:SetTexCoord(unpack(coords)) end
		end
		if r then tex:SetVertexColor(vr, vg, vb, va) end
		tex:SetBlendMode(oldBlend)
	end)
	tex:SetTexture(file)
	tex:SetTexCoord(0, 1, 0, 1)
	if r then tex:SetVertexColor(r, g, b, a or 1) end
	tex:SetBlendMode(blend or 'BLEND')
end

local function SetVertexColor(state, tex, r, g, b, a)
	if not tex then return end
	local vr, vg, vb, va = tex:GetVertexColor()
	Push(state, function() tex:SetVertexColor(vr, vg, vb, va) end)
	tex:SetVertexColor(r, g, b, a or 1)
end

-- Only for regions that already had an explicit size.
local function SetSize(state, region, width, height)
	if not region then return end
	local w, h = region:GetSize()
	Push(state, function() region:SetSize(w, h) end)
	region:SetSize(width, height)
end

local function SetHeight(state, region, height)
	if not region then return end
	local h = region:GetHeight()
	Push(state, function() region:SetHeight(h) end)
	region:SetHeight(height)
end

-- Saves all anchors, clears them and calls place() to set new ones.
local function SetPoints(state, region, place)
	if not region then return end
	local points = {}
	for i = 1, region:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = region:GetPoint(i)
		points[i] = { point, relativeTo, relativePoint, x, y }
	end
	Push(state, function()
		region:ClearAllPoints()
		for _, p in ipairs(points) do
			region:SetPoint(p[1], p[2] or region:GetParent(), p[3], p[4], p[5])
		end
	end)
	region:ClearAllPoints()
	place(region)
end

-- Saves a BackdropTemplate frame's backdrop and colors for the undo. No
-- AceGUI OnRelease touches backdrops, so restoring the snapshot is safe.
local function SaveBackdrop(state, frame)
	local info = frame.backdropInfo -- the original table (GetBackdrop returns an altered copy)
	local bg = { frame:GetBackdropColor() }
	local border = { frame:GetBackdropBorderColor() }
	Push(state, function()
		frame:SetBackdrop(info)
		if info then
			if bg[1] then frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4]) end
			if border[1] then frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4]) end
		end
	end)
end

-- Swaps a BackdropTemplate frame's backdrop for a flat one in a SaftUI
-- template's colors.
local function FlatBackdrop(state, frame, template)
	if not frame or not frame.SetBackdrop then return end
	SaveBackdrop(state, frame)
	local config = st.config.profile.templates[template]
	frame:SetBackdrop(FLAT_BACKDROP)
	frame:SetBackdropColor(unpack(config.backdropcolor))
	if config.border then
		frame:SetBackdropBorderColor(unpack(config.bordercolor))
	else
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	end
end

local function ClearBackdrop(state, frame)
	if not frame or not frame.SetBackdrop then return end
	SaveBackdrop(state, frame)
	frame:SetBackdrop(nil)
end

-- Wraps a method on one widget instance; the undo puts back exactly what was
-- there (nil when the method came from the widget's metatable). The hooked
-- methods (AddChild, AddChildren, AddItem, RefreshTree) return nothing.
local function HookMethod(state, obj, key, after)
	local orig = obj[key]
	if type(orig) ~= 'function' then return end
	local raw = rawget(obj, key)
	rawset(obj, key, function(...)
		orig(...)
		after(...)
	end)
	Push(state, function() rawset(obj, key, raw) end)
end

--------------------------------------------------------------------------------
-- Objects we create (backdrop boxes). They're made once per AceGUI frame and
-- kept; while scoped they show, on release they hide.
--------------------------------------------------------------------------------

local function Owned(state, host, key, create)
	local bag = owned[host]
	if not bag then
		bag = {}
		owned[host] = bag
	end
	local obj = bag[key]
	if not obj then
		obj = create(host)
		bag[key] = obj
	end
	obj:Show()
	Push(state, function()
		obj:Hide()
		obj:ClearAllPoints()
	end)
	return obj
end

-- A SaftUI backdrop behind host, inset by `inset` (default: fill host).
-- Callers that need other anchors re-anchor it after.
local function Box(state, host, key, template, inset)
	local box = Owned(state, host, key, function(h)
		return st:CreateFrame('Frame', nil, h)
	end)
	box:SetFrameLevel(math.max(0, host:GetFrameLevel() - 1))
	st:SetTemplate(box, template)
	inset = inset or 0
	box:ClearAllPoints()
	box:SetPoint('TOPLEFT', host, 'TOPLEFT', inset, -inset)
	box:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', -inset, inset)
	return box
end

-- Small down arrow on a dropdown box, from SaftUI's atlas.
local function BoxArrow(box)
	if not box.arrow then
		box.arrow = box:CreateTexture(nil, 'OVERLAY')
		box.arrow:SetSize(10, 10)
		box.arrow:SetPoint('RIGHT', box, 'RIGHT', -5, 0)
	end
	st:SetTexture(box.arrow, 'down-arrow')
	box.arrow:SetVertexColor(TextColor())
	box.arrow:Show()
end

--------------------------------------------------------------------------------
-- Shared pieces
--------------------------------------------------------------------------------

-- UIPanelButtonTemplate buttons: hide the art, flat highlight, SaftUI box and font.
local function StyleUIButton(state, button, template)
	if not button then return end
	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	for _, region in ipairs({ button:GetRegions() }) do
		if region ~= highlight and region:IsObjectType('Texture') then
			SetAlpha(state, region, 0)
		end
	end
	if highlight then
		local r, g, b = Blue()
		Retexture(state, highlight, st.BLANK_TEX, r, g, b, 0.25, 'BLEND')
	end
	if button.GetNormalFontObject then
		local normal, hover = button:GetNormalFontObject(), button:GetHighlightFontObject()
		Push(state, function()
			if normal then button:SetNormalFontObject(normal) end
			if hover then button:SetHighlightFontObject(hover) end
		end)
		button:SetNormalFontObject(Font('pixel'))
		button:SetHighlightFontObject(Font('pixel'))
	end
	Box(state, button, 'box', template or 'thick', 2)
end

-- UIPanelScrollBarTemplate sliders: flat thumb, stepper buttons hidden.
local function StyleScrollBar(state, bar)
	if not bar then return end
	local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
	if thumb then
		Retexture(state, thumb, st.BLANK_TEX, 0.3, 0.3, 0.3, 1)
		SetSize(state, thumb, 6, thumb:GetHeight())
	end
	local name = bar:GetName()
	for _, key in ipairs({ 'ScrollUpButton', 'ScrollDownButton' }) do
		SetAlpha(state, bar[key] or (name and _G[name .. key]), 0)
	end
end

local function StyleLabel(state, fs, disabled)
	SetFont(state, fs, Font('pixel'))
	if not disabled then
		SetTextColor(state, fs, TextColor())
	end
end

-- The 25px-high click area at the bottom of Dropdown / LSM30 widgets.
local function DropdownBox(state, frame)
	local box = Box(state, frame, 'box', 'thin')
	box:ClearAllPoints()
	box:SetPoint('TOPLEFT', frame, 'BOTTOMLEFT', 0, 24)
	box:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 2)
	BoxArrow(box)
	return box
end

local function HideButtonArt(state, button)
	if not button then return end
	for _, getter in ipairs({ 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }) do
		if button[getter] then
			SetAlpha(state, button[getter](button), 0)
		end
	end
end

--------------------------------------------------------------------------------
-- Per widget type
--------------------------------------------------------------------------------

local STYLERS = {}

STYLERS['Frame'] = function(state, w)
	local frame = w.frame
	ClearBackdrop(state, frame)
	local box = Box(state, frame, 'box', 'thick', 2)

	-- Header strip at the top, drawn on our box so it sits under the content.
	local headerHeight = 20
	if not box.header then
		box.header = box:CreateTexture(nil, 'ARTWORK')
		box.header:SetTexture(st.BLANK_TEX)
	end
	box.header:ClearAllPoints()
	box.header:SetPoint('TOPLEFT', box, 'TOPLEFT', 2, -2)
	box.header:SetPoint('TOPRIGHT', box, 'TOPRIGHT', -2, -2)
	box.header:SetHeight(headerHeight)
	box.header:SetVertexColor(unpack(st.config.profile.templates.highlight.backdropcolor))

	-- Resize grip, also on our box.
	if not box.grip then
		box.grip = box:CreateTexture(nil, 'ARTWORK')
		box.grip:SetSize(12, 12)
		box.grip:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', -4, 4)
		box.grip:SetTexture(st.textures.cornerbr)
	end
	box.grip:SetVertexColor(0.5, 0.5, 0.5, 1)

	-- Stock title art (titlebg and its two end caps) are the frame's OVERLAY textures.
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:IsObjectType('Texture') and region:GetDrawLayer() == 'OVERLAY' then
			SetAlpha(state, region, 0)
		end
	end
	if w.sizer_se then
		for _, region in ipairs({ w.sizer_se:GetRegions() }) do
			if region:IsObjectType('Texture') then
				SetAlpha(state, region, 0)
			end
		end
	end

	-- Title: the drag area becomes the header strip, the text sits in it.
	if w.titletext then
		local title = w.titletext:GetParent()
		if title and title ~= frame then
			SetPoints(state, title, function(f)
				f:SetPoint('TOPLEFT', box.header, 'TOPLEFT')
				f:SetPoint('BOTTOMRIGHT', box.header, 'BOTTOMRIGHT')
			end)
		end
		SetPoints(state, w.titletext, function(fs)
			fs:SetPoint('CENTER', box.header, 'CENTER', 0, 0)
		end)
		SetFont(state, w.titletext, Font('pixel'))
		SetTextColor(state, w.titletext, TextColor())
	end

	-- Status bar strip at the bottom.
	local statusbg = w.statustext and w.statustext:GetParent()
	if statusbg and statusbg ~= frame then
		FlatBackdrop(state, statusbg, 'thin')
		SetFont(state, w.statustext, Font('pixel'))
	end

	-- The close button is the one other child Button that points back at us.
	for _, child in ipairs({ frame:GetChildren() }) do
		if child ~= statusbg and child.obj == w and child:IsObjectType('Button') then
			StyleUIButton(state, child)
		end
	end
end

STYLERS['TreeGroup'] = function(state, w)
	FlatBackdrop(state, w.treeframe, 'thick')
	FlatBackdrop(state, w.border, 'thick')
	StyleScrollBar(state, w.scrollbar)

	-- Tree buttons are plain frames the TreeGroup makes and re-fonts on every
	-- refresh, so restyle after each one. Each button's originals are saved the
	-- first time we touch it.
	local function StyleButtons(self)
		local r, g, b = Blue()
		for _, button in ipairs(self.buttons or {}) do
			if not state.saved[button] then
				state.saved[button] = true
				local normal, hover = button:GetNormalFontObject(), button:GetHighlightFontObject()
				Push(state, function()
					if normal then button:SetNormalFontObject(normal) end
					if hover then button:SetHighlightFontObject(hover) end
				end)
				Retexture(state, button:GetHighlightTexture(), st.BLANK_TEX, r, g, b, 0.3, 'BLEND')
			end
			button:SetNormalFontObject(Font('pixel'))
			button:SetHighlightFontObject(Font('pixel'))
		end
	end
	HookMethod(state, w, 'RefreshTree', StyleButtons)
	StyleButtons(w)
end

STYLERS['InlineGroup'] = function(state, w)
	FlatBackdrop(state, w.content and w.content:GetParent(), 'thick')
	StyleLabel(state, w.titletext)
end

STYLERS['DropdownGroup'] = function(state, w)
	FlatBackdrop(state, w.border, 'thick')
	StyleLabel(state, w.titletext)
	-- Its dropdown belongs to the group and is never released on its own.
	if w.dropdown then
		Scope(w.dropdown)
		Push(state, function() Unscope(w.dropdown) end)
	end
end

STYLERS['ScrollFrame'] = function(state, w)
	StyleScrollBar(state, w.scrollbar)
end

STYLERS['CheckBox'] = function(state, w)
	local radio = (w.checkbg:GetWidth() or 24) < 20
	local size = radio and 12 or 14
	local r, g, b = Blue()

	SetAlpha(state, w.checkbg, 0)
	local box = Box(state, w.frame, 'box', 'thin')
	box:ClearAllPoints()
	box:SetPoint('CENTER', w.checkbg, 'CENTER')
	box:SetSize(size, size)

	Retexture(state, w.check, st.BLANK_TEX, r, g, b, 1, 'BLEND')
	SetPoints(state, w.check, function(tex)
		tex:SetPoint('TOPLEFT', box, 'TOPLEFT', 3, -3)
		tex:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', -3, 3)
	end)
	Retexture(state, w.highlight, st.BLANK_TEX, 1, 1, 1, 0.15, 'BLEND')
	SetPoints(state, w.highlight, function(tex)
		tex:SetPoint('TOPLEFT', box, 'TOPLEFT', 1, -1)
		tex:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', -1, 1)
	end)

	SetFont(state, w.text, Font('pixel'))
	SetFont(state, w.desc, Font('pixel'))
end

STYLERS['Slider'] = function(state, w)
	local r, g, b = Blue()
	FlatBackdrop(state, w.slider, 'thin')
	local thumb = w.slider:GetThumbTexture()
	if thumb then
		Retexture(state, thumb, st.BLANK_TEX, r, g, b, 1, 'BLEND')
		SetSize(state, thumb, 8, 13)
	end
	FlatBackdrop(state, w.editbox, 'thin')
	SetFont(state, w.editbox, Font('pixel'))
	SetFont(state, w.lowtext, Font('pixel'))
	SetFont(state, w.hightext, Font('pixel'))
	StyleLabel(state, w.label, w.disabled)
end

STYLERS['EditBox'] = function(state, w)
	local editbox = w.editbox
	for _, region in ipairs({ editbox:GetRegions() }) do
		if region:IsObjectType('Texture') then
			SetAlpha(state, region, 0)
		end
	end
	local box = Box(state, editbox, 'box', 'thin')
	box:ClearAllPoints()
	box:SetPoint('TOPLEFT', editbox, 'TOPLEFT', -4, 0)
	box:SetPoint('BOTTOMRIGHT', editbox, 'BOTTOMRIGHT', 0, 0)
	SetFont(state, editbox, Font('pixel'))
	StyleLabel(state, w.label, w.disabled)
	StyleUIButton(state, w.button, 'thin')
end

STYLERS['Button'] = function(state, w)
	StyleUIButton(state, w.frame)
end

STYLERS['Heading'] = function(state, w)
	for _, line in ipairs({ w.left, w.right }) do
		Retexture(state, line, st.BLANK_TEX, 0.3, 0.3, 0.3, 1)
		SetHeight(state, line, 1)
	end
	StyleLabel(state, w.label)
end

STYLERS['Label'] = function(state, w)
	local fs = w.label
	local oldObject = fs:GetFontObject()
	local file, size, flags = fs:GetFont()
	local r, g, b, a = fs:GetTextColor()
	Push(state, function()
		-- font only; the color stays whatever the widget has now
		local cr, cg, cb, ca = fs:GetTextColor()
		RestoreFont(fs, oldObject, file, size, flags)
		fs:SetTextColor(cr, cg, cb, ca)
	end)
	-- Through the widget's own method so it re-measures its height.
	local large = oldObject == GameFontHighlightLarge
	w:SetFontObject(large and Font('pixel_med') or Font('pixel'))
	fs:SetTextColor(r, g, b, a)
end

STYLERS['ColorPicker'] = function(state, w)
	local swatch = w.colorSwatch
	Retexture(state, swatch, st.BLANK_TEX) -- keeps its vertex color: that's the picked color
	SetSize(state, swatch, 12, 12)
	if swatch.background then
		SetVertexColor(state, swatch.background, 0, 0, 0, 1)
		SetSize(state, swatch.background, 14, 14)
	end
	if swatch.checkers then
		SetSize(state, swatch.checkers, 12, 12)
	end
	SetFont(state, w.text, Font('pixel'))
end

STYLERS['Dropdown'] = function(state, w)
	local dropdown = w.dropdown
	local name = dropdown:GetName()
	for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do
		SetAlpha(state, dropdown[part] or (name and _G[name .. part]), 0)
	end
	HideButtonArt(state, w.button)
	DropdownBox(state, w.frame)
	SetFont(state, w.text, Font('pixel'))
	StyleLabel(state, w.label, w.disabled)

	-- The pullout is released by the dropdown's OnRelease, or (for a
	-- DropdownGroup's own dropdown) unscoped along with it here.
	if w.pullout then
		local pullout = w.pullout
		Scope(pullout)
		Push(state, function() Unscope(pullout) end)
	end
end

STYLERS['Dropdown-Pullout'] = function(state, w)
	local r, g, b = Blue()
	FlatBackdrop(state, w.frame, 'thick')
	FlatBackdrop(state, w.slider, 'thin')
	local thumb = w.slider and w.slider:GetThumbTexture()
	if thumb then
		Retexture(state, thumb, st.BLANK_TEX, r, g, b, 1, 'BLEND')
		SetSize(state, thumb, 6, 16)
	end
	for _, item in ipairs(w.items) do
		Scope(item)
	end
	HookMethod(state, w, 'AddItem', function(_, item) Scope(item) end)
	-- Items normally get released (and restored) by the pullout's Clear; this
	-- covers a pullout that is unscoped without being released.
	Push(state, function()
		for _, item in ipairs(w.items) do
			Unscope(item)
		end
	end)
end

local function StyleDropdownItem(state, w)
	local r, g, b = Blue()
	SetFont(state, w.text, Font('pixel'))
	Retexture(state, w.highlight, st.BLANK_TEX, r, g, b, 0.3, 'BLEND')
	if w.check then
		Retexture(state, w.check, st.BLANK_TEX, r, g, b, 1, 'BLEND')
		SetSize(state, w.check, 6, 6)
		SetPoints(state, w.check, function(tex)
			tex:SetPoint('LEFT', w.frame, 'LEFT', 7, 0)
		end)
	end
end

-- LibSharedMedia dropdowns (AceGUI-3.0-SharedMediaWidgets) share one base frame.
-- Their popup list is a separate shared frame and stays stock.
local function StyleLSM30(state, w)
	local frame = w.frame
	for _, key in ipairs({ 'DLeft', 'DMiddle', 'DRight' }) do
		SetAlpha(state, frame[key], 0)
	end
	HideButtonArt(state, frame.dropButton)
	DropdownBox(state, frame)
	StyleLabel(state, frame.label, w.disabled)
end

local function GetStyler(widgetType)
	if not widgetType then return nil end
	if STYLERS[widgetType] then
		return STYLERS[widgetType]
	elseif widgetType:find('^Dropdown%-Item%-') then
		return StyleDropdownItem
	elseif widgetType:find('^LSM30_') then
		return StyleLSM30
	end
end

--------------------------------------------------------------------------------
-- Scoping
--------------------------------------------------------------------------------

function Scope(widget)
	if not widget or states[widget] then return end
	local state = { undo = {}, saved = {} }
	states[widget] = state

	local styler = GetStyler(widget.type)
	if styler then
		local ok, err = pcall(styler, state, widget)
		if not ok then geterrorhandler()(err) end
	end

	-- Containers: everything added later is scoped too, and so is what's already in.
	if widget.children then
		HookMethod(state, widget, 'AddChild', function(_, child) Scope(child) end)
		HookMethod(state, widget, 'AddChildren', function(_, ...)
			for i = 1, select('#', ...) do
				Scope((select(i, ...)))
			end
		end)
		for _, child in ipairs(widget.children) do
			Scope(child)
		end
	end
end

function Unscope(widget)
	local state = widget and states[widget]
	if not state then return end
	states[widget] = nil
	for i = #state.undo, 1, -1 do
		local ok, err = pcall(state.undo[i])
		if not ok then geterrorhandler()(err) end
	end
end

-- Runs after AceGUI:Release. Release can be re-entered while it runs (a Frame's
-- OnHide fires OnClose, which releases it again and returns early); skip those
-- calls and act once the real release is done.
local function OnRelease(_, widget)
	if not widget or widget.isQueuedForRelease then return end
	if states[widget] then
		Unscope(widget)
	end
	local window = windows[widget]
	if window then
		windows[widget] = nil
		if AceConfigDialog.OpenFrames[window.name] == widget then
			AceConfigDialog.OpenFrames[window.name] = nil
		end
		if window.onClose then
			window.onClose(widget)
		end
	end
end

--------------------------------------------------------------------------------
-- Keeping SaftUI's windows in sync. Several windows show the same settings
-- (e.g. the minimap's size and offsets in /sui and in its edit mode window),
-- so a change in one refreshes the others.
--
-- Two triggers, one relay:
--  * NotifyChange on a SaftUI app (drags, nudges, SelectGroup) reaches the
--    registry's ConfigTableChange callback below.
--  * A value changed by the user in a window doesn't call NotifyChange
--    (AceConfigDialog just re-opens that window), so LinkOptions wraps the
--    tables' set/func handlers to relay after they run.
-- The relay calls NotifyChange on every other SaftUI app. Those calls come back
-- through ConfigTableChange while `relaying` is set and are ignored, so windows
-- can't keep refreshing each other; each just gets AceConfigDialog's normal
-- deferred refresh. No AceConfigDialog methods are hooked for this.
--------------------------------------------------------------------------------

local relaying = false
local function Relay(appName)
	if relaying or not apps[appName] then return end
	relaying = true
	for other in pairs(apps) do
		if other ~= appName then
			local ok, err = pcall(AceConfigRegistry.NotifyChange, AceConfigRegistry, other)
			if not ok then geterrorhandler()(err) end
		end
	end
	relaying = false
end

AceConfigRegistry.RegisterCallback(Skin, 'ConfigTableChange', function(_, appName)
	Relay(appName)
end)

local wrapped = setmetatable({}, { __mode = 'k' }) -- our wrapper functions

-- The app is taken from AceConfig's info table (info.appName), so a table
-- shared by two apps relays from whichever window it was changed in.
local function Wrap(fn, appName)
	if wrapped[fn] then return fn end
	local wrapper = function(info, ...)
		local source = type(info) == 'table' and info.appName or appName
		local a, b, c = fn(info, ...)
		Relay(source)
		return a, b, c
	end
	wrapped[wrapper] = true
	return wrapper
end

local function LinkGroup(option, appName, seen)
	if type(option) ~= 'table' or seen[option] then return end
	seen[option] = true
	if type(option.set) == 'function' then option.set = Wrap(option.set, appName) end
	if type(option.func) == 'function' then option.func = Wrap(option.func, appName) end
	if type(option.args) == 'table' then
		for _, child in pairs(option.args) do
			LinkGroup(child, appName, seen)
		end
	end
	if type(option.plugins) == 'table' then
		for _, plugin in pairs(option.plugins) do
			for _, child in pairs(plugin) do
				LinkGroup(child, appName, seen)
			end
		end
	end
end

-- Hooked lazily. Re-checked when an addon loads, but only re-hooked if a newer
-- AceGUI (different minor) replaced Release, so the hook can't stack however
-- other addons hook it.
local hookedMinor
local function EnsureReleaseHook()
	local lib, minor = LibStub('AceGUI-3.0')
	if lib == AceGUI and minor ~= hookedMinor then
		hooksecurefunc(AceGUI, 'Release', OnRelease)
		hookedMinor = minor
	end
end

local loader = CreateFrame('Frame')
loader:RegisterEvent('ADDON_LOADED')
loader:SetScript('OnEvent', function()
	if hookedMinor then EnsureReleaseHook() end
end)

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

function Skin:IsScoped(widget)
	return states[widget] ~= nil
end

-- Returns a SaftUI-styled AceGUI Frame for the AceConfig app `name`, reusing it
-- if it's already open. It's registered as AceConfigDialog's open frame for
-- `name`, so open it with AceConfigDialog:Open(name): that way NotifyChange
-- refreshes it and Escape closes it, like a stock options window.
-- onClose(window) runs after the window is released.
-- `title` shows until the window is opened; AceConfigDialog:Open then sets
-- the options table's `name` as the title.
function Skin:CreateWindow(name, title, onClose)
	EnsureReleaseHook()
	apps[name] = true

	local existing = AceConfigDialog.OpenFrames[name]
	if existing and windows[existing] then
		windows[existing].onClose = onClose
		existing:SetTitle(title)
		return existing
	elseif existing then
		existing:Hide() -- a stock window for this app: AceConfigDialog releases it
	end

	local window = AceGUI:Create('Frame')
	window:SetCallback('OnClose', function(widget) AceGUI:Release(widget) end)
	window:SetTitle(title)
	Scope(window)
	windows[window] = { name = name, onClose = onClose }
	AceConfigDialog.OpenFrames[name] = window
	return window
end

-- Wraps the function set/func handlers in an options table (in place, at every
-- level) so that a change made in appName's window refreshes SaftUI's other
-- windows. Returns the table, for RegisterOptionsTable. Handlers given as
-- method names (handler tables, e.g. AceDBOptions' profiles) aren't wrapped.
function Skin:LinkOptions(appName, options)
	LinkGroup(options, appName, {})
	return options
end

-- The status bar strip at the bottom of a window, for footer content.
function Skin:GetStatusBar(window)
	local statusbg = window.statustext and window.statustext:GetParent()
	if statusbg ~= window.frame then
		return statusbg
	end
end

-- Moves the status text (where AceConfigDialog shows validation errors) to
-- start `left` px into the status bar, clear of footer content. The original
-- anchors are recorded on the first call and restored when the window is released.
function Skin:SetStatusTextInset(window, left)
	local state = states[window]
	local statusbg = self:GetStatusBar(window)
	if not state or not statusbg then return end
	local fs = window.statustext
	local function Place(text)
		text:SetPoint('TOPLEFT', statusbg, 'TOPLEFT', left + 7, -2)
		text:SetPoint('BOTTOMRIGHT', statusbg, 'BOTTOMRIGHT', -7, 2)
	end
	if state.saved[fs] then
		fs:ClearAllPoints()
		Place(fs)
	else
		state.saved[fs] = true
		SetPoints(state, fs, Place)
	end
end
