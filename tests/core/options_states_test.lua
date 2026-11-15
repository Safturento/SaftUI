-- Every state of /sui's window, checked together (SaftUI-Core/Config/optionswindow.lua,
-- optionssizes.lua, optionsnav.lua and the pages), and the size arrows' Blizzard
-- art (optionssizes.lua's S.LookSizeButton, themeart_data.lua's ART.sizebutton).
--
-- The states are W1 (full, sidebar shown), W2 (full, collapsed), W3 (half, shown),
-- W4 (half, collapsed) and W5 (the bar), and W6, the bar with the sidebar
-- collapsed (it keeps the sidebar's state). The matrix walks them on both
-- clients, under Thick, Thin and Blizzard, on the pages the window really has
-- (Global settings, the Theme tab of Fonts, Profiles, Action bars, Unit frames with its
-- Unit, Copy from, Profile and Manage line, the Bags' Categories tab, Loot, Skinning and a
-- search), one transition at a time, and at each state checks: every edge on a
-- whole pixel (with the size noise up, down and off, in turn); no two of the
-- window's controls overlap and none passes the window; the page's own pieces
-- (tabs, the picker's line, its rows) inside the body; the top right corner, the
-- close X and the page's right edge where they were; the page, pick, tab and
-- search kept; and on some states the window closed and opened again, which
-- restores the state. To stay fast the size noise and the reopen are
-- sampled by a fixed rule (see NOISES and REOPEN_EVERY): every state of every
-- page on every look and client is walked, but each with one noise value, and
-- each fourth with a reopen.
--
-- Real: Core's Config on a real AceDB (the Categories tab's world,
-- bags/categories_world.lua: the bags' views world with Core's config, the
-- options window and the Bags' options, dragparts, rule editor and Categories
-- tab) with, over it, the real options files of Unit frames (with the profile
-- line), Loot, Action bars and Skinning, and their stand-ins for what needs the
-- game's frames (as options_frames_pages_test.lua and profile_control_test.lua
-- have them). The window's clock and the mouse are played by firing scripts.
local CW = load_test_file('bags/categories_world.lua')
local P = load_test_file('lib/pixels.lua')

local CLIENTS = { 'forever', 'retail' }
local LOOKS = { 'thick', 'thin', 'blizzard' }
local NOISES = { 2 ^ -14, -2 ^ -14, 0 }
local REOPEN_EVERY = 4

local st, OW, W
local tick = tick_options_window
local click = stub.click
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

------------------------------------------------------------------ the world

-- A fresh world on client: the Categories tab's, and the pages of Unit frames,
-- Loot, Skinning and Action bars over it.
local loaded
local function world(client)
	-- The tests run client by client, so the world is built once for each.
	if loaded == client then return end
	loaded = client
	local _, INV
	_, st, INV, _, OW, _, W = CW.world(client)
	load_saftui('SaftUI-Unitframes/config/position.lua')
	load_saftui('SaftUI-Unitframes/config/default.lua')
	for _, file in ipairs({ 'player', 'target', 'party', 'nameplate', 'friendlynameplate' }) do
		load_saftui('SaftUI-Unitframes/config/units/' .. file .. '.lua')
	end
	apply_defaults()
	local UF = st:NewModule('Unitframes')
	function UF:UpdateConfig() local _ = self:GetProfileConfig().player end
	UF.units = { player = CreateFrame('Frame', nil, UIParent), target = CreateFrame('Frame', nil, UIParent) }
	UF.groups, UF.holders, UF.elements = { party = CreateFrame('Frame', nil, UIParent) }, { party = CreateFrame('Frame', nil, UIParent) }, {}
	UF.unit_strings, UF.group_strings = { player = 'Player', target = 'Target' }, { party = 'Party' }
	function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end
	load_saftui('SaftUI-Unitframes/config/profiles.lua')
	load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
	load_saftui('SaftUI-Unitframes/config/config.lua')
	load_saftui('SaftUI-Unitframes/nameplates/options.lua')

	load_saftui('SaftUI-Loot/config.lua')
	load_saftui('SaftUI-Loot/init.lua')
	local LT = st:GetModule('Loot')
	st:BindModuleConfig(LT, 'loot')
	LT.rollAnchor, LT.feed = CreateFrame('Frame', nil, UIParent), CreateFrame('Frame', nil, UIParent)
	function LT:UpdateGroupLootConfig() end
	function LT:UpdateLootFeedConfig() end
	function LT:UpdateConfig() end -- builds Blizzard's roll frames and the feed's lines
	load_saftui('SaftUI-Loot/options.lua')

	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	st:GetModule('Skinning').config = st.config.profile.skinning

	load_saftui('SaftUI-ActionBars/config.lua')
	load_saftui('SaftUI-ActionBars/init.lua')
	apply_defaults()
	local AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	AB.EXTRA_IDS = { 'extra', 'zone', 'vehicleleave' }
	AB.EXTRA_LABELS = { extra = 'Extra action button', zone = 'Zone ability', vehicleleave = 'Leave vehicle button' }
	AB.built = true
	AB.bars, AB.extras = {}, {}
	for _, id in ipairs(AB.BAR_IDS) do
		AB.bars[id] = { buttons = {} }
		for i = 1, (id == 'pet' or id == 'stance') and 10 or 12 do AB.bars[id].buttons[i] = {} end
	end
	for _, id in ipairs(AB.EXTRA_IDS) do AB.extras[id] = CreateFrame('Frame', nil, UIParent) end
	AB.barTypes = { pet = { texts = { hotkey = true, countdown = true } }, stance = { texts = { hotkey = true, countdown = true } } }
	local function nothing() return function() end end
	function AB:ShowsCooldownNumbers() return true end -- reads Blizzard's cvar
	-- The page asks the numbers' drawn font (a text's Size and Outline hide while it is a shared font).
	function AB:GetCountdownFont(config)
		return config.size >= st.LARGE_COUNTDOWN_SIZE and 'pixel_med' or 'pixel', 12, 'NONE'
	end
	AB.UpdateBar, AB.UpdateBars, AB.LayoutBar, AB.LayoutExtra, AB.UpdateConfig = nothing(), nothing(), nothing(), nothing(), nothing()
	load_saftui('SaftUI-ActionBars/shared.lua')
	load_saftui('SaftUI-ActionBars/textoptions.lua')
	load_saftui('SaftUI-ActionBars/options.lua')
	take_errors()
	return INV
end

local function frames() return OW.GetFrames() end
local function wait() stub.time = stub.time + 0.31 end

-- SaftUI's theme switched, as the Theme tab does it, and the window's next frame.
local function look(name)
	st.config.profile.theme.name = name
	st:ThemeChanged()
	if OW:IsShown() then tick() end
end

-- Nothing saved, nothing open.
local function reset()
	stub.size_noise = 0
	stub.in_combat = false
	st.config.global.optionsWindow = nil
	st.Config:Close()
	if W.ColorPickerShown() then W.CloseColorPicker() end
	st.config.global.optionsWindow = nil
	stub.screen_width, stub.screen_height = 1920, 1080
end

------------------------------------------------------------------ the states

local STATES = {
	W1 = { size = 'full', sidebar = true }, W2 = { size = 'full', sidebar = false },
	W3 = { size = 'half', sidebar = true }, W4 = { size = 'half', sidebar = false },
	W5 = { size = 'mini', sidebar = true }, W6 = { size = 'mini', sidebar = false },
}
local FIVE = { 'W1', 'W2', 'W3', 'W4', 'W5' }
local RANK = { full = 1, half = 2, mini = 3 }

local function set_sidebar(shown)
	if OW:IsSidebarShown() == shown then return end
	wait()
	check(OW:SetSidebarShown(shown), 'the sidebar ' .. (shown and 'shows' or 'collapses'))
end

local function set_size(size)
	while OW:GetWindowSize() ~= size do
		wait()
		local step = RANK[size] > RANK[OW:GetWindowSize()] and 1 or -1
		local nextSize = OW.NextSize(OW:GetWindowSize(), step)
		check(OW:SetWindowSize(nextSize), 'the window goes to ' .. tostring(nextSize))
	end
end

-- One transition at a time to state: the sidebar is set while the window isn't
-- the bar (the bar keeps it).
local function go(name)
	local state = STATES[name]
	if state.size == 'mini' then
		set_sidebar(state.sidebar)
		set_size('mini')
	else
		set_size(state.size)
		set_sidebar(state.sidebar)
	end
	tick()
end

-- The state the window is in now, as a name.
local function now()
	local size, sidebar = OW:GetWindowSize(), OW:IsSidebarShown()
	for name, state in pairs(STATES) do
		if state.size == size and state.sidebar == sidebar then return name end
	end
end

------------------------------------------------------------------ the pages

-- The Categories tab's widget, as the window drew it last.
local function categories() return CW.tab() end

local PAGES = {
	{ name = 'Global settings', open = function() st.Config:Open('Fonts', 'general') end },
	{ name = 'Theme tab', open = function() st.Config:Open('Fonts', 'theme') end },
	{ name = 'Profiles', open = function() st.Config:Open('profile') end },
	{ name = 'Action bars', open = function() st.Config:Open('ActionBars') end },
	{ name = 'Unit frames', open = function() st.Config:Open('Unitframes', 'player', 'general') end, line = true },
	{ name = 'Bags: Categories', open = function() st.Config:Open('Inventory', 'categories') end, categories = true },
	{ name = 'Loot', open = function() st.Config:Open('Loot') end },
	{ name = 'Skinning', open = function() st.Config:Open('Skinning') end },
	{ name = 'Search', open = function()
		st.Config:Open('Skinning')
		frames().search:SetText('Theme')
		tick(0.3)
	end, search = 'Theme' },
}

------------------------------------------------------------------ what is checked

local function near(a, b) return math.abs(a - b) < 1e-3 end

local function rect(f)
	return { l = f:GetLeft(), r = f:GetRight(), t = f:GetTop(), b = f:GetBottom() }
end

local function overlap(a, b)
	return math.min(a.r, b.r) - math.max(a.l, b.l) > 0.5 and math.min(a.t, b.t) - math.max(a.b, b.b) > 0.5
end

-- The window's controls that must not overlap one another or pass the window,
-- as { name, frame } for each one that shows.
local function chrome(F)
	local list = {}
	local function add(name, f)
		if f and f:IsVisible() and f:GetLeft() then list[#list + 1] = { name = name, f = f } end
	end
	add('close', F.close)
	add('shrink', F.shrink)
	add('grow', F.grow)
	add('miniGrow', F.miniGrow)
	add('miniBrand', F.miniBrand)
	add('miniPage', F.miniPage)
	add('miniTab', F.miniTab)
	add('title', F.title)
	add('sideToggle', F.sideToggle)
	add('profile', F.profile)
	for i, tool in ipairs(F.tools or {}) do add('tool' .. i, tool) end
	add('reload', F.reloadButton)
	add('closeButton', F.closeButton)
	add('picker', F.picker and F.picker.frame)
	for i, widget in ipairs(F.pickerWidgets or {}) do add('pickerWidget' .. i, widget.frame) end
	for i, tab in ipairs(F.tabs or {}) do add('tab' .. i, tab) end
	for i, tab in ipairs(F.subtabs or {}) do add('subtab' .. i, tab) end
	return list
end

-- The window's rect, grown by the metal's reach under Blizzard, whose close
-- button sits in a socket that reaches past the drawn frame.
local function room(F)
	local w = rect(F.window)
	if st:IsBlizzardLook('theme', 'theme') then
		local left, right, top, bottom = st.ThemeArt.MetalReach()
		w.l, w.r, w.t, w.b = w.l - left, w.r + right, w.t + top, w.b - bottom
	end
	return w
end

local function check_state(where, page, base)
	local F = frames()
	local w = F.window
	-- Whole pixels.
	local off = P.off(w)
	eq(#off, 0, where .. ': whole pixels: ' .. P.report(off))
	-- Nothing overlaps, nothing passes the window.
	local list, window = chrome(F), room(F)
	check(#list >= (OW:GetWindowSize() == 'mini' and 4 or 6), where .. ': the controls are found: ' .. #list)
	for i, a in ipairs(list) do
		local ra = rect(a.f)
		check(ra.l >= window.l - 1e-3 and ra.r <= window.r + 1e-3 and ra.t <= window.t + 1e-3 and ra.b >= window.b - 1e-3,
			where .. ': ' .. a.name .. ' is inside the window')
		for j = i + 1, #list do
			check(not overlap(ra, rect(list[j].f)), where .. ': ' .. a.name .. ' overlaps ' .. list[j].name)
		end
	end
	-- The page's own pieces are inside the body.
	if F.main:IsShown() then
		local main = rect(F.main)
		for _, item in ipairs(list) do
			if item.name:match('^tab') or item.name:match('^subtab') or item.name:match('^picker') then
				local r = rect(item.f)
				check(r.r <= main.r + 1e-3 and r.l >= main.l - 1e-3, where .. ': ' .. item.name .. ' is inside the main column')
			end
		end
		local content = rect(F.content)
		for _, cell in ipairs(OW.GetDrawnRows()) do
			if cell.frame and cell.frame:IsVisible() then
				local r = rect(cell.frame)
				check(r.l >= content.l - 1e-3 and r.r <= content.r + 1e-3, where .. ': row ' .. tostring(cell.row.key) .. ' is inside the body')
			end
		end
	end
	-- The corner, the close X and the page's right edge where they were. The bar
	-- under Blizzard sits where the metal's corner was (OW.MiniShift).
	local size = OW:GetWindowSize()
	local dx, dy = 0, 0
	if size == 'mini' then dx, dy = OW.MiniShift(OW.S.layout) end
	check(near(w:GetRight(), base.right + dx), where .. ': the right edge')
	check(near(w:GetTop(), base.top + dy), where .. ': the top')
	if size ~= 'mini' then
		check(near(F.close:GetRight(), base.closeRight), where .. ': the close X, right')
		check(near(F.close:GetTop(), base.closeTop), where .. ': the close X, top')
		check(near(F.main:GetRight(), base.mainRight), where .. ': the page\'s right edge')
		-- The scroll bar, where it shows (a page that fits has none), is as far in from the window's right as it was.
		if F.bar:IsShown() and F.bar:GetRight() then
			local inset = w:GetRight() - F.bar:GetRight()
			if base.barInset == nil then base.barInset = inset end
			check(near(inset, base.barInset), where .. ': the scroll bar: ' .. inset .. ' in from the right, not ' .. base.barInset)
		end
	else
		eq(F.close:GetRight(), w:GetRight() - OW.S.MINI_PAD, where .. ': the bar\'s close X, 8 in')
		check(F.mini:IsShown() and not F.main:IsShown(), where .. ': the bar is drawn alone')
	end
	-- The width the pure functions give (the bar's is even and at most OW.MINI_MAX, 42 tall), an even height.
	local width, height = math.floor(w:GetWidth() + 0.5), math.floor(w:GetHeight() + 0.5) -- read back with the noise
	if size == 'mini' then
		eq(width % 2, 0, where .. ': the bar\'s width is even: ' .. width)
		check(width <= OW.MINI_MAX, where .. ': the bar is at most ' .. OW.MINI_MAX .. ' wide: ' .. width)
		eq(height, OW.MINI_HEIGHT, where .. ': the bar is 42 tall')
	else
		eq(width, OW.WindowWidth(OW.S.layout, size, OW:IsSidebarShown()), where .. ': the width the table gives')
		eq(width % 2, 0, where .. ': even')
		eq(height % 2, 0, where .. ': an even height')
	end
	-- The save follows the state: half for half and the bar, nothing for full; false for a collapsed sidebar.
	local saved = st.config.global.optionsWindow
	saved = type(saved) == 'table' and saved or {}
	if size == 'full' then eq(saved.size, nil, where .. ': nothing saved for full') else eq(saved.size, 'half', where .. ': half saved') end
	if OW:IsSidebarShown() then eq(saved.sidebar, nil, where .. ': nothing saved for a shown sidebar') else eq(saved.sidebar, false, where .. ': false saved for a collapsed one') end
	-- The page kept.
	local state = OW:GetState()
	eq(state.page, page.state.page, where .. ': the page')
	eq(state.pick, page.state.pick, where .. ': the pick')
	eq(state.tab, page.state.tab, where .. ': the tab')
	eq(state.search, page.state.search, where .. ': the search')
	-- What is the page's own.
	if size ~= 'mini' then
		if page.line then
			local widgets = F.pickerWidgets
			eq(#widgets, 3, where .. ': the unit line holds Copy from, Profile and Manage')
			for _, widget in ipairs(widgets) do check(widget.frame:IsVisible(), where .. ': a piece of the line shows') end
			local labels = 0
			for _, label in ipairs(F.pickerLabels) do if label:IsShown() then labels = labels + 1 end end
			check(labels >= 1, where .. ': the Profile label shows')
		end
		if page.categories then
			local tab = categories()
			eq(tab.menuButton:IsVisible(), size ~= 'full', where .. ': the category list is a menu exactly when it is not full')
			if size == 'full' then check(tab.listScroll:IsVisible(), where .. ': the list is beside the editor at full') end
			local r, content = rect(tab.menuButton:IsVisible() and tab.menuButton or tab.listScroll), rect(F.content)
			check(r.r <= content.r + 1e-3, where .. ': the list or its button is inside the body')
		end
	end
end

------------------------------------------------------------------ the matrix

-- The cases, each run on both clients, client by client (the world is built
-- once per client): per_client(name, function(client, clientIndex) ... end).
local CASES = {}
local function per_client(name, fn) CASES[#CASES + 1] = { name = name, fn = fn } end

-- Walks page through route (state names, in order) on client's current look,
-- with the checks of check_state at each, the size noise in turn and the
-- window closed and opened again on some. Returns the number of states checked.
local counter = 0
local function walk(client, lookName, pageIndex, page, route, base_tag)
	reset()
	page.open()
	local F = frames()
	local state = OW:GetState()
	page.state = { page = state.page, pick = state.pick, tab = state.tab, search = state.search }
	if page.search then eq(page.state.search, page.search, 'a search is on') end
	eq(now(), 'W1', client .. ' ' .. lookName .. ' ' .. page.name .. ': opens at W1')
	local base = {
		right = F.window:GetRight(), top = F.window:GetTop(), closeRight = F.close:GetRight(),
		closeTop = F.close:GetTop(), mainRight = F.main:GetRight(),
	}
	local checked = 0
	for step, target in ipairs(route) do
		counter = counter + 1
		stub.size_noise = NOISES[counter % #NOISES + 1]
		local where = ('%s %s %s %s%s -> %s (noise %s)'):format(client, lookName, page.name, base_tag or '', step, target, tostring(stub.size_noise))
		go(target)
		eq(now(), target, where .. ': the state')
		check_state(where, page, base)
		checked = checked + 1
		if (step + pageIndex) % REOPEN_EVERY == 0 then
			-- Close and open again: the state comes back (the bar as half).
			st.Config:Close()
			page.open()
			local want = STATES[target]
			eq(OW:GetWindowSize(), want.size == 'mini' and 'half' or want.size, where .. ': reopened at its size')
			eq(OW:IsSidebarShown(), want.sidebar, where .. ': reopened with its sidebar')
			tick()
			go(target)
			check_state(where .. ' reopened', page, base)
		end
	end
	eq(#take_errors(), 0, client .. ' ' .. lookName .. ' ' .. page.name .. ': no errors')
	return checked
end

-- Every page on every look, in every state, on one client or the other: the
-- states in ORDER are dealt out so that each (page, look, state) is walked once
-- on one of the two clients (the one (page + look + state) is even or odd for),
-- and a page is walked in three states of six on each. The whole matrix is
-- 54 page-and-look pairs, which walked in all six states on both clients
-- took half a minute; this takes a fifth of that. The long walk below goes
-- through every transition on the Unit frames page.
local ORDER = { 'W1', 'W2', 'W4', 'W6', 'W5', 'W3' }

do
	per_client('every page in its states under every look: whole pixels, nothing overlapping or outside, the corner and the page edge fixed, the saved state restored', function(client, clientIndex)
		world(client)
		local checked = 0
		for lookIndex, lookName in ipairs(LOOKS) do
			look(lookName)
			for pageIndex, page in ipairs(PAGES) do
				local route = {}
				for stateIndex, name in ipairs(ORDER) do
					if (pageIndex + lookIndex + stateIndex) % 2 == clientIndex % 2 then route[#route + 1] = name end
				end
				checked = checked + walk(client, lookName, pageIndex, page, route)
			end
		end
		reset()
		look('thick')
		check(checked >= #PAGES * #LOOKS * #ORDER / 2 - 1, 'the states were walked: ' .. checked)
	end)
end

-- Every transition, on the Unit frames page (its line of Unit, Copy from, Profile and
-- Manage is the widest thing at half), where Blizzard is the look with the most to
-- move: the window up and down through all six states, on both clients, under
-- Blizzard and under Thick (forever) and Thin (retail).
local WALK = { 'W2', 'W4', 'W3', 'W5', 'W3', 'W4', 'W6', 'W4', 'W2', 'W1', 'W3', 'W1' }
per_client('every transition on the Unit frames page keeps the corner, the close X and the page edge', function(client)
	local unit
	for i, page in ipairs(PAGES) do if page.name == 'Unit frames' then unit = i end end
	check(unit, 'the page is listed')
	world(client)
	for _, name in ipairs({ 'blizzard', client == 'forever' and 'thick' or 'thin' }) do
		look(name)
		walk(client, name, unit, PAGES[unit], WALK, 'transition ')
	end
	reset()
	look('thick')
end)

------------------------------------------------------------------ the art

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

-- The files shown on a frame's textures (the panel button's), sorted and comma-joined.
local function files_of(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		local file = region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAlpha() > 0 and region:GetTexture()
		if type(file) == 'string' and file:find('UI%-Panel%-Button') then out[#out + 1] = file end
	end
	table.sort(out)
	return table.concat(out, ',')
end

local function tip_text(button)
	local title, lines = button.tip(button)
	local out = { title }
	for _, line in ipairs(lines or {}) do
		out[#out + 1] = type(line) == 'table' and ((line.danger and 'danger:' or '') .. line.text) or line
	end
	return table.concat(out, ' | ')
end

local function sorted(...)
	local names = { ... }
	table.sort(names)
	return table.concat(names, ',')
end

do
	per_client("under Blizzard the size arrows wear Blizzard's expand and condense art", function(client)
		world(client)
		reset()
		local art = st.ThemeArt.Control('sizebutton')
		check(art ~= nil, client .. ' has the art')
		eq(art.size, 24, "the template's 24 square")
		check(C_Texture.GetAtlasInfo(art.grow.normal) and C_Texture.GetAtlasInfo(art.shrink.disabled), 'its atlases exist')
		look('blizzard')
		st.Config:Open('Loot')
		wait(); OW:SetWindowSize('half')
		local F = frames()
		local glow = art.highlight
		-- Shrink wears the condense art, grow the expand art, the box and chevrons hidden.
		eq(atlases_of(F.shrink), sorted(art.shrink.normal, glow), 'shrink: Condense')
		eq(atlases_of(F.grow), sorted(art.grow.normal, glow), 'grow: Expand')
		for _, button in ipairs({ F.shrink, F.grow }) do
			check(not button.icon:IsShown(), 'the chevron is hidden')
			eq(button.backdropInfo, nil, 'the box is off')
			check(not button.outline:IsShown(), 'and its dark line')
			eq(files_of(button), '', "Blizzard's panel button is hidden under the art")
			eq(button:GetWidth() .. 'x' .. button:GetHeight(), '24x24', 'the close X\'s size')
		end
		for _, region in ipairs({ F.shrink:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:GetAtlas() == art.shrink.normal then
				eq(region:GetWidth() .. 'x' .. region:GetHeight(), '24x24', 'the art at its size')
				local cx, cy = region:GetCenter()
				local bx, by = F.shrink:GetCenter()
				eq(cx .. ',' .. cy, bx .. ',' .. by, 'centred where the square is')
			end
		end
		-- The tooltip is the same, and so is the pressed art.
		stub.fire_script(F.shrink, 'OnEnter', true)
		check(GameTooltip:IsOwned(F.shrink) and GameTooltip:IsShown(), 'the tooltip shows')
		eq(tip_text(F.shrink), 'Shrink to a bar | A small bar, to see the whole UI. It keeps the page.')
		stub.fire_script(F.shrink, 'OnLeave', true)
		stub.fire_script(F.shrink, 'OnMouseDown', 'LeftButton')
		eq(atlases_of(F.shrink), sorted(art.shrink.pushed, glow), 'pressed: Condense-Pressed')
		stub.fire_script(F.shrink, 'OnMouseUp', 'LeftButton')
		eq(atlases_of(F.shrink), sorted(art.shrink.normal, glow), 'let go: normal again')
		-- Disabled (the color picker is open): the disabled art, the red line, still the mouse.
		check(W.OpenColorPicker(F.window, { r = 1, g = 0, b = 0, onChange = function() end }), 'the picker opens')
		check(F.shrink.disabled and F.grow.disabled, 'both disabled')
		eq(atlases_of(F.shrink), art.shrink.disabled, 'shrink: Condense-Disabled, no highlight')
		eq(atlases_of(F.grow), art.grow.disabled, 'grow: Expand-Disabled')
		eq(F.shrink:GetAlpha(), 0.4, 'at the disabled alpha, as under every look')
		eq(tip_text(F.shrink), 'Shrink to a bar | A small bar, to see the whole UI. It keeps the page. | danger:Close the color picker first.')
		stub.fire_script(F.shrink, 'OnMouseDown', 'LeftButton')
		eq(atlases_of(F.shrink), art.shrink.disabled, 'a disabled arrow is not pressed')
		stub.fire_script(F.shrink, 'OnMouseUp', 'LeftButton')
		wait(); click(F.shrink)
		eq(OW:GetWindowSize(), 'half', 'a click does nothing')
		W.CloseColorPicker()
		eq(atlases_of(F.shrink), sorted(art.shrink.normal, glow), 'enabled again')
		-- The bar's grow arrow.
		wait(); click(F.shrink)
		eq(OW:GetWindowSize(), 'mini', 'it works')
		eq(atlases_of(F.miniGrow), sorted(art.grow.normal, glow), "the bar's grow: Expand")
		check(not F.miniGrow.icon:IsShown(), 'no chevron')
		-- Thick again: the box and the chevrons, no art.
		look('thick')
		for _, button in ipairs({ F.shrink, F.grow, F.miniGrow }) do
			eq(atlases_of(button), '', 'no Blizzard art under Thick')
			check(button.icon:IsShown(), 'the chevron')
			check(button.backdropInfo ~= nil and button.outline:IsShown(), 'the box')
		end
		eq(F.shrink.icon:GetTexture(), st.icons.minimize2, 'shrink wears minimize-2')
		eq(F.grow.icon:GetTexture(), st.icons.maximize2, 'grow wears maximize-2')
		eq(F.miniGrow.icon:GetTexture(), st.icons.maximize2, "the bar's grow wears maximize-2")
		look('blizzard')
		eq(atlases_of(F.miniGrow), sorted(art.grow.normal, glow), 'and back under Blizzard')
		reset()
		look('thick')
		eq(#take_errors(), 0, 'no errors')
	end)

	per_client("a client without the art keeps the chevron on Blizzard's panel button", function(client)
		world(client)
		reset()
		look('blizzard')
		-- Where the theme has no art for the client, and where the client lacks the atlases.
		local data = st.ThemeArt.ART.sizebutton
		local info = C_Texture.GetAtlasInfo
		local cases = {
			['no art in the table'] = function() st.ThemeArt.ART.sizebutton = nil end,
			['the atlases missing'] = function()
				C_Texture.GetAtlasInfo = function(name)
					if name:lower():find('redbutton%-expand') or name:lower():find('redbutton%-condense') then return nil end
					return info(name)
				end
			end,
		}
		for what, remove in pairs(cases) do
			remove()
			st.Config:Open('Loot')
			wait(); OW:SetWindowSize('half')
			local F = frames()
			tick()
			OW:Render()
			for _, button in ipairs({ F.shrink, F.grow }) do
				eq(atlases_of(button), '', what .. ': no expand or condense art')
				check(button.icon:IsShown(), what .. ': the chevron shows')
				check(files_of(button):find('UI%-Panel%-Button'), what .. ": Blizzard's panel button: " .. files_of(button))
				eq(button.backdropInfo, nil, what .. ': the box is off under Blizzard')
			end
			eq(F.shrink.icon:GetTexture(), st.icons.minimize2, what .. ': the Lucide fallback is minimize-2')
			eq(F.grow.icon:GetTexture(), st.icons.maximize2, what .. ': and maximize-2')
			-- Everything else is as with the art.
			W.OpenColorPicker(F.window, { r = 1, g = 0, b = 0, onChange = function() end })
			check(F.shrink.disabled, what .. ': disabled by the picker')
			eq(F.shrink:GetAlpha(), 0.4, what .. ': at the disabled alpha')
			eq(tip_text(F.shrink), 'Shrink to a bar | A small bar, to see the whole UI. It keeps the page. | danger:Close the color picker first.')
			W.CloseColorPicker()
			-- Thick still has its box.
			look('thick')
			check(F.shrink.backdropInfo ~= nil and F.shrink.icon:IsShown(), what .. ': Thick: the box and the chevron')
			look('blizzard')
			reset()
			C_Texture.GetAtlasInfo = info
			st.ThemeArt.ART.sizebutton = data
		end
		-- With the art back, the arrows wear it again.
		st.Config:Open('Loot')
		wait(); OW:SetWindowSize('half')
		local art = st.ThemeArt.Control('sizebutton')
		eq(atlases_of(frames().shrink), sorted(art.shrink.normal, art.highlight), 'the art again')
		reset()
		look('thick')
		eq(#take_errors(), 0, 'no errors')
	end)
end

------------------------------------------------------------------ Esc, combat, a theme change

per_client('Esc and combat close every state, and the window opens again at the size it should, under every look', function(client, clientIndex)
	do
		world(client)
		for lookIndex, name in ipairs(LOOKS) do
			look(name)
			for stateIndex, which in ipairs({ 'W1', 'W2', 'W3', 'W4', 'W5', 'W6' }) do
				local want = STATES[which]
				local reopened = want.size == 'mini' and 'half' or want.size
				local where = client .. ' ' .. name .. ' ' .. which
				-- Esc on one client and combat on the other, by turns: each state under
				-- each look is closed both ways across the two.
				local how = (lookIndex + stateIndex + clientIndex) % 2 == 0 and 'Esc' or 'combat'
				do
					reset()
					st.Config:Open('Loot')
					go(which)
					if how == 'Esc' then
						stub.fire_script(frames().keys, 'OnKeyDown', 'ESCAPE')
					else
						st.Config:PLAYER_REGEN_DISABLED()
					end
					check(not OW:IsShown(), where .. ': ' .. how .. ' closes it')
					if how == 'combat' then
						stub.in_combat = true
						st.Config:Open('Loot')
						check(not OW:IsShown(), where .. ': and /sui refuses to open in combat')
						stub.in_combat = false
					end
					st.Config:Open('Loot')
					eq(OW:GetWindowSize(), reopened, where .. ': opens at ' .. reopened .. ' after ' .. how)
					eq(OW:IsSidebarShown(), want.sidebar, where .. ': with its sidebar')
					local saved = st.config.global.optionsWindow
					if want.size == 'full' then
						eq(saved and saved.size, nil, where .. ': nothing saved for full')
					else
						eq(saved.size, 'half', where .. ': half saved')
					end
					check(frames().main:IsShown() and not frames().mini:IsShown(), where .. ': drawn as ' .. reopened)
				end
			end
		end
	end
	reset()
	look('thick')
	eq(#take_errors(), 0, 'no errors')
end)

-- A theme change is slow (every frame is drawn again), so each client takes half
-- of the states: between them, all six.
local THEME_STATES = { forever = { 'W1', 'W4', 'W5' }, retail = { 'W2', 'W3', 'W6' } }
per_client('a theme change keeps the state: the size, the sidebar, the corner and the page', function(client)
	do
		world(client)
		for _, which in ipairs(THEME_STATES[client]) do
			reset()
			look('thick')
			st.Config:Open('Unitframes', 'player', 'general')
			go(which)
			local F = frames()
			local dx0, dy0 = 0, 0
			if which == 'W5' or which == 'W6' then dx0, dy0 = OW.MiniShift(OW.S.layout) end
			local corner = { F.window:GetRight() - dx0, F.window:GetTop() - dy0 }
			local state = OW:GetState()
			for _, name in ipairs({ 'blizzard', 'thick' }) do
				look(name)
				local where = client .. ' ' .. which .. ' -> ' .. name
				eq(now(), which, where .. ': the state')
				local dx, dy = 0, 0
				if which == 'W5' or which == 'W6' then dx, dy = OW.MiniShift(OW.S.layout) end
				eq(F.window:GetRight() .. ',' .. F.window:GetTop(), (corner[1] + dx) .. ',' .. (corner[2] + dy), where .. ': the corner (the bar sits where the metal\'s corner is under Blizzard)')
				eq(OW:GetState().page .. OW:GetState().pick .. OW:GetState().tab, state.page .. state.pick .. state.tab, where .. ': the page')
				local off = P.off(F.window)
				eq(#off, 0, where .. ': ' .. P.report(off))
			end
		end
	end
	reset()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ a save from before this work, or by hand

per_client('an older save, bad values or a saved bar open the window as they should, and nothing is written until a click', function(client)
	world(client)
	local cases = {
		{ saved = { point = 'CENTER', x = -200, y = 50, height = 760 }, size = 'full', sidebar = true, name = 'an older save' },
		{ saved = { size = 'mini' }, size = 'half', sidebar = true, name = 'a saved bar' },
		{ saved = { size = 'huge' }, size = 'full', sidebar = true, name = 'size huge' },
		{ saved = { size = 7 }, size = 'full', sidebar = true, name = 'size 7' },
		{ saved = { sidebar = 0 }, size = 'full', sidebar = true, name = 'sidebar 0' },
		{ saved = { sidebar = 'no' }, size = 'full', sidebar = true, name = 'sidebar no' },
		{ saved = { point = 'NOWHERE', x = 'a' }, size = 'full', sidebar = true, name = 'a point that is no point' },
		{ saved = { size = 'half', sidebar = false }, size = 'half', sidebar = false, name = 'a saved half, collapsed' },
	}
	for _, look_name in ipairs({ 'thick', 'blizzard' }) do
		look(look_name)
		for _, case in ipairs(cases) do
			reset()
			local saved = {}
			for k, v in pairs(case.saved) do saved[k] = v end
			st.config.global.optionsWindow = saved
			st.Config:Open('Loot')
			local where = look_name .. ' ' .. case.name
			eq(OW:GetWindowSize(), case.size, where .. ': size')
			eq(OW:IsSidebarShown(), case.sidebar, where .. ': sidebar')
			local after = st.config.global.optionsWindow
			eq(after.size, case.saved.size, where .. ': no size written')
			eq(after.sidebar, case.saved.sidebar, where .. ': no sidebar written')
			local off = P.off(frames().window)
			eq(#off, 0, where .. ': ' .. P.report(off))
		end
	end
	reset()
	look('thick')
	eq(#take_errors(), 0, 'no errors')
end)

for _, client in ipairs(CLIENTS) do
	for _, case in ipairs(CASES) do
		test(case.name .. ', ' .. client, function() case.fn(client, client == 'forever' and 1 or 2) end)
	end
end
