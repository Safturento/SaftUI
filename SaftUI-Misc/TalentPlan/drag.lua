local st = SaftUI
local TP = st:GetModule('TalentPlan')

local floor, ceil = math.floor, math.ceil

--[[
	TP.DragParts: what the panel's rows and phase headers drag with, a copy of
	SaftUI-Bags/dragparts.lua (Misc can't depend on Bags; a followup moves both
	copies to Core), with its text from st:CreateFontString instead of the
	options window's.
	  Muted()                          Text > Muted's r, g, b
	  Text(parent)                     a font string that doesn't wrap
	  TextWidth(fs)                    its whole text's width, rounded up
	  HANDLE_WIDTH, Handle(parent, height)
	                                   a drag handle: 6 Muted dots, two across
	                                   and three down, 2 apart
	  InView(frame)                    the cursor is inside every scroll frame
	                                   frame is drawn in
	  UnderCursor(rows) -> i, lower    the row (a record with .frame) under the
	                                   cursor, and whether it's in its lower
	                                   half; none while the cursor is out of the
	                                   rows' view
	  ShowGhost(w, label, height)      shows w.ghost (made once, in SaftUI's
	                                   theme) with label, colors w.insert in the
	                                   accent and runs w.drawDrag on w.frame's
	                                   OnUpdate
	  PlaceGhost(ghost)                the ghost by the cursor
	  StopDrag(w)                      no w.drag, no OnUpdate, the ghost and
	                                   w.insert hidden
	A widget that drags has w.frame, w.insert (its insertion line), w.drawDrag
	and w.drag while it drags.
]]
local D = {}
TP.DragParts = D

D.HANDLE_WIDTH = 10

function D.Muted() return st:Color('text', 'muted'):GetRGB() end

function D.Text(parent)
	local fs = st:CreateFontString(parent, 'normal')
	fs:SetJustifyH('LEFT')
	fs:SetWordWrap(false)
	return fs
end

function D.TextWidth(fs) return ceil(fs:GetUnboundedStringWidth()) end

function D.Handle(parent, height)
	local handle = CreateFrame('Button', nil, parent)
	handle:SetSize(D.HANDLE_WIDTH, height)
	handle.dots = {}
	for row = 0, 2 do
		for col = 0, 1 do
			local dot = handle:CreateTexture(nil, 'OVERLAY')
			dot:SetColorTexture(D.Muted())
			dot:SetSize(2, 2)
			dot:SetPoint('TOPLEFT', handle, 'TOPLEFT', 2 + col * 4, -(6 + row * 4))
			handle.dots[#handle.dots + 1] = dot
		end
	end
	return handle
end

-- IsMouseOver is a rectangle test: it doesn't know a scroll frame cuts off
-- what's scrolled out of it.
function D.InView(frame)
	local parent = frame:GetParent()
	while parent do
		if parent:IsObjectType('ScrollFrame') and not parent:IsMouseOver() then return false end
		parent = parent:GetParent()
	end
	return true
end

function D.UnderCursor(rows)
	if not (rows[1] and D.InView(rows[1].frame)) then return end
	for i, record in ipairs(rows) do
		local f = record.frame
		if f:IsMouseOver() then
			local _, y = GetCursorPosition()
			local _, middle = f:GetCenter()
			return i, y / f:GetEffectiveScale() < middle
		end
	end
end

function D.ShowGhost(w, label, height)
	local ghost = w.ghost
	if not ghost then
		ghost = st:CreateFrame('Frame', nil, w.frame)
		ghost:SetFrameStrata('TOOLTIP')
		ghost:SetHeight(height)
		ghost:EnableMouse(false)
		ghost.text = D.Text(ghost)
		ghost.text:SetPoint('LEFT', ghost, 'LEFT', 8, 0)
		w.ghost = ghost
	end
	st:SetBackdrop(ghost, 'theme', 'solid', 'small')
	ghost.text:SetText(label)
	ghost:SetWidth(D.TextWidth(ghost.text) + 16)
	ghost:Show()
	w.insert:SetColorTexture(st:Color('accent'):GetRGB())
	w.frame:SetScript('OnUpdate', w.drawDrag)
	return ghost
end

function D.PlaceGhost(ghost)
	local x, y = GetCursorPosition()
	local scale = ghost:GetEffectiveScale()
	ghost:ClearAllPoints()
	ghost:SetPoint('LEFT', UIParent, 'BOTTOMLEFT', floor(x / scale) + 12, floor(y / scale))
end

function D.StopDrag(w)
	w.drag = nil
	w.frame:SetScript('OnUpdate', nil)
	if w.ghost then w.ghost:Hide() end
	w.insert:Hide()
end
