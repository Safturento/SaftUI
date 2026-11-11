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
--                               init's own included: { frame, method, element }.
--
-- An object is built as oUF's initObject builds one (ouf.lua 431-447): the
-- active style's function (object, unit, not header), then its active
-- elements, then each element whose widget it has (frame.Health, frame.Range,
-- the aura containers) enabled with the unit, then the init callbacks. Before
-- that, EnableElement errors "attempt to index a nil value", as ouf.lua 104
-- (activeElements[self][name] = true) does.
--
-- Every object gets EnableElement, DisableElement, IsElementEnabled,
-- UpdateAllElements (counted in frame.__updates), UpdateTags, Tag,
-- PauseAllElements and ResumeAllElements (frame.__paused) and CreateAuras.
-- Enabling Health or Power gives the bar __owner, ForceUpdate (counted in
-- bar.__forceUpdates), SetColorTapping and SetColorReaction, as their Enables
-- do (Libraries/oUF/elements/health.lua and power.lua); the setters, and the
-- Enable, register UNIT_FACTION on the frame while either flag is on, and the
-- frame drops it once no bar wants it (oUF's events.lua keeps one handler per
-- bar). Enabling the aura containers turns each on (SetEnabled(true)), as the
-- Auras meta element's Enable does.
--
-- What the real oUF does beyond it:
--   * Spawn makes a SecureUnitButtonTemplate button, sets its rolesets and
--     click attributes, hides Blizzard's frame for the unit, watches the unit,
--     and evaluates vehicles and pets; SpawnHeader makes a SecureGroupHeader,
--     which makes its buttons as members appear. A unit attribute set on a
--     frame becomes its active unit only if that unit exists, after vehicle
--     and pet mapping (updateActiveUnit), and runs a full update; here it
--     becomes the active unit as it is, with no update.
--   * The elements register their events and update from the unit's data
--     (UpdateAllElements runs them, only for a unit that exists); here
--     nothing updates. Some Enables also check the unit (the castbar not on a
--     unit's target, the ready check only on party and raid members); here a
--     widget is enough.
--   * Pausing and resuming act per element, on nameplates.
--   * CreateAuras makes a Blizzard AuraContainer (CustomAuraContainerTemplate),
--     which makes a button for each aura it shows; here a plain frame that
--     records what's set on it and makes no buttons:
--       container.groups[key] = { filter, options, candidateFilters, layout },
--       container.enabled, container.flow = { anchor, lineSize, growthX, growthY }.
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
		if name == 'Health' or name == 'Power' then return EnableBar(frame, widget) end
		return true
	end
	local function Disable(frame, name)
		if name == 'Auras' then
			for _, container in ipairs(containers[frame] or {}) do container:SetEnabled(false) end
		elseif name == 'Health' or name == 'Power' then
			WantFaction(frame[name], false)
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
		Disable(self, name)
	end
	function methods.IsElementEnabled(self, name)
		if not KNOWN[name] then return end
		local enabled = active[self]
		return enabled and enabled[name]
	end
	function methods.UpdateAllElements(self, event)
		assert(type(event) == 'string', "Invalid argument 'event' in UpdateAllElements.")
		self.__updates = (self.__updates or 0) + 1
	end
	function methods.UpdateTags() end
	function methods.Tag() end
	function methods.PauseAllElements(self) self.__paused = true end
	function methods.ResumeAllElements(self) self.__paused = false end
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
		local isObjectType = container.IsObjectType
		function container:IsObjectType(typeName)
			return typeName == 'AuraContainer' or isObjectType(self, typeName)
		end
		containers[owner] = containers[owner] or {}
		table.insert(containers[owner], container)
		return container
	end

	-- oUF's onAttributeChanged, which initObject hooks: a unit set on the frame
	-- becomes its active unit.
	local function OnAttributeChanged(object, name, value)
		if name == 'unit' and value then object.__unit = value end
	end

	-- oUF's initObject, for one object.
	local function Init(object, unit, header)
		object.__unit = unit
		object.style = activeStyle
		for name, fn in pairs(methods) do object[name] = fn end
		styles[activeStyle](object, unit, not header)
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

	return ouf
end

return M
