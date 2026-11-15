-- A file with a plain case and a scaled one that both pass. The plain case
-- checks the world is at k 1; the scaled one checks the world is at the k the
-- scale model gives the screen for test_scale().
test('plain', function()
	eq(test_scale(), 1, 'a plain case is at k 1')
end)

scaled_test('scaled', function()
	local st = SaftUI
	local row = SCALE_SCREENS[test_scale()]
	local resolved = st.UIScale.Resolve({ mode = row[3], size = 1 }, { width = row[1], height = row[2] })
	check(near(1 / st.pixel, resolved.k), 'the world is at k ' .. tostring(resolved.k) .. ', got ' .. tostring(1 / st.pixel))
end)
