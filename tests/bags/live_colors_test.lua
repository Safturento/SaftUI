-- The bags' colors follow a pick at once (SaftUI-Bags' OnColorsChanged and its
-- followers): a changed color repaints only what it reaches and nothing else,
-- with nothing laid out, sorted, filed or made, in combat too.
--
-- (The world holds 1272 slots, 912 of them filled; the names say what each case measures.)
--
-- Real: bags/container_helpers.lua's views world (the module's real files, the
-- real slots, categories and windows) with containers/bag.lua, bank.lua and
-- combinedbank.lua; the bag window, the bank and the warband bank hold the
-- items the bags world gives them (every slot a real one), 40 of them epic, 100
-- armor or weapons (10 Warbound, 20 Bind on Equip), and the bag window has 20
-- currencies (3 epic). The bank's bag bar is made by hand as state_colors_test.lua
-- makes it. Each case runs on a fresh world.
local H = load_test_file('bags/container_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local st

local INV, W
local containers

local function rgb(r, g, b) return T.rgb(r, g, b) end
local function up(fn, name)
	for i = 1, 40 do
		local n, v = debug.getupvalue(fn, i)
		if not n then return nil end
		if n == name then return v end
	end
end

local EPIC = 4
local CURRENCY_QUALITY = {}

-- The window's slots in the order they were made: slots, in each category.
local function each_slot(fn)
	for _, container in pairs(INV.containers) do
		for _, category in pairs(container.categories or {}) do
			for _, slot in pairs(category.slots or {}) do fn(slot, container) end
		end
	end
end

-- Puts n items, g counting up over the three windows' slots, as the header says.
local function fill()
	local g = 0
	local function put(id, bagID, slots, firstG)
		for slot = 1, slots do
			g = g + 1
			local armor = g <= 100
			local extra = { quality = (g % 5 == 0 and g <= 100 or (g > 300 and g <= 310) or (g > 500 and g <= 510)) and EPIC or (g % 2 == 0 and 3 or 1) }
			if g <= 10 then extra.accountUntilEquip = true
			elseif g <= 30 then extra.bindType = Enum.ItemBind.OnEquip end
			W.put(bagID, slot, W.item(1000 + g, 'Thing ' .. g, armor and (g % 2 == 0 and 'Armor' or 'Weapon') or 'Miscellaneous', 10 + g, extra))
		end
	end
	for _, id in ipairs(INV.bagIds.bag) do put('bag', id, 50) end
	for _, id in ipairs(INV.bagIds.bank) do put('bank', id, 34) end
	for _, id in ipairs(INV.bagIds.warband) do put('warband', id, 34) end
	return g
end

local function world(client)
	INV, W = H.views_world(client or 'retail')
	st = SaftUI
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	load_string_format()
	_G.BankFrame = { BankPanel = { SetBankType = function() end } }
	Enum.BankType = { Character = 0, Account = 2 }
	string.trim = string.trim or function(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end
	for _, file in ipairs({ 'containers/bag.lua', 'containers/combinedbank.lua', 'containers/bank.lua' }) do
		load_saftui('SaftUI-Bags/' .. file)
	end
	local colors = st.config.profile.colors
	colors.text.strong:SetRGB(0.2, 0.7, 0.6); colors.text.success:SetRGB(0.1, 0.8, 0.3); colors.text.shared:SetRGB(0.4, 0.2, 0.9)
	colors.text.muted:SetRGB(0.5, 0.5, 0.4); colors.text.normal:SetRGB(0.6, 0.6, 0.9)
	colors.button.danger:SetRGB(0.1, 0.2, 0.9)
	for id, name in pairs({ bag = 'Bags', bank = 'Bank', warband = 'Warband' }) do
		for _, bagID in ipairs(INV.bagIds[id]) do W.bag(bagID, id == 'bag' and 50 or 34, name .. bagID) end
	end
	fill()
	INV.config.bag.view, INV.config.bank.view, INV.config.warband.view = 'compact', 'compact', 'compact'
	INV.config.stackItems = false
	INV.config.bag.emptySlots, INV.config.bank.emptySlots, INV.config.warband.emptySlots = 'off', 'off', 'off'
	-- Twenty currencies, three of them epic.
	local items = {}
	for i = 1, 20 do
		items[i] = { id = i, currencyIndex = i, quantity = i, iconFileID = i, isAccountWide = i % 5 == 0 }
		CURRENCY_QUALITY[i] = i <= 3 and EPIC or 1
	end
	_G.C_CurrencyInfo = {
		GetBasicCurrencyInfo = function(id) return { quality = CURRENCY_QUALITY[id] } end,
		RequestCurrencyDataForAccountCharacters = function() end,
	}
	INV.GetCurrencies = function() return items end
	local bag = H.window('bag')
	H.window('bank')
	H.window('warband')
	for _, id in ipairs({ 'bag', 'bank', 'warband' }) do
		INV.containers[id]:Show()
		INV:UpdateContainer(id, true, true)
	end
	INV:UpdateCurrencyCategory(true, 6, items)
	return bag
end

local function slots_where(pred)
	local n = 0
	each_slot(function(slot) if slot.info and not slot.info.empty and pred(slot) then n = n + 1 end end)
	return n
end

-- Counts the calls of the module functions a pass must never reach, and of
-- st:SetBorderColor and the reflow's friends.
local watched, restorers
local function spy()
	watched, restorers = {}, {}
	local function watch(owner, key, name)
		local real = owner[key]
		if not real then return end
		owner[key] = function(...) watched[name or key] = (watched[name or key] or 0) + 1; return real(...) end
		restorers[#restorers + 1] = function() owner[key] = real end
	end
	for _, key in ipairs({ 'UpdateConfig', 'QueueUpdate', 'CategoriesChanged', 'UpdateContainer', 'UpdateContainerLayout',
		'ApplyView', 'StyleSlot', 'SkinSlot', 'AssignSlot', 'SortByPriority', 'UpdateCategory', 'UpdateVisibleContainers',
		'ReleaseLayout', 'GetViewSections', 'ReadBags', 'GetBagInfo' }) do
		watch(INV, key)
	end
	watch(st, 'SetBorderColor')
end
local function unspy() for i = #restorers, 1, -1 do restorers[i]() end; restorers = {} end
local function count(name) return watched[name] or 0 end

local function quiet()
	for _, key in ipairs({ 'UpdateConfig', 'QueueUpdate', 'CategoriesChanged', 'UpdateContainer', 'UpdateContainerLayout',
		'ApplyView', 'StyleSlot', 'SkinSlot', 'AssignSlot', 'SortByPriority', 'UpdateCategory', 'UpdateVisibleContainers',
		'ReleaseLayout', 'GetViewSections', 'ReadBags', 'GetBagInfo' }) do
		eq(count(key), 0, key .. ' is not called')
	end
end

-- Bags' own handler alone, measured: what Bags itself repaints for a color.
-- (A whole pass also runs Core's widget followers: every button's, close
-- button's and scroll thumb's own colors, which "nothing of Bags'" must not count.)
local function bags_pass(group, key)
	spy()
	local ok, m = pcall(C.measure, function() INV:OnColorsChanged(group, key) end, 1)
	unspy()
	if not ok then error(m, 0) end
	return m
end

-- A pass of one color, measured: setters, forbidden calls and garbage.
local function pass(group, key, runs)
	spy()
	local ok, m = pcall(C.measure, function() st:ColorChanged(group, key) end, runs or 1)
	local result = watched
	unspy()
	if not ok then error(m, 0) end
	return m
end

local function setters(m, name) return m.calls.by[name] or 0 end

-- The bank window's bag bar, as state_colors_test.lua makes it, on the bank window.
local function bank_bar(id, afford)
	_G.C_Bank = {
		FetchMaxNumBankTabs = function() return 4 end,
		FetchNumPurchasedBankTabs = function() return 2 end,
		FetchPurchasedBankTabData = function() return { [1] = {}, [2] = {} } end,
		FetchNextPurchasableBankTabData = function() return { tabCost = 1000, canAfford = afford } end,
	}
	Enum.BankType = { Character = 0, Account = 2 }
	_G.ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end, }
	_G.C_Item = { DoesItemExist = function() return false end }
	local bar = st:CreateFrame('Frame', 'SaftUILiveBankBar', UIParent)
	bar.slots, bar.purchaseButton = {}, CreateFrame('Button', nil, bar)
	bar.purchaseButton.text = bar.purchaseButton:CreateFontString(nil, 'OVERLAY')
	INV:UpdateBankBagSlots(bar)
	INV.containers[id or 'bank'].bagSlotContainer = bar
	return bar
end

test('the world: 40 epic slots, 100 armor or weapons, 3 epic currencies', function()
	world()
	eq(slots_where(function(slot) return slot.info.quality == EPIC end), 40, 'epic slots')
	eq(slots_where(function(slot) return slot.info.class == 'Armor' or slot.info.class == 'Weapon' end), 100, 'gear')
	eq(slots_where(function(slot) return slot.info.isWarbound end), 10, 'Warbound')
	eq(slots_where(function(slot) return slot.info.isBoE and not slot.info.isWarbound end), 20, 'Bind on Equip')
	local epic, n = 0, 0
	for slot in INV.containers.bag.categories.Currencies.slotPool:EnumerateActive() do
		n = n + 1
		if CURRENCY_QUALITY[slot.elementData.id] == EPIC then epic = epic + 1 end
	end
	eq(n, 20, 'currencies shown')
	eq(epic, 3, 'epic currencies')
	eq(#take_errors(), 0, 'no errors')
end)

test('Item quality > Epic: only the 40 epic slots and 3 epic currencies, nothing laid out, sorted or made', function()
	world()
	local m = pass('item_quality', EPIC)
	eq(count('SetBorderColor'), 43, 'st:SetBorderColor: 40 slots and 3 currencies')
	quiet()
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	C.print('bags, epic', m)
	eq(#take_errors(), 0, 'no errors')
end)

test('Item quality, no key: every filled slot and every shown currency', function()
	world()
	pass('item_quality', nil)
	local filled = slots_where(function() return true end)
	eq(count('SetBorderColor'), filled + 20, 'every filled slot and every shown currency')
end)

test('Item quality: the borders take the new color', function()
	world()
	local color = st.config.profile.colors.item_quality[EPIC]
	color:SetRGB(0.9, 0.1, 0.8)
	st:ColorChanged('item_quality', EPIC)
	local checked = 0
	each_slot(function(slot)
		if slot.info and slot.info.quality == EPIC and slot.backdrop then
			checked = checked + 1
			eq(T.edge_rgb(slot.backdrop), T.text(0.9, 0.1, 0.8), 'an epic slot')
		end
	end)
	check(checked > 0, 'epic slots were checked')
end)

test("the Accent: the bag bar's slots, the loading bars, the selected bank window, the lit view buttons", function()
	local bag = world()
	local bank = INV.containers.bank
	INV:SelectBankCategory(bank.header)
	local bar = CreateFrame('Button', nil, UIParent)
	bar.icon = bar:CreateTexture(nil, 'BORDER')
	bar:SetNormalTexture(st.BLANK_TEX); bar:SetHighlightTexture(st.BLANK_TEX); bar:SetPushedTexture(st.BLANK_TEX)
	up(INV.InitializePlayerBagSlots, 'RestyleBagSlot')(bar)
	st:FollowColor(bar, 'accent', nil, up(INV.InitializePlayerBagSlots, 'PaintBagSlotHover'))
	local accent = st.config.profile.theme.accent
	accent:SetRGB(0.9, 0.2, 0.4)
	local m = pass('accent', nil)
	local want = T.text(0.9, 0.2, 0.4)
	eq(T.text(bar:GetHighlightTexture():GetVertexColor()), want .. ',1.00', "a bag bar slot's hover")
	eq(T.text(bag.loadingOverlay.loadingBar:GetStatusBarColor()), want .. ',1.00', "the bag window's loading bar")
	eq(T.text(bank.loadingOverlay.loadingBar:GetStatusBarColor()), want .. ',1.00', "the bank's loading bar")
	eq(T.edge_rgb(bank.backdrop), want, 'the selected bank window')
	quiet()
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	accent:SetRGB(0, 0.68, 0.94)
end)

test('100 Accent passes over every slot of the world allocate under 4 KB; in combat the same (Review Focus 4)', function()
	-- TODO after Task 2 (Core's widgets) merges: st:SkinActionButton then follows the Accent on every
	-- item, currency and bank bar slot's hover (about 1300 SetVertexColor calls in this world). Count
	-- them here (setters(m, 'SetVertexColor') >= the slots made), keep the 4 KB check, and add the
	-- brief's "every item slot's hover once" assertion.
	world()
	INV:SelectBankCategory(INV.containers.bank.header)
	local accent = st.config.profile.theme.accent
	for _, combat in ipairs({ false, true }) do
		stub.in_combat = combat
		-- Each border is given a color once first (a stub widget's first call makes its table).
		st:ColorChanged('accent')
		local m = pass('accent', nil, 100)
		C.print('bags, accent' .. (combat and ', in combat' or ''), m)
		check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB' .. (combat and ' in combat' or ''))
		eq(m.forbidden.total, 0, 'nothing forbidden' .. (combat and ' in combat' or ''))
		eq(m.made, 0, 'nothing made' .. (combat and ' in combat' or ''))
	end
	stub.in_combat = false
	eq(accent ~= nil, true)
end)

test('100 Epic passes over every slot of the world: nothing made or forbidden, under 4 KB', function()
	world()
	st:ColorChanged('item_quality', EPIC)
	local m = pass('item_quality', EPIC, 100)
	C.print('bags, epic x100', m)
	check(m.kb < 4, 'garbage: ' .. m.kb .. ' KB')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
end)

test('Text > Strong, Success, Shared: item levels by their key, reagent markers, currency counts, footers', function()
	world()
	local c = st.config.profile.colors.text
	local gear = function(key) return function(slot) return slot.info.isWarbound and key == 'shared' or (slot.info.isBoE and not slot.info.isWarbound and key == 'success') or (not slot.info.isBoE and not slot.info.isWarbound and key == 'strong') end end
	-- Strong: the 70 plain gear item levels and the plain currency counts.
	c.strong:SetRGB(0.9, 0.9, 0.1)
	local m = pass('text', 'strong')
	eq(setters(m, 'SetTextColor'), 70 + 16, 'Strong: 70 item levels and the 16 ordinary currency counts')
	each_slot(function(slot)
		if slot.info and gear('strong')(slot) and (slot.info.class == 'Armor' or slot.info.class == 'Weapon') then
			eq(rgb(slot.itemLevel:GetTextColor()), rgb(0.9, 0.9, 0.1), 'a plain item level')
		end
	end)
	quiet()
	-- Success: the 20 Bind on Equip item levels, every reagent marker, the bag footer.
	c.success:SetRGB(0.9, 0.5, 0.1)
	m = pass('text', 'success')
	eq(setters(m, 'SetTextColor'), 20, 'Success: 20 item levels')
	local markers, shown = 0, 0
	each_slot(function(slot)
		if slot.reagentMarker then
			markers = markers + 1
			eq(rgb(slot.reagentMarker:GetVertexColor()), rgb(0.9, 0.5, 0.1), 'a reagent marker')
		end
	end)
	check(markers > 0, 'markers were checked')
	quiet()
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	-- Shared: the 10 Warbound item levels and the account-wide currency counts.
	c.shared:SetRGB(0.2, 0.9, 0.9)
	m = pass('text', 'shared')
	eq(setters(m, 'SetTextColor'), 10 + 4, 'Shared: 10 item levels and the 4 account-wide currency counts')
	quiet()
	eq(#take_errors(), 0, 'no errors')
end)

test('100 passes of each Text color over every slot of the world: nothing made or forbidden, in combat too', function()
	world()
	for _, combat in ipairs({ false, true }) do
		stub.in_combat = combat
		for _, key in ipairs({ 'strong', 'success', 'shared', 'muted', 'normal', 'danger' }) do
			st:ColorChanged('text', key)
			local m = pass('text', key, 100)
			C.print('bags, text ' .. key .. (combat and ', in combat' or ''), m)
			eq(m.forbidden.total, 0, key .. ': nothing forbidden')
			eq(m.made, 0, key .. ': nothing made')
		end
	end
	stub.in_combat = false
end)

test('a currency count follows its own color only', function()
	world()
	local c = st.config.profile.colors.text
	c.shared:SetRGB(0.3, 0.9, 0.2)
	st:ColorChanged('text', 'shared')
	local seen = {}
	for slot in INV.containers.bag.categories.Currencies.slotPool:EnumerateActive() do
		seen[slot.elementData.id] = rgb(slot.Count:GetTextColor())
	end
	eq(seen[5], rgb(0.3, 0.9, 0.2), 'an account-wide currency')
	eq(seen[1], rgb(0.2, 0.7, 0.6), 'an ordinary one stays Strong')
end)

test("the bag window's reagent count and the combined bank's warband count follow Success and Shared", function()
	world()
	local bag = INV.containers.bag
	INV.GetNumContainerSlots = function() return 2, 10 end
	local update = up(INV.InitializePlayerBags, 'UpdateContainerSlots')
	update(bag)
	local c = st.config.profile.colors.text
	c.success:SetRGB(0.9, 0.5, 0.1)
	st:ColorChanged('text', 'success')
	eq(bag.footer.slots:GetText(), '8/10 |cff' .. st.StringFormat:ToHex(0.9, 0.5, 0.1) .. '8/10 |r', 'the bag footer, in the new Success')
	local combined = H.window('combinedbank')
	local cupdate = up(INV.InitializeCombinedBank, 'UpdateContainerSlots')
	cupdate(combined)
	c.shared:SetRGB(0.2, 0.9, 0.9)
	st:ColorChanged('text', 'shared')
	eq(combined.footer.slots:GetText(), '8/10 |cff' .. st.StringFormat:ToHex(0.2, 0.9, 0.9) .. '8/10|r', 'the combined footer, in the new Shared')
end)

test("Text > Muted: a special bag's title set again, nothing laid out", function()
	world()
	local bag = INV.containers.bag
	INV.config.bag.view = 'multibag'
	W.bag_item(5, 'Reagent Bag')
	INV:ApplyView('bag')
	local frame = bag.categories['view:bag5']
	check(frame and frame.titleText, 'the reagent bag has a title')
	if not frame then return end
	local before = frame.header.text:GetText()
	st.config.profile.colors.text.muted:SetRGB(0.9, 0.1, 0.2)
	local m = pass('text', 'muted')
	local hex = st.StringFormat and ('%02x%02x%02x'):format(230, 26, 51) or ''
	check(frame.titleText:find('|cff' .. hex, 1, true), 'the stored title has the new grey: ' .. tostring(frame.titleText))
	check(frame.header.text:GetText():find('|cff' .. hex, 1, true), 'and so does the shown one')
	check(before ~= frame.header.text:GetText(), 'the text changed')
	quiet()
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing forbidden')
end)

test("Text > Muted: the combined bank's eye follows it", function()
	world()
	local eye = CreateFrame('CheckButton', nil, UIParent)
	local checked = eye:CreateTexture(nil, 'ARTWORK')
	eye:SetCheckedTexture(checked)
	check(INV.PaintEye, 'INV.PaintEye is the eye paint')
	if not INV.PaintEye then return end
	eye.unchecked = eye:CreateTexture(nil, 'OVERLAY')
	st:FollowColor(eye, 'text', 'muted', INV.PaintEye)
	st.config.profile.colors.text.muted:SetRGB(0.7, 0.2, 0.3)
	st:ColorChanged('text', 'muted')
	eq(T.text(eye:GetCheckedTexture():GetVertexColor()), T.text(0.7, 0.2, 0.3) .. ',1.00', 'the open eye')
	eq(T.text(eye.unchecked:GetVertexColor()), T.text(0.7, 0.2, 0.3) .. ',0.30', 'the closed eye at 30%')
end)

test("Text > Normal: the view buttons' glyphs and the currencies' funnel", function()
	world()
	local bag = INV.containers.bag
	local funnel = bag.categories.Currencies.filterButton
	check(funnel and funnel.icon, 'the funnel')
	st.config.profile.colors.text.normal:SetRGB(0.2, 0.6, 0.4)
	local m = pass('text', 'normal')
	eq(T.text(funnel.icon:GetVertexColor()), T.text(0.2, 0.6, 0.4) .. ',1.00', 'the funnel')
	for _, piece in ipairs(bag.viewButtons.compact.glyph) do
		local rgba = stub.state(piece).color_texture
		eq(T.text(rgba[1], rgba[2], rgba[3]), T.text(0.2, 0.6, 0.4), 'a glyph')
	end
	quiet()
	eq(m.forbidden.total, 0, 'nothing forbidden')
end)

test('another text color does not recolor the glyphs or the funnel', function()
	world()
	local bag = INV.containers.bag
	local funnel = bag.categories.Currencies.filterButton
	st.config.profile.colors.text.normal:SetRGB(0.2, 0.6, 0.4)
	st:ColorChanged('text', 'normal')
	local m = bags_pass('text', 'danger')
	eq(setters(m, 'SetColorTexture'), 0, 'no glyph')
	eq(setters(m, 'SetVertexColor'), 0, 'no funnel, no marker')
end)

test("Buttons > Danger: the bank's unbought slots, at their region's 0.3", function()
	world()
	local bar = bank_bar('bank', false)
	local unbought = 0
	for _, slot in pairs(bar.slots) do if slot.locked:IsShown() then unbought = unbought + 1 end end
	check(unbought > 0, 'some slots are for sale')
	st.config.profile.colors.button.danger:SetRGB(0.9, 0.9, 0.1)
	local m = pass('button', 'danger')
	for _, slot in pairs(bar.slots) do
		eq(rgb(slot.locked:GetVertexColor()), rgb(0.9, 0.9, 0.1), 'the tint')
		eq(string.format('%.2f', slot.locked:GetAlpha()), '0.30', "the region's 0.3")
	end
	quiet()
	eq(m.forbidden.total, 0, 'nothing forbidden')
	m = bags_pass('button', 'hover')
	eq(setters(m, 'SetVertexColor'), 0, 'another Buttons color: nothing')
end)

test("Text > Danger and Strong: the bank's price of a tab follows the one it is drawn in", function()
	world()
	local bar = bank_bar('bank', false)
	local text = bar.purchaseButton.text
	eq(rgb(text:GetTextColor()), rgb(st.config.profile.colors.text.danger:GetRGB()), "too expensive: Danger")
	st.config.profile.colors.text.danger:SetRGB(0.9, 0.3, 0.1)
	st:ColorChanged('text', 'danger')
	eq(rgb(text:GetTextColor()), rgb(0.9, 0.3, 0.1), 'Danger changed')
	st.config.profile.colors.text.strong:SetRGB(0.1, 0.9, 0.1)
	local m = pass('text', 'strong')
	eq(rgb(text:GetTextColor()), rgb(0.9, 0.3, 0.1), 'Strong does not touch a price drawn in Danger')
end)

test('INV.ItemLevelKey: Warbound shared, Bind on Equip success, else strong', function()
	world()
	eq(INV.ItemLevelKey({ isWarbound = true, isBoE = true }), 'shared', 'Warbound first')
	eq(INV.ItemLevelKey({ isBoE = true }), 'success')
	eq(INV.ItemLevelKey({}), 'strong')
	eq(INV.ItemLevelKey({ isWarbound = false, isBoE = false }), 'strong')
end)

test('INV:ColorSlotTexts: the item level by its key, the marker for Success', function()
	world()
	local slot = {
		info = { class = 'Armor', isBoE = true },
		itemLevel = UIParent:CreateFontString(nil, 'OVERLAY'),
		reagentMarker = UIParent:CreateTexture(nil, 'OVERLAY'),
	}
	st.config.profile.colors.text.success:SetRGB(0.3, 0.8, 0.2)
	INV:ColorSlotTexts(slot, 'strong')
	check(rgb(slot.itemLevel:GetTextColor()) ~= rgb(0.3, 0.8, 0.2), 'Strong does not reach a Bind on Equip item level')
	INV:ColorSlotTexts(slot, 'success')
	eq(rgb(slot.itemLevel:GetTextColor()), rgb(0.3, 0.8, 0.2), 'Success does')
	eq(rgb(slot.reagentMarker:GetVertexColor()), rgb(0.3, 0.8, 0.2), 'and the marker')
	slot.info = { class = 'Miscellaneous' }
	INV:ColorSlotTexts(slot)
	eq(#take_errors(), 0, 'a slot with no gear is left alone')
end)

test('a profile switch (the whole pass) reaches the same readers with no error', function()
	world()
	INV:SelectBankCategory(INV.containers.bank.header)
	for _, group in ipairs({ 'item_quality', 'accent', 'text', 'button', 'theme' }) do
		st:ColorsChanged(group)
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ fix round 1

test("the combined bank's bag bar (the default layout): unbought tabs and the price follow a pick and the whole pass", function()
	world('forever')
	H.window('combinedbank')
	local bar = bank_bar('combinedbank', false)
	local colors = st.config.profile.colors
	check(bar.slots[3], 'a tab for sale')
	colors.button.danger:SetRGB(0.9, 0.9, 0.1)
	st:ColorChanged('button', 'danger')
	eq(rgb(bar.slots[3].locked:GetVertexColor()), rgb(0.9, 0.9, 0.1), 'the tint, after a pick')
	colors.button.danger:SetRGB(0.3, 0.9, 0.1)
	st:ColorsChanged('button')
	eq(rgb(bar.slots[3].locked:GetVertexColor()), rgb(0.3, 0.9, 0.1), 'the tint, after the whole pass')
	eq(string.format('%.2f', bar.slots[3].locked:GetAlpha()), '0.30', "the region's 0.3")
	colors.text.danger:SetRGB(0.8, 0.2, 0.2)
	st:ColorChanged('text', 'danger')
	eq(rgb(bar.purchaseButton.text:GetTextColor()), rgb(0.8, 0.2, 0.2), 'the price too dear, after a pick')
	bar = bank_bar('combinedbank', true)
	colors.text.strong:SetRGB(0.1, 0.9, 0.9)
	st:ColorsChanged('text')
	eq(rgb(bar.purchaseButton.text:GetTextColor()), rgb(0.1, 0.9, 0.9), 'the price you can pay, after the whole pass')
	eq(#take_errors(), 0, 'no errors')
end)

test("Muted: the retitle keeps the layout's parts: no GetBagInfo, nothing allocated, the count is the layout's", function()
	world()
	local bag = INV.containers.bag
	INV.config.bag.view = 'multibag'
	W.bag_item(5, 'Reagent Bag')
	INV:ApplyView('bag')
	local frame = bag.categories['view:bag5']
	check(frame and frame.titleText, 'the reagent bag has a title')
	if not frame then return end
	local count = frame.titleText:match('%\((.-)%\)$')
	-- A bag changes after the layout: its slots are laid out for the old count.
	W.put(5, 50, W.item(9999, 'Late', 'Miscellaneous', 1))
	st.config.profile.colors.text.muted:SetRGB(0.9, 0.1, 0.2)
	st:ColorChanged('text', 'muted')
	eq(frame.titleText:match('%\((.-)%\)$'), count, "the title's count is the layout's, whatever the bag holds now")
	check(frame.titleText:find('|cffe61a33', 1, true), 'in the new grey')
	local m = pass('text', 'muted', 100)
	check(m.kb < 4, 'garbage over 100 Muted passes: ' .. m.kb .. ' KB')
	eq(watched.GetBagInfo or 0, 0, 'no GetBagInfo')
	quiet()
end)

test('the footers: 100 Success and Shared passes under 4 KB with the counts set, the text what it was', function()
	world()
	local bag = INV.containers.bag
	INV.GetNumContainerSlots = function() return 2, 10 end
	up(INV.InitializePlayerBags, 'UpdateContainerSlots')(bag)
	local combined = H.window('combinedbank')
	up(INV.InitializeCombinedBank, 'UpdateContainerSlots')(combined)
	check(bag.slotCounts and combined.slotCounts, 'the counts are set, so the footer code runs')
	local c = st.config.profile.colors.text
	c.success:SetRGB(0.9, 0.5, 0.1); c.shared:SetRGB(0.2, 0.9, 0.9)
	st:ColorChanged('text', 'success'); st:ColorChanged('text', 'shared')
	local sx, sh = st.StringFormat:ToHex(0.9, 0.5, 0.1), st.StringFormat:ToHex(0.2, 0.9, 0.9)
	eq(bag.footer.slots:GetText(), '8/10 |cff' .. sx .. '8/10 |r', 'the bag footer, byte for byte')
	eq(combined.footer.slots:GetText(), '8/10 |cff' .. sh .. '8/10|r', 'the combined footer, byte for byte')
	for _, key in ipairs({ 'success', 'shared' }) do
		local m = pass('text', key, 100)
		check(m.kb < 4, key .. ': ' .. m.kb .. ' KB over 100 passes')
		eq(m.forbidden.total, 0, key .. ': nothing forbidden')
	end
end)

-- The markers' color on the slots, shown and not, of every window.
local function markers(fn)
	each_slot(function(slot) if slot.reagentMarker then fn(slot.reagentMarker) end end)
end

test('Success during an edit colors only the markers shown; the edit end colors the rest, and a marker shown later has it', function()
	world()
	local c = st.config.profile.colors.text
	c.success:SetRGB(0.9, 0.5, 0.1)
	local shown, all = 0, 0
	markers(function(marker) all = all + 1; if marker:IsShown() then shown = shown + 1 end end)
	check(shown > 0 and shown < all, 'some markers shown, most not: ' .. shown .. ' of ' .. all)
	st:BeginColorEdit()
	st:ColorChanged('text', 'success')
	local m = C.measure(function() C.step(st) end)
	eq(setters(m, 'SetVertexColor'), shown, 'only the shown markers were colored')
	markers(function(marker)
		if marker:IsShown() then eq(rgb(marker:GetVertexColor()), rgb(0.9, 0.5, 0.1), 'a shown marker') end
	end)
	st:EndColorEdit()
	markers(function(marker) eq(rgb(marker:GetVertexColor()), rgb(0.9, 0.5, 0.1), 'after the edit, every marker') end)
	-- Outside an edit a Success pass colors them all.
	c.success:SetRGB(0.3, 0.6, 0.2)
	m = pass('text', 'success')
	eq(setters(m, 'SetVertexColor'), all, 'outside an edit: every marker')
end)

test("a closed window's markers have the new Success when it opens, and its slots when they are assigned", function()
	world()
	local bank = INV.containers.bank
	bank:Hide()
	st.config.profile.colors.text.success:SetRGB(0.9, 0.5, 0.1)
	st:ColorChanged('text', 'success')
	bank:Show()
	local n = 0
	for _, category in pairs(bank.categories) do
		for _, slot in pairs(category.slots) do
			n = n + 1
			eq(rgb(slot.reagentMarker:GetVertexColor()), rgb(0.9, 0.5, 0.1), 'a marker of the closed window')
		end
	end
	check(n > 0, 'the window has slots')
	INV:UpdateContainer('bank', true, true)
	for _, category in pairs(bank.categories) do
		for _, slot in pairs(category.slots) do
			eq(rgb(slot.reagentMarker:GetVertexColor()), rgb(0.9, 0.5, 0.1), 'and after an update')
		end
	end
end)

test('a currency slot handed to a currency of another quality follows the new quality', function()
	world()
	CURRENCY_QUALITY[1] = 1
	INV:UpdateCurrencyCategory(true, 6, INV:GetCurrencies())
	spy()
	st:ColorChanged('item_quality', EPIC)
	local after = count('SetBorderColor')
	unspy()
	eq(after, 40 + 2, 'two epic currencies are left')
	spy()
	st:ColorChanged('item_quality', 1)
	local rest = count('SetBorderColor')
	unspy()
	check(rest >= 18, 'the slot reused for quality 1 follows quality 1: ' .. rest)
end)

test('every group: the whole pass and the price pass lay out, sort and file nothing', function()
	world()
	bank_bar('bank', false)
	for _, group in ipairs({ 'item_quality', 'accent', 'text', 'button', 'theme' }) do
		spy()
		st:ColorsChanged(group)
		quiet()
		unspy()
	end
	spy()
	st:ColorChanged('text', 'danger')
	quiet()
	unspy()
	eq(#take_errors(), 0, 'no errors')
end)

test("the selected bank window keeps its accent border through a Theme tab color change and a Bags option change", function()
	world()
	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()
	local accent = st.config.profile.theme.accent
	accent:SetRGB(0.9, 0.2, 0.4)
	local bank = INV.containers.bank
	INV:SelectBankCategory(bank.header)
	local want = T.text(0.9, 0.2, 0.4)
	eq(T.edge_rgb(bank.backdrop), want, 'picked')
	st.config.profile.templates.thin.bordercolor = { 0.1, 0.8, 0.8, 1 }
	st:RecolorThemed()
	eq(T.edge_rgb(bank.backdrop), want, 'after a Theme tab color change')
	INV:UpdateConfig('bank')
	eq(T.edge_rgb(bank.backdrop), want, 'after a Bags option change')
	INV:SelectBankCategory(INV.containers.warband.header)
	check(T.edge_rgb(bank.backdrop) ~= want, 'a window no longer selected goes back to the theme')
	accent:SetRGB(0, 0.68, 0.94)
end)
