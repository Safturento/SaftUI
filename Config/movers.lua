local ADDON_NAME, st = ...

st.Movers = {}

local moving = false
local activeMover = nil

local function clearActiveMover()
	st.MoversWindow.title:SetText('Movers')
	if activeMover then activeMover:SetEnabled(true) end
end

local function setActiveMover(mover)
	clearActiveMover()
	mover:SetEnabled(false)
	st.MoversWindow.title:SetText('Movers: ' .. (mover.name:GetText() or ''))
	activeMover = mover
end

local function getOffset() return IsShiftKeyDown() and 10 or 1 end

function st:InitializeMovers()
	local window = st:CreatePanel('Movers', {250, 200})
	window:SetPoint('TOPLEFT', 20, 200)
	local arrows = st:CreateArrowCluster(window)
	arrows:SetPoint('TOPLEFT', 5, -25)
	arrows.left:SetScript('OnClick', function(self)
		local pos, frame, relPos, x, y = activeMover.frame:GetPoint()
		activeMover.frame:SetPoint( pos, frame, relPos, x - getOffset(), y)
	end)

	arrows.right:SetScript('OnClick', function(self)
		local pos, frame, relPos, x, y = activeMover.frame:GetPoint()
		activeMover.frame:SetPoint( pos, frame, relPos, x + getOffset(), y)
	end)

	arrows.up:SetScript('OnClick', function(self)
		local pos, frame, relPos, x, y = activeMover.frame:GetPoint()
		activeMover.frame:SetPoint( pos, frame, relPos, x, y + getOffset())
	end)

	arrows.down:SetScript('OnClick', function(self)
		local pos, frame, relPos, x, y = activeMover.frame:GetPoint()
		activeMover.frame:SetPoint( pos, frame, relPos, x, y - getOffset())
	end)

	window.arrows = arrows
	st.MoversWindow = window
end

--st.MoversWindow:Hide()

function st:GetMoving()
	return moving
end

function st:ToggleMovers()
	if moving then
		st:DisableMovers()
	else
		st:EnableMovers()
	end
end

function st:EnableMovers()
	if not st.MoversWindow then
		self:InitializeMovers()
	end

	for _, mover in pairs(st.Movers) do
		mover:Show()
	end
	moving = true
end

function st:DisableMovers()
	for _, mover in pairs(st.Movers) do
		mover:Hide()
	end
	moving = false
end

function st:RegisterMover(frame, callback, name)
	local mover = CreateFrame('Button', nil, UIParent)
	mover:SetAllPoints(frame)
	st:SetBackdrop(mover, st.config.profile.panels.template)
	mover:EnableMouse(true)
	frame:SetMovable(true)
	
	frame:SetClampedToScreen(true)
	local inset = st.config.profile.misc.clamp_inset
	frame:SetClampRectInsets(-inset, inset, inset, -inset)

	mover.name = mover:CreateFontString(nil, 'OVERLAY')
	mover.name:SetPoint('CENTER')
	mover.name:SetFontObject(GameFontNormal)
	mover.name:SetText(name or frame:GetName() or '')

	local normal_tex = mover:CreateTexture()
	normal_tex:SetTexture(st.BLANK_TEX)
	normal_tex:SetVertexColor(0, 0.6784*0.3, 0.9373*0.3, 0.9)
	normal_tex:SetAllPoints(mover)
	mover:SetNormalTexture(normal_tex)

	hover_tex = mover:CreateTexture()
	hover_tex:SetTexture(st.BLANK_TEX)
	hover_tex:SetVertexColor(0, 0.6784*0.6, 0.9373*0.6, 0.9)
	hover_tex:SetAllPoints(mover)
	mover:SetHighlightTexture(hover_tex)

	disable_tex = mover:CreateTexture()
	disable_tex:SetTexture(st.BLANK_TEX)
	disable_tex:SetVertexColor(0, 0.6784*0.9, 0.9373*0.9, 0.9)
	disable_tex:SetAllPoints(mover)
	mover:SetDisabledTexture(disable_tex)

	mover:SetFrameStrata('HIGH')

	mover:SetScript('OnMouseDown', function(self)
		setActiveMover(self)
		st.MoversWindow:Show()
		frame:StartMoving()
	end)
	mover:SetScript('OnMouseUp', function(self)
		frame:StopMovingOrSizing()
		callback(frame)
	end)

	mover:Hide()
	
	tinsert(self.Movers, mover)
	frame.mover = mover
	mover.frame = frame
end


















-- grid.lua
