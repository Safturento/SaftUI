-- The pet's defaults (SaftUI-Unitframes/config/units/pet.lua): its power bar's
-- text is off, as is its name. The file once wrote the power table twice; Lua
-- kept the second, and one copy says the same.
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
load_saftui('SaftUI-Unitframes/config/units/pet.lua')

local pet = SaftUI.defaults.unitframes.profiles['**'].pet

test("the pet's power defaults turn its text off and set nothing else", function()
	eq(pet.power.text.enable, false, 'power text is off')
	local keys = {}
	for key in pairs(pet.power) do keys[#keys + 1] = key end
	eq(table.concat(keys, ','), 'text', 'power has only its text table')
	keys = {}
	for key in pairs(pet.power.text) do keys[#keys + 1] = key end
	eq(table.concat(keys, ','), 'enable', 'the text table has only enable')
end)

test("the pet's name defaults are off", function()
	eq(pet.name.enable, false, 'name is off')
	eq(pet.width, 120, 'its width')
end)
