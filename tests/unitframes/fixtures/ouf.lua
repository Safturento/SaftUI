-- A stand-in for the bundled oUF (SaftUI-Unitframes/Libraries/oUF), as far as
-- SaftUI uses it. new() returns a fresh one; a test sets it as
-- addon_namespace('SaftUI-Unitframes').oUF before unitframes.lua loads, and
-- registers the style and UF.InitUnit with it as UF:OnEnable does.
--
--   ouf.colors, ouf.Tags        oUF's colors (theme_test.lua's table, which
--                               UF:UpdateColors merges the profile's into) and
--                               its tag tables, which tags.lua fills.
--   ouf:RegisterStyle(name, fn), ouf:SetActiveStyle(name),
--   ouf:RegisterInitCallback(fn)
--                               as oUF's: the first style registered is the
--                               active one, and a nil callback is dropped.
--   ouf:Spawn(unit, name)       a single unit's frame: a Button on UIParent.
--   ouf:SpawnGroupButton(header, unit, name)
--                               a group header's unit button: a Button child
--                               of header, as the header makes one. The style
--                               function and the Enables get the unit oUF
--                               guesses from the header's showRaid or
--                               showParty ('raid', 'party'); unit (e.g.
--                               'party1') arrives after init, through the
--                               button's unit attribute, as the header lays
--                               the member out.
--   ouf.IsInitialized(frame)    whether oUF has made the frame's active
--                               elements (the end of initObject's setup).
--   ouf.calls                   every EnableElement and DisableElement call,
--                               init's own included: { frame, method, element },
--                               and every UpdateAllElements: { frame,
--                               'UpdateAllElements', event }.
--   ouf:SpawnNamePlates(prefix) oUF's nameplate driver (ouf.lua 866-1097),
--                               below.
--
-- An object is built as oUF's initObject builds one (ouf.lua 431-447): the
-- active style's function (object, unit, not header), then its active
-- elements, then each element whose widget it has (frame.Health, frame.Range,
-- the aura containers) enabled with the unit, then the init callbacks. Before
-- that, EnableElement errors "attempt to index a nil value", as ouf.lua 104
-- (activeElements[self][name] = true) does.
--
-- Every object gets EnableElement, DisableElement, IsElementEnabled,
-- IsElementPaused, UpdateAllElements (counted in frame.__updates), UpdateTags,
-- Tag, PauseAllElements, ResumeAllElements and CreateAuras. IsElementEnabled
-- and IsElementPaused error on a name that isn't a string, as oUF's argcheck
-- does. Pausing and resuming are oUF's (ouf.lua 164-327): a pause runs each
-- active element's Disable and keeps it enabled, a resume runs its Enable
-- again, and EnableElement leaves a paused element paused (it's still
-- enabled), while DisableElement on one only drops it, with no Disable.
--
-- The nameplate driver, ouf:SpawnNamePlates(prefix), returns a frame with
-- SetSize(width[, height]) (C_NamePlate.SetNamePlateSize, height defaulting to
-- width), SetAddedCallback, SetRemovedCallback and SetTargetCallback, each
-- callback called (unitFrame, event, unit). On the game's events:
--   * NAME_PLATE_UNIT_ADDED: a plate C_NamePlate won't give (a forbidden one)
--     is skipped. A plate's first add makes its frame: a Button named prefix
--     .. the plate's name, the plate's child, mouse off, SetAllPoints to the
--     plate, isNamePlate; the plate's unitFrame and style are set with rawset
--     (oUF writes them onto Blizzard's plate, its own departure from
--     .agents/taint.md rule 1); the driver's style and init; then the plate's
--     current UnitFrame's WidgetContainer (on the plate, TOP to its BOTTOM)
--     and SoftTargetFrame are moved onto the plate, on the first add only, as
--     upstream does. A unit whose plate shows only widgets, or a game object:
--     every element paused and the frame hidden, with no added callback.
--     Otherwise the unit attribute is set (the frame's __unit; a unit that
--     exists and differs from the one the frame had runs UpdateAllElements
--     ('OnAttributeChanged') at once, as oUF's updateActiveUnit does, so a
--     reused plate updates once with its old unit's elements before the added
--     callback), the plate's click area is set to the frame
--     (ClearAllHitTestPoints, then SetAllHitTestPoints, ouf.lua 1030-1031),
--     the added callback runs, then UpdateAllElements.
--   * NAME_PLATE_UNIT_REMOVED: the unit attribute cleared (oUF's handler
--     ignores a nil unit, so __unit keeps the unit that left), every paused
--     element resumed, the frame shown, then the removed callback.
--   * PLAYER_TARGET_CHANGED: on the target's plate (not one showing only
--     widgets or a game object), the target callback with 'target', then
--     UpdateAllElements.
-- A second SpawnNamePlates reports 'oUF nameplate driver has already been
-- initialized.' to the error handler and returns nil, as oUF's nierror does.
-- Enabling an element gives its widget __owner, the frame, as every element's
-- Enable does. Enabling Health or Power also gives the bar ForceUpdate
-- (counted in bar.__forceUpdates), SetColorTapping and SetColorReaction, as
-- their Enables do (Libraries/oUF/elements/health.lua and power.lua); the
-- setters, and the Enable, register UNIT_FACTION on the frame while either
-- flag is on, and the frame drops it once no bar wants it (oUF's events.lua
-- keeps one handler per bar). Health's Enable shows the bar and its Disable
-- hides it, whatever SaftUI's config says, as health.lua's do (a pause and a
-- resume too); the castbar's Enable and Disable both hide it, as castbar.lua's
-- do (oUF shows it for a cast, which nothing here starts). Enabling the aura
-- containers turns each on (SetEnabled(true)), as the Auras meta element's
-- Enable does. Enabling QuestIndicator gives it ForceUpdate, as its Enable
-- does (Libraries/oUF/elements/questindicator.lua), which runs oUF's Path
-- with (frame, 'ForceUpdate', frame.__unit): the element's Override where it
-- has one; oUF's own update, without one, isn't run here.
--
-- What the real oUF does beyond it:
--   * Spawn makes a SecureUnitButtonTemplate button, sets its rolesets and
--     click attributes, hides Blizzard's frame for the unit, watches the unit,
--     and evaluates vehicles and pets; SpawnHeader makes a SecureGroupHeader,
--     which makes its buttons as members appear. A unit attribute set on a
--     frame becomes its active unit only if that unit exists (UnitExists or
--     UnitIsVisible), after vehicle and pet mapping (updateActiveUnit); here
--     it becomes the active unit as it is, and runs the full update only for
--     a unit that exists (the player, or a stub.units unit) and changed.
--   * The elements register their events and update from the unit's data
--     (UpdateAllElements runs them, only for a unit that exists); here
--     nothing updates. Some Enables also check the unit (the castbar not on a
--     unit's target, the ready check only on party and raid members); here a
--     widget is enough.
--   * The nameplate driver also disables Blizzard's UnitFrame on every add
--     (oUF:DisableBlizzard: UnregisterAllEvents and SetRolesets on it and its
--     bars), makes its frames from PingableUnitFrameTemplate, and sets the
--     size, the hit test insets and console variables only once logged in
--     (at PLAYER_LOGIN otherwise); a unit attribute set on a plate's frame
--     also runs a full update. Paused elements are also left out of
--     UpdateAllElements.
--   * CreateAuras makes a Blizzard AuraContainer (CustomAuraContainerTemplate),
--     which makes a button for each aura it shows; here a plain frame that
--     records what's set on it and makes a button only when a test asks:
--       container.groups[key] = { filter, options, candidateFilters, layout },
--       container.enabled, container.flow = { anchor, lineSize, growthX, growthY },
--       container:_AddButton() -> button: a Button child of the container, at
--       its group's size (oUF's default 16 before any group), built as oUF's
--       CreateButton builds one (Libraries/oUF/elements/auras.lua): its Icon
--       (BORDER, over the whole button), Count and Border (OVERLAY, over the
--       whole button), then handed to the element's PostCreateButton, as
--       Blizzard's container does. No Cooldown (the stubs have no Cooldown
--       frames), and nothing about it is Blizzard's: it isn't locked, as
--       auras.lua keeps button.backdrop on it (theme_test.lua's stand-in
--       button allows the same).
--     The container answers IsObjectType('AuraContainer') with true, unless a
--     test sets ouf.containerIsIntrinsic before it's made: then it answers as
--     the plain frame it is. In game AuraContainer is an XML intrinsic
--     (<Frame name="AuraContainer" intrinsic="true">, Blizzard_AuraContainer.xml),
--     and Blizzard tells an intrinsic by a key of its own, not IsObjectType
--     (DropdownButton.lua: frame.intrinsic == "DropdownButton"), so which
--     answer the game gives isn't known.
--   * Tag binds a tag string to a font string and updates it on events.

local M = {}

-- oUF's elements (Libraries/oUF/elements/*.lua, AddElement and the Auras meta
-- element), each enabled at init on a frame that has its widget.
local ELEMENTS = {
	'Health', 'Power', 'AdditionalPower', 'AlternativePower', 'Castbar', 'ClassPower', 'Runes', 'Stagger',
	'Totems', 'Portrait', 'Range', 'Auras', 'PrivateAuras', 'Happiness',
	'AssistantIndicator', 'CombatIndicator', 'FocusIndicator', 'GroupRoleIndicator', 'LeaderIndicator',
	'MasterLooterIndicator', 'PhaseIndicator', 'PvPClassificationIndicator', 'PvPIndicator', 'QuestIndicator',
	'RaidRoleIndicator', 'RaidTargetIndicator', 'ReadyCheckIndicator', 'RestingIndicator',
	'ResurrectIndicator', 'SummonIndicator', 'TargetIndicator', 'ThreatIndicator',
}
local KNOWN = {}
for _, name in ipairs(ELEMENTS) do KNOWN[name] = true end

function M.new()
	local ouf = {
		colors = {
			class = {},
			reaction = {},
			power = {},
			disconnected = CreateColor(1, 1, 1),
			tapped = CreateColor(1, 1, 1),
			health = CreateColor(0.2, 0.8, 0.2),
			roles = {},
			runes = {},
		},
		Tags = { Methods = {}, Events = {} },
		calls = {},
	}

	local styles, activeStyle = {}, nil
	local callbacks = {}
	-- frame -> { [element] = true }, made after the style function (oUF's
	-- activeElements).
	local active = setmetatable({}, { __mode = 'k' })
	-- frame -> its aura containers, in the order made (oUF's STATE[frame].elements).
	local containers = setmetatable({}, { __mode = 'k' })
	-- frame -> the number of aura groups added on it (oUF's STATE[frame].groupIndex).
	local groupCounts = setmetatable({}, { __mode = 'k' })
	-- frame -> { [bar] = true } for the bars that want UNIT_FACTION.
	local factionBars = setmetatable({}, { __mode = 'k' })
	-- frame -> { [element] = true } for its paused elements (oUF's pausedElements).
	local paused = setmetatable({}, { __mode = 'k' })

	-- A bar wants UNIT_FACTION or not; the frame has it while any bar does.
	local function WantFaction(bar, want)
		local frame = bar.__owner
		factionBars[frame] = factionBars[frame] or {}
		factionBars[frame][bar] = want or nil
		if next(factionBars[frame]) then
			frame:RegisterEvent('UNIT_FACTION')
		else
			frame:UnregisterEvent('UNIT_FACTION')
		end
	end

	-- Health's and Power's SetColorTapping and SetColorReaction (their
	-- elements' code, with WantFaction for the frame's RegisterEvent and
	-- UnregisterEvent).
	local function SetColorTapping(bar, state, isForced)
		if bar.colorTapping ~= state or isForced then
			bar.colorTapping = state
			if state then
				WantFaction(bar, true)
			elseif not bar.colorReaction then
				WantFaction(bar, false)
			end
		end
	end
	local function SetColorReaction(bar, state, isForced)
		if bar.colorReaction ~= state or isForced then
			bar.colorReaction = state
			if state then
				WantFaction(bar, true)
			elseif not bar.colorTapping then
				WantFaction(bar, false)
			end
		end
	end
	local function ForceUpdate(bar)
		bar.__forceUpdates = (bar.__forceUpdates or 0) + 1
	end
	-- The quest icon's ForceUpdate: oUF's Path, as far as an Override.
	local function QuestForceUpdate(element)
		local frame = element.__owner
		if element.Override then return element.Override(frame, 'ForceUpdate', frame.__unit) end
	end

	local function EnableBar(frame, bar)
		bar.__owner = frame
		bar.ForceUpdate = ForceUpdate
		bar.SetColorTapping = SetColorTapping
		bar.SetColorReaction = SetColorReaction
		if bar.colorTapping or bar.colorReaction then
			WantFaction(bar, true)
		end
		return true
	end

	-- Each element's Enable (true if the frame has its widget) and Disable.
	-- oUF hands them the unit too; none here reads it.
	local function Enable(frame, name)
		if name == 'Auras' then
			if not containers[frame] then return end
			for _, container in ipairs(containers[frame]) do container:SetEnabled(true) end
			return true
		end
		local widget = frame[name]
		if widget == nil then return end
		if type(widget) == 'table' then widget.__owner = frame end
		if name == 'Health' then widget:Show() end
		if name == 'Castbar' then widget:Hide() end
		if name == 'QuestIndicator' then widget.ForceUpdate = QuestForceUpdate end
		if name == 'Health' or name == 'Power' then return EnableBar(frame, widget) end
		return true
	end
	local function Disable(frame, name)
		if name == 'Auras' then
			for _, container in ipairs(containers[frame] or {}) do container:SetEnabled(false) end
		elseif name == 'Health' or name == 'Power' then
			if name == 'Health' then frame.Health:Hide() end
			WantFaction(frame[name], false)
		elseif name == 'Castbar' then
			frame.Castbar:Hide()
		end
	end

	local methods = {}
	function methods.EnableElement(self, name, unit)
		ouf.calls[#ouf.calls + 1] = { self, 'EnableElement', name }
		if not KNOWN[name] or self:IsElementEnabled(name) then return end
		if Enable(self, name) then
			active[self][name] = true -- errors before init, as oUF's does
		end
	end
	function methods.DisableElement(self, name)
		ouf.calls[#ouf.calls + 1] = { self, 'DisableElement', name }
		if not self:IsElementEnabled(name) then return end
		active[self][name] = nil
		if self:IsElementPaused(name) then
			-- Pausing already ran its Disable.
			paused[self][name] = nil
			return
		end
		Disable(self, name)
	end
	-- oUF's argcheck (private.lua 5-15): an argument of the wrong type errors,
	-- naming the method.
	local function NameCheck(name, method)
		if type(name) ~= 'string' then
			error(("Bad argument #2 to '%s' (string expected, got %s)"):format(method, type(name)), 3)
		end
	end
	function methods.IsElementEnabled(self, name)
		NameCheck(name, 'IsElementEnabled')
		if not KNOWN[name] then return end
		local enabled = active[self]
		return enabled and enabled[name]
	end
	function methods.IsElementPaused(self, name)
		NameCheck(name, 'IsElementPaused')
		if not KNOWN[name] then return end
		local list = paused[self]
		return list and list[name]
	end
	function methods.UpdateAllElements(self, event)
		assert(type(event) == 'string', "Invalid argument 'event' in UpdateAllElements.")
		ouf.calls[#ouf.calls + 1] = { self, 'UpdateAllElements', event }
		self.__updates = (self.__updates or 0) + 1
	end
	function methods.UpdateTags() end
	function methods.Tag() end
	function methods.PauseAllElements(self)
		for name in pairs(active[self]) do
			if not self:IsElementPaused(name) then
				paused[self] = paused[self] or {}
				paused[self][name] = true
				Disable(self, name)
			end
		end
	end
	function methods.ResumeAllElements(self)
		for name in pairs(paused[self] or {}) do
			if self:IsElementEnabled(name) and Enable(self, name) then
				paused[self][name] = nil
			end
		end
	end
	function methods.CreateAuras(self)
		local owner = self
		local container = CreateFrame('Frame', nil, owner)
		container.__owner = owner
		container.groups = {}
		container.flow = {}
		function container:AddGroup(filter, options)
			groupCounts[owner] = (groupCounts[owner] or 0) + 1
			local key = 'Group' .. groupCounts[owner]
			self.groups[key] = { filter = filter, options = options, candidateFilters = options and options.candidateFilters }
			return key
		end
		function container:SetAuraGroupFilterString(key, filter) self.groups[key].filter = filter end
		function container:SetAuraGroupCandidateFilters(key, filters) self.groups[key].candidateFilters = filters end
		function container:SetAuraGroupLayout(key, layout) self.groups[key].layout = layout end
		function container:SetEnabled(enabled) self.enabled = enabled end
		function container:SetFlowLayoutAnchorPoint(point) self.flow.anchor = point end
		function container:SetFlowLayoutMaximumLineSize(size) self.flow.lineSize = size end
		function container:SetFlowLayoutGrowthDirection(x, y) self.flow.growthX, self.flow.growthY = x, y end
		if not ouf.containerIsIntrinsic then
			local isObjectType = container.IsObjectType
			function container:IsObjectType(typeName)
				return typeName == 'AuraContainer' or isObjectType(self, typeName)
			end
		end
		-- The container making a button for an aura that shows (see the top).
		function container:_AddButton()
			local _, group = next(self.groups)
			local size = group and group.options and group.options.size or 16
			local button = CreateFrame('Button', nil, self)
			button:SetSize(size, size)
			local icon = button:CreateTexture(nil, 'BORDER')
			icon:SetAllPoints()
			button.Icon = icon
			local count = button:CreateFontString(nil, 'OVERLAY')
			count:SetPoint('BOTTOMRIGHT', -1, 0)
			button.Count = count
			local border = button:CreateTexture(nil, 'OVERLAY')
			border:SetAllPoints()
			button.Border = border
			if self.PostCreateButton then self:PostCreateButton(button) end
			return button
		end
		containers[owner] = containers[owner] or {}
		table.insert(containers[owner], container)
		return container
	end

	-- oUF's onAttributeChanged, which initObject hooks: a unit set on the frame
	-- becomes its active unit, and one that exists and changed runs a full
	-- update (updateActiveUnit).
	local function OnAttributeChanged(object, name, value)
		if name == 'unit' and value then
			local changed = object.__unit ~= value
			object.__unit = value
			if changed and (value == 'player' or stub.units[value] ~= nil) then
				object:UpdateAllElements('OnAttributeChanged')
			end
		end
	end

	-- oUF's initObject, for one object, with the active style or the one
	-- given (a nameplate driver's).
	local function Init(object, unit, header, style)
		style = style or activeStyle
		object.__unit = unit
		object.style = style
		for name, fn in pairs(methods) do object[name] = fn end
		styles[style](object, unit, not header)
		object:HookScript('OnAttributeChanged', OnAttributeChanged)
		active[object] = {}
		for _, name in ipairs(ELEMENTS) do
			object:EnableElement(name, unit)
		end
		for _, fn in ipairs(callbacks) do fn(object) end
	end

	-- The unit the header's oUF-initialConfigFunction guesses for a button it
	-- makes, from the header's attributes (ouf.lua 668-690, without the main
	-- tank and assist filters and the unit suffixes, which SaftUI's headers
	-- don't set).
	local function GuessUnit(header)
		if header:GetAttribute('showRaid') then return 'raid' end
		if header:GetAttribute('showParty') then return 'party' end
	end

	function ouf:RegisterStyle(name, fn)
		styles[name] = fn
		activeStyle = activeStyle or name
	end
	function ouf:SetActiveStyle(name)
		assert(styles[name], ('Style [%s] does not exist.'):format(tostring(name)))
		activeStyle = name
	end
	function ouf:RegisterInitCallback(fn)
		table.insert(callbacks, fn)
	end
	function ouf:Spawn(unit, name)
		unit = unit:lower()
		local object = CreateFrame('Button', name, UIParent)
		Init(object, unit, nil)
		object:SetAttribute('unit', unit)
		return object
	end
	function ouf:SpawnGroupButton(header, unit, name)
		local object = CreateFrame('Button', name, header)
		local guess = GuessUnit(header)
		assert(guess, 'SpawnGroupButton: the header shows neither party nor raid (showParty, showRaid)')
		object:SetAttribute('oUF-guessUnit', guess)
		Init(object, guess, header)
		object:SetAttribute('unit', unit)
		return object
	end
	function ouf.IsInitialized(frame)
		return active[frame] ~= nil
	end

	-- The nameplate driver (see the top of this file).
	local function ShowsUnit(unit)
		return not (UnitNameplateShowsWidgetsOnly(unit) or UnitIsGameObject(unit))
	end
	local function DriverEvent(driver, event, unit)
		if event == 'NAME_PLATE_UNIT_ADDED' then
			local plate = C_NamePlate.GetNamePlateForUnit(unit)
			if not plate then return end
			local object = plate.unitFrame
			if not object then
				rawset(plate, 'style', driver.style)
				object = CreateFrame('Button', driver.prefix .. plate:GetName(), plate)
				rawset(plate, 'unitFrame', object)
				object:EnableMouse(false)
				object:SetAllPoints()
				object.isNamePlate = true
				Init(object, unit, nil, driver.style)
				plate.UnitFrame.WidgetContainer:SetParent(plate)
				plate.UnitFrame.WidgetContainer:SetPoint('TOP', plate, 'BOTTOM')
				plate.UnitFrame.SoftTargetFrame:SetParent(plate)
			end
			if not ShowsUnit(unit) then
				object:PauseAllElements()
				object:Hide()
			else
				object:SetAttribute('unit', unit)
				plate:ClearAllHitTestPoints()
				plate:SetAllHitTestPoints(object)
				if driver.addedCallback then driver.addedCallback(object, event, unit) end
				object:UpdateAllElements(event)
			end
		elseif event == 'NAME_PLATE_UNIT_REMOVED' then
			local plate = C_NamePlate.GetNamePlateForUnit(unit)
			if not plate or not plate.unitFrame then return end
			local object = plate.unitFrame
			object:SetAttribute('unit', nil)
			object:ResumeAllElements()
			object:Show()
			if driver.removedCallback then driver.removedCallback(object, event, unit) end
		elseif event == 'PLAYER_TARGET_CHANGED' then
			local plate = C_NamePlate.GetNamePlateForUnit('target')
			if not plate or not plate.unitFrame or not ShowsUnit('target') then return end
			if driver.targetCallback then driver.targetCallback(plate.unitFrame, event, 'target') end
			plate.unitFrame:UpdateAllElements(event)
		end
	end

	local driverMethods = {}
	function driverMethods:SetSize(width, height)
		assert(type(width) == 'number', "Bad argument #2 to 'SetSize' (number expected)")
		assert(height == nil or type(height) == 'number', "Bad argument #3 to 'SetSize' (number or nil expected)")
		self.plateWidth, self.plateHeight = width, height or width
		C_NamePlate.SetNamePlateSize(self.plateWidth, self.plateHeight)
	end
	for _, name in ipairs({ 'Added', 'Removed', 'Target' }) do
		local key = name:lower() .. 'Callback'
		driverMethods['Set' .. name .. 'Callback'] = function(self, fn)
			assert(fn == nil or type(fn) == 'function', ("Bad argument #2 to 'Set%sCallback' (function or nil expected)"):format(name))
			self[key] = fn
		end
	end

	-- The driver's global name is oUF's: its X-oUF name (the unit frames'
	-- TOC) and _NamePlateDriver.
	local DRIVER_NAME = 'SaftUI-Unitframes_NamePlateDriver'
	function ouf:SpawnNamePlates(prefix)
		assert(activeStyle, 'Unable to create frame. No styles have been registered.')
		if _G[DRIVER_NAME] then
			return geterrorhandler()('oUF nameplate driver has already been initialized.')
		end
		local driver = CreateFrame('Frame', DRIVER_NAME)
		for name, fn in pairs(driverMethods) do driver[name] = fn end
		driver.style = activeStyle
		driver.prefix = prefix
		driver:SetScript('OnEvent', DriverEvent)
		driver:RegisterEvent('NAME_PLATE_UNIT_ADDED')
		driver:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
		driver:RegisterEvent('PLAYER_TARGET_CHANGED')
		return driver
	end

	return ouf
end

return M
