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
	-- a label that never had a color of its own keeps following the font object
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
