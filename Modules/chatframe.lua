local st = SaftUI
local CHT = st:NewModule('Chat', 'AceHook-3.0', 'AceEvent-3.0')

-------------------------------------
-- IMPROVED CHAT SCROLLING ----------
-------------------------------------
-- No modifier 		- scrolls 3 lines at a time
-- Alt 				- scrolls 1 line at a time
-- Shift 			- scrolls a page at a time
-- Ctrl 			- scrolls all the way up or down

local numlines = 3
function FloatingChatFrame_OnMouseScroll(self, delta)
	if delta < 0 then
		if IsControlKeyDown() then
			self:ScrollToBottom()
		elseif IsShiftKeyDown() then
			self:PageDown()
		elseif IsAltKeyDown() then
			self:ScrollDown()
		else
			for i=1, numlines do
				self:ScrollDown()
			end
		end
	elseif delta > 0 then
		if IsControlKeyDown() then
			self:ScrollToTop()
		elseif IsShiftKeyDown() then
			self:PageUp()
		elseif IsAltKeyDown() then
			self:ScrollUp()
		else
			for i=1, numlines do
				self:ScrollUp()
			end
		end
	end
end

function CHT:ChatFrame_OnUpdate(frame)
	local frametop = frame:GetTop()

	local prev
	for i,region in pairs({frame:GetRegions()}) do
		if region:GetObjectType() == 'FontString' and not region:GetName() then
			if not region.handled then
				region:ClearAllPoints()
				region:SetSpacing(self.config.linespacing)
				if prev then 
					region:SetPoint('BOTTOMLEFT', prev, 'TOPLEFT', 0, self.config.linespacing)
				else
					region:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, self.config.linespacing)
				end

				region.handled = true
			end
				
			if region:GetTop() and region:GetTop() > frametop-self.config.linespacing then region:Hide() else region:Show() end
			prev = region

		end
	end

	local font, size, outline = st:GetFont(self.config.font):GetFont()
	frame:SetFont(font, self.config.fontsize, outline)
	frame:SetShadowOffset(0,0)
end

function CHT:SkinChatFrame(frame)
	local name = frame:GetName()
	st:StripTextures(frame)
	st:SetBackdrop(frame, self.config.template)
	frame:SetMinResize(170, 40)
	frame:SetMaxResize(1000, 1000)
	frame:SetBackdropBorderColor(0, 0, 0, 0)
	frame:SetFading(false)
	frame:SetClampRectInsets(0,0,0,0)

	local font, size, outline = st:GetFont(self.config.font):GetFont()
	frame:SetFont(font, self.config.fontsize, outline)
	frame:SetShadowOffset(0,0)

	frame.EditBox = _G[name..'EditBox']
	frame.EditBox.Header = _G[name..'EditBoxHeader']
	frame.EditBox.HeaderSuffix = _G[name..'EditBoxHeaderSuffix']

	frame.EditBox:SetHeight(self.config.editbox.height)
	frame.EditBox:SetFrameLevel(frame:GetFrameLevel()+2)
	frame.EditBox:SetAltArrowKeyMode(false)
	st:SkinEditBox(frame.EditBox, self.config.template, self.config.font)
	frame.EditBox:ClearAllPoints()
	frame.EditBox:SetPoint('BOTTOMLEFT', frame.backdrop, 'TOPLEFT', 0, 1)
	frame.EditBox:SetPoint('BOTTOMRIGHT', frame.backdrop, 'TOPRIGHT', 0, 1)
	frame.EditBox:SetScript('OnShow', function() GeneralDockManager:Hide() end)
	frame.EditBox:SetScript('OnHide', function() GeneralDockManager:Show() end)

	st:Kill(_G[name..'ButtonFrame'])
	st:Kill(frame.ScrollToBottomButton)

	frame.Tab = _G[name..'Tab']
	frame.Tab.Text = _G[name..'TabText']

	st:StripTextures(frame.Tab)
	frame.Tab:SetHeight(self.config.tabs.height)
	frame.Tab.Text:ClearAllPoints()
	frame.Tab.Text:SetPoint('CENTER')
	frame.Tab.Text:SetFont(st:GetFont(self.config.font):GetFont())
	frame.Tab.Text:SetShadowOffset(0, 0)

	if not self.config.tabs.fade then
		frame.Tab:SetAlpha(1)
		frame.Tab.SetAlpha = UIFrameFadeRemoveFrame
	end

	frame.ResizeButton = _G[name..'ResizeButton']
	frame.ResizeButton:ClearAllPoints()
	frame.ResizeButton:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

	frame.ResizeButton:SetNormalTexture(st.textures.cornerbr)
	
	frame.ResizeButton:SetPushedTexture(st.textures.cornerbr)
	frame.ResizeButton:GetPushedTexture():SetVertexColor(unpack(st.config.profile.colors.button.hover))

	frame.ResizeButton:SetHighlightTexture(st.textures.cornerbr)
	frame.ResizeButton:GetHighlightTexture():SetVertexColor(unpack(st.config.profile.colors.button.hover))
	frame.ResizeButton:GetHighlightTexture():SetBlendMode('BLEND')

	frame.ResizeButton:SetFrameStrata('LOW')
	frame.ResizeButton:SetFrameLevel(4)

	self:UpdateChatFrameDisplay(frame)
end

function CHT:UpdateChatFrameDisplay(frame)
	st:SetBackdrop(frame, self.config.template)

	local offset = 0
	if frame.CombatLogQuickButtonFrame then
		offset = frame.CombatLogQuickButtonFrame:GetHeight()
	end
	frame.backdrop:ClearAllPoints()
	frame.backdrop:SetPoint('TOPLEFT', -self.config.padding, self.config.padding + offset)
	frame.backdrop:SetPoint('BOTTOMRIGHT', self.config.padding, -self.config.padding)
	
	st:SetBackdrop(frame.Tab, self.config.tmeplate)
end

-------------------------------------
-- INITIALIZATION -------------------
-------------------------------------

function CHT:OnEnable()
	self.config =  st.config.profile.chat

	-- Kill stuff
	st:Kill(ChatConfigFrameDefaultButton)
	st:Kill(ChatFrameMenuButton)
	st:Kill(ChatFrameChannelButton)


	ChatFrame1:ClearAllPoints()
	ChatFrame1:SetPoint(unpack(self.config.position))

	for chatID=1, NUM_CHAT_WINDOWS do
		self:SkinChatFrame(_G['ChatFrame'..chatID])
	end

	-- self:SecureHook('FCFDock_UpdateTabs')
	-- self:SecureHook('ChatEdit_UpdateHeader')
	self:SecureHook('ChatFrame_OnUpdate')
	self:SecureHook('FloatingChatFrame_UpdateBackgroundAnchors', 'UpdateChatFrameDisplay')
end