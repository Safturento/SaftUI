local st = SaftUI
local TB = st:GetModule('TotemBar')
local S = TB.S

--[[
	The totem bar's position (totembar.lua says what the bar is). On a shaman SaftUI
	moves the bar in its own edit mode, the way it moves the default tooltip's container
	(tooltipposition.lua):
	  - A holder of SaftUI's (SaftUITotemBarHolder) is the edit mode mover and the /sui
	    Position. It's placed from the profile's position and is always the bar's size
	    (TB:ApplyButtonLayout sizes both).
	  - The bar is put where the holder is: its bottom-left corner on UIParent's, at the
	    holder's left and bottom in whole pixels (TB:AnchorBar), with the plain widget
	    methods (st:ClearAllPointsDirect, st:SetPointDirect). The bar's own SetPoint and
	    ClearAllPoints are Blizzard's Edit Mode overrides, which write Edit Mode state.
	    It's put there again whenever the holder is placed (a post-hook on the holder's
	    SetPoint: a drag, a nudge, /sui, a profile change) or resized (the button
	    layout), out of combat only.
	  - The bar is never anchored to the holder itself, because Blizzard's Edit Mode
	    reads its anchor. The bar is snapped to MainActionBar in its default position
	    (SetPointOverride's SetSnappedToFrame). When MainActionBar hides, e.g. entering a
	    vehicle out of combat, BreakSnappedFrames runs the bar's BreakFrameSnap, which
	    re-anchors it (the post-hooks below put it back) and then reads GetPoint(1) in
	    UpdateSystemAnchorInfo, into the active layout, which a later save keeps.
	    Anchored to the holder, the layout would name SaftUITotemBarHolder, and on an alt
	    without the holder (another class, SaftUI-Misc off) Blizzard would anchor the
	    bar to a frame that isn't there. On UIParent, Blizzard records the spot the bar
	    is at, as it would for any snap break.
	  - Blizzard re-places the bar when an Edit Mode layout loads, and in its default
	    position from UpdateBottomActionBarPositions (see totembar.lua), in combat too.
	    Post-hooks on the bar's ClearAllPoints and SetPoint put it back at the holder's
	    spot: straight away, or at the end of combat if it's on, as the bar is protected.
	    SaftUI never changes the bar's Edit Mode position, so these re-places keep coming,
	    until Blizzard itself records a spot for it after a snap break (above), which
	    stops UpdateBottomActionBarPositions from stacking it.
	  - So the buttons don't go with the bar when Blizzard re-places it mid-fight, they're
	    anchored to the holder, not to the bar, as SaftUI-ActionBars/extras.lua does with
	    the extra action button. Blizzard's bar frame then sits at Blizzard's spot until
	    combat ends, empty. Its XML makes it take the mouse though it has nothing to
	    click, so it's made click-through, and it can't catch clicks meant for what's
	    under it there.
	  - Blizzard's Edit Mode box for the bar (its Selection) is kept hidden, so Blizzard's
	    Edit Mode can't move it any more. Blizzard's Totem Bar checkbox still shows the bar
	    while Blizzard's Edit Mode is open. The bar has no other Edit Mode settings.
	  - First load moves nothing. totembar.position has no default: AceDB fills in
	    defaults, so a default couldn't be told apart from a position the user set. A
	    profile with no position takes the bar's spot on screen once Blizzard has placed
	    it, out of combat (TB:CapturePosition), and that's saved. Until then the bar
	    stays Blizzard's, with its buttons on it, and the holder waits in the middle of
	    the screen, unsaved, until it's captured or moved. On a profile change, a profile
	    with no position keeps the holder's spot from the profile before
	    (TB:KeepPlacement), so switching profiles moves nothing either.
	  - Only a shaman has totems, so only a shaman gets the holder, the mover and the
	    hooks. On every other class the bar stays where Blizzard puts it, as before.
	The trade-off is the one that kept SaftUI from moving the bar before: in Blizzard's
	default position Blizzard re-anchors it in combat, and a protected bar can't be put
	back until combat ends. With the buttons on the holder only Blizzard's empty frame
	moves, except as totemlayout.lua says for Blizzard's own button update in combat.
]]

-- From totemlayout.lua: the bar's width and height for the profile, which the holder
-- has too.
local BarSize = S.BarSize

-- Where the holder waits while the profile has no position and Blizzard hasn't placed
-- the bar yet (see the top of this file): the middle of the screen. Never saved by
-- itself; moving the holder from here saves it with the move.
local WAITING_POSITION = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 }

-- A copy of the position the holder was last placed from, kept across profile changes
-- for TB:KeepPlacement. nil until a profile's position first places it.
local placedAt

-- How far across and up a frame each anchor point is.
local POINT_X = {
	TOPLEFT = 0, LEFT = 0, BOTTOMLEFT = 0,
	TOP = 0.5, CENTER = 0.5, BOTTOM = 0.5,
	TOPRIGHT = 1, RIGHT = 1, BOTTOMRIGHT = 1,
}
local POINT_Y = {
	BOTTOMLEFT = 0, BOTTOM = 0, BOTTOMRIGHT = 0,
	LEFT = 0.5, CENTER = 0.5, RIGHT = 0.5,
	TOPLEFT = 1, TOP = 1, TOPRIGHT = 1,
}

-- Where one of a frame's anchor points is on screen, in UIParent's units, or nil while
-- the frame has no place.
local function PointPosition(frame, point)
	local left, bottom, width, height = frame:GetRect()
	if not (left and bottom and width and height) then return end
	local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
	return (left + width * POINT_X[point]) * scale, (bottom + height * POINT_Y[point]) * scale
end

local function CopyPosition(position)
	local copy = {}
	for key, value in pairs(position) do copy[key] = value end
	return copy
end

-- The holder's position: the profile's, or a new copy of the waiting spot while the
-- profile has none. The edit mode mover and /sui Position change the table this hands
-- them and save it, so a first move from the waiting spot saves a position.
function TB:GetPosition()
	return self.config.position or CopyPosition(WAITING_POSITION)
end

-- A profile with no position (a new or reset one) keeps the spot the holder was last
-- placed at by another profile, so switching profiles doesn't move the bar. The bar is
-- at the holder's spot then, so there's nothing to read from Blizzard. Safe in combat: it
-- only writes the profile.
function TB:KeepPlacement()
	if self.holder and not self.config.position and placedAt then
		self.config.position = CopyPosition(placedAt)
	end
end

-- Saves the bar's spot on screen as the profile's position, if Blizzard has placed it,
-- and returns whether it did. The bar is placed once Blizzard's Edit Mode has applied its
-- layout to it (EditModeSystemMixin:UpdateSystem sets its systemInfo) and, in Blizzard's
-- default position, once it shows: until then Blizzard leaves it at UIParent's top-left
-- corner (ApplySystemAnchor), as UpdateBottomActionBarPositions only stacks shown bars.
-- The position keeps the bar's own anchor point, moved onto UIParent's same point, so the
-- holder grows from where the bar grew (see the top of this file). Called out of combat,
-- from outside Blizzard's re-places (TB:QueueCapture), so the bar is where Blizzard left it.
function TB:CapturePosition()
	local bar = self.bar
	local info = bar.systemInfo
	if not info then return false end
	if info.isInDefaultPosition and not bar:IsShown() then return false end

	local point = bar:GetPoint(1)
	if not POINT_X[point] then point = 'BOTTOMLEFT' end
	local x, y = PointPosition(bar, point)
	local parentX, parentY = PointPosition(UIParent, point)
	if not (x and parentX) then return false end

	self.config.position = {
		point = point,
		frame = 'UIParent',
		rel_point = point,
		x_off = st:RoundToPixel(x - parentX, self.holder),
		y_off = st:RoundToPixel(y - parentY, self.holder),
	}
	return true
end

-- Captures the bar's spot, if the profile has no position, and places the holder there.
-- Out of combat only, as placing the holder moves the protected bar to its spot: in combat
-- this waits for the end of combat and tries again then.
function TB:TryCapture()
	if self.config.position then return end
	if st:QueueAfterCombat('totembar_capture', function() self:TryCapture() end) then return end
	if self:CapturePosition() then self:ApplyHolder() end
end

-- Tries the capture on the next frame, once however often it's asked for in one frame.
-- It's asked for from post-hooks on Blizzard's own re-places, where the bar can be
-- between two of Blizzard's anchors: an Edit Mode layout load first puts every frame at
-- UIParent's top-left corner, then where the layout says. By the next frame Blizzard is
-- done.
local captureQueued = false
function TB:QueueCapture()
	if captureQueued or not self.holder or self.config.position then return end
	captureQueued = true
	C_Timer.After(0, function()
		captureQueued = false
		self:TryCapture()
	end)
end

-- Puts Blizzard's bar where the holder is: its bottom-left corner on UIParent's, at the
-- holder's left and bottom, in whole pixels. They're the same size (TB:ApplyButtonLayout),
-- so the bar covers the holder exactly. Never anchored to the holder itself, as Blizzard's
-- Edit Mode can record the bar's anchor into its layout (see the top of this file). Plain
-- widget methods, as the bar's own are Edit Mode's overrides; they don't run the
-- post-hooks below either. The bar is protected, so in combat this waits for the end of
-- combat. A holder with no place yet (between ClearAllPoints and SetPoint on a profile
-- change) leaves the bar where it is: placing the holder calls this again.
function TB:AnchorBar()
	local bar, holder = self.bar, self.holder
	if not (holder and self.config.position) then return end
	if st:QueueAfterCombat('totembar_anchor', function() self:AnchorBar() end) then return end
	local left, bottom = holder:GetLeft(), holder:GetBottom()
	if not (left and bottom) then return end
	local scale = holder:GetEffectiveScale() / bar:GetEffectiveScale()
	st:ClearAllPointsDirect(bar)
	st:SetPointDirect(bar, 'BOTTOMLEFT', UIParent, 'BOTTOMLEFT',
		st:RoundToPixel(left * scale, bar), st:RoundToPixel(bottom * scale, bar))
end

-- Sizes and places the holder from the profile, then puts the bar at its spot and lays
-- the buttons out on it, the first time it's placed from a position. The edit mode mover's
-- apply, so it runs at the end of every drag and on every nudge. The holder is protected
-- once the buttons are anchored to it, so in combat it's placed at the end of combat.
-- Placing it puts the bar at its spot through the holder's SetPoint hook (TB:SetupPosition);
-- AnchorBar here covers a holder that was already where the position says.
function TB:ApplyHolder()
	local holder = self.holder
	if not holder then return end
	self:KeepPlacement()

	st:PlaceHolder(holder, 'totembar_holder',
		function() return BarSize(self.config, self.bar) end,
		function() return self:GetPosition() end)

	local position = self.config.position
	if not position then return end
	placedAt = CopyPosition(position)
	self:AnchorBar()
	if S.laidOutOn ~= holder then self:ApplyButtonLayout() end
end

-- Blizzard's bar takes the mouse (enableMouse in its XML) but has nothing of its own to
-- click. Made click-through, with the plain widget method, so while Blizzard has it
-- somewhere else in combat it can't catch clicks or hovers meant for what's under it
-- there. Protected on a protected frame, so out of combat only.
function TB:DisableBarMouse()
	if st:QueueAfterCombat('totembar_mouse', function() self:DisableBarMouse() end) then return end
	getmetatable(self.bar).__index.EnableMouse(self.bar, false)
end

-- The holder's hooks and mover, on a shaman (see the top of this file). Once. After a
-- /reload in combat the holder is still placed straight away, as nothing is anchored to it
-- yet (the button layout waits for the end of combat), so it isn't protected. The bar and
-- its mouse wait for the end of combat.
function TB:SetupPosition()
	local bar, holder = self.bar, self.holder
	if not holder then return end

	-- Every placement of the holder (ApplyHolder, and a drag, which calls its SetPoint) puts
	-- the bar at its new spot. ClearAllPoints needs no hook: SetPoint follows it.
	hooksecurefunc(holder, 'SetPoint', function() self:AnchorBar() end)
	-- The holder's mover keeps it inside the screen edge margin, and a new margin can move
	-- where it shows without its SetPoint (st:UpdateScreenMargin).
	hooksecurefunc(st, 'UpdateScreenMargin', function() self:AnchorBar() end)

	-- Blizzard's Edit Mode places the bar through these on every layout load, and in its
	-- default position on every bottom bar update, and after a snap break. Put it back at
	-- the holder's spot after each, or, while the profile has no position, take its new
	-- spot once Blizzard is done.
	local function PutBack()
		if self.config.position then
			self:AnchorBar()
		else
			self:QueueCapture()
		end
	end
	hooksecurefunc(bar, 'ClearAllPoints', PutBack)
	hooksecurefunc(bar, 'SetPoint', PutBack)

	-- Blizzard's Edit Mode box for the bar, hidden from its next show, and now. Not
	-- secure, so hiding it is safe in combat.
	st:HideEditModeSelection(bar)
	if bar.Selection then bar.Selection:Hide() end

	self:DisableBarMouse()

	-- A shaman whose bar is hidden at login (no totems yet, or in a vehicle) gets it
	-- placed by Blizzard later, through the hooks above. A bar moved in Blizzard's Edit
	-- Mode isn't re-placed when it shows, so its showing tries too (the capture waits for
	-- it, if it can't read the hidden bar's spot). PLAYER_ENTERING_WORLD also tries, after
	-- every loading screen. On the holder: totemtimers.lua has TB's own
	-- PLAYER_ENTERING_WORLD, and AceEvent keeps one handler per event. Each is a no-op once
	-- the profile has a position.
	bar:HookScript('OnShow', function() self:QueueCapture() end)
	holder:RegisterEvent('PLAYER_ENTERING_WORLD')
	holder:SetScript('OnEvent', function() self:QueueCapture() end)

	self:ApplyHolder()
	self:QueueCapture()

	st:RegisterMover('totembar', {
		frame = holder,
		label = 'Totem Bar',
		getPosition = function() return self:GetPosition() end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyHolder() end,
		configPath = { 'TotemBar', 'general' },
	})
end
