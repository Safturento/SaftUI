-- SaftUI-Core/Widgets/states.lua's textKeep option: a kit box's label keeps the color it has
-- (its owner's, or the font object's) through every state. There is no flip to a dark text any
-- more (the owner's call, 2026-11-16: the black outline is enough, so the text stays its color
-- even at Hover 60% over a gold Accent). Real: the theme engine, the live colors, the options kit.
local st, ST
local function world()
	reset_world()
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	ST = st.States
end
world()
local T = load_test_file('lib/theme_helpers.lua')

local function box(opts)
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local label = f:CreateFontString(nil, 'OVERLAY')
	st:AddStates(f, 'box', { text = label, textKeep = true })
	return f, label
end

local function settings(t)
	local s = st.config.profile.theme.states
	for k, v in pairs(t) do s[k] = v end
	ST.Changed()
end

local function gold()
	st.config.profile.theme.accent = CreateColor(0.9, 0.78, 0.29)
	ST.Changed()
end

test('at the defaults a label is never written: its own color and the font object stay through hover, pushed and selected', function()
	world()
	local f, label = box()
	label:SetTextColor(0.2, 0.8, 0.3)
	local writes = 0
	local real = label.SetTextColor
	label.SetTextColor = function(...) writes = writes + 1; return real(...) end
	for _, key in ipairs({ 'hover', 'pushed', 'selected' }) do
		st:SetState(f, key, true)
		eq(T.rgb(label:GetTextColor()), '0.20,0.80,0.30', key .. ': its own color')
		st:SetState(f, key, false)
	end
	eq(writes, 0, 'nothing written')
	-- a label that never had a color of its own is not written either
	local g, plain = box()
	local n = 0
	local realPlain = plain.SetTextColor
	plain.SetTextColor = function(...) n = n + 1; return realPlain(...) end
	st:SetState(g, 'hover', true); st:SetState(g, 'hover', false)
	eq(n, 0, 'a label that follows the font object is not made to hold a color')
end)

test('Hover at 60% over a pale Accent: the label keeps its own color, with nothing written', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label = box()
	label:SetTextColor(0.9, 0.9, 0.8)
	local writes = 0
	local real = label.SetTextColor
	label.SetTextColor = function(...) writes = writes + 1; return real(...) end
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80', 'its own color, never the dark')
	for _ = 1, 10 do st:ColorChanged('accent') end
	st:SetState(f, 'hover', false)
	eq(writes, 0, 'no write over the state, a pass or the leave')
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80', 'still its own color')
end)

test('a color its owner sets while a state is lit is its owner\'s, and stays', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label = box()
	label:SetTextColor(0.9, 0.9, 0.8)
	st:SetState(f, 'hover', true)
	label:SetTextColor(0.2, 0.2, 0.9)
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.20,0.20,0.90', "the owner's newest color")
end)

test('F06: a release with no hold never takes the count below zero', function()
	world()
	st:ReleaseColorEdit()
	st:ReleaseColorEdit()
	st:HoldColorEdit()
	check(st:InColorEdit(), 'a hold after stray releases holds')
	st:ReleaseColorEdit()
	check(not st:InColorEdit(), 'and one release lets go')
end)

test('a raw BeginColorEdit is not ended by a holder\'s last release; an edit a holder began is', function()
	world()
	st:BeginColorEdit()
	st:HoldColorEdit(); st:HoldColorEdit()
	st:ReleaseColorEdit(); st:ReleaseColorEdit()
	check(st:InColorEdit(), 'the raw edit goes on after the holders let go')
	st:EndColorEdit()
	check(not st:InColorEdit(), 'its own end ends it')
	-- a holder's own edit, and a second holder over it, end with the last release
	st:HoldColorEdit(); st:HoldColorEdit()
	st:ReleaseColorEdit()
	check(st:InColorEdit(), 'one holder still holds')
	st:ReleaseColorEdit()
	check(not st:InColorEdit(), 'the last release ends the edit the holders began')
	-- the edit a holder began ended raw, then another begun raw: the stale hold does not end it
	st:HoldColorEdit(); st:EndColorEdit(); st:BeginColorEdit()
	st:ReleaseColorEdit()
	check(st:InColorEdit(), 'a later raw edit is not the holders\'')
	st:EndColorEdit()
end)

------------------------------------------------------------------ a font object, with the state still drawn

-- A kit-like label: it follows a font object's color. The helper never writes it (textKeep), so it
-- keeps following the object while a state is drawn, and a Text > Normal change reaches it at once.
local function followed_box()
	local fo = CreateFont('SaftUI_TextKeepTestFont' .. tostring(math.random(1e9)))
	fo:SetTextColor(0.9, 0.9, 0.8)
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local label = f:CreateFontString(nil, 'OVERLAY')
	label:SetFontObject(fo)
	st:AddStates(f, 'box', { text = label, textKeep = true })
	return f, label, fo
end

local function with_bytes(fn)
	local ok, err = pcall(fn)
	stub.color_bytes = nil
	if not ok then error(err, 0) end
end

local function follows_while_lit()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label, fo = followed_box()
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80', 'hovered at Hover 60%: the object\'s color')
	fo:SetTextColor(0.2, 0.7, 0.9)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.20,0.70,0.90', 'the object recolored while hovered: followed at once')
	-- through a held color edit (the picker, then Okay, with the mouse still on the button)
	st:HoldColorEdit()
	fo:SetTextColor(0.9, 0.3, 0.3)
	st:ColorsChanged('text')
	st:ReleaseColorEdit()
	eq(T.rgb(label:GetTextColor()), '0.90,0.30,0.30', 'after a held edit ends, still hovered')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.30,0.30', 'left: the same')
	fo:SetTextColor(0.5, 0.5, 0.1)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.50,0.50,0.10', 'and it still follows')
end

test('a label on a font object follows it while a state is drawn at Hover 60% on a pale Accent, and after', follows_while_lit)

test('the same in byte-color mode', function() with_bytes(function() stub.color_bytes = true; follows_while_lit() end) end)

test("a caller's own color (Bank Buy's red) is kept through hover and selected, and is not made to follow the object", function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label, fo = followed_box()
	label:SetTextColor(0.9, 0.2, 0.2)
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', 'hovered')
	st:SetState(f, 'selected', true)
	fo:SetTextColor(0.1, 0.5, 0.1)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', 'selected, the object recolored: its own red')
	st:SetState(f, 'selected', false); st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', 'left')
end)
