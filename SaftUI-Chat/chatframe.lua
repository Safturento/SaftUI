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
	(EditModeChatFrameSystemTemplate). On every layout load or change Blizzard re-applies
	its position and size (EditModeChatFrameSystemMixin:UpdateSystem):
	  - ApplySystemAnchor: ClearAllPoints, then SetPoint with the layout's anchor. Both are
	    Lua overrides installed by EditModeSystemMixin:OnSystemLoad, and SetPointOverride
	    writes EditModeManagerFrame.editModeSystemAnchorDirty, so addon code never calls
	    them on ChatFrame1. st:ClearAllPointsDirect and st:SetPointDirect run the widget
	    API's own methods instead.
	  - UpdateSystemSettingWidth/Height: SetSize with the layout's Width and Height (the
	    plain widget method; OnSystemLoad doesn't replace it), then UpdateSystemAnchorInfo,
	    which copies ChatFrame1's first two anchors into Blizzard's layout.

	SaftUI owns both. Its edit mode moves a holder frame, not ChatFrame1 (a drag calls the
	mover frame's ClearAllPoints and SetPoint). The holder is a plain SaftUI frame, sized
	from chat.width/height and anchored from chat.position. ChatFrame1 gets the holder's
	size (st:SetSizeDirect) and the same single anchor, so the two cover the same
	rectangle. ChatFrame1 isn't anchored to the holder itself: UpdateSystemAnchorInfo would
	then write the holder's name into Blizzard's layout, which breaks a saved layout once
	SaftUI is off. Whenever the holder's SetPoint runs (the profile, /sui, a drag or a
	nudge), a post-hook copies its size and anchor to ChatFrame1.

	The holder, not ChatFrame1, is kept inside SaftUI's screen edge margin
	(st:KeepInScreenMargin). ChatFrame1's clamp insets are Blizzard's: its Edit Mode
	rewrites them from the frame's Selection box on every layout apply and Edit Mode
	enter (EditModeSystemMixin:UpdateClampOffsets). The game shows a holder anchored
	into the margin at the margin, but its anchor stays as set, so ChatFrame1 takes the
	anchor moved by as much as the holder was (st:GetClampShift), and is placed again
	whenever the margin changes.

	These put SaftUI's size and anchor back after Blizzard changes them:
	  - post-hooks on ChatFrame1's ClearAllPoints and SetPoint, after each anchor change;
	  - a post-hook on ChatFrame1's UpdateSystem, after each layout apply and its SetSize;
	  - an OnSizeChanged hook, after any other resize, e.g. a StartSizing drag from a
	    docked chat window's resize button, which sizes the dock's primary frame
	    (ChatFrame1).
	They re-apply with the direct helpers only, which skip those hooks, so they can't loop.

	Blizzard's Edit Mode box on ChatFrame1 and its resize grabber (EditModeResizeButton,
	shown on Edit Mode enter) are kept hidden with HookScript, so Blizzard's Edit Mode can't
	select, drag or resize the chat frame: /sui owns its size. ChatFrame1's own resize
	button (ResizeButton) is left alone, as Blizzard never shows it for DEFAULT_CHAT_FRAME
	(FCF_UpdateResizeButton). Docked chat windows are normally locked, which hides theirs
	too; should one show, the OnSizeChanged hook undoes its resize.

	Nothing is written onto ChatFrame1 or any other Blizzard table, except that
	hooksecurefunc replaces the methods it hooks (ChatFrame1's ClearAllPoints, SetPoint and
	UpdateSystem) with its own secure wrappers.
]]

-- SetPoint's argument order: the array shape chat.position had before the chat frame
-- became a mover.
local POSITION_KEYS_BY_INDEX = { 'point', 'frame', 'rel_point', 'x_off', 'y_off' }

-- Converts a chat.position saved in the old array shape to the named keys, in place, so
-- the chat frame doesn't move. AceDB saves only the entries that differ from the
-- default, so any of [1] to [5] can be there on its own. A missing entry held the old
-- default, and the old and new defaults are the same spot, so it's left to the named
-- default.
function CHT:MigratePosition()
	local position = self.config and self.config.position
	if not position then return end

	for i, key in ipairs(POSITION_KEYS_BY_INDEX) do
		if position[i] ~= nil then
			position[key] = position[i]
			position[i] = nil
		end
	end
end

-- The chat frame's size from the profile, rounded to the pixel, or nil while the profile
-- has none yet (see CaptureSize).
function CHT:GetChatSize()
	local width, height = tonumber(self.config.width), tonumber(self.config.height)
	if not (width and height) then return end
	return st:RoundToPixel(width, self.holder), st:RoundToPixel(height, self.holder)
end

-- chat.width and chat.height have no defaults. A profile without them takes the size
-- the chat frame has, so nothing changes on first load or on switching to a new
-- profile. Blizzard's Edit Mode sizes ChatFrame1 from its layout, which can arrive after
-- SaftUI loads (EDIT_MODE_LAYOUTS_UPDATED); until then ChatFrame1 has its XML size. So
-- this waits for Blizzard's first layout apply: EditModeSystemMixin:UpdateSystem sets
-- ChatFrame1.systemInfo, and the UpdateSystem post-hook calls this again. force skips the
-- wait (a size typed in /sui fills in the other one).
function CHT:CaptureSize(force)
	local config = self.config
	if config.width and config.height then return end
	if not (force or ChatFrame1.systemInfo) then return end

	local width, height = ChatFrame1:GetSize()
	config.width = config.width or math.floor(width + 0.5)
	config.height = config.height or math.floor(height + 0.5)
end

-- Gives ChatFrame1 the holder's anchor and SaftUI's size. In combat it can't move if a
-- protected frame (e.g. a unit frame) is anchored to it; then this waits for the end of
-- combat and reads the holder and the profile when it runs.
function CHT:PlaceChatFrame()
	st:SafeReposition(ChatFrame1, 'chat', function()
		local point, relative, rel_point, x, y = self.holder:GetPoint(1)
		if not point then return end -- the holder is between ClearAllPoints and SetPoint
		-- Where the holder shows, which the screen edge margin can keep in from
		-- where its anchor puts it.
		local dx, dy = st:GetClampShift(self.holder)
		if dx then
			x, y = st:RoundToPixel(x + dx, ChatFrame1), st:RoundToPixel(y + dy, ChatFrame1)
		end
		st:ClearAllPointsDirect(ChatFrame1)
		st:SetPointDirect(ChatFrame1, point, relative, rel_point, x, y)

		local width, height = self:GetChatSize()
		if width then -- until the profile has a size, Blizzard's stays (see CaptureSize)
			st:SetSizeDirect(ChatFrame1, width, height)
		end
	end)
end

-- After anything other than SaftUI resized ChatFrame1, puts SaftUI's size and anchor
-- back. A resize drag leaves ChatFrame1 anchored where the drag put it, so the anchor
-- goes back too, and the chat doesn't grow from the wrong edge.
function CHT:HoldSize()
	local width, height = self:GetChatSize()
	if not width then return end

	local currentWidth, currentHeight = ChatFrame1:GetSize()
	if math.abs(currentWidth - width) > 0.01 or math.abs(currentHeight - height) > 0.01 then
		self:PlaceChatFrame()
	end
end

-- Sizes and places the holder from the profile; ChatFrame1 follows (see PlaceChatFrame).
-- Until the profile has a size, the holder takes ChatFrame1's.
function CHT:ApplyHolder()
	local holder = self.holder
	if not holder then return end

	st:SafeReposition(holder, 'chat_holder', function()
		local width, height = self:GetChatSize()
		if not width then
			width, height = ChatFrame1:GetSize()
		end
		holder:SetSize(width, height)

		local point, relative, rel_point, x, y = st:UnpackPoint(self.config.position)
		holder:ClearAllPoints()
		holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point,
			st:RoundToPixel(x, holder), st:RoundToPixel(y, holder))
	end)
end

-- Puts the mover's outline on the chat frame's border line. SaftUI's backdrop sits
-- `padding` outside the holder (ChatFrame1's rectangle), with its line on its outer
-- edge, and an overlay draws its line EM.OUTLINE_OUTSET outside its own rect, so the
-- overlay goes that much inside the padding. With the 'none' template there's no
-- backdrop, and the overlay covers the holder. Anchored to the holder, the outline
-- follows its size. The outline is SaftUI's own frame, so this is safe in combat.
function CHT:UpdateFootprint()
	local mover = self.mover
	if not mover then return end

	local inset = self.config.template == 'none' and 0
		or self.config.padding - st.EditModeFrames.OUTLINE_OUTSET
	local overlay = mover.overlay
	overlay:ClearAllPoints()
	overlay:SetPoint('TOPLEFT', self.holder, 'TOPLEFT', -inset, inset)
	overlay:SetPoint('BOTTOMRIGHT', self.holder, 'BOTTOMRIGHT', inset, -inset)
end

-- Font, template, padding and edit box height of every chat frame.
function CHT:ApplyAppearance()
	for chatID=1, NUM_CHAT_WINDOWS do
		self:ApplyChatFrameConfig(_G['ChatFrame'..chatID])
	end
end

-- A profile change: chat size and position, then each chat frame's look. Tab fading
-- (tabs.fade) is only applied when the frames are first skinned.
function CHT:UpdateConfig()
	if not self.config then return end -- not enabled

	self:MigratePosition()
	self:CaptureSize()
	self:ApplyHolder()
	self:ApplyAppearance()
end

-- Copies the holder's size and anchor to ChatFrame1 on every SaftUI placement, and puts
-- them back after anything Blizzard does to ChatFrame1 (see above).
function CHT:TakeOverChatFrame()
	local function Place() self:PlaceChatFrame() end

	-- Every SaftUI placement of the holder, and a mover drag (which calls SetPoint on
	-- it), is copied to ChatFrame1. ClearAllPoints needs no hook: SetPoint follows it.
	hooksecurefunc(self.holder, 'SetPoint', Place)
	-- A new screen edge margin can move where the holder shows without moving its anchor.
	hooksecurefunc(st, 'UpdateScreenMargin', Place)

	-- Blizzard's Edit Mode applies its layout's anchor through these two.
	hooksecurefunc(ChatFrame1, 'ClearAllPoints', Place)
	hooksecurefunc(ChatFrame1, 'SetPoint', Place)

	-- A layout apply also sets Blizzard's Width and Height. The first one gives a profile
	-- without a size the layout's size (CaptureSize); after that SaftUI's goes back on.
	if ChatFrame1.UpdateSystem then
		hooksecurefunc(ChatFrame1, 'UpdateSystem', function()
			self:CaptureSize()
			self:ApplyHolder()
		end)
	end

	-- Any other resize.
	ChatFrame1:HookScript('OnSizeChanged', function() self:HoldSize() end)

	-- Blizzard's Edit Mode box and resize grabber no longer control this frame, so keep
	-- them hidden. HookScript only; nothing is written onto the frames.
	local function KeepHidden(frame)
		if not frame then return end
		frame:HookScript('OnShow', function(self) self:Hide() end)
		frame:Hide()
	end
	KeepHidden(ChatFrame1.Selection)
	KeepHidden(ChatFrame1.EditModeResizeButton)
end

function CHT:RegisterChatMover()
	self.mover = st:RegisterMover('chat', {
		frame = self.holder,
		label = 'Chat',
		getPosition = function() return self.config.position end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyHolder() end,
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

	-- The holder exists, with its hooks and the screen edge margin, before it is first
	-- placed: placing it copies the size and where it shows to ChatFrame1.
	self.holder = CreateFrame('Frame', st.name .. 'ChatHolder', UIParent)
	st:KeepInScreenMargin(self.holder)
	self:TakeOverChatFrame()
	self:CaptureSize()
	self:ApplyHolder()
	self:RegisterChatMover()

	-- self:SecureHook('FCFDock_UpdateTabs')
	-- self:SecureHook('ChatEdit_UpdateHeader')
	--self:SecureHook('ChatFrame_OnUpdate')
	self:SecureHook('FloatingChatFrame_UpdateBackgroundAnchors', 'UpdateChatFrameDisplay')
	self:SecureHook('FCFDock_UpdateTabs')
end