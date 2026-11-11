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
--     as members, a boss's as unit frames.
--
-- The world is theme_test.lua's (see its top), made fresh on each client
-- (world): real Core and its defaults, the unit frames' defaults (every
-- unit's), unitframes.lua, groups.lua, config/config.lua, constructors.lua,
-- updaters.lua and the bar and aura elements; oUF stood in for by its colors
-- table, and a unit frame by a SaftUI button with UF.ConstructUnit's fields
-- and the elements a test names, built by their own constructors
-- (make_unit_frame). The draw calls are watched (T.watch), since the kind
-- changes nothing under Thick and Thin.
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
	for _, file in ipairs({ 'unitframes', 'groups', 'config/config', 'constructors', 'updaters' }) do
		load_saftui('SaftUI-Unitframes/' .. file .. '.lua')
	end
	for _, file in ipairs(ELEMENTS) do
		load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
	end
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st.StringFormat = LibStub('LibStringFormat-1.0')
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

		-- The unit frame itself, 10 tall, with its own Theme.
		P.target.theme, P.target.height = 'theme', 10
		UF:UpdateUnitFrame(target)
		eq(drawn(target), 'theme,theme,small', client .. ': a unit frame 10 tall')
		eq(blizzard(target), 'small', client .. ': a line and the fill')
		eq(drawn(target.Health), 'theme,theme,small', client .. ': its health, filling it, is small too')
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

------------------------------------------------------------------ previews

-- Each part a preview has (groups.lua's CreatePreviewFrame) as
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
