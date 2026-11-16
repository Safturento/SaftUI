-- Leftovers in the unit frames' defaults (config/default.lua, config/units/*):
-- every position in every unit's defaults, both plate configs too, places its
-- parts by numbers, not text ("0", "-3"); the
-- player's class power has no show_empty (oUF shows every point up to the max,
-- and nothing reads the key); the raid target marker names no Portrait element
-- (none is registered) and sits on the unit frame, as it always did.
--
-- The world is uf_world.lua's, every unit's config, no elements.
local UW = load_test_file('unitframes/uf_world.lua')

-- Every x_off and y_off under t, with its path.
local function offsets(t, path, out)
	for key, value in pairs(t) do
		if type(value) == 'table' then
			offsets(value, path .. '.' .. tostring(key), out)
		elseif key == 'x_off' or key == 'y_off' then
			out[#out + 1] = { path .. '.' .. key, value }
		end
	end
	return out
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ": every position's offsets in every unit's defaults are numbers", function()
		local units = { 'nameplate', 'friendlynameplate' }
		for _, unit in ipairs(UW.UNITS) do units[#units + 1] = unit end
		local st, UF, P = UW.world({ client = client, elements = {}, units = units })
		local seen = 0
		for _, unit in ipairs(units) do
			check(type(P[unit]) == 'table', unit .. ' has defaults')
			if type(P[unit]) == 'table' then
				for _, pair in ipairs(offsets(P[unit], unit, {})) do
					seen = seen + 1
					eq(type(pair[2]), 'number', pair[1] .. ' is a number')
				end
			end
		end
		eq(seen > 100, true, 'many offsets were checked: ' .. seen)
	end)

	test(client .. ": the player's class power has no show_empty", function()
		local st, UF, P = UW.world({ client = client, elements = {} })
		eq(P.player.classpower.show_empty, nil, 'no show_empty default')
	end)

	test(client .. ': the raid target marker names no element and anchors to the unit frame', function()
		local st, UF, P = UW.world({ client = client, elements = {} })
		for _, unit in ipairs(UW.UNITS) do
			local config = P[unit].raidtargetindicator
			if config then
				eq(config.position.element, nil, unit .. ": no element named, Portrait isn't registered")
				local unitframe = CreateFrame('Button', nil, UIParent)
				eq(UF:GetFrame(unitframe, config.position), unitframe, unit .. ': it anchors to the unit frame')
			end
		end
	end)
end
