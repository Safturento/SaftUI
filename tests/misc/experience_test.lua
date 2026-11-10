-- SaftUI-Misc/experience.lua: the XP bar's frame levels (backdrop below the
-- rested part below the fill), the Experience and Rested color options, and the
-- bars drawn as bars in the page's Theme and Background.
-- Migrated from the xpsim harness. The config is Core's real defaults, and
-- the frames come from Core's real helpers (st:SetBackdrop and the rest).
load_core_helpers()
local T = load_test_file('lib/theme_draws.lua')
local drawn = T.watch()
-- Blizzard's minimap, which the bar's default position anchors to (the profile
-- has Core's real defaults).
CreateFrame('Frame', 'Minimap', UIParent)
for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
	load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua') -- EditMode/load.xml's order; the bar registers a mover
end
load_saftui('SaftUI-Misc/experience.lua')
-- The page's layout, as the options window lays it out.
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')

-- Rested experience present, so the bar's first update takes the rested path.
stub.rested_xp = 300

local st = SaftUI
local XP = st:GetModule('Experience')
XP:Enable()
local exp = XP.bars.experience
local profile = st.config.profile

test('frame levels: backdrop 3, rested 4, fill 5', function()
	eq(exp.backdrop:GetFrameLevel(), 3, 'backdrop at 3')
	eq(exp.rested:GetFrameLevel(), 4, 'rested at 4')
	eq(exp:GetFrameLevel(), 5, 'xp bar at 5')
	check(exp.backdrop:GetFrameLevel() < exp.rested:GetFrameLevel() and exp.rested:GetFrameLevel() < exp:GetFrameLevel(), 'backdrop < rested < fill')
end)

test('the levels hold on a second UpdateConfig, and the rested alpha comes from config', function()
	XP:UpdateConfig()
	check(exp.backdrop:GetFrameLevel() == 3 and exp.rested:GetFrameLevel() == 4 and exp:GetFrameLevel() == 5, 'levels hold on a second UpdateConfig')
	eq(exp.rested:GetAlpha(), profile.experience.rest_alpha, 'rested alpha is the profile\'s rest_alpha')
	profile.experience.rest_alpha = 0.55
	XP:UpdateConfig()
	eq(exp.rested:GetAlpha(), 0.55, 'and follows a change to it')
end)

local args = XP:GetConfigTable().args.general.args

test('the Experience and Rested colors are color options that read the profile', function()
	check(args.normal_color.type == 'color' and args.rested_color.type == 'color', 'two color options')
	local r, g, b = args.rested_color.get()
	local rested = profile.colors.experience.rested
	check(r == rested.r and g == rested.g and b == rested.b, "rested get returns the profile's rested color")
end)

test('setting the rested color writes the profile and recolors the fill at once', function()
	stub.rested_xp = 300
	XP:Update()
	args.rested_color.set(nil, 1, 0, 0)
	check(profile.colors.experience.rested.r == 1, 'rested set writes the profile')
	local r, g = exp:GetStatusBarColor()
	check(r == 1 and g == 0, 'rested fill recolored at once (rested xp present)')
end)

test('without rested experience the normal color is used', function()
	args.normal_color.set(nil, 0, 1, 0)
	stub.rested_xp = nil
	XP:Update()
	local r, g = exp:GetStatusBarColor()
	check(r == 0 and g == 1, 'normal color used without rest')
end)

test('a reputation color change recolors the reputation bar at once; other groups do not', function()
	C_GossipInfo = { GetFriendshipReputation = function() end }
	C_Reputation.IsMajorFaction = function() return false end
	C_Reputation.GetWatchedFactionData = function()
		return { name = 'Stormwind', reaction = 5, factionID = 72, currentReactionThreshold = 0,
			nextReactionThreshold = 100, currentStanding = 40 }
	end
	XP:UpdateReputation()
	profile.colors.reaction[5] = CreateColor(0.9, 0.1, 0.2)
	XP:OnColorsChanged('class')
	local r1 = XP.bars.reputation:GetStatusBarColor()
	check(math.abs(r1 - 0.9) > 0.001, 'a class change leaves the bar alone')
	XP:OnColorsChanged('reaction')
	local r, g, b = XP.bars.reputation:GetStatusBarColor()
	check(math.abs(r - 0.9) < 0.001 and math.abs(g - 0.1) < 0.001 and math.abs(b - 0.2) < 0.001, 'the bar takes the new standing color')
	C_Reputation.GetWatchedFactionData = function() return nil end
end)

test('before the module is enabled a color change does nothing', function()
	local bars = XP.bars
	local drawn = 0
	local original = XP.UpdateReputation
	XP.UpdateReputation = function() drawn = drawn + 1 end
	XP.bars = nil
	XP:OnColorsChanged('reaction')
	XP.bars = bars
	XP.UpdateReputation = original
	eq(drawn, 0, 'no redraw')
end)

test('the Experience page reads Theme | Background, Spacing | Height, Width | the two colors, Rested bar alpha, then Position', function()
	local root = { Experience = XP:GetConfigTable() }
	local view = st.OptionsModel.BuildView(root, 'Experience')
	local sections = view.sections
	eq(#sections, 2, 'General, then the Position section')
	local placed = st.OptionsBody.LayoutRows(sections[1].rows)
	local got = {}
	for _, p in ipairs(placed) do
		got[#got + 1] = string.format('%s:%s %s%s', p.row.key, p.row.size or 'normal', tostring(p.col),
			p.quarter and ('/' .. p.quarter) or '')
	end
	eq(table.concat(got, ', '),
		'theme:normal 1, background:normal 2, spacing:normal 1, height:normal 2, '
		.. 'width:normal 1, normal_color:small 2/1, rested_color:small 2/2, rest_alpha:normal 1',
		'General reads in pairs, the two colors sharing a half')
	eq(placed[1].y, placed[2].y, 'Theme and Background share a line')
	eq(placed[5].y, placed[7].y, 'Width and the colors share a line')
	eq(sections[2].title, 'Position', 'Position has a section of its own')
	eq(#sections[2].rows, 1, 'with the one row')
	eq(sections[2].rows[1].type, 'position', 'the Position block')
	eq(st.OptionsBody.LayoutRows(sections[2].rows)[1].col, 'full', 'on a line of its own')
end)

test("the bars are drawn as bars in the page's Theme and Background", function()
	XP:UpdateConfig()
	for _, key in ipairs({ 'experience', 'reputation' }) do
		local bar = XP.bars[key]
		eq(drawn(bar), 'theme,theme,bar', key .. ': the Experience Theme and Background, as a bar')
		eq(T.inset(bar.backdrop), 2, key .. ": Thick's border")
	end
	profile.experience.theme, profile.experience.background = 'thin', 'solid'
	XP:UpdateConfig()
	for _, key in ipairs({ 'experience', 'reputation' }) do
		local bar = XP.bars[key]
		eq(drawn(bar), 'thin,solid,bar', key .. ': a new Theme and Background')
		eq(T.offset(bar.backdrop, 'TOPLEFT'), '-1.00,1.00', key .. ": Thin's border outside the bar")
	end
	eq(exp.backdrop:GetFrameLevel(), 3, 'the backdrop keeps its level under the rested part')
	profile.experience.theme, profile.experience.background = 'theme', 'theme'
	XP:UpdateConfig()
end)
