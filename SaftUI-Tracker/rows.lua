local st = SaftUI
local TR = st.Tracker
local L, Layout = TR.LAYOUT, TR.Layout

--[[
	The quest list's rows: the row pools, what each kind of row draws, and the
	refresh that keeps them current. Built by TR:Build with the window, so with
	the switch off none of it exists. Nothing here is secure and nothing is
	anchored to a secure frame, so the rows lay out in combat too; the quest
	item buttons are the item layer's (items.lua), not the rows': a row only
	leaves room for one, and draws the item's slot (below).

	A refresh (TR:Refresh) reads the model, groups it, makes the entries, claims
	a row for each, lays them out (TR.Layout.Rows, with the real font strings
	measuring) and draws what changed (TR:DrawRows), then the later stages.
	Performance is a goal of the design: rows, their lines and their bars are
	pooled, a font string's text is set only when it changed (TR.SetText), a
	text is measured again only when its text or width changed (TR:Measure), a
	frame is moved or sized only when its place changed, and a refresh that
	changed nothing sets no text and makes no frame. The one thing that runs
	between refreshes is the timer line's 1 second ticker, only while a timed
	quest shows.

	The pools (TR.pools[kind], kind 'zone', 'quest', 'popup' or 'empty'):
	TR:AcquireRow(kind, key) hands out the row a key had last refresh (a
	quest's ID, a group's key), so a quest keeps its row and its texts stay set,
	or a free one, or a new one. TR:ReleaseRows() hides every row not acquired
	since TR:BeginRows(). TR:GetRow(kind, key) and TR:GetQuestRow(questID) find
	the row a key has now. A quest row is a Button (the mouse for the hover, and
	for the clicks of Task 7): .title (font string), .icon, .hover, .parts[i]
	({ fs, bar }: the i-th line, a text or a progress bar), .quest (the model's),
	.questID, .item ('row' where the quest's item sits in the row, whose room the
	title and lines leave on the right: its top right corner is the row's top
	right, itemSize square), .slot (a plain Button over that corner, shown by
	TR:SetSlotMode: the item's icon greyed while the quest has no button yet, or
	plain where the item has none to click, hidden under a button). 'beside' says
	the quest's button is in the column beside the tracker (items.lua): the row
	then has no slot, and .tag (the Pixel font, in the accent) shows the number
	of the quest's button at the end of the title (TR:SetTag).
]]

local PlainNumber = st.PlainNumber

local function Round(value)
	return math.floor(value + 0.5)
end

local function Colors()
	return st.config.profile.colors
end

local ROW_KINDS = { 'zone', 'quest', 'popup', 'empty' }

------------------------------------------------------------------ text

-- fs's text set to text, only when it differs from what it shows; a secret
-- text is always set (it can't be compared, and SetText takes it). Returns
-- whether it set. Every text of the rows goes through this and nothing else
-- sets one, so fs.shownText says what the text is.
function TR.SetText(fs, text)
	if text == nil then text = '' end
	if issecretvalue(text) then
		fs.shownText = nil
		fs:SetText(text)
		return true
	end
	if fs.shownText == text then return false end
	fs.shownText = text
	fs:SetText(text)
	return true
end

-- The height of one line of the text font, for a text the game won't measure
-- (a secret one may not give a height) and to center the quest icon on a
-- title's first line.
function TR:LineHeight()
	if self.lineHeightStamp ~= self.fontStamp then
		local scratch = self.scratch
		TR.SetText(scratch, 'A')
		self.lineHeightValue = Round(PlainNumber(scratch:GetStringHeight()) or 0)
		self.lineHeightStamp = self.fontStamp
	end
	return self.lineHeightValue
end

-- The height text takes wrapped at width in fs (a font string of row, whose
-- text and width this sets), in whole pixels: read after the width is set, and
-- rounded, never ceiled. Kept per text and width, so the same text at the same
-- width asks the game nothing; a secret text is always asked (it can't be a key
-- or be compared), and a height it won't give is one line.
function TR:Measure(row, fs, text, width)
	if text == nil then text = '' end
	local secret = issecretvalue(text)
	if not secret and fs.measuredStamp == self.fontStamp and fs.shownText == text
		and fs.measuredText == text and fs.measuredWidth == width then
		return fs.measuredHeight
	end
	local wide = math.max(1, width) -- a width of 0 is no limit to the game
	if fs.shownWidth ~= wide then
		fs:SetWidth(wide)
		fs.shownWidth = wide
	end
	TR.SetText(fs, text)
	local height = PlainNumber(fs:GetStringHeight())
	height = height and Round(height) or self:LineHeight()
	if secret then
		fs.measuredText = nil
	else
		fs.measuredStamp, fs.measuredText, fs.measuredWidth, fs.measuredHeight = self.fontStamp, text, width, height
	end
	return height
end

------------------------------------------------------------------ colors

-- The color of a state of a text: Text > Normal, the two Objectives colors,
-- Text > Grey, white, the accent (Buttons > Blue), or the quest's difficulty
-- color. Read at draw time and never kept, so a Colors tab change is seen by
-- the next draw and by TR:ColorRows.
local function StateColor(state, difficulty)
	local colors = Colors()
	if state == 'completed' then return colors.objectives.completed:GetRGB() end
	if state == 'failed' then return colors.objectives.failed:GetRGB() end
	if state == 'grey' then return colors.text.grey:GetRGB() end
	if state == 'white' then return 1, 1, 1 end
	if state == 'accent' then return colors.button.blue:GetRGB() end
	if state == 'difficulty' and difficulty then return difficulty.r, difficulty.g, difficulty.b end
	return colors.text.normal:GetRGB()
end

local function Paint(fs, state, difficulty)
	local r, g, b = StateColor(state, difficulty)
	if fs.trState ~= state or fs.trR ~= r or fs.trG ~= g or fs.trB ~= b then
		fs.trState, fs.trDiff, fs.trR, fs.trG, fs.trB = state, difficulty, r, g, b
		fs:SetTextColor(r, g, b)
	end
end

-- A texture in the accent: a color fill at alpha, or a vertex color (an icon).
local function PaintAccent(tex)
	local r, g, b = StateColor('accent')
	if tex.accentAlpha then
		tex:SetColorTexture(r, g, b, tex.accentAlpha)
	else
		tex:SetVertexColor(r, g, b, 1)
	end
end

-- A texture drawn in the accent, painted again by TR:ColorRows.
function TR:NewAccent(tex, alpha)
	tex.accentAlpha = alpha
	self.accents[#self.accents + 1] = tex
	PaintAccent(tex)
	return tex
end

-- What the rows color themselves, put back after a Colors tab change: the
-- texts (their status colors, the zone titles and counts) and every accent
-- piece (the focus bar, the hover, the map pin, a popup's bar). Nothing is
-- rebuilt or measured. Called by the module's one OnColorsChanged (init.lua).
function TR:ColorRows()
	if not self.fontStrings then return end
	for _, fs in ipairs(self.fontStrings) do
		if fs.trState then Paint(fs, fs.trState, fs.trDiff) end
	end
	for _, tex in ipairs(self.accents) do PaintAccent(tex) end
end

------------------------------------------------------------------ fonts

local function FontOf(role)
	local config = TR.config
	if role == 'text' then return st:FontObject(config.font) end
	if role == 'header' then return st:FontObject(config.header_font) end
	return st:FontObject('pixel')
end

local FONT_ROLES = { 'text', 'header', 'pixel' }

local function FontKey(font)
	if not font then return '' end
	local path, size, flags = font:GetFont()
	return tostring(path) .. ':' .. tostring(size) .. ':' .. tostring(flags)
end

-- A font string of the rows in the font of its role: 'text' (titles and
-- objectives, Font), 'header' (zone headers, Header font) or 'pixel' (the bars'
-- percent).
function TR:NewText(parent, role)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(FontOf(role))
	fs:SetJustifyH('LEFT')
	fs:SetWordWrap(role == 'text')
	fs.role = role
	self.fontStrings[#self.fontStrings + 1] = fs
	return fs
end

-- Puts the fonts the page and the Fonts tab give on every text, and tells the
-- measures when one changed (the page's Font or Header font, or the font
-- object's own size, shadow or spacing, which the Fonts tab changes without
-- telling any module). Checked at the start of every draw.
function TR:CheckFonts()
	local changed = false
	local key = ''
	for index = 1, #FONT_ROLES do
		local role = FONT_ROLES[index]
		local font = FontOf(role)
		if font ~= self.fonts[role] then
			self.fonts[role] = font
			for _, fs in ipairs(self.fontStrings) do
				if fs.role == role then fs:SetFontObject(font) end
			end
			changed = true
		end
		key = key .. FontKey(font) .. '|'
	end
	if key ~= self.fontKey then
		self.fontKey = key
		changed = true
	end
	if changed then self.fontStamp = self.fontStamp + 1 end
end

------------------------------------------------------------------ small helpers

-- Shows or hides obj only when its state changes.
local function Shown(obj, shown)
	if obj.trShown ~= shown then
		obj.trShown = shown
		obj:SetShown(shown)
	end
end

-- obj's top left corner x right and y down from parent's, set only when it
-- moved.
local function Place(obj, parent, x, y)
	if obj.placeX ~= x or obj.placeY ~= y or obj.placeParent ~= parent then
		obj.placeX, obj.placeY, obj.placeParent = x, y, parent
		obj:ClearAllPoints()
		obj:SetPoint('TOPLEFT', parent, 'TOPLEFT', x, y == 0 and 0 or -y)
	end
end

local function Size(obj, width, height)
	if obj.sizeW ~= width or obj.sizeH ~= height then
		obj.sizeW, obj.sizeH = width, height
		obj:SetSize(width, height)
	end
end

local function Width(fs, width)
	width = math.max(1, width)
	if fs.shownWidth ~= width then
		fs.shownWidth = width
		fs:SetWidth(width)
	end
end

------------------------------------------------------------------ making rows

-- A quest row's i-th line: { fs } a text, and { bar } once it has been a
-- progress bar. Made when first needed and kept.
function TR:Part(row, index)
	local part = row.parts[index]
	if not part then
		part = { fs = self:NewText(row, 'text') }
		part.fs:SetJustifyV('TOP')
		row.parts[index] = part
		if index > row.nparts then row.nparts = index end
	end
	return part
end

-- A line's dash: its own font string (the text may be a secret that can't be
-- joined to one), made when first needed.
function TR:PartDash(part)
	if not part.dash then
		part.dash = self:NewText(part.fs:GetParent(), 'text')
		part.dash:SetWordWrap(false)
		part.dash:SetJustifyV('TOP')
	end
	return part.dash
end

-- The room an objective's dash takes before its text: the dash's width and 4.
function TR:DashWidth()
	if self.dashStamp ~= self.fontStamp then
		local scratch = self.scratch
		TR.SetText(scratch, '-')
		local unbounded = scratch.GetUnboundedStringWidth or scratch.GetStringWidth
		self.dashValue = math.ceil(PlainNumber(unbounded(scratch)) or 0) + L.ICON_GAP
		self.dashStamp = self.fontStamp
	end
	return self.dashValue
end

-- The progress bar of a line: SaftUI's bar (a backdrop drawn as kind 'bar' in
-- the page's Theme and Background, the flat texture) in Blizzard's progress
-- blue, with the percent centered on it in the Pixel font. The fill is a
-- texture sized in whole pixels.
local BAR_COLOR = { 0.26, 0.42, 1 }

function TR:PartBar(row, part)
	local bar = part.bar
	if bar then return bar end
	bar = st:CreateFrame('Frame', nil, row)
	bar:SetSize(1, L.BAR)
	local fill = bar:CreateTexture(nil, 'ARTWORK')
	fill:SetTexture(st.BLANK_TEX)
	fill:SetVertexColor(BAR_COLOR[1], BAR_COLOR[2], BAR_COLOR[3], 1)
	fill:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, 0)
	fill:SetHeight(L.BAR)
	bar.fill = fill
	local label = self:NewText(bar, 'pixel')
	label:SetJustifyH('CENTER')
	label:SetPoint('CENTER', bar, 'CENTER', 0, 0)
	bar.label = label
	st:SetBackdrop(bar, self.config.theme, self.config.background, 'bar')
	part.bar = bar
	return bar
end

local function MakeZoneRow(self)
	-- A Button: a left click anywhere on the header collapses or expands the
	-- group, as the chevron does; a right click does nothing.
	local row = CreateFrame('Button', nil, self.content)
	row:EnableMouse(true)
	row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	row:SetScript('OnClick', function(self, button)
		if button == 'LeftButton' and self.key ~= nil then TR:ToggleZone(self.key) end
	end)
	local chevron = self:NewChevron(row, function()
		return row.collapsed and 'Expand' or 'Collapse'
	end)
	chevron:SetPoint('LEFT', row, 'LEFT', 0, 0)
	chevron:SetScript('OnClick', function(button)
		TR:ToggleZone(row.key)
		if GameTooltip:IsOwned(button) then button:ShowTip() end
	end)
	row.chevron = chevron

	local title = self:NewText(row, 'header')
	title:SetWordWrap(false)
	title:SetPoint('LEFT', row, 'LEFT', L.CHEVRON + L.ZONE_TITLE_GAP, 0)
	row.title = title

	local pin = row:CreateTexture(nil, 'OVERLAY')
	pin:SetTexture(st.icons.mapPin)
	pin:SetSize(L.CHEVRON, L.CHEVRON)
	pin:SetPoint('LEFT', title, 'RIGHT', L.ZONE_TITLE_GAP, 0)
	row.pin = self:NewAccent(pin)

	local count = self:NewText(row, 'header')
	count:SetWordWrap(false)
	count:SetJustifyH('RIGHT')
	count:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
	row.count = count
	return row
end

local function MakeQuestRow(self)
	local row = CreateFrame('Button', nil, self.content)
	row:EnableMouse(true)
	row.parts, row.nparts = {}, 0

	local hover = row:CreateTexture(nil, 'BACKGROUND')
	hover:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, L.HOVER_PAD)
	hover:SetPoint('BOTTOMRIGHT', row, 'BOTTOMRIGHT', 0, -L.HOVER_PAD)
	hover:Hide()
	row.hover = self:NewAccent(hover, st.TINT_ROW)

	row.icon = row:CreateTexture(nil, 'ARTWORK')
	row.icon:SetSize(L.ICON, L.ICON)
	row.title = self:NewText(row, 'text')
	row.title:SetJustifyV('TOP')

	-- The item's slot, at the row's top right. A plain Button (never secure): it
	-- takes the mouse from the row there, so it keeps the row's hover, and
	-- clicks nothing. Items.lua says what it shows.
	local slot = CreateFrame('Button', nil, row)
	slot:EnableMouse(true)
	slot:Hide()
	slot.icon = slot:CreateTexture(nil, 'ARTWORK')
	slot.icon:SetAllPoints(slot)
	slot.mode = 'none'
	-- Its clicks are the row's (a left click, the menu, Shift-click): the slot only
	-- shows the item, it uses nothing.
	slot:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	slot:SetScript('OnClick', function(self, button) TR:OnQuestClick(row, button) end)
	slot:SetScript('OnEnter', function(self)
		TR:HoverRow(row, true)
		TR:ShowSlotTooltip(self, row)
	end)
	slot:SetScript('OnLeave', function(self)
		TR:HoverRow(row, false)
		if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
	row.slot = slot

	-- The column's number, at the end of the title (TR:SetTag). Plain text, so it
	-- is set in combat too.
	row.tag = self:NewText(row, 'pixel')
	row.tag:SetWordWrap(false)
	row.tag:SetJustifyV('TOP')
	row.tag:Hide()

	-- The quest's icon is a button of its own over the icon texture: a click
	-- focuses the quest, or stops focusing it (Blizzard's POI button does the
	-- same). It takes the mouse from the row there, so it keeps the row's hover.
	local iconButton = CreateFrame('Button', nil, row)
	iconButton:SetAllPoints(row.icon)
	iconButton:Hide()
	iconButton:SetScript('OnClick', function() TR:ToggleFocus(row.questID) end)
	iconButton:SetScript('OnEnter', function(self)
		TR:HoverRow(row, true)
		TR:ShowIconTooltip(self, row)
	end)
	iconButton:SetScript('OnLeave', function(self)
		TR:HoverRow(row, false)
		if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end)
	row.iconButton = iconButton

	-- Both mouse buttons, on release, as Blizzard's blocks take them. The game
	-- calls the hover scripts with a second argument, motion: each is wrapped.
	row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	row:SetScript('OnClick', function(self, button) TR:OnQuestClick(self, button) end)
	row:SetScript('OnEnter', function(self)
		TR:HoverRow(self, true)
		TR:ShowRowTooltip(self)
	end)
	row:SetScript('OnLeave', function(self)
		TR:HoverRow(self, false)
		TR:HideRowTooltip(self)
	end)
	return row
end

local function MakePopupRow(self)
	local row = CreateFrame('Button', nil, self.content)
	row:EnableMouse(true)
	local bar = row:CreateTexture(nil, 'ARTWORK')
	bar:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, 0)
	bar:SetPoint('BOTTOMLEFT', row, 'BOTTOMLEFT', 0, 0)
	bar:SetWidth(L.POPUP_BAR)
	row.bar = self:NewAccent(bar, 1)
	row.label = self:NewText(row, 'header')
	row.label:SetWordWrap(false)
	row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', L.POPUP_BAR + L.FOCUS_GAP, 0)
	row.title = self:NewText(row, 'text')
	row.title:SetWordWrap(false)
	row:SetScript('OnClick', function(self) TR:OnPopupClick(self) end)
	return row
end

local function MakeEmptyRow(self)
	local row = CreateFrame('Frame', nil, self.content)
	row.title = self:NewText(row, 'text')
	row.title:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, 0)
	return row
end

local MAKERS = { zone = MakeZoneRow, quest = MakeQuestRow, popup = MakePopupRow, empty = MakeEmptyRow }

-- Starts a pass: the rows acquired from here on are the ones ReleaseRows keeps.
function TR:BeginRows()
	self.pass = self.pass + 1
end

-- The row for key of kind: the one the key had last pass, else a free one, else
-- a new one (the only place a frame is made). A key is a quest's ID, a group's
-- key, a popup's quest ID, 'empty'.
function TR:AcquireRow(kind, key)
	local pool = self.pools[kind]
	local row = key ~= nil and pool.byKey[key] or nil
	if not row then
		row = table.remove(pool.free)
		if not row then
			row = MAKERS[kind](self)
			-- A row made while the window is faded out takes no mouse (visibility.lua).
			if self.inputOff then self:SetRowMouse(row, false) end
			row.kind = kind
			pool.rows[#pool.rows + 1] = row
		end
		if key ~= nil then pool.byKey[key] = row end
		row.key = key
	end
	row.pass = self.pass
	row.inUse = true
	return row
end

-- Hides and frees every row not acquired since BeginRows (all of them with
-- all), so a quest that went leaves nothing behind.
function TR:ReleaseRows(all)
	for _, kind in ipairs(ROW_KINDS) do
		local pool = self.pools[kind]
		for _, row in ipairs(pool.rows) do
			if row.inUse and (all or row.pass ~= self.pass) then
				row.inUse = false
				Shown(row, false)
				if row.hover then
					row.hovered = false
					row.hover:Hide()
				end
				if row.key ~= nil then pool.byKey[row.key] = nil end
				row.key, row.quest, row.questID, row.item, row.timerPart = nil, nil, nil, nil, nil
				if row.slot then
					row.slot.mode = 'none'
					Shown(row.slot, false)
				end
				if row.tag then
					row.tag.numberShown = nil
					Shown(row.tag, false)
				end
				pool.free[#pool.free + 1] = row
			end
		end
	end
end

-- What a quest row's item slot shows: 'none' (hidden: a button sits over the
-- row's corner), 'greyed' (the icon desaturated at DIM_ALPHA, while the quest's
-- item has no button yet) or 'icon' (the plain icon, where the item has no
-- button to be had). Only a change is drawn.
function TR:SetSlotMode(row, mode)
	local slot = row.slot
	if slot.mode == mode then return end
	slot.mode = mode
	if mode == 'none' then
		Shown(slot, false)
		return
	end
	local greyed = mode == 'greyed'
	slot.icon:SetDesaturated(greyed)
	slot.icon:SetAlpha(greyed and TR.DIM_ALPHA or 1)
	Shown(slot, true)
end

-- What a quest row's tag shows: the number of its quest's button, or nothing
-- (nil). Only a change is drawn.
function TR:SetTag(row, number)
	local tag = row.tag
	if not tag then return end
	if number == nil then
		if tag.numberShown ~= nil then
			tag.numberShown = nil
			Shown(tag, false)
		end
		return
	end
	if tag.numberShown ~= number then
		tag.numberShown = number
		TR.SetText(tag, tostring(number))
		Paint(tag, 'accent')
	end
	Shown(tag, true)
end

-- The room a number (or the item's icon, one line high) takes at the end of a
-- title beside the tracker: the wider of "00" in the Pixel font (the log holds 40
-- quests at most) and a line, and the gap before it.
function TR:TagRoom()
	if self.tagStamp ~= self.fontStamp then
		local scratch = self.tagScratch
		TR.SetText(scratch, '00')
		local unbounded = scratch.GetUnboundedStringWidth or scratch.GetStringWidth
		-- Wide enough for two digits, or for the item's icon one line high.
		self.tagValue = math.max(math.ceil(PlainNumber(unbounded(scratch)) or 0), self:LineHeight()) + L.ITEM_GAP
		self.tagHeight = PlainNumber(scratch:GetStringHeight()) or 0
		self.tagStamp = self.fontStamp
	end
	return self.tagValue
end

-- The row (one in use) kind's key has now, or nil.
function TR:GetRow(kind, key)
	local pool = self.pools and self.pools[kind]
	local row = pool and key ~= nil and pool.byKey[key] or nil
	if row and row.inUse then return row end
end

-- A popup's row: an offer and a complete popup of one quest have one each.
function TR:GetPopupRow(questID, kind)
	return self:GetRow('popup', ('%d:%s'):format(questID, kind))
end

-- The quest's row, or nil while it isn't drawn (not tracked, or under a
-- collapsed zone header).
function TR:GetQuestRow(questID)
	return self:GetRow('quest', questID)
end

------------------------------------------------------------------ interaction

-- The accent fill under the mouse, TINT_ROW strong, HOVER_PAD beyond the row.
function TR:HoverRow(row, hovered)
	row.hovered = hovered
	row.hover:SetShown(hovered)
end

-- A zone header's collapse, kept per character (st.config.char.tracker.zones,
-- the group's key to true) and drawn again at once from the model already
-- read.
function TR:ToggleZone(key)
	local zones = self:CharData().zones
	if zones[key] then
		zones[key] = nil
	else
		zones[key] = true
	end
	self:Redraw()
end

-- A popup's click: the game's own offer or turn-in frame (the game functions
-- that open it through its own events, no Blizzard Lua of ours), then the
-- popup is removed, as Blizzard's does. Allowed in combat (an in-game check).
function TR:OnPopupClick(row)
	local questID = row.questID
	if not questID then return end
	if row.popupKind == 'COMPLETE' then
		if type(ShowQuestComplete) == 'function' then ShowQuestComplete(questID) end
	else
		if type(ShowQuestOffer) == 'function' then ShowQuestOffer(questID) end
	end
	if type(RemoveAutoQuestPopUp) == 'function' then RemoveAutoQuestPopUp(questID) end
	self:MarkDirty('POPUP')
end

------------------------------------------------------------------ drawing

local function DrawZone(self, row, entry, p, width)
	local group = entry.group
	row.collapsed = group.collapsed
	if row.chevronDown ~= group.collapsed then
		row.chevronDown = group.collapsed
		row.chevron:SetDown(group.collapsed)
	end
	TR.SetText(row.title, group.title)
	Paint(row.title, group.current and 'normal' or 'grey')
	TR.SetText(row.count, tostring(group.count))
	Paint(row.count, 'grey')
	Shown(row.pin, group.current and true or false)
	-- The title is as wide as its text up to the room the pin and the count
	-- leave, so the pin follows its last letter.
	local unbounded = row.title.GetUnboundedStringWidth or row.title.GetStringWidth
	local countRoom = math.ceil(PlainNumber(unbounded(row.count)) or 0) + L.COUNT_GAP
	local pinRoom = group.current and (L.ZONE_TITLE_GAP + L.CHEVRON) or 0
	local room = width - L.CHEVRON - L.ZONE_TITLE_GAP - countRoom - pinRoom
	Width(row.title, math.min(math.ceil(PlainNumber(unbounded(row.title)) or 0), room))
end

local function DrawPopup(self, row, entry, p, width)
	local popup = entry.popup
	row.questID, row.popupKind = popup.id, popup.kind
	Paint(row.label, 'accent')
	Paint(row.title, 'normal')
	Place(row.title, row, L.POPUP_BAR + L.FOCUS_GAP, p.labelHeight + L.LINE_GAP)
end

local function DrawEmpty(self, row, entry, p, width)
	Paint(row.title, 'grey')
end

local function TitleState(quest, settings)
	if TR.Model.Finished(quest) then return 'completed' end
	if quest.failed then return 'failed' end
	if settings.difficulty and quest.difficultyColor then return 'difficulty', quest.difficultyColor end
	return 'normal'
end

local function DrawIcon(self, row, quest, entry)
	local icon = row.icon
	local show = false
	if entry.icons then
		local asset, isAtlas = QuestUtil.GetQuestIconActiveForQuestID(quest.id, TR.Model.Finished(quest))
		if asset then
			show = true
			if icon.trAsset ~= asset or icon.trAtlas ~= isAtlas then
				icon.trAsset, icon.trAtlas = asset, isAtlas
				if isAtlas then icon:SetAtlas(asset) else icon:SetTexture(asset) end
			end
			-- Centered on the title's first line.
			Place(icon, row, 0, math.max(0, math.floor((self:LineHeight() - L.ICON) / 2)))
		end
	end
	Shown(icon, show)
	Shown(row.iconButton, show)
end

-- The item slot's place (the row's top right, itemSize square) and icon, for a
-- quest whose item sits in its row; hidden for one with no item there. What it
-- shows is TR:SetSlotMode's, from the item stage (items.lua).
local function SlotIcon(slot, quest, size)
	local texture = quest.item.texture
	local trim = st.config.profile.misc.icon_trim
	if slot.shownTexture ~= texture or slot.shownTrim ~= trim or slot.shownSize ~= size then
		slot.shownTexture, slot.shownTrim, slot.shownSize = texture, trim, size
		slot.icon:SetTexture(texture)
		-- Cropped by Icon zoom, as the button's icon is.
		slot.icon:SetTexCoord(st:IconTexCoords(trim, size, size))
	end
end

local function DrawItemSlot(self, row, quest, entry, width)
	local slot = row.slot
	if entry.item == 'beside' and quest.item then return end -- DrawQuest's, by the title
	if entry.item ~= 'row' or not quest.item then
		self:SetSlotMode(row, 'none')
		return
	end
	local size = row.itemSize
	Place(slot, row, width - size, 0)
	Size(slot, size, size)
	SlotIcon(slot, quest, size)
end

local function DrawQuest(self, row, entry, p, width)
	local quest = entry.quest
	local settings = self.config.quests
	row.quest, row.questID, row.item = quest, quest.id, entry.item
	row.itemSize = self.config.items.size
	row.timerPart = nil
	DrawItemSlot(self, row, quest, entry, width)
	DrawIcon(self, row, quest, entry)
	local titleX = entry.icons and (L.ICON + L.ICON_GAP) or 0
	Place(row.title, row, titleX, 0)
	Paint(row.title, TitleState(quest, settings))
	row.titleX = titleX
	if entry.item == 'beside' then
		-- The number follows the title's last letter, as the zone pin does, up to the
		-- room the layout left for it. What it says is the item stage's (TR:SetTag).
		-- A secret title is never measured: the number goes at the title's width.
		local reach = p.titleWidth
		if not issecretvalue(entry.first) then
			local unbounded = row.title.GetUnboundedStringWidth or row.title.GetStringWidth
			reach = math.min(math.ceil(PlainNumber(unbounded(row.title)) or reach), reach)
		end
		local x = titleX + reach + L.ITEM_GAP
		-- Centred on the title's first line, as the icon is; the item's icon (one line
		-- high) takes the same place while the quest has no number.
		local line = self:LineHeight()
		Place(row.tag, row, x, math.max(0, math.floor((line - self.tagHeight) / 2)))
		Place(row.slot, row, x, 0)
		Size(row.slot, line, line)
		SlotIcon(row.slot, quest, line)
	else
		self:SetTag(row, nil)
	end

	local lines = entry.lines
	for j, line in ipairs(lines) do
		local part = self:Part(row, j)
		local lp = p.lines[j]
		local x = titleX + lp.x
		if line.kind == 'bar' then
			local bar = self:PartBar(row, part)
			Shown(part.fs, false)
			if part.dash then Shown(part.dash, false) end
			Shown(bar, true)
			Place(bar, row, x, lp.y)
			Size(bar, p.lineWidth, L.BAR)
			local percent = math.min(math.max(PlainNumber(line.value) or 0, 0), 100)
			local fill = Round(p.lineWidth * percent / 100)
			if bar.fillW ~= fill then
				bar.fillW = fill
				bar.fill:SetWidth(math.max(fill, 1))
				bar.fill:SetShown(fill > 0)
			end
			TR.SetText(bar.label, line.text)
			Paint(bar.label, 'white')
		else
			if part.bar then Shown(part.bar, false) end
			Shown(part.fs, true)
			Place(part.fs, row, x, lp.y)
			Paint(part.fs, line.state)
			-- An objective's dash is its own font string, so a secret text needs no
			-- join; the text's later lines align under the text, not the dash.
			if line.kind == 'objective' then
				local dash = self:PartDash(part)
				Place(dash, row, titleX + L.INDENT, lp.y)
				TR.SetText(dash, '-')
				Paint(dash, line.state)
				Shown(dash, true)
			elseif part.dash then
				Shown(part.dash, false)
			end
			if line.kind == 'timer' then
				row.timerPart, row.timerHeight, row.lineWidth = j, lp.height, lp.width
				self.timedRows = self.timedRows + 1
			end
		end
	end
	for j = #lines + 1, row.nparts do
		local part = row.parts[j]
		if part then
			Shown(part.fs, false)
			if part.bar then Shown(part.bar, false) end
			if part.dash then Shown(part.dash, false) end
		end
	end
end

local DRAW = { zone = DrawZone, quest = DrawQuest, popup = DrawPopup, empty = DrawEmpty }

-- Draws the rows the entries claimed at the places the layout gave: each row's
-- place and size, its texts' colors, its parts. Texts and their widths were set
-- by the measure. Then the rows no entry claimed go, the focused quest's bar is
-- put where its row is, and the timer's ticker runs while a timed quest shows.
function TR:DrawRows(entries, placed)
	local width = self.rowWidth
	self.timedRows = 0
	self.focusY, self.focusH = nil, nil
	local focused = self.model and self.model.focused
	for index, entry in ipairs(entries) do
		local row, p = entry.row, placed[index]
		Place(row, self.content, 0, p.y)
		Size(row, width, p.height)
		DRAW[entry.kind](self, row, entry, p, width)
		Shown(row, true)
		if entry.quest and focused and entry.quest.id == focused then
			self.focusY, self.focusH = p.y, p.height
		end
	end
	self:ReleaseRows()
	self:PlaceFocusBar()
	self:UpdateTicker()
end

-- The timer's ticker runs while a timed quest shows and the tracker is open.
function TR:UpdateTicker()
	if (self.timedRows or 0) > 0 and not self:IsCollapsed() then
		if not self.timerTicker and C_Timer and C_Timer.NewTicker then
			self.timerTicker = C_Timer.NewTicker(1, function() TR:TickTimers() end)
		end
	elseif self.timerTicker then
		self.timerTicker:Cancel()
		self.timerTicker = nil
	end
end

------------------------------------------------------------------ the timer

-- One second of every timed quest's timer line: the time left counted down from
-- the read, the text set only when it changed, its color Failed under a minute.
-- A line that reached 0, or one whose text now wraps differently, asks for a
-- refresh (the quest may have failed; the layout is the refresh's).
function TR:TickTimers()
	local now = GetTime()
	local dirty = false
	for _, row in ipairs(self.pools.quest.rows) do
		local index = row.inUse and row.timerPart
		if index then
			local quest = row.quest
			local left = quest.timeLeft - (now - (quest.readAt or now))
			if left <= 0 then
				dirty = true
			else
				local text, state = TR.TimerLine(left)
				local fs = row.parts[index].fs
				if TR.SetText(fs, text) then
					Paint(fs, state)
					if self:Measure(row, fs, text, row.lineWidth) ~= row.timerHeight then dirty = true end
				end
			end
		end
	end
	if dirty then self:MarkDirty('TIMER') end
end

------------------------------------------------------------------ the focused quest

-- The focused quest's marker: a 2 px accent bar 4 left of its row, as tall as
-- the part of the row in view. It's the window's, not a row's: the list's
-- scroll frame clips what's left of it, and the marker sits in the window's
-- padding. Placed after a draw and after every scroll.
function TR:PlaceFocusBar()
	local bar = self.focusBar
	if not bar then return end
	local show = false
	if self.focusY and not self:IsCollapsed() then
		local view = Round(self.scroll:GetHeight())
		local offset = Round(self:GetScroll())
		local top = math.max(self.focusY - offset, 0)
		local bottom = math.min(self.focusY + self.focusH - offset, view)
		if bottom > top then
			show = true
			if bar.placeTop ~= top or bar.placeBottom ~= bottom then
				bar.placeTop, bar.placeBottom = top, bottom
				bar:ClearAllPoints()
				bar:SetPoint('TOPLEFT', self.scroll, 'TOPLEFT', -(L.FOCUS_GAP + L.FOCUS_BAR), top == 0 and 0 or -top)
				bar:SetSize(L.FOCUS_BAR, bottom - top)
			end
		end
	end
	Shown(bar, show)
end

------------------------------------------------------------------ building

-- Makes the pools, the scratch text the layout measures a line height with,
-- and the focus bar. Called by TR:Build after the window.
function TR:BuildRows()
	self.pools = {}
	for _, kind in ipairs(ROW_KINDS) do
		self.pools[kind] = { rows = {}, free = {}, byKey = {} }
	end
	self.fontStrings, self.accents, self.fonts = {}, {}, {}
	self.fontStamp, self.pass, self.timedRows = 0, 0, 0
	self.entries, self.placed = {}, {}
	self.metrics = { width = 0, spacing = 0, icons = false, itemSize = 0 }
	self.scratch = self.window:CreateFontString(nil, 'OVERLAY')
	self.scratch:SetWordWrap(false)
	self.scratch.role = 'text'
	self.fontStrings[1] = self.scratch
	-- The number's room is measured in a text of its own, in the Pixel font.
	self.tagScratch = self:NewText(self.window, 'pixel')
	self.tagScratch:SetWordWrap(false)
	self.tagScratch:Hide()
	self.scratch:SetFontObject(FontOf('text'))
	self.scratch:Hide()
	self.fonts.text = FontOf('text')

	local bar = self.window:CreateTexture(nil, 'OVERLAY')
	bar:Hide()
	self.focusBar = self:NewAccent(bar, 1)

	-- The layout asks for the height of a title or a line: the font string of
	-- that text, in its row, answers.
	self.measureText = function(text, width, font, entry, slot)
		local row = entry.row
		local fs
		if slot == 'title' then
			fs = row.title
		elseif slot == 'label' then
			fs = row.label
		else
			fs = TR:Part(row, slot).fs
		end
		return TR:Measure(row, fs, text, width)
	end
end

-- The rows' look from the page: the bars' backdrops in the Theme and
-- Background (a theme change draws every drawn frame again by itself; this is
-- for the page's own pair).
function TR:DrawRowsLook()
	if not self.pools then return end
	local config = self.config
	for _, row in ipairs(self.pools.quest.rows) do
		for index = 1, row.nparts do
			local bar = row.parts[index] and row.parts[index].bar
			if bar then st:SetBackdrop(bar, config.theme, config.background, 'bar') end
		end
	end
end

------------------------------------------------------------------ entries

local EMPTY_TEXT = 'No tracked quests.'

-- Whether the quest icons show: Quest icons on, and the game's util that says
-- which icon (Blizzard's, which only works out an atlas name) is there.
function TR:ShowsIcons()
	return self.config.quests.icons and type(QuestUtil) == 'table'
		and type(QuestUtil.GetQuestIconActiveForQuestID) == 'function' or false
end

-- Fills the next entry of the reused list: its fields are cleared, so nothing
-- of the last refresh's stays.
local function NextEntry(entries, n, kind)
	local entry = entries[n]
	if not entry then
		entry = {}
		entries[n] = entry
	end
	entry.kind = kind
	entry.label, entry.first, entry.lines, entry.item, entry.group, entry.quest, entry.popup, entry.row, entry.icons = nil, nil, nil, nil, nil, nil, nil, nil, nil
	return entry
end

-- The key an entry's row is found by: a group's key, a quest's or popup's ID.
local function RowKey(entry)
	local kind = entry.kind
	if kind == 'zone' then return entry.group.key end
	if kind == 'quest' then return entry.quest.id end
	if kind == 'popup' then return ('%d:%s'):format(entry.popup.id, entry.popup.kind) end
	return 'empty'
end

-- The list of what is drawn, top to bottom: the popups, then each group's
-- header (none with Group by zone off) and, unless the player collapsed it,
-- its quests (a collapsed group keeps its header and count); or the empty
-- line, when there is nothing and the window isn't hidden for it. Each entry
-- is { kind, first, lines, item, ... } as TR.Layout.Rows takes it, with its
-- data (group, quest, popup) and the row it claimed (row). The list is the
-- same table each refresh. A quest's title and lines are said here, once.
function TR:BuildEntries(model, groups)
	local entries = self.entries
	local config = self.config
	local settings = config.quests
	local icons = self:ShowsIcons()
	-- In the row, the item takes room there: a button (In the row), or its plain
	-- icon (Off). Beside the tracker the button is in the column, and the title
	-- leaves room for the number at its end.
	local placement = config.items.placement
	local inRow = placement == 'row' or placement == 'off'
	local beside = placement == 'beside'
	self.metrics.tagRoom = beside and self:TagRoom() or 0
	local now = GetTime()
	local n = 0

	for _, popup in ipairs(model.popups) do
		n = n + 1
		local entry = NextEntry(entries, n, 'popup')
		entry.popup = popup
		entry.label = popup.kind == 'COMPLETE' and 'Quest complete' or 'Quest discovered'
		entry.first = popup.title
	end
	for _, group in ipairs(groups) do
		if group.key ~= TR.ALL_KEY then
			n = n + 1
			NextEntry(entries, n, 'zone').group = group
		end
		if not group.collapsed then
			for _, quest in ipairs(group.quests) do
				n = n + 1
				local entry = NextEntry(entries, n, 'quest')
				entry.quest = quest
				entry.first = TR.TitleText(quest, settings)
				entry.lines = TR.QuestLines(quest, settings, now)
				entry.item = quest.item and (inRow and 'row' or beside and 'beside') or nil
				entry.icons = icons
			end
		end
	end
	if n == 0 and not config.hide_empty then
		n = 1
		NextEntry(entries, n, 'empty').first = EMPTY_TEXT
	end
	for index = n + 1, #entries do entries[index] = nil end

	-- Every row is claimed before the layout measures, so the texts are measured
	-- in the font strings they will be drawn in: first the rows their keys had
	-- last time, then the rows of what went are freed, and only then the rest
	-- take free rows (so a refresh that swaps quests makes no frame).
	self:BeginRows()
	for _, entry in ipairs(entries) do
		local key = RowKey(entry)
		if self:GetRow(entry.kind, key) then entry.row = self:AcquireRow(entry.kind, key) end
	end
	self:ReleaseRows()
	for _, entry in ipairs(entries) do
		if not entry.row then entry.row = self:AcquireRow(entry.kind, RowKey(entry)) end
	end
	return entries
end
