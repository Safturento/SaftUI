local st = SaftUI
local OM, W, OB = st.OptionsModel, st.OptionsWidgets, st.OptionsBody

--[[
	The small dialog over SaftUI's options window (st.OptionsWindow,
	optionswindow.lua): OW:OpenDialog, OW:CloseDialog and OW:IsDialogShown,
	for an option table of its own (UF's Copy from and its unit frame
	profiles). It loads after optionswindow.lua (Config/load.xml) and takes
	what it needs from OW.S; the window's render draws it again through
	S.FollowDialog.
]]

local OW = st.OptionsWindow
local S = OW.S

local max, min = math.max, math.min

-- The window's fonts, pieces and numbers (optionsbody.lua).
local Text, Line, ScrollTo = OB.Text, OB.Line, OB.ScrollTo
local ROW_HEIGHT, SCROLL_STEP = OB.ROW_HEIGHT, OB.SCROLL_STEP

-- From optionswindow.lua.
local F, Colors, Inside = S.F, S.Colors, S.Inside
local ColorPickerShown, EscapeKeys = S.ColorPickerShown, S.EscapeKeys

------------------------------------------------------------------ a small dialog

--[[
	OW:OpenDialog(title, options): a small SaftUI window, over /sui, for an
	option table of its own (UF's Copy from, its unit frame profiles). title
	is text, or a function that gives it, read on each render. options is a
	group, as a page's: its options and inline groups are drawn by a body of
	its own (OB.New), two columns of rows as in the window. A dialog has no
	tabs or picker: of child groups that aren't inline, only the first one's
	rows show.

	It's as tall as its rows (up to 600, then they scroll) with its head (58)
	and a foot under them: under Thick and Thin the dialog's side padding
	(24), the body's own bottom margin (OB.BOTTOM) left off, so a closing
	line of buttons (floating under the panel) ends 24 above the dialog's
	edge, or 30 while the status line has text, to fit it; under Blizzard,
	as before, the margin and a foot of 30 (54 under the last row). It sits
	over the window's middle (the screen's without the window) by its top
	left corner (W.PlaceCentred), so at any height, odd or even, its edges
	and all it holds are on whole pixels.

	A set re-renders it, after the drag for a slider's (meanwhile its other
	rows follow the drag in place, as the window's do), and not while
	SaftUI's color picker is open (the swatch shows its color itself; the
	next set draws the rest). Each render of the window draws it again too,
	so it follows a change made elsewhere (a ConfigTableChange, a profile
	change; UF's profile prompts answer after its own set drew it), but not
	while one of its sliders is held or one of its boxes has the keyboard. A
	failed validate shows its message at the bottom. Esc (its own keyboard
	catcher, which the window's passes to) and the close X close it, and so
	do closing the window and entering combat. It refuses to open in combat
	(false). Its catcher passes Esc on while an item's menu shows
	(optionsmenu.lua). Closing it, or opening it again on other options,
	closes a menu whose item is one of its rows; drawing it again by itself
	(its own set) has that menu follow its item, as a window render does. A
	failed validate in such a menu shows in this dialog's status line.
]]

local DIALOG_WIDTH, DIALOG_PAD = 568, 24
local DIALOG_CONTENT = DIALOG_WIDTH - 2 * DIALOG_PAD -- two columns of 240
local DIALOG_HEAD, DIALOG_MAX_BODY = 58, 600
-- Under the rows (the foot): under Thick and Thin the side padding, the
-- body's own bottom margin (OB.BOTTOM) left off, or STATUS_FOOT while the
-- status line has text, to fit it; under Blizzard, as before, the margin
-- kept and STATUS_FOOT always (54 under the last row).
local STATUS_FOOT = 30
local DIALOG_KEY = 'dialog' -- the table's key in the dialog's root
local D = { offset = 0, height = 0, statusText = '' } -- the dialog's frames, body and what it draws

local function SetDialogScroll(offset)
	D.offset = ScrollTo(D.scroll, D.bar, offset, D.height)
end

-- The foot under the rows, for the look the dialog is drawn in.
local function Foot(blizzard)
	if blizzard or D.statusText ~= '' then return STATUS_FOOT end
	return DIALOG_PAD
end

-- Sizes the dialog to its rows (D.height) with its head and foot, its scroll
-- frame's bottom on the foot, and places it again over what it opened over
-- (D.over): its height follows what it holds, and is as often odd as even,
-- so it's placed by its corner (W.PlaceCentred), its edges and all it holds
-- on whole units. The scroll frame reaches past its content as the window's
-- body does in the look it's drawn in (OW.LAYOUT's bodyReach: under Blizzard
-- the dropdown's glow, so a select at the content's right edge isn't
-- clipped).
local function SizeDialog()
	local blizzard = W.BlizzardLook()
	local reach = (blizzard and OW.LAYOUT.blizzard or OW.LAYOUT.own).bodyReach
	local foot = Foot(blizzard)
	D.scroll:SetPoint('BOTTOMRIGHT', D.frame, 'BOTTOMRIGHT', -(DIALOG_PAD - reach), foot)
	local height = DIALOG_HEAD + min(max(D.height, ROW_HEIGHT), DIALOG_MAX_BODY) + foot
	D.frame:SetHeight(height)
	W.PlaceCentred(D.frame, D.over, DIALOG_WIDTH, height)
	D.scroll:UpdateScrollChildRect()
	SetDialogScroll(D.offset)
end

local function DrawDialog()
	D.body:Release()
	local title = D.titleSource
	if type(title) == 'function' then title = title() end
	D.title:SetText(tostring(title or ''))
	local view = OM.BuildView(D.root, DIALOG_KEY)
	local height = view and D.body:Draw(view.sections) or 0
	-- Under Thick and Thin the rows end the content: the foot is the dialog's
	-- own padding, not the body's margin as well.
	if height > 0 and not W.BlizzardLook() then height = height - OB.BOTTOM end
	D.height = height
	D.content:SetHeight(max(1, D.height))
	SizeDialog()
end

-- The dialog drawn again by itself (its own set, its opening), and an item's
-- menu with it, as a window render draws both: the menu follows its item to
-- the redrawn row, or closes (optionsmenu.lua).
local function RenderDialog()
	if not (D.frame and D.frame:IsShown()) then return end
	xpcall(DrawDialog, geterrorhandler())
	if S.FollowMenu then xpcall(S.FollowMenu, geterrorhandler()) end
end

-- The status line's text (a validate error; '' clears it). Its coming or
-- going changes the foot, so a shown dialog is sized again.
local function SetStatus(text)
	text = text or ''
	local changed = (D.statusText == '') ~= (text == '')
	D.statusText = text
	D.status:SetText(text)
	if changed and D.frame:IsShown() then SizeDialog() end
end

-- The dialog's widgets' onChanged, as the window's Changed: mid-drag its other
-- rows follow in place, and it's drawn again when the mouse is let go.
local function DialogChanged(ok, err, isDragging, widget)
	D.dragging = isDragging and true or nil
	SetStatus(ok == false and err or '')
	if ok == false and err then return end
	if isDragging then
		xpcall(function() D.body:Refresh(widget) end, geterrorhandler())
		return
	end
	if ColorPickerShown() then return end
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
	scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -DIALOG_PAD, STATUS_FOOT) -- SizeDialog sets it on each draw
	local content = CreateFrame('Frame', nil, scroll)
	content:SetSize(DIALOG_CONTENT, 1)
	scroll:SetScrollChild(content)
	scroll:EnableMouseWheel(true)
	scroll:SetScript('OnMouseWheel', function(_, delta) SetDialogScroll(D.offset - delta * SCROLL_STEP) end)
	D.scroll, D.content = scroll, content
	D.bar = OB.ScrollBar(frame, SetDialogScroll, { narrow = true, step = SCROLL_STEP })
	D.body = OB.New(content, nil, DialogChanged, DIALOG_CONTENT)

	D.status = Text(frame, 'field')
	D.status:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', DIALOG_PAD, 10)
	D.status:SetWidth(DIALOG_CONTENT)
	D.status:SetTextColor(Colors().text.red:GetRGB())

	-- Esc, only while the dialog is shown, and not while an item's menu is
	-- (its own keys close it).
	local keys = EscapeKeys(frame, function() return OW.IsMenuShown ~= nil and OW:IsMenuShown() end,
		function() OW:CloseDialog() end)
	D.keys = keys

	frame:SetScript('OnShow', function()
		keys:Show()
		keys:EnableKeyboard(true)
		if not InCombatLockdown() then keys:SetPropagateKeyboardInput(true) end
	end)
	frame:SetScript('OnHide', function()
		keys:EnableKeyboard(false)
		keys:Hide()
		-- A color picker open from one of its rows cancels while the row's widget is still there.
		W.CloseColorPicker(frame)
		-- A menu of one of its items goes with it.
		if OW.CloseMenu then OW:CloseMenu(D.body) end
		-- Its list first, while its owner is still inside the dialog (a
		-- released widget is parented away).
		local owner = W.ListOwner()
		if owner and Inside(owner, frame) then W.CloseList() end
		W.CancelConfirm()
		D.body:Release()
		SetStatus('')
	end)
	-- Its sets can reach protected frames (UF's copy updates the unit frames).
	frame:RegisterEvent('PLAYER_REGEN_DISABLED')
	frame:SetScript('OnEvent', function() OW:CloseDialog() end)
end

-- The window's render (OW:Render) draws an open dialog again with it, unless
-- the user is busy in it: a slider of its own held (a lost mouse-up can't
-- hold it off), one of its boxes typed in, or its own dropdown list or a
-- confirm open (drawing it again would close them).
local function FollowDialog()
	if not (D.frame and D.frame:IsShown()) then return end
	local owner = W.ListOwner()
	if owner and Inside(owner, D.frame) then return end
	if W.ConfirmText() then return end
	if D.dragging and IsMouseButtonDown('LeftButton') then return end
	local focus = GetCurrentKeyBoardFocus()
	if focus and Inside(focus, D.frame) then return end
	D.dragging = nil
	DrawDialog()
end

------------------------------------------------------------------ the API

-- A small dialog over the window for options, a group table of its own
-- (see "a small dialog" above). False in combat.
function OW:OpenDialog(title, options)
	if InCombatLockdown() then return false end
	if not D.frame then BuildDialog() end
	-- A menu of the dialog's last rows goes: the new rows reuse their widgets.
	if OW.CloseMenu then OW:CloseMenu(D.body) end
	D.titleSource, D.root, D.offset, D.dragging = title, { [DIALOG_KEY] = options }, 0, nil
	D.body:SetRoot(D.root)
	SetStatus('')
	-- Over the window, or the screen without it; placed at the height it
	-- has, and again by its draw (SizeDialog).
	D.over = self:IsShown() and F.window or UIParent
	W.PlaceCentred(D.frame, D.over, DIALOG_WIDTH, OB.WholeHeight(D.frame:GetHeight()))
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

-- For tests: the dialog's { frame, title, scroll, content, bar, status, keys,
-- body }; its drawn rows are body.cells.
function OW.GetDialogFrames() return D end

------------------------------------------------------------------ for optionswindow.lua

S.FollowDialog = FollowDialog
-- Its status line, for a validate's message from an item's menu on one of
-- its rows (optionsmenu.lua); nil or '' clears it.
S.SetDialogStatus = function(text) SetStatus(text) end
