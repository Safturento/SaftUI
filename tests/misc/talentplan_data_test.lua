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
	stub.traits.definitions[stub.traits.entries[entryID].definitionID].overrideName = ''
	eq(D.Read(1).nodes[id].name, 'Flurry', 'an empty override is no override')
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

test('the shape holds groups, gates, edges and costs', function()
	SH.install({ shape = true })
	local shape = D.Read(1).shape
	eq(#shape.groups, 3)
	eq(shape.groups[1].name, 'Elemental'); eq(shape.groups[2].name, 'Enhancement'); eq(shape.groups[3].name, 'Restoration')
	eq(shape.groups[2].id, SH.GROUP.Enhancement)
	local ss = shape.nodes[SH.ID.Stormstrike]
	eq(#ss.parents, 1); eq(ss.parents[1].nodeID, SH.ID['Spirit Weapons']); eq(ss.parents[1].type, 3)
	eq(shape.nodes[SH.ID['Improved Stormstrike']].parents[1].nodeID, SH.ID.Stormstrike)
	local flurry = shape.nodes[SH.ID.Flurry] -- row 2 of Enhancement
	eq(flurry.gates[1].required, 5); eq(flurry.group, SH.GROUP.Enhancement); eq(flurry.posY, 50)
	eq(flurry.maxRanks, 5); eq(flurry.cost, 1); eq(flurry.plannable, true); eq(flurry.name, 'Flurry')
	eq(#shape.nodes[SH.ID['Thundering Strikes']].gates, 0, 'row 1 has no gate')
	local choice = shape.nodes[130]
	check(choice, 'the choice node is in the shape'); eq(choice.plannable, false)
	eq(shape.nodes[SH.ID['Totemic Focus']].parents[1].nodeID, 130)
	eq(shape.nodes[131], nil, 'an invisible node is not')
	eq(shape.budget, nil); eq(shape.hideSingle, false)
	eq(#stub.traits.calls, 0)
end)

test('a cost, a budget and hideSingleRankNumbers come from the game', function()
	SH.install({ shape = true })
	stub.traits.costs[SH.ID.Flurry] = { { ID = 800, amount = 2 } }
	stub.traits.currency = { { traitCurrencyID = 800, quantity = 5, maxQuantity = 31, spent = 0 } }
	stub.traits.tree_info[501] = { hideSingleRankNumbers = true }
	local shape = D.Read(1).shape
	eq(shape.nodes[SH.ID.Flurry].cost, 2); eq(shape.budget, 31); eq(shape.hideSingle, true)
end)

test('a node whose group the tree does not list has no group', function()
	SH.install({ shape = true })
	stub.traits.nodes[1001][SH.ID.Flurry].groupIDs = { 999, SH.GROUP.Elemental }
	stub.traits.nodes[1001][SH.ID['Mental Quickness']].groupIDs = { 999 }
	local shape = D.Read(1).shape
	eq(shape.nodes[SH.ID.Flurry].group, SH.GROUP.Elemental, 'the first listed one')
	eq(shape.nodes[SH.ID['Mental Quickness']].group, nil)
end)

test('gates from GetTreeInfo when nodes carry none', function()
	SH.install({ shape = true })
	for _, info in pairs(stub.traits.nodes[1001]) do info.conditionIDs = {} end
	-- the gate's top left node is Stormstrike (Enhancement, row 2): it covers that group's nodes at or below posY 50
	stub.traits.conditions[8001] = { isGate = true, isMet = false, spentAmountRequired = 5, traitCurrencyID = 800 }
	stub.traits.tree_info[501] = { gates = { { topLeftNodeID = SH.ID.Stormstrike, conditionID = 8001 } } }
	local shape = D.Read(1).shape
	eq(shape.nodes[SH.ID.Flurry].gates[1].required, 5)
	eq(shape.nodes[SH.ID['Spirit Weapons']].gates[1].required, 5, 'a row below')
	eq(#shape.nodes[SH.ID['Thundering Strikes']].gates, 0, 'a row above')
	eq(#shape.nodes[SH.ID['Call of Flame']].gates, 0, 'another group')
	-- nodes that carry their own gate are left as they are
	stub.traits.nodes[1001][SH.ID.Flurry].conditionIDs = { 9000 + SH.ID.Flurry }
	stub.traits.conditions[9000 + SH.ID.Flurry] = { isGate = true, isMet = false, spentAmountRequired = 5 }
	eq(#D.Read(1).shape.nodes[SH.ID.Flurry].gates, 1)
end)
