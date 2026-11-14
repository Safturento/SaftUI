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

local floor, min, ceil = math.floor, math.min, math.ceil
local format = string.format

-- The window's fonts and pieces (optionsbody.lua).
local Text, Acquire, ReleaseAll = OB.Text, OB.Acquire, OB.ReleaseAll

-- From optionswindow.lua.
local F, state, pools = S.F, S.state, S.pools
local Colors, Normal, Grey, Blue, Button = S.Colors, S.Normal, S.Grey, S.Blue, S.Button
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

local function UpdateEditModeButton()
	local button = F.actions and F.actions[1]
	if not button then return end
	local EM = st.EditModeFrames
	W.SetOn(button, (EM and EM.active) and true or false)
end

-- The search box (optionswindow.lua's), then under it Edit mode and every
-- st.Config:AddCommand, two to a line. Under Blizzard the same, at the
-- sidebar's top (the title bar names the window, so there is no brand).
local function DrawActions()
	F.search:ClearAllPoints()
	F.search:SetPoint('TOPLEFT', F.actionsFrame, 'TOPLEFT', 12, -ACTION_PAD)
	F.search:SetWidth(SEARCH_WIDTH)
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

-- A sidebar entry's look: the open page's blue fill and bar, or under
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
	item:SetHeight(NAV_ITEM) -- as wide as the layout's rows (DrawSidebar)
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

function OW:SetSidebarShown(shown)
	shown = shown ~= false
	if InCombatLockdown() or S.ColorPickerShown() then return false end
	if shown == (S.sidebar ~= false) then return false end
	-- The bar keeps the state for when it grows (and grows to half whatever the
	-- screen); the other sizes need the width.
	if S.size ~= 'mini' and not OW.Fits(S.layout, S.size, shown) then return false end
	local window = self:IsShown()
	if window then S.CloseOverlays() end
	S.SaveWindow({ sidebar = shown and S.UNSET or false })
	S.sidebar = shown
	S.sidebarAt = GetTime()
	if window then self:Render() end
	return true
end

------------------------------------------------------------------ for optionswindow.lua

S.UpdateEditModeButton, S.MakeNavItem, S.MakeNavGroup, S.DrawSidebar = UpdateEditModeButton, MakeNavItem, MakeNavGroup, DrawSidebar
S.MakeTab, S.DrawTabRow, S.PlaceLine, S.HidePicker, S.DrawPicker = MakeTab, DrawTabRow, PlaceLine, HidePicker, DrawPicker
