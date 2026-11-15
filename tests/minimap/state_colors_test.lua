-- The micro menu's stats and alert flash in the state colors: the latency text
-- runs from Text > Success through Caution to Warning (SaftUI-Minimap/stats.lua),
-- and the flat alert flash on a micro button is Text > Caution
-- (microbuttons.lua). Every case runs with the three at values that are not
-- their defaults, so a reader that drew a color of its own fails.
--
-- Real: stats.lua on a stand-in MicroMenu module, and Core's gradient
-- (st:ColorGradient, Utilities/utilities.lua).
load_core_helpers()
load_saftui('SaftUI-Core/Utilities/utilities.lua')
local T = load_test_file('lib/theme_helpers.lua')
local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu')
load_saftui('SaftUI-Minimap/stats.lua')

local colors = st.config.profile.colors.text
local GOOD, OKAY, BAD = { 0.1, 0.8, 0.3 }, { 0.7, 0.7, 0.2 }, { 0.9, 0.4, 0.1 }
colors.success:SetRGB(unpack(GOOD)); colors.caution:SetRGB(unpack(OKAY)); colors.warning:SetRGB(unpack(BAD))

local function fontstring()
	local fs = CreateFrame('Frame', nil, UIParent):CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(GameFontNormal)
	return fs
end

test('the latency text runs from Success (fast) through Caution to Warning (slow), at odd values', function()
	local latency = { text = fontstring() }
	local cases = { { 0, GOOD, 'no delay: Success' }, { 300, OKAY, 'half of the worst: Caution' }, { 600, BAD, 'the worst: Warning' } }
	for _, case in ipairs(cases) do
		_G.GetNetStats = function() return 0, 0, case[1], case[1] end
		latency.lastUpdate = nil
		MicroMenu:UpdateLatency(latency)
		eq(T.rgb(latency.text:GetTextColor()), T.rgb(unpack(case[2])), case[3])
	end
end)

test('a changed color is the next reading', function()
	local latency = { text = fontstring() }
	colors.success:SetRGB(0.2, 0.2, 0.9)
	_G.GetNetStats = function() return 0, 0, 0, 0 end
	MicroMenu:UpdateLatency(latency)
	eq(T.rgb(latency.text:GetTextColor()), T.rgb(0.2, 0.2, 0.9), 'Success changed')
	colors.success:SetRGB(unpack(GOOD))
end)
