-- SaftUI-Core/Widgets/states.lua, the engine's small task: what a UI scale change
-- does to a drawn state, what a restyle and a theme recolor allocate, hover coming
-- back when a control is enabled, and a label recolored by its owner while lit.
-- Real: the theme engine, the scale runtime (st.UIScale:Apply and its pass), the
-- live colors, Core's widgets. The mouse is played by firing scripts.
local st, ST
local function world(w, h)
	reset_world()
	if w then stub.screen_width, stub.screen_height = w, h end
	load_test_file('core/config_helpers.lua')
	load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
	load_saftui('SaftUI-Core/Widgets/scrollbar.lua')
	st = SaftUI
	ST = st.States
end
world()
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')

local function fire(frame, script, ...) stub.fire_script(frame, script, ...) end

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

-- Every point of a state piece, as one string: where it sits.
local function where(piece)
	local out = {}
	for i = 1, piece:GetNumPoints() do
		local point, _, rel, x, y = piece:GetPoint(i)
		out[#out + 1] = ('%s/%s/%.4f/%.4f'):format(point, rel, x, y)
	end
	return table.concat(out, ' ') .. (' w%.4f h%.4f'):format(piece:GetWidth() or 0, piece:GetHeight() or 0)
end

------------------------------------------------------------------ 1. a scale change

local function make_states()
	local out = {}
	local row = st:CreateFrame('Button', nil, UIParent)
	row:SetSize(120, 20)
	st:AddStates(row, 'row')
	local tab = st:CreateFrame('Button', nil, UIParent)
	tab:SetSize(80, 24)
	st:AddStates(tab, 'tab', { barOffset = st:GetLineSize(tab) })
	local box = st:CreateFrame('Button', nil, UIParent)
	box:SetSize(100, 24)
	st:SetTemplate(box, 'theme', 'solid', 'control')
	st:AddStates(box, 'box')
	local check = st:CreateFrame('CheckButton', nil, UIParent)
	check:SetSize(18, 18)
	st:SetTemplate(check, 'theme', 'solid', 'control')
	st:AddStates(check, 'check')
	for _, f in ipairs({ row, tab, box, check }) do
		st:SetState(f, 'selected', true)
		st:SetState(f, 'hover', true)
	end
	out.row, out.tab, out.box, out.check = row, tab, box, check
	return out
end

-- What a fresh set of frames built at the current scale looks like.
local function geometry(set)
	local look = {}
	for name, f in pairs(set) do
		local l = st:StateLook(f)
		local p = l.pieces
		look[name] = { layer = where(p.layer), fill = where(p.fill), bar = p.bar and where(p.bar), mark = p.mark and where(p.mark) }
	end
	return look
end

test('a UI scale change places every state piece again: a row bar, a tab underline and its offset, the layer, fill and mark', function()
	for _, k in ipairs({ 0.75, 1, 1.25 }) do
		world(2560, 1440)
		start_uiscale()
		local U = st.UIScale
		local set = make_states()
		-- every other size in turn, with the states on, then compare with a set built there
		for _, to in ipairs({ k, 1.25 == k and 0.75 or 1.25, k }) do
			local ok = U:Apply({ mode = 'auto', size = to })
			check(ok, 'applied ' .. to)
			local fresh = make_states()
			local got, want = geometry(set), geometry(fresh)
			for name in pairs(set) do
				for piece, here in pairs(got[name]) do
					eq(here, want[name][piece], ('size %s, %s: the %s'):format(to, name, piece))
				end
			end
			local line = st:GetLineSize(set.row)
			local bar = st:StateLook(set.row)
			check(math.abs(bar.bar.width - 2 * line) < 1e-6, ('size %s: a bar is two current lines: %s vs %s'):format(to, bar.bar.width, 2 * line))
			local pixel = st:GetPixelSize(set.row)
			local px = bar.bar.width / pixel
			check(math.abs(px - math.floor(px + 0.5)) < 1e-4, 'whole pixels: ' .. px)
		end
	end
end)

------------------------------------------------------------------ 2. a restyle on a frame that changed nothing

local function crowd()
	local list = {}
	local row = st:CreateFrame('Button', nil, UIParent)
	row:SetSize(120, 20)
	local label = row:CreateFontString(nil, 'OVERLAY')
	local glyph = row:CreateTexture(nil, 'ARTWORK')
	st:AddStates(row, 'row', { text = label, glyph = glyph })
	list[#list + 1] = row
	local box = st:CreateFrame('Button', nil, UIParent)
	box:SetSize(100, 24)
	st:SetTemplate(box, 'theme', 'solid', 'control')
	st:AddStates(box, 'box', { edge = 'theme', text = { box:CreateFontString(nil, 'OVERLAY'), box:CreateFontString(nil, 'OVERLAY') } })
	list[#list + 1] = box
	local icon = CreateFrame('Button', nil, UIParent)
	icon:SetSize(24, 24)
	local hover, pushed = icon:CreateTexture(nil, 'OVERLAY'), icon:CreateTexture(nil, 'OVERLAY')
	st:AddStates(icon, 'icon', { pieces = { hover = hover, pushed = pushed } })
	list[#list + 1] = icon
	list[#list + 1] = button('Game Menu')
	list[#list + 1] = checkbox()
	return list
end

test('100 restyles of an unchanged frame make under 1 KB; 100 paints too', function()
	world()
	local list = crowd()
	-- at rest: a hovered label's stand-in goes through the stubs' own color wrapper, which is theirs, not the engine's
	for _, f in ipairs(list) do st:RestyleStates(f) end
	local m = C.measure(function()
		for _, f in ipairs(list) do st:RestyleStates(f) end
	end, 100)
	check(m.kb < 1, 'restyle garbage over 100 rounds of ' .. #list .. ' frames: ' .. m.kb .. ' KB')
	local p = C.measure(function()
		for _, f in ipairs(list) do st:PaintStates(f) end
	end, 100)
	check(p.kb < 1, 'paint garbage: ' .. p.kb .. ' KB')
	local icon = list[3]
	local one = C.measure(function() st:RestyleStates(icon) end, 100)
	check(one.kb < 1, 'the game menu micro button (an icon with pieces), 100 restyles: ' .. one.kb .. ' KB')
end)

------------------------------------------------------------------ 3. a theme recolor

test('a theme recolor over 100 buttons, 50 check boxes and 50 thumbs: the helpers add no garbage', function()
	world()
	local frames = {}
	for _ = 1, 100 do frames[#frames + 1] = button() end
	for _ = 1, 50 do frames[#frames + 1] = checkbox() end
	for _ = 1, 50 do
		local bar = scrollBar()
		st:SkinNewScrollBar(bar)
		frames[#frames + 1] = bar:GetThumb()
	end
	st:RecolorThemed()
	local with = C.measure(function() st:RecolorThemed() end, 100)
	eq(with.forbidden.total, 0, 'nothing forbidden')
	eq(with.made, 0, 'nothing made')
	-- the same pass with the 150 theme-edge records gone is the base (the thumbs stay: their own redraw paints them)
	local n = 0
	for i = 1, 150 do st:RemoveStates(frames[i]); n = n + 1 end -- the buttons and check boxes (theme edge: Kept)
	st:RecolorThemed()
	local base = C.measure(function() st:RecolorThemed() end, 100)
	C.print('recolor with', with); C.print('recolor base', base)
	print(('  recolor garbage: with %.1f KB, base %.1f KB'):format(with.kb, base.kb))
	check(with.kb - base.kb < 50, ('the helpers add %.1f KB over 100 passes'):format(with.kb - base.kb))
end)

------------------------------------------------------------------ 4. enabled again under the mouse

local function mouse_over(frame)
	local l, r, b, t = frame:GetLeft(), frame:GetRight(), frame:GetBottom(), frame:GetTop()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = (l + r) / 2 * scale, (b + t) / 2 * scale
end

test('a widget enabled again while the mouse is over it shows hover again', function()
	world()
	local b = button()
	b:EnableMouse(true)
	b:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	mouse_over(b)
	fire(b, 'OnEnter', true)
	check(st:StateLook(b).layer.shown, 'hover shows')
	b:Disable()
	check(not st:StateLook(b).layer.shown, 'disabled: no hover')
	b:Enable()
	eq(st:GetState(b, 'hover'), true, 'enabled under the mouse: hover is back')
	check(st:StateLook(b).layer.shown, 'and drawn')
	-- the mouse elsewhere: no hover
	b:Disable()
	stub.cursor_x, stub.cursor_y = -500, -500
	b:Enable()
	eq(st:GetState(b, 'hover'), false, 'the mouse away: no hover')
	-- a state frame set by hand
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(50, 20)
	f:EnableMouse(true)
	f:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	st:AddStates(f, 'box')
	mouse_over(f)
	st:SetState(f, 'disabled', true)
	st:SetState(f, 'disabled', false)
	eq(st:GetState(f, 'hover'), true, 'the helper restores hover on leaving disabled')
	-- a caller that sets hover itself sees no change
	st:SetState(f, 'disabled', true); st:SetState(f, 'disabled', false); st:SetState(f, 'hover', true)
	eq(st:GetState(f, 'hover'), true)
end)

------------------------------------------------------------------ 5. a label recolored while lit

test("a label recolored by its owner while a state is drawn on it comes back at rest in the owner's color", function()
	world()
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local label = f:CreateFontString(nil, 'OVERLAY')
	label:SetTextColor(1, 1, 1)
	st:AddStates(f, 'box', { text = label, textRest = function() return 1, 1, 1 end })
	st:SetState(f, 'hover', true)
	label:SetTextColor(0.9, 0.2, 0.2)
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', "the owner's newest color is back")
	-- recolored, then a pass paints, then rest
	st:SetState(f, 'hover', true)
	label:SetTextColor(0.1, 0.8, 0.3)
	st:ColorChanged('accent')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.10,0.80,0.30', 'also across a pass')
	-- nobody recolored: textRest as before
	st:SetState(f, 'hover', true); st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '1.00,1.00,1.00', 'a cycle nobody recolored: textRest, as before')
	local g = st:CreateFrame('Button', nil, UIParent)
	g:SetSize(100, 24)
	st:SetTemplate(g, 'theme', 'solid', 'control')
	local l2 = g:CreateFontString(nil, 'OVERLAY')
	l2:SetTextColor(0.5, 0.5, 0.5)
	st:AddStates(g, 'box', { text = l2, textRest = function() return 0.3, 0.4, 0.5 end })
	st:SetState(g, 'hover', true); st:SetState(g, 'hover', false)
	eq(T.rgb(l2:GetTextColor()), '0.30,0.40,0.50', 'no owner recolor: textRest comes back')
	-- a Core button: Buy in Danger, recolored while hovered
	local b = button()
	local danger = st:Color('text', 'danger')
	b.text:SetTextColor(danger.r, danger.g, danger.b)
	fire(b, 'OnEnter', true)
	b.text:SetTextColor(0.2, 0.9, 0.9)
	fire(b, 'OnLeave', true)
	eq(T.rgb(b.text:GetTextColor()), '0.20,0.90,0.90', 'a Core button: the newest color')
	fire(b, 'OnEnter', true); fire(b, 'OnLeave', true)
	eq(T.rgb(b.text:GetTextColor()), '0.20,0.90,0.90', 'and it stays through the next hover')
end)

------------------------------------------------------------------ fix round 1

-- (a world's reset replaces the stub: the switch goes on after it, off again at the end)
local function with_bytes(fn)
	local ok, err = pcall(fn)
	stub.color_bytes = nil
	if not ok then error(err, 0) end
end
local function bytes_world() world(); stub.color_bytes = true end

test('H1: on a client that keeps label colors as bytes, a tab, a kit row and a Core button are back at rest after a hover', function()
	with_bytes(function()
		bytes_world()
		local muted = st:Color('text', 'muted')
		local function labelled(shape)
			local f = st:CreateFrame('Button', nil, UIParent)
			f:SetSize(100, 24)
			st:SetTemplate(f, 'theme', 'solid', 'control')
			local label = f:CreateFontString(nil, 'OVERLAY')
			label:SetTextColor(muted.r, muted.g, muted.b)
			st:AddStates(f, shape, { text = label, textRest = function() return muted.r, muted.g, muted.b end })
			return f, label
		end
		for _, shape in ipairs({ 'tab', 'row' }) do
			local f, label = labelled(shape)
			local want = T.rgb(label:GetTextColor())
			st:SetState(f, 'hover', true)
			st:ColorChanged('accent')
			st:SetState(f, 'hover', false)
			eq(T.rgb(label:GetTextColor()), want, shape .. ': back at Muted')
			st:SetState(f, 'selected', true); st:SetState(f, 'selected', false)
			eq(T.rgb(label:GetTextColor()), want, shape .. ': and after selecting')
		end
		local b = button()
		local want = T.rgb(b.text:GetTextColor())
		fire(b, 'OnEnter', true); st:ColorChanged('accent'); fire(b, 'OnLeave', true)
		eq(T.rgb(b.text:GetTextColor()), want, 'a Core button: white again')
		fire(b, 'OnEnter', true); fire(b, 'OnLeave', true)
		eq(T.rgb(b.text:GetTextColor()), want, 'and the next hover')
	end)
end)

test('H1: an owner recolor still comes back in byte mode; one under a byte and a half does not count', function()
	with_bytes(function()
		bytes_world()
		local f = st:CreateFrame('Button', nil, UIParent)
		f:SetSize(100, 24)
		st:SetTemplate(f, 'theme', 'solid', 'control')
		local label = f:CreateFontString(nil, 'OVERLAY')
		st:AddStates(f, 'box', { text = label, textRest = function() return 1, 1, 1 end })
		st:SetState(f, 'hover', true)
		label:SetTextColor(0.9, 0.2, 0.2)
		st:SetState(f, 'hover', false)
		eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', "the owner's color")
	end)
	world()
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local label = f:CreateFontString(nil, 'OVERLAY')
	st:AddStates(f, 'box', { text = label, textRest = function() return 1, 1, 1 end })
	st:SetState(f, 'hover', true)
	local r, g, b = label:GetTextColor()
	label:SetTextColor(r + 1 / 255, g, b)
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '1.00,1.00,1.00', 'a one-byte change is the painted color: textRest')
	st:SetState(f, 'hover', true)
	r, g, b = label:GetTextColor()
	label:SetTextColor(r + 4 / 255, g, b)
	st:SetState(f, 'hover', false)
	check(label:GetTextColor() ~= 1, 'four bytes is the owner')
end)

test('H1: a secret color value never reaches the compare', function()
	world()
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local label = f:CreateFontString(nil, 'OVERLAY')
	st:AddStates(f, 'box', { text = label, textRest = function() return 1, 1, 1 end })
	st:SetState(f, 'hover', true)
	local real = label.GetTextColor
	local secret = {}
	local saved = _G.issecretvalue
	_G.issecretvalue = function(v) return v == secret or (saved and saved(v)) end
	label.GetTextColor = function() return secret, secret, secret, 1 end
	local ok, err = pcall(st.SetState, st, f, 'hover', false)
	label.GetTextColor = real
	_G.issecretvalue = saved
	check(ok, 'no error comparing a secret: ' .. tostring(err))
end)

test('M1: enabled again, hover only for a visible frame that has the mouse focus', function()
	world()
	local b = button()
	b:EnableMouse(true)
	b:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	mouse_over(b)
	local cover = CreateFrame('Frame', nil, UIParent)
	cover:SetFrameStrata('DIALOG'); cover:EnableMouse(true)
	cover:SetAllPoints(UIParent)
	b:Disable(); b:Enable()
	eq(st:GetState(b, 'hover'), false, 'a frame under another under the cursor: no hover')
	cover:Hide()
	b:Disable(); b:Enable()
	eq(st:GetState(b, 'hover'), true, 'uncovered: hover')
	b:Disable(); b:Hide(); b:Enable()
	eq(st:GetState(b, 'hover'), false, 'hidden: none')
end)

test('L2: a barOffset is one line or units; barLines says more lines', function()
	world(2560, 1440)
	start_uiscale()
	local function tab(offset, lines)
		local f = st:CreateFrame('Button', nil, UIParent)
		f:SetSize(80, 24)
		st:AddStates(f, 'tab', { barOffset = offset, barLines = lines })
		st:SetState(f, 'selected', true)
		return f
	end
	local line = st:GetLineSize(UIParent)
	local one, two, units = tab(line), tab(nil, 2), tab(2 * line)
	local function y(f) return select(5, st:StateLook(f).pieces.bar:GetPoint(1)) end
	st.UIScale:Apply({ mode = 'auto', size = 1.25 })
	local now = st:GetLineSize(UIParent)
	check(math.abs(y(one) + now) < 1e-6, 'one line follows the line: ' .. y(one))
	check(math.abs(y(two) + 2 * now) < 1e-6, 'barLines = 2 follows it: ' .. y(two))
	check(math.abs(y(units) + 2 * line) < 1e-6, 'two lines in units stay units: ' .. y(units))
end)

test('L3: two labels are each checked and restored on their own', function()
	world()
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local a, b = f:CreateFontString(nil, 'OVERLAY'), f:CreateFontString(nil, 'OVERLAY')
	st:AddStates(f, 'box', { text = { a, b }, textRest = function() return 1, 1, 1 end })
	st:SetState(f, 'hover', true)
	b:SetTextColor(0.2, 0.9, 0.9)
	st:SetState(f, 'hover', false)
	eq(T.rgb(a:GetTextColor()), '1.00,1.00,1.00', 'label 1: textRest')
	eq(T.rgb(b:GetTextColor()), '0.20,0.90,0.90', "label 2: its owner's")
	-- a merge that shortens the list leaves the dropped label alone
	st:AddStates(f, 'box', { text = { a } })
	st:SetState(f, 'hover', true)
	local dropped = T.rgb(b:GetTextColor())
	eq(dropped, '0.20,0.90,0.90', 'the dropped label is not painted')
end)

test('L4: an erroring record is reported once, the others are still kept and placed again; one registration', function()
	world()
	local calls = 0
	local keep, onchanged = st.KeepOwnColors, st.UIScale.OnChanged
	st.KeepOwnColors = function(...) calls = calls + 1; return keep(...) end
	st.UIScale.OnChanged = function(...) calls = calls + 100; return onchanged(...) end
	local bad, good = false, nil
	local function make(fail)
		local f = st:CreateFrame('Button', nil, UIParent)
		f:SetSize(100, 24)
		st:SetTemplate(f, 'theme', 'solid', 'control')
		st:AddStates(f, 'box', { edge = 'theme', blizzard = function() if fail and bad then error('boom') end return false end })
		st:SetState(f, 'selected', true)
		return f
	end
	local a, b, c = make(true), make(false), make(false)
	eq(calls, 101, 'the walker and the scale callback registered once for three records')
	st.KeepOwnColors, st.UIScale.OnChanged = keep, onchanged
	start_uiscale()
	take_errors()
	bad = true
	st:RecolorThemed(); st:RecolorThemed(); st:RecolorThemed()
	local errs = take_errors()
	eq(#errs, 1, 'reported once over three recolors')
	st.UIScale:Apply({ mode = 'auto', size = 1.25 })
	eq(#take_errors(), 0, 'and not again by the scale pass')
	local edge = st:StateLook(b).edge
	local accent = st:Color('accent')
	check(edge and math.abs(edge.r - accent.r) < 0.01 and math.abs(edge.b - accent.b) < 0.01, 'the others keep their accent edge')
end)

test('L4: a merge that changes only barOffset moves the bar', function()
	world()
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(80, 24)
	st:AddStates(f, 'tab')
	st:SetState(f, 'selected', true)
	local y0 = select(5, st:StateLook(f).pieces.bar:GetPoint(1))
	st:AddStates(f, 'tab', { barOffset = 3 })
	local y1 = select(5, st:StateLook(f).pieces.bar:GetPoint(1))
	check(y1 ~= y0, 'moved: ' .. y0 .. ' to ' .. y1)
end)

------------------------------------------------------------------ Task 11: the engine's nits

local function labelled(n, opts)
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local labels = {}
	for i = 1, n do labels[i] = f:CreateFontString(nil, 'OVERLAY') end
	local o = { text = labels, textRest = function() return 1, 1, 1 end }
	for k, v in pairs(opts or {}) do o[k] = v end
	st:AddStates(f, 'box', o)
	return f, labels
end

test("N1: the owner-color table is made by AddStates, never inside a pass", function()
	world()
	local f, labels = labelled(2)
	check(st:StateLook(f).ownMade, 'made at registration')
	-- a label recolored by its owner while lit is noted in the same table
	st:SetState(f, 'hover', true)
	labels[1]:SetTextColor(0.2, 0.9, 0.9)
	st:SetState(f, 'hover', false)
	eq(T.rgb(labels[1]:GetTextColor()), '0.20,0.90,0.90', "and still comes back in the owner's color")
end)

test("N2: a record's error is reported again when it fails again after it ran clean", function()
	world()
	local bad = false
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	st:AddStates(f, 'box', { edge = 'theme', blizzard = function() if bad then error('boom') end return false end })
	take_errors()
	bad = true
	st:RecolorThemed(); st:RecolorThemed()
	eq(#take_errors(), 1, 'a failing record: once over two recolors')
	bad = false
	st:RecolorThemed()
	eq(#take_errors(), 0, 'it runs clean')
	bad = true
	st:RecolorThemed(); st:RecolorThemed()
	eq(#take_errors(), 1, 'and fails again: reported again, once')
end)

test('N3: a merge that gives fewer labels forgets the dropped ones; a later merge with more starts clean', function()
	world()
	local f, labels = labelled(2)
	st:SetState(f, 'hover', true)
	labels[2]:SetTextColor(0.2, 0.9, 0.9) -- its owner's, while lit
	st:ColorChanged('accent') -- a pass notes it (slot 2)
	st:AddStates(f, 'box', { text = { labels[1] } })
	local fresh2 = f:CreateFontString(nil, 'OVERLAY')
	-- (the color the lit label is painted in, so that it is no owner's color of its own)
	fresh2:SetTextColor(labels[1]:GetTextColor())
	st:AddStates(f, 'box', { text = { labels[1], fresh2 } })
	st:SetState(f, 'hover', false)
	eq(T.rgb(fresh2:GetTextColor()), '1.00,1.00,1.00', "the new second label gets textRest, not the dropped one's owner color")
end)
