local ADDON_NAME, st = ...

st.Movers = {}

local moving = false

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
	mover:SetFrameStrata('HIGH')

	mover:SetScript('OnMouseDown', function(self)
		frame:StartMoving()
	end)
	mover:SetScript('OnMouseUp', function(self)
		frame:StopMovingOrSizing()
		callback(frame)
	end)

	mover:Hide()
	
	tinsert(self.Movers, mover)
	frame.mover = mover
end