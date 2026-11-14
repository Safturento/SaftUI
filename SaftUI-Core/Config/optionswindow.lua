local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

--[[
	SaftUI's options window: /sui, drawn by SaftUI from the modules' Ace
	option tables (the tree st.Config:GetOptionsTable() builds), laid out as the
	approved mockup (docs/superpowers/specs/assets/2026-11-09-options-window-
	mockup.html). The model (optionsmodel.lua) turns the tree into pages, tabs,
	a picker, sections and rows; the body (optionsbody.lua) draws the sections
	and rows, and the widgets (optionswidgets.lua) the rows' controls. This file
	owns the frame, search, the footer and the keyboard; the navigation is
	optionsnav.lua's.

	  OW:Open(path, root)   shows the window (root: the tree, kept for later
	                        opens), at the page, picker, tab and subtab a path
	                        of option keys names (OM.SelectionForPath).
	                        Refuses in combat (false).
	  OW:Close(), OW:IsShown(), OW:GetFrame()
	  OW:Navigate(pageKey, selection)   a page; selection { tab, subtab, pick }
	  OW:Render()           draws the current page again (and an open dialog)
	  OW:SetRoot(root)      a new tree (a profile change), drawn next frame
	  OW:SetStatus(text)    the footer's status line (validate errors)
	  OW:GetFooter()        the footer region between Reload UI and Close, for
	                        edit mode's controls
	  OW:SetFooterInset(w)  edit mode's controls take the region's first w: the
	                        status line starts there, and a page's footer
	                        control keeps clear of them
	  OW:UpdateFonts()      the profile's faces again (a profile change)
	  OW:OpenDialog(title, options), OW:CloseDialog(), OW:IsDialogShown()
	                        a small dialog over the window for an option table
	                        of its own (UF's Copy from and its unit frame
	                        profiles; optionssmalldialog.lua)
	  OW:OpenMenu(widget), OW:CloseMenu(body), OW:IsMenuShown(widget)
	                        an item's menu (optionsmenu.lua)

	The window (drawn as a window in SaftUI's theme with a solid background,
	FULLSCREEN_DIALOG, so edit mode's outlines draw under it), laid out in one
	of two layouts (OW.LAYOUT, optionslayout.lua): the mockup's under Thick
	and Thin (1040 wide, at least 700 tall), and under Blizzard Blizzard's
	Settings window (1110 wide, at least 728 tall: the metal and its title
	bar, the inner frame over the sidebar and the main column, the footer
	under it across the window). It grows taller by its grip (the bottom
	right corner) or its bottom edge (optionsresize.lua), in either layout:
	  - the sidebar: the search box, with Edit mode and the
	    st.Config:AddCommand buttons under it, then Global settings and
	    Profiles, then the module pages under their category (Frames, Combat,
	    Info, any other, then Other; OW.SidebarEntries);
	  - the header: the page's title and description, and the close X
	    (st:CreateCloseButton; under Blizzard in the metal's socket). Dragging
	    it, the sidebar's title (under Thick and Thin) or the title bar (under
	    Blizzard) moves the window, and where it was left is kept in
	    st.config.global.optionsWindow, with the height it was dragged to;
	  - the tab row, across the main column; a second row for subtabs; the
	    picker row (the picked group's control, its pickerControl, right of
	    the picker); the body, a scroll frame of sections (OB.LayoutSections)
	    of rows in quarters, halves and whole lines (OB.LayoutRows), drawn by
	    an OB.New body;
	  - the footer: Reload UI, the region (edit mode's buttons from its left,
	    the status line, and the open page's footer control), Close.

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
	    is busy: a list or confirm dialog open, a drag, a resize, the color
	    picker, typing in one of the window's boxes. It waits for that to end.

	Search waits for typing to pause (SEARCH_DELAY), then shows OM.Search's
	results as a page of sections (page > tabs, then the section); clicking one
	opens its page and brings the row into view. A result in an item's menu
	(menu) brings the item into view and opens its menu at the end of the
	draw, once the scroll is set. Going to a page, tab or pick clears the
	search, one still waiting for the typing to pause too.

	An item's menu (optionsmenu.lua) follows its item through each render
	(S.FollowMenu, after the dialog's), and closes with the window, on
	OW:Navigate (a search result's too) and on a tab or pick (Select).

	A page's footer control is its group's footer (SaftUI's field,
	OM.BuildView's view.footer): a group whose options are drawn in the
	footer's region after its name (their one label), with the options kit's
	own widgets, so in either look. It's centred between Reload UI and Close;
	while edit mode's buttons take the region's left it keeps clear of them,
	at the region's right end, beside Close, and without its label when even
	that is too close (OW.FooterPlace). The status line ends before it, and
	comes before the control's label (and, when edit mode leaves it no room,
	before the control itself): an error shows whole, in the room the control
	leaves, the control dropping its label or hiding until the status clears
	(OW:SetStatus places the footer again). Search results draw no page, so
	no control, and a result for a footer's option opens its page as it is. A render draws an open dialog
	again too, so the dialog follows what changed the tree (a profile change,
	UF's profile prompts).

	A pick's control is the picked group's pickerControl (SaftUI's field,
	OM.BuildView's view.picker.control): a group whose options, buttons, are
	drawn on the picker's line, 12 right of the picker and apart, with the
	options kit's own widgets and their options' tooltips, on every tab of
	that pick (DrawPickerControl). A pick without one draws none; nor do
	search results.

	Esc closes the window through a SaftUI keyboard catcher that is on only
	while the window is shown (not Blizzard's UISpecialFrames). It passes every
	other key on, and Esc too while a box has the keyboard, the dialog or an
	item's menu is shown or Blizzard's color picker is open. In combat it does
	nothing (SetPropagateKeyboardInput is protected); the window is closed then
	anyway (st.Config's PLAYER_REGEN_DISABLED), and opening refuses.

	Every frame and texture here is SaftUI's; nothing is written onto Blizzard
	frames or tables.

	The window is split by job, its files loading in Config/load.xml's order:
	optionslayout.lua (OW.LAYOUT, the sidebar's width and entries, the
	window's height; it makes OW and OW.S), this one, then
	optionsresize.lua (growing taller), optionsnav.lua (the sidebar, the
	tabs and the picker), optionssmalldialog.lua (OW:OpenDialog) and
	optionsmenu.lua (OW:OpenMenu). OW.S holds what they share
	(optionslayout.lua says how).
]]

local OW = st.OptionsWindow
local S = OW.S

local floor, max, ceil = math.floor, math.max, math.ceil
local format = string.format

-- From optionslayout.lua.
local ArtReach, FOOTER_GAP = S.ArtReach, S.FOOTER_GAP

------------------------------------------------------------------ the mockup's numbers

local PAD = 28 -- the main column's left padding
local CONTENT_WIDTH = OB.WIDTH -- the body: two columns of 367 with a gap of 40
local ROW_HEIGHT = OB.ROW_HEIGHT
local FIELD_HEIGHT = W.FIELD_HEIGHT

local HEAD_TOP = 20 -- the title's top, in the main column
local TABS_TOP = 87 -- the first tab line's top
local TAB_HEIGHT, SUBTAB_GAP = 24, 10
local SEARCH_DELAY = 0.25
local SEARCH_TEXT_INSET = 8 -- the search box's text, in from its edges, and its hint
local PICKER_GAP = 12

local SCROLL_STEP = OB.SCROLL_STEP

-- The sidebar.
local BRAND_HEIGHT = 73
local ACTION_PAD, ACTION_HEIGHT = 10, 24
local NAV_ITEM = 26
local FOOT_HEIGHT = 30

local SIDEBAR_BG = { 0.09, 0.09, 0.09, 1 } -- #171717

local POINTS = {
	TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
	BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
local EMPTY = {}

------------------------------------------------------------------ state

local F = {} -- the window's frames (OW.GetFrames, for tests)
local root -- the tree drawn: Config:GetOptionsTable()'s args
local state = { page = nil, selections = {}, search = '' } -- what the user chose
S.shown = {} -- what the last render drew: page, tab, subtab, pick
local results -- the current search's results
local pageBody -- the body (OB.New) the page is drawn in: its cells are the drawn rows
local rendering, pending, dragging = false, false, false
S.sizing = nil -- the resize under way (StartResize), or nil
local searchDue -- seconds until the search runs
local focusPath -- a search result's path, brought into view by the next render
local focusMenu -- that result is in the item's menu: open it once drawn
local menuFor -- the item widget whose menu the render opens at its end (focusMenu)
local contentHeight = 0
S.scrollOffset, S.navOffset, S.navHeight = 0, 0, 0
S.filledTo = nil -- the view height the last page's fill rows were drawn to, or nil
local renders = 0
-- Whether the window draws its controls in Blizzard's Settings art: under
-- SaftUI's theme Blizzard (W.BlizzardLook), read once a render, so a theme
-- change reaches them when the window renders again. Under Thick and Thin
-- they keep the mockup's look.
S.blizzard = false
-- The layout the window is in (OW.LAYOUT), and the look it was laid out for
-- (Relayout): nil until the window is built.
S.layout = OW.LAYOUT.own
local laidOut = nil

local Colors, Normal, Grey, Blue = OB.Colors, OB.Normal, OB.Grey, OB.Blue

-- Whether Blizzard's color picker is open (its keys and its changes are its).
local function ColorPickerShown() return ColorPickerFrame and ColorPickerFrame:IsShown() end

-- An item's menu (optionsmenu.lua, loaded after this file): whether one is
-- shown, and closing it.
local function MenuShown() return OW.IsMenuShown ~= nil and OW:IsMenuShown() end
local function CloseMenu() if OW.CloseMenu then OW:CloseMenu() end end

-- The Esc catcher of the window and of its small dialog: a frame, shown only
-- with its owner, that closes it on Esc. A box's keys and the owner's own
-- exceptions (held(), and Blizzard's color picker) go on to the game; nothing
-- is done in combat (SetPropagateKeyboardInput is protected).
local function EscapeKeys(parent, held, close)
	local keys = CreateFrame('Frame', nil, parent)
	keys:Hide()
	keys:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		if GetCurrentKeyBoardFocus() or held() or ColorPickerShown() then
			self:SetPropagateKeyboardInput(true)
			return
		end
		local escape = key == 'ESCAPE'
		self:SetPropagateKeyboardInput(not escape)
		if escape then close() end
	end)
	return keys
end

local function Copy(t)
	local copy = {}
	for k, v in pairs(t or EMPTY) do copy[k] = v end
	return copy
end

------------------------------------------------------------------ small pieces

-- The window's fonts and pieces (optionsbody.lua).
local Text, Line, Pool, ReleaseAll = OB.Text, OB.Line, OB.Pool, OB.ReleaseAll

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

local pools = {}

local function Inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

------------------------------------------------------------------ position and height

--[[
	st.config.global.optionsWindow = { point = 'CENTER', x, y, height }: where
	the user left the window, its centre's offset from the screen's, and the
	height they dragged it to (nil until they do). A move keeps the height saved
	as it was, and only a resize writes it: a height saved by a move under
	Blizzard (728) would open Thick's window 728 tall.
]]

local function SavedPosition()
	local saved = st.config.global.optionsWindow
	if type(saved) == 'table' and POINTS[saved.point] and type(saved.x) == 'number' and type(saved.y) == 'number' then
		return saved.point, saved.x, saved.y
	end
	return 'CENTER', 0, 0
end

local function RestorePosition()
	local point, x, y = SavedPosition()
	F.window:SetHeight(OW.WindowHeight(F.layout or OW.LAYOUT.own))
	F.window:ClearAllPoints()
	F.window:SetPoint(point, UIParent, point, x, y)
end

-- Where the user left the window, as its center's offset from the screen's,
-- in whole units (pixels, at SaftUI's scale). The saved height stays.
local function SavePosition()
	local cx, cy = F.window:GetCenter()
	local ux, uy = UIParent:GetCenter()
	if not (cx and ux) then return end
	local saved = st.config.global.optionsWindow
	local height = type(saved) == 'table' and type(saved.height) == 'number' and saved.height or nil
	st.config.global.optionsWindow = { point = 'CENTER', x = floor(cx - ux + 0.5), y = floor(cy - uy + 0.5), height = height }
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

-- A scroll frame's offset and its bar, 10 to the right of what it holds, or
-- under Blizzard Blizzard's minimal scroll bar, 12 to its right (optionsbody.lua).
local ScrollTo = OB.ScrollTo

local function SetScroll(offset)
	S.scrollOffset = ScrollTo(F.body, F.bar, offset, contentHeight)
end

-- The sidebar's nav: no bar under Thick and Thin; under Blizzard a narrow
-- one, 4 right of its rows.
local NAV_BAR_GAP = 4

local function SetNavScroll(offset)
	S.navOffset = ScrollTo(F.navFrame, F.navBar, offset, S.navHeight, NAV_BAR_GAP)
end

------------------------------------------------------------------ re-rendering

-- Whether the user is in the middle of something a render would break.
local function Busy()
	-- A drag ends when the button comes up, even if the slider's OnMouseUp
	-- never arrived; so does a scroll bar's held thumb (W.ScrollBarHeld).
	if dragging and not IsMouseButtonDown('LeftButton') then dragging = false end
	if dragging or S.sizing or W.ListOwner() or W.ConfirmText() or W.ScrollBarHeld() then return true end
	if ColorPickerShown() then return true end
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
	if ColorPickerShown() then
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
	S.scrollOffset = 0
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
		S.scrollOffset = 0
		OW:Render()
	else
		searchDue = SEARCH_DELAY
		F.ticker:Show()
	end
end

-- A search result: its page, picker and tabs, with the row brought into view.
-- A footer's result opens its page as it is: the footer isn't in the picker or
-- the tabs, so the page's own pick and tab stay, and its key can't match one.
-- A result in an item's menu (menu) opens the menu too, once drawn.
local function GoTo(path, footer, menu)
	if footer then
		if path[1] then OW:Navigate(path[1]) end
		return
	end
	local pageKey, selection = OM.SelectionForPath(root, path)
	if not pageKey then return end
	focusPath, focusMenu = path, menu and true or nil
	OW:Navigate(pageKey, selection)
end

-- A tab or the picker (optionsnav.lua) chose key for slot ('tab', 'subtab'
-- or 'pick').
local function Select(slot, key)
	local selection = state.selections[state.page] or {}
	state.selections[state.page] = selection
	selection[slot] = key
	if state.search ~= '' or searchDue then ClearSearch() end
	CloseMenu()
	S.scrollOffset = 0
	OW:SetStatus(nil)
	OW:Render()
end

------------------------------------------------------------------ the footer control

-- A page's footer control (see the top): its options, read and set through
-- the model as a page's rows are (Changed: a set draws the page again), from
-- a tree of their own, as the picker's and the dialog's.
local FOOTER_KEY = 'footer' -- the footer group's key in that tree
local FOOTER_SPACING = 8 -- after the label, and between the widgets
local footerInset = 0 -- the region's left that edit mode's buttons take (OW:SetFooterInset)

local function ReleaseFooterControl()
	for _, widget in ipairs(F.footerWidgets) do
		widget.frame.footerTip = nil
		widget:Release()
	end
	wipe(F.footerWidgets)
	F.footerControl:Hide()
end

-- A footer widget's tooltip (a pick's control's too), its option's name and
-- desc as a body's row shows them. An execute button has the hook for it
-- (widget.onTip); any other widget's frame gets one, once (the frame is
-- pooled), that reads footerTip. The game calls a script with the mouse's
-- motion as a second argument, so these take none.
local function TipFooterWidget(widget, row)
	local owner = widget.frame
	local tip = { row = row }
	local function Tip(on)
		if on then OB.ShowTip(tip, owner) else OB.HideTip(tip, owner) end
	end
	if row.type == 'execute' then
		widget.onTip = Tip
		return
	end
	if not owner.footerTipHooked then
		owner.footerTipHooked = true
		owner:HookScript('OnEnter', function(self) if self.footerTip then self.footerTip(true) end end)
		owner:HookScript('OnLeave', function(self) if self.footerTip then self.footerTip(false) end end)
	end
	owner.footerTip = Tip
end

-- A control's widgets, one for each row of its view, made in parent and bound
-- to the control's own tree, listed in into; place (optional) is called with
-- each widget.
local function CreateControlWidgets(view, tree, parent, into, place)
	for _, section in ipairs(view.sections) do
		for _, row in ipairs(section.rows) do
			local widget = W.Create(parent, row.type)
			widget:Bind(tree, row, Changed)
			TipFooterWidget(widget, row)
			if place then place(widget) end
			into[#into + 1] = widget
		end
	end
end

-- footer (a page's view.footer, or nil for none) drawn into the control.
local function DrawFooterControl(footer)
	if not footer then return end
	local tree = { [FOOTER_KEY] = footer }
	local view = OM.BuildView(tree, FOOTER_KEY)
	if not view then return end -- hidden
	F.footerLabel:SetText(view.title)
	CreateControlWidgets(view, tree, F.footerControl, F.footerWidgets)
	F.footerControl:SetShown(#F.footerWidgets > 0)
end

-- The region's parts: the status line from edit mode's buttons (footerInset)
-- and, while a page's footer control shows, the control where
-- OW.FooterPlace puts it, the label, then its widgets left to right, with the
-- status line ending FOOTER_GAP before it. An error to read comes before the
-- control's place: while the status has text the label is dropped and the
-- widgets are at the region's right end, and when even then the status would
-- have no room (edit mode's buttons take it), the control is hidden until
-- the status clears (OW:SetStatus places the footer again).
local function PlaceFooter()
	local region, control, status = F.footerRegion, F.footerControl, F.status
	status:ClearAllPoints()
	status:SetPoint('LEFT', region, 'LEFT', footerInset, 0)
	local label, widgets = F.footerLabel, F.footerWidgets
	if #widgets == 0 then
		status:SetPoint('RIGHT', region, 'RIGHT', 0, 0)
		status:Show()
		return
	end
	local labelWidth = ceil(label:GetStringWidth()) + FOOTER_SPACING
	local widgetsWidth = (#widgets - 1) * FOOTER_SPACING
	for _, widget in ipairs(widgets) do widgetsWidth = widgetsWidth + widget:GetWidth() end
	local regionWidth = floor(region:GetWidth() + 0.5)
	local x, labelShown = OW.FooterPlace(regionWidth, footerInset, labelWidth, widgetsWidth)
	if (status:GetText() or '') ~= '' then
		x, labelShown = regionWidth - widgetsWidth, false
		if x - FOOTER_GAP <= footerInset then
			control:Hide()
			status:SetPoint('RIGHT', region, 'RIGHT', 0, 0)
			status:Show()
			return
		end
	end
	control:Show()
	label:SetShown(labelShown)
	local left = labelShown and labelWidth or 0
	for _, widget in ipairs(widgets) do
		widget.frame:ClearAllPoints()
		widget.frame:SetPoint('LEFT', control, 'LEFT', left, 0)
		left = left + widget:GetWidth() + FOOTER_SPACING
	end
	control:ClearAllPoints()
	control:SetPoint('LEFT', region, 'LEFT', x, 0)
	control:SetWidth(left - FOOTER_SPACING)
	status:SetPoint('RIGHT', control, 'LEFT', -FOOTER_GAP, 0)
	status:SetShown(x - FOOTER_GAP > footerInset)
end

------------------------------------------------------------------ a pick's control

-- A pick's control (its group's pickerControl, SaftUI's field: OM.BuildView's
-- view.picker.control): a group whose options, buttons, are drawn on the
-- picker's line, PICKER_CONTROL_GAP right of the picker and apart, each the
-- options kit's own widget (so it takes both looks) showing its option's
-- tooltip, read and set through the model from a tree of their own, as the
-- footer control's (Changed: a set draws the page again). They go with the
-- page's rows, and a pick without one draws none.
local PICKER_CONTROL_KEY = OM.PICKER_CONTROL_KEY -- the control's key in that tree
local PICKER_CONTROL_GAP = 12 -- as the buttons on a line are apart

local function ReleasePickerControl()
	for _, widget in ipairs(F.pickerWidgets) do
		widget.frame.footerTip = nil
		widget:Release()
	end
	wipe(F.pickerWidgets)
end

-- picker (a page's view.picker, drawn) and its control, if any, beside it.
local function DrawPickerControl(picker)
	local control = picker and picker.control
	if not control then return end
	local tree = { [PICKER_CONTROL_KEY] = control }
	local view = OM.BuildView(tree, PICKER_CONTROL_KEY)
	if not view then return end -- hidden
	local anchor = F.picker.frame
	CreateControlWidgets(view, tree, F.main, F.pickerWidgets, function(widget)
		-- By its left, on the picker's middle line: a button 2 taller than
		-- the picker sits 1 over and under it, on whole pixels.
		widget.frame:ClearAllPoints()
		widget.frame:SetPoint('LEFT', anchor, 'RIGHT', PICKER_CONTROL_GAP, 0)
		anchor = widget.frame
	end)
end

------------------------------------------------------------------ the body

-- The page's rows, and its footer control and a pick's control with them.
local function ReleaseBody()
	pageBody:Release()
	F.placeholder:Hide()
	ReleaseFooterControl()
	ReleasePickerControl()
end

-- The body from top down to the layout's bottom (the footer under Thick and
-- Thin, the inner frame's rim under Blizzard), its scroll frame reaching
-- bodyReach past the content. A page with a fill row has nothing to scroll,
-- so its body reaches over its own bar's place (filled, fillReach), where the
-- row draws bars of its own: the Categories tab's editor.
local function PlaceBody(top, filled)
	local reach = filled and S.layout.fillReach or S.layout.bodyReach
	F.body:ClearAllPoints()
	F.body:SetPoint('TOPLEFT', F.main, 'TOPLEFT', PAD, -top)
	F.body:SetPoint('BOTTOMRIGHT', F.main, 'BOTTOMRIGHT', -(S.layout.rightPad - reach), S.layout.bodyBottom)
end

local function SamePath(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- A search result's row, once its page is drawn: scrolled to and marked blue.
-- A result in an item's menu leaves the item's widget in menuFor, for Draw
-- to open its menu once the scroll is set.
local function BringIntoView()
	local path, menu = focusPath, focusMenu
	focusPath, focusMenu = nil, nil
	if not path then return end
	for _, cell in ipairs(pageBody.cells) do
		if cell.row.path and SamePath(cell.row.path, path) then
			S.scrollOffset = max(0, cell.y - ROW_HEIGHT)
			cell.label:SetTextColor(Colors().text.blue:GetRGB())
			if menu then menuFor = cell.widget end
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
	S.shown = { page = state.page }
	local view = state.page and OM.BuildView(root, state.page, state.selections[state.page])
	if not view then
		F.title:SetText(st.name)
		F.desc:SetText('')
		S.PlaceLine(F.tabLine, S.DrawTabRow(pools.tab, EMPTY, nil, TABS_TOP, 'tab'))
		ReleaseAll(pools.subtab)
		F.subLine:Hide()
		S.HidePicker()
		PlaceBody(TABS_TOP + TAB_HEIGHT)
		return
	end
	F.title:SetText(view.title)
	F.desc:SetText(view.desc or '')
	S.shown.tab, S.shown.subtab = view.tab, view.subtab
	S.shown.pick = view.picker and view.picker.selected

	-- A single tab is the page itself, so it isn't drawn (as in the mockup).
	local bottom = S.DrawTabRow(pools.tab, #view.tabs > 1 and view.tabs or EMPTY, view.tab, TABS_TOP, 'tab')
	S.PlaceLine(F.tabLine, bottom)
	if #view.subtabs > 1 then
		bottom = S.DrawTabRow(pools.subtab, view.subtabs, view.subtab, bottom + SUBTAB_GAP, 'subtab')
		S.PlaceLine(F.subLine, bottom)
	else
		ReleaseAll(pools.subtab)
		F.subLine:Hide()
	end
	if view.picker then
		bottom = S.DrawPicker(view.picker, bottom + PICKER_GAP)
		DrawPickerControl(view.picker)
	else
		S.HidePicker()
	end
	PlaceBody(bottom)
	-- A fill row stretches to what the body shows.
	local visible = F.body:GetHeight() or 0
	contentHeight = pageBody:Draw(view.sections, visible)
	if pageBody.filled then
		S.filledTo = visible
		PlaceBody(bottom, true)
	end
	if #pageBody.cells == 0 then Placeholder('Nothing to set here.') end
	BringIntoView()
	DrawFooterControl(view.footer)
end

-- The results page: a section per page, tabs and section, in the order found.
local function DrawSearch(pages)
	S.shown = { page = state.page }
	local count = #results
	F.title:SetText('Search')
	F.desc:SetText(format('%d%s result%s for "%s"', count, count >= 100 and '+' or '', count == 1 and '' or 's', state.search))
	S.PlaceLine(F.tabLine, S.DrawTabRow(pools.tab, EMPTY, nil, TABS_TOP, 'tab'))
	ReleaseAll(pools.subtab)
	F.subLine:Hide()
	S.HidePicker()
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
		last.rows[#last.rows + 1] = {
			key = result.path[#result.path], name = result.name, size = 'normal', path = result.path,
			footer = result.footer, menu = result.menu,
		}
	end
	contentHeight = pageBody:DrawResults(sections, function(row) GoTo(row.path, row.footer, row.menu) end)
	if count == 0 then Placeholder(format('No settings match "%s".', state.search)) end
end

-- The window's own controls in the look: the footer's buttons, the search
-- box (its text and hint start clear of Blizzard's magnifying glass) and the
-- resize grip.
local function LookControls()
	W.LookButton(F.reloadButton, S.blizzard, st.BOX_COLORS.bg)
	W.LookButton(F.closeButton, S.blizzard, st.BOX_COLORS.bg)
	local left = W.LookSearch(F.search, S.blizzard, FIELD_HEIGHT) or SEARCH_TEXT_INSET
	F.search:SetTextInsets(left, SEARCH_TEXT_INSET, 0, 0)
	F.search.hint:SetPoint('LEFT', F.search, 'LEFT', left, 0)
	S.LookGrip()
end

-- Lays the window out for a look (settings: Blizzard's), in its layout
-- (OW.LAYOUT): its size (the saved height, OW.WindowHeight), its look drawn
-- again (the metal under Blizzard; a
-- render can come before the redraw that follows a theme change), the close
-- X, the title bar, the inner frame, the sidebar, the main column and the
-- footer. Inside the main column everything keeps its place. Build runs it,
-- and Draw again when the look changed.
local function Relayout(settings)
	local L = settings and OW.LAYOUT.blizzard or OW.LAYOUT.own
	S.layout, F.layout = L, L
	local window = F.window
	window:SetSize(L.width, OW.WindowHeight(L))
	st:SetTemplate(window, 'theme', 'solid', 'window')
	-- The screen edge margin again, now the art reaches as far as the look's
	-- (the metal under Blizzard).
	st:KeepInScreenMargin(window)

	-- The close X: Blizzard's in the metal's socket, at its spot from the
	-- window's top right corner (st.ThemeArt.Close), or the mockup's at its own.
	st:UpdateCloseButton(window)
	F.close:ClearAllPoints()
	if settings then
		local close = st.ThemeArt.Close()
		F.close:SetPoint('TOPRIGHT', window, 'TOPRIGHT', close.x, close.y)
	else
		F.close:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -16, -14)
	end

	-- The metal's title bar, the window's drag strip under Blizzard, with the
	-- window's name centred on its title strip (the strip's bottom on the
	-- title bar's).
	F.titleBar:SetHeight(st.ThemeArt.TitleHeight())
	F.titleText:ClearAllPoints()
	F.titleText:SetPoint('CENTER', F.titleBar, 'BOTTOM', 0, st.ThemeArt.TitleStrip() / 2)
	F.titleBar:SetShown(settings)
	F.titleText:SetShown(settings)

	-- The inner frame, stretched over the sidebar and the main column, from
	-- under the title bar down to the footer.
	if settings then
		F.inner:SetAtlas(st.ThemeArt.Control('optionswindow').inner)
		F.inner:ClearAllPoints()
		F.inner:SetPoint('TOPLEFT', window, 'TOPLEFT', L.innerX, -L.innerTop)
		F.inner:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -L.innerX, L.footer)
	end
	F.inner:SetShown(settings)

	-- The sidebar: the brand at its top and the actions under it, or under
	-- Blizzard (the title bar names the window) no brand, the actions at its top.
	F.side:ClearAllPoints()
	F.side:SetPoint('TOPLEFT', window, 'TOPLEFT', L.sideX, -L.sideTop)
	F.side:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', L.sideX, L.sideBottom)
	F.side:SetWidth(L.sideWidth)
	F.brand:SetShown(not settings)
	-- Under Blizzard the inner frame is the sidebar's ground and edge: its
	-- fill and lines go.
	F.sideFill:SetShown(not settings)
	for _, line in ipairs(F.sideLines) do line:SetShown(not settings) end
	F.footerLine:SetShown(not settings)
	F.actionsFrame:ClearAllPoints()
	if settings then
		F.actionsFrame:SetPoint('TOPLEFT', F.side, 'TOPLEFT', 0, 0)
		F.actionsFrame:SetPoint('TOPRIGHT', F.side, 'TOPRIGHT', -1, 0)
	else
		F.actionsFrame:SetPoint('TOPLEFT', F.brand, 'BOTTOMLEFT', 0, 0)
		F.actionsFrame:SetPoint('TOPRIGHT', F.brand, 'BOTTOMRIGHT', 0, 0)
	end
	F.navContent:SetWidth(L.navWidth)
	F.profile:SetWidth(L.sideWidth - 1 - 36) -- the foot's width, 18 clear each side

	F.main:ClearAllPoints()
	F.main:SetPoint('TOPLEFT', window, 'TOPLEFT', L.mainLeft, -L.mainTop)
	F.main:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -L.mainRight, L.mainBottom)

	-- The footer: along the main column's bottom, Reload UI PAD in and Close
	-- rightPad in; under Blizzard across the window under the inner frame,
	-- the two footerX and footerY from its bottom corners.
	local footer = F.footer
	footer:ClearAllPoints()
	F.reloadButton:ClearAllPoints()
	F.closeButton:ClearAllPoints()
	if settings then
		footer:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 0, 0)
		footer:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', 0, 0)
		F.reloadButton:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', L.footerX, L.footerY)
		F.closeButton:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -L.footerX, L.footerY)
	else
		footer:SetPoint('BOTTOMLEFT', F.main, 'BOTTOMLEFT', 0, 0)
		footer:SetPoint('BOTTOMRIGHT', F.main, 'BOTTOMRIGHT', 0, 0)
		F.reloadButton:SetPoint('LEFT', footer, 'LEFT', PAD, 0)
		F.closeButton:SetPoint('RIGHT', footer, 'RIGHT', -L.rightPad, 0)
	end
	footer:SetHeight(L.footer)
	laidOut = settings -- last, so a Relayout that errors is tried again
end

local function Draw()
	S.blizzard = W.BlizzardLook()
	if S.blizzard ~= laidOut then Relayout(S.blizzard) end
	-- The window's name in the profile's font for window titles, which the
	-- Fonts tab can change.
	F.titleText:SetFontObject(st:GetFont(st.config.profile.headers.font))
	LookControls()
	ReleaseBody()
	contentHeight, S.filledTo = 0, nil
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
	S.DrawSidebar(entries)
	menuFor = nil
	if state.search ~= '' and results then DrawSearch(pages) else DrawPage() end
	PlaceFooter()
	F.content:SetHeight(max(1, contentHeight))
	F.body:UpdateScrollChildRect()
	SetScroll(S.scrollOffset)
	-- A search result's item: its menu, now its dots are where they stay.
	if menuFor then
		local widget = menuFor
		menuFor = nil
		if widget.OpenMenu then widget:OpenMenu() end
	end
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
	S.StopResize()
	F.keys:EnableKeyboard(false)
	F.keys:Hide()
	pending, dragging = false, false
	ClearSearch()
	ReleaseBody()
	W.CloseList()
	W.CancelConfirm()
	OW:SetStatus(nil)
	CloseMenu()
	OW:CloseDialog()
	if st.EditModeFrames then st.EditModeFrames:UpdateFooter() end
end

-- The search box, at the top of the sidebar's actions (parent), over Edit
-- mode and the command buttons: optionsnav.lua's DrawActions places it.
local function BuildSearch(parent)
	local search = W.Box(st:CreateFrame('EditBox', nil, parent))
	search:SetHeight(FIELD_HEIGHT) -- its width and place are the sidebar's (optionsnav.lua)
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
	return search
end

-- The parts whose place or size the layout gives are placed by Relayout.
local function BuildSidebar(window)
	local side = CreateFrame('Frame', nil, window)
	F.side = side
	local bg = side:CreateTexture(nil, 'BACKGROUND')
	bg:SetAllPoints(side)
	bg:SetColorTexture(unpack(SIDEBAR_BG))
	F.sideFill, F.sideLines = bg, {}
	local edge = Line(side)
	F.sideLines[#F.sideLines + 1] = edge
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
	F.sideLines[#F.sideLines + 1] = EdgeLine(brand, 'BOTTOM')
	F.brand = brand

	local actions = CreateFrame('Frame', nil, side)
	actions:SetHeight(ACTION_PAD * 2 + ACTION_HEIGHT)
	F.sideLines[#F.sideLines + 1] = EdgeLine(actions, 'BOTTOM')
	F.actionsFrame, F.actions = actions, {}
	F.search = BuildSearch(actions)

	-- The profile's name at the bottom.
	local foot = CreateFrame('Frame', nil, side)
	foot:SetPoint('BOTTOMLEFT', side, 'BOTTOMLEFT', 0, 0)
	foot:SetPoint('BOTTOMRIGHT', side, 'BOTTOMRIGHT', -1, 0)
	foot:SetHeight(FOOT_HEIGHT)
	F.sideLines[#F.sideLines + 1] = EdgeLine(foot, 'TOP')
	F.profile = Text(foot, 'small')
	F.profile:SetPoint('LEFT', foot, 'LEFT', 18, 0)
	F.profile:SetTextColor(Grey())
	F.foot = foot

	local nav = CreateFrame('ScrollFrame', nil, side)
	nav:SetPoint('TOPLEFT', actions, 'BOTTOMLEFT', 0, -1)
	nav:SetPoint('BOTTOMRIGHT', foot, 'TOPRIGHT', 0, 1)
	local content = CreateFrame('Frame', nil, nav)
	content:SetHeight(1)
	nav:SetScrollChild(content)
	nav:EnableMouseWheel(true)
	nav:SetScript('OnMouseWheel', function(_, delta) SetNavScroll(S.navOffset - delta * NAV_ITEM * 2) end)
	F.navFrame, F.navContent, F.nav = nav, content, {}
	F.navBar = OB.ScrollBar(side, SetNavScroll, { narrow = true, step = NAV_ITEM * 2, flat = false })
	pools.nav = Pool(S.MakeNavItem)
	pools.group = Pool(S.MakeNavGroup)
end

local function BuildMain(window)
	local main = CreateFrame('Frame', nil, window)
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

	F.close = st:CreateCloseButton(window)

	F.tabLine, F.subLine = Line(main), Line(main)
	F.tabLine:SetHeight(1)
	F.subLine:SetHeight(1)
	pools.tab, pools.subtab = Pool(S.MakeTab), Pool(S.MakeTab)
	F.tabs, F.subtabs = pools.tab.used, pools.subtab.used

	F.pickerLabel = Text(main, 'field')
	F.picker = W.Create(main, 'select')
	F.pickerWidgets = {} -- a pick's control, beside the picker (DrawPickerControl)
	S.HidePicker()

	-- The body.
	local body = CreateFrame('ScrollFrame', nil, main)
	local content = CreateFrame('Frame', nil, body)
	content:SetSize(CONTENT_WIDTH, 1)
	body:SetScrollChild(content)
	body:EnableMouseWheel(true)
	body:SetScript('OnMouseWheel', function(_, delta) SetScroll(S.scrollOffset - delta * SCROLL_STEP) end)
	-- A fill row follows the body's height: drawn again once it changes.
	body:SetScript('OnSizeChanged', function(_, _, height)
		if S.filledTo and floor((height or 0) + 0.5) ~= floor(S.filledTo + 0.5) then Schedule() end
	end)
	F.body, F.content = body, content
	F.bar = OB.ScrollBar(main, SetScroll, { step = SCROLL_STEP })
	F.placeholder = Text(content, 'label')
	F.placeholder:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, -OB.TOP)
	F.placeholder:SetTextColor(Grey())
	F.placeholder:Hide()

	pageBody = OB.New(content, root, Changed, CONTENT_WIDTH)
end

local function BuildFooter()
	local footer = CreateFrame('Frame', nil, F.main)
	F.footerLine = EdgeLine(footer, 'TOP')
	F.footer = footer

	F.reloadButton = W.Button(footer, 'Reload UI', function() ReloadUI() end)
	F.closeButton = W.Button(footer, 'Close', function() OW:Close() end)

	-- Edit mode's controls go here (from the left); the status line shows
	-- validate errors (from the right); a page's footer control sits in it
	-- too (PlaceFooter places them).
	local region = CreateFrame('Frame', nil, footer)
	region:SetPoint('LEFT', F.reloadButton, 'RIGHT', FOOTER_GAP, 0)
	region:SetPoint('RIGHT', F.closeButton, 'LEFT', -FOOTER_GAP, 0)
	region:SetHeight(26)
	F.footerRegion = region
	F.status = Text(footer, 'field', 'RIGHT')
	F.status:SetPoint('LEFT', region, 'LEFT', 0, 0)
	F.status:SetPoint('RIGHT', region, 'RIGHT', 0, 0)
	F.status:SetTextColor(Colors().text.red:GetRGB())

	-- The footer control, over edit mode's buttons' frame (its level + 2,
	-- EditMode/footer.lua) should the two ever meet: its label, then its
	-- widgets (DrawFooterControl).
	local control = CreateFrame('Frame', nil, region)
	control:SetHeight(26)
	control:SetFrameLevel(region:GetFrameLevel() + 3)
	control:Hide()
	F.footerControl, F.footerWidgets = control, {}
	F.footerLabel = Text(control, 'field')
	F.footerLabel:SetPoint('LEFT', control, 'LEFT', 0, 0)
	F.footerLabel:SetTextColor(Grey())
end

-- Under Blizzard: the metal's title bar, the window's drag strip, with the
-- window's name ("SaftUI Options") on it; and the inner frame
-- (Options_InnerFrame), a texture of the window between its fill and the
-- metal. Shown only under Blizzard (Relayout).
local function BuildTitleBar(window)
	local bar = CreateFrame('Frame', nil, window)
	bar:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, 0)
	bar:SetPoint('TOPRIGHT', window, 'TOPRIGHT', 0, 0)
	bar:Hide()
	Draggable(bar)
	-- The close X sits over the bar's right end, in the metal's socket: over
	-- the bar, so a click on it is the button's.
	F.close:SetFrameLevel(bar:GetFrameLevel() + 1)
	local text = bar:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(st:GetFont(st.config.profile.headers.font))
	text:SetText(format('%s Options', st.name))
	F.titleBar, F.titleText = bar, text

	F.inner = window:CreateTexture(nil, 'ARTWORK')
	F.inner:Hide()
end

local function Build()
	local window = st:CreateFrame('Frame', nil, UIParent)
	window:SetFrameStrata('FULLSCREEN_DIALOG')
	window:SetFrameLevel(100)
	window:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	window:SetMovable(true)
	-- Dragged by its header, so it keeps to the margin too, with its art.
	st:KeepInScreenMargin(window, function() return ArtReach(S.layout) end)
	-- A margin change takes its height in at once, as chat and the totem bar
	-- take their places in.
	hooksecurefunc(st, 'UpdateScreenMargin', S.ApplyHeight)
	window:EnableMouse(true)
	window:Hide()
	F.window = window
	W.SetDialogAnchor(window)

	BuildSidebar(window)
	BuildMain(window)
	BuildFooter()
	BuildTitleBar(window)
	S.BuildResize(window)

	-- Esc, only while the window is shown. The dialog's Esc is its own (its
	-- catcher, in optionssmalldialog.lua, closes it), and so is an item's
	-- menu's (optionsmenu.lua).
	F.keys = EscapeKeys(window, function() return OW:IsDialogShown() or MenuShown() end, function() OW:Close() end)

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
		EM:On('Enabled', S.UpdateEditModeButton)
		EM:On('Disabled', S.UpdateEditModeButton)
	end

	-- Its size, its look (st:SetTemplate) and its parts' places, in the
	-- layout of the look now.
	Relayout(W.BlizzardLook())
	PlaceBody(TABS_TOP + TAB_HEIGHT)
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
			S.scrollOffset = 0
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
	CloseMenu()
	S.scrollOffset = 0
	self:SetStatus(nil)
	self:Render()
end

-- Draws the page (or search results) again from the model, and an open
-- dialog with it (optionssmalldialog.lua): what changed the tree may be its.
-- Then an open item's menu follows its item (optionsmenu.lua).
function OW:Render()
	if rendering or not self:IsShown() or not root then return end
	rendering, pending = true, false
	xpcall(Draw, geterrorhandler())
	xpcall(S.FollowDialog, geterrorhandler())
	if S.FollowMenu then xpcall(S.FollowMenu, geterrorhandler()) end
	rendering = false
	renders = renders + 1
end

-- A new tree (a profile change rebuilt it), drawn on the next frame.
function OW:SetRoot(tree)
	root = tree
	Schedule()
end

function OW:SetStatus(text)
	if not F.status then return end
	F.status:SetText(text or '')
	PlaceFooter()
end

function OW:GetFooter()
	if not F.window then Build() end
	return F.footerRegion
end

-- Edit mode's buttons take the region's left (EditMode/footer.lua): the
-- status line starts width in, clear of them, and a page's footer control
-- keeps clear of them too (PlaceFooter).
function OW:SetFooterInset(width)
	footerInset = width or 0
	if F.status then PlaceFooter() end
end

-- What the last render drew: { page, tab, subtab, pick, search }.
function OW:GetState()
	return { page = S.shown.page, tab = S.shown.tab, subtab = S.shown.subtab, pick = S.shown.pick, search = state.search }
end

-- For tests: the frames, the drawn body rows, how many renders ran.
function OW.GetFrames() return F end
function OW.GetDrawnRows() return pageBody and pageBody.cells or EMPTY end
function OW.GetRenderCount() return renders end

-- st.Config:Refresh notifies AceConfigRegistry: re-render on the next frame.
LibStub('AceConfigRegistry-3.0').RegisterCallback(OW, 'ConfigTableChange', function(_, appName)
	if appName == st.name and not rendering then Schedule() end
end)

------------------------------------------------------------------ for the later files

S.F, S.Colors, S.Schedule, S.SavePosition, S.Inside = F, Colors, Schedule, SavePosition, Inside
S.ColorPickerShown, S.EscapeKeys = ColorPickerShown, EscapeKeys
S.SetScroll, S.SetNavScroll = SetScroll, SetNavScroll
S.state, S.pools, S.Normal, S.Grey, S.Blue, S.Button, S.Select = state, pools, Normal, Grey, Blue, W.Button, Select
S.PAD, S.FIELD_HEIGHT, S.TAB_HEIGHT = PAD, FIELD_HEIGHT, TAB_HEIGHT
S.ACTION_PAD, S.ACTION_HEIGHT, S.NAV_ITEM = ACTION_PAD, ACTION_HEIGHT, NAV_ITEM
