local ADDON_NAME, st = ...

local function CreateAltBorder(frame)
	frame.altborder = {}

	frame.altborder.LEFT = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.LEFT:SetWidth(3)
	frame.altborder.LEFT:SetPoint('TOPLEFT', frame, 'TOPLEFT', -1, 1)
	frame.altborder.LEFT:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', -1, -1)
	frame.altborder.LEFT:SetTexture(st.BLANK_TEX)

	frame.altborder.RIGHT = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.RIGHT:SetWidth(3)
	frame.altborder.RIGHT:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 1, 1)
	frame.altborder.RIGHT:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 1, -1)
	frame.altborder.RIGHT:SetTexture(st.BLANK_TEX)
	
	frame.altborder.TOP = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.TOP:SetHeight(3)
	frame.altborder.TOP:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, 1)
	frame.altborder.TOP:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -1, 1)
	frame.altborder.TOP:SetTexture(st.BLANK_TEX)

	frame.altborder.BOTTOM = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.BOTTOM:SetHeight(3)
	frame.altborder.BOTTOM:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 1, -1)
	frame.altborder.BOTTOM:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -1, -1)
	frame.altborder.BOTTOM:SetTexture(st.BLANK_TEX)
end

function st:SetTemplate(frame, template)
	if not template or template == 'none' then
		frame:SetBackdrop(nil)
		for _,border in pairs(frame.altborder) do
			border:SetVertexColor(0, 0, 0, 0)
		end
		return
	end

	local config = st.config.profile.templates[template]
	assert(config, template .. ' template not found')

	if not frame.altborder then
		CreateAltBorder(frame)
	end
	
	for _,border in pairs(frame.altborder) do
		border:SetVertexColor(unpack(config.altbordercolor))
	end

	local inset = config.thick and 2 or 1
	frame:SetBackdrop({
		bgFile = st.BLANK_TEX,
		edgeFile = st.BLANK_TEX,
		edgeSize = 1,
		tile = false, tileSize = 0,
		insets = {
			left = inset,
			right = inset,
			top = inset,
			bottom = inset
		}
	})

	frame:SetBackdropColor(unpack(config.backdropcolor))
	frame:SetBackdropBorderColor(unpack(config.bordercolor))
end

function st:SetBackdrop(frame, template)
	if not template or template == 'none' then
		if frame.backdrop then frame.backdrop:SetBackdrop(nil) end
		return
	end
	
	local config = st.config.profile.templates[template]
	assert(config, template .. ' template not found')

	if not frame.backdrop then
		frame.backdrop = CreateFrame('frame', nil, frame)
		frame.backdrop:SetFrameLevel(min(0, frame:GetFrameLevel()-1))
	end

	local offset = config.thick and 2 or 1
	frame.backdrop:ClearAllPoints()
	frame.backdrop:SetPoint('TOPLEFT', -offset, offset)
	frame.backdrop:SetPoint('BOTTOMRIGHT', offset, -offset)
	
	st:SetTemplate(frame.backdrop, template)
end