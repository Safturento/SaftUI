-- The options kit's interaction states (the plan "interaction states", Task 3):
-- every control, list row, sidebar row and tab of /sui is a state frame
-- (Widgets/states.lua, st:GetState reads it), drawn by the helper from the Accent:
-- hover tints the BODY (never only the edge), pushed tints it darker, selected is
-- the accent edge (a left bar on a row, an underline on a tab) with a fade, focus
-- is the accent edge, disabled dims. Which state holds is the kit's code; what each
-- looks like is the helper's (states_draw_test.lua has the helper itself).
--
-- Real: the /sui window and its widgets (options_window_helpers.lua), the
-- real Theme and Colors modules, Core's helpers and the state helpers.
-- The mouse and the keyboard are played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local SL = load_test_file('lib/states_look.lua')
local P = load_test_file('lib/pixels.lua')
local C = load_test_file('lib/color_cost.lua')
local st = SaftUI
local W, OB, OW = st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local Kit = W.Kit
local frames, theme, close_all, click = H.frames, H.theme, H.close_all, H.click
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function look(frame) return st:StateLook(frame) end
local function enter(frame) stub.fire_script(frame, 'OnEnter', true) end
local function leave(frame) stub.fire_script(frame, 'OnLeave', true) end
local function edge_of(frame) return rgb(frame:GetBackdropBorderColor()) end
local function fill_of(frame) return rgb(frame:GetBackdropColor()) end
local EDGE = rgb(unpack(st.BOX_COLORS.edge))
local function tone() return rgb(st:StateColor('edgeHover')) end
local function accent() return rgb(st:StateColor('edge')) end
local function lit(piece) return piece and piece.shown and piece.alpha > 0 end

local function new_parent()
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetSize(500, 300)
	f:SetPoint('CENTER')
	return f
end
local function put(control)
	control:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	return control
end

-- A kit widget of rowType bound to a one-option row, placed.
local function widget(rowType, fields)
	local option = { type = rowType, name = 'Thing', get = function() return fields.value end, set = function() end }
	for k, v in pairs(fields) do if k ~= 'value' then option[k] = v end end
	local page = { type = 'group', name = 'Page', args = { thing = option } }
	local root = { page = page }
	local row
	for _, section in ipairs(st.OptionsModel.BuildView(root, 'page').sections) do
		for _, r in ipairs(section.rows) do if r.key == 'thing' then row = r end end
	end
	local w = W.Create(new_parent(), rowType)
	w:Bind(root, row, function() end)
	w:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	return w
end

------------------------------------------------------------------ rest

test('every kit control at rest is drawn as before: its fill, its edge, its alpha, no piece shown', function()
	theme('thick')
	local reload = put(W.Button(new_parent(), 'Reload UI', function() end))
	eq(fill_of(reload), rgb(unpack(st.BOX_COLORS.bg)), 'a button: the window fill')
	eq(edge_of(reload), EDGE, 'its edge 0.3')
	local input = widget('input', { value = 'abc' })
	eq(fill_of(input.frame), rgb(unpack(st.BOX_COLORS.field)), 'an input: the field fill 0.078')
	eq(edge_of(input.frame), EDGE, 'its edge')
	for name, frame in pairs({ reload = reload, input = input.frame }) do
		local l = look(frame)
		check(l and l.shape == 'box', name .. ' is a state frame (st:GetState reads it)')
		check(not lit(l.layer) and not lit(l.fill), name .. ': nothing drawn at rest')
		eq(l.alpha, 1, name .. ': full alpha')
		check(st:GetState(frame, 'hover') == false and st:GetState(frame, 'disabled') == false, name .. ': no state holds')
	end
	input:Release()
	-- the tabs and the sidebar: Muted and Normal as before
	st.Config:Open('Fonts', 'theme')
	local F = frames()
	local muted, normal = st:Color('text', 'muted'), st:Color('text', 'normal')
	local active, other
	for _, tab in ipairs(F.tabs) do
		if tab.active then active = tab elseif not other then other = tab end
	end
	check(active and other, 'a row of tabs')
	eq(rgb(active.text:GetTextColor()), rgb(normal:GetRGB()), 'the active tab: Text > Normal')
	eq(rgb(other.text:GetTextColor()), rgb(muted:GetRGB()), 'another tab: Text > Muted')
	close_all()
end)

------------------------------------------------------------------ boxes

test("a button's label is over its layer; hover changes the body, never the edge", function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Reload UI', function() end))
	enter(b)
	local l = look(b)
	check(lit(l.layer), 'the Layer shows under the mouse')
	check(SL.near(l.layer, '5cc6ff'), 'in the tone: ' .. SL.bytes(l.layer))
	eq(string.format('%.2f', l.layer.a), string.format('%.2f', select(4, st:StateColor('hover'))), 'at the hover strength')
	check(l.layer.layer == 'ARTWORK' and l.layer.sublevel == -8, 'ARTWORK -8')
	check(l.layer.blend == 'BLEND', 'BLEND')
	check(b.text:GetDrawLayer() == 'OVERLAY', 'the label is over it')
	eq(edge_of(b), EDGE, 'the edge is unchanged (0.3, 0.3, 0.3)')
	leave(b)
	check(not lit(look(b).layer), 'the tint goes')
end)

test('a button held down: the pushed Layer, the label one line down, the size never changes', function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Reload UI', function() end))
	local width, height = b:GetWidth(), b:GetHeight()
	enter(b)
	stub.fire_script(b, 'OnMouseDown', 'LeftButton')
	local l = look(b)
	local d = { st:StateColor('pushed') }
	eq(rgb(l.layer.r, l.layer.g, l.layer.b), rgb(d[1], d[2], d[3]), 'the pushed tone')
	check(SL.near(l.layer, '0093cc'), 'darker: ' .. SL.bytes(l.layer))
	local _, _, _, _, y = b.text:GetPoint(1)
	eq(y, -1, 'the label 1 down')
	eq(b:GetWidth() .. 'x' .. b:GetHeight(), width .. 'x' .. height, 'the size holds')
	stub.fire_script(b, 'OnMouseUp', 'LeftButton')
	local _, _, _, _, y2 = b.text:GetPoint(1)
	eq(y2, 0, 'let go: the label back')
	leave(b)
end)

test('an input: hover tints, focus is the accent edge, both at once compose', function()
	theme('thick')
	local w = widget('input', { value = 'abc' })
	local e = w.frame
	enter(e)
	check(lit(look(e).layer), 'hover tints the body')
	eq(edge_of(e), EDGE, 'and the edge stays')
	stub.fire_script(e, 'OnEditFocusGained')
	eq(edge_of(e), accent(), 'focus: the accent edge')
	check(lit(look(e).layer), 'under the mouse still: the tint composes')
	leave(e)
	eq(edge_of(e), accent(), 'the mouse leaving does not take the focus edge')
	stub.fire_script(e, 'OnEditFocusLost')
	eq(edge_of(e), EDGE, 'focus lost: the edge goes')
	check(not lit(look(e).layer), 'and no tint')
	w:Release()
end)

test('a toggle: hover, on (edge, mark, fade), on + hover; disabled at 40%, no hover', function()
	theme('thick')
	local on = true
	local w = widget('toggle', { get = function() return on end, set = function(_, v) on = v end })
	local box = w.frame
	local l = look(box)
	eq(l.shape, 'check', 'a check box')
	eq(edge_of(box), accent(), 'on: the accent edge')
	check(lit(l.mark) and lit(l.fill), 'the mark and the fade')
	eq(rgb(l.mark.r, l.mark.g, l.mark.b), accent(), 'the mark in the accent')
	eq(l.mark.layer, 'OVERLAY', 'OVERLAY')
	enter(box)
	l = look(box)
	check(lit(l.layer), 'on + hover: the Layer')
	eq(edge_of(box), tone(), 'the edge in the lighter tone')
	eq(rgb(l.mark.r, l.mark.g, l.mark.b), tone(), 'and the mark')
	leave(box)
	click(box)
	check(not on, 'a click sets it off')
	check(not lit(look(box).mark) and not lit(look(box).fill), 'off: no mark, no fade')
	eq(edge_of(box), EDGE, 'its own edge')
	w:SetDisabled(true)
	eq(box:GetAlpha(), st:StateAlpha(), 'disabled: the Disabled opacity')
	eq(string.format('%.1f', box:GetAlpha()), '0.4', 'at 40%')
	box:EnableMouse(true)
	enter(box)
	check(not lit(look(box).layer), 'a disabled box takes no hover')
	leave(box)
	w:SetDisabled(false)
	eq(box:GetAlpha(), 1, 'enabled again: full alpha')
	w:Release()
end)

test('an icon button on: the accent edge and the fade, its icon in the accent; hoverIcon: the lighter tone under the mouse', function()
	theme('thick')
	local b = put(W.IconButton(new_parent(), st.icons.eye, function() return 'Eye', { 'Shows.' } end))
	W.SetOn(b, true)
	local l = look(b)
	eq(edge_of(b), accent(), 'the accent edge')
	check(lit(l.fill), 'and the fade')
	eq(rgb(b.icon:GetVertexColor()), accent(), 'the icon in the accent')
	enter(b)
	eq(rgb(b.icon:GetVertexColor()), accent(), 'under the mouse (no hoverIcon): still the accent')
	leave(b)
	b.hoverIcon = true
	enter(b)
	eq(rgb(b.icon:GetVertexColor()), tone(), 'hoverIcon, on, hovered: the lighter tone')
	leave(b)
	W.SetOn(b, false)
	local grey = rgb(st:Color('text', 'muted'):GetRGB())
	eq(rgb(b.icon:GetVertexColor()), grey, 'off: Muted')
	enter(b)
	eq(rgb(b.icon:GetVertexColor()), tone(), 'hoverIcon: the lighter tone under the mouse')
	leave(b)
	b.hoverIcon = nil
	enter(b)
	eq(rgb(b.icon:GetVertexColor()), grey, 'no hoverIcon: an icon stays Muted under the mouse')
	leave(b)
end)

test('a select, a color field and the dropdown face: boxes (hover tints, the edge stays)', function()
	theme('thick')
	local s = widget('select', { values = { a = 'A', b = 'B' }, value = 'a' })
	local c = widget('color', { value = 1, get = function() return 0.5, 0.5, 0.5, 1 end })
	local face = put(W.SelectFace(new_parent(), 150, function() end))
	for name, frame in pairs({ select = s.frame, color = c.frame, face = face }) do
		enter(frame)
		check(lit(look(frame).layer), name .. ': hover tints the body')
		eq(edge_of(frame), EDGE, name .. ': the edge stays')
		leave(frame)
	end
	s:Release(); c:Release()
end)

test('the keybinding button waiting for a key: the selected look, "Press a key" in the accent', function()
	theme('thick')
	local w = widget('keybinding', { value = 'K' })
	local b = w.frame
	enter(b)
	check(lit(look(b).layer) and not look(b).selected, 'hover tints it')
	leave(b)
	click(b)
	check(w.waiting, 'it waits')
	check(st:GetState(b, 'selected'), 'waiting is selected')
	eq(edge_of(b), accent(), 'the accent edge')
	check(lit(look(b).fill), 'and the fade')
	eq(rgb(w.text:GetTextColor()), accent(), '"Press a key" stays in the accent (a prompt)')
	eq(w.text:GetText(), 'Press a key', 'its prompt')
	w:StopWaiting()
	check(not st:GetState(b, 'selected'), 'selected goes with it')
	eq(edge_of(b), EDGE, 'the edge goes back')
	w:Release()
end)

test('the range: the fill stays the accent; the knob is solid under the mouse and darker while dragged', function()
	theme('thick')
	local w = widget('range', { min = 0, max = 10, step = 1, value = 5 })
	local state = stub.state(w.fill).color_texture
	eq(rgb(state[1], state[2], state[3]), accent(), 'the fill is the accent (progress)')
	local knob = w.slider:GetThumbTexture()
	local normal = rgb(st:Color('text', 'normal'):GetRGB())
	eq(rgb(knob:GetVertexColor()), normal, 'the knob rests in Text > Normal')
	check(st:GetState(w.slider, 'hover') == false, 'the slider is a state frame')
	enter(w.slider)
	local r, g, b = knob:GetVertexColor()
	check(SL.near({ r = r, g = g, b = b }, '5cc6ff'), 'solid in the tone under the mouse: ' .. SL.bytes({ r = r, g = g, b = b }))
	stub.fire_script(w.slider, 'OnMouseDown', 'LeftButton')
	r, g, b = knob:GetVertexColor()
	check(SL.near({ r = r, g = g, b = b }, '0093cc'), 'and the dark tone while dragged: ' .. SL.bytes({ r = r, g = g, b = b }))
	stub.fire_script(w.slider, 'OnMouseUp', 'LeftButton')
	leave(w.slider)
	eq(rgb(knob:GetVertexColor()), normal, 'back to its rest')
	-- the value box
	enter(w.edit)
	check(lit(look(w.edit).layer), 'the value box tints')
	leave(w.edit)
	stub.fire_script(w.edit, 'OnEditFocusGained')
	eq(edge_of(w.edit), accent(), 'and focus lights its edge')
	stub.fire_script(w.edit, 'OnEditFocusLost')
	w:Release()
end)

------------------------------------------------------------------ rows, tabs, the sidebar

test('the sidebar: hover tints (no grey); the current page has a 2-line bar and the fade; under Blizzard the list art', function()
	theme('thick')
	st.Config:Open('Fonts', 'theme')
	local F = frames()
	local current, other
	for _, item in ipairs(F.nav) do
		if item.key and item.active then current = item elseif item.key and not other then other = item end
	end
	check(current and other, 'pages')
	local l = look(current)
	eq(l.shape, 'row', 'a row')
	check(lit(l.bar) and lit(l.fill), 'the current page: the bar and the fade')
	eq(l.bar.width, 2 * st:GetLineSize(current), 'a bar two lines wide')
	eq(rgb(l.bar.r, l.bar.g, l.bar.b), accent(), 'in the accent')
	check(not lit(look(other).bar), 'another page: none')
	enter(other)
	l = look(other)
	check(lit(l.layer) and SL.near(l.layer, '5cc6ff'), 'hover tints in the tone (not grey #222)')
	leave(other)
	check(not lit(look(other).layer), 'gone')
	-- the open page under the mouse: both
	enter(current)
	l = look(current)
	check(lit(l.layer) and lit(l.bar), 'selected and hovered: both')
	eq(rgb(l.bar.r, l.bar.g, l.bar.b), tone(), 'the bar in the lighter tone')
	leave(current)
	-- under Blizzard: the list's art, none of SaftUI's
	theme('blizzard')
	st.Config:Open('Fonts', 'theme')
	F = frames()
	for _, item in ipairs(F.nav) do
		if item.key and item.active then
			check(item.listPicked:IsShown(), 'Blizzard: the picked art')
			check(not lit(look(item).bar) and not lit(look(item).fill), "Blizzard: none of SaftUI's pieces show")
			check(look(item).blizzard, 'the helper holds back')
		end
	end
	theme('thick')
	close_all()
end)

test('tabs: hover tints and the text goes Normal; the active one has the underline as the bar (one line below) and the fade', function()
	theme('thick')
	st.Config:Open('Fonts', 'theme')
	local F = frames()
	local active, other
	for _, tab in ipairs(F.tabs) do
		if tab.active then active = tab elseif not other then other = tab end
	end
	local l = look(active)
	eq(l.shape, 'tab', 'a tab')
	check(lit(l.bar) and lit(l.fill), 'the bar (the underline) and the fade')
	eq(l.bar.width, 2 * st:GetLineSize(active), 'two lines')
	local bar = st:StateLook(active).pieces.bar
	eq(bar:GetBottom(), active:GetBottom() - st:GetLineSize(active), 'one line below the tab (opts.barOffset)')
	eq(rgb(l.bar.r, l.bar.g, l.bar.b), accent(), 'in the accent')
	local muted = rgb(st:Color('text', 'muted'):GetRGB())
	eq(rgb(other.text:GetTextColor()), muted, 'another tab rests Muted')
	enter(other)
	local o = look(other)
	check(lit(o.layer), 'hover tints')
	eq(rgb(other.text:GetTextColor()), rgb(st:Color('text', 'normal'):GetRGB()), 'its text goes Normal')
	leave(other)
	eq(rgb(other.text:GetTextColor()), muted, 'and back to Muted')
	theme('thick')
	close_all()
end)

test('a dropdown list: rows tint under the mouse; the picked row has the bar and fade and its text by the pick', function()
	theme('thick')
	local w = widget('select', { values = { a = 'Alpha', b = 'Beta' }, value = 'a' })
	click(w.frame)
	local list = W.GetListFrames()
	local picked, plain = list.rows[1], list.rows[2]
	check(st:GetState(picked, 'selected'), 'the picked row is selected')
	check(lit(look(picked).bar) and lit(look(picked).fill), 'a bar and the fade')
	eq(rgb(picked.text:GetTextColor()), rgb(st:Color('text', 'normal'):GetRGB()), 'its text is Normal by contrast, no longer the accent')
	check(not st:GetState(plain, 'selected'), 'the other is not')
	enter(plain)
	check(lit(look(plain).layer), 'a row tints under the mouse')
	eq(string.format('%.2f', look(plain).layer.a), string.format('%.2f', select(4, st:StateColor('hover'))), 'at the hover strength')
	leave(plain)
	W.CloseList()
	w:Release()
end)

test('a check list row: its box takes its row\'s hover; the box is ticked by the pick', function()
	theme('thick')
	local owner = put(W.Button(new_parent(), 'Pick', function() end))
	local checked = { a = true }
	W.OpenCheckList(owner, { { key = 'a', label = 'A' }, { key = 'b', label = 'B' } }, function(key) return checked[key] end, function() end)
	local list = W.GetListFrames()
	local row = list.rows[2]
	check(st:GetState(list.rows[1].box, 'selected'), 'the ticked row\'s box is selected')
	enter(row)
	check(lit(look(row).layer), 'the row tints')
	check(lit(look(row.box).layer), 'and its box takes the same hover')
	leave(row)
	check(not lit(look(row.box).layer), 'gone with it')
	W.CloseList()
end)

------------------------------------------------------------------ glyphs

test('glyphs: the reset icon, dots, links, nudges, the page arrow, the position dots', function()
	theme('thick')
	local muted = rgb(st:Color('text', 'muted'):GetRGB())
	-- the reset icon: Muted, then the lighter tone
	local reset = CreateFrame('Frame', nil, UIParent)
	reset:SetSize(40, 20)
	local icon = OB.ResetIcon(reset, function() end, function() end)
	icon:SetPoint('CENTER')
	eq(rgb(icon.icon:GetVertexColor()), muted, 'the reset icon: Muted')
	enter(icon)
	eq(rgb(icon.icon:GetVertexColor()), tone(), 'under the mouse: the lighter tone')
	check(SL.near(look(icon).glyph, '5cc6ff'), 'the tone is #5cc6ff')
	leave(icon)
	eq(rgb(icon.icon:GetVertexColor()), muted, 'Muted again')
	-- an icon link
	local link = put(W.IconLink(new_parent(), st.icons.search, 14, function() return 'Search' end))
	eq(rgb(link.icon:GetVertexColor()), muted, 'a link icon: Muted')
	enter(link)
	eq(rgb(link.icon:GetVertexColor()), tone(), 'its tone under the mouse')
	leave(link)
	-- the nudges' arrows: Muted, the tone under the mouse
	local owner = { disabled = false, Tip = function() end }
	local pair, up = Kit.NudgePair(owner, new_parent(), function() end, function() end)
	put(pair)
	eq(rgb(up.arrow:GetVertexColor()), muted, 'a nudge arrow: Muted')
	enter(up)
	eq(rgb(up.arrow:GetVertexColor()), tone(), 'the tone under the mouse')
	leave(up)
	owner.disabled = true
	enter(up)
	eq(rgb(up.arrow:GetVertexColor()), muted, 'the owner disabled: it stays Muted')
	leave(up)
	-- the position block's dots: 4 square grey, the tone hovered, 8 square in the accent picked
	local w = widget('position', { target = 'name', get = function(_, part) return ({ point = 'CENTER', rel_point = 'TOP', x_off = 0, y_off = 0, frame = 'X' })[part] end })
	local grey = rgb(0.333, 0.333, 0.333)
	local picked_dot, plain_dot = w.this[5], w.this[1]
	eq(plain_dot.dot:GetWidth() .. ',' .. rgb(plain_dot.dot:GetVertexColor()), '4,' .. grey, 'a dot: 4 square, grey')
	eq(picked_dot.dot:GetWidth() .. ',' .. rgb(picked_dot.dot:GetVertexColor()), '8,' .. accent(), 'the picked dot: 8 square, the accent')
	enter(plain_dot)
	eq(plain_dot.dot:GetWidth() .. ',' .. rgb(plain_dot.dot:GetVertexColor()), '4,' .. tone(), 'hovered: 4 square, the tone')
	leave(plain_dot)
	enter(picked_dot)
	eq(picked_dot.dot:GetWidth() .. ',' .. rgb(picked_dot.dot:GetVertexColor()), '8,' .. tone(), 'picked and hovered: 8 square, the tone')
	leave(picked_dot)
	w:Release()
	-- the title's page arrow and a link of the share line are in the window's own tests
	theme('thick')
end)

test('a link is a glyph in the accent, Text > Strong under the mouse (opts.glyphHover); the font row\'s dots are white under Blizzard', function()
	theme('thick')
	-- optionsshare.lua's Link: placed by MakeParts on a row; read through the share tests' own world instead:
	-- here the contract: a glyph whose hover color is Strong (the helper's glyphHover) and rest the accent.
	local host = CreateFrame('Frame', nil, UIParent)
	local text = host:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(W.GetFont())
	text:SetText('All')
	local f = CreateFrame('Button', nil, UIParent)
	f:SetSize(20, 10)
	st:AddStates(f, 'glyph', { glyph = text, glyphRest = OB.Accent, glyphHover = function() return st:Color('text', 'strong'):GetRGB() end })
	st:PaintStates(f)
	eq(rgb(text:GetTextColor()), accent(), 'the accent at rest')
	enter(f)
	eq(rgb(text:GetTextColor()), rgb(st:Color('text', 'strong'):GetRGB()), 'Strong under the mouse')
	leave(f)
	eq(rgb(text:GetTextColor()), accent(), 'and the accent again')
end)

------------------------------------------------------------------ F3, F4, F8

test('F3: W.Edge on a frame with no record paints the border directly, as it did; the search box is a state frame', function()
	theme('thick')
	local plain = W.Box(st:CreateFrame('EditBox', nil, UIParent))
	check(st:GetState(plain, 'focus') == nil, 'no record')
	W.Edge(plain, true)
	eq(edge_of(plain), accent(), 'lit: the accent edge')
	W.Edge(plain, false)
	eq(edge_of(plain), EDGE, 'unlit: its own edge')
	-- a registered frame: focus is the helper's
	local reg = W.HoverStates(W.Box(st:CreateFrame('EditBox', nil, UIParent)))
	W.Edge(reg, true)
	check(st:GetState(reg, 'focus'), 'a state frame: the focus state')
	W.Edge(reg, false)
	-- the /sui search box: a state frame whose hover tints and whose focus lights the edge
	st.Config:Open('Fonts', 'theme')
	local F = frames()
	check(st:GetState(F.search, 'focus') == false, 'the search box is a state frame')
	enter(F.search)
	check(lit(look(F.search).layer), 'hover tints it')
	eq(edge_of(F.search), EDGE, 'its edge stays')
	stub.fire_script(F.search, 'OnEditFocusGained')
	eq(edge_of(F.search), accent(), 'focus: the accent edge')
	stub.fire_script(F.search, 'OnEditFocusLost')
	leave(F.search)
	close_all()
end)

test('F4: W.HoverEdge is gone; W.HoverStates takes the frame and its options, no isDisabled', function()
	check(W.HoverEdge == nil, 'the alias is gone')
	local box = W.Box(st:CreateFrame('Button', nil, UIParent))
	W.HoverStates(box)
	check(st:GetState(box, 'hover') == false, 'it makes a state frame')
	enter(box)
	check(st:GetState(box, 'hover'), 'and hover holds under the mouse')
	leave(box)
end)

-- How many times SetState runs when frame's OnEnter fires: one set of hooks says 1.
local function sets_on_enter(frame)
	local n, real = 0, st.SetState
	st.SetState = function(...) n = n + 1; return real(...) end
	enter(frame)
	st.SetState = real
	return n
end

test('F8: a pooled widget is wired once: 100 acquire / release cycles pile up no texture and no hook, and start at rest', function()
	theme('thick')
	local types = {
		toggle = { value = true }, input = { value = 'x' }, select = { values = { a = 'A' }, value = 'a' },
		color = { get = function() return 1, 0, 0, 1 end }, execute = { func = function() end },
		keybinding = { value = 'K' }, range = { min = 0, max = 10, value = 3, step = 1 },
		item = { get = function() return true end, menu = {} }, multiselect = { values = { a = 'A', b = 'B' }, get = function() return true end },
	}
	for rowType, fields in pairs(types) do
		local w = widget(rowType, fields)
		local frame = w.frame
		-- every state frame of the widget: its own and the ones it tracks (the knob's slider, the value box...)
		local function states() local list = { frame }; for _, f in ipairs(w.states or {}) do list[#list + 1] = f end; return list end
		local function regions() local n = 0; for _, f in ipairs(states()) do n = n + #{ f:GetRegions() } + #{ f:GetChildren() } end; return n end
		local function sets() local n = 0; for _, f in ipairs(states()) do if f.GetScript and f:GetScript('OnEnter') then n = n + sets_on_enter(f) end end; return n end
		local before, hooks = regions(), sets()
		for _, f in ipairs(states()) do if f.GetScript and f:GetScript('OnLeave') then leave(f) end end
		w:Release()
		for i = 1, 100 do
			local again = widget(rowType, fields)
			if i % 2 == 0 then again:SetDisabled(true) end
			-- released in a state: under the mouse (and disabled, every other time)
			for _, f in ipairs(states()) do if f.GetScript and f:GetScript('OnEnter') then enter(f) end end
			again:Release()
		end
		local last = widget(rowType, fields)
		eq(last.frame, frame, rowType .. ': the same frame from the pool')
		eq(regions(), before, rowType .. ': no texture or frame piled up over 100 cycles')
		for _, f in ipairs(states()) do
			check(st:GetState(f, 'hover') ~= true, rowType .. ': acquired at rest (hover cleared)')
			check(st:GetState(f, 'pushed') ~= true, rowType .. ': and not pushed')
		end
		check(st:GetState(frame, 'disabled') ~= true, rowType .. ': and not disabled')
		eq(sets(), hooks, rowType .. ': one set of hooks, not more')
		for _, f in ipairs(states()) do if f.GetScript and f:GetScript('OnLeave') then leave(f) end end
		last:Release()
	end
end)

test('F8: the list rows, the sidebar rows and the tabs are wired once and start at rest each time', function()
	theme('thick')
	local w = widget('select', { values = { a = 'A', b = 'B' }, value = 'a' })
	click(w.frame)
	local list = W.GetListFrames()
	local row = list.rows[2]
	local before = #{ row:GetRegions() }
	local sets = sets_on_enter(row)
	leave(row)
	for _ = 1, 100 do
		W.CloseList()
		click(w.frame)
	end
	eq(#{ row:GetRegions() }, before, 'the list row: no texture piled up over 100 openings')
	eq(sets_on_enter(row), 1, 'one set of hooks (the row sets its hover itself)')
	check(sets >= 1, 'hover is set')
	leave(row)
	W.CloseList()
	w:Release()
	-- the sidebar: drawn again 100 times
	st.Config:Open('Fonts', 'theme')
	local F = frames()
	local item = F.nav[2] and F.nav[2].key and F.nav[2] or F.nav[3]
	enter(item)
	local n = #{ item:GetRegions() }
	for _ = 1, 100 do OW:Navigate('Fonts', { tab = 'theme' }) end
	-- (a row's frame may be another pooled one: read the first current one)
	local current
	for _, nav in ipairs(frames().nav) do if nav.key then current = nav break end end
	eq(#{ current:GetRegions() }, n, 'a sidebar row: no texture piled up over 100 draws')
	check(not st:GetState(current, 'hover'), 'and it starts at rest')
	close_all()
end)

test('rows hold still: a row never changes height or moves anything on hover', function()
	theme('thick')
	st.Config:Open('Fonts', 'theme')
	local function rect(f) return string.format('%.2f,%.2f,%.2f,%.2f', f:GetLeft(), f:GetTop(), f:GetRight(), f:GetBottom()) end
	local rows = OW.GetDrawnRows()
	check(#rows > 3, 'rows drawn: ' .. #rows)
	for _, cell in ipairs(rows) do
		local f = cell.frame
		local before = { rect(f), rect(cell.label), cell.widget and rect(cell.widget.frame) or '', f:GetHeight() }
		enter(f)
		if cell.widget then enter(cell.widget.frame) end
		local after = { rect(f), rect(cell.label), cell.widget and rect(cell.widget.frame) or '', f:GetHeight() }
		eq(table.concat(after, ' '), table.concat(before, ' '), (cell.row.key or '?') .. ': nothing moves or resizes under the mouse')
		if cell.widget then leave(cell.widget.frame) end
		leave(f)
	end
	close_all()
end)

------------------------------------------------------------------ Blizzard, pixels, cost

test('under Blizzard: every control wears its art and no SaftUI piece shows (T.round_trip)', function()
	SL.each_look(function(name)
		local blizzard = name == 'blizzard'
		local toggle = widget('toggle', { value = true })
		local input = widget('input', { value = 'x' })
		local button = put(W.Button(new_parent(), 'Go', function() end))
		W.LookControl(button, blizzard)
		for key, frame in pairs({ toggle = toggle.frame, input = input.frame, button = button }) do
			enter(frame)
			local l = look(frame)
			eq(l.blizzard, blizzard, name .. ' ' .. key .. ': the helper knows the look')
			if blizzard then
				check(not lit(l.layer) and not lit(l.fill) and not lit(l.mark), name .. ' ' .. key .. ": none of SaftUI's pieces show")
			else
				check(lit(l.layer), name .. ' ' .. key .. ': the tint shows')
			end
			leave(frame)
		end
		toggle:Release(); input:Release()
	end)
end)

test('whole pixels: the bars and pieces under Thick, Thin and Blizzard (P.off == 0, size noise)', function()
	for _, noise in ipairs({ 0, 1 }) do
		stub.size_noise = noise
		SL.each_look(function(name)
			st.Config:Open('Fonts', 'theme')
			local F = frames()
			local tab, item
			for _, t in ipairs(F.tabs) do if t.active then tab = t end end
			for _, i in ipairs(F.nav) do if i.key and i.active then item = i end end
			enter(item); enter(tab)
			local off = {}
			for _, root in ipairs({ item, tab, F.search }) do for _, o in ipairs(P.off(root)) do off[#off + 1] = o end end
			eq(#off, 0, name .. ' noise ' .. noise .. ': ' .. P.report(off))
			leave(item); leave(tab)
			close_all()
		end)
	end
	stub.size_noise = 0
end)

test('a pass over the open window: under 300 calls, nothing made or forbidden, under 4 KB (the Colors page at full size and the sidebar)', function()
	theme('thick')
	st.Config:Open('Fonts', 'colors')
	check(OW:GetWindowSize() == 'full', 'at full size')
	local owner = frames().search
	local w = widget('select', { values = { a = 'A', b = 'B' }, value = 'a' })
	click(w.frame)
	local flip = 0
	local accent_c = st.config.profile.theme.accent
	local keep = { accent_c:GetRGB() }
	local m = C.measure(function()
		flip = 1 - flip
		accent_c:SetRGB(0.2 + flip * 0.1, 0.5, 0.8)
		st:ColorChanged('accent')
	end, 100)
	accent_c:SetRGB(unpack(keep))
	st:ColorChanged('accent')
	local per = m.calls.total / 100
	eq(per, 32, 'calls per pass (measured; the brief budget was under 300)')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
	C.print('the kit, a pass of the accent', m)
	W.CloseList()
	w:Release()
	close_all()
end)

test('the hover Layer and the fade sit inside the box\'s own 1 unit edge (inset 1): the border is never covered', function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Go', function() end))
	enter(b)
	local layer = look(b).pieces.layer
	eq(layer:GetLeft() - b:GetLeft(), 1, 'in 1 on the left')
	eq(b:GetRight() - layer:GetRight(), 1, 'and on the right')
	eq(b:GetTop() - layer:GetTop(), 1, 'and the top')
	leave(b)
end)

test('a disabled number box does not tint under the mouse, and its pressed layer follows the mouse like every input\'s', function()
	theme('thick')
	local value = 5
	local box = put(W.NumberBox(new_parent(), { get = function() return value end, set = function(v) value = v end, tip = function() return 'T', {} end }))
	stub.fire_script(box.edit, 'OnMouseDown', 'LeftButton')
	check(lit(look(box.edit).layer) and st:GetState(box.edit, 'pushed'), 'a press tints the edit box darker')
	eq(string.format('%.2f', look(box.edit).layer.a), string.format('%.2f', select(4, st:StateColor('pushed'))), 'at the pushed strength')
	stub.fire_script(box.edit, 'OnMouseUp', 'LeftButton')
	check(not st:GetState(box.edit, 'pushed'), 'let go')
	W.SetEnabled(box, false)
	enter(box.edit)
	check(not lit(look(box.edit).layer), 'disabled: no hover tint')
	stub.fire_script(box.edit, 'OnMouseDown', 'LeftButton')
	check(not st:GetState(box.edit, 'pushed'), 'and no pushed')
	leave(box.edit)
	W.SetEnabled(box, true)
end)

test("a sidebar page the model says is disabled (a group's disabled) is dimmed, takes no hover tint and cannot be opened", function()
	theme('thick')
	local module = {
		GetConfigTable = function()
			return { name = 'Off page', type = 'group', order = 50, disabled = function() return true end,
				args = { thing = { type = 'toggle', name = 'Thing', get = function() return false end, set = function() end } } }
		end,
	}
	st.modules.StatesOffPage = module
	st.Config:Open('Fonts', 'theme')
	local f
	for _, i in ipairs(frames().nav) do if i.key == 'StatesOffPage' then f = i end end
	check(f, 'the page is in the sidebar')
	check(f.disabled, "the entry came from the model's disabled")
	eq(st:GetState(f, 'disabled'), true, 'a disabled state frame')
	eq(f:GetAlpha(), st:StateAlpha(), 'dimmed to the Disabled opacity')
	enter(f)
	check(not lit(look(f).layer), 'no hover tint')
	check(not st:GetState(f, 'hover'), 'and no hover state')
	click(f)
	local opened = false
	for _, i in ipairs(frames().nav) do if i.key == 'StatesOffPage' and i.active then opened = true end end
	check(not opened, 'a click does not open it')
	leave(f)
	-- an enabled page drawn on the same pooled frame is back at full opacity
	module.GetConfigTable = function()
		return { name = 'Off page', type = 'group', order = 50,
			args = { thing = { type = 'toggle', name = 'Thing', get = function() return false end, set = function() end } } }
	end
	st.Config:Open('Fonts', 'theme')
	for _, i in ipairs(frames().nav) do if i.key == 'StatesOffPage' then f = i end end
	eq(st:GetState(f, 'disabled'), false, 'enabled: not disabled')
	eq(f:GetAlpha(), 1, 'at full opacity')
	st.modules.StatesOffPage = nil
	close_all()
end)

test('a disabled sidebar page is dimmed to the Disabled opacity and takes no hover tint', function()
	theme('thick')
	st.Config:Open('Fonts', 'theme')
	local item
	for _, i in ipairs(frames().nav) do if i.key and not i.active then item = i end end
	item.disabled = true
	OW:Navigate('Fonts', { tab = 'theme' })
	local f
	for _, i in ipairs(frames().nav) do if i.key == item.key then f = i end end
	check(f, 'the page is drawn')
	f.disabled = true
	st:SetState(f, 'disabled', true)
	eq(f:GetAlpha(), st:StateAlpha(), 'dimmed')
	enter(f)
	check(not lit(look(f).layer), 'no tint')
	leave(f)
	close_all()
end)
