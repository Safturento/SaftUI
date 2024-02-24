local st = SaftUI

local function CreateAltBorder(frame)
	frame.altborder = {}

	local offset = 1
	local width = 3

	frame.altborder.LEFT = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.LEFT:SetWidth(width)
	frame.altborder.LEFT:SetPoint('TOPLEFT', frame, 'TOPLEFT', -offset, offset)
	frame.altborder.LEFT:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', -offset, -offset)
	frame.altborder.LEFT:SetTexture(st.BLANK_TEX)

	frame.altborder.RIGHT = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.RIGHT:SetWidth(width)
	frame.altborder.RIGHT:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', offset, offset)
	frame.altborder.RIGHT:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', offset, -offset)
	frame.altborder.RIGHT:SetTexture(st.BLANK_TEX)

	frame.altborder.TOP = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.TOP:SetHeight(width)
	frame.altborder.TOP:SetPoint('TOPLEFT', frame, 'TOPLEFT', offset, offset)
	frame.altborder.TOP:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -offset, offset)
	frame.altborder.TOP:SetTexture(st.BLANK_TEX)

	frame.altborder.BOTTOM = frame:CreateTexture(nil, 'BACKGROUND')
	frame.altborder.BOTTOM:SetHeight(width)
	frame.altborder.BOTTOM:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', offset, -offset)
	frame.altborder.BOTTOM:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -offset, -offset)
	frame.altborder.BOTTOM:SetTexture(st.BLANK_TEX)
end

function st:SetTemplate(frame, template)
	if template == nil or template == 'none' or template == '' then
		frame:SetBackdrop(nil)
		if frame.outer_shadow then
			frame.outer_shadow:Hide()
		end
		if frame.altborder then
			for _,border in pairs(frame.altborder) do
				border:Hide()
			end
		end

		if self.template_cache and self.template_cache[frame] then
			self.template_cache[frame] = nil
		end

		return
	end


	local config = st.config.profile.templates[template]
	assert(config, template .. ' template not found')

	if not self.template_cache then self.template_cache = {} end
	if not self.template_cache[frame] then self.template_cache[frame] = template end

	if not frame.altborder then
		CreateAltBorder(frame)
	end

	if not frame.outer_shadow then
		frame.outer_shadow = st:CreateFrame('frame', nil, frame)
		frame.outer_shadow:SetPoint('TOPLEFT', -4, 4)
		frame.outer_shadow:SetPoint('BOTTOMRIGHT', 4, -4)
		frame.outer_shadow:SetBackdrop({edgeFile = st.textures.glow, edgeSize = 4})
	end
	frame.outer_shadow:Show()
	frame.outer_shadow:SetBackdropBorderColor(unpack(config.outer_shadow))

	for _,border in pairs(frame.altborder) do
		if config.border and config.thick then
			border:SetVertexColor(unpack(config.altbordercolor))
			border:Show()
		else
			border:Hide()
		end
	end

	local inset = not config.border and 0 or config.thick and 2 or 1
	if frame.SetBackdrop then
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
	end

	frame:SetBackdropColor(unpack(config.backdropcolor))
	if config.border then
		frame:SetBackdropBorderColor(unpack(config.bordercolor))
	else
		frame:SetBackdropBorderColor(0, 0, 0 ,0)
	end
end

function st:SetBackdrop(frame, template)
	if template == nil or template == 'none' or template == '' then
		if frame.backdrop then
			st:SetTemplate(frame.backdrop, 'none')
		end
		return
	end

	local config = st.config.profile.templates[template]
	assert(config, template .. ' template not found')

	if not frame.GetObjectType then return print('GetObjectType missing',debugstack()) end

	local is_texture = frame:GetObjectType() == 'Texture'

	local parent = is_texture and frame:GetParent() or frame

	if not frame.backdrop then
		frame.backdrop = st:CreateFrame('frame', nil, parent)
		frame.backdrop:SetFrameLevel(max(0, parent:GetFrameLevel()-1))
	end

	local offset = config.thick and 2 or 1
	-- explicitly define as true or false to ensure thick is only nil when st:SetBackdrop is never called
	frame.thick = config.thick and true or false
	frame.backdrop:ClearAllPoints()
	frame.backdrop:SetPoint('TOPLEFT', frame, 'TOPLEFT', -offset, offset)
	frame.backdrop:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', offset, -offset)

	frame.backdrop.template = template

	st:SetTemplate(frame.backdrop, template)
end


--Creates a dragable header for a frame
st.headers = {}
function st:CreateHeader(frame, title, close_button)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	local inset = st.config.profile.misc.clamp_inset
	frame:SetClampRectInsets(-inset, inset, inset, -inset)
	local frameName = frame:GetName()
	local header = st:CreateFrame('Button', frameName and frameName ..'_Header' or '', frame)
	header:SetFrameLevel(frame:GetFrameLevel()+2)
	st:SetTemplate(header, 'highlight')

	header:SetPoint('TOPLEFT')
	header:SetPoint('TOPRIGHT')

	header:EnableMouse(true)
	header:SetScript('OnMouseDown', function() frame:StartMoving() end)
	header:SetScript('OnMouseUp', function()
		frame:StopMovingOrSizing()
		frame:ClearAllPoints()
		-- We reposition the frame using a corner point to the nearest pixel to ensure pixel perfectness
		frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', frame:GetLeft(), frame:GetTop())
	end)

	if title then
		if type(title) == 'string' then
			frame.title = header:CreateFontString(nil, 'OVERLAY')
			frame.title:SetFontObject(GameFontWhiteSmall)
			frame.title:SetText(title)
		else
			frame.title = title
		end

		frame.title:SetFontObject(st:GetFont(st.config.profile.headers.font))
		frame.title:SetParent(header)
		frame.title:ClearAllPoints()
		frame.title:SetPoint('CENTER', header)
		frame.title:SetJustifyH('MIDDLE')
	end

	if close_button then frame.close_button = close_button end
	if frame.close_button then
		st:StripTextures(frame.close_button)
		st:SetBackdrop(frame.close_button, 'close')
		frame.close_button.backdrop:SetAllPoints()
		frame.close_button:ClearAllPoints()
		frame.close_button:SetFrameLevel(header:GetFrameLevel()+4)
		frame.close_button:SetPoint('TOPRIGHT', header, -10, 0)
		frame.close_button:SetSize(unpack(st.CLOSE_BUTTON_SIZE))
	end

	frame.header = header
	table.insert(st.headers, header)
	st:UpdateHeader(header)
	return header
end

function st:UpdateHeader(header)
	if not header then
		for header in self.headers do
			self:UpdateHeader(header)
		end
	end

	header:SetHeight(st.config.profile.headers.height)
	if header.title then
		header.title:SetFontObject(st:GetFont(st.config.profile.headers.font))
	end
end

function st:CreateFooter(frame)
	local footer = st:CreateFrame('Frame', nil, frame)
	footer:SetPoint('BOTTOMLEFT')
	footer:SetPoint('BOTTOMRIGHT')
	footer:SetHeight(st.config.profile.headers.height)
	st:SetTemplate(footer, 'highlight')
	frame.footer = footer
end

function st:CreateCloseButton(frame)
	local close = st:CreateFrame('Button', nil, frame)
	self:SetTemplate(close, 'close')
	close:SetPoint('TOPRIGHT', 0, 0)
	close:SetSize(unpack(self.CLOSE_BUTTON_SIZE))
	close:SetScript('OnClick', function() frame:Hide() end)

	frame.close = close_button
	return close
end

local ATLAS_COORDS = {
	['left-arrow']  		= { 0.00, 0.25, 0.00, 0.50 },
	['right-arrow'] 		= { 0.25, 0.50, 0.00, 0.50 },
	['up-arrow'] 			= { 0.50, 0.75, 0.00, 0.50 },
	['down-arrow'] 			= { 0.75, 1.00, 0.00, 0.50 },
	['left-arrow-thick']  	= { 0.00, 0.25, 0.50, 1.00 },
	['right-arrow-thick'] 	= { 0.25, 0.50, 0.50, 1.00 },
	['up-arrow-thick'] 		= { 0.50, 0.75, 0.50, 1.00 },
	['down-arrow-thick'] 	= { 0.75, 1.00, 0.50, 1.00 },
}

function st:SetTexture(texture, key)
	texture:SetTexture(st.textures.atlas)
	texture:SetTexCoord(unpack(ATLAS_COORDS[key]))
end

function st:CreateArrowButton(parent, direction)
	local ARROW_SIZE = 16
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(ARROW_SIZE, ARROW_SIZE)

	local normalTexture = button:CreateTexture()
	normalTexture:SetTexture(st.textures.atlas)
	normalTexture:SetDrawLayer('OVERLAY', 0)
	normalTexture:SetAllPoints()
	st:SetTexture(normalTexture, direction..'-arrow')
	button:SetNormalTexture(normalTexture)

	local hoverTexture = button:CreateTexture()
	hoverTexture:SetTexture(st.textures.atlas)
	hoverTexture:SetBlendMode('DISABLE')
	hoverTexture:SetVertexColor(1, 0, 0, 1)
	hoverTexture:SetAllPoints()
	st:SetTexture(hoverTexture, direction..'-arrow-thick')
	button:SetHighlightTexture(hoverTexture)

	return button
end

function st:CreateArrowCluster(parent)

	local cluster = CreateFrame('Frame', nil, parent)

	local left = st:CreateArrowButton(cluster, 'left')
	left:SetPoint('LEFT')
	cluster.left = left

	local right = st:CreateArrowButton(cluster, 'right')
	right:SetPoint('RIGHT')
	cluster.right = right

	local up = st:CreateArrowButton(cluster, 'up')
	up:SetPoint('TOP')
	cluster.up = up

	local down = st:CreateArrowButton(cluster, 'down')
	down:SetPoint('BOTTOM')
	cluster.down = down

	cluster:SetSize(48, 48)

	return cluster

end

function st:CreateFrame(frameType, frameName, parentFrame, templates, id)
	local templateString = "BackdropTemplate"
	if templates then templateString = templateString .. "," .. templates end
	return CreateFrame(frameType, frameName, parentFrame, templateString, id)
end

function st:CreatePanel(name, width, height)
	local panel = st:CreateFrame('Frame', 'SaftUI_Panel_'..name:gsub(' ', '_'), UIParent)
	self:SetBackdrop(panel, self.config.profile.panels.template)
	self:CreateHeader(panel, name, self:CreateCloseButton(panel))
	if width then st:SetWidth(panel, width) end
	if height then st:SetHeight(panel, height) end

	function panel:CreateArrowButton(...)
		return st:CreateArrowButton(self, ...)
	end

	return panel
end

--function st:CreateButton(name, parent, text, template)
--	local button = self:CreateFrame('Button', name and 'SaftUI_'..name or nil, parent)
--	button.text = self:CreateFontString(button, 'pixel', text)
--	button.text:SetAllPoints()
--	st:SetBackdrop(button, template or 'thick')
--
--	button.SetFont = function(font) button.text:SetFontObject(st:GetFont(font)) end
--	button.SetText = button.text.SetText
--
--	return button
--end

function st:CreateFontString(parent, font, text)
	local fontString = parent:CreateFontString(nil, 'OVERLAY')
	fontString:SetFontObject(st:GetFont(font or 'pixel'))
	if text then fontString:SetText(text) end
	return fontString
end