local st = SaftUI

--[[
	How SaftUI's options window (st.OptionsWindow, optionswindow.lua) grows
	taller: its grip and its bottom edge, the resize they start, and the
	height taken again when the screen edge margin changes. It loads after
	optionswindow.lua (Config/load.xml), which calls it through OW.S.
]]

local OW = st.OptionsWindow
local S = OW.S

local floor, max, min = math.floor, math.max, math.min

-- From optionslayout.lua and optionswindow.lua.
local Margins = S.Margins
local F, Schedule, SaveWindow = S.F, S.Schedule, S.SaveWindow
local SetScroll, SetNavScroll = S.SetScroll, S.SetNavScroll

------------------------------------------------------------------ growing taller

--[[
	The window grows taller by its grip (F.grip, the bottom right corner:
	Blizzard's PanelResizeButtonTemplate under Blizzard, st:EnableResizing's
	corner under Thick and Thin) or its bottom edge (F.sizer, the strip left of
	the grip). Its width and top stay (it is anchored by its top); the
	sidebar, the main column, the inner frame and the body take the height
	(their anchors), the footer staying at the bottom. Its height stays even, from the layout's least to the most
	(OW.MaxHeight), and stops where its bottom, or under Blizzard the metal
	under it, meets the screen edge margin (Margins).

	A press of the left button on either starts a resize; while it's held, the
	pressed handle's OnUpdate follows the cursor. Each new height re-places the
	body's and the sidebar's scroll bars (their offsets clamp to the new
	range; FollowHeight); nothing renders while the button is held (Busy), and
	a fill page (the Categories tab) draws its fill row again once it's let
	go. It ends on the button's release (OnMouseUp, or the handle's next frame
	finding it up) or the window hiding, and a height it changed is saved,
	with the window's corner. The window is anchored by its top right corner
	(optionswindow.lua), so a new height moves only the bottom. A change of
	the screen edge margin moves the most height, so the window takes its height again then (st:UpdateScreenMargin,
	hooked in Build; ApplyHeight).
]]
local GRIP_SIZE = 16 -- st:EnableResizing's, and PanelResizeButtonTemplate's
local EDGE_HEIGHT = 6
local HANDLE_LEVEL = 10 -- the grip and the edge, over the window's own frames

-- After the window's height changed: the sidebar's bar re-placed in its new
-- range, and the body's, except on a fill page, whose fill row was drawn to
-- the old height: re-placed now, the body's bar would show over the page's
-- own bars until the render that draws the row again (Schedule; in game the
-- body's OnSizeChanged schedules it too), which places it.
local function FollowHeight()
	if S.filledTo then Schedule() else SetScroll(S.scrollOffset) end
	SetNavScroll(S.navOffset)
end

-- The window's height again (OW.WindowHeight), from its current anchor, while
-- it shows and isn't being resized: for a change of the screen edge margin,
-- which moves OW.MaxHeight. The bar is always 42 tall: nothing for it.
local function ApplyHeight()
	if not (F.window and F.window:IsShown()) or S.sizing or S.size == 'mini' then return end
	local height = OW.WindowHeight(S.layout)
	if F.window:GetHeight() == height then return end
	F.window:SetHeight(height)
	FollowHeight()
end

local function StopResize()
	if not S.sizing then return end
	local resize = S.sizing
	S.sizing = nil
	resize.handle:SetScript('OnUpdate', nil)
	if resize.at == resize.height then return end
	-- The height, with the corner it has (a window never moved has none saved,
	-- and the next open would centre it again): the top stays where it was.
	SaveWindow({ height = resize.at, point = 'TOPRIGHT', x = S.corner.x, y = S.corner.y })
end

local function UpdateResize()
	if not IsMouseButtonDown('LeftButton') then return StopResize() end
	local window = F.window
	local _, y = GetCursorPosition()
	local _, below = Margins(S.layout)
	local most = min(OW.MaxHeight(), 2 * floor((S.sizing.top - below) / 2))
	local height = S.sizing.height + S.sizing.cursor - y / window:GetEffectiveScale()
	height = max(S.layout.height, min(most, 2 * floor(height / 2 + 0.5)))
	if height == S.sizing.at then return end
	S.sizing.at = height
	-- Anchored by its top right corner: the top stays, the bottom moves.
	window:SetHeight(height)
	FollowHeight()
end

-- From where the window shows (the game's clamp may have moved it from its
-- anchor): the cursor's y, the window's height and its top.
local function StartResize(handle, button)
	if button ~= 'LeftButton' or S.sizing then return end
	local window = F.window
	if not window:GetTop() then return end
	local _, y = GetCursorPosition()
	local height = floor(window:GetHeight() + 0.5)
	-- cursor and height at the press, at the height now, and the top.
	S.sizing = {
		handle = handle,
		cursor = y / window:GetEffectiveScale(),
		height = height, at = height,
		top = window:GetTop(),
	}
	handle:SetScript('OnUpdate', UpdateResize)
end

local function EndResize(_, button)
	if button == 'LeftButton' then StopResize() end
end

-- The grip and the edge, at the window's bottom, over its frames. The grip's
-- textures are dressed for the look by LookGrip.
local function BuildResize(window)
	local level = window:GetFrameLevel() + HANDLE_LEVEL
	local grip = CreateFrame('Button', nil, window)
	grip:SetSize(GRIP_SIZE, GRIP_SIZE)
	grip:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', 0, 0)
	grip:SetFrameLevel(level)
	grip.normal = grip:CreateTexture(nil, 'ARTWORK')
	grip.highlight = grip:CreateTexture(nil, st.ThemeArt.HOVER_LAYER)
	grip.pushed = grip:CreateTexture(nil, 'ARTWORK')
	for _, texture in ipairs({ grip.normal, grip.highlight, grip.pushed }) do texture:SetAllPoints(grip) end
	grip:SetNormalTexture(grip.normal)
	grip:SetHighlightTexture(grip.highlight)
	grip:SetPushedTexture(grip.pushed)

	local sizer = CreateFrame('Frame', nil, window)
	sizer:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 0, 0)
	sizer:SetPoint('BOTTOMRIGHT', grip, 'BOTTOMLEFT', 0, 0)
	sizer:SetHeight(EDGE_HEIGHT)
	sizer:SetFrameLevel(level)

	for _, handle in ipairs({ grip, sizer }) do
		handle:EnableMouse(true)
		handle:SetScript('OnMouseDown', StartResize)
		handle:SetScript('OnMouseUp', EndResize)
	end
	F.grip, F.sizer = grip, sizer
	-- A glyph, the pushed texture too: the game shows it instead of the normal one while held (after the scripts above): the corner is white, the lighter tone of the accent under
	-- the mouse or held; under Blizzard the game's own highlight and pushed art.
	st:AddStates(grip, 'glyph', {
		glyph = { grip.normal, grip.pushed }, glyphRest = function() return 1, 1, 1 end,
		blizzard = function() return S.blizzard == true end,
	})
end

-- The grip in the look: Blizzard's PanelResizeButtonTemplate
-- (st.ThemeArt.Control('resizegrip')), or st:EnableResizing's corner, whose own tint under the
-- mouse is the states helper's (its highlight and pushed textures stay clear).
local function LookGrip()
	local grip = F.grip
	local look = S.blizzard and st.ThemeArt.Control('resizegrip')
	grip.normal:SetVertexColor(1, 1, 1, 1)
	if look then
		grip:SetSize(look.size, look.size)
		grip.normal:SetTexture(look.normal)
		grip.highlight:SetTexture(look.highlight)
		grip.pushed:SetTexture(look.pushed)
		grip.highlight:SetVertexColor(1, 1, 1, 1)
		grip.pushed:SetVertexColor(1, 1, 1, 1)
		grip.highlight:SetBlendMode(look.highlightBlend)
		grip.highlight:SetAlpha(1)
		grip.pushed:SetAlpha(1)
	else
		grip:SetSize(GRIP_SIZE, GRIP_SIZE)
		for _, texture in ipairs({ grip.normal, grip.highlight, grip.pushed }) do texture:SetTexture(st.textures.cornerbr) end
		grip.highlight:SetBlendMode('BLEND')
		grip.highlight:SetAlpha(0)
		grip.pushed:SetAlpha(1) -- the game shows it in place of the normal corner while held: it is the corner too
	end
	st:RestyleStates(grip)
	st:PaintStates(grip) -- the rest color back on the corner
end

------------------------------------------------------------------ for optionswindow.lua

S.ApplyHeight, S.StopResize, S.BuildResize, S.LookGrip = ApplyHeight, StopResize, BuildResize, LookGrip
