-- SaftUI-Minimap's micro menu bar under the Blizzard theme
-- (st.ThemeArt.Control('microbar')):
--   - on Forever the zone, clock, latency and FPS boxes stand on Camelot's
--     header button, the square items on its addon indicator and search on its
--     tracking button, whose magnifier is drawn in, so SaftUI's hides; each
--     drawn at its own height, centred in the 25 tall row, on the item's panel;
--   - on retail every box takes the grey minimap button kit, and SaftUI's
--     magnifier stays;
--   - on Forever the micro buttons stand on one bronze strip of SaftUI's, from
--     the first shown holder to the last, which follows Blizzard showing and
--     hiding them (in combat too) and goes when none shows; retail has none;
--   - Thick puts today's boxes back, and nothing of Blizzard's micro menu is
--     shown, moved or written onto.
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
	MM.Container = CreateFrame('Frame', nil, UIParent)
	MM.Container:SetPoint('TOPLEFT')
end

-- A switch to the theme name, as Config:UpdateConfig runs it: every drawn frame
-- redrawn, then the bar laid out again.
local function theme(name)
	st.config.profile.theme.name = name
	st:RedrawThemed()
	MM:UpdateButtons()
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

test("Forever under Blizzard: the zone, clock, latency and FPS boxes on the header button, the square items on the addon indicator, search on Blizzard's tracking button; Thick puts today's boxes back", function()
	world('forever')
	local zone, fps = item({ width = 200, art = 'header' }), item({ width = 48, art = 'header' })
	local square, search = item(), CreateFrame('Button', nil, UIParent)
	local magnifier = search:CreateTexture(); MM:AddButton(search, { art = 'tracking', icon = magnifier })
	MM:SkinBarButton(zone) -- its flat hover
	theme('blizzard')
	local z = MM:GetItemArt(zone)
	eq(z:GetAtlas(), 'ui-hud-minimap-header-button'); eq(T.around(z, zone), '0,-1,0,1', 'its 23 centred on the 25 row, the box wide')
	eq(T.around(MM:GetItemArt(fps), fps), '0,-1,0,1')
	local s = MM:GetItemArt(square); eq(s:GetAtlas(), 'ui-hud-minimap-addon-indicator'); eq(T.around(s, square), '1,-1,-1,2')
	local t = MM:GetItemArt(search); eq(t:GetAtlas(), 'ui-hud-minimap-tracking-button'); eq(T.around(t, search), '1,-1,-1,1')
	check(z:IsShown() and s:IsShown() and t:IsShown(), 'each shows')
	eq(select(1, z:GetDrawLayer()), 'ARTWORK')
	check(not magnifier:IsShown(), "SaftUI's magnifier hidden: Blizzard's is drawn in")
	eq(drawn(panel(zone)), 'theme,theme,control'); eq(panel(zone).backdropInfo, nil, 'no flat box, no line')
	eq(z:GetParent(), panel(zone), "on the item's panel, under the item's own art")
	eq(zone:GetHighlightTexture():GetDrawLayer(), 'HIGHLIGHT', 'the flat hover stays')
	eq(shown(select(2, MM:GetItemArt(zone))), 0, 'no kit on Forever')
	theme('thick')
	check(not z:IsShown() and not s:IsShown() and not t:IsShown()); check(magnifier:IsShown())
	eq(drawn(panel(zone)), 'theme,theme,control')
	eq(T.inset(panel(zone)), 2); eq(T.offset(panel(zone), 'TOPLEFT'), '-2.00,2.00', "today's small frame")
	eq(select(4, panel(zone):GetBackdropColor()), 0.9, "SaftUI's transparent background, as today")
	theme('thin'); check(not z:IsShown() and not t:IsShown() and magnifier:IsShown() and T.inset(panel(zone)) == 1, "Thin: today's 1px small frame, no Blizzard art")
	theme('blizzard')
	check(z:IsShown() and t:IsShown(), 'and back'); check(not magnifier:IsShown())
end)

test('retail under Blizzard: every box takes the grey minimap button kit, and there is no strip', function()
	world('retail')
	local zone, square = item({ width = 200, art = 'header' }), item()
	local search = CreateFrame('Button', nil, UIParent)
	local magnifier = search:CreateTexture(); MM:AddButton(search, { art = 'tracking', icon = magnifier })
	item({ width = 20, theme = 'none', micro = true }); item({ width = 20, theme = 'none', micro = true })
	theme('blizzard')
	local boxes = { zone = zone, square = square, search = search }
	for name, box in pairs(boxes) do
		local texture, pieces = MM:GetItemArt(box)
		check(not (texture and texture:IsShown()), name .. ": no atlas of Forever's")
		eq(shown(pieces), 9, name .. ': nine kit pieces')
		eq(pieces.TopLeftCorner:GetAtlas(), 'ui-hud-minimap-button-NineSlice-CornerTopLeft', name)
		eq(pieces.Center:GetAtlas(), 'ui-hud-minimap-button-NineSlice-Center', name)
		eq(pieces.Center:GetParent(), panel(box), name .. ': on its panel')
		eq(T.around(pieces.TopLeftCorner, box):match('^%-?%d+,%-?%d+'), '0,0', name .. ": the top left corner at the box's corner")
		eq(T.around(pieces.BottomRightCorner, box):match('%-?%d+,%-?%d+$'), '0,0', name .. ": the bottom right corner at the box's corner")
		eq(T.around(pieces.Center, box), '6,-6,-7,7', name .. ': the Center between the corners')
	end
	check(magnifier:IsShown(), "SaftUI's magnifier stays: the kit draws no icon")
	local strip = MM:GetStrip()
	check(not (strip and strip:IsShown()), 'no strip')
	theme('thick')
	for name, box in pairs(boxes) do
		eq(shown(select(2, MM:GetItemArt(box))), 0, name .. ': under Thick no piece shows')
	end
	check(magnifier:IsShown())
	eq(T.inset(panel(zone)), 2, "today's small frame")
end)

test('the micro buttons stand on one bronze strip from the first shown holder to the last, and it follows Blizzard showing and hiding them', function()
	world('forever')
	local before = item({ width = 48, art = 'header' })
	local a, b, c = item({ width = 20, theme = 'none', micro = true }), item({ width = 20, theme = 'none', micro = true }), item({ width = 20, theme = 'none', micro = true })
	local mail = item()
	check(MM:GetStrip() == nil, 'made the first time it shows')
	theme('blizzard')
	local strip, frameArt, background = MM:GetStrip()
	check(strip:IsShown()); eq(frameArt:GetAtlas(), 'UI-HUD-ActionBar-Frame'); eq(T.around(frameArt, strip), '0,0,0,0')
	eq(background:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Background'); eq(T.around(background, strip), '2,-2,-2,2')
	eq(select(1, frameArt:GetDrawLayer()), 'BORDER', 'the frame over'); eq(select(1, background:GetDrawLayer()), 'BACKGROUND', 'the background under it')
	eq(T.around(strip, a):match('^%-?%d+,%-?%d+'), '-4,4'); eq(T.around(strip, c):match('%-?%d+,%-?%d+$'), '4,-4')
	eq(strip:GetHeight(), 33); check(strip:GetLeft() > before:GetRight(), 'clear of the box before it')
	check(strip:GetRight() < mail:GetLeft(), 'and of the box after it')
	eq(strip:GetParent(), MM.Container); eq(strip:GetFrameLevel(), MM.Container:GetFrameLevel(), "the Container's level, under the holders")
	c:Hide(); eq(strip:GetRight(), b:GetRight() + 4, 'it ends at the last one shown')
	mail:Hide(); check(not MM:GetItemArt(mail):IsVisible(), "an item's art goes with it")
	-- In game the Container is protected: Blizzard's buttons are anchored to
	-- its holders. The strip, its child, isn't, so it still follows.
	MM.Container.IsProtected = function() return true end
	stub.in_combat = true; c:Show(); eq(strip:GetRight(), c:GetRight() + 4); eq(#stub.blocked, 0); stub.in_combat = false
	MM.Container.IsProtected = nil
	a:Hide(); eq(strip:GetLeft(), b:GetLeft() - 4, 'it starts at the first one shown')
	b:Hide(); c:Hide(); check(not strip:IsShown(), 'none shown: no strip')
	a:Show(); check(strip:IsShown(), 'back with one')
	theme('thick'); check(not strip:IsShown())
	theme('thin'); check(not strip:IsShown(), 'nor under Thin')
end)

------------------------------------ Blizzard's micro menu

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
	local strip = MM:GetStrip()
	check(strip ~= nil and strip:IsShown(), 'the strip of SaftUI shows')
	eq(T.around(strip, holder), '-4,4,4,-4', "around the button's holder")
	eq(strip:GetParent(), MM.Container, "a frame of SaftUI's bar")
	check(strip:GetFrameLevel() < holder:GetFrameLevel(), 'under the holder')
	theme('thick')
	check(not strip:IsShown()); eq(menu.BorderArt:GetAlpha(), 0)
end)
