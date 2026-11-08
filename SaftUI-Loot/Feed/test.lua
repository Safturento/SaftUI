-- Feed test mode. While LT.testFeed is on, a timer pushes varied fake entries
-- through LT:LootFeedHandler, the same path real chat messages take, so the
-- pattern matching, icons and filters all get exercised. Entries are tagged
-- (info.test, see LT:LootFeedPush) so turning test mode off removes only them,
-- and tagged entries are never saved. The state is a plain module field: it is
-- never saved and resets on /reload.

local st = SaftUI
local LT = st:GetModule('Loot')

local PUSH_INTERVAL = 1

-- A spread of qualities. Item data can be uncached, so these are looked up by
-- ID and skipped (after requesting a load) until the client knows them.
local TEST_ITEMS = {
	7073,   -- Broken Fang (poor)
	2589,   -- Linen Cloth (common)
	1204,   -- The Green Tower (uncommon)
	16309,  -- Drakefire Amulet (rare)
	18814,  -- Choker of the Fire Lord (epic)
	19019,  -- Thunderfury (legendary)
	45693,  -- Mimiron's Head (mount, epic; retail only)
}

local TEST_CURRENCIES = { 1767, 1828, 515, 1220 }

local TEST_FACTIONS = { 'Stormwind', 'Orgrimmar', 'Darnassus', 'Thunder Bluff' }

local TEST_SKILLS = { 'Swords', 'Defense', 'Mining', 'Blacksmithing', 'Herbalism' }

-- Returns an item link the client has data for, or nil (and asks for the data
-- so a later tick can use it) when the item isn't cached.
local function GetTestItemLink(itemID)
	local _, link = C_Item.GetItemInfo(itemID)
	if not link and C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	return link
end

local function PickRandomItemLink()
	-- Bounded: try each item at most once, starting from a random one.
	local start = random(#TEST_ITEMS)
	for offset = 0, #TEST_ITEMS - 1 do
		local link = GetTestItemLink(TEST_ITEMS[(start + offset - 1) % #TEST_ITEMS + 1])
		if link then return link end
	end
end

local function PickCurrencyLink()
	if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyLink) then return end
	local start = random(#TEST_CURRENCIES)
	for offset = 0, #TEST_CURRENCIES - 1 do
		local id = TEST_CURRENCIES[(start + offset - 1) % #TEST_CURRENCIES + 1]
		local link = C_CurrencyInfo.GetCurrencyLink(id, random(1, 50))
		if link and C_CurrencyInfo.GetCurrencyInfoFromLink(link) then return link end
	end
end

-- A faction from the character's own reputation list, so test entries find
-- real standing data and show a progress bar. The fixed names are the
-- fallback when the list has nothing to offer.
local function PickTestFaction()
	local names = {}
	if C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex then
		for index = 1, C_Reputation.GetNumFactions() do
			local data = C_Reputation.GetFactionDataByIndex(index)
			if data and (not data.isHeader or data.isHeaderWithRep)
				and not issecretvalue(data.name) and type(data.name) == 'string' and data.name ~= '' then
				tinsert(names, data.name)
			end
		end
	end
	if #names > 0 then return names[random(#names)] end
	return TEST_FACTIONS[random(#TEST_FACTIONS)]
end

-- Sample rolls for a roll result: someone else won, you won, or everyone
-- passed. The other names are made up.
local function SampleRolls()
	local S = LT.ROLL_STATE
	local variant = random(3)
	if variant == 3 then return { allPassed = true, list = {} } end

	local me = UnitName('player')
	local _, myClass = UnitClass('player')
	local list
	if variant == 1 then
		list = {
			{ name = 'Brightblade', class = 'PALADIN', state = S.NeedMainSpec, roll = 92, isWinner = true },
			{ name = me, class = myClass, state = S.NeedMainSpec, roll = 71, isSelf = true },
		}
	else
		list = {
			{ name = me, class = myClass, state = S.NeedMainSpec, roll = 97, isSelf = true, isWinner = true },
			{ name = 'Brightblade', class = 'PALADIN', state = S.NeedMainSpec, roll = 92 },
		}
	end
	tinsert(list, { name = 'Mistweave', class = 'PRIEST', state = S.NeedOffSpec, roll = 88 })
	tinsert(list, { name = 'Quickshot', class = 'HUNTER', state = S.Greed, roll = 64 })
	tinsert(list, { name = 'Emberfall', class = 'MAGE', state = S.Pass })
	tinsert(list, { name = 'Duskwhisper', class = 'ROGUE', state = S.Pass })
	return { winner = 1, list = list }
end

local function MoneyString()
	local gold, silver, copper = random(0, 25), random(0, 99), random(0, 99)
	return ('%s %s %s'):format(
		GOLD_AMOUNT:format(gold), SILVER_AMOUNT:format(silver), COPPER_AMOUNT:format(copper))
end

-- Each generator pushes one entry, or does nothing when its data isn't
-- available on this client (uncached item, unknown global string).
local generators = {
	-- items, single and stacked
	function(self)
		local link = PickRandomItemLink()
		if link then self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(link)) end
	end,
	function(self)
		local link = PickRandomItemLink()
		if link then
			self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(link, random(2, 20)))
		end
	end,
	function(self)
		local link = GetTestItemLink(TEST_ITEMS[#TEST_ITEMS])
		if link then self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(link)) end
	end,
	-- gold
	function(self)
		self:LootFeedHandler('CHAT_MSG_MONEY', YOU_LOOT_MONEY:format(MoneyString()))
	end,
	-- currency
	function(self)
		local link = PickCurrencyLink()
		if link and CURRENCY_GAINED then
			self:LootFeedHandler('CHAT_MSG_CURRENCY', CURRENCY_GAINED:format(link))
		end
	end,
	-- skill up
	function(self)
		self:LootFeedHandler('CHAT_MSG_SKILL',
			SKILL_RANK_UP:format(TEST_SKILLS[random(#TEST_SKILLS)], random(2, 300)))
	end,
	-- experience
	function(self)
		self:LootFeedHandler('CHAT_MSG_COMBAT_XP_GAIN', ('You gain %d experience.'):format(random(50, 5000)))
	end,
	-- reputation
	function(self)
		if not FACTION_STANDING_INCREASED then return end
		self:LootFeedHandler('CHAT_MSG_COMBAT_FACTION_CHANGE',
			FACTION_STANDING_INCREASED:format(PickTestFaction(), random(5, 250)))
	end,
	-- honor: the feed has no chat pattern for honor, so hand it to the honor
	-- builder directly with the fields a match would carry
	function(self)
		self:LootFeedAddHonor({ honor = random(10, 500) })
	end,
	-- roll result: these come from the loot history, not chat, so the sample
	-- is built and pushed directly. It never touches the recorded drops.
	function(self)
		local link = PickRandomItemLink()
		if not link then return end
		local info = self:BuildRollEntry(link, SampleRolls())
		if info then self:LootFeedPush(info) end
	end,
}

local last_generator

local function PushTestEntry(self)
	local index = random(#generators)
	if index == last_generator then index = index % #generators + 1 end
	last_generator = index

	-- LootFeedPush tags entries pushed while this flag is up.
	self.pushingTest = true
	local ok, err = pcall(generators[index], self)
	self.pushingTest = nil
	if not ok then st:Error('Loot feed test mode:', err) end
end

local function OnTestUpdate(driver, elapsed)
	if st:barrier(driver, elapsed, PUSH_INTERVAL) then return end
	PushTestEntry(LT)
end

function LT:SetTestFeed(enabled)
	enabled = enabled and true or false
	if enabled == (self.testFeed or false) then return end
	if not self.feed then return end

	self.testFeed = enabled or nil

	if enabled then
		self.testFeedDriver = self.testFeedDriver or CreateFrame('frame')
		self.testFeedDriver.barrierTime = 0
		self.testFeedDriver:SetScript('OnUpdate', OnTestUpdate)
		self.debugText:Show()

		-- Don't wait a second for the first entries.
		for _ = 1, 3 do PushTestEntry(self) end
	else
		if self.testFeedDriver then
			self.testFeedDriver:SetScript('OnUpdate', nil)
		end
		self.debugText:Hide()
		self:RemoveTestFeedEntries()
	end
end
