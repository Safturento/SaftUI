local st = SaftUI
local DUR = st:GetModule('Durability')

--[[
	The durability figure's tooltip (durability.lua has the figure). Blizzard's
	DurabilityFrame has a tooltip of its own on both clients: its OnEnter (the
	XML's script) makes GameTooltip owned by the figure, at ANCHOR_BOTTOMLEFT,
	with the title "Repair Armor" and one line, and shows it, while any slot is
	damaged or broken. SaftUI adds to it from a HookScript post-hook on that
	OnEnter, only while GameTooltip is owned by the figure, so it never touches
	another tooltip, and hooks nothing on GameTooltip itself (SaftUI's tooltip
	module and every other addon's lines are unaffected).

	Under Blizzard's lines: a blank line, then one line per equipped slot with
	durability below 100%, lowest first (the item's name in its quality color,
	its percent in green from 50%, orange from 20% and red under that: the Colors
	page's text colors), then Repair cost, the sum for every equipped item, in
	the game's coin string. A slot at 100% or with no durability is left out;
	with every slot at 100% nothing is added.

	The sources, each guarded by presence: GetInventoryItemDurability for the
	current and maximum, GetInventoryItemLink for the name, GetInventoryItemQuality
	for the color, and C_TooltipInfo.GetInventoryItem('player', slot).repairCost for
	the cost (both clients' TooltipData has it; Blizzard's TooltipDataRules reads
	it). A secret value is never compared, added or formatted: a slot whose
	durability is secret is left out, a secret quality or link gives an
	uncolored name or the slot's own name, and a damaged item whose cost is secret
	or missing leaves the Repair cost line out (a partial sum would be wrong).
]]

-- The inventory slots that can have durability, with the name the game gives the
-- slot (its GlobalString) for when an item's own can't be read.
local SLOTS = {
	{ 1, 'HEADSLOT' }, { 3, 'SHOULDERSLOT' }, { 5, 'CHESTSLOT' }, { 6, 'WAISTSLOT' },
	{ 7, 'LEGSSLOT' }, { 8, 'FEETSLOT' }, { 9, 'WRISTSLOT' }, { 10, 'HANDSSLOT' },
	{ 16, 'MAINHANDSLOT' }, { 17, 'SECONDARYHANDSLOT' }, { 18, 'RANGEDSLOT' },
}

local function Plain(value)
	return value ~= nil and not issecretvalue(value)
end

local function Number(value)
	return Plain(value) and type(value) == 'number' and value or nil
end

local function Hex(color)
	local function byte(v) return math.floor(math.min(1, math.max(0, v)) * 255 + 0.5) end
	return ('|cff%02x%02x%02x'):format(byte(color.r), byte(color.g), byte(color.b))
end

-- The Colors page's text color for a durability ratio: Success, Warning or Danger.
local function PercentColor(ratio)
	if ratio >= 0.5 then return st:Color('text', 'success') end
	if ratio >= 0.2 then return st:Color('text', 'warning') end
	return st:Color('text', 'danger')
end

-- The item's name in slot, from its link's [name]; the slot's own name when
-- that can't be read.
local function ItemName(slot, slotName)
	local link = GetInventoryItemLink and GetInventoryItemLink('player', slot)
	local name = Plain(link) and type(link) == 'string' and link:match('%[(.-)%]')
	if name and name ~= '' then return name end
	return _G[slotName] or ('Slot ' .. slot)
end

-- The item in slot's repair cost, or nil when it can't be told (an item at full
-- durability has none: Blizzard's tooltip data leaves the field out).
local function RepairCost(slot)
	if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return end
	local data = C_TooltipInfo.GetInventoryItem('player', slot)
	if not Plain(data) or type(data) ~= 'table' then return end
	return Number(data.repairCost)
end

-- The game's coin string for an amount of copper, or nil with neither API.
local function MoneyString(copper)
	if GetMoneyString then return GetMoneyString(copper) end
	if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then return C_CurrencyInfo.GetCoinTextureString(copper) end
end

-- The detail lines for the tooltip: { { left, right }, ... }, the repair cost
-- last. Empty when there's nothing damaged to show or no API to read it.
function DUR:GetTooltipLines()
	if not GetInventoryItemDurability then return {} end
	local items, total, unknown = {}, 0, false
	for _, entry in ipairs(SLOTS) do
		local slot, slotName = entry[1], entry[2]
		local current, maximum = GetInventoryItemDurability(slot)
		current, maximum = Number(current), Number(maximum)
		if current and maximum and maximum > 0 then
			if current < maximum then
				-- Only a damaged item has a repair cost; one whose cost can't be
				-- read makes the sum a guess.
				local cost = RepairCost(slot)
				if cost then total = total + cost else unknown = true end
				local quality = GetInventoryItemQuality and GetInventoryItemQuality('player', slot)
				local color = Number(quality) and st:QualityColor(quality)
				local name = ItemName(slot, slotName)
				if color then name = Hex(color) .. name .. '|r' end
				local ratio = current / maximum
				items[#items + 1] = {
					ratio = ratio, slot = slot, left = name,
					right = Hex(PercentColor(ratio)) .. math.floor(ratio * 100) .. '%|r',
				}
			end
		end
	end
	if #items == 0 then return {} end
	table.sort(items, function(a, b)
		if a.ratio ~= b.ratio then return a.ratio < b.ratio end
		return a.slot < b.slot
	end)
	local lines = {}
	for i, item in ipairs(items) do lines[i] = { item.left, item.right } end
	local money = not unknown and MoneyString(total)
	if money then lines[#lines + 1] = { _G.REPAIR_COST and _G.REPAIR_COST:gsub(':%s*$', ''):gsub('\239\188\154%s*$', '') or 'Repair cost', money } end
	return lines
end

-- Adds the lines under Blizzard's, while the figure owns the tooltip.
function DUR:AddTooltipLines()
	local frame = self.frame
	if not (self.config.tooltip_details and frame and GameTooltip:IsOwned(frame)) then return end
	local lines = self:GetTooltipLines()
	if #lines == 0 then return end
	GameTooltip:AddLine(' ')
	for _, line in ipairs(lines) do
		GameTooltip:AddDoubleLine(line[1], line[2], 1, 1, 1, 1, 1, 1)
	end
	-- The tooltip is sized for the lines it had when Blizzard showed it.
	GameTooltip:Show()
end

function DUR:SetupTooltip()
	self.frame:HookScript('OnEnter', function() self:AddTooltipLines() end)
end
