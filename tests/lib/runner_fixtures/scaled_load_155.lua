-- A file whose scaled run fails while loading, at 1.55 only: its top level
-- prints, then errors, when the runner gave the state TEST_SCALE 1.55. Its
-- path rotates to 1.55, so even a plain run of it fails.
scaled_test('never reached at 1.55', function()
	check(true, 'a scaled case')
end)

if TEST_SCALE == 1.55 then
	print('printed while loading at 1.55')
	error('load fails at 1.55', 0)
end
