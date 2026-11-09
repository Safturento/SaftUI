-- Runner self-check fixture: an error inside a case.
test('errors', function()
	check(true, 'a check that passes first')
	error('boom')
end)
