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

-- The Font size row's value before chat's font took Text's own size: the old
-- default, which AceDB never saved, so a profile without one drew at this.
CHT.OLD_FONT_SIZE = 16

-- The one-time step for a profile saved before chat's font was a shared font's
-- whole look. It drew Text's face and outline at its own Font size (fontsize)
-- with its shadow forced to 0, 0, so where that differs from what chat's font
-- setting reads now (Text's size and shadow, or a typeface's), chat keeps the old
-- look as a typeface. The common profile, whose Font size is Text's, changes
-- nothing: chat keeps following its font. The marker, chat.fontsVersion, rides
-- in chat's own profile table, so a copy carries it and a reset clears it. Table
-- writes only. Returns whether it ran.
function CHT:ConvertFonts()
	local config = self.config
	if not config or config.fontsVersion ~= nil then return false end

	local size = type(config.fontsize) == 'number' and config.fontsize or CHT.OLD_FONT_SIZE
	local fields = st:FontFields(config.font)
	local x, y = fields.shadow_offset[1], fields.shadow_offset[2]
	if size ~= fields.font_size or x ~= 0 or y ~= 0 then
		fields.font_size = size
		fields.shadow_offset = { 0, 0 }
		config.font = fields
	end
	config.fontsize = nil
	config.fontsVersion = 1
	return true
end

-- What ApplyChatFont last set on each chat frame: frame -> { path, size, flags,
-- shadow x, shadow y }. Kept apart from the frame (Blizzard's).
local applied = setmetatable({}, { __mode = 'k' })

-- The profile's font on a chat frame, shared by SkinChatFrame and
-- ApplyChatFrameConfig: the face, size, outline and shadow of chat's font setting,
-- the shadow opaque black as Blizzard's own. Blizzard's chat frames draw at line
-- spacing 0 and chat leaves it there (Text's is 4, which would widen every
-- line), so no spacing is set. A face the game refuses to load draws in Text's.
-- With onlyIfChanged, a frame whose last values from here are the same is left as
-- it is: Blizzard's own Font Size menu sets a window's size too, and a Fonts tab
-- change that does not touch chat's font must not undo it. Chat's own changes
-- (its options, a profile change) always apply.
function CHT:ApplyChatFont(frame, onlyIfChanged)
	local path, size, flags, x, y = st:FontValues(self.config.font)
	local last = applied[frame]
	if not last then
		last = {}
		applied[frame] = last
	elseif onlyIfChanged and last[1] == path and last[2] == size and last[3] == flags
		and last[4] == x and last[5] == y then
		return
	end
	last[1], last[2], last[3], last[4], last[5] = path, size, flags, x, y
	frame:SetFont(path, size, flags)
	frame:SetShadowColor(0, 0, 0, 1)
	frame:SetShadowOffset(x, y)
end

-- Kept apart from Blizzard's frames, which get no field from SaftUI
-- (.agents/taint.md, rule 1), each keyed weakly by the chat frame:
--   backdrops: chat frame -> the frame of SaftUI's drawn behind it (st:SetBackdropIn);
--   pieces: chat frame -> { editbox, tab }, Blizzard's edit box and tab of that window;
--   hooked: the edit boxes whose scripts and the tabs whose SetAlpha SaftUI has
--   hooked, so a second skin of the same window adds no second hook.
local backdrops = setmetatable({}, { __mode = 'k' })
local pieces = setmetatable({}, { __mode = 'k' })
local hooked = setmetatable({}, { __mode = 'k' })

-- A chat frame's tab: the one SkinChatFrame found, or for a window it never skinned
-- (a docked one Blizzard made later) the global its XML names. Only read.
local function TabOf(frame)
	local own = pieces[frame]
	if own then return own.tab end
	local name = frame.GetName and frame:GetName()
	return name and _G[name .. 'Tab']
end

-- A chat frame's edit box, the same way: the one SkinChatFrame found, else the global.
local function EditBoxOf(frame)
	local own = pieces[frame]
	if own then return own.editbox end
	return _G[frame:GetName() .. 'EditBox']
end

-- Sets a tab's alpha with the widget's own C method, never the hooked field, so no hook
-- (SaftUI's own below, or another addon's) runs from SaftUI's call.
local function SetTabAlpha(tab, alpha)
	getmetatable(tab).__index.SetAlpha(tab, alpha)
end

-- tabs SaftUI is holding at alpha 1 now (tabs.fade was off at the last HoldTabAlpha).
local held = setmetatable({}, { __mode = 'k' })

-- With tab fading off (tabs.fade) a tab stays at alpha 1: after Blizzard's own SetAlpha
-- on it, which UIFrameFade makes at every step of a fade, a post-hook puts 1 back. The
-- hook reads the profile each time. It calls the widget's own method, not the hooked
-- field, so it can't call itself, and it runs after Blizzard's call, which stays secure.
-- (The old code wrote its own SetAlpha field onto the tab, which Blizzard's fade loop and
-- FCFTab_UpdateAlpha then read, and which dropped the tab from the shared fade list
-- in the middle of that loop: tainted reads inside Blizzard's secure code.)
-- When fading is turned on again, a tab SaftUI was holding gets the alpha Blizzard keeps
-- for it (ChatFrameUtil.GetTabAlphas, a read behind securecallfunction; the mouse-over one
-- once the window has been faded, else the no-mouse one), by the C method, so Blizzard's
-- fade picks up from there at once. FCFTab_UpdateAlpha itself is Blizzard's writer and is
-- never called from here (.agents/taint.md, rule 3).
function CHT:HoldTabAlpha(frame)
	local tab = frame and TabOf(frame)
	if not tab then return end
	if self.config.tabs.fade then
		if held[tab] then
			held[tab] = nil
			if ChatFrameUtil and ChatFrameUtil.GetTabAlphas then
				local over, nomouse = ChatFrameUtil.GetTabAlphas(tab)
				local alpha = frame.hasBeenFaded and over or nomouse
				if alpha then SetTabAlpha(tab, alpha) end
			end
		end
		return
	end
	if not hooked[tab] then
		hooked[tab] = true
		hooksecurefunc(tab, 'SetAlpha', function(widget, alpha)
			if not CHT.config.tabs.fade and alpha ~= 1 then
				SetTabAlpha(widget, 1)
			end
		end)
	end
	held[tab] = true
	if tab:GetAlpha() ~= 1 then SetTabAlpha(tab, 1) end
end

-- Every window's tab takes tabs.fade now (a profile change, the /sui toggle).
function CHT:ApplyTabFading()
	for chatID = 1, NUM_CHAT_WINDOWS do
		local frame = _G['ChatFrame' .. chatID]
		if frame then self:HoldTabAlpha(frame) end
	end
end

function CHT:SkinChatFrame(frame)
	local name = frame:GetName()
	st:StripTextures(frame)
	st:SetBackdropIn(backdrops, frame, self.config.theme, self.config.background, 'panel')

	st:Kill(_G[frame:GetName()..'Background'])
	st:Kill(_G[frame:GetName()..'RightTexture'])

	st:SkinScrollBar(frame.ScrollBar)

	frame:SetScript('OnMouseWheel', onMouseScroll)
	
-- 	frame:SetMinResize(170, 40)
-- 	frame:SetMaxResize(1000, 1000)
	frame:SetFading(false)
	-- ChatFrame1's clamp insets are Blizzard's (an Edit Mode system frame, .agents/taint.md
	-- rule 5): Edit Mode sets them on every layout apply, and the holder reads them live
	-- (st:KeepHolderInScreenMargin), so SaftUI never sets them. The other windows' are 0.
	if frame ~= ChatFrame1 then
		frame:SetClampRectInsets(0,0,0,0)
	end

	self:ApplyChatFont(frame)

	-- Blizzard's edit box and tab of this window. Nothing reads the box's Header or
	-- HeaderSuffix, so they aren't kept at all.
	local editbox = _G[name..'EditBox']
	local tab = _G[name..'Tab']
	pieces[frame] = { editbox = editbox, tab = tab }

	editbox:SetHeight(self.config.editbox.height)
	editbox:SetFrameLevel(frame:GetFrameLevel()+2)
	editbox:SetAltArrowKeyMode(false)
	st:SkinEditBox(editbox, self.config.theme, self.config.background, self.config.font)
	-- Added to Blizzard's own OnShow and OnHide (ChatFrameEditBoxMixin), which run first and
	-- stay: they reset the chat type, deactivate the box and pick the last active window.
	if not hooked[editbox] then
		hooked[editbox] = true
		editbox:HookScript('OnShow', function() GeneralDockManager:Hide() end)
		editbox:HookScript('OnHide', function() GeneralDockManager:Show() end)
	end

	st:Kill(_G[name..'ButtonFrame'])
	st:Kill(frame.ScrollToBottomButton)

	st:StripTextures(tab)
	tab:SetNormalFontObject(st:GetFont('pixel'))
	tab:SetDisabledFontObject(st:GetFont('pixel'))
	tab.Text:SetPoint("CENTER", 0, 2)

	self:HoldTabAlpha(frame)

	self:UpdateChatFrameDisplay(frame)
end

function CHT:UpdateChatFrameDisplay(frame)
	-- The backdrop when a look is drawn; nil under None, even after a theme was drawn once.
	local drawnBackdrop = st:SetBackdropIn(backdrops, frame, self.config.theme, self.config.background, 'panel')

	local offset = 0
	if frame.CombatLogQuickButtonFrame then
		offset = frame.CombatLogQuickButtonFrame:GetHeight()
	end
	-- No backdrop is made while the theme is None.
	local backdrop = backdrops[frame]
	if backdrop then
		backdrop:ClearAllPoints()
		backdrop:SetPoint('TOPLEFT', -self.config.padding, self.config.padding + offset)
		backdrop:SetPoint('BOTTOMRIGHT', self.config.padding, -self.config.padding)
	end

	-- The edit box and the scroll bar sit against the backdrop, or against the window itself
	-- while the theme is None: a nil relative frame would mean the box's parent, which
	-- Blizzard sets to UIParent, and put it off the top of the screen. Only for a window
	-- SkinChatFrame skinned (a temporary one comes through here from Blizzard's hook too).
	local own = pieces[frame]
	if own then
		local against = drawnBackdrop or frame
		local editbox = own.editbox
		editbox:ClearAllPoints()
		editbox:SetPoint('BOTTOMLEFT', against, 'TOPLEFT', 0, 1)
		editbox:SetPoint('BOTTOMRIGHT', against, 'TOPRIGHT', 0, 1)
		local scrollbar = frame.ScrollBar
		scrollbar:ClearAllPoints()
		scrollbar:SetPoint('TOPLEFT', against, 'TOPRIGHT', 5, 0)
		scrollbar:SetPoint('BOTTOMLEFT', against, 'BOTTOMRIGHT', 5, 0)
	end

	if frame == ChatFrame1 then
		self:UpdateFootprint()
	end
end

-- Applies the profile's font, theme, padding and edit box height to a chat
-- frame SkinChatFrame already skinned.
function CHT:ApplyChatFrameConfig(frame)
	self:ApplyChatFont(frame)

	-- Tab fading follows the profile: the hook is made the first time it is off.
	self:HoldTabAlpha(frame)

	local editbox = EditBoxOf(frame)
	if editbox then
		editbox:SetHeight(self.config.editbox.height)
		st:StyleEditBox(editbox, self.config.theme, self.config.background, self.config.font)
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
	enter (EditModeSystemMixin:UpdateClampOffsets), and they keep ChatFrame1 32 in from
	the screen's left and bottom, 25 from its right and 60 from its top. So the holder
	goes no nearer the edges than that either (st:KeepHolderInScreenMargin): where the
	margin is narrower, the holder and the mover's outline on it went on past the chat,
	which stopped at Blizzard's 32. The game shows a holder anchored into the margin at
	the margin, but its anchor stays as set, so ChatFrame1 takes the anchor moved by as
	much as the holder was (st:GetClampShift), and is placed again whenever the margin
	changes.

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
	hooksecurefunc replaces the methods it hooks (ChatFrame1's ClearAllPoints, SetPoint,
	UpdateSystem and, through st:KeepHolderInScreenMargin, UpdateClampOffsets) with its
	own secure wrappers.
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

	st:PlaceHolder(holder, 'chat_holder', function()
		local width, height = self:GetChatSize()
		if not width then
			width, height = ChatFrame1:GetSize()
		end
		return width, height
	end, function() return self.config.position end)
end

-- Puts the mover's outline on the chat frame's border line. SaftUI's backdrop sits
-- `padding` outside the holder (ChatFrame1's rectangle), with its line on its outer
-- edge, and an overlay draws its line EM.OutlineOutset() outside its own rect, so the
-- overlay goes that much inside the padding. With the None theme there's no
-- backdrop, and the overlay covers the holder. Anchored to the holder, the outline
-- follows its size. The outline is SaftUI's own frame, so this is safe in combat.
function CHT:UpdateFootprint()
	local mover = self.mover
	if not mover then return end

	local inset = self.config.theme == 'none' and 0
		or self.config.padding - st.EditModeFrames.OutlineOutset()
	local overlay = mover.overlay
	overlay:ClearAllPoints()
	overlay:SetPoint('TOPLEFT', self.holder, 'TOPLEFT', -inset, inset)
	overlay:SetPoint('BOTTOMRIGHT', self.holder, 'BOTTOMRIGHT', inset, -inset)
end

-- Font, theme, padding and edit box height of every chat frame.
function CHT:ApplyAppearance()
	for chatID=1, NUM_CHAT_WINDOWS do
		self:ApplyChatFrameConfig(_G['ChatFrame'..chatID])
	end
end

-- A profile change: chat size and position, then each chat frame's look, tab fading
-- (tabs.fade) among it.
function CHT:UpdateConfig()
	if not self.config then return end -- not enabled

	self:ConvertFonts()
	self:MigratePosition()
	self:CaptureSize()
	self:ApplyHolder()
	self:ApplyAppearance()
end

-- A shared font or a font setting changed (st:FontsChanged): every chat frame takes
-- chat's font again, and its edit box, and nothing else (no backdrop redraw: a Size
-- drag on the Fonts tab calls this for each step). A window whose font from chat is
-- unchanged is left alone (ApplyChatFont), so Blizzard's own per-window Font Size
-- survives a change that does not touch chat's font. The profile update calls this
-- before the modules' UpdateConfig, with the new profile bound, so a profile
-- switched to converts here first, before its font is read.
function CHT:OnFontsChanged()
	if not self.config then return end -- not enabled
	self:ConvertFonts()
	for chatID = 1, NUM_CHAT_WINDOWS do
		local frame = _G['ChatFrame' .. chatID]
		if frame then
			self:ApplyChatFont(frame, true)
			local editbox = EditBoxOf(frame)
			if editbox then st:ApplyEditBoxFont(editbox, self.config.font) end
		end
	end
end

-- Copies the holder's size and anchor to ChatFrame1 on every SaftUI placement, and puts
-- them back after anything Blizzard does to ChatFrame1 (see above).
function CHT:TakeOverChatFrame()
	local function Place() self:PlaceChatFrame() end

	-- The holder is kept inside the screen edge margin, and no nearer the edges than
	-- ChatFrame1's own clamp lets ChatFrame1 go, so the two stop together.
	st:KeepHolderInScreenMargin(self.holder, ChatFrame1)

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
	-- them hidden, from their next show and now. HookScript only; nothing is written
	-- onto the frames.
	st:HideEditModeSelection(ChatFrame1)
	if ChatFrame1.Selection then ChatFrame1.Selection:Hide() end
	local function KeepHidden(frame)
		if not frame then return end
		frame:HookScript('OnShow', function(self) self:Hide() end)
		frame:Hide()
	end
	KeepHidden(ChatFrame1.EditModeResizeButton)
end

function CHT:RegisterChatMover()
	self.mover = st:RegisterConfigMover(self.holder, {
		key = 'chat',
		label = 'Chat',
		config = function() return self.config end,
		apply = function() self:ApplyHolder() end,
		configPath = { 'Chat', 'general' },
		module = 'Chat',
		defaults = function() return st.defaults.chat end,
	})
	self:UpdateFootprint()
end

function CHT:FCFDock_UpdateTabs(dock, forceUpdate)
	if not (dock.isDirty or forceUpdate) then return end

	local prev
	for index, frame in ipairs(dock.DOCKED_CHAT_FRAMES) do
		local tab = TabOf(frame)
		if tab then
			if prev then
				tab:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', 0, 0)
			else
				tab:ClearAllPoints()
				tab:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 0, 10)
			end
			prev = tab
		end
	end
end

function CHT:OnEnable()
	st:BindModuleConfig(self, 'chat')
	self:ConvertFonts()

	-- Kill stuff
	st:Kill(ChatFrameMenuButton)
	st:Kill(ChatFrameChannelButton)
	st:Kill(QuickJoinToastButton)

	self:MigratePosition()

	for chatID=1, NUM_CHAT_WINDOWS do
		self:SkinChatFrame(_G['ChatFrame'..chatID])
	end

	-- The holder exists, with its hooks and the screen edge margin (TakeOverChatFrame),
	-- before it is first placed: placing it copies the size and where it shows to
	-- ChatFrame1.
	self.holder = CreateFrame('Frame', st.name .. 'ChatHolder', UIParent)
	self:TakeOverChatFrame()
	self:CaptureSize()
	self:ApplyHolder()
	self:RegisterChatMover()

	-- self:SecureHook('FCFDock_UpdateTabs')
	-- self:SecureHook('ChatEdit_UpdateHeader')
	self:SecureHook('FloatingChatFrame_UpdateBackgroundAnchors', 'UpdateChatFrameDisplay')
	self:SecureHook('FCFDock_UpdateTabs')
end