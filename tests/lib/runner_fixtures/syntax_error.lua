-- Runner self-check fixture: a syntax error. The runner must exit non-zero.
test('never registered', function()
	check(true
end)
