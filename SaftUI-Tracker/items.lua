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

	Beside the tracker (placement 'beside') the same buttons sit in a column
	4 outside the window, on the side nearer the screen's middle, each level
	with its quest's title, and numbered 1 to n in list order (the pure
	Items.Side and Items.Column). A column button is as secure as a row's, and
	in combat it follows the same rules, except for what the list does: the
	list scrolls freely, the column stays as it was (a button is not tied to its
	row, the number is), and a button dims only when its quest left the list or
	its item changed. The numbers are only set out of combat, so a button, its
	number and its row's tag always name the same quest.

	The one function that holds how a button is told what to use is
	TR.ItemAttributes (experiment P3).
]]

local PlainNumber, PlainString = st.PlainNumber, st.PlainString

TR.BUTTON_MIN_ALPHA = 0.25
TR.DIM_ALPHA = 0.4
TR.MOVE_TOLERANCE = 2
TR.RANGE_INTERVAL = 0.2

-- The pet battle's part of every visibility driver, and the nearest button's own
-- driver (nearest.lua: an action button, never touched by a trigger, Hide quest
-- items or the fade). The layer's driver is built from the settings
-- (TR.Visibility.Driver, visibility.lua) and starts with the same part.
TR.PET_BATTLE_HIDE = '[petbattle] hide'
TR.ITEM_DRIVER = TR.PET_BATTLE_HIDE .. '; show'

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

-- Which side of the tracker the column is on: left when the holder's centre is
-- right of the screen's middle, else right (the beside spot's rule).
function Items.Side(holderCenterX, screenCenterX)
	if holderCenterX > screenCenterX then return 'left' end
	return 'right'
end

-- Where each column button goes, as { left, top, number } or nil, one for each
-- entry in list order. Each entry is { top = the title's top or nil }, y up (nil:
-- no row to follow: collapsed, hidden or gone). left is 4 outside the window on
-- side ('left' or 'right'); top is the title's, or 2 under the place above when
-- it would be closer than 2 to it; nil while the title's button would have its
-- centre outside the scroll view (viewTop and viewBottom), and for a button that
-- stacking pushed so far down that its centre is under the view's bottom (the
-- column never runs past the window). Numbers run 1 to n in list
-- order, counting the entries out of view, so a number never changes as the list
-- scrolls. round is the caller's rounding (default a unit), out a table of an
-- earlier call to fill again, so a scroll makes none.
function Items.Column(entries, size, side, windowLeft, windowRight, viewTop, viewBottom, round, out)
	round = round or Round
	local places = out or {}
	local spare = places.spare
	if not spare then
		spare = {}
		places.spare = spare
	end
	local left
	if side == 'left' then
		left = round(windowLeft - L.COLUMN_GAP - size)
	else
		left = round(windowRight + L.COLUMN_GAP)
	end
	local count = #entries
	local bottom -- the bottom of the place above, once there is one
	for index = 1, count do
		local top = entries[index].top
		local place
		if top ~= nil and viewTop ~= nil and viewBottom ~= nil then
			local centre = top - size / 2
			if centre <= viewTop and centre >= viewBottom then
				top = round(top)
				if bottom ~= nil and top > bottom - L.COLUMN_STACK then top = bottom - L.COLUMN_STACK end
				bottom = top - size
				-- A stack that ran on past the view's bottom has no room for this button:
				-- it hides (it would hang under the window), and so does what follows.
				if top - size / 2 >= viewBottom then
					place = spare[index]
					if not place then
						place = {}
						spare[index] = place
					end
					place.left, place.top, place.number = left, top, index
				end
			end
		end
		places[index] = place
	end
	for index = count + 1, places.count or 0 do places[index] = nil end
	places.count = count
	return places
end

-- The room the column takes beside the tracker, for the beside spot of Blizzard's
-- tracker (TR:BlizzardTarget): Button size while the column shows, else 0. Its 4
-- gap is the caller's. Out of combat it is what the list draws (the placement is
-- Beside the tracker, the list is open, and a quest it draws has an item with a
-- link: a collapsed group's quest has no row and so no button). In combat it is
-- the column as it was placed: the buttons can't move or hide then, and a button
-- whose quest left still takes clicks, so Blizzard's tracker must stay clear of
-- every one that shows, whatever the list is now.
function TR:ColumnWidth()
	if self.config.items.placement ~= 'beside' then return 0 end
	if InCombatLockdown() then
		for _, button in ipairs(self.itemButtons or {}) do
			if button.column and button.questID and button:IsShown() then return self.config.items.size end
		end
		return 0
	end
	return self:ItemsToShow() and self.config.items.size or 0
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
-- `alpha` is what the button is for (1, or DIM_ALPHA when its row moved); a pool
-- button (button.fades) wears the tracker's fade on top, Hide quest items with
-- the tracker on (TR.itemFade, visibility.lua; 1 while it is off), and the floor
-- holds for the result. The nearest button never fades: it is its own.
function TR:SetItemAlpha(button, alpha)
	button.baseAlpha = alpha
	if button.fades then alpha = alpha * (self.itemFade or 1) end
	alpha = math.max(alpha, TR.BUTTON_MIN_ALPHA)
	if button.alphaSet ~= alpha then
		button.alphaSet = alpha
		button:SetAlpha(alpha)
	end
end

-- The fade changed: every pool button's alpha is worked out again from what it
-- is for. Alpha only, so it runs in combat, and it allocates nothing.
function TR:RefreshItemAlpha()
	local buttons = self.itemButtons
	if not buttons then return end
	for index = 1, #buttons do
		local button = buttons[index]
		if button.baseAlpha then self:SetItemAlpha(button, button.baseAlpha) end
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
local function StyleButton(button, look, size)
	local config = TR.config
	size = size or config.items.size
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

-- The tooltip's place: its top right 8 left of the row's top left (Ruling 30); a
-- column button's is 8 outside the column, away from the window.
local function PlaceTip(owner, row)
	GameTooltip:SetOwner(owner, 'ANCHOR_NONE')
	GameTooltip:ClearAllPoints()
	if owner.column then
		-- A column button's tooltip goes outward from the column, off the window.
		if owner.columnSide == 'right' then
			GameTooltip:SetPoint('TOPLEFT', owner, 'TOPRIGHT', L.PAD, 0)
		else
			GameTooltip:SetPoint('TOPRIGHT', owner, 'TOPLEFT', -L.PAD, 0)
		end
		return
	end
	GameTooltip:SetPoint('TOPRIGHT', row or TR.window, 'TOPLEFT', -L.PAD, 0)
end

-- The game's tooltip for the quest's item, with the quest's title under it while
-- the button is dimmed or in the column (it names the quest the button belongs to). Obeys the
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
	-- The driver comes from the settings (TR.Visibility.Driver): the pet battle's
	-- part, and In combat, Out of combat and Boss fights Hide while Hide quest items
	-- with the tracker is on.
	local driver = TR.Visibility.Driver(self.config.visibility)
	RegisterStateDriver(layer, 'visibility', driver)
	self.itemDriver = driver
	self.itemLayer = layer
	return layer
end

-- The frame of a quest item button, made once: the secure button, the icon, the
-- hover, the cooldown, the count and the column's number. The pool's buttons are
-- made on the layer (MakeButton), the nearest button (nearest.lua) on its holder.
-- No scripts are set: the owner's differ. Out of combat only.
local function NewButton(parent, name)
	local button = CreateFrame('Button', name, parent, 'SecureActionButtonTemplate')
	-- AnyUp and AnyDown, as SaftUI's own secure buttons register
	-- (SaftUI-ActionBars/buttons.lua) and LibActionButton-1.0 does: an addon's
	-- secure action button gets no isKeyPress or isSecureAction from the game
	-- (SecureTemplates.xml), so SecureActionButton_OnClick acts on the press when
	-- ActionButtonUseKeyDown is on (its default) and on the release when off. A
	-- button registered for AnyUp alone would never act with the setting on. A key
	-- bound to click the button (the nearest button's) arrives the same way, the
	-- press and then the release, so it uses the item once per press.
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
	TR:NewAccent(button.hover, 0.4)

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
	button.over = over
	button.count = over:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(button.count, 'pixel')
	button.count:SetJustifyH('RIGHT')
	button.count:SetPoint('BOTTOMRIGHT', over, 'BOTTOMRIGHT', -2, 2)
	button.count:Hide()
	-- The column's number (Beside the tracker), made with the button like the count:
	-- the Pixel font, at the bottom left.
	button.numberText = over:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(button.numberText, 'pixel')
	button.numberText:SetJustifyH('LEFT')
	button.numberText:SetPoint('BOTTOMLEFT', over, 'BOTTOMLEFT', 2, 2)
	button.numberText:Hide()
	return button
end

-- The nearest button's (nearest.lua): the same button and look on its own holder,
-- with its own scripts and size.
TR.NewItemButton = NewButton
TR.StyleItemButton = StyleButton
TR.PaintItemButton = PaintButton
TR.LogIndex = LogIndex
TR.ReadItemRange = ReadRange
TR.ReadItemCooldown = ReadCooldown

local function MakeButton(self)
	local index = #self.itemButtons + 1
	local button = NewButton(self.itemLayer, st.name .. 'TrackerItem' .. index)
	button.fades = true
	-- The button takes the mouse from its row, so it keeps the row's hover too.
	button:SetScript('OnEnter', function(self)
		local row = self.questID and TR:GetQuestRow(self.questID)
		if row then TR:HoverRow(row, true) end
		TR:ShowItemTooltip(self, self.questID, self.title, self.dimmed or self.column)
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
-- is In the row or Beside the tracker, the list is open, and a quest the list
-- draws has an item with a link (what Wanted would hand a button out for).
function TR:ItemsToShow()
	if not self.built or not self.model or not self.entries then return false end
	local placement = self.config.items.placement
	if placement ~= 'row' and placement ~= 'beside' or self:IsCollapsed() then return false end
	for _, entry in ipairs(self.entries) do
		local quest = entry.kind == 'quest' and entry.quest
		if quest and quest.item and quest.item.link then return true end
	end
	return false
end

-- Whether any button sits in a row (shown), which is what holds the list still
-- in combat (TR:IsScrollLocked, window.lua). A column button doesn't: it is not
-- over a row, so the list scrolls freely and the column stays.
function TR:RowButtonShown()
	for _, button in ipairs(self.itemButtons or {}) do
		if button.questID and not button.column and button:IsShown() then return true end
	end
	return false
end

-- Whether the mouse is over a shown button of the column (the tracker counts it
-- as itself: TR:IsHovered, window.lua).
function TR:IsColumnHovered()
	for _, button in ipairs(self.itemButtons or {}) do
		if button.column and button.questID and button:IsVisible() and button:IsMouseOver() then return true end
	end
	return false
end

-- The quests the layer draws buttons for, in the list's order, as { quest, row }
-- (a beside entry also has the quest's number, its place in the list among the
-- quests with an item to click). In the row: each quest with an item and a row
-- that says its item sits there. Beside the tracker: the quests the list draws
-- (collapsed groups' have no row) with an item that has a link, in the order
-- they are drawn.
local NONE = {}

local function Wanted(self)
	local wanted = self.itemWanted
	local n = 0
	if self.handoverState == 'blizzard' or self.itemsHidden then
		-- Blizzard's tracker is in SaftUI's place (handover.lua), or Hide quest items
		-- with the tracker hides them directly (In instances, Mythic+, Boss fights:
		-- TR.Visibility.Resolve's hideItemsDirectly): no button, and none left from
		-- before.
		for index = 1, #wanted do wanted[index] = nil end
		return wanted
	end
	if self.config.items.placement == 'beside' then
		for _, entry in ipairs(self.entries) do
			local quest = entry.kind == 'quest' and entry.quest
			local row = quest and quest.item and quest.item.link and self:GetQuestRow(quest.id)
			if row and row.item == 'beside' then
				n = n + 1
				local slot = wanted[n]
				if not slot then
					slot = {}
					wanted[n] = slot
				end
				slot.quest, slot.row, slot.number = quest, row, n
			end
		end
	else
		for _, quest in ipairs(self.model.quests) do
			local row = quest.item and self:GetQuestRow(quest.id)
			if row and row.item == 'row' then
				n = n + 1
				local slot = wanted[n]
				if not slot then
					slot = {}
					wanted[n] = slot
				end
				slot.quest, slot.row, slot.number = quest, row, nil
			end
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

-- Whether a row is laid out where it can be read: visible, or shown in a window
-- that only a trigger has hidden (Hide quest items off: the list keeps being laid
-- out while it is hidden, so the buttons are assigned and placed by their rows as
-- usual). Not for a collapsed list or a window the handover or an empty list hides.
local function RowLaidOut(self, row)
	if not row then return false end
	if row:IsVisible() then return true end
	return self.visHidden == true and row:IsShown() and self.scroll:IsShown() and self.content:IsShown()
		and not self.itemsHidden and self.handoverState ~= 'blizzard'
end

-- The offsets of a row's button, in the layer's pixels, or nil while it isn't
-- wanted there.
local function Place(self, row, size)
	if not RowLaidOut(self, row) then return nil end
	return Items.RowPlace(row:GetTop(), row:GetRight(), self.scroll:GetTop(), self.scroll:GetBottom(), size, RoundToPixel)
end

-- Remembers whether the stack hid a button whose title is in view (its place is
-- none though its title shows): out of combat only, so in combat its row keeps the
-- plain icon rather than promising a button that won't come.
local function MarkStacked(self, button, index, place)
	local entry = self.columnEntries[index]
	button.stackedOut = (not place) and entry ~= nil and entry.inView == true
end

-- Puts a button at left and top, or hides it while there is none (its row is out of
-- view, collapsed or gone). Secure calls, so out of combat only, and only on a
-- change.
local function ShowAt(self, button, left, top)
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

local function PlaceButton(self, button, row, size)
	ShowAt(self, button, Place(self, row, size))
end

-- What a button is: a row's (its place is its row's top right) or the column's (its
-- place is the list's, and it wears its number). Regions of the button's child
-- frame only, so a change is free; the kind is set out of combat anyway.
local function SetKind(button, column, number, side)
	button.column, button.columnSide = column, side
	if column and number then
		if button.number ~= number then
			button.number = number
			button.numberText:SetText(tostring(number))
		end
		if not button.numberText:IsShown() then button.numberText:Show() end
	else
		button.number = nil
		if button.numberText:IsShown() then button.numberText:Hide() end
	end
end

-- Each wanted quest's place in the column, in list order: the title's top (the
-- row's, whole pixels, nil while the row isn't visible) against the window's edge
-- on the side nearer the screen's middle, the scroll view as the rows' buttons
-- use it. The table is the same each call.
local function ColumnPlaces(self, wanted, size)
	local scroll = self.scroll
	local entries = self.columnEntries
	if not entries then
		entries = {}
		self.columnEntries, self.columnPlaces = entries, {}
	end
	for index, slot in ipairs(wanted) do
		local entry = entries[index]
		if not entry then
			entry = {}
			entries[index] = entry
		end
		local row = slot.row
		local top = RowLaidOut(self, row) and row:GetTop() or nil
		entry.top = top and RoundToPixel(top) or nil
		-- Whether the title's button would be in view: a place of none then means the
		-- stack pushed it out, not the scroll.
		entry.inView = top ~= nil and scroll:GetTop() ~= nil and scroll:GetBottom() ~= nil
			and top - size / 2 <= scroll:GetTop() and top - size / 2 >= scroll:GetBottom()
	end
	for index = #wanted + 1, #entries do entries[index] = nil end
	local window = self.window
	local holderX, screenX = self.holder:GetCenter(), UIParent:GetCenter()
	local side = (holderX and screenX) and Items.Side(holderX, screenX) or 'left'
	self.columnSide = side
	local left, right = window:GetLeft(), window:GetRight()
	if not (left and right) then
		for index = 1, #entries do entries[index] = nil end
		return Items.Column(entries, size, side, 0, 0, nil, nil, RoundToPixel, self.columnPlaces)
	end
	return Items.Column(entries, size, side, RoundToPixel(left), RoundToPixel(right), scroll:GetTop(), scroll:GetBottom(), RoundToPixel, self.columnPlaces)
end

-- Out of combat: the pool is handed out and each button told its item, set up
-- and placed (at its row, or in the column). Buttons are made on need, up to the
-- cap. This is the refresh's, not a scroll's: it tells buttons their items and
-- styles them.
local function AssignItems(self, wanted)
	local config = self.config
	local byQuest = self.itemByQuest
	local placement = config.items.placement
	local column = placement == 'beside'
	if (placement == 'row' or column) and not self.itemLayer then self:BuildItemLayer() end
	if not ((placement == 'row' or column) and self.itemLayer) then
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
	local places = column and wanted ~= NONE and ColumnPlaces(self, wanted, size) or nil
	for index, entry in ipairs(wanted) do
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
			SetKind(button, column, entry.number, self.columnSide)
			if column then
				local place = places[index]
				MarkStacked(self, button, index, place)
				if place then
					ShowAt(self, button, place.left, place.top)
				else
					ShowAt(self, button)
				end
			else
				PlaceButton(self, button, entry.row, size)
			end
		end
	end
	-- Spare buttons go.
	for _, button in ipairs(self.itemButtons) do
		if not button.questID and button:IsShown() then button:Hide() end
	end
end

-- In combat: nothing secure. A button stays where it was; it dims to DIM_ALPHA
-- when its quest's item is another one now or the quest is gone, and a row's also
-- when its row moved by more than MOVE_TOLERANCE or is out of view, and goes on
-- using its own quest's item. What a drawing may change (the count, the
-- cooldown) follows the quest while its item is the same one. A column button
-- is not tied to its row: the list scrolls, the column stays.
local function DimItems(self)
	local size = self.config.items.size
	for _, button in ipairs(self.itemButtons) do
		if button.questID and button:IsShown() then
			local row = self:GetQuestRow(button.questID)
			local quest = row and row.quest
			local item = quest and quest.item
			local sameItem = item and item.link == (button.item and button.item.link)
			local alpha
			if button.column then
				local same = sameItem and row.item == 'beside'
				if same then
					button.item, button.title = item, quest.title
					button.cd, button.range = item.cooldown, item.range
				end
				alpha = same and 1 or TR.DIM_ALPHA
			else
				local rowTop
				if sameItem and row.item == 'row' then
					local _, top = Place(self, row, button.sizeSet or size)
					rowTop = top
					button.item, button.title = item, quest.title
					button.cd, button.range = item.cooldown, item.range
				end
				alpha = Items.CombatAlpha(button.placedTop, rowTop)
			end
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

-- The number a beside row shows: its quest's own button's, while that button is
-- shown and holds the row's item (a button that can't be shown in combat, or a
-- new item, has none).
local function BesideNumber(self, row)
	local button = self.itemByQuest[row.questID]
	local item = row.quest and row.quest.item
	if button and button.column and button.number and button:IsShown() and item and button.item and button.item.link == item.link then
		return button.number
	end
end

-- Each quest row's item slot (rows.lua): hidden where the quest's own button
-- sits shown (dimmed and displaced or not: it is that quest's), a greyed icon in
-- combat where the quest has none and one can still come, a plain icon
-- otherwise (Item buttons Off, or no button to be had: no link, the pool full).
-- A beside row's slot is where its number goes: hidden under a number, else the
-- icon, greyed in combat only while a button is still to come (not for one the
-- stack hid, which stays plain).
local function DrawSlots(self, combat)
	local placement = self.config.items.placement
	for _, row in ipairs(self.pools.quest.rows) do
		if row.inUse and row.item == 'beside' then
			-- Beside the tracker the slot is where the number goes: hidden under a number,
			-- else the item's icon (greyed while its button is to come in combat).
			local item = row.quest and row.quest.item
			local mode = 'icon'
			if BesideNumber(self, row) then
				mode = 'none'
			elseif combat and item and CanHaveButton(self, item) then
				local button = self.itemByQuest[row.questID]
				if not (button and button.stackedOut) then mode = 'greyed' end
			end
			self:SetSlotMode(row, mode)
		elseif row.inUse and row.item == 'row' then
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

-- Each beside quest row's tag: the number of its quest's own button while that
-- button is shown and for the row's item, else none (a new quest has no button
-- until combat ends, and one whose item changed is not what the button holds). Text only, so it
-- runs in combat too.
local function DrawTags(self)
	for _, row in ipairs(self.pools.quest.rows) do
		if row.inUse and row.item == 'beside' then
			self:SetTag(row, BesideNumber(self, row))
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
	if combat then
		st:QueueAfterCombat('tracker_items', QueuedPass)
		DimItems(self)
	else
		-- The layer's driver follows the settings (out of combat only: a state driver
		-- is attributes).
		self:ApplyItemDriver()
		AssignItems(self, Wanted(self))
	end
	DrawSlots(self, combat)
	DrawTags(self)
	self:UpdateScrollLock()
	self:UpdateRangeWatch()
end

-- The layer's visibility driver from the settings: set out of combat, else queued
-- as 'tracker_items' (the pass at the end of combat sets it, RefreshItems).
function TR:ApplyItemDriver()
	local layer = self.itemLayer
	if not layer then return end
	local driver = TR.Visibility.Driver(self.config.visibility)
	if self.itemDriver == driver then return end
	if st:QueueAfterCombat('tracker_items', QueuedPass) then return end
	self.itemDriver = driver
	RegisterStateDriver(layer, 'visibility', driver)
end

-- The column's buttons, placed again where the list has them now: their places
-- and numbers, hiding the ones whose title is out of view.
local function PlaceColumn(self)
	local wanted = Wanted(self)
	local places = ColumnPlaces(self, wanted, self.config.items.size)
	for index, slot in ipairs(wanted) do
		local button = self.itemByQuest[slot.quest.id]
		if button and button.column then
			SetKind(button, true, slot.number, self.columnSide)
			local place = places[index]
			MarkStacked(self, button, index, place)
			if place then ShowAt(self, button, place.left, place.top) else ShowAt(self, button) end
		end
	end
end

-- The rows moved without a refresh (a scroll, the window collapsing, hiding or
-- being moved, the screen changing size, an edit mode drag): out of combat the
-- buttons follow them, in combat a row's dim and the column stays (and asks to
-- be placed again at the end of combat). Only places: it tells no button its
-- item and styles none (the refresh does), so a thumb drag's scroll events cost
-- a few reads and no allocation.
function TR:PlaceItems()
	if not self.built or not self.model or not self.itemButtons then return end
	local combat = InCombatLockdown()
	if combat then
		DimItems(self)
		for _, button in ipairs(self.itemButtons) do
			if button.column and button.questID then
				st:QueueAfterCombat('tracker_items', QueuedPass)
				break
			end
		end
	else
		local size = self.config.items.size
		for _, button in ipairs(self.itemButtons) do
			if button.questID and not button.column then PlaceButton(self, button, self:GetQuestRow(button.questID), size) end
		end
		if self.config.items.placement == 'beside' then PlaceColumn(self) end
	end
	DrawSlots(self, combat)
	DrawTags(self)
	self:UpdateScrollLock()
	self:UpdateRangeWatch()
end
