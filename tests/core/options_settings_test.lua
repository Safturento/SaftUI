-- /sui under the Blizzard theme as Blizzard's Settings window
-- (SaftUI-Core/Config/optionswindow.lua, with themeart.lua's optionswindow
-- art), on both clients: the window drawn as a window (the metal, its title
-- bar reading "SaftUI Options", the close button in the metal's socket), the
-- inner frame over the sidebar and the main column, the sidebar as wide as
-- the divider drawn into the inner frame, the footer under it across the
-- window, and the two layouts (OW.LAYOUT.own, OW.LAYOUT.blizzard) a theme or
-- profile switch moves between with the page, its scroll and a fill row kept.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (core/config_helpers.lua),
-- the options model, widgets, body and window, on the client world(client)
-- names. The pages are synthetic modules registered in world(). The window
-- re-renders on its ticker's OnUpdate, which the stubs never run by
-- themselves, so tick() fires it.
local T = load_test_file('lib/theme_helpers.lua')

local CLIENTS = { 'forever', 'retail' }

local st, OW, W, drawn
-- The heights the Fill page's row was given (its SetHeight), in order.
local fillHeights

-- One small page, as options_window_test.lua's SmallModule.
local function SmallModule(key, name, category)
	local module = st:NewModule(key)
	function module:GetConfigTable()
		return {
			name = name, type = 'group', category = category,
			args = { general = { name = 'General', type = 'group', args = {
				on = { type = 'toggle', name = name .. ' on', get = function() return true end, set = function() end },
			} } },
		}
	end
end

local function toggle(name, order, size)
	return { type = 'toggle', name = name, order = order, size = size, get = function() return true end, set = function() end }
end

-- A fresh world on client, 'forever' or 'retail', with /sui's pages: a small
-- page in each of Frames, Combat, Info and none; Long, three titled sections
-- of ten toggles, each on a line of its own, so it scrolls well past a view;
-- Tabs, two tabs, the first with two subtabs; Fill, a fill row.
local function world(client)
	reset_world()
	stub.interface = client == 'forever' and 16001 or 120000
	load_saftui('SaftUI-Core/constants.lua')
	load_test_file('core/config_helpers.lua')
	for _, f in ipairs({ 'optionsmodel', 'optionswidgets', 'optionsbody', 'optionswindow' }) do
		load_saftui('SaftUI-Core/Config/' .. f .. '.lua')
	end
	st, OW, W = SaftUI, SaftUI.OptionsWindow, SaftUI.OptionsWidgets
	drawn = T.watch()

	SmallModule('Chat', 'Chat', 'Frames')
	SmallModule('Auras', 'Auras', 'Combat')
	SmallModule('Loot', 'Loot', 'Info')
	SmallModule('Zeta', 'Zeta', nil)

	local long = st:NewModule('Long')
	function long:GetConfigTable()
		local args = {}
		for s = 1, 3 do
			local section = { order = s, type = 'group', inline = true, name = 'Section ' .. s, args = {} }
			for i = 1, 10 do section.args['t' .. i] = toggle('Toggle ' .. i, i, i <= 8 and 'wide' or nil) end
			args['s' .. s] = section
		end
		return { name = 'Long', type = 'group', category = 'Frames', args = args }
	end

	local tabs = st:NewModule('Tabs')
	function tabs:GetConfigTable()
		return {
			name = 'Tabs', type = 'group', category = 'Frames', childGroups = 'tab',
			args = {
				one = { order = 1, name = 'One', type = 'group', childGroups = 'tab', args = {
					a = { order = 1, name = 'A', type = 'group', args = { on = toggle('A on', 1) } },
					b = { order = 2, name = 'B', type = 'group', args = { on = toggle('B on', 1) } },
				} },
				two = { order = 2, name = 'Two', type = 'group', args = { on = toggle('Two on', 1) } },
			},
		}
	end

	fillHeights = {}
	W.Define('settingsfill', {
		bare = true,
		fill = true,
		minHeight = 100,
		build = function(w)
			w.frame = CreateFrame('Frame', nil, UIParent)
			w.frame:SetSize(10, 10)
		end,
		methods = {
			SetWidth = function(self, width) self.frame:SetWidth(width) end,
			SetHeight = function(self, height)
				self.frame:SetHeight(height)
				fillHeights[#fillHeights + 1] = height
			end,
			Refresh = function() end,
		},
	})
	local fill = st:NewModule('Fill')
	function fill:GetConfigTable()
		return {
			name = 'Fill', type = 'group', category = 'Info',
			args = { fill = { type = 'settingsfill', name = 'Fill', desc = 'A fill row.', size = 'wide', order = 1 } },
		}
	end
end

------------------------------------------------------------------ helpers

-- One frame passes on the window's clock (none before the window is built).
local function tick()
	local ticker = OW.GetFrames().ticker
	if ticker then stub.fire_script(ticker, 'OnUpdate', 0.01) end
end

-- SaftUI's theme switched, as the Theme tab does it, and the window's next frame.
local function switch(name)
	st.config.profile.theme.name = name
	st:ThemeChanged()
	tick()
end

-- Where a region sits in the window: x and y from its top left, and its size.
local function at(f)
	local w = OW.GetFrames().window
	return ('%d,%d %dx%d'):format(f:GetLeft() - w:GetLeft(), w:GetTop() - f:GetTop(), f:GetWidth(), f:GetHeight())
end

-- A region's first anchor, 'POINT rel RELPOINT x,y': rel named as the
-- window's frames (window, main, search, header), from names, or 'frame' for
-- the region's parent.
local function anchor(region, names)
	local F = OW.GetFrames()
	local known = { [F.window] = 'window', [F.main] = 'main', [F.search] = 'search', [F.header] = 'header' }
	for frame, name in pairs(names or {}) do known[frame] = name end
	local point, rel, relPoint, x, y = region:GetPoint(1)
	local name = known[rel] or (rel == region:GetParent() and 'frame') or tostring(rel)
	return ('%s %s %s %d,%d'):format(tostring(point), name, tostring(relPoint), x, y)
end

-- A font string's text color, 'r,g,b' to two places.
local function rgb(fs)
	local r, g, b = fs:GetTextColor()
	return ('%.2f,%.2f,%.2f'):format(r, g, b)
end

local function size_of(frame) return frame:GetWidth() .. 'x' .. frame:GetHeight() end

-- Where a region's edges sit from another's, 'left,top,right,bottom', in whole pixels.
local function around(outer, inner)
	local function px(a, b) return string.format('%d', math.floor(a - b + 0.5)) end
	return table.concat({ px(outer:GetLeft(), inner:GetLeft()), px(outer:GetTop(), inner:GetTop()),
		px(outer:GetRight(), inner:GetRight()), px(outer:GetBottom(), inner:GetBottom()) }, ',')
end

-- How far in from frame's edges a region sits, 'left,top,right,bottom'.
local function insets(region, frame)
	local function px(a) return string.format('%d', math.floor(a + 0.5)) end
	return table.concat({ px(region:GetLeft() - frame:GetLeft()), px(frame:GetTop() - region:GetTop()),
		px(frame:GetRight() - region:GetRight()), px(region:GetBottom() - frame:GetBottom()) }, ',')
end

-- The atlases shown on a frame (shown and not see-through), sorted and comma-joined.
local function atlases_of(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 and region:GetAtlas() then
			out[#out + 1] = region:GetAtlas()
		end
	end
	table.sort(out)
	return table.concat(out, ',')
end

-- The drawn row of the page by its option key.
local function cell(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

-- The metal's eight pieces as T.art lists them (theme_blizzard_windows_test.lua's METAL).
local METAL = table.concat({
	'BottomEdge=_UI-Frame-Metal-EdgeBottom',
	'BottomLeftCorner=UI-Frame-Metal-CornerBottomLeft',
	'BottomRightCorner=UI-Frame-Metal-CornerBottomRight',
	'LeftEdge=!UI-Frame-Metal-EdgeLeft',
	'RightEdge=!UI-Frame-Metal-EdgeRight',
	'TopEdge=_UI-Frame-Metal-EdgeTop',
	'TopLeftCorner=UI-Frame-Metal-CornerTopLeft',
	'TopRightCorner=UI-Frame-Metal-CornerTopRight',
}, ',')

-- /sui's frames where options_window_test.lua's Task 1 case pins them under
-- Thick and Thin, on the Loot page (one tab: no tab row).
local function check_own(where)
	local F = OW.GetFrames()
	eq(at(F.window), '0,0 1040x700', where)
	eq(at(F.side), '2,2 208x696', where .. ': the sidebar')
	eq(at(F.brand), '2,2 207x73', where .. ': the brand')
	eq(at(F.actionsFrame), '2,75 207x44', where .. ': the actions')
	eq(at(F.navFrame), '2,120 207x547', where .. ': the nav')
	eq(at(F.foot), '2,668 207x30', where .. ": the profile's name")
	eq(at(F.main), '210,2 828x696', where .. ': the main column')
	eq(at(F.title):match('^%d+,%d+'), '238,22', where .. ': the title')
	eq(at(F.close), '1000,14 24x24', where .. ': the close X')
	eq(at(F.search), '822,83 190x24', where .. ': the search box')
	eq(at(F.tabLine), '210,113 828x1', where .. ': the tab line')
	eq(at(F.body), '238,113 774x539', where .. ': the body')
	eq(at(F.footer), '210,652 828x46', where .. ': the footer')
	eq(table.concat(stub.state(F.sideFill).color_texture, ','), '0.09,0.09,0.09,1', where .. ': the sidebar fill')
	for _, l in ipairs(F.sideLines) do check(l:IsShown(), where .. ': a sidebar line shown') end
	eq(F.window.backdropInfo.insets.left, 2, where .. ': the border inset')
	for _, item in ipairs(F.nav) do
		if item.key then eq(item:GetWidth(), 207, where .. ': a nav entry') end
	end
end

------------------------------------------------------------------ the window

test('/sui under Blizzard: the metal, its title bar and the close button in the socket', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F, close = OW.GetFrames(), st.ThemeArt.Close()
		eq(drawn(F.window), 'theme,solid,window', client)
		eq(T.art(F.window), METAL, client .. ': the metal')
		eq(at(F.window), '0,0 1110x728', client)
		eq(F.titleText:GetText(), 'SaftUI Options', client)
		eq(F.titleText:GetFontObject(), st:GetFont(st.config.profile.headers.font), client .. ': the header font')
		local _, cy = F.titleText:GetCenter()
		eq(F.window:GetTop() - cy, st.ThemeArt.TitleHeight() - 10, client .. ': centred on the title strip')
		eq(at(F.titleBar), ('0,0 1110x%d'):format(st.ThemeArt.TitleHeight()), client .. ': the drag strip is the title bar')
		check(F.titleBar:IsShown() and F.titleText:IsShown(), client .. ': the title bar shown')
		eq(anchor(F.close), ('TOPRIGHT window TOPRIGHT %d,%d'):format(close.x, close.y), client .. ': in the socket')
		eq(F.close:GetWidth(), close.size, client .. ": Blizzard's close button")
		check(F.close:GetFrameLevel() > F.titleBar:GetFrameLevel(), client .. ': over the title bar, so a click reaches it')
		check(not F.brand:IsShown(), client .. ': no brand')

		-- The title bar moves the window, as the brand does under Thick.
		stub.fire_script(F.titleBar, 'OnDragStart')
		eq(stub.state(F.window).moving, true, client .. ': dragging the title bar moves the window')
		F.window:ClearAllPoints()
		F.window:SetPoint('CENTER', UIParent, 'CENTER', 120, -40) -- where the mouse left it
		stub.fire_script(F.titleBar, 'OnDragStop')
		eq(stub.state(F.window).moving, false, client .. ': stopped')
		local saved = st.config.global.optionsWindow
		eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'CENTER 120 -40', client .. ': where it was left is saved')

		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('/sui under Blizzard: the inner frame, the sidebar on its divider, the footer under it', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		eq(F.inner:GetAtlas(), 'Options_InnerFrame', client); check(F.inner:IsShown(), client .. ': the inner frame shown')
		eq(at(F.inner), '17,28 1076x654', client .. ': the inner frame')
		eq(at(F.side), '17,28 242x654', client .. ': the sidebar')
		eq(F.side:GetWidth(), OW.SidebarWidth(1076), client .. ': the sidebar ends on the drawn divider')
		eq(at(F.actionsFrame), '17,28 241x44', client .. ': the actions at the sidebar top')
		eq(at(F.foot), '17,652 241x30', client .. ": the profile's name at the sidebar's bottom, inside the inner frame")
		eq(at(F.main), '259,28 834x654', client .. ': the main column')
		eq(at(F.body), '287,139 781x539', client .. ': the body: 28 in, the 774 content plus 7, as tall as under Thick')
		eq(F.content:GetWidth(), 774, client .. ': the content')
		eq(at(F.footer), '0,682 1110x46', client .. ': the footer across the window, under the inner frame')
		eq(at(F.reloadButton):match('^%d+'), '16', client .. ': Reload UI 16 in')
		eq(F.window:GetBottom() + 16, F.reloadButton:GetBottom(), client .. ': and 16 up')
		eq(F.window:GetRight() - 16, F.closeButton:GetRight(), client .. ': Close 16 in')
		eq(F.window:GetBottom() + 16, F.closeButton:GetBottom(), client .. ': and 16 up')
		eq(F.search:GetRight() - F.content:GetLeft(), 774, client .. ": the search box's right on the content's")
		local items = 0
		for _, item in ipairs(F.nav) do
			if item.key then
				items = items + 1
				eq(item:GetWidth(), 226, client .. ': a nav entry')
			end
		end
		check(items > 0, client .. ': nav entries drawn')
		eq(F.layout, OW.LAYOUT.blizzard, client .. ': the layout in use')
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('OW.LAYOUT: Blizzard sizes follow the divider and keep the body', function()
	world('forever')
	local b = OW.LAYOUT.blizzard
	eq(b.width, 2 * b.innerX + b.sideWidth + 28 + 774 + b.rightPad)
	eq(b.sideWidth, OW.SidebarWidth(b.width - 2 * b.innerX))
	eq(b.width % 2 + b.height % 2, 0, 'even: the window is anchored by its centre')
	eq(b.height - b.innerTop - b.footer - 111 - b.bodyBottom, 700 - 4 - 46 - 111, 'the body as tall as today')
	eq(b.mainLeft, b.innerX + b.sideWidth, 'the main column starts at the sidebar\'s end')
	eq(b.navWidth, b.sideWidth - 16, 'the nav rows: the sidebar less room for its bar')
	local look = st.ThemeArt.Control('optionswindow')
	eq(look.inner .. ' ' .. look.width .. ' ' .. look.divider, 'Options_InnerFrame 886 199', "the inner frame's art and its divider")
	eq(OW.SidebarWidth(886), 199, 'at its own width, on the divider')

	local o = OW.LAYOUT.own
	eq(o.width .. 'x' .. o.height, '1040x700', "own: today's window")
	eq(o.mainLeft + 28 + 774 + o.rightPad + o.mainRight, o.width, "own: today's main column")
end)

------------------------------------------------------------------ switching

test('Thick to Blizzard to Thick, and a profile switch, re-lay /sui out', function()
	world('forever')
	switch('thick')
	st.Config:Open('Loot')
	local F = OW.GetFrames()
	check_own('Thick')
	eq(F.layout, OW.LAYOUT.own, 'Thick: the own layout')
	check(not F.inner:IsShown() and not F.titleBar:IsShown(), 'Thick: no inner frame or title bar')

	switch('blizzard')
	eq(at(F.window), '0,0 1110x728', 'Blizzard')
	eq(at(F.side), '17,28 242x654', 'Blizzard: the sidebar')
	check(F.inner:IsShown() and F.titleBar:IsShown(), 'Blizzard: the inner frame and title bar')

	switch('thick')
	check_own('Thick again')
	check(not F.inner:IsShown(), 'Thick again: no inner frame')
	check(not F.titleBar:IsShown(), 'Thick again: no title bar')
	check(F.brand:IsShown(), 'Thick again: the brand')
	eq(T.art(F.window), '', 'Thick again: no metal')
	eq(drawn(F.window), 'theme,solid,window', 'Thick again: still drawn as a window')
	eq(T.inset(F.window), 2, "Thick again: Thick's border")
	eq(anchor(F.close), 'TOPRIGHT window TOPRIGHT -16,-14', 'Thick again: the close X at its place')

	-- A profile switch to a Blizzard profile and back.
	local first = st.config:GetCurrentProfile()
	SaftUI_DB.profiles.Blue = { theme = { name = 'blizzard' } }
	st.config:SetProfile('Blue')
	tick()
	eq(F.layout, OW.LAYOUT.blizzard, 'the Blizzard profile: the Blizzard layout')
	eq(at(F.window), '0,0 1110x728', 'the Blizzard profile')
	eq(at(F.main), '259,28 834x654', 'the Blizzard profile: the main column')
	eq(T.art(F.window), METAL, 'the Blizzard profile: the metal')
	check(F.inner:IsShown() and F.titleBar:IsShown() and not F.brand:IsShown(), 'the Blizzard profile: inner frame and title bar, no brand')
	st.config:SetProfile(first)
	tick()
	check_own('back to the first profile')
	eq(T.art(F.window), '', 'back to the first profile: no metal')
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

test('a switch with /sui scrolled or on a fill page', function()
	world('forever')
	switch('thick')
	st.Config:Open('Long')
	local F = OW.GetFrames()
	for _ = 1, 3 do stub.fire_script(F.body, 'OnMouseWheel', -1) end
	eq(F.body:GetVerticalScroll(), 3 * 68, 'three turns down')
	check(F.content:GetHeight() > F.body:GetHeight() + 3 * 68, 'well inside what it holds')

	switch('blizzard')
	eq(OW:GetState().page, 'Long', 'Blizzard: the same page')
	eq(F.body:GetVerticalScroll(), 3 * 68, 'Blizzard: the scroll kept')
	eq(F.body:GetHeight(), 539, 'Blizzard: the body still 539 tall')
	switch('thick')
	eq(OW:GetState().page, 'Long', 'Thick again: the same page')
	eq(F.body:GetVerticalScroll(), 3 * 68, 'Thick again: the scroll kept')
	eq(F.body:GetHeight(), 539, 'Thick again: 539 tall')

	-- A fill page: its row fills the view under each look, and the body
	-- reaches over its bar's place.
	st.Config:Open('Fill')
	local thick = fillHeights[#fillHeights]
	eq(thick, cell('fill').height - 12, 'Thick: the row told its cell less 12')
	eq(F.content:GetHeight(), F.body:GetHeight(), 'Thick: the drawn height is the view')
	eq(F.body:GetRight() - F.content:GetRight(), 13, 'Thick: 13 past the content')

	local count = #fillHeights
	switch('blizzard')
	check(#fillHeights > count, 'Blizzard: the fill row was told its height again')
	eq(OW:GetState().page, 'Fill', 'Blizzard: the same page')
	eq(fillHeights[#fillHeights], thick, 'Blizzard: as tall, the body as tall')
	eq(fillHeights[#fillHeights], cell('fill').height - 12, 'Blizzard: its cell less 12')
	eq(F.content:GetHeight(), F.body:GetHeight(), 'Blizzard: the drawn height is the view')
	eq(F.body:GetRight() - F.content:GetRight(), 25, 'Blizzard: 25 past the content')

	count = #fillHeights
	switch('thick')
	check(#fillHeights > count, 'Thick again: the fill row was told its height again')
	eq(fillHeights[#fillHeights], thick, 'Thick again: as tall')
	eq(F.body:GetRight() - F.content:GetRight(), 13, 'Thick again: 13 past the content')
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the dressing

-- The group headers' texts with their banners' atlases, in order.
local function banners()
	local out = {}
	for _, entry in ipairs(OW.GetFrames().nav) do
		if entry.group then out[#out + 1] = entry.text:GetText() .. '=' .. tostring(entry.banner:IsShown() and entry.banner:GetAtlas()) end
	end
	return table.concat(out, ',')
end

-- The first sidebar header, and the entry for a page.
local function first_header()
	for _, entry in ipairs(OW.GetFrames().nav) do
		if entry.group then return entry end
	end
end
local function entry_of(key)
	for _, entry in ipairs(OW.GetFrames().nav) do
		if entry.key == key then return entry end
	end
end

-- The body's shown line textures as wide as the body's content and 1 tall,
-- and those 1 wide (the halves' dividers).
local function lines(wide)
	local F, n = OW.GetFrames(), 0
	for _, region in ipairs({ F.content:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and stub.state(region).color_texture then
			if wide and region:GetWidth() == F.content:GetWidth() and region:GetHeight() == 1 then n = n + 1 end
			if not wide and region:GetWidth() == 1 then n = n + 1 end
		end
	end
	return n
end

test('the sidebar under Blizzard: no fill or lines, banners by index, gold and white names', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Chat')
		local F = OW.GetFrames()
		check(not F.sideFill:IsShown(), client .. ': no sidebar fill')
		for _, l in ipairs(F.sideLines) do check(not l:IsShown(), client .. ': no sidebar line') end
		eq(banners(), 'Frames=Options_CategoryHeader_1,Combat=Options_CategoryHeader_2,Info=Options_CategoryHeader_3,Other=Options_CategoryHeader_1', client)
		eq(OW.BannerAtlas(5), 'Options_CategoryHeader_2', client .. ': the fifth wraps to the second')
		local header, active, other = first_header(), entry_of('Chat'), entry_of('Auras')
		eq(header:GetHeight(), 30, client)
		eq(insets(header.banner, header):match('^0,0'), '0,0', client)
		eq(size_of(header.banner), '199x144', client)
		eq(anchor(header.text, { [header] = 'header' }), 'LEFT header LEFT 20,-1', client)
		eq(rgb(header.text), '1.00,1.00,1.00', client)
		eq(rgb(active.text), '1.00,1.00,1.00', client .. ': the open page white')
		eq(rgb(other.text), '1.00,0.82,0.00', client .. ': the others gold')
		stub.fire_script(other, 'OnEnter'); eq(rgb(other.text), '1.00,1.00,1.00', client .. ': white under the mouse')
		stub.fire_script(other, 'OnLeave'); eq(rgb(other.text), '1.00,0.82,0.00', client)
		other.disabled = true -- a disabled entry keeps its gold under the mouse
		stub.fire_script(other, 'OnEnter'); eq(rgb(other.text), '1.00,0.82,0.00', client .. ': disabled stays gold')
		stub.fire_script(other, 'OnLeave'); other.disabled = nil
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('the main column under Blizzard: the page divider, no section rules, no footer line, the glass', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		eq(F.tabLine:GetAtlas(), 'Options_HorizontalDivider', client)
		eq(at(F.tabLine), '259,139 834x1', client)
		st.Config:Open('Tabs')
		eq(F.subLine:GetAtlas(), 'Options_HorizontalDivider', client .. ": the subtab row's line too")
		st.Config:Open('Long') -- three titled sections
		eq(lines(true), 0, client .. ': no 1px line across the body')
		check(lines(false) > 0, client .. ": the halves' dividers stay")
		check(not F.footerLine:IsShown(), client .. ': no footer line')
		local glass
		for _, region in ipairs({ F.search:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() == st.ThemeArt.Control('search').icon then glass = region end
		end
		check(glass, client .. ': the glass')
		eq(size_of(glass), '10x10', client)
		eq(anchor(glass), 'LEFT search LEFT 6,-1', client)
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('the dressing comes off under Thick', function()
	world('forever')
	switch('blizzard'); st.Config:Open('Long')
	switch('thick')
	local F = OW.GetFrames()
	local r, g, b, a = unpack(stub.state(F.sideFill).color_texture)
	eq(('%.2f,%.2f,%.2f,%.2f'):format(r, g, b, a), '0.09,0.09,0.09,1.00', 'the sidebar fill back')
	check(F.sideFill:IsShown(), 'shown')
	for _, l in ipairs(F.sideLines) do check(l:IsShown(), 'every side line shown') end
	local header = first_header()
	eq(header:GetHeight(), 29)
	eq(anchor(header.text, { [header] = 'header' }), 'TOPLEFT header TOPLEFT 18,-12')
	check(not header.banner:IsShown(), 'no banner')
	eq(rgb(header.text), ('%.2f,%.2f,%.2f'):format(st.config.profile.colors.text.grey:GetRGB()), 'grey')
	local normal = ('%.2f,%.2f,%.2f'):format(st.config.profile.colors.text.normal:GetRGB())
	eq(rgb(entry_of('Long').text), normal, 'the open page in the normal text color')
	eq(rgb(entry_of('Chat').text), normal, 'the others too')
	eq(F.tabLine:GetAtlas(), nil, 'the tab line has no atlas')
	for _, line in ipairs({ F.tabLine, F.subLine }) do
		eq(line:GetAtlas(), nil, 'no atlas on a tab row line')
		eq(table.concat(stub.state(line).color_texture, ','), table.concat(st.OptionsBody.LINE, ','), 'the lines color')
	end
	eq(lines(true), 2, 'a line between each pair of the three sections')
	check(F.footerLine:IsShown(), 'the footer line back')
	local glass = false
	for _, region in ipairs({ F.search:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() then glass = true end
	end
	check(not glass, "the glass back to Thick's (none)")
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)
