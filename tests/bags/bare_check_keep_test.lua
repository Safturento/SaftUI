-- The two bare check boxes the bags restyle keep their own look through every
-- Buttons pass (live colors): the hidden currency's veil (currencies.lua:
-- the checked texture black at 0.6) and the combined bank tab's eye
-- (combinedbank.lua: the checked texture is the open eye in Text > Muted). A
-- 'bare' check box is "restyled by its caller" (Widgets/checkbutton.lua), so
-- its checked texture follows nothing; a whole Buttons pass (the profile
-- update and every theme switch run one), a Buttons > Hover pick and a theme
-- switch must leave both as their callers made them.
--
-- Real: Core's helpers, the real check box widget; the callers' own restyle
-- is repeated here (their worlds are too heavy to build), and the source scan
-- pins that they still ask for the 'bare' style and restyle the checked texture.
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')
local C = load_test_file('lib/color_cost.lua')
local st = T.client('forever')
load_saftui('SaftUI-Core/Widgets/checkbutton.lua')

local function box()
	local check = CreateFrame('CheckButton', nil, UIParent)
	st:SkinCheckButton(check, 'bare') -- what st:CreateCheckButton(nil, parent, 'bare') does after making it
	return check
end

test('both callers still make a bare box and restyle its checked texture', function()
	for _, file in ipairs({ 'SaftUI-Bags/currencies.lua', 'SaftUI-Bags/containers/combinedbank.lua' }) do
		local code = select(1, L.Lex(read_saftui_source(file)))
		check(code:find("'bare'", 1, true), file .. ": a 'bare' check box")
		check(code:find('GetCheckedTexture()', 1, true), file .. ': restyles its checked texture')
	end
end)

local function passes(check, want, label)
	local function read() return T.text(check:GetCheckedTexture():GetVertexColor()) end
	st:ColorsChanged('button')
	eq(read(), want, label .. ': a whole Buttons pass')
	C.edit(st, function()
		st.config.profile.colors.button.hover:SetRGB(0.9, 0.2, 0.6)
		st:ColorChanged('button', 'hover')
		C.step(st)
		eq(read(), want, label .. ': a Buttons > Hover pick, before the edit ends')
		st.config.profile.colors.button.checked:SetRGB(0.2, 0.9, 0.6)
		st:ColorChanged('button', 'checked')
		C.step(st)
		eq(read(), want, label .. ': a Buttons > Checked pick, before the edit ends')
	end)
	T.theme('blizzard'); T.theme('thick')
	eq(read(), want, label .. ': a theme switch')
	for _, group in ipairs(st.COLOR_GROUPS) do st:ColorsChanged(group) end
	eq(read(), want, label .. ': a profile switch (every group, whole)')
	local d = st.defaults.colors.button.hover
	st.config.profile.colors.button.hover:SetRGB(d.r, d.g, d.b)
	st.config.profile.colors.button.checked:SetRGB(d.r, d.g, d.b)
end

test("a hidden currency's veil keeps its black 0.6 through every Buttons pass", function()
	local check = box()
	check:GetCheckedTexture():SetVertexColor(0, 0, 0, .6)
	passes(check, T.text(0, 0, 0, 0.6), 'veil')
end)

test("the combined bank's eye keeps Text > Muted through every Buttons pass", function()
	local check = box()
	local r, g, b = st:Color('text', 'muted'):GetRGB()
	check:GetCheckedTexture():SetVertexColor(r, g, b, 1)
	passes(check, T.text(r, g, b, 1), 'eye')
end)
