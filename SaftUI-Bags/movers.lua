local st = SaftUI
local INV = st:GetModule('Inventory')

-- The bag and bank windows as edit mode movers.
--
-- Each window has an anchor frame (SaftUIBagsAnchor_<id>) that owns the
-- window's position. The window is anchored to it at the same point, and the
-- anchor is sized like the window, so the two cover the same rectangle. The
-- anchor is what the mover moves: it always exists and is always shown, so a
-- window that is closed, or not made yet (the bank is built the first time it
-- opens), still has an outline in edit mode and can be placed.

local ANCHOR_PREFIX = st.name .. 'BagsAnchor_'

-- Every window that can have a position, in the order /sui lists them.
local WINDOW_IDS = { 'bag', 'bank', 'combinedbank', 'warband' }

local WINDOW_LABELS = {
	bag = 'Bags',
	bank = 'Bank',
	combinedbank = 'Combined Bank',
	warband = 'Warband Bank',
}
INV.windowIds = WINDOW_IDS
INV.windowLabels = WINDOW_LABELS

INV.anchors = {}
INV.moverIds = {}

-- The size INV:UpdateConfig(id) gives a window before its first layout: the
-- configured width, 200 tall.
local function ConfiguredSize(self, id)
	local config = self.config
	local inner = (config.buttonwidth + config.buttonspacing) * config[id].perrow - config.buttonspacing
	return config.padding * 2 + inner, 200
end

--[[
	Positions used to be arrays: { point, x, y } or { point, frame, rel_point,
	x, y }. They are { point, frame, rel_point, x_off, y_off } now. A profile
	saved before that still holds the array (the defaults fill the named fields
	in beside it), so convert it in place, keeping the spot it described. Plain
	table writes, safe in combat. Does nothing for a position already converted.
]]
-- The array-style defaults positions had before they moved to the named shape.
-- AceDB saves only the slots that differ from the default, so a saved array can
-- be missing any slot (e.g. { [2] = -100 }); the gaps come from these.
local OLD_ARRAY_DEFAULTS = {
	bag = { 'BOTTOMRIGHT', -20, 20 },
	bank = { 'TOPLEFT', 200, -200 },
	combinedbank = { 'TOPLEFT', 200, -200 },
	reagent = { 'TOPLEFT', 'SaftUIBank', 'TOPRIGHT', 20, 0 },
	warband = { 'TOPLEFT', 'SaftUIBank', 'TOPRIGHT', 20, 0 },
}

local function HasArraySlots(position)
	for key in pairs(position) do
		if type(key) == 'number' then return true end
	end
	return false
end

function INV:MigratePosition(id)
	local settings = self.config and self.config[id]
	local position = settings and settings.position
	if type(position) ~= 'table' or not HasArraySlots(position) then return end

	local old = OLD_ARRAY_DEFAULTS[id] or {}
	local function slot(i)
		if position[i] ~= nil then return position[i] end
		return old[i]
	end
	local point, second, third, fourth, fifth = slot(1), slot(2), slot(3), slot(4), slot(5)
	if point == nil then return end
	local frame, relPoint, x, y
	if type(second) == 'string' then
		frame, relPoint, x, y = second, third or point, fourth, fifth
	else
		-- { point, x, y }: relative to the screen, same point on both.
		frame, relPoint, x, y = 'UIParent', point, second, third
	end

	for key in pairs(position) do
		if type(key) == 'number' then position[key] = nil end
	end
	position.point = point
	position.frame = frame
	position.rel_point = relPoint
	position.x_off = tonumber(x) or 0
	position.y_off = tonumber(y) or 0
end

function INV:MigratePositions()
	for _, id in ipairs(WINDOW_IDS) do
		self:MigratePosition(id)
	end
	self:MigratePosition('reagent') -- no window yet, but it has a config entry
end

function INV:GetAnchor(id)
	local anchor = self.anchors[id]
	if not anchor then
		anchor = CreateFrame('Frame', ANCHOR_PREFIX .. id, UIParent)
		anchor:SetSize(ConfiguredSize(self, id))
		self.anchors[id] = anchor
	end
	return anchor
end

-- Places the window's anchor from the profile, and the window on it. The window
-- may be anchored (through its items) to protected frames, which makes the
-- anchor protected too; in combat the move then waits for the end of combat.
function INV:ApplyPosition(id)
	self:MigratePosition(id)
	local anchor = self:GetAnchor(id)

	st:SafeReposition(anchor, 'bags_' .. id, function()
		local point, relative, relPoint, x, y = st:UnpackPoint(self.config[id].position)
		x, y = tonumber(x) or 0, tonumber(y) or 0

		-- A window can be placed relative to another window's anchor; make sure
		-- that one exists so the name resolves.
		for _, otherId in ipairs(WINDOW_IDS) do
			if relative == ANCHOR_PREFIX .. otherId then
				self:GetAnchor(otherId)
			end
		end

		anchor:ClearAllPoints()
		-- A frame that is gone or would make a loop falls back to the screen
		-- instead of leaving the window without a position.
		if not pcall(anchor.SetPoint, anchor, point, st:ResolveFrame(relative) or UIParent, relPoint, x, y) then
			anchor:ClearAllPoints()
			anchor:SetPoint(point, UIParent, relPoint, x, y)
		end

		local container = self.containers[id]
		if container then
			container:ClearAllPoints()
			container:SetPoint(point, anchor, point)
		end
	end)
end

-- Gives the anchor the window's current size (or the size it will start with,
-- if the window isn't made yet).
function INV:SyncAnchorSize(id)
	local anchor = self:GetAnchor(id)
	st:SafeReposition(anchor, 'bags_size_' .. id, function()
		local container = self.containers[id]
		local width, height = ConfiguredSize(self, id)
		if container then
			local containerWidth, containerHeight = container:GetSize()
			if containerWidth > 0 and containerHeight > 0 then
				width, height = containerWidth, containerHeight
			end
		end
		anchor:SetSize(width, height)
	end)
end

-- Windows with a mover on this client, for the layout the profile uses. The bank
-- opens combined or as separate bank and warband windows, never both at once
-- (INV:BANKFRAME_OPENED). The warband window is only made from the separate
-- bank. Reagents have a config entry but no window, so no mover.
function INV:GetMoverIds()
	local ids = { 'bag' }
	if st.retail and self.config.combinedBank then
		tinsert(ids, 'combinedbank')
	else
		tinsert(ids, 'bank')
		if self:HasWarbandBank() then
			tinsert(ids, 'warband')
		end
	end
	return ids
end

-- Registers the movers the profile's layout needs. Safe to call again: a window
-- already registered is left alone. A profile change can switch the bank layout;
-- the new layout's movers join then, and the old layout's stay for the session
-- (there is no unregistering).
function INV:RegisterMovers()
	for _, id in ipairs(self:GetMoverIds()) do
		if not self.moverIds[id] then
			self.moverIds[id] = true
			self:ApplyPosition(id)
			self:SyncAnchorSize(id)

			st:RegisterMover('bags_' .. id, {
				frame = self:GetAnchor(id),
				label = WINDOW_LABELS[id],
				getPosition = function() return self.config[id].position end,
				setPosition = function(position) self.config[id].position = position end,
				apply = function() self:ApplyPosition(id) end,
				configPath = { 'Inventory', id, 'general' },
			})
		end
	end
end
