local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

--[[
	An item's menu (the item: optionsitem.lua; its option's fields:
	optionsmodel.lua's header): OW:OpenMenu, OW:CloseMenu, OW:IsMenuShown,
	OW.MenuPlace and OW.GetMenuFrames on SaftUI's options window
	(st.OptionsWindow, optionswindow.lua). It loads after
	optionssmalldialog.lua (Config/load.xml), modelled on its small dialog,
	and takes what it needs from OW.S; the window's render draws it again
	through S.FollowMenu, after S.FollowDialog.

	  OW:OpenMenu(widget) -> boolean
	      opens the menu of a widget: its own, widget:Menu() -> group, title
	      (a font row's typeface menu: optionsfont.lua), when the widget has
	      Menu, else its row's option's menu (an item's), a group; closing any
	      open one first. false in combat, when the item is
	      disabled (a search result can ask, though its dots can't), or when
	      the row has no menu (a Menu that gives nil). It remembers the item as { body =
	      widget.rowBody, path = widget.row.path }, the body that drew it (the
	      window's page or the small dialog's) and its path there.
	  OW:CloseMenu(body)   closes it; with body, only when its item is in it
	  OW:IsMenuShown(widget) -> boolean
	      whether it's shown; with widget, whether it's that item's
	  OW.MenuPlace(anchor, width, height, screenWidth, screenHeight, margin)
	      -> point, relPoint, x, y: where a menu width x height goes by the
	      dots (anchor = { left, right, top, bottom }, their rect, in the
	      menu's units), inside the screen less margin ({ left, right, top,
	      bottom }, the screen edge margin st:KeepInScreenMargin clamps the
	      menu to; none when nil): its TOPRIGHT on the dots' BOTTOMRIGHT, 4
	      below; its left edge past the margin's, TOPLEFT on BOTTOMLEFT
	      instead (unless that goes further past the right one); its bottom
	      past the margin's, above (BOTTOM* on TOP*, 4 above) when there's
	      more room there.
	  OW.GetMenuFrames() -> { frame, catcher, title, content, body, keys,
	      owner = { body, path } } (owner nil while closed), for tests.
	  A part row's dots (an item with a summary) are drawn in the accent while
	  its menu is open (Kit.MarkSlot), and as they were when it closes.

	The menu: a frame over UIParent at FULLSCREEN_DIALOG, level 410 (over the
	small dialog's 300), 400 wide, drawn as the small dialog is
	(st:SetTemplate(frame, 'theme', 'solid', 'panel'): under Blizzard the
	panel art), kept in the screen edge margin. Its title (the item's
	menuTitle, else its name; the section font, Text > Muted) 12 in and 10 down;
	under it a plain content frame (no scroll frame: it is as tall as what it
	holds, so nothing opened from it is cut off) holding a body of its own,
	OB.New(content, OM.MenuRoot({ menu = group }), MenuChanged, 376), told it is
	a half body (body:SetWidth(376, true), as the window's half width lays a
	page out: OB.HalfSize), which draws OM.BuildView(root, OM.MENU_KEY).sections:
	two small rows to a line (the 376's halves), every other row a line of its
	own, on panels under Thick and Thin (a closing line of
	buttons floats under its panel), none under Blizzard. The menu is as tall
	as its title and its body: its last row ends 12 above its edge, or a
	closing line of buttons 24 (OB.FLOAT_GAP), as far as it floats under the
	panel above it. Its
	content's parent is the menu, which the hover lines' watcher takes for
	the body's view (optionsshare.lua). Its catcher: a frame over UIParent at
	FULLSCREEN_DIALOG level 400 that takes the mouse and closes the menu on a
	click (OnMouseDown), but not while SaftUI's color picker is open (that
	click is the picker's: it cancels, and the color widget the menu holds
	must still be there to put its color back). The catcher and the menu
	take the mouse wheel and do nothing with it, so the page under an open
	menu doesn't scroll away from it (the menu's own content doesn't
	scroll). Its keys: the window's EscapeKeys on the menu, Esc closing it
	(the window's and the dialog's own pass Esc on while it shows). A
	dropdown's list and a confirm draw at TOOLTIP, above it: their catchers
	close them and leave the menu, and Esc closes the list first.

	A set in it (MenuChanged): a failed validate shows in the status line of
	what its item is in, the window's, or the small dialog's when the item is
	one of its rows (the window's sits behind it), and nothing is drawn
	again; mid-drag the menu's own rows follow in place (body:Refresh, as
	the window's do); otherwise the window renders (OW:Render), drawing the
	page (the item's marks) and the menu again, or with the window closed
	the small dialog and the menu. While SaftUI's color picker is open it
	waits, as the window does.

	The menu's frame is anchored to its item's dots, which belong to a pooled
	widget, so it is taken off them (ClearAllPoints) when it hides, which is
	what stops the loop reproduced from a font row's menu, and again before each
	draw of its rows, as defence for a redraw while shown (FollowMenu): those
	rows are drawn before the menu is anchored again, and a row's widget may be
	that very widget (a face-only font row), which would anchor a row to a cell
	that hangs from its own dots, an anchor loop. Each has a test of its own.

	Following its item (S.FollowMenu, on every render after the dialog's): it
	finds its item's cell again in owner.body's cells by path, asks that
	cell's widget for its menu again, re-anchors to the cell's dots
	(OW.MenuPlace) and draws its body again (the values, title and menu the
	new row has); with no cell of that path, or a widget whose menu is now
	nil (a font row whose value is a shared font again), it closes.
	While it's busy (a list or a confirm open from it, its slider held, one of
	its boxes typed in) its rows aren't drawn again, as FollowDialog waits: it
	only moves onto its item's new dots, unless that cell is gone or its
	widget gives no menu, when it closes.

	It closes on Esc, a click outside, OW:Navigate, a tab or pick (Select), a
	search result's GoTo (through OW:Navigate), the window hiding (combat
	closes the window), the small dialog hiding or opening again when its
	item is the dialog's, and entering combat. Closing closes a list or
	confirm still open from it, then releases its body.
]]

local OW = st.OptionsWindow
local S = OW.S

local max = math.max

local Text, Muted = OB.Text, OB.Muted
local Inside, EscapeKeys, ColorPickerShown = S.Inside, S.EscapeKeys, S.ColorPickerShown

local MENU_WIDTH, MENU_PAD = 400, 12
local BODY_WIDTH = MENU_WIDTH - 2 * MENU_PAD -- 376: the hover line beside a 170 control fits
local TITLE_TOP, TITLE_GAP = 10, 8 -- the title's top; its bottom to the first row
-- The content's top: its first rows (OB.TOP down it) TITLE_GAP under the title.
local CONTENT_TOP = TITLE_TOP + OB.TITLE_HEIGHT + TITLE_GAP - OB.TOP
local DOTS_GAP = 4 -- between the dots and the menu
local MENU_LEVEL, CATCHER_LEVEL = 410, 400 -- over the small dialog (300)

local M = {} -- the menu's frames and body, and its owner while it shows

------------------------------------------------------------------ where it goes

local NO_MARGIN = { left = 0, right = 0, top = 0, bottom = 0 }

function OW.MenuPlace(anchor, width, height, screenWidth, screenHeight, margin)
	margin = margin or NO_MARGIN
	-- Right-aligned, unless that passes the margin's left and left-aligned
	-- passes its right by less.
	local side = 'RIGHT'
	local pastLeft = margin.left - (anchor.right - width)
	if pastLeft > 0 then
		local pastRight = anchor.left + width - (screenWidth - margin.right)
		if pastRight < pastLeft then side = 'LEFT' end
	end
	-- Below, unless its bottom passes the margin's and above has more room.
	local below = anchor.bottom - DOTS_GAP - height - margin.bottom
	local above = screenHeight - margin.top - (anchor.top + DOTS_GAP + height)
	if below < 0 and above > below then
		return 'BOTTOM' .. side, 'TOP' .. side, 0, DOTS_GAP
	end
	return 'TOP' .. side, 'BOTTOM' .. side, 0, -DOTS_GAP
end

-- The menu on dots (an item's), by OW.MenuPlace, anchored to them so it
-- moves with them (the page scrolled). The margin is the one the menu is
-- clamped to (st:KeepInScreenMargin, in its own units), so a menu placed
-- below is never pushed back up over its dots by the clamp.
local function Anchor(dots)
	local frame = M.frame
	local left, right, top, bottom = dots:GetLeft(), dots:GetRight(), dots:GetTop(), dots:GetBottom()
	local point, relPoint, x, y = 'TOPRIGHT', 'BOTTOMRIGHT', 0, -DOTS_GAP
	if left and right and top and bottom then
		local scale = dots:GetEffectiveScale() / frame:GetEffectiveScale()
		local units = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
		local mLeft, mRight, mTop, mBottom = st:GetScreenMargin(frame)
		point, relPoint, x, y = OW.MenuPlace(
			{ left = left * scale, right = right * scale, top = top * scale, bottom = bottom * scale },
			frame:GetWidth(), frame:GetHeight(), UIParent:GetWidth() * units, UIParent:GetHeight() * units,
			{ left = mLeft, right = mRight, top = mTop, bottom = mBottom })
	end
	frame:ClearAllPoints()
	frame:SetPoint(point, dots, relPoint, x, y)
end

------------------------------------------------------------------ drawing

local function SamePath(a, b)
	if #a ~= #b then return false end
	for i = 1, #a do
		if a[i] ~= b[i] then return false end
	end
	return true
end

-- The drawn item cell of body at path, with its dots, or nil.
local function ItemCell(body, path)
	for _, cell in ipairs(body.cells) do
		if cell.row.path and SamePath(cell.row.path, path) and cell.widget and cell.widget.dots then return cell end
	end
end

-- The rows again, and the menu as tall as its title and them.
local function DrawBody()
	M.body:Release()
	local view = OM.BuildView(M.root, OM.MENU_KEY)
	local height = view and M.body:Draw(view.sections) or 0
	M.content:SetHeight(max(1, height))
	-- The body ends OB.BOTTOM under its last row: the menu's own padding
	-- instead; under a closing line of buttons (off the panel), OB.FLOAT_GAP,
	-- as far as the line is under the rows above it.
	local foot = M.body.endsFloating and OB.FLOAT_GAP or MENU_PAD
	M.frame:SetHeight(CONTENT_TOP + (height > 0 and height - OB.BOTTOM or OB.TOP) + foot)
end

-- The menu of a widget's row: the widget's own (widget:Menu(): a font row's
-- typeface menu, built on each ask, with its title; nil when it has none now),
-- else the row's option's menu, a group (its title is menuTitle's or the
-- row's name, drawn by Draw).
local function MenuOf(widget)
	if type(widget.Menu) == 'function' then return widget:Menu() end
	local menu = widget.row and widget.row.option and widget.row.option.menu
	if type(menu) == 'table' then return menu end
end

-- The menu of an item's row (in body, the body that drew it) drawn, and on
-- its dots. menu is MenuOf's group, and title its own title when the widget
-- gave one.
local function Draw(body, row, dots, menu, title)
	M.owner = { body = body, path = row.path }
	-- A part row's dots are open while its menu is (the last ones, possibly another
	-- pooled widget's by now, are let go).
	if M.dots then W.Kit.MarkSlot(M.dots, false) end
	M.dots = type(row.option) == 'table' and type(row.option.summary) == 'function' and dots or nil
	if M.dots then W.Kit.MarkSlot(M.dots, true) end
	M.root = OM.MenuRoot({ menu = menu })
	M.body:SetRoot(M.root)
	if title == nil then title = OM.Member(body.root, row, 'menuTitle') end
	if type(title) == 'number' then title = tostring(title) end
	M.title:SetText(type(title) == 'string' and title ~= '' and title or row.name)
	-- On each draw: Text > Muted can change, or the profile with it.
	M.title:SetTextColor(Muted())
	-- Off its old dots first: the rows are drawn before the menu is anchored
	-- again, and a pooled widget they take may be the one the menu still hangs
	-- from (a font row's dots), which would anchor a row to its own descendant.
	M.frame:ClearAllPoints()
	DrawBody()
	Anchor(dots)
end

-- A validate's message (nil clears it) in the status line of what the item
-- is in: the small dialog's for one of its rows, else the window's.
local function SetStatus(text)
	local dialog = OW.GetDialogFrames and OW.GetDialogFrames()
	if M.owner and dialog and M.owner.body == dialog.body and S.SetDialogStatus then
		S.SetDialogStatus(text)
	else
		OW:SetStatus(text)
	end
end

-- The menu's widgets' onChanged (see the top).
local function MenuChanged(ok, err, isDragging, widget)
	M.dragging = isDragging and true or nil
	SetStatus(ok == false and err or nil)
	if ok == false and err then return end
	if isDragging then
		xpcall(function() M.body:Refresh(widget) end, geterrorhandler())
		return
	end
	if ColorPickerShown() then
		S.Schedule()
	elseif OW:IsShown() then
		OW:Render()
	else
		xpcall(S.FollowDialog, geterrorhandler())
		xpcall(S.FollowMenu, geterrorhandler())
	end
end

local function Build()
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata('FULLSCREEN_DIALOG')
	catcher:SetFrameLevel(CATCHER_LEVEL)
	catcher:EnableMouse(true)
	catcher:Hide()
	-- While the color picker is open the click is the picker's (see the top).
	catcher:SetScript('OnMouseDown', function()
		if not ColorPickerShown() then OW:CloseMenu() end
	end)

	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(MENU_LEVEL)
	frame:SetSize(MENU_WIDTH, CONTENT_TOP + OB.TOP + MENU_PAD)
	st:KeepInScreenMargin(frame)
	frame:EnableMouse(true)
	frame:Hide()
	st:SetTemplate(frame, 'theme', 'solid', 'panel')

	-- The wheel stops at the menu and its catcher: the page under them stays.
	for _, wheel in ipairs({ catcher, frame }) do
		wheel:EnableMouseWheel(true)
		wheel:SetScript('OnMouseWheel', function() end)
	end

	local title = Text(frame, 'section')
	title:SetPoint('TOPLEFT', frame, 'TOPLEFT', MENU_PAD, -TITLE_TOP)
	title:SetWidth(BODY_WIDTH)

	-- A plain frame: the menu is as tall as its rows, and the hover lines'
	-- watcher takes the menu (its parent) for the view.
	local content = CreateFrame('Frame', nil, frame)
	content:SetPoint('TOPLEFT', frame, 'TOPLEFT', MENU_PAD, -CONTENT_TOP)
	content:SetSize(BODY_WIDTH, 1)

	M.frame, M.catcher, M.title, M.content = frame, catcher, title, content
	M.body = OB.New(content, nil, MenuChanged, BODY_WIDTH)
	-- As a half body: two small rows to a line, the rest a line each (OB.HalfSize).
	M.body:SetWidth(BODY_WIDTH, true)

	-- Esc, only while the menu is shown.
	local keys = EscapeKeys(frame, function() return false end, function() OW:CloseMenu() end)
	M.keys = keys

	frame:SetScript('OnShow', function()
		catcher:Show()
		keys:Show()
		keys:EnableKeyboard(true)
		if not InCombatLockdown() then keys:SetPropagateKeyboardInput(true) end
	end)
	frame:SetScript('OnHide', function()
		catcher:Hide()
		keys:EnableKeyboard(false)
		keys:Hide()
		-- A color picker open from one of its rows cancels while the row's widget is still there.
		W.CloseColorPicker(frame)
		-- Its list first, while its owner is still inside the menu (a
		-- released widget is parented away).
		local owner = W.ListOwner()
		if owner and Inside(owner, frame) then W.CloseList() end
		W.CancelConfirm()
		M.body:Release()
		if M.dots then W.Kit.MarkSlot(M.dots, false) end
		M.owner, M.root, M.dragging, M.dots = nil, nil, nil, nil
		-- Off the dots it was on: they belong to a widget that goes back to a pool.
		frame:ClearAllPoints()
	end)
	-- Its sets can reach protected frames, as the dialog's.
	frame:RegisterEvent('PLAYER_REGEN_DISABLED')
	frame:SetScript('OnEvent', function() OW:CloseMenu() end)
end

------------------------------------------------------------------ following its item

-- Whether the user is busy in the menu: its own list open, a confirm, its
-- slider held (a lost mouse-up can't hold it off), one of its boxes typed in.
local function Busy()
	local owner = W.ListOwner()
	if owner and Inside(owner, M.frame) then return true end
	if W.ConfirmText() then return true end
	if M.dragging and IsMouseButtonDown('LeftButton') then return true end
	local focus = GetCurrentKeyBoardFocus()
	return focus ~= nil and Inside(focus, M.frame)
end

-- The window's render (and a set in the menu with the window closed): see
-- the top.
local function FollowMenu()
	if not (M.frame and M.frame:IsShown() and M.owner) then return end
	local cell = ItemCell(M.owner.body, M.owner.path)
	-- Its widget's menu again: a font row has none once its value is no longer
	-- a typeface, so the menu closes (even while busy: it has nothing to draw).
	local menu, title
	if cell then menu, title = MenuOf(cell.widget) end
	if not menu then return OW:CloseMenu() end
	if Busy() then
		Anchor(cell.widget.dots)
		return
	end
	M.dragging = nil
	Draw(cell.body, cell.row, cell.widget.dots, menu, title)
end

------------------------------------------------------------------ the API

function OW:OpenMenu(widget)
	-- Not guarded: a menu opened from a widget inside the menu itself. Closing
	-- the open one first releases that widget, and Draw would then anchor to its
	-- dots (or to its own descendant, if the redraw takes the widget back: the
	-- loop again). No menu can do it today (a face-only font row hides its dots
	-- on a typeface and its link only navigates; no menu holds an item row), so
	-- whoever puts an item or a typeface row in a menu adds
	-- `if widget.rowBody == M.body then return false end` here.
	if InCombatLockdown() then return false end
	if widget and widget.disabled then return false end
	local row = widget and widget.row
	if not (row and widget.rowBody and widget.dots) then return false end
	local menu, title = MenuOf(widget)
	if type(menu) ~= 'table' then return false end
	if not M.frame then Build() end
	self:CloseMenu()
	Draw(widget.rowBody, row, widget.dots, menu, title)
	M.frame:Show()
	return true
end

function OW:CloseMenu(body)
	if not self:IsMenuShown() then return end
	if body ~= nil and M.owner and M.owner.body ~= body then return end
	M.frame:Hide()
end

function OW:IsMenuShown(widget)
	if not (M.frame and M.frame:IsShown()) then return false end
	if widget == nil then return true end
	local owner = M.owner
	return owner ~= nil and widget.rowBody == owner.body and widget.row ~= nil and SamePath(widget.row.path, owner.path)
end

function OW.GetMenuFrames() return M end

------------------------------------------------------------------ for optionswindow.lua

S.FollowMenu = FollowMenu
