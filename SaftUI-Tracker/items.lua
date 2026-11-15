local st = SaftUI
local TR = st.Tracker
local L = TR.LAYOUT

--[[
	The quest item layer and the item buttons in the rows (design: "Quest item
	buttons"). Each button is SaftUI's own SecureActionButtonTemplate button,
	because UseQuestLogSpecialItem is protected and only a secure button can
	call it for an addon. The game's rules for them (.agents/taint.md rule 6
	and 15), and how this file keeps them:

	  - Made, anchored, sized, shown, hidden and given attributes only out of
	    combat. TR:RefreshItems in combat only sets alpha and draws (alpha and
	    every child of a button are free), and queues itself as 'tracker_items',
	    so one pass at the end of combat makes everything right.
	  - Never a child of, or anchored to, a frame that must move in combat. The
	    layer (SaftUITrackerItems) fills UIParent and never moves; each button is a
	    child of it anchored by its TOPLEFT to UIParent's BOTTOMLEFT, at the
	    place of its row, worked out from the row's own rect (rows are plain
	    SaftUI frames, safe to read) out of combat. The window, the scroll frame
	    and the rows are never protected.
	  - Never invisible while clickable: a button is either hidden (out of
	    combat, by Hide) or at BUTTON_MIN_ALPHA or more.

	So in combat a button stays where it was, the rows move under it, and one
	whose row moved by more than MOVE_TOLERANCE or went dims to DIM_ALPHA and
	still uses its own quest's item. The list doesn't scroll in combat while a
	button sits in a row (TR:IsScrollLocked, window.lua), so scrolling never
	leaves a button behind a row; what the wheel can't do, a window that
	shrinks or a group that collapses can, and that is the dimming. A quest whose
	item has no button (it appeared in combat) shows a greyed icon in its row
	(rows.lua's slot) until combat ends.

	  TR.itemLayer      the layer, once made (out of combat)
	  TR.itemButtons    the pool, in the order made; never freed, at most
	                    TR.ItemPoolMax() (the log's most, read from the game)
	  TR.itemByQuest    questID -> its button, for the quests drawn in rows
	  TR.itemWatcher    a plain frame: the range timer (an OnUpdate, set only
	                    while a button shows) and the quest area's event

	The one function that holds how a button is told what to use is
	TR.ItemAttributes (experiment P3).
]]

local PlainNumber, PlainString = st.PlainNumber, st.PlainString

TR.BUTTON_MIN_ALPHA = 0.25
TR.DIM_ALPHA = 0.4
TR.MOVE_TOLERANCE = 2
TR.RANGE_INTERVAL = 0.2

-- The layer's visibility driver, until Task 12 builds it from the settings.
TR.ITEM_DRIVER = '[petbattle] hide; show'

-- The pool's cap: the log's most, read from the game (model.lua's TR.MaxQuests,
-- which falls back to TR.FALLBACK_MAX_QUESTS), never a literal.
function TR.ItemPoolMax()
	return TR.MaxQuests()
end

local function Round(value)
	return math.floor(value + 0.5)
end

local function Colors()
	return st.config.profile.colors
end

------------------------------------------------------------------ the pure parts

local Items = {}
TR.Items = Items

-- Where a row's button goes, as the offsets from UIParent's bottom left of its
-- top left corner: left, top (whole; round is the caller's rounding, a
-- physical pixel in the layer, a unit by default). Its top right corner is the
-- row's top right. nil while the button isn't wanted: no row (gone, hidden or
-- collapsed away: rowTop or rowRight nil) or the button's centre is outside
-- the scroll view (viewTop and viewBottom, the edges y up).
function Items.RowPlace(rowTop, rowRight, viewTop, viewBottom, size, round)
	if rowTop == nil or rowRight == nil or viewTop == nil or viewBottom == nil then return nil end
	round = round or Round
	local left, top = round(rowRight - size), round(rowTop)
	local centre = top - size / 2
	if centre > viewTop or centre < viewBottom then return nil end
	return left, top
end

-- What a button in combat is drawn at: DIM_ALPHA when its row is gone or has
-- moved more than MOVE_TOLERANCE from where the button was placed, else 1.
function Items.CombatAlpha(placedTop, rowTop)
	if placedTop == nil or rowTop == nil then return TR.DIM_ALPHA end
	if math.abs(rowTop - placedTop) > TR.MOVE_TOLERANCE then return TR.DIM_ALPHA end
	return 1
end

------------------------------------------------------------------ P3: what a button uses

-- The attributes a button is given for an item (P3: how a quest item button is
-- told what to use). Type item with the item's link, which keeps a button right
-- when the log's indexes shift. If the experiment fails this returns
-- { type = 'macro', macrotext = '/use item:' .. id } and nothing else changes.
-- An item with no link gives no attributes.
function TR.ItemAttributes(item)
	if not item or not item.link then return {} end
	return { type = 'item', item = item.link }
end

-- Every attribute any form of TR.ItemAttributes has named: a button gives up
-- the ones the new table doesn't name.
local KNOWN_ATTRIBUTES = { 'type', 'item', 'macrotext', 'macro', 'spell' }

-- Tells a button what to use: the attributes TR.ItemAttributes gives, and none
-- of the others. A secure call, so false in combat with nothing changed.
function TR:SetButtonItem(button, item)
	if InCombatLockdown() then return false end
	-- The same item through the same seam: nothing to tell it (a scroll or a
	-- refresh that changed nothing makes no table and no call).
	if button.applied and button.appliedLink == (item and item.link) and button.appliedFn == TR.ItemAttributes then
		return true
	end
	local attributes = TR.ItemAttributes(item) or {}
	local applied = button.applied or {}
	for key in pairs(applied) do
		if attributes[key] == nil then button:SetAttribute(key, nil) end
	end
	for _, key in ipairs(KNOWN_ATTRIBUTES) do
		if attributes[key] == nil and applied[key] == nil and button:GetAttribute(key) ~= nil then
			button:SetAttribute(key, nil)
		end
	end
	local now = {}
	for key, value in pairs(attributes) do
		now[key] = value
		if applied[key] ~= value then button:SetAttribute(key, value) end
	end
	button.applied = now
	button.appliedLink, button.appliedFn = item and item.link, TR.ItemAttributes
	return true
end

------------------------------------------------------------------ reads

-- The quest's index in the log now, or nil.
local function LogIndex(questID)
	if questID == nil or type(C_QuestLog) ~= 'table' or type(C_QuestLog.GetLogIndexForQuestID) ~= 'function' then return nil end
	local index = PlainNumber(C_QuestLog.GetLogIndexForQuestID(questID))
	if index and index > 0 then return index end
end

-- { start, duration, enable } of the quest item's cooldown, or nil.
local function ReadCooldown(index)
	if not index or type(GetQuestLogSpecialItemCooldown) ~= 'function' then return nil end
	local start, duration, enable = GetQuestLogSpecialItemCooldown(index)
	start, duration, enable = PlainNumber(start), PlainNumber(duration), PlainNumber(enable)
	if start and duration then return { start = start, duration = duration, enable = enable } end
end

-- 0 out of range, 1 in range, nil where the item has no range.
local function ReadRange(index)
	if not index or type(IsQuestLogSpecialItemInRange) ~= 'function' then return nil end
	return PlainNumber(IsQuestLogSpecialItemInRange(index))
end

local function ReadInside(questID)
	if type(C_Minimap) ~= 'table' or type(C_Minimap.IsInsideQuestBlob) ~= 'function' then return false end
	return C_Minimap.IsInsideQuestBlob(questID) == true
end

------------------------------------------------------------------ drawing a button

-- Alpha is free in combat, but never under BUTTON_MIN_ALPHA (a button at 0
-- still takes clicks). Everything that sets a button's alpha goes through this.
function TR:SetItemAlpha(button, alpha)
	alpha = math.max(alpha, TR.BUTTON_MIN_ALPHA)
	if button.alphaSet ~= alpha then
		button.alphaSet = alpha
		button:SetAlpha(alpha)
	end
end

-- The cooldown as Blizzard's CooldownFrame_Set draws it (its start, duration and
-- enable), and the icon dimmed while it waits for the item's effect (a
-- duration with enable 0), as QuestObjectiveItemButtonMixin:UpdateCooldown does.
local function DrawCooldown(button)
	local cd = button.cd
	local shown = TR.config.items.cooldown and cd and cd.duration > 0 and (cd.enable or 1) ~= 0 and cd.start > 0
	if shown then
		if button.cdStart ~= cd.start or button.cdDuration ~= cd.duration then
			button.cdStart, button.cdDuration = cd.start, cd.duration
			button.cooldown:SetCooldown(cd.start, cd.duration)
		end
	elseif button.cdStart ~= nil then
		button.cdStart, button.cdDuration = nil, nil
		button.cooldown:Clear()
	end
end

-- Everything a button draws from its state, none of it secure, so it runs in
-- combat too: the icon and its tint (red out of range, dim while waiting),
-- the count, the cooldown, the accent border inside the quest's area.
local function PaintButton(button)
	local config = TR.config.items
	local item = button.item
	if item and button.shownTexture ~= item.texture then
		button.shownTexture = item.texture
		button.icon:SetTexture(item.texture)
	end
	DrawCooldown(button)

	local out = config.range and button.range == 0
	local waiting = button.cd and button.cd.duration > 0 and button.cd.enable == 0
	local tint = 'white'
	if out then tint = 'red' elseif waiting then tint = 'dim' end
	if button.tint ~= tint then
		button.tint = tint
		if tint == 'red' then
			button.icon:SetVertexColor(Colors().text.red:GetRGB())
		elseif tint == 'dim' then
			button.icon:SetVertexColor(0.4, 0.4, 0.4)
		else
			button.icon:SetVertexColor(1, 1, 1)
		end
		button.countTint = nil
	end
	local charges = item and item.charges
	local showCount = config.count and charges and charges > 1
	if showCount then
		local text = tostring(charges)
		if button.countText ~= text then
			button.countText = text
			button.count:SetText(text)
		end
	end
	if button.countShown ~= (showCount and true or false) then
		button.countShown = showCount and true or false
		button.count:SetShown(button.countShown)
	end
	if button.countTint ~= out then
		button.countTint = out
		if out then
			button.count:SetTextColor(Colors().text.red:GetRGB())
		else
			button.count:SetTextColor(1, 1, 1)
		end
	end

	-- The border is only drawn again when it changes: under the Blizzard theme
	-- it is a piece made when the button was styled (out of combat), only shown,
	-- hidden and colored here.
	if button.backdrop and button.borderInside ~= (button.inside and true or false) then
		button.borderInside = button.inside and true or false
		if button.inside then
			st:SetBorderColor(button.backdrop, Colors().button.blue:GetRGB())
		else
			st:SetBorderColor(button.backdrop)
		end
	end
end

-- The button's size, backdrop and icon from the profile: SaftUI's backdrop drawn
-- as kind 'action' in the tracker's Theme and Background, the icon inside it
-- and cropped by Icon zoom. A secure call (the size), so out of combat only;
-- put off to the end of combat otherwise. What was drawn is remembered as the
-- look that resolved (look is st:ResolveTheme's, nil for None), not the
-- setting's name: a change of SaftUI's theme, which the tracker follows, changes
-- the look and so the icon's inset. Every region the button can need is made
-- here: the Blizzard theme's art goes on a frame of SaftUI's, not on the secure
-- button (st:MarkForeign, MakeButton), and the quest-area border's piece is
-- made now, by coloring the border and putting it back, so in combat it is only
-- shown, hidden and colored.
local function StyleButton(button, look)
	local config = TR.config
	local size = config.items.size
	local trim = st.config.profile.misc.icon_trim
	local name = look and look.name
	if button.styleName == name and button.styleSize == size and button.styleTrim == trim
		and button.styleTheme == config.theme and button.styleBackground == config.background then
		return
	end
	button.styleName, button.styleSize, button.styleTrim = name, size, trim
	button.styleTheme, button.styleBackground = config.theme, config.background
	if button.sizeSet ~= size then
		button.sizeSet = size
		button:SetSize(size, size)
	end
	st:SetBackdrop(button, config.theme, config.background, 'action')
	if button.backdrop then
		button.backdrop:ClearAllPoints()
		button.backdrop:SetAllPoints(button)
		st:SetBorderColor(button.backdrop, Colors().button.blue:GetRGB())
		st:SetBorderColor(button.backdrop)
	end
	local inset = st:ThemeInset(config.theme, config.background, 'action') or 0
	local icon = button.icon
	icon:ClearAllPoints()
	st:SetInside(icon, inset)
	icon:SetTexCoord(st:IconTexCoords(trim, size - 2 * inset, size - 2 * inset))
	button.tint, button.countTint, button.borderInside = nil, nil, nil
end

------------------------------------------------------------------ tooltips

-- The tooltip's place: its top right 8 left of the row's top left (Ruling 30).
local function PlaceTip(owner, row)
	GameTooltip:SetOwner(owner, 'ANCHOR_NONE')
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', row or TR.window, 'TOPLEFT', -L.PAD, 0)
end

-- The game's tooltip for the quest's item, with the quest's title under it while
-- the button is dimmed (it names the quest the button belongs to). Obeys the
-- Tooltips setting.
function TR:ShowItemTooltip(owner, questID, title, dimmed)
	if not self.config.quests.tooltips then return end
	local index = LogIndex(questID)
	PlaceTip(owner, self:GetQuestRow(questID))
	if index then
		GameTooltip:SetQuestLogSpecialItem(index)
		if dimmed and title then GameTooltip:AddLine(title, 1, 1, 1) end
	elseif title then
		-- The quest left the log with its button still on screen in combat: all
		-- there is to say is whose it was.
		GameTooltip:SetText(title, 1, 1, 1)
	else
		return
	end
	GameTooltip:Show()
end

-- The tooltip of a row's slot: a greyed icon says its button comes when combat
-- ends; a plain icon is the game's own item tooltip.
function TR:ShowSlotTooltip(slot, row)
	local quest = row.quest
	if not quest or not self.config.quests.tooltips then return end
	if slot.mode == 'greyed' then
		PlaceTip(slot, row)
		GameTooltip:AddLine(quest.title, 1, 1, 1)
		local r, g, b = Colors().text.grey:GetRGB()
		GameTooltip:AddLine('Its button comes when combat ends.', r, g, b, true)
		GameTooltip:Show()
	else
		self:ShowItemTooltip(slot, quest.id)
	end
end

------------------------------------------------------------------ the layer and the pool

-- The layer: a SecureHandlerStateTemplate frame on UIParent that fills it and
-- takes no mouse, under a visibility driver (which shows and hides every
-- button with it, in combat too, with no addon code). Out of combat only; in
-- combat the pass that makes it is queued as 'tracker_items'. Made once.
-- The pass queued for the end of combat (one function, so queuing it makes no
-- closure).
local function QueuedPass()
	TR:RefreshItems()
end

function TR:BuildItemLayer()
	if self.itemLayer then return self.itemLayer end
	if st:QueueAfterCombat('tracker_items', QueuedPass) then return nil end
	local layer = CreateFrame('Frame', st.name .. 'TrackerItems', UIParent, 'SecureHandlerStateTemplate')
	layer:SetFrameStrata('LOW')
	layer:SetFrameLevel(30)
	layer:SetAllPoints(UIParent)
	layer:EnableMouse(false)
	-- The driver comes from Task 12's settings; until then a pet battle hides it.
	RegisterStateDriver(layer, 'visibility', TR.ITEM_DRIVER)
	self.itemLayer = layer
	return layer
end

local function MakeButton(self)
	local index = #self.itemButtons + 1
	local button = CreateFrame('Button', st.name .. 'TrackerItem' .. index, self.itemLayer, 'SecureActionButtonTemplate')
	-- AnyUp and AnyDown, as SaftUI's own secure buttons register
	-- (SaftUI-ActionBars/buttons.lua) and LibActionButton-1.0 does: an addon's
	-- secure action button gets no isKeyPress or isSecureAction from the game
	-- (SecureTemplates.xml), so SecureActionButton_OnClick acts on the press when
	-- ActionButtonUseKeyDown is on (its default) and on the release when off. A
	-- button registered for AnyUp alone would never act with the setting on.
	button:RegisterForClicks('AnyUp', 'AnyDown')
	button:Hide()
	-- The Blizzard theme draws a button's ring and its own-color piece as textures
	-- of the button it sits behind, which for a secure button would be regions of a
	-- protected frame: made, anchored and sized only out of combat. Marked foreign,
	-- the pieces go on a frame of SaftUI's under the backdrop instead
	-- (.agents/taint.md rule 15).
	st:MarkForeign(button)

	button.icon = button:CreateTexture(nil, 'ARTWORK')
	button.hover = button:CreateTexture(nil, 'HIGHLIGHT')
	button.hover:SetAllPoints(button.icon)
	self:NewAccent(button.hover, 0.4)

	-- The levels are ordered on purpose: the cooldown at the button's own level,
	-- the Blizzard theme's ring (a holder frame one over the backdrop's and the
	-- button's, so one level up) over the swipe, and the count on a frame over
	-- that, two up.
	button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.cooldown:SetAllPoints(button.icon)
	button.cooldown:SetFrameLevel(button:GetFrameLevel())
	local over = CreateFrame('Frame', nil, button)
	over:SetAllPoints(button)
	over:SetFrameLevel(button:GetFrameLevel() + 2)
	button.count = over:CreateFontString(nil, 'OVERLAY')
	button.count:SetFontObject(st:GetFont('pixel'))
	button.count:SetJustifyH('RIGHT')
	button.count:SetPoint('BOTTOMRIGHT', over, 'BOTTOMRIGHT', -2, 2)
	button.count:Hide()

	-- The button takes the mouse from its row, so it keeps the row's hover too.
	button:SetScript('OnEnter', function(self)
		local row = self.questID and TR:GetQuestRow(self.questID)
		if row then TR:HoverRow(row, true) end
		TR:ShowItemTooltip(self, self.questID, self.title, self.dimmed)
	end)
	button:SetScript('OnLeave', function(self)
		local row = self.questID and TR:GetQuestRow(self.questID)
		if row then TR:HoverRow(row, false) end
		if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
	self.itemButtons[index] = button
	return button
end

-- The button a quest's row has now, or nil (none made for it, or in combat).
function TR:GetItemButton(questID)
	return self.itemByQuest and self.itemByQuest[questID] or nil
end

------------------------------------------------------------------ building

-- The parts of the item layer that are not secure, made with the tracker: the
-- pool's tables and the watcher frame, which fills UIParent so a change of the
-- screen's size or the UI scale (the window hangs from one corner, the buttons
-- from another) places the buttons again, hears the quest-area event, and runs
-- the range timer. Edit mode's drag moves the holder every frame without a
-- refresh: a hook on the holder's SetPoint places them again (edit mode is never
-- open in combat). Called by TR:Build, so with the switch off nothing exists. The
-- layer and the buttons are made by the first pass out of combat.
function TR:BuildItems()
	self.itemButtons, self.itemByQuest, self.itemWanted = {}, {}, {}
	local watcher = CreateFrame('Frame', nil, UIParent)
	watcher:SetAllPoints(UIParent)
	watcher.waited = 0
	watcher:SetScript('OnEvent', function(_, event, ...)
		if event == 'PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED' then TR:OnBlobChanged(...) end
	end)
	watcher:SetScript('OnSizeChanged', function() TR:PlaceItems() end)
	if not (C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED')) then
		watcher:RegisterEvent('PLAYER_INSIDE_QUEST_BLOB_STATE_CHANGED')
	end
	self.itemWatcher = watcher
	-- Edit mode's drag sets the holder's point every frame (its 'PositionChanged'
	-- only comes every 0.1 s): a post-hook on SaftUI's own holder follows it.
	hooksecurefunc(self.holder, 'SetPoint', function() TR:PlaceItems() end)
end

-- The game says the player is inside a quest's area, or left it.
function TR:OnBlobChanged(questID, inside)
	if not self.itemButtons then return end
	local button = self.itemByQuest[questID]
	if button then
		button.inside = inside == true
		PaintButton(button)
	end
end

-- The range timer: one OnUpdate, set only while a button shows and Out of range
-- in red is on. Every RANGE_INTERVAL it reads each shown button's range.
local function OnRangeUpdate(watcher, elapsed)
	watcher.waited = watcher.waited + elapsed
	if watcher.waited < TR.RANGE_INTERVAL then return end
	watcher.waited = 0
	for _, button in ipairs(TR.itemButtons) do
		if button.questID and button:IsShown() then
			local range = ReadRange(LogIndex(button.questID))
			if range ~= button.range then
				button.range = range
				PaintButton(button)
			end
		end
	end
end

function TR:UpdateRangeWatch()
	local watcher = self.itemWatcher
	if not watcher then return end
	local needed = false
	if self.config.items.range then
		for _, button in ipairs(self.itemButtons) do
			if button.questID and button:IsShown() then
				needed = true
				break
			end
		end
	end
	if needed then
		if not watcher:GetScript('OnUpdate') then
			watcher.waited = 0
			watcher:SetScript('OnUpdate', OnRangeUpdate)
		end
	elseif watcher:GetScript('OnUpdate') then
		watcher:SetScript('OnUpdate', nil)
	end
end

-- BAG_UPDATE_COOLDOWN: each assigned button's cooldown is read again and drawn,
-- with no refresh (init.lua calls this for the event). A drawing, so in combat
-- too.
function TR:RefreshCooldowns()
	if not self.itemButtons then return end
	for _, button in ipairs(self.itemButtons) do
		if button.questID and button.item then
			button.cd = ReadCooldown(LogIndex(button.questID))
			PaintButton(button)
		end
	end
end

-- A color change (a theme recolor, a Colors tab change): what the buttons color
-- themselves is put back. The hover is one of the rows' accents, painted by
-- TR:ColorRows.
function TR:ColorItems()
	if not self.itemButtons then return end
	for _, button in ipairs(self.itemButtons) do
		button.tint, button.countTint, button.borderInside = nil, nil, nil
		PaintButton(button)
	end
end

------------------------------------------------------------------ the pass

-- Whether there is an item for the handover to leave buttons for: the placement
-- is In the row or Beside the tracker, and a quest has an item.
function TR:ItemsToShow()
	if not self.built or not self.model then return false end
	local placement = self.config.items.placement
	if placement ~= 'row' and placement ~= 'beside' then return false end
	for _, quest in ipairs(self.model.quests) do
		if quest.item then return true end
	end
	return false
end

-- Whether any button sits in a row (shown), which is what holds the list still
-- in combat (TR:IsScrollLocked, window.lua).
function TR:RowButtonShown()
	for _, button in ipairs(self.itemButtons or {}) do
		if button.questID and button:IsShown() then return true end
	end
	return false
end

-- The quests the layer draws in rows, in the list's order: each quest with an
-- item and a row, as { quest, row }.
local NONE = {}

local function Wanted(self)
	local wanted = self.itemWanted
	local n = 0
	for _, quest in ipairs(self.model.quests) do
		local row = quest.item and self:GetQuestRow(quest.id)
		if row and row.item == 'row' then
			n = n + 1
			local entry = wanted[n]
			if not entry then
				entry = {}
				wanted[n] = entry
			end
			entry.quest, entry.row = quest, row
		end
	end
	for index = n + 1, #wanted do wanted[index] = nil end
	return wanted
end

-- The rounding of the layer's offsets: a physical pixel (one function, so no
-- closure is made per pass).
local function RoundToPixel(value)
	return st:RoundToPixel(value, UIParent)
end

-- The offsets of a row's button, in the layer's pixels, or nil while it isn't
-- wanted there.
local function Place(self, row, size)
	if not row or not row:IsVisible() then return nil end
	return Items.RowPlace(row:GetTop(), row:GetRight(), self.scroll:GetTop(), self.scroll:GetBottom(), size, RoundToPixel)
end

-- Puts a button at its row's place, or hides it while the row is out of view,
-- collapsed or gone. Secure calls, so out of combat only, and only on a change.
local function PlaceButton(self, button, row, size)
	local left, top = Place(self, row, size)
	if left then
		if button.placedLeft ~= left or button.placedTop ~= top then
			button.placedLeft, button.placedTop = left, top
			button:ClearAllPoints()
			button:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', left, top)
		end
		button.dimmed = false
		self:SetItemAlpha(button, 1)
		PaintButton(button)
		if not button:IsShown() then button:Show() end
	elseif button:IsShown() then
		button:Hide()
	end
end

-- Out of combat: the pool is handed out and each button told its item, set up
-- and placed at its row. Buttons are made on need, up to the cap. This is the
-- refresh's, not a scroll's: it tells buttons their items and styles them.
local function AssignItems(self, wanted)
	local config = self.config
	local byQuest = self.itemByQuest
	local row = config.items.placement == 'row'
	if row and not self.itemLayer then self:BuildItemLayer() end
	if not (row and self.itemLayer) then
		-- Off, or the layer can't be made now: nothing is wanted of a button.
		wanted = NONE
	end

	for questID, button in pairs(byQuest) do
		local kept = false
		for _, entry in ipairs(wanted) do
			if entry.quest.id == questID then kept = true; break end
		end
		if not kept then
			byQuest[questID] = nil
			button.questID, button.item, button.range, button.cd, button.inside = nil, nil, nil, nil, nil
		end
	end

	local look = st:ResolveTheme(config.theme, config.background, 'action')
	local size = config.items.size
	for _, entry in ipairs(wanted) do
		local quest = entry.quest
		local button = byQuest[quest.id]
		if not button and quest.item.link then
			for _, spare in ipairs(self.itemButtons) do
				if not spare.questID then button = spare; break end
			end
			if not button and #self.itemButtons < TR.ItemPoolMax() then button = MakeButton(self) end
			if button then
				byQuest[quest.id] = button
				button.questID = quest.id
			end
		end
		if button and self:SetButtonItem(button, quest.item) then
			button.item, button.title = quest.item, quest.title
			button.cd, button.range = quest.item.cooldown, quest.item.range
			button.inside = ReadInside(quest.id)
			StyleButton(button, look)
			PlaceButton(self, button, entry.row, size)
		end
	end
	-- Spare buttons go.
	for _, button in ipairs(self.itemButtons) do
		if not button.questID and button:IsShown() then button:Hide() end
	end
end

-- In combat: nothing secure. A button stays where it was; it dims to DIM_ALPHA
-- when its row moved by more than MOVE_TOLERANCE, is out of view or is gone, or
-- its quest's item is another one now, and goes on using its own quest's item.
-- What a drawing may change (the count, the cooldown) follows the quest while its
-- item is the same one.
local function DimItems(self)
	local size = self.config.items.size
	for _, button in ipairs(self.itemButtons) do
		if button.questID and button:IsShown() then
			local row = self:GetQuestRow(button.questID)
			local quest = row and row.quest
			local item = quest and quest.item
			local rowTop
			if item and row.item == 'row' and item.link == (button.item and button.item.link) then
				local _, top = Place(self, row, button.sizeSet or size)
				rowTop = top
				button.item, button.title = item, quest.title
				button.cd, button.range = item.cooldown, item.range
			end
			local alpha = Items.CombatAlpha(button.placedTop, rowTop)
			button.dimmed = alpha < 1
			self:SetItemAlpha(button, alpha)
			PaintButton(button)
		end
	end
end

-- Whether a button could still be had for a quest's item: it has a link, and
-- the pool is not full of buttons for other quests.
local function CanHaveButton(self, item)
	if not item.link then return false end
	if #self.itemButtons < TR.ItemPoolMax() then return true end
	for _, button in ipairs(self.itemButtons) do
		if not button.questID then return true end
	end
	return false
end

-- Each quest row's item slot (rows.lua): hidden where the quest's own button
-- sits shown (dimmed and displaced or not: it is that quest's), a greyed icon in
-- combat where the quest has none and one can still come, a plain icon
-- otherwise (Item buttons Off, or no button to be had: no link, the pool full).
local function DrawSlots(self, combat)
	local placement = self.config.items.placement
	for _, row in ipairs(self.pools.quest.rows) do
		if row.inUse and row.item == 'row' then
			local button = self.itemByQuest[row.questID]
			local item = row.quest and row.quest.item
			local mode
			if placement == 'off' then
				mode = 'icon'
			elseif button and button:IsShown() and item and button.item and button.item.link == item.link then
				mode = 'none'
			elseif combat and item and CanHaveButton(self, item) then
				mode = 'greyed'
			else
				mode = 'icon'
			end
			self:SetSlotMode(row, mode)
		end
	end
end

-- The item stage of the refresh (init.lua's RunStages) and of the end of combat.
-- Out of combat it hands out the pool, sets, places, shows and hides the
-- buttons; in combat it only dims and draws, and queues itself for the end of
-- the fight. Nothing runs with the switch off.
function TR:RefreshItems()
	if not self.built or not self.model or not self.itemButtons then return end
	local combat = InCombatLockdown()
	local wanted = Wanted(self)
	if combat then
		st:QueueAfterCombat('tracker_items', QueuedPass)
		DimItems(self)
	else
		AssignItems(self, wanted)
	end
	DrawSlots(self, combat)
	self:UpdateScrollLock()
	self:UpdateRangeWatch()
end

-- The rows moved without a refresh (a scroll, the window collapsing, hiding or
-- being moved, the screen changing size, an edit mode drag): out of combat the
-- buttons follow them, in combat they dim. Only places: it tells no button its
-- item and styles none (the refresh does), so a thumb drag's scroll events cost
-- a few reads and no allocation.
function TR:PlaceItems()
	if not self.built or not self.model or not self.itemButtons then return end
	local combat = InCombatLockdown()
	if combat then
		DimItems(self)
	else
		local size = self.config.items.size
		for _, button in ipairs(self.itemButtons) do
			if button.questID then PlaceButton(self, button, self:GetQuestRow(button.questID), size) end
		end
	end
	DrawSlots(self, combat)
	self:UpdateScrollLock()
	self:UpdateRangeWatch()
end
