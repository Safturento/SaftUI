local _, ns = ...
local st = SaftUI
local UF = st:NewModule('Unitframes')
UF.oUF = ns.oUF
assert(UF.oUF, 'st was unable to locate oUF.')

-- oUF's own role and rune colors, for profiles that have none (UF:UpdateColors).
local DEFAULT_ROLE_COLORS = UF.oUF.colors.roles
local DEFAULT_RUNE_COLORS = UF.oUF.colors.runes

UF.elements = {}

-- Holders (unit -> frame): boss and arena (made in OnEnable, see
-- UF:PlaceHolder) and party and raid (UF:CreateGroupHeaders, see
-- UF:PlaceGroupHolder).
UF.holders = {}

UF.unit_strings = {
	['player'] = 'Player',
	['target'] = 'Target',
	['targettarget'] = 'TargetTarget',
	['focus'] = 'Focus',
	['focustarget'] = 'FocusTarget',
	['pet'] = 'Pet',
	['pettarget'] = 'PetTarget', -- off by default (its enable), turned on in /sui
	['boss'] = 'Boss',
	--['arena'] = 'Arena'
}

UF.group_strings = {
	['party'] = 'Party',
	['raid10'] = 'Raid 10',
	['raid40'] = 'Raid 40',
}

function UF:GetFrame(unitframe, configPosition)
	--print(configPosition.element)
    return unitframe[configPosition.element] or _G[configPosition.frame] or unitframe
end

-- oUF keeps the active unit in __unit, but Blizzard's UnitFrame_OnEnter reads
-- self.unit and passes it straight to GameTooltip:SetUnit, which throws on nil.
function UF.OnEnter(self)
	local unit = self.__unit
	if not unit or not UnitExists(unit) then return end
	self.unit = unit
	UnitFrame_OnEnter(self)
end

function UF.ConstructUnit(self, unit)
	-- Ensure that we have access to a numberless unit type for config tables
	local base_unit = self:GetParent():GetAttribute('base_unit')
	if base_unit then
		self.is_group_unit = true
		self.base_unit = base_unit
	else
		self.base_unit = strmatch(unit, '(%D+)')
	end

	self.ID = tonumber(strmatch(self:GetName(), '(%d+)'))
	if UF.unit_strings[self.base_unit] then
		self.unitLabel = UF.unit_strings[self.base_unit] .. (self.ID or '')
	end
	-- RegisterForClicks is protected on a secure button in combat. Group
	-- buttons are all made out of combat (UF:ApplyGroupLayout), but one the
	-- header still makes in combat gets right-click once combat ends.
	if InCombatLockdown() then
		st:QueueAfterCombat('uf_clicks_' .. self:GetName(), function() self:RegisterForClicks('AnyUp') end)
	else
		self:RegisterForClicks('AnyUp')
	end
	self:SetScript('OnEnter', UF.OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	
	-- Used as a parent to text objects to ensure they're always above status bars
	local textoverlay = CreateFrame('frame', nil, self)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(self)
	self.TextOverlay = textoverlay

	self.config = UF:GetProfileConfig()[self.base_unit]
	self.GetConfig = function() return UF:GetProfileConfig()[self.base_unit]  end
	
	-- Since oUF doesn't give us access to a table of active elements
	-- we can keep track of them here to easily loop and update through them later.
	-- ValidUnit gets the config unit (self.base_unit, e.g. 'player', 'boss' or
	-- 'party'), like the /sui unit sections (UF:GetConfigTable).
	self.elements = {}
	for element_name, funcs in pairs(UF.elements) do
		if (not funcs.ValidUnit) or funcs.ValidUnit(self.base_unit) then
			self.elements[element_name] = funcs.Constructor(self, element_name)
		end
	end

	if self.is_group_unit then
		UF:UpdateUnitFrame(self)
	else
		UF.allUnits[unit] = self
	end
end

--[[
name (string): the name of the element to use as the key
Constructor (function): for actually creating the element and binding it to oUF
UpdateConfig (function): the function used to update the display of the element based on the configuration table
	Constructor and UpdateConfig take the unitframe object created from oUF:Spawn and the element name.
GetConfigTable (function, optional): GetConfigTable(unit, frame_position_get, frame_position_set)
	returns the AceConfig group for the element's tab in the unit's /sui section.
ValidUnit (function, optional): ValidUnit(unit) is true for the config units
	('player', 'boss', 'party', ...) that get the element. Others get neither the
	element nor its tab.
]]--
function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
	self.elements[name] = {
	    name = name,
		Constructor = Constructor,
		UpdateConfig = UpdateConfig,
		GetConfigTable = GetConfigTable,
		ValidUnit = ValidUnit
	}
end

function UF:UpdateColors()
	st.tablemerge(UF.oUF.colors.disconnected, st.config.profile.colors.status.disconnected, true)
	st.tablemerge(UF.oUF.colors.tapped, st.config.profile.colors.status.tapped, true)
	st.tablemerge(UF.oUF.colors.reaction, st.config.profile.colors.reaction, true)
	st.tablemerge(UF.oUF.colors.power, st.config.profile.colors.power, true)
	st.tablemerge(UF.oUF.colors.class, st.config.profile.colors.class, true)
	-- The profile has no roles or runes colors by default; use oUF's then
	-- instead of wiping them. Set every time, so a profile without them doesn't
	-- keep the colors of a profile switched away from.
	UF.oUF.colors.roles = st.config.profile.colors.roles or DEFAULT_ROLE_COLORS
	UF.oUF.colors.runes = st.config.profile.colors.runes or DEFAULT_RUNE_COLORS
end

-- A color changed on the Colors tab (st:ColorsChanged calls this). Lighter than
-- UF:UpdateConfig, because the picker sets a color on every move of its cursor:
-- it copies the colors to oUF, makes the bars and tags read them again, and
-- draws the test previews again, and rebuilds nothing. Groups the unit frames
-- don't use (text, button, item quality, renown) and a module that isn't
-- enabled yet (no UF.units) change nothing.
local UNIT_FRAME_COLOR_GROUPS = { class = true, reaction = true, power = true, status = true }
-- ClassPower sets its color only when it checks its visibility, which
-- ForceUpdate runs.
local RECOLORED_ELEMENTS = { 'Health', 'Power', 'AdditionalPower', 'ClassPower' }
function UF:OnColorsChanged(group)
	if not self.units or not UNIT_FRAME_COLOR_GROUPS[group] then return end
	self:UpdateColors()
	self:ForEachUnitFrame(function(frame)
		-- A frame whose unit doesn't exist (a boss or arena frame out of an
		-- encounter, an empty party slot) has nothing to draw, and its tags
		-- error on a nil name; oUF updates it, with the colors merged above,
		-- when its unit appears.
		if not (frame.unit and UnitExists(frame.unit)) then return end
		for _, name in ipairs(RECOLORED_ELEMENTS) do
			if frame[name] and frame:IsElementEnabled(name) then
				frame[name]:ForceUpdate()
			end
		end
		frame:UpdateTags()
	end)
	for testGroup in pairs(self.testGroups or {}) do
		self:UpdateGroupPreview(testGroup)
	end
end

-- Calls fn(frame) for every spawned unit frame: single units, the numbered
-- boss/arena frames, and group header children.
function UF:ForEachUnitFrame(fn)
	for unit, frame in pairs(self.units or {}) do
		if unit == 'boss' or unit == 'arena' then
			for _, numbered in pairs(frame) do
				fn(numbered)
			end
		else
			fn(frame)
		end
	end
	for _, header in pairs(self.groups or {}) do
		for i = 1, header:GetNumChildren() do
			local child = select(i, header:GetChildren())
			if child and child.GetConfig then
				fn(child)
			end
		end
	end
end

-- Points an element's cached config (and its texts' and icons') at the
-- current profile.
local function RefreshElementConfig(element)
	if element.GetConfig then
		element.config = element:GetConfig()
	end
	for _, text in pairs(element.textElements or {}) do
		text.config = text:GetConfig()
	end
	for _, icon in pairs(element.icons or {}) do
		icon.config = icon:GetConfig()
	end
end

-- Points every frame's and element's cached config at the current profile.
-- Element callbacks (PostUpdate and friends) read those tables, and after a
-- profile switch the old ones have lost their defaults. Only plain table
-- writes, so it's safe in combat.
function UF:RefreshConfigReferences()
	self:ForEachUnitFrame(function(frame)
		frame.config = frame:GetConfig()
		for _, element in pairs(frame.elements or {}) do
			RefreshElementConfig(element)
		end
	end)
	for unit, header in pairs(self.groups or {}) do
		header.config = self:GetProfileConfig()[unit]
	end
end

-- Sizes and places one unit frame from frame.config. A group button is only
-- sized: its header places it (and UF:AnchorGroupHeader places the header).
-- Boss/arena 1 sits at the top of its group's holder and the others chain
-- below it. A disabled frame goes off screen, and false is returned for it.
-- Unit frames are secure: out of combat only.
function UF:PlaceUnitFrame(frame)
	local config = frame.config
	if not frame.is_group_unit then
		frame:ClearAllPoints()
		if not config.enable then
			frame:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 10000, 10000)
			return false
		end
		local holder = self.holders[frame.base_unit]
		if frame.ID and holder then
			-- Boss/arena share party and raid's layout math (groups.lua). Arena has
			-- no layout keys, so GetGroupLayout's fallbacks give it one column
			-- growing down by its spacing, as before. Frame i then hangs TOP to
			-- BOTTOM under frame i-1 (it was TOPLEFT to BOTTOMLEFT) and frame 1
			-- sits at the holder's TOP (it was TOPLEFT): the same spots while the
			-- frames are as wide as the holder.
			local frames = self.units[frame.base_unit]
			local layout = UF.GetGroupLayout(config)
			local _, _, unitsPerColumn, numColumns, shown = UF.GetGroupLayoutSize(layout, #frames)
			if frame.ID > shown then
				-- The layout holds fewer than all of them (max columns x units per
				-- column): the rest are parked, as a header doesn't show them.
				frame:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 10000, 10000)
				return false
			end
			for _, a in ipairs(UF.GroupAnchor(frame.ID, frames, holder, layout, unitsPerColumn, numColumns)) do
				frame:SetPoint(a[1], a[2], a[3], a[4], a[5])
			end
		elseif frame.ID and frame.ID > 1 then
			frame:SetPoint('TOPLEFT', self.units[frame.base_unit][frame.ID-1], 'BOTTOMLEFT', 0, -config.spacing)
		elseif holder then
			frame:SetPoint('TOPLEFT', holder, 'TOPLEFT')
		else
			frame:SetPoint(st:UnpackPoint(config.position))
		end
	end
	st:SetSize(frame, config.width, config.height)
	return true
end

-- Sizes a boss/arena holder to its group, the frames the layout shows (shown
-- or not), and places it at the group's position. The holder is the group's edit
-- mode outline, so it covers the group's spot even with no boss up. It counts
-- as protected in combat while frame 1 is anchored to it (st:CanMoveNow).
function UF:PlaceHolder(unit)
	local holder = self.holders[unit]
	local config = self:GetProfileConfig()[unit]
	local count = #self.units[unit]
	holder:ClearAllPoints()
	holder:SetPoint(st:UnpackPoint(config.position))
	-- Boss/arena lay out like party and raid: the holder covers all of it.
	local width, height = UF.GetGroupLayoutSize(UF.GetGroupLayout(config), count)
	st:SetSize(holder, width, height)
end

function UF:UpdateUnitFrame(frame, element_name)
	frame.config = frame:GetConfig()

	if element_name and self.elements[element_name] then
        if self.elements[element_name].UpdateConfig then
            self.elements[element_name].UpdateConfig(frame, element_name)
        else
            self:UpdateElement(frame[element_name])
        end
	else
		if not InCombatLockdown() and not self:PlaceUnitFrame(frame) then
			return -- disabled, and moved off screen
		end

		st:SetBackdrop(frame, frame.config.template)

		-- Updated in place: oUF's range element keeps its state on this table.
		frame.Range = frame.Range or {}
		frame.Range.insideAlpha = frame.config.range_alpha.inside
		frame.Range.outsideAlpha = frame.config.range_alpha.outside
		
		for _element_name, element in pairs(frame.elements) do
            if self.elements[_element_name].UpdateConfig then
                self.elements[_element_name].UpdateConfig(frame, _element_name)
            else
                self:UpdateElement(frame[_element_name])
            end
		end
	end

	frame:UpdateAllElements('OnShow')
end

--[[
	Updates unit frames from the current profile: one unit (and optionally one
	of its elements), or with no unit everything, colors included. Runs on
	profile changes (Config:UpdateConfig) and option edits.

	Unit frames are secure, so their size and position can't change in combat.
	In combat the cached config is re-pointed right away (element callbacks
	read it) and the full update waits for PLAYER_REGEN_ENABLED.
]]
function UF:UpdateConfig(unit, element_name)
	if not self.units then return end -- not enabled

	if st:QueueAfterCombat('Unitframes', function() UF:UpdateConfig() end) then
		self:RefreshConfigReferences()
		return
	end

	if not unit then
		self:UpdateColors()
	end
	self:ApplyConfig(unit, element_name)
	-- Either raid group being on hides Blizzard's raid frames (groups.lua).
	self:UpdateBlizzardRaidFrames()
end

-- Updates one frame, reporting an error instead of raising it, so one frame
-- that fails (e.g. a SetPoint into an anchor loop) doesn't stop the frames
-- after it.
local function SafeUpdateUnitFrame(frame, element_name)
	xpcall(function() UF:UpdateUnitFrame(frame, element_name) end, geterrorhandler())
end

-- Clears the points of every frame ApplyConfig places: the single and
-- numbered unit frames, the boss/arena, party and raid holders, and the group
-- headers (their children are placed by the header). Returns each frame's old points, for
-- st:RestorePoints. Unit frames are secure: out of combat only.
local function ClearUnitFramePoints(self)
	local previous = {}
	local function Clear(frame)
		previous[frame] = st:GetPoints(frame)
		frame:ClearAllPoints()
	end
	for unit, frame in pairs(self.units) do
		if unit == 'boss' or unit == 'arena' then
			for _, numbered in pairs(frame) do
				Clear(numbered)
			end
		else
			Clear(frame)
		end
	end
	for _, holder in pairs(self.holders) do
		Clear(holder)
	end
	for _, header in pairs(self.groups or {}) do
		Clear(header)
	end
	return previous
end

--[[
	Wrapper function for UpdateUnitFrame that allows you to update
		using unit string instead of the frame object. Also used 
		to update all group frames at once
]]
function UF:ApplyConfig(unit, element_name)
	if not unit then
		-- Two profiles can anchor frames the other way round (Pet to Player in
		-- one, Player to Pet in the other), and placing them one by one would
		-- then pass through an anchor loop. Out of combat, every frame's points
		-- are cleared first, so they can be placed in any order. In combat
		-- nothing is placed (UpdateUnitFrame skips it, UpdateConfig waits).
		local previous
		if not element_name and not InCombatLockdown() then
			previous = ClearUnitFramePoints(self)
		end

		for unit, frame in pairs(self.units) do
			UF:ApplyConfig(unit, element_name)
		end

		if self.groups then
			for unit,_ in pairs(self.groups) do
				UF:ApplyConfig(unit, element_name)
			end
		end

		-- A frame whose update failed after its points were cleared gets its
		-- old ones back, now that every other frame is placed.
		for frame, points in pairs(previous or {}) do
			st:RestorePoints(frame, points)
		end
	else
		if self.units[unit] then
			if unit == 'boss' or unit == 'arena' then
				-- The holder follows the group's size and position, like the
				-- frames, and only out of combat, like UpdateUnitFrame.
				if self.holders[unit] and not element_name and not InCombatLockdown() then
					xpcall(function() self:PlaceHolder(unit) end, geterrorhandler())
				end
				for i,frame in pairs(self.units[unit]) do
					SafeUpdateUnitFrame(frame, element_name)
				end
				-- Boss's test mode previews follow the frames (groups.lua).
				xpcall(function() self:UpdateGroupPreview(unit) end, geterrorhandler())
			else
				SafeUpdateUnitFrame(self.units[unit], element_name)
			end
		elseif self.groups and self.groups[unit] then
			local header = self.groups[unit]
			header.config = self:GetProfileConfig()[unit]
			-- The holder, the header's anchor and attributes follow the group's
			-- config, out of combat only, like UpdateUnitFrame.
			local layout = not element_name and not InCombatLockdown()

			if layout then
				xpcall(function()
					self:PlaceGroupHolder(unit)
					self:AnchorGroupHeader(unit)
				end, geterrorhandler())
			end

			for i=1,header:GetNumChildren() do
				local frame = select(i, header:GetChildren())
				if frame and frame.Health then
					SafeUpdateUnitFrame(frame, element_name)
				end
			end

			-- After the buttons are resized, so the header measures them anew.
			if layout then
				xpcall(function() self:ApplyGroupLayout(unit) end, geterrorhandler())
			end
			xpcall(function() self:UpdateGroupPreview(unit) end, geterrorhandler())
		end
	end
end

-- The frame a unit's mover drags and outlines, and its Position section
-- validates typed anchors against: a boss/arena, party or raid group's
-- holder, or the unit's own frame.
function UF:GetMoverFrame(unit)
	return self.holders[unit] or self.units[unit]
end

-- A mover's apply, after a drag, a nudge or a profile change: sizes and places
-- one unit's frames (and a group's holder) from the profile with the same code
-- as UpdateUnitFrame. A move doesn't need the elements refreshed. Unit frames
-- are secure, so in combat this waits for the end of combat.
function UF:ApplyPosition(unit)
	if self.groups and self.groups[unit] then
		return self:ApplyGroupPosition(unit)
	end
	local holder = self.holders[unit]
	local frames = holder and self.units[unit] or { self.units[unit] }
	if holder then
		st:SafeReposition(holder, 'uf_holder_' .. unit, function() self:PlaceHolder(unit) end)
	end
	st:SafeReposition(frames[1], 'uf_' .. unit, function()
		for _, frame in ipairs(frames) do
			frame.config = frame:GetConfig()
			self:PlaceUnitFrame(frame)
		end
	end)
end

-- Every spawned unit gets an edit mode mover: each single frame, and boss,
-- party, raid10 and raid40 as one group each (its holder). Clicking one opens
-- its General group in /sui. Arena isn't spawned (commented out of
-- unit_strings), so it has none.
function UF:RegisterMovers()
	local function Register(unit, label)
		st:RegisterMover('uf_' .. unit, {
			frame = self:GetMoverFrame(unit),
			label = label,
			-- Looked up on every call: a profile change replaces these tables.
			getPosition = function() return self:GetProfileConfig()[unit].position end,
			setPosition = function(pos) self:GetProfileConfig()[unit].position = pos end,
			apply = function() self:ApplyPosition(unit) end,
			configPath = { 'Unitframes', unit, 'general' },
		})
	end
	for unit in pairs(self.units) do
		Register(unit, self.unit_strings[unit])
	end
	for group in pairs(self.groups or {}) do
		Register(group, self.group_strings[group])
	end
end

function UF:OnEnable()
	self.oUF:RegisterStyle('SaftUI', UF.ConstructUnit)
	self.oUF:SetActiveStyle('SaftUI')

	self.units = {}
	self.allUnits = {}
	for unit, labelName in pairs(self.unit_strings) do
		if unit == 'boss' or unit == 'arena' then
			self.units[unit] = {}
			for i=1, 5 do
				self.units[unit][i] = self.oUF:Spawn(unit..i, 'SaftUI_'..labelName..i)
			end
			-- The five frames move as one group, on a SaftUI holder.
			self.holders[unit] = CreateFrame('Frame', 'SaftUI_'..labelName..'Holder', UIParent)
			-- Test mode's previews make way for them (groups.lua).
			self:WatchFramesForPreview(unit)
		else
			self.units[unit] = self.oUF:Spawn(unit, 'SaftUI_'..labelName)
		end
	end

	self.RMH = RealMobHealth

	UF:CreateGroupHeaders()
	UF:ApplyConfig()
	UF:UpdateColors()
	UF:RegisterMovers()
	UF:SetupBlizzardRaidFrames()
end