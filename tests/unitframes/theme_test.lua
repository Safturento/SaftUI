-- The unit frames with SaftUI's theme (SaftUI-Core/theme.lua):
--   - every unit's and element's Theme and Background default draws exactly
--     what its template default drew before themes;
--   - each part of a unit frame draws as its kind: the unit frame and its bars
--     as bars, the aura buttons as auras, and the castbar's icon, the class
--     power points and the indicators as small;
--   - a config update draws no backdrop on the aura and class power areas
--     (their buttons and points are drawn), so nothing of SaftUI's is anchored
--     to Blizzard's aura container (.agents/taint.md, rule 11);
--   - a boss or party test mode preview draws like its real frame (groups.lua);
--   - an aura button's dispel type fill keeps its color through a theme
--     recolor and redraw, and the dark line SaftUI draws over it follows the
--     theme (elements/auras.lua).
--
-- Real: Core's helpers and profile defaults, the unit frames' defaults (every
-- unit's), filled the way AceDB fills them; unitframes.lua (UF:UpdateUnitFrame,
-- UF:ApplyConfig, UF:RegisterElement); groups.lua (the previews);
-- config/config.lua (UF:GetProfileConfig); constructors.lua and updaters.lua;
-- the health, power, additional power, castbar, class power, aura and
-- indicator elements, whose constructors build the parts and whose
-- UpdateConfig draws them; LibStringFormat-1.0, which init.lua makes
-- st.StringFormat.
--
-- Stand-ins, for what needs oUF:
--   * UF.oUF, as far as unitframes.lua and the previews use it: its colors
--     table, into which UF:UpdateColors merges the profile's.
--   * A unit frame (make_unit_frame): in game oUF:Spawn makes it and
--     UF.ConstructUnit gives it its text overlay, config and elements, by the
--     elements' own constructors. Here a SaftUI button with ConstructUnit's
--     fields and only the elements a test names, built by those same
--     constructors; oUF's UpdateAllElements is a no-op.
--   * The aura container (frame:CreateAuras in make_unit_frame): oUF's
--     CreateAuras makes a Blizzard AuraContainer, which makes a button for
--     each aura that shows and hands it to PostCreateButton, and tints the
--     button's dispel type texture (Border) with a secret color. Here a plain
--     frame with the methods auras.lua's UpdateConfig calls on it (oUF's
--     AddGroup, which gives a group key, and the container's SetEnabled, flow
--     layout setters and SetAuraGroupLayout, which here only take their
--     arguments), and the test hands PostCreateButton a button with oUF's
--     Icon, Count and Border, and tints the Border itself.
--
-- The kind a frame is drawn with changes nothing under Thick and Thin, so the
-- draw calls are watched: st:SetBackdrop is wrapped to note its arguments, and
-- still draws.
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
for _, unit in ipairs({ 'arena', 'boss', 'focus', 'focustarget', 'party', 'pet', 'pettarget', 'player', 'raid10', 'raid40', 'target', 'targettarget' }) do
	load_saftui('SaftUI-Unitframes/config/units/' .. unit .. '.lua')
end
apply_defaults()
addon_namespace('SaftUI-Unitframes').oUF = {
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
}
load_saftui('SaftUI-Unitframes/unitframes.lua')
load_saftui('SaftUI-Unitframes/groups.lua')
load_saftui('SaftUI-Unitframes/config/config.lua')
load_saftui('SaftUI-Unitframes/constructors.lua')
load_saftui('SaftUI-Unitframes/updaters.lua')
for _, file in ipairs({ 'auras', 'power', 'additionalpower', 'health', 'castbar', 'classpower', 'indicators' }) do
	load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
end
load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')

local st = SaftUI
st.StringFormat = LibStub('LibStringFormat-1.0')
local UF = st:GetModule('Unitframes')
local P = UF:GetProfileConfig()
UF:UpdateColors()

-- draws[frame] is the theme, background and kind frame was last drawn with.
local draws = setmetatable({}, { __mode = 'k' })
do
	local real = st.SetBackdrop
	st.SetBackdrop = function(self, frame, theme, background, kind)
		draws[frame] = { theme, background, kind }
		return real(self, frame, theme, background, kind)
	end
end

-- How frame was last drawn: 'theme,background,kind' ('nil' for what wasn't
-- passed), or nil if it wasn't.
local function drawn(frame)
	local d = draws[frame]
	if not d then return nil end
	return ('%s,%s,%s'):format(tostring(d[1]), tostring(d[2]), tostring(d[3]))
end

-- What a frame's backdrop shows: its border's inset, fill and edge colors, and
-- whether Thick's outer lines show; 'bare' for none.
local function looks(frame)
	local backdrop = frame.backdrop
	if not (backdrop and backdrop.backdropInfo) then return 'bare' end
	local outer = backdrop.altborder and backdrop.altborder.LEFT:IsShown() and 'outer' or 'no outer'
	local r, g, b, a = backdrop:GetBackdropColor()
	local er, eg, eb, ea = backdrop:GetBackdropBorderColor()
	return ('inset %d, fill %.2f,%.2f,%.2f,%.2f, edge %.2f,%.2f,%.2f,%.2f, %s'):format(
		backdrop.backdropInfo.insets.left, r, g, b, a, er, eg, eb, ea or 1, outer)
end

-- A unit frame for a config unit, with the named elements built by their own
-- constructors (see the top of this file).
local function make_unit_frame(name, unit, elements, parent)
	local frame = CreateFrame('Button', name, parent or UIParent)
	frame.base_unit = unit
	frame.GetConfig = function() return UF:GetProfileConfig()[unit] end
	frame.config = frame:GetConfig()
	function frame:UpdateAllElements() end
	function frame:CreateAuras()
		local auras = CreateFrame('Frame', nil, self)
		function auras:SetEnabled() end
		function auras:SetFlowLayoutAnchorPoint() end
		function auras:SetFlowLayoutMaximumLineSize() end
		function auras:SetFlowLayoutGrowthDirection() end
		function auras:AddGroup() return 'Group1' end
		function auras:SetAuraGroupLayout() end
		return auras
	end
	local overlay = CreateFrame('Frame', nil, frame)
	overlay:SetFrameLevel(99)
	overlay:SetAllPoints(frame)
	frame.TextOverlay = overlay
	frame.elements = {}
	for _, element in ipairs(elements) do
		frame.elements[element] = UF.elements[element].Constructor(frame, element)
	end
	return frame
end

-- A button oUF's aura container made for an aura, handed to the element's
-- PostCreateButton as oUF does (see the top of this file).
local function make_aura_button(auras)
	local button = CreateFrame('Button', nil, auras)
	button:SetSize(24, 24)
	button:SetPoint('TOPLEFT')
	button.Icon = button:CreateTexture(nil, 'BORDER')
	button.Icon:SetAllPoints()
	button.Count = button:CreateFontString(nil, 'OVERLAY')
	button.Border = button:CreateTexture(nil, 'OVERLAY')
	button.Border:SetAllPoints()
	auras:PostCreateButton(button)
	return button
end

local function rgba(r, g, b, a) return ('%.2f,%.2f,%.2f,%.2f'):format(r, g, b, a or 1) end

------------------------------------------------------------------ defaults

-- What each part of each unit drew before themes: the template defaults of
-- default.lua and config/units/*.lua at 7ec1df8, as AceDB filled them in.
-- Every unit drew BASE, but for its own in OLD.
local BASE = {
	frame = 'none', health = 'thicktransparent', power = 'thicktransparent', additionalpower = 'thick',
	castbar = 'thin', ['castbar.icon'] = 'thick', classpower = 'none', buffs = 'thick', debuffs = 'thick',
	portrait = 'none', name = 'none', aurawatch = 'none', questindicator = 'none', raidroleindicator = 'none',
	grouproleindicator = 'none', readycheckindicator = 'none', raidtargetindicator = 'none',
}
local OLD = {
	player = { castbar = 'thicktransparent', classpower = 'thicktransparent' },
	target = { castbar = 'thicktransparent' },
	focus = { castbar = 'thicktransparent' },
	raid10 = { frame = 'thick', buffs = 'thin', debuffs = 'thin' },
	raid40 = { frame = 'thick', buffs = 'thin', debuffs = 'thin' },
	targettarget = {}, focustarget = {}, pet = {}, pettarget = {}, boss = {}, arena = {}, party = {},
}
-- An old default's Theme and Background (global-constraints.md's table).
local NEW = {
	thicktransparent = 'theme,theme', thick = 'theme,solid', thin = 'thin,solid', thintransparent = 'thin,theme', none = 'none,theme',
}

-- A part's config: the unit's own for its frame, the castbar's icon's, or the
-- element's.
local function part_config(unit, part)
	if part == 'frame' then return P[unit] end
	if part == 'castbar.icon' then return P[unit].castbar.icon end
	return P[unit][part]
end

-- A look by its name, inset and alpha; 'none' for no look.
local function describe(look)
	if not look then return 'none' end
	return ('%s %d %.2f'):format(look.name, look.inset, look.alpha)
end

test('every unit frame default looks as it did', function()
	local profile = st.config.profile.theme
	check(profile.name == 'thick' and profile.transparent and profile.opacity == 0.9, "SaftUI's default theme, today's thicktransparent")
	local count = 0
	for unit, own in pairs(OLD) do
		for part, base in pairs(BASE) do
			local old = own[part] or base
			local config = part_config(unit, part)
			local where = ('%s.%s (was %s)'):format(unit, part, old)
			-- rawget: reading a key the unit and aura tables' '**' defaults don't
			-- have makes a table of them.
			eq(rawget(config, 'template'), nil, where .. ' has no template')
			eq(tostring(config.theme) .. ',' .. tostring(config.background), NEW[old], where .. "'s Theme and Background")
			eq(describe(st:ResolveTheme(config.theme, config.background)), describe(st:ResolveLegacyTemplate(old)), where .. ' looks as it did')
			count = count + 1
		end
	end
	eq(count, 12 * 17, 'every unit, its frame and its sixteen parts')
end)

------------------------------------------------------------------ kinds

test('each part of a unit frame draws as its kind: the frame and its bars as bars, aura buttons as auras, the rest small', function()
	local player = P.player
	player.additionalpower.enable = true
	player.castbar.icon.enable = true
	player.grouproleindicator.enable = true
	player.grouproleindicator.theme = 'thin'
	local frame = make_unit_frame('SaftUI_Player', 'player',
		{ 'Health', 'Power', 'AdditionalPower', 'Castbar', 'ClassPower', 'GroupRoleIndicator', 'RaidRoleIndicator' })
	UF:UpdateUnitFrame(frame)

	eq(drawn(frame), 'none,theme,bar', 'the unit frame: a bar, None by default')
	eq(looks(frame), 'bare', 'the unit frame draws nothing')
	eq(drawn(frame.Health), 'theme,theme,bar', 'health: a bar')
	eq(drawn(frame.Power), 'theme,theme,bar', 'power: a bar')
	eq(drawn(frame.AdditionalPower), 'theme,solid,bar', 'additional power: a bar')
	eq(drawn(frame.Castbar), 'theme,theme,bar', 'the castbar: a bar')
	eq(drawn(frame.Castbar.Icon), 'theme,solid,small', "the castbar's icon: small")
	for i = 1, 10 do
		eq(drawn(frame.ClassPower[i]), 'theme,theme,small', 'class power point ' .. i .. ': small')
	end
	eq(drawn(frame.ClassPower), nil, 'the class power row itself is not drawn')
	eq(looks(frame.ClassPower), 'bare', 'and shows nothing')
	eq(drawn(frame.GroupRoleIndicator), 'thin,theme,small', 'an indicator: small')
	eq(drawn(frame.RaidRoleIndicator), 'none,theme,small', 'another, None by default')

	-- Drawn as SaftUI's theme draws them.
	local thick = st.config.profile.templates.thick
	local r, g, b, a = unpack(thick.backdropcolor)
	local transparent = ('inset 2, fill %s, edge %s, outer'):format(rgba(r, g, b, a * 0.9), rgba(unpack(thick.bordercolor)))
	eq(looks(frame.Health), transparent, "health: SaftUI's theme")
	eq(looks(frame.Castbar.Icon), ('inset 2, fill %s, edge %s, outer'):format(rgba(r, g, b, a), rgba(unpack(thick.bordercolor))),
		"the castbar's icon: SaftUI's theme, solid")
	local thin = st.config.profile.templates.thin
	local tr, tg, tb, ta = unpack(thin.backdropcolor)
	eq(looks(frame.GroupRoleIndicator), ('inset 1, fill %s, edge %s, no outer'):format(rgba(tr, tg, tb, ta * 0.9), rgba(unpack(thin.bordercolor))),
		'the indicator: Thin, with the theme\'s transparent background')

	local debuffs = UF.elements.Debuffs.Constructor(frame, 'Debuffs')
	local button = make_aura_button(debuffs)
	eq(drawn(button), 'theme,solid,aura', 'an aura button: an aura')

	player.additionalpower.enable, player.castbar.icon.enable = false, false
	player.grouproleindicator.enable, player.grouproleindicator.theme = false, 'none'
end)

------------------------------------------------------------------ aura and class power areas

-- The aura areas and the class power row are drawn through their buttons and
-- points, each with the element's Theme; the area itself has no backdrop. An
-- aura area is Blizzard's AuraContainer, and a frame anchored to it needs the
-- container's layout aspect (.agents/taint.md, rule 11), so no backdrop of
-- SaftUI's is made, or placed, on it.
test('a config update draws no backdrop on the aura and class power areas, and the other elements as before', function()
	local player = P.player
	check(player.buffs.enable and player.debuffs.enable and player.classpower.enable, "the player's buffs, debuffs and class power are on by default")
	check(player.buffs.theme ~= 'none' and player.classpower.theme ~= 'none', 'with a Theme that draws')
	local frame = make_unit_frame('SaftUI_PlayerAreas', 'player', { 'Health', 'Power', 'ClassPower', 'Buffs', 'Debuffs' })
	-- Twice: the first update, and a later one (an option set, a profile switch).
	for pass = 1, 2 do
		UF:UpdateUnitFrame(frame)
		for _, name in ipairs({ 'Buffs', 'Debuffs', 'ClassPower' }) do
			local area = frame[name]
			local where = ('update %d, %s'):format(pass, name)
			eq(drawn(area), nil, where .. ': no draw call on the area')
			eq(area.backdrop, nil, where .. ': no backdrop made on it')
			eq(looks(area), 'bare', where .. ': it draws nothing')
		end
		eq(frame.Buffs:GetNumChildren(), 0, ('update %d: nothing made on the buffs container to anchor to it'):format(pass))
		eq(frame.Debuffs:GetNumChildren(), 0, ('update %d: nor on the debuffs container'):format(pass))
		eq(frame.ClassPower:GetNumChildren(), 10, ('update %d: the class power row holds only its ten points'):format(pass))

		eq(drawn(frame.Health), 'theme,theme,bar', 'health: drawn as before')
		eq(drawn(frame.Power), 'theme,theme,bar', 'power: drawn as before')
		for i = 1, 10 do
			eq(drawn(frame.ClassPower[i]), 'theme,theme,small', 'class power point ' .. i .. ': drawn as before')
		end
		local thick = st.config.profile.templates.thick
		local r, g, b, a = unpack(thick.backdropcolor)
		eq(looks(frame.Health), ('inset 2, fill %s, edge %s, outer'):format(rgba(r, g, b, a * 0.9), rgba(unpack(thick.bordercolor))),
			"health: SaftUI's theme")
	end

	-- An aura button is still drawn as an aura, with the element's Theme.
	local button = make_aura_button(frame.Debuffs)
	eq(drawn(button), 'theme,solid,aura', 'an aura button: an aura')
	check(looks(button) ~= 'bare', 'and drawn')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ previews

-- Each part a preview has (groups.lua's CreatePreviewFrame), on a preview and
-- on a real frame: 'part: how it was drawn; how it looks'.
local PREVIEW_PARTS = { 'Health', 'Power', 'GroupRoleIndicator' }
local function picture(frame)
	local out = { 'frame: ' .. tostring(drawn(frame)) .. '; ' .. looks(frame) }
	for _, part in ipairs(PREVIEW_PARTS) do
		out[#out + 1] = part .. ': ' .. tostring(drawn(frame[part])) .. '; ' .. looks(frame[part])
	end
	return table.concat(out, '\n')
end

-- Gives a unit's frame, health, power and role corner overrides of their own,
-- with power and the corner on, so each preview part has something to draw.
local function override(unit)
	local config = P[unit]
	config.theme, config.background = 'thin', 'transparent'
	config.health.theme, config.health.background = 'thick', 'solid'
	config.power.enable, config.power.theme, config.power.background = true, 'thin', 'theme'
	config.grouproleindicator.enable = true
	config.grouproleindicator.theme, config.grouproleindicator.background = 'thick', 'transparent'
end

local EXPECTED_DRAWS = {
	frame = 'thin,transparent,bar', Health = 'thick,solid,bar', Power = 'thin,theme,bar', GroupRoleIndicator = 'thick,transparent,small',
}

test('a boss or party preview draws like its real frame', function()
	-- Boss: five boss frames on the boss holder (unitframes.lua's OnEnable),
	-- placed relative to the target frame by default, and hidden, as with no
	-- boss up, so test mode shows the previews.
	local target = CreateFrame('Frame', 'SaftUI_Target', UIParent)
	target:SetPoint('CENTER')
	target:SetSize(300, 40)
	UF.units = { boss = {} }
	UF.holders.boss = CreateFrame('Frame', 'SaftUI_BossHolder', UIParent)
	for i = 1, 5 do
		local boss = make_unit_frame('SaftUI_Boss' .. i, 'boss', PREVIEW_PARTS)
		boss.ID = i
		boss:Hide()
		UF.units.boss[i] = boss
	end
	override('boss')
	UF.testGroups.boss = true
	UF:ApplyConfig('boss')

	local previews = UF.previews.boss and UF.previews.boss.frames or {}
	eq(#previews, 5, 'a preview for each boss frame')
	for i, preview in ipairs(previews) do
		local real = UF.units.boss[i]
		eq(picture(preview), picture(real), 'boss preview ' .. i .. ' draws like boss frame ' .. i)
		for part, expected in pairs(EXPECTED_DRAWS) do
			eq(drawn(part == 'frame' and preview or preview[part]), expected, 'boss preview ' .. i .. "'s " .. part)
		end
	end

	-- Party: a header's button (the header is hidden, out of a group, so test
	-- mode shows the previews), drawn as UF:ApplyConfig draws each one.
	local player = CreateFrame('Frame', 'SaftUI_Player', UIParent)
	player:SetPoint('CENTER')
	player:SetSize(300, 40)
	UF.groups = { party = CreateFrame('Frame', 'SaftUI_Party', UIParent) }
	UF.groups.party:Hide()
	UF.holders.party = CreateFrame('Frame', 'SaftUI_PartyHolder', UIParent)
	UF.holders.party:SetPoint('CENTER')
	local member = make_unit_frame('SaftUI_PartyUnitButton1', 'party', PREVIEW_PARTS, UF.groups.party)
	member.is_group_unit = true
	override('party')
	UF:UpdateUnitFrame(member)
	UF.testGroups.party = true
	UF:UpdateGroupPreview('party')

	local preview = UF.previews.party and UF.previews.party.frames[1]
	if check(preview ~= nil, 'the party previews show') then
		eq(picture(preview), picture(member), 'a party preview draws like a party member')
		for part, expected in pairs(EXPECTED_DRAWS) do
			eq(drawn(part == 'frame' and preview or preview[part]), expected, "party preview's " .. part)
		end
	end
	UF.testGroups.boss, UF.testGroups.party = nil, nil
end)

------------------------------------------------------------------ aura borders

-- The dark line auras.lua draws over a button's dispel type fill: the button's
-- texture on the BACKGROUND layer, sublevel 1.
local function inner_line(button)
	for _, region in ipairs({ button:GetRegions() }) do
		local layer, sublevel = region:GetDrawLayer()
		if layer == 'BACKGROUND' and sublevel == 1 then return region end
	end
end

-- Whether the dispel fill covers the button's backdrop exactly.
local function covers_backdrop(button)
	local border, backdrop = button.Border, button.backdrop
	return border:GetLeft() == backdrop:GetLeft() and border:GetRight() == backdrop:GetRight()
		and border:GetTop() == backdrop:GetTop() and border:GetBottom() == backdrop:GetBottom()
end

test("an aura button's dispel type fill keeps its color through a theme recolor and redraw, and the dark line over it follows the theme", function()
	local frame = make_unit_frame('SaftUI_Focus', 'focus', {})
	frame:SetSize(250, 34)
	frame:SetPoint('CENTER')
	local debuffs = UF.elements.Debuffs.Constructor(frame, 'Debuffs')
	debuffs:SetAllPoints(frame)
	local button = make_aura_button(debuffs)
	-- The container tints the fill by the debuff's dispel type.
	button.Border:SetVertexColor(0.8, 0.1, 0.9, 1)
	local function fill_color() return rgba(button.Border:GetVertexColor()) end

	local thick = st.config.profile.templates.thick
	local line = inner_line(button)
	if not check(line ~= nil, 'a dark line over the fill') then return end
	check(line:IsShown(), 'shown under Thick')
	eq(rgba(line:GetVertexColor()), rgba(unpack(thick.altbordercolor)), "in Thick's outer border color")
	check(covers_backdrop(button), 'the fill covers the backdrop')

	-- A drag of the Outer border color picker.
	local saved = { unpack(thick.altbordercolor) }
	thick.altbordercolor[1], thick.altbordercolor[2], thick.altbordercolor[3] = 0.3, 0.2, 0.1
	st:RecolorThemed()
	eq(rgba(line:GetVertexColor()), rgba(0.3, 0.2, 0.1, saved[4]), 'the dark line takes the new outer border color')
	eq(fill_color(), rgba(0.8, 0.1, 0.9, 1), 'the dispel fill keeps its color')
	check(covers_backdrop(button), 'and still covers the backdrop')

	-- A switch to Thin: one line, so no dark line inside it.
	local theme = st.config.profile.theme
	theme.name = 'thin'
	st:RedrawThemed()
	check(not line:IsShown(), 'no dark line under Thin')
	eq(looks(button):match('^inset %d'), 'inset 1', "the button's border is Thin's")
	eq(fill_color(), rgba(0.8, 0.1, 0.9, 1), 'the dispel fill keeps its color')
	check(covers_backdrop(button), "and covers the backdrop at Thin's border")

	theme.name = 'thick'
	st:RedrawThemed()
	check(line:IsShown(), 'the dark line is back under Thick')
	eq(rgba(line:GetVertexColor()), rgba(0.3, 0.2, 0.1, saved[4]), 'in the outer border color')
	check(covers_backdrop(button), "the fill covers the backdrop at Thick's border")
	for i, v in ipairs(saved) do thick.altbordercolor[i] = v end
end)
