-- /sui's frames where they sit today under Thick and Thin, and the window's art
-- under SaftUI's theme Blizzard: the tabs, the sidebar's open page, the search
-- box and the buttons.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local frames, theme, close_all, size_of, click = H.frames, H.theme, H.close_all, H.size_of, H.click
local rgba = H.rgba

-- The textures shown on a frame (shown and not see-through).
local function shown_textures(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 then
			out[#out + 1] = region
		end
	end
	return out
end

-- The atlases shown on a frame, sorted and comma-joined.
local function atlases_of(frame)
	local out = {}
	for _, region in ipairs(shown_textures(frame)) do
		if region:GetAtlas() then out[#out + 1] = region:GetAtlas() end
	end
	table.sort(out)
	return table.concat(out, ',')
end

-- Whether region lies inside frame's rect on screen.
local function within(region, frame)
	local e = 0.001
	return region:GetLeft() >= frame:GetLeft() - e and region:GetRight() <= frame:GetRight() + e
		and region:GetBottom() >= frame:GetBottom() - e and region:GetTop() <= frame:GetTop() + e
end

local function art_inside(frame, name)
	for _, region in ipairs(shown_textures(frame)) do
		check(within(region, frame), name .. ': ' .. tostring(region:GetAtlas() or region:GetTexture()) .. ' inside its rect')
	end
end

-- Every texture shown on frame is anchored to fill it exactly: for the
-- sidebar's entries, which sit in a scroll child the stubs don't place.
local function art_fills(frame, name)
	for _, region in ipairs(shown_textures(frame)) do
		local points = {}
		for i = 1, region:GetNumPoints() do
			local point, rel, relPoint, x, y = region:GetPoint(i)
			check(rel == frame and point == relPoint and x == 0 and y == 0, name .. ': ' .. tostring(region:GetAtlas()) .. ' on its edges')
			points[#points + 1] = point
		end
		table.sort(points)
		eq(table.concat(points, ','), 'BOTTOMRIGHT,TOPLEFT', name .. ': ' .. tostring(region:GetAtlas()) .. ' fills it')
	end
end

local BOX = { fill = rgba(unpack(st.BOX_COLORS.field)), bg = rgba(unpack(st.BOX_COLORS.bg)), edge = rgba(unpack(st.BOX_COLORS.edge)) }

------------------------------------------------------------------ /sui's frames, pinned

test("/sui's frames where they sit today, under Thick and Thin", function()
	-- Where a frame sits in the window: x and y from its top left, and its size.
	local function at(f)
		local w = frames().window
		return ('%d,%d %dx%d'):format(f:GetLeft() - w:GetLeft(), w:GetTop() - f:GetTop(), f:GetWidth(), f:GetHeight())
	end
	-- The flat colors a frame shows, as 'r,g,b,a x,y WxH', sorted.
	local function fills(frame)
		local out = {}
		for _, region in ipairs({ frame:GetRegions() }) do
			local color = region:GetObjectType() == 'Texture' and region:IsShown() and stub.state(region).color_texture
			if color then
				out[#out + 1] = ('%.2f,%.2f,%.2f,%.2f %s'):format(color[1], color[2], color[3], color[4], at(region))
			end
		end
		table.sort(out)
		return table.concat(out, '\n')
	end

	for _, name in ipairs({ 'thick', 'thin' }) do
		st.config.profile.theme.name = name
		st:RedrawThemed() -- the window drawn once already takes the theme, as a switch does
		st.Config:Open('Loot') -- one tab: no tab row
		local F = frames()
		local side = F.navFrame:GetParent()
		local brand = select(2, F.actionsFrame:GetPoint(1))
		eq(at(F.window), '0,0 1040x700', name)
		eq(F.window.backdropInfo.insets.left, name == 'thick' and 2 or 1, name .. ': the border')
		eq(at(side), '2,2 208x696', name)
		eq(at(brand), '2,2 207x73', name)
		eq(at(F.actionsFrame), '2,75 207x44', name)
		eq(at(F.navFrame), '2,120 207x547', name)
		eq(at(F.profile:GetParent()), '2,668 207x30', name)
		eq(at(F.main), '210,2 828x696', name)
		eq(at(F.title):match('^%d+,%d+'), '238,22', name)
		eq(at(F.close), '1000,14 24x24', name)
		eq(at(F.search), '822,83 190x24', name)
		eq(at(F.tabLine), '210,113 828x1', name)
		eq(at(F.body), '238,113 774x539', name)
		eq(at(F.reloadButton:GetParent()), '210,652 828x46', name)
		eq(fills(side), '0.09,0.09,0.09,1.00 2,2 208x696\n0.18,0.18,0.18,1.00 209,2 1x696', name .. ': the fill and edge')
		eq(fills(F.footer):match('^[^\n]*'), '0.18,0.18,0.18,1.00 210,652 828x1', name .. ': the footer line')
		eq(F.tabLine:GetAtlas(), nil, name .. ': the tab line is a color')
		eq(stub.state(F.tabLine).color_texture[1], 0.18, name .. ': the tab line in the lines color')
		-- A group header's rect and where its text sits in it.
		local header
		for _, entry in ipairs(F.nav) do
			if entry.group then header = entry break end
		end
		check(header, name .. ': a group header')
		eq(('%dx%d'):format(header:GetWidth(), header:GetHeight()), '207x29', name .. ': a group header')
		local _, _, _, tx, ty = header.text:GetPoint(1)
		eq(('%d,%d'):format(tx, ty), '18,-12', name .. ': a group header text')
		st.Config:Close()
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ under the Blizzard theme

test("the tabs are Blizzard's Settings tabs, the active one picked, with no underline", function()
	theme('thick')
	st.Config:Open('Inventory', 'bag', 'text')
	local rows = { tab = frames().tabs, subtab = frames().subtabs }
	local sizes = {}
	for slot, tabs in pairs(rows) do
		check(#tabs > 1, 'a row of ' .. slot .. 's')
		for i, tab in ipairs(tabs) do
			eq(atlases_of(tab), '', 'Thick: ' .. slot .. ' ' .. i .. ' has no Blizzard art')
			eq(tab.underline:IsShown(), tab.active, 'Thick: only the active ' .. slot .. ' is underlined')
			sizes[slot .. i] = size_of(tab)
		end
	end

	theme('blizzard')
	rows = { tab = frames().tabs, subtab = frames().subtabs }
	for slot, tabs in pairs(rows) do
		local picked = 0
		for i, tab in ipairs(tabs) do
			local name = slot .. ' ' .. i
			check(not tab.underline:IsShown(), name .. ': no underline')
			if tab.active then
				picked = picked + 1
				eq(atlases_of(tab), 'Options_Tab_Active_Left,Options_Tab_Active_Middle,Options_Tab_Active_Right', name .. ': picked')
			else
				eq(atlases_of(tab), 'Options_Tab_Left,Options_Tab_Middle,Options_Tab_Right', name .. ': a tab')
			end
			art_inside(tab, name)
			eq(size_of(tab), sizes[slot .. i], name .. ' keeps its size')
		end
		eq(picked, 1, 'one ' .. slot .. ' picked')
	end
	-- Another tab picked: the art follows.
	click(frames().subtabs[1])
	for _, tab in ipairs(frames().subtabs) do
		eq(atlases_of(tab):find('Active', 1, true) ~= nil, tab.active, 'the picked subtab follows the pick')
	end

	theme('thick')
	for slot, tabs in pairs({ tab = frames().tabs, subtab = frames().subtabs }) do
		for i, tab in ipairs(tabs) do
			eq(atlases_of(tab), '', 'Thick again: ' .. slot .. ' ' .. i .. ' has no Blizzard art')
			eq(tab.underline:IsShown(), tab.active, 'Thick again: the active ' .. slot .. ' underlined')
		end
	end
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the sidebar's open page sits on Options_List_Active", function()
	theme('thick')
	st.Config:Open('Loot')
	local function items()
		local active, other
		for _, item in ipairs(frames().nav) do
			if item.key and item.active then active = item elseif item.key and not other then other = item end
		end
		return active, other
	end
	local active, other = items()
	check(active.bar:IsShown() and active.bg:IsShown(), "Thick: the open page's blue bar and fill")
	eq(atlases_of(active), '', 'Thick: no Blizzard art')
	stub.fire_script(other, 'OnEnter')
	check(other.bg:IsShown(), 'Thick: the hover fill')
	eq(atlases_of(other), '', 'Thick: no hover art')
	stub.fire_script(other, 'OnLeave')

	theme('blizzard')
	active, other = items()
	eq(atlases_of(active), 'Options_List_Active', 'the open page on Options_List_Active')
	check(not active.bar:IsShown() and not active.bg:IsShown(), 'no blue bar or fill')
	art_fills(active, 'the open page')
	eq(atlases_of(other), '', 'another page: no art')
	stub.fire_script(other, 'OnEnter')
	eq(atlases_of(other), 'Options_List_Hover', 'under the mouse: Options_List_Hover')
	check(not other.bg:IsShown(), 'and no flat hover')
	art_fills(other, 'the page under the mouse')
	stub.fire_script(other, 'OnLeave')
	eq(atlases_of(other), '', 'the mouse gone')
	eq(size_of(active), '226x26', "an entry: the Blizzard layout's nav width, its height kept")

	theme('thick')
	active, other = items()
	check(active.bar:IsShown() and active.bg:IsShown(), "Thick again: the open page's blue bar and fill")
	eq(atlases_of(active), '', 'Thick again: no Blizzard art')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the search box carries SearchBoxTemplate's art", function()
	theme('thick')
	st.Config:Open('Loot')
	local box = frames().search
	local _, _, _, hintX = box.hint:GetPoint(1)
	eq(hintX, 8, 'Thick: the hint 8 in')
	eq(atlases_of(box), '', 'Thick: no Blizzard art')
	check(box.backdropInfo ~= nil and box.outline:IsShown(), 'Thick: its own box')

	theme('blizzard')
	eq(box.backdropInfo, nil, 'its own box off')
	check(not box.outline:IsShown(), 'and its dark line')
	eq(atlases_of(box), 'common-search-border-left,common-search-border-middle,common-search-border-right,common-search-magnifyingglass',
		"SearchBoxTemplate's border and magnifying glass")
	art_inside(box, 'the search box')
	eq(size_of(box), '190x24', 'it keeps its size')
	local glass
	for _, region in ipairs(shown_textures(box)) do
		if region:GetAtlas() == 'common-search-magnifyingglass' then glass = region end
	end
	local _, _, _, glassX = box.hint:GetPoint(1)
	check(glassX >= glass:GetRight() - box:GetLeft(), 'the hint clear of the glass')
	local left = box:GetTextInsets()
	eq(left, glassX, 'and the text starts where the hint does')

	theme('thick')
	eq(atlases_of(box), '', 'Thick again: no Blizzard art')
	check(box.backdropInfo ~= nil and box.outline:IsShown(), 'Thick again: its own box')
	eq(rgba(box:GetBackdropColor()), BOX.fill, 'Thick again: its fill')
	_, _, _, hintX = box.hint:GetPoint(1)
	eq(hintX, 8, 'Thick again: the hint 8 in')
	eq((box:GetTextInsets()), 8, 'Thick again: the text 8 in')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the footer's and the sidebar's buttons are panel buttons", function()
	theme('thick')
	st.Config:Open('Loot')
	local f = frames()
	local buttons = { reload = f.reloadButton, close = f.closeButton, editmode = f.actions[1] }
	local function panel(button)
		local n = 0
		for _, region in ipairs(shown_textures(button)) do
			local file = region:GetTexture()
			if type(file) == 'string' and file:find('UI-Panel-Button-Up', 1, true) then n = n + 1 end
		end
		return n
	end
	local sizes = {}
	for name, button in pairs(buttons) do
		eq(panel(button), 0, 'Thick: ' .. name .. ' is no panel button')
		eq(rgba(button:GetBackdropColor()), BOX.bg, 'Thick: ' .. name .. "'s own fill")
		sizes[name] = size_of(button)
	end

	theme('blizzard')
	for name, button in pairs(buttons) do
		eq(panel(button), 3, name .. " is Blizzard's panel button")
		eq(button.backdropInfo, nil, name .. ': its own box off')
		check(not button.outline:IsShown(), name .. ': and its dark line')
		art_inside(button, name)
		eq(size_of(button), sizes[name], name .. ' keeps its size')
	end

	theme('thick')
	for name, button in pairs(buttons) do
		eq(panel(button), 0, 'Thick again: ' .. name .. ' is no panel button')
		eq(rgba(button:GetBackdropColor()), BOX.bg, 'Thick again: ' .. name .. "'s own fill")
		eq(rgba(button:GetBackdropBorderColor()), BOX.edge, 'Thick again: ' .. name .. "'s own edge")
		check(button.outline:IsShown(), 'Thick again: ' .. name .. "'s dark line")
	end
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
