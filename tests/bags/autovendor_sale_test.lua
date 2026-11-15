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
local used, prints, prompt

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

	used, prints, prompt = {}, {}, nil
	_G.MerchantFrame = CreateFrame('Frame', 'MerchantFrame', UIParent)
	MerchantFrame:Hide()
	-- Selling a stack takes it out of its slot, as the game does, unless the
	-- slot is one the merchant refuses.
	W.refused = {}
	C_Container.UseContainerItem = function(bagID, slotID)
		local item = W.bags[bagID].items[slotID]
		used[#used + 1] = { bag = bagID, slot = slotID, id = item and item.itemID }
		if item and MerchantFrame:IsShown() and not W.refused[item.itemID] then
			W.bags[bagID].items[slotID] = nil
		end
	end
	SaftUI.Print = function(_, ...) prints[#prints + 1] = table.concat({ ... }, ' ') end
	SaftUI.StringFormat = { GoldFormat = function(_, money) return 'gold ' .. money end }
	SaftUI.OptionsWidgets = {
		Confirm = function(text, onYes, onNo, yesLabel, noLabel)
			prompt = { text = text, yes = onYes, no = onNo, yesLabel = yesLabel, noLabel = noLabel }
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
	eq(prompt, nil, 'no prompt at 12')
	eq(#used, 14, 'the grays and the twelve are sold')
	eq(csv(sold_ids()):sub(1, 7), '601,602', 'the grays first')
end)

test('13 non-gray items sell the grays and ask before the rest', function()
	world({ { 601, 10 }, { 602, 10 } }, 13)
	open_merchant()
	step()
	check(prompt ~= nil, 'a prompt')
	eq(csv(sold_ids()), '601,602', 'only the grays are sold, at once')
	eq(prompt.yesLabel, 'Sell them', 'the first answer sells')
	eq(prompt.noLabel, 'Keep them', 'the second keeps')
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
	check(prompt.text:find('13 items', 1, true), 'how many: ' .. prompt.text)
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
	check(summary and summary:find('1 item', 1, true), 'the summary counts the one: ' .. tostring(summary))
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
	close_merchant()
	eq(step(), false, 'the loop is gone')
	check(prints[#prints] and prints[#prints]:find('Sold 4 items', 1, true), 'summary: ' .. tostring(prints[#prints]))
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
	local summary = prints[#prints]
	check(summary and summary:find('Sold 1 item ', 1, true), 'one item: ' .. tostring(summary))
	check(summary:find('gold 20', 1, true), 'for what it fetched: ' .. summary)
end)

test('the summary has the count and the gold of what was sold, and none when nothing was', function()
	world({ { 601, 10, 2 }, { 602, 5 } }, 2)
	open_merchant()
	step()
	step()
	local summary = prints[#prints]
	check(summary:find('Sold 4 items', 1, true), summary)
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
