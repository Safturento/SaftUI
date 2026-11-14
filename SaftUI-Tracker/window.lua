local st = SaftUI
local TR = st.Tracker
local L, Layout = TR.LAYOUT, TR.Layout

--[[
	SaftUI's tracker window: its holder and edit mode mover, the window, the
	header, Width, Max height and Grow, the scroll frame and its bar. Built by
	TR:Build, so with the switch off none of this exists. Nothing here is
	secure and nothing is ever anchored to a secure frame, so the window is
	never protected: it sizes, moves, scrolls, shows and hides in combat. The
	rows (Task 5) fill TR.content and tell the window their height through
	TR:SetContentHeight.

	  TR.holder   SaftUITrackerHolder, the mover's frame: Width by Max height at
	              tracker.position. It draws nothing, so edit mode's outline
	              covers the whole height the tracker may take.
	  TR.window   SaftUITracker: as tall as its contents up to Max height,
	              hanging from the holder's top right (Grow down) or bottom
	              right (Grow up). Drawn as a 'panel' in the Theme and
	              Background of the page.
	  TR.header   the header (the title, the count, the collapse chevron, and a
	              line along its bottom); TR.scroll the scroll frame under it,
	              and TR.content the scroll child the rows go in.
	  TR.watcher  one frame whose OnUpdate runs only while a hover rule needs
	              it (today: the scroll bar under the mouse only).

	Every length is a whole pixel: sizes read back from the game (the scroll
	bar's room) are rounded, never ceiled, and every frame is placed by a
	corner.
]]

-- In the game this is the bags' scroll frame (the options kit's bar is a 3 px
-- marker that can't be dragged). The tests replace it with a stand-in
-- (tests/tracker/tracker_world.lua: the game's needs Blizzard's template).
TR.NewScrollFrame = function(parent) return st:CreateScrollFrame(parent) end

local function Round(value)
	return math.floor(value + 0.5)
end

local function Colors()
	return st.config.profile.colors
end

------------------------------------------------------------------ tooltips

-- A tooltip over owner: title in white, then line (if any) in Text > Normal.
-- The tracker sits at the screen's edge, so it opens to the left.
local function ShowTip(owner, title, line)
	GameTooltip:SetOwner(owner, 'ANCHOR_LEFT')
	GameTooltip:ClearLines()
	GameTooltip:AddLine(title, 1, 1, 1)
	if line then
		local r, g, b = Colors().text.normal:GetRGB()
		GameTooltip:AddLine(line, r, g, b, true)
	end
	GameTooltip:Show()
end

local function HideTip(owner)
	if GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end

------------------------------------------------------------------ the header's texts

-- The header's count: the quests in the log over the most it holds, "12/40".
-- Only the first where the game doesn't say the second, and nothing where it
-- says neither. counts is the model's (nil fields where the API is missing).
function TR.CountText(counts)
	local inLog = counts and counts.inLog
	if not inLog then return '' end
	if counts.max then return ('%d/%d'):format(inLog, counts.max) end
	return ('%d'):format(inLog)
end

-- The header's tooltip line under its title, from the model's counts:
-- "12 of 40 quests in your quest log, 8 tracked (up to 25)." and, with the
-- watch list full, "..., 25 tracked: the most you can track." (Ruling 14).
-- nil when the game doesn't say how many are in the log.
function TR.HeaderTip(counts)
	local inLog = counts and counts.inLog
	if not inLog then return end
	local text
	if counts.max then
		text = ('%d of %d quests in your quest log'):format(inLog, counts.max)
	else
		text = ('%d quests in your quest log'):format(inLog)
	end
	local watched, limit = counts.watched, counts.watchMax
	if not watched then return text .. '.' end
	if limit and watched >= limit then
		return text .. (', %d tracked: the most you can track.'):format(watched)
	end
	if limit then return text .. (', %d tracked (up to %d).'):format(watched, limit) end
	return text .. (', %d tracked.'):format(watched)
end

------------------------------------------------------------------ chevrons

-- Every chevron NewChevron made, so a color change paints them again.
local chevrons = setmetatable({}, { __mode = 'k' })

-- Text > Grey at rest, white under the mouse (the skin's chevrons).
local function PaintChevron(button)
	if button.hovered then
		button.icon:SetVertexColor(1, 1, 1, 1)
	else
		local r, g, b = Colors().text.grey:GetRGB()
		button.icon:SetVertexColor(r, g, b, 1)
	end
end

-- A collapse chevron: a 16 square button with Lucide's chevron-up (button:
-- SetDown(false)) or chevron-down drawn 16 (an 8 px glyph). getTip() gives its
-- tooltip's one line ("Collapse", "Expand"); the button's owner binds its click
-- (SetScript('OnClick'): these are the tracker's own plain buttons, not kit
-- controls) and calls button:ShowTip() after a click that changes the tip.
function TR:NewChevron(parent, getTip)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(L.CHEVRON, L.CHEVRON)
	local icon = button:CreateTexture(nil, 'OVERLAY')
	icon:SetSize(L.CHEVRON, L.CHEVRON)
	icon:SetPoint('CENTER')
	icon:SetTexture(st.icons.chevronUp)
	button.icon = icon
	button.hovered = false

	function button:SetDown(down)
		self.icon:SetTexture(down and st.icons.chevronDown or st.icons.chevronUp)
	end
	function button:ShowTip()
		ShowTip(self, getTip())
	end

	button:SetScript('OnEnter', function(self)
		self.hovered = true
		PaintChevron(self)
		self:ShowTip()
	end)
	button:SetScript('OnLeave', function(self)
		self.hovered = false
		PaintChevron(self)
		HideTip(self)
	end)
	chevrons[button] = true
	PaintChevron(button)
	return button
end

------------------------------------------------------------------ position

-- The first position (call 26): a copy of the skin's saved one when Misc is
-- loaded and the profile has one, else Blizzard's default spot, so SaftUI's
-- tracker starts where the player's was. A copy of the five keys of a
-- position, never the skin's own table (AceDB's, with its metatable).
local POSITION_KEYS = { 'point', 'frame', 'rel_point', 'x_off', 'y_off' }

local function FirstPosition()
	local position = st:DefaultTrackerPosition()
	-- Only while Misc's tracker mover exists: AceDB keeps the profile's table
	-- after Misc is disabled, and a stale spot must not be copied.
	local skin = st:GetModule('ObjectiveTracker', true) and st.config.profile.objectivetracker
	local saved = skin and skin.position
	if type(saved) == 'table' then
		for _, key in ipairs(POSITION_KEYS) do
			if saved[key] ~= nil then position[key] = saved[key] end
		end
	end
	return position
end

-- The holder's position: the profile's. A profile with none (a new or reset
-- one) gets the first position written once the tracker is built (Ruling 7);
-- with the switch off it's only read, so the profile is never written. A saved
-- position can lack keys (AceDB drops the ones equal to a default): any
-- missing one comes from the default spot.
function TR:GetPosition()
	local config = self.config
	local position = config.position
	if not position then
		position = FirstPosition()
		if self.holder then config.position = position end
		return position
	end
	for key, value in pairs(st:DefaultTrackerPosition()) do
		if position[key] == nil then position[key] = value end
	end
	return position
end

-- The window hangs from the holder's top right (Grow down) or its bottom right
-- (Grow up): Grow only picks the edge, so it converts no position.
function TR:PlaceWindow()
	local window, holder = self.window, self.holder
	if not (window and holder) then return end
	local point = self.config.grow == 'up' and 'BOTTOMRIGHT' or 'TOPRIGHT'
	window:ClearAllPoints()
	window:SetPoint(point, holder, point, 0, 0)
end

-- Sizes the holder (Width by Max height) and places it from the profile, in
-- whole pixels and kept inside the screen edge margin, then hangs the window on
-- it again. The holder isn't protected, so this runs in combat too.
function TR:ApplyHolder()
	local holder = self.holder
	if not holder then return end
	st:PlaceHolder(holder, 'tracker_holder',
		function() return self.config.width, self:MaxHeight() end,
		function() return self:GetPosition() end)
	st:KeepInScreenMargin(holder)
	self:PlaceWindow()
end

------------------------------------------------------------------ collapsed

-- Whether the window is its header only: the player collapsed it, per
-- character. With Header off there is no whole-tracker collapse, and the saved
-- state is ignored (Ruling 15). While auto quest popups show it is open
-- whatever was saved, and the saved state stays (Ruling 15).
function TR:IsCollapsed()
	return self.config.header and not self.popupsShown and self:CharData().collapsed or false
end

-- Popups show (the refresh says so before it sizes the window): the window is
-- expanded while they do, without changing the saved state.
function TR:SetPopups(shown)
	shown = shown and true or false
	if self.popupsShown == shown then return end
	self.popupsShown = shown
	if self.header then self.header.collapse:SetDown(self:IsCollapsed()) end
end

-- Whether the list is empty (nothing tracked, no popups): the window is hidden
-- for it with Hide when empty, else it shows its header and the empty line.
function TR:SetEmpty(empty)
	self.isEmpty = empty and true or false
	if not self.window then return end
	local shown = not (self.isEmpty and self.config.hide_empty)
	if self.window:IsShown() ~= shown then self.window:SetShown(shown) end
end

function TR:SetCollapsed(collapsed)
	self:CharData().collapsed = collapsed and true or false
	if not self.window then return end
	self.header.collapse:SetDown(self:IsCollapsed())
	self:LayoutWindow()
	self:UpdateTicker()
end

------------------------------------------------------------------ size and scroll

-- Max height as drawn: the saved value, but no taller than the room the screen
-- leaves inside its edge margin (the game would push a taller holder up, and
-- with Grow up the window hangs from the edge that goes off). The saved value
-- is kept. Read when the holder or window is sized: a change of the screen's
-- size shows at the next update.
function TR:MaxHeight()
	local height = self.config.height
	local margin = st.config.profile.misc and st.config.profile.misc.clamp_inset or 0
	local room = Round(UIParent:GetHeight() - 2 * margin)
	if room > 0 and height > room then return room end
	return height
end

-- The window sized for the content height the rows give it: as tall as the
-- content up to Max height, then the list scrolls, with the bar's room kept
-- while it does. The scroll offset is kept, clamped.
function TR:SetContentHeight(height)
	self.contentHeight = Round(height or 0)
	self:LayoutWindow()
end

function TR:LayoutWindow()
	local window, scroll = self.window, self.scroll
	if not window then return end
	local config = self.config
	local header = config.header and true or false
	local collapsed = self:IsCollapsed()
	local content = self.contentHeight or 0
	local width = Round(config.width)

	local height = Layout.WindowHeight(content, { header = header, collapsed = collapsed, max = self:MaxHeight() })
	local view = Layout.ViewHeight(height, header)
	local range = collapsed and 0 or Layout.ScrollRange(content, view)
	-- The bar's room is read from the game (single precision: a hair off), and
	-- rounded so the child's width stays a whole pixel.
	local room = range > 0 and Round(st:ScrollBarRoom(scroll)) or 0
	local childWidth = Layout.ChildWidth(width, room)

	-- Only when something it is made of changed: a refresh that changed nothing
	-- resizes and re-anchors nothing.
	local key = ('%s,%s,%s,%s,%s,%s,%s,%s'):format(width, height, view, childWidth, content, range, header and 1 or 0, collapsed and 1 or 0)
	if key ~= self.layoutKey then
		self.layoutKey = key
		window:SetSize(width, height)
		self.header:SetSize(width - 2 * L.PAD, L.HEADER)
		scroll:ClearAllPoints()
		scroll:SetPoint('TOPLEFT', window, 'TOPLEFT', L.PAD, -(L.PAD + (header and L.HEADER + L.HEADER_GAP or 0)))
		scroll:SetSize(childWidth, view)
		scroll:SetContentSize(childWidth, content)
		scroll:SetShown(not collapsed)
		-- The window and the list take the wheel only while the list scrolls, so
		-- the camera still zooms with the cursor over a tracker that fits, is empty
		-- or is collapsed. Neither frame is protected: safe in combat.
		window:EnableMouseWheel(range > 0)
		scroll:EnableMouseWheel(range > 0)
	end
	self.scrollRange = range
	self:UpdateWatcher()
	-- A collapsed window keeps the player's place for when it opens again.
	if not collapsed then self:ScrollTo(self:GetScroll()) end
	self:PlaceFocusBar()
end

-- The scroll view's height as drawn, in whole pixels.
function TR:ViewHeight()
	return self.scroll and Round(self.scroll:GetHeight()) or 0
end

-- How far down the list is scrolled.
function TR:GetScroll()
	return self.scroll and self.scroll:GetVerticalScroll() or 0
end

-- Scrolls to offset, a whole number of pixels, clamped to the list.
function TR:ScrollTo(offset)
	if not self.scroll then return end
	local whole = math.min(math.max(Round(offset), 0), self.scrollRange or 0)
	self.scrollAt = whole
	if self.scroll:GetVerticalScroll() ~= whole then
		self.scrolling = true
		self.scroll:SetVerticalScroll(whole)
		self.scrolling = false
	end
	self:PlaceFocusBar()
end

-- Task 8: while an item button sits in a row the list doesn't scroll in combat.
function TR:IsScrollLocked()
	return false
end

-- The wheel over the window or the scroll frame: 40 a notch, clamped.
local function OnWheel(_, delta)
	if (TR.scrollRange or 0) <= 0 or TR:IsScrollLocked() then return end
	TR.lastUserScroll = GetTime()
	TR:ScrollTo(Layout.Wheel(TR:GetScroll(), delta, TR.scrollRange or 0))
end

-- Whether the mouse is over the tracker: the window (Task 9 adds the item
-- column beside it).
function TR:IsHovered()
	return self.window ~= nil and self.window:IsMouseOver() or false
end

-- The bar rule: shown while Scroll bar under the mouse only is off, or the
-- tracker is hovered, or within BAR_LINGER after the mouse leaves (so it can
-- be reached). The bar is hidden by alpha: the template shows and hides it
-- itself, by whether the list scrolls.
function TR:UpdateBar()
	local bar = self.scroll and self.scroll.ScrollBar
	if not bar then return end
	local visible = true
	if self.config.visibility.scrollbar_hover then
		local now = GetTime()
		if self:IsHovered() then
			self.hoverAt = now
		else
			visible = self.hoverAt ~= nil and now - self.hoverAt < L.BAR_LINGER
		end
	end
	local alpha = visible and 1 or 0
	if self.barAlpha ~= alpha or bar:GetAlpha() ~= alpha then
		self.barAlpha = alpha
		bar:SetAlpha(alpha)
	end
end

local function OnWatch()
	TR:UpdateBar()
end

-- The one OnUpdate, running only while a hover rule needs it: the window shows
-- and the scroll bar is under the mouse only.
function TR:UpdateWatcher()
	local watcher = self.watcher
	if not watcher then return end
	-- Only while a bar can show: the list scrolls. Otherwise the OnUpdate would
	-- run every frame (an IsMouseOver and a GetTime) for nothing. While it runs
	-- that is all it costs.
	local needed = self.config.visibility.scrollbar_hover and self.window:IsShown() and (self.scrollRange or 0) > 0
	if needed then
		if not watcher:GetScript('OnUpdate') then watcher:SetScript('OnUpdate', OnWatch) end
	elseif watcher:GetScript('OnUpdate') then
		watcher:SetScript('OnUpdate', nil)
	end
	self:UpdateBar()
end

------------------------------------------------------------------ the header

-- The header's count and tooltip from the model's counts (Task 5 calls this
-- after each refresh); nil clears them.
function TR:UpdateHeader(model)
	self.counts = model and model.counts or nil
	local header = self.header
	if not header then return end
	TR.SetText(header.count, TR.CountText(self.counts))
	header.tipLine = TR.HeaderTip(self.counts)
end

-- The line along the header's bottom: the drawn theme's border color, faint
-- (the skin's LineColor rule).
local function LineColor()
	local config = TR.config
	local look = st:ResolveTheme(config.theme, config.background) or st:ResolveTheme()
	local r, g, b = unpack(look.colors.bordercolor)
	return r, g, b, L.LINE_ALPHA
end

-- What the module colors itself, put back after a theme recolor or a color
-- change: the texts, the line and the chevrons.
function TR:ColorHeader()
	local header = self.header
	if not header then return end
	local text = Colors().text
	header.title:SetTextColor(text.normal:GetRGB())
	header.count:SetTextColor(text.grey:GetRGB())
	header.line:SetVertexColor(LineColor())
	for chevron in pairs(chevrons) do PaintChevron(chevron) end
end

-- The window's part of a color change; the module's one OnColorsChanged
-- (init.lua) calls it, and each later part adds its own call there.
function TR:ColorWindow()
	self:ColorHeader()
end

-- The header from the profile: shown or not, its fonts, the count's switch and
-- the chevron's direction.
function TR:DrawHeader()
	local config, header = self.config, self.header
	header:SetShown(config.header and true or false)
	local font = st:GetFont(config.header_font)
	header.title:SetFontObject(font)
	header.count:SetFontObject(font)
	header.count:SetShown(config.count and true or false)
	header.collapse:SetDown(self:IsCollapsed())
	self:ColorHeader()
end

-- The window from the profile: its Theme and Background (a panel in the pair;
-- a theme change draws it again by itself, and OnColorsChanged puts the line
-- and chevrons back), the header, its size and the hover rule.
function TR:DrawWindow()
	local config = self.config
	st:SetBackdrop(self.window, config.theme, config.background, 'panel')
	-- The bar's thumb wears the tracker's Theme, not only SaftUI's (the skin
	-- draws it in the global one).
	local bar = self.scroll.ScrollBar
	local thumb = bar and bar.GetThumb and bar:GetThumb()
	if thumb then st:SetBackdrop(thumb, config.theme, 'solid', 'control') end
	self:DrawHeader()
	self:LayoutWindow()
	self:UpdateWatcher()
end

------------------------------------------------------------------ building

local function BuildHeader(window)
	local header = CreateFrame('Frame', nil, window)
	header:SetPoint('TOPLEFT', window, 'TOPLEFT', L.PAD, -L.PAD)
	header:SetSize(1, L.HEADER)
	header:EnableMouse(true)

	-- A text needs its font before it's given text (DrawHeader sets the profile's).
	local font = st:GetFont(TR.config.header_font)
	local title = header:CreateFontString(nil, 'OVERLAY')
	title:SetFontObject(font)
	title:SetPoint('LEFT', header, 'LEFT', 0, 0)
	title:SetJustifyH('LEFT')
	title:SetText('Objectives')
	header.title = title

	local collapse = TR:NewChevron(header, function()
		return TR:IsCollapsed() and 'Expand' or 'Collapse'
	end)
	collapse:SetPoint('TOPRIGHT', header, 'TOPRIGHT', 0, -(L.HEADER - L.CHEVRON) / 2)
	collapse:SetScript('OnClick', function(self)
		-- Popups hold the window open: a click would save a state that shows nothing.
		if TR.popupsShown then return end
		TR:SetCollapsed(not TR:IsCollapsed())
		if GameTooltip:IsOwned(self) then self:ShowTip() end
	end)
	header.collapse = collapse

	local count = header:CreateFontString(nil, 'OVERLAY')
	count:SetFontObject(font)
	count:SetPoint('RIGHT', collapse, 'LEFT', -L.COUNT_GAP, 0)
	count:SetJustifyH('RIGHT')
	header.count = count

	local line = header:CreateTexture(nil, 'ARTWORK')
	line:SetTexture(st.BLANK_TEX)
	line:SetPoint('BOTTOMLEFT', header, 'BOTTOMLEFT', 0, 0)
	line:SetPoint('BOTTOMRIGHT', header, 'BOTTOMRIGHT', 0, 0)
	line:SetHeight(st:GetPixelSize(header) or 1)
	header.line = line

	header:SetScript('OnEnter', function(self)
		ShowTip(self, 'Objectives', self.tipLine)
	end)
	header:SetScript('OnLeave', function(self)
		HideTip(self)
	end)
	return header
end

-- Makes the holder, the mover, the window and everything in it. Called once, by
-- TR:Build, only with the switch on.
function TR:BuildWindow()
	local holder = st:CreateFrame('Frame', st.name .. 'TrackerHolder', UIParent)
	self.holder = holder

	local window = st:CreateFrame('Frame', st.name .. 'Tracker', UIParent)
	window:SetFrameStrata('LOW')
	window:SetFrameLevel(10)
	window:EnableMouseWheel(true)
	window:SetScript('OnMouseWheel', OnWheel)
	window:SetScript('OnShow', function() TR:UpdateWatcher() end)
	window:SetScript('OnHide', function() TR:UpdateWatcher() end)
	self.window = window

	self.header = BuildHeader(window)

	local scroll = TR.NewScrollFrame(window)
	scroll:SetScript('OnMouseWheel', OnWheel)
	-- The bar's own input (its wheel, steppers, thumb and track) goes through
	-- Blizzard's percentage x range (ScrollUtil.InitScrollFrameWithScrollBar):
	-- its wheel is the window's, its step 40, and the offset it sets is made a
	-- whole pixel here, or put back while the list is locked.
	if scroll.ScrollBar then scroll.ScrollBar:SetScript('OnMouseWheel', OnWheel) end
	if scroll.SetPanExtent then scroll:SetPanExtent(L.WHEEL) end
	local settling = false
	scroll:HookScript('OnVerticalScroll', function(frame, offset)
		if settling then return end
		local at = TR.scrollAt or 0
		local target
		if TR:IsScrollLocked() and math.abs(offset - at) > 0.01 then
			target = at
		else
			target = Round(offset)
			TR.scrollAt = target
		end
		-- The float noise of percentage x range is left alone; a drag's fraction
		-- isn't. The guard keeps the bar's own re-set from coming back here.
		if math.abs(target - offset) > 0.01 then
			settling = true
			frame:SetVerticalScroll(target)
			settling = false
		end
		TR:PlaceFocusBar()
	end)
	-- The player's own scrolling is real input only: the wheel (OnWheel) and a
	-- mouse-down on the bar's thumb, track or steppers. The bar setting the offset
	-- itself after a range change fires OnVerticalScroll too and is not that.
	local bar = scroll.ScrollBar
	if bar then
		local parts = { bar.Track, bar.Back, bar.Forward, bar.GetThumb and bar:GetThumb() }
		for index = 1, 4 do
			local part = parts[index]
			if part and part.HookScript then
				part:HookScript('OnMouseDown', function() TR.lastUserScroll = GetTime() end)
			end
		end
	end
	self.scroll = scroll
	self.content = scroll.ScrollChild

	self.watcher = CreateFrame('Frame', nil, UIParent)

	-- Sized and placed first: the mover's outline is the holder's.
	self:ApplyHolder()
	st:RegisterMover('tracker', {
		frame = holder,
		label = 'Tracker',
		getPosition = function() return self:GetPosition() end,
		-- What the profile holds, nil while it has none (getPosition makes one up).
		getSavedPosition = function() return self.config.position end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyHolder() end,
		configPath = { 'Tracker', 'general' },
		module = 'Tracker',
		isHidden = function() return not self.window:IsShown() end,
		-- Blizzard's default spot, a fresh table on every call.
		getDefaultPosition = function() return st:DefaultTrackerPosition() end,
	})
	self:DrawWindow()
end
