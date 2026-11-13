local st = SaftUI
local INV = st:GetModule('Inventory')

local W = st.OptionsWidgets

local floor, ceil = math.floor, math.ceil

-- The drag handle's width, which the rule editor lays its rows out by too.
local HANDLE_WIDTH = 10

--[[
	INV.DragParts: what the rule editor (ruleeditor.lua) and the Categories
	tab (categoriestab.lua), which load after this file, both draw and drag with.
	  Colors(), Grey()                the profile's colors; grey text's r, g, b
	  Text(parent, font, justify)     a font string that doesn't wrap (the
	                                  options window's field font by default)
	  TextWidth(fs)                   its whole text's width, rounded up
	  Inside(frame, ancestor)         frame is ancestor or inside it
	  HANDLE_WIDTH, Handle(parent, height)
	                                  a drag handle: 6 grey dots, two across
	                                  and three down, 2 apart
	  InView(frame)                   the cursor is inside every scroll frame
	                                  frame is drawn in (the window's body, the
	                                  Categories tab's list and editor)
	  UnderCursor(rows) -> i, lower   the row (a record with .frame) under the
	                                  cursor, and whether it's in its lower
	                                  half; none while the cursor is out of the
	                                  rows' view, where a row scrolled out of
	                                  it would still be under it by IsMouseOver
	  ShowGhost(w, label, height)     shows w.ghost (made once, drawn in
	                                  SaftUI's theme) with label, colors
	                                  w.insert blue and runs w.drawDrag on
	                                  w.frame's OnUpdate
	  PlaceGhost(ghost)               the ghost by the cursor
	  StopDrag(w)                     no w.drag, no OnUpdate, the ghost and
	                                  w.insert hidden
	A widget that drags has w.frame, w.insert (its insertion line), w.drawDrag
	and w.drag while it drags.
]]
local D = {}
INV.DragParts = D

function D.Colors() return st.config.profile.colors end
function D.Grey() return D.Colors().text.grey:GetRGB() end

function D.Text(parent, font, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(font or W.GetFont())
	fs:SetJustifyH(justify or 'LEFT')
	fs:SetWordWrap(false)
	return fs
end

function D.TextWidth(fs) return ceil(fs:GetUnboundedStringWidth()) end

function D.Inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

D.HANDLE_WIDTH = HANDLE_WIDTH

function D.Handle(parent, height)
	local handle = CreateFrame('Button', nil, parent)
	handle:SetSize(D.HANDLE_WIDTH, height)
	for row = 0, 2 do
		for col = 0, 1 do
			local dot = handle:CreateTexture(nil, 'OVERLAY')
			dot:SetColorTexture(D.Grey())
			dot:SetSize(2, 2)
			dot:SetPoint('TOPLEFT', handle, 'TOPLEFT', 2 + col * 4, -(6 + row * 4))
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

-- The rows share their scroll frames, so the first one's view is theirs.
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
	w.insert:SetColorTexture(D.Colors().button.blue:GetRGB())
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
