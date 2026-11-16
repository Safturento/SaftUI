-- SaftUI-Core/Widgets/states.lua: the helpers that draw a state (st:AddStates,
-- st:SetState, st:PaintStates, st:RestyleStates, st:RemoveStates), read back
-- through st:StateLook. Real: the theme engine (st:SetTemplate, the Blizzard
-- look), the live color mechanism, the stubs' textures and scripts. The mouse
-- is played by firing scripts (OnEnter with `true`, as the game passes motion).
-- The cost cases use tests/lib/color_cost.lua (the live colors plan's budget).
-- A fresh world with Core's real config (the Theme tab's switch runs
-- Config:UpdateConfig), the helpers loaded, the profile filled from the defaults.
local st, ST
local function world()
	reset_world()
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	ST = st.States
end
world()
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')

local ACCENT = '00adf0'
local PLUS, MINUS = '5cc6ff', '0093cd' -- T+ and T- of the default Accent at the defaults

local function bytes_of(r, g, b) return SL.bytes({ r = r, g = g, b = b }) end

-- Each byte within 1 (the shipped Accent is (0, 0.68, 0.94), not #00adf0 to the byte).
local function near_hex(label, got, want)
	local t = { r = tonumber(got:sub(1, 2), 16) / 255, g = tonumber(got:sub(3, 4), 16) / 255, b = tonumber(got:sub(5, 6), 16) / 255 }
	check(SL.near(t, want), label .. ': ' .. tostring(got) .. ' ~ ' .. want)
end

local function box(w, h)
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(w or 100, h or 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	return f
end

local function fire(frame, script, ...) stub.fire_script(frame, script, ...) end

-- The edge as T.edge reads it when it is the accent, at 1.
local function edge_accent()
	local c = st:Color('accent')
	return T.text(c.r, c.g, c.b, 1)
end

local function with_settings(over, fn)
	local saved = st.config.profile.theme.states
	local keep = {}
	for k, v in pairs(over) do keep[k] = saved[k]; saved[k] = v end
	ST.Changed()
	local ok, err = pcall(fn)
	for k in pairs(over) do saved[k] = keep[k] end
	ST.Changed()
	if not ok then error(err, 0) end
end

local function with_accent(r, g, b, fn)
	local c = st:Color('accent')
	local keep = { c.r, c.g, c.b }
	c:SetRGB(r, g, b)
	ST.Changed()
	local ok, err = pcall(fn)
	c:SetRGB(unpack(keep))
	ST.Changed()
	if not ok then error(err, 0) end
end

test("a box: rest is untouched; hover tints the body inside the edge, under the text", function()
	world()
	local f = box()
	local fill, edge = T.fill(f), T.edge(f)
	st:AddStates(f, 'box', { edge = 'theme' })
	eq(T.fill(f), fill, 'the fill after AddStates'); eq(T.edge(f), edge, 'the edge after AddStates')
	local look = st:StateLook(f)
	check(not look.layer.shown and not look.fill.shown, 'nothing shows at rest')
	st:SetState(f, 'hover', true)
	look = st:StateLook(f)
	check(look.layer.shown, 'the layer shows')
	near_hex('hover is T+', SL.bytes(look.layer), PLUS)
	eq(look.layer.a, 0.16); eq(look.layer.blend, 'BLEND'); eq(look.layer.layer, 'ARTWORK'); eq(look.layer.sublevel, -8)
	local inset = st:DrawnInset(f)
	check(inset and inset > 0, 'drawn with an inset')
	local point, _, _, x, y = look.pieces.layer:GetPoint(1)
	eq(point, 'TOPLEFT'); eq(x, inset); eq(y, -inset)
	local _, _, _, x2, y2 = look.pieces.layer:GetPoint(2)
	eq(x2, -inset); eq(y2, inset)
	eq(T.edge(f), edge, 'the edge unchanged'); eq(T.fill(f), fill, 'and the body')
	st:SetState(f, 'hover', false)
	check(not st:StateLook(f).layer.shown, 'hover off hides it')
	eq(st:GetState(f, 'hover'), false)
end)

test('hover and pushed follow the mouse: OnEnter, OnLeave, OnMouseDown, OnMouseUp, OnHide', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	fire(f, 'OnEnter', true)
	eq(st:GetState(f, 'hover'), true)
	fire(f, 'OnMouseDown', 'LeftButton')
	eq(st:GetState(f, 'pushed'), true)
	fire(f, 'OnLeave', true)
	eq(st:GetState(f, 'hover'), false); eq(st:GetState(f, 'pushed'), true, 'leaving while held keeps pushed')
	fire(f, 'OnMouseUp', 'LeftButton')
	eq(st:GetState(f, 'pushed'), false, 'let go')
	fire(f, 'OnMouseDown', 'RightButton')
	eq(st:GetState(f, 'pushed'), false, 'the right button pushes nothing')
	fire(f, 'OnEnter', true); fire(f, 'OnMouseDown', 'LeftButton'); f:Hide()
	eq(st:GetState(f, 'hover'), false); eq(st:GetState(f, 'pushed'), false, 'hidden: both off')
end)

test('pushed wins over hover; a disabled box ignores both and dims', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'hover', true); st:SetState(f, 'pushed', true)
	local look = st:StateLook(f)
	near_hex('pushed is T-', SL.bytes(look.layer), MINUS); eq(look.layer.a, 0.32)
	st:SetState(f, 'pushed', false)
	near_hex('back to hover', SL.bytes(st:StateLook(f).layer), PLUS)
	st:SetState(f, 'disabled', true)
	look = st:StateLook(f)
	eq(look.alpha, 0.4); check(not look.layer.shown, 'the layer is hidden'); eq(look.hover, false); eq(look.pushed, false)
	fire(f, 'OnEnter', true); fire(f, 'OnMouseDown', 'LeftButton')
	look = st:StateLook(f)
	check(not look.layer.shown and not look.hover and not look.pushed, 'a later OnEnter and press show nothing')
	st:SetState(f, 'disabled', false)
	eq(st:StateLook(f).alpha, 1)
end)

test('selected: the edge in the accent and a fill fading over 70%; selected + hover in the lighter tone', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'selected', true)
	local look = st:StateLook(f)
	eq(T.edge(f), edge_accent(), 'the edge in the accent at 1')
	check(look.fill.shown, 'the fill shows')
	near_hex('the fill is the accent', SL.bytes(look.fill), ACCENT); eq(look.fill.a, 0.24)
	check(near(look.fill.right, 1 / 0.7), 'it fades over 70%: ' .. look.fill.right)
	eq(look.fill.layer, 'ARTWORK'); eq(look.fill.sublevel, -7); eq(look.fill.texture, st.textures.stateFade); eq(look.fill.blend, 'BLEND')
	check(not look.layer.shown, 'no layer without hover')
	st:SetState(f, 'hover', true)
	look = st:StateLook(f)
	near_hex('hover layer', SL.bytes(look.layer), PLUS); eq(look.layer.a, 0.16)
	near_hex('hover fill', SL.bytes(look.fill), PLUS); eq(look.fill.a, 0.24)
	near_hex('hover edge', SL.bytes(look.edge), PLUS)
	st:SetState(f, 'pushed', true)
	look = st:StateLook(f)
	near_hex('pushed layer', SL.bytes(look.layer), MINUS)
	near_hex('pushed: the fill is the accent', SL.bytes(look.fill), ACCENT)
	near_hex('pushed: the edge is the accent', SL.bytes(look.edge), ACCENT)
	st:SetState(f, 'selected', false); st:SetState(f, 'pushed', false); st:SetState(f, 'hover', false)
	eq(T.edge(f), T.edge(box()), 'the rest edge is back')
	check(not st:StateLook(f).fill.shown, 'and the fill is gone')
end)

test('focus is the accent edge; the body is unchanged', function()
	world()
	local f = box()
	local fill = T.fill(f)
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'focus', true)
	local look = st:StateLook(f)
	eq(T.edge(f), edge_accent()); eq(T.fill(f), fill)
	check(not look.layer.shown and not look.fill.shown, 'no layer, no fill')
	st:SetState(f, 'hover', true)
	check(st:StateLook(f).layer.shown, 'a hover layer composes')
	st:SetState(f, 'focus', false); st:SetState(f, 'hover', false)
	eq(T.edge(f), T.edge(box()), 'the rest edge is back')
end)

test('a kit box edge is the backdrop border (edge = backdrop), put back to the kit edge', function()
	world()
	local f = st:CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
	f:SetSize(80, 20)
	f:SetBackdrop({ bgFile = st.BLANK_TEX, edgeFile = st.BLANK_TEX, edgeSize = 1 })
	f:SetBackdropBorderColor(unpack(st.BOX_COLORS.edge))
	st:AddStates(f, 'box', { edge = 'backdrop', inset = 1 })
	st:SetState(f, 'selected', true)
	eq(T.edge(f), edge_accent())
	local _, _, _, x = st:StateLook(f).pieces.layer:GetPoint(1)
	eq(x, 1, 'the given inset')
	st:SetState(f, 'selected', false)
	eq(T.edge(f), T.text(unpack(st.BOX_COLORS.edge)), 'the kit edge back')
	-- a function edge gets (frame, r, g, b) and (frame, nil)
	local calls = {}
	local g = CreateFrame('Frame', nil, UIParent)
	g:SetSize(10, 10)
	st:AddStates(g, 'box', { edge = function(frame, r, gg, b) calls[#calls + 1] = { frame, r, gg, b } end })
	st:SetState(g, 'selected', true); st:SetState(g, 'selected', false)
	eq(#calls, 2); eq(calls[1][1], g); check(type(calls[1][2]) == 'number', 'a color'); eq(calls[2][2], nil)
end)

scaled_test('a row: bar two lines at its left, a tab: two lines along its bottom', function()
	world()
	local row = st:CreateFrame('Button', nil, UIParent)
	row:SetSize(120, 20)
	st:AddStates(row, 'row', { text = nil })
	local look = st:StateLook(row)
	check(not look.bar.shown and not look.layer.shown, 'rest')
	st:SetState(row, 'selected', true)
	look = st:StateLook(row)
	check(look.bar.shown, 'selected: the bar')
	check(near(look.bar.width, 2 * st:GetLineSize(row)), 'two lines: ' .. look.bar.width)
	if test_scale() == 1 then eq(look.bar.width, 2, 'at k 1 it is 2 wide') end
	local p1, p2 = look.pieces.bar:GetPoint(1), look.pieces.bar:GetPoint(2)
	eq(p1, 'TOPLEFT'); eq(p2, 'BOTTOMLEFT')
	near_hex('the bar is the accent', SL.bytes(look.bar), ACCENT)
	check(look.fill.shown, 'with the fill')
	st:SetState(row, 'hover', true)
	near_hex('hover: the bar in the lighter tone', SL.bytes(st:StateLook(row).bar), PLUS)
	eq(st:StateLook(row).edge, nil, 'a row has no edge')
	-- a tab
	local tab = st:CreateFrame('Button', nil, UIParent)
	tab:SetSize(80, 24)
	st:AddStates(tab, 'tab')
	st:SetState(tab, 'selected', true)
	look = st:StateLook(tab)
	check(near(look.bar.width, 2 * st:GetLineSize(tab)), 'a tab: two lines tall: ' .. look.bar.width)
	eq(look.pieces.bar:GetPoint(1), 'BOTTOMLEFT'); eq(look.pieces.bar:GetPoint(2), 'BOTTOMRIGHT')
end)

scaled_test('a check: edge, mark and fill when selected; the mark floor(size / 6) in', function()
	world()
	for _, size in ipairs({ 18, 12, 8 }) do
		local f = st:CreateFrame('CheckButton', nil, UIParent)
		f:SetSize(size, size)
		st:SetTemplate(f, 'theme', 'solid', 'control')
		st:AddStates(f, 'check', { edge = 'theme' })
		local look = st:StateLook(f)
		check(not look.mark.shown, size .. ': no mark at rest')
		st:SetState(f, 'selected', true)
		look = st:StateLook(f)
		check(look.mark.shown and look.fill.shown, size .. ': mark and fill')
		eq(T.edge(f), edge_accent(), size .. ': the edge')
		near_hex(size .. ' mark', SL.bytes(look.mark), ACCENT)
		local _, _, _, x, y = look.pieces.mark:GetPoint(1)
		eq(x, st:RoundToPixel(math.floor(size / 6), f), size .. ': the mark is floor(size / 6) in')
		eq(y, -x)
		if test_scale() == 1 then eq(x, ({ [18] = 3, [12] = 2, [8] = 1 })[size]) end
		st:SetState(f, 'hover', true)
		near_hex(size .. ' mark + hover', SL.bytes(st:StateLook(f).mark), PLUS)
	end
	-- a mark the caller gives is positioned and colored, nothing new made
	local f = st:CreateFrame('CheckButton', nil, UIParent)
	f:SetSize(12, 12)
	local mark = f:CreateTexture(nil, 'OVERLAY')
	st:AddStates(f, 'check', { mark = mark })
	st:SetState(f, 'selected', true)
	eq(st:StateLook(f).pieces.mark, mark)
end)

test('a thumb and a knob: solid fills from their rest colors', function()
	world()
	local thumb = CreateFrame('Frame', nil, UIParent)
	thumb:SetSize(10, 40)
	st:SetBackdrop(thumb, 'theme', 'solid', 'control')
	local rest = function() return unpack(ST.THUMB_REST) end
	thumb.backdrop:SetBackdropColor(rest())
	st:AddStates(thumb, 'thumb', { solidRest = rest })
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(unpack(ST.THUMB_REST)), 'rest untouched')
	fire(thumb, 'OnEnter', true)
	near_hex('hover is T+', SL.bytes(st:StateLook(thumb).solid), PLUS)
	fire(thumb, 'OnMouseDown', 'LeftButton')
	near_hex('pushed is T-', SL.bytes(st:StateLook(thumb).solid), MINUS)
	fire(thumb, 'OnMouseUp', 'LeftButton'); fire(thumb, 'OnLeave', true)
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(unpack(ST.THUMB_REST)), 'rest comes back')
	-- the knob: a texture
	local slider = CreateFrame('Frame', nil, UIParent)
	slider:SetSize(100, 14)
	local knob = slider:CreateTexture(nil, 'OVERLAY')
	local n = st:Color('text', 'normal')
	knob:SetTexture(st.BLANK_TEX); knob:SetVertexColor(n.r, n.g, n.b)
	st:AddStates(slider, 'knob', { glyph = knob, solidRest = function() return n.r, n.g, n.b end })
	st:SetState(slider, 'hover', true)
	near_hex('the knob under the mouse', SL.bytes(st:StateLook(slider).solid), PLUS)
	st:SetState(slider, 'hover', false)
	eq(T.rgb(knob:GetVertexColor()), T.text(n.r, n.g, n.b), 'and back')
	-- Layers mixes the accent into the rest color
	with_settings({ mode = 'layers' }, function()
		st:SetState(slider, 'hover', true)
		near_hex('layers: the accent mixed in 60%', SL.bytes(st:StateLook(slider).solid), '5cc4e2')
		st:SetState(slider, 'hover', false)
	end)
end)

test("an icon: the game pieces are the button's own highlight, pushed and checked textures, BLEND, colored on every pass", function()
	world()
	local f = CreateFrame('CheckButton', nil, UIParent)
	f:SetSize(36, 36)
	st:AddStates(f, 'icon', { game = true, checked = true })
	local look = st:StateLook(f)
	eq(f:GetHighlightTexture(), look.pieces.hover, 'the highlight is the record\'s hover piece')
	eq(f:GetPushedTexture(), look.pieces.pushed); eq(f:GetCheckedTexture(), look.pieces.checked)
	eq(look.hover_piece.blend, 'BLEND'); eq(look.hover_piece.layer, 'HIGHLIGHT')
	near_hex('hover piece', SL.bytes(look.hover_piece), PLUS); eq(look.hover_piece.a, 0.16)
	near_hex('pushed piece', SL.bytes(look.pushed_piece), MINUS); eq(look.pushed_piece.a, 0.32)
	near_hex('checked piece', SL.bytes(look.checked_piece), ACCENT); eq(look.checked_piece.a, 0.24)
	eq(look.checked_piece.texture, st.textures.stateFade)
	check(near(look.checked_piece.right, 1 / 0.7), 'checked uses the fade: ' .. look.checked_piece.right)
	-- not wired: the game shows them
	fire(f, 'OnEnter', true)
	eq(st:GetState(f, 'hover'), false, 'an icon is not wired')
	-- a pass puts the colors back on, and the new fade
	look.pieces.hover:SetVertexColor(1, 1, 1, 1)
	with_accent(1, 0, 0, function()
		local d = st:StateLook(f)
		check(d.hover_piece.r > 0.9, 'the hover piece follows the accent: ' .. SL.rgb(d.hover_piece))
	end)
	with_settings({ fade = 0.5 }, function()
		check(near(st:StateLook(f).checked_piece.right, 2), 'the fade setting reaches the checked piece')
	end)
	near_hex('back', SL.bytes(st:StateLook(f).hover_piece), PLUS)
	-- selected: the checked texture is the game's; the edge, when asked for, is ours
	local g = st:CreateFrame('CheckButton', nil, UIParent)
	g:SetSize(36, 36)
	st:SetTemplate(g, 'theme', 'solid', 'control')
	st:AddStates(g, 'icon', { game = true, edge = 'theme' })
	st:SetState(g, 'selected', true)
	eq(T.edge(g), edge_accent())
	-- pieces that exist: colored only, nothing made
	local h = CreateFrame('Button', nil, UIParent)
	local hover, pushed, checked = h:CreateTexture(nil, 'HIGHLIGHT'), h:CreateTexture(nil, 'ARTWORK'), h:CreateTexture(nil, 'ARTWORK')
	local regions = #{ h:GetRegions() }
	st:AddStates(h, 'icon', { pieces = { hover = hover, pushed = pushed, checked = checked } })
	eq(#{ h:GetRegions() }, regions, 'no texture made')
	near_hex('given hover', bytes_of(hover:GetVertexColor()), PLUS)
	eq(checked:GetTexture(), st.textures.stateFade, 'a checked piece gets the fade texture once')
	check(near(select(5, checked:GetTexCoord()), 1 / 0.7), 'and its coordinates')
end)

test('a glyph: rest its own color; hover the lighter tone; Layers the accent', function()
	world()
	local f = CreateFrame('Button', nil, UIParent)
	f:SetSize(16, 16)
	local icon = f:CreateTexture(nil, 'OVERLAY')
	local rest = { 0.7, 0.7, 0.7 }
	icon:SetTexture(st.icons.x); icon:SetVertexColor(unpack(rest))
	st:AddStates(f, 'glyph', { glyph = icon, glyphRest = function() return unpack(rest) end })
	eq(T.rgb(icon:GetVertexColor()), '0.70,0.70,0.70', 'rest is its own')
	st:SetState(f, 'hover', true)
	near_hex('hover is T+', SL.bytes(st:StateLook(f).glyph), PLUS)
	st:SetState(f, 'selected', true)
	near_hex('selected + hover', SL.bytes(st:StateLook(f).glyph), PLUS)
	st:SetState(f, 'hover', false)
	near_hex('selected is the accent', SL.bytes(st:StateLook(f).glyph), ACCENT)
	st:SetState(f, 'selected', false)
	eq(T.rgb(icon:GetVertexColor()), '0.70,0.70,0.70', 'rest back')
	with_settings({ mode = 'layers' }, function()
		st:SetState(f, 'hover', true)
		near_hex('layers: the accent', SL.bytes(st:StateLook(f).glyph), ACCENT)
		st:SetState(f, 'hover', false)
	end)
	-- with no glyphRest the rest color is left alone; a list is painted on any shape
	local g = CreateFrame('Button', nil, UIParent)
	local label = g:CreateFontString(nil, 'OVERLAY')
	local other = g:CreateTexture(nil, 'OVERLAY')
	label:SetTextColor(0.5, 0.6, 0.7)
	st:AddStates(g, 'box', { glyph = { label, other } })
	eq(T.rgb(label:GetTextColor()), '0.50,0.60,0.70', 'untouched at rest')
	st:SetState(g, 'hover', true)
	near_hex('a font string in the list', bytes_of(label:GetTextColor()), PLUS)
	near_hex('a texture in the list', bytes_of(other:GetVertexColor()), PLUS)
	st:SetState(g, 'hover', false)
	near_hex('no glyphRest: left as it is', bytes_of(label:GetTextColor()), PLUS)
end)

test('the text on a fill follows the pick, and its rest color comes back', function()
	world()
	local f = box()
	local label = f:CreateFontString(nil, 'OVERLAY')
	label:SetTextColor(0.7, 0.7, 0.7)
	local normal = st:Color('text', 'normal')
	st:AddStates(f, 'box', { edge = 'theme', text = label, textRest = function() return 0.7, 0.7, 0.7 end })
	eq(T.rgb(label:GetTextColor()), '0.70,0.70,0.70', 'rest untouched')
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), T.rgb(normal.r, normal.g, normal.b), 'light over the default composite')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.70,0.70,0.70', 'rest is back')
	-- strong settings and a pale accent: the dark text
	with_accent(230 / 255, 200 / 255, 74 / 255, function()
		with_settings({ mode = 'layers', hover = 0.6 }, function()
			st:SetState(f, 'hover', true)
			eq(T.rgb(label:GetTextColor()), T.rgb(unpack(ST.DARK_TEXT)), 'dark over a strong pale hover')
			st:SetState(f, 'hover', false)
			eq(T.rgb(label:GetTextColor()), '0.70,0.70,0.70')
		end)
	end)
	-- selected: the text follows the fill at its strongest
	st:SetState(f, 'selected', true)
	eq(T.rgb(label:GetTextColor()), T.rgb(normal.r, normal.g, normal.b))
	st:SetState(f, 'selected', false)
	eq(T.rgb(label:GetTextColor()), '0.70,0.70,0.70')
	-- a list of labels, and a body the caller gives
	local g = box()
	local a, b = g:CreateFontString(nil, 'OVERLAY'), g:CreateFontString(nil, 'OVERLAY')
	st:AddStates(g, 'box', { edge = 'theme', text = { a, b }, body = { 0.9, 0.9, 0.9 } })
	st:SetState(g, 'hover', true)
	eq(T.rgb(a:GetTextColor()), T.rgb(unpack(ST.DARK_TEXT)), 'over a pale body the dark text')
	eq(T.rgb(b:GetTextColor()), T.rgb(unpack(ST.DARK_TEXT)))
end)

test('under Blizzard the pieces are held at alpha 0 and the edge is the art', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme', blizzard = function() return true end })
	local borders = 0
	local real = st.SetBorderColor
	st.SetBorderColor = function(...) borders = borders + 1 return real(...) end
	st:SetState(f, 'hover', true)
	local look = st:StateLook(f)
	eq(look.layer.alpha, 0, 'the layer is at alpha 0'); check(look.layer.shown, 'the state is kept')
	st:SetState(f, 'selected', true)
	eq(borders, 0, 'no edge call under Blizzard')
	eq(st:StateLook(f).fill.alpha, 0)
	st.SetBorderColor = real
	-- the round trip: states kept, pieces back at full
	local g = box()
	st:AddStates(g, 'box', { edge = 'theme' })
	st:SetState(g, 'selected', true); st:SetState(g, 'hover', true)
	T.round_trip('box', function(label)
		local look = st:StateLook(g)
		local blizzard = st.config.profile.theme.name == 'blizzard'
		eq(look.selected, true, label .. ': selected kept'); eq(look.hover, true, label .. ': hover kept')
		eq(look.layer.alpha, blizzard and 0 or 1, label .. ': the layer')
		eq(look.fill.alpha, blizzard and 0 or 1, label .. ': the fill')
		check(look.layer.shown and look.fill.shown, label .. ': still shown')
		if not blizzard then near_hex(label .. ': the edge', SL.bytes(look.edge), PLUS) end
	end)
	-- every look keeps its pieces where the inset says
	SL.each_look(function(name)
		local look = st:StateLook(g)
		local inset = st:DrawnInset(g) or 0
		local _, _, _, x = look.pieces.layer:GetPoint(1)
		eq(x, inset, name .. ': the layer is inset by the drawn edge')
	end)
end)

test('AddStates twice merges and makes no second piece; a new shape errors', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	local regions = #{ f:GetRegions() }
	local label = f:CreateFontString(nil, 'OVERLAY')
	regions = regions + 1
	local back = st:AddStates(f, 'box', { text = label })
	eq(back, f, 'returns the frame'); eq(#{ f:GetRegions() }, regions, 'no second piece')
	st:SetState(f, 'selected', true)
	eq(T.edge(f), edge_accent(), 'the first call\'s edge is kept')
	st:SetState(f, 'hover', true)
	check(label:GetTextColor() ~= nil, 'and the second call\'s text is wired')
	local ok, err = pcall(function() st:AddStates(f, 'row') end)
	check(not ok and tostring(err):find('box', 1, true), 'a new shape errors: ' .. tostring(err))
	ok = pcall(function() st:AddStates(f, 'sphere') end)
	check(not ok, 'an unknown shape errors')
	local calls = 0
	fire(f, 'OnLeave', true)
	st:AddStates(f, 'box', {})
	st:AddStates(f, 'box', {})
	fire(f, 'OnEnter', true)
	eq(st:GetState(f, 'hover'), true, 'hooked once, not once per call')
end)

test('RemoveStates forgets the frame: a pass paints nothing of it', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'selected', true); st:SetState(f, 'hover', true)
	local regions = #{ f:GetRegions() }
	st:RemoveStates(f)
	eq(st:StateLook(f), nil, 'no record')
	eq(T.edge(f), T.edge(box()), 'the edge is back to rest')
	local m = C.measure(function() st:ColorChanged('accent') end, 3)
	eq(m.calls.total, 0, 'a pass paints nothing of it')
	fire(f, 'OnEnter', true)
	eq(st:GetState(f, 'hover'), nil, 'its scripts do nothing, and it has no record')
	local ok, err = pcall(function() st:SetState(f, 'hover', true) end)
	check(not ok and tostring(err):find('states_draw_test', 1, true), 'SetState on it errors at the caller: ' .. tostring(err))
	ok = pcall(function() st:PaintStates(f) end)
	check(not ok, 'PaintStates on it errors')
	st:RemoveStates(f) -- twice: nothing
	-- added again: the pieces it had are reused
	st:AddStates(f, 'box', { edge = 'theme' })
	eq(#{ f:GetRegions() }, regions, 'no new piece for a pooled frame')
	-- wired once in its life: one OnEnter sets hover once, however many times it was added and removed
	for _ = 1, 3 do st:RemoveStates(f); st:AddStates(f, 'box', { edge = 'theme' }) end
	eq(#{ f:GetRegions() }, regions, 'still no new piece after more cycles')
	local sets, real = 0, st.SetState
	st.SetState = function(...) sets = sets + 1 return real(...) end
	fire(f, 'OnEnter', true)
	st.SetState = real
	eq(sets, 1, 'one OnEnter, one set')
	eq(st:GetState(f, 'hover'), true)
end)

test('game = true adopts the button\'s own pieces, and leaves them alone under Blizzard', function()
	world()
	local f = CreateFrame('CheckButton', nil, UIParent)
	f:SetSize(36, 36)
	local hl, pushed, checked = f:CreateTexture(nil, 'HIGHLIGHT'), f:CreateTexture(nil, 'ARTWORK'), f:CreateTexture(nil, 'ARTWORK')
	f:SetHighlightTexture(hl); f:SetPushedTexture(pushed); f:SetCheckedTexture(checked)
	local regions = #{ f:GetRegions() }
	local blizzard = false
	st:AddStates(f, 'icon', { game = true, checked = true, blizzard = function() return blizzard end })
	eq(#{ f:GetRegions() }, regions, 'nothing made: the three are adopted')
	eq(f:GetHighlightTexture(), hl); eq(f:GetPushedTexture(), pushed); eq(f:GetCheckedTexture(), checked)
	local look = st:StateLook(f)
	eq(look.pieces.hover, hl); eq(look.hover_piece.blend, 'BLEND'); eq(look.hover_piece.texture, st.BLANK_TEX)
	near_hex('adopted hover colored', SL.bytes(look.hover_piece), PLUS)
	eq(look.checked_piece.texture, st.textures.stateFade)
	-- Blizzard's art draws on them: no color, alpha, texture, coordinates or blend of ours
	blizzard = true
	hl:SetTexture('Interface\\Art\\Hover'); hl:SetBlendMode('ADD'); hl:SetVertexColor(1, 1, 1, 1); hl:SetAlpha(0.5)
	checked:SetTexture('Interface\\Art\\Checked'); checked:SetTexCoord(0, 0.5, 0, 0.5)
	st:RestyleStates(f)
	st:ColorChanged('accent')
	st:SetState(f, 'selected', true)
	look = st:StateLook(f)
	eq(look.hover_piece.texture, 'Interface\\Art\\Hover'); eq(look.hover_piece.blend, 'ADD')
	eq(look.hover_piece.alpha, 0.5); eq(SL.rgb(look.hover_piece), '1.00,1.00,1.00')
	eq(look.checked_piece.texture, 'Interface\\Art\\Checked'); eq(look.checked_piece.right, 0.5)
	-- back to SaftUI's look: RestyleStates puts them right
	blizzard = false
	st:RestyleStates(f)
	look = st:StateLook(f)
	eq(look.hover_piece.texture, st.BLANK_TEX); eq(look.hover_piece.blend, 'BLEND'); eq(f:GetHighlightTexture(), hl)
	near_hex('and colored', SL.bytes(look.hover_piece), PLUS)
	eq(look.checked_piece.texture, st.textures.stateFade)
	check(near(look.checked_piece.right, 1 / 0.7), 'the fade again')
	-- pieces: the same
	local h = CreateFrame('Button', nil, UIParent)
	local hover = h:CreateTexture(nil, 'HIGHLIGHT')
	st:AddStates(h, 'icon', { pieces = { hover = hover }, blizzard = function() return true end })
	hover:SetVertexColor(1, 1, 1, 1)
	st:ColorChanged('accent')
	eq(SL.rgb({ r = select(1, hover:GetVertexColor()), g = select(2, hover:GetVertexColor()), b = select(3, hover:GetVertexColor()) }), '1.00,1.00,1.00', 'pieces untouched under Blizzard')
end)

test("a theme recolor puts a selected box's accent edge back (KeepOwnColors)", function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'selected', true)
	st:SetBorderColor(f, 1, 0, 0, 1)
	st:RecolorThemed()
	eq(T.edge(f), edge_accent(), 'after a recolor')
	st:SetBorderColor(f, 1, 0, 0, 1)
	st:RedrawThemed()
	eq(T.edge(f), edge_accent(), 'after a redraw')
	st:SetState(f, 'selected', false)
	st:RecolorThemed()
	eq(T.edge(f), T.edge(box()), 'at rest the theme\'s own')
end)

test('disabled: the opacity follows the setting through a pass', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'disabled', true)
	eq(f:GetAlpha(), 0.4)
	with_settings({ disabled = 0.25 }, function() eq(f:GetAlpha(), 0.25, 'a pass sets it') end)
	eq(f:GetAlpha(), 0.4)
	st:SetState(f, 'disabled', false)
	eq(f:GetAlpha(), 1)
	local ok = pcall(function() st:SetState(f, 'sleeping', true) end)
	check(not ok, 'an unknown state errors')
	ok = pcall(function() st:SetState(CreateFrame('Frame'), 'hover', true) end)
	check(not ok, 'a frame that is not a state frame errors')
end)

-- 500 icons and 500 boxes at rest, 20 boxes selected
local function crowd()
	local icons, boxes, selected = {}, {}, {}
	for i = 1, 500 do
		local f = CreateFrame('Button', nil, UIParent)
		f:SetSize(36, 36)
		st:AddStates(f, 'icon', { game = true })
		icons[i] = f
	end
	for i = 1, 500 do
		local f = box()
		st:AddStates(f, 'box', { edge = 'theme' })
		boxes[i] = f
		if i <= 20 then st:SetState(f, 'selected', true); selected[i] = f end
	end
	return icons, boxes, selected
end

test('a pass: game pieces always, scripted pieces only while shown, nothing made', function()
	world()
	local icons, boxes = crowd()
	local m = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(m.made, 0, 'nothing made'); eq(m.forbidden.total, 0, 'nothing forbidden: ' .. tostring(next(m.forbidden.by)))
	check(m.kb < 4, 'under 4 KB over 100 passes: ' .. m.kb)
	check(m.calls.total / 100 <= 500 * 2 + 20 * 4, 'calls per pass ' .. m.calls.total / 100)
	C.print('states', m)
	-- the boxes at rest: no setter calls
	for _, f in ipairs(icons) do st:RemoveStates(f) end
	for i = 1, 20 do st:SetState(boxes[i], 'selected', false) end
	local rest = C.measure(function() st:ColorChanged('accent') end, 20)
	eq(rest.calls.total, 0, 'the boxes at rest: 0 setter calls')
end)

test('in combat a pass only colors', function()
	world()
	local icons, boxes = crowd()
	stub.in_combat = true
	local m = C.measure(function() st:ColorChanged('accent') end, 100)
	stub.in_combat = false
	eq(m.made, 0); eq(m.forbidden.total, 0, 'no Show, Hide or SetPoint on any frame: ' .. tostring(next(m.forbidden.by)))
	check(m.kb < 4, 'under 4 KB: ' .. m.kb)
	eq(#stub.blocked, 0, 'nothing blocked')
end)

test('a drag of the accent in an edit: one pass a frame, the states follow', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'selected', true)
	local c = st:Color('accent')
	local keep = { c.r, c.g, c.b }
	C.edit(st, function()
		c:SetRGB(1, 0, 0)
		st:ColorChanged('accent')
		C.step(st)
	end)
	eq(T.edge(f), T.text(1, 0, 0, 1), 'the edge followed the accent')
	c:SetRGB(unpack(keep))
	st:ColorChanged('accent')
end)

test('a frame the theme drew needs no edge option; PaintStates puts a thumb\'s rest color back', function()
	world()
	local f = box()
	st:AddStates(f, 'box')
	st:SetState(f, 'selected', true)
	eq(T.edge(f), edge_accent(), 'a drawn frame colors its edge through the theme by default')
	local thumb = CreateFrame('Frame', nil, UIParent)
	thumb:SetSize(10, 40)
	st:SetBackdrop(thumb, 'theme', 'solid', 'control')
	local rest = function() return unpack(ST.THUMB_REST) end
	st:AddStates(thumb, 'thumb', { solidRest = rest })
	thumb.backdrop:SetBackdropColor(1, 0, 0, 1) -- a redraw reset it
	st:PaintStates(thumb)
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), T.rgb(rest()), 'the rest color is back')
	-- a pass leaves a thumb at rest alone
	thumb.backdrop:SetBackdropColor(1, 0, 0, 1)
	st:ColorChanged('accent')
	eq(T.rgb(thumb.backdrop:GetBackdropColor()), '1.00,0.00,0.00', 'a pass paints nothing at rest')
end)

test('a preview paints a state frame with its own derived table', function()
	world()
	local f = box()
	st:AddStates(f, 'box', { edge = 'theme' })
	st:SetState(f, 'selected', true); st:SetState(f, 'hover', true)
	local d = ST.Derive(1, 0, 0, ST.Settings(), ST.NewDerived())
	st:PaintStates(f, d)
	local look = st:StateLook(f)
	check(look.layer.r > 0.9 and look.layer.g < 0.5, 'the layer wears the preview\'s tone: ' .. SL.rgb(look.layer))
	check(T.edge(f):sub(1, 4) ~= '0.00', 'and the edge')
	st:PaintStates(f)
	near_hex('the cache again', SL.bytes(st:StateLook(f).layer), PLUS)
end)

local P = load_test_file('lib/pixels.lua')

scaled_test('every piece starts and ends on a whole pixel: layer, fill, bar and mark, under every look and size noise', function()
	for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
		world()
		stub.size_noise = noise
		local root = CreateFrame('Frame', nil, UIParent)
		local function R(v) return st:RoundToPixel(v, UIParent) end
		root:SetSize(R(300), R(120))
		root:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', R(100), -R(100))
		local frames = {}
		local function add(kind, shape, x, y, w, h, selected)
			local f = st:CreateFrame(kind, nil, root)
			f:SetSize(R(w), R(h))
			f:SetPoint('TOPLEFT', root, 'TOPLEFT', R(x), -R(y))
			st:SetTemplate(f, 'theme', 'solid', 'control')
			st:AddStates(f, shape, { edge = 'theme' })
			st:SetState(f, 'selected', true); st:SetState(f, 'hover', true)
			frames[#frames + 1] = f
		end
		add('Button', 'box', 0, 0, 100, 24)
		add('Button', 'row', 110, 0, 120, 20)
		add('Button', 'tab', 0, 40, 80, 24)
		add('CheckButton', 'check', 100, 40, 18, 18)
		add('CheckButton', 'check', 130, 40, 12, 12)
		add('CheckButton', 'check', 150, 40, 8, 8)
		SL.each_look(function(look)
			local off = P.off(root)
			eq(#off, 0, ('noise %s, %s: %s'):format(tostring(noise), look, P.report(off)))
		end)
		stub.size_noise = 0
	end
end)
