-- SaftUI-Minimap's micro menu bar under the Blizzard theme: every item (the
-- zone, clock, latency, FPS, addon count, expansion, mail, difficulty, queue,
-- search and each micro button) stands on the same box, ThemeArt.LayBox's
-- (the minimap header button's), laid on the item's own panel at the item's
-- rect with its centre. No strip stands under the micro buttons, search keeps
-- the magnifier SaftUI draws, and Thick and Thin put today's boxes back.
--
-- Real: SaftUI-Minimap's minimap.lua, config.lua, micromenu.lua,
-- micromenuart.lua, micromenuitems.lua, micromenuoptions.lua and
-- microbuttons.lua, Core's helpers and the theme engine. Each case starts from
-- a fresh world on a client (T.client), since cases change the profile's theme.
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('lib/locked_widget.lua')

local st, MM, drawn

-- A fresh world on client with the micro menu loaded, its Container a frame at
-- UIParent's top left, as theme_test.lua makes it (OnEnable's is the same).
local function world(client)
	st = T.client(client)
	drawn = T.watch()
	-- Blizzard's minimap, which minimap.lua sizes and places
	CreateFrame('Frame', 'Minimap', UIParent)
	load_saftui('SaftUI-Minimap/minimap.lua')
	load_saftui('SaftUI-Minimap/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Minimap/micromenu.lua')
	load_saftui('SaftUI-Minimap/micromenuart.lua')
	load_saftui('SaftUI-Minimap/micromenuitems.lua')
	load_saftui('SaftUI-Minimap/micromenuoptions.lua')
	load_saftui('SaftUI-Minimap/microbuttons.lua')
	MM = st:GetModule('MicroMenu')
	st:BindModuleConfig(MM, 'micromenu')
	MM.Container = CreateFrame('Frame', nil, UIParent)
	MM.Container:SetPoint('TOPLEFT')
end

-- A switch to the theme name, as Config:UpdateConfig runs it: every drawn frame
-- redrawn, then the bar laid out again.
local function theme(name)
	T.theme(name, function() MM:UpdateButtons() end)
end

-- A bar item: a Button of UIParent's, added with options.
local function item(options)
	local button = CreateFrame('Button', nil, UIParent)
	MM:AddButton(button, options)
	return button
end

-- The item's panel: its child the theme drew.
local function panel(button)
	for _, child in ipairs({ button:GetChildren() }) do
		if drawn(child) then return child end
	end
end

-- How many of a set of pieces show.
local function shown(pieces)
	local n = 0
	for _, piece in pairs(pieces or {}) do
		if piece:IsShown() then n = n + 1 end
	end
	return n
end

-- A micro button as Blizzard's MainMenuBarMicroButton template builds it,
-- copied from theme_test.lua (which says what it models), hung on MicroMenu.
-- The button is locked, so a field the skin writes onto it fails.
local function micro_button(index, textureName)
	local menu = _G.MicroMenu
	local button = CreateFrame('Button', nil, menu)
	button.layoutIndex, button.textureName = index, textureName
	button.Background = button:CreateTexture(nil, 'BACKGROUND')
	button.Background:SetAtlas('UI-HUD-MicroMenu-ButtonBG-Up', true)
	button.Background:SetPoint('CENTER')
	button.PushedBackground = button:CreateTexture(nil, 'BACKGROUND')
	button.PushedBackground:SetAtlas('UI-HUD-MicroMenu-ButtonBG-Down', true)
	button.PushedBackground:SetPoint('CENTER')
	button.PushedBackground:Hide()
	button.FlashBorder = button:CreateTexture(nil, 'OVERLAY')
	button.FlashBorder:SetAtlas('UI-HUD-MicroMenu-Highlightalert')
	button.FlashBorder:SetAllPoints(button)
	button.FlashBorder:Hide()
	button.Shadow = button:CreateTexture(nil, 'BORDER')
	button.PushedShadow = button:CreateTexture(nil, 'OVERLAY')
	button.MainMenuBarPerformanceBar = button:CreateTexture(nil, 'ARTWORK')
	button.Emblem = button:CreateTexture(nil, 'ARTWORK')
	button.HighlightEmblem = button:CreateTexture(nil, 'ARTWORK')
	button.NotificationOverlay = CreateFrame('Frame', nil, button)
	button.NotificationOverlay:CreateTexture(nil, 'OVERLAY')
	button:SetNormalTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetPushedTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetHighlightTexture(button:CreateTexture(nil, 'HIGHLIGHT'))
	button.SetHighlightAtlas = function(self, atlas, blend)
		local highlight = self:GetHighlightTexture()
		highlight:SetAtlas(atlas)
		highlight:SetBlendMode(blend or 'BLEND')
	end
	return locked(button, 'Blizzard micro button')
end

-- The items a bar has: text items, square ones, a search with its own
-- magnifier, and micro button holders (Blizzard's micro buttons' own panels
-- are the buttons', so the holders are theme 'none' items under Thick).
local function bar()
	local items = {
		zone = item({ key = 'zone', width = 200, text = UIParent:CreateFontString() }),
		clock = item({ key = 'clock', width = 60 }),
		latency = item({ width = 48 }),
		mail = item({ key = 'mail' }),
	}
	-- Real micro buttons, which SkinBlizzardMicroMenu gives a holder each
	local menu = _G.MicroMenu or CreateFrame('Frame', 'MicroMenu', UIParent)
	function menu:Layout() end
	local character, spells = micro_button(1, 'CharacterMicroButton'), micro_button(2, 'SpellbookMicroButton')
	MM:SkinBlizzardMicroMenu()
	MM:UpdateButtons() -- the holders take their places
	items.micro_character = select(2, character:GetPoint(1))
	items.micro_spells = select(2, spells:GetPoint(1))
	local search = CreateFrame('Button', nil, UIParent)
	local magnifier = search:CreateTexture(); MM:AddButton(search, { key = 'search', icon = magnifier })
	items.search = search
	return items, magnifier
end

-- The box pieces of an item (laid on its panel), by key.
local function box_of(button)
	return MM:GetItemBox(button)
end

local EIGHT = { 'BottomEdge', 'BottomLeftCorner', 'BottomRightCorner', 'LeftEdge', 'RightEdge', 'TopEdge', 'TopLeftCorner', 'TopRightCorner' }

test('every item stands on the same box, at the bar height: the default and the setting\'s ends', function()
	world('forever')
	local items = bar()
	theme('blizzard')
	for _, height in ipairs({ 25, 16, 48 }) do
		st.config.profile.micromenu.height = height
		MM:UpdateConfig()
		eq(MM:BarHeight(), height)
		for name, button in pairs(items) do
			local where = name .. ' at ' .. height
			local pieces = box_of(button)
			check(pieces, where .. ': has a box')
			eq(T.around(panel(button), button), '0,0,0,0', where .. ": the panel is the item's rect")
			eq(drawn(panel(button)), 'theme,theme,control', where)
			eq(panel(button).backdropInfo, nil, where .. ': no fill or line of its own')
			for _, key in ipairs(EIGHT) do
				check(pieces[key] and pieces[key]:IsShown(), where .. ': ' .. key .. ' shows')
				eq(pieces[key]:GetParent(), panel(button), where .. ': on the panel')
			end
			check(pieces.Center and pieces.Center:IsShown(), where .. ': the centre shows')
			local info = C_Texture.GetAtlasInfo('ui-hud-minimap-header-button')
			eq(pieces.TopLeftCorner:GetTexture(), 8026705, where .. ': a cut of the header button file')
			eq(pieces.TopLeftCorner:GetWidth() .. 'x' .. pieces.TopLeftCorner:GetHeight(), '6x6', where .. ': 6px corners whole')
			local top, bottom = pieces.TopLeftCorner:GetTop(), pieces.BottomLeftCorner:GetBottom()
			eq(top - bottom, height, where .. ": the box is the bar's height")
			eq(pieces.TopLeftCorner:GetLeft(), button:GetLeft(), where .. ": from the item's left")
			eq(pieces.TopRightCorner:GetRight(), button:GetRight(), where .. ": to the item's right")
			check(pieces.LeftEdge:GetHeight() > 0, where .. ': the side edges a positive length')
			check(pieces.TopEdge:GetWidth() > 0, where .. ': the top edge a positive length')
		end
	end
end)

test('a turned-off item draws no box', function()
	world('forever')
	local items = bar()
	theme('blizzard')
	local show = st.config.profile.micromenu.show
	show.micro_button1 = false; show.zone = false
	MM:UpdateConfig()
	for _, name in ipairs({ 'micro_character', 'zone' }) do
		eq(items[name]:GetAlpha(), 0, name .. ': concealed')
		eq(box_of(items[name]).TopLeftCorner:GetEffectiveAlpha(), 0, name .. ': no box piece is visible')
	end
	check(shown(box_of(items.clock)) > 0, 'the others keep theirs')
end)

test("no fill outside the box, no strip under the micro buttons", function()
	world('forever')
	local items = bar()
	theme('blizzard')
	for name, button in pairs(items) do
		local p = panel(button)
		check(p.backdropInfo == nil or select(4, p:GetBackdropColor()) == 0, name .. ': the panel has no fill')
	end
	eq(MM.GetStrip, nil, 'there is no strip')
	local named = 0
	for _, child in ipairs({ MM.Container:GetChildren() }) do
		for _, region in ipairs({ child:GetRegions() }) do
			local atlas = region.GetAtlas and region:GetAtlas()
			if region:IsShown() and atlas and atlas:lower() == 'ui-hud-actionbar-frame' then named = named + 1 end
		end
	end
	eq(named, 0, 'no ui-hud-actionbar-frame shows')
end)

test('search keeps its magnifier under Blizzard', function()
	world('forever')
	local items, magnifier = bar()
	theme('blizzard')
	check(magnifier:IsShown(), 'shown on Forever')
	theme('thick'); check(magnifier:IsShown())
	theme('blizzard'); check(magnifier:IsShown(), 'and back')
end)

test('retail draws the kit on every item', function()
	world('retail')
	local items, magnifier = bar()
	theme('blizzard')
	for name, button in pairs(items) do
		local pieces = box_of(button)
		eq(pieces.TopLeftCorner:GetAtlas(), 'ui-hud-minimap-button-NineSlice-CornerTopLeft', name)
		eq(pieces.Center:GetAtlas(), 'ui-hud-minimap-button-NineSlice-Center', name)
		check(pieces.Center:IsShown(), name .. ': with its centre')
	end
	check(magnifier:IsShown())
end)

test("Thick and Thin draw no box, and the micro menu reads as on modular", function()
	world('forever')
	local items = bar()
	theme('blizzard')
	theme('thick')
	for name, button in pairs(items) do
		eq(shown(box_of(button)), 0, name .. ': no piece shows under Thick')
		if button ~= items.micro_character and button ~= items.micro_spells then
			eq(T.inset(panel(button)), 2, name .. ": today's small frame")
		end
	end
	theme('thin')
	for name, button in pairs(items) do eq(shown(box_of(button)), 0, name .. ': nor under Thin') end
end)

------------------------------------ Blizzard's micro menu

-- A region's points as text, to tell whether anything moved it.
local function points(region)
	local out = {}
	for i = 1, region:GetNumPoints() do
		local point, relativeTo, relativePoint, x, y = region:GetPoint(i)
		out[i] = ('%s,%s,%s,%s'):format(point, tostring(relativeTo), relativePoint, T.text(x, y))
	end
	return table.concat(out, ';')
end

test("nothing of Blizzard's micro menu is shown, moved or written onto", function()
	world('forever')
	-- Camelot's MicroMenu (Blizzard_MicroMenu/Camelot/MainMenuBarMicroMenu.xml):
	-- its frame art around the whole menu, which the skin fades for good.
	local menu = CreateFrame('Frame', 'MicroMenu', UIParent)
	function menu:Layout() end -- Blizzard's layout, which the skin hooks
	menu:SetPoint('BOTTOMRIGHT', -10, 10); menu:SetSize(100, 40)
	menu.BorderArt = menu:CreateTexture(nil, 'BACKGROUND', nil, -3)
	menu.BorderArt:SetAtlas('UI-HUD-ActionBar-Frame')
	menu.BorderArt:SetPoint('TOPLEFT', -8, 8); menu.BorderArt:SetPoint('BOTTOMRIGHT', 8, -8)
	menu.BackgroundArt = menu:CreateTexture(nil, 'BACKGROUND', nil, -3)
	menu.BackgroundArt:SetAtlas('UI-HUD-ActionBar-IconFrame-Background')
	menu.BackgroundArt:SetPoint('TOPLEFT', menu.BorderArt, 'TOPLEFT', -13, 0)
	menu.BackgroundArt:SetPoint('BOTTOMRIGHT', menu.BorderArt, 'BOTTOMRIGHT', 14, 4)
	local button = micro_button(1, 'Questlog')
	locked(menu, 'Blizzard micro menu')
	local before = points(menu.BorderArt) .. '|' .. points(menu.BackgroundArt)

	MM:SkinBlizzardMicroMenu()
	theme('blizzard')
	eq(menu.BorderArt:GetAlpha(), 0, "Blizzard's frame art stays faded"); eq(menu.BackgroundArt:GetAlpha(), 0)
	eq(points(menu.BorderArt) .. '|' .. points(menu.BackgroundArt), before, 'and unmoved')
	eq(menu.BorderArt:GetAtlas(), 'UI-HUD-ActionBar-Frame', 'and as Blizzard set it')
	local holder = select(2, button:GetPoint(1))
	local backdrop = panel(holder)
	check(backdrop and backdrop:IsShown(), "the holder's panel of SaftUI shows, with the box on it")
	eq(T.around(backdrop, holder), '0,0,0,0', "on the holder's rect")
	check(backdrop:GetFrameLevel() < holder:GetFrameLevel() + 1, "under the holder's level: Blizzard's button art stays above")
	theme('thick')
	eq(shown(MM:GetItemBox(holder)), 0, 'no box under Thick'); eq(menu.BorderArt:GetAlpha(), 0)
end)
