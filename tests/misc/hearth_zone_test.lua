-- SaftUI-Misc/hearthzone.lua: the zone the hearthstone is bound to, learned per
-- character and shown as one line on the hearth's item tooltip.
--   - learned on HEARTHSTONE_BOUND (the zone the player stands in), and on the
--     zone events while the player stands in the bind's own area (its subzone
--     or minimap zone text), so a bind made before learns on the next hearth;
--   - kept only for the bind it was learned for;
--   - the line, "Zone: <zone>", on any item tooltip whose lines name the bind,
--     or the Hearthstone's own; a "not known yet" line before it is learned;
--     nothing when the bind's name is its zone, or for another item;
--   - a secret value is never compared or shown.
-- Real: Core's helpers and hearthzone.lua. The zone APIs and
-- TooltipDataProcessor are the test's stand-ins.
local S = load_test_file('lib/secrets.lua')
local HZ, post, toy_post

local place -- what the zone APIs return now

local function world()
	use_client('forever')
	load_core_helpers()
	st = SaftUI
	st.config.char = {}
	place = { bind = "Lion's Pride Inn", zone = 'Elwynn Forest', sub = 'Goldshire', minimap = 'Goldshire' }
	GetBindLocation = function() return place.bind end
	GetRealZoneText = function() return place.zone end
	GetSubZoneText = function() return place.sub end
	GetMinimapZoneText = function() return place.minimap end
	Enum.TooltipDataType = { Item = 0, Toy = 19 }
	post, toy_post = nil, nil
	_G.TooltipDataProcessor = {
		AddTooltipPostCall = function(kind, fn)
			if kind == Enum.TooltipDataType.Item then post = fn end
			if kind == Enum.TooltipDataType.Toy then toy_post = fn end
		end,
	}
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end
	load_saftui('SaftUI-Misc/hearthzone.lua')
	HZ = st:GetModule('HearthZone')
	HZ:Enable()
end

local function clean() eq(#take_errors(), 0, 'no errors') end

local function hearth_data(bind)
	return { id = 6948, lines = {
		{ leftText = 'Hearthstone' },
		{ leftText = 'Use: Returns you to ' .. (bind or place.bind) .. '. Speak to an Innkeeper in a different place to change your home location.' },
	} }
end

-- The tooltip's lines after the post-call, from a fresh tooltip.
local function shown(data)
	GameTooltip:ClearLines()
	GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	GameTooltip:SetText('Hearthstone')
	post(GameTooltip, data)
	local s = stub.state(GameTooltip)
	local out = {}
	for i = 2, s.lines or 0 do out[#out + 1] = s.texts[i] end
	return out
end

test('binding learns the zone, and the hearthstone shows it', function()
	world()
	check(post, 'the post-call is registered for items')
	place.sub = 'Lion\'s Pride Inn'
	stub.fire_event('HEARTHSTONE_BOUND')
	eq(st.config.char.hearth.location, "Lion's Pride Inn", 'the bind')
	eq(st.config.char.hearth.zone, 'Elwynn Forest', 'its zone')
	eq(shown(hearth_data())[1], 'Zone: Elwynn Forest', 'the line')
	clean()
end)

test('before it is learned the line says how it will be', function()
	world()
	eq(shown(hearth_data())[1], 'Zone: not known yet. Hearth there once to learn it.', 'not known')
	clean()
end)

test('a bind made before learns its zone once the player stands in the inn', function()
	world()
	place.zone, place.sub, place.minimap = 'Stormwind City', 'Trade District', 'Trade District'
	stub.fire_event('ZONE_CHANGED')
	eq(HZ:Zone(), nil, 'not learned elsewhere')
	place.zone, place.sub, place.minimap = 'Elwynn Forest', 'Goldshire', "Lion's Pride Inn"
	stub.fire_event('ZONE_CHANGED_INDOORS')
	eq(HZ:Zone(), 'Elwynn Forest', 'by the minimap zone text')
	st.config.char.hearth = nil
	place.minimap, place.sub = 'Goldshire', "Lion's Pride Inn"
	stub.fire_event('ZONE_CHANGED')
	eq(HZ:Zone(), 'Elwynn Forest', 'by the subzone text')
	clean()
end)

test('a zone learned for another bind does not count', function()
	world()
	st.config.char.hearth = { location = 'Stoutlager Inn', zone = 'Loch Modan' }
	eq(HZ:Zone(), nil, 'stale')
	eq(shown(hearth_data())[1], 'Zone: not known yet. Hearth there once to learn it.', 'not the old zone')
	clean()
end)

test('any item that names the bind gets the line; others and city binds do not', function()
	world()
	st.config.char.hearth = { location = "Lion's Pride Inn", zone = 'Elwynn Forest' }
	local toy = { id = 1234, lines = { { leftText = 'Toy' }, { leftText = "Use: Returns you to Lion's Pride Inn." } } }
	eq(shown(toy)[1], 'Zone: Elwynn Forest', 'an item whose Use: line names the bind')
	eq(toy_post, post, 'toy tooltips take the same post-call')
	eq(#shown({ id = 5, lines = { { leftText = 'Quest item' }, { leftText = "Bring it to Lion's Pride Inn." } } }), 0,
		'a line that only mentions the bind')
	eq(#shown({ id = 2589, lines = { { leftText = 'Linen Cloth' } } }), 0, 'another item')
	eq(#shown(nil), 0, 'no data')
	place.bind, place.zone = 'Stormwind City', 'Stormwind City'
	st.config.char.hearth = { location = 'Stormwind City', zone = 'Stormwind City' }
	eq(#shown(hearth_data()), 0, 'the bind is its zone')
	-- A city bind arriving in the city's inn subzone: learned by the zone's name.
	st.config.char.hearth = nil
	place.bind, place.zone, place.sub, place.minimap = 'Orgrimmar', 'Orgrimmar', 'Valley of Strength', 'Valley of Strength'
	stub.fire_event('ZONE_CHANGED_NEW_AREA')
	eq(HZ:Zone(), 'Orgrimmar', 'learned in the city')
	eq(#shown(hearth_data()), 0, 'and no not-known line')
	clean()
end)

test('secret values are never compared or shown', function()
	world()
	place.bind = S.secret("Lion's Pride Inn")
	stub.fire_event('HEARTHSTONE_BOUND')
	eq(st.config.char.hearth, nil, 'a secret bind is not learned')
	eq(#shown(hearth_data("Lion's Pride Inn")), 0, 'and no line')
	place.bind = "Lion's Pride Inn"
	place.zone = S.secret('Elwynn Forest')
	stub.fire_event('HEARTHSTONE_BOUND')
	eq(HZ:Zone(), nil, 'a secret zone is not learned')
	local data = hearth_data()
	data.id = S.secret(6948)
	data.lines[2].leftText = S.secret(data.lines[2].leftText)
	eq(#shown(data), 0, 'a secret id or line is not read')
	clean()
end)

test('without TooltipDataProcessor nothing is hooked', function()
	world()
	HZ.tooltipPostCall = nil
	_G.TooltipDataProcessor = nil
	eq(HZ:HookTooltips(), false, 'not hooked')
	clean()
end)
