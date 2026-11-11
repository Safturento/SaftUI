-- SaftUI-Misc/Skinning/ZoneText.lua, the zone text that shows when you enter a
-- zone:
--   - the faction: the game's PvP status as Alliance, Horde or Neutral, and
--     each word in its Colors tab text color;
--   - the level range: a range, a single level, none;
--   - the line under the zone name, e.g. "Level 10-20 . Alliance", in place of
--     Blizzard's PvP line, with the subzone name under it; in an instance, the
--     level only (never an outdoor zone's), and the difficulty line; both
--     cleared when a banner clears Blizzard's zone text;
--   - the hooks: Blizzard's OnEvent handler stays and runs first, nothing is
--     written onto Blizzard's frames or into its globals, and SaftUI's fade
--     times still apply.
--
-- Real: Core's helpers, LibStringFormat, SaftUI-Misc's config.lua,
-- Skinning/skinning.lua, ZoneText.lua and ZoneFactions.lua. Blizzard's zone
-- text and world map are zone_helpers.lua's stand-ins, locked so a write onto
-- them fails.
local H = load_test_file('misc/zone_helpers.lua')
local ZT = H.fresh()
local enable_errors = take_errors()
local st = SaftUI

local DASH = '\226\128\147' -- an en dash, U+2013
local DOT = '\194\183' -- a middle dot, U+00B7

-- The maps the player can be on (stub.maps): Eastern Kingdoms, two zones in
-- it, a cave in one, a dungeon with a second floor, an orphan map hung off the
-- continent and one in a zone (a garrison), and Kalimdor's The Barrens with
-- Warsong Gulch, a battleground the game files as an orphan map under it.
local function set_maps()
	stub.maps = {
		[1414] = { name = 'Kalimdor', mapType = Enum.UIMapType.Continent },
		[1413] = { name = 'The Barrens', mapType = Enum.UIMapType.Zone, parentMapID = 1414, levels = { 10, 25 } },
		[1460] = { name = 'Warsong Gulch', mapType = Enum.UIMapType.Orphan, parentMapID = 1413 },
		[9202] = { name = 'The Deadmines, the Mast Room', mapType = Enum.UIMapType.Micro, parentMapID = 9200 },
		[9301] = { name = 'Lunarfall', mapType = Enum.UIMapType.Orphan, parentMapID = 1429 },
		[1415] = { name = 'Eastern Kingdoms', mapType = Enum.UIMapType.Continent, levels = { 1, 60 } },
		[1429] = { name = 'Elwynn Forest', mapType = Enum.UIMapType.Zone, parentMapID = 1415, levels = { 1, 10 } },
		[1434] = { name = 'Stranglethorn Vale', mapType = Enum.UIMapType.Zone, parentMapID = 1415, levels = { 30, 30 } },
		[1453] = { name = 'Stormwind City', mapType = Enum.UIMapType.Zone, parentMapID = 1415 },
		[9100] = { name = 'Jasperlode Mine', mapType = Enum.UIMapType.Micro, parentMapID = 1429 },
		[9200] = { name = 'The Deadmines', mapType = Enum.UIMapType.Dungeon, parentMapID = 1436, levels = { 15, 21 } },
		[9201] = { name = 'The Stockade', mapType = Enum.UIMapType.Dungeon, parentMapID = 1453 },
		[9300] = { name = 'Lonely Isle', mapType = Enum.UIMapType.Orphan, parentMapID = 1415 },
	}
end

-- Puts the player somewhere: on map, with the game's PvP status there, in an
-- instance or not.
local function place(map, pvpType, factionName, instance)
	set_maps()
	stub.player_map = map
	stub.pvp = { type = pvpType, faction = factionName }
	stub.instance = instance
end

local DEADMINES = { name = 'The Deadmines', type = 'party', difficulty_id = 1, difficulty_name = 'Normal', max_players = 5 }

test('enabling the module raised no error', function()
	eq(#enable_errors, 0, 'errors: ' .. table.concat(enable_errors, '; '))
end)

------------------------------------------------------------------ the hooks

test("Blizzard's OnEvent handler stays, and SaftUI's line follows it", function()
	eq(ZoneTextFrame:GetScript('OnEvent'), ZoneText_OnEvent, "Blizzard's handler is still the frame's script")
	place(1429, 'friendly', 'Alliance')
	H.enter('Elwynn Forest', 'Goldshire')
	eq(ZoneTextString:GetText(), 'Elwynn Forest', "Blizzard's handler ran")
	eq(ZT.ZoneLineString:GetText(), 'Level 1' .. DASH .. '10 ' .. DOT .. ' ' .. H.colored('Alliance', 'blue'),
		'and SaftUI set its line after it')
	eq(#take_errors(), 0, 'nothing written onto the locked frames')
end)

test("Blizzard's zone text globals keep Blizzard's values, and SaftUI's fade times are on its frames", function()
	eq(ZoneFadeInDuration, 0.5, 'ZoneFadeInDuration')
	eq(ZoneHoldDuration, 1.0, 'ZoneHoldDuration')
	eq(ZoneFadeOutDuration, 2.0, 'ZoneFadeOutDuration')
	for _, frame in ipairs({ ZoneTextFrame, SubZoneTextFrame }) do
		local name = frame:GetName()
		eq(frame.fadeInTime, 1, name .. ' fades in over a second')
		eq(frame.holdTime, 2, name .. ' holds for two')
		eq(frame.fadeOutTime, 2, name .. ' fades out over two')
	end
end)

------------------------------------------------------------------ the faction

test('the PvP status names the faction: friendly and hostile zones their holder, anything else Neutral', function()
	eq(ZT.FactionFromPvP('friendly', 'Alliance'), 'Alliance', 'friendly, Alliance')
	eq(ZT.FactionFromPvP('hostile', 'Horde'), 'Horde', 'hostile, Horde')
	eq(ZT.FactionFromPvP('hostile', 'Alliance'), 'Alliance', 'a hostile Alliance zone (for a Horde player)')
	for _, pvpType in ipairs({ 'contested', 'sanctuary', 'arena', 'combat', '' }) do
		eq(ZT.FactionFromPvP(pvpType, nil), 'Neutral', pvpType)
	end
	eq(ZT.FactionFromPvP(nil, nil), 'Neutral', 'no PvP status')
	eq(ZT.FactionFromPvP('contested', 'Alliance'), 'Neutral', 'a faction name never makes a contested zone a faction')
end)

test("a faction name in another language is told apart by the player's own faction", function()
	-- The stubbed player is Alliance.
	eq(ZT.FactionFromPvP('friendly', 'Allianz'), 'Alliance', 'friendly: the player\'s faction')
	eq(ZT.FactionFromPvP('hostile', 'Horda'), 'Horde', 'hostile: the other one')
	eq(ZT.FactionFromPvP('friendly', ''), 'Alliance', 'an empty name too')
	local factionGroup = UnitFactionGroup
	_G.UnitFactionGroup = function() return 'Neutral', 'Neutral' end -- an unaligned pandaren
	eq(ZT.FactionFromPvP('friendly', 'Allianz'), 'Neutral', 'a player of no faction can\'t tell, so Neutral')
	eq(ZT.FactionFromPvP('friendly', 'Alliance'), 'Alliance', 'but an English name still counts')
	_G.UnitFactionGroup = factionGroup
end)

test("LiveFaction reads the game's PvP status where the player stands, and nil when it gives none", function()
	place(1429, 'hostile', 'Horde')
	eq(ZT:LiveFaction(), 'Horde', 'hostile, Horde')
	place(1429, 'sanctuary')
	eq(ZT:LiveFaction(), 'Neutral', 'a sanctuary')
	place(1429, '')
	eq(ZT:LiveFaction(), nil, "no status: the game's ''")
	stub.pvp = {}
	eq(ZT:LiveFaction(), nil, 'no status at all (the API may return nothing)')
end)

test("LiveFaction hands the game's faction name on", function()
	local factionGroup = UnitFactionGroup
	_G.UnitFactionGroup = function() return 'Neutral', 'Neutral' end -- an unaligned pandaren
	place(1429, 'friendly', 'Alliance')
	eq(ZT:LiveFaction(), 'Alliance', 'friendly, Alliance: from the name, not the player')
	_G.UnitFactionGroup = factionGroup
end)

test("each word takes its Colors tab text color: Alliance blue, Horde red, Neutral yellow", function()
	eq(ZT:ColorFaction('Alliance'), H.colored('Alliance', 'blue'), 'Alliance')
	eq(ZT:ColorFaction('Horde'), H.colored('Horde', 'red'), 'Horde')
	eq(ZT:ColorFaction('Neutral'), H.colored('Neutral', 'yellow'), 'Neutral')
	local blue = st.config.profile.colors.text.blue
	st.config.profile.colors.text.blue = CreateColor(0, 0, 1)
	eq(ZT:ColorFaction('Alliance'), '|cff0000ffAlliance|r', "a changed color is the user's palette")
	st.config.profile.colors.text.blue = blue
end)

------------------------------------------------------------------ the level range

test('the level range: a range, a single level, or nothing without one', function()
	eq(ZT.FormatLevels(10, 20), 'Level 10' .. DASH .. '20', 'a range, with an en dash')
	eq(ZT.FormatLevels(70, 70), 'Level 70', 'one level when both ends match')
	eq(ZT.FormatLevels(0, 0), nil, "the game's 0s mean none")
	eq(ZT.FormatLevels(0, 60), nil, 'a range missing one end is none')
	eq(ZT.FormatLevels(nil, nil), nil, 'no range at all')
end)

test("the zone's levels: its own, its zone's from a cave, never a continent's", function()
	place(1429)
	check(select(1, ZT:PlayerZoneLevels()) == 1 and select(2, ZT:PlayerZoneLevels()) == 10, 'Elwynn Forest: 1 to 10')
	place(9100)
	eq(select(2, ZT:PlayerZoneLevels()), 10, "a cave with none: Elwynn's, the zone it's in")
	place(9300)
	eq(ZT:PlayerZoneLevels(), nil, "an orphan map with none: not the continent's above it")
	place(1453)
	eq(ZT:PlayerZoneLevels(), nil, 'a city the game gives none')
	place(nil)
	eq(ZT:PlayerZoneLevels(), nil, 'no map (a loading screen)')
end)

------------------------------------------------------------------ the line

local function line_after_entering(zone, subzone)
	H.enter(zone, subzone)
	return ZT.ZoneLineString:GetText()
end

test('the line: the level range and the colored faction', function()
	place(1429, 'friendly', 'Alliance')
	eq(line_after_entering('Elwynn Forest'), 'Level 1' .. DASH .. '10 ' .. DOT .. ' ' .. H.colored('Alliance', 'blue'), 'a range')
	place(1434, 'contested')
	eq(line_after_entering('Stranglethorn Vale'), 'Level 30 ' .. DOT .. ' ' .. H.colored('Neutral', 'yellow'), 'a single level')
	place(1453, 'friendly', 'Alliance')
	eq(line_after_entering('Stormwind City'), H.colored('Alliance', 'blue'), 'no level range: the faction only')
	place(9100, 'hostile', 'Horde')
	eq(line_after_entering('Elwynn Forest'), 'Level 1' .. DASH .. '10 ' .. DOT .. ' ' .. H.colored('Horde', 'red'),
		"in a cave: the zone's levels, the live faction")
	place(1429, '')
	eq(line_after_entering('Elwynn Forest'), 'Level 1' .. DASH .. '10 ' .. DOT .. ' ' .. H.colored('Neutral', 'yellow'),
		'no PvP status: Neutral, as anything but friendly or hostile is')
	place(9301, 'friendly', 'Alliance')
	eq(line_after_entering('Elwynn Forest'), 'Level 1' .. DASH .. '10 ' .. DOT .. ' ' .. H.colored('Alliance', 'blue'),
		"outside an instance, an orphan map in a zone (a garrison): the zone's levels")
end)

test("in an instance: the level if the game gives one, no faction, and the difficulty line", function()
	place(9200, 'sanctuary', nil, DEADMINES)
	eq(line_after_entering('The Deadmines'), 'Level 15' .. DASH .. '21', 'the level only')
	check((ZT.DifficultyTextString:GetText() or ''):find('Normal', 1, true), 'the difficulty line names it: '
		.. tostring(ZT.DifficultyTextString:GetText()))
	place(9201, 'sanctuary', nil, { name = 'The Stockade', type = 'party', max_players = 5 })
	eq(line_after_entering('The Stockade'), '', 'no level: an empty line')
	place(9201, 'pvp', nil, { name = 'Warsong Gulch', type = 'pvp', max_players = 10 })
	eq(line_after_entering('Warsong Gulch'), '', 'a battleground is an instance too')
	place(9202, 'sanctuary', nil, DEADMINES)
	eq(line_after_entering('The Deadmines', 'The Mast Room'), 'Level 15' .. DASH .. '21', "a dungeon's second floor: the dungeon's level")
end)

test("in an instance filed as an orphan map under a zone, nothing of the zone outside", function()
	-- Warsong Gulch (Forever 1460) is an orphan map under The Barrens, with no levels of its own.
	place(1460, 'combat', nil, { name = 'Warsong Gulch', type = 'pvp', max_players = 10 })
	eq(line_after_entering('Warsong Gulch'), '', "no level: not The Barrens'")
	eq(ZT:IsPlayerIn(1413), false, 'nor is the player in The Barrens')
	eq(ZT:MapFaction(1413), 'Horde', "so The Barrens on the map is the table's Horde, not the battleground's status")
	eq(ZT:IsPlayerIn(1460), true, 'the player is in Warsong Gulch itself')
end)

test("a banner clearing Blizzard's zone text clears SaftUI's line and the difficulty line too", function()
	place(1429, 'friendly', 'Alliance')
	H.enter('Elwynn Forest', 'Goldshire')
	check(ZT.ZoneLineString:GetText() ~= '', 'the line is up')
	ZoneText_Clear() -- what the world quest and PvP objective banners call
	eq(ZoneTextString:GetText(), '', "Blizzard's zone name is cleared")
	eq(ZoneTextFrame:IsShown(), true, 'while its frame keeps fading')
	eq(ZT.ZoneLineString:GetText(), '', "and SaftUI's line with it")

	place(9200, 'sanctuary', nil, DEADMINES)
	H.enter('The Deadmines')
	check((ZT.DifficultyTextString:GetText() or '') ~= '', 'the difficulty line is up')
	ZoneText_Clear()
	eq(ZT.DifficultyTextString:GetText(), '', 'and goes too')
	eq(#take_errors(), 0, 'nothing written onto the locked frames')
end)

test("the line takes the place of Blizzard's PvP line, which stays unseen", function()
	place(1434, 'contested')
	H.enter('Stranglethorn Vale', 'Booty Bay')
	eq(PVPInfoTextString:GetText(), '(Contested Territory)', 'Blizzard still writes its PvP line')
	eq(PVPInfoTextString:GetAlpha(), 0, 'but it is unseen')
	local line = H.pt(ZT.ZoneLineString, 'TOP')
	check(line and line.rel == ZoneTextString and line.relPoint == 'BOTTOM', 'the line sits where it was, under the zone name')
	local sub = H.pt(SubZoneTextString, 'TOP')
	check(sub and sub.rel == ZT.ZoneLineString and sub.relPoint == 'BOTTOM', 'the subzone name goes under the line')
	eq(SubZoneTextString:GetNumPoints(), 1, 'with one anchor')
	eq(ZT.ZoneLineString:GetParent(), ZoneTextFrame, 'the line fades with the zone name')
end)

test('with no line, or no zone name shown, the subzone name goes under the zone name', function()
	place(9201, 'sanctuary', nil, { name = 'The Stockade', type = 'party', max_players = 5 })
	H.enter('The Stockade', 'Cell Block')
	local sub = H.pt(SubZoneTextString, 'TOP')
	check(sub and sub.rel == ZoneTextString and sub.relPoint == 'BOTTOM', 'an empty line leaves no gap')

	place(1434, 'contested')
	H.enter('Stranglethorn Vale')
	ZoneTextFrame:Hide() -- its fade ended
	stub.pvp = { type = 'sanctuary' } -- Booty Bay's own status, so Blizzard keeps its PvP line
	H.enter('Stranglethorn Vale', 'Booty Bay', 'ZONE_CHANGED')
	eq(SubZoneTextString:GetText(), 'Booty Bay', 'the subzone shows alone')
	sub = H.pt(SubZoneTextString, 'TOP')
	check(sub and sub.rel == ZoneTextString and sub.relPoint == 'BOTTOM', 'under the zone name, as Blizzard has it')
	eq(ZT.DifficultyTextString:GetText(), '', 'and no difficulty outside an instance')
end)

test('a text color change recolors a line still on screen', function()
	place(1429, 'friendly', 'Alliance')
	H.enter('Elwynn Forest')
	local blue = st.config.profile.colors.text.blue
	st.config.profile.colors.text.blue = CreateColor(0, 0, 1)
	st:ColorsChanged('text')
	check(ZT.ZoneLineString:GetText():find('|cff0000ffAlliance|r', 1, true), 'the new blue: ' .. ZT.ZoneLineString:GetText())
	st.config.profile.colors.text.blue = blue
	local r, g, b = ZT.ZoneLineString:GetTextColor()
	local nr, ng, nb = st.config.profile.colors.text.normal:GetRGB()
	check(r == nr and g == ng and b == nb, 'the rest of the line is ordinary text')
end)
