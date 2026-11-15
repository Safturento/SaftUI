-- The bags' bag slot bars and the bank's bag slots wear Core's own button settings,
-- so their texts follow Button text (Global settings > Fonts): containers/bag.lua
-- and containers/bank.lua pass no config to st:SkinActionButton, which then keeps
-- each text with st:FollowFont (Ruling 9; tests/core/fonts_tab_test.lua pins that
-- path). The real bank slot has no text of its own and Blizzard's bag slots need
-- Blizzard's bags bar, so what is pinned here is the call itself, read from the
-- source: a profile's `buttons` table passed in its place would stop the follow.
local L = load_test_file('lib/source_lex.lua')

for _, file in ipairs({ 'SaftUI-Bags/containers/bag.lua', 'SaftUI-Bags/containers/bank.lua' }) do
	test(file .. ' skins its bag slots with no config of their own', function()
		local source = read_saftui_source(file)
		check(source ~= nil, 'the file is there')
		local code = select(1, L.Lex(source))
		local calls = 0
		for args in code:gmatch('st:SkinActionButton%((.-)%)') do
			calls = calls + 1
			eq((args:gsub('%s', '')), "slot,nil,'slot'", 'a call passes nil for the config')
		end
		eq(calls, 1, 'one call to st:SkinActionButton')
		check(not code:find('profile%.buttons%)'), 'no profile buttons table passed in its place')
	end)
end
