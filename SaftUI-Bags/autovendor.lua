local st = SaftUI
local INV = st:GetModule('Inventory')

local vendorHandler = CreateFrame('frame')
INV.vendorFrame = vendorHandler -- for the tests, which drive its OnUpdate and OnEvent

-- A merchant's buyback list holds the last 12 things sold, one entry for each
-- stack (Blizzard's MerchantFrame.lua: BUYBACK_ITEMS_PER_PAGE = 12 on both
-- clients, and it lists GetNumBuybackItems() entries, the newest last). That is
-- how much of a sale can be undone. The game's constant is read when asked, the
-- named number is for a client that gives none.
local BUYBACK_SIZE = 12
-- Blizzard throttles selling, so a pass runs every 2 seconds until nothing is left.
local PASS_SECONDS = 2
-- A stack still in its slot after this many tries is one the merchant won't
-- take, and is left for this visit.
local MAX_TRIES = 3
-- The most valuable items the question names.
local NAMED = 3

function INV:BuybackSize()
	local size = _G.BUYBACK_ITEMS_PER_PAGE
	if type(size) == 'number' and size > 0 then return size end
	return BUYBACK_SIZE
end

local function IsGray(info)
	return (info.quality or 0) == 0
end

-- The order of a sale: grays first, then everything else; each cheapest stack
-- first (its price times its count), then by bag and slot so it is always the
-- same. The buyback list keeps the most recent sales, so selling the most
-- valuable last leaves them in it, and the first to go are the ones a player
-- would least want back.
local function SaleOrder(a, b)
	local grayA, grayB = IsGray(a), IsGray(b)
	if grayA ~= grayB then return grayA end
	if a.stackPrice ~= b.stackPrice then return a.stackPrice < b.stackPrice end
	if a.bagID ~= b.bagID then return a.bagID < b.bagID end
	return a.slotID < b.slotID
end

-- What auto vendor sells, from the bags themselves, so it is the same in every
-- view (One bag and Multi bag keep no Grays/Auto Vendor frame): one info per
-- slot, never merged stacks, in the order they are sold (SaleOrder), with the
-- profit of them all.
function INV:GetVendorItems()
	local items = {}
	local profit = 0

	local bags, _, _, categoryOf = self:ReadBags('bag', function(bagID) return self:StackGroup(bagID) end, true)
	for _, bag in ipairs(bags) do
		for _, info in ipairs(bag.items) do
			if self:IsAutoVendorItem(info, categoryOf[info]) then
				tinsert(items, info)
				profit = profit + info.stackPrice
			end
		end
	end

	table.sort(items, SaleOrder)
	return items, profit
end

local function Gold(money)
	local format = st.StringFormat
	if format and format.GoldFormat then return format:GoldFormat(money) end
	return tostring(money)
end

local function InCombat()
	return UnitAffectingCombat('player') or InCombatLockdown()
end

-- The visit now at a merchant: what was sold (counted from the slots the sales
-- emptied, not from what was asked for), the stacks asked of the game last pass
-- and how many times each was tried, and the answer to the question
-- ('sell' | 'keep', nil before it is answered and asking while it is up).
local visit

local function SlotKey(info)
	return info.bagID .. ':' .. info.slotID .. ':' .. info.itemID
end

-- Counts the stacks last pass sold: one that is gone from its slot (or has
-- changed there) was sold; one still there was not.
local function Account(v)
	for _, entry in ipairs(v.attempted) do
		local now = C_Container.GetContainerItemInfo(entry.bagID, entry.slotID)
		if not now or now.itemID ~= entry.itemID or now.stackCount ~= entry.count then
			v.sold = v.sold + 1
			v.money = v.money + entry.price
		end
	end
	v.attempted = {}
end

local function Finish(v)
	if v.done then return end
	Account(v)
	v.done = true
	vendorHandler:SetScript('OnUpdate', nil)
	if visit == v then visit = nil end
	-- A question left open is taken away (its No does nothing now).
	local W = st.OptionsWidgets
	if v.question and W and W.ConfirmText and W.ConfirmText() == v.question then W.CancelConfirm() end
	if v.sold > 0 then
		st:Print(('Sold %d item%s for %s.'):format(v.sold, v.sold == 1 and '' or 's', Gold(v.money)))
	end
end

-- The question before a sale of more non-grays than a buyback list holds:
-- how many, what they fetch, the few most valuable by name.
local function QuestionText(rest)
	local total = 0
	local byValue = {}
	for i, info in ipairs(rest) do
		total = total + info.stackPrice
		byValue[i] = info
	end
	table.sort(byValue, function(a, b)
		if a.stackPrice ~= b.stackPrice then return a.stackPrice > b.stackPrice end
		if a.bagID ~= b.bagID then return a.bagID < b.bagID end
		return a.slotID < b.slotID
	end)
	local names = {}
	for i = 1, math.min(NAMED, #byValue) do
		local info = byValue[i]
		names[i] = info.name .. ((info.count or 1) > 1 and (' x' .. info.count) or '')
	end
	local more = #byValue - #names
	return ("Auto Vendor caught %d items that aren't junk, worth %s, and a merchant's buyback holds only the last %d you sell. Most valuable: %s%s. Sell them, or keep them in your bags this visit?")
		:format(#rest, Gold(total), INV:BuybackSize(), table.concat(names, ', '),
			more > 0 and (' and ' .. more .. ' more') or '')
end

local function Ask(v, rest)
	local W = st.OptionsWidgets
	if not (W and W.Confirm) then
		v.decision = 'keep'
		st:Print(("Auto Vendor kept %d items that aren't junk; it couldn't ask."):format(#rest))
		return
	end
	v.decision = 'asking'
	v.question = QuestionText(rest)
	W.Confirm(v.question,
		function() if not v.done and v.decision == 'asking' then v.decision = 'sell' end end,
		function() if not v.done and v.decision == 'asking' then v.decision = 'keep' end end,
		'Sell them', 'Keep them')
end

local function Sell(v, info)
	local key = SlotKey(info)
	v.tries[key] = (v.tries[key] or 0) + 1
	tinsert(v.attempted, { bagID = info.bagID, slotID = info.slotID, itemID = info.itemID,
		count = info.count, price = info.stackPrice })
	C_Container.UseContainerItem(info.bagID, info.slotID)
end

-- One pass of the sale at the open merchant. Returns whether to go on: false
-- once the merchant is closed or nothing is left to sell. Grays go at once; the
-- rest go when there are no more than a buyback list holds, or once the question
-- is answered Sell them. Keep them sells nothing more this visit.
function INV:VendorPass()
	local v = visit
	if not v or v.done then return false end
	Account(v)
	if not (MerchantFrame and MerchantFrame:IsShown()) then
		Finish(v)
		return false
	end
	if InCombat() then return true end

	local grays, rest = {}, {}
	for _, info in ipairs(self:GetVendorItems()) do
		if (v.tries[SlotKey(info)] or 0) < MAX_TRIES then
			tinsert(IsGray(info) and grays or rest, info)
		end
	end

	local sellRest = false
	if #rest > 0 then
		if v.decision == 'keep' then
			-- Nothing more this visit.
		elseif v.decision == 'sell' or #rest <= self:BuybackSize() then
			sellRest = true
		elseif v.decision == nil then
			Ask(v, rest)
		end
	end

	for _, info in ipairs(grays) do Sell(v, info) end
	if sellRest then
		for _, info in ipairs(rest) do Sell(v, info) end
	end

	if #grays == 0 and not sellRest and v.decision ~= 'asking' then
		Finish(v)
		return false
	end
	return true
end

function INV:AutoVendor()
	if visit then Finish(visit) end
	visit = { sold = 0, money = 0, attempted = {}, tries = {} }
	vendorHandler.timeLeft = 0
	vendorHandler:SetScript('OnUpdate', function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft > 0 then return end
		self.timeLeft = PASS_SECONDS
		if not INV:VendorPass() then self:SetScript('OnUpdate', nil) end
	end)
end

-- The merchant closed: the sale ends where it is, and a question still up goes.
function INV:HandleMerchantClosed()
	if visit then Finish(visit) end
end

vendorHandler:RegisterEvent('MERCHANT_CLOSED')
vendorHandler:SetScript('OnEvent', function(_, event)
	if event == 'MERCHANT_CLOSED' then INV:HandleMerchantClosed() end
end)

function INV:HandleMerchant()
	-- Vendor greys and other selected items
	if UnitAffectingCombat('player') then
		st:Print('Cannot vendor in combat, reopen after leaving combat.')
		return
	else
		if self.config.autovendor then
			INV:AutoVendor()
		end
	end

	-- Auto repair gear
	if self.config.autorepair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()

		repairAllCost, canRepair = GetRepairAllCost()

		if canRepair and repairAllCost > 0 and repairAllCost < GetMoney() then
			RepairAllItems()
			st:Print('Repaired all items for ' .. st.StringFormat:GoldFormat(repairAllCost))
		elseif repairAllCost > 0 then
			st:Print('Insufficient funds for gear repair.')
		end

	end
end