-- Core's widgets and skinners draw their interaction states through the helpers
-- (Widgets/states.lua): st:CreateButton and st:SkinButton ('box'), st:SkinCheckButton
-- ('check', 'button' style 'box', 'bare' a layer only), st:SkinNewScrollBar ('thumb'),
-- st:CreateRadioGroup (the pick is selected), st:SkinActionButton ('icon', game
-- pieces), st:SkinEditBox (focus on its backdrop) and st:EnableResizing ('glyph').
-- Real: Core's helpers, the theme engine and the Blizzard look, the live colors.
-- The mouse is played by firing scripts (OnEnter with `true`, as the game passes
-- motion). A fresh world with Core's real config (the Theme tab's switch runs
-- Config:UpdateConfig), the widgets loaded, the profile filled from the defaults.
local st, ST
local function world()
	reset_world()
	load_test_file('core/config_helpers.lua')
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
	load_saftui('SaftUI-Core/Widgets/scrollbar.lua')
	st = SaftUI
	ST = st.States
end
world()
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')

local ACCENT = '00adf0'
local PLUS, MINUS = '5cc6ff', '0093cd' -- T+ and T- of the default Accent at the defaults

local function fire(frame, script, ...) stub.fire_script(frame, script, ...) end

-- Each byte within 1 (the shipped Accent is (0, 0.68, 0.94), not #00adf0 to the byte).
local function near_hex(label, t, want)
	check(SL.near(t, want), label .. ': ' .. SL.bytes(t) .. ' ~ ' .. want)
end

local function bytes_of(r, g, b) return { r = r, g = g, b = b } end

local function edge_accent()
	local c = st:Color('accent')
	return T.text(c.r, c.g, c.b, 1)
end

local function button(text)
	local b = st:CreateButton(nil, UIParent, text or 'Okay')
	b:SetSize(100, 24)
	return b
end

local function checkbox(style)
	local c = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(c, style)
	return c
end

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
	return bar
end

local function slot(kind)
	local b = CreateFrame('Button', nil, UIParent)
	b:SetSize(36, 36)
	local icon = b:CreateTexture(nil, 'BACKGROUND')
	icon:SetAllPoints(b)
	b.icon = icon
	st:SkinActionButton(b, nil, kind or 'slot')
	return b
end

local function resizable()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame.SetResizable = function() end
	return frame
end

------------------------------------------------------------------ buttons

-- Recorded from the code before this task (Thick, the shipped Accent and colors):
-- the backdrop, its border, and the label's own color.
local REST_FILL, REST_EDGE, REST_TEXT = '0.12,0.12,0.12,1.00', '0.30,0.30,0.30,1.00', '1.00,1.00,1.00,1.00'

test('a skinned button at rest is drawn as before', function()
	world()
	local drawn = T.watch()
	local b = button()
	eq(drawn(b), 'theme,solid,control')
	eq(T.fill(b.backdrop), REST_FILL); eq(T.edge(b.backdrop), REST_EDGE)
	eq(T.text(b.text:GetTextColor()), REST_TEXT, "the label's color unchanged")
	local look = st:StateLook(b)
	eq(look.shape, 'box')
	check(not look.layer.shown and not look.fill.shown, 'no state piece shows at rest')
	eq(b:GetHighlightTexture(), nil, 'no game highlight over the label')
	eq(b:GetPushedTexture(), nil, 'no game pushed texture')
	eq(b:GetDisabledTexture(), nil, 'no disabled texture')
	eq(b.hover, nil); eq(b.pushed, nil); eq(b.disabled, nil)
end)

test('a skinned button: hover and pushed tint its body under the label; disabled dims it', function()
	world()
	local b = button()
	fire(b, 'OnEnter', true)
	local look = st:StateLook(b)
	check(look.layer.shown, 'the layer shows')
	near_hex('hover is T+', look.layer, PLUS)
	eq(look.layer.a, 0.16); eq(look.layer.layer, 'ARTWORK'); eq(look.layer.sublevel, -8); eq(look.layer.blend, 'BLEND')
	eq(b.text:GetDrawLayer(), 'OVERLAY', 'the label is drawn over it')
	eq(b:GetHighlightTexture(), nil, 'no game highlight over the label')
	local n = st:Color('text', 'normal')
	eq(T.rgb(b.text:GetTextColor()), T.rgb(n.r, n.g, n.b), 'a light label on the tinted body')
	eq(T.edge(b.backdrop), REST_EDGE, 'the edge is unchanged by hover')
	fire(b, 'OnMouseDown', 'LeftButton')
	look = st:StateLook(b)
	near_hex('pushed is T-', look.layer, MINUS); eq(look.layer.a, 0.32)
	fire(b, 'OnMouseUp', 'LeftButton'); fire(b, 'OnLeave', true)
	check(not st:StateLook(b).layer.shown, 'at rest again')
	eq(T.text(b.text:GetTextColor()), REST_TEXT, 'the label is back to the color it had at rest (the font object\'s white), not Text > Normal')
	b:Disable()
	eq(b:GetAlpha(), 0.4, 'disabled dims')
	eq(st:GetState(b, 'disabled'), true)
	fire(b, 'OnEnter', true)
	eq(st:GetState(b, 'hover'), false, 'a disabled button takes no hover')
	b:Enable()
	eq(b:GetAlpha(), 1, 'enabled again'); eq(st:GetState(b, 'disabled'), false)
	b:SetEnabled(false)
	eq(b:GetAlpha(), 0.4, 'SetEnabled(false) dims too')
	b:SetEnabled(true)
	eq(b:GetAlpha(), 1)
	-- the Disabled opacity is the setting's
	local saved = st.config.profile.theme.states.disabled
	st.config.profile.theme.states.disabled = 0.2
	ST.Changed()
	b:Disable()
	eq(b:GetAlpha(), 0.2, "Alpha d is the setting's")
	b:Enable()
	st.config.profile.theme.states.disabled = saved
	ST.Changed()
end)

test('a button skinned while disabled starts disabled', function()
	world()
	local b = CreateFrame('Button', nil, UIParent)
	b:SetSize(80, 20)
	b:Disable()
	st:SkinButton(b)
	eq(st:GetState(b, 'disabled'), true)
	eq(b:GetAlpha(), 0.4)
end)

test("a skinned button selected: the theme's edge in the accent and the fade; st:SetButtonPressed sets it", function()
	world()
	local b = button()
	st:SetButtonPressed(b, true)
	eq(st:GetState(b, 'selected'), true)
	eq(T.edge(b.backdrop), edge_accent(), 'the edge is the accent')
	local look = st:StateLook(b)
	check(look.fill.shown, 'the fill shows'); near_hex('the fill', look.fill, ACCENT); eq(look.fill.a, 0.24)
	check(look.fill.right > 1.4 and look.fill.right < 1.5, 'it fades: ' .. look.fill.right)
	st:SetButtonPressed(b, false)
	eq(T.edge(b.backdrop), REST_EDGE, 'the rest edge is back'); check(not st:StateLook(b).fill.shown, 'the fill is gone')
end)

test("a Blizzard panel button st:SkinButton skins keeps the game's disabled art and alpha", function()
	world()
	local b = CreateFrame('Button', nil, UIParent)
	b.Left, b.Middle, b.Right = b:CreateTexture(), b:CreateTexture(), b:CreateTexture()
	b:SetSize(100, 22)
	st:SkinButton(b)
	T.theme('blizzard')
	b:Disable()
	eq(b:GetAlpha(), 1, 'its alpha stays')
	eq(st:GetState(b, 'disabled'), false, 'no disabled state')
	b:Enable()
	-- the states are there for hover
	fire(b, 'OnEnter', true)
	eq(st:GetState(b, 'hover'), true)
end)

test("a module's SetScript on a skinned button keeps hover (a button, a check box, the funnel style)", function()
	world()
	local b = button()
	b:SetScript('OnEnter', function() end)
	b:SetScript('OnLeave', function() end)
	b:SetScript('OnMouseDown', function() end)
	fire(b, 'OnEnter', true)
	eq(st:GetState(b, 'hover'), true, 'a button: hover right after the SetScript, no redraw between')
	fire(b, 'OnMouseDown', 'LeftButton')
	eq(st:GetState(b, 'pushed'), true)
	fire(b, 'OnLeave', true)
	eq(st:GetState(b, 'hover'), false)
	for _, style in ipairs({ false, 'button', 'bare' }) do
		local c = checkbox(style or nil)
		c:SetScript('OnEnter', function() end)
		c:SetScript('OnLeave', function() end)
		fire(c, 'OnEnter', true)
		eq(st:GetState(c, 'hover'), true, 'a check box (' .. tostring(style) .. ')')
		fire(c, 'OnLeave', true)
		eq(st:GetState(c, 'hover'), false)
	end
	-- once per set: a second SetScript does not stack hooks
	local sets = 0
	local real = st.SetState
	st.SetState = function(...) sets = sets + 1 return real(...) end
	for _ = 1, 10 do b:SetScript('OnEnter', function() end) end
	fire(b, 'OnEnter', true)
	st.SetState = real
	eq(sets, 1, 'one hover set after ten SetScripts')
	-- a script that is not a state script is left alone
	b:SetScript('OnClick', function() end)
	-- never on a Blizzard panel button (skin.own): no SetScript hook there
	local own = CreateFrame('Button', nil, UIParent)
	own.Left, own.Middle, own.Right = own:CreateTexture(), own:CreateTexture(), own:CreateTexture()
	own:SetSize(100, 22)
	st:SkinButton(own)
	check(rawget(own, 'SetScript') == nil, 'no SetScript hook on a Blizzard panel button')
end)

test('a label keeps the color it had at rest through a hover, and a module that colors its own label keeps that (Bank Buy)', function()
	world()
	local b = button()
	fire(b, 'OnEnter', true); fire(b, 'OnLeave', true)
	eq(T.text(b.text:GetTextColor()), REST_TEXT, 'white at rest after the first hover')
	-- a module colors its label (Text > Danger) while at rest
	local danger = st:Color('text', 'danger')
	b.text:SetTextColor(danger.r, danger.g, danger.b)
	fire(b, 'OnEnter', true)
	fire(b, 'OnLeave', true)
	eq(T.rgb(b.text:GetTextColor()), T.rgb(danger.r, danger.g, danger.b), 'the red survives a hover')
	fire(b, 'OnMouseDown', 'LeftButton'); fire(b, 'OnMouseUp', 'LeftButton')
	eq(T.rgb(b.text:GetTextColor()), T.rgb(danger.r, danger.g, danger.b), 'and a press')
	-- recolored again at rest
	b.text:SetTextColor(0.2, 0.4, 0.6)
	fire(b, 'OnEnter', true); fire(b, 'OnLeave', true)
	eq(T.rgb(b.text:GetTextColor()), '0.20,0.40,0.60')
end)

test('under the Blizzard look a SaftUI button on the panel art shows only the -Disabled art: no 40% alpha; Thick dims', function()
	world()
	T.theme('blizzard')
	local b = button()
	b:Disable()
	eq(b:GetAlpha(), 1, 'Blizzard: the art alone')
	eq(st:GetState(b, 'disabled'), false)
	T.theme('thick')
	eq(b:GetAlpha(), 0.4, 'switched to Thick while disabled: dimmed')
	T.theme('blizzard')
	eq(b:GetAlpha(), 1, 'and back: undimmed')
	b:Enable()
	T.theme('thick')
	eq(b:GetAlpha(), 1)
	b:Disable()
	eq(b:GetAlpha(), 0.4, 'a SaftUI button on SaftUI\'s own look still dims to 40%')
end)

test("retail's deposit button (a Blizzard panel button) is dimmed when disabled under Thick, and left alone under Blizzard", function()
	world()
	local own = CreateFrame('Button', nil, UIParent)
	own.Left, own.Middle, own.Right = own:CreateTexture(), own:CreateTexture(), own:CreateTexture()
	own:SetSize(100, 22)
	st:SkinButton(own)
	own:Disable()
	eq(own:GetAlpha(), 0.4, 'Thick: a disabled deposit button looks disabled')
	own:Enable()
	eq(own:GetAlpha(), 1)
	T.theme('blizzard')
	own:Disable()
	eq(own:GetAlpha(), 1, "Blizzard: the game's -Disabled art and alpha")
	T.theme('thick')
	eq(own:GetAlpha(), 0.4, 'Thick again, still disabled')
	-- nothing written onto it, no SetScript
	check(rawget(own, 'SetScript') == nil and rawget(own, 'Disable') == nil, 'no field or method hook on the Blizzard button')
end)

test("st:SkinButton clears a Blizzard template's own highlight, pushed and disabled textures (none left drawing, none made)", function()
	world()
	local b = CreateFrame('Button', nil, UIParent)
	b:SetSize(100, 22)
	b:SetHighlightTexture([[Interface\Buttons\UI-Panel-Button-Highlight]])
	b:SetPushedTexture([[Interface\Buttons\UI-Panel-Button-Down]])
	b:SetDisabledTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
	st:SkinButton(b)
	for _, state in ipairs({ 'Highlight', 'Pushed', 'Disabled' }) do
		local t = b['Get' .. state .. 'Texture'](b)
		check(t == nil or not t:GetTexture() or t:GetTexture() == '', state .. ' texture cleared')
	end
end)

test("the 'button' style check registers its label as the box's text; a check box takes the disabled state", function()
	world()
	local c = CreateFrame('CheckButton', nil, UIParent)
	c.Text = c:CreateFontString(nil, 'OVERLAY')
	st:SkinCheckButton(c, 'button')
	check(st:StateLook(c).text ~= nil, "the label is the box's text: Text > Normal over the Fill")
	local d = checkbox()
	d:Disable()
	eq(d:GetAlpha(), 0.4, 'a disabled check box dims')
	eq(st:GetState(d, 'disabled'), true)
	d:Enable()
	eq(d:GetAlpha(), 1)
	d:SetEnabled(false)
	eq(d:GetAlpha(), 0.4)
	d:SetEnabled(true)
	local e = checkbox('button')
	e:Disable()
	eq(e:GetAlpha(), 0.4, "the 'button' style too")
end)

test("a slot skinned once keeps the look of its last skin when the theme changes (no tint on Blizzard's art)", function()
	world()
	T.theme('blizzard')
	local b = slot('action')
	eq(st:StateLook(b).blizzard, true)
	T.theme('thick')
	-- not re-skinned: the textures still wear Blizzard's art, so the helper still leaves them alone
	st:RestyleStates(b) -- any later restyle or state set reads the look again
	eq(st:StateLook(b).blizzard, true, 'the record follows the look the textures wear, not the live theme')
	st:SkinActionButton(b, nil, 'action')
	eq(st:StateLook(b).blizzard, false, 'a re-skin brings the SaftUI look')
end)

------------------------------------------------------------------ check boxes

test('a check box: off, hover, checked (edge, mark 2 in, fade), checked + hover; checked by a click and by code', function()
	world()
	local c = checkbox()
	local look = st:StateLook(c)
	eq(look.shape, 'check')
	check(not look.layer.shown and not look.fill.shown and not look.mark.shown, 'off: nothing shows')
	eq(T.edge(c.backdrop), REST_EDGE)
	fire(c, 'OnEnter', true)
	look = st:StateLook(c)
	near_hex('hover is T+', look.layer, PLUS); eq(look.layer.a, 0.16)
	eq(c:GetHighlightTexture() and c:GetHighlightTexture():GetAlpha(), 0, 'the old flat highlight is gone')
	fire(c, 'OnLeave', true)
	-- checked by code
	c:SetChecked(true)
	eq(st:GetState(c, 'selected'), true, 'SetChecked(true) sets selected')
	look = st:StateLook(c)
	eq(T.edge(c.backdrop), edge_accent(), 'the edge is the accent')
	check(look.fill.shown, 'the fade shows'); near_hex('the fill', look.fill, ACCENT)
	check(look.mark.shown, 'the mark shows'); near_hex('the mark is the accent', look.mark, ACCENT)
	eq(c:GetCheckedTexture(), look.pieces.mark, 'the checked texture is the mark')
	local m = st:RoundToPixel(2, c)
	local _, _, _, x, y = look.pieces.mark:GetPoint(1)
	eq(x, m); eq(y, -m)
	local _, _, _, x2, y2 = look.pieces.mark:GetPoint(2)
	eq(x2, -m); eq(y2, m)
	fire(c, 'OnEnter', true)
	look = st:StateLook(c)
	near_hex('checked + hover: the edge is T+', look.edge, PLUS)
	near_hex('the layer', look.layer, PLUS)
	fire(c, 'OnLeave', true)
	c:SetChecked(false)
	eq(st:GetState(c, 'selected'), false)
	eq(T.edge(c.backdrop), REST_EDGE, 'unchecked: the rest edge'); check(not st:StateLook(c).mark.shown, 'and no mark')
	-- by a click: the game checks it before OnClick; PostClick hears it
	local d = checkbox()
	d:SetChecked(true) -- the game's own toggle
	fire(d, 'PostClick')
	eq(st:GetState(d, 'selected'), true, 'PostClick sets selected')
	d:SetChecked(false)
	fire(d, 'PostClick')
	eq(st:GetState(d, 'selected'), false)
end)

test("a check box styled 'button' is a box: selected while checked (edge and fill), no mark", function()
	world()
	local c = checkbox('button')
	local look = st:StateLook(c)
	eq(look.shape, 'box'); eq(look.mark, nil, 'no mark')
	c:SetChecked(true)
	eq(T.edge(c.backdrop), edge_accent(), 'the edge')
	check(st:StateLook(c).fill.shown, 'the fill')
	fire(c, 'OnEnter', true)
	near_hex('hover layer', st:StateLook(c).layer, PLUS)
	fire(c, 'OnLeave', true)
	c:SetChecked(false)
	eq(T.edge(c.backdrop), REST_EDGE)
	-- Blizzard's own checked art is not left showing over the box
	local shown = c:GetCheckedTexture()
	check(shown == nil or shown:GetTexture() == '' or shown:GetAlpha() == 0, "no checked texture drawn over a 'button' style box")
end)

test("a check box styled 'bare' is a box with a layer only: its checked texture is its caller's", function()
	world()
	local c = checkbox('bare')
	local look = st:StateLook(c)
	eq(look.shape, 'box'); check(look.layer ~= nil and look.mark == nil, 'a layer')
	eq(c.backdrop, nil, 'no backdrop of its own')
	fire(c, 'OnEnter', true)
	near_hex('hover is T+', st:StateLook(c).layer, PLUS)
	fire(c, 'OnLeave', true)
	local checked = c:GetCheckedTexture()
	checked:SetVertexColor(0.25, 0.5, 0.75, 0.6)
	c:SetChecked(true)
	eq(st:GetState(c, 'selected'), false, 'checking sets no state')
	eq(T.text(checked:GetVertexColor()), '0.25,0.50,0.75,0.60', 'its color is its caller\'s')
	st:ColorChanged('accent')
	T.theme('blizzard'); T.theme('thick')
	st:ColorChanged('accent')
	eq(T.text(checked:GetVertexColor()), '0.25,0.50,0.75,0.60', 'through a pass and a theme switch')
	eq(checked:GetTexture(), st.BLANK_TEX)
end)

test('a check box under Blizzard shows the Settings art; the states return with Thick', function()
	world()
	local c = checkbox()
	c:SetChecked(true)
	T.theme('blizzard')
	local look = st:StateLook(c)
	eq(look.blizzard, true)
	eq(look.layer.alpha, 0, 'the layer is held'); eq(look.fill.alpha, 0)
	eq(c:GetCheckedTexture():GetAtlas(), st.ThemeArt.Control('checkbox').checked, 'the art on the checked texture')
	T.theme('thick')
	look = st:StateLook(c)
	eq(look.blizzard, false)
	eq(c:GetCheckedTexture():GetTexture(), st.BLANK_TEX, 'the mark is flat again')
	near_hex('the mark is the accent', look.mark, ACCENT)
	eq(T.edge(c.backdrop), edge_accent())
end)

------------------------------------------------------------------ scroll bar thumbs

test('a scroll bar thumb rests in kit-edge and is solid T+ and T- under the mouse and held', function()
	world()
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local thumb = bar:GetThumb()
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(unpack(ST.THUMB_REST)), 'at rest: kit-edge')
	eq(st:StateLook(thumb).shape, 'thumb')
	fire(thumb, 'OnEnter', true)
	near_hex('under the mouse', st:StateLook(thumb).solid, PLUS)
	fire(thumb, 'OnMouseDown', 'LeftButton')
	near_hex('held', st:StateLook(thumb).solid, MINUS)
	fire(thumb, 'OnMouseUp', 'LeftButton'); fire(thumb, 'OnLeave', true)
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(unpack(ST.THUMB_REST)), 'at rest again')
	eq(thumb.entered, nil, 'nothing is written onto the thumb'); eq(thumb.pressed, nil)
	-- a theme redraw puts the rest color back
	T.theme('thin')
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(unpack(ST.THUMB_REST)), 'after a redraw')
	fire(thumb, 'OnEnter', true)
	T.theme('thick')
	near_hex('under the mouse, kept through a redraw', st:StateLook(thumb).solid, PLUS)
	fire(thumb, 'OnLeave', true)
	-- under Blizzard: MinimalScrollBar's own art, no recolor
	T.theme('blizzard')
	eq(st:StateLook(thumb).blizzard, true)
	fire(thumb, 'OnEnter', true); fire(thumb, 'OnLeave', true)
	T.theme('thick')
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(unpack(ST.THUMB_REST)), 'back under Thick at rest')
end)

------------------------------------------------------------------ radio groups

local function radio(options)
	options = options or {}
	local calls = {}
	local group = st:CreateRadioGroup('SaftUITestRadio', UIParent, {
		buttonWidth = 60, buttonHeight = 20, buttonSpacing = 2,
		theme = options.theme, background = options.background,
		items = { { label = 'One' }, { label = 'Two' }, { label = 'Three' } },
		onClick = function(self) calls[#calls + 1] = self.config.label end,
	})
	return group, calls
end

test('a radio group picks with the selected look; a group drawn with None no longer errors', function()
	world()
	local group, calls = radio()
	local a, b = group.buttons[1], group.buttons[2]
	stub.click(a)
	eq(st:GetState(a, 'selected'), true); eq(st:GetState(b, 'selected'), false)
	eq(T.edge(a.backdrop), edge_accent(), 'the picked one: the accent edge')
	check(st:StateLook(a).fill.shown, 'and the fade')
	eq(T.edge(b.backdrop), REST_EDGE, 'the others keep the theme edge')
	stub.click(b)
	eq(st:GetState(a, 'selected'), false); eq(st:GetState(b, 'selected'), true)
	eq(T.edge(a.backdrop), REST_EDGE, 'the first has its edge back'); eq(T.edge(b.backdrop), edge_accent())
	eq(calls[#calls], 'Two', "the group's click handler still runs")
	-- the accent moves: the picked one follows through the helper
	local c = st:Color('accent')
	local keep = { c.r, c.g, c.b }
	c:SetRGB(1, 0, 0); ST.Changed()
	eq(T.edge(b.backdrop), T.text(1, 0, 0, 1), 'the accent reaches the picked button')
	c:SetRGB(unpack(keep)); ST.Changed()
	-- None: no backdrop, nothing to index
	local none = radio({ theme = 'none' })
	local n = none.buttons[1]
	eq(n.backdrop, nil, 'None draws no backdrop')
	stub.click(n)
	eq(st:GetState(n, 'selected'), true, 'picked with no error')
end)

------------------------------------------------------------------ slots

test('st:SkinActionButton: hover BLEND T+ at 0.16 over the icon, pushed T- at 0.32, the disabled texture kept', function()
	world()
	local b = slot()
	local look = st:StateLook(b)
	eq(look.shape, 'icon')
	eq(b:GetHighlightTexture(), look.pieces.hover, 'the highlight is the helper\'s piece')
	eq(look.hover_piece.blend, 'BLEND'); eq(look.hover_piece.layer, st.ThemeArt.HOVER_LAYER)
	near_hex('hover is T+', look.hover_piece, PLUS); eq(look.hover_piece.a, 0.16)
	near_hex('pushed is T-', look.pushed_piece, MINUS); eq(look.pushed_piece.a, 0.32)
	eq(look.pushed_piece.blend, 'BLEND'); eq(look.pushed_piece.layer, 'OVERLAY')
	eq(look.hover_piece.texture, st.BLANK_TEX)
	check(b:GetDisabledTexture() ~= nil, 'the disabled texture is kept')
	eq(T.text(b:GetDisabledTexture():GetVertexColor()), '0.00,0.00,0.00,0.40')
	-- it follows the accent, through the helper
	local c = st:Color('accent')
	local keep = { c.r, c.g, c.b }
	c:SetRGB(1, 0, 0); ST.Changed()
	check(st:StateLook(b).hover_piece.r > 0.9, 'the hover follows the accent')
	c:SetRGB(unpack(keep)); ST.Changed()
	-- skinned again (a profile change): nothing made twice, BLEND still
	local regions = #{ b:GetRegions() }
	st:SkinActionButton(b, nil, 'slot')
	eq(#{ b:GetRegions() }, regions, 'no second texture')
	eq(st:StateLook(b).hover_piece.blend, 'BLEND')
end)

test("a slot under Blizzard wears Blizzard's state art; the helper leaves it alone", function()
	world()
	T.theme('blizzard')
	local b = slot('action')
	local look = st:StateLook(b)
	eq(look.blizzard, true)
	check(look.hover_piece.r == 1 and look.hover_piece.g == 1 and look.hover_piece.b == 1, "Blizzard's art is not tinted: " .. SL.rgb(look.hover_piece))
	check(b:GetHighlightTexture():GetAtlas() ~= nil or b:GetHighlightTexture():GetTexture() ~= st.BLANK_TEX, "Blizzard's art")
	T.theme('thick')
	st:SkinActionButton(b, nil, 'action')
	look = st:StateLook(b)
	eq(look.blizzard, false)
	eq(look.hover_piece.texture, st.BLANK_TEX); eq(look.hover_piece.blend, 'BLEND')
	near_hex('and the flat tint is back', look.hover_piece, PLUS)
end)

------------------------------------------------------------------ edit boxes

local function editbox(theme)
	local e = CreateFrame('EditBox', nil, UIParent)
	e:SetSize(100, 20)
	st:SkinEditBox(e, theme)
	return e
end

test("st:SkinEditBox's focus is the accent edge, kept through a recolor; under Blizzard none", function()
	world()
	local e = editbox()
	local backdrop = st:DrawnFrame(e)
	check(backdrop ~= nil, 'a backdrop of SaftUI\'s')
	eq(st:StateLook(backdrop).shape, 'box')
	local rest = T.edge(backdrop)
	e:SetFocus()
	fire(e, 'OnEditFocusGained')
	eq(T.edge(backdrop), edge_accent(), 'focused: the accent edge, no longer white')
	eq(st:GetState(backdrop, 'focus'), true)
	check(not st:StateLook(backdrop).layer.shown, 'the body is unchanged')
	-- a recolor puts it back
	st:ColorsChanged('theme')
	eq(T.edge(backdrop), edge_accent(), 'kept through a recolor')
	T.theme('thin')
	eq(T.edge(backdrop), edge_accent(), 'kept through a redraw')
	T.theme('thick')
	-- the accent moves while focused
	local c = st:Color('accent')
	local keep = { c.r, c.g, c.b }
	c:SetRGB(1, 0, 0); ST.Changed()
	eq(T.edge(backdrop), T.text(1, 0, 0, 1), 'follows the accent')
	c:SetRGB(unpack(keep)); ST.Changed()
	e:ClearFocus()
	fire(e, 'OnEditFocusLost')
	eq(T.edge(backdrop), rest, 'unfocused: the theme edge')
	eq(st:GetState(backdrop, 'focus'), false)
	-- Blizzard: no SaftUI edge
	T.theme('blizzard')
	local f = editbox()
	f:SetFocus(); fire(f, 'OnEditFocusGained')
	eq(st:StateLook(st:DrawnFrame(f) or f) and st:StateLook(st:DrawnFrame(f)).blizzard, true, 'under Blizzard the helper holds nothing of SaftUI\'s')
	T.theme('thick')
	-- None: no backdrop, no error
	local g = editbox('none')
	g:SetFocus(); fire(g, 'OnEditFocusGained')
	g:ClearFocus(); fire(g, 'OnEditFocusLost')
end)

------------------------------------------------------------------ resize corner

test('a resize corner is a glyph: white at rest, the lighter tone under the mouse and held', function()
	world()
	local frame = resizable()
	local sized = false
	frame.StartSizing = function() sized = true end
	frame.StopMovingOrSizing = function() end
	st:EnableResizing(frame)
	local corner = frame.ResizeButton
	local look = st:StateLook(corner)
	eq(look.shape, 'glyph')
	eq(T.rgb(corner:GetNormalTexture():GetVertexColor()), '1.00,1.00,1.00', 'white at rest')
	fire(corner, 'OnEnter', true)
	near_hex('under the mouse', bytes_of(corner:GetNormalTexture():GetVertexColor()), PLUS)
	near_hex('the highlight too', bytes_of(corner:GetHighlightTexture():GetVertexColor()), PLUS)
	fire(corner, 'OnMouseDown', 'LeftButton')
	near_hex('held', bytes_of(corner:GetPushedTexture():GetVertexColor()), PLUS)
	fire(corner, 'OnMouseUp', 'LeftButton'); fire(corner, 'OnLeave', true)
	eq(T.rgb(corner:GetNormalTexture():GetVertexColor()), '1.00,1.00,1.00', 'white again')
	eq(corner:GetHighlightTexture():GetBlendMode(), 'BLEND')
	-- the corner's own resize still runs
	check(sized, 'the corner still sizes the frame')
end)

------------------------------------------------------------------ Blizzard

test('under Blizzard: panel art, Settings check art, MinimalScrollBar art, the state art; no SaftUI piece shows', function()
	world()
	local b = button()
	local c = checkbox()
	c:SetChecked(true)
	local p = checkbox('button')
	local bar = scrollBar()
	st:SkinNewScrollBar(bar)
	local s = slot('action')
	fire(b, 'OnEnter', true); fire(c, 'OnEnter', true); fire(p, 'OnEnter', true)
	st:SetButtonPressed(b, true)
	SL.each_look(function(name)
		if name == 'blizzard' then
			for _, f in ipairs({ b, c, p }) do
				local look = st:StateLook(f)
				eq(look.blizzard, true, 'a state frame under Blizzard')
				eq(look.layer.alpha, 0, 'its layer is held'); eq(look.fill.alpha, 0, 'its fill is held')
				if look.mark and f == c then eq(look.mark.alpha, 1, "the check's mark is Blizzard's art, left alone") end
			end
			eq(st:StateLook(bar:GetThumb()).blizzard, true)
			eq(c:GetCheckedTexture():GetAtlas(), st.ThemeArt.Control('checkbox').checked)
		else
			for _, f in ipairs({ b, c, p }) do
				eq(st:StateLook(f).blizzard, false)
				eq(st:StateLook(f).layer.alpha, 1, name .. ': the layer is at full again')
			end
		end
		st:SkinActionButton(s, nil, 'action')
	end)
end)

------------------------------------------------------------------ cost

test('a pass over 200 Core widgets and 700 slots: under 1,500 calls, nothing made or forbidden, under 4 KB', function()
	world()
	for _ = 1, 100 do button() end
	for _ = 1, 50 do checkbox() end
	for _ = 1, 50 do st:SkinNewScrollBar(scrollBar()) end
	for _ = 1, 700 do slot() end
	local m = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing forbidden: ' .. tostring(next(m.forbidden.by)))
	check(m.kb < 4, 'under 4 KB over 100 passes: ' .. m.kb)
	local per = m.calls.total / 100
	check(per <= 700 * 2 + 50, 'calls per pass ' .. per)
	eq(per, 700 * 2, 'the slots color two pieces each; the 200 widgets at rest cost no setter')
	C.print('core widgets', m)
end)

test('a theme recolor lays nothing out: 100 buttons, 50 check boxes, 50 thumbs, RecolorThemed x100', function()
	world()
	for _ = 1, 100 do button() end
	for _ = 1, 50 do checkbox() end
	for _ = 1, 50 do st:SkinNewScrollBar(scrollBar()) end
	st:RecolorThemed()
	local m = C.measure(function() st:RecolorThemed() end, 100)
	eq(m.forbidden.total, 0, 'nothing forbidden (no ClearAllPoints or SetPoint): ' .. tostring(next(m.forbidden.by)))
	eq(m.made, 0, 'nothing made')
	check(m.calls.total / 100 <= 1250, 'setters per pass at the base count: ' .. m.calls.total / 100)
	-- a look flip (Blizzard and back) still restyles: the states follow
	local b = button()
	fire(b, 'OnEnter', true)
	T.theme('blizzard')
	eq(st:StateLook(b).layer.alpha, 0, 'Blizzard: held')
	T.theme('thick')
	eq(st:StateLook(b).layer.alpha, 1, 'Thick again: back')
	C.print('recolor', m)
end)
