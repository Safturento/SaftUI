-- SaftUI-Loot's interaction states (the interaction states plan, Task 7;
-- SaftUI-Core/Widgets/states.lua): the chosen roll's button on a held bar or a
-- preview is a selected 'box' on its icon's backdrop (the theme's edge in the
-- Accent and the fade; the others at the states' Disabled alpha; "Choice" and the
-- timer stay the Accent: a label and a progress fill are not states), the loot
-- window's rows are 'row' cards (a tint under the mouse; the border stays the
-- theme's), and the feed's two icon buttons are 'box' states with the icon as
-- the glyph (the lighter tone under the mouse).
--
-- Real: SaftUI-Loot's config.lua, init.lua, rollbar.lua, rollinfo.lua, Feed/feed.lua
-- and popup.lua, Core's helpers, the theme engine and the states. The window is
-- fixtures/loot_frame.lua. The roll bars and the feed button are checked in one
-- world, the window on both clients in a fresh one each.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')

local st, LT, profile, drawn
local LF

local EXPECT_BARS, EXPECT_WINDOW = 32, 1 -- setter calls a pass makes (measured)

local function same(a, b) return ('%.3f,%.3f,%.3f,%.3f'):format(unpack(a)) == ('%.3f,%.3f,%.3f,%.3f'):format(unpack(b)) end

------------------------------------------------------------------ the roll bars and the feed

local function bars_world(client)
	st = T.client(client)
	drawn = T.watch()
	load_string_format()
	GameTooltip = GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	load_saftui('SaftUI-Core/Utilities/utilities.lua')
	load_saftui('SaftUI-Loot/config.lua')
	apply_defaults()
	profile = st.config.profile
	load_saftui('SaftUI-Loot/init.lua')
	LT = st.Loot
	st:BindModuleConfig(LT, 'loot')
	st.config.char = {}
	load_saftui('SaftUI-Loot/rollbar.lua')
	load_saftui('SaftUI-Loot/rollinfo.lua')
	load_saftui('SaftUI-Loot/Feed/history.lua')
	load_saftui('SaftUI-Loot/Feed/parse.lua')
	load_saftui('SaftUI-Loot/Feed/feed.lua')
	take_errors()
end

local function make_bar(choice, config)
	local rb = LT.rollbar
	local bar = rb.CreateBar(UIParent)
	rb.LockBar(bar, choice)
	rb.ApplyBarConfig(bar, config or LT.config.roll)
	bar:Show()
	return bar
end

local function button_of(bar, choice)
	for _, button in ipairs(bar.buttons) do if button.choice == choice then return button end end
end

for _, client in ipairs({ 'forever', 'retail' }) do
	local function case(name, fn) test(name .. ' [' .. client .. ']', function() fn(client) eq(#take_errors(), 0, 'no error reported') end) end

	case('a bar and its buttons at rest are drawn as before: no border, nothing selected', function()
		bars_world(client)
		local bar = make_bar(nil)
		for _, button in ipairs(bar.buttons) do
			eq(button:GetAlpha(), 1, button.choice .. ': bright')
			check(not button.Icon.backdrop, button.choice .. ': no border')
		end
		check(not bar.Choice:IsShown(), 'no label')
	end)

	case('a chosen roll: the edge and fade on its icon, "Choice" in the accent; the others at the Disabled alpha', function()
		bars_world(client)
		local bar = make_bar('Greed')
		local lit = button_of(bar, 'Greed')
		local backdrop = lit.Icon.backdrop
		check(backdrop ~= nil, 'the chosen icon has a backdrop')
		local look = st:StateLook(backdrop)
		eq(look.shape, 'box', 'a box')
		eq(st:GetState(backdrop, 'selected'), true, 'selected')
		check(look.fill.shown, 'the fade shows')
		eq(('%.2f'):format(look.fill.a), ('%.2f'):format(select(4, st:StateColor('fill'))), 'at the derived fill')
		eq(SL.bytes(look.edge), SL.bytes({ r = profile.theme.accent.r, g = profile.theme.accent.g, b = profile.theme.accent.b }), 'the edge is the Accent')
		eq(T.edge_rgb(backdrop), T.text(profile.theme.accent.r, profile.theme.accent.g, profile.theme.accent.b), 'drawn on the theme\'s border')
		eq(lit:GetAlpha(), 1, 'the chosen button bright')
		for _, choice in ipairs({ 'Need', 'Pass' }) do
			eq(T.text(button_of(bar, choice):GetAlpha()), T.text(st:StateAlpha()), choice .. ': the states\' Disabled alpha')
		end
		eq(T.rgb(bar.Choice:GetTextColor()), T.rgb(profile.theme.accent:GetRGB()), '"Choice" is the Accent itself')
		check(not st:StateLook(backdrop).blizzard, 'not Blizzard\'s look')
	end)

	case('the Disabled setting reaches the dimmed buttons, the Accent the edge and the label', function()
		bars_world(client)
		local bar = make_bar('Greed')
		local backdrop = button_of(bar, 'Greed').Icon.backdrop
		local accent = profile.theme.accent
		local keep = { accent:GetRGB() }
		accent:SetRGB(0.9, 0.1, 0.2)
		st:ColorChanged('accent')
		LT.rollbar.ColorLocked(bar) -- roll.lua's ColorRollBars, on the accent group
		eq(T.edge_rgb(backdrop), '0.90,0.10,0.20', 'the new Accent\'s edge')
		eq(T.rgb(bar.Choice:GetTextColor()), '0.90,0.10,0.20', 'and "Choice"')
		accent:SetRGB(unpack(keep))
		st:ColorChanged('accent')
		-- The Disabled setting itself: the dimmed buttons follow it (Colors > States).
		local settings = profile.theme.states
		check(settings ~= nil, 'the profile holds the states settings')
		local before = st:StateAlpha()
		settings.disabled = 0.7
		st.States.Changed()
		LT.rollbar.ColorLocked(bar) -- roll.lua's ColorRollBars, on the accent group
		eq(T.text(st:StateAlpha()), '0.70', 'the setting took')
		for _, choice in ipairs({ 'Need', 'Pass' }) do
			eq(T.text(button_of(bar, choice):GetAlpha()), '0.70', choice .. ': follows the Disabled setting')
		end
		eq(button_of(bar, 'Greed'):GetAlpha(), 1, 'the chosen one stays bright')
		settings.disabled = nil
		st.States.Changed()
		check(before ~= nil, 'was set')
	end)

	case('a bar reused for another choice moves the selection; unlocked, nothing is selected', function()
		bars_world(client)
		local rb = LT.rollbar
		local bar = make_bar('Greed')
		local first = button_of(bar, 'Greed').Icon.backdrop
		rb.LockBar(bar, 'Need')
		rb.ApplyBarConfig(bar, LT.config.roll)
		eq(st:GetState(first, 'selected'), false, 'Greed is let go')
		eq(st:GetState(button_of(bar, 'Need').Icon.backdrop, 'selected'), true, 'Need is selected')
		check(not st:StateLook(first).fill.shown, 'Greed\'s fade is gone')
		rb.LockBar(bar, nil)
		rb.ApplyBarConfig(bar, LT.config.roll)
		for _, button in ipairs(bar.buttons) do
			eq(button:GetAlpha(), 1, button.choice .. ': bright')
			local b = button.Icon.backdrop
			check(not b or not st:GetState(b, 'selected'), button.choice .. ': not selected')
		end
	end)

	case('under Blizzard: a chosen roll keeps the Accent edge and a visible fade (the line is SaftUI\'s own)', function()
		bars_world(client)
		local config = setmetatable({ theme = 'blizzard' }, { __index = LT.config.roll })
		local bar = make_bar('Greed', config)
		local backdrop = button_of(bar, 'Greed').Icon.backdrop
		check(backdrop ~= nil, 'the chosen icon has a backdrop')
		local look = st:StateLook(backdrop)
		check(not look.blizzard, 'not treated as Blizzard\'s art')
		check(look.fill.shown and look.fill.alpha > 0, 'the fade shows')
		local accent = profile.theme.accent
		eq(T.edge_rgb(backdrop), T.text(accent.r, accent.g, accent.b), 'the edge is the Accent')
	end)

	case('under Blizzard the feed icons rest in Text > Normal and follow a change', function()
		bars_world(client)
		local feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
		feed:SetSize(400, 20)
		LT.feed = feed
		feed.items = {}
		feed.filterButton = LT:CreateFeedIconButton('SaftUITestFeedBliz', st.icons.funnel, 'Filter')
		feed.reset_button = LT:CreateFeedIconButton('SaftUITestFeedBliz2', st.icons.arrowDownToLine, 'Jump')
		T.theme('blizzard')
		LT:ColorFeed('theme')
		local normal = profile.colors.text.normal
		eq(T.rgb(feed.filterButton.icon:GetVertexColor()), T.rgb(normal:GetRGB()), 'at rest in Text > Normal')
		local saved = normal
		profile.colors.text.normal = CreateColor(0.25, 0.5, 0.75, 1)
		LT:ColorFeed('text')
		eq(T.rgb(feed.filterButton.icon:GetVertexColor()), '0.25,0.50,0.75', 'a new Text > Normal reaches the filter icon')
		eq(T.rgb(feed.reset_button.icon:GetVertexColor()), '0.25,0.50,0.75', 'and the jump icon')
		profile.colors.text.normal = saved
		T.theme('thick')
	end)

	case('the feed\'s buttons: the Layer for hover, the icon the lighter tone, the accent kept out', function()
		bars_world(client)
		local feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
		feed:SetSize(400, 20)
		LT.feed = feed
		local button = LT:CreateFeedIconButton('SaftUITestFeedButton', st.icons.funnel, 'Filter')
		local look = st:StateLook(button)
		eq(look.shape, 'box', 'a box')
		check(not look.layer.shown, 'no Layer at rest')
		eq(T.rgb(button.icon:GetVertexColor()), T.rgb(st:Color('text', 'normal'):GetRGB()), 'the icon at Text > Normal')
		stub.fire_script(button, 'OnEnter', true)
		look = st:StateLook(button)
		check(look.layer.shown, 'the Layer under the mouse')
		eq(T.rgb(button.icon:GetVertexColor()), T.rgb(st:StateColor('edgeHover')), 'the icon the lighter tone')
		check(T.rgb(button.icon:GetVertexColor()) ~= T.rgb(profile.theme.accent:GetRGB()), 'not the Accent itself')
		stub.fire_script(button, 'OnLeave', true)
		check(not st:StateLook(button).layer.shown, 'gone on leave')
		eq(T.rgb(button.icon:GetVertexColor()), T.rgb(st:Color('text', 'normal'):GetRGB()), 'the icon at rest again')
	end)

	case('a pass with four locked rolls and a feed button: under 60 calls, nothing made or forbidden', function()
		bars_world(client)
		local feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
		feed:SetSize(400, 20)
		LT.feed = feed
		feed.filterButton = LT:CreateFeedIconButton('SaftUITestFeedButtonA', st.icons.funnel, 'Filter')
		feed.reset_button = LT:CreateFeedIconButton('SaftUITestFeedButtonB', st.icons.arrowDownToLine, 'Jump')
		feed.items = {}
		local bars = {}
		for _, choice in ipairs({ 'Need', 'Greed', 'Pass', 'Need' }) do
			bars[#bars + 1] = make_bar(choice)
		end
		st:ColorChanged('accent')
		local m = C.measure(function()
			st:ColorChanged('accent')
			for _, bar in ipairs(bars) do LT.rollbar.ColorLocked(bar) end -- ColorRollBars' pass over locked bars
		end, 1)
		eq(m.forbidden.total, 0, 'nothing forbidden')
		eq(m.made, 0, 'nothing made')
		eq(m.calls.total, EXPECT_BARS, 'the exact setter calls')
		check(m.calls.total < 60, 'under 60 setter calls: ' .. m.calls.total)
		local m100 = C.measure(function() st:ColorChanged('accent') end, 100)
		check(m100.kb < 4, 'under 4 KB over 100 passes: ' .. ('%.2f'):format(m100.kb))
		-- The same pass in combat: colors on SaftUI's own frames, nothing blocked.
		stub.in_combat, stub.blocked = true, {}
		local mc = C.measure(function()
			st:ColorChanged('accent')
			for _, bar in ipairs(bars) do LT.rollbar.ColorLocked(bar) end
		end, 1)
		stub.in_combat = false
		eq(mc.calls.total, EXPECT_BARS, 'in combat: the same calls')
		eq(mc.forbidden.total, 0, 'in combat: nothing forbidden')
		eq(#stub.blocked, 0, 'in combat: nothing blocked')
	end)
end

------------------------------------------------------------------ the loot window

local SLOTS = {
	{ kind = 'item', quality = 4, name = 'Epic thing' },
	{ kind = 'item', quality = 2, name = 'Green thing', count = 5 },
}

local function window_world(client, theme)
	st = T.client(client)
	_G.LootFrame = nil
	stub.loaded_addons.Blizzard_UIPanels_Game = nil
	drawn = T.watch()
	load_saftui('SaftUI-Loot/config.lua')
	apply_defaults()
	profile = st.config.profile
	if theme then profile.loot.popup.theme = theme end
	load_saftui('SaftUI-Loot/init.lua')
	load_saftui('SaftUI-Loot/options.lua')
	load_saftui('SaftUI-Loot/popup.lua')
	LT = st.Loot
	LF = load_test_file('loot/fixtures/loot_frame.lua')
	function LT:SetTestRolls() end
	function LT:SetTestFeed() end
	st:BindModuleConfig(LT, 'loot')
	LF.build({ client = client })
	stub.loaded_addons.Blizzard_UIPanels_Game = true
	LT:InitializeLootFrame()
	LF.open(SLOTS)
	take_errors()
end

local function card_of(row)
	for _, child in ipairs({ row:GetChildren() }) do
		if not LF.set[child] and child.backdrop then return child end
	end
end

for _, client in ipairs({ 'forever', 'retail' }) do
	local function case(name, fn) test(name .. ' [' .. client .. ']', function() fn(client) eq(#take_errors(), 0, 'no error reported') end) end

	case('a loot window row tints under the mouse; its edge stays the theme\'s', function()
		window_world(client)
		local row = LF.elements()[1]
		local card = card_of(row)
		local look = st:StateLook(card)
		eq(look.shape, 'row', 'a row')
		check(not look.layer.shown, 'no tint at rest')
		local edge = T.edge_rgb(card.backdrop)
		LF.fire(row.Item, 'OnEnter')
		look = st:StateLook(card)
		check(look.layer.shown, 'the tint under the mouse')
		eq(('%.2f'):format(look.layer.a), ('%.2f'):format(select(4, st:StateColor('hover'))), 'at the derived hover')
		eq(T.edge_rgb(card.backdrop), edge, 'the edge is the theme\'s still')
		LF.fire(row.Item, 'OnLeave')
		check(not st:StateLook(card).layer.shown, 'gone on leave')
		eq(#LF.stray, 0, 'nothing of Blizzard\'s written')
	end)

	case('under Blizzard: Blizzard\'s (the window is left alone, no card tint)', function()
		window_world(client, 'blizzard')
		for _, row in ipairs(LF.elements()) do
			local card = card_of(row)
			check(not card or not card:IsShown(), 'SaftUI\'s card is not shown')
			eq(row.NameFrame:GetAlpha(), 1, 'Blizzard\'s card')
		end
	end)

	case('a pass with the window open and a hovered row: under 60 calls, nothing made or forbidden', function()
		window_world(client)
		local row = LF.elements()[1]
		LF.fire(row.Item, 'OnEnter')
		st:ColorChanged('accent')
		local m = C.measure(function() st:ColorChanged('accent') end, 1)
		eq(m.forbidden.total, 0, 'nothing forbidden')
		eq(m.made, 0, 'nothing made')
		eq(m.calls.total, EXPECT_WINDOW, 'the exact setter calls')
		check(m.calls.total < 60, 'under 60 setter calls: ' .. m.calls.total)
		local m100 = C.measure(function() st:ColorChanged('accent') end, 100)
		check(m100.kb < 4, 'under 4 KB over 100 passes: ' .. ('%.2f'):format(m100.kb))
		stub.in_combat, stub.blocked = true, {}
		local mc = C.measure(function() st:ColorChanged('accent') end, 1)
		stub.in_combat = false
		eq(mc.calls.total, EXPECT_WINDOW, 'in combat: the same calls')
		eq(mc.forbidden.total, 0, 'in combat: nothing forbidden')
		eq(#stub.blocked, 0, 'in combat: nothing blocked')
	end)
end
