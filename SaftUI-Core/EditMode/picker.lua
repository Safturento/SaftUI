local st = SaftUI
local EM = st.EditModeFrames

--[[
	Picking between outlines that overlap, the way /fstack cycles frames.

	When two or more outlines are under the cursor, a small list by the cursor
	names them all and marks the one a click or drag would get (the top one).
	The others under the cursor are dimmed. Pressing Alt brings the next one in
	the list to the front, so it's the one grabbed; it stays in front until
	something else is. The list is in registration order, so repeated presses
	go down it and wrap around.

	Outlines are all in the same strata, so their frame levels decide which is
	on top and gets the mouse. Each outline gets its own pair of levels (its
	backdrop sits one below it), handed out in rising order: a new outline, or
	one brought to the front, takes the next pair.
]]

local LEVEL_FIRST, LEVEL_STEP, LEVEL_MAX = 10, 2, 9000
local SCAN_INTERVAL = 0.05 -- seconds between checks of what's under the cursor
local DIM_ALPHA = 0.4
local CURSOR_OFFSET = 16

local nextLevel = LEVEL_FIRST
local nextOrder = 0

local function SetLevel(mover, level)
	mover.level = level
	mover.overlay:SetFrameLevel(level)
	mover.overlay.backdrop:SetFrameLevel(level - 1)
end

-- Gives every outline a fresh pair of levels from LEVEL_FIRST up, in the order
-- they're stacked now, so the levels never run past LEVEL_MAX.
local function Renumber()
	local stacked = {}
	for _, mover in pairs(EM.movers) do stacked[#stacked + 1] = mover end
	table.sort(stacked, function(a, b) return (a.level or 0) < (b.level or 0) end)
	nextLevel = LEVEL_FIRST
	for _, mover in ipairs(stacked) do
		nextLevel = nextLevel + LEVEL_STEP
		SetLevel(mover, nextLevel)
	end
end

function EM:BringToFront(mover)
	if nextLevel + LEVEL_STEP > LEVEL_MAX then Renumber() end
	nextLevel = nextLevel + LEVEL_STEP
	SetLevel(mover, nextLevel)
end

-- Called once per mover by EM:CreateMover: its place in the list, and the front.
function EM:StackMover(mover)
	nextOrder = nextOrder + 1
	mover.order = nextOrder
	self:BringToFront(mover)
end

-- The list by the cursor.
local list = st:CreateFrame('Frame', nil, UIParent)
list:SetFrameStrata('TOOLTIP')
list:SetClampedToScreen(true)
list:Hide()
local text = list:CreateFontString(nil, 'OVERLAY')
text:SetJustifyH('LEFT')
text:SetPoint('TOPLEFT', 6, -6)

local function Name(mover)
	-- Some labels add a second line (an action bar's "off").
	local label = mover.label:GetText() or mover.key
	return label:match('^[^\n]*')
end

local function ColorCode(color)
	local r, g, b = color:GetRGB()
	return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
end

local stack = {} -- the outlines under the cursor, in registration order
local dimmed = {}

local function Undim()
	for mover in pairs(dimmed) do
		mover.overlay:SetAlpha(1)
		dimmed[mover] = nil
	end
end

local function Top()
	local top
	for _, mover in ipairs(stack) do
		if not top or mover.level > top.level then top = mover end
	end
	return top
end

local function IsDragging()
	for _, mover in pairs(EM.movers) do
		if mover.drag then return true end
	end
	return false
end

local function Refresh()
	Undim()
	if #stack < 2 then
		list:Hide()
		return
	end

	local top = Top()
	local colors = st.config.profile.colors
	local lines = {}
	for _, mover in ipairs(stack) do
		if mover == top then
			lines[#lines + 1] = ColorCode(colors.button.blue) .. '> ' .. Name(mover) .. '|r'
		else
			lines[#lines + 1] = '  ' .. Name(mover)
			mover.overlay:SetAlpha(DIM_ALPHA)
			dimmed[mover] = true
		end
	end
	lines[#lines + 1] = ColorCode(colors.button.grey) .. 'Alt: next|r'

	text:SetText(table.concat(lines, '\n'))
	list:SetSize(text:GetStringWidth() + 12, text:GetStringHeight() + 12)
	list:Show()
end

-- The frame the mouse is on: only outlines count, not a window (e.g. /sui)
-- that's over them.
local function MouseFocus()
	if GetMouseFoci then return GetMouseFoci()[1] end
	return GetMouseFocus and GetMouseFocus()
end

local function Scan()
	wipe(stack)
	if not IsDragging() then
		local focus = MouseFocus()
		local onOutline = false
		for _, mover in pairs(EM.movers) do
			if mover.overlay:IsShown() and mover.overlay:IsMouseOver() then
				stack[#stack + 1] = mover
				if mover.overlay == focus then onOutline = true end
			end
		end
		if onOutline then
			table.sort(stack, function(a, b) return a.order < b.order end)
		else
			wipe(stack)
		end
	end
	Refresh()
end

local function FollowCursor()
	local x, y = GetCursorPosition()
	local scale = list:GetEffectiveScale()
	list:ClearAllPoints()
	list:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x / scale + CURSOR_OFFSET, y / scale + CURSOR_OFFSET)
end

-- Brings the outline after the current top one (in list order) to the front.
local function Cycle()
	if #stack < 2 then return end
	local top = Top()
	for i, mover in ipairs(stack) do
		if mover == top then
			EM:BringToFront(stack[i % #stack + 1])
			break
		end
	end
	Refresh()
end

-- Runs only while edit mode is on.
local driver = CreateFrame('Frame')
driver:Hide()
local elapsed = 0
driver:SetScript('OnUpdate', function(_, delta)
	elapsed = elapsed + delta
	if elapsed >= SCAN_INTERVAL then
		elapsed = 0
		Scan()
	end
	if list:IsShown() then FollowCursor() end
end)
driver:SetScript('OnEvent', function(_, _, key, down)
	if down == 1 and (key == 'LALT' or key == 'RALT') and not IsDragging() then
		Cycle()
	end
end)

EM:On('Enabled', function()
	-- Styled here, not at file load: the theme and fonts come from the profile.
	st:SetBackdrop(list, 'theme', 'solid', 'small')
	text:SetFontObject(st:GetFont('pixel'))
	elapsed = SCAN_INTERVAL
	driver:RegisterEvent('MODIFIER_STATE_CHANGED')
	driver:Show()
end)

EM:On('Disabled', function()
	driver:UnregisterEvent('MODIFIER_STATE_CHANGED')
	driver:Hide()
	wipe(stack)
	Undim()
	list:Hide()
end)
