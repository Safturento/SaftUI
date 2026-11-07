local st = SaftUI
local EM = st.EditModeFrames

local ARROW_KEYS = { UP = true, DOWN = true, LEFT = true, RIGHT = true }
local NUDGE = {
	UP = { 0, 1 }, DOWN = { 0, -1 }, LEFT = { -1, 0 }, RIGHT = { 1, 0 },
}
local LIVE_INTERVAL = 0.1 -- seconds between settings refreshes while dragging

local function SetBorderColor(mover, selected)
	local r, g, b = 1, 1, 1
	if selected then
		r, g, b = st.config.profile.colors.button.blue:GetRGB()
	end
	mover.overlay.backdrop:SetBackdropBorderColor(r, g, b, 1)
	for _, border in pairs(mover.overlay.backdrop.altborder or {}) do
		border:SetVertexColor(r, g, b, 1)
	end
end

-- The anchor the mover's frame is positioned with, taken from its stored position.
local function GetAnchor(mover)
	local pos = mover.def.getPosition()
	local point, relative, rel_point, x, y = st:UnpackPoint(pos)
	return point, st:ResolveFrame(relative) or UIParent, rel_point, x, y
end

local function ApplyOffsets(mover, x, y)
	local point, relative, rel_point = GetAnchor(mover)
	local frame = mover.def.frame
	frame:ClearAllPoints()
	frame:SetPoint(point, relative, rel_point, x, y)
end

function EM:StartDrag(mover)
	local _, _, _, x, y = GetAnchor(mover)
	local cx, cy = GetCursorPosition()
	local uiScale = UIParent:GetEffectiveScale()
	mover.drag = { cx = cx / uiScale, cy = cy / uiScale, x0 = x, y0 = y, x = x, y = y }
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
	local dx = (cx / uiScale - drag.cx) * ratio
	local dy = (cy / uiScale - drag.cy) * ratio
	drag.x = st:RoundToPixel(drag.x0 + dx, mover.def.frame)
	drag.y = st:RoundToPixel(drag.y0 + dy, mover.def.frame)
	ApplyOffsets(mover, drag.x, drag.y)

	-- Keep open settings windows showing the live x/y. Throttled: each
	-- refresh rebuilds their widgets. The drag's end commits as before.
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

function EM:Nudge(mover, key, big)
	local def = mover.def
	local pixel = st:GetPixelSize(def.frame)
	if not pixel then return end
	local step = st:RoundToPixel(pixel, def.frame) * (big and 10 or 1)
	local _, _, _, x, y = GetAnchor(mover)
	local dir = NUDGE[key]
	self:CommitPosition(mover, x + dir[1] * step, y + dir[2] * step)
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
	st:SetBackdrop(overlay, 'thick')
	-- keep the target frame visible through the overlay
	overlay.backdrop:SetBackdropColor(0, 0, 0, 0.3)

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
		EM:Select(mover)
	end)

	SetBorderColor(mover, false)
	self.movers[key] = mover
	if self.active then overlay:Show() end
	return mover
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
