local st = SaftUI
local CHT = st:NewModule('Chat')

-------------------------------------
-- IMPROVED CHAT SCROLLING ----------
-------------------------------------
-- No modifier 		- scrolls 3 lines at a time
-- Alt 				- scrolls 1 line at a time
-- Shift 			- scrolls a page at a time
-- Ctrl 			- scrolls all the way up or down

local numlines = 3
local function onMouseScroll(self, delta)
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

	st:Kill(_G[frame:GetName()..'Background'])
	st:Kill(_G[frame:GetName()..'RightTexture'])

	if st.retail then
		st:SkinScrollBar(frame.ScrollBar)
		frame.ScrollBar:ClearAllPoints()
		frame.ScrollBar:SetPoint('TOPLEFT', frame.backdrop, 'TOPRIGHT', 5, 0)
		frame.ScrollBar:SetPoint('BOTTOMLEFT', frame.backdrop, 'BOTTOMRIGHT', 5, 0)
	end

	frame:SetScript('OnMouseWheel', onMouseScroll)
	
-- 	frame:SetMinResize(170, 40)
-- 	frame:SetMaxResize(1000, 1000)
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
	st:StripTextures(frame.Tab)
	frame.Tab:SetNormalFontObject(st:GetFont('pixel'))
	frame.Tab:SetDisabledFontObject(st:GetFont('pixel'))
	frame.Tab.Text:SetPoint("CENTER", 0, 2)

	if not self.config.tabs.fade then
		frame.Tab:SetAlpha(1)
		frame.Tab.SetAlpha = UIFrameFadeRemoveFrame
	end

	self:UpdateChatFrameDisplay(frame)
end

function CHT:UpdateChatFrameDisplay(frame)
	st:SetBackdrop(frame, self.config.template)

	local offset = 0
	if frame.CombatLogQuickButtonFrame then
		offset = frame.CombatLogQuickButtonFrame:GetHeight()
	end
	-- No backdrop is made while the template is 'none'.
	if frame.backdrop then
		frame.backdrop:ClearAllPoints()
		frame.backdrop:SetPoint('TOPLEFT', -self.config.padding, self.config.padding + offset)
		frame.backdrop:SetPoint('BOTTOMRIGHT', self.config.padding, -self.config.padding)
	end

	if frame == ChatFrame1 then
		self:UpdateFootprint()
	end

	st:SetBackdrop(frame.Tab, self.config.tmeplate)
end

-- Applies the profile's font, font size, template, padding and edit box
-- height to a chat frame SkinChatFrame already skinned.
function CHT:ApplyChatFrameConfig(frame)
	local font, _, outline = st:GetFont(self.config.font):GetFont()
	frame:SetFont(font, self.config.fontsize, outline)
	frame:SetShadowOffset(0, 0)

	local editbox = _G[frame:GetName()..'EditBox']
	if editbox then
		editbox:SetHeight(self.config.editbox.height)
		st:StyleEditBox(editbox, self.config.template, self.config.font)
	end

	self:UpdateChatFrameDisplay(frame)
end

--[[
	ChatFrame1 is a Blizzard Edit Mode system on retail and Forever alike
	(EditModeChatFrameSystemTemplate). Blizzard re-applies its Edit Mode position on every
	layout load or change (EditModeSystemMixin:ApplySystemAnchor: ClearAllPoints, then
	SetPoint with the layout's anchor). Both are Lua overrides installed by
	EditModeSystemMixin:OnSystemLoad, and SetPointOverride writes
	EditModeManagerFrame.editModeSystemAnchorDirty, so addon code never calls them on
	ChatFrame1. st:ClearAllPointsDirect and st:SetPointDirect run the widget API's own
	methods instead.

	SaftUI's edit mode moves a holder frame, not ChatFrame1 (a drag calls the mover frame's
	ClearAllPoints and SetPoint). The holder is a plain SaftUI frame the same size as
	ChatFrame1 (a post-hook on ChatFrame1's OnSizeChanged copies the size), anchored from
	chat.position. ChatFrame1 gets the same single anchor as the holder, so the two cover
	the same rectangle. Whenever the holder's SetPoint runs (the profile, the Position
	section, a drag or a nudge), a post-hook copies its anchor to ChatFrame1.

	Post-hooks on ChatFrame1's own ClearAllPoints and SetPoint put the holder's anchor
	back straight after each Blizzard layout apply. They re-anchor ChatFrame1 with the
	direct helpers only, which skip those hooks, so they can't loop. Blizzard's size is
	left alone: its Width and Height settings and the resize handle still size ChatFrame1,
	and the holder follows.

	Blizzard's Edit Mode box on ChatFrame1 is kept hidden (HookScript only), so Blizzard's
	Edit Mode can't select or drag it. Nothing is written onto ChatFrame1 or any other
	Blizzard table here.
]]

local OLD_POSITION_KEYS = { 'point', 'frame', 'rel_point', 'x_off', 'y_off' }

-- Profiles saved before the chat frame became a mover keep chat.position as an array
-- ({ point, frame, rel_point, x, y }, SetPoint's argument order). Converts one to the
-- { point, frame, rel_point, x_off, y_off } shape in place, with the saved values, so
-- the chat frame doesn't move. The array entries are cleared.
function CHT:MigratePosition()
	local position = self.config and self.config.position
	if not position or position[1] == nil then return end

	for i, key in ipairs(OLD_POSITION_KEYS) do
		local value = position[i]
		if value == nil and i >= 4 then
			value = 0 -- SetPoint(point, frame, rel_point) means no offset
		end
		if value ~= nil then
			position[key] = value
		end
		position[i] = nil
	end
end

-- Anchors ChatFrame1 where the holder is. In combat it can't move if a protected frame
-- (e.g. a unit frame) is anchored to it; then this waits for the end of combat and
-- reads the holder's anchor when it runs.
function CHT:PlaceChatFrame()
	st:SafeReposition(ChatFrame1, 'chat', function()
		local point, relative, rel_point, x, y = self.holder:GetPoint(1)
		if not point then return end -- the holder is between ClearAllPoints and SetPoint
		st:ClearAllPointsDirect(ChatFrame1)
		st:SetPointDirect(ChatFrame1, point, relative, rel_point, x, y)
	end)
end

-- Places the holder from chat.position; ChatFrame1 follows (see PlaceChatFrame).
function CHT:ApplyPosition()
	local holder = self.holder
	if not holder then return end

	st:SafeReposition(holder, 'chat_holder', function()
		local point, relative, rel_point, x, y = st:UnpackPoint(self.config.position)
		holder:ClearAllPoints()
		holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point,
			st:RoundToPixel(x, holder), st:RoundToPixel(y, holder))
	end)
end

-- Makes the mover's outline cover what shows of the chat frame: ChatFrame1 plus the
-- padding SaftUI's backdrop extends past it. The outline is SaftUI's own frame, so
-- this is safe in combat.
function CHT:UpdateFootprint()
	local mover = self.mover
	if not mover then return end

	local padding = self.config.padding
	local overlay = mover.overlay
	overlay:ClearAllPoints()
	overlay:SetPoint('TOPLEFT', ChatFrame1, 'TOPLEFT', -padding, padding)
	overlay:SetPoint('BOTTOMRIGHT', ChatFrame1, 'BOTTOMRIGHT', padding, -padding)
end

-- Font, template, padding and edit box height of every chat frame.
function CHT:ApplyAppearance()
	for chatID=1, NUM_CHAT_WINDOWS do
		self:ApplyChatFrameConfig(_G['ChatFrame'..chatID])
	end
end

-- A profile change: chat position, then each chat frame's look. Tab fading
-- (tabs.fade) is only applied when the frames are first skinned.
function CHT:UpdateConfig()
	if not self.config then return end -- not enabled

	self:MigratePosition()
	self:ApplyPosition()
	self:ApplyAppearance()
end

-- Keeps the holder the size of ChatFrame1, and puts the holder's anchor back on
-- ChatFrame1 after anything Blizzard does to its position.
function CHT:TakeOverChatFrame()
	local holder = self.holder

	local function CopySize()
		local width, height = ChatFrame1:GetSize()
		if width and height then
			holder:SetSize(width, height)
		end
	end
	ChatFrame1:HookScript('OnSizeChanged', CopySize)
	CopySize()

	-- Every SaftUI placement of the holder, and a mover drag (which calls SetPoint on
	-- it), is copied to ChatFrame1. ClearAllPoints needs no hook: SetPoint follows it.
	hooksecurefunc(holder, 'SetPoint', function() self:PlaceChatFrame() end)

	-- Blizzard's Edit Mode applies its layout through these two (see above).
	hooksecurefunc(ChatFrame1, 'ClearAllPoints', function() self:PlaceChatFrame() end)
	hooksecurefunc(ChatFrame1, 'SetPoint', function() self:PlaceChatFrame() end)

	-- Blizzard's Edit Mode box no longer controls this frame, so keep it hidden.
	-- HookScript only; nothing is written onto the frame.
	local selection = ChatFrame1.Selection
	if selection then
		selection:HookScript('OnShow', function(box) box:Hide() end)
		selection:Hide()
	end
end

function CHT:RegisterChatMover()
	self.mover = st:RegisterMover('chat', {
		frame = self.holder,
		label = 'Chat',
		getPosition = function() return self.config.position end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyPosition() end,
		configPath = { 'Chat', 'general' },
	})
	self:UpdateFootprint()
end

function CHT:FCFDock_UpdateTabs(dock, forceUpdate)
	if not (dock.isDirty or forceUpdate) then return end

	local prev
	for index, frame in ipairs(dock.DOCKED_CHAT_FRAMES) do
		if prev then
			frame.Tab:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 0, 0)
		else
			frame.Tab:ClearAllPoints()
			frame.Tab:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 10)
			prev = frame.Tab
		end
	end
end

function CHT:OnEnable()
	st:BindModuleConfig(self, 'chat')

	-- Kill stuff
	st:Kill(ChatFrameMenuButton)
	st:Kill(ChatFrameChannelButton)
	st:Kill(QuickJoinToastButton)

	self:MigratePosition()

	for chatID=1, NUM_CHAT_WINDOWS do
		self:SkinChatFrame(_G['ChatFrame'..chatID])
	end

	-- The holder exists, with its hooks, before it is first placed: placing it copies
	-- the anchor to ChatFrame1.
	self.holder = CreateFrame('Frame', st.name .. 'ChatHolder', UIParent)
	self:TakeOverChatFrame()
	self:ApplyPosition()
	self:RegisterChatMover()

	-- self:SecureHook('FCFDock_UpdateTabs')
	-- self:SecureHook('ChatEdit_UpdateHeader')
	--self:SecureHook('ChatFrame_OnUpdate')
	self:SecureHook('FloatingChatFrame_UpdateBackgroundAnchors', 'UpdateChatFrameDisplay')
	self:SecureHook('FCFDock_UpdateTabs')
end