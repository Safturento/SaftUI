-- SaftUI-Misc/TalentPlan/data.lua: the talent tree read through the trait stubs
-- (tests/wow/traits.lua), on the shaman fixture. It only reads.
load_saftui('SaftUI-Misc/TalentPlan/talentplan.lua')
load_saftui('SaftUI-Misc/TalentPlan/data.lua')
local D = SaftUI:GetModule('TalentPlan').Data
local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')

test('Read gives names, icons, ranks and skips choice and hidden nodes', function()
	SH.install({ ranks = { ['Thundering Strikes'] = 3 } })
	local t = D.Read(1)
	eq(t.configID, 1001); eq(t.treeID, 501); check(t.active); eq(t.level, stub.level)
	local n = t.nodes[SH.ID['Thundering Strikes']]
	eq(n.name, 'Thundering Strikes'); eq(n.maxRanks, 5); eq(n.committed, 3); eq(n.staged, 3)
	eq(n.icon, 134000 + SH.ID['Thundering Strikes'])
	eq(t.nodes[130], nil); eq(t.nodes[131], nil); eq(#t.names, 23)
	eq(#stub.traits.calls, 0, 'nothing bought or committed')
end)

test('an override name wins, and a spell name is the fallback', function()
	SH.install()
	local id = SH.ID.Flurry
	eq(D.Read(1).nodes[id].name, 'Flurry', 'the spell name')
	local entryID = stub.traits.nodes[1001][id].entryIDs[1]
	stub.traits.definitions[stub.traits.entries[entryID].definitionID].overrideName = 'Renamed'
	eq(D.Read(1).nodes[id].name, 'Renamed')
end)

test('a node the game does not know, a sub tree node and a nameless one are skipped', function()
	SH.install()
	table.insert(stub.traits.trees[501], 999)
	stub.traits.nodes[1001][SH.ID.Flurry].subTreeID = 7
	stub.traits.spells[stub.traits.definitions[stub.traits.entries[stub.traits.nodes[1001][SH.ID.Stormstrike].entryIDs[1]].definitionID].spellID].name = nil
	local t = D.Read(1)
	eq(t.nodes[999], nil); eq(t.nodes[SH.ID.Flurry], nil); eq(t.nodes[SH.ID.Stormstrike], nil); eq(#t.names, 21)
end)

test('a tab with no config: tree from the active config, ranks 0, no level', function()
	SH.install({ ranks = { Flurry = 2 } })
	local t = D.Read(2)
	eq(t.configID, nil); eq(t.treeID, 501); eq(t.level, nil); check(not t.active)
	eq(t.nodes[SH.ID.Flurry].committed, 0); eq(t.nodes[SH.ID.Flurry].staged, 0)
	eq(t.nodes[SH.ID.Flurry].block, 'Switch to this spec to learn it.')
end)

test('a second spec group reads its own config, inactive', function()
	SH.install({ second = true, ranks = { Flurry = 2 } })
	local t = D.Read(2)
	eq(t.configID, 1002); check(not t.active); eq(t.level, stub.level); eq(t.nodes[SH.ID.Flurry].committed, 0)
end)

test('no config anywhere: nil', function()
	SH.install()
	stub.traits.group_configs = {}; stub.traits.active_group = 1
	eq(D.Read(1), nil)
end)

test('staged purchases and refunds keep the committed rank', function()
	eq(D.CommittedRank(2, nil, nil), 2); eq(D.CommittedRank(3, 'purchase', 1), 1, 'two staged, snapshot wins')
	eq(D.CommittedRank(3, 'purchase', nil), 2); eq(D.CommittedRank(0, 'refund', 2), 2); eq(D.CommittedRank(1, 'refund', nil), 2)
	SH.install({ ranks = { Flurry = 1 } }); D.ResetSnapshots(); D.Read(1) -- snapshot 1
	stub.traits.nodes[1001][SH.ID.Flurry].ranksPurchased = 3
	stub.traits.staged[1001] = { purchases = { SH.ID.Flurry }, refunds = {} }
	local n = D.Read(1).nodes[SH.ID.Flurry]; eq(n.committed, 1); eq(n.staged, 3)
end)

test('BlockReason copy', function()
	eq(D.BlockReason({ canPurchaseRank = true }, {}, true), nil)
	eq(D.BlockReason({ canPurchaseRank = false }, {}, false), 'Switch to this spec to learn it.')
	eq(D.BlockReason({ meetsEdgeRequirements = false }, {}, true), 'Needs the talent above it first.')
	eq(D.BlockReason({ meetsEdgeRequirements = true, isAvailable = false }, { { isGate = true, isMet = false, spentAmountRequired = 8 } }, true), 'Needs 8 points spent in the tree first.')
	eq(D.BlockReason({ meetsEdgeRequirements = true, isAvailable = false }, { { isGate = true, isMet = false } }, true), 'Not available yet.')
	eq(D.BlockReason({ meetsEdgeRequirements = true, isAvailable = true }, {}, true), 'No talent points to spend.')
end)

test('a node blocked by a gate reads its reason through the condition', function()
	SH.install()
	local info = stub.traits.nodes[1001][SH.ID.Flurry]
	info.canPurchaseRank = false; info.isAvailable = false; info.conditionIDs = { 77 }
	stub.traits.conditions[77] = { isGate = true, isMet = false, spentAmountRequired = 8 }
	eq(D.Read(1).nodes[SH.ID.Flurry].block, 'Needs 8 points spent in the tree first.')
	info.ranksPurchased = 5
	eq(D.Read(1).nodes[SH.ID.Flurry].block, nil, 'a maxed node has no reason')
end)
