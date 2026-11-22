--[[
	The talent trees' API, for SaftUI-Misc's talent plan tests. Loaded at the end
	of game.lua. A fresh `stub.traits` is the game's trait system:

	  stub.traits = { active_group = 1,
	    group_configs = { [1] = configID, [2] = nil },   -- the config of each spec group
	    configs = { [configID] = { treeIDs = { treeID } } },
	    trees = { [treeID] = { nodeID, ... } },
	    nodes = { [configID] = { [nodeID] = TraitNodeInfo } },
	    entries = { [entryID] = { definitionID, maxRanks, type = 1 } },
	    definitions = { [definitionID] = { spellID, overrideName, overrideIcon } },
	    spells = { [spellID] = { name, icon } },
	    conditions = { [condID] = { isGate, isMet, spentAmountRequired } },
	    staged = { [configID] = { purchases = {}, refunds = {} } },
	    tree_info = { [treeID] = { gates = { { topLeftNodeID, conditionID } }, hideSingleRankNumbers } },
	    groups = { [treeID] = { { groupID, orderIndex, displayName } } },
	    costs = { [nodeID] = { { ID, amount } } },       -- none: the node costs 1
	    currency = { { traitCurrencyID, quantity, maxQuantity, spent } },
	    unspent = false, calls = {} }

	`calls` gets the name of every PurchaseRank, RefundRank and CommitConfig
	call: the talent plan only reads, so a test asserts it stays empty.
	stub.reset_traits() makes the table again (the fixture's SH.install does).

	Where each function comes from: names, arguments and return shapes are in
	Blizzard_APIDocumentationGenerated on the `forever` branch of
	Gethe/wow-ui-source, read 2026-11-22: SharedTraitsDocumentation.lua
	(C_Traits: GetConfigInfo, GetTreeNodes, GetTreeInfo,
	GetGroupDisplayInfoByTreeID, GetNodeCost, GetTreeCurrencyInfo, GetNodeInfo, GetEntryInfo,
	GetDefinitionInfo, GetConditionInfo, GetStagedChanges, PurchaseRank,
	RefundRank, CommitConfig and the TraitNodeInfo, TraitCondInfo,
	TraitEntryInfo, TraitDefinitionInfo and TraitConfigInfo structures),
	ClassTalentsDocumentation.lua (GetActiveConfigID, HasUnspentTalentPoints),
	SpecializationInfoDocumentation.lua (GetActiveSpecGroup,
	GetCombatConfigIDForSpecGroup) and SpellDocumentation.lua (GetSpellName,
	GetSpellTexture, which gives the icon twice here).

	Every argument is checked as in game: one that isn't a number errors with
	the call's Usage line. GetStagedChanges gives nothing when no change is
	staged, as its documentation says.

	UNVERIFIED: what the real C_Traits.GetNodeInfo gives for a node it doesn't
	know. The documentation marks it MayReturnNothing and the stub gives nil;
	the talent plan's reader skips such a node. Not modelled: hero talent
	sub trees (a node's subTreeID is only a field a test may set), selection
	swaps (the third staged table is always empty), inspect and pet groups.
]]

C_Traits = C_Traits or {}
C_ClassTalents = C_ClassTalents or {}
C_SpecializationInfo = C_SpecializationInfo or {}
C_Spell = C_Spell or {}

function stub.reset_traits()
	stub.traits = { active_group = 1, group_configs = {}, configs = {}, trees = {}, nodes = {},
		entries = {}, definitions = {}, spells = {}, conditions = {}, staged = {}, unspent = false, calls = {},
		tree_info = {}, groups = {}, costs = {}, currency = {} }
end
stub.reset_traits()

do
	local T = C_Traits

	local function number_arg(value, usage)
		if type(value) ~= 'number' then error('Usage: ' .. usage, 3) end
		return value
	end

	local function call(name) table.insert(stub.traits.calls, name) end

	function T.GetConfigInfo(configID)
		number_arg(configID, 'local configInfo = C_Traits.GetConfigInfo(configID)')
		local config = stub.traits.configs[configID]
		if not config then return nil end
		return { ID = configID, type = 1, name = 'Config ' .. configID, treeIDs = config.treeIDs, usesSharedActionBars = false }
	end

	function T.GetTreeNodes(treeID)
		number_arg(treeID, 'local nodeIDs = C_Traits.GetTreeNodes(treeID)')
		local nodes = stub.traits.trees[treeID]
		if not nodes then return nil end
		local copy = {}
		for i, id in ipairs(nodes) do copy[i] = id end
		return copy
	end

	function T.GetNodeInfo(configID, nodeID)
		number_arg(configID, 'local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)')
		number_arg(nodeID, 'local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)')
		local nodes = stub.traits.nodes[configID]
		local info = nodes and nodes[nodeID]
		if not info then return nil end
		local copy = {}
		for k, v in pairs(info) do copy[k] = v end
		return copy
	end

	-- { ID, gates = { { topLeftNodeID, conditionID } }, hideSingleRankNumbers }
	function T.GetTreeInfo(configID, treeID)
		number_arg(configID, 'local treeInfo = C_Traits.GetTreeInfo(configID, treeID)')
		number_arg(treeID, 'local treeInfo = C_Traits.GetTreeInfo(configID, treeID)')
		local info = stub.traits.tree_info[treeID] or {}
		return { ID = treeID, gates = info.gates or {}, hideSingleRankNumbers = info.hideSingleRankNumbers == true,
			cannotRefund = false }
	end

	-- A list of { groupID, treeID, orderIndex, displayName }.
	function T.GetGroupDisplayInfoByTreeID(treeID)
		number_arg(treeID, 'local displayInfos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)')
		local out = {}
		for i, g in ipairs(stub.traits.groups[treeID] or {}) do
			out[i] = { groupID = g.groupID, treeID = treeID, skillLineID = 0, orderIndex = g.orderIndex,
				displayName = g.displayName, icon = 0 }
		end
		return out
	end

	-- A list of { ID, amount }.
	function T.GetNodeCost(configID, nodeID)
		number_arg(configID, 'local costs = C_Traits.GetNodeCost(configID, nodeID)')
		number_arg(nodeID, 'local costs = C_Traits.GetNodeCost(configID, nodeID)')
		local out = {}
		for i, c in ipairs(stub.traits.costs[nodeID] or {}) do out[i] = { ID = c.ID, amount = c.amount } end
		return out
	end

	-- A list of { traitCurrencyID, quantity, maxQuantity, spent }.
	function T.GetTreeCurrencyInfo(configID, treeID, excludeStagedChanges)
		number_arg(configID, 'local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, excludeStagedChanges)')
		number_arg(treeID, 'local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, excludeStagedChanges)')
		if type(excludeStagedChanges) ~= 'boolean' then
			error('Usage: local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, excludeStagedChanges)', 2)
		end
		local out = {}
		for i, c in ipairs(stub.traits.currency or {}) do
			out[i] = { traitCurrencyID = c.traitCurrencyID, quantity = c.quantity, maxQuantity = c.maxQuantity, spent = c.spent or 0 }
		end
		return out
	end

	function T.GetEntryInfo(configID, entryID)
		number_arg(configID, 'local entryInfo = C_Traits.GetEntryInfo(configID, entryID)')
		number_arg(entryID, 'local entryInfo = C_Traits.GetEntryInfo(configID, entryID)')
		local entry = stub.traits.entries[entryID]
		if not entry then return nil end
		return { definitionID = entry.definitionID, subTreeID = entry.subTreeID, type = entry.type or 1,
			maxRanks = entry.maxRanks or 1, isAvailable = true, isDisplayError = false, conditionIDs = {} }
	end

	function T.GetDefinitionInfo(definitionID)
		number_arg(definitionID, 'local definitionInfo = C_Traits.GetDefinitionInfo(definitionID)')
		local def = stub.traits.definitions[definitionID]
		if not def then return nil end
		return { spellID = def.spellID, overrideName = def.overrideName, overrideIcon = def.overrideIcon }
	end

	function T.GetConditionInfo(configID, condID)
		number_arg(configID, 'local condInfo = C_Traits.GetConditionInfo(configID, condID)')
		number_arg(condID, 'local condInfo = C_Traits.GetConditionInfo(configID, condID)')
		local cond = stub.traits.conditions[condID]
		if not cond then return nil end
		return { condID = condID, isAlwaysMet = false, isMet = cond.isMet == true, isGate = cond.isGate == true,
			isSufficient = false, type = 0, spentAmountRequired = cond.spentAmountRequired,
			traitCurrencyID = cond.traitCurrencyID }
	end

	-- nodeIDsWithPurchases, nodeIDsWithRefunds, nodeIDsWithSelectionSwaps; nothing when none is staged.
	function T.GetStagedChanges(configID)
		number_arg(configID, 'local nodeIDsWithPurchases, nodeIDsWithRefunds, nodeIDsWithSelectionSwaps = C_Traits.GetStagedChanges(configID)')
		local staged = stub.traits.staged[configID]
		if not staged or (#(staged.purchases or {}) == 0 and #(staged.refunds or {}) == 0) then return end
		local purchases, refunds = {}, {}
		for i, id in ipairs(staged.purchases or {}) do purchases[i] = id end
		for i, id in ipairs(staged.refunds or {}) do refunds[i] = id end
		return purchases, refunds, {}
	end

	function T.PurchaseRank(configID, nodeID)
		number_arg(configID, 'local success = C_Traits.PurchaseRank(configID, nodeID)')
		number_arg(nodeID, 'local success = C_Traits.PurchaseRank(configID, nodeID)')
		call('PurchaseRank')
		return false
	end

	function T.RefundRank(configID, nodeID, clearEdges)
		number_arg(configID, 'local success = C_Traits.RefundRank(configID, nodeID [, clearEdges])')
		number_arg(nodeID, 'local success = C_Traits.RefundRank(configID, nodeID [, clearEdges])')
		call('RefundRank')
		return false
	end

	function T.CommitConfig(configID)
		number_arg(configID, 'local success = C_Traits.CommitConfig(configID)')
		call('CommitConfig')
		return false
	end

	function C_ClassTalents.GetActiveConfigID()
		return stub.traits.group_configs[stub.traits.active_group]
	end

	function C_ClassTalents.HasUnspentTalentPoints()
		return stub.traits.unspent, 0, 0
	end

	function C_SpecializationInfo.GetActiveSpecGroup(isInspect, isPet)
		return stub.traits.active_group
	end

	function C_SpecializationInfo.GetCombatConfigIDForSpecGroup(groupIndex)
		number_arg(groupIndex, 'local configID = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(groupIndex)')
		return stub.traits.group_configs[groupIndex]
	end

	function C_Spell.GetSpellName(spellIdentifier)
		number_arg(spellIdentifier, 'local name = C_Spell.GetSpellName(spellIdentifier)')
		local spell = stub.traits.spells[spellIdentifier]
		return spell and spell.name or nil
	end

	function C_Spell.GetSpellTexture(spellIdentifier)
		number_arg(spellIdentifier, 'local iconID, originalIconID, conditionalIconID = C_Spell.GetSpellTexture(spellIdentifier)')
		local spell = stub.traits.spells[spellIdentifier]
		if not spell then return end
		return spell.icon, spell.icon
	end
end
