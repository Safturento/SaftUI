-- SaftUI-Misc/Skinning/ZoneFactions.lua: the table of which faction holds each
-- zone, by uiMapID, one list per client, and its lookup, ZT:GetZoneFaction,
-- which the world map's zone label reads.
--
-- Real: Core's helpers, Skinning/skinning.lua, ZoneText.lua (the module the
-- table belongs to) and ZoneFactions.lua. Nothing is enabled: the lookup needs
-- no frames.
load_core_helpers()
load_saftui('SaftUI-Misc/Skinning/skinning.lua')
load_saftui('SaftUI-Misc/Skinning/ZoneText.lua')
load_saftui('SaftUI-Misc/Skinning/ZoneFactions.lua')
local st = SaftUI
local ZT = st:GetModule('Skinning'):GetModule('ZoneText')

test('on Forever, starting zones and cities are their faction, contested zones and sanctuaries Neutral', function()
	check(st.forever, 'the stubs are Forever')
	eq(ZT:GetZoneFaction(1429), 'Alliance', 'Elwynn Forest')
	eq(ZT:GetZoneFaction(1453), 'Alliance', 'Stormwind City')
	eq(ZT:GetZoneFaction(1457), 'Alliance', 'Darnassus')
	eq(ZT:GetZoneFaction(1411), 'Horde', 'Durotar')
	eq(ZT:GetZoneFaction(1454), 'Horde', 'Orgrimmar')
	eq(ZT:GetZoneFaction(1458), 'Horde', 'Undercity')
	eq(ZT:GetZoneFaction(1436), 'Alliance', 'Westfall, Alliance territory past the starting zones')
	eq(ZT:GetZoneFaction(1413), 'Horde', 'The Barrens, Horde territory')
	eq(ZT:GetZoneFaction(1434), 'Neutral', 'Stranglethorn Vale, contested')
	eq(ZT:GetZoneFaction(1440), 'Neutral', 'Ashenvale, contested')
	eq(ZT:GetZoneFaction(2548), 'Neutral', "Riverglades, one of Forever's own zones")
	eq(ZT:GetZoneFaction(2521), 'Neutral', 'Zephras Isle, a sanctuary')
end)

test("on retail, retail's IDs, and the capitals and starting zones the game leaves contested", function()
	st.forever = false
	eq(ZT:GetZoneFaction(37), 'Alliance', 'Elwynn Forest')
	eq(ZT:GetZoneFaction(84), 'Alliance', 'Stormwind City')
	eq(ZT:GetZoneFaction(85), 'Horde', 'Orgrimmar')
	eq(ZT:GetZoneFaction(76), 'Horde', 'Azshara, Horde territory since Cataclysm')
	eq(ZT:GetZoneFaction(224), 'Neutral', 'Stranglethorn Vale')
	eq(ZT:GetZoneFaction(1161), 'Alliance', 'Boralus, which the game leaves contested')
	eq(ZT:GetZoneFaction(1165), 'Horde', "Dazar'alor, likewise")
	eq(ZT:GetZoneFaction(179), 'Alliance', 'Gilneas, the worgen starting zone, an orphan map')
	eq(ZT:GetZoneFaction(427), 'Alliance', 'Coldridge Valley, a starting area that is an orphan map')
	eq(ZT:GetZoneFaction(111), 'Neutral', 'Shattrath City, a sanctuary')
	eq(ZT:GetZoneFaction(2112), 'Neutral', 'Valdrakken, a sanctuary')
	eq(ZT:GetZoneFaction(2393), 'Neutral', "Midnight's Silvermoon City, a sanctuary for both factions")
	eq(ZT:GetZoneFaction(110), 'Horde', "the older Silvermoon City, the blood elves' capital")
	eq(ZT:GetZoneFaction(1429), nil, "Forever's Elwynn Forest isn't a retail map")
	st.forever = true
	eq(ZT:GetZoneFaction(37), nil, "and retail's isn't a Forever one")
end)

test('a map the table lacks has no faction', function()
	eq(ZT:GetZoneFaction(1415), nil, 'a continent (Eastern Kingdoms)')
	eq(ZT:GetZoneFaction(947), nil, 'the world (Azeroth)')
	eq(ZT:GetZoneFaction(999999), nil, 'an unknown map')
	eq(ZT:GetZoneFaction(nil), nil, 'no map')
end)

test('each client has its zones, each one Alliance, Horde or Neutral', function()
	local valid = { Alliance = true, Horde = true, Neutral = true }
	local clients = 0
	for client, zones in pairs(ZT.ZONE_FACTIONS) do
		clients = clients + 1
		local count, bad = 0, {}
		for id, word in pairs(zones) do
			count = count + 1
			if type(id) ~= 'number' or not valid[word] then bad[#bad + 1] = tostring(id) .. '=' .. tostring(word) end
		end
		eq(table.concat(bad, ', '), '', client .. ': every entry a uiMapID and one of the three words')
		check(count >= 40, client .. ' lists its zones (' .. count .. ')')
	end
	eq(clients, 2, 'Forever and retail')
end)
