-- SaftUI-Loot/Feed/feed.lua: the fade timer refresh when hovering a line
-- (UpdateAllFeedTimers) and the feed's cap (LootFeedPush), over the real
-- feed.lua, filter.lua and history.lua.
load_core_helpers()
load_saftui('SaftUI-Core/Utilities/utilities.lua') -- feed.lua takes the Utilities module at load
load_saftui('SaftUI-Loot/config.lua')
apply_defaults()
load_saftui('SaftUI-Loot/init.lua')
load_saftui('SaftUI-Loot/Feed/history.lua')
load_saftui('SaftUI-Loot/Feed/feed.lua')
load_saftui('SaftUI-Loot/Feed/filter.lua')

local st = SaftUI
local LT = st.Loot
st:BindModuleConfig(LT, 'loot')
st.config.char = {} -- AceDB's per-character table; the shell has none

-- The feed's lines are not built here (UpdateFeed draws them, and needs the
-- Blizzard-side item widgets). This stands in for UpdateFeed's one effect the
-- logic reads: refreshing the cached filtered list.
LT.feed = { offset = 0, items = {} }
function LT:UpdateFeed() self:GetFilteredItems() end

local MAX = LT.MAX_HISTORY

local function entry(name, kind)
	return { name = name, type = kind or 'Loot', icon = 1 }
end

local function reset_feed()
	wipe(LT:GetAllItems())
	wipe(LT:GetHistoryStore().feed)
	LT.feed.offset = 0
	LT.config.feed.filters.Self = false
	LT.config.feed.filters.Loot = true
	LT.config.feed.filters.Gold = true
	stub.time = 100
end

test('hover refreshes the lines it shows, by the filtered list', function()
	reset_feed()
	-- Newest first: loot A, gold (hidden), loot C, loot D.
	LT.config.feed.filters.Gold = false
	local stack = LT:GetAllItems()
	local A, G, C, D = entry('A'), entry('G', 'Gold'), entry('C'), entry('D')
	for _, e in ipairs({ A, G, C, D }) do e.time = 0; tinsert(stack, e) end
	LT:GetFilteredItems() -- A, C, D are on screen as lines 1-3

	stub.time = 500
	LT:UpdateAllFeedTimers(2) -- hovering line 2 (C) refreshes lines 1 and 2

	eq(A.time, 500, 'A (line 1) refreshed')
	eq(C.time, 500, 'C (line 2) refreshed')
	eq(G.time, 0, 'the hidden gold entry is not refreshed')
	eq(D.time, 0, 'D (line 3, below the hovered line) is not refreshed')
end)

test('hover honours the scroll offset in the filtered list', function()
	reset_feed()
	LT.config.feed.filters.Gold = false
	local stack = LT:GetAllItems()
	local list = {}
	for i = 1, 6 do
		local e = entry('E' .. i, i % 2 == 0 and 'Gold' or 'Loot')
		e.time = 0
		tinsert(stack, e)
		list[i] = e
	end
	LT:GetFilteredItems() -- E1, E3, E5 pass
	LT.feed.offset = 1 -- line 1 is E3

	stub.time = 700
	LT:UpdateAllFeedTimers(1)
	eq(list[3].time, 700, 'line 1 is the second filtered entry (E3)')
	eq(list[1].time, 0, 'E1 is scrolled off')
	eq(list[2].time, 0, 'hidden E2 untouched')
end)

local function fill_to_cap()
	local stack = LT:GetAllItems()
	for i = MAX, 1, -1 do -- pushed oldest first, so entry 1 ends on top
		LT:LootFeedPush(entry('Item' .. i))
	end
	return stack
end

test('a push that merges into the top entry does not drop one from a full feed', function()
	reset_feed()
	local stack = fill_to_cap()
	eq(#stack, MAX, 'feed is full')
	local oldest = stack[MAX]

	LT:LootFeedPush(entry('Item1')) -- same as the top entry: merges
	eq(#stack, MAX, 'still full')
	eq(stack[MAX], oldest, 'the oldest entry is still there')
	eq(stack[1].count, 2, 'and the top entry took the count')
end)

test('a push that inserts into a full feed drops the oldest', function()
	reset_feed()
	local stack = fill_to_cap()
	local oldest, second_oldest = stack[MAX], stack[MAX - 1]

	LT:LootFeedPush(entry('Brand new'))
	eq(#stack, MAX, 'the feed stays at its cap')
	eq(stack[1].name, 'Brand new', 'the new entry is on top')
	check(stack[MAX] ~= oldest and stack[MAX] == second_oldest, 'the oldest was dropped')
end)

test('a gold merge into a full feed drops nothing either', function()
	reset_feed()
	local stack = fill_to_cap()
	LT:LootFeedPush({ name = 'Gold', type = 'Gold', gold = 5 })
	local oldest = stack[MAX]
	LT:LootFeedPush({ name = 'Gold', type = 'Gold', gold = 7 })
	eq(#stack, MAX, 'full')
	eq(stack[MAX], oldest, 'oldest kept')
	eq(stack[1].gold, 12, 'gold summed')
end)
