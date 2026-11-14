local st = SaftUI
local OTP = st:NewModule('ObjectiveTracker')

--[[
	Makes Blizzard's objective tracker (ObjectiveTrackerFrame, an Edit Mode system
	on Forever and retail alike) a SaftUI mover, placed from the SaftUI profile.
	The tracker's look is Blizzard_ObjectiveTracker.lua.

	How Blizzard places it:
	  - In its default position it's a right managed frame: each time it shows,
	    RightManagedFrameContainer (the column under the minimap, at TOPRIGHT
	    -5, -260 less the right action bars' width) takes it as its child and
	    lays it out at its own top right, 15 down on Forever (the tracker's
	    topPadding) and 0 on retail, and again on every ManageFramePositions.
	  - Once moved in Blizzard's Edit Mode, ApplySystemAnchor puts it back on
	    UIParent and anchors it from the saved layout.
	  - Its height is Blizzard's (ObjectiveTrackerContainerMixin:UpdateHeight):
	    in the default position its parent's height plus its first point's y
	    offset, so it reaches down to the container's bottom; moved, Edit Mode's
	    Height setting (400 to 1000, else 800). How much of the tracker shows
	    follows from it: Blizzard drops the objectives that don't fit.
	Its SetPoint and ClearAllPoints are Edit Mode's Lua overrides
	(EditModeSystemMixin:OnSystemLoad), which write Edit Mode state; this file
	never calls them.

	SaftUI's holder (SaftUIObjectiveTrackerHolder) is the mover and the /sui
	Position: the tracker's width and its header's height, placed from the
	profile. The tracker hangs from it: its top right corner goes on the
	holder's, anchored to the tracker's own parent (UIParent, or the right
	container in the default position), never to the holder, with the plain
	widget methods (st:ClearAllPointsDirect, st:SetPointDirect). Its anchor to
	its parent keeps Blizzard's height working as Blizzard meant it (in the
	default position it still reaches down to the container's bottom), and
	Blizzard's Edit Mode can read it into its layout (a snap break,
	UpdateSystemAnchorInfo) without naming a frame other characters lack
	(docs/followups.md, "Edit Mode frames anchored straight to SaftUI holders").
	It's put there again whenever the holder is placed (a post-hook on the
	holder's SetPoint: a drag, a nudge, /sui, a profile change), after each of
	Blizzard's re-places (post-hooks on the tracker's ClearAllPoints and
	SetPoint), and after the screen edge margin changes.

	SaftUI never sets the tracker's height, and never reads its size in a way
	that could run its OnSizeChanged (GetWidth(true) and GetHeight(true), which
	skip the rect resolve). Setting the height runs the tracker's OnSizeChanged
	(ObjectiveTrackerContainerMixin:MarkDirty), and from SaftUI's code that
	would write the tracker's dirty flag and schedule its layout tainted. A
	tainted layout that makes a quest item button from the pool writes the
	button's mixin methods tainted, OnClick among them (the click looks it up on
	the button each time, and UseQuestLogSpecialItem is protected), and the pool
	hands that same button out for the rest of the session; it also writes the
	button's charges and rangeTimer tainted, which its OnUpdate reads. (The
	buttons' attributes carry no taint: they're stored in the game, not in
	Lua.) An item used in combat could then be blocked. So there is no Height
	setting, and Blizzard's own (Edit Mode's) can't be reached either, below.

	First load moves nothing. objectivetracker.position has no default (AceDB
	fills defaults in, so one couldn't be told from a position the user set;
	the totem bar's position works the same way, totemposition.lua). With none
	saved the holder waits at Blizzard's default spot (DefaultPosition), the
	tracker's own, unsaved, until it's moved. A tracker the player had moved in
	Blizzard's Edit Mode (systemInfo.isInDefaultPosition false) is left where
	it is, its spot read once the layout has placed it (OTP:CapturePosition)
	and saved as the profile's position, and the holder goes there.

	None of the tracker's frames is secure, so it isn't protected and is put
	back at once, in combat too; should the game count it as protected, the
	re-place waits for the end of combat and the tracker shows where Blizzard
	put it until then.

	The tracker's own clamp keeps its whole rect on screen (Blizzard never gives
	it insets), and it's taller than the holder: so the holder goes no lower
	than the tracker can (its reach below, read again after each of Blizzard's
	UpdateHeight), or the tracker would stop above it.

	Blizzard's Edit Mode box for the tracker (its Selection) is kept hidden, so
	Blizzard's Edit Mode can't select or drag it: its Height, Opacity and Text
	Size settings can't be reached, and keep the values the layout has. Text
	Size and Opacity still apply (the tracker's look replaces Text Size while
	SaftUI's skin is on). State lives on this module; nothing is written onto
	the tracker or any Blizzard table.
]]

-- The holder's height: the tracker's own header's (ObjectiveTrackerContainerHeaderTemplate).
local HOLDER_HEIGHT = 32
local TRACKER_WIDTH = 260 -- ObjectiveTrackerContainerTemplate, if the tracker's can't be read

-- Where Blizzard's default puts the tracker's top right corner: in the right
-- column 260 below the screen's top (275 on Forever, whose tracker sits 15
-- lower in it), and the screen edge margin in from the right.
local function DefaultPosition()
	return {
		point = 'TOPRIGHT',
		frame = 'UIParent',
		rel_point = 'TOPRIGHT',
		x_off = -st.CLAMP_INSET,
		y_off = st.forever and -275 or -260,
	}
end

-- The holder's position: the profile's, or Blizzard's default spot while the
-- profile has none. The edit mode mover and /sui Position change the table
-- this hands them and save it, so a first move saves a position.
function OTP:GetPosition()
	return self.config.position or DefaultPosition()
end

-- Sizes and places the holder from the profile; its SetPoint hook puts the
-- tracker there (PlaceTracker covers a holder already where the profile says).
-- The holder isn't protected (nothing is anchored to it), so it's placed in
-- combat too.
function OTP:ApplyHolder()
	local holder = self.holder
	if not holder then return end
	st:PlaceHolder(holder, 'objectivetracker_holder',
		function() return self.width, HOLDER_HEIGHT end,
		function() return self:GetPosition() end)
	self:PlaceTracker()
end

local function Plain(...)
	for i = 1, select('#', ...) do
		local value = select(i, ...)
		if value == nil or issecretvalue(value) then return false end
	end
	return true
end

-- Whether Blizzard's Edit Mode has the tracker moved from its default
-- position. A read of Blizzard's layout state, nothing is written.
local function Moved(tracker)
	local info = tracker.systemInfo
	return type(info) == 'table' and info.isInDefaultPosition == false
end

-- Whether the tracker already hangs where PlaceTracker would put it: its one
-- point is that, so there's nothing to re-anchor (each re-anchor makes the game
-- lay the tracker's whole subtree out again, and Blizzard re-places it several
-- times in one right column update).
local function PlacedAt(tracker, parent, x, y)
	if tracker:GetNumPoints() ~= 1 then return false end
	local point, relativeTo, relativePoint, px, py = tracker:GetPoint(1)
	return Plain(point, relativePoint, px, py) and point == 'TOPRIGHT' and relativeTo == parent
		and relativePoint == 'TOPRIGHT' and px == x and py == y
end

-- Saves the tracker's spot on screen as the profile's position, if the profile
-- has none and Blizzard's Edit Mode has the tracker moved, and returns whether
-- it did: its top right corner on UIParent's. Read once Blizzard has placed
-- the tracker (OTP:QueueCapture); the tracker is never moved by this.
function OTP:CapturePosition()
	local tracker, holder = self.tracker, self.holder
	if not (tracker and holder) or self.config.position or not Moved(tracker) then return false end
	local right, top, scale = tracker:GetRight(), tracker:GetTop(), tracker:GetEffectiveScale()
	local parentRight, parentTop, parentScale = UIParent:GetRight(), UIParent:GetTop(), UIParent:GetEffectiveScale()
	if not Plain(right, top, scale, parentRight, parentTop, parentScale) or scale == 0 or parentScale == 0 then
		return false
	end
	local ratio = scale / parentScale
	self.config.position = {
		point = 'TOPRIGHT',
		frame = 'UIParent',
		rel_point = 'TOPRIGHT',
		x_off = st:RoundToPixel(right * ratio - parentRight, holder),
		y_off = st:RoundToPixel(top * ratio - parentTop, holder),
	}
	return true
end

function OTP:TryCapture()
	if self:CapturePosition() then self:ApplyHolder() end
end

-- Tries the capture on the next frame, once however often it's asked for in one
-- frame. It's asked for from the post-hooks on Blizzard's re-places, where the
-- tracker can be between two of Blizzard's anchors (a layout load puts it at
-- UIParent's top left, then where the layout says); by the next frame Blizzard
-- is done.
local captureQueued = false
function OTP:QueueCapture()
	if captureQueued or not self.holder or self.config.position then return end
	captureQueued = true
	C_Timer.After(0, function()
		captureQueued = false
		self:TryCapture()
	end)
end

-- Puts the tracker's top right corner on the holder's, anchored to the
-- tracker's parent (see the top of this file), in whole pixels. A frame whose
-- edges can't be read yet (or are secret) leaves the tracker as it is, and so
-- does a tracker Blizzard's Edit Mode has moved while the profile has no
-- position yet: that spot is the profile's first (OTP:CapturePosition).
function OTP:PlaceTracker()
	local tracker, holder = self.tracker, self.holder
	if not (tracker and holder) then return end
	if not self.config.position and Moved(tracker) then
		self:QueueCapture()
		return
	end
	if not st:CanMoveNow(tracker) and st:QueueAfterCombat('objectivetracker_place', function() self:PlaceTracker() end) then
		return
	end
	local parent = tracker:GetParent() or UIParent
	local right, top, parentRight, parentTop = holder:GetRight(), holder:GetTop(), parent:GetRight(), parent:GetTop()
	local scale, parentScale, trackerScale = holder:GetEffectiveScale(), parent:GetEffectiveScale(), tracker:GetEffectiveScale()
	if not Plain(right, top, parentRight, parentTop, scale, parentScale, trackerScale) or trackerScale == 0 then return end
	local x = (right * scale - parentRight * parentScale) / trackerScale
	local y = (top * scale - parentTop * parentScale) / trackerScale
	x, y = st:RoundToPixel(x, tracker), st:RoundToPixel(y, tracker)
	if PlacedAt(tracker, parent, x, y) then return end
	st:ClearAllPointsDirect(tracker)
	st:SetPointDirect(tracker, 'TOPRIGHT', parent, 'TOPRIGHT', x, y)
end

-- How far past the holder's edges the tracker's own clamp keeps the tracker,
-- less the margin, as st:KeepInScreenMargin's reach: below, the tracker's
-- height less the holder's (more if Blizzard ever gives it insets); sideways,
-- what it's wider. 0 where the margin already covers it, or if a size, scale
-- or inset can't be read.
function OTP:TrackerReach()
	local tracker, holder = self.tracker, self.holder
	local clamped = tracker:IsClampedToScreen()
	if issecretvalue(clamped) or not clamped then return 0, 0, 0, 0 end
	local left, right, top, bottom = tracker:GetClampRectInsets()
	local width, height = tracker:GetWidth(true), tracker:GetHeight(true)
	local holderWidth, holderHeight = holder:GetWidth(), holder:GetHeight()
	local scale, holderScale = tracker:GetEffectiveScale(), holder:GetEffectiveScale()
	if not Plain(left, right, top, bottom, width, height, holderWidth, holderHeight, scale, holderScale) or holderScale == 0 then
		return 0, 0, 0, 0
	end
	local k = scale / holderScale
	local margin = st.config.profile.misc.clamp_inset
	local function Past(keptIn, outside) return math.max(0, keptIn * k + outside - margin) end
	return Past(-left, width * k - holderWidth), Past(right, 0), Past(top, 0), Past(-bottom, height * k - holderHeight)
end

-- The holder's margin again, with the tracker's reach now, and the tracker put
-- where the holder shows (the clamp can move it without its SetPoint).
function OTP:KeepInMargin()
	st:KeepInScreenMargin(self.holder)
	self:PlaceTracker()
end

function OTP:Setup()
	if self.holder then return end
	local tracker = _G.ObjectiveTrackerFrame
	self.tracker = tracker

	local width = tracker:GetWidth(true)
	self.width = Plain(width) and width > 0 and width or TRACKER_WIDTH

	local holder = CreateFrame('Frame', st.name .. 'ObjectiveTrackerHolder', UIParent)
	self.holder = holder

	-- Every placement of the holder puts the tracker at its new spot.
	-- ClearAllPoints needs no hook: SetPoint follows it.
	hooksecurefunc(holder, 'SetPoint', function() self:PlaceTracker() end)
	-- A new margin can move where the holder shows without its SetPoint.
	hooksecurefunc(st, 'UpdateScreenMargin', function() self:PlaceTracker() end)

	-- Blizzard places the tracker through these: the right container's layout,
	-- a layout apply, a snap break. It goes back on the holder after each.
	local function PutBack() self:PlaceTracker() end
	hooksecurefunc(tracker, 'ClearAllPoints', PutBack)
	hooksecurefunc(tracker, 'SetPoint', PutBack)
	-- Blizzard's height for it, set again on every layout and ManageFramePositions.
	if type(tracker.UpdateHeight) == 'function' then
		hooksecurefunc(tracker, 'UpdateHeight', function() self:KeepInMargin() end)
	end

	-- Blizzard's Edit Mode box, hidden from its next show, and now. Not secure,
	-- so hiding it is safe in combat.
	st:HideEditModeSelection(tracker)
	if tracker.Selection then tracker.Selection:Hide() end

	-- A tracker moved in Blizzard's Edit Mode gives the profile its first
	-- position before anything is placed (or, if Blizzard hasn't placed it yet,
	-- from the next frame, and after each of its re-places, through PlaceTracker).
	self:CapturePosition()
	self:QueueCapture()

	-- Sized and placed first: the margin's reach reads the holder's size.
	self:ApplyHolder()
	self.mover = st:RegisterMover('objectivetracker', {
		frame = holder,
		label = 'Objective Tracker',
		getPosition = function() return self:GetPosition() end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyHolder() end,
		configPath = { 'ObjectiveTracker', 'general' },
	})
	st:KeepInScreenMargin(holder, function() return self:TrackerReach() end)
	self:PlaceTracker()
end

-- A profile change: the holder from the new profile, and the tracker on it.
function OTP:UpdateConfig()
	self:ApplyHolder()
end

function OTP:OnEnable()
	st:BindModuleConfig(self, 'objectivetracker')
	if _G.ObjectiveTrackerFrame then
		self:Setup()
	elseif C_AddOns.DoesAddOnExist('Blizzard_ObjectiveTracker') then
		st:OnBlizzardAddon('Blizzard_ObjectiveTracker', function() self:Setup() end)
	end
end

-- The skin (a Skinning submodule), which the fonts here restyle the tracker
-- through; nil without it.
local function Skin()
	local SK = st:GetModule('Skinning', true)
	return SK and SK:GetModule('Blizzard_ObjectiveTracker', true)
end

local function SkinOff()
	local skin = Skin()
	return not (skin and skin:IsActive())
end

-- The Objective Tracker page in /sui: General, the tracker's fonts, then its
-- Position. Clicking the tracker in edit mode opens it (the mover's
-- configPath). Absent until the tracker exists.
function OTP:GetConfigTable()
	if not self.holder then return end
	local generators = st.Config.generators

	-- The tracker is placed from the holder: anchoring the holder to it, or
	-- to a frame anchored to it, would move the tracker with its own spot.
	local position = generators.position(1000, true,
		function(key) return self:GetPosition()[key] end,
		function(key, value)
			local position = self:GetPosition()
			position[key] = value
			self.config.position = position
			self:ApplyHolder()
		end,
		function() return self.holder end,
		"Where the objective tracker's top right corner is. The tracker hangs down from here, as tall as Blizzard makes it: in Blizzard's default position down to Blizzard's own bottom line, else the Height last set in Blizzard's Edit Mode.")
	local validate = position.validate
	position.validate = function(info, part, value)
		if part == 'frame' and value == 'ObjectiveTrackerFrame' then
			return "The objective tracker's position can't be anchored to the tracker itself."
		end
		return validate(info, part, value)
	end

	local function FontOption(order, name, desc)
		local option = generators.font(order, desc)
		option.name = name
		option.disabled = SkinOff
		option.disabledDesc = "Only while Skinning -> Objective tracker is on and the Skinning page's Theme isn't Blizzard: otherwise the tracker keeps Blizzard's fonts."
		return option
	end

	return {
		name = 'Objective Tracker',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionslayout.lua)
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					local skin = Skin()
					if skin then skin:UpdateConfig() end
				end,
				args = {
					font = FontOption(1, 'Font',
						"The font of the quest titles, objectives and bar texts in the objective tracker. Texts already showing take it at once; their spacing follows at the tracker's next update."),
					header_font = FontOption(2, 'Header font',
						"The font of the objective tracker's headers: All Objectives, Quests, Campaign, Scenario, Achievements and the rest."),
					position = position,
				},
			},
		},
	}
end
