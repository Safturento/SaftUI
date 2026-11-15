-- A file with a plain case and scaled ones that all pass. The plain case
-- checks the world is at k 1; the scaled ones check the world is at the k the
-- scale model gives the screen for test_scale(): the world the file loaded
-- into, and every world a case rebuilds (reset_world, use_client, T.client).
local T = load_test_file('lib/theme_helpers.lua')

test('plain', function()
	eq(test_scale(), 1, 'a plain case is at k 1')
end)

-- The screen the world is on, UIParent's scale and the tokens, against what
-- the scale model gives SCALE_SCREENS[test_scale()].
local function check_world(where)
	local st = SaftUI
	local row = SCALE_SCREENS[test_scale()]
	local resolved = st.UIScale.Resolve({ mode = row[3], size = 1 }, { width = row[1], height = row[2] })
	check(stub.screen_width == row[1] and stub.screen_height == row[2],
		where .. ': the screen is ' .. row[1] .. ' x ' .. row[2] .. ', got ' .. stub.screen_width .. ' x ' .. stub.screen_height)
	check(near(UIParent:GetScale(), resolved.uiScale), where .. ': UIParent scale ' .. tostring(resolved.uiScale) .. ', got ' .. tostring(UIParent:GetScale()))
	check(near(1 / st.pixel, resolved.k), where .. ': k ' .. tostring(resolved.k) .. ', got ' .. tostring(1 / st.pixel))
	check(near(st.line, resolved.line), where .. ': line ' .. tostring(resolved.line) .. ', got ' .. tostring(st.line))
end

scaled_test('scaled', function()
	check_world('the world the file loaded into')
end)

scaled_test('rebuilt worlds', function()
	check_world('at the start')
	reset_world()
	check_world('after reset_world')
	use_client('retail')
	check_world('after use_client retail')
	use_client('forever')
	check_world('after use_client forever')
	T.client('retail')
	check_world('after T.client retail')
	T.client('forever')
	check_world('after T.client forever')
end)
