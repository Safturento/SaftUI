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

	A set re-renders it, after the drag for a slider's (meanwhile its other
	rows follow the drag in place, as the window's do), and not while
	Blizzard's color picker is open (the swatch shows its color itself; the
	next set draws the rest). Each render of the window draws it again too,
	so it follows a change made elsewhere (a ConfigTableChange, a profile
	change; UF's profile prompts answer after its own set drew it), but not
	while one of its sliders is held or one of its boxes has the keyboard. A
	failed validate shows its message at the bottom. Esc (its own keyboard
	catcher, which the window's passes to) and the close X close it, and so
	do closing the window and entering combat. It refuses to open in combat
	(false).
]]

local DIALOG_WIDTH, DIALOG_PAD = 568, 24
local DIALOG_CONTENT = DIALOG_WIDTH - 2 * DIALOG_PAD -- two columns of 240
local DIALOG_HEAD, DIALOG_FOOT, DIALOG_MAX_BODY = 58, 30, 600
local DIALOG_KEY = 'dialog' -- the table's key in the dialog's root
local D = { offset = 0, height = 0 } -- the dialog's frames, body and what it draws

local function SetDialogScroll(offset)
	D.offset = ScrollTo(D.scroll, D.bar, offset, D.height)
end

-- The dialog's scroll frame reaches past its content as the window's body
-- does in the look it's drawn in (OW.LAYOUT's bodyReach: under Blizzard the
-- dropdown's glow, so a select at the content's right edge isn't clipped).
-- Set when the look changed.
local function PlaceDialogScroll()
	local blizzard = W.BlizzardLook()
	if blizzard == D.laidOut then return end
	local reach = (blizzard and OW.LAYOUT.blizzard or OW.LAYOUT.own).bodyReach
	D.scroll:SetPoint('BOTTOMRIGHT', D.frame, 'BOTTOMRIGHT', -(DIALOG_PAD - reach), DIALOG_FOOT)
	D.laidOut = blizzard
end

local function DrawDialog()
	PlaceDialogScroll()
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
	D.dragging = isDragging and true or nil
	D.status:SetText(ok == false and err or '')
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
	scroll:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -DIALOG_PAD, DIALOG_FOOT)
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

	-- Esc, only while the dialog is shown.
	local keys = EscapeKeys(frame, function() return false end, function() OW:CloseDialog() end)
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

-- The window's render (OW:Render) draws an open dialog again with it, unless
-- the user is busy in it: a slider of its own held (a lost mouse-up can't
-- hold it off), or one of its boxes typed in.
local function FollowWindow()
	if not (D.frame and D.frame:IsShown()) then return end
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
	D.titleSource, D.root, D.offset, D.dragging = title, { [DIALOG_KEY] = options }, 0, nil
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

-- For tests: the dialog's { frame, title, scroll, content, bar, status, keys,
-- body }; its drawn rows are body.cells.
function OW.GetDialogFrames() return D end

------------------------------------------------------------------ for optionswindow.lua

S.FollowDialog = FollowWindow
