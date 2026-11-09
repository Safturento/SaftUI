-- SaftUI-Misc/tooltip.lua: the skin keeps its backdrop frames in its own weak
-- table and writes nothing onto Blizzard's tooltips, the status bar or the
-- dropdown lists (.agents/taint.md, rule 1), and still colors them.
-- Core's real helpers (st:SetBackdropIn, st:SetTemplate) make the backdrops.
load_core_helpers()

-- The Blizzard frames the module skins, as bare frames. A tooltip has the
-- NineSlice child the module fades, and the close-button-less ones skip that branch.
local function make_tooltip(name)
	local tip = CreateFrame('GameTooltip', name, UIParent)
	tip.NineSlice = CreateFrame('Frame', nil, tip) -- Blizzard's own field, made before SaftUI
	return tip
end

local names = { 'GameTooltip', 'ItemRefTooltip', 'ItemRefShoppingTooltip1', 'ItemRefShoppingTooltip2',
	'ItemRefShoppingTooltip3', 'ShoppingTooltip1', 'ShoppingTooltip2', 'ShoppingTooltip3', 'WorldMapTooltip' }
local tooltips = {}
for _, name in ipairs(names) do tooltips[name] = make_tooltip(name) end
local bar = CreateFrame('StatusBar', 'GameTooltipStatusBar', UIParent)
local dropdowns = {
	CreateFrame('Frame', 'DropDownList1', UIParent),
	CreateFrame('Frame', 'DropDownList2', UIParent),
}
-- The container Blizzard places the default tooltip with (tooltipposition.lua).
CreateFrame('Frame', 'GameTooltipDefaultContainer', UIParent):SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT')

-- Blizzard's function SaftUI post-hooks (GameTooltip_ShowCompareItem takes the tooltip and shows the compare tooltips).
function GameTooltip_ShowCompareItem() end

-- hooksecurefunc replaces a method with a wrapper in the frame's table; that's
-- the game's own mechanism for a post-hook, not a field SaftUI sets, so the
-- hooked names are left out of the comparison.
local hooked_methods = { GetUnit = true, Show = true }
local function keys(frame)
	local list = {}
	for k in pairs(frame) do
		if not hooked_methods[k] then list[#list + 1] = tostring(k) end
	end
	table.sort(list)
	return table.concat(list, ',')
end

local blizzard = { bar, dropdowns[1], dropdowns[2] }
for _, name in ipairs(names) do blizzard[#blizzard + 1] = tooltips[name] end
local before = {}
for _, frame in ipairs(blizzard) do before[frame] = keys(frame) end

for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
	load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua')
end
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_saftui('SaftUI-Misc/tooltip.lua')
load_saftui('SaftUI-Misc/tooltipposition.lua')

local st = SaftUI
local TT = st:GetModule('Tooltip')
TT:Enable()
local enable_errors = take_errors()

-- The SaftUI backdrop frame of a skinned frame: the child of it that has a
-- backdrop and the template the module set.
local function backdrop_of(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.template ~= nil then return child end
	end
end

test('enabling the module raised no error', function()
	eq(#enable_errors, 0, 'errors: ' .. table.concat(enable_errors, '; '))
end)

test('skinning adds no field to any Blizzard frame it skins', function()
	for _, frame in ipairs(blizzard) do
		eq(keys(frame), before[frame], (frame:GetName() or '?') .. ' keys unchanged')
	end
end)

test('every skinned frame got a SaftUI backdrop in the profile template', function()
	for _, frame in ipairs(blizzard) do
		local backdrop = backdrop_of(frame)
		check(backdrop ~= nil, (frame:GetName() or '?') .. ' has a backdrop child')
		if backdrop then eq(backdrop.template, TT.config.template, 'template') end
	end
end)

test('a unit tooltip colors the border of the tooltip and the status bar', function()
	local c = { r = 0.1, g = 0.2, b = 0.3 }
	_G.UnitName = function() return 'Someone' end
	_G.UnitPlayerControlled = function() return true end
	_G.UnitClass = function() return 'Mage', 'MAGE' end
	_G.RAID_CLASS_COLORS = { MAGE = c }
	local left1 = tooltips.GameTooltip:CreateFontString('GameTooltipTextLeft1', 'ARTWORK')
	left1:SetFontObject(GameFontNormal)
	TT:GameTooltip_OnTooltipSetUnit(tooltips.GameTooltip)
	for _, frame in ipairs({ tooltips.GameTooltip, bar }) do
		local r, g, b = backdrop_of(frame):GetBackdropBorderColor()
		check(r == c.r and g == c.g and b == c.b, (frame:GetName()) .. ' border is the class color')
	end
	eq(keys(tooltips.GameTooltip), before[tooltips.GameTooltip], 'still no new field')
end)

test('UpdateConfig finds the same backdrops and re-colors them for a new template', function()
	local backdrop = backdrop_of(tooltips.ShoppingTooltip1)
	st.config.profile.templates.thick.bordercolor = { 0.9, 0.8, 0.7, 1 }
	TT.config.template = 'thick'
	TT:UpdateConfig()
	eq(backdrop_of(tooltips.ShoppingTooltip1), backdrop, 'the backdrop frame is reused')
	eq(backdrop.template, 'thick', 'template updated')
	local r, g, b = backdrop:GetBackdropBorderColor()
	check(r == 0.9 and g == 0.8 and b == 0.7, 'border re-colored')
	for _, frame in ipairs(blizzard) do
		eq(keys(frame), before[frame], (frame:GetName() or '?') .. ' keys unchanged after UpdateConfig')
	end
end)

test('a none template clears the backdrop and writes nothing', function()
	TT.config.template = 'none'
	TT:UpdateConfig()
	for _, frame in ipairs(blizzard) do
		eq(keys(frame), before[frame], (frame:GetName() or '?') .. ' keys unchanged')
	end
	eq(backdrop_of(tooltips.GameTooltip).backdropInfo, nil, 'backdrop cleared')
end)
