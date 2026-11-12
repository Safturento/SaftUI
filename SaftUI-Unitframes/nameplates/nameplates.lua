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
	-- Platynator (plusmouse's): its folder name is to be confirmed, since no
	-- public source of it was found to check its TOC against.
	{ addon = 'Platynator', label = 'Platynator' },
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

-- SaftUI's frame showing each unit token, from oUF's added callback to its
-- removed one, so a unit's plate is found without walking every plate (threat
-- events come many times a second in a pull).
local frameOfUnit = {}

-- SaftUI's frame showing a unit ('nameplate4'), or nil when no plate of
-- SaftUI's shows it.
function UF:PlateForUnit(unit)
	local frame = frameOfUnit[unit]
	if frame and showing[frame] and frame.__unit == unit then
		return frame
	end
end

-- Whether a plate's frame shows its unit (frame.__unit) now.
function UF:PlateShowsUnit(frame)
	return showing[frame] == true
end

-- What other parts of SaftUI do when a plate gets a unit, loses it, or is
-- updated:
--   'added'   fn(frame, unit), after oUF has set the frame's unit and before
--             it updates the elements. Never for a plate that shows only
--             widgets or a game object: oUF hides SaftUI's frame for those.
--   'removed' fn(frame, unit), once oUF has shown the frame again for the
--             plate's next unit (also after a plate that showed only widgets).
--   'updated' fn(frame), after every UF:UpdateUnitFrame on a plate.
--   'kind'    fn(frame), once UF:ApplyPlateKind has set the plate's kind
--             (frame.friendly): on every add, inside the first 'added'
--             callback, so before the others; and when a change of the
--             unit's faction changes its kind.
local callbacks = { added = {}, removed = {}, updated = {}, kind = {} }

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

--[[
	Friendly and enemy plates. A friendly unit's plate carries the health bar,
	the name, the health text and the raid mark; an enemy's every part. The
	parts only an enemy's plate shows (the castbar, the aura areas, the quest
	icon and the threat text, threat.lua) are UF.PLATE_ENEMY_ONLY, which
	UF:ElementWanted (updaters.lua) hides on a friendly plate whatever their
	config says, so every update of a plate keeps them hidden there.

	The game hands each plate to unit after unit, a friend after an enemy
	(often mid-fight), so the kind is set on every add (UF:ApplyPlateKind, the
	first 'added' callback, before any other reads frame.friendly), again when
	the unit's faction changes, and the oUF parts follow a config change.
]]
UF.PLATE_ENEMY_ONLY = { Castbar = true, Buffs = true, Debuffs = true, QuestIndicator = true, Threat = true }

-- The enemy-only parts that are oUF elements of their own: a friendly plate
-- has them disabled in oUF, so they don't run for it. oUF's castbar Disable
-- gives Blizzard's castbars their events back only for a 'player' frame that
-- isn't a plate, so disabling it here is safe. The aura areas share oUF's one
-- Auras element with each other, so they're turned on and off as areas.
local OUF_ENEMY_ONLY = { Castbar = true, QuestIndicator = true }
local AURA_AREAS = { Buffs = true, Debuffs = true }

-- Whether a plate's unit is a friend: UnitIsFriend and not UnitCanAttack.
-- Broader than Blizzard's own plate on purpose: Blizzard counts only an
-- attackable party member who's a player as an enemy
-- (NamePlateUnitFrameMixin:UpdateIsFriend), and SaftUI counts every
-- attackable friend as one (a duel, free-for-all PvP), since you can fight it.
-- A secret answer counts as an enemy, so the plate shows everything.
function UF.IsFriendlyPlate(unit)
	local friend = UnitIsFriend('player', unit)
	if issecretvalue(friend) or not friend then return false end
	local attackable = UnitCanAttack('player', unit)
	if issecretvalue(attackable) then return false end
	return not attackable
end

-- Enables or disables in oUF the plate's enemy-only oUF parts, each by
-- UF:ElementWanted. Returns true when it enabled one, which then needs an
-- update to show its unit's state (oUF's castbar Enable hides the bar).
local function EnablePlateParts(frame)
	local enabled = false
	for name in pairs(OUF_ENEMY_ONLY) do
		local element = frame.elements[name]
		if element then
			if not UF:ElementWanted(element) then
				frame:DisableElement(name)
			elseif not frame:IsElementEnabled(name) then
				frame:EnableElement(name)
				enabled = true
			end
		end
	end
	return enabled
end

-- Sets a plate's frame up for a friend (friendly true) or an enemy: notes the
-- kind (frame.friendly), enables or disables its enemy-only oUF parts, turns
-- its aura areas on or off, and shows or hides each part by
-- UF:ElementWanted. Every part, not only the enemy-only ones: when a plate
-- that showed only widgets loses its unit, oUF resumes its parts, which turns
-- every aura area on and shows the health bar whatever the config says.
-- Runs on a frame oUF has initialized (EnableElement errors before that):
-- from the 'added' callback, which comes after oUF's init. Then the 'kind'
-- callbacks run.
function UF:ApplyPlateKind(frame, friendly)
	frame.friendly = friendly and true or false
	EnablePlateParts(frame)
	for name, element in pairs(frame.elements) do
		local wanted = self:ElementWanted(element)
		element:SetShown(wanted)
		if AURA_AREAS[name] then
			element:SetEnabled(wanted)
		end
	end
	self:RunPlateCallbacks('kind', frame)
end

-- The plate's unit changed faction: a friend turned hostile, or back. Updated
-- only when its kind changed, and then the frame's elements updated too, as
-- oUF does after an add, so the parts turned on show their unit's state.
local function UpdatePlateKind(frame)
	local friendly = UF.IsFriendlyPlate(frame.__unit)
	if friendly == frame.friendly then return end
	UF:ApplyPlateKind(frame, friendly)
	frame:UpdateAllElements('UNIT_FACTION')
end

-- First of the 'added' callbacks: the others read frame.friendly.
UF:RegisterPlateCallback('added', function(frame, unit)
	UF:ApplyPlateKind(frame, UF.IsFriendlyPlate(unit))
end)

-- A config change on a plate that shows its unit (UF:UpdateUnitFrame) turns
-- its enemy-only oUF parts on or off in oUF to match: a castbar or quest icon
-- turned on in the options while the plate shows an enemy is enabled now, and
-- the frame updated again, since UF:UpdateUnitFrame's own update came before
-- it was enabled. A plate that shows only widgets, or no unit, waits for its
-- next add.
UF:RegisterPlateCallback('updated', function(frame)
	if showing[frame] and EnablePlateParts(frame) then
		frame:UpdateAllElements('OnShow')
	end
end)

-- Every add, Blizzard's driver hands the plate a UnitFrame from its pool
-- (NamePlateBaseMixin:AcquireUnitFrame), which oUF blocks. Its widgets (a
-- capture bar, a quest object's progress) and soft target icon are moved onto
-- the plate so they still show: oUF does that on a plate's first add only,
-- for the UnitFrame the plate had then, so SaftUI does it on every add,
-- widget-only and game object plates included (oUF runs no added callback for
-- those). Reading the plate's UnitFrame is only a read, and the calls are
-- widget methods on Blizzard's frames, as oUF's are.
--
-- Blizzard anchors the widgets itself just before (NamePlateUnitFrameMixin:
-- UpdateWidgetsOnlyMode): their bottom on its UnitFrame's bottom on a plate
-- that shows only widgets, their top under its castbar otherwise. Their
-- points are cleared first, so they hang from the plate's bottom, or sit on it
-- for a widget-only plate, by one point. A UnitFrame made from a template
-- without them (a spectator's) is left as it is.
local function PlaceWidgets(plate, unit)
	local blizzardFrame = plate.UnitFrame
	if not blizzardFrame then return end
	local widgets = blizzardFrame.WidgetContainer
	if widgets then
		widgets:SetParent(plate)
		widgets:ClearAllPoints()
		if UnitNameplateShowsWidgetsOnly(unit) then
			widgets:SetPoint('BOTTOM', plate, 'BOTTOM')
		else
			widgets:SetPoint('TOP', plate, 'BOTTOM')
		end
	end
	local softTarget = blizzardFrame.SoftTargetFrame
	if softTarget then softTarget:SetParent(plate) end
end

-- The plate each unit is on ('nameplate3' -> NamePlate3), for every plate
-- C_NamePlate gives addon code (not a forbidden one), widget-only ones too:
-- from SaftUI's own listener, from the add to the remove.
local plateOfUnit = {}

--[[
	The click area. A plate takes the clicks in its hit-test points, and oUF
	sets them to SaftUI's frame on every add that shows the unit (ouf.lua:
	ClearAllHitTestPoints, then SetAllHitTestPoints with the frame), so a
	click on the plate's bar targets its unit. Blizzard's pooled UnitFrame on
	the plate sets its own again outside the add (UpdateHitTestArea,
	Blizzard_NamePlateUnitFrame.lua, both clients): round its own hidden bar
	and name, or none in show-only-name or widgets-only mode. It does so
	  * when its driver's options update runs ApplyFrameOptions on every plate
	    (NamePlateDriverFrame:UpdateNamePlateOptions: a window resize, the
	    options loading, a change to one of Blizzard's nameplate options);
	  * from its callbacks on the friendly NPC plates setting
	    (UpdateWidgetsOnlyMode) and on showing only friendly players' names
	    (UpdateShowOnlyName), which stay registered on the UnitFrame oUF
	    blocks: its UnregisterAllEvents drops events, not these.
	So SaftUI runs oUF's two calls again after each, on the plates SaftUI
	shows (showing; ruling N11): from a post-hook on the options update; at the
	end of UF:RefreshPlateWidgets, which runs after SaftUI sets the game's
	plate settings; and on the frame after either setting changes, from
	CVarCallbackRegistry, since its callbacks run in no set order and
	Blizzard's UnitFrames' can come after SaftUI's.
]]

-- Sets the click area of every plate SaftUI shows back to its frame, with
-- oUF's own two calls on the plate (the frame's parent). The game lets addon
-- code change a plate's click area in combat only on the tick the plate got
-- its unit, or one on which Blizzard's own code changed it
-- (CanChangeHitTestPoints, FrameAPINamePlateDocumentation.lua, both clients;
-- the calls error otherwise): so from the options update's post-hook it goes
-- through, and a plate the game refuses waits for the end of combat. It's
-- asked again before the second call: the docs don't say the same-tick
-- exception stays open after SaftUI's first. A plate the game took away, or
-- one showing only widgets, is left alone.
local function MayChange(plate)
	return not plate.CanChangeHitTestPoints or plate:CanChangeHitTestPoints()
end

function UF:RestorePlateHitTests()
	local refused = false
	for frame in pairs(showing) do
		local plate = frame:GetParent()
		if MayChange(plate) then
			plate:ClearAllHitTestPoints()
			if MayChange(plate) then
				plate:SetAllHitTestPoints(frame)
			else
				refused = true
			end
		else
			refused = true
		end
	end
	if refused then
		st:QueueAfterCombat('NameplateHitTest', function() UF:RestorePlateHitTests() end)
	end
end

-- Places the widgets of every plate that shows a unit again, then the click
-- areas. Blizzard anchors the widgets again whenever the game's friendly NPC
-- plates setting changes (its UpdateWidgetsOnlyMode is a callback on it, and
-- sets the click area too), which SaftUI's Friendly plates toggle sets, so
-- this runs after SaftUI sets it, and on the frame after anyone changes it.
function UF:RefreshPlateWidgets()
	for unit, plate in pairs(plateOfUnit) do
		PlaceWidgets(plate, unit)
	end
	self:RestorePlateHitTests()
end

-- The game's settings whose Blizzard callbacks set a plate's click area (and,
-- for the friendly NPC plates, its widgets) again, by their name in
-- NamePlateConstants (Blizzard_NamePlateConstants.lua, both clients).
local CLICK_AREA_CVARS = { 'SHOW_FRIENDLY_NPCS_CVAR', 'SHOW_ONLY_NAME_FOR_FRIENDLY_PLAYER_UNITS_CVAR' }

-- One of them changed: the widgets and click areas are put back on the next
-- frame, after every callback on it has run, once however many changed.
local refreshQueued = false
local function OnClickAreaCVar()
	if refreshQueued then return end
	refreshQueued = true
	C_Timer.After(0, function()
		refreshQueued = false
		UF:RefreshPlateWidgets()
	end)
end

-- Hooks what sets the click area outside oUF's add, each where this client
-- has it: a client without one hooks nothing for it.
local function WatchClickAreas()
	if NamePlateDriverFrame and type(NamePlateDriverFrame.UpdateNamePlateOptions) == 'function' then
		hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateOptions', function() UF:RestorePlateHitTests() end)
	end
	if type(CVarCallbackRegistry) == 'table' and CVarCallbackRegistry.RegisterCallback and type(NamePlateConstants) == 'table' then
		for _, key in ipairs(CLICK_AREA_CVARS) do
			local cvar = NamePlateConstants[key]
			if cvar then CVarCallbackRegistry:RegisterCallback(cvar, OnClickAreaCVar) end
		end
	end
end

-- SaftUI's own listener, made with the driver (UF:SpawnNameplates).
local function OnPlateEvent(_, event, unit)
	if event == 'NAME_PLATE_UNIT_ADDED' then
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		plateOfUnit[unit] = plate
		if plate then PlaceWidgets(plate, unit) end
	elseif event == 'NAME_PLATE_UNIT_REMOVED' then
		plateOfUnit[unit] = nil
	elseif event == 'UNIT_FACTION' then
		if unit == 'player' then
			-- The player's own faction (a PvP flag) can change any plate's.
			for frame in pairs(showing) do UpdatePlateKind(frame) end
		else
			local frame = UF:PlateForUnit(unit)
			if frame then UpdatePlateKind(frame) end
		end
	end
end

-- The size handed to oUF's driver for the config's width and height. The
-- config's size is in UIParent's units, where one unit is a pixel, and SaftUI's
-- frame on each plate is pinned to UIParent's scale (pixels.lua). The plates
-- (NamePlate1, ...) are WorldFrame's children and take their size in its
-- units, so the size is turned into those: the plate, where the game takes
-- the clicks, and SaftUI's frame covering it are then the config's width and
-- height in pixels. A secret or zero scale gives the config's size as it is.
function UF.PlateDriverSize(width, height)
	local ui, world = UIParent:GetEffectiveScale(), WorldFrame:GetEffectiveScale()
	if issecretvalue(ui) or issecretvalue(world) or ui == 0 or world == 0 then
		return width, height
	end
	local ratio = ui / world
	return width * ratio, height * ratio
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
-- it, from a post-hook; and their click areas, which SaftUI puts back too
-- (WatchClickAreas).
function UF:SpawnNameplates()
	if self.plateDriver then return false end
	if not self:GetProfileConfig().nameplate.enable then return false end
	if self:NameplateAddon() then return false end

	local driver = self.oUF:SpawnNamePlates('SaftUI_')
	if not driver then return false end -- oUF reported why
	self.plateDriver = driver

	driver:SetAddedCallback(function(frame, _, unit)
		showing[frame] = true
		frameOfUnit[unit] = frame
		UF:RunPlateCallbacks('added', frame, unit)
	end)
	driver:SetRemovedCallback(function(frame, _, unit)
		showing[frame] = nil
		if frameOfUnit[unit] == frame then frameOfUnit[unit] = nil end
		UF:RunPlateCallbacks('removed', frame, unit)
	end)

	-- Made after the driver, so oUF hears of each add first.
	local events = CreateFrame('Frame')
	events:SetScript('OnEvent', OnPlateEvent)
	events:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	events:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
	events:RegisterEvent('UNIT_FACTION')

	-- The hooks first, so a size oUF refuses (its SetSize checks its
	-- arguments) is reported without leaving Blizzard's size in place later.
	hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateSize', function() UF:ApplyPlateSize() end)
	WatchClickAreas()
	xpcall(function() self:ApplyPlateSize() end, geterrorhandler())
	return true
end
