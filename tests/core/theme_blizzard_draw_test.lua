-- The Blizzard theme drawn (SaftUI-Core/themeart.lua, through theme.lua's
-- draw calls):
--   - each kind's look under Blizzard: the tooltip border on tooltips, bars
--     and panels, the metal on windows (at each client's corner offsets, with
--     its title bar above the window), the action and item buttons' rings over
--     the icon's edge with their slot art behind it, a bare aura, small as one
--     line in Border, and header and control clear;
--   - the fill in the theme's Background (Window background for a window) at
--     the Opacity, no edge line and no Thick lines;
--   - switches between Thick, Blizzard and Thin, a recolor under Blizzard, and
--     None clearing the art;
--   - a frame's own border color (st:SetBorderColor): the border and line under
--     Thick and Thin, the tinted border art, the equipped and quality borders
--     and a small frame's line under Blizzard, and a control left alone;
--   - st:DrawnInset, st:DrawnKind and st:CalculateSpacing following the inset
--     each frame was drawn at;
--   - a frame first drawn in combat, nothing written onto a frame that isn't
--     SaftUI's, a ring's holder placed with no math on a secret frame level,
--     and no SaftUI Lua file the game loads naming NineSliceUtil.
--
-- Real: theme.lua and themeart.lua, with Core's helpers (load_core_helpers)
-- and the profile's defaults; every SaftUI Lua file's source, for the scan. Each case starts from a fresh world on a client
-- (T.client), on Forever unless it names retail, with SaftUI's theme Blizzard.
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('misc/fixtures/locked_widget.lua')
local text, fill, edge, inset, offset = T.text, T.fill, T.edge, T.inset, T.offset

-- A fresh world on client, with SaftUI's theme Blizzard.
local function blizzard(client)
	local st = T.client(client or 'forever')
	st.config.profile.theme.name = 'blizzard'
	return st
end

local function frame(st)
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(100, 50)
	f:SetPoint('CENTER')
	return f
end

-- Whether Thick's outer lines (the dark ones either side of the border) show.
local function outerShown(f)
	if not f.altborder then return false end
	for _, line in pairs(f.altborder) do
		if not line:IsShown() then return false end
	end
	return true
end

-- A drawn frame with no backdrop, no outer lines and no art: what None draws.
local function bare(f)
	return f.backdropInfo == nil and not outerShown(f) and T.art(f) == '' and T.over(f) == ''
end

-- One piece of a drawn frame's art: on the frame (pieces) or over the icon's
-- edge (over).
local function piece(st, f, key, set)
	local art = st.ThemeArt.Get(f)
	return art and art[set or 'pieces'][key]
end

-- One of a region's anchors as text: 'POINT relative RELPOINT x,y', where
-- relative names what it's anchored to among names (a table of region -> name).
local function anchor(region, point, names)
	for i = 1, region:GetNumPoints() do
		local p, rel, rp, x, y = region:GetPoint(i)
		if p == point then return ('%s %s %s %s'):format(p, names[rel] or tostring(rel), rp, text(x, y)) end
	end
end

-- Every anchor of a region, as text, in a fixed order.
local function anchors(region)
	local out = {}
	for i = 1, region:GetNumPoints() do
		local p, rel, rp, x, y = region:GetPoint(i)
		out[#out + 1] = table.concat({ p, tostring(rel), rp, text(x, y) }, ' ')
	end
	table.sort(out)
	return table.concat(out, '; ')
end

-- Every piece of a drawn frame's art, on it and over the icon's edge.
local function eachPiece(st, f, fn)
	local art = st.ThemeArt.Get(f)
	if not art then return end
	for _, set in ipairs({ 'pieces', 'over' }) do
		for key, region in pairs(art[set]) do fn(key, region) end
	end
end

-- A nine-slice border's shown pieces as T.art lists them: corners
-- '<prefix>-Corner<Where>', edges '_<prefix>-Edge<Top/Bottom>' and
-- '!<prefix>-Edge<Left/Right>'.
local function nine(prefix)
	return table.concat({
		'BottomEdge=_' .. prefix .. '-EdgeBottom',
		'BottomLeftCorner=' .. prefix .. '-CornerBottomLeft',
		'BottomRightCorner=' .. prefix .. '-CornerBottomRight',
		'LeftEdge=!' .. prefix .. '-EdgeLeft',
		'RightEdge=!' .. prefix .. '-EdgeRight',
		'TopEdge=_' .. prefix .. '-EdgeTop',
		'TopLeftCorner=' .. prefix .. '-CornerTopLeft',
		'TopRightCorner=' .. prefix .. '-CornerTopRight',
	}, ',')
end
local TOOLTIP, METAL = nine('Tooltip-NineSlice'), nine('UI-Frame-Metal')

-- A button of SaftUI's laid out as Blizzard's templates lay one out (the same
-- on both clients): its icon (the action button's in BACKGROUND, the item
-- button's in BORDER), a font string (the action button's name in OVERLAY,
-- the item button's count in ARTWORK at 0), and a cooldown, a child frame at
-- the button's own level (the templates' useParentLevel).
local function button(st, iconLayer, textLayer)
	local b = st:CreateFrame('CheckButton', nil, UIParent)
	b:SetSize(36, 36)
	b:SetPoint('CENTER')
	b.icon = b:CreateTexture(nil, iconLayer)
	b.text = b:CreateFontString(nil, textLayer)
	-- Kept in no field: st:SkinActionButton would skin a field named cooldown
	-- as Blizzard's Cooldown, which the stubs don't have.
	local cooldown = CreateFrame('Frame', nil, b)
	cooldown:SetFrameLevel(b:GetFrameLevel())
	return b
end

-- Where a region draws among its frame's regions: its layer, then its sublevel.
local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
local function depth(region)
	local layer, sublevel = region:GetDrawLayer()
	return LAYERS[layer] * 100 + (sublevel or 0)
end

-- Checks that a button of SaftUI's drawn as kind has its ring over its icon's
-- edge and under its texts, cooldown and glows: a texture of the button's own,
-- above the icon and below the font string, and no frame of the art's over the
-- button, where it would sit at or above the cooldown.
local function checkRingOnButton(st, owner, label)
	local b = owner.backdrop
	local ring = piece(st, b, 'Ring', 'over')
	eq(ring and ring:GetParent(), owner, label .. ": the ring is a texture of the button's own")
	if not ring then return end
	check(depth(ring) > depth(owner.icon), label .. ': above the icon')
	check(depth(ring) < depth(owner.text), label .. ': below its font strings')
	eq(b:GetNumChildren(), 0, label .. ": no frame of the art's sits at or above the cooldown's level")
	eq(T.around(ring, b), '0,0,0,0', label .. ': the ring covers the drawn frame')
end

local ACTION_ART = 'SlotArt=UI-HUD-ActionBar-IconFrame-Slot,SlotBackground=UI-HUD-ActionBar-IconFrame-Background'
local ACTION_RING = 'Ring=UI-HUD-ActionBar-IconFrame'
local SLOT_ART = 'SlotArt=bags-item-slot64'
local SLOT_RING = [[Ring=Interface\Buttons\UI-Quickslot2]]

test('a tooltip: the eight tooltip pieces, edges tiled, no line, the Background at the Opacity', function()
	local st = blizzard()
	local f = frame(st)
	-- Drawn Thick first, so it has Thick's lines for Blizzard to hide.
	st:SetBackdrop(f, 'thick', 'theme', 'tooltip')
	local b = f.backdrop
	check(outerShown(b), "drawn Thick: Thick's lines show")
	st:SetBackdrop(f, 'theme', 'theme', 'tooltip')

	eq(T.art(b), TOOLTIP, 'the eight tooltip pieces')
	eq(T.over(b), '', 'nothing over an icon')
	local names = { [b] = 'frame' }
	for _, key in ipairs({ 'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner' }) do
		names[piece(st, b, key)] = key
	end
	local corners = {
		TopLeftCorner = 'TOPLEFT', TopRightCorner = 'TOPRIGHT',
		BottomLeftCorner = 'BOTTOMLEFT', BottomRightCorner = 'BOTTOMRIGHT',
	}
	for key, point in pairs(corners) do
		local p = piece(st, b, key)
		eq(anchor(p, point, names), point .. ' frame ' .. point .. ' 0.00,0.00', key .. " at the drawn frame's corner")
		check(not p:GetHorizTile() and not p:GetVertTile(), key .. ' does not tile')
	end
	-- Each edge runs between its corners, as Blizzard's nine-slice code lays it.
	local top, left = piece(st, b, 'TopEdge'), piece(st, b, 'LeftEdge')
	eq(anchor(top, 'TOPLEFT', names), 'TOPLEFT TopLeftCorner TOPRIGHT 0.00,0.00', 'the top edge starts at the top left corner')
	eq(anchor(top, 'TOPRIGHT', names), 'TOPRIGHT TopRightCorner TOPLEFT 0.00,0.00', 'and ends at the top right corner')
	eq(anchor(piece(st, b, 'BottomEdge'), 'BOTTOMRIGHT', names), 'BOTTOMRIGHT BottomRightCorner BOTTOMLEFT 0.00,0.00', 'the bottom edge')
	eq(anchor(left, 'BOTTOMLEFT', names), 'BOTTOMLEFT BottomLeftCorner TOPLEFT 0.00,0.00', 'the left edge')
	eq(anchor(piece(st, b, 'RightEdge'), 'TOPRIGHT', names), 'TOPRIGHT TopRightCorner BOTTOMRIGHT 0.00,0.00', 'the right edge')
	check(top:GetHorizTile() and not top:GetVertTile(), 'TopEdge tiles across')
	check(piece(st, b, 'BottomEdge'):GetHorizTile(), 'BottomEdge tiles across')
	check(left:GetVertTile() and not left:GetHorizTile(), 'LeftEdge tiles down')
	check(piece(st, b, 'RightEdge'):GetVertTile(), 'RightEdge tiles down')
	eachPiece(st, b, function(key, p)
		eq(p:GetParent(), b, key .. ' is on the drawn frame')
		eq((p:GetDrawLayer()), 'BORDER', key .. " in the tooltip border's layer")
		eq(text(p:GetVertexColor()), '1.00,1.00,1.00,1.00', key .. ' untinted')
	end)

	eq(fill(b), '0.09,0.09,0.19,0.90', "the Background at the profile's Opacity")
	eq(inset(b), 3, "the fill sits the tooltip's inset in")
	eq(b.backdropInfo and b.backdropInfo.edgeFile, nil, 'no edge line')
	check(not outerShown(b), "Thick's lines are hidden")
end)

test('bars and panels wear the tooltip border, a window the metal', function()
	local st = blizzard()
	local drawn = {}
	for _, kind in ipairs({ 'bar', 'panel', 'window' }) do
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', kind)
		drawn[kind] = f.backdrop
	end
	eq(T.art(drawn.bar), TOOLTIP, 'a bar: the tooltip border')
	eq(T.art(drawn.panel), TOOLTIP, 'a panel: the tooltip border')
	eq(T.art(drawn.window), METAL, 'a window: the metal')
	eachPiece(st, drawn.window, function(key, p)
		eq((p:GetDrawLayer()), 'OVERLAY', key .. ": the metal's layer")
		eq(p:IsSnappingToPixelGrid(), false, key .. ': no pixel snapping')
		eq(stub.state(p).texel_snapping_bias, 0, key .. ': no texel snapping bias')
	end)

	eq(fill(drawn.window), '0.12,0.12,0.13,0.90', "a window's fill: the Window background")
	eq(fill(drawn.panel), '0.09,0.09,0.19,0.90', "a panel's: the Background")
	eq(fill(drawn.bar), '0.09,0.09,0.19,0.90', "a bar's: the Background")

	-- Dark grey everywhere is one value.
	st.config.profile.templates.blizzard.backdropcolor = { 0.12, 0.12, 0.13, 1 }
	st:RecolorThemed()
	eq(fill(drawn.window), '0.12,0.12,0.13,0.90', 'the window stays grey')
	eq(fill(drawn.panel), '0.12,0.12,0.13,0.90', 'the panel turns grey')
end)

test("a frame drawn as a window, then as a tooltip: the metal's snapping doesn't stay", function()
	local st = blizzard()
	local f = frame(st)
	st:SetBackdrop(f, 'theme', 'theme', 'window')
	st:SetBackdrop(f, 'theme', 'theme', 'tooltip')
	eq(T.art(f.backdrop), TOOLTIP, 'the tooltip border, on the same pieces')
	eachPiece(st, f.backdrop, function(key, p)
		eq(p:IsSnappingToPixelGrid(), true, key .. ': pixel snapping is back on')
		eq((p:GetDrawLayer()), 'BORDER', key .. ": in the tooltip border's layer")
	end)
end)

test("the metal's corners sit at each client's offsets", function()
	local want = {
		retail = { TopLeftCorner = '-8.00,16.00', TopRightCorner = '4.00,16.00', BottomLeftCorner = '-8.00,-3.00', BottomRightCorner = '4.00,-3.00' },
		forever = { TopLeftCorner = '-8.00,16.00', TopRightCorner = '2.00,16.00', BottomLeftCorner = '-8.00,-8.00', BottomRightCorner = '2.00,-8.00' },
	}
	local points = {
		TopLeftCorner = 'TOPLEFT', TopRightCorner = 'TOPRIGHT',
		BottomLeftCorner = 'BOTTOMLEFT', BottomRightCorner = 'BOTTOMRIGHT',
	}
	for _, client in ipairs({ 'retail', 'forever' }) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'window')
		local b = f.backdrop
		for key, point in pairs(points) do
			local p = piece(st, b, key)
			eq(p and offset(p, point), want[client][key], client .. ': ' .. key)
			eq(p and anchor(p, point, { [b] = 'frame' }):match('^%S+ %S+ %S+'), point .. ' frame ' .. point,
				client .. ': ' .. key .. " from the drawn frame's own corner")
		end
	end
end)

test("an action button: the ring over the icon's edge, the slot art behind", function()
	local st = blizzard()
	local f = button(st, 'BACKGROUND', 'OVERLAY')
	st:SetBackdrop(f, 'theme', 'theme', 'action')
	local b = f.backdrop

	eq(T.over(b), ACTION_RING, "Blizzard's ring over the icon's edge")
	eq(T.art(b), ACTION_ART, 'the slot art behind the icon')
	checkRingOnButton(st, f, 'an action button')
	for _, key in ipairs({ 'SlotBackground', 'SlotArt' }) do
		local p = piece(st, b, key)
		eq(p:GetParent(), b, key .. ' is on the drawn frame, behind the button')
		eq(T.around(p, b), '0,0,0,0', key .. ' fills the drawn frame')
		eq(text(p:GetAlpha()), '0.90', key .. " takes the look's alpha")
	end
	local _, below = piece(st, b, 'SlotBackground'):GetDrawLayer()
	local _, above = piece(st, b, 'SlotArt'):GetDrawLayer()
	check(above > below, 'the slot art is over its background')
	eq(fill(b), '0.00,0.00,0.00,0.00', 'the fill is clear')
	eq(b.backdropInfo and b.backdropInfo.edgeFile, nil, 'no edge line')
end)

test('a slot: the item ring and the empty slot\'s art', function()
	local st = blizzard()
	local f = button(st, 'BORDER', 'ARTWORK')
	st:SetBackdrop(f, 'theme', 'theme', 'slot')
	local b = f.backdrop

	eq(T.over(b), SLOT_RING, "the item button's ring over the icon's edge")
	eq(T.art(b), SLOT_ART, "the empty slot's art behind it")
	checkRingOnButton(st, f, 'a slot')
	local ring = piece(st, b, 'Ring', 'over')
	-- Blizzard draws the 64px ring on a 37px button, centred 1px low: the
	-- button's part of it is cut out, so it fits a slot of any size.
	local function exact(...)
		local out = {}
		for i = 1, select('#', ...) do out[i] = ('%.4f'):format((select(i, ...))) end
		return table.concat(out, ',')
	end
	local l, r, t, bottom = 13.5 / 64, 50.5 / 64, 12.5 / 64, 49.5 / 64
	eq(exact(ring:GetTexCoord()), exact(l, t, l, bottom, r, t, r, bottom), "cut to the 37 of 64 the button covers")
	eq(text(piece(st, b, 'SlotArt'):GetAlpha()), '0.90', "the slot art takes the look's alpha")
	eq(fill(b), '0.00,0.00,0.00,0.00', 'the fill is clear')
end)

test("a ring for a frame that isn't SaftUI's, or a texture, is on a frame of SaftUI's over the drawn frame", function()
	local st = blizzard()
	-- Blizzard's button, drawn behind with st:SetBackdropIn: nothing of
	-- SaftUI's goes on it, so the ring is on a frame of SaftUI's, a child of the
	-- backdrop one level above the button.
	local backdrops = setmetatable({}, { __mode = 'k' })
	for _, kind in ipairs({ 'action', 'slot' }) do
		local owner = CreateFrame('CheckButton', nil, UIParent)
		owner:SetSize(36, 36)
		owner:SetPoint('CENTER')
		locked(owner, 'Blizzard')
		local b = st:SetBackdropIn(backdrops, owner, 'theme', 'theme', kind)
		local ring = piece(st, b, 'Ring', 'over')
		local holder = ring and ring:GetParent()
		check(holder ~= nil and holder ~= owner, kind .. ": the ring isn't on Blizzard's button")
		eq(holder and holder:GetParent(), b, kind .. ': it is on a child of the backdrop')
		check(holder and holder:GetFrameLevel() > owner:GetFrameLevel(), kind .. ': one level above the button, over its icon')
		eq(T.around(ring, b), '0,0,0,0', kind .. ': the ring covers the drawn frame')
	end

	-- An icon that's a texture (the options window's image): the ring follows
	-- its backdrop, which shows and hides with it.
	local holderFrame = CreateFrame('Frame', nil, UIParent)
	holderFrame:SetSize(40, 40)
	holderFrame:SetPoint('CENTER')
	local image = holderFrame:CreateTexture(nil, 'ARTWORK')
	image:SetAllPoints()
	st:SetBackdrop(image, 'theme', 'theme', 'action')
	local ring = piece(st, image.backdrop, 'Ring', 'over')
	eq(ring and ring:GetParent():GetParent(), image.backdrop, "a texture's ring: on a child of its backdrop")
	image.backdrop:Hide()
	eq(ring and ring:IsVisible(), false, 'hidden with its backdrop')
	eq(#take_errors(), 0, 'no errors')
end)

test("a frame marked as not SaftUI's gets none of the art made on it: its ring is on a frame of SaftUI's", function()
	local st = blizzard()
	-- Someone else's buttons that a module still draws on with st:SetBackdrop
	-- (Hekili's) or st:SkinActionButton (the bags bar's Blizzard bag slots).
	-- Both still write .backdrop and .thick onto them, and st:SkinActionButton
	-- its own state textures, so the frame records each texture made on it
	-- rather than being locked: none may be the art's.
	local function owner()
		local f = button(st, 'BACKGROUND', 'OVERLAY')
		f.made = {}
		local create = f.CreateTexture
		f.CreateTexture = function(self, ...)
			local texture = create(self, ...)
			self.made[texture] = true
			return texture
		end
		st:MarkForeign(f)
		return f
	end
	local function checkHolder(f, label)
		local art = st.ThemeArt.Get(f.backdrop)
		local ring = art and art.over.Ring
		check(ring ~= nil, label .. ': its ring is drawn')
		if not ring then return end
		check(ring:GetParent() ~= f, label .. ": the ring isn't on the frame")
		eq(ring:GetParent():GetParent(), f.backdrop, label .. ': it is on a child of the backdrop')
		check(ring:GetParent():GetFrameLevel() > f:GetFrameLevel(), label .. ': over its icon')
		local mine = {}
		for _, set in ipairs({ art.pieces, art.over }) do
			for key, region in pairs(set) do
				if f.made[region] then mine[#mine + 1] = key end
			end
		end
		eq(table.concat(mine, ','), '', label .. ': no texture of the art is made on the frame')
	end

	local hekili = owner()
	st:SetBackdrop(hekili, 'theme', 'theme', 'action')
	checkHolder(hekili, 'through st:SetBackdrop')
	local slot = owner()
	st:SkinActionButton(slot, st.config.profile.buttons, 'slot')
	checkHolder(slot, 'through st:SkinActionButton')

	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	checkHolder(hekili, 'through st:SetBackdrop, after a switch')
	checkHolder(slot, 'through st:SkinActionButton, after a switch')
	eq(#take_errors(), 0, 'no errors')
end)

-- A frame level can be secret (a frame of Blizzard's in a restricted layout,
-- .agents/clients.md), so the holder does no math on one: one level over the
-- frame's own when only its parent's is secret, and left where it was made
-- (its frame's child, one over it) when the frame's own is. A secret value is
-- a newproxy here, which issecretvalue is told to recognise.
test("a ring's holder over a frame whose parent's level, or its own, is secret: placed without math on it", function()
	local st = blizzard()
	local secret = newproxy(false)
	local real = issecretvalue
	issecretvalue = function(v) return v == secret or real(v) end

	local parent = CreateFrame('Frame', nil, UIParent)
	parent:SetSize(36, 36)
	parent:SetPoint('CENTER')
	parent:SetFrameLevel(10)
	local f = st:CreateFrame('Frame', nil, parent)
	f:SetAllPoints(parent)
	f:SetFrameLevel(4)
	parent.GetFrameLevel = function() return secret end
	local ok, err = pcall(st.SetTemplate, st, f, 'theme', 'theme', 'slot')
	check(ok, "its parent's level secret: drawn: " .. tostring(err))
	local ring = piece(st, f, 'Ring', 'over')
	if check(ring ~= nil, "its parent's level secret: its ring is drawn") then
		eq(ring:GetParent():GetFrameLevel(), 5, "on a holder one over the frame's own level")
	end

	local g = st:CreateFrame('Frame', nil, UIParent)
	g:SetSize(36, 36)
	g:SetPoint('CENTER')
	g:SetFrameLevel(7)
	g.GetFrameLevel = function() return secret end
	ok, err = pcall(st.SetTemplate, st, g, 'theme', 'theme', 'slot')
	check(ok, 'its own level secret: drawn: ' .. tostring(err))
	ring = piece(st, g, 'Ring', 'over')
	if check(ring ~= nil, 'its own level secret: its ring is drawn') then
		eq(ring:GetParent():GetFrameLevel(), 8, 'on a holder where it was made, one over the frame')
	end

	issecretvalue = real
	eq(#take_errors(), 0, 'no errors')
end)

test('a backdrop its caller anchored keeps its anchors through Thick, Blizzard and Thick, with art only under Blizzard', function()
	local st = T.client('forever')
	local profile = st.config.profile
	-- An action button's backdrop, made to fill the button (the action bars),
	-- and a window's, placed by its own code.
	local a = button(st, 'BACKGROUND', 'OVERLAY')
	st:SetBackdrop(a, 'theme', 'theme', 'action')
	a.backdrop:ClearAllPoints()
	a.backdrop:SetAllPoints(a)
	local w = frame(st)
	st:SetBackdrop(w, 'theme', 'theme', 'window')
	w.backdrop:ClearAllPoints()
	w.backdrop:SetPoint('TOPLEFT', w, 'TOPLEFT', -5, 30)
	w.backdrop:SetPoint('BOTTOMRIGHT', w, 'BOTTOMRIGHT', 5, -5)
	local before = { [a] = anchors(a.backdrop), [w] = anchors(w.backdrop) }

	local function expect(name)
		for f, label in pairs({ [a] = 'the action button', [w] = 'the window' }) do
			local where = name .. ', ' .. label
			eq(anchors(f.backdrop), before[f], where .. ': the anchors its caller set')
			local art = T.art(f.backdrop) .. T.over(f.backdrop)
			if name == 'blizzard' then
				check(art ~= '', where .. ': its art')
			else
				eq(art, '', where .. ': no art')
			end
			eq(outerShown(f.backdrop), name == 'thick', where .. ": Thick's lines only under Thick")
		end
	end
	expect('thick')
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	expect('blizzard')
	eq(T.art(w.backdrop), METAL, 'the window wears the metal where it is')
	eq(T.over(a.backdrop), ACTION_RING, 'the action button its ring')
	profile.theme.name = 'thick'
	st:RedrawThemed()
	expect('thick')
	eq(#take_errors(), 0, 'no errors')
end)

test('an aura has no art; small is one line in Border; a header and a control draw nothing', function()
	local st = blizzard()
	local a = frame(st)
	st:SetBackdrop(a, 'theme', 'theme', 'aura')
	eq(T.art(a.backdrop), '', 'an aura: no art')
	eq(T.over(a.backdrop), '', 'an aura: nothing over the icon')
	check(not (a.backdrop.backdropInfo and a.backdrop.backdropInfo.edgeFile), 'an aura: no line')
	eq(fill(a.backdrop), '0.00,0.00,0.00,0.00', 'an aura: no fill')

	local s = frame(st)
	st:SetBackdrop(s, 'theme', 'theme', 'small')
	eq(edge(s.backdrop), '0.50,0.50,0.50,1.00', 'small: one line in Border')
	eq(inset(s.backdrop), 1, 'small: one line wide')
	eq(fill(s.backdrop), '0.09,0.09,0.19,0.90', 'small: the Background inside it')
	eq(T.art(s.backdrop) .. T.over(s.backdrop), '', 'small: no art')
	check(not outerShown(s.backdrop), "small: no Thick lines")

	local h = frame(st)
	st:SetTemplate(h, 'theme', 'theme', 'header')
	check(bare(h), 'a header strip draws nothing')
	local hb = frame(st)
	st:SetBackdrop(hb, 'theme', 'theme', 'header')
	check(bare(hb.backdrop), "a header's backdrop draws nothing")
	local c = frame(st)
	st:SetBackdrop(c, 'theme', 'theme', 'control')
	check(c.backdrop ~= nil, 'a control drawn under Blizzard still has its backdrop')
	check(c.backdrop and bare(c.backdrop), 'and it draws nothing')

	-- Kept as drawn: a switch to Thick draws the control as a small frame
	-- again, and the strip as Thick's.
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	local ref = frame(st)
	st:SetBackdrop(ref, 'theme', 'theme', 'small')
	eq(fill(c.backdrop), fill(ref.backdrop), 'the control under Thick: the fill of a small frame')
	eq(edge(c.backdrop), edge(ref.backdrop), 'its border')
	eq(inset(c.backdrop), 2, "Thick's inset")
	eq(offset(c.backdrop, 'TOPLEFT'), '-2.00,2.00', "and Thick's 2px out")
	check(outerShown(c.backdrop), "with Thick's lines")
	eq(fill(h), '0.30,0.30,0.30,0.40', "the header strip: Thick's border color at 0.4")
end)

test("Thick, Blizzard, Thin, Blizzard: art only under Blizzard, Thick's lines only under Thick, each backdrop at its kind's inset", function()
	local st = T.client('forever')
	local profile = st.config.profile
	-- Under Blizzard: where each backdrop's top left and bottom right sit, its
	-- fill's inset (nil: no fill to measure), and whether it has art.
	local BLIZZARD = {
		tooltip = { '-3.00,3.00', '3.00,-3.00', 3, true },
		window = { '-2.00,20.00', '2.00,-2.00', 2, true },
		action = { '-3.00,3.00', '3.00,-3.00', nil, true },
		small = { '-1.00,1.00', '1.00,-1.00', 1, false },
	}
	local frames = {}
	for kind in pairs(BLIZZARD) do
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', kind)
		frames[kind] = f
	end

	local function expect(name)
		for kind, f in pairs(frames) do
			local b, where = f.backdrop, name .. ', ' .. kind
			local want = BLIZZARD[kind]
			if name == 'thick' then
				want = { '-2.00,2.00', '2.00,-2.00', 2, false }
			elseif name == 'thin' then
				want = { '-1.00,1.00', '1.00,-1.00', 1, false }
			end
			eq(offset(b, 'TOPLEFT'), want[1], where .. ': its top left')
			eq(offset(b, 'BOTTOMRIGHT'), want[2], where .. ': its bottom right')
			if want[3] then eq(inset(b), want[3], where .. ": the fill's inset") end
			eq(st:DrawnInset(f), name == 'blizzard' and st.ThemeArt.Inset(kind) or want[3], where .. ': the drawn inset')
			eq(outerShown(b), name == 'thick', where .. ": Thick's lines only under Thick")
			local art = T.art(b) .. T.over(b)
			if want[4] then
				check(art ~= '', where .. ': its art')
			else
				eq(art, '', where .. ': no art')
			end
		end
	end

	expect('thick')
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	expect('blizzard')
	profile.theme.name = 'thin'
	st:RedrawThemed()
	expect('thin')
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	expect('blizzard')
	eq(T.art(frames.window.backdrop), METAL, 'the window wears the metal again')
	eq(T.over(frames.action.backdrop), ACTION_RING, 'the action button its ring')
	eq(#take_errors(), 0, 'no errors')
end)

test("a window's metal reaches the title bar above it", function()
	for _, client in ipairs({ 'retail', 'forever' }) do
		local st = blizzard(client)
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', 'window')
		local b = f.backdrop
		local title = client == 'retail' and 21 or 20
		eq(offset(b, 'TOPLEFT'), text(-2, title), client .. ": the title bar's height above the window")
		eq(offset(b, 'BOTTOMRIGHT'), '2.00,-2.00', client .. ': its inset outside it on the other sides')
		local i = b.backdropInfo and b.backdropInfo.insets or {}
		eq(text(i.left or -1, i.top or -1, i.right or -1, i.bottom or -1), text(2, title, 2, 2),
			client .. ': the fill is the window, under the title bar')
	end
end)

test('a recolor under Blizzard: the fill and the small lines follow, the art stays white, nothing moves', function()
	local st = blizzard()
	local drawn = {}
	for _, kind in ipairs({ 'tooltip', 'window', 'action', 'slot', 'small' }) do
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', kind)
		drawn[kind] = f.backdrop
	end
	local before = {}
	for _, b in pairs(drawn) do
		before[b] = anchors(b)
		eachPiece(st, b, function(_, p) before[p] = anchors(p) end)
	end
	-- A module's own color on a piece: a recolor takes it off, as it takes a
	-- module's border color off a backdrop.
	piece(st, drawn.tooltip, 'TopEdge'):SetVertexColor(1, 0, 0, 1)

	local blizzardColors = st.config.profile.templates.blizzard
	blizzardColors.backdropcolor = { 0, 0, 1, 1 }
	blizzardColors.bordercolor = { 1, 0, 0, 1 }
	st.config.profile.theme.opacity = 0.5
	st:RecolorThemed()

	eq(fill(drawn.tooltip), '0.00,0.00,1.00,0.50', 'the fill takes the Background and the Opacity')
	eq(fill(drawn.small), '0.00,0.00,1.00,0.50', "a small frame's fill too")
	eq(edge(drawn.small), '1.00,0.00,0.00,1.00', "a small frame's line takes the Border")
	eq(fill(drawn.window), '0.12,0.12,0.13,0.50', "a window keeps the Window background, at the Opacity")
	eq(fill(drawn.action), '0.00,0.00,0.00,0.00', "an action button's fill stays clear")
	eq(text(piece(st, drawn.action, 'SlotArt'):GetAlpha()), '0.50', "the action button's slot art takes the Opacity")
	eq(text(piece(st, drawn.slot, 'SlotArt'):GetAlpha()), '0.50', "a slot's too")
	local tinted = {}
	for _, b in pairs(drawn) do
		eachPiece(st, b, function(key, p)
			if text(p:GetVertexColor()) ~= '1.00,1.00,1.00,1.00' then tinted[#tinted + 1] = key end
			eq(anchors(p), before[p], key .. ' has not moved')
		end)
		eq(anchors(b), before[b], 'the backdrop has not moved')
	end
	eq(table.concat(tinted, ','), '', 'every piece is white')
	eq(text(piece(st, drawn.tooltip, 'TopEdge'):GetAlpha()), '1.00', 'the border stays opaque')
end)

test('None under Blizzard draws nothing and clears the art', function()
	local st = blizzard()
	local t = frame(st)
	st:SetBackdrop(t, 'theme', 'theme', 'tooltip')
	check(T.art(t.backdrop) ~= '', 'drawn with the theme: the tooltip border')
	st:SetBackdrop(t, 'none', 'theme', 'tooltip')
	check(bare(t.backdrop), 'drawn again with None: no backdrop, and no art')

	local a = frame(st)
	st:SetBackdrop(a, 'theme', 'theme', 'action')
	st:SetBackdrop(a, 'none')
	check(bare(a.backdrop), 'an action button drawn None: no ring, no slot art')
	local s = frame(st)
	st:SetTemplate(s, 'theme', 'theme', 'window')
	st:SetTemplate(s, 'none')
	check(bare(s), 'a frame drawn on itself with None: no metal')

	st:RedrawThemed()
	check(bare(t.backdrop) and bare(a.backdrop) and bare(s), 'a redraw keeps them bare')
end)

test('CalculateSpacing follows the drawn inset', function()
	local st = blizzard()
	local profile = st.config.profile
	local a = frame(st)
	st:SetBackdrop(a, 'theme', 'theme', 'action')
	eq(st:CalculateSpacing(a), 3, 'an action button under Blizzard')
	eq(st:DrawnInset(a), 3, 'DrawnInset of the owner')
	eq(st:DrawnInset(a.backdrop), 3, 'and of its backdrop')
	eq(st:DrawnKind(a), 'action', 'DrawnKind of the owner')
	eq(st:DrawnKind(a.backdrop), 'action', 'and of its backdrop')
	local never = frame(st)
	eq(st:CalculateSpacing(never), 0, 'a frame never drawn')
	eq(st:DrawnInset(never), nil, 'has no drawn inset')
	eq(st:DrawnKind(never), nil, 'and no drawn kind')

	local t = frame(st)
	st:SetBackdrop(t, 'theme', 'theme', 'tooltip')
	eq(st:CalculateSpacing(a, t, 4), 4 + 3 + 3, "with an anchor: both frames' insets and the spacing")
	local backdrops = setmetatable({}, { __mode = 'k' })
	local o = frame(st)
	st:SetBackdropIn(backdrops, o, 'theme', 'theme', 'window')
	eq(st:DrawnInset(o), 2, 'the owner of a SetBackdropIn backdrop')
	eq(st:DrawnKind(o), 'window', 'and its kind')
	local own = frame(st)
	st:SetTemplate(own, 'theme', 'theme', 'small')
	eq(st:DrawnInset(own), 1, 'a frame drawn on itself')

	profile.theme.name = 'thick'
	st:RedrawThemed()
	eq(st:CalculateSpacing(a), 2, 'under Thick after a redraw')
	eq(st:CalculateSpacing(a, t, 4), 4 + 2 + 2, 'with an anchor under Thick')
	profile.theme.name = 'thin'
	st:RedrawThemed()
	eq(st:CalculateSpacing(a), 1, 'under Thin')
	st:SetBackdrop(a, 'none')
	eq(st:CalculateSpacing(a), 0, 'drawn None')
end)

test('a frame first drawn in combat under Blizzard gets its art', function()
	local st = blizzard()
	stub.in_combat = true
	local slot = frame(st)
	st:SetBackdrop(slot, 'theme', 'theme', 'slot')
	eq(T.art(slot.backdrop), SLOT_ART, "the empty slot's art")
	eq(T.over(slot.backdrop), SLOT_RING, 'and the ring')
	eq(#take_errors(), 0, 'no errors')
	stub.in_combat = false
end)

test("drawing under Blizzard writes nothing onto a frame that isn't SaftUI's", function()
	local st = blizzard()
	local backdrops = setmetatable({}, { __mode = 'k' })
	local frames = {}
	for kind in pairs(st.THEME_KINDS) do
		local f = CreateFrame('Frame', nil, UIParent)
		f:SetSize(40, 40)
		f:SetPoint('CENTER')
		locked(f, 'Blizzard')
		local ok, err = pcall(st.SetBackdropIn, st, backdrops, f, 'theme', 'theme', kind)
		check(ok, kind .. ': drawn without writing onto the frame: ' .. tostring(err))
		frames[kind] = f
	end
	st:RecolorThemed()
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	local errors = take_errors()
	eq(#errors, 0, 'nothing written through a recolor and two switches: ' .. tostring(errors[1]))
	eq(T.art(backdrops[frames.tooltip]), TOOLTIP, 'the tooltip border is drawn')
	eq(T.over(backdrops[frames.slot]), SLOT_RING, "a slot's ring is drawn")
end)

------------------------------------------------------------------ a frame's own border color

-- The own-color piece of a drawn frame (shown or not), or nil.
local function own(st, f)
	local art = st.ThemeArt.Get(f)
	return art and art.own
end

-- The own-color piece as text: 'file-or-atlas r,g,b,a' while shown, 'off' otherwise.
local function ownText(st, f)
	local p = own(st, f)
	if not (p and p:IsShown()) then return 'off' end
	return tostring(p:GetAtlas() or p:GetTexture()) .. ' ' .. text(p:GetVertexColor())
end

-- The vertex colors of every piece of a border, one text if they're the same.
local function tint(st, f)
	local colors = {}
	for _, p in pairs(st.ThemeArt.Get(f).pieces) do colors[text(p:GetVertexColor())] = true end
	local list = {}
	for c in pairs(colors) do list[#list + 1] = c end
	table.sort(list)
	return table.concat(list, ' | ')
end

test("SetBorderColor under Thick and Thin is the border color, and no color is the theme's", function()
	local st = T.client('forever')
	for _, name in ipairs({ 'thick', 'thin' }) do
		st.config.profile.theme.name = name
		local theme = T.text(unpack(st.config.profile.templates[name].bordercolor))
		for _, kind in ipairs({ 'panel', 'window', 'action', 'slot', 'aura', 'small', 'control' }) do
			local f = frame(st)
			st:SetBackdrop(f, 'theme', 'theme', kind)
			st:SetBorderColor(f.backdrop, 1, 0, 0, 0.5)
			eq(edge(f.backdrop), '1.00,0.00,0.00,0.50', name .. ' ' .. kind .. ': the border color')
			st:SetBorderColor(f.backdrop, 0, 1, 0)
			eq(edge(f.backdrop), '0.00,1.00,0.00,1.00', name .. ' ' .. kind .. ': no alpha is opaque')
			st:SetBorderColor(f.backdrop)
			eq(edge(f.backdrop), theme, name .. ' ' .. kind .. ": no color: the theme's")
			eq(T.art(f.backdrop) .. T.over(f.backdrop), '', name .. ' ' .. kind .. ': no Blizzard art')
		end
		-- A strip's border is none: no color puts that back.
		local h = frame(st)
		st:SetBackdrop(h, 'theme', 'theme', 'header')
		st:SetBorderColor(h.backdrop, 1, 0, 0)
		st:SetBorderColor(h.backdrop)
		eq(edge(h.backdrop), '0.00,0.00,0.00,0.00', name .. ' header: no border')
	end

	-- A frame drawn on itself (st:SetTemplate), and a frame never drawn or drawn None.
	local f = frame(st)
	st:SetTemplate(f, 'theme', 'theme', 'panel')
	st:SetBorderColor(f, 0, 0, 1)
	eq(edge(f), '0.00,0.00,1.00,1.00', 'a frame drawn with st:SetTemplate')
	local never = frame(st)
	st:SetBorderColor(never, 1, 0, 0)
	st:SetBorderColor(never)
	local none = frame(st)
	st:SetBackdrop(none, 'theme', 'theme', 'panel')
	st:SetBackdrop(none, 'none')
	st:SetBorderColor(none.backdrop, 1, 0, 0)
	eq(#take_errors(), 0, 'a frame never drawn or drawn None is left alone, with no error')
	eq(none.backdrop.backdropInfo, nil, 'drawn None stays bare')
end)

test("SetBorderColor under Blizzard: tooltip and metal pieces tinted, the action's equipped border, the slot's and aura's white icon border, no color takes it off", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = blizzard(client)

		-- The tooltip and metal borders: every piece tinted, white again with no color.
		for _, kind in ipairs({ 'tooltip', 'panel', 'bar', 'window' }) do
			local f = frame(st)
			st:SetBackdrop(f, 'theme', 'theme', kind)
			local b = f.backdrop
			st:SetBorderColor(b, 1, 0, 0, 0.5)
			eq(tint(st, b), '1.00,0.00,0.00,0.50', client .. ' ' .. kind .. ': every piece tinted')
			eq(own(st, b), nil, client .. ' ' .. kind .. ': no own-color piece')
			st:SetBorderColor(b)
			eq(tint(st, b), '1.00,1.00,1.00,1.00', client .. ' ' .. kind .. ': no color: white')
		end

		-- An action button: Blizzard's equipped border in the color, over the ring.
		local a = button(st, 'BACKGROUND', 'OVERLAY')
		st:SetBackdrop(a, 'theme', 'theme', 'action')
		eq(ownText(st, a.backdrop), 'off', client .. ' action: no border until one is given')
		st:SetBorderColor(a.backdrop, 0, 1, 0)
		eq(ownText(st, a.backdrop), 'UI-HUD-ActionBar-IconFrame-Border 0.00,1.00,0.00,1.00', client .. " action: the equipped border, in the green")
		eq(T.over(a.backdrop), ACTION_RING, client .. ' action: the ring stays')
		eq(T.art(a.backdrop), ACTION_ART, client .. ' action: so does the slot art')
		eq(text(piece(st, a.backdrop, 'SlotArt'):GetVertexColor()), '1.00,1.00,1.00,1.00', client .. ' action: the slot art is untinted')
		local o = own(st, a.backdrop)
		eq(o:GetParent(), a, client .. " action: a texture of the button's own, as the ring is")
		eq(T.around(o, a.backdrop), '0,0,0,0', client .. ' action: it covers the drawn frame')
		local ring = piece(st, a.backdrop, 'Ring', 'over')
		check(depth(o) > depth(ring), client .. ' action: over the ring')
		check(depth(o) > depth(a.icon), client .. ' action: over the icon')
		check(depth(o) < depth(a.text), client .. ' action: under its font strings')
		st:SetBorderColor(a.backdrop, 0, 0, 1)
		eq(ownText(st, a.backdrop), 'UI-HUD-ActionBar-IconFrame-Border 0.00,0.00,1.00,1.00', client .. ' action: recolored')
		st:SetBorderColor(a.backdrop)
		eq(ownText(st, a.backdrop), 'off', client .. ' action: no color takes it off')
		eq(T.over(a.backdrop), ACTION_RING, client .. ' action: the ring stays')

		-- A slot and an aura: the white icon border in the color.
		local WHITE = [[Interface\Common\WhiteIconFrame]]
		local slot = button(st, 'BORDER', 'ARTWORK')
		st:SetBackdrop(slot, 'theme', 'theme', 'slot')
		st:SetBorderColor(slot.backdrop, 0.64, 0.21, 0.93)
		eq(ownText(st, slot.backdrop), WHITE .. ' 0.64,0.21,0.93,1.00', client .. " slot: the white icon border in the quality's color")
		eq(T.over(slot.backdrop), SLOT_RING, client .. ' slot: the ring stays')
		eq(own(st, slot.backdrop):GetParent(), slot, client .. " slot: a texture of the button's own")
		check(depth(own(st, slot.backdrop)) > depth(slot.icon), client .. ' slot: over the icon')
		check(depth(own(st, slot.backdrop)) < depth(slot.text), client .. ' slot: under its count')
		st:SetBorderColor(slot.backdrop)
		eq(ownText(st, slot.backdrop), 'off', client .. ' slot: no color: off (a free slot)')

		local aura = frame(st)
		st:SetBackdrop(aura, 'theme', 'theme', 'aura')
		eq(ownText(st, aura.backdrop), 'off', client .. ' aura: bare')
		st:SetBorderColor(aura.backdrop, 1, 0.5, 0, 1)
		eq(ownText(st, aura.backdrop), WHITE .. ' 1.00,0.50,0.00,1.00', client .. ' aura: the white icon border, tinted')
		st:SetBorderColor(aura.backdrop)
		eq(ownText(st, aura.backdrop), 'off', client .. ' aura: off with no color')

		-- A small frame: its line.
		local small = frame(st)
		st:SetBackdrop(small, 'theme', 'theme', 'small')
		st:SetBorderColor(small.backdrop, 1, 1, 0, 1)
		eq(edge(small.backdrop), '1.00,1.00,0.00,1.00', client .. " small: the line's color")
		st:SetBorderColor(small.backdrop)
		eq(edge(small.backdrop), '0.50,0.50,0.50,1.00', client .. " small: no color: Blizzard's Border")

		-- The theme's colors back (a recolor) take every own color off, as they
		-- take it off a backdrop: the module sets it again on OnColorsChanged.
		st:SetBorderColor(a.backdrop, 0, 1, 0)
		st:SetBorderColor(slot.backdrop, 1, 0, 0)
		local tip = frame(st)
		st:SetBackdrop(tip, 'theme', 'theme', 'tooltip')
		st:SetBorderColor(tip.backdrop, 1, 0, 0)
		st:RecolorThemed()
		eq(ownText(st, a.backdrop), 'off', client .. ': a recolor takes the equipped border off')
		eq(ownText(st, slot.backdrop), 'off', client .. ': and the quality border')
		eq(tint(st, tip.backdrop), '1.00,1.00,1.00,1.00', client .. ': and a tint')

		-- A redraw (a theme switch and back) leaves no own color either, and the
		-- piece is shown again by the next color.
		st:SetBorderColor(a.backdrop, 0, 1, 0)
		st.config.profile.theme.name = 'thick'
		st:RedrawThemed()
		eq(ownText(st, a.backdrop), 'off', client .. ': under Thick, no own-color piece shows')
		local thick = st.config.profile.templates.thick.bordercolor
		eq(T.edge_rgb(a.backdrop), T.text(thick[1], thick[2], thick[3]), client .. ": Thick's border, not the green")
		st:SetBorderColor(a.backdrop, 0, 1, 0)
		eq(T.edge_rgb(a.backdrop), '0.00,1.00,0.00', client .. ': Thick: the green line')
		eq(ownText(st, a.backdrop), 'off', client .. ': and still no piece')
		st.config.profile.theme.name = 'blizzard'
		st:RedrawThemed()
		st:SetBorderColor(a.backdrop, 0, 1, 0)
		eq(ownText(st, a.backdrop), 'UI-HUD-ActionBar-IconFrame-Border 0.00,1.00,0.00,1.00', client .. ': back under Blizzard: the border shows')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("a foreign owner given SetBorderColor under Blizzard gets no texture made on it", function()
	local st = blizzard()
	-- Someone else's buttons a module still draws on (Hekili's, the bags bar's
	-- Blizzard slots, WeakAuras' regions): every texture made on the frame is
	-- recorded, and none may be the own-color piece's.
	local function foreign()
		local f = button(st, 'BACKGROUND', 'OVERLAY')
		f.made = 0
		local create = f.CreateTexture
		f.CreateTexture = function(self, ...)
			self.made = self.made + 1
			return create(self, ...)
		end
		st:MarkForeign(f)
		return f
	end
	for _, kind in ipairs({ 'action', 'slot', 'aura' }) do
		local f = foreign()
		st:SetBackdrop(f, 'theme', 'theme', kind)
		local before = f.made
		st:SetBorderColor(f.backdrop, 1, 0, 0)
		eq(f.made, before, kind .. ': no texture is made on the frame')
		local o = own(st, f.backdrop)
		check(o ~= nil and o:IsShown(), kind .. ": the border is drawn all the same")
		check(o and o:GetParent() ~= f, kind .. ": on a frame of SaftUI's, not the frame")
		local ring = piece(st, f.backdrop, 'Ring', 'over')
		if kind == 'aura' then
			eq(ring, nil, kind .. ': bare, with no ring')
		elseif check(ring ~= nil and ring:IsShown(), kind .. ': its ring is drawn') then
			check(depth(o) > depth(ring), kind .. ': the border is over the ring on a holder too')
		end
		eq(o and o:GetParent():GetParent(), f.backdrop, kind .. ': a child of the backdrop')
		st:SetBorderColor(f.backdrop)
		st:SetBorderColor(f.backdrop, 0, 1, 0)
		eq(f.made, before, kind .. ': nor on a second color')
	end

	-- Blizzard's own frames, drawn behind with st:SetBackdropIn: the same.
	local backdrops = setmetatable({}, { __mode = 'k' })
	for _, kind in ipairs({ 'action', 'slot', 'aura' }) do
		local owner = CreateFrame('CheckButton', nil, UIParent)
		owner:SetSize(36, 36)
		owner:SetPoint('CENTER')
		locked(owner, 'Blizzard')
		local b = st:SetBackdropIn(backdrops, owner, 'theme', 'theme', kind)
		local ok, err = pcall(st.SetBorderColor, st, b, 1, 0, 0)
		check(ok, kind .. ' (SetBackdropIn): written nothing onto the frame: ' .. tostring(err))
		local o = own(st, b)
		eq(o and o:GetParent():GetParent(), b, kind .. ' (SetBackdropIn): on a child of the backdrop')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("an action button drawn with st:SetTemplate: its own-color piece is on a holder, over the ring", function()
	local st = blizzard()
	for _, kind in ipairs({ 'action', 'slot' }) do
		local f = frame(st)
		st:SetTemplate(f, 'theme', 'theme', kind)
		st:SetBorderColor(f, 0, 1, 0)
		local o, ring = own(st, f), piece(st, f, 'Ring', 'over')
		check(o ~= nil and o:IsShown(), kind .. ': the border shows')
		check(ring ~= nil and ring:IsShown(), kind .. ': its ring is drawn')
		if o and ring then
			eq(o:GetParent(), ring:GetParent(), kind .. ': on the ring\'s holder')
			check(o:GetParent() ~= f, kind .. ': a frame of SaftUI\'s over the drawn frame')
			check(depth(o) > depth(ring), kind .. ': over the ring')
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test('SetBorderColor leaves a control alone under Blizzard', function()
	local st = blizzard()
	local c = frame(st)
	st:SetBackdrop(c, 'theme', 'theme', 'control')
	st:SetBorderColor(c.backdrop, 1, 0, 0)
	check(bare(c.backdrop), 'a control draws nothing, with a color')
	eq(own(st, c.backdrop), nil, 'and has no own-color piece')
	st:SetBorderColor(c.backdrop)
	check(bare(c.backdrop), 'nor with none')
	-- Under Thick the same frame is a small frame and takes the color.
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	st:SetBorderColor(c.backdrop, 1, 0, 0)
	eq(edge(c.backdrop), '1.00,0.00,0.00,1.00', 'under Thick it is a small frame, and takes it')
	-- Headers and the close button, which draw nothing under Blizzard, too.
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	for _, kind in ipairs({ 'header', 'close' }) do
		local f = frame(st)
		st:SetBackdrop(f, 'theme', 'theme', kind)
		st:SetBorderColor(f.backdrop, 1, 0, 0)
		check(bare(f.backdrop), kind .. ' draws nothing, with a color')
	end
	eq(#take_errors(), 0, 'no errors')
end)

-- Every SaftUI Lua file the game loads, outside the bundled libraries
-- (T.saftui_files, the walk tests/core/theme_kinds_test.lua checks), as
-- .agents/taint.md rule 12 says.
test('no SaftUI file names NineSliceUtil', function()
	local files = T.saftui_files()
	check(#files > 140, 'every SaftUI file, not a few: ' .. #files)
	local found = {}
	for _, path in ipairs(files) do
		local source = read_saftui_source(path)
		if check(source ~= nil, path .. ' is read') and source:find('NineSliceUtil', 1, true) then
			found[#found + 1] = path
		end
	end
	eq(table.concat(found, ', '), '', 'no SaftUI file names NineSliceUtil')
end)
