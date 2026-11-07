local st = SaftUI

-- SaftUI's own edit mode, exposed as st.EditModeFrames.
local EM = st:NewModule('EditMode')
st.EditModeFrames = EM

EM.movers = {}
EM.active = false
EM.selected = nil

local callbacks = {}

-- Registers fn for event ('PositionChanged', 'Selected', 'Enabled', 'Disabled').
function EM:On(event, fn)
	callbacks[event] = callbacks[event] or {}
	table.insert(callbacks[event], fn)
end

function EM:Fire(event, ...)
	local list = callbacks[event]
	if not list then return end
	for _, fn in ipairs(list) do
		fn(...)
	end
end

function EM:IsActive()
	return self.active
end

function EM:Activate()
	if self.active then return end
	if InCombatLockdown() then
		st:Print("Can't open edit mode in combat.")
		return
	end
	self.active = true
	for _, mover in pairs(self.movers) do
		mover.overlay:Show()
	end
	self:UpdateKeyboard()
	self:Fire('Enabled')
	st:Print('Edit mode on.')
end

function EM:Deactivate()
	if not self.active then return end
	self.active = false
	for _, mover in pairs(self.movers) do
		self:StopDrag(mover)
		mover.overlay:Hide()
	end
	self:Select(nil)
	self:UpdateKeyboard()
	self:Fire('Disabled')
	st:Print('Edit mode off.')
end

function EM:Toggle()
	if self.active then
		self:Deactivate()
	else
		self:Activate()
	end
end

function EM:OnInitialize()
	-- Follow Blizzard's Edit Mode. Only listen; never touch its frames.
	EventRegistry:RegisterCallback('EditMode.Enter', function() self:Activate() end, self)
	EventRegistry:RegisterCallback('EditMode.Exit', function() self:Deactivate() end, self)
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
end

function EM:PLAYER_REGEN_DISABLED()
	if not self.active then return end
	self:Deactivate() -- stops any drag, committing the last applied offset
	st:Print('Edit mode closed: entering combat.')
end

-- Writes the (rounded) offsets into the mover's stored position and re-applies it.
function EM:CommitPosition(mover, x, y)
	local def = mover.def
	x = st:RoundToPixel(x, def.frame)
	y = st:RoundToPixel(y, def.frame)
	local pos = def.getPosition()
	pos.x_off = x
	pos.y_off = y
	def.setPosition(pos)
	def.apply()
	self:Fire('PositionChanged', mover)
end

-- Start of a profile change: clears every mover frame's anchors. Movers can be
-- anchored to each other, and placing them one by one while some still hold
-- the old profile's anchors could form a loop (SetPoint errors). With every
-- frame cleared first, they can be placed in any order. Config:UpdateConfig
-- runs this before any module updates, and EM:UpdateConfig places them all.
-- A frame that can't be moved now (in combat, and protected: see
-- st:CanMoveNow) keeps its anchors; EM:UpdateConfig leaves it for after combat.
-- No loop can form around it: whatever it's anchored to is protected too.
-- Each frame's anchors are kept first, for EM:UpdateConfig to put back if
-- placing it fails.
function EM:ClearPositions()
	for _, mover in pairs(self.movers) do
		local frame = mover.def.frame
		mover.previousPoints = st:GetPoints(frame)
		if st:CanMoveNow(frame) then
			frame:ClearAllPoints()
		end
	end
end

-- A profile change: every mover's frame goes to the new profile's position.
-- A drag in progress is dropped without committing, since its start offsets
-- came from the old profile. Config:UpdateConfig runs this after every other
-- module's UpdateConfig, so it has the last word on positions. In combat a
-- protected mover frame gets its position when combat ends.
--
-- An apply that errors is reported, and the movers after it are still placed.
-- If it left its frame with no anchors (ClearPositions cleared them), the
-- frame gets its anchors from before the profile change back. That waits until
-- every other mover is placed, so none of them is placed onto restored anchors
-- that point back at it.
function EM:UpdateConfig()
	local failed = {}
	for key, mover in pairs(self.movers) do
		if mover.drag then
			mover.drag = nil
			mover.overlay:SetScript('OnUpdate', nil)
		end
		local def = mover.def
		st:SafeReposition(def.frame, 'mover_' .. key, function()
			if not xpcall(def.apply, geterrorhandler()) then
				failed[mover] = true
			end
		end)
	end
	-- A deferred apply runs after combat; st:SafeReposition's queue restores
	-- anchors the same way there.
	for mover in pairs(failed) do
		st:RestorePoints(mover.def.frame, mover.previousPoints)
	end
end

-- Shows the mover's section in /sui, opening /sui if it's closed.
function EM:ShowSettings(mover)
	local path = mover.def.configPath
	if path then
		st.Config:Open(unpack(path))
	end
end

-- Selecting a frame shows its settings. Deselecting leaves /sui as it is.
EM:On('Selected', function(mover)
	if mover then
		EM:ShowSettings(mover)
	end
end)

-- Registers a movable frame. def = { frame, label, getPosition, setPosition,
-- apply, configPath }; configPath is the option keys from the /sui root to the
-- frame's section, e.g. { 'Minimap', 'general' }. apply can run in combat.
-- def.configPath is the option keys from the /sui root to the group shown
-- when the frame is clicked, e.g. { 'Minimap', 'general' }.
function st:RegisterMover(key, def)
	assert(type(key) == 'string', 'RegisterMover: key must be a string')
	assert(def and def.frame and def.getPosition and def.setPosition and def.apply,
		'RegisterMover: def needs frame, getPosition, setPosition and apply')
	return EM:CreateMover(key, def)
end
