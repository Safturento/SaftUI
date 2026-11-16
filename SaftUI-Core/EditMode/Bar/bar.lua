local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody

--[[
	Edit mode's bar: the controls of edit mode (Exit, the grid and its size, the
	snaps, Dim world, Coordinates, Show disabled, Show hidden, the module list, the
	filter, Options, Hide until hovered, Detach) on a small two-row bar at the top of the screen
	(or, detached, in the floating window of barwindow.lua), shown while edit
	mode is on, with /sui open or closed. This file is the bar itself: its
	frame, the list of groups of controls, the layout (EM.BarLayout, pure) and
	the events that show it, fade it and keep it current. Where it sits, how it
	slides and hides is bardock.lua's. The groups and their controls are
	bargroups.lua's, and later files add theirs the same way (EM:AddBarGroup,
	at load).

	  EM.BAR                   the numbers: ROW 26 (a row of controls), VPAD 7,
	                           ROW_GAP 4 (HEIGHT 70 = 2 * VPAD + 2 * ROW + ROW_GAP),
	                           PAD 10 (the bar's ends), GAP 4 (between controls),
	                           GROUP_PAD 8 (each side of a divider), LEVEL 9500,
	                           DRAG_ALPHA
	  EM:AddBarGroup(group)    group = { key, order, side = 'left' | 'right',
	                           row = 1 | 2, dockKeys = { key, ... }, section = 'title' | 'grid' | 'show' |
	                           'changes', controls = function(parent) -> { control, ... } }.
	                           row is the docked bar's (a group without one is on
	                           row 1 when left, row 2 when right); section is the
	                           floating window's. Within a row groups run left to
	                           right by order. dockKeys (optional) is the order of
	                           the group's controls on the docked bar only; the
	                           floating window keeps the group's own. side only
	                           says the default row.
	  a control                { key, frame, Lay, Refresh, Look, Recolor, section, align }
	    Lay(control, floating) -> width   lays the control out and says its
	                           width; 0 is not shown
	    Refresh(control)       puts the settings' state on it (optional)
	    Look(control, blizzard) its look for the theme; W.LookControl(frame) when
	                           it has none (a number box's is W.LookNumberBox)
	    Recolor(control, blizzard) its colors only, for a color pass (optional:
	                           with none Look runs, which must then do nothing
	                           but color while the art is the same)
	    section, align         the group's section overridden, 'right' (unused in
	                           the docked bar)
	  EM.BarLayout(rows) -> xs, dividers, width      the pure part
	  EM:GetBar()              the frame, built on first use
	  EM:LayoutBar()           lays the controls out and sizes the bar
	  EM:RefreshBar()          each control's look and state again
	  EM:RecolorBar()          each control's colors again (a color pass: nothing
	                           placed, shown or hidden)
	  EM:BarControl(key)       a control by its key
	  EM:IsBlizzardEditModeOpen()

	The frame is a SaftUI frame in FULLSCREEN_DIALOG at level BAR.LEVEL, above
	every mover (they climb to 9000, picker.lua) and /sui (level 100), under
	everything in TOOLTIP strata. It is two rows tall and only as wide as its
	wider row, drawn as a panel in the theme: its backdrop sits the theme's
	inset outside the frame. Each row is centred in the bar; the bar is the
	wider row plus PAD at each end, made even. It sits against the top edge,
	slid along it by bardock.lua. The frame takes the mouse (dragging its blank
	parts slides it); its controls are children one level above its own (their
	boxes' backdrops, one below them, stay over the bar's), vertically centred
	in their row on whole pixels.

	The two rows fit the narrowest screen at every control's full width, so
	nothing gives way. The bar lays out again on UI_SCALE_CHANGED and
	DISPLAY_SIZE_CHANGED (its own frame's events). Sizes the game reads back
	carry a hair of float noise, so a height is rounded before it is placed by.

	Events (EM:On): Enabled lays out, refreshes and shows it, Disabled hides it
	(and so does entering combat, which turns edit mode off). DragStarted fades
	it to DRAG_ALPHA and takes the mouse off every control, so a frame dragged
	up under it shows through; DragStopped brings it back. SettingsChanged refreshes it; ColorsChanged
	(group, key) for Text's Normal and Muted and the Accent recolors it
	(EM:RecolorBar), and for Theme looks again (EM:RefreshBar). Every control's click does nothing in combat
	(bargroups.lua's Guard).

	Whole pixels: widths come in whole, the controls are placed by their top
	left from the bar's, and a divider is a 1 x 26 line, HAIRLINE, kept under
	Blizzard too (it has no art for one).
]]

local floor = math.floor

EM.BAR = {
	ROW = 26, VPAD = 7, ROW_GAP = 4, PAD = 10, GAP = 4, GROUP_PAD = 8,
	LEVEL = 9500, DRAG_ALPHA = 0.25,
}
local BAR = EM.BAR
BAR.HEIGHT = 2 * BAR.VPAD + 2 * BAR.ROW + BAR.ROW_GAP -- 70
local ROWS = 2

local groups = {} -- registered groups, by order
local bar         -- the frame, once made
local windowed = false -- the controls are in the floating window (barwindow.lua), not on the bar

------------------------------------------------------------------ Blizzard's Edit Mode

-- Whether Blizzard's own Edit Mode is open. Only read: nothing of Blizzard's
-- is called or changed from here (.agents/taint.md).
function EM:IsBlizzardEditModeOpen()
	return _G.EditModeManagerFrame ~= nil and EditModeManagerFrame:IsShown() == true
end

------------------------------------------------------------------ the layout

local function GroupWidth(widths)
	local total, count = 0, 0
	for _, width in ipairs(widths) do
		if width > 0 then total, count = total + width, count + 1 end
	end
	if count == 0 then return 0, 0 end
	return total + (count - 1) * BAR.GAP, count
end

-- Puts a group's controls from x, GAP apart, a width of 0 skipped; group[c] is
-- control c's x.
local function PlaceGroup(group, widths, x)
	local first = true
	for c, width in ipairs(widths) do
		if width > 0 then
			if not first then x = x + BAR.GAP end
			first = false
			group[c] = x
			x = x + width
		end
	end
	return x
end

-- How wide a row is: its groups (a group with no control is not there), a
-- divider and GROUP_PAD each side between them.
local function RowWidth(row)
	local total, count = 0, 0
	for _, group in ipairs(row) do
		local width, controls = GroupWidth(group.widths)
		if controls > 0 then
			if count > 0 then total = total + 2 * BAR.GROUP_PAD + 1 end
			total, count = total + width, count + 1
		end
	end
	return total
end

--[[
	Where everything goes. rows is { row, ... }, a row { group, ... } in order, a
	group { widths = { w, ... } } (a width of 0 is not shown; a group with none
	is skipped whole, divider and all). Returns xs, dividers and width:
	  - xs[r][g][c], control c of group g of row r's x from the bar's left, whole;
	  - dividers[r], a list of x;
	  - width, the bar's: the wider row plus PAD at each end, made even.
	A row's controls run from its own start, GAP apart, with GROUP_PAD, a 1 wide
	divider and GROUP_PAD between groups. Each row is centred in the bar
	(floor((width - the row's width) / 2)), so the wider one starts at PAD or,
	when the width was made even, one more.
]]
function EM.BarLayout(rows)
	local widest = 0
	for _, row in ipairs(rows) do widest = math.max(widest, RowWidth(row)) end
	local width = widest + 2 * BAR.PAD
	width = width + width % 2
	local xs, dividers = {}, {}
	for r, row in ipairs(rows) do
		xs[r], dividers[r] = {}, {}
		local x, any = floor((width - RowWidth(row)) / 2), false
		for g, group in ipairs(row) do
			xs[r][g] = {}
			local _, count = GroupWidth(group.widths)
			if count > 0 then
				if any then
					dividers[r][#dividers[r] + 1] = x + BAR.GROUP_PAD
					x = x + 2 * BAR.GROUP_PAD + 1
				end
				any = true
				x = PlaceGroup(xs[r][g], group.widths, x)
			end
		end
	end
	return xs, dividers, width
end

------------------------------------------------------------------ the controls

-- Lays every control out (showing or hiding its frame), and returns the rows as
-- BarLayout takes them: row r's groups { widths, group }.
local function LayAll()
	local rows = {}
	for r = 1, ROWS do rows[r] = {} end
	for _, group in ipairs(groups) do
		local entry = { widths = {}, group = group, controls = {} }
		local byKey = {}
		for _, control in ipairs(group.built or {}) do byKey[control.key] = control end
		for _, key in ipairs(group.dockKeys or {}) do
			entry.controls[#entry.controls + 1] = byKey[key]
			byKey[key] = nil
		end
		for _, control in ipairs(group.built or {}) do
			if byKey[control.key] then entry.controls[#entry.controls + 1] = control end
		end
		for c, control in ipairs(entry.controls) do
			local width = control:Lay(false) or 0
			entry.widths[c] = width
			control.frame:SetShown(width > 0)
		end
		local row = rows[group.row] or rows[1]
		row[#row + 1] = entry
	end
	return rows
end

-- The top of row r, from the bar's top.
local function RowTop(r)
	return BAR.VPAD + (r - 1) * (BAR.ROW + BAR.ROW_GAP)
end

-- A control's top in its row: centred in its ROW on whole pixels (26 at the
-- row's top, 24 one down, 22 two), from the height as the game reads it back.
local function Top(frame, r)
	return -(RowTop(r) + floor((BAR.ROW - floor(frame:GetHeight() + 0.5)) / 2))
end

local dividers = {} -- the bar's dividers, kept

-- Puts every shown control and the dividers where BarLayout said.
local function Place(rows, xs, divided)
	for r, row in ipairs(rows) do
		for g, entry in ipairs(row) do
			for c, control in ipairs(entry.controls) do
				local x = xs[r][g][c]
				if x then
					control.frame:ClearAllPoints()
					control.frame:SetPoint('TOPLEFT', bar, 'TOPLEFT', x, Top(control.frame, r))
				end
			end
		end
	end
	local n = 0
	for r, list in ipairs(divided) do
		for _, x in ipairs(list) do
			n = n + 1
			local line = dividers[n]
			if not line then
				line = bar:CreateTexture(nil, 'ARTWORK')
				line:SetSize(1, BAR.ROW)
				dividers[n] = line
			end
			line:SetColorTexture(unpack(OB.HAIRLINE))
			line:ClearAllPoints()
			line:SetPoint('TOPLEFT', bar, 'TOPLEFT', x, -RowTop(r))
			line:Show()
		end
	end
	for i = n + 1, #dividers do dividers[i]:Hide() end
end

-- Lays the controls out and sizes the bar to them, then places it on the top
-- edge (bardock.lua). Returns the bar's width.
function EM:LayoutBar()
	local frame = self:GetBar()
	if windowed then return self:LayoutWindow() end
	local rows = LayAll()
	local xs, divided, width = EM.BarLayout(rows)
	frame:SetSize(width, BAR.HEIGHT)
	Place(rows, xs, divided)
	self:PlaceBar()
	self:Fire('BarLaid')
	return width
end

------------------------------------------------------------------ groups

local function SortGroups()
	table.sort(groups, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.key < b.key
	end)
end

-- One level up for frame and everything under it: a control is made one level
-- above the bar's, and its box's backdrop, one level below it, would sit level
-- with the bar's own art; shifted, every part stays over it.
local function Raise(frame)
	frame:SetFrameLevel(frame:GetFrameLevel() + 1)
	for _, child in ipairs({ frame:GetChildren() }) do Raise(child) end
end

-- A frame's descendants' levels relative to its own, top down: { { frame, offset }, ... }.
local function LevelShape(frame)
	local base, list = frame:GetFrameLevel(), {}
	local function walk(f)
		for _, child in ipairs({ f:GetChildren() }) do
			list[#list + 1] = { child, child:GetFrameLevel() - base }
			walk(child)
		end
	end
	walk(frame)
	return list
end
EM.LevelShape = LevelShape

-- Sets frame's level and each descendant of shape (LevelShape, taken once, when
-- the control was built) to level plus its offset, top down. SetParent gives a
-- frame the level one over its new parent's (the game, as the stub), and may or
-- may not carry its children along; absolute levels from the one shape are the
-- same either way, however many times the control moves.
local function Settle(frame, level, shape)
	frame:SetFrameLevel(level)
	for _, item in ipairs(shape) do item[1]:SetFrameLevel(level + item[2]) end
end
EM.SettleLevel = Settle -- barwindow.lua puts its own buttons the same two over

-- Puts a group's controls on parent, the bar or the floating window.
local function Adopt(group, parent)
	for _, control in ipairs(group.built or {}) do
		control.frame:SetParent(parent)
		Settle(control.frame, parent:GetFrameLevel() + 2, control.shape)
	end
end

local function BuildGroup(group)
	group.built = group.controls(bar)
	for _, control in ipairs(group.built) do
		control.group = group
		control.section = control.section or group.section
		Raise(control.frame)
		control.shape = LevelShape(control.frame)
	end
	if windowed then Adopt(group, EM:GetBarWindow()) end
end

-- Adds a group of controls (see the top). Call at load: the controls are made
-- with the bar, the first time it is wanted.
function EM:AddBarGroup(group)
	assert(type(group.key) == 'string' and type(group.order) == 'number'
		and (group.side == 'left' or group.side == 'right') and type(group.controls) == 'function',
		'AddBarGroup: a group needs key, order, side and controls')
	group.row = group.row or (group.side == 'left' and 1 or 2)
	groups[#groups + 1] = group
	SortGroups()
	if bar then
		BuildGroup(group)
		self:LayoutBar()
		self:RefreshBar()
	end
end

function EM:BarControl(key)
	for _, group in ipairs(groups) do
		for _, control in ipairs(group.built or {}) do
			if control.key == key then return control end
		end
	end
end

-- Puts the theme's look on every control, then its state from the settings.
function EM:RefreshBar()
	if not bar then return end
	local blizzard = W.BlizzardLook()
	for _, group in ipairs(groups) do
		for _, control in ipairs(group.built or {}) do
			if control.Look then control:Look(blizzard) else W.LookControl(control.frame, blizzard) end
			if control.Refresh then control:Refresh() end
		end
	end
	if self.LookBarWindow then self:LookBarWindow(blizzard) end
end

-- A color pass over the bar: each control's colors again, and nothing else (no
-- look, no state, nothing placed or shown). A control's Recolor(control,
-- blizzard) paints its own; one with no Recolor has the look put on again,
-- which does only that while the art is the same (Changes), as W.LookControl.
function EM:RecolorBar()
	if not bar then return end
	local blizzard = W.BlizzardLook()
	for _, group in ipairs(groups) do
		local built = group.built -- (nil until built: no table made per pass)
		for i = 1, built and #built or 0 do
			local control = built[i]
			if control.Recolor then
				control:Recolor(blizzard)
			elseif control.Look then
				control:Look(blizzard)
			else
				W.LookControl(control.frame, blizzard)
			end
		end
	end
	if self.LookBarWindow then self:LookBarWindow(blizzard) end
end

-- Every control, in group order: the floating window lays them out by section.
function EM:BarControls()
	local list = {}
	for _, group in ipairs(groups) do
		for _, control in ipairs(group.built or {}) do list[#list + 1] = control end
	end
	return list
end

------------------------------------------------------------------ the frame

function EM:GetBar()
	if bar then return bar end
	bar = st:CreateFrame('Frame', nil, UIParent)
	EM.bar = bar -- the docked bar's frame (EM:BarRect reads whether it is shown)
	bar:SetFrameStrata('FULLSCREEN_DIALOG')
	bar:SetFrameLevel(BAR.LEVEL)
	bar:SetSize(BAR.PAD * 2, BAR.HEIGHT)
	bar:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
	bar:EnableMouse(true) -- its blank parts are the handle bardock.lua slides it by
	st:SetBackdrop(bar, 'theme', 'options', 'panel')
	bar:Hide()
	-- (In the floating window the window's own events lay it out.) The screen
	-- events can fire before UIParent has its new size, so the bar is placed
	-- again on the next frame too (bardock.lua).
	-- A change of SaftUI's own scale fires no screen event, so the scale's
	-- change callback (st.UIScale:OnChanged, after the pass) runs it too.
	local function OnScreenChanged()
		if windowed then return end
		EM:LayoutBar()
		C_Timer.After(0, function() if not windowed then EM:PlaceBar() end end)
	end
	bar:RegisterEvent('UI_SCALE_CHANGED')
	bar:RegisterEvent('DISPLAY_SIZE_CHANGED')
	bar:SetScript('OnEvent', OnScreenChanged)
	st.UIScale:OnChanged(OnScreenChanged)
	for _, group in ipairs(groups) do BuildGroup(group) end
	if self:IsBarFloating() then
		windowed = true
		for _, group in ipairs(groups) do Adopt(group, self:GetBarWindow()) end
	end
	self:LayoutBar()
	self:RefreshBar()
	self:SetupBarDock()
	return bar
end

------------------------------------------------------------------ docked or floating

-- Whether the bar is the floating window now: st.config.global.editModeBar
-- { floating, x, y }, written on a mode change and a window drag (an account's
-- choice, not a profile's).
function EM:IsBarFloating()
	local saved = st.config and st.config.global and st.config.global.editModeBar
	return type(saved) == 'table' and saved.floating == true
end

-- Whether the controls are in the floating window, not on the docked bar.
function EM:IsBarWindowed() return windowed end

-- Lets go of what an open list or a focused box holds, for a control that is
-- about to move: tooltips, the History list, the kit's list when a bar control
-- owns it, and the keyboard.
local function CloseOpenThings()
	local owner = W.ListOwner and W.ListOwner()
	if EM.barWindow then W.HideTip(EM.barWindow.dock) end
	for _, group in ipairs(groups) do
		for _, control in ipairs(group.built or {}) do
			W.HideTip(control.frame)
			if owner and owner == control.frame then W.CloseList() end
			if control.frame.HasFocus and control.frame:HasFocus() then control.frame:ClearFocus() end
			if control.frame.edit and control.frame.edit:HasFocus() then control.frame.edit:ClearFocus() end
		end
	end
	EM:HideHistoryList()
end

-- Shows the docked bar or the window, whichever holds the controls, while edit
-- mode is on; neither while it is off.
local function ShowSurface()
	local window = EM:GetBarWindow()
	if EM.active and not InCombatLockdown() then
		if windowed then
			bar:Hide()
			window:Show()
		else
			window:Hide()
			bar:SetShown(not EM:IsBarAway())
		end
	else
		bar:Hide()
		window:Hide()
	end
	EM:UpdateBarDock()
end

-- Shows the bar or the window for the state edit mode is in (bardock.lua's
-- hide until hovered changes it).
function EM:ShowBarSurface() ShowSurface() end

-- Puts the controls where the saved mode says (on the bar or in the window).
-- The controls move, the layout is redone and the lists close when it changed.
local function ApplyMode()
	local want = EM:IsBarFloating()
	if want == windowed then return false end
	CloseOpenThings()
	windowed = want
	local parent = want and EM:GetBarWindow() or bar
	for _, group in ipairs(groups) do Adopt(group, parent) end
	if EM.statusText then EM:SetBarStatus('') end
	EM:LayoutBar()
	EM:RefreshBar()
	return true
end

function EM:SetBarFloating(floating)
	floating = floating and true or false
	local global = st.config.global
	if type(global.editModeBar) ~= 'table' then global.editModeBar = {} end
	global.editModeBar.floating = floating
	if floating then self:SaveBarWindowPlace() end
	if bar then
		ApplyMode()
		ShowSurface()
	end
	self:Fire('BarModeChanged')
end

------------------------------------------------------------------ events

-- The frames under the bar that took the mouse, while a drag has it off them.
local released = {}

local function ReleaseMouse(frame)
	if frame:IsMouseEnabled() then
		released[#released + 1] = frame
		frame:EnableMouse(false)
	end
	for _, child in ipairs({ frame:GetChildren() }) do ReleaseMouse(child) end
end

-- Puts the bar back as it is outside a drag: full alpha and the mouse on the
-- frames the drag took it off. Called when a drag ends and when edit mode turns
-- on or off, so a drag that never reported its end can't leave the bar dead.
local function Restore()
	if not bar then return end
	bar:SetAlpha(1)
	if EM.barWindow then EM.barWindow:SetAlpha(1) end
	if EM.historyList then EM.historyList:SetAlpha(1) end
	for _, frame in ipairs(released) do frame:EnableMouse(true) end
	wipe(released)
end

-- A focused Grid size box or History length box would keep the keyboard from
-- edit mode's catcher, so the arrow keys would not nudge: they let go when a
-- mover is pressed or dragged and when edit mode closes.
local function DropFocus()
	local control = EM:BarControl('gridSize')
	if control and control.frame.edit then control.frame.edit:ClearFocus() end
	local list = EM.historyList
	if list and list.box then list.box.edit:ClearFocus() end
end

EM:On('Enabled', function()
	Restore()
	EM:GetBar()
	ApplyMode()
	EM:LayoutBar()
	EM:RefreshBar()
	EM:RecolorBar() -- what a pass skipped while edit mode was off (the number boxes' arrows)
	ShowSurface()
end)

EM:On('Disabled', function()
	if not bar then return end
	for _, group in ipairs(groups) do
		for _, control in ipairs(group.built or {}) do W.HideTip(control.frame) end
	end
	DropFocus()
	Restore()
	bar:Hide()
	if EM.barWindow then
		W.HideTip(EM.barWindow.dock)
		EM.barWindow:Hide()
	end
end)

EM:On('Pressed', DropFocus)

EM:On('DragStarted', function()
	if not bar then return end
	for _, group in ipairs(groups) do
		for _, control in ipairs(group.built or {}) do W.HideTip(control.frame) end
	end
	DropFocus()
	bar:SetAlpha(BAR.DRAG_ALPHA)
	if #released == 0 then ReleaseMouse(bar) end
	-- The floating window fades and lets go of the mouse the same way (a click
	-- on it would otherwise stop the dragged frame under it from showing).
	local window = EM.barWindow
	if window then
		W.HideTip(window.dock)
		window:SetAlpha(BAR.DRAG_ALPHA)
		if window:IsShown() then ReleaseMouse(window) end
	end
	-- The open History list (historylist.lua) follows the bar: faded, and off the mouse.
	local list = EM.historyList
	if list then
		list:SetAlpha(BAR.DRAG_ALPHA)
		if list:IsShown() then ReleaseMouse(list) end
	end
end)

EM:On('DragStopped', function()
	Restore()
end)

EM:On('SettingsChanged', function() EM:RefreshBar() end)
-- Whether a color pass of (group, key) reaches what the bar, its floating
-- window and the History list draw: Text's Normal and Muted (labels, icons,
-- arrows) and the Accent (a lit control's edge, a mark, the hover). They draw
-- no Buttons color (the controls' fills are the kit's own) and no other Text
-- (Danger shows in a tooltip, drawn as it shows).
function EM.DrawsColor(group, key)
	if group == 'accent' then return true end
	return group == 'text' and (key == nil or key == 'normal' or key == 'muted')
end

-- A Theme pass looks again as it always did; the colors the bar draws repaint
-- its colors only (EM:RecolorBar).
EM:On('ColorsChanged', function(group, key)
	if group == 'theme' then
		EM:RefreshBar()
	elseif EM.DrawsColor(group, key) then
		EM:RecolorBar()
	end
end)
