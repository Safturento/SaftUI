local st = SaftUI
local OM, W = st.OptionsModel, st.OptionsWidgets

--[[
	SaftUI's options window: /sui, drawn by SaftUI from the same Ace option
	tree AceConfigDialog drew (st.Config:GetOptionsTable()), laid out as the
	approved mockup (docs/superpowers/specs/assets/2026-11-09-options-window-
	mockup.html). The model (optionsmodel.lua) turns the tree into pages, tabs,
	a picker, sections and rows; the widgets (optionswidgets.lua) draw the rows'
	controls. This file owns the frame, navigation, search, the footer and the
	keyboard.

	  OW:Open(path, root)   shows the window (root: the tree, kept for later
	                        opens), at the page, picker, tab and subtab a path
	                        of option keys names (OM.SelectionForPath).
	                        Refuses in combat (false).
	  OW:Close(), OW:IsShown(), OW:GetFrame()
	  OW:Navigate(pageKey, selection)   a page; selection { tab, subtab, pick }
	  OW:Render()           draws the current page again
	  OW:SetRoot(root)      a new tree (a profile change), drawn next frame
	  OW:SetStatus(text)    the footer's status line (validate errors)
	  OW:GetFooter()        the footer region between Reload UI and Close, for
	                        edit mode's controls
	  OW:UpdateFonts()      the profile's faces again (a profile change)

	The window (1040x700, the thick template, FULLSCREEN_DIALOG like the old
	AceGUI window, so edit mode's outlines draw under it):
	  - the sidebar: Edit mode and the st.Config:AddCommand buttons, then Global
	    Settings and Profiles, then the module pages under their category
	    (Frames, Combat, Info, any other, then Other; OW.SidebarEntries);
	  - the header: the page's title and description, and the close X
	    (st:CreateCloseButton). Dragging it (or the sidebar's title) moves the
	    window, and where it was left is kept in st.config.global.optionsWindow;
	  - the tab row, with the search box at its right; a second row for
	    subtabs; the picker row; the body, a scroll frame of sections
	    (OW.LayoutSections) of two-column rows (OW.LayoutRows);
	  - the footer: Reload UI, the region, the status line, Close.

	Re-rendering redraws the whole page from the model, keeping the page, tab,
	subtab and pick (and the scroll) when they still exist:
	  - straight away after the window's own set, except mid-drag (a slider's
	    onChanged says so; the render waits for the mouse to be let go) and
	    while Blizzard's color picker is open;
	  - on AceConfigRegistry's ConfigTableChange for st.name (st.Config:Refresh),
	    on the next frame, several in one frame coalesced. Never during a render
	    (a get may notify, as UF's profile select's does), and not while the user
	    is busy: a list or confirm dialog open, a drag, the color picker, typing in
	    one of the window's boxes. It waits for that to end.

	Search waits for typing to pause (SEARCH_DELAY), then shows OM.Search's
	results as a page of sections (page > tabs, then the section); clicking one
	opens its page and brings the row into view.

	Esc closes the window through a SaftUI keyboard catcher that is on only
	while the window is shown (not Blizzard's UISpecialFrames). It passes every
	other key on, and Esc too while a box has the keyboard. In combat it does
	nothing (SetPropagateKeyboardInput is protected); the window is closed then
	anyway (st.Config's PLAYER_REGEN_DISABLED), and opening refuses.

	Every frame and texture here is SaftUI's; nothing is written onto Blizzard
	frames or tables. GameTooltip shows a row's desc through its public API.
]]

local OW = {}
st.OptionsWindow = OW

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format, tremove = string.format, table.remove

------------------------------------------------------------------ the mockup's numbers

local WIDTH, HEIGHT = 1040, 700
local SIDEBAR_WIDTH = 210
local MAIN_WIDTH = WIDTH - SIDEBAR_WIDTH - 2 -- inside the window's border
local FOOTER_HEIGHT = 46
local PAD = 28 -- the main column's left padding
local CONTENT_WIDTH = 774 -- the body: two columns of 367 with a gap of 40
local RIGHT_PAD = MAIN_WIDTH - PAD - CONTENT_WIDTH
local COLUMN_GAP = 40
local COLUMN_WIDTH = (CONTENT_WIDTH - COLUMN_GAP) / 2
local ROW_HEIGHT = 34
local LABEL_GAP = 10
local FIELD_HEIGHT = 24

local HEAD_TOP = 20 -- the title's top, in the main column
local TABS_TOP = 87 -- the first tab line's top
local TAB_HEIGHT, TAB_GAP, TAB_WRAP_GAP, SUBTAB_GAP = 24, 22, 6, 10
local SEARCH_WIDTH, SEARCH_DELAY = 190, 0.25
local PICKER_GAP = 12

-- Sections, in the body (OW.LayoutSections).
local BODY_TOP, BODY_BOTTOM = 4, 24
local SECTION_PAD, SECTION_MARGIN = 16, 14
local TITLE_HEIGHT, TITLE_GAP = 15, 6
local NOTE_HEIGHT, NOTE_GAP = 13, 4
local CONTINUE_GAP = 4 -- an untitled section after another: a continuation
local SCROLL_STEP = ROW_HEIGHT * 2

-- The sidebar.
local BRAND_HEIGHT = 73
local ACTION_PAD, ACTION_GAP, ACTION_HEIGHT = 10, 6, 24
local ACTION_WIDTH = floor((SIDEBAR_WIDTH - 3 - 24 - ACTION_GAP) / 2)
local NAV_ITEM, NAV_GROUP, NAV_TOP = 26, 29, 6
local FOOT_HEIGHT = 30

local LINE = { 0.18, 0.18, 0.18, 1 } -- #2e2e2e: the lines between parts
local SIDEBAR_BG = { 0.09, 0.09, 0.09, 1 } -- #171717
local HOVER = { 0.133, 0.133, 0.133, 1 } -- #222

local CATEGORIES = { 'Frames', 'Combat', 'Info' } -- then any others, then Other
local POINTS = {
	TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
	BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local EMPTY = {}

------------------------------------------------------------------ the pure layout

-- Places rows in two columns: a normal row takes the next column (1, then 2),
-- a full row a line of its own. A line is as tall as its tallest row
-- (heightOf(row), ROW_HEIGHT without it). Returns { {row, col = 1|2|'full',
-- y} } and the height of them all.
function OW.LayoutRows(rows, heightOf)
	local placed, y, col, lineHeight = {}, 0, 1, 0
	local function NextLine()
		y, col, lineHeight = y + lineHeight, 1, 0
	end
	for _, row in ipairs(rows) do
		local height = heightOf and heightOf(row) or ROW_HEIGHT
		if row.width == 'full' then
			if col == 2 then NextLine() end
			placed[#placed + 1] = { row = row, col = 'full', y = y }
			lineHeight = height
			NextLine()
		else
			placed[#placed + 1] = { row = row, col = col, y = y }
			lineHeight = max(lineHeight, height)
			if col == 1 then col = 2 else NextLine() end
		end
	end
	if col == 2 then NextLine() end
	return placed, y
end

-- Places sections down the body: { {section, lineY, titleY, noteY, rowsY,
-- placed} } and the body's height. Sections after the first are separated by
-- a line; an untitled one (rows that follow a nested group) gets none, so it
-- reads as a continuation of the one above.
function OW.LayoutSections(sections, heightOf)
	local laid, y = {}, BODY_TOP
	for i, section in ipairs(sections) do
		local entry = { section = section }
		if i == 1 then
			y = y + SECTION_PAD
		elseif section.title then
			y = y + SECTION_MARGIN
			entry.lineY = y
			y = y + 1 + SECTION_PAD
		else
			y = y + CONTINUE_GAP
		end
		if section.title then
			entry.titleY = y
			y = y + TITLE_HEIGHT + TITLE_GAP
		end
		if section.note then
			entry.noteY = y - 2
			y = y + NOTE_HEIGHT + NOTE_GAP
		end
		entry.rowsY = y
		local placed, height = OW.LayoutRows(section.rows, heightOf)
		entry.placed = placed
		y = y + height
		laid[#laid + 1] = entry
	end
	return laid, y + BODY_BOTTOM
end

-- The sidebar's entries from OM.Pages: Global Settings and Profiles, then a
-- { group = category } header and its pages for each category, in the fixed
-- order. Pages keep the order they came in (order, then name).
function OW.SidebarEntries(pages)
	local entries, byCategory, others = {}, {}, {}
	for _, special in ipairs({ 'global', 'profiles' }) do
		for _, page in ipairs(pages) do
			if page.special == special then entries[#entries + 1] = page end
		end
	end
	local fixed = { Other = true }
	for _, category in ipairs(CATEGORIES) do fixed[category] = true end
	for _, page in ipairs(pages) do
		if not page.special then
			local category = tostring(page.category or 'Other')
			if not byCategory[category] then
				byCategory[category] = {}
				if not fixed[category] then others[#others + 1] = category end
			end
			local list = byCategory[category]
			list[#list + 1] = page
		end
	end
	table.sort(others)
	local order = {}
	for _, category in ipairs(CATEGORIES) do order[#order + 1] = category end
	for _, category in ipairs(others) do order[#order + 1] = category end
	order[#order + 1] = 'Other'
	for _, category in ipairs(order) do
		if byCategory[category] then
			entries[#entries + 1] = { group = category }
			for _, page in ipairs(byCategory[category]) do entries[#entries + 1] = page end
		end
	end
	return entries
end

------------------------------------------------------------------ state

local F = {} -- the window's frames (OW.GetFrames, for tests)
local root -- the tree drawn: Config:GetOptionsTable()'s args
local state = { page = nil, selections = {}, search = '' } -- what the user chose
local shown = {} -- what the last render drew: page, tab, subtab, pick
local results -- the current search's results
local cells = {} -- the body's drawn rows: { row, frame, widget, label, height, y }
local rendering, pending, dragging = false, false, false
local searchDue -- seconds until the search runs
local focusPath -- a search result's path, brought into view by the next render
local scrollOffset, contentHeight, navOffset, navHeight = 0, 0, 0, 0
local renders = 0

local function Colors() return st.config.profile.colors end
local function Normal() return Colors().text.normal:GetRGB() end
local function Grey() return Colors().text.grey:GetRGB() end
local function Blue() return Colors().button.blue:GetRGB() end

local function Copy(t)
	local copy = {}
	for k, v in pairs(t or EMPTY) do copy[k] = v end
	return copy
end

------------------------------------------------------------------ fonts

-- The window's own font objects: the profile's title (Colus) and normal
-- (Agency FB) faces and outlines, at the window's sizes. 'field' is the
-- widgets' (15).
local FONTS = {
	title = { 'title', 34 }, brand = { 'title', 26 }, section = { 'title', 15 }, group = { 'title', 13 },
	tab = { 'normal', 17 }, label = { 'normal', 16 }, small = { 'normal', 13 },
}
local fontObjects = {}

local function ApplyFont(key)
	local face, size = FONTS[key][1], FONTS[key][2]
	local config = st.config.profile.fonts[face]
	fontObjects[key]:SetFont(st.LSM:Fetch('font', config.font_name), size, config.font_outline)
	fontObjects[key]:SetTextColor(Normal())
end

local function Font(key)
	if key == 'field' then return W.GetFont() end
	if not fontObjects[key] then
		local name = 'SaftUI_Options' .. key:gsub('^%l', string.upper) .. 'Font'
		fontObjects[key] = _G[name] or CreateFont(name)
		ApplyFont(key)
	end
	return fontObjects[key]
end

function OW:UpdateFonts()
	for key in pairs(fontObjects) do ApplyFont(key) end
	W.UpdateFonts()
end

------------------------------------------------------------------ small pieces

local function Text(parent, font, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(Font(font))
	fs:SetJustifyH(justify or 'LEFT')
	fs:SetWordWrap(false)
	return fs
end

local function Line(parent)
	local line = parent:CreateTexture(nil, 'ARTWORK')
	line:SetColorTexture(unpack(LINE))
	return line
end

-- A line along the bottom (or top) of frame.
local function EdgeLine(frame, side)
	local line = Line(frame)
	line:SetPoint(side .. 'LEFT', frame, side .. 'LEFT', 0, 0)
	line:SetPoint(side .. 'RIGHT', frame, side .. 'RIGHT', 0, 0)
	line:SetHeight(1)
	return line
end

-- The mockup's button: the window's fill, a 1px border (blue on hover) and
-- the dark line outside it.
local function Button(parent, label, onClick)
	local button = W.Box(st:CreateFrame('Button', nil, parent), st.BOX_COLORS.bg)
	button.label = label
	button.text = Text(button, 'field', 'CENTER')
	button.text:SetPoint('CENTER', button, 'CENTER', 0, 0)
	button.text:SetText(label)
	W.HoverEdge(button, function() return false end)
	button:SetScript('OnMouseDown', function(self) self.text:SetPoint('CENTER', self, 'CENTER', 0, -1) end)
	button:SetScript('OnMouseUp', function(self) self.text:SetPoint('CENTER', self, 'CENTER', 0, 0) end)
	button:SetScript('OnClick', onClick)
	button:SetSize(max(80, ceil(button.text:GetStringWidth()) + 28), 26)
	return button
end

-- Pools of frames, font strings or textures, handed out per render.
local function Pool(make) return { make = make, free = {}, used = {} } end

local function Acquire(pool)
	local object = tremove(pool.free) or pool.make()
	pool.used[#pool.used + 1] = object
	object:ClearAllPoints()
	object:Show()
	return object
end

local function ReleaseAll(pool)
	for i = #pool.used, 1, -1 do
		local object = pool.used[i]
		pool.used[i] = nil
		object:Hide()
		object:ClearAllPoints()
		pool.free[#pool.free + 1] = object
	end
end

local pools = {}

local function Inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

------------------------------------------------------------------ position

local function SavedPosition()
	local saved = st.config.global.optionsWindow
	if type(saved) == 'table' and POINTS[saved.point] and type(saved.x) == 'number' and type(saved.y) == 'number' then
		return saved.point, saved.x, saved.y
	end
	return 'CENTER', 0, 0
end

local function RestorePosition()
	local point, x, y = SavedPosition()
	F.window:ClearAllPoints()
	F.window:SetPoint(point, UIParent, point, x, y)
end

-- Where the user left the window, as its center's offset from the screen's,
-- in whole units (pixels, at SaftUI's scale).
local function SavePosition()
	local cx, cy = F.window:GetCenter()
	local ux, uy = UIParent:GetCenter()
	if not (cx and ux) then return end
	st.config.global.optionsWindow = { point = 'CENTER', x = floor(cx - ux + 0.5), y = floor(cy - uy + 0.5) }
	RestorePosition()
end

local function Draggable(frame)
	frame:EnableMouse(true)
	frame:RegisterForDrag('LeftButton')
	frame:SetScript('OnDragStart', function() F.window:StartMoving() end)
	frame:SetScript('OnDragStop', function()
		F.window:StopMovingOrSizing()
		SavePosition()
	end)
end

------------------------------------------------------------------ scrolling

local function SetScroll(offset)
	local view = F.body:GetHeight() or 0
	local range = max(0, contentHeight - view)
	scrollOffset = max(0, min(range, floor(offset + 0.5)))
	F.body:SetVerticalScroll(scrollOffset)
	if range > 0 and view > 0 then
		local size = max(20, floor(view * view / contentHeight))
		F.bar:SetHeight(size)
		F.bar:ClearAllPoints()
		F.bar:SetPoint('TOPLEFT', F.body, 'TOPRIGHT', 10, -floor((view - size) * scrollOffset / range))
		F.bar:Show()
	else
		F.bar:Hide()
	end
end

local function SetNavScroll(offset)
	local range = max(0, navHeight - (F.navFrame:GetHeight() or 0))
	navOffset = max(0, min(range, floor(offset + 0.5)))
	F.navFrame:SetVerticalScroll(navOffset)
end

------------------------------------------------------------------ re-rendering

-- Whether the user is in the middle of something a render would break.
local function Busy()
	if dragging or W.ListOwner() or W.ConfirmText() then return true end
	if ColorPickerFrame and ColorPickerFrame:IsShown() then return true end
	local focus = GetCurrentKeyBoardFocus()
	return focus ~= nil and focus ~= F.search and Inside(focus, F.window)
end

-- A render on the next frame that isn't busy.
local function Schedule()
	if not OW:IsShown() then return end
	pending = true
	F.ticker:Show()
end

-- A widget's onChanged. A failed validate shows its message and changed
-- nothing; anything else re-renders, after the drag if there is one.
local function Changed(ok, err, isDragging)
	OW:SetStatus(ok == false and err or nil)
	if ok == false and err then return end
	if isDragging then
		dragging = true
		return
	end
	dragging = false
	if ColorPickerFrame and ColorPickerFrame:IsShown() then
		Schedule()
	else
		OW:Render()
	end
end

------------------------------------------------------------------ search

local function ClearSearch()
	state.search, results, searchDue = '', nil, nil
	if F.search then
		F.search:ClearFocus()
		F.search:SetText('')
		F.search.hint:Show()
	end
end

local function RunSearch()
	searchDue = nil
	local text = strtrim(F.search:GetText())
	if text == '' or text == state.search then return end
	state.search = text
	results = OM.Search(root, text)
	scrollOffset = 0
	OW:Render()
end

local function SearchChanged(box)
	box.hint:SetShown(box:GetText() == '' and not box:HasFocus())
	local text = strtrim(box:GetText())
	if text == state.search then
		searchDue = nil
	elseif text == '' then
		-- Cleared: the page comes back at once.
		state.search, results, searchDue = '', nil, nil
		scrollOffset = 0
		OW:Render()
	else
		searchDue = SEARCH_DELAY
		F.ticker:Show()
	end
end

-- A search result: its page, picker and tabs, with the row brought into view.
local function GoTo(path)
	local pageKey, selection = OM.SelectionForPath(root, path)
	if not pageKey then return end
	focusPath = path
	OW:Navigate(pageKey, selection)
end

------------------------------------------------------------------ the sidebar

local function UpdateEditModeButton()
	local button = F.actions and F.actions[1]
	if not button then return end
	local EM = st.EditModeFrames
	local color = (EM and EM.active) and Colors().text.green or Colors().text.normal
	button.text:SetTextColor(color:GetRGB())
end

-- Edit mode, then every st.Config:AddCommand, two to a line.
local function DrawActions()
	local list = { { label = 'Edit mode', func = function() st.EditModeFrames:Toggle() end } }
	for _, command in ipairs(st.Config:GetCommands()) do list[#list + 1] = command end
	for i, command in ipairs(list) do
		local button = F.actions[i]
		if not button then
			button = Button(F.actionsFrame, command.label, function(self) self.func() end)
			F.actions[i] = button
		end
		button.label, button.func = command.label, command.func
		button.text:SetText(command.label)
		button:SetSize(ACTION_WIDTH, ACTION_HEIGHT)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', F.actionsFrame, 'TOPLEFT',
			12 + ((i - 1) % 2) * (ACTION_WIDTH + ACTION_GAP),
			-(ACTION_PAD + floor((i - 1) / 2) * (ACTION_HEIGHT + ACTION_GAP)))
	end
	local lines = ceil(#list / 2)
	F.actionsFrame:SetHeight(ACTION_PAD * 2 + lines * ACTION_HEIGHT + (lines - 1) * ACTION_GAP)
	UpdateEditModeButton()
end

local function StyleNavItem(item)
	if item.active then
		local r, g, b = Blue()
		item.bg:SetColorTexture(r, g, b, 0.25)
		item.bg:Show()
		item.bar:Show()
	else
		item.bg:Hide()
		item.bar:Hide()
	end
	item:SetAlpha(item.disabled and 0.4 or 1)
end

local function MakeNavItem()
	local item = CreateFrame('Button', nil, F.navContent)
	item:SetSize(SIDEBAR_WIDTH - 3, NAV_ITEM)
	item.bg = item:CreateTexture(nil, 'BACKGROUND')
	item.bg:SetAllPoints(item)
	item.bar = item:CreateTexture(nil, 'ARTWORK')
	item.bar:SetColorTexture(Blue())
	item.bar:SetPoint('TOPLEFT', item, 'TOPLEFT', 0, 0)
	item.bar:SetPoint('BOTTOMLEFT', item, 'BOTTOMLEFT', 0, 0)
	item.bar:SetWidth(2)
	item.text = Text(item, 'label')
	item.text:SetWidth(SIDEBAR_WIDTH - 3 - 22 - 8)
	item:SetScript('OnEnter', function(self)
		if self.active then return end
		self.bg:SetColorTexture(unpack(HOVER))
		self.bg:Show()
	end)
	item:SetScript('OnLeave', function(self) StyleNavItem(self) end)
	item:SetScript('OnClick', function(self)
		if not self.disabled then OW:Navigate(self.key) end
	end)
	return item
end

local function MakeNavGroup()
	local header = CreateFrame('Frame', nil, F.navContent)
	header:SetSize(SIDEBAR_WIDTH - 3, NAV_GROUP)
	header.text = Text(header, 'group')
	header.text:SetPoint('TOPLEFT', header, 'TOPLEFT', 18, -12)
	header.text:SetTextColor(Grey())
	return header
end

local function DrawSidebar(entries)
	DrawActions()
	ReleaseAll(pools.nav)
	ReleaseAll(pools.group)
	wipe(F.nav)
	local y = NAV_TOP
	for _, entry in ipairs(entries) do
		local frame
		if entry.group then
			frame = Acquire(pools.group)
			frame.group = entry.group
			frame.text:SetText(entry.group)
		else
			frame = Acquire(pools.nav)
			frame.key, frame.name, frame.disabled = entry.key, entry.name, entry.disabled
			frame.active = state.search == '' and entry.key == state.page
			frame.text:ClearAllPoints()
			frame.text:SetPoint('LEFT', frame, 'LEFT', entry.special and 18 or 22, 0)
			frame.text:SetText(entry.name)
			StyleNavItem(frame)
		end
		frame:SetPoint('TOPLEFT', F.navContent, 'TOPLEFT', 0, -y)
		y = y + frame:GetHeight()
		F.nav[#F.nav + 1] = frame
	end
	navHeight = y + 10
	F.navContent:SetHeight(navHeight)
	F.navFrame:UpdateScrollChildRect()
	SetNavScroll(navOffset)

	local r, g, b = Normal()
	F.profile:SetText(format('Profile: |cff%02x%02x%02x%s|r', floor(r * 255), floor(g * 255), floor(b * 255),
		tostring(st.config:GetCurrentProfile())))
end

------------------------------------------------------------------ tabs and the picker

local function Select(slot, key)
	local selection = state.selections[state.page] or {}
	state.selections[state.page] = selection
	selection[slot] = key
	scrollOffset = 0
	OW:SetStatus(nil)
	OW:Render()
end

local function MakeTab()
	local tab = CreateFrame('Button', nil, F.main)
	tab.text = Text(tab, 'tab')
	tab.text:SetPoint('BOTTOMLEFT', tab, 'BOTTOMLEFT', 2, 7)
	tab.underline = tab:CreateTexture(nil, 'OVERLAY')
	tab.underline:SetColorTexture(Blue())
	tab.underline:SetPoint('BOTTOMLEFT', tab, 'BOTTOMLEFT', 0, -1)
	tab.underline:SetPoint('BOTTOMRIGHT', tab, 'BOTTOMRIGHT', 0, -1)
	tab.underline:SetHeight(2)
	tab:SetScript('OnEnter', function(self)
		if not (self.active or self.disabled) then self.text:SetTextColor(Normal()) end
	end)
	tab:SetScript('OnLeave', function(self)
		if not self.active then self.text:SetTextColor(Grey()) end
	end)
	tab:SetScript('OnClick', function(self)
		if not self.disabled then Select(self.slot, self.key) end
	end)
	return tab
end

-- A row of tabs from top, wrapping onto more lines when they don't fit (the
-- first line stops short of the search box). Returns its bottom.
local function DrawTabRow(pool, list, active, top, slot)
	ReleaseAll(pool)
	local x, y = 0, top
	local limit = slot == 'tab' and (CONTENT_WIDTH - SEARCH_WIDTH - TAB_GAP) or CONTENT_WIDTH
	for _, entry in ipairs(list) do
		local tab = Acquire(pool)
		tab.key, tab.slot, tab.disabled = entry.key, slot, entry.disabled
		tab.active = entry.key == active
		tab.text:SetText(entry.name)
		local width = ceil(tab.text:GetStringWidth()) + 4
		if x > 0 and x + width > limit then
			x, y, limit = 0, y + TAB_HEIGHT + TAB_WRAP_GAP, CONTENT_WIDTH
		end
		tab:SetSize(width, TAB_HEIGHT)
		tab:SetPoint('TOPLEFT', F.main, 'TOPLEFT', PAD + x, -y)
		if tab.active then tab.text:SetTextColor(Normal()) else tab.text:SetTextColor(Grey()) end
		tab.underline:SetShown(tab.active)
		tab:SetAlpha(entry.disabled and 0.4 or 1)
		x = x + width + TAB_GAP
	end
	return y + TAB_HEIGHT
end

local function PlaceLine(line, y)
	line:ClearAllPoints()
	line:SetPoint('TOPLEFT', F.main, 'TOPLEFT', 0, -y)
	line:SetPoint('TOPRIGHT', F.main, 'TOPRIGHT', 0, -y)
	line:Show()
end

-- The picker is a select widget over a one-option tree of its own, so it
-- gets the same list (and the list's Esc and outside click).
local pickerOption = {
	type = 'select', name = '',
	get = function() return shown.pick end,
	set = function(_, key) Select('pick', key) end,
}
local pickerRoot = { picker = pickerOption }
local pickerRow = { key = 'picker', type = 'select', name = '', width = 'normal', path = { 'picker' }, option = pickerOption }
local function NoChange() end

local function HidePicker()
	F.pickerLabel:Hide()
	F.picker.frame:Hide()
end

local function DrawPicker(picker, top)
	local values, sorting = {}, {}
	for i, entry in ipairs(picker.values) do
		values[entry.key] = entry.name
		sorting[i] = entry.key
	end
	pickerOption.values, pickerOption.sorting = values, sorting
	local label = F.pickerLabel
	label:SetText(picker.name)
	label:Show()
	local w = F.picker
	w.frame:ClearAllPoints()
	w.frame:SetPoint('TOPLEFT', F.main, 'TOPLEFT', PAD + ceil(label:GetStringWidth()) + LABEL_GAP, -top)
	label:ClearAllPoints()
	label:SetPoint('RIGHT', w.frame, 'LEFT', -LABEL_GAP, 0)
	w:Bind(pickerRoot, pickerRow, NoChange)
	w.frame:Show()
	return top + FIELD_HEIGHT
end

------------------------------------------------------------------ the body

local function ShowTip(frame)
	local row = frame.row
	if not (row and row.desc and row.desc ~= '') then return end
	GameTooltip:SetOwner(frame, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(row.name, 1, 1, 1)
	GameTooltip:AddLine(row.desc, nil, nil, nil, true)
	GameTooltip:Show()
end

local function HideTip(frame)
	if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
end

local function MakeRow()
	local frame = CreateFrame('Frame', nil, F.content)
	frame:EnableMouse(true)
	frame.label = Text(frame, 'label')
	frame:SetScript('OnEnter', ShowTip)
	frame:SetScript('OnLeave', HideTip)
	return frame
end

-- A row's place in its cell: the label on the left, the control on the
-- right. A description is text across the row, and a button stands alone.
local function PlaceRow(cell, x, y, width)
	local frame, widget, label, row = cell.frame, cell.widget, cell.label, cell.row
	frame:SetPoint('TOPLEFT', F.content, 'TOPLEFT', x, -y)
	frame:SetSize(width, cell.height)
	label:ClearAllPoints()
	if row.type == 'description' then
		label:Hide()
		widget:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -6)
	elseif row.type == 'execute' then
		label:Hide()
		widget:SetPoint('LEFT', frame, 'LEFT', 0, 0)
	else
		label:SetText(row.name)
		if row.disabled then label:SetTextColor(Grey()) else label:SetTextColor(Normal()) end
		label:SetWidth(max(1, width - widget:GetWidth() - LABEL_GAP))
		label:Show()
		if cell.height > ROW_HEIGHT then
			label:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -floor((ROW_HEIGHT - 16) / 2))
			widget:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, -6)
		else
			label:SetPoint('LEFT', frame, 'LEFT', 0, 0)
			widget:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
		end
	end
end

-- A drawn row of the page: its frame and widget, and its height.
local function RowCell(row)
	if not W.WIDTH[row.type] then return nil end -- not a type the widgets draw
	local frame = Acquire(pools.row)
	frame.row = row
	local widget = W.Create(frame, row.type)
	widget:Bind(root, row, Changed)
	local cell = { row = row, frame = frame, widget = widget, label = frame.label, height = ROW_HEIGHT, place = PlaceRow }
	if row.type == 'description' then
		widget:SetWidth(CONTENT_WIDTH)
		cell.height = max(ROW_HEIGHT, ceil(widget:GetHeight()) + 12)
	elseif row.type == 'multiselect' then
		cell.height = max(ROW_HEIGHT, ceil(widget:GetHeight()) + 12)
	end
	cells[#cells + 1] = cell
	return cell
end

local function MakeResult()
	local button = CreateFrame('Button', nil, F.content)
	button.hover = button:CreateTexture(nil, 'BACKGROUND')
	button.hover:SetAllPoints(button)
	button.hover:Hide()
	button.text = Text(button, 'label')
	button.text:SetPoint('LEFT', button, 'LEFT', 8, 0)
	button:SetScript('OnEnter', function(self)
		local r, g, b = Blue()
		self.hover:SetColorTexture(r, g, b, 0.25)
		self.hover:Show()
	end)
	button:SetScript('OnLeave', function(self) self.hover:Hide() end)
	button:SetScript('OnClick', function(self) GoTo(self.row.path) end)
	return button
end

local function PlaceResult(cell, x, y, width)
	cell.frame:SetPoint('TOPLEFT', F.content, 'TOPLEFT', x, -y)
	cell.frame:SetSize(width, cell.height)
	cell.label:SetWidth(width - 16)
end

local function ResultCell(row)
	local button = Acquire(pools.result)
	button.row = row
	button.text:SetText(row.name)
	local cell = { row = row, frame = button, label = button.text, height = ROW_HEIGHT, place = PlaceResult }
	cells[#cells + 1] = cell
	return cell
end

local function ReleaseBody()
	for _, cell in ipairs(cells) do
		if cell.widget then cell.widget:Release() end
	end
	wipe(cells)
	for _, key in ipairs({ 'row', 'result', 'title', 'note', 'line' }) do ReleaseAll(pools[key]) end
	F.placeholder:Hide()
end

local function PlaceBody(top)
	F.body:ClearAllPoints()
	F.body:SetPoint('TOPLEFT', F.main, 'TOPLEFT', PAD, -top)
	F.body:SetPoint('BOTTOMRIGHT', F.main, 'BOTTOMRIGHT', -RIGHT_PAD, FOOTER_HEIGHT)
end

-- Draws sections of rows with makeCell (rows it draws nothing for are left
-- out, and so are sections left empty).
local function DrawSections(sections, makeCell)
	local byRow, kept = {}, {}
	for _, section in ipairs(sections) do
		local rows = {}
		for _, row in ipairs(section.rows) do
			local cell = makeCell(row)
			if cell then
				byRow[row] = cell
				rows[#rows + 1] = row
			end
		end
		if #rows > 0 then kept[#kept + 1] = { title = section.title, note = section.note, rows = rows } end
	end
	local laid, height = OW.LayoutSections(kept, function(row) return byRow[row].height end)
	for _, entry in ipairs(laid) do
		if entry.lineY then
			local line = Acquire(pools.line)
			line:SetPoint('TOPLEFT', F.content, 'TOPLEFT', 0, -entry.lineY)
			line:SetSize(CONTENT_WIDTH, 1)
		end
		if entry.titleY then
			local title = Acquire(pools.title)
			title:SetPoint('TOPLEFT', F.content, 'TOPLEFT', 0, -entry.titleY)
			title:SetText(entry.section.title)
		end
		if entry.noteY then
			local note = Acquire(pools.note)
			note:SetPoint('TOPLEFT', F.content, 'TOPLEFT', 0, -entry.noteY)
			note:SetText(entry.section.note)
		end
		for _, p in ipairs(entry.placed) do
			local cell = byRow[p.row]
			cell.y = entry.rowsY + p.y
			cell.place(cell, p.col == 2 and (COLUMN_WIDTH + COLUMN_GAP) or 0, cell.y,
				p.col == 'full' and CONTENT_WIDTH or COLUMN_WIDTH)
		end
	end
	contentHeight = #kept > 0 and height or 0
end

local function SamePath(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- A search result's row, once its page is drawn: scrolled to and marked blue.
local function BringIntoView()
	local path = focusPath
	focusPath = nil
	if not path then return end
	for _, cell in ipairs(cells) do
		if cell.row.path and SamePath(cell.row.path, path) then
			scrollOffset = max(0, cell.y - ROW_HEIGHT)
			cell.label:SetTextColor(Colors().text.blue:GetRGB())
			return
		end
	end
end

local function Placeholder(text)
	F.placeholder:SetText(text)
	F.placeholder:Show()
end

------------------------------------------------------------------ pages

local function DrawPage()
	shown = { page = state.page }
	local view = state.page and OM.BuildView(root, state.page, state.selections[state.page])
	if not view then
		F.title:SetText(st.name)
		F.desc:SetText('')
		PlaceLine(F.tabLine, DrawTabRow(pools.tab, EMPTY, nil, TABS_TOP, 'tab'))
		ReleaseAll(pools.subtab)
		F.subLine:Hide()
		HidePicker()
		PlaceBody(TABS_TOP + TAB_HEIGHT)
		return
	end
	F.title:SetText(view.title)
	F.desc:SetText(view.desc or '')
	shown.tab, shown.subtab = view.tab, view.subtab
	shown.pick = view.picker and view.picker.selected

	-- A single tab is the page itself, so it isn't drawn (as in the mockup).
	local bottom = DrawTabRow(pools.tab, #view.tabs > 1 and view.tabs or EMPTY, view.tab, TABS_TOP, 'tab')
	PlaceLine(F.tabLine, bottom)
	if #view.subtabs > 1 then
		bottom = DrawTabRow(pools.subtab, view.subtabs, view.subtab, bottom + SUBTAB_GAP, 'subtab')
		PlaceLine(F.subLine, bottom)
	else
		ReleaseAll(pools.subtab)
		F.subLine:Hide()
	end
	if view.picker then
		bottom = DrawPicker(view.picker, bottom + PICKER_GAP)
	else
		HidePicker()
	end
	PlaceBody(bottom)
	DrawSections(view.sections, RowCell)
	if #cells == 0 then Placeholder('Nothing to set here.') end
	BringIntoView()
end

-- The results page: a section per page, tabs and section, in the order found.
local function DrawSearch(pages)
	shown = { page = state.page }
	local count = #results
	F.title:SetText('Search')
	F.desc:SetText(format('%d%s result%s for "%s"', count, count >= 100 and '+' or '', count == 1 and '' or 's', state.search))
	PlaceLine(F.tabLine, DrawTabRow(pools.tab, EMPTY, nil, TABS_TOP, 'tab'))
	ReleaseAll(pools.subtab)
	F.subLine:Hide()
	HidePicker()
	PlaceBody(TABS_TOP + TAB_HEIGHT)

	local names = {}
	for _, page in ipairs(pages) do names[page.key] = page.name end
	local sections, last = {}, nil
	for _, result in ipairs(results) do
		local title = tostring(names[result.pageKey] or result.pageKey)
		if result.tabName then title = title .. ' > ' .. result.tabName end
		if not (last and last.title == title and last.note == result.sectionTitle) then
			last = { title = title, note = result.sectionTitle, rows = {} }
			sections[#sections + 1] = last
		end
		last.rows[#last.rows + 1] = { key = result.path[#result.path], name = result.name, width = 'normal', path = result.path }
	end
	DrawSections(sections, ResultCell)
	if count == 0 then Placeholder(format('No settings match "%s".', state.search)) end
end

local function Draw()
	ReleaseBody()
	contentHeight = 0
	local pages = OM.Pages(root)
	local entries = OW.SidebarEntries(pages)
	local found = false
	for _, page in ipairs(pages) do
		if page.key == state.page then found = true end
	end
	if not found then
		state.page = nil
		for _, entry in ipairs(entries) do
			if entry.key and not entry.disabled then
				state.page = entry.key
				break
			end
		end
	end
	DrawSidebar(entries)
	if state.search ~= '' and results then DrawSearch(pages) else DrawPage() end
	F.content:SetHeight(max(1, contentHeight))
	F.body:UpdateScrollChildRect()
	SetScroll(scrollOffset)
end

------------------------------------------------------------------ the frame

local function OnShow()
	F.keys:Show()
	F.keys:EnableKeyboard(true)
	if not InCombatLockdown() then F.keys:SetPropagateKeyboardInput(true) end
	OW:Render()
	if st.EditModeFrames then st.EditModeFrames:UpdateFooter() end
end

local function OnHide()
	F.window:StopMovingOrSizing()
	F.keys:EnableKeyboard(false)
	F.keys:Hide()
	pending, dragging = false, false
	ClearSearch()
	ReleaseBody()
	W.CloseList()
	W.CancelConfirm()
	OW:SetStatus(nil)
	if st.EditModeFrames then st.EditModeFrames:UpdateFooter() end
end

local function BuildSidebar(window)
	local side = CreateFrame('Frame', nil, window)
	side:SetPoint('TOPLEFT', window, 'TOPLEFT', 2, -2)
	side:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 2, 2)
	side:SetWidth(SIDEBAR_WIDTH - 2)
	local bg = side:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(side)
	bg:SetColorTexture(unpack(SIDEBAR_BG))
	local edge = Line(side)
	edge:SetPoint('TOPRIGHT', side, 'TOPRIGHT', 0, 0)
	edge:SetPoint('BOTTOMRIGHT', side, 'BOTTOMRIGHT', 0, 0)
	edge:SetWidth(1)

	-- SaftUI / Options. It moves the window too.
	local brand = CreateFrame('Frame', nil, side)
	brand:SetPoint('TOPLEFT', side, 'TOPLEFT', 0, 0)
	brand:SetPoint('TOPRIGHT', side, 'TOPRIGHT', -1, 0)
	brand:SetHeight(BRAND_HEIGHT)
	Draggable(brand)
	local name = Text(brand, 'brand')
	name:SetPoint('TOPLEFT', brand, 'TOPLEFT', 18, -18)
	name:SetText(st.name)
	local sub = Text(brand, 'small')
	sub:SetPoint('TOPLEFT', name, 'BOTTOMLEFT', 0, -2)
	sub:SetTextColor(Grey())
	sub:SetText('Options')
	EdgeLine(brand, 'BOTTOM')

	local actions = CreateFrame('Frame', nil, side)
	actions:SetPoint('TOPLEFT', brand, 'BOTTOMLEFT', 0, 0)
	actions:SetPoint('TOPRIGHT', brand, 'BOTTOMRIGHT', 0, 0)
	actions:SetHeight(ACTION_PAD * 2 + ACTION_HEIGHT)
	EdgeLine(actions, 'BOTTOM')
	F.actionsFrame, F.actions = actions, {}

	-- The profile's name at the bottom.
	local foot = CreateFrame('Frame', nil, side)
	foot:SetPoint('BOTTOMLEFT', side, 'BOTTOMLEFT', 0, 0)
	foot:SetPoint('BOTTOMRIGHT', side, 'BOTTOMRIGHT', -1, 0)
	foot:SetHeight(FOOT_HEIGHT)
	EdgeLine(foot, 'TOP')
	F.profile = Text(foot, 'small')
	F.profile:SetPoint('LEFT', foot, 'LEFT', 18, 0)
	F.profile:SetWidth(SIDEBAR_WIDTH - 3 - 36)
	F.profile:SetTextColor(Grey())

	local nav = CreateFrame('ScrollFrame', nil, side)
	nav:SetPoint('TOPLEFT', actions, 'BOTTOMLEFT', 0, -1)
	nav:SetPoint('BOTTOMRIGHT', foot, 'TOPRIGHT', 0, 1)
	local content = CreateFrame('Frame', nil, nav)
	content:SetSize(SIDEBAR_WIDTH - 3, 1)
	nav:SetScrollChild(content)
	nav:EnableMouseWheel(true)
	nav:SetScript('OnMouseWheel', function(_, delta) SetNavScroll(navOffset - delta * NAV_ITEM * 2) end)
	F.navFrame, F.navContent, F.nav = nav, content, {}
	pools.nav = Pool(MakeNavItem)
	pools.group = Pool(MakeNavGroup)
end

local function BuildMain(window)
	local main = CreateFrame('Frame', nil, window)
	main:SetPoint('TOPLEFT', window, 'TOPLEFT', SIDEBAR_WIDTH, -2)
	main:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -2, 2)
	F.main = main

	-- The title area moves the window. It stops short of the close X.
	local header = CreateFrame('Frame', nil, main)
	header:SetPoint('TOPLEFT', main, 'TOPLEFT', 0, 0)
	header:SetPoint('TOPRIGHT', main, 'TOPRIGHT', -56, 0)
	header:SetHeight(TABS_TOP - 8)
	Draggable(header)
	F.header = header
	F.title = Text(header, 'title')
	F.title:SetPoint('TOPLEFT', main, 'TOPLEFT', PAD, -HEAD_TOP)
	F.title:SetWidth(CONTENT_WIDTH - 40)
	F.desc = Text(header, 'field')
	F.desc:SetPoint('TOPLEFT', F.title, 'BOTTOMLEFT', 0, -4)
	F.desc:SetWidth(CONTENT_WIDTH)
	F.desc:SetTextColor(Grey())

	local close = st:CreateCloseButton(window)
	close:ClearAllPoints()
	close:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -16, -14)
	F.close = close

	F.tabLine, F.subLine = Line(main), Line(main)
	F.tabLine:SetHeight(1)
	F.subLine:SetHeight(1)
	pools.tab, pools.subtab = Pool(MakeTab), Pool(MakeTab)
	F.tabs, F.subtabs = pools.tab.used, pools.subtab.used

	-- The search box, at the right of the first tab line.
	local search = W.Box(st:CreateFrame('EditBox', nil, main))
	search:SetSize(SEARCH_WIDTH, FIELD_HEIGHT)
	search:SetPoint('TOPRIGHT', main, 'TOPRIGHT', -RIGHT_PAD, -(TABS_TOP + TAB_HEIGHT - 6 - FIELD_HEIGHT))
	search:SetFontObject(W.GetFont())
	search:SetTextInsets(8, 8, 0, 0)
	search:SetAutoFocus(false)
	search.hint = Text(search, 'field')
	search.hint:SetPoint('LEFT', search, 'LEFT', 8, 0)
	search.hint:SetTextColor(Grey())
	search.hint:SetText('Search settings...')
	search:SetScript('OnEnter', function(self) W.Edge(self, true) end)
	search:SetScript('OnLeave', function(self) W.Edge(self, self:HasFocus()) end)
	search:SetScript('OnEditFocusGained', function(self)
		W.Edge(self, true)
		self.hint:Hide()
	end)
	search:SetScript('OnEditFocusLost', function(self)
		W.Edge(self, false)
		self.hint:SetShown(self:GetText() == '')
	end)
	search:SetScript('OnTextChanged', SearchChanged)
	search:SetScript('OnEnterPressed', function(self)
		self:ClearFocus()
		if searchDue then RunSearch() end
	end)
	search:SetScript('OnEscapePressed', function(self)
		self:ClearFocus()
		self:SetText('')
	end)
	F.search = search

	F.pickerLabel = Text(main, 'field')
	F.picker = W.Create(main, 'select')
	HidePicker()

	-- The body.
	local body = CreateFrame('ScrollFrame', nil, main)
	local content = CreateFrame('Frame', nil, body)
	content:SetSize(CONTENT_WIDTH, 1)
	body:SetScrollChild(content)
	body:EnableMouseWheel(true)
	body:SetScript('OnMouseWheel', function(_, delta) SetScroll(scrollOffset - delta * SCROLL_STEP) end)
	F.body, F.content = body, content
	PlaceBody(TABS_TOP + TAB_HEIGHT)
	F.bar = main:CreateTexture(nil, 'OVERLAY')
	F.bar:SetColorTexture(unpack(st.BOX_COLORS.edge))
	F.bar:SetWidth(3)
	F.bar:Hide()
	F.placeholder = Text(content, 'label')
	F.placeholder:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -(BODY_TOP + SECTION_PAD))
	F.placeholder:SetTextColor(Grey())
	F.placeholder:Hide()

	pools.row = Pool(MakeRow)
	pools.result = Pool(MakeResult)
	pools.line = Pool(function() return Line(content) end)
	pools.title = Pool(function()
		local title = Text(content, 'section')
		title:SetTextColor(Grey())
		title:SetWidth(CONTENT_WIDTH)
		return title
	end)
	pools.note = Pool(function()
		local note = Text(content, 'small')
		note:SetTextColor(Grey())
		note:SetWidth(CONTENT_WIDTH)
		return note
	end)
end

local function BuildFooter()
	local footer = CreateFrame('Frame', nil, F.main)
	footer:SetPoint('BOTTOMLEFT', F.main, 'BOTTOMLEFT', 0, 0)
	footer:SetPoint('BOTTOMRIGHT', F.main, 'BOTTOMRIGHT', 0, 0)
	footer:SetHeight(FOOTER_HEIGHT)
	EdgeLine(footer, 'TOP')

	F.reloadButton = Button(footer, 'Reload UI', function() ReloadUI() end)
	F.reloadButton:SetPoint('LEFT', footer, 'LEFT', PAD, 0)
	F.closeButton = Button(footer, 'Close', function() OW:Close() end)
	F.closeButton:SetPoint('RIGHT', footer, 'RIGHT', -RIGHT_PAD, 0)

	-- Edit mode's controls go here (from the left); the status line shows
	-- validate errors (from the right).
	local region = CreateFrame('Frame', nil, footer)
	region:SetPoint('LEFT', F.reloadButton, 'RIGHT', 12, 0)
	region:SetPoint('RIGHT', F.closeButton, 'LEFT', -12, 0)
	region:SetHeight(26)
	F.footerRegion = region
	F.status = Text(footer, 'field', 'RIGHT')
	F.status:SetPoint('LEFT', region, 'LEFT', 0, 0)
	F.status:SetPoint('RIGHT', region, 'RIGHT', 0, 0)
	F.status:SetTextColor(Colors().text.red:GetRGB())
end

local function Build()
	local window = st:CreateFrame('Frame', nil, UIParent)
	window:SetFrameStrata('FULLSCREEN_DIALOG')
	window:SetFrameLevel(100)
	window:SetSize(WIDTH, HEIGHT)
	window:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	window:SetMovable(true)
	window:SetClampedToScreen(true)
	window:EnableMouse(true)
	window:Hide()
	st:SetTemplate(window, 'thick')
	F.window = window
	W.SetDialogAnchor(window)

	BuildSidebar(window)
	BuildMain(window)
	BuildFooter()

	-- Esc, only while the window is shown.
	local keys = CreateFrame('Frame', nil, window)
	keys:Hide()
	keys:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		if GetCurrentKeyBoardFocus() then
			self:SetPropagateKeyboardInput(true)
			return
		end
		local escape = key == 'ESCAPE'
		self:SetPropagateKeyboardInput(not escape)
		if escape then OW:Close() end
	end)
	F.keys = keys

	-- The frame clock: deferred renders and the search's wait. Shown only
	-- while one is due.
	local ticker = CreateFrame('Frame', nil, window)
	ticker:Hide()
	ticker:SetScript('OnUpdate', function(self, elapsed)
		if searchDue then
			searchDue = searchDue - elapsed
			if searchDue <= 0 then RunSearch() end
		end
		if pending and not Busy() then OW:Render() end
		if not (pending or searchDue) then self:Hide() end
	end)
	F.ticker = ticker

	window:SetScript('OnShow', OnShow)
	window:SetScript('OnHide', OnHide)
	local EM = st.EditModeFrames
	if EM then
		EM:On('Enabled', UpdateEditModeButton)
		EM:On('Disabled', UpdateEditModeButton)
	end
end

------------------------------------------------------------------ the API

function OW:IsShown()
	return F.window ~= nil and F.window:IsShown()
end

function OW:GetFrame()
	return F.window
end

function OW:GetRoot()
	return root
end

-- Shows the window at path (a list of option keys, e.g. { 'Unitframes',
-- 'player', 'general' }; empty keeps the page it was on). root is the tree to
-- draw, kept for the next open. False in combat.
function OW:Open(path, tree)
	if InCombatLockdown() then return false end
	if tree then root = tree end
	if not root then error('SaftUI options: no option tree to draw', 2) end
	if not F.window then Build() end
	if path and #path > 0 then
		local pageKey, selection = OM.SelectionForPath(root, path)
		if pageKey then
			state.page = pageKey
			state.selections[pageKey] = selection
			scrollOffset = 0
			if state.search ~= '' then ClearSearch() end
		end
	end
	if F.window:IsShown() then
		self:Render()
	else
		RestorePosition()
		F.window:Show() -- OnShow draws it
	end
	return true
end

function OW:Close()
	if self:IsShown() then F.window:Hide() end
end

-- Opens pageKey with selection ({ tab, subtab, pick }; nil keeps the one it
-- had), leaving search.
function OW:Navigate(pageKey, selection)
	state.page = pageKey
	if selection then state.selections[pageKey] = Copy(selection) end
	if state.search ~= '' then ClearSearch() end
	scrollOffset = 0
	self:SetStatus(nil)
	self:Render()
end

-- Draws the page (or search results) again from the model.
function OW:Render()
	if rendering or not self:IsShown() or not root then return end
	rendering, pending = true, false
	xpcall(Draw, geterrorhandler())
	rendering = false
	renders = renders + 1
end

-- A new tree (a profile change rebuilt it), drawn on the next frame.
function OW:SetRoot(tree)
	root = tree
	Schedule()
end

function OW:SetStatus(text)
	if F.status then F.status:SetText(text or '') end
end

function OW:GetFooter()
	if not F.window then Build() end
	return F.footerRegion
end

-- What the last render drew: { page, tab, subtab, pick, search }.
function OW:GetState()
	return { page = shown.page, tab = shown.tab, subtab = shown.subtab, pick = shown.pick, search = state.search }
end

-- For tests: the frames, the drawn body rows, how many renders ran.
function OW.GetFrames() return F end
function OW.GetDrawnRows() return cells end
function OW.GetRenderCount() return renders end

-- st.Config:Refresh notifies AceConfigRegistry: re-render on the next frame.
LibStub('AceConfigRegistry-3.0').RegisterCallback(OW, 'ConfigTableChange', function(_, appName)
	if appName == st.name and not rendering then Schedule() end
end)
