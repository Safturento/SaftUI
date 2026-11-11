local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	SaftUI's nameplates: the 'nameplate' unit (config/units/nameplate.lua),
	drawn by oUF's nameplate driver (oUF:SpawnNamePlates, Libraries/oUF/ouf.lua),
	which UF:OnEnable makes once, after the other units.

	The game makes the plates (NamePlate1, NamePlate2, ...) and reuses each one
	for unit after unit. The first time a plate gets a unit, oUF builds a frame
	of SaftUI's on it with SaftUI's style (UF.ConstructUnit), which fills the
	plate, and UF.InitUnit gives it its first update once oUF has enabled its
	elements. The frame stays on its plate for every later unit, so it's kept
	by the plate's number (UF.nameplates), never by a unit.

	Another nameplate addon (UF.NAMEPLATE_ADDONS) draws the plates instead:
	SaftUI then makes no driver and touches nothing of Blizzard's plates.
	Nothing is written onto Blizzard's plate frames here (.agents/taint.md,
	rule 1). oUF itself writes its frame and style onto each plate (unitFrame,
	style) and blocks Blizzard's own UnitFrame on it on every add.
]]

-- The nameplate addons SaftUI stands down for, in the order they're named to
-- the user: addon is the folder C_AddOns.IsAddOnLoaded knows it by, label the
-- name shown. drawsPlates, where there is one, says whether the addon draws
-- the plates while it's loaded.
UF.NAMEPLATE_ADDONS = {
	{ addon = 'Plater', label = 'Plater' },
	{ addon = 'EllesmereUINameplates', label = 'EllesmereUI Nameplates' },
	{ addon = 'Kui_Nameplates', label = 'KuiNameplates' },
	{ addon = 'TidyPlates_ThreatPlates', label = 'Threat Plates' },
	{ addon = 'NeatPlates', label = 'NeatPlates' },
	{
		addon = 'ElvUI',
		label = 'ElvUI',
		-- ElvUI's nameplates can be turned off in its own options. Only a
		-- setting that says off counts as off: ElvUI loaded with its private
		-- settings not yet set up counts as drawing them.
		drawsPlates = function()
			local E = type(ElvUI) == 'table' and ElvUI[1]
			local private = type(E) == 'table' and E.private
			local nameplates = type(private) == 'table' and private.nameplates
			return not (type(nameplates) == 'table' and nameplates.enable == false)
		end,
	},
}

-- The name of the nameplate addon that draws the plates (the first of
-- UF.NAMEPLATE_ADDONS that's loaded and draws them), or nil for none.
function UF:NameplateAddon()
	for _, entry in ipairs(UF.NAMEPLATE_ADDONS) do
		if C_AddOns.IsAddOnLoaded(entry.addon) and (not entry.drawsPlates or entry.drawsPlates()) then
			return entry.label
		end
	end
end

-- SaftUI's frame on each plate, by the plate's number (frame.ID: NamePlate3's
-- is SaftUI_NamePlate3). UF.ConstructUnit adds each one as oUF builds it.
UF.nameplates = {}

function UF:ForEachPlate(fn)
	for _, frame in pairs(self.nameplates) do
		fn(frame)
	end
end

-- Whether a plate's frame shows its unit now: from oUF's added callback to its
-- removed one. oUF keeps a frame's unit (__unit) after the game takes the
-- plate away, since its remove clears only the unit attribute (and ignores the
-- nil), so __unit alone would still name the unit that left.
local showing = setmetatable({}, { __mode = 'k' })

-- SaftUI's frame showing a unit ('nameplate4'), by its __unit, or nil when
-- no plate of SaftUI's shows it.
function UF:PlateForUnit(unit)
	for _, frame in pairs(self.nameplates) do
		if showing[frame] and frame.__unit == unit then
			return frame
		end
	end
end

-- What other parts of SaftUI do when a plate gets a unit, loses it, or is
-- updated:
--   'added'   fn(frame, unit), after oUF has set the frame's unit and before
--             it updates the elements. Never for a plate that shows only
--             widgets or a game object: oUF hides SaftUI's frame for those.
--   'removed' fn(frame, unit), once oUF has shown the frame again for the
--             plate's next unit (also after a plate that showed only widgets).
--   'updated' fn(frame), after every UF:UpdateUnitFrame on a plate.
local callbacks = { added = {}, removed = {}, updated = {} }

function UF:RegisterPlateCallback(event, fn)
	assert(callbacks[event], 'RegisterPlateCallback: no plate event ' .. tostring(event))
	assert(type(fn) == 'function', 'RegisterPlateCallback: fn must be a function')
	table.insert(callbacks[event], fn)
end

-- Runs event's callbacks with (frame, ...). One that errors is reported and
-- the rest still run.
function UF:RunPlateCallbacks(event, frame, ...)
	for _, fn in ipairs(callbacks[event]) do
		xpcall(fn, geterrorhandler(), frame, ...)
	end
end

-- The size handed to oUF's driver for the config's width and height: the
-- config's, for now.
function UF.PlateDriverSize(width, height)
	return width, height
end

-- Sets every plate's size from the config through oUF's driver. The game has
-- one size for all plates, and refuses it from addon code in combat, so in
-- combat this waits until combat ends. Nothing before the driver is made.
function UF:ApplyPlateSize()
	if not self.plateDriver then return end
	if st:QueueAfterCombat('NameplateSize', function() UF:ApplyPlateSize() end) then return end
	local config = self:GetProfileConfig().nameplate
	self.plateDriver:SetSize(UF.PlateDriverSize(config.width, config.height))
end

-- Makes oUF's nameplate driver, once, so the plates get SaftUI's frames. Does
-- nothing and returns false when the driver is made already, Nameplates is
-- off, or another nameplate addon draws the plates (UF:NameplateAddon); a
-- change to either needs a /reload, since oUF can make its driver only once.
-- Blizzard sets the plates' size again whenever its nameplate options change
-- (NamePlateDriverFrame:UpdateNamePlateSize), so SaftUI's is set again after
-- it, from a post-hook.
function UF:SpawnNameplates()
	if self.plateDriver then return false end
	if not self:GetProfileConfig().nameplate.enable then return false end
	if self:NameplateAddon() then return false end

	local driver = self.oUF:SpawnNamePlates('SaftUI_')
	if not driver then return false end -- oUF reported why
	self.plateDriver = driver

	driver:SetAddedCallback(function(frame, _, unit)
		showing[frame] = true
		UF:RunPlateCallbacks('added', frame, unit)
	end)
	driver:SetRemovedCallback(function(frame, _, unit)
		showing[frame] = nil
		UF:RunPlateCallbacks('removed', frame, unit)
	end)

	self:ApplyPlateSize()
	hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateSize', function() UF:ApplyPlateSize() end)
	return true
end
