local st = SaftUI
local TR = st.Tracker

--[[
	The quests in zone groups: a group per quest log header, the current zone's
	first, then campaigns, then the rest in the log's own order, and the quests
	whose header the log doesn't give last, in Other. Pure over the model's
	quests (model.lua): no frame, no event, no API call.
]]

local Groups = {}
TR.Groups = Groups

-- The collapse key and title of the group of quests the log can't place, and
-- the key of the one list with Group by zone off. A real header titled "Other"
-- has the key "Other", so it stays apart.
TR.OTHER_KEY = '*other'
TR.OTHER_TITLE = 'Other'
TR.ALL_KEY = '*all'

-- Whether a header's title is the current zone: it equals one of the zone's
-- names (the model's zoneNames: the map's, GetRealZoneText's, GetZoneText's).
-- A title that isn't a plain string (a secret one) is not.
function Groups.IsCurrent(title, zoneNames)
	title = st.PlainString(title)
	if not title or type(zoneNames) ~= 'table' then return false end
	for _, name in ipairs(zoneNames) do
		if name == title then return true end
	end
	return false
end

-- Whether quest a goes before quest b in the game's order: the tracked ones by
-- Model.Compare, then the untracked in log order.
local function GameBefore(a, b)
	if a.tracked ~= b.tracked then return a.tracked and true or false end
	if a.tracked then return TR.Model.Compare(a, b) end
	return (a.logIndex or 0) < (b.logIndex or 0)
end

local function LogBefore(a, b)
	return (a.logIndex or 0) < (b.logIndex or 0)
end

-- Low level first, then the game's order; a quest with no level last.
local function LevelBefore(a, b)
	if a.level ~= b.level then
		if a.level == nil then return false end
		if b.level == nil then return true end
		return a.level < b.level
	end
	return GameBefore(a, b)
end

local COMPARATORS = { game = GameBefore, log = LogBefore, level = LevelBefore }

-- Sorts quests in place: order is 'game' (the watch list as the game sorts it,
-- the untracked after it in log order), 'log' (the quest log's order) or
-- 'level' (low first, then the game's). With finishedFirst the finished quests
-- (complete or ready to turn in) come first, each part in the same order.
function Groups.Sort(quests, order, finishedFirst)
	local before = COMPARATORS[order] or GameBefore
	table.sort(quests, before)
	if not finishedFirst then return end
	local finished, rest = {}, {}
	for _, quest in ipairs(quests) do
		if TR.Model.Finished(quest) then
			finished[#finished + 1] = quest
		else
			rest[#rest + 1] = quest
		end
	end
	for i, quest in ipairs(finished) do quests[i] = quest end
	for i, quest in ipairs(rest) do quests[#finished + i] = quest end
end

-- The groups of the model's quests: { key, title, current, campaign,
-- collapsed, count, quests } each. key is the header's title (what the
-- character's `collapsed` table, title to true, is read by), TR.OTHER_KEY for
-- Other and TR.ALL_KEY for the one list with Group by zone off (title nil, never
-- collapsed). current says the title is the current zone's, campaign is the
-- header's campaign ID (nil for none). A collapsed group keeps its quests, with
-- count their number: it's the drawing that leaves them out. No quests, no
-- groups.
--
-- Order of groups: the current zone's first (with current_first), then the
-- campaigns, then the rest in the log's header order, Other last. Headers that
-- repeat a title are one group, in the first one's place. Headers' order is
-- told by their quests' log indexes, since a header sits above its quests.
-- settings is the quests settings: zones, current_first, order, finished_first.
function Groups.Build(quests, settings, zoneNames, collapsed)
	collapsed = collapsed or {}
	if #quests == 0 then return {} end

	if not settings.zones then
		local list = {}
		for i, quest in ipairs(quests) do list[i] = quest end
		Groups.Sort(list, settings.order, settings.finished_first)
		return { { key = TR.ALL_KEY, current = false, collapsed = false, count = #list, quests = list } }
	end

	local byKey, groups = {}, {}
	for _, quest in ipairs(quests) do
		local key = quest.headerTitle or TR.OTHER_KEY
		local group = byKey[key]
		if not group then
			group = {
				key = key, title = quest.headerTitle or TR.OTHER_TITLE, quests = {}, first = quest.logIndex or 0,
				current = quest.headerTitle ~= nil and Groups.IsCurrent(quest.headerTitle, zoneNames),
				campaign = quest.campaign, other = quest.headerTitle == nil,
			}
			byKey[key] = group
			groups[#groups + 1] = group
		end
		group.quests[#group.quests + 1] = quest
		if (quest.logIndex or 0) < group.first then group.first = quest.logIndex or 0 end
		if group.campaign == nil then group.campaign = quest.campaign end
	end

	-- 1 current, 2 campaign, 3 the rest, 4 Other.
	local function Rank(group)
		if group.other then return 4 end
		if group.current and settings.current_first then return 1 end
		if group.campaign then return 2 end
		return 3
	end
	table.sort(groups, function(a, b)
		local ra, rb = Rank(a), Rank(b)
		if ra ~= rb then return ra < rb end
		return a.first < b.first
	end)

	for _, group in ipairs(groups) do
		Groups.Sort(group.quests, settings.order, settings.finished_first)
		group.count = #group.quests
		group.collapsed = collapsed[group.key] == true
		group.first, group.other = nil, nil
	end
	return groups
end
