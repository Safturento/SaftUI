-- The Blizzard theme's one box (SaftUI-Core/themeart.lua and themeart_data.lua,
-- through theme.lua's draw calls; the design is
-- docs/superpowers/specs/2026-11-17-saftui-blizzard-theme-one-border-design.md):
--   - panel, bar, tooltip and unitframe drawn in the box: on Forever cut from
--     the minimap header button (ui-hud-minimap-header-button, Camelot's
--     member in file 8026705) into 6px corners and stretched edges with no
--     centre, on retail the ui-hud-minimap-button kit;
--   - the box's pieces on a frame of SaftUI's (ThemeArt.BoxFrame), a child of
--     the drawn frame, 4 outside the frame it borders and one level above it
--     and its children (ThemeArt.LevelAbove), or on the frame's own bounds
--     for a frame drawn on itself, or around another frame (over);
--   - Thick, Thin and None hiding the box and Blizzard showing it again, a
--     secret frame level, the box hiding with its frame;
--   - nothing moving: the kinds' insets and st:CalculateSpacing as before.
--
-- Real: theme.lua and themeart.lua, with Core's helpers (load_core_helpers)
-- and the profile's defaults. Each case starts from a fresh world on a client
-- (T.client), with SaftUI's theme Blizzard, on both clients unless it names one.
local T = load_test_file('lib/theme_helpers.lua')

local CLIENTS = { 'forever', 'retail' }
local BOX_KINDS = { 'panel', 'bar', 'tooltip', 'unitframe' }

-- A fresh world on client, with SaftUI's theme Blizzard.
local function blizzard(client)
	local st = T.client(client or 'forever')
	st.config.profile.theme.name = 'blizzard'
	return st
end

local function frame(st, parent)
	local f = st:CreateFrame('Frame', nil, parent or UIParent)
	f:SetSize(100, 50)
	f:SetPoint('CENTER')
	return f
end

-- A texture's coordinates in its file, 'left,right,top,bottom', to 6 places.
local function coords(texture)
	local left, top, _, bottom, right = texture:GetTexCoord()
	return ('%.6f,%.6f,%.6f,%.6f'):format(left, right, top, bottom)
end

-- A rectangle of a w by h file, in its pixels, as coords gives it.
local function px(l, r, t, b, w, h)
	return ('%.6f,%.6f,%.6f,%.6f'):format(l / w, r / w, t / h, b / h)
end

-- A region's size as 'WxH', in whole pixels.
local function size_of(region)
	local w, h = region:GetSize()
	return ('%dx%d'):format(math.floor(w + 0.5), math.floor(h + 0.5))
end

local KEYS = {
	'BottomEdge', 'BottomLeftCorner', 'BottomRightCorner', 'LeftEdge',
	'RightEdge', 'TopEdge', 'TopLeftCorner', 'TopRightCorner',
}

-- The box's eight pieces as T.art lists them on this client: on Forever each
-- cut from the header button's file, on retail the kit's atlases.
local function box(client)
	local out = {}
	for i, key in ipairs(KEYS) do
		local name
		if client == 'forever' then
			name = '8026705'
		elseif key:find('Corner$') then
			name = 'ui-hud-minimap-button-NineSlice-Corner' .. key:gsub('Corner$', '')
		elseif key == 'TopEdge' or key == 'BottomEdge' then
			name = '_ui-hud-minimap-button-NineSlice-Edge' .. key:gsub('Edge$', '')
		else
			name = '!ui-hud-minimap-button-NineSlice-Edge' .. key:gsub('Edge$', '')
		end
		out[i] = key .. '=' .. name
	end
	return table.concat(out, ',')
end

test('panel, bar and tooltip draw the box, 4 outside the frame, on a frame above it', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		for _, kind in ipairs({ 'panel', 'bar', 'tooltip' }) do
			local where = client .. ' ' .. kind
			local f = frame(st)
			st:SetBackdrop(f, 'theme', 'theme', kind)
			eq(T.art(f.backdrop), box(client), where .. ': the eight pieces')
			local holder = st.ThemeArt.BoxFrame(f.backdrop)
			eq(T.around(holder, f), '-4,4,4,-4', where .. ': the box 4 outside the frame')
			check(holder:GetFrameLevel() > f:GetFrameLevel(), where .. ': its frame above the frame')
			eq(holder:GetParent(), f.backdrop, where .. ': a child of the drawn frame')
			for key, p in pairs(st.ThemeArt.Get(f.backdrop).pieces) do
				eq(p:GetParent(), holder, where .. ': ' .. key .. ' is on the box frame')
			end
			check(holder:IsShown(), where .. ': shown')
			eq(T.inset(f.backdrop), 3, where .. ': the fill at the inset it had')
		end
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('unitframe draws the box too, its inset unchanged', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'unitframe')
		eq(T.art(f.backdrop), box(client), client .. ': the eight pieces')
		eq(T.around(st.ThemeArt.BoxFrame(f.backdrop), f), '-4,4,4,-4', client .. ': 4 outside the frame')
		eq(T.inset(f.backdrop), 2, client .. ': the fill at the inset 2')
	end
end)

test("the box is above the frame's children", function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		local bar = CreateFrame('StatusBar', nil, f)
		bar:SetFrameLevel(f:GetFrameLevel() + 3)
		st:SetBackdrop(f, 'theme', 'theme', 'bar')
		eq(st.ThemeArt.BoxFrame(f.backdrop):GetFrameLevel(), bar:GetFrameLevel() + 1, client .. ': one over the highest child')
		-- A redraw doesn't climb: the box frame isn't counted among the children.
		st:RedrawThemed()
		st:RedrawThemed()
		eq(st.ThemeArt.BoxFrame(f.backdrop):GetFrameLevel(), bar:GetFrameLevel() + 1, client .. ': the same after redraws')
		eq(st.ThemeArt.LevelAbove(f), bar:GetFrameLevel() + 1, client .. ': LevelAbove')
	end
end)

test('Forever cuts the box from the header button', function()
	local st = blizzard('forever')
	local f = frame(st)
	st:SetBackdrop(f, 'theme', 'theme', 'panel')
	local pieces = st.ThemeArt.Get(f.backdrop).pieces
	eq(pieces.TopLeftCorner:GetTexture(), 8026705, "the header button's file")
	eq(coords(pieces.TopLeftCorner), px(256, 262, 256, 262, 512, 512), 'the top left corner')
	eq(coords(pieces.TopEdge), px(262, 402, 256, 262, 512, 512), 'the top edge')
	-- Every piece, in file pixels: the member's left and top (256, 256) plus
	-- the piece's rectangle in the 152 by 23 atlas.
	local want = {
		TopLeftCorner = { 0, 6, 0, 6 }, TopRightCorner = { 146, 152, 0, 6 },
		BottomLeftCorner = { 0, 6, 17, 23 }, BottomRightCorner = { 146, 152, 17, 23 },
		TopEdge = { 6, 146, 0, 6 }, BottomEdge = { 6, 146, 17, 23 },
		LeftEdge = { 0, 6, 6, 17 }, RightEdge = { 146, 152, 6, 17 },
	}
	for key, r in pairs(want) do
		eq(coords(pieces[key]), px(256 + r[1], 256 + r[2], 256 + r[3], 256 + r[4], 512, 512), key .. "'s rectangle")
		check(not pieces[key]:GetHorizTile() and not pieces[key]:GetVertTile(), key .. ' is stretched, not tiled')
	end
	for _, key in ipairs({ 'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner' }) do
		eq(size_of(pieces[key]), '6x6', key .. ' is 6 by 6')
	end
	-- The box frame is the 100 by 50 frame and 4 outside it: 108 by 58.
	local holder = st.ThemeArt.BoxFrame(f.backdrop)
	eq(T.around(pieces.TopLeftCorner, holder), '0,0,-102,52', "the top left corner at the box frame's")
	eq(T.around(pieces.TopEdge, holder), '6,0,-6,52', 'the top edge between the corners, 6 thick')
	eq(T.around(pieces.LeftEdge, holder), '0,-6,-102,6', 'the left edge, 6 thick')
	check(pieces.Center == nil or not pieces.Center:IsShown(), 'no centre')
end)

test('retail draws the minimap button kit', function()
	local st = blizzard('retail')
	local f = frame(st)
	st:SetBackdrop(f, 'theme', 'theme', 'tooltip')
	eq(T.art(f.backdrop), box('retail'), "the kit's eight pieces, no Center")
	local pieces = st.ThemeArt.Get(f.backdrop).pieces
	eq(T.around(pieces.TopLeftCorner, st.ThemeArt.BoxFrame(f.backdrop)):match('^%-?%d+,%-?%d+'), '0,0',
		"the top left corner at the box frame's")
end)

test('LayBox lays the box on a frame in the caller\'s own table, with its centre when asked', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		local pieces = {}
		st.ThemeArt.LayBox(pieces, f, false)
		local shown = {}
		for key, p in pairs(pieces) do if p:IsShown() then shown[#shown + 1] = key end end
		table.sort(shown)
		eq(table.concat(shown, ','), table.concat(KEYS, ','), client .. ': the eight pieces, no centre')
		eq(T.around(pieces.TopLeftCorner, f):match('^%-?%d+,%-?%d+'), '0,0', client .. ": on the frame's own bounds")
		eq(pieces.TopLeftCorner:GetParent(), f, client .. ': textures of the frame')
		eq(st.ThemeArt.Get(f), nil, client .. ": kept in the caller's table")
		st.ThemeArt.LayBox(pieces, f, true)
		check(pieces.Center and pieces.Center:IsShown(), client .. ': the centre when asked')
		if client == 'forever' then
			eq(coords(pieces.Center), px(262, 402, 262, 273, 512, 512), client .. ": the header button's centre")
		end
		st.ThemeArt.LayBox(pieces, f, false)
		check(not pieces.Center:IsShown(), client .. ': and not again when not')
	end
end)

test('a frame drawn on itself keeps the box inside', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetTemplate(f, 'theme', 'theme', 'panel')
		local holder = st.ThemeArt.BoxFrame(f)
		eq(T.around(holder, f), '0,0,0,0', client .. ": on the frame's own bounds")
		check(holder:GetFrameLevel() > f:GetFrameLevel(), client .. ': above the frame')
		eq(T.art(f), box(client), client .. ': the eight pieces')
		local level = holder:GetFrameLevel()
		st:RedrawThemed()
		eq(holder:GetFrameLevel(), level, client .. ': a redraw keeps its level')
		eq(T.around(holder, f), '0,0,0,0', client .. ': and its place')
	end
end)

test("over places a self-drawn backdrop's box outside another frame", function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local owner = frame(st)
		local b = st:CreateFrame('Frame', nil, owner)
		b:SetAllPoints(owner)
		st:SetTemplate(b, 'theme', 'theme', 'panel', nil, owner)
		local holder = st.ThemeArt.BoxFrame(b)
		eq(T.around(holder, owner), '-4,4,4,-4', client .. ': 4 outside the other frame')
		check(holder:GetFrameLevel() > owner:GetFrameLevel(), client .. ': above it')
		st:RedrawThemed()
		eq(T.around(holder, owner), '-4,4,4,-4', client .. ': a redraw keeps it there')
	end
end)

test('switching to Thick, Thin or None hides the box', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'panel')
		local holder = st.ThemeArt.BoxFrame(f.backdrop)
		for _, name in ipairs({ 'thick', 'thin' }) do
			st.config.profile.theme.name = name
			st:RedrawThemed()
			eq(holder:IsShown(), false, client .. ' ' .. name .. ': the box frame is hidden')
			eq(T.art(f.backdrop), '', client .. ' ' .. name .. ': no art')
			st.config.profile.theme.name = 'blizzard'
			st:RedrawThemed()
			eq(holder:IsShown(), true, client .. ' ' .. name .. ', back to Blizzard: shown')
			eq(T.art(f.backdrop), box(client), client .. ' ' .. name .. ', back to Blizzard: the eight pieces')
		end
		st:SetBackdrop(f, 'none')
		eq(holder:IsShown(), false, client .. ' None: the box frame is hidden')
		eq(T.art(f.backdrop), '', client .. ' None: no art')
		st:SetBackdrop(f, 'theme', 'theme', 'panel')
		eq(holder:IsShown(), true, client .. ' back to Blizzard: shown')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('a frame with a secret level gets its box with no level math', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local secret = newproxy(false)
		local real = issecretvalue
		issecretvalue = function(v) return v == secret or real(v) end

		local owner = CreateFrame('Frame', nil, UIParent)
		owner:SetSize(100, 50)
		owner:SetPoint('CENTER')
		owner:SetFrameLevel(6)
		local child = CreateFrame('Frame', nil, owner)
		child.GetFrameLevel = function() return secret end
		owner.GetFrameLevel = function() return secret end
		local backdrops = setmetatable({}, { __mode = 'k' })
		local ok, err = pcall(st.SetBackdropIn, st, backdrops, owner, 'theme', 'theme', 'bar')
		check(ok, client .. ': drawn: ' .. tostring(err))
		local b = backdrops[owner]
		if check(b ~= nil, client .. ': a backdrop') then
			local holder = st.ThemeArt.BoxFrame(b)
			check(holder:IsShown(), client .. ': the box is shown')
			eq(T.around(holder, owner), '-4,4,4,-4', client .. ': and placed')
			eq(T.art(b), box(client), client .. ': its pieces')
		end
		eq(st.ThemeArt.LevelAbove(owner), nil, client .. ': LevelAbove of a secret level is nil')

		-- A child's secret level is left out.
		local f = frame(st)
		local secretChild = CreateFrame('Frame', nil, f)
		secretChild.GetFrameLevel = function() return secret end
		eq(st.ThemeArt.LevelAbove(f), f:GetFrameLevel() + 1, client .. ": a child's secret level is left out")

		issecretvalue = real
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('the box hides and shows with its frame', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'panel')
		local holder = st.ThemeArt.BoxFrame(f.backdrop)
		f:Hide()
		eq(holder:IsVisible(), false, client .. ': hidden with its frame')
		f:Show()
		eq(holder:IsVisible(), true, client .. ': shown with it')
	end
end)

test('nothing moves: the insets and CalculateSpacing are what they were', function()
	local INSETS = { panel = 3, bar = 3, tooltip = 3, unitframe = 2 }
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		for _, kind in ipairs(BOX_KINDS) do
			local where = client .. ' ' .. kind
			eq(st:ThemeInset('blizzard', 'theme', kind), INSETS[kind], where .. ': ThemeInset')
			eq(st.ThemeArt.Inset(kind), INSETS[kind], where .. ': ThemeArt.Inset')
			eq(st.ThemeArt.Reach(kind), 4, where .. ': the art reaches 4 out')
			local f = frame(st)
			st:SetBackdrop(f, 'theme', 'theme', kind)
			eq(st:CalculateSpacing(f), INSETS[kind], where .. ': CalculateSpacing')
			eq(st:DrawnInset(f), INSETS[kind], where .. ': DrawnInset')
			eq(T.around(f.backdrop, f), ('-%d,%d,%d,-%d'):format(INSETS[kind], INSETS[kind], INSETS[kind], INSETS[kind]),
				where .. ': the backdrop where it was')
			local t = frame(st)
			st:SetBackdrop(t, 'theme', 'theme', 'tooltip')
			eq(st:CalculateSpacing(f, t, 4), 4 + INSETS[kind] + 3, where .. ': with an anchor')
		end
	end
end)

-- A piece's vertex colour as 'r,g,b,a', to 2 places.
local function vertex(piece)
	local r, g, b, a = piece:GetVertexColor()
	return ('%.2f,%.2f,%.2f,%.2f'):format(r, g, b, a)
end

-- Every piece of f's box: its key, desaturated, vertex colour.
local function each_piece(st, f, fn)
	local n = 0
	for key, p in pairs(st.ThemeArt.Get(f.backdrop).pieces) do
		fn(key, p)
		n = n + 1
	end
	eq(n, 8, 'eight pieces')
end

test('an own colour shows on a desaturated box', function()
	for _, client in ipairs(CLIENTS) do
		for _, kind in ipairs(BOX_KINDS) do
			local st = blizzard(client)
			local f = frame(st)
			st:SetBackdrop(f, 'theme', 'theme', kind)
			st:SetBorderColor(f.backdrop, 0.64, 0.21, 0.93)
			each_piece(st, f, function(key, p)
				local where = client .. ' ' .. kind .. ' ' .. key
				eq(p:IsDesaturated(), true, where .. ': desaturated')
				eq(vertex(p), '0.64,0.21,0.93,1.00', where .. ': the colour')
			end)
		end
	end
end)

test('clearing the own colour gives plain bronze back', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'panel')
		st:SetBorderColor(f.backdrop, 0.64, 0.21, 0.93)
		st:SetBorderColor(f.backdrop)
		each_piece(st, f, function(key, p)
			eq(p:IsDesaturated(), false, client .. ' ' .. key .. ': not desaturated')
			eq(vertex(p), '1.00,1.00,1.00,1.00', client .. ' ' .. key .. ': white')
		end)
	end
end)

test('a recolour pass leaves the box plain', function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'panel')
		st:SetBorderColor(f.backdrop, 0.64, 0.21, 0.93)
		st:RecolorThemed()
		each_piece(st, f, function(key, p)
			eq(p:IsDesaturated(), false, client .. ' ' .. key .. ': not desaturated')
			eq(vertex(p), '1.00,1.00,1.00,1.00', client .. ' ' .. key .. ': white')
		end)
	end
end)

test("the swing timer, the XP and reputation bars and the tooltip's status bar wear the box outside", function()
	for _, client in ipairs(CLIENTS) do
		local st = blizzard(client)
		-- SetBackdrop's owners: the XP and reputation bars, the tooltip's status bar
		local owner = frame(st)
		st:SetBackdrop(owner, 'theme', 'theme', 'bar')
		eq(T.around(st.ThemeArt.BoxFrame(owner.backdrop), owner), '-4,4,4,-4', client .. ': SetBackdrop bar')
		-- SetBackdropIn's: the swing timer's, drawn in its module's own table
		local backdrops, bar = {}, frame(st)
		local made = st:SetBackdropIn(backdrops, bar, 'theme', 'theme', 'bar')
		eq(T.around(st.ThemeArt.BoxFrame(made), bar), '-4,4,4,-4', client .. ': SetBackdropIn bar')
		check(st.ThemeArt.BoxFrame(made):GetFrameLevel() > bar:GetFrameLevel(), client .. ': above the bar')
	end
end)
