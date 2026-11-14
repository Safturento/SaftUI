local st = SaftUI
local TR = st.Tracker
local L, Layout = TR.LAYOUT, TR.Layout

--[[
	The quest list's rows: the row pools, what each kind of row draws, and the
	refresh that keeps them current. Built by TR:Build with the window, so with
	the switch off none of it exists. Nothing here is secure and nothing is
	anchored to a secure frame, so the rows lay out in combat too; the quest
	item buttons (Task 8) are the layer's, not the rows'.

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
	.questID, .item ('row' where the quest's item button sits in the row, whose
	room the title and lines leave on the right: its top right corner is the
	row's top right, itemSize square).
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
-- (a secret one may not give a height) and to centre the quest icon on a
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
	if role == 'text' then return st:GetFont(config.font) or st:GetFont('normal') end
	if role == 'header' then return st:GetFont(config.header_font) or st:GetFont('normal') end
	return st:GetFont('pixel')
end

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
	local key = {}
	for _, role in ipairs({ 'text', 'header', 'pixel' }) do
		local font = FontOf(role)
		if font ~= self.fonts[role] then
			self.fonts[role] = font
			for _, fs in ipairs(self.fontStrings) do
				if fs.role == role then fs:SetFontObject(font) end
			end
			changed = true
		end
		key[#key + 1] = FontKey(font)
	end
	key = table.concat(key, '|')
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

-- The progress bar of a line: SaftUI's bar (a backdrop drawn as kind 'bar' in
-- the page's Theme and Background, the flat texture) in Blizzard's progress
-- blue, with the percent centred on it in the Pixel font. The fill is a
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
	local row = CreateFrame('Frame', nil, self.content)
	local chevron = self:NewChevron(row, function()
		return row.collapsed and 'Expand' or 'Collapse'
	end)
	chevron:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, -(L.ZONE - L.CHEVRON) / 2)
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

	-- The game calls these with a second argument, motion: each is wrapped.
	row:SetScript('OnEnter', function(self) TR:HoverRow(self, true) end)
	row:SetScript('OnLeave', function(self) TR:HoverRow(self, false) end)
	return row
end

local function MakePopupRow(self)
	local row = CreateFrame('Button', nil, self.content)
	row:EnableMouse(true)
	local bar = row:CreateTexture(nil, 'ARTWORK')
	bar:SetSize(L.POPUP_BAR, L.POPUP)
	bar:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, 0)
	row.bar = self:NewAccent(bar, 1)
	row.label = self:NewText(row, 'header')
	row.label:SetWordWrap(false)
	row.label:SetPoint('TOPLEFT', row, 'TOPLEFT', L.POPUP_BAR + L.FOCUS_GAP, 0)
	row.title = self:NewText(row, 'text')
	row.title:SetWordWrap(false)
	row.title:SetPoint('BOTTOMLEFT', row, 'BOTTOMLEFT', L.POPUP_BAR + L.FOCUS_GAP, 0)
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
				pool.free[#pool.free + 1] = row
			end
		end
	end
end

-- The row (one in use) kind's key has now, or nil.
function TR:GetRow(kind, key)
	local pool = self.pools and self.pools[kind]
	local row = pool and key ~= nil and pool.byKey[key] or nil
	if row and row.inUse then return row end
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
-- the header's title to true) and drawn again at once from the model already
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
	TR.SetText(row.label, popup.kind == 'COMPLETE' and 'Quest complete' or 'Quest discovered')
	Paint(row.label, 'accent')
	TR.SetText(row.title, popup.title)
	Paint(row.title, 'normal')
	Width(row.label, p.titleWidth)
	Width(row.title, p.titleWidth)
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
			-- Centred on the title's first line.
			Place(icon, row, 0, math.max(0, math.floor((self:LineHeight() - L.ICON) / 2)))
		end
	end
	Shown(icon, show)
end

local function DrawQuest(self, row, entry, p, width)
	local quest = entry.quest
	local settings = self.config.quests
	row.quest, row.questID, row.item = quest, quest.id, entry.item
	row.itemSize = self.config.items.size
	row.timerPart = nil
	DrawIcon(self, row, quest, entry)
	local titleX = entry.icons and (L.ICON + L.ICON_GAP) or 0
	Place(row.title, row, titleX, 0)
	Paint(row.title, TitleState(quest, settings))
	row.titleX = titleX

	local lines = entry.lines
	for j, line in ipairs(lines) do
		local part = self:Part(row, j)
		local lp = p.lines[j]
		local x = titleX + L.INDENT
		if line.kind == 'bar' then
			local bar = self:PartBar(row, part)
			Shown(part.fs, false)
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
			if line.kind == 'timer' then
				row.timerPart, row.timerHeight, row.lineWidth = j, lp.height, p.lineWidth
				self.timedRows = self.timedRows + 1
			end
		end
	end
	for j = #lines + 1, row.nparts do
		local part = row.parts[j]
		if part then
			Shown(part.fs, false)
			if part.bar then Shown(part.bar, false) end
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
	if self.timedRows > 0 then
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
		local offset = self:GetScroll()
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
		local fs = slot == 'title' and row.title or TR:Part(row, slot).fs
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
	entry.first, entry.lines, entry.item, entry.group, entry.quest, entry.popup, entry.row, entry.icons = nil, nil, nil, nil, nil, nil, nil, nil
	return entry
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
	local inRow = config.items.placement == 'row'
	local now = GetTime()
	local n = 0

	for _, popup in ipairs(model.popups) do
		n = n + 1
		NextEntry(entries, n, 'popup').popup = popup
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
				entry.item = inRow and quest.item and 'row' or nil
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
	-- in the font strings they will be drawn in.
	self:BeginRows()
	for _, entry in ipairs(entries) do
		local kind = entry.kind
		local key
		if kind == 'zone' then
			key = entry.group.key
		elseif kind == 'quest' then
			key = entry.quest.id
		elseif kind == 'popup' then
			key = entry.popup.id
		else
			key = 'empty'
		end
		entry.row = self:AcquireRow(kind, key)
	end
	return entries
end
