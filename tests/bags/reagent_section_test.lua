-- The bags' settings have no reagent section: no reagent window exists on
-- either client. A profile that saved one keeps it as an inert table: nothing
-- reads it, and the position migration no longer touches it.
local H = load_test_file('bags/container_helpers.lua')

test('the bags have no reagent section in their defaults', function()
	local INV = H.views_world('forever')
	eq(INV.config.reagent, nil, 'no reagent settings')
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile with a saved reagent section is left alone, and the other windows still migrate', function()
	local INV = H.views_world('forever')
	INV.config.reagent = { position = { 'TOPLEFT', 5, 5 }, perrow = 6 }
	INV.config.bag.position = { 'BOTTOMRIGHT', -30, 30 } -- an older, array-style position
	INV:MigratePositions()
	eq(INV.config.reagent.position[1] .. INV.config.reagent.position[2] .. INV.config.reagent.position[3], 'TOPLEFT55', 'the saved reagent position is untouched, still an array')
	eq(INV.config.reagent.position.point, nil, 'not converted')
	eq(INV.config.reagent.perrow, 6, 'and its other keys')
	eq(INV.config.bag.position.point, 'BOTTOMRIGHT', "the bag window's old position is converted")
	eq(INV.config.bag.position.x_off, -30, 'with its offsets')
	for _, id in ipairs({ 'bag', 'bank', 'combinedbank', 'warband' }) do
		check(INV.config[id] ~= nil, id .. ' keeps its settings')
	end
	eq(#take_errors(), 0, 'no errors')
end)
