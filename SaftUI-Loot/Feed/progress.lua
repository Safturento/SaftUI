-- Progress snapshots for the experience and reputation feed entries. A
-- snapshot is taken when the entry is pushed and kept on it (info.progress), so
-- the entry's bar keeps showing what it showed when the entry arrived:
-- re-renders and scrolling never read the live values again.
-- A snapshot is { value, max, r, g, b }. It's nil when there's nothing true to
-- show (no XP to earn, faction not found, secret values), which hides the bar.

local st = SaftUI
local LT = st.Loot

-- Checked before any arithmetic or comparison on a number from the API.
local function IsSecret(...)
	for i = 1, select('#', ...) do
		if issecretvalue((select(i, ...))) then return true end
	end
	return false
end

local function NewProgress(value, total, color)
	if IsSecret(value, total) then return end
	if type(value) ~= 'number' or type(total) ~= 'number' or total <= 0 then return end

	local r, g, b = 1, 1, 1
	if color then r, g, b = color:GetRGB() end
	return { value = value, max = total, r = r, g = g, b = b }
end

local function FullBar(color)
	return NewProgress(1, 1, color)
end

------------------------------------
---- Experience --------------------
------------------------------------

local function ExperienceProgress()
	-- UnitXPMax is 0 when there's no XP to earn, which hides the bar.
	return NewProgress(UnitXP('player'), UnitXPMax('player'), st.config.profile.colors.experience.normal)
end

------------------------------------
---- Reputation --------------------
------------------------------------

-- Faction name -> factionID. C_Reputation.GetFactionDataByIndex only walks the
-- rows the reputation panel lists right now, so factions under a collapsed
-- header aren't in it, and expanding a header would change Blizzard's UI
-- state. So every faction seen in a list scan, as the watched faction or in
-- FACTION_STANDING_CHANGED is remembered here and read back by ID.
local factionIDs = {}

local function RememberFaction(data)
	if not data or IsSecret(data.factionID, data.name) then return end
	if data.isHeader and not data.isHeaderWithRep then return end

	local id, name = data.factionID, data.name
	if type(id) == 'number' and id > 0 and type(name) == 'string' and name ~= '' then
		factionIDs[name] = id
	end
end

local function ScanFactions()
	if C_Reputation.GetWatchedFactionData then
		RememberFaction(C_Reputation.GetWatchedFactionData())
	end

	if not (C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex) then return end
	local num = C_Reputation.GetNumFactions()
	if IsSecret(num) or type(num) ~= 'number' then return end

	for index = 1, num do
		RememberFaction(C_Reputation.GetFactionDataByIndex(index))
	end
end

local function LookupFaction(name)
	local id = factionIDs[name]
	local data = id and C_Reputation.GetFactionDataByID(id)
	if data and not IsSecret(data.name) and data.name == name then return data end
end

local function FindFaction(name)
	if not (C_Reputation and C_Reputation.GetFactionDataByID) then return end
	if IsSecret(name) or type(name) ~= 'string' then return end

	local data = LookupFaction(name)
	if data then return data end

	ScanFactions()
	return LookupFaction(name)
end

-- FACTION_STANDING_CHANGED handler: remembers the faction even when it sits
-- under a collapsed header.
function LT:RememberChangedFaction(_, factionID)
	if IsSecret(factionID) or type(factionID) ~= 'number' then return end
	if not (C_Reputation and C_Reputation.GetFactionDataByID) then return end
	RememberFaction(C_Reputation.GetFactionDataByID(factionID))
end

-- SaftUI's reaction colors (the profile's, which the Colors tab edits), else
-- Blizzard's standing colors.
local function ReactionColor(reaction)
	local color = st.config.profile.colors.reaction[reaction]
	if color then return color end
	color = FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
	if color and color.GetRGB then return color end
end

-- Progress within the current rank, in the same order Blizzard's own
-- reputation status bar checks (ReputationStatusBarMixin:Update): paragon,
-- renown, friendship, then standard standings.
local function ReputationProgress(factionName)
	local data = FindFaction(factionName)
	if not data or IsSecret(data.factionID, data.reaction) then return end

	local id, reaction = data.factionID, data.reaction
	local colors = st.config.profile.colors
	local isMajor = C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(id)

	-- Paragon: toward the next paragon reward, full while one is waiting.
	if C_Reputation.IsFactionParagonForCurrentPlayer and C_Reputation.IsFactionParagonForCurrentPlayer(id) then
		local value, threshold, _, rewardPending = C_Reputation.GetFactionParagonInfo(id)
		if IsSecret(value, threshold) or type(value) ~= 'number' or type(threshold) ~= 'number' or threshold <= 0 then
			return
		end
		local color = isMajor and colors.renown or ReactionColor(reaction)
		if rewardPending then return FullBar(color) end
		return NewProgress(value % threshold, threshold, color)
	end

	-- Renown: through the current renown level, full at max renown.
	if isMajor then
		if not C_MajorFactions then return end
		if C_MajorFactions.HasMaximumRenown and C_MajorFactions.HasMaximumRenown(id) then
			return FullBar(colors.renown)
		end
		local major = C_MajorFactions.GetMajorFactionData and C_MajorFactions.GetMajorFactionData(id)
		if not major then return end
		return NewProgress(major.renownReputationEarned, major.renownLevelThreshold, colors.renown)
	end

	-- Friendship: through the current rank, full at max rank. Blizzard colors
	-- every friendship green.
	local friendship = C_GossipInfo and C_GossipInfo.GetFriendshipReputation
		and C_GossipInfo.GetFriendshipReputation(id)
	if friendship and not IsSecret(friendship.friendshipFactionID)
		and type(friendship.friendshipFactionID) == 'number' and friendship.friendshipFactionID > 0 then
		local standing, low, high = friendship.standing, friendship.reactionThreshold, friendship.nextThreshold
		local color = ReactionColor(5)
		if IsSecret(standing, low, high) then return end
		if high == nil then return FullBar(color) end
		if type(standing) ~= 'number' or type(low) ~= 'number' or type(high) ~= 'number' then return end
		return NewProgress(standing - low, high - low, color)
	end

	-- Standard: within the current standing, e.g. Friendly 1200/6000.
	local value, low, high = data.currentStanding, data.currentReactionThreshold, data.nextReactionThreshold
	if IsSecret(value, low, high) then return end
	if type(value) ~= 'number' or type(low) ~= 'number' or type(high) ~= 'number' then return end

	local color = ReactionColor(reaction)
	-- No room above the current standing means it's capped: a full bar.
	if high <= low then return FullBar(color) end
	return NewProgress(value - low, high - low, color)
end

------------------------------------
---- Snapshots ---------------------
------------------------------------

-- A snapshot that fails must never stop the entry itself from being pushed.
local function Snapshot(fn, ...)
	local ok, progress = pcall(fn, ...)
	if ok then return progress end
	st:Debug('Loot', 'Feed progress snapshot failed:', progress)
end

function LT:SnapshotExperienceProgress()
	return Snapshot(ExperienceProgress)
end

function LT:SnapshotReputationProgress(factionName)
	return Snapshot(ReputationProgress, factionName)
end
