
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

local st = SaftUI
local LT = st.Loot

local MAX_HISTORY = 500
local feed_stack = {}

------------------------------------
---- Pattern matching --------------
------------------------------------
local match_replacements = {
	link = "(\124c%x%x%x%x%x%x%x%x\124H[^:]*:[^\124]*\124h.*\124h)%D*",
	currency = "(\124c%x%x%x%x%x%x%x%x\124Hcurrency[%-?%d:]+%D*)",
	count =  '(%d+)',
	honor = '(%d+)'
}


local patterns = {}

local function generate_match(match, keys, categories)
	--[[
	We need to do some escaping to convert the global strings into regex.
	The result of this turns
		%s receives item: %sx%d.
	into
		(.+) receives item (\124c%x%x%x%x%x%x%x%x\124H[^:]*:[^\124]*\124h.*\124h)%D*x(%d+).$
						   |---------------this whole chunk is the item link-------|
	]]--
	replacements = {}

	match = match:gsub("%(", "")
	match = match:gsub("%)", "")
	match = match:gsub('%%d', '%%s')

	for _,key in pairs(keys) do
		tinsert(replacements, match_replacements[key] or '(.+)')
	end


	patterns[match:format(unpack(replacements))..'$'] = {
		categories = categories,
		keys = keys
	}

	return match:format(unpack(replacements))..'$'
end


local function get_match(string)
	string = string:gsub("%(", ""):gsub("%)", "")
	for pattern, details in pairs(patterns) do
		local keys = details['keys']
        local match = {string:match(pattern)}

        if #match > 0 and #match == #keys then
            local result = {}
            for i,item in ipairs(match) do
                result[keys[i]] = item
            end

			result.categories = details.categories
			result.pattern = pattern

            return result
        end
	end
end

categories = {
	LOOT = "LOOT",
	OTHERS = "OTHERS",
	EXPERIENCE = "EXPERIENCE",
	REPUTATION = "REPUTATION",
	SKILL_UP = "SKILL_UP",
	HONOR = "HONOR",
	GOLD = "GOLD",
	CURRENCY = "CURRENCY",
}

SELF_LOOT = {categories.SELF, categories.LOOT}
SELF_CURRENCY = {categories.SELF, categories.CURRENCY}
SELF_GOLD = { categories.SELF, categories.GOLD }
SELF_SKILL_UP = { categories.SELF, categories.SKILL_UP }
SELF_HONOR = { categories.SELF, categories.HONOR }
SELF_REPUTATION = { categories.SELF, categories.REPUTATION }

OTHERS_LOOT = {categories.OTHERS, categories.LOOT}

-- self loot
generate_match(LOOT_ITEM_BONUS_ROLL_SELF, {'link'}, SELF_LOOT)
generate_match(LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE, {'link', 'count'}, SELF_LOOT)
generate_match(LOOT_ITEM_CREATED_SELF, {'link'}, SELF_LOOT)
generate_match(LOOT_ITEM_CREATED_SELF_MULTIPLE, {'link', 'count'}, SELF_LOOT)
generate_match(LOOT_ITEM_PUSHED_SELF, {'link'}, SELF_LOOT)
generate_match(LOOT_ITEM_PUSHED_SELF_MULTIPLE, {'link', 'count'}, SELF_LOOT)
generate_match(LOOT_ITEM_REFUND, {'link'}, SELF_LOOT)
generate_match(LOOT_ITEM_REFUND_MULTIPLE, {'link', 'count'}, SELF_LOOT)
generate_match(LOOT_ITEM_SELF, {'link'}, SELF_LOOT)
generate_match(LOOT_ITEM_SELF_MULTIPLE, {'link', 'count'}, SELF_LOOT)


-- self currency
generate_match(CURRENCY_GAINED, {'currency'}, SELF_CURRENCY)
generate_match(CURRENCY_GAINED_MULTIPLE, {'currency', 'count'}, SELF_CURRENCY)
generate_match(CURRENCY_GAINED_MULTIPLE_BONUS, {'currency', 'count'}, SELF_CURRENCY)
generate_match(LOOT_CURRENCY_REFUND, {'link', 'count'}, SELF_CURRENCY)

-- self gold
generate_match(YOU_LOOT_MONEY, {'gold'}, SELF_GOLD)
generate_match(YOU_LOOT_MONEY_GUILD, {'gold', 'bank_gold'}, SELF_GOLD)
generate_match(LOOT_MONEY_SPLIT, {'gold'}, SELF_GOLD)
generate_match(LOOT_MONEY_SPLIT_GUILD, {'gold', 'bank_gold'}, SELF_GOLD)
-- TODO: LOOT_MONEY_REFUND and LOOT_ITEM_REFUND are exactly the same, need to find
-- a different way to tell them apart than simple regex, maybe matching gold string vs item link?
generate_match(LOOT_MONEY_REFUND, {'link'}, SELF_GOLD)

--self skills
generate_match(SKILL_RANK_UP, {'skill', 'count'}, SELF_SKILL_UP)

-- others loot
generate_match(LOOT_ITEM, {'player', 'link'}, OTHERS_LOOT)
generate_match(LOOT_ITEM_BONUS_ROLL, {'player', 'link'}, OTHERS_LOOT)
generate_match(LOOT_ITEM_PUSHED, {'player', 'link'}, OTHERS_LOOT)
generate_match(LOOT_ITEM_WHILE_PLAYER_INELIGIBLE, {'player', 'link'}, OTHERS_LOOT)
generate_match(LOOT_ITEM_MULTIPLE, {'player','link', 'count'}, OTHERS_LOOT)
generate_match(LOOT_ITEM_PUSHED_MULTIPLE, {'player','link', 'count'}, OTHERS_LOOT)
generate_match(LOOT_ITEM_BONUS_ROLL_MULTIPLE, {'player','link', 'count'}, OTHERS_LOOT)

--honor
generate_match(COMBATLOG_HONORAWARD, {'honor'}, SELF_HONOR)
generate_match(COMBATLOG_HONORGAIN, {'player', 'rank', 'honor'}, SELF_HONOR)
generate_match(COMBATLOG_HONORGAIN_NO_RANK, {'player', 'honor'}, SELF_HONOR)

--reputation
generate_match(FACTION_STANDING_INCREASED, {'faction', 'count'}, SELF_REPUTATION)
generate_match(FACTION_STANDING_DECREASED, {'faction', 'count'}, SELF_REPUTATION)

------------------------------------
---- Dropdown ----------------------
------------------------------------

local filterMenuList = {
	{
		text="gold",
		checked=true,
	}
}

local function CreateSlotDropdown()
    INV.SlotDropDown = CreateFrame("Frame", "SaftUI_LootFeedFilterMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(INV.SlotDropDown, 200)
    UIDropDownMenu_SetText(INV.SlotDropDown, "Options")
    UIDropDownMenu_Initialize(INV.SlotDropDown, function(dropdown, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Auto Vendor"
        info.checked = function(self)
            return INV.config.autoVendorFilter and INV.config.autoVendorFilter[INV.SelectedSlot.info.itemID]
        end
        info.func = function(dropdown, arg1, arg2, checked)
            if not INV.SelectedSlot then return end

            if not INV.config.autoVendorFilter then INV.config.autoVendorFilter = {} end
            INV.config.autoVendorFilter[INV.SelectedSlot.info.itemID] = not checked
            INV:QueueUpdate()
        end
        UIDropDownMenu_AddButton(info)
    end)
end

------------------------------------
---- Feed updates ------------------
------------------------------------

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
				local quality = info.link and info.link:match(":(Professions%-ChatIcon%-Quality%-Tier%d+):")
				local text = info.name

				if quality then
					text = text .. CreateAtlasMarkup(quality, 16, 16, 0, -5)
				end

				item.text:SetText(text)
			end

			item.rightText:SetText(info.rightText or '')

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

	-- If you loot gold multiple times together, group it up into one item
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

local function colorItemName(name, quality)
	local item_color = st.config.profile.colors.item_quality[quality]
	if not item_color then return st:Debug('Loot', ('Invalid quality (%d) for item %s'):format(quality, name)) end

	return st.StringFormat:ColorString(name, unpack(item_color))
end

function LT:LootFeedAddCurrency(match)
	if not match['currency'] then return end

	local info = C_CurrencyInfo.GetCurrencyInfoFromLink(match['currency'])

	local name
	if info.maxQuantity > 0 then
		name = ("%s (%d/%d)"):format(colorItemName(info.name, info.quality), info.quantity, info.maxQuantity)
	else
		name = ("%s (%d)"):format(colorItemName(info.name, info.quality), info.quantity)
	end

	self:LootFeedPush({
		name = name,
		icon = info.iconFileID,
		link = match['link'],
		count = match['count']
	})
end

function LT:LootFeedAddItem(match)
	local filters = self.config.feed.filters

	if not match['link'] then return end

	local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(match['link'])

	if not name then
		st:Error("Item has weird link:", match['link'], match['link']:gsub("|", "||"))
	end

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
			name = name,
			rightText = match['player'],
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

function LT:LootFeedAddHonor(match)
	if not match.honor then return end

	local player = ''
	if match.player then
		player = match.player or ''
		if match.rank then
			player = match.rank .. ' ' .. player
		end
		player = format(' (%s)', player)
	end

	self:LootFeedPush({
		name = ('%s Honor%s'):format(match.honor, player),
		icon = "Interface\\PvPRankBadges\\PvPRank12"
	})
end

function LT:LootFeedAddReputation(match)
	if not match.faction then return end

	local iconId = match.count >= 0 and 5 or 3
	--TODO: Add font color based on current status with the faction? Add current faction rank?
	self:LootFeedPush({
		name = ('%d Reputation (%s)'):format(match.count, match.faction),
		icon = "Interface\\ICONS\\Achievement_Reputation_0" .. iconId
	})
end
------------------------------------
-- General
------------------------------------

function LT:LootFeedHandler(event, text)

	local match = get_match(text)
	if not match then return end

	if match['link'] then
		self:LootFeedAddItem(match)
	elseif match['currency'] then
		self:LootFeedAddCurrency(match)
	elseif match['gold'] then
		self:LootFeedAddGold(match)
	elseif match['honor'] then
		self:LootFeedAddHonor(match)
	elseif match['faction'] then
		match.count = tonumber(match.count)
		if strfind(match.pattern, "decreased") then
			match.count = -match.count
		end
		self:LootFeedAddReputation(match)
	end
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
		local item = CreateFrame('button', st.name ..'LootFeed'..i, self.feed)
		if i == 1 then
			item:SetPoint('BOTTOMRIGHT', self.feed , 'BOTTOMRIGHT', 0, 0)
		else
			item:SetPoint('BOTTOMRIGHT', self.feed.items[i-1], 'TOPRIGHT', 0, config.spacing)
		end

		item:Hide()

		item.text = item:CreateFontString(nil, 'OVERLAY')
		item.rightText = item:CreateFontString(nil, 'OVERLAY')
		item.icon = item:CreateTexture(nil, 'OVERLAY', nil, 1)
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
		item.text:SetPoint('RIGHT', item.rightText, 'LEFT', -10, 0)
		item.text:SetJustifyH('LEFT')
		item.text:SetWordWrap(false)
		item.text:SetText('Item '..i)


		item.rightText:SetFontObject(font_obj)
		item.rightText:SetPoint('RIGHT', item, 'RIGHT', -10, 0)
		item.rightText:SetJustifyH('RIGHT')
		item.rightText:SetText('Player '..i)

		item.count:SetFontObject(font_obj)
		item.count:SetPoint('BOTTOMRIGHT', item.icon, 0, 2)

		item.icon:SetSize(config.item_height, config.item_height)
		item.icon:SetPoint('LEFT', item)
		st:SkinIcon(item.icon)
		st:SetBackdrop(item, config.template)
	end

	self.feed.overlay:SetPoint('BOTTOMLEFT', self.feed)
	self.feed.overlay:SetPoint('TOPRIGHT', self.feed.items[config.max_items], 'TOPRIGHT')

	local x = self.feed:GetCenter()
	if x > GetScreenWidth()/2 then
		self.feed.filter_button:SetPoint('BOTTOMRIGHT', self.feed, 'BOTTOMLEFT', -config.spacing, 0)
	else
		self.feed.filter_button:SetPoint('BOTTOMLEFT', self.feed, 'BOTTOMRIGHT', config.spacing, 0)
	end

	self.feed.filter_button.text:SetFontObject(font_obj)
	st:SetBackdrop(self.feed.filter_button, config.template)

	self.feed.reset_button.text:SetFontObject(font_obj)
	st:SetBackdrop(self.feed.reset_button, config.template)
end

function LT:InitializeLootFeed()
	local feed = CreateFrame('frame', st.name ..'LootFeed', UIParent)
	feed:SetSize(200, 20)
	feed.items = {}
	feed.offset = 0
	feed.overlay = CreateFrame('frame', feed:GetName()..'ScrollOverlay', feed)
	feed.overlay:SetScript('OnMouseWheel', function(_, offset)
		feed.last_scroll_time = GetTime()

		if #feed_stack <= self.config.feed.max_items then

			for _,item in pairs(feed.items) do
				item:SetShown(item.info)
			end

			return
		end

		if IsControlKeyDown() then -- Scroll to top/bottom
			offset = offset * #feed_stack
		elseif IsShiftKeyDown() then -- Page scroll
			offset = offset * self.config.feed.max_items
		elseif not IsAltKeyDown() then
			offset = offset * 3
		end

		feed.offset = min(max(0, feed.offset + offset), #feed_stack - self.config.feed.max_items)

		if feed.offset == 0 then
			feed.reset_button:Hide()
		else
			feed.reset_button:Show()
		end

		self:UpdateFeed()
	end)

	self.feed = feed

	feed.filter_button = CreateFrame('Button', feed:GetName()..'FilterButton', feed)
	feed.filter_button:SetSize(20, 20)
	feed.filter_button.text = feed.filter_button:CreateFontString(nil, 'OVERLAY')
	feed.filter_button.text:SetFontObject(GameFontNormal)
	feed.filter_button.text:SetText('F')
	feed.filter_button.text:SetPoint('CENTER')

	feed.reset_button = CreateFrame('Button', feed:GetName()..'ScrollReset', feed)
	feed.reset_button:SetSize(20, 20)
	feed.reset_button.text = feed.reset_button:CreateFontString(nil, 'OVERLAY')
	feed.reset_button.text:SetFontObject(GameFontNormal)
	feed.reset_button.text:SetText('V')
	feed.reset_button.text:SetPoint('CENTER')
	feed.reset_button:Hide()
	feed.reset_button:SetPoint('BOTTOM', feed.filter_button, 'TOP', 0, self.config.feed.spacing)
	feed.reset_button:SetScript('OnClick', function()
		feed.offset = 0
		feed.reset_button:Hide()
		self:UpdateFeed()
	end)

	LT:UpdateLootFeedConfig()

	self:RegisterEvent('CHAT_MSG_LOOT', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_MONEY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_CURRENCY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_SKILL', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_COMBAT_HONOR_GAIN', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', 'LootFeedHandler')
end