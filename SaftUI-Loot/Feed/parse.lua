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

-- COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = You gain %d experience.

local st = SaftUI
local LT = st.Loot

-- Reads the loot, money, experience, skill and reputation chat lines. feed.lua
-- takes `get_match` and `decreasePatterns` from `LT.parse`.

------------------------------------
---- Pattern matching --------------
------------------------------------

local match_replacements = {
	link = '(\124cnIQ%d:\124H[^:]*:[^\124]*\124h.*\124h)%D*',
	currency = '(\124cnIQ%d:\124Hcurrency[%-?%d:]+%D*)',
	count =  '(%d+)',
	honor = '(%d+)',
	experience = '(%d+)',
}


local patterns = {}

local function generate_match(match, keys, fuzzy)
	if not match then return end

	--[[
	We need to do some escaping to convert the global strings into regex.
	The result of this turns
		%s receives item: %sx%d.
	into
		(.+) receives item (\124c%x%x%x%x%x%x%x%x\124H[^:]*:[^\124]*\124h.*\124h)%D*x(%d+).$
						   |---------------this whole chunk is the item link-------|
	]]--
	local replacements = {}

	match = match:gsub("%(", "")
	match = match:gsub("%)", "")
	match = match:gsub('%%d', '%%s')

	for _,key in pairs(keys) do
		tinsert(replacements, match_replacements[key] or '(.+)')
	end

	local patternKey = match:format(unpack(replacements))
	if not fuzzy then
		patternKey = patternKey ..'$'
	end

	patterns[patternKey] = {
		keys = keys
	}

	return patternKey
end


local function get_match(string)
	if issecretvalue(string) then return end

	string = string:gsub("%(", ""):gsub("%)", "")
	for pattern, details in pairs(patterns) do
		local keys = details['keys']
		-- ex: { 1 = [Volatile Life], 2 = 3 }
        local match = {string:match(pattern)}
		--print('[', #match > 0, '] ', pattern, '|', string, '|', unpack(match))

        if #match > 0 and #match == #keys then
            local result = {}
            for i,item in ipairs(match) do
                result[keys[i]] = item
            end

			result.pattern = pattern

            return result
        end
	end
end

-- self loot
generate_match(LOOT_ITEM_BONUS_ROLL_SELF, {'link'})
generate_match(LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_CREATED_SELF, {'link'})
generate_match(LOOT_ITEM_CREATED_SELF_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_PUSHED_SELF, {'link'})
generate_match(LOOT_ITEM_PUSHED_SELF_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_REFUND, {'link'})
generate_match(LOOT_ITEM_REFUND_MULTIPLE, {'link', 'count'})
generate_match(LOOT_ITEM_SELF, {'link'})
generate_match(LOOT_ITEM_SELF_MULTIPLE, {'link', 'count'})

--self experience
generate_match("You gain %d experience", {'experience'}, true)
generate_match("you gain %d experience", {'experience'}, true)

-- self currency
generate_match(CURRENCY_GAINED, {'currency'})
generate_match(CURRENCY_GAINED_MULTIPLE, {'currency', 'count'})
generate_match(CURRENCY_GAINED_MULTIPLE_BONUS, {'currency', 'count'})
generate_match(LOOT_CURRENCY_REFUND, {'link', 'count'})

-- self gold
generate_match(YOU_LOOT_MONEY, {'gold'})
generate_match(YOU_LOOT_MONEY_GUILD, {'gold', 'bank_gold'})
generate_match(LOOT_MONEY_SPLIT, {'gold'})
generate_match(LOOT_MONEY_SPLIT_GUILD, {'gold', 'bank_gold'})
-- TODO: LOOT_MONEY_REFUND and LOOT_ITEM_REFUND are exactly the same, need to find
-- a different way to tell them apart than simple regex, maybe matching gold string vs item link?
generate_match(LOOT_MONEY_REFUND, {'link'})

--self skills
generate_match(SKILL_RANK_UP, {'skill', 'count'})

-- others loot
generate_match(LOOT_ITEM, {'player', 'link'})
generate_match(LOOT_ITEM_BONUS_ROLL, {'player', 'link'})
generate_match(LOOT_ITEM_PUSHED, {'player', 'link'})
generate_match(LOOT_ITEM_WHILE_PLAYER_INELIGIBLE, {'player', 'link'})
generate_match(LOOT_ITEM_MULTIPLE, {'player','link', 'count'})
generate_match(LOOT_ITEM_PUSHED_MULTIPLE, {'player','link', 'count'})
generate_match(LOOT_ITEM_BONUS_ROLL_MULTIPLE, {'player','link', 'count'})

--honor
--generate_match(COMBATLOG_HONORAWARD, {'honor'})
--generate_match(COMBATLOG_HONORGAIN, {'player', 'rank', 'honor'})
--generate_match(COMBATLOG_HONORGAIN_NO_RANK, {'player', 'honor'})

--reputation
local decreasePatterns = {}
for _, name in ipairs({
	'FACTION_STANDING_INCREASED',
	'FACTION_STANDING_INCREASED_ACCOUNT_WIDE',
	'FACTION_STANDING_DECREASED',
	'FACTION_STANDING_DECREASED_ACCOUNT_WIDE',
}) do
	local key = generate_match(_G[name], {'faction', 'count'})
	if key and name:find('DECREASED') then decreasePatterns[key] = true end
end

-- Gains with a bonus suffix, e.g. "... increased by 12. (+1.2 Bonus)", never match the
-- end-anchored patterns above. Strip the suffix from the global and match loosely.
for _, name in ipairs({
	'FACTION_STANDING_INCREASED_ACH_BONUS',
	'FACTION_STANDING_INCREASED_BONUS',
	'FACTION_STANDING_INCREASED_ACH_BONUS_ACCOUNT_WIDE',
	'FACTION_STANDING_INCREASED_BONUS_ACCOUNT_WIDE',
	'FACTION_STANDING_DECREASED_ACH_BONUS',
}) do
	local global = _G[name]
	if type(global) == 'string' then
		local stripped = global:gsub('%s*%(.-%%%.1f.-%)%s*$', '')
		local key = generate_match(stripped, {'faction', 'count'}, true)
		if key and name:find('DECREASED') then decreasePatterns[key] = true end
	end
end

LT.parse = {
	get_match = get_match,
	decreasePatterns = decreasePatterns,
}
