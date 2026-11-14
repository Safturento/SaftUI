--[[
	Blizzard's color picker (Blizzard_ColorPickerFrame), as far as SaftUI's skin
	(SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua) reads and styles it.
	Load it with `local CP = load_test_file('misc/fixtures/color_picker.lua')`,
	then CP.build() makes what the game makes when the addon loads (CP.widgets is every
	frame and region of Blizzard's it made, before any skin adds its own). Every field
	below is one Blizzard really has; checked 2026-11-13 against the forever
	(Mainline/ColorPickerFrame.xml and .lua) and live (Mainline/...) branches of
	Gethe/wow-ui-source, which agree on all of it but Forever's extra gamepad
	frames:

	  - ColorPickerFrame (ColorPickerFrame.xml): 388 by 210, DIALOG strata, hidden,
	    centered, movable, clamped, with the parentKeys
	      .Border      DialogBorderTemplate (a NineSlice frame; its .Bg texture),
	      .Header      DialogHeaderTemplate: .LeftBG, .RightBG, .CenterBG (the
	                   metal) and .Text (GameFontNormal),
	      .DragBar,
	      .Content     with the textures .AlphaBackground, .ColorSwatchCurrent and
	                   .ColorSwatchOriginal, the ColorSelect .ColorPicker (.Wheel,
	                   .Value, .Alpha ... here a frame with its .Wheel, as the
	                   skin never looks at it), and .HexBox (an EditBox of
	                   InputBoxInstructionsTemplate: the border textures .Left,
	                   .Middle and .Right of InputBoxVisualTemplate, the font
	                   string .Instructions, and its own .Hash, "#"),
	      .Footer      with .CancelButton and .OkayButton, both
	                   UIPanelButtonTemplate: the textures .Left, .Middle and
	                   .Right, a highlight texture, the text, and the state fonts
	                   GameFontNormalOutline, GameFontHighlightOutline and
	                   GameFontDisable (UIPanelButtonNoTooltipTemplate),
	      .FrameGlow   (Forever only: FrameGlowTemplate, hidden, level 505).
	  - ColorPickerFrameMixin: OnShow sets the frame's width to 388 with the alpha
	    slider (hasOpacity) and 331 without (the wheel to 255 or 200 wide), and
	    :SetupColorPickerAndShow(info) keeps the caller's functions in swatchFunc,
	    opacityFunc, cancelFunc, hasOpacity, opacity, previousValues, extraInfo
	    and swatch, which other addons read.
	  - The Okay and Cancel buttons' OnClick is Blizzard's (SetScript in OnLoad).

	CP.build{ omit = { 'Border', ... } } leaves out named parts (a client that
	lacks one); the names are the parentKeys, 'HexBox.Hash' for a part of one.
	Every frame and region is locked once built (lib/locked_widget.lua), so a skin
	that writes a field onto one, or SetScripts one, fails. CP.keys(widget) lists
	the fields Blizzard's tables have, for comparing before and after. The
	frame's methods Blizzard's code calls (OnShow, SetupColorPickerAndShow) record
	a call from SaftUI's code, outside CP.show, in CP.stray: the skin must never
	run them (.agents/taint.md rule 3).
]]

local lock_widget = load_test_file('lib/locked_widget.lua')
local OWNER = 'Blizzard color picker'

local CP = {}
CP.stray = {}

-- The named fonts the templates use; the stubs have only some.
for _, name in ipairs({ 'GameFontNormal', 'GameFontNormalLarge', 'GameFontDisableSmall', 'GameFontHighlightSmall',
		'GameFontNormalOutline', 'GameFontHighlightOutline', 'GameFontDisable' }) do
	if not _G[name] then
		local font = CreateFont(name)
		font:SetFont([[Fonts\FRIZQT__.TTF]], 12, '')
	end
end

local driving = 0

-- Blizzard's own entry points, for CP.show: a call outside them is SaftUI's.
local function guard(name, fn)
	return function(...)
		if driving == 0 then CP.stray[#CP.stray + 1] = name end
		return fn(...)
	end
end

local omitted

local function wanted(path) return not omitted[path] end

local function texture(parent, key, layer, path)
	if not wanted(path) then return end
	local t = parent:CreateTexture(nil, layer)
	rawset(parent, key, t)
	return t
end

local function child(parent, key, kind, path, name)
	if not wanted(path) then return end
	local f = CreateFrame(kind, nil, parent)
	rawset(parent, key, f)
	return f
end

local function lock_tree(frame)
	for _, region in ipairs({ frame:GetRegions() }) do lock_widget(region, OWNER) end
	for _, kid in ipairs({ frame:GetChildren() }) do lock_tree(kid) end
	lock_widget(frame, OWNER)
end

-- A UIPanelButtonTemplate button: Left, Middle, Right, the highlight texture
-- (HighlightTexture inherits UIPanelButtonHighlightTexture), the text and the
-- three state fonts.
local function panel_button(footer, key, label)
	local path = 'Footer.' .. key
	local button = child(footer, key, 'Button', path)
	if not button then return end
	button:SetSize(154, 22)
	for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do
		texture(button, part, 'BACKGROUND', path .. '.' .. part)
	end
	button:SetHighlightTexture([[Interface\Buttons\UI-Panel-Button-Highlight]])
	button:SetNormalFontObject(GameFontNormalOutline)
	button:SetHighlightFontObject(GameFontHighlightOutline)
	button:SetDisabledFontObject(GameFontDisable)
	return button
end

function CP.build(opts)
	opts = opts or {}
	omitted = {}
	for _, path in ipairs(opts.omit or {}) do omitted[path] = true end

	local frame = CreateFrame('Frame', 'ColorPickerFrame', UIParent)
	frame:SetSize(388, 210)
	frame:SetFrameStrata('DIALOG')
	frame:SetPoint('CENTER')
	frame:Hide()

	local border = child(frame, 'Border', 'Frame', 'Border')
	if border then
		border:SetAllPoints()
		texture(border, 'Bg', 'BACKGROUND', 'Border.Bg')
	end

	local header = child(frame, 'Header', 'Frame', 'Header')
	if header then
		header:SetSize(200, 39)
		header:SetPoint('TOP', 0, 11)
		for _, part in ipairs({ 'LeftBG', 'RightBG', 'CenterBG' }) do
			texture(header, part, 'ARTWORK', 'Header.' .. part)
		end
		if wanted('Header.Text') then
			local text = header:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
			text:SetPoint('TOP', 0, -13)
			text:SetText('Color Picker')
			rawset(header, 'Text', text)
		end
	end

	child(frame, 'DragBar', 'Frame', 'DragBar')

	local content = child(frame, 'Content', 'Frame', 'Content')
	if content then
		content:SetAllPoints()
		texture(content, 'AlphaBackground', 'ARTWORK', 'Content.AlphaBackground')
		texture(content, 'ColorSwatchCurrent', 'ARTWORK', 'Content.ColorSwatchCurrent')
		texture(content, 'ColorSwatchOriginal', 'ARTWORK', 'Content.ColorSwatchOriginal')
		local wheel = child(content, 'ColorPicker', 'Frame', 'Content.ColorPicker')
		if wheel then
			wheel:SetSize(255, 142)
			wheel:SetPoint('TOPLEFT', 23, -30)
			texture(wheel, 'Wheel', 'ARTWORK', 'Content.ColorPicker.Wheel')
		end
		local box = child(content, 'HexBox', 'EditBox', 'Content.HexBox')
		if box then
			box:SetSize(73, 22)
			box:SetPoint('BOTTOMRIGHT', -23, 44)
			box:SetFontObject(GameFontHighlightSmall)
			for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do
				texture(box, part, 'BACKGROUND', 'Content.HexBox.' .. part)
			end
			if wanted('Content.HexBox.Instructions') then
				local instructions = box:CreateFontString(nil, 'ARTWORK', 'GameFontDisableSmall')
				instructions:SetPoint('TOPLEFT', 16, 0)
				instructions:SetPoint('BOTTOMRIGHT', -20, 0)
				rawset(box, 'Instructions', instructions)
			end
			if wanted('Content.HexBox.Hash') then
				local hash = box:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
				hash:SetPoint('LEFT')
				hash:SetText('#')
				rawset(box, 'Hash', hash)
			end
		end
	end

	local footer = child(frame, 'Footer', 'Frame', 'Footer')
	if footer then
		footer:SetSize(331, 25)
		footer:SetPoint('BOTTOM', 0, 12)
		local cancel = panel_button(footer, 'CancelButton')
		if cancel then cancel:SetPoint('BOTTOMRIGHT', -11.5, 0) end
		local okay = panel_button(footer, 'OkayButton')
		if okay then
			if cancel then okay:SetPoint('RIGHT', cancel, 'LEFT') else okay:SetPoint('BOTTOMRIGHT', -165.5, 0) end
		end
	end

	local glow = child(frame, 'FrameGlow', 'Frame', 'FrameGlow')
	if glow then glow:Hide() end

	-- ColorPickerFrameMixin: what other addons call and read.
	rawset(frame, 'OnShow', guard('OnShow', function(self)
		local width = self.hasOpacity and 388 or 331
		self:SetWidth(width)
	end))
	rawset(frame, 'SetupColorPickerAndShow', guard('SetupColorPickerAndShow', function(self, info)
		-- Blizzard's own writes, which the lock would refuse from anyone else.
		rawset(self, 'swatchFunc', info.swatchFunc)
		rawset(self, 'hasOpacity', info.hasOpacity)
		rawset(self, 'opacityFunc', info.opacityFunc)
		rawset(self, 'opacity', info.opacity)
		rawset(self, 'previousValues', { r = info.r, g = info.g, b = info.b, a = info.opacity })
		rawset(self, 'cancelFunc', info.cancelFunc)
		rawset(self, 'extraInfo', info.extraInfo)
		rawset(self, 'swatch', info.swatch)
		self:Show()
		self:OnShow()
	end))

	-- Blizzard's own OnClick on the buttons (set in OnLoad, before any skin).
	if footer then
		for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
			local button = footer[key]
			if button then
				CP[key] = { clicks = 0 }
				button:SetScript('OnClick', function() CP[key].clicks = CP[key].clicks + 1 end)
			end
		end
	end

	-- Every frame and region of Blizzard's, before any skin adds its own.
	local list = {}
	local function walk(f)
		list[#list + 1] = f
		for _, region in ipairs({ f:GetRegions() }) do list[#list + 1] = region end
		for _, kid in ipairs({ f:GetChildren() }) do walk(kid) end
	end
	walk(frame)
	CP.widgets = list

	lock_tree(frame)
	CP.frame = frame
	return frame
end

-- Opens the picker the way an addon does (Blizzard's SetupColorPickerAndShow).
function CP.show(info)
	driving = driving + 1
	local ok, err = pcall(CP.frame.SetupColorPickerAndShow, CP.frame, info or {
		r = 1, g = 0.5, b = 0.25, hasOpacity = false,
		swatchFunc = function() end, cancelFunc = function() end,
	})
	driving = driving - 1
	if not ok then error(err, 2) end
end

-- The fields a Blizzard table has now, as a sorted 'key,key' text.
function CP.keys(widget)
	local out = {}
	for key in pairs(widget) do out[#out + 1] = tostring(key) end
	table.sort(out)
	return table.concat(out, ',')
end


return CP
