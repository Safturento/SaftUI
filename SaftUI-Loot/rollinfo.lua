-- Live choices on the roll bars. While a roll is open, each roll button shows
-- how many players have picked that choice so far, and hovering the bar shows
-- the item tooltip with everyone's choices added (LT:AddRollLines).
--
-- The game doesn't link a roll (a bar's rollID) to its drop in C_LootHistory,
-- so a bar is matched to a drop still being rolled by its item, comparing
-- GetLootRollItemLink(rollID) with the drop's itemHyperlink. Each drop goes to
-- one bar at most. Two copies of an item go first come, first served: bars by
-- rollID, drops oldest first. Copies rolled at once can end up swapped; that's
-- accepted. A bar that keeps its roll keeps its drop while the drop is still
-- open, so a later update never swaps them. A bar with no drop shows no
-- counts, and its tooltip is just the item's.
--
-- Held rolls: once you choose on a roll, Blizzard takes its bar away, and
-- roll.lua shows a bar of SaftUI's in its place, locked on your choice
-- (LT:HoldRoll), until the roll ends. Your choice is seen through a post-hook on
-- RollOnLoot; the held bar carries the roll's drop forward and is matched and
-- updated here with the Blizzard bars. A Blizzard bar never takes a drop
-- you've chosen on (only a bar that keeps its roll keeps one), and a held roll
-- only takes one you have. It goes when its drop resolves (here) or its time
-- runs out (roll.lua).
--
-- The roll frames and their buttons are Blizzard's: nothing is written onto
-- them. Each bar's count font strings and matched drop live in `bars`, keyed by
-- the roll frame, and Blizzard's scripts get post-hooks only. The info frame
-- (the bar's body) is SaftUI's own, from roll.lua (LT:GetRollInfoFrame).
--
-- Feed/rolls.lua calls LT:UpdateRollBars after every loot history update, and
-- provides the plain-value checks and LT:GetOpenDrops used here. It loads after
-- this file, so those are looked up when called.

local st = SaftUI
local LT = st:GetModule('Loot')

-- [Blizzard roll frame] = {
--   counts = { [font string] = { choice, color } } (LT:CreateRollCounts),
--   rollID, link, item, itemID (the roll's link, item string and ID),
--   dropID (the matched drop's encounterID:index), rolls (its live summary),
--   lastDropID (the drop this roll was last matched to),
-- }
local bars = setmetatable({}, { __mode = 'k' })

-- Your choice on each roll still on a Blizzard bar, by rollID: { choice (the
-- roll button it's counted on), ends (the GetTime its time runs out), length
-- (the roll's, in seconds) }. Recorded when RollOnLoot is called for it (a roll
-- button's click, or an addon's), and taken when its bar goes. The time is read
-- then: a main spec Need zeroes Blizzard's timer for its dice animation.
local chosen = {}

------------------------------------
---- Counts ------------------------
------------------------------------

-- The roll button each choice counts on (built on first use: LT.ROLL_STATE
-- comes from Feed/rolls.lua). Both kinds of need count as Need.
local buttonForState
local function ButtonForState(state)
	if not buttonForState then
		local S = LT.ROLL_STATE
		buttonForState = {
			[S.NeedMainSpec] = 'Need',
			[S.NeedOffSpec] = 'Need',
			[S.Transmog] = 'Transmog',
			[S.Greed] = 'Greed',
			[S.Pass] = 'Pass',
		}
	end
	return buttonForState[state]
end

-- Blizzard shows Greed or Transmog on a bar, never both. The one it shows also
-- counts the other's picks, as a second number in that choice's colour (the
-- colours roll.lua gives those buttons' letters).
local PAIRED = {
	Greed = { choice = 'Transmog', color = 'purple' },
	Transmog = { choice = 'Greed', color = 'yellow' },
}

local function NewCount(button, point, x, y)
	local text = button:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(st:GetFont('pixel'))
	text:SetJustifyH('RIGHT')
	text:SetPoint(point, button, point, x, y)
	text:Hide()
	return text
end

-- Adds a roll button's counts to `counts`, a table of [font string] = { choice,
-- color }: its own, a small white number in its bottom right corner like a
-- stack count on an item, and on Greed or Transmog the other one's, top right.
-- Each is hidden until someone has picked that choice.
function LT:CreateRollCounts(counts, button, name)
	counts[NewCount(button, 'BOTTOMRIGHT', 1, 1)] = { choice = name }
	if PAIRED[name] then counts[NewCount(button, 'TOPRIGHT', 1, -1)] = PAIRED[name] end
end

-- Sets every count from a summary in LT:SummarizeDrop's shape. With no summary
-- (a bar with no drop), every count is hidden.
function LT:SetRollCounts(counts, rolls)
	local totals = {}
	local list = type(rolls) == 'table' and type(rolls.list) == 'table' and rolls.list or {}
	for _, line in ipairs(list) do
		local name = type(line) == 'table' and ButtonForState(line.state)
		if name then totals[name] = (totals[name] or 0) + 1 end
	end

	for text, count in pairs(counts) do
		local total = totals[count.choice]
		if total then
			text:SetText(total)
			if count.color then text:SetTextColor(st.config.profile.colors.text[count.color]:GetRGB()) end
			text:Show()
		else
			text:SetText('')
			text:Hide()
		end
	end
end

------------------------------------
---- Tooltips ----------------------
------------------------------------

-- The rolls to add to a bar's tooltip: the matched drop's, and only while the
-- frame still shows the roll they were matched for.
local function BarRolls(frame, rollID)
	local state = bars[frame]
	if state and rollID and state.rollID == rollID then return state.rolls end
end

-- Hover scripts for one of SaftUI's own frames (a bar's info frame, the
-- previews' icon and info frames). `source(owner)` gives the tooltip method
-- that shows the item, its argument, and the rolls to add after it (nil adds
-- none). When the item's data arrives, GameTooltip redoes the item part and
-- drops lines added after it; with UpdateTooltip on the owner, it calls that
-- instead (then, and on its update timer), so the rolls are added again.
function LT:SetRollTooltipScripts(owner, source)
	owner:EnableMouse(true)
	owner.UpdateTooltip = function(self)
		local method, arg, rolls = source(self)
		if not arg or GameTooltip:IsForbidden() then return end
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		GameTooltip[method](GameTooltip, arg)
		if rolls then LT:AddRollLines(GameTooltip, rolls, true) end
		GameTooltip:Show()
	end
	owner:SetScript('OnEnter', owner.UpdateTooltip)
	owner:SetScript('OnLeave', function(self)
		if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
end

-- The info frame's tooltip: the roll's item, as the icon frame shows it.
local function InfoTooltip(owner)
	local frame = owner:GetParent()
	local rollID = LT.PlainNumber(frame.rollID)
	return 'SetLootRollItem', rollID, BarRolls(frame, rollID)
end

-- Blizzard's icon frame shows the item on enter and sets it again every frame
-- while hovered (its OnUpdate). These post-hooks add the rolls each time.
local function AddIconLines(icon)
	if not GameTooltip:IsOwned(icon) then return end
	local frame = icon:GetParent()
	local rolls = BarRolls(frame, LT.PlainNumber(frame.rollID))
	if rolls then
		LT:AddRollLines(GameTooltip, rolls, true)
		GameTooltip:Show()
	end
end

------------------------------------
---- Matching ----------------------
------------------------------------

local function ClearBar(state)
	state.rollID, state.link, state.item, state.itemID = nil, nil, nil, nil
	state.dropID, state.rolls, state.lastDropID = nil, nil, nil
	LT:SetRollCounts(state.counts, nil)
end

-- A Blizzard bar still up means you haven't chosen on its roll yet, so it never
-- takes a drop you've chosen on (your state on it plain and not NoRoll). That
-- keeps a frame reused for a queued copy of an item off the copy you already
-- chose on. A held roll takes only a drop you've chosen on.
local function StillYours(drop)
	return drop.playerState == nil or drop.playerState == LT.ROLL_STATE.NoRoll
end

local function Chosen(drop)
	return not StillYours(drop)
end

-- Pass 1 matches the same item string, pass 2 only the same item ID: a link
-- that differs from the history's in its other fields still finds its drop,
-- without taking a drop from a bar whose item string matches it exactly.
local function Matches(drop, state, pass)
	if pass == 1 then return drop.item == state.item end
	return drop.itemID ~= nil and drop.itemID == state.itemID
end

-- Each bar in `list` (Blizzard's or held, by rollID) with no drop takes the
-- oldest unclaimed open drop of its item that `takes` allows.
local function ClaimDrops(list, open, claimed, pass, takes)
	for _, state in ipairs(list) do
		if not state.dropID then
			for _, drop in ipairs(open) do
				if not claimed[drop.id] and takes(drop) and Matches(drop, state, pass) then
					claimed[drop.id] = true
					state.dropID = drop.id
					break
				end
			end
		end
	end
end

-- Rebuilds an open tooltip on one of SaftUI's frames with its rolls.
local function UpdateOpenTooltip(owner)
	if owner and GameTooltip:IsOwned(owner) then owner:UpdateTooltip() end
end

local function ByRoll(a, b) return a.rollID < b.rollID end

-- Matches every shown roll bar and every held roll (roll.lua) to a drop still
-- being rolled, then sets its counts and rebuilds its tooltip if that's open;
-- a held roll whose drop has resolved goes. Runs after every loot history
-- update (Feed/rolls.lua) and when a bar shows or hides, so a drop a hidden bar
-- let go of can match another bar. An open tooltip on a Blizzard bar's icon
-- frame needs nothing: Blizzard sets it again every frame.
function LT:UpdateRollBars()
	local PlainNumber, PlainString = self.PlainNumber, self.PlainString
	if not PlainNumber then return end

	local frames, shown = {}, {}
	for frame, state in pairs(bars) do
		local rollID = frame:IsShown() and PlainNumber(frame.rollID) or nil
		-- A new roll on the frame (or none): nothing carries over from the last.
		if rollID ~= state.rollID then
			ClearBar(state)
			state.rollID = rollID
		end
		if rollID and not state.item then
			local link = PlainString(GetLootRollItemLink(rollID))
			if link then state.link, state.item, state.itemID = link, self.ItemString(link), self.ItemID(link) end
		end
		if state.item then
			tinsert(shown, state)
			frames[state] = frame
		elseif state.dropID or state.rolls then
			state.dropID, state.rolls = nil, nil
			self:SetRollCounts(state.counts, nil)
		end
	end
	local held = {}
	for _, bar in ipairs(self:GetHeldRolls()) do
		if bar.item then tinsert(held, bar) end
	end
	if not shown[1] and not held[1] then return end
	-- First come, first served, assuming the game numbers rolls in the order
	-- they start (likely, not confirmed).
	table.sort(shown, ByRoll)
	table.sort(held, ByRoll)

	local open, byID = {}, {}
	for _, drop in ipairs(self:GetOpenDrops()) do
		drop.item, drop.itemID = self.ItemString(drop.link), self.ItemID(drop.link)
		tinsert(open, drop)
		byID[drop.id] = drop
	end

	-- A held roll keeps its drop while it's open, and goes once it isn't: the
	-- game has awarded the item or everyone passed, or its roll time is over.
	local claimed, ended = {}, {}
	for _, bar in ipairs(held) do
		local drop = bar.dropID and byID[bar.dropID]
		if drop and not claimed[drop.id] then
			claimed[drop.id] = true
		elseif drop then
			bar.dropID = nil
		elseif bar.dropID then
			ended[bar] = true
		end
	end

	-- A Blizzard bar keeps its drop while it's open, even once you've chosen on
	-- it: a main spec Need's dice animation keeps the bar up for a while after,
	-- and the held roll then takes the drop from it.
	for _, state in ipairs(shown) do
		local drop = state.dropID and byID[state.dropID]
		if drop and not claimed[drop.id] and (Matches(drop, state, 1) or Matches(drop, state, 2)) then
			claimed[drop.id] = true
		else
			state.dropID = nil
		end
	end

	-- The rest take the oldest unclaimed drop of their item: a held roll one
	-- you've chosen on, a Blizzard bar one you haven't.
	for pass = 1, 2 do
		ClaimDrops(held, open, claimed, pass, Chosen)
		ClaimDrops(shown, open, claimed, pass, StillYours)
	end

	-- The sorted info orders each choice's players as Blizzard's Loot Rolls window does.
	local function Summary(state)
		local drop = state.dropID and byID[state.dropID]
		local info = drop and C_LootHistory.GetSortedInfoForDrop(drop.encounterID, drop.index)
		return self:SummarizeDrop(info)
	end
	for _, state in ipairs(shown) do
		state.rolls = Summary(state)
		state.lastDropID = state.dropID or state.lastDropID
		self:SetRollCounts(state.counts, state.rolls)
		UpdateOpenTooltip(self:GetRollInfoFrame(frames[state]))
	end
	for _, bar in ipairs(held) do
		if not ended[bar] then
			bar.rolls = Summary(bar)
			self:SetRollCounts(bar.counts, bar.rolls)
			UpdateOpenTooltip(bar.InfoFrame)
			UpdateOpenTooltip(bar.IconFrame)
		end
	end
	for _, bar in ipairs(held) do
		if ended[bar] then self:ReleaseHeldRoll(bar) end
	end
end

------------------------------------
---- Bars --------------------------
------------------------------------

local function OnBarShow()
	LT:UpdateRollBars()
end

-- The bar hid. Hidden itself (not only with UIParent), Blizzard took its roll
-- away: it ended, or you chose on it. If you chose, the roll is held, carrying
-- the drop it was matched to (or last was: one that resolved just before
-- makes the held roll go at once, below).
local function OnBarHide(frame)
	local state = bars[frame]
	if state then
		local choice = state.rollID and chosen[state.rollID]
		if choice and not frame:IsShown() then
			chosen[state.rollID] = nil
			LT:HoldRoll(frame, {
				rollID = state.rollID, choice = choice.choice, ends = choice.ends, length = choice.length,
				link = state.link, item = state.item, itemID = state.itemID,
				dropID = state.dropID or state.lastDropID, rolls = state.dropID and state.rolls,
			})
		end
		ClearBar(state)
	end
	LT:UpdateRollBars()
end

-- RollOnLoot's roll types, the roll buttons' IDs (GroupLootFrame.xml), by the
-- button each is counted on. Disenchant (3) has no button on these bars:
-- LT:HoldRoll lights whichever of Greed and Transmog the bar shows.
local CHOICE_FOR_ROLL_TYPE = { [0] = 'Pass', [1] = 'Need', [2] = 'Greed', [3] = 'Disenchant', [4] = 'Transmog' }

-- After RollOnLoot (a roll button's OnClick, or an addon): notes your choice on
-- a roll a skinned bar shows, with the time it has left. A choice the game asks
-- you to confirm (CONFIRM_LOOT_ROLL, for a bind on pickup item) is noted at
-- once; cancelling it leaves the bar up, and the next choice replaces it.
local function OnRollChosen(rollID, rollType)
	local PlainNumber = LT.PlainNumber
	if not PlainNumber then return end
	rollID, rollType = PlainNumber(rollID), PlainNumber(rollType)
	local choice = rollType and CHOICE_FOR_ROLL_TYPE[rollType]
	if not (rollID and choice) then return end
	for frame in pairs(bars) do
		if frame:IsShown() and PlainNumber(frame.rollID) == rollID then
			local _, length = frame.Timer:GetMinMaxValues()
			local left = PlainNumber(frame.Timer:GetValue())
			length = PlainNumber(length)
			if left and length then
				chosen[rollID] = {
					choice = choice,
					ends = GetTime() + LT.RollSeconds(left, length),
					length = LT.RollSeconds(length, length),
				}
			end
			return
		end
	end
end
if type(RollOnLoot) == 'function' then
	hooksecurefunc('RollOnLoot', OnRollChosen)
end

-- CANCEL_ALL_LOOT_ROLLS (registered in roll.lua's LT:InitializeRollFrame):
-- every roll is cancelled, say on leaving the group, so no choice is held and
-- every held roll goes. Blizzard's frames take themselves away on it too, before
-- or after this. Before: a frame whose choice was still pending (a confirmation
-- open, a Need's dice animation) has just been held, and goes here. After:
-- there's no choice left to hold.
function LT:OnCancelAllLootRolls()
	wipe(chosen)
	local list = {}
	for _, bar in ipairs(self:GetHeldRolls()) do tinsert(list, bar) end
	for _, bar in ipairs(list) do self:ReleaseHeldRoll(bar) end
end

-- Called once per roll frame from SkinRollFrame (roll.lua), after its info
-- frame exists. `counts` is the table LT:CreateRollCounts filled for its buttons.
function LT:AttachRollInfo(frame, counts)
	if bars[frame] then return end
	bars[frame] = { counts = counts }

	frame:HookScript('OnShow', OnBarShow)
	frame:HookScript('OnHide', OnBarHide)
	frame.IconFrame:HookScript('OnEnter', AddIconLines)
	frame.IconFrame:HookScript('OnUpdate', AddIconLines)
	self:SetRollTooltipScripts(self:GetRollInfoFrame(frame), InfoTooltip)

	-- A frame is skinned just after its first roll shows.
	self:UpdateRollBars()
end
