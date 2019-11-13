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
	player = "(.+)[a-zA-Z-']*"
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
generate_match(YOU_LOOT_MONEY, {'link'})
generate_match(YOU_LOOT_MONEY_GUILD, {'link', 'bank'})
generate_match(LOOT_MONEY_SPLIT, {'link'})
generate_match(LOOT_MONEY_SPLIT_GUILD, {'link', 'bank'})
-- others_loot
generate_match(LOOT_ITEM, {'player', 'link'})
generate_match(LOOT_ITEM_BONUS_ROLL, {'player', 'link'})
generate_match(LOOT_ITEM_PUSHED, {'player', 'link'})
generate_match(LOOT_ITEM_WHILE_PLAYER_INELIGIBLE, {'player', 'link'})
generate_match(LOOT_ITEM_MULTIPLE, {'player','link', 'count'})
generate_match(LOOT_ITEM_PUSHED_MULTIPLE, {'player','link', 'count'})
generate_match(LOOT_ITEM_BONUS_ROLL_MULTIPLE, {'player','link', 'count'})

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

	if self.DEBUG then
		if time - lastPush >= 2 then
			lastPush = time
			if random() > 0.5 then
				self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(generate_random_item()))
			else
				self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
			end
		end
	end

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
			item.text:SetText(info.text)
			item.count:SetText(info.count)
			item.icon:SetTexture(info.icon)
			item.link = info.link
			item.info = info

			item:Show()
		end
	end
end

function LT:LootFeedPush(link, name, texture, count)
	if #feed_stack == MAX_HISTORY then
		tremove(feed_stack)
	end

	tinsert(feed_stack, 1, {
		icon = texture,
		text = name,
		count = count == 1 and '' or count,
		link = link,
		time = GetTime()
	})

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
		return self:LootFeedPush(match['link'], name, texture, match['count'])
	end

	if filters.other_item then
		return self:LootFeedPush(match['link'], match['player']..': '..name, texture, match['count'])
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
	if match['link'] then
		self:LootFeedAddItem(match)
	end
end

function LT:Test()
	local test_item = "\124cff0070dd\124Hitem:16309::::::::60:::::\124h[Drakefire Amulet]\124h\124r"
	local test_item2 = "\124cffffffff\124Hitem:2589::::::::60:::::\124h[Linen Cloth]\124h\124r"
	local test_money = {420, 69, 35}

	local other_item = LOOT_ITEM:format("Sáfturento-Mal'Ganis", test_item)
	local self_item = LOOT_ITEM_SELF:format(test_item)
	local self_item_mult = LOOT_ITEM_SELF_MULTIPLE:format(test_item2, 5)
	
	assert(get_match(self_item), 'LOOT_ITEM_SELF failed')

	local mult_test = get_match(self_item_mult)
	assert(mult_test and mult_test['count'] == '5', 'LOOT_ITEM_SELF_MULTIPLE failed')
	
	local other_test = get_match(other_item)
	
	assert(other_test and other_test['player']=="Sáfturento", 'LOOT_ITEM failed')

	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item)
	LT:LootFeedHandler('CHAT_MSG_LOOT', self_item_mult)
	LT:LootFeedHandler('CHAT_MSG_LOOT', other_item)
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
		item.count:SetPoint('BOTTOMRIGHT', item.icon, -2, 2)

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

	if self.DEBUG then self:Test() end
	
	self:HookScript(feed, 'OnUpdate', 'UpdateHandler')
end

