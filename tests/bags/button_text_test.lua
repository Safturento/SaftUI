-- The bags' bag slot bars and the bank's bag slots wear Core's own button settings,
-- so their texts follow Button text (Global settings > Fonts). containers/bank.lua
-- passes no config to st:SkinActionButton, which then keeps each text with
-- st:FollowFont (Ruling 9; tests/core/fonts_tab_test.lua pins that path). The real
-- bank slot has no text of its own, so what is pinned for it is the call itself,
-- read from the source: a profile's `buttons` table passed in its place would stop
-- the follow. containers/bag.lua skins Blizzard's bag slots itself, since
-- st:SkinActionButton writes fields onto the button (.agents/taint.md, rule 1): it
-- no longer calls it, and bag_bar_slot_test.lua pins that its slots' texts follow
-- Button text, by behavior.
local L = load_test_file('lib/source_lex.lua')

test('SaftUI-Bags/containers/bank.lua skins its bag slots with no config of their own', function()
	local source = read_saftui_source('SaftUI-Bags/containers/bank.lua')
	check(source ~= nil, 'the file is there')
	local code = select(1, L.Lex(source))
	local calls = 0
	for _ in code:gmatch('st:SkinActionButton%(%s*[%w_.]+%s*,%s*nil%s*,') do
		calls = calls + 1
	end
	eq(calls, 1, 'one call to st:SkinActionButton')
	check(not code:find('profile%.buttons%)'), 'no profile buttons table passed in its place')
end)

test('SaftUI-Bags/containers/bag.lua does not skin Blizzard\'s bag slots through st:SkinActionButton', function()
	local source = read_saftui_source('SaftUI-Bags/containers/bag.lua')
	check(source ~= nil, 'the file is there')
	local code = select(1, L.Lex(source))
	check(not code:find('st:SkinActionButton', 1, true), 'it writes .backdrop, .hover and the like onto the button')
end)
