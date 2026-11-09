-- Runner self-check fixture: a case that never ends. The harness's
-- instruction limit must stop it (this takes about 5 seconds).
test('loops forever', function()
	while true do end
end)
