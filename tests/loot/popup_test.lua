-- The loot window skin (SaftUI-Loot/popup.lua), Blizzard's LootFrame in SaftUI's look:
--   - Loot -> Loot window has Enable (on by default), Theme, Background and Font,
--     each with its own reset, and applies at once;
--   - with Enable on and a Thick or Thin look: SaftUI's panel behind the window,
--     Blizzard's border and background faded, the title in the Window titles
--     font, the close button's art faded and a cross of SaftUI's over it; each row
--     a card of SaftUI's (its Blizzard card and click art faded, tinted by the
--     states' hover while the mouse is over the row, its border the theme's) and its icon in a slot of SaftUI's
--     whose border is the item's quality color, cropped by Icon zoom with its round
--     mask off; the texts in the Loot window's font; a changed slot recolors;
--   - under Blizzard, under None and with Enable off, Blizzard's own art, fonts,
--     tex coords and masks, and nothing of SaftUI's shown; each theme switch, the
--     toggle, a profile change and a recolor or font change going between them live;
--   - with Enable off from the start, nothing is hooked or touched at all;
--   - nothing written onto Blizzard's frames (every frame and region is locked:
--     lib/locked_widget.lua, and the key lists before and after are the same), no
--     script replaced, only the C methods the skin is allowed to call on them
--     (LF.calls), and none of Blizzard's functions that write run from SaftUI;
--   - styled in combat with nothing blocked, and a window that something made
--     protected styled once combat ends;
--   - a window with no scroll box, or a part a client lacks, left alone with no error;
--   - the addon loading after SaftUI.
-- On both clients: the window is the same on each (tests/loot/fixtures/loot_frame.lua).
--
-- Real: SaftUI-Loot's config.lua, init.lua, options.lua and popup.lua, Core's
-- helpers and the theme engine. Blizzard's window is fixtures/loot_frame.lua.
local T = load_test_file('lib/theme_helpers.lua')

local st, drawn, LT, profile, LF

local SLOTS = {
	{ kind = 'item', quality = 4, name = 'Epic thing' },
	{ kind = 'item', quality = 2, name = 'Green thing', count = 5 },
	{ kind = 'money', quality = 1, name = '12 gold' },
}

-- A fresh world on client with the skin loaded and Blizzard's window built
-- before SaftUI's module enables (as the game loads Blizzard's addon first),
-- unless opts.late; opts.off turns Enable off, opts.theme sets the popup's Theme.
local function world(client, opts)
	opts = opts or {}
	st = T.client(client)
	_G.LootFrame = nil
	stub.loaded_addons.Blizzard_UIPanels_Game = nil
	drawn = T.watch()
	load_saftui('SaftUI-Loot/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.off then profile.loot.popup.enable = false end
	if opts.theme then profile.loot.popup.theme = opts.theme end
	load_saftui('SaftUI-Loot/init.lua')
	load_saftui('SaftUI-Loot/options.lua')
	load_saftui('SaftUI-Loot/popup.lua')
	LT = st.Loot
	-- Blizzard's window, whose fonts and frames the fresh world has to make.
	LF = load_test_file('loot/fixtures/loot_frame.lua')
	-- The rolls and the feed aren't loaded here.
	function LT:SetTestRolls() end
	function LT:SetTestFeed() end
	st:BindModuleConfig(LT, 'loot')
	if not opts.late then
		LF.build({ client = client, protected = opts.protected, omit = opts.omit })
		stub.loaded_addons.Blizzard_UIPanels_Game = true
	end
	-- In combat from the start, with opts.combat (the game's login is never in
	-- combat, but a reload can be).
	if opts.combat then stub.in_combat, stub.blocked = true, {} end
	-- OnEnable's call.
	LT:InitializeLootFrame()
end

-- The Theme tab's switch, as Config:UpdateConfig runs it: every themed frame
-- drawn again, then the module's own update, then the recolor.
local function switch(name)
	T.theme(name, function()
		LT:UpdateConfig()
		st:ColorsChanged('theme')
	end)
end

local function own_children(frame)
	local out = {}
	for _, child in ipairs({ frame:GetChildren() }) do
		if not LF.set[child] then out[#out + 1] = child end
	end
	return out
end

local function own_regions(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if not LF.set[region] then out[#out + 1] = region end
	end
	return out
end

-- SaftUI's frame that carries a theme drawing (a backdrop's frame) among a
-- frame's own children, or its child's child (a holder's backdrop).
local function drawn_child(frame)
	for _, child in ipairs(own_children(frame)) do
		if child.backdrop then return child end
	end
end

local function slot_backdrop(row)
	for _, child in ipairs(own_children(row.Item)) do
		if child.backdropInfo then return child end
	end
end

local function panel_of(frame)
	for _, child in ipairs(own_children(frame)) do
		if child.backdropInfo and child:GetFrameLevel() < frame:GetFrameLevel() then return child end
	end
end

local function visible(frame) return frame and frame:IsShown() end

local function rows() return LF.elements() end

-- Blizzard's art as the templates draw it: nothing faded, nothing of SaftUI's
-- shown, Blizzard's fonts, tex coords and masks.
local function check_blizzard(where)
	local frame = LF.frame
	eq(frame.NineSlice:GetAlpha(), 1, where .. ': the border is Blizzard\'s')
	eq(frame.Bg:GetAlpha(), 1, where .. ': the background is Blizzard\'s')
	eq(frame.TitleContainer.TitleText:GetFontObject(), GameFontNormal, where .. ': the title font')
	eq(T.rgb(frame.TitleContainer.TitleText:GetTextColor()), '1.00,0.82,0.00', where .. ': the title is Blizzard\'s yellow')
	for _, getter in ipairs({ 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }) do
		eq(frame.ClosePanelButton[getter](frame.ClosePanelButton):GetAlpha(), 1, where .. ': close ' .. getter)
	end
	local panel = panel_of(frame)
	check(not panel or not panel:IsShown(), where .. ': SaftUI\'s panel is not shown')
	eq(frame.ScrollBox:GetScale(), 1, where .. ': the rows are at Blizzard\'s scale')
	eq(frame.ScrollBox:GetWidth(), 214, where .. ': the scroll box is Blizzard\'s width')
	eq(select(4, frame.ScrollBox:GetPoint(1)), 4, where .. ': and anchored where Blizzard anchors it')
	check(frame:GetWidth() == 220 or frame:GetWidth() == 236, where .. ': the window is Blizzard\'s width')
	for _, child in ipairs(own_children(frame.ClosePanelButton)) do
		check(not child:IsShown(), where .. ': SaftUI\'s cross is not shown')
	end
	for i, row in ipairs(rows()) do
		local label = where .. ', row ' .. i
		eq(row.NameFrame:GetAlpha(), 1, label .. ': the card')
		eq(row.BorderFrame:GetAlpha(), 1, label .. ': the card\'s stroke')
		eq(row.HighlightNameFrame:GetAlpha(), 0.7, label .. ': the hover stroke keeps the alpha its XML gives it')
		eq(row.PushedNameFrame:GetAlpha(), 1, label .. ': the pushed stroke')
		eq(row.Item.IconBorder:GetAlpha(), 1, label .. ': the icon border')
		eq(row.Item:GetNormalTexture():GetAlpha(), 1, label .. ': the normal texture')
		eq(row.Text:GetFontObject(), GameFontNormal, label .. ': the name font')
		eq(row.Item.Count:GetFontObject(), NumberFontNormal, label .. ': the count font')
		if row.QualityText then
			eq(row.QualityText:GetFontObject(), GameFontWhiteTiny2, label .. ': the quality font')
			eq(row.QualityText:GetAlpha(), 1, label .. ': the quality word shows')
		end
		check(row.Text:CanWordWrap(), label .. ': the name wraps, as Blizzard\'s does')
		eq(select(2, row.Text:GetPoint(1)), row.Item, label .. ': the name is anchored as Blizzard anchors it')
		eq(T.text(row.Text:GetSize()), T.text(150, 30), label .. ': at Blizzard\'s size')
		eq(T.text(row.Item:GetHitRectInsets()), T.text(0, 0, 0, 0), label .. ': the icon\'s click area is as built')
		eq(T.text(row.Item.icon:GetTexCoord()), T.text(0, 0, 0, 1, 1, 0, 1, 1), label .. ': the icon shows the whole texture')
		eq(row.Item.icon:GetNumMaskTextures(), LF.client == 'forever' and 1 or 0,
			label .. ': the icon has the mask Blizzard gave it (Forever\'s round one, none on retail)')
		eq(T.rgb(row.Text:GetTextColor()), T.rgb(unpack(LF.QUALITY[select(5, GetLootSlotInfo(i))])), label .. ': the name keeps Blizzard\'s quality color')
		local card = drawn_child(row)
		check(not card or not card:IsShown(), label .. ': SaftUI\'s card is not shown')
		local slot = slot_backdrop(row)
		check(not slot or not slot:IsShown(), label .. ': SaftUI\'s slot is not shown')
	end
end

local function check_skinned(where)
	local frame = LF.frame
	local look = 'theme,solid,'
	eq(drawn(frame), look .. 'panel', where .. ': the window is drawn as a panel in the Loot window\'s look')
	local panel = panel_of(frame)
	check(visible(panel), where .. ': SaftUI\'s panel is shown')
	eq(frame.NineSlice:GetAlpha(), 0, where .. ': Blizzard\'s border is faded')
	eq(frame.Bg:GetAlpha(), 0, where .. ': Blizzard\'s background is faded')
	eq(frame.TitleContainer.TitleText:GetFontObject(), st:FontObject(profile.headers.font), where .. ': the title is in the Window titles font')
	eq(T.rgb(frame.TitleContainer.TitleText:GetTextColor()), T.rgb(st:FontObject(profile.headers.font):GetTextColor()),
		where .. ': and wears that font\'s color, not Blizzard\'s yellow')
	for _, getter in ipairs({ 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }) do
		eq(frame.ClosePanelButton[getter](frame.ClosePanelButton):GetAlpha(), 0, where .. ': close ' .. getter .. ' is faded')
	end
	local cross = own_children(frame.ClosePanelButton)[1]
	check(visible(cross), where .. ': the cross is shown')
	eq(own_regions(cross)[1]:GetTexture(), st.icons.x, where .. ': the cross is Lucide\'s x')

	-- The compact layout: rows scaled down in a wider window, the texts in the
	-- Loot window's font made larger by the same factor.
	local box = frame.ScrollBox
	eq(box:GetScale(), 0.75, where .. ': the rows are scaled down')
	eq(frame:GetWidth(), 300 + (frame.ScrollBar:IsShown() and 16 or 0), where .. ': the window is wider')
	eq(box:GetWidth(), 294 / 0.75, where .. ': and so is the scroll box, in its scaled units')
	local font = LT.PopupFont()
	local base = st:FontObject(profile.loot.popup.font)
	eq(select(2, font:GetFont()), select(2, base:GetFont()) / 0.75, where .. ': the rows\' font is the Loot window\'s, made larger by the scale')
	for i, row in ipairs(rows()) do
		local label = where .. ', row ' .. i
		eq(row.NameFrame:GetAlpha(), 0, label .. ': Blizzard\'s card is faded')
		eq(row.BorderFrame:GetAlpha(), 0, label .. ': its stroke')
		eq(row.HighlightNameFrame:GetAlpha(), 0, label .. ': its hover stroke')
		eq(row.PushedNameFrame:GetAlpha(), 0, label .. ': its pushed stroke')
		if row.QualityStripe then eq(row.QualityStripe:GetAlpha(), 0, label .. ': its quality stripe') end
		eq(row.Item.IconBorder:GetAlpha(), 0, label .. ': Blizzard\'s icon border')
		eq(row.Item:GetNormalTexture():GetAlpha(), 0, label .. ': the normal texture')
		eq(row.Item:GetPushedTexture():GetAlpha(), 0, label .. ': the pushed texture')
		local holder = drawn_child(row)
		check(visible(holder), label .. ': SaftUI\'s card is shown')
		eq(drawn(holder), look .. 'panel', label .. ': the card is a panel')
		local slot = slot_backdrop(row)
		check(visible(slot), label .. ': SaftUI\'s slot is shown')
		eq(drawn(row.Item), look .. 'slot', label .. ': the icon is in a slot')
		eq(row.Text:GetFontObject(), font, label .. ': the name is in the Loot window\'s font')
		eq(row.Item.Count:GetFontObject(), font, label .. ': so is the count')
		if row.QualityText then eq(row.QualityText:GetAlpha(), 0, label .. ': the quality word is faded') end
		check(not row.Text:CanWordWrap(), label .. ': the name stays on one line')
		eq(holder:GetScale(), 1 / 0.75, label .. ': the card is in the window\'s own pixels')
		eq(slot:GetScale(), 1 / 0.75, label .. ': so is the slot')
		eq(holder:GetPoint(1) and select(2, holder:GetPoint(1)), row.Item, label .. ': the card starts right of the icon')
		eq(select(2, row.Text:GetPoint(1)), holder, label .. ': the name runs across the card')
		eq(select(2, row.Item:GetHitRectInsets()), -(294 / 0.75 - 12 - 42), label .. ': the icon\'s click area covers the card')
		local trim = profile.misc.icon_trim
		eq(T.text(row.Item.icon:GetTexCoord()), T.text(trim, trim, trim, 1 - trim, 1 - trim, trim, 1 - trim, 1 - trim), label .. ': the icon is cropped')
		eq(row.Item.icon:GetNumMaskTextures(), 0, label .. ': its round mask is off')
		eq(T.rgb(row.Text:GetTextColor()), T.rgb(unpack(LF.QUALITY[select(5, GetLootSlotInfo(i))])), label .. ': the name keeps Blizzard\'s quality color through the font')
		-- The slot's border is the quality color; a money row has none.
		if row.QualityText then
			local color = st:QualityColor((select(5, GetLootSlotInfo(i))))
			eq(T.edge_rgb(slot), T.text(color.r, color.g, color.b), label .. ': the slot\'s border is the item\'s quality color')
		end
		check(slot.GetFrameLevel(slot) < row.Item:GetFrameLevel(), label .. ': the slot lies under the icon')
		check(slot.GetFrameLevel(slot) > holder.backdrop:GetFrameLevel(), label .. ': and over the card')
	end
end

local function open() LF.open(SLOTS) end

local function clean()
	-- The compact layout's C calls on plain frames and regions (none on
	-- LootFrame is Edit Mode's: SetWidth and SetHeight aren't overridden).
	local allowed = { SetAlpha = true, SetFontObject = true, SetTextColor = true, SetTexCoord = true, RemoveMaskTexture = true, AddMaskTexture = true, HookScript = true,
		SetScale = true, ClearAllPoints = true, SetPoint = true, SetWidth = true, SetHeight = true, SetSize = true, SetShown = true,
		SetWordWrap = true, SetJustifyV = true, SetHitRectInsets = true }
	for _, call in ipairs(LF.calls) do
		check(allowed[call], 'SaftUI called ' .. call .. ' on one of Blizzard\'s loot widgets')
	end
	eq(#LF.stray, 0, 'no Blizzard function that writes ran from SaftUI')
	for _, widget in ipairs(LF.widgets) do
		eq(LF.keys(widget), LF.keys0[widget], 'the fields of a Blizzard widget are as built')
	end
	local errors = take_errors()
	eq(#errors, 0, 'no errors: ' .. tostring(errors[1]))
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the window and its rows are skinned', function()
		world(client)
		open()
		check_skinned(client)
		eq(#own_children(LF.frame), 1, 'SaftUI made one child of the window: its panel')
		eq(#own_children(LF.frame.ClosePanelButton), 1, 'and one of the close button: its cross')
		for _, row in ipairs(rows()) do
			eq(#own_children(row), 1, 'one of each row: its card')
			eq(#own_children(row.Item), 1, 'and one of its icon button: the slot')
		end
		clean()
	end)

	test(client .. ': the window is skinned when it shows, before any row', function()
		world(client)
		-- Nothing is open yet: no row exists, and only the window is styled.
		LF.show()
		check(visible(panel_of(LF.frame)), 'the panel is there when the window shows')
		clean()
	end)
end

test('a changed slot takes the new quality (read as Init reads it); a pooled row comes back styled', function()
	world('forever')
	open()
	local row = rows()[1]
	local slot = slot_backdrop(row)
	local before = T.edge_rgb(slot)
	LF.change(1, { quality = 5, name = 'Legendary thing' })
	-- The element data still says epic (LOOT_OPENED's); GetLootSlotInfo says legendary.
	eq(row.GetQuality(row), 4, 'Blizzard\'s element data is not replaced')
	local color = st:QualityColor(5)
	eq(T.edge_rgb(slot), T.text(color.r, color.g, color.b), 'the slot\'s border is the new quality\'s')
	check(before ~= T.edge_rgb(slot), 'it changed')
	eq(T.rgb(row.Text:GetTextColor()), T.rgb(unpack(LF.QUALITY[5])), 'and the name keeps Blizzard\'s color for it')
	LF.close()
	LF.open({ { kind = 'item', quality = 3, name = 'Blue thing' } })
	eq(#own_children(rows()[1]), 1, 'a pooled row has still only one card')
	local blue = st:QualityColor(3)
	eq(T.edge_rgb(slot_backdrop(rows()[1])), T.text(blue.r, blue.g, blue.b), 'and the new slot\'s color')
	LF.open(SLOTS)
	check_skinned('the pool, handed out again')
	clean()
end)

test('retail: no mask to take off or put back, and a toggle round trip leaves none', function()
	world('retail')
	open()
	for _, row in ipairs(rows()) do eq(row.Item.icon:GetNumMaskTextures(), 0, 'no mask on retail\'s icon') end
	check_skinned('retail on')
	profile.loot.popup.enable = false
	LT:UpdatePopup()
	check_blizzard('retail off')
	profile.loot.popup.enable = true
	LT:UpdatePopup()
	check_skinned('retail on again')
	clean()
end)

test('names keep their quality colors through a font change, the toggle and a theme switch', function()
	world('forever')
	open()
	profile.loot.popup.font = 'pixel'
	st:FontsChanged()
	check_skinned('font')
	profile.loot.popup.enable = false
	LT:UpdatePopup()
	check_blizzard('off')
	profile.loot.popup.enable = true
	LT:UpdatePopup()
	switch('blizzard')
	check_blizzard('Blizzard theme')
	switch('thin')
	check_skinned('Thin')
	clean()
end)

test('a row handed out while Enable is off is not hooked, and no row is hooked twice', function()
	world('forever')
	open()
	profile.loot.popup.enable = false
	LT:UpdatePopup()
	LF.open({ { kind = 'item', quality = 2, name = 'Late thing' }, { kind = 'item', quality = 1, name = 'x' },
		{ kind = 'item', quality = 1, name = 'y' }, { kind = 'item', quality = 1, name = 'z' } })
	local fresh = rows()[4]
	check(not stub.hook_wrappers[fresh.Init], 'a row first seen while off has no Init hook')
	profile.loot.popup.enable = true
	LT:UpdatePopup()
	check(stub.hook_wrappers[fresh.Init], 'hooked once it is on')
	LT:UpdatePopup()
	LT:UpdatePopup()
	local init = fresh.Init
	LT:UpdatePopup()
	eq(fresh.Init, init, 'and never a second time')
	clean()
end)

test('the mouse over a row tints its card, and its border stays the theme\'s', function()
	world('forever')
	open()
	local row = rows()[1]
	local holder = drawn_child(row)
	local card = holder.backdrop
	local before = T.edge_rgb(card)
	LF.fire(row.Item, 'OnEnter')
	eq(st:GetState(holder, 'hover'), true, 'the card is hovered')
	check(st:StateLook(holder).layer.shown, 'its tint shows')
	eq(T.edge_rgb(card), before, 'the border is the theme\'s, not the accent')
	eq(row.HighlightNameFrame:GetAlpha(), 0, 'Blizzard\'s hover stroke stays faded (it shows, at no alpha)')
	LF.fire(row.Item, 'OnLeave')
	eq(st:GetState(holder, 'hover'), false, 'the card is let go')
	check(not st:StateLook(holder).layer.shown, 'its tint is gone')
	eq(T.edge_rgb(card), before, 'the theme\'s own border')
	clean()
end)

test('Blizzard\'s own scripts on the row still run (the hooks only add)', function()
	world('forever')
	open()
	local row = rows()[1]
	LF.fire(row.Item, 'OnEnter')
	check(row.HighlightNameFrame:IsShown(), 'Blizzard\'s OnEnter showed its stroke')
	LF.fire(row.Item, 'OnLeave')
	check(not row.HighlightNameFrame:IsShown(), 'and its OnLeave hid it')
	LF.click(row.Item)
	eq(LF.clicked, 1, 'Blizzard\'s OnClick runs on a click')
	clean()
end)

test('Thick, Thin, Blizzard and back: Blizzard\'s art comes back under Blizzard and goes again', function()
	world('forever')
	open()
	check_skinned('Thick')
	switch('thin')
	check_skinned('Thin')
	switch('blizzard')
	check_blizzard('Blizzard')
	switch('thick')
	check_skinned('Thick again')
	clean()
end)

test('the popup\'s own Theme: Blizzard and None leave Blizzard\'s window, Thin and Thick skin it', function()
	for _, theme in ipairs({ 'blizzard', 'none' }) do
		world('forever', { theme = theme })
		open()
		check_blizzard('Theme ' .. theme)
		eq(#own_children(LF.frame), 0, theme .. ': SaftUI made nothing on the window')
		for _, row in ipairs(rows()) do
			eq(#own_children(row), 0, theme .. ': nor on a row')
			eq(#own_children(row.Item), 0, theme .. ': nor on its icon button')
		end
		clean()
	end
	for _, theme in ipairs({ 'thick', 'thin' }) do
		world('forever', { theme = theme })
		open()
		eq(drawn(LF.frame), theme .. ',solid,panel', 'Theme ' .. theme)
		eq(LF.frame.NineSlice:GetAlpha(), 0, theme .. ': Blizzard\'s border is faded')
		clean()
	end
	-- Switched live: Blizzard, then Thin.
	world('forever')
	open()
	profile.loot.popup.theme = 'blizzard'
	LT:UpdatePopup()
	check_blizzard('switched to Blizzard')
	profile.loot.popup.theme = 'thin'
	LT:UpdatePopup()
	eq(drawn(LF.frame), 'thin,solid,panel', 'switched to Thin')
	eq(LF.frame.NineSlice:GetAlpha(), 0, 'and skinned')
	profile.loot.popup.theme = 'none'
	LT:UpdatePopup()
	check_blizzard('switched to None')
	clean()
end)

test('Enable off from the start: nothing hooked, nothing touched', function()
	world('forever', { off = true })
	local update = LF.scroll_box.Update
	local show = LF.frame:GetScript('OnShow')
	open()
	rows() -- built
	check_blizzard('off')
	check(not stub.hook_wrappers[LF.scroll_box.Update], 'the scroll box\'s Update is not hooked')
	eq(LF.scroll_box.Update, update, 'and is the one Blizzard had')
	check(not stub.hook_wrappers[rows()[1].Init], 'no row\'s Init is hooked')
	eq(#LF.calls, 0, 'SaftUI called nothing on a Blizzard widget')
	eq(#own_children(LF.frame), 0, 'and made nothing on the window')
	for _, row in ipairs(rows()) do eq(#own_children(row), 0, 'nor on a row') end
	eq(LF.frame:GetScript('OnShow'), show, 'the window\'s OnShow is Blizzard\'s')
	clean()
end)

test('the toggle goes both ways live: off puts Blizzard\'s window back, on skins it again', function()
	world('forever')
	open()
	check_skinned('on')
	profile.loot.popup.enable = false
	LT:UpdatePopup()
	check_blizzard('turned off')
	-- A row handed out while it is off is left alone.
	LF.open(SLOTS)
	check_blizzard('opened while off')
	profile.loot.popup.enable = true
	LT:UpdatePopup()
	check_skinned('turned on again')
	LF.open({ { kind = 'item', quality = 5, name = 'Legendary thing' } })
	check_skinned('a window opened after')
	clean()
end)

test('the compact layout: a short window for few rows, Blizzard\'s max height and the scroll bar for many, Blizzard\'s size back when off', function()
	world('forever')
	LF.open({ { kind = 'item', quality = 2 }, { kind = 'item', quality = 3 } })
	-- Two 46 px rows and their 2 px gap with the 6 px paddings, scaled, and the
	-- title and margins.
	eq(LF.frame:GetHeight(), (2 * 46 + 2 + 12) * 0.75 + 46 - 12, 'two rows: the window fits them')
	check(not LF.frame.ScrollBar:IsShown(), 'and has no scroll bar')
	eq(LF.frame:GetWidth(), 300, 'at the compact width')
	local seven = {}
	for i = 1, 7 do seven[i] = { kind = 'item', quality = 1 } end
	LF.open(seven)
	eq(LF.frame:GetHeight(), 290, 'seven rows: Blizzard\'s max height')
	check(not LF.frame.ScrollBar:IsShown(), 'and they all fit, so no scroll bar')
	eq(LF.frame:GetWidth(), 300, 'nor its room')
	local many = {}
	for i = 1, 12 do many[i] = { kind = 'item', quality = 1, name = 'Thing ' .. i } end
	LF.open(many)
	eq(LF.frame:GetHeight(), 290, 'twelve rows: Blizzard\'s max height')
	check(LF.frame.ScrollBar:IsShown(), 'with the scroll bar')
	eq(LF.frame:GetWidth(), 316, 'and room for it')
	profile.loot.popup.enable = false
	LT:UpdatePopup()
	eq(LF.frame:GetHeight(), 290, 'off: Blizzard\'s height for twelve rows')
	eq(LF.frame:GetWidth(), 236, 'and Blizzard\'s width with its scroll bar')
	LF.open({ { kind = 'item', quality = 2 } })
	eq(LF.frame:GetHeight(), 46 + 46, 'opened while off: Blizzard\'s own Resize, untouched')
	eq(LF.frame:GetWidth(), 220, 'at Blizzard\'s width')
	clean()
end)

test('a font change reaches the open window, a Window titles font change the title', function()
	world('forever')
	open()
	profile.loot.popup.font = 'pixel'
	st:FontsChanged()
	check_skinned('Small text')
	for _, row in ipairs(rows()) do
		eq(row.Text:GetFontObject(), LT.PopupFont(), 'the name is in the rows\' font')
		eq(select(2, LT.PopupFont():GetFont()), select(2, st:FontObject('pixel'):GetFont()) / 0.75, 'which is Small text, made larger by the scale')
	end
	profile.headers.font = 'pixel'
	st:FontsChanged()
	eq(LF.frame.TitleContainer.TitleText:GetFontObject(), st:FontObject('pixel'), 'the title follows Window titles')
	-- Back to Blizzard: the fonts it had.
	profile.loot.popup.enable = false
	st:FontsChanged()
	check_blizzard('off after a font change')
	clean()
end)

test('a color change reaches the slots, and a recolor does not leave them on the theme\'s border', function()
	world('forever')
	open()
	profile.colors.item_quality[4] = CreateColor(0.2, 0.4, 0.6)
	st:ColorsChanged('item_quality')
	eq(T.edge_rgb(slot_backdrop(rows()[1])), '0.20,0.40,0.60', 'the new epic color')
	-- A theme recolor takes the border colors off, then tells modules.
	st:RecolorThemed()
	eq(T.edge_rgb(slot_backdrop(rows()[1])), '0.20,0.40,0.60', 'kept through a recolor')
	local first = rows()[1]
	LF.fire(first.Item, 'OnEnter')
	st:RecolorThemed()
	eq(st:GetState(drawn_child(first), 'hover'), true, 'a card under the mouse keeps its hover through a recolor')
	clean()
end)

test('a profile change follows the new profile\'s toggle and theme', function()
	world('forever')
	open()
	check_skinned('profile one')
	-- The new profile has the popup off, then on with Thin.
	profile.loot.popup.enable = false
	LT:UpdateConfig()
	check_blizzard('profile two')
	profile.loot.popup.enable, profile.loot.popup.theme = true, 'thin'
	LT:UpdateConfig()
	eq(drawn(LF.frame), 'thin,solid,panel', 'profile three')
	eq(LF.frame.NineSlice:GetAlpha(), 0, 'skinned')
	clean()
end)

test('in combat: styled, nothing blocked', function()
	world('forever')
	stub.in_combat, stub.blocked = true, {}
	open()
	check_skinned('in combat')
	LF.change(1, { quality = 5, name = 'Legendary thing' })
	switch('blizzard')
	check_blizzard('Blizzard in combat')
	switch('thick')
	check_skinned('Thick again in combat')
	eq(#stub.blocked, 0, 'nothing blocked')
	stub.in_combat = false
	clean()
end)

test('a window another addon made protected is styled when combat ends, not in it', function()
	world('forever', { protected = true, combat = true })
	open()
	check_blizzard('protected, in combat')
	-- Only the hook on the window's OnShow (HookScript is not a protected
	-- function); nothing styled, and the one call the game blocked is the
	-- fixture's own Show and Resize (Blizzard's secure code shows and sizes it
	-- in combat).
	eq(table.concat(LF.calls, ','), 'HookScript', 'SaftUI only hooked the window in combat')
	local names = {}
	for _, call in ipairs(stub.blocked) do names[#names + 1] = call[2] end
	eq(table.concat(names, ','), 'Show,SetHeight,SetWidth', 'the calls blocked are the fixture\'s Show and Resize')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	-- The fixture's Show was blocked; the game's secure code would have shown
	-- it, so it shows now, and is laid out as it shows.
	LF.show()
	check_skinned('after combat')
	clean()
end)

test('a window with no scroll box is left alone, with no error', function()
	world('forever', { late = true })
	local frame = CreateFrame('Frame', 'LootFrame', UIParent)
	frame:Hide()
	stub.loaded_addons.Blizzard_UIPanels_Game = true
	LT:InitializeLootFrame()
	LT:UpdatePopup()
	LT:UpdateConfig()
	st:FontsChanged()
	st:ColorsChanged('theme')
	eq(#({ frame:GetChildren() }), 0, 'nothing made on it')
	eq(#take_errors(), 0, 'no errors')
end)

test('a part a client lacks skips its step', function()
	for _, omit in ipairs({ { 'NineSlice' }, { 'Bg' }, { 'ClosePanelButton' }, { 'Item.IconBorder' }, { 'QualityStripe' },
			{ 'HighlightNameFrame' }, { 'Item.Count' }, { 'IconQuestTexture' } }) do
		world('retail', { omit = omit })
		open()
		eq(LF.frame.TitleContainer.TitleText:GetFontObject(), st:FontObject(profile.headers.font), omit[1] .. ': the rest is styled')
		local errors = take_errors()
		eq(#errors, 0, omit[1] .. ' missing: no errors ' .. tostring(errors[1]))
	end
end)

test('the addon loading after SaftUI: skinned once it loads', function()
	world('forever', { late = true })
	eq(_G.LootFrame, nil, 'not built yet')
	LF.build({ client = 'forever' })
	stub.loaded_addons.Blizzard_UIPanels_Game = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_UIPanels_Game')
	open()
	check_skinned('loaded late')
	clean()
end)

test('skinned once: repeated updates add no second piece or hook', function()
	world('forever')
	open()
	LT:UpdatePopup()
	LT:UpdateConfig()
	LT:InitializeLootFrame()
	LF.open(SLOTS)
	check_skinned('after repeats')
	eq(#own_children(LF.frame), 1, 'one panel')
	for _, row in ipairs(rows()) do
		eq(#own_children(row), 1, 'one card')
		eq(#own_children(row.Item), 1, 'one slot')
	end
	local before = LF.scroll_box.Update
	LT:UpdatePopup()
	eq(LF.scroll_box.Update, before, 'the scroll box is hooked once')
	clean()
end)

test('the Loot window page: Enable, Theme, Background and Font, each with its reset', function()
	world('forever')
	open()
	LT.rollAnchor = CreateFrame('Frame', nil, UIParent)
	LT.feed = CreateFrame('Frame', nil, UIParent)
	local tree = LT:GetConfigTable()
	LT.rollAnchor, LT.feed = nil, nil
	local group = tree.args.popup
	eq(group.name, 'Loot window', 'the page')
	local general = group.args.general
	local args = general.args
	eq(args.enable.type, 'toggle', 'Enable is a toggle')
	eq(args.enable.name, 'Enable', 'named Enable')
	check(type(args.enable.desc) == 'string' and #args.enable.desc > 20, 'with a description')
	eq(args.position, nil, 'no Position: the window opens where Blizzard says')
	local OM = st.OptionsModel
	local root = { Loot = tree }
	local function Row(key)
		local path = { 'Loot', 'popup', 'general', key }
		local option = args[key]
		return { option = option, path = path, type = option.type, key = key }
	end
	for _, key in ipairs({ 'enable', 'theme', 'background', 'font' }) do
		check(args[key], key .. ' is offered')
		eq(OM.DefaultSource(root, Row(key)), 'derived', key .. ' resets from where the group saves it, with no hand default')
		eq(args[key].default, nil, key .. ' has no default of its own')
		check(not OM.DefaultDiffers(root, Row(key)), key .. ' is at its default')
	end
	local count = 0
	local update = LT.UpdatePopup
	function LT:UpdatePopup() count = count + 1; return update(self) end
	general.set({ 'enable' }, false)
	eq(profile.loot.popup.enable, false, 'Enable writes the profile')
	eq(count, 1, 'and applies at once')
	check_blizzard('Enable unticked')
	check(OM.DefaultDiffers(root, Row('enable')), 'the reset shows while it differs')
	count = 0
	check(OM.DefaultReset(root, Row('enable')), 'its reset runs')
	eq(profile.loot.popup.enable, true, 'its reset puts it back')
	eq(count, 1, 'and applies the window at once, through the row\'s own set')
	check_skinned('reset')
	general.set({ 'theme' }, 'thin')
	check(OM.DefaultDiffers(root, Row('theme')), 'Theme differs')
	OM.DefaultReset(root, Row('theme'))
	eq(profile.loot.popup.theme, 'theme', 'Theme\'s reset')
	general.set({ 'font' }, 'pixel')
	check(OM.DefaultDiffers(root, Row('font')), 'Font differs')
	OM.DefaultReset(root, Row('font'))
	eq(profile.loot.popup.font, st.defaults.loot.popup.font, 'Font\'s reset puts the default back')
	T.check_theme_page({
		group = general, where = 'popup', config = profile.loot.popup,
		path = 'loot.popup', prefix = 'popup: ',
		reads = { { 'theme', 'theme' }, { 'background', 'solid' } },
		writes = { { 'theme', 'thin' }, { 'background', 'transparent' } },
	})
	LT.UpdatePopup = update
end)

test('the defaults: on, following the theme, in Text; no size or position the window does not own', function()
	world('forever')
	local popup = profile.loot.popup
	eq(popup.enable, true, 'on by default')
	eq(popup.theme, 'theme', 'Theme follows the profile\'s')
	eq(popup.background, 'solid', 'Background solid')
	eq(popup.font, 'normal', 'Font is Text')
	for _, key in ipairs({ 'width', 'button_height', 'spacing', 'name_wrap' }) do
		eq(st.defaults.loot.popup[key], nil, key .. ' is Blizzard\'s, not a setting')
	end
	T.check_default(popup, 'thick', 'loot.popup')
end)

test('the source: no write onto Blizzard\'s frames, no Kill, no CreateHeader, no replaced script', function()
	local source = read_saftui_source('SaftUI-Loot/popup.lua')
	local lex = load_test_file('lib/source_lex.lua')
	local _, code = lex.Lex(source)
	for _, word in ipairs({ 'st:Kill', 'CreateHeader', 'nametext', 'LootButton', 'SetScript', 'StripTextures', 'SkinActionButton', ':Hide%(', ':Show%(', 'SetParent' }) do
		check(not code:find(word), 'popup.lua does not use ' .. word)
	end
	local init = read_saftui_source('SaftUI-Loot/init.lua')
	check(init:find('\n\tself:InitializeLootFrame%(%)'), 'OnEnable starts the skin')
	check(not init:find('%-%-%s*self:InitializeLootFrame'), 'and it is not commented out')
end)

test('a currency slot takes its container\'s quality, and a changed one the new quality', function()
	world('forever')
	LF.open({ { kind = 'item', quality = 1, name = 'Currency thing', currency = 123 }, { kind = 'item', quality = 2, name = 'Item' } })
	LF.currencies[123] = 3
	-- Opened before the container's quality was set: the first update reads it.
	LF.update()
	local row = rows()[1]
	local blue = st:QualityColor(3)
	LF.change(1, { kind = 'item', quality = 1, name = 'Currency thing', currency = 123 })
	eq(T.edge_rgb(slot_backdrop(row)), T.text(blue.r, blue.g, blue.b), 'the slot\'s border is the container\'s quality')
	LF.currencies[123] = 4
	LF.change(1, { kind = 'item', quality = 1, name = 'Currency thing', currency = 123 })
	local epic = st:QualityColor(4)
	eq(T.edge_rgb(slot_backdrop(row)), T.text(epic.r, epic.g, epic.b), 'and the changed slot\'s')
	eq(T.rgb(row.Text:GetTextColor()), T.rgb(unpack(LF.QUALITY[4])), 'the name keeps Blizzard\'s color for it')
	-- A container the game has no quality for falls back to the element data (the
	-- quality it opened with), with no error.
	LF.currencies[123] = nil
	LF.change(1, { kind = 'item', quality = 1, name = 'Currency thing', currency = 123 })
	eq(#take_errors(), 0, 'no error without a container quality')
end)

test('a row whose styling errors is retried by the next update and reported once', function()
	world('forever')
	local fail = true
	local draw = st.SetBackdrop
	st.SetBackdrop = function(self, frame, ...)
		if fail then error('styling failed') end
		return draw(self, frame, ...)
	end
	LF.open({ { kind = 'item', quality = 2, name = 'One thing' } })
	LF.update()
	LF.update()
	local errors = take_errors()
	eq(#errors, 1, 'reported once, not on every update')
	local row = rows()[1]
	check(not drawn_child(row), 'the row was not styled')
	fail = false
	LF.update()
	check(drawn_child(row), 'the next update styles it')
	eq(#take_errors(), 0, 'with no more reports')
	st.SetBackdrop = draw
end)
