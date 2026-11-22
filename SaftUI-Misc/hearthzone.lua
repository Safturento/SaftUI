local st = SaftUI
local HZ = st:NewModule('HearthZone')

--[[
	The zone the hearthstone is bound to, as one line on its tooltip. The game
	only names the inn (GetBindLocation: "Lion's Pride Inn"), and no API turns
	that name into a zone, so SaftUI learns it and keeps it per character, in
	st.config.char.hearth = { location = the bind's name, zone = its zone }:

	  - when the player binds (HEARTHSTONE_BOUND): the player is at the
	    innkeeper, so the zone they stand in is the bind's. The zone is the
	    world zone from the map (C_Map: the player's map, walked up through
	    its parents past any Micro, Dungeon or Orphan map to the first Zone
	    map), since GetRealZoneText can name the inn's own area (Forever's
	    Farholde Keep); GetRealZoneText only when there is no map;
	  - whenever the player stands in the bind's own area (the zone events and
	    the loading screen, with GetSubZoneText or GetMinimapZoneText equal to
	    the bind's name), which every hearth home ends in. So a character
	    bound before this shipped learns its zone the next time it hearths, or
	    walks into the inn;
	  - whenever the zone itself has the bind's name (a bind that names its
	    city): the zone is the bind, and no line is needed.

	A learned zone counts only while its location is still the bind's name; a
	bind made with SaftUI off is not taken for the old one.

	The line goes on:
	  - the Hearthstone and the hearthstone toys (HEARTH_ITEMS), by item ID;
	  - any other item or toy with a "Use:" line (ITEM_SPELL_TRIGGER_ONUSE)
	    that names the bind location, as every hearth item's "Use: Returns you
	    to ..." does, so a toy not in the list (Forever's own) is caught too; a
	    line that only mentions the name is not enough;
	  - the hearth spells (HEARTH_SPELLS: the Hearthstone's own and Astral
	    Recall), by spell ID, and any spell whose text names the bind location
	    (a spell has no "Use:" line).
	It says "Zone: <zone>", or, before the zone is learned, how it will be.
	Nothing when the bind's name already is the zone (a city's). From
	TooltipDataProcessor post-calls for items, toys and spells, which write
	only the line (Blizzard's handler shows the tooltip again after its
	post-calls, so it is sized for it); on a client without one, nothing. A
	secret value is never compared or shown.
]]

-- The Hearthstone and the hearthstone toys (an ID no client has is harmless).
local HEARTH_ITEMS = {
	[6948] = true, -- Hearthstone
	[54452] = true, [64488] = true, [93672] = true, [142542] = true, [162973] = true,
	[163045] = true, [165669] = true, [165670] = true, [165802] = true, [166746] = true,
	[166747] = true, [168907] = true, [172179] = true, [180290] = true, [182773] = true,
	[183716] = true, [184353] = true, [188952] = true, [190196] = true, [190237] = true,
	[193588] = true, [200630] = true, [206195] = true, [208704] = true, [209035] = true,
	[210455] = true, [212337] = true, [228940] = true, [235016] = true, [236687] = true,
	[246565] = true,
}

-- The spells that take the player to the bind.
local HEARTH_SPELLS = {
	[8690] = true, -- Hearthstone (the item's spell, on a bar or in a macro)
	[556] = true, -- Astral Recall
}

local function Text(value)
	value = st.PlainString(value)
	return value ~= '' and value or nil
end

local function Call(fn) return fn and Text(fn()) end

-- Records written before the zone came from the map hold the inn's area for
-- some binds, so only this version counts.
local VERSION = 2

-- The world zone the player stands in: the first Zone map up from the
-- player's map, else GetRealZoneText.
function HZ:WorldZone()
	local zoneType = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
	local mapID = C_Map and C_Map.GetBestMapForUnit and st.PlainNumber(C_Map.GetBestMapForUnit('player'))
	for _ = 1, 10 do
		if not mapID or mapID == 0 then break end
		local info = C_Map.GetMapInfo(mapID)
		if type(info) ~= 'table' then break end
		local mapType = st.PlainNumber(info.mapType)
		if not mapType or mapType < zoneType then break end -- a continent or above: no zone
		if mapType == zoneType then return Text(info.name) end
		mapID = st.PlainNumber(info.parentMapID)
	end
	return Call(GetRealZoneText)
end

-- The per-character record, made on first use.
function HZ:Store()
	local char = st.config.char
	if type(char.hearth) ~= 'table' then char.hearth = {} end
	return char.hearth
end

-- The bind's name now, or nil.
function HZ:BindLocation() return Call(GetBindLocation) end

-- Takes the zone the player stands in as the bind's.
function HZ:Learn()
	local location, zone = self:BindLocation(), self:WorldZone()
	if not (location and zone) then return end
	local store = self:Store()
	store.location, store.zone, store.version = location, zone, VERSION
end

-- Standing in the bind's own area: learn its zone.
function HZ:CheckArea()
	local location = self:BindLocation()
	if not location then return end
	if Call(GetSubZoneText) == location or Call(GetMinimapZoneText) == location
			or Call(GetRealZoneText) == location then
		self:Learn()
	end
end

-- The bind's zone, or nil while it isn't known for the current bind.
function HZ:Zone()
	local location = self:BindLocation()
	local store = st.config.char and st.config.char.hearth
	if not (location and type(store) == 'table' and store.location == location and store.version == VERSION) then return end
	return Text(store.zone)
end

-- Whether a tooltip's data is about the hearth: an ID in ids, or a line that
-- names the bind location (and, when use is given, holds it).
local function NamesBind(data, location, ids, use)
	if type(data) ~= 'table' then return false end
	local id = st.PlainNumber(data.id)
	if id and ids[id] then return true end
	if type(data.lines) ~= 'table' then return false end
	for _, line in ipairs(data.lines) do
		local text = type(line) == 'table' and Text(line.leftText)
		if text and (not use or text:find(use, 1, true)) and text:find(location, 1, true) then return true end
	end
	return false
end

-- The line for an item, toy or (spell true) spell tooltip's data, or nil for none.
function HZ:TooltipLine(data, spell)
	local location = self:BindLocation()
	if not location then return end
	local about
	if spell then
		about = NamesBind(data, location, HEARTH_SPELLS)
	else
		about = NamesBind(data, location, HEARTH_ITEMS, Text(ITEM_SPELL_TRIGGER_ONUSE) or 'Use:')
	end
	if not about then return end
	local zone = self:Zone()
	if zone == location then return end
	if zone then return 'Zone: ' .. zone end
	return 'Zone: not known yet. Hearth there once to learn it.'
end

function HZ:AddTooltipLine(tooltip, data, spell)
	if not (tooltip and tooltip.AddLine) then return end
	local line = self:TooltipLine(data, spell)
	if not line then return end
	local color = NORMAL_FONT_COLOR
	if color then
		tooltip:AddLine(line, color.r, color.g, color.b)
	else
		tooltip:AddLine(line)
	end
end

-- Registers the post-call once. Returns whether it is registered.
function HZ:HookTooltips()
	if self.tooltipPostCall then return true end
	if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
			and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item) then
		return false
	end
	local function post(tooltip, data) HZ:AddTooltipLine(tooltip, data) end
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, post)
	-- A toy's tooltip (the toy box, a toy on a bar) is its own type on retail.
	if Enum.TooltipDataType.Toy then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Toy, post)
	end
	if Enum.TooltipDataType.Spell then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
			HZ:AddTooltipLine(tooltip, data, true)
		end)
	end
	self.tooltipPostCall = true
	return true
end

function HZ:OnEnable()
	self:RegisterEvent('HEARTHSTONE_BOUND', 'Learn')
	for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA' }) do
		self:RegisterEvent(event, 'CheckArea')
	end
	self:HookTooltips()
	self:CheckArea()
end
