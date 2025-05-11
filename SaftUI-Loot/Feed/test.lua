local st = SaftUI
local LT = st:GetModule('Loot')

local test_item = "\124cff0070dd\124Hitem:16309::::::::60:::::\124h[Drakefire Amulet]\124h\124r"
local test_item2 = "\124cffffffff\124Hitem:2589::::::::60:::::\124h[Linen Cloth]\124h\124r"
local test_item_quality1 = "\124cnIQ3:\124Hitem:222427::::::::80:262:::::::::\124h[Ironclaw Alloy \124A:Professions-ChatIcon-Quality-Tier2:17:23::1\124a]\124h\124r"
local test_item_quality2 = "\124cff1eff00\124Hitem:210937::::::::75:102::::1:38:2:::::\124h[Ironclaw Ore \124A:Professions-ChatIcon-Quality-Tier2:17:23::1\124a]\124h\124r"
local test_item_quality3 = "\124cff1eff00\124Hitem:210938::::::::75:102::::1:38:3:::::\124h[Ironclaw Ore \124A:Professions-ChatIcon-Quality-Tier3:17:18::1\124a]\124h\124r"
local test_item_quality5 = "\124cffa335ee\124Hitem:222568:7460:::::::80:262::13:9:10421:9633:8902:9627:12040:11300:8960:8793:12043:9:28:2734:29:49:30:40:38:8:40:2251:45:230906:46:226024:47:222584:48:230935::::Player-3676-0A85482B:\124h[Vagabond's Bounding Baton \124A:Professions-ChatIcon-Quality-Tier5:17:17::1\124a]\124h\124r"
local test_armor_track = "\124cnIQ4:\124Hitem:228866::::::::80:262::5:6:6652:11967:10355:11988:1507:10255:1:28:2462:::::\124h[Deep-Pocketed Pantaloons]\124h\124r"
local test_armor_track_max = "\124cnIQ4:\124Hitem:234502::::::::80:262::35:7:10390:6652:11964:10383:11996:1527:10255:1:28:2462:::::\124h[Bront's Singed Blastcoat]\124h\124r"
local test_currency = "|cffffffff|Hcurrency:1767:0|h[Stygia]|h|r"
local test_currency_weekly_max = "|cffff8000|Hcurrency:1828:0|h[Soul Ash]|h|r"
local thunderfury = "\124cffff8000\124Hitem:19019::::::::70:262:::::::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r"
local test_mount = "\124cnIQ4:\124Hitem:45693::::::::80:262:::::::::\124h[Mimiron's Head]\124h\124r"

local function generate_random_item()
	local link
	while not link do
		link = select(2, C_Item.GetItemInfo(random(0, 10000)))
	end
	return link, random(1, 20)
end

local function AddRandomFeedItem()
	local randomValue = random()
	if randomValue < .5 then
		LT:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(generate_random_item(), 12))
	elseif randomValue < .2 then
		LT:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	elseif randomValue < .3 then
		LT:LootFeedHandler('CHAT_MSG_MONEY', YOU_LOOT_MONEY:format('1 Gold, 23 Silver, 45 Copper'))
	elseif randomValue < .4 then
		LT:LootFeedHandler('CHAT_MSG_CURRENCY', CURRENCY_GAINED:format(test_currency))
	elseif randomValue < .5 then
		LT:LootFeedHandler('CHAT_MSG_SKILL', 	SKILL_RANK_UP:format('Blacksmithing', 375))
	elseif randomValue < .6 then
		LT:LootFeedHandler('CHAT_MSG_HONOR_GAIN', COMBATLOG_HONORGAIN:format(UnitName('player'), 'High Warlord', 198))
	else
		LT:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	end
end

function LT:UpdateHandler(timer, elapsed)
	if st:barrier(timer, elapsed, 1) then return end

	AddRandomFeedItem()

	self:UpdateFeed()
end

function LT:InitializeTestMode()
	self.debugText:Show()
	C_Item.GetItemInfo(test_armor_track)
	C_Item.GetItemInfo(test_armor_track_max)
	C_Item.GetItemInfo(test_item_quality1)
	C_Item.GetItemInfo(test_mount)
	C_Item.GetItemInfo(test_item_quality1)

	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(test_armor_track_max))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(test_armor_track))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(test_mount))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality1, 5))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality1, 5))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality2, 4))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality3, 3))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(test_item_quality5))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(generate_random_item()))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_PUSHED:format("Party-Othr'relm", test_item_quality5))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item(), 5))
	self:LootFeedHandler('CHAT_MSG_MONEY', YOU_LOOT_MONEY:format('1 Gold, 23 Silver, 45 Copper'))
	self:LootFeedHandler('CHAT_MSG_CURRENCY', CURRENCY_GAINED:format(test_currency))
	--self:LootFeedHandler('CHAT_MSG_SKILL', 	SKILL_RANK_UP:format('Blacksmithing', 375))
	--self:LootFeedHandler('CHAT_MSG_HONOR_GAIN', COMBATLOG_HONORGAIN:format(UnitName('player'), 'High Warlord', 198))
	--self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	--self:LootFeedHandler('CHAT_MSG_COMBAT_XP_GAIN', COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED:format("1234"))
	--self:LootFeedHandler('CHAT_MSG_COMBAT_XP_GAIN', COMBATLOG_XPGAIN_EXHAUSTION2:format("The Boss", "1337", "+666", "Rested"))
	--for i=1,15 do
	--	AddRandomFeedItem()
	--end
	--self:HookScript(CreateFrame('frame'), 'OnUpdate', 'UpdateHandler')
end