-- Core's controls under the Blizzard theme. Each draws kind control, which the
-- engine leaves clear under Blizzard, and shows Blizzard's own art itself:
--   - a SaftUI button (Widgets/button.lua) is Blizzard's panel button, its
--     three pieces swapped by its states and its ends 12/22 of its height; a
--     button of Blizzard's panel button template shows its own Left, Middle
--     and Right again;
--   - a check box (Widgets/checkbutton.lua) is the Settings panel's box, sized
--     so its box is SaftUI's 12px; a check button styled 'button' is the
--     panel button, pressed while checked; one styled 'bare' keeps SaftUI's
--     flat textures in every theme;
--   - a radio group's buttons (Widgets/radiogroup.lua) are Blizzard's top
--     tabs, the picked one active;
--   - a scroll bar (Widgets/scrollbar.lua) has its own layers on again, with
--     no thumb backdrop of SaftUI's;
--   - an edit box (skinning.lua, st:SkinEditBox) shows its own border
--     textures, concealed by alpha under Thick, with nothing written onto a
--     box of Blizzard's and no st:Kill.
-- Under Thick each is today's look again.
--
-- Real: Core's helpers, theme.lua and themeart.lua (T.client, on Forever: the
-- controls' art is the same on both clients), and Widgets/checkbutton.lua,
-- radiogroup.lua and scrollbar.lua. Made by hand, for Blizzard templates the
-- stubs lack:
--   - UICheckButtonTemplate, which st:CreateCheckButton makes its buttons
--     from: a check button with its Text;
--   - Blizzard's MinimalScrollBar, as far as st:SkinNewScrollBar uses it;
--   - a button of Blizzard's panel button template (UIPanelButtonTemplate:
--     its Left, Middle and Right) and Blizzard's chat edit box
--     (ChatFrameEditBoxTemplate: its border and focus textures), both locked
--     (misc/fixtures/locked_widget.lua) once SaftUI has what it keeps on them.
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('misc/fixtures/locked_widget.lua')
local text = T.text

local drawn

-- A fresh world on Forever, with the widgets loaded, the draw calls watched
-- and UICheckButtonTemplate stood in for.
local function fresh()
	local st = T.client('forever')
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
	load_saftui('SaftUI-Core/Widgets/scrollbar.lua')
	drawn = T.watch()
	local createFrame = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		local rest, checkTemplate = {}, false
		for templateName in tostring(template or ''):gmatch('[^,%s]+') do
			if templateName == 'UICheckButtonTemplate' then checkTemplate = true else rest[#rest + 1] = templateName end
		end
		local frame = createFrame(frameType, name, parent, #rest > 0 and table.concat(rest, ',') or nil, ...)
		if checkTemplate then
			frame.Text = frame:CreateFontString(name and name .. 'Text', 'ARTWORK')
		end
		return frame
	end
	return st
end

-- SaftUI's theme switched and every drawn frame drawn again, as the Theme tab
-- does it (the profile update's first step).
local function switch(st, name)
	st.config.profile.theme.name = name
	st:RedrawThemed()
end

-- The textures shown on a frame (shown and not see-through), as a list.
local function shown(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 then
			out[#out + 1] = region
		end
	end
	return out
end

-- A texture's texture coordinates as 'left,right,top,bottom'.
local function coords(texture)
	local ulx, uly, llx, lly, urx = texture:GetTexCoord()
	return ('%.5f,%.5f,%.5f,%.5f'):format(ulx, urx, uly, lly)
end

-- Which piece of the panel button a texture is, by its left texture coordinate.
local PIECE_BY_LEFT = { ['0.00000'] = 'Left', ['0.09375'] = 'Middle', ['0.53125'] = 'Right' }

-- The panel button's pieces shown on a button: { Left, Middle, Right,
-- Highlight } (each a texture or nil), and as text, 'Left=Up,Middle=Up,
-- Right=Up' (each piece by the state its file is; '' for none).
local function panel(button)
	local pieces, out = {}, {}
	for _, region in ipairs(shown(button)) do
		local file = region:GetTexture()
		local state = type(file) == 'string' and file:match('^Interface\\Buttons\\UI%-Panel%-Button%-(%a+)$')
		if state == 'Highlight' then
			pieces.Highlight = region
		elseif state then
			local key = PIECE_BY_LEFT[('%.5f'):format((region:GetTexCoord()))] or '?'
			pieces[key] = region
			out[#out + 1] = key .. '=' .. state
		end
	end
	table.sort(out)
	return pieces, table.concat(out, ',')
end

-- The tab art shown on a button: its atlases, sorted and comma-joined.
local function tabs(button)
	local out = {}
	for _, region in ipairs(shown(button)) do
		local atlas = region:GetAtlas()
		if atlas and atlas:find('uiframe', 1, true) then out[#out + 1] = atlas end
	end
	table.sort(out)
	return table.concat(out, ',')
end

-- The Global Constraints' texture coordinates of the panel button's pieces.
local PANEL_COORDS = {
	Left = '0.00000,0.09375,0.00000,0.68750',
	Middle = '0.09375,0.53125,0.00000,0.68750',
	Right = '0.53125,0.62500,0.00000,0.68750',
}

local THICK_EDGE = '0.30,0.30,0.30,1.00'

------------------------------------------------------------------ buttons

test("a SaftUI button: Blizzard's panel button, swapped by its states, and its own look again under Thick", function()
	local st = fresh()
	st.config.profile.theme.name = 'blizzard'
	local button = st:CreateButton('ThemeTestPanelButton', UIParent, 'Go')
	button:SetSize(100, 22)
	button:SetPoint('CENTER')
	stub.fire_script(button, 'OnSizeChanged', 100, 22)
	eq(drawn(button), 'theme,solid,control', "Use SaftUI's theme and Solid, as a control")

	local pieces, states = panel(button)
	eq(states, 'Left=Up,Middle=Up,Right=Up', 'Left, Middle and Right show UI-Panel-Button-Up')
	for key, want in pairs(PANEL_COORDS) do
		eq(pieces[key] and coords(pieces[key]), want, key .. " at the Global Constraints' coordinates")
	end
	eq(pieces.Left and T.around(pieces.Left, button), '0,0,-88,0', 'Left at the left, 12 wide, the full height')
	eq(pieces.Right and T.around(pieces.Right, button), '88,0,0,0', 'Right at the right')
	eq(pieces.Middle and T.around(pieces.Middle, button), '12,0,-12,0', 'Middle between them')
	check(pieces.Highlight ~= nil, "Blizzard's additive highlight")
	eq(pieces.Highlight and pieces.Highlight:GetBlendMode(), 'ADD', 'additive')
	eq(pieces.Highlight and select(1, pieces.Highlight:GetDrawLayer()), 'HIGHLIGHT', 'shown under the mouse')

	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq(select(2, panel(button)), 'Left=Down,Middle=Down,Right=Down', 'a mouse down: -Down')
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	eq(select(2, panel(button)), 'Left=Up,Middle=Up,Right=Up', 'a mouse up: -Up again')
	button:Disable()
	eq(select(2, panel(button)), 'Left=Disabled,Middle=Disabled,Right=Disabled', 'disabled: -Disabled')
	button:Enable()
	eq(select(2, panel(button)), 'Left=Up,Middle=Up,Right=Up', 'enabled: -Up again')

	for _, key in ipairs({ 'hover', 'pushed', 'disabled' }) do
		eq(button[key]:GetAlpha(), 0, 'its flat ' .. key .. ' texture is hidden')
	end
	eq(button.backdrop.backdropInfo, nil, 'the backdrop draws nothing')

	switch(st, 'thick')
	eq(select(2, panel(button)), '', 'under Thick the three are hidden')
	check(not (pieces.Highlight and pieces.Highlight:IsShown()), "and Blizzard's highlight")
	for _, key in ipairs({ 'hover', 'pushed', 'disabled' }) do
		eq(button[key]:GetAlpha(), 1, 'its flat ' .. key .. ' texture shown again')
	end
	eq(T.inset(button.backdrop), 2, "Thick's border")
	eq(T.edge(button.backdrop), THICK_EDGE, "in Thick's color")
	button:Disable()
	eq(select(2, panel(button)), '', 'a disable under Thick shows no panel')
	eq(#take_errors(), 0, 'no errors')
end)

test("a 31-tall button's ends are 17 wide", function()
	local st = fresh()
	local button = st:CreateButton('ThemeTestTallButton', UIParent, 'Go')
	button:SetSize(100, 31)
	button:SetPoint('CENTER')
	switch(st, 'blizzard')
	local pieces = panel(button)
	eq(pieces.Left and pieces.Left:GetWidth(), 17, 'the left end: 12/22 of 31, rounded')
	eq(pieces.Right and pieces.Right:GetWidth(), 17, 'the right end')

	-- A size change follows (the game fires OnSizeChanged; the stubs don't).
	button:SetHeight(22)
	stub.fire_script(button, 'OnSizeChanged', 100, 22)
	eq(pieces.Left and pieces.Left:GetWidth(), 12, "22 tall: Blizzard's 12")

	-- A square button narrower than both ends keeps them to half its width each.
	button:SetSize(16, 16)
	stub.fire_script(button, 'OnSizeChanged', 16, 16)
	eq(pieces.Left and pieces.Left:GetWidth(), 8, 'a 16 square: half its width')
	eq(#take_errors(), 0, 'no errors')
end)

-- A button of Blizzard's panel button template (UIPanelButtonTemplate), as
-- retail's bank deposit button is: its Left, Middle and Right.
local function blizzardPanelButton()
	local button = CreateFrame('Button', 'ThemeTestDepositButton', UIParent)
	button:SetSize(200, 16)
	button:SetPoint('CENTER')
	for key, coord in pairs({ Left = { 0, 0.09375 }, Middle = { 0.09375, 0.53125 }, Right = { 0.53125, 0.625 } }) do
		local texture = button:CreateTexture(nil, 'BACKGROUND')
		texture:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
		texture:SetTexCoord(coord[1], coord[2], 0, 0.6875)
		button[key] = texture
	end
	return button
end

test("a Blizzard panel button given to st:SkinButton shows its own Left, Middle and Right again", function()
	local st = fresh()
	local button = blizzardPanelButton()
	st:SkinButton(button, 'theme', 'solid')
	for _, key in ipairs({ 'Left', 'Middle', 'Right' }) do
		eq(button[key]:GetAlpha(), 0, 'under Thick its ' .. key .. ' is faded, as before')
	end
	-- What st:SkinButton keeps on it is written now; nothing more may be.
	locked(button, 'Blizzard')
	local regions = select('#', button:GetRegions())

	switch(st, 'blizzard')
	for _, key in ipairs({ 'Left', 'Middle', 'Right' }) do
		eq(button[key]:GetAlpha(), 1, 'under Blizzard its own ' .. key .. ' shows again')
	end
	for _, key in ipairs({ 'hover', 'pushed', 'disabled' }) do
		eq(button[key]:GetAlpha(), 0, "SaftUI's flat " .. key .. ' texture is hidden')
	end
	eq(select('#', button:GetRegions()), regions, 'no texture of SaftUI\'s is made on it')

	switch(st, 'thick')
	for _, key in ipairs({ 'Left', 'Middle', 'Right' }) do
		eq(button[key]:GetAlpha(), 0, 'under Thick its ' .. key .. ' is faded again')
	end
	for _, key in ipairs({ 'hover', 'pushed', 'disabled' }) do
		eq(button[key]:GetAlpha(), 1, "SaftUI's flat " .. key .. ' texture shown again')
	end
	eq(#take_errors(), 0, 'nothing written onto it on either switch')
end)

------------------------------------------------------------------ check boxes

test("a check box takes checkbox-minimal, checked checkmark-minimal, and SaftUI's box under Thick", function()
	local st = fresh()
	st.config.profile.theme.name = 'blizzard'
	local box = st:CreateCheckButton('ThemeTestCheckBox', UIParent)
	box:SetPoint('CENTER')
	eq(drawn(box), 'theme,theme,control', "panels' Theme and Background, as a control")
	eq(text(box:GetSize()), '12.00,12.00', "SaftUI's 12px")
	eq(box.backdrop.backdropInfo, nil, 'no backdrop of SaftUI\'s')

	local art
	for _, region in ipairs(shown(box)) do
		if region:GetAtlas() == 'checkbox-minimal' and region ~= box:GetHighlightTexture() then art = region end
	end
	check(art ~= nil, "Blizzard's Settings box: checkbox-minimal")
	-- checkbox-minimal's box is 26 of its 30 wide and 25 of its 29 tall, 2
	-- clear on each side: drawn 1px outside the 12px button, it's 12.
	eq(art and T.around(art, box), '-1,1,1,-1', 'drawn 1px outside, so its box is the 12px button')
	local checked = box:GetCheckedTexture()
	eq(checked:GetAtlas(), 'checkmark-minimal', 'checked: checkmark-minimal')
	eq(T.around(checked, box), '-1,1,1,-1', 'over the box')
	eq(text(checked:GetVertexColor()), '1.00,1.00,1.00,1.00', 'untinted')
	local hover = box:GetHighlightTexture()
	eq(hover:GetAtlas(), 'checkbox-minimal', "the highlight is the box's own art")
	eq(hover:GetBlendMode(), 'ADD', 'additive')

	switch(st, 'thick')
	check(not art:IsShown(), "under Thick Blizzard's box is hidden")
	eq(checked:GetAtlas(), nil, "the check is SaftUI's flat square")
	eq(checked:GetTexture(), st.BLANK_TEX, 'blank')
	eq(T.around(checked, box), '0,0,0,0', 'filling the box')
	eq(text(checked:GetVertexColor()), text(st.config.profile.colors.button.hover:GetRGB()) .. ',1.00', 'in the hover color')
	eq(hover:GetTexture(), st.BLANK_TEX, 'the highlight is flat')
	eq(text(hover:GetVertexColor()), text(st.config.profile.colors.button.normal:GetRGB()) .. ',1.00', 'in the button color')
	eq(T.inset(box.backdrop), 2, "SaftUI's box: Thick's border")
	eq(#take_errors(), 0, 'no errors')
end)

test("a check button styled 'button' is a panel button, pressed while checked", function()
	local st = fresh()
	st.config.profile.theme.name = 'blizzard'
	local toggle = st:CreateCheckButton(nil, UIParent, 'button')
	toggle:SetSize(40, 20)
	toggle:SetPoint('CENTER')
	stub.fire_script(toggle, 'OnSizeChanged', 40, 20)
	eq(drawn(toggle), 'theme,theme,control', 'drawn as a control')
	eq(select(2, panel(toggle)), 'Left=Up,Middle=Up,Right=Up', 'unchecked: the panel button, up')
	eq(toggle:GetCheckedTexture():GetAlpha(), 0, 'its flat check is hidden')
	eq(toggle:GetHighlightTexture():GetAlpha(), 0, 'and its flat highlight')

	toggle:SetChecked(true)
	eq(select(2, panel(toggle)), 'Left=Down,Middle=Down,Right=Down', 'checked: pressed')
	-- A click checks the button in the game's own code, not through
	-- SetChecked; the stub's state stands for it, then the click's scripts run.
	stub.state(toggle).checked = false
	stub.fire_script(toggle, 'PostClick', 'LeftButton', false)
	eq(select(2, panel(toggle)), 'Left=Up,Middle=Up,Right=Up', 'clicked off: up again')
	stub.fire_script(toggle, 'OnMouseDown', 'LeftButton')
	eq(select(2, panel(toggle)), 'Left=Down,Middle=Down,Right=Down', 'pressed under the mouse')
	stub.fire_script(toggle, 'OnMouseUp', 'LeftButton')
	stub.state(toggle).checked = true
	stub.fire_script(toggle, 'PostClick', 'LeftButton', false)
	eq(select(2, panel(toggle)), 'Left=Down,Middle=Down,Right=Down', 'clicked on: pressed while checked')

	switch(st, 'thick')
	eq(select(2, panel(toggle)), '', 'under Thick no panel button')
	eq(toggle:GetCheckedTexture():GetAlpha(), 1, 'its flat check again')
	eq(toggle:GetHighlightTexture():GetAlpha(), 1, 'and its flat highlight')
	eq(T.inset(toggle.backdrop), 2, "Thick's border")
	eq(#take_errors(), 0, 'no errors')
end)

test("a check button styled 'bare' keeps SaftUI's flat textures in every theme, with no backdrop", function()
	local st = fresh()
	st.config.profile.theme.name = 'blizzard'
	local bare = st:CreateCheckButton(nil, UIParent, 'bare')
	eq(drawn(bare), nil, 'nothing drawn')
	eq(bare.backdrop, nil, 'no backdrop')
	local checked = bare:GetCheckedTexture()
	eq(checked:GetTexture(), st.BLANK_TEX, "under Blizzard the check is SaftUI's flat square")
	eq(checked:GetAlpha(), 1, 'shown')
	-- Its caller restyles it (the bags' currency overlay, the bank's eye).
	checked:SetVertexColor(0, 0, 0, 0.6)
	switch(st, 'thick')
	switch(st, 'blizzard')
	eq(text(checked:GetVertexColor()), '0.00,0.00,0.00,0.60', "its caller's color survives a switch")
	eq(select(2, panel(bare)), '', 'no panel button')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ radio groups

test("a radio group shows Blizzard's tabs, the picked one active", function()
	local st = fresh()
	st.config.profile.theme.name = 'blizzard'
	local group = st:CreateRadioGroup('ThemeTestTabs', UIParent, {
		buttonHeight = 30, buttonWidth = 140, buttonSpacing = 6, theme = 'theme', background = 'theme',
		items = { { label = 'Bank' }, { label = 'Warband' } },
	})
	group:SetPoint('CENTER')
	local first, second = group.buttons[1], group.buttons[2]
	local OTHER = '_uiframe-tab-center,uiframe-tab-left,uiframe-tab-right'
	local PICKED = '_uiframe-activetab-center,uiframe-activetab-left,uiframe-activetab-right'
	eq(drawn(first), 'theme,theme,control', 'its buttons draw as controls')
	eq(tabs(first), OTHER, 'before a pick, every button is a tab')
	eq(select(2, panel(first)), '', 'not a panel button')

	stub.fire_script(second, 'OnClick', 'LeftButton', false)
	eq(tabs(second), PICKED, 'the picked one is the active tab')
	eq(tabs(first), OTHER, 'the other one a tab')
	-- Each end as wide as its art, its last quarter cut off, at the 30
	-- height: uiframe-activetab-left is 35x42 and -right 37x42, uiframe-tab-left
	-- 35x36 and -right 37x36.
	local function ends(button)
		local widths = {}
		for _, region in ipairs(shown(button)) do
			local atlas = region:GetAtlas() or ''
			if atlas:find('%-left$') then widths[1] = region:GetWidth() end
			if atlas:find('%-right$') then widths[2] = region:GetWidth() end
		end
		return ('%s,%s'):format(tostring(widths[1]), tostring(widths[2]))
	end
	eq(ends(second), '33,35', 'the picked tab: 35 and 37 wide at 42 * 0.75, drawn 30 tall')
	eq(ends(first), '39,41', 'the other: 35 and 37 wide at 36 * 0.75, drawn 30 tall')
	eq(second.backdrop.backdropInfo, nil, 'no blue border: no backdrop of SaftUI\'s')
	stub.fire_script(first, 'OnClick', 'LeftButton', false)
	eq(tabs(first), PICKED, 'a new pick is active')
	eq(tabs(second), OTHER, 'the old one a tab again')

	switch(st, 'thick')
	eq(tabs(first), '', 'under Thick no tabs')
	eq(tabs(second), '', 'on either')
	eq(T.edge(first.backdrop), text(st.config.profile.colors.button.blue:GetRGB()) .. ',1.00', "SaftUI's blue border on the picked one")
	eq(T.edge(second.backdrop), THICK_EDGE, "the theme's on the other")
	eq(first.hover:GetAlpha(), 1, "SaftUI's flat highlight again")
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ scroll bars

-- Blizzard's MinimalScrollBar, as far as st:SkinNewScrollBar uses it: its
-- thumb, track and steppers (frames of its own in game too). In game it also
-- scrolls, sizes the thumb and steps; nothing here needs that.
local function scrollBar()
	local bar = CreateFrame('Frame', nil, UIParent)
	local parts = {}
	for _, key in ipairs({ 'thumb', 'track', 'forward', 'back' }) do
		parts[key] = CreateFrame('Button', nil, bar)
		parts[key]:SetSize(8, 20)
		parts[key]:SetPoint('CENTER')
	end
	function bar:GetThumb() return parts.thumb end
	function bar:GetTrack() return parts.track end
	function bar:GetForwardStepper() return parts.forward end
	function bar:GetBackStepper() return parts.back end
	return bar, parts
end

-- The layers st:SkinNewScrollBar turns off under Thick and Thin: the thumb's
-- art, the track's and the steppers'.
local LAYERS = {
	{ 'thumb', 'BACKGROUND' }, { 'thumb', 'ARTWORK' }, { 'track', 'ARTWORK' },
	{ 'forward', 'BACKGROUND' }, { 'back', 'BACKGROUND' },
}

test("a scroll bar's layers come back on under Blizzard and go off under Thick", function()
	local st = fresh()
	local bar, parts = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = parts.thumb
	eq(drawn(thumb), 'theme,solid,control', 'the thumb draws as a control')
	for _, layer in ipairs(LAYERS) do
		eq(parts[layer[1]]:IsDrawLayerEnabled(layer[2]), false, 'Thick: ' .. layer[1] .. ' ' .. layer[2] .. ' off, as before')
	end

	switch(st, 'blizzard')
	for _, layer in ipairs(LAYERS) do
		eq(parts[layer[1]]:IsDrawLayerEnabled(layer[2]), true, 'Blizzard: ' .. layer[1] .. ' ' .. layer[2] .. ' on')
	end
	eq(thumb.backdrop.backdropInfo, nil, 'no thumb backdrop of SaftUI\'s')
	stub.fire_script(thumb, 'OnEnter')
	stub.fire_script(thumb, 'OnMouseDown')
	eq(thumb.backdrop.backdropInfo, nil, 'and no thumb colors under the mouse or pressed')
	stub.fire_script(thumb, 'OnMouseUp')
	stub.fire_script(thumb, 'OnLeave')

	switch(st, 'thick')
	for _, layer in ipairs(LAYERS) do
		eq(parts[layer[1]]:IsDrawLayerEnabled(layer[2]), false, 'Thick again: ' .. layer[1] .. ' ' .. layer[2] .. ' off')
	end
	eq(T.inset(thumb.backdrop), 2, "SaftUI's thumb back, in Thick's border")
	local r, g, b = thumb.backdrop:GetBackdropColor()
	eq(text(r, g, b), text(st.config.profile.colors.button.normal:GetRGB()), 'in the button color')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ edit boxes

-- Blizzard's chat edit box (ChatFrameEditBoxTemplate), as far as
-- st:SkinEditBox reads it: its text (its first region), its border textures
-- ($parentLeft, $parentRight and $parentMid) and its focus textures
-- (focusLeft, focusRight and focusMid). Locked: nothing may be written onto it.
local function chatEditBox()
	local name = 'ThemeTestChatEditBox'
	local box = CreateFrame('EditBox', name, UIParent)
	box:SetSize(200, 20)
	box:SetPoint('CENTER')
	box:CreateFontString(nil, 'OVERLAY')
	local borders = {}
	for _, key in ipairs({ 'Left', 'Right', 'Mid' }) do
		borders[key] = box:CreateTexture(name .. key, 'BACKGROUND')
	end
	for _, key in ipairs({ 'focusLeft', 'focusRight', 'focusMid' }) do
		borders[key] = box:CreateTexture(nil, 'BORDER')
		box[key] = borders[key]
	end
	return locked(box, 'Blizzard'), borders
end

test("an edit box's border textures show under Blizzard and hide under Thick", function()
	local st = fresh()
	local box, borders = chatEditBox()
	local kills, kill = 0, st.Kill
	st.Kill = function(...) kills = kills + 1; return kill(...) end
	st:SkinEditBox(box, 'theme', 'theme')
	st.Kill = kill
	eq(kills, 0, 'st:Kill is never called')
	eq(drawn(box), 'theme,theme,control', 'drawn as a control')
	for key, texture in pairs(borders) do
		eq(texture:GetAlpha(), 0, 'Thick: ' .. key .. ' concealed by alpha')
		check(texture:IsShown(), 'Thick: ' .. key .. ' still shown, so Blizzard keeps its own say')
	end
	local backdrop = st:DrawnFrame(box)
	check(backdrop ~= nil and backdrop ~= box, 'a backdrop of SaftUI\'s behind it')
	eq(backdrop and T.inset(backdrop), 2, "in Thick's border")
	box:SetFocus()
	eq(backdrop and T.edge(backdrop), '1.00,1.00,1.00,1.00', 'white while focused')
	box:ClearFocus()

	switch(st, 'blizzard')
	for key, texture in pairs(borders) do
		eq(texture:GetAlpha(), 1, 'Blizzard: ' .. key .. ' shows')
	end
	eq(backdrop.backdropInfo, nil, 'no backdrop of SaftUI\'s')
	box:SetFocus()
	eq(backdrop.backdropInfo, nil, 'and no white focus border')
	box:ClearFocus()
	eq(backdrop.backdropInfo, nil, 'nor after losing focus')

	switch(st, 'thick')
	for key, texture in pairs(borders) do
		eq(texture:GetAlpha(), 0, 'Thick again: ' .. key .. ' concealed')
	end
	eq(T.inset(backdrop), 2, "SaftUI's backdrop again")
	eq(#take_errors(), 0, 'nothing written onto the box')
end)

test('st:StyleEditBox draws a box st:SkinEditBox never skinned, as before', function()
	local st = fresh()
	local box = CreateFrame('EditBox', 'ThemeTestUnskinnedEditBox', UIParent)
	box:SetSize(200, 20)
	box:SetPoint('CENTER')
	box:CreateFontString(nil, 'OVERLAY')
	st:StyleEditBox(box, 'theme', 'theme')
	eq(drawn(box), 'theme,theme,control', 'drawn as a control')
	eq(T.inset(st:DrawnFrame(box)), 2, "in Thick's border")
	switch(st, 'blizzard')
	switch(st, 'thick')
	eq(#take_errors(), 0, 'no error: it has no border textures to show or hide')
end)
