local st = SaftUI
local EM = st.EditModeFrames
local W, OB = st.OptionsWidgets, st.OptionsBody

--[[
	The edit mode bar's floating window: the same controls as the docked bar
	(bar.lua), in a small window that is dragged by its title, in sections.
	Detach (bargroups.lua) turns the bar into it, Dock in its title turns it
	back, and EM:SetBarFloating(floating) is what both call (bar.lua: it saves
	the mode, moves every control with SetParent, lays out and keeps the shown
	state).

	  st.config.global.editModeBar = { floating, x, y }   the mode and the
	                           window's top left, whole, from UIParent's top
	                           left (written on a mode change and a drag; an
	                           account's choice, not the profile's)
	  EM.WINDOW                { WIDTH 312, PAD 12, TITLE 42, CAPTION 13,
	                           CAPTION_GAP 4, SECTION_PAD 8, GAP 4 }
	  EM.WINDOW_SECTIONS       { { key, caption }, ... }: Grid and snap, Show,
	                           Changes. A control's section (bar.lua) says which
	                           it is under; 'title' controls (Exit) are in the
	                           title row, with Dock.
	  EM.WindowLayout(width, sections) -> rows, height      the pure part
	  EM:GetBarWindow() -> frame             built on first use (EM.barWindow)
	  EM:LayoutWindow() -> 0                 lays the controls out in it
	  EM:PlaceBarWindow() -> x, y            at the saved place, or by default,
	                           kept inside the screen edge margin
	  EM:SaveBarWindowPlace()                writes the place if none is saved
	  EM:PlaceWindowStatus(text)             the status line under Changes
	  window.dock, window.title, window.heading, window.captions[key]

	The frame is a SaftUI frame on UIParent in FULLSCREEN_DIALOG at level
	EM.BAR.LEVEL (over /sui at 100 and the movers; under the History list at
	9700 and everything in TOOLTIP strata), a panel in the theme, movable, and
	kept inside the screen edge margin (st:KeepInScreenMargin). It takes the
	mouse (a click on it selects no mover under it) except while a mover is
	dragged, when it fades and lets go with the bar's controls (bar.lua). Its
	title row is the drag handle (StartMoving; at the end the place is read from
	where it shows, made whole, put inside the margin, saved and anchored).
	Edit mode turning off hides it, and so does combat.

	Layout. Whole pixels throughout: the controls are placed by their top left,
	a text is ceil(its width) wide, sizes are whole. EM.WindowLayout gives each
	control its x and y (a line's top, 26 tall; the window centres a shorter
	control in it) and the window's height: the title, then for each section
	with a control SECTION_PAD, its caption, CAPTION_GAP, its lines GAP apart,
	SECTION_PAD, and a 1px line between sections. Controls wrap into lines
	within width less twice PAD; a control WIDE (100) or more wide starts a new
	line when the line already holds a narrower one (one way: a narrow one after
	it may share; so the Show section is its toggles, then the face and filter on
	a line of their own), and one that is
	right-aligned ends its line at the right padding. A width of 0 is not shown.

	The status line (barchanges.lua, EM:SetBarStatus) is under the Changes
	section, wrapped to the window's inside width, from the left; the window
	grows by its height and the padding while it shows, and is never cut, so it
	has no tooltip fallback there.

	The History list opens beside it (historylist.lua's EM:PlaceHistoryList).
]]

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

EM.WINDOW = { WIDTH = 312, PAD = 12, TITLE = 42, CAPTION = 13, CAPTION_GAP = 4, SECTION_PAD = 8, GAP = 4 }
local WIN = EM.WINDOW

EM.WINDOW_SECTIONS = {
	{ key = 'grid', caption = 'Grid and snap' },
	{ key = 'show', caption = 'Show' },
	{ key = 'changes', caption = 'Changes' },
}

local LINE = 26        -- a line of controls: the kit's button height
local WIDE = 100       -- a control this wide or more has a line to itself, with its own kind
local TITLE_IN = 8     -- the title row's buttons, in from the window's right
local DEFAULT_TOP = -80

local window

local function Whole(value) return floor(value + 0.5) end

------------------------------------------------------------------ the pure layout

--[[
	Where everything goes in a window width wide. sections is { { widths = { w,
	... }, aligns = { 'right' | nil, ... } }, ... } in order. Returns rows and
	height:
	  rows[s][c]   { x, y } of control c of section s, from the window's top
	               left, whole (nil for a width of 0): y is its line's top
	  rows[s].top, .caption, .bottom   the section's top, its caption's top and
	               its bottom, nil for a section with no control
	  rows[s].rule the y of the 1px line above it, nil for the first one shown
	  height       the window's, whole
]]
function EM.WindowLayout(width, sections)
	local inner = width - 2 * WIN.PAD
	local limit = WIN.PAD + inner
	local rows = {}
	local y, shown = WIN.TITLE, 0
	for s, section in ipairs(sections) do
		local entry = {}
		rows[s] = entry
		local any = false
		for _, w in ipairs(section.widths) do if w > 0 then any = true end end
		if any then
			if shown > 0 then
				entry.rule = y
				y = y + 1
			end
			shown = shown + 1
			entry.top = y
			y = y + WIN.SECTION_PAD
			entry.caption = y
			y = y + WIN.CAPTION + WIN.CAPTION_GAP
			local lineTop, x = y, WIN.PAD
			local empty, narrow, closed = true, false, false
			for c, w in ipairs(section.widths) do
				if w > 0 then
					local right = section.aligns and section.aligns[c] == 'right'
					local wraps = closed or (not empty and (x + w > limit or (w >= WIDE and narrow)))
					if wraps then
						lineTop = lineTop + LINE + WIN.GAP
						x, empty, narrow, closed = WIN.PAD, true, false, false
					end
					local at = right and limit - w or x
					entry[c] = { x = at, y = lineTop }
					x = at + w + WIN.GAP
					empty = false
					if w < WIDE then narrow = true end
					if right then closed = true end
				end
			end
			y = lineTop + LINE + WIN.SECTION_PAD
			entry.bottom = y
		end
	end
	return rows, y
end

------------------------------------------------------------------ the saved place

local function Saved()
	local saved = st.config and st.config.global and st.config.global.editModeBar
	return type(saved) == 'table' and saved or nil
end

-- The saved place, whole, or nothing when there is none or it is not numbers.
local function SavedPlace()
	local saved = Saved()
	if saved and type(saved.x) == 'number' and type(saved.y) == 'number' and saved.x == saved.x and saved.y == saved.y
		and math.abs(saved.x) < 1e6 and math.abs(saved.y) < 1e6 then
		return Whole(saved.x), Whole(saved.y)
	end
end

local function DefaultPlace()
	return floor((UIParent:GetWidth() - WIN.WIDTH) / 2), DEFAULT_TOP
end

-- x, y moved inside the screen edge margin (st:GetScreenMargin): the left and
-- top win where the window is larger than the room, and the result is whole.
local function Inside(x, y)
	local width, height = Whole(window:GetWidth()), Whole(window:GetHeight())
	local left, right, top, bottom = st:GetScreenMargin(window)
	local screenWidth, screenHeight = UIParent:GetWidth(), UIParent:GetHeight()
	x = max(min(x, floor(screenWidth - right - width)), ceil(left))
	y = min(max(y, ceil(bottom + height - screenHeight)), -ceil(top))
	return x, y
end

function EM:PlaceBarWindow()
	local frame = self:GetBarWindow()
	local x, y = SavedPlace()
	if not x then x, y = DefaultPlace() end
	x, y = Inside(x, y)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x, y)
	return x, y
end

-- A mode change writes the place too: the default one when none is saved.
function EM:SaveBarWindowPlace()
	local saved = Saved()
	if not saved or SavedPlace() then return end
	saved.x, saved.y = DefaultPlace()
end

-- The end of a drag: where the window shows, whole and inside the margin, saved
-- and anchored.
local function Dropped()
	window:StopMovingOrSizing()
	local left, top = window:GetLeft(), window:GetTop()
	if not left or not top then return end
	local x, y = Inside(Whole(left - UIParent:GetLeft()), Whole(top - UIParent:GetTop()))
	local saved = Saved()
	if not saved then
		saved = {}
		st.config.global.editModeBar = saved
	end
	saved.x, saved.y = x, y
	EM:PlaceBarWindow()
	if EM:IsHistoryListShown() then EM:PlaceHistoryList() end
end

------------------------------------------------------------------ the layout of the real window

-- A text ceil of its width wide and of its height tall, from its top left.
local function FitText(text)
	local width, height = ceil(text:GetStringWidth()), ceil(text:GetStringHeight())
	text:SetSize(width, height)
	return width, height
end

function EM:LayoutWindow()
	local frame = self:GetBarWindow()
	local sectionOf, lists = {}, {}
	for i, section in ipairs(EM.WINDOW_SECTIONS) do
		sectionOf[section.key] = i
		lists[i] = {}
	end
	local title = {}
	for _, control in ipairs(self:BarControls()) do
		local width = control:Lay(0, true) or 0
		control.frame:SetShown(width > 0)
		-- A section the window does not have goes in the last one (never left
		-- shown with no place).
		local into = control.section == 'title' and title or lists[sectionOf[control.section] or #lists]
		if into and width > 0 then into[#into + 1] = { control = control, width = width } end
	end

	local sections = {}
	for i, list in ipairs(lists) do
		local widths, aligns = {}, {}
		for c, item in ipairs(list) do
			widths[c], aligns[c] = item.width, item.control.align
		end
		sections[i] = { widths = widths, aligns = aligns }
	end
	local rows, height = EM.WindowLayout(WIN.WIDTH, sections)

	for i, list in ipairs(lists) do
		local entry = rows[i]
		for c, item in ipairs(list) do
			local spot = entry[c]
			local f = item.control.frame
			f:ClearAllPoints()
			f:SetPoint('TOPLEFT', frame, 'TOPLEFT', spot.x, -(spot.y + floor((LINE - Whole(f:GetHeight())) / 2)))
		end
		local caption = frame.captions[EM.WINDOW_SECTIONS[i].key]
		if entry.top then
			local _, textHeight = FitText(caption)
			caption:ClearAllPoints()
			caption:SetPoint('TOPLEFT', frame, 'TOPLEFT', WIN.PAD, -(entry.caption + floor((WIN.CAPTION - textHeight) / 2)))
			caption:Show()
		else
			caption:Hide()
		end
	end

	-- The lines: under the title, and between the sections.
	local rules = { WIN.TITLE - 1 }
	for _, entry in ipairs(rows) do
		if entry.rule then rules[#rules + 1] = entry.rule end
	end
	for i, y in ipairs(rules) do
		local line = frame.rules[i]
		if not line then
			line = OB.Line(frame)
			line:SetHeight(1)
			frame.rules[i] = line
		end
		line:SetWidth(WIN.WIDTH)
		line:ClearAllPoints()
		line:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -y)
		line:Show()
	end
	for i = #rules + 1, #frame.rules do frame.rules[i]:Hide() end

	-- The title row: the heading at the left; the buttons at the right, Exit
	-- last, Dock before it, 4 apart, TITLE_IN from the edge.
	local _, headingHeight = FitText(frame.heading)
	frame.heading:ClearAllPoints()
	frame.heading:SetPoint('TOPLEFT', frame, 'TOPLEFT', WIN.PAD, -floor((WIN.TITLE - headingHeight) / 2))
	local x = WIN.WIDTH - TITLE_IN
	local function PlaceTitle(f, width)
		x = x - width
		f:ClearAllPoints()
		f:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -floor((WIN.TITLE - Whole(f:GetHeight())) / 2))
		x = x - WIN.GAP
	end
	for i = #title, 1, -1 do PlaceTitle(title[i].control.frame, title[i].width) end
	frame.dock:Show()
	PlaceTitle(frame.dock, Whole(frame.dock:GetWidth()))

	frame.baseHeight = height
	frame:SetSize(WIN.WIDTH, height)
	self:PlaceBarWindow()
	self:Fire('BarLaid')
	return 0
end

-- The status line under the Changes section (barchanges.lua's PlaceStatus):
-- wrapped to the inside width and from the left, the window as tall as the
-- sections and it. text nil (or empty) is no status: the window as tall as
-- the sections.
function EM:PlaceWindowStatus(text)
	local frame = self:GetBarWindow()
	local base = frame.baseHeight or Whole(frame:GetHeight())
	if not text or (text:GetText() or '') == '' then
		frame:SetHeight(base)
		if frame:IsShown() then self:PlaceBarWindow() end
		return
	end
	text:SetParent(frame)
	text:SetJustifyH('LEFT')
	text:SetWordWrap(true)
	text:SetWidth(WIN.WIDTH - 2 * WIN.PAD)
	-- A font string lays its text out inside the height it was given (lines
	-- past it are dropped), so it is measured with none: 0 sizes it to its text.
	text:SetHeight(0)
	local height = ceil(text:GetStringHeight())
	text:SetHeight(height)
	text:ClearAllPoints()
	text:SetPoint('TOPLEFT', frame, 'TOPLEFT', WIN.PAD, -base)
	text:Show()
	frame:SetHeight(base + height + WIN.SECTION_PAD)
	if frame:IsShown() then self:PlaceBarWindow() end
end

------------------------------------------------------------------ the frame

-- The look of the window's own parts: the title, the captions, the lines and
-- Dock (the controls' are bar.lua's).
function EM:LookBarWindow(blizzard)
	if not window then return end
	W.LookControl(window.dock, blizzard)
	window.heading:SetTextColor(OB.Normal())
	for _, caption in pairs(window.captions) do caption:SetTextColor(OB.Grey()) end
	for _, line in ipairs(window.rules) do line:SetColorTexture(unpack(OB.LINE)) end
end

function EM:GetBarWindow()
	if window then return window end
	window = st:CreateFrame('Frame', nil, UIParent)
	EM.barWindow = window
	window:SetFrameStrata('FULLSCREEN_DIALOG')
	window:SetFrameLevel(EM.BAR.LEVEL)
	window:SetSize(WIN.WIDTH, WIN.TITLE)
	window:SetMovable(true)
	window:EnableMouse(true)
	window:Hide()
	st:SetBackdrop(window, 'theme', 'theme', 'panel')
	st:KeepInScreenMargin(window)
	window.captions, window.rules = {}, {}

	-- The title row is the drag handle.
	local title = CreateFrame('Frame', nil, window)
	window.title = title
	title:SetSize(WIN.WIDTH, WIN.TITLE)
	title:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, 0)
	title:EnableMouse(true)
	title:RegisterForDrag('LeftButton')
	title:SetScript('OnDragStart', function() window:StartMoving() end)
	title:SetScript('OnDragStop', Dropped)
	-- Hidden mid-drag (combat closes edit mode): it must not go on following the
	-- cursor when it shows again.
	window:SetScript('OnHide', function(self) self:StopMovingOrSizing() end)

	window.heading = OB.Text(title, 'section', 'LEFT')
	window.heading:SetText('Edit mode')
	for _, section in ipairs(EM.WINDOW_SECTIONS) do
		local caption = OB.Text(window, 'caption', 'LEFT')
		caption:SetText(section.caption)
		window.captions[section.key] = caption
	end

	local dock = W.IconButton(window, st.icons.panelTop, function()
		return 'Dock', { 'Puts the controls back in a bar across the top of the screen.' }
	end)
	dock.onClick = EM.BarGuard(function() EM:SetBarFloating(false) end)
	EM.SettleLevel(dock, window:GetFrameLevel() + 2, EM.LevelShape(dock))
	window.dock = dock

	-- The screen's size or scale, and the screen edge margin, change where it
	-- can sit: it lays out again and is put back inside.
	window:RegisterEvent('UI_SCALE_CHANGED')
	window:RegisterEvent('DISPLAY_SIZE_CHANGED')
	window:SetScript('OnEvent', function()
		if EM:IsBarFloating() then EM:LayoutBar() end
		-- The events can fire before UIParent has its new size: place again on
		-- the next frame, as the bar also lays out on its own size change.
		C_Timer.After(0, function()
			if EM:IsBarFloating() and window:IsShown() then EM:PlaceBarWindow() end
		end)
	end)
	hooksecurefunc(st, 'UpdateScreenMargin', function()
		if window:IsShown() then EM:PlaceBarWindow() end
	end)
	EM:LookBarWindow(W.BlizzardLook())
	return window
end
