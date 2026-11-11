local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

--[[
	SaftUI's options window: /sui, drawn by SaftUI from the modules' Ace
	option tables (the tree st.Config:GetOptionsTable() builds), laid out as the
	approved mockup (docs/superpowers/specs/assets/2026-11-09-options-window-
	mockup.html). The model (optionsmodel.lua) turns the tree into pages, tabs,
	a picker, sections and rows; the body (optionsbody.lua) draws the sections
	and rows, and the widgets (optionswidgets.lua) the rows' controls. This file
	owns the frame, navigation, search, the footer and the keyboard.

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
	  OW:SetFooterInset(w)  the status line starts w into the region, clear of
	                        them
	  OW:UpdateFonts()      the profile's faces again (a profile change)
	  OW:OpenDialog(title, options), OW:CloseDialog(), OW:IsDialogShown()
	                        a small dialog over the window for an option table
	                        of its own (UF's Copy from; "a small dialog" below)

	The window (1040x700, SaftUI's theme with a solid background,
	FULLSCREEN_DIALOG, so edit mode's outlines draw under it):
	  - the sidebar: Edit mode and the st.Config:AddCommand buttons, then Global
	    Settings and Profiles, then the module pages under their category
	    (Frames, Combat, Info, any other, then Other; OW.SidebarEntries);
	  - the header: the page's title and description, and the close X
	    (st:CreateCloseButton). Dragging it (or the sidebar's title) moves the
	    window, and where it was left is kept in st.config.global.optionsWindow;
	  - the tab row, with the search box at its right; a second row for
	    subtabs; the picker row; the body, a scroll frame of sections
	    (OB.LayoutSections) of rows in quarters, halves and whole lines
	    (OB.LayoutRows), drawn by an OB.New body;
	  - the footer: Reload UI, the region, the status line, Close.

	Re-rendering redraws the whole page from the model, keeping the page, tab,
	subtab and pick (and the scroll) when they still exist:
	  - straight away after the window's own set, except mid-drag (a slider's
	    onChanged says so; the render waits for the mouse to be let go) and
	    while Blizzard's color picker is open. Mid-drag, each set refreshes
	    the other drawn widgets in place instead (body:Refresh): their values,
	    a description's image, and whether they're disabled follow the drag,
	    while rows that would show or hide wait for the render;
	  - on AceConfigRegistry's ConfigTableChange for st.name (st.Config:Refresh),
	    on the next frame, several in one frame coalesced. Never during a render
	    (a get may notify, as UF's profile select's does), and not while the user
	    is busy: a list or confirm dialog open, a drag, the color picker, typing in
	    one of the window's boxes. It waits for that to end.

	Search waits for typing to pause (SEARCH_DELAY), then shows OM.Search's
	results as a page of sections (page > tabs, then the section); clicking one
	opens its page and brings the row into view. Going to a page, tab or pick
	clears the search, one still waiting for the typing to pause too.

	Esc closes the window through a SaftUI keyboard catcher that is on only
	while the window is shown (not Blizzard's UISpecialFrames). It passes every
	other key on, and Esc too while a box has the keyboard, the dialog is
	shown or Blizzard's color picker is open. In combat it does
	nothing (SetPropagateKeyboardInput is protected); the window is closed then
	anyway (st.Config's PLAYER_REGEN_DISABLED), and opening refuses.

	Every frame and texture here is SaftUI's; nothing is written onto Blizzard
	frames or tables.
]]

local OW = {}
st.OptionsWindow = OW

local floor, max, min, ceil = math.floor, math.max, math.min, math.ceil
local format = string.format

------------------------------------------------------------------ the mockup's numbers

local WIDTH, HEIGHT = 1040, 700
local SIDEBAR_WIDTH = 210
local MAIN_WIDTH = WIDTH - SIDEBAR_WIDTH - 2 -- inside the window's border
local FOOTER_HEIGHT = 46
local PAD = 28 -- the main column's left padding
local CONTENT_WIDTH = OB.WIDTH -- the body: two columns of 367 with a gap of 40
local RIGHT_PAD = MAIN_WIDTH - PAD - CONTENT_WIDTH
local ROW_HEIGHT = OB.ROW_HEIGHT
local LABEL_GAP = OB.LABEL_GAP
local FIELD_HEIGHT = 24

local HEAD_TOP = 20 -- the title's top, in the main column
local TABS_TOP = 87 -- the first tab line's top
local TAB_HEIGHT, TAB_GAP, TAB_WRAP_GAP, SUBTAB_GAP = 24, 22, 6, 10
local SEARCH_WIDTH, SEARCH_DELAY = 190, 0.25
local SEARCH_TEXT_INSET = 8 -- the search box's text, in from its edges, and its hint
local PICKER_GAP = 12

local SCROLL_STEP = ROW_HEIGHT * 2

-- The sidebar.
local BRAND_HEIGHT = 73
local ACTION_PAD, ACTION_GAP, ACTION_HEIGHT = 10, 6, 24
local ACTION_WIDTH = floor((SIDEBAR_WIDTH - 3 - 24 - ACTION_GAP) / 2)
local NAV_ITEM, NAV_GROUP, NAV_TOP = 26, 29, 6
local FOOT_HEIGHT = 30

local SIDEBAR_BG = { 0.09, 0.09, 0.09, 1 } -- #171717
local HOVER = { 0.133, 0.133, 0.133, 1 } -- #222

local CATEGORIES = { 'Frames', 'Combat', 'Info' } -- then any others, then Other
local POINTS = {
	TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
	BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local EMPTY = {}

------------------------------------------------------------------ the pure layout

-- The body's layout (optionsbody.lua), here too for the window's tests.
OW.LayoutRows, OW.LayoutSections = OB.LayoutRows, OB.LayoutSections

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
local pageBody -- the body (OB.New) the page is drawn in: its cells are the drawn rows
local rendering, pending, dragging = false, false, false
local searchDue -- seconds until the search runs
local focusPath -- a search result's path, brought into view by the next render
local scrollOffset, contentHeight, navOffset, navHeight = 0, 0, 0, 0
local renders = 0
-- Whether the window draws its controls in Blizzard's Settings art: under
-- SaftUI's theme Blizzard (W.BlizzardLook), read once a render, so a theme
-- change reaches them when the window renders again. Under Thick and Thin
-- they keep the mockup's look.
local blizzard = false

local function Colors() return st.config.profile.colors end
local function Normal() return Colors().text.normal:GetRGB() end
local function Grey() return Colors().text.grey:GetRGB() end
local function Blue() return Colors().button.blue:GetRGB() end

local function Copy(t)
	local copy = {}
	for k, v in pairs(t or EMPTY) do copy[k] = v end
	return copy
end

------------------------------------------------------------------ small pieces

-- The window's fonts and pieces (optionsbody.lua).
local Text, Line, Pool, Acquire, ReleaseAll = OB.Text, OB.Line, OB.Pool, OB.Acquire, OB.ReleaseAll

function OW:UpdateFonts()
	OB.UpdateFonts()
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
-- the dark line outside it. Under Blizzard it's Blizzard's panel button
-- (W.LookButton, put on as it's drawn).
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

-- Scrolls frame (a scroll frame) to offset, within the height of what it
-- holds, and places its bar 10 to its right. Returns the offset it took.
local function ScrollTo(frame, bar, offset, height)
	local view = frame:GetHeight() or 0
	local range = max(0, height - view)
	offset = max(0, min(range, floor(offset + 0.5)))
	frame:SetVerticalScroll(offset)
	if range > 0 and view > 0 then
		local size = max(20, floor(view * view / height))
		bar:SetHeight(size)
		bar:ClearAllPoints()
		bar:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 10, -floor((view - size) * offset / range))
		bar:Show()
	else
		bar:Hide()
	end
	return offset
end

local function SetScroll(offset)
	scrollOffset = ScrollTo(F.body, F.bar, offset, contentHeight)
end

local function SetNavScroll(offset)
	local range = max(0, navHeight - (F.navFrame:GetHeight() or 0))
	navOffset = max(0, min(range, floor(offset + 0.5)))
	F.navFrame:SetVerticalScroll(navOffset)
end

------------------------------------------------------------------ re-rendering

-- Whether the user is in the middle of something a render would break.
local function Busy()
	-- A drag ends when the button comes up, even if the slider's OnMouseUp
	-- never arrived.
	if dragging and not IsMouseButtonDown('LeftButton') then dragging = false end
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
local function Changed(ok, err, isDragging, widget)
	OW:SetStatus(ok == false and err or nil)
	if ok == false and err then return end
	if isDragging then
		-- The render waits for the drag; Schedule keeps the clock running so a
		-- lost OnMouseUp can't hold it off for good (see Busy).
		dragging = true
		Schedule()
		-- Meanwhile the other rows follow the drag in place (a preview of the
		-- value, a row it disables), leaving the dragged slider be.
		xpcall(function() pageBody:Refresh(widget) end, geterrorhandler())
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
		W.LookButton(button, blizzard, st.BOX_COLORS.bg)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', F.actionsFrame, 'TOPLEFT',
			12 + ((i - 1) % 2) * (ACTION_WIDTH + ACTION_GAP),
			-(ACTION_PAD + floor((i - 1) / 2) * (ACTION_HEIGHT + ACTION_GAP)))
	end
	local lines = ceil(#list / 2)
	F.actionsFrame:SetHeight(ACTION_PAD * 2 + lines * ACTION_HEIGHT + (lines - 1) * ACTION_GAP)
	UpdateEditModeButton()
end

-- A sidebar entry's look: the open page's blue fill and bar, or under
-- Blizzard (item.blizzard) the Settings panel's category list, the open page
-- on its picked art (item.listPicked); the one under the mouse is lit by
-- OnEnter (item.listHover).
local function StyleNavItem(item)
	item.listHover:Hide()
	item.listPicked:SetShown(item.blizzard and item.active or false)
	if item.active and not item.blizzard then
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
	-- Under Blizzard, the Settings panel's category list: the open page's
	-- art, and the art under the mouse (their atlases set as it's drawn).
	item.listPicked = item:CreateTexture(nil, 'BACKGROUND')
	item.listPicked:SetAllPoints(item)
	item.listPicked:Hide()
	item.listHover = item:CreateTexture(nil, 'BACKGROUND')
	item.listHover:SetAllPoints(item)
	item.listHover:Hide()
	item.text = Text(item, 'label')
	item.text:SetWidth(SIDEBAR_WIDTH - 3 - 22 - 8)
	item:SetScript('OnEnter', function(self)
		if self.active then return end
		if self.blizzard then
			self.listHover:Show()
			return
		end
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
	local look = blizzard and st.ThemeArt.Control('optionslist')
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
			frame.blizzard = look and true or false
			if look then
				frame.listPicked:SetAtlas(look.picked)
				frame.listHover:SetAtlas(look.hover)
			end
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
	if state.search ~= '' or searchDue then ClearSearch() end
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

-- A tab's art under Blizzard: the Settings panel's tab (look,
-- st.ThemeArt.Control('optionstab')), the picked one for the active tab, at
-- its art's height (at most the tab's) along the tab's bottom, in place of
-- the blue underline. None under Thick and Thin (look nil).
local function LookTab(tab, look)
	if not look then
		W.HideArt(tab)
		return
	end
	local set = tab.active and look.picked or look.other
	local _, height = W.AtlasSize(set.left)
	W.LayThree(tab, set, 'BACKGROUND', min(height or TAB_HEIGHT, TAB_HEIGHT), 'BOTTOM')
end

-- A row of tabs from top, wrapping onto more lines when they don't fit (the
-- first line stops short of the search box). Returns its bottom.
local function DrawTabRow(pool, list, active, top, slot)
	ReleaseAll(pool)
	local look = blizzard and st.ThemeArt.Control('optionstab')
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
		tab.underline:SetShown(tab.active and not blizzard)
		LookTab(tab, look)
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
local pickerRow = { key = 'picker', type = 'select', name = '', size = 'normal', path = { 'picker' }, option = pickerOption }
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

local function ReleaseBody()
	pageBody:Release()
	F.placeholder:Hide()
end

local function PlaceBody(top)
	F.body:ClearAllPoints()
	F.body:SetPoint('TOPLEFT', F.main, 'TOPLEFT', PAD, -top)
	F.body:SetPoint('BOTTOMRIGHT', F.main, 'BOTTOMRIGHT', -RIGHT_PAD, FOOTER_HEIGHT)
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
	for _, cell in ipairs(pageBody.cells) do
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
	contentHeight = pageBody:Draw(view.sections)
	if #pageBody.cells == 0 then Placeholder('Nothing to set here.') end
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
		last.rows[#last.rows + 1] = { key = result.path[#result.path], name = result.name, size = 'normal', path = result.path }
	end
	contentHeight = pageBody:DrawResults(sections, function(row) GoTo(row.path) end)
	if count == 0 then Placeholder(format('No settings match "%s".', state.search)) end
end

-- The window's own controls in the look: the footer's buttons and the
-- search box (its text and hint start clear of Blizzard's magnifying glass).
local function LookControls()
	W.LookButton(F.reloadButton, blizzard, st.BOX_COLORS.bg)
	W.LookButton(F.closeButton, blizzard, st.BOX_COLORS.bg)
	local left = W.LookSearch(F.search, blizzard, FIELD_HEIGHT) or SEARCH_TEXT_INSET
	F.search:SetTextInsets(left, SEARCH_TEXT_INSET, 0, 0)
	F.search.hint:SetPoint('LEFT', F.search, 'LEFT', left, 0)
end

local function Draw()
	blizzard = W.BlizzardLook()
	LookControls()
	ReleaseBody()
	contentHeight = 0
	pageBody:SetRoot(root)
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
	OW:CloseDialog()
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
	search:SetTextInsets(SEARCH_TEXT_INSET, SEARCH_TEXT_INSET, 0, 0)
	search:SetAutoFocus(false)
	search.hint = Text(search, 'field')
	search.hint:SetPoint('LEFT', search, 'LEFT', SEARCH_TEXT_INSET, 0)
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
	F.placeholder:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -OB.TOP)
	F.placeholder:SetTextColor(Grey())
	F.placeholder:Hide()

	pageBody = OB.New(content, root, Changed, CONTENT_WIDTH)
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
	st:KeepInScreenMargin(window) -- dragged by its header, so it keeps to the margin too
	window:EnableMouse(true)
	window:Hide()
	st:SetTemplate(window, 'theme', 'solid', 'panel')
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
		-- A box's keys, the dialog's Esc (its catcher closes it), and Esc while
		-- Blizzard's color picker is open (it's the picker's).
		if GetCurrentKeyBoardFocus() or OW:IsDialogShown() or (ColorPickerFrame and ColorPickerFrame:IsShown()) then
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

------------------------------------------------------------------ a small dialog

--[[
	OW:OpenDialog(title, options): a small SaftUI window, over /sui, for an
	option table of its own (UF's Copy from). title is text, or a function
	that gives it, read on each render. options is a group, as a page's: its
	options and inline groups are drawn by a body of its own (OB.New), two
	columns of rows as in the window. A dialog has no tabs or picker: of child
	groups that aren't inline, only the first one's rows show.

	A set re-renders it, after the drag for a slider's (meanwhile its other
	rows follow the drag in place, as the window's do), and not while
	Blizzard's color picker is open (the swatch shows its color itself; the
	next set draws the rest). A failed validate shows its message at the
	bottom. Esc (its own keyboard catcher, which the window's passes to) and
	the close X close it, and so do closing the window and entering combat.
	It refuses to open in combat (false).
]]

local DIALOG_WIDTH, DIALOG_PAD = 568, 24
local DIALOG_CONTENT = DIALOG_WIDTH - 2 * DIALOG_PAD -- two columns of 240
local DIALOG_HEAD, DIALOG_FOOT, DIALOG_MAX_BODY = 58, 30, 600
local DIALOG_KEY = 'dialog' -- the table's key in the dialog's root
local D = { offset = 0, height = 0 } -- the dialog's frames, body and what it draws

local function SetDialogScroll(offset)
	D.offset = ScrollTo(D.scroll, D.bar, offset, D.height)
end

local function DrawDialog()
	D.body:Release()
	local title = D.titleSource
	if type(title) == 'function' then title = title() end
	D.title:SetText(tostring(title or ''))
	local view = OM.BuildView(D.root, DIALOG_KEY)
	D.height = view and D.body:Draw(view.sections) or 0
	D.content:SetHeight(max(1, D.height))
	D.frame:SetHeight(DIALOG_HEAD + min(max(D.height, ROW_HEIGHT), DIALOG_MAX_BODY) + DIALOG_FOOT)
	D.scroll:UpdateScrollChildRect()
	SetDialogScroll(D.offset)
end

local function RenderDialog()
	if D.frame and D.frame:IsShown() then xpcall(DrawDialog, geterrorhandler()) end
end

-- The dialog's widgets' onChanged, as the window's Changed: mid-drag its other
-- rows follow in place, and it's drawn again when the mouse is let go.
local function DialogChanged(ok, err, isDragging, widget)
	D.status:SetText(ok == false and err or '')
	if ok == false and err then return end
	if isDragging then
		xpcall(function() D.body:Refresh(widget) end, geterrorhandler())
		return
	end
	if ColorPickerFrame and ColorPickerFrame:IsShown() then return end
	RenderDialog()
end

local function BuildDialog()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(300) -- over the window (100) and all it holds
	frame:SetWidth(DIALOG_WIDTH)
	st:KeepInScreenMargin(frame)
	frame:EnableMouse(true)
	frame:Hide()
	st:SetTemplate(frame, 'theme', 'solid', 'panel')
	D.frame = frame

	D.title = Text(frame, 'brand')
	D.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', DIALOG_PAD, -18)
	D.title:SetWidth(DIALOG_CONTENT - 40)
	local close = st:CreateCloseButton(frame)
	close:ClearAllPoints()
	close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -14, -14)
	local line = Line(frame)
	line:SetPoint('TOPLEFT', frame, 'TOPLEFT', 2, -(DIALOG_HEAD - 6))
	line:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -2, -(DIALOG_HEAD - 6))
	line:SetHeight(1)

	local scroll = CreateFrame('ScrollFrame', nil, frame)
	scroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', DIALOG_PAD, -DIALOG_HEAD)
	scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -DIALOG_PAD, DIALOG_FOOT)
	local content = CreateFrame('Frame', nil, scroll)
	content:SetSize(DIALOG_CONTENT, 1)
	scroll:SetScrollChild(content)
	scroll:EnableMouseWheel(true)
	scroll:SetScript('OnMouseWheel', function(_, delta) SetDialogScroll(D.offset - delta * SCROLL_STEP) end)
	D.scroll, D.content = scroll, content
	D.bar = frame:CreateTexture(nil, 'OVERLAY')
	D.bar:SetColorTexture(unpack(st.BOX_COLORS.edge))
	D.bar:SetWidth(3)
	D.bar:Hide()
	D.body = OB.New(content, nil, DialogChanged, DIALOG_CONTENT)

	D.status = Text(frame, 'field')
	D.status:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', DIALOG_PAD, 10)
	D.status:SetWidth(DIALOG_CONTENT)
	D.status:SetTextColor(Colors().text.red:GetRGB())

	-- Esc, only while the dialog is shown.
	local keys = CreateFrame('Frame', nil, frame)
	keys:Hide()
	keys:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		if GetCurrentKeyBoardFocus() or (ColorPickerFrame and ColorPickerFrame:IsShown()) then
			self:SetPropagateKeyboardInput(true)
			return
		end
		local escape = key == 'ESCAPE'
		self:SetPropagateKeyboardInput(not escape)
		if escape then OW:CloseDialog() end
	end)
	D.keys = keys

	frame:SetScript('OnShow', function()
		keys:Show()
		keys:EnableKeyboard(true)
		if not InCombatLockdown() then keys:SetPropagateKeyboardInput(true) end
	end)
	frame:SetScript('OnHide', function()
		keys:EnableKeyboard(false)
		keys:Hide()
		D.body:Release()
		local owner = W.ListOwner()
		if owner and Inside(owner, frame) then W.CloseList() end
		W.CancelConfirm()
		D.status:SetText('')
	end)
	-- Its sets can reach protected frames (UF's copy updates the unit frames).
	frame:RegisterEvent('PLAYER_REGEN_DISABLED')
	frame:SetScript('OnEvent', function() OW:CloseDialog() end)
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
			if state.search ~= '' or searchDue then ClearSearch() end
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
	if state.search ~= '' or searchDue then ClearSearch() end
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

-- A small dialog over the window for options, a group table of its own
-- (see "a small dialog" above). False in combat.
function OW:OpenDialog(title, options)
	if InCombatLockdown() then return false end
	if not D.frame then BuildDialog() end
	D.titleSource, D.root, D.offset = title, { [DIALOG_KEY] = options }, 0
	D.body:SetRoot(D.root)
	D.status:SetText('')
	D.frame:ClearAllPoints()
	D.frame:SetPoint('CENTER', self:IsShown() and F.window or UIParent, 'CENTER', 0, 0)
	D.frame:Show()
	RenderDialog()
	return true
end

function OW:CloseDialog()
	if self:IsDialogShown() then D.frame:Hide() end
end

function OW:IsDialogShown()
	return D.frame ~= nil and D.frame:IsShown()
end

function OW:SetStatus(text)
	if F.status then F.status:SetText(text or '') end
end

function OW:GetFooter()
	if not F.window then Build() end
	return F.footerRegion
end

-- Edit mode's buttons take the region's left (EditMode/footer.lua): the
-- status line starts width in, clear of them.
function OW:SetFooterInset(width)
	if not F.status then return end
	F.status:SetPoint('LEFT', F.footerRegion, 'LEFT', width or 0, 0)
end

-- What the last render drew: { page, tab, subtab, pick, search }.
function OW:GetState()
	return { page = shown.page, tab = shown.tab, subtab = shown.subtab, pick = shown.pick, search = state.search }
end

-- For tests: the frames, the drawn body rows, how many renders ran.
function OW.GetFrames() return F end
function OW.GetDrawnRows() return pageBody and pageBody.cells or EMPTY end
-- The dialog's: { frame, title, scroll, content, bar, status, keys, body };
-- its drawn rows are body.cells.
function OW.GetDialogFrames() return D end
function OW.GetRenderCount() return renders end

-- st.Config:Refresh notifies AceConfigRegistry: re-render on the next frame.
LibStub('AceConfigRegistry-3.0').RegisterCallback(OW, 'ConfigTableChange', function(_, appName)
	if appName == st.name and not rendering then Schedule() end
end)
