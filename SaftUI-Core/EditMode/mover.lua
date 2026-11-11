local st = SaftUI
local EM = st.EditModeFrames

local ARROW_KEYS = { UP = true, DOWN = true, LEFT = true, RIGHT = true }
local NUDGE = {
	UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 },
}
local LIVE_INTERVAL = 0.1 -- seconds between settings refreshes while dragging

-- The overlay has SaftUI's theme's border: a 1px line EM.OutlineOutset()
-- outside the frame (under Thick 2px, between two dark lines). Only that line
-- takes the highlight color, so the outline sits exactly where a SaftUI
-- frame's own border line is, and gaps between frames look the same in edit
-- mode as out of it. The fill stays see-through so the frame shows; the
-- selected frame's is tinted blue, since a 1px line alone is easy to miss.
local function SetBorderColor(mover, selected)
	local backdrop = mover.overlay.backdrop
	local r, g, b = 1, 1, 1
	if selected then
		r, g, b = st.config.profile.colors.button.blue:GetRGB()
		backdrop:SetBackdropColor(r, g, b, 0.15)
	else
		backdrop:SetBackdropColor(0, 0, 0, 0.3)
	end
	st:SetBorderColor(backdrop, r, g, b, 1)
end

-- The anchor the mover's frame is positioned with, taken from its stored position.
local function GetAnchor(mover)
	local pos = mover.def.getPosition()
	local point, relative, rel_point, x, y = st:UnpackPoint(pos)
	-- Older profiles saved typed offsets as strings; drags and nudges do math
	-- on them (st:RoundToPixel compares with <), so normalise here.
	return point, st:ResolveFrame(relative) or UIParent, rel_point, tonumber(x) or 0, tonumber(y) or 0
end

local function ApplyOffsets(mover, x, y)
	local point, relative, rel_point = GetAnchor(mover)
	local frame = mover.def.frame
	frame:ClearAllPoints()
	frame:SetPoint(point, relative, rel_point, x, y)
end

-- Where the mover's frame shows: the offsets that anchor it there, and its rect
-- in UIParent units ({ left, right, bottom, top }, nil if it can't be read, e.g.
-- a secret edge). The game shows a frame kept inside the screen edge margin
-- inside it even when its anchor would put it in the margin (st:GetClampShift),
-- so a drag or nudge starts from where it shows, and stores where it ends.
local function Where(mover)
	local _, _, _, x, y = GetAnchor(mover)
	local frame = mover.def.frame
	local sx, sy = st:GetClampShift(frame)
	if sx then x, y = x + sx, y + sy end
	local l, r, b, t = EM.GetRectInUI(frame)
	return x, y, l and { left = l, right = r, bottom = b, top = t }
end

-- The correction (mx, my), in UIParent units, that keeps a frame moved by
-- (dx, dy) inside the screen edge margin: rect is where it shows before the
-- move ({ left, right, bottom, top }, UIParent units), the screen is width x
-- height, and inset is the margin (below 0, how far past the edges it can go).
-- 0, 0 for a move that stays inside. A frame too wide or tall for the room
-- inside the margin keeps its left and top edges in.
function EM.MarginCorrection(rect, dx, dy, width, height, inset)
	-- The smallest and largest moves that keep low..high inside 0..size.
	local function Range(low, high, size)
		return inset - low, size - inset - high
	end
	local leastX, mostX = Range(rect.left, rect.right, width)
	local leastY, mostY = Range(rect.bottom, rect.top, height)
	local x = math.max(math.min(dx, mostX), leastX) -- left wins
	local y = math.min(math.max(dy, leastY), mostY) -- top wins
	return x - dx, y - dy
end

-- The screen edge margin in UIParent units. It's in the frame's own units
-- (SetClampRectInsets), and ratio is UIParent's scale over the frame's.
local function MarginInUI(ratio)
	return st.config.profile.misc.clamp_inset / ratio
end

function EM:StartDrag(mover)
	local x, y, shown = Where(mover)
	local cx, cy = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	mover.drag = { cx = cx / uiScale, cy = cy / uiScale, x0 = x, y0 = y, x = x, y = y, shown = shown }
	-- For snapping: where the frame is now, and the lines it can snap to. The
	-- other frames don't move during a drag, so the lines are made once.
	-- It's measured by its outline, the line its overlay draws (chat's sits on
	-- its padded border). The overlay is anchored to the frame, so it moves by
	-- the same delta.
	local l, r, b, t = EM.GetOutlineRect(mover)
	if l then
		mover.drag.rect0 = { left = l, right = r, bottom = b, top = t }
	end
	mover.drag.xLines, mover.drag.yLines = self:GetSnapLines(mover)
	mover.dragged = true
	mover.overlay:SetScript('OnUpdate', function() EM:UpdateDrag(mover) end)
end

function EM:UpdateDrag(mover)
	local drag = mover.drag
	if not drag then return end
	local cx, cy = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	-- cursor delta in UIParent units, converted to the moved frame's units
	local ratio = uiScale / mover.def.frame:GetEffectiveScale()
	local dUIx = cx / uiScale - drag.cx
	local dUIy = cy / uiScale - drag.cy
	-- Snapping adds a correction (in UIParent units) that pulls an edge or the
	-- center onto a nearby line. Ctrl held suspends it.
	local sx, sy = 0, 0
	if drag.rect0 and not IsControlKeyDown()
			and (#drag.xLines > 0 or #drag.yLines > 0) then
		sx, sy = EM.SnapDrag(drag.rect0, dUIx, dUIy, drag.xLines, drag.yLines, EM.SNAP_REACH)
	end
	-- The screen edge margin has the last word: the frame can't be dragged into it.
	if drag.shown then
		local mx, my = EM.MarginCorrection(drag.shown, dUIx + sx, dUIy + sy,
			UIParent:GetWidth(), UIParent:GetHeight(), MarginInUI(ratio))
		sx, sy = sx + mx, sy + my
	end
	drag.x = st:RoundToPixel(EM.SnappedOffset(drag.x0, dUIx, sx, ratio), mover.def.frame)
	drag.y = st:RoundToPixel(EM.SnappedOffset(drag.y0, dUIy, sy, ratio), mover.def.frame)
	ApplyOffsets(mover, drag.x, drag.y)

	-- Keep an open /sui showing the live x/y. Throttled: each refresh
	-- rebuilds its widgets. The drag's end commits as before.
	local now = GetTime()
	if (drag.x ~= drag.shownX or drag.y ~= drag.shownY)
			and now - (drag.shownAt or 0) >= LIVE_INTERVAL then
		drag.shownX, drag.shownY, drag.shownAt = drag.x, drag.y, now
		local pos = mover.def.getPosition()
		pos.x_off = drag.x
		pos.y_off = drag.y
		mover.def.setPosition(pos)
		self:Fire('PositionChanged', mover)
	end
end

-- Ends a drag (if any), committing the last applied offset.
function EM:StopDrag(mover)
	local drag = mover.drag
	if not drag then return end
	mover.drag = nil
	mover.overlay:SetScript('OnUpdate', nil)
	self:CommitPosition(mover, drag.x, drag.y)
end

function EM:Select(mover)
	if self.selected == mover then return end
	if self.selected then
		SetBorderColor(self.selected, false)
	end
	self.selected = mover
	if mover then
		SetBorderColor(mover, true)
	end
	self:UpdateKeyboard()
	self:Fire('Selected', mover)
end

-- Moves the frame a pixel (big: 10), from where it shows, and not into the
-- screen edge margin.
function EM:Nudge(mover, key, big)
	local def = mover.def
	local pixel = st:GetPixelSize(def.frame)
	if not pixel then return end
	local step = st:RoundToPixel(pixel, def.frame) * (big and 10 or 1)
	local x, y, shown = Where(mover)
	local dir = NUDGE[key]
	local dx, dy = dir[1] * step, dir[2] * step
	if shown then
		local ratio = UIParent:GetEffectiveScale() / def.frame:GetEffectiveScale()
		local mx, my = EM.MarginCorrection(shown, dx / ratio, dy / ratio,
			UIParent:GetWidth(), UIParent:GetHeight(), MarginInUI(ratio))
		dx, dy = dx + mx * ratio, dy + my * ratio
	end
	self:CommitPosition(mover, x + dx, y + dy)
end

function EM:CreateMover(key, def)
	local mover = { key = key, def = def }

	local overlay = st:CreateFrame('Button', nil, UIParent)
	overlay:SetFrameStrata('FULLSCREEN_DIALOG')
	overlay:SetAllPoints(def.frame)
	overlay:EnableMouse(true)
	overlay:RegisterForClicks('LeftButtonUp')
	overlay:RegisterForDrag('LeftButton')
	overlay:Hide()
	st:SetBackdrop(overlay, 'theme', 'solid', 'small') -- colored by SetBorderColor

	local label = overlay:CreateFontString(nil, 'OVERLAY')
	label:SetFontObject(st:GetFont('pixel'))
	label:SetPoint('CENTER')
	label:SetText(def.label or key)

	mover.overlay = overlay
	mover.label = label

	overlay:SetScript('OnMouseDown', function() mover.dragged = false end)
	overlay:SetScript('OnDragStart', function() EM:StartDrag(mover) end)
	overlay:SetScript('OnDragStop', function() EM:StopDrag(mover) end)
	overlay:SetScript('OnClick', function()
		if mover.dragged then return end -- a drag, not a click
		if EM.selected == mover then
			-- Reopen /sui if it was closed since; if it's open, leave the user
			-- on whatever section they're in (e.g. Position).
			if not st.Config:GetWindow() then
				EM:ShowSettings(mover)
			end
		else
			EM:Select(mover) -- 'Selected' shows its settings
		end
	end)

	SetBorderColor(mover, false)
	self.movers[key] = mover
	self:StackMover(mover) -- its own frame levels, on top (picker.lua)
	if self.active then overlay:Show() end
	return mover
end

-- A theme recolor (or redraw) gives every drawn frame the theme's colors; the
-- overlays take their own back.
function EM:OnColorsChanged(group)
	if group ~= 'theme' then return end
	for _, mover in pairs(self.movers) do
		SetBorderColor(mover, mover == self.selected)
	end
end

-- Keyboard catcher: only exists while edit mode is active. Everything except
-- the keys we use propagates, so other keybinds keep working.
local keys = CreateFrame('Frame', nil, UIParent)
keys:Hide()

keys:SetScript('OnKeyDown', function(self, key)
	-- A focused edit box (e.g. a settings window field) gets typing, not us.
	if GetCurrentKeyBoardFocus() then
		if not InCombatLockdown() then
			self:SetPropagateKeyboardInput(true)
		end
		return
	end
	local mover = EM.selected
	local consumed = false
	if key == 'ESCAPE' then
		consumed = true
		if mover then
			EM:Select(nil)
		else
			EM:Deactivate()
		end
	elseif mover and ARROW_KEYS[key] then
		consumed = true
		EM:Nudge(mover, key, IsShiftKeyDown())
	end
	if not InCombatLockdown() then
		self:SetPropagateKeyboardInput(not consumed)
	end
end)

-- EnableKeyboard/Show aren't combat-restricted (only SetPropagateKeyboardInput is),
-- so this still closes the catcher when edit mode drops on entering combat.
function EM:UpdateKeyboard()
	keys:EnableKeyboard(self.active)
	keys:SetShown(self.active)
end
