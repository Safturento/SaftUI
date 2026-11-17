-- SaftUI-Core/Media/states.lua (st.States): the derivation of every interaction
-- state from the Accent, in OKLCH, checked against the spec's worked values
-- (docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md,
-- section 2, "Worked values"): each byte within 1 of the table's. Also the
-- settings' clamps, the cache (one computation per change, nothing made), the
-- fade texture and migration step 7's neighbor in color_migration_test.lua.
load_core_helpers()
local st = SaftUI
local ST = st.States

local function hex(r, g, b)
	return ('%02x%02x%02x'):format(math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function bytes(h)
	return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

local function within(label, got, want)
	local g1, g2, g3 = bytes(got)
	local w1, w2, w3 = bytes(want)
	check(math.abs(g1 - w1) <= 1 and math.abs(g2 - w2) <= 1 and math.abs(g3 - w3) <= 1, label .. ': ' .. got .. ' ~ ' .. want)
end

local function rgb(h) -- 'rrggbb' as 0..1 channels
	local r, g, b = bytes(h)
	return r / 255, g / 255, b / 255
end

local function deg(rad) return (rad * 180 / math.pi) % 360 end

-- The three presets of the spec's tables.
local BLUE, VIOLET, GOLD = '00adf0', '8a5cf5', 'e6c84a'

local function settings(mode, over)
	local s = { mode = mode, hover = 0.16, pushed = 0.32, selected = 0.24, fade = 0.70, disabled = 0.40,
		step = 0.08, shift = 20, chroma = 0.10, direction = 'warm' }
	for k, v in pairs(over or {}) do s[k] = v end
	return s
end

local TONES, HUE, COOL, LAYERS = settings('tones'), settings('hue'), settings('hue', { direction = 'cool' }), settings('layers')

local function tone(accent, k, s)
	local r, g, b = rgb(accent)
	return hex(ST.Tone(r, g, b, k, s))
end

local function derive(accent, s)
	local r, g, b = rgb(accent)
	return ST.Derive(r, g, b, s, ST.NewDerived())
end

test('OKLCH of the presets', function()
	local function oklch(h, L, C, H)
		local l, c, hh = ST.Oklch(rgb(h))
		check(math.abs(l - L) < 1e-4, h .. ' L ' .. l)
		check(math.abs(c - C) < 1e-4, h .. ' C ' .. c)
		check(math.abs(deg(hh) - H) < 0.01, h .. ' H ' .. deg(hh))
	end
	oklch(BLUE, 0.7061, 0.1505, 235.32)
	oklch(VIOLET, 0.6040, 0.2177, 292.50)
	oklch(GOLD, 0.8360, 0.1450, 95.58)
	for _, h in ipairs({ BLUE, VIOLET, GOLD, '000000', 'ffffff', '808080' }) do
		local r, g, b = rgb(h)
		local r2, g2, b2 = ST.Srgb(ST.Oklch(r, g, b))
		check(math.abs(r - r2) < 1e-6 and math.abs(g - g2) < 1e-6 and math.abs(b - b2) < 1e-6, 'round trip of ' .. h)
	end
end)

test('the test vectors: tones', function()
	local cells = {
		[BLUE] = { [-3] = '006189', [-2] = '007aaa', [-1] = '0093cd', [1] = '5cc6ff', [2] = 'a1dcff', [3] = 'dbf1ff' },
		[VIOLET] = { [-3] = '49009c', [-2] = '5e22be', [-1] = '7441d9', [1] = '9f7fff', [2] = 'b5a2ff', [3] = 'cdc2ff' },
		[GOLD] = { [-3] = '967d00', [-2] = 'b19500', [-1] = 'ccae28', [1] = 'ffe370', [2] = 'fffef9', [3] = 'ffffff' },
	}
	for accent, row in pairs(cells) do
		for k, want in pairs(row) do within(('#%s %+d'):format(accent, k), tone(accent, k, TONES), want) end
	end
	-- Layers: the Accent itself, both ways
	within('layers +1', tone(BLUE, 1, LAYERS), BLUE)
	within('layers -1', tone(BLUE, -1, LAYERS), BLUE)
end)

test('the test vectors: hue-shifted, warm and cool', function()
	local warm = {
		[BLUE] = { [-3] = '4c3fc2', [-2] = '5660d7', [-1] = '3888e9', [1] = '1ccef0', [2] = '5fecec', [3] = 'b5ffea' },
		[VIOLET] = { [-3] = '3700ac', [-2] = '490edd', [-1] = '5a44ed', [1] = 'c26eef', [2] = 'f184e2', [3] = 'ffb1d2' },
		[GOLD] = { [-3] = 'd7461d', [-2] = 'e27600', [-1] = 'e99f00', [1] = 'f7e579', [2] = 'fffef7', [3] = 'ffffff' },
	}
	for accent, row in pairs(warm) do
		for k, want in pairs(row) do within(('warm #%s %+d'):format(accent, k), tone(accent, k, HUE), want) end
	end
	local cool = {
		[BLUE] = { [-1] = '0098b2', [1] = '89bcff' },
		[VIOLET] = { [-1] = '9721c9', [1] = '878aff' },
		[GOLD] = { [-1] = 'c8b100', [1] = 'ffdeaf' },
	}
	for accent, row in pairs(cool) do
		for k, want in pairs(row) do within(('cool #%s %+d'):format(accent, k), tone(accent, k, COOL), want) end
	end
	-- The hue never passes its target: the warm +k hue lies between the start and 100 the short way.
	for _, accent in ipairs({ BLUE, VIOLET, GOLD }) do
		local _, _, h0 = ST.Oklch(rgb(accent))
		for k = 1, 6 do
			local r0, g0, b0 = rgb(accent)
			local L, C, h1 = ST.Oklch(ST.Tone(r0, g0, b0, k, HUE))
			if C > 0.02 and L < 0.97 then -- clamped to white or black the hue is noise
				local from, to, at = deg(h0), 100, deg(h1)
				local span = (to - from + 540) % 360 - 180 -- signed short way, start to target
				local walked = (at - from + 540) % 360 - 180
				check(walked * span >= -0.5 and math.abs(walked) <= math.abs(span) + 0.5,
					('#%s +%d: hue %.1f between %.1f and 100'):format(accent, k, at, from))
			end
		end
	end
end)

test('the gamut fit', function()
	for _, accent in ipairs({ BLUE, VIOLET, GOLD }) do
		check(ST.InGamut(ST.Oklch(rgb(accent))), accent .. ' is in gamut')
	end
	-- #00adf0 +1 before the fit is out of gamut, and after it C is near 0.1271.
	local L, C, H = ST.Oklch(rgb(BLUE))
	L = L + 0.08
	check(not ST.InGamut(L, C, H), '#00adf0 +1 is out before the fit')
	local fit = ST.FitChroma(L, C, H)
	check(math.abs(fit - 0.1271) < 0.0005, 'fitted C ' .. fit)
	check(ST.InGamut(L, fit, H), 'in gamut after')
	-- An in-gamut color keeps its C.
	local l, c, h = ST.Oklch(rgb(VIOLET))
	eq(ST.FitChroma(l, c, h), c)
end)

-- The composites at the defaults over the kit's button fill (0.12): the hover
-- layer, the pushed layer, the Fill's start, and selected + hover's start,
-- (the spec's table, less its contrast columns: the text no longer flips).
local BODY = 0.12
local COMPOSITES = {
	{ BLUE, 'layers', '1a3540', '154c62', '174151', '14526a' },
	{ BLUE, 'tones', '283943', '154456', '174151', '355b70' },
	{ BLUE, 'hue', '1e3b40', '27405f', '174151', '1e5e6a' },
	{ VIOLET, 'layers', '302841', '413263', '382d52', '45356c' },
	{ VIOLET, 'tones', '332e43', '3a2a5a', '382d52', '4d4170' },
	{ VIOLET, 'hue', '392b40', '322b61', '382d52', '5a3b6a' },
	{ GOLD, 'layers', '3f3a26', '5e552c', '4e4729', '675c2e' },
	{ GOLD, 'tones', '433e2c', '564d22', '4e4729', '70653c' },
	{ GOLD, 'hue', '413e2d', '5f4815', '4e4729', '6d663f' },
}

local function composites(accent, mode)
	local d = derive(accent, settings(mode))
	local h, p, f, fh = d.hover, d.pushed, d.fill, d.fillHover
	local hr, hg, hb = ST.Mix(BODY, BODY, BODY, h[1], h[2], h[3], h[4])
	local pr, pg, pb = ST.Mix(BODY, BODY, BODY, p[1], p[2], p[3], p[4])
	local fr, fg, fb = ST.Mix(BODY, BODY, BODY, f[1], f[2], f[3], f[4])
	local sr, sg, sb = ST.Mix(hr, hg, hb, fh[1], fh[2], fh[3], fh[4])
	return d, { { hr, hg, hb }, { pr, pg, pb }, { fr, fg, fb }, { sr, sg, sb } }
end

test('the composites at the defaults', function()
	for _, row in ipairs(COMPOSITES) do
		local accent, mode = row[1], row[2]
		local d, c = composites(accent, mode)
		for i = 1, 4 do
			local label = ('#%s %s %s'):format(accent, mode, ({ 'hover', 'pushed', 'fill', 'fill + hover' })[i])
			within(label, hex(c[i][1], c[i][2], c[i][3]), row[2 + i])
		end
	end
	-- over the kit's field fill (0.078) the Tones hovers
	local want = { [BLUE] = '1f303a', [VIOLET] = '2a253a', [GOLD] = '3a3523' }
	for accent, w in pairs(want) do
		local d = derive(accent, TONES)
		local h = d.hover
		within('field hover #' .. accent, hex(ST.Mix(0.078, 0.078, 0.078, h[1], h[2], h[3], h[4])), w)
	end
end)

test('solids', function()
	local layers = derive(BLUE, LAYERS)
	local edge = ST.THUMB_REST
	within('layers thumb hover', hex(st:StateSolid('hover', edge[1], edge[2], edge[3], layers)), '1f86af')
	within('layers thumb pushed', hex(st:StateSolid('pushed', edge[1], edge[2], edge[3], layers)), '0b9fd7')
	local n = st:Color('text', 'normal')
	within('layers knob hover', hex(st:StateSolid('hover', n.r, n.g, n.b, layers)), '5cc4e2')
	within('layers knob pushed', hex(st:StateSolid('pushed', n.r, n.g, n.b, layers)), '22b5eb')
	local tones = derive(BLUE, TONES)
	within('tones hover', hex(st:StateSolid('hover', 0.9, 0.2, 0.1, tones)), '5cc6ff')
	within('tones pushed', hex(st:StateSolid('pushed', 0.9, 0.2, 0.1, tones)), '0093cd')
	local ok = pcall(st.StateSolid, st, 'fill', 0, 0, 0, tones)
	check(not ok, 'only hover and pushed are solids')
end)

test('extremes: black, white, grey, no NaN', function()
	local function pair(accent, s)
		return tone(accent, 1, s), tone(accent, -1, s)
	end
	local function is(label, accent, s, plus, minus)
		local a, b = pair(accent, s)
		within(label .. ' +', a, plus)
		within(label .. ' -', b, minus)
	end
	for _, s in ipairs({ TONES, HUE }) do
		is('#000000', '000000', s, '020202', '000000')
		is('#ffffff', 'ffffff', s, 'ffffff', 'e4e4e4')
		is('#808080', '808080', s, '989898', '696969')
		is('#0a0a0a', '0a0a0a', s, '1c1c1c', '010101')
		is('#f5f5f5', 'f5f5f5', s, 'ffffff', 'dbdbdb')
	end
	is('#ff0000 tones', 'ff0000', TONES, 'ff6a59', 'd50000')
	is('#ff0000 hue', 'ff0000', HUE, 'fa7400', 'd00055')
	-- no NaN, every channel in 0..1, at every setting's edge
	local extremes = { { 0, 0, 0 }, { 1, 1, 1 }, { 0.5, 0.5, 0.5 }, { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 }, { 0, 0.68, 0.94 }, { 1e-9, 0, 0 } }
	local loud = settings('hue', { step = 0.2, shift = 60, chroma = 0.3 })
	for _, s in ipairs({ TONES, HUE, COOL, LAYERS, loud, settings('hue', { shift = 0, chroma = 0, step = 0.02 }) }) do
		for _, c in ipairs(extremes) do
			for k = -6, 6 do
				local r, g, b = ST.Tone(c[1], c[2], c[3], k, s)
				for _, v in ipairs({ r, g, b }) do
					check(type(v) == 'number' and v == v and v >= 0 and v <= 1, ('Tone(%s, %d) channel %s'):format(table.concat(c, ','), k, tostring(v)))
				end
			end
			local d = ST.Derive(c[1], c[2], c[3], s, ST.NewDerived())
			for _, name in ipairs({ 'hover', 'pushed', 'fill', 'fillHover', 'edge', 'edgeHover' }) do
				for i = 1, 4 do check(d[name][i] == d[name][i], 'derived ' .. name .. ' is no NaN') end
			end
		end
	end
	-- out-of-range inputs are clamped, never NaN
	local r, g, b = ST.Tone(-1, 2, 0 / 0, 1, TONES)
	check(r == r and g == g and b == b, 'a NaN channel gives no NaN')
end)

test('the settings: defaults, clamps, unknown words', function()
	local defaults = st.defaults.theme.states
	local s = ST.Settings()
	for k, v in pairs(defaults) do eq(s[k], v, 'default ' .. k) end
	local saved = st.config.profile.theme.states
	saved.hover, saved.fade, saved.mode, saved.direction, saved.shift = 2, 0, 'neon', 'sideways', 'x'
	s = ST.Settings()
	eq(s.hover, 0.6, 'hover clamps to its top'); eq(s.fade, 0.1, 'fade clamps to its bottom')
	eq(s.mode, 'tones', 'an unknown mode reads as the default')
	eq(s.direction, 'warm', 'an unknown direction too')
	eq(s.shift, 20, 'a word for a number reads as the default')
	saved.mode, saved.direction = 'hue', 'cool'
	s = ST.Settings()
	eq(s.mode, 'hue'); eq(s.direction, 'cool')
	saved.hover, saved.fade, saved.mode, saved.direction, saved.shift = 0.16, 0.7, 'tones', 'warm', 20
	for k in pairs(ST.RANGES) do check(type(s[k]) == 'number', k .. ' is a number') end
end)

test('the cache computes once per change and makes nothing', function()
	local calls = 0
	local real = ST.Derive
	ST.Derive = function(...) calls = calls + 1 return real(...) end
	local passes = 0
	local watcher = {}
	st:FollowColor(watcher, 'accent', nil, function() passes = passes + 1 end)

	ST.serial = ST.serial + 1 -- stale on purpose
	for _ = 1, 100 do st:StateColor('hover') end
	eq(calls, 1, '100 reads, one computation')

	st.config.profile.theme.accent.r = 0.5
	st:StateColor('hover')
	eq(calls, 2, 'a changed Accent: the next read computes')
	st:StateColor('hover')
	eq(calls, 2)

	ST.Changed()
	eq(passes, 1, 'ST.Changed passes the accent group')
	eq(calls, 2, 'a pass alone computes nothing')
	st:StateColor('pushed'); st:StateColor('hover')
	eq(calls, 3, 'ST.Changed makes the next read compute once')

	local other = {}
	for k, v in pairs(st.config.profile.theme.states) do other[k] = v end
	st.config.profile.theme.states = other
	st:StateColor('fill'); st:StateColor('fill')
	eq(calls, 4, 'a profile switch (another states table): once')
	ST.Derive = real
	st:UnfollowColor(watcher)

	st.config.profile.theme.accent.r = 0
	st:StateColor('hover')
	collectgarbage(); collectgarbage('stop')
	local before = collectgarbage('count')
	for _ = 1, 1000 do
		st:StateColor('hover'); st:StateSolid('hover', 0.3, 0.3, 0.3)
		st:StateFade(); st:StateAlpha()
	end
	local grew = collectgarbage('count') - before
	collectgarbage('restart')
	check(grew < 1, ('1000 reads grew the heap by %.2f KB'):format(grew))
end)

test('the readers at the defaults', function()
	local r, g, b, a = st:StateColor('hover')
	check(math.abs(r - 92 / 255) <= 1 / 255 and math.abs(g - 198 / 255) <= 1 / 255 and math.abs(b - 255 / 255) <= 1 / 255, ('hover is T+: %.4f %.4f %.4f'):format(r * 255, g * 255, b * 255))
	eq(a, 0.16)
	local er, eg, eb, ea = st:StateColor('edge')
	local accent = st:Color('accent')
	eq(er, accent.r); eq(eg, accent.g); eq(eb, accent.b); eq(ea, 1)
	local _, _, _, pa = st:StateColor('pushed')
	eq(pa, 0.32); eq(select(4, st:StateColor('fill')), 0.24); eq(select(4, st:StateColor('fillHover')), 0.24)
	check(near(st:StateFade(), 1 / 0.7), 'the fade is 1 / 0.7')
	eq(st:StateAlpha(), 0.4)
	local ok, err = pcall(function() local r = st:StateColor('nope') return r end) -- not a tail call: the caller's line is named
	check(not ok and tostring(err):find('nope', 1, true) and tostring(err):find('states_derive_test', 1, true), 'an unknown name errors at the caller: ' .. tostring(err))
end)

test('the fade texture', function()
	eq(st.textures.stateFade, st:TexturePath('state-fade.tga'))
	local data = read_saftui_source('SaftUI-Core/Media/Textures/state-fade.tga')
	check(data ~= nil, 'the file is there')
	local function u8(i) return data:byte(i + 1) end
	eq(u8(2), 2, 'type 2: uncompressed true color')
	eq(u8(12) + 256 * u8(13), 256, 'width'); eq(u8(14) + 256 * u8(15), 8, 'height'); eq(u8(16), 32, '32 bits')
	eq(#data, 18 + 256 * 8 * 4, 'its size')
	local function alpha(x, y) return u8(18 + (y * 256 + x) * 4 + 3) end
	eq(alpha(0, 0), 255); eq(alpha(64, 0), 191); eq(alpha(128, 0), 127); eq(alpha(255, 0), 0)
	for y = 0, 7 do
		for x = 0, 255 do
			local at = 18 + (y * 256 + x) * 4
			if u8(at) ~= 255 or u8(at + 1) ~= 255 or u8(at + 2) ~= 255 or u8(at + 3) ~= math.floor(255 * (1 - x / 255) + 0.5) then
				check(false, ('pixel %d, %d is wrong'):format(x, y))
				return
			end
		end
	end
	check(true, 'every pixel is white with its column alpha')
end)

test('L7: a NaN Accent channel reads as 0 and does not recompute on every read', function()
	local accent = st.config.profile.theme.accent
	local keep = accent.r
	accent.r = 0 / 0
	local calls, real = 0, ST.Derive
	ST.Derive = function(...) calls = calls + 1 return real(...) end
	for _ = 1, 100 do st:StateColor('hover') end
	ST.Derive = real
	check(calls <= 1, 'derived ' .. calls .. ' times')
	local r, g, b = st:StateColor('hover')
	check(r == r and g == g and b == b, 'no NaN')
	accent.r = keep
	st:StateColor('hover')
end)
