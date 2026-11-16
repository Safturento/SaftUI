-- SaftUI-Core/Widgets/states.lua's textKeep option: a kit box's label keeps the color it has
-- (its owner's, or the font object's) through every state and turns to the dark text only where
-- the dark reads better than its own color over what is under it (Task 10: gold at Hover 60% is
-- 2.37:1 in Text > Normal). Real: the theme engine, the live colors, the options kit's buttons.
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
	st:AddStates(f, 'box', { text = label, textKeep = true, body = { 0.1, 0.1, 0.1 } })
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
	-- a label that never had a color of its own keeps following the font object
	local g, plain = box()
	local n = 0
	local realPlain = plain.SetTextColor
	plain.SetTextColor = function(...) n = n + 1; return realPlain(...) end
	st:SetState(g, 'hover', true); st:SetState(g, 'hover', false)
	eq(n, 0, 'a label that follows the font object is not made to hold a color')
end)

test('Hover at 60% over a pale Accent: the label turns dark, and its own color is back after', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label = box()
	label:SetTextColor(0.9, 0.9, 0.8)
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.07,0.07,0.07', 'the dark text')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80', 'its own color back')
	-- a caller's own green that reads on the lit body is kept
	label:SetTextColor(0.05, 0.05, 0.05)
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.05,0.05,0.05', 'a color that already reads is left')
	st:SetState(f, 'hover', false)
end)

test('the pick follows the label\'s own color, not Text > Normal', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label = box()
	label:SetTextColor(0.9, 0.9, 0.8)
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.07,0.07,0.07')
	-- the settings come down while it is held: the light reads again, and comes back
	settings({ hover = 0.16 })
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80', 'the pass puts the light back when it reads again')
	settings({ hover = 0.6 })
	eq(T.rgb(label:GetTextColor()), '0.07,0.07,0.07', 'and the dark again')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80')
end)

test('a color its owner sets while the dark text is on is its owner\'s, and stays', function()
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

test('a pass with a state lit and nothing to change writes nothing', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label = box()
	label:SetTextColor(0.9, 0.9, 0.8)
	st:SetState(f, 'hover', true)
	local writes = 0
	local real = label.SetTextColor
	label.SetTextColor = function(...) writes = writes + 1; return real(...) end
	for _ = 1, 10 do st:ColorChanged('accent') end
	eq(writes, 0, 'ten passes, no write')
	st:SetState(f, 'hover', false)
end)

------------------------------------------------------------------ fix round 1: the font object, and the owner while dark

-- A kit-like label: it follows a font object's color until anything sets one of its own.
local function followed_box()
	local fo = CreateFont('SaftUI_TextKeepTestFont' .. tostring(math.random(1e9)))
	fo:SetTextColor(0.9, 0.9, 0.8)
	local f = st:CreateFrame('Button', nil, UIParent)
	f:SetSize(100, 24)
	st:SetTemplate(f, 'theme', 'solid', 'control')
	local label = f:CreateFontString(nil, 'OVERLAY')
	label:SetFontObject(fo)
	st:AddStates(f, 'box', { text = label, textKeep = true, body = { 0.1, 0.1, 0.1 } })
	return f, label, fo
end

local function with_bytes(fn)
	local ok, err = pcall(fn)
	stub.color_bytes = nil
	if not ok then error(err, 0) end
end

test('M1: after a dark write the label follows its font object again, as one never hovered does', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label, fo = followed_box()
	st:SetState(f, 'hover', true)
	eq(T.rgb(label:GetTextColor()), '0.07,0.07,0.07', 'dark')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.90,0.80')
	fo:SetTextColor(0.3, 0.9, 0.3)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.30,0.90,0.30', 'the hovered one follows the new Normal')
end)

test('M1: Text > Normal changed while the dark text is on: leaving shows the new Normal', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label, fo = followed_box()
	st:SetState(f, 'hover', true)
	fo:SetTextColor(0.2, 0.7, 0.9)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.07,0.07,0.07', 'still dark while held')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.20,0.70,0.90', 'the new Normal')
	fo:SetTextColor(0.5, 0.5, 0.1)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.50,0.50,0.10', 'and it keeps following')
end)

test('M1: the same in byte-color mode', function()
	with_bytes(function()
		world()
		stub.color_bytes = true
		gold()
		settings({ hover = 0.6 })
		local f, label, fo = followed_box()
		st:SetState(f, 'hover', true)
		st:SetState(f, 'hover', false)
		fo:SetTextColor(0.3, 0.9, 0.3)
		st:ColorsChanged('text')
		eq(T.rgb(label:GetTextColor()), '0.30,0.90,0.30', 'follows')
		st:SetState(f, 'hover', true)
		fo:SetTextColor(0.2, 0.7, 0.9)
		st:ColorsChanged('text')
		st:SetState(f, 'hover', false)
		eq(T.rgb(label:GetTextColor()), '0.20,0.70,0.90', 'new Normal after leaving')
	end)
end)

test("M1: a caller's own color (Bank Buy's red) survives and is not made to follow the font object", function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label, fo = followed_box()
	label:SetTextColor(0.9, 0.2, 0.2)
	st:SetState(f, 'hover', true)
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', 'its own red back')
	fo:SetTextColor(0.3, 0.9, 0.3)
	st:ColorsChanged('text')
	eq(T.rgb(label:GetTextColor()), '0.90,0.20,0.20', 'and it stays red when Normal changes')
end)

test('L6: an owner recolor while the label is dark, then the dark no longer reads better: the owner\'s color stays', function()
	world()
	gold()
	settings({ hover = 0.6 })
	local f, label = box()
	label:SetTextColor(0.9, 0.9, 0.8)
	st:SetState(f, 'hover', true)
	label:SetTextColor(0.8, 0.9, 1.0)
	settings({ hover = 0.16 })
	eq(T.rgb(label:GetTextColor()), '0.80,0.90,1.00', 'not put back over by the old kept color')
	st:SetState(f, 'hover', false)
	eq(T.rgb(label:GetTextColor()), '0.80,0.90,1.00')
end)
