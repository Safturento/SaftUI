-- SaftUI-Misc/Skinning/ZoneText.lua on the world map: hovering a zone, a line
-- under Blizzard's zone name and level label names who holds it, in that
-- faction's color:
--   - from ZoneFactions.lua's table, and for the zone you're in from the
--     game's live PvP status;
--   - nothing for a zone the table lacks, off the canvas, over the map's own
--     area or under another label (a point of interest's);
--   - under the label's description line when it has one;
--   - hooked with HookScript on the label Blizzard made, writing nothing onto
--     it or the map, also when the map loads after SaftUI.
--
-- Real: as zone_text_test.lua. The world map, its area label provider and the
-- label are zone_helpers.lua's stand-ins of Blizzard's (AreaLabelDataProvider.lua),
-- locked so a write onto them fails. The stubs run no OnUpdate, so H.hover
-- runs the label's once for each cursor position.
local H = load_test_file('misc/zone_helpers.lua')
local ZT = H.fresh()
local enable_errors = take_errors()
local st = SaftUI

-- The Eastern Kingdoms (Forever's IDs), as the map shows it, and where each
-- zone sits on it. Testlands (9001) is in no table.
local function set_maps()
	stub.maps = {
		[1415] = { name = 'Eastern Kingdoms', mapType = Enum.UIMapType.Continent },
		[1429] = { name = 'Elwynn Forest', mapType = Enum.UIMapType.Zone, parentMapID = 1415,
			levels = { 1, 10 }, area = { 0.40, 0.70, 0.50, 0.80 } },
		[1436] = { name = 'Westfall', mapType = Enum.UIMapType.Zone, parentMapID = 1415,
			levels = { 9, 18 }, area = { 0.30, 0.75, 0.39, 0.85 } },
		[1434] = { name = 'Stranglethorn Vale', mapType = Enum.UIMapType.Zone, parentMapID = 1415,
			levels = { 30, 45 }, area = { 0.35, 0.86, 0.50, 0.99 } },
		[1420] = { name = 'Tirisfal Glades', mapType = Enum.UIMapType.Zone, parentMapID = 1415,
			levels = { 1, 10 }, area = { 0.35, 0.10, 0.50, 0.20 } },
		[9001] = { name = 'Testlands', mapType = Enum.UIMapType.Zone, parentMapID = 1415,
			levels = { 5, 5 }, area = { 0.60, 0.10, 0.70, 0.20 } },
		[9100] = { name = 'Jasperlode Mine', mapType = Enum.UIMapType.Micro, parentMapID = 1429 },
	}
	stub.player_map = nil
	stub.pvp = {}
end
set_maps()

local ELWYNN, WESTFALL, STRANGLETHORN, TIRISFAL, TESTLANDS = { 0.45, 0.75 }, { 0.35, 0.80 }, { 0.40, 0.90 }, { 0.40, 0.15 }, { 0.65, 0.15 }

local function hover(at)
	H.hover(at and at[1], at and at[2])
end

-- The faction line's text, or nil while it's hidden.
local function line()
	return ZT.mapLine:IsShown() and ZT.mapLine:GetText() or nil
end

test('enabling the module raised no error', function()
	eq(#enable_errors, 0, 'errors: ' .. table.concat(enable_errors, '; '))
end)

test("the label keeps Blizzard's OnUpdate, and SaftUI's line is its own font string on it", function()
	eq(H.label:GetScript('OnUpdate'), H.label_onupdate, "Blizzard's OnUpdate is still the label's script")
	check(ZT.mapLine ~= nil and ZT.mapLine:GetObjectType() == 'FontString', 'a font string')
	eq(ZT.mapLine:GetParent(), H.label, 'on the label, so it shows, scales and fades with it')
	eq(ZT.mapLine:GetFontObject(), SubZoneTextFont, "in the label's description font")
end)

test("hovering a zone shows its faction from the table, in the faction's color", function()
	set_maps()
	hover(ELWYNN)
	eq(H.label.Name:GetText(), 'Elwynn Forest|cffffff00 (1-10)|r', "Blizzard's label names the zone and its levels")
	eq(line(), H.colored('Alliance', 'blue'), 'Elwynn Forest: Alliance')
	hover(TIRISFAL)
	eq(line(), H.colored('Horde', 'red'), 'Tirisfal Glades: Horde')
	hover(STRANGLETHORN)
	eq(line(), H.colored('Neutral', 'yellow'), 'Stranglethorn Vale: Neutral')
	hover(WESTFALL)
	eq(line(), H.colored('Alliance', 'blue'), 'Westfall: Alliance')
	eq(#take_errors(), 0, 'nothing written onto the locked map or label')
end)

test('the line sits under the zone name, or under the description when there is one', function()
	set_maps()
	hover(ELWYNN)
	local p = H.pt(ZT.mapLine, 'TOP')
	check(p and p.rel == H.label.Name and p.relPoint == 'BOTTOM' and p.y == -10, 'under the name')
	hover(nil)
	rawset(H.label, '_description', 'Wild battle pets (1-3)')
	hover(ELWYNN)
	eq(H.label.Description:GetText(), 'Wild battle pets (1-3)', "Blizzard's label has a description")
	p = H.pt(ZT.mapLine, 'TOP')
	check(p and p.rel == H.label.Description and p.relPoint == 'BOTTOM' and p.y == -10, 'under the description')
	eq(ZT.mapLine:GetNumPoints(), 1, 'with one anchor')
	rawset(H.label, '_description', nil)
end)

test('no line for a zone the table lacks, off the canvas, or over the map itself', function()
	set_maps()
	hover(ELWYNN)
	hover(TESTLANDS)
	eq(H.label.Name:GetText(), 'Testlands|cffffff00 (5)|r', 'Blizzard labels it')
	eq(line(), nil, 'Testlands is in no table: no line')
	hover(ELWYNN)
	hover(nil)
	eq(line(), nil, 'the cursor left the canvas')
	hover(ELWYNN)
	hover({ 0.90, 0.50 })
	eq(line(), nil, "over the continent's own area, where there's no zone")
end)

test("no line while another label, a point of interest's, shows over the zone's", function()
	set_maps()
	hover(ELWYNN)
	H.label:SetLabel(MAP_AREA_LABEL_TYPE.POI, 'Goldshire Inn') -- as the point of interest's pin does on hover
	hover(ELWYNN)
	eq(H.label.Name:GetText(), 'Goldshire Inn', "Blizzard's label shows the point of interest")
	eq(line(), nil, 'so no faction line')
	H.label:ClearLabel(MAP_AREA_LABEL_TYPE.POI)
	hover(ELWYNN)
	eq(line(), H.colored('Alliance', 'blue'), 'back on the zone')
end)

test("for the zone you're in, the game's live PvP status wins over the table", function()
	set_maps()
	hover(ELWYNN)
	eq(line(), H.colored('Alliance', 'blue'), 'Elwynn Forest from elsewhere: the table')
	-- The map stays open, the cursor on Elwynn Forest, as you walk into it.
	stub.player_map, stub.pvp = 1429, { type = 'contested' }
	H.enter('Elwynn Forest')
	hover(ELWYNN)
	eq(line(), H.colored('Neutral', 'yellow'), 'once you enter it, contested right now: Neutral')
	hover(WESTFALL)
	eq(line(), H.colored('Alliance', 'blue'), "Westfall, where you aren't: the table")
	stub.player_map, stub.pvp = 9100, { type = 'hostile', faction = 'Horde' }
	H.enter('Elwynn Forest', 'Jasperlode Mine', 'ZONE_CHANGED_INDOORS')
	hover(ELWYNN)
	eq(line(), H.colored('Horde', 'red'), 'from a cave in Elwynn Forest: still the live status')
	stub.player_map, stub.pvp = 9001, { type = 'friendly', faction = 'Alliance' }
	H.enter('Testlands')
	hover(TESTLANDS)
	eq(line(), H.colored('Alliance', 'blue'), 'and for a zone the table lacks')
end)

test('MapFaction: the live status for your zone, the table for the rest, nil for neither', function()
	set_maps()
	stub.player_map, stub.pvp = 1429, { type = 'sanctuary' }
	eq(ZT:MapFaction(1429), 'Neutral', 'your zone: live')
	eq(ZT:MapFaction(1420), 'Horde', 'another: the table')
	eq(ZT:MapFaction(9001), nil, 'one the table lacks')
	eq(ZT:MapFaction(nil), nil, 'no zone')
	stub.player_map = nil
	eq(ZT:MapFaction(1429), 'Alliance', 'no player map: the table')
end)

test('a zone under the cursor that is not the one the label names gets no line', function()
	set_maps()
	H.hover(ELWYNN[1], ELWYNN[2])
	eq(ZT:HoveredZone('Elwynn Forest|cffffff00 (1-10)|r'), 1429, 'the label names the zone under the cursor')
	eq(ZT:HoveredZone('Westfall|cffffff00 (9-18)|r'), nil, 'a label for another zone (a gamepad cursor elsewhere)')
end)

test('a text color change shows on the next frame', function()
	set_maps()
	hover(ELWYNN)
	local blue = st.config.profile.colors.text.blue
	st.config.profile.colors.text.blue = CreateColor(0, 0, 1)
	st:ColorsChanged('text')
	hover(ELWYNN)
	eq(line(), '|cff0000ffAlliance|r', 'the new blue, without moving the cursor')
	st.config.profile.colors.text.blue = blue
end)

test('a world map that loads after SaftUI is hooked when it loads', function()
	ZT = H.fresh({ map = false })
	eq(#take_errors(), 0, 'enabling without a map raised no error')
	eq(ZT.mapLine, nil, 'nothing to hook yet')
	H.make_world_map()
	stub.fire_event('ADDON_LOADED', 'SomeOtherAddon')
	eq(ZT.mapLine, nil, "another addon's load hooks nothing")
	stub.fire_event('ADDON_LOADED', 'Blizzard_WorldMap')
	check(ZT.mapLine ~= nil, 'hooked once Blizzard_WorldMap loads')
	set_maps()
	hover(ELWYNN)
	eq(line(), H.colored('Alliance', 'blue'), 'and it works')
	eq(#take_errors(), 0, 'with nothing written onto the map or label')
end)
