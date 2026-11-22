--[[
	The shaman talent tree as names, for the talent plan's parser: the 20 talents
	of the owner's Enhancement guide and three decoys. Node IDs and max ranks are
	fixture data. Load it with `local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')`;
	SH.NAMES is the list TP.Parse takes ({ name, nodeID, maxRanks }) and SH.ID[name]
	a name's node ID.
]]
local SH = { NAMES = {}, ID = {} }

local list = {
	{ 'Thundering Strikes', 5 }, { 'Mental Dexterity', 3 }, { 'Ancestral Knowledge', 5 },
	{ 'Shamanistic Focus', 1 }, { 'Elemental Weapons', 3 },
	{ 'Stormstrike', 1 }, { 'Improved Ghost Wolf', 2 }, { 'Flurry', 5 },
	{ 'Improved Stormstrike', 2 }, { 'Mental Quickness', 3 },
	{ 'Spirit Weapons', 1 }, { 'Maelstrom Weapon', 5 }, { 'Tidal Focus', 5 },
	{ 'Mindfulness', 3 }, { 'Concussion', 5 },
	{ 'Call of Flame', 3 }, { 'Elemental Devastation', 3 }, { 'Elemental Focus', 1 },
	{ 'Reverberation', 5 }, { 'Trial by Fire', 3 },
	-- decoys
	{ 'Improved Lightning Shield', 3 }, { "Nature's Guardian", 5 }, { 'Totemic Focus', 5 },
}

for i, t in ipairs(list) do
	SH.NAMES[i] = { name = t[1], nodeID = 100 + i, maxRanks = t[2] }
	SH.ID[t[1]] = 100 + i
end

return SH
