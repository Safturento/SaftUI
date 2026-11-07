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

local Skin = {}
st.AceSkin = Skin

local states = {}   -- scoped widget -> { undo = { fn, ... }, saved = {} }
local windows = {}  -- window widget -> { name, onClose }
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

-- FontStrings and EditBoxes. The text color is kept, since SetFontObject would
-- otherwise replace a color the widget set (e.g. greyed out when disabled).
local function SetFont(state, fs, font)
	if not fs or not font then return end
	local oldObject = fs:GetFontObject()
	local file, size, flags = fs:GetFont()
	local r, g, b, a = fs:GetTextColor()
	Push(state, function()
		if oldObject then
			fs:SetFontObject(oldObject)
		elseif file then
			fs:SetFont(file, size, flags)
		end
		fs:SetTextColor(r, g, b, a)
	end)
	fs:SetFontObject(font)
	fs:SetTextColor(r, g, b, a)
end

local function SetTextColor(state, fs, r, g, b, a)
	if not fs then return end
	local or_, og, ob, oa = fs:GetTextColor()
	Push(state, function() fs:SetTextColor(or_, og, ob, oa) end)
	fs:SetTextColor(r, g, b, a or 1)
end

-- Replaces a texture's image. r == nil keeps its vertex color (it is still
-- restored, in case it changes while scoped).
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
		tex:SetVertexColor(vr, vg, vb, va)
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

-- Swaps a BackdropTemplate frame's backdrop for a flat one in a SaftUI
-- template's colors.
local function FlatBackdrop(state, frame, template)
	if not frame or not frame.SetBackdrop then return end
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
	local r, g, b, a = fs:GetTextColor()
	Push(state, function()
		if oldObject then fs:SetFontObject(oldObject) end
		fs:SetTextColor(r, g, b, a)
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

-- Hooked lazily, and again if a newer AceGUI loaded later replaced Release.
local hookedRelease
local function EnsureReleaseHook()
	if AceGUI.Release ~= hookedRelease then
		hooksecurefunc(AceGUI, 'Release', OnRelease)
		hookedRelease = AceGUI.Release
	end
end

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
function Skin:CreateWindow(name, title, onClose)
	EnsureReleaseHook()

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

-- The status bar strip at the bottom of a window, for footer content.
function Skin:GetStatusBar(window)
	local statusbg = window.statustext and window.statustext:GetParent()
	if statusbg ~= window.frame then
		return statusbg
	end
end
