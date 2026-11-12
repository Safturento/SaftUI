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

-- The kind of frame (st.THEME_KINDS) a unit's frames and their bars draw as:
-- a party or raid member's (a group header's, UF.group_strings) as a member,
-- which Blizzard draws as a bare fill; every other unit's (player, target,
-- boss, ...) as a unit frame, which Blizzard draws in the bronze box. Under
-- Thick and Thin both draw as a bar.
function UF.UnitKind(unit)
	return UF.group_strings[unit] and 'member' or 'unitframe'
end

-- The config units a nameplate draws from: Enemy nameplates' and Friendly
-- nameplates' (config/units/nameplate.lua, friendlynameplate.lua).
UF.PLATE_UNITS = { nameplate = true, friendlynameplate = true }

function UF.IsPlateUnit(unit)
	return UF.PLATE_UNITS[unit] == true
end

-- The config unit a plate draws from: an enemy's plate from nameplate, or from
-- friendlynameplate while nameplate.use_friendly; a friend's plate from
-- friendlynameplate, or from nameplate while friendlynameplate.use_enemy. The
-- page keeps the two boxes from being on together; if both are, an enemy is
-- drawn from the Friendly page and a friend from the Enemy page, so nothing
-- depends on the other answer.
function UF.PlateConfigKey(friendly)
	local profile = UF:GetProfileConfig()
	if friendly then
		return profile.friendlynameplate.use_enemy and 'nameplate' or 'friendlynameplate'
	end
	return profile.nameplate.use_friendly and 'friendlynameplate' or 'nameplate'
end

-- Whether the bronze box fits a unit frame or bar of this size (width and
-- height from its config; nil for a side it doesn't set). The box is drawn
-- its inset outside the frame, and that drawn frame must hold the box's two
-- corners (st.ThemeArt.ART.unitframe) on each side, which would overlap on a
-- smaller one: at least 16 for 8px corners, so a bar at least 12 for an inset
-- of 2. Read from the config, so it's known before the frame is sized and
-- nothing is read back off a unit frame.
function UF.BoxFits(width, height)
	local least = 2 * st.ThemeArt.ART.unitframe.size - 2 * st.ThemeArt.Inset('unitframe')
	width, height = tonumber(width), tonumber(height)
	return not ((width and width < least) or (height and height < least))
end

-- The kind a unit frame or one of its bars draws as at its size: its unit's
-- (UF.UnitKind), but a small frame (a line and the fill) where the bronze box
-- doesn't fit (UF.BoxFits), such as a 5-tall power bar. Under Thick and Thin
-- a small frame draws as a bar does.
function UF.SizedKind(unit, width, height)
	local kind = UF.UnitKind(unit)
	if kind == 'unitframe' and not UF.BoxFits(width, height) then return 'small' end
	return kind
end

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
	-- A plate's frame takes no mouse (oUF turned it off), so the mouse stays
	-- the game's: a click on the plate targets its unit. So it gets no clicks
	-- and no hover scripts, which could take the mouse over the plate.
	if not self.isNamePlate then
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
	end

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

	-- oUF enables the elements whose widgets a frame has once this returns,
	-- before any config is applied (UF.InitUnit updates a group button after
	-- that). So a group button's range fade table is made here: its alphas come
	-- from that update (UF:UpdateUnitFrame). Other units get no range fade
	-- (config.lua's Range options are for groups only).
	if self.is_group_unit then
		self.Range = {}
	elseif self.isNamePlate then
		-- The game hands a plate to unit after unit, so its frame is kept by
		-- the plate's number (nameplates.lua), not by its first unit.
		UF.nameplates[self.ID] = self
	else
		UF.allUnits[unit] = self
	end
end

--[[
name (string): the name of the element to use as the key
Constructor (function): for actually creating the element and binding it to oUF
UpdateConfig (function): the function used to update the display of the element based on the configuration table
	Constructor and UpdateConfig take the unitframe object created from oUF:Spawn and the element name.
GetConfigTable (function, optional): GetConfigTable(unit)
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
-- enabled yet (no UF.units) change nothing. The threat colors are only the
-- nameplates' tint and threat text (nameplates/threat.lua): the plates are
-- tinted again, and no other unit frame is updated.
--
-- 'theme' comes after a theme recolor or redraw, which takes a frame's own
-- border color off (st:SetBorderColor): the target's border on its nameplate
-- (nameplates/target.lua: Thick's and Thin's white line, Blizzard's art) is
-- drawn again on every plate, shown or not, as every module colors its own
-- borders again then. target.lua also keeps it with st:KeepOwnColors, which
-- the engine runs first; this puts it back after anything else colored it
-- off too. The plate is rounded to whole pixels again too (UF.RoundLayout,
-- nameplates/pixels.lua): in combat the theme's redraw and the unit frames'
-- update wait apart, and run in no set order once it ends, so the redraw's
-- new art can come after the update's rounding. Each plate on its own, so one
-- that errors leaves the rest drawn.
local UNIT_FRAME_COLOR_GROUPS = { class = true, reaction = true, power = true, status = true, threat = true }
-- ClassPower sets its color only when it checks its visibility, which
-- ForceUpdate runs.
local RECOLORED_ELEMENTS = { 'Health', 'Power', 'AdditionalPower', 'ClassPower' }
function UF:OnColorsChanged(group)
	if group == 'theme' and self.nameplates then
		self:ForEachPlate(function(frame)
			xpcall(self.UpdatePlateTarget, geterrorhandler(), self, frame)
			xpcall(self.RoundLayout, geterrorhandler(), frame, true)
		end)
	end
	if not self.units or not UNIT_FRAME_COLOR_GROUPS[group] then return end
	self:UpdateColors()
	if group == 'threat' then
		for _, frame in pairs(self.nameplates or {}) do
			self:UpdatePlateThreat(frame, true)
		end
		return
	end
	self:ForEachUnitFrame(function(frame)
		-- A frame whose unit doesn't exist (a boss or arena frame out of an
		-- encounter, an empty party slot) has nothing to draw, and its tags
		-- error on a nil name; oUF updates it, with the colors merged above,
		-- when its unit appears. The unit is oUF's active unit (__unit): .unit
		-- is set only by UF.OnEnter, so a frame never hovered has none. A
		-- plate's frame keeps the unit it last showed after the game takes its
		-- plate away (nameplates.lua), so only a plate showing it now counts.
		local unit = frame.__unit
		if not (unit and UnitExists(unit)) then return end
		if frame.isNamePlate and not self:PlateShowsUnit(frame) then return end
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
-- boss/arena frames, group header children, and the plates' frames
-- (nameplates.lua), shown or not.
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
	for _, frame in pairs(self.nameplates or {}) do
		fn(frame)
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

-- Points a frame's cached config, and every element's, text's and icon's, at
-- its config unit's (frame.base_unit) in the current profile. Only plain
-- table writes, so it's safe in combat.
function UF:RefreshFrameConfig(frame)
	frame.config = frame:GetConfig()
	for _, element in pairs(frame.elements or {}) do
		RefreshElementConfig(element)
	end
end

-- Points every frame's and element's cached config at the current profile.
-- Element callbacks (PostUpdate and friends) read those tables, and after a
-- profile switch the old ones have lost their defaults. Only plain table
-- writes, so it's safe in combat.
function UF:RefreshConfigReferences()
	self:ForEachUnitFrame(function(frame) self:RefreshFrameConfig(frame) end)
	for unit, header in pairs(self.groups or {}) do
		header.config = self:GetProfileConfig()[unit]
	end
end

-- Sizes and places one unit frame from frame.config. A group button is only
-- sized: its header places it (and UF:AnchorGroupHeader places the header).
-- Boss/arena 1 sits at the top of its group's holder and the others chain
-- below it. A disabled frame goes off screen, and false is returned for it.
-- A plate's frame is placed on its plate (UF:PlacePlateFrame, nameplates.lua):
-- the game places the plates, and their size is the game's
-- (UF:ApplyPlateSize). Unit frames are secure: out of combat only. A plate's
-- frame isn't, and is placed in combat too (UF:UpdateUnitFrame).
function UF:PlaceUnitFrame(frame)
	if frame.isNamePlate then
		self:PlacePlateFrame(frame)
		return true
	end
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
			local layout = UF.GetUnitGroupLayout(frame.base_unit, config)
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
	local width, height = UF.GetGroupLayoutSize(UF.GetUnitGroupLayout(unit, config), count)
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
		-- A plate's frame is placed in combat too: its unit's kind, and with
		-- it the config and size it's drawn at, can change mid-fight.
		if (frame.isNamePlate or not InCombatLockdown()) and not self:PlaceUnitFrame(frame) then
			return -- disabled, and moved off screen
		end

		local config = frame.config
		st:SetBackdrop(frame, config.theme, config.background, UF.SizedKind(frame.base_unit, config.width, config.height))

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

	if frame.isNamePlate then
		self:RunPlateCallbacks('updated', frame)
	end
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

-- oUF's init callback (UF:OnEnable registers it): runs for every frame oUF
-- builds, after the style function (UF.ConstructUnit) and after oUF has
-- enabled its elements. A group header makes its buttons when it first lays
-- members out (UF:ApplyGroupLayout, or a member joining), and oUF's nameplate
-- driver makes a plate's frame on the plate's first add (nameplates.lua), so
-- those get their first update here: after oUF's own Enables (which turn every
-- aura area on, for one), and with their bars' setters there
-- (UF.SetFactionColorFlags). Single units are spawned in OnEnable, which
-- places and updates them all (UF:ApplyConfig).
function UF.InitUnit(object)
	if not (object.is_group_unit or object.isNamePlate) then return end
	SafeUpdateUnitFrame(object)
	-- A header can still make a button in combat (a member joins), and then the
	-- update can't size it: a unit frame is secure (UF:UpdateUnitFrame skips
	-- UF:PlaceUnitFrame in combat). So it's updated again once combat ends. A
	-- plate's frame isn't secure, and its update in combat is whole.
	if object.is_group_unit and InCombatLockdown() then
		st:QueueAfterCombat('uf_init_' .. object:GetName(), function() SafeUpdateUnitFrame(object) end)
	end
end

-- Clears the points of every frame ApplyConfig places: the single and
-- numbered unit frames, the boss/arena, party and raid holders, and the group
-- headers (their children are placed by the header). The plates' frames keep
-- theirs, on their plates (UF:PlacePlateFrame). Returns each frame's old
-- points, for st:RestorePoints. Unit frames are secure: out of combat only.
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

		UF:ApplyConfig('nameplate', element_name)

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

			-- The group border follows the members' Theme (groups.lua). It
			-- touches only SaftUI's own border, so in combat too.
			xpcall(function() self:UpdateGroupBorder(unit) end, geterrorhandler())

			-- After the buttons are resized, so the header measures them anew.
			if layout then
				xpcall(function() self:ApplyGroupLayout(unit) end, geterrorhandler())
			end
			xpcall(function() self:UpdateGroupPreview(unit) end, geterrorhandler())
		elseif UF.IsPlateUnit(unit) then
			-- The plates' frames (nameplates.lua), which aren't among the units:
			-- oUF's nameplate driver makes them. The plates' size first, set
			-- through the driver from the enemy look's config (none while
			-- SaftUI doesn't draw the plates), so each frame is placed, and its
			-- click area set again, on its plate's new size. Either page's
			-- change, one of the boxes among them, can move a plate to the other
			-- config unit, so each plate's is worked out again
			-- (UF:ApplyPlateConfig): one that moved gets a full update from it,
			-- the others the update asked for. Every plate, whichever page it
			-- draws from, since the threat text is always the Enemy page's
			-- (threat.lua), and a box decides which frames fill their plates.
			if not element_name and self.plateDriver then
				xpcall(function() self:ApplyPlateSize() end, geterrorhandler())
			end
			for _, frame in pairs(self.nameplates or {}) do
				if not self:ApplyPlateConfig(frame) then
					SafeUpdateUnitFrame(frame, element_name)
				end
			end
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
	-- Before anything is spawned, so every frame gets it. Here rather than when
	-- the file loads, where the tests' stand-in oUF has only its colors table.
	self.oUF:RegisterInitCallback(UF.InitUnit)
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

	UF:CreateGroupHeaders()
	UF:ApplyConfig()
	UF:UpdateColors()
	UF:RegisterMovers()
	UF:SetupBlizzardRaidFrames()
	-- The nameplates last, once every other unit is placed and the colors are
	-- set (nameplates.lua). They get no mover: the game places each plate.
	-- SaftUI's plates set the game's nameplate settings; with Nameplates off
	-- the ones SaftUI changed go back as they were. Another nameplate addon's
	-- plates leave them all to it (nameplates/cvars.lua).
	if UF:SpawnNameplates() then
		UF:ApplyNameplateCVars()
	elseif not UF:NameplateAddon() then
		UF:RestoreNameplateCVars()
	end
end