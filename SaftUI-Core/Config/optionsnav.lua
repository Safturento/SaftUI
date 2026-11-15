local st = SaftUI
local W, OB = st.OptionsWidgets, st.OptionsBody

--[[
	The navigation of SaftUI's options window (st.OptionsWindow,
	optionswindow.lua): the sidebar (the search box over Edit mode and the
	command buttons, the pages under their groups, the profile's name) and the
	tab rows and the picker over the body. It draws into frames
	optionswindow.lua builds (F.side and the main column), and loads after it
	(Config/load.xml); optionswindow.lua calls it through OW.S.
]]

local OW = st.OptionsWindow
local S = OW.S

local floor, min, max, ceil = math.floor, math.min, math.max, math.ceil
local format = string.format

-- The window's fonts and pieces (optionsbody.lua).
local Text, Acquire, ReleaseAll = OB.Text, OB.Acquire, OB.ReleaseAll

-- From optionswindow.lua.
local F, state, pools = S.F, S.state, S.pools
local Colors, Normal, Grey, Accent, Button = S.Colors, S.Normal, S.Grey, S.Accent, S.Button
local SetNavScroll, Select = S.SetNavScroll, S.Select
local PAD, FIELD_HEIGHT, TAB_HEIGHT = S.PAD, S.FIELD_HEIGHT, S.TAB_HEIGHT
local ACTION_PAD, ACTION_HEIGHT, NAV_ITEM = S.ACTION_PAD, S.ACTION_HEIGHT, S.NAV_ITEM

------------------------------------------------------------------ the mockup's numbers

local LABEL_GAP = OB.LABEL_GAP
local TAB_GAP, TAB_WRAP_GAP = 22, 6

-- The sidebar.
local ACTION_GAP = 6
-- Two to a line in the mockup's sidebar; the same size in either layout.
local ACTION_WIDTH = floor((OW.LAYOUT.own.navWidth - 24 - ACTION_GAP) / 2)
-- The search box over them: as wide as a line of two, flush with them (the
-- sidebar less its padding, as the mockup draws it), and 8 above them.
local SEARCH_WIDTH, SEARCH_GAP = 2 * ACTION_WIDTH + ACTION_GAP, 8
local NAV_GROUP, NAV_TOP = 29, 6

local HOVER = { 0.133, 0.133, 0.133, 1 } -- #222

------------------------------------------------------------------ the sidebar

-- The sidebar's Edit mode button and the collapsed footer's (F.tools[2]) are
-- on while edit mode is; the footer's Search is while a search is.
local function UpdateEditModeButton()
	local EM = st.EditModeFrames
	local on = (EM and EM.active) and true or false
	local button = F.actions and F.actions[1]
	if button then W.SetOn(button, on) end
	local tool = F.tools and F.tools[2]
	if tool then W.SetOn(tool, on) end
	local search = F.tools and F.tools[1]
	if search then W.SetOn(search, state.search ~= '') end
end

-- The search box (optionswindow.lua's), then under it Edit mode and every
-- st.Config:AddCommand, two to a line. Under Blizzard the same, at the
-- sidebar's top (the title bar names the window, so there is no brand).
local function DrawActions()
	S.PlaceSearch()
	local top = ACTION_PAD + FIELD_HEIGHT + SEARCH_GAP
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
		W.LookButton(button, S.blizzard, st.BOX_COLORS.bg)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', F.actionsFrame, 'TOPLEFT',
			12 + ((i - 1) % 2) * (ACTION_WIDTH + ACTION_GAP),
			-(top + floor((i - 1) / 2) * (ACTION_HEIGHT + ACTION_GAP)))
	end
	local lines = ceil(#list / 2)
	F.actionsFrame:SetHeight(top + lines * ACTION_HEIGHT + (lines - 1) * ACTION_GAP + ACTION_PAD)
	UpdateEditModeButton()
end

-- The banner a group header wears: the Settings panel's three, in turn.
function OW.BannerAtlas(n)
	local banners = st.ThemeArt.Control('optionswindow').banners
	return banners[((n - 1) % #banners) + 1]
end

-- A sidebar name's white: the open page's, and the one under the mouse.
local function PickedText()
	return unpack(st.ThemeArt.Control('optionslist').text.picked)
end

-- A sidebar entry's look: the open page's accent fill and bar, or under
-- Blizzard (item.blizzard) the Settings panel's category list, the open page
-- on its picked art (item.listPicked) with its name white and the others
-- gold; the one under the mouse is lit by OnEnter (item.listHover). Under
-- Thick and Thin the name keeps the profile's text color.
local function StyleNavItem(item)
	item.listHover:Hide()
	if item.blizzard then
		local text = st.ThemeArt.Control('optionslist').text
		if item.active then item.text:SetTextColor(PickedText()) else item.text:SetTextColor(unpack(text.normal)) end
	else
		item.text:SetTextColor(Normal())
	end
	item.listPicked:SetShown(item.blizzard and item.active or false)
	if item.active and not item.blizzard then
		item.bg:SetColorTexture(st:ColorRGBA('accent', nil, st.TINT_ROW))
		item.bg:Show()
		item.bar:SetColorTexture(Accent()) -- read at each look, so a new accent shows on a pooled entry
		item.bar:Show()
	else
		item.bg:Hide()
		item.bar:Hide()
	end
	item:SetAlpha(item.disabled and 0.4 or 1)
end

local function MakeNavItem()
	local item = CreateFrame('Button', nil, F.navContent)
	item:SetHeight(NAV_ITEM) -- as wide as the layout's rows (DrawSidebar)
	item.bg = item:CreateTexture(nil, 'BACKGROUND')
	item.bg:SetAllPoints(item)
	item.bar = item:CreateTexture(nil, 'ARTWORK')
	item.bar:SetColorTexture(Accent())
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
	item:SetScript('OnEnter', function(self)
		if self.active then return end
		if self.blizzard then
			self.listHover:Show()
			if not self.disabled then self.text:SetTextColor(PickedText()) end
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
	header:SetHeight(NAV_GROUP) -- as wide as the layout's rows (DrawSidebar)
	-- Under Blizzard its banner (DrawSidebar sets its art), hanging from the
	-- header's top left at its own size.
	header.banner = header:CreateTexture(nil, 'BACKGROUND')
	header.banner:SetPoint('TOPLEFT', header, 'TOPLEFT', 0, 0)
	header.banner:Hide()
	header.text = Text(header, 'group')
	return header
end

local function DrawSidebar(entries)
	S.pageEntries = entries -- the title's page list reads them (S.OpenPageList)
	DrawActions()
	ReleaseAll(pools.nav)
	ReleaseAll(pools.group)
	wipe(F.nav)
	local look = S.blizzard and st.ThemeArt.Control('optionslist')
	local art = S.blizzard and st.ThemeArt.Control('optionswindow')
	local y, groups = NAV_TOP, 0
	for _, entry in ipairs(entries) do
		local frame
		if entry.group then
			frame = Acquire(pools.group)
			frame.group = entry.group
			frame.text:SetText(entry.group)
			frame.text:ClearAllPoints()
			if art then
				groups = groups + 1
				local atlas = OW.BannerAtlas(groups)
				local info = C_Texture.GetAtlasInfo(atlas)
				frame.banner:SetAtlas(atlas)
				frame.banner:SetSize(info.width, info.height)
				frame.banner:Show()
				frame:SetHeight(art.groupHeight)
				frame.text:SetPoint('LEFT', frame, 'LEFT', art.groupLabel.x, art.groupLabel.y)
				frame.text:SetTextColor(PickedText())
			else
				frame.banner:Hide()
				frame:SetHeight(NAV_GROUP)
				frame.text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 18, -12)
				frame.text:SetTextColor(Grey())
			end
		else
			frame = Acquire(pools.nav)
			frame.key, frame.name, frame.disabled = entry.key, entry.name, entry.disabled
			frame.active = state.search == '' and entry.key == state.page
			frame.text:ClearAllPoints()
			frame.text:SetPoint('LEFT', frame, 'LEFT', entry.special and 18 or 22, 0)
			frame.text:SetText(entry.name)
			frame.text:SetWidth(S.layout.navWidth - 30)
			frame.blizzard = look and true or false
			if look then
				frame.listPicked:SetAtlas(look.picked)
				frame.listHover:SetAtlas(look.hover)
			end
			StyleNavItem(frame)
		end
		frame:SetWidth(S.layout.navWidth)
		frame:SetPoint('TOPLEFT', F.navContent, 'TOPLEFT', 0, -y)
		y = y + floor(frame:GetHeight() + 0.5) -- a height read back is a hair off the one set
		F.nav[#F.nav + 1] = frame
	end
	S.navHeight = y + 10
	F.navContent:SetHeight(S.navHeight)
	F.navFrame:UpdateScrollChildRect()
	SetNavScroll(S.navOffset)

	local r, g, b = Normal()
	F.profile:SetText(format('Profile: |cff%02x%02x%02x%s|r', floor(r * 255), floor(g * 255), floor(b * 255),
		tostring(st.config:GetCurrentProfile())))
end

------------------------------------------------------------------ tabs and the picker

local function MakeTab()
	local tab = CreateFrame('Button', nil, F.main)
	tab.text = Text(tab, 'tab')
	tab.text:SetPoint('BOTTOMLEFT', tab, 'BOTTOMLEFT', 2, 7)
	tab.underline = tab:CreateTexture(nil, 'OVERLAY')
	tab.underline:SetColorTexture(Accent())
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
-- the accent underline. None under Thick and Thin (look nil).
local function LookTab(tab, look)
	if not look then
		W.HideArt(tab)
		return
	end
	local set = tab.active and look.picked or look.other
	local _, height = W.AtlasSize(set.left)
	W.LayThree(tab, set, 'BACKGROUND', min(height or TAB_HEIGHT, TAB_HEIGHT), 'BOTTOM')
end

-- A row of tabs from top, wrapping onto more lines when they don't fit the
-- content's width. Returns its bottom.
local function DrawTabRow(pool, list, active, top, slot)
	ReleaseAll(pool)
	local look = S.blizzard and st.ThemeArt.Control('optionstab')
	local x, y = 0, top
	for _, entry in ipairs(list) do
		local tab = Acquire(pool)
		tab.key, tab.slot, tab.disabled = entry.key, slot, entry.disabled
		tab.active = entry.key == active
		tab.text:SetText(entry.name)
		local width = ceil(tab.text:GetStringWidth()) + 4
		if x > 0 and x + width > S.bodyWidth then
			x, y = 0, y + TAB_HEIGHT + TAB_WRAP_GAP
		end
		tab:SetSize(width, TAB_HEIGHT)
		tab:SetPoint('TOPLEFT', F.main, 'TOPLEFT', PAD + x, -y)
		if tab.active then tab.text:SetTextColor(Normal()) else tab.text:SetTextColor(Grey()) end
		if tab.active and not S.blizzard then tab.underline:SetColorTexture(Accent()) end
		tab.underline:SetShown(tab.active and not S.blizzard)
		LookTab(tab, look)
		tab:SetAlpha(entry.disabled and 0.4 or 1)
		x = x + width + TAB_GAP
	end
	return y + TAB_HEIGHT
end

-- A line across the main column: Blizzard's divider under Blizzard, a 1px
-- line in OB.LINE's color otherwise.
local function PlaceLine(line, y)
	if S.blizzard then
		line:SetAtlas(st.ThemeArt.Control('optionswindow').rule)
	else
		line:SetColorTexture(unpack(OB.LINE))
	end
	line:ClearAllPoints()
	line:SetPoint('TOPLEFT', F.main, 'TOPLEFT', 0, -y)
	line:SetPoint('TOPRIGHT', F.main, 'TOPRIGHT', 0, -y)
	line:Show()
end

-- The picker is a select widget over a one-option tree of its own, so it
-- gets the same list (and the list's Esc and outside click).
local pickerOption = {
	type = 'select', name = '',
	get = function() return S.shown.pick end,
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

------------------------------------------------------------------ the sidebar toggle

--[[
	The sidebar collapses and is shown again (at full and at half; the sidebar's
	state, S.sidebar, and the size are separate, and the bar keeps it for when it
	grows). The window narrows from its left, so the page, the close X and the
	window's top right corner stay where they are.

	  OW:IsSidebarShown() -> boolean
	  OW:SetSidebarShown(shown) -> boolean
	      false in combat, while SaftUI's color picker is open, for no change,
	      and when the width it would take doesn't OW.Fits (at the bar nothing
	      is checked: the state is kept for when the bar grows). Else it closes
	      what is open over the window (S.CloseOverlays: a menu, the small
	      dialog, a list, the keyboard in a box of the window's, among them the
	      search box's, and the status line), saves sidebar = false (nil for
	      shown) through S.SaveWindow, sets S.sidebar and draws the window once
	      (OW:Render). The page, tab, pick, search and both scroll offsets are
	      kept as they are: the search is not ended, a results page stays, and
	      the box (its text and all) is drawn again when the sidebar is.

	F.sideToggle, W.IconButton (26, a 16 icon, its icon accent under the mouse)
	with its tooltip, whose click is ignored for OW.SIZE_GUARD after the sidebar
	last changed (S.sidebarAt; the API is not guarded), placed by
	S.PlaceSideToggle (Relayout runs it): shown, a child of the sidebar's foot
	(F.foot), 8 in from its right, centred on its 30, wearing panelLeftOpen
	("Collapse the sidebar", pointing right); collapsed, a child of the footer,
	under Thick and Thin PAD (28) in from its left and centred on it, under
	Blizzard footerX in and footerY up from the window's bottom left corner,
	wearing panelLeftClose ("Show the sidebar", pointing left). The footer's
	region starts FOOTER_GAP after it (Relayout). While it is disabled the
	tooltip says why in red: the color picker is open; the screen is too narrow
	for the sidebar (S.UpdateWindowButtons).
]]

local TOGGLE_SIZE, TOGGLE_ICON = 26, 16
S.SIDE_TOGGLE_SIZE, S.SIDE_TOGGLE_RIGHT = TOGGLE_SIZE, 8 -- in the sidebar's foot, 8 from its right

local function ToggleTip()
	local collapsed = S.sidebar == false
	local title, line = 'Collapse the sidebar', 'Hides the page list; the window narrows from its left.'
	if collapsed then title, line = 'Show the sidebar', 'Shows the page list again.' end
	local lines = { line }
	if S.ColorPickerShown() then
		lines[#lines + 1] = { text = 'Close the color picker first.', red = true }
	end
	if collapsed and S.size ~= 'mini' and not OW.Fits(S.layout, S.size, true) then
		lines[#lines + 1] = { text = S.size == 'full' and 'The screen is too narrow for the sidebar at full size. Shrink to half first.'
			or 'The screen is too narrow for the sidebar.', red = true }
	end
	return title, lines
end

-- Whether the toggle can be used now (S.UpdateWindowButtons).
function S.SideToggleEnabled()
	if S.ColorPickerShown() then return false end
	return S.sidebar ~= false or S.size == 'mini' or OW.Fits(S.layout, S.size, true)
end

function S.BuildSideToggle(foot)
	local toggle = W.IconButton(foot, st.icons.panelLeftOpen, ToggleTip, TOGGLE_SIZE, TOGGLE_ICON)
	toggle.hoverIcon = true -- its icon turns accent under the mouse, as the arrows'
	-- Guarded as the size buttons are (OW.SIZE_GUARD): a double click would fall
	-- through to what lands under the mouse (the world, or a control).
	toggle.onClick = function()
		if S.sidebarAt ~= nil and GetTime() - S.sidebarAt < OW.SIZE_GUARD then return end
		OW:SetSidebarShown(S.sidebar == false)
	end
	F.sideToggle = toggle
end

-- Where the toggle sits and what it shows, for S.sidebar and the look. In the
-- foot it is the sidebar's, hidden with it; collapsed it moves to the footer.
function S.PlaceSideToggle()
	local toggle, L = F.sideToggle, S.layout
	toggle:ClearAllPoints()
	if S.sidebar ~= false then
		toggle:SetParent(F.foot)
		toggle:SetPoint('RIGHT', F.foot, 'RIGHT', -S.SIDE_TOGGLE_RIGHT, 0)
		toggle.icon:SetTexture(st.icons.panelLeftOpen)
	else
		toggle:SetParent(F.footer)
		if S.blizzard then
			toggle:SetPoint('BOTTOMLEFT', F.window, 'BOTTOMLEFT', L.footerX, L.footerY)
		else
			toggle:SetPoint('LEFT', F.footer, 'LEFT', PAD, 0)
		end
		toggle.icon:SetTexture(st.icons.panelLeftClose)
	end
	toggle:SetFrameLevel(toggle:GetParent():GetFrameLevel() + 2)
	W.LookControl(toggle, S.blizzard)
	W.SetEnabled(toggle, S.SideToggleEnabled())
end

function OW:IsSidebarShown()
	return S.sidebar ~= false
end

-- A double click on the toggle sends its second click where the toggle was, which
-- the change has moved away from (the sidebar's foot to the footer's left, or
-- back): to the game world, or a control. So for OW.SIZE_GUARD after the change a
-- small frame of the window's own, with the mouse, sits on the old spot and
-- takes that click (F.toggleGuard). It is hidden when the guard ends, on any
-- relayout and when the window hides. The toggle at its new spot ignores clicks
-- for the same time (its onClick, S.sidebarAt).
-- spot is { x, y, width, height }: the old spot's bottom left from the
-- window's bottom right corner, which a sidebar change leaves where it was.
function S.GuardToggleSpot(spot)
	local guard = F.toggleGuard
	if not guard then
		guard = CreateFrame('Frame', nil, F.window)
		guard:EnableMouse(true)
		guard:SetScript('OnUpdate', function(self)
			if GetTime() - self.since >= OW.SIZE_GUARD then self:Hide() end
		end)
		guard:Hide()
		F.toggleGuard = guard
	end
	guard.since = GetTime()
	guard:ClearAllPoints()
	guard:SetPoint('BOTTOMLEFT', F.window, 'BOTTOMRIGHT', spot[1], spot[2])
	guard:SetSize(spot[3], spot[4])
	guard:SetFrameLevel(F.window:GetFrameLevel() + 100)
	guard:Show()
end

function S.HideToggleGuard()
	if F.toggleGuard then F.toggleGuard:Hide() end
end

function OW:SetSidebarShown(shown)
	shown = shown ~= false
	if InCombatLockdown() or S.ColorPickerShown() then return false end
	if shown == (S.sidebar ~= false) then return false end
	-- The bar keeps the state for when it grows (and grows to half whatever the
	-- screen); the other sizes need the width.
	if S.size ~= 'mini' and not OW.Fits(S.layout, S.size, shown) then return false end
	local window = self:IsShown()
	local spot
	local toggle, w = F.sideToggle, F.window
	if window and toggle and toggle:IsVisible() and toggle:GetLeft() then
		spot = { floor(toggle:GetLeft() - w:GetRight() + 0.5), floor(toggle:GetBottom() - w:GetBottom() + 0.5),
			floor(toggle:GetWidth() + 0.5), floor(toggle:GetHeight() + 0.5) }
	end
	if window then S.CloseOverlays() end
	S.SaveWindow({ sidebar = shown and S.UNSET or false })
	S.sidebar = shown
	S.sidebarAt = GetTime()
	if window then self:Render() end
	if spot then S.GuardToggleSpot(spot) end
	return true
end

------------------------------------------------------------------ with the sidebar collapsed

--[[
	What the sidebar offered moves while it is collapsed (S.sidebar == false;
	Relayout, optionswindow.lua, draws them; none at the bar):

	  - F.tools, in the footer in a line from the toggle, TOOL_GAP (6) apart,
	    level with it (under Blizzard on Blizzard's panel button,
	    W.LookControl):
	      [1] Search, W.IconButton (search), whose click opens the search panel;
	      [2] Edit mode (move), whose click is st.EditModeFrames:Toggle(),
	      then each st.Config:AddCommand command with an icon, in order, as a
	      W.IconButton (its label the title) while it fits before Reload UI
	      with the footer's 12 gap. Every command that doesn't fit, and every
	      one with no icon, is under one overflow button (ellipsis, "More"),
	      last, which opens W.OpenList of their labels; a pick runs the
	      command. The overflow button always fits (Search, Edit mode and it
	      are the floor; the status line has given way by then: no footer
	      control is drawn now that the unit frames' profile is on the Unit
	      dropdown's line). Search is on (W.SetOn) while a search is, Edit mode while edit
	      mode is (UpdateEditModeButton: edit mode's Enabled and Disabled, and
	      every draw). S.DrawTools(room) places them and returns how far they
	      reach from the toggle's right (the footer's region starts FOOTER_GAP
	      after); room is what Relayout leaves them before Reload UI.
	  - F.searchPop: the sidebar's own search box (F.search, moved into it by
	    S.PlaceSearch) in a panel SEARCH_POP_PAD round it, a child of F.main 20
	    levels up, its bottom left 6 over the Search icon's top left. The icon
	    opens it with the keyboard in the box and closes it again; it closes
	    when the box loses the keyboard (Enter, Esc) and on a mouse down
	    anywhere else, through F.searchCatcher (a full-screen frame in the
	    window's strata between the page and the panel, as the kit list's
	    catcher: the click is the catcher's, so a click on the icon only
	    closes it), and the search stays. The box goes back to the sidebar when that shows.
	  - F.titleButton over the page's title and F.titleArrow (chevronDown, 16,
	    Text > Grey, accent under the mouse) 8 after the title's text: the
	    button opens the sidebar's pages as W.OpenList's list, groups as
	    captions (OW.PageMenuEntries), and a pick goes where a click in the
	    sidebar does (OW:Navigate). Hidden while the sidebar shows.
]]

local TOOL_GAP, SEARCH_POP_PAD, SEARCH_POP_GAP = 6, 8, 6
local TITLE_ARROW, TITLE_ARROW_GAP = 16, 8
S.TITLE_ARROW_ROOM = TITLE_ARROW + TITLE_ARROW_GAP -- the title's room less this while collapsed
S.SEARCH_POP_WIDTH, S.SEARCH_POP_HEIGHT = SEARCH_WIDTH + 2 * SEARCH_POP_PAD, FIELD_HEIGHT + 2 * SEARCH_POP_PAD

function S.ClosePop()
	if F.searchPop then F.searchPop:Hide() end
	if F.searchCatcher then F.searchCatcher:Hide() end
end

-- The search box in the sidebar's actions while that shows, else in the panel.
function S.PlaceSearch()
	local box = F.search
	local collapsed = S.sidebar == false
	local parent = collapsed and F.searchPop or F.actionsFrame
	if box:GetParent() ~= parent then
		box:SetParent(parent)
		box:SetFrameLevel(parent:GetFrameLevel() + 1)
	end
	box:ClearAllPoints()
	if collapsed then
		box:SetPoint('TOPLEFT', parent, 'TOPLEFT', SEARCH_POP_PAD, -SEARCH_POP_PAD)
	else
		box:SetPoint('TOPLEFT', parent, 'TOPLEFT', 12, -ACTION_PAD)
	end
	box:SetWidth(SEARCH_WIDTH)
end

local function SearchTip()
	if state.search ~= '' then
		return 'Search settings', { format('Searching for "%s". Click to change it.', state.search) }
	end
	return 'Search settings', { 'Finds a setting by name, on any page.' }
end

local function EditModeTip()
	return 'Edit mode', { "Drag and nudge SaftUI's frames. /sui edit does too." }
end

local function ToggleSearchPop()
	if S.sidebar ~= false then return end
	if F.searchPop:IsShown() then
		S.ClosePop()
		F.search:ClearFocus()
		return
	end
	S.PlaceSearch()
	F.searchCatcher:Show()
	F.searchPop:Show()
	F.search:SetFocus()
end

-- What the tools are made of (the commands, their icons and labels), to make
-- them again if a command is added.
function S.ToolsKey()
	local parts = {}
	for i, command in ipairs(st.Config:GetCommands()) do
		parts[i] = format('%s|%s|%s', command.command, tostring(command.icon), tostring(command.label))
	end
	return table.concat(parts, ';')
end

-- A command's icon button, made once (F.commandTools, by command).
local function CommandTool(command)
	local tool = F.commandTools[command.command]
	if not tool or tool.iconPath ~= command.icon then
		tool = W.IconButton(F.footer, command.icon, function() return command.label end, TOGGLE_SIZE, TOGGLE_ICON)
		tool.iconPath = command.icon
		tool.onClick = function() command.func() end
		F.commandTools[command.command] = tool
	end
	return tool
end

-- The overflow button's list: the commands that are not buttons, by label; a
-- pick runs one.
local function OpenOverflow(button)
	local entries = {}
	for i, command in ipairs(F.overflowCommands or {}) do entries[i] = { key = i, label = tostring(command.label) } end
	W.OpenList(button, entries, nil, function(i)
		local command = F.overflowCommands[i]
		if command then command.func() end
	end)
end

-- The footer's tools, placed and put in the look: shown only while the sidebar
-- is collapsed. room is the width from the toggle's right to Reload UI's left
-- less the gap (Relayout works it out): Search and Edit mode always, then each
-- command with an icon, in order, while it fits (each TOOL_GAP and its width,
-- keeping the overflow button's if anything is left over), and the rest, with
-- the commands that have no icon, under the overflow button, last. Returns
-- how far they reach right of the toggle.
function S.DrawTools(room)
	room = room or math.huge
	local step = TOOL_GAP + TOGGLE_SIZE
	if not F.search1 then
		F.search1 = W.IconButton(F.footer, st.icons.search, SearchTip, TOGGLE_SIZE, TOGGLE_ICON)
		F.search1.onClick = ToggleSearchPop
		F.edit1 = W.IconButton(F.footer, st.icons.move, EditModeTip, TOGGLE_SIZE, TOGGLE_ICON)
		F.edit1.onClick = function() st.EditModeFrames:Toggle() end
		F.overflow1 = W.IconButton(F.footer, st.icons.ellipsis, function() return 'More' end, TOGGLE_SIZE, TOGGLE_ICON)
		F.overflow1.onClick = OpenOverflow
		F.commandTools = {}
	end
	local commands = st.Config:GetCommands()
	local iconed, others = {}, 0
	for _, command in ipairs(commands) do
		if command.icon then iconed[#iconed + 1] = command else others = others + 1 end
	end
	-- How many icon commands fit: all of them if nothing else needs the
	-- overflow button, else with its step kept.
	local free = room - 2 * step
	local fit = max(0, min(#iconed, floor(free / step)))
	if fit < #iconed or others > 0 then fit = max(0, min(#iconed, floor((free - step) / step))) end
	local shown = {}
	for k = 1, fit do shown[iconed[k]] = true end
	F.overflowCommands = {}
	for _, command in ipairs(commands) do
		if not shown[command] then F.overflowCommands[#F.overflowCommands + 1] = command end
	end
	local order = { F.search1, F.edit1 }
	for k = 1, fit do order[#order + 1] = CommandTool(iconed[k]) end
	if #F.overflowCommands > 0 then order[#order + 1] = F.overflow1 end
	local inOrder = {}
	for _, tool in ipairs(order) do inOrder[tool] = true end
	for _, tool in pairs(F.commandTools) do if not inOrder[tool] then tool:Hide() end end
	if not inOrder[F.overflow1] then F.overflow1:Hide() end
	for i = #F.tools, 1, -1 do F.tools[i] = nil end
	local collapsed = S.sidebar == false
	local reach, previous = 0, F.sideToggle
	for i, tool in ipairs(order) do
		F.tools[i] = tool
		tool.hoverIcon = true -- an icon is accent under the mouse, as the toggle's
		tool:ClearAllPoints()
		tool:SetPoint('LEFT', previous, 'RIGHT', TOOL_GAP, 0)
		tool:SetFrameLevel(F.footer:GetFrameLevel() + 2)
		W.LookControl(tool, S.blizzard)
		tool:SetShown(collapsed)
		reach = reach + step
		previous = tool
	end
	F.searchPop:ClearAllPoints()
	F.searchPop:SetPoint('BOTTOMLEFT', F.tools[1], 'TOPLEFT', 0, SEARCH_POP_GAP)
	UpdateEditModeButton()
	return reach
end

-- The title's page list: the sidebar's pages, the current one marked.
function S.OpenPageList()
	if S.sidebar ~= false or not S.pageEntries then return end
	local current = state.search == '' and state.page or nil
	W.OpenList(F.titleButton, OW.PageMenuEntries(S.pageEntries), current, function(key) OW:Navigate(key) end)
end

-- The page's title opens the page list while the sidebar is collapsed: its
-- button covers the title's text and the arrow 8 after it. Hidden, and so
-- taking no click, while the sidebar shows (Heading runs it).
function S.PlaceTitle()
	local collapsed = S.sidebar == false
	F.titleButton:SetShown(collapsed)
	if not collapsed then return end
	local width = min(ceil(F.title:GetUnboundedStringWidth()), S.titleRoom)
	local height = floor(F.title:GetStringHeight() + 0.5)
	F.titleButton:ClearAllPoints()
	F.titleButton:SetPoint('TOPLEFT', F.title, 'TOPLEFT', 0, 0)
	F.titleButton:SetSize(width + TITLE_ARROW_GAP + TITLE_ARROW, height)
	F.titleArrow:ClearAllPoints()
	F.titleArrow:SetPoint('TOPLEFT', F.titleButton, 'TOPLEFT', width + TITLE_ARROW_GAP, -floor((height - TITLE_ARROW) / 2))
	local r, g, b = Grey()
	F.titleArrow:SetVertexColor(r, g, b)
end

-- Builds the search panel and the title's button (Build, after the footer).
function S.BuildCollapsed()
	F.tools = {}
	local pop = st:CreateFrame('Frame', nil, F.main)
	pop:SetFrameLevel(F.main:GetFrameLevel() + 20)
	pop:SetSize(S.SEARCH_POP_WIDTH, S.SEARCH_POP_HEIGHT)
	pop:EnableMouse(true)
	pop:Hide()
	st:SetTemplate(pop, 'theme', 'solid', 'panel')
	F.searchPop = pop
	-- A mouse down anywhere else closes the panel (and takes the keyboard from
	-- its box): a full-screen catcher in the window's strata under the panel
	-- and over the rest of the window, as the kit list's.
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata(F.window:GetFrameStrata())
	catcher:SetFrameLevel(pop:GetFrameLevel() - 1)
	catcher:EnableMouse(true)
	catcher:Hide()
	catcher:SetScript('OnMouseDown', function()
		S.ClosePop()
		F.search:ClearFocus()
	end)
	F.searchCatcher = catcher
	S.PlaceSearch() -- the sidebar shows by default: the box stays in it

	local button = CreateFrame('Button', nil, F.header)
	button:SetFrameLevel(F.header:GetFrameLevel() + 2)
	button:EnableMouse(true)
	button:Hide()
	local arrow = button:CreateTexture(nil, 'OVERLAY')
	arrow:SetTexture(st.icons.chevronDown)
	arrow:SetSize(TITLE_ARROW, TITLE_ARROW)
	arrow:SetVertexColor(Grey())
	button:SetScript('OnEnter', function(self)
		arrow:SetVertexColor(Accent())
		W.ShowTip(self, 'Choose a page')
	end)
	button:SetScript('OnLeave', function(self)
		arrow:SetVertexColor(Grey())
		W.HideTip(self)
	end)
	button:SetScript('OnHide', function() arrow:SetVertexColor(Grey()) end)
	S.Draggable(button) -- a drag on the title moves the window, a click opens the list
	-- A drag is no click (the game can send a click at the end of a drag), as
	-- the bar's names and a mover.
	button.dragged = false
	button:SetScript('OnMouseDown', function(self) self.dragged = false end)
	button:HookScript('OnDragStart', function(self) self.dragged = true end)
	button:SetScript('OnClick', function(self)
		if self.dragged then return end
		S.OpenPageList()
	end)
	F.titleButton, F.titleArrow = button, arrow
end

------------------------------------------------------------------ for optionswindow.lua

S.UpdateEditModeButton, S.MakeNavItem, S.MakeNavGroup, S.DrawSidebar = UpdateEditModeButton, MakeNavItem, MakeNavGroup, DrawSidebar
S.MakeTab, S.DrawTabRow, S.PlaceLine, S.HidePicker, S.DrawPicker = MakeTab, DrawTabRow, PlaceLine, HidePicker, DrawPicker
