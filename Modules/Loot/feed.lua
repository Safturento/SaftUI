
-- LOOT_ROLL_YOU_WON = "You won: %s",
-- LOOT_ITEM_SELF = "You receive loot: %s.",
-- LOOT_ITEM_REFUND = "You are refunded: %s.",
-- LOOT_ITEM_CREATED_SELF = "You create: %s.",
-- LOOT_MONEY_REFUND = "You are refunded %s.",
-- CURRENCY_GAINED = "You receive currency: %s.",
-- LOOT_ITEM_PUSHED_SELF = "You receive item: %s.",
-- LOOT_ITEM_BONUS_ROLL_SELF = "You receive bonus loot: %s.",
-- LOOT_CURRENCY_REFUND = "You are refunded: %s x%d.",
-- LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d.",
-- LOOT_ITEM_CREATED_SELF_MULTIPLE = "You create: %sx%d.",
-- LOOT_ITEM_REFUND_MULTIPLE = "You are refunded: %sx%d.",
-- CURRENCY_GAINED_MULTIPLE = "You receive currency: %s x%d.",
-- LOOT_ITEM_PUSHED_SELF_MULTIPLE = "You receive item: %sx%d.",
-- LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE = "You receive bonus loot: %sx%d.",
-- CURRENCY_GAINED_MULTIPLE_BONUS = "You receive currency: %s x%d. (Bonus Objective)"

-- YOU_LOOT_MONEY = "You loot %s",
-- YOU_LOOT_MONEY_GUILD = "You loot %s (%s deposited to guild bank)",
-- LOOT_MONEY_SPLIT = "Your share of the loot is %s.",
-- LOOT_MONEY_SPLIT_GUILD = "Your share of the loot is %s. (%s deposited to guild bank)",

-- LOOT_ITEM = "%s receives loot: %s.",
-- LOOT_ITEM_BONUS_ROLL = "%s receives bonus loot: %s.",
-- LOOT_ITEM_BONUS_ROLL_MULTIPLE = "%s receives bonus loot: %sx%d.",
-- LOOT_ITEM_MULTIPLE = "%s receives loot: %sx%d.",
-- LOOT_ITEM_PUSHED = "%s receives item: %s.",
-- LOOT_ITEM_PUSHED_MULTIPLE = "%s receives item: %sx%d.",
-- LOOT_ITEM_WHILE_PLAYER_INELIGIBLE = "%s receives loot: |TInterface\\Common\\Icon-NoLoot:13:13:0:0|t%s",

local ADDON_NAME, st = ...
local LT = st:GetModule('Loot')

------------------------------------
-- Pattern matching
------------------------------------
local match_replacements = {
	item = "(\124c%x%x%x%x%x%x%x%x\124Hitem[%-?%d:]+).+",
	count =  '(%d+)'
}

local patterns = {}
local function generate_match(match, keys)
	replacements = {}

	match = match:gsub('%%d', '%%s')

	for _,key in pairs(keys) do
		tinsert(replacements, match_replacements[key] or '(%w+)')
	end
	patterns[match:format(unpack(replacements))..'$'] = keys
end

-- self_loot
generate_match(LOOT_ROLL_YOU_WON, {'item'})
generate_match(LOOT_ITEM_SELF, {'item'})
generate_match(LOOT_ITEM_REFUND, {'item'})
generate_match(LOOT_ITEM_CREATED_SELF, {'item'})
generate_match(LOOT_MONEY_REFUND, {'item'})
generate_match(CURRENCY_GAINED, {'item'})
generate_match(LOOT_ITEM_PUSHED_SELF, {'item'})
generate_match(LOOT_ITEM_BONUS_ROLL_SELF, {'item'})
generate_match(LOOT_CURRENCY_REFUND, {'item', 'count'})
generate_match(LOOT_ITEM_SELF_MULTIPLE, {'item', 'count'})
generate_match(LOOT_ITEM_CREATED_SELF_MULTIPLE, {'item', 'count'})
generate_match(LOOT_ITEM_REFUND_MULTIPLE, {'item', 'count'})
generate_match(CURRENCY_GAINED_MULTIPLE, {'item', 'count'})
generate_match(LOOT_ITEM_PUSHED_SELF_MULTIPLE, {'item', 'count'})
generate_match(LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE, {'item', 'count'})
generate_match(CURRENCY_GAINED_MULTIPLE_BONUS, {'item', 'count'})
-- self_gold
generate_match(YOU_LOOT_MONEY, {'item'})
generate_match(YOU_LOOT_MONEY_GUILD, {'item', 'bank'})
generate_match(LOOT_MONEY_SPLIT, {'item'})
generate_match(LOOT_MONEY_SPLIT_GUILD, {'item', 'bank'})
-- others_loot
generate_match(LOOT_ITEM, {'player', 'item'})
generate_match(LOOT_ITEM_BONUS_ROLL, {'player', 'item'})
generate_match(LOOT_ITEM_PUSHED, {'player', 'item'})
generate_match(LOOT_ITEM_WHILE_PLAYER_INELIGIBLE, {'player', 'item'})
generate_match(LOOT_ITEM_MULTIPLE, {'player','item', 'count'})
generate_match(LOOT_ITEM_PUSHED_MULTIPLE, {'player','item', 'count'})
generate_match(LOOT_ITEM_BONUS_ROLL_MULTIPLE, {'player','item', 'count'})

local function get_match(string)
	for pattern, keys in pairs(patterns) do
		-- print(string, pattern, string:match(pattern))
		match = {string:match(pattern)}
		if #match > 0 and #match == #keys then
			-- print(#match, #keys, string, pattern)
			local result = {}
			for i,item in ipairs(match) do
				-- print(keys[i], item)
				result[keys[i]] = item
			end
			return result
		end
	end
end

------------------------------------
-- Feed updates
------------------------------------
local feed_stack = {}

local lastUpdate = 0
function LT:UpdateHandler(elapsed)
	local time = GetTime()
	-- only check once a second
	if time - lastUpdate < 1 then return end
	lastUpdate = time

	-- Check all items and pop those who are over time
	local need_update = false
		
	local item
	for i=#feed_stack, 1, -1 do
		item = feed_stack[i]
		if item then
			if time - item.time > self.config.feed.fade_time then
				tremove(feed_stack, i)
				need_update = true
			else
				break
			end
		end
	end

	if need_update then
		self:UpdateFeed()
	end
end

function LT:UpdateFeed()
	for i,item in ipairs(feed_stack) do
		self.feed.items[i].text:SetText(item.text)
		self.feed.items[i].count:SetText(item.count)
		self.feed.items[i].icon:SetTexture(item.icon)
		self.feed.items[i].link = item.link
		self.feed.items[i]:Show()
	end

	for i=#feed_stack + 1, self.config.feed.max_items do
		if self.feed.items[i]:IsShown() then
			self.feed.items[i]:Hide()
		end
	end
end

function LT:LootFeedPush(link, name, texture, count)
	if #feed_stack == self.config.feed.max_items then
		tremove(feed_stack)
	end
	
	tinsert(feed_stack, 1, {
		icon = texture,
		text = name,
		count = count == 1 and '' or count,
		link = link,
		time = GetTime()
	})

	self:UpdateFeed()
end

function LT:LootFeedAddItem(match)
	local filters = self.config.feed.filters

	if not match['item'] then return end

	local item_id = select(2, strsplit(":", string.match(match['item'], "item[%-?%d:]+")))
	local name, link, quality, ilvl, reqLevel, class, subclass, maxStack,
	equipSlot, texture, vendor_price, item_type_id, item_subtype_id, bind_type,
	expac_id, item_set_id, crafting_reagent = GetItemInfo(item_id) 

	local item_color = st.config.profile.colors.item_quality[quality]
	name = st.StringFormat:ColorString(name, unpack(item_color))

	if filters.self_item and not match['player'] then
		return self:LootFeedPush(link, name, texture, match['count'])
	end

	if filters.other_item then
		return self:LootFeedPush(link, match['player']..': '..name, texture, match['count'])
	end
end

function LT:LootFeedAddCurrency(match)

end

------------------------------------
-- General
------------------------------------

function LT:LootFeedHandler(event, text)
	match = get_match(text)
	if not match then return end

	if match['item'] then
		self:LootFeedAddItem(match)
	end
end

function LT:Test()
	local test_item = "\124cff0070dd\124Hitem:49908::::::::120:::::\124h[Primordial Saronite]\124h\124r"
	local test_item2 = "\124cffffffff\124Hitem:2589::::::::60:::::\124h[Linen Cloth]\124h\124r"
	local test_money = {420, 69, 35}

	local other_item = LOOT_ITEM:format('Safturento', test_item)
	local self_item = LOOT_ITEM_SELF:format(test_item)
	local self_item_mult = LOOT_ITEM_SELF_MULTIPLE:format(test_item2, 5)

	assert(get_match(self_item), 'LOOT_ITEM_SELF failed')
	assert(get_match(self_item_mult), 'LOOT_ITEM_SELF_MULTIPLE failed')
	assert(get_match(other_item), 'LOOT_ITEM failed')

	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item_mult)
	LT:LootFeedHandler('CHAT_MSG_LOOT', other_item)
end

local function ShowTooltip(self)
	if not self.link then return end
	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', -7, 0)
	GameTooltip:SetHyperlink(self.link)
	GameTooltip:Show()
end

local function HideTooltip()
	GameTooltip:Hide()
end

function LT:UpdateLootFeedConfig()
	local config = self.config.feed

	self.feed:SetWidth(config.width)
	-- st:SetBackdrop(self.feed, config.template)
	self.feed:SetPoint(st:UnpackPoint(config.position))

	for i=#self.feed.items+1, config.max_items do
		local item = CreateFrame('button', ADDON_NAME..'LootFeed'..i, self.feed)
		if i == 1 then
			item:SetPoint('BOTTOMRIGHT', self.feed , 'BOTTOMRIGHT', 0, 0)
		else
			item:SetPoint('BOTTOMRIGHT', self.feed.items[i-1], 'TOPRIGHT', 0, config.spacing)
		end
		
		item:Hide()
		
		item.text = item:CreateFontString(nil, 'OVERLAY')
		item.icon = item:CreateTexture(nil, 'OVERLAY')
		item.count = item:CreateFontString(nil, 'OVERLAY')
		item:SetScript("OnEnter", ShowTooltip)
		item:SetScript("OnLeave", HideTooltip)
		item:EnableMouse(true)

		self.feed.items[i] = item
	end

	local font_obj = st:GetFont(config.font)

	for i,item in pairs(self.feed.items) do
		item:SetSize(config.width, config.item_height)
		item.text:SetFontObject(font_obj)
		item.text:SetPoint('LEFT', item.icon, 'RIGHT', 5, 0)
		item.text:SetText('Item '..i)
		
		item.count:SetFontObject(font_obj)
		item.count:SetPoint('BOTTOMRIGHT', item.icon, -2, 2)

		item.icon:SetSize(config.item_height, config.item_height)
		item.icon:SetPoint('LEFT', item)
		st:SkinIcon(item.icon)
		st:SetBackdrop(item, config.template)
	end
end

function LT:InitializeLootFeed()
	local feed = CreateFrame('frame', ADDON_NAME..'LootFeed', UIParent)
	feed:SetSize(20, 200)
	feed.items = {}
	self.feed = feed

	LT:UpdateLootFeedConfig()

	self:RegisterEvent('CHAT_MSG_LOOT', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_MONEY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_CURRENCY', 'LootFeedHandler')

	self:Test()
	
	self:HookScript(feed, 'OnUpdate', 'UpdateHandler')
end

