-- The unit frames' kinds (SaftUI-Unitframes/unitframes.lua and updaters.lua):
--   - a unit frame and its bars (health, power, additional power, the
--     castbar) draw as unitframe, and a party or raid member's as member;
--     under Thick and Thin both look exactly as a bar does;
--   - one box per edge under Blizzard: health lying exactly over its unit
--     frame, both drawn in Blizzard's art, draws None, so only the frame's
--     bronze box shows; health that doesn't quite fill the frame (resized,
--     moved, anchored to another element), or a frame drawn in another look,
--     keeps its own box (Review Focus 4);
--   - the player's separate power bar has its own box, and a castbar whose
--     Theme is Thin keeps Thin's line;
--   - a bar or frame too small for the bronze box's two corners on a side
--     draws as a small frame (a line and the fill), decided from its config
--     at every update, so it follows its size; under Thick and Thin it looks
--     as a bar; a bar sized by another's config (Mana as primary) goes by
--     that size;
--   - the test mode previews draw as their real frames do: a party member's
--     as members, a boss's as unit frames;
--   - the group border (groups.lua): under Blizzard each party and raid
--     header, and a party or raid test mode preview, sits in Blizzard's raid
--     group border, options_frame_child cut at 6px with no middle, on a frame
--     of SaftUI's anchored (-2, 2) and (2, -3) around it; shown when the
--     group's frame Theme, or its health's where the frame's is None, is
--     Blizzard's; following a member joining in combat by its anchors alone,
--     with nothing protected called and nothing written onto the header (a
--     locked, protected stand-in for the secure group header).
--
-- The world is theme_test.lua's (see its top), made fresh on each client
-- (world): real Core and its defaults, the unit frames' defaults (every
-- unit's), unitframes.lua, the group files (grouplayout.lua, groups.lua,
-- blizzardraid.lua, grouppreview.lua), config/profiles.lua,
-- config/groupoptions.lua, config/config.lua, constructors.lua, updaters.lua
-- and the bar and aura elements, and nameplates/options.lua; oUF stood in for
-- by its colors table, and a unit frame by a SaftUI button with
-- UF.ConstructUnit's fields and the elements a test names, built by their own
-- constructors (make_unit_frame). The draw calls are watched (T.watch), since
-- the kind changes nothing under Thick and Thin.
local T = load_test_file('lib/theme_helpers.lua')

local st, UF, P, drawn

local UNITS = { 'arena', 'boss', 'focus', 'focustarget', 'party', 'pet', 'pettarget', 'player', 'raid10', 'raid40', 'target', 'targettarget' }
local ELEMENTS = { 'auras', 'power', 'additionalpower', 'health', 'castbar', 'classpower', 'indicators' }

-- A fresh world on one client, with SaftUI's theme set to theme.
local function world(client, theme)
	T.client(client)
	st = SaftUI
	load_saftui('SaftUI-Unitframes/config/default.lua')
	for _, unit in ipairs(UNITS) do
		load_saftui('SaftUI-Unitframes/config/units/' .. unit .. '.lua')
	end
	apply_defaults()
	addon_namespace('SaftUI-Unitframes').oUF = {
		colors = {
			class = {}, reaction = {}, power = {},
			disconnected = CreateColor(1, 1, 1), tapped = CreateColor(1, 1, 1), health = CreateColor(0.2, 0.8, 0.2),
			roles = {}, runes = {},
		},
	}
	for _, file in ipairs({ 'unitframes', 'grouplayout', 'groups', 'blizzardraid', 'grouppreview', 'config/profiles', 'config/groupoptions', 'config/config', 'constructors', 'updaters' }) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
	for _, file in ipairs(ELEMENTS) do
		load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
	end
	load_saftui('SaftUI-Unitframes/nameplates/options.lua')
	load_string_format()
	UF = st:GetModule('Unitframes')
	P = UF:GetProfileConfig()
	UF:UpdateColors()
	drawn = T.watch()
	st.config.profile.theme.name = theme or 'thick'
end

-- A unit frame for a config unit, with the named elements built by their own
-- constructors (theme_test.lua's).
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

-- What a frame's backdrop shows: its inset, fill and edge colors, whether
-- Thick's outer lines show, where it sits around the frame, whether it has an
-- edge line (Blizzard draws one only for a small frame) and the Blizzard art
-- shown on it (T.art); 'bare' for none.
local function looks(frame)
	local backdrop = frame.backdrop
	if not (backdrop and backdrop.backdropInfo) then return 'bare' end
	local outer = backdrop.altborder and backdrop.altborder.LEFT:IsShown() and 'outer' or 'no outer'
	local line = backdrop.backdropInfo.edgeFile and 'a line' or 'no line'
	return ('inset %d, fill %s, edge %s, %s, %s, at %s, art {%s}'):format(T.inset(backdrop), T.fill(backdrop),
		T.edge(backdrop), outer, line, T.around(backdrop, frame), T.art(backdrop))
end

-- What a frame of the same size as frame looks like drawn with theme and
-- background as a bar.
local function as_bar(frame, theme, background)
	local bar = CreateFrame('Frame', nil, UIParent)
	bar:SetSize(frame:GetWidth(), frame:GetHeight())
	bar:SetPoint('CENTER')
	st:SetBackdrop(bar, theme, background, 'bar')
	return looks(bar)
end

-- The shown pieces of a frame's Blizzard art, by key; '' for none.
local function pieces(frame)
	return (T.art(frame.backdrop or frame):gsub('=[^,]*', ''))
end
local BOX = 'BottomEdge,BottomLeftCorner,BottomRightCorner,LeftEdge,RightEdge,TopEdge,TopLeftCorner,TopRightCorner'

-- How a Blizzard kind looks on a frame: the bronze box (its eight pieces,
-- inset 2, no line), a small frame (a 1px line, inset 1, no art) or a member
-- (the fill, inset 0, no line, no art); 'bare' for none.
local function blizzard(frame)
	local backdrop = frame.backdrop
	if not (backdrop and backdrop.backdropInfo) then return 'bare' end
	local line = backdrop.backdropInfo.edgeFile ~= nil
	local inset, around = T.inset(backdrop), T.around(backdrop, frame)
	if pieces(frame) == BOX and inset == 2 and not line and around == '-2,2,2,-2' then return 'box' end
	if pieces(frame) == '' and inset == 1 and line and around == '-1,1,1,-1' then return 'small' end
	if pieces(frame) == '' and inset == 0 and not line and around == '0,0,0,0' then return 'member' end
	return 'something else: ' .. looks(frame)
end

local CLIENTS = { 'forever', 'retail' }

-- Turns the offsets in a config saved as text into numbers. The castbar's
-- defaults save some as text ("0", "-3"), which the game's SetPoint takes
-- (Lua's C API reads a numeric string as a number) and the stub's refuses.
local function number_offsets(config)
	for key, value in pairs(config) do
		if type(value) == 'table' then
			number_offsets(value)
		elseif (key == 'x_off' or key == 'y_off') and type(value) == 'string' then
			config[key] = tonumber(value)
		end
	end
end

------------------------------------------------------------------ the kinds

test('every unit frame and bar draws as unitframe, a party or raid member as member; under Thick and Thin as a bar', function()
	for _, theme in ipairs({ 'thick', 'thin' }) do
		world('forever', theme)
		P.player.additionalpower.enable = true
		P.party.power.enable = true
		local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'AdditionalPower', 'Castbar' })
		local party = make_unit_frame('M', 'party', { 'Health', 'Power' })
		party.is_group_unit = true
		local raid10 = make_unit_frame('R10', 'raid10', { 'Health' })
		raid10.is_group_unit = true
		local raid40 = make_unit_frame('R40', 'raid40', { 'Health' })
		raid40.is_group_unit = true
		-- A header places its buttons; UF:PlaceUnitFrame only sizes them.
		for _, frame in ipairs({ party, raid10, raid40 }) do frame:SetPoint('CENTER') end
		for _, frame in ipairs({ player, party, raid10, raid40 }) do UF:UpdateUnitFrame(frame) end

		local expected = {
			{ player, 'player', 'none,theme,unitframe' },
			{ player.Health, 'health', 'theme,theme,unitframe' },
			{ player.Power, "the player's power", 'theme,theme,unitframe' },
			{ player.AdditionalPower, 'additional power', 'theme,solid,unitframe' },
			{ player.Castbar, 'the castbar', 'theme,theme,unitframe' },
			{ party, 'a party member', 'none,theme,member' },
			{ party.Health, "a party member's health", 'theme,theme,member' },
			{ party.Power, "a party member's power, 5 tall", 'theme,theme,member' },
			{ raid10, 'a raid 10 member', 'theme,solid,member' },
			{ raid10.Health, "a raid 10 member's health", 'theme,theme,member' },
			{ raid40, 'a raid 40 member', 'theme,solid,member' },
			{ raid40.Health, "a raid 40 member's health", 'theme,theme,member' },
		}
		for _, e in ipairs(expected) do
			local frame, name, draw = e[1], theme .. ', ' .. e[2], e[3]
			eq(drawn(frame), draw, name .. ': drawn as ' .. draw:match('[^,]*$'))
			local pair, background = draw:match('^([^,]*),([^,]*)')
			eq(looks(frame), as_bar(frame, pair, background), name .. ': looks as a bar of its size')
		end
		check(looks(player.Health) ~= 'bare', theme .. ': health is drawn')
		eq(looks(player), 'bare', theme .. ': the player frame draws nothing (None by default)')
		eq(#take_errors(), 0, theme .. ': no errors')
	end
end)

test('UF.UnitKind: party and raid members are members, every other unit a unit frame', function()
	world('forever')
	for _, unit in ipairs(UNITS) do
		local member = unit == 'party' or unit == 'raid10' or unit == 'raid40'
		eq(UF.UnitKind(unit), member and 'member' or 'unitframe', unit)
	end
end)

test('UF.FillsFrame: only as wide and tall as the frame, on the frame itself, at the same point, with no offset', function()
	world('forever')
	local function fills(change)
		local config = {
			relative_width = true, width = 0, relative_height = true, height = 0,
			position = { point = 'TOPRIGHT', rel_point = 'TOPRIGHT', x_off = 0, y_off = 0 },
		}
		if change then change(config) end
		return UF.FillsFrame(config)
	end
	eq(fills(), true, "health's default")
	eq(fills(function(c) c.position.x_off, c.position.y_off = '0', '0' end), true, 'offsets saved as text')
	eq(fills(function(c) c.position.rel_point = nil end), true, 'no relative point: the point (st:UnpackPoint)')
	eq(fills(function(c) c.position.x_off, c.position.y_off = nil, nil end), true, 'no offsets: 0 (st:UnpackPoint)')
	eq(fills(function(c) c.height = -4 end), false, 'relative height -4')
	eq(fills(function(c) c.width = 2 end), false, 'relative width 2')
	eq(fills(function(c) c.relative_height = false end), false, 'height 0, not relative')
	eq(fills(function(c) c.relative_width = false end), false, 'width 0, not relative')
	eq(fills(function(c) c.position.y_off = -1 end), false, 'offset y -1')
	eq(fills(function(c) c.position.x_off = '1' end), false, 'offset x 1, as text')
	eq(fills(function(c) c.position.element = 'Power' end), false, 'anchored to another element')
	eq(fills(function(c) c.position.frame = 'UIParent' end), false, 'anchored to a frame')
	eq(fills(function(c) c.position.rel_point = 'TOPLEFT' end), false, 'at another point')
end)

------------------------------------------------------------------ one box per edge

-- Under Blizzard with the player's frame Theme on: health lying exactly over
-- the frame draws None, so only the frame's box shows; anything else and both
-- show (Review Focus 4).
test('one box per edge', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 'blizzard')
		P.player.theme = 'theme'
		local player = make_unit_frame('P', 'player', { 'Health', 'Power' })
		local health = P.player.health
		local function update(where)
			UF:UpdateUnitFrame(player)
			eq(drawn(player), 'theme,theme,unitframe', client .. ', ' .. where .. ': the frame, drawn as a unit frame')
			eq(blizzard(player), 'box', client .. ', ' .. where .. ": the frame's box shows")
		end

		update('health filling the frame')
		eq(drawn(player.Health), 'none,theme,unitframe', client .. ': health filling the frame draws None')
		eq(looks(player.Health), 'bare', client .. ': and shows nothing: no second box on the same edges')

		local cases = {
			{ 'health at relative height -4', function() health.height = -4 end, function() health.height = 0 end },
			{ 'health offset y -1', function() health.position.y_off = -1 end, function() health.position.y_off = 0 end },
			{ "health anchored to the player's power", function() health.position.element = 'Power' end,
				function() health.position.element = nil end },
		}
		for _, case in ipairs(cases) do
			local where = client .. ', ' .. case[1]
			case[2]()
			update(case[1])
			eq(drawn(player.Health), 'theme,theme,unitframe', where .. ': health draws its own Theme')
			eq(blizzard(player.Health), 'box', where .. ': both boxes show')
			case[3]()
			update(case[1] .. ', back')
			eq(drawn(player.Health), 'none,theme,unitframe', where .. ', back: health draws None again')
			eq(looks(player.Health), 'bare', where .. ', back: one box')
		end

		-- The frame Thick and health SaftUI's theme: one Thick, one Blizzard.
		P.player.theme = 'thick'
		UF:UpdateUnitFrame(player)
		eq(drawn(player), 'thick,theme,unitframe', client .. ': the frame Thick')
		eq(pieces(player), '', client .. ': the frame shows no Blizzard art')
		check(looks(player):find(', outer, a line, ', 1, true) ~= nil, client .. ": the frame shows Thick's border")
		eq(drawn(player.Health), 'theme,theme,unitframe', client .. ': health draws its own Theme')
		eq(blizzard(player.Health), 'box', client .. ': health shows the bronze box')

		-- Health set to Thick under the frame's Blizzard box: both.
		P.player.theme = 'theme'
		health.theme = 'thick'
		UF:UpdateUnitFrame(player)
		eq(blizzard(player), 'box', client .. ": health Thick: the frame's box")
		eq(drawn(player.Health), 'thick,theme,unitframe', client .. ': health Thick draws Thick')
		check(looks(player.Health):find(', outer, ', 1, true) ~= nil, client .. ": health Thick: Thick's border")
		health.theme = 'theme'

		-- SaftUI's theme Thick: health draws its own pair, as before.
		st.config.profile.theme.name = 'thick'
		UF:UpdateUnitFrame(player)
		eq(drawn(player.Health), 'theme,theme,unitframe', client .. ', Thick: health draws its own Theme')
		eq(looks(player.Health), as_bar(player.Health, 'theme', 'theme'), client .. ', Thick: health looks as before')
		eq(looks(player), as_bar(player, 'theme', 'theme'), client .. ', Thick: so does the frame')

		-- Back to Blizzard: one box again.
		st.config.profile.theme.name = 'blizzard'
		UF:UpdateUnitFrame(player)
		eq(looks(player.Health), 'bare', client .. ', Blizzard again: health draws None')
		eq(blizzard(player), 'box', client .. ", Blizzard again: the frame's box")
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

-- The frame's own Theme None (its default): health draws the box.
test("with the frame's Theme None, health draws the box", function()
	world('forever', 'blizzard')
	local player = make_unit_frame('P', 'player', { 'Health' })
	UF:UpdateUnitFrame(player)
	eq(drawn(player), 'none,theme,unitframe', 'the frame: None')
	eq(looks(player), 'bare', 'shows nothing')
	eq(drawn(player.Health), 'theme,theme,unitframe', 'health draws its own Theme')
	eq(blizzard(player.Health), 'box', 'and shows the box')
end)

test("the player's separate power bar has its own box; a castbar set to Thin keeps Thin's line", function()
	for _, client in ipairs(CLIENTS) do
		world(client, 'blizzard')
		P.player.theme = 'theme'
		local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'Castbar' })
		UF:UpdateUnitFrame(player)
		eq(P.player.power.height, 20, "the player's power bar is 20 tall")
		eq(drawn(player.Power), 'theme,theme,unitframe', client .. ": the player's power bar")
		eq(blizzard(player.Power), 'box', client .. ': its own box')
		eq(drawn(player.Castbar), 'theme,theme,unitframe', client .. ": the player's castbar")
		eq(blizzard(player.Castbar), 'box', client .. ': its own box')
		eq(looks(player.Health), 'bare', client .. ': health, filling the frame, none')

		-- The boss castbar's Theme is Thin by default (default.lua's castbar;
		-- the player's, target's and focus's are SaftUI's theme). A boss frame
		-- is placed relative to the target's by default.
		local target = make_unit_frame('SaftUI_Target', 'target', { 'Health', 'Castbar' })
		UF:UpdateUnitFrame(target)
		number_offsets(P.boss.castbar)
		local boss = make_unit_frame('B', 'boss', { 'Health', 'Castbar' })
		UF:UpdateUnitFrame(boss)
		eq(drawn(boss.Castbar), 'thin,solid,unitframe', client .. ": the boss castbar's Thin default")
		local thin = st.config.profile.templates.thin
		eq(looks(boss.Castbar), ('inset 1, fill %s, edge %s, no outer, a line, at -1,1,1,-1, art {}'):format(
			T.text(unpack(thin.backdropcolor)), T.text(unpack(thin.bordercolor))), client .. ": Thin's line, no pieces")

		-- The target's castbar, SaftUI's theme by default: the box. Set to Thin
		-- by the user: Thin's line.
		eq(drawn(target.Castbar), 'theme,theme,unitframe', client .. ": the target's castbar")
		eq(blizzard(target.Castbar), 'box', client .. ': its own box')
		P.target.castbar.theme, P.target.castbar.background = 'thin', 'solid'
		UF:UpdateUnitFrame(target, 'Castbar')
		eq(drawn(target.Castbar), 'thin,solid,unitframe', client .. ": the target's castbar set to Thin")
		eq(looks(target.Castbar), looks(boss.Castbar), client .. ": Thin's line, no pieces")
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

------------------------------------------------------------------ too small for the box

-- The box's two 8px corners need a drawn frame at least 16 on each side: a
-- bar or frame at most 11 (drawn 15) draws as a small frame instead, a line
-- and the fill. Decided from its config at each update.
test('a bar or frame too small for the bronze box draws as a small frame, decided again when its size changes; under Thick and Thin nothing changes', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 'blizzard')
		local power = P.target.power
		power.enable = true
		local target = make_unit_frame('T', 'target', { 'Health', 'Power' })
		UF:UpdateUnitFrame(target)
		local function update(where, kind, look)
			UF:UpdateUnitFrame(target, 'Power')
			eq(drawn(target.Power), 'theme,theme,' .. kind, client .. ', ' .. where .. ': drawn as ' .. kind)
			eq(blizzard(target.Power), look, client .. ', ' .. where .. ': ' .. look)
		end

		eq(power.height, 5, "the target's power bar is 5 tall by default")
		eq(drawn(target.Power), 'theme,theme,small', client .. ': a 5-tall power bar is a small frame')
		eq(blizzard(target.Power), 'small', client .. ': a line and the fill, no pieces')
		power.height = 20
		update('20 tall', 'unitframe', 'box')
		power.height = 5
		update('5 tall again', 'small', 'small')
		power.height = 12
		update('12 tall, drawn 16', 'unitframe', 'box')
		power.height = 11
		update('11 tall, drawn 15', 'small', 'small')
		power.height, power.width, power.relative_width = 30, 5, false
		update('a vertical bar 5 wide', 'small', 'small')
		power.width = 12
		update('12 wide', 'unitframe', 'box')
		power.width = 11
		update('11 wide', 'small', 'small')
		power.height, power.width, power.relative_width = 5, 0, true

		-- A relative size: the frame's height less 24.
		P.target.health.height = -24
		UF:UpdateUnitFrame(target, 'Health')
		eq(drawn(target.Health), 'theme,theme,small', client .. ': health 10 tall (34 - 24)')
		P.target.health.height = 0

		-- The unit frame itself, 10 tall, with its own Theme: it draws the line,
		-- and its health, filling it, draws None, so one line shows on its edges.
		P.target.theme, P.target.height = 'theme', 10
		UF:UpdateUnitFrame(target)
		eq(drawn(target), 'theme,theme,small', client .. ': a unit frame 10 tall')
		eq(blizzard(target), 'small', client .. ': a line and the fill')
		eq(drawn(target.Health), 'none,theme,small', client .. ': its health, filling it, draws None')
		eq(looks(target.Health), 'bare', client .. ': and shows nothing: no second line on the same edges')
		-- Health 2 shorter: both lines, the frame's and its own.
		P.target.health.height = -2
		UF:UpdateUnitFrame(target, 'Health')
		eq(drawn(target.Health), 'theme,theme,small', client .. ': health 8 tall in the 10-tall frame draws its own Theme')
		eq(blizzard(target.Health), 'small', client .. ': its own line and fill')
		P.target.health.height = 0
		P.target.height = 34
		UF:UpdateUnitFrame(target)
		eq(blizzard(target), 'box', client .. ': 34 tall: the box')
		eq(looks(target.Health), 'bare', client .. ': and health none')
		P.target.theme = 'none'

		-- Under Thick and Thin a 5-tall bar looks exactly as a bar.
		for _, theme in ipairs({ 'thick', 'thin' }) do
			st.config.profile.theme.name = theme
			UF:UpdateUnitFrame(target)
			eq(looks(target.Power), as_bar(target.Power, 'theme', 'theme'), client .. ', ' .. theme .. ': the 5-tall bar looks as a bar')
		end
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

-- power.lua and additionalpower.lua hand UF:UpdateElement the other bar's
-- config with Mana as primary on, and the bar is sized by it
-- (UF:UpdateElementSize): its kind follows that size.
test("a bar sized by another's config takes its kind from that size", function()
	world('forever', 'blizzard')
	local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'AdditionalPower' })
	UF:UpdateUnitFrame(player)
	local other = P.player.additionalpower
	other.height = 5
	eq(UF:ElementKind(player.Power), 'unitframe', 'by its own config, 20 tall: a unit frame')
	eq(UF:ElementKind(player.Power, other), 'small', "by the additional power's, 5 tall: a small frame")
	UF:UpdateElement(player.Power, other)
	eq(player.Power:GetHeight(), 5, 'sized by it')
	eq(drawn(player.Power), 'theme,theme,small', 'and drawn as a small frame, in its own Theme')
	eq(blizzard(player.Power), 'small', 'a line and the fill')
	eq(#take_errors(), 0, 'no errors')
end)

-- UF:UpdateElement(element, configOverride) places the element by the
-- override's position too, as it sizes it by the override.
test("an element given another's config is placed by its position", function()
	world('forever', 'thick')
	local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'AdditionalPower' })
	UF:UpdateUnitFrame(player)
	local other = {}
	for key, value in pairs(P.player.power) do other[key] = value end
	other.position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = 17, y_off = -23 }
	UF:UpdateElement(player.Power, other)
	local point, relative, rel_point, x, y = player.Power:GetPoint()
	eq(point, 'TOPLEFT', 'its point')
	eq(relative, UIParent, 'its frame')
	eq(rel_point, 'BOTTOMRIGHT', 'its relative point')
	eq(x, 17, 'its x offset')
	eq(y, -23, 'its y offset')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ previews

-- Each part a preview has (grouppreview.lua's CreatePreviewFrame) as
-- 'part: how it was drawn; how it looks'.
local PREVIEW_PARTS = { 'Health', 'Power', 'GroupRoleIndicator' }
local function picture(frame)
	local out = { 'frame: ' .. tostring(drawn(frame)) .. '; ' .. looks(frame) }
	for _, part in ipairs(PREVIEW_PARTS) do
		out[#out + 1] = part .. ': ' .. tostring(drawn(frame[part])) .. '; ' .. looks(frame[part])
	end
	return table.concat(out, '\n')
end

test('a party preview draws as members, a boss preview as a unit frame', function()
	for _, theme in ipairs({ 'thick', 'blizzard' }) do
		world('forever', theme)
		-- Boss: five hidden boss frames on the boss holder, placed relative to
		-- the target frame by default (theme_test.lua's preview test).
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
		P.boss.theme = 'theme'
		P.boss.power.enable = true
		UF.testGroups.boss = true
		UF:ApplyConfig('boss')

		local previews = UF.previews.boss and UF.previews.boss.frames or {}
		eq(#previews, 5, theme .. ': a preview for each boss frame')
		for i, preview in ipairs(previews) do
			local where = theme .. ', boss preview ' .. i
			eq(drawn(preview), 'theme,theme,unitframe', where .. ': a unit frame')
			eq(drawn(preview.Power), 'theme,theme,small', where .. ': its 5-tall power bar a small frame')
			eq(picture(preview), picture(UF.units.boss[i]), where .. ' draws like boss frame ' .. i)
		end
		if theme == 'blizzard' then
			eq(blizzard(previews[1]), 'box', "under Blizzard the boss preview's box")
			eq(drawn(previews[1].Health), 'none,theme,unitframe', 'and its health, filling it, None')
		else
			eq(drawn(previews[1].Health), 'theme,theme,unitframe', 'under Thick its health a unit frame')
		end

		-- Party: a hidden header's button, drawn as UF:ApplyConfig draws each one.
		local player = CreateFrame('Frame', 'SaftUI_Player', UIParent)
		player:SetPoint('CENTER')
		player:SetSize(300, 40)
		UF.groups = { party = CreateFrame('Frame', 'SaftUI_Party', UIParent) }
		UF.groups.party:Hide()
		UF.holders.party = CreateFrame('Frame', 'SaftUI_PartyHolder', UIParent)
		UF.holders.party:SetPoint('CENTER')
		local member = make_unit_frame('SaftUI_PartyUnitButton1', 'party', PREVIEW_PARTS, UF.groups.party)
		member.is_group_unit = true
		member:SetPoint('CENTER', UIParent)
		P.party.theme = 'theme'
		P.party.power.enable = true
		UF:UpdateUnitFrame(member)
		UF.testGroups.party = true
		UF:UpdateGroupPreview('party')

		local preview = UF.previews.party and UF.previews.party.frames[1]
		if check(preview ~= nil, theme .. ': the party previews show') then
			eq(drawn(preview), 'theme,theme,member', theme .. ': the party preview, a member')
			eq(drawn(preview.Health), 'theme,theme,member', theme .. ": its health, a member's")
			eq(drawn(preview.Power), 'theme,theme,member', theme .. ": its power, a member's")
			eq(picture(preview), picture(member), theme .. ': a party preview draws like a party member')
			if theme == 'blizzard' then
				eq(blizzard(preview), 'member', 'under Blizzard the party preview is a bare fill')
				eq(blizzard(preview.Health), 'member', 'its health too')
			end
		end
		eq(#take_errors(), 0, theme .. ': no errors')
	end
end)

------------------------------------------------------------------ the group border

-- Stands in for a secure group header, which oUF's SpawnHeader makes and the
-- border mustn't be written onto: a field written onto it errors.
local locked = load_test_file('lib/locked_widget.lua')

-- How many keys a table has.
local function count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

-- A region's size as 'WxH', in whole pixels.
local function size_of(region)
	local w, h = region:GetSize()
	return ('%dx%d'):format(math.floor(w + 0.5), math.floor(h + 0.5))
end

-- A texture's coordinates in its file, 'left,right,top,bottom', to 6 places.
local function coords(texture)
	local left, top, _, bottom, right = texture:GetTexCoord()
	return ('%.6f,%.6f,%.6f,%.6f'):format(left, right, top, bottom)
end

-- A rectangle of a w by h file, in its pixels, as coords gives it.
local function px(l, r, t, b, w, h)
	return ('%.6f,%.6f,%.6f,%.6f'):format(l / w, r / w, t / h, b / h)
end

-- A locked group header, centred, the size a header gives itself for members
-- 200 by 34 and 8 apart in one column (the party's defaults).
local function header_of(name, members)
	local header = locked(CreateFrame('Frame', name, UIParent), 'secure group header')
	header:SetPoint('CENTER')
	header:SetSize(200, members * 34 + (members - 1) * 8)
	return header
end

-- The group border's eight pieces: each one's rectangle of options_frame_child
-- (28 by 26, { x0, x1, y0, y1 }), and its size around a 200 by 160 header
-- (the border 204 by 165).
local GROUP_BORDER = {
	TopLeftCorner = { { 0, 6, 0, 6 }, '6x6' },
	TopRightCorner = { { 22, 28, 0, 6 }, '6x6' },
	BottomLeftCorner = { { 0, 6, 20, 26 }, '6x6' },
	BottomRightCorner = { { 22, 28, 20, 26 }, '6x6' },
	TopEdge = { { 6, 22, 0, 6 }, '192x6' },
	BottomEdge = { { 6, 22, 20, 26 }, '192x6' },
	LeftEdge = { { 0, 6, 6, 20 }, '6x153' },
	RightEdge = { { 22, 28, 6, 20 }, '6x153' },
}

-- options_frame_child's file on each client and its top left pixel there (the
-- file is 1024 by 1024): Forever's Camelot member, retail's own.
local GROUP_BORDER_FILE = { forever = { 8086468, 901, 1 }, retail = { 1318750, 616, 24 } }

test('the group border: options_frame_child cut at 6px around the group header, no middle', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		local header = header_of('SaftUI_Party', 4)
		UF.groups = { party = header }
		local border = UF:GroupBorder(header)
		eq(UF:GroupBorder(header), border, client .. ': made once')
		check(border:GetParent() == header, client .. ": the header's child")
		st.config.profile.theme.name = 'blizzard'; UF:UpdateGroupBorder('party')
		check(border:IsShown(), client .. ': shown under Blizzard')
		eq(T.around(border, header), '-2,2,2,-3', client .. ": Blizzard's offsets around the header")
		local pieces = st.ThemeArt.Get(border).pieces
		eq(count(pieces), 8, client .. ': no middle'); eq(size_of(pieces.TopLeftCorner), '6x6', client .. ': 6px corners')
		eq(pieces.TopLeftCorner:GetTexture(), client == 'forever' and 8086468 or 1318750, client .. ": options_frame_child's file")
		eq(coords(pieces.TopLeftCorner), client == 'forever' and px(901, 907, 1, 7, 1024, 1024) or px(616, 622, 24, 30, 1024, 1024),
			client .. ': the top left corner cut from it')
		eq(border:GetFrameLevel(), header:GetFrameLevel(), client .. ": at the header's level, under its members")

		-- Every piece: its rectangle, its size, its layer, white, on the border.
		local file, x, y = unpack(GROUP_BORDER_FILE[client])
		for key, expected in pairs(GROUP_BORDER) do
			local piece, rect, where = pieces[key], expected[1], client .. ', ' .. key
			if check(piece ~= nil, where .. ': drawn') then
				check(piece:IsShown(), where .. ': shown')
				eq(piece:GetTexture(), file, where .. ': the file')
				eq(coords(piece), px(x + rect[1], x + rect[2], y + rect[3], y + rect[4], 1024, 1024), where .. ': its rectangle')
				eq(size_of(piece), expected[2], where .. ': its size')
				eq((piece:GetDrawLayer()), 'BORDER', where .. ': in BORDER')
				eq(T.text(piece:GetVertexColor()), '1.00,1.00,1.00,1.00', where .. ': white')
				check(piece:GetParent() == border, where .. ": a texture of the border's")
			end
		end

		-- Under Thick it's hidden, its pieces too (ThemeArt.Clear); back under
		-- Blizzard, all eight again.
		st.config.profile.theme.name = 'thick'; UF:UpdateGroupBorder('party')
		check(not border:IsShown(), client .. ': hidden under Thick')
		eq(T.art(border), '', client .. ': its pieces hidden')
		st.config.profile.theme.name = 'blizzard'; UF:UpdateGroupBorder('party')
		check(border:IsShown(), client .. ': shown under Blizzard again')
		eq((T.art(border):gsub('=[^,]*', '')), BOX, client .. ': its eight pieces again')
		eq(#take_errors(), 0, client .. ': no errors')
	end

	-- A frame level can be secret (.agents/clients.md): no math on it, and the
	-- border stays where it was made, one over its owner. A secret value is a
	-- newproxy here, which issecretvalue is told to recognise.
	world('forever', 'blizzard')
	local secret = newproxy(false)
	local real = issecretvalue
	issecretvalue = function(v) return v == secret or real(v) end
	local header = header_of('SaftUI_Raid10', 2)
	header:SetFrameLevel(5)
	rawset(header, 'GetFrameLevel', function() return secret end)
	local ok, border = pcall(UF.GroupBorder, UF, header)
	issecretvalue = real
	if check(ok, "the header's level secret: made: " .. tostring(border)) then
		eq(border:GetFrameLevel(), 6, 'left where it was made, one over the header')
	end
end)

test('which Theme turns the group border on', function()
	world('forever', 'blizzard')
	local party, raid = header_of('SaftUI_Party', 4), header_of('SaftUI_Raid10', 2)
	UF.groups = { party = party, raid10 = raid }
	-- A party member, drawn as UF:ApplyConfig draws each (its header places it).
	local member = make_unit_frame('SaftUI_PartyUnitButton1', 'party', { 'Health' }, party)
	member.is_group_unit = true
	member:SetPoint('TOP', party)
	local function shown(group)
		UF:UpdateGroupBorder(group)
		return UF:GroupBorder(UF.groups[group]):IsShown()
	end
	-- Whether a frame draws Thick: inset 2, with Thick's outer lines.
	local function thick(frame)
		return T.inset(frame.backdrop) == 2 and looks(frame):find(', outer, a line, ', 1, true) ~= nil
	end

	eq(P.party.theme, 'none', "the party's frame Theme is None by default")
	eq(P.party.health.theme, 'theme', "and its health's SaftUI's theme")
	eq(shown('party'), true, 'the party at its defaults: shown')

	P.party.theme = 'thick'
	UF:UpdateUnitFrame(member)
	eq(shown('party'), false, 'the frame Thick: hidden')
	check(thick(member), "and the member's frame draws Thick: " .. looks(member))
	P.party.theme = 'none'

	P.party.health.theme = 'thick'
	UF:UpdateUnitFrame(member)
	eq(shown('party'), false, 'the frame None and health Thick: hidden')
	check(thick(member.Health), "and the member's health draws Thick: " .. looks(member.Health))

	P.party.health.theme = 'none'
	eq(shown('party'), false, 'the frame None and health None: hidden')
	P.party.health.theme = 'theme'

	eq(P.raid10.theme, 'theme', "raid10's frame Theme is SaftUI's theme by default")
	eq(shown('raid10'), true, 'raid10 at its defaults: shown')

	st.config.profile.theme.name = 'thick'
	eq(shown('party'), false, "SaftUI's Thick: the party's hidden")
	eq(shown('raid10'), false, "SaftUI's Thick: raid10's hidden")
	-- A group whose frame Theme is Blizzard's own draws its members in
	-- Blizzard's look under any theme of SaftUI's: its border shows.
	P.raid10.theme = 'blizzard'
	eq(shown('raid10'), true, "SaftUI's Thick, raid10's frame Theme Blizzard: shown")
	eq(#take_errors(), 0, 'no errors')
end)

test("it follows a member joining in combat, with nothing of SaftUI's running, nothing protected called and nothing written onto the header", function()
	world('forever', 'blizzard')
	local header = header_of('SaftUI_Party', 4)
	UF.groups = { party = header }
	-- Made out of combat, as UF:CreateGroupHeaders makes it.
	local border = UF:GroupBorder(header)
	UF:UpdateGroupBorder('party')

	-- The header is protected, as a secure group header is.
	local protected = true
	rawset(header, 'IsProtected', function() return protected, protected end)
	stub.in_combat = true
	-- An update that reaches it in combat touches only SaftUI's border: hidden
	-- under Thick, shown again under Blizzard.
	st.config.profile.theme.name = 'thick'
	UF:UpdateGroupBorder('party')
	check(not border:IsShown(), 'in combat, under Thick: hidden')
	st.config.profile.theme.name = 'blizzard'
	UF:UpdateGroupBorder('party')
	check(border:IsShown(), 'in combat, under Blizzard: shown')
	eq(#stub.blocked, 0, 'nothing protected called')

	local calls = 0
	local real = UF.UpdateGroupBorder
	UF.UpdateGroupBorder = function(...) calls = calls + 1; return real(...) end
	-- The header's own secure layout pass for a fifth member: not addon code,
	-- so the game doesn't block it.
	protected = false; header:SetSize(200, 5 * 34 + 4 * 8); protected = true
	eq(T.around(border, header), '-2,2,2,-3', 'the border follows by its anchors')
	eq(size_of(border), '204x207', 'around five members')
	eq(calls, 0, "no code of SaftUI's ran")
	UF.UpdateGroupBorder = real
	stub.in_combat = false
	eq(#stub.blocked, 0, 'nothing protected called')
	eq(#take_errors(), 0, 'no errors')
end)

-- With the party's showPlayer off (its default), an invite makes a group of
-- one at once, so [group:party] holds and the header shows with no member to
-- show, for every pending invite and briefly while a group disbands. It sizes
-- itself to a sliver then (configureChildren in SecureGroupHeaders.lua:
-- minWidth by minHeight, at least 0.1; 200 by 0.1 for the party growing
-- down), where the border would be a bronze strip. So the border's art is
-- hidden (its alpha 0) while either side is under two of its pieces (12),
-- from the border's own OnSizeChanged, which the stub fires as the game's
-- layout pass does.
test("a header with no member to show (a pending invite) shows no bronze strip: the border's art waits until two pieces fit, in combat too", function()
	world('forever', 'blizzard')
	local header = header_of('SaftUI_Party', 4)
	UF.groups = { party = header }
	local border = UF:GroupBorder(header)
	UF:UpdateGroupBorder('party')
	eq(border:GetAlpha(), 1, 'four members: its art shows')

	-- The header is protected, as a secure group header is, and in combat it
	-- lays itself out: not addon code, so the game doesn't block it. That
	-- resizes the border by its anchors, and the game fires its OnSizeChanged.
	local protected = true
	rawset(header, 'IsProtected', function() return protected, protected end)
	stub.in_combat = true
	local function layout(width, height)
		protected = false; header:SetSize(width, height); protected = true
		check(stub.fire_script(border, 'OnSizeChanged', border:GetSize()), ('%sx%s: its OnSizeChanged ran'):format(width, height))
	end
	layout(200, 0.1)
	check(border:IsShown(), 'no member to show: still shown')
	eq(border:GetAlpha(), 0, 'but its art hidden: no bronze strip')
	layout(200, 34)
	eq(border:GetAlpha(), 1, 'one member: its art shows again')
	layout(200, 6)
	eq(border:GetAlpha(), 0, 'the border 11 tall: under two pieces, hidden')
	layout(200, 7)
	eq(border:GetAlpha(), 1, 'the border 12 tall: two pieces fit, shown')
	layout(0.1, 34)
	eq(border:GetAlpha(), 0, 'a header growing sideways with no member, 0.1 wide: hidden')
	layout(7, 34)
	eq(border:GetAlpha(), 0, 'the border 11 wide: hidden')
	layout(8, 34)
	eq(border:GetAlpha(), 1, 'the border 12 wide: shown')
	eq(#stub.blocked, 0, 'nothing protected called')

	-- A secret size (.agents/clients.md): no math on it, and the art stays as it
	-- was. A secret value is a newproxy here, which issecretvalue is told to recognise.
	local secret = newproxy(false)
	local real = issecretvalue
	issecretvalue = function(v) return v == secret or real(v) end
	stub.fire_script(border, 'OnSizeChanged', secret, secret)
	issecretvalue = real
	eq(border:GetAlpha(), 1, 'a secret size: left as it was')
	stub.in_combat = false
	eq(#take_errors(), 0, 'no errors')

	-- An update that finds the header a sliver (a /reload with an invite
	-- pending, an option changed then) hides the art too.
	header:SetSize(200, 0.1)
	UF:UpdateGroupBorder('party')
	check(border:IsShown(), 'an update with no member to show: shown')
	eq(border:GetAlpha(), 0, 'its art hidden')
	header:SetSize(200, 34)
	UF:UpdateGroupBorder('party')
	eq(border:GetAlpha(), 1, 'an update with one member: its art shows')
	eq(#stub.blocked, 0, 'nothing protected called')
	eq(#take_errors(), 0, 'no errors')
end)

test("UF:ApplyConfig draws the group border after the members', in combat too", function()
	world('forever', 'blizzard')
	-- An oUF header (UF:ApplyConfig keeps the group's config on it), protected
	-- as a secure group header is, with one member.
	local header = CreateFrame('Frame', 'SaftUI_Party', UIParent)
	header:SetPoint('CENTER')
	header:SetSize(200, 160)
	UF.units = {} -- no single units (UF:OnEnable spawns them)
	UF.groups = { party = header }
	local member = make_unit_frame('SaftUI_PartyUnitButton1', 'party', { 'Health' }, header)
	member.is_group_unit = true
	member:SetPoint('TOP', header)
	local border = UF:GroupBorder(header)

	local order = {}
	local realUnit, realBorder = UF.UpdateUnitFrame, UF.UpdateGroupBorder
	UF.UpdateUnitFrame = function(self, ...) order[#order + 1] = 'member'; return realUnit(self, ...) end
	UF.UpdateGroupBorder = function(self, ...) order[#order + 1] = 'border'; return realBorder(self, ...) end

	-- An option edit to the party's health: no layout pass.
	P.party.theme = 'thick'
	UF:ApplyConfig('party', 'Health')
	eq(table.concat(order, ','), 'member,border', 'the border after the members')
	check(not border:IsShown(), 'the frame Thick: hidden')

	order = {}
	header.IsProtected = function() return true, true end
	stub.in_combat = true
	P.party.theme = 'none'
	UF:ApplyConfig('party')
	stub.in_combat = false
	eq(table.concat(order, ','), 'member,border', 'in combat too, after the members')
	check(border:IsShown(), "the frame None and health SaftUI's theme: shown")
	eq(#stub.blocked, 0, 'nothing protected called')

	UF.UpdateUnitFrame, UF.UpdateGroupBorder = realUnit, realBorder
	eq(#take_errors(), 0, 'no errors')
end)

test('each group header gets its border as it spawns, out of combat', function()
	world('forever', 'blizzard')
	-- oUF's SpawnHeader, standing in: a plain frame for the header.
	UF.oUF.SpawnHeader = function(_, name) return CreateFrame('Frame', name, UIParent) end
	UF:CreateGroupHeaders()
	for _, group in ipairs({ 'party', 'raid10', 'raid40' }) do
		local header = UF.groups[group]
		eq(header:GetNumChildren(), 1, group .. ': one child, made with the header')
		check((header:GetChildren()) == UF:GroupBorder(header), group .. ': its border')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('test mode previews get the same border', function()
	for _, theme in ipairs({ 'blizzard', 'thick' }) do
		world('forever', theme)
		-- The party's real frames hidden (out of a group), as test mode shows
		-- its previews then.
		local header = header_of('SaftUI_Party', 4)
		header:Hide()
		UF.groups = { party = header }
		UF.holders.party = CreateFrame('Frame', 'SaftUI_PartyHolder', UIParent)
		UF.holders.party:SetPoint('CENTER')
		UF:SetGroupTestMode('party', true)

		local container = UF.previews.party
		if check(container ~= nil and container:IsShown(), theme .. ': the previews show') then
			local border = UF:GroupBorder(container)
			if theme == 'blizzard' then
				check(border:IsShown(), 'under Blizzard the previews sit in the border')
				eq(T.around(border, container), '-2,2,2,-3', "at Blizzard's offsets around them")
				eq((T.art(border):gsub('=[^,]*', '')), BOX, 'its eight pieces')
				eq(border:GetFrameLevel(), container:GetFrameLevel(), "at the container's level")
				check(border:GetFrameLevel() < container.frames[1]:GetFrameLevel(), 'under the previews')
			else
				check(not border:IsShown(), 'under Thick none')
				eq(T.art(border), '', 'nothing drawn')
				-- A switch to Blizzard with the previews up: they redraw, the border with them.
				st.config.profile.theme.name = 'blizzard'
				UF:UpdateGroupPreview('party')
				check(border:IsShown(), 'switched to Blizzard: the border shows')
			end
		end

		-- Boss frames are unit frames, not a group: their previews get no border.
		UF.units = { boss = {} }
		UF.holders.boss = CreateFrame('Frame', 'SaftUI_BossHolder', UIParent)
		UF.holders.boss:SetPoint('CENTER')
		for i = 1, 5 do
			local boss = CreateFrame('Frame', nil, UIParent)
			boss:Hide()
			UF.units.boss[i] = boss
		end
		UF:SetGroupTestMode('boss', true)
		local bosses = UF.previews.boss
		if check(bosses ~= nil and bosses:IsShown(), theme .. ': the boss previews show') then
			eq(bosses:GetNumChildren(), #bosses.frames, theme .. ': the boss previews, and no border among them')
		end
		eq(#take_errors(), 0, theme .. ': no errors')
	end
end)

------------------------------------------------------------------ the bar fills

-- Under Blizzard the health and power bars fill with Blizzard's raid bar art
-- (RaidFrame-Hp-Fill over raidframe-hp-bg-white, the resource fill over its
-- background), tiled as CompactUnitFrame.xml tiles them, and still tinted by
-- the bar's color. Only where the element's texture is the default (SaftUI
-- Flat) and its own resolved Theme is Blizzard's; Thick and Thin keep today's
-- flat fill.
local function flat(bar, where)
	eq(bar:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, where .. ': the flat fill')
	eq(bar:GetStatusBarTexture():GetAtlas(), nil, where .. ': with no atlas')
	check(not bar:GetStatusBarTexture():GetHorizTile() and not bar:GetStatusBarTexture():GetVertTile(), where .. ': not tiled')
end

test('under Blizzard health fills with RaidFrame-Hp-Fill over raidframe-hp-bg-white, power with the resource fill, still tinted', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 'blizzard')
		P.player.theme = 'theme'
		local player = make_unit_frame('P', 'player', { 'Health', 'Power' })
		UF:UpdateUnitFrame(player)
		local fill = player.Health:GetStatusBarTexture()
		eq(fill:GetAtlas(), 'RaidFrame-Hp-Fill', client .. ': health fill')
		check(fill:GetHorizTile() and fill:GetVertTile(), client .. ': health fill tiles both ways')
		eq(player.Health.bg:GetAtlas(), 'raidframe-hp-bg-white', client .. ': health bg')
		check(player.Health.bg:GetHorizTile() and player.Health.bg:GetVertTile(), client .. ': health bg tiles both ways')
		eq(player.Power:GetStatusBarTexture():GetAtlas(), '_RaidFrame-Resource-Fill', client .. ': power fill')
		check(player.Power:GetStatusBarTexture():GetHorizTile() and not player.Power:GetStatusBarTexture():GetVertTile(),
			client .. ': power fill tiles across only')
		eq(player.Power.bg:GetAtlas(), '_RaidFrame-Resource-Background', client .. ': power bg')
		check(player.Power.bg:GetHorizTile() and not player.Power.bg:GetVertTile(), client .. ': power bg tiles across only')

		player.Health:SetStatusBarColor(0.2, 0.4, 0.6) -- as oUF's class color does
		eq(T.text(player.Health:GetStatusBarColor()), '0.20,0.40,0.60,1.00', client .. ': the class color still tints it')

		-- A custom color lands after an update, on the Blizzard fill.
		P.player.health.colorCustom, P.player.health.customColor = true, { 0.9, 0.1, 0.1 }
		UF:UpdateUnitFrame(player)
		eq(player.Health:GetStatusBarTexture():GetAtlas(), 'RaidFrame-Hp-Fill', client .. ': still the Blizzard fill')
		eq(T.text(player.Health:GetStatusBarColor()), '0.90,0.10,0.10,1.00', client .. ': the custom color')

		-- Power's PostUpdate used to put the flat texture back on every update.
		player.Power.text = nil
		player.Power.PostUpdate(player.Power, 'player', 50, 0, 100)
		eq(player.Power:GetStatusBarTexture():GetAtlas(), '_RaidFrame-Resource-Fill', client .. ': power keeps it through an update')
		eq(player.Power.bg:GetAtlas(), '_RaidFrame-Resource-Background', client .. ': and its bg')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('only the default texture, only its own Blizzard look; Thick puts the flat fill back', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 'blizzard')
		P.player.theme = 'theme'
		local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'Castbar' })
		UF:UpdateUnitFrame(player)
		eq(player.Health:GetStatusBarTexture():GetAtlas(), 'RaidFrame-Hp-Fill', client .. ': the default')
		check(player.Castbar:GetStatusBarTexture():GetAtlas() == nil, client .. ': the castbar keeps its texture')

		-- A texture the user picked stays.
		P.player.health.texture = 'Another'
		UF:UpdateUnitFrame(player)
		eq(player.Health:GetStatusBarTexture():GetAtlas(), nil, client .. ': a picked texture, no atlas')
		eq(player.Health:GetStatusBarTexture():GetTexture(), st:GetStatusBarTexture('Another'), client .. ': the picked texture')
		eq(player.Health.bg:GetAtlas(), nil, client .. ': and the bg is flat')
		check(not player.Health.bg:GetHorizTile(), client .. ': untiled')
		P.player.health.texture = 'SaftUI Flat'

		-- Health set to None while SaftUI's theme is Blizzard: not a Blizzard
		-- Theme of its own, so the flat fill.
		P.player.health.theme = 'none'
		UF:UpdateUnitFrame(player)
		flat(player.Health, client .. ': health with Theme None')
		eq(player.Health.bg:GetAtlas(), nil, client .. ': its bg too')
		P.player.health.theme = 'theme'

		UF:UpdateUnitFrame(player)
		eq(player.Health:GetStatusBarTexture():GetAtlas(), 'RaidFrame-Hp-Fill', client .. ': back')

		st.config.profile.theme.name = 'thick'
		UF:UpdateUnitFrame(player)
		for _, bar in ipairs({ player.Health, player.Power }) do
			flat(bar, client .. ': Thick, ' .. bar.name)
			eq(bar.bg:GetTexture(), st.BLANK_TEX, client .. ': ' .. bar.name .. ' bg flat')
			eq(bar.bg:GetAtlas(), nil, client .. ': ' .. bar.name .. ' bg no atlas')
			check(not bar.bg:GetHorizTile() and not bar.bg:GetVertTile(), client .. ': ' .. bar.name .. ' bg untiled')
		end
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

-- Counts the calls that put art on a bar and its bg: SetStatusBarTexture on
-- the bar and SetAtlas / SetTexture on the bar's texture and the bg.
local function art_calls(bar)
	local n = { count = 0 }
	local function wrap(object, method)
		local original = object[method]
		object[method] = function(...) n.count = n.count + 1; return original(...) end
	end
	wrap(bar, 'SetStatusBarTexture')
	for _, texture in ipairs({ bar:GetStatusBarTexture(), bar.bg }) do
		wrap(texture, 'SetAtlas')
		wrap(texture, 'SetTexture')
	end
	return n
end

test('a bar already drawn with a fill is not drawn again; a change redraws it', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 'blizzard')
		P.player.theme = 'theme'
		local player = make_unit_frame('P', 'player', { 'Health', 'Power' })
		UF:UpdateUnitFrame(player)
		player.Power.text = nil
		local calls = art_calls(player.Power)
		player.Power.PostUpdate(player.Power, 'player', 50, 0, 100)
		UF:SetBarFill(player.Power, player.Power.barFill, player.Power.barFlat)
		eq(calls.count, 0, client .. ': the same fill again draws nothing')
		eq(player.Power:GetStatusBarTexture():GetAtlas(), '_RaidFrame-Resource-Fill', client .. ': still drawn')

		st.config.profile.theme.name = 'thick'
		UF:UpdateUnitFrame(player)
		check(calls.count > 0, client .. ': a theme switch redraws')
		flat(player.Power, client .. ': flat under Thick')
		calls.count = 0
		player.Power.PostUpdate(player.Power, 'player', 40, 0, 100)
		eq(calls.count, 0, client .. ': and the flat fill is not drawn again either')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('a power bar with a picked texture keeps it through its own updates', function()
	for _, theme in ipairs({ 'thick', 'blizzard' }) do
		world('forever', theme)
		P.player.theme = 'theme'
		P.player.power.texture = 'Another'
		local player = make_unit_frame('P', 'player', { 'Health', 'Power' })
		UF:UpdateUnitFrame(player)
		local picked = st:GetStatusBarTexture('Another')
		check(picked ~= st.BLANK_TEX, theme .. ': the test texture is not the flat one')
		player.Power.text = nil
		player.Power.PostUpdate(player.Power, 'player', 50, 0, 100)
		eq(player.Power:GetStatusBarTexture():GetTexture(), picked, theme .. ': kept through PostUpdate')
		eq(player.Power:GetStatusBarTexture():GetAtlas(), nil, theme .. ': no atlas')
		eq(#take_errors(), 0, theme .. ': no errors')
	end
end)

test('additional power takes the power fill; a group preview keeps the Blizzard fill through its updates', function()
	world('forever', 'blizzard')
	P.player.theme = 'theme'
	local player = make_unit_frame('P', 'player', { 'Health', 'Power', 'AdditionalPower' })
	P.player.additionalpower.enable = true
	UF:UpdateUnitFrame(player)
	eq(player.AdditionalPower:GetStatusBarTexture():GetAtlas(), '_RaidFrame-Resource-Fill', 'additional power fill')
	eq(player.AdditionalPower.bg:GetAtlas(), '_RaidFrame-Resource-Background', 'additional power bg')

	UF.groups = { party = CreateFrame('Frame', 'SaftUI_Party', UIParent) }
	UF.groups.party:Hide()
	UF.holders.party = CreateFrame('Frame', 'SaftUI_PartyHolder', UIParent)
	UF.holders.party:SetPoint('CENTER')
	local member = make_unit_frame('SaftUI_PartyUnitButton1', 'party', { 'Health', 'Power', 'Castbar' }, UF.groups.party)
	member.is_group_unit = true
	member:SetPoint('CENTER', UIParent)
	P.party.theme = 'theme'
	P.party.power.enable = true
	UF:UpdateUnitFrame(member)
	UF.testGroups.party = true
	UF:UpdateGroupPreview('party')
	local preview = UF.previews.party and UF.previews.party.frames[1]
	if check(preview ~= nil, 'the party previews show') then
		eq(preview.Health:GetStatusBarTexture():GetAtlas(), 'RaidFrame-Hp-Fill', 'preview health')
		eq(preview.Power:GetStatusBarTexture():GetAtlas(), '_RaidFrame-Resource-Fill', 'preview power')
		eq(preview.Power.bg:GetAtlas(), '_RaidFrame-Resource-Background', 'preview power bg')
	end
	eq(#take_errors(), 0, 'no errors')
end)
