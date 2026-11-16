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
	for _, f in ipairs(list) do st:SetState(f, 'hover', true) end
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
