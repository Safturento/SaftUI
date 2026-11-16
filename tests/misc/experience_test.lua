-- SaftUI-Misc/experience.lua: the XP bar's frame levels (backdrop below the
-- rested part below the fill), the Experience and Rested color options, and the
-- bars drawn as bars in the page's Theme and Background.
-- Migrated from the xpsim harness. The config is Core's and Misc's real
-- defaults (SaftUI-Misc/config.lua has the bars'), and the frames come from
-- Core's real helpers (st:SetBackdrop and the rest).
load_core_helpers()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
-- Blizzard's minimap, which the bar's default position anchors to (the profile
-- has the real defaults).
CreateFrame('Frame', 'Minimap', UIParent)
load_editmode() -- the bar registers a mover
load_saftui('SaftUI-Misc/experience.lua')
-- The page's layout, as the options window lays it out.
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local R = load_test_file('lib/reset_walk.lua')

-- Rested experience present, so the bar's first update takes the rested path.
stub.rested_xp = 300

local st = SaftUI
local XP = st:GetModule('Experience')
XP:Enable()
local exp = XP.bars.experience
local profile = st.config.profile

test('every value row of the Experience page has a reset, and each derived one round-trips', function()
	-- first: the walk wants the profile as a fresh one has it, before a test changes a value
	local tree = XP:GetConfigTable()
	R.check_page({ Experience = tree }, 'Experience')
end)

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

test('the Experience page reads Theme | Background, Spacing | Height, Width | Normal color, Rested color | Rested bar alpha, then Position', function()
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
		.. 'width:normal 1, normal_color:normal 2, rested_color:normal 1, rest_alpha:normal 2',
		'General reads in pairs, each color a half of its own (a bar as wide as a dropdown)')
	eq(placed[1].y, placed[2].y, 'Theme and Background share a line')
	eq(placed[5].y, placed[6].y, 'Width and the first color share a line')
	eq(placed[7].y, placed[8].y, 'the second color and Rested bar alpha share the next')
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

test("the mover's default position is a copy of the profile defaults'; it is hidden while no bar shows", function()
	local EM = st.EditModeFrames
	local mover = EM.movers.experience
	eq(EM:MoverModule(mover), 'Misc', 'module')
	eq(EM:IsMoverDisabled(mover), false, 'never disabled')
	local default = EM:GetDefaultPosition(mover)
	local want = st.defaults.experience.position
	eq(('%s %s %s %d,%d'):format(default.point, default.frame, default.rel_point, default.x_off, default.y_off),
		('%s %s %s %d,%d'):format(want.point, want.frame, want.rel_point, want.x_off, want.y_off), "the defaults' position")
	check(default ~= want, 'a copy, not the defaults table')
	default.y_off = 123
	eq(want.y_off, -7, 'a write into it never reaches the defaults')
	for _, bar in pairs(XP.bars) do bar:Show() end
	eq(EM:IsMoverHidden(mover), false, 'shown while a bar shows')
	for _, bar in pairs(XP.bars) do bar:Hide() end
	eq(EM:IsMoverHidden(mover), true, 'hidden while none does')
end)

test('a reputation or renown pass only colors: no Show, range or value, nothing made, under 4 KB over 100 passes', function()
	local C = load_test_file('lib/color_cost.lua')
	C_GossipInfo = { GetFriendshipReputation = function() end }
	C_Reputation.IsMajorFaction = function() return false end
	C_Reputation.GetWatchedFactionData = function()
		return { name = 'Stormwind', reaction = 5, factionID = 72, currentReactionThreshold = 0,
			nextReactionThreshold = 100, currentStanding = 40 }
	end
	XP:UpdateReputation()
	local bar = XP.bars.reputation
	local before = { bar:GetValue(), select(2, bar:GetMinMaxValues()) }
	st:ColorChanged('reaction', 5) -- the first pass makes what a widget makes once
	local shows, ranges = 0, 0
	local show, set = bar.Show, bar.SetMinMaxValues
	bar.Show = function(...) shows = shows + 1; return show(...) end
	bar.SetMinMaxValues = function(...) ranges = ranges + 1; return set(...) end
	local m = C.measure(function() st:ColorChanged('reaction', 5) end, 100)
	bar.Show, bar.SetMinMaxValues = nil, nil
	eq(shows, 0, 'no Show')
	eq(ranges, 0, 'no range set')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, ('under 4 KB, got %.2f'):format(m.kb))
	eq(bar:GetValue() .. ',' .. select(2, bar:GetMinMaxValues()), before[1] .. ',' .. before[2], 'the bar is as it was')
	-- Renown, and a pass for the other color, and a hidden bar.
	C_Reputation.IsMajorFaction = function() return true end
	C_MajorFactions = { GetMajorFactionData = function() return { name = 'A', renownLevel = 3, renownReputationEarned = 5, renownLevelThreshold = 10 } end }
	XP:UpdateReputation()
	profile.colors.renown:SetRGB(0.3, 0.6, 0.9)
	st:ColorChanged('reaction', 5)
	local r = XP.bars.reputation:GetStatusBarColor()
	check(math.abs(r - 0.3) > 0.001, 'renown on screen: a standing pass leaves it')
	st:ColorChanged('renown')
	r = XP.bars.reputation:GetStatusBarColor()
	check(math.abs(r - 0.3) < 0.001, 'a renown pass colors it')
	C_Reputation.IsMajorFaction = function() return false end
	C_Reputation.GetWatchedFactionData = function() return nil end
	XP:UpdateReputation()
	XP.bars.reputation:SetStatusBarColor(1, 1, 1)
	st:ColorChanged('reaction', 5)
	eq(select(1, XP.bars.reputation:GetStatusBarColor()), 1, 'a hidden bar is left alone')
end)
