--[[
	Blizzard's armour durability figure (Blizzard_DurabilityFrame), as far as
	SaftUI's durability.lua and durabilitytooltip.lua read and drive it. Load it
	with `local DF = load_test_file('misc/fixtures/durability_frame.lua')`, then
	DF.build() makes what the game makes when the addon loads. Both clients have
	the same files (checked 2026-11-14 against the forever and live branches of
	Gethe/wow-ui-source), so there is one shape:

	  - DurabilityFrame (DurabilityFrame.xml): a 60 by 75 Frame in LOW strata,
	    created hidden here (SetAlerts hides it until some gear is damaged),
	    inheriting EditModeDurabilityFrameSystemTemplate and
	    RightManagedFrameTemplate. From EditModeSystemTemplate it is clamped to
	    the screen, has its Edit Mode box (Selection, hidden), and has Edit Mode's
	    SetPoint and ClearAllPoints overrides (EditModeSystemMixin:OnSystemLoad),
	    which count Blizzard's calls in DF.calls. isRightManagedFrame is a key of
	    RightManagedFrameTemplate. IsInDefaultPosition is Edit Mode's
	    (systemInfo.isInDefaultPosition). The XML's OnEnter (DurabilityFrameMixin:
	    OnEnter) runs as the frame's own script: while anyItemBroken or
	    anyItemBreaking it makes the tooltip, owned by the frame at
	    ANCHOR_BOTTOMLEFT, with the title "Repair Armor" (REPAIR_ARMOR_TOOLTIP_TITLE),
	    one line (REPAIR_ARMOR_TOOLTIP_BROKEN or REPAIR_ARMOR_TOOLTIP_BREAKING) and
	    a Show. OnLeave hides it while the frame owns it.
	  - RightManagedFrameContainer (Blizzard_ManagedFrameSystem, VerticalLayoutFrame):
	    260 wide at TOPRIGHT -5, -260 of UIParent. Its Layout, while the frame
	    shows in the default position and is its child, clears the frame's anchors
	    and sets TOPRIGHT, -rightOffset, -topOffset (LayoutMixin:LayoutChildren
	    with align right), the top offset being the room the frames above it
	    take (DF.above, 0 when none).
	  - What Blizzard calls: DF.show() (ManagedFrameMixin:OnShow -> AddManagedFrame
	    -> UpdateFrame: ClearAllPoints, SetParent(container), Layout),
	    DF.manage() (a ManageFramePositions: the container placed and laid out
	    again), DF.apply_layout() (EditModeSystemMixin:ApplySystemAnchor for a frame
	    Edit Mode has moved: UIParent as its parent, the saved anchor) and DF.hide().
	Blizzard's code is secure: the game lets it move a protected frame in combat,
	which the stubs can't tell from addon code, so its own calls on the frame
	step out of combat for that call only.

	Every Blizzard frame built here is locked (lib/locked_widget.lua), so a skin
	that writes a field onto one, or SetScripts one, fails. The fixture's own
	writes (Blizzard's) use rawset.

	Not built: the textures of the figure, SetAlerts (DF.show() takes its place),
	the vehicle seat indicator and arena frames it yields to, Edit Mode's other
	settings.
]]

local lock_widget = load_test_file('lib/locked_widget.lua')
local OWNER = 'Blizzard durability frame'

local DF = {}

-- Runs one of Blizzard's own calls on its frames: secure code, which the game
-- lets move a protected frame in combat.
local function secure(fn, ...)
	local combat = stub.in_combat
	stub.in_combat = false
	local results = { fn(...) }
	stub.in_combat = combat
	return unpack(results)
end

DF.above = 0

function DF.build(opts)
	opts = opts or {}
	DF.calls = { SetPoint = 0, ClearAllPoints = 0 }
	DF.above = opts.above or 0

	local container = CreateFrame('Frame', 'RightManagedFrameContainer', UIParent)
	container:SetWidth(260)
	container:SetHeight(300)
	DF.container = container

	local frame = CreateFrame('Frame', 'DurabilityFrame', UIParent)
	frame:SetSize(60, 75)
	frame:SetFrameStrata('LOW')
	frame:SetClampedToScreen(true)
	frame:Hide()
	local selection = CreateFrame('Frame', nil, frame)
	selection:SetAllPoints(frame)
	selection:Hide()
	rawset(frame, 'Selection', lock_widget(selection, 'Blizzard Edit Mode box'))
	rawset(frame, 'layoutIndex', 9)
	rawset(frame, 'isRightManagedFrame', true)
	rawset(frame, 'systemInfo', { isInDefaultPosition = opts.moved == nil })
	rawset(frame, 'anchorInfo', opts.moved)
	rawset(frame, 'IsInDefaultPosition', function(self) return self.systemInfo.isInDefaultPosition end)
	rawset(frame, 'anyItemBroken', false)
	rawset(frame, 'anyItemBreaking', false)

	-- Edit Mode's overrides (SetPointOverride, ClearAllPointsOverride), which
	-- addon code must never call. Blizzard's code calls them, as secure code.
	local methods = getmetatable(frame).__index
	rawset(frame, 'SetPoint', function(self, ...)
		DF.calls.SetPoint = DF.calls.SetPoint + 1
		secure(methods.SetPoint, self, ...)
	end)
	rawset(frame, 'ClearAllPoints', function(self)
		DF.calls.ClearAllPoints = DF.calls.ClearAllPoints + 1
		secure(methods.ClearAllPoints, self)
	end)
	if opts.protected then
		rawset(frame, 'IsProtected', function() return true, true end)
	end

	-- DurabilityFrameMixin:OnEnter and OnLeave, the frame's own scripts.
	frame:SetScript('OnEnter', function(self)
		if self.anyItemBroken or self.anyItemBreaking then
			GameTooltip:SetOwner(self, 'ANCHOR_BOTTOMLEFT')
			GameTooltip:SetText('Repair Armor')
			GameTooltip:AddLine(self.anyItemBroken
				and 'Your armor is broken. Visit a vendor in town to repair it.'
				or 'The durability of your armor is getting low. Visit a vendor in town to repair the item before it breaks.')
			GameTooltip:Show()
		end
	end)
	frame:SetScript('OnLeave', function(self)
		if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
	end)

	-- The container's Layout (LayoutMixin:LayoutChildren, the frame its one
	-- child, aligned right).
	rawset(container, 'Layout', function(self)
		if frame:IsShown() and frame:IsInDefaultPosition() and frame:GetParent() == self then
			frame:ClearAllPoints()
			frame:SetPoint('TOPRIGHT', 0, DF.above == 0 and 0 or -DF.above)
		end
	end)

	DF.frame = lock_widget(frame, OWNER)
	DF.container = lock_widget(container, OWNER)
	DF.manage()
	return DF.frame
end

-- ManageRightFrameContainer: the container placed (x across from the screen's
-- right edge) and laid out again.
function DF.manage(x)
	secure(function()
		local container = DF.container
		container:ClearAllPoints()
		container:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', x or -5, -260)
	end)
	DF.container:Layout()
end

-- The frame showing in its default position: ManagedFrameMixin:OnShow,
-- AddManagedFrame, UpdateFrame. level is 1 (low) or 2 (broken), as
-- GetInventoryAlertStatus says.
function DF.show(broken)
	local frame = DF.frame
	frame.anyItemBroken = broken and true or false
	frame.anyItemBreaking = true
	secure(frame.Show, frame)
	if not frame:IsInDefaultPosition() then return DF.apply_layout() end
	secure(function()
		frame:ClearAllPoints()
		frame:SetParent(DF.container)
	end)
	DF.container:Layout()
end

-- The frame hiding (SetAlerts with nothing damaged).
function DF.hide()
	local frame = DF.frame
	frame.anyItemBroken, frame.anyItemBreaking = false, false
	secure(frame.Hide, frame)
end

-- An Edit Mode layout apply for a frame it has moved: the frame on UIParent at
-- the layout's anchor ({ point, relativePoint, offsetX, offsetY }).
function DF.apply_layout()
	local frame = DF.frame
	secure(function()
		frame:SetParent(UIParent)
		frame:ClearAllPoints()
		local a = frame.anchorInfo
		frame:SetPoint(a.point, UIParent, a.relativePoint, a.offsetX, a.offsetY)
	end)
end

-- Blizzard's Edit Mode moving the frame (a layout apply naming a spot for it).
function DF.edit_mode_moves(anchor)
	local frame = DF.frame
	rawset(frame, 'anchorInfo', anchor)
	frame.systemInfo.isInDefaultPosition = false
	DF.apply_layout()
end

-- Whether widget is one of Blizzard's (the frame, its container, its box).
function DF.is_blizzard(widget)
	return widget == DF.frame or widget == DF.container or widget == DF.frame.Selection
end

return DF
