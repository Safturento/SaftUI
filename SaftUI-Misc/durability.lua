local st = SaftUI
local DUR = st:NewModule('Durability')

--[[
	Makes Blizzard's armour durability figure (DurabilityFrame: the little gold
	armoured man that shows while gear is damaged or broken) a SaftUI mover.
	Its tooltip is durabilitytooltip.lua.

	How Blizzard places it (Blizzard_DurabilityFrame; the same files on Forever
	and retail, checked 2026-11-14 against the forever and live branches of
	Gethe/wow-ui-source):
	  - It's a right managed frame (RightManagedFrameTemplate, layoutIndex 9) and
	    an Edit Mode system (EditModeDurabilityFrameSystemTemplate), 60 by 75, its
	    width 58 to 92 as the weapon and shield pieces show. SetAlerts, on
	    UPDATE_INVENTORY_ALERTS and PLAYER_ENTERING_WORLD, shows and hides it.
	  - Each time it shows, RightManagedFrameContainer (ManagedFrameMixin:OnShow
	    -> AddManagedFrame -> UpdateFrame) clears its anchors, makes it the
	    container's child and runs the container's Layout, which puts it at the
	    container's top right (VerticalLayoutFrame, align right: ClearAllPoints,
	    then one SetPoint('TOPRIGHT', -x, -y)). The container is laid out again
	    on every ManageFramePositions. The frame stays in the container's layout
	    for as long as it shows, so it keeps its room in the column.
	  - Once moved in Blizzard's Edit Mode (systemInfo.isInDefaultPosition false)
	    the container lets go of it and ApplySystemAnchor puts it on UIParent.
	Its SetPoint and ClearAllPoints are Edit Mode's Lua overrides
	(EditModeSystemMixin:OnSystemLoad), which write Edit Mode state; this file
	never calls them (st:SetPointDirect, st:ClearAllPointsDirect). Nothing in
	its code is protected, and it has no OnSizeChanged.

	SaftUI's holder (SaftUIDurabilityHolder) is the mover and the /sui Position,
	60 by 75 (the XML's size). Once the player has moved it, the figure's top
	right corner goes on the holder's, anchored to the figure's own parent (the
	right container, or UIParent), never to the holder, with the plain widget
	methods: its one point is the one Blizzard's layout sets (TOPRIGHT), so each
	of Blizzard's SetPoint calls replaces SaftUI's, and a post-hook puts it back.
	Nothing is reparented, hidden or taken out of the container, so the
	container's layout isn't touched: it still counts the figure, and the room
	it takes in the column stays where it was while the figure is shown. SaftUI
	never sizes it or sets its scale (Edit Mode's Size setting, which the figure
	keeps), and writes nothing onto it.

	Until then SaftUI moves nothing. durability.position has no default (AceDB
	fills defaults in, so one couldn't be told from a position the user set; the
	objective tracker's works the same way): with none saved the figure stays
	wherever Blizzard puts it, and the holder follows it, so edit mode's outline
	sits on the figure while it shows, and where it last was while it's hidden
	(Show hidden). The follow reads the figure's rect, which is safe here (the
	frame has no script on a size change), and does it on the next frame after
	Blizzard's re-place, never inside it.

	The Move the durability figure setting (default on) off puts the figure back
	where Blizzard last put it (the anchor Blizzard's own SetPoint call gave,
	kept from the post-hook, and re-set with the plain methods) and leaves it
	alone after that. Blizzard's Edit Mode box (Selection) is kept hidden, so its
	Edit Mode can't drag it either; its Size setting keeps its value.

	Placing the figure is refused in combat only if the game counts it as
	protected (it isn't); then it waits for the end of combat and shows where
	Blizzard put it until then.
]]

-- The holder's size: the figure's own (the XML's Size).
local HOLDER_WIDTH, HOLDER_HEIGHT = 60, 75

-- Where the holder waits while the figure has never shown: the right column's
-- top, 260 below the screen's top on both clients (the figure has no top padding,
-- unlike Forever's tracker), and 5 in from the right (RightManagedFrameContainer).
local function FallbackPosition()
	return {
		point = 'TOPRIGHT',
		frame = 'UIParent',
		rel_point = 'TOPRIGHT',
		x_off = -5,
		y_off = -260,
	}
end

local function Plain(...)
	for i = 1, select('#', ...) do
		local value = select(i, ...)
		if value == nil or issecretvalue(value) then return false end
	end
	return true
end

-- Where the figure was last seen on screen, as a position (its top right corner
-- on UIParent's). nil until it has been read once.
local followed

-- The figure's top right corner on UIParent's, in UIParent's units, or nil
-- while it isn't shown or anything can't be read.
local function FigureCorner(frame)
	if not frame:IsShown() then return end
	local right, top, scale = frame:GetRight(), frame:GetTop(), frame:GetEffectiveScale()
	local parentRight, parentTop, parentScale = UIParent:GetRight(), UIParent:GetTop(), UIParent:GetEffectiveScale()
	if not Plain(right, top, scale, parentRight, parentTop, parentScale) or parentScale == 0 then return end
	return right * scale / parentScale - parentRight, top * scale / parentScale - parentTop
end

-- The holder's position: the profile's, else where the figure is (was last), else
-- the column's top. The edit mode mover and /sui Position change the table this
-- hands them and save it, so a first move saves a position. A position saved by
-- an earlier build can lack keys (AceDB drops the ones equal to a default), so any
-- missing one comes from the fallback.
function DUR:GetPosition()
	local position = self.config.position
	local base = FallbackPosition()
	if followed then
		base.x_off, base.y_off = followed.x_off, followed.y_off
	end
	if not position then return base end
	for key, value in pairs(base) do
		if position[key] == nil then position[key] = value end
	end
	return position
end

-- Whether SaftUI places the figure: the setting is on and there is a position.
function DUR:Placing()
	return self.config.move and self.config.position ~= nil
end

-- How far past the screen edge margin the holder may go. While the holder only
-- follows an unmoved figure it may sit as near the right and top edges as the
-- figure does (Blizzard puts it 5 in from the right, the margin is 20), so the
-- outline sits exactly on the figure; the margin applies once a place is saved
-- (a drag's own limit is the margin).
function DUR:MarginReach()
	if self:Placing() or not followed then return 0, 0, 0, 0 end
	local margin = st.config.profile.misc.clamp_inset
	return 0, math.min(0, -followed.x_off - margin), math.min(0, -followed.y_off - margin), 0
end

-- Sizes and places the holder; its SetPoint hook puts the figure there.
function DUR:ApplyHolder()
	local holder = self.holder
	if not holder then return end
	st:KeepInScreenMargin(holder)
	st:PlaceHolder(holder, 'durability_holder',
		function() return HOLDER_WIDTH, HOLDER_HEIGHT end,
		function() return self:GetPosition() end)
	self:PlaceFigure()
end

-- The anchor Blizzard last gave the figure (its SetPoint's arguments), kept to put
-- it back when the setting goes off. nil until one is known.
local blizzardPoint

-- Whether the figure is at SaftUI's anchor now (set by PlaceFigure, cleared when
-- Blizzard re-places it or SaftUI gives it back).
local placed = false

-- Whether the figure already hangs where PlaceFigure would put it (each
-- re-anchor makes the game lay its subtree out again, and Blizzard sets it
-- more than once in one container update).
local function PlacedAt(frame, parent, x, y)
	if frame:GetNumPoints() ~= 1 then return false end
	local point, relativeTo, relativePoint, px, py = frame:GetPoint(1)
	return Plain(point, relativePoint, px, py) and point == 'TOPRIGHT' and relativeTo == parent
		and relativePoint == 'TOPRIGHT' and px == x and py == y
end

-- Puts the figure's top right corner on the holder's, anchored to the figure's
-- parent, in whole pixels. A frame whose edges can't be read yet (or are secret)
-- leaves it as it is.
function DUR:PlaceFigure()
	local frame, holder = self.frame, self.holder
	if not (frame and holder) then return end
	if not self:Placing() then
		-- The place was cleared (edit mode's Undo, a profile with none) or the
		-- setting went off while the figure is still where SaftUI put it.
		if placed then
			self:ReleaseFigure()
			self:QueueFollow()
		end
		return
	end
	if not st:CanMoveNow(frame) and st:QueueAfterCombat('durability_place', function() self:PlaceFigure() end) then
		return
	end
	local parent = frame:GetParent() or UIParent
	local right, top, parentRight, parentTop = holder:GetRight(), holder:GetTop(), parent:GetRight(), parent:GetTop()
	local scale, parentScale, figureScale = holder:GetEffectiveScale(), parent:GetEffectiveScale(), frame:GetEffectiveScale()
	if not Plain(right, top, parentRight, parentTop, scale, parentScale, figureScale) or figureScale == 0 then return end
	local x = (right * scale - parentRight * parentScale) / figureScale
	local y = (top * scale - parentTop * parentScale) / figureScale
	x, y = st:RoundToPixel(x, frame), st:RoundToPixel(y, frame)
	if PlacedAt(frame, parent, x, y) then return end
	st:ClearAllPointsDirect(frame)
	st:SetPointDirect(frame, 'TOPRIGHT', parent, 'TOPRIGHT', x, y)
	placed = true
end

-- Puts the figure back where Blizzard last put it (setting turned off).
function DUR:ReleaseFigure()
	local frame = self.frame
	if not frame then return end
	if not blizzardPoint then
		placed = false
		return
	end
	if not st:CanMoveNow(frame) and st:QueueAfterCombat('durability_place', function() self:ReleaseFigure() end) then
		return
	end
	placed = false
	st:ClearAllPointsDirect(frame)
	st:SetPointDirect(frame, unpack(blizzardPoint, 1, blizzardPoint.n))
end

-- Reads where the figure is now, once the frame after Blizzard has placed it,
-- and moves the holder there while the profile has no position (or the setting
-- is off). Asked for from the post-hook on Blizzard's SetPoint, where the figure
-- can sit between two of Blizzard's anchors, however often in one frame.
local followQueued = false
function DUR:QueueFollow()
	if followQueued or not self.holder then return end
	followQueued = true
	C_Timer.After(0, function()
		followQueued = false
		self:Follow()
	end)
end

function DUR:Follow()
	local frame = self.frame
	if not frame or self:Placing() then return end
	local x, y = FigureCorner(frame)
	if not x then return end
	x, y = st:RoundToPixel(x, self.holder), st:RoundToPixel(y, self.holder)
	if followed and followed.x_off == x and followed.y_off == y then return end
	followed = { x_off = x, y_off = y }
	self:ApplyHolder()
end

function DUR:Setup()
	if self.holder then return end
	local frame = _G.DurabilityFrame
	self.frame = frame

	local holder = CreateFrame('Frame', st.name .. 'DurabilityHolder', UIParent)
	self.holder = holder

	-- Every placement of the holder puts the figure at its new spot.
	hooksecurefunc(holder, 'SetPoint', function() self:PlaceFigure() end)
	-- A new margin can move where the holder shows without its SetPoint.
	hooksecurefunc(st, 'UpdateScreenMargin', function() self:PlaceFigure() end)

	-- Blizzard places the figure through SetPoint (the container's layout, a
	-- layout apply). SaftUI's own placements use the plain methods, which this
	-- hook never sees, so every call it hears is Blizzard's: its anchor is kept,
	-- and the figure goes back on the holder, or the holder follows the figure.
	hooksecurefunc(frame, 'SetPoint', function(_, ...)
		blizzardPoint = { n = select('#', ...), ... }
		placed = false -- Blizzard's call replaced SaftUI's anchor
		if self.config.move then
			if self:Placing() then
				self:PlaceFigure()
			else
				self:QueueFollow()
			end
		end
	end)

	-- Blizzard's Edit Mode box, hidden from its next show, and now. Not secure,
	-- so hiding it is safe in combat. Only while SaftUI moves the figure.
	if self.config.move then
		st:HideEditModeSelection(frame)
		if frame.Selection then frame.Selection:Hide() end
	end

	-- Where Blizzard has it now (a one-point anchor), for putting it back.
	if frame:GetNumPoints() == 1 then
		local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
		if Plain(point, relativePoint, x, y) then blizzardPoint = { n = 5, point, relativeTo, relativePoint, x, y } end
	end

	self:SetupTooltip()
	self:ApplyHolder()
	self:QueueFollow()
	self.mover = st:RegisterMover('durability', {
		frame = holder,
		label = 'Durability',
		getPosition = function() return self:GetPosition() end,
		-- What the profile holds, nil while it has none (getPosition makes one up): the
		-- edit mode history puts "none" back with this and setPosition(nil).
		getSavedPosition = function() return self.config.position end,
		setPosition = function(position) self.config.position = position end,
		apply = function() self:ApplyHolder() end,
		configPath = { 'Durability', 'general' },
		module = 'Misc',
		isDisabled = function() return not self.config.move end,
		-- Blizzard's figure, read only: it shows only while armour is damaged.
		isHidden = function() return not frame:IsShown() end,
		noDefaultReason = "The durability figure has no default place of its own: Blizzard stacks it in its right column, wherever its container puts it. Undo goes back to where it was, and turning off Move the durability figure leaves it to Blizzard.",
	})
	st:KeepInScreenMargin(holder, function() return self:MarginReach() end)
	self:PlaceFigure()
	st.EditModeFrames:On('Enabled', function() self:Follow() end)
end

-- A profile change, or the setting: the holder from the profile, and the figure on it
-- or back with Blizzard.
function DUR:UpdateConfig()
	if not self.holder then return end
	local frame = self.frame
	if self.config.move then
		st:HideEditModeSelection(frame)
		if frame.Selection then frame.Selection:Hide() end
		self:ApplyHolder()
		self:QueueFollow()
	else
		self:ReleaseFigure()
	end
end

function DUR:OnEnable()
	st:BindModuleConfig(self, 'durability')
	if _G.DurabilityFrame then
		self:Setup()
	elseif C_AddOns.DoesAddOnExist('Blizzard_DurabilityFrame') then
		st:OnBlizzardAddon('Blizzard_DurabilityFrame', function() self:Setup() end)
	end
end

-- The Durability page in /sui: the two settings, then its Position. Clicking the
-- figure's outline in edit mode opens it (the mover's configPath). Absent until
-- the figure exists.
function DUR:GetConfigTable()
	if not self.holder then return end
	local generators = st.Config.generators

	-- The figure is placed from the holder: anchoring the holder to it, or to a
	-- frame anchored to it, would move the figure with its own spot.
	local position = generators.position(1000, true,
		function(key) return self:GetPosition()[key] end,
		function(key, value)
			local position = self:GetPosition()
			position[key] = value
			self.config.position = position
			self:ApplyHolder()
		end,
		function() return self.holder end,
		"Where the durability figure's top right corner is. Until you move it, the figure stays where Blizzard puts it, in its column under the minimap.")
	local validate = position.validate
	position.validate = function(info, part, value)
		if part == 'frame' and value == 'DurabilityFrame' then
			return "The durability figure's position can't be anchored to the figure itself."
		end
		return validate(info, part, value)
	end

	return {
		name = 'Durability',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionslayout.lua)
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				saved = st.Config.SavedIn('durability'),
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:UpdateConfig()
				end,
				args = {
					move = {
						order = 1,
						name = 'Move the durability figure',
						type = 'toggle',
						desc = "Lets you move Blizzard's durability figure (the armoured man that shows when gear is damaged) in edit mode and below. Off, it stays wherever Blizzard puts it and its edit mode outline is turned off. Blizzard's own Edit Mode box for it is kept hidden once this has been on, until a reload.",
					},
					tooltip_details = {
						order = 2,
						name = 'Durability details in its tooltip',
						type = 'toggle',
						desc = "Adds to the figure's tooltip each damaged item's durability, lowest first, and what repairing everything costs. Applies at once.",
					},
					position = position,
				},
			},
		},
	}
end
