-- The Cooldown Manager skin (SaftUI-Misc/Skinning/blizzard/Blizzard_CooldownViewer.lua):
--   - every viewer's items look like SaftUI's action buttons in the Skinning
--     page's look: a backdrop of SaftUI's drawn as the action kind with the
--     item as its host, 2px inside the item (where Blizzard's round icon sat),
--     so Blizzard's default Icon Padding leaves a gap between neighbours; the
--     icon inside its border, in BACKGROUND, unmasked and cropped as
--     st:SkinIcon crops (and kept cropped); the Cooldown Manager's frame round
--     it and the round out of range shadow faded; the cooldown and its flash
--     over the icon, a flat swipe and the action bars' countdown fonts; the
--     count in the Skinning font at the icon's corner;
--   - a buff bar's icon the same, and its bar as SaftUI's bars: a backdrop drawn
--     as a bar, a flat orange fill, the background art faded, a flat pip, its
--     texts in the Skinning font; its stack count as tall as its font;
--   - under the Blizzard theme, the action ring a texture of the item (of a
--     bar's icon frame) over the icon and under Blizzard's cooldown, count and
--     debuff border frames and a bar's stack count, none of them moved, and
--     the proc and pandemic glows no lower than the cooldown;
--   - items made before SaftUI loads, after, and in combat (with the viewer
--     protected, as the worst case), each skinned once, and a reused item not
--     skinned again; the addon loading after SaftUI;
--   - a skin that errors is reported, and Blizzard's layout still completes;
--     the item is skinned the next time it's handed out;
--   - nothing written onto Blizzard's frames: every viewer, item, frame and
--     region of the fixture is locked (fixtures/locked_widget.lua);
--   - a theme switch (Thick, Thin, Blizzard, None) and the Skinning page's own
--     Theme, Background and font reaching every item;
--   - Skinning -> Cooldown Manager off leaving Blizzard's look, hooking nothing.
-- On both clients: the Cooldown Manager is the same on each.
--
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and
-- Skinning/blizzard/Blizzard_CooldownViewer.lua, Core's helpers and the theme engine.
-- Blizzard's Cooldown Manager is fixtures/cooldown_viewer.lua.
local T = load_test_file('lib/theme_helpers.lua')

local st, drawn, CV, SK, profile

-- How far inside the item SaftUI's backdrop sits (the skin's ITEM_INSET).
local ITEM_INSET = 2

-- A fresh world on client: SaftUI-Misc's Skinning and the skin loaded, the
-- Cooldown Manager built before SaftUI's modules are enabled (as the game
-- loads Blizzard's addon first) unless opts.late, Cooldown Manager off with
-- opts.off, and before anything is enabled opts.before(), with the viewers.
-- Then the Skinning module and its skins are enabled, as at login.
local function world(client, opts)
	opts = opts or {}
	st = T.client(client)
	drawn = T.watch()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.off then profile.skinning.cooldown_manager = false end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_CooldownViewer.lua')
	SK = st:GetModule('Skinning')
	CV = load_test_file('misc/fixtures/cooldown_viewer.lua')
	if not opts.late then CV.build() end
	if opts.before then opts.before() end
	SK:Enable()
end

-- The frame of SaftUI's behind a holder (the item, or a bar's icon frame) or a
-- bar: the one child of it with a backdrop, which the fixture never makes.
local function backdrop_of(holder)
	for _, child in ipairs({ holder:GetChildren() }) do
		if child.backdropInfo or child.SetBackdrop then return child end
	end
end

local function count_children(frame) return select('#', frame:GetChildren()) end

-- 'n,-n,-n,n': a region n inside another on every side (T.around).
local function inside(n)
	local a, b = string.format('%d', n), string.format('%d', -n)
	return table.concat({ a, b, b, a }, ',')
end

-- The icon's tex coords as SaftUI's crop gives them for a square icon.
local function crop_text()
	local trim = profile.misc.icon_trim
	return T.text(trim, 1 - trim, trim, 1 - trim)
end
local function tex_coord_text(icon)
	local l, t, _, b, r = icon:GetTexCoord()
	return T.text(l, r, t, b)
end

-- The alpha of the Cooldown Manager's frame round an icon, found by its atlas.
local function overlay_alpha(holder)
	for _, region in ipairs({ holder:GetRegions() }) do
		if region.GetAtlas and region:GetAtlas() == CV.OVERLAY then return region:GetAlpha() end
	end
end

-- The point of region named point, as 'relativeTo-is-target,relativePoint,x,y'.
local function anchored(region, point, target)
	for i = 1, region:GetNumPoints() do
		local p, relativeTo, relativePoint, x, y = region:GetPoint(i)
		if p == point then
			return (relativeTo == target and 'target' or 'other') .. ',' .. relativePoint .. ',' .. T.text(x, y)
		end
	end
end

-- Checks an icon item, or a bar's icon frame (holder), drawn in the Skinning
-- look as an action button: the backdrop 2px inside it, the icon inset more
-- by the border's inset.
local function check_icon(holder, icon, inset, where)
	local backdrop = backdrop_of(holder)
	check(backdrop ~= nil, where .. ": a backdrop of SaftUI's")
	if not backdrop then return end
	eq(drawn(backdrop), 'theme,theme,action', where .. ': drawn in the Skinning Theme and Background, as an action button')
	eq(T.around(backdrop, holder), inside(ITEM_INSET), where .. ': the backdrop 2px inside it')
	eq(backdrop:GetFrameLevel(), holder:GetFrameLevel() - 1, where .. ': one level under it')
	eq(T.around(icon, holder), inside(ITEM_INSET + inset), where .. ': the icon inside the border')
	eq(icon:GetDrawLayer(), 'BACKGROUND', where .. ': the icon in BACKGROUND, under the ring')
	eq(icon:GetNumMaskTextures(), 0, where .. ': the round mask is off')
	eq(tex_coord_text(icon), crop_text(), where .. ': cropped as SaftUI crops icons')
	eq(overlay_alpha(holder), 0, where .. ": the Cooldown Manager's frame is faded")
end

-- Checks a cooldown item's cooldown, flash, shadow and count.
local function check_cooldown_parts(item, numbersFont, where)
	local icon = item.Icon
	eq(T.around(item.Cooldown, icon), '0,0,0,0', where .. ': the cooldown over the icon')
	eq(item.Cooldown:GetFrameLevel(), item:GetFrameLevel() + 1, where .. ': the cooldown at its own level')
	eq(stub.state(item.Cooldown).swipe_texture, st.BLANK_TEX, where .. ': a flat swipe')
	eq(item.Cooldown:GetCountdownFontString():GetFontObject(), st:GetFont(numbersFont), where .. ': the countdown in ' .. numbersFont)
	if item.CooldownFlash then
		eq(T.around(item.CooldownFlash, icon), '0,0,0,0', where .. ': the flash over the icon')
		eq(item.OutOfRange:GetAlpha(), 0, where .. ': the round out of range shadow faded (the red tint shows it)')
	end
	local count = item.ChargeCount and item.ChargeCount.Current or item.Applications.Applications
	eq(count:GetFontObject(), st:GetFont(profile.skinning.font), where .. ': the count in the Skinning font')
	eq(anchored(count, 'BOTTOMRIGHT', icon), 'target,BOTTOMRIGHT,-1.00,1.00', where .. ": the count in the icon's corner")
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': items made before SaftUI loads are skinned when it does, as action buttons', function()
		local before = {}
		world(client, { before = function()
			for _, key in ipairs(CV.KEYS) do before[key] = CV[key]:RefreshLayout(2) end
		end })
		for _, item in ipairs(before.Essential) do
			check_icon(item, item.Icon, 2, 'Essential')
			check_cooldown_parts(item, 'pixel_med', 'Essential')
		end
		for _, item in ipairs(before.Utility) do
			check_icon(item, item.Icon, 2, 'Utility')
			check_cooldown_parts(item, 'pixel', 'Utility (30 wide)')
		end
		for _, item in ipairs(before.BuffIcon) do
			check_icon(item, item.Icon, 2, 'BuffIcon')
			check_cooldown_parts(item, 'pixel_med', 'BuffIcon (40 wide)')
		end
		for _, item in ipairs(before.BuffBar) do
			check_icon(item.Icon, item.Icon.Icon, 2, 'BuffBar icon')
		end
		eq(#take_errors(), 0, 'no errors')
	end)
end

-- st:ThemeChanged's steps, as Config:UpdateConfig runs them (tests/actionbars/theme_test.lua's switch).
local function switch(name)
	profile.theme.name = name
	st:RedrawThemed()
	SK:UpdateConfig()
	st:ColorsChanged('theme')
end

test("Blizzard's default Icon Padding leaves a gap between neighbours' borders", function()
	world('forever')
	-- The fixture lays Essential out as Blizzard does at its default Icon
	-- Padding of 2: each item 2 - 4 = -2px from the last, overlapping.
	local items = CV.Essential:RefreshLayout(3)
	eq(items[2]:GetLeft() - items[1]:GetRight(), -2, 'the items overlap by 2px, as Blizzard lays them out')
	for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
		switch(theme)
		for i = 2, 3 do
			local gap = backdrop_of(items[i]):GetLeft() - backdrop_of(items[i - 1]):GetRight()
			eq(gap, 2, theme .. ': a 2px gap between neighbouring backdrops')
		end
	end
	-- The tracked buffs at their default of 5: 5px apart.
	local buffs = CV.BuffIcon:RefreshLayout(2)
	eq(backdrop_of(buffs[2]):GetLeft() - backdrop_of(buffs[1]):GetRight(), 5, 'tracked buffs: 5px apart')
	switch('thick')
	eq(#take_errors(), 0, 'no errors')
end)

test("a buff bar's bar is drawn as SaftUI's bars", function()
	local items
	world('forever', { before = function() items = CV.BuffBar:RefreshLayout(2) end })
	for _, item in ipairs(items) do
		local bar = item.Bar
		local backdrop = backdrop_of(bar)
		check(backdrop ~= nil, "a backdrop of SaftUI's behind the bar")
		eq(drawn(bar), 'theme,theme,bar', 'drawn in the Skinning Theme and Background, as a bar')
		eq(T.offset(backdrop, 'TOPLEFT'), '-2.00,2.00', "Thick's border outside the bar")
		check(backdrop:GetLeft() - backdrop_of(item.Icon):GetRight() >= 2, "a gap between the icon's border and the bar's")
		local fill = bar:GetStatusBarTexture()
		eq(fill:GetTexture(), st.BLANK_TEX, 'a flat fill')
		eq(fill:GetAtlas(), nil, "Blizzard's bar art gone")
		eq(T.text(bar:GetStatusBarColor()), T.text(CV.BAR_COLOR[1], CV.BAR_COLOR[2], CV.BAR_COLOR[3], 1), "in Blizzard's orange")
		eq(bar.BarBG:GetAlpha(), 0, "Blizzard's bar background faded")
		local pip = bar.Pip
		eq(pip:GetTexture(), st.BLANK_TEX, 'a flat pip')
		eq(pip:GetWidth(), 2, '2 wide')
		eq(pip:GetNumPoints(), 2, 'anchored top and bottom only')
		eq(anchored(pip, 'TOP', fill), 'target,TOPRIGHT,0.00,0.00', "its top on the fill's right end")
		eq(anchored(pip, 'BOTTOM', fill), 'target,BOTTOMRIGHT,0.00,0.00', 'its bottom too')
		eq(bar.Name:GetFontObject(), st:GetFont('pixel'), 'the name in the Skinning font')
		eq(bar.Duration:GetFontObject(), st:GetFont('pixel'), 'the duration in the Skinning font')
		local count = item.Icon.Applications
		eq(count:GetFontObject(), st:GetFont('pixel'), 'the stack count in the Skinning font')
		eq(anchored(count, 'BOTTOMRIGHT', item.Icon.Icon), 'target,BOTTOMRIGHT,-1.00,1.00', "the stack count in the icon's corner")
		eq(count:GetParent(), item.Icon, 'the stack count stays in the icon frame')
		eq(count:GetHeight(), 10, "as tall as Pixel's 10")
	end

	-- Blizzard's template makes the stack count 32 by 10: a taller Skinning
	-- font gets a count as tall as it.
	profile.skinning.font = 'normal'
	SK:UpdateConfig()
	local _, size = st:GetFont('normal'):GetFont()
	check(size > 10, "Normal is taller than Blizzard's 10")
	eq(items[1].Icon.Applications:GetHeight(), size, 'the stack count as tall as Normal')
	profile.skinning.font = 'pixel'
	SK:UpdateConfig()
	eq(items[1].Icon.Applications:GetHeight(), 10, 'and back')
	eq(#take_errors(), 0, 'no errors')
end)

test('items made after SaftUI loads are skinned, in combat too, each once, and a reused one is left as it is', function()
	world('forever')
	-- Counted after T.watch's wrapper: each draw, by the frame drawn.
	local draws = {}
	local real = st.SetTemplate
	st.SetTemplate = function(self, frame, ...)
		draws[frame] = (draws[frame] or 0) + 1
		return real(self, frame, ...)
	end
	local function draws_of(item) return draws[backdrop_of(item)] end

	local first = CV.Utility:RefreshLayout(3)
	for _, item in ipairs(first) do
		check_icon(item, item.Icon, 2, 'made after load')
		eq(draws_of(item), 1, 'drawn once')
		-- The template's cooldown, charges and flash, and SaftUI's backdrop.
		eq(count_children(item), 4, "one frame of SaftUI's on it")
	end

	-- Blizzard re-lays the viewer out: every item released and acquired again
	-- (the pool hands the same ones back), and one more made.
	local again = CV.Utility:RefreshLayout(4)
	for i = 1, 3 do
		local item = again[i]
		local reused = false
		for _, old in ipairs(first) do reused = reused or old == item end
		check(reused, 'the pool hands back an item it made before')
		eq(draws_of(item), 1, 'a reused item is not drawn again')
		eq(count_children(item), 4, 'and gets nothing new')
	end
	check_icon(again[4], again[4].Icon, 2, 'a new one')
	eq(draws_of(again[4]), 1, 'the new one drawn once')

	-- In combat, with the viewer protected (through an anchor, perhaps: the worst
	-- case), Blizzard makes more: they're skinned at once, and nothing of the
	-- viewer's is touched.
	rawset(CV.Utility, 'IsProtected', function() return true, true end)
	stub.in_combat = true
	local fight = CV.Utility:RefreshLayout(6)
	for _, item in ipairs(fight) do
		check_icon(item, item.Icon, 2, 'made in combat')
		eq(draws_of(item), 1, 'drawn once')
	end
	eq(#stub.blocked, 0, 'nothing blocked')
	stub.in_combat = false
	rawset(CV.Utility, 'IsProtected', nil)

	-- Blizzard resets an icon's tex coords: the crop comes back.
	fight[1].Icon:SetTexCoord(0, 1, 0, 1)
	eq(tex_coord_text(fight[1].Icon), crop_text(), "Blizzard's reset tex coords are cropped again")
	eq(#take_errors(), 0, 'no errors')
end)

test("a skin that errors is reported, Blizzard's layout still completes, and the item is skinned next time", function()
	-- The skin breaks while SaftUI loads, on items the viewer shows already.
	local before
	local realSkinIcon
	world('forever', { before = function()
		before = CV.Essential:RefreshLayout(2)
		realSkinIcon = st.SkinIcon
		st.SkinIcon = function() error('the skin broke') end
	end })
	eq(#take_errors(), 2, 'an error reported for each item shown at load')

	-- And while Blizzard lays a viewer out: the hooked call returns, every item
	-- is acquired, handed out and laid out as Blizzard does.
	local items = CV.Utility:RefreshLayout(3)
	eq(#items, 3, 'every item acquired')
	eq(#take_errors(), 3, 'an error reported for each item')
	for i, item in ipairs(items) do
		check(item:IsShown(), "Blizzard's OnAcquireItemFrame ran: shown")
		eq(item.viewerFrame, CV.Utility, 'and given its viewer')
		eq(item:GetNumPoints(), 1, "and Blizzard's layout placed it")
		eq(item.layoutIndex, i, 'in its place')
	end

	-- Fixed, the next layout skins them, with no second backdrop.
	st.SkinIcon = realSkinIcon
	items = CV.Utility:RefreshLayout(3)
	for _, item in ipairs(items) do
		check_icon(item, item.Icon, 2, 'skinned the next time')
		eq(count_children(item), 4, "still one frame of SaftUI's on it")
	end
	before = CV.Essential:RefreshLayout(2)
	check_icon(before[1], before[1].Icon, 2, 'an item first shown at load, the next time')
	eq(#take_errors(), 0, 'no more errors')
end)

test('the Cooldown Manager loading after SaftUI is skinned when it loads', function()
	world('forever', { late = true })
	stub.fire_event('ADDON_LOADED', 'Blizzard_SomethingElse')
	CV.build()
	stub.fire_event('ADDON_LOADED', 'Blizzard_CooldownViewer')
	local items = CV.Essential:RefreshLayout(2)
	check_icon(items[1], items[1].Icon, 2, 'after its ADDON_LOADED')
	eq(#take_errors(), 0, 'no errors')
end)

test("under Blizzard the ring is the item's, over the icon and under Blizzard's frames and glows", function()
	world('forever')
	local item = CV.Essential:RefreshLayout(1)[1]
	local buff = CV.BuffIcon:RefreshLayout(1)[1]
	local barItem = CV.BuffBar:RefreshLayout(1)[1]
	switch('blizzard')

	local level = item:GetFrameLevel()
	local ring = st.ThemeArt.Get(backdrop_of(item)).over.Ring
	check(ring ~= nil and ring:IsShown(), "Blizzard's action ring is drawn")
	eq(ring:GetParent(), item, 'a texture of the item (the host), not of a frame over it')
	eq(select(1, ring:GetDrawLayer()), 'ARTWORK', 'in ARTWORK')
	eq(item.Icon:GetDrawLayer(), 'BACKGROUND', 'over the icon, in BACKGROUND')
	for _, key in ipairs({ 'Cooldown', 'CooldownFlash', 'ChargeCount' }) do
		eq(item[key]:GetFrameLevel(), level + 1, key .. ': a frame over the item, where Blizzard made it')
	end
	for _, key in ipairs({ 'Cooldown', 'Applications', 'DebuffBorder' }) do
		eq(buff[key]:GetFrameLevel(), buff:GetFrameLevel() + 1, "a tracked buff's " .. key .. ': where Blizzard made it')
	end

	-- The proc and pandemic glows, as Blizzard makes them: no lower than the
	-- cooldown, so its swipe doesn't dim them.
	local alert, pandemic = CV.show_alert(item), CV.show_pandemic(item)
	check(alert:GetFrameLevel() >= item.Cooldown:GetFrameLevel(), 'the proc glow is no lower than the cooldown')
	check(pandemic:GetFrameLevel() >= item.Cooldown:GetFrameLevel(), 'the pandemic glow is no lower than the cooldown')

	-- A bar's icon: the ring a texture of its icon frame, under the stack count
	-- Blizzard put there.
	local barRing = st.ThemeArt.Get(backdrop_of(barItem.Icon)).over.Ring
	eq(barRing:GetParent(), barItem.Icon, "a bar's ring a texture of its icon frame")
	eq(barItem.Icon.Icon:GetDrawLayer(), 'BACKGROUND', 'over its icon')
	eq(barItem.Icon.Applications:GetParent(), barItem.Icon, 'its stack count where Blizzard put it')
	eq(barItem.Icon.Applications:GetDrawLayer(), 'OVERLAY', 'in OVERLAY, over the ring')

	switch('thick')
	check(not ring:IsShown(), 'Thick: no ring')
	eq(#take_errors(), 0, 'no errors')
end)

test('a theme switch and the Skinning page reach every item', function()
	world('forever')
	local icons = CV.Essential:RefreshLayout(2)
	local bars = CV.BuffBar:RefreshLayout(1)
	local item, barItem = icons[1], bars[1]
	local backdrop, barBackdrop = backdrop_of(item), backdrop_of(barItem.Bar)

	switch('thin')
	eq(T.inset(backdrop), 1, "Thin's border")
	eq(T.around(backdrop, item), inside(ITEM_INSET), 'the backdrop still 2px inside the item')
	eq(T.around(item.Icon, item), inside(ITEM_INSET + 1), "the icon inside Thin's border")
	eq(T.offset(barBackdrop, 'TOPLEFT'), '-1.00,1.00', "the bar's backdrop at Thin's border")

	switch('blizzard')
	local inset = st:ThemeInset('blizzard', 'theme', 'action')
	eq(T.around(backdrop, item), inside(ITEM_INSET), 'under Blizzard too')
	eq(T.around(item.Icon, item), inside(ITEM_INSET + inset), "the icon inside the action art's inset")
	eq(T.over(backdrop), 'Ring=UI-HUD-ActionBar-IconFrame', "Blizzard's action button ring over the icon's edge")
	eq(T.art(backdrop), 'SlotArt=UI-HUD-ActionBar-IconFrame-Slot,SlotBackground=UI-HUD-ActionBar-IconFrame-Background',
		"and its slot art behind the icon")
	eq(T.over(backdrop_of(barItem.Icon)), 'Ring=UI-HUD-ActionBar-IconFrame', "the bar's icon too")

	switch('thick')
	eq(T.inset(backdrop), 2, "Thick's border again")
	eq(T.over(backdrop), '', 'no ring left')
	eq(T.around(item.Icon, item), inside(ITEM_INSET + 2), "the icon inside Thick's border")

	-- The Skinning page's own Theme, Background and font, at once.
	profile.skinning.theme, profile.skinning.background, profile.skinning.font = 'none', 'solid', 'normal'
	SK:UpdateConfig()
	eq(drawn(backdrop), 'none,solid,action', 'the Skinning page reaches the items')
	eq(backdrop.backdropInfo, nil, 'None: bare')
	eq(T.around(item.Icon, item), inside(ITEM_INSET), 'None: the icon where the backdrop would be')
	eq(item.ChargeCount.Current:GetFontObject(), st:GetFont('normal'), 'the count in the new font')
	eq(barItem.Bar.Name:GetFontObject(), st:GetFont('normal'), "the bar's name too")
	profile.skinning.theme, profile.skinning.font = 'thin', 'pixel'
	SK:UpdateConfig()
	eq(T.inset(backdrop), 1, 'Thin from the Skinning page')
	eq(T.around(item.Icon, item), inside(ITEM_INSET + 1), 'the icon inside it')

	-- An item first made under None is drawn when a theme comes back.
	profile.skinning.theme = 'none'
	SK:UpdateConfig()
	local later = CV.Utility:RefreshLayout(1)[1]
	eq(backdrop_of(later).backdropInfo, nil, 'made under None: bare')
	eq(T.around(later.Icon, later), inside(ITEM_INSET), 'the icon where the backdrop would be')
	profile.skinning.theme = 'theme'
	SK:UpdateConfig()
	eq(T.inset(backdrop_of(later)), 2, "Thick's border once the theme is back")
	eq(T.around(later.Icon, later), inside(ITEM_INSET + 2), "the icon inside Thick's border")
	eq(#take_errors(), 0, 'no errors')
end)

test("Cooldown Manager off leaves Blizzard's look and hooks nothing", function()
	local items, hooks = {}, {}
	world('forever', { off = true, before = function()
		for _, key in ipairs(CV.KEYS) do
			hooks[key] = rawget(CV[key], 'OnAcquireItemFrame')
			items[key] = CV[key]:RefreshLayout(2)
		end
	end })
	for _, key in ipairs(CV.KEYS) do
		eq(rawget(CV[key], 'OnAcquireItemFrame'), hooks[key], key .. ': not hooked')
	end
	local later = CV.Essential:RefreshLayout(3)
	for _, item in ipairs(later) do
		eq(backdrop_of(item), nil, "no backdrop of SaftUI's")
		eq(item.Icon:GetNumMaskTextures(), 1, 'the round mask stays')
		eq(tex_coord_text(item.Icon), T.text(0, 1, 0, 1), 'the whole icon shows')
		eq(T.around(item.Icon, item), '0,0,0,0', 'filling the item')
		eq(item.Icon:GetDrawLayer(), 'ARTWORK', "in Blizzard's layer")
		eq(overlay_alpha(item), 1, "the Cooldown Manager's frame shows")
		eq(item.OutOfRange:GetAlpha(), 1, 'and its out of range shadow')
		eq(stub.state(item.Cooldown).swipe_texture, CV.SWIPE, "Blizzard's round swipe")
		eq(item.Cooldown:GetCountdownFontString():GetFontObject(), _G.GameFontHighlightHugeOutline, "Blizzard's countdown font")
	end
	local bar = items.BuffBar[1].Bar
	eq(bar:GetStatusBarTexture():GetAtlas(), CV.BAR, "the bar keeps Blizzard's art")
	eq(bar.BarBG:GetAlpha(), 1, 'and its background')
	-- A profile update with nothing skinned does nothing.
	SK:UpdateConfig()
	eq(backdrop_of(later[1]), nil, 'still nothing after a profile update')
	eq(#take_errors(), 0, 'no errors')
end)
