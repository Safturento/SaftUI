local st = SaftUI
local TR = st.Tracker

--[[
	The nearest quest item button and its key (design: "The nearest quest item
	button"): one bigger button for the quest item you most likely want, a
	SecureActionButtonTemplate button of SaftUI's, SaftUITrackerNearestItem, on its
	own holder (SaftUITrackerNearestHolder, its edit mode mover 'trackernearest'),
	not in the item layer. Off by default (items.nearest); shown only while it has
	an item and combat is not on. The game's rules for it are the item buttons'
	(items.lua, .agents/taint.md rules 6 and 15), kept like this:

	  - The holder is a plain frame made with the tracker, in combat too (a
	    /reload in combat). The button, a child of a state driver frame on the
	    holder (hiding it in a pet battle) and anchored to the holder, is made, sized, shown, hidden and given its attributes out of combat only,
	    the first time the setting is on; in combat the pass is queued as
	    'tracker_nearest' and one pass at the end of combat makes it right. A
	    holder with a secure child is protected, so it is placed through
	    st:SafeReposition (st:PlaceHolder).
	  - Which item it uses can only change out of combat, so in combat it is
	    frozen: it shows the item it had, and the key, which clicks the button,
	    uses that item and no other. If its quest's item goes meanwhile (the quest
	    is turned in, the item is used up) it dims to TR.DIM_ALPHA (never under
	    TR.BUTTON_MIN_ALPHA while it can be clicked) and its tooltip names the
	    quest it was; a new "nearest" waits for the end of combat. Alpha, the
	    count, the cooldown, the range tint and the key's text are drawn in combat
	    too (none of them an anchor, a size or an attribute).
	  - The key is the game's own binding, CLICK SaftUITrackerNearestItem:LeftButton
	    (Bindings.xml), not a SaftUI setting. SetBinding and SaveBindings are
	    blocked in combat, so TR:SetNearestKey queues them as 'tracker_binding'.
	    The button registers AnyUp and AnyDown (items.lua, NewButton), so a key
	    press uses the item once, on the press or the release as
	    ActionButtonUseKeyDown says.

	TR.ChooseNearest is the one function that decides which quest's item is
	"nearest" (in-game experiment P4).
]]

local PlainNumber = st.PlainNumber

TR.NEAREST_INTERVAL = 1

local function Exists(table, name)
	return type(table) == 'table' and type(table[name]) == 'function'
end

------------------------------------------------------------------ the choice

-- Which quest's item the nearest button offers (P4). candidates are the tracked
-- quests with an item that Blizzard's rule shows (QuestUtil.QuestShowsItemByIndex:
-- the model's quest.item), in the game's order, each { id, inArea, distanceSq,
-- onContinent, ... } (inArea true or nil, distanceSq a plain number or nil,
-- onContinent true or nil); focusedID is the focused (super tracked) quest's ID,
-- nil for none. It returns the chosen candidate, nil for none:
--   1. a quest whose area you're inside (the focused one if it is, else the first
--      in the game's order);
--   2. else the focused quest, if it is a candidate (it has an item);
--   3. else the one with the smallest distance, among those on your continent (a
--      quest with no distance counts as farthest, so it never beats one with one);
--   4. else the first in the game's order, which also decides ties.
-- If in-game experiment P4 finds that on Forever the distance or the area don't
-- answer, `geometry` is `not st.forever` and steps 1 and 3 are skipped there,
-- leaving the focus, then the game's order.
function TR.ChooseNearest(candidates, focusedID)
	local geometry = true
	local first = candidates[1]
	if not first then return nil end
	if geometry then
		local inside
		for _, candidate in ipairs(candidates) do
			if candidate.inArea == true then
				if candidate.id == focusedID then return candidate end
				inside = inside or candidate
			end
		end
		if inside then return inside end
	end
	if focusedID then
		for _, candidate in ipairs(candidates) do
			if candidate.id == focusedID then return candidate end
		end
	end
	if geometry then
		local nearest
		for _, candidate in ipairs(candidates) do
			if candidate.onContinent == true and candidate.distanceSq ~= nil
				and (nearest == nil or candidate.distanceSq < nearest.distanceSq) then
				nearest = candidate
			end
		end
		if nearest then return nearest end
	end
	return first
end

-- The candidates now, in the game's order, from the model's quests (what is
-- tracked and has an item) and a fresh read of the area and the distance, which
-- change as the player moves. Both reads are guarded by presence and the values
-- are plain or nothing (a secret one is missing). The list and its entries are
-- the same tables each call.
local function Candidates(self)
	local list = self.nearestCandidates
	if not list then
		list = {}
		self.nearestCandidates = list
	end
	local n = 0
	local insideKnown, distanceKnown = Exists(C_Minimap, 'IsInsideQuestBlob'), Exists(C_QuestLog, 'GetDistanceSqToQuest')
	for _, quest in ipairs(self.model.quests) do
		if quest.tracked and quest.item and quest.item.link then
			n = n + 1
			local candidate = list[n]
			if not candidate then
				candidate = {}
				list[n] = candidate
			end
			candidate.id, candidate.quest, candidate.title, candidate.item = quest.id, quest, quest.title, quest.item
			candidate.inArea = insideKnown and st.Plain(C_Minimap.IsInsideQuestBlob(quest.id)) == true or nil
			candidate.distanceSq, candidate.onContinent = nil, nil
			if distanceKnown then
				local distanceSq, onContinent = C_QuestLog.GetDistanceSqToQuest(quest.id)
				distanceSq = PlainNumber(distanceSq)
				if distanceSq then
					candidate.distanceSq = distanceSq
					candidate.onContinent = st.Plain(onContinent) == true or nil
				end
			end
		end
	end
	for index = n + 1, #list do list[index] = nil end
	return list
end

------------------------------------------------------------------ the key

-- The first key bound to the nearest button's command, nil for none (the Items
-- tab's Key row reads it; it is the game's binding, not a profile setting).
function TR.NearestKey()
	local key = GetBindingKey(TR.NEAREST_COMMAND)
	if key ~= nil and key ~= '' then return key end
	return nil
end

-- The key's text on the button: the Pixel font at the top right, drawn in combat
-- too (a font string of the button's child frame).
function TR:UpdateNearestKey()
	local button = self.nearestButton
	if not button then return end
	local key = TR.NearestKey()
	if key then
		-- The short form the action bars' hotkeys use (Core's st:ShortBindingKey).
		button.keyText:SetText(st:ShortBindingKey(key))
		if not button.keyText:IsShown() then button.keyText:Show() end
	elseif button.keyText:IsShown() then
		button.keyText:Hide()
	end
end

-- Binds key to the button, or clears the binding with '' (the Esc of the Key
-- row): the old keys are cleared first, then the key is bound and the bindings
-- saved, as Blizzard's own key bindings settings do
-- (Blizzard_Settings_Shared/Blizzard_Keybindings.lua). A key the game refuses
-- leaves the old ones bound. SetBinding and SaveBindings are blocked in combat,
-- so in combat the change waits for its end ('tracker_binding'; the last one
-- asked for is the one made). Like /sui kb (SaftUI-ActionBars/keybindmode.lua),
-- it tells the player in chat when the key was bound to another action ("(was
-- X)") and when the game refused it.
function TR:SetNearestKey(key)
	if st:QueueAfterCombat('tracker_binding', function() TR:SetNearestKey(key) end) then return end
	local old = { GetBindingKey(TR.NEAREST_COMMAND) }
	local binding = key ~= nil and key ~= ''
	local previous = binding and GetBindingAction(key) or nil
	local name = GetBindingName(TR.NEAREST_COMMAND)
	for _, oldKey in ipairs(old) do SetBinding(oldKey) end
	if binding then
		if SetBinding(key, TR.NEAREST_COMMAND) then
			if previous and previous ~= '' and previous ~= TR.NEAREST_COMMAND then
				st:Print(('%s bound to %s (was %s).'):format(GetBindingText(key), name, GetBindingName(previous)))
			else
				st:Print(('%s bound to %s.'):format(GetBindingText(key), name))
			end
		else
			for _, oldKey in ipairs(old) do SetBinding(oldKey, TR.NEAREST_COMMAND) end
			st:Print(("Can't bind %s to %s."):format(GetBindingText(key), name))
		end
	end
	SaveBindings(GetCurrentBindingSet())
	self:UpdateNearestKey()
end

------------------------------------------------------------------ the button

local function QueuedPass()
	TR:RefreshNearest()
end

-- The holder's size and place from the profile, whole pixels, through
-- st:SafeReposition: a holder with a secure child is protected, so in combat it
-- waits for the end of it.
function TR:PlaceNearest()
	local holder = self.nearestHolder
	if not holder then return end
	st:PlaceHolder(holder, 'tracker_nearest_holder',
		function()
			local size = TR.NearestSize(self)
			return size, size
		end,
		function() return TR.NearestPosition(self) end)
	st:KeepInScreenMargin(holder)
end

-- The holder's and the button's size, one whole-pixel number (the mover's
-- outline and the button never differ by a hair).
function TR.NearestSize(self)
	return st:RoundToPixel(self.config.items.nearest_size, self.nearestHolder)
end

-- Why the nearest holder may not be anchored to frame, or nil. A holder with a
-- secure child is protected, and protection spreads to the frames it is anchored
-- to, through the chain (.agents/taint.md rule 6), so it must never be anchored
-- to a frame the tracker sizes or moves in combat: the tracker's window, and
-- anything that moves with it (its scroll frame, content, rows and what hangs
-- from them). SaftUITrackerHolder is fine: it is placed through
-- st:SafeReposition and the window hangs from it, not the other way round.
function TR.NearestAnchorRefusal(frame)
	local window = TR.window
	if frame and window and st:MovesWith(frame, window) then
		return "The tracker's window changes size in combat, so the nearest button can't be attached to it or to anything in it. Attach it to SaftUITrackerHolder or UIParent."
	end
	-- Blizzard's tracker, which SaftUI's conceals off screen while it owns it (the
	-- button would go with it, and a protected tracker can't be revealed in combat).
	local blizzard = _G.ObjectiveTrackerFrame
	if frame and blizzard and TR:OwnsBlizzard() and st:MovesWith(frame, blizzard) then
		return "Blizzard's tracker is moved off screen while SaftUI's tracker is on, so the nearest button can't be attached to it or to anything on it. Attach it to SaftUITrackerHolder or UIParent."
	end
end

-- The saved position, with an anchor the rule above refuses (a profile or an
-- import can hold one) put on UIParent, the profile left as it is.
function TR.NearestPosition(self)
	local position = self.config.items.nearest_position
	if TR.NearestAnchorRefusal(st:ResolveFrame(position.frame)) then
		local copy = st.tablecopy(position, true)
		copy.frame = 'UIParent'
		return copy
	end
	return position
end

local function OnEnter(button)
	if not TR.config.quests.tooltips or not button.questID then return end
	GameTooltip:SetOwner(button, 'ANCHOR_LEFT')
	local index = TR.LogIndex(button.questID)
	if index then
		GameTooltip:SetQuestLogSpecialItem(index)
		if button.title then GameTooltip:AddLine(button.title, 1, 1, 1) end
	elseif button.title then
		-- The quest left the log with its button still on screen in combat: all
		-- there is to say is whose it was.
		GameTooltip:SetText(button.title, 1, 1, 1)
	else
		return
	end
	GameTooltip:Show()
end

local function OnLeave(button)
	if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
end

-- The nearest button's driver: the pet battle's part of the item driver
-- constant (TR.ITEM_DRIVER, items.lua) and nothing more, so a change to the
-- constant (a vehicle condition for the layer, say) never reaches it.
function TR.NearestDriver()
	return (TR.ITEM_DRIVER:match('%[petbattle%] hide') or TR.PET_BATTLE_HIDE) .. '; show'
end

-- Keeps its driver as TR.NearestDriver() says: set out of combat, else queued as
-- 'tracker_nearest' (the pass at the end of combat is TR:RefreshNearest).
function TR:SyncNearestDriver()
	local driver = self.nearestDriver
	if not driver then return end
	local want = TR.NearestDriver()
	if self.nearestDriverSet == want then return end
	if st:QueueAfterCombat('tracker_nearest', QueuedPass) then return end
	self.nearestDriverSet = want
	RegisterStateDriver(driver, 'visibility', want)
end

-- The button, made once, out of combat, the first time the setting is on (in
-- combat the pass is queued). Every region it can need is made here.
function TR:BuildNearestButton()
	if self.nearestButton then return self.nearestButton end
	if st:QueueAfterCombat('tracker_nearest', QueuedPass) then return nil end
	local holder = self.nearestHolder
	-- The button hides in a pet battle by the item layer's own mechanism: its
	-- parent is a SecureHandlerStateTemplate frame filling the holder under a
	-- visibility driver (TR.NearestDriver(): the pet battle's part and nothing
	-- else, set out of combat, here with the button), so the game hides and shows
	-- it with no addon Lua, in combat too. It is an action button: none of the
	-- tracker's triggers, Hide quest items with the tracker or the fade touch it
	-- (TR.Visibility.Driver is the layer's alone). The holder itself stays a plain
	-- frame for the mover.
	local driver = CreateFrame('Frame', st.name .. 'TrackerNearestDriver', holder, 'SecureHandlerStateTemplate')
	driver:SetAllPoints(holder)
	driver:EnableMouse(false)
	local want = TR.NearestDriver()
	RegisterStateDriver(driver, 'visibility', want)
	self.nearestDriverSet = want
	self.nearestDriver = driver
	local button = TR.NewItemButton(driver, st.name .. 'TrackerNearestItem')
	button:SetPoint('TOPLEFT', holder, 'TOPLEFT', 0, 0)
	-- Its key, top right, in the Pixel font.
	local text = button.over:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(st:GetFont('pixel'))
	text:SetJustifyH('RIGHT')
	text:SetPoint('TOPRIGHT', button.over, 'TOPRIGHT', -2, -2)
	text:Hide()
	button.keyText = text
	button:SetScript('OnEnter', function(self) OnEnter(self) end)
	button:SetScript('OnLeave', function(self) OnLeave(self) end)
	self.nearestButton = button
	self:UpdateNearestKey()
	return button
end

-- The range tint, read every TR.RANGE_INTERVAL while the button shows (the
-- row buttons' watcher does the same for theirs).
local function UpdateRange(self)
	local button = self.nearestButton
	if not (button and button.questID and self.config.items.range and button:IsShown()) then return end
	local range = TR.ReadItemRange(TR.LogIndex(button.questID))
	if range ~= button.range then
		button.range = range
		TR.PaintItemButton(button)
	end
end

local function OnUpdate(watcher, elapsed)
	watcher.rangeWaited = watcher.rangeWaited + elapsed
	watcher.waited = watcher.waited + elapsed
	if watcher.rangeWaited >= TR.RANGE_INTERVAL then
		watcher.rangeWaited = 0
		UpdateRange(TR)
	end
	-- Chosen again each second out of combat; in combat the choice is frozen, and
	-- the first tick after it chooses.
	if watcher.waited >= TR.NEAREST_INTERVAL and not InCombatLockdown() then
		watcher.waited = 0
		TR:RefreshNearest()
	end
end

-- The tick runs only while the button is on.
function TR:UpdateNearestWatch()
	local watcher = self.nearestWatcher
	if not watcher then return end
	if self.config.items.nearest then
		if not watcher:GetScript('OnUpdate') then
			watcher.waited, watcher.rangeWaited = 0, 0
			watcher:SetScript('OnUpdate', OnUpdate)
		end
	elseif watcher:GetScript('OnUpdate') then
		watcher:SetScript('OnUpdate', nil)
	end
end

-- Made with the tracker (TR:Build), so with the switch off nothing exists: the
-- holder, its mover and the watcher that hears the quest area and the bindings
-- and runs the tick. The holder is a plain frame, so this runs in combat too (a
-- /reload in combat); the button is made when the setting is first on.
function TR:BuildNearest()
	if self.nearestHolder then return end
	local holder = st:CreateFrame('Frame', st.name .. 'TrackerNearestHolder', UIParent)
	holder:SetFrameStrata('LOW')
	holder:SetFrameLevel(40)
	self.nearestHolder = holder

	local watcher = CreateFrame('Frame')
	watcher:SetScript('OnEvent', function(_, event, ...)
		if event == 'UPDATE_BINDINGS' then
			TR:UpdateNearestKey()
		else
			TR:OnNearestBlobChanged(...)
		end
	end)
	watcher:RegisterEvent('UPDATE_BINDINGS')
	if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED')) then
		watcher:RegisterEvent('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED')
	end
	self.nearestWatcher = watcher

	self:PlaceNearest()
	st:RegisterMover('trackernearest', {
		frame = holder,
		label = 'Nearest quest item',
		-- The placed position: a refused saved anchor reads as UIParent, so a drag
		-- starts from where the holder is and its commit heals the profile.
		getPosition = function() return TR.NearestPosition(self) end,
		setPosition = function(position) self.config.items.nearest_position = position end,
		apply = function() self:PlaceNearest() end,
		configPath = { 'Tracker', 'items' },
		module = 'Tracker',
		isDisabled = function() return not self.config.items.nearest end,
		-- On, but with nothing to show now.
		isHidden = function() return not (self.nearestButton and self.nearestButton.questID) end,
		getDefaultPosition = function() return st.tablecopy(st.defaults.tracker.items.nearest_position, true) end,
	})
	self:UpdateNearestWatch()
end

-- The player entered or left a quest's area: the button's border follows if it
-- is that quest's (a drawing, free in combat), and the choice is made again.
function TR:OnNearestBlobChanged(questID, inside)
	local button = self.nearestButton
	if button and questID ~= nil and button.questID == questID then
		button.inside = inside == true
		TR.PaintItemButton(button)
	end
	self:RefreshNearest()
end

-- BAG_UPDATE_COOLDOWN (init.lua): the cooldown is read again and drawn, in
-- combat too.
function TR:RefreshNearestCooldown()
	local button = self.nearestButton
	if button and button.questID and button.item and TR.ReadButtonCooldown(button, TR.LogIndex(button.questID)) then
		TR.PaintItemButton(button)
	end
end

-- A color change (a theme recolor, a Colors tab change): what the button colors
-- itself is put back.
function TR:ColorNearest()
	local button = self.nearestButton
	if not button then return end
	button.tint, button.countTint, button.borderInside = nil, nil, nil
	TR.PaintItemButton(button)
	button.keyText:SetTextColor(1, 1, 1)
end

------------------------------------------------------------------ the pass

-- In combat: nothing secure. The button stays as it was: it dims to DIM_ALPHA
-- when its quest's item is gone or another one now, and still uses the item it
-- shows; what a drawing may change (the count, the cooldown, the range) follows
-- the quest while its item is the same one.
local function DimNearest(self)
	local button = self.nearestButton
	if not (button and button.questID and button:IsShown()) then return end
	local quest
	for _, candidate in ipairs(self.model.quests) do
		if candidate.id == button.questID then
			quest = candidate
			break
		end
	end
	local item = quest and quest.tracked and quest.item
	local same = item and item.link ~= nil and item.link == (button.item and button.item.link)
	if same then
		button.item, button.title = item, quest.title
		-- (the cooldown and range are the button's own live reads: the watcher's
		-- range timer and BAG_UPDATE_COOLDOWN)
	end
	button.dimmed = not same
	self:SetItemAlpha(button, same and 1 or TR.DIM_ALPHA)
	TR.PaintItemButton(button)
end

-- Out of combat: nothing to offer, or the setting off. The button uses nothing
-- and is hidden.
local function ClearNearest(button)
	if button.questID == nil and not button:IsShown() and not (button.applied and next(button.applied)) then return end
	TR:SetButtonItem(button, nil)
	button.questID, button.item, button.title, button.cd, button.range, button.inside = nil, nil, nil, nil, nil, nil
	button.dimmed = false
	if button:IsShown() then button:Hide() end
end

-- Chooses the quest whose item the button offers and tells the button: every
-- second out of combat, on the quest events (the refresh runs it) and when the
-- player enters or leaves a quest's area. Frozen in combat (DimNearest) and
-- caught up when it ends. Does nothing with the switch off.
function TR:RefreshNearest()
	if not (self.built and self.nearestHolder and self.model) then return end
	self:UpdateNearestWatch()
	local config = self.config.items
	-- Off and no button made: nothing to keep right, so no queue and no dimming.
	if not config.nearest and not self.nearestButton then return end
	if st:QueueAfterCombat('tracker_nearest', QueuedPass) then
		DimNearest(self)
		return
	end
	self:SyncNearestDriver()
	if not config.nearest then
		if self.nearestButton then ClearNearest(self.nearestButton) end
		return
	end
	local button = self.nearestButton or self:BuildNearestButton()
	if not button then return end
	local chosen = TR.ChooseNearest(Candidates(self), self.model.focused)
	if not chosen then
		ClearNearest(button)
		return
	end
	local quest = chosen.quest
	if not self:SetButtonItem(button, quest.item) then return end
	button.questID, button.item, button.title = quest.id, quest.item, quest.title
	-- The cooldown and the range come from their own live reads, never from the
	-- model (read when the last quest or bag event came): the pass runs every
	-- second and must not put a stale tint or swipe back over what the button
	-- read itself.
	local index = TR.LogIndex(quest.id)
	TR.ReadButtonCooldown(button, index)
	button.range = TR.ReadItemRange(index)
	button.inside = chosen.inArea == true
	button.dimmed = false
	TR.StyleItemButton(button, st:ResolveTheme(self.config.theme, self.config.background, 'action'), TR.NearestSize(self))
	self:SetItemAlpha(button, 1)
	TR.PaintItemButton(button)
	if not button:IsShown() then button:Show() end
end
