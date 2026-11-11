-- SaftUI-Misc/tooltip.lua: the skin keeps its backdrop frames in its own weak
-- table and writes nothing onto Blizzard's tooltips, the status bar or the
-- dropdown lists (.agents/taint.md, rule 1), and still colors them: the
-- tooltips and dropdown lists drawn as tooltips and the status bar as a bar, in
-- the Tooltip page's Theme and Background, and a unit tooltip's class or
-- reaction border kept through a theme recolor.
-- Core's real helpers (st:SetBackdropIn, st:SetTemplate) make the backdrops.
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()

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
-- GameTooltip's name line, which Blizzard makes before SaftUI loads and the unit hook colors.
local left1 = tooltips.GameTooltip:CreateFontString('GameTooltipTextLeft1', 'ARTWORK')
left1:SetFontObject(GameFontNormal)
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

-- The SaftUI backdrop frame of a skinned frame: its child with Blizzard's
-- Backdrop mixin, which st:CreateFrame gives SaftUI's frames (Blizzard's
-- NineSlice here has none, and these tooltips have no close button).
local function backdrop_of(frame)
	for _, child in ipairs({ frame:GetChildren() }) do
		if child.SetBackdrop then return child end
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

test("every skinned frame got a SaftUI backdrop in the Tooltip page's Theme and Background", function()
	for _, frame in ipairs(blizzard) do
		local backdrop = backdrop_of(frame)
		check(backdrop ~= nil, (frame:GetName() or '?') .. ' has a backdrop child')
		if backdrop then eq(T.inset(backdrop), 2, (frame:GetName() or '?') .. ": Thick's border") end
		local kind = frame == bar and 'bar' or 'tooltip'
		eq(drawn(frame), 'theme,theme,' .. kind, (frame:GetName() or '?') .. ' is drawn as a ' .. kind)
	end
end)

test('a unit tooltip colors the border of the tooltip and the status bar', function()
	local c = { r = 0.1, g = 0.2, b = 0.3 }
	_G.UnitName = function() return 'Someone' end
	_G.UnitPlayerControlled = function() return true end
	_G.UnitClass = function() return 'Mage', 'MAGE' end
	st.config.profile.colors.class.MAGE = c
	_G.RAID_CLASS_COLORS = { MAGE = { r = 0.9, g = 0.9, b = 0.9 } } -- Blizzard's, not used
	TT:GameTooltip_OnTooltipSetUnit(tooltips.GameTooltip)
	for _, frame in ipairs({ tooltips.GameTooltip, bar }) do
		local r, g, b = backdrop_of(frame):GetBackdropBorderColor()
		check(r == c.r and g == c.g and b == c.b, (frame:GetName()) .. ' border is the class color')
	end
	local tr, tg, tb = left1:GetTextColor()
	check(tr == c.r and tg == c.g and tb == c.b, "the name line is the profile's class color")
	eq(keys(tooltips.GameTooltip), before[tooltips.GameTooltip], 'still no new field')
end)

test('an NPC tooltip takes the profile reaction color', function()
	local c = { r = 0.4, g = 0.5, b = 0.6 }
	_G.UnitName = function() return 'Someone' end
	_G.UnitPlayerControlled = function() return false end
	_G.UnitReaction = function() return 2 end
	st.config.profile.colors.reaction[2] = c
	_G.FACTION_BAR_COLORS = { [2] = { r = 0.9, g = 0.9, b = 0.9 } } -- Blizzard's, not used
	TT:GameTooltip_OnTooltipSetUnit(tooltips.GameTooltip)
	for _, frame in ipairs({ tooltips.GameTooltip, bar }) do
		local r, g, b = backdrop_of(frame):GetBackdropBorderColor()
		check(r == c.r and g == c.g and b == c.b, (frame:GetName()) .. ' border is the reaction color')
	end
	local tr, tg, tb = left1:GetTextColor()
	check(tr == c.r and tg == c.g and tb == c.b, "the name line is the profile's reaction color")
end)

-- The game can make a unit's class or reaction a secret value (a world-cursor
-- unit on Forever: BugGrabber, tooltip.lua:71, "attempted to index a table
-- that cannot be indexed with secret keys"). The stubs have no secret values,
-- so one is stood in for: a key issecretvalue reports, which SaftUI's own
-- color tables refuse as the game's do. Blizzard's C_ClassColor.GetClassColor
-- takes a secret class.
local SECRET = setmetatable({}, { __tostring = function() return '<secret>' end })
local function with_secrets(fn)
	local was_secret, was_classcolor = _G.issecretvalue, _G.C_ClassColor
	local colors = st.config.profile.colors
	local refuse = { __index = function(_, key)
		if key == SECRET then error('attempted to index a table that cannot be indexed with secret keys', 2) end
	end }
	local class_mt, reaction_mt = getmetatable(colors.class), getmetatable(colors.reaction)
	setmetatable(colors.class, refuse)
	setmetatable(colors.reaction, refuse)
	_G.issecretvalue = function(v) return v == SECRET end
	local ok, err = pcall(fn)
	_G.issecretvalue, _G.C_ClassColor = was_secret, was_classcolor
	setmetatable(colors.class, class_mt)
	setmetatable(colors.reaction, reaction_mt)
	if not ok then error(err, 0) end
end

test("a player whose class is secret takes Blizzard's class color, with no error", function()
	with_secrets(function()
		local blizzard = { r = 0.7, g = 0.6, b = 0.5 }
		_G.UnitName = function() return 'Someone' end
		_G.UnitPlayerControlled = function() return true end
		_G.UnitClass = function() return 'Mage', SECRET end
		_G.C_ClassColor = { GetClassColor = function(class) return class == SECRET and blizzard or nil end }
		TT:GameTooltip_OnTooltipSetUnit(tooltips.GameTooltip)
		for _, frame in ipairs({ tooltips.GameTooltip, bar }) do
			local r, g, b = backdrop_of(frame):GetBackdropBorderColor()
			check(r == blizzard.r and g == blizzard.g and b == blizzard.b, frame:GetName() .. " border is Blizzard's class color")
		end
		local tr, tg, tb = left1:GetTextColor()
		check(tr == blizzard.r and tg == blizzard.g and tb == blizzard.b, "the name line is Blizzard's class color")
	end)
end)

test('a unit whose reaction is secret is left uncolored, with no error', function()
	with_secrets(function()
		left1:SetTextColor(0.11, 0.22, 0.33)
		_G.UnitName = function() return 'Someone' end
		_G.UnitPlayerControlled = function() return false end
		_G.UnitReaction = function() return SECRET end
		TT:GameTooltip_OnTooltipSetUnit(tooltips.GameTooltip)
		local tr, tg, tb = left1:GetTextColor()
		check(tr == 0.11 and tg == 0.22 and tb == 0.33, 'the name line keeps the color it had')
	end)
end)

test('UpdateConfig finds the same backdrops and re-colors them for a new Theme and Background', function()
	local backdrop = backdrop_of(tooltips.ShoppingTooltip1)
	st.config.profile.templates.thick.bordercolor = { 0.9, 0.8, 0.7, 1 }
	TT.config.theme, TT.config.background = 'thick', 'solid'
	TT:UpdateConfig()
	eq(backdrop_of(tooltips.ShoppingTooltip1), backdrop, 'the backdrop frame is reused')
	eq(drawn(tooltips.ShoppingTooltip1), 'thick,solid,tooltip', 'Theme and Background updated')
	eq(select(4, backdrop:GetBackdropColor()), 1, 'Solid')
	local r, g, b = backdrop:GetBackdropBorderColor()
	check(r == 0.9 and g == 0.8 and b == 0.7, 'border re-colored')
	for _, frame in ipairs(blizzard) do
		eq(keys(frame), before[frame], (frame:GetName() or '?') .. ' keys unchanged after UpdateConfig')
	end
end)

test('a None theme clears the backdrop and writes nothing', function()
	TT.config.theme = 'none'
	TT:UpdateConfig()
	for _, frame in ipairs(blizzard) do
		eq(keys(frame), before[frame], (frame:GetName() or '?') .. ' keys unchanged')
	end
	eq(backdrop_of(tooltips.GameTooltip).backdropInfo, nil, 'backdrop cleared')
end)

test("a unit tooltip's class border survives a theme recolor, until the tooltip shows something else", function()
	TT.config.theme, TT.config.background = 'theme', 'theme'
	TT:UpdateConfig()
	local tip = tooltips.GameTooltip
	local c = { r = 0.1, g = 0.2, b = 0.3 }
	_G.UnitName = function() return 'Someone' end
	_G.UnitPlayerControlled = function() return true end
	_G.UnitClass = function() return 'Mage', 'MAGE' end
	st.config.profile.colors.class.MAGE = c
	tip:Show()
	TT:GameTooltip_OnTooltipSetUnit(tip)
	local saved = st.config.profile.templates.thick.bordercolor
	for _ = 1, 3 do
		st.config.profile.templates.thick.bordercolor = { 0.7, 0.1, 0.1, 1 }
		st:RecolorThemed()
	end
	for _, frame in ipairs({ tip, bar }) do
		eq(T.edge(backdrop_of(frame)), '0.10,0.20,0.30,1.00', frame:GetName() .. ' keeps the class color through a recolor')
	end
	eq(T.edge(backdrop_of(tooltips.ShoppingTooltip1)), '0.70,0.10,0.10,1.00', 'another tooltip takes the new border color')

	-- Shown again for something else (an item): the theme's border.
	tip:Hide()
	tip:Show()
	st:RecolorThemed()
	eq(T.edge(backdrop_of(tip)), '0.70,0.10,0.10,1.00', 'shown again, the tooltip takes the theme border')
	st.config.profile.templates.thick.bordercolor = saved
	st:RecolorThemed()
	eq(keys(tip), before[tip], 'still no new field')
end)
