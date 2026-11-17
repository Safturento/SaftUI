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
-- (LT:HoldRoll), until the roll ends. Your choice is known before the bar goes:
-- on a plain click the game cancels the roll inside RollOnLoot, so the bar hides
-- before RollOnLoot returns. A pre-hook on each roll button (PreClick) notes the
-- click as pending, and the bar hiding holds the roll with it; a post-hook on
-- RollOnLoot notes the choice that leaves the bar up (a bind on pickup
-- confirmation, a Need's dice animation), and holds a roll whose bar hid with
-- no click behind it (another addon's RollOnLoot) from a snapshot taken at the
-- hide. The held bar carries the roll's drop
-- forward and is matched and updated here with the Blizzard bars. A Blizzard
-- bar never takes a drop you've chosen on (only a bar that keeps its roll keeps
-- one), and a held roll only takes one you have. It finishes when its drop resolves (here) or its
-- time runs out (roll.lua): it then stays up a few seconds and fades before it
-- goes (roll.lua), takes no drop and is left out of matching; it still shows
-- the later results of the drop it finished on (counts only).
--
-- The roll frames and their buttons are Blizzard's: nothing is written onto
-- them. Each bar's count font strings and matched drop live in `bars`, keyed by
-- the roll frame, and Blizzard's scripts get native hooks only. The info frame
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
-- (the roll's, in seconds) }. Recorded after RollOnLoot returns with the bar
-- still up (a bind on pickup confirmation, a Need's dice animation), and taken
-- when its bar goes.
local chosen = {}

-- The same, for a roll button's click still under way, by rollID: recorded at
-- PreClick, before RollOnLoot, and cleared at PostClick, so it never outlives its
-- click. The time is read then: the game can cancel the roll inside RollOnLoot
-- (a plain click), and a main spec Need's dice animation zeroes Blizzard's timer
-- (it probably starts after the call, on the server's answer; if it starts inside
-- it, the time is still the one read here). `held` is set once the bar's hiding has held the roll with it.
local pending = {}
-- [roll button] = the rollID its click is pending for, to clear it at PostClick
-- (the frame may show another roll by then).
local clicking = setmetatable({}, { __mode = 'k' })

-- A bar that hid with no choice known, by rollID, until RollOnLoot returns: a
-- call from another addon has no PreClick, and on a roll with no confirmation
-- the game cancels the roll inside the call, so the bar hides first. The roll's
-- state as it was at the hide ({ frame, roll (HoldRoll's, with the item's
-- `shown` and stack `index`) }); the RollOnLoot post-hook holds from it if it
-- names that roll. Dropped at the next frame (a bar that ended on its own is
-- never claimed).
local hidden = {}

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
	Greed = { choice = 'Transmog', color = 'transmog' },
	Transmog = { choice = 'Greed', color = 'greed' },
}

local function NewCount(button, point, x, y)
	local text = button:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(text, 'pixel')
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
			if count.color then text:SetTextColor(st:Color('loot', count.color):GetRGB()) end
			text:Show()
		else
			text:SetText('')
			text:Hide()
		end
	end
end

-- The shown paired counts in Loot color `key` (nil: every one), in their color
-- as it is now: those of Blizzard's bars (`bars`), the held bars' and the
-- previews'. Only the color is set. From LT:ColorRollBars.
local NONE = {} -- what a pass walks when there is nothing: no table per pass
local function ColorCounts(counts, key)
	for text, count in pairs(counts) do
		if count.color and (key == nil or key == count.color) and text:IsShown() then
			text:SetTextColor(st:Color('loot', count.color):GetRGB())
		end
	end
end

function LT:ColorRollCounts(key)
	for _, state in pairs(bars) do ColorCounts(state.counts, key) end
	for _, bar in ipairs(self:GetHeldRolls()) do ColorCounts(bar.counts, key) end
	for _, bar in ipairs(self.rollPreview and self.rollPreview.bars or NONE) do ColorCounts(bar.counts, key) end
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
					-- A claim happens once, when a bar has no drop: not every update.
					if st.DEBUG and takes == Chosen then st:Debug('Loot', 'held roll', state.rollID, 'took drop', drop.id) end
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

-- A drop's summary from its id (encounterID:index, as LT:GetOpenDrops makes
-- them), nil when it can't be read.
function LT:ReadDropRolls(dropID)
	local encounterID, index = dropID:match('^(%-?%d+):(%-?%d+)$')
	local info = encounterID and C_LootHistory.GetSortedInfoForDrop(tonumber(encounterID), tonumber(index))
	return self:SummarizeDrop(info)
end

-- Matches every shown roll bar and every held roll (roll.lua) to a drop still
-- being rolled, then sets its counts and rebuilds its tooltip if that's open;
-- a held roll whose drop has resolved finishes. Runs after every loot history
-- update (Feed/rolls.lua) and when a bar shows or hides, so a drop a hidden bar
-- let go of can match another bar. An open tooltip on a Blizzard bar's icon
-- frame needs nothing: Blizzard sets it again every frame.
function LT:UpdateRollBars()
	local PlainNumber, PlainString = self.PlainNumber, self.PlainString

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
		if bar.finishedAt then
			-- A finished bar takes no part in matching, but shows later results for
			-- the drop it finished on, counts only: a time-out's auto-passes and
			-- winner come inside its linger.
			local rolls = bar.finalDropID and self:ReadDropRolls(bar.finalDropID)
			if rolls then
				bar.rolls = rolls
				self:SetRollCounts(bar.counts, rolls)
				UpdateOpenTooltip(bar.InfoFrame)
				UpdateOpenTooltip(bar.IconFrame)
			end
		elseif bar.item then
			tinsert(held, bar)
		end
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

	-- A held roll keeps its drop while it's open, and finishes once it isn't: the
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
	-- The drop's last summary gives the finished bar its final counts, if it can
	-- still be read; if not, the bar keeps the counts it had.
	for _, bar in ipairs(held) do
		if ended[bar] then
			self:FinishHeldRoll(bar, 'drop resolved', self:ReadDropRolls(bar.dropID))
		end
	end
end

------------------------------------
---- Bars --------------------------
------------------------------------

local function OnBarShow()
	LT:UpdateRollBars()
end

-- The bar hid. Hidden itself (not only with UIParent), Blizzard took its roll
-- away: it ended, or you chose on it. If you chose (a click under way, or a
-- choice noted), the roll is held now, from the bar's state as it is at this
-- hide: the frame may show another roll before RollOnLoot returns. It carries
-- the drop it was matched to (or last was: one that resolved just before
-- makes the held roll finish at once (LT:UpdateRollBars, below): it stays up a
-- few seconds and fades).
local ReadTimer
local function OnBarHide(frame)
	local state = bars[frame]
	if state then
		-- A click under way is newer than a choice noted before it.
		local choice = state.rollID and (pending[state.rollID] or chosen[state.rollID])
		if st.DEBUG and state.rollID then
			st:Debug('Loot', 'bar hid:', state.rollID, 'choice noted', chosen[state.rollID] ~= nil,
				'pending', pending[state.rollID] ~= nil,
				'frame hidden', not frame:IsShown(), 'drop', state.dropID or state.lastDropID)
		end
		if choice and not frame:IsShown() then
			chosen[state.rollID] = nil
			local bar = LT:HoldRoll(frame, {
				rollID = state.rollID, choice = choice.choice, ends = choice.ends, length = choice.length,
				link = state.link, item = state.item, itemID = state.itemID,
				dropID = state.dropID or state.lastDropID, rolls = state.dropID and state.rolls,
			})
			-- Only a hold that happened: the post-hook says nothing of one skipped.
			if bar then choice.held = true end
		elseif state.rollID and not frame:IsShown() then
			local timer = ReadTimer(frame)
			local shown, index = LT:RollSnapshot(frame)
			if timer and shown then
				local rollID = state.rollID
				local snapshot = { frame = frame, roll = {
					rollID = rollID, choice = nil, ends = timer.ends, length = timer.length,
					link = state.link, item = state.item, itemID = state.itemID,
					dropID = state.dropID or state.lastDropID, rolls = state.dropID and state.rolls,
					shown = shown, index = index,
				} }
				hidden[rollID] = snapshot
				C_Timer.After(0, function()
					if hidden[rollID] == snapshot then hidden[rollID] = nil end
				end)
			end
		end
		ClearBar(state)
	end
	LT:UpdateRollBars()
end

-- RollOnLoot's roll types, the roll buttons' IDs (GroupLootFrame.xml), by the
-- button each is counted on. Disenchant (3) has no button on these bars:
-- LT:HoldRoll lights whichever of Greed and Transmog the bar shows.
local CHOICE_FOR_ROLL_TYPE = { [0] = 'Pass', [1] = 'Need', [2] = 'Greed', [3] = 'Disenchant', [4] = 'Transmog' }

-- The roll's time left, as Blizzard's timer shows it now: { ends (the GetTime
-- it runs out), length (the roll's, in seconds), left } in plain seconds, or nil
-- when its values are not plain numbers.
function ReadTimer(frame)
	local PlainNumber = LT.PlainNumber
	local _, length = frame.Timer:GetMinMaxValues()
	local left = PlainNumber(frame.Timer:GetValue())
	length = PlainNumber(length)
	if not (left and length) then return end
	return {
		ends = GetTime() + LT.RollSeconds(left, length),
		length = LT.RollSeconds(length, length),
		left = LT.RollSeconds(left, length),
	}
end

-- A roll button's PreClick, before RollOnLoot: notes the click as pending, with
-- the time left read now. On a roll with no confirmation the game cancels it
-- inside RollOnLoot and the bar hides (OnBarHide) before any post-hook runs.
local function OnRollPreClick(frame, button)
	local PlainNumber = LT.PlainNumber
	local rollID, rollType = PlainNumber(frame.rollID), PlainNumber(button:GetID())
	local choice = rollType and CHOICE_FOR_ROLL_TYPE[rollType]
	if not (rollID and choice and frame:IsShown()) then return end
	local timer = ReadTimer(frame)
	if not timer then
		if st.DEBUG then st:Debug('Loot', 'choice not pending:', rollID, 'the timer values are not plain') end
		return
	end
	timer.choice = choice
	pending[rollID] = timer
	clicking[button] = rollID
	if st.DEBUG then st:Debug('Loot', 'choice pending:', rollID, choice, 'seconds left', ('%.1f'):format(timer.left)) end
end

-- PostClick: the click is over, whatever the roll did.
local function OnRollPostClick(button)
	local rollID = clicking[button]
	clicking[button] = nil
	if rollID then pending[rollID] = nil end
end

-- After RollOnLoot (a roll button's OnClick, or an addon): notes your choice on
-- a roll a skinned bar still shows, with the time it has left. A roll whose bar
-- already went (a plain click: the game cancelled it inside the call) was held
-- at that hide. A click's choice is the one PreClick read, before the call (a
-- Need's dice animation, if it starts inside the call, zeroes the timer; it
-- probably comes after, from the server, and the code handles both); a direct
-- call's time is read here. A choice the game asks you to confirm
-- (CONFIRM_LOOT_ROLL, for a bind on pickup item) is noted at once; cancelling it
-- leaves the bar up, and the next choice replaces it.
local function OnRollChosen(rollID, rollType)
	local PlainNumber = LT.PlainNumber
	rollID, rollType = PlainNumber(rollID), PlainNumber(rollType)
	local choice = rollType and CHOICE_FOR_ROLL_TYPE[rollType]
	if not (rollID and choice) then
		if st.DEBUG then st:Debug('Loot', 'choice not noted: no plain roll ID or roll type', rollID, rollType) end
		return
	end
	local click = pending[rollID]
	if click and click.choice ~= choice then click = nil end
	if click and click.held then
		if st.DEBUG then st:Debug('Loot', 'choice held at the bar hiding:', rollID, choice) end
		return
	end
	local snapshot = hidden[rollID]
	if snapshot then
		-- The bar hid inside this call with no click behind it: held from what it
		-- showed then, with the choice the call names.
		hidden[rollID] = nil
		snapshot.roll.choice = choice
		LT:HoldRoll(snapshot.frame, snapshot.roll)
		return
	end
	for frame in pairs(bars) do
		if frame:IsShown() and PlainNumber(frame.rollID) == rollID then
			local noted = click or ReadTimer(frame)
			if noted then
				chosen[rollID] = { choice = choice, ends = noted.ends, length = noted.length }
				if st.DEBUG then st:Debug('Loot', 'choice noted:', rollID, choice, 'seconds left', ('%.1f'):format(noted.left)) end
			elseif st.DEBUG then
				st:Debug('Loot', 'choice not noted:', rollID, 'the timer values are not plain')
			end
			return
		end
	end
	if st.DEBUG then st:Debug('Loot', 'choice not noted:', rollID, 'no shown bar with that roll') end
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
	wipe(pending)
	wipe(hidden)
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
	-- The roll buttons are Blizzard's and not secure: native hooks only.
	local container = frame.LootButtonContainer or frame
	for _, name in ipairs({ 'Need', 'Greed', 'Transmog', 'Pass' }) do
		local button = container[name .. 'Button']
		if button and button.HookScript then
			button:HookScript('PreClick', function(self) OnRollPreClick(frame, self) end)
			button:HookScript('PostClick', OnRollPostClick)
		end
	end
	frame.IconFrame:HookScript('OnEnter', AddIconLines)
	frame.IconFrame:HookScript('OnUpdate', AddIconLines)
	self:SetRollTooltipScripts(self:GetRollInfoFrame(frame), InfoTooltip)

	-- A frame is skinned just after its first roll shows.
	self:UpdateRollBars()
end
