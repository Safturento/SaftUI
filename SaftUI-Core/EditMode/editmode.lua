local st = SaftUI

-- SaftUI's own edit mode, exposed as st.EditModeFrames. Its bar across the top
-- of the screen (Bar/) and the other parts listen to its events (EM:On).
local EM = st:NewModule('EditMode')
st.EditModeFrames = EM

EM.movers = {}
EM.active = false
EM.selected = nil

local callbacks = {}

-- Registers fn for event. The events, with what fn gets:
--   'PositionChanged'  mover (a drag's live offsets, a nudge, a commit)
--   'Selected'         mover, or nil when nothing is selected now
--   'Enabled', 'Disabled'  edit mode turned on or off
--   'SettingsChanged'  key, or nil for every setting (a profile change): a
--                      setting of the grid, snapping, Dim world, Coordinates,
--                      Show disabled, Show hidden or the module choice
--                      changed (settings.lua)
--   'Pressed'          mover: the mouse went down on its outline
--   'DragStarted', 'DragStopped'  mover: a drag began, or ended (by a drop, or
--                      dropped by a profile change)
--   'ShownChanged'     no arguments: an overlay was shown or hidden, a selected
--                      mover that stopped showing was deselected, or a mover's
--                      overlap state changed (filter.lua's EM:UpdateShown, which
--                      the ticker runs twice a second: fired only on a change)
--   'ColorsChanged'    group: st:ColorsChanged(group), for every group
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

function EM:Activate()
	if self.active then return end
	if InCombatLockdown() then
		st:Print("Can't open edit mode in combat.")
		return
	end
	self.active = true
	self:UpdateShown() -- filter.lua: the overlays of the movers that show
	self:UpdateKeyboard()
	self:Fire('Enabled')
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
			self:Fire('DragStopped', mover)
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
	-- The new profile has its own grid settings: the grid and the bar follow.
	self:Fire('SettingsChanged')
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
-- apply, configPath, blizzardFrame, module, isDisabled, isHidden,
-- getDefaultPosition, noDefaultReason }; configPath is the option keys from the
-- /sui root to the frame's section, e.g. { 'Minimap', 'general' }. apply can
-- run in combat.
--
-- What the edit mode bar reads (all optional; Core never names a module, so
-- every name comes from a registration):
--   module              the name the bar's Show list gives the mover's addon, in
--                       sentence case ('Action bars', 'Unit frames'). None is
--                       EM.OTHER_MODULE.
--   isDisabled          function() -> boolean, true when a setting turns the
--                       frame off (a disabled bar, a hidden swing timer).
--   isHidden            function() -> boolean, true when the frame is on but not
--                       on screen now (a closed bag window, no pet). Read only
--                       when isDisabled is false.
--   getDefaultPosition  function() -> table | nil, where Reset puts the frame.
--                       EM:GetDefaultPosition copies it on every call.
--   noDefaultReason     a string, why Reset can't run when there is no default.
-- The two predicates only read (IsShown, config, a field of Blizzard's): never
-- Blizzard code that writes (.agents/taint.md rule 3).
--
-- The frame is kept inside the screen edge margin (st:KeepInScreenMargin), and
-- drags and nudges stop at it (mover.lua). def.blizzardFrame says the frame is
-- Blizzard's own, moved with no SaftUI holder (the Minimap): SaftUI never clamps
-- a Blizzard frame, so only its drags and nudges keep to the margin.
function st:RegisterMover(key, def)
	assert(type(key) == 'string', 'RegisterMover: key must be a string')
	assert(def and def.frame and def.getPosition and def.setPosition and def.apply,
		'RegisterMover: def needs frame, getPosition, setPosition and apply')
	local mover = EM:CreateMover(key, def)
	if not def.blizzardFrame then
		st:KeepInScreenMargin(def.frame)
	end
	return mover
end

-- Registers a mover for frame whose position lives at config.position in the
-- profile. spec = { key, config, apply, <anything else st:RegisterMover takes:
-- label, configPath, blizzardFrame, module, isDisabled, isHidden,
-- noDefaultReason, ...> }. spec isn't changed; its other fields go to
-- st:RegisterMover as they are, except frame, getPosition and setPosition, which
-- the helper's own replace, and defaults, which becomes getDefaultPosition:
--   key     the mover's key, as st:RegisterMover's first argument.
--   defaults  optional, the twin of config: a function returning the table that
--           holds the default `position` (function() return st.defaults.chat end).
--           getDefaultPosition returns a copy of its position, or nil. Give
--           defaults or getDefaultPosition, not both.
--   config  a function returning the table that holds the position, called on
--           every read and write, not once, since a profile change replaces
--           the profile's tables (e.g. function() return self.config[id] end).
--   apply   places the frame from the profile, as st:RegisterMover's apply.
-- getPosition returns config().position; setPosition(position) stores the table
-- it's given as config().position. Every other field goes to st:RegisterMover
-- as it is. Returns the mover. A frame whose position needs more than that
-- (migrating it on read, a default when the profile has none) registers with
-- st:RegisterMover.
function st:RegisterConfigMover(frame, spec)
	assert(type(spec) == 'table' and type(spec.config) == 'function',
		'RegisterConfigMover: spec needs a config function')
	local getConfig = spec.config
	local def = {}
	for field, value in pairs(spec) do
		if field ~= 'key' and field ~= 'config' and field ~= 'defaults' then def[field] = value end
	end
	if spec.defaults ~= nil then
		assert(spec.getDefaultPosition == nil, 'RegisterConfigMover: give defaults or getDefaultPosition, not both')
		local defaults = spec.defaults
		def.getDefaultPosition = function()
			local d = defaults()
			return d and d.position and st.tablecopy(d.position, true) or nil
		end
	end
	def.frame = frame
	def.getPosition = function() return getConfig().position end
	def.setPosition = function(position) getConfig().position = position end
	return st:RegisterMover(spec.key, def)
end

-- The module name a mover with none is listed under.
EM.OTHER_MODULE = 'Other'

-- The name of the module a mover belongs to (its registration's `module`).
function EM:MoverModule(mover)
	return mover.def.module or EM.OTHER_MODULE
end

-- Runs a registration's predicate. Only a plain true is true: no predicate, an
-- error (reported to the game's handler), a secret value or anything else is
-- false. A secret is tested before the comparison, which the game refuses.
-- An error is reported once per mover and predicate for a session of edit
-- mode (the ticker asks twice a second: a module's bug must not be a stream).
local reported = setmetatable({}, { __mode = 'k' }) -- mover -> { isDisabled = true, ... }

local function RunPredicate(mover, name)
	local fn = mover.def[name]
	if not fn then return false end
	local ok, value = xpcall(fn, function(err)
		local seen = reported[mover]
		if not seen then
			seen = {}
			reported[mover] = seen
		end
		if not seen[name] then
			seen[name] = true
			geterrorhandler()(err)
		end
		return err
	end)
	if not ok or issecretvalue(value) then return false end
	return value == true
end

EM:On('Disabled', function() wipe(reported) end) -- the session is over

-- True when a setting turns the mover's frame off.
function EM:IsMoverDisabled(mover)
	return RunPredicate(mover, 'isDisabled')
end

-- True when the mover's frame is on but not on screen now.
function EM:IsMoverHidden(mover)
	return RunPredicate(mover, 'isHidden')
end

-- Where Reset puts the mover's frame: a fresh deep copy on every call, so a
-- caller's writes never reach st.defaults. Nil when it has no default (see
-- def.noDefaultReason for why).
function EM:GetDefaultPosition(mover)
	local get = mover.def.getDefaultPosition
	if not get then return nil end
	local ok, position = xpcall(get, geterrorhandler())
	if not ok or type(position) ~= 'table' then return nil end
	return st.tablecopy(position, true)
end
