-- How auto vendor sells at a merchant (SaftUI-Bags/autovendor.lua): grays
-- first, then everything else the rules catch, cheapest stack first (the
-- buyback list keeps the most recent 12 sold, so what is left in it is the most
-- valuable); more than a buyback list's worth of non-grays asks before selling
-- them (sell them, or keep them this visit); the throttle, combat, the merchant
-- closing and the chat summary. bags/bag_world.lua's bags under
-- bags/container_helpers.lua's views world, with a merchant, UseContainerItem
-- and the options kit's confirm dialog stood in.
local H = load_test_file('bags/container_helpers.lua')

local INV, W
local used, prints, prompt, asked

local function step()
	local frame = INV.vendorFrame
	local onUpdate = frame:GetScript('OnUpdate')
	if onUpdate then onUpdate(frame, 2) end
	return onUpdate ~= nil
end

local function open_merchant()
	MerchantFrame:Show()
	INV:HandleMerchant()
end

local function close_merchant()
	MerchantFrame:Hide()
	stub.fire_script(INV.vendorFrame, 'OnEvent', 'MERCHANT_CLOSED')
end

-- Grays: { id, unit price, count }, each in its own slot of bag 0. others: how
-- many pinned non-gray items, ids 700+, the price of the ith 5 * ((i * 7) % 13
-- + 1) so they are not in order of slot. Returns the ids of the others in slot
-- order.
local function world(grays, others)
	INV, W = H.views_world('forever')
	load_saftui('SaftUI-Bags/autovendor.lua')
	W.bag(0, 24, 'Backpack')
	W.bag(1, 32, 'Bag')
	local slot = 0
	local function put(item)
		slot = slot + 1
		if slot > 24 then W.put(1, slot - 24, item) else W.put(0, slot, item) end
	end
	for _, gray in ipairs(grays or {}) do
		put(W.item(gray[1], 'Gray ' .. gray[1], 'Miscellaneous', 1,
			{ quality = 0, vendorPrice = gray[2], count = gray[3] or 1, maxStack = 20 }))
	end
	local ids = {}
	for i = 1, others or 0 do
		local id = 700 + i
		put(W.item(id, 'Thing ' .. id, 'Miscellaneous', 1,
			{ quality = 1, vendorPrice = 5 * ((i * 7) % 13 + 1) }))
		INV:SetAutoVendorMark(id, true)
		ids[#ids + 1] = id
	end
	INV.config.bag.emptySlots = 'off'
	INV.config.autovendor = true
	INV.config.autorepair = false
	H.window('bag')

	used, prints, prompt, asked = {}, {}, nil, 0
	_G.MerchantFrame = CreateFrame('Frame', 'MerchantFrame', UIParent)
	MerchantFrame:Hide()
	-- Selling a stack takes it out of its slot, as the game does, unless the
	-- slot is one the merchant refuses.
	W.refused = {}
	-- W.slow holds the sales until W.flush() (a slow server).
	W.slow, W.queue = false, {}
	-- A sale in flight leaves its stack locked in its slot, as the game does.
	W.flush = function(count)
		local rest = {}
		for i, sale in ipairs(W.queue) do
			if not count or i <= count then W.bags[sale.bag].items[sale.slot] = nil else rest[#rest + 1] = sale end
		end
		W.queue = rest
	end
	C_Container.UseContainerItem = function(bagID, slotID)
		local item = W.bags[bagID].items[slotID]
		used[#used + 1] = { bag = bagID, slot = slotID, id = item and item.itemID }
		if item and MerchantFrame:IsShown() and not W.refused[item.itemID] then
			if W.slow then
				W.queue[#W.queue + 1] = { bag = bagID, slot = slotID }
				item.locked = true
			else W.bags[bagID].items[slotID] = nil end
		end
	end
	-- The stub's container info has no locked flag: an item's own.
	local info_of = C_Container.GetContainerItemInfo
	C_Container.GetContainerItemInfo = function(bagID, slotID)
		local info = info_of(bagID, slotID)
		if info then info.locked = W.bags[bagID].items[slotID].locked or false end
		return info
	end
	-- An item's GUID: its own, given the first time it is asked, so a stack
	-- put in a slot later (a purchase) has a GUID of its own.
	local guids = 0
	C_Item.GetItemGUID = function(location)
		local item = W.bags[location.bagID].items[location.slot]
		if not item or item.noguid then return nil end -- noguid: an item the game gives no GUID for
		if not item.guid then guids = guids + 1; item.guid = 'Item-1-' .. guids end
		return item.guid
	end
	SaftUI.Print = function(_, ...) prints[#prints + 1] = table.concat({ ... }, ' ') end
	SaftUI.StringFormat = { GoldFormat = function(_, money) return 'gold ' .. money end }
	SaftUI.OptionsWidgets = {
		Confirm = function(text, onYes, onNo, opts)
			asked = asked + 1
			prompt = { text = text, yes = onYes, no = onNo, opts = opts or {} }
		end,
		ConfirmText = function() return prompt and prompt.text end,
		CancelConfirm = function()
			local p = prompt
			prompt = nil
			if p and p.no then p.no() end
		end,
	}
	stub.in_combat = false
	return ids
end

local function sold_ids()
	local out = {}
	for _, u in ipairs(used) do out[#out + 1] = u.id end
	return out
end

local function csv(list) return table.concat(list, ',') end

local function answer(yes)
	local p = prompt
	prompt = nil
	if yes then p.yes() else p.no() end
end

------------------------------------------------------------------ order

test('the sale is grays first, then everything else, each from the cheapest stack up', function()
	-- Grays worth 30 (3 x 10), 20 and 20 (a tie, slots 2 and 3 break it), and
	-- five other items.
	world({ { 601, 10, 3 }, { 602, 20 }, { 603, 20 } }, 5)
	local items = INV:GetVendorItems()
	local order = {}
	for _, info in ipairs(items) do order[#order + 1] = info.bagID .. ':' .. info.slotID .. '=' .. info.stackPrice end
	-- The others: i = 1..5 -> 5 * (i * 7 % 13 + 1) = 40, 10, 45, 15, 50 in slots 4..8.
	eq(csv(order), '0:2=20,0:3=20,0:1=30,0:5=10,0:7=15,0:4=40,0:6=45,0:8=50',
		'grays by value (ties by bag and slot), then the others by value')
	open_merchant()
	step()
	step()
	eq(csv(sold_ids()), '602,603,601,702,704,701,703,705', 'and UseContainerItem is called in that order')
end)

test('a stack is worth its price times its count', function()
	world({ { 601, 10, 9 }, { 602, 50 } }, 0)
	local items = INV:GetVendorItems()
	eq(items[1].itemID, 602, 'one at 50 sells before nine at 10, both gray, the cheaper stack first')
	eq(items[2].itemID, 601, 'then the 90')
end)

------------------------------------------------------------------ the threshold

test('the limit is the buyback list: BUYBACK_ITEMS_PER_PAGE, 12 when the game gives none', function()
	world({}, 0)
	local saved = _G.BUYBACK_ITEMS_PER_PAGE
	_G.BUYBACK_ITEMS_PER_PAGE = nil
	eq(INV:BuybackSize(), 12, 'the buyback size with no game constant')
	_G.BUYBACK_ITEMS_PER_PAGE = 12
	eq(INV:BuybackSize(), 12, "the game's constant")
	_G.BUYBACK_ITEMS_PER_PAGE = 5
	eq(INV:BuybackSize(), 5, 'whatever it is')
	_G.BUYBACK_ITEMS_PER_PAGE = saved
end)

test('12 non-gray items sell with no prompt, with the grays and in the same visit', function()
	world({ { 601, 10 }, { 602, 10 } }, 12)
	open_merchant()
	step()
	eq(#used, 2, 'the grays go in the first pass, alone')
	step()
	eq(prompt, nil, 'no prompt at 12')
	eq(#used, 14, 'then the twelve')
	eq(csv(sold_ids()):sub(1, 7), '601,602', 'the grays first')
end)

test('13 non-gray items sell the grays and ask before the rest', function()
	world({ { 601, 10 }, { 602, 10 } }, 13)
	open_merchant()
	step()
	check(prompt ~= nil, 'a prompt')
	eq(csv(sold_ids()), '601,602', 'only the grays are sold, at once')
	eq(prompt.opts.yes, 'Sell them', 'the first answer sells')
	eq(prompt.opts.no, 'Keep them', 'the second keeps')
	eq(prompt.opts.enter, false, 'Enter answers nothing')
	step()
	step()
	eq(#used, 2, 'nothing more sold while it asks')
end)

test('grays never count toward the limit', function()
	local grays = {}
	for i = 1, 30 do grays[i] = { 600 + i, 10 } end
	world(grays, 12)
	open_merchant()
	step()
	step()
	eq(prompt, nil, '30 grays and 12 others: no prompt')
	eq(#used, 42, 'everything sold')
end)

test('a stack of an item counts once: it is one buyback entry', function()
	world({}, 12)
	-- One of the 12 is a stack of many; still 12 entries.
	W.bags[0].items[1].count = 20
	open_merchant()
	step()
	eq(prompt, nil, 'no prompt')
	eq(#used, 12, 'all sold')
end)

test('a priced-at-nothing item is never sold and never counts', function()
	world({}, 13)
	W.bags[0].items[1].vendorPrice = 0
	open_merchant()
	step()
	eq(prompt, nil, '13 pinned, one with no price: 12 count, no prompt')
	eq(#used, 12, 'twelve sold')
	for _, u in ipairs(used) do check(u.id ~= 701, 'the priceless one is not sold') end
end)

test('the limit follows the game: with a buyback of 5, six asks', function()
	world({}, 6)
	local saved = _G.BUYBACK_ITEMS_PER_PAGE
	_G.BUYBACK_ITEMS_PER_PAGE = 5
	open_merchant()
	step()
	_G.BUYBACK_ITEMS_PER_PAGE = saved
	check(prompt ~= nil, 'six asks at 5')
end)

------------------------------------------------------------------ the prompt

test('the prompt says how many, their total value and the most valuable by name', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	local total = 0
	for i = 1, 13 do total = total + 5 * ((i * 7) % 13 + 1) end
	check(prompt.text:find('13 stacks', 1, true), 'how many: ' .. prompt.text)
	check(prompt.text:find('gold ' .. total, 1, true), 'their total value: ' .. prompt.text)
	local best = {}
	for i = 1, 13 do best[#best + 1] = { id = 700 + i, price = 5 * ((i * 7) % 13 + 1) } end
	table.sort(best, function(a, b) if a.price ~= b.price then return a.price > b.price end return a.id < b.id end)
	for k = 1, 3 do
		check(prompt.text:find('Thing ' .. best[k].id, 1, true), 'names the ' .. k .. 'th most valuable: ' .. prompt.text)
	end
	check(not prompt.text:find('Thing ' .. best[13].id, 1, true), 'and not the cheapest')
	check(not prompt.text:find('Gray', 1, true), 'nothing about the grays')
end)

test('Sell them sells the rest, cheapest first, and the summary counts all of it', function()
	local ids = world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	answer(true)
	step()
	local order = sold_ids()
	eq(#order, 14, 'the gray and the 13')
	local prev = 0
	for k = 2, 14 do
		local item
		for i, id in ipairs(ids) do if id == order[k] then item = i end end
		local price = 5 * ((item * 7) % 13 + 1)
		check(price >= prev, 'ascending value at ' .. k)
		prev = price
	end
	step() -- nothing left: the visit ends and says what it sold
	eq(step(), false, 'the loop has stopped')
	local summary = prints[#prints]
	check(summary and summary:find('14', 1, true), 'the summary counts 14: ' .. tostring(summary))
end)

test('Keep them sells nothing more at this visit, however long it stays', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	answer(false)
	for _ = 1, 5 do step() end
	eq(#used, 1, 'only the gray was ever sold')
	eq(prompt, nil, 'and it does not ask again')
	local summary = prints[#prints]
	check(summary and summary:find('1 stack', 1, true), 'the summary counts the one: ' .. tostring(summary))
end)

test('Esc or a click outside the dialog (the dialog answers No) keeps them', function()
	world({}, 13)
	open_merchant()
	step()
	SaftUI.OptionsWidgets.CancelConfirm()
	step()
	eq(#used, 0, 'nothing sold')
end)

test('a second visit asks again when the rest is still over the limit', function()
	world({}, 13)
	open_merchant()
	step()
	answer(false)
	step()
	close_merchant()
	eq(prompt, nil, 'no prompt left')
	open_merchant()
	step()
	check(prompt ~= nil, 'asked again at the next visit')
	answer(true)
	step()
	eq(#used, 13, 'and Sell them sold them')
end)

test('the next visit starts fresh: what is under the limit sells with no prompt', function()
	world({}, 13)
	open_merchant()
	step()
	answer(true)
	step()
	close_merchant()
	W.bags[0].items[1] = W.item(701, 'Thing 701', 'Miscellaneous', 1, { quality = 1, vendorPrice = 10 })
	INV:SetAutoVendorMark(701, true)
	open_merchant()
	step()
	eq(#used, 14, 'under the limit now: sold with no prompt')
end)

------------------------------------------------------------------ the merchant closing

test('a merchant closed mid-sale stops the loop and says what was sold so far', function()
	world({ { 601, 10 } }, 3)
	open_merchant()
	step()
	step()
	close_merchant()
	eq(step(), false, 'the loop is gone')
	check(prints[#prints] and prints[#prints]:find('Sold 4 stacks', 1, true), 'summary: ' .. tostring(prints[#prints]))
end)

test('a merchant closed while the prompt is up takes the prompt away and sells nothing', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	close_merchant()
	eq(prompt, nil, 'the prompt is gone')
	eq(step(), false, 'the loop is gone')
	eq(#used, 1, 'only the gray')
end)

test('a late answer after the merchant closed sells nothing', function()
	world({}, 13)
	open_merchant()
	step()
	local p = prompt
	close_merchant()
	if p then p.yes() end
	step()
	eq(#used, 0, 'nothing sold at a closed merchant')
end)

test('the loop notices a merchant that closed without the event, too', function()
	world({ { 601, 10 } }, 3)
	open_merchant()
	step()
	MerchantFrame:Hide()
	eq(step(), true, 'the pass that finds it closed')
	eq(step(), false, 'and then it has stopped')
end)

------------------------------------------------------------------ combat

test('in combat nothing is sold and nothing is asked', function()
	world({ { 601, 10 } }, 13)
	stub.in_combat = true
	open_merchant()
	eq(#used, 0, 'nothing sold')
	eq(prompt, nil, 'nothing asked')
	eq(step(), false, 'no loop')
	check(prints[#prints] and prints[#prints]:find('combat', 1, true), 'it says why')
end)

test('a fight that starts mid-sale pauses it until the fight ends', function()
	world({ { 601, 10 }, { 602, 20 } }, 3)
	open_merchant()
	stub.in_combat = true
	step()
	eq(#used, 0, 'no sale during the fight')
	stub.in_combat = false
	step()
	check(#used > 0, 'it goes on after')
end)

------------------------------------------------------------------ what cannot sell, the summary

test('an item the merchant refuses is not in the summary, and the sale does not claim it', function()
	world({ { 601, 10 }, { 602, 20 } }, 0)
	W.refused[601] = true
	open_merchant()
	step()
	step()
	close_merchant()
	stub.time = stub.time + 1 -- the summary waits a second for sales still on their way
	stub.run_timers()
	local summary = prints[#prints]
	check(summary and summary:find('Sold 1 stack ', 1, true), 'one item: ' .. tostring(summary))
	check(summary:find('gold 20', 1, true), 'for what it fetched: ' .. summary)
end)

test('the summary has the count and the gold of what was sold, and none when nothing was', function()
	world({ { 601, 10, 2 }, { 602, 5 } }, 2)
	open_merchant()
	step()
	step()
	step()
	local summary = prints[#prints]
	check(summary:find('Sold 4 stacks', 1, true), summary)
	local expect = 20 + 5 + 5 * ((1 * 7) % 13 + 1) + 5 * ((2 * 7) % 13 + 1)
	check(summary:find('gold ' .. expect, 1, true), 'gold ' .. expect .. ' in ' .. summary)
	-- A visit with nothing to sell says nothing.
	world({}, 0)
	open_merchant()
	step()
	eq(#prints, 0, 'no summary for no sale')
end)

test('with the setting off nothing is sold', function()
	world({ { 601, 10 } }, 0)
	INV.config.autovendor = false
	open_merchant()
	eq(step(), false, 'no loop')
	eq(#used, 0, 'nothing sold')
end)

test('without the options kit it keeps the rest rather than sell it unasked', function()
	world({ { 601, 10 } }, 13)
	SaftUI.OptionsWidgets = nil
	open_merchant()
	step()
	step()
	eq(#used, 1, 'only the gray')
end)

test('the sale is throttled: a pass under two seconds after the last does nothing', function()
	world({ { 601, 10 } }, 0)
	open_merchant()
	local frame = INV.vendorFrame
	local onUpdate = frame:GetScript('OnUpdate')
	onUpdate(frame, 0.1)
	eq(#used, 1, 'the first pass at once')
	W.bags[0].items[1] = W.item(601, 'Gray 601', 'Miscellaneous', 1, { quality = 0, vendorPrice = 10 })
	onUpdate(frame, 0.5)
	eq(#used, 1, 'not again at 0.5 seconds')
	onUpdate(frame, 2)
	eq(#used, 2, 'again after two')
end)

------------------------------------------------------------------ fix round 1

local function count_prints(pattern)
	local n = 0
	for _, line in ipairs(prints) do if line:find(pattern, 1, true) then n = n + 1 end end
	return n
end

local function add_pinned(id, price, bag, slot)
	W.put(bag or 1, slot or 20, W.item(id, 'Thing ' .. id, 'Miscellaneous', 1, { quality = 1, vendorPrice = price }))
	INV:SetAutoVendorMark(id, true)
end

test('I-1: while the question is up nothing non-gray sells, whatever the count drops to', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	check(prompt ~= nil, 'asked')
	W.bags[0].items[2] = nil -- one leaves the bags, so 12 are left
	step()
	step()
	eq(#used, 1, 'only the gray is sold before the answer')
	check(prompt ~= nil, 'the question is still up')
	answer(true)
	step()
	eq(#used, 13, 'Sell them sells the 12 that are left')
end)

test('I-2: a gray the server dropped never sells after the non-grays', function()
	world({ { 601, 10 }, { 602, 10 } }, 12)
	W.refused[601] = true
	open_merchant()
	step()
	step()
	W.refused[601] = nil
	step()
	step()
	local order = sold_ids()
	local seen_non_gray = false
	for _, id in ipairs(order) do
		if id >= 700 then seen_non_gray = true end
		check(not (seen_non_gray and id < 700), 'no gray sold after a non-gray: ' .. csv(order))
	end
	local twelve = 0
	for _, id in ipairs(order) do if id >= 700 then twelve = twelve + 1 end end
	eq(twelve, 12, 'all twelve non-grays sold')
end)

test('I-2: a 13th stack that shows up after 12 were sold asks first', function()
	world({}, 12)
	open_merchant()
	step()
	eq(#used, 12, 'twelve sold')
	add_pinned(799, 999)
	step()
	eq(#used, 12, 'the 13th is not sold')
	check(prompt ~= nil, 'it asks')
	check(prompt.text:find('Thing 799', 1, true), 'about the new one')
end)

test('I-2: a stack that shows up while the visit is under the limit sells without asking', function()
	world({}, 3)
	open_merchant()
	step()
	add_pinned(799, 999)
	step()
	eq(#used, 4, 'sold')
	eq(prompt, nil, 'no question')
end)

test('I-2: a gray that shows up late counts toward the limit too', function()
	world({}, 12)
	open_merchant()
	step()
	W.put(1, 21, W.item(698, 'Late Gray', 'Miscellaneous', 1, { quality = 0, vendorPrice = 10 }))
	step()
	eq(#used, 12, 'not sold: it would push a non-gray out of the buyback list')
	check(prompt ~= nil, 'it asks')
end)

test('I-2: Sell them sells exactly the stacks the question named; a new one needs its own question', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	add_pinned(799, 999) -- worth more than everything named
	answer(true)
	step()
	local sold799 = false
	for _, id in ipairs(sold_ids()) do if id == 799 then sold799 = true end end
	eq(sold799, false, 'the stack the question did not name is not sold')
	eq(#used, 14, 'the gray and the 13 named')
	step()
	eq(asked, 2, 'it asks about the new one')
	check(prompt and prompt.text:find('Thing 799', 1, true), 'naming it')
	answer(false)
	step()
	step()
	eq(#used, 14, 'and Keep them keeps it')
end)

test('I-2: a named stack that is gone or changed at the moment of sale is not sold', function()
	world({}, 13)
	open_merchant()
	step()
	W.bags[0].items[1] = W.item(990, 'Impostor', 'Miscellaneous', 1, { quality = 1, vendorPrice = 1 })
	answer(true)
	step()
	for _, id in ipairs(sold_ids()) do check(id ~= 990, 'the impostor in a named slot is not sold') end
	eq(#used, 12, 'the other twelve are')
end)

test('I-3: the question takes Enter for nothing, Esc and a click for Keep them', function()
	world({}, 13)
	open_merchant()
	step()
	eq(prompt.opts.enter, false, 'Enter answers nothing')
	SaftUI.OptionsWidgets.CancelConfirm() -- what Esc and a click outside do
	step()
	eq(#used, 0, 'Keep them: nothing sold')
end)

test('I-4: combat taking the question down, and asking again after it', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	local first = prompt
	stub.in_combat = true
	stub.fire_script(INV.vendorFrame, 'OnEvent', 'PLAYER_REGEN_DISABLED')
	eq(prompt, nil, 'the question is down')
	step()
	eq(#used, 1, 'nothing sold in the fight')
	eq(prompt, nil, 'and none asked in it')
	stub.in_combat = false
	step()
	check(prompt ~= nil, 'asked again after the fight')
	eq(asked, 2, 'a second time')
	first.yes()
	step()
	eq(#used, 1, "the first question's Sell them no longer answers")
	answer(false)
	step()
	eq(#used, 1, 'Keep them keeps')
end)

test('I-4: combat with no question up changes nothing', function()
	world({}, 3)
	open_merchant()
	stub.fire_script(INV.vendorFrame, 'OnEvent', 'PLAYER_REGEN_DISABLED')
	stub.in_combat = false
	step()
	eq(#used, 3, 'sold')
end)

test('a merchant hidden without its event sells nothing more, whatever is answered', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	step()
	local p = prompt
	MerchantFrame:Hide()
	p.yes()
	step()
	eq(#used, 1, 'only the gray')
end)

test('M-1: the buyback size is at most 12 whatever the game says', function()
	world({}, 0)
	local saved = _G.BUYBACK_ITEMS_PER_PAGE
	_G.BUYBACK_ITEMS_PER_PAGE = 24
	eq(INV:BuybackSize(), 12, 'a bigger page does not raise it')
	_G.BUYBACK_ITEMS_PER_PAGE = 8
	eq(INV:BuybackSize(), 8, 'a smaller one lowers it')
	_G.BUYBACK_ITEMS_PER_PAGE = saved
end)

test('M-2: an item of unknown quality counts as non-gray and is not sold until it is known', function()
	world({}, 2)
	W.bags[0].items[2].quality = nil
	open_merchant()
	step()
	local sold = sold_ids()
	eq(#sold, 1, 'only the other one')
	eq(step(), true, 'the visit waits')
	W.bags[0].items[2].quality = 1
	step()
	eq(#used, 2, 'sold once its quality is known')
end)

test('M-3: a locked stack is skipped and does not use up a try', function()
	world({}, 1)
	W.bags[0].items[1].locked = true
	open_merchant()
	for _ = 1, 6 do step() end
	eq(#used, 0, 'not sold while locked')
	W.bags[0].items[1].locked = false
	step()
	eq(#used, 1, 'sold once unlocked: it kept all its tries')
end)

test('M-4: a stack given up on is named in the summary, after exactly 3 tries, and the summary is one line', function()
	world({ { 601, 10 }, { 602, 10 } }, 0)
	W.refused[601] = true
	open_merchant()
	local passes = 0
	while step() and passes < 10 do passes = passes + 1 end
	eq(#used, 4, 'the other once and the refused three times')
	eq(count_prints('Sold'), 1, 'one summary')
	local line = prints[#prints]
	check(line:find('Sold 1 stack ', 1, true), 'what sold: ' .. line)
	check(line:find('Gray 601', 1, true), 'the stack left is named: ' .. line)
end)

test('M-4: a merchant that closes right after a pass still gets every sale counted', function()
	world({}, 3)
	W.slow = true
	open_merchant()
	step()
	MerchantFrame:Hide()
	stub.fire_script(INV.vendorFrame, 'OnEvent', 'MERCHANT_CLOSED')
	W.flush() -- the server answers after the window closed
	stub.time = stub.time + 1
	stub.run_timers()
	eq(count_prints('Sold 3 stacks'), 1, 'counted once, all three: ' .. tostring(prints[#prints]))
end)

test('M-5: turning Auto Vendor off stops a visit already running', function()
	world({ { 601, 10 } }, 0)
	W.refused[601] = true
	open_merchant()
	step()
	INV.config.autovendor = false
	step()
	eq(#used, 1, 'no more tries')
	eq(step(), false, 'the loop is gone')
end)

test('M-6: the question names the most valuable by link, so its quality color shows', function()
	world({}, 13)
	open_merchant()
	step()
	check(prompt.text:find('|Hitem:711|h[Thing 711]|h', 1, true), 'a link: ' .. prompt.text)
end)

test('the once-only summary: a visit of many passes prints one line', function()
	world({ { 601, 10 } }, 13)
	open_merchant()
	for _ = 1, 3 do step() end
	answer(true)
	for _ = 1, 6 do step() end
	eq(count_prints('Sold'), 1, 'one line')
end)

------------------------------------------------------------------ fix round 2

test('N-1: a sale still in flight counts, so a stack that appears meanwhile cannot sell unasked past 12', function()
	world({}, 12)
	W.slow = true
	open_merchant()
	step() -- twelve asked of the game, each locked in its slot
	W.flush(11) -- the server has answered eleven; one is still in flight
	add_pinned(799, 999)
	W.slow = false
	step()
	eq(#used, 12, 'the 13th is not sold')
	check(prompt ~= nil, 'it asks')
	check(prompt.text:find('1 stack sold earlier this visit will leave the buyback', 1, true),
		'a sale in flight counts in what leaves: ' .. prompt.text)
	W.flush()
	step()
	eq(#used, 12, 'and still not, once the last one lands')
end)

test('N-1: a gray still in flight keeps the non-grays waiting', function()
	world({ { 601, 10 } }, 3)
	W.slow = true
	open_merchant()
	step() -- the gray is in flight, locked
	W.slow = false
	step()
	eq(#used, 1, 'no non-gray sold while a gray is on its way')
	W.flush()
	step()
	eq(#used, 4, 'sold once it landed')
end)

test('N-2: a second question says how many stacks sold earlier this visit it would push out', function()
	world({}, 5)
	open_merchant()
	step()
	for i = 1, 10 do add_pinned(800 + i, 5, 1, i) end
	step()
	check(prompt ~= nil, 'asked')
	check(prompt.text:find('3 stacks sold earlier this visit will leave the buyback', 1, true), prompt.text)
end)

test('N-2: with nothing to push out the question does not say so', function()
	world({}, 13)
	open_merchant()
	step()
	check(not prompt.text:find('earlier', 1, true), prompt.text)
end)

test("m-1: a question that holds a late gray does not call its stacks 'not junk'", function()
	world({}, 12)
	open_merchant()
	step()
	W.put(1, 21, W.item(698, 'Late Gray', 'Miscellaneous', 1, { quality = 0, vendorPrice = 10 }))
	step()
	check(prompt ~= nil, 'asked')
	check(not prompt.text:find("aren't junk", 1, true), prompt.text)
	check(prompt.text:find('1 stack sold earlier this visit will leave', 1, true), prompt.text)
end)

test('m-2: a stack bought back into its own slot is a new stack: it needs a new question', function()
	world({}, 13)
	W.refused[713] = true -- keeps the visit going
	open_merchant()
	step()
	answer(true)
	step()
	step() -- the sales are counted, and leave the named list
	W.bags[0].items[1] = W.item(701, 'Thing 701', 'Miscellaneous', 1, { quality = 1, vendorPrice = 40 })
	local before = #used
	step()
	step() -- the refused stack is given up on: the bought-back one is all that is left
	for i = before + 1, #used do check(used[i].id ~= 701, 'not sold again under the old answer') end
	eq(asked, 2, 'it asks again')
end)

test('m-4: a named slot that now holds the same item in another count is not sold', function()
	world({}, 13)
	open_merchant()
	step()
	W.bags[0].items[3].count = 2
	answer(true)
	step()
	for _, id in ipairs(sold_ids()) do check(id ~= 703, 'the changed stack is not sold under the answer') end
	eq(#used, 12, 'the other twelve are')
end)

test('m-4: Sell them while a gray is still being retried waits for the gray', function()
	world({ { 601, 10 } }, 13)
	W.refused[601] = true
	open_merchant()
	step()
	answer(true)
	step()
	for _, id in ipairs(sold_ids()) do check(id < 700, 'no named stack sold while the gray is retried') end
	W.refused[601] = nil
	step()
	step()
	local order = sold_ids()
	local last_gray, first_other
	for i, id in ipairs(order) do
		if id < 700 then last_gray = i elseif not first_other then first_other = i end
	end
	check(last_gray and first_other and last_gray < first_other, 'the gray sells before the named stacks: ' .. csv(order))
end)

------------------------------------------------------------------ fix round 3

test("n-3: the question says '1 stack' and 'N stacks'", function()
	world({}, 13)
	open_merchant()
	step()
	check(prompt.text:find('would sell 13 stacks', 1, true), prompt.text)
	check(not prompt.text:find('1 stacks', 1, true), 'no "1 stacks": ' .. prompt.text)
	-- One late gray over a visit of 12.
	world({}, 12)
	open_merchant()
	step()
	W.put(1, 21, W.item(698, 'Late Gray', 'Miscellaneous', 1, { quality = 0, vendorPrice = 10 }))
	step()
	check(prompt.text:find('would sell 1 stack,', 1, true), prompt.text)
	check(not prompt.text:find('1 stacks', 1, true), 'no "1 stacks": ' .. prompt.text)
end)

test("n-3: the summary says '1 stack' and 'N stacks'", function()
	world({ { 601, 10 } }, 0)
	open_merchant()
	step()
	step()
	check(prints[#prints]:find('Sold 1 stack for', 1, true), prints[#prints])
	check(not prints[#prints]:find('1 stacks', 1, true), prints[#prints])
end)

test("n-4: a question of non-grays says 'that aren't junk'", function()
	world({}, 13)
	open_merchant()
	step()
	check(prompt.text:find("stacks that aren't junk", 1, true), prompt.text)
end)

test('n-4: a refused stack is not a sale in flight: it is not counted twice', function()
	-- Twelve pinned; one is refused on the first pass. Eleven sold, so the retry
	-- of the twelfth still fits the buyback list: no question.
	world({}, 12)
	W.refused[701] = true
	open_merchant()
	step()
	eq(#used, 12, 'twelve asked')
	W.refused[701] = nil
	step()
	eq(prompt, nil, 'no question for the retry')
	eq(#used, 13, 'the refused one is sold on the next pass')
end)

test('a fresh purchase of the same item and count in a slot just sold is a sale landed, not a refused one', function()
	-- Twelve sold with no question; the first slot is refilled by a purchase
	-- before the next pass. It is a new stack (a new GUID): the twelfth sale is
	-- counted, so selling the purchase would be a 13th and asks.
	world({}, 12)
	open_merchant()
	step()
	eq(#used, 12, 'twelve sold unasked')
	W.put(0, 1, W.item(701, 'Thing 701', 'Miscellaneous', 1, { quality = 1, vendorPrice = 40 }))
	step()
	eq(#used, 12, 'the purchase is not sold under the old count')
	check(prompt ~= nil, 'it asks first')
end)

test('a stack that stays in its slot is the same stack: a refused one is not counted sold', function()
	world({}, 12)
	W.refused[701] = true
	open_merchant()
	step()
	step()
	eq(#used, 13, 'the refused one is tried again')
	eq(prompt, nil, 'and with eleven counted, it fits')
end)

test("N-2: past 12 the question says how many of the earlier stacks leave, not all of them", function()
	world({}, 13)
	open_merchant()
	step()
	answer(true)
	step()
	eq(#used, 13, 'thirteen sold')
	add_pinned(899, 5, 1, 1)
	step() -- the 13 sold are counted, and the new stack is a question of its own
	check(prompt ~= nil, 'asked')
	-- 13 sold, 12 still in the buyback: one more pushes out one of them.
	check(prompt.text:find('(and 1 stack sold earlier this visit will leave the buyback)', 1, true), prompt.text)
end)

test("a slot that answers no GUID where a GUID was recorded is a changed stack: the safe side, so it is counted and asks", function()
	world({}, 12)
	open_merchant()
	step()
	eq(#used, 12, 'twelve sold unasked')
	W.put(0, 1, W.item(701, 'Thing 701', 'Miscellaneous', 1, { quality = 1, vendorPrice = 40, noguid = true }))
	step()
	eq(#used, 12, 'the purchase, with no GUID to compare, counts the twelfth as sold: no 13th unasked')
	check(prompt ~= nil, 'it asks first')
end)
