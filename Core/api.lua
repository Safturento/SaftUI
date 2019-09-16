local ADDON_NAME, st = ...

function st:Kill(frame)
	if frame.UnregisterAllEvents then
		frame:UnregisterAllEvents()
		frame:SetParent(st.HiddenFrame)
	end
	frame._Show = frame.Show
	frame.Show = frame.Hide
	
	frame:Hide()
end

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
		if frame.altborder then
			for _,border in pairs(frame.altborder) do
				border:SetVertexColor(0, 0, 0, 0)
			end
		end
		return
	end

	local config = st.config.profile.templates[template]
	assert(config, template .. ' template not found')

	if not frame.altborder then
		CreateAltBorder(frame)
	end
	
	for _,border in pairs(frame.altborder) do
		if config.border then 
			border:SetVertexColor(unpack(config.altbordercolor))
		else
			border:SetVertexColor(0, 0, 0, 0)
		end
	end

	local inset = not config.border and 0 or config.thick and 2 or 1
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
	if config.border then
		frame:SetBackdropBorderColor(unpack(config.bordercolor))
	else
		frame:SetBackdropBorderColor(0, 0, 0 ,0)
	end
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
		frame.backdrop:SetFrameLevel(max(0, frame:GetFrameLevel()-1))
	end

	local offset = config.thick and 2 or 1
	frame.backdrop:ClearAllPoints()
	frame.backdrop:SetPoint('TOPLEFT', -offset, offset)
	frame.backdrop:SetPoint('BOTTOMRIGHT', offset, -offset)
	
	st:SetTemplate(frame.backdrop, template)
end

function st:StripTextures(frame, kill)
	if frame.SetNormalTexture    then frame:SetNormalTexture('')    end	
	if frame.SetHighlightTexture then frame:SetHighlightTexture('') end
	if frame.SetPushedTexture    then frame:SetPushedTexture('')    end	
	if frame.SetDisabledTexture  then frame:SetDisabledTexture('')  end	

	local name = frame.GetName and frame:GetName()
	if name then 
		if _G[name..'Left'] then _G[name..'Left']:SetAlpha(0) end
		if _G[name..'Middle'] then _G[name..'Middle']:SetAlpha(0) end
		if _G[name..'Right'] then _G[name..'Right']:SetAlpha(0) end	
	end

	if frame.Left then frame.Left:SetAlpha(0) end
	if frame.Right then frame.Right:SetAlpha(0) end	
	if frame.Middle then frame.Middle:SetAlpha(0) end

	for i=1, frame:GetNumRegions() do
		local region = select(i, frame:GetRegions())
		if region:GetObjectType() == 'Texture' then
			if kill then
				st:Kill(region)
			else
				region:SetTexture(nil)
			end
		end
	end	 
end

function st:SkinIcon(icon, customTrim, anchorFrame)
	if anchorFrame then
		icon:SetAllPoints(anchorFrame)
	end
	
	if icon.SetTexCoord then
		local trim = customTrim or st.config.profile.misc.icon_trim
		icon:SetTexCoord(trim, 1-trim, trim, 1-trim)
		icon.SetTexCoord = SaftUI.dummy
	else
		S:print('function SetTexCoord does not exist for',icon:GetName() or icon)
	end
end

function st.SkinActionButton(button, config)
	local name = button:GetName()

	local icon = _G[name.."Icon"] or button.icon or button.Icon
	local count = _G[name.."Count"] or button.count or button.Count
	local flash = _G[name.."Flash"] or button.flash or button.Flash
	local hotkey = _G[name.."HotKey"] or button.hotkey or button.HotKey
	local border = _G[name.."Border"] or button.border or button.Border
	local normal = _G[name.."NormalTexture"] or button.NormalTexture
	local bg = _G[name..'FloatingBG']

	if bg then
		bg:SetTexture(nil)
	end

	if flash then
		flash:SetTexture('')
	end

	if icon then
		st:SkinIcon(icon)
	end

	if config.font then
		local font_object = st:GetFont(config.font)
		
		for _,region in pairs({button:GetRegions()}) do
			if region:GetObjectType() == 'FontString' then
				region:SetFontObject(font_object)
			end
		end

		if button.SetNormalFontObject then
			button:SetNormalFontObject(font_object)
			button:SetHighlightFontObject(font_object)
			button:SetDisabledFontObject(font_object)
			button:SetPushedTextOffset(0, 0)
		end
	end

	if button.SetNormalTexture then
		button:SetNormalTexture('')
	end

	if button.SetHighlightTexture and not button.hover then
		local hover = button:CreateTexture(nil, 'OVERLAY')
		hover:SetTexture(st.BLANK_TEX)
		-- hover:SetVertexColor(1, 1, 1, .1)
		hover:SetVertexColor(unpack(st.config.profile.colors.button.blue))
		hover:SetAllPoints(button)
		button.hover = hover
		button:SetHighlightTexture(hover)
	end

	if button.SetPushedTexture and not button.pushed then
		local pushed = button:CreateTexture(nil, 'OVERLAY')
		pushed:SetTexture(st.BLANK_TEX)
		pushed:SetVertexColor(0, 0, 0, .1)
		pushed:SetAllPoints(button)
		button.pushed = pushed
		button:SetPushedTexture(pushed)
	end

	if button.SetDisabledTexture and not button.disabled then
		local disabled = button:CreateTexture(nil, 'OVERLAY')
		disabled:SetTexture(st.BLANK_TEX)
		disabled:SetVertexColor(0, 0, 0, .4)
		disabled:SetAllPoints(button)
		button.disabled = disabled
		button:SetDisabledTexture(disabled)
	end

	if config and config.template then
		st:SetBackdrop(button, config.template)
	end
end

function st:SkinEditBox(editbox, template, font, height, width)
	local name = editbox:GetName()

	if name then
		if _G[name..'Left'] then st:Kill(_G[name..'Left']) end
		if _G[name..'Middle'] then st:Kill(_G[name..'Middle']) end
		if _G[name..'Right'] then st:Kill(_G[name..'Right']) end
		if _G[name..'Mid'] then st:Kill(_G[name..'Mid']) end
	end

	st:SetTemplate(editbox, template)

	editbox:SetAutoFocus(false)
	
	-- Get the highlight and blinking pointer textures to modify them a bit
	local fontstring, highlight, _, _, pointer, header = editbox:GetRegions()

	if font then
		fontstring:SetFontObject(st:GetFont(font))
		header:SetFontObject(st:GetFont(font))
	end
	editbox.highlight = highlight
	editbox.pointer = pointer

	editbox.highlight:SetTexture(st.BLANK_TEX)
	editbox.highlight:SetVertexColor(1,1,1, 0.3)

	editbox:HookScript('OnEditFocusGained', function(self)
		self.pointer:SetWidth(1)
	end)

	editbox:HookScript('OnEnterPressed',  function(self) self:ClearFocus() end)
	editbox:HookScript('OnEscapePressed', function(self) self:ClearFocus() end)
	editbox:HookScript('OnEditFocusGained', function(self) self:HighlightText() end)
	editbox:HookScript('OnEditFocusLost', function(self) self:HighlightText(0,0) end)

	editbox:SetHeight(height or 20)
	if width then editbox:SetWidth(width) end
end

--Creates a dragable header for a frame
st.headers = {}

function st:CreateHeader(frame, title, closeButton)
	frame:SetMovable(true)

	local header = CreateFrame('Button', '', frame)
	header:SetFrameLevel(frame:GetFrameLevel()+2)
	st:SetTemplate(header, 'highlight')

	header:SetPoint('TOPLEFT')
	header:SetPoint('TOPRIGHT')

	header:EnableMouse(true)
	header:SetScript('OnMouseDown', function() frame:StartMoving() end)
	header:SetScript('OnMouseUp', function()
		frame:StopMovingOrSizing()
		local anchor, frame, relAnchor, x, y = frame:GetPoint()
		frame:SetPoint(anchor, frame, relAnchor, math.floor(x + 0.5), math.floor(y + 0.5) )
	end)

	if title then
		if type(title) == 'string' then
			frame.title = header:CreateFontString(nil, 'OVERLAY')
			frame.title:SetFontObject(st:GetFont(st.config.profile.headers.font))
			frame.title:SetText(title)
		else
			frame.title = title
		end

		frame.title:SetParent(header)
		frame.title:ClearAllPoints()
		frame.title:SetPoint('CENTER', header)
		frame.title:SetJustifyH('MIDDLE')
	end
	
	if closeButton then frame.close = close_button end
	if frame.close then
		st:SetTemplate(frame.close, 'close')
		frame.close:ClearAllPoints()
		frame.close:SetFrameLevel(header:GetFrameLevel()+4)
		frame.close:SetPoint('TOPRIGHT', header, -10, 0)
		frame.close:SetSize(unpack(st.CLOSE_BUTTON_SIZE))
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
	local footer = CreateFrame('Frame', nil, frame)
	footer:SetPoint('BOTTOMLEFT')
	footer:SetPoint('BOTTOMRIGHT')
	footer:SetHeight(st.config.profile.headers.height)
	st:SetTemplate(footer, 'highlight')
	frame.footer = footer
end

function st:CreateCloseButton(frame)
	local close = CreateFrame('Button', nil, frame)
	st:SetTemplate(close, 'close')
	close:SetPoint('TOPRIGHT', 0, 0)
	close:SetSize(unpack(st.CLOSE_BUTTON_SIZE))
	close:SetScript('OnClick', function() frame:Hide() end)

	frame.close = close
	return close
end

function st:EnableMoving(frame)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:HookScript('OnMouseDown', function(frame) frame:StartMoving() end)
	frame:HookScript('OnMouseUp', function(frame) frame:StopMovingOrSizing() end)
end