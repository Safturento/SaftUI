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

-- At most 12: the page size is a UI number another addon could raise, the
-- server's capacity is not in the UI source. A smaller one only asks sooner.
function INV:BuybackSize()
	local size = _G.BUYBACK_ITEMS_PER_PAGE
	if type(size) == 'number' and size > 0 then return math.min(size, BUYBACK_SIZE) end
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

-- The visit now at a merchant. What it keeps:
--   sold, money   what was sold (counted from the slots the sales emptied, not
--                 from what was asked for);
--   attempted     the stacks asked of the game last pass;
--   tries         how many times each stack was tried; gaveUp, the stacks left
--                 after MAX_TRIES;
--   tailStarted   a non-gray stack has been sold: from then on every stack
--                 sold of any quality pushes the buyback list along, so each
--                 counts (tailSold) toward its size. Grays are sold before it
--                 starts and not after, unless they fit the count;
--   decision      nil, 'asking' (the question is up: nothing counted in it
--                 sells), 'sell' or 'keep'; asked, the stacks the question
--                 named (by bag, slot and item, with their count), which are
--                 the only ones Sell them sells; question, its token, so a
--                 question taken down can't be answered later.
-- The promise of a visit: every non-gray stack sold without asking is still in
-- the buyback list when it ends.
local visit

local function SlotKey(info)
	return info.bagID .. ':' .. info.slotID .. ':' .. info.itemID
end

-- Counts the stacks last pass sold: one that is gone from its slot (or has
-- changed there) was sold; one still there was not, and is returned.
local function Account(v)
	local left = {}
	for _, entry in ipairs(v.attempted) do
		local now = C_Container.GetContainerItemInfo(entry.bagID, entry.slotID)
		if not now or now.itemID ~= entry.itemID or now.stackCount ~= entry.count then
			v.sold = v.sold + 1
			v.money = v.money + entry.price
			if entry.tail then v.tailSold = v.tailSold + 1 end
		else
			left[#left + 1] = entry
		end
	end
	v.attempted = {}
	return left
end

local function Name(info)
	return info.link or info.name
end

local function Summary(v)
	local text = ''
	if v.sold > 0 then
		text = ('Sold %d item%s for %s.'):format(v.sold, v.sold == 1 and '' or 's', Gold(v.money))
	end
	-- The stacks the merchant would not take, still in their slots.
	local names = {}
	for _, info in pairs(v.gaveUp) do
		local now = C_Container.GetContainerItemInfo(info.bagID, info.slotID)
		if now and now.itemID == info.itemID then names[#names + 1] = Name(info) end
	end
	table.sort(names)
	if #names > 0 then
		text = text .. (text ~= '' and ' ' or '') .. ("Couldn't sell %d stack%s: %s."):format(#names, #names == 1 and '' or 's', table.concat(names, ', '))
	end
	if text ~= '' then st:Print(text) end
end

-- Takes the question down, if it is ours.
local function TakeDownQuestion(v)
	local W = st.OptionsWidgets
	local text = v.questionText
	v.question, v.questionText = nil, nil
	if text and W and W.ConfirmText and W.ConfirmText() == text then W.CancelConfirm() end
end

-- late: the merchant closed, so a sale asked of the game in the last pass may
-- still be on its way: the summary waits a second for it.
local function Finish(v, late)
	if v.done then return end
	local left = Account(v)
	v.done = true
	vendorHandler:SetScript('OnUpdate', nil)
	if visit == v then visit = nil end
	TakeDownQuestion(v)
	if late and #left > 0 and C_Timer and C_Timer.After then
		C_Timer.After(1, function()
			v.attempted = left
			Account(v)
			Summary(v)
		end)
		return
	end
	Summary(v)
end

-- The question before a sale that would push a non-gray out of the buyback
-- list: how many stacks, what they fetch at a vendor, the few most valuable
-- as links (their quality color shows).
local function QuestionText(stacks)
	local total = 0
	local byValue = {}
	for i, info in ipairs(stacks) do
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
		names[i] = Name(info) .. ((info.count or 1) > 1 and (' x' .. info.count) or '')
	end
	local more = #byValue - #names
	return ("Auto Vendor would sell %d stacks that aren't junk, worth %s at a vendor, and a merchant's buyback holds only the last %d you sell. Most valuable by vendor price: %s%s. Sell them, or keep them in your bags this visit?")
		:format(#stacks, Gold(total), INV:BuybackSize(), table.concat(names, ', '),
			more > 0 and (' and ' .. more .. ' more') or '')
end

local function Ask(v, stacks)
	local W = st.OptionsWidgets
	if not (W and W.Confirm) then
		v.decision = 'keep'
		st:Print(("Auto Vendor kept %d stacks that aren't junk; it couldn't ask."):format(#stacks))
		return
	end
	local token = {}
	v.decision = 'asking'
	v.question = token
	v.asked = {}
	for _, info in ipairs(stacks) do v.asked[SlotKey(info)] = info.count end
	v.questionText = QuestionText(stacks)
	-- Enter answers nothing: a stray Enter must not sell what can't all be
	-- bought back. Only a click answers, and Esc is Keep them.
	W.Confirm(v.questionText,
		function() if not v.done and v.question == token then v.decision = 'sell' end end,
		function() if not v.done and v.question == token then v.decision = 'keep' end end,
		{ yes = 'Sell them', no = 'Keep them', enter = false })
end

-- The stack's quality as the game gives it now; nil when it doesn't.
local function QualityOf(info)
	local now = C_Container.GetContainerItemInfo(info.bagID, info.slotID)
	return now and now.quality
end

-- Sells one stack, if it is still what was read: the same item and count in
-- the slot, not locked, with a known quality (a gray, for a gray sold before
-- the tail). Returns whether it asked the game.
local function Sell(v, info, tail)
	local now = C_Container.GetContainerItemInfo(info.bagID, info.slotID)
	if not now or now.itemID ~= info.itemID or now.stackCount ~= info.count or now.locked then return false end
	if now.quality == nil or (not tail and now.quality ~= 0) then return false end
	local key = SlotKey(info)
	v.tries[key] = (v.tries[key] or 0) + 1
	if tail then v.tailStarted = true end
	tinsert(v.attempted, { bagID = info.bagID, slotID = info.slotID, itemID = info.itemID,
		count = info.count, price = info.stackPrice, tail = tail })
	C_Container.UseContainerItem(info.bagID, info.slotID)
	return true
end

-- One pass of the sale at the open merchant. Returns whether to go on: false
-- once the merchant is closed, the setting off or nothing is left to sell.
--   * Grays go first and alone: the non-grays wait for a pass with no gray
--     left, so a gray the server was slow on is never sold after them.
--   * From the first non-gray sold, every stack sold counts toward the
--     buyback size. The stacks left to sell (the non-grays, and a gray that
--     turned up late) are sold when they fit it; when they would not, it asks.
--   * While it asks nothing in it sells. Sell them sells the stacks the
--     question named, as they are at that moment; any other needs its own
--     question. Keep them sells no more non-grays this visit.
function INV:VendorPass()
	local v = visit
	if not v or v.done then return false end
	if not self.config.autovendor then
		Finish(v)
		return false
	end
	Account(v)
	if not (MerchantFrame and MerchantFrame:IsShown()) then
		Finish(v, true)
		return false
	end
	if InCombat() then return true end

	local grays, rest = {}, {}
	local waiting = false
	for _, info in ipairs(self:GetVendorItems()) do
		local key = SlotKey(info)
		if (v.tries[key] or 0) >= MAX_TRIES then
			v.gaveUp[key] = info
		elseif info.locked then
			waiting = true -- not now, and no try used
		else
			local quality = QualityOf(info)
			if quality == nil then waiting = true end -- not sold until it is known
			tinsert(quality == 0 and grays or rest, info)
		end
	end

	local acted = false
	if not v.tailStarted then
		for _, info in ipairs(grays) do
			if Sell(v, info, false) then acted = true end
		end
	end

	-- What is left to sell with the buyback list in mind.
	local stacks = rest
	if v.tailStarted and #grays > 0 then
		stacks = {}
		for _, info in ipairs(grays) do tinsert(stacks, info) end
		for _, info in ipairs(rest) do tinsert(stacks, info) end
	end
	local grayFirst = not v.tailStarted and #grays > 0 -- the grays go before any of the others

	-- With no answer to go by: sell what fits the buyback list, or ask.
	local function Decide(list)
		if v.tailSold + #list > self:BuybackSize() then
			Ask(v, list)
			waiting = true
		elseif grayFirst then
			waiting = true
		else
			for _, info in ipairs(list) do
				if Sell(v, info, true) then acted = true end
			end
		end
	end

	if #stacks > 0 and v.decision ~= 'keep' then
		if v.decision == 'asking' then
			waiting = true
		elseif v.decision == 'sell' then
			local named, unnamed = {}, {}
			for _, info in ipairs(stacks) do
				tinsert(v.asked[SlotKey(info)] == info.count and named or unnamed, info)
			end
			if grayFirst then
				waiting = true
			else
				for _, info in ipairs(named) do
					if Sell(v, info, true) then acted = true end
				end
				if #unnamed > 0 then
					if #named == 0 then
						-- What the question named is done: the rest is its own question.
						v.decision, v.asked = nil, nil
						Decide(unnamed)
					else
						waiting = true
					end
				end
			end
		else
			Decide(stacks)
		end
	end

	if acted or waiting or v.decision == 'asking' then return true end
	Finish(v)
	return false
end

function INV:AutoVendor()
	if visit then Finish(visit) end
	visit = { sold = 0, money = 0, tailSold = 0, attempted = {}, tries = {}, gaveUp = {} }
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
	if visit then Finish(visit, true) end
end

-- A fight with the question up: it comes down (and its full-screen key catcher
-- with it: the game won't let a frame hand keys on in combat), counts as not
-- answered, and is asked again once the fight is over if the sale still needs it.
function INV:HandleCombatStart()
	local v = visit
	if v and v.decision == 'asking' then
		v.decision, v.asked = nil, nil
		TakeDownQuestion(v)
	end
end

vendorHandler:RegisterEvent('MERCHANT_CLOSED')
vendorHandler:RegisterEvent('PLAYER_REGEN_DISABLED')
vendorHandler:SetScript('OnEvent', function(_, event)
	if event == 'MERCHANT_CLOSED' then INV:HandleMerchantClosed()
	elseif event == 'PLAYER_REGEN_DISABLED' then INV:HandleCombatStart() end
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