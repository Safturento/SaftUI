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
	      open one first, unless the widget is a row of the open menu itself
	      (below: the second level). false in combat, when the item is
	      disabled (a search result can ask, though its dots can't), or when
	      the row has no menu (a Menu that gives nil), or from a row of the
	      second level (two levels only). It remembers the item as { body =
	      widget.rowBody, path = widget.row.path }, the body that drew it (the
	      window's page, the small dialog's, or the first menu's) and its path there.
	  OW:CloseMenu(body)   closes it, and its second level with it; with body, only
	      when its item is in that body (the first menu's body closes the second only)
	  OW:CloseMenuOf(widget)   closes the menu that is the widget's: the second
	      level alone when it is that, else the first with the second
	  OW:IsMenuShown(widget) -> boolean
	      whether a menu is shown; with widget, whether it's that item's, in either level
	  OW.MenuPlace(anchor, width, height, screenWidth, screenHeight, margin)
	      -> point, relPoint, x, y: where a menu width x height goes by the
	      dots (anchor = { left, right, top, bottom }, their rect, in the
	      menu's units), inside the screen less margin ({ left, right, top,
	      bottom }, the screen edge margin st:KeepInScreenMargin clamps the
	      menu to; none when nil): its TOPRIGHT on the dots' BOTTOMRIGHT, 4
	      below; its left edge past the margin's, TOPLEFT on BOTTOMLEFT
	      instead (unless that goes further past the right one); its bottom
	      past the margin's, above (BOTTOM* on TOP*, 4 above) when there's
	      more room there; with room on neither, beside the dots (TOPLEFT on their TOPRIGHT, 4
	      right of them, or TOPRIGHT on their TOPLEFT when that passes the margin's right).
	  OW.GetMenuFrames(level) -> { frame, catcher, title, content, body, keys,
	      owner = { body, path }, level } (owner nil while closed), for tests;
	      level 1 (the default) or 2, the second level (below).
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

	A menu group with colorEdit = true (the Accent's) begins a color edit as it opens
	(st:HoldColorEdit) and lets go as it closes, so a drag in it is one pass of the colors a
	frame and the whole pass runs at the close; the edit is counted, so with the color picker
	open too it ends when the last of them lets go, in either order. The menu and the picker never overlap:
	the catcher takes the click outside the menu.

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

	A SECOND LEVEL. A widget whose row is drawn by the open menu's own body (a font
	row's dots in a part's menu: the unit frames' texts need Size, Outline, Shadow and
	Line spacing each) opens a second menu over it, the first staying open: the same
	code, a second instance (level 2: M2, the first is M). Two levels only: a widget of
	the second asks and gets false. The second has its own catcher between the first
	menu and itself (frame levels 400 catcher and 410 menu for the first, 420 and 430
	for the second), so a click on the first menu or outside closes the second only; Esc
	closes it first (the first passes Esc on while the second shows). It is placed by
	OW.MenuPlace on the dots that opened it, on whole pixels as the first is. While the
	second shows the first is held as it is, as when busy: it only moves onto its item's
	new dots, never drawing its rows again (that would release the pooled font widget
	the second hangs from, and its dots). A set in the second saves, the font row's own
	Refresh shows it in the first's row, and the window renders so the page behind
	follows (the part row's summary); the first's rows stay the same widgets. The second
	follows its item (the font row, in the first's body) as the first does and closes
	when it is gone or has no menu (the value became a shared font). Closing the first
	closes the second first; combat and Esc as above. A menu with colorEdit counts its
	own hold in either level.

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
-- Each level's catcher and frame levels: the first over the small dialog (300), the second over the first.
local CATCHER_LEVEL = { 400, 420 }
local MENU_LEVEL = { 410, 430 }

-- A level's menu: its frames and body, and its owner while it shows. M is the first, M2 the second.
local function NewMenu(level) return { level = level } end
local M, M2 = NewMenu(1), NewMenu(2)

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
	if below < 0 and above < 0 then
		-- Neither side has room (a tall menu on a short UI): beside the dots, top to top, so
		-- it never covers its own row: to their right, or their left when that passes the margin's.
		if anchor.right + DOTS_GAP + width <= screenWidth - margin.right then
			return 'TOPLEFT', 'TOPRIGHT', DOTS_GAP, 0
		end
		return 'TOPRIGHT', 'TOPLEFT', -DOTS_GAP, 0
	end
	if below < 0 and above > below then
		return 'BOTTOM' .. side, 'TOP' .. side, 0, DOTS_GAP
	end
	return 'TOP' .. side, 'BOTTOM' .. side, 0, -DOTS_GAP
end

-- The menu m on dots (an item's), by OW.MenuPlace, anchored to them so it
-- moves with them (the page scrolled). The margin is the one the menu is
-- clamped to (st:KeepInScreenMargin, in its own units), so a menu placed
-- below is never pushed back up over its dots by the clamp.
local function Anchor(m, dots)
	local frame = m.frame
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
local function DrawBody(m)
	m.body:Release()
	local view = OM.BuildView(m.root, OM.MENU_KEY)
	local height = view and m.body:Draw(view.sections) or 0
	m.content:SetHeight(max(1, height))
	-- The body ends OB.BOTTOM under its last row: the menu's own padding
	-- instead; under a closing line of buttons (off the panel), OB.FLOAT_GAP,
	-- as far as the line is under the rows above it.
	local foot = m.body.endsFloating and OB.FLOAT_GAP or MENU_PAD
	m.frame:SetHeight(CONTENT_TOP + (height > 0 and height - OB.BOTTOM or OB.TOP) + foot)
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

-- The menu m of an item's row (in body, the body that drew it) drawn, and on
-- its dots. menu is MenuOf's group, and title its own title when the widget
-- gave one.
local function Draw(m, body, row, dots, menu, title)
	m.owner = { body = body, path = row.path }
	-- A part row's dots are open while its menu is (the last ones, possibly another
	-- pooled widget's by now, are let go).
	if m.dots then W.Kit.MarkSlot(m.dots, false) end
	m.dots = type(row.option) == 'table' and type(row.option.summary) == 'function' and dots or nil
	if m.dots then W.Kit.MarkSlot(m.dots, true) end
	m.root = OM.MenuRoot({ menu = menu })
	m.body:SetRoot(m.root)
	if title == nil then title = OM.Member(body.root, row, 'menuTitle') end
	if type(title) == 'number' then title = tostring(title) end
	m.title:SetText(type(title) == 'string' and title ~= '' and title or row.name)
	-- On each draw: Text > Muted can change, or the profile with it.
	m.title:SetTextColor(Muted())
	-- Off its old dots first: the rows are drawn before the menu is anchored
	-- again, and a pooled widget they take may be the one the menu still hangs
	-- from (a font row's dots), which would anchor a row to its own descendant.
	m.frame:ClearAllPoints()
	DrawBody(m)
	Anchor(m, dots)
end

-- A validate's message (nil clears it) in the status line of what the item
-- is in: the small dialog's for one of its rows, else the window's. The
-- second level's item is in the first menu, so it is the first's owner that says.
local function SetStatus(m, text)
	local dialog = OW.GetDialogFrames and OW.GetDialogFrames()
	local owner = (m.level == 2 and M.owner) or m.owner
	if owner and dialog and owner.body == dialog.body and S.SetDialogStatus then
		S.SetDialogStatus(text)
	else
		OW:SetStatus(text)
	end
end

-- The menu's widgets' onChanged (see the top).
local function MenuChanged(m, ok, err, isDragging, widget)
	m.dragging = isDragging and true or nil
	SetStatus(m, ok == false and err or nil)
	if ok == false and err then return end
	if isDragging then
		xpcall(function() m.body:Refresh(widget) end, geterrorhandler())
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

local function Build(m)
	local level = m.level
	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata('FULLSCREEN_DIALOG')
	catcher:SetFrameLevel(CATCHER_LEVEL[level])
	catcher:EnableMouse(true)
	catcher:Hide()
	-- While the color picker is open the click is the picker's (see the top). The
	-- second level's catcher is over the first menu: a click there closes the second only.
	catcher:SetScript('OnMouseDown', function()
		if ColorPickerShown() then return end
		if level == 2 then m.frame:Hide() else OW:CloseMenu() end
	end)

	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(MENU_LEVEL[level])
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

	m.frame, m.catcher, m.title, m.content = frame, catcher, title, content
	m.body = OB.New(content, nil, function(...) return MenuChanged(m, ...) end, BODY_WIDTH)
	-- As a half body: two small rows to a line, the rest a line each (OB.HalfSize).
	m.body:SetWidth(BODY_WIDTH, true)

	-- Esc, only while the menu is shown. The first passes it on while the second shows,
	-- which closes first.
	local keys = EscapeKeys(frame, function() return level == 1 and M2.frame ~= nil and M2.frame:IsShown() end,
		function()
			if level == 2 then m.frame:Hide() else OW:CloseMenu() end
		end)
	m.keys = keys

	frame:SetScript('OnShow', function()
		catcher:Show()
		keys:Show()
		keys:EnableKeyboard(true)
		if not InCombatLockdown() then keys:SetPropagateKeyboardInput(true) end
	end)
	frame:SetScript('OnHide', function()
		-- The second level first: it hangs from this menu's rows.
		if level == 1 and M2.frame and M2.frame:IsShown() then M2.frame:Hide() end
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
		m.body:Release()
		if m.dots then W.Kit.MarkSlot(m.dots, false) end
		m.owner, m.root, m.dragging, m.dots = nil, nil, nil, nil
		-- Off the dots it was on: they belong to a widget that goes back to a pool.
		frame:ClearAllPoints()
		-- The color edit it began ends last: its whole pass covers what the menu set.
		if m.beganEdit then
			m.beganEdit = nil
			st:ReleaseColorEdit()
		end
	end)
	-- Its sets can reach protected frames, as the dialog's.
	frame:RegisterEvent('PLAYER_REGEN_DISABLED')
	frame:SetScript('OnEvent', function() OW:CloseMenu() end)
end

------------------------------------------------------------------ following its item

local function Shown(m) return m.frame ~= nil and m.frame:IsShown() end

-- Whether the user is busy in the menu: its own list open, a confirm, its
-- slider held (a lost mouse-up can't hold it off), one of its boxes typed in;
-- or, for the first, a second level open over it, which hangs from its rows.
local function Busy(m)
	if m.level == 1 and Shown(M2) then return true end
	local owner = W.ListOwner()
	if owner and Inside(owner, m.frame) then return true end
	if W.ConfirmText() then return true end
	if m.dragging and IsMouseButtonDown('LeftButton') then return true end
	local focus = GetCurrentKeyBoardFocus()
	return focus ~= nil and Inside(focus, m.frame)
end

local function FollowLevel(m)
	if not (Shown(m) and m.owner) then return end
	local cell = ItemCell(m.owner.body, m.owner.path)
	-- Its widget's menu again: a font row has none once its value is no longer
	-- a typeface, so the menu closes (even while busy: it has nothing to draw).
	local menu, title
	if cell then menu, title = MenuOf(cell.widget) end
	if not menu then
		if m.level == 2 then m.frame:Hide() else OW:CloseMenu() end
		return
	end
	if Busy(m) then
		Anchor(m, cell.widget.dots)
		-- Held by a second level: the rows stay the same widgets, reading their values again in
		-- place (a font row's kind, which its second menu asks), nothing released.
		if m.level == 1 and Shown(M2) then xpcall(m.body.Refresh, geterrorhandler(), m.body) end
		return
	end
	m.dragging = nil
	Draw(m, cell.body, cell.row, cell.widget.dots, menu, title)
end

-- The window's render (and a set in the menu with the window closed): see
-- the top. The first, then the second, which hangs from the first's rows.
local function FollowMenu()
	FollowLevel(M)
	FollowLevel(M2)
end

------------------------------------------------------------------ the API

function OW:OpenMenu(widget)
	if InCombatLockdown() then return false end
	if widget and widget.disabled then return false end
	local row = widget and widget.row
	if not (row and widget.rowBody and widget.dots) then return false end
	-- A row of the second level's own body: two levels only.
	if M2.body and widget.rowBody == M2.body then return false end
	local menu, title = MenuOf(widget)
	if type(menu) ~= 'table' then return false end
	-- A row drawn by the open first menu's body (a font row's dots in a part's menu) opens
	-- the second level over it, the first staying.
	local m = M
	if M.body and Shown(M) and widget.rowBody == M.body then m = M2 end
	if not m.frame then Build(m) end
	if m == M2 then
		m.frame:Hide() -- one that was open (another row's): its owner, colour edit and rows go first
	else
		self:CloseMenu()
	end
	Draw(m, widget.rowBody, row, widget.dots, menu, title)
	-- A menu that changes colors (colorEdit) edits as the picker does: changes pass once a
	-- frame, the whole pass at the close. Only an edit it began is its to end.
	if menu.colorEdit == true then
		st:HoldColorEdit()
		m.beganEdit = true
	end
	m.frame:Show()
	return true
end

function OW:CloseMenu(body)
	if not self:IsMenuShown() then return end
	if body == nil then
		M.frame:Hide() -- the second goes with it
		return
	end
	-- With a body: the menus whose item is in it. The first menu's body is the second's.
	if Shown(M2) and M2.owner and M2.owner.body == body then M2.frame:Hide() end
	if Shown(M) and M.owner and M.owner.body == body then M.frame:Hide() end
end

local function OwnedBy(m, widget)
	local owner = m.owner
	return Shown(m) and owner ~= nil and widget.rowBody == owner.body and widget.row ~= nil and SamePath(widget.row.path, owner.path)
end

-- The menu that is the widget's closed: the second level alone when it is that,
-- else the first (and the second with it).
function OW:CloseMenuOf(widget)
	if widget and OwnedBy(M2, widget) then
		M2.frame:Hide()
	elseif widget == nil or OwnedBy(M, widget) then
		self:CloseMenu()
	end
end

function OW:IsMenuShown(widget)
	if not Shown(M) then return false end
	if widget == nil then return true end
	return OwnedBy(M, widget) or OwnedBy(M2, widget)
end

function OW.GetMenuFrames(level) return level == 2 and M2 or M end

------------------------------------------------------------------ for optionswindow.lua

S.FollowMenu = FollowMenu
