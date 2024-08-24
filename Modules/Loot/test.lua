local st = SaftUI
local LT = st:GetModule('Loot')

local test_item = "\124cff0070dd\124Hitem:16309::::::::60:::::\124h[Drakefire Amulet]\124h\124r"
local test_item2 = "\124cffffffff\124Hitem:2589::::::::60:::::\124h[Linen Cloth]\124h\124r"
local test_item_quality1 = "\124cffffffff\124Hitem:188658::::::::70:262::::1:38:1:::::\124h[Serevite Ore\124A:Professions-ChatIcon-Quality-Tier1:17:23::1\124a]\124h\124r"
local test_item_quality2 = "\124cffffffff\124Hitem:188658::::::::70:262::::1:38:2:::::\124h[Serevite Ore\124A:Professions-ChatIcon-Quality-Tier2:17:23::1\124a]\124h\124r"
local test_item_quality3 = "\124cffffffff\124Hitem:188658::::::::70:262::::1:38:3:::::\124h[Serevite Ore\124A:Professions-ChatIcon-Quality-Tier3:17:23::1\124a]\124h\124r"
local test_item_quality4 = "\124cffffffff\124Hitem:188658::::::::70:262::::1:38:4:::::\124h[Serevite Ore\124A:Professions-ChatIcon-Quality-Tier4:17:23::1\124a]\124h\124r"
local test_item_quality5 = "\124cffa335ee\124Hitem:190506:6652:::::::70:262::13:7:8836:8840:8902:8802:8790:8937:8960:7:28:2164:29:49:30:40:38:8:40:191:45:192552:46:193943::::Player-3676-0DDC1111:\124h[Primal Molten Spellblade \124A:Professions-ChatIcon-Quality-Tier5:17:17::1\124a]\124h\124r"
local test_currency = "|cffffffff|Hcurrency:1767:0|h[Stygia]|h|r"
local test_currency_weekly_max = "|cffff8000|Hcurrency:1828:0|h[Soul Ash]|h|r"
local thunderfury = "\124cffff8000\124Hitem:19019::::::::70:262:::::::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r"

local function generate_random_item()
	local link
	while not link do
		link = select(2, C_Item.GetItemInfo(random(0, 10000)))
	end
	return link, random(1, 20)
end


function LT:UpdateHandler(timer, elapsed)
	if st:barrier(timer, elapsed, 3) then return end

	local randomValue = random()

	if randomValue < 0.1 then
		self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(generate_random_item(), 12))
	elseif randomValue < .2 then
		self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	elseif randomValue < .3 then
		self:LootFeedHandler('CHAT_MSG_MONEY', YOU_LOOT_MONEY:format('1 Gold, 23 Silver, 45 Copper'))
	elseif randomValue < .4 then
		self:LootFeedHandler('CHAT_MSG_CURRENCY', CURRENCY_GAINED:format(test_currency))
	elseif randomValue < .5 then
		self:LootFeedHandler('CHAT_MSG_SKILL', 	SKILL_RANK_UP:format('Blacksmithing', 375))
	elseif randomValue < .6 then
		self:LootFeedHandler('CHAT_MSG_HONOR_GAIN', COMBATLOG_HONORGAIN:format(UnitName('player'), 'High Warlord', 198))
	else
		self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	end


	self:UpdateFeed()
end

function LT:InitializeTestMode()
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality1, 5))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality2, 4))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality3, 3))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(test_item_quality4, 2))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF:format(test_item_quality5))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_SELF_MULTIPLE:format(generate_random_item()))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_PUSHED:format("Party-Othr'relm", test_item_quality5))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item(), 5))
	self:LootFeedHandler('CHAT_MSG_MONEY', YOU_LOOT_MONEY:format('1 Gold, 23 Silver, 45 Copper'))
	self:LootFeedHandler('CHAT_MSG_CURRENCY', CURRENCY_GAINED:format(test_currency))
	self:LootFeedHandler('CHAT_MSG_SKILL', 	SKILL_RANK_UP:format('Blacksmithing', 375))
	self:LootFeedHandler('CHAT_MSG_HONOR_GAIN', COMBATLOG_HONORGAIN:format(UnitName('player'), 'High Warlord', 198))
	self:LootFeedHandler('CHAT_MSG_LOOT', LOOT_ITEM_MULTIPLE:format('Party'.."-Othr'relm", generate_random_item()))
	self:LootFeedHandler('CHAT_MSG_COMBAT_XP_GAIN', COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED:format("1234"))
	self:LootFeedHandler('CHAT_MSG_COMBAT_XP_GAIN', COMBATLOG_XPGAIN_EXHAUSTION2:format("The Boss", "1337", "+666", "Rested"))
	self:HookScript(CreateFrame('frame'), 'OnUpdate', 'UpdateHandler')
end