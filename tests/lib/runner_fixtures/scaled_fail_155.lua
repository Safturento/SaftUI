-- A scaled case that fails only in the scaled run at 1.55 (in the normal run
-- test_scale() is 1).
scaled_test('fails at 1.55', function()
	check(test_scale() ~= 1.55, 'this case fails at 1.55')
end)
