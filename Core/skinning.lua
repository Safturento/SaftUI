local ADDON_NAME, st = ...

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

function st:SkinScrollBar(bar, custom_width)
	local parent = bar:GetParent()
	local name = bar:GetName()

	local down_button = bar.ScrollDownButton or _G[name..'ScrollDownButton']
	local up_button = bar.ScrollUpButton or _G[name..'ScrollUpButton']

	if down_button then st:Kill(down_button) end
	if up_button then st:Kill(up_button) end

	if name then
		if _G[name..'Top'] then st:Kill(_G[name..'Top']) end
		if _G[name..'Bottom'] then st:Kill(_G[name..'Bottom']) end
	end

	st:StripTextures(bar)
	st:StripTextures(parent)

	local width = custom_width or 20

	local thumb = bar.ThumbTexture or _G[name..'ThumbTexture']
	thumb:SetTexture(nil)
	st:SetBackdrop(thumb, st.config.profile.panels.template)
	thumb:SetWidth(width)


	-- Standardized positioning for all scrollbars
	bar:ClearAllPoints()
	if inside then
		bar:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', 1, 0)
		bar:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', 1, 0)
	else
		bar:SetPoint('TOPLEFT', parent, 'TOPRIGHT', 0, 0)
		bar:SetPoint('BOTTOMLEFT', parent, 'BOTTOMRIGHT', 0, 0)
	end
	bar:SetWidth(width)

	bar.SetPoint = st.dummy
end

function st:SkinCheckButton(button)
	st:StripTextures(button)

	button:SetSize(12, 12)
	st:SetBackdrop(button, st.config.profile.panels.template)

	button:SetFrameLevel(button:GetFrameLevel()+1)

	local checked = button:CreateTexture(nil, 'OVERLAY')
	checked:SetTexture(st.BLANK_TEX)
	checked:SetVertexColor(unpack(st.config.profile.colors.button.hover))
	checked:SetAllPoints(button)
	button:SetCheckedTexture(checked)

	local hover = button:CreateTexture(nil, 'OVERLAY')
	hover:SetTexture(st.BLANK_TEX)
	hover:SetVertexColor(unpack(st.config.profile.colors.button.normal))
	hover:SetAllPoints(button)
	button:SetHighlightTexture(hover)

	local name = button:GetName()
	local text = button.Text or button.Label or name and _G[name..'Text']
	if text then
		text:SetFontObject(st:GetFont(st.config.profile.panels.font))
	end
end

function st:SkinIcon(icon, customTrim, anchorFrame)
	if anchorFrame then
		icon:SetAllPoints(anchorFrame)
		icon:SetSize(anchorFrame:GetSize())
	end

	if icon.SetTexCoord then
		local w, h = icon:GetSize()
		local scale
		local trim = customTrim or st.config.profile.misc.icon_trim
		if (w == 0) and (h == 0) then
			icon:SetTexCoord(trim, 1 - trim, trim, 1 - trim)
		elseif w > h then
			scale = (1 - h / w) / 2
			icon:SetTexCoord(trim, 1-trim, scale + trim, 1 - scale - trim)
		else
			scale = (1 - w / h) / 2
			icon:SetTexCoord(scale + trim, 1 - scale - trim, trim, 1 - trim)
		end
	else
		print('function SetTexCoord does not exist for', icon:GetName() or icon)
	end
end

function st.SkinActionButton(button, config)
	if not config then
		config = {
			font = st.config.profile.buttons.font,
			template = st.config.profile.buttons.template
		}
	end

	local name = button:GetName() or ''

	local icon = _G[name.."Icon"] or _G[name..'IconTexture'] or button.icon or button.Icon
	local count = _G[name.."Count"] or button.count or button.Count
	local flash = _G[name.."Flash"] or button.flash or button.Flash
	local hotkey = _G[name.."HotKey"] or button.hotkey or button.HotKey
	local border = _G[name.."Border"] or button.border or button.Border
	local normal = _G[name.."NormalTexture"] or button.NormalTexture
	local item_level = button.item_level
	local bg = _G[name..'FloatingBG']

	if button.Left then st:Kill(button.Left) end
	if button.Middle then st:Kill(button.Middle) end
	if button.Right then st:Kill(button.Right) end
	if button.Center then st:Kill(button.Center) end

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

		if count and type(count) == 'table' then
			count:ClearAllPoints()
			count:SetPoint('BOTTOMRIGHT', 2, 1)
			count:SetJustifyH('RIGHT')
			count:SetJustifyV('BOTTOM')
		end

		if item_level then
			item_level:ClearAllPoints()
			item_level:SetPoint('BOTTOMRIGHT', 2, 1)
			item_level:SetJustifyH('RIGHT')
			item_level:SetJustifyV('BOTTOM')
		end

		if hotkey then
			hotkey:ClearAllPoints()
			hotkey:SetPoint('TOPRIGHT')
			hotkey:SetPoint('TOPLEFT', 0, 2)
			hotkey:SetJustifyH('LEFT')
			hotkey:SetJustifyV('TOP')
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

function st:SkinEditBox(editbox, template, font)
	local name = editbox:GetName()
	template = template or 'thick'

	for _,region_name in pairs({'Left', 'Right', 'Middle', 'Mid', 'focusLeft', 'focusRight', 'focusMid'}) do
		local region = _G[name..region_name] or editbox[region_name]
		if region then
			st:Kill(region)
		end
	end


	if editbox.searchIcon then
		editbox.searchIcon:ClearAllPoints()
		editbox.searchIcon:SetPoint('LEFT', editbox, 5, -1)
	end

	if editbox.Instructions then
		editbox.Instructions:ClearAllPoints()
		editbox.Instructions:SetPoint('LEFT', editbox, 'LEFT', editbox.searchIcon and 20 or 5, 0)
		if font then
			editbox.Instructions:SetFontObject(st:GetFont(font))
		end
	end

	st:SetBackdrop(editbox, template)

	local text, _, _, _, header = editbox:GetRegions()
	if font then
		text:SetFontObject(st:GetFont(font or 'normal'))
		-- if header then
		-- 	header:SetFontObject(st:GetFont(font))
		-- end
	end

	editbox:HookScript('OnEditFocusGained', function(self)
		self.backdrop:SetBackdropBorderColor(1, 1, 1, 1)
		text:ClearAllPoints()
		text:SetPoint('LEFT', editbox, 'LEFT', editbox.searchIcon and 20 or 5, 0)
	end)

	editbox:HookScript('OnEditFocusLost', function(self)
		st:SetBackdrop(self, template)
	end)
end

function st:EnableHorizontalResizing(frame, ...)
	st:EnableResizing(frame, ...)
	frame.ResizeButton:SetScript()
end

function st:EnableResizing(frame, resizeButton, callback)
	if resizeButton then
		frame.ResizeButton = resizeButton
	else
		local resize = st:CreateFrame('Button', nil, frame)
		resize:SetScript('OnMouseDown', function(self) frame:StartSizing() end)
		resize:SetScript('OnMouseUp', function(self) frame:StopMovingOrSizing() end)
		resize:SetFrameStrata("HIGH")
		frame.ResizeButton = resize
	end

	frame:SetResizable(true)
	frame.ResizeButton:ClearAllPoints()
	st:SetSize(frame.ResizeButton, 16, 16)
	frame.ResizeButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

	frame.ResizeButton:SetNormalTexture(st.textures.cornerbr)

	frame.ResizeButton:SetPushedTexture(st.textures.cornerbr)
	frame.ResizeButton:GetPushedTexture():SetVertexColor(unpack(st.config.profile.colors.button.hover))

	frame.ResizeButton:SetHighlightTexture(st.textures.cornerbr)
	frame.ResizeButton:GetHighlightTexture():SetVertexColor(unpack(st.config.profile.colors.button.hover))
	frame.ResizeButton:GetHighlightTexture():SetBlendMode('BLEND')

	frame.ResizeButton:SetFrameLevel(4)
end