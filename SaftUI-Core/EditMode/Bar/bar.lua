local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody

--[[
	Edit mode's bar: the controls of edit mode (Exit, the grid and its size, the
	snaps, Dim world, Coordinates, Show disabled, Show hidden, the module list, the filter, Options, Detach) in one strip across the top of the
	screen (or, detached, in the floating window of barwindow.lua), shown while edit
	mode is on, with /sui open or closed. This file is the bar itself: its
	frame, the list of groups of controls, the layout (EM.BarLayout, pure) and
	the events that show it, fade it and keep it current. The groups and their
	controls are bargroups.lua's, and later files add theirs the same way
	(EM:AddBarGroup, at load).

	  EM.BAR                   the numbers: HEIGHT 40, PAD 10 (the bar's ends), GAP 4
	                           (between controls), GROUP_PAD 8 (each side of a
	                           divider), FLEX_MIN 12 (the least gap between the left
	                           and right groups), LEVEL 9500, DRAG_ALPHA, STAGES 6
	  EM:AddBarGroup(group)    group = { key, order, side = 'left' | 'right',
	                           section = 'title' | 'grid' | 'show' | 'changes',
	                           controls = function(parent) -> { control, ... } }.
	                           section is the floating window's. Left groups run
	                           from the left end by order, right groups to the
	                           right end.
	  a control                { key, frame, Lay, Refresh, Look, section, align }
	    Lay(control, stage, floating) -> width   lays the control out for the
	                           stage and says its width; 0 is not shown
	    Refresh(control)       puts the settings' state on it (optional)
	    Look(control, blizzard) its look for the theme; W.LookControl(frame) when
	                           it has none (a number box's is W.LookNumberBox)
	    section, align         the group's section overridden, 'right' (unused in
	                           the docked bar)
	  EM.BarLayout(width, groups) -> xs, dividers, fits      the pure part
	  EM:GetBar()              the frame, built on first use
	  EM:LayoutBar() -> stage  lays the controls out for the bar's width
	  EM:BarGap() -> left, right  the flexible gap in the bar's x: where the left
	                           groups end, and where the first right group's
	                           divider is (the bar's right end less PAD with no
	                           right groups), as the last layout left it
	  EM:BarWidthAt(stage)     the narrowest width the bar fits at that stage
	  EM:RefreshBar()          each control's look and state again
	  EM:BarControl(key)       a control by its key
	  EM:IsBlizzardEditModeOpen()

	The frame is a SaftUI frame in FULLSCREEN_DIALOG at level BAR.LEVEL, above
	every mover (they climb to 9000, picker.lua) and /sui (level 100), under
	everything in TOOLTIP strata. It is HEIGHT tall from the screen's left to
	its right, drawn as a panel in the theme: its backdrop already sits the
	theme's inset outside the frame, so with the frame flush with the screen's
	top, left and right only its bottom line shows. The frame takes no mouse
	(a click between controls reaches the mover under it); its controls do.
	Controls are children one level above its own (their boxes' backdrops, one
	below them, stay over the bar's), vertically centred on whole pixels.

	Narrow screens. The stages give way cumulatively, each when the one before
	does not fit (EM:LayoutBar takes the first that does, else the last):
	1 narrows the filter box, 2 hides the Show caption, 3 narrows the Show
	face, 4 makes Exit and Options icon buttons, 5 hides the filter box. A
	control reads its stage in its Lay and ignores the ones that are not its.
	The bar lays out again on UI_SCALE_CHANGED and DISPLAY_SIZE_CHANGED (its own
	frame's events) and on its own size change. Sizes the game reads back carry
	a hair of float noise, so the width is rounded.

	Events (EM:On): Enabled lays out, refreshes and shows it, Disabled hides it
	(and so does entering combat, which turns edit mode off). DragStarted fades
	it to DRAG_ALPHA and takes the mouse off every control, so a frame dragged
	up under it shows through; DragStopped brings it back. SettingsChanged and
	ColorsChanged refresh it. Every control's click does nothing in combat
	(bargroups.lua's Guard).

	Whole pixels: widths come in whole, the controls are placed by their top
	left from the bar's, and a divider is a 1 x 26 line, HAIRLINE, kept under
	Blizzard too (it has no art for one).
]]

local floor = math.floor

EM.BAR = {
	HEIGHT = 40, PAD = 10, GAP = 4, GROUP_PAD = 8, FLEX_MIN = 12,
	LEVEL = 9500, DRAG_ALPHA = 0.25, STAGES = 6,
}
local BAR = EM.BAR

local DIVIDER_HEIGHT = 26

local groups = {} -- registered groups, by order
local bar         -- the frame, once made
local windowed = false -- the controls are in the floating window (barwindow.lua), not on the bar
local stage = 0   -- the stage the controls are laid out for
local gapLeft, gapRight = BAR.PAD, BAR.PAD -- the flexible gap, from the last layout

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

-- Puts a row's controls from x, GAP apart, a width of 0 skipped; row[c] is
-- control c's x. Returns where the last one ends.
local function PlaceRow(row, widths, x)
	local first = true
	for c, width in ipairs(widths) do
		if width > 0 then
			if not first then x = x + BAR.GAP end
			first = false
			row[c] = x
			x = x + width
		end
	end
	return x
end

-- Where the left groups end, and how wide the right groups' block is from its
-- first divider to PAD short of the bar's right end.
local function Measure(list)
	local x, leftEnd, anyLeft = BAR.PAD, BAR.PAD, false
	local block, rightCount = 0, 0
	for _, group in ipairs(list) do
		local total, count = GroupWidth(group.widths)
		if count > 0 then
			if group.side == 'right' then
				rightCount = rightCount + 1
				block = block + (rightCount == 1 and 1 + BAR.GROUP_PAD or 2 * BAR.GROUP_PAD + 1) + total
			else
				if anyLeft then x = x + 2 * BAR.GROUP_PAD + 1 end
				anyLeft = true
				x = x + total
				leftEnd = x
			end
		end
	end
	return leftEnd, block
end

--[[
	Where everything goes in a bar width wide. groups is { { side, widths = {
	w, ... } }, ... } in order, a width of 0 not shown (a group with none is
	skipped whole). Returns xs, dividers and fits:
	  - xs[g][c], control c of group g's x from the bar's left, whole;
	  - dividers, a list of x;
	  - fits, whether the left end plus FLEX_MIN is at most the divider before
	    the right groups (the bar's right end less PAD with no right groups).
	The left groups run from PAD, GAP between controls, with GROUP_PAD, a 1
	wide divider and GROUP_PAD between groups. The right groups end PAD short
	of the right end, the same between them, and the first has a divider at its
	left.
]]
function EM.BarLayout(width, list)
	local xs, dividers = {}, {}
	local x, anyLeft = BAR.PAD, false
	local right, leftEnd = {}, BAR.PAD
	for g, group in ipairs(list) do
		xs[g] = {}
		local _, count = GroupWidth(group.widths)
		if count > 0 then
			if group.side == 'right' then
				right[#right + 1] = g
			else
				if anyLeft then
					dividers[#dividers + 1] = x + BAR.GROUP_PAD
					x = x + 2 * BAR.GROUP_PAD + 1
				end
				anyLeft = true
				x = PlaceRow(xs[g], group.widths, x)
				leftEnd = x
			end
		end
	end
	local _, block = Measure(list)
	local boundary = width - BAR.PAD
	x = width - BAR.PAD - block
	for i, g in ipairs(right) do
		if i == 1 then boundary = x end
		dividers[#dividers + 1] = x
		x = PlaceRow(xs[g], list[g].widths, x + 1 + BAR.GROUP_PAD) + BAR.GROUP_PAD
	end
	return xs, dividers, leftEnd + BAR.FLEX_MIN <= boundary
end

------------------------------------------------------------------ the controls

-- Lays every control out for stage (showing or hiding its frame), and returns
-- the groups as BarLayout takes them, with the group and its controls.
local function LayAll(forStage, floating)
	local list = {}
	for _, group in ipairs(groups) do
		local entry = { side = group.side, widths = {}, group = group }
		for c, control in ipairs(group.built or {}) do
			local width = control:Lay(forStage, floating or false) or 0
			entry.widths[c] = width
			control.frame:SetShown(width > 0)
		end
		list[#list + 1] = entry
	end
	return list
end

-- The controls' top: centred in the bar on whole pixels (26 at 7, 24 at 8, 22
-- at 9), from the height as the game reads it back.
local function Top(frame)
	return -floor((BAR.HEIGHT - floor(frame:GetHeight() + 0.5)) / 2)
end

local dividers = {} -- the bar's dividers, kept

-- Puts every shown control and the dividers where BarLayout said.
local function Place(list, xs, divided)
	for g, entry in ipairs(list) do
		for c, control in ipairs(entry.group.built or {}) do
			local x = xs[g][c]
			if x then
				control.frame:ClearAllPoints()
				control.frame:SetPoint('TOPLEFT', bar, 'TOPLEFT', x, Top(control.frame))
			end
		end
	end
	local top = -floor((BAR.HEIGHT - DIVIDER_HEIGHT) / 2)
	for i, x in ipairs(divided) do
		local line = dividers[i]
		if not line then
			line = bar:CreateTexture(nil, 'ARTWORK')
			line:SetSize(1, DIVIDER_HEIGHT)
			dividers[i] = line
		end
		line:SetColorTexture(unpack(OB.HAIRLINE))
		line:ClearAllPoints()
		line:SetPoint('TOPLEFT', bar, 'TOPLEFT', x, top)
		line:Show()
	end
	for i = #divided + 1, #dividers do dividers[i]:Hide() end
end

-- Lays the controls out for the bar's width: the first stage whose layout
-- fits, else the last. Returns the stage.
function EM:LayoutBar()
	local frame = self:GetBar()
	if windowed then return self:LayoutWindow() end
	local width = floor(frame:GetWidth() + 0.5)
	for s = 0, BAR.STAGES - 1 do
		local list = LayAll(s)
		local xs, divided, fits = EM.BarLayout(width, list)
		if fits or s == BAR.STAGES - 1 then
			Place(list, xs, divided)
			stage = s
			local leftEnd, block = Measure(list)
			gapLeft = leftEnd
			gapRight = width - BAR.PAD - block
			self:Fire('BarLaid')
			return s
		end
	end
end

-- The flexible gap between the left groups and the first right group's
-- divider, in the bar's x, as the last layout left it: the status line
-- (barchanges.lua) sits in it. 'BarLaid' (no arguments) fires after each
-- layout, for what is placed by it.
function EM:BarGap() return gapLeft, gapRight end

-- The narrowest bar the controls fit in at stage: the left groups, FLEX_MIN,
-- and the right groups' block, with PAD at each end. The controls are laid
-- out at the stage they were at again afterwards.
function EM:BarWidthAt(forStage)
	self:GetBar()
	local leftEnd, block = Measure(LayAll(forStage))
	LayAll(stage, windowed)
	return leftEnd + BAR.FLEX_MIN + BAR.PAD + block
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
	EM.bar = bar -- the docked bar's frame (EM:BarCoverHeight reads whether it is shown)
	bar:SetFrameStrata('FULLSCREEN_DIALOG')
	bar:SetFrameLevel(BAR.LEVEL)
	bar:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
	bar:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', 0, 0)
	bar:SetHeight(BAR.HEIGHT)
	bar:EnableMouse(false)
	st:SetBackdrop(bar, 'theme', 'theme', 'panel')
	bar:Hide()
	-- The screen events can fire before UIParent has its new size, so the bar
	-- also lays out when its own size (UIParent's width) changes.
	bar:RegisterEvent('UI_SCALE_CHANGED')
	bar:RegisterEvent('DISPLAY_SIZE_CHANGED')
	-- (In the floating window the window's own events lay it out.)
	bar:SetScript('OnEvent', function() if not windowed then EM:LayoutBar() end end)
	bar:HookScript('OnSizeChanged', function() if not windowed then EM:LayoutBar() end end)
	for _, group in ipairs(groups) do BuildGroup(group) end
	if self:IsBarFloating() then
		windowed = true
		for _, group in ipairs(groups) do Adopt(group, self:GetBarWindow()) end
	end
	self:LayoutBar()
	self:RefreshBar()
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

-- How much of the screen's top the bar covers: its height and the line its
-- backdrop draws under it while it is docked and shown, else 0 (floating, or
-- hidden). EM:ScreenTop and what keeps clear of the bar read it.
function EM:BarCoverHeight()
	if bar and bar:IsShown() and not windowed then
		return BAR.HEIGHT + st:ThemeInset('theme', 'theme', 'panel')
	end
	return 0
end

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
			bar:Show()
		end
	else
		bar:Hide()
		window:Hide()
	end
end

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
EM:On('ColorsChanged', function() EM:RefreshBar() end)
