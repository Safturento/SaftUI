local st = SaftUI
local TR = st.Tracker

--[[
	Blizzard's objective tracker while SaftUI's is on (design: "Blizzard's
	tracker while SaftUI's is on"). It stays loaded, registered, shown when it
	has content and laying out on its own events, exactly as without SaftUI; it
	is only moved off screen (concealed), never hidden. That keeps everything it
	does untainted (its item buttons, auto-tracking an accepted quest, sorting
	the watch list on a zone change) and keeps SaftUI's calls from running a
	tainted layout of its own (.agents/taint.md rule 5).

	What SaftUI calls on Blizzard's tracker, the whole list:
	  - the three C methods, taken from the frame's metatable so Edit Mode's Lua
	    overrides on the frame object aren't what runs: SetClampedToScreen,
	    ClearAllPoints and SetPoint (TR:PlaceBlizzard only: one anchor, TOPRIGHT
	    to its own parent);
	  - the reads GetParent, GetNumPoints, GetPoint, GetEffectiveScale and
	    IsClampedToScreen (and IsProtected, in combat, through st:CanMoveNow);
	  - post-hooks (hooksecurefunc, each in xpcall to the error handler) on its
	    SetPoint, ClearAllPoints and UpdateHeight, which only run
	    TR:PlaceBlizzard again;
	  - st:HideEditModeSelection and its Selection's Hide, so Blizzard's Edit Mode
	    can't select it.
	It is never given Hide, Show, SetShown, SetParent, SetScale, a size, a
	roleset, SetAlpha (until Task 12's fade), an unregistered event, or a field;
	none of its functions is replaced or wrapped; and none of its methods is
	called (tests/tracker/source_scan_test.lua scans this file and every other
	of the TOC's for the list).

	TR:PlaceBlizzard(where) is the one function that holds the concealment
	(experiment P2: if the game says off screen alone isn't safe, only its
	'concealed' branch changes). Later tasks place it only through that.
]]

-- How far past UIParent's left edge the concealed tracker's right edge is, in
-- UIParent units.
TR.BLIZZARD_OFF = 100

-- The places TR:PlaceBlizzard knows. 'beside' (Task 11) is added there.
local PLACES = { concealed = true, place = true }

-- Whether SaftUI's tracker owns Blizzard's: it is on this session and
-- Blizzard's tracker exists. Misc's mover stands down while it does
-- (Blizzard_ObjectiveTrackerPosition.lua asks at call time).
function TR:OwnsBlizzard()
	return self:IsOn() and _G.ObjectiveTrackerFrame ~= nil
end

local function Plain(...)
	for i = 1, select('#', ...) do
		local value = select(i, ...)
		if value == nil or issecretvalue(value) then return false end
	end
	return true
end

-- Whether the tracker already has the one point (point, parent, point, x, y):
-- then there's nothing to anchor again (each anchor makes the game lay the
-- tracker's whole subtree out again, and Blizzard re-places it several times
-- in one right column update).
local function PlacedAt(tracker, parent, point, x, y)
	if tracker:GetNumPoints() ~= 1 then return false end
	local at, relativeTo, relativePoint, px, py = tracker:GetPoint(1)
	return Plain(at, relativePoint, px, py) and at == point and relativeTo == parent
		and relativePoint == point and px == x and py == y
end

-- The frame whose top right is the spot Blizzard's tracker shows at in
-- SaftUI's place: the holder (Grow down) or the window (Grow up), which hang
-- from each other by the same corner they grow from.
function TR:BlizzardSpot()
	if self.config.grow == 'up' then return self.window end
	return self.holder
end

-- Where Blizzard's tracker goes for `where`: parent, point, x, y for one
-- anchor of its own parent, or nil for a place it doesn't know or a spot that
-- can't be worked out now.
--   'place'      its top right on the window's: the holder's top right for
--                Grow down, the window's for Grow up.
--   'concealed'  the same y as the spot the current mode reveals at (Ruling 29:
--                in place, or beside, whose y is the holder's top), with an x
--                that puts its right edge TR.BLIZZARD_OFF left of UIParent's
--                left edge. Only x differs, so its height, which Blizzard
--                works out from its anchor's y (UpdateHeight), is what it would
--                be revealed.
function TR:BlizzardTarget(where)
	local tracker = self.blizzardFrame
	if not (tracker and PLACES[where] and self.holder) then return end
	local parent = tracker:GetParent() or UIParent
	local uiScale = UIParent:GetEffectiveScale()
	local spot = self:BlizzardSpot()
	if where == 'concealed' and self.config.blizzard.mode == 'beside' then spot = self.holder end

	local top, right, scale
	if spot then top, right, scale = spot:GetTop(), spot:GetRight(), spot:GetEffectiveScale() end
	local screenY, screenX
	if Plain(top, scale) then screenY = top * scale end
	if where == 'place' then
		if not (screenY and Plain(right)) then return end
		screenX = right * scale
	else
		-- Off screen whatever can't be read: the default spot's y stands in.
		local uiTop = UIParent:GetTop()
		if not screenY then
			if not Plain(uiTop, uiScale) then return end
			screenY = (uiTop + st:DefaultTrackerPosition().y_off) * uiScale
		end
		local uiLeft = UIParent:GetLeft()
		if not Plain(uiLeft, uiScale) then return end
		screenX = (uiLeft - TR.BLIZZARD_OFF) * uiScale
	end
	local x, y = st:CornerOffset(tracker, parent, 'TOPRIGHT', screenX, screenY)
	if not x then return end
	return parent, 'TOPRIGHT', x, y
end

-- Puts Blizzard's tracker at `where` ('concealed' or 'place'; Task 11 adds
-- 'beside'): the clamp off for concealed and on otherwise, then its one point.
-- The P2 seam: the only function that holds the concealment, called by the
-- hooks, the handover and the profile's update, and by nothing else. It uses
-- only the three C methods, from the frame's metatable. Nothing is called when
-- its clamp and its one point are already as wanted. Blizzard's tracker isn't
-- protected, so it's placed in combat too; should the game count it as
-- protected, the placement waits for the end of combat and Blizzard's spot
-- shows until then.
function TR:PlaceBlizzard(where)
	local tracker = self.blizzardFrame
	if not (tracker and PLACES[where]) then return end
	self.blizzardWhere = where
	if not st:CanMoveNow(tracker)
		and st:QueueAfterCombat('tracker_blizzard', function() self:PlaceBlizzard(self.blizzardWhere) end) then
		return
	end
	local parent, point, x, y = self:BlizzardTarget(where)
	if not parent then return end
	local methods = getmetatable(tracker).__index
	local clamp = where ~= 'concealed'
	local clamped = tracker:IsClampedToScreen()
	if issecretvalue(clamped) or (clamped and true or false) ~= clamp then
		methods.SetClampedToScreen(tracker, clamp)
	end
	if PlacedAt(tracker, parent, point, x, y) then return end
	methods.ClearAllPoints(tracker)
	methods.SetPoint(tracker, point, parent, point, x, y)
end

-- A post-hook that puts Blizzard's tracker back where it should be after one
-- of Blizzard's own calls. It runs inside Blizzard's call, so an error in it
-- goes to the error handler and Blizzard's code goes on.
local function Replace()
	local ok, err = xpcall(function() TR:PlaceBlizzard(TR.blizzardWhere) end, geterrorhandler())
	return ok, err
end

-- Called by TR:Build: conceals Blizzard's tracker and keeps it there. Through
-- st:OnBlizzardAddon when Blizzard_ObjectiveTracker isn't loaded yet. Once: the
-- hooks never stack however often it is called.
function TR:SetupBlizzard()
	-- Only once the tracker is built (the switch on): while it's off nothing is hooked.
	if not self.built or self.blizzardFrame then return end
	local tracker = _G.ObjectiveTrackerFrame
	if not tracker then
		if not self.blizzardWaiting and C_AddOns.DoesAddOnExist('Blizzard_ObjectiveTracker') then
			self.blizzardWaiting = true
			st:OnBlizzardAddon('Blizzard_ObjectiveTracker', function() self:SetupBlizzard() end)
		end
		return
	end
	self.blizzardFrame = tracker
	self.blizzardWhere = 'concealed'

	-- Blizzard places it through these: the right container's layout, a layout
	-- apply, a snap break (SetPoint, ClearAllPoints), and its height on every
	-- layout (UpdateHeight, which in its default position reads its anchor's y).
	if type(tracker.SetPoint) == 'function' then hooksecurefunc(tracker, 'SetPoint', Replace) end
	if type(tracker.ClearAllPoints) == 'function' then hooksecurefunc(tracker, 'ClearAllPoints', Replace) end
	if type(tracker.UpdateHeight) == 'function' then hooksecurefunc(tracker, 'UpdateHeight', Replace) end

	-- Blizzard's Edit Mode box, hidden from its next show, and now. Not secure,
	-- so hiding it is safe in combat.
	st:HideEditModeSelection(tracker)
	if tracker.Selection then tracker.Selection:Hide() end

	self:PlaceBlizzard('concealed')
end
