
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

local MAX_HISTORY = 100
local feed_stack = {}

------------------------------------
-- Pattern matching
------------------------------------
local match_replacements = {
	link = "(\124c%x%x%x%x%x%x%x%x\124Hitem[%-?%d:]+)%D*",
	count =  '(%d+)',
	honor = '(%d+)'
}

local patterns = {}
local function generate_match(match, keys)
	replacements = {}
	match = match:gsub("%(", "")
	match = match:gsub("%)", "")
	match = match:gsub('%%d', '%%s')
	for _,key in pairs(keys) do
		tinsert(replacements, match_replacements[key] or '(.+)')
	end
	patterns[match:format(unpack(replacements))..'$'] = keys
end

-- self_loot
generate_match(LOOT_ITEM_SELF, {'link'})
generate_match(LOOT_ITEM_REFUND, {'link'})
generate_match(LOOT_ITEM_CREATED_SELF, {'link'})
generate_match(LOOT_MONEY_REFUND, {'link'})
generate_match(CURRENCY_GAINED, {'link'})
generate_match(LOOT_ITEM_PUSHED_SELF, {'link'})
generate_match(LOOT_ITEM_BONUS_ROLL_SELF, {'link'})
generate_match(LOOT_CURRENCY_REFUND, {'link', 'count'})
generate_match(LOOT_ITEM_SELF_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_CREATED_SELF_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_REFUND_MULTIPLE, {'link', 'count'})
generate_match(CURRENCY_GAINED_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_PUSHED_SELF_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE, {'link', 'count'})
generate_match(CURRENCY_GAINED_MULTIPLE_BONUS, {'link', 'count'})
-- self_gold
generate_match(YOU_LOOT_MONEY, {'gold'})
generate_match(YOU_LOOT_MONEY_GUILD, {'gold', 'bank_gold'})
generate_match(LOOT_MONEY_SPLIT, {'gold'})
generate_match(LOOT_MONEY_SPLIT_GUILD, {'gold', 'bank_gold'})
-- others_loot
generate_match(LOOT_ITEM, {'player', 'link'})
generate_match(LOOT_ITEM_BONUS_ROLL, {'player', 'link'})
generate_match(LOOT_ITEM_PUSHED, {'player', 'link'})
generate_match(LOOT_ITEM_WHILE_PLAYER_INELIGIBLE, {'player', 'link'})
generate_match(LOOT_ITEM_MULTIPLE, {'player','link', 'count'})
generate_match(LOOT_ITEM_PUSHED_MULTIPLE, {'player','link', 'count'})
generate_match(LOOT_ITEM_BONUS_ROLL_MULTIPLE, {'player','link', 'count'})

--honor
generate_match(COMBATLOG_HONORAWARD, {'honor'})
generate_match(COMBATLOG_HONORGAIN, {'player', 'rank', 'honor'})
generate_match(COMBATLOG_HONORGAIN_NO_RANK, {'player', 'honor'})


local function get_match(string)
	string = string:gsub("%(", "")
	string = string:gsub("%)", "")
	for pattern, keys in pairs(patterns) do
		-- print(string, pattern, string:match(pattern))
		local match = {string:match(pattern)}
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
local function generate_random_item()
	local link
	while not link do
		link = select(2, GetItemInfo(random(0, 10000)))
	end
	return link, random(1, 20)
end

local lastUpdate = 0
local lastPush = 0
function LT:UpdateHandler(elapsed)
	local time = GetTime()
	-- only check once a second
	if time - lastUpdate < 1 then return end
	lastUpdate = time

	-- if self.DEBUG then
	-- 	if time - lastPush >= 2 then
	-- 		lastPush = time
	-- 		if random() > 0.5 then
	-- 			self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(generate_random_item()))
	-- 		else
	-- 			self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	-- 		end
	-- 	end
	-- end

	self:UpdateFeed()
end

function LT:UpdateFeed()
	local now = GetTime()
	local item, info

	local recently_scrolled = self.feed.last_scroll_time and (now - self.feed.last_scroll_time < self.config.feed.fade_time)

	for i=1, self.config.feed.max_items do
		item = self.feed.items[i]
		info = feed_stack[i + self.feed.offset]

		if not info then break end

		-- fade out old items
		if (not recently_scrolled) and
			(self.feed.offset == 0) and
			(self.config.feed.fade_time > 0) and
			(now - info.time > self.config.feed.fade_time) then
			item:Hide()
		else
			if info.gold then
				item.text:SetText(st.StringFormat:GoldFormat(info.gold))
			else
				item.text:SetText(info.name)
			end
			item.count:SetText(info.count or '')
			item.icon:SetTexture(info.icon)
			item.link = info.link
			item.info = info

			item:Show()
		end
	end
end

function LT:LootFeedPush(info)
	if #feed_stack == MAX_HISTORY then
		tremove(feed_stack)
	end

	info.time = GetTime()

	if info.gold and feed_stack[1] and feed_stack[1].gold then
		feed_stack[1].gold = feed_stack[1].gold + info.gold
		feed_stack[1].time = info.time
	else
		tinsert(feed_stack, 1, info)
	end

	-- If scrolling through history, don't push the feed upwards
	if self.feed.offset > 0 then
		self.feed.offset = self.feed.offset + 1
	end

	self:UpdateFeed()
end

function LT:LootFeedAddItem(match)
	local filters = self.config.feed.filters

	if not match['link'] then return end

	local item_id = select(2, strsplit(":", string.match(match['link'], "item[%-?%d:]+")))
	local name, link, quality, ilvl, reqLevel, class, subclass, maxStack,
	equipSlot, texture, vendor_price, item_type_id, item_subtype_id, bind_type,
	expac_id, item_set_id, crafting_reagent = GetItemInfo(match['link']) 

	if not name then return end

	if quality < self.config.feed.min_quality then return end

	local item_color = st.config.profile.colors.item_quality[quality]
	if not item_color then return st:Debug('Loot', ('Invalid quality (%d) for item %s'):format(quality, name)) end
	
	name = st.StringFormat:ColorString(name, unpack(item_color))

	if filters.self_item and not match['player'] then
		self:LootFeedPush({
			name = name,
			icon = texture,
			link = match['link'],
			count = match['count']
		})
	elseif filters.other_item then
		self:LootFeedPush({
			name = match['player']..': '..name,
			icon = texture,
			link = match['link'],
			count = match['count']
		})
	end
end

local function extract_gold(gold_string)
	local c = gold_string:match(COPPER_AMOUNT:gsub('%%d', '%%s'):format('(%d+)')) or 0
	local s = gold_string:match(SILVER_AMOUNT:gsub('%%d', '%%s'):format('(%d+)')) or 0
	local g = gold_string:match(GOLD_AMOUNT:gsub('%%d', '%%s'):format('(%d+)')) or 0

	return c + s*1E2 + g*1E4
end

function LT:LootFeedAddGold(match)
	local filters = self.config.feed.filters

	if not filters.gold then return end

	local gold, icon = extract_gold(match['gold']), [[Interface\ICONS\INV_Misc_Coin_06]]

	if gold >= 1E4 then
		icon = [[Interface\ICONS\INV_Misc_Coin_02]]
	elseif gold >= 1E2 then
		icon = [[Interface\ICONS\INV_Misc_Coin_04]]
	end

	self:LootFeedPush({
		gold = gold,
		icon = icon
	})
end

local HONOR_RANKS = {}
for i=1, 18 do
	rank_name, rank_number = GetPVPRankInfo(i);
	HONOR_RANKS[rank_name] = rank_number
end

function LT:LootFeedAddHonor(match)
	if not match.honor then return end

	local player = match.player
	if match.rank then
		player = match.rank .. ' ' .. player
	end

	self:LootFeedPush({
		name = ('%s Honor (%s)'):format(match.honor, player),
		icon = ("Interface\\PvPRankBadges\\PvPRank%02d"):format(HONOR_RANKS[match.rank] or 1),
	})
end

------------------------------------
-- General
------------------------------------

function LT:LootFeedHandler(event, text)
	local match = get_match(text)
	if not match then return end

	if match['link'] then self:LootFeedAddItem(match) end
	if match['gold'] then self:LootFeedAddGold(match) end
	if match['honor'] then self:LootFeedAddHonor(match) end
end

local function ShowTooltip(self)
	if not self.link then return end

	self.info.time = GetTime()

	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', -10, 0)
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

		st:SetBackdrop(item.icon, config.template)

		item:SetScript("OnEnter", ShowTooltip)
		item:SetScript("OnLeave", HideTooltip)
		item:EnableMouse(true)

		self.feed.items[i] = item
	end

	local font_obj = st:GetFont(config.font)

	for i,item in pairs(self.feed.items) do
		item:SetSize(config.width, config.item_height)
		item.text:SetFontObject(font_obj)
		item.text:SetPoint('LEFT', item.icon, 'RIGHT', 10, 0)
		item.text:SetPoint('RIGHT', item, 'RIGHT', -10, 0)
		item.text:SetJustifyH('LEFT')
		item.text:SetWordWrap(false)
		item.text:SetText('Item '..i)
		
		item.count:SetFontObject(font_obj)
		item.count:SetPoint('BOTTOMRIGHT', item.icon, 0, 2)

		item.icon:SetSize(config.item_height, config.item_height)
		item.icon:SetPoint('LEFT', item)
		st:SkinIcon(item.icon)
		st:SetBackdrop(item, config.template)
	end

	self.feed.overlay:SetPoint('BOTTOMLEFT', self.feed)
	self.feed.overlay:SetPoint('TOPRIGHT', self.feed.items[config.max_items], 'TOPRIGHT')

	local x, y = self.feed:GetCenter()
	if x > GetScreenWidth()/2 then
		self.feed.reset_button:SetPoint('BOTTOMRIGHT', self.feed, 'BOTTOMLEFT', -config.spacing, 0)
	else
		self.feed.reset_button:SetPoint('BOTTOMLEFT', self.feed, 'BOTTOMRIGHT', config.spacing, 0)
	end
	self.feed.reset_button.text:SetFontObject(font_obj)
	st:SetBackdrop(self.feed.reset_button, config.template)
end

function LT:InitializeLootFeed()
	local feed = CreateFrame('frame', ADDON_NAME..'LootFeed', UIParent)
	feed:SetSize(200, 20)
	feed.items = {}
	feed.offset = 0
	feed.overlay = CreateFrame('frame', feed:GetName()..'ScrollOverlay', feed)
	feed.overlay:SetScript('OnMouseWheel', function(_, offset)
		feed.last_scroll_time = GetTime()
		
		if #feed_stack <= self.config.feed.max_items then return end

		if IsModifierKeyDown() then offset = offset * 3 end
		
		feed.offset = min(max(0, feed.offset + offset), #feed_stack - self.config.feed.max_items)
		

		if feed.offset == 0 then
			feed.reset_button:Hide()
		else
			feed.reset_button:Show()
		end
		
		self:UpdateFeed()
	end)

	self.feed = feed

	feed.reset_button = CreateFrame('Button', feed:GetName()..'ScrollReset', feed)
	feed.reset_button:SetSize(20, 20)
	feed.reset_button.text = feed.reset_button:CreateFontString(nil, 'OVERLAY')
	feed.reset_button.text:SetFontObject(GameFontNormal)
	feed.reset_button.text:SetText('V')
	feed.reset_button.text:SetPoint('CENTER')
	feed.reset_button:Hide()
	feed.reset_button:SetScript('OnClick', function()
		feed.offset = 0
		feed.reset_button:Hide()
		self:UpdateFeed()
	end)

	LT:UpdateLootFeedConfig()

	self:RegisterEvent('CHAT_MSG_LOOT', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_MONEY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_CURRENCY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_COMBAT_HONOR_GAIN', 'LootFeedHandler')

	-- if WoWUnit then self:Test() end
	
	self:HookScript(feed, 'OnUpdate', 'UpdateHandler')
end


if not WoWUnit then return end

local Tests = WoWUnit(ADDON_NAME..'LootFeed')
local AreEqual, Exists, Replace = WoWUnit.AreEqual, WoWUnit.Exists, WoWUnit.Replace

local test_item = "\124cff0070dd\124Hitem:16309::::::::60:::::\124h[Drakefire Amulet]\124h\124r"
local test_item2 = "\124cffffffff\124Hitem:2589::::::::60:::::\124h[Linen Cloth]\124h\124r"

function Tests:LootSelf()
	local self_item = LOOT_ITEM_SELF:format(test_item)
	Exists(get_match(self_item))
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
end

function Tests:LootSelfMultiple()
	local self_item_mult = LOOT_ITEM_SELF_MULTIPLE:format(test_item2, 5)
	local mult_test = get_match(self_item_mult)
	Exists(mult_test)
	AreEqual(mult_test.count, '5')
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item_mult)
end

function Tests:LootOther()
	local other_item = LOOT_ITEM:format("Sáfturento-Mal'Ganis", test_item)
	local other_test = get_match(other_item)
	Exists(other_test)
	AreEqual(other_test['player'], "Sáfturento-Mal'Ganis")
	LT:LootFeedHandler('CHAT_MSG_LOOT', other_item)
end

function Tests:LootGold()
	local gold = YOU_LOOT_MONEY:format('1 Gold, 23 Silver, 45 Copper')
	Exists(get_match(gold))
	LT:LootFeedHandler('CHAT_MSG_MONEY', gold)
end

function Tests:GainHonor()
	local honor = COMBATLOG_HONORGAIN:format('Safturento', 'High Warlord', 198)
	Exists(get_match(honor))
	LT:LootFeedHandler('CHAT_MSG_COMBAT_HONOR_GAIN', honor)
end