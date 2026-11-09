-- Live choices on the roll bars. While a roll is open, each roll button shows
-- how many players have picked that choice so far, and hovering the bar shows
-- the item tooltip with everyone's choices added (LT:AddRollLines).
--
-- The game doesn't link a roll (a bar's rollID) to its drop in C_LootHistory,
-- so a bar is matched to a drop still being rolled by its item, comparing
-- GetLootRollItemLink(rollID) with the drop's itemHyperlink. Each drop goes to
-- one bar at most, and a drop you've already chosen on goes to none. Two
-- copies of an item go first come, first served: bars by rollID, drops oldest
-- first. Copies rolled at once can end up swapped; that's accepted. A bar that
-- keeps its roll keeps its drop while the drop is still open, so a later
-- update never swaps them. A bar with no drop shows no counts, and its tooltip
-- is just the item's.
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
--   rollID, item, itemID (the roll's item string and ID),
--   dropID (the matched drop's encounterID:index), rolls (its live summary),
-- }
local bars = setmetatable({}, { __mode = 'k' })

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
	state.rollID, state.item, state.itemID = nil, nil, nil
	state.dropID, state.rolls = nil, nil
	LT:SetRollCounts(state.counts, nil)
end

-- A bar still up means you haven't chosen on its roll yet, so a drop you've
-- chosen on (your state on it plain and not NoRoll) is never a bar's. That
-- keeps a frame reused for a queued copy of an item off the copy you already
-- chose on. During the Need dice animation the bar stays up after you chose
-- and loses its match; that's accepted (its buttons are hidden then anyway).
local function StillYours(drop)
	return drop.playerState == nil or drop.playerState == LT.ROLL_STATE.NoRoll
end

-- Pass 1 matches the same item string, pass 2 only the same item ID: a link
-- that differs from the history's in its other fields still finds its drop,
-- without taking a drop from a bar whose item string matches it exactly.
local function Matches(drop, state, pass)
	if pass == 1 then return drop.item == state.item end
	return drop.itemID ~= nil and drop.itemID == state.itemID
end

-- Matches every shown roll bar to a drop still being rolled, then sets its
-- counts and rebuilds its info frame's tooltip if that's open. Runs after
-- every loot history update (Feed/rolls.lua) and when a bar shows or hides,
-- so a drop a hidden bar let go of can match another bar. An open tooltip on
-- the icon frame needs nothing: Blizzard sets it again every frame.
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
			if link then state.item, state.itemID = self.ItemString(link), self.ItemID(link) end
		end
		if state.item then
			tinsert(shown, state)
			frames[state] = frame
		elseif state.dropID or state.rolls then
			state.dropID, state.rolls = nil, nil
			self:SetRollCounts(state.counts, nil)
		end
	end
	if not shown[1] then return end
	-- First come, first served, assuming the game numbers rolls in the order
	-- they start (likely, not confirmed).
	table.sort(shown, function(a, b) return a.rollID < b.rollID end)

	local open, byID = {}, {}
	for _, drop in ipairs(self:GetOpenDrops()) do
		if StillYours(drop) then
			drop.item, drop.itemID = self.ItemString(drop.link), self.ItemID(drop.link)
			tinsert(open, drop)
			byID[drop.id] = drop
		end
	end

	-- Bars keep their drop while it's still open.
	local claimed = {}
	for _, state in ipairs(shown) do
		local drop = state.dropID and byID[state.dropID]
		if drop and not claimed[drop.id] and (Matches(drop, state, 1) or Matches(drop, state, 2)) then
			claimed[drop.id] = true
		else
			state.dropID = nil
		end
	end

	-- The rest take the oldest unclaimed drop of their item.
	for pass = 1, 2 do
		for _, state in ipairs(shown) do
			if not state.dropID then
				for _, drop in ipairs(open) do
					if not claimed[drop.id] and Matches(drop, state, pass) then
						claimed[drop.id] = true
						state.dropID = drop.id
						break
					end
				end
			end
		end
	end

	-- The sorted info orders each choice's players as Blizzard's Loot Rolls window does.
	for _, state in ipairs(shown) do
		local drop = state.dropID and byID[state.dropID]
		local info = drop and C_LootHistory.GetSortedInfoForDrop(drop.encounterID, drop.index)
		state.rolls = self:SummarizeDrop(info)
		self:SetRollCounts(state.counts, state.rolls)

		local body = self:GetRollInfoFrame(frames[state])
		if body and GameTooltip:IsOwned(body) then body:UpdateTooltip() end
	end
end

------------------------------------
---- Bars --------------------------
------------------------------------

local function OnBarShow()
	LT:UpdateRollBars()
end

local function OnBarHide(frame)
	local state = bars[frame]
	if state then ClearBar(state) end
	LT:UpdateRollBars()
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
