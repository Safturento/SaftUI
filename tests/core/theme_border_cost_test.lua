-- What st:SetBorderColor costs (SaftUI-Core/theme.lua, themeart.lua): a color
-- pass repaints every border a reader holds through it (bag slots, an
-- equipped border, a feed entry, a tooltip), so under every theme it makes
-- no table and, under Blizzard, textures and places its own-color piece only
-- once, then only colors it. 40 borders, 100 passes.
--
-- Real: Core's theme and Blizzard's art on the stubs; the cost helper.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')

local KINDS = { 'slot', 'aura', 'panel', 'small', 'tooltip' }

-- 40 drawn frames, each given a border color once (a cold widget's first
-- setter call makes its stub table, and a Blizzard piece is made).
local function borders(st, theme)
	local list = {}
	for i = 1, 40 do
		local f = st:CreateFrame('Frame', nil, UIParent)
		f:SetSize(36, 36)
		f:SetPoint('CENTER')
		local kind = KINDS[i % #KINDS + 1]
		if theme == 'none' then
			-- Drawn None: recorded, with no backdrop; SetBorderColor must leave it alone.
			st:SetTemplate(f, 'none', 'theme', kind)
			list[i] = f
		elseif i % 2 == 0 then
			-- Drawn on itself: no host.
			st:SetTemplate(f, 'theme', 'theme', kind)
			list[i] = f
		else
			st:SetBackdrop(f, 'theme', 'theme', kind)
			list[i] = f.backdrop
		end
		st:SetBorderColor(list[i], 0.1, 0.2, 0.3, 1)
	end
	return list
end

for _, client in ipairs({ 'forever', 'retail' }) do
	for _, theme in ipairs({ 'thick', 'thin', 'blizzard', 'none' }) do
		test(('%s, %s: 40 borders recolored 100 times make no garbage and move or texture nothing'):format(client, theme), function()
			local st = T.client(client)
			st.config.profile.theme.name = theme == 'none' and 'thick' or theme
			local list = borders(st, theme)
			local m = C.measure(function()
				for i = 1, 40 do st:SetBorderColor(list[i], 0.4, 0.5, 0.6, 1) end
			end, 100)
			check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
			eq(m.forbidden.total, 0, 'forbidden calls: ' .. (function()
				local out = {}
				for k, v in pairs(m.forbidden.by) do out[#out + 1] = k .. '=' .. v end
				table.sort(out)
				return table.concat(out, ',')
			end)())
			eq(m.made, 0, 'nothing made')
			if theme ~= 'none' then
				check(m.calls.total >= 4000, 'it does color: ' .. m.calls.total)
			else
				eq(m.calls.total, 0, 'drawn None: nothing is colored')
				eq(list[1].backdropInfo, nil, 'and it stays bare')
			end
			C.print(client .. ' ' .. theme, m)
		end)
	end
end

-- r3 (Task 3's re-review): the same pass with the stub making Blizzard's backdrop
-- pieces (the nine textures SetupPieceVisuals makes). A color pass colors the
-- backdrop through its setter and leaves the pieces alone: no piece is made,
-- textured, placed or recolored by hand.
local PIECES = { 'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner',
	'TopEdge', 'BottomEdge', 'LeftEdge', 'RightEdge', 'Center' }

local function piece_colors(list)
	local out = {}
	for i, frame in ipairs(list) do
		for _, name in ipairs(PIECES) do
			local texture = frame[name]
			if texture then
				local r, g, b, a = texture:GetVertexColor()
				out[#out + 1] = ('%d.%s=%s,%s,%s,%s'):format(i, name, tostring(r), tostring(g), tostring(b), tostring(a))
			end
		end
	end
	return table.concat(out, ';')
end

for _, client in ipairs({ 'forever', 'retail' }) do
	for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
		test(('%s, %s: with the backdrop pieces made, a color pass leaves them alone'):format(client, theme), function()
			local st = T.client(client)
			stub.backdrop_pieces = true
			st.config.profile.theme.name = theme
			local list = borders(st, theme)
			local pieces = 0
			for _, frame in ipairs(list) do
				for _, name in ipairs(PIECES) do if frame[name] then pieces = pieces + 1 end end
			end
			check(pieces > 0, 'the stub made pieces: ' .. pieces)
			local before = piece_colors(list)
			local m = C.measure(function()
				for i = 1, 40 do st:SetBorderColor(list[i], 0.4, 0.5, 0.6, 1) end
			end, 100)
			eq(m.made, 0, 'nothing made')
			eq(m.forbidden.total, 0, 'nothing placed, textured or reparented')
			check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
			eq(piece_colors(list), before, 'no piece was recolored by hand')
			stub.backdrop_pieces = nil
		end)
	end
end

-- The own-color piece of a frame drawn as kind under Blizzard.
local function piece(st, f)
	local art = st.ThemeArt.Get(f)
	return art and art.own
end

test('Blizzard: the own-color piece is made and placed once, and a color call places and textures nothing', function()
	local st = T.client('forever')
	st.config.profile.theme.name = 'blizzard'
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36); f:SetPoint('CENTER')
	st:SetBackdrop(f, 'theme', 'theme', 'slot')
	st:SetBorderColor(f.backdrop, 1, 0, 0, 1)
	local own = piece(st, f.backdrop)
	check(own, 'a piece is made')
	local m = C.measure(function() st:SetBorderColor(f.backdrop, 0, 1, 0, 1) end)
	eq(m.forbidden.total, 0, 'a color call places and textures nothing')
	local r, g, b = own:GetVertexColor()
	eq(r .. ',' .. g .. ',' .. b, '0,1,0', 'it takes the color')
	check(own:IsShown(), 'and shows')
	st:SetBorderColor(f.backdrop)
	check(not own:IsShown(), 'no color hides it')
	st:SetBorderColor(f.backdrop, 0, 0, 1, 1)
	check(own:IsShown(), 'and a color shows it again')
end)

test('Blizzard: another art or another host textures and places the piece again', function()
	local st = T.client('forever')
	st.config.profile.theme.name = 'blizzard'
	local look = { name = 'blizzard', colors = st.config.profile.templates.blizzard }
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36); f:SetPoint('CENTER')
	st:SetBackdrop(f, 'theme', 'theme', 'slot')
	local b = f.backdrop
	local hostA, hostB = CreateFrame('Frame', nil, UIParent), CreateFrame('Frame', nil, UIParent)
	st.ThemeArt.SetBorder(b, look, 'slot', hostA, 1, 0, 0, 1)
	local own = piece(st, b)
	eq(own:GetParent(), hostA, 'made on the first host')
	local same = C.measure(function() st.ThemeArt.SetBorder(b, look, 'slot', hostA, 0, 1, 0, 1) end)
	eq(same.forbidden.total, 0, 'the same art and host: only colored')
	local art = C.measure(function() st.ThemeArt.SetBorder(b, look, 'action', hostA, 0, 1, 0, 1) end)
	check((art.forbidden.by.SetTexture or 0) + (art.forbidden.by.SetAtlas or 0) >= 1, 'another art is textured again')
	local host = C.measure(function() st.ThemeArt.SetBorder(b, look, 'action', hostB, 0, 1, 0, 1) end)
	check((host.forbidden.by.ClearAllPoints or 0) >= 1, 'another host places it again')
	eq(own:GetParent(), hostA, 'and it stays on the first (a piece is never re-parented)')
end)

test('Blizzard: a frame with no host, raised after it is drawn, keeps its own-color piece above it when recolored', function()
	local st = T.client('forever')
	st.config.profile.theme.name = 'blizzard'
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36); f:SetPoint('CENTER')
	st:SetTemplate(f, 'theme', 'theme', 'slot')
	st:SetBorderColor(f, 1, 0, 0, 1)
	local own = piece(st, f)
	check(own, 'a piece is made')
	local holder = own:GetParent()
	check(holder ~= f, 'on a holder of its own (the frame has no host)')
	f:SetFrameLevel(f:GetFrameLevel() + 10)
	st:SetBorderColor(f, 0, 1, 0, 1)
	check(holder:GetFrameLevel() > f:GetFrameLevel(), 'the holder is above the raised frame: ' .. holder:GetFrameLevel() .. ' over ' .. f:GetFrameLevel())
end)

test('a strip drawn with a theme override still takes the profile theme: its border color is the backdrop line', function()
	local st = T.client('forever')
	st.config.profile.theme.name = 'thick'
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(100, 20); f:SetPoint('CENTER')
	st:SetBackdrop(f, 'blizzard', 'solid', 'header')
	st:SetBorderColor(f.backdrop, 1, 0, 0, 1)
	eq(string.format('%.2f,%.2f,%.2f,%.2f', f.backdrop:GetBackdropBorderColor()), '1.00,0.00,0.00,1.00', 'the backdrop border took the color')
	check(not piece(st, f.backdrop), 'no Blizzard piece')
end)
