-- The state colors in the bags' windows: the footer's reagent count (Success)
-- and warband count (Shared), a locked bank slot (Buttons > Danger), the bank's
-- combat line (Danger) and the price of a tab you can or can't afford (Strong,
-- Danger). The item levels and "Caught by:" are in views_data_test.lua and
-- category_tooltip_menu_test.lua, the Categories list's and the rule editor's in
-- categories_*_test.lua and rule_editor_test.lua.
--
-- Every case runs with Success, Shared, Strong, Danger and Buttons > Danger set
-- to values that are not their defaults, so a reader that drew a color of its
-- own fails.
--
-- Real: container_helpers.lua's world, containers/bag.lua, combinedbank.lua and
-- bank.lua. The file-local functions the footers and the bank use are taken
-- from their module's methods' upvalues.
local H = load_test_file('bags/container_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local INV = H.views_world('forever')
local st = SaftUI
load_string_format()
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
for _, file in ipairs({ 'containers/bag.lua', 'containers/combinedbank.lua', 'containers/bank.lua' }) do
	load_saftui('SaftUI-Bags/' .. file)
end

local colors = st.config.profile.colors
local SUCCESS, SHARED, STRONG, DANGER, BUTTON = { 0.1, 0.8, 0.3 }, { 0.4, 0.2, 0.9 }, { 0.2, 0.7, 0.6 }, { 0.9, 0.3, 0.1 }, { 0.1, 0.2, 0.9 }
colors.text.success:SetRGB(unpack(SUCCESS)); colors.text.shared:SetRGB(unpack(SHARED))
colors.text.strong:SetRGB(unpack(STRONG)); colors.text.danger:SetRGB(unpack(DANGER))
colors.button.danger:SetRGB(unpack(BUTTON))

-- The library's own hex (it truncates a channel), so the case reads what the footer wrote.
local function hex(c) return st.StringFormat:ToHex(c[1], c[2], c[3]) end
-- The game's string.trim, which the money format calls and the stubs lack.
string.trim = string.trim or function(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end
local function rgb(r, g, b) return T.rgb(r, g, b) end
local function up(fn, name)
	for i = 1, 40 do
		local n, v = debug.getupvalue(fn, i)
		if not n then return nil end
		if n == name then return v end
	end
end

test("the bag window's reagent count is Text > Success, at an odd value", function()
	local update = up(INV.InitializePlayerBags, 'UpdateContainerSlots')
	check(update, 'the footer function')
	local container = H.window('bag')
	local real = INV.GetNumContainerSlots
	INV.GetNumContainerSlots = function() return 2, 10 end
	update(container)
	INV.GetNumContainerSlots = real
	eq(container.footer.slots:GetText(), '8/10 |cff' .. hex(SUCCESS) .. '8/10 |r', 'the second count, in Success')
end)

test("the combined bank's warband count is Text > Shared, at an odd value", function()
	local update = up(INV.InitializeCombinedBank, 'UpdateContainerSlots')
	check(update, 'the footer function')
	local container = H.window('combinedbank')
	local real = INV.GetNumContainerSlots
	INV.GetNumContainerSlots = function() return 2, 10 end
	update(container)
	INV.GetNumContainerSlots = real
	eq(container.footer.slots:GetText(), '8/10 |cff' .. hex(SHARED) .. '8/10|r', 'the warband count, in Shared')
end)

-- The bank bag bar: one tab bought, two more for sale.
local function bank_bar(afford)
	_G.C_Bank = {
		FetchMaxNumBankTabs = function() return 4 end,
		FetchNumPurchasedBankTabs = function() return 2 end,
		FetchPurchasedBankTabData = function() return { [1] = {}, [2] = {} } end,
		FetchNextPurchasableBankTabData = function() return { tabCost = 1000, canAfford = afford } end,
	}
	Enum.BankType = { Character = 0, Account = 2 }
	_G.ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end }
	_G.C_Item = { DoesItemExist = function() return false end }
	local bar = st:CreateFrame('Frame', 'SaftUIStateTestBankBar' .. tostring(afford), UIParent)
	bar.slots, bar.purchaseButton = {}, CreateFrame('Button', nil, bar)
	bar.purchaseButton.text = bar.purchaseButton:CreateFontString(nil, 'OVERLAY')
	INV:UpdateBankBagSlots(bar)
	return bar
end

test("a bank slot not bought yet is tinted Buttons > Danger, at an odd value", function()
	local bar = bank_bar(true)
	eq(rgb(bar.slots[3].locked:GetVertexColor()), rgb(unpack(BUTTON)), 'the locked tab')
	check(bar.slots[3].locked:IsShown(), 'shown on a tab not bought')
	eq(string.format('%.2f', bar.slots[3].locked:GetAlpha()), '0.30', 'at 30%, as before')
end)

test("the tab's price is Text > Strong when you can afford it and Text > Danger when you can't", function()
	eq(rgb(bank_bar(true).purchaseButton.text:GetTextColor()), rgb(unpack(STRONG)), 'affordable')
	eq(rgb(bank_bar(false).purchaseButton.text:GetTextColor()), rgb(unpack(DANGER)), "too expensive")
	eq(rgb(bank_bar(nil).purchaseButton.text:GetTextColor()), rgb(unpack(STRONG)), 'a price the game does not say: Strong')
end)

test("the bank's combat line in the purchase tooltip is Text > Danger", function()
	local show = up(up(INV.InitializeBankBagSlots, 'CreateBankBagPurchaseButton'), 'BankBagPurchase_OnEnter')
	check(show, 'the tooltip function')
	local lines = {}
	local real = GameTooltip.AddLine
	GameTooltip.AddLine = function(self, text, r, g, b, wrap)
		lines[#lines + 1] = { text = text, color = r and rgb(r, g, b) }
		return real(self, text, r, g, b, wrap)
	end
	_G.C_Bank = { FetchNextPurchasableBankTabData = function() return { tabCost = 1000 } end }
	Enum.BankType = { Character = 0, Account = 2 }
	stub.in_combat = true
	show(CreateFrame('Button', nil, UIParent))
	stub.in_combat = false
	GameTooltip.AddLine = real
	local last = lines[#lines]
	eq(last and last.text, "Can't buy bank slots in combat.")
	eq(last and last.color, rgb(unpack(DANGER)), 'in Danger')
end)

test("a currency's count is Text > Shared when it is account-wide or transferable, else Text > Strong", function()
	load_saftui('SaftUI-Bags/currencies.lua')
	-- What INV:InitializeCurrencyCategory needs of the game to make the category.
	_G.C_CurrencyInfo = _G.C_CurrencyInfo or {}
	C_CurrencyInfo.RequestCurrencyDataForAccountCharacters = C_CurrencyInfo.RequestCurrencyDataForAccountCharacters or function() end
	C_CurrencyInfo.GetBasicCurrencyInfo = C_CurrencyInfo.GetBasicCurrencyInfo or function() return { quality = 1 } end
	local container = H.window('bag')
	local category = container.categories.Currencies
	check(category, 'the bag window has its Currencies category')
	local items = {
		{ quantity = 7, iconFileID = 1, currencyIndex = 1, isAccountWide = true },
		{ quantity = 8, iconFileID = 2, currencyIndex = 2, isAccountTransferable = true },
		{ quantity = 9, iconFileID = 3, currencyIndex = 3 },
	}
	INV:UpdateCurrencyCategory(true, 4, items)
	local seen = {}
	for slot in category.slotPool:EnumerateActive() do seen[slot.Count:GetText()] = rgb(slot.Count:GetTextColor()) end
	eq(seen['7'], rgb(unpack(SHARED)), 'an account-wide currency')
	eq(seen['8'], rgb(unpack(SHARED)), 'a transferable one')
	eq(seen['9'], rgb(unpack(STRONG)), 'an ordinary one')
end)
