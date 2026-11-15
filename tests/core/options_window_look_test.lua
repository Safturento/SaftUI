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
st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6) -- not the default, so a reader that draws a grey of its own fails
local OW = st.OptionsWindow
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
		eq(at(F.actionsFrame), '2,75 207x76', name)
		eq(at(F.navFrame), '2,152 207x515', name)
		eq(at(F.profile:GetParent()), '2,668 207x30', name)
		eq(at(F.main), '210,2 828x696', name)
		eq(at(F.title):match('^%d+,%d+'), '238,22', name)
		eq(at(F.close), '1000,14 24x24', name)
		eq(at(F.search), '14,85 182x24', name .. ': the search box in the sidebar, over the buttons')
		eq(at(F.tabLine), '210,113 828x1', name)
		eq(at(F.body), '238,113 774x539', name)
		eq(at(F.reloadButton:GetParent()), '210,652 828x46', name)
		eq(fills(side), '0.09,0.09,0.09,0.90 2,2 208x696\n0.18,0.18,0.18,1.00 209,2 1x696', name .. ': the fill and edge')
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
	eq(size_of(box), '182x24', 'it keeps its size')
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

test("a press leaves the sidebar's and the footer's buttons their size, and a hover their label's colour", function()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		st.Config:Open('Loot')
		local f = frames()
		local green = st.config.profile.colors.text.success
		for name, button in pairs({ reload = f.reloadButton, close = f.closeButton, editmode = f.actions[1] }) do
			local before = size_of(button)
			stub.fire_script(button, 'OnMouseDown', 'LeftButton')
			eq(size_of(button), before, look .. ': ' .. name .. ' keeps its size while pressed')
			stub.fire_script(button, 'OnMouseUp', 'LeftButton')
			eq(size_of(button), before, look .. ': ' .. name .. ' keeps its size once let go')
		end
		eq(size_of(f.actions[1]), '88x24', look .. ': Edit mode is the sidebar\'s 88 x 24')
		-- Edit mode's green label (edit mode on) survives the mouse passing over.
		local edit = f.actions[1]
		edit.text:SetTextColor(green:GetRGB())
		stub.fire_script(edit, 'OnEnter', true)
		stub.fire_script(edit, 'OnLeave', true)
		local gr, gg, gb = green:GetRGB()
		eq(rgba(edit.text:GetTextColor()), rgba(gr, gg, gb, 1), look .. ': its green after a hover')
		close_all()
	end
	theme('thick')
	local errors = take_errors()
	eq(#errors, 0, 'no errors: ' .. table.concat(errors, ' | '))
end)

test("the footer control is the options kit's own widgets, so it takes both looks", function()
	theme('thick')
	st.Config:Open('Unitframes', 'player', 'general')
	local function pieces()
		local w = frames().footerWidgets
		return w[1], w[2]
	end
	-- How many of Blizzard's panel button pieces a button shows.
	local function panel(button)
		local n = 0
		for _, region in ipairs(shown_textures(button)) do
			local file = region:GetTexture()
			if type(file) == 'string' and file:find('UI-Panel-Button-Up', 1, true) then n = n + 1 end
		end
		return n
	end
	local function centred(where)
		local f = frames()
		local region = f.footerRegion
		local left = f.footerLabel:GetLeft() - region:GetLeft()
		local right = region:GetRight() - f.footerWidgets[2].frame:GetRight()
		check(math.abs(left - right) <= 1, where .. ': centred between Reload UI and Close: ' .. left .. ' and ' .. right)
	end
	local dropdown, manage = pieces()
	eq(atlases_of(dropdown.frame), '', 'Thick: the dropdown has no Blizzard art')
	check(dropdown.frame.backdropInfo ~= nil and dropdown.frame.outline:IsShown(), 'Thick: its own box')
	eq(panel(manage.frame), 0, 'Thick: Manage is no panel button')
	check(manage.frame.backdropInfo ~= nil, 'Thick: its own box')
	centred('Thick')

	theme('blizzard')
	dropdown, manage = pieces()
	check(atlases_of(dropdown.frame):find('common-dropdown-c-button', 1, true) ~= nil, "Blizzard: the Settings dropdown")
	eq(dropdown.frame.backdropInfo, nil, 'Blizzard: its own box off')
	eq(panel(manage.frame), 3, "Blizzard: Manage is Blizzard's panel button")
	centred('Blizzard, the footer across the window')

	theme('thick')
	dropdown, manage = pieces()
	eq(atlases_of(dropdown.frame), '', 'Thick again: no Blizzard art')
	eq(panel(manage.frame), 0, 'Thick again: no panel button')
	centred('Thick again')
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ a disabled tab, and a centred fill line, in every theme

test('a disabled tab stays in its place, faded and taking no click, under Thick, Thin and Blizzard', function()
	local off = false
	local module = st:GetModule('FadedTabs', true) or st:NewModule('FadedTabs')
	function module:GetConfigTable()
		local function tab(name, order, fields)
			local group = { type = 'group', name = name, order = order, args = {
				on = { type = 'toggle', name = name .. ' on', desc = name, get = function() return true end, set = function() end },
			} }
			for key, value in pairs(fields or {}) do group[key] = value end
			return group
		end
		return {
			name = 'Faded tabs', type = 'group', category = 'Frames',
			args = {
				one = tab('One', 1),
				two = tab('Two', 2, { disabled = function() return off end }),
				three = tab('Three', 3, { disabled = function() return off end }),
			},
		}
	end
	local function tabs_by_key()
		local out = {}
		for _, tab in ipairs(frames().tabs) do out[tab.key] = tab end
		return out
	end

	st.Config:Open('FadedTabs')
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		theme(name)
		off = false
		st.OptionsWindow:Render()
		local places = {}
		for key, tab in pairs(tabs_by_key()) do
			places[key] = tab:GetLeft() .. ',' .. tab:GetTop() .. ',' .. size_of(tab)
			eq(tab:GetAlpha(), 1, name .. ': ' .. key .. ' whole while enabled')
		end
		local top = frames().body:GetTop()

		off = true
		st.OptionsWindow:Render()
		local now = tabs_by_key()
		eq(now.one:GetAlpha(), 1, name .. ': the enabled tab whole')
		for _, key in ipairs({ 'two', 'three' }) do
			eq(now[key]:GetAlpha(), 0.4, name .. ': ' .. key .. ' faded')
			eq(now[key]:GetLeft() .. ',' .. now[key]:GetTop() .. ',' .. size_of(now[key]), places[key], name .. ': ' .. key .. ' where it was')
		end
		eq(frames().body:GetTop(), top, name .. ': the page under the tabs does not move')
		click(now.two)
		eq(st.OptionsWindow:GetState().tab, 'one', name .. ': a click on a disabled tab opens nothing')
		stub.fire_script(now.two, 'OnEnter')
		local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
		eq(rgb(now.two.text:GetTextColor()), rgb(st.config.profile.colors.text.muted:GetRGB()), name .. ': nor lights it')
		stub.fire_script(now.two, 'OnLeave')
	end
	theme('thick')
	module.GetConfigTable = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a description with fill and justifyH CENTER sits in the middle of what the page leaves, across and down, under Thick, Thin and Blizzard', function()
	local module = st:GetModule('CentredLine', true) or st:NewModule('CentredLine')
	local function toggle(name, order, size)
		return { type = 'toggle', name = name, desc = name, order = order, size = size, get = function() return true end, set = function() end }
	end
	local function page()
		return {
			name = 'Centred line', type = 'group', category = 'Frames',
			args = {
				switch = toggle('Switch', 1, 'small'),
				box = toggle('Box', 2),
				line = { type = 'description', name = 'Sourced from elsewhere', order = 3, justifyH = 'CENTER', fill = true },
			},
		}
	end
	module.GetConfigTable = page
	local lineHeight = math.floor(15 * 1.3)

	local function check_centred(name)
		local F = frames()
		local view = F.body:GetHeight()
		local c = H.cell('line')
		eq(H.drawn(), 'switch,box,line', name .. ': the line after the switches')
		-- Rows are 38 tall under Thick and Thin, 34 under Blizzard.
		eq(c.y, H.cell('box').y + (name == 'Blizzard' and 34 or 38), name .. ': on the line after them')
		eq(c.y + c.height + 24, view, name .. ': its row takes what the page leaves (less the bottom padding)')
		local w = c.widget
		eq(w:GetHeight(), c.height - 12, name .. ': the description as tall as its row less its padding')
		eq(w.frame:GetWidth(), 774, name .. ": the body's width")
		eq(w.text:GetJustifyH(), 'CENTER', name .. ': its text centred across it')
		eq(w.text:GetLeft() .. '-' .. w.text:GetRight(), w.frame:GetLeft() .. '-' .. w.frame:GetRight(), name .. ': the text spans it')
		eq(w.text:GetTop(), w.frame:GetTop() - math.floor((w:GetHeight() - lineHeight) / 2), name .. ': in the middle of it, down')
		eq(F.content:GetHeight(), view, name .. ': nothing to scroll')
		check(not F.bar:IsShown(), name .. ': no bar')
		return c
	end

	st.Config:Open('CentredLine')
	local F = frames()
	check_centred('Thick')
	eq(F.body:GetRight() - F.content:GetRight(), 13, "Thick: the body reaches over its bar's place, as on any fill page")

	-- A taller window: the line follows, still in the middle.
	local before = H.cell('line').height
	F.window:SetHeight(F.window:GetHeight() + 100)
	stub.fire_script(F.body, 'OnSizeChanged', F.body:GetWidth(), F.body:GetHeight())
	H.tick()
	eq(H.cell('line').height, before + 100, 'a taller window: its row 100 taller')
	check_centred('Thick, taller')
	F.window:SetHeight(F.window:GetHeight() - 100)
	stub.fire_script(F.body, 'OnSizeChanged', F.body:GetWidth(), F.body:GetHeight())
	H.tick()

	theme('thin')
	check_centred('Thin')
	theme('blizzard')
	check_centred('Blizzard')
	eq(F.body:GetRight() - F.content:GetRight(), 25, "Blizzard: the body reaches over Blizzard's bar's place")
	theme('thick')
	close_all()

	-- With no height to fill (a dialog's body, search results): as tall as its text.
	local root = { CentredLine = page() }
	for _, look in ipairs({ { 'thick', 38 }, { 'blizzard', 34 } }) do
		local name, rowHeight = look[1], look[2]
		st.config.profile.theme.name = name
		local content = CreateFrame('Frame', nil, UIParent)
		content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
		content:SetSize(520, 300)
		local body = st.OptionsBody.New(content, root, nil, 520)
		body:Draw(st.OptionsModel.BuildView(root, 'CentredLine').sections)
		local c
		for _, each in ipairs(body.cells) do if each.row.key == 'line' then c = each end end
		eq(c.height, rowHeight, name .. ': no fill height: a row as tall as any one-line description')
		eq(c.widget:GetHeight(), rowHeight - 12, name .. ': the description told that, less its padding')
		eq(c.widget.text:GetTop(), c.widget.frame:GetTop() - math.floor((rowHeight - 12 - lineHeight) / 2), name .. ': its text in the middle')
		eq(c.widget.text:GetJustifyH(), 'CENTER', name .. ': and centred across')
		body:Release()
	end
	st.config.profile.theme.name = 'thick'
	module.GetConfigTable = nil
	eq(#take_errors(), 0, 'no errors')
end)
