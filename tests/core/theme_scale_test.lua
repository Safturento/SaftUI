-- The theme engine at every UI scale (SaftUI-Core/theme.lua, themeart.lua,
-- panels.lua, uiscale.lua): every border and line it draws is a whole number
-- of pixels wide, in the units of the frame it is drawn on.
--   - k = 1, the owner's screen: today's numbers exactly (edge 1, insets 2 / 1,
--     Thick's strips one out and 3 wide, the kinds' art insets), for every
--     kind under every theme on both clients, against the engine's drawn
--     state from before this work (theme_k1_golden.lua);
--   - k = 0.75, 1.25 and 1.55: an edge one line (st:GetLineSize), insets in
--     lines (look.lines), the strips one line out and three wide, a backdrop
--     placed in its owner's lines, Blizzard's insets in whole pixels, a frame
--     with a scale of its own in its own pixels, a redraw after a scale
--     change, the close button and st.BACKDROP;
--   - st:SnapDrawn, switched by st.SNAP_DRAWN ('unsnap' shipped, 'round' and
--     'none' the other values), and left alone on a protected frame in combat.
--
-- Real: theme.lua, themeart.lua, panels.lua and uiscale.lua, with Core's
-- helpers and the profile's defaults, on both clients.
local T = load_test_file('lib/theme_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local S = load_test_file('core/theme_snapshot.lua')
local SECRETS = load_test_file('lib/secrets.lua')
local GOLD = load_test_file('core/theme_k1_golden.lua')

local KS = { 0.75, 1.25, 1.55 }

local function world(client, theme)
	local st = T.client(client or 'forever')
	if theme then st.config.profile.theme.name = theme end
	return st
end

local function owner_of(st, how, kind, w, h)
	local owner = st:CreateFrame('Frame', nil, UIParent)
	owner:SetSize(w or 36, h or 36)
	owner:SetPoint('CENTER')
	if how == 'template' then
		st:SetTemplate(owner, 'theme', 'theme', kind)
	else
		st:SetBackdrop(owner, 'theme', 'theme', kind)
	end
	return owner
end

local function pts(region)
	local out = {}
	for i = 1, region:GetNumPoints() do
		local p, _, _, x, y = region:GetPoint(i)
		out[p] = { x = x, y = y }
	end
	return out
end

local function sorted_kinds(st)
	return S.kinds(st)
end

local function close_to(a, b, tol)
	return type(a) == 'number' and type(b) == 'number' and math.abs(a - b) <= (tol or 1e-6)
end

-- Whole pixels, in the units of region: value over region's pixel is a whole number.
local function whole_px(st, value, region)
	local n = value / st:GetPixelSize(region)
	return math.abs(n - math.floor(n + 0.5)) < 1e-6
end

------------------------------------------------------------------ k = 1

test("k 1: today's drawn state exactly, text for text, on both clients: every kind under Thick, Thin and Blizzard, redrawn, in a table, tinted, hosted, None and the close button", function()
	local seen = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = world(client)
		local rows = S.all(st, client)
		for key, text in pairs(rows) do
			eq(text, GOLD[key], key)
			seen = seen + 1
		end
		for key in pairs(GOLD) do
			if key:sub(1, #client) == client then check(rows[key] ~= nil, key .. ' is drawn') end
		end
	end
	eq(seen, 414, 'every row was compared')
end)

test("k 1: the numbers the brief names, rawequal: edge 1, insets 2 / 1 / the art's, strips and placement", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = world(client)
		for _, kind in ipairs(sorted_kinds(st)) do
			st.config.profile.theme.name = 'thick'
			local owner = owner_of(st, 'backdrop', kind)
			local bd = owner.backdrop
			local strip = kind == 'header' or kind == 'close'
			eq(bd.backdropInfo.edgeSize, 1, client .. ' Thick ' .. kind .. ': edge')
			check(rawequal(bd.backdropInfo.edgeSize, 1), 'rawequal 1')
			local want = strip and 0 or 2
			check(rawequal(bd.backdropInfo.insets.left, want), client .. ' Thick ' .. kind .. ': inset ' .. tostring(bd.backdropInfo.insets.left))
			check(rawequal(st:DrawnInset(owner), 2), 'DrawnInset 2')
			local at = pts(bd)
			check(rawequal(at.TOPLEFT.x, -2) and rawequal(at.TOPLEFT.y, 2), 'TOPLEFT -2, 2')
			check(rawequal(at.BOTTOMRIGHT.x, 2) and rawequal(at.BOTTOMRIGHT.y, -2), 'BOTTOMRIGHT 2, -2')
			if not strip then
				local left = pts(bd.altborder.LEFT)
				check(rawequal(left.TOPLEFT.x, -1) and rawequal(left.TOPLEFT.y, 1), 'LEFT strip TOPLEFT -1, 1')
				check(rawequal(left.BOTTOMLEFT.x, -1) and rawequal(left.BOTTOMLEFT.y, -1), 'LEFT strip BOTTOMLEFT -1, -1')
				check(rawequal(bd.altborder.LEFT:GetWidth(), 3), 'LEFT strip 3 wide')
				local right = pts(bd.altborder.RIGHT)
				check(rawequal(right.TOPRIGHT.x, 1) and rawequal(bd.altborder.RIGHT:GetWidth(), 3), 'RIGHT strip')
				local top = pts(bd.altborder.TOP)
				check(rawequal(top.TOPLEFT.y, 1) and rawequal(bd.altborder.TOP:GetHeight(), 3), 'TOP strip')
				local bottom = pts(bd.altborder.BOTTOM)
				check(rawequal(bottom.BOTTOMLEFT.y, -1) and rawequal(bottom.BOTTOMLEFT.x, 1), 'BOTTOM strip')
			end

			st.config.profile.theme.name = 'thin'
			st:RedrawThemed()
			check(rawequal(bd.backdropInfo.edgeSize, 1), 'Thin edge 1')
			check(rawequal(bd.backdropInfo.insets.left, strip and 0 or 1), 'Thin inset 1')
			check(rawequal(st:DrawnInset(owner), 1), 'Thin DrawnInset 1')
			at = pts(bd)
			check(rawequal(at.TOPLEFT.x, -1) and rawequal(at.TOPLEFT.y, 1), 'Thin TOPLEFT -1, 1')

			st.config.profile.theme.name = 'blizzard'
			st:RedrawThemed()
			local inset = st.ThemeArt.Inset(kind)
			check(rawequal(st:DrawnInset(owner), inset), 'Blizzard DrawnInset is the art inset: ' .. kind)
			at = pts(bd)
			check(rawequal(at.TOPLEFT.x, -inset) and rawequal(at.TOPLEFT.y, st.ThemeArt.Top(kind)), 'Blizzard placement ' .. kind)
		end
		eq(st:ThemeInset('thick', 'theme', 'panel'), 2, 'st:ThemeInset thick')
		eq(st:ThemeInset('thin', 'theme', 'panel'), 1, 'st:ThemeInset thin')
		eq(st:ThemeInset('blizzard', 'theme', 'panel'), st.ThemeArt.Inset('panel'), 'st:ThemeInset blizzard')
		st.config.profile.theme.name = 'blizzard'
		st:RedrawThemed()
		local small = owner_of(st, 'template', 'small')
		check(rawequal(small.backdropInfo.edgeSize, 1), "small's line 1")
		local lines = {}
		for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
			lines[theme] = st:ResolveTheme(theme, 'theme', 'panel').lines
		end
		eq(lines.thick, 2, 'look.lines thick')
		eq(lines.thin, 1, 'look.lines thin')
		eq(lines.blizzard, nil, 'look.lines is nil under Blizzard')
	end
end)

test("k 1: st.BACKDROP and the close button: edge 1, insets 1, the dark line 1 outside it", function()
	local st = world('forever', 'thick')
	check(rawequal(st.BACKDROP.edgeSize, 1), 'BACKDROP edge')
	for _, side in ipairs({ 'left', 'right', 'top', 'bottom' }) do
		check(rawequal(st.BACKDROP.insets[side], 1), 'BACKDROP inset ' .. side)
	end
	local panel = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(panel)
	check(rawequal(close.backdropInfo.edgeSize, 1), "close button's edge 1")
	check(rawequal(close.backdropInfo.insets.left, 1), "close button's inset 1")
	check(rawequal(close.outline.backdropInfo.edgeSize, 1), "the dark line is 1")
	local at = pts(close.outline)
	check(rawequal(at.TOPLEFT.x, -1) and rawequal(at.TOPLEFT.y, 1), 'the dark line 1 outside: TOPLEFT')
	check(rawequal(at.BOTTOMRIGHT.x, 1) and rawequal(at.BOTTOMRIGHT.y, -1), 'the dark line 1 outside: BOTTOMRIGHT')
	stub.fire_script(close, 'OnMouseDown')
	check(rawequal(pts(close.icon).CENTER.y, -1), 'the pressed cross sits 1 down')
	stub.fire_script(close, 'OnMouseUp')
	check(rawequal(pts(close.icon).CENTER.y, 0), 'and back')
end)

------------------------------------------------------------------ k = 0.75, 1.25, 1.55

test("k 0.75, 1.25 and 1.55: one-line edges, insets in lines, the strips one line out and three wide, placement in the owner's lines", function()
	for _, k in ipairs(KS) do
		for _, client in ipairs({ 'forever', 'retail' }) do
			local st = world(client)
			use_scale(k)
			local line = st.line
			-- The screens are 1920 x 1080, 3200 x 1800 and 3456 x 2234: 1.55 is 1.5514 there.
			local real = 1 / st.pixel
			check(close_to(line, st.lineWeight / real, 1e-9), ('k %s: the line is lineWeight pixels'):format(k))
			if k == 1.55 then
				eq(st.lineWeight, 2, 'a line is 2 pixels at 1.55')
				check(close_to(line, 2 * st.pixel, 1e-12), 'line == 2 * st.pixel')
			end
			for _, theme in ipairs({ 'thick', 'thin' }) do
				st.config.profile.theme.name = theme
				local lines = theme == 'thick' and 2 or 1
				for _, kind in ipairs(sorted_kinds(st)) do
					local label = ('k %s %s %s %s'):format(k, client, theme, kind)
					local owner = owner_of(st, 'backdrop', kind)
					local bd = owner.backdrop
					local ownLine = st:GetLineSize(bd)
					local strip = kind == 'header' or kind == 'close'
					check(close_to(bd.backdropInfo.edgeSize, ownLine, 1e-9), label .. ': the edge is one line: ' .. tostring(bd.backdropInfo.edgeSize))
					check(close_to(bd.backdropInfo.edgeSize, line, 1e-9), label .. ': and the token line')
					local want = strip and 0 or lines * ownLine
					for _, side in ipairs({ 'left', 'right', 'top', 'bottom' }) do
						check(close_to(bd.backdropInfo.insets[side], want, 1e-9), label .. ': inset ' .. side)
					end
					check(close_to(st:DrawnInset(owner), lines * ownLine, 1e-9), label .. ': recorded inset')
					check(whole_px(st, st:DrawnInset(owner), bd), label .. ': the recorded inset is whole pixels')
					check(close_to(st:ThemeInset(theme, 'theme', kind), lines * line, 1e-9), label .. ': ThemeInset')
					local look = st:ResolveTheme(theme, 'theme', kind)
					eq(look.lines, lines, label .. ': look.lines')
					check(close_to(look.inset, lines * line, 1e-9), label .. ': look.inset')

					local at = pts(bd)
					local outside = lines * st:GetLineSize(owner)
					check(close_to(at.TOPLEFT.x, -outside, 1e-9) and close_to(at.TOPLEFT.y, outside, 1e-9), label .. ': placed lines outside, top')
					check(close_to(at.BOTTOMRIGHT.x, outside, 1e-9) and close_to(at.BOTTOMRIGHT.y, -outside, 1e-9), label .. ': placed lines outside, bottom')

					if theme == 'thick' and not strip then
						local left, right = pts(bd.altborder.LEFT), pts(bd.altborder.RIGHT)
						check(close_to(left.TOPLEFT.x, -ownLine, 1e-9) and close_to(left.TOPLEFT.y, ownLine, 1e-9), label .. ': LEFT strip one line out')
						check(close_to(left.BOTTOMLEFT.x, -ownLine, 1e-9) and close_to(left.BOTTOMLEFT.y, -ownLine, 1e-9), label .. ': LEFT strip bottom')
						check(close_to(right.TOPRIGHT.x, ownLine, 1e-9) and close_to(right.BOTTOMRIGHT.y, -ownLine, 1e-9), label .. ': RIGHT strip')
						check(close_to(bd.altborder.LEFT:GetWidth(), 3 * ownLine, 1e-9), label .. ': LEFT 3 lines wide')
						check(close_to(bd.altborder.RIGHT:GetWidth(), 3 * ownLine, 1e-9), label .. ': RIGHT 3 lines wide')
						check(close_to(bd.altborder.TOP:GetHeight(), 3 * ownLine, 1e-9), label .. ': TOP 3 lines tall')
						check(close_to(bd.altborder.BOTTOM:GetHeight(), 3 * ownLine, 1e-9), label .. ': BOTTOM 3 lines tall')
						local top, bottom = pts(bd.altborder.TOP), pts(bd.altborder.BOTTOM)
						check(close_to(top.TOPLEFT.x, ownLine, 1e-9) and close_to(top.TOPLEFT.y, ownLine, 1e-9), label .. ': TOP strip')
						check(close_to(bottom.BOTTOMLEFT.x, ownLine, 1e-9) and close_to(bottom.BOTTOMLEFT.y, -ownLine, 1e-9), label .. ': BOTTOM strip')
						if k == 1.55 then
							check(close_to(3 * bd.backdropInfo.edgeSize * real, 6, 1e-9), label .. ': Thick is 6 pixels at 1.55')
						end
					end
				end
			end
		end
	end
end)

test("Blizzard's kinds: each inset a whole number of pixels at every k, small's one line", function()
	for _, k in ipairs({ 0.75, 1, 1.25, 1.55 }) do
		local st = world('forever', 'blizzard')
		use_scale(k)
		local real = 1 / st.pixel
		for _, kind in ipairs(sorted_kinds(st)) do
			local label = ('k %s %s'):format(k, kind)
			local n, top = st.ThemeArt.Inset(kind), st.ThemeArt.Top(kind)
			-- The pixel count as the line weight counts: k trimmed to 1e-4, so a half pixel a float short still rounds up.
			local function px(v) return v == 0 and 0 or math.max(1, math.floor(math.floor(v * real * 10000 + 0.5) / 10000 + 0.5)) end
			local owner = owner_of(st, 'backdrop', kind)
			local bd = owner.backdrop
			check(close_to(st:DrawnInset(owner), px(n) * st.pixel, 1e-9), label .. ': recorded inset ' .. tostring(st:DrawnInset(owner)))
			check(whole_px(st, st:DrawnInset(owner), bd), label .. ': whole pixels')
			local look = st:ResolveTheme('theme', 'theme', kind)
			eq(look.lines, nil, label .. ': no lines')
			check(close_to(look.inset, px(n) * st.pixel, 1e-9), label .. ': look.inset')
			local at = pts(bd)
			check(close_to(at.TOPLEFT.x, -px(n) * st:GetPixelSize(owner), 1e-9), label .. ': placed on the side')
			check(close_to(at.TOPLEFT.y, px(top) * st:GetPixelSize(owner), 1e-9), label .. ': top in whole pixels')
			check(close_to(at.BOTTOMRIGHT.y, -px(n) * st:GetPixelSize(owner), 1e-9), label .. ': bottom')
			if bd.backdropInfo then
				check(close_to(bd.backdropInfo.insets.left, px(n) * st.pixel, 1e-9), label .. ': backdrop inset')
				check(close_to(bd.backdropInfo.insets.top, px(top) * st.pixel, 1e-9), label .. ': backdrop top inset')
				if bd.backdropInfo.edgeFile then
					check(close_to(bd.backdropInfo.edgeSize, st:GetLineSize(bd), 1e-9), label .. ': a line is one line')
				end
			end
			if kind == 'small' then
				check(close_to(st:DrawnInset(owner), st.line, 1e-9), "small's inset is its one line")
			end
		end
	end
end)

test('a frame with a scale of its own draws in its own lines, and records its inset in its own units', function()
	local st = world('forever', 'thick')
	local owner = st:CreateFrame('Frame', nil, UIParent)
	owner:SetSize(40, 40)
	owner:SetPoint('CENTER')
	owner:SetScale(0.8)
	st:SetTemplate(owner, 'theme', 'theme', 'panel')
	local want = st.lineWeight * st:GetPixelSize(owner)
	check(close_to(want, 1.25, 1e-9), 'a pixel is 1.25 of its units')
	check(close_to(owner.backdropInfo.edgeSize, want, 1e-9), 'edge: ' .. tostring(owner.backdropInfo.edgeSize))
	check(close_to(owner.backdropInfo.insets.left, 2 * want, 1e-9), 'insets two lines')
	check(close_to(st:DrawnInset(owner), 2 * want, 1e-9), 'recorded in its own units')
	check(close_to(owner.altborder.LEFT:GetWidth(), 3 * want, 1e-9), 'strips in its own lines')
	check(close_to(pts(owner.altborder.LEFT).TOPLEFT.x, -want, 1e-9), 'one line out')

	-- A backdrop behind it is placed in the owner's lines.
	local with = st:CreateFrame('Frame', nil, UIParent)
	with:SetSize(40, 40)
	with:SetPoint('CENTER')
	with:SetScale(0.8)
	st:SetBackdrop(with, 'theme', 'theme', 'panel')
	check(close_to(pts(with.backdrop).TOPLEFT.x, -2 * want, 1e-9), 'placed two of its lines out')

	-- Blizzard: the art inset in whole pixels of the frame (3 units is 2.4 pixels here: 2).
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	check(close_to(st:DrawnInset(with), 2 * 1.25, 1e-9), 'Blizzard: whole pixels of its own')
	check(whole_px(st, st:DrawnInset(with), with), 'whole in its own pixels')
end)

test('a redraw after a scale change draws every frame at the new line weight; a backdrop its caller placed stays put', function()
	local st = world('forever', 'thick')
	local a = owner_of(st, 'backdrop', 'panel')
	local b = owner_of(st, 'backdrop', 'panel')
	local c = owner_of(st, 'template', 'panel')
	-- b's backdrop is its caller's from here on.
	b.backdrop:ClearAllPoints()
	b.backdrop:SetPoint('TOPLEFT', b, 'TOPLEFT', -7, 7)
	b.backdrop:SetPoint('BOTTOMRIGHT', b, 'BOTTOMRIGHT', 7, -7)
	check(rawequal(a.backdrop.backdropInfo.edgeSize, 1), 'drawn at k 1')

	use_scale(1.55)
	local line = st.line
	st:RedrawThemed()
	for _, f in ipairs({ a.backdrop, b.backdrop, c }) do
		check(close_to(f.backdropInfo.edgeSize, line, 1e-9), 'edge is the new line')
		check(close_to(f.backdropInfo.insets.left, 2 * line, 1e-9), 'insets are the new two lines')
		check(close_to(f.altborder.LEFT:GetWidth(), 3 * line, 1e-9), 'strips 3 new lines')
		check(close_to(pts(f.altborder.LEFT).TOPLEFT.x, -line, 1e-9), 'strips one new line out')
	end
	check(close_to(pts(a.backdrop).TOPLEFT.x, -2 * line, 1e-9), "the engine's backdrop moved to the new lines")
	eq(pts(b.backdrop).TOPLEFT.x, -7, "the caller's backdrop stays where the caller put it")
	eq(pts(b.backdrop).BOTTOMRIGHT.y, -7, 'and its other corner')
	check(close_to(st:DrawnInset(a), 2 * line, 1e-9), 'the record follows')
	check(close_to(st:DrawnInset(c), 2 * line, 1e-9), 'on a frame drawn on itself too')

	-- And back.
	use_scale(1)
	st:RedrawThemed()
	check(rawequal(a.backdrop.backdropInfo.edgeSize, 1), 'back at k 1 the edge is 1')
	check(rawequal(pts(a.backdrop).TOPLEFT.x, -2), 'and the placement 2')
	check(rawequal(pts(a.backdrop.altborder.LEFT).TOPLEFT.x, -1), 'strips one out again')
end)

------------------------------------------------------------------ whole pixels (every scale)

local NOISE = { 2 ^ -14, -2 ^ -14, 0 }

scaled_test('every kind drawn on a whole-pixel owner has its edges, strips and backdrop on whole pixels', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, noise in ipairs(NOISE) do
			for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
				local st = world(client, theme)
				stub.size_noise = noise
				local size = st:RoundToPixel(36, UIParent)
				local x = st:RoundToPixel(120, UIParent)
				for _, kind in ipairs(sorted_kinds(st)) do
					for _, how in ipairs({ 'template', 'backdrop' }) do
						local owner = st:CreateFrame('Frame', nil, UIParent)
						owner:SetSize(size, size)
						owner:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', x, x)
						if how == 'template' then
							st:SetTemplate(owner, 'theme', 'theme', kind)
						else
							st:SetBackdrop(owner, 'theme', 'theme', kind)
						end
						-- Blizzard's art is drawn at the art's own size (call 21), not on pixels:
						-- the engine's lines, strips and backdrop are what is measured.
						local art = st.ThemeArt.Get(owner.backdrop or owner)
						if art then
							for _, set in ipairs({ art.pieces, art.over }) do
								for _, piece in pairs(set) do piece:Hide() end
							end
						end
						local off = P.off(owner)
						eq(#off, 0, ('%s %s %s %s noise %s at %s: %s'):format(client, theme, how, kind, noise, test_scale(), P.report(off)))
						owner:Hide()
					end
				end
				stub.size_noise = 0
			end
		end
	end
end)

------------------------------------------------------------------ the close button

test('the close button: its edge and dark line one line, its pressed cross one line down, back from Blizzard too', function()
	for _, k in ipairs(KS) do
		local st = world('forever', 'thick')
		use_scale(k)
		local panel = st:CreateFrame('Frame', nil, UIParent)
		panel:SetSize(200, 100)
		panel:SetPoint('CENTER')
		local close = st:CreateCloseButton(panel)
		local line = st:GetLineSize(close)
		local label = 'k ' .. k
		check(close_to(close.backdropInfo.edgeSize, line, 1e-9), label .. ': edge one line')
		check(close_to(close.backdropInfo.insets.top, line, 1e-9), label .. ': inset one line')
		check(close_to(close.outline.backdropInfo.edgeSize, line, 1e-9), label .. ': dark line one line')
		local at = pts(close.outline)
		check(close_to(at.TOPLEFT.x, -line, 1e-9) and close_to(at.TOPLEFT.y, line, 1e-9), label .. ': dark line one line outside')
		check(close_to(at.BOTTOMRIGHT.x, line, 1e-9) and close_to(at.BOTTOMRIGHT.y, -line, 1e-9), label .. ': and the other corner')
		stub.fire_script(close, 'OnMouseDown')
		check(close_to(pts(close.icon).CENTER.y, -line, 1e-9), label .. ': the pressed cross one line down')
		stub.fire_script(close, 'OnMouseUp')
		eq(pts(close.icon).CENTER.y, 0, label .. ': back up')

		-- Blizzard, then back at another scale: the line is taken again on the draw.
		st.config.profile.theme.name = 'blizzard'
		st:RedrawThemed()
		eq(close.backdropInfo, nil, label .. ': no backdrop under Blizzard')
		use_scale(k == 1.55 and 0.75 or 1.55)
		st.config.profile.theme.name = 'thick'
		st:RedrawThemed()
		local line2 = st:GetLineSize(close)
		check(not close_to(line2, line, 1e-6), label .. ': the scale did change')
		check(close_to(close.backdropInfo.edgeSize, line2, 1e-9), label .. ': back from Blizzard at the new line')
		check(close_to(close.outline.backdropInfo.edgeSize, line2, 1e-9), label .. ': and its dark line')
		check(close_to(pts(close.outline).TOPLEFT.x, -line2, 1e-9), label .. ': and the dark line placed')
	end
end)

test('the close button takes the line on every draw, and sets its backdrop again only when the line changed', function()
	local st = world('forever', 'thick')
	local panel = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(panel)
	local sets, outlineSets = 0, 0
	local real, realOutline = close.SetBackdrop, close.outline.SetBackdrop
	close.SetBackdrop = function(...) sets = sets + 1; return real(...) end
	close.outline.SetBackdrop = function(...) outlineSets = outlineSets + 1; return realOutline(...) end
	st:RecolorThemed()
	st:RecolorThemed()
	st:RedrawThemed()
	eq(sets, 0, 'no backdrop set while the line is the same')
	eq(outlineSets, 0, 'nor the dark line')
	use_scale(1.55)
	st:RecolorThemed()
	eq(sets, 1, 'a draw at a new line sets it once')
	eq(outlineSets, 1, 'and the dark line')
	st:RecolorThemed()
	eq(sets, 1, 'and no more')
	check(close_to(close.backdropInfo.edgeSize, st.line, 1e-9), 'the edge is the new line')
end)

test('st.BACKDROP takes one line on every SetTokens', function()
	for _, k in ipairs({ 0.75, 1.25, 1.55, 1 }) do
		local st = world('forever')
		use_scale(k)
		check(close_to(st.BACKDROP.edgeSize, st.line, 1e-9), ('k %s: edge %s'):format(k, tostring(st.BACKDROP.edgeSize)))
		for _, side in ipairs({ 'left', 'right', 'top', 'bottom' }) do
			check(close_to(st.BACKDROP.insets[side], st.line, 1e-9), ('k %s: inset %s'):format(k, side))
		end
		st.BACKDROP.edgeSize = 99
		st.UIScale:SetTokens()
		check(close_to(st.BACKDROP.edgeSize, st.line, 1e-9), 'SetTokens sets it again')
	end
end)

------------------------------------------------------------------ SnapDrawn

local function rounded(region) return stub.state(region).round_layout end
local function snapped(region) return stub.state(region).snap_to_pixel_grid end

local function bias(region) return stub.state(region).texel_snapping_bias end

test("SnapDrawn is 'unsnap' as shipped: the engine's border textures stop snapping, nothing is rounded", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = world(client, 'thick')
		eq(st.SNAP_DRAWN, 'unsnap', 'shipped as unsnap')
		local owner = owner_of(st, 'backdrop', 'panel')
		local bd = owner.backdrop
		check(not rounded(bd), 'the drawn frame is not rounded')
		for key, line in pairs(bd.altborder) do
			check(not rounded(line), 'a strip is not rounded')
			eq(snapped(line), false, client .. ': strip ' .. key .. ' has texture snapping off')
			eq(bias(line), 0, 'and a texel bias of 0')
			eq(line:IsSnappingToPixelGrid(), false, 'as the game reports it')
		end
		-- A redraw (a scale change) does it again; a color pass is not needed for it.
		local fresh = owner_of(st, 'template', 'panel')
		for _, line in pairs(fresh.altborder) do eq(snapped(line), false, 'a frame drawn on itself too') end
		-- The own-color piece, made once by a border color, is unsnapped too.
		st.config.profile.theme.name = 'blizzard'
		st:RedrawThemed()
		local slot = owner_of(st, 'backdrop', 'slot')
		st:SetBorderColor(slot.backdrop, 1, 0, 0, 1)
		local own = st.ThemeArt.Get(slot.backdrop).own
		eq(snapped(own), false, client .. ': the own-color piece does not snap')
		eq(bias(own), 0, 'bias 0')
		-- Blizzard's own art pieces are the art's: left as they were laid.
		for key, piece in pairs(st.ThemeArt.Get(bd).pieces) do
			eq(bias(piece) == 0 and snapped(piece) == false, false, 'art piece ' .. key .. ' is left to the art')
		end
	end
end)

test('the stubs know the texture snapping calls: defaults on and 0.3', function()
	local st = world('forever')
	local t = UIParent:CreateTexture()
	eq(t:IsSnappingToPixelGrid(), true, 'snapping on')
	check(near(t:GetTexelSnappingBias(), 0.3), 'bias 0.3')
	t:SetSnapToPixelGrid(false)
	t:SetTexelSnappingBias(0)
	eq(t:IsSnappingToPixelGrid(), false, 'off')
	eq(t:GetTexelSnappingBias(), 0, 'bias 0')
end)

test("SnapDrawn 'none': nothing is rounded or unsnapped", function()
	local st = world('forever', 'thick')
	st.SNAP_DRAWN = 'none'
	local owner = owner_of(st, 'backdrop', 'panel')
	local bd = owner.backdrop
	check(not rounded(bd), 'the drawn frame is not rounded')
	for _, line in pairs(bd.altborder) do
		check(not rounded(line), 'nor a strip')
		eq(snapped(line), nil, 'texture snapping untouched')
	end
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	for _, piece in pairs(st.ThemeArt.Get(bd).pieces) do check(not rounded(piece), 'nor a piece of art') end
end)

test("SnapDrawn 'round': the drawn frame and its own regions round their layout; texture snapping is left as it was", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = world(client, 'thick')
		-- Texture snapping as it is without SnapDrawn.
		st.SNAP_DRAWN = 'none'
		local before = owner_of(st, 'backdrop', 'panel')
		local snapBefore = {}
		for key, line in pairs(before.backdrop.altborder) do snapBefore[key] = snapped(line) end

		st.SNAP_DRAWN = 'round'
		local owner = owner_of(st, 'backdrop', 'panel')
		local bd = owner.backdrop
		eq(rounded(bd), true, client .. ': the drawn frame rounds')
		for key, line in pairs(bd.altborder) do
			eq(rounded(line), true, client .. ': strip ' .. key .. ' rounds')
			eq(snapped(line), snapBefore[key], client .. ': and texture snapping is as it was')
		end
		local alone = owner_of(st, 'template', 'panel')
		eq(rounded(alone), true, client .. ': a frame drawn on itself too')

		st.config.profile.theme.name = 'blizzard'
		st:RedrawThemed()
		local art = st.ThemeArt.Get(bd)
		local n = 0
		for key, piece in pairs(art.pieces) do
			n = n + 1
			eq(rounded(piece), true, client .. ': art piece ' .. key .. ' rounds')
		end
		check(n > 0, 'the panel has art')
		eq(rounded(bd), true, 'the drawn frame still rounds under Blizzard')

		-- A button's own-color piece, made once by a border color, rounds too.
		local slot = owner_of(st, 'backdrop', 'slot')
		st:SetBorderColor(slot.backdrop, 1, 0, 0, 1)
		local own = st.ThemeArt.Get(slot.backdrop).own
		check(own ~= nil, 'the own-color piece exists')
		eq(rounded(own), true, client .. ': and it rounds')
	end
end)

test("SnapDrawn: switching the value changes the next draws only", function()
	local st = world('forever', 'thick')
	st.SNAP_DRAWN = 'round'
	local first = owner_of(st, 'backdrop', 'panel')
	eq(rounded(first.backdrop), true, 'round rounds')
	st.SNAP_DRAWN = 'none'
	local second = owner_of(st, 'backdrop', 'panel')
	check(not rounded(second.backdrop), 'none rounds nothing')
	for _, line in pairs(second.backdrop.altborder) do check(not rounded(line), 'not a strip') end
	st.SNAP_DRAWN = 'whatever'
	local third = owner_of(st, 'backdrop', 'panel')
	check(not rounded(third.backdrop), 'a value that is not round is none')
end)

test('SnapDrawn leaves a protected frame alone in combat, and does it after (Review Focus 2)', function()
	local st = world('forever', 'thick')
	local button = st:CreateFrame('Button', nil, UIParent, 'SecureActionButtonTemplate')
	button:SetSize(36, 36)
	button:SetPoint('CENTER')
	st:SetTemplate(button, 'theme', 'theme', 'action')
	check(button:IsProtected(), 'the button is protected')
	eq(rounded(button), nil, 'drawn out of combat under none: not rounded')

	st.SNAP_DRAWN = 'round'
	local calls = 0
	local real = button.SetRoundLayoutToNearestPixel
	button.SetRoundLayoutToNearestPixel = function(...) calls = calls + 1; return real(...) end
	stub.in_combat = true
	stub.blocked = {}
	st:RedrawThemed()
	st:RedrawThemed()
	eq(#stub.blocked, 0, 'nothing protected was called in combat')
	eq(calls, 0, 'the protected frame was not asked to round')
	eq(rounded(button), nil, 'and is not rounded')
	eq(#take_errors(), 0, 'no error')

	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(rounded(button), true, 'rounded when combat ends')
	eq(calls, 1, 'once')
	for _, line in pairs(button.altborder) do eq(rounded(line), true, 'and its strips') end
	eq(#stub.blocked, 0, 'still nothing blocked')
end)

test('a pooled frame (no parent) and a plate frame (under WorldFrame) are drawn in UIParent\'s lines, a frame with a scale of its own in its own', function()
	local st = world('forever', 'thick')
	use_scale(1.55)
	local line = st.line
	local pooled = st:CreateFrame('Frame', nil, UIParent)
	pooled:SetSize(40, 40)
	pooled:SetParent(nil)
	st:SetTemplate(pooled, 'theme', 'theme', 'panel')
	check(close_to(pooled.backdropInfo.edgeSize, line, 1e-9), 'pooled: UIParent line, not the 1.0 scale of a parentless frame')
	local plate = CreateFrame('Frame', nil, WorldFrame)
	local onPlate = st:CreateFrame('Frame', nil, plate)
	st:SetTemplate(onPlate, 'theme', 'theme', 'panel')
	check(close_to(onPlate.backdropInfo.edgeSize, line, 1e-9), 'plate: UIParent line')
	eq(st:DrawingFrame(pooled), UIParent, 'DrawingFrame of a pooled frame')
	local scaled = st:CreateFrame('Frame', nil, UIParent)
	scaled:SetScale(0.8)
	eq(st:DrawingFrame(scaled), scaled, 'a frame under UIParent is its own')
end)


------------------------------------------------------------------ Fix round 1

local PIECES = { 'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner',
	'TopEdge', 'BottomEdge', 'LeftEdge', 'RightEdge', 'Center' }

test('I1: the close button takes a new line in game: its backdrop is applied again, with a table of its own', function()
	-- Blizzard's SetBackdrop returns at once on the table the frame holds (the
	-- stub's does too), so a table changed in place would never be applied.
	local st = world('forever', 'thick')
	local panel = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(panel)
	local info = close.backdropInfo
	local applies = stub.state(close).backdrop_applies
	check(applies and applies >= 1, 'applied once when made')
	use_scale(1.55)
	st:RecolorThemed()
	check(close.backdropInfo ~= info, 'a new table')
	eq(stub.state(close).backdrop_applies, applies + 1, 'applied again, once')
	check(close_to(close.backdropInfo.edgeSize, st.line, 1e-9), 'at the new line')
	check(close_to(close.backdropInfo.insets.left, st.line, 1e-9), 'and its insets')
	st:RecolorThemed()
	eq(stub.state(close).backdrop_applies, applies + 1, 'and not again while the line is the same')
	-- Back from Blizzard at another scale.
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	use_scale(0.75)
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	check(close_to(close.backdropInfo.edgeSize, st.line, 1e-9), 'back from Blizzard at 0.75')
end)

test('I3: the backdrop\'s own pieces are unsnapped under \'unsnap\', and left alone under \'none\'', function()
	for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
		local st = world('forever', theme)
		stub.backdrop_pieces = true
		local owner = owner_of(st, 'backdrop', 'small')
		local bd = owner.backdrop
		for _, name in ipairs(PIECES) do
			local piece = bd[name]
			check(piece ~= nil, theme .. ': the stub makes ' .. name)
			if piece then
				eq(snapped(piece), false, theme .. ': ' .. name .. ' does not snap')
				eq(bias(piece), 0, theme .. ': ' .. name .. ' has a bias of 0')
			end
		end
		st.SNAP_DRAWN = 'none'
		local second = owner_of(st, 'backdrop', 'small')
		for _, name in ipairs(PIECES) do
			if second.backdrop[name] then eq(snapped(second.backdrop[name]), nil, theme .. ' none: ' .. name .. ' as the game has it') end
		end
	end
	-- m3: the close button's lines and the loading overlay's table are SaftUI's own textures too.
	local st = world('forever', 'thick')
	stub.backdrop_pieces = true
	local panel = st:CreateFrame('Frame', nil, UIParent)
	local close = st:CreateCloseButton(panel)
	for _, name in ipairs(PIECES) do
		if close[name] then eq(snapped(close[name]), false, 'close ' .. name) end
		if close.outline[name] then eq(snapped(close.outline[name]), false, 'outline ' .. name) end
	end
	check(close.TopEdge ~= nil and close.outline.TopEdge ~= nil, 'the close button has pieces')
	stub.backdrop_pieces = nil
end)

test('a texture is unsnapped once, not on every draw', function()
	local st = world('forever', 'thick')
	local owner = owner_of(st, 'backdrop', 'panel')
	local calls = 0
	for _, strip in pairs(owner.backdrop.altborder) do
		local real = strip.SetSnapToPixelGrid
		strip.SetSnapToPixelGrid = function(...) calls = calls + 1; return real(...) end
	end
	st:RedrawThemed()
	st:RedrawThemed()
	eq(calls, 0, 'redraws do not unsnap again')
end)

-- Every method call of a frame and a texture, and the backdrop's, counted over fn.
local function count_calls(fn)
	local n, restore, seen = 0, {}, {}
	local function wrap(methods)
		if seen[methods] then return end
		seen[methods] = true
		for name, f in pairs(methods) do
			if type(f) == 'function' then
				restore[#restore + 1] = { methods, name, f }
				methods[name] = function(...) n = n + 1; return f(...) end
			end
		end
	end
	for _, w in ipairs({ CreateFrame('Frame'), CreateFrame('Button'), UIParent:CreateTexture(nil, 'ARTWORK') }) do
		local m = getmetatable(w).__index
		if type(m) == 'table' then wrap(m) end
	end
	wrap(stub.backdrop)
	fn()
	for _, r in ipairs(restore) do r[1][r[2]] = r[3] end
	return n
end

local COST_KINDS = { 'action', 'aura', 'bar', 'close', 'control', 'header', 'member', 'panel', 'slot', 'small', 'tooltip', 'unitframe', 'window' }

test("m1: a recolor costs what it did before the scale work, and a redraw a little over what it did, not 2.6 times", function()
	-- Base (8a4ad66f), 26 frames (13 kinds drawn on themselves and with a backdrop):
	-- recolor 140 / 52 / 118 and redraw 361 / 273 / 1201 widget calls under Thick / Thin / Blizzard.
	local base = { thick = { 140, 361 }, thin = { 52, 273 }, blizzard = { 118, 1201 } }
	-- What a redraw may make now: the chain and scale read once a draw, each texture unsnapped once.
	-- Blizzard: 1363 before the action art's cut, 1365 with it (two SetTexCoord calls on an action
	-- frame's ring), the 7 calls of margin it had. 1577 with the box (round 3) on panel, bar,
	-- tooltip and unitframe: each of those 8 frames cuts its pieces (a texture, coordinates and a
	-- size each, where the tooltip border set an atlas) and places, levels and shows its box frame;
	-- the same 7 of margin.
	local most = { thick = 500, thin = 410, blizzard = 1584 }
	for _, theme in ipairs({ 'thick', 'thin', 'blizzard' }) do
		local st = world('forever', theme)
		for _, kind in ipairs(COST_KINDS) do
			owner_of(st, 'template', kind)
			owner_of(st, 'backdrop', kind)
		end
		local recolor = count_calls(function() st:RecolorThemed() end)
		local redraw = count_calls(function() st:RedrawThemed() end)
		eq(recolor, base[theme][1], theme .. ': a recolor makes the calls it made before')
		check(redraw <= most[theme], ('%s: a redraw makes %d calls, base %d, at most %d'):format(theme, redraw, base[theme][2], most[theme]))
		print(('  %s: recolor %d, redraw %d'):format(theme, recolor, redraw))
	end
end)

test('M9: a protected frame in combat keeps the strips it has after a scale change, and lays them when combat ends', function()
	local st = world('forever', 'thick')
	local button = st:CreateFrame('Button', nil, UIParent, 'SecureActionButtonTemplate')
	button:SetSize(36, 36)
	button:SetPoint('CENTER')
	st:SetTemplate(button, 'theme', 'theme', 'action')
	use_scale(1.55)
	stub.in_combat = true
	stub.blocked = {}
	st:RedrawThemed()
	eq(#stub.blocked, 0, 'nothing protected was called in combat')
	eq(button.altborder.LEFT:GetWidth(), 3, 'the strips keep the old line')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	st:RedrawThemed()
	check(close_to(button.altborder.LEFT:GetWidth(), 3 * st.line, 1e-9), 'laid at the new line by the next draw')
end)

test("M12: a frame drawn on itself under Blizzard takes the record's inset on a redraw after a scale change", function()
	local st = world('forever', 'blizzard')
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36)
	f:SetPoint('CENTER')
	st:SetTemplate(f, 'theme', 'theme', 'panel')
	use_scale(1.55)
	st:RedrawThemed()
	local want = math.floor(3 * (1 / st.pixel) + 0.5) * st.pixel
	check(close_to(st:DrawnInset(f), want, 1e-9), 'the record: 5 pixels, ' .. tostring(st:DrawnInset(f)))
	check(close_to(f.backdropInfo.insets.left, want, 1e-9), 'and the backdrop drawn with it')
end)

test("M23: a Blizzard backdrop on a frame with a scale of its own is inset in its own whole pixels", function()
	local st = world('forever', 'blizzard')
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36)
	f:SetPoint('CENTER')
	f:SetScale(0.8)
	st:SetTemplate(f, 'theme', 'theme', 'panel')
	-- 3 units is 2.4 of its pixels (1.25 units each): 2 pixels, 2.5 units.
	check(close_to(f.backdropInfo.insets.left, 2.5, 1e-9), 'inset ' .. tostring(f.backdropInfo.insets.left))
	check(close_to(f.backdropInfo.insets.top, 2.5, 1e-9), 'top ' .. tostring(f.backdropInfo.insets.top))
	eq(f.backdropInfo.insets.left, st:DrawnInset(f), 'from the record')

	-- r7 (Task 3's re-review, mutant F7): a `small` frame's line is a line of the
	-- frame's own pixels, 1.25 units at this scale, not UIParent's line (1 unit).
	local small = st:CreateFrame('Frame', nil, UIParent)
	small:SetSize(36, 36)
	small:SetPoint('CENTER')
	small:SetScale(0.8)
	st:SetTemplate(small, 'theme', 'theme', 'small')
	check(close_to(small.backdropInfo.edgeSize, st:GetLineSize(small), 1e-9), 'small: the edge is the frame\'s own line ' .. tostring(small.backdropInfo.edgeSize))
	check(close_to(small.backdropInfo.edgeSize, 1.25, 1e-9), 'which is 1.25 units, not UIParent\'s ' .. tostring(st.line))
	check(close_to(small.backdropInfo.insets.left, st:GetLineSize(small), 1e-9), 'and its inset is that line')
end)

test("M19: a length is at least one pixel on a frame so small a scale that it would round to none", function()
	local st = world('forever', 'blizzard')
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetScale(0.3)
	-- One unit is 0.3 of a pixel: it rounds to 0, and is one pixel (3.33 units).
	check(close_to(st.ThemeArt.Whole(1, f), 1 / 0.3, 1e-9), 'one unit is one pixel')
	eq(st.ThemeArt.Whole(0, f), 0, 'nothing stays nothing')
	f:SetSize(36, 36)
	f:SetPoint('CENTER')
	st:SetTemplate(f, 'theme', 'theme', 'small')
	check(f.backdropInfo.insets.left > 0, 'small keeps its line')
end)

test("M7: a secret UI scale draws at the token line and the art's own inset, and says nothing", function()
	local st = world('forever', 'thick')
	local restore = SECRETS.install()
	local real = UIParent.GetEffectiveScale
	UIParent.GetEffectiveScale = function() return SECRETS.secret('UI scale') end
	local ok, err = pcall(function()
		local owner = owner_of(st, 'backdrop', 'panel')
		check(close_to(owner.backdrop.backdropInfo.edgeSize, st.line, 1e-9), 'Thick: the token line')
		st.config.profile.theme.name = 'blizzard'
		st:RedrawThemed()
		eq(st:DrawnInset(owner), st.ThemeArt.Inset('panel'), 'Blizzard: the art inset, unrounded')
		st.config.profile.theme.name = 'thin'
		st:RedrawThemed()
		check(close_to(owner.backdrop.backdropInfo.edgeSize, st.line, 1e-9), 'Thin after a redraw')
	end)
	UIParent.GetEffectiveScale = real
	restore()
	check(ok, tostring(err))
	eq(#take_errors(), 0, 'no error was reported')
end)

test("I2: st:ThemeInset with a frame is its inset in that frame's whole pixels, without one UIParent's", function()
	local st = world('forever', 'thick')
	local f = st:CreateFrame('Frame', nil, UIParent)
	for _, scale in ipairs({ 0.8, 1.25, 1.5 }) do
		f:SetScale(scale)
		local pixel = st:GetPixelSize(f)
		check(close_to(st:ThemeInset('thick', 'theme', 'action', f), 2 * pixel, 1e-9), ('Thick at %s: two of its pixels'):format(scale))
		check(close_to(st:ThemeInset('thin', 'theme', 'action', f), pixel, 1e-9), 'Thin one')
		check(close_to(st:ThemeInset('blizzard', 'theme', 'action', f), math.max(1, math.floor(math.floor(3 / pixel * 10000 + 0.5) / 10000 + 0.5)) * pixel, 1e-6), 'Blizzard whole pixels of it')
		eq(st:ThemeInset('thick', 'theme', 'action'), 2, 'and without a frame UIParent\'s, 2')
	end
	eq(st:ThemeInset('none', 'theme', nil, f), 0, 'None is 0')
end)

test("n5: the title bar's top is whole pixels at other scales and the base number at k 1", function()
	local st = world('forever', 'blizzard')
	local owner = owner_of(st, 'backdrop', 'window')
	eq(pts(owner.backdrop).TOPLEFT.y, st.ThemeArt.Top('window'), 'k 1: the art\'s own top')
	use_scale(0.75)
	st:RedrawThemed()
	local y = pts(owner.backdrop).TOPLEFT.y
	check(whole_px(st, y, owner), 'whole pixels at 0.75: ' .. tostring(y))
end)
