local st = SaftUI
local HZ = st:NewModule('HearthZone')

--[[
	The zone the hearthstone is bound to, as one line on its tooltip. The game
	only names the inn (GetBindLocation: "Lion's Pride Inn"), and no API turns
	that name into a zone, so SaftUI learns it and keeps it per character, in
	st.config.char.hearth = { location = the bind's name, zone = its zone }:

	  - when the player binds (HEARTHSTONE_BOUND): the player is at the
	    innkeeper, so the zone they stand in (GetRealZoneText) is the bind's;
	  - whenever the player stands in the bind's own area (the zone events and
	    the loading screen, with GetSubZoneText or GetMinimapZoneText equal to
	    the bind's name), which every hearth home ends in. So a character
	    bound before this shipped learns its zone the next time it hearths, or
	    walks into the inn.

	A learned zone counts only while its location is still the bind's name; a
	bind made with SaftUI off is not taken for the old one.

	The line: any item tooltip whose text names the bind location (the
	hearthstone's "Use: Returns you to ...", and any toy or item that says the
	same) or that is the Hearthstone itself gets "Zone: <zone>", or, before the
	zone is learned, a line that says how it will be. Nothing when the bind's
	name already is the zone (a city's). From a TooltipDataProcessor post-call
	for items, which writes only the line; on a client without one, nothing.
	A secret value is never compared or shown.
]]

local HEARTHSTONE = 6948

local function Text(value)
	return value ~= nil and not issecretvalue(value) and type(value) == 'string' and value ~= '' and value or nil
end

local function Call(fn) return fn and Text(fn()) end

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
	local location, zone = self:BindLocation(), Call(GetRealZoneText)
	if not (location and zone) then return end
	local store = self:Store()
	store.location, store.zone = location, zone
end

-- Standing in the bind's own area: learn its zone.
function HZ:CheckArea()
	local location = self:BindLocation()
	if not location then return end
	if Call(GetSubZoneText) == location or Call(GetMinimapZoneText) == location then
		self:Learn()
	end
end

-- The bind's zone, or nil while it isn't known for the current bind.
function HZ:Zone()
	local location = self:BindLocation()
	local store = st.config.char and st.config.char.hearth
	if not (location and type(store) == 'table' and store.location == location) then return end
	return Text(store.zone)
end

-- Whether an item's tooltip data is about the hearth: the Hearthstone, or a
-- line that names the bind location.
local function NamesBind(data, location)
	if type(data) ~= 'table' then return false end
	local id = data.id
	if id ~= nil and not issecretvalue(id) and id == HEARTHSTONE then return true end
	if type(data.lines) ~= 'table' then return false end
	for _, line in ipairs(data.lines) do
		local text = type(line) == 'table' and Text(line.leftText)
		if text and text:find(location, 1, true) then return true end
	end
	return false
end

-- The line for an item tooltip's data, or nil for none.
function HZ:TooltipLine(data)
	local location = self:BindLocation()
	if not (location and NamesBind(data, location)) then return end
	local zone = self:Zone()
	if zone == location then return end
	if zone then return 'Zone: ' .. zone end
	return 'Zone: not known yet. Hearth there once to learn it.'
end

function HZ:AddTooltipLine(tooltip, data)
	if not (tooltip and tooltip.AddLine) then return end
	local line = self:TooltipLine(data)
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
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
		HZ:AddTooltipLine(tooltip, data)
	end)
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
