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
	    ClearAllPoints and SetPoint (TR:PlaceBlizzard only: one anchor to its own
	    parent, TOPRIGHT, or TOPLEFT beside SaftUI's on its right), and a fourth,
	    SetAlpha, for the fade while it shows during a handover
	    (TR:SetBlizzardAlpha only; Edit Mode has no override of it);
	  - the reads GetParent, GetNumPoints, GetPoint, GetEffectiveScale and
	    IsClampedToScreen (and IsProtected, in combat, through st:CanMoveNow), and
	    GetParent, GetHeight(true) and GetEffectiveScale of the Edit Mode spot,
	    which are plain methods on purpose: none has a Lua override on either
	    client (the same overrides list as the three C methods: SetPoint,
	    ClearAllPoints, SetScale, SetShown and Hide), so the plain call is the C
	    one, and the rule's wording (C methods only) is about the writes;
	  - post-hooks (hooksecurefunc, each in xpcall to the error handler) on its
	    SetPoint, ClearAllPoints, UpdateHeight and SetAlpha, which only run
	    TR:PlaceBlizzard or TR:OnBlizzardAlpha (an alpha from outside that lifts
	    the fade is put back; a lower one, Blizzard's 0 or another addon's, stands);
	  - the sections' watch (TR:WatchModules): a post-hook on each module's own
	    Update, which reads the module's state and hasContents and asks for a probe
	    pass on the next frame, and a read of the container's `modules` list, with
	    GetName on a module nobody knows (for the chat line about it);
	  - st:HideEditModeSelection and its Selection's Hide, so Blizzard's Edit Mode
	    can't select it.
	It is never given Hide, Show, SetShown, SetParent, SetScale, a size, a
	roleset, a plain SetAlpha (the fade's is the C method), an unregistered event,
	or a field;
	none of its functions is replaced or wrapped; and none of its methods is
	called (tests/tracker/source_scan_test.lua scans this file and every other
	of the TOC's for the list).

	TR:PlaceBlizzard(where) is the one function that holds the concealment
	(experiment P2: if the game says off screen alone isn't safe, only its
	'concealed' branch changes). The handover (handover.lua) and every later task
	place it only through that.
]]

-- How far past UIParent's left edge the concealed tracker's right edge is, in
-- UIParent units.
TR.BLIZZARD_OFF = 100

-- The least a spot Blizzard's tracker is revealed at (and concealed at, which is
-- the same y) may be above the screen's bottom, in UIParent units. Blizzard works
-- the tracker's height out from its anchor's y (down to the right column's
-- bottom, 20 at the least), so a spot lower than this would give its modules no
-- room. Grow up's window, which hangs from its bottom, is the usual one.
TR.BLIZZARD_FLOOR = 200

-- The places TR:PlaceBlizzard knows: off screen, in SaftUI's place, and beside
-- SaftUI's tracker (the handover's states own, blizzard and both).
local PLACES = { concealed = true, place = true, beside = true }

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

-- The y a spot is revealed at: SaftUI's tracker's, kept off the bottom of the
-- screen (the controller's ruling, for the owner to check: TR.BLIZZARD_FLOOR
-- above it at the least, so the revealed top may be above SaftUI's). Blizzard
-- works the tracker's height out from its anchor's y, down to the right
-- column's bottom and at least 20, so a low spot would give its modules no room
-- and the game's clamp would push a tall one up. A tracker the player moved in
-- Blizzard's Edit Mode is a child of UIParent (not of the right column) with a
-- fixed height, which `GetHeight(true)` gives without lag: its top is raised to
-- keep that height on screen (the clamp would do the same, but the tracker then
-- sits where SaftUI put it and the two never fight). Never above the screen's
-- top. Concealed it is the same y (Ruling 29), so its height is what it will be.
local function RevealY(tracker, parent, screenY)
	local uiScale, bottom, top = UIParent:GetEffectiveScale(), UIParent:GetBottom(), UIParent:GetTop()
	if not (Plain(uiScale, bottom, top) and uiScale > 0) then return screenY end
	local floor = (bottom + TR.BLIZZARD_FLOOR) * uiScale
	if parent == UIParent then
		local height, scale = tracker:GetHeight(true), tracker:GetEffectiveScale()
		if Plain(height, scale) then floor = math.max(floor, bottom * uiScale + height * scale) end
	end
	return TR.Layout.RevealY(screenY, floor, top * uiScale)
end

-- Where Blizzard's tracker goes for `where`: parent, point, x, y for one
-- anchor of its own parent, or nil for a place it doesn't know or a spot that
-- can't be worked out now.
--   'place'      its top right on the window's: the holder's top right for
--                Grow down, the window's for Grow up.
--   'beside'     the beside spot (TR.Layout.BesideSpot): 12 out of the holder on
--                the side nearer the screen's middle, past the item column, level
--                with the holder's top; its top right on the left of SaftUI's, its
--                top left on the right.
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
	local beside = where == 'beside' or (where == 'concealed' and self.config.blizzard.mode == 'beside')
	local spot = beside and self.holder or self:BlizzardSpot()

	local top, right, scale
	if spot then top, right, scale = spot:GetTop(), spot:GetRight(), spot:GetEffectiveScale() end
	local screenY, screenX
	local point = 'TOPRIGHT'
	-- With Grow up the window's top is the holder's bottom and the window's height.
	-- While it is hidden by the handover (handover.lua) SaftUI's list goes on
	-- changing height behind it and Blizzard's tracker must not move with it, so
	-- the height is the one it had when it was hidden (TR.heldHeight), on the
	-- holder's live bottom: a holder that moves (an edit mode drag, a profile) takes
	-- Blizzard's tracker with it, x and y. Grow down hangs from the holder's top,
	-- which is the spot's own.
	if not beside and self.heldHeight and Plain(self.heldHeight) and self.config.grow == 'up' and self.holder then
		local bottom, holderScale = self.holder:GetBottom(), self.holder:GetEffectiveScale()
		if Plain(bottom, holderScale) then top, scale = bottom + self.heldHeight, holderScale end
	end
	if Plain(top, scale) then screenY = top * scale end
	if where == 'place' then
		if not (screenY and Plain(right)) then return end
		screenX = right * scale
	elseif where == 'beside' then
		local left = spot:GetLeft()
		if not (screenY and Plain(left, right, uiScale)) then return end
		-- In the holder's own units, as the item column's side is worked out.
		local holderX, screenMid = spot:GetCenter(), UIParent:GetCenter()
		local side = Plain(holderX, screenMid) and TR.Items.Side(holderX, screenMid) or 'left'
		local column = self:ColumnWidth() * uiScale / scale
		local x, y
		point, x, y = TR.Layout.BesideSpot(left, right, top, side, column)
		screenX, screenY = x * scale, y * scale
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
	screenY = RevealY(tracker, parent, screenY)
	local x, y = st:CornerOffset(tracker, parent, point, screenX, screenY)
	if not x then return end
	-- (the screen spot of the corner is returned too, for the hover: the beside spot's numbers)
	return parent, point, x, y, screenX, screenY
end

------------------------------------------------------------------ the fade and the mouse

-- Whether the mouse is over the place Blizzard's tracker shows at: SaftUI's
-- holder plus the rectangle SaftUI placed it in (CacheRect), while it shows (in
-- SaftUI's place or beside). Never Blizzard's own frame (no rect read of it,
-- .agents/taint.md rule 5). False while it is concealed. Allocates nothing.
function TR:IsBlizzardHovered()
	local where = self.blizzardEffective
	if not self.blizzardFrame or where == nil or where == 'concealed' then return false end
	if self.holder and self.holder:IsMouseOver() then return true end
	local rect = self.blizzardRect
	if not (rect and rect.valid) then return false end
	local cursorX, cursorY = GetCursorPosition()
	if not Plain(cursorX, cursorY) then return false end
	return cursorX >= rect.left and cursorX <= rect.right and cursorY <= rect.top and cursorY >= rect.bottom
end

-- Holds Blizzard's tracker at `alpha` (its C SetAlpha, from the frame's
-- metatable, like the three that place it), or lets it go with nil: its own alpha
-- is Blizzard's (the right column's animations set it to 0 and 1), so a hold sets
-- 1 once when it ends. Only what changed is written. Hold `force` writes it again
-- after one of Blizzard's own calls.
function TR:SetBlizzardAlpha(alpha, force)
	local tracker = self.blizzardFrame
	if not tracker then return end
	if alpha == nil then
		if self.blizzardAlphaSet == nil then return end
		self.blizzardAlphaSet = nil
		getmetatable(tracker).__index.SetAlpha(tracker, 1)
	elseif force or self.blizzardAlphaSet ~= alpha then
		self.blizzardAlphaSet = alpha
		getmetatable(tracker).__index.SetAlpha(tracker, alpha)
	end
end

-- What the fade asks of Blizzard's tracker now: the window's faded alpha while the
-- tracker shows (in SaftUI's place or beside), nothing while it is concealed (it
-- is off screen: not touched, and let go the next time it is revealed unfaded).
-- Called after every placement, every step of the fade, and Blizzard's own SetAlpha.
function TR:SyncBlizzardAlpha(force)
	if not self.blizzardFrame then return end
	local where = self.blizzardEffective
	if where == nil then return end
	if where == 'concealed' then
		-- Off screen: not touched. But if Blizzard set its own alpha meanwhile the
		-- hold is stale (unknown, false), so the next reveal writes it again.
		if force and self.blizzardAlphaSet ~= nil then self.blizzardAlphaSet = false end
		return
	end
	local fx = self.fx
	local alpha = fx and fx.window or 1
	self:SetBlizzardAlpha(alpha < 1 and alpha or nil, force)
end

-- The post-hook's work: `alpha` was just set on Blizzard's tracker from outside.
-- Concealed, the hold goes stale as before (TR:SyncBlizzardAlpha). Shown with a
-- fade held, an alpha above the fade lifts it (Blizzard's 1, or another addon
-- giving it back) and the fade is written again; one below it (0, from Blizzard's
-- hidden UIParent or another addon hiding it) stands, and the hold is marked
-- unknown (false) so SaftUI's own next write, at a fade step or a reveal, is made.
-- With no fade held an outside alpha is never touched.
function TR:OnBlizzardAlpha(alpha)
	if not self.blizzardFrame then return end
	local where = self.blizzardEffective
	if where == nil or where == 'concealed' or type(alpha) ~= 'number' or not Plain(alpha) then
		self:SyncBlizzardAlpha(true)
		return
	end
	local fx = self.fx
	local fade = fx and fx.window or 1
	if fade >= 1 then
		self:SyncBlizzardAlpha(true) -- (lets a hold go; no fade held: nothing is written)
	elseif alpha >= fade then
		self:SyncBlizzardAlpha(true)
	elseif self.blizzardAlphaSet ~= nil then
		self.blizzardAlphaSet = false
	end
end

-- Puts Blizzard's tracker at `where` ('concealed', 'place' or 'beside'): the
-- clamp off for concealed and on otherwise, then its one point, by the three C
-- methods. Nothing is called when its clamp and its one point are already as wanted.
-- Returns false when the move waits for the end of combat (a protected tracker),
-- else its point and screen spot.
local function PlaceAt(self, tracker, where)
	if not st:CanMoveNow(tracker)
		and st:QueueAfterCombat('tracker_blizzard', function() self:PlaceBlizzard(self.blizzardWhere) end) then
		return false -- (waiting for the end of combat: it is where it was)
	end
	local parent, point, x, y, screenX, screenY = self:BlizzardTarget(where)
	if not parent then return end
	local methods = getmetatable(tracker).__index
	local clamp = where ~= 'concealed'
	local clamped = tracker:IsClampedToScreen()
	if issecretvalue(clamped) or (clamped and true or false) ~= clamp then
		methods.SetClampedToScreen(tracker, clamp)
	end
	if not PlacedAt(tracker, parent, point, x, y) then
		methods.ClearAllPoints(tracker)
		methods.SetPoint(tracker, point, parent, point, x, y)
	end
	return point, screenX, screenY
end

-- Blizzard's revealed rectangle as SaftUI placed it, in screen units, cached for
-- the hover (one table, refilled): worked out from the spot SaftUI gave the tracker
-- and the two reads rule 5 allows (`GetWidth(true)`, `GetHeight(true)`), each time
-- it is placed (every layout of Blizzard's re-places it, so a height change
-- follows), never per frame. The controller's ruling (for the owner to check): the
-- hover area is SaftUI's holder plus this rectangle while Blizzard's tracker shows,
-- so Grow up in place, where the tracker hangs below the holder's bottom, is covered.
local function CacheRect(self, tracker, where, point, screenX, screenY)
	local rect = self.blizzardRect
	if not rect then
		rect = {}
		self.blizzardRect = rect
	end
	rect.valid = false
	if where == 'concealed' or not screenX then return end
	local width, height, scale = tracker:GetWidth(true), tracker:GetHeight(true), tracker:GetEffectiveScale()
	if not Plain(width, height, scale) then return end
	width, height = width * scale, height * scale
	rect.left = point == 'TOPLEFT' and screenX or screenX - width
	rect.right = rect.left + width
	rect.top, rect.bottom = screenY, screenY - height
	rect.valid = true
end

-- Puts Blizzard's tracker at `where` ('concealed', 'place' or 'beside').
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
	-- `where` is the place the handover wants; a trigger that hides the tracker
	-- (Fading and hiding, visibility.lua) conceals it whatever the place, and the
	-- place is kept for when the trigger ends.
	self.blizzardWhere = where
	if self.visHidden then where = 'concealed' end
	local point, screenX, screenY = PlaceAt(self, tracker, where)
	-- A protected tracker's move waits for the end of combat (the queued pass
	-- places it and records it): until then it is where it was, so it is not
	-- recorded as revealed (given an alpha, its place counted as the hover) while
	-- it is still off screen, nor as concealed while it still shows.
	if point == false then
		self:SyncBlizzardAlpha()
		return
	end
	self.blizzardEffective = where
	CacheRect(self, tracker, where, point, screenX, screenY)
	-- The fade holds while it shows, and is let go once it is revealed again.
	self:SyncBlizzardAlpha()
end

-- A post-hook that puts Blizzard's tracker back where it should be after one
-- of Blizzard's own calls. It runs inside Blizzard's call, so an error in it
-- goes to the error handler and Blizzard's code goes on.
local function Replace()
	local ok, err = xpcall(function() TR:PlaceBlizzard(TR.blizzardWhere) end, geterrorhandler())
	return ok, err
end

-- The same for an alpha set on the frame from outside. SaftUI's own writes are the
-- C method from the metatable, which this hook (on the frame's own field) never
-- hears, so every call it hears is Blizzard's (the right column: 0 when UIParent
-- hides, 1 when it shows) or another addon's (BigWigs sets it in boss fights; the
-- spec's edge case: SaftUI doesn't fight it). They are told apart by what they do
-- to the fade (TR:OnBlizzardAlpha), never by who called.
local function Realpha(_, alpha)
	local ok, err = xpcall(TR.OnBlizzardAlpha, geterrorhandler(), TR, alpha)
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
	-- The fade (visibility.lua) is put back after Blizzard's own SetAlpha (the right
	-- column fades its frames in and out).
	if type(tracker.SetAlpha) == 'function' then hooksecurefunc(tracker, 'SetAlpha', Realpha) end

	-- Blizzard's Edit Mode box, hidden from its next show, and now. Not secure,
	-- so hiding it is safe in combat.
	st:HideEditModeSelection(tracker)
	if tracker.Selection then tracker.Selection:Hide() end

	self:PlaceBlizzard('concealed')
	self:WatchModules()
end

------------------------------------------------------------------ the sections' watch

-- The modules already hooked, by frame: SaftUI's own table (rule 1: nothing is
-- written onto a Blizzard frame), so a second TR:WatchModules hooks nothing again.
local hooked = setmetatable({}, { __mode = 'k' })

-- The two quest modules, which SaftUI draws and never reads.
local QUEST_MODULES = { 'QuestObjectiveTracker', 'CampaignQuestObjectiveTracker' }

-- The post-hook on a module's own Update. It runs inside Blizzard's layout, so it
-- reads two fields and asks for a probe pass, nothing else; an error in it goes
-- to the error handler and Blizzard's layout goes on.
local function OnModuleUpdate(module)
	local ok, err = xpcall(TR.ModuleUpdated, geterrorhandler(), TR, module)
	return ok, err
end

-- Hooks one module's Update (the frame's own field, which Blizzard looks up at
-- call time on every layout, dirty ones included: the mixin's methods are copied
-- onto the frame, so hooking the mixin table would reach nothing) and reads where
-- it stands now, since it may have laid out before the hook.
local function Watch(self, module, key)
	if hooked[module] then return end
	hooked[module] = true
	self.moduleKeys[module] = key
	if type(module.Update) == 'function' then hooksecurefunc(module, 'Update', OnModuleUpdate) end
	self:ModuleUpdated(module, key)
end

-- The frames SaftUI knows (the nine sections' modules and the two quest ones),
-- one table kept and refilled, so a pass allocates none.
local known = {}

-- Called by TR:SetupBlizzard, and by every probe pass for what a patch may add:
-- the nine sections' modules' Update (the container's own can't be hooked: its
-- dirty update holds a closure of the function; the two quest modules are never
-- hooked), and any frame in the container's `modules` list SaftUI doesn't know,
-- which counts as a section while it has content; the list is walked only when
-- its length changes. Reads and post-hooks only (.agents/taint.md rule 5); a
-- module's name is the C method's, taken from its metatable like the others.
function TR:WatchModules()
	local tracker = self.blizzardFrame
	if not tracker then return end
	for module in pairs(known) do known[module] = nil end
	for _, section in ipairs(TR.SECTIONS) do
		local module = _G[section.module]
		if module then
			known[module] = true
			Watch(self, module, section.key)
		end
	end
	for _, name in ipairs(QUEST_MODULES) do
		local module = _G[name]
		if module then known[module] = true end
	end
	if type(tracker.modules) ~= 'table' or self.moduleCount == #tracker.modules then return end
	self.moduleCount = #tracker.modules
	for index, module in ipairs(tracker.modules) do
		if not known[module] and not hooked[module] then
			local getName = getmetatable(module).__index.GetName
			local key = type(getName) == 'function' and getName(module)
			if type(key) ~= 'string' or key == '' then key = 'Unnamed module ' .. index end
			Watch(self, module, key)
		end
	end
end
