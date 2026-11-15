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
	    parent, TOPRIGHT, or TOPLEFT beside SaftUI's on its right);
	  - the reads GetParent, GetNumPoints, GetPoint, GetEffectiveScale and
	    IsClampedToScreen (and IsProtected, in combat, through st:CanMoveNow);
	  - post-hooks (hooksecurefunc, each in xpcall to the error handler) on its
	    SetPoint, ClearAllPoints and UpdateHeight, which only run
	    TR:PlaceBlizzard again;
	  - the sections' watch (TR:WatchModules): a post-hook on each module's own
	    Update, which reads the module's state and hasContents and asks for a probe
	    pass on the next frame, and a read of the container's `modules` list, with
	    GetName on a module nobody knows (for the chat line about it);
	  - st:HideEditModeSelection and its Selection's Hide, so Blizzard's Edit Mode
	    can't select it.
	It is never given Hide, Show, SetShown, SetParent, SetScale, a size, a
	roleset, SetAlpha (until Task 12's fade), an unregistered event, or a field;
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
	local x, y = st:CornerOffset(tracker, parent, point, screenX, RevealY(tracker, parent, screenY))
	if not x then return end
	return parent, point, x, y
end

-- Puts Blizzard's tracker at `where` ('concealed', 'place' or 'beside'): the
-- clamp off for concealed and on otherwise, then its one point.
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
