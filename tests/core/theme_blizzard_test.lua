-- The Blizzard theme's looks (SaftUI-Core/themeart.lua, and theme.lua's
-- resolution):
--   - Blizzard resolving its name, colors and alpha by the same rules as Thick
--     and Thin, with each kind's inset on each client (st:ResolveTheme and
--     st:ThemeInset take the kind), the metal's title bar and the close
--     button's size;
--   - Thick's and Thin's insets ignoring the kind, and the window and control
--     kinds drawing as a panel and a small frame under them;
--   - the Blizzard theme's default colors, and no default naming Blizzard;
--   - st:IsBlizzardLook, st.ThemeArt.ClassPower, and every atlas the theme
--     names existing on both clients (C_Texture.GetAtlasInfo answers from
--     tests/wow/atlases.lua, the clients' atlas tables);
--   - a saved theme this version doesn't know still reading as Thick.
--
-- Real: theme.lua and themeart.lua, with Core's helpers (load_core_helpers)
-- and the profile's defaults. Each case starts from a fresh world on a client
-- (T.client), since cases change the profile's theme.
local T = load_test_file('lib/theme_helpers.lua')
local text, fill, edge, inset, offset = T.text, T.fill, T.edge, T.inset, T.offset

-- Every kind, and its starting inset under Blizzard (the same on both clients
-- until they're measured in game).
local BLIZZARD_INSETS = {
	panel = 3, window = 2, bar = 3, action = 3, slot = 3, aura = 0,
	tooltip = 3, header = 0, close = 0, control = 0, small = 1,
}

local CLIENTS = { 'forever', 'retail' }

local function frame(st)
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(100, 50)
	f:SetPoint('CENTER')
	return f
end

-- Whether Thick's outer lines (the dark ones either side of the border) show.
local function outerShown(f)
	if not f.altborder then return false end
	for _, line in pairs(f.altborder) do
		if not line:IsShown() then return false end
	end
	return true
end

test('T.client gives a fresh world on each client, one after the other', function()
	local st = T.client('retail')
	check(not st.forever and st.retail, 'retail: st.forever off, st.retail on')
	eq(select(4, GetBuildInfo()), 120000, "retail: the game's interface")
	eq(st.ThemeArt and st.ThemeArt.Client(), 'live', "retail: the theme's client is live")
	st.config.profile.theme.name = 'thin'

	st = T.client('forever')
	check(st.forever and st.retail, 'forever: st.forever on (it counts as retail too)')
	eq(select(4, GetBuildInfo()), 16001, "forever: the game's interface")
	eq(st.ThemeArt and st.ThemeArt.Client(), 'forever', "forever: the theme's client")
	eq(st.config.profile.theme.name, 'thick', 'the profile is fresh: the theme is the default again')
	check(st.config.profile.templates.thick ~= nil, 'and filled from the defaults')

	local ok = pcall(T.client, 'classic')
	check(not ok, 'a client that is neither is an error')
end)

test('Blizzard resolves like Thick and Thin', function()
	local st = T.client('forever')
	local profile = st.config.profile
	profile.theme.name = 'blizzard'

	local look = st:ResolveTheme('theme', 'theme', 'tooltip')
	eq(look.name, 'blizzard', 'name')
	eq(look.alpha, 0.9, "the profile's Transparent background at its Opacity")
	eq(look.inset, 3, "the tooltip kind's inset")
	eq(look.kind, 'tooltip', 'the look names its kind')
	check(look.colors == profile.templates.blizzard, "the colors are the profile's Blizzard colors")
	eq(st:ResolveTheme('theme', 'solid', 'tooltip').alpha, 1, 'a Solid background is opaque')
	eq(st:ResolveTheme('none', 'theme', 'tooltip'), nil, 'None draws nothing')
	eq(st:ResolveTheme('thick', 'theme', 'tooltip').inset, 2, 'an override to Thick is Thick')
	eq(st:ResolveTheme('blizzard', 'theme', 'window').inset, 2, 'an override that names Blizzard')
	eq(st:ResolveTheme('theme', 'theme').inset, nil, 'with no kind, a Blizzard look has no inset')
	eq(st:ResolveTheme().name, 'blizzard', 'no arguments follow the theme')

	profile.theme.name = 'thick'
	look = st:ResolveTheme('blizzard', 'transparent', 'window')
	eq(look and look.name, 'blizzard', 'an override names Blizzard while the theme is Thick')
	eq(look and look.inset, 2, "and has the window's inset")
	check(look and look.colors == profile.templates.blizzard, "and Blizzard's colors")
	eq(st:ResolveTheme('theme', 'theme', 'window').inset, 2, "Thick's inset, whatever the kind")
end)

test("each kind's inset under Blizzard, on Forever and on retail", function()
	for _, client in ipairs(CLIENTS) do
		local st = T.client(client)
		local count = 0
		for kind in pairs(st.THEME_KINDS) do
			count = count + 1
			check(BLIZZARD_INSETS[kind] ~= nil, client .. ': ' .. kind .. ' is one of the eleven kinds')
		end
		eq(count, 11, client .. ': eleven kinds')
		for kind, want in pairs(BLIZZARD_INSETS) do
			eq(st:ThemeInset('blizzard', 'theme', kind), want, client .. ': ' .. kind)
			eq(st.ThemeArt.Inset(kind), want, client .. ': ThemeArt.Inset ' .. kind)
			eq(st:ThemeInset('none', 'theme', kind), 0, client .. ': None, ' .. kind)
		end

		local forever = client == 'forever'
		eq(st.ThemeArt.TitleHeight(), forever and 20 or 21, client .. ": the metal's title bar")
		local close = st.ThemeArt.Close()
		eq(close.size, forever and 28 or 24, client .. ": the close button's size")
		eq(text(close.x, close.y), forever and '0.00,3.00' or '1.00,0.00', client .. ': its spot on a window')
		eq(table.concat({ close.normal, close.pushed, close.highlight, close.disabled }, ','),
			'RedButton-Exit,RedButton-exit-pressed,RedButton-Highlight,RedButton-Exit-Disabled',
			client .. ': its four textures')
	end
end)

test('Thick and Thin insets ignore the kind', function()
	local st = T.client('forever')
	for kind in pairs(BLIZZARD_INSETS) do
		eq(st:ThemeInset('thick', 'theme', kind), 2, 'Thick, ' .. kind)
		eq(st:ThemeInset('thin', 'theme', kind), 1, 'Thin, ' .. kind)
	end
end)

test('st:ThemeInset with no kind is an error', function()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		local st = T.client('forever')
		st.config.profile.theme.name = name
		check(not pcall(st.ThemeInset, st, 'theme', 'theme'), name .. ': no kind is an error')
		check(not pcall(st.ThemeInset, st, name), name .. ': named, no kind, is an error')
		check(not pcall(st.ThemeInset, st, 'theme', 'theme', 'nonsense'), name .. ': not a kind is an error')
		eq(st:ThemeInset('none', 'theme'), 0, name .. ': None needs no kind')
		eq(st:ThemeInset('none'), 0, name .. ': None with no Background')
	end
end)

test('a window draws as a panel, and a control as a small frame, under Thick and Thin', function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		local st = T.client('forever')
		st.config.profile.theme.name = name
		for _, pair in ipairs({ { 'window', 'panel' }, { 'control', 'small' } }) do
			local a, b = frame(st), frame(st)
			local ok, err = pcall(function()
				st:SetBackdrop(a, 'theme', 'theme', pair[1])
				st:SetBackdrop(b, 'theme', 'theme', pair[2])
			end)
			local where = name .. ': ' .. pair[1] .. ' as ' .. pair[2]
			check(ok, where .. ' draws: ' .. tostring(err))
			if ok then
				eq(fill(a.backdrop), fill(b.backdrop), where .. ': fill')
				eq(edge(a.backdrop), edge(b.backdrop), where .. ': border')
				eq(inset(a.backdrop), inset(b.backdrop), where .. ': inset')
				eq(offset(a.backdrop, 'TOPLEFT'), offset(b.backdrop, 'TOPLEFT'), where .. ': where the backdrop sits')
				eq(outerShown(a.backdrop), outerShown(b.backdrop), where .. ": Thick's outer lines")
			end
		end
	end
end)

test("the Blizzard theme's default colors", function()
	local st = T.client('forever')
	local blizzard = st.defaults.templates.blizzard
	check(blizzard ~= nil, 'templates.blizzard')
	if not blizzard then return end
	local function rgba(c) return c and text(unpack(c)) end
	eq(rgba(blizzard.bordercolor), '0.50,0.50,0.50,1.00', 'Border')
	eq(rgba(blizzard.altbordercolor), '0.00,0.00,0.00,0.00', 'Outer border, unused')
	-- Dark grey everywhere (the user, 2026-11-11): both fills start as
	-- Blizzard's dark grey panel color, and stay two settings.
	eq(rgba(blizzard.backdropcolor), '0.12,0.12,0.13,1.00', "Background: Blizzard's dark grey")
	eq(rgba(blizzard.windowcolor), '0.12,0.12,0.13,1.00', "Window background: Blizzard's dark grey")
	check(blizzard.backdropcolor ~= blizzard.windowcolor, 'two arrays, so either can be set alone')
	eq(rgba(st.config.profile.templates.blizzard.backdropcolor), '0.12,0.12,0.13,1.00', 'the profile has the grey Background')
	local keys = {}
	for key in pairs(blizzard) do keys[#keys + 1] = key end
	table.sort(keys)
	eq(table.concat(keys, ','), 'altbordercolor,backdropcolor,bordercolor,windowcolor', 'those four and no others')
	eq(st.defaults.templates.thick.windowcolor, nil, 'Thick has no Window background')
	eq(st.defaults.templates.thin.windowcolor, nil, 'Thin has no Window background')
	eq(rgba(st.config.profile.templates.blizzard.windowcolor), '0.12,0.12,0.13,1.00', 'the profile has them')
end)

test('IsBlizzardLook', function()
	local st = T.client('forever')
	local profile = st.config.profile
	profile.theme.name = 'blizzard'
	eq(st:IsBlizzardLook('theme', 'theme'), true, "SaftUI's theme Blizzard")
	eq(st:IsBlizzardLook('none', 'theme'), false, 'None under Blizzard')
	eq(st:IsBlizzardLook('thin', 'theme'), false, 'an override to Thin under Blizzard')
	profile.theme.name = 'thick'
	eq(st:IsBlizzardLook('blizzard', 'solid'), true, 'an override to Blizzard under Thick')
	eq(st:IsBlizzardLook('theme', 'theme'), false, "SaftUI's theme Thick")
	eq(st:IsBlizzardLook('none', 'theme'), false, 'None under Thick')
end)

test("ClassPower names each resource's art", function()
	local st = T.client('retail')
	local A = st.ThemeArt
	local function art(...) return table.concat({ tostring((A.ClassPower(...))), tostring((select(2, A.ClassPower(...)))) }, ',') end
	eq(art('COMBO_POINTS', 2, 'ROGUE'), 'uf-roguecp-bg,uf-roguecp-icon-red', "a rogue's combo point")
	eq(art('COMBO_POINTS', 2, 'ROGUE', true), 'uf-roguecp-bg,uf-roguecp-icon-blue', "a rogue's charged point")
	eq(art('COMBO_POINTS', 1, 'DRUID'), 'UF-DruidCP-BG-Active,UF-DruidCP-Icon', "a druid's combo point")
	eq(art('HOLY_POWER', 3, 'PALADIN'), 'uf-holypower-rune3,uf-holypower-rune3-active', 'holy power: a rune for each point')
	eq(art('HOLY_POWER', 5, 'PALADIN'), 'uf-holypower-rune5,uf-holypower-rune5-active', 'the fifth rune')
	eq(art('SOUL_SHARDS', 1, 'WARLOCK'), 'UF-SoulShard-Holder,UF-SoulShard-Icon', 'soul shards')
	eq(art('CHI', 4, 'MONK'), 'uf-chi-bg,uf-chi-icon', 'chi')
	eq(art('ARCANE_CHARGES', 2, 'MAGE'), 'UF-Arcane-BG,UF-Arcane-Icon', 'arcane charges')
	eq(art('ESSENCE', 5, 'EVOKER'), 'UF-Essence-BG,UF-Essence-Icon', 'essence')
	eq(A.ClassPower('RUNES', 1, 'DEATHKNIGHT'), nil, 'runes have no art')
	eq(A.ClassPower('HOLY_POWER', nil, 'PALADIN'), nil, 'no point, no art')
end)

test('no default names Blizzard', function()
	local st = T.client('forever')
	eq(st.defaults.theme.name, 'thick', "SaftUI's theme stays Thick")
	local found, seen = {}, {}
	local function walk(t, path)
		if seen[t] then return end
		seen[t] = true
		for key, value in pairs(t) do
			local here = path .. '.' .. tostring(key)
			if value == 'blizzard' then found[#found + 1] = here end
			if type(value) == 'table' then walk(value, here) end
		end
	end
	walk(st.defaults, 'defaults')
	eq(table.concat(found, ', '), '', "no default's value is 'blizzard'")
end)

test('every atlas the theme names exists on both clients', function()
	for _, client in ipairs(CLIENTS) do
		local st = T.client(client)
		local names = st:ThemeAtlases()
		local count, missing, odd = 0, {}, {}
		for name, value in pairs(names) do
			count = count + 1
			if value ~= true then odd[#odd + 1] = name .. ' is not true' end
			if name:find('\\', 1, true) then odd[#odd + 1] = name .. ' is a file' end
			if name:find('%', 1, true) then odd[#odd + 1] = name .. ' is a format' end
			if not C_Texture.GetAtlasInfo(name) then missing[#missing + 1] = name end
		end
		table.sort(missing)
		eq(table.concat(missing, ', '), '', client .. ': every atlas exists')
		eq(table.concat(odd, ', '), '', client .. ': names only, of atlases')
		check(count >= 100, client .. ': at least 100 names, got ' .. count)
		for _, name in ipairs({
			'editmode-actionbar-highlight-NineSlice-Corner', 'editmode-actionbar-selected-NineSlice-Corner',
			'_editmode-actionbar-selected-NineSlice-EdgeTop', 'editmode-actionbar-selected-NineSlice-Center',
			'uf-holypower-rune1', 'uf-holypower-rune5-active', 'UI-HUD-ActionBar-IconFrame-Border',
			'checkbox-minimal', 'RedButton-Exit-Disabled', '!UI-Frame-Metal-EdgeRight',
		}) do
			check(names[name], client .. ': names ' .. name)
		end
	end
end)

test("the atlas stub answers each client's table, ignoring case", function()
	local st = T.client('forever')
	local info = C_Texture.GetAtlasInfo('UI-Frame-Metal-CornerTopLeft')
	eq(info and text(info.width, info.height), '95.00,95.00', "Forever's Camelot metal corner")
	info = C_Texture.GetAtlasInfo('_UI-Frame-Metal-EdgeTop')
	check(info and info.tilesHorizontally and not info.tilesVertically, 'the top edge tiles across')
	info = C_Texture.GetAtlasInfo('UF-HolyPower-Rune3')
	check(info ~= nil, "a name in another case (the atlas table's own)")
	eq(C_Texture.GetAtlasInfo('no-such-atlas'), nil, 'an unknown name')

	st = T.client('retail')
	info = C_Texture.GetAtlasInfo('UI-Frame-Metal-CornerTopLeft')
	eq(info and text(info.width, info.height), '75.00,75.00', "retail's metal corner")
	info = C_Texture.GetAtlasInfo('!Tooltip-NineSlice-EdgeLeft')
	check(info and info.tilesVertically and not info.tilesHorizontally, 'a side edge tiles down')
end)

-- A profile a later version saved can name a theme this one doesn't have. It
-- reads as Thick, so every frame still draws; Blizzard is now a theme of this
-- version's.
test("an unknown saved theme still reads as Thick, and Blizzard is known", function()
	local st = T.client('forever')
	local profile = st.config.profile
	profile.theme.name = 'later'
	local look = st:ResolveTheme('theme', 'theme', 'panel')
	eq(look and look.name, 'thick', 'an unknown theme reads as Thick')
	eq(look and look.inset, 2, "with Thick's inset")
	eq(st:IsBlizzardLook('theme', 'theme'), false, 'and is not Blizzard')
	profile.theme.name = 'blizzard'
	eq(st:ResolveTheme('theme', 'theme', 'panel').name, 'blizzard', 'Blizzard reads as Blizzard')
	eq(profile.theme.name, 'blizzard', 'the saved name is kept')
end)
