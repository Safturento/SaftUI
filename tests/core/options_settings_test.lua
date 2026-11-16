-- /sui under the Blizzard theme as Blizzard's Settings window
-- (SaftUI-Core/Config/optionswindow.lua and the files beside it, with
-- themeart_data.lua's optionswindow art), on both clients: the window drawn as a window (the metal, its title
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

-- One small page, as options_window_helpers.lua's SmallModule.
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
-- Tabs, two tabs, the first with two subtabs; Fill, a fill row. setup, if
-- given, runs on the fresh stubs before Core's config loads.
local function world(client, setup)
	use_client(client, setup)
	load_test_file('core/config_helpers.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
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
local tick = tick_options_window

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

-- /sui's frames where options_window_look_test.lua's first case pins them under
-- Thick and Thin, on the Loot page (one tab: no tab row).
local function check_own(where)
	local F = OW.GetFrames()
	eq(at(F.window), '0,0 1040x700', where)
	eq(at(F.side), '2,2 208x696', where .. ': the sidebar')
	eq(at(F.brand), '2,2 207x73', where .. ': the brand')
	eq(at(F.actionsFrame), '2,75 207x76', where .. ': the search box and the actions')
	eq(at(F.navFrame), '2,152 207x515', where .. ': the nav')
	eq(at(F.foot), '2,668 207x30', where .. ": the profile's name")
	eq(at(F.main), '210,2 828x696', where .. ': the main column')
	eq(at(F.title):match('^%d+,%d+'), '238,22', where .. ': the title')
	eq(at(F.close), '1000,14 24x24', where .. ': the close X')
	eq(at(F.search), '14,85 182x24', where .. ': the search box in the sidebar, over the buttons')
	eq(at(F.tabLine), '210,113 828x1', where .. ': the tab line')
	eq(at(F.body), '238,113 774x539', where .. ': the body')
	eq(at(F.footer), '210,652 828x46', where .. ': the footer')
	eq(table.concat(stub.state(F.sideFill).color_texture, ','), '0.09,0.09,0.09,0.9', where .. ': the sidebar fill, at the window\'s alpha')
	for _, l in ipairs(F.sideLines) do check(l:IsShown(), where .. ': a sidebar line shown') end
	eq(F.window.backdropInfo.insets.left, 2, where .. ': the border inset')
	for _, item in ipairs(F.nav) do
		if item.key then eq(item:GetWidth(), 207, where .. ': a nav entry') end
	end
end

------------------------------------------------------------------ the window

test("/sui's Blizzard title bar follows Window titles at once, with no redraw", function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		eq(F.titleText:GetFontObject(), st:GetFont('normal'), client .. ': Text to start with')
		st.config.profile.headers.font = 'subtitle'
		st:FontsChanged()
		eq(F.titleText:GetFontObject(), st:GetFont('subtitle'), client .. ': a shared font, at once')
		local face = { font_name = 'Colus', font_size = 12, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
		st.config.profile.headers.font = face
		st:FontsChanged()
		eq(F.titleText:GetFontObject(), st:FontObject(face), client .. ': a typeface, at once')
		st.config.profile.headers.font = 'normal'
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("Theme > Window titles reaches /sui's Blizzard title bar and a header's title at once", function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		local row = st:GetModule('Theme'):GetConfigTable().args.window_titles.args.font
		local panel = st:CreatePanel('Window titles test', 200, 100)
		row.set({}, 'subtitle')
		eq(st.config.profile.headers.font, 'subtitle', client .. ': saved in headers.font')
		eq(F.titleText:GetFontObject(), st:GetFont('subtitle'), client .. ': the title bar, at once')
		eq(panel.title:GetFontObject(), st:GetFont('subtitle'), client .. ': a window header, at once')
		eq(st.config.profile.fonts.normal.font_name, st.defaults.fonts.normal.font_name, client .. ': Text is untouched')
		local root = st.Config:GetOptionsTable()
		local titles
		for _, section in ipairs(st.OptionsModel.BuildView(root, 'Fonts', { tab = 'theme' }).sections) do
			for _, r in ipairs(section.rows) do
				if r.key == 'font' and r.path[#r.path - 1] == 'window_titles' then titles = r end
			end
		end
		eq(st.OptionsModel.DefaultReset(root, titles), true, client .. ': the derived reset ran')
		eq(F.titleText:GetFontObject(), st:GetFont('normal'), client .. ': its reset, at once')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('/sui under Blizzard: the metal, its title bar and the close button in the socket', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F, close = OW.GetFrames(), st.ThemeArt.Close()
		eq(drawn(F.window), 'theme,options,window', client)
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
		-- By its top right corner: the 1110 x 728 window centred 120 right and 40 down.
		eq(saved.point .. ' ' .. saved.x .. ' ' .. saved.y, 'TOPRIGHT -285 -216', client .. ': where it was left is saved')

		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('/sui under Blizzard: the inner frame, the sidebar on its divider, the footer under it', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		check(F.innerList:IsShown() and F.innerSettings:IsShown(), client .. ': the inner frame shown, in its two parts')
		eq(at(F.innerList), '17,28 242x654', client .. ': the inner frame: the list part over the sidebar')
		eq(at(F.innerSettings), '259,28 834x654', client .. ': and the settings part over the main column')
		eq(F.innerList:GetWidth() + F.innerSettings:GetWidth(), 1076, client .. ': together the inner frame')
		eq(at(F.side), '17,28 242x654', client .. ': the sidebar')
		eq(F.side:GetWidth(), OW.SidebarWidth(1076), client .. ': the sidebar ends on the drawn divider')
		eq(at(F.actionsFrame), '17,28 241x76', client .. ': the search box and the actions at the sidebar top')
		eq(at(F.search), '29,38 182x24', client .. ': the search box at the top, 12 in, over the buttons')
		eq(F.search:GetBottom() - F.actions[1]:GetTop(), 8, client .. ': 8 above Edit mode')
		eq(F.search:GetWidth(), 2 * F.actions[1]:GetWidth() + 6, client .. ': as wide as their line')
		eq(at(F.foot), '17,652 241x30', client .. ": the profile's name at the sidebar's bottom, inside the inner frame")
		eq(at(F.main), '259,28 834x654', client .. ': the main column')
		eq(at(F.body), '287,139 781x539', client .. ': the body: 28 in, the 774 content plus 7, as tall as under Thick')
		eq(F.content:GetWidth(), 774, client .. ': the content')
		eq(at(F.footer), '0,682 1110x46', client .. ': the footer across the window, under the inner frame')
		eq(F.reloadButton:GetRight(), F.closeButton:GetLeft() - 12, client .. ': Reload UI 12 left of Close')
		eq(F.window:GetBottom() + 16, F.reloadButton:GetBottom(), client .. ': and 16 up')
		eq(F.window:GetRight() - 16, F.closeButton:GetRight(), client .. ': Close 16 in')
		eq(F.window:GetBottom() + 16, F.closeButton:GetBottom(), client .. ': and 16 up')
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

test('under Blizzard: the inner frame in two parts, the arrows on the title bar, at full and at half', function()
	local P = load_test_file('lib/pixels.lua')
	for _, client in ipairs(CLIENTS) do
		world(client)
		CreateFrame('GameTooltip', 'GameTooltip', UIParent)
		st.config.global.optionsWindow = nil
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		local look = st.ThemeArt.Control('optionswindow')
		local info = C_Texture.GetAtlasInfo(look.inner)
		local list, settings = OW.InnerCuts(look, info.height)
		eq(table.concat(list, ',') .. ' ' .. table.concat(settings, ','), '0,199,0,618 199,886,0,618', client .. ': the cuts')
		-- The cuts, as ThemeArt.Cut lays them on a texture.
		local function cut(rect)
			local t = UIParent:CreateTexture()
			st.ThemeArt.Cut(t, look.inner, rect)
			return table.concat({ t:GetTexCoord() }, ','), t:GetTexture()
		end
		local function parts(where)
			local listCoords, listFile = cut(list)
			local settingsCoords, settingsFile = cut(settings)
			eq(table.concat({ F.innerList:GetTexCoord() }, ','), listCoords, client .. where .. ": the list part's texcoords")
			eq(table.concat({ F.innerSettings:GetTexCoord() }, ','), settingsCoords, client .. where .. ": the settings part's texcoords")
			eq(F.innerList:GetTexture(), listFile, client .. where .. ': the atlas file')
			eq(F.innerSettings:GetTexture(), settingsFile, client .. where .. ': the same file')
			check(F.innerList:IsShown() and F.innerSettings:IsShown(), client .. where .. ': both shown')
			eq(select(5, F.innerList:GetTexCoord()), (F.innerSettings:GetTexCoord()), client .. where .. ': they meet at the divider')
		end
		check(F.inner == nil, client .. ': no whole inner frame any more')
		eq(at(F.innerList), '17,28 242x654', client .. ': the list part')
		eq(at(F.innerSettings), '259,28 834x654', client .. ': the settings part')
		parts(' full')
		local close = st.ThemeArt.Close()
		local function arrows(where)
			-- The one beside the close X: shrink at full, grow at half.
			local beside = OW:GetWindowSize() == 'full' and F.shrink or F.grow
			eq(beside:GetWidth() .. 'x' .. beside:GetHeight(), '24x24', client .. where .. ": the close X's size")
			eq(beside:GetRight(), F.close:GetLeft() - 6, client .. where .. ': 6 left of the close button')
			eq(F.close:GetTop() - beside:GetTop(), (close.size - 24) / 2, client .. where .. ': centred on it (' .. close.size .. ' tall)')
			eq(F.shrink:GetTop(), beside:GetTop(), client .. where .. ': shrink level with it')
			check(beside:GetFrameLevel() > F.titleBar:GetFrameLevel(), client .. where .. ': over the title bar')
			eq(F.window:GetRight() - 16, F.closeButton:GetRight(), client .. where .. ': Close 16 from the right')
			eq(F.window:GetBottom() + 16, F.closeButton:GetBottom(), client .. where .. ': and 16 up')
			eq(F.reloadButton:GetRight(), F.closeButton:GetLeft() - 12, client .. where .. ': Reload UI 12 left of Close')
			eq(F.reloadButton:GetBottom(), F.closeButton:GetBottom(), client .. where .. ': level with it')
			eq(F.footerRegion:GetLeft(), F.window:GetLeft() + 16, client .. where .. ": the region from the footer's 16")
			eq(F.footerRegion:GetRight(), F.reloadButton:GetLeft() - 12, client .. where .. ': to 12 before Reload UI')
			eq(F.title:GetWidth(), F.content:GetWidth() - 40, client .. where .. ': the title as wide as the body less 40')
			eq(F.header:GetRight(), F.main:GetRight() - 56, client .. where .. ': the drag strip stays 56 short')
		end
		arrows(' full')
		check(F.shrink:IsShown() and not F.grow:IsShown(), client .. ': full: shrink shown')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(F.window)
			eq(#off, 0, client .. ' W1 noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0

		stub.time = stub.time + 1
		stub.click(F.shrink)
		eq(OW:GetWindowSize(), 'half', client .. ': half')
		eq(at(F.window), '0,0 704x728', client .. ': W3')
		eq(at(F.innerList), '17,28 242x654', client .. ': half: the list part as at full')
		eq(at(F.innerSettings), '259,28 428x654', client .. ': half: the settings part squeezed')
		parts(' half')
		arrows(' half')
		check(F.grow:IsShown(), client .. ': grow shown at half')
		eq(F.shrink:GetRight(), F.grow:GetLeft() - 6, client .. ': shrink 6 left of grow')
		eq(F.content:GetWidth(), 368, client .. ': the body is 368')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(F.window)
			eq(#off, 0, client .. ' W3 noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0
		stub.fire_script(F.close, 'OnEnter', true)
		check(GameTooltip:IsOwned(F.close), client .. ': the close button has its tooltip')
		stub.fire_script(F.close, 'OnLeave', true)
		st.Config:Close()
		st.config.global.optionsWindow = nil
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("the bar under Blizzard: a panel at the metal's top right, the red close button inside it", function()
	local P = load_test_file('lib/pixels.lua')
	for _, client in ipairs(CLIENTS) do
		world(client)
		CreateFrame('GameTooltip', 'GameTooltip', UIParent)
		st.config.global.optionsWindow = nil
		switch('blizzard'); st.Config:Open('Unitframes')
		local F = OW.GetFrames()
		local w = F.window
		local reachLeft, reachRight, reachTop = st.ThemeArt.MetalReach()
		local dx, dy = OW.MiniShift(OW.LAYOUT.blizzard)
		eq(dx .. ' ' .. dy, reachRight .. ' ' .. reachTop, client .. ': the shift is the metal\'s right and top reach')
		-- At full the metal's top right is the window's corner plus the reach.
		local metalRight, metalTop = w:GetRight() + dx, w:GetTop() + dy
		local right, top = w:GetRight(), w:GetTop()
		local x0, y0 = select(4, w:GetPoint(1)), select(5, w:GetPoint(1))
		stub.time = stub.time + 1; stub.click(F.shrink)
		stub.time = stub.time + 1; stub.click(F.shrink)
		eq(OW:GetWindowSize(), 'mini', client .. ': the bar')
		eq(w:GetRight(), metalRight, client .. ": the bar's right is the metal's")
		eq(w:GetTop(), metalTop, client .. ": and its top")
		eq(w:GetHeight(), 42, client .. ': 42 tall')
		eq(drawn(w), 'theme,options,panel', client .. ': a panel')
		local reference = st:CreateFrame('Frame', nil, UIParent)
		st:SetTemplate(reference, 'theme', 'solid', 'panel')
		eq(T.art(w), T.art(reference), client .. ": the panel kind's art")
		check(T.art(w) ~= METAL, client .. ': not the metal')
		local close = st.ThemeArt.Close()
		eq(F.close:GetWidth(), close.size, client .. ": the red close button at Blizzard's size")
		eq(F.close:GetNormalTexture():GetAtlas(), close.normal, client .. ': in its art')
		eq(F.close:GetTop() - F.close:GetBottom(), close.size, client .. ': ' .. close.size .. ' tall')
		eq(w:GetTop() - F.close:GetTop(), (42 - close.size) / 2, client .. ': centred on the bar')
		eq(w:GetRight() - F.close:GetRight(), 8, client .. ': 8 in from the right')
		eq(F.close:GetLeft(), F.miniGrow:GetRight() + 8, client .. ': grow 8 before it')
		eq(w:GetTop() - F.miniGrow:GetTop(), 9, client .. ': grow centred on the bar')
		check(not F.titleBar:IsShown() and not F.innerList:IsShown() and not F.innerSettings:IsShown(), client .. ': no title bar or inner frame')
		check(F.close:IsShown() and F.miniGrow:IsShown(), client .. ': the buttons')
		eq(#P.off(w), 0, client .. ': whole pixels')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(w)
			eq(#off, 0, client .. ' noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0
		-- A switch to Thick and back keeps it a bar.
		switch('thick')
		eq(OW:GetWindowSize(), 'mini', client .. ': Thick: still the bar'); eq(drawn(w), 'theme,options,panel')
		eq(select(4, w:GetPoint(1)) .. ' ' .. select(5, w:GetPoint(1)), x0 .. ' ' .. y0, client .. ': under Thick the bar sits at the corner')
		switch('blizzard')
		eq(OW:GetWindowSize(), 'mini', client .. ': Blizzard again: still the bar'); eq(drawn(w), 'theme,options,panel')
		eq(w:GetRight(), metalRight, client .. ": at the metal's corner again")
		-- A drag saves the corner less the shift.
		stub.fire_script(F.miniNames, 'OnMouseDown', 'LeftButton')
		stub.fire_script(F.miniNames, 'OnDragStart')
		w:ClearAllPoints()
		w:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -200 + dx, -100 + dy)
		stub.fire_script(F.miniNames, 'OnDragStop')
		local saved = st.config.global.optionsWindow
		eq(saved.x .. ' ' .. saved.y, '-200 -100', client .. ': the saved corner is where it shows less the shift')
		-- Grow: the window under the metal again, at that corner.
		stub.time = stub.time + 1; stub.click(F.miniGrow)
		eq(OW:GetWindowSize(), 'half', client .. ': half')
		eq(drawn(w), 'theme,options,window', client .. ': a window')
		eq(T.art(w), METAL, client .. ': the metal again')
		eq(select(4, w:GetPoint(1)) .. ' ' .. select(5, w:GetPoint(1)), '-200 -100', client .. ': the corner')
		eq(F.close:GetWidth(), close.size)
		check(F.titleBar:IsShown() and F.innerSettings:IsShown(), client .. ': the title bar and the inner frame back')
		st.Config:Close()
		st.config.global.optionsWindow = nil
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
	check(not F.innerList:IsShown() and not F.innerSettings:IsShown() and not F.titleBar:IsShown(), 'Thick: no inner frame or title bar')

	switch('blizzard')
	eq(at(F.window), '0,0 1110x728', 'Blizzard')
	eq(at(F.side), '17,28 242x654', 'Blizzard: the sidebar')
	check(F.innerList:IsShown() and F.innerSettings:IsShown() and F.titleBar:IsShown(), 'Blizzard: the inner frame and title bar')

	switch('thick')
	check_own('Thick again')
	check(not F.innerList:IsShown() and not F.innerSettings:IsShown(), 'Thick again: no inner frame')
	check(not F.titleBar:IsShown(), 'Thick again: no title bar')
	check(F.brand:IsShown(), 'Thick again: the brand')
	eq(T.art(F.window), '', 'Thick again: no metal')
	eq(drawn(F.window), 'theme,options,window', 'Thick again: still drawn as a window')
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
	check(F.innerList:IsShown() and F.innerSettings:IsShown() and F.titleBar:IsShown() and not F.brand:IsShown(), 'the Blizzard profile: inner frame and title bar, no brand')
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
-- and those 1 wide (the halves' dividers), in OB.LINE's color: under Thick and
-- Thin the dividers and the lines between rows are the panels' hairlines (white
-- at 7%), which are no part of what this counts.
local function lines(wide)
	local F, n = OW.GetFrames(), 0
	local line = table.concat(st.OptionsBody.LINE, ',')
	for _, region in ipairs({ F.content:GetRegions() }) do
		local color = region:GetObjectType() == 'Texture' and region:IsShown() and stub.state(region).color_texture
		if color and table.concat(color, ',') == line then
			if wide and region:GetWidth() == F.content:GetWidth() and region:GetHeight() == 1 then n = n + 1 end
			if not wide and region:GetWidth() == 1 then n = n + 1 end
		end
	end
	return n
end

-- How many of the body's textures show in color (a panel's fill, a hairline's).
local function painted(color)
	local F, n = OW.GetFrames(), 0
	local want = table.concat(color, ',')
	for _, region in ipairs({ F.content:GetRegions() }) do
		local c = region:GetObjectType() == 'Texture' and region:IsShown() and stub.state(region).color_texture
		if c and table.concat(c, ',') == want then n = n + 1 end
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
		eq(painted(st.OptionsBody.HAIRLINE), 0, client .. ': no hairline under Blizzard')
		eq(painted(st.OptionsBody.PANEL_FILL), 0, client .. ': no panel under Blizzard')
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
	eq(('%.2f,%.2f,%.2f,%.2f'):format(r, g, b, a), '0.09,0.09,0.09,0.90', 'the sidebar fill back, at the window\'s alpha')
	check(F.sideFill:IsShown(), 'shown')
	for _, l in ipairs(F.sideLines) do check(l:IsShown(), 'every side line shown') end
	local header = first_header()
	eq(header:GetHeight(), 29)
	eq(anchor(header.text, { [header] = 'header' }), 'TOPLEFT header TOPLEFT 18,-12')
	check(not header.banner:IsShown(), 'no banner')
	eq(rgb(header.text), ('%.2f,%.2f,%.2f'):format(st.config.profile.colors.text.muted:GetRGB()), 'grey')
	local normal = ('%.2f,%.2f,%.2f'):format(st.config.profile.colors.text.normal:GetRGB())
	eq(rgb(entry_of('Long').text), normal, 'the open page in the normal text color')
	eq(rgb(entry_of('Chat').text), normal, 'the others too')
	eq(F.tabLine:GetAtlas(), nil, 'the tab line has no atlas')
	for _, line in ipairs({ F.tabLine, F.subLine }) do
		eq(line:GetAtlas(), nil, 'no atlas on a tab row line')
		eq(table.concat(stub.state(line).color_texture, ','), table.concat(st.OptionsBody.LINE, ','), 'the lines color')
	end
	eq(lines(true), 0, 'no line between the sections: their panels part them')
	check(painted(st.OptionsBody.PANEL_FILL) > 0 and painted(st.OptionsBody.HAIRLINE) > 0, 'panels and hairlines drawn under Thick')
	check(F.footerLine:IsShown(), 'the footer line back')
	local glass = false
	for _, region in ipairs({ F.search:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() then glass = true end
	end
	check(not glass, "the glass back to Thick's (none)")
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the dropdowns' steppers

-- A dropdown button's face: its shown common-dropdown-c-button texture.
local function face_of(button)
	for _, region in ipairs({ button:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() == 'common-dropdown-c-button' then return region end
	end
end

-- Every atlas shown on frame and the shown frames under it.
local function all_atlases(frame, out)
	out = out or {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() then out[#out + 1] = region:GetAtlas() end
	end
	for _, child in ipairs({ frame:GetChildren() }) do
		if child:IsShown() then all_atlases(child, out) end
	end
	return out
end

test("the picker row's select has steppers when its choices fit; the position block's dropdown has none", function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		-- A page with a picker of short names, each with a position block whose target is a select.
		local store = { point = 'TOP', rel_point = 'TOP', x_off = 0, y_off = 0, frame = 'PlayerFrame', relative_to = 'Health' }
		local function unit(name, order)
			return { order = order, name = name, type = 'group', args = {
				pos = {
					order = 1, type = 'position', name = 'Position', target = 'select',
					values = { Health = 'Health', Power = 'Power' },
					get = function(_, part) return store[part] end,
					set = function(_, part, value) store[part] = value end,
				},
			} }
		end
		local picker = st:NewModule('Picker')
		function picker:GetConfigTable()
			return { name = 'Picker', type = 'group', category = 'Frames', childGroups = 'select',
				args = { one = unit('One', 1), two = unit('Two', 2), three = unit('Three', 3) } }
		end

		switch('blizzard'); st.Config:Open('Picker', 'one')
		local F = OW.GetFrames()
		local w = F.picker
		check(w.frame:IsShown(), client .. ': the picker shows')
		check(w.back:IsShown() and w.next:IsShown(), client .. ': its short names fit: steppers')
		eq(size_of(w.frame), '170x24', client .. ': the picker keeps its size')
		eq(around(face_of(w.frame), w.frame), '24,7,-23,-7', client .. ': the face between them')
		check(not w.back:IsEnabled() and w.next:IsEnabled(), client .. ': at the first unit, only next')

		local block = cell('pos').widget
		check(block.select:IsShown(), client .. ": the block's dropdown shows")
		eq(around(face_of(block.select), block.select), '-4,4,4,-4', client .. ': compact, across its whole width')
		for _, atlas in ipairs(all_atlases(block.frame)) do
			check(not atlas:find('^common%-dropdown%-icon'), client .. ': no stepper in the block: ' .. atlas)
		end

		-- A step picks the next unit, as a pick from the list does.
		stub.fire_script(w.next, 'OnClick', 'LeftButton')
		tick()
		eq(OW:GetState().pick, 'two', client .. ': next picks the next unit')
		eq(w.text:GetText(), 'Two', client .. ': and the picker shows it')
		check(w.back:IsEnabled() and w.next:IsEnabled(), client .. ': in the middle, both')

		switch('thick')
		check(not w.back:IsShown() and not w.next:IsShown(), client .. ': Thick: no steppers')
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("the Profiles page: Copy From and Delete have no steppers, the current profile's select keeps its own", function()
	for _, client in ipairs(CLIENTS) do
		-- A short character and realm name, so every profile name AceDBOptions
		-- lists (the character's, the realm's, the class's and Default) fits
		-- the stepped face. AceDB reads them when it loads.
		world(client, function()
			local unitName = UnitName
			UnitName = function(unit)
				if unit == 'player' then return 'Al', nil end
				return unitName(unit)
			end
			GetRealmName = function() return 'Rx' end
		end)
		local current = st.config:GetCurrentProfile()
		eq(current, 'Al - Rx', client .. ': the current profile')
		-- A second profile, its own Screen edge margin, for Copy From and Delete to offer.
		st.config:SetProfile('Alt')
		st.config.profile.misc.clamp_inset = 37
		st.config:SetProfile(current)
		local inset = st.config.profile.misc.clamp_inset
		check(inset ~= 37, client .. ': the current profile its own margin')

		switch('blizzard'); st.Config:Open('profile')
		local choose, copy, delete = cell('choose').widget, cell('copyfrom').widget, cell('delete').widget
		check(choose.stepped and choose.back:IsShown() and choose.next:IsShown(), client .. ': Choose: steppers')
		eq(around(face_of(choose.frame), choose.frame), '24,7,-23,-7', client .. ': Choose: the face between them')
		for name, w in pairs({ ['Copy From'] = copy, Delete = delete }) do
			check(not w.disabled, client .. ': ' .. name .. ' offers Alt')
			check(w:StepsFit(), client .. ': ' .. name .. ": its choices would fit")
			check(not w.stepped and not w.back:IsShown() and not w.next:IsShown(), client .. ': ' .. name .. ': no steppers')
			eq(around(face_of(w.frame), w.frame), '-7,7,7,-7', client .. ': ' .. name .. ': the face at the full 170')
			-- A click can't reach CopyProfile or DeleteProfile: no stepper shows, and a step does nothing.
			w:Step(1); w:Step(-1)
			tick()
			eq(st.config.profile.misc.clamp_inset, inset, client .. ': ' .. name .. ': nothing copied')
			eq(W.ConfirmText(), nil, client .. ': ' .. name .. ': nothing asked')
		end
		local profiles = st.config:GetProfiles()
		check(#profiles == 2, client .. ': nothing deleted')

		-- Choose steps through the profiles as a pick does.
		local _, nextKey = choose:StepTargets()
		stub.fire_script(choose.next, 'OnClick', 'LeftButton')
		tick()
		eq(st.config:GetCurrentProfile(), nextKey, client .. ": Choose's next switches to the next profile")
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

------------------------------------------------------------------ the scroll bars

-- The thumb's three atlases in a state ('' normal, '-over', '-down'), sorted
-- as atlases_of lists them.
local function thumb_art(state)
	return ('minimal-scrollbar-small-thumb-bottom%s,minimal-scrollbar-small-thumb-middle%s,minimal-scrollbar-small-thumb-top%s'):format(state, state, state)
end

test('under Blizzard a scroll area shows MinimalScrollBar only with something to scroll', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Long')
		local F = OW.GetFrames()
		local bar = st.OptionsBody.Companion(F.bar)
		check(bar.frame:IsShown(), client .. ': the body has a bar')
		check(not F.bar:IsShown(), client .. ': not the 3px bar')
		eq(atlases_of(bar.track), '!minimal-scrollbar-track-middle,minimal-scrollbar-track-bottom,minimal-scrollbar-track-top', client .. ': the track')
		eq(bar.track:GetLeft() - F.content:GetLeft(), 774 + 12, client .. ': 12 right of the content')
		eq(bar.track:GetWidth(), 8, client .. ': 8 wide')
		eq(size_of(bar.up), '17x11', client .. ': the up arrow')
		eq(size_of(bar.down), '17x11', client .. ': the down arrow')
		eq(atlases_of(bar.up), 'minimal-scrollbar-arrow-top', client)
		eq(atlases_of(bar.down), 'minimal-scrollbar-arrow-bottom', client)
		eq(bar.up:GetLeft(), bar.track:GetLeft() - 4, client .. ': the arrows from 4 left of the track')
		eq(bar.down:GetLeft(), bar.track:GetLeft() - 4, client)
		eq(bar.up:GetTop(), F.body:GetTop(), client .. ": the up arrow at the body's top")
		eq(bar.down:GetBottom(), F.body:GetBottom(), client .. ': the down arrow at its bottom')
		eq(bar.track:GetTop(), F.body:GetTop() - 19, client .. ': the track 19 in from the top')
		eq(bar.track:GetBottom(), F.body:GetBottom() + 19, client .. ': and from the bottom')
		local track_len, view, total = bar.track:GetHeight(), F.body:GetHeight(), F.content:GetHeight()
		eq(bar.thumb:GetHeight(), math.max(23, math.floor(track_len * view / total)), client .. ': the thumb its share of the track')
		eq(bar.thumb:GetWidth(), 8, client)
		eq(bar.thumb:GetTop(), bar.track:GetTop(), client .. ': at the top')
		eq(atlases_of(bar.thumb), thumb_art(''), client .. ': the small thumb')
		eq(table.concat({ bar.thumb:GetHitRectInsets() }, ','), '-4,-4,-4,-4', client .. ": it takes the mouse 4 past its edges, as MinimalScrollBar's")
		for _, region in ipairs({ bar.track:GetRegions() }) do
			if region:GetAtlas() == '!minimal-scrollbar-track-middle' then
				check(region:GetVertTile(), client .. ": the track's middle tiles down")
				eq(region:GetTop() .. ',' .. region:GetBottom(), (bar.track:GetTop() - 8) .. ',' .. (bar.track:GetBottom() + 8), client .. ': between its 8 tall ends')
			end
		end
		check(bar.down:GetRight() <= F.main:GetRight() - 7, 'clear of the inner frame')
		for _ = 1, 50 do stub.fire_script(F.body, 'OnMouseWheel', -1) end
		eq(bar.thumb:GetBottom(), bar.track:GetBottom(), client .. ': scrolled to the end, the thumb at the bottom')

		st.Config:Open('Loot')
		check(not bar.frame:IsShown(), client .. ': nothing to scroll: no bar')
		check(not F.bar:IsShown(), client .. ': nor the 3px one')
		-- The nav's few pages fit it: no bar there either.
		check(F.navContent:GetHeight() <= F.navFrame:GetHeight(), client .. ': the nav has nothing to scroll')
		check(not st.OptionsBody.Companion(F.navBar).frame:IsShown(), client .. ': the nav: no bar')
		check(not F.navBar:IsShown(), client .. ': nor a 3px one')
		switch('thick'); st.Config:Open('Long')
		check(F.bar:IsShown(), client .. ": Thick: the 3px bar, as today")
		eq(F.bar:GetLeft() - F.content:GetLeft(), 774 + 10, client .. ': Thick: 10 right of the content')
		check(not bar.frame:IsShown(), client .. ': Thick: no Blizzard bar')
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('the scroll bar works: drag the thumb, click an arrow, click the track; the wheel as before', function()
	world('forever')
	switch('blizzard'); st.Config:Open('Long')
	local F = OW.GetFrames()
	local bar = st.OptionsBody.Companion(F.bar)
	local function scroll() return F.body:GetVerticalScroll() end
	local view = F.body:GetHeight()
	local range = F.content:GetHeight() - view
	local room = bar.track:GetHeight() - bar.thumb:GetHeight()
	local scale = bar.frame:GetEffectiveScale()
	check(range > 0 and room > 0, 'something to scroll, and room for the thumb to move')
	eq(scroll(), 0, 'at the top')

	-- The thumb: lit under the mouse, pressed while held, dragged.
	stub.fire_script(bar.thumb, 'OnEnter')
	eq(atlases_of(bar.thumb), thumb_art('-over'), 'the thumb under the mouse')
	local _, y = bar.thumb:GetCenter()
	stub.cursor_x, stub.cursor_y = 0, y * scale
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	eq(atlases_of(bar.thumb), thumb_art('-down'), 'held')
	eq(scroll(), 0, 'a press alone scrolls nothing')
	stub.cursor_y = (y - 40) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(scroll(), math.floor(40 * range / room + 0.5), 'the cursor 40 down: the body as far through its range as the thumb through its room')
	check(math.abs(bar.track:GetTop() - bar.thumb:GetTop() - 40) <= 1, 'the thumb follows the cursor')
	stub.cursor_y = (y - 2000) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(scroll(), range, 'past the end: at the end')
	eq(bar.thumb:GetBottom(), bar.track:GetBottom(), 'the thumb at the bottom')
	stub.cursor_y = (y + 2000) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(scroll(), 0, 'past the top: at the top')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar.thumb, 'OnMouseUp', 'LeftButton')
	eq(atlases_of(bar.thumb), thumb_art('-over'), 'let go, still under the mouse')
	stub.cursor_y = (y - 100) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(scroll(), 0, 'let go: the cursor no longer drags')
	stub.fire_script(bar.thumb, 'OnLeave')
	eq(atlases_of(bar.thumb), thumb_art(''), 'the mouse gone')

	-- A thumb let go without its mouse up (the button came up elsewhere) stops too.
	stub.cursor_y = y * scale
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
	stub.mouse_buttons.LeftButton = nil
	stub.cursor_y = (y - 40) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(scroll(), 0, 'the button up: no drag')
	eq(atlases_of(bar.thumb), thumb_art(''), 'and not held')

	-- The arrows: a step each, lit and pressed as the nudges are.
	stub.fire_script(bar.down, 'OnClick', 'LeftButton')
	eq(scroll(), 68, 'the down arrow: a step down')
	stub.fire_script(bar.up, 'OnClick', 'LeftButton')
	eq(scroll(), 0, 'the up arrow: back')
	stub.fire_script(bar.up, 'OnClick', 'LeftButton')
	eq(scroll(), 0, 'no further than the top')
	stub.fire_script(bar.down, 'OnEnter')
	eq(atlases_of(bar.down), 'minimal-scrollbar-arrow-bottom-over', 'an arrow under the mouse')
	stub.fire_script(bar.down, 'OnMouseDown', 'LeftButton')
	eq(atlases_of(bar.down), 'minimal-scrollbar-arrow-bottom-down', 'pressed')
	stub.fire_script(bar.down, 'OnMouseUp', 'LeftButton')
	eq(atlases_of(bar.down), 'minimal-scrollbar-arrow-bottom-over', 'let go')
	stub.fire_script(bar.down, 'OnLeave')
	eq(atlases_of(bar.down), 'minimal-scrollbar-arrow-bottom', 'the mouse gone')

	-- The track: a view at a time, toward the click.
	stub.cursor_y = (bar.thumb:GetBottom() - 5) * scale
	stub.fire_script(bar.track, 'OnMouseDown', 'LeftButton')
	eq(scroll(), math.min(range, view), 'below the thumb: a view down')
	stub.cursor_y = (bar.thumb:GetTop() + 2) * scale
	check(bar.thumb:GetTop() + 2 < bar.track:GetTop(), 'room above the thumb to click')
	stub.fire_script(bar.track, 'OnMouseDown', 'LeftButton')
	eq(scroll(), math.max(0, math.min(range, view) - view), 'above it: a view up')

	-- The wheel, as before; over the bar, outside the body, too.
	stub.fire_script(F.body, 'OnMouseWheel', -1)
	eq(scroll(), 68, 'a turn of the wheel: 68')
	eq(bar.thumb:GetTop(), bar.track:GetTop() - math.floor(room * 68 / range), 'the thumb follows the wheel')
	check(bar.frame:IsMouseWheelEnabled(), 'the bar takes the wheel')
	stub.fire_script(bar.frame, 'OnMouseWheel', -1)
	eq(scroll(), 136, 'a turn over the bar: 68 more')
	stub.fire_script(bar.frame, 'OnMouseWheel', 1)
	eq(scroll(), 68, 'and back')
	stub.cursor_x, stub.cursor_y = 0, 0
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

test('a held thumb: a theme switch waits for it; the window closing mid-drag (combat) lets it go', function()
	world('forever')
	switch('blizzard'); st.Config:Open('Long')
	local F = OW.GetFrames()
	local bar = st.OptionsBody.Companion(F.bar)
	local scale = bar.frame:GetEffectiveScale()
	local function hold()
		local _, y = bar.thumb:GetCenter()
		stub.cursor_x, stub.cursor_y = 0, y * scale
		stub.mouse_buttons.LeftButton = true
		stub.fire_script(bar.thumb, 'OnMouseDown', 'LeftButton')
		return y
	end

	-- A switch to Thick mid-drag: the render, and with it the 3px bar, waits
	-- until the thumb is let go.
	hold()
	check(W.ScrollBarHeld(), 'held')
	local renders = OW.GetRenderCount()
	switch('thick')
	eq(OW.GetRenderCount(), renders, 'no render while the thumb is held')
	check(bar.frame:IsShown() and bar.held, "Blizzard's bar still there, still held")
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(bar.thumb, 'OnMouseUp', 'LeftButton')
	tick()
	eq(OW.GetRenderCount(), renders + 1, 'let go: the render')
	check(not bar.frame:IsShown() and F.bar:IsShown(), "Thick's 3px bar in place of Blizzard's")

	-- Combat closes /sui mid-drag: the thumb hides with the window and lets go,
	-- though the button is still down, so nothing is held for the next open.
	switch('blizzard'); st.Config:Open('Long')
	local y = hold()
	check(W.ScrollBarHeld(), 'held again')
	st.Config:PLAYER_REGEN_DISABLED()
	check(not OW:IsShown(), 'combat: the window closed')
	check(not bar.held, 'the drag ended with it')
	check(stub.mouse_buttons.LeftButton and not W.ScrollBarHeld(), 'nothing held, the button still down')
	local offset = F.body:GetVerticalScroll()
	stub.cursor_y = (y - 40) * scale
	stub.fire_script(bar.frame, 'OnUpdate', 0.01)
	eq(F.body:GetVerticalScroll(), offset, 'the cursor scrolls nothing')
	stub.mouse_buttons.LeftButton = nil
	stub.cursor_x, stub.cursor_y = 0, 0
	eq(#take_errors(), 0, 'no errors')
end)

-- A group of n wide toggles, for a dialog taller than it shows.
local function tall_group(n)
	local args = {}
	for i = 1, n do args['t' .. i] = toggle('Toggle ' .. i, i, 'wide') end
	return { type = 'group', name = 'Tall', args = args }
end

test('each scroll area has its bar where there is room: the nav, the dialog', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		for i = 1, 40 do SmallModule('Page' .. i, ('Page %02d'):format(i), 'Frames') end
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()

		-- The nav: narrow, 4 right of its rows and 4 short of the divider.
		local nav = st.OptionsBody.Companion(F.navBar)
		check(nav.frame:IsShown(), client .. ': the nav has a bar')
		check(not F.navBar:IsShown(), client .. ': not a 3px one')
		eq(size_of(nav.up), '8x5', client .. ': narrow arrows')
		eq(size_of(nav.down), '8x5', client)
		eq(nav.up:GetLeft(), nav.track:GetLeft(), client .. ': over the track')
		eq(nav.track:GetLeft() - F.side:GetLeft(), 226 + 4, client .. ': 4 right of the rows')
		eq(nav.up:GetTop(), F.navFrame:GetTop(), client .. ': from the top of the nav')
		eq(nav.down:GetBottom(), F.navFrame:GetBottom(), client .. ': to its bottom')
		eq(nav.track:GetTop(), F.navFrame:GetTop() - 9, client .. ': the track 9 in')
		eq(nav.track:GetBottom(), F.navFrame:GetBottom() + 9, client)
		eq(F.side:GetRight() - nav.track:GetRight(), 4, client .. ': 4 short of the divider')
		check(nav.frame:GetLeft() >= F.side:GetLeft() and nav.frame:GetRight() <= F.side:GetRight(), client .. ': inside the sidebar')
		stub.fire_script(nav.down, 'OnClick', 'LeftButton')
		eq(F.navFrame:GetVerticalScroll(), 52, client .. ': an arrow: two rows')
		stub.fire_script(F.navFrame, 'OnMouseWheel', 1)
		eq(F.navFrame:GetVerticalScroll(), 0, client .. ': the wheel, as before')
		for _ = 1, 100 do stub.fire_script(F.navFrame, 'OnMouseWheel', -1) end
		eq(F.navFrame:GetVerticalScroll(), F.navContent:GetHeight() - F.navFrame:GetHeight(), client .. ': no further than its end')

		-- The dialog: narrow, 12 right of its content.
		OW:OpenDialog('Tall', tall_group(24))
		local d = OW.GetDialogFrames()
		local dialog = st.OptionsBody.Companion(d.bar)
		check(dialog.frame:IsShown(), client .. ': the dialog has a bar')
		check(not d.bar:IsShown(), client .. ': not a 3px one')
		eq(size_of(dialog.up), '8x5', client .. ': narrow')
		eq(dialog.track:GetLeft() - d.content:GetLeft(), 520 + 12, client .. ': 12 right of its content')
		eq(dialog.up:GetTop(), d.scroll:GetTop(), client .. ': from the top of its scroll')
		eq(dialog.down:GetBottom(), d.scroll:GetBottom(), client .. ': to its bottom')
		check(dialog.frame:GetRight() <= d.frame:GetRight() - st.ThemeArt.Inset('panel'), client .. ': inside the dialog')
		stub.fire_script(dialog.down, 'OnClick', 'LeftButton')
		eq(d.scroll:GetVerticalScroll(), 68, client .. ': an arrow: a step')
		OW:CloseDialog()

		-- Under Thick: the nav has none, the dialog its 3px bar as today.
		switch('thick')
		check(not nav.frame:IsShown(), client .. ': Thick: the nav has no bar')
		check(not F.navBar:IsShown(), client .. ': not even a 3px one')
		OW:OpenDialog('Tall', tall_group(24))
		check(d.bar:IsShown(), client .. ': Thick: the dialog its 3px bar')
		eq(d.bar:GetLeft() - d.content:GetLeft(), 520 + 10, client .. ': 10 right of its content')
		check(not dialog.frame:IsShown(), client .. ': no Blizzard bar')
		OW:CloseDialog()
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

------------------------------------------------------------------ growing taller

-- Drags handle dy units down (up when negative): the button down, one frame, the button up.
local function resize(handle, dy)
	local scale = OW.GetFrames().window:GetEffectiveScale()
	stub.mouse_buttons.LeftButton = true
	stub.cursor_y = 500 * scale
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	stub.cursor_y = (500 - dy) * scale
	stub.fire_script(handle, 'OnUpdate', 0.016)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(handle, 'OnMouseUp', 'LeftButton')
end

-- A frame's clamp insets as 'left,right,top,bottom'.
local function clamp_insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = ('%d'):format(v) end
	return table.concat(out, ',')
end

test('under Blizzard /sui grows taller from 728; the inner frame and the sidebar stretch; the grip is Blizzard\'s', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		eq(at(F.window), '0,0 1110x728', client)
		eq(F.grip:GetNormalTexture():GetTexture(), [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Up]], client)
		eq(F.grip:GetHighlightTexture():GetTexture(), [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Highlight]], client)
		eq(F.grip:GetPushedTexture():GetTexture(), [[Interface\ChatFrame\UI-ChatIM-SizeGrabber-Down]], client)
		eq(at(F.grip), '1094,712 16x16', client .. ': in the corner, as PanelResizeButtonTemplate is 16')
		resize(F.grip, 100)
		eq(at(F.innerList), '17,28 242x754', client); eq(at(F.innerSettings), '259,28 834x754', client)
		eq(at(F.side), '17,28 242x754', client); eq(at(F.body), '287,139 781x639', client)
		eq(at(F.footer), '0,782 1110x46', client)
		switch('thick'); eq(at(F.window), '0,0 1040x828', client .. ': the dragged height under Thick too')
		eq(F.grip:GetNormalTexture():GetTexture(), st.textures.cornerbr, client)
		eq(F.grip:GetHighlightTexture():GetAlpha(), 0, client .. ': Thick: the corner takes the tone itself (a glyph): the highlight is clear')
		eq(F.grip:GetPushedTexture():GetAlpha(), 1, client .. ': Thick: the pushed texture shows the corner while held')
		st.config.global.optionsWindow.height = 700; switch('blizzard'); eq(F.window:GetHeight(), 728, client .. ": a height under Blizzard's least")
		eq(table.concat({ F.grip:GetHighlightTexture():GetVertexColor() }, ','), '1,1,1,1', client .. ": Blizzard's highlight untinted")
		eq(F.grip:GetHighlightTexture():GetBlendMode(), 'ADD', client .. ": and added, as a HighlightTexture's default")
		st.config.global.optionsWindow = nil; st.Config:Close(); st.Config:Open('Loot')
		stub.fire_script(F.titleBar, 'OnDragStart'); stub.fire_script(F.titleBar, 'OnDragStop') -- a move at 728
		eq(st.config.global.optionsWindow.height, nil, client .. ': a move saves no height')
		switch('thick'); eq(F.window:GetHeight(), 700, client .. ": so Thick keeps today's 700")
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("under Blizzard the metal stays inside the screen edge margin: the clamp, the most height, a resize's stop", function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		local inset = st.config.profile.misc.clamp_inset
		local left, right, above, below = st.ThemeArt.MetalReach()
		eq(('%d,%d,%d,%d'):format(left, right, above, below), client == 'forever' and '8,2,16,8' or '8,4,16,3',
			client .. ": how far the metal reaches past the window: its corners' offsets")
		switch('thick'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		eq(clamp_insets(F.window), ('%d,%d,%d,%d'):format(-inset, inset, inset, -inset), client .. ': Thick: the window kept in the margin')
		switch('blizzard')
		eq(clamp_insets(F.window), ('%d,%d,%d,%d'):format(-inset - left, inset + right, inset + above, -inset - below),
			client .. ': Blizzard: the metal kept in it, so a move to the top keeps the title bar on screen')
		eq(OW.MaxHeight(), 2 * math.floor((1080 - 2 * inset - above - below) / 2), client .. ': the most height leaves room for the metal')
		local top = F.window:GetTop()
		resize(F.grip, 5000)
		eq(F.window:GetHeight(), 2 * math.floor((top - inset - below) / 2), client .. ': grown until the metal meets the margin')
		eq(F.window:GetTop(), top, client .. ': its top stays')
		local bottom = F.window:GetBottom() - below
		check(bottom >= inset and bottom < inset + 2, client .. ': the grip, and the metal under it, inside the margin')
		st.config.global.optionsWindow = { point = 'CENTER', x = 0, y = 0, height = 5000 }
		st.Config:Close(); st.Config:Open('Loot')
		eq(F.window:GetHeight(), OW.MaxHeight(), client .. ': a saved height too tall: the most')
		check(F.window:GetHeight() + above + below + 2 * inset <= UIParent:GetHeight(), client .. ': the window and its metal fit inside the margin')
		switch('thick')
		eq(clamp_insets(F.window), ('%d,%d,%d,%d'):format(-inset, inset, inset, -inset), client .. ': Thick again')
		eq(F.window:GetHeight(), 1080 - 2 * inset, client .. ": Thick's most: no metal")

		-- A margin below 0 lets the window past the screen's edges, but never
		-- grows it past them: its grip stays on screen.
		st.config.global.optionsWindow = nil
		st.Config:Close(); st.Config:Open('Loot')
		st.config.profile.misc.clamp_inset = -30
		st:UpdateScreenMargin()
		eq(clamp_insets(F.window), '30,-30,-30,30', client .. ': Thick: 30 past the edges')
		eq(OW.MaxHeight(), 1080, client .. ': no taller than the screen')
		resize(F.grip, 5000)
		eq(F.window:GetBottom(), 0, client .. ': its bottom on the screen edge')
		switch('blizzard')
		eq(clamp_insets(F.window), ('%d,%d,%d,%d'):format(30 - left, -30 + right, -30 + above, 30 - below), client .. ': Blizzard: the metal 30 past them')
		st.config.profile.misc.clamp_inset = inset
		st:UpdateScreenMargin()
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('a resize under Blizzard moves the scroll bars with the body and the sidebar', function()
	for _, client in ipairs(CLIENTS) do
		world(client)
		for i = 1, 40 do SmallModule('Page' .. i, ('Page %02d'):format(i), 'Frames') end
		switch('blizzard'); st.Config:Open('Long')
		local F = OW.GetFrames()
		local body, nav = st.OptionsBody.Companion(F.bar), st.OptionsBody.Companion(F.navBar)
		for _ = 1, 50 do stub.fire_script(F.body, 'OnMouseWheel', -1) end
		for _ = 1, 100 do stub.fire_script(F.navFrame, 'OnMouseWheel', -1) end
		local renders = OW.GetRenderCount()
		resize(F.sizer, 100)
		tick()
		eq(OW.GetRenderCount(), renders, client .. ': no render')
		eq(F.body:GetHeight(), 639, client .. ': the body 100 taller')
		eq(body.down:GetBottom(), F.body:GetBottom(), client .. ": the body's bar down to its new bottom")
		eq(body.thumb:GetBottom(), body.track:GetBottom(), client .. ': the thumb still at the end')
		eq(F.body:GetVerticalScroll(), F.content:GetHeight() - 639, client .. ': the offset in the new range')
		eq(nav.down:GetBottom(), F.navFrame:GetBottom(), client .. ": the sidebar's bar too")
		eq(F.navFrame:GetVerticalScroll(), F.navContent:GetHeight() - F.navFrame:GetHeight(), client .. ': the nav in its new range')
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('collapsed under Blizzard: only the settings part of the inner frame, from 17; the toggle 16 from the bottom left', function()
	local P = load_test_file('lib/pixels.lua')
	for _, client in ipairs(CLIENTS) do
		world(client)
		CreateFrame('GameTooltip', 'GameTooltip', UIParent)
		st.config.global.optionsWindow = nil
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		local w = F.window
		-- Blizzard's panel button: its pieces are textures of the toggle's.
		local function panel_pieces(frame)
			local n = 0
			for _, region in ipairs({ frame:GetRegions() }) do
				local file = region:GetObjectType() == 'Texture' and region:IsShown() and region:GetTexture()
				if type(file) == 'string' and file:match('^Interface\\Buttons\\UI%-Panel%-Button%-%a+$') and not file:match('Highlight') then n = n + 1 end
			end
			return n
		end
		-- Shown: in the sidebar's foot, as under Thick.
		eq(F.sideToggle:GetParent(), F.foot, client .. ': in the foot')
		eq(F.sideToggle:GetRight(), F.foot:GetRight() - 8, client .. ": 8 in from the foot's right")
		eq(F.profile:GetWidth(), 242 - 61, client .. ': the profile line ends 8 before it')
		eq(panel_pieces(F.sideToggle), 3, client .. ": Blizzard's panel button")
		check(OW:SetSidebarShown(false), client .. ': collapsed at W1')
		eq(at(F.window), '0,0 868x728', client .. ': W2')
		check(not F.innerList:IsShown() and not F.side:IsShown(), client .. ': the list part and the sidebar hidden')
		eq(at(F.innerSettings), '17,28 834x654', client .. ': the settings part from 17')
		eq(at(F.main), '17,28 834x654', client .. ': the main column with it')
		eq(F.sideToggle:GetParent(), F.footer, client .. ': in the footer')
		eq(F.sideToggle:GetLeft() - w:GetLeft(), 16, client .. ": 16 from the window's left")
		eq(F.sideToggle:GetBottom() - w:GetBottom(), 16, client .. ': and 16 up')
		eq(F.sideToggle:GetBottom(), F.closeButton:GetBottom(), client .. ': level with Close')
		eq(panel_pieces(F.sideToggle), 3, client .. ": on Blizzard's panel button")
		eq(F.sideToggle.icon:GetTexture(), st.icons.panelLeftClose, client .. ': the show icon')
		eq(F.footerRegion:GetLeft(), F.tools[#F.tools]:GetRight() + 12, client .. ': the region 12 after the last tool (Task 6)')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(w)
			eq(#off, 0, client .. ' W2 noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0
		stub.time = stub.time + 1
		check(OW:SetWindowSize('half'), client .. ': half')
		eq(at(F.window), '0,0 462x728', client .. ': W4')
		check(not F.innerList:IsShown(), client .. ': no list part')
		eq(at(F.innerSettings), '17,28 428x654', client .. ': W4: the settings part')
		eq(at(F.main), '17,28 428x654')
		eq(F.sideToggle:GetLeft() - w:GetLeft(), 16, client .. ': the toggle still 16 in')
		eq(F.sideToggle:GetBottom() - w:GetBottom(), 16)
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(w)
			eq(#off, 0, client .. ' W4 noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0
		-- Shown again at half: W3 with both parts.
		check(OW:SetSidebarShown(true), client .. ': shown at half')
		eq(at(F.window), '0,0 704x728', client .. ': W3')
		check(F.innerList:IsShown() and F.innerSettings:IsShown(), client .. ': both parts')
		eq(F.sideToggle:GetParent(), F.foot)
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(w)
			eq(#off, 0, client .. ' W3 noise ' .. noise .. ': ' .. P.report(off))
		end
		stub.size_noise = 0
		st.Config:Close()
		st.config.global.optionsWindow = nil
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('collapsed under Blizzard: the footer tools on Blizzard panel buttons, the search panel and the page list on Blizzard art, clear of Reload UI, whole pixels', function()
	local P = load_test_file('lib/pixels.lua')
	for _, client in ipairs(CLIENTS) do
		world(client)
		CreateFrame('GameTooltip', 'GameTooltip', UIParent)
		local ran = 0
		st.Config:AddCommand('kb', 'Keybind mode', function() ran = ran + 1 end, st.icons.keyboard)
		st.Config:AddCommand('two', 'Two', function() ran = ran + 1 end)
		st.config.global.optionsWindow = nil
		switch('blizzard'); st.Config:Open('Loot')
		local F = OW.GetFrames()
		local function panel_pieces(frame)
			local n = 0
			for _, region in ipairs({ frame:GetRegions() }) do
				local file = region:GetObjectType() == 'Texture' and region:IsShown() and region:GetTexture()
				if type(file) == 'string' and file:match('^Interface\\Buttons\\UI%-Panel%-Button%-%a+$') and not file:match('Highlight') then n = n + 1 end
			end
			return n
		end
		check(OW:SetSidebarShown(false), client .. ': collapsed')
		eq(#F.tools, 4, client .. ': Search, Edit mode, two commands')
		local function clear_of_neighbours(where)
			eq(F.tools[1]:GetLeft(), F.sideToggle:GetRight() + 6, client .. where .. ': 6 after the toggle')
			for i = 1, #F.tools do
				eq(F.tools[i]:GetBottom(), F.sideToggle:GetBottom(), client .. where .. ': level with the toggle')
				if i > 1 then eq(F.tools[i]:GetLeft(), F.tools[i - 1]:GetRight() + 6, client .. where .. ': 6 apart') end
			end
			check(F.tools[#F.tools]:GetRight() + 12 <= F.reloadButton:GetLeft() + 1e-3, client .. where .. ': the tools stop short of Reload UI: '
				.. F.tools[#F.tools]:GetRight() .. ' vs ' .. F.reloadButton:GetLeft())
		end
		for i = 1, 4 do eq(panel_pieces(F.tools[i]), 3, client .. ": tool " .. i .. " on Blizzard's panel button") end
		clear_of_neighbours(' W2')
		stub.time = stub.time + 1
		check(OW:SetWindowSize('half'), client .. ': half')
		clear_of_neighbours(' W4')
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			OW:Render()
			local off = P.off(F.window)
			eq(#off, 0, client .. ' W4 tools noise ' .. noise .. ': ' .. P.report(off))
			stub.fire_script(F.tools[1], 'OnClick', 'LeftButton')
			check(F.searchPop:IsShown(), client .. ': the search panel opens')
			off = P.off(F.window)
			eq(#off, 0, client .. ' W4 search panel noise ' .. noise .. ': ' .. P.report(off))
			stub.fire_script(F.tools[1], 'OnClick', 'LeftButton')
			stub.fire_script(F.titleButton, 'OnClick', 'LeftButton')
			eq(W.ListOwner(), F.titleButton, client .. ': the page list opens')
			local list = W.GetListFrames()
			check(list.skin ~= nil and list.skin:IsShown(), client .. ": on the Settings menu's art")
			off = P.off(list.frame)
			eq(#off, 0, client .. ' W4 page list noise ' .. noise .. ': ' .. P.report(off))
			W.CloseList()
		end
		-- More commands, with and without icons: the rest are under the overflow
		-- button, and nothing overlaps Reload UI or Close, at W4 and at W2.
		st.Config:AddCommand('c3', 'Third', function() end, st.icons.search)
		st.Config:AddCommand('c4', 'Fourth', function() end, st.icons.move)
		st.Config:AddCommand('c5', 'Fifth', function() end)
		for _, size in ipairs({ 'half', 'full' }) do
			if size == 'full' then stub.time = stub.time + 1; check(OW:SetWindowSize('full'), client .. ': full') end
			for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
				stub.size_noise = noise
				OW:Render()
				clear_of_neighbours(' more commands ' .. size)
				eq(F.tools[#F.tools].icon:GetTexture(), st.icons.ellipsis, client .. ': the overflow button last')
				eq(panel_pieces(F.tools[#F.tools]), 3, client .. ": on Blizzard's panel button")
				local off = P.off(F.window)
				eq(#off, 0, client .. ' ' .. size .. ' with the overflow button, noise ' .. noise .. ': ' .. P.report(off))
			end
			stub.size_noise = 0
		end
		stub.size_noise = 0
		st.Config:Close()
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)
